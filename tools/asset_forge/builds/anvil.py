# Anvil (folder: stations): a forged iron anvil (stepped feet, tapered waist, heel, hardy hole, a horn that grows out of the face) on a banded stump standing on the ground.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

iron = kit.tex_mat("iron")
# Stump: a wide foot ring on the ground, the trunk, two iron hoops.
kit.tcyl("wood", 0.34, 0.06, (0, 0, 0.03), verts=16, variant="dark")
kit.tcyl("wood", 0.3, 0.4, (0, 0, 0.26), verts=16, variant="dark")
kit.ring(0.305, 0.022, (0, 0, 0.14), iron)
kit.ring(0.305, 0.022, (0, 0, 0.38), iron)
# Body: stepped feet, tapered waist, flare under the face.
kit.taper(0.46, 0.3, 0.34, 0.22, 0.06, (0, 0, 0.46), iron)
kit.taper(0.34, 0.22, 0.2, 0.15, 0.16, (0, 0, 0.52), iron)
kit.taper(0.2, 0.15, 0.3, 0.2, 0.06, (0, 0, 0.68), iron)
# The face, with a heel at the back.
kit.tbox("iron", (0.52, 0.22, 0.12), (-0.05, 0, 0.8), bevel=0.018)
kit.tbox("iron", (0.1, 0.17, 0.085), (-0.35, 0, 0.815), bevel=0.012)
kit.box((0.04, 0.04, 0.012), (-0.22, 0, 0.862), kit.mat("charcoal"), bevel=0.003, wobble=0)
kit.box((0.025, 0.025, 0.012), (-0.14, 0, 0.862), kit.mat("charcoal"), bevel=0.003, wobble=0)
# Horn: starts INSIDE the face with the face's own width/height (oval), narrows and dips to a point.
verts, faces = [], []
rings, sides = 10, 12
for i in range(rings):
	t = i / (rings - 1)
	ry = 0.11 * (1 - t) ** 1.2 + 0.006
	rz = 0.06 * (1 - t) ** 1.1 + 0.006
	cx, cz = 0.13 + t * 0.4, 0.8 - 0.03 * t * t + 0.0 * t
	for k in range(sides):
		a = 2 * math.pi * k / sides
		verts.append((cx, math.cos(a) * ry, cz + math.sin(a) * rz))
for i in range(rings - 1):
	for k in range(sides):
		a, b = i * sides + k, i * sides + (k + 1) % sides
		faces.append((a, b, b + sides, a + sides))
faces.append(tuple(range(sides)))
faces.append(tuple(reversed(range((rings - 1) * sides, rings * sides))))
kit._mesh_obj("horn", verts, faces, iron, smooth=True)
# Two iron staples holding the anvil to the stump.
for x in (-0.16, 0.16):
	kit.tbox("iron", (0.04, 0.34, 0.03), (x, 0, 0.475))
	for y in (-0.17, 0.17):
		kit.tbox("iron", (0.04, 0.03, 0.12), (x, y, 0.42))

kit.save(out, preview)
