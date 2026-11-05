# org-spec

One shared Agent Skills bundle, usable with Claude Code and Pi/OpenAI models.
No provider-specific APIs, plugins, or model assumptions.

## Two documents, two audiences

- **`<topic>-spec.org`**: the short human design document. Problem, decisions
  first, alternatives nested under each choice, accepted tradeoffs, a useful
  comparison table/diagram, and remaining risks/questions. One page ideally;
  four exported pages maximum. No acceptance criteria, opaque IDs, arbitrary
  scope exclusions, or machine-local paths.
- **`<topic>-spec.md`**: the full agent-facing implementation spec. Exact sizes,
  thresholds, interfaces, prototype context, acceptance criteria, and validation.
  No four-page cap. Agents read both and keep them consistent; you don't need to
  read the full Markdown document.

Write Org as the author's proposal to the team, not an agent advising the author.
The whole document is a proposal: state choices directly, without "Recommendation:"
prefixes or per-choice approval labels. Explain the approach, the alternatives
considered, and why they were not preferred. A bare "Chosen:" label isn't enough.
Do not imply team approval that hasn't happened. Important uncertainty stays
visible as real design questions, not approval chores or buried Markdown detail.

## Install

This directory is the complete, project-independent skill. No private repository,
Nix installation, or project account is required to draft and review documents.
Export/publishing dependencies are optional; see the references below.

From this skill directory in any checkout:

```sh
skill_dir="$(pwd -P)"
mkdir -p ~/.claude/skills ~/.pi/agent/skills
ln -s "$skill_dir" ~/.claude/skills/org-spec
ln -s "$skill_dir" ~/.pi/agent/skills/org-spec
```

Existing destinations are deliberately not overwritten. Install for either host
or both; both links should point to this one canonical copy. Copying the complete
directory instead also works.

In the author's dotfiles setup the canonical source is `~/dotfiles/skills/org-spec/`.
Private configuration holds installation links only; no skill implementation or
project-specific content belongs there. No Nix rebuild is needed for skill edits.
Start a fresh Claude Code session if the command isn't visible; in Pi run `/reload`.

## Usage

Claude Code:

```text
/org-spec Draft a one-page spec for <feature> in feature-spec.org
/org-spec Address my comments in feature-spec.org
/org-spec Export feature-spec.org to DOCX and check the page budget
upload org-spec to https://linear.app/<workspace>/issue/APP-123/<slug>
```

Pi:

```text
/skill:org-spec Draft a one-page spec for <feature> in feature-spec.org
/skill:org-spec Address my comments in feature-spec.org
/skill:org-spec Export feature-spec.org to DOCX and check the page budget
upload org-spec to https://linear.app/<workspace>/issue/APP-123/<slug>
```

Natural-language requests can also trigger the skill.

## Upload to Linear

"upload org-spec to <issue link>" attaches the Org document to that issue as a
Linear document titled `WIP: <title>`; uploading again updates it in place. Mermaid
diagrams go up as source and Linear renders them; comments and the Markdown
companion stay local. Both hosts need the Linear MCP server, named `linear`:

- Claude Code: `claude mcp add --transport http linear https://mcp.linear.app/mcp`,
  then sign in through `/mcp`.
- Pi: `pi mcp add linear --url https://mcp.linear.app/mcp`, then
  `pi mcp login linear`.

`references/linear.md` has the steps the agent follows.

## Comment on any passage

Save this immediately after the passage in your Org file:

```org
# ? Why is this synchronous? Please explain the tradeoff.
```

Invoke the skill to address comments. It replies directly underneath and makes
explicitly requested edits. Add another comment to follow up, or just move on.
No IDs or statuses to manage. Agents refer to the passage by topic or quoted
text, not an identifier. Ordinary informal comments also work.

Comments and replies stay in Org but are excluded from DOCX.

## Portability

Keep `SKILL.md`, `assets/`, `references/`, and `scripts/` together. All bundled
paths are relative to this directory. Project-specific conventions and publishing
destinations belong in the consuming project's instructions, not this bundle.
Actual proposals, transcripts, exports, authentication, and application state must
not be committed here. See `references/export.md` for optional
export dependencies and honest pagination validation, and
`references/linear.md` for Linear uploads (Pandoc required).
