# Workbench (folder: stations), hand-built from the owner's ChatGPT concept: one thick mossy stone slab
# on twisted root legs with stone feet, a lower plank shelf, an iron vice on the front-right corner,
# a hammer and a little pile of rocks on top.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

out, preview = kit.args()
kit.reset()

W, D = 1.6, 0.85
TOP_Z = 0.92
LX, LY = W / 2 - 0.22, D / 2 - 0.16   # leg positions

# Stone feet.
for x in (-LX, LX):
	for y in (-LY, LY):
		kit.stone((0.34, 0.3, 0.15), (x, y, 0.075), dark=True)

# Twisted root legs: three thick roots per leg, leaning into each other.
for x in (-LX, LX):
	for y in (-LY, LY):
		for k in range(3):
			a = k * 2 * math.pi / 3 + x * 3 + y * 5
			ox, oy = math.cos(a) * 0.05, math.sin(a) * 0.05
			kit.cylinder(0.055, 0.62, (x + ox, y + oy, 0.45), kit.tex_mat("wood"),
				rot=(math.degrees(oy) * 2.2, -math.degrees(ox) * 2.2, k * 40), verts=8, bevel=0.01)

# Frame under the slab, with big iron bolt heads.
kit.plank((W - 0.2, 0.12, 0.16), (0, -LY, TOP_Z - 0.3))
kit.plank((W - 0.2, 0.12, 0.16), (0, LY, TOP_Z - 0.3), dark=True)
for x in (-LX, LX):
	kit.plank((0.14, D - 0.15, 0.16), (x, 0, TOP_Z - 0.3))
	kit.band((0.16, 0.04, 0.12), (x, -LY - 0.07, TOP_Z - 0.3), kit.tex_mat("iron"), rivets=1)

# Lower shelf: four planks across the front-to-back beams.
kit.plank((W - 0.3, 0.08, 0.08), (0, -LY + 0.02, 0.3), dark=True)
kit.plank((W - 0.3, 0.08, 0.08), (0, LY - 0.02, 0.3), dark=True)
for i in range(4):
	x = -0.45 + i * 0.3
	kit.plank((0.27, D - 0.2, 0.05), (x, 0, 0.36), rot=(0, 0, 90 + (i % 2) * 2))

# The slab: one big thick stone with moss in a crack.
kit.stone((W, D, 0.24), (0, 0, TOP_Z - 0.12))
kit.box((0.18, 0.05, 0.02), (-0.45, -D / 2 + 0.04, TOP_Z - 0.06), kit.mat("moss"), bevel=0.005, wobble=0.005, rot=(90, 0, 0))

# Iron vice on the front-right corner: base, two jaws, screw and handle bar.
iron = kit.tex_mat("iron")
vx, vy = W / 2 - 0.2, -D / 2 + 0.06
kit.box((0.26, 0.24, 0.07), (vx, vy + 0.06, TOP_Z + 0.035), iron, bevel=0.01, wobble=0.002)
kit.box((0.24, 0.07, 0.17), (vx, vy + 0.13, TOP_Z + 0.15), iron, bevel=0.012, wobble=0.002)
kit.box((0.24, 0.07, 0.17), (vx, vy - 0.02, TOP_Z + 0.15), iron, bevel=0.012, wobble=0.002)
kit.cylinder(0.025, 0.3, (vx, vy - 0.12, TOP_Z + 0.13), iron, rot=(90, 0, 0), verts=10)
kit.cylinder(0.016, 0.3, (vx, vy - 0.26, TOP_Z + 0.13), iron, rot=(0, 90, 0), verts=8)
for s in (-1, 1):
	kit.rivet((vx + s * 0.15, vy - 0.26, TOP_Z + 0.13), iron, r=0.03)

# Hammer lying on the slab: handle along X, head across its left end.
kit.cylinder(0.03, 0.42, (-0.3, 0.12, TOP_Z + 0.032), kit.tex_mat("wood", "b"), rot=(0, 90, 0))
kit.box((0.11, 0.2, 0.11), (-0.55, 0.12, TOP_Z + 0.055), iron, bevel=0.015, wobble=0.003)

# Little pile of rocks at the back.
for (x, y, s) in ((0.1, 0.22, 0.13), (0.24, 0.24, 0.09), (0.0, 0.25, 0.08), (0.17, 0.12, 0.07)):
	kit.stone((s * 1.3, s * 1.1, s), (x, y, TOP_Z + s / 2))

kit.save(out, preview)
