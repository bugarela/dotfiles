# Herdr over Tailscale

## Security boundary

Herdr already uses SSH and can execute arbitrary commands as Gabriela. Forcing
`hc connect` would not provide a meaningful sandbox. This setup uses ordinary
OpenSSH, not Tailscale SSH. No Herdr TCP listener, router port forwarding,
Funnel, subnet router, or exit node is needed.

The **tailnet policy** is what restricts access: only the tagged laptop may
reach the tagged desktop, only on TCP 22. Reply traffic is allowed automatically.
Do not add `tailscale0` to NixOS's trusted interfaces. Existing LAN services and
firewall openings are unchanged.

## First-time setup

1. In the Tailscale admin console, replace the default allow-all access policy
   with [herdr-tailnet-policy.json](herdr-tailnet-policy.json).
   **Do this before connecting either machine.** Do not retain a wildcard ACL
   or grant: permissions are additive. This policy is for a dedicated tailnet;
   replacing an existing policy will remove other devices' access.
2. Confirm that the laptop's 1Password SSH agent offers the configured public
   key (the one already used for Git signing):
   ```sh
   SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -L
   ```
   If a different key is intended for desktop login, change
   `users.users.gabriela.openssh.authorizedKeys.keys` in `nixos/desktop.nix`
   before rebuilding. Private keys remain in 1Password.
3. Apply the dotfiles on **each** machine:
   ```sh
   # Desktop
   sudo nixos-rebuild switch --impure --flake .#desktop
   # Laptop
   sudo nixos-rebuild switch --impure --flake .#laptop
   ```
   `--impure` is needed by the existing Firefox/NUR configuration.
4. Authenticate each machine, initially blocking all incoming tailnet traffic:
   ```sh
   sudo tailscale up --shields-up
   ```
   Open the login URL on each machine. In the admin console, assign exactly
   one device `tag:herdr-laptop` and exactly one `tag:herdr-desktop`.
   Do not assign the laptop tag to other devices. Leave route/exit-node
   advertisements, Tailscale SSH, Serve and Funnel disabled.
5. On the **desktop only**, allow incoming traffic governed by the policy:
   ```sh
   sudo tailscale set --shields-up=false
   ```
   The laptop remains shields-up. Check the policy tests in the admin console.
6. On the laptop:
   ```sh
   tailscale status
   ssh herdr-desktop true
   ```
   `herdr-desktop` is an SSH alias for the desktop's MagicDNS name
   `gabriela-nixos`. If that name was renamed or suffixed in Tailscale, update
   `HostName` in `home-manager/laptop.nix`. MagicDNS must be enabled.
   Verify the first SSH host-key fingerprint against the desktop, not blindly.
   On the desktop, `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` shows it.

## Working remotely

On the **laptop**, with 1Password running and its SSH agent enabled:

```sh
systemctl --user start herdr-agent-forward
systemctl --user status herdr-agent-forward

# Once: register the SSH alias in the laptop's Herdr.
hc machine add herdr-desktop --name desktop
```

Select that desktop machine in Herdr. If you already registered its LAN address,
this adds another entry; after verifying it, remove the old entry with
`hc machine rm <old-name>`. Do not use `--install`: both machines have hc via Nix.

Test a Git fetch from an **existing desktop Herdr terminal**. Approval should
appear in the laptop's 1Password, not the desktop's. An independent SSH check
from the laptop is:

```sh
ssh herdr-desktop 'ssh -T git@github.com'
```

GitHub's successful authentication greeting still exits with status 1.
`ssh-add -l` in an existing Herdr terminal is not a valid test: its old
environment can still point to the desktop agent. Git's OpenSSH client
uses the configured `IdentityAgent` instead.

When done, on the laptop:

```sh
systemctl --user stop herdr-agent-forward
ssh herdr-desktop 'rm -f /home/gabriela/.ssh/herdr-laptop-agent.sock'
```

The service is intentionally **not enabled at login**. It retries if the network
drops while started. Inspect failures with:

```sh
journalctl --user -u herdr-agent-forward -n 50
```

## Why a separate agent tunnel?

On Linux, Herdr intentionally does not inherit an SSH login's `SSH_AUTH_SOCK`
into its persistent systemd services. Ordinary `ForwardAgent yes` alone would
therefore not fix Git inside existing Herdr terminals.

The dedicated tunnel forwards the laptop's 1Password socket to
`/home/gabriela/.ssh/herdr-laptop-agent.sock` on the desktop. Desktop OpenSSH
prefers that socket when present, otherwise the ordinary forwarded agent or
local 1Password. Jujutsu on the desktop uses Git's subprocess backend so it also
honors this SSH configuration.

A stale socket can remain after a disconnect. Reconnecting the service replaces
it; removing it with the command above restores local 1Password selection.
Until then, fetch may fail rather than silently fall back. No Herdr restart
or desktop unlock is required.

**Trust:** while the tunnel is running, processes with your desktop UID (and
desktop root) can request signatures from the laptop agent, including outside
Herdr. Private keys are not copied; 1Password's approval/caching policy still
applies. Stop the tunnel when not needed. This changes fetch/SSH authentication,
not the existing Git/Jujutsu `op-ssh-sign` commit-signing configuration.

## Validate the restriction

From the laptop, `ssh herdr-desktop true` should work while direct connections
to desktop ports 443 and 7000 over its Tailscale IP should fail. Another tailnet
device must not reach desktop port 22. Desktop-initiated connections to the
laptop are denied. Use the admin console's policy tests as well; a failed
connection alone might only mean no service was listening.

The tailnet policy in [herdr-tailnet-policy.json](herdr-tailnet-policy.json) has
been uploaded to the admin console; keep the two in sync if either changes.
These dotfile changes do not perform any system switch or Tailscale login.
