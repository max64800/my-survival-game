# Gem Bench (folder: stations), hand-built from the kit (follows the ChatGPT concept: stone-block top, wooden frame
# with copper bands, stone feet, a big violet gem, hammer and tongs).
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

out, preview = kit.args()
kit.reset()

W, D = 1.25, 0.75          # table width (x) and depth (y)
TOP_Z = 0.86               # top surface height

# Stone feet under each leg.
for x in (-W / 2 + 0.17, W / 2 - 0.17):
	for y in (-D / 2 + 0.15, D / 2 - 0.15):
		kit.stone((0.3, 0.28, 0.22), (x, y, 0.11), dark=True)

# Wooden posts and the frame.
for x in (-W / 2 + 0.17, W / 2 - 0.17):
	for y in (-D / 2 + 0.15, D / 2 - 0.15):
		kit.plank((0.16, 0.16, 0.44), (x, y, 0.44))
kit.plank((W - 0.25, 0.1, 0.12), (0, -D / 2 + 0.15, 0.32))            # front low beam
kit.plank((W - 0.25, 0.1, 0.12), (0, D / 2 - 0.15, 0.32), dark=True)  # back low beam
for x in (-W / 2 + 0.17, W / 2 - 0.17):
	kit.plank((0.1, D - 0.2, 0.1), (x, 0, 0.32), dark=True)          # side beams
	kit.plank((0.2, D - 0.05, 0.14), (x, 0, 0.66))                     # top rails under the slab

# Copper bands with rivets on the front posts.
for x in (-W / 2 + 0.17, W / 2 - 0.17):
	kit.band((0.24, 0.05, 0.11), (x, -D / 2 + 0.06, 0.6), kit.mat("copper", metal=0.7, rough=0.45))

# Top: three big cut stone blocks.
bw = W / 3
for i in range(3):
	kit.stone((bw - 0.015, D, 0.2), (-W / 2 + bw * (i + 0.5), 0, TOP_Z - 0.1), rot_z=0)
kit.box((0.12, 0.08, 0.012), (-0.45, -0.2, TOP_Z + 0.004), kit.mat("moss"), bevel=0.004, wobble=0.004)

# The gem, with two small shards next to it.
violet = kit.mat("gem_violet", rough=0.2, metal=0.1, glow=0.25)
kit.gem((-0.18, 0.08, TOP_Z + 0.11), (0.17, 0.13, 0.13), violet, seed=3)
kit.gem((0.0, -0.05, TOP_Z + 0.03), (0.05, 0.04, 0.035), violet, seed=5)
kit.gem((0.06, 0.02, TOP_Z + 0.025), (0.035, 0.03, 0.025), violet, seed=8)

# Hammer: wooden handle lying on the slab, iron head.
# Handle points along (sin35, -cos35); the head sits across its far end.
kit.cylinder(0.028, 0.4, (0.36, -0.1, TOP_Z + 0.03), kit.tex_mat("wood", "b"), rot=(90, 0, 35))
kit.box((0.2, 0.09, 0.09), (0.245, 0.064, TOP_Z + 0.046), kit.tex_mat("iron"), rot=(0, 0, 35), bevel=0.012, wobble=0.003)

# Tongs: two iron bars, slightly crossed.
iron = kit.tex_mat("iron")
kit.box((0.4, 0.025, 0.02), (-0.35, -0.22, TOP_Z + 0.012), iron, rot=(0, 0, 8), bevel=0.005, wobble=0)
kit.box((0.4, 0.025, 0.02), (-0.35, -0.2, TOP_Z + 0.032), iron, rot=(0, 0, -6), bevel=0.005, wobble=0)

kit.save(out, preview)
