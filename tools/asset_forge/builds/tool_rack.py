# Tool Rack (folder: stations): a standing plank board on feet with pegs holding a hammer, a saw and tongs.
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

W, H = 1.1, 1.2
for x in (-W / 2 + 0.06, W / 2 - 0.06):
	kit.plank((0.09, 0.09, H), (x, 0.05, H / 2))
	kit.plank((0.12, 0.4, 0.07), (x, 0.05, 0.035), dark=True)
for k in range(5):
	kit.plank((W - 0.12, 0.04, 0.18), (0, 0.08, 0.3 + k * 0.18), dark=(k % 2 == 1))
kit.plank((W, 0.1, 0.08), (0, 0.06, H - 0.02))
for x in (-0.35, -0.05, 0.25):
	kit.tcyl("wood", 0.015, 0.1, (x, 0.01, 0.95), rot=(90, 0, 0), verts=6, variant="c")
# Hammer hanging head-down.
kit.tcyl("wood", 0.018, 0.4, (-0.35, -0.02, 0.73), verts=8, variant="b")
kit.tbox("iron", (0.16, 0.06, 0.07), (-0.35, -0.02, 0.52))
# Saw: a toothed iron blade with a wooden handle.
kit.taper(0.12, 0.012, 0.06, 0.012, 0.5, (-0.05, -0.02, 0.42), iron, bevel=0.002)
for k in range(10):
	kit.cone(0.012, 0.0, 0.025, (-0.05 - 0.062 + 0.002 * k, -0.02, 0.43 + k * 0.045), iron, rot=(0, -90, 0), verts=3, bevel=0)
kit.tbox("wood", (0.1, 0.04, 0.12), (-0.05, -0.02, 0.96), variant="c")
# Tongs: two crossed bars.
for a in (-6, 6):
	kit.box((0.025, 0.02, 0.45), (0.25, -0.02, 0.72), iron, bevel=0.004, wobble=0, rot=(0, a, 0))
kit.ring(0.03, 0.008, (0.25, -0.02, 0.86), iron, rot=(90, 0, 0), seg=10)

kit.save(out, preview)
