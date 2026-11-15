# Carpenter's Vise (folder: stations): a heavy plank bench with a big iron screw vise on its front edge.
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

W, D, TOP = 1.3, 0.7, 0.85
for x in (-W / 2 + 0.12, W / 2 - 0.12):
	for y in (-D / 2 + 0.1, D / 2 - 0.1):
		kit.plank((0.13, 0.13, TOP - 0.1), (x, y, (TOP - 0.1) / 2))
	kit.plank((0.1, D - 0.15, 0.1), (x, 0, 0.22), dark=True)
kit.plank((W - 0.2, 0.08, 0.1), (0, 0, 0.22), dark=True)
for k in range(4):
	kit.plank((W, D / 4 - 0.01, 0.1), (0, -D / 2 + D / 8 + k * D / 4, TOP - 0.05))
vx = W / 2 - 0.25
vy = -D / 2 - 0.02
kit.tbox("iron", (0.3, 0.1, 0.2), (vx, vy + 0.06, TOP + 0.04))
kit.tbox("iron", (0.3, 0.07, 0.24), (vx, vy - 0.1, TOP + 0.02))
kit.tcyl("iron", 0.03, 0.34, (vx, vy - 0.05, TOP - 0.06), rot=(90, 0, 0), verts=10)
kit.tcyl("iron", 0.018, 0.36, (vx, vy - 0.22, TOP - 0.06), rot=(0, 90, 0), verts=8)
for s in (-1, 1):
	kit.rivet((vx + s * 0.18, vy - 0.22, TOP - 0.06), iron, r=0.032)
for x in (-0.3, 0.0):
	kit.plank((0.25, 0.06, 0.04), (x, 0.1, TOP + 0.02), dark=True)

kit.save(out, preview)
