# Delver's Shack, version 2 (owner, Nov 15): the first 4 pieces rebuilt to match the turnaround sheet
# assets/concepts/building-kit/shack_turnaround_4pieces.png (front / side / back / top views) and the kit sheet
# shack_kit_sheet_v2.png. Chunky bark logs with flat-cut ends, X rope lashings at the top corners, wide thick
# planks with round iron bolt heads, big wooden shingles.
#   blender --background --factory-startup --python builds/shack_v2.py -- [grey] [out=<folder>] [piece ...]
# Pieces: foundation, wall, doorway, door, roof_26. "grey" = one plain grey material (the shape check step).
# Default output: assets/models/build/<piece>__plank_root.glb (only once the owner approves the shape).
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402

K.S = "shack"
T, blk, log, J, peg = K.T, K.blk, K.log, K.J, K.peg
E = 0.006          # every outer face stays this far inside the piece box
POST_R = 0.14      # depth (the wall is 0.3 deep); posts are wider than deep (POST_W)
POST_W = 0.22     # the big corner posts (the picture's posts are very thick)
TOP_Y = 1.80       # top log centre (walls and doorway match)


def bolt(c, axis="z", s=1, r=0.032):
	"""A round iron bolt head on a surface (c = the surface point; axis/s = which way it faces), sunk so it
	never sticks out more than about 1 cm."""
	p = list(c)
	k = {"x": 0, "y": 1, "z": 2}[axis]
	p[k] -= s * (r - 0.01)
	kit.rivet(K.G(tuple(p)), kit.tex_mat("iron", "dark"), r=r)


def xrope(c, r, faces=("z+", "z-"), rw=None):
	"""The X-shaped rope lashing on a vertical post: two rope bands crossing on each outer face, pressed into
	the log so nothing sticks out past the piece."""
	x, y, z = c
	rw = rw or r
	for f in faces:
		ax, sg = f[0], 1 if f[1] == "+" else -1
		for a in (32, -32):
			L = rw * 2.0
			dx, dy = math.cos(math.radians(90 - a)) * L / 2, math.sin(math.radians(90 - a)) * L / 2
			if ax == "z":
				p0, p1 = (x - dx, y - dy, z + sg * (r - 0.035)), (x + dx, y + dy, z + sg * (r - 0.035))
			else:
				p0, p1 = (x + sg * (r - 0.035), y - dy, z - dx), (x + sg * (r - 0.035), y + dy, z + dx)
			log(p0, p1, 0.042, kit.tex_mat("rope"), seg=8, rings=2, ends=False, bend=0)


def post(x, z, y0, y1, r=POST_R, w=None):
	"""A thick upright log with a flat-cut top (end grain showing); w = its half-width across x."""
	log((x, y0, z), (x + J(0.006), y1, z + J(0.006)), r, ends=True, rv=(w or r) / r)


def planks(x0, x1, y0, y1, d, n=None, z=0.0, hole=None):
	"""Wide thick upright planks (4 across a wall), small gaps, each a little different. hole = (r, spring)."""
	n = n or max(2, round((x1 - x0) / 0.36))
	pw = (x1 - x0) / n
	fr = K.Frame()
	for i in range(n):
		a, b = x0 + i * pw + 0.008, x0 + (i + 1) * pw - 0.008
		m = T("wood", "abc"[i % 3])
		dz = z + J(0.006)
		if not hole:
			K.plank_shape(fr, a, b, lambda x: y0, lambda x: y1 - abs(J(0.01)), dz, d, m)
			continue
		r, spring = hole
		top_of_hole = lambda x: spring + math.sqrt(max(0.0, r * r - min(x * x, r * r)))
		if b <= -r or a >= r:
			K.plank_shape(fr, a, b, lambda x: y0, lambda x: y1, dz, d, m)
			continue
		if a < -r:  # plank partly beside the opening: split at the opening edge
			K.plank_shape(fr, a, -r, lambda x: y0, lambda x: y1, dz, d, m)
			a = -r
		if b > r:
			K.plank_shape(fr, r, b, lambda x: y0, lambda x: y1, dz, d, m)
			b = r
		if y1 - top_of_hole((a + b) / 2) > 0.04:
			K.plank_shape(fr, a, b, top_of_hole, lambda x: y1, dz, d, m, k=6)


def wall_frame(w=2.0, h=2.0, d=0.3, door=False, pw=POST_W):
	px = w / 2 - pw - E
	for s_ in (-1, 1):
		post(s_ * px, 0.0, E, h - 0.03, w=pw)
		for y in (0.16, 1.0):
			bolt((s_ * px, y, POST_R), "z")
	log((-px, TOP_Y, 0.0), (px, TOP_Y, 0.0), 0.13, ends=False, rv=1.2)  # big top log between the posts
	for x in (-0.35, 0.35):
		bolt((x, TOP_Y, 0.13), "z")
	if not door:
		log((-px, 0.13, 0.0), (px, 0.13, 0.0), 0.12, ends=False, rv=1.05)  # sill log
		for x in (-0.35, 0.35):
			bolt((x, 0.13, 0.12), "z")
	return px


def wall(w=2.0, h=2.0, d=0.3):
	px = wall_frame(w, h, d)
	planks(-px, px, 0.2, TOP_Y - 0.1, 0.1, n=3)


DOOR_R, DOOR_CY = 0.78, 0.70   # hobbit-style round door: a circle cut flat at the floor (fits the dwarf)


def circle_cut(r, cy, n=28):
	"""Points of the round opening (flat at the floor), counter-clockwise."""
	a0 = math.asin(max(-1.0, min(1.0, -cy / r)))
	a1 = math.pi - a0
	return [(math.cos(a0 + (a1 - a0) * k / n) * r, cy + math.sin(a0 + (a1 - a0) * k / n) * r) for k in range(n + 1)]


def doorway(w=2.0, h=2.0, d=0.3):
	"""A wall with a ROUND door opening (hobbit style): wide planks cut exactly to the circle, a thick ring of
	bent plank segments round it, slim side posts and the same top log as the wall."""
	r, cy = DOOR_R, DOOR_CY
	px = wall_frame(w, h, d, door=True, pw=0.1)
	fr = K.Frame()
	# planks: cut exactly round the circle (the ring covers the cut edge)
	R = r + 0.06
	n = 5
	x0, x1 = -px, px
	pw_ = (x1 - x0) / n
	for i in range(n):
		a, b = x0 + i * pw_ + 0.008, x0 + (i + 1) * pw_ - 0.008
		m = T("wood", "abc"[i % 3])
		top = lambda x: TOP_Y - 0.1
		lo = lambda x: (cy + math.sqrt(max(0.0, R * R - x * x))) if abs(x) < R else E
		hi_bot = lambda x: (cy - math.sqrt(max(0.0, R * R - x * x))) if abs(x) < R else None
		if b <= -R or a >= R:
			K.plank_shape(fr, a, b, lambda x: E, top, J(0.004), 0.1, m)
			continue
		for (pa, pb) in ((a, min(b, -R)), (max(a, R), b)):
			if pb - pa > 0.02:
				K.plank_shape(fr, pa, pb, lambda x: E, top, J(0.004), 0.1, m)
		ca, cb = max(a, -R + 0.002), min(b, R - 0.002)
		if cb - ca > 0.02:
			K.plank_shape(fr, ca, cb, lo, top, J(0.004), 0.1, m, k=8)
			below = lambda x: max(E + 0.004, cy - math.sqrt(max(0.0, R * R - x * x)))
			if max(below(ca), below(cb)) > E + 0.03:  # planks under the round opening's lower curve
				K.plank_shape(fr, ca, cb, lambda x: E, below, J(0.004), 0.1, m, k=8)
	# the ring: thick bent-plank segments all round, cut flat at the floor
	fw = 0.13
	a0 = math.asin(-cy / (r + fw))
	K.arch_ring(fr, 0.0, cy, r + 0.004, r + fw, 12, 0.22, lambda: T("wood", "b"), gap=0.008, a0=a0, a1=math.pi - a0)
	for k in range(10):
		a = a0 + (math.pi - 2 * a0) * (k + 0.5) / 10
		bolt((math.cos(a) * (r + fw / 2), cy + math.sin(a) * (r + fw / 2), 0.11), "z")
	blk((0, 0.025, 0), (2 * math.sqrt((r + fw) ** 2 - cy ** 2) + 0.1, 0.04, 0.24), T("wood", "dark"), bevel=0.008)  # threshold board


