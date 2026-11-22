---
name: prose-pass
description: Hands a Markdown file to Gabriela in Write On, collects the changes that she makes there and turns them into evidence about her prose style. Use it to write or polish a document with her, or when Write On sends a file back.
---

# Prose pass

A pass is one round of work on a Markdown file. The agent writes the file and
hands it to Gabriela in Write On, which is her editor in Herdr. She edits the
file there and sends it back. Her changes are collected as records, and the
records become evidence in her prose profile at
`~/.claude/skills/prose-style/profile.md`. A hypothesis that is confirmed
becomes a rule of the `prose-style` skill, and the next pass is written with
what was learned.

Write On is the Herdr mod at `~/.config/herdr-app/mods/my-write-on`. Its
script `prose-pass.mjs` keeps a copy of the file as the agent wrote it, and it
compares her saved file with that copy. Every change that it finds is kept in
the edits log at `~/.local/state/write-on/edits.jsonl`, which stays on the
machine where the pass was collected.

## Handing a file over

1. The file is written by the rules of the `prose-style` skill, with one
   paragraph on each line, since Write On reads each line as a paragraph. A
   file that is wrapped is unwrapped first. A list item, a table row, a
   heading and each line of a code block keep a line of their own.
2. Each cut of the last pass whose text is still in the body of the file is
   ghosted text, and it is deleted. Write On keeps ghosted text in the
   Markdown, and it shows that text again once another tool has changed the
   file. Text below the `<!-- overflow -->` line is hers to keep.
3. A paragraph that holds alternatives of hers is left as it is, since a
   changed paragraph loses its alternatives. Her alternatives are listed in
   the `<!-- write_on … -->` comment at the end of the file.
4. The pass is started.

       node --no-warnings ~/.config/herdr-app/mods/my-write-on/prose-pass.mjs start <file>

5. On the first pass of a session, the file is opened in a Write On pane
   beside the agent's terminal. A later pass needs no new pane, since the pane
   reloads the file once it changes on disk.

       herdr-app do pane.split "$(herdr-app ls | jq -c --arg t "$HC_TERMINAL_ID" --arg path <absolute path> \
         '{direction: "right", pane: first(.. | objects | select(.terminal? == $t) | .pane), mod: "my-write-on", props: {path: $path, reply: $t}}')"

   When `HC_TERMINAL_ID` is not set, the session runs outside Herdr. The path
   is given to her then, and she says in the session when she is done.
6. The turn ends with the path of the file. The file is not written again
   until she sends it back, since Write On would refuse her next save.

## Collecting a pass

A file is sent back with the Send back button of Write On. The message "Write
On: Gabriela sent back <path>" then arrives in the session, and her note is
appended to it when she wrote one.

The pass is collected with the following command. One record is printed for
each change, and every record is appended to the edits log. The saved file
then becomes the copy that the next pass is compared with.

    node --no-warnings ~/.config/herdr-app/mods/my-write-on/prose-pass.mjs collect <file>

| Field             | Value                                                                                          |
|-------------------|------------------------------------------------------------------------------------------------|
| `id`              | `<yyyymmdd>-<hhmm>-<nn>`, in UTC. The profile cites a record by its id.                         |
| `file`, `at`      | The absolute path of the file and the time of the collection                                    |
| `kind`            | `"rewrite"`, `"cut"`, `"add"` or `"pick"`                                                       |
| `before`          | The sentences as the agent wrote them, or `null` for an add                                     |
| `after`           | The sentences as she left them, or `null` for a cut                                             |
| `context`         | The paragraph as she left it. For a paragraph that was cut, it is the paragraph as it was.      |
| `chosen`, `others` | Only in a pick. They are the alternative that she left showing and the alternatives that she did not. |

A sentence that she split in two comes back as one record, since a run of
changed sentences in a paragraph is one rewrite. Ghosted text and text that she moved
to Overflow come back as cuts. A paragraph that keeps fewer than about half of
its words comes back as a cut and an add.

For example, the following record was collected from a design note. The
clause that followed the comma and "so" became a sentence of its own. The record counts for a
hypothesis that two sentences read better than two clauses that are joined
with a comma and "so".

```json
{"id": "20260101-0910-03", "file": "/home/you/notes/cache.md", "at": "2026-01-01T09:10:12.000Z", "kind": "rewrite", "before": "The job clears the cache, so the next run starts empty.", "after": "The job clears the cache. The next run therefore starts empty.", "context": "…"}
```

## Recording the evidence

Her note is read first, and then each record with its context.

- A record that changes a fact, a number or a claim is a content edit. It says
  nothing about her style, and it is left out of the profile.
- A rewrite counts for a hypothesis when `after` has the form that the
  hypothesis predicts and `before` has the other form. A rewrite in the other
  direction counts against it.
- A rewrite that changes a dimension which no hypothesis covers opens a new
  hypothesis, with the record as its first row.
- A cut counts for a hypothesis about what is cut, such as a sentence that only
  announces what follows.
- A pick counts for a hypothesis when `chosen` has the predicted form and one
  of `others` differs from it in that dimension alone.
- Text that she left unchanged is not counted, since she may not have read it
  closely.

Each row is written into the profile in the form that the head of the profile
describes, with the answer given as `Edit, <id>`. The result quotes the
change, since the edits log is kept on one machine only. A note that asks for
a rule needs no evidence, and the rule is promoted at once.

The pass has been recorded when every record of the pass is either a content
edit or a row in the profile.

## Promotion

A hypothesis is confirmed when at least three records from at least two
paragraphs count for it and none counts against it. It is rejected in the
mirror case. When the records are divided, the hypothesis is split into
narrower claims. For example, a claim about every named doer can be split into
one claim about tools and one about "you".

A confirmed hypothesis is proposed to Gabriela through the bell, with the
records that support it. Once she agrees, it is written into the `prose-style`
skill in the following ways, and it is marked as promoted in the profile.

- A rule is added to the list of sentence rules, or the rule that it
  contradicts is changed.
- A row is added to the table of examples that are written and not written.
- A Vale rule is added only when the construction is matched by a regular
  expression or a sequence of tags without many false matches.

The changed `SKILL.md` is linted as the `prose-style` skill says. A rejected
hypothesis that contradicts a current rule is proposed in the same way, as a
change to that rule.

## The next pass

The next pass keeps her sentences as she wrote them. The rules that were
promoted are applied to the paragraphs that she has not edited, and so is what
her note asks for. Where her edits show a pattern, the same change may be made
to sentences of the same kind elsewhere in the file. A change that follows a
pattern tests its hypothesis, since a rewrite that undoes the change in the
next pass counts against the hypothesis.

The document is done when she says so. A finished file keeps no ghosted text
and no `<!-- write_on … -->` comment, since a reader of the Markdown would see
the ghosted text. Both are removed then.
