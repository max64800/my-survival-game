# Home decor, Nov 21 batch g: bonsai, mushroom shelf, dartboard, stone game table, drum, crystal globe, wind chime,
# two floor mosaics. Same look as night_decor.py.
# Owner fix round (Nov 21): root_bonsai root-over-rock with crisp leaves, mushroom_shelf_garden uses the game's own
# glowcap/gfungus_cap/tinycaps models, dartboard hangs on the wall (no stand), crystal_globe + wind_chime more detail.
# Deleted by the owner: glowfish_tank, hand_harp, toy_cart, water_clock.
#   blender --background --factory-startup --python builds/decor_nov21_g.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (mushroom shelf, dartboard) have a flat back at +Y; the dartboard hangs on the wall only. The wind chime hangs from its ceiling hook.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, disc, kit, log, mesh, plank, rivet, rng, stone, stream, water_disc  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import CU, IRON, WOOD, plank_board, rope_tie, wall_post  # noqa: E402,F401
from decor_nov21_f import glass, place_glb, tint  # noqa: E402,F401  (glass is also imported from here by decor_nov21_lw)
from decor_nov21_a import slim  # noqa: E402


def chain(pts, r, m, r_end=None, seg=7):
	"""A bent branch/trunk through several points (each piece starts where the last ended)."""
	n = len(pts) - 1
	r_end = r if r_end is None else r_end
	for i in range(n):
		ra = r + (r_end - r) * i / n
		rb = r + (r_end - r) * (i + 1) / n
		log(pts[i], pts[i + 1], ra, m, seg=seg, rings=2, ends=False, bend=0.12, r1=rb)


# ================= living things =================
def leaf_cluster(c, rad, n, seed, cols):
	"""A dome of many small crisp pointed leaves (no blobs), each a thin diamond facing outward."""
	import random
	r = random.Random(seed)
	for k in range(n):
		u, a = r.uniform(0.15, 1.0), r.uniform(0, 2 * math.pi)
		d = Vector((math.cos(a) * math.sqrt(1 - u * u), math.sin(a) * math.sqrt(1 - u * u), u * 0.7)).normalized()
		f = r.uniform(0.25, 0.9)
		p = Vector(c) + Vector((d.x * rad * f, d.y * rad * f, d.z * rad * 0.6 * f))
		log(tuple(c), tuple(p), 0.004, T("bark", "b"), seg=4, rings=1, ends=False, bend=0)  # each leaf on its own twig
		ln, w, t = r.uniform(0.035, 0.05), r.uniform(0.014, 0.02), 0.003
		v = [(0, -ln / 2, 0), (w / 2, 0, 0), (0, ln / 2, 0), (-w / 2, 0, 0)]
		v = [(x, y, -t) for x, y, _ in v] + [(x, y, t + 0.002 * (abs(y) < 0.001)) for x, y, _ in v]
		o = mesh(v, [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], cols[k % len(cols)])
		o.location = p
		o.rotation_euler = (d.to_track_quat("Z", "Y") @ Quaternion((0, 0, 1), r.uniform(0, 6.28))).to_euler()


