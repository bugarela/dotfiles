import { parse, serialize, htmlToBlocks, blocksToHtml, plainText } from './vendor/format.js';

export function openDocument(text) {
  const { state } = parse(text);
  return { blocks: htmlToBlocks(state.html), groups: state.groups, overflow: state.overflow };
}
export function snapshot(doc) {
  return { html: blocksToHtml(doc.blocks), groups: doc.groups, overflow: doc.overflow };
}
export const saveDocument = doc => serialize(snapshot(doc));
export const readingText = doc => plainText(snapshot(doc), { withoutGhost: true });
export const blockText = b => (b.kind === 'h' ? '#'.repeat(b.level) + ' ' : '') + b.runs.map(r => r.text).join('');
export function editBlock(doc, index, text) {
  const b = doc.blocks[index];
  const ghost = b.runs.length > 0 && b.runs.every(r => r.ghost);
  const heading = /^(#{1,6}) (.*)$/s.exec(text);
  b.runs = [{ text: heading ? heading[2] : text, ...(ghost ? { ghost: true } : {}) }];
  b.kind = heading ? 'h' : text ? 'p' : 'blank';
  if (heading) b.level = heading[1].length;
  if (b.vid && doc.groups[b.vid]) {
    const g = doc.groups[b.vid];
    g.variants[g.active] = text;
  }
}
export function groupFor(doc, index) {
  const b = doc.blocks[index];
  if (!b.vid) {
    let id = Date.now().toString(36);
    while (doc.groups[id]) id += 'a';
    b.vid = id;
    doc.groups[id] = { scope: 'paragraph', variants: [blockText(b)], active: 0 };
  }
  return doc.groups[b.vid];
}
export function chooseVariant(doc, index, variant) {
  const g = groupFor(doc, index);
  if (!Number.isInteger(variant) || variant < 0 || variant >= g.variants.length) return;
  g.active = variant;
  const ghost = doc.blocks[index].runs.some(r => r.ghost);
  editBlock(doc, index, g.variants[variant]);
  doc.blocks[index].runs.forEach(r => { r.ghost = ghost; });
}
export function toggleGhost(doc, index) {
  const b = doc.blocks[index];
  const ghost = !b.runs.every(r => r.ghost);
  b.runs = b.runs.map(r => ({ ...r, ghost }));
}
export function stash(doc, index) {
  doc.overflow = [doc.overflow, blockText(doc.blocks[index])].filter(Boolean).join('\n\n');
  doc.blocks.splice(index, 1);
  if (!doc.blocks.length) doc.blocks.push({ kind: 'blank', runs: [] });
}
