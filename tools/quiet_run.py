"""Runs a command (a Godot game run, the tests, a Blender script...) and prints only the useful part of its output,
to save Claude tokens (owner, Nov 21): everything printed stays in the chat and is re-read on every step.

  python3 tools/quiet_run.py <godot> --headless --audio-driver Dummy --path . -- claude=caves seed=42

- drops Godot's banner, blank lines and the end-of-run "leaked at exit" chatter (harmless, ~40 lines every run)
- folds repeats: the same line 17 times becomes one line "(x17)"
- keeps every ERROR / FAIL / your own prints; if it's still long, keeps the first 40 and last 80 lines
- keeps the command's exit code. Add QUIET=0 to the environment to see everything.
"""
import os
import re
import subprocess
import sys

DROP = [
    re.compile(r"^Godot Engine v\d"),
    re.compile(r"leaked at exit|still in use at exit|Pages in use exist at exit|Leaked instance dependency"),
    re.compile(r"^\s+at: ~Dependency|^\s+at: \(?(servers|core|drivers|modules)/.*cleanup|^\s+at: .*_leak"),
    re.compile(r"^\s*$"),
]
HEAD, TAIL = 40, 80


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = subprocess.run(sys.argv[1:], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.decode("utf-8", "replace").splitlines()
    if os.environ.get("QUIET") == "0":
        print("\n".join(lines))
        return p.returncode
    kept, counts, order = [], {}, []
    dropped = False
    for ln in lines:
        ln = ln.rstrip()
        if any(rx.search(ln) for rx in DROP) or (dropped and ln.lstrip().startswith("at: ")):
            dropped = not ln.strip() == ""  # an "at:" line belongs to the dropped line above it
            continue
        dropped = False
        key = re.sub(r"^\[\d\d:\d\d:\d\d\] ", "", ln)  # same message at another time = a repeat
        if "FAIL" in ln or ln.startswith("        - "):  # test failures are never folded (each belongs to its test)
            key = f"{len(order)}\0{key}"
        if key in counts:
            counts[key] += 1
            continue
        counts[key] = 1
        order.append((key, ln))
    kept = [ln + (f"  (x{counts[k]})" if counts[k] > 1 else "") for k, ln in order]
    if len(kept) > HEAD + TAIL:
        cut = len(kept) - HEAD - TAIL
        kept = kept[:HEAD] + [f"... {cut} lines hidden (run with QUIET=0 to see all) ..."] + kept[-TAIL:]
    print("\n".join(kept))
    if p.returncode:
        print(f"(exit code {p.returncode})")
    return p.returncode


if __name__ == "__main__":
    sys.exit(main())
