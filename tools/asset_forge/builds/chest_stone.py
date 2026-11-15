# Stone Chest (folder: stations): an open stone crate of thick slabs with iron corner bands (no lid).
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

W, D, Hb = 1.0, 0.7, 0.5
kit.stone((W, D, 0.1), (0, 0, 0.05), dark=True)
for y in (-D / 2 + 0.06, D / 2 - 0.06):
	kit.stone((W, 0.12, Hb - 0.08), (0, y, 0.05 + (Hb - 0.08) / 2))
for x in (-W / 2 + 0.06, W / 2 - 0.06):
	kit.stone((0.12, D - 0.2, Hb - 0.08), (x, 0, 0.05 + (Hb - 0.08) / 2))
kit.stone((W - 0.2, D - 0.22, 0.04), (0, 0, 0.11), dark=True)
iron = kit.tex_mat("iron")
for x in (-W / 2, W / 2):
	for y in (-D / 2, D / 2):
		kit.box((0.07, 0.07, Hb - 0.05), (x * 0.99, y * 0.98, Hb / 2), iron, bevel=0.006, wobble=0.001)
		kit.rivet((x * 0.99, y + (-0.04 if y < 0 else 0.04), Hb - 0.12), iron, r=0.02)

kit.save(out, preview)
