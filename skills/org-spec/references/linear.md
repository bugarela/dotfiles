# Upload to a Linear issue

"Upload org-spec to <Linear issue link>" publishes the human Org document as a
Linear document attached to that issue. The user's request is the consent to
publish; never upload unprompted. Upload only the Org document: the companion
Markdown spec, review comments and agent replies stay local unless asked for.

## Linear access

Use the host's Linear MCP tools (`get_issue`, `save_document`, `get_document`;
Claude Code and Pi both name them `mcp__linear__<tool>` when the server is called
`linear`). Don't call Linear's API with tokens instead. If no Linear tools are
available, stop and give the one-time setup:

- Claude Code: `claude mcp add --transport http linear https://mcp.linear.app/mcp`,
  then sign in through `/mcp`.
- Pi: `pi mcp add linear --url https://mcp.linear.app/mcp`, then
  `pi mcp login linear` and `/reload`.

## Steps

1. Pick the spec: the Org document in the conversation, otherwise the only
   `*-spec.org` in the working directory; ask if several qualify. If Emacs holds
   unsaved edits to it, ask the user to save first; upload the saved file.
2. Take the issue identifier (for example, `APP-123`) from a link shaped like
   `https://linear.app/<workspace>/issue/APP-123/<slug>`. The workspace, team
   prefix, and issue number come from the user's link; never assume a particular
   project or supply a default publishing destination.
3. Convert, from the skill directory, to a scratch path:

   ```sh
   python3 scripts/linear_markdown.py /path/feature-spec.org /scratch/feature-spec.linear.md
   ```

   It prints the Org `#+title`, the diagram count and `local_references`. Org
   comments and COMMENT subtrees are dropped, each Mermaid block becomes a
   ```` ```mermaid ```` fence that Linear renders as a diagram, a diagram's
   caption follows it in italics, and its cached preview PNG is dropped.
4. Resolve every `local_references` entry before uploading: upload a needed image
   with Linear's file upload tool and substitute the returned Markdown; replace a
   link to a local file with the shared location or plain text. Never publish a
   machine-local path.
5. Look up the issue with `get_issue` (fields `documents`). If one of its
   documents has the Org title, with or without `WIP:`, update that one by `id`
   with the full new content,
   keeping its title unless asked otherwise. Otherwise create one with
   `save_document`, `issue` set to the identifier, and title `WIP: <#+title>`.
   Drop the `WIP:` prefix only when the user says the proposal is agreed or final.
6. Pass the converted file's content verbatim as `content`, with real newlines
   and no escaping. Don't hand-edit it beyond step 4.
7. Read it back with `get_document`: the ```` ```mermaid ```` fences, tables and
   prices (`$5`) must survive unescaped. The API returns Markdown only, so ask
   the user to glance at the rendered diagram the first time.
8. Report the document link. The Linear copy does not follow later Org edits;
   uploading again updates it in place.
