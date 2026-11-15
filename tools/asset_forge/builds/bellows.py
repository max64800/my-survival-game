# Bellows (folder: stations): leather forge bellows between two wooden boards, iron nozzle and handles, on a small stand.
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

kit.plank((0.7, 0.3, 0.08), (0, 0, 0.18), dark=True)
for x in (-0.25, 0.25):
	kit.plank((0.08, 0.26, 0.16), (x, 0, 0.07), dark=True)
kit.taper(0.5, 0.36, 0.22, 0.28, 0.02, (0.02, 0, 0.22), kit.tex_mat("wood", "b"), bevel=0.008).scale = (1, 1, 1)
body = kit.gem((0.0, 0, 0.32), (0.25, 0.17, 0.08), kit.tex_mat("leather"), seed=9)
kit.soft(body, 1)
top = kit.taper(0.5, 0.36, 0.22, 0.28, 0.02, (0.04, 0, 0.4), kit.tex_mat("wood", "c"), bevel=0.008)
for k in range(9):
	a = 2 * math.pi * k / 9
	kit.rivet((0.02 + math.cos(a) * 0.2, math.sin(a) * 0.15, 0.405), iron, r=0.012)
kit.cone(0.05, 0.02, 0.22, (-0.33, 0, 0.3), iron, rot=(0, -90, 0), verts=10)
kit.tcyl("wood", 0.03, 0.18, (0.36, 0, 0.42), rot=(0, 90, 0), verts=8, variant="dark")
kit.tcyl("wood", 0.03, 0.18, (0.36, 0, 0.23), rot=(0, 90, 0), verts=8, variant="dark")

kit.save(out, preview)
