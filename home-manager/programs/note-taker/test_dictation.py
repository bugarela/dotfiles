"""Backend regression tests; no microphone, model download, or inference."""
import io
import unittest
from unittest.mock import Mock, patch

import dictation


class DictationTests(unittest.TestCase):
    def test_transcription_is_plain_text(self):
        model = Mock()
        model.transcribe.return_value = ([Mock(text=" Hello "), Mock(text="world.")], None)
        self.assertEqual(dictation.transcribe(model, "audio.wav", "en"), "Hello world.")
        model.transcribe.assert_called_once_with("audio.wav", language="en", vad_filter=True)

    def capture(self, command="stop\n", startup_code=None):
        recorder = Mock()
        recorder.poll.return_value = startup_code
        events = []
        order = []
        with (patch.object(dictation.subprocess, "Popen", return_value=recorder) as spawn,
              patch.object(dictation.time, "sleep"),
              patch.object(dictation.sys, "stdin", io.StringIO(command)),
              patch.object(dictation.select, "select", side_effect=lambda *args: ([dictation.sys.stdin], [], [])),
              patch.object(dictation, "emit", side_effect=lambda event, **fields: events.append((event, fields))),
              patch.object(dictation, "stop_recorder", side_effect=lambda proc: order.append("stop")),
              patch.object(dictation, "transcribe", side_effect=lambda *args: order.append("transcribe") or "Review this.")):
            try:
                dictation.dictate(Mock(), "en", "default", 300)
            except RuntimeError:
                if command == "stop\n" and startup_code is None:
                    raise
            return spawn.call_args.args[0], events, order

    def test_microphone_only_and_flush_before_transcription(self):
        command, events, order = self.capture()
        self.assertEqual(command.count("-i"), 1)
        self.assertNotIn("amix", " ".join(command))
        self.assertEqual([event for event, _ in events], ["recording", "transcribing", "text"])
        self.assertEqual(events[-1][1]["text"], "Review this.")
        self.assertEqual(order, ["stop", "transcribe", "stop"])

    def test_closed_stdin_discards_and_cleans_up(self):
        _, events, order = self.capture(command="")
        self.assertEqual([event for event, _ in events], ["recording"])
        self.assertEqual(order, ["stop"])

    def test_failed_capture_does_not_claim_recording(self):
        _, events, order = self.capture(startup_code=1)
        self.assertEqual(events, [])
        self.assertEqual(order, ["stop"])

    def test_recorder_reaped_after_timeout(self):
        recorder = Mock()
        recorder.poll.return_value = None
        recorder.wait.side_effect = [dictation.subprocess.TimeoutExpired("ffmpeg", 5), None]
        dictation.stop_recorder(recorder)
        recorder.send_signal.assert_called_once_with(dictation.signal.SIGINT)
        recorder.kill.assert_called_once()
        self.assertEqual(recorder.wait.call_count, 2)


if __name__ == "__main__":
    unittest.main()
