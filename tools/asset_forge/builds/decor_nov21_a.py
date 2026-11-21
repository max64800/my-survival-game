# Decor group A (Nov 21): dungeon and ruin story pieces: abandoned, old, worn. Same style as night_decor.py.
#   blender --background --factory-startup --python builds/decor_nov21_a.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (shackles, carvings, pickaxe in wall) have a flat back at +Y so they sit flush on a wall.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, plank, rivet, rng, stone  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import plank_board, rail_track, rope_tie, stone_blocks, wall_post  # noqa: E402

WOOD = lambda: T("wood")  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
BONE = lambda s=0.0: kit.mat("bone", s, rough=0.9)  # noqa: E731
INK = lambda: C((0.16, 0.11, 0.08), 0.95)  # noqa: E731
PAPER = lambda s=0.0: C((0.8 + s, 0.72 + s, 0.55 + s), 0.95)  # noqa: E731
CHAR = lambda s=0.0: kit.mat("charcoal", s, rough=1.0)  # noqa: E731


# ---------------- helpers ----------------
def objs():
	return set(bpy.data.objects)


def slim(small=0.0, fine=0.0, bare=0.0, few=0.0, angle=40):
	"""Lighter files, same look (Nov 21, models under 2 MB): bevels skip the already-soft edges of round parts
	(between faces under `angle` degrees, e.g. a 10-sided cylinder's sides); parts smaller than `small` m and
	bevels no wider than `fine` m get one bevel step; parts smaller than `bare` m (teeth) lose their bevel;
	plain parts (no modifiers) smaller than `few` m (rivets, studs, knobs) keep half their faces."""
	for o in bpy.context.scene.objects:
		if o.type != "MESH":
			continue
		tiny = max(o.dimensions) < small
		if not o.modifiers and max(o.dimensions) < few and len(o.data.polygons) > 24:
			o.modifiers.new("few", "DECIMATE").ratio = 0.5
			continue
		for md in list(o.modifiers):
			if md.type == "BEVEL" and max(o.dimensions) < bare:
				o.modifiers.remove(md)
			elif md.type == "BEVEL":
				if md.limit_method == "ANGLE":
					md.angle_limit = max(md.angle_limit, math.radians(angle))
				if tiny or md.width <= fine:
					md.segments = 1


def turn(group, axis, deg, pivot):
	"""Rotate a group of parts around a pivot point (axis 'X', 'Y' or 'Z')."""
	p = Vector(pivot)
	M = Matrix.Translation(p) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-p)
	for o in group:
		o.matrix_world = M @ o.matrix_world


def shift(group, d):
	for o in group:
		o.location += Vector(d)


def low_z(group):
	return min((o.matrix_world @ v.co).z for o in group if o.type == "MESH" for v in o.data.vertices)


def rod(p0, p1, r, m, seg=6):
	return log(p0, p1, r, m, seg=seg, rings=1, ends=False, bend=0)


def prism(pts, a0, a1, m, axis="y"):
	"""A flat shape (2D outline) given thickness: axis y = outline in (x, z) from y=a0 to a1; axis z = (x, y) outline."""
	n = len(pts)
	if axis == "y":
		v = [(x, a0, z) for x, z in pts] + [(x, a1, z) for x, z in pts]
	elif axis == "x":
		v = [(a0, y, z) for y, z in pts] + [(a1, y, z) for y, z in pts]
	else:
		v = [(x, y, a0) for x, y in pts] + [(x, y, a1) for x, y in pts]
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def circ(cx, cz, r, n=12, sz=1.0, wob=0.04):
	return [(cx + math.cos(2 * math.pi * i / n) * r * (1 + J(wob)), cz + math.sin(2 * math.pi * i / n) * r * sz * (1 + J(wob))) for i in range(n)]


def bar(p0, p1, w0, w1=None):
	"""A thick line (limb, handle, beam) as a 4-point outline."""
	w1 = w0 if w1 is None else w1
	(x0, z0), (x1, z1) = p0, p1
	d = math.hypot(x1 - x0, z1 - z0) or 1
	nx, nz = -(z1 - z0) / d, (x1 - x0) / d
	return [(x0 + nx * w0 / 2, z0 + nz * w0 / 2), (x1 + nx * w1 / 2, z1 + nz * w1 / 2),
		(x1 - nx * w1 / 2, z1 - nz * w1 / 2), (x0 - nx * w0 / 2, z0 - nz * w0 / 2)]


def chain(p0, p1, link=0.035, wire=0.009, m=None):
	"""Iron chain links from p0 to p1, each link turned 90 degrees to the last and overlapping it."""
	a, b = Vector(p0), Vector(p1)
	d = b - a
	n = max(2, int(d.length / (link * 2.0)) + 1)
	q = d.to_track_quat("Z", "Y")
	for i in range(n):
		c = a + d * (i / (n - 1))
		o = kit.ring(link, wire, tuple(c), m or IRON("dark"), seg=10)
		o.rotation_mode = "QUATERNION"
		o.rotation_quaternion = q @ Matrix.Rotation(math.pi / 2 * (i % 2), 4, "Z").to_quaternion() @ Matrix.Rotation(math.pi / 2, 4, "X").to_quaternion()
		o.scale = (1, 1.45, 1)


def floor_cut():
	"""Flatten anything that dips below the floor (rough lumps) so the whole model stands on z = 0."""
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		mw = o.matrix_world.copy()
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.z < 0:
				w.z = 0.0
				v.co = inv @ w


def flat_back_rock(loc, size, m, seed=1, back=0.0):
	"""A rock lump cut flat at the back (y = back) so it sits flush on a wall."""
	o = kit.gem((0, 0, 0), size, m, seed=seed)
	for v in o.data.vertices:
		v.co.y = min(v.co.y, back - loc[1])
		v.co.z = max(v.co.z, -loc[2])  # flat on the floor too
	o.location = loc
	return o


GROOVE_M = lambda: C((0.035, 0.033, 0.03), 0.95)  # noqa: E731  dark walls of a carved groove


def carve(targets, cutters):
	"""Cut `cutters` INTO `targets` (boolean difference): runes, grooves, holes, chips. The cut walls take each
	cutter's material, so give cutters a dark groove colour. Cutters must start in front of the surface."""
	targets = list(targets) if isinstance(targets, (list, tuple, set)) else [targets]
	for o in targets + list(cutters):
		bpy.context.view_layer.objects.active = o
		for m in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=m.name)
	col = bpy.data.collections.new("cutters")
	bpy.context.scene.collection.children.link(col)
	for c in cutters:
		for uc in list(c.users_collection):
			uc.objects.unlink(c)
		col.objects.link(c)
	for t in targets:
		m = t.modifiers.new("carve", "BOOLEAN")
		m.operation, m.operand_type, m.collection, m.solver = "DIFFERENCE", "COLLECTION", col, "EXACT"
		m.material_mode = "TRANSFER"
		bpy.context.view_layer.objects.active = t
		bpy.ops.object.modifier_apply(modifier=m.name)
	for c in list(col.objects):
		bpy.data.objects.remove(c, do_unlink=True)
	bpy.data.collections.remove(col)
	return targets


def groove(p0, p1, y, w=0.014, depth=0.012, m=None):
	"""Cutters for one carved stroke on a front face (front = -Y) from 3 cm in front of it to `depth` deep.
	y may be a function of z (a sloped face): long strokes are then cut in short pieces that follow the face."""
	(x0, z0), (x1, z1) = p0, p1
	n = max(1, int(math.hypot(x1 - x0, z1 - z0) / 0.1) + 1) if callable(y) else 1
	out = []
	for i in range(n):
		xa, za = x0 + (x1 - x0) * i / n, z0 + (z1 - z0) * i / n
		xb, zb = x0 + (x1 - x0) * (i + 1) / n, z0 + (z1 - z0) * (i + 1) / n
		yy = y((za + zb) / 2) if callable(y) else y
		ang = math.degrees(math.atan2(zb - za, xb - xa))
		out.append(B((math.hypot(xb - xa, zb - za) + w * 0.9, depth + 0.03, w), ((xa + xb) / 2, yy + (depth - 0.03) / 2, (za + zb) / 2),
			m or GROOVE_M(), bevel=0, rot=(0, -ang, 0)))
	return out


def groove_path(pts, y, w=0.014, depth=0.012, closed=False, m=None):
	out = []
	for a, b in zip(pts, pts[1:] + (pts[:1] if closed else [])):
		out += groove(a, b, y, w, depth, m)
	return out


def groove_ring(cx, cz, r, y, w=0.014, depth=0.012, n=16):
	return groove_path([(cx + math.cos(2 * math.pi * k / n) * r, cz + math.sin(2 * math.pi * k / n) * r) for k in range(n)], y, w, depth, True)


def rune_row(x0, x1, z, y, h=0.07, w=0.012, depth=0.012, seed=1):
	"""Cutters for a row of made-up dwarf runes (a stem with angled branches), z = row centre."""
	r = __import__("random").Random(seed)
	out = []
	n = max(2, int((x1 - x0) / (h * 0.62)))
	for i in range(n):
		x = x0 + (x1 - x0) * (i + 0.5) / n
		lo, hi = z - h / 2, z + h / 2
		out += groove((x, lo), (x, hi), y, w, depth)
		k = r.randrange(6)
		s_ = r.choice((-1, 1))
		if k == 0:
			out += groove((x, hi - h * 0.15), (x + s_ * h * 0.3, hi - h * 0.45), y, w * 0.9, depth)
		elif k == 1:
			out += groove((x - h * 0.25, z + h * 0.2), (x + h * 0.25, z - h * 0.2), y, w * 0.9, depth)
		elif k == 2:
			out += groove((x, hi), (x + s_ * h * 0.28, hi - h * 0.25), y, w * 0.9, depth)
			out += groove((x, z), (x + s_ * h * 0.28, z - h * 0.25), y, w * 0.9, depth)
		elif k == 3:
			out += groove((x - h * 0.22, hi - h * 0.1), (x + h * 0.22, hi - h * 0.1), y, w * 0.9, depth)
		elif k == 4:
			out += groove((x, z + h * 0.1), (x + s_ * h * 0.28, hi), y, w * 0.9, depth)
			out += groove((x, z + h * 0.1), (x - s_ * h * 0.28, hi), y, w * 0.9, depth)
		else:
			out += groove((x, lo + h * 0.25), (x + s_ * h * 0.3, lo), y, w * 0.9, depth)
	return out


