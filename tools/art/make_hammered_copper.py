# Hammered copper picture for the hand-built copper armour (F914, Claude, Nov 26, 2026).
# The look to match: the GPT armour pictures (big round hammer dents packed like a honeycomb, bright where the metal
# rises between dents, darker in the dents). Owner, Nov 26: "the shoulders, helmet and back need a way better texture".
# Bold, so it reads from the game camera (see the bold-texture rule): ~20 dents across one tile.
#
#   python3 tools/art/make_hammered_copper.py
#
# Writes (tile 2048 px = 0.32 m of armour, repeats seamlessly):
#   assets/textures/armor/copper_hammered_col.png  colour
#   assets/textures/armor/copper_hammered_nrm.png  bumps (normal map, OpenGL / glTF style: green = up)
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "textures" / "armor"
N = 2048          # pixels per side
COLS, ROWS = 20, 24  # dents across / down (rows even: the honeycomb's offset rows join up when it repeats)
rng = np.random.default_rng(914)

# dent centres: a honeycomb, each nudged a little (hand-hammered: no two the same)
dx, dy = N / COLS, N / ROWS
pts = []
for r in range(ROWS):
	for c in range(COLS):
		x = (c + 0.5 * (r % 2)) * dx + rng.uniform(-0.2, 0.2) * dx
		y = (r + 0.5) * dy + rng.uniform(-0.2, 0.2) * dy
		pts.append((x % N, y % N))
pts = np.array(pts)
tree = cKDTree(pts, boxsize=[N, N])
yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
q = np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1)
d, idx = tree.query(q, k=2)
f1, f2 = d[:, 0].reshape(N, N), d[:, 1].reshape(N, N)
cell = idx[:, 0].reshape(N, N)

# height: each dent a shallow bowl, a sharp ridge where two dents meet
edge = (f2 - f1) / dx          # 0 on the ridge, ~0.5 in the middle of a dent
bowl = np.clip(edge / 0.45, 0, 1)
rad = rng.uniform(0.55, 0.68, len(pts))[cell] * dx  # (round dents, not cells with lines: owner hated "cracks")
round_ = np.clip(1 - (f1 / rad) ** 2, 0, 1)
height = -(0.65 * round_ ** 0.8 + 0.35 * bowl ** 1.6)  # (deepest in the middle)
depth = rng.uniform(0.75, 1.25, len(pts))[cell]  # (some dents hit harder)
height *= depth


def wrap_blur(a, r):
	for ax in (0, 1):
		c = np.cumsum(np.concatenate([a.take(range(-r - 1, 0), ax), a, a.take(range(0, r), ax)], ax), ax)
		a = (c.take(range(2 * r + 1, 2 * r + 1 + N), ax) - c.take(range(0, N), ax)) / (2 * r + 1)
	return a


height = wrap_blur(wrap_blur(height, 4), 3)  # (ridges rounded off a little, not knife edges)
# normal map from the slopes (wraps round: seamless)
s = 5.0  # bump strength
gx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * s
gy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * s
nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
nrm = np.stack([-gx * nz, gy * nz, nz], -1)  # (image rows go down; OpenGL green = up the picture)
Image.fromarray(((nrm * 0.5 + 0.5) * 255).clip(0, 255).astype(np.uint8)).save(OUT / "copper_hammered_nrm.png")

# colour: warm copper; ridges bright (they catch the light and get rubbed), dents a bit darker and redder,
# each dent its own shade (medium variety), a slow cloudy patina change across the tile
base = np.array([0.78, 0.40, 0.21])
dark = np.array([0.50, 0.21, 0.10])
light = np.array([1.00, 0.70, 0.47])
ridge = np.clip(1 - edge / 0.2, 0, 1) ** 2
dent = -height / max(1e-6, -height.min())
lit = np.clip(nrm @ np.array([-0.45, 0.55, 0.7]) / np.linalg.norm([-0.45, 0.55, 0.7]), 0, 1)
lit = (lit - lit.mean()) / (lit.std() + 1e-9)  # (each dent lit from the top left, like the picture)
shade = rng.uniform(0.9, 1.08, len(pts))[cell]
cloud = wrap_blur(wrap_blur(wrap_blur(rng.standard_normal((N, N)), 50), 50), 50)
cloud = (cloud - cloud.mean()) / (cloud.std() + 1e-9)
col = base[None, None] * shade[..., None]
col = col * (1 - 0.35 * dent[..., None]) + dark[None, None] * 0.35 * dent[..., None]
col = col * (1 - 0.18 * ridge[..., None]) + light[None, None] * 0.18 * ridge[..., None]
col *= (1 + 0.13 * np.clip(lit, -2.5, 2.5))[..., None]
col *= (1 + 0.05 * cloud)[..., None]
Image.fromarray((col.clip(0, 1) * 255).astype(np.uint8)).save(OUT / "copper_hammered_col.png")
print("saved", OUT / "copper_hammered_col.png", OUT / "copper_hammered_nrm.png")
