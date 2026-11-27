# Bronze pictures for the hand-built bronze plate armour (F914 bronze, Claude, Nov 27, 2026).
# Round 3 (owner, Nov 27, page v27: "way too smooth and way too simple, it needs engravings like dwarven ruins"):
# hammered like the copper (deep dents again), and thick RAISED knot carving like the Nov 26 bronze picture
# (tools/art/sheets/bronze_armour_sheet_nov26.png). Our own patterns: a three-strand plait and a ring-and-four-loops
# knot round a stepped diamond (no other game's art).
#
#   python3 tools/art/make_bronze_plate.py
#
# Writes into assets/textures/armor/:
#   bronze_hammered_col.png / _nrm.png  the plates' middles (tile 2048 px, repeats seamlessly): copper's dent recipe
#                                       (make_hammered_copper.py: 20 x 24 deep round dents) in bronze colours
#   bronze_knot_col.png / _nrm.png      the raised knot band (2048 x 512 = 4 band widths, repeats left-right): two edge
#                                       rails and a three-strand plait, over-and-under, a carved line down each strand,
#                                       dark green patina deep in the cuts
#   bronze_medal_col.png / _nrm.png     the round knot medallion (1024 px): riveted rim, four links woven on a ring,
#                                       a stepped diamond in the middle
# and the heights (0 = deepest cut, 1 = top) the builder pushes out as real raised metal:
#   tools/art/heights/bronze_knot_height.png, bronze_medal_height.png  (copper_plate_armor.py metal=bronze)
# Normal maps are OpenGL / glTF style (green = up the picture).
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "textures" / "armor"
HGT = ROOT / "tools" / "art" / "heights"
HGT.mkdir(exist_ok=True)
rng = np.random.default_rng(697)

BRONZE = np.array([0.86, 0.62, 0.32])  # (round 1 at 0.70/0.52/0.28 read olive and dull in the game)
B_DARK = np.array([0.52, 0.33, 0.13])
B_LIGHT = np.array([1.0, 0.84, 0.55])
PATINA = np.array([0.035, 0.09, 0.06])  # (the cuts: dark green, matches the patina edges)


def wrap_blur(a, r, axes=(0, 1)):
	for ax in axes:
		n = a.shape[ax]
		c = np.cumsum(np.concatenate([a.take(range(-r - 1, 0), ax), a, a.take(range(0, r), ax)], ax), ax)
		a = (c.take(range(2 * r + 1, 2 * r + 1 + n), ax) - c.take(range(0, n), ax)) / (2 * r + 1)
	return a


def normals(height, s):
	gx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * s
	gy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * s
	nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
	return np.stack([-gx * nz, gy * nz, nz], -1)


def save(a, name, folder=OUT):
	Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).save(folder / name)
	print("saved", folder / name)


def smooth01(x):
	x = np.clip(x, 0, 1)
	return x * x * (3 - 2 * x)


# ---------------------------------------------------------------- hammered bronze (plates' middles), copper's recipe
N = 2048
COLS, ROWS = 20, 24  # (as copper; round 2's 32 x 36 soft dents were "way too smooth")
dx, dy = N / COLS, N / ROWS
pts = []
for r in range(ROWS):
	for c in range(COLS):
		pts.append((((c + 0.5 * (r % 2)) * dx + rng.uniform(-0.2, 0.2) * dx) % N,
			((r + 0.5) * dy + rng.uniform(-0.2, 0.2) * dy) % N))
