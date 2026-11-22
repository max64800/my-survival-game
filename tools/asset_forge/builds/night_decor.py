# Decor remade from the night pictures decor_* (furniture per building style, lights, storage, mine props,
# wall trophies, fungal garden, creative beams). One object per picture cell.
#   blender --background --factory-startup --python builds/night_decor.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (shelves, plaques, banners, torches) have a flat back at +Y so they sit flush on a wall.
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, cband, disc, ember_bed, kit, log, mesh, mesh_cloth, plank, rivet, rng, stone, stream, water_disc  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402

WOOD = lambda: T("wood")  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
GREEN = lambda: T("greenpaint")  # noqa: E731


def legs4(w, d, h, r=0.05, m=None, inset=0.06, logs=True):
	for x in (-w / 2 + inset, w / 2 - inset):
		for y in (-d / 2 + inset, d / 2 - inset):
			if logs:
				log((x, y, 0), (x + J(0.01), y, h), r, m or T("bark"), seg=7, rings=2, bend=0.05)
			else:
				B((r * 2, r * 2, h), (x, y, h / 2), m or WOOD(), bevel=0.015)


def plank_top(w, d, z, t=0.06, n=4, m=None, along="x"):
	for i in range(n):
		if along == "x":
			plank((w, d / n - 0.008, t), (0, -d / 2 + d / n * (i + 0.5), z))
		else:
			plank((w / n - 0.008, d, t), (-w / 2 + w / n * (i + 0.5), 0, z))


def rope_tie(c, r, axis="z"):
	rot = {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
	for k in (-1, 0, 1):
		p = list(c)
		p[{"x": 0, "y": 1, "z": 2}[axis]] += k * 0.03
		kit.ring(r + 0.008, 0.013, tuple(p), kit.tex_mat("rope"), rot=rot, seg=12)


def blanket(w, d, z, cols=((0.55, 0.15, 0.12), (0.2, 0.3, 0.55), (0.75, 0.6, 0.35))):
	n = len(cols) * 2
	for i in range(n):
		B((w / n + 0.003, d, 0.05), (-w / 2 + w / n * (i + 0.5), 0, z), kit.tex_mat("cloth", "a") if False else C(cols[i % len(cols)], 0.9), bevel=0.012)


def cushion(loc, size, rgb=(0.8, 0.72, 0.55)):
	o = B(size, loc, C(rgb, 0.95), bevel=min(size) * 0.4)
	return o


def stone_blocks(w, d, h, z0=0.0, cy=0.0):
	"""A rough block of stacked stones (stone furniture), centred at y = cy."""
	B((w - 0.06, d - 0.06, h - 0.02), (0, cy, z0 + h / 2), kit.mat("charcoal", 0.4), bevel=0)
	rows = max(1, round(h / 0.2))
	for r in range(rows):
		z = z0 + h / rows * (r + 0.5)
		for (x, y, sx, sy) in ((0, -d / 2 + 0.05, w, 0.1), (0, d / 2 - 0.05, w, 0.1), (-w / 2 + 0.05, 0, 0.1, d - 0.1), (w / 2 - 0.05, 0, 0.1, d - 0.1)):
			k = max(1, round(max(sx, sy) / 0.3))
			for i in range(k):
				if sx > sy:
					stone((sx / k - 0.01, sy, h / rows - 0.01), (x - sx / 2 + sx / k * (i + 0.5), y + cy, z), bevel=0.018)
				else:
					stone((sx, sy / k - 0.01, h / rows - 0.01), (x, y + cy - sy / 2 + sy / k * (i + 0.5), z), bevel=0.018)


def rug_mesh(w, d, rgb_a, rgb_b, round_=False):
	if round_:
		for k, r in enumerate((w / 2, w / 2 * 0.75, w / 2 * 0.5, w / 2 * 0.25)):
			disc(r, 0.0, 0.012 + k * 0.002, (0, 0), C(rgb_a if k % 2 == 0 else rgb_b, 0.95), seg=26, wob=0.02)
		for k in range(24):
			a = 2 * math.pi * k / 24
			kit.ring(0.02, 0.006, (math.cos(a) * w / 2, math.sin(a) * w / 2, 0.006), kit.tex_mat("rope"), seg=8)
		return
	B((w, d, 0.014), (0, 0, 0.007), C(rgb_a, 0.95), bevel=0.004)
	B((w * 0.8, d * 0.7, 0.004), (0, 0, 0.016), C(rgb_b, 0.95), bevel=0.001)
	for k in range(4):
		B((w * 0.12, d * 0.12, 0.004), (0, -d * 0.25 + k * d * 0.17, 0.02), C(rgb_a, 0.9), bevel=0, rot=(0, 0, 45))
	for s_ in (-1, 1):
		for k in range(10):
			B((0.012, 0.06, 0.006), (-w / 2 + 0.05 + k * (w - 0.1) / 9, s_ * (d / 2 + 0.025), 0.004), kit.tex_mat("rope"), bevel=0)


# ================= Delver's Shack furniture =================
def shack_bed():
	W, D = 1.0, 1.9
	legs4(W, D, 0.5, r=0.06)
	for x in (-W / 2 + 0.06, W / 2 - 0.06):
		log((x, -D / 2, 0.3), (x, D / 2, 0.3), 0.055, T("bark"), seg=7, rings=3)
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		log((-W / 2, y, 0.3), (W / 2, y, 0.3), 0.05, T("bark"), seg=7, rings=2)
		rope_tie((-W / 2 + 0.06, y, 0.3), 0.06)
		rope_tie((W / 2 - 0.06, y, 0.3), 0.06)
	B((W - 0.14, D - 0.14, 0.12), (0, 0, 0.38), kit.tex_mat("sack", "a"), bevel=0.04)
	blanket(W - 0.12, D * 0.55, 0.46)
	cushion((0, D / 2 - 0.25, 0.48), (0.5, 0.28, 0.1))


def shack_table():
	W, D, H = 1.3, 0.75, 0.75
	for x in (-W / 2 + 0.15, W / 2 - 0.15):
		log((x, -D / 2 + 0.1, 0), (x * 0.9, 0.0, H - 0.08), 0.05, T("bark"), seg=7, rings=2)
		log((x, D / 2 - 0.1, 0), (x * 0.9, 0.0, H - 0.08), 0.05, T("bark"), seg=7, rings=2)
		rope_tie((x * 0.9, 0, H - 0.1), 0.06)
	log((-W / 2 + 0.15, 0, 0.3), (W / 2 - 0.15, 0, 0.3), 0.04, T("bark"), seg=7, rings=2)
	log((-W / 2 + 0.1, 0, H - 0.1), (W / 2 - 0.1, 0, H - 0.1), 0.05, T("bark"), seg=7, rings=2)
	plank_top(W, D, H - 0.03, n=4)
	for x in (-W / 2 + 0.1, W / 2 - 0.1):
		for y in (-0.25, 0.25):
			rivet((x, y, H), IRON())


def shack_stool():
	log((0, 0, 0.36), (0, 0, 0.44), 0.18, T("bark"), seg=10, rings=1, end_m=kit.tex_mat("wood", "c"))
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.37), (math.cos(a) * 0.16, math.sin(a) * 0.16, 0.0), 0.04, T("bark"), seg=6, rings=2)
	kit.ring(0.12, 0.014, (0, 0, 0.2), kit.tex_mat("rope"), seg=14)


def shack_bench():
	W = 1.3
	for x in (-W / 2 + 0.12, W / 2 - 0.12):
		for y in (-0.12, 0.12):
			log((x, y, 0), (x, y * 0.5, 0.4), 0.045, T("bark"), seg=6, rings=2)
		rope_tie((x, 0, 0.38), 0.05)
	plank_top(W, 0.32, 0.42, n=2)


