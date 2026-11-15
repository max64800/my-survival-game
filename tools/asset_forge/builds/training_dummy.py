# Training Dummy (folder: stations): stacked stones on a post bound by rope bands that hug the stones, log arms with lashed stone fists, a stone head with an iron cap and a target board.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

for (x, y, s) in ((0.15, 0.1, 0.15), (-0.13, 0.08, 0.13), (0.03, -0.15, 0.12)):
	kit.stone((s * 1.3, s * 1.1, s), (x, y, s / 2), dark=True)
kit.tcyl("wood", 0.07, 1.0, (0, 0, 0.5), verts=10)
kit.rope_wrap((0, 0, 0), 0.075, 0.7, 0.8, 3, thick=0.013)
kit.stone((0.42, 0.34, 0.3), (0, 0, 0.95))
kit.stone((0.5, 0.36, 0.28), (0, 0, 1.22))


def band(w, d, z, t=0.018):
	# A rope band hugging a w x d block at height z (four straight ropes just outside its sides).
	hw, hd = w / 2 + t, d / 2 + t
	for (a, b) in (((-hw, -hd), (hw, -hd)), ((hw, -hd), (hw, hd)), ((hw, hd), (-hw, hd)), ((-hw, hd), (-hw, -hd))):
		kit.rope((a[0], a[1], z), (b[0], b[1], z), r=t)


band(0.42, 0.34, 0.88)
band(0.42, 0.34, 1.02)
band(0.5, 0.36, 1.3)
kit.tcyl("wood", 0.06, 1.15, (0, 0, 1.24), rot=(0, 90, 0), verts=10, variant="dark")
for x in (-0.6, 0.6):
	kit.stone((0.16, 0.16, 0.16), (x, 0, 1.24))
	kit.rope_wrap((0, 1.24), 0.068, x * 0.82 - 0.05, x * 0.82 + 0.05, 3, thick=0.011, axis="x")
kit.gem((0, 0, 1.52), (0.16, 0.15, 0.15), kit.tex_mat("stone", "c"), seed=5)
kit.cone(0.17, 0.1, 0.08, (0, 0, 1.63), kit.tex_mat("iron"), verts=12)
kit.tbox("wood", (0.4, 0.05, 0.36), (0, -0.2, 1.1), variant="c")
for r, c in ((0.16, "target_red"), (0.11, "linen"), (0.055, "target_red")):
	kit.cylinder(r, 0.01, (0, -0.23 - (0.16 - r) * 0.05, 1.1), kit.mat(c), rot=(90, 0, 0), verts=18, bevel=0)

kit.save(out, preview)
