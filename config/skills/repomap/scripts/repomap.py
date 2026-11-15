#!/usr/bin/env python3
"""
RepoMap - Lightweight repository mapper for AI agents.

Traverses a project directory, extracts symbols (classes/functions),
builds an import reference graph, ranks symbols by PageRank-like scoring,
and outputs a compact ~1024-token summary to STDOUT.

Usage:
    python repomap.py <root_dir> [--max-tokens N]
"""

import sys
import os
import re
import math
import argparse
from collections import defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SUPPORTED_EXTENSIONS = {".py", ".ts", ".js", ".go", ".java"}

IGNORE_DIRS = {
    ".git", ".hg", ".svn", "__pycache__", "node_modules",
    ".venv", "venv", "env", ".env", "dist", "build", "target",
    ".mypy_cache", ".pytest_cache", ".tox", "coverage",
    ".idea", ".vscode",
}

MAX_FILE_SIZE_BYTES = 512 * 1024  # 512 KB

# Approx chars per token (conservative)
CHARS_PER_TOKEN = 4

# ---------------------------------------------------------------------------
# Symbol extraction (regex-based, no tree-sitter required)
# ---------------------------------------------------------------------------

PATTERNS = {
    ".py": {
        "class": re.compile(r"^class\s+(\w+)", re.MULTILINE),
        "func":  re.compile(r"^(?:async\s+)?def\s+(\w+)", re.MULTILINE),
        "import": re.compile(
            r"^\s*(?:from\s+([\w.]+)\s+import|import\s+([\w., ]+))",
            re.MULTILINE,
        ),
    },
    ".ts": {
        "class": re.compile(r"(?:^|\s)class\s+(\w+)", re.MULTILINE),
        "func":  re.compile(
            r"(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?\()",
            re.MULTILINE,
        ),
        "import": re.compile(r"^\s*import\s+.*?from\s+['\"]([^'\"]+)['\"]", re.MULTILINE),
    },
    ".js": {
        "class": re.compile(r"(?:^|\s)class\s+(\w+)", re.MULTILINE),
        "func":  re.compile(
            r"(?:function\s+(\w+)|(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?\()",
            re.MULTILINE,
        ),
        "import": re.compile(r"^\s*(?:import|require)\s*.*?['\"]([^'\"]+)['\"]", re.MULTILINE),
    },
    ".go": {
        "class": re.compile(r"^type\s+(\w+)\s+struct", re.MULTILINE),
        "func":  re.compile(r"^func\s+(?:\(\w+\s+\*?\w+\)\s+)?(\w+)\s*\(", re.MULTILINE),
        "import": re.compile(r'"([\w./]+)"', re.MULTILINE),
    },
    ".java": {
        "class": re.compile(r"(?:class|interface|enum)\s+(\w+)", re.MULTILINE),
        "func":  re.compile(
            r"(?:public|protected|private|static|\s)+[\w<>\[\]]+\s+(\w+)\s*\([^)]*\)\s*(?:throws[^{]*)?\{",
            re.MULTILINE,
        ),
        "import": re.compile(r"^\s*import\s+([\w.]+);", re.MULTILINE),
    },
}

# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

class FileInfo:
    def __init__(self, path: str, rel_path: str, ext: str):
        self.path = path
        self.rel_path = rel_path
        self.ext = ext
        self.classes: list[str] = []
        self.functions: list[str] = []
        self.imports: list[str] = []
        self.line_count: int = 0
        self.rank: float = 1.0

# ---------------------------------------------------------------------------
# File traversal
# ---------------------------------------------------------------------------

def find_files(root: Path) -> list[FileInfo]:
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        # Prune ignored directories in-place
        dirnames[:] = [
            d for d in dirnames
            if d not in IGNORE_DIRS and not d.startswith(".")
        ]
        for fname in filenames:
            ext = Path(fname).suffix.lower()
            if ext not in SUPPORTED_EXTENSIONS:
                continue
            full_path = os.path.join(dirpath, fname)
            if os.path.getsize(full_path) > MAX_FILE_SIZE_BYTES:
                continue
            rel = os.path.relpath(full_path, root)
            files.append(FileInfo(full_path, rel, ext))
    return files

# ---------------------------------------------------------------------------
# Symbol extraction
# ---------------------------------------------------------------------------