def shack_shelf():
	"""A plank shelf hung on two ropes from a wall batten, with jars and a pot on it."""
	W = 0.9
	B((W + 0.1, 0.06, 0.08), (0, 0.03, 0.62), WOOD(), bevel=0.01)
	plank((W, 0.26, 0.05), (0, -0.1, 0.12))
	for x in (-W / 2 - 0.02, W / 2 + 0.02):
		log((x, 0.02, 0.6), (x, -0.12, 0.12), 0.012, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
		kit.ring(0.03, 0.01, (x, -0.12, 0.13), kit.tex_mat("rope"), rot=(0, 90, 0), seg=8)
	for (x, r, h, m) in ((-0.28, 0.06, 0.16, kit.tex_mat("clay", "b")), (-0.1, 0.045, 0.2, kit.tex_mat("clay", "c")), (0.15, 0.07, 0.12, kit.tex_mat("clay", "a"))):
		kit.cylinder(r, h, (x, -0.1, 0.145 + h / 2), m, verts=10, bevel=0.01)
		kit.cylinder(r * 0.6, 0.03, (x, -0.1, 0.145 + h + 0.015), C((0.85, 0.75, 0.55), 0.9), verts=8, bevel=0.004)


def shack_nightstand():
	B((0.4, 0.38, 0.45), (0, 0, 0.225), WOOD(), bevel=0.015)
	for d in (45, -45):
		B((0.5, 0.02, 0.05), (0, -0.2, 0.225), T("wood", "dark"), bevel=0.004, rot=(0, d, 0))
	kit.ring(0.04, 0.008, (0, -0.205, 0.3), IRON(), rot=(90, 0, 0), seg=10)
	kit.cylinder(0.05, 0.02, (0.05, 0.02, 0.46), CU(), verts=10, bevel=0.003)
	kit.cylinder(0.03, 0.1, (0.05, 0.02, 0.52), C((0.95, 0.9, 0.75), 0.8), verts=8, bevel=0.004)
	kit.fire_spot((0.05, 0.02, 0.58), 0.12)


def shack_peg_rack():
	B((0.9, 0.06, 0.14), (0, 0.03, 0.9), WOOD(), bevel=0.015)
	for x in (-0.3, 0.0, 0.3):
		log((x, 0.0, 0.9), (x, -0.14, 0.94), 0.022, T("wood", "c"), seg=6, rings=1)
		rivet((x + 0.06, -0.003, 0.9), IRON())
	mesh_cloth((0.0, -0.13), 0.94, 0.3, 0.75, m=C((0.55, 0.45, 0.2), 0.95))
	B((0.05, 0.05, 0.9), (0, 0.03, 0.45), T("wood", "dark"), bevel=0.01)
	B((0.3, 0.2, 0.04), (0, 0.0, 0.02), T("wood", "dark"), bevel=0.01)


def shack_rug():
	rug_mesh(1.4, 0.9, (0.7, 0.5, 0.25), (0.6, 0.25, 0.15))


# ================= Stonehold furniture =================
def stone_bed():
	W, D = 1.1, 2.0
	stone_blocks(W, D, 0.35)
	stone_blocks(W, 0.24, 0.55, 0.35, cy=D / 2 - 0.12)
	stone((0.24, 0.18, 0.2), (0, D / 2 - 0.12, 0.98), tone=T("limestone", "c"))
	B((W - 0.16, D - 0.3, 0.12), (0, -0.1, 0.41), kit.tex_mat("cloth", "b"), bevel=0.04)
	B((W - 0.12, D * 0.5, 0.05), (0, -D * 0.2, 0.49), C((0.55, 0.2, 0.15), 0.9), bevel=0.015)
	cushion((0, D / 2 - 0.4, 0.5), (0.55, 0.3, 0.1), (0.85, 0.8, 0.7))
	for x in (-W / 2, W / 2):
		cband((0.02, 0.1, 0.35), (x, -D / 2 + 0.1, 0.18), rivets=1, axis="z", m=CU())


def stone_table():
	stone_blocks(0.3, 0.6, 0.6)
	B((0.3, 0.6, 0.6), (0, 0, 0.3), kit.mat("charcoal", 0.4), bevel=0)
	for x in (-0.55, 0.55):
		stone((0.3, 0.6, 0.6), (x, 0, 0.3))
	for i in range(3):
		stone((0.5, 0.8, 0.12), (-0.5 + i * 0.5, 0, 0.66), tone=T("stone", "c"), bevel=0.02)
	for x in (-0.55, 0.55):
		cband((0.32, 0.62, 0.05), (x, 0, 0.55), rivets=2, m=CU())


def stone_stool():
	for x in (-0.13, 0.13):
		for y in (-0.13, 0.13):
			stone((0.12, 0.12, 0.3), (x, y, 0.15))
	stone((0.4, 0.4, 0.08), (0, 0, 0.33), tone=T("stone", "c"))
	cushion((0, 0, 0.42), (0.38, 0.38, 0.1), (0.45, 0.25, 0.15))
	for x in (-0.13, 0.13):
		cband((0.13, 0.13, 0.04), (x, -0.13, 0.08), rivets=1, m=CU())


def stone_throne():
	stone_blocks(0.7, 0.6, 0.45)
	B((0.6, 0.5, 0.06), (0, -0.02, 0.48), kit.tex_mat("leather", "a"), bevel=0.02)
	for x in (-0.3, 0.3):
		stone((0.12, 0.5, 0.25), (x, 0, 0.58))
	B((0.6, 0.12, 0.8), (0, 0.24, 0.85), T("wood", "dark"), bevel=0.02)
	for x in (-0.33, 0.33):
		stone((0.14, 0.16, 1.0), (x, 0.24, 0.95))
	stone((0.24, 0.12, 0.2), (0, 0.24, 1.35), tone=T("limestone", "c"))
	for z in (0.65, 1.0):
		cband((0.62, 0.02, 0.05), (0, 0.17, z), rivets=2, m=CU())


def stone_wall_shelf():
	stone_blocks(0.9, 0.18, 0.9)
	stone((0.95, 0.3, 0.08), (0, -0.1, 0.42), tone=T("stone", "c"))
	for x in (-0.3, 0.3):
		B((0.06, 0.18, 0.12), (x, -0.13, 0.33), CU(), bevel=0.008)
	for x in (-0.22, 0.0, 0.22):
		kit.cylinder(0.05, 0.12, (x, -0.12, 0.52), IRON(), verts=10, bevel=0.006)
		kit.ring(0.03, 0.01, (x + 0.06, -0.12, 0.53), IRON(), rot=(90, 0, 0), seg=8)


def stone_weapon_plaque():
	stone_blocks(0.8, 0.15, 1.0)
	kit.cylinder(0.4, 0.15, (0, 0.0, 1.0), T("stone"), rot=(90, 0, 0), verts=14, bevel=0.02)
	B((0.6, 0.06, 0.9), (0, -0.09, 0.6), T("wood", "dark"), bevel=0.02)
	for a in (35, -35):
		B((0.04, 0.03, 0.75), (0, -0.13, 0.62), T("wood", "b"), bevel=0.006, rot=(0, a, 0))
		x = math.sin(math.radians(a)) * 0.32
		B((0.18, 0.025, 0.14), (x, -0.13, 0.62 + math.cos(math.radians(a)) * 0.3), IRON(), bevel=0.008, rot=(0, a, 0))
	kit.cylinder(0.2, 0.04, (0, -0.15, 0.48), T("wood", "b"), rot=(90, 0, 0), verts=16, bevel=0.01)
	kit.ring(0.2, 0.02, (0, -0.15, 0.48), CU(), rot=(90, 0, 0), seg=18)
	kit.gem((0, -0.18, 0.48), (0.06, 0.03, 0.06), CU(), seed=2)


def stone_chest():
	stone_blocks(0.9, 0.6, 0.45)
	B((0.88, 0.58, 0.18), (0, 0, 0.54), T("wood", "dark"), bevel=0.07)
	for x in (-0.3, 0.3):
		B((0.07, 0.6, 0.19), (x, 0, 0.545), CU(), bevel=0.06)
	B((0.16, 0.04, 0.2), (0, -0.31, 0.42), CU(), bevel=0.01)
	B((0.03, 0.01, 0.06), (0, -0.335, 0.4), kit.mat("charcoal"), bevel=0)


def stone_rug():
	rug_mesh(1.4, 0.95, (0.2, 0.22, 0.3), (0.55, 0.2, 0.15))


# ================= Hearthbrick furniture =================
def brick_box(w, d, h, z0=0.0, cap=True):
	B((w - 0.04, d - 0.04, h), (0, 0, z0 + h / 2), C((0.85, 0.8, 0.7), 0.95), bevel=0)
	rows = max(1, round(h / 0.125))
	for r in range(rows):
		z = z0 + h / rows * (r + 0.5)
		for (y, along) in ((-d / 2, "x"), (d / 2, "x")):
			n = max(1, round(w / 0.25))
			for i in range(n):
				x = -w / 2 + w / n * (i + 0.5) + (0.06 if r % 2 else 0)
				if abs(x) < w / 2 - 0.05:
					B((w / n - 0.016, 0.06, h / rows - 0.016), (x, y + (0.02 if y < 0 else -0.02), z), T("brick"), bevel=0)
		for x in (-w / 2, w / 2):
			B((0.08, d, h / rows - 0.016), (x + (0.03 if x < 0 else -0.03), 0, z), T("brick") if r % 2 else T("limestone"), bevel=0.004)
	if cap:
		B((w + 0.04, d + 0.04, 0.06), (0, 0, z0 + h + 0.03), T("limestone"), bevel=0.012)


def hearth_bed():
	W, D = 1.2, 2.0
	brick_box(W, D, 0.35)
	B((W - 0.16, D - 0.2, 0.12), (0, 0, 0.44), kit.tex_mat("cloth", "b"), bevel=0.04)
	blanket(W - 0.12, D * 0.55, 0.52, cols=((0.25, 0.4, 0.2), (0.8, 0.6, 0.3), (0.6, 0.2, 0.15)))
	cushion((0, D / 2 - 0.35, 0.54), (0.55, 0.3, 0.1), (0.9, 0.85, 0.7))
	# arched brick alcove at the head with green curtains
	for x in (-W / 2, W / 2):
		B((0.16, 0.2, 1.4), (x, D / 2 - 0.1, 0.7), T("brick"), bevel=0.01)
	for i in range(9):
		a = math.pi * (i + 0.5) / 9
		B((0.16, 0.2, 0.12), (-math.cos(a) * W / 2, D / 2 - 0.1, 1.4 + math.sin(a) * 0.3), T("brick"), bevel=0, rot=(0, math.degrees(a - math.pi / 2), 0))
	for x in (-W / 2 + 0.12, W / 2 - 0.12):
		B((0.14, 0.04, 1.0), (x, D / 2 - 0.22, 1.0), C((0.25, 0.42, 0.22), 0.95), bevel=0.02)
	B((W - 0.1, 0.03, 0.03), (0, D / 2 - 0.22, 1.5), CU(), bevel=0.004)


def hearth_table():
	brick_box(0.5, 0.5, 0.55, cap=False)
	kit.cylinder(0.5, 0.06, (0, 0, 0.58), GREEN(), verts=20, bevel=0.012)
	kit.ring(0.5, 0.02, (0, 0, 0.58), CU(), seg=24)
	kit.cylinder(0.08, 0.12, (0.1, 0.05, 0.67), kit.tex_mat("clay", "a"), verts=10, bevel=0.01)
	for k in range(5):
		a = k * 1.25
		kit.gem((0.1 + math.cos(a) * 0.05, 0.05 + math.sin(a) * 0.05, 0.735), (0.03, 0.03, 0.015), C((0.95, 0.92, 0.7), 0.7), seed=k)
	kit.cylinder(0.03, 0.12, (-0.2, -0.1, 0.67), C((0.95, 0.9, 0.75), 0.8), verts=8, bevel=0.004)
	kit.fire_spot((-0.2, -0.1, 0.74), 0.1)


def hearth_chair():
	legs4(0.48, 0.48, 0.45, r=0.035, m=GREEN(), logs=False)
	B((0.5, 0.5, 0.05), (0, 0, 0.47), GREEN(), bevel=0.012)
	cushion((0, 0, 0.52), (0.44, 0.44, 0.06), (0.6, 0.25, 0.18))
	for x in (-0.21, 0.21):
		B((0.06, 0.06, 0.55), (x, 0.21, 0.75), GREEN(), bevel=0.01)
	o = kit.cylinder(0.24, 0.05, (0, 0.21, 1.0), GREEN(), rot=(90, 0, 0), verts=16, bevel=0.01)
	B((0.42, 0.05, 0.25), (0, 0.21, 0.88), GREEN(), bevel=0.01)
	cband((0.44, 0.02, 0.04), (0, 0.18, 0.78), rivets=2, m=CU())


def hearth_fireplace():
	W = 1.4
	for x in (-W / 2 + 0.2, W / 2 - 0.2):
		brick_box(0.4, 0.5, 1.0, cap=False)
		bpy.context.object.location.x += 0
	for i, x in enumerate((-W / 2 + 0.2, W / 2 - 0.2)):
		for r in range(8):
			B((0.4, 0.5, 0.11), (x, 0, 0.0625 + r * 0.125), T("brick") if r % 2 else T("limestone"), bevel=0.004)
	B((W, 0.5, 0.25), (0, 0, 1.12), T("brick"), bevel=0.01)
	for i in range(9):
		a = math.pi * (i + 0.5) / 9
		B((0.14, 0.52, 0.12), (-math.cos(a) * 0.36, 0, 0.62 + math.sin(a) * 0.36), T("limestone"), bevel=0.004, rot=(0, math.degrees(a - math.pi / 2), 0))
	B((W + 0.1, 0.6, 0.08), (0, -0.02, 1.28), T("limestone", "c"), bevel=0.015)
	B((0.6, 0.45, 0.6), (0, 0.04, 0.3), kit.mat("charcoal", -0.2), bevel=0)
	ember_bed(0, -0.05, 0.0, 0.18, n=8)
	kit.fire_spot((0, -0.05, 0.08), 0.5)
	kit.cylinder(0.04, 0.2, (0.45, -0.1, 1.42), C((0.95, 0.9, 0.75), 0.8), verts=8, bevel=0.004)
	for k in range(3):
		B((0.06, 0.18, 0.2), (-0.5 + k * 0.08, 0.0, 1.42), C([(0.5, 0.2, 0.15), (0.2, 0.35, 0.5), (0.3, 0.45, 0.2)][k], 0.9), bevel=0.006)


def hearth_dresser():
	B((1.0, 0.45, 0.6), (0, 0, 0.3), GREEN(), bevel=0.015)
	for x in (-0.25, 0.25):
		B((0.42, 0.02, 0.22), (x, -0.23, 0.35), T("greenpaint", "dark"), bevel=0.006)
		kit.rivet((x, -0.245, 0.35), CU(), r=0.022)
	B((1.04, 0.5, 0.05), (0, 0, 0.62), T("wood", "b"), bevel=0.01)
	B((1.0, 0.12, 0.8), (0, 0.17, 1.05), GREEN(), bevel=0.015)
	for z in (0.9, 1.2):
		B((0.96, 0.18, 0.03), (0, 0.07, z), T("wood", "b"), bevel=0.006)
	for x in (-0.3, 0.0, 0.3):
		kit.cylinder(0.11, 0.02, (x, 0.07, 1.04), C((0.9, 0.88, 0.8), 0.6), rot=(80, 0, 0), verts=14, bevel=0.003)
	kit.cylinder(0.05, 0.1, (0.35, 0.04, 1.27), CU("a"), verts=10, bevel=0.005)


def hearth_planter():
	brick_box(0.8, 0.4, 0.4)
	disc(0.36, 0.4, 0.43, (0, 0), kit.tex_mat("soil", "a"), seg=12, wob=0.05)
	for (x, s) in ((-0.2, 0.9), (0.0, 1.2), (0.2, 0.8)):
		kit.mushroom((x, 0.0, 0.42), s * 0.4, cap="crystal_amber", seed=int(x * 10) + 3)
	for k in range(6):
		kit.gem((-0.35 + k * 0.14, -0.2, 0.36), (0.05, 0.03, 0.05), kit.mat("moss"), seed=k)


def hearth_pot_rack():
	B((1.0, 0.08, 0.14), (0, 0.04, 1.1), GREEN(), bevel=0.015)
	B((1.0, 0.04, 0.04), (0, -0.08, 1.06), CU(), bevel=0.006)
	for x in (-0.45, 0.45):
		B((0.04, 0.16, 0.04), (x, -0.04, 1.06), CU(), bevel=0.004)
	for (x, kind) in ((-0.3, "pan"), (0.0, "pot"), (0.3, "ladle")):
		kit.ring(0.025, 0.006, (x, -0.08, 1.02), IRON(), rot=(90, 0, 0), seg=8)
		if kind == "pan":
			B((0.02, 0.02, 0.25), (x, -0.08, 0.88), IRON(), bevel=0.003)
			kit.cylinder(0.12, 0.03, (x, -0.08, 0.68), IRON("dark"), rot=(90, 0, 0), verts=14, bevel=0.006)
		elif kind == "pot":
			log((x, -0.08, 1.0), (x, -0.08, 0.85), 0.006, IRON(), seg=5, rings=1, ends=False, bend=0)
			sphere((x, -0.08, 0.75), 0.11, CU("a"), scale=(1, 1, 0.85))
		else:
			B((0.02, 0.02, 0.3), (x, -0.08, 0.85), T("wood", "c"), bevel=0.003)
			sphere((x, -0.08, 0.68), 0.04, T("wood", "c"), scale=(1, 0.4, 1.3))
	B((0.06, 0.06, 1.05), (0, 0.04, 0.53), T("wood", "dark"), bevel=0.01)
	B((0.4, 0.3, 0.05), (0, 0, 0.025), T("wood", "dark"), bevel=0.01)


def hearth_rug():
	rug_mesh(1.3, 1.3, (0.75, 0.35, 0.2), (0.85, 0.7, 0.45), round_=True)


# ================= Lights =================
def hanging_lantern():
	"""A lantern on a short post-and-arm bracket (stands on the floor, hangs from its arm)."""
	B((0.3, 0.3, 0.06), (0, 0, 0.03), T("wood", "dark"), bevel=0.01)
	B((0.06, 0.06, 1.5), (0, 0.1, 0.78), T("wood", "b"), bevel=0.01)
	B((0.4, 0.05, 0.05), (-0.15, 0.1, 1.5), T("wood", "b"), bevel=0.008)
	log((-0.3, 0.1, 1.48), (-0.3, 0.1, 1.32), 0.008, IRON(), seg=5, rings=1, ends=False, bend=0)
	lantern_body((-0.3, 0.1, 1.05))


def lantern_body(c, s=1.0):
	x, y, z = c
	kit.cylinder(0.1 * s, 0.03, (x, y, z), CU(), verts=8, bevel=0.004)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		B((0.02, 0.02, 0.22 * s), (x + math.cos(a) * 0.075 * s, y + math.sin(a) * 0.075 * s, z + 0.12 * s), CU(), bevel=0.003)
	kit.cylinder(0.065 * s, 0.2 * s, (x, y, z + 0.12 * s), C((1.0, 0.75, 0.35), 0.3, glow=1.2), verts=8, bevel=0)
	kit.cone(0.1 * s, 0.03, 0.08 * s, (x, y, z + 0.27 * s), CU(), verts=8, bevel=0.004)
	kit.ring(0.025, 0.007, (x, y, z + 0.33 * s), CU(), rot=(90, 0, 0), seg=8)


def brazier():
	for k in range(3):
		a = 2 * math.pi * k / 3
		B((0.06, 0.06, 0.5), (math.cos(a) * 0.2, math.sin(a) * 0.2, 0.25), T("wood", "dark"), bevel=0.01, rot=(math.sin(a) * 12, -math.cos(a) * 12, 0))
	kit.cone(0.15, 0.32, 0.2, (0, 0, 0.55), IRON("dark"), verts=14, bevel=0.01)
	kit.ring(0.32, 0.02, (0, 0, 0.65), CU(), seg=18)
	ember_bed(0, 0, 0.63, 0.22, n=12)
	kit.fire_spot((0, 0, 0.68), 0.6)


def candle_cluster():
	disc(0.3, 0.0, 0.05, (0, 0), T("stone", "c"), seg=16, wob=0.05)
	for (x, y, r, h) in ((0, 0.02, 0.07, 0.35), (-0.14, -0.05, 0.05, 0.22), (0.13, -0.06, 0.05, 0.18), (0.08, 0.12, 0.04, 0.12)):
		kit.cylinder(r, h, (x, y, 0.05 + h / 2), C((0.95, 0.88, 0.65), 0.85), verts=10, bevel=0.01)
		kit.fire_spot((x, y, 0.05 + h + 0.03), 0.12)
		kit.gem((x + r * 0.8, y, 0.05 + h * 0.8), (0.015, 0.015, 0.03), C((0.95, 0.88, 0.65), 0.85), seed=int(h * 100))


def chandelier():
	"""A wagon-wheel chandelier on a short stand (so it can be placed): 6 candles, chains to a centre ring."""
	B((0.3, 0.3, 0.05), (0, 0, 0.025), T("wood", "dark"), bevel=0.01)
	B((0.07, 0.07, 1.9), (0, 0, 0.95), T("wood", "b"), bevel=0.01)
	z = 1.2
	kit.ring(0.45, 0.04, (0, 0, z), T("wood", "b"), seg=24)
	for k in range(6):
		a = 2 * math.pi * k / 6
		B((0.42, 0.04, 0.04), (math.cos(a) * 0.22, math.sin(a) * 0.22, z), T("wood", "b"), bevel=0.006, rot=(0, 0, math.degrees(a)))
		x, y = math.cos(a) * 0.45, math.sin(a) * 0.45
		kit.cylinder(0.04, 0.03, (x, y, z + 0.05), CU(), verts=8, bevel=0.004)
		kit.cylinder(0.025, 0.12, (x, y, z + 0.12), C((0.95, 0.88, 0.65), 0.85), verts=8, bevel=0.004)
		kit.fire_spot((x, y, z + 0.2), 0.08)
		log((x, y, z), (0, 0, 1.85), 0.006, IRON(), seg=4, rings=1, ends=False, bend=0)


def crystal_lamp_post():
	B((0.3, 0.3, 0.08), (0, 0, 0.04), T("stone"), bevel=0.02)
	log((0, 0, 0.06), (0, 0, 1.1), 0.05, T("wood", "b"), seg=8, rings=2)
	for z in (0.3, 0.9):
		kit.ring(0.06, 0.015, (0, 0, z), CU(), seg=12)
	kit.cone(0.06, 0.12, 0.1, (0, 0, 1.15), CU(), verts=10, bevel=0.004)
	kit.crystal((0, 0, 1.18), 0.07, 0.26, C((0.3, 0.7, 1.0), 0.15, glow=1.0), sides=6)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		B((0.02, 0.02, 0.28), (math.cos(a) * 0.1, math.sin(a) * 0.1, 1.32), CU(), bevel=0.003)
	kit.ring(0.1, 0.012, (0, 0, 1.46), CU(), seg=12)


def wall_torch():
	B((0.14, 0.04, 0.3), (0, 0.02, 0.85), IRON("dark"), bevel=0.01)
	log((0, 0.0, 0.8), (0, -0.16, 0.95), 0.02, IRON(), seg=6, rings=1, ends=False, bend=0)
	kit.cone(0.04, 0.08, 0.14, (0, -0.18, 1.0), IRON(), verts=8, bevel=0.004)
	log((0, -0.18, 0.86), (0, -0.18, 1.05), 0.03, T("wood", "b"), seg=6, rings=1)
	kit.rope_wrap((0, -0.18), 0.045, 1.02, 1.08, 2, thick=0.012, material=kit.tex_mat("leather", "dark"))
	kit.fire_spot((0, -0.18, 1.12), 0.25)
	B((0.06, 0.04, 0.85), (0, 0.02, 0.42), T("wood", "dark"), bevel=0.008)
	B((0.25, 0.2, 0.04), (0, 0, 0.02), T("wood", "dark"), bevel=0.008)


def firefly_jar():
	kit.cylinder(0.11, 0.26, (0, 0, 0.13), C((0.95, 0.75, 0.35), 0.1, glow=0.4), verts=14, bevel=0.03)
	kit.cylinder(0.07, 0.05, (0, 0, 0.28), T("wood", "c"), verts=10, bevel=0.01)
	kit.ring(0.075, 0.012, (0, 0, 0.25), kit.tex_mat("rope"), seg=12)
	for k in range(6):
		a, r, z = k * 1.1, 0.05 + 0.03 * (k % 2), 0.06 + k * 0.03
		kit.gem((math.cos(a) * r, math.sin(a) * r, z), (0.015, 0.015, 0.015), C((1.0, 0.85, 0.3), 0.3, glow=2.0), seed=k)


def stone_lantern():
	for x in (-0.14, 0.14):
		stone((0.12, 0.3, 0.3), (x, 0, 0.15))
	stone((0.42, 0.36, 0.1), (0, 0, 0.35))
	B((0.3, 0.26, 0.26), (0, 0, 0.53), C((1.0, 0.7, 0.3), 0.3, glow=0.8), bevel=0.01)
	for x in (-0.15, 0.15):
		for y in (-0.13, 0.13):
			stone((0.06, 0.06, 0.28), (x, y, 0.54), tone=T("stone", "c"))
	kit.cone(0.32, 0.08, 0.2, (0, 0, 0.78), T("stone", "b"), verts=4, bevel=0.02, rot=(0, 0, 45))
	stone((0.1, 0.1, 0.08), (0, 0, 0.91))


# ================= Storage =================
def crate(w, d, h, loc, rope=False):
	x, y, z = loc
	B((w, d, h), (x, y, z + h / 2), WOOD(), bevel=0.015)
	for s_ in (-1, 1):
		B((w + 0.01, 0.02, 0.06), (x, y + s_ * d / 2, z + h * 0.15), T("wood", "dark"), bevel=0.004)
		B((w + 0.01, 0.02, 0.06), (x, y + s_ * d / 2, z + h * 0.85), T("wood", "dark"), bevel=0.004)
	for (cx, cy) in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
		B((0.04, 0.04, h), (x + cx * w / 2, y + cy * d / 2, z + h / 2), IRON(), bevel=0.004)
	if rope:
		kit.ring(0.05, 0.012, (x + w / 2 + 0.01, y, z + h * 0.6), kit.tex_mat("rope"), rot=(0, 90, 0), seg=10)


def crate_stack():
	crate(0.6, 0.5, 0.4, (0, 0, 0), rope=True)
	crate(0.5, 0.45, 0.35, (0.03, 0.0, 0.4), rope=True)


def grain_sacks():
	for (x, y, s) in ((-0.15, 0.05, 1.0), (0.18, 0.08, 0.9), (0.0, -0.18, 0.7)):
		o = sphere((x, y, 0.0), 0.2 * s, C((0.68, 0.55, 0.38), 0.95), scale=(1, 1, 1.25), cut=0.0)
		kit.roughen(o, 0.012, 1, seed=int(x * 10) + 5)
		kit.ring(0.07 * s, 0.015, (x, y, 0.25 * s), kit.tex_mat("rope"), seg=10)
		kit.cone(0.07 * s, 0.1 * s, 0.08 * s, (x, y, 0.29 * s), C((0.62, 0.5, 0.34), 0.95), verts=8, bevel=0.004)
	for k in range(5):
		kit.gem((0.05 + k * 0.04, -0.3 + J(0.03), 0.02), (0.03, 0.025, 0.02), kit.mat("mushroom_red" if k % 2 else "gill"), seed=k)


def cheese_shelf():
	W, H = 0.7, 1.4
	for x in (-W / 2, W / 2):
		B((0.06, 0.4, H), (x, 0, H / 2), T("wood", "dark"), bevel=0.012)
	for z in (0.05, 0.45, 0.85, 1.25):
		plank((W, 0.38, 0.04), (0, 0, z))
		for (x, s) in ((-0.15, 1.0), (0.15, 0.9)):
			if z < 1.2:
				kit.cylinder(0.12 * s, 0.12, (x, 0, z + 0.08), C((0.95, 0.72, 0.3), 0.6), verts=14, bevel=0.015)
	for x in (-W / 2, W / 2):
		for z in (0.1, H - 0.1):
			rivet((x, -0.2, z), CU("dark"))


def keg():
	for x in (-0.3, 0.3):
		B((0.08, 0.5, 0.06), (x, 0, 0.03), T("wood", "dark"), bevel=0.01)
		for y in (-0.18, 0.18):
			B((0.08, 0.08, 0.22), (x, y, 0.14), T("wood", "dark"), bevel=0.01, rot=(math.copysign(30, y), 0, 0))
	o = kit.cylinder(0.3, 0.7, (0, 0, 0.5), T("wood", "b"), rot=(0, 90, 0), verts=16, bevel=0.03)
	o.scale = (1, 1.08, 1.08)
	for x in (-0.28, -0.1, 0.1, 0.28):
		kit.ring(0.31 if abs(x) < 0.2 else 0.3, 0.02, (x, 0, 0.5), CU(), rot=(0, 90, 0), seg=20)
	kit.cylinder(0.025, 0.08, (0.37, -0.0, 0.38), CU(), rot=(0, 90, 0), verts=8, bevel=0.003)
	B((0.03, 0.03, 0.06), (0.4, 0, 0.35), CU(), bevel=0.004)


def hanging_herbs():
	B((1.0, 0.06, 0.06), (0, 0.0, 1.0), T("wood", "b"), bevel=0.01)
	for x in (-0.48, 0.48):
		B((0.06, 0.06, 1.0), (x, 0.0, 0.5), T("wood", "dark"), bevel=0.01)
		B((0.25, 0.2, 0.04), (x, 0, 0.02), T("wood", "dark"), bevel=0.008)
	cols = [(0.6, 0.4, 0.2), (0.35, 0.5, 0.2), (0.7, 0.2, 0.15), (0.3, 0.45, 0.25), (0.5, 0.35, 0.55)]
	for k in range(5):
		x = -0.32 + k * 0.16
		kit.ring(0.03, 0.008, (x, 0, 0.97), kit.tex_mat("rope"), rot=(90, 0, 0), seg=8)
		for j in range(4):
			B((0.03, 0.02, 0.28), (x + (j - 1.5) * 0.015, 0.0, 0.8), C(cols[k], 0.85), bevel=0.006, rot=(0, (j - 1.5) * 8, 0))


def ore_basket():
	kit.cone(0.2, 0.26, 0.3, (0, 0, 0.15), kit.tex_mat("straw", "a"), verts=16, bevel=0.01)
	for z in (0.05, 0.15, 0.25):
		kit.ring(0.21 + z * 0.2, 0.012, (0, 0, z), kit.tex_mat("rope"), seg=18)
	for k in range(8):
		a, r = k * 0.8, 0.12 * (k % 3) / 2
		lump((math.cos(a) * r, math.sin(a) * r, 0.31), (0.06, 0.05, 0.045), IRON("dark") if k % 2 else T("stone"), seed=k, rough=0.008)


def firewood_rack():
	for x in (-0.4, 0.4):
		for y in (-0.15, 0.15):
			B((0.06, 0.06, 0.8), (x, y, 0.4), T("wood", "dark"), bevel=0.01)
		B((0.06, 0.36, 0.06), (x, 0, 0.78), T("wood", "dark"), bevel=0.01)
	B((0.86, 0.36, 0.04), (0, 0, 0.04), T("wood", "dark"), bevel=0.008)
	for row in range(5):
		for k in range(5 - (row % 2)):
			x = -0.3 + k * 0.15 + (0.075 if row % 2 else 0)
			log((x, -0.17, 0.12 + row * 0.13), (x, 0.17, 0.12 + row * 0.13), 0.065, T("bark"), seg=7, rings=1)


def tavern_table():
	kit.cylinder(0.45, 0.07, (0, 0, 0.72), T("wood", "b"), verts=18, bevel=0.012)
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.3, math.sin(a) * 0.3, 0), (math.cos(a) * 0.2, math.sin(a) * 0.2, 0.69), 0.05, T("bark"), seg=7, rings=2)
	kit.ring(0.26, 0.012, (0, 0, 0.3), kit.tex_mat("rope"), seg=16)
	B((0.3, 0.18, 0.025), (0.0, 0.05, 0.77), T("wood", "c"), bevel=0.005)
	sphere((0.0, 0.05, 0.78), 0.08, C((0.75, 0.5, 0.25), 0.6), scale=(1.3, 0.8, 0.6), cut=0.0)
	for x in (-0.28, 0.28):
		kit.cylinder(0.055, 0.14, (x, -0.1, 0.83), T("wood", "c"), verts=10, bevel=0.008)
		kit.cylinder(0.05, 0.03, (x, -0.1, 0.915), C((0.95, 0.92, 0.85), 0.9), verts=10, bevel=0.01)
		kit.ring(0.035, 0.01, (x + 0.07, -0.1, 0.83), T("wood", "c"), rot=(90, 0, 0), seg=8)


