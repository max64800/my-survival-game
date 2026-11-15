# Rope Ladder (folder: stations): two twisted ropes tied round a top bar, wooden rungs lashed to the ropes.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

Hh, Wd = 2.0, 0.55
BAR = Hh + 0.08
kit.tcyl("wood", 0.05, Wd + 0.4, (0, 0, BAR), rot=(0, 90, 0), verts=8)
for x in (-Wd / 2, Wd / 2):
	kit.rope((x, 0, 0.02), (x, 0, BAR - 0.05), r=0.028)
	kit.rope_wrap((0, BAR), 0.062, x - 0.04, x + 0.04, 2.5, thick=0.014, axis="x")
for k in range(7):
	z = 0.15 + k * 0.27
	kit.plank((Wd + 0.12, 0.07, 0.05), (0, 0, z))
	for x in (-Wd / 2, Wd / 2):
		kit.rope_wrap((x, 0, 0), 0.042, z - 0.045, z + 0.045, 2.5, thick=0.011)

kit.save(out, preview)
