# DOCX export and page gate

## Export

Dependencies: Python 3 and Pandoc; Mermaid CLI (`mmdc`) when diagrams are present.
Final page validation additionally needs LibreOffice (`libreoffice`) and Poppler
(`pdfinfo`). Do not install packages or download dependencies without permission.

From the skill directory, with absolute document paths:

```sh
python3 scripts/export.py /path/feature-spec.org /path/feature-spec.docx
```

The exporter:

1. Reads Org with Pandoc, excluding Org comments and COMMENT subtrees.
2. Renders Mermaid source blocks to PNG using local `mmdc`, replacing those
   blocks only in the temporary Pandoc AST. Original Org source is untouched.
3. Embeds images, native tables, and code in DOCX. It never evaluates Babel.
4. Renders DOCX to PDF using an isolated headless LibreOffice profile and counts
   pages with `pdfinfo`. More than four pages FAILS without writing a final DOCX.
5. Refuses to overwrite an existing output. Pick a temporary/new output for
   revisions and replace the old artifact only after successful inspection.

For provisional export when pagination tools aren't available:

```sh
python3 scripts/export.py /path/feature-spec.org /path/feature-spec.draft.docx --draft
```

Label this **draft / page count unverified**. Never report a word-count estimate,
Word's cached `docProps/app.xml` page count, or a successful conversion as proof
of the four-page limit. Don't use `--draft` to bypass a known over-limit result.
If final export is requested but the tools are missing, disclose the blocker.

## Layout

Use Pandoc's default DOCX layout as a starting point, or pass a reviewed Word
reference file with `--reference-doc /path/spec-reference.docx`. A reference can
be created with `pandoc --print-default-data-file reference.docx > reference.docx`
and styled in Word/LibreOffice. Prefer A4 or Letter, 0.75–1 inch margins, 11 pt
body text, compact paragraph spacing, and readable monospace code. No cover/TOC.
Do not decrease body text below 10.5 pt or margins below 0.65 inches to fit.

A page-count pass is not a visual-layout pass. Inspect the exported document or
its rendered pages for clipped/wide tables, broken rows, oversized diagrams,
unreadable labels, orphan headings, and code wrapping. Check that all diagrams
are images, review text is absent, and essential content is present. The exporter
uses a fixed 5.5-inch diagram width: simplify tall graphs or adjust the export
layout if they waste space; never squash labels to force a fit.

Count with the same paper size, styles, and renderer used for delivery. Report
that LibreOffice pagination was checked; Word can paginate differently. If the
recipient requires exact Word pagination, validate there before claiming it.
Target one page, compress unnecessary detail if over one, and treat four as an
absolute gate rather than the default target.

## Emacs preview

Mermaid blocks use `:eval never-export :exports code :file diagram-name.png
:results file graphics :scale 2` (on one header line). Put point in the block and press
`C-c C-c` to render locally with `ob-mermaid` and `mmdc`; approve the usual Babel
confirmation. Each block needs a unique PNG filename. `:eval never` is for code
snippets, NOT Mermaid: it disables manual rendering as well as export evaluation.
Emacs must enable the `mermaid` Babel language. The DOCX helper remains independent
of Babel and renders the source itself, so previews are optional and aren't
embedded a second time.

For a larger inline preview, put an Org-only width on the rendered result:

```org
#+RESULTS: request-flow
#+attr_org: :width 1600
[[file:request-flow.png]]
```

Choose a width that fits the user's window, normally 1200–1600 pixels on a wide
screen. `:scale 2` supplies sharper image pixels; the result attribute controls
how large Emacs displays them. Org should have `org-image-actual-width` nil (or
another attribute-respecting setting). Refresh inline images after a sizing
change. Do not change global image settings or unrelated diagrams. The DOCX
exporter's separate 5.5-inch print width is unaffected by this preview attribute.

## Troubleshooting and limits

- A Mermaid render failure must be surfaced and corrected, not replaced silently
  with raw code or a missing image. `mmdc` may need a locally configured browser;
  respect the existing sandbox configuration, don't disable it automatically.
- No source execution, Emacs packages, network diagram services, or provider APIs
  are required. Never upload spec content to a rendering service without consent.
- The exporter handles `mermaid` source blocks, not arbitrary Babel workflows.
  Org `:exports` settings may suppress blocks before they reach Pandoc; use the
  template's `:exports code` convention.
- Images linked from Org resolve relative to the source document. Keep external
  assets alongside the spec; do not put generated artifacts in the skill bundle.
- Raw export blocks, included files, and unusual Org macros need explicit
  inspection: the helper is not a general Org publishing engine or sanitizer.
