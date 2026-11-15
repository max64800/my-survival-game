# Bed (folder: stations): a plank bed with rounded posts and one plain, slightly lumpy straw-and-linen mattress.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

L, W = 1.9, 0.95
iron = kit.tex_mat("iron")
for x, h in ((-L / 2, 0.88), (L / 2, 0.62)):
	for y in (-W / 2, W / 2):
		kit.tcyl("wood", 0.07, h, (x, y, h / 2), verts=10)
		kit.gem((x, y, h + 0.02), (0.075, 0.075, 0.05), kit.tex_mat("wood", "c"), seed=3)
		kit.ring(0.072, 0.015, (x, y, 0.12), iron, seg=12)
	kit.plank((0.06, W, 0.12), (x, 0, h - 0.12))
	kit.plank((0.05, W - 0.1, 0.22), (x, 0, h - 0.33), dark=True)
for y in (-W / 2, W / 2):
	kit.plank((L, 0.07, 0.14), (0, y, 0.3))
kit.plank((L - 0.1, W - 0.1, 0.04), (0, 0, 0.3), dark=True)
# One old, lumpy, dirty sackcloth mattress lying ON the boards (bottom at 0.32): sagging in the middle,
# bulging at the sides, uneven stuffing, a corner flattened.
import random
import bmesh
import bpy
rr = random.Random(11)
ML, MW, MH = L - 0.22, W - 0.16, 0.15
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.32 + MH / 2))
mt = bpy.context.object
mt.scale = (ML, MW, MH)
bpy.ops.object.transform_apply(scale=True)
bm = bmesh.new()
bm.from_mesh(mt.data)
bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=7, use_grid_fill=True)
lumps = [(rr.uniform(-ML / 2, ML / 2), rr.uniform(-MW / 2, MW / 2), rr.uniform(0.01, 0.03)) for _ in range(9)]
for v in bm.verts:
	x, y, z = v.co
	fx, fy = abs(x) / (ML / 2), abs(y) / (MW / 2)
	top = (z - 0.32) / MH
	# Round the edges like a stuffed sack.
	v.co.z -= 0.035 * (max(fx, fy) ** 6) * (top - 0.5) * 2
	# Sag in the middle (where someone sleeps) and lumps of stuffing on top.
	if top > 0.5:
		v.co.z -= 0.04 * (1 - fx ** 2) * (1 - fy ** 2) * top
		for (lx, ly, h) in lumps:
			d2 = ((x - lx) / 0.25) ** 2 + ((y - ly) / 0.2) ** 2
			v.co.z += h * math.exp(-d2) * top
	# Bulge out at the sides, and one squashed corner.
	side = 1 - abs(top - 0.5) * 2
	v.co.x += (0.02 if x > 0 else -0.02) * side * fx
	v.co.y += (0.02 if y > 0 else -0.02) * side * fy
	if x > ML / 2 - 0.25 and y < -MW / 2 + 0.2 and top > 0.5:
		v.co.z -= 0.03
	v.co.z -= 0.012  # sink a little into the boards so the rounded bottom never floats
bm.to_mesh(mt.data)
bm.free()
kit._finish(mt, kit.tex_mat("sack", "b"), 0, 0)
kit.soft(mt, 1)

kit.save(out, preview)
