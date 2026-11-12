"""Microphone-only dictation using note-taker's existing Whisper environment.

JSON-lines stdout protocol; stdin accepts `stop` after the recording event.
No meeting files or timestamps. Audio is temporary and deleted on exit.
"""
import argparse
import json
from pathlib import Path
import select
import signal
import subprocess
import sys
import tempfile
import time
import warnings


def emit(event, **fields):
    print(json.dumps({"event": event, **fields}), flush=True)


def stop_recorder(process):
    if process.poll() is None:
        process.send_signal(signal.SIGINT)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def transcribe(model, audio, language):
    segments, _ = model.transcribe(str(audio), language=language, vad_filter=True)
    return " ".join(segment.text.strip() for segment in segments).strip()


def dictate(model, language, source, timeout):
    with tempfile.TemporaryDirectory(prefix="note-taker-dictation-") as directory:
        audio = Path(directory) / "speech.wav"
        with open(Path(directory) / "ffmpeg.log", "w+") as log:
            recorder = subprocess.Popen(
                ["ffmpeg", "-nostdin", "-y", "-f", "pulse", "-i", source,
                 "-ar", "16000", "-ac", "1", str(audio)],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=log,
            )
            try:
                time.sleep(0.25)
                if recorder.poll() is not None:
                    log.seek(0)
                    raise RuntimeError("Microphone capture failed: " + log.read()[-2000:])
                emit("recording")
                # Poll capture as well as stdin so a lost audio device cannot
                # leave Emacs displaying a false recording indicator forever.
                deadline = time.monotonic() + timeout
                while True:
                    if recorder.poll() is not None:
                        log.seek(0)
                        raise RuntimeError("Microphone capture ended: " + log.read()[-2000:])
                    remaining = deadline - time.monotonic()
                    # At the limit, keep what was said: stop and transcribe as on `stop`.
                    if remaining <= 0:
                        break
                    if select.select([sys.stdin], [], [], min(0.25, remaining))[0]:
                        command = sys.stdin.readline().strip()
                        if command != "stop":
                            raise RuntimeError("Dictation cancelled (stdin closed or invalid command)")
                        break
                stop_recorder(recorder)
                # SIGINT closes the WAV container before Whisper reads it. This
                # captures the final words without waiting for a silence boundary.
                emit("transcribing")
                emit("text", text=transcribe(model, audio, language))
            finally:
                stop_recorder(recorder)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--language", default="en")
    parser.add_argument("--source", default="default", help="PulseAudio microphone source")
    parser.add_argument("--timeout", type=float, default=1800, help="Maximum recording seconds; then it stops and transcribes")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")

    # Emacs cancellation sends SIGTERM to this process, not to the whole group.
    # Raising here ensures the recorder's finally block still runs.
    def cancel(_signum, _frame):
        raise SystemExit(130)

    signal.signal(signal.SIGTERM, cancel)
    signal.signal(signal.SIGINT, cancel)
    try:
        warnings.filterwarnings("ignore", message=".*pkg_resources.*")
        from faster_whisper import WhisperModel
        emit("loading")
        model = WhisperModel("base", device="cpu", compute_type="int8")
        dictate(model, args.language, args.source, args.timeout)
    except Exception as error:
        print(str(error), file=sys.stderr, flush=True)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