def root_bonsai():
	"""A root-over-rock bonsai (owner Nov 21: more detail): roots grip a rock and dive into the soil of a footed stone
	tray with a cut-in rim groove; crisp leaf pads, pebbles, a few glowing buds, on a small wooden stand."""
	wood = kit.tex_mat("wood", "b")
	B((0.56, 0.38, 0.04), (0, 0, 0.02), wood, bevel=0.01)
	for cx in (-1, 1):
		B((0.05, 0.36, 0.03), (cx * 0.22, 0, 0.045), kit.tex_mat("wood", "dark"), bevel=0.006)
	stone_m = T("greystone", "b")
	for cx in (-1, 1):  # tray feet
		for cy in (-1, 1):
			B((0.06, 0.05, 0.03), (cx * 0.19, cy * 0.11, 0.075), T("greystone", "a"), bevel=0.008)
	B((0.5, 0.32, 0.08), (0, 0, 0.13), stone_m, bevel=0.015)
	for s_ in (-1, 1):  # rim groove cut into the sides (dark sunk strip)
		B((0.46, 0.006, 0.012), (0, s_ * 0.1585, 0.14), kit.mat("stone_dark", -0.35), bevel=0)
	B((0.44, 0.26, 0.012), (0, 0, 0.168), kit.tex_mat("soil", "a"), bevel=0.004)
	for k in range(9):
		lump((-0.19 + k * 0.045, -0.105 + 0.02 * (k % 2), 0.176), (0.016, 0.013, 0.008), T("stone", "abc"[k % 3]), seed=k, rough=0.002)
	rock = lump((0.02, 0.01, 0.23), (0.11, 0.09, 0.08), T("greystone", "c"), seed=6, rough=0.008)
	bark = T("bark", "b")
	for k in range(6):  # roots over the rock into the soil
		a = 2 * math.pi * k / 6 + 0.3
		top = (0.02 + math.cos(a) * 0.03, 0.01 + math.sin(a) * 0.03, 0.31)
		mid = (0.02 + math.cos(a) * 0.105, 0.01 + math.sin(a) * 0.085, 0.24)
		low = (0.02 + math.cos(a) * 0.15, 0.01 + math.sin(a) * 0.11, 0.17)
		chain([top, mid, low], 0.018, bark, r_end=0.01)
	trunk = [(0.02, 0.01, 0.3), (0.06, 0.0, 0.4), (0.0, 0.02, 0.5), (0.05, 0.01, 0.58), (0.12, 0.0, 0.62)]
	chain(trunk, 0.04, bark, r_end=0.02)
	chain([(0.0, 0.02, 0.5), (-0.1, 0.0, 0.53), (-0.17, 0.02, 0.58)], 0.02, bark, r_end=0.011)
	chain([(0.05, 0.01, 0.58), (0.03, 0.06, 0.66), (0.0, 0.05, 0.71)], 0.018, bark, r_end=0.01)
	chain([(0.06, 0.0, 0.4), (0.16, -0.02, 0.44), (0.21, -0.01, 0.48)], 0.016, bark, r_end=0.009)
	leaves = [C((0.2, 0.3, 0.12), 0.85), C((0.17, 0.27, 0.1), 0.85), C((0.25, 0.35, 0.14), 0.85)]
	for k, (p, rad, n) in enumerate((((0.12, 0.0, 0.63), 0.12, 70), ((-0.17, 0.02, 0.59), 0.1, 56),
			((0.0, 0.05, 0.72), 0.1, 56), ((0.21, -0.01, 0.49), 0.08, 40))):
		leaf_cluster(p, rad, n, k + 3, leaves)
	for k, p in enumerate(((0.12, -0.04, 0.66), (-0.17, -0.02, 0.62), (0.0, 0.02, 0.76))):
		kit.gem(p, (0.009, 0.009, 0.009), C((0.95, 0.75, 0.3), 0.3, glow=1.5), seed=k)


def mushroom_shelf_garden():
	"""A standing wall shelf (flat back) with soil trays of the game's own mushrooms (owner Nov 21)."""
	W, D, H = 0.9, 0.3, 1.36
	back = D / 2
	B((W + 0.04, 0.03, H + 0.04), (0, back - 0.015, 0.02 + (H + 0.04) / 2), T("wood", "dark"), bevel=0.008)
	for x in (-W / 2, W / 2):
		B((0.05, D - 0.01, H), (x, -0.005, H / 2), T("wood", "b"), bevel=0.012)
		for z in (0.15, H - 0.1):
			rivet((x, -D / 2, z), CU("dark"))
	plank((W + 0.08, D + 0.02, 0.05), (0, -0.01, H + 0.045))
	kinds = [("cave/glowcap", 0.2, ("soil",), "glow_cap", (0.25, 0.95, 0.85), 0.8), ("cave/gfungus_cap", 0.17, (), None, None, 0),
		("cave/tinycaps", 0.05, (), "tint", (0.75, 0.5, 0.3), 0)]
	for row, zs in enumerate((0.1, 0.52, 0.94)):
		plank((W - 0.03, D - 0.04, 0.04), (0, -0.01, zs))
		zt = zs + 0.02
		for i, x in enumerate((-0.21, 0.21)):
			B((0.38, 0.2, 0.07), (x, -0.03, zt + 0.03), T("wood", "c"), bevel=0.01)
			B((0.34, 0.16, 0.02), (x, -0.03, zt + 0.07), kit.tex_mat("soil", "a"), bevel=0.006)
			for y in (-0.13, 0.07):
				B((0.4, 0.025, 0.03), (x, y, zt + 0.065), T("wood", "b"), bevel=0.006)
			top = zt + 0.078
			name, h, drop, key, rgb, glow = kinds[(row + i) % 3]
			if name.endswith("tinycaps"):  # a young glowcap with a carpet of tiny caps round it
				tint(place_glb("cave/glowcap", (x, -0.03, top), 0.14, rotz=50 * row, drop=("soil",), height=True), "glow_cap", (0.25, 0.95, 0.85), 0.8)
				for j, dx in enumerate((-0.1, 0.1)):
					tint(place_glb(name, (x + dx, -0.03, top), 0.13, rotz=40 * j + 20 * i), key, rgb, glow)
			else:
				for j, (dx, s) in enumerate(((-0.07, 1.0), (0.08, 0.8))):
					ms = place_glb(name, (x + dx, -0.03 + 0.01 * j, top), h * s, rotz=70 * j + 30 * row, drop=drop, height=True)
					if key:
						tint(ms, key, rgb, glow)
	slim(small=0.03, fine=0.005, few=0.02)  # lighter file (under 2 MB), same look