def door(w=None, h=None, d=0.12):
	"""The round hobbit door: wide planks cut to the circle (flat at the floor), a rim, long copper hinge straps
	and a round copper knob in the middle."""
	r, cy = DOOR_R - 0.006, DOOR_CY
	fr = K.Frame()
	n = 5
	for i in range(n):
		a, b = -r + i * 2 * r / n + 0.006, -r + (i + 1) * 2 * r / n - 0.006
		lo = lambda x: max(E, cy - math.sqrt(max(0.0, r * r - x * x)))
		hi = lambda x: cy + math.sqrt(max(0.0, r * r - x * x))
		K.plank_shape(fr, a, b, lo, hi, J(0.003), 0.07, T("wood", "abc"[i % 3]), k=8)
	a0 = math.asin(-cy / r)
	K.arch_ring(fr, 0.0, cy, r - 0.08, r - 0.002, 14, 0.024, lambda: T("wood", "dark"), z=0.045, gap=0.004, a0=a0, a1=math.pi - a0)
	for k in range(12):
		a = a0 + (math.pi - 2 * a0) * (k + 0.5) / 12
		bolt((math.cos(a) * (r - 0.04), cy + math.sin(a) * (r - 0.04), 0.057), "z", r=0.013)
	cu = kit.tex_mat("copper", "b")
	for y in (cy - 0.38, cy + 0.38):  # long hinge straps from the hinge side
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))
		blk((-r + 0.06 + 0.45, y, 0.063), (0.9, 0.07, 0.012), cu, bevel=0.004)
		for x in (-r + 0.15, -r + 0.45, -r + 0.8):
			kit.rivet(K.G((x, y, 0.066)), kit.tex_mat("copper", "dark"), r=0.012)
	kit.cylinder(0.07, 0.02, K.G((0, cy, 0.068)), cu, rot=(90, 0, 0), verts=16, bevel=0.006)  # the round knob plate
	kit.rivet(K.G((0, cy, 0.072)), cu, r=0.045)
	for y in (cy - 0.3, cy + 0.3):  # back battens
		hw = math.sqrt(max(0.0, (r - 0.08) ** 2 - (y - cy) ** 2))
		blk((0, y, -0.044), (2 * hw, 0.11, 0.024), T("wood", "dark"), bevel=0.008)


def foundation(w=2.0, h=1.0, dd=2.0):
	c = w / 2 - 0.205 - E
	pl = K.edge_planes(-w / 2, w / 2, -dd / 2, dd / 2, E)
	for sx in (-1, 1):
		for sz in (-1, 1):
			x, z = sx * c, sz * c
			sq = [(x + 0.26 * math.cos(math.pi / 4 + k * math.pi / 2 + J(0.1)), z + 0.26 * math.sin(math.pi / 4 + k * math.pi / 2 + J(0.1))) for k in range(4)]
			K.floor_poly(K.clip_poly(sq, pl), E, 0.1, T("greystone"))
			post(x, z, 0.1, h - 0.25, r=0.2)
			bolt((x, 0.35, z + sz * 0.185), "z", sz)
	# beams under the deck, front/back and left/right, between the posts
	for sz in (-1, 1):
		log((-c, h - 0.2, sz * c), (c, h - 0.2, sz * c), 0.12, ends=False)
		for x in (-0.35, 0.35):
			bolt((x, h - 0.2, sz * (c + 0.12)), "z", sz)
	for sx in (-1, 1):
		log((sx * c, h - 0.2, -c), (sx * c, h - 0.2, c), 0.12, ends=False)
	log((0, h - 0.19, -c), (0, h - 0.19, c), 0.1, ends=False)
	# deck: wide thick planks front to back, notched round the corner posts
	n = 4
	x0, x1 = -w / 2 + E, w / 2 - E
	pw = (x1 - x0) / n
	for i in range(n):
		a, b = x0 + i * pw + 0.007, x0 + (i + 1) * pw - 0.007
		zr = dd / 2 - E
		K.floor_poly([(a, -zr), (b, -zr), (b, zr), (a, zr)], h - 0.13, h - E - abs(J(0.006)), T("wood", "abc"[i % 3]))
		for zz in (-0.55, 0.0, 0.55):
			bolt(((a + b) / 2, h - E - 0.006, zz), "y")


def roof(w=2.0, rise=1.0, dd=2.0):
	sl = K.Slope("z", dd / 2, -dd / 2, rise, 0.33, vlo=-w / 2, vhi=w / 2)
	pl = sl.planes()
	for v in (-0.82, 0.82):  # the two big side rafters (round ends show at the eave)
		a, b = sl.P(sl.u(0.1), v, 0.09), sl.P(sl.u(sl.run - 0.08), v, 0.09)
		log(a, b, 0.09, ends=True)
	sl.strip(0.0, sl.run, sl.vlo, sl.vhi, pl, lambda u: 0.165, lambda u: 0.185, T("wood", "dark"))  # boards
	# big shingles in 5 overlapping rows, each with a bolt
	Er, OV, TH = 0.46, 0.14, 0.05
	i = 0
	while i * Er < sl.run - 0.1:
		d0, d1 = i * Er, min(i * Er + Er + OV, sl.run - 0.16)
		hb = (lambda a_: (lambda u: 0.183 + 0.06 * (1 - (sl.d(u) - a_) / (Er + OV))))(d0)
		ht = (lambda f: (lambda u: f(u) + TH))(hb)
		v = sl.vlo + (0.0 if i % 2 == 0 else -0.16)
		while v < sl.vhi - 0.02:
			sw = 0.31 + J(0.03)
			poly = sl.strip(d0, d1, max(sl.vlo, v) + 0.008, min(sl.vhi, v + sw) - 0.008, pl, hb, ht, T("shingle", "a"), min_area=0.004)
			if poly and min(sl.vhi, v + sw) - max(sl.vlo, v) > 0.15:
				vm = (max(sl.vlo, v) + min(sl.vhi, v + sw)) / 2
				p = sl.P(sl.u(d0 + 0.08), vm, hb(sl.u(d0 + 0.08)) + TH)
				kit.rivet(K.G(p), kit.tex_mat("iron", "dark"), r=0.026)
			v += sw
		i += 1
	# the ridge board across the high end
	sl.strip(sl.run - 0.2, sl.run, sl.vlo, sl.vhi, pl, lambda u: 0.185, lambda u: 0.3, T("wood", "b"))
	for v in (-0.6, 0.0, 0.6):
		kit.rivet(K.G(sl.P(sl.u(sl.run - 0.1), v, 0.29)), kit.tex_mat("iron", "dark"), r=0.02)


