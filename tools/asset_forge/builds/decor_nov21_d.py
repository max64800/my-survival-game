# Decor batch Nov 21 (group d): a root-wrapped column, a faded banner and home trophies.
#   blender --background --factory-startup --python builds/decor_nov21_d.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on a short floor post (like night_decor's wall trophies).
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, plank, rivet, rng, stone  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import plank_board, stone_blocks, wall_post  # noqa: E402

CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
GOLD = lambda: C((0.88, 0.64, 0.22), 0.3, metal=0.85)  # noqa: E731
BONE = lambda: kit.mat("bone", rng.uniform(-0.12, 0.02))  # noqa: E731


# ---------------- helpers ----------------
def tube(pts, r0, r1, m, seg=7):
	"""A bendy tube along points, tapering r0 -> r1 (roots, cords, braided hair)."""
	pts = [Vector(p) for p in pts]
	n = len(pts)
	verts = []
	for i, p in enumerate(pts):
		d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
		up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
		u = d.cross(up).normalized()
		v = d.cross(u)
		r = r0 + (r1 - r0) * i / (n - 1)
		for k in range(seg):
			a = 2 * math.pi * k / seg
			rr = r * (1 + J(0.1))
			verts.append(tuple(p + u * math.cos(a) * rr + v * math.sin(a) * rr))
	faces = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	faces += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	return mesh(verts, faces, m, smooth=True)


def root(pts, r0=0.035, r1=0.012):
	return tube(pts, r0 * 1.3, r1 * 1.3, T("bark", "dark"))


def slab(pts, y0, y1, m, ang=0.0, c=(0.0, 0.0)):
	"""A flat shape drawn in the wall plane (x, z), y0 = front, y1 = back; turned `ang` degrees around c."""
	ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
	p = [(c[0] + x * ca - z * sa, c[1] + x * sa + z * ca) for x, z in pts]
	n = len(p)
	v = [(x, y0, z) for x, z in p] + [(x, y1, z) for x, z in p]
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def rot2(x, z, ang, c):
	ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
	return c[0] + x * ca - z * sa, c[1] + x * sa + z * ca


def glass():
	m = bpy.data.materials.new("glass")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (0.75, 0.9, 0.95, 1)
	b.inputs["Roughness"].default_value = 0.05
	b.inputs["Alpha"].default_value = 0.1
	for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
		try:
			setattr(m, attr, val)
		except (AttributeError, TypeError):
			pass
	return m


# ================= Ruins =================
def column_rootwrapped():
	"""A stone column on a plinth gripped by old roots: three thick roots come over the capital and spiral down,
	split into side roots that hug the drums, run over the plinth edge and thin out across the floor. No moss."""
	stone((0.62, 0.62, 0.16), (0, 0, 0.08), tone=T("greystone", "b"), bevel=0.025)
	z = 0.15
	for i in range(5):
		h = 0.34
		kit.cylinder(0.22 + J(0.012), h - 0.004, (J(0.01), J(0.01), z + h / 2), T("greystone"), verts=10, bevel=0.02).rotation_euler = (0, 0, J(0.3))
		z += h
	stone((0.56, 0.56, 0.16), (0, 0, z + 0.07), tone=T("greystone", "c"), bevel=0.025)
	top = z + 0.15

	def hug(a, zz, rr):
		return (math.cos(a) * rr, math.sin(a) * rr, zz)

	def floor_tip(p, a, ln, r):
		"""A thin root running out across the floor from p, curling a little."""
		pts = [p]
		for t in (0.35, 0.7, 1.0):
			b = a + 0.25 * math.sin(t * 3 + a)
			rr = math.hypot(p[0], p[1]) + ln * t
			pts.append((math.cos(b) * rr, math.sin(b) * rr, r * (1.3 - 0.8 * t) + 0.004))
		root(pts, r, r * 0.3)

	for k in range(3):
		a0 = 2 * math.pi * k / 3
		dirn = 1 if k % 2 else -1
		rr = 0.245 + 0.01 * k
		pts = [hug(a0, top + 0.02, 0.05), hug(a0, top - 0.005, 0.27), hug(a0, top - 0.13, 0.31)]
		n = 14
		spiral = []
		for i in range(n + 1):
			t = i / n
			a = a0 + t * 2.6 * dirn
			spiral.append((a, (top - 0.22) - t * (top - 0.22 - 0.26)))
		pts += [hug(a, zz, rr) for a, zz in spiral]
		a_end = spiral[-1][0]
		pts += [hug(a_end, 0.19, 0.33), hug(a_end + 0.05 * dirn, 0.1, 0.38), hug(a_end + 0.1 * dirn, 0.045, 0.47)]
		root(pts, 0.05, 0.022)
		for j in (3, 7, 11):  # side roots splitting off and hugging the drums the other way round
			a, zz = spiral[j]
			side = [hug(a, zz, rr)] + [hug(a - dirn * 0.35 * s, zz - 0.11 * s, 0.236 - 0.004 * s) for s in (1, 2, 3, 4)]
			root(side, 0.022, 0.008)
		e = hug(a_end + 0.1 * dirn, 0.035, 0.47)
		for f in (-0.3, 0.35):  # the end splits into two tips on the floor
			floor_tip(e, a_end + 0.1 * dirn + f, 0.14, 0.018)
	for k in range(3):  # thinner roots straight down between the big ones
		a = 2 * math.pi * k / 3 + math.pi / 3
		pts = [hug(a, top - 0.02, 0.29), hug(a, top - 0.15, 0.3)]
		for i in range(1, 8):
			pts.append(hug(a + 0.12 * math.sin(i * 1.7 + k), top - 0.15 - i * (top - 0.45) / 8, 0.234))
		pts += [hug(a, 0.2, 0.32), hug(a + 0.06, 0.06, 0.38)]
		root(pts, 0.026, 0.012)
		floor_tip(hug(a + 0.06, 0.03, 0.38), a + 0.1, 0.12, 0.016)


