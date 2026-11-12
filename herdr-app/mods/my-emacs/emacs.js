// Herdr machine names -> local SSH aliases. No IPs: SSH config owns routing,
// including Tailscale. Add an entry here if a machine is renamed in Herdr.
export const SSH_HOSTS = {
  desktop: "herdr-desktop",
  "gabriela-nixos": "herdr-desktop",
  "herdr-desktop": "herdr-desktop",
};

// The desktop's hostname: there, desktop paths are local files.
export const DESKTOP_HOSTNAME = "gabriela-nixos";

// Pasted or selected text -> { path, line, col }. Accepts quotes, file:// URLs,
// ~/, paths relative to `cwd`, and a compiler-style :line[:col] suffix.
export function parsePath(text, { cwd, home }) {
  let s = text.trim().replace(/^(['"`])(.*)\1$/, "$2");
  if (s.startsWith("file://")) s = decodeURIComponent(s.slice("file://".length));
  let line = null, col = null;
  const at = s.match(/^(.*?):(\d+)(?::(\d+))?:?$/);
  if (at) { s = at[1]; line = Number(at[2]); col = at[3] ? Number(at[3]) : null; }
  if (s === "~" || s.startsWith("~/")) s = home + s.slice(1);
  else if (s && !s.startsWith("/") && cwd) s = `${cwd.replace(/\/$/, "")}/${s}`;
  return { path: s, line, col };
}

export function emacsArgs(path, machine, line = null, col = null) {
  if (!path.startsWith("/") || path.includes("\0") || path.includes("\n")) {
    throw new Error("Open in Emacs requires an absolute Unix file path");
  }
  const host = machine ? SSH_HOSTS[machine] ?? machine : null;
  if (host && !/^[a-zA-Z0-9_.-]+$/.test(host)) {
    throw new Error("Add an SSH alias for this machine in mods/my-emacs/emacs.js");
  }
  // emacsclient reads +line[:col] even after --; the path always starts with /.
  const position = line ? [`+${line}${col ? `:${col}` : ""}`] : [];
  // No shell or Lisp interpolation. -n returns immediately; -a starts a local
  // daemon if needed; -c creates a GUI frame on this computer, never the host.
  return ["-n", "-c", "-a", "", "--", ...position, host ? `/ssh:${host}:${path}` : path];
}
