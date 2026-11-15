# Glow Lamp (folder: stations): a short post on stone feet with a little iron cage holding a glowing green gland.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402

out, preview = kit.args()
kit.reset()
iron = kit.tex_mat("iron")
for (x, y, s) in ((0.12, 0.05, 0.15), (-0.1, 0.08, 0.13), (0.02, -0.12, 0.12)):
	kit.stone((s * 1.3, s * 1.1, s), (x, y, s / 2), dark=True)
kit.tcyl("wood", 0.06, 0.9, (0, 0, 0.45), verts=10)
kit.rope_wrap((0, 0, 0), 0.068, 0.35, 0.5, 4, thick=0.012)
kit.tcyl("iron", 0.11, 0.03, (0, 0, 0.92), verts=10)
for k in range(6):
	a = 2 * math.pi * k / 6
	kit.box((0.014, 0.014, 0.22), (math.cos(a) * 0.09, math.sin(a) * 0.09, 1.04), iron, bevel=0.003, wobble=0)
kit.cone(0.12, 0.03, 0.08, (0, 0, 1.18), iron, verts=10)
kit.ring(0.035, 0.008, (0, 0, 1.24), iron, rot=(90, 0, 0), seg=10)
kit.COLORS["gland"] = (0.4, 0.95, 0.5)
g = kit.gem((0, 0, 1.04), (0.07, 0.07, 0.08), kit.glow("gland", 0.6), seed=6)
kit.soft(g, 2)
kit.save(out, preview)