def chip(loc, size, seed=1, m=None):
	"""A cutter that knocks a chip off an edge or corner (the broken face shows fresh, lighter stone)."""
	return kit.gem(loc, size, m or kit.tex_mat("greystone", "a"), seed=seed)


def tube(pts, r0, r1, m, seg=7):
	"""A bendy tube along points, tapering r0 -> r1 (ribs, roots, cords)."""
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
			verts.append(tuple(p + (u * math.cos(a) + v * math.sin(a)) * r))
	faces = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	faces += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	return mesh(verts, faces, m, smooth=True)


def loft_x(stations, m, seg=14):
	"""One solid shape lofted along x through cross-sections (x, width, z_bottom, z_top, squareness 2=round..8=boxy)."""
	verts = []
	for x, w, zb, zt, p in stations:
		zc, hh, e = (zb + zt) / 2, (zt - zb) / 2, 2.0 / p
		for k in range(seg):
			a = 2 * math.pi * (k + 0.5) / seg
			c, s = math.cos(a), math.sin(a)
			verts.append((x, math.copysign(abs(c) ** e, c) * w / 2, zc + math.copysign(abs(s) ** e, s) * hh))
	n = len(stations)
	faces = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	faces += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	return mesh(verts, faces, m)


def rest(o, z=0.002):
	"""Drop or lift a part so its lowest point sits at z (a loose stone resting on the floor)."""
	bpy.context.view_layer.update()
	o.location.z += z - min((o.matrix_world @ v.co).z for v in o.data.vertices)
	return o


def spin(o, rx, ry, rz):
	"""Turn a lump around its own centre (its origin), angles in degrees."""
	o.data.transform(Matrix.Rotation(math.radians(rz), 4, "Z") @ Matrix.Rotation(math.radians(ry), 4, "Y") @ Matrix.Rotation(math.radians(rx), 4, "X"))
	return o


def rubble_heap(cx, cy, rx, ry, H, tones, n=70, smax=0.26, smin=0.05, dirt=None, seed=1):
	"""A settled heap: a dirt fill (open underneath) with many angular stones of different sizes half sunk into it
	and overlapping, big ones low, small ones high. Returns the heap height function h(x, y)."""
	r = __import__("random").Random(seed)

	def h(x, y):
		d = math.hypot((x - cx) / rx, (y - cy) / ry)
		return H * max(0.0, 1 - d) ** 0.85

	rings, segs = 9, 20
	v = [(cx, cy, H * 0.92)]
	for i in range(1, rings + 1):
		t = i / rings * 1.04
		for k in range(segs):
			a = 2 * math.pi * k / segs
			x, y = cx + math.cos(a) * rx * t, cy + math.sin(a) * ry * t
			v.append((x, y, max(0.0, h(x, y) * 0.9 + (r.uniform(-0.02, 0.02) if i < rings else 0))))
	f = [(0, 1 + k, 1 + (k + 1) % segs) for k in range(segs)]
	for i in range(rings - 1):
		a0, a1 = 1 + i * segs, 1 + (i + 1) * segs
		f += [(a0 + k, a1 + k, a1 + (k + 1) % segs, a0 + (k + 1) % segs) for k in range(segs)]
	mesh(v, f, dirt or kit.tex_mat("soil", "b"))
	for i in range(n):
		s = smin + (smax - smin) * (1 - i / n) ** 1.1 * r.uniform(0.7, 1.0)
		for _ in range(20):
			a, d = r.uniform(0, 2 * math.pi), math.sqrt(r.uniform(0, 1)) * (1.0 - 0.6 * (1 - i / n) * 0.3)
			x, y = cx + math.cos(a) * rx * d, cy + math.sin(a) * ry * d
			if h(x, y) > 0.02:
				break
		o = kit.gem((0, 0, 0), (s * r.uniform(0.8, 1.2), s * r.uniform(0.7, 1.05), s * r.uniform(0.45, 0.75)), tones[i % len(tones)], seed=seed * 100 + i)
		spin(o, r.uniform(-25, 25), r.uniform(-25, 25), r.uniform(0, 360))
		o.location = (x, y, h(x, y) * 0.9 + s * 0.12)  # sunk into the dirt fill
		bpy.context.view_layer.update()
		lo = min((o.matrix_world @ vv.co).z for vv in o.data.vertices)
		if lo < 0.002:
			o.location.z += 0.002 - lo
	return h


# ================= models =================
def ancestor_stone_tall():
	"""A tall carved name stone on a stepped plinth: a double border, a medallion with crossed hammers over an
	anvil, a sunken panel of rune rows and a zigzag band, all cut INTO the stone; chipped corners."""
	stone((1.02, 0.52, 0.12), (0, 0, 0.06), tone=T("greystone", "c"), bevel=0.025)
	stone((0.9, 0.42, 0.1), (0, 0, 0.165), tone=T("greystone", "b"), bevel=0.02)
	z0, H, D0, D1, W0, W1 = 0.21, 1.35, 0.24, 0.18, 0.72, 0.6
	slab = kit.taper(W0, D0, W1, D1, H, (0, 0, z0), T("greystone", "b"), bevel=0.02)
	cap = kit.taper(W1 + 0.04, D1 + 0.04, 0.1, 0.12, 0.2, (0, 0, z0 + H - 0.005), T("greystone", "a"), bevel=0.015)

	def front(z):
		return -(D0 + (D1 - D0) * (z - z0) / H) / 2

	def hw(z):
		return (W0 + (W1 - W0) * (z - z0) / H) / 2

	cut = []
	zb, zt = z0 + 0.08, z0 + H - 0.07
	for ins, w in ((0.04, 0.016), (0.075, 0.008)):  # double border following the tapered edges
		pts = [(-hw(zb) + ins, zb + ins - 0.04), (hw(zb) - ins, zb + ins - 0.04), (hw(zt) - ins, zt - ins + 0.04), (-hw(zt) + ins, zt - ins + 0.04)]
		cut += groove_path(pts, front, w, 0.012, closed=True)
	for (sx, z) in ((-1, zb + 0.015), (1, zb + 0.015), (-1, zt - 0.015), (1, zt - 0.015)):  # little diamonds in the border corners
		x = sx * (hw(z) - 0.057)
		cut += groove_path([(x, z + 0.018), (x + 0.018, z), (x, z - 0.018), (x - 0.018, z)], front, 0.007, 0.01, closed=True)
	# medallion: ring, crossed hammers over an anvil
	mz = z0 + H - 0.24
	cut += groove_ring(0, mz, 0.13, front, 0.016, 0.014, n=20)
	cut += groove_ring(0, mz, 0.105, front, 0.007, 0.01, n=20)
	for s_ in (-1, 1):
		cut += groove((s_ * 0.06, mz - 0.06), (-s_ * 0.05, mz + 0.05), front, 0.014, 0.014)  # handle
		hx, hz = -s_ * 0.05, mz + 0.05
		cut += groove((hx - 0.03, hz - s_ * 0.03), (hx + 0.03, hz + s_ * 0.03), front, 0.03, 0.016)  # hammer head
	cut += groove_path([(-0.06, mz - 0.07), (0.06, mz - 0.07), (0.035, mz - 0.085), (0.02, mz - 0.085)], front, 0.014, 0.014)  # anvil top
	cut += groove((-0.03, mz - 0.092), (0.03, mz - 0.092), front, 0.012, 0.012)
	# sunken name panel with rune rows cut deeper into it, a ruling line under each row
	pz0, pz1 = z0 + 0.26, z0 + H - 0.42
	px = hw((pz0 + pz1) / 2) - 0.12
	for k in range(4):  # the panel is cut in 4 bands so it follows the sloped face
		za, zb_ = pz0 + (pz1 - pz0) * k / 4, pz0 + (pz1 - pz0) * (k + 1) / 4
		zm = (za + zb_) / 2
		cut.append(B((2 * px, 0.036, zb_ - za + 0.002), (0, front(zm) + (0.006 - 0.03) / 2, zm), T("greystone", "dark"), bevel=0))
	rows = 6
	for i in range(rows):
		z = pz1 - 0.06 - i * (pz1 - pz0 - 0.08) / (rows - 0.6)
		yr = lambda zz: front(zz) + 0.006  # noqa: E731  the panel floor
		cut += rune_row(-px + 0.03, px - 0.03 - (0.12 if i == rows - 1 else 0), z, yr, h=0.065, w=0.012, depth=0.01, seed=17 + i)
		cut += groove((-px + 0.02, z - 0.047), (px - 0.02, z - 0.047), yr, 0.005, 0.006)
	# zigzag band near the foot
	zz = z0 + 0.14
	pts = [(-hw(zz) + 0.1 + i * 0.045, zz + (0.022 if i % 2 else -0.022)) for i in range(int((2 * hw(zz) - 0.2) / 0.045) + 1)]
	cut += groove_path(pts, front, 0.011, 0.011)
	# chips off the corners and edges
	for k, (x, y, z, s) in enumerate(((-hw(z0 + H) + 0.01, front(z0 + H) + 0.01, z0 + H - 0.04, 0.06), (hw(z0 + 0.6) - 0.005, front(z0 + 0.6), z0 + 0.6, 0.05),
			(-hw(z0 + 0.3), -front(z0 + 0.3) - 0.01, z0 + 0.3, 0.05), (hw(z0 + 1.1), front(z0 + 1.1) + 0.02, z0 + 1.1, 0.04))):
		cut.append(chip((x, y, z), (s, s * 0.7, s * 0.9), seed=k + 3))
	carve(slab, cut)
	carve(cap, [chip((0.1, -0.1, z0 + H + 0.05), (0.05, 0.05, 0.05), seed=9), chip((-0.05, 0.08, z0 + H + 0.12), (0.04, 0.04, 0.04), seed=11)])


