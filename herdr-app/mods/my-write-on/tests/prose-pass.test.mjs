import { test } from 'node:test';
import assert from 'node:assert/strict';
import { changes } from '../prose-pass.mjs';
import { openDocument, saveDocument, groupFor, chooseVariant, toggleGhost, stash } from '../document.js';

const page = '# Title\n\nThe code reports its events. A run of the code records them. Each event is a line.\n\nThe binding is written outside the editor.\n';

test('an unchanged file has no changes', () => {
  assert.deepEqual(changes(page, page), []);
});
test('a rewritten sentence is paired with the sentence it replaced', () => {
  const after = page.replace('A run of the code records them.', 'They are recorded while the code runs.');
  assert.deepEqual(changes(page, after), [{
    kind: 'rewrite',
    before: 'A run of the code records them.',
    after: 'They are recorded while the code runs.',
    context: 'The code reports its events. They are recorded while the code runs. Each event is a line.',
  }]);
});
test('a sentence that is split in two is one rewrite', () => {
  const after = page.replace('The binding is written outside the editor.', 'The binding is written by you. It is written outside the editor.');
  const [change] = changes(page, after);
  assert.equal(change.kind, 'rewrite');
  assert.equal(change.after, 'The binding is written by you. It is written outside the editor.');
});
test('a paragraph that keeps few of its words is a cut and an add', () => {
  const after = page.replace('The binding is written outside the editor.', 'Proofs come last.');
  assert.deepEqual(changes(page, after).map((c) => c.kind), ['cut', 'add']);
});
test('a dropped sentence is a cut inside its paragraph', () => {
  const after = page.replace(' A run of the code records them.', '');
  assert.deepEqual(changes(page, after).map((c) => [c.kind, c.before]), [['cut', 'A run of the code records them.']]);
});
test('ghosted text and text moved to Overflow are cuts', () => {
  const ghosted = openDocument(page);
  toggleGhost(ghosted, 4);
  assert.deepEqual(changes(page, saveDocument(ghosted)).map((c) => [c.kind, c.before]), [['cut', 'The binding is written outside the editor.']]);
  const moved = openDocument(page);
  stash(moved, 4);
  assert.deepEqual(changes(page, saveDocument(moved)).map((c) => [c.kind, c.before]), [['cut', 'The binding is written outside the editor.']]);
});
test('the alternative left showing is a pick over the others', () => {
  const d = openDocument(page);
  groupFor(d, 4).variants.push('The binding is written by you.');
  chooseVariant(d, 4, 1);
  const picks = changes(page, saveDocument(d)).filter((c) => c.kind === 'pick');
  assert.deepEqual(picks, [{ kind: 'pick', chosen: 'The binding is written by you.', others: ['The binding is written outside the editor.'] }]);
});