# ================= Mine props =================
def mine_cart():
	rail_track(length=1.2)
	z = 0.12
	for x in (-0.25, 0.25):
		for y in (-0.22, 0.22):
			kit.cylinder(0.1, 0.05, (x, y, z), IRON("dark"), rot=(90, 0, 0), verts=12, bevel=0.006)
	log((-0.25, -0.25, z), (-0.25, 0.25, z), 0.02, IRON(), seg=6, rings=1, ends=False, bend=0)
	log((0.25, -0.25, z), (0.25, 0.25, z), 0.02, IRON(), seg=6, rings=1, ends=False, bend=0)
	o = kit.taper(0.7, 0.45, 0.85, 0.55, 0.4, (0, 0, z + 0.06), WOOD(), bevel=0.015)
	for x in (-0.3, 0.3):
		cband((0.04, 0.5, 0.4), (x, 0, z + 0.26), rivets=0, m=IRON("dark"))
	for k in range(9):
		a, r = k * 0.7, 0.2 * (k % 3) / 2
		lump((math.cos(a) * r, math.sin(a) * r * 0.7, z + 0.46), (0.07, 0.06, 0.05), IRON("dark") if k % 3 else T("stone"), seed=k, rough=0.008)


def rail_track(length=1.0):
	for k in range(4):
		y = -length / 2 + 0.12 + k * (length - 0.24) / 3
		B((0.7, 0.12, 0.05), (0, y, 0.025), T("wood", "dark"), bevel=0.008, rot=(0, 0, J(3)))
	for x in (-0.22, 0.22):
		B((0.04, length, 0.05), (x, 0, 0.075), IRON("a"), bevel=0.004)