def ancestor_stone_small():
	"""A small name slab on a ledge stone: carved border, a ring with a hammer, three rune lines cut in, chipped
	corners; three burned-down candles on the ledge."""
	stone((0.62, 0.42, 0.12), (0, 0, 0.06), tone=T("greystone", "c"), bevel=0.02)
	z0, H, D0, D1, W0, W1, yc = 0.11, 0.55, 0.13, 0.11, 0.42, 0.36, 0.11
	slab = kit.taper(W0, D0, W1, D1, H, (0, yc, z0), T("greystone", "b"), bevel=0.015)
	top = B((0.4, 0.15, 0.07), (0, yc, z0 + H + 0.03), T("greystone", "a"), bevel=0.02)

	def front(z):
		return yc - (D0 + (D1 - D0) * (z - z0) / H) / 2

	def hw(z):
		return (W0 + (W1 - W0) * (z - z0) / H) / 2

	cut = []
	zb, zt = z0 + 0.05, z0 + H - 0.03
	for ins, w in ((0.028, 0.012), (0.052, 0.006)):
		pts = [(-hw(zb) + ins, zb + ins - 0.028), (hw(zb) - ins, zb + ins - 0.028), (hw(zt) - ins, zt - ins + 0.028), (-hw(zt) + ins, zt - ins + 0.028)]
		cut += groove_path(pts, front, w, 0.01, closed=True)
	mz = z0 + H - 0.12
	cut += groove_ring(0, mz, 0.055, front, 0.01, 0.01, n=14)
	cut += groove((0, mz - 0.035), (0, mz + 0.02), front, 0.01, 0.011)  # hammer handle
	cut += groove((-0.025, mz + 0.025), (0.025, mz + 0.025), front, 0.022, 0.012)  # hammer head
	for i, z in enumerate((z0 + 0.29, z0 + 0.21, z0 + 0.135)):
		x1 = hw(z) - 0.075 - (0.06 if i == 2 else 0)
		cut += rune_row(-hw(z) + 0.075, x1, z, front, h=0.05, w=0.009, depth=0.009, seed=41 + i)
		cut += groove((-hw(z) + 0.07, z - 0.035), (hw(z) - 0.07, z - 0.035), front, 0.004, 0.005)
	for k, (x, z, s) in enumerate(((-hw(z0 + H) + 0.01, z0 + H - 0.02, 0.04), (hw(z0 + 0.2), z0 + 0.2, 0.035), (hw(z0 + 0.45) - 0.005, z0 + 0.45, 0.03))):
		cut.append(chip((x, front(z) + 0.005, z), (s, s * 0.7, s * 0.9), seed=k + 5))
	carve(slab, cut)
	carve(top, [chip((0.19, yc - 0.07, z0 + H + 0.06), (0.04, 0.035, 0.04), seed=21), chip((-0.2, yc + 0.06, z0 + H + 0.06), (0.035, 0.035, 0.03), seed=22)])
	wax = C((0.86, 0.8, 0.64), 0.7)
	for k, (x, y, h) in enumerate(((-0.2, -0.09, 0.05), (0.0, -0.13, 0.03), (0.2, -0.07, 0.065))):
		ztop = 0.115 + h
		kit.cylinder(0.035 - k * 0.004, h + 0.01, (x, y, 0.115 + h / 2 - 0.005), wax, verts=9, bevel=0.004)
		kit.cylinder(0.055, 0.008, (x + 0.01, y - 0.005, 0.117), C((0.82, 0.76, 0.6), 0.7), verts=11, bevel=0.002)  # wax puddle
		kit.cylinder(0.004, 0.025, (x, y, ztop + 0.008), CHAR(), verts=5, bevel=0)  # burnt wick
		for d in range(2):
			sphere((x + 0.015 * (d * 2 - 1), y - 0.03, ztop - 0.02 - d * 0.01), 0.012, wax, scale=(1, 0.8, 1.8), seg=8, rings=5)


def paper(pts, y, m, t=0.006):
	"""A sheet of paper (outline in x, z) whose back is pressed 2 mm into the board face at y."""
	return prism(pts, y + 0.002, y - t, m)


def notice_board_torn():
	"""A plank notice board on two posts under a little roof, torn notes nailed on, one WANTED note with a monster sketch."""
	for x in (-0.6, 0.6):
		stone((0.24, 0.24, 0.1), (x, 0, 0.05))
		log((x, 0, 0.08), (x + J(0.01), 0, 1.75), 0.06, T("bark"), seg=8, rings=2)
	for k in range(5):  # board planks, front face at y = -0.065
		plank((1.14, 0.04, 0.14), (0, -0.045, 0.82 + k * 0.15))
	for z in (0.84, 1.36):
		B((1.3, 0.05, 0.08), (0, 0.035, z), T("wood", "dark"), bevel=0.01)  # battens behind, on the posts
	for s_ in (-1, 1):
		B((0.75, 0.42 + 0.02 * s_, 0.04), (s_ * 0.3, 0, 1.85), T("wood", "c"), bevel=0.01, rot=(0, s_ * 20, 0))
	B((0.08, 0.5, 0.08), (0, 0, 1.97), T("wood", "dark"), bevel=0.01)
	fy = -0.065
	notes = [((-0.42, 1.18), 0.22, 0.28, 8, 0.03), ((0.38, 1.2), 0.2, 0.24, -6, 0.04), ((-0.35, 0.86), 0.18, 0.14, 12, 0.0),
		((0.42, 0.88), 0.16, 0.2, -4, 0.06)]
	for k, ((cx, cz), w, h, a, tear) in enumerate(notes):
		ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
		raw = [(-w / 2, h / 2), (w / 2, h / 2), (w / 2, -h / 2 + tear)]
		for i in range(5):  # torn ragged bottom
			raw.append((w / 2 - w * (i + 1) / 6, -h / 2 + (0.03 if i % 2 else -0.0) + tear * (i / 5)))
		raw.append((-w / 2, -h / 2))
		pts = [(cx + x * ca - z * sa, cz + x * sa + z * ca) for x, z in raw]
		paper(pts, fy, PAPER(-0.05 * (k % 3)))
		for i in range(3):  # faded writing lines
			lz = h / 2 - 0.06 - i * 0.045
			if lz < -h / 2 + 0.05:
				break
			p0 = (cx - w * 0.35 * ca - lz * sa, cz - w * 0.35 * sa + lz * ca)
			p1 = (cx + w * 0.3 * ca - lz * sa, cz + w * 0.3 * sa + lz * ca)
			prism(bar(p0, p1, 0.012), fy - 0.004, fy - 0.009, C((0.45, 0.38, 0.3), 0.95))
		rivet((cx - h / 2 * sa, fy - 0.01, cz + h / 2 * ca - 0.02), IRON("dark"))
	# torn scrap left under a nail
	paper([(-0.02, 1.4), (0.08, 1.41), (0.05, 1.33), (0.02, 1.36), (-0.03, 1.32)], fy, PAPER(-0.08))
	rivet((0.02, fy - 0.01, 1.385), IRON("dark"))
	# the WANTED note, in the middle
	cx, cz, w, h = 0.0, 1.08, 0.32, 0.4
	paper([(cx - w / 2, cz + h / 2), (cx + w / 2, cz + h / 2 - 0.01), (cx + w / 2 + 0.01, cz - h / 2 + 0.04), (cx + 0.06, cz - h / 2 + 0.02),
		(cx + 0.02, cz - h / 2 + 0.06), (cx - 0.03, cz - h / 2), (cx - w / 2, cz - h / 2 + 0.01)], fy, PAPER(0.04))
	pf = fy - 0.004
	red = C((0.5, 0.12, 0.08), 0.9)
	for i in range(6):  # big title "word" of chunky strokes
		x = cx - 0.12 + i * 0.048
		prism(bar((x, cz + 0.13), (x + 0.012 * (1 if i % 2 else -1), cz + 0.17), 0.016), pf, pf - 0.005, red)
	ink = INK()
	prism(circ(cx, cz - 0.02, 0.085, n=14, sz=0.8, wob=0.12), pf, pf - 0.004, C((0.55, 0.47, 0.38), 0.95))  # monster body smudge
	for s_ in (-1, 1):
		prism(circ(cx + s_ * 0.03, cz + 0.0, 0.016, n=8), pf - 0.004, pf - 0.008, ink)  # eyes
		prism([(cx + s_ * 0.05, cz + 0.04), (cx + s_ * 0.1, cz + 0.11), (cx + s_ * 0.07, cz + 0.035)], pf - 0.004, pf - 0.008, ink)  # horns
		for j in range(2):  # legs
			lx = cx + s_ * (0.03 + j * 0.035)
			prism(bar((lx, cz - 0.07), (lx + s_ * 0.03, cz - 0.13), 0.012), pf - 0.004, pf - 0.008, ink)
	teeth = [(cx - 0.05, cz - 0.04)]
	for i in range(6):
		teeth.append((cx - 0.05 + (i + 1) * 0.0167, cz - 0.04 - (0.02 if i % 2 == 0 else 0)))
	teeth += [(cx + 0.05, cz - 0.05), (cx - 0.05, cz - 0.05)]
	prism(teeth, pf - 0.004, pf - 0.008, ink)
	for i in range(4):  # reward coins at the bottom
		prism(circ(cx - 0.09 + i * 0.045, cz - 0.15, 0.014, n=8), pf, pf - 0.005, C((0.6, 0.45, 0.15), 0.6))
	for x in (cx - w / 2 + 0.02, cx + w / 2 - 0.02):
		rivet((x, fy - 0.01, cz + h / 2 - 0.02), IRON("dark"))


