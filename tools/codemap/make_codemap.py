"""Builds docs/CODE-MAP.md: the code's table of contents (owner, Nov 21: "read only the part you need").

One line per file (path, size, what it is) and one line per function with its line number, so Claude can
Grep the map for a word, jump to the right file and line, and read only ~60 lines instead of a whole file.
Runs by itself at the start of every Claude chat (SessionStart hook in .claude/settings.json); safe to run
any time:  python tools/codemap/make_codemap.py
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs", "CODE-MAP.md")
SCAN = [("src", ".gd"), ("tests", ".gd"), ("tools", ".gd"), ("tools", ".py"), ("video/scripts", ".py")]
SKIP_DIRS = {".venv", "venv", "site-packages", "__pycache__", "node_modules", ".godot", "addons"}
GD_FUNC = re.compile(r"^(static\s+)?func\s+(\w+)")
GD_CLASS = re.compile(r"^class(_name)?\s+(\w+)")
PY_FUNC = re.compile(r"^(def|class)\s+(\w+)")


def purpose(lines, ext):
    """First comment sentence near the top of the file (what the file is for)."""
    for ln in lines[:15]:
        s = ln.strip()
        if ext == ".gd" and s.startswith("#"):
            return s.lstrip("#").strip()
        if ext == ".py" and (s.startswith('"""') or s.startswith("#")):
            t = s.strip('"').lstrip("#").strip()
            if t:
                return t
    return ""


def main():
    files = []
    for base, ext in SCAN:
        for dp, dns, fns in os.walk(os.path.join(ROOT, base)):
            dns[:] = sorted(d for d in dns if d not in SKIP_DIRS)
            for fn in sorted(fns):
                if fn.endswith(ext):
                    files.append(os.path.join(dp, fn))
    out = ["# Code map (made by tools/codemap/make_codemap.py — do not edit by hand)", "",
           "Never read this whole file: Grep it for a word (e.g. `Grep \"loot\" docs/CODE-MAP.md`), then read",
           "only ~60 lines of the file around the line number it gives. Line numbers are from the last chat start.", ""]
    for path in sorted(set(files)):
        rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
        with open(path, encoding="utf-8", errors="ignore") as f:
            lines = f.read().splitlines()
        ext = os.path.splitext(path)[1]
        about = purpose(lines, ext)[:110]
        out.append(f"## {rel} ({len(lines)} lines){' — ' + about if about else ''}")
        rx = PY_FUNC if ext == ".py" else GD_FUNC
        for i, ln in enumerate(lines, 1):
            m = rx.match(ln) or (GD_CLASS.match(ln) if ext == ".gd" else None)
            if m:
                out.append(f"- {rel}:{i} {m.group(2)}")
        out.append("")
    text = "\n".join(out)
    old = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
    if text != old:  # don't touch the file when nothing changed (parallel chats share the folder)
        with open(OUT, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)


if __name__ == "__main__":
    main()
