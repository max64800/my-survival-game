# Decor, Nov 21 group C: dungeon and ruin story pieces, old and worn (maps, war drum, portcullis, prison bench,
# fallen chandelier, carved wall slabs...). Same style and helpers as night_decor.py.
#   blender --background --factory-startup --python builds/decor_nov21_c.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (map, tally marks, graffiti, prison bench) have a flat back at +Y so they sit flush on a wall.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, cband, disc, kit, log, mesh, plank, rivet, rng, stone  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402
from decor_nov21_a import GROOVE_M, carve, chip, groove, groove_path, rest, rubble_heap, spin  # noqa: E402

WOOD = lambda: T("wood")  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
RUST = lambda: C((0.26, 0.13, 0.08), 0.75, metal=0.35)  # noqa: E731
OLD_IRON = lambda: IRON("dark") if rng.random() < 0.75 else RUST()  # noqa: E731
GROOVE = lambda: C((0.16, 0.14, 0.12), 0.95)  # noqa: E731
WAX = lambda: C((0.88, 0.8, 0.6), 0.85)  # noqa: E731
PARCH = lambda: C((0.74, 0.63, 0.44), 0.95)  # noqa: E731
INK = lambda: C((0.3, 0.2, 0.12), 0.9)  # noqa: E731


# ---------------- helpers ----------------
def slab_xz(pts, y0, y1, m):
	"""A flat plate: outline pts (x, z) pushed from y0 to y1 (paper, carved stones, painted signs)."""
	n = len(pts)
	v = [(x, y0, z) for x, z in pts] + [(x, y1, z) for x, z in pts]
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def tube(pts, radii, m, seg=10, up=(0, 1, 0)):
	"""A bent tube through pts (horns, hooks); radii per point. Curves in the XZ plane keep `up` = Y."""
	pts = [Vector(p) for p in pts]
	up = Vector(up)
	verts = []
	for i, p in enumerate(pts):
		t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
		u = t.cross(up).normalized()
		w = t.cross(u)
		for k in range(seg):
			a = 2 * math.pi * k / seg
			verts.append(tuple(p + (u * math.cos(a) + w * math.sin(a)) * radii[i]))
	faces = []
	for i in range(len(pts) - 1):
		for k in range(seg):
			a, b = i * seg + k, i * seg + (k + 1) % seg
			faces.append((a, b, b + seg, a + seg))
	faces.append(tuple(reversed(range(seg))))
	faces.append(tuple(range((len(pts) - 1) * seg, len(pts) * seg)))
	return mesh(verts, faces, m, smooth=True)


def chain(p0, p1, R=0.024, wire=0.008, m=None, first=True):
	"""Interlocked iron links from p0 to p1 (each link turned 90 degrees to the last)."""
	p0, p1 = Vector(p0), Vector(p1)
	d = p1 - p0
	x = d.normalized()
	ref = Vector((0, 0, 1)) if abs(x.z) < 0.9 else Vector((1, 0, 0))
	u = x.cross(ref).normalized()
	v = x.cross(u)
	n = max(2, int(d.length / (R * 1.5)) + 1)
	for i in range(0 if first else 1, n):
		c = p0 + d * (i / (n - 1))
		z = u if i % 2 else v
		o = kit.ring(R, wire, tuple(c), m or IRON("dark"), seg=10)
		o.rotation_euler = Matrix((x, z.cross(x), z)).transposed().to_euler()


def line_xz(p0, p1, y, w=0.018, m=None, depth=0.01):
	"""A carved or painted stroke on a wall face at y (front)."""
	(x0, z0), (x1, z1) = p0, p1
	ln = math.hypot(x1 - x0, z1 - z0)
	ang = math.degrees(math.atan2(z1 - z0, x1 - x0))
	B((ln + w * 0.6, depth, w), ((x0 + x1) / 2, y, (z0 + z1) / 2), m or GROOVE(), bevel=0.003, rot=(0, -ang, 0))


def wall_slab(w, h, d=0.16, rows=3, tones=("stone", "stone", "greystone", "brownrock")):
	"""Old masonry slab for a wall: staggered blocks, front face flat at y = -d, a dark backing flush at y = 0."""
	B((w - 0.04, d - 0.03, h - 0.03), (0, -(d - 0.03) / 2, h / 2), kit.mat("charcoal", 0.4), bevel=0)
	blocks = []
	rh = h / rows
	for r in range(rows):
		x = -w / 2
		k = 0
		while x < w / 2 - 0.05:
			bw = min(w / 2 - x, (0.38 if (r + k) % 2 else 0.28) + J(0.06))
			if w / 2 - (x + bw) < 0.12:
				bw = w / 2 - x
			blocks.append(B((bw - 0.012, d - 0.02, rh - 0.012), (x + bw / 2, -d / 2 - 0.01, rh * (r + 0.5)),
				T(tones[rng.randrange(len(tones))], rng.choice("abc")), bevel=0.02))
			x += bw
			k += 1
	return blocks


def mug(loc, tipped=False, ang=0.0):
	x, y, z = loc
	m = T("wood", "b")
	if tipped:
		kit.cylinder(0.05, 0.12, (x, y, z + 0.06), m, rot=(90, 0, ang), verts=10, bevel=0.006)
		a = math.radians(ang)
		for t in (-0.035, 0.035):
			kit.ring(0.052, 0.008, (x + math.sin(a) * t, y - math.cos(a) * t, z + 0.06), CU("dark"), rot=(90, 0, ang), seg=12)
		kit.ring(0.03, 0.01, (x + math.cos(a) * 0.055, y + math.sin(a) * 0.055, z + 0.045), m, rot=(0, 0, ang), seg=10)
		disc(0.12, 0.0, 0.004, (x - math.sin(a) * 0.14, y + math.cos(a) * 0.14), C((0.25, 0.14, 0.07), 0.3), seg=12, wob=0.2)
		return
	kit.cylinder(0.05, 0.12, (x, y, z + 0.06), m, verts=10, bevel=0.006)
	for t in (0.025, 0.095):
		kit.ring(0.052, 0.008, (x, y, z + t), CU("dark"), seg=12)
	kit.ring(0.032, 0.01, (x + 0.055, y, z + 0.06), m, rot=(90, 0, 0), seg=10)


def plate(loc, r=0.13, m=None):
	x, y, z = loc
	kit.cylinder(r, 0.015, (x, y, z + 0.0075), m or T("wood", "c"), verts=16, bevel=0.004)
	kit.ring(r - 0.01, 0.007, (x, y, z + 0.016), m or T("wood", "c"), seg=16)


def splinters(p, ax=(0, 0, 1), n=4, r=0.03):
	"""Wood splinters sticking out of a snapped end at p, pointing along ax."""
	ax = Vector(ax).normalized()
	q = Vector((0, 0, 1)).rotation_difference(ax)
	u = ax.orthogonal().normalized()
	v = ax.cross(u)
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.4)
		c = Vector(p) + (u * math.cos(a) + v * math.sin(a)) * r * 0.55 + ax * 0.025
		o = kit.cone(0.012, 0.0, 0.06 + J(0.02), tuple(c), T("wood", "c"), verts=4, bevel=0)
		o.rotation_euler = q.to_euler()


def ground_lump(x, y, size, m, seed=1, rough=0.01):
	"""A lump resting on the floor: dropped so its lowest corner sits at z = 0."""
	o = lump((x, y, 0.1), size, m, seed=seed, rough=rough)
	bpy.context.view_layer.update()
	o.location.z -= min((o.matrix_world @ v.co).z for v in o.data.vertices)
	return o


def turn(objs, axis, deg, pivot):
	R = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-Vector(pivot))
	for o in objs:
		o.matrix_world = R @ o.matrix_world


def low_z(objs):
	return min((o.matrix_world @ v.co).z for o in objs for v in o.data.vertices)


