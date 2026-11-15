# Chisel Rack (folder: stations): a stone mason's bench of cut stone with a wooden block holding a row of chisels and a mallet.
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

kit.stone((1.0, 0.55, 0.32), (0, 0, 0.16), dark=True)
kit.stone((1.05, 0.6, 0.14), (0, 0, 0.39))
kit.tbox("wood", (0.6, 0.16, 0.12), (0, 0.06, 0.52), variant="dark")
for k in range(5):
	x = -0.22 + k * 0.11
	kit.tcyl("wood", 0.025, 0.16, (x, 0.06, 0.65), verts=8, variant="b")
	kit.ring(0.027, 0.006, (x, 0.06, 0.58), iron, seg=10)
	kit.taper(0.02, 0.012, 0.04, 0.006, 0.08, (x, 0.06, 0.5), iron, bevel=0.002)
kit.tbox("wood", (0.12, 0.18, 0.12), (0.38, -0.12, 0.52), rot=(0, 0, 25), variant="c")
kit.tcyl("wood", 0.02, 0.24, (0.27, -0.2, 0.48), rot=(0, 90, 25), verts=8, variant="b")
for (x, y, s) in ((-0.38, -0.18, 0.06), (-0.3, -0.12, 0.04), (0.5, 0.35, 0.08)):
	kit.stone((s * 1.3, s * 1.1, s), (x, y, 0.46 + s / 2 if abs(y) < 0.3 else s / 2))

kit.save(out, preview)
