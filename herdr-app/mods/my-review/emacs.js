// emacsclient arguments for a file at a line, here or over TRAMP. A mod cannot
// import another mod's files, so this repeats the rules of my-emacs/emacs.js;
// keep SSH_HOSTS in step with the map there.
const SSH_HOSTS = {
  desktop: "herdr-desktop",
  "gabriela-nixos": "herdr-desktop",
  "herdr-desktop": "herdr-desktop",
};

export function emacsArgs(path, machine, line = null) {
  if (!path.startsWith("/") || path.includes("\0") || path.includes("\n")) throw new Error("Not an absolute file path");
  const host = machine ? SSH_HOSTS[machine] ?? machine : null;
  if (host && !/^[a-zA-Z0-9_.-]+$/.test(host)) throw new Error("Add an SSH alias for this machine in mods/my-emacs/emacs.js");
  return ["-n", "-c", "-a", "", "--", ...(line ? [`+${line}`] : []), host ? `/ssh:${host}:${path}` : path];
}
