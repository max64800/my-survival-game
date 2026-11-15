# Glow Marker (folder: stations): a stake with spiral and cross rope lashing and an iron claw holding a glowing crystal cluster.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

for (x, y, s) in ((0.12, 0.05, 0.16), (-0.1, 0.08, 0.13), (0.02, -0.12, 0.12)):
	kit.stone((s * 1.3, s * 1.1, s), (x, y, s / 2), dark=True)
kit.tcyl("wood", 0.07, 1.0, (0, 0, 0.55), verts=10)
kit.rope_wrap((0, 0, 0), 0.08, 0.4, 0.66, 5, thick=0.014)
for a in (40, -40):
	kit.rope((-0.07, -0.06, 0.42), (0.07, -0.06, 0.64), r=0.012).rotation_euler.rotate_axis("Z", math.radians(a))
kit.ring(0.08, 0.02, (0, 0, 0.38), kit.tex_mat("iron"), seg=14)
kit.ring(0.08, 0.02, (0, 0, 0.68), kit.tex_mat("iron"), seg=14)
iron = kit.tex_mat("iron")
kit.cone(0.1, 0.07, 0.06, (0, 0, 1.08), iron, verts=10)
for k in range(4):
	a = math.radians(45 + k * 90)
	kit.cone(0.018, 0.006, 0.2, (math.cos(a) * 0.07, math.sin(a) * 0.07, 1.18), iron,
		rot=(-math.sin(a) * 20, math.cos(a) * 20, 0), verts=6)
kit.crystal_cluster((0, 0, 1.1), 0.75, kit.glow("glow_cyan", 0.6), seed=6, n=5)

kit.save(out, preview)
