#!/usr/bin/env python3
"""Convert an Org spec to Markdown for a Linear document, keeping Mermaid as source."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess

REMOTE = re.compile(r"^(https?|mailto):", re.IGNORECASE)
BLOCKS = {"Plain", "Para", "LineBlock", "CodeBlock", "RawBlock", "BlockQuote",
          "OrderedList", "BulletList", "DefinitionList", "Header", "HorizontalRule",
          "Table", "Figure", "Div"}


def run(args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, **kwargs)


def text(inlines):
    """Plain text of Pandoc inlines, enough for a title."""
    parts = []
    for node in inlines:
        kind = node.get("t")
        if kind == "Str":
            parts.append(node["c"])
        elif kind in ("Space", "SoftBreak", "LineBreak"):
            parts.append(" ")
        elif kind in ("Emph", "Strong", "Strikeout", "Underline", "SmallCaps"):
            parts.append(text(node["c"]))
        elif kind in ("Code", "Math"):
            parts.append(node["c"][1])
        elif kind in ("Link", "Span", "Quoted"):
            parts.append(text(node["c"][1]))
    return "".join(parts).strip()


def convert(source, output):
    if not shutil.which("pandoc"):
        raise RuntimeError("Missing dependency: pandoc")
    if source == output:
        raise RuntimeError("Source and output must be different files")
    if not output.parent.is_dir():
        raise RuntimeError(f"Output directory does not exist: {output.parent}")

    # Org comments, agent replies and COMMENT subtrees are omitted by Pandoc's reader.
    ast = json.loads(run(["pandoc", str(source), "--from=org", "--to=json"],
                         cwd=source.parent).stdout)
    meta_title = ast.get("meta", {}).get("title", {}).get("c", [])
    title = text(meta_title) if isinstance(meta_title, list) else ""

    # A Mermaid block's cached preview is a local PNG Linear cannot show; the
    # diagram itself renders from the source block.
    previews = set()

    def collect(node):
        if isinstance(node, list):
            for item in node:
                collect(item)
        elif isinstance(node, dict):
            if node.get("t") == "CodeBlock" and "mermaid" in node["c"][0][1]:
                previews.update(v for k, v in node["c"][0][2] if k == "file")
            for value in node.values():
                collect(value)

    collect(ast["blocks"])
    diagrams = 0
    local = []

    def mermaid(code):
        nonlocal diagrams
        diagrams += 1
        # Linear turns exactly "```mermaid" into a diagram.
        return {"t": "RawBlock", "c": ["markdown", f"```mermaid\n{code.rstrip()}\n```"]}

    def blocks(items):
        result = []
        for block in items:
            if block.get("t") == "Div" and "captioned-content" in block["c"][0][1]:
                caption, body = [], []
                for inner in block["c"][1]:
                    if inner.get("t") == "Div" and "caption" in inner["c"][0][1]:
                        for part in inner["c"][1]:
                            caption += part["c"] if part.get("t") in ("Plain", "Para") else []
                    else:
                        body.append(inner)
                result += blocks(body)
                if caption:
                    result.append({"t": "Para", "c": [{"t": "Emph", "c": caption}]})
                continue
            if block.get("t") == "Para" and len(block["c"]) == 1 \
                    and block["c"][0].get("t") == "Image" \
                    and block["c"][0]["c"][2][0] in previews:
                continue
            if block.get("t") == "CodeBlock" and "mermaid" in block["c"][0][1]:
                result.append(mermaid(block["c"][1]))
                continue
            result.append(walk(block))
        return result

    def walk(node):
        if isinstance(node, list):
            if node and all(isinstance(item, dict) and item.get("t") in BLOCKS
                            for item in node):
                return blocks(node)
            return [walk(item) for item in node]
        if not isinstance(node, dict):
            return node
        if node.get("t") in ("Image", "Link"):
            target = node["c"][2][0]
            if not REMOTE.match(target) and not target.startswith("#"):
                local.append(target)
        return {key: walk(value) for key, value in node.items()}

    ast["blocks"] = blocks(ast["blocks"])
    ast["meta"] = {}
    markdown = run(["pandoc", "--from=json", "--to=gfm-tex_math_dollars", "--wrap=none"],
                   input=json.dumps(ast).encode()).stdout.decode()
    output.write_text(markdown, encoding="utf-8")
    print(json.dumps({"title": title, "markdown": str(output), "diagrams": diagrams,
                      "local_references": sorted(set(local))}, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.suffix.lower() != ".md":
        parser.error("output must have the .md extension")
    try:
        convert(args.source.resolve(), args.output.absolute())
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        if isinstance(error, subprocess.CalledProcessError):
            stderr = error.stderr or b""
            if isinstance(stderr, bytes):
                stderr = stderr.decode(errors="replace")
            parser.exit(1, f"Conversion failed: {error}\n{stderr}\n")
        parser.exit(1, f"Conversion failed: {error}\n")


if __name__ == "__main__":
    main()
