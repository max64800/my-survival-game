# Ore Crate fill (folder: stations): the heap of ore inside the crate. Origin bottom-centre; at scale 1 and y=0.08 it fills the crate.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

ore = [kit.tex_mat("stone", "b"), kit.tex_mat("copper"), kit.tex_mat("iron", "c"), kit.tex_mat("stone", "dark")]
kit.tbox("stone", (0.76, 0.48, 0.2), (0, 0, 0.1), variant="dark", bevel=0.03, wobble=0.01)
# The heap itself (F42: the lumps and gems used to hang above a flat slab).
import bpy  # noqa: E402
bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1, location=(0, 0, 0.19))
heap = bpy.context.object
for v in heap.data.vertices:
	v.co.z = max(v.co.z, 0)
heap.scale = (0.37, 0.23, 0.13)
bpy.ops.object.transform_apply(scale=True)
kit._finish(heap, kit.tex_mat("stone", "dark"), 0, 0)
kit.roughen(heap, 0.012, 1, seed=3)


def surface(x, y):
	"""Height of the heap's top at (x, y)."""
	q = 1 - (x / 0.37) ** 2 - (y / 0.23) ** 2
	return 0.19 + 0.13 * max(q, 0) ** 0.5


import random as _r
rr = _r.Random(5)
for i in range(22):
	x, y = rr.uniform(-0.3, 0.3), rr.uniform(-0.17, 0.17)
	kit.gem((x, y, surface(x, y) - 0.015), (0.08, 0.07, 0.06), ore[i % 4], seed=i + 2)
for (x, y) in ((-0.1, 0.05), (0.18, -0.06)):
	kit.crystal_cluster((x, y, surface(x, y) - 0.03), 0.45, kit.glow("crystal_blue", 0.35), seed=int(x * 100) + 9, n=4)

kit.save(out, preview)
