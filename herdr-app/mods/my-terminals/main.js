import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, agents, focused, layout, theme, run } from "herdr";

const base = path => (path ?? "").replace(/[\\/]+$/, "").split(/[\\/]/).pop() || "~";
function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const result = find(child, id);
    if (result) return result;
  }
}

export default class Terminals extends View {
  render() {
    const t = theme(), sp = spaces(), ps = panes(), focus = focused();
    const narrow = (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;
    const agentAddresses = new Set(agents().map(a => a.address));
    const tabs = new Map(sp.flatMap(s => s.tabs.map(tab => [tab.id, { tab, space: s }])));
    const list = ps.filter(p => p.terminal && !p.status && !p.program?.agent && !agentAddresses.has(p.terminal)
      && tabs.has(p.tab) && !(tabs.get(p.tab).tab.named && tabs.get(p.tab).tab.name === "jj"));
    const button = (id, icon, tip, action) => div().id(id).size(22).flex_none().flex().items_center().justify_center()
      .rounded(4).text_color(t.dim).cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
      .tooltip(tip).on_click((_e, cx) => { cx.stop_propagation(); action(); }).child(svg(icon).size(12));
    const add = () => {
      const space = sp.find(s => s.id === focus?.space) ?? sp.find(s => s.active);
      const folder = focus?.cwd || ps.find(p => tabs.get(p.tab)?.space.id === space?.id && p.cwd)?.cwd || space?.folder;
      if (space) run("tab.new", { space: space.id, ...(folder ? { folder } : {}) });
      else run("space.new");
    };
    return v_flex().size_full().min_h(0).bg(t.chrome).border_t(1).border_color(t.border).text_size(13)
      .child(h_flex().h(36).flex_none().px(narrow ? 8 : 16).items_center().justify_between()
        .when(!narrow, el => el.child(div().text_size(11.5).font_medium().text_color(t.dim).child("Terminals")))
        .child(button("terminal-new", "mods/workspace-chrome/plus.svg", "New terminal in the current folder", add)))
      .child(v_flex().id("terminal-list").flex_1().min_h(0).px(narrow ? 0 : 8).overflow_y_scrollbar().children(list.map((p, i) => {
        const { tab, space } = tabs.get(p.tab);
        const folder = p.cwd || space.folder;
        const detail = tab.named ? tab.name : p.program?.shell ? `Terminal ${i + 1}` : p.program?.name || `Terminal ${i + 1}`;
        return h_flex().id(`terminal-${p.pane}`).h(30).flex_none().px(8).gap(6).items_center().rounded(4)
          .when(p.focused, el => el.bg(t.selected)).cursor_pointer().hover(s => s.bg(t.hover))
          .tooltip(`${space.machine ? `${space.machine}: ` : ""}${folder ?? space.name} · ${detail}`)
          .on_click(() => run("pane.focus", { pane: p.pane }))
          .on_mouse_down("right", () => run("tab.rename", { id: tab.id }))
          .child(div().flex_1().min_w(0).truncate().text_color(p.focused ? t.foreground : t.muted)
            .child(narrow ? String(i + 1) : `${base(folder) || space.name} · ${detail}`))
          .when(!narrow, el => el.child(button(`terminal-close-${p.pane}`, "mods/pane/close.svg", "Close terminal and end its process", () => run("pane.close", { pane: p.pane }))));
      })))
      .when(!list.length && !narrow, el => el.child(div().px(16).pb(8).text_size(12).text_color(t.dim).child("No terminals. Use + to open one here.")));
  }
}
