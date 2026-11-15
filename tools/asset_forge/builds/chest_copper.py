# Copper-bound Chest (folder: stations): a strongbox clad in copper corners and studs, with a raised hipped lid, copper ridge and boss, ring handles and a big hasp.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402
import _parts  # noqa: E402,F401

out, preview = kit.args()
kit.reset()

W, D, Hb = 0.95, 0.62, 0.5
cu, cud = kit.tex_mat("copper"), kit.tex_mat("copper", "dark")
kit.tbox("wood", (W + 0.03, D + 0.03, 0.06), (0, 0, 0.03), variant="dark", bevel=0.015)
kit.tbox("wood", (W, D, Hb - 0.06), (0, 0, 0.06 + (Hb - 0.06) / 2), variant="dark", bevel=0.02)
kit.tbox("copper", (W + 0.06, D + 0.06, 0.04), (0, 0, Hb + 0.02), bevel=0.012)
# Hipped lid: a sloped wooden top with a copper ridge strip and a central boss.
kit.taper(W + 0.02, D + 0.02, W - 0.3, D - 0.34, 0.14, (0, 0, Hb + 0.04), kit.tex_mat("wood", "c"), bevel=0.015)
kit.tbox("copper", (W - 0.26, 0.06, 0.03), (0, 0, Hb + 0.19), bevel=0.01)
kit.cylinder(0.06, 0.04, (0, 0, Hb + 0.205), cud, verts=12, bevel=0.01)
kit.rivet((0, 0, Hb + 0.235), r=0.025)
for s in (-1, 1):
	kit.tbox("copper", (0.05, D * 0.62, 0.02), (s * (W / 2 - 0.08), 0, Hb + 0.1), rot=(0, s * 40, 0), bevel=0.006)
for x in (-W / 2, W / 2):
	for y in (-D / 2, D / 2):
		kit.box((0.14, 0.14, Hb - 0.04), (x * 0.965, y * 0.955, 0.06 + (Hb - 0.06) / 2), cu, bevel=0.01, wobble=0.002)
		for z in (0.14, 0.3, 0.44):
			kit.rivet((x * 1.015, y + (-0.035 if y < 0 else 0.035), z), r=0.015)
kit.box((W - 0.2, 0.03, 0.05), (0, -D / 2 - 0.01, 0.16), cud, bevel=0.008, wobble=0.002)
kit.box((0.22, 0.04, 0.24), (0, -D / 2 - 0.02, Hb - 0.04), cu, bevel=0.015, wobble=0.002)
kit.ring(0.045, 0.012, (0, -D / 2 - 0.05, Hb - 0.12), cud, rot=(90, 0, 0), seg=14)
kit.box((0.03, 0.02, 0.06), (0, -D / 2 - 0.045, Hb - 0.0), kit.mat("charcoal"), bevel=0.004, wobble=0)
for x in (-W / 2 - 0.03, W / 2 + 0.03):
	kit.ring(0.07, 0.015, (x, 0, Hb - 0.14), cud, rot=(90, 0, 90), seg=16)
	kit.box((0.02, 0.12, 0.06), (x * 0.99, 0, Hb - 0.08), cu, bevel=0.005, wobble=0)

kit.save(out, preview)
