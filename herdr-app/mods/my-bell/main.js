// The Bell panel: what ~/org/bell.org holds for Gabriela, rendered, with an
// item's options as buttons and a box to answer or reply. A message goes back
// to whoever filed the item: the live Claude session that its source names
// (`session:<id>:<slug>`), else that session resumed in a new tab, else a new
// agent handed the item. bell.org stays the store, so Org's agenda keeps it;
// writes go through ~/kitchen/kitchen, which edits her Emacs buffer when open.
// Items are archived to ~/org/bell_archive.txt one at a time or in a batch, and
// Check relevance starts /bell-triage, whose verdicts mark the stale ones.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, TextView, TextareaState, Textarea } from "gpui-base";
import { exec, hc, home, readTextFile, writeTextFile, terminals, spaces, panes, theme, run, layout, props } from "herdr";
import { parseBell, parseOptions } from "./items.js";

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const SESSION = /^session:([0-9a-f][0-9a-f-]{7,})(?::|$)/;
// One call per poll: bell.org's stamp, then the newest triage run's folder,
// whether it finished, its run.json and its verdict lines.
const POLL = 'stat -L -c "%Y %s %i" "$1" || exit 3; d=$(ls -1td "$2"/*/ 2>/dev/null | head -n1); printf "%s\\n" "${d%/}"; '
  + '[ -n "$d" ] || exit 0; if [ -e "$d/summary.md" ]; then echo finished; else echo running; fi; '
  + 'tr -d "\\n" < "$d/run.json" 2>/dev/null; echo; cat "$d"/verdicts-*.jsonl 2>/dev/null; true';

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const elisp = (s) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
const clip = (s, n) => s.length > n ? `${s.slice(0, n - 1)}…` : s;
const midnight = (ms) => { const d = new Date(ms); return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime(); };

function day(ms) {
  const ago = Math.round((midnight(Date.now()) - midnight(ms)) / 86400000), d = new Date(ms);
  return ago === 0 ? "Today" : ago === 1 ? "Yesterday" : `${DAYS[d.getDay()]} ${d.getDate()} ${MONTHS[d.getMonth()]}`;
}
const pad = (n) => String(n).padStart(2, "0");
const clock = (ms) => { const d = new Date(ms); return `${pad(d.getHours())}:${pad(d.getMinutes())}`; };

export default class Bell extends View {
  init(_props, cx) {
    this.home = home(); this.file = `${this.home}/org/bell.org`; this.triageRoot = `${this.home}/.local/state/bell-triage`;
    this.items = []; this.sig = null; this.parsed = {}; this.sessions = {}; this.transcripts = {};
    this.tab = "waiting"; this.openId = null; this.choice = null; this.drafts = {}; this.text = "";
    this.selected = {}; this.triage = null; this.verdicts = {}; this.undo = null;
    this.note = null; this.confirm = null; this.error = null;
    this.reply = TextareaState.new({ placeholder: "Answer, or reply to discuss it first" });
    this.reply.set_auto_grow(2, 10);
    this.reply.on("change", (_e, cx) => { this.text = this.reply.value(); cx.notify(); });
    this.load(cx);
    cx.timer.every(4000, (cx) => { if (this.shown()) this.load(cx); });
  }

  // Hidden copies keep their timers, so work only while the panel shows.
  shown() {
    if (props()?.overlay) return true;
    const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
    return !body || (panel && !panel.hidden && body.active === "bell");
  }

