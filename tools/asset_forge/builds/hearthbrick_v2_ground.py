# Hearthbrick, version 2: the ground pieces (owner, Nov 20: "work through all of the batches"). Same look as the
# approved batch-1 floor and foundation in hearthbrick_v2.py: pale rough limestone borders and corners, hand-pressed
# bumpy bricks, herringbone tops, round-topped arches in the foundation sides.
#   blender --background --factory-startup --python builds/hearthbrick_v2_ground.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Pieces: foundation_half, foundation_triangle, foundation_steps, floor_half, small_floor, floor_triangle,
# ceiling_panel, stairs, ramp. Default output folder: journey/hearthbrick_v2/glb.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import hearthbrick_v2 as HB  # noqa: E402

SV = HB.SV
E = HB.E
blk = K.blk
tag, since, cbox = HB.tag, HB.since, HB.cbox
MORT = HB.MORT


def lime_roles():
	for o in bpy.data.objects:
		if o.get("role") == "stone":
			o["role"] = "lime"


# ---------------- herringbone inside any convex outline ----------------
def herringbone_in(planes, box, y0, y1, under=False, bed_pts=None):
	"""HB.herringbone, but cut to any convex outline (half-planes in x, z) instead of a rectangle; box = the
	outline's (x0, x1, z0, z1) to skip bricks far outside. bed_pts = the mortar bed's outline under the bricks."""
	w, L = HB.HB_W, HB.HB_L
	cs, sn = math.cos(math.pi / 4), math.sin(math.pi / 4)
	g = MORT / 2
	x0, x1, z0, z1 = box
	before = set(bpy.data.objects)
	bed = (y0 + (y1 - y0) * 0.45, y1 - 0.004) if under else (y0 + 0.004, y0 + (y1 - y0) * 0.55)
	K.floor_poly(bed_pts, bed[0], bed[1], HB.m_mortar())
	tag(since(before), "mortar")
	N = int(2.2 / w) + 2
	for k in range(-12, 13):
		ou, ov = k * 3 * w, -k * 3 * w
		for nn in range(-N, N):
			for (ua, ub, va, vb) in ((ou + nn * w, ou + nn * w + L, ov + nn * w, ov + nn * w + w),
					(ou + nn * w, ou + nn * w + w, ov + nn * w + w, ov + nn * w + w + L)):
				ua, ub, va, vb = ua + g, ub - g, va + g, vb - g
				pts = [((u - v) * cs, (u + v) * sn) for (u, v) in ((ua, va), (ub, va), (ub, vb), (ua, vb))]
				cx = sum(q[0] for q in pts) / 4
				cz = sum(q[1] for q in pts) / 4
				if not (x0 - 0.3 < cx < x1 + 0.3 and z0 - 0.3 < cz < z1 + 0.3):
					continue
				pts = K.clip_poly(pts, planes)
				if not pts or K.area(pts) < 0.0012 or HB.thin(pts, 0.03):
					continue
				th = (y1 - y0) - K.rng.uniform(0.0, 0.012)
				before = set(bpy.data.objects)
				o = K.floor_poly(pts, y0, y0 + th, HB.m_brick()) if under else K.floor_poly(pts, y1 - th, y1, HB.m_brick())
				if not under:
					b = o.modifiers.new("chisel", "BEVEL")
					b.width, b.segments, b.limit_method, b.angle_limit = 0.01, 1, "ANGLE", math.radians(35)
				for pp in o.data.polygons:
					pp.use_smooth = False
				tag(since(before), "brick")
				o["dark"] = K.rng.random() < 0.06


def rect_planes(x0, x1, z0, z1):
	return [(-1, 0, -x0), (1, 0, x1), (0, -1, -z0), (0, 1, z1)]


def rect_pts(x0, x1, z0, z1):
	return [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]


