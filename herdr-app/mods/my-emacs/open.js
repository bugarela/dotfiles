// Open a path from pasted or selected text in this computer's Emacs, over TRAMP when remote.
import { exec, home, spaces, panes } from "herdr";
import { SSH_HOSTS, DESKTOP_HOSTNAME, emacsArgs, parsePath } from "./emacs.js";

export const sameMachine = (a, b) => (a ? SSH_HOSTS[a] ?? a : null) === (b ? SSH_HOSTS[b] ?? b : null);

export async function onDesktop() {
  const result = await exec("hostname");
  return result.stdout.trim() === DESKTOP_HOSTNAME;
}

export function spaceOfPane(pane) {
  const tab = panes().find(p => p.pane === pane)?.tab;
  return spaces().find(s => s.tabs?.some(t => t.id === tab)) ?? null;
}

export async function clipboard() {
  const result = await exec("xclip", ["-o", "-selection", "clipboard"]).catch(() => null);
  return result?.code === 0 ? result.stdout : "";
}

// Pasted text, not a document: one line that could be a path.
export const looksLikePath = text => Boolean(text.trim()) && !text.trim().includes("\n") && text.length < 4096;

export async function openInEmacs(text, machine, cwd) {
  const { path, line, col } = parsePath(text, { cwd, home: home() });
  const result = await exec("emacsclient", emacsArgs(path, machine, line, col));
  if (result.code !== 0) throw new Error(result.stderr.trim() || "emacsclient failed");
}

// Text shown by a terminal on `machine` names a file there. A local terminal on
// the laptop is usually showing an SSH session, so a missing file means the desktop.
export async function machineForText(text, machine, cwd) {
  if (machine) return machine;
  const { path } = parsePath(text, { cwd, home: home() });
  const here = await exec("test", ["-e", path]).catch(() => null);
  return here?.code === 0 || (await onDesktop()) ? null : "desktop";
}
