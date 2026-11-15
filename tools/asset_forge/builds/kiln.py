# Kiln (folder: stations): a round fired-clay dome on a ring of bricks, an arched glowing mouth with coals
# (the game plays animated fire at its fire spot), a short clay chimney, and split logs stacked beside it.
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

R, H = 0.58, 0.85
# Brick ring footing.
n = 14
for k in range(n):
	a = 2 * math.pi * k / n
	if abs(math.atan2(math.sin(a + math.pi / 2), math.cos(a + math.pi / 2))) < 0.45:
		continue
	kit.tbox("brick", (2 * R * math.sin(math.pi / n) * 1.1, 0.18, 0.16), (math.cos(a) * R, math.sin(a) * R, 0.08),
		rot=(0, 0, math.degrees(a) + 90), variant="abc"[k % 3], bevel=0.008, wobble=0.003)
# The dome: a squashed half ball of clay.
bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=10, radius=1, location=(0, 0, 0.14))
d = bpy.context.object
for v in d.data.vertices:
	if v.co.z < 0:
		v.co.z = 0
d.scale = (R, R, H)
bpy.ops.object.transform_apply(scale=True)
kit._finish(d, kit.tex_mat("clay", "b"), 0, 0)
kit.roughen(d, 0.008, 1, seed=4)
for p in d.data.polygons:
	p.use_smooth = True
# Clay bands around the dome.
for z, r in ((0.35, R * 0.97), (0.6, R * 0.82)):
	kit.ring(r, 0.025, (0, 0, z), kit.tex_mat("clay", "dark"), seg=24)
# Mouth: dark recess, coals, a brick arch.
my = -R + 0.1
kit.box((0.36, 0.25, 0.3), (0, my, 0.27), kit.mat("charcoal", -0.4), bevel=0.03, wobble=0)
_parts.coals(0, my - 0.06, 0.15, 0.1, n=6)
kit.fire_spot((0, my - 0.06, 0.2), 0.4)
for ang in (-80, -45, 0, 45, 80):
	a = math.radians(ang)
	kit.tbox("brick", (0.13, 0.2, 0.11), (math.sin(a) * 0.24, my - 0.1, 0.3 + math.cos(a) * 0.18), rot=(0, ang, 0), variant="c", bevel=0.008)
kit.tbox("brick", (0.5, 0.22, 0.06), (0, my - 0.12, 0.12), variant="dark", bevel=0.008)
# Chimney.
kit.tcyl("clay", 0.12, 0.3, (0.12, 0.08, H + 0.22), verts=12, variant="c")
kit.ring(0.125, 0.022, (0.12, 0.08, H + 0.36), kit.tex_mat("clay", "dark"), seg=14)
kit.cylinder(0.08, 0.02, (0.12, 0.08, H + 0.375), kit.mat("charcoal"), verts=12, bevel=0)
# Logs waiting to be burned.
_parts.log_pile(R + 0.32, 0.05, n_bottom=2, length=0.5)
kit.save(out, preview)