  // bell.org is reread only when Emacs or MEGA replaced or changed it.
  load(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const poll = await exec("sh", ["-c", POLL, "sh", this.file, this.triageRoot]);
        if (poll.code !== 0) throw new Error(`No bell at ${this.file}`);
        const lines = poll.stdout.split("\n");
        if (lines[0] !== this.sig) {
          const r = await exec("cat", [this.file]);
          if (r.code !== 0) throw new Error(r.stderr.trim() || "Cannot read bell.org");
          this.items = parseBell(r.stdout); this.parsed = {}; this.sig = lines[0];
          const ids = new Set(this.items.map(i => i.id));
          for (const id of Object.keys(this.selected)) if (!ids.has(id)) delete this.selected[id];
        }
        this.readTriage(lines);
        this.sessions = await this.liveSessions();
        this.error = null;
      } catch (e) { this.error = String(e.message ?? e); }
      finally { this.loading = false; cx.notify(); }
    });
  }

  readTriage(lines) {
    if (!lines[1]) { this.triage = null; this.verdicts = {}; return; }
    let run = {};
    try { run = JSON.parse(lines[3] || "{}"); } catch {}
    const verdicts = {};
    for (const line of lines.slice(4)) {
      try { const v = JSON.parse(line); if (v?.id && v.verdict) verdicts[v.id] = v; } catch {}
    }
    this.triage = { dir: lines[1], finished: lines[2] === "finished", started: run.started ?? null, count: run.count ?? null };
    this.verdicts = verdicts;
  }

  // Claude Code keeps ~/.claude/sessions/<pid>.json for each running session,
  // and a herdr terminal's foreground pid is that pid.
  async liveSessions() {
    const sessions = {};
    for (const t of terminals()) {
      const fg = t.foreground;
      if (t.state !== "live" || t.address.includes("/") || !fg?.pid || !/claude/.test(`${fg.name} ${fg.argv?.[0]}`)) continue;
      const text = await readTextFile(`${this.home}/.claude/sessions/${fg.pid}.json`).catch(() => null);
      try {
        const s = JSON.parse(text ?? "null");
        if (s?.sessionId && s.pid === fg.pid) sessions[s.sessionId] = t.address;
      } catch {}
    }
    return sessions;
  }

  // A session that ended resumes where it ran: its transcript is
  // ~/.claude/projects/<folder slug>/<id>.jsonl, and its lines carry `cwd`.
  findTranscript(prefix, cx) {
    if (prefix in this.transcripts) return;
    this.transcripts[prefix] = undefined;
    cx.spawn(async (cx) => {
      let found = null;
      try {
        const r = await exec("find", [`${this.home}/.claude/projects`, "-maxdepth", "2", "-name", `${prefix}*.jsonl`]);
        const path = r.stdout.split("\n").find(Boolean);
        if (path) {
          const g = await exec("grep", ["-m1", "-o", '"cwd":"[^"]*"', path]);
          const cwd = g.code === 0 ? JSON.parse(`{${g.stdout.split("\n")[0]}}`).cwd : null;
          if (cwd) found = { session: path.split("/").pop().replace(/\.jsonl$/, ""), cwd };
        }
      } catch {}
      this.transcripts[prefix] = found;
      cx.notify();
    });
  }

  liveTerminal(prefix) {
    const id = prefix && Object.keys(this.sessions).find(s => s.startsWith(prefix));
    return id ? terminals().find(t => t.address === this.sessions[id] && t.state === "live") ?? null : null;
  }

  route(item) {
    const prefix = SESSION.exec(item.source)?.[1];
    if (!prefix) return { kind: "new" };
    const terminal = this.liveTerminal(prefix);
    if (terminal) return { kind: "live", terminal };
    const found = this.transcripts[prefix];
    return found ? { kind: "resume", ...found } : { kind: found === undefined ? "looking" : "new", prefix };
  }

  options(item) {
    if (!this.parsed[item.id]) this.parsed[item.id] = parseOptions(item.body);
    return this.parsed[item.id];
  }

  agentName(t) {
    const tab = spaces().flatMap(s => s.tabs).find(x => x.id === t.labels?.["herdr.tab"]);
    return [t.title, tab?.name].filter(Boolean).join(" · ") || t.name || t.address;
  }

  // A new tab goes to the local space already working in that folder.
  spaceFor(cwd) {
    const local = spaces().filter(s => !s.machine);
    const owner = (tab) => local.find(s => s.tabs.some(x => x.id === tab))?.id;
    const pane = cwd ? panes().find(p => p.cwd === cwd && owner(p.tab)) : null;
    return (pane && owner(pane.tab)) ?? local.find(s => cwd && s.folder === cwd)?.id ?? local.find(s => s.active)?.id ?? local[0]?.id;
  }

  // An answer is resolved in the bell already, so the agent only acts on it; a
  // reply leaves the item waiting.
  message(item, text, answer) {
    return `${answer ? "Answer to" : "Reply about"} bell item ${item.id} (${item.title}), ${answer ? "resolved in the bell already" : "still waiting in the bell"}:\n\n${text}`;
  }

  brief(item, text, answer) {
    return [
      `Gabriela ${answer ? "answered" : "replied to"} an item in her bell (~/org/bell.org) from the Herdr panel, and no session that filed it is left to act on it.`,
      answer ? "Carry out her answer as the agent that filed it would have. The item is resolved already."
        : `Discuss it with her here. Once she decides, carry it out and resolve the item with \`~/kitchen/bell resolve ${item.id}\`.`,
      "", `Item ${item.id}, source ${item.source || "unknown"}:`, "", `# ${item.title}`, "", item.body, "",
      answer ? "Her answer:" : "Her reply:", "", text,
    ].join("\n");
  }

  send(item, answer, cx) {
    const chosen = this.choice?.id === item.id ? this.options(item).options.find(o => o.letter === this.choice.letter) : null;
    const typed = this.reply.value().trim();
    const text = chosen ? `${chosen.letter}: ${chosen.text}${typed ? `\n\n${typed}` : ""}` : typed;
    const route = this.route(item);
    if (!text || route.kind === "looking") return;
    this.act(cx, answer ? "Answering" : "Sending", async () => {
      let done;
      if (route.kind === "live") {
        const r = await hc(["send", route.terminal.address, this.message(item, text, answer)]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || "hc send failed");
        done = `Sent to ${this.agentName(route.terminal)}`;
      } else if (route.kind === "resume") {
        run("tab.new", { name: "bell", space: this.spaceFor(route.cwd), folder: route.cwd, argv: ["claude", "--resume", route.session], task: this.message(item, text, answer) });
        done = "Its session resumes in a new tab";
      } else {
        run("tab.new", { name: "bell", space: this.spaceFor(null), folder: this.home, argv: ["claude"], task: this.brief(item, text, answer) });
        done = "A new agent has it in a new tab";
      }
      this.reply.set_value(""); this.text = ""; delete this.drafts[item.id]; this.choice = null;
      if (!answer) return done;
      await this.resolve(item, text);
      return `${done}, and the item is resolved`;
    });
  }

  // Later answer lines are indented so that none starts an Org heading.
  async resolve(item, answer) {
    const done = await this.kitchen("kitchen-bell-resolve", [item.id], ...(answer ? [answer.replace(/\n/g, "\n  ")] : []));
    if (!done.length) throw new Error("The item is no longer in bell.org");
  }

  // board.el's bell functions answer "ok", or "not-found" for an ID that the
  // file lacks. One Emacs call runs FN over every ID and returns the IDs it
  // found.
  async kitchen(fn, ids, ...args) {
    if (!ids.every(id => /^[A-Za-z0-9-]+$/.test(id))) throw new Error("Unexpected item ID");
    const extra = args.map(a => ` ${elisp(a)}`).join("");
    const r = await exec(`${this.home}/kitchen/kitchen`, [`(mapconcat (lambda (id) (${fn} id${extra})) '(${ids.map(id => `"${id}"`).join(" ")}) " ")`]);
    this.sig = null;
    const out = r.stdout.trim().split(/\s+/);
    if (r.code !== 0 || out.length !== ids.length || out.some(o => o !== "ok" && o !== "not-found")) throw new Error(r.stdout.trim() || r.stderr.trim() || `${fn} failed`);
    return ids.filter((_, i) => out[i] === "ok");
  }

  // Archiving takes no confirmation, since Undo moves the items back.
  archive(ids, cx) {
    if (!ids.length) return;
    this.act(cx, ids.length > 1 ? `Archiving ${ids.length} items` : "Archiving", async () => {
      const done = await this.kitchen("kitchen-bell-archive", ids);
      for (const id of ids) delete this.selected[id];
      if (ids.includes(this.openId)) this.openId = null;
      this.undo = done;
      return `Archived ${done.length === 1 ? "1 item" : `${done.length} items`} to bell_archive.txt`;
    });
  }

  unarchive(cx) {
    const ids = this.undo ?? [];
    this.act(cx, "Moving them back", async () => {
      const done = await this.kitchen("kitchen-bell-unarchive", ids);
      return `Moved ${done.length === 1 ? "1 item" : `${done.length} items`} back to bell.org`;
    });
  }

  // The triage gets the list as shown, written to its run folder, and its
  // verdicts come back through the same folder.
  startTriage(cx) {
    const waiting = this.waiting(), t = this.triage;
    if (!waiting.length) return;
    if (t && !t.finished && Date.now() - (t.started ?? 0) < 3600000 && !this.armed(cx, "triage")) return;
    const d = new Date();
    const dir = `${this.triageRoot}/${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
    this.act(cx, "Starting the relevance check", async () => {
      const r = await exec("mkdir", ["-p", dir]);
      if (r.code !== 0) throw new Error(r.stderr.trim() || `Cannot make ${dir}`);
      const items = waiting.map(i => ({ id: i.id, title: i.title, source: i.source, created: i.created ? new Date(i.created).toISOString() : null, body: i.body }));
      await writeTextFile(`${dir}/items.json`, JSON.stringify(items, null, 1), null);
      await writeTextFile(`${dir}/run.json`, JSON.stringify({ started: Date.now(), count: items.length }), null);
      run("tab.new", { name: "bell triage", space: this.spaceFor(null), folder: this.home, argv: ["claude"], task: `/bell-triage ${dir}` });
      return `Checking ${items.length} items in a new tab`;
    });
  }

  waiting() {
    return this.items.filter(i => i.state === "TODO").sort((a, b) => (b.created ?? 0) - (a.created ?? 0) || b.line - a.line);
  }

  dismiss(item, cx) {
    if (!this.armed(cx, `resolve-${item.id}`)) return;
    this.act(cx, "Resolving", async () => { await this.resolve(item, null); return "Resolved without an answer"; });
  }

  goTo(item, cx) {
    const route = this.route(item);
    if (route.kind === "live") run("agent.focus", { terminal: route.terminal.address });
    else if (route.kind === "resume") {
      run("tab.new", { name: "bell", space: this.spaceFor(route.cwd), folder: route.cwd, argv: ["claude", "--resume", route.session] });
      this.note = { text: "Its session resumes in a new tab", error: false };
      cx.notify();
    }
  }

  openEmacs(item, cx) {
    this.act(cx, "Opening in Emacs", async () => {
      const r = await exec("emacsclient", ["-n", "-c", "-a", "", "--", `+${item.line}`, this.file]);
      if (r.code !== 0) throw new Error(r.stderr.trim() || "emacsclient failed");
      return "Opened in Emacs";
    });
  }

  toggle(item, cx) {
    if (this.openId) this.drafts[this.openId] = this.reply.value();
    this.openId = this.openId === item.id ? null : item.id;
    if (this.openId) this.reply.set_value(this.drafts[this.openId] ?? "");
    this.text = this.reply.value(); this.confirm = null;
    cx.notify();
  }

  act(cx, label, work) {
    this.note = { text: `${label}…`, error: false }; this.undo = null;
    cx.spawn(async (cx) => {
      try { this.note = { text: await work(), error: false }; }
      catch (e) { this.note = { text: String(e.message ?? e), error: true }; }
      this.load(cx); cx.notify();
    });
    cx.notify();
  }

  // Resolving without an answer, and restarting a running check, take a second
  // click within four seconds.
  armed(cx, name) {
    if (this.confirm?.name === name && Date.now() < this.confirm.until) { this.confirm = null; return true; }
    this.confirm = { name, until: Date.now() + 4000 };
    cx.timer.after(4100, (cx) => cx.notify());
    cx.notify();
    return false;
  }

  render(cx) {
    const t = theme();
    const waiting = this.waiting();
    const resolved = this.items.filter(i => i.state === "DONE").sort((a, b) => (b.resolved ?? 0) - (a.resolved ?? 0));
    const list = this.tab === "resolved" ? resolved : waiting;
    const chosen = list.filter(i => this.selected[i.id]).map(i => i.id);
    const stale = waiting.filter(i => this.verdicts[i.id]?.verdict === "stale").map(i => i.id);
    const pill = (text, color) => div().flex_none().px(6).py(1).rounded(4).border_1().border_color(color ?? t.border).text_size(10.5).text_color(color ?? t.muted).child(text);
    const link = (id, text, action) => div().id(`bell-${id}`).flex_none().text_size(11).text_color(t.accent).cursor_pointer().on_click((_e, cx) => action(cx)).child(text);
    const tabButton = (id, label) => div().id(`bell-tab-${id}`).px(10).h(28).flex().items_center().text_size(12).cursor_pointer()
      .border_b(2).border_color(this.tab === id ? t.accent : t.chrome).text_color(this.tab === id ? t.foreground : t.muted)
      .on_click((_e, cx) => { this.tab = id; cx.notify(); }).child(label);
    const select = (ids, on) => (cx) => { for (const id of ids) { if (on) this.selected[id] = true; else delete this.selected[id]; } cx.notify(); };

    const header = v_flex().flex_none().px(14).pt(12).pb(8).gap(8).border_b(1).border_color(t.border)
      .child(h_flex().gap(8).items_center()
        .child(div().font_semibold().child("Bell"))
        .child(div().flex_1())
        .when(this.loading && !this.sig, e => e.child(svg("mods/workspace-chrome/spinner.svg").size(12).text_color(t.dim).spin(900)))
        .child(link("emacs", "bell.org", (cx) => this.openEmacs({ line: 1 }, cx)))
        .child(this.button("triage", "Check relevance", (cx) => this.startTriage(cx), t,
          { enabled: waiting.length > 0, tip: "Agents read every waiting item and mark the ones that no longer need you" })))
      .when(Boolean(this.note), e => e.child(h_flex().gap(8).items_start()
        .child(div().flex_1().min_w(0).text_size(11.5).text_color(this.note.error ? t.ansi1 : t.muted).child(this.note.text))
        .when(Boolean(this.undo?.length), e => e.child(link("undo", "Undo", (cx) => this.unarchive(cx))))))
      .when(Boolean(this.triage), e => e.child(this.triageLine(waiting, t)))
      .child(h_flex().gap(6).items_center().flex_wrap()
        .when(chosen.length > 0, e => e
          .child(this.button("archive-selected", `Archive ${chosen.length}`, (cx) => this.archive(chosen, cx), t, { primary: true, tip: "Move the selected items to bell_archive.txt" }))
          .child(this.button("clear", "Clear", select(chosen, false), t)))
        .when(chosen.length < list.length, e => e.child(this.button("select-all", "Select all", select(list.map(i => i.id), true), t)))
        .when(this.tab === "waiting" && stale.some(id => !this.selected[id]), e => e.child(this.button("select-stale", `Select stale ${stale.length}`, select(stale, true), t,
          { tip: "Select the items the relevance check found stale" }))))
      .child(h_flex().gap(2).mb(-8)
        .child(tabButton("waiting", `Waiting${waiting.length ? ` ${waiting.length}` : ""}`))
        .child(tabButton("resolved", `Resolved${resolved.length ? ` ${resolved.length}` : ""}`)));

    let body = v_flex().id("bell-body").flex_1().min_h(0).overflow_y_scrollbar().px(10).pb(14).gap(2).text_size(12.5);
    if (this.error) body = body.child(div().pt(12).px(4).text_color(t.ansi1).child(this.error));
    else if (!list.length) body = body.child(div().pt(12).px(4).text_color(t.dim).child(!this.sig ? "Loading…" : this.tab === "waiting" ? "Nothing waits on you." : "Nothing resolved."));
    else {
      const when = (i) => this.tab === "resolved" ? i.resolved : i.created;
      const groups = [];
      for (const item of list) {
        const label = when(item) ? day(when(item)) : "Undated";
        if (groups[groups.length - 1]?.label !== label) groups.push({ label, items: [] });
        groups[groups.length - 1].items.push(item);
      }
      for (const g of groups) {
        const ids = g.items.map(i => i.id), all = ids.every(id => this.selected[id]);
        body = body.child(h_flex().pt(10).pb(2).px(4).items_center()
          .child(div().flex_1().text_size(11).font_semibold().text_color(t.dim).child(g.label.toUpperCase()))
          .child(link(`day-${g.label}`, all ? "unselect" : "select", select(ids, !all))));
        body = body.children(g.items.map(item => this.row(item, t, pill, cx)));
      }
    }
    return v_flex().id("bell").size_full().min_h(0).rounded(4).overflow_hidden().bg(t.background).border_1().border_color(t.border)
      .text_color(t.foreground).child(header).child(body);
  }

  triageLine(waiting, t) {
    const tr = this.triage, shown = waiting.filter(i => this.verdicts[i.id]);
    const count = (v) => shown.filter(i => this.verdicts[i.id].verdict === v).length;
    const checked = Object.keys(this.verdicts).length;
    const text = tr.finished
      ? `Relevance check ${tr.started ? `of ${day(tr.started).toLowerCase()} ${clock(tr.started)}` : "finished"}: ${count("stale")} stale, ${count("keep")} to keep, ${count("unsure")} unsure`
      : Date.now() - (tr.started ?? 0) < 7200000
        ? `Relevance check running: ${checked}${tr.count ? ` of ${tr.count}` : ""} checked`
        : `Relevance check stopped after ${checked}${tr.count ? ` of ${tr.count}` : ""}`;
    return h_flex().gap(6).items_center()
      .when(!tr.finished && Date.now() - (tr.started ?? 0) < 7200000, e => e.child(svg("mods/workspace-chrome/spinner.svg").size(11).text_color(t.working).spin(900)))
      .child(div().text_size(11.5).text_color(t.muted).child(text));
  }

  row(item, t, pill, cx) {
    const open = this.openId === item.id, done = item.state === "DONE", checked = Boolean(this.selected[item.id]);
    const prefix = SESSION.exec(item.source)?.[1];
    const live = !done && this.liveTerminal(prefix);
    const verdict = done ? null : this.verdicts[item.id];
    const slug = item.source.split(":").pop();
    const meta = done ? `resolved ${item.resolved ? clock(item.resolved) : ""}${item.answer ? " · answered" : ""}`
      : `${item.created ? clock(item.created) : ""} · ${slug}`;
    const head = h_flex().id(`bell-item-${item.id}`).gap(8).px(6).py(7).items_start().rounded(4).cursor_pointer()
      .when(!open, e => e.hover(s => s.bg(t.hover)))
      .on_click((_e, cx) => this.toggle(item, cx))
      .child(div().id(`bell-check-${item.id}`).flex_none().mt(2).size(15).rounded(3).border_1().flex().items_center().justify_center()
        .border_color(checked ? t.accent : t.input).bg(checked ? t.accent : t.background).text_size(10).text_color(t.accent_foreground)
        .on_click((_e, cx) => { cx.stop_propagation(); if (checked) delete this.selected[item.id]; else this.selected[item.id] = true; cx.notify(); })
        .when(checked, e => e.child("✓")))
      .child(v_flex().flex_1().min_w(0).gap(2)
        .child(div().text_size(12.5).when(open, e => e.font_semibold()).text_color(done ? t.muted : t.foreground).child(item.title))
        .child(h_flex().gap(6).text_size(11).text_color(t.dim)
          .child(div().min_w(0).truncate().child(meta))
          .when(Boolean(live), e => e.child(div().flex_none().text_color(t.done).child("agent live"))))
        .when(Boolean(verdict), e => e.child(h_flex().pt(2).gap(6).items_start()
          .child(pill(verdict.verdict, { stale: t.blocked, keep: t.done }[verdict.verdict] ?? t.muted))
          .child(div().flex_1().min_w(0).text_size(11).text_color(t.muted).child(verdict.reason ?? "")))))
      .child(div().id(`bell-archive-${item.id}`).flex_none().p(4).rounded(4).text_color(t.dim).cursor_pointer()
        .hover(s => s.bg(t.selected).text_color(t.foreground))
        .on_click((_e, cx) => { cx.stop_propagation(); this.archive([item.id], cx); })
        .child(svg("mods/my-bell/archive.svg").size(14)).tooltip("Archive: move it to bell_archive.txt"));
    if (!open) return head;
    return v_flex().rounded(6).border_1().border_color(t.border).bg(t.raised).pb(10).gap(8)
      .child(head)
      .child(done ? this.resolvedDetail(item, t, cx) : this.waitingDetail(item, t, pill, cx));
  }

  resolvedDetail(item, t, cx) {
    const md = (id, text) => TextView.markdown(id, text).selectable(true).scrollable(false).w_full().text_size(12.5);
    return v_flex().px(12).gap(8)
      .when(Boolean(item.answer), e => e.child(v_flex().gap(4).p(8).rounded(4).border_1().border_color(t.border).bg(t.background)
        .child(div().text_size(11).font_semibold().text_color(t.dim).child("ANSWER"))
        .child(md(`bell-answer-${item.id}`, item.answer))))
      .child(md(`bell-md-${item.id}`, this.options(item).markdown))
      .child(h_flex().gap(6).child(this.button(`emacs-${item.id}`, "Emacs", (cx) => this.openEmacs(item, cx), t, { tip: "Open the item in bell.org" })));
  }

  waitingDetail(item, t, pill, cx) {
    const { options, markdown } = this.options(item);
    const route = this.route(item);
    if (route.kind === "looking") this.findTranscript(route.prefix, cx);
    const chosen = this.choice?.id === item.id ? this.choice.letter : null;
    const ready = route.kind !== "looking";
    const option = (o) => {
      const on = chosen === o.letter;
      return h_flex().id(`bell-opt-${item.id}-${o.letter}`).gap(8).px(8).py(6).items_start().rounded(4).border_1().cursor_pointer()
        .border_color(on ? t.accent : t.input).bg(on ? t.selected : t.background).hover(s => s.bg(t.hover))
        .on_click((_e, cx) => { this.choice = on ? null : { id: item.id, letter: o.letter }; cx.notify(); })
        .child(div().flex_none().size(18).rounded(9).flex().items_center().justify_center().text_size(11).font_semibold()
          .bg(on ? t.accent : t.hover).text_color(on ? t.accent_foreground : t.foreground).child(o.letter))
        .child(div().flex_1().min_w(0).text_size(12).child(clip(o.text, 240)))
        .when(o.recommended, e => e.child(pill("recommended", t.done)));
    };
    const where = {
      live: () => `${this.agentName(route.terminal)} is live: messages go to its prompt.`,
      resume: () => `Its session ended: a message resumes it in a new tab, in ${route.cwd.replace(this.home, "~")}.`,
      new: () => "No session to go back to: a new agent gets the item and the message.",
      looking: () => "Looking for its session…",
    }[route.kind]();
    const typed = this.text.trim().length > 0;
    return v_flex().px(12).gap(10)
      .child(TextView.markdown(`bell-md-${item.id}-${markdown.length}`, markdown || "_No details._").selectable(true).scrollable(false).w_full().text_size(12.5))
      .when(options.length > 0, e => e.child(v_flex().gap(4)
        .child(div().text_size(11).font_semibold().text_color(t.dim).child("CHOOSE"))
        .children(options.map(option))))
      .child(Textarea.new(this.reply).w_full().px(8).py(6).rounded(4).border_1().border_color(t.input).bg(t.background).text_size(12.5).text_color(t.foreground))
      .child(h_flex().gap(6).flex_wrap()
        .child(this.button(`answer-${item.id}`, chosen ? `Answer ${chosen}` : "Answer", (cx) => this.send(item, true, cx), t,
          { primary: true, enabled: ready && (Boolean(chosen) || typed), tip: "Send it to the agent and resolve the item" }))
        .child(this.button(`reply-${item.id}`, "Reply", (cx) => this.send(item, false, cx), t,
          { enabled: ready && typed, tip: "Send it to the agent and keep the item waiting" }))
        .child(this.button(`resolve-${item.id}`, "Resolve", (cx) => this.dismiss(item, cx), t, { tip: "Resolve it without an answer" }))
        .when(route.kind === "live" || route.kind === "resume", e => e.child(this.button(`agent-${item.id}`, route.kind === "live" ? "Agent" : "Resume", (cx) => this.goTo(item, cx), t,
          { tip: route.kind === "live" ? "Go to the agent that filed it" : "Resume the session that filed it, without a message" })))
        .child(this.button(`emacs-${item.id}`, "Emacs", (cx) => this.openEmacs(item, cx), t, { tip: "Open the item in bell.org" })))
      .child(div().text_size(11).text_color(t.dim).child(where));
  }

  button(id, label, action, t, { primary = false, enabled = true, tip = null } = {}) {
    const armed = this.confirm?.name === id && Date.now() < this.confirm.until;
    const el = h_flex().id(`bell-${id}`).h(28).px(10).items_center().rounded(4).flex_none().text_size(12)
      .border_1().border_color(primary && enabled ? t.solid : t.input).bg(armed ? t.blocked : primary && enabled ? t.solid : t.background)
      .text_color(armed ? t.solid_foreground : !enabled ? t.dim : primary ? t.solid_foreground : t.foreground)
      .when(enabled, e => e.cursor_pointer().hover(s => s.opacity(0.88)).on_click((_e, cx) => action(cx)))
      .child(armed ? `Confirm ${label.toLowerCase()}` : label);
    return tip ? el.tooltip(tip) : el;
  }
}