# ---------------- floors (half, small, ceiling) ----------------
def floor_any(w=2.0, h=0.25, dd=2.0):
	"""HB.floor for any size: limestone border all round, herringbone on top and underneath, dark joists (as many
	as fit: 3 on a 2 m floor, 1 on a 1 m one) with copper brackets."""
	bw = 0.2 if min(w, dd) > 1.5 else 0.16
	x0, x1, z0, z1 = -w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E
	HB.stone_frame(x0, x1, z0, z1, E, h - E, bw)
	ix0, ix1, iz0, iz1 = x0 + bw + 0.003, x1 - bw - 0.003, z0 + bw + 0.003, z1 - bw - 0.003
	pl = rect_planes(ix0, ix1, iz0, iz1)
	bed = rect_pts(ix0 + 0.01, ix1 - 0.01, iz0 + 0.01, iz1 - 0.01)
	herringbone_in(pl, (ix0, ix1, iz0, iz1), 0.185, h - E, bed_pts=bed)
	before = set(bpy.data.objects)
	blk((0, 0.165, 0), (ix1 - ix0 - 0.01, 0.03, iz1 - iz0 - 0.01), kit.tex_mat("wood", "dark"), bevel=0)
	tag(since(before), "mortar")
	under_y0, under_y1 = 0.105, 0.152
	herringbone_in(pl, (ix0, ix1, iz0, iz1), under_y0, under_y1, under=True, bed_pts=bed)
	jw, jy0, jy1 = 0.1, E + 0.004, under_y0 + 0.003
	span = iz1 - iz0
	zs = (-0.42, 0.0, 0.42) if span > 1.2 else (0.0,)
	for zc in zs:
		before = set(bpy.data.objects)
		blk((0, (jy0 + jy1) / 2, zc), (ix1 - ix0 - 0.006, jy1 - jy0, jw), kit.tex_mat("wood", "dark"), bevel=0.01)
		tag(since(before), "timber")
		for sx in (-1, 1):
			for sz in (-1, 1):
				before = set(bpy.data.objects)
				blk((sx * (ix1 - 0.07), (jy0 + jy1) / 2, zc + sz * (jw / 2 + 0.006)), (0.12, (jy1 - jy0) * 0.7, 0.01), kit.tex_mat("copper", "b"), bevel=0.002)
				tag(since(before), "copper")


def floor_half():
	floor_any(2.0, 0.25, 1.0)


def small_floor():
	floor_any(1.0, 0.25, 1.0)


def ceiling_panel():
	floor_any(2.0, 0.25, 2.0)


# ---------------- triangles ----------------
TK = 1.0 - E / K.TRI_IN   # the triangle pulled E inside its outline (scaled round its centre)


def tri_band(y0, y1, bw):
	"""Limestone band round the triangle's three edges, bw deep, mitred into the corners."""
	outer = K.tri_pts(TK)
	inner = SV._inset(outer, bw)
	SV.floor_rim(outer, inner, y0, y1, per_side=3)
	lime_roles()
	return inner


def tri_box():
	pts = K.tri_pts(1.0)
	return (min(p[0] for p in pts), max(p[0] for p in pts), min(p[1] for p in pts), max(p[1] for p in pts))


def floor_triangle(h=0.25):
	"""Triangle floor: limestone band round the edges (full height), herringbone on top and underneath, one dark
	joist from the point to the front edge with copper brackets at its front end."""
	bw = 0.18
	tri_band(E, h - E, bw)
	ins = E + bw + 0.003
	pl = K.tri_planes(1.0, ins)
	bed = SV._inset(K.tri_pts(1.0), ins + 0.01)
	herringbone_in(pl, tri_box(), 0.185, h - E, bed_pts=bed)
	before = set(bpy.data.objects)
	K.floor_poly(SV._inset(K.tri_pts(1.0), ins + 0.006), 0.152, 0.18, kit.tex_mat("wood", "dark"))
	tag(since(before), "mortar")
	under_y0, under_y1 = 0.105, 0.152
	herringbone_in(pl, tri_box(), under_y0, under_y1, under=True, bed_pts=bed)
	jw, jy0, jy1 = 0.1, E + 0.004, under_y0 + 0.003
	zs = [z * 0.005 - 1.2 for z in range(400)]
	ok = [z for z in zs if K.in_tri(-jw / 2, z, 1.0, ins + 0.004) and K.in_tri(jw / 2, z, 1.0, ins + 0.004)]
	za, zb = min(ok), max(ok)
	before = set(bpy.data.objects)
	blk((0, (jy0 + jy1) / 2, (za + zb) / 2), (jw, jy1 - jy0, zb - za), kit.tex_mat("wood", "dark"), bevel=0.01)
	tag(since(before), "timber")
	for sx in (-1, 1):
		before = set(bpy.data.objects)
		blk((sx * (jw / 2 + 0.006), (jy0 + jy1) / 2, zb - 0.07), (0.01, (jy1 - jy0) * 0.7, 0.12), kit.tex_mat("copper", "b"), bevel=0.002)
		tag(since(before), "copper")