# ---------------- version 3: the beetle style (owner, Nov 15): chunky chisel-cut faces, rough and imperfect ----------------
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402


def _flat(o):
	for p in o.data.polygons:
		p.use_smooth = False
	return o


def facet_log(p0, p1, r, m=None, sides=7, rings=4, jit=0.13, chop=(0.0, 0.0)):
	"""A chunky chisel-cut log: few flat faces, an uneven outline, axe-chopped ends (chop = end tilt, radians)."""
	p0, p1 = Vector(p0), Vector(p1)
	ax = (p1 - p0).normalized()
	up = Vector((0, 1, 0)) if abs(ax.y) < 0.9 else Vector((1, 0, 0))
	u = ax.cross(up).normalized()
	v = ax.cross(u)
	base = [1 + J(jit) for _ in range(sides)]
	rot0 = K.rng.uniform(0, math.tau)
	verts, n = [], sides
	for i in range(rings + 1):
		t = i / rings
		c = p0 + (p1 - p0) * t
		for k in range(sides):
			a = rot0 + math.tau * k / sides + J(0.12)
			rr = r * base[k] * (1 + J(jit * 0.35))
			q = c + u * math.cos(a) * rr + v * math.sin(a) * rr
			if i in (0, rings):  # axe-chopped end: tilt the end face
				tilt = chop[0] if i == 0 else chop[1]
				q = q + ax * (math.cos(a) * rr * math.tan(tilt)) * (1 if i else -1)
			verts.append(tuple(q))
	faces = []
	for i in range(rings):
		for k in range(n):
			a, b = i * n + k, i * n + (k + 1) % n
			faces.append((a, b, b + n, a + n))
	faces.append(tuple(reversed(range(n))))
	faces.append(tuple(range(rings * n, (rings + 1) * n)))
	o = _flat(K.mesh(verts, faces, m or T("bark")))
	o["role"] = "log"
	o["axis"] = (list(p0), list(p1))
	o["r"] = r
	return o


def boulder(c, sx, sy, sz, m=None, floor=E):
	"""A chunky faceted stone, like the beetle's shell plates: a lumpy low-poly ball, flat underneath."""
	bm = bmesh.new()
	bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
	verts = []
	for vt in bm.verts:
		x, y, z = vt.co.x * sx * (1 + J(0.16)), vt.co.z * sy * (1 + J(0.16)), vt.co.y * sz * (1 + J(0.16))
		verts.append((c[0] + x, max(floor, c[1] + y), c[2] + z))
	faces = [tuple(vv.index for vv in f.verts) for f in bm.faces]
	bm.free()
	o = _flat(K.mesh(verts, faces, m or T("greystone")))
	o["role"] = "stone"
	return o


def rough_board(x0, x1, z0, z1, y0, y1, m=None, chips=2, notch=None, broken=None, warp=0.0):
	"""A thick hand-split board seen from above: wavy edges, chipped corners, an optional bite out of one edge
	(notch = (side, z, size)) or a broken jagged end (broken = 'front'/'back'). Top a little uneven."""
	pts = []
	L = z1 - z0
	nz = max(3, int(L / 0.28))
	def edge_x(xb, sgn, zz):
		w = J(0.006)
		if notch and notch[0] == sgn and abs(zz - notch[1]) < notch[2]:
			w -= sgn * (notch[2] - abs(zz - notch[1])) * 0.8
		return xb + w
	# outline: front end, right edge (+x) up, back end, left edge down
	cut = [K.rng.uniform(0.02, 0.06) if K.rng.random() < 0.5 else 0.0 for _ in range(4)]
	pts.append((x0 + cut[0], z1))
	if broken == "front":
		for k in range(1, 4):
			pts.append((x0 + (x1 - x0) * k / 4, z1 - K.rng.uniform(0.02, 0.09)))
	pts.append((x1 - cut[1], z1))
	for k in range(1, nz):
		zz = z1 - L * k / nz
		pts.append((edge_x(x1, 1, zz), zz))
	pts.append((x1 - cut[2], z0))
	if broken == "back":
		for k in range(3, 0, -1):
			pts.append((x0 + (x1 - x0) * k / 4, z0 + K.rng.uniform(0.02, 0.09)))
	pts.append((x0 + cut[3], z0))
	for k in range(1, nz):
		zz = z0 + L * k / nz
		pts.append((edge_x(x0, -1, zz), zz))
	pts = [(max(-0.994, min(0.994, x)), max(-0.994, min(0.994, z))) for x, z in pts]
	n = len(pts)
	# top: a little uneven and tipped (warp); the board is a prism with its own wobbly top
	tops = [y1 - abs(J(0.006)) - warp * ((z - z0) / L) for x, z in pts]
	verts = [(x, y0, z) for x, z in pts] + [(x, t, z) for (x, z), t in zip(pts, tops)]
	faces = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	o = _flat(K.mesh(verts, faces, m or T("wood")))
	o["role"] = "board"
	return o


def real_log(p0, p1, r, style="round", m=None, rings=7, stub=True):
	"""A believable log (Nov 15, the owner: the chisel-cut pencil logs looked cartoonish).
	style round: 14 sides, smooth, a little taper and bend, a few bumps, ends cut almost square with a rough
	bevel, sometimes a cut-off branch stub. style hewn: squared with an axe, four flat chopped faces (wood)
	and the bark left on the rounded corners (wane), like an old cabin beam."""
	p0, p1 = Vector(p0), Vector(p1)
	ax = (p1 - p0).normalized()
	up = Vector((0, 1, 0)) if abs(ax.y) < 0.9 else Vector((1, 0, 0))
	u = ax.cross(up).normalized()
	v = ax.cross(u)
	if style == "hewn":
		angs = []
		for k in range(4):
			c0 = math.radians(90 * k + 45)
			for d in (-32, -20, 20, 32):
				angs.append((c0 + math.radians(d)) % math.tau)
		angs.sort()
	else:
		angs = [math.tau * k / 14 for k in range(14)]
	n = len(angs)
	bump = [1 + J(0.045) for _ in range(n)]
	bend = Vector((J(1), J(1), J(1))) * r * 0.25
	L = (p1 - p0).length
	verts = []
	ring_t = [0.0, 0.025 / L] + [k / (rings - 1) for k in range(1, rings - 1)] + [1 - 0.025 / L, 1.0]
	for i, t in enumerate(ring_t):
		c = p0 + (p1 - p0) * t + bend * math.sin(math.pi * t)
		taper = 1.0 - 0.07 * t
		cham = 0.9 if i in (0, len(ring_t) - 1) else 1.0
		for k, a in enumerate(angs):
			rr = r * bump[k] * taper * cham * (1 + J(0.015))
			q = c + u * math.cos(a) * rr + v * math.sin(a) * rr
			if i in (0, len(ring_t) - 1):
				q = q + ax * (J(0.012) + math.cos(a) * rr * 0.05) * (1 if i else -1)
			verts.append(tuple(q))
	R = len(ring_t)
	faces = []
	for i in range(R - 1):
		for k in range(n):
			a_, b_ = i * n + k, i * n + (k + 1) % n
			faces.append((a_, b_, b_ + n, a_ + n))
	faces.append(tuple(reversed(range(n))))
	faces.append(tuple(range((R - 1) * n, R * n)))
	o = K.mesh(verts, faces, m or T("bark"))
	for poly in o.data.polygons:
		poly.use_smooth = style == "round"
	o["role"] = "log"
	o["style"] = style
	o["axis"] = (list(p0), list(p1))
	o["r"] = r
	if stub and style == "round" and L > 0.6 and K.rng.random() < 0.7:
		t = K.rng.uniform(0.3, 0.7)
		a = K.rng.uniform(0, math.tau)
		dirv = u * math.cos(a) + v * math.sin(a)
		base = p0 + (p1 - p0) * t + bend * math.sin(math.pi * t) + dirv * r * 0.8
		so = K.log(tuple(base), tuple(base + dirv * (r * 0.35 + 0.03)), r * 0.22, T("bark"), seg=8, rings=1, ends=True, bend=0)
		so["role"] = "stub"
	return o


