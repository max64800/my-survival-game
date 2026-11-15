# Chopping Block (folder: stations): a thick banded stump with an axe buried in its top, wood chips around.
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

kit.tcyl("wood", 0.33, 0.46, (0, 0, 0.23), verts=16, variant="dark")
kit.cylinder(0.31, 0.012, (0, 0, 0.462), kit.tex_mat("wood", "c"), verts=16, bevel=0)
for k in range(3):
	kit.ring(0.06 + k * 0.08, 0.004, (0, 0, 0.47), kit.tex_mat("wood", "b"), seg=20)
for z in (0.1, 0.36):
	kit.ring(0.335, 0.02, (0, 0, z), iron, seg=24)
# The axe: blade sunk into the top, handle sticking up at an angle.
kit.box((0.05, 0.2, 0.14), (0.04, 0, 0.47), iron, bevel=0.008, wobble=0.002, rot=(0, -20, 0))
kit.tcyl("wood", 0.022, 0.6, (0.17, 0, 0.72), rot=(0, 30, 0), verts=8, variant="b")
for (x, y, a) in ((0.42, -0.1, 20), (-0.38, 0.2, 70), (0.2, 0.4, 130), (-0.3, -0.33, 40)):
	kit.tbox("wood", (0.09, 0.04, 0.015), (x, y, 0.008), rot=(0, 0, a), variant="c", bevel=0.003, wobble=0.002)

kit.save(out, preview)
