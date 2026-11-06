# Local dictation in Emacs and Herdr

The existing `note-taker` meeting recorder is unchanged. `note-taker --dictate`
adds microphone-only dictation, using the same Nix Python environment and
`faster-whisper` `base` model on CPU/int8. Each invocation loads the model; its
existing downloaded model cache is reused. There is no hosted transcription API.

## Emacs usage

After rebuilding your Home Manager/NixOS configuration to update `note-taker`,
restart Doom Emacs or reload its configuration. No `doom sync` is needed.
For a Git-backed flake rebuild, ensure `dictation.py` and `dictation_control.py`
are tracked (or staged) so Nix includes them in the flake source.

In **any editable buffer**, regardless of file type:

- **F8**: start recording; wait for `Voice: RECORDING`, then speak.
- **F8** again: stop and insert plain transcription at the saved cursor location.
- **Shift+F8**: cancel without insertion.

Selected text is not replaced; the region end is the insertion point. Moving
elsewhere while transcribing doesn't redirect the result or move your new point.
If point stays at the insertion location, it advances past the inserted words.
Capture runs locally even when editing through TRAMP. Read-only buffers are
protected. No automatic save or source-code execution.

For an explicit **Org review comment**, place point after a passage (or select
it) and use the existing additional bindings:

- **SPC a v**: start; wait for `Voice: RECORDING`, then speak.
- **SPC a v** again: stop capture and transcribe the complete recording.
- **SPC a V**: cancel during loading, recording, or transcription.

The transcription is inserted after the saved line/selection as `# ? …`, even
if point moves. It is one undoable edit and is not auto-saved. Read/edit it, save,
then ask org-spec to address comments. Dictation does not invoke an agent.

The mode line shows loading, recording, transcribing, or cancelling. No speech
means no inserted comment. Errors appear in `*Org dictation errors*`; results
whose destination became uneditable go to `*Voice dictation recovery*`.
Closing the destination buffer or Emacs cancels capture. Recording times out
after five minutes. Temporary WAV files are removed on normal completion/error/
cancellation; no meeting transcript files are created. A force-kill or system
crash may leave a temporary directory in the system temp location.

The standalone Emacs module is `doom.d/org-dictation.el`. Its customizable
`my/org-dictation-command` defaults to `("note-taker" "--dictate")`. Backend
options include `--language en`, `--source default` (PulseAudio source name),
and `--timeout 300`.

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
installed `note-taker --dictate`. It works with the existing dictation-enabled
package: no rebuild is needed just for this Herdr integration. New package
builds also expose `note-taker --dictation-control <action>`.

The bridge's commands are `start`, `status`, `stop`, `cancel`, and `discard`, with
`--session` after start. They return quickly as JSON; a detached worker owns the
interactive backend. Herdr polls once a second only while active. Polls renew a
lease: loss of the controller cancels capture after 20 seconds. Closing the mod,
changing layouts, or quitting Herdr also requests cancellation. No recording
starts merely by opening the app or loading the mod. F8/Shift+F8 apply while
`my-main` is shown; other layouts need the mod added before binding its commands.

Herdr intercepts its F8 before terminal programs; GUI Emacs has its own binding.
Emacs inside a Herdr terminal receives the same native paste as other programs;
use `SPC a v` there if you specifically want an Org review comment.

## Backend protocol

Stdout contains JSON lines with events `loading`, `recording`, `transcribing`,
and finally `text` with a `text` string. Diagnostics go to stderr. Write
`stop\n` to stdin after `recording` to finish. Closing stdin discards capture;
SIGTERM cancels and cleans up ffmpeg. The mic is not opened until model loading
finishes. `ffmpeg` captures the default PulseAudio input only, never the system
output mix used by meeting recording.

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

Tests mock microphone/inference; they do not record audio or download a model.
An actual microphone/Whisper round trip needs an interactive test.
