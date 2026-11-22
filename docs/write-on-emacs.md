# Write On in Emacs

A small Org-native prototype is provided in `doom.d/write-on.el`. No new Emacs package is required.

## Try the prototype

The module is loaded by the Doom configuration after Emacs is restarted. The module can also be loaded into the current session.

```elisp
(load-file "~/dotfiles/doom.d/write-on.el")
```

Run `M-x write-on-demo` to open an editable sample. Write On is enabled automatically in Org buffers by the Doom configuration.

| Key | Action |
| --- | --- |
| `SPC m w g` | Generate alternatives for the selection or word. |
| `SPC m w G` | Generate alternatives with an additional direction. |
| `SPC m w c` | Browse the saved versions at point. |
| `SPC m w a` | Open a draft for your own alternative. |
| `SPC m w s` | Move selected prose to COMMENT Overflow. |
| `SPC m w f` | Keep the visible wording without its alternative wrapper. |
| `SPC m w x` | Cancel the current generation request. |

A side panel is opened and focused for alternatives. Long options are wrapped instead of being truncated.

| Panel key | Action |
| --- | --- |
| `j`, `n`, Down or Tab | Preview the next alternative in the document. |
| `k`, `p`, Up or Shift-Tab | Preview the previous alternative in the document. |
| `RET` | Keep the preview and return to the document. |
| `a` or `A` | Edit the highlighted wording in a capture-style Org buffer. |
| `q` or Escape | Restore the starting wording and close the panel. |

Clicking an alternative also previews the wording. The panel keys work directly, without a leader prefix or an Evil mode change.

Alternatives are labelled “Mine”, “AI” or “Original”. Older alternatives are labelled “Unattributed” because authorship was not recorded by the earlier format. The labels are retained after saving and reopening.

Previewing changes the actual source buffer and highlights the affected passage. Saving is refused until the preview is kept or cancelled. Unrelated edits are preserved when a preview is cancelled.

Normal undo is supported. Suggestions are discarded if the selected text changes during generation. An unrelated edit before the selection is tracked through Emacs markers.

## Write your own alternative

Press `a` or `A` in the panel to open an ordinary Org draft. The highlighted alternative is copied into the draft. No minibuffer editing is required.

The draft is opened in insert mode under Evil. After editing, press Escape and then `SPC m w c` to finish. Press Escape and then `SPC m w k` to cancel.

The standard capture shortcuts are also available. `C-c C-c` finishes the draft, and `C-c C-k` cancels the draft.

Finishing adds your wording as “Mine” and previews your wording in the document. AI alternatives are requested automatically, with your draft treated as the primary brief. Your version remains selected while the suggestions arrive.

The original wording and previous alternatives remain available. Browsing can continue while the request runs. Your version remains available if generation fails.

Line wrapping and paragraph breaks are accepted while editing. The draft is joined into a single paragraph when the draft is finished. A stale source or invalid draft leaves the editor open.

Cancelling the draft leaves the previous preview unchanged and starts no AI request. In the draft editor, `F8` inserts ordinary dictation instead of treating selected text as a rewrite request.

## Ask for substantial changes

The model is instructed to develop ideas rather than preserve the original sentence structure. A request for explanation can produce several sentences instead of a synonym substitution.

For example, select “The cache is cleared” and explain how expired entries are removed. A fuller replacement can describe the process and the next read.

New information that you supply is included in the rewrite brief. Unsupported facts must not be invented. Default suggestions can differ in wording, explanation and organization.

## Give a spoken rewrite instruction

Select prose in an Org buffer and press `F8`. Wait for “Voice: RECORDING”, then describe the change that you want. Press `F8` again to stop recording.

For example, select “The system is good” and say “Make the benefit more concrete”. One AI alternative is generated and previewed in context.

Press `RET` to keep the alternative or `q` to restore the starting wording. Your instruction is not inserted into the document. The generated wording is labelled “AI”.

The selection is captured before recording starts. Moving point or switching buffers does not redirect the rewrite. A changed selection is not overwritten, and your instruction is preserved in `*Voice dictation recovery*`.

Without selected Org prose, `F8` remains ordinary dictation. `Shift+F8` cancels voice capture. `SPC m w x` cancels the subsequent generation request.

Transcription is performed locally through the existing Whisper backend. The instruction, selection and surrounding paragraph are then sent to the configured model provider.

## Use either computer

A terminal Emacs session can be opened over SSH.

```sh
ssh -t your-desktop 'emacs -nw'
```

Alternatively, a remote document can be opened from the laptop through TRAMP.

```text
/ssh:your-desktop:/home/gabriela/drafts/note.org
```

Generation is always run on the machine that runs Emacs. With laptop Emacs and a TRAMP document, Pi and its login are needed on the laptop. With SSH terminal Emacs, Pi is needed on the desktop.

The selection and its surrounding paragraph are sent to the configured model provider. Generation is explicit and may incur provider charges. No generation is performed while typing or during ordinary file saves.

The default command uses Pi in print mode with tools and project context disabled. Existing Pi credentials and the default model are used. A model can be selected through `write-on-command`.

```elisp
(setq write-on-command
      (append write-on-command '("--model" "your-model-id")))
```

The files are not synchronized by this module. TRAMP can be used to edit the same desktop file from either computer. Normal Emacs file-conflict checks remain in effect.

## Keep the file portable

The active wording is stored as an Org link description. Each alternative's text and authorship are stored as JSON in `#+WRITE_ON` keywords in the same file.

For example, “quick” can be chosen instead of “fast”. The exported sentence contains “quick”, while both versions remain available after the file is reopened.

Links are highlighted and can be followed to reopen the alternatives. Link markup can be hidden with normal Org descriptive-link display. A document remains editable without the module, but clean exports require the module's link exporter.

## Proof-of-concept boundaries

Only plain prose is supported for generation. Nested links, square brackets and selections across blank lines are refused. An existing alternative can be targeted at point or by selecting its entire visible wording.

Overflow is kept in COMMENT subtrees instead of being deleted. Prose can be restored with ordinary cut and paste. Ghost rendering, automatic agent handoff and prose-profile evidence collection are not implemented.

Unused metadata is retained after an alternative is flattened or deleted. No machine-specific sidecar is required. Alternative history is not merged automatically after concurrent edits.

## Tests

```sh
emacs --batch -Q -L doom.d -l doom.d/tests/write-on-test.el \
  -l doom.d/tests/org-dictation-test.el \
  -l doom.d/tests/write-on-voice-test.el \
  -l doom.d/tests/write-on-edit-test.el -f ert-run-tests-batch-and-exit
```
