# Stone Chest (folder: stations): a crate of thick stone slabs with iron corner bands and a hinged stone lid.
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

# A stone lid (owner, Nov 19): a thick slab with a raised, chisel-edged top, iron bands over it that bend down the
# front, two iron hinge straps on the back and a ring pull. Its own part: it swings open (kit.save lid=).
LZ = Hb - 0.02  # where the lid starts (the walls end just below)
kit.tbox("stone", (W + 0.04, D + 0.04, 0.1), (0, 0, LZ + 0.05), variant="dark", bevel=0.03, wobble=0.008)
kit.tbox("stone", (W - 0.14, D - 0.14, 0.05), (0, 0, LZ + 0.125), bevel=0.02, wobble=0.008)
for x in (-W / 2 + 0.22, W / 2 - 0.22):
	kit.box((0.07, D + 0.07, 0.025), (x, 0, LZ + 0.11), iron, bevel=0.005, wobble=0.002)
	kit.box((0.07, 0.025, 0.12), (x, -D / 2 - 0.035, LZ + 0.05), iron, bevel=0.005, wobble=0.002)
	kit.rivet((x, -D / 2 - 0.05, LZ + 0.02), iron, r=0.016)
	kit.box((0.06, 0.025, 0.1), (x, D / 2 + 0.035, LZ - 0.01), iron, bevel=0.005, wobble=0.002)  # hinge strap
kit.box((0.12, 0.03, 0.06), (0, -D / 2 - 0.03, LZ + 0.05), iron, bevel=0.006, wobble=0.002)
kit.ring(0.05, 0.012, (0, -D / 2 - 0.055, LZ + 0.0), iron, rot=(90, 0, 0), seg=14)

kit.save(out, preview, lid=LZ - 0.003)  # the lid swings open (owner F345)
