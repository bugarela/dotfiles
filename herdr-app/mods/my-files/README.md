# Files → local Emacs

Click a file in Herdr's Files panel, then **Open in Emacs** above the preview.
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

If a machine is renamed in Herdr, add its name to `SSH_HOSTS` in `emacs.js`.
Unmapped names are treated as local SSH aliases. This configuration must be
available in the laptop's checkout as well; edits hot-reload, no Nix rebuild
is required for the mod itself. SSH configuration changes need the usual
laptop rebuild. Arbitrary terminal file links are not intercepted.

## Checks

```
node --test herdr-app/mods/my-files/tests/emacs.test.mjs
herdr-app check ~/dotfiles/herdr-app/mods/my-files
```

A real laptop-to-desktop click/save test is still required after SSH/Tailscale
is configured; the unit tests and mod check do not establish connectivity.
