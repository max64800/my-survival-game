"""Step 1 for the owner's one-handed videos (F389 chat 13: sword IMG_4428, mace IMG_4429; front view, pale blue glove =
RIGHT hand with a white stick, orange glove = LEFT fist at his chest).
Reads <dir>/track.json (track_all_frames.py) and <dir>/frames/, then per frame:
  - mends the body points where the tracker lost him or put both hands on one fist (fills in from the frames around),
  - smooths them a little (the tracker jitters),
  - finds the stick (stick_finder.py) from the right fist.
Writes <dir>/scan.json and <dir>/timeline.png (the fist's speed and height over time: the hits are the speed peaks).
  python one_hand_scan.py <dir>
By the dwarf-animations Claude, chat 13, Nov 20, 2026."""
import json, math, sys
from pathlib import Path
import cv2
import numpy as np
import stick_finder as sf

D = Path(sys.argv[1])
T = json.load(open(D / "track.json"))
N = len(T)
px = np.full((N, 33, 2), np.nan); wd = np.full((N, 33, 3), np.nan)
for k, r in enumerate(T):
    if "px" in r:
        p = np.array(r["px"]); w = np.array(r["w"])
        if np.linalg.norm(p[16, :2] - p[15, :2]) < 45:  # both hands on one fist: the right one is wrong
            continue
        px[k] = p[:, :2]; wd[k] = w
# a jump of the right wrist much bigger than its neighbours = a wrong frame too
for k in range(1, N - 1):
    a, b, c = px[k - 1, 16], px[k, 16], px[k + 1, 16]
    if not (np.isnan(a).any() or np.isnan(b).any() or np.isnan(c).any()):
        if np.linalg.norm(b - (a + c) / 2) > 60 and np.linalg.norm(a - c) < 40:
            px[k] = np.nan; wd[k] = np.nan


def mend(arr):
    flat = arr.reshape(N, -1)
    good = ~np.isnan(flat[:, 0])
    idx = np.arange(N)
    for j in range(flat.shape[1]):
        flat[:, j] = np.interp(idx, idx[good], flat[good, j])
    return flat.reshape(arr.shape), good


def smooth(arr, s=1.2):
    k = np.exp(-0.5 * (np.arange(-4, 5) / s) ** 2); k /= k.sum()
    flat = arr.reshape(N, -1).copy()
    pad = np.pad(flat, ((4, 4), (0, 0)), mode="edge")
    out = sum(k[i] * pad[i:i + N] for i in range(9))
    return out.reshape(arr.shape)


px, good = mend(px); wd, _ = mend(wd)
px = smooth(px); wd = smooth(wd)
rows = []
prev = None
for k in range(N):
    img = cv2.imread(str(D / "frames" / f"f{k + 1:05d}.jpg"))
    p = px[k]
    hand = (p[16] + p[18] + p[20]) / 3
    fist = p[16] + (hand - p[16]) * 1.6
    s = sf.find(img, fist, prev)
    prev = s["angle"] if s and s["score"] > 1500 else None
    rows.append({"i": k + 1, "tracked": bool(good[k]), "fist": [float(x) for x in fist], "stick": s})
    if k % 300 == 0:
        print(k, flush=True)
json.dump({"px": np.round(px, 1).tolist(), "w": np.round(wd, 4).tolist(), "rows": rows}, open(D / "scan.json", "w"))

# timeline: fist speed (px/frame) and height, stick angle; 300 frames per strip
sp = np.r_[0, np.linalg.norm(np.diff(px[:, 16], axis=0), axis=1)]
H = 120; strips = []
for a in range(0, N, 300):
    img = np.full((H * 2, 300 * 3, 3), 255, np.uint8)
    for k in range(a, min(N, a + 300)):
        x = (k - a) * 3
        cv2.line(img, (x, H), (x, H - int(min(sp[k], 40) * 3)), (0, 0, 200), 2)
        y = int(np.clip((px[k, 16, 1] - 100) / 700 * H, 0, H - 1)) + H
        cv2.circle(img, (x, y), 1, (200, 0, 0), -1)
        if not good[k]:
            cv2.line(img, (x, 0), (x, 6), (0, 160, 0), 2)
        if k % 30 == 0:
            cv2.line(img, (x, 0), (x, 2 * H), (200, 200, 200), 1)
            cv2.putText(img, str(k + 1), (x + 2, 2 * H - 4), cv2.FONT_HERSHEY_SIMPLEX, 0.35, (0, 0, 0), 1)
    strips.append(img)
cv2.imwrite(str(D / "timeline.png"), np.vstack(strips))
print("done", N, "frames;", int((~good).sum()), "mended")