def peg(x, y, z, axis="y", s=1):
	"""A wooden peg: a short round dowel driven in, with a slightly domed head showing (Rule 6: wooden pegs)."""
	d = {"x": (s * 1, 0, 0), "y": (0, s * 1, 0), "z": (0, 0, s * 1)}[axis]
	head = (x + d[0] * 0.006, y + d[1] * 0.006, z + d[2] * 0.006)
	o = K.log((x - d[0] * 0.04, y - d[1] * 0.04, z - d[2] * 0.04), head, 0.015, T("wood", "dark"), seg=8, rings=1, ends=False, bend=0)
	o["role"] = "peg"
	hd = (head[0] + d[0] * 0.002, head[1] + d[1] * 0.002, head[2] + d[2] * 0.002)
	kit.rivet(K.G(hd), T("wood", "dark"), r=0.02)


LOG_STYLE = "round"


def foundation_v3(w=2.0, h=1.0, dd=2.0, parts=("under", "deck")):
	"""Delver's Shack foundation, rustic starter style: log legs on lumpy stones, two side logs on the legs, three
	cross logs resting on them in notches (nothing passes through anything), and a deck of uneven split boards
	with gaps, chips, a knot bite and a broken end, held with wooden pegs. Flat top at 1 m.
	LOG_STYLE round = believable round logs, hewn = axe-squared beams with bark on the corners."""
	st = LOG_STYLE
	c = w / 2 - 0.22
	deck_bot = h - 0.11
	r_up, r_lo = (0.095, 0.11) if st == "round" else (0.09, 0.1)
	y_up = deck_bot - r_up + 0.012
	y_lo = y_up - r_up - r_lo + 0.035
	leg_top = y_lo - r_lo + 0.03
	for sx in ((-1, 1) if "under" in parts else ()):
		for sz in (-1, 1):
			x, z = sx * c, sz * c
			boulder((x + J(0.02), 0.07, z + J(0.02)), 0.21, 0.1, 0.2)
			real_log((x, 0.1, z), (x + J(0.012), leg_top, z + J(0.012)), 0.165, st, stub=False)
	for sx in ((-1, 1) if "under" in parts else ()):
		real_log((sx * c, y_lo, -dd / 2 + 0.05), (sx * c + J(0.01), y_lo, dd / 2 - 0.05), r_lo, st)
	for z in ((-c, 0.0, c) if "under" in parts else ()):
		real_log((-w / 2 + 0.05, y_up, z + J(0.02)), (w / 2 - 0.05, y_up, z + J(0.02)), r_up, st)
	for sz in ((-1, 1) if "under" in parts else ()):  # a rough diagonal brace board, pegged into the MIDDLE of each leg
		z = sz * (c + 0.13)
		a, b = (-c, 0.3), (c, leg_top - 0.1)
		Lb = math.hypot(b[0] - a[0], b[1] - a[1]) + 0.16
		br = blk(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, z), (Lb, 0.13, 0.045), T("wood", "b"), bevel=0.012,
			rz=math.degrees(math.atan2(b[1] - a[1], b[0] - a[0])))
		br["role"] = "brace"
		for (px, py) in (a, b):
			peg(px, py, z + sz * 0.022, "z", sz)
	if "deck" not in parts:
		return
	x = -w / 2 + 0.006
	widths = [0.42, 0.34, 0.45, 0.36, 0.0]
	widths[-1] = (w - 0.012) - sum(widths[:-1])
	gaps = [0.012, 0.03, 0.018, 0.026]
	for i, bw in enumerate(widths):
		g0 = gaps[i - 1] / 2 if i > 0 else 0.0
		g1 = gaps[i] / 2 if i < len(gaps) else 0.0
		a, b = x + g0, x + bw - g1
		special = dict(notch=(1, 0.35, 0.09)) if i == 1 else dict(broken="front") if i == 3 else {}
		z1 = dd / 2 - 0.006 - (0.05 if i == 3 else 0.0)
		rough_board(a, b, -dd / 2 + 0.006, z1, deck_bot, h - 0.006, T("wood", "abc"[i % 3]), warp=J(0.01), **special)
		for zz in (-c, 0.0, c):
			peg((a + b) / 2 + J(0.04), h - 0.032, zz + J(0.015))
		x += bw




# ---------------- the rest of the first Shack set, in the approved foundation's style (Nov 15) ----------------
def rough_ring(cx, cy, r_in, fw, n, d, z=0.0, a0=0.0, a1=math.pi, keep_in=None):
	"""A hand-made ring of board pieces round a circle: every piece a little different in width, depth, gap and
	angle, the edges wavy (nothing perfect). keep_in = smallest inner radius allowed (so the door never touches)."""
	fr = K.Frame()
	objs = []
	cuts = [a0] + sorted(a0 + (a1 - a0) * (k + K.rng.uniform(-0.18, 0.18)) / n for k in range(1, n)) + [a1]
	for k in range(n):
		g = K.rng.uniform(0.004, 0.016) / max(r_in, 0.1)
		sa, sb = cuts[k] + g, cuts[k + 1] - g
		ri = r_in + K.rng.uniform(0.0, 0.018)
		if keep_in:
			ri = max(ri, keep_in)
		ro = ri + fw + J(0.018)
		steps = 5
		inner = [(cx + math.cos(sa + (sb - sa) * t / steps) * (ri + J(0.005)), cy + math.sin(sa + (sb - sa) * t / steps) * (ri + J(0.005))) for t in range(steps + 1)]
		if keep_in:
			inner = [(x, y) if math.hypot(x - cx, y - cy) >= keep_in else (cx + (x - cx) * keep_in / math.hypot(x - cx, y - cy), cy + (y - cy) * keep_in / math.hypot(x - cx, y - cy)) for x, y in inner]
		outer = [(cx + math.cos(sb - (sb - sa) * t / steps) * (ro + J(0.012)), cy + math.sin(sb - (sb - sa) * t / steps) * (ro + J(0.012))) for t in range(steps + 1)]
		pts = [(x, max(E, y)) for x, y in inner + outer]
		o = K.slab_poly(fr, pts, z + J(0.003), d * K.rng.uniform(0.9, 1.0), T("wood"))
		_flat(o)
		o["role"] = "board"
		objs.append((o, (sa + sb) / 2, (ri + ro) / 2))
	return objs


