"""Measure the approved dwarf turnaround picture (assets/concepts/dwarf/dwarf_turnaround.png: front, side, back on a
plain grey background) for the body round (owner, Nov 16: "do this for his entire body now"). By Claude, Nov 17, 2026.

    python tools/asset_forge/dwarf_turnaround_measure.py [out.png]

Finds the dwarf's outline in each view, scales it so the crown is at 1.19 m and the soles at 0 (the head round's
size), and prints the width (front view) and depth (side view: front edge, back edge) every 2.5 cm of height, plus
where the key parts are, found from the colours (shirt hem, shorts cuffs, wraps). With [out.png]: draws the outlines
and the measured heights, to check by eye.
"""
import sys

import numpy as np
from PIL import Image, ImageDraw

PIC = "assets/concepts/dwarf/dwarf_turnaround.png"
CROWN = 1.19

im = np.asarray(Image.open(PIC).convert("RGB")).astype(np.float32)
H, W, _ = im.shape
bg = np.median(np.concatenate([im[:8].reshape(-1, 3), im[-8:].reshape(-1, 3)]), axis=0)
mask = np.abs(im - bg).max(axis=2) > 28
cols = mask.sum(axis=0)
# the three views: runs of columns with dwarf in them, split at the widest empty gaps
filled = cols > 2
runs, start = [], None
for x in range(W):
	if filled[x] and start is None:
		start = x
	if not filled[x] and start is not None:
		runs.append([start, x])
		start = None
if start is not None:
	runs.append([start, W])
merged = [runs[0]]
for a, b in runs[1:]:
	if a - merged[-1][1] < 25:
		merged[-1][1] = b
	else:
		merged.append([a, b])
views = sorted(merged, key=lambda r: r[1] - r[0], reverse=True)[:3]
views.sort()
names = ["front", "side", "back"]
out = {}
for name, (x0, x1) in zip(names, views):
	m = mask[:, x0:x1]
	rows = np.nonzero(m.any(axis=1))[0]
	top, bot = rows.min(), rows.max()
	px_per_m = (bot - top) / CROWN
	out[name] = (x0, x1, top, bot, px_per_m)
	print(f"VIEW {name}: columns {x0}-{x1}, crown row {top}, sole row {bot}, {px_per_m:.1f} px per metre")


def height_of(row, name):
	x0, x1, top, bot, k = out[name]
	return (bot - row) / k


def row_of(h, name):
	x0, x1, top, bot, k = out[name]
	return int(round(bot - h * k))


# colours: shirt (light linen), shorts (brown), wraps (pale), skin, hair (orange-red)
def classify(rgb):
	r, g, b = rgb
	if r > 150 and g > 120 and b > 80 and abs(r - g) < 45 and r - b < 80:
		return "linen"
	if r > 150 and g < 110 and b < 70:
		return "hair"
	if 70 < r < 150 and 40 < g < 100 and b < 70 and r - g > 20:
		return "shorts"
	return "other"


print("HEIGHT (m) | front: width (m) | side: front edge .. back edge (m, from the outline's middle at hip height) | front pieces (m)")
fx0, fx1, ftop, fbot, fk = out["front"]
sx0, sx1, stop_, sbot, sk = out["side"]
hip_row = row_of(0.42, "side")
srow = np.nonzero(mask[hip_row, sx0:sx1])[0]
s_mid = sx0 + (srow.min() + srow.max()) / 2
for h in np.arange(0.0, CROWN + 0.001, 0.025):
	fr = row_of(h, "front")
	fxs = np.nonzero(mask[fr, fx0:fx1])[0]
	width = (fxs.max() - fxs.min()) / fk if len(fxs) else 0.0
	sr = row_of(h, "side")
	sxs = np.nonzero(mask[sr, sx0:sx1])[0]
	front_e = (sxs.min() + sx0 - s_mid) / sk if len(sxs) else 0.0
	back_e = (sxs.max() + sx0 - s_mid) / sk if len(sxs) else 0.0
	# the separate pieces across this row (arm | body | arm, or leg | leg), each as (left, right) in metres from the
	# picture's middle line
	pieces, run = [], None
	row = mask[fr, fx0:fx1]
	cx = (fxs.min() + fxs.max()) / 2 if len(fxs) else 0
	for x in range(len(row) + 1):
		on = x < len(row) and row[x]
		if on and run is None:
			run = x
		if not on and run is not None:
			if x - run > 3:
				pieces.append(f"{(run - cx) / fk:+.3f}..{(x - cx) / fk:+.3f}")
			run = None
	print(f"{h:5.3f} | {width:5.3f} | {front_e:+.3f} .. {back_e:+.3f} | {'  '.join(pieces)}")
if len(sys.argv) > 1:
	img = Image.open(PIC).convert("RGB")
	d = ImageDraw.Draw(img)
	for name in names:
		x0, x1, top, bot, k = out[name]
		for h in np.arange(0.0, CROWN, 0.1):
			r = row_of(h, name)
			d.line([(x0, r), (x1, r)], fill=(0, 120, 255), width=1)
			d.text((x0 + 2, r - 10), f"{h:.1f}", fill=(0, 60, 160))
	img.save(sys.argv[1])
	print("SAVED", sys.argv[1])