def banner_torn_faded():
	wall_post(1.6)
	log((-0.4, 0.0, 1.5), (0.4, 0.0, 1.5), 0.025, T("wood", "b"), seg=6, rings=1)
	cloth = C((0.46, 0.28, 0.24), 0.95)
	w, h, n, rows = 0.66, 0.95, 12, 6
	tear = [rng.uniform(0.0, 0.28) * (1 if i % 3 else 0.4) for i in range(n + 1)]
	verts = []
	for j in range(rows + 1):
		for i in range(n + 1):
			x = -w / 2 + w * i / n
			zz = 1.49 - h * j / rows
			if j == rows:
				zz += tear[i]
			elif j == rows - 1:
				zz += tear[i] * 0.35
			verts.append((x, -0.01 - 0.005 * math.sin(i * 1.7 + j), zz))
	faces = [(j * (n + 1) + i, j * (n + 1) + i + 1, (j + 1) * (n + 1) + i + 1, (j + 1) * (n + 1) + i) for j in range(rows) for i in range(n)]
	o = mesh(verts, faces, cloth)
	sol = o.modifiers.new("t", "SOLIDIFY")
	sol.thickness, sol.offset = 0.012, 0.0
	B((w, 0.046, 0.012), (0, 0.027, 1.494), cloth, bevel=0.002)
	B((w - 0.02, 0.016, 0.1), (0, -0.037, 1.38), C((0.62, 0.52, 0.34), 0.95), bevel=0.004)  # faded gold stripe
	pale = C((0.68, 0.62, 0.5), 0.95)
	slab([(-0.025, -0.16), (0.025, -0.16), (0.025, 0.08), (-0.025, 0.08)], -0.045, -0.03, pale, ang=-20, c=(0, 1.1))
	slab([(-0.1, 0.06), (0.1, 0.06), (0.11, 0.15), (-0.1, 0.15)], -0.05, -0.034, pale, ang=-20, c=(0, 1.1))
	for i in range(1, n, 2):  # loose threads at the torn bottom
		x = -w / 2 + w * i / n
		zb = 1.49 - h + tear[i]
		log((x, -0.012, zb + 0.01), (x + J(0.015), -0.014, zb - 0.06), 0.004, cloth, seg=4, rings=1, ends=False, bend=0)


