// Paste a file path, pick where it lives, Enter opens it in this computer's Emacs.
// props.selection { pane, terminal } (the terminal menu) or props.file { path, machine }
// (the Files panel): open it right away, staying open only to fix it. Otherwise the
// clipboard prefills.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { props, closeOverlay, theme, spaces, focused, panes, run } from "herdr";
import { sameMachine, onDesktop, clipboard, looksLikePath, openInEmacs, spaceOfPane, machineForText } from "./open.js";

export default class OpenInEmacs extends View {
  init(_props, cx) {
    const p = props() ?? {};
    const space = p.selection ? spaceOfPane(p.selection.pane) : spaces().find(s => s.active);
    this.text = "";
    this.machine = space?.machine ?? "desktop";
    this.remote = space?.machine && !sameMachine(space.machine, "desktop") ? space.machine : null;
    this.desktop = false;
    this.error = "";
    this.busy = false;
    this.input = InputState.new({ value: this.text });
    this.input.on("change", (_e, cx) => { this.text = this.input.value(); this.error = ""; cx.notify(); });
    this.input.on("submit", (_e, cx) => this.submit(cx));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
    cx.spawn(async cx => {
      this.desktop = await onDesktop().catch(() => false);
      // On the desktop its own files are local; there is no SSH alias to itself.
      if (this.desktop && sameMachine(this.machine, "desktop")) this.machine = null;
      if (p.file) { this.machine = p.file.machine; this.prefill(p.file.path); await this.open(null); }
      else if (p.selection) await this.openSelection(p.selection, space, cx);
      else this.prefill(await clipboard());
      cx.notify();
    });
  }

  prefill(text) {
    if (!looksLikePath(text) || this.text) return;
    this.text = text.trim();
    this.input.set_value(this.text);
    this.input.set_selected_range({ start: 0, end: this.text.length });
  }

  // terminal.copy writes the clipboard; an unchanged clipboard means nothing was selected.
  async openSelection({ pane, terminal }, space, cx) {
    const before = await clipboard();
    run("pane.focus", { terminal });
    run("terminal.copy");
    let text = before;
    for (let i = 0; i < 10 && text === before; i++) {
      await new Promise(done => cx.timer.after(50, done));
      text = await clipboard();
    }
    this.input.focus();
    if (text === before) { this.error = "Nothing selected in that terminal"; return; }
    this.prefill(text);
    if (!looksLikePath(text)) return;
    const cwd = panes().find(p => p.pane === pane)?.cwd ?? null;
    this.machine = await machineForText(text, space?.machine ?? null, cwd).catch(() => this.machine);
    await this.open(cwd);
  }

  async open(cwd) {
    this.busy = true;
    try {
      await openInEmacs(this.text, this.machine, cwd);
      closeOverlay(props().overlay);
    } catch (error) {
      this.error = String(error.message ?? error);
    }
    this.busy = false;
  }

  submit(cx) {
    if (this.busy || !this.text.trim()) return;
    // Relative paths follow the focused terminal, when it is on the chosen machine.
    const space = spaces().find(s => s.active);
    const cwd = sameMachine(space?.machine ?? null, this.machine) ? focused()?.cwd ?? null : null;
    cx.spawn(async cx => { await this.open(cwd); cx.notify(); });
  }

  render(cx) {
    const t = theme();
    const choices = [
      ...(this.remote ? [[this.remote, this.remote]] : []),
      ...(this.desktop ? [] : [["desktop", "Desktop"]]),
      [null, "This computer"],
    ];
    const chip = ([machine, label]) => {
      const on = sameMachine(machine, this.machine);
      return div().id(`emacs-on-${label}`).h(26).px(10).flex().items_center().rounded(6).cursor_pointer().text_size(12)
        .border_1().border_color(on ? t.accent : t.input).bg(on ? t.selected : t.raised).text_color(on ? t.foreground : t.muted)
        .on_click((_e, cx) => { this.machine = machine; this.error = ""; cx.notify(); this.input.focus(); }).child(label);
    };
    const button = (id, text, primary, action) => h_flex().id(id).h(32).px(14).items_center().rounded(8)
      .border_1().border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground).text_size(12.5).font_medium().cursor_pointer()
      .hover(s => s.opacity(0.88)).on_click(action).child(text);
    return v_flex().id("my-emacs").track_focus(this.handle)
      .on_key_down((e, cx) => { if (e.key === "escape") { closeOverlay(props().overlay); cx.stop_propagation(); } })
      .w_full().min_h(0).p(18).gap(10).bg(t.popover).text_color(t.foreground)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child("Open in Emacs"))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(Input.new(this.input).h(36).px(10).rounded(9).border_1().border_color(t.accent).bg(t.background).text_size(12.8).text_color(t.foreground))
      .child(h_flex().gap(6).items_center().child(div().text_size(11.5).text_color(t.dim).mr(4).child("File is on")).children(choices.map(chip)))
      .when(Boolean(this.error), el => el.child(div().text_size(11.5).text_color(t.blocked).truncate().child(this.error)))
      .child(h_flex().gap(8).justify_end()
        .child(button("emacs-cancel", "Cancel", false, () => closeOverlay(props().overlay)))
        .child(button("emacs-open", this.busy ? "Opening…" : "Open", true, (_e, cx) => this.submit(cx))));
  }
}