def signpost():
	B((0.3, 0.3, 0.1), (0, 0, 0.05), T("stone"), bevel=0.02)
	log((0, 0, 0.05), (0, 0, 1.5), 0.05, T("wood", "b"), seg=8, rings=2)
	for (z, ang, ln) in ((1.35, 10, 0.5), (1.1, -15, 0.45), (0.85, 5, 0.4)):
		B((ln, 0.04, 0.14), (math.cos(math.radians(ang)) * ln / 2.2, -0.05, z), T("wood", "c"), bevel=0.008, rot=(0, 0, ang))
		rivet((0, -0.075, z), IRON())


def timber_stack():
	beams = []  # (x, y, z, yaw degrees) of each beam, so the rope can follow where they really lie
	for row in range(3):
		for k in range(3 - row):
			y = (k - (2 - row) / 2) * 0.17
			c = (J(0.02), y, 0.07 + row * 0.14)
			a = J(2)
			B((0.9, 0.16, 0.14), c, WOOD(), bevel=0.012, rot=(0, 0, a))
			beams.append(c + (a,))
	# Two ropes pulled tight round the pile (F730, owner Nov 22: "the rope isn't really tied around the logs"; it was a
	# loose round ring). Each follows the pile's outline where it crosses (a 3-2-1 stack: a rounded triangle) and
	# presses 5 mm into the wood, so it is joined to the beams, not floating or sitting exactly on them (no shimmer).
	for x in (-0.25, 0.25):
		_tight_rope(x, beams, 0.014)


