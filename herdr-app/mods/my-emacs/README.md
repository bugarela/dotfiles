# Open in Emacs

Three ways in, all opening the file in **this** computer's Emacs:

- **Ctrl+Shift+F**, or the file icon next to the microphone: paste a path
  (the clipboard prefills it), pick where the file is (Desktop / This
  computer; a remote space adds its machine), Enter. Accepts `~/`, quotes,
  `file://`, paths relative to the focused terminal, and `path:line[:col]`.
- **Right-click a terminal → Open selection in Emacs**: copies the selected
  text and opens it on the machine that terminal runs on. From a local
  terminal on the laptop, a path that doesn't exist locally means the desktop
  (an SSH session). Nothing selected or a bad path leaves the dialog open.
  Left-clicking a selection can't be hooked: terminals keep their presses.
- **Files panel → Open in Emacs** above a preview.

The GUI runs on the computer displaying Herdr, even in a remote space. Local
files open directly; remote files open through SSH/TRAMP. Saving writes back
to the original machine. `emacsclient -n -c -a ""` reuses the local server or
starts a daemon if none is running. Emacs is already enabled in Home Manager.

## Laptop / Tailscale

The desktop's Herdr names `desktop`, `gabriela-nixos`, and `herdr-desktop`
map to the laptop's existing SSH alias `herdr-desktop`. Keep that alias's
`HostName` pointed at the desktop's Tailscale MagicDNS name or Tailscale IP
in `home-manager/laptop.nix` (networking is managed separately).

First verify `ssh herdr-desktop true` on the laptop; accept the verified host
key and ensure SSH authentication works. Add the machine to Herdr's Machines
settings with the same SSH alias if not already connected. No desktop Emacs
server, X forwarding, or Emacs TCP listener is needed.

If a machine is renamed in Herdr, add its name to `SSH_HOSTS` in `mods/my-emacs/emacs.js`.
Unmapped names are treated as local SSH aliases. The terminal menu is `my-menu` (a clone of `menu`), set as
`terminal_menu` in `layouts/my-main.json`. This configuration must be
available in the laptop's checkout as well; edits hot-reload, no Nix rebuild
is required for the mod itself. SSH configuration changes need the usual
laptop rebuild. Arbitrary terminal file links are not intercepted.

## Checks

```
node --test herdr-app/mods/my-emacs/tests/emacs.test.mjs
for m in my-emacs my-menu my-tabs my-files; do herdr-app check ~/dotfiles/herdr-app/mods/$m; done
```

A real laptop-to-desktop click/save test is still required after SSH/Tailscale
is configured; the unit tests and mod check do not establish connectivity.
