# Ore Crate (folder: stations): an open plank crate with iron corner brackets (empty; the ore pile is crate_ore_fill.glb).
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

W, D, H = 0.9, 0.62, 0.5
kit.tbox("wood", (W, D, 0.06), (0, 0, 0.03), variant="dark")
for y in (-D / 2 + 0.03, D / 2 - 0.03):
	for k in range(3):
		kit.plank((W, 0.05, 0.15), (0, y, 0.1 + k * 0.155))
for x in (-W / 2 + 0.03, W / 2 - 0.03):
	for k in range(3):
		kit.plank((0.05, D - 0.1, 0.15), (x, 0, 0.1 + k * 0.155))
kit.plank((W * 1.02, 0.04, 0.09), (0, -D / 2 - 0.01, 0.27), rot=(0, -22, 0), dark=True)
iron = kit.tex_mat("iron")
for x in (-W / 2, W / 2):
	for y in (-D / 2, D / 2):
		kit.box((0.07, 0.07, H), (x, y, H / 2), iron, bevel=0.008, wobble=0.002)
		kit.rivet((x, y - 0.04 if y < 0 else y + 0.04, H - 0.06))

kit.save(out, preview)