def _tight_rope(x, beams, r, hw=0.08, hh=0.07, sink=0.005, sides=8):
	"""A closed rope loop at `x` wrapped tight round boxes lying along x (the convex outline of their cross-sections)."""
	pts = []
	for (bx, by, bz, a) in beams:
		yc = by + (x - bx) * math.tan(math.radians(a))
		w = hw / math.cos(math.radians(a))
		pts += [(yc - w, bz - hh), (yc + w, bz - hh), (yc - w, bz + hh), (yc + w, bz + hh)]
	pts = sorted(set(pts))
	cross = lambda o, a, b: (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])  # noqa: E731
	lower, upper = [], []
	for p in pts:
		while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
			lower.pop()
		lower.append(p)
	for p in reversed(pts):
		while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
			upper.pop()
		upper.append(p)
	hull = lower[:-1] + upper[:-1]  # counter-clockwise in (y, z)
	off = r - sink  # the rope's centre this far out from the wood
	path = []
	n = len(hull)
	for i, v in enumerate(hull):
		p0, p1 = hull[i - 1], hull[(i + 1) % n]
		a0 = math.atan2(-(v[0] - p0[0]), v[1] - p0[1])  # outward normal of the edge coming in
		a1 = math.atan2(-(p1[0] - v[0]), p1[1] - v[1])  # ... and of the edge going out
		while a1 < a0:
			a1 += 2 * math.pi
		steps = max(1, int((a1 - a0) / 0.35))
		for s in range(steps + 1):
			t = a0 + (a1 - a0) * s / steps
			path.append((x, v[0] + math.cos(t) * off, v[1] + math.sin(t) * off))
	verts, faces = [], []
	m = len(path)
	for i, p in enumerate(path):
		q0, q1 = path[i - 1], path[(i + 1) % m]
		d = (q1[1] - q0[1], q1[2] - q0[2])
		ln = math.hypot(*d) or 1.0
		ny, nz = d[1] / ln, -d[0] / ln  # in the loop's plane, at right angles to the rope
		for k in range(sides):
			t = 2 * math.pi * k / sides
			verts.append((p[0] + math.cos(t) * r, p[1] + math.sin(t) * r * ny, p[2] + math.sin(t) * r * nz))
	for i in range(m):
		j = (i + 1) % m
		for k in range(sides):
			k2 = (k + 1) % sides
			faces.append((i * sides + k, i * sides + k2, j * sides + k2, j * sides + k))
	mesh(verts, faces, kit.tex_mat("rope"), smooth=True)


