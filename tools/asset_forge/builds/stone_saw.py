# Stone Saw (folder: stations): two wooden A-frames holding a big round iron saw blade on an axle, with a crank.
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

R = 0.42
for x in (-0.18, 0.18):
	for s in (-1, 1):
		kit.plank((0.08, 0.08, 0.75), (x, s * 0.22, 0.36), rot=(s * 18, 0, 0))
	kit.plank((0.08, 0.6, 0.08), (x, 0, 0.06), dark=True)
kit.tcyl("iron", 0.03, 0.5, (0, 0, R + 0.18), rot=(0, 90, 0), verts=10)
kit.tcyl("iron", R, 0.02, (0, 0, R + 0.18), rot=(0, 90, 0), verts=32)
kit.tcyl("iron", 0.08, 0.05, (0, 0, R + 0.18), rot=(0, 90, 0), verts=12, variant="dark")
for k in range(24):
	a = 2 * math.pi * k / 24
	kit.cone(0.02, 0.0, 0.04, (0, math.cos(a) * (R + 0.012), R + 0.18 + math.sin(a) * (R + 0.012)), iron,
		rot=(-math.degrees(a) + 90, 0, 0), verts=3, bevel=0)
kit.tbox("iron", (0.04, 0.03, 0.22), (0.27, 0, R + 0.08), bevel=0.004)
kit.tcyl("wood", 0.02, 0.14, (0.32, 0, R - 0.03), rot=(0, 90, 0), verts=8, variant="b")
kit.tbox("stone", (0.3, 0.5, 0.12), (0, -0.05, 0.06), variant="b", bevel=0.02, wobble=0.01)

kit.save(out, preview)