def hanging_cage():
	"""An iron cage on a ceiling chain, its door hanging open, a few old bones on its floor."""
	R, H = 0.36, 1.0
	m = IRON("dark")
	kit.cylinder(R + 0.02, 0.05, (0, 0, 0.025), IRON("a"), verts=16, bevel=0.008)
	kit.ring(R + 0.01, 0.018, (0, 0, 0.055), m, seg=20)
	kit.ring(R, 0.018, (0, 0, H), m, seg=20)
	kit.ring(R * 0.97, 0.016, (0, 0, H * 0.5), m, seg=20)
	n = 12
	for k in range(n):
		a = 2 * math.pi * k / n
		if k in (0, 1):
			continue  # the open door gap (front-right)
		x, y = math.cos(a) * R, math.sin(a) * R
		rod((x, y, 0.04), (x * 0.98, y * 0.98, H + 0.01), 0.013, m)
		rod((x, y, H), (math.cos(a) * 0.05, math.sin(a) * 0.05, H + 0.32), 0.012, m)  # dome bars
	for k in (0, 1):
		a = 2 * math.pi * k / n
		rod((math.cos(a) * R, math.sin(a) * R, H), (math.cos(a) * 0.05, math.sin(a) * 0.05, H + 0.32), 0.012, m)
	kit.cylinder(0.07, 0.06, (0, 0, H + 0.33), IRON("a"), verts=10, bevel=0.006)
	kit.ring(0.05, 0.014, (0, 0, H + 0.41), m, rot=(90, 0, 0), seg=12)
	# the door: hinged on the bar at angle -30 deg, swung out toward the front
	a0 = 2 * math.pi * (n - 1) / n
	hx, hy = math.cos(a0) * R, math.sin(a0) * R
	ex, ey = hx + 0.12, hy - 0.42
	for z in (0.12, 0.5, 0.9):
		rod((hx, hy, z), (ex, ey, z), 0.013, m)
	for t in (0.5, 1.0):
		px, py = hx + (ex - hx) * t, hy + (ey - hy) * t
		rod((px, py, 0.1), (px, py, 0.92), 0.012, m)
	B((0.06, 0.03, 0.09), (ex - 0.01, ey + 0.02, 0.5), IRON("a"), bevel=0.006)  # lock plate
	# chain up to a ceiling plate
	chain((0, 0, H + 0.44), (0, 0, H + 1.38), link=0.035)
	B((0.3, 0.3, 0.05), (0, 0, H + 1.45), IRON("a"), bevel=0.01)
	for (x, y) in ((-0.11, -0.11), (0.11, -0.11), (-0.11, 0.11), (0.11, 0.11)):
		rivet((x, y, H + 1.42), IRON("dark"))
	# bones on the floor
	for k, (x, y, rz) in enumerate(((-0.1, 0.08, 30), (0.08, -0.05, -20))):
		log((x - 0.1, y - 0.03, 0.065), (x + 0.1, y + 0.03, 0.065), 0.016, BONE(-0.05 * k), seg=6, rings=1, ends=False, bend=0)
		for e in (-1, 1):
			sphere((x + e * 0.1, y + e * 0.03, 0.07), 0.024, BONE(-0.05 * k), seg=8, rings=5)
	sphere((-0.15, -0.15, 0.1), 0.06, BONE(-0.08), scale=(1, 1.15, 0.9))


def wall_shackles():
	"""A plank wall plate with two iron rings; the chains hang straight down under their weight to two cuffs. Flat back at +Y."""
	wall_post(1.2)
	plank_board(0.8, 0.3, 1.3)
	for s_ in (-1, 1):
		x = s_ * 0.24
		B((0.09, 0.02, 0.09), (x, -0.01, 1.3), IRON("a"), bevel=0.004)  # bolt plate
		rivet((x, -0.025, 1.3), IRON("dark"), r=0.02)
		kit.ring(0.04, 0.011, (x, -0.045, 1.265), IRON("dark"), rot=(0, 90, 0), seg=10)  # eye ring hanging from the bolt
		chain((x, -0.045, 1.225), (x, -0.045, 0.86), link=0.03, wire=0.008)
		cz = 0.775
		kit.ring(0.065, 0.02, (x, -0.045, cz), IRON("dark"), rot=(90, 0, 0), seg=14)  # the cuff, hanging plumb
		B((0.04, 0.05, 0.035), (x, -0.045, cz + 0.075), IRON("a"), bevel=0.005)  # hinge knuckle at the top
		B((0.035, 0.045, 0.03), (x, -0.045, cz - 0.075), IRON("a"), bevel=0.005)  # lock lug at the bottom


def forge_bellows_broken():
	"""Old forge bellows on a stone block: the top board pried up and split, its pleated leather side torn open
	at the back, an iron nozzle and hinge strap at the front."""
	stone((0.72, 0.52, 0.24), (0, 0, 0.12), tone=T("greystone", "b"), bevel=0.03)
	B((0.66, 0.48, 0.2), (0, 0, 0.335), T("greystone", "c"), bevel=0.03)  # level top for the bellows
	top = 0.44
	paddle = [(0.0, -0.33), (0.08, -0.25), (0.2, -0.05), (0.22, 0.1), (0.15, 0.2), (0.0, 0.23), (-0.15, 0.2), (-0.22, 0.1),
		(-0.2, -0.05), (-0.08, -0.25)]
	pad = [(x * (1 + J(0.02)), y) for x, y in paddle]
	prism(pad, top - 0.005, top + 0.035, T("wood", "b"), axis="z")  # bottom board
	rod((0, 0.2, top + 0.015), (0, 0.42, top + 0.015), 0.017, T("wood", "c"))  # bottom handle, set into the board
	ang, hy, hz = 14, -0.3, top + 0.06
	before = objs()
	board = prism(pad, top + 0.06, top + 0.095, T("wood", "a"), axis="z")  # top board
	rod((0, 0.2, top + 0.078), (0, 0.4, top + 0.078), 0.017, T("wood", "c"))
	for (x, y) in ((-0.1, -0.12), (0.1, -0.12), (-0.12, 0.1), (0.12, 0.1)):
		rivet((x, y, top + 0.098), IRON("dark"), r=0.014)
	upper = objs() - before
	carve(board, [prism([(0.03, -0.12), (0.05, -0.02), (0.035, 0.08), (0.06, 0.24), (0.075, 0.24), (0.05, 0.08), (0.065, -0.02), (0.04, -0.12)],
		top + 0.075, top + 0.12, CHAR(-0.3), axis="z")])  # split along the grain
	turn(upper, "X", ang, (0, hy, hz))  # board pried up, back end raised
	lea = kit.tex_mat("leather", "b")
	t = math.tan(math.radians(ang))
	# pleated leather wall between the boards, torn open over the back
	ring = [(x * 0.94, y * 0.94 + 0.005) for x, y in pad]
	pts = []
	for (x0, y0), (x1, y1) in zip(ring, ring[1:] + ring[:1]):
		for k in range(3):
			f = k / 3
			x, y = x0 + (x1 - x0) * f, y0 + (y1 - y0) * f
			pin = 0.97 if k % 2 else 1.0
			pts.append((x * pin, y * pin if y > -0.25 else y))
	keep = [p for p in pts if not (p[1] > 0.05 and p[0] < 0.12)]  # the torn-open part
	vs, fs = [], []
	for x, y in keep:
		zt = hz + (y - hy) * t - 0.006
		vs += [(x, y, top + 0.03), (x, y, zt - (0.02 if y > 0.0 else 0.0))]
	for i in range(len(keep) - 1):
		if math.hypot(keep[i + 1][0] - keep[i][0], keep[i + 1][1] - keep[i][1]) > 0.12:
			continue
		a = 2 * i
		fs.append((a, a + 2, a + 3, a + 1))
	o = mesh(vs, fs, lea)
	sol = o.modifiers.new("t", "SOLIDIFY")
	sol.thickness = 0.008
	# nozzle, its clamp ring and the iron hinge strap holding the two boards at the front
	kit.cone(0.04, 0.018, 0.18, (0, -0.42, top + 0.047), IRON("a"), rot=(90, 0, 0), verts=10)
	kit.ring(0.045, 0.012, (0, -0.335, top + 0.047), IRON("dark"), rot=(90, 0, 0), seg=10)
	for s_ in (-1, 1):
		B((0.03, 0.05, 0.075), (s_ * 0.07, -0.285, top + 0.047), IRON("dark"), bevel=0.005)
		rivet((s_ * 0.07, -0.311, top + 0.065), IRON("a"), r=0.01)