def rope_fence():
	for x in (-0.8, 0.8):
		stone((0.2, 0.2, 0.1), (x, 0, 0.05))
		log((x, 0, 0.08), (x, 0, 0.9), 0.05, T("bark"), seg=8, rings=2)
		rope_tie((x, 0, 0.8), 0.05)
	log((-0.8, 0, 0.5), (0.8, 0, 0.5), 0.04, T("bark"), seg=7, rings=3)
	pts = [(-0.8 + 1.6 * i / 10, 0, 0.82 - 0.12 * math.sin(math.pi * i / 10)) for i in range(11)]
	for p, q in zip(pts, pts[1:]):
		log(p, q, 0.015, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)


# ================= Wall trophies (flat back at +Y) =================
def plank_board(w, h, z, round_=False):
	if round_:
		kit.cylinder(w / 2, 0.06, (0, 0.03, z), T("wood", "b"), rot=(90, 0, 0), verts=18, bevel=0.012)
		kit.ring(w / 2, 0.025, (0, 0.0, z), CU(), rot=(90, 0, 0), seg=20)
		for k in range(8):
			a = 2 * math.pi * k / 8
			rivet((math.cos(a) * (w / 2 - 0.01), -0.025, z + math.sin(a) * (w / 2 - 0.01)), CU("dark"))
		return
	B((w, 0.06, h), (0, 0.03, z), T("wood", "b"), bevel=0.015)
	for (cx, cz) in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
		B((0.1, 0.015, 0.1), (cx * (w / 2 - 0.04), -0.005, z + cz * (h / 2 - 0.04)), CU(), bevel=0.004)


def wall_post(top):
	"""Wall trophies also stand on the floor on a short post, so they never float when placed in the open."""
	B((0.06, 0.05, top), (0, 0.04, top / 2), T("wood", "dark"), bevel=0.008)
	B((0.3, 0.2, 0.04), (0, 0.04, 0.02), T("wood", "dark"), bevel=0.008)


