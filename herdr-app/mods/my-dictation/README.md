# Voice drafts

Personal Herdr mod for the `my-main` layout. Uses the same local Whisper backend
as Emacs. A compact microphone button beside the top-right + starts/stops
recording. The draggable status/draft panel appears only during an active session;
there is no floating button when idle.

- **F8** starts/stops recording; wait for the Recording indicator before speaking.
- **Shift+F8** cancels capture or discards a draft.
- Edit the transcription, then click **Send to original agent** to submit it.
  Sending includes Enter and is never automatic. Only the original agent is a
  destination; switching tabs cannot redirect the draft. Shells are never sent
  dictated input. Working/blocked/missing agents leave the draft intact.
- Without a focused agent, dictation still works but the result must be copied
  from the editable draft. No Send button is offered.

Runs local `python3 ~/dotfiles/home-manager/programs/note-taker/dictation_control.py`
for short start/status/stop/cancel/discard requests. Its detached worker runs the
installed `note-taker --dictate` and keeps microphone capture out of the UI's
30-second exec limit. The bridge needs Python's standard library only.

The controller's one-second status poll renews a 20-second lease; losing the UI
cancels capture. Closing the mod also requests cancellation. No recording starts
on app/mod load. Draft text is kept in local Herdr shared state until sent or
discarded; private runtime session files are removed on discard, with abandoned
day-old sessions pruned at the next start. No cloud speech service is used.

Bindings live in `herdr-app/keys.json`; the personal layout's floating slot owns
the mod. Add it to other personal layouts before routing F8 there. If a terminal
Emacs is nested inside Herdr, the outer app owns F8; GUI Emacs uses its own F8.

Check after any mod change:

```sh
herdr-app check ~/dotfiles/herdr-app/mods/my-dictation
```

Full backend/setup/test notes: `home-manager/programs/note-taker/README.md` in
this dotfiles repository.