def forge_anvil_cracked():
	"""A cracked anvil on a tree stump: body, horn and heel are one clean forged shape, a deep crack cut across the
	face and down the side, hardy and pritchel holes, a heap of glassy slag beside it."""
	log((0, 0, 0), (0, 0, 0.45), 0.24, T("bark"), seg=12, rings=2, bend=0.03, end_m=kit.tex_mat("wood", "c"))
	for z in (0.1, 0.36):
		kit.ring(0.245, 0.012, (0, 0, z), IRON("dark"), seg=20)
	z = 0.46
	m = IRON("dark")
	B((0.42, 0.28, 0.06), (0, 0, z + 0.025), m, bevel=0.012)  # foot plate
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.1, 0.08, 0.05), (sx * 0.16, sy * 0.1, z + 0.065), m, bevel=0.01)  # four feet
	kit.taper(0.3, 0.2, 0.17, 0.13, 0.16, (0, 0, z + 0.05), m, bevel=0.01)  # waist
	zf = z + 0.33
	zb = z + 0.2
	st = [(-0.54, 0.006, zf - 0.075, zf - 0.068, 2), (-0.5, 0.025, zf - 0.08, zf - 0.055, 2), (-0.44, 0.05, zf - 0.085, zf - 0.04, 2.2),
		(-0.36, 0.085, zf - 0.095, zf - 0.03, 2.4), (-0.27, 0.12, zb + 0.01, zf - 0.028, 2.8), (-0.19, 0.16, zb, zf - 0.026, 3.5),
		(-0.165, 0.18, zb, zf - 0.026, 5), (-0.155, 0.19, zb, zf, 8), (0.25, 0.19, zb, zf, 8), (0.28, 0.17, zb + 0.02, zf, 7),
		(0.33, 0.13, zb + 0.05, zf - 0.004, 6), (0.345, 0.1, zb + 0.065, zf - 0.008, 5)]
	body = loft_x(st, IRON("a"), seg=16)
	crack = prism([(0.02, -0.12), (0.045, -0.05), (0.025, 0.0), (0.05, 0.06), (0.035, 0.12), (0.045, 0.12), (0.06, 0.06), (0.035, 0.0),
		(0.055, -0.05), (0.03, -0.12)], zf - 0.06, zf + 0.03, CHAR(-0.3), axis="z")
	side = prism([(0.02, zf + 0.01), (0.045, zf - 0.04), (0.02, zf - 0.09), (0.03, zf - 0.09), (0.055, zf - 0.04), (0.03, zf + 0.01)],
		-0.13, -0.08, CHAR(-0.3), axis="y")
	hardy = B((0.035, 0.035, 0.1), (0.2, 0.0, zf), CHAR(-0.3), bevel=0)
	pritchel = kit.cylinder(0.012, 0.1, (0.13, 0.045, zf), CHAR(-0.3), verts=8, bevel=0)
	carve(body, [crack, side, hardy, pritchel])
	# slag heap next to the stump
	sl = (CHAR(0.2), T("basalt", "dark"), C((0.2, 0.15, 0.12), 0.4), kit.tex_mat("iron", "dark"))
	for k in range(11):
		a = k * 2.3
		r = 0.12 * (k % 4) / 3
		s = 0.08 - r * 0.2
		h = 0.05 if k < 7 else 0.12
		lump((0.5 + math.cos(a) * r, -0.12 + math.sin(a) * r, h), (s, s * 0.9, s * 0.7), sl[k % 4], seed=k + 1, rough=0.01)
	floor_cut()


def skeleton_with_note():
	"""A dwarf skeleton slumped dead against a low stone slab: torso sagged to one side, head fallen forward with
	the jaw hanging open, one arm dropped to the floor, the other limp in its lap on a rolled note, legs sprawled.
	Ribs, spine, finger and foot bones are all separate. Helmet still on."""
	stone((0.95, 0.24, 0.42), (0, 0.22, 0.21), tone=T("greystone", "b"), bevel=0.03)
	stone((0.4, 0.2, 0.12), (0.25, 0.22, 0.47), tone=T("greystone", "b"), bevel=0.025)
	bn, bn2 = BONE(-0.18), BONE(-0.28)  # old, yellowed bone
	V = Vector

	def bone(p0, p1, r=0.016, m=bn, knob=1.5):
		log(tuple(p0), tuple(p1), r, m, seg=7, rings=1, ends=False, bend=0)
		for p in (p0, p1):
			sphere(tuple(p), r * knob, m, seg=8, rings=5)

	def pair(p0, p1, r, side, m=bn):
		"""Two side-by-side bones (forearm, shin)."""
		off = V(side).normalized() * r * 0.9
		bone(V(p0) + off, V(p1) + off, r, m, knob=1.35)
		bone(V(p0) - off, V(p1) - off, r * 0.55, bn2, knob=1.5)

	def hand(w, fwd, side, droop=0.35):
		w, fwd, side = V(w), V(fwd).normalized(), V(side).normalized()
		down = V((0, 0, -1))
		sphere(tuple(w), 0.018, bn2, scale=(1.2, 1.2, 0.6), seg=8, rings=5)  # wrist bones
		for i in range(5):
			o = side * (i - 2) * 0.011
			base = w + fwd * 0.012 + o * 0.5
			if i == 0:  # thumb
				base, d = w + side * -0.02, (fwd * 0.6 - side * 0.8).normalized()
			else:
				d = fwd
			tip = base + d * 0.04 + o * 0.4
			bone(base, tip, 0.0045, bn, knob=1.5)
			p = tip
			for j, ln in enumerate((0.022, 0.016, 0.012)[: 2 if i == 0 else 3]):
				c = min(1.0, droop * (j + 1))
				dd = (d * (1 - c) + down * c).normalized()
				q = p + dd * ln
				if q.z < 0.006:
					q.z = 0.006
				bone(p, q, 0.004 - j * 0.0005, bn, knob=1.4)
				p = q

	def foot(a, fwd, side):
		a, fwd, side = V(a), V(fwd).normalized(), V(side).normalized()
		sphere(tuple(a - fwd * 0.03), 0.026, bn2, scale=(1.2, 1.2, 0.9), seg=8, rings=5)  # heel
		for i in range(5):
			b0 = a + side * (i - 2) * 0.014
			b1 = b0 + fwd * 0.07 + side * (i - 2) * 0.006
			bone(b0, b1, 0.006, bn, knob=1.4)
			bone(b1, b1 + fwd * 0.025, 0.005, bn, knob=1.3)

	# pelvis on the floor
	sphere((0, 0.045, 0.11), 0.038, bn, scale=(1, 0.7, 1.3), seg=10, rings=6)  # sacrum
	for s_ in (-1, 1):
		sphere((s_ * 0.075, 0.02, 0.12), 0.055, bn, scale=(0.55, 1.0, 1.05), seg=10, rings=6)  # hip wings
		sphere((s_ * 0.085, -0.01, 0.08), 0.03, bn2, seg=8, rings=5)  # sockets
		log((s_ * 0.075, -0.02, 0.075), (0, -0.055, 0.065), 0.014, bn, seg=6, rings=1, ends=False, bend=0)
	# torso, built upright, then sagged forward and to the right
	before = objs()
	for i in range(10):
		z = 0.155 + i * 0.03
		sphere((0, 0.06, z), 0.02, bn2 if i % 2 else bn, scale=(1.3, 1.0, 0.72), seg=8, rings=5)  # vertebrae
		B((0.055, 0.012, 0.01), (0, 0.068, z), bn, bevel=0.003)  # side spurs
	for i in range(7):
		z = 0.25 + i * 0.026
		rx = 0.07 + 0.04 * math.sin(math.pi * (i + 1.5) / 8.5)
		ry = 0.055 + 0.008 * math.sin(math.pi * (i + 1) / 8)
		reach = 150 if i > 1 else 110  # the lowest two are short floating ribs
		for s_ in (-1, 1):
			pts = []
			for k in range(8):
				ph = math.radians(10 + (reach - 10) * k / 7)
				pts.append((s_ * rx * math.sin(ph), 0.06 - ry * (1 - math.cos(ph)), z - 0.045 * ph / math.pi))
			if i > 1:
				pts.append((s_ * 0.017, -0.052, z - 0.05))
			tube(pts, 0.0075, 0.006, bn if (i + s_) % 2 else bn2, seg=6)
	B((0.032, 0.016, 0.15), (0, -0.055, 0.33), bn, bevel=0.006)  # breastbone
	for s_ in (-1, 1):
		bone((s_ * 0.02, -0.05, 0.405), (s_ * 0.135, 0.04, 0.425), 0.009, bn)  # collarbones
		sphere((s_ * 0.08, 0.082, 0.37), 0.05, bn2, scale=(1, 0.22, 1.25), seg=10, rings=6)  # shoulder blades
		sphere((s_ * 0.14, 0.045, 0.425), 0.024, bn, seg=8, rings=5)  # shoulder joints
	for i in range(3):
		sphere((0, 0.055 - i * 0.008, 0.46 + i * 0.024), 0.016, bn2, scale=(1.2, 1, 0.75), seg=8, rings=5)  # neck
	torso = objs() - before
	piv = V((0, 0.06, 0.13))
	M = Matrix.Translation(piv) @ Matrix.Rotation(math.radians(12), 4, "X") @ Matrix.Rotation(math.radians(16), 4, "Y") @ Matrix.Translation(-piv)
	for o in torso:
		o.matrix_world = M @ o.matrix_world

	def tp(p):
		return M @ V(p)

	# skull, helmet still on, fallen forward and sideways, jaw hanging open
	N = tp((0, 0.04, 0.5))
	c = N + V((0, -0.01, 0.09))
	before = objs()
	cran = sphere(tuple(c), 0.085, bn, scale=(0.92, 1.08, 0.95), seg=14, rings=9)
	maxi = sphere(tuple(c + V((0, -0.058, -0.055))), 0.045, bn, scale=(1.1, 0.8, 0.7), seg=10, rings=6)
	cuts = [sphere(tuple(c + V((s_ * 0.033, -0.088, -0.008))), 0.025, CHAR(-0.4), seg=8, rings=5) for s_ in (-1, 1)]
	cuts.append(sphere(tuple(c + V((0, -0.098, -0.045))), 0.013, CHAR(-0.4), scale=(0.8, 1, 1.4), seg=8, rings=5))
	carve([cran, maxi], cuts)
	for s_ in (-1, 1):
		sphere(tuple(c + V((s_ * 0.052, -0.06, -0.03))), 0.019, bn, scale=(1.2, 0.8, 0.7), seg=8, rings=5)  # cheekbones
	for k in range(8):
		a = math.radians(-60 + k * 120 / 7)
		B((0.011, 0.01, 0.016), tuple(c + V((math.sin(a) * 0.034, -0.088 + (1 - math.cos(a)) * 0.03, -0.083))), bn, bevel=0.002)  # upper teeth
	jaw0 = objs()
	hinge = c + V((0, -0.01, -0.06))
	jaw = [c + V((s_ * 0.046, -0.005, -0.045)) for s_ in (-1, 1)]
	tube([jaw[0], c + V((-0.046, -0.03, -0.1)), c + V((-0.03, -0.075, -0.108)), c + V((0, -0.092, -0.108)),
		c + V((0.03, -0.075, -0.108)), c + V((0.046, -0.03, -0.1)), jaw[1]], 0.012, 0.012, bn, seg=7)
	for k in range(7):
		a = math.radians(-50 + k * 100 / 6)
		B((0.01, 0.009, 0.014), tuple(c + V((math.sin(a) * 0.032, -0.085 + (1 - math.cos(a)) * 0.03, -0.094))), bn2, bevel=0.002)  # lower teeth
	turn(objs() - jaw0, "X", 28, tuple(hinge))  # the jaw dropped open
	sphere((c.x, c.y, c.z + 0.012), 0.1, IRON("a"), scale=(1, 1.08, 0.95), seg=16, rings=8, cut=0.0)  # helmet dome
	kit.ring(0.099, 0.013, (c.x, c.y, c.z + 0.014), CU("dark"), seg=20).scale = (1, 1.08, 1)
	for k in range(8):
		a = 2 * math.pi * k / 8
		rivet((c.x + math.cos(a) * 0.1, c.y + math.sin(a) * 0.108, c.z + 0.014), IRON("dark"), r=0.009)
	B((0.022, 0.016, 0.06), (c.x, c.y - 0.113, c.z - 0.01), IRON("a"), bevel=0.005)  # nose guard
	B((0.022, 0.19, 0.026), (c.x, c.y, c.z + 0.105), CU("b"), bevel=0.007)  # crest
	head = objs() - before
	turn(head, "Y", 26, tuple(N))
	turn(head, "X", 30, tuple(N))
	# right arm dropped: hand lying on the floor beside the hip
	Sr = tp((0.14, 0.045, 0.425))
	Er = Sr + V((0.045, -0.02, -0.19))
	Wr = V((Er.x + 0.06, Er.y - 0.07, 0.02))
	bone(Sr, Er, 0.016)
	pair(Er, Wr, 0.009, (0, 1, 0))
	hand(Wr, (0.45, -0.85, 0), (0.85, 0.45, 0), droop=0.1)
	# left arm limp in the lap, its hand slack over the rolled note on the thigh
	Sl = tp((-0.14, 0.045, 0.425))
	El = Sl + V((-0.05, -0.1, -0.17))
	Wl = V((-0.1, -0.2, 0.115))
	bone(Sl, El, 0.016)
	pair(El, Wl, 0.009, (0, 0, 1))
	hand(Wl, (0.55, -0.65, -0.3), (0.65, 0.55, 0), droop=0.45)
	log((-0.12, -0.29, 0.1), (0.07, -0.31, 0.035), 0.024, PAPER(-0.03), seg=10, rings=1, ends=False, bend=0)  # the rolled note
	kit.ring(0.025, 0.006, (-0.03, -0.3, 0.068), kit.mat("target_red", -0.2), rot=(0, 90 - 19, 0), seg=10)  # its string
	# legs sprawled out on the floor, feet fallen outward
	for s_, K, A in ((1, (0.2, -0.34, 0.055), (0.25, -0.67, 0.03)), (-1, (-0.165, -0.37, 0.07), (-0.15, -0.71, 0.03))):
		Hp = V((s_ * 0.085, -0.01, 0.08))
		K, A = V(K), V(A)
		bone(Hp, K, 0.02, knob=1.4)
		sphere(tuple(K + V((0, -0.015, 0.018))), 0.018, bn2, scale=(1, 0.7, 1), seg=8, rings=5)  # kneecap
		pair(K, A, 0.014, (s_, 0, 0.3))
		foot(A, (s_ * 0.5, -0.6, 0.0), (0.8, s_ * 0.5, 0.0))
	floor_cut()


