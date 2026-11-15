# Grindstone (folder: stations): a round sharpening stone on an axle in a wooden frame, with a crank and a little water trough.
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

R = 0.32
for y in (-0.16, 0.16):
	for s in (-1, 1):
		kit.plank((0.08, 0.08, 0.6), (s * 0.24, y, 0.3), rot=(0, s * -12, 0))
	kit.plank((0.6, 0.08, 0.08), (0, y, 0.06), dark=True)
	kit.plank((0.12, 0.09, 0.08), (0, y, R + 0.22), dark=True)
kit.tcyl("stone", R, 0.12, (0, 0, R + 0.22), rot=(90, 0, 0), verts=24, variant="b")
kit.ring(0.06, 0.015, (0, -0.065, R + 0.22), iron, rot=(90, 0, 0), seg=12)
kit.tcyl("iron", 0.025, 0.5, (0, 0, R + 0.22), rot=(90, 0, 0), verts=10)
kit.tbox("iron", (0.03, 0.03, 0.18), (0, -0.26, R + 0.14), bevel=0.004)
kit.tcyl("wood", 0.022, 0.14, (0, -0.32, R + 0.06), rot=(90, 0, 0), verts=8, variant="b")
kit.tbox("wood", (0.5, 0.24, 0.12), (0, 0, 0.14), variant="dark", bevel=0.015)
kit.water((0, 0, 0.205), 0.0001, ripples=0)
kit.box((0.44, 0.18, 0.01), (0, 0, 0.2), kit.mat("water", rough=0.05, glow=0.08), bevel=0, wobble=0)

kit.save(out, preview)
