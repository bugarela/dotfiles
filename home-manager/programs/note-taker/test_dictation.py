"""Streaming regressions; no microphone, model download, or real inference."""
import os
import shutil
import subprocess
import sys
import threading
import time
import unittest
from unittest.mock import Mock, patch

import dictation

VOICE = b"\xe8\x03" * (dictation.FRAME_BYTES // 2)
SILENCE = bytes(dictation.FRAME_BYTES)


class FakeVad:
    def is_speech(self, frame, rate):
        assert len(frame) == dictation.FRAME_BYTES
        assert rate == 16000
        return any(frame)


class ChunkTests(unittest.TestCase):
    def test_silence_is_discarded(self):
        chunks = dictation.SpeechChunks(FakeVad())
        for _ in range(50):
            self.assertIsNone(chunks.feed(SILENCE))
        self.assertIsNone(chunks.finish())

    def test_pause_emits_chunk_with_preroll_without_losing_next_utterance(self):
        chunks = dictation.SpeechChunks(FakeVad())
        for _ in range(15):
            chunks.feed(SILENCE)
        self.assertIsNone(chunks.feed(VOICE))
        for _ in range(19):
            self.assertIsNone(chunks.feed(SILENCE))
        self.assertEqual(chunks.feed(SILENCE), SILENCE * 9 + VOICE + SILENCE * 20)
        chunks.feed(VOICE)
        self.assertEqual(chunks.finish(), VOICE)
        self.assertIsNone(chunks.finish())

    def test_short_pause_does_not_split_words(self):
        chunks = dictation.SpeechChunks(FakeVad())
        for frame in [VOICE] + [SILENCE] * 19 + [VOICE]:
            self.assertIsNone(chunks.feed(frame))
        self.assertEqual(chunks.finish(), VOICE + SILENCE * 19 + VOICE)


class PipelineTests(unittest.TestCase):
    def test_transcription_happens_before_finish_and_preserves_order(self):
        heard = threading.Event()
        received = []

        def transcribe(model, pcm, language, decoding):
            self.assertEqual(decoding, "fast")
            received.append(pcm)
            heard.set()
            return "First." if len(received) == 1 else "Second."

        with (patch.object(dictation, "load_vad", return_value=FakeVad()),
              patch.object(dictation, "transcribe", side_effect=transcribe)):
            pipeline = dictation.StreamingTranscriber(Mock(), "en")
            try:
                for frame in [VOICE] + [SILENCE] * 20:
                    pipeline.feed(frame)
                self.assertTrue(heard.wait(2), "No inference during capture")
                self.assertFalse(pipeline.result.done())
                pipeline.feed(VOICE)
                pipeline.finish()
                self.assertEqual(pipeline.result.result(timeout=2), "First. Second.")
                self.assertEqual(received, [VOICE + SILENCE * 20, VOICE])
            finally:
                pipeline.cancel()

    def test_capture_is_queued_while_model_loads(self):
        loading, release = threading.Event(), threading.Event()
        model = Mock()

        def load():
            loading.set()
            release.wait(2)
            return model

        with (patch.object(dictation, "load_vad", return_value=FakeVad()),
              patch.object(dictation, "load_model", side_effect=load),
              patch.object(dictation, "transcribe", return_value="Buffered.") as transcribe):
            pipeline = dictation.StreamingTranscriber(None, "en")
            try:
                self.assertTrue(loading.wait(2))
                pipeline.feed(VOICE)
                pipeline.finish()
                self.assertFalse(pipeline.result.done())
                release.set()
                self.assertEqual(pipeline.result.result(timeout=2), "Buffered.")
                self.assertEqual(transcribe.call_args.args[1], VOICE)
            finally:
                release.set()
                pipeline.cancel()

    def test_thorough_decoding_is_forwarded_to_inference(self):
        with (patch.object(dictation, "load_vad", return_value=FakeVad()),
              patch.object(dictation, "transcribe", return_value="Thorough.") as transcribe):
            model = Mock()
            pipeline = dictation.StreamingTranscriber(model, "en", "thorough")
            try:
                pipeline.feed(VOICE)
                pipeline.finish()
                self.assertEqual(pipeline.result.result(timeout=2), "Thorough.")
                transcribe.assert_called_once_with(model, VOICE, "en", "thorough")
            finally:
                pipeline.cancel()

    def test_failures_are_not_silently_lost(self):
        for failure in [RuntimeError("failed"), TimeoutError("inference timed out")]:
            with (patch.object(dictation, "load_vad", return_value=FakeVad()),
                  patch.object(dictation, "transcribe", side_effect=failure)):
                pipeline = dictation.StreamingTranscriber(Mock(), "en")
                pipeline.feed(VOICE)
                pipeline.finish()
                with self.assertRaisesRegex(type(failure), str(failure)):
                    pipeline.result.result(timeout=2)
                pipeline.cancel()

    def test_cancellation_does_not_wait_for_model_or_transcribe_queued_audio(self):
        loading, release = threading.Event(), threading.Event()

        def load():
            loading.set()
            release.wait(2)
            return Mock()

        with (patch.object(dictation, "load_vad", return_value=FakeVad()),
              patch.object(dictation, "load_model", side_effect=load),
              patch.object(dictation, "transcribe") as transcribe):
            pipeline = dictation.StreamingTranscriber(None, "en")
            self.assertTrue(loading.wait(2))
            pipeline.feed(VOICE)
            pipeline.finish()
            pipeline.cancel()
            release.set()
            time.sleep(0.05)
            transcribe.assert_not_called()
            self.assertFalse(pipeline.result.done())


class DictationTests(unittest.TestCase):
    def capture(self, command=b"stop\n", initial=VOICE, tail=VOICE, timeout=2,
                stop_after_inference=False, fail_capture=False):
        events, heard, received = [], threading.Event(), []
        read_fd, write_fd = os.pipe()
        process = None
        spawn = subprocess.Popen
        script = (
            "import os,signal,sys,time\n"
            f"tail = {tail!r}\n"
            "def stop(*args):\n"
            " os.write(1, tail); sys.exit(0)\n"
            "signal.signal(signal.SIGINT, stop)\n"
            + ("sys.exit(1)\n" if fail_capture else f"os.write(1, {initial!r})\nwhile True: time.sleep(.1)\n")
        )
        timers = []

        def popen(args, **kwargs):
            nonlocal process
            self.assertEqual(args[-1], "pipe:1")
            self.assertIn("s16le", args)
            self.assertEqual(args.count("-i"), 1)
            self.assertEqual(kwargs["stdout"], subprocess.PIPE)
            process = spawn([sys.executable, "-u", "-c", script], **kwargs)
            return process

        def emit(event, **fields):
            events.append((event, fields))
            if event == "recording" and command is not None:
                def stop():
                    if stop_after_inference:
                        heard.wait(2)
                    os.write(write_fd, command)
                timer = threading.Thread(target=stop)
                timer.start()
                timers.append(timer)

        def transcribe(model, pcm, language, decoding):
            received.append(pcm)
            heard.set()
            return f"Chunk {len(received)}."

        try:
            with (os.fdopen(read_fd) as stdin,
                  patch.object(dictation.sys, "stdin", stdin),
                  patch.object(dictation.subprocess, "Popen", side_effect=popen),
                  patch.object(dictation, "emit", side_effect=emit),
                  patch.object(dictation, "load_vad", return_value=FakeVad()),
                  patch.object(dictation, "transcribe", side_effect=transcribe),
                  patch("builtins.open", side_effect=AssertionError("Dictation must not open a file"))):
                if command == b"" or fail_capture:
                    if command == b"":
                        os.close(write_fd)
                        write_fd = None
                    with self.assertRaises(RuntimeError):
                        dictation.dictate(Mock(), "en", "default", timeout)
                else:
                    dictation.dictate(Mock(), "en", "default", timeout)
            self.assertIsNotNone(process.poll())
            return events, received
        finally:
            for timer in timers:
                timer.join(3)
            if write_fd is not None:
                os.close(write_fd)
            if process is not None and process.poll() is None:
                process.kill()
                process.wait()

    def test_stop_flushes_final_samples_without_audio_files(self):
        events, received = self.capture(tail=VOICE[:100])
        self.assertEqual([event for event, _ in events if event != "level"],
                         ["recording", "transcribing", "text"])
        self.assertEqual(events[-1][1]["text"], "Chunk 1.")
        self.assertEqual(b"".join(received), VOICE + VOICE[:100] + bytes(860))

    def test_pause_transcribes_before_stop_and_tail_is_kept(self):
        events, received = self.capture(initial=VOICE + SILENCE * 20,
                                        stop_after_inference=True)
        self.assertEqual(received, [VOICE + SILENCE * 20, VOICE])
        self.assertEqual(events[-1][1]["text"], "Chunk 1. Chunk 2.")

    def test_timeout_keeps_audio(self):
        events, received = self.capture(command=None, timeout=0.1)
        self.assertEqual(b"".join(received), VOICE * 2)
        self.assertEqual(events[-1][0], "text")

    def test_eof_discards_without_text(self):
        events, _ = self.capture(command=b"")
        self.assertNotIn("text", [event for event, _ in events])

    def test_failed_capture_does_not_claim_recording(self):
        events, _ = self.capture(fail_capture=True)
        self.assertEqual(events, [])

    def test_meter_responds_to_samples(self):
        self.assertEqual(dictation.audio_level(SILENCE), 0)
        self.assertGreater(dictation.audio_level(VOICE), 0)
        self.assertGreater(dictation.audio_level(b"\xff\x7f" * 160), 0.99)
        self.assertLessEqual(dictation.audio_level(VOICE), 1)

    def test_recorder_reaped_after_timeout(self):
        recorder = Mock()
        recorder.poll.return_value = None
        recorder.wait.side_effect = [subprocess.TimeoutExpired("ffmpeg", 5), None]
        dictation.stop_recorder(recorder)
        recorder.kill.assert_called_once()
        self.assertEqual(recorder.wait.call_count, 2)

    @unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg is not installed")
    def test_real_ffmpeg_pipe_contains_only_pcm(self):
        process = subprocess.Popen(
            ["ffmpeg", "-nostdin", "-loglevel", "error", "-f", "lavfi",
             "-i", "anullsrc=r=16000:cl=mono", "-t", "0.3", "-f", "s16le", "pipe:1"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        )
        pcm, _ = process.communicate(timeout=5)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(pcm, SILENCE * 10)

    def test_whisper_receives_float_array_not_a_filename(self):
        try:
            import numpy as np
        except ImportError:
            self.skipTest("Run with note-taker's Python environment for numpy")
        model = Mock()
        model.transcribe.return_value = ([Mock(text=" Hello "), Mock(text="world.")], None)
        self.assertEqual(dictation.transcribe(model, VOICE, "en"), "Hello world.")
        audio = model.transcribe.call_args.args[0]
        self.assertIsInstance(audio, np.ndarray)
        self.assertEqual(audio.dtype, np.float32)
        self.assertEqual(len(audio), 480)
        self.assertAlmostEqual(float(audio[0]), 1000 / 32768)
        self.assertEqual(model.transcribe.call_args.kwargs,
                         dict(language="en", vad_filter=True, beam_size=1,
                              best_of=1, temperature=0.0))
        dictation.transcribe(model, VOICE, "en", decoding="thorough")
        self.assertEqual(model.transcribe.call_args.kwargs,
                         dict(language="en", vad_filter=True))


if __name__ == "__main__":
    unittest.main()
