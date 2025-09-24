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
        "title": "A New Perspective on High Dimensional Intervals"
    },
    {
        "name": "chap3",
        "dir": "../man-alt-post",
        "title": "Alternative Likelihoods for Lasso High-Dimensional Intervals"
    },
    {
        "name": "chap4",
        "dir": "../man-post-ext",
        "title": "Generalized High-Dimensional Intervals for Penalized Regression Models"
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

    # Mapping from citation key to replacement
    citation_map = {
        "AvgCov": "Chapter 2",
        "PIPEP": "Chapter 3",
    }

    # Pattern matches \cite{key}, \citet{key}, or \citep{key}
    pattern = re.compile(r"\\cite[t|p]?{([^}]+)}")

    def replacer(match):
        key = match.group(1)
        return citation_map.get(key, match.group(0))  # fallback to original if not mapped

    return pattern.sub(replacer, text)


def process_content(content: str) -> str:
    """Run all normalization steps on content."""
    # content = normalize_width(content)
    content = normalize_citations(content)
    return content

def _demote_sections_to_subsections(text: str) -> str:
    """
    Turn any \section{...}, \section*[...]{...}, or \section[opt]{...}
    into the corresponding \subsection... form. Leaves other macros alone.
    """
    # Replace the command token only; preserve any star and following args
    return re.sub(r'\\section(?=\s*\*?\s*[\[{])', r'\\subsection', text)

def _write_processed(src: Path, dst: Path, header: str, transform=lambda s: s) -> None:
    """Strip preamble, normalize, optionally transform body, then write with header."""
    raw = src.read_text()
    m   = re.search(r"\\begin\{document\}(.*)\\end\{document\}", raw, flags=re.S)
    body = m.group(1).strip() if m else raw
    body = process_content(body)
    body = transform(body)
    dst.write_text(header + body + "\n")

def copy_manuscripts() -> None:
    """
    Copy *main* and (optionally) *supp* TeX for every entry in PAPERS.

    chapN tries main-man{N-1}.tex / supp-man{N-1}.tex first, then falls back.
    Output names: chapN.tex and chapN-sup.tex

    Supplements:
      - start with \section{Supplemental Materials}
      - demote all \section to \subsection inside the copied content
    """
    for p in PAPERS:
        src_dir = Path(p["dir"]).resolve()
        chap_no = int(re.search(r"\d+", p["name"]).group())
        man_tag = f"man{chap_no - 1}" if chap_no > 2 else None

        # main
        main_candidates = [src_dir / f"main-{man_tag}.tex"] if man_tag else []
        main_candidates.append(src_dir / "main.tex")
        main_src = next((f for f in main_candidates if f.exists()), None)
        if main_src is None:
            print(f"[WARN] no main*.tex found in {src_dir}")
            continue

        # supp
        supp_candidates = [src_dir / f"supp-{man_tag}.tex"] if man_tag else []
        supp_candidates.append(src_dir / "supp.tex")
        supp_src = next((f for f in supp_candidates if f.exists()), None)

        # write main
        main_out = Path(f"chap{chap_no}.tex")
        main_header = f"\\chapter{{{p['title']}}}\\label{{sec:chap{chap_no}}}\n\n"
        _write_processed(main_src, main_out, main_header)

        # write supplement (if any)
        if supp_src:
            supp_out = Path(f"chap{chap_no}-sup.tex")
            supp_header = "\\section{Supplemental Materials}\n\n"
            _write_processed(
                supp_src,
                supp_out,
                supp_header,
                transform=_demote_sections_to_subsections
            )

    print("Main and supplementary TeX files copied to project root.")

def main():
    copy_r_scripts()
    copy_manuscripts()
    print("Sync complete.")


if __name__ == "__main__":
    main()