def rough_vboard(x0, x1, y0, y1, z, d, m=None, broken_top=False, knot=None):
	"""An upright hand-split board: wavy sides, chipped corners, a slightly uneven front, optionally a broken
	jagged top or a knot bite out of one side (knot = (side, y, size))."""
	pts = []
	H = y1 - y0
	ny = max(3, int(H / 0.3))
	cut = [K.rng.uniform(0.015, 0.045) if K.rng.random() < 0.5 else 0.0 for _ in range(4)]

	def edge(xb, sgn, yy):
		w = J(0.005)
		if knot and knot[0] == sgn and abs(yy - knot[1]) < knot[2]:
			w -= sgn * (knot[2] - abs(yy - knot[1])) * 0.7
		return xb + w
	pts.append((x0 + cut[0], y0))
	pts.append((x1 - cut[1], y0))
	for k in range(1, ny):
		yy = y0 + H * k / ny
		pts.append((edge(x1, 1, yy), yy))
	pts.append((x1, y1 - cut[2]))
	if broken_top:
		for k in range(3, 0, -1):
			pts.append((x0 + (x1 - x0) * k / 4, y1 - K.rng.uniform(0.03, 0.1)))
	pts.append((x0 + cut[3], y1))
	for k in range(ny - 1, 0, -1):
		yy = y0 + H * k / ny
		pts.append((edge(x0, -1, yy), yy))
	n = len(pts)
	front = [z + d / 2 + J(0.004) for _ in pts]
	verts = [(x, y, z - d / 2) for x, y in pts] + [(x, y, f) for (x, y), f in zip(pts, front)]
	faces = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	o = _flat(K.mesh(verts, faces, m or T("wood")))
	o["role"] = "board"
	return o


def hewn(p0, p1, r, stub=False):
	return real_log(p0, p1, r, "hewn", stub=stub)


def pegs_on(x, y, z, s=1):
	peg(x, y, z, "z", s)


def wall_v3(w=2.0, h=2.0, d=0.3):
	"""Shack wall: hand-hewn corner posts, a hewn sill beam and top beam, and four upright split boards of
	different widths with small gaps, a knot bite and one broken top, pegged to the beams."""
	px = w / 2 - 0.006 - 0.145
	for s_ in (-1, 1):
		hewn((s_ * px, 0.012, 0.0), (s_ * px + J(0.008), h - 0.014, J(0.006)), 0.14)
	hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	hewn((-px, 1.8, 0.0), (px, 1.8 + J(0.008), 0.0), 0.12)
	x0, x1 = -px + 0.13, px - 0.13
	widths = [0.36, 0.42, 0.33]
	widths.append((x1 - x0) - sum(widths))
	gaps = [0.012, 0.024, 0.016]
	x = x0
	for i, bw in enumerate(widths):
		a = x + (gaps[i - 1] / 2 if i else 0.0)
		b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
		rough_vboard(a, b, 0.17, 1.72, J(0.008), 0.07, broken_top=(i == 2), knot=(1, 1.05, 0.07) if i == 1 else None)
		for y in (0.115, 1.8):
			pegs_on((a + b) / 2 + J(0.04), y, 0.112 if y > 1 else 0.093)
		x += bw


def doorway_v3(w=2.0, h=2.0, d=0.3):
	"""Shack round doorway (hobbit style): a ring of thick bent-board segments round the circle, upright boards
	cut exactly round it, slim hewn end posts that stay clear of the ring, and the same hewn top beam."""
	r, cy = DOOR_R, DOOR_CY
	px = w / 2 - 0.006 - 0.056
	for s_ in (-1, 1):
		hewn((s_ * px, 0.012, 0.0), (s_ * px, h - 0.014, 0.0), 0.056)
	hewn((-px - 0.04, 1.8, 0.0), (px + 0.04, 1.8 + J(0.008), 0.0), 0.12)
	fr = K.Frame()
	fw = 0.11
	R = r + 0.05
	a0 = math.asin(-cy / (r + fw))
	for (o, am, rm) in rough_ring(0.0, cy, r + 0.008, fw, 11, 0.22, a0=a0, a1=math.pi - a0, keep_in=r + 0.008):
		if K.rng.random() < 0.8:
			pegs_on(math.cos(am) * rm + J(0.01), cy + math.sin(am) * rm, 0.098)
	# upright boards between the end posts, cut round the circle
	xa, xb = -px + 0.05, px - 0.05
	widths = [0.31, 0.27, 0.36, 0.3, 0.33]
	widths.append((xb - xa) - sum(widths))
	x = xa
	top = lambda xx: 1.69
	for i, bw in enumerate(widths):
		a, b = x + K.rng.uniform(0.004, 0.012), x + bw - K.rng.uniform(0.004, 0.012)
		dz = J(0.01)
		segs = []
		if b <= -R or a >= R:
			segs.append((a, b, lambda xx: E, top))
		else:
			if a < -R:
				segs.append((a, -R, lambda xx: E, top))
			if b > R:
				segs.append((R, b, lambda xx: E, top))
			ca, cb = max(a, -R + 0.002), min(b, R - 0.002)
			above = lambda xx: cy + math.sqrt(max(0.0, R * R - xx * xx))
			below = lambda xx: max(E + 0.004, cy - math.sqrt(max(0.0, R * R - xx * xx)))
			segs.append((ca, cb, above, top))
			if max(below(ca), below(cb)) > E + 0.03:
				segs.append((ca, cb, lambda xx: E, below))
		for (sa, sb, lo, hi) in segs:
			if sb - sa > 0.02:
				before = set(bpy.data.objects)
				K.plank_shape(fr, sa, sb, lo, hi, dz, 0.07, T("wood"), k=8)
				for o in set(bpy.data.objects) - before:
					o["role"] = "board"
		x += bw
	before = set(bpy.data.objects)
	blk((0, 0.022, 0), (2 * math.sqrt((r + fw) ** 2 - cy ** 2) + 0.06, 0.036, 0.24), T("wood", "dark"), bevel=0.008)  # threshold
	for o in set(bpy.data.objects) - before:
		o["role"] = "board"


