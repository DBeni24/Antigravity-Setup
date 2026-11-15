---
name: repomap
description: >
  Lightweight repository mapper that traverses a codebase, extracts symbols
  (classes, functions), builds an import reference graph, ranks files by
  PageRank-like importance, and emits a compact ~1024-token summary to STDOUT.
  Use this skill whenever you need to understand the structure of an unfamiliar
  repository before reading individual files.
---

# RepoMap Skill

## When to Activate

Activate this skill **at the start of any task** that involves:

- Navigating or understanding an **unfamiliar codebase**
- Finding **where** a specific class or function likely lives
- Identifying the **most important / central files** to read first
- Building a mental model of a project **before making changes**
- Answering questions like "how is this project structured?"

> [!TIP]
> Run RepoMap first, then read only the top-ranked files in detail. This saves
> context-window budget compared to reading every file blindly.

## How to Invoke

```powershell
# Default (~1024 token output):
uv run C:\Users\HP\.gemini\config\skills\repomap\scripts\repomap.py <project_root>

# Extended output (~2048 tokens):
uv run C:\Users\HP\.gemini\config\skills\repomap\scripts\repomap.py <project_root> --max-tokens 2048

# Example:
uv run C:\Users\HP\.gemini\config\skills\repomap\scripts\repomap.py C:\Users\HP\my-project --max-tokens 1024
```

> [!NOTE]
> `uv run` requires no prior `pip install`; it handles execution directly.
> The script has **no external dependencies** — only the Python standard library.

## Output Format

```
# RepoMap — <root>
Files: N  |  Symbols: M

## path/to/file.py  [████████░░]  (123 lines)
  classes  : MyClass, AnotherClass
  functions: main, helper, parse_args +3 more
  imports  : os, sys, re, pathlib +2 more

## path/to/other.ts  [██████░░░░]  (87 lines)
  ...
```

Each file block shows:
- **Rank bar** (10 segments, filled by importance)
- **Line count**
- **Classes**, **functions**, **imports** (top N, with "+X more" suffix)

Files are sorted **highest rank first**. The rank combines:
1. PageRank from the import reference graph (how often other files import this file)
2. Symbol density (files with many classes/functions score higher)

## Supported Languages

| Extension | Classes | Functions | Imports |
|-----------|---------|-----------|---------|
| `.py`     | ✅       | ✅         | ✅       |
| `.ts`     | ✅       | ✅         | ✅       |
| `.js`     | ✅       | ✅         | ✅       |
| `.go`     | ✅ (structs) | ✅    | ✅       |
| `.java`   | ✅       | ✅         | ✅       |

## Ignored Automatically

`.git`, `node_modules`, `__pycache__`, `.venv`, `dist`, `build`, `target`,
`.idea`, `.vscode`, and other common non-source directories.

Files larger than **512 KB** are skipped.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `root` (positional) | `.` | Project root directory to scan |
| `--max-tokens N` | `1024` | Approximate output size in tokens |

## Integration Notes

- The script writes **only** to STDOUT; errors go to STDERR.
- Exit code `0` on success, `1` if the root directory is invalid.
- Safe to run on any directory; it never modifies files.
- Combine with `grep` / `Select-String` to filter output by keyword.
