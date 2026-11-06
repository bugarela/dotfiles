# Voice input

Personal Herdr mod for the `my-main` layout, using the same local Whisper engine
as Emacs. The microphone button beside the top-right + and **F8** toggle recording.
Wait for Recording, speak, then press F8 again. **Shift+F8** cancels.

When transcription finishes, text is pasted into the original terminal input.
Edit it THERE and press Enter yourself. There is no separate draft editor, Send
button, agent selection, status/turn guard, or automatic submission. Shells,
editors, Claude Code, and Pi all receive the same ordinary terminal paste.
Control characters/newlines are flattened so dictation cannot press Enter.

This uses the system clipboard and Herdr's native `terminal.paste`; it replaces
the clipboard text. It does not call `hc send`. The original terminal must still
be selected when the text is ready. If you switch tabs, the transcript is kept:
return to the original terminal and press F8 to paste. No input is redirected and
focus is never stolen. The status panel is hidden when idle.

Existing drafts from the old UI, interrupted paste attempts, and failures are
kept locally rather than automatically replayed. F8 pastes a kept transcript;
Copy transcript provides manual recovery, and Shift+F8 discards it. If an old
draft had no destination, copy it, discard it, and start F8 from a terminal.

The mod runs local `python3 ~/dotfiles/home-manager/programs/note-taker/dictation_control.py`.
Its detached worker runs installed `note-taker --dictate`, outlasting the UI's
30-second exec limit. Capture is microphone-only; there is no cloud speech API.

The controller's one-second status poll renews a 20-second lease; losing the UI
cancels capture. Closing the mod also requests cancellation. Nothing records on
app/mod load. Pending text is kept in local Herdr state until pasted/discarded.
Private runtime session files are removed on discard; abandoned day-old sessions
are pruned at the next start. Pasted text remains in the system clipboard.

Bindings live in `herdr-app/keys.json`; the personal layout's floating slot owns
the controller. Add it to other personal layouts before routing F8 there. A
terminal Emacs inside Herdr receives Herdr's paste; GUI Emacs has its own F8.

Checks (no real microphone, clipboard, or terminal input in the tests):

```sh
herdr-app check ~/dotfiles/herdr-app/mods/my-dictation
node --experimental-default-type=module --test \
  ~/dotfiles/herdr-app/mods/my-dictation/tests/dictation.test.mjs
```

Backend/setup/test notes: `home-manager/programs/note-taker/README.md` in this repo.