def banner(rgb, art):
	wall_post(1.6)
	log((-0.4, 0.0, 1.5), (0.4, 0.0, 1.5), 0.025, T("wood", "b"), seg=6, rings=1)
	mesh_cloth((0.0, -0.01), 1.49, 0.66, 0.9, m=C(rgb, 0.95))
	for x in (-0.25, 0.0, 0.25):
		kit.cone(0.02, 0.0, 0.08, (x, -0.02, 0.56), C((0.85, 0.7, 0.3), 0.6), rot=(180, 0, 0), verts=6, bevel=0)
	art()


def banner_anvil():
	def art():
		B((0.3, 0.02, 0.16), (0, -0.03, 1.08), C((0.85, 0.75, 0.4), 0.6), bevel=0.01)
		kit.cone(0.15, 0.0, 0.3, (0, -0.03, 1.28), C((0.95, 0.9, 0.85), 0.8), rot=(90, 0, 0), verts=3, bevel=0)
	banner((0.6, 0.15, 0.12), art)


def banner_landscape():
	def art():
		for (x, s, c) in ((-0.12, 0.28, (0.3, 0.4, 0.3)), (0.1, 0.35, (0.4, 0.5, 0.45))):
			kit.cone(s / 2, 0.0, s, (x, -0.03, 1.0 + s / 2), C(c, 0.9), rot=(90, 0, 0), verts=3, bevel=0)
		B((0.06, 0.02, 0.3), (0, -0.03, 0.85), C((0.3, 0.5, 0.75), 0.6), bevel=0.01, rot=(0, 20, 0))
	banner((0.2, 0.35, 0.3), art)


def horn_plaque():
	wall_post(1.0)
	plank_board(0.5, 0.5, 1.2, round_=True)
	kit.cone(0.06, 0.012, 0.42, (0.1, -0.12, 1.25), kit.mat("bone", -0.1), rot=(70, 40, 0), verts=10, bevel=0)
	kit.ring(0.065, 0.015, (0.0, -0.05, 1.18), CU(), rot=(70, 40, 0), seg=10)


def fossil_plaque():
	wall_post(1.0)
	plank_board(0.55, 0.55, 1.25)
	B((0.42, 0.04, 0.42), (0, -0.02, 1.25), T("stone", "c"), bevel=0.02)
	for i in range(18):
		t = i / 18
		a = t * 3.6 * math.pi
		r = 0.15 * (1 - t * 0.85)
		kit.ring(0.008 + 0.03 * (1 - t), 0.01, (math.cos(a) * r, -0.045, 1.25 + math.sin(a) * r), T("stone", "b"), rot=(90, 0, 0), seg=8)


def crossed_pickaxes():
	wall_post(1.0)
	plank_board(0.5, 0.5, 1.25)
	for s_ in (-1, 1):
		B((0.04, 0.035, 0.7), (0, -0.03, 1.25), T("wood", "b"), bevel=0.006, rot=(0, s_ * 40, 0))
		hx, hz = -s_ * 0.24, 1.25 + 0.27
		B((0.3, 0.035, 0.05), (hx, -0.04, hz), IRON(), bevel=0.008, rot=(0, -s_ * 20, 0))


def bat_trophy():
	wall_post(1.0)
	plank_board(0.5, 0.5, 1.25)
	sphere((0, -0.06, 1.24), 0.09, C((0.5, 0.35, 0.3), 0.85), scale=(1, 0.7, 1.1))
	for s_ in (-1, 1):
		pts = [(0, 1.3), (s_ * 0.28, 1.38), (s_ * 0.32, 1.12), (s_ * 0.18, 1.18), (0, 1.15)]
		v = [(x, -0.05, z) for x, z in pts] + [(x, -0.07, z) for x, z in pts]
		n = len(pts)
		mesh(v, [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)], C((0.45, 0.25, 0.25), 0.8))
		kit.cone(0.03, 0.0, 0.07, (s_ * 0.05, -0.06, 1.36), C((0.5, 0.35, 0.3), 0.85), verts=5, bevel=0)


def rune_shield():
	wall_post(1.0)
	plank_board(0.55, 0.55, 1.25, round_=True)
	m = C((0.95, 0.75, 0.4), 0.5, glow=0.4)
	B((0.03, 0.02, 0.32), (0, -0.04, 1.25), m, bevel=0.004)
	for s_ in (-1, 1):
		B((0.03, 0.02, 0.16), (s_ * 0.05, -0.04, 1.33), m, bevel=0.004, rot=(0, s_ * 35, 0))
		B((0.03, 0.02, 0.16), (s_ * 0.05, -0.04, 1.15), m, bevel=0.004, rot=(0, -s_ * 35, 0))


def map_board():
	wall_post(1.0)
	plank_board(0.7, 0.55, 1.25)
	B((0.6, 0.02, 0.45), (0, -0.01, 1.25), C((0.85, 0.75, 0.55), 0.95), bevel=0.004)
	ink = C((0.4, 0.28, 0.15), 0.9)
	for (x, z, a) in ((-0.15, 1.35, 10), (0.05, 1.28, -30), (0.15, 1.15, 60)):
		B((0.15, 0.012, 0.012), (x, -0.025, z), ink, bevel=0, rot=(0, a, 0))
	for x in (-0.2, 0.18):
		kit.cone(0.04, 0.0, 0.06, (x, -0.025, 1.4), ink, rot=(90, 0, 0), verts=3, bevel=0)


# ================= Fungal garden =================
def mushroom_planter():
	crate(0.8, 0.4, 0.3, (0, 0, 0))
	disc(0.36, 0.3, 0.33, (0, 0), kit.tex_mat("soil", "a"), seg=12, wob=0.05)
	for (x, s, c) in ((-0.22, 1.0, "glow_cyan"), (0.0, 1.4, "glow_cyan"), (0.22, 0.9, "glow_cyan")):
		kit.mushroom((x, 0.0, 0.32), s * 0.35, cap=c, seed=int(x * 10) + 2)
	for k in range(5):
		kit.gem((-0.3 + k * 0.15, -0.18, 0.32), (0.05, 0.03, 0.05), kit.mat("sprout"), seed=k)


def potted_fungus():
	kit.cone(0.13, 0.2, 0.25, (0, 0, 0.125), kit.tex_mat("clay", "a"), verts=14, bevel=0.01)
	kit.ring(0.2, 0.02, (0, 0, 0.24), kit.tex_mat("clay", "b"), seg=16)
	disc(0.18, 0.22, 0.25, (0, 0), kit.tex_mat("soil", "a"), seg=12)
	log((0, 0, 0.24), (0.02, 0, 0.55), 0.04, C((0.8, 0.7, 0.85), 0.7), seg=8, rings=2, bend=0.15)
	sphere((0.02, 0, 0.55), 0.2, C((0.6, 0.25, 0.75), 0.45, glow=0.3), scale=(1, 1, 0.45), cut=0.0)


def hanging_basket():
	B((0.3, 0.3, 0.05), (0, 0, 0.025), T("wood", "dark"), bevel=0.01)
	B((0.06, 0.06, 1.5), (0, 0.1, 0.78), T("wood", "b"), bevel=0.01)
	B((0.45, 0.05, 0.05), (-0.18, 0.1, 1.5), T("wood", "b"), bevel=0.008)
	x = -0.35
	sphere((x, 0.1, 0.8), 0.2, kit.tex_mat("straw", "a"), scale=(1, 1, 0.6), cut=0.0)
	disc(0.19, 0.8 + 0.115, 0.8 + 0.125, (x, 0.1), kit.mat("moss"), seg=12)
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((x + math.cos(a) * 0.18, 0.1 + math.sin(a) * 0.18, 0.92), (x, 0.1, 1.48), 0.006, IRON(), seg=4, rings=1, ends=False, bend=0)
	for k in range(5):
		a = k * 1.25
		log((x + math.cos(a) * 0.18, 0.1 + math.sin(a) * 0.18, 0.88), (x + math.cos(a) * 0.22, 0.1 + math.sin(a) * 0.22, 0.65), 0.012, kit.mat("sprout"), seg=5, rings=2, ends=False, bend=0.3)
	kit.mushroom((x, 0.1, 0.92), 0.25, cap="crystal_amber", seed=4)


