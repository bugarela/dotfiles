// A pinned "jj" tab in every space that is a jj repo, with its log kept on
// screen. It stays last, so tab numbers and the ctrl+digit keys still count
// only the other tabs. Closing it while other tabs are open brings it back.
import { spaces, panes, terminals, exec, hc, run, appHome } from "herdr";

const NAME = "jj";
const RUNNER = "jj-log";
const ARGV = () => [`${appHome()}/mods/my-tabs/${RUNNER}`];
// How long "not a jj repo" holds before asking again: a terminal may cd into one.
const RETRY = 60_000;

export const isPinned = (tab) => tab.named && tab.name === NAME;
export const PINNED_PROGRAM = { name: NAME, icon: "mods/my-workspace-chrome/git-branch.svg", tint: true };

// Remote ids carry a "machine/" prefix; labels on that machine leave it off.
const local = (id) => id.slice(id.indexOf("/") + 1);
const newTabId = () => "tb" + Array.from({ length: 32 }, () => Math.floor(Math.random() * 16).toString(16)).join("");

export class PinnedJj {
  constructor() {
    this.roots = new Map();    // JSON [machine, cwd] -> { root, at }
    this.asking = new Set();   // those keys with a `jj root` in flight
    this.starting = new Map(); // space id -> { tab, at, renamed } until the tab shows, named
    this.shell = new Map();    // pinned tab id -> ticks in a row it hasn't been running jj-log
  }

  tick(cx) {
    const ps = panes();
    for (const space of spaces()) {
      const started = this.starting.get(space.id);
      if (started) {
        const tab = space.tabs.find((t) => t.id === started.tab);
        if (!tab) { if (Date.now() > started.at) this.starting.delete(space.id); continue; }
        if (!isPinned(tab)) {
          if (!started.renamed) { run("tab.rename", { id: tab.id, name: NAME }); started.renamed = true; }
          continue;
        }
        this.starting.delete(space.id);
      }
      const [pinned, ...extra] = space.tabs.filter(isPinned);
      for (const tab of extra) run("tab.close", { id: tab.id, confirmed: true });
      if (pinned) this.keep(space, pinned, ps);
      else if (space.tabs.length) this.start(space, ps, cx);
    }
  }

  keep(space, pinned, ps) {
    const others = space.tabs.filter((t) => !isPinned(t));
    if (!others.length) return;
    if (space.tabs[space.tabs.length - 1].id !== pinned.id) run("tab.move", { id: pinned.id, index: space.tabs.length });
    // After a reboot the core gives a lost terminal a shell, never the old command:
    // start it over. By its foreground process, not `program`: the app files the
    // script under "sh", a shell. Three ticks in a row rule out a flicker.
    const address = ps.find((p) => p.tab === pinned.id)?.terminal;
    const fg = terminals().find((t) => t.address === address)?.foreground?.name;
    const lost = fg != null && fg !== RUNNER;
    const ticks = lost ? (this.shell.get(pinned.id) ?? 0) + 1 : 0;
    if (ticks < 3) { if (ticks) this.shell.set(pinned.id, ticks); else this.shell.delete(pinned.id); return; }
    this.shell.delete(pinned.id);
    run("tab.close", { id: pinned.id, confirmed: true });
  }

  // The first of the space's live folders that is in a jj repo.
  start(space, ps, cx) {
    const tabs = new Set(space.tabs.map((t) => t.id));
    const cwds = new Set(ps.filter((p) => tabs.has(p.tab) && p.cwd).map((p) => p.cwd));
    for (const cwd of cwds) {
      const key = JSON.stringify([space.machine, cwd]);
      const known = this.roots.get(key);
      if (known?.root) return this.launch(space, known.root);
      if (!known || Date.now() - known.at > RETRY) this.ask(key, space.machine, cwd, cx);
    }
  }

  ask(key, on, cwd, cx) {
    if (this.asking.has(key)) return;
    this.asking.add(key);
    cx.spawn(async () => {
      let root = null;
      try {
        // `jj root` alone stops at any .jj above, even a broken one over a git-only repo.
        const opens = await exec("jj", ["log", "--ignore-working-copy", "--no-graph", "-r", "@", "-T", "''"], { cwd, on });
        const r = opens.code === 0 ? await exec("jj", ["root", "--ignore-working-copy"], { cwd, on }) : opens;
        if (r.code === 0) root = r.stdout.trim();
      } catch {}
      this.roots.set(key, { root, at: Date.now() });
      this.asking.delete(key);
    });
  }

  // Through hc, not tab.new: tab.new shows the tab it makes, pulling the window
  // to a space in the background. A labeled terminal becomes a tab quietly.
  launch(space, root) {
    const tab = newTabId();
    const started = { tab: space.machine ? `${space.machine}/${tab}` : tab, at: Date.now() + 15_000, renamed: false };
    this.starting.set(space.id, started);
    hc(["run", "--bg", "--no-parent", "--no-notify", "--cwd", root,
      ...(space.machine ? ["--on", space.machine] : []),
      "--label", `herdr.space=${local(space.id)}`, "--label", `herdr.tab=${tab}`, "--", ...ARGV()])
      .then((r) => { if (r.code !== 0) started.at = Date.now() + RETRY; })
      .catch(() => { started.at = Date.now() + RETRY; });
  }
}