# ================= games and music =================
def dartboard():
	"""A round wooden dartboard hanging on the wall from a leather strap and peg (owner Nov 21: no stand; flat back at +Y)."""
	z = 0.34
	B((0.5, 0.03, 0.5), (0, 0.065, z), T("wood", "dark"), bevel=0.01)  # backing board, flat on the wall
	for cx in (-1, 1):
		for cz in (-1, 1):
			rivet((cx * 0.21, 0.049, z + cz * 0.21), IRON("dark"), r=0.012)
	plank_board(0.44, 0.44, z, round_=True)
	for k, (r, rgb) in enumerate(((0.19, (0.62, 0.54, 0.4)), (0.15, (0.42, 0.13, 0.08)), (0.105, (0.62, 0.54, 0.4)),
			(0.06, (0.22, 0.17, 0.13)), (0.025, (0.5, 0.15, 0.08)))):
		kit.cylinder(r, 0.01, (0, -0.003 - k * 0.005, z), C(rgb, 0.85), rot=(90, 0, 0), verts=24, bevel=0.002)
	for k in range(8):  # spokes of thin copper wire
		a = math.pi * k / 4 + math.pi / 8
		log((math.cos(a) * 0.06, -0.009, z + math.sin(a) * 0.06), (math.cos(a) * 0.19, -0.006, z + math.sin(a) * 0.19),
			0.003, CU("dark"), seg=4, rings=1, ends=False, bend=0)
	for k in range(12):  # little score pegs round the rim
		a = 2 * math.pi * k / 12
		kit.cylinder(0.01, 0.015, (math.cos(a) * 0.2, -0.006, z + math.sin(a) * 0.2), kit.tex_mat("wood", "c"), rot=(90, 0, 0), verts=6, bevel=0.002)
	# hung from a peg above on a leather strap
	kit.cylinder(0.018, 0.08, (0, 0.04, z + 0.34), kit.tex_mat("wood", "c"), rot=(90, 0, 0), verts=8, bevel=0.004)
	for s_ in (-1, 1):
		log((s_ * 0.012, 0.02, z + 0.33), (s_ * 0.15, 0.02, z + 0.17), 0.008, kit.tex_mat("leather", "dark"), seg=5, rings=1, ends=False, bend=0)
		rivet((s_ * 0.15, 0.012, z + 0.17), CU("dark"), r=0.012)
	flights = [C((0.35, 0.45, 0.25), 0.9), C((0.6, 0.45, 0.2), 0.9), C((0.3, 0.35, 0.5), 0.9)]
	for k, (x, zz) in enumerate(((0.04, 0.06), (-0.08, -0.03), (0.11, -0.09))):
		p1 = (x + 0.02, -0.15, z + zz + 0.02)
		log((x, 0.01, z + zz), (x + 0.005, -0.04, z + zz + 0.005), 0.004, IRON(), seg=5, rings=1, ends=False, bend=0)
		log((x + 0.005, -0.04, z + zz + 0.005), p1, 0.008, T("wood", "b"), seg=6, rings=1, ends=False, bend=0)
		fy = p1[1] + 0.02
		B((0.003, 0.05, 0.035), (p1[0], fy, p1[2]), flights[k], bevel=0)
		B((0.035, 0.05, 0.003), (p1[0], fy, p1[2]), flights[k], bevel=0)


