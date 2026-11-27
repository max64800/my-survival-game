# Bronze pictures for the hand-built bronze plate armour (F914 bronze, Claude, Nov 27, 2026).
# Owner's picks (Nov 27): same shapes as copper, bronze colour, SMOOTHER (finer, softer hammer marks, a bit more shine),
# MORE ENGRAVINGS, dark green patina edges.
#
#   python3 tools/art/make_bronze_plate.py
#
# Writes into assets/textures/armor/:
#   bronze_smooth_col.png / _nrm.png    the plates' middles (tile 2048 px, repeats seamlessly): ~32 soft dents across,
#                                       half as deep as copper's, warm gold-brown
#   bronze_engrave_col.png / _nrm.png   an engraved strip (2048 x 512, repeats left-right): two edge lines and a chain of
#                                       diamonds, each with a smaller diamond and a dot inside, joined by short bars;
#                                       the grooves hold dark green patina (copper_plate_armor.py lays it as a band just
#                                       inside every big plate's raised edge, and along the collar, brow and forearm bands)
# Normal maps are OpenGL / glTF style (green = up the picture).
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "textures" / "armor"
rng = np.random.default_rng(697)

BRONZE = np.array([0.86, 0.62, 0.32])  # (round 1 at 0.70/0.52/0.28 read olive and dull in the game)
B_DARK = np.array([0.46, 0.30, 0.12])
B_LIGHT = np.array([0.98, 0.80, 0.50])
PATINA = np.array([0.04, 0.10, 0.07])  # (round 1's 0.10/0.24/0.17 grooves were too faint from the game camera)  # (the grooves and deepest dents: dark green, matches the patina edges)


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


def save(a, name):
	Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).save(OUT / name)
	print("saved", OUT / name)


# ---------------------------------------------------------------- smooth hammered bronze (plates' middles)
N = 2048
COLS, ROWS = 32, 36  # (copper: 20 x 24; finer marks)
dx, dy = N / COLS, N / ROWS
pts = []
for r in range(ROWS):
	for c in range(COLS):
		pts.append((((c + 0.5 * (r % 2)) * dx + rng.uniform(-0.22, 0.22) * dx) % N,
			((r + 0.5) * dy + rng.uniform(-0.22, 0.22) * dy) % N))
pts = np.array(pts)
yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
d, idx = cKDTree(pts, boxsize=[N, N]).query(np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1), k=2)
f1, f2 = d[:, 0].reshape(N, N), d[:, 1].reshape(N, N)
cell = idx[:, 0].reshape(N, N)
edge = (f2 - f1) / dx
rad = rng.uniform(0.6, 0.75, len(pts))[cell] * dx
round_ = np.clip(1 - (f1 / rad) ** 2, 0, 1)
height = -(0.9 * round_ ** 1.5 + 0.1 * np.clip(edge / 0.45, 0, 1) ** 1.6) * rng.uniform(0.7, 1.1, len(pts))[cell]
height = wrap_blur(wrap_blur(height, 6), 4)  # (softer ridges than copper: planished, not freshly hammered)
nrm = normals(height, 2.6)  # (copper 5.0: half as deep)
save(nrm * 0.5 + 0.5, "bronze_smooth_nrm.png")
dent = -height / max(1e-6, -height.min())
ridge = np.clip(1 - edge / 0.2, 0, 1) ** 2
lit = np.clip(nrm @ (np.array([-0.45, 0.55, 0.7]) / np.linalg.norm([-0.45, 0.55, 0.7])), 0, 1)
lit = (lit - lit.mean()) / (lit.std() + 1e-9)
cloud = wrap_blur(wrap_blur(wrap_blur(rng.standard_normal((N, N)), 50), 50), 50)
cloud = (cloud - cloud.mean()) / (cloud.std() + 1e-9)
col = BRONZE[None, None] * rng.uniform(0.94, 1.05, len(pts))[cell][..., None]
col = col * (1 - 0.25 * dent[..., None]) + B_DARK * 0.25 * dent[..., None]
col = col * (1 - 0.06 * ridge[..., None]) + B_LIGHT * 0.06 * ridge[..., None]  # (faint: copper's bright
# ridges read as cell lines when the dents are this small)
col *= (1 + 0.08 * np.clip(lit, -2.5, 2.5))[..., None]
col *= (1 + 0.06 * cloud)[..., None]
save(col, "bronze_smooth_col.png")

# ---------------------------------------------------------------- the engraved strip
W, H = 2048, 512   # 4 square units across; the strip repeats left-right
UNIT = H
SS = 2  # (drawn twice as big, then shrunk: smooth groove edges)
groove = Image.new("L", (W * SS, H * SS), 0)
g = ImageDraw.Draw(groove)
LW = int(0.075 * UNIT * SS)  # groove width (~1.6 mm on a 2.2 cm band; round 1's 1 mm vanished at game distance)


def P(x, y):
	return (x * UNIT * SS, y * UNIT * SS)


for y in (0.1, 0.9):  # the two edge lines, all the way along
	g.line([P(-0.1, y), P(W / UNIT + 0.1, y)], fill=255, width=LW)
for k in range(-1, W // UNIT + 1):
	cx = k + 0.5
	for s, w in ((0.36, LW), (0.17, LW)):  # a diamond, and a smaller one inside it
		g.line([P(cx, 0.5 - s * 0.95), P(cx + s * 1.15, 0.5), P(cx, 0.5 + s * 0.95), P(cx - s * 1.15, 0.5),
			P(cx, 0.5 - s * 0.95)], fill=255, width=w, joint="curve")
	r = 0.045
	g.ellipse([P(cx - r, 0.5 - r), P(cx + r, 0.5 + r)], fill=255)  # a punched dot in the middle
	g.line([P(cx + 0.36 * 1.15, 0.5), P(cx + 1 - 0.36 * 1.15, 0.5)], fill=255, width=LW)  # the bar to the next one
	for sy in (-1, 1):  # little dots between the diamonds, above and below the bar
		g.ellipse([P(cx + 0.5 - r * 0.8, 0.5 + sy * 0.26 - r * 0.8), P(cx + 0.5 + r * 0.8, 0.5 + sy * 0.26 + r * 0.8)], fill=255)
groove = groove.filter(ImageFilter.GaussianBlur(SS * 1.5)).resize((W, H), Image.LANCZOS)
gm = np.asarray(groove).astype(np.float64) / 255.0
gm = np.clip(gm * 1.15, 0, 1)
# the strip's middle: polished smooth bronze, no dents (an engraver files the band smooth first), soft cloudy colour
cl = cloud[:H, :W]
base = B_LIGHT[None, None] * (0.95 + 0.05 * cl)[..., None]  # (brighter than the plate: polished, so the grooves stand out)
eh = -2.2 * gm  # (grooves cut deep: they must read from the game camera)
near = np.clip(wrap_blur(gm, 6, axes=(1,)) * 2.0 - gm, 0, 1)  # (a thin bright lip beside each groove: rubbed metal)
ec = base * (1 - gm[..., None]) + PATINA * gm[..., None]
ec = ec * (1 - 0.18 * near[..., None]) + B_LIGHT * 0.18 * near[..., None]
save(ec, "bronze_engrave_col.png")
en = normals(wrap_blur(eh, 2), 3.2)
save(en * 0.5 + 0.5, "bronze_engrave_nrm.png")