# ---------------- wall carvings (relief panels) ----------------
D_SLAB = 0.14


def carving_slab():
	"""A 1.6 x 1.2 m stone panel standing on the floor, front face at y=0, flat back at y=+0.14, with a stone frame."""
	B((1.6, D_SLAB, 1.2), (0, D_SLAB / 2, 0.6), T("greystone", "dark"), bevel=0.02)
	for z in (0.05, 1.15):  # frame stones top and bottom
		for i in range(4):
			stone((0.39, 0.06, 0.1), (-0.6 + i * 0.4, -0.02, z), tone=T("greystone", "b"), bevel=0.015)
	for x in (-0.75, 0.75):
		for i in range(3):
			stone((0.1, 0.06, 0.31), (x, -0.02, 0.27 + i * 0.33), tone=T("greystone", "b"), bevel=0.015)


def rl(pts, depth, m=None):
	"""A raised carved shape: from 4 mm inside the panel to `depth` in front of it."""
	return prism(pts, 0.004, -depth, m or T("greystone", "c"))


def dwarf(x, z, s=1.0, face=1, tool=None):
	"""A carved dwarf in profile (facing +x when face=1): legs, body, head with helmet, big beard, arm; z = feet."""
	f = face
	m = T("greystone", "c")
	for dx in (-0.03, 0.03):
		rl(bar((x + dx * s, z), (x + dx * s * 0.8, z + 0.12 * s), 0.05 * s), 0.02, m)  # legs
	rl([(x - 0.08 * s, z + 0.1 * s), (x + 0.08 * s, z + 0.1 * s), (x + 0.07 * s, z + 0.28 * s), (x - 0.07 * s, z + 0.28 * s)], 0.024, m)  # body
	rl(circ(x, z + 0.33 * s, 0.065 * s, n=10), 0.028, m)  # head
	rl([(x - 0.075 * s, z + 0.35 * s), (x + 0.075 * s, z + 0.35 * s), (x + 0.05 * s, z + 0.41 * s), (x, z + 0.43 * s), (x - 0.05 * s, z + 0.41 * s)], 0.032, m)  # helmet
	rl([(x + f * 0.0 * s, z + 0.31 * s), (x + f * 0.075 * s, z + 0.3 * s), (x + f * 0.05 * s, z + 0.16 * s), (x + f * 0.02 * s, z + 0.12 * s)], 0.032, m)  # beard
	if tool == "pick":
		hx, hz = x + f * 0.2 * s, z + 0.46 * s
		rl(bar((x + f * 0.03 * s, z + 0.24 * s), (hx, hz), 0.035 * s), 0.036, m)  # arm + handle
		rl(bar((hx - f * 0.11 * s, hz - 0.02 * s), (hx + f * 0.12 * s, hz - 0.07 * s), 0.035 * s, 0.012 * s), 0.04, m)  # pick head
	elif tool == "block":
		rl(bar((x + f * 0.02 * s, z + 0.24 * s), (x + f * 0.09 * s, z + 0.42 * s), 0.035 * s), 0.036, m)
		rl([(x + f * 0.0 * s, z + 0.42 * s), (x + f * 0.2 * s, z + 0.42 * s), (x + f * 0.2 * s, z + 0.55 * s), (x + f * 0.0 * s, z + 0.55 * s)], 0.04, m)
	elif tool == "point":
		rl(bar((x + f * 0.03 * s, z + 0.25 * s), (x + f * 0.2 * s, z + 0.33 * s), 0.035 * s), 0.036, m)
	elif tool == "flee":
		rl(bar((x - f * 0.03 * s, z + 0.25 * s), (x - f * 0.17 * s, z + 0.4 * s), 0.035 * s), 0.036, m)
		rl(bar((x + f * 0.03 * s, z + 0.25 * s), (x + f * 0.17 * s, z + 0.18 * s), 0.035 * s), 0.036, m)


def wall_carving_1():
	"""Relief: three dwarves digging into a rock face full of ore."""
	carving_slab()
	rock = T("greystone", "b")
	rl([(-0.68, 0.11), (0.68, 0.11), (0.68, 0.17), (-0.68, 0.17)], 0.018, rock)  # ground line
	rl([(0.32, 0.17), (0.68, 0.17), (0.68, 1.08), (0.5, 1.02), (0.42, 0.85), (0.36, 0.7), (0.4, 0.5), (0.34, 0.32)], 0.018, rock)  # rock face
	for (x, z) in ((0.5, 0.8), (0.58, 0.45), (0.46, 0.3), (0.6, 0.95)):
		rl(circ(x, z, 0.04, n=6, wob=0.15), 0.03, kit.tex_mat("copper", "dark"))  # ore
	for k in range(4):  # chips flying from the face
		rl(circ(0.27 - k * 0.03, 0.62 + k * 0.05, 0.015, n=5, wob=0.2), 0.024, rock)
		rl(bar((0.27 - k * 0.03, 0.62 + k * 0.05), (0.32, 0.6 + k * 0.03), 0.008), 0.022, rock)
	dwarf(0.12, 0.17, 1.0, 1, "pick")
	dwarf(-0.2, 0.17, 0.95, 1, "pick")
	dwarf(-0.5, 0.17, 0.9, 1, "block")
	# a cart of rubble behind them
	rl([(-0.66, 0.66), (-0.42, 0.66), (-0.45, 0.8), (-0.63, 0.8)], 0.02, rock)
	rl(circ(-0.54, 0.84, 0.07, n=8, sz=0.6), 0.016, rock)
	for x in (-0.6, -0.48):
		rl(circ(x, 0.63, 0.03, n=8), 0.026, rock)
	rl(bar((-0.68, 0.6), (-0.42, 0.6), 0.02), 0.024, rock)