def door_v3(w=None, h=None, d=0.12):
	"""Round Shack door, hand-made: five split boards of different widths and thickness, their round ends a
	little ragged, a rim of uneven board pieces pegged on, two long copper hinge straps lying flat on the boards
	(inside the circle), a round copper knob. It stays inside the doorway ring all round."""
	r, cy = DOOR_R - 0.012, DOOR_CY
	fr = K.Frame()
	widths = [0.3, 0.34, 0.26, 0.33]
	widths.append(2 * r - sum(widths))
	x = -r
	for i, bw in enumerate(widths):
		a, b = x + K.rng.uniform(0.003, 0.008), x + bw - K.rng.uniform(0.003, 0.008)
		short = K.rng.uniform(0.0, 0.025)
		lo = lambda xx: max(E, cy - math.sqrt(max(0.0, r * r - xx * xx)))
		hi = (lambda sh: (lambda xx: cy + math.sqrt(max(0.0, r * r - xx * xx)) - sh - abs(J(0.012))))(short)
		before = set(bpy.data.objects)
		K.plank_shape(fr, a, b, lo, hi, -0.006 + J(0.004), 0.06 * K.rng.uniform(0.9, 1.0), T("wood"), k=8)
		for o in set(bpy.data.objects) - before:
			o["role"] = "board"
			_flat(o)
		x += bw
	a0 = math.asin(-cy / r)
	for (o, am, rm) in rough_ring(0.0, cy, r - 0.1, 0.066, 10, 0.022, z=0.035, a0=a0, a1=math.pi - a0):
		kit.rivet(K.G((math.cos(am) * rm, cy + math.sin(am) * rm, 0.044)), T("wood", "dark"), r=0.013)
	cu = kit.tex_mat("copper", "a")
	for y in (cy - 0.33, cy + 0.33):
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))  # stays inside the rim, on the boards
		x0, x1 = -hw + 0.02, -hw + 0.02 + min(0.8, 1.4 * hw)
		before = set(bpy.data.objects)
		K.slab_poly(fr, [(x0, y - 0.035), (x1 - 0.06, y - 0.03), (x1, y), (x1 - 0.06, y + 0.03), (x0, y + 0.035)], 0.028, 0.008, cu)
		for xx in (x0 + 0.08, (x0 + x1) / 2, x1 - 0.1):
			kit.rivet(K.G((xx, y, 0.03)), kit.tex_mat("copper", "dark"), r=0.009)
	kit.cylinder(0.065, 0.01, K.G((0, cy, 0.029)), cu, rot=(90, 0, 0), verts=12, bevel=0.003)
	kit.rivet(K.G((0, cy, 0.034)), cu, r=0.024)
	for y in (cy - 0.3, cy + 0.3):  # back battens
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))
		before = set(bpy.data.objects)
		blk((J(0.02), y, -0.045), (2 * hw - 0.04, 0.11, 0.02), T("wood", "dark"), bevel=0.006, rz=J(2))
		for o in set(bpy.data.objects) - before:
			o["role"] = "board"


def window_wall_v3(w=2.0, h=2.0, d=0.3, ow=1.0, oh=0.8, ob=0.6):
	"""Shack window wall: like the wall (hewn posts and beams, split boards), with a window opening framed by
	hand-hewn sill and lintel pieces and rough side boards, a crooked cross bar, and two narrow plank shutters
	swung open on copper hinges. Everything a little uneven."""
	px = w / 2 - 0.006 - 0.145
	for s_ in (-1, 1):
		hewn((s_ * px, 0.012, 0.0), (s_ * px + J(0.008), h - 0.014, J(0.006)), 0.14)
	hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	hewn((-px, 1.8, 0.0), (px, 1.8 + J(0.008), 0.0), 0.12)
	top = ob + oh
	x0, x1 = -px + 0.13, px - 0.13
	fr = K.Frame()
	widths = [0.27, 0.36, 0.31, 0.33]
	widths.append((x1 - x0) - sum(widths))
	x = x0
	for i, bw in enumerate(widths):
		a, b = x + K.rng.uniform(0.007, 0.014), x + bw - K.rng.uniform(0.007, 0.014)
		dz = J(0.008)
		hl, hr = -ow / 2 - 0.02, ow / 2 + 0.02
		parts = []
		if b <= hl or a >= hr:
			parts.append((a, b, 0.17, 1.72))
		else:
			if a < hl:
				parts.append((a, hl - 0.008, 0.17, 1.72))
			if b > hr:
				parts.append((hr + 0.008, b, 0.17, 1.72))
			ca, cb = max(a, hl + 0.008), min(b, hr - 0.008)
			parts.append((ca, cb, 0.17, ob - 0.06))
			parts.append((ca, cb, top + 0.07, 1.72))
		for (pa, pb, y0, y1) in parts:
			if pb - pa > 0.03 and y1 - y0 > 0.05:
				rough_vboard(pa, pb, y0, y1, dz, 0.07, broken_top=(i == 4 and y1 > 1.7))
		x += bw
	# window frame: hewn sill and lintel, rough side boards, all pegged
	hewn((-ow / 2 - 0.12, ob - 0.05, 0.02), (ow / 2 + 0.12, ob - 0.05 + J(0.01), 0.02), 0.065)
	hewn((-ow / 2 - 0.14, top + 0.06, 0.02), (ow / 2 + 0.14, top + 0.06 + J(0.01), 0.02), 0.07)
	for s_ in (-1, 1):
		rough_vboard(s_ * ow / 2 + (0.0 if s_ > 0 else -0.09), s_ * ow / 2 + (0.09 if s_ > 0 else 0.0), ob - 0.02, top + 0.02, 0.03, 0.06)
		for y in (ob + 0.1, top - 0.1):
			pegs_on(s_ * (ow / 2 + 0.045), y, 0.065)
	for xx in (-ow / 2 - 0.08, ow / 2 + 0.08):
		pegs_on(xx, ob - 0.05, 0.085)
		pegs_on(xx, top + 0.06, 0.09)
	# a crooked cross bar and a middle bar
	blk((J(0.01), ob + oh / 2, 0.02), (0.05, oh, 0.045), T("wood", "dark"), bevel=0.008, rz=J(2))["role"] = "brace"
	blk((0, ob + oh / 2 + J(0.02), 0.02), (ow, 0.045, 0.045), T("wood", "dark"), bevel=0.008, rz=J(2))["role"] = "brace"
	# two narrow shutters swung open against the boards, on flat copper hinges
	cu = kit.tex_mat("copper", "a")
	for s_ in (-1, 1):
		sx0 = s_ * (ow / 2 + 0.08)
		for k in range(2):
			a, b = sx0 + s_ * (0.004 + k * 0.062), sx0 + s_ * (0.004 + k * 0.062 + 0.058)
			rough_vboard(min(a, b), max(a, b), ob - 0.01 + J(0.01), top - 0.01 + J(0.01), 0.072, 0.03)
		for y in (ob + 0.15, top - 0.15):
			K.slab_poly(fr, [(sx0, y - 0.025), (sx0 + s_ * 0.1, y - 0.02), (sx0 + s_ * 0.12, y), (sx0 + s_ * 0.1, y + 0.02), (sx0, y + 0.025)], 0.091, 0.008, cu)
			kit.rivet(K.G((sx0 + s_ * 0.06, y, 0.093)), kit.tex_mat("copper", "dark"), r=0.009)


