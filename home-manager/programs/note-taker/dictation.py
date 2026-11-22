"""Microphone-only, memory-only streaming dictation.

JSON-lines stdout; stdin accepts `stop` after the recording event.
Audio travels through a pipe and memory queues, never an audio file.
"""
import argparse
from array import array
from collections import deque
from concurrent.futures import Future
import json
import math
import os
import queue
import select
import signal
import subprocess
import sys
import threading
import time
import warnings

SAMPLE_RATE = 16000
FRAME_BYTES = 960  # 30 ms of mono signed 16-bit PCM.


def emit(event, **fields):
    print(json.dumps({"event": event, **fields}), flush=True)


def timing(stage, **fields):
    # Diagnostics contain durations/configuration only, never audio or words.
    print(json.dumps({"timing": stage, **fields}), file=sys.stderr, flush=True)


def stop_recorder(process):
    if process.poll() is None:
        process.send_signal(signal.SIGINT)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def audio_level(pcm):
    samples = array("h", pcm)
    if sys.byteorder != "little":
        samples.byteswap()
    rms = math.sqrt(sum(sample * sample for sample in samples) / max(1, len(samples)))
    db = 20 * math.log10(max(rms / 32768, 1e-6))
    return max(0.0, min(1.0, (db + 60) / 60))


def transcribe(model, pcm, language, decoding="fast"):
    import numpy as np
    audio = np.frombuffer(pcm, dtype="<i2").astype(np.float32) / 32768.0
    # Default temperature fallback can decode repetitive audio six times.
    # Keep the previous search/retry policy available for accuracy comparisons.
    options = dict(beam_size=1, best_of=1, temperature=0.0) if decoding == "fast" else {}
    started = time.monotonic()
    segments, _ = model.transcribe(audio, language=language, vad_filter=True, **options)
    text = " ".join(segment.text.strip() for segment in segments).strip()
    timing("chunk", audio_seconds=len(audio) / SAMPLE_RATE,
           seconds=round(time.monotonic() - started, 3), decoding=decoding)
    return text