# ================= Wall pieces =================
def map_torn_wall():
	"""A torn parchment map nailed to the wall: ragged edges, a corner torn off and hanging, fold creases, stains,
	branching tunnels with chambers, peaks, a compass, a skull for danger, a dashed route to a red X, notes in
	scribble and a small second note nailed over the corner."""
	r = rng
	outline = []
	W, H = 0.72, 0.52
	for i in range(9):  # bottom edge, torn
		outline.append((-W / 2 + W * i / 8, 0.0 + r.uniform(0, 0.03)))
	outline += [(W / 2 - 0.01, 0.12), (W / 2 + 0.01, 0.3), (W / 2 - 0.02, 0.38), (W / 2 - 0.12, 0.42), (W / 2 - 0.16, H)]  # torn corner
	for i in range(1, 8):
		outline.append((W / 2 - 0.16 - (W - 0.16) * i / 7, H + r.uniform(-0.015, 0.01)))
	outline += [(-W / 2 + 0.01, H - 0.12), (-W / 2 - 0.01, 0.25), (-W / 2 + 0.01, 0.1)]
	slab_xz(outline, -0.006, 0.0, PARCH())
	# hanging flap (the torn-off corner still holding on)
	slab_xz([(W / 2 - 0.15, 0.42), (W / 2 - 0.03, 0.39), (W / 2 + 0.02, 0.26), (W / 2 - 0.09, 0.3)], -0.02, -0.014, C((0.68, 0.57, 0.38), 0.95))
	B((0.03, 0.012, 0.02), (W / 2 - 0.1, -0.012, 0.4), C((0.68, 0.57, 0.38), 0.95), bevel=0)
	# stains and fold creases
	for (x, z, s) in ((-0.2, 0.15, 0.07), (0.1, 0.38, 0.05), (0.22, 0.08, 0.06)):
		blob = [(x + math.cos(a) * s * rng.uniform(0.7, 1.2), z + math.sin(a) * s * rng.uniform(0.6, 1.0)) for a in [2 * math.pi * k / 9 for k in range(9)]]
		slab_xz(blob, -0.007, -0.0085, C((0.58, 0.46, 0.29), 0.95))
	crease = C((0.6, 0.5, 0.33), 0.95)
	line_xz((0.0, 0.02), (0.0, H - 0.01), -0.0062, w=0.005, m=crease, depth=0.0015)
	line_xz((-W / 2 + 0.01, 0.26), (W / 2 - 0.02, 0.26), -0.0062, w=0.005, m=crease, depth=0.0015)
	ink = INK()

	def ink_line(a, b, w=0.011):
		line_xz(a, b, -0.009, w=w, m=ink, depth=0.006)

	# tunnels: a main way with side branches, chambers as rings
	for path in ([(-0.3, 0.1), (-0.18, 0.2), (-0.05, 0.17), (0.05, 0.28), (0.18, 0.25)], [(-0.18, 0.2), (-0.2, 0.29), (-0.12, 0.34)],
			[(0.05, 0.28), (0.03, 0.38), (0.1, 0.44)], [(-0.05, 0.17), (0.0, 0.09), (0.1, 0.07)]):
		for a, b in zip(path, path[1:]):
			ink_line(a, b, 0.013)
	for (x, z, rr) in ((-0.3, 0.1, 0.035), (-0.12, 0.34, 0.028), (0.1, 0.44, 0.03)):
		pts = [(x + math.cos(2 * math.pi * k / 7) * rr, z + math.sin(2 * math.pi * k / 7) * rr) for k in range(7)]
		for a, b in zip(pts, pts[1:] + pts[:1]):
			ink_line(a, b, 0.008)
	for (x, z) in ((-0.25, 0.42), (-0.17, 0.46), (-0.08, 0.42)):  # peaks
		ink_line((x - 0.04, z - 0.04), (x, z), 0.01)
		ink_line((x, z), (x + 0.04, z - 0.04), 0.01)
		ink_line((x - 0.012, z - 0.012), (x + 0.008, z - 0.03), 0.006)  # shading stroke
	river = C((0.25, 0.35, 0.42), 0.9)
	line_xz((0.0, 0.05), (0.1, 0.12), -0.008, w=0.014, m=river, depth=0.006)
	line_xz((0.1, 0.12), (0.12, 0.2), -0.008, w=0.014, m=river, depth=0.006)
	# compass
	cx, cz = -0.28, 0.27
	ink_line((cx, cz - 0.05), (cx, cz + 0.06), 0.008)
	ink_line((cx - 0.045, cz), (cx + 0.045, cz), 0.008)
	ink_line((cx - 0.02, cz + 0.035), (cx, cz + 0.07), 0.006)
	ink_line((cx + 0.02, cz + 0.035), (cx, cz + 0.07), 0.006)
	# skull for danger: round head, two eyes, crossed bones
	sx, sz = 0.13, 0.15
	pts = [(sx + math.cos(2 * math.pi * k / 8) * 0.022, sz + math.sin(2 * math.pi * k / 8) * 0.022) for k in range(8)]
	for a, b in zip(pts, pts[1:] + pts[:1]):
		ink_line(a, b, 0.006)
	for s_ in (-1, 1):
		B((0.008, 0.006, 0.008), (sx + s_ * 0.008, -0.012, sz + 0.003), ink, bevel=0)
		ink_line((sx - 0.035, sz - 0.04 * s_ - 0.005), (sx + 0.035, sz + 0.04 * s_ - 0.005), 0.006)
	# dashed route to the red X
	route = [(-0.3, 0.06), (-0.15, 0.05), (0.0, 0.03), (0.15, 0.1), (0.18, 0.22)]
	for a, b in zip(route, route[1:]):
		for t in (0.1, 0.55):
			p = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
			q = (a[0] + (b[0] - a[0]) * (t + 0.28), a[1] + (b[1] - a[1]) * (t + 0.28))
			line_xz(p, q, -0.0095, w=0.007, m=C((0.45, 0.14, 0.09), 0.9), depth=0.006)
	red = C((0.5, 0.12, 0.08), 0.9)
	line_xz((0.15, 0.22), (0.21, 0.28), -0.009, w=0.016, m=red, depth=0.008)
	line_xz((0.15, 0.28), (0.21, 0.22), -0.013, w=0.016, m=red, depth=0.004)
	# scribbled notes
	for i in range(3):
		z = 0.48 - i * 0.025
		for k in range(4):
			x = 0.0 + k * 0.032
			ink_line((x, z + (0.004 if k % 2 else -0.004)), (x + 0.028, z + (-0.004 if k % 2 else 0.004)), 0.005)
	# a second small note nailed over the bottom right
	slab_xz([(0.2, 0.02), (0.33, 0.03), (0.34, 0.14), (0.27, 0.15), (0.21, 0.13)], -0.014, -0.0105, C((0.78, 0.7, 0.52), 0.95))
	for i in range(3):
		line_xz((0.225, 0.11 - i * 0.025), (0.31, 0.113 - i * 0.025), -0.0155, w=0.005, m=ink, depth=0.003)
	kit.cylinder(0.006, 0.02, (0.27, -0.016, 0.135), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0)
	kit.cylinder(0.014, 0.008, (0.27, -0.026, 0.135), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	# nails
	for (x, z) in ((-0.32, 0.47), (0.14, 0.49), (-0.31, 0.05), (0.3, 0.3)):
		kit.cylinder(0.006, 0.02, (x, -0.012, z), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0)
		kit.cylinder(0.016, 0.008, (x, -0.022, z), OLD_IRON(), rot=(90, 0, 0), verts=8, bevel=0.002)


def tally_marks():
	"""A wall slab with tally marks cut into the stone: groups of four and a slash, the last group unfinished,
	a crack running through one block."""
	W, H, D = 1.0, 0.8, 0.16
	blocks = wall_slab(W, H, D, tones=("greystone",))
	y = -D
	cut = []
	for row, zc in enumerate((0.62, 0.38, 0.15)):
		for g in range(4 if row < 2 else 2):
			x0 = -0.38 + g * 0.22 + J(0.02)
			k = 5 if not (row == 2 and g == 1) else 3
			for i in range(min(k, 4)):
				x = x0 + i * 0.035
				cut += groove((x + J(0.008), zc - 0.08), (x + J(0.012), zc + 0.08 + J(0.01)), y, w=0.015 + J(0.003), depth=0.014)
			if k == 5:
				cut += groove((x0 - 0.03, zc - 0.05), (x0 + 0.14, zc + 0.06), y, w=0.016, depth=0.016)
	cut += groove_path([(0.36, 0.03), (0.39, 0.1), (0.37, 0.18), (0.42, 0.27), (0.4, 0.34)], y, w=0.007, depth=0.02)
	cut += [chip((-0.5, y + 0.01, 0.79), (0.05, 0.04, 0.04), seed=3), chip((0.5, y + 0.01, 0.3), (0.04, 0.04, 0.05), seed=4)]
	carve(blocks, cut)


def graffiti_pell():
	"""A wall slab with a crude dwarf face (helmet, big nose, braided beard) and a pickaxe doodle cut into the stone. No letters."""
	W, H, D = 1.0, 0.8, 0.16
	blocks = wall_slab(W, H, D, rows=2, tones=("greystone",))
	y = -D
	cut = []

	def g(a, b, w=0.026, d=0.014):
		cut.extend(groove(a, b, y, w, d))

	cx, cz, r = -0.15, 0.5, 0.17
	pts = [(cx + math.cos(a) * r, cz + math.sin(a) * r * 1.05) for a in [math.radians(200 - 22 * i) for i in range(12)]]
	for a, b in zip(pts, pts[1:]):  # head + helmet arc
		g(a, b)
	g((cx - r - 0.05, cz + 0.05), (cx + r + 0.05, cz + 0.05))  # helmet brim
	g((cx, cz + r * 1.05), (cx, cz + r + 0.08))  # helmet spike
	for s_ in (-1, 1):  # eyes: chiselled diamonds
		cut.append(B((0.04, 0.03 + 0.016, 0.04), (cx + s_ * 0.065, y + (0.016 - 0.03) / 2, cz - 0.02), GROOVE_M(), bevel=0, rot=(0, 45, 0)))
	g((cx, cz - 0.01), (cx - 0.02, cz - 0.08))  # nose
	g((cx - 0.02, cz - 0.08), (cx + 0.03, cz - 0.08))
	beard = [(cx - r - 0.01, cz - 0.04), (cx - 0.12, cz - 0.24), (cx - 0.07, cz - 0.14), (cx - 0.03, cz - 0.3), (cx + 0.02, cz - 0.15),
		(cx + 0.07, cz - 0.28), (cx + 0.1, cz - 0.13), (cx + 0.14, cz - 0.22), (cx + r + 0.01, cz - 0.04)]
	for a, b in zip(beard, beard[1:]):
		g(a, b)
	for (x, z) in ((cx - 0.05, cz - 0.2), (cx + 0.08, cz - 0.19)):  # braid rings
		g((x - 0.02, z), (x + 0.02, z), 0.012, 0.01)
	g((0.18, 0.12), (0.36, 0.55), 0.02)  # pickaxe handle + curved head
	head = [(0.2, 0.48), (0.26, 0.55), (0.34, 0.58), (0.42, 0.57), (0.5, 0.52)]
	for a, b in zip(head, head[1:]):
		g(a, b, 0.022, 0.016)
	for (a, b) in (((0.25, 0.1), (0.33, 0.07)), ((-0.42, 0.12), (-0.36, 0.18)), ((0.3, 0.68), (0.38, 0.7))):  # stray scratches
		g(a, b, 0.008, 0.008)
	cut += [chip((0.5, y + 0.01, 0.78), (0.05, 0.04, 0.05), seed=7)]
	carve(blocks, cut)




# ================= War =================
def war_drum_split():
	"""A big war drum on a log stand: the hide head lapped over the rim and tacked down, split open with a curled
	flap and old repair stitches across the split, a faded painted hammer ring, rope lacing, copper hoops."""
	legs = 0.38
	for (x, y) in ((-0.3, -0.3), (0.3, -0.3), (-0.3, 0.3), (0.3, 0.3)):
		log((x, y, 0), (x * 0.82, y * 0.82, legs + 0.03), 0.045, T("bark"), seg=7, rings=2)
	kit.ring(0.35, 0.035, (0, 0, legs), T("wood", "dark"), seg=20)
	R, Hd, z0 = 0.4, 0.5, legs
	kit.cylinder(R, Hd, (0, 0, z0 + Hd / 2), T("wood", "b"), verts=18, bevel=0.02)
	for z in (z0 + 0.04, z0 + Hd - 0.04):
		kit.ring(R + 0.01, 0.025, (0, 0, z), CU("dark"), seg=20)
	for k in range(9):
		a0, a1 = 2 * math.pi * k / 9, 2 * math.pi * (k + 0.5) / 9
		log((math.cos(a0) * (R + 0.02), math.sin(a0) * (R + 0.02), z0 + 0.06),
			(math.cos(a1) * (R + 0.02), math.sin(a1) * (R + 0.02), z0 + Hd - 0.07), 0.01, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
		a2 = 2 * math.pi * (k + 1) / 9
		log((math.cos(a1) * (R + 0.02), math.sin(a1) * (R + 0.02), z0 + Hd - 0.07),
			(math.cos(a2) * (R + 0.02), math.sin(a2) * (R + 0.02), z0 + 0.06), 0.01, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
	zt = z0 + Hd
	hide = C((0.72, 0.6, 0.42), 0.9)
	# head in two halves with a jagged split between them
	jag = [(-R, 0.02), (-0.2, -0.03), (-0.05, 0.04), (0.1, -0.02), (0.25, 0.03), (R, -0.01)]
	for s_ in (-1, 1):
		poly = [(x, y + s_ * 0.025) for x, y in jag] + [(math.cos(math.radians(s_ * 20 * i)) * R, math.sin(math.radians(s_ * 20 * i)) * R) for i in range(1, 9)]
		n = len(poly)
		v = [(x, y, zt - 0.005) for x, y in poly] + [(x, y, zt + 0.012) for x, y in poly]
		f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
		mesh(v, f, hide)
	disc(R - 0.02, zt + 0.001, zt + 0.004, (0, 0), kit.mat("charcoal", 0.2), seg=16, wob=0.0)  # dark inside seen through the split
	# curled flap
	mesh([(0.0, -0.02, zt + 0.012), (0.12, -0.02, zt + 0.012), (0.1, -0.07, zt + 0.12), (0.02, -0.06, zt + 0.1),
		(0.0, -0.03, zt + 0.012), (0.12, -0.03, zt + 0.012), (0.1, -0.08, zt + 0.12), (0.02, -0.07, zt + 0.1)],
		[(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], hide)
	kit.ring(R + 0.005, 0.03, (0, 0, zt - 0.012), hide, seg=24)  # the hide lapped over the rim
	for k in range(24):  # iron tacks holding the lap down
		a = 2 * math.pi * (k + 0.5) / 24
		kit.rivet((math.cos(a) * (R + 0.034), math.sin(a) * (R + 0.034), zt - 0.02), IRON("dark"), r=0.011)
	# faded painted ring and hammer on the hide (paint, so it lies on the hide)
	paint = C((0.42, 0.16, 0.1), 0.95)
	for k in range(20):
		a0, a1 = 2 * math.pi * k / 20, 2 * math.pi * (k + 0.8) / 20
		x0, y0, x1, y1 = math.cos(a0) * 0.28, math.sin(a0) * 0.28, math.cos(a1) * 0.28, math.sin(a1) * 0.28
		if min(abs(y0), abs(y1)) < 0.075:
			continue  # the paint is gone along the split
		ln, ang = math.hypot(x1 - x0, y1 - y0), math.degrees(math.atan2(y1 - y0, x1 - x0))
		B((ln + 0.01, 0.022, 0.004), ((x0 + x1) / 2, (y0 + y1) / 2, zt + 0.013), paint, bevel=0, rot=(0, 0, ang))
	for (x, y, w, d) in ((-0.11, 0.15, 0.03, 0.14), (-0.11, 0.2, 0.11, 0.045), (0.12, -0.17, 0.03, 0.12), (0.12, -0.21, 0.1, 0.04)):
		B((w, d, 0.004 + 0.002 * (w > 0.05)), (x, y, zt + 0.013 + 0.001 * (w > 0.05)), paint, bevel=0)  # a hammer on each half
	# old repair stitches across the split, two of them torn
	for k, x in enumerate((-0.3, -0.16, -0.02, 0.17, 0.31)):
		if k in (1, 3):
			kit.cylinder(0.005, 0.03, (x, 0.05, zt + 0.016), kit.tex_mat("rope"), rot=(90, 0, 0), verts=5, bevel=0)  # torn end
			continue
		ya = 0.055 + 0.0 * k
		log((x, -ya, zt + 0.015), (x + 0.01, ya, zt + 0.015), 0.005, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)


def horn_shell(pts, radii, wall, k0, m_out, m_in, seg=14):
	"""A horn as one closed shell: outside along pts, then over the rim and back inside to ring k0 (open bell)."""
	pts = [Vector(p) for p in pts]
	n = len(pts)
	frames = []
	for i, p in enumerate(pts):
		t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
		u = t.cross(Vector((0, 1, 0))).normalized()
		frames.append((p, u, t.cross(u)))
	rings = [(i, radii[i]) for i in range(n)] + [(i, radii[i] - wall) for i in range(n - 1, k0 - 1, -1)]
	verts = []
	for i, r in rings:
		p, u, w = frames[i]
		for k in range(seg):
			a = 2 * math.pi * k / seg
			verts.append(tuple(p + (u * math.cos(a) + w * math.sin(a)) * r))
	faces = [(j * seg + k, j * seg + (k + 1) % seg, (j + 1) * seg + (k + 1) % seg, (j + 1) * seg + k) for j in range(len(rings) - 1) for k in range(seg)]
	faces += [tuple(reversed(range(seg))), tuple(range((len(rings) - 1) * seg, len(rings) * seg))]
	o = mesh(verts, faces, m_out, smooth=True)
	o.data.materials.append(m_in)
	first_in = (n - 1) * seg  # faces after the outside belong to the rim/inside
	for i, poly in enumerate(o.data.polygons):
		if first_in + seg <= i < len(faces) - 2 or i == len(faces) - 1:
			poly.material_index = 1
	return o


def war_horn_stand():
	"""A long curved war horn with an open, hollow bell resting in two forked posts lashed with rope on a plank
	base; riveted copper bands, a mouthpiece with rings, a leather carry strap hanging under it."""
	B((1.25, 0.38, 0.07), (0, 0, 0.035), T("wood", "b"), bevel=0.015)
	for x in (-0.5, 0.5):
		B((0.08, 0.42, 0.04), (x, 0, 0.012), T("wood", "b"), bevel=0.008)  # cross battens
	pts, radii = [], []
	n = 14
	for i in range(n + 1):
		t = i / n
		x = -0.6 + 1.2 * t
		z = 0.72 + 0.22 * (t ** 2) - 0.1 * math.sin(t * math.pi)
		pts.append((x, 0, z))
		radii.append(0.025 + 0.12 * t ** 2.2)
	horn = C((0.66, 0.56, 0.42), 0.7)
	horn_shell(pts, radii, 0.014, 9, horn, kit.mat("charcoal", 0.15))

	def axis_deg(i):
		return 90 - math.degrees(math.atan2(pts[min(i + 1, n)][2] - pts[max(i - 1, 0)][2], pts[min(i + 1, n)][0] - pts[max(i - 1, 0)][0]))

	for i in (2, 4, 7, 10, 12):
		kit.ring(radii[i] + 0.004, 0.011, pts[i], CU("dark"), rot=(0, axis_deg(i), 0), seg=16)
		th = math.radians(90 - axis_deg(i))  # the horn's slope at this band
		nrm = Vector((-math.sin(th), 0, math.cos(th)))
		for k in range(4):  # rivets round the band
			a = math.pi / 4 + k * math.pi / 2
			kit.rivet(tuple(Vector(pts[i]) + (nrm * math.cos(a) + Vector((0, 1, 0)) * math.sin(a)) * (radii[i] + 0.013)), CU("b"), r=0.009)
	rim = n
	kit.ring(radii[rim] - 0.007, 0.012, pts[rim], CU("b"), rot=(0, axis_deg(rim), 0), seg=20)  # copper lip on the bell
	kit.cylinder(0.028, 0.04, (pts[0][0] - 0.015, 0, pts[0][2]), CU(), rot=(0, 90, 0), verts=10, bevel=0.004)  # mouthpiece
	for dx in (-0.03, 0.0):
		kit.ring(0.03, 0.007, (pts[0][0] + dx, 0, pts[0][2]), CU("dark"), rot=(0, 90, 0), seg=12)
	# leather carry strap hanging between two bands
	a_, b_ = Vector(pts[4]) - Vector((0, 0, radii[4] + 0.008)), Vector(pts[10]) - Vector((0, 0, radii[10] + 0.008))
	strap = [a_ + (b_ - a_) * (k / 8) - Vector((0, 0.0, 0.16 * math.sin(math.pi * k / 8))) for k in range(9)]
	log(tuple(strap[0]), tuple(strap[0] + Vector((0, 0, 0.012))), 0.012, kit.tex_mat("leather", "dark"), seg=6, rings=1, ends=False, bend=0)
	for p, q in zip(strap, strap[1:]):
		log(tuple(p), tuple(q), 0.011, kit.tex_mat("leather", "dark"), seg=6, rings=1, ends=False, bend=0)
	for xi in (3, 10):
		x, _, z = pts[xi]
		r = radii[xi]
		log((x, 0, 0.06), (x, 0, z - r - 0.03), 0.04, T("wood", "b"), seg=7, rings=2)
		for s_ in (-1, 1):
			log((x, 0, z - r - 0.05), (x, s_ * (r + 0.06), z + 0.03), 0.025, T("wood", "b"), seg=6, rings=1, bend=0)
		for dz in (0.0, 0.035):
			kit.ring(0.045, 0.011, (x, 0, z - r - 0.06 - dz), kit.tex_mat("rope"), seg=10)  # lashing
		for s_ in (-1, 1):
			kit.cylinder(0.012, 0.02, (x + s_ * 0.06, 0, 0.075), T("wood", "c"), verts=6, bevel=0.002)  # pegs in the base




# ================= Gates and doors =================
def stone_column(x, w, d, h, z0=0.0):
	B((w - 0.05, d - 0.05, h - 0.08), (x, 0, z0 + h / 2), kit.mat("charcoal", 0.4), bevel=0)
	rows = max(1, round(h / 0.32))
	for r in range(rows):
		stone((w, d, h / rows - 0.012), (x + J(0.015), J(0.01), z0 + h / rows * (r + 0.5)), bevel=0.03)


def portcullis_rusted():
	"""A rusted iron portcullis half lowered in a stone frame: spiked bottom, one bar bent, one missing."""
	OW, OH = 1.7, 1.75  # opening
	PW, PD = 0.3, 0.42
	for s_ in (-1, 1):
		stone_column(s_ * (OW / 2 + PW / 2), PW, PD, OH)
	# lintel
	B((OW + 2 * PW - 0.05, PD - 0.05, 0.28), (0, 0, OH + 0.19), kit.mat("charcoal", 0.4), bevel=0)
	for k in range(4):
		w = (OW + 2 * PW) / 4
		stone((w - 0.012, PD + 0.02, 0.38), (-(OW + 2 * PW) / 2 + w * (k + 0.5), 0, OH + 0.19), bevel=0.03)
	zb = 0.85  # bottom of the gate
	top = OH + 0.15
	nb = 9
	for i in range(nb):
		x = -OW / 2 + 0.1 + (OW - 0.2) * i / (nb - 1)
		if i == 6:
			continue  # missing bar
		if i == 2:
			log((x, 0, top), (x + 0.05, -0.04, zb - 0.02), 0.025, RUST(), seg=6, rings=3, ends=False, bend=0.6)
			continue
		B((0.05, 0.05, top - zb), (x, 0, (top + zb) / 2), OLD_IRON(), bevel=0.006)
		kit.cone(0.035, 0.0, 0.12, (x, 0, zb - 0.06), OLD_IRON(), rot=(180, 0, 45), verts=4, bevel=0)
	for z in (zb + 0.12, zb + 0.5, zb + 0.88):
		B((OW + 0.04, 0.03, 0.06), (0, -0.04, z), OLD_IRON(), bevel=0.005)
		for i in range(0, nb, 2):
			x = -OW / 2 + 0.1 + (OW - 0.2) * i / (nb - 1)
			rivet((x, -0.058, z), RUST(), r=0.013)
	# a stub of the missing bar and rust dribbles on the frame
	x6 = -OW / 2 + 0.1 + (OW - 0.2) * 6 / (nb - 1)
	B((0.05, 0.05, top - zb - 0.62), (x6, 0, (top + zb + 0.62) / 2), RUST(), bevel=0.006)


def floor_grate():
	"""An iron grate over a stone-lined drain shaft, set in dressed floor stones: a riveted iron frame, bars
	with cross bars (one bent), two hinges and a lift ring. Stone and iron kept in one grey family."""
	S, T_ = 1.0, 0.16
	hole = 0.5
	g = lambda v: T("greystone", v)  # noqa: E731
	B((S - 0.02, S - 0.02, 0.035), (0, 0, 0.0175), g("dark"), bevel=0.006)  # bedding under the stones = the shaft floor
	disc(0.12, 0.035, 0.039, (0.06, -0.05), C((0.07, 0.075, 0.08), 0.15), seg=12, wob=0.25)  # wet puddle at the bottom
	stones = []
	for (x, y, sx, sy) in ((-0.25, -0.375, 0.5, 0.25), (0.25, -0.375, 0.5, 0.25), (-0.25, 0.375, 0.5, 0.25), (0.25, 0.375, 0.5, 0.25),
			(-0.375, 0.0, 0.25, 0.5), (0.375, 0.0, 0.25, 0.5)):
		h = T_ - 0.005 + J(0.004)
		stones.append(B((sx - 0.015, sy - 0.015, h), (x, y, 0.005 + h / 2), g(rng.choice("abc")), bevel=0.025))
	carve(stones, [chip((-0.49, -0.49, T_), (0.05, 0.05, 0.04), seed=3), chip((0.49, 0.2, T_), (0.04, 0.05, 0.035), seed=4),
		chip((0.05, 0.49, T_), (0.05, 0.04, 0.035), seed=5)])
	# shaft lining: two courses of darker stones on each inner wall
	wall = hole / 2 + 0.0075
	for (z0, v) in ((0.04, "dark"), (0.09, "b")):
		for s_ in (-1, 1):
			for i in range(3):
				xa = -hole / 2 + 0.01 + i * (hole - 0.02) / 3
				ln = (hole - 0.02) / 3 - 0.008
				B((ln, 0.03, 0.045), (xa + ln / 2 + 0.004, s_ * (wall - 0.01), z0 + 0.0225), g(v), bevel=0.006)
				B((0.03, ln, 0.045), (s_ * (wall - 0.01), xa + ln / 2 + 0.004, z0 + 0.0225), g(v), bevel=0.006)
	# iron frame on the stones round the hole, with rivets
	fz = T_ + 0.002
	for s_ in (-1, 1):
		B((hole + 0.1, 0.05, 0.012), (0, s_ * (hole / 2 + 0.02), fz), IRON("a"), bevel=0.003)
		B((0.05, hole - 0.0, 0.012), (s_ * (hole / 2 + 0.02), 0, fz - 0.001), IRON("a"), bevel=0.003)
		for t in (-0.22, 0.0, 0.22):
			rivet((t, s_ * (hole / 2 + 0.02), fz + 0.006), IRON("dark"), r=0.011)
			rivet((s_ * (hole / 2 + 0.02), t * 0.8, fz + 0.005), IRON("dark"), r=0.011)
	# the grate: bars along y resting on the frame, two cross bars under them
	zb = fz + 0.006 + 0.012
	xs = [-hole / 2 + 0.045 + (hole - 0.09) * i / 5 for i in range(6)]
	for i, x in enumerate(xs):
		if i == 3:
			log((x, -hole / 2 - 0.02, zb), (x + 0.03, hole / 2 + 0.02, zb), 0.015, IRON("a"), seg=6, rings=3, ends=False, bend=0.8)
		else:
			B((0.03, hole + 0.05, 0.026), (x, 0, zb), IRON("a"), bevel=0.004)
	for y in (-0.12, 0.12):
		B((hole + 0.02, 0.03, 0.02), (0, y, zb - 0.015), IRON("a"), bevel=0.004)
		for i, x in enumerate(xs):
			if i != 3:
				rivet((x, y, zb + 0.013), IRON("dark"), r=0.009)
	# hinges on the back edge, a lift ring at the front
	for x in (-0.15, 0.15):
		kit.cylinder(0.016, 0.07, (x, hole / 2 + 0.035, zb + 0.004), IRON("dark"), rot=(0, 90, 0), verts=8, bevel=0.002)
		B((0.05, 0.04, 0.01), (x, hole / 2 + 0.06, fz + 0.008), IRON("dark"), bevel=0.002)
	B((0.04, 0.03, 0.02), (0, -hole / 2 - 0.0, zb + 0.008), IRON("dark"), bevel=0.003)
	kit.ring(0.03, 0.007, (0, -hole / 2 - 0.03, zb + 0.004), IRON("dark"), rot=(10, 0, 0), seg=12)


def hanging_hook():
	"""A heavy log frame (two posts, a top beam, braces) with a big iron hook hanging on a chain."""
	W, H = 1.3, 1.9
	for x in (-W / 2, W / 2):
		log((x, -0.35, 0.07), (x, 0.35, 0.07), 0.07, T("bark"), seg=8, rings=2)
		log((x, 0, 0.1), (x, 0, H), 0.07, T("bark"), seg=8, rings=3, bend=0.04)
		for s_ in (-1, 1):
			log((x, s_ * 0.3, 0.1), (x, 0, 0.55), 0.04, T("bark"), seg=6, rings=2)
		log((x * 0.55, 0, H - 0.05), (x, 0, H - 0.4), 0.04, T("bark"), seg=6, rings=2)
		kit.ring(0.08, 0.014, (x, 0, H - 0.06), kit.tex_mat("rope"), seg=12)
	log((-W / 2 - 0.12, 0, H + 0.04), (W / 2 + 0.12, 0, H + 0.04), 0.08, T("bark"), seg=8, rings=3, bend=0.04)
	kit.ring(0.09, 0.016, (0, 0, H + 0.04), RUST(), rot=(0, 90, 0), seg=12)
	chain((0, 0, H - 0.05), (0, 0, 1.05))
	# hook: shank down, then a big J curl
	pts = [(0, 0, 1.05), (0, 0, 0.95), (0, 0, 0.82)]
	for k in range(1, 9):
		a = math.radians(180 + 25 * k)
		pts.append((0.11 + math.cos(a) * 0.11, 0, 0.82 + math.sin(a) * 0.11))
	radii = [0.022, 0.024, 0.026] + [0.026 - 0.0028 * k for k in range(1, 9)]
	tube(pts, radii, IRON("dark"), seg=8)
	kit.ring(0.035, 0.012, (0, 0, 1.07), IRON("dark"), rot=(90, 0, 0), seg=10)


def plank_crate(w, d, h, loc=(0, 0, 0)):
	"""A plank crate: four corner posts, side boards with gaps, Z-braces, a board lid, iron nail heads. One wood family."""
	x0, y0, z0 = loc
	wood = lambda: T("wood", rng.choice("abc"))  # noqa: E731
	t = 0.022
	B((w - 0.07, d - 0.07, h - 0.04), (x0, y0, z0 + h / 2), kit.tex_mat("shackdark", "a"), bevel=0)  # dark inside behind the gaps
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.045, 0.045, h - 0.01), (x0 + sx * (w / 2 - t - 0.02), y0 + sy * (d / 2 - t - 0.02), z0 + (h - 0.01) / 2), T("wood", "b"), bevel=0.006)
	nb = 3
	ph = (h - 0.02) / nb
	for i in range(nb):
		zc = z0 + 0.01 + ph * (i + 0.5)
		for sy in (-1, 1):
			B((w - 0.004, t, ph - 0.012), (x0, y0 + sy * (d / 2 - t / 2), zc), wood(), bevel=0.005)
		for sx in (-1, 1):
			B((t, d - 2 * t - 0.006, ph - 0.012), (x0 + sx * (w / 2 - t / 2), y0, zc), wood(), bevel=0.005)
	for sy in (-1, 1):  # Z-brace on front and back
		yb = y0 + sy * (d / 2 + 0.008)
		for zz in (z0 + 0.07, z0 + h - 0.07):
			B((w - 0.06, 0.02, 0.06), (x0, yb, zz), T("wood", "b"), bevel=0.005)
		dl = math.hypot(w - 0.12, h - 0.2)
		B((dl, 0.014, 0.055), (x0, yb, z0 + h / 2), T("wood", "b"), bevel=0.005, rot=(0, -math.degrees(math.atan2(h - 0.2, w - 0.12)), 0))
		for sx in (-1, 1):
			for zz in (z0 + 0.07, z0 + h - 0.07):
				rivet((x0 + sx * (w / 2 - 0.06), yb + sy * 0.011, zz), IRON("dark"), r=0.008)
	nl = 4
	for i in range(nl):  # lid boards
		yc = y0 - d / 2 + d * (i + 0.5) / nl
		B((w + 0.01, d / nl - 0.008, 0.024), (x0, yc, z0 + h + 0.008), wood(), bevel=0.005)
		for sx in (-1, 1):
			rivet((x0 + sx * (w / 2 - 0.03), yc, z0 + h + 0.021), IRON("dark"), r=0.007)
	return z0 + h + 0.02


def dice_on_crate():
	"""A plank crate used as a gaming table: bone dice and a tipped leather dice cup, copper coin stacks and
	loose coins, a mug, a candle stub in an iron dish."""
	zt = plank_crate(0.62, 0.5, 0.46)
	bone = kit.mat("bone", -0.12)
	for k, (x, y) in enumerate(((-0.1, -0.1), (-0.03, -0.16), (0.02, -0.07))):
		s = 0.038
		a = rng.uniform(0, 90)
		B((s, s, s), (x, y, zt + s / 2 - 0.001), bone, bevel=0.007, rot=(0, 0, a))
		for p in range(k + 1):
			off = (p - k / 2) * 0.012
			kit.rivet((x + math.cos(math.radians(a)) * off, y + math.sin(math.radians(a)) * off, zt + s - 0.0005), C((0.1, 0.07, 0.05), 0.9), r=0.0045)
	lea = kit.tex_mat("leather", "dark")
	kit.cylinder(0.042, 0.1, (-0.2, -0.05, zt + 0.042), lea, rot=(90, 0, 70), verts=12, bevel=0.005)  # dice cup on its side
	kit.ring(0.043, 0.007, (-0.2 + math.cos(math.radians(-20)) * 0.05, -0.05 + math.sin(math.radians(-20)) * 0.05, zt + 0.042), CU("dark"), rot=(90, 0, 70), seg=12)
	coin = CU("b")
	for (x, y, n) in ((0.12, -0.12, 5), (0.2, -0.03, 3), (0.08, 0.02, 2)):
		for i in range(n):
			kit.cylinder(0.022, 0.007, (x + J(0.003), y + J(0.003), zt + 0.0035 + i * 0.0068), coin, verts=10, bevel=0.001)
	for k, (x, y) in enumerate(((0.0, 0.08), (0.16, 0.08), (-0.08, 0.02))):
		kit.cylinder(0.022, 0.007, (x, y, zt + 0.0035), coin, verts=10, bevel=0.001)
	mug((-0.18, 0.13, zt))
	kit.cylinder(0.055, 0.012, (0.18, 0.15, zt + 0.006), IRON("dark"), verts=12, bevel=0.003)  # candle dish
	kit.ring(0.055, 0.006, (0.18, 0.15, zt + 0.013), IRON("dark"), seg=12)
	kit.ring(0.02, 0.005, (0.235, 0.15, zt + 0.012), IRON("dark"), rot=(90, 0, 0), seg=8)  # finger ring
	kit.cylinder(0.03, 0.055, (0.18, 0.15, zt + 0.039), WAX(), verts=9, bevel=0.004)
	kit.cylinder(0.004, 0.02, (0.18, 0.15, zt + 0.074), C((0.05, 0.04, 0.03), 0.9), verts=5, bevel=0)  # wick


def last_meal():
	"""A small three-legged stool with a last meal on a wooden plate: a crusty loaf with scored cuts and its broken-off
	end showing the crumb, a gnawed meat bone, a knife, and a mug beside it."""
	zs = 0.42
	log((0, 0, zs - 0.06), (0, 0, zs), 0.2, T("bark"), seg=10, rings=1, end_m=kit.tex_mat("wood", "c"))
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.3
		log((math.cos(a) * 0.09, math.sin(a) * 0.09, zs - 0.05), (math.cos(a) * 0.18, math.sin(a) * 0.18, 0.0), 0.035, T("bark"), seg=6, rings=2)
	kit.ring(0.13, 0.012, (0, 0, 0.18), kit.tex_mat("rope"), seg=14)
	zt = zs + 0.012
	plate((-0.03, -0.03, zt), r=0.125)
	zp = zt + 0.015
	crust, crumb = C((0.42, 0.25, 0.1), 0.85), C((0.72, 0.6, 0.4), 0.95)
	loaf = sphere((-0.06, -0.035, zp - 0.002), 0.07, crust, scale=(1.45, 0.95, 0.8), seg=16, rings=9, cut=0.0)
	cuts = [B((0.012, 0.11, 0.03), (-0.1 + i * 0.04, -0.035, zp + 0.058), C((0.3, 0.16, 0.06), 0.9), bevel=0, rot=(0, 0, 25)) for i in range(3)]
	cuts.append(B((0.1, 0.2, 0.2), (0.09, -0.035, zp), crumb, bevel=0))  # the broken end
	carve(loaf, cuts)
	end = sphere((0, 0, 0), 0.05, crust, scale=(0.7, 0.95, 0.8), seg=12, rings=8, cut=0.0)
	carve(end, [B((0.1, 0.2, 0.2), (-0.05, 0, 0), crumb, bevel=0)])
	end.data.transform(Matrix.Rotation(math.radians(90), 4, "Y"))  # lying on its crust, crumb face up
	end.data.transform(Matrix.Rotation(math.radians(30), 4, "Z"))
	end.location = (0.045, -0.08, zp)
	bpy.context.view_layer.update()
	end.location.z += zp - 0.001 - min((end.matrix_world @ v.co).z for v in end.data.vertices)
	bn = kit.mat("bone", -0.12)
	p0, p1 = Vector((0.0, 0.04, zp + 0.016)), Vector((0.08, 0.0, zp + 0.016))
	log(tuple(p0), tuple(p1), 0.011, bn, seg=7, rings=1, ends=False, bend=0)
	side = (p1 - p0).cross(Vector((0, 0, 1))).normalized() * 0.011
	for p in (p0, p1):
		for s_ in (-1, 1):
			sphere(tuple(p + side * s_), 0.016, bn, seg=8, rings=5)
	kit.gem((0.04, 0.02, zp + 0.026), (0.018, 0.012, 0.008), C((0.4, 0.16, 0.1), 0.8), seed=4)  # dried meat left on it
	# knife across the plate edge
	ka = math.radians(-35)
	kx, ky = -0.02, 0.06
	B((0.1, 0.022, 0.004), (kx + math.cos(ka) * 0.05, ky + math.sin(ka) * 0.05, zp + 0.003), IRON("a"), bevel=0.001, rot=(0, 0, math.degrees(ka)))
	B((0.065, 0.02, 0.016), (kx - math.cos(ka) * 0.035, ky - math.sin(ka) * 0.035, zp + 0.008), T("wood", "c"), bevel=0.004, rot=(0, 0, math.degrees(ka)))
	for t in (-0.02, -0.05):
		kit.rivet((kx + math.cos(ka) * t, ky + math.sin(ka) * t, zp + 0.016), CU("b"), r=0.004)
	mug((0.12, 0.1, zt))


def ring_wall(r_in, r_out, z0, z1, m, seg=20):
	"""A thick round wall (a tube with real inner and outer faces)."""
	v = []
	for r, z in ((r_out, z0), (r_out, z1), (r_in, z1), (r_in, z0)):
		v += [(math.cos(2 * math.pi * k / seg) * r, math.sin(2 * math.pi * k / seg) * r, z) for k in range(seg)]
	f = [(j * seg + k, j * seg + (k + 1) % seg, ((j + 1) % 4) * seg + (k + 1) % seg, ((j + 1) % 4) * seg + k) for j in range(4) for k in range(seg)]
	return mesh(v, f, m)


def pit_bucket():
	"""A log pulley frame over a stone-curbed pit: the shaft goes down inside the curb, its stone lining darker the
	deeper it goes; a bucket hangs on its rope over the hole, the rope tied off on a post."""
	for c_, z in enumerate((0.075, 0.225)):  # the curb: two courses of stones round the hole
		for k in range(12):
			a = 2 * math.pi * (k + 0.5 * c_) / 12
			stone((0.22, 0.14, 0.145), (math.cos(a) * 0.43, math.sin(a) * 0.43, z), tone=T("greystone", rng.choice("abc")), rotz=math.degrees(a) + 90)
	ring_wall(0.338, 0.37, 0.17, 0.3, T("greystone", "dark"), seg=20)  # shaft lining, top course
	ring_wall(0.318, 0.342, 0.012, 0.19, C((0.05, 0.05, 0.055), 0.95), seg=20)  # deeper, darker course
	disc(0.32, 0.0, 0.012, (0, 0), C((0.012, 0.012, 0.014), 0.95), seg=16, wob=0.0)  # the black far bottom
	H = 1.6
	for x in (-0.62, 0.62):
		log((x, 0, 0.0), (x * 0.92, 0, H), 0.06, T("bark"), seg=8, rings=3, bend=0.04)
		for s_ in (-1, 1):
			log((x * 1.05, s_ * 0.3, 0.035), (x * 0.95, s_ * 0.035, 0.7), 0.035, T("bark"), seg=6, rings=2)
	log((-0.7, 0, H - 0.04), (0.7, 0, H - 0.04), 0.06, T("bark"), seg=8, rings=2)
	for x in (-0.55, 0.55):
		kit.ring(0.075, 0.014, (x * 1.04, 0, H - 0.04), kit.tex_mat("rope"), rot=(0, 90, 0), seg=12)
	# pulley wheel hanging under the beam
	kit.cylinder(0.11, 0.05, (0.0, 0, H - 0.22), T("wood", "dark"), rot=(90, 0, 0), verts=14, bevel=0.008)
	B((0.04, 0.09, 0.18), (0.0, 0, H - 0.12), IRON("dark"), bevel=0.005)
	kit.cylinder(0.02, 0.1, (0.0, 0, H - 0.22), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	rope = kit.tex_mat("rope")
	zb = 0.5
	log((-0.11, 0, H - 0.22), (-0.11, 0, zb + 0.41), 0.012, rope, seg=5, rings=2, ends=False, bend=0.02)
	log((0.11, 0, H - 0.22), (0.56, 0, 0.75), 0.012, rope, seg=5, rings=2, ends=False, bend=0.02)
	kit.ring(0.065, 0.016, (0.6, 0, 0.75), rope, seg=12)
	# bucket
	kit.cone(0.12, 0.15, 0.26, (-0.11, 0, zb + 0.13), T("wood", "b"), verts=14, bevel=0.01)
	for z in (zb + 0.05, zb + 0.21):
		kit.ring(0.12 + 0.03 * (z - zb) / 0.26 + 0.008, 0.01, (-0.11, 0, z), CU("dark"), seg=16)
	kit.ring(0.15, 0.01, (-0.11, 0, zb + 0.26), IRON("dark"), rot=(90, 0, 0), seg=16)


def coal_pile_shovel():
	"""A heap of coal: many near-black, glossy, sharp-edged lumps of every size piled and settled on a bed of coal
	dust, an old shovel driven into it, a few lumps rolled away."""
	coal = [C((0.028, 0.028, 0.032), 0.22, metal=0.3), C((0.04, 0.039, 0.045), 0.28, metal=0.25), C((0.02, 0.02, 0.024), 0.18, metal=0.35)]
	fill = C((0.022, 0.022, 0.026), 0.25, metal=0.3)  # the core is coal-coloured too, never a matte dome
	before = set(bpy.data.objects)
	h = rubble_heap(0.0, 0.0, 0.62, 0.55, 0.5, coal, n=230, smax=0.13, smin=0.025, dirt=fill, seed=8)
	S, Z = 0.72, 0.86
	hf = lambda x, y: Z * 0.9 * h(x / S, y / S)  # noqa: E731  the shrunk core's height
	for o in set(bpy.data.objects) - before:  # pull the core in and down so the lumps cover it right to the floor (owner, round 2)
		if fill.name in [m.name for m in o.data.materials]:
			for v in o.data.vertices:
				v.co.x *= S
				v.co.y *= S
				v.co.z *= Z
		else:  # and let every lump settle down onto the smaller core (or the floor)
			bpy.context.view_layer.update()
			c = o.matrix_world.translation
			lo = min((o.matrix_world @ v.co).z for v in o.data.vertices)
			bed = max(0.002, hf(c.x, c.y) - 0.006 - 0.012 * ((sum(map(ord, o.name)) % 7) / 7))
			if lo > bed:
				o.location.z -= lo - bed
	bpy.context.view_layer.update()
	lumps = sorted((o for o in set(bpy.data.objects) - before if fill.name not in [m.name for m in o.data.materials]), key=lambda o: o.name)
	info = []
	for o in lumps:
		ws = [o.matrix_world @ v.co for v in o.data.vertices]
		lo_, hi_ = Vector([min(w[i] for w in ws) for i in range(3)]), Vector([max(w[i] for w in ws) for i in range(3)])
		info.append((o, (lo_ + hi_) / 2, max(hi_ - lo_) / 2))
	gone = set()
	for i, (o, c, rr) in enumerate(info):  # two lumps sunk deep into each other show each other's faces (shimmer): keep the bigger
		for o2, c2, rr2 in info[:i]:
			if o2 not in gone and (c - c2).length < 0.5 * (rr + rr2):
				gone.add(o if rr <= rr2 else o2)
				break
	for o in gone:
		bpy.data.objects.remove(o, do_unlink=True)
	r = __import__("random").Random(23)
	for k in range(60):  # the bottom layer: lumps settled on the floor all round the foot of the heap
		a = 2 * math.pi * k / 60 + r.uniform(-0.05, 0.05)
		d = r.uniform(0.66, 0.97)
		s_ = 0.04 + 0.05 * r.random()
		o = kit.gem((math.cos(a) * 0.62 * d, math.sin(a) * 0.55 * d, 0.1), (s_ * 1.1, s_ * 0.9, s_ * 0.7), coal[k % 3], seed=400 + k)
		spin(o, r.uniform(-25, 25), r.uniform(-25, 25), r.uniform(0, 360))
		rest(o)
	for k in range(8):  # lumps rolled away
		a = r.uniform(0, 2 * math.pi)
		s = 0.025 + 0.03 * r.random()
		o = kit.gem((math.cos(a) * 0.7, math.sin(a) * 0.62, 0.1), (s, s * 0.85, s * 0.65), coal[k % 3], seed=300 + k)
		spin(o, r.uniform(-20, 20), r.uniform(-20, 20), r.uniform(0, 360))
		rest(o)
	# melt every lump into one surface (boolean union): lumps sunk into each other leave no faces inside or side by side
	lumps = [o for o in set(bpy.data.objects) - before if o.type == "MESH" and fill.name not in [m.name for m in o.data.materials]]
	lumps.sort(key=lambda o: o.name)
	col = bpy.data.collections.new("coal_union")
	bpy.context.scene.collection.children.link(col)
	for o in lumps[1:]:
		for uc in list(o.users_collection):
			uc.objects.unlink(o)
		col.objects.link(o)
	md = lumps[0].modifiers.new("union", "BOOLEAN")
	md.operation, md.operand_type, md.collection, md.solver = "UNION", "COLLECTION", col, "EXACT"
	md.material_mode = "TRANSFER"
	bpy.context.view_layer.objects.active = lumps[0]
	bpy.ops.object.modifier_apply(modifier=md.name)
	for o in list(col.objects):
		bpy.data.objects.remove(o, do_unlink=True)
	bpy.data.collections.remove(col)
	# shovel: blade buried along the shaft line, shaft and D-grip
	tip, top = Vector((0.12, -0.12, h(0.12, -0.12) * 0.9)), Vector((0.42, -0.3, 1.1))
	d = (top - tip).normalized()
	al, be = math.degrees(math.asin(-d.y)), math.degrees(math.asin(d.x / math.cos(math.asin(-d.y))))
	B((0.24, 0.03, 0.28), tuple(tip - d * 0.12), IRON("dark"), bevel=0.01, rot=(al, be, 0))
	log(tuple(tip), tuple(top), 0.025, T("wood", "b"), seg=7, rings=3, ends=False, bend=0.03)
	log(tuple(tip - d * 0.01), tuple(tip + d * 0.1), 0.034, IRON("dark"), seg=8, rings=1, ends=False, bend=0)
	kit.ring(0.06, 0.016, tuple(top + d * 0.05), T("wood", "b"), rot=(al + 90, be, 0), seg=12)


def cage_floor_open():
	"""A rusted iron floor cage with its door hanging open on one hinge, a padlock dangling, straw and a bone inside."""
	W, H = 1.0, 1.25
	h = W / 2
	corners = [(-h, -h), (h, -h), (h, h), (-h, h)]
	for (x, y) in corners:
		B((0.06, 0.06, H), (x, y, H / 2), OLD_IRON(), bevel=0.008)
	for z in (0.04, H - 0.03):
		for i in range(4):
			(x0, y0), (x1, y1) = corners[i], corners[(i + 1) % 4]
			if z < 0.1 and i == 0:
				continue  # no sill under the door
			B((abs(x1 - x0) + 0.05, abs(y1 - y0) + 0.05, 0.05), ((x0 + x1) / 2, (y0 + y1) / 2, z), OLD_IRON(), bevel=0.006)
	for i in (1, 2, 3):
		(x0, y0), (x1, y1) = corners[i], corners[(i + 1) % 4]
		for k in range(1, 6):
			t = k / 6
			x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
			log((x, y, 0.06), (x + J(0.02), y + J(0.02), H - 0.05), 0.014, OLD_IRON(), seg=6, rings=2, ends=False, bend=0.15)
	for k in range(1, 5):  # roof bars
		x = -h + W * k / 5
		log((x, -h, H - 0.03), (x, h, H - 0.03), 0.013, OLD_IRON(), seg=6, rings=2, ends=False, bend=0.1)
	# floor boards inside
	for i in range(5):
		plank((W - 0.08, W / 5 - 0.02, 0.03), (0, -h + 0.04 + (W - 0.08) / 5 * (i + 0.5), 0.015 + 0.002 * (i % 2)), m=T("wood", "dark"))
	# open door: hinged on the front-left post, swung out towards -Y
	hx, hy = -h + 0.045, -h - 0.04
	ang = math.radians(-115)
	dw, dz0, dz1 = W - 0.08, 0.06, H - 0.08
	ux, uy = math.cos(ang), math.sin(ang)
	far_drop = 0.035
	for k in range(6):
		t = k / 5
		x, y = hx + ux * dw * t, hy + uy * dw * t
		log((x, y, dz0 - far_drop * t), (x, y, dz1 - far_drop * t), 0.014, OLD_IRON(), seg=6, rings=2, ends=False, bend=0.1)
	for z in (dz0, (dz0 + dz1) / 2, dz1):
		log((hx, hy, z), (hx + ux * dw, hy + uy * dw, z - far_drop), 0.018, OLD_IRON(), seg=6, rings=1, ends=False, bend=0)
	for z in (0.2, H - 0.2):
		kit.ring(0.035, 0.012, (hx, hy + 0.01, z), RUST(), seg=10)
	# padlock hanging from the far edge of the door
	lx, ly = hx + ux * dw, hy + uy * dw
	kit.ring(0.035, 0.009, (lx, ly - 0.02, 0.58), IRON("dark"), rot=(0, 90, math.degrees(ang)), seg=10)
	B((0.07, 0.03, 0.08), (lx, ly - 0.02, 0.51), RUST(), bevel=0.01, rot=(0, 0, math.degrees(ang)))
	# straw and a bone inside
	for k in range(14):
		a = J(math.pi)
		x, y = J(0.3), J(0.3)
		B((0.16, 0.012, 0.008), (x, y, 0.038), kit.tex_mat("straw", "a"), bevel=0, rot=(0, 0, math.degrees(a)))
	log((0.15, 0.2, 0.06), (-0.1, 0.25, 0.06), 0.02, kit.mat("bone", -0.05), seg=6, rings=1, ends=False, bend=0)
	for p in ((0.15, 0.2, 0.06), (-0.1, 0.25, 0.06)):
		sphere(p, 0.032, kit.mat("bone", -0.05), scale=(1, 1.3, 1))


def prison_bench():
	"""A stone bench under a masonry wall, two iron chains with cuffs: one hanging, one lying on the seat."""
	W = 1.6
	wall_slab(W, 1.6, 0.18, rows=5)
	yw = -0.18
	# bench: thick stone seat on two blocks
	for x in (-0.5, 0.5):
		stone((0.3, 0.36, 0.38), (x, yw - 0.2, 0.19), bevel=0.03)
	B((1.4, 0.44, 0.1), (0, yw - 0.22, 0.43), T("stone", "b"), bevel=0.03)
	zs = 0.48
	for (x, hang) in ((-0.4, True), (0.35, False)):
		bolt = (x, yw - 0.03, 1.15)
		kit.cylinder(0.035, 0.05, (x, yw - 0.01, 1.15), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.004)
		kit.ring(0.04, 0.011, (x, yw - 0.05, 1.15), RUST(), rot=(0, 90, 0), seg=10)
		top = (x, yw - 0.06, 1.1)
		if hang:
			end = (x, yw - 0.07, 0.72)
			chain(top, end)
			kit.ring(0.05, 0.016, (x, yw - 0.07, 0.66), OLD_IRON(), rot=(90, 0, 0), seg=14)
		else:
			mid = (x + 0.05, yw - 0.12, zs + 0.03)
			chain(top, mid)
			chain(mid, (x + 0.3, yw - 0.25, zs + 0.03), first=False)
			kit.ring(0.05, 0.016, (x + 0.36, yw - 0.29, zs + 0.016), OLD_IRON(), seg=14)
			B((0.05, 0.035, 0.035), (x + 0.36, yw - 0.35, zs + 0.03), RUST(), bevel=0.005)


# ================= Collapse and leftovers =================
def chandelier_fallen():
	"""An iron ring chandelier smashed on the floor: bent ring, a snapped spoke, candles knocked over, chain coiled."""
	Rr = 0.5
	o = kit.ring(Rr, 0.035, (0, 0, 0.035), IRON("dark"), seg=28)
	o.scale = (1, 0.9, 1)
	for k in range(6):
		a = 2 * math.pi * k / 6
		x, y = math.cos(a) * Rr, math.sin(a) * Rr * 0.9
		if k == 4:
			B((0.2, 0.03, 0.03), (x * 0.25, y * 0.25, 0.05), RUST(), bevel=0.004, rot=(0, 0, math.degrees(a)))
			B((0.14, 0.03, 0.03), (x * 0.8, y * 0.8, 0.045), RUST(), bevel=0.004, rot=(0, 12, math.degrees(a) + 20))
		else:
			B((Rr * 0.92, 0.03, 0.03), (x * 0.5, y * 0.5, 0.05), OLD_IRON(), bevel=0.004, rot=(0, 0, math.degrees(a)))
		kit.cylinder(0.045, 0.03, (x, y, 0.08), CU("dark"), verts=8, bevel=0.004)
		if k % 2 == 0:
			kit.cylinder(0.026, 0.05 + 0.02 * (k % 3), (x, y, 0.12 + 0.01 * (k % 3)), WAX(), verts=8, bevel=0.004)
	kit.cylinder(0.08, 0.06, (0, 0, 0.055), IRON("dark"), verts=10, bevel=0.006)
	kit.ring(0.04, 0.012, (0, 0, 0.1), IRON("dark"), rot=(90, 0, 0), seg=10)
	# knocked-over candles and wax drips
	for (x, y, a) in ((0.7, -0.15, 20), (-0.25, -0.62, -50), (0.15, 0.62, 80)):
		kit.cylinder(0.026, 0.12, (x, y, 0.026), WAX(), rot=(90, 0, a), verts=8, bevel=0.004)
		disc(0.05, 0.0, 0.006, (x + 0.02, y + 0.03), WAX(), seg=10, wob=0.25)
	# chain coiled beside it: runs from the hub out to a loose spiral pile
	path = [(0, 0, 0.11), (0.25, 0.25, 0.05), (0.62, 0.38, 0.04)]
	for k in range(14):
		a = k * 0.7
		r = 0.08 + 0.012 * k
		path.append((0.8 + math.cos(a) * r, 0.5 + math.sin(a) * r, 0.04 + 0.025 * (k > 8)))
	for i, (a, b) in enumerate(zip(path, path[1:])):
		chain(a, b, R=0.022, wire=0.008, first=i == 0)
	for k in range(5):
		ground_lump(J(0.3) - 0.75, J(0.3) + 0.3, (0.05, 0.04, 0.025), T("stone"), seed=k)


def table_overturned():
	"""A plank table knocked onto its side, one leg snapped; mugs, a plate and a spilled puddle on the floor."""
	W, D, Hl = 1.3, 0.75, 0.65
	for i in range(4):  # top planks standing on their edge
		plank((W, 0.06, D / 4 - 0.01), (0, 0.3, 0.012 + D / 4 * (i + 0.5)), m=T("wood", rng.choice("abc")))
	for x in (-W / 2 + 0.15, W / 2 - 0.15):
		B((0.08, 0.05, D - 0.06), (x, 0.245, D / 2), T("wood", "dark"), bevel=0.01)
	for (x, z, broken) in ((-W / 2 + 0.15, 0.065, False), (W / 2 - 0.15, 0.065, False), (-W / 2 + 0.15, D - 0.1, False), (W / 2 - 0.15, D - 0.1, True)):
		ln = Hl * (0.45 if broken else 1)
		log((x, 0.25, z), (x, 0.25 - ln, z + J(0.01)), 0.05, T("bark"), seg=7, rings=2, ends=not broken)
		if broken:
			splinters((x, 0.25 - ln, z), (0, -1, 0), n=4, r=0.05)
	B((W - 0.4, 0.04, 0.08), (0, 0.24, D - 0.1), T("wood", "dark"), bevel=0.008)
	log((W / 2 - 0.1, -0.5, 0.046), (W / 2 - 0.2, -0.75, 0.046), 0.045, T("bark"), seg=7, rings=2)  # the snapped leg end
	mug((-0.3, -0.45, 0.0), tipped=True, ang=30)
	mug((0.25, -0.25, 0.0))
	plate((-0.05, -0.75, 0.0))
	sphere((-0.05, -0.75, 0.04), 0.05, C((0.55, 0.38, 0.2), 0.9), scale=(1.2, 1, 0.6))


def ore_crusher_broken():
	"""A wooden trip-hammer ore crusher: its arm snapped at the break, the hammer end lying by the stone block,
	ore chunks spilled around."""
	for y in (-0.3, 0.3):
		log((-0.7, y, 0.07), (0.25, y, 0.07), 0.07, T("bark"), seg=8, rings=3)
		log((-0.3, y, 0.12), (-0.3, y, 1.25), 0.06, T("bark"), seg=8, rings=3, bend=0.04)
		log((-0.65, y, 0.12), (-0.3, y, 0.7), 0.04, T("bark"), seg=6, rings=2)
	log((-0.3, -0.36, 1.25), (-0.3, 0.36, 1.25), 0.06, T("bark"), seg=8, rings=2)
	ax_z = 0.95
	log((-0.3, -0.38, ax_z), (-0.3, 0.38, ax_z), 0.035, IRON("dark"), seg=8, rings=1, ends=False, bend=0)
	# the arm: tail end with counterweight stone, front end snapped and drooping
	log((-0.85, 0, ax_z + 0.12), (-0.3, 0, ax_z), 0.055, T("wood", "b"), seg=7, rings=2, bend=0.03)
	stone((0.2, 0.2, 0.2), (-0.85, 0, ax_z + 0.04))
	kit.ring(0.11, 0.015, (-0.85, 0, ax_z + 0.04), kit.tex_mat("rope"), rot=(0, 90, 0), seg=12)
	end = (0.12, 0, ax_z - 0.2)
	log((-0.3, 0, ax_z), end, 0.055, T("wood", "b"), seg=7, rings=2, ends=False, bend=0.03)
	splinters(end, (0.42, 0, -0.2), n=5, r=0.05)
	kit.ring(0.065, 0.014, (-0.3, 0, ax_z), IRON("dark"), rot=(0, 90, 0), seg=12)
	# the stone block (mortar) and the fallen hammer end
	B((0.42, 0.42, 0.3), (0.55, 0, 0.15), T("stone", "b"), bevel=0.03)
	for k in range(5):
		lump((0.55 + J(0.12), J(0.12), 0.32), (0.05, 0.045, 0.035), T("brownrock", "b") if k % 2 else T("stone", "c"), seed=k, rough=0.01)
	fb = (0.4, -0.55, 0.06)
	log(fb, (0.85, -0.42, 0.06), 0.055, T("wood", "b"), seg=7, rings=2)
	splinters((0.4, -0.55, 0.06), (-0.45, -0.13, 0), n=4, r=0.05)
	B((0.2, 0.18, 0.18), (0.88, -0.41, 0.09), T("wood", "dark"), bevel=0.02)
	for dz in (-0.05, 0.05):
		cband((0.21, 0.19, 0.035), (0.88, -0.41, 0.09 + dz), rivets=2, m=IRON("dark"))
	# spilled ore
	for k in range(9):
		a = rng.uniform(0, 6.28)
		r = rng.uniform(0.28, 0.45)
		ground_lump(0.55 + math.cos(a) * r, math.sin(a) * r, (0.06, 0.05, 0.035),
			[T("stone", "c"), T("brownrock", "b"), C((0.42, 0.3, 0.2), 0.8)][k % 3], seed=k + 20, rough=0.01)
	for k in range(3):
		kit.gem((0.3 + J(0.06), -0.25 + J(0.06) + k * 0.06, 0.022), (0.03, 0.025, 0.02), CU("b"), seed=k + 40)


MODELS = {
	"map_torn_wall": map_torn_wall, "war_drum_split": war_drum_split, "war_horn_stand": war_horn_stand,
	"portcullis_rusted": portcullis_rusted, "floor_grate": floor_grate,
	"cage_floor_open": cage_floor_open, "prison_bench": prison_bench, "hanging_hook": hanging_hook,
	"chandelier_fallen": chandelier_fallen, "table_overturned": table_overturned, "dice_on_crate": dice_on_crate,
	"last_meal": last_meal, "pit_bucket": pit_bucket, 
	"ore_crusher_broken": ore_crusher_broken, "coal_pile_shovel": coal_pile_shovel,
	"tally_marks": tally_marks, "graffiti_pell": graffiti_pell,
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