def turn(objs, deg):
	"""Turn parts round the triangle's centre (the piece's origin) about the up axis (Godot yaw)."""
	R = Matrix.Rotation(math.radians(deg), 4, "Z")
	for o in objs:
		o.matrix_world = R @ o.matrix_world


def arch_side(p, u0, u1, cap0, t, arch=True, n_mortar=20):
	"""One brick foundation side between two corner columns (u0..u1 along it), 7 courses up to cap0, with one
	round-topped arch in the middle when it fits (the batch-1 foundation's side, made lighter)."""
	nc = 7
	ch = (cap0 - E) / nc
	spring = E + ch * 3
	R, ring_t = 0.34, 0.1
	if arch and (u1 - u0) < 2 * (R + ring_t) + 0.2:
		arch = False
	reach = MORT / 2 - 0.0025
	if arch:
		HB.arch_backing(p, u0 - 0.002, u1 + 0.002, E + 0.004, cap0 - 0.004, 0.0, E + 0.004, spring, R + 0.009, t, depth=0.5)
		cutter = HB.round_cutter(0.0, spring, R + ring_t + 0.002)
	else:
		before = set(bpy.data.objects)
		K.slab_poly(p.fr, [(u0 - 0.002, E + 0.004), (u1 + 0.002, E + 0.004), (u1 + 0.002, cap0 - 0.004), (u0 - 0.002, cap0 - 0.004)], 0.0, t * 0.5, HB.m_mortar())
		tag(since(before), "mortar")
		cutter = None
	for c in range(nc):
		ya, yb = E + ch * c, E + ch * (c + 1)
		below = yb <= spring + 1e-6
		cuts = [(-R - MORT / 2, R + MORT / 2)] if (arch and below) else []
		off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
		for (sa, sb) in HB.segments(u0 - reach, u1 + reach, cuts):
			for (a, b) in HB.lay_row(sa, sb, off if sa < u0 else 0.0):
				HB.brick(p, a, b, ya, yb, t, None if below else cutter, dark=K.rng.random() < 0.06)
	if arch:
		HB.ring(p, 0.0, spring, R, R + ring_t, 0.0, math.pi, t, 11)
		HB.mortar_arc(p, 0.0, spring, R + ring_t - 0.01, R + ring_t + 0.06, 0.0, math.pi, t - 2 * E - 0.04,
			(u0, u1, spring, cap0 - 0.004), n=n_mortar)


def foundation_any(w=2.0, h=1.0, dd=2.0):
	"""The batch-1 foundation for any size: limestone corner columns, brick sides (an arch only where the side is
	long enough: the 1 m sides of the half foundation are plain brick), limestone capping round a herringbone top."""
	cap0, t, cw = 0.84, 0.24, 0.3
	x0, x1, z0, z1 = -w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E
	HB.stone_frame(x0, x1, z0, z1, cap0, h - E, t)
	ix0, ix1, iz0, iz1 = x0 + t + 0.003, x1 - t - 0.003, z0 + t + 0.003, z1 - t - 0.003
	herringbone_in(rect_planes(ix0, ix1, iz0, iz1), (ix0, ix1, iz0, iz1), 0.90, h - E, bed_pts=rect_pts(ix0 + 0.01, ix1 - 0.01, iz0 + 0.01, iz1 - 0.01))
	before = set(bpy.data.objects)
	blk((0, (cap0 + 0.9) / 2 + 0.004, 0), (w - 2 * t - 0.03, 0.9 - cap0 - 0.006, dd - 2 * t - 0.03), kit.tex_mat("wood", "dark"), bevel=0)
	tag(since(before), "mortar")
	ys = [E, 0.23, 0.42, 0.63, cap0]
	for sx in (-1, 1):
		for sz in (-1, 1):
			cx, cz = sx * (w / 2 - E - cw / 2), sz * (dd / 2 - E - cw / 2)
			for k in range(4):
				tag([cbox((cx, (ys[k] + ys[k + 1]) / 2, cz), (cw - 0.004, ys[k + 1] - ys[k] - 0.004, cw - 0.004), HB.m_lime(),
					cut=0.035, dent=0.02, free="xz", seeds=1)], "lime")
	lime_roles()
	sides = [HB.Panel(oz=dd / 2 - E - t / 2), HB.Panel(oz=-(dd / 2 - E - t / 2)),
		HB.Panel(ox=w / 2 - E - t / 2, yaw=90), HB.Panel(ox=-(w / 2 - E - t / 2), yaw=90)]
	for p in sides:
		L = (w if p.yaw == 0 else dd) - 2 * E - 2 * cw
		arch_side(p, -L / 2, L / 2, cap0, t)


