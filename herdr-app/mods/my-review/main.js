// The Review panel: a /review-lenses run's reviewers as live agents, the @ai
// markers left in the source, and the criteria the reviewers apply. It reads the
// run folders that review_run.py keeps; the skills live in ~/.claude/skills.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { spaces, panes, focused, exec, hc, readTextFile, watchFolder, terminals, theme, run, layout, props } from "herdr";
import { emacsArgs } from "./emacs.js";

// `@ai` opening a comment, at the start of a line or after code.
const MARKER = /(?:^|\s)(\/\/+|#+|--+|;+|\/\*+|<!--|%+|\(\*)\s*@ai\b:?\s*(.*)$/;
const PROSE = /\.(md|markdown|txt|rst)$/i;
const TAG = /^\[\s*([^\]·]+?)\s*·\s*([a-z]+)\s*\]\s*(.*)$/;
const CLASSES = ["decision", "architectural", "local", "yours"];
const REFINE_CHANGES = 'mutable() & ::@ & description(regex:"^refine:")';
const STANDARDS = ["CLAUDE.md", "AGENTS.md", ".claude/rules/*.md", "CONTRIBUTING*", "CODING_STANDARDS*"];

// The focused pane's repository, or the one a pane or overlay copy was given
// as `props.folder` (with `props.machine` when it lives elsewhere).
function location() {
  const space = spaces().find((s) => s.active), given = props() ?? {};
  if (given.folder) return { cwd: given.folder, on: given.machine ?? null, space: space?.id ?? null };
  const f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder, on, space: space?.id ?? null };
}
const key = () => { const { cwd, on } = location(); return JSON.stringify({ cwd, on }); };

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const clock = () => { const d = new Date(); return [d.getHours(), d.getMinutes(), d.getSeconds()].map(n => String(n).padStart(2, "0")).join(""); };
const lines = (text) => text.split("\n").filter(Boolean);

// A findings file ends with `DONE <lens> <n>` or `FAILED <lens> <reason>`.
function verdict(text) {
  const last = (text ?? "").trim().split("\n").pop()?.trim() ?? "";
  const m = /^(DONE|FAILED)\s+\S+\s*(.*)$/.exec(last);
  return m ? { done: m[1] === "DONE", detail: m[2] } : null;
}

// One marker per hit; its continuation is the comment lines right below it that
// carry the same opener and do not start another marker.
function parseMarkers(hits, files, root) {
  const markers = [];
  for (const { path, line, text } of hits) {
    const m = MARKER.exec(text);
    // In prose files a `//` or `#` is text, so only a real comment counts there.
    if (!m || (PROSE.test(path) && m[1] !== "<!--")) continue;
    const opener = m[1], body = m[2].replace(/\s*(-->|\*\/|\*\))\s*$/, "");
    const tag = TAG.exec(body);
    const more = [], source = files[path];
    if (source) {
      for (let i = line; i < Math.min(source.length, line + 16); i++) {
        const next = source[i].trim();
        if (!next.startsWith(opener) || /@ai\b/.test(next)) break;
        const rest = next.slice(opener.length).replace(/\s*(-->|\*\/|\*\))\s*$/, "");
        if (!rest.trim()) break;
        more.push(rest.replace(/^\s?/, ""));
      }
    }
    markers.push({
      path, line, rel: path.startsWith(root + "/") ? path.slice(root.length + 1) : path,
      lens: tag?.[1] ?? null, cls: tag && CLASSES.includes(tag[2]) ? tag[2] : tag ? "local" : "yours",
      text: tag?.[3] ?? body, more,
    });
  }
  return markers;
}

export default class Review extends View {
  init(_props, cx) {
    this.tab = props()?.tab ?? "run"; this.machines = {}; this.runCache = {}; this.reset();
    // A running review is reread every 5 s, an idle one every 15 s.
    cx.timer.every(5000, (cx) => {
      if (this.shown() && this.root && (this.run?.state === "running" || Date.now() - (this.loadedAt ?? 0) > 15000)) this.loadRun(cx);
    });
  }

  reset() {
    this.root = null; this.vcs = null; this.error = null; this.runs = []; this.selected = null;
    this.files = {}; this.markers = []; this.refines = []; this.criteria = null; this.repoStandards = [];
    this.open = {}; this.note = null; this.confirm = null; this.watched = null;
  }

