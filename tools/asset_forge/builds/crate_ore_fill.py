# Ore Crate fill (folder: stations): the heap of ore inside the crate. Origin bottom-centre; at scale 1 and y=0.08 it fills the crate.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

ore = [kit.tex_mat("stone", "b"), kit.tex_mat("copper"), kit.tex_mat("iron", "c"), kit.tex_mat("stone", "dark")]
kit.tbox("stone", (0.76, 0.48, 0.2), (0, 0, 0.1), variant="dark", bevel=0.03, wobble=0.01)
import random as _r
rr = _r.Random(5)
for i in range(22):
	x, y = rr.uniform(-0.34, 0.34), rr.uniform(-0.2, 0.2)
	z = 0.2 + 0.12 * (1 - (abs(x) / 0.4) ** 2) * (1 - (abs(y) / 0.25) ** 2) + rr.uniform(-0.02, 0.02)
	kit.gem((x, y, z), (0.08, 0.07, 0.06), ore[i % 4], seed=i + 2)
for (x, y) in ((-0.1, 0.05), (0.18, -0.06)):
	kit.crystal_cluster((x, y, 0.28), 0.45, kit.glow("crystal_blue", 0.35), seed=int(x * 100) + 9, n=4)

kit.save(out, preview)