def foundation_half():
	foundation_any(2.0, 1.0, 1.0)


def foundation_triangle(h=1.0):
	"""Triangle foundation: a limestone column in each corner (a 60-degree kite, so it fits the corner exactly),
	a brick side with one arch along each edge, a limestone band round a herringbone top."""
	cap0, t = 0.84, 0.24
	a = t / math.tan(math.radians(30))   # the kite's length along each edge: its inner side then meets the brick side square
	inner = tri_band(cap0, h - E, t)
	ins = E + t + 0.003
	pl = K.tri_planes(1.0, ins)
	herringbone_in(pl, tri_box(), 0.90, h - E, bed_pts=SV._inset(K.tri_pts(1.0), ins + 0.01))
	before = set(bpy.data.objects)
	K.floor_poly(SV._inset(K.tri_pts(1.0), t + 0.02), cap0 + 0.004, 0.894, kit.tex_mat("wood", "dark"))
	tag(since(before), "mortar")
	zf = K.TRI_IN * TK   # the front edge (outer face) after the E inset
	ys = [E, 0.23, 0.42, 0.63, cap0]
	for k in range(3):
		before = set(bpy.data.objects)
		# the front side (along +z), then turned into place
		p = HB.Panel(oz=zf - t / 2)
		arch_side(p, -TK + a, TK - a, cap0, t)
		# the kite column in the front-left corner
		C = Vector((-TK, zf))
		e1 = Vector((1, 0))
		e2 = (Vector((0, -K.TRI_OUT * TK)) - C).normalized()
		A1, A2 = C + e1 * a, C + e2 * a
		Q = A1 + Vector((0, -t))
		kite = [tuple(C), tuple(A2), tuple(Q), tuple(A1)]
		kite = SV._inset(kite, 0.002)
		for j in range(4):
			SV.slab_xz(kite, ys[j] + 0.002, ys[j + 1] - 0.002, HB.m_lime(), c=0.03, role="lime")
		turn(since(before), 120 * k)


