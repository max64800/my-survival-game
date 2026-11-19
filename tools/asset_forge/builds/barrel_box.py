# Loot barrel (folder: stations): the building kit's barrel (build_pieces.py barrel(), F61), but open-topped with a
# black circle inside, and its lid as its own part on a back hinge so it can swing open like the chests (owner, Nov 19).
# The building kit's own barrel (barrel__plank_root) stays one solid piece.
#   blender --background --factory-startup --python builds/barrel_box.py -- <out.glb> [preview.png]
import math
import sys
from pathlib import Path

import bmesh

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()


def G(p):  # Godot (x, y up, z toward you) -> Blender
	return (p[0], -p[2], p[1])


TOP = 0.9  # the staves' rim
# Staves: the same bulging barrel, its top cap taken off so you can look in.
o = kit.cylinder(0.33, 0.9, G((0, 0.45, 0)), kit.tex_mat("wood", "b"), verts=16, bevel=0.02)
bm = bmesh.new()
bm.from_mesh(o.data)
for v in bm.verts:
	t = v.co.z / 0.45
	k = 1.0 + 0.1 * (1 - t * t)
	v.co.x *= k
	v.co.y *= k
bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.normal.z > 0.9 and f.calc_center_median().z > 0.4], context="FACES_ONLY")
bm.to_mesh(o.data)
bm.free()
# The inside (owner, Nov 19: "not hollow, just a black circle"): a black disc 2 cm below the rim.
kit.cylinder(0.31, 0.02, G((0, TOP - 0.03, 0)), kit.mat("charcoal", shade=-0.9, rough=1.0), verts=16, bevel=0)
# Copper bands and the tap, as on the kit's barrel.
band = kit.tex_mat("copper", "b")
for y in (0.12, 0.32, 0.58, 0.78):
	t = (y - 0.45) / 0.45
	r = 0.33 * (1.0 + 0.1 * (1 - t * t)) * math.cos(math.pi / 16) + 0.006
	kit.cylinder(r, 0.07, G((0, y, 0)), band, verts=16, bevel=0.004)
	for k in range(4):
		a = 2 * math.pi * k / 4 + 0.4
		kit.rivet(G((math.cos(a) * (r + 0.004), y, math.sin(a) * (r + 0.004))), kit.tex_mat("copper", "dark"), r=0.012)
kit.cylinder(0.025, 0.1, G((0, 0.25, 0.37)), kit.tex_mat("copper", "b"), rot=(90, 0, 0), verts=8, bevel=0.004)
kit.box((0.03, 0.03, 0.06), G((0, 0.22, 0.41)), kit.tex_mat("copper", "b"), bevel=0.004, wobble=0)
# The lid: a plank disc resting just above the rim (1 cm seam), a copper handle, and a hinge strap at the back.
LID = TOP + 0.01
kit.cylinder(0.335, 0.03, G((0, LID + 0.015, 0)), kit.tex_mat("wood", "c"), verts=16, bevel=0.004)
kit.box((0.22, 0.05, 0.04), G((0, LID + 0.05, 0)), kit.tex_mat("copper", "b"), bevel=0.008, wobble=0)
for x in (-0.1, 0.1):
	kit.box((0.04, 0.05, 0.04), G((x, LID + 0.035, 0)), kit.tex_mat("copper", "b"), bevel=0.006, wobble=0)
kit.box((0.06, 0.14, 0.012), G((0, LID + 0.031, -0.26)), kit.tex_mat("copper", "dark"), bevel=0.003, wobble=0)

kit.save(out, preview, lid=TOP + 0.0055)  # the lid swings open on its back edge (owner, Nov 19)