def roof_v3(w=2.0, rise=1.0, dd=2.0):
	"""Shack roof (the owner liked it): the same big stepped shingles, now each one a different painting, on
	hand-hewn rafters, a hewn ridge beam at the top, wooden pegs instead of iron bolts."""
	sl = K.Slope("z", dd / 2, -dd / 2, rise, 0.33, vlo=-w / 2, vhi=w / 2)
	pl = sl.planes()
	for v in (-0.82, 0.82):
		a, b = sl.P(sl.u(0.1), v, 0.09), sl.P(sl.u(sl.run - 0.08), v, 0.09)
		hewn(a, b, 0.088)
	before = set(bpy.data.objects)
	sl.strip(0.0, sl.run, sl.vlo, sl.vhi, pl, lambda u: 0.165, lambda u: 0.185, T("wood", "dark"))
	for o in set(bpy.data.objects) - before:
		o["role"] = "board"
	Er, OV, TH = 0.46, 0.14, 0.05
	i = 0
	while i * Er < sl.run - 0.1:
		d0, d1 = i * Er, min(i * Er + Er + OV, sl.run - 0.16)
		hb = (lambda a_: (lambda u: 0.183 + 0.06 * (1 - (sl.d(u) - a_) / (Er + OV))))(d0)
		ht = (lambda f: (lambda u: f(u) + TH))(hb)
		v = sl.vlo + (0.0 if i % 2 == 0 else -0.16)
		pl = sl.planes(e=K.E_IN + 0.005 * (i % 2))  # course ends never share a plane
		while v < sl.vhi - 0.02:
			sw = 0.31 + J(0.04)
			before = set(bpy.data.objects)
			poly = sl.strip(d0, d1, max(sl.vlo, v) + 0.008, min(sl.vhi, v + sw) - 0.008, pl, hb, ht, T("shingle", "a"), min_area=0.004)
			for o in set(bpy.data.objects) - before:
				o["role"] = "shingle"
			if poly and min(sl.vhi, v + sw) - max(sl.vlo, v) > 0.15:
				vm = (max(sl.vlo, v) + min(sl.vhi, v + sw)) / 2
				pp = sl.P(sl.u(d0 + 0.08), vm, hb(sl.u(d0 + 0.08)) + TH - 0.004)
				kit.rivet(K.G(pp), T("wood", "dark"), r=0.02)
			v += sw
		i += 1
	a, b = sl.P(sl.u(sl.run - 0.1), sl.vlo + 0.03, 0.235), sl.P(sl.u(sl.run - 0.1), sl.vhi - 0.03, 0.235)
	hewn(a, b, 0.075)


# ---------------- paint: one painted picture per part, like the turnaround sheet ----------------
# Textures from the ChatGPT texture sheet (assets/textures/kit/shack_*.png): bark, plank, shingle, logend, footing, darkwood.
PAINT = {"bark": "shackbark", "wood": "shackplank", "shingle": "shackshingle", "greystone": "shackstone", "wood_dark": "shackdark"}


def fit_uv(o, mode):
	"""Wrap ONE whole painting around a part: 'plank'/'shingle' = the face's longest side runs along the picture's
	grain (v), stretched to fit; 'log' = round the log (u) and along it (v, repeating every metre)."""
	me = o.data
	if not me.uv_layers:
		me.uv_layers.new()
	uv = me.uv_layers.active.data
	vs = [v.co for v in me.vertices]
	lo = [min(v[k] for v in vs) for k in range(3)]
	hi = [max(v[k] for v in vs) for k in range(3)]
	ext = [max(1e-4, hi[k] - lo[k]) for k in range(3)]
	if mode == "log":
		c = [(lo[k] + hi[k]) / 2 for k in range(3)]
		ax = max(range(3), key=lambda k: ext[k])
		o1, o2 = [k for k in range(3) if k != ax]
		for poly in me.polygons:
			for li in poly.loop_indices:
				v = vs[me.loops[li].vertex_index]
				ang = math.atan2(v[o2] - c[o2], v[o1] - c[o1])
				uv[li].uv = ((ang / (2 * math.pi)) % 1.0 * 1.5, (v[ax] - lo[ax]) / 1.0)
		return
	for poly in me.polygons:
		n = poly.normal
		dom = max(range(3), key=lambda k: abs(n[k]))
		a1, a2 = [k for k in range(3) if k != dom]
		# grain (v) along the longer of the two in-face directions
		if ext[a1] > ext[a2]:
			a1, a2 = a2, a1
		for li in poly.loop_indices:
			v = vs[me.loops[li].vertex_index]
			uv[li].uv = ((v[a1] - lo[a1]) / ext[a1], (v[a2] - lo[a2]) / ext[a2])


def paint():
	"""Swap the kit textures for the Shack's own painted ones and fit each part's picture to it."""
	for o in list(bpy.data.objects):
		if o.type != "MESH" or not o.data.materials:
			continue
		m = o.data.materials[0]
		kind = m.name.rsplit("_", 1)[0]
		variant = m.name.rsplit("_", 1)[-1]
		if m.name.startswith("wood_dark"):
			kind, variant = "wood_dark", "a"
		if kind not in PAINT:
			continue
		tex = PAINT[kind]
		mode = "log" if kind == "bark" else "plank"
		if kind == "wood" and min(o.dimensions) < 0.02:  # the thin end-grain cap discs of a log
			tex, mode = "shacklogend", "plank"
		nm = kit.tex_mat(tex, variant if variant in ("a", "b", "c") else "a")
		o.data.materials.clear()
		o.data.materials.append(nm)
		fit_uv(o, mode)


def _uvs(o):
	me = o.data
	if not me.uv_layers:
		me.uv_layers.new()
	return me.uv_layers.active.data