def wall_carving_2():
	"""Relief: a great hall being built: pillars and arches, scaffold, dwarves carrying stone."""
	carving_slab()
	rock = T("greystone", "b")
	rl([(-0.68, 0.11), (0.68, 0.11), (0.68, 0.17), (-0.68, 0.17)], 0.018, rock)
	# finished part: two pillars with an arch on the left
	for x in (-0.6, -0.2):
		rl([(x - 0.05, 0.17), (x + 0.05, 0.17), (x + 0.045, 0.82), (x - 0.045, 0.82)], 0.02, rock)
		rl([(x - 0.075, 0.82), (x + 0.075, 0.82), (x + 0.075, 0.87), (x - 0.075, 0.87)], 0.026, rock)
	arch = []
	for i in range(9):
		a = math.pi * i / 8
		arch.append((-0.4 + math.cos(a) * 0.25, 0.87 + math.sin(a) * 0.17))
	for i in range(9):
		a = math.pi * (8 - i) / 8
		arch.append((-0.4 + math.cos(a) * 0.17, 0.87 + math.sin(a) * 0.1))
	rl(arch, 0.02, rock)
	rl([(-0.68, 1.04), (-0.12, 1.04), (-0.12, 1.08), (-0.68, 1.08)], 0.022, rock)  # roof line
	# half-built pillar on the right with a scaffold and a hoist
	rl([(0.25, 0.17), (0.35, 0.17), (0.345, 0.5), (0.3, 0.55), (0.255, 0.5)], 0.02, rock)
	for x in (0.15, 0.55):
		rl(bar((x, 0.17), (x, 0.9), 0.025), 0.016, rock)
	rl(bar((0.15, 0.55), (0.55, 0.55), 0.025), 0.022, rock)
	rl(bar((0.15, 0.9), (0.62, 0.9), 0.025), 0.022, rock)
	rl(bar((0.6, 0.9), (0.6, 0.72), 0.01), 0.026, rock)  # hoist rope
	rl([(0.56, 0.62), (0.64, 0.62), (0.64, 0.72), (0.56, 0.72)], 0.03, rock)  # stone on the rope
	dwarf(0.4, 0.56, 0.75, -1, "point")
	dwarf(0.02, 0.17, 0.95, 1, "block")
	dwarf(0.48, 0.17, 0.85, -1, "block")


def wall_carving_3():
	"""Relief: something huge rising from the deep: a great head with eyes and reaching arms; small dwarves flee."""
	carving_slab()
	rock = T("greystone", "b")
	# the pit at the bottom
	rl([(-0.68, 0.11), (-0.3, 0.11), (-0.26, 0.2), (-0.68, 0.22)], 0.018, rock)
	rl([(0.3, 0.11), (0.68, 0.11), (0.68, 0.22), (0.26, 0.2)], 0.018, rock)
	# the great head
	head = [(-0.26, 0.11), (0.26, 0.11), (0.3, 0.45), (0.25, 0.68), (0.13, 0.8), (0.0, 0.84), (-0.13, 0.8), (-0.25, 0.68), (-0.3, 0.45)]
	rl(head, 0.022, rock)
	m = T("greystone", "c")
	for s_ in (-1, 1):
		rl([(s_ * 0.14, 0.76), (s_ * 0.24, 0.98), (s_ * 0.2, 0.74)], 0.026, m)  # horns
		rl(circ(s_ * 0.1, 0.56, 0.05, n=8, sz=0.6), 0.03, kit.mat("ember", -0.45))  # dull red eyes
	rl([(-0.15, 0.3), (0.15, 0.3), (0.1, 0.24), (-0.1, 0.24)], 0.03, kit.mat("stone_dark", -0.3))  # mouth
	for i in range(5):
		x = -0.12 + i * 0.06
		rl([(x - 0.02, 0.296), (x + 0.02, 0.296), (x, 0.25)], 0.036, m)  # teeth
	# arms reaching up the sides
	for s_ in (-1, 1):
		pts = [(s_ * 0.28, 0.25), (s_ * 0.45, 0.4), (s_ * 0.5, 0.65), (s_ * 0.47, 0.82)]
		for i, (p, q) in enumerate(zip(pts, pts[1:])):
			rl(bar(p, q, 0.09, 0.07), 0.022 + 0.004 * i, rock)
		for k in range(3):
			a = math.radians(70 + (k - 1) * 30)
			rl(bar((s_ * 0.47, 0.82), (s_ * (0.47 + math.cos(a) * 0.1 * s_ * s_ - 0.05 * (k - 1) * s_ * s_), 0.82 + math.sin(a) * 0.12), 0.03, 0.01), 0.038 + 0.003 * k, m)
	# small dwarves fleeing along the top
	dwarf(-0.5, 0.92, 0.38, -1, "flee")
	dwarf(-0.3, 0.92, 0.38, -1, "flee")
	dwarf(0.32, 0.92, 0.38, 1, "flee")
	rl([(-0.68, 0.9), (-0.08, 0.9), (-0.08, 0.92), (-0.68, 0.92)], 0.016, rock)
	rl([(0.2, 0.9), (0.68, 0.9), (0.68, 0.92), (0.2, 0.92)], 0.016, rock)
	for (x, z) in ((-0.55, 0.5), (0.58, 0.32), (-0.6, 0.3)):
		rl(circ(x, z, 0.03, n=6, wob=0.2), 0.02, rock)  # falling rocks


def hit_y(o, x, z):
	"""Where the rock's front surface is at (x, z): a ray from the front."""
	bpy.context.view_layer.update()
	inv = o.matrix_world.inverted()
	ok, loc, _n, _i = o.ray_cast(inv @ Vector((x, -2.0, z)), (inv.to_3x3() @ Vector((0, 1, 0))).normalized())
	return (o.matrix_world @ loc).y if ok else None


def pickaxe_in_wall():
	"""A rock face (flat back) with a miner's pick driven deep into it and left: the spike sits in a hole it
	knocked in, cracks run out from the hit, rock layers, the broken-off stone in a heap at the foot."""
	rock = flat_back_rock((0, 0.0, 0.45), (0.46, 0.3, 0.45), T("greystone", "b"), seed=5, back=0.12)
	for loc, size, sd in (((0.33, 0.0, 0.2), (0.26, 0.22, 0.2), 8), ((-0.33, 0.01, 0.17), (0.22, 0.2, 0.17), 11), ((-0.12, 0.02, 0.82), (0.26, 0.18, 0.14), 14)):
		flat_back_rock(loc, size, T("greystone", "b"), seed=sd, back=0.11)
	P = Vector((0.03, hit_y(rock, 0.03, 0.6), 0.6))
	d_in = Vector((0.1, 1.0, -0.22)).normalized()
	E = P - d_in * 0.13  # the pick's eye, out in front of the rock
	cut = [log(tuple(P - d_in * 0.04), tuple(P + d_in * 0.13), 0.034, GROOVE_M(), seg=8, rings=1, ends=False, bend=0, r1=0.012)]  # the hole
	cut.append(kit.gem((P.x, P.y - 0.01, P.z), (0.075, 0.035, 0.065), kit.tex_mat("greystone", "c"), seed=33))  # crater of broken stone
	for k in range(7):  # cracks running out from the hit
		a = math.radians(k * 51 + 10)
		x, z = P.x, P.z
		ln = 0.07 + 0.03 * (k % 3)
		for seg_ in range(3):
			a2 = a + J(0.5)
			nx, nz = x + math.cos(a2) * ln, z + math.sin(a2) * ln
			yy = hit_y(rock, (x + nx) / 2, (z + nz) / 2)
			if yy is None:
				break
			cut += groove((x, z), (nx, nz), yy, w=0.012 - seg_ * 0.003, depth=0.014)
			x, z, ln = nx, nz, ln * 0.75
	for zl in (0.3, 0.82):  # rock layers
		xs = [-0.4 + i * 0.1 for i in range(9)]
		for xa, xb in zip(xs, xs[1:]):
			za, zb = zl + 0.02 * math.sin(xa * 9), zl + 0.02 * math.sin(xb * 9)
			yy = hit_y(rock, (xa + xb) / 2, (za + zb) / 2)
			if yy is not None and abs((xa + xb) / 2 - P.x) > 0.12:
				cut += groove((xa, za), (xb, zb), yy, w=0.008, depth=0.008)
	carve(rock, cut)
	# the pick: spike buried in its hole, chisel end out, handle down to the floor
	log(tuple(E), tuple(P + d_in * 0.11), 0.03, IRON("a"), seg=6, rings=2, ends=False, bend=0, r1=0.008)
	log(tuple(E), tuple(E - d_in * 0.12), 0.03, IRON("a"), seg=4, rings=1, ends=False, bend=0, r1=0.014)
	B((0.075, 0.08, 0.08), tuple(E), IRON("dark"), bevel=0.01)
	end = Vector((0.24, -0.62, 0.03))
	log(tuple(E + (E - end).normalized() * 0.05), tuple(end), 0.026, T("wood", "b"), seg=7, rings=2, ends=False, bend=0)
	g = E + (end - E) * 0.82
	rod(tuple(g), tuple(end + (end - E).normalized() * 0.012), 0.032, kit.tex_mat("leather", "a"), seg=8)  # grip wrap
	for t in (0.84, 0.9, 0.96):
		kit.ring(0.033, 0.006, tuple(E + (end - E) * t), kit.tex_mat("leather", "dark"), rot=(math.degrees(math.atan2((end - E).y, (end - E).z)) * -1, 0, 0), seg=10)
	# the stone knocked out by the hit, in a small heap at the foot of the face, resting on the floor
	r = __import__("random").Random(7)
	for k in range(12):
		s = 0.03 + 0.05 * r.random() ** 1.5
		o = kit.gem((0.05 + r.uniform(-0.14, 0.14), -0.27 + r.uniform(-0.07, 0.05), 0.1), (s, s * 0.8, s * 0.55), kit.tex_mat("greystone", "bc"[k % 2]), seed=60 + k)
		spin(o, r.uniform(-20, 20), r.uniform(-20, 20), r.uniform(0, 360))
		rest(o)
	floor_cut()


