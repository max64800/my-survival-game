# Armoury Bench (folder: stations, F894): a sturdy plank bench in the workbench style. On its left end an armour
# stand (a wooden dummy) wears a leather tunic with a belt and shoulder pads; a round shield leans on the front-right
# leg; hammers, leather straps hanging over the edge and a rolled hide on top; folded leather on the lower shelf.
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

out, preview = kit.args()
kit.reset()

W, D = 1.7, 0.8
TOP_Z = 0.82
LX, LY = W / 2 - 0.18, D / 2 - 0.12   # leg positions
iron = kit.tex_mat("iron")

# Stone feet and thick square legs.
for x in (-LX, LX):
	for y in (-LY, LY):
		kit.stone((0.27, 0.25, 0.13), (x, y, 0.065), dark=True)
		kit.plank((0.15, 0.15, 0.64), (x, y, 0.43), dark=(x > 0) == (y > 0))

# Frame under the top (aprons sink 1 cm into the top planks so nothing just touches).
kit.plank((W - 0.2, 0.1, 0.15), (0, -LY, TOP_Z - 0.155))
kit.plank((W - 0.2, 0.1, 0.15), (0, LY, TOP_Z - 0.155), dark=True)
for x in (-LX, LX):
	kit.plank((0.1, D - 0.2, 0.15), (x, 0, TOP_Z - 0.155), dark=True)
	kit.band((0.18, 0.04, 0.12), (x, -LY - 0.075, TOP_Z - 0.155), iron, rivets=2)  # corner straps

# Top: four thick planks with dark gaps between them.
pw = (D - 3 * 0.012) / 4
for i in range(4):
	y = -D / 2 + pw / 2 + i * (pw + 0.012)
	kit.plank((W, pw, 0.09), (0, y, TOP_Z - 0.045), dark=(i == 2))

# Lower shelf with a stack of folded leather on it.
kit.plank((W - 0.3, 0.08, 0.08), (0, -LY + 0.02, 0.26), dark=True)
kit.plank((W - 0.3, 0.08, 0.08), (0, LY - 0.02, 0.26), dark=True)
for i in range(5):
	kit.plank((0.25, D - 0.22, 0.05), (-0.58 + i * 0.29, 0, 0.31), rot=(0, 0, 90 + (i % 2) * 2))
for k, (v, dz, rz) in enumerate((("dark", 0.0, 4), ("a", 0.05, -6), ("b", 0.1, 9))):
	kit.tbox("leather", (0.5 - k * 0.05, 0.36 - k * 0.03, 0.055), (0.18, 0.02, 0.355 + dz), rot=(0, 0, rz), variant=v, bevel=0.018, wobble=0.008)

# --- the armour stand on the left end of the top
SX = -0.5
kit.plank((0.38, 0.32, 0.09), (SX, 0.03, TOP_Z + 0.04), dark=True)                  # heavy base block
kit.cylinder(0.045, 0.32, (SX, 0.03, TOP_Z + 0.22), kit.tex_mat("wood", "b"), verts=8)  # post below the tunic
T0 = TOP_Z + 0.33                                                                    # tunic bottom
kit.taper(0.4, 0.25, 0.5, 0.28, 0.46, (SX, 0.03, T0), kit.tex_mat("leather", "dark"), bevel=0.03)
# Belt with an iron buckle, and a collar.
kit.box((0.425, 0.275, 0.055), (SX, 0.03, T0 + 0.09), kit.tex_mat("leather", "b"), bevel=0.012, wobble=0.004)
kit.box((0.07, 0.03, 0.065), (SX + 0.04, 0.03 - 0.147, T0 + 0.09), iron, bevel=0.008, wobble=0.002)
kit.box((0.2, 0.16, 0.05), (SX, 0.03, T0 + 0.47), kit.tex_mat("leather", "dark"), bevel=0.015, wobble=0.004)
# Shoulder pads (leaning out a little) and short sleeves.
for s in (-1, 1):
	kit.tbox("leather", (0.17, 0.29, 0.06), (SX + s * 0.2, 0.03, T0 + 0.44), rot=(0, s * 22, 0), variant="c", bevel=0.02, wobble=0.006)
	kit.tbox("leather", (0.1, 0.2, 0.16), (SX + s * 0.27, 0.03, T0 + 0.34), rot=(0, s * 10, 0), variant="dark", bevel=0.025, wobble=0.006)
	for z in (0.16, 0.28):   # lacing up the front
		kit.rivet((SX + s * 0.03, 0.03 - 0.133 - z * 0.06, T0 + z), kit.mat("rope", rough=0.9), r=0.014)
