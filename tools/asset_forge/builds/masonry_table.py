# Masonry Table (folder: stations): a heavy stone-topped table with a cut block, chisel, mallet and rubble.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

W, D, TOP = 1.3, 0.8, 0.85
for x in (-W / 2 + 0.16, W / 2 - 0.16):
	for y in (-D / 2 + 0.14, D / 2 - 0.14):
		kit.plank((0.17, 0.17, TOP - 0.16), (x, y, (TOP - 0.16) / 2))
kit.plank((W - 0.25, 0.1, 0.1), (0, -D / 2 + 0.14, 0.25), dark=True)
kit.plank((W - 0.25, 0.1, 0.1), (0, D / 2 - 0.14, 0.25), dark=True)
for i in range(2):
	kit.stone((W / 2 - 0.01, D, 0.18), (-W / 4 + i * W / 2, 0, TOP - 0.09))
kit.stone((0.4, 0.32, 0.3), (-0.1, 0.05, TOP + 0.15))
kit.tcyl("wood", 0.025, 0.3, (0.32, -0.12, TOP + 0.03), rot=(0, 90, 20), verts=8, variant="b")
kit.tbox("wood", (0.12, 0.18, 0.12), (0.5, -0.06, TOP + 0.06), rot=(0, 0, 20), variant="dark")
kit.tbox("iron", (0.2, 0.025, 0.025), (0.2, 0.25, TOP + 0.013), rot=(0, 0, -30))
for (x, y, s) in ((0.32, 0.22, 0.07), (0.4, 0.12, 0.05), (-0.45, -0.25, 0.06), (0.25, -0.5, 0.1), (-0.5, -0.5, 0.12)):
	kit.stone((s * 1.3, s * 1.1, s), (x, y, (TOP + s / 2) if abs(y) < D / 2 else s / 2))

kit.save(out, preview)
