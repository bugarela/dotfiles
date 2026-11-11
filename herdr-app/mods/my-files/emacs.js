// Herdr machine names -> local SSH aliases. No IPs: SSH config owns routing,
// including Tailscale. Add an entry here if a machine is renamed in Herdr.
export const SSH_HOSTS = {
  desktop: "herdr-desktop",
  "gabriela-nixos": "herdr-desktop",
  "herdr-desktop": "herdr-desktop",
};

export function emacsArgs(path, machine) {
  if (!path.startsWith("/") || path.includes("\0") || path.includes("\n")) {
    throw new Error("Open in Emacs requires an absolute Unix file path");
  }
  const host = machine ? SSH_HOSTS[machine] ?? machine : null;
  if (host && !/^[a-zA-Z0-9_.-]+$/.test(host)) {
    throw new Error("Add an SSH alias for this machine in mods/my-files/emacs.js");
  }
  // No shell or Lisp interpolation. -n returns immediately; -a starts a local
  // daemon if needed; -c creates a GUI frame on this computer, never the host.
  return ["-n", "-c", "-a", "", "--", host ? `/ssh:${host}:${path}` : path];
}