# ---------------- stairs ----------------
def stairs(w=2.0, h=2.0, dd=2.0, n=5):
	"""Solid brick stairs: each step a slice of bricks (the riser) with a limestone nosing along its front edge
	and flat bricks behind it on the tread; brick side walls cut to the steps, their front ends in limestone."""
	sw = 0.2
	dz = (dd - 2 * E) / n
	rise = (h - E) / n
	per = max(3, round(rise / 0.105))   # brick courses per step; the top one is the nosing / tread
	ch = rise / per
	nh = ch
	W = w - 2 * E - 2 * sw
	# the steps reach 0.6 cm from the side walls' (sunk) bricks: at 1.1 cm the game counted the side walls as
	# floating parts (its join limit is 1 cm) and showed a plain code shape instead (Nov 20)
	xa, xb = -W / 2 - 0.006, W / 2 + 0.006
	zback = -dd / 2 + E
	for i in range(n):
		zf = dd / 2 - E - i * dz
		zb = zf - dz
		top = E + (i + 1) * rise - (0.0 if i < n - 1 else 0.0)
		top = min(top, h - E)
		prev = E + i * rise
		# hidden mortar core (the joints show it)
		before = set(bpy.data.objects)
		cz0, cz1 = (zback + 0.055 if i == n - 1 else zb + 0.001), zf - 0.055   # the last one stops at the brick back wall
		cy1 = top - nh * 0.5   # the tread bricks and the nosing sit half in it
		blk((0, (E + cy1) / 2, (cz0 + cz1) / 2), (W - 0.006, cy1 - E, cz1 - cz0), HB.m_mortar(), bevel=0)
		if prev > E + 0.01:
			blk((0, (E + prev - 0.001) / 2, zf - 0.016), (W - 0.006, prev - 0.001 - E, 0.026), HB.m_mortar(), bevel=0)
		tag(since(before), "mortar")
		# riser bricks
		p = HB.Panel(oz=zf - 0.1)
		for c in range(per - 1):
			ya, yb = prev + ch * c, prev + ch * (c + 1)
			off = K.rng.uniform(0.1, 0.17) if (c + i) % 2 else 0.0
			for (a, b) in HB.lay_row(xa, xb, off):
				HB.brick(p, a, b, ya, yb, 0.2, None, dark=K.rng.random() < 0.06)
		# the tread: limestone nosing in front, flat bricks behind (header bricks running back)
		ny0, ny1 = top - nh + 0.002, top
		x = xa
		while x < xb - 0.01:
			nx = min(xb, x + K.rng.uniform(0.5, 0.75))
			if xb - nx < 0.3:
				nx = xb
			tag([cbox(((x + nx) / 2, (ny0 + ny1) / 2, zf - 0.08), (nx - x - 0.004, ny1 - ny0, 0.156), HB.m_lime(),
				cut=0.03, dent=0.016, free="yz", seeds=1)], "lime")
			x = nx
		tz0, tz1 = (zback if i == n - 1 else zb) + 0.004, zf - 0.162
		for (a, b) in HB.lay_row(xa, xb, K.rng.uniform(0.0, 0.15)):
			g = MORT / 2
			before = set(bpy.data.objects)
			o = cbox(((a + b) / 2, (ny0 + ny1) / 2, (tz0 + tz1) / 2), (b - a - 2 * g, ny1 - ny0 - 0.004, tz1 - tz0 - 2 * g),
				HB.m_brick(), cut=0.014, dent=0.012, free="y", seeds=0)
			tag(since(before), "brick")
			o["dark"] = K.rng.random() < 0.06
	# the brick back wall (seen from behind), up to under the top tread
	p = HB.Panel(oz=zback + 0.1)
	for c in range(n * per - 1):
		ya, yb = E + ch * c, E + ch * (c + 1)
		off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
		for (a, b) in HB.lay_row(xa, xb, off):
			HB.brick(p, a, b, ya, yb, 0.2, None, dark=K.rng.random() < 0.06)
	stair_sides(w, h, dd, n, sw, rise, ch)


def stair_sides(w, h, dd, n, sw, rise, ch):
	"""The two brick side walls: course by course, each reaching forward to the front of the lowest step whose
	top is at or above it; the front end of every course is a limestone block (like the wall's corner stones)."""
	dz = (dd - 2 * E) / n
	nc = round((h - E) / ch)
	for sx in (-1, 1):
		p = HB.Panel(ox=sx * (w / 2 - E - sw / 2), yaw=90)
		before = set(bpy.data.objects)   # the mortar sheet inside the side wall, stepped like it
		for i in range(n):
			zf = dd / 2 - E - i * dz
			top = min(h - E, E + (i + 1) * rise)
			K.slab_poly(p.fr, [(-zf + 0.012, E + 0.004), (dd / 2 - E - 0.01, E + 0.004), (dd / 2 - E - 0.01, top - 0.012),
				(-zf + 0.012, top - 0.012)], 0.0, sw * 0.45, HB.m_mortar()) if i == 0 else \
				K.slab_poly(p.fr, [(-zf + 0.012, E + i * rise + 0.002), (dd / 2 - E - 0.01, E + i * rise + 0.002), (dd / 2 - E - 0.01, top - 0.012),
				(-zf + 0.012, top - 0.012)], 0.0, sw * 0.45, HB.m_mortar())
		tag(since(before), "mortar")
		for c in range(nc):
			ya, yb = E + ch * c, min(h - E, E + ch * (c + 1))
			i_min = max(0, math.ceil((yb - E) / rise - 1e-6) - 1)
			zf = dd / 2 - E - i_min * dz
			u0, u1 = -zf, dd / 2 - E   # u = -z: front end at u0
			qw = (0.26, 0.17)[c % 2]
			HB.stone(p, u0, u0 + qw, ya, yb, sw)
			off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
			for (a, b) in HB.lay_row(u0 + qw - 0.0025, u1, off):
				HB.brick(p, a, b, ya, yb, sw, None, dark=K.rng.random() < 0.06)
	lime_roles()


