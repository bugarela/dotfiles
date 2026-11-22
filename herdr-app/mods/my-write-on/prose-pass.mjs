// What Gabriela changed in a Markdown file during one pass in Write On, as records that the
// prose-pass skill turns into evidence about her prose.
//
//   node prose-pass.mjs start <file>     keeps the file as it stands, as the baseline
//   node prose-pass.mjs collect <file>   prints one JSON record per change since the baseline,
//                                        appends them to the edits log, then makes the file the
//                                        new baseline
//
// Both live under $XDG_STATE_HOME/write-on: the baselines in passes/, one file for each path,
// and every record ever collected in edits.jsonl.
// Ghosted text and text moved to Overflow are compared as cut, since neither is read.

import { createHash } from 'node:crypto';
import { appendFileSync, mkdirSync, readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse, plainText } from './vendor/format.js';
import { sentences } from './vendor/text.js';

const reading = (text) => parse(text).state;
const paragraphs = (state) => plainText(state, { withoutGhost: true }).split('\n').filter((line) => line.trim());
const sentencesOf = (paragraph) => sentences(paragraph).map(({ start, end }) => paragraph.slice(start, end));

// The stretches where `a` and `b` differ, between the items that they share in order.
function gaps(a, b) {
  const common = Array.from({ length: a.length + 1 }, () => new Array(b.length + 1).fill(0));
  for (let i = a.length - 1; i >= 0; i--)
    for (let j = b.length - 1; j >= 0; j--)
      common[i][j] = a[i] === b[j] ? common[i + 1][j + 1] + 1 : Math.max(common[i + 1][j], common[i][j + 1]);
  const found = [];
  let gap = { a: [], b: [] };
  const close = () => {
    if (gap.a.length || gap.b.length) found.push(gap);
    gap = { a: [], b: [] };
  };
  for (let i = 0, j = 0; i < a.length || j < b.length; ) {
    if (i < a.length && j < b.length && a[i] === b[j]) {
      close();
      i++;
      j++;
    } else if (j >= b.length || (i < a.length && common[i + 1][j] >= common[i][j + 1])) gap.a.push(a[i++]);
    else gap.b.push(b[j++]);
  }
  close();
  return found;
}

// The share of words that two paragraphs have in common, from 0 to 1.
function likeness(a, b) {
  const words = (text) => text.toLowerCase().match(/[\p{L}\p{N}'’]+/gu) ?? [];
  const left = words(a);
  const right = words(b);
  const counts = new Map();
  for (const w of left) counts.set(w, (counts.get(w) ?? 0) + 1);
  let shared = 0;
  for (const w of right) {
    if (counts.get(w) > 0) {
      counts.set(w, counts.get(w) - 1);
      shared++;
    }
  }
  return left.length + right.length ? (2 * shared) / (left.length + right.length) : 1;
}

const SAME_PARAGRAPH = 0.4;

/**
 * The changes from one version of a file to the next. A paragraph that keeps enough of its
 * words is compared sentence by sentence, and each run of changed sentences is one rewrite.
 * A group whose showing alternative changed is also a pick, with the alternatives left over.
 * @returns {Array<{kind: 'rewrite' | 'cut' | 'add', before: string | null, after: string | null, context: string} | {kind: 'pick', chosen: string, others: string[]}>}
 */
export function changes(beforeText, afterText) {
  const before = reading(beforeText);
  const after = reading(afterText);
  const found = [];
  for (const gap of gaps(paragraphs(before), paragraphs(after))) {
    let next = 0;
    const add = (until) => {
      for (; next < until; next++) found.push({ kind: 'add', before: null, after: gap.b[next], context: gap.b[next] });
    };
    for (const old of gap.a) {
      let match = -1;
      let best = SAME_PARAGRAPH;
      for (let k = next; k < gap.b.length; k++) {
        const score = likeness(old, gap.b[k]);
        if (score >= best) [match, best] = [k, score];
      }
      if (match < 0) {
        found.push({ kind: 'cut', before: old, after: null, context: old });
        continue;
      }
      add(match);
      const now = gap.b[next++];
      for (const part of gaps(sentencesOf(old), sentencesOf(now))) {
        const kind = part.a.length && part.b.length ? 'rewrite' : part.a.length ? 'cut' : 'add';
        found.push({ kind, before: part.a.join(' ') || null, after: part.b.join(' ') || null, context: now });
      }
    }
    add(gap.b.length);
  }
  for (const [id, group] of Object.entries(after.groups)) {
    const chosen = group.variants[group.active];
    const was = before.groups[id];
    if (group.variants.length < 2 || (was && was.variants[was.active] === chosen)) continue;
    found.push({ kind: 'pick', chosen, others: group.variants.filter((v) => v !== chosen) });
  }
  return found;
}

function main([command, path]) {
  if (!['start', 'collect'].includes(command) || !path) {
    console.error('usage: prose-pass.mjs start|collect <file>');
    return 2;
  }
  const file = resolve(path);
  const state = join(process.env.XDG_STATE_HOME || join(homedir(), '.local/state'), 'write-on');
  const baseline = join(state, 'passes', `${createHash('sha1').update(file).digest('hex')}.md`);
  const text = readFileSync(file, 'utf8');
  if (command === 'collect') {
    let old;
    try {
      old = readFileSync(baseline, 'utf8');
    } catch {
      console.error(`no pass was started for ${file}`);
      return 1;
    }
    const now = new Date();
    const stamp = now.toISOString().slice(0, 16).replace(/[-:]/g, '').replace('T', '-');
    const records = changes(old, text).map((change, n) => {
      const id = `${stamp}-${String(n + 1).padStart(2, '0')}`;
      return `${JSON.stringify({ id, file, at: now.toISOString(), ...change })}\n`;
    });
    process.stdout.write(records.join(''));
    appendFileSync(join(state, 'edits.jsonl'), records.join(''));
  }
  mkdirSync(dirname(baseline), { recursive: true });
  writeFileSync(baseline, text);
  return 0;
}

if (process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) process.exitCode = main(process.argv.slice(2));
