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
TOP_BEAM = 1.858   # v3 walls: the hewn top beam's centre; its top reaches the top of the wall (no gap under roofs/floors)


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
	cz = dd / 2 - 0.22
	czs = (-cz, 0.0, cz) if dd > 1.5 else (-cz, cz)
	deck_bot = h - 0.11
	r_up, r_lo = (0.095, 0.11) if st == "round" else (0.09, 0.1)
	y_up = deck_bot - r_up + 0.012
	y_lo = y_up - r_up - r_lo + 0.035
	leg_top = y_lo - r_lo + 0.03
	for sx in ((-1, 1) if "under" in parts else ()):
		for sz in (-1, 1):
			x, z = sx * c, sz * cz
			boulder((x + J(0.02), 0.07, z + J(0.02)), 0.21 if dd > 1.5 else 0.16, 0.1, 0.2 if dd > 1.5 else 0.16)
			real_log((x, 0.1, z), (x + J(0.012), leg_top, z + J(0.012)), 0.165, st, stub=False)
	for sx in ((-1, 1) if "under" in parts else ()):
		real_log((sx * c, y_lo, -dd / 2 + 0.05), (sx * c + J(0.01), y_lo, dd / 2 - 0.05), r_lo, st)
	for z in (czs if "under" in parts else ()):
		real_log((-w / 2 + 0.05, y_up, z + J(0.02)), (w / 2 - 0.05, y_up, z + J(0.02)), r_up, st)
	for sz in ((-1, 1) if "under" in parts else ()):  # a rough diagonal brace board, pegged into the MIDDLE of each leg
		z = sz * (cz + 0.13)
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
		for zz in czs:
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
	ya, yb = (y1, y1) if not isinstance(y1, tuple) else y1
	top = lambda xx: ya + (yb - ya) * (xx - x0) / max(1e-4, x1 - x0)
	y1 = max(ya, yb)
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
		yy = y0 + (top(x1) - y0) * k / ny
		pts.append((edge(x1, 1, yy), yy))
	pts.append((x1, top(x1) - cut[2]))
	if broken_top:
		for k in range(3, 0, -1):
			xx = x0 + (x1 - x0) * k / 4
			pts.append((xx, top(xx) - K.rng.uniform(0.03, 0.1)))
	pts.append((x0 + cut[3], top(x0 + cut[3])))
	for k in range(ny - 1, 0, -1):
		yy = y0 + (top(x0) - y0) * k / ny
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
		hewn((s_ * px, 0.012, 0.0), (s_ * px + J(0.008), h - 0.05, J(0.006)), 0.14)
	hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	hewn((-px, TOP_BEAM, 0.0), (px, TOP_BEAM + J(0.004), 0.0), 0.12)
	x0, x1 = -px + 0.13, px - 0.13
	widths = [0.36, 0.42, 0.33]
	widths.append((x1 - x0) - sum(widths))
	gaps = [0.012, 0.024, 0.016]
	x = x0
	for i, bw in enumerate(widths):
		a = x + (gaps[i - 1] / 2 if i else 0.0)
		b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
		rough_vboard(a, b, 0.17, TOP_BEAM - 0.08, J(0.008), 0.07, broken_top=(i == 2), knot=(1, 1.05, 0.07) if i == 1 else None)
		for y in (0.115, TOP_BEAM):
			pegs_on((a + b) / 2 + J(0.04), y, 0.112 if y > 1 else 0.093)
		x += bw


