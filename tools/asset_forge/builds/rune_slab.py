# Rune Slab (folder: stations): a tall standing stone on a stepped plinth with a carved border, a glowing rune circle, side glyph columns and a capstone.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

kit.stone((1.2, 0.6, 0.12), (0, 0, 0.06), dark=True)
kit.stone((1.0, 0.48, 0.1), (0, 0, 0.17), dark=True)
kit.stone((0.85, 0.32, 1.3), (0, 0, 0.87))
kit.stone((0.7, 0.36, 0.14), (0, 0.01, 1.57))
kit.stone((0.4, 0.26, 0.12), (0, 0.02, 1.69))
g = kit.glow("glow_cyan", 0.8)
carve = kit.mat("charcoal", 0.3)
y = -0.168


def groove(size, loc, rot=0, glow=True):
	kit.box((size[0] + 0.025, 0.012, size[1] + 0.025), (loc[0], y + 0.006, loc[1]), carve, bevel=0.004, wobble=0, rot=(0, rot, 0))
	if glow:
		kit.box((size[0], 0.016, size[1]), (loc[0], y, loc[1]), g, bevel=0.004, wobble=0, rot=(0, rot, 0))


# Carved (dark, not glowing) border around the face.
groove((0.7, 0.02), (0, 1.47), glow=False)
groove((0.7, 0.02), (0, 0.3), glow=False)
groove((0.02, 1.17), (-0.35, 0.885), glow=False)
groove((0.02, 1.17), (0.35, 0.885), glow=False)
# The rune circle with a double ring.
kit.ring(0.22, 0.014, (0, y, 0.92), g, rot=(90, 0, 0), seg=32)
kit.ring(0.22, 0.024, (0, y + 0.008, 0.92), carve, rot=(90, 0, 0), seg=32)
kit.ring(0.15, 0.008, (0, y, 0.92), g, rot=(90, 0, 0), seg=28)
groove((0.032, 0.62), (0, 0.92))
for s in (-1, 1):
	groove((0.028, 0.2), (s * 0.075, 1.06), rot=s * 40)
	groove((0.028, 0.18), (s * 0.075, 0.79), rot=-s * 40)
	groove((0.028, 0.1), (s * 0.12, 0.92), rot=90)
	# Side glyph columns: little marks stacked down each side.
	for k in range(6):
		z = 0.45 + k * 0.17
		groove((0.05, 0.02), (s * 0.28, z), rot=(k % 3 - 1) * 30)
		if k % 2:
			groove((0.02, 0.05), (s * 0.28, z + 0.05))
groove((0.14, 0.025), (0, 1.3))
for k in range(8):
	a = 2 * math.pi * k / 8
	groove((0.022, 0.022), (math.cos(a) * 0.27, 0.92 + math.sin(a) * 0.27), rot=45)
for (x, yy, s) in ((0.55, -0.25, 0.13), (-0.55, -0.2, 0.11)):
	kit.stone((s * 1.3, s * 1.1, s), (x, yy, s / 2), dark=True)

kit.save(out, preview)