def miner_tent():
	"""A small abandoned canvas tent on poles, guy ropes to pegs, a torn front flap and a bedroll inside."""
	W, L, Hh = 0.7, 0.7, 1.0
	for y in (-L, L):
		log((0, y, 0), (0, y, Hh + 0.02), 0.035, T("bark"), seg=7, rings=2, ends=False)
	log((0, -L - 0.06, Hh), (0, L + 0.06, Hh), 0.035, T("bark"), seg=7, rings=2, ends=False)
	cloth = kit.tex_mat("sack", "a")
	for s_ in (-1, 1):  # the two canvas sides, sagging a little
		v = []
		n = 6
		for j in range(4):
			t = j / 3
			for i in range(n + 1):
				y = -L + 2 * L * i / n
				sag = 0.04 * math.sin(math.pi * i / n) * math.sin(math.pi * t)
				v.append((s_ * (W * t - sag), y, Hh + 0.05 - (Hh + 0.03) * t + sag * 0.5))
		f = []
		for j in range(3):
			for i in range(n):
				a = j * (n + 1) + i
				f.append((a, a + 1, a + n + 2, a + n + 1))
		o = mesh(v, f, cloth)
		sol = o.modifiers.new("t", "SOLIDIFY")
		sol.thickness = 0.014
		sol.offset = 1 if s_ > 0 else -1
	# back wall and the front flap that's left
	prism([(-W + 0.03, 0.02), (W - 0.03, 0.02), (0, Hh - 0.01)], L - 0.01, L - 0.025, kit.tex_mat("sack", "b"))
	prism([(-W + 0.03, 0.02), (-0.12, 0.02), (-0.06, 0.25), (-0.14, 0.42), (0, Hh - 0.01)], -L + 0.01, -L + 0.025, kit.tex_mat("sack", "b"))
	log((0.06, -L - 0.03, Hh - 0.08), (W - 0.06, -L - 0.03, 0.1), 0.045, kit.tex_mat("sack", "c"), seg=8, rings=2, ends=False)  # rolled-up flap
	for z in (0.75, 0.35):
		kit.ring(0.05, 0.01, ((Hh - z) / Hh * W, -L - 0.03, z), kit.tex_mat("rope"), rot=(0, 90 - math.degrees(math.atan2(Hh, W)), 0), seg=10)
	# guy ropes and pegs
	for s_ in (-1, 1):
		top = (0, s_ * (L + 0.03), Hh + 0.02)
		peg = (0, s_ * (L + 0.45), 0.06)
		kit.rope(top, peg, r=0.01)
		log((0, s_ * (L + 0.43), 0.0), (0, s_ * (L + 0.47), 0.12), 0.022, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
	# bedroll inside
	kit.cylinder(0.09, 0.55, (0.15, 0.1, 0.09), kit.tex_mat("cloth", "b"), rot=(90, 0, 0), verts=12, bevel=0.01)
	for y in (-0.08, 0.28):
		kit.ring(0.092, 0.01, (0.15, y, 0.09), kit.tex_mat("rope"), rot=(90, 0, 0), seg=12)


def lantern_post_burnt():
	CHAR = lambda s=0.0: C((0.075 * (1 + s), 0.06 * (1 + s), 0.05 * (1 + s)), 0.95)  # noqa: E731,N806  charred wood
	"""A scorched wooden post with an arm, a cracked empty lantern hanging from it."""
	stone((0.32, 0.32, 0.12), (0, 0, 0.06))
	log((0, 0, 0.1), (0.02, 0, 0.8), 0.07, T("wood", "dark"), seg=8, rings=2, end_m=CHAR(0.1))
	log((0.02, 0, 0.8), (0.04, 0, 1.75), 0.065, CHAR(0.15), seg=8, rings=3, end_m=CHAR(-0.1))  # charred top
	for k in range(6):
		lump((0.0 + J(0.03) + (0.06 if k % 2 else -0.06), J(0.04), 0.6 + k * 0.1), (0.03, 0.03, 0.04), CHAR(-0.2), seed=k, rough=0.004)
	log((0.04, 0, 1.62), (0.04, -0.42, 1.62), 0.04, CHAR(0.2), seg=7, rings=2, end_m=CHAR(-0.1))  # arm
	log((0.04, 0, 1.3), (0.04, -0.2, 1.6), 0.03, CHAR(0.2), seg=6, rings=1, ends=False, bend=0)  # brace
	kit.ring(0.03, 0.008, (0.04, -0.36, 1.57), IRON("dark"), rot=(0, 90, 0), seg=10)
	chain((0.04, -0.36, 1.54), (0.04, -0.36, 1.38), link=0.025, wire=0.007)
	# the lantern: cap, base, four corner posts, panes (one broken out, one cracked)
	cx, cy, zb, zt = 0.04, -0.36, 1.0, 1.28
	kit.ring(0.03, 0.008, (cx, cy, zt + 0.1), IRON("dark"), rot=(90, 0, 0), seg=10)
	kit.cone(0.13, 0.03, 0.09, (cx, cy, zt + 0.04), IRON("a"), verts=4, bevel=0.004, rot=(0, 0, 45))
	B((0.18, 0.18, 0.03), (cx, cy, zb + 0.015), IRON("a"), bevel=0.006)
	for dx in (-0.075, 0.075):
		for dy in (-0.075, 0.075):
			rod((cx + dx, cy + dy, zb + 0.02), (cx + dx, cy + dy, zt), 0.011, IRON("dark"))
	glass = C((0.5, 0.55, 0.45), 0.25)
	B((0.13, 0.008, 0.24), (cx, cy + 0.075, zb + 0.15), glass, bevel=0.002)  # back pane
	B((0.008, 0.13, 0.24), (cx - 0.075, cy, zb + 0.15), glass, bevel=0.002)  # left pane
	prism([(cx - 0.065, zb + 0.03), (cx + 0.065, zb + 0.03), (cx + 0.065, zb + 0.12), (cx + 0.01, zb + 0.16), (cx - 0.065, zb + 0.1)], cy - 0.071, cy - 0.079, glass)  # cracked front: lower piece
	prism([(cx - 0.065, zb + 0.115), (cx + 0.0, zb + 0.165), (cx + 0.065, zb + 0.135), (cx + 0.065, zb + 0.27), (cx - 0.065, zb + 0.27)], cy - 0.071, cy - 0.079, glass)  # upper piece
	B((0.008, 0.13, 0.03), (cx + 0.075, cy, zb + 0.045), glass, bevel=0.002)  # right pane broken out, a shard left
	kit.cylinder(0.025, 0.015, (cx, cy, zb + 0.037), CHAR(0.3), verts=8, bevel=0)  # burnt-out wick holder


def rope_ladder_broken():
	"""A top beam (spiked into the wall at +Y) with a rope ladder hanging down, rungs snapped, slack rope on the floor."""
	Z = 2.2
	log((-0.5, 0, Z), (0.5, 0, Z), 0.07, T("bark"), seg=8, rings=2, end_m=kit.tex_mat("wood", "c"))
	for x in (-0.4, 0.4):
		rod((x, 0.0, Z), (x, 0.2, Z), 0.018, IRON("dark"))  # spikes into the wall
		kit.cylinder(0.035, 0.015, (x, -0.075, Z), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.003)
	rx = 0.22
	for s_ in (-1, 1):
		rope_tie((s_ * rx, 0, Z), 0.07, axis="x")
		pts = [(s_ * rx, -0.07, Z - 0.02)]
		for i in range(1, 6):
			z = Z - 0.02 - i * (Z - 0.06) / 5
			pts.append((s_ * rx + J(0.015), -0.07 - 0.01 * i, max(z, 0.02)))
		for p, q in zip(pts, pts[1:]):
			kit.rope(p, q, r=0.014)
		kit.ring(0.12, 0.016, (s_ * rx + s_ * 0.06, -0.14, 0.018), kit.tex_mat("rope"), seg=14).scale = (1, 0.8, 1)  # slack on the floor
	rope_m = kit.tex_mat("rope")

	def side(s_, z):
		return (s_ * rx, -0.07 - 0.01 * ((Z - 0.02 - z) / ((Z - 0.06) / 5)), z)

	for i, z in enumerate((1.95, 1.65, 1.35, 1.05, 0.75, 0.45)):
		L_, R_ = Vector(side(-1, z)), Vector(side(1, z))
		if i == 2:  # snapped: each half hangs from its rope
			for s_, p in ((-1, L_), (1, R_)):
				e = p + Vector((-s_ * 0.12, -0.02, -0.17))
				log(tuple(p), tuple(e), 0.022, T("wood", "b"), seg=6, rings=1, ends=False, bend=0)
				kit.ring(0.026, 0.008, tuple(p), rope_m, rot=(0, 90, 0), seg=8)
		elif i == 4:  # gone: only knots left
			for p in (L_, R_):
				sphere(tuple(p), 0.026, rope_m, seg=8, rings=5)
		else:
			log(tuple(L_), tuple(R_), 0.022, T("wood", "b" if i % 2 else "c"), seg=6, rings=1, ends=False, bend=0)
			for p in (L_, R_):
				kit.ring(0.026, 0.008, tuple(p), rope_m, rot=(0, 90, 0), seg=8)
	# the lost rung on the floor, broken in two
	log((-0.25, -0.45, 0.022), (-0.03, -0.38, 0.022), 0.022, T("wood", "b"), seg=6, rings=1, ends=False, bend=0)
	log((0.02, -0.42, 0.022), (0.22, -0.5, 0.022), 0.022, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)


MODELS = {
	"ancestor_stone_tall": ancestor_stone_tall, "ancestor_stone_small": ancestor_stone_small,
	"notice_board_torn": notice_board_torn, "hanging_cage": hanging_cage, "wall_shackles": wall_shackles,
	"forge_bellows_broken": forge_bellows_broken, "forge_anvil_cracked": forge_anvil_cracked, "skeleton_with_note": skeleton_with_note,
	"wall_carving_1": wall_carving_1, "wall_carving_2": wall_carving_2, "wall_carving_3": wall_carving_3, "pickaxe_in_wall": pickaxe_in_wall, "miner_tent": miner_tent,
	"lantern_post_burnt": lantern_post_burnt, "rope_ladder_broken": rope_ladder_broken,
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
