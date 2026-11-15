# Farm Plot (folder: stations): a low square bed of dark soil framed with stones, with cave mushrooms.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

S = 1.3
kit.tbox("soil", (S - 0.2, S - 0.2, 0.16), (0, 0, 0.08), bevel=0.02, wobble=0.01)
n = 5
for side in range(4):
	for k in range(n):
		t = -S / 2 + S * (k + 0.5) / n
		if side == 0:
			x, y = t, -S / 2 + 0.1
		elif side == 1:
			x, y = t, S / 2 - 0.1
		elif side == 2:
			x, y = -S / 2 + 0.1, t
		else:
			x, y = S / 2 - 0.1, t
		kit.stone((0.24, 0.22, 0.2), (x, y, 0.1), rot_z=0 if side < 2 else 90)
kit.mushroom((-0.2, 0.12, 0.16), 1.2, seed=1)
kit.mushroom((0.2, -0.15, 0.16), 0.9, seed=2)
kit.mushroom((0.28, 0.25, 0.16), 0.7, seed=3)
kit.mushroom((-0.3, -0.25, 0.16), 0.55, cap="crystal_amber", seed=4)
kit.mushroom((0.02, 0.3, 0.16), 0.45, seed=5)

kit.save(out, preview)