def stone_game_table():
	"""A small stone table with our own 5x5 ring-and-hole board and round carved stone pieces."""
	stone((0.6, 0.6, 0.1), (0, 0, 0.05), tone=T("stone", "b"), bevel=0.025)
	stone((0.34, 0.34, 0.52), (0, 0, 0.35), tone=T("stone", "a"), bevel=0.03)
	B((0.84, 0.84, 0.1), (0, 0, 0.65), T("stone", "c"), bevel=0.025)
	for x in (-0.42, 0.42):
		B((0.04, 0.6, 0.05), (x, 0, 0.64), CU(), bevel=0.006)
	ink = kit.mat("charcoal", 0.15)
	s, n = 0.13, 5
	ext = s * (n - 1)
	for i in range(n):
		c = -ext / 2 + i * s
		B((ext, 0.012, 0.005), (0, c, 0.7), ink, bevel=0)
		B((0.012, ext, 0.005), (c, 0, 0.7), ink, bevel=0)
	B((ext + 0.12, 0.02, 0.005), (0, -(ext + 0.1) / 2, 0.7), ink, bevel=0)
	B((ext + 0.12, 0.02, 0.005), (0, (ext + 0.1) / 2, 0.7), ink, bevel=0)
	pale, dark = T("limestone", "b"), T("basalt", "b")
	pieces = {(0, 0): pale, (1, 0): pale, (0, 1): pale, (3, 4): dark, (4, 4): dark, (4, 3): dark, (2, 2): pale, (2, 3): dark}
	for i in range(n):
		for j in range(n):
			x, y = -ext / 2 + i * s, -ext / 2 + j * s
			kit.ring(0.036, 0.006, (x, y, 0.704), ink, seg=14)
			kit.cylinder(0.018, 0.012, (x, y, 0.703), kit.mat("charcoal", -0.3), verts=10, bevel=0)
			if (i, j) in pieces:
				o = kit.cylinder(0.042, 0.035, (x, y, 0.725), pieces[(i, j)], verts=12, bevel=0.01)
				kit.roughen(o, 0.002, 1, seed=i * 5 + j)
				sphere((x, y, 0.741), 0.026, pieces[(i, j)], scale=(1, 1, 0.5), seg=10, rings=5, cut=0.0)


def drum_music_stand():
	"""A small hand drum with a hide top and rope lacing, in a three-leg stand, two sticks resting on it."""
	wood = T("wood", "b")
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		log((math.cos(a) * 0.26, math.sin(a) * 0.26, 0), (math.cos(a) * 0.17, math.sin(a) * 0.17, 0.62), 0.025, wood,
			seg=6, rings=2, bend=0.05)
	kit.ring(0.17, 0.022, (0, 0, 0.61), T("wood", "dark"), seg=18)
	kit.ring(0.225, 0.016, (0, 0, 0.22), T("wood", "dark"), seg=18)
	zb, h = 0.6, 0.24
	kit.cone(0.15, 0.18, h, (0, 0, zb + h / 2), T("wood", "c"), verts=18, bevel=0.01)
	kit.cylinder(0.186, 0.012, (0, 0, zb + h + 0.003), C((0.8, 0.7, 0.52), 0.9), verts=20, bevel=0.003)
	kit.ring(0.183, 0.012, (0, 0, zb + h - 0.01), kit.tex_mat("rope"), seg=20)
	kit.ring(0.152, 0.012, (0, 0, zb + 0.03), kit.tex_mat("rope"), seg=20)
	for k in range(10):  # zig-zag lacing
		a0 = 2 * math.pi * k / 10
		a1 = 2 * math.pi * (k + 0.5) / 10
		log((math.cos(a0) * 0.183, math.sin(a0) * 0.183, zb + h - 0.012), (math.cos(a1) * 0.155, math.sin(a1) * 0.155, zb + 0.03),
			0.005, kit.tex_mat("rope"), seg=4, rings=1, ends=False, bend=0)
	top = zb + h + 0.009
	for k, (a, x0) in enumerate(((20, -0.02), (-25, 0.03))):
		r = math.radians(a)
		p0 = (x0 - math.cos(r) * 0.16, -math.sin(r) * 0.16, top + 0.012)
		p1 = (x0 + math.cos(r) * 0.16, math.sin(r) * 0.16, top + 0.012 + k * 0.022)
		log(p0, p1, 0.012, T("wood", "a"), seg=6, rings=1, ends=False, bend=0)
		sphere(p1, 0.02, C((0.75, 0.68, 0.52), 0.9), seg=8, rings=5)


