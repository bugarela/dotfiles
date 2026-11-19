// One file as a read-only pane: markdown rendered, anything else as code. Re-read every
// few seconds, so edits made elsewhere show. props.file { path, machine }: machine is a
// Herdr machine name, null for this computer.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState, TextView } from "gpui-base";
import { props, readTextFile, theme, settings } from "herdr";

const MARKDOWN = /\.(md|markdown)$/i;

export default class Viewer extends View {
  init(_props, cx) {
    this.version = 0;
    this.load(cx);
    cx.timer.every(3000, cx => this.load(cx));
  }

  load(cx) {
    const { path, machine } = props()?.file ?? {};
    if (!path || this.loading) return;
    this.loading = true;
    cx.spawn(async cx => {
      let text, error = null;
      try {
        text = await readTextFile(path, { on: machine });
        if (text === null) error = "This file is no longer available";
        else if (text.includes("\0")) error = "Binary file · no text preview";
      } catch (e) { error = String(e.message ?? e); }
      finally { this.loading = false; }
      if (text === this.text && error === this.error) return;
      this.text = text; this.error = error; this.version++;
      if (error || MARKDOWN.test(path)) { this.code?.release(); this.code = null; }
      else if (this.code) this.code.set_value(text);
      else {
        const t = theme();
        this.code = EditorState.new({ language: /\.([^./]+)$/.exec(path)?.[1] ?? "txt", readonly: true, value: text,
          font_family: settings().font_family, font_size: 12,
          syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      }
      cx.notify();
    });
  }

  render() {
    const t = theme();
    return v_flex().size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(13)
      .child(h_flex().h(28).flex_none().px(12).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(props()?.file?.path ?? "")))
      .child(this.error || this.text === undefined ? div().p(12).text_color(t.dim).child(this.error || "Loading file…")
        : this.code ? Editor.new(this.code).flex_1().min_h(0)
        // A scroll box of its own keeps the position when a re-read replaces the text.
        : v_flex().id("viewer-scroll").flex_1().min_h(0).overflow_y_scrollbar().px(20).py(14)
          .child(TextView.markdown(`viewer-md-${this.version}`, this.text).selectable(true).scrollable(false).w_full()));
  }
}
