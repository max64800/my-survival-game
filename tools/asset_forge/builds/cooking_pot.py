# Cooking Pot (folder: stations): an iron pot hanging on a linked chain from a lashed log frame over a fire.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

_parts.fire_pit(0, 0, r=0.36, stones=8, logs=True, flames=0.6)
TOP = 1.12
for x in (-0.55, 0.55):
	kit.tcyl("wood", 0.05, TOP + 0.05, (x, 0, (TOP + 0.05) / 2), verts=8)
kit.tcyl("wood", 0.045, 1.35, (0, 0, TOP), rot=(0, 90, 0), verts=8)
for x in (-0.55, 0.55):
	kit.rope_wrap((x, 0, 0), 0.058, TOP - 0.08, TOP - 0.03, 3, thick=0.012)
	kit.rope_wrap((0, TOP), 0.052, x - 0.09 if x < 0 else x + 0.04, x - 0.04 if x < 0 else x + 0.09, 3, thick=0.012, axis="x")
_parts.chain((0, 0, TOP - 0.05), (0, 0, 0.92), link=0.06)
iron = kit.tex_mat("iron")
kit.tcyl("iron", 0.26, 0.3, (0, 0, 0.56), verts=16)
kit.ring(0.26, 0.03, (0, 0, 0.71), iron)
bail = kit.ring(0.21, 0.012, (0, 0, 0.71), iron, rot=(90, 0, 0), seg=16)
bail.scale = (1, 1, 1.0)
kit.cylinder(0.235, 0.02, (0, 0, 0.705), kit.mat("ember", -0.35, glow=0.15), verts=16, bevel=0)
for k in range(4):
	a = k * 1.6
	kit.gem((math.cos(a) * 0.1, math.sin(a) * 0.1, 0.72), (0.04, 0.035, 0.02), kit.mat("mushroom_red", -0.2), seed=k)

kit.save(out, preview)