def crystal_globe():
	"""A glass globe on a turned base (owner Nov 21: more detail): copper claw feet, brass meridian ring, finial
	crystal, inside a rock with a crystal cluster and pebbles."""
	for k in range(3):  # copper ball feet tucked under the base
		a = 2 * math.pi * k / 3 + 0.5
		sphere((math.cos(a) * 0.13, math.sin(a) * 0.13, 0.02), 0.03, CU("dark"), scale=(1, 1, 0.7), seg=8, rings=5)
	kit.cylinder(0.18, 0.03, (0, 0, 0.04), T("wood", "dark"), verts=18, bevel=0.008)
	kit.cone(0.17, 0.155, 0.07, (0, 0, 0.09), T("wood", "b"), verts=18, bevel=0.012)
	kit.ring(0.16, 0.012, (0, 0, 0.125), CU(), seg=20)
	kit.ring(0.172, 0.01, (0, 0, 0.06), CU(), seg=20)
	for k in range(6):
		a = 2 * math.pi * k / 6
		rivet((math.cos(a) * 0.165, math.sin(a) * 0.165, 0.093), CU("dark"), r=0.009)
	kit.cylinder(0.14, 0.02, (0, 0, 0.13), T("wood", "dark"), verts=18, bevel=0.004)
	zc, R = 0.138, 0.135  # the glass dome sits on the base top
	lump((0, 0, 0.16), (0.08, 0.07, 0.04), T("stone", "b"), seed=4, rough=0.006)
	for k in range(5):
		a = k * 1.25
		lump((math.cos(a) * 0.09, math.sin(a) * 0.09, 0.148), (0.018, 0.015, 0.01), T("stone", "abc"[k % 3]), seed=k + 7, rough=0.002)
	kit.crystal_cluster((0, 0, 0.17), 0.42, C((0.3, 0.65, 0.95), 0.2, glow=1.0), seed=5, n=5)
	kit.gem((0.05, 0.03, 0.175), (0.02, 0.02, 0.02), C((0.6, 0.4, 0.9), 0.2, glow=1.0), seed=2)
	top = zc + R * 1.25
	sphere((0, 0, zc), R, glass((0.75, 0.88, 0.95), 0.22, glow=0.05), scale=(1, 1, 1.25), seg=20, rings=12, cut=0.0)
	kit.ring(R + 0.012, 0.008, (0, 0, zc + 0.002), CU(), seg=24)
	pts = [(math.cos(math.pi * t / 12) * (R + 0.012), 0, zc + math.sin(math.pi * t / 12) * (R * 1.25 + 0.012)) for t in range(13)]
	for p, q in zip(pts, pts[1:]):  # brass meridian arch over the dome
		log(p, q, 0.007, CU("a"), seg=6, rings=1, ends=False, bend=0)
	kit.cylinder(0.03, 0.025, (0, 0, top), CU(), verts=8, bevel=0.004)
	kit.cylinder(0.02, 0.02, (0, 0, top + 0.02), CU("dark"), verts=8, bevel=0.003)
	sphere((0, 0, top + 0.035), 0.018, CU("a"), seg=10, rings=6)