def foundation_steps():
	stairs(2.0, 1.0, 2.0, n=3)


# ---------------- ramp ----------------
def ramp(w=2.0, h=1.0, dd=2.0):
	"""Brick ramp rising toward the back: rows of flat bricks laid on the slope over a mortar core, a limestone lip
	at the bottom and a limestone row at the top, brick side walls cut to the slope under limestone coping, a brick
	back wall."""
	sw, cap, th = 0.2, 0.09, 0.075
	uf, ub = -(dd / 2 - E), dd / 2 - E   # u = -z: the low front edge, the high back edge
	m = (h - 2 * E) / (ub - uf)

	def s(u):
		return E + m * (u - uf)

	W = w - 2 * E - 2 * sw
	xa, xb = -W / 2 + 0.002, W / 2 - 0.002
	fr = K.Frame(yaw=90)

	def prism_x(pts, x0, x1, mat, role, bevel=0.012):
		pts = [(u, max(E, y)) for (u, y) in pts]
		pts = HB.simplify(pts) if len(pts) > 3 else pts
		if K.area(pts) < 0.0008:
			return None
		before = set(bpy.data.objects)
		o = K.slab_poly(K.Frame(ox=(x0 + x1) / 2, yaw=90), pts, 0.0, x1 - x0, mat)
		if bevel:
			b = o.modifiers.new("chisel", "BEVEL")
			b.width, b.segments, b.limit_method, b.angle_limit = bevel, 1, "ANGLE", math.radians(35)
		for pp in o.data.polygons:
			pp.use_smooth = False
		tag(since(before), role)
		return o

	def strip(ua, ub_, y_lo):
		"""Side-view outline of a piece lying on the slope from ua to ub_, from y_lo below the slope to the slope."""
		pts = [(ua, s(ua) - y_lo), (ub_, s(ub_) - y_lo), (ub_, s(ub_)), (ua, s(ua))]
		if s(ua) - y_lo < E:   # near the bottom it reaches the ground: cut at the ground
			pts = K.clip_poly(pts, [(0, -1, -E)])
		return pts

	# mortar core under the bricks (the back wall's bricks fill the last 12 cm)
	bk = 0.12
	core = K.clip_poly([(uf + 0.003, E), (ub - bk - 0.002, E), (ub - bk - 0.002, s(ub - bk - 0.002) - th * 0.45), (uf + 0.003, s(uf + 0.003) - th * 0.45)], [(0, -1, -E - 0.001)])
	prism_x(core, xa - 0.002, xb + 0.002, HB.m_mortar(), "mortar", bevel=0)
	# limestone lip at the bottom, limestone row at the top (right at the back edge)
	lip, top_row = 0.2, 0.2
	for (ua, ub_) in ((uf + 0.002, uf + lip), (ub - top_row, ub - 0.002)):
		x = xa
		while x < xb - 0.01:
			nx = min(xb, x + K.rng.uniform(0.5, 0.75))
			if xb - nx < 0.3:
				nx = xb
			prism_x(strip(ua, ub_, th + 0.02), x + 0.002, nx - 0.002, HB.m_lime(), "lime", bevel=0.02)
			x = nx
	# brick rows on the slope between them
	rows_u0, rows_u1 = uf + lip + MORT, ub - top_row - MORT
	nrow = max(1, round((rows_u1 - rows_u0) / 0.125))
	du = (rows_u1 - rows_u0) / nrow
	for r in range(nrow):
		ua, ub_ = rows_u0 + r * du + MORT / 2, rows_u0 + (r + 1) * du - MORT / 2
		for (a, b) in HB.lay_row(xa, xb, K.rng.uniform(0.1, 0.17) if r % 2 else 0.0):
			a, b = a + MORT / 2, b - MORT / 2
			o = prism_x(strip(ua, ub_, th - K.rng.uniform(0.0, 0.01)), a, b, HB.m_brick(), "brick", bevel=0.01)
			if o:
				o["dark"] = K.rng.random() < 0.06
	# the brick back wall (seen from behind) under the top limestone row, each brick's top cut to the slope
	ch = 0.11
	lim = th + 0.026
	for c in range(int((h - E) / ch) + 1):
		ya, yb = E + ch * c + MORT / 2, E + ch * (c + 1) - MORT / 2
		if ya > s(ub) - lim - 0.03:
			break
		for (a, b) in HB.lay_row(xa, xb, K.rng.uniform(0.1, 0.17) if c % 2 else 0.0):
			pts = K.clip_poly([(ub - bk, ya), (ub - 0.003, ya), (ub - 0.003, yb), (ub - bk, yb)], [(-m, 1, E - lim - m * uf)])
			if pts and K.area(pts) > 0.0015 and not HB.thin(pts):
				o = prism_x(pts, a + MORT / 2, b - MORT / 2, HB.m_brick(), "brick", bevel=0.012)
				if o:
					o["dark"] = K.rng.random() < 0.06
	# side walls
	for sx in (-1, 1):
		p = HB.Panel(ox=sx * (w / 2 - E - sw / 2), yaw=90)
		before = set(bpy.data.objects)
		mort = K.clip_poly([(uf + 0.01, E + 0.004), (ub - 0.01, E + 0.004), (ub - 0.01, s(ub) - cap - 0.01), (uf + 0.01, s(uf) - cap - 0.01)], [(0, -1, -E - 0.004)])
		if mort and K.area(mort) > 0.001:
			K.slab_poly(p.fr, mort, 0.0, sw * 0.7, HB.m_mortar())
		tag(since(before), "mortar")
		plane = [(-m, 1, E - cap - m * uf)]

		def cutter(a, b, ya, yb, plane=plane):
			if yb <= s(a) - cap:
				return None
			if ya >= s(b) - cap:
				return []
			pts = K.clip_poly([(a, ya), (b, ya), (b, yb), (a, yb)], plane)
			return pts if pts and K.area(pts) > 0.002 else []

		ch_s = 0.11
		nc = int((h - E) / ch_s) + 1
		for c in range(nc):
			ya, yb = E + ch_s * c, E + ch_s * (c + 1)
			qw = (0.26, 0.17)[c % 2]
			if ya < s(ub) - cap:   # the back end: a limestone corner block
				HB.stone(p, ub - qw, ub, ya, yb, sw, cutter)
			off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
			for (a, b) in HB.lay_row(uf, ub - qw + 0.0025, off):
				HB.brick(p, a, b, ya, yb, sw, cutter, dark=K.rng.random() < 0.06)
		# limestone coping along the slope
		cuts = [uf, uf + 0.55, uf + 1.1, ub]
		for k in range(3):
			ua, ub_ = cuts[k] + 0.002, cuts[k + 1] - 0.002
			prism_x(strip(ua, ub_, cap - 0.002), p.fr.ox - sw / 2 + 0.002, p.fr.ox + sw / 2 - 0.002, HB.m_lime(), "lime", bevel=0.02)
	lime_roles()


PIECES = {"foundation_half": foundation_half, "foundation_triangle": foundation_triangle, "foundation_steps": foundation_steps,
	"floor_half": floor_half, "small_floor": small_floor, "floor_triangle": floor_triangle, "ceiling_panel": ceiling_panel,
	"stairs": stairs, "ramp": ramp}


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), HB.OUT_DEFAULT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in names:
		K.rng.seed(sum(map(ord, name + "hearthbrick2")))
		kit.reset()
		PIECES[name]()
		HB.split_big_faces()
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			HB.paint()
		png = str(K.JOUR / f"{name}__clay_brick.png") if install else None
		kit.save(str(out_dir / f"{name}__clay_brick.glb"), png, recenter=False, tex_size=512)
		n = 0
		for o in bpy.data.objects:
			if o.type == "MESH":
				n += sum(len(pp.vertices) - 2 for pp in o.data.polygons)
		print("PIECE_OK", name, "tris", n)