def extract_symbols(fi: FileInfo) -> None:
    try:
        with open(fi.path, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return

    fi.line_count = content.count("\n") + 1
    pats = PATTERNS.get(fi.ext, {})

    if "class" in pats:
        fi.classes = pats["class"].findall(content)
        # flatten tuples if any group
        fi.classes = [c if isinstance(c, str) else next((x for x in c if x), "") for c in fi.classes]

    if "func" in pats:
        raw = pats["func"].findall(content)
        funcs = []
        for item in raw:
            if isinstance(item, str):
                funcs.append(item)
            else:
                funcs.append(next((x for x in item if x), ""))
        fi.functions = [f for f in funcs if f]

    if "import" in pats:
        raw = pats["import"].findall(content)
        imports = []
        for item in raw:
            if isinstance(item, str):
                imports.append(item.strip())
            else:
                for x in item:
                    if x:
                        imports.extend(p.strip() for p in x.split(","))
        fi.imports = [i for i in imports if i]

# ---------------------------------------------------------------------------
# Reference graph & PageRank
# ---------------------------------------------------------------------------

def build_graph(files: list[FileInfo]) -> dict[str, list[str]]:
    """Return adjacency list: file_rel_path -> [referenced_rel_paths]."""
    # Build a quick lookup: module-name-like string -> rel_path
    stem_to_rel: dict[str, str] = {}
    for fi in files:
        stem = Path(fi.rel_path).stem
        stem_to_rel[stem] = fi.rel_path
        # Also index by dot-path relative to root
        dot_path = fi.rel_path.replace(os.sep, ".").replace("/", ".").removesuffix(fi.ext)
        stem_to_rel[dot_path] = fi.rel_path

    graph: dict[str, list[str]] = defaultdict(list)
    for fi in files:
        for imp in fi.imports:
            # Try to match import string to a known file
            # Strip leading dots (relative imports)
            normalized = imp.lstrip(".")
            # Try exact dot-path match, then stem match
            target = None
            for key, rel in stem_to_rel.items():
                if normalized and (key.endswith(normalized) or normalized.endswith(key)):
                    target = rel
                    break
            if target and target != fi.rel_path:
                graph[fi.rel_path].append(target)
    return dict(graph)

def pagerank(files: list[FileInfo], graph: dict[str, list[str]],
             damping: float = 0.85, iterations: int = 20) -> None:
    """Assign rank scores to files in-place."""
    n = len(files)
    if n == 0:
        return

    rel_paths = [fi.rel_path for fi in files]
    idx = {rel: i for i, rel in enumerate(rel_paths)}
    scores = [1.0 / n] * n

    # Build in-link map
    in_links: dict[int, list[int]] = defaultdict(list)
    out_count = [0] * n
    for src_rel, dests in graph.items():
        if src_rel not in idx:
            continue
        s = idx[src_rel]
        for d_rel in dests:
            if d_rel in idx:
                d = idx[d_rel]
                in_links[d].append(s)
                out_count[s] += 1

    for _ in range(iterations):
        new_scores = [(1 - damping) / n] * n
        for i in range(n):
            for j in in_links[i]:
                if out_count[j] > 0:
                    new_scores[i] += damping * scores[j] / out_count[j]
        scores = new_scores

    # Normalize to [0,1]
    max_s = max(scores) or 1.0
    for fi, s in zip(files, scores):
        fi.rank = s / max_s

    # Boost by symbol count
    for fi in files:
        sym_count = len(fi.classes) + len(fi.functions)
        fi.rank = fi.rank * 0.7 + min(sym_count / 50, 1.0) * 0.3

# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

def format_output(root: Path, files: list[FileInfo], max_tokens: int) -> str:
    max_chars = max_tokens * CHARS_PER_TOKEN
    lines = []

    # Header
    header = f"# RepoMap — {root}\n"
    lines.append(header)

    total_files = len(files)
    total_symbols = sum(len(f.classes) + len(f.functions) for f in files)
    lines.append(f"Files: {total_files}  |  Symbols: {total_symbols}\n\n")

    # Sort by rank descending
    sorted_files = sorted(files, key=lambda f: f.rank, reverse=True)

    char_budget = max_chars - sum(len(l) for l in lines)

    for fi in sorted_files:
        if char_budget <= 0:
            lines.append("... (truncated)\n")
            break

        rank_bar = "█" * min(10, max(1, round(fi.rank * 10)))
        entry_lines = [f"\n## {fi.rel_path}  [{rank_bar}]  ({fi.line_count} lines)\n"]

        if fi.classes:
            entry_lines.append(f"  classes  : {', '.join(fi.classes[:8])}\n")
        if fi.functions:
            shown = fi.functions[:10]
            rest = len(fi.functions) - len(shown)
            suffix = f" +{rest} more" if rest > 0 else ""
            entry_lines.append(f"  functions: {', '.join(shown)}{suffix}\n")
        if fi.imports:
            shown_i = fi.imports[:5]
            rest_i = len(fi.imports) - len(shown_i)
            suffix_i = f" +{rest_i} more" if rest_i > 0 else ""
            entry_lines.append(f"  imports  : {', '.join(shown_i)}{suffix_i}\n")

        entry_text = "".join(entry_lines)
        char_budget -= len(entry_text)
        lines.append(entry_text)

    return "".join(lines)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="RepoMap — compact repo summary for AI agents")
    parser.add_argument("root", nargs="?", default=".", help="Project root directory")
    parser.add_argument("--max-tokens", type=int, default=1024, dest="max_tokens",
                        help="Approximate token budget for output (default: 1024)")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"ERROR: '{root}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    files = find_files(root)
    if not files:
        print(f"No supported source files found in '{root}'.", file=sys.stderr)
        sys.exit(0)

    for fi in files:
        extract_symbols(fi)

    graph = build_graph(files)
    pagerank(files, graph)

    output = format_output(root, files, args.max_tokens)
    print(output)

if __name__ == "__main__":
    main()