def wind_chime():
	"""Crystal shards in copper caps on beaded strings from a carved wooden disc, a striker and a wooden sail
	(owner Nov 21: more detail); hangs from a ceiling plate with an iron hook."""
	zp = 0.8
	kit.cylinder(0.08, 0.03, (0, 0, zp + 0.015), T("wood", "dark"), verts=12, bevel=0.008)
	for k in range(3):
		a = 2 * math.pi * k / 3
		rivet((math.cos(a) * 0.055, math.sin(a) * 0.055, zp - 0.001), IRON(), r=0.01)
	log((0, 0, zp), (0, 0, zp - 0.03), 0.006, IRON(), seg=5, rings=1, ends=False, bend=0)
	kit.ring(0.022, 0.006, (0, 0, zp - 0.045), IRON(), rot=(90, 0, 0), seg=10)
	twine = kit.tex_mat("rope")
	zr = 0.6
	kit.cylinder(0.16, 0.035, (0, 0, zr), T("wood", "b"), verts=24, bevel=0.01)  # top disc
	kit.ring(0.16, 0.01, (0, 0, zr), CU(), seg=24)
	for k in range(12):  # notches cut round the disc edge (dark sunk slits)
		a = 2 * math.pi * (k + 0.5) / 12
		B((0.01, 0.012, 0.02), (math.cos(a) * 0.162, math.sin(a) * 0.162, zr + 0.012), kit.mat("charcoal", 0.3), bevel=0, rot=(0, 0, math.degrees(a)))
	kit.cylinder(0.035, 0.02, (0, 0, zr + 0.027), T("wood", "c"), verts=10, bevel=0.004)
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.12, math.sin(a) * 0.12, zr + 0.017), (0, 0, zp - 0.06), 0.004, twine, seg=4, rings=1, ends=False, bend=0)
	cols = [C((0.5, 0.75, 0.95), 0.2, glow=0.8), C((0.7, 0.55, 0.95), 0.2, glow=0.8), C((0.55, 0.9, 0.8), 0.2, glow=0.8)]
	bead = kit.tex_mat("wood", "c")
	for k in range(6):
		a = 2 * math.pi * k / 6
		x, y = math.cos(a) * 0.125, math.sin(a) * 0.125
		zs = zr - 0.12 - (k % 3) * 0.05
		log((x, y, zr - 0.017), (x, y, zs + 0.03), 0.003, twine, seg=4, rings=1, ends=False, bend=0)
		sphere((x, y, (zr + zs) / 2), 0.012, bead, seg=8, rings=5)
		kit.cone(0.026, 0.012, 0.03, (x, y, zs + 0.015), CU(), verts=8, bevel=0.003)  # copper cap holding the crystal
		kit.ring(0.026, 0.005, (x, y, zs + 0.002), CU("dark"), seg=10)
		kit.crystal((x, y, zs + 0.01), 0.018, 0.15 + (k % 2) * 0.04, cols[k % 3], tilt=(180, 0, k * 20))
	# striker disc and wind sail on the middle string
	zs = zr - 0.2
	log((0, 0, zr - 0.017), (0, 0, 0.12), 0.003, twine, seg=4, rings=1, ends=False, bend=0)
	kit.cylinder(0.05, 0.02, (0, 0, zs), T("wood", "b"), verts=12, bevel=0.004)
	kit.ring(0.05, 0.006, (0, 0, zs), CU(), seg=14)
	for z in (zs + 0.05, zs - 0.05):
		sphere((0, 0, z), 0.012, bead, seg=8, rings=5)
	B((0.11, 0.015, 0.14), (0, 0, 0.06), T("wood", "b"), bevel=0.01)
	kit.ring(0.012, 0.004, (0, 0, 0.13), IRON(), rot=(90, 0, 0), seg=8)
	kit.gem((0, -0.009, 0.06), (0.02, 0.006, 0.03), cols[0], seed=3)


# ================= floor mosaics =================
def mosaic(colour_at, seed):
	"""A 2x2 m floor panel: dark grout slab under ~780 small irregular stones with 1 cm gaps."""
	B((1.99, 1.99, 0.025), (0, 0, 0.0125), kit.mat("charcoal", 0.05), bevel=0.004)
	n, half = 28, 0.99
	step = 2 * half / n
	pts = [[(-half + i * step + (J(step * 0.28) if 0 < i < n else 0), -half + j * step + (J(step * 0.28) if 0 < j < n else 0))
		for j in range(n + 1)] for i in range(n + 1)]
	groups = {}
	for i in range(n):
		for j in range(n):
			q = [pts[i][j], pts[i + 1][j], pts[i + 1][j + 1], pts[i][j + 1]]
			cx, cy = sum(p[0] for p in q) / 4, sum(p[1] for p in q) / 4
			dmin = min(abs((b[0] - a[0]) * (a[1] - cy) - (a[0] - cx) * (b[1] - a[1])) / math.hypot(b[0] - a[0], b[1] - a[1])
				for a, b in zip(q, q[1:] + q[:1]))
			s0 = 1 - 0.0055 / dmin  # every edge moves in >= 5.5 mm: >= 1.1 cm gap to the neighbour
			s1 = 1 - 0.0115 / dmin  # chamfered top: a worn, hand-cut edge
			ztop = 0.038 + rng.uniform(-0.003, 0.003)
			v = [(cx + (x - cx) * s0, cy + (y - cy) * s0, 0.02) for x, y in q]
			v += [(cx + (x - cx) * s0, cy + (y - cy) * s0, ztop - 0.005) for x, y in q]
			v += [(cx + (x - cx) * s1, cy + (y - cy) * s1, ztop + J(0.0015)) for x, y in q]
			g = groups.setdefault(colour_at(cx, cy), ([], []))
			o = len(g[0])
			g[0].extend(v)
			g[1].extend([(o + 3, o + 2, o + 1, o), (o + 8, o + 9, o + 10, o + 11)])
			for a in range(4):
				b = (a + 1) % 4
				g[1].append((o + a, o + b, o + 4 + b, o + 4 + a))
				g[1].append((o + 4 + a, o + 4 + b, o + 8 + b, o + 8 + a))
	for rgb, (verts, faces) in groups.items():
		mesh(verts, faces, C(rgb, 0.8))