# ================= Home trophies =================
def gem_stand():
	stone((0.32, 0.32, 0.08), (0, 0, 0.04), tone=T("stone", "c"), bevel=0.02)
	kit.taper(0.2, 0.2, 0.13, 0.13, 0.5, (0, 0, 0.075), T("stone", "b"), bevel=0.015)
	for z in (0.15, 0.5):
		kit.ring(0.09 if z > 0.3 else 0.105, 0.012, (0, 0, z), T("stone", "c"), seg=4).rotation_euler = (0, 0, math.radians(45))
	stone((0.22, 0.22, 0.06), (0, 0, 0.6), tone=T("stone", "c"), bevel=0.015)
	kit.cylinder(0.1, 0.04, (0, 0, 0.645), CU(), verts=12, bevel=0.008)
	gem_c = (0, 0, 0.73)
	lump(gem_c, (0.065, 0.055, 0.08), C((0.45, 0.12, 0.7), 0.25, glow=0.35), seed=7, rough=0.01)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		log((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.66), (math.cos(a) * 0.05, math.sin(a) * 0.045, 0.75), 0.011, CU(), seg=5, rings=1, ends=False, bend=0)


def gem_case():
	W, D, Z = 0.7, 0.45, 0.68
	for x in (-W / 2 + 0.04, W / 2 - 0.04):
		for y in (-D / 2 + 0.04, D / 2 - 0.04):
			B((0.06, 0.06, Z), (x, y, Z / 2), T("wood", "dark"), bevel=0.01)
		B((0.04, D - 0.1, 0.04), (x, 0, 0.18), T("wood", "dark"), bevel=0.006)
	B((W, D, 0.04), (0, 0, Z + 0.02), T("wood", "b"), bevel=0.01)
	for s_ in (-1, 1):
		B((W, 0.04, 0.13), (0, s_ * (D / 2 - 0.02), Z + 0.105), T("wood", "b"), bevel=0.008)
		B((0.04, D - 0.08, 0.13), (s_ * (W / 2 - 0.02), 0, Z + 0.105), T("wood", "b"), bevel=0.008)
	B((W - 0.08, D - 0.08, 0.075), (0, 0, Z + 0.0725), C((0.4, 0.1, 0.12), 0.95), bevel=0.012)  # velvet bed
	vz = Z + 0.11
	gems = {0: (0.3, 0.6, 0.95), 2: (0.85, 0.2, 0.15), 4: (0.25, 0.75, 0.35)}
	for i in range(6):
		x, y = -0.2 + (i % 3) * 0.2, -0.08 + (i // 3) * 0.16
		kit.ring(0.055, 0.012, (x, y, vz), C((0.28, 0.06, 0.08), 0.95), seg=14)
		if i in gems:
			lump((x, y, vz + 0.02), (0.045, 0.04, 0.035), C(gems[i], 0.2, glow=0.35), seed=i + 3, rough=0.006)
	top = Z + 0.17
	for s_ in (-1, 1):
		B((W + 0.02, 0.05, 0.03), (0, s_ * (D / 2 - 0.01), top + 0.015), T("wood", "dark"), bevel=0.006)
		B((0.05, D - 0.08, 0.03), (s_ * (W / 2 - 0.01), 0, top + 0.015), T("wood", "dark"), bevel=0.006)
	B((W - 0.06, D - 0.06, 0.008), (0, 0, top + 0.012), glass(), bevel=0)
	for (cx, cy) in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
		B((0.06, 0.06, 0.04), (cx * (W / 2 - 0.01), cy * (D / 2 - 0.01), top + 0.015), CU(), bevel=0.006)
	B((0.07, 0.03, 0.08), (0, -D / 2 - 0.005, top - 0.03), CU(), bevel=0.006)


def ore_sample_shelf():
	wall_post(1.0)
	B((1.05, 0.05, 0.4), (0, 0.035, 1.15), T("wood", "b"), bevel=0.012)
	plank((1.05, 0.22, 0.04), (0, -0.1, 1.0))
	for x in (-0.4, 0.4):
		B((0.04, 0.16, 0.12), (x, -0.07, 0.92), T("wood", "dark"), bevel=0.008)
	z0 = 1.02
	ores = (("copper", CU("b")), ("iron", C((0.5, 0.26, 0.14), 0.8)), ("coal", None), ("silver", kit.tex_mat("silver", "a")),
		("gold", GOLD()), ("crystal", None))
	for i, (name, m) in enumerate(ores):
		x = -0.42 + i * 0.168
		if name == "coal":
			lump((x, -0.1, z0 + 0.05), (0.07, 0.06, 0.055), kit.mat("charcoal", 0.3), seed=i + 1, rough=0.01)
		elif name == "crystal":
			lump((x, -0.1, z0 + 0.025), (0.06, 0.05, 0.035), T("stone", "c"), seed=i + 1, rough=0.006)
			kit.crystal_cluster((x, -0.1, z0 + 0.04), 0.5, C((0.4, 0.75, 1.0), 0.15, glow=0.6), seed=i)
		else:
			lump((x, -0.1, z0 + 0.045), (0.07, 0.06, 0.05), T("stone", "b" if i % 2 else "c"), seed=i + 1, rough=0.008)
			for k in range(3):
				a = k * 2.1 + i
				kit.gem((x + math.cos(a) * 0.04, -0.1 + math.sin(a) * 0.035, z0 + 0.06 + 0.01 * k), (0.025, 0.022, 0.02), m, seed=k + i * 3)
		B((0.11, 0.01, 0.035), (x, -0.215, 1.0), C((0.85, 0.78, 0.6), 0.95), bevel=0.002)
		B((0.07, 0.006, 0.006), (x, -0.221, 1.004), C((0.3, 0.2, 0.12), 0.9), bevel=0)
	for x in (-0.48, 0.48):
		rivet((x, 0.008, 1.3), CU("dark"))


def tooth_necklace():
	wall_post(1.0)
	plank_board(0.5, 0.6, 1.25)
	log((0, 0.0, 1.43), (0, -0.12, 1.46), 0.022, T("wood", "c"), seg=6, rings=1)
	pts = [(0, 1.44), (0.08, 1.38), (0.15, 1.28), (0.17, 1.18), (0.14, 1.1), (0.07, 1.05), (0, 1.04), (-0.07, 1.05),
		(-0.14, 1.1), (-0.17, 1.18), (-0.15, 1.28), (-0.08, 1.38), (0, 1.44)]
	yy = lambda z: -0.016 - (z - 1.04) / 0.4 * 0.085  # noqa: E731
	cord = [(x, yy(z), z) for x, z in pts]
	tube(cord, 0.009, 0.009, kit.tex_mat("leather", "dark"), seg=6)
	for i, (x, z) in enumerate(pts):
		if z > 1.2 or i in (0, len(pts) - 1):
			continue
		big = i == 6
		d = Vector((x * 0.5, 0, z - 1.25)).normalized()
		ln = 0.17 if big else 0.08 + 0.02 * (i % 2)
		p0 = Vector((x, yy(z), z))
		log(tuple(p0), tuple(p0 + d * ln), 0.028 if big else 0.016, BONE(), seg=7, rings=2, ends=False, bend=0.05, r1=0.003)
	for (x, z) in ((0.115, 1.33), (-0.115, 1.33), (0.165, 1.23), (-0.165, 1.23)):
		sphere((x, yy(z), z), 0.016, CU("b"))


def bat_wing_trophy():
	wall_post(1.0)
	plank_board(1.1, 0.55, 1.3)
	mem = C((0.24, 0.17, 0.16), 0.85)
	bone_m = C((0.36, 0.27, 0.22), 0.8)
	for s_ in (-1, 1):
		P = lambda x, z: (s_ * x, z)  # noqa: E731
		shape = [P(0.05, 1.36), P(0.3, 1.46), P(0.5, 1.5), P(0.44, 1.37), P(0.48, 1.29), P(0.38, 1.24), P(0.38, 1.13), P(0.22, 1.17), P(0.05, 1.22)]
		slab(shape, -0.028, -0.018, mem)
		wrist = (s_ * 0.3, -0.032, 1.46)
		log((s_ * 0.05, -0.032, 1.36), wrist, 0.014, bone_m, seg=6, rings=2, ends=False, bend=0.02)
		for tip in ((0.5, 1.5), (0.48, 1.29), (0.38, 1.13)):
			log(wrist, (s_ * tip[0], -0.032, tip[1]), 0.009, bone_m, seg=5, rings=2, ends=False, bend=0.03, r1=0.005)
			rivet((s_ * tip[0], -0.035, tip[1]), CU("dark"))
		kit.cone(0.02, 0.0, 0.05, (s_ * 0.31, -0.035, 1.49), bone_m, verts=5, bevel=0)
	sphere((0, -0.05, 1.29), 0.075, C((0.3, 0.22, 0.18), 0.95), scale=(1, 0.7, 1.25))
	sphere((0, -0.07, 1.4), 0.055, C((0.4, 0.3, 0.26), 0.95), scale=(1.1, 0.9, 0.9))
	for s_ in (-1, 1):
		kit.cone(0.025, 0.004, 0.08, (s_ * 0.035, -0.07, 1.47), C((0.4, 0.3, 0.26), 0.95), rot=(0, s_ * 20, 0), verts=5, bevel=0)
		sphere((s_ * 0.022, -0.115, 1.41), 0.009, C((0.85, 0.55, 0.2), 0.3, glow=0.3))
		kit.cone(0.006, 0.0, 0.02, (s_ * 0.012, -0.11, 1.37), BONE(), rot=(180, 0, 0), verts=4, bevel=0)


def sword(ang, y0, c=(0, 1.25)):
	y1 = y0 + 0.035
	slab([(-0.03, -0.18), (0.03, -0.18), (0.028, 0.3), (0, 0.4), (-0.028, 0.3)], y0, y1, IRON("a"), ang, c)
	slab([(-0.006, -0.16), (0.006, -0.16), (0.006, 0.28), (-0.006, 0.28)], y0 - 0.004, y0 + 0.004, IRON("dark"), ang, c)
	slab([(-0.11, -0.21), (-0.1, -0.18), (0.1, -0.18), (0.11, -0.21), (0.09, -0.22), (-0.09, -0.22)], y0 - 0.01, y1 + 0.01, CU(), ang, c)
	slab([(-0.018, -0.34), (0.018, -0.34), (0.018, -0.215), (-0.018, -0.215)], y0 + 0.003, y1 - 0.003, kit.tex_mat("leather", "dark"), ang, c)
	px, pz = rot2(0, -0.36, ang, c)
	sphere((px, (y0 + y1) / 2, pz), 0.032, CU())


def crossed_swords():
	wall_post(1.0)
	plank_board(0.64, 0.64, 1.3, round_=True)
	sword(38, -0.04)
	sword(-38, -0.068)


def crossed_axes():
	wall_post(1.0)
	shield = [(-0.31, 1.62), (0.0, 1.66), (0.31, 1.62), (0.29, 1.25), (0.17, 1.03), (0.0, 0.92), (-0.17, 1.03), (-0.29, 1.25)]
	slab(shield, 0.005, 0.06, CU("dark"))
	inner = [(x * 0.88, 1.29 + (z - 1.29) * 0.9) for x, z in shield]
	slab(inner, -0.015, 0.045, T("wood", "b"))
	for x, z in inner:
		rivet((x * 0.97, -0.006, 1.29 + (z - 1.29) * 0.97 + 0.0), CU("dark"))
	c = (0, 1.28)
	for s_, y0 in ((1, -0.05), (-1, -0.08)):
		ang = -s_ * 35
		slab([(-0.018, -0.36), (0.018, -0.36), (0.016, 0.36), (-0.016, 0.36)], y0, y0 + 0.03, T("wood", "c"), ang, c)
		head = [(s_ * x, z) for x, z in ((0.0, 0.17), (0.07, 0.19), (0.14, 0.13), (0.18, 0.24), (0.16, 0.36), (0.07, 0.32), (0.0, 0.34))]
		slab(head, y0 - 0.006, y0 + 0.036, IRON("a"), ang, c)
		hx, hz = rot2(s_ * 0.17, 0.24, ang, c)
		slab([(s_ * x, z) for x, z in ((0.155, 0.15), (0.185, 0.24), (0.165, 0.35), (0.15, 0.33), (0.165, 0.24), (0.14, 0.16))], y0 - 0.012, y0 - 0.004, IRON("dark"), ang, c)
		for z in (-0.3, -0.24):
			slab([(-0.022, z - 0.015), (0.022, z - 0.015), (0.022, z + 0.015), (-0.022, z + 0.015)], y0 - 0.005, y0 + 0.035, kit.tex_mat("leather", "dark"), ang, c)


def medal_board():
	wall_post(1.1)  # the post reaches up into the board (it stopped 5 cm short)
	plank_board(0.8, 0.5, 1.3)
	B((0.7, 0.03, 0.03), (0, -0.02, 1.49), T("wood", "dark"), bevel=0.006)
	ribbons = ((0.55, 0.2, 0.18), (0.28, 0.34, 0.5), (0.3, 0.42, 0.25), (0.62, 0.5, 0.25))
	metals = (GOLD(), kit.tex_mat("silver", "a"), CU("b"), IRON("a"))
	for i, x in enumerate((-0.27, -0.09, 0.09, 0.27)):
		ln = 0.16 + 0.03 * (i % 2)
		slab([(x - 0.035, 1.5), (x + 0.035, 1.5), (x + 0.035, 1.5 - ln), (x, 1.5 - ln + 0.025), (x - 0.035, 1.5 - ln)], -0.03, -0.018, C(ribbons[i], 0.95))
		slab([(x - 0.01, 1.49), (x + 0.01, 1.49), (x + 0.01, 1.5 - ln + 0.02), (x - 0.01, 1.5 - ln + 0.02)], -0.036, -0.026, C((0.8, 0.75, 0.6), 0.95))
		mz = 1.5 - ln - 0.035
		kit.cylinder(0.055, 0.014, (x, -0.03, mz), metals[i], rot=(90, 0, 0), verts=14, bevel=0.004)
		kit.ring(0.05, 0.007, (x, -0.037, mz), metals[i], rot=(90, 0, 0), seg=14)
		star = [(math.cos(math.pi / 2 + k * math.pi / 5) * (0.028 if k % 2 == 0 else 0.012), math.sin(math.pi / 2 + k * math.pi / 5) * (0.028 if k % 2 == 0 else 0.012)) for k in range(10)]
		slab([(x + a, mz + b) for a, b in star], -0.044, -0.034, metals[i])
		rivet((x, -0.04, 1.49), CU("dark"))


def golden_pickaxe():
	stone_blocks(0.5, 0.4, 0.45)
	stone((0.6, 0.5, 0.08), (0, 0, 0.49), tone=T("stone", "c"), bevel=0.02)
	kit.cylinder(0.07, 0.06, (0, 0, 0.55), CU("b"), verts=10, bevel=0.01)
	log((0, 0, 0.52), (0.01, 0, 1.2), 0.03, T("wood", "dark"), seg=8, rings=3, bend=0.02)
	for z in (0.62, 0.68, 1.05):
		kit.ring(0.033, 0.008, (0.005, 0, z), GOLD(), seg=10)
	hz = 1.2
	B((0.08, 0.07, 0.09), (0.01, 0, hz), GOLD(), bevel=0.012)
	for s_ in (-1, 1):
		tube([(0.01, 0, hz), (s_ * 0.14, 0, hz + 0.015), (s_ * 0.26, 0, hz - 0.02), (s_ * 0.34, 0, hz - 0.09)], 0.036, 0.008, GOLD(), seg=8)
	B((0.2, 0.012, 0.07), (0, -0.255, 0.49), GOLD(), bevel=0.004)


def first_coin_frame():
	"""A small wooden frame on a wall post, a red velvet back and the first gold coin ever earned: raised rim and a
	stamped hammer, a little brass plate under it."""
	wall_post(1.05)
	z, s = 1.17, 0.3
	B((s - 0.06, 0.03, s - 0.06), (0, 0.035, z), C((0.3, 0.1, 0.1), 0.95), bevel=0.004)
	for (w, h, x, zz) in ((s, 0.05, 0, z + s / 2 - 0.025), (s, 0.05, 0, z - s / 2 + 0.025), (0.05, s - 0.1, -s / 2 + 0.025, z), (0.05, s - 0.1, s / 2 - 0.025, z)):
		B((w, 0.05, h), (x, 0.025, zz), T("wood", "b"), bevel=0.008)
	gold, gold_dk = GOLD(), C((0.55, 0.38, 0.1), 0.35, metal=0.85)
	cz = z + 0.02
	kit.cylinder(0.065, 0.012, (0, 0.013, cz), gold, rot=(90, 0, 0), verts=20, bevel=0.003)  # the coin, just off the velvet
	kit.ring(0.06, 0.005, (0, 0.006, cz), gold, rot=(90, 0, 0), seg=20)  # raised rim
	slab([(-0.008, -0.03), (0.008, -0.03), (0.008, 0.012), (-0.008, 0.012)], 0.002, 0.008, gold_dk, c=(0, cz))  # stamped hammer: handle
	slab([(-0.03, 0.012), (0.03, 0.012), (0.03, 0.032), (-0.03, 0.032)], 0.002, 0.008, gold_dk, c=(0, cz))  # and head
	for k in range(12):  # little dots round the edge, like an old stamped coin
		a = 2 * math.pi * k / 12
		kit.rivet((math.cos(a) * 0.047, 0.005, cz + math.sin(a) * 0.047), gold_dk, r=0.004)
	B((0.1, 0.008, 0.028), (0, 0.016, z - 0.08), CU("b"), bevel=0.002)  # brass name plate
	for x in (-0.042, 0.042):
		kit.rivet((x, 0.012, z - 0.08), CU("dark"), r=0.004)


def foreman_helmet_trophy():
	wall_post(1.0)
	plank_board(0.7, 0.7, 1.32, round_=True)
	cy, cz = -0.23, 1.25
	log((0, 0.02, 1.2), (0, cy, 1.24), 0.03, T("wood", "dark"), seg=7, rings=1)
	o = sphere((0, cy, cz), 0.22, kit.tex_mat("iron", "dark"), scale=(1, 1, 1.05), seg=16, rings=10, cut=0.0)
	kit.roughen(o, 0.006, 1, seed=4)
	o = kit.cylinder(0.27, 0.02, (0, cy + 0.01, cz), kit.tex_mat("iron", "a"), verts=20, bevel=0.006)
	o.scale = (1, 0.93, 1)
	kit.ring(0.222, 0.016, (0, cy, cz + 0.05), CU("b"), seg=20)
	for k in range(8):
		a = math.pi + k * math.pi / 7
		rivet((math.cos(a) * 0.233, cy + math.sin(a) * 0.233, cz + 0.05), CU("dark"))
	pts = [(0, cy - 0.2 * math.cos(t), cz + 0.225 * math.sin(t)) for t in (0.5, 0.9, 1.25, 1.57, 1.9, 2.3)]
	tube(pts, 0.028, 0.028, kit.tex_mat("iron", "a"), seg=6)  # crest ridge front to back
	lz, ly = cz + 0.13, cy - 0.17
	kit.cylinder(0.065, 0.09, (0, ly, lz), CU("b"), rot=(90, 0, 0), verts=12, bevel=0.008)
	kit.cylinder(0.05, 0.012, (0, ly - 0.046, lz), C((1.0, 0.8, 0.4), 0.2, glow=1.0), rot=(90, 0, 0), verts=12, bevel=0)
	kit.ring(0.058, 0.012, (0, ly - 0.046, lz), CU("dark"), rot=(90, 0, 0), seg=14)
	B((0.05, 0.06, 0.05), (0, ly + 0.06, lz - 0.05), CU("dark"), bevel=0.006)
	for (x, zz, a) in ((0.12, cz + 0.1, 30), (-0.1, cz + 0.05, -50)):
		B((0.07, 0.01, 0.008), (x, cy - math.sqrt(max(0.0, 0.22 ** 2 - x ** 2 - ((zz - cz) / 1.05) ** 2)) - 0.002, zz), kit.mat("charcoal"), bevel=0, rot=(0, a, 0))


MODELS = {
	"column_rootwrapped": column_rootwrapped,
	"banner_torn_faded": banner_torn_faded,
	"gem_stand": gem_stand, "gem_case": gem_case, "ore_sample_shelf": ore_sample_shelf, "tooth_necklace": tooth_necklace,
	"bat_wing_trophy": bat_wing_trophy, "crossed_swords": crossed_swords, "crossed_axes": crossed_axes,
	"medal_board": medal_board, "golden_pickaxe": golden_pickaxe,
	"first_coin_frame": first_coin_frame, "foreman_helmet_trophy": foreman_helmet_trophy,
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
