// Reads ~/org/bell.org as ~/kitchen/board.el writes it: one top-level heading
// per item (`* TODO <title> :bell:today:`), a property drawer with ID, SOURCE,
// CREATED and, once resolved, RESOLVED, then the item's text, which agents
// write as Markdown. kitchen-bell-resolve puts `Answered: …` right below the
// drawer, its later lines indented by the panel so none can start a heading.

const HEADING = /^\* (?:(TODO|DONE|CANCELLED)\s+)?(.*?)(?:\s+(:[\w@#%:]+:))?\s*$/;
const STAMP = /\[(\d{4})-(\d\d)-(\d\d)(?:\s+\S+)?(?:\s+(\d\d):(\d\d))?\]/;
const LABEL = /^[A-Z][\w ()/'.-]{0,40}:(\s|$)/;

function stamp(text) {
  const m = STAMP.exec(text ?? "");
  return m ? new Date(+m[1], +m[2] - 1, +m[3], +(m[4] ?? 0), +(m[5] ?? 0)).getTime() : null;
}

export function parseBell(text) {
  const items = [];
  let item = null, drawer = false;
  text.split("\n").forEach((line, i) => {
    const h = line.startsWith("* ") && HEADING.exec(line);
    if (h) {
      item = { state: h[1] ?? "", title: h[2], line: i + 1, props: {}, lines: [], seenDrawer: false };
      items.push(item); drawer = false;
      return;
    }
    if (!item) return;
    if (!item.seenDrawer && !item.lines.length && /^\s*:PROPERTIES:\s*$/.test(line)) { drawer = true; item.seenDrawer = true; return; }
    if (drawer) {
      if (/^\s*:END:\s*$/.test(line)) drawer = false;
      else {
        const p = /^\s*:([\w-]+):\s*(.*)$/.exec(line);
        if (p) item.props[p[1].toUpperCase()] = p[2].trim();
      }
      return;
    }
    item.lines.push(line);
  });
  return items.filter(x => x.props.ID).map(x => {
    let lines = x.lines, answer = null;
    if (lines[0]?.startsWith("Answered: ")) {
      let end = 1;
      while (end < lines.length && lines[end].startsWith("  ")) end++;
      answer = [lines[0].slice(10), ...lines.slice(1, end).map(l => l.slice(2))].join("\n");
      lines = lines.slice(end);
    }
    return {
      id: x.props.ID, state: x.state, title: x.title, line: x.line, source: x.props.SOURCE ?? "",
      created: stamp(x.props.CREATED), resolved: stamp(x.props.RESOLVED), answer,
      body: lines.join("\n").replace(/^\s*\n/, "").trimEnd(),
    };
  });
}

// The rest of a line that opens option `letter`: "A.", "A)", "A:", "- A:",
// "**A.**", "(A)", "A —", or a bare letter before "(recommended)" or, from B
// on, before a capitalised word, as in "A (recommended) …" then "B Inline …".
function lettered(line, letter) {
  const m = /^\s*(?:[-*+]\s+)?(?:\*\*)?\(?([A-H])(?:\*\*)?(\)|\.|:|\]|\s+[—–-])?(?:\*\*)?\s+(\S.*)$/.exec(line);
  if (!m || m[1] !== letter) return null;
  if (!m[2] && !/^\(recommended/i.test(m[3]) && (letter === "A" || !/^[A-Z(`"]/.test(m[3]))) return null;
  return m[3];
}

// An "Options:" paragraph that letters its options inline: "(a) …; (b) …".
function inline(paragraph) {
  const parts = paragraph.split(/\(([a-h])\)\s*/);
  if (parts.length < 5) return null;
  const options = [];
  for (let i = 1; i < parts.length; i += 2) {
    if (parts[i] !== "abcdefgh"[options.length]) return null;
    options.push(parts[i + 1].replace(/\s+/g, " ").replace(/[\s;,]*(or|and)?[\s;,.]*$/i, "").trim());
  }
  return options;
}

// The choice an item offers, and its text as Markdown to show. Options become
// a list in the Markdown; an item that offers more than one set of lettered
// options gets no buttons, since one button cannot say which set it answers.
export function parseOptions(body) {
  const lines = body.split("\n"), out = [], groups = [];
  let group = null, current = null, blank = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const expected = group ? "ABCDEFGH"[group.length] : "A";
    let rest = lettered(line, expected);
    if (rest === null && group && lettered(line, "A") !== null) { group = null; rest = lettered(line, "A"); }
    if (rest !== null) {
      if (!group) { group = []; groups.push(group); }
      current = { letter: "ABCDEFGH"[group.length], text: rest };
      group.push(current);
      out.push(`- **${current.letter}** ${rest}`);
      blank = false;
      continue;
    }
    if (!line.trim()) { current = null; blank = true; out.push(line); continue; }
    if (current) { current.text += " " + line.trim(); out[out.length - 1] += " " + line.trim(); continue; }
    if (group && blank) group = null;
    blank = false;
    out.push(line);
  }
  let options = groups.length === 1 && groups[0].length >= 2 ? groups[0] : [];
  if (!groups.length) {
    const paragraphs = body.split(/\n\s*\n/).filter(p => /^\s*Options?\b/i.test(p) && /\(a\)/.test(p) && /\(b\)/.test(p));
    const found = paragraphs.length === 1 && inline(paragraphs[0]);
    if (found) options = found.map((text, i) => ({ letter: "ABCDEFGH"[i], text }));
  }
  options = options.map(o => ({ ...o, text: o.text.trim(), recommended: /recommend/i.test(o.text) }));
  return { options, markdown: markdown(out) };
}

// Org leftovers become Markdown, a "Label:" line that the agent meant as a
// paragraph of its own gets the blank line that Markdown needs to keep it so,
// and a tag written as prose ("two <source> elements") is escaped, since
// Markdown would take it for HTML and drop it.
function markdown(lines) {
  const out = [];
  let fence = false;
  for (const raw of lines) {
    let line = raw;
    if (/^\s*#\+begin_(src|example)/i.test(line)) { out.push("```" + (line.trim().split(/\s+/)[1] ?? "")); fence = true; continue; }
    if (/^\s*#\+end_(src|example)/i.test(line)) { out.push("```"); fence = false; continue; }
    if (fence || /^\s*```/.test(line)) { if (/^\s*```/.test(line)) fence = !fence; out.push(line); continue; }
    line = line.replace(/^(\*{2,})\s+(.*)$/, (_m, _s, t) => `### ${t}`)
      .replace(/\[\[([^\]]+)\]\[([^\]]+)\]\]/g, "[$2]($1)").replace(/\[\[([^\]]+)\]\]/g, "[$1]($1)")
      .split(/(`[^`]*`)/).map((part, i) => i % 2 ? part : part.replace(/<(?=[A-Za-z\/!])/g, "\\<")).join("");
    const prev = out[out.length - 1];
    if (LABEL.test(line) && prev !== undefined && prev.trim() && !/^\s*([-*+]|\d+[.)])\s/.test(prev)) out.push("");
    out.push(line);
  }
  return out.join("\n");
}
