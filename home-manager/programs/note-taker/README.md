# Local dictation in Emacs and Herdr

The existing `note-taker` meeting recorder is unchanged. `note-taker --dictate`
adds microphone-only dictation, using the same Nix Python environment and
`faster-whisper` `base` model on CPU/int8. Microphone capture is started before Whisper is loaded.
The model is loaded in the background while you speak, and the downloaded model cache is reused.
There is no hosted transcription API.

Audio is streamed from FFmpeg through a pipe into memory queues.
No audio file is created, including a temporary WAV.
Speech chunks are transcribed during pauses while microphone capture continues.
For example, a sentence followed by a pause can be transcribed before you finish the next sentence.
F8 stops capture, drains the final samples and waits for pending chunks before inserting the combined text.
Cancellation discards the session without inserting partial results.

An audio-level meter is shown during recording in both applications.
The bars respond to microphone volume rather than a fixed animation.
For example, the bars shrink during silence and grow as you speak.
After a short recording, transcription may still wait for model loading to finish.

## Emacs usage

After rebuilding your Home Manager/NixOS configuration to update `note-taker`,
restart Doom Emacs or reload its configuration. No `doom sync` is needed.
For a Git-backed flake rebuild, ensure `dictation.py` and `dictation_control.py`
are tracked (or staged) so Nix includes them in the flake source.

For ordinary dictation in any editable buffer, leave Org prose unselected.

- **F8**: start recording; wait for `Voice: RECORDING`, then speak.
- **F8** again: stop and insert plain transcription at the saved cursor location.
- **Shift+F8**: cancel without insertion.

Outside Org buffers, selected text is not replaced, and the region end is used as the insertion point.
Moving elsewhere while transcribing does not redirect the result or move your new point.
If point stays at the insertion location, it advances past the inserted words.
Capture runs locally even when editing through TRAMP. Read-only buffers are
protected. No automatic save or source-code execution.

With **selected Org prose**, F8 records a rewrite instruction instead of inserting the transcription.
One AI alternative is generated through Pi and previewed in the document.
Press RET to keep the alternative or q to restore the starting wording.
Transcription remains local, but the instruction and selected passage are sent to the configured model provider.
The surrounding paragraph is also sent.
See [the writing guide](../../../docs/write-on-emacs.md) for details.

For an explicit **Org review comment**, place point after a passage (or select
it) and use the existing additional bindings:

- **SPC a v**: start; wait for `Voice: RECORDING`, then speak.
- **SPC a v** again: stop capture and transcribe the complete recording.
- **SPC a V**: cancel during loading, recording, or transcription.

The transcription is inserted after the saved line/selection as `# ? …`, even
if point moves. It is one undoable edit and is not auto-saved. Read/edit it, save,
then ask org-spec to address comments. This review comment command does not invoke an agent.

The mode line shows loading, recording, transcribing, or cancelling. No speech
means no inserted comment. Errors appear in `*Org dictation errors*`; results
whose destination became uneditable go to `*Voice dictation recovery*`.
Closing the destination buffer or Emacs cancels capture. Recording stops after
30 minutes, and pending speech is transcribed as though F8 had been pressed.
Audio stays in process memory, and no audio or meeting transcript files are created.
Ordinary process memory remains subject to the operating system's swap policy.

The standalone Emacs module is `doom.d/org-dictation.el`. Its customizable
`my/org-dictation-command` defaults to `("note-taker" "--dictate")`. Backend
options include `--language en`, `--source default` (PulseAudio source name),
`--timeout 1800` (seconds; then it stops and transcribes) and `--decoding fast` or `--decoding thorough`.
Fast decoding is the default and uses a single greedy pass without temperature retries.
Thorough decoding restores Whisper's previous beam search and temperature fallback policy.
The model remains `base` on CPU/int8, but recognition accuracy can differ between decoding modes.

## Herdr usage

The personal `my-main` layout has a compact **microphone icon beside the +** at
the top right. Click it or press F8 to start/stop; Shift+F8 cancels. Wait for the
Recording indicator, speak, and press F8 again. Transcription is pasted into the
original terminal's input using Herdr's ordinary native paste. Edit it there,
then press Enter yourself. There is no separate draft editor/Send button, custom
Enter binding, agent-status guard, or automatic submission. Shells and editors
work too; transcript control characters/newlines are flattened before paste.

