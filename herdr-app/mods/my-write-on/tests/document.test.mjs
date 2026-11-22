import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openDocument, saveDocument, readingText, blockText, editBlock, groupFor, chooseVariant, toggleGhost, stash } from '../document.js';

test('plain Markdown survives unchanged', () => {
  const d = openDocument('# Title\n\nHello, world.\n');
  assert.equal(saveDocument(d), '# Title\n\nHello, world.\n');
});
test('paragraph alternatives survive a file round trip', () => {
  const d = openDocument('First version.');
  groupFor(d, 0).variants.push('Second version.');
  chooseVariant(d, 0, 1);
  const restored = openDocument(saveDocument(d));
  assert.equal(blockText(restored.blocks[0]), 'Second version.');
  assert.deepEqual(groupFor(restored, 0).variants, ['First version.', 'Second version.']);
  chooseVariant(restored, 0, 0);
  assert.equal(readingText(restored), 'First version.');
});
test('editing one alternative preserves the other', () => {
  const d = openDocument('One.');
  groupFor(d, 0).variants.push('Two.');
  chooseVariant(d, 0, 1); editBlock(d, 0, 'Revised.');
  assert.deepEqual(groupFor(d, 0).variants, ['One.', 'Revised.']);
});
test('ghosts are reversible and survive saving', () => {
  const d = openDocument('Keep.\n\nHide.');
  toggleGhost(d, 2);
  const restored = openDocument(saveDocument(d));
  assert.equal(readingText(restored), 'Keep.');
  toggleGhost(restored, 2);
  assert.match(readingText(restored), /Hide\./);
});
test('stashing the final paragraph leaves an editable blank', () => {
  const d = openDocument('Later.'); stash(d, 0);
  assert.equal(d.blocks.length, 1);
  assert.equal(d.overflow, 'Later.');
  assert.equal(openDocument(saveDocument(d)).overflow, 'Later.');
});
test('editing heading text retains heading syntax', () => {
  const d = openDocument('# Title');
  editBlock(d, 0, '## New title');
  assert.equal(saveDocument(d), '## New title\n');
});