def _pick(shades):
	return shades[rng.randrange(len(shades))]


def mosaic_a():
	"""Warm sun: golden centre, twelve rays, a red-brown ring, ochre border."""
	gold = ((0.78, 0.58, 0.22), (0.72, 0.52, 0.18), (0.82, 0.64, 0.3))
	amber = ((0.72, 0.4, 0.15), (0.66, 0.36, 0.13))
	rust = ((0.5, 0.22, 0.12), (0.45, 0.2, 0.11), (0.55, 0.26, 0.14))
	sand = ((0.62, 0.52, 0.38), (0.57, 0.48, 0.35), (0.66, 0.56, 0.42))
	brown = ((0.38, 0.27, 0.18), (0.34, 0.24, 0.16))
	ochre = ((0.7, 0.55, 0.3), (0.65, 0.5, 0.27))

	def colour(x, y):
		r, a = math.hypot(x, y), math.atan2(y, x)
		if r < 0.24:
			return _pick(gold)
		if r < 0.62 and math.cos(12 * a) > 0.25 + (r - 0.24) * 1.2:
			return _pick(amber)
		if 0.66 < r < 0.78:
			return _pick(rust)
		if max(abs(x), abs(y)) > 0.86:
			return _pick(ochre)
		if r > 0.92:
			return _pick(brown)
		return _pick(sand)
	mosaic(colour, 1)


def mosaic_b():
	"""Grey-blue floor with two crossed pickaxes inside a ring."""
	bg = ((0.3, 0.33, 0.38), (0.27, 0.3, 0.35), (0.33, 0.36, 0.4))
	blue = ((0.18, 0.26, 0.4), (0.2, 0.29, 0.44), (0.16, 0.23, 0.36))
	pale = ((0.78, 0.8, 0.8), (0.72, 0.74, 0.76))
	handle = ((0.58, 0.5, 0.4), (0.53, 0.46, 0.37))
	dark = ((0.2, 0.22, 0.26), (0.18, 0.2, 0.24))

	def seg_d(x, y, a, b):
		dx, dy = b[0] - a[0], b[1] - a[1]
		t = max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / (dx * dx + dy * dy)))
		return math.hypot(x - a[0] - t * dx, y - a[1] - t * dy), t

	def colour(x, y):
		for s in (1, -1):
			d, t = seg_d(x, y, (-0.55 * s, -0.55), (0.5 * s, 0.5))
			if d < 0.07:
				return _pick(handle)
			# the head: a curved, pointed blade across the handle's top end
			d, t = seg_d(x, y, (0.2 * s, 0.8), (0.8 * s, 0.2))
			bow = 0.08 * (1 - (2 * t - 1) ** 2)
			d2, t2 = seg_d(x - s * bow * 0.7, y - bow * 0.7, (0.2 * s, 0.8), (0.8 * s, 0.2))
			if d2 < 0.11 * (1 - abs(2 * t2 - 1) * 0.75):
				return _pick(pale)
		r = math.hypot(x, y)
		if 0.9 < r < 0.98 or max(abs(x), abs(y)) > 0.92:
			return _pick(dark if max(abs(x), abs(y)) > 0.92 else blue)
		return _pick(bg)
	mosaic(colour, 2)


MODELS = {
	"root_bonsai": root_bonsai, "mushroom_shelf_garden": mushroom_shelf_garden, "dartboard": dartboard,
	"stone_game_table": stone_game_table, "drum_music_stand": drum_music_stand,
	"crystal_globe": crystal_globe, "wind_chime": wind_chime,
	"mosaic_a": mosaic_a, "mosaic_b": mosaic_b,
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