pts = np.array(pts)
yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
d, idx = cKDTree(pts, boxsize=[N, N]).query(np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1), k=2)
f1, f2 = d[:, 0].reshape(N, N), d[:, 1].reshape(N, N)
cell = idx[:, 0].reshape(N, N)
edge = (f2 - f1) / dx
bowl = np.clip(edge / 0.45, 0, 1)
rad = rng.uniform(0.55, 0.68, len(pts))[cell] * dx
round_ = np.clip(1 - (f1 / rad) ** 2, 0, 1)
height = -(0.65 * round_ ** 0.8 + 0.35 * bowl ** 1.6) * rng.uniform(0.75, 1.25, len(pts))[cell]
height = wrap_blur(wrap_blur(height, 4), 3)
nrm = normals(height, 5.0)
save(nrm * 0.5 + 0.5, "bronze_hammered_nrm.png")
ridge = np.clip(1 - edge / 0.2, 0, 1) ** 2
dent = -height / max(1e-6, -height.min())
lit = np.clip(nrm @ (np.array([-0.45, 0.55, 0.7]) / np.linalg.norm([-0.45, 0.55, 0.7])), 0, 1)
lit = (lit - lit.mean()) / (lit.std() + 1e-9)
cloud = wrap_blur(wrap_blur(wrap_blur(rng.standard_normal((N, N)), 50), 50), 50)
cloud = (cloud - cloud.mean()) / (cloud.std() + 1e-9)
col = BRONZE[None, None] * rng.uniform(0.9, 1.08, len(pts))[cell][..., None]
col = col * (1 - 0.35 * dent[..., None]) + B_DARK * 0.35 * dent[..., None]
col = col * (1 - 0.18 * ridge[..., None]) + B_LIGHT * 0.18 * ridge[..., None]
col *= (1 + 0.13 * np.clip(lit, -2.5, 2.5))[..., None]
col *= (1 + 0.05 * cloud)[..., None]
save(col, "bronze_hammered_col.png")


# ---------------------------------------------------------------- knot drawing helpers
def strand_height(dist, hw, soft):
	"""A flat-topped strand with rounded shoulders and a carved line down its middle."""
	top = smooth01((hw - dist) / soft)
	line = 1 - 0.22 * smooth01(1 - dist / (hw * 0.16))
	return top * line


def weave(dists, over, hw, gap, soft):
	"""dists: list of distance fields (one per strand); over: index of the strand that lies on top at each pixel
	(or -1 where only one is near). Under-strands stop a gap short of the over-strand."""
	D = np.stack(dists)
	hgt = np.zeros(D.shape[1:])
	near = D < hw + gap
	for k in range(len(dists)):
		h = strand_height(D[k], hw, soft)
		blocked = np.zeros_like(h, bool)
		for j in range(len(dists)):
			if j != k:
				blocked |= (over == j) & near[j] & near[k]
		h = np.where(blocked, 0.0, h)
		hgt = np.maximum(hgt, h)
	return hgt


def finish(hgt, nrm_s, name, cuts_wide, floor=None):
	"""Colour + normal + height pictures from a 0..1 height: polished bronze on top, dark patina in the cuts."""
	H_, W_ = hgt.shape
	save(hgt, f"bronze_{name}_height.png", HGT)
	nn = normals(hgt, nrm_s)
	save(nn * 0.5 + 0.5, f"bronze_{name}_nrm.png")
	lit = nn @ (np.array([-0.45, 0.55, 0.7]) / np.linalg.norm([-0.45, 0.55, 0.7]))
	occl = np.clip(hgt - wrap_blur(hgt, cuts_wide) + 0.5, 0, 1)  # (dark close under each raised edge)
	cl = wrap_blur(wrap_blur(rng.standard_normal((H_, W_)), 30), 30)
	cl = (cl - cl.mean()) / (cl.std() + 1e-9)
	top = smooth01(hgt / 0.55)
	metal = BRONZE[None, None] * (0.95 + 0.05 * cl)[..., None]
	metal = metal * (1 - 0.45 * smooth01(hgt * 1.3 - 0.3)[..., None]) + B_LIGHT * 0.45 * smooth01(hgt * 1.3 - 0.3)[..., None]
	low = PATINA if floor is None else floor  # (the medallion's floor: dark bronze, patina only in the cuts by the strands)
	if floor is not None:
		cut = np.clip((0.5 - occl) * 5, 0, 1)[..., None]
		low = floor * (1 - cut) + PATINA * cut
	c = low * (1 - top[..., None]) + metal * top[..., None]
	c *= (0.75 + 0.5 * np.clip(lit, 0, 1))[..., None]
	c *= (0.55 + 0.45 * occl)[..., None]
	save(c, f"bronze_{name}_col.png")


