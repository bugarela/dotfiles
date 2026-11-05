#!/usr/bin/env python3
"""Export Org via Pandoc; render Mermaid without evaluating Org source blocks."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def run(args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, **kwargs)


def require(name):
    if not shutil.which(name):
        raise RuntimeError(f"Missing dependency: {name}")


def export(source, output, reference=None, draft=False):
    require("pandoc")
    if not draft:
        require("libreoffice")
        require("pdfinfo")
    if source == output:
        raise RuntimeError("Source and output must be different files")
    if output.exists():
        raise RuntimeError(f"Refusing to overwrite {output}; choose a new output path")
    if not output.parent.is_dir():
        raise RuntimeError(f"Output directory does not exist: {output.parent}")

    with tempfile.TemporaryDirectory(prefix="org-spec-") as directory:
        work = Path(directory)
        # Org comments are omitted by Pandoc's reader. No Babel is invoked.
        ast = json.loads(run([
            "pandoc", str(source), "--from=org", "--to=json"
        ], cwd=source.parent).stdout)
        count = 0

        def render(node):
            nonlocal count
            if isinstance(node, list):
                return [render(item) for item in node]
            if not isinstance(node, dict):
                return node
            if node.get("t") == "CodeBlock":
                attributes, code = node["c"]
                if "mermaid" in attributes[1]:
                    require("mmdc")
                    count += 1
                    diagram = work / f"diagram-{count}.mmd"
                    image = diagram.with_suffix(".png")
                    diagram.write_text(code, encoding="utf-8")
                    run(["mmdc", "-i", str(diagram), "-o", str(image),
                         "-b", "white", "-s", "2"], cwd=source.parent)
                    # Keep source in Org; embed only the rendered image in DOCX.
                    return {"t": "Para", "c": [{
                        "t": "Image", "c": [
                            [attributes[0], [], [["width", "5.5in"]]],
                            [{"t": "Str", "c": f"Diagram {count}"}],
                            [str(image), ""]
                        ]
                    }]}
            return {key: render(value) for key, value in node.items()}

        ast = render(ast)
        docx = work / "spec.docx"
        args = ["pandoc", "--from=json", "--to=docx", "--output", str(docx),
                "--resource-path", str(source.parent)]
        if reference:
            args += ["--reference-doc", str(reference)]
        run(args, input=json.dumps(ast).encode(), cwd=source.parent)

        if draft:
            shutil.copyfile(docx, output)
            print(f"DRAFT: {output}; pagination UNVERIFIED; diagrams rendered: {count}")
            return

        # Isolate LibreOffice from any running desktop instance.
        pdfdir = work / "pdf"
        pdfdir.mkdir()
        profile = (work / "lo-profile").as_uri()
        run(["libreoffice", f"-env:UserInstallation={profile}", "--headless",
             "--convert-to", "pdf", "--outdir", str(pdfdir), str(docx)])
        pdf = pdfdir / "spec.pdf"
        info = run(["pdfinfo", str(pdf)], text=True).stdout
        match = re.search(r"^Pages:\s+(\d+)\s*$", info, flags=re.MULTILINE)
        if not match:
            raise RuntimeError("Could not determine rendered page count")
        pages = int(match.group(1))
        if not 1 <= pages <= 4:
            raise RuntimeError(f"Rendered {pages} pages (maximum 4); no final DOCX written")
        shutil.copyfile(docx, output)
        print(f"PAGE-CHECKED: {output}; {pages} page(s); diagrams rendered: {count}")
        print("Still inspect layout visually; pagination may vary in Microsoft Word.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--reference-doc", type=Path)
    parser.add_argument("--draft", action="store_true",
                        help="Export without pagination validation; not a final artifact")
    args = parser.parse_args()
    if args.output.suffix.lower() != ".docx":
        parser.error("output must have the .docx extension")
    try:
        export(args.source.resolve(), args.output.absolute(),
               args.reference_doc.resolve() if args.reference_doc else None,
               args.draft)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        if isinstance(error, subprocess.CalledProcessError):
            stderr = error.stderr or b""
            if isinstance(stderr, bytes):
                stderr = stderr.decode(errors="replace")
            parser.exit(1, f"Export failed: {error}\n{stderr}\n")
        parser.exit(1, f"Export failed: {error}\n")


if __name__ == "__main__":
    main()