def load_model():
    started = time.monotonic()
    warnings.filterwarnings("ignore", message=".*pkg_resources.*")
    from faster_whisper import WhisperModel
    cpus = len(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else (os.cpu_count() or 1)
    threads = min(8, cpus)
    model = WhisperModel("base", device="cpu", compute_type="int8", cpu_threads=threads)
    timing("model", seconds=round(time.monotonic() - started, 3), threads=threads)
    return model


def load_vad():
    import webrtcvad
    return webrtcvad.Vad(2)


class SpeechChunks:
    """Split only at pauses; keep pre-roll and the complete final utterance."""

    def __init__(self, vad):
        self.vad = vad
        self.pre_roll = deque(maxlen=10)  # 300 ms before the first voiced frame.
        self.frames = []
        self.silence = 0

    def feed(self, frame):
        voiced = self.vad.is_speech(frame, SAMPLE_RATE)
        if not self.frames:
            self.pre_roll.append(frame)
            if voiced:
                self.frames = list(self.pre_roll)
                self.pre_roll.clear()
            return None
        self.frames.append(frame)
        self.silence = 0 if voiced else self.silence + 1
        if self.silence >= 20:  # 600 ms pause, retained for Whisper's context.
            return self.finish()
        return None

    def finish(self):
        pcm = b"".join(self.frames)
        self.frames = []
        self.silence = 0
        return pcm or None


class StreamingTranscriber:
    """Capture, VAD, model loading and inference never block one another.

    Pending audio stays in RAM. A slow model can accumulate up to the capture
    timeout's worth of PCM (about 58 MB for the default 30-minute limit).
    """

    def __init__(self, model, language, decoding="fast"):
        self.decoding = decoding
        self.frames = queue.Queue()
        self.chunks = queue.Queue()
        self.cancelled = threading.Event()
        self.result = Future()
        self.result_lock = threading.Lock()
        self.model = model
        self.language = language
        threading.Thread(target=self.segment, daemon=True).start()
        threading.Thread(target=self.recognize, daemon=True).start()

    def fail(self, error):
        # Either thread may fail first; only one owns completion of the future.
        with self.result_lock:
            if not self.result.done():
                self.result.set_exception(error)
        self.cancel()

    def segment(self):
        try:
            chunks = SpeechChunks(load_vad())
            while not self.cancelled.is_set():
                frame = self.frames.get()
                if frame is None:
                    final = chunks.finish()
                    if final:
                        self.chunks.put(final)
                    self.chunks.put(None)
                    return
                chunk = chunks.feed(frame)
                if chunk:
                    self.chunks.put(chunk)
        except BaseException as error:
            self.fail(error)

    def recognize(self):
        try:
            model = self.model if self.model is not None else load_model()
            text = []
            while not self.cancelled.is_set():
                chunk = self.chunks.get()
                if chunk is None:
                    if not self.cancelled.is_set():
                        with self.result_lock:
                            if not self.result.done():
                                self.result.set_result(" ".join(text))
                    return
                if self.cancelled.is_set():
                    return
                words = transcribe(model, chunk, self.language, self.decoding)
                if words:
                    text.append(words)
        except BaseException as error:
            self.fail(error)

    def feed(self, frame):
        self.frames.put(frame)

    def finish(self):
        self.frames.put(None)

    def cancel(self):
        self.cancelled.set()
        self.frames.put(None)
        self.chunks.put(None)


def finish_capture(recorder):
    """Drain while ffmpeg exits, rather than blocking it on a full stdout pipe."""
    if recorder.poll() is None:
        recorder.send_signal(signal.SIGINT)
    deadline = time.monotonic() + 5
    audio = bytearray()
    while time.monotonic() < deadline:
        if select.select([recorder.stdout], [], [], 0.05)[0]:
            data = os.read(recorder.stdout.fileno(), 16384)
            if not data:
                recorder.wait(timeout=max(0.1, deadline - time.monotonic()))
                return bytes(audio)
            audio.extend(data)
    raise RuntimeError("Microphone capture did not stop cleanly")


def dictate(model, language, source, timeout, decoding="fast"):
    recorder = subprocess.Popen(
        ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
         "-f", "pulse", "-i", source, "-ar", str(SAMPLE_RATE), "-ac", "1",
         "-f", "s16le", "-flush_packets", "1", "pipe:1"],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        bufsize=0,
    )
    pipeline = None
    pending = b""
    started = time.monotonic()
    deadline = started + 5
    last_meter = started
    try:
        while True:
            readable = select.select([sys.stdin, recorder.stdout], [], [], 0.05)[0]
            # Give stdin priority: EOF/invalid input must discard even during startup.
            if sys.stdin in readable:
                if sys.stdin.readline().strip() != "stop" or pipeline is None:
                    raise RuntimeError("Dictation cancelled (stdin closed or invalid command)")
                break
            if recorder.stdout in readable:
                data = os.read(recorder.stdout.fileno(), 16384)
                if not data:
                    raise RuntimeError("Microphone capture ended unexpectedly; check the PulseAudio source")
                pending += data
                while len(pending) >= FRAME_BYTES:
                    frame, pending = pending[:FRAME_BYTES], pending[FRAME_BYTES:]
                    if pipeline is None:
                        # Actual PCM, not just a live PID, proves capture is ready.
                        emit("recording")
                        timing("capture", seconds=round(time.monotonic() - started, 3))
                        pipeline = StreamingTranscriber(model, language, decoding)
                        deadline = time.monotonic() + timeout
                    pipeline.feed(frame)
                now = time.monotonic()
                if pipeline is not None and now - last_meter >= 0.1:
                    emit("level", level=audio_level(data[:len(data) // 2 * 2]))
                    last_meter = now
            if pipeline is not None and pipeline.result.done():
                pipeline.result.result()  # Surface model/VAD/inference failures promptly.
            if time.monotonic() >= deadline:
                if pipeline is None:
                    raise RuntimeError("Microphone capture did not produce samples within 5 seconds")
                break
        # Stop capture, then drain the pipe so F8 retains the final samples.
        stopped = time.monotonic()
        pending += finish_capture(recorder)
        if pending:
            pending = pending[:len(pending) // 2 * 2]
            for offset in range(0, len(pending), FRAME_BYTES):
                pipeline.feed(pending[offset:offset + FRAME_BYTES].ljust(FRAME_BYTES, b"\0"))
        emit("transcribing")
        pipeline.finish()
        while not pipeline.result.done():
            if select.select([sys.stdin], [], [], 0.05)[0]:
                raise RuntimeError("Dictation cancelled (stdin closed or invalid command)")
        text = pipeline.result.result()
        timing("after_stop", seconds=round(time.monotonic() - stopped, 3))
        emit("text", text=text)
    finally:
        if pipeline is not None:
            pipeline.cancel()
        recorder.stdout.close()
        stop_recorder(recorder)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--language", default="en")
    parser.add_argument("--source", default="default", help="PulseAudio microphone source")
    parser.add_argument("--timeout", type=float, default=1800, help="Maximum recording seconds; then it stops and transcribes")
    parser.add_argument("--decoding", choices=["fast", "thorough"], default="fast",
                        help="Fast single-pass decoding (default), or the previous beam search and retries")
    args = parser.parse_args()
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be finite and positive")

    def cancel(_signum, _frame):
        raise SystemExit(130)

    signal.signal(signal.SIGTERM, cancel)
    signal.signal(signal.SIGINT, cancel)
    try:
        emit("loading")
        dictate(None, args.language, args.source, args.timeout, args.decoding)
    except Exception as error:
        print(str(error), file=sys.stderr, flush=True)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
