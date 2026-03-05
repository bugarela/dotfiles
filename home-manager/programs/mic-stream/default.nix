{ pkgs ? import <nixpkgs> {} }:

let
  python = pkgs.python3.withPackages (ps: with ps; [
    faster-whisper
    sounddevice
    numpy
    webrtcvad
    setuptools
  ]);

  script = pkgs.writeText "mic-stream.py" ''
    import warnings
    warnings.filterwarnings("ignore", message=".*pkg_resources.*")

    import sys
    import queue
    import collections
    from datetime import datetime
    from pathlib import Path
    import numpy as np
    import sounddevice as sd
    import webrtcvad
    from faster_whisper import WhisperModel

    SAMPLE_RATE    = 16000
    CHANNELS       = 1
    FRAME_MS       = 30
    FRAME_SAMPLES  = int(SAMPLE_RATE * FRAME_MS / 1000)
    SILENCE_MS     = 800
    NUM_PAD_FRAMES = int(SILENCE_MS / FRAME_MS)

    OUT_DIR = Path.home() / "notes" / "mic"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_file = OUT_DIR / f"{datetime.now().strftime('%Y-%m-%d_%H%M%S')}.txt"

    print("Loading Whisper model...", flush=True)
    model = WhisperModel("base", device="cpu", compute_type="int8")
    vad   = webrtcvad.Vad(2)

    print(f"Saving to: {out_file}", flush=True)
    print("Listening... (Ctrl+C to stop)\n", flush=True)

    audio_q = queue.Queue()

    def callback(indata, frames, time_info, status):
        if status:
            print(f"[audio] {status}", file=sys.stderr)
        audio_q.put(indata.copy())

    def transcribe(frames):
        audio = np.concatenate(frames).flatten()
        if len(audio) < SAMPLE_RATE * 0.2:
            return
        segments, _ = model.transcribe(audio, language="en", vad_filter=True)
        text = " ".join(seg.text for seg in segments).strip()
        if text:
            print(text, flush=True)
            with open(out_file, "a") as f:
                f.write(text + "\n")

    def run():
        triggered     = False
        ring          = collections.deque(maxlen=NUM_PAD_FRAMES)
        voiced_frames = []

        with sd.InputStream(
            samplerate = SAMPLE_RATE,
            channels   = CHANNELS,
            dtype      = "float32",
            blocksize  = FRAME_SAMPLES,
            callback   = callback,
        ):
            while True:
                chunk = audio_q.get()
                pcm_bytes = (chunk * 32767).astype(np.int16).tobytes()
                is_speech = vad.is_speech(pcm_bytes, SAMPLE_RATE)

                if not triggered:
                    ring.append((chunk, is_speech))
                    if sum(1 for _, s in ring if s) / ring.maxlen > 0.75:
                        triggered = True
                        voiced_frames.extend(f for f, _ in ring)
                        ring.clear()
                else:
                    voiced_frames.append(chunk)
                    ring.append((chunk, is_speech))
                    if sum(1 for _, s in ring if not s) / ring.maxlen > 0.75:
                        transcribe(voiced_frames)
                        triggered     = False
                        voiced_frames = []
                        ring.clear()

    try:
        run()
    except KeyboardInterrupt:
        print(f"\nSaved to: {out_file}", flush=True)
  '';
in

pkgs.writeShellApplication {
  name = "mic-stream";

  runtimeInputs = [ python ];

  text = ''
    python3 ${script}
  '';
}