  // Hidden copies keep their timers, so work only while the panel shows.
  shown() {
    if (props()?.overlay) return true;
    const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
    return !body || (panel && !panel.hidden && body.active === "review");
  }

  async machine(on) {
    const k = on ?? "";
    if (!this.machines[k]) {
      const r = await exec("sh", ["-c", 'printf "%s\\n%s" "$HOME" "${XDG_STATE_HOME:-$HOME/.local/state}/review-lenses"'], { on });
      const [home, state] = r.stdout.split("\n");
      this.machines[k] = { home, state, skills: `${home}/.claude/skills` };
    }
    return this.machines[k];
  }

  refresh(cx) {
    if (this.loading) return;
    const { cwd, on } = location(), context = key();
    if (context !== this.context) { this.context = context; this.reset(); }
    if (!cwd) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        let top = await exec("jj", ["root", "--ignore-working-copy"], { cwd, on }).catch(() => null);
        let vcs = "jj";
        if (top?.code !== 0) { top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }); vcs = "git"; }
        if (key() !== context) return;
        if (top.code !== 0) { this.root = null; this.error = "Not a jj or git repository"; return; }
        this.root = top.stdout.trim(); this.vcs = vcs; this.on = on; this.error = null;
        this.mach = await this.machine(on);
        await Promise.all([this.loadRunNow(context), this.loadMarkers(context), this.loadCriteria(context)]);
        this.watch(this.root, cx);
      } catch (e) { if (key() === context) this.error = String(e.message ?? e); }
      finally { this.loading = false; cx.notify(); }
    });
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.watched === root) {
          await watchFolder(root);
          if (this.watched !== root) return;
          if (this.shown()) { await this.loadMarkers(this.context); cx.notify(); }
          else this.stale = true;
        }
      } catch { this.watched = null; }
    });
  }

  loadRun(cx) {
    cx.spawn(async (cx) => { await this.loadRunNow(this.context).catch(() => {}); cx.notify(); });
  }

  // run.json is cached per run once it is finished; a running one is reread.
  async loadRunNow(context) {
    const { state } = this.mach, on = this.on, root = this.root;
    const ls = await exec("ls", ["-1t", `${state}/runs`], { on });
    if (key() !== context) return;
    const ids = ls.code === 0 ? lines(ls.stdout).slice(0, 60) : [];
    const runs = [];
    for (const id of ids) {
      let r = this.runCache[id];
      if (!r || r.state === "running") {
        const text = await readTextFile(`${state}/runs/${id}/run.json`, { on }).catch(() => null);
        try { r = text ? JSON.parse(text) : null; } catch { r = null; }
        if (r) this.runCache[id] = r;
      }
      if (r?.repo === root) runs.push(r);
    }
    runs.sort((a, b) => (b.started ?? "").localeCompare(a.started ?? ""));
    const selected = runs.find(r => r.id === this.selected) ?? runs[0] ?? null;
    const files = {};
    if (selected) {
      const dir = `${state}/runs/${selected.id}`;
      const names = await exec("ls", ["-1", dir], { on });
      for (const name of lines(names.stdout).filter(n => n.endsWith(".md") && n !== "scope.md")) {
        files[name.slice(0, -3)] = await readTextFile(`${dir}/${name}`, { on }).catch(() => null) ?? "";
      }
    }
    let refines = [];
    if (this.vcs === "jj") {
      const r = await exec("jj", ["--ignore-working-copy", "log", "--no-graph", "-r", REFINE_CHANGES, "-T", 'change_id.short(8) ++ " " ++ description.first_line() ++ "\\n"'], { cwd: root, on });
      refines = r.code === 0 ? lines(r.stdout).map(l => ({ id: l.slice(0, 8), subject: l.slice(9) })) : [];
    }
    if (key() !== context) return;
    this.runs = runs; this.run = selected; this.files = files; this.refines = refines; this.loadedAt = Date.now();
  }

  async loadMarkers(context) {
    const root = this.root, on = this.on;
    const r = await exec("rg", ["-n", "--no-heading", "--color", "never", "--hidden", "-g", "!.jj", "-g", "!.git", "--max-columns", "400", "-e", "@ai", "--", root], { on });
    if (key() !== context) return;
    if (r.code > 1) { this.markerError = r.stderr.trim(); return; }
    const hits = [];
    for (const l of lines(r.stdout).slice(0, 400)) {
      const m = /^(.*?):(\d+):(.*)$/.exec(l);
      if (m) hits.push({ path: m[1], line: Number(m[2]), text: m[3] });
    }
    const files = {};
    for (const path of [...new Set(hits.map(h => h.path))].slice(0, 40)) {
      const text = await readTextFile(path, { on }).catch(() => null);
      if (text !== null) files[path] = text.split("\n");
    }
    if (key() !== context) return;
    this.markers = parseMarkers(hits, files, root); this.markerError = null; this.stale = false;
  }

  async loadCriteria(context) {
    const { skills } = this.mach, on = this.on, root = this.root;
    const read = (p) => readTextFile(p, { on }).catch(() => null);
    const [lenses, standards] = await Promise.all([read(`${skills}/review-lenses/references/lenses.md`), read(`${skills}/review-lenses/references/code-standards.md`)]);
    const files = await exec("rg", ["--files", "--hidden", "--max-depth", "4", ...STANDARDS.flatMap(g => ["-g", g]), "-g", "!node_modules", "--", root], { on });
    if (key() !== context) return;
    this.criteria = { lenses, standards };
    this.repoStandards = lines(files.stdout).map(p => p.slice(root.length + 1)).sort();
  }

  // The reviewers of a run are the terminals labelled with it; a run made with
  // sub-agents instead has only its findings files.
  lenses(r) {
    const live = terminals().filter(t => t.labels?.["review-run"] === r.id && t.labels?.["review-lens"]);
    const names = new Set([...live.map(t => t.labels["review-lens"]), ...Object.keys(this.files).filter(n => !["plan", "report"].includes(n))]);
    return [...names].sort().map(name => ({ name, terminal: live.find(t => t.labels["review-lens"] === name) ?? null, text: this.files[name] ?? null }));
  }

  // By label, not address: a remote terminal's address carries its machine.
  coordinator(r) {
    return r ? terminals().find(t => t.labels?.["review-run"] === r.id && t.labels?.["review-role"] === "coordinator") ?? null : null;
  }

  state(r) {
    if (r.state !== "running") return r.state;
    const c = this.coordinator(r);
    return r.coordinator && (!c || c.state === "finished") ? "stopped" : "running";
  }

  act(cx, label, work) {
    this.note = { text: `${label}…`, error: false };
    cx.spawn(async (cx) => {
      try { this.note = { text: await work(), error: false }; }
      catch (e) { this.note = { text: String(e.message ?? e), error: true }; }
      this.loadRun(cx); cx.notify();
    });
    cx.notify();
  }

  // Destructive actions take a second click within four seconds.
  armed(cx, name) {
    if (this.confirm?.name === name && Date.now() < this.confirm.until) { this.confirm = null; return true; }
    this.confirm = { name, until: Date.now() + 4000 };
    cx.timer.after(4100, (cx) => cx.notify());
    cx.notify();
    return false;
  }

  // The coordinator gets a tab of its own: a terminal with no parent and no tab
  // would stay out of herdr's screens, and its reviewers with it. The command and
  // first message come from the herdr-core template, as `hc run` would send them.
  startReview(cx) {
    const root = this.root, on = this.on, space = location().space, home = this.mach.home;
    this.act(cx, "Starting the review", async () => {
      const text = await readTextFile(`${home}/.config/herdr-core/templates/review-coordinator.md`, { on });
      const m = text && /^---\n([\s\S]*?)\n---\n([\s\S]*)$/.exec(text);
      const command = m && /^command:\s*(.+)$/m.exec(m[1])?.[1];
      if (!command) throw new Error("The review-coordinator template is missing from ~/.config/herdr-core/templates");
      run("tab.new", { name: `review ${clock().slice(0, 4)}`, space, folder: root, argv: ["sh", "-c", command], task: `${m[2].trim()}\nhere` });
      this.selected = null;
      return "The coordinator is starting in a new tab";
    });
  }

  // Refine goes to the session that asked for the review while it waits at its
  // prompt; otherwise it opens in a tab of its own, since it may ask questions.
  startRefine(cx) {
    const address = this.run?.parent && (this.on ? `${this.on}/${this.run.parent}` : this.run.parent);
    const parent = address ? terminals().find(t => t.address === address) : null;
    if (parent?.state === "live" && parent.status === "idle") {
      this.act(cx, "Sending /refine-markers", async () => {
        const r = await hc(["send", "--if", "idle", parent.address, "/refine-markers"]);
        if (r.code !== 0) throw new Error(r.stderr.trim());
        return `Sent to ${parent.name ?? parent.address}`;
      });
    } else {
      run("tab.new", { name: "refine", space: location().space, folder: this.root, argv: ["claude"], task: "/refine-markers" });
      this.note = { text: "Refine opened in a new tab", error: false };
      cx.notify();
    }
  }

  fold(cx) {
    if (!this.armed(cx, "fold")) return;
    const root = this.root, on = this.on, script = `${this.mach.skills}/refine-markers/scripts/fold.sh`;
    this.act(cx, "Folding refine changes", async () => {
      const r = await exec(script, [root], { cwd: root, on });
      const out = (r.stdout + r.stderr).trim();
      if (r.code !== 0) throw new Error(out || "fold.sh failed");
      return out.split("\n").filter(l => !l.startsWith("  ")).join(" · ");
    });
  }

  end(cx) {
    const c = this.coordinator(this.run);
    if (!c || c.state !== "live" || !this.armed(cx, "end")) return;
    this.act(cx, "Ending the run", async () => {
      const r = await hc(["kill", c.address]);
      if (r.code !== 0) throw new Error(r.stderr.trim());
      return "The coordinator and its reviewers ended";
    });
  }

  openFile(path, line, cx) {
    const abs = path.startsWith("/") ? path : `${this.root}/${path}`;
    this.act(cx, "Opening in Emacs", async () => {
      const r = await exec("emacsclient", emacsArgs(abs, this.on, line));
      if (r.code !== 0) throw new Error(r.stderr.trim() || "emacsclient failed");
      return `Opened ${path.split("/").pop()}`;
    });
  }

  render(cx) {
    if (key() !== this.context || (this.stale && this.shown())) { this.stale = false; this.refresh(cx); }
    const t = theme();
    const r = this.run;
    const pill = (text, color) => div().px(6).py(1).rounded(4).border_1().border_color(color ?? t.border).text_size(10.5).text_color(color ?? t.muted).child(text);
    const button = (id, label, action, { primary = false, enabled = true, tip = null } = {}) => {
      const armed = this.confirm?.name === id && Date.now() < this.confirm.until;
      const el = h_flex().id(`review-${id}`).h(28).px(10).items_center().rounded(4).flex_none().text_size(12)
        .border_1().border_color(primary && enabled ? t.solid : t.input).bg(armed ? t.blocked : primary && enabled ? t.solid : t.raised)
        .text_color(armed ? t.solid_foreground : !enabled ? t.dim : primary ? t.solid_foreground : t.foreground)
        .when(enabled, e => e.cursor_pointer().hover(s => s.opacity(0.88)).on_click((_e, cx) => action(cx)))
        .child(armed ? `Confirm ${label.toLowerCase()}` : label);
      return tip ? el.tooltip(tip) : el;
    };
    const tabButton = (id, label) => div().id(`review-tab-${id}`).px(10).h(28).flex().items_center().text_size(12).cursor_pointer()
      .border_b(2).border_color(this.tab === id ? t.accent : t.chrome).text_color(this.tab === id ? t.foreground : t.muted)
      .on_click((_e, cx) => { this.tab = id; cx.notify(); }).child(label);
    const md = (id, text) => TextView.markdown(id, text ?? "").selectable(true).scrollable(false).w_full().text_size(12.5);
    const heading = (text) => div().pt(10).pb(4).text_size(11).font_semibold().text_color(t.dim).child(text.toUpperCase());
    const coordinator = this.coordinator(r);

    const header = v_flex().flex_none().px(14).pt(12).pb(8).gap(8).border_b(1).border_color(t.border)
      .child(h_flex().gap(8).items_center()
        .child(div().font_semibold().child("Review"))
        .when(Boolean(this.root), e => e.child(pill(this.root.split("/").pop())))
        .when(this.loading, e => e.child(svg("mods/workspace-chrome/spinner.svg").size(12).text_color(t.dim).spin(900))))
      .child(h_flex().gap(6).flex_wrap()
        .child(button("start", "Review", (cx) => this.startReview(cx), { primary: true, enabled: Boolean(this.root), tip: "Start /review-lenses on this repository" }))
        .child(button("refine", "Refine", (cx) => this.startRefine(cx), { enabled: Boolean(this.root) && this.markers.length > 0, tip: "Act on the @ai markers with /refine-markers" }))
        .child(button("fold", `Fold${this.refines.length ? ` ${this.refines.length}` : ""}`, (cx) => this.fold(cx), { enabled: this.refines.length > 0, tip: "Fold the refine changes into the changes they fix (jj absorb)" }))
        .child(button("end", "End", (cx) => this.end(cx), { enabled: coordinator?.state === "live", tip: "End the review's coordinator and reviewers" })))
      .when(Boolean(this.note), e => e.child(div().text_size(11.5).text_color(this.note.error ? t.ansi1 : t.muted).child(this.note.text)))
      .child(h_flex().gap(2).mb(-8)
        .child(tabButton("run", "Run"))
        .child(tabButton("markers", `Markers${this.markers.length ? ` ${this.markers.length}` : ""}`))
        .child(tabButton("criteria", "Criteria")));

    const body = v_flex().id("review-body").flex_1().min_h(0).overflow_y_scrollbar().px(14).pb(14).text_size(12.5);
    if (this.error || !this.root) return this.frame(t, header, body.child(div().pt(12).text_color(t.dim).child(this.error ?? (this.loading ? "Loading…" : "No folder"))));
    if (this.tab === "markers") return this.frame(t, header, this.markersTab(body, t, pill, heading, cx));
    if (this.tab === "criteria") return this.frame(t, header, this.criteriaTab(body, t, md, heading, cx));
    return this.frame(t, header, this.runTab(body, r, t, pill, md, heading));
  }

  frame(t, header, body) {
    return v_flex().id("review").size_full().min_h(0).rounded(4).overflow_hidden().bg(t.background).border_1().border_color(t.border)
      .text_color(t.foreground).child(header).child(body);
  }

  runTab(body, r, t, pill, md, heading) {
    if (!r) return body.child(div().pt(12).text_color(t.dim).child("No review yet for this repository. Review starts one."));
    const state = this.state(r);
    const color = { running: t.working, done: t.done, failed: t.ansi1, stopped: t.blocked }[state] ?? t.muted;
    const lensRow = (l) => {
      const term = l.terminal, v = verdict(l.text), open = this.open[l.name];
      const status = v ? (v.done ? `done · ${v.detail}` : "failed") : term?.state === "live" ? term.status ?? "starting"
        : term ? "ended without a verdict" : l.text !== null ? "unfinished" : "no file";
      const dotColor = v ? (v.done ? t.done : t.ansi1) : term?.status === "blocked" ? t.blocked : term?.status === "working" ? t.working : t.idle;
      return v_flex().gap(4)
        .child(h_flex().id(`lens-${l.name}`).h(28).px(8).gap(8).items_center().rounded(4).cursor_pointer().hover(s => s.bg(t.hover)).when(open, e => e.bg(t.selected))
          .on_click((_e, cx) => { this.open[l.name] = !open; cx.notify(); })
          .child(term?.status === "working" && !v ? svg("mods/workspace-chrome/spinner.svg").size(12).text_color(t.working).spin(900) : div().size(8).rounded(4).bg(dotColor))
          .child(div().flex_1().min_w(0).truncate().child(l.name))
          .child(div().text_size(11).text_color(term?.status === "blocked" ? t.blocked : t.dim).child(status))
          .when(term?.state === "live", e => e.child(div().id(`peek-${l.name}`).px(6).text_size(11).text_color(t.accent).cursor_pointer()
            .on_click((_e, cx) => { cx.stop_propagation(); run("terminal.peek", { terminal: term.address }); }).child("peek"))))
        .when(open, e => e.child(div().px(8).pb(6).child(l.text ? md(`lens-md-${r.id}-${l.name}`, l.text) : div().text_color(t.dim).child("No findings file yet"))));
    };
    const older = this.runs.filter(x => x.id !== r.id).slice(0, 8);
    return body
      .child(h_flex().pt(12).gap(6).items_center().flex_wrap()
        .child(pill(state, color))
        .when(r.delta, e => e.child(pill("delta")))
        .when(r.findings !== null && r.findings !== undefined, e => e.child(pill(`${r.findings} findings`)))
        .child(div().text_size(11).text_color(t.dim).child(`${r.files} files · ${r.changes} changes`)))
      .child(div().pt(6).text_size(11).text_color(t.dim).truncate().child(`${r.from_rev}..${r.to_rev}`))
      .when(Boolean(this.coordinator(r)), e => e.child(h_flex().id("coordinator").pt(4).gap(6).text_size(11).text_color(t.accent).cursor_pointer()
        .on_click(() => run("terminal.peek", { terminal: this.coordinator(r).address })).child(`coordinator ${this.coordinator(r).name ?? r.coordinator} · ${this.coordinator(r).status ?? ""}`)))
      .child(heading("Reviewers"))
      .children(this.lenses(r).map(lensRow))
      .when(!this.lenses(r).length, e => e.child(div().text_color(t.dim).child(state === "running" ? "Picking lenses…" : "No reviewers recorded")))
      .when(Boolean(this.files.plan), e => e.child(heading("Plan")).child(md(`plan-${r.id}`, this.files.plan.replace(/^# Plan\s*/, ""))))
      .when(Boolean(this.files.report), e => e.child(heading("Report")).child(md(`report-${r.id}`, this.files.report)))
      .when(this.refines.length > 0, e => e.child(heading("Refine changes, not folded yet"))
        .children(this.refines.map(c => div().text_size(11.5).text_color(t.muted).truncate().child(`${c.id} ${c.subject}`))))
      .when(older.length > 0, e => e.child(heading("Earlier runs")).children(older.map(x =>
        h_flex().id(`run-${x.id}`).h(24).px(8).gap(8).items_center().rounded(4).cursor_pointer().hover(s => s.bg(t.hover)).text_size(11.5)
          .on_click((_e, cx) => { this.selected = x.id; this.open = {}; this.loadRun(cx); }).child(div().flex_1().truncate().child(x.id))
          .child(div().text_color(t.dim).child(`${this.state(x)}${x.findings != null ? ` · ${x.findings}` : ""}`)))));
  }

  markersTab(body, t, pill, heading, cx) {
    if (this.markerError) return body.child(div().pt(12).text_color(t.ansi1).child(this.markerError));
    if (!this.markers.length) return body.child(div().pt(12).text_color(t.dim).child("No @ai markers in this repository."));
    const color = { decision: t.blocked, architectural: t.ansi5, local: t.ansi4, yours: t.accent };
    const label = { decision: "Decisions", architectural: "Architectural", local: "Local", yours: "Yours (no tag)" };
    const row = (m, i) => v_flex().id(`marker-${i}`).px(8).py(6).gap(3).rounded(4).cursor_pointer().hover(s => s.bg(t.hover))
      .on_click((_e, cx) => this.openFile(m.path, m.line, cx))
      .child(h_flex().gap(6).items_center()
        .when(Boolean(m.lens), e => e.child(pill(m.lens, color[m.cls])))
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(`${m.rel}:${m.line}`)))
      .child(div().text_size(12.5).child(m.text))
      .children(m.more.slice(0, 6).map(l => div().text_size(11).text_color(t.muted).truncate().child(l.trim())));
    let i = 0;
    return CLASSES.reduce((el, cls) => {
      const group = this.markers.filter(m => m.cls === cls);
      return group.length ? el.child(heading(`${label[cls]} · ${group.length}`)).children(group.map(m => row(m, i++))) : el;
    }, body);
  }

  criteriaTab(body, t, md, heading, cx) {
    const c = this.criteria;
    if (!c) return body.child(div().pt(12).text_color(t.dim).child("Loading…"));
    const section = (id, title, text) => {
      const open = this.open[`criteria-${id}`] ?? id === "lenses";
      return body.child(h_flex().id(`criteria-${id}`).pt(10).pb(4).gap(6).items_center().cursor_pointer()
        .on_click((_e, cx) => { this.open[`criteria-${id}`] = !open; cx.notify(); })
        .child(div().text_size(11).text_color(t.dim).child(open ? "▾" : "▸"))
        .child(div().text_size(11).font_semibold().text_color(t.dim).child(title.toUpperCase())))
        .when(open, e => e.child(text === null ? div().text_color(t.ansi1).child("Not found: is the review-lenses skill installed?") : md(`criteria-md-${id}`, text)));
    };
    section("lenses", "Lenses and smells", c.lenses);
    section("standards", "Code standards", c.standards);
    return body.child(heading("This repository's standards"))
      .when(!this.repoStandards.length, e => e.child(div().text_color(t.dim).child("None found")))
      .children(this.repoStandards.map((p, i) => div().id(`standard-${i}`).h(24).px(8).flex().items_center().rounded(4).text_size(12).text_color(t.accent)
        .cursor_pointer().hover(s => s.bg(t.hover)).on_click((_e, cx) => this.openFile(p, null, cx)).child(p)));
  }
}
