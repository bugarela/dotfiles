{ pkgs ? import <nixpkgs> {} }:

let
  python = pkgs.python3.withPackages (ps: with ps; [
    faster-whisper
    numpy
    webrtcvad
    setuptools
  ]);

  script = pkgs.writeText "note-taker.py" ''
    import warnings
    warnings.filterwarnings("ignore", message=".*pkg_resources.*")

    import sys
    import re
    import queue
    import signal
    import collections
    import threading
    import subprocess
    from datetime import datetime
    from pathlib import Path
    import numpy as np
    import webrtcvad
    from faster_whisper import WhisperModel

    SAMPLE_RATE     = 16000
    CHANNELS        = 1
    FRAME_MS        = 30
    FRAME_SAMPLES   = int(SAMPLE_RATE * FRAME_MS / 1000)
    BYTES_PER_FRAME = FRAME_SAMPLES * 2
    SILENCE_MS      = 800
    NUM_PAD_FRAMES  = int(SILENCE_MS / FRAME_MS)

    OUT_DIR = Path.home() / "notes" / "meetings"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_file = OUT_DIR / f"{datetime.now().strftime('%Y-%m-%d_%H%M%S')}.txt"

    def get_default_sink():
        result = subprocess.run(["pw-metadata", "0"], capture_output=True, text=True, timeout=2)
        for line in result.stdout.split("\n"):
            if "default.audio.sink" in line:
                m = re.search(r'"name":"([^"]+)"', line)
                if m:
                    return m.group(1)
        return None

    print("Loading Whisper model...", flush=True)
    model = WhisperModel("base", device="cpu", compute_type="int8")
    vad   = webrtcvad.Vad(2)

    sink = get_default_sink()
    if not sink:
        print("Error: could not detect default audio sink", file=sys.stderr)
        sys.exit(1)

    monitor = f"{sink}.monitor"
    print(f"Capturing: {monitor}", flush=True)
    print(f"Saving transcript to: {out_file}", flush=True)
    print("Listening... (Ctrl+C to stop)\n", flush=True)

    # Mix mic (default pulse source) + system audio (sink monitor) via ffmpeg.
    # Outputs raw s16le PCM to stdout — no container header to deal with.
    proc = subprocess.Popen(
        ["ffmpeg",
         "-f", "pulse", "-i", "default",
         "-f", "pulse", "-i", monitor,
         "-filter_complex", "amix=inputs=2:duration=longest",
         "-f", "s16le",
         "-ar", str(SAMPLE_RATE),
         "-ac", str(CHANNELS),
         "-"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

    if proc.poll() is not None:
        print("Error: ffmpeg failed to start", file=sys.stderr)
        sys.exit(1)

    audio_q = queue.Queue()

    def reader():
        try:
            while True:
                data = proc.stdout.read(BYTES_PER_FRAME)
                if len(data) < BYTES_PER_FRAME:
                    break
                audio_q.put(data)
        except Exception as e:
            print(f"[reader] {e}", file=sys.stderr)

    threading.Thread(target=reader, daemon=True).start()

    def transcribe(frames_data):
        audio = np.concatenate([
            np.frombuffer(d, dtype=np.int16).astype(np.float32) / 32767.0
            for d in frames_data
        ])
        if len(audio) < SAMPLE_RATE * 0.2:
            return
        segments, _ = model.transcribe(audio, language="en", vad_filter=True)
        text = " ".join(seg.text for seg in segments).strip()
        if text:
            ts = datetime.now().strftime("%H:%M:%S")
            line = f"[{ts}] {text}"
            print(line, flush=True)
            with open(out_file, "a") as f:
                f.write(line + "\n")

    def run():
        triggered     = False
        ring          = collections.deque(maxlen=NUM_PAD_FRAMES)
        voiced_frames = []

        while True:
            data = audio_q.get()
            is_speech = vad.is_speech(data, SAMPLE_RATE)

            if not triggered:
                ring.append((data, is_speech))
                if sum(1 for _, s in ring if s) / ring.maxlen > 0.75:
                    triggered = True
                    voiced_frames.extend(d for d, _ in ring)
                    ring.clear()
            else:
                voiced_frames.append(data)
                ring.append((data, is_speech))
                if sum(1 for _, s in ring if not s) / ring.maxlen > 0.75:
                    transcribe(voiced_frames)
                    triggered     = False
                    voiced_frames = []
                    ring.clear()

    try:
        run()
    except KeyboardInterrupt:
        proc.send_signal(signal.SIGINT)
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
        print(f"\nSaved to: {out_file}", flush=True)
  '';
in

pkgs.writeShellApplication {
  name = "note-taker";

  runtimeInputs = [ python pkgs.pipewire pkgs.ffmpeg ];

  text = ''
    python3 ${script}
  '';
}
