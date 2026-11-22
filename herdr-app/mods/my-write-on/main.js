import { View, div } from 'gpui-kit';
import { v_flex, h_flex, Input, InputState, Textarea, TextareaState, TextView } from 'gpui-base';
import { theme, home, readTextFile, writeTextFile, props, hc } from 'herdr';
import { openDocument, saveDocument, readingText, blockText, editBlock, groupFor, chooseVariant, toggleGhost, stash } from './document.js';

// An agent opens a pane on a file with props { path, reply }, where `reply` is the agent's
// terminal; Send back saves the file and tells that terminal, with an optional note.
export default class WriteOn extends View {
  init(_props, cx) {
    const { path, reply } = props() ?? {};
    let draft;
    try { draft = JSON.parse(localStorage.getItem('draft') || 'null'); } catch (_) {}
    if (path && draft?.loadedPath !== path) draft = null;
    this.doc = openDocument(draft?.text ?? '');
    this.path = InputState.new({ value: path ?? draft?.path ?? `${home()}/write-on.md` });
    this.expected = draft?.expected ?? null;
    this.loadedPath = draft?.loadedPath;
    this.reply = reply;
    this.selected = 0;
    this.tools = true;
    this.message = draft ? 'Draft restored' : path ? 'Opening…' : 'Local draft · choose a file path to save';
    this.history = []; this.future = [];
    this.alternative = InputState.new({ placeholder: 'Another way to say it…' });
    this.alternative.on('submit', (_e, cx) => this.addAlternative(cx));
    this.note = InputState.new({ placeholder: 'Note for the agent…' });
    this.note.on('submit', (_e, cx) => this.sendBack(cx));
    this.rebuild();
    cx.timer.every(2000, () => this.persist());
    cx.timer.every(2000, cx => this.follow(cx));
    if (path && !draft) this.file(cx, false);
  }
  // A file that changes on disk is reloaded, unless that would drop edits that are not saved.
  follow(cx) {
    if (this.busy || this.following || !this.loadedPath) return;
    this.following = true;
    cx.spawn(async cx => {
      try {
        const text = await readTextFile(this.loadedPath);
        if (text !== null && text !== this.expected) {
          if (saveDocument(this.doc) === saveDocument(openDocument(this.expected ?? ''))) {
            this.checkpoint(); this.doc = openDocument(text); this.expected = text;
            this.selected = Math.min(this.selected, this.doc.blocks.length - 1);
            this.rebuild(); this.persist(); this.message = 'Reloaded · the file changed on disk';
          } else this.message = 'The file changed on disk · Open loads it, and Save is refused';
          cx.notify();
        }
      } catch (_) {}
      this.following = false;
    });
  }
  sendBack(cx) {
    this.file(cx, true, async () => {
      const note = this.note.value().trim();
      const text = `Write On: Gabriela sent back ${this.loadedPath}. Collect the pass with the prose-pass skill.${note ? `\n\nHer note: ${note}` : ''}`;
      const r = await hc(['send', this.reply, text]);
      if (r.code !== 0) throw new Error(r.stderr.trim() || 'hc send failed');
      this.note.set_value(''); this.message = 'Saved and sent back';
    });
  }
  persist() {
    localStorage.setItem('draft', JSON.stringify({ text: saveDocument(this.doc), path: this.path.value(), loadedPath: this.loadedPath, expected: this.expected }));
  }
  checkpoint() {
    this.history.push(saveDocument(this.doc));
    if (this.history.length > 100) this.history.shift();
    this.future = [];
  }
  rebuild() {
    this.inputs?.forEach(s => s.release());
    this.inputs = this.doc.blocks.map((b, i) => {
      const s = TextareaState.new({ value: blockText(b), rows: 2 });
      s.set_auto_grow(2, 30);
      s.on('focus', (_e, cx) => { this.selected = i; cx.notify(); });
      s.on('change', (_e, cx) => {
        this.checkpoint(); editBlock(this.doc, i, s.value()); this.message = 'Draft changed'; cx.notify();
      });
      return s;
    });
    this.overflow?.release();
    this.overflow = TextareaState.new({ value: this.doc.overflow, rows: 6 });
    this.overflow.on('change', (_e, cx) => { this.checkpoint(); this.doc.overflow = this.overflow.value(); cx.notify(); });
  }
  change(cx, fn) {
    this.checkpoint(); fn();
    this.selected = Math.min(this.selected, this.doc.blocks.length - 1);
    this.rebuild(); this.persist(); cx.notify();
  }
  addAlternative(cx) {
    const value = this.alternative.value().trim();
    if (!value) return;
    this.change(cx, () => {
      const g = groupFor(this.doc, this.selected);
      if (!g.variants.includes(value)) g.variants.push(value);
      chooseVariant(this.doc, this.selected, g.variants.indexOf(value));
    });
    this.alternative.set_value('');
  }
  undo(cx, redo = false) {
    const from = redo ? this.future : this.history;
    const to = redo ? this.history : this.future;
    if (!from.length) return;
    to.push(saveDocument(this.doc)); this.doc = openDocument(from.pop());
    this.selected = Math.min(this.selected, this.doc.blocks.length - 1);
    this.rebuild(); this.persist(); cx.notify();
  }
  file(cx, save, after) {
    if (this.busy) return;
    const path = this.path.value();
    if (!path.startsWith('/')) { this.message = 'Use an absolute local file path'; cx.notify(); return; }
    this.busy = true;
    cx.spawn(async cx => {
      try {
        if (save) {
          const text = saveDocument(this.doc);
          await writeTextFile(path, text, path === this.loadedPath ? this.expected : null);
          this.expected = text; this.loadedPath = path; this.message = 'Saved';
        } else {
          const text = await readTextFile(path);
          if (text === null) throw new Error('File not found');
          this.checkpoint(); this.doc = openDocument(text); this.selected = 0;
          this.expected = text; this.loadedPath = path; this.rebuild(); this.message = 'Opened';
        }
        this.persist();
        if (after) await after();
      } catch (e) { this.message = String(e.message ?? e); }
      this.busy = false; cx.notify();
    });
  }
  render(cx) {
    const t = theme();
    const button = (id, label, fn) => div().id(id).px(9).py(6).rounded(5).cursor_pointer().hover(s => s.bg(t.hover)).on_click((_e, cx) => fn(cx)).child(label);
    const b = this.doc.blocks[this.selected];
    const group = b?.vid && this.doc.groups[b.vid];
    const words = readingText(this.doc).match(/\S+/g)?.length ?? 0;
    const page = v_flex().id('page').flex_1().min_w(0).min_h(0).overflow_y_scrollbar().px(32).py(24).gap(10);
    if (!this.tools) page.child(TextView.markdown('read', readingText(this.doc)).selectable(true).scrollable(false).w_full());
    else {
      page.children(this.doc.blocks.map((block, i) => {
        const row = v_flex().id(`block-${i}`).px(10).py(6).rounded(6).border(1).border_color(i === this.selected ? t.border : t.background);
        row.child(Textarea.new(this.inputs[i]).w_full().text_size(18).text_color(block.runs.length && block.runs.every(r => r.ghost) ? t.dim : t.foreground));
        if (block.vid || block.runs.some(r => r.ghost)) row.child(div().text_size(11).text_color(t.dim).child(`${block.runs.some(r => r.ghost) ? 'Ghosted · ' : ''}${this.doc.groups[block.vid]?.variants.length ?? 1} versions`));
        return row;
      }));
      page.child(button('paragraph', '+ Paragraph', cx => this.change(cx, () => { this.doc.blocks.push({ kind: 'blank', runs: [] }); this.selected = this.doc.blocks.length - 1; })));
    }
    const body = h_flex().flex_1().min_h(0).child(page);
    if (this.tools) {
      const panel = v_flex().id('tools-panel').w(280).flex_none().min_h(0).overflow_y_scrollbar().p(16).gap(10).border_l(1).border_color(t.border);
      panel.child(div().font_semibold().child(`Paragraph ${this.selected + 1} · alternatives`));
      panel.children((group?.variants ?? [blockText(b)]).map((v, i) => button(`variant-${i}`, `${i === (group?.active ?? 0) ? '●' : '○'} ${v || '(blank)'}`, cx => this.change(cx, () => chooseVariant(this.doc, this.selected, i)))));
      panel.child(Input.new(this.alternative).w_full().px(8).py(8).border(1).border_color(t.input).rounded(4));
      panel.child(button('add-alt', 'Keep alternative', cx => this.addAlternative(cx)));
      panel.child(button('ghost', 'Ghost / revive paragraph', cx => this.change(cx, () => toggleGhost(this.doc, this.selected))));
      panel.child(button('stash', 'Move to Overflow', cx => this.change(cx, () => stash(this.doc, this.selected))));
      panel.child(div().mt(16).font_semibold().child('Overflow'));
      panel.child(Textarea.new(this.overflow).w_full().p(8).border(1).border_color(t.input).rounded(4));
      panel.child(button('restore', 'Return Overflow to page', cx => { if (this.doc.overflow.trim()) this.change(cx, () => { this.doc.blocks.push(...openDocument(this.doc.overflow).blocks); this.doc.overflow = ''; }); }));
      body.child(panel);
    }
    return v_flex().size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(14)
      .child(h_flex().px(18).py(10).gap(8).items_center().border_b(1).border_color(t.border)
        .child(button('tools', `${words} words · ${this.tools ? 'Read' : 'Edit'}`, cx => { this.tools = !this.tools; cx.notify(); }))
        .child(div().flex_1())
        .child(button('undo', 'Undo', cx => this.undo(cx)))
        .child(button('redo', 'Redo', cx => this.undo(cx, true))))
      .when(this.tools, el => el.child(h_flex().px(18).py(8).gap(6).items_center()
        .child(Input.new(this.path).flex_1().px(8).py(6).border(1).border_color(t.input).rounded(4))
        .child(button('open', 'Open', cx => this.file(cx, false)))
        .child(button('save', this.busy ? 'Working…' : 'Save', cx => this.file(cx, true)))))
      .when(Boolean(this.reply), el => el.child(h_flex().px(18).py(8).gap(6).items_center()
        .child(Input.new(this.note).flex_1().px(8).py(6).border(1).border_color(t.input).rounded(4))
        .child(button('send', 'Send back', cx => this.sendBack(cx)))))
      .child(body)
      .child(div().px(18).py(8).text_size(11).text_color(t.dim).child(this.message));
  }
}