# ---------------------------------------------------------------- the raised knot band (three-strand plait)
W, H = 2048, 512   # 4 band widths across; repeats left-right
x = (np.arange(W) + 0.5) / H          # along, in band widths (0..4)
y = (np.arange(H) + 0.5) / H          # across, 0..1
X, Y = np.meshgrid(x, y)
PER, AMP = 2.0, 0.27  # (one plait twist per 2 band widths; strands swing between the rails)
HW, GAP, SOFT = 0.085, 0.04, 0.03
dists, pri = [], []
for k in range(3):
	ph = 2 * np.pi * X / PER + 2 * np.pi * k / 3
	yk = 0.5 + AMP * np.sin(ph)
	slope = AMP * 2 * np.pi / PER * np.cos(ph)
	dists.append(np.abs(Y - yk) / np.sqrt(1 + slope * slope))
	pri.append(-(yk - 0.5) * slope)  # (a plait: the strand swinging in towards the middle lies on top)
near_ = np.stack(dists) < HW + GAP
over = np.argmax(np.where(near_, np.stack(pri), -1e9), 0)  # (only the strands that meet here decide who's on top)
hgt = weave(dists, over, HW, GAP, SOFT)
rail = smooth01((0.075 - np.minimum(Y, 1 - Y)) / 0.02) * 0.85  # the two edge rails
hgt = np.maximum(hgt, rail)
hgt = wrap_blur(hgt, 2, axes=(1,))
finish(hgt, 26.0, "knot", 10)

# ---------------------------------------------------------------- the medallion (ring woven through four loops)
M = 1024
c_ = (np.arange(M) + 0.5) / M * 2 - 1
MX, MY = np.meshgrid(c_, -c_)   # (y up the picture)
R = np.hypot(MX, MY)
HWm, GAPm, SOFTm = 0.085, 0.035, 0.022  # (round 3b: thicker strands, read from the game camera)
RING = 0.5
LOOPS = [(RING * np.cos(a), RING * np.sin(a)) for a in np.radians([90, 0, 270, 180])]  # (four links threaded on the ring)
LR = 0.25
dists = [np.abs(R - RING)] + [np.abs(np.hypot(MX - cx, MY - cy) - LR) for cx, cy in LOOPS]
# over-and-under: each loop crosses the ring twice; going round the ring it is over, under, over, under...
ang = np.arctan2(MY, MX)
over = np.full(R.shape, -1)
for i, (cx, cy) in enumerate(LOOPS):
	a0 = np.arctan2(cy, cx)
	rel = (ang - a0 + np.pi) % (2 * np.pi) - np.pi  # (which side of the loop's middle line)
	mine = np.hypot(MX - cx, MY - cy) < LR + HWm + GAPm
	over = np.where(mine & (rel > 0), 0, np.where(mine & (rel <= 0), i + 1, over))
hgt = weave(dists, over, HWm, GAPm, SOFTm)
# the rim: a raised rail with a carved line, eight round studs on it
rim = smooth01((R - 0.86) / 0.025) * (1 - 0.25 * smooth01(1 - np.abs(R - 0.93) / 0.012)) * 0.9
for a in np.radians(np.arange(8) * 45 + 22.5):
	sd = np.hypot(MX - 0.93 * np.cos(a), MY - 0.93 * np.sin(a))
	rim = np.maximum(rim, 1.05 * np.sqrt(np.clip(1 - (sd / 0.045) ** 2, 0, 1)) * (R < 1.0))
hgt = np.maximum(hgt, rim * (R < 1.0))
# the middle: a stepped diamond (two steps, dwarf stonework)
dia = np.abs(MX) + np.abs(MY)
hgt = np.maximum(hgt, np.where(dia < 0.15, 0.8, 0) + np.where(dia < 0.09, 0.25, 0))
hgt = np.where(R < 1.0, hgt, 0.0)
hgt = wrap_blur(hgt, 1)
finish(hgt, 22.0, "medal", 14, floor=B_DARK * 0.55)
