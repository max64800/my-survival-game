"""Close long silences INSIDE edit segments (Max's rule: no dead air mid-sentence).

Splits every segment in work/<clip>/edl.json wherever the voice drops out for longer than MAX_GAP, keeping a
little padding around each voiced run. Run after cut.py, then render with `cut.py <raw> --from-edl --force`.
Usage: python editor/close_pauses.py Raw/IMG_XXXX.MOV
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np

MAX_GAP = 0.35      # seconds of silence allowed inside a line
PAD = 0.08          # keep this much air around each voiced run
HOP = 0.02


def voiced_runs(src, a, b):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", f"{a:.3f}", "-t", f"{b - a:.3f}", "-i", str(src), "-vn", "-ac", "1",
                          "-ar", "16000", "-f", "f32le", "-"], capture_output=True).stdout
    x = np.frombuffer(raw, np.float32)
    hop = int(16000 * HOP)
    db = np.array([20 * np.log10(np.sqrt((x[i:i + hop] ** 2).mean()) + 1e-9) for i in range(0, len(x) - hop, hop)])
    if not len(db):
        return [(a, b)]
    thr = max(db.max() - 30, -42)                   # voice = within 30 dB of this line's loudest moment
    on = db > thr
    runs, st = [], None
    for i, v in enumerate(on):
        if v and st is None:
            st = i
        if not v and st is not None:
            runs.append([a + st * HOP, a + i * HOP]); st = None
    if st is not None:
        runs.append([a + st * HOP, b])
    merged = []                                     # glue runs separated by short gaps (normal speech)
    for r in runs:
        if merged and r[0] - merged[-1][1] <= MAX_GAP:
            merged[-1][1] = r[1]
        else:
            merged.append(r)
    return [(max(a, s - PAD), min(b, e + PAD)) for s, e in merged if e - s > 0.12]


def main(src):
    clip = Path(src).stem
    p = Path("work") / clip / "edl.json"
    edl = json.load(open(p))
    out = []
    for seg in edl:
        runs = voiced_runs(src, seg["start"], seg["end"])
        if len(runs) <= 1:
            out.append(seg)
            continue
        print(f'split {seg["start"]:.2f}-{seg["end"]:.2f} into {len(runs)}: "{seg.get("text", "")[:50]}"')
        for s, e in runs:
            out.append({**seg, "start": round(s, 2), "end": round(e, 2)})
    json.dump(out, open(p, "w"), indent=1)
    print(f"{len(edl)} -> {len(out)} segments")


if __name__ == "__main__":
    main(sys.argv[1])