# Neck and a chunky wooden head.
kit.cylinder(0.045, 0.12, (SX, 0.03, T0 + 0.53), kit.tex_mat("wood", "b"), verts=8)
kit.box((0.17, 0.15, 0.19), (SX, 0.03, T0 + 0.66), kit.tex_mat("wood", "a"), bevel=0.05, wobble=0.012)

# --- tools and straps on the top
# Big hammer: handle along X, head across its right end. Small riveting hammer beside it.
kit.cylinder(0.028, 0.42, (0.05, 0.15, TOP_Z + 0.024), kit.tex_mat("wood", "b"), rot=(0, 90, 0))
kit.box((0.1, 0.19, 0.1), (0.29, 0.15, TOP_Z + 0.045), iron, bevel=0.015, wobble=0.003)
kit.cylinder(0.02, 0.3, (0.12, -0.05, TOP_Z + 0.017), kit.tex_mat("wood", "c"), rot=(0, 90, 12))
kit.box((0.06, 0.13, 0.06), (-0.03, -0.08, TOP_Z + 0.028), iron, rot=(0, 0, 12), bevel=0.01, wobble=0.002)
# Leather straps lying on the top and hanging down the front edge, each with a little buckle.
for k, x in enumerate((0.1, 0.22, 0.34)):
	lv = ("dark", "dark", "c")[k]
	kit.tbox("leather", (0.05, 0.3, 0.014), (x, -0.25, TOP_Z + 0.002), variant=lv, bevel=0.004, wobble=0.002)
	kit.tbox("leather", (0.05, 0.014, 0.2 + k * 0.05), (x, -D / 2 - 0.002, TOP_Z - 0.09 - k * 0.025), variant=lv, bevel=0.004, wobble=0.002)
	kit.box((0.065, 0.02, 0.04), (x, -D / 2 - 0.008, TOP_Z - 0.17 - k * 0.05), iron, bevel=0.005, wobble=0.001)
# A rolled hide at the back right, tied with rope.
kit.tcyl("leather", 0.075, 0.5, (0.5, 0.25, TOP_Z + 0.07), rot=(0, 90, 4), verts=10, variant="b")
for dx in (-0.15, 0.15):
	kit.ring(0.08, 0.012, (0.5 + dx, 0.25, TOP_Z + 0.07), kit.tex_mat("rope", "a"), rot=(0, 90, 4), seg=14)

# --- a round shield leaning on the front-right leg (tilted 15 degrees back)
A = 15.0
n = (0.0, -math.cos(math.radians(A)), math.sin(math.radians(A)))   # the shield's front
up = (0.0, math.sin(math.radians(A)), math.cos(math.radians(A)))   # "up" across its face
C = (LX, -0.44, 0.31)


def on_face(u, v, f):
	"""A point on the shield: u along x, v along its up, f out of its front."""
	return (C[0] + u, C[1] + v * up[1] + f * n[1], C[2] + v * up[2] + f * n[2])


rot = (90 - A, 0, 0)
kit.cylinder(0.29, 0.04, C, kit.tex_mat("wood", "a"), rot=rot, verts=12, bevel=0.01)
for k in (-1, 1):   # two plank seams painted as darker boards
	kit.box((0.014, 0.5, 0.012), on_face(k * 0.1, 0, 0.021), kit.tex_mat("wood", "dark"), rot=rot, bevel=0.002, wobble=0.002)
kit.ring(0.29, 0.028, C, iron, rot=rot, seg=14)
kit.cylinder(0.085, 0.05, on_face(0, 0, 0.03), iron, rot=rot, verts=10, bevel=0.012)   # the boss
for i in range(8):
	a = i * math.pi / 4 + 0.3
	kit.rivet(on_face(math.cos(a) * 0.235, math.sin(a) * 0.235, 0.022), iron, r=0.016)

kit.save(out, preview)
