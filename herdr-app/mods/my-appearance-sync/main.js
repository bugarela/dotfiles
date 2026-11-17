import { View, div } from "gpui-kit";
import { appHome, exec, focused, machines, panes, settings } from "herdr";

// A remote core answers its terminals' color queries (OSC 11, mode 2031)
// with the palette of the app on that machine, not this window's. Mirror this
// window's light/dark onto every connected machine's settings.json.
const SET = `
import json, os, sys
path = os.path.expanduser("~/.config/herdr-app/settings.json")
try:
    with open(path) as f: s = json.load(f)
except FileNotFoundError: s = {}
if s.get("appearance") != sys.argv[1]:
    s["appearance"] = sys.argv[1]
    with open(path, "w") as f: json.dump(s, f, indent=2); f.write("\\n")
`;

// Claude Code's "auto" theme stops listening for scheme changes when the
// terminal doesn't report one right after it asks, which herdr-core doesn't,
// and a terminal off screen reports a default dark palette. So whenever a
// Claude Code agent is on screen and hasn't heard of the current appearance,
// send it the report; it then asks the terminal for its background again.
const SETTLE_MS = 2000; // for the other machine's app to repaint its terminals

export default class AppearanceSync extends View {
  init(_props, cx) {
    this.synced = new Map(); // machine -> appearance written there
    this.told = new Map(); // terminal -> appearance its agent was told
    this.busy = new Set(); // terminals being told
    this.appearance = null;
    this.changedAt = 0;
    cx.timer.every(1000, cx => this.sync(cx));
  }

  sync(cx) {
    const appearance = settings().dark ? "dark" : "light";
    if (appearance !== this.appearance) {
      this.appearance = appearance;
      this.changedAt = Date.now();
    }
    for (const { name, layout } of machines()) {
      if (name === null) continue;
      if (layout !== "ready") { this.synced.delete(name); continue; }
      if (this.synced.get(name) === appearance || this.busy.has(name)) continue;
      this.busy.add(name);
      cx.spawn(async () => {
        const result = await exec("python3", ["-c", SET, appearance], { on: name });
        this.busy.delete(name);
        if (result.code === 0) {
          this.synced.set(name, appearance);
          this.changedAt = Date.now();
        } else {
          this.synced.delete(name);
          console.log(`appearance sync to ${name} failed: ${result.stderr.trim()}`);
        }
      });
    }
    this.tellAgents(cx, appearance);
  }

  tellAgents(cx, appearance) {
    if (Date.now() - this.changedAt < SETTLE_MS) return;
    const tab = focused()?.tab;
    for (const { terminal, app } of panes().filter(p => p.tab === tab)) {
      if (!terminal || app !== "claude-code") continue;
      if (this.told.get(terminal) === appearance || this.busy.has(terminal)) continue;
      const machine = terminal.includes("/") ? terminal.split("/")[0] : null;
      if (machine !== null && this.synced.get(machine) !== appearance) continue;
      this.busy.add(terminal);
      cx.spawn(async () => {
        const script = `${appHome()}/mods/my-appearance-sync/notify.py`;
        const result = await exec("python3", [script, terminal, appearance]);
        this.busy.delete(terminal);
        if (result.code === 0) this.told.set(terminal, appearance);
        else console.log(`telling ${terminal} the appearance failed: ${result.stderr.trim()}`);
      });
    }
  }

  render() {
    return div().w(0).h(0);
  }
}
