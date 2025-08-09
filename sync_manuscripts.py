#!/usr/bin/env python3
"""
sync_manuscripts.py

Copies R scripts and manuscript TeX files from each paper folder into your thesis root.
Prepends a \chapter{...}\label{sec:...} line using the provided chapter titles.
Normalizes any width=<fraction>\\linewidth to width=\\linewidth and replaces specific citations.
Run from the thesis project root:

    python sync_manuscripts.py

"""
import shutil
import re
from pathlib import Path

# --------------------
# Configuration
# --------------------
# Target directory in thesis project for all R scripts
TARGET_CODE_DIR = Path("code")

# List of papers: each with a unique chapter key, folder path, and display title
PAPERS = [
    {
        "name": "chap2",
        "dir": "../man-avg-cov",
        "title": "A New Perspective on High Dimensional Confidence Intervals"
    },
    {
        "name": "chap3",
        "dir": "../man-alt-post",
        "title": "Average Coverage CIs: Alternative Likelihood Constructions"
    },
    {
        "name": "chap4",
        "dir": "../man-post-ext",
        "title": "Extending Laplace-Normal Quantile Computation"
    },
]
# Only copy setup.R once (from the first paper)
SETUP_FILENAME = "setup.R"

# --------------------
# Helper functions
# --------------------
def copy_r_scripts():
    """Copy all .R files into TARGET_CODE_DIR, copying setup.R only once."""
    TARGET_CODE_DIR.mkdir(exist_ok=True)
    setup_copied = False

    for paper in PAPERS:
        src_code = Path(paper["dir"]) / "code"
        if not src_code.is_dir():
            print(f"Warning: code directory not found: {src_code}")
            continue
        for rfile in src_code.glob("*.R"):
            dest = TARGET_CODE_DIR / rfile.name
            if rfile.name == SETUP_FILENAME:
                if not setup_copied:
                    shutil.copy(rfile, dest)
                    setup_copied = True
            else:
                shutil.copy(rfile, dest)
    print("R scripts copied to code/.")


# def normalize_width(text: str) -> str:
#     """Replace any width=<number>\\linewidth with width=\\linewidth."""
#     return re.sub(r"width\s*=\s*[0-9]+(?:\.[0-9]+)?\\linewidth", r"width=\\linewidth", text)


def normalize_citations(text: str) -> str:
    """Replace specific citations with chapter/author references."""
    # Replace literal \cite{AvgCov} with 'Chapter 2'
    text = text.replace(r"\cite{AvgCov}", "Chapter 2")
    # Replace literal \cite{PIPEP} with 'Chapter 3'
    text = text.replace(r"\cite{PIPEP}", "Chapter 3")
    # Replace literal \cite{PIPE} with 'Biyue Dai in her dissertation'
    text = text.replace(r"\cite{PIPE}", "Biyue Dai in her dissertation")
    return text


def process_content(content: str) -> str:
    """Run all normalization steps on content."""
    # content = normalize_width(content)
    content = normalize_citations(content)
    return content

def _write_processed(src: Path, dst: Path, header: str) -> None:
    """Strip preamble, normalise content, write with header."""
    raw = src.read_text()
    m   = re.search(r"\\begin\{document\}(.*)\\end\{document\}", raw, flags=re.S)
    body = m.group(1).strip() if m else raw
    dst.write_text(header + process_content(body) + "\n")

def copy_manuscripts() -> None:
    """
    Copy *main* and (optionally) *supp* TeX for every entry in PAPERS.

    * chapN looks for main-man{N-1}.tex / supp-man{N-1}.tex first,
      otherwise falls back to main.tex / supp.tex.
    * Output names are always chapN.tex and chapN-sup.tex.
    * Supplements start with an unnumbered section called
      “Supplementary Materials”, **not** a new chapter.
    """
    for p in PAPERS:
        src_dir = Path(p["dir"]).resolve()
        chap_no = int(re.search(r"\d+", p["name"]).group())      # chap3 → 3
        man_tag = f"man{chap_no - 1}" if chap_no > 2 else None   # chap3 → man2

        # ---------------- locate main -----------------
        main_src = next(
            (f for f in ([src_dir / f"main-{man_tag}.tex"] if man_tag else [])
                       + [src_dir / "main.tex"]
             if f.exists()), None)

        if main_src is None:
            print(f"[WARN] no main*.tex found in {src_dir}")
            continue

        # ---------------- locate supplement -----------
        supp_src = next(
            (f for f in ([src_dir / f"supp-{man_tag}.tex"] if man_tag else [])
                       + [src_dir / "supp.tex"]
             if f.exists()), None)

        # ---------------- write MAIN ------------------
        main_out = Path(f"chap{chap_no}.tex")
        header   = f"\\chapter{{{p['title']}}}\\label{{sec:chap{chap_no}}}\n\n"
        _write_processed(main_src, main_out, header)

        # ---------------- write SUPP ------------------
        if supp_src:
            supp_out   = Path(f"chap{chap_no}-sup.tex")
            SUPP_HEADER = "\\section*{Supplementary Materials}\n\n"
            _write_processed(supp_src, supp_out, SUPP_HEADER)

    print("Main and supplementary TeX files copied to project root.")

def main():
    copy_r_scripts()
    copy_manuscripts()
    print("Sync complete.")


if __name__ == "__main__":
    main()