def doorway_v3(w=2.0, h=2.0, d=0.3):
	"""Shack round doorway (hobbit style): a ring of thick bent-board segments round the circle, upright boards
	cut exactly round it, slim hewn end posts that stay clear of the ring, and the same hewn top beam."""
	r, cy = DOOR_R, DOOR_CY
	px = w / 2 - 0.006 - 0.056
	for s_ in (-1, 1):
		hewn((s_ * px, 0.012, 0.0), (s_ * px, h - 0.014, 0.0), 0.056)
	hewn((-px - 0.04, TOP_BEAM, 0.0), (px + 0.04, TOP_BEAM + J(0.004), 0.0), 0.12)
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
	top = lambda xx: TOP_BEAM - 0.11
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
	little ragged, a rim of uneven board pieces pegged on, two long dark-wood hinge straps lying flat on the boards
	(inside the circle), a round wooden knob. It stays inside the doorway ring all round."""
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
	cu = T("wood", "dark")  # wooden hinges and knob: the Shack door needs no copper (owner, Nov 16)
	for y in (cy - 0.33, cy + 0.33):
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))  # stays inside the rim, on the boards
		x0, x1 = -hw + 0.02, -hw + 0.02 + min(0.8, 1.4 * hw)
		before = set(bpy.data.objects)
		K.slab_poly(fr, [(x0, y - 0.035), (x1 - 0.06, y - 0.03), (x1, y), (x1 - 0.06, y + 0.03), (x0, y + 0.035)], 0.028, 0.008, cu)
		for xx in (x0 + 0.08, (x0 + x1) / 2, x1 - 0.1):
			kit.rivet(K.G((xx, y, 0.03)), T("wood", "dark"), r=0.009)
	kit.cylinder(0.065, 0.01, K.G((0, cy, 0.029)), cu, rot=(90, 0, 0), verts=12, bevel=0.003)
	kit.rivet(K.G((0, cy, 0.034)), cu, r=0.024)
	for y in (cy - 0.3, cy + 0.3):  # back battens
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))
		before = set(bpy.data.objects)
		blk((J(0.02), y, -0.045), (2 * hw - 0.04, 0.11, 0.02), T("wood", "dark"), bevel=0.006, rz=J(2))
		for o in set(bpy.data.objects) - before:
			o["role"] = "board"


def window_wall_v3(w=2.0, h=2.0, d=0.3, ow=1.0, oh=0.8, ob=0.6, shutters=True, sides=True, post_r=0.14):
	"""Shack window wall: like the wall (hewn posts and beams, split boards), with a window opening framed by
	hand-hewn sill and lintel pieces and rough side boards, a crooked cross bar, and two narrow plank shutters
	swung open on wooden hinges. Everything a little uneven."""
	px = w / 2 - 0.006 - 0.145
	for s_ in (-1, 1):
		hewn((s_ * px, 0.012 if post_r >= 0.14 else 0.03, 0.0), (s_ * px + J(0.008), h - 0.05, J(0.006)), post_r)
	hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	hewn((-px, TOP_BEAM, 0.0), (px, TOP_BEAM + J(0.004), 0.0), 0.12)
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
			parts.append((a, b, 0.17, TOP_BEAM - 0.08))
		else:
			if a < hl:
				parts.append((a, hl - 0.008, 0.17, TOP_BEAM - 0.08))
			if b > hr:
				parts.append((hr + 0.008, b, 0.17, TOP_BEAM - 0.08))
			ca, cb = max(a, hl + 0.008), min(b, hr - 0.008)
			parts.append((ca, cb, 0.17, ob - 0.06))
			parts.append((ca, cb, top + 0.07, TOP_BEAM - 0.08))
		for (pa, pb, y0, y1) in parts:
			if pb - pa > 0.03 and y1 - y0 > 0.05:
				rough_vboard(pa, pb, y0, y1, dz, 0.07, broken_top=(i == 4 and y1 > 1.7))
		x += bw
	# window frame: hewn sill and lintel, rough side boards, all pegged
	hewn((-ow / 2 - 0.12, ob - 0.05, 0.02), (ow / 2 + 0.12, ob - 0.05 + J(0.01), 0.02), 0.065)
	hewn((-ow / 2 - 0.14, top + 0.06, 0.02), (ow / 2 + 0.14, top + 0.06 + J(0.01), 0.02), 0.07)
	for s_ in ((-1, 1) if sides else ()):
		rough_vboard(s_ * ow / 2 + (0.0 if s_ > 0 else -0.09), s_ * ow / 2 + (0.09 if s_ > 0 else 0.0), ob - 0.02, top + 0.02, 0.03, 0.06)
		for y in (ob + 0.1, top - 0.1):
			pegs_on(s_ * (ow / 2 + 0.045), y, 0.065)
	for xx in ((-ow / 2 - 0.08, ow / 2 + 0.08) if sides else (-ow / 2 + 0.1, ow / 2 - 0.1)):
		pegs_on(xx, ob - 0.05, 0.085)
		pegs_on(xx, top + 0.06, 0.09)
	# a crooked cross bar and a middle bar
	blk((J(0.01), ob + oh / 2, 0.02), (0.05, oh, 0.045), T("wood", "dark"), bevel=0.008, rz=J(2))["role"] = "brace"
	blk((0, ob + oh / 2 + J(0.02), 0.028), (ow, 0.045, 0.045), T("wood", "dark"), bevel=0.008, rz=J(2))["role"] = "brace"  # 8 mm in front of the upright bar: no shared faces where they cross
	# two narrow shutters swung open against the boards, on flat wooden hinges
	cu = T("wood", "dark")  # wooden shutter hinges (owner, Nov 16: wood, not copper)
	for s_ in ((-1, 1) if shutters else ()):
		sx0 = s_ * (ow / 2 + 0.08)
		for k in range(2):
			a, b = sx0 + s_ * (0.004 + k * 0.062), sx0 + s_ * (0.004 + k * 0.062 + 0.058)
			rough_vboard(min(a, b), max(a, b), ob - 0.01 + J(0.01), top - 0.01 + J(0.01), 0.072, 0.03)
		for y in (ob + 0.15, top - 0.15):
			K.slab_poly(fr, [(sx0, y - 0.025), (sx0 + s_ * 0.1, y - 0.02), (sx0 + s_ * 0.12, y), (sx0 + s_ * 0.1, y + 0.02), (sx0, y + 0.025)], 0.091, 0.008, cu)
			kit.rivet(K.G((sx0 + s_ * 0.06, y, 0.093)), T("wood", "dark"), r=0.009)


def _inside(u, v, pl, m=0.0):
	return all(a_ * u + b_ * v <= c_ - m for (a_, b_, c_) in pl)


def shingle_slope(sl, extra=(), rafters=(-0.9, 0.9), sark_cut=(), sh_cut=(), base=0.0, eave=True):
	"""One Shack roof slope, in layers from below: hand-hewn rafters, a board deck (sarking), then courses of big
	stepped shingles, each a different painting, pegged. `extra` = diagonal cuts (corner roofs); sark_cut /
	sh_cut = cuts for the deck / shingles only (they stop short of a valley board); base = lower everything
	(thin pieces with no rafters)."""
	pl = sl.planes(extra)
	if eave:  # a hewn eave beam along the low edge, sitting on the wall top: no gap between roof and wall
		vs = [sl.vlo + 0.05 + k * 0.01 for k in range(int((sl.vhi - sl.vlo - 0.1) / 0.01) + 1)]
		ok = [v for v in vs if _inside(sl.u(0.115), v, pl)]
		if len(ok) > 20:
			va = ok[0] + (0.0 if ok[0] < sl.vlo + 0.055 else 0.12)   # stay clear of a diagonal cut
			vb = ok[-1] - (0.0 if ok[-1] > sl.vhi - 0.055 else 0.12)
			real_log(sl.P(sl.u(0.115), va, 0.088 - base), sl.P(sl.u(0.115), vb, 0.088 - base), 0.088, "round", stub=False)  # round: no flat corner lying on the boards
	for v in rafters:
		if not extra:
			d0, d1 = (0.19 if eave else 0.1), sl.run - 0.08
		else:
			rg = sl.d_range(v, sl.planes(list(extra) + list(sark_cut)), half=0.1)  # stop before a valley board
			if not rg or rg[1] - rg[0] < 0.35:
				continue
			d0, d1 = rg[0] + (0.19 if eave and rg[0] < 0.05 else 0.1), rg[1] - 0.08
		hewn(sl.P(sl.u(d0), v, 0.09 - base), sl.P(sl.u(d1), v, 0.09 - base), 0.088)
	before = set(bpy.data.objects)
	sl.strip(0.0, sl.run, sl.vlo, sl.vhi, sl.planes(list(extra) + list(sark_cut)), lambda u: 0.165 - base, lambda u: 0.185 - base, T("wood", "dark"))
	for o in set(bpy.data.objects) - before:
		o["role"] = "board"
	Er, OV, TH = 0.46, 0.14, 0.05
	cuts = list(extra) + list(sh_cut)
	i = 0
	while i * Er < sl.run - 0.1:
		d0, d1 = i * Er, min(i * Er + Er + OV, sl.run - 0.16)
		hb = (lambda a_: (lambda u: 0.183 - base + 0.06 * (1 - (sl.d(u) - a_) / (Er + OV))))(d0)
		ht = (lambda f: (lambda u: f(u) + TH))(hb)
		v = sl.vlo + (0.0 if i % 2 == 0 else -0.16)
		pl = sl.planes([(a_, b_, c_ - 0.004 * (i % 2)) for (a_, b_, c_) in cuts], e=K.E_IN + 0.005 * (i % 2))  # course ends never share a plane
		while v < sl.vhi - 0.02:
			sw = 0.31 + J(0.04)
			before = set(bpy.data.objects)
			poly = sl.strip(d0, d1, max(sl.vlo, v) + 0.008, min(sl.vhi, v + sw) - 0.008, pl, hb, ht, T("shingle", "a"), min_area=0.004 if not cuts else 0.012)
			for o in set(bpy.data.objects) - before:
				o["role"] = "shingle"
				o["down"] = 1 if sl.axis == "z" else 0
			if poly and min(sl.vhi, v + sw) - max(sl.vlo, v) > 0.15:
				vm = (max(sl.vlo, v) + min(sl.vhi, v + sw)) / 2
				if _inside(sl.u(d0 + 0.08), vm, pl, 0.04):
					pp = sl.P(sl.u(d0 + 0.08), vm, hb(sl.u(d0 + 0.08)) + TH - 0.004)
					kit.rivet(K.G(pp), T("wood", "dark"), r=0.02)
			v += sw
		i += 1


def roof_v3(w=2.0, rise=1.0, dd=2.0):
	"""Shack roof (the owner liked it): the same big stepped shingles, now each one a different painting, on
	hand-hewn rafters, a hewn ridge beam at the top, wooden pegs instead of iron bolts."""
	sl = K.Slope("z", dd / 2, -dd / 2, rise, 0.33, vlo=-w / 2, vhi=w / 2)
	shingle_slope(sl)
	a, b = sl.P(sl.u(sl.run - 0.11), sl.vlo + 0.04, 0.22), sl.P(sl.u(sl.run - 0.11), sl.vhi - 0.04, 0.22)
	real_log(a, b, 0.075, "round", stub=False)  # round ridge log: no flat corner lying on the steep boards


def roof_corner_v3(w=2.0, rise=1.0, dd=2.0, inner=False):
	"""Shack corner roof. Outer (hip): high at the back-left corner, two slopes meet on a diagonal under a hewn
	hip log pegged on top. Inner (valley): high along the back and left edges, the slopes meet in a dark board
	valley, the shingles stop just short of it. Same layers as the roof; cut exactly on the diagonal (F80)."""
	g = 0.005
	cut = [(-1.0, 1.0, -g)] if not inner else [(1.0, -1.0, -g)]
	slz = K.Slope("z", dd / 2, -dd / 2, rise, 0.33, vlo=-w / 2, vhi=w / 2)
	slx = K.Slope("x", w / 2, -w / 2, rise, 0.33, vlo=-dd / 2, vhi=dd / 2)
	sark, shc = ([(1.0, -1.0, -0.2)], [(1.0, -1.0, -0.2)]) if inner else ((), ())
	for sl in (slz, slx):
		shingle_slope(sl, cut, rafters=(-0.9, 0.0, 0.9), sark_cut=sark, sh_cut=shc)

	def diag(f, h):
		u = (dd / 2 - 0.13) - f * (dd - 0.26)
		return slz.P(u, u, h)
	hewn(diag(0.0, 0.085), diag(1.0, 0.085), 0.088)  # the hip / valley rafter
	if inner:  # the valley: a dark board down each side of the diagonal, under the shingle ends
		for sl in (slz, slx):
			before = set(bpy.data.objects)
			sl.strip(0.0, sl.run, sl.vlo, sl.vhi, sl.planes([(1.0, -1.0, -g), (-1.0, 1.0, 0.26)], e=K.E_IN + 0.008),
				lambda u: 0.15, lambda u: 0.181, T("wood", "dark"))
			for o in set(bpy.data.objects) - before:
				o["role"] = "board"
		return
	r = 0.072
	h = 0.268
	f_hi = 1.0
	while Vector(diag(f_hi, h)).y + r * 1.3 > rise - E:
		f_hi -= 0.02
	hewn(diag(0.0, h), diag(f_hi, h), r)
	for f in (0.2, 0.5, 0.8):
		p = diag(f * f_hi, h + r * 0.9)
		peg(p[0], p[1], p[2], "y")


def ridge_v3(w=2.0, rise=0.5, dd=2.0):
	"""Shack ridge cap: two short slopes (deck + shingles, no rafters: thin, open underneath) leaning on a
	hewn beam under the peak, and a hewn ridge log on top, pegged."""
	cap = 0.07
	sls = []
	for lo in (dd / 2, -dd / 2):
		sl = K.Slope("z", lo, 0.0, rise - cap, 0.14, vlo=-w / 2, vhi=w / 2)
		shingle_slope(sl, rafters=(), base=0.16, eave=False)
		sls.append(sl)
	sl = sls[0]
	top_deck = sl.P(sl.u(sl.run), 0.0, 0.005)[1]
	hewn((-w / 2 + 0.05, top_deck - 0.058, 0.0), (w / 2 - 0.05, top_deck - 0.058 + J(0.006), 0.0), 0.075)
	r = 0.075
	y = min(rise - E - r * 1.2, top_deck + 0.02 + r * 0.55)  # resting on the deck at the peak
	hewn((-w / 2 + 0.03, y, J(0.01)), (w / 2 - 0.03, y + J(0.006), J(0.01)), r)
	for x in (-0.6, 0.0, 0.6):
		peg(x + J(0.05), y + r * 0.7, 0.0, "y")


def gable_v3(w=2.0, rise=1.0, d=0.3):
	"""Shack gable / sloped wall (a right triangle, high at +x): a hewn corner post, a hewn sill, a thick rough
	barge board along the whole slope (it fills the thin tip), and upright split boards cut to the slope
	(gaps, a knot, a broken end), all pegged."""
	px = w / 2 - 0.162
	k = (rise - 0.33 - 2 * K.E_IN) / w                   # the roof piece's real slope (roof_v3 / shingle_slope)
	slope = lambda x: K.E_IN + k * (x + w / 2) + 0.15    # up into the roof's boards: no gap under the roof
	ys, rs = 0.142, 0.1
	xs = max(-w / 2 + 0.06, (ys + rs * 1.15 + 0.03 - slope(-w / 2)) / k - w / 2)  # the sill's end stays under the slope
	hewn((px, 0.03, 0.0), (px + J(0.006), slope(px - 0.16) - 0.02, J(0.005)), 0.12)
	hewn((xs, ys, 0.0), (px, ys + J(0.008), 0.0), rs)
	# the barge board: a thick hand-cut timber following the slope, down to the ground at the tip
	BH = 0.17
	xl = -w / 2 + 0.03
	n = 9
	xsamp = [xl + (w / 2 - 0.03 - xl) * k / n for k in range(n + 1)]
	top = [(x, slope(x) - 0.012 - abs(J(0.006))) for x in xsamp]
	bot = [(x, 0.006 if x < xs + 0.06 else max(0.006, slope(x) - BH + J(0.008))) for x in reversed(xsamp)]
	o = K.slab_poly(K.Frame(), top + bot, J(0.004), 0.17, T("wood"))
	_flat(o)
	o["role"] = "board"
	x0 = max(-w / 2 + 0.2, (0.35 + 0.05 - slope(-w / 2)) / k - w / 2 + 0.02)  # boards start where they are 30 cm tall
	x1 = px - 0.13
	x = x0
	gaps = [0.012, 0.024, 0.016, 0.02, 0.014]
	i = 0
	while x < x1 - 0.06:
		bw = min(K.rng.uniform(0.3, 0.42), x1 - x)
		if x1 - (x + bw) < 0.12:
			bw = x1 - x
		a, b = x + (gaps[i % 5] / 2 if i else 0.0), x + bw - gaps[(i + 1) % 5] / 2
		rough_vboard(a, b, 0.17, (slope(a) - 0.06, slope(b) - 0.06), J(0.008), 0.07, broken_top=(i == 2),
			knot=(1, 0.5 * (0.17 + slope(a)), 0.06) if i == 1 else None)
		xm = (a + b) / 2
		pegs_on(xm + J(0.03), ys, 0.093)
		pegs_on(xm, slope(xm) - 0.09, 0.083)
		x += bw
		i += 1


# ---------------- set 3: stairs and supports (same rules: hewn timber, split boards, wooden pegs, stones) ----------------
K.SIZE.update({"ramp": (2, 1, 2), "ladder": (1, 2, 0.2), "brace": (2, 2, 0.25), "mine_prop": (2, 3, 0.4)})


def board_x(x0, x1, z0, z1, y0, y1, **kw):
	"""A rough split board seen from above that runs along x (wavy front and back edges)."""
	o = rough_board(z0, z1, x0, x1, y0, y1, **kw)
	for v in o.data.vertices:
		bx, by, bz = v.co
		v.co = (-by, -bx, bz)
	K.fix_normals(o)
	return o


def side_board(x, pts, d, m=None):
	"""A thick board standing on edge along z at x (outline pts [(z, y)...]), like a stair stringer."""
	fr = K.Frame(x, 0.0, 90)
	o = K.slab_poly(fr, [(-z + J(0.003), max(E, y + J(0.003))) for z, y in pts], 0.0, d, m or T("wood"))
	_flat(o)
	o["role"] = "board"
	return o


def stairs_v3(w=2.0, h=2.0, dd=2.0, n=5):
	"""Shack stairs: two zig-zag stringers cut from thick split boards, a thick split plank on every step
	(pegged down), and hewn back posts on lumpy stones holding up the top."""
	dz, rise, t = dd / n, h / n, 0.07
	tops = [min(h - 0.008, (i + 1) * rise) - abs(J(0.004)) for i in range(n)]
	zf = [dd / 2 - 0.006 - i * dz for i in range(n)]
	zb = [max(-dd / 2 + 0.006, z - dz) for z in zf]
	D = min(0.3, rise * 0.9)
	for s_ in (-1, 1):
		X = s_ * (w / 2 - 0.1)
		pts = [(dd / 2 - 0.03, E)]
		for i in range(n):
			fl = tops[i] - t + 0.006
			pts += [(zf[i] - 0.03, fl), (zb[i] + (0.0 if i < n - 1 else 0.024), fl)]
		zbl = zb[-1] + 0.024
		yb = tops[-1] - t - D
		pts.append((zbl, yb))
		zg = zbl + (yb - E) * dz / rise
		pts.append((min(dd / 2 - 0.05, zg), E))
		side_board(X, pts, 0.075)
		px = s_ * (w / 2 - 0.23)
		boulder((px, 0.06, -dd / 2 + 0.24), 0.16, 0.08, 0.16)
		hewn((px, 0.1, -dd / 2 + 0.24), (px + J(0.006), tops[-1] - t - 0.01, -dd / 2 + 0.24 + J(0.006)), 0.085)
	for i in range(n):
		board_x(-w / 2 + 0.03, w / 2 - 0.03, zb[i] + 0.006, zf[i] - 0.006, tops[i] - t, tops[i], warp=J(0.006),
			broken="front" if i == 2 else None)
		for s_ in (-1, 1):
			peg(s_ * (w / 2 - 0.1) + J(0.01), tops[i] - 0.032, (zf[i] + zb[i]) / 2 + J(0.04), "y")


def ramp_v3(w=2.0, h=1.0, dd=2.0):
	"""Shack ramp (low at the front): rough planks across the slope with grip strips pegged on, two thick
	side timbers under them that reach the ground at the front, and hewn posts on stones under the high end."""
	sl = K.Slope("z", dd / 2, -dd / 2, h, 0.085, vlo=-w / 2, vhi=w / 2)
	d = 0.0
	k = 0
	while d < sl.run - 0.05:
		pw = min(K.rng.uniform(0.2, 0.27), sl.run - d)
		if sl.run - (d + pw) < 0.1:
			pw = sl.run - d
		d0, d1 = d + 0.006, d + pw - 0.006
		va, vb = sl.vlo + 0.02, sl.vhi - 0.02
		poly = [(sl.u(d0 + J(0.004)), va + K.rng.uniform(0, 0.02)), (sl.u(d1 + J(0.004)), va + K.rng.uniform(0, 0.02))]
		poly += [(sl.u(d1 + J(0.005)), va + (vb - va) * f) for f in (0.33, 0.66)]
		poly += [(sl.u(d1 + J(0.004)), vb - K.rng.uniform(0, 0.02)), (sl.u(d0 + J(0.004)), vb - K.rng.uniform(0, 0.02))]
		poly += [(sl.u(d0 + J(0.005)), va + (vb - va) * f) for f in (0.66, 0.33)]
		poly = [(max(-dd / 2 + 0.008, min(dd / 2 - 0.008, u)), v) for u, v in poly]
		o = sl.slab(poly, lambda u: 0.0, lambda u: 0.045 - abs(J(0.004)), T("wood"))
		_flat(o)
		o["role"] = "board"
		if k % 2 == 1:  # a grip strip across
			dm = (d0 + d1) / 2
			o = sl.slab([(sl.u(dm - 0.025), -0.82), (sl.u(dm + 0.025), -0.82), (sl.u(dm + 0.025), 0.82), (sl.u(dm - 0.025), 0.82)],
				lambda u: 0.042, lambda u: 0.078, T("wood", "dark"))
			_flat(o)
			o["role"] = "brace"
		for x in (-0.75, 0.75):
			pp = sl.P(sl.u((d0 + d1) / 2 + J(0.03)), x, 0.024)
			peg(pp[0], pp[1], pp[2], "y")
		d += pw
		k += 1
	under = lambda z: sl.P(z, 0.0, 0.0)[1] - 0.004
	for x in (-0.75, 0.75):
		zs = [dd / 2 - 0.02 - (dd - 0.04) * f / 8 for f in range(9)]
		top = [(z, under(z)) for z in zs]
		bot = [(z, max(E, under(z) - 0.2)) for z in reversed(zs)]
		side_board(x, [(top[0][0], E)] + top[1:] + bot, 0.1)
	for z in (-dd / 2 + 0.16, 0.0):
		for x in (-0.75, 0.75):
			yt = under(z) - 0.15
			if yt > 0.2:
				px = x + (0.11 if x > 0 else -0.11)
				boulder((px, 0.05, z), 0.1, 0.07, 0.12)
				hewn((px, 0.08, z), (px + J(0.006), under(z) - 0.004, z + J(0.006)), 0.07)


def ladder_v3(w=1.0, h=2.0, d=0.2):
	"""Shack ladder: two round poles, hewn rungs set into them and held by wooden pegs from the side."""
	for s_ in (-1, 1):
		real_log((s_ * 0.38, 0.022, 0.0), (s_ * 0.38 + J(0.01), h - 0.022, J(0.01)), 0.048, "round", stub=False)
	y = 0.26
	while y < h - 0.12:
		yy = y + J(0.015)
		hewn((-0.38, yy, 0.0), (0.38, yy + J(0.01), 0.0), 0.03)
		for s_ in (-1, 1):
			peg(s_ * (0.38 + 0.042), yy, 0.0, "x", s_)
		y += 0.3


def railing_v3(w=2.0, h=1.0, d=0.15):
	"""Shack railing: hewn posts, a hewn top rail and bottom rail, and split pickets between them, pegged."""
	for x in (-w / 2 + 0.072, J(0.03), w / 2 - 0.072):
		hewn((x, 0.02, 0.0), (x + J(0.006), h - 0.052, J(0.004)), 0.056)
	hewn((-w / 2 + 0.03, h - 0.075, 0.0), (w / 2 - 0.03, h - 0.075 + J(0.008), 0.0), 0.044)
	hewn((-w / 2 + 0.08, 0.14, 0.0), (w / 2 - 0.08, 0.14 + J(0.008), 0.0), 0.045)
	for half in (-1, 1):
		a0, a1 = (-w / 2 + 0.14, -0.07) if half < 0 else (0.07, w / 2 - 0.14)
		n = 6
		for i in range(n):
			xc = a0 + (a1 - a0) * (i + 0.5) / n + J(0.01)
			bw = K.rng.uniform(0.07, 0.1)
			rough_vboard(xc - bw / 2, xc + bw / 2, 0.12, h - 0.09 + J(0.01), J(0.004), 0.032, broken_top=(i == 3 and half > 0))
	for x in (-w / 2 + 0.072, w / 2 - 0.072):
		peg(x, h - 0.075 + 0.05 * 0.82, J(0.006), "y")


def beam_v3(w=2.0, s=0.3):
	"""Shack beam: one hand-hewn timber with the bark left on its corners, pegged at the ends."""
	hewn((-w / 2 + 0.03, s / 2, 0.0), (w / 2 - 0.03, s / 2 + J(0.008), J(0.006)), 0.128)
	for x in (-w / 2 + 0.16, w / 2 - 0.16):
		peg(x + J(0.02), s / 2 + 0.128 * 0.82, J(0.02), "y")


def pillar_v3(w=0.4, h=2.0):
	"""Shack pillar: a hewn post on a lumpy stone, with a short hewn bolster on top, pegged through."""
	boulder((0.0, 0.06, 0.0), 0.16, 0.08, 0.16)
	hewn((0.0, 0.1, 0.0), (J(0.008), h - 0.15, J(0.008)), 0.148)
	hewn((-w / 2 + 0.025, h - 0.104, J(0.006)), (w / 2 - 0.025, h - 0.104 + J(0.004), J(0.006)), 0.08)
	peg(J(0.02), h - 0.104 + 0.08 * 0.8, 0.0, "y")


def brace_v3(w=2.0, h=2.0, d=0.25):
	"""Shack diagonal brace: a hewn timber from bottom left to top right, its ends on short hewn shoes,
	pegged through."""
	a, b = (-w / 2 + 0.14, 0.14), (w / 2 - 0.14, h - 0.14)
	hewn((a[0], a[1], 0.0), (b[0], b[1], J(0.004)), 0.09)
	hewn((-w / 2 + 0.03, 0.114, 0.0), (-w / 2 + 0.5, 0.114 + J(0.006), 0.0), 0.088)
	hewn((w / 2 - 0.5, h - 0.1, 0.0), (w / 2 - 0.03, h - 0.1 + J(0.006), 0.0), 0.088)
	for (x, y) in ((a[0] + 0.05, a[1] + 0.03), (b[0] - 0.05, b[1] - 0.03)):
		pegs_on(x, y, 0.082)


def mine_prop_v3(w=2.0, h=3.0, d=0.4):
	"""Shack mine prop (holds the rock up): two big hewn posts on stones, a hewn cap beam across the top, two
	knee braces, and flat copper straps nailed over the joints (it costs one copper bar)."""
	cu = kit.tex_mat("copper", "a")
	fr = K.Frame()
	for s_ in (-1, 1):
		x = s_ * 0.8
		boulder((x, 0.06, 0.0), 0.155, 0.08, 0.155)
		hewn((x, 0.1, 0.0), (x + J(0.008), h - 0.3, J(0.008)), 0.15)
		hewn((x - s_ * 0.06, h - 0.62, 0.0), (s_ * 0.42, h - 0.27, 0.0), 0.062)  # knee brace
		pegs_on(x - s_ * 0.13, h - 0.58, 0.056)
		# a flat copper strap over the post-cap joint, on the front
		y0 = h - 0.5
		o = K.slab_poly(fr, [(x - 0.07, y0), (x + 0.07, y0 + 0.01), (x + 0.075, h - 0.1), (x - 0.07, h - 0.11)], 0.147, 0.024, cu)
		for yy in (y0 + 0.07, h - 0.17):
			kit.rivet(K.G((x + J(0.01), yy, 0.16)), kit.tex_mat("copper", "dark"), r=0.009)
	hewn((-w / 2 + 0.03, h - 0.18, 0.0), (w / 2 - 0.03, h - 0.18 + J(0.008), J(0.006)), 0.15)


# ---------------- set 4: floors and foundations ----------------
K.SIZE.update({"floor_half": (2, 0.25, 1), "small_floor": (1, 0.25, 1)})


def deck_boards(x0, x1, z0, z1, y0, y1, pl=None, peg_z=(), peg_ok=None, peg_x=None):
	"""Uneven split boards along z side by side (different widths, gaps, a knot bite, a broken end), cut exactly
	to the outline planes `pl` when given (triangles), pegged down at the beams under them (peg_z)."""
	x = x0
	i = 0
	while x < x1 - 0.05:
		bw = min(K.rng.uniform(0.3, 0.45), x1 - x)
		if x1 - (x + bw) < 0.16:
			bw = x1 - x
		a = x + (K.rng.uniform(0.005, 0.015) if i else 0.0)
		b = x + bw - (K.rng.uniform(0.005, 0.015) if x + bw < x1 - 0.01 else 0.0)
		if pl is None:
			special = dict(notch=(1, J(0.4), 0.08)) if i == 1 else dict(broken="front") if i == 3 else {}
			rough_board(a, b, z0 + 0.006, z1 - 0.006 - (0.05 if i == 3 else 0.0), y0, y1, warp=J(0.008), **special)
		else:
			nz = 6
			pts = [(a + J(0.004), z0 + (z1 - z0) * k / nz) for k in range(nz + 1)] + [(b + J(0.004), z1 - (z1 - z0) * k / nz) for k in range(nz + 1)]
			poly = K.clip_poly(pts, pl)
			if poly and K.area(poly) > 0.01:
				o = K.floor_poly(poly, y0, y1 - abs(J(0.006)), T("wood"))
				_flat(o)
				o["role"] = "board"
		pxs = [(a + b) / 2 + J(0.04)] if peg_x is None else [xx + J(0.01) for xx in peg_x if a + 0.05 < xx < b - 0.05]
		for zz in peg_z:
			for px in pxs:
				if peg_ok is None or peg_ok(px, zz):
					peg(px, y1 - 0.026, zz + J(0.015), "y")
		x += bw
		i += 1


def rim_beams(corners, r=0.068, y=0.086):
	"""A hand-hewn beam along every edge of a floor (outline `corners`), from the bottom up to the boards, so
	there's no open strip between two stories (owner, Nov 16). Each beam stops short of the corners: they meet,
	nothing passes through anything."""
	n = len(corners)
	cx, cz = sum(c[0] for c in corners) / n, sum(c[1] for c in corners) / n
	for i in range(n):
		a, b = Vector((*corners[i], 0)), Vector((*corners[(i + 1) % n], 0))
		edge = (b - a).normalized()
		inward = Vector((cx, cz, 0)) - (a + b) / 2
		inward = (inward - edge * inward.dot(edge)).normalized()
		inset = r + 0.012
		end = 0.03 if i % 2 == 0 else 2 * r + 0.045  # every other side fits between the ends of the others
		p0 = a + inward * inset + edge * end
		p1 = b + inward * inset - edge * end
		if n == 3:  # triangles: stop well clear of the sharp corners
			p0, p1 = a + inward * (r + 0.012) + edge * 0.32, b + inward * (r + 0.012) - edge * 0.32
		hewn((p0.x, y, p0.y), (p1.x, y + J(0.004), p1.y), r)


def floor_v3(w=2.0, dd=2.0, t=0.25):
	"""Shack floor / ceiling panel: hand-hewn joists running across, a deck of uneven split boards along z resting
	on them, pegged into every joist."""
	zs = (-dd / 2 + 0.3, 0.0, dd / 2 - 0.3) if dd > 1.5 else (-dd / 2 + 0.3, dd / 2 - 0.3)
	for z in zs:  # joists butt into the side rim beams (nothing passes through anything)
		hewn((-w / 2 + 0.165, 0.088, z + J(0.01)), (w / 2 - 0.165, 0.088 + J(0.004), z + J(0.01)), 0.07)
	rim_beams([(-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2)])
	deck_boards(-w / 2 + 0.012, w / 2 - 0.012, -dd / 2, dd / 2, 0.148, t - 0.015, peg_z=zs)


def floor_triangle_v3(t=0.25):
	"""Shack triangle floor: hewn joists across, cut short of the slanted edges, split boards cut exactly to the
	triangle, pegged."""
	ti, to = K.TRI_IN, K.TRI_OUT
	zs = (0.32, -0.12, -0.52)
	rim_beams([(x, z) for x, z in K.tri_pts()])
	for z in zs:
		half = K.tri_half(z) - 0.17
		if half > 0.12:
			hewn((-half, 0.088, z + J(0.01)), (half, 0.088 + J(0.004), z + J(0.01)), 0.07)
	deck_boards(-1.0, 1.0, -to, ti, 0.148, t - 0.015, pl=K.tri_planes(1.0, 0.006), peg_z=zs,
		peg_ok=lambda px, zz: abs(px) < K.tri_half(zz) - 0.22)


def _hewn_style(f):
	def run():
		global LOG_STYLE
		LOG_STYLE = "hewn"
		f()
		LOG_STYLE = "round"
	return run


def foundation_triangle_v3(h=1.0):
	"""Shack triangle foundation: three hewn legs on lumpy stones, two hewn beams from the back leg to the front
	legs, hewn cross logs resting on them, and split deck boards cut exactly to the triangle, pegged."""
	ti, to = K.TRI_IN, K.TRI_OUT
	legs = [(x * 0.55, z * 0.55) for x, z in K.tri_pts()]
	deck_bot = h - 0.11
	r_up, r_lo = 0.09, 0.1
	y_up = deck_bot - r_up + 0.012
	y_lo = y_up - r_up - r_lo + 0.035
	leg_top = y_lo - r_lo + 0.03
	for (x, z) in legs:
		boulder((x + J(0.015), 0.07, z + J(0.015)), 0.18, 0.1, 0.18)
		hewn((x, 0.1, z), (x + J(0.012), leg_top, z + J(0.012)), 0.165)
	back = legs[2]
	for (x, z) in legs[:2]:
		hewn((back[0], y_lo, back[1] + 0.02), (x * 1.08, y_lo + J(0.006), z * 1.08), r_lo)
	cross = (0.22, -0.28)
	for zz in cross:
		half = K.tri_half(zz) - 0.2
		hewn((-half, y_up, zz + J(0.015)), (half, y_up + J(0.006), zz + J(0.015)), r_up)
	deck_boards(-1.0, 1.0, -to, ti, deck_bot, h - 0.006, pl=K.tri_planes(1.0, 0.006), peg_z=cross,
		peg_ok=lambda px, zz: abs(px) < K.tri_half(zz) - 0.26)


# ---------------- set 5: the other walls ----------------
K.SIZE.update({"wall_narrow": (1, 2, 0.3), "window_wide": (2, 2, 0.3)})


def wall_any_v3(w=2.0, h=2.0, d=0.3):
	"""Shack wall of any size (half wall, narrow wall): hewn corner posts, a hewn sill and top beam, upright split
	boards of different widths with gaps, a knot bite and a broken top, pegged to both beams."""
	px = w / 2 - 0.151
	rt = 0.12 if h > 1.5 else 0.1
	yt = h - 0.135 if h > 1.5 else h - 0.112  # the top beam reaches the top of the piece
	for s_ in (-1, 1):
		hewn((s_ * px, 0.03, 0.0), (s_ * px + J(0.006), h - 0.05, J(0.005)), 0.126)
	hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	hewn((-px, yt, 0.0), (px, yt + J(0.008), 0.0), rt)
	x0, x1 = -px + 0.13, px - 0.13
	x = x0
	i = 0
	while x < x1 - 0.05:
		bw = min(K.rng.uniform(0.3, 0.42), x1 - x)
		if x1 - (x + bw) < 0.14:
			bw = x1 - x
		a = x + (K.rng.uniform(0.006, 0.012) if i else 0.0)
		b = x + bw - (K.rng.uniform(0.006, 0.012) if x + bw < x1 - 0.01 else 0.0)
		rough_vboard(a, b, 0.17, yt - rt + 0.04, J(0.008), 0.07, broken_top=(i == 2), knot=(1, 0.5 + 0.2 * h, 0.07) if i == 1 else None)
		for y, zf in ((0.115, 0.093), (yt, rt * 0.93)):
			pegs_on((a + b) / 2 + J(0.04), y, zf)
		x += bw
		i += 1


# ---------------- foundation legs on slopes (F162): the game stacks these under a leg down to the rock ----------------
def foundation_leg_v3():
	"""One 1 m section of the foundation's hand-hewn leg, origin at its TOP (y 0 .. -1). The game stacks and
	stretches a few of them (at most 2x) so a leg reaches the ground on a slope."""
	hewn((0.0, 0.0, 0.0), (J(0.006), -1.0, J(0.006)), 0.16)


def foundation_foot_v3():
	"""The lumpy stone a lengthened leg stands on (origin at its bottom, like the foundation's own stones)."""
	boulder((J(0.01), 0.07, J(0.01)), 0.21, 0.1, 0.2)


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
		elif role in ("board", "brace", "darkboard"):
			me.materials.clear()
			me.materials.append(next_plank_dark() if role == "darkboard" else next_plank())
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
			ln = int(o["down"]) if "down" in o else (1 if ext[1] >= ext[0] else 0)  # Blender y = down a z-axis slope
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


# ---------------- new stair pieces (owner, Nov 21: docs/design/new-pieces-plan.md) ----------------
K.SIZE.update({"stairs_corner": (2, 2, 2), "stairs_spiral": (2, 2, 2), "railing_stairs": (2, 3, 0.15)})


def _shrink(pts, g=0.004):
	"""An outline pulled g toward its middle (the gap between two boards)."""
	cx, cz = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
	out = []
	for x, z in pts:
		dx, dz = cx - x, cz - z
		L = max(1e-6, math.hypot(dx, dz))
		out.append((x + dx / L * g, z + dz / L * g))
	return out


def wedge_board(pts, y0, y1, role="board"):
	o = _flat(K.floor_poly(_shrink(pts), y0, y1, T("wood")))
	o["role"] = role
	return o


def stairs_corner_v3(w=2.0, h=2.0, dd=2.0, n=8):
	"""Shack corner stairs: 8 wedge steps fanning a quarter turn round a hewn corner post. Every step is two
	thick split boards on a hewn bearer that runs out from the post, held up at its far end by a hewn post on
	a lumpy stone (the low steps sit straight on stones), pegged down."""
	cx, cz = -w / 2 + E, dd / 2 - E
	X1, Z0 = w / 2 - E, -dd / 2 + E
	pr = 0.11   # half the corner post's room (a hewn post's bark corners reach past its half-width)
	t = 0.07
	rise = (h - 0.008) / n

	def ray(a):
		return math.cos(a), -math.sin(a)

	def far(a):
		dx, dz = ray(a)
		return min((X1 - cx) / dx if dx > 1e-6 else 9, (Z0 - cz) / dz if dz < -1e-6 else 9)

	def near(a):
		dx, dz = ray(a)
		return min(2 * pr / dx if dx > 1e-6 else 9, 2 * pr / -dz if dz < -1e-6 else 9) + 0.005

	def pt(a, r):
		dx, dz = ray(a)
		return (cx + dx * r, cz + dz * r)
	px, pz = cx + pr, cz - pr
	boulder((px + 0.04, 0.05, pz - 0.04), 0.115, 0.08, 0.115)
	hewn((px, 0.09, pz), (px + J(0.004), h - 0.02, pz + J(0.004)), 0.075)
	ca = math.atan2(-(Z0 - cz), X1 - cx)
	for i in range(n):
		a0, a1 = math.radians(90 * i / n), math.radians(90 * (i + 1) / n)
		am = (a0 + a1) / 2 + J(0.03)
		top = (i + 1) * rise - abs(J(0.004))
		for (b0, b1) in ((a0, am), (am, a1)):
			poly = [pt(b0, near(b0)), pt(b0, far(b0))] + ([(X1, Z0)] if b0 < ca < b1 else []) + [pt(b1, far(b1)), pt(b1, near(b1))]
			wedge_board(poly, top - t, top)
			fx, fz = pt((b0 + b1) / 2, far((b0 + b1) / 2) - 0.14)
			peg(fx, top - 0.032, fz, "y")
		ac = (a0 + a1) / 2
		yb = top - t - 0.042
		edge_gap = 0.052 / max(0.05, math.sin(min(ac, math.pi / 2 - ac)))   # the first and last bearers run close to an edge
		(ix, iz), (ox, oz) = pt(ac, max(2 * pr + 0.004, edge_gap)), pt(ac, far(ac) - 0.09)
		hewn((ix, yb, iz), (ox, yb + J(0.004), oz), 0.04)
		sx, sz = pt(ac, far(ac) - 0.2)
		bot = yb - 0.042
		if bot < 0.22:
			boulder((sx, 0.0, sz), 0.1, max(0.04, (bot - 0.01) / 1.2), 0.1)
		else:
			boulder((sx, 0.05, sz), 0.1, 0.07, 0.1)
			hewn((sx, 0.08, sz), (sx + J(0.006), bot - 0.002, sz + J(0.006)), 0.055)


def stairs_spiral_v3(w=2.0, h=2.0, dd=2.0, n=12):
	"""Shack spiral stairs: one thick round log as the middle post, on a stone, and 12 wedge steps going one
	full turn up 2 m. Each step is two split boards on a hewn bearer set against the log, pegged down."""
	R = min(w, dd) / 2 - E - 0.03
	rl = 0.17
	boulder((0, 0.05, 0), 0.26, 0.08, 0.26)
	real_log((0, 0.09, 0), (J(0.006), h - 0.022, J(0.006)), rl, "round", stub=False)
	t = 0.06
	step = math.tau / n
	ri = rl + 0.03
	for i in range(n):
		a0, a1 = step * i, step * (i + 1) + 0.05
		am = (a0 + a1) / 2 + J(0.03)
		top = 0.012 + (h - 0.024) * (i + 1) / n
		for (b0, b1) in ((a0, am), (am, a1)):
			pts = [(R * math.cos(b0 + (b1 - b0) * k / 3), -R * math.sin(b0 + (b1 - b0) * k / 3)) for k in range(4)]
			pts += [(ri * math.cos(b1), -ri * math.sin(b1)), (ri * math.cos(b0), -ri * math.sin(b0))]
			wedge_board(pts, top - t, top)
			bc = (b0 + b1) / 2
			peg(0.72 * math.cos(bc), top - 0.032, -0.72 * math.sin(bc), "y")
		ac = (a0 + a1) / 2
		yb = top - t - 0.042
		hewn((rl * 0.9 * math.cos(ac), yb, -rl * 0.9 * math.sin(ac)), ((R - 0.06) * math.cos(ac), yb, -(R - 0.06) * math.sin(ac)), 0.04)


def railing_stairs_v3(w=2.0, h=3.0, d=0.15):
	"""Shack stair railing (owner, Nov 21: dark wood, like a real railing): two hewn newel posts standing on the
	bottom and top steps, a hewn hand rail on the slant, and dark split pickets standing on the steps, set
	against the rail's side. Along x, rising toward +x (a quarter turn makes it rise toward -z like the stairs);
	its top meets the plain railing's top at both floors."""
	n, dzs = 5, (2.0 - 2 * E) / 5
	steps = [(-1 + E + i * dzs, -1 + E + (i + 1) * dzs, (i + 1) * (2.0 / n) - (0.008 if i == n - 1 else 0.0)) for i in range(n)]

	def rail_y(x):   # the rail's centre line
		return (h - 1.0) + x - 0.05
	rr, nr = 0.034, 0.058
	x0, x1 = steps[0][0] + nr + 0.004, steps[-1][1] - nr - 0.004
	hewn((x0, steps[0][2] + 0.003, 0), (x0, rail_y(x0) + 0.14, J(0.004)), nr)
	hewn((x1, steps[-1][2] + 0.003, 0), (x1, h - 0.024, J(0.004)), nr)
	ra, rb = x0 + nr - 0.006, x1 - nr + 0.006
	hewn((ra, rail_y(ra), 0), (rb, rail_y(rb), 0), rr)
	pd = 0.026
	pz = rr + pd / 2 + 0.003
	for (sa, sb, top) in steps:
		for f in (0.18, 0.5, 0.82):
			xc = sa + (sb - sa) * f + J(0.01)
			bw = K.rng.uniform(0.07, 0.09)
			if xc - bw / 2 < x0 + nr + 0.01 or xc + bw / 2 > x1 - nr - 0.01:
				continue
			o = rough_vboard(xc - bw / 2, xc + bw / 2, top + 0.003, (rail_y(xc - bw / 2) + 0.025, rail_y(xc + bw / 2) + 0.025), pz, pd)
			o["role"] = "darkboard"


# ---------------- batch 2 new pieces (docs/design/new-pieces-plan.md) ----------------
import new_pieces_common as NC  # noqa: E402

K.SIZE.update({"sloped_wall_down": (2, 2, 0.3), "edge_strip": (2, 0.3, 0.07), "floor_hatch": (2, 0.31, 2),
	"lattice_wall": (2, 2, 0.3), "roof_cap": (1.1, 0.5, 1.1)})
HATCH = (0.0, 0.4, 0.42, 0.47)   # the hole's centre x, z, its open radius, the rim's outer radius (clear of the front rim log)


def sloped_wall_down_v3():
	"""Upside-down sloped wall: the Shack sloped wall turned half a turn round its front-back line (full along the
	top, the barge board now running along the slanted underside)."""
	gable_v3(2.0, 2.0)
	NC.flip_down(2.0)


def edge_board(x0, x1, y0, y1, d, role="board"):
	"""A hand-split board standing on its edge (its face to the front): a wavy top, chipped corners."""
	top = [(x1 - 0.02, y1)] + [(x1 - (x1 - x0) * k / 6 + J(0.03), y1 - abs(J(0.008))) for k in range(1, 6)] + [(x0 + 0.02, y1)]
	pts = [(x0 + 0.015, y0), (x1 - 0.02, y0), (x1, y0 + 0.018), (x1, y1 - 0.014)] + top + [(x0, y1 - 0.02), (x0, y0 + 0.012)]
	o = _flat(K.slab_poly(K.Frame(), pts, J(0.003), d - K.rng.uniform(0.0, 0.008), T("wood")))
	o["role"] = role
	return o


def edge_strip_v3(w=2.0, h=0.3, d=0.07):
	"""A thin wooden lip along a floor's edge: two split boards on edge, one on the other, pegged."""
	dd = d - 2 * E - 0.006
	xa, xb = -w / 2 + E, w / 2 - E
	edge_board(xa, xb, E + 0.002, 0.15, dd, "darkboard")
	xm = K.J(0.3)
	edge_board(xa, xm - 0.003, 0.153, h - E, dd)
	edge_board(xm + 0.003, xb, 0.153, h - E, dd)
	for x in (xa + 0.12, xm - 0.12, xm + 0.12, xb - 0.12):
		for y in (0.08, 0.225):
			peg(x, y, dd / 2 - 0.006, "z")


def floor_hatch_v3(w=2.0, dd=2.0, t=0.25):
	"""Floor with a round hatch: the Shack floor with a round hole near its front, a dark board curb ring round
	it, and the round lid of dark split boards swung open, lying on the deck behind it (two battens, pegged)."""
	floor_v3(w, dd, t)
	cx, cz, r_in, r_out = HATCH
	NC.cut_round_hole(cx, cz, r_in + 0.025)
	o = NC.ring_mesh(cx, cz, r_in, r_out, 0.105, t - E - 0.022, T("wood"), n=36)
	o["role"] = "darkboard"
	lr = r_out - 0.016   # the lid covers the 42 cm opening and rests on the curb
	lz = cz - 2 * lr - 0.006
	y0 = t - 0.016
	NC.lid_boards(cx, lz, lr, y0, y0 + 0.03, 4, lambda: T("wood"), "darkboard")
	for sx in (-0.2, 0.2):
		half = math.sqrt(lr * lr - sx * sx) - 0.04
		o = _flat(K.blk((cx + sx, y0 + 0.03 + 0.006, lz), (0.08, 0.016, 2 * half), T("wood"), bevel=0.005))
		o["role"] = "board"
		for zz in (lz - half + 0.06, lz, lz + half - 0.06):
			peg(cx + sx, y0 + 0.038, zz, "y")


def lattice_wall_v3(w=2.0, h=2.0, d=0.3):
	"""Open lattice wall: a hewn frame (two posts, a sill and a head beam) round a see-through lattice of dark
	split laths crossing on the diagonal, a peg at every crossing."""
	r = 0.085
	px = w / 2 - E - r * 1.45
	for sx in (-1, 1):
		hewn((sx * px, E + 0.016, 0.0), (sx * px + J(0.005), h - E - 0.016, J(0.004)), r)
	ys, yh = 0.13, h - 0.14
	for y in (ys, yh):
		hewn((-px + 0.06, y, 0.0), (px - 0.06, y + J(0.008), 0.0), 0.075)
	pts = NC.lattice(-px + 0.04, px - 0.04, ys + 0.03, yh - 0.03, 0.0, 0.34, 0.06, 0.05, lambda: T("wood"), "darkboard")
	for (x, y) in pts:
		peg(x, y, 0.05 * 0.82 + 0.004, "z")


def roof_cap_v3():
	"""Roof peak cap: closes the tip where four sloped roofs meet. Four faces of rough shingles (open underneath,
	like the roof pieces) and a split board along each hip; no knob on top (owner)."""
	NC.pyramid_cap(0.49, E + 0.026, 0.40, 4, 0.03, lambda: T("shingle", "a"), "shingle", lambda: T("wood"), "board")


PIECES = {"foundation3": foundation_v3, "foundation_hewn": _hewn, "foundation_mix": _mix,
	"wall_v3": wall_v3, "doorway_v3": doorway_v3, "door_v3": door_v3, "roof_26_v3": lambda: roof_v3(2.0, 1.0),
	"window_wall_v3": window_wall_v3,
	"roof_45_v3": lambda: roof_v3(2.0, 2.0),
	"roof_26_outer_v3": lambda: roof_corner_v3(2.0, 1.0), "roof_26_inner_v3": lambda: roof_corner_v3(2.0, 1.0, inner=True),
	"roof_45_outer_v3": lambda: roof_corner_v3(2.0, 2.0), "roof_45_inner_v3": lambda: roof_corner_v3(2.0, 2.0, inner=True),
	"roof_26_ridge_v3": lambda: ridge_v3(2.0, 0.5), "roof_45_ridge_v3": lambda: ridge_v3(2.0, 1.0),
	"gable_26_v3": lambda: gable_v3(2.0, 1.0), "gable_45_v3": lambda: gable_v3(2.0, 2.0), "sloped_wall_v3": lambda: gable_v3(2.0, 2.0),
	"stairs_v3": stairs_v3, "foundation_steps_v3": lambda: stairs_v3(2.0, 1.0, 2.0, 4), "ramp_v3": ramp_v3, "ladder_v3": ladder_v3,
	"railing_v3": railing_v3, "beam_v3": beam_v3, "beam_half_v3": lambda: beam_v3(1.0), "pillar_v3": pillar_v3, "brace_v3": brace_v3,
	"mine_prop_v3": mine_prop_v3,
	"floor_v3": floor_v3, "floor_half_v3": lambda: floor_v3(2.0, 1.0), "small_floor_v3": lambda: floor_v3(1.0, 1.0),
	"ceiling_panel_v3": floor_v3, "floor_triangle_v3": floor_triangle_v3,
	"foundation_leg_v3": foundation_leg_v3, "foundation_foot_v3": foundation_foot_v3,
	"half_wall_v3": lambda: wall_any_v3(2.0, 1.0), "wall_narrow_v3": lambda: wall_any_v3(1.0, 2.0),
	"window_wide_v3": lambda: window_wall_v3(ow=1.6, oh=0.9, ob=0.6, shutters=False, sides=False, post_r=0.126),
	"foundation_half_v3": _hewn_style(lambda: foundation_v3(2.0, 1.0, 1.0)), "foundation_triangle_v3": foundation_triangle_v3,
	"stairs_corner_v3": stairs_corner_v3, "stairs_spiral_v3": stairs_spiral_v3, "railing_stairs_v3": railing_stairs_v3, "sloped_wall_down_v3": sloped_wall_down_v3, "edge_strip_v3": edge_strip_v3, "floor_hatch_v3": floor_hatch_v3, "lattice_wall_v3": lattice_wall_v3, "roof_cap_v3": roof_cap_v3, "foundation": foundation, "wall": wall, "doorway": doorway, "door": door, "roof_26": lambda: roof(2.0, 1.0)}


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
	GAME_NAME.update({n: n[:-3] for n in PIECES if n.endswith("_v3") and n[:-3] not in GAME_NAME.values()})
	GAME_NAME.update({"foundation_leg_v3": "foundation_leg", "foundation_foot_v3": "foundation_foot"})  # leg parts (F162)
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
		# install: also save the preview picture (journey/...) that make_piece_icons.py turns into the build-menu icon
		png = str(K.JOUR / f"{fname}__plank_root.png") if install else None
		kit.save(str(out_dir / f"{fname}__plank_root.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
