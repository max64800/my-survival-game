# Tanning Rack (folder: stations): a log frame with a hide stretched by ropes tied to its legs and edges, on stone feet.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

Wd, Hh = 1.3, 1.5
LOW, HIGH = 0.3, Hh - 0.05
for x in (-Wd / 2, Wd / 2):
	kit.stone((0.22, 0.22, 0.12), (x, 0, 0.06), dark=True)
	kit.tcyl("wood", 0.06, Hh, (x, 0, Hh / 2 + 0.08), verts=10)
	for z in (LOW, HIGH):
		kit.rope_wrap((x, 0, 0), 0.07, z - 0.05, z + 0.05, 3, thick=0.012)
for z in (LOW, HIGH):
	kit.tcyl("wood", 0.05, Wd + 0.2, (0, 0, z), rot=(0, 90, 0), verts=10, variant="dark")
cz = (Hh + 0.3) / 2
kit.hide(0.9, 0.95, (0, 0, cz), kit.tex_mat("leather"), seed=3)
tips = kit.hide_tips(0.9, 0.95, (0, 0, cz), inset=0.035)
frame = [(-Wd / 2 + 0.06, HIGH - 0.02), (Wd / 2 - 0.06, HIGH - 0.02), (Wd / 2 - 0.06, LOW + 0.02), (-Wd / 2 + 0.06, LOW + 0.02)]
for (tx, ty, tz) in tips:
	if abs(tx) < 0.05:
		fx, fz = tx, (HIGH - 0.05 if tz > cz else LOW + 0.05)
	elif abs(tz - cz) < 0.05:
		fx, fz = (Wd / 2 - 0.06 if tx > 0 else -Wd / 2 + 0.06), tz
	else:
		fx, fz = min(frame, key=lambda p: (p[0] - tx) ** 2 + (p[1] - tz) ** 2)
	kit.rope((tx, 0, tz), (fx, 0, fz), r=0.012)
	kit.ring(0.02, 0.008, (tx, 0, tz), kit.tex_mat("rope"), rot=(90, 0, 0), seg=10)

kit.save(out, preview)
