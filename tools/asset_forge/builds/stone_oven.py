# Stone Oven (folder: stations; kitchen level 3, owner Nov 20): a squat stacked-stone base, a clay-plastered barrel
# vault on top, a round stone-ringed mouth with glowing coals (the game plays animated fire at its fire spot),
# a stone ledge in front of the mouth, a short stone chimney at the back and a wooden bread paddle leaning on its side.
# Built different from the kiln (that one is a round clay dome). Mouth faces -Y like the kiln.
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402

out, preview = kit.args()
kit.reset()

W, D = 1.12, 0.96   # base footprint
BASE_H = 0.46       # stone base height
# --- Base: 3 courses of chunky stones, each course shifted so the joints don't line up.
course_h = BASE_H / 3
for row in range(3):
	z = course_h * (row + 0.5)
	n = 3 if row % 2 == 0 else 4
	for side, (length, depth, axis_y, fixed) in enumerate((
			(W, 0.2, False, -D / 2 + 0.1), (W, 0.2, False, D / 2 - 0.1),
			(D - 0.4, 0.2, True, -W / 2 + 0.1), (D - 0.4, 0.2, True, W / 2 - 0.1))):
		k = n if side < 2 else max(2, n - 1)
		seg = length / k
		for i in range(k):
			c = -length / 2 + seg * (i + 0.5)
			loc = (fixed, c, z) if axis_y else (c, fixed, z)
			size = (depth, seg - 0.012, course_h - 0.012) if axis_y else (seg - 0.012, depth, course_h - 0.012)
			kit.stone(size, loc, dark=(row + i + side) % 4 == 0)
# A hearth slab closes the top of the base (the vault sits on it), and a flat stone fills the hollow middle.
kit.tbox("greystone", (W - 0.06, D - 0.06, 0.08), (0, 0, BASE_H + 0.03), variant="b", bevel=0.02, wobble=0.006)
kit.tbox("stone", (W - 0.42, D - 0.42, BASE_H - 0.05), (0, 0, BASE_H / 2 - 0.02), variant="dark", bevel=0.01, wobble=0.003)

# --- The vault: a lying clay barrel along Y, its lower half sunk into the stone base (only the top half shows).
VR, VL = 0.5, D - 0.2
vz = BASE_H + 0.1
bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=VR, depth=VL, location=(0, 0, vz), rotation=(math.radians(90), 0, 0))
v = bpy.context.object
kit._finish(v, kit.tex_mat("clay", "b"), 0.02, 0)
kit.roughen(v, 0.01, 1, seed=7)
for p in v.data.polygons:
	p.use_smooth = True
# Clay ribs across the vault (two hoops, standing a little proud of it).
for y in (-VL * 0.18, VL * 0.22):
	kit.ring(VR + 0.015, 0.03, (0, y, vz), kit.tex_mat("clay", "dark"), rot=(90, 0, 0), seg=26)

# --- The front face: a round stone face (half sunk like the vault) with a round mouth (rule 5).
fy = -VL / 2 - 0.04
kit.tcyl("greystone", VR + 0.05, 0.1, (0, fy, vz), rot=(90, 0, 0), verts=24, variant="a", bevel=0.02)
MR = 0.19  # mouth radius
mz = vz + 0.02 + MR
kit.cylinder(MR, 0.06, (0, fy - 0.035, mz), kit.mat("charcoal", -0.45), rot=(90, 0, 0), verts=20, bevel=0)  # dark inside
_parts.coals(0, fy - 0.1, vz + 0.04, 0.09, n=5, seed=9)
kit.fire_spot((0, fy - 0.1, vz + 0.1), 0.35)
# Ring of wedge stones round the mouth (the bottom one is the ledge).
for k in range(9):
	a = math.radians(-90 + 180 * k / 8)  # from the left side over the top to the right side
	x, z = math.sin(a) * (MR + 0.07), mz + math.cos(a) * (MR + 0.07)
	kit.tbox("warmstone", (0.1, 0.1, 0.1), (x, fy - 0.07, z), rot=(0, -90 + 180 * k / 8, 0), variant="abc"[k % 3], bevel=0.015, wobble=0.004)
for side in (-1, 1):  # the two stones the arch stands on
	kit.tbox("warmstone", (0.1, 0.1, 0.17), (side * (MR + 0.07), fy - 0.07, mz - 0.1), variant="b", bevel=0.015, wobble=0.004)
# Ledge: a thick stone slab sticking out under the mouth.
kit.tbox("greystone", (0.62, 0.26, 0.07), (0, fy - 0.13, vz - 0.01), variant="c", bevel=0.02, wobble=0.005)

# --- Chimney at the back top: three stacked stones, a slate cap.
cy = VL / 2 - 0.16
top = vz + VR - 0.02
for i, s in enumerate((0.26, 0.23, 0.21)):
	kit.tbox("greystone", (s, s, 0.13), (0.0, cy, top - 0.04 + i * 0.125), rot=(0, 0, (i - 1) * 6), variant="abc"[i], bevel=0.02, wobble=0.006)
kit.tbox("slate", (0.3, 0.3, 0.04), (0.0, cy, top + 0.33), variant="dark", bevel=0.012, wobble=0.004)
kit.cylinder(0.06, 0.02, (0.0, cy, top + 0.30), kit.mat("charcoal", -0.4), verts=10, bevel=0)

# --- A wooden bread paddle leaning on the right side, its blade resting on the floor.
px = W / 2 + 0.06
blade = kit.tbox("wood", (0.04, 0.26, 0.34), (px + 0.02, -0.12, 0.2), rot=(0, -12, 0), variant="b", bevel=0.012, wobble=0.003)
kit.tcyl("wood", 0.025, 0.7, (px - 0.035, -0.12, 0.7), rot=(0, -12, 0), verts=8, variant="dark")

kit.save(out, preview)