def stepping_stones():
	for k, (x, y) in enumerate(((-0.35, -0.2), (0.0, 0.0), (0.35, 0.22), (-0.1, 0.35))):
		o = kit.cylinder(0.18, 0.06, (x, y, 0.03), T("stone", "c"), verts=10, bevel=0.015)
		kit.roughen(o, 0.006, 1, seed=k)
	for k in range(6):
		kit.gem((J(0.4), J(0.35), 0.02), (0.06, 0.04, 0.02), kit.mat("moss"), seed=k)
	disc(0.55, 0.0, 0.012, (0, 0.05), kit.tex_mat("soil", "a"), seg=16, wob=0.1)


def mushroom_fountain():
	for k in range(8):
		a = 2 * math.pi * k / 8
		stone((0.24, 0.16, 0.25), (math.cos(a) * 0.38, math.sin(a) * 0.38, 0.125), rotz=math.degrees(a) + 90)
	water_disc(0.34, 0.2, (0, 0))
	log((0, 0, 0.18), (0, 0, 0.75), 0.07, C((0.85, 0.8, 0.7), 0.7), seg=8, rings=2, bend=0.1)
	sphere((0, 0, 0.72), 0.3, C((0.75, 0.4, 0.2), 0.5), scale=(1, 1, 0.45), cut=0.0)
	for k in range(6):
		a = k * 1.05
		kit.gem((math.cos(a) * 0.17, math.sin(a) * 0.17, 0.83), (0.03, 0.03, 0.015), C((0.95, 0.9, 0.8), 0.6), seed=k)
	stream((0.28, 0, 0.72), (0.3, 0, 0.2), r=0.014)


def mushroom_stool():
	log((0, 0, 0.0), (0, 0, 0.35), 0.1, C((0.88, 0.82, 0.68), 0.7), seg=10, rings=2, bend=0.05, r1=0.08)
	sphere((0, 0, 0.33), 0.26, C((0.7, 0.35, 0.18), 0.5), scale=(1, 1, 0.42), cut=0.0)
	for k in range(7):
		a = k * 0.9
		r = 0.08 + 0.08 * (k % 2)
		kit.gem((math.cos(a) * r, math.sin(a) * r, 0.43), (0.035, 0.035, 0.012), C((0.95, 0.85, 0.65), 0.6), seed=k)


def glow_trellis():
	for x in (-0.4, 0.4):
		B((0.06, 0.06, 1.3), (x, 0, 0.65), T("wood", "b"), bevel=0.01)
		stone((0.18, 0.18, 0.1), (x, 0, 0.05))
	for k in range(6):
		for s_ in (-1, 1):
			B((0.03, 0.03, 0.55), (-0.2 + (k % 3) * 0.2, 0, 0.3 + (k // 3) * 0.45), T("wood", "c"), bevel=0.004, rot=(0, s_ * 35, 0))
	B((0.86, 0.06, 0.06), (0, 0, 1.28), T("wood", "b"), bevel=0.01)
	for k in range(10):
		x, z = J(0.35), 0.2 + J(0.5) + 0.5
		kit.gem((x, -0.03, z), (0.05, 0.02, 0.04), kit.mat("sprout"), seed=k)
		if k % 2:
			kit.gem((x + 0.03, -0.045, z - 0.03), (0.018, 0.018, 0.018), C((0.3, 0.75, 1.0), 0.3, glow=1.5), seed=k + 20)


def mossy_bench():
	for x in (-0.45, 0.45):
		log((x, -0.1, 0.0), (x, 0.1, 0.0), 0.16, T("bark"), seg=9, rings=1, end_m=kit.tex_mat("wood", "c"))
	log((-0.6, 0, 0.3), (0.6, 0, 0.3), 0.15, T("bark"), seg=10, rings=3, end_m=kit.tex_mat("wood", "c"))
	B((1.0, 0.24, 0.04), (0, 0, 0.44), kit.tex_mat("wood", "c"), bevel=0.01)
	for k in range(6):
		kit.gem((-0.5 + k * 0.2, J(0.1), 0.44), (0.05, 0.04, 0.02), kit.mat("moss"), seed=k)
	for x in (-0.3, 0.4):
		kit.mushroom((x, 0.12, 0.42), 0.2, cap="crystal_amber", seed=int(x * 10) + 7)


# ================= Creative beams (Valheim-style), real 26 and 45 degree angles =================
def beam(length, ang=0.0, r=0.1):
	"""A rough log beam `length` long, rising `ang` degrees, its low end on the ground at the origin side."""
	a = math.radians(ang)
	x0 = -length / 2 * math.cos(a)
	p0 = (x0, 0, r)
	p1 = (x0 + length * math.cos(a), 0, r + length * math.sin(a))
	log(p0, p1, r, T("bark"), seg=9, rings=4, bend=0.06)
	for t in (0.15, 0.85):
		c = tuple(p0[i] + (p1[i] - p0[i]) * t for i in range(3))
		kit.ring(r + 0.01, 0.014, c, kit.tex_mat("rope"), rot=(0, 90 - ang, 0), seg=12)


def pole(h, r=0.09):
	B((0.3, 0.3, 0.08), (0, 0, 0.04), T("stone"), bevel=0.02)
	log((0, 0, 0.06), (0, 0, h), r, T("bark"), seg=9, rings=4, bend=0.04)


def brace_corner():
	pole(1.0)
	log((0.0, 0, 0.95), (0.6, 0, 0.95), 0.08, T("bark"), seg=8, rings=2)
	log((0.0, 0, 0.55), (0.42, 0, 0.95), 0.05, T("bark"), seg=7, rings=2)
	for c in ((0, 0, 0.95), (0, 0, 0.55)):
		kit.ring(0.1, 0.014, c, kit.tex_mat("rope"), seg=12)


MODELS = {
	"shack_bed": shack_bed, "shack_table": shack_table, "shack_stool": shack_stool, "shack_bench": shack_bench,
	"shack_shelf": shack_shelf, "shack_nightstand": shack_nightstand, "shack_peg_rack": shack_peg_rack, "shack_rug": shack_rug,
	"stone_bed": stone_bed, "stone_table": stone_table, "stone_stool": stone_stool, "stone_throne": stone_throne,
	"stone_wall_shelf": stone_wall_shelf, "stone_weapon_plaque": stone_weapon_plaque, "stone_chest": stone_chest, "stone_rug": stone_rug,
	"hearth_bed": hearth_bed, "hearth_table": hearth_table, "hearth_chair": hearth_chair, "hearth_fireplace": hearth_fireplace,
	"hearth_dresser": hearth_dresser, "hearth_planter": hearth_planter, "hearth_pot_rack": hearth_pot_rack, "hearth_rug": hearth_rug,
	"hanging_lantern": hanging_lantern, "brazier": brazier, "candle_cluster": candle_cluster, "chandelier": chandelier,
	"crystal_lamp_post": crystal_lamp_post, "wall_torch": wall_torch, "firefly_jar": firefly_jar, "stone_lantern": stone_lantern,
	"crate_stack": crate_stack, "grain_sacks": grain_sacks, "cheese_shelf": cheese_shelf, "keg": keg,
	"hanging_herbs": hanging_herbs, "ore_basket": ore_basket, "firewood_rack": firewood_rack, "tavern_table": tavern_table,
	"mine_cart": mine_cart, "rail_track": rail_track, "signpost": signpost, "timber_stack": timber_stack, "rope_fence": rope_fence,
	"banner_anvil": banner_anvil, "banner_landscape": banner_landscape, "horn_plaque": horn_plaque, "fossil_plaque": fossil_plaque,
	"crossed_pickaxes": crossed_pickaxes, "bat_trophy": bat_trophy, "rune_shield": rune_shield, "map_board": map_board,
	"mushroom_planter": mushroom_planter, "potted_fungus": potted_fungus, "hanging_basket": hanging_basket,
	"stepping_stones": stepping_stones, "mushroom_fountain": mushroom_fountain, "mushroom_stool": mushroom_stool,
	"glow_trellis": glow_trellis, "mossy_bench": mossy_bench,
	"beam_1m": lambda: beam(1.0), "beam_2m": lambda: beam(2.0), "beam_2m_26": lambda: beam(2.0, 26.565),
	"beam_2m_45": lambda: beam(2.0, 45.0), "pole_1m": lambda: pole(1.0), "pole_2m": lambda: pole(2.0), "brace_corner": brace_corner,
}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