Pasting uses and replaces the system clipboard. If you change terminals while
transcribing, nothing is typed elsewhere: return to the original terminal and
press F8 to paste the retained text. Old drafts from the previous UI and
interrupted delivery attempts are never automatically replayed. F8 or Copy
transcript can recover them; Shift+F8 discards them.

Pending text is saved in local Herdr state until pasted/discarded. The bridge
keeps private runtime session files (directory 0700/files 0600), removed on
paste/discard; abandoned sessions are pruned after a day on the next start.
Pasted text remains in the clipboard. No cloud transcription. A session ID is
internal bookkeeping, never shown in UI.

The mod invokes the standard-library bridge at
`~/dotfiles/home-manager/programs/note-taker/dictation_control.py`, which starts
installed `note-taker --dictate`. Memory-only streaming, faster capture and the audio meter require a rebuilt `note-taker` package.
Older dictation-enabled packages still work with this integration, but no audio levels are received.
New package builds also expose `note-taker --dictation-control <action>`.

The bridge's commands are `start`, `status`, `stop`, `cancel`, and `discard`, with
`--session` after start. They return quickly as JSON; a detached worker owns the
interactive backend. Herdr polls every 100 milliseconds only while active. Polls renew a
lease: loss of the controller cancels capture after 20 seconds. Closing the mod,
changing layouts, or quitting Herdr also requests cancellation. No recording
starts merely by opening the app or loading the mod. F8/Shift+F8 apply while
`my-main` is shown; other layouts need the mod added before binding its commands.

Herdr intercepts its F8 before terminal programs; GUI Emacs has its own binding.
Emacs inside a Herdr terminal receives the same native paste as other programs;
use `SPC a v` there if you specifically want an Org review comment.

## Backend protocol

Stdout contains JSON lines with events `loading`, `recording`, `level`, `transcribing`
and finally `text` with a `text` string. A normalized microphone volume between 0 and 1 is included in each `level` event. Diagnostics go to stderr. Write
`stop\n` to stdin after `recording` to finish. Closing stdin discards capture;
SIGTERM cancels and cleans up ffmpeg. The `recording` event is emitted only after microphone samples have been received.
Whisper is then loaded in a background thread.
`ffmpeg` streams mono 16 kHz PCM through stdout and captures only the default PulseAudio input.
The system output mix that is used for meetings is not captured.

## Tests / build

From the dotfiles repository:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s home-manager/programs/note-taker -p 'test_dictation*.py' -v
emacs --batch -Q -L doom.d -l doom.d/tests/org-dictation-test.el \
  -f ert-run-tests-batch-and-exit
nix-build home-manager/programs/note-taker/default.nix --no-out-link
herdr-app check ~/dotfiles/herdr-app/mods/my-dictation
```

Tests use synthetic PCM, mocked inference and a synthetic FFmpeg source without opening the microphone or downloading a model.
The NumPy-array test requires the Python environment that is provided by the `note-taker` package.
An actual microphone/Whisper round trip needs an interactive test.

## Latency and memory

Speech is split after approximately 600 milliseconds of silence that is detected by WebRTC VAD.
Pre-roll audio and trailing silence are retained for each chunk.
A final partial frame is padded in memory rather than discarded.
Continuous speech is not forcibly split, since a word could be cut in half.
Without a pause, the full utterance still needs transcription after F8.

Late status responses are ignored after paste or session deletion, since a completed session must not be shown as a capture failure.

Single-run synthetic benchmarks on this desktop compared the previous settings with fast decoding and eight CPU threads.
The timings below exclude model loading, and actual microphone results will vary.

| Synthetic input | Audio duration | Previous decoding | Fast decoding |
|---|---:|---:|---:|
| Ordinary prose | 7.9 seconds | 0.87 seconds | 0.60 seconds |
| Repeated syllables | 6.9 seconds | 16.08 seconds | 2.10 seconds |

The ordinary-prose transcript was identical in this comparison.
The repeated-syllable transcript was inaccurate in both modes, and these measurements do not demonstrate equivalent recognition quality.

Duration-only diagnostics are written to stderr for capture startup, model loading, chunk inference and the wait after stopping.
No audio samples or transcript text are included in these timing messages.
Herdr's existing backend log holds these messages until the session is discarded.

The model is loaded for each invocation and is not kept warm between sessions.
Short recordings may therefore still wait for model startup.
If inference falls behind, audio is queued in memory rather than dropped or written to storage.
The default 30-minute capture limit corresponds to approximately 58 MB of raw PCM, excluding inference memory and queue overhead.
