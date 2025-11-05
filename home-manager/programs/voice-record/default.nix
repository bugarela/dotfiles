{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellApplication {
  name = "voice-record";

  runtimeInputs = with pkgs; [
    sox
    openai-whisper
  ];

  text = ''
    # Create recordings directory if it doesn't exist
    mkdir -p "$HOME/recordings"

    # Generate filename with timestamp
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    RECORDING="$HOME/recordings/recording_$TIMESTAMP.wav"

    echo "Recording... Press Ctrl+C to stop"
    echo "Saving to: $RECORDING"
    echo ""

    # Record audio (16kHz is good for Whisper)
    rec -r 16000 -c 1 "$RECORDING"

    echo ""
    echo "Recording saved. Transcribing..."
    echo ""

    # Transcribe with Whisper (output_format txt gives plain text, no timestamps)
    whisper "$RECORDING" --model base --language en --output_format txt --output_dir /tmp --fp16 False

    # Get the base filename without extension
    BASENAME=$(basename "$RECORDING" .wav)

    # Display the transcription
    echo "=== Transcription ==="
    cat "/tmp/$BASENAME.txt"
    echo ""
    echo "=== End Transcription ==="
  '';
}