def paint3():
	"""Beetle-style paint: every surface uses the Shack's painted textures at their real size (no stretching):
	bark round the logs (the painted log end on chopped ends), one painted plank across each board's width,
	lumpy painted stone, iron nails. Each part starts at a different spot of its picture so none repeat."""
	barks = [kit.tex_mat("shackbark", f"v{i}{t}") for i in range(4) for t in ("", "d", "r")]
	K.rng.shuffle(barks)
	ends = [kit.tex_mat("shacklogend", f"v{i}") for i in range(4)]
	log_i = [0]

	def next_log():  # every log its own bark painting and shade, and its own chopped end (Rule 6)
		k = log_i[0]
		log_i[0] += 1
		return barks[k % len(barks)], ends[k % len(ends)]
	mats = {"shackbark": [kit.tex_mat("shackbark", f"v{i}") for i in range(4)],
		"shacklogend": [kit.tex_mat("shacklogend", f"v{i}") for i in range(4)],
		"shackstone": [kit.tex_mat("shackstone", v) for v in "abc"]}
	planks = [kit.tex_mat("shackplank", f"v{i}") for i in range(8)]
	K.rng.shuffle(planks)
	plank_i = [0]

	darks = [kit.tex_mat("shackplank", f"v{i}") for i in (1, 3, 5, 7)]

	def next_plank_dark():
		return darks[log_i[0] % len(darks)]

	shingles = [kit.tex_mat("shackshingle", f"v{i}") for i in range(8)] if (K.OUT.parents[1] / "textures/kit/shackshingle_v0.png").exists() else [kit.tex_mat("shackshingle", v) for v in "abc"]
	K.rng.shuffle(shingles)
	sh_i = [0]

	def next_shingle():
		m = shingles[sh_i[0] % len(shingles)]
		sh_i[0] += 1
		return m

	def next_plank():  # every board/brace a different painting (Rule 6)
		m = planks[plank_i[0] % len(planks)]
		plank_i[0] += 1
		return m
	for o in list(bpy.data.objects):
		if o.type != "MESH":
			continue
		role = o.get("role")
		if o.get("painted"):
			continue
		o["painted"] = True
		me = o.data
		if role == "log":
			p0, p1 = Vector(o["axis"][0]), Vector(o["axis"][1])
			P0, P1 = Vector(K.G(tuple(p0))), Vector(K.G(tuple(p1)))  # Blender space
			ax = (P1 - P0).normalized()
			up = Vector((0, 0, 1)) if abs(ax.z) < 0.9 else Vector((1, 0, 0))
			u_ = ax.cross(up).normalized()
			v_ = ax.cross(u_)
			me.materials.clear()
			mb, me_ = next_log()
			me.materials.append(mb)
			me.materials.append(me_)
			uv = _uvs(o)
			ou, ov = K.rng.random(), K.rng.random()
			r = float(o["r"])
			hewn = o.get("style") == "hewn"
			if hewn:
				me.materials.append(next_plank_dark())
			for poly in me.polygons:
				end = abs(poly.normal.dot(ax)) > 0.7
				poly.material_index = 1 if end else 0
				if hewn and not end:
					pc0 = poly.center - P0
					ang = math.degrees(math.atan2(pc0.dot(v_), pc0.dot(u_)))
					if abs(((ang - 45) % 90) - 45) > 24:  # the flat chopped faces (bark stays on the corners)
						poly.material_index = 2
				pc = poly.center - P0
				ac = math.atan2(pc.dot(v_), pc.dot(u_))
				for li in poly.loop_indices:
					q = me.vertices[me.loops[li].vertex_index].co - P0
					if end:  # the log end: one whole painted log end over the cut face
						uv[li].uv = (0.5 + q.dot(u_) / (2.3 * r), 0.5 + q.dot(v_) / (2.3 * r))
						continue
					a = math.atan2(q.dot(v_), q.dot(u_))
					a = ac + ((a - ac + math.pi) % math.tau - math.pi)
					uv[li].uv = (ou + a * r / 0.32, ov + q.dot(ax) / 0.5)
		elif role in ("board", "brace"):
			me.materials.clear()
			me.materials.append(next_plank())
			uv = _uvs(o)
			vs = [v.co for v in me.vertices]
			lo = [min(v[k] for v in vs) for k in range(3)]
			hi = [max(v[k] for v in vs) for k in range(3)]
			ext = [hi[k] - lo[k] for k in range(3)]
			ln = max(range(3), key=lambda k: ext[k])  # along the board (grain)
			wd = max((k for k in range(3) if k != ln), key=lambda k: ext[k])  # across the board
			th = [k for k in range(3) if k not in (ln, wd)][0]
			ov = K.rng.random()
			flip = K.rng.random() < 0.5
			for poly in me.polygons:
				dom = max(range(3), key=lambda k: abs(poly.normal[k]))
				for li in poly.loop_indices:
					q = me.vertices[me.loops[li].vertex_index].co
					across = (q[wd] - lo[wd]) / max(ext[wd], 1e-4) if dom == th else (q[th] - lo[th]) / 0.4 + 0.1
					if flip:
						across = 1 - across
					along = ov + (q[ln] - lo[ln]) / 1.1 if dom != ln else (q[wd] - lo[wd]) / 0.4
					uv[li].uv = (across * 0.96 + 0.02, along)
		elif role == "shingle":
			me.materials.clear()
			me.materials.append(next_shingle())
			uv = _uvs(o)
			vs = [vv.co for vv in me.vertices]
			lo = [min(vv[k] for vv in vs) for k in range(3)]
			hi = [max(vv[k] for vv in vs) for k in range(3)]
			ext = [max(1e-4, hi[k] - lo[k]) for k in range(3)]
			ln = 1 if ext[1] >= ext[0] else 0  # Blender y = down the slope for a z-axis roof
			wd = 1 - ln
			for poly in me.polygons:
				for li in poly.loop_indices:
					q = me.vertices[me.loops[li].vertex_index].co
					uv[li].uv = ((q[wd] - lo[wd]) / ext[wd], (q[ln] - lo[ln]) / ext[ln])
		elif role == "stone":
			me.materials.clear()
			me.materials.append(K.rng.choice(mats["shackstone"]))
			kit._uv_box(o, 0.45)


def _hewn():
	global LOG_STYLE
	LOG_STYLE = "hewn"
	foundation_v3()
	LOG_STYLE = "round"


def _mix():
	"""Owner's pick (Nov 15): option A's deck on option B's hand-hewn under-structure."""
	global LOG_STYLE
	K.rng.seed(sum(map(ord, "foundation3v2")))  # replay option A exactly (same random numbers)
	foundation_v3()
	paint3()
	for o in list(bpy.data.objects):  # keep only A's deck boards and the pegs in them
		zmin = min((o.matrix_world @ v.co).z for v in o.data.vertices) if o.type == "MESH" else 0.0
		keep = o.get("role") == "board" or zmin > 0.85
		if not keep:
			bpy.data.objects.remove(o, do_unlink=True)
	for o in bpy.data.objects:
		o["painted"] = True
	LOG_STYLE = "hewn"
	K.rng.seed(sum(map(ord, "foundation_hewnv2")))
	foundation_v3(parts=("under",))
	LOG_STYLE = "round"


PIECES = {"foundation3": foundation_v3, "foundation_hewn": _hewn, "foundation_mix": _mix,
	"wall_v3": wall_v3, "doorway_v3": doorway_v3, "door_v3": door_v3, "roof_26_v3": lambda: roof_v3(2.0, 1.0),
	"window_wall_v3": window_wall_v3, "foundation": foundation, "wall": wall, "doorway": doorway, "door": door, "roof_26": lambda: roof(2.0, 1.0)}


def make_grey():
	g = bpy.data.materials.new("clay_white")
	g.use_nodes = True
	g.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.82, 0.8, 0.77, 1)
	g.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
	for o in bpy.data.objects:
		if o.type == "MESH":
			o.data.materials.clear()
			o.data.materials.append(g)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), K.OUT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	out_dir.mkdir(parents=True, exist_ok=True)
	# install=1: write the approved v3 pieces under their game names (assets/models/build/<piece>__plank_root.glb)
	GAME_NAME = {"foundation_mix": "foundation", "wall_v3": "wall", "doorway_v3": "doorway", "door_v3": "door", "roof_26_v3": "roof_26",
		"window_wall_v3": "window_wall"}
	install = "install=1" in args
	if install:
		names = [n for n in names if n in GAME_NAME] or list(GAME_NAME)
	for name in names:
		K.rng.seed(sum(map(ord, name + "v2")))
		kit.reset()
		PIECES[name]()
		K.fit_check(name.rstrip("3").replace("_hewn", "").replace("_mix", "").replace("_v", "") if not name.endswith("_v3") else name[:-3])
		if grey:
			make_grey()
		elif name.endswith("3") or name.endswith("_hewn") or name.endswith("_mix") or name.endswith("_v3"):
			paint3()
		else:
			paint()
		fname = GAME_NAME[name] if install else name
		kit.save(str(out_dir / f"{fname}__plank_root.glb"), None, recenter=False, tex_size=512)
		print("PIECE_OK", name)
