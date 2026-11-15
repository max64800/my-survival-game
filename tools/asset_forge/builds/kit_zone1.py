# Zone 1 building kit (folder: build): three styles, each its own design (docs/design/building-kit-zone1.md).
#   Delver's Shack = plank_root (bark logs, uneven split planks, rope lashings, shingle roofs)
#   Stonehold      = cut_stone  (chunky blocks in 4 tones, dark mortar, timber lintels, copper bands, flat roof)
#   Hearthbrick    = clay_brick (warm bricks in 4 tones, pale limestone quoins/sills/keystones, terracotta tiles)
#   blender --background --factory-startup --python builds/kit_zone1.py -- [piece__family ...]   (none = all)
# Output: assets/models/build/<piece>__<family>.glb in PIECE space (Godot coords: x right, y up, z front;
# origin bottom-centre; triangles: origin at the centroid). Sizes match src/build/pieces.gd exactly.
# Rules: every part touches its neighbours, nothing floats, no perfect shapes (each block/plank/log is a
# little uneven and tilted), roofs are hollow panels.
import math
import random
import shutil
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "build"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "build"

STYLE_OF = {"plank_root": "shack", "cut_stone": "stone", "clay_brick": "brick"}
TRI_IN, TRI_OUT = 0.57735027, 1.1547005
rng = random.Random(1)
S = "shack"


# ---------------- basics (Godot space -> Blender) ----------------
def G(p):
	return (p[0], -p[2], p[1])


def GS(s):
	return (s[0], s[2], s[1])


def J(a):
	return rng.uniform(-a, a)


def T(kind, v=None):
	return kit.tex_mat(kind, v or rng.choice("abc"))


def blk(c, s, m, bevel=0.012, rx=0.0, ry=0.0, rz=0.0):
	"""A box: centre c, size s (Godot), turned ry around up, tilted rx (toward the viewer) and rz (in the wall plane)."""
	return kit.box(GS(s), G(c), m, bevel=bevel, wobble=0, rot=(rx, -rz, ry))


def fix_normals(o):
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	bm.to_mesh(o.data)
	bm.free()
	return o


def mesh(verts, faces, m, smooth=False):
	return fix_normals(kit._mesh_obj("part", [G(v) for v in verts], faces, m, smooth=smooth))


def log(p0, p1, r, m=None, seg=8, rings=3, ends=True, bend=0.08, end_m=None):
	"""A log or pole from p0 to p1: an uneven round section, a slight bend, light end-grain caps."""
	p0, p1 = Vector(p0), Vector(p1)
	d = p1 - p0
	ax = d.normalized()
	up = Vector((0, 1, 0)) if abs(ax.y) < 0.9 else Vector((1, 0, 0))
	u = ax.cross(up).normalized()
	v = ax.cross(u)
	prof = [r * (1 + J(0.09)) for _ in range(seg)]
	verts = []
	for i in range(rings + 1):
		t = i / rings
		c = p0 + d * t
		if 0 < i < rings:
			c = c + (u * J(1) + v * J(1)) * r * bend
		for k in range(seg):
			a = 2 * math.pi * k / seg
			rr = prof[k] * (1 + J(0.03))
			verts.append(tuple(c + u * math.cos(a) * rr + v * math.sin(a) * rr))
	faces = []
	for i in range(rings):
		for k in range(seg):
			a, b = i * seg + k, i * seg + (k + 1) % seg
			faces.append((a, b, b + seg, a + seg))
	faces.append(tuple(reversed(range(seg))))
	faces.append(tuple(range(rings * seg, (rings + 1) * seg)))
	o = mesh(verts, faces, m or T("bark"), smooth=True)
	if ends and r > 0.035:
		em = end_m or kit.tex_mat("wood", "c")
		for p, s_ in ((p0, -1), (p1, 1)):
			log(tuple(p + ax * s_ * 0.004), tuple(p + ax * s_ * 0.016), r * 0.8, em, seg=seg, rings=1, ends=False, bend=0)
	return o


def lash(c, r, axis="y", n=3):
	"""Pale straw-rope lashing: a few tight turns around a log."""
	rot = {"y": (0, 0, 0), "x": (0, 90, 0), "z": (90, 0, 0)}[axis]
	k = {"x": 0, "y": 1, "z": 2}[axis]
	for i in range(n):
		p = list(c)
		p[k] += (i - (n - 1) / 2) * 0.034
		kit.ring(r + 0.008, 0.016, G(p), kit.tex_mat("rope"), rot=rot, seg=12)


def peg(c, m=None):
	kit.rivet(G(c), m or kit.tex_mat("iron"), r=0.016)


def strap(c, s, m=None, rivets=2, along="x", face=1):
	"""A metal strap with rivet heads on its outer face (face=+1 front +z, -1 back)."""
	m = m or kit.tex_mat("copper", "b")
	blk(c, s, m, bevel=0.004)
	k = {"x": 0, "y": 1}[along]
	for i in range(rivets):
		p = list(c)
		p[k] += (i - (rivets - 1) / 2) * (s[k] - 0.08) / max(1, rivets - 1)
		p[2] += face * s[2] / 2
		peg(p, kit.tex_mat("copper", "dark"))


# ---------------- layout: rows of blocks, with slopes and openings ----------------
def layout(x0, x1, y0, y1, rh, bl, limit=None, hole=None, quoin=None, start=None):
	"""Lay courses of blocks in a rectangle. Returns (blocks, mortar):
	blocks = [(a, b, ya, yb, row, end)] (end = 'L'/'R' for quoin blocks), mortar = [(a, b, ya, yb)].
	limit(ya, yb) -> (lo, hi) or None = allowed x for that row; hole(ya, yb) -> (hl, hr) or None = cut out."""
	rows = []
	y = y0
	while y < y1 - 0.02:
		h = rng.uniform(*rh) if isinstance(rh, tuple) else rh
		if y1 - (y + h) < (rh[0] if isinstance(rh, tuple) else rh) * 0.6:
			h = y1 - y
		rows.append((y, min(y + h, y1)))
		y += h
	blocks, mortar = [], []
	for r, (ya, yb) in enumerate(rows):
		lo, hi = x0, x1
		if limit:
			lim = limit(ya, yb)
			if not lim:
				continue
			lo, hi = max(lo, lim[0]), min(hi, lim[1])
		if hi - lo < 0.04:
			continue
		spans = [(lo, hi)]
		if hole:
			hcut = hole(ya, yb)
			if hcut:
				spans = [(a, b) for a, b in ((lo, min(hi, hcut[0])), (max(lo, hcut[1]), hi)) if b - a > 0.04]
		for (a0, b0) in spans:
			mortar.append((a0, b0, ya, yb))
			xx = a0
			first = True
			if not quoin:
				off = (start if start is not None else 0.5) * (r % 2)
				xx = a0 - (rng.uniform(*bl) if isinstance(bl, tuple) else bl) * off
			while xx < b0 - 0.01:
				ln = rng.uniform(*bl) if isinstance(bl, tuple) else bl
				end = ""
				if quoin and first and abs(a0 - x0) < 0.01:
					ln, end = quoin[r % 2], "L"
				a, b = max(xx, a0), min(xx + ln, b0)
				if quoin and abs(b0 - x1) < 0.01 and b0 - b < quoin[(r + 1) % 2] + 0.05:
					# Finish the row with the right-hand quoin.
					if b0 - a > quoin[(r + 1) % 2] + 0.1:
						blocks.append((a, b0 - quoin[(r + 1) % 2], ya, yb, r, end))
						a = b0 - quoin[(r + 1) % 2]
					blocks.append((a, b0, ya, yb, r, "R"))
					break
				if b - a > 0.05:
					blocks.append((a, b, ya, yb, r, end))
				xx += ln
				first = False
	return blocks, mortar


def round_hole(w, top, ring=0.0, bottom=0.0):
	"""An opening `w` wide whose round top (radius w/2) peaks at `top`; cut wider by `ring`."""
	r = w / 2
	spring = top - r

	def cut(ya, yb):
		if yb <= bottom + 0.005 or ya >= top + ring:
			return None
		y = max((ya + yb) / 2, bottom)
		if y <= spring:
			hw = r + ring
		else:
			R = r + ring
			hw = math.sqrt(max(0.0, R * R - (y - spring) ** 2))
		if hw < 0.02:
			return None
		return (-hw, hw)
	return cut


def rect_hole(w, y0, y1, ring=0.0):
	def cut(ya, yb):
		if yb <= y0 - ring + 0.005 or ya >= y1 + ring - 0.005:
			return None
		return (-w / 2 - ring, w / 2 + ring)
	return cut


def slope_limit(w, rise):
	"""A slope rising from (-w/2, 0) to (+w/2, rise): rows reach as far as the slope (cut exactly by slope_clip)."""
	def lim(ya, yb):
		if ya > rise - 0.02:
			return None
		return (-w / 2 + ya / rise * w, w / 2)
	return lim


def slope_clip(w, rise):
	return [(-rise / w, 1.0, rise / 2)]


# ---------------- frames: lay a flat layout onto a wall face anywhere ----------------
class Frame:
	"""Local wall space (x along the wall, y up, z out of the face) -> piece space, turned by yaw."""
	def __init__(self, ox=0.0, oz=0.0, yaw=0.0):
		self.ox, self.oz, self.yaw = ox, oz, yaw
		self.c, self.s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

	def p(self, x, y, z):
		return (self.ox + x * self.c + z * self.s, y, self.oz - x * self.s + z * self.c)

	def box(self, c, s, m, bevel=0.012, rx=0.0, rz=0.0):
		return blk(self.p(*c), s, m, bevel=bevel, rx=rx, ry=self.yaw, rz=rz)


def masonry(fr, blocks, mortar, d, tones, mortar_m, z=0.0, gap=0.022, bevel=0.018, tilt=1.2, jit=0.012,
		quoin_m=None, qd=0.04, moss=0, clip=None):
	for (a, b, ya, yb) in mortar:
		rect = [(a, ya), (b, ya), (b, yb), (a, yb)]
		if clip and needs_clip(rect, clip):
			poly = clip_poly(rect, clip)
			if poly:
				slab_poly(fr, poly, z, d * 0.8, mortar_m)
			continue
		fr.box(((a + b) / 2, (ya + yb) / 2, z), (b - a, yb - ya, d * 0.8), mortar_m, bevel=0)
	for (a, b, ya, yb, r, end) in blocks:
		m = quoin_m if (end and quoin_m) else tones()
		dd = d + (qd if end else J(0.02))
		g2 = gap / 2
		rect = [(a + g2, ya + g2), (b - g2, ya + g2), (b - g2, yb - g2), (a + g2, yb - g2)]
		if clip and needs_clip(rect, clip):
			poly = clip_poly(rect, clip)
			if poly and area(poly) > 0.004:
				slab_poly(fr, poly, z + J(jit), dd, m)
			continue
		fr.box(((a + b) / 2 + J(0.004), (ya + yb) / 2, z + J(jit)), (b - a - gap, yb - ya - gap, dd), m, bevel=bevel,
			rz=J(tilt), rx=J(tilt * 0.4))
	for _ in range(moss):
		if not blocks:
			break
		a, b, ya, yb, r, end = rng.choice(blocks)
		for side in (-1, 1):
			fr.box((rng.uniform(a, b), ya + 0.01, z + side * d * 0.42), (rng.uniform(0.08, 0.2), 0.035, 0.05),
				kit.mat("moss", J(0.1)), bevel=0.01)


def slab_poly(fr, pts, z, d, m):
	"""A flat plank/board whose outline in the wall plane is `pts` [(x, y)...] (any shape), `d` thick."""
	n = len(pts)
	v = [fr.p(x, y, z - d / 2) for x, y in pts] + [fr.p(x, y, z + d / 2) for x, y in pts]
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def clip_poly(poly, planes):
	"""Cut a convex outline [(x, y)...] by half-planes [(a, b, c)] keeping a*x + b*y <= c."""
	for (a, b, c) in planes:
		out = []
		n = len(poly)
		for i in range(n):
			p, q = poly[i], poly[(i + 1) % n]
			fp, fq = a * p[0] + b * p[1] - c, a * q[0] + b * q[1] - c
			if fp <= 0:
				out.append(p)
			if (fp < 0 < fq) or (fq < 0 < fp):
				t = fp / (fp - fq)
				out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
		poly = out
		if len(poly) < 3:
			return []
	return poly


def needs_clip(rect, planes):
	return any(a * x + b * y > c + 1e-6 for (a, b, c) in planes for (x, y) in rect)


def area(poly):
	return abs(sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))) / 2


def floor_poly(pts, y0, y1, m):
	"""A flat tile whose outline seen from above is pts [(x, z)...]."""
	n = len(pts)
	v = [(x, y0, z) for x, z in pts] + [(x, y1, z) for x, z in pts]
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def tri_planes(k=1.0, inset=0.0):
	"""Half-planes (in x, z) for the inside of the triangle, shrunk by `inset`."""
	out = []
	pts = tri_pts(k)
	for i in range(3):
		(ax, az), (bx, bz) = pts[i], pts[(i + 1) % 3]
		ex, ez = bx - ax, bz - az
		L = math.hypot(ex, ez)
		nx, nz = -ez / L, ex / L
		if nx * (0 - ax) + nz * (0 - az) < 0:
			nx, nz = -nx, -nz
		out.append((-nx, -nz, -(nx * ax + nz * az) - inset))
	return out


def plank_shape(fr, a, b, bot, top, z, d, m, k=4):
	"""Upright plank between x=a..b whose bottom/top follow the functions bot(x)/top(x) exactly."""
	xs = [a + (b - a) * i / k for i in range(k + 1)]
	pts = [(x, bot(x)) for x in xs] + [(x, top(x)) for x in reversed(xs)]
	return slab_poly(fr, pts, z, d, m)


def planks_v(fr, x0, x1, y0, y_top, d, hole_top=None, hole_x=None, hole_bot=None, grey=0.2, z=0.0, w=(0.18, 0.28)):
	"""Upright split planks from x0 to x1, cut exactly to the top line y_top(x). An opening hole_x = (hl, hr)
	with sill hole_bot (None = from the floor) and top line hole_top(x) leaves an exact gap."""
	zones = [(x0, x1, False)]
	if hole_x:
		zones = [(x0, hole_x[0], False), (hole_x[0], hole_x[1], True), (hole_x[1], x1, False)]
	for (za, zb, inside) in zones:
		xx = za
		while xx < zb - 0.03:
			pw = min(rng.uniform(*w), zb - xx)
			if zb - (xx + pw) < 0.08:
				pw = zb - xx
			a, b = xx + 0.008, xx + pw - 0.008
			m = T("greywood") if rng.random() < grey else T("wood")
			dz = z + J(0.008)
			dd = d * rng.uniform(0.9, 1.0)
			lift = J(0.012)
			top = lambda x: y_top(x) + lift
			if not inside:
				plank_shape(fr, a, b, lambda x: y0, top, dz, dd, m)
			else:
				if hole_bot and hole_bot > y0 + 0.05:
					plank_shape(fr, a, b, lambda x: y0, lambda x: hole_bot, dz, dd, m)
				if y_top((a + b) / 2) - hole_top((a + b) / 2) > 0.05:
					plank_shape(fr, a, b, hole_top, top, dz, dd, m, k=6)
			xx += pw


# ---------------- tones per style ----------------
def stone_tone():
	k = rng.random()
	if k < 0.5:
		return T("stone")
	if k < 0.68:
		return T("basalt", rng.choice("ab"))
	if k < 0.85:
		return T("brownrock", rng.choice("ab"))
	return T("limestone", rng.choice("bc"))


def brick_tone():
	k = rng.random()
	if k < 0.55:
		return T("brick")
	if k < 0.75:
		return T("rooftile", rng.choice("bc"))
	if k < 0.92:
		return T("brickochre")
	return T("brick", "dark")


def mortar_m():
	return kit.mat("charcoal", 0.5) if S == "stone" else kit.tex_mat("limestone", "dark")


def wood_dark():
	return kit.tex_mat("wood", "dark")


# ---------------- walls ----------------
def wall_body(w, h, d=0.3, hole=None, slope=None, fr=None):
	"""The wall's fill in the style. hole = ('round', ow, top) or ('rect', ow, y0, y1) or ('round_win', ow, y0, y1)."""
	fr = fr or Frame()
	lim = slope_limit(w, h) if slope else None
	if S == "shack":
		y_top = (lambda x: h * (x + w / 2) / w - 0.06) if slope else (lambda x: h - 0.08)
		hx = ht = hb = None
		if hole:
			if hole[0] == "round":
				r = hole[1] / 2
				hx, hb = (-r, r), None
				ht = lambda x: hole[2] - r + math.sqrt(max(0.0, r * r - min(x * x, r * r)))
			else:
				hx, hb = (-hole[1] / 2 - 0.06, hole[1] / 2 + 0.06), hole[2] - 0.05
				ht = lambda x: hole[3] + 0.06
		planks_v(fr, -w / 2 + 0.04, w / 2 - 0.04, 0.08, y_top, d * 0.36, ht, hx, hb)
		return
	if S == "stone":
		rh, bl, quoin, qm = (0.3, 0.42), (0.38, 0.72), ((0.55, 0.32) if not slope else None), None
		gap, bev = 0.024, 0.02
	else:
		rh, bl, quoin, qm = 0.125, 0.25, ((0.3, 0.18) if not slope else None), T("limestone")
		gap, bev = 0.016, 0.0
	cut = None
	if hole:
		ring = 0.2 if S == "stone" else 0.13
		if hole[0] == "round":
			cut = round_hole(hole[1], hole[2], ring)
		elif hole[0] == "round_win":
			cut = round_hole(hole[1], hole[3], ring, bottom=hole[2] - 0.06)
		else:
			cut = rect_hole(hole[1], hole[2], hole[3], 0.06)
	blocks, mortar = layout(-w / 2, w / 2, 0, h, rh, bl, limit=lim, hole=cut, quoin=quoin)
	masonry(fr, blocks, mortar, d, stone_tone if S == "stone" else brick_tone, mortar_m(), gap=gap, bevel=bev,
		tilt=1.2 if S == "stone" else 0.7, jit=0.014 if S == "stone" else 0.006, quoin_m=qm, moss=4 if S == "stone" else 0,
		clip=slope_clip(w, h) if slope else None)


def shack_frame(w, h, d, slope=False, gap=None, door=False):
	"""Bark-log frame of a Shack wall: sill log, corner posts, top plate (or slope log), rope lashings."""
	r = 0.12
	if door:  # the sill log stops at the doorway's stone jambs
		log((-w / 2, 0.1, 0), (gap[0] + 0.02, 0.1, 0), 0.1)
		log((gap[1] - 0.02, 0.1, 0), (w / 2, 0.1, 0), 0.1)
	else:
		log((-w / 2, 0.1, 0), (w / 2, 0.1, 0), 0.1)
	if slope:
		log((w / 2 - r, 0, 0), (w / 2 - r, h - 0.02, 0), r)
		lash((w / 2 - r, h - 0.25, 0), r)
		log((-w / 2 + 0.02, 0.1, 0), (w / 2 - 0.1, h - 0.08, 0), 0.085)
		return
	for x in (-w / 2 + r, w / 2 - r):
		log((x, 0, 0), (x, h, 0), r)
		if h > 1.2:
			lash((x, h - 0.25, 0), r)
	log((-w / 2 + 0.05, h - 0.1, 0), (w / 2 - 0.05, h - 0.1, 0), 0.1)
	if h > 1.2:  # inside cross batten (in two parts around an opening)
		spans = [(-w / 2 + 0.2, w / 2 - 0.2)] if not gap else [(-w / 2 + 0.2, gap[0]), (gap[1], w / 2 - 0.2)]
		for a, b in spans:
			if b - a > 0.1:
				blk(((a + b) / 2, h * 0.5 + (0.45 if gap and gap[2] else 0), -d * 0.27), (b - a, 0.14, 0.05), T("greywood"), rz=J(1.5))


def wall(w=2.0, h=2.0, d=0.3):
	wall_body(w, h, d)
	if S == "shack":
		shack_frame(w, h, d)
	elif S == "stone":
		for x0, x1 in ((-w / 2, -w / 4 + J(0.1)), (-w / 4 + 0.05, w / 4 + J(0.1)), (w / 4 + 0.15, w / 2)):
			blk(((x0 + x1) / 2, h - 0.05, 0), (x1 - x0 - 0.02, 0.1, d + 0.05), T("limestone", rng.choice("bc")), bevel=0.02, rz=J(0.8))


def half_wall(w=2.0, h=1.0, d=0.3):
	wall(w, h, d)


def sloped_wall(w=2.0, h=2.0, d=0.3):
	wall_body(w, h, d, slope=True)
	if S == "shack":
		shack_frame(w, h, d, slope=True)
	else:
		coping(w, h, d)


def coping(w, rise, d):
	"""Flat stones (or limestone) laid along the slope, covering the stepped block ends."""
	L = math.hypot(w, rise)
	ang = math.degrees(math.atan2(rise, w))
	n = max(2, round(L / 0.5))
	m = (lambda: T("limestone")) if S == "brick" else stone_tone
	for i in range(n):
		f = (i + 0.5) / n
		x, y = -w / 2 + f * w, f * rise
		blk((x - 0.03 * math.sin(math.radians(ang)), y - 0.035, 0), (L / n - 0.02, 0.1, d + 0.04), m(), bevel=0.015, rz=ang + J(0.8))


def doorway(w=2.0, h=2.0, d=0.3, ow=1.0, top=1.8, ring_w=None):
	r = ow / 2
	spring = top - r
	wall_body(w, h, d, hole=("round", ow, top))
	if S == "shack":
		shack_frame(w, h, d, gap=(-r - 0.16, r + 0.16, False), door=True)
		# A ring of rough stones around the round doorway, down to the floor.
		ring_w = 0.16
		n = 9
		for i in range(n):
			a = math.pi * (i + 0.5) / n
			p = (-math.cos(a) * (r + ring_w / 2), spring + math.sin(a) * (r + ring_w / 2), 0)
			blk(p, (math.pi * (r + ring_w / 2) / n - 0.025, ring_w, d * 0.75), T("stone"), bevel=0.02,
				rz=math.degrees(a - math.pi / 2) + J(3))
		for s_ in (-1, 1):
			y = 0.0
			while y < spring - 0.05:
				hh = min(rng.uniform(0.28, 0.42), spring - y)
				blk((s_ * (r + ring_w / 2), y + hh / 2, 0), (ring_w + J(0.02), hh - 0.02, d * 0.75), T("stone"), bevel=0.02, rz=J(2))
				y += hh
		return
	ring = ring_w or (0.2 if S == "stone" else 0.13)
	arch_backing(w, h, d, r, spring)
	voussoirs(r, spring, ring, d, keystone=True)


def arch_backing(w, h, d, r, spring, fr=None):
	"""Two wall halves cut EXACTLY to the round opening (stone or brick surface), set just behind the blocks,
	so the stepped block ends never leave square notches at the arch's shoulders (F57: it must read round)."""
	fr = fr or Frame()
	m = T("stone", "b") if S == "stone" else T("brick", "dark")
	for s_ in (-1, 1):
		arc = [(s_ * r * math.cos(math.pi / 2 * k / 10), spring + r * math.sin(math.pi / 2 * k / 10)) for k in range(11)]
		pts = [(s_ * w / 2, 0.0), (s_ * r, 0.0)] + arc + [(0.0, h), (s_ * w / 2, h)]
		if s_ < 0:
			pts = list(reversed(pts))
		slab_poly(fr, pts, 0.0, d * 0.86, m)


def voussoirs(r, spring, ring, d, keystone=True, n=None):
	"""Wedge stones (stone) or upright bricks (brick) around a round top, plus straight jambs down to the floor."""
	n = n or (9 if S == "stone" else max(11, round(math.pi * (r + ring / 2) / 0.1)))
	for i in range(n):
		a = math.pi * (i + 0.5) / n
		mid = n // 2
		key = keystone and i == mid
		rr = r + ring / 2 + (0.03 if key else 0)
		p = (-math.cos(a) * rr, spring + math.sin(a) * rr, 0)
		if S == "stone":
			m = T("limestone", "c") if key else stone_tone()
		else:
			m = T("limestone") if key else brick_tone()
		wdt = math.pi * (r + ring / 2) / n - (0.02 if S == "stone" else 0.014)
		blk(p, (wdt + (0.06 if key else 0), ring + (0.1 if key else 0), d + (0.06 if key else 0.02)), m,
			bevel=0.018 if S == "stone" else 0.0, rz=math.degrees(a - math.pi / 2) + J(1.5))
		if key and S == "stone":  # a carved rune on the keystone
			for ang in (20, -20):
				blk((p[0], p[1] + 0.02, d / 2 + 0.035), (0.025, 0.16, 0.02), kit.mat("charcoal", 0.2), bevel=0, rz=ang)
	# Jambs down both sides.
	for s_ in (-1, 1):
		y = 0.0
		k = 0
		while y < spring - 0.04:
			hh = min(rng.uniform(0.3, 0.45) if S == "stone" else 0.25, spring - y)
			wide = ring + (0.08 if k % 2 else 0)
			m = stone_tone() if S == "stone" else T("limestone")
			blk((s_ * (r + wide / 2), y + hh / 2, 0), (wide - 0.02, hh - 0.02, d + 0.03), m, bevel=0.018, rz=J(1))
			y += hh
			k += 1


def arch_doorway(w=2.0, h=2.0, d=0.3):
	doorway(w, h, d, ow=1.2, top=1.9, ring_w=0.24)


def window_wall(w=2.0, h=2.0, d=0.3, ow=1.0, oh=0.8, ob=0.6):
	top = ob + oh
	if S == "brick":  # a tall arched window with leaded panes
		wall_body(w, h, d, hole=("round_win", ow, ob, top))
		r = ow / 2
		spring = top - r
		ring = 0.13
		n = 11
		for i in range(n):
			a = math.pi * (i + 0.5) / n
			key = i == n // 2
			rr = r + ring / 2 + (0.02 if key else 0)
			blk((-math.cos(a) * rr, spring + math.sin(a) * rr, 0), (math.pi * (r + ring / 2) / n - 0.014 + (0.05 if key else 0),
				ring + (0.06 if key else 0), d + 0.02), T("limestone") if key else brick_tone(), bevel=0.0, rz=math.degrees(a - math.pi / 2))
		for s_ in (-1, 1):
			blk((s_ * (r + ring / 2), (ob + spring) / 2, 0), (ring - 0.01, spring - ob, d + 0.02), T("limestone"), bevel=0.012, rz=J(0.8))
		blk((0, ob - 0.05, 0.02), (ow + 0.4, 0.1, d + 0.1), T("limestone", "c"), bevel=0.015)
		leaded(ow - 0.04, ob, spring, r - 0.02)
		return
	wall_body(w, h, d, hole=("rect", ow, ob, top))
	if S == "shack":
		shack_frame(w, h, d, gap=(-ow / 2 - 0.12, ow / 2 + 0.12, False))
		# Split-log frame, cross bars, and two plank shutters swung open flat against the wall.
		log((-ow / 2 - 0.1, ob - 0.04, 0.02), (ow / 2 + 0.1, ob - 0.04, 0.02), 0.06)
		log((-ow / 2 - 0.12, top + 0.05, 0.02), (ow / 2 + 0.12, top + 0.05, 0.02), 0.065)
		for s_ in (-1, 1):
			log((s_ * (ow / 2 + 0.04), ob - 0.07, 0.02), (s_ * (ow / 2 + 0.04), top + 0.08, 0.02), 0.05)
		blk((0, ob + oh / 2, 0), (0.05, oh, 0.05), T("wood", "dark"), bevel=0.008)
		blk((0, ob + oh / 2, 0), (ow, 0.05, 0.05), T("wood", "dark"), bevel=0.008)
		for s_ in (-1, 1):
			sx = s_ * (ow / 2 + 0.31)
			for k in range(2):
				blk((sx + (k - 0.5) * 0.21, ob + oh / 2, 0.072), (0.2, oh - 0.04 + J(0.02), 0.045), T("greywood"), bevel=0.008, rz=J(1))
			for yy in (ob + 0.15, top - 0.15):
				strap((sx, yy, 0.1), (0.38, 0.05, 0.015), rivets=2)
		return
	# Stonehold: heavy timber lintel, stone sill, iron grille.
	blk((0, top + 0.1, 0), (ow + 0.5, 0.2, d + 0.06), wood_dark(), bevel=0.02, rz=J(0.8))
	for s_ in (-1, 1):
		peg((s_ * (ow / 2 + 0.15), top + 0.1, d / 2 + 0.035), kit.tex_mat("copper", "dark"))
	blk((0, ob - 0.06, 0.02), (ow + 0.3, 0.12, d + 0.08), T("limestone", "c"), bevel=0.02)
	for x in (-ow / 4, 0.0, ow / 4):
		blk((x, ob + oh / 2, 0), (0.035, oh + 0.04, 0.035), kit.tex_mat("iron"), bevel=0.004)
	for y in (ob + oh * 0.33, ob + oh * 0.66):
		blk((0, y, 0), (ow + 0.04, 0.03, 0.03), kit.tex_mat("iron"), bevel=0.004)
	for s_ in (-1, 1):
		blk((s_ * (ow / 2 + 0.03), ob + oh / 2, 0), (0.06, oh, d), wood_dark(), bevel=0.01)


def leaded(ow, ob, spring, r):
	"""Leaded glass: pale glass and a diamond lattice of thin dark strips, filling a round-topped window."""
	glass = kit.mat("water_light", -0.15, rough=0.25)
	blk((0, (ob + spring) / 2, 0), (ow, spring - ob, 0.02), glass, bevel=0)
	prof = [(-ow / 2, spring)] + [(-math.cos(math.pi * i / 10) * r, spring + math.sin(math.pi * i / 10) * r) for i in range(1, 10)] + [(ow / 2, spring)]
	verts = [(x, y, -0.01) for x, y in prof] + [(x, y, 0.01) for x, y in prof]
	n = len(prof)
	faces = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, i + 1, i + 1 + n, i + n) for i in range(n - 1)]
	mesh(verts, faces, glass)
	lead = kit.mat("iron", -0.3)
	for s_ in (-1, 1):
		for k in range(-3, 4):
			x0 = k * 0.25
			blk((x0, (ob + spring + r * 0.6) / 2, 0), (0.018, (spring + r * 0.6 - ob) * 1.25, 0.03), lead, bevel=0, rz=s_ * 35)
	# trim the lattice inside the frame: a thin frame hides the ends
	for s_ in (-1, 1):
		blk((s_ * (ow / 2 + 0.01), (ob + spring) / 2, 0), (0.04, spring - ob, 0.06), wood_dark(), bevel=0.005)


# ---------------- doors ----------------
def door(w=1.0, h=1.8, d=0.12):
	r = w / 2
	spring = h - r
	m = (lambda: T("wood")) if S == "shack" else (lambda: T("wood", "dark")) if S == "stone" else (lambda: T("greenpaint"))
	n = 5
	pw = w / n
	fr = Frame()
	ctop = lambda x: spring + math.sqrt(max(0.0, r * r - min(x * x, r * r)))
	for i in range(n):
		a, b = -r + i * pw + 0.006, -r + (i + 1) * pw - 0.006
		plank_shape(fr, a, b, lambda x: 0.0, lambda x: ctop(x) - 0.004, J(0.006), d * 0.8, m(), k=6)
	# Back battens and a brace.
	for y in (0.3, spring - 0.1):
		blk((0, y, -d * 0.45), (w - 0.1, 0.1, 0.04), wood_dark() if S != "brick" else T("greenpaint", "dark"), bevel=0.008)
	seg = math.hypot(w - 0.2, spring - 0.4)
	blk((0, (spring + 0.2) / 2, -d * 0.45), (0.09, seg, 0.035), wood_dark(), bevel=0.006, rz=math.degrees(math.atan2(w - 0.2, spring - 0.4)))
	# Copper hinges from the hinge side (x = -0.5), and a ring pull.
	hm = kit.tex_mat("iron") if S == "shack" else kit.tex_mat("copper", "b")
	for y in (0.32, spring - 0.08):
		blk((-r + 0.3, y, d * 0.42), (0.58, 0.07, 0.02), hm, bevel=0.004)
		for x in (-r + 0.08, -r + 0.3, -r + 0.52):
			peg((x, y, d * 0.42 + 0.012), hm)
		log((-r + 0.005, y - 0.05, d * 0.3), (-r + 0.005, y + 0.05, d * 0.3), 0.025, hm, seg=6, rings=1, ends=False, bend=0)
	ring_m = kit.tex_mat("copper", "b") if S != "shack" else kit.tex_mat("iron")
	blk((r * 0.62, spring * 0.62, d * 0.42 + 0.005), (0.07, 0.07, 0.02), ring_m, bevel=0.004)
	kit.ring(0.055, 0.012, G((r * 0.62, spring * 0.62 - 0.06, d * 0.42 + 0.025)), ring_m, rot=(90, 0, 0), seg=12)
	if S == "stone":  # extra copper straps across the dark planks
		for y in (0.9,):
			blk((0, y, d * 0.42), (w - 0.06, 0.06, 0.018), kit.tex_mat("copper", "b"), bevel=0.004)


# ---------------- floors and foundations ----------------
def tri_pts(k=1.0):
	return [(-k, TRI_IN * k), (k, TRI_IN * k), (0.0, -TRI_OUT * k)]


def tri_half(z, k=1.0):
	"""Half-width of the triangle at depth z (0 at the point)."""
	return max(0.0, (z + TRI_OUT * k) / (TRI_IN * k + TRI_OUT * k) * k)


def in_tri(x, z, k=1.0, inset=0.0):
	pts = tri_pts(k)
	for i in range(3):
		(ax, az), (bx, bz) = pts[i], pts[(i + 1) % 3]
		ex, ez = bx - ax, bz - az
		L = math.hypot(ex, ez)
		# inward normal (centroid at origin)
		nx, nz = -ez / L, ex / L
		if nx * (0 - ax) + nz * (0 - az) < 0:
			nx, nz = -nx, -nz
		if nx * (x - ax) + nz * (z - az) < inset:
			return False
	return True


def tri_edges(k=1.0):
	"""[(mid_x, mid_z, yaw_deg)] for each edge; the local +z of the edge frame points out."""
	out = []
	pts = tri_pts(k)
	for i in range(3):
		(ax, az), (bx, bz) = pts[i], pts[(i + 1) % 3]
		mx, mz = (ax + bx) / 2, (az + bz) / 2
		yaw = math.degrees(math.atan2(mx, mz))  # local +z toward the outward direction
		out.append((mx, mz, yaw))
	return out


def deck(x0, x1, z0, z1, y0, t, tri=False, k=1.0):
	"""The walking surface: planks (shack), flagstones (stone), basket-weave bricks (brick)."""
	if S == "shack":
		zz = z0
		while zz < z1 - 0.03:
			pw = min(rng.uniform(0.18, 0.27), z1 - zz)
			if z1 - (zz + pw) < 0.08:
				pw = z1 - zz
			a, b = zz, zz + pw
			lo, hi = x0, x1
			if tri:
				hw = tri_half(a, k)
				lo, hi = -hw + 0.02, hw - 0.02
			if hi - lo > 0.1:
				m = T("greywood") if rng.random() < 0.2 else T("wood")
				blk(((lo + hi) / 2, y0 + t / 2 + J(0.006), (a + b) / 2), (hi - lo, t, pw - 0.014), m, bevel=0.01, rx=J(0.6))
				for x in (lo + 0.08, hi - 0.08):
					peg((x, y0 + t + 0.004, (a + b) / 2))
			zz += pw
		return
	cell = 0.5 if S == "stone" else 0.25
	blk(((x0 + x1) / 2, y0 + t * 0.4, (z0 + z1) / 2), (x1 - x0 - 0.02, t * 0.8, z1 - z0 - 0.02), mortar_m(), bevel=0) if not tri else \
		mesh_tri_slab(y0, y0 + t * 0.8, k, mortar_m())
	if S == "stone":
		blocks, _ = layout(x0, x1, z0, z1, (0.38, 0.6), (0.4, 0.7))
		tp = tri_planes(k, 0.2) if tri else None
		for (a, b, za, zb, r, e) in blocks:
			cx, cz = (a + b) / 2, (za + zb) / 2
			if tri:
				rect = [(a + 0.015, za + 0.015), (b - 0.015, za + 0.015), (b - 0.015, zb - 0.015), (a + 0.015, zb - 0.015)]
				if needs_clip(rect, tp):
					poly = clip_poly(rect, tp)
					if poly and area(poly) > 0.006:
						floor_poly(poly, y0, y0 + t + J(0.008), stone_tone())
					continue
			blk((cx, y0 + t / 2 + J(0.008), cz), (b - a - 0.03, t, zb - za - 0.03), stone_tone(), bevel=0.02, rx=J(0.8), rz=J(0.8))
	else:  # basket weave: 0.5 m squares of two bricks, turning each square
		n = int(round((x1 - x0) / cell))
		m_ = int(round((z1 - z0) / cell))
		for i in range(n):
			for j in range(m_):
				cx, cz = x0 + cell * (i + 0.5), z0 + cell * (j + 0.5)
				for h in (-1, 1):
					if (i + j) % 2:
						c, s = (cx + h * cell / 4, cz), (cell / 2 - 0.016, t, cell - 0.016)
					else:
						c, s = (cx, cz + h * cell / 4), (cell - 0.016, t, cell / 2 - 0.016)
					if tri:
						rect = [(c[0] - s[0] / 2, c[1] - s[2] / 2), (c[0] + s[0] / 2, c[1] - s[2] / 2), (c[0] + s[0] / 2, c[1] + s[2] / 2), (c[0] - s[0] / 2, c[1] + s[2] / 2)]
						tp = tri_planes(k, 0.2)
						if needs_clip(rect, tp):
							poly = clip_poly(rect, tp)
							if poly and area(poly) > 0.003:
								floor_poly(poly, y0, y0 + t, brick_tone())
							continue
					blk((c[0], y0 + t / 2 + J(0.004), c[1]), s, brick_tone(), bevel=0, rx=J(0.5), rz=J(0.5))
	if tri:  # edge stones along the three sides (cover the stepped ends)
		for (mx, mz, yaw) in tri_edges(k):
			fr = Frame(mx, mz, yaw)
			L = 2 * k
			n = 4 if S == "stone" else 8
			for i in range(n):
				x = -L / 2 + L * (i + 0.5) / n
				ln = L / n - 0.02
				# shorten near the corners so neighbours don't cross outside
				e = abs(x) + ln / 2 - (L / 2 - 0.2)
				if e > 0:
					ln -= e
					x -= math.copysign(e / 2, x)
				fr.box((x, y0 + t / 2 + 0.005, -0.12), (ln, t + 0.01, 0.22),
					stone_tone() if S == "stone" else T("limestone"), bevel=0.015 if S == "stone" else 0.006, rz=J(0.6))


def mesh_tri_slab(y0, y1, k, m, inset=0.0):
	pts = [(x * (1 - inset), z * (1 - inset)) for x, z in tri_pts(k)]
	v = [(x, y0, z) for x, z in pts] + [(x, y1, z) for x, z in pts]
	f = [(0, 1, 2), (3, 4, 5), (0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)]
	return mesh(v, f, m)


def joists(xs, z0, z1, y0, r, tri=False, k=1.0, along="z"):
	"""Beams under a floor (they're the ceiling seen from below)."""
	for x in xs:
		a, b = z0, z1
		if tri:
			# along z at this x: from where |x| fits in the triangle to the front edge
			a = -TRI_OUT * k + abs(x) * (TRI_IN * k + TRI_OUT * k) / k + 0.1
			b = TRI_IN * k - 0.06
			if b - a < 0.2:
				continue
		if S == "shack":
			log((x, y0 + r, a), (x, y0 + r, b), r)
		else:
			blk((x, y0 + r, (a + b) / 2), (r * 1.6, r * 2, b - a), wood_dark(), bevel=0.015, rz=J(0.5))
			for zz in (a + 0.12, b - 0.12):
				blk((x, y0 + r * 2 + 0.01, zz), (r * 1.6 + 0.04, 0.02, 0.1), kit.tex_mat("copper", "b"), bevel=0.003)
				blk((x + r * 0.8 + 0.01, y0 + r * 1.2, zz), (0.02, r * 1.6, 0.1), kit.tex_mat("copper", "b"), bevel=0.003)


def floor(w=2.0, t=0.25, dd=2.0):
	js = 0.07 if S == "shack" else 0.06
	joists((-0.55, 0.55), -dd / 2 + 0.02, dd / 2 - 0.02, 0, js)
	if S == "shack":  # edge logs under the boards at front and back
		for z in (-dd / 2 + 0.08, dd / 2 - 0.08):
			log((-w / 2 + 0.02, js, z), (w / 2 - 0.02, js, z), js)
	deck(-w / 2, w / 2, -dd / 2, dd / 2, js * 2 - 0.01, t - js * 2 + 0.01)


def floor_triangle(t=0.25):
	js = 0.07 if S == "shack" else 0.06
	joists((-0.35, 0.35), 0, 0, 0, js, tri=True)
	if S == "shack":
		for (mx, mz, yaw) in tri_edges():
			fr = Frame(mx, mz, yaw)
			a, b = fr.p(-0.78, js, -0.1), fr.p(0.78, js, -0.1)
			log(a, b, js)
	deck(-1, 1, -TRI_OUT, TRI_IN, js * 2 - 0.01, t - js * 2 + 0.01, tri=True)


def shack_legs(corners, h_frame):
	"""Tall log legs on flat stone footings, with diagonal braces."""
	for (x, z) in corners:
		blk((x + J(0.02), 0.05, z + J(0.02)), (0.36 + J(0.04), 0.1, 0.34 + J(0.04)), T("stone"), bevel=0.025, ry=J(20))
		log((x, 0.08, z), (x + J(0.015), h_frame + 0.02, z + J(0.015)), 0.12)
	return corners


def foundation(w=2.0, h=1.0, dd=2.0):
	if S == "shack":
		cx, cz = w / 2 - 0.2, dd / 2 - 0.2
		legs = shack_legs([(-cx, -cz), (cx, -cz), (cx, cz), (-cx, cz)], h - 0.25)
		yb = h - 0.21
		for z in (-cz, cz):
			log((-w / 2 + 0.02, yb, z), (w / 2 - 0.02, yb, z), 0.11)
		for x in (-cx, cx):
			log((x, yb + 0.02, -dd / 2 + 0.02), (x, yb + 0.02, dd / 2 - 0.02), 0.1)
		log((0, yb, -dd / 2 + 0.05), (0, yb, dd / 2 - 0.05), 0.09)
		for (x0, z0), (x1, z1) in (((-cx, cz), (cx, cz)), ((cx, -cz), (-cx, -cz)), ((cx, cz), (cx, -cz)), ((-cx, -cz), (-cx, cz))):
			log((x0, 0.15, z0), ((x0 + x1) / 2 + (x1 - x0) * 0.2, yb - 0.06, (z0 + z1) / 2 + (z1 - z0) * 0.2), 0.05)
			lash((x0, yb - 0.15, z0), 0.12)
		deck(-w / 2, w / 2, -dd / 2, dd / 2, h - 0.1, 0.1)
		return
	t = 0.32
	sides = [(0, dd / 2 - t / 2, 0), (0, -dd / 2 + t / 2, 180), (w / 2 - t / 2, 0, 90), (-w / 2 + t / 2, 0, -90)]
	for (ox, oz, yaw) in sides:
		fr = Frame(ox, oz, yaw)
		L = (dd - 2 * t) if yaw in (90, -90) else w
		foundation_side(fr, L, h - 0.1, t, full=yaw in (0, 180))
	cap_top(w, h, dd)


def foundation_side(fr, L, h, t, full=True):
	if S == "stone":
		blocks, mortar = layout(-L / 2, L / 2, 0, h, (0.28, 0.4), (0.4, 0.7), quoin=(0.5, 0.3) if full else None)
		masonry(fr, blocks, mortar, t, stone_tone, mortar_m(), bevel=0.02, moss=3, quoin_m=None)
		blk(fr.p(0, 0.08, 0.03), (L + (0.06 if full else 0), 0.16, t + 0.06), T("basalt", "b"), bevel=0.025, ry=fr.yaw)  # plinth
		return
	# Hearthbrick: brick piers with a little round arch between them, dark crawl space behind.
	ow = min(1.1, L - 0.5)
	cut = round_hole(ow, 0.72, 0.12) if ow > 0.5 else None
	blocks, mortar = layout(-L / 2, L / 2, 0, h, 0.125, 0.25, hole=cut, quoin=(0.3, 0.18) if full else None)
	masonry(fr, blocks, mortar, t, brick_tone, mortar_m(), gap=0.016, bevel=0.0, tilt=0.6, jit=0.006, quoin_m=T("limestone"))
	if cut:
		fr.box((0, 0.36, -t * 0.4), (ow + 0.02, 0.72, 0.04), kit.mat("charcoal", 0.0), bevel=0)
		r = ow / 2
		spring = 0.72 - r
		n = 11
		for i in range(n):
			a = math.pi * (i + 0.5) / n
			rr = r + 0.065
			fr.box((-math.cos(a) * rr, spring + math.sin(a) * rr, 0), (math.pi * rr / n - 0.012, 0.12, t), brick_tone(), bevel=0,
				rz=math.degrees(a - math.pi / 2))
		for s_ in (-1, 1):
			fr.box((s_ * (r + 0.065), spring / 2, 0), (0.12, spring, t), brick_tone(), bevel=0)


def cap_top(w, h, dd, tri=False):
	"""Top of a stone/brick foundation: the floor surface, plus copper band (stone) or limestone capping row (brick)."""
	deck(-w / 2, w / 2, -dd / 2, dd / 2, h - 0.12, 0.12, tri=tri)
	if tri:
		return
	if S == "stone":
		for (ox, oz, yaw, L) in ((0, dd / 2, 0, w), (0, -dd / 2, 180, w), (w / 2, 0, 90, dd), (-w / 2, 0, -90, dd)):
			fr = Frame(ox, oz, yaw)
			fr.box((0, h - 0.17, 0.005), (L - 0.04, 0.09, 0.025), kit.tex_mat("copper", "b"), bevel=0.004)
			for x in (-L / 2 + 0.2, -L / 6, L / 6, L / 2 - 0.2):
				peg(fr.p(x, h - 0.17, 0.02), kit.tex_mat("copper", "dark"))
	else:
		for (ox, oz, yaw, L) in ((0, dd / 2, 0, w), (0, -dd / 2, 180, w), (w / 2, 0, 90, dd), (-w / 2, 0, -90, dd)):
			fr = Frame(ox, oz, yaw)
			n = 5
			for i in range(n):
				x = -L / 2 + L * (i + 0.5) / n
				fr.box((x, h - 0.06, -0.1), (L / n - 0.015, 0.12, 0.24), T("limestone"), bevel=0.012, rz=J(0.5))


def foundation_triangle(h=1.0):
	if S == "shack":
		pts = [(x * 0.78, z * 0.78) for x, z in tri_pts()]
		shack_legs(pts, h - 0.25)
		yb = h - 0.21
		for i in range(3):
			a, b = pts[i], pts[(i + 1) % 3]
			log((a[0], yb, a[1]), (b[0], yb, b[1]), 0.11)
			lash((a[0], yb - 0.15, a[1]), 0.12)
		log((0, yb - 0.01, -TRI_OUT * 0.78), (0, yb - 0.01, TRI_IN * 0.95), 0.09)
		for i in range(3):
			a, b = pts[i], pts[(i + 1) % 3]
			log((a[0], 0.15, a[1]), (a[0] + (b[0] - a[0]) * 0.6, yb - 0.06, a[1] + (b[1] - a[1]) * 0.6), 0.05)
		deck(-1, 1, -TRI_OUT, TRI_IN, h - 0.1, 0.1, tri=True)
		return
	t = 0.3
	for (mx, mz, yaw) in tri_edges():
		# the side sits inside the edge; corners get piers
		fr = Frame(mx - math.sin(math.radians(yaw)) * t / 2, mz - math.cos(math.radians(yaw)) * t / 2, yaw)
		foundation_side(fr, 2 - t * 1.75, h - 0.1, t, full=False)
	for (x, z) in tri_pts():
		cx, cz = x * 0.8, z * 0.8
		yaw = math.degrees(math.atan2(x, z))
		y = 0.0
		k = 0
		while y < h - 0.13:
			hh = min(0.3 if S == "stone" else 0.25, h - 0.1 - y)
			m = stone_tone() if S == "stone" else T("limestone")
			blk((cx, y + hh / 2, cz), (0.36 + (0.06 if k % 2 else 0), hh - 0.02, 0.36), m, bevel=0.02, ry=yaw + J(4))
			y += hh
			k += 1
	cap_top(2, h, 2, tri=True)
	mesh_tri_slab(h - 0.14, h - 0.11, 1.0, mortar_m(), inset=0.02)


# ---------------- stairs, supports, railings ----------------
def stairs(w=2.0, h=2.0, dd=2.0, n=5):
	dz = dd / n
	if S == "shack":
		for s_ in (-1, 1):
			x = s_ * (w / 2 - 0.1)
			log((x, 0.06, dd / 2 - 0.04), (x, h - 0.12, -dd / 2 + 0.08), 0.1)
			log((x, 0, -dd / 2 + 0.12), (x, h - 0.1, -dd / 2 + 0.12), 0.1)  # back leg: holds the top up
			blk((x, 0.05, -dd / 2 + 0.12), (0.3, 0.1, 0.3), T("stone"), bevel=0.02, ry=J(20))
			blk((x, 0.05, dd / 2 - 0.15), (0.3, 0.1, 0.3), T("stone"), bevel=0.02, ry=J(20))
		for i in range(n):
			y = (i + 1) * h / n
			z = dd / 2 - (i + 0.5) * dz
			blk((J(0.02), y - 0.05, z), (w - 0.06, 0.08, dz + 0.02), T("greywood") if rng.random() < 0.25 else T("wood"), bevel=0.01, rx=J(0.6), rz=J(0.8))
			for x in (-w / 2 + 0.1, w / 2 - 0.1):
				peg((x, y - 0.005, z))
			blk((0, y - 0.13, z - dz / 2 + 0.06), (w - 0.25, 0.1, 0.06), T("wood", "dark"), bevel=0.008)  # cleat under the tread
		return
	for i in range(n):
		y1 = (i + 1) * h / n
		z = dd / 2 - (i + 0.5) * dz
		fr = Frame(0, z, 0)
		rh = (0.3, 0.42) if S == "stone" else 0.125
		bl = (0.4, 0.75) if S == "stone" else 0.25
		blocks, mortar = layout(-w / 2, w / 2, 0, y1 - 0.08, rh, bl)
		masonry(fr, blocks, mortar, dz, stone_tone if S == "stone" else brick_tone, mortar_m(), gap=0.02 if S == "stone" else 0.016,
			bevel=0.02 if S == "stone" else 0.0, jit=0.0, tilt=0.6)
		blk((0, y1 - 0.04, z + 0.01), (w, 0.08, dz + 0.02), T("limestone", "c") if S == "brick" else stone_tone(), bevel=0.02, rx=J(0.5))
		if S == "stone":
			blk((0, y1 - 0.02, z + dz / 2 + 0.005), (w - 0.1, 0.05, 0.02), kit.tex_mat("copper", "b"), bevel=0.004)


def pillar(w=0.4, h=2.0):
	if S == "shack":
		blk((0, 0.05, 0), (w, 0.1, w - 0.02), T("stone"), bevel=0.025, ry=J(6))
		log((0, 0.08, 0), (J(0.01), h - 0.06, J(0.01)), 0.16)
		blk((0, h - 0.04, 0), (w, 0.08, w * 0.7), T("wood", "dark"), bevel=0.012, ry=J(4))
		lash((0, h - 0.3, 0), 0.16)
		lash((0, 0.35, 0), 0.16)
		return
	cap = (lambda: stone_tone()) if S == "stone" else (lambda: T("limestone"))
	blk((0, 0.11, 0), (w, 0.22, w), cap(), bevel=0.025, ry=J(2))
	blk((0, h - 0.1, 0), (w, 0.2, w), cap(), bevel=0.025, ry=J(2))
	if S == "stone":
		blk((0, h / 2, 0), (w - 0.14, h - 0.1, w - 0.14), mortar_m(), bevel=0)  # mortar core: blocks sit on it
		y = 0.22
		while y < h - 0.22:
			hh = min(rng.uniform(0.3, 0.42), h - 0.2 - y)
			blk((J(0.008), y + hh / 2, J(0.008)), (w - 0.08, hh - 0.02, w - 0.08), stone_tone(), bevel=0.02, ry=J(3))
			y += hh
		blk((0, h * 0.55, 0), (w - 0.05, 0.07, w - 0.05), kit.tex_mat("copper", "b"), bevel=0.004)
	else:  # round brick pillar: courses of bricks around a core, pale mortar between
		kit.cylinder(w * 0.4, h - 0.4, G((0, h / 2, 0)), mortar_m(), verts=12, bevel=0)
		y = 0.22
		k = 0
		while y < h - 0.22:
			for j in range(8):
				a = 2 * math.pi * (j + 0.5 * (k % 2)) / 8
				blk((math.cos(a) * w * 0.36, y + 0.0625, math.sin(a) * w * 0.36), (0.13, 0.11, 0.1), brick_tone(), bevel=0, ry=-math.degrees(a) + 90)
			y += 0.125
			k += 1


def beam(w=2.0, s=0.3):
	if S == "shack":
		log((-w / 2 + 0.01, s / 2, 0), (w / 2 - 0.01, s / 2, 0), s / 2 - 0.01)
		for x in (-w / 2 + 0.25, w / 2 - 0.25):
			lash((x, s / 2, 0), s / 2 - 0.01, axis="x")
		return
	blk((0, s / 2, 0), (w - 0.02, s - 0.02, s - 0.02), wood_dark(), bevel=0.03, rz=J(0.5))
	for s_ in (-1, 1):
		blk((s_ * (w / 2 - 0.05), s / 2, 0), (0.1, s, s), kit.tex_mat("copper", "b"), bevel=0.008)
		for dy in (-0.07, 0.07):
			peg((s_ * (w / 2 - 0.05), s / 2 + dy, s / 2 + 0.003), kit.tex_mat("copper", "dark"))
	if S == "brick":
		for x in (-0.5, 0.0, 0.5):
			for dy in (-0.08, 0.08):
				peg((x, s / 2 + dy, s / 2 - 0.005), kit.tex_mat("copper", "dark"))


def railing(w=2.0, h=1.0, d=0.15):
	if S == "shack":
		for x in (-w / 2 + 0.07, 0.0, w / 2 - 0.07):
			log((x, 0, 0), (x, h, 0), 0.065)
		log((-w / 2 + 0.02, h - 0.07, 0), (w / 2 - 0.02, h - 0.07, 0.0), 0.06)
		log((-w / 2 + 0.05, h * 0.45, 0), (w / 2 - 0.05, h * 0.45, 0), 0.045)
		for s_ in (-1, 1):
			log((s_ * (w / 2 - 0.1), 0.08, 0), (s_ * 0.08, h * 0.45 - 0.04, 0), 0.035)
		for x in (-w / 2 + 0.07, 0.0, w / 2 - 0.07):
			lash((x, h - 0.07, 0), 0.07)
		return
	if S == "stone":  # balustrade: base rail, turned balusters, top rail, square end posts
		blk((0, 0.07, 0), (w, 0.14, d), stone_tone(), bevel=0.015)
		blk((0, h - 0.06, 0), (w, 0.12, d + 0.02), T("limestone", "c"), bevel=0.015)
		for s_ in (-1, 1):
			blk((s_ * (w / 2 - 0.08), h / 2, 0), (0.16, h - 0.1, d), stone_tone(), bevel=0.015)
		n = 7
		for i in range(n):
			x = -w / 2 + 0.25 + i * (w - 0.5) / (n - 1)
			kit.cone(0.035, 0.06, 0.28, G((x, 0.29, 0)), T("stone", "c"), verts=8, bevel=0)
			kit.cone(0.06, 0.035, 0.28, G((x, 0.57, 0)), T("stone", "c"), verts=8, bevel=0)
			kit.cylinder(0.04, 0.24, G((x, 0.82, 0)), T("stone", "c"), verts=8, bevel=0)
		blk((0, h - 0.125, d / 2 + 0.003), (w - 0.2, 0.03, 0.01), kit.tex_mat("copper", "b"), bevel=0.003)
		return
	# Hearthbrick: brick base, small brick arches, limestone top rail.
	blocks, mortar = layout(-w / 2, w / 2, 0, 0.25, 0.125, 0.25)
	masonry(Frame(), blocks, mortar, d, brick_tone, mortar_m(), gap=0.016, bevel=0.0, tilt=0.5, jit=0.004)
	for x in (-w / 2 + 0.09, -0.33, 0.33, w / 2 - 0.09):
		blocks, mortar = layout(x - 0.09, x + 0.09, 0.25, h - 0.1, 0.125, 0.18)
		masonry(Frame(), blocks, mortar, d, brick_tone, mortar_m(), gap=0.016, bevel=0.0, tilt=0.5, jit=0.004)
	for (a, b) in ((-w / 2 + 0.18, -0.42), (-0.24, 0.24), (0.42, w / 2 - 0.18)):
		cx, r = (a + b) / 2, (b - a) / 2
		spring = h - 0.1 - r - 0.07
		for i in range(7):
			ang = math.pi * (i + 0.5) / 7
			blk((cx - math.cos(ang) * (r + 0.04), spring + math.sin(ang) * (r + 0.04), 0), (math.pi * r / 7, 0.08, d - 0.01), brick_tone(),
				bevel=0, rz=math.degrees(ang - math.pi / 2))
		blk((cx, h - 0.1 - 0.035, 0), (b - a, 0.07, d - 0.02), brick_tone(), bevel=0)
	blk((0, h - 0.05, 0), (w, 0.1, d + 0.03), T("limestone"), bevel=0.012)


# ---------------- roofs (hollow panels) ----------------
def roof_mat():
	return T("shingle") if S == "shack" else T("rooftile")


def panel(axis, u_low, u_high, rise_base, clip=None, rafters=True, under=True, cover=True, y_low=0.0):
	"""One sloped roof panel. axis 'z' = slope along z, 'x' = along x. It runs from u_low (low, y_low)
	to u_high (high, y_low + rise_base). clip(ua, ub) -> (v0, v1) = what's covered across, per row."""
	du = u_high - u_low
	L = math.hypot(abs(du), rise_base)
	ang = math.degrees(math.atan2(rise_base, abs(du)))
	sgn = 1 if du < 0 else -1  # rising toward -u = +1

	def P(u, v, y):
		return (v, y, u) if axis == "z" else (u, y, v)

	def base(u):
		return y_low + rise_base * (u - u_low) / du

	def rot(extra=0.0):
		a = sgn * (ang + extra)
		return dict(rx=a) if axis == "z" else dict(rz=-a)

	full = clip or (lambda ua, ub: (-1.0, 1.0))
	rows = max(3, round(L / (0.34 if S == "shack" else 0.42)))
	nrm_lift = math.cos(math.radians(ang))
	for i in range(rows):
		ua = u_low + du * i / rows
		ub = u_low + du * (i + 1) / rows
		v0, v1 = full(min(ua, ub), max(ua, ub))
		if v1 - v0 < 0.06:
			continue
		um = (ua + ub) / 2
		y = base(um)
		if under:  # boards seen from below
			m = kit.tex_mat("wood", rng.choice("ab")) if S != "brick" else kit.tex_mat("wood", "b")
			blk(P(um, (v0 + v1) / 2, y + 0.075 * nrm_lift), *_sz(axis, L / rows + 0.01, v1 - v0, 0.03), m, bevel=0.004, **rot())
		if not cover:
			continue
		if S == "shack":
			# shingles: short overlapping courses, each a few rough shakes
			vv = v0
			while vv < v1 - 0.03:
				sw = min(rng.uniform(0.25, 0.42), v1 - vv)
				if v1 - (vv + sw) < 0.1:
					sw = v1 - vv
				blk(P(um + sgn * 0.0, vv + sw / 2, y + (0.12 + J(0.006)) * nrm_lift), *_sz(axis, L / rows + 0.08, sw - 0.02, 0.035), roof_mat(),
					bevel=0.006, **rot(J(1.5)))
				vv += sw
		else:
			# terracotta: a flat underlay and rows of rounded tiles running down the slope
			blk(P(um, (v0 + v1) / 2, y + 0.1 * nrm_lift), *_sz(axis, L / rows + 0.02, v1 - v0, 0.03), T("rooftile", "dark"), bevel=0, **rot())
			k = max(1, int((v1 - v0) / 0.14))
			sp = (v1 - v0) / k
			for j in range(k):
				v = v0 + sp * (j + 0.5)
				dy = (0.13 + J(0.005)) * nrm_lift
				h0, h1 = base(ua) + dy, base(ub) + dy
				a = P(ua - (du / abs(du)) * 0.03, v, h0 - 0.006 * (1 if du > 0 else -1))
				b = P(ub + (du / abs(du)) * 0.03, v, h1)
				log(a, b, 0.058, T("rooftile"), seg=7, rings=1, ends=True, bend=0, end_m=T("rooftile", "dark"))
	if rafters:
		vs = [-0.85, 0.0, 0.85]
		for v in vs:
			us = [u_low + du * t / 40 for t in range(41)]
			ok = [u for u in us if full(min(u, u), max(u, u))[0] - 0.05 <= v <= full(u, u)[1] + 0.05]
			if len(ok) < 4:
				continue
			a, b = ok[0], ok[-1]
			r = 0.05
			pa = P(a, v, base(a) + r * nrm_lift + 0.005)
			pb = P(b, v, base(b) + r * nrm_lift + 0.005)
			if S == "shack":
				log(pa, pb, r)
			else:
				log(pa, pb, r, wood_dark(), seg=6, rings=1)


def _sz(axis, along, across, thick):
	return ((across, thick, along),) if axis == "z" else ((along, thick, across),)


def roof(w=2.0, rise=1.0, dd=2.0):
	panel("z", dd / 2, -dd / 2, rise - 0.15)
	eave(w, dd)


def eave(w, dd, axis="z", u=None):
	"""A board along the low edge."""
	u = dd / 2 if u is None else u
	m = kit.tex_mat("wood", "dark")
	if axis == "z":
		blk((0, 0.07, u - 0.03), (w, 0.12, 0.05), m, bevel=0.008, rx=J(1))
	else:
		blk((u - 0.03, 0.07, 0), (0.05, 0.12, w), m, bevel=0.008, rz=J(1))


def ridge(w=2.0, rise=0.5, dd=2.0):
	panel("z", dd / 2, 0.0, rise - 0.15)
	panel("z", -dd / 2, 0.0, rise - 0.15)
	eave(w, dd)
	eave(w, dd, u=-dd / 2 + 0.06)
	if S == "shack":
		log((-w / 2, rise - 0.06, 0), (w / 2, rise - 0.06, 0), 0.08)
		for x in (-0.7, 0.0, 0.7):
			lash((x, rise - 0.06, 0), 0.08, axis="x")
	else:
		n = 6
		for i in range(n):
			x = -w / 2 + w * (i + 0.5) / n
			log((x - w / n / 2 - 0.01, rise - 0.07, 0), (x + w / n / 2 + 0.01, rise - 0.07, 0), 0.085, T("rooftile"), seg=8, rings=1, end_m=T("rooftile", "dark"))


def roof_corner(w=2.0, rise=1.0, dd=2.0, inner=False):
	hx, hz = w / 2, dd / 2
	rb = rise - 0.15
	if not inner:
		# outer hip: high at (-x, -z); panel A slopes to +z where x <= z, panel B slopes to +x where x >= z
		panel("z", hz, -hz, rb, clip=lambda ua, ub: (-hx, min(hx, ua)))
		panel("x", hx, -hx, rb, clip=lambda ua, ub: (-hz, min(hz, ua)))
	else:
		# inner valley: high along the -z and -x edges, low at (+x, +z)
		panel("z", hz, -hz, rb, clip=lambda ua, ub: (max(-hx, ub), hx))
		panel("x", hx, -hx, rb, clip=lambda ua, ub: (max(-hz, ub), hz))
	eave(w, dd, axis="z") if not inner else None
	eave(w, dd, axis="x", u=hx) if not inner else None
	# hip / valley along the diagonal
	tip, low = (-hx + 0.06, rb + 0.12, -hz + 0.06), (hx - 0.04, 0.14, hz - 0.04)
	if S == "shack":
		log(tip, low, 0.075)
		for f in (0.2, 0.5, 0.8):
			c = tuple(a + (b - a) * f for a, b in zip(tip, low))
			kit.ring(0.085, 0.016, G(c), kit.tex_mat("rope"), rot=(0, 0, 0), seg=10)
	else:
		n = 6
		for i in range(n):
			a = tuple(tip[k] + (low[k] - tip[k]) * i / n for k in range(3))
			b = tuple(tip[k] + (low[k] - tip[k]) * (i + 1.05) / n for k in range(3))
			log(a, b, 0.075, T("rooftile"), seg=8, rings=1, end_m=T("rooftile", "dark"))
			if i % 2 == 0:
				c = tuple((a[k] + b[k]) / 2 for k in range(3))
				kit.ring(0.082, 0.012, G(c), kit.tex_mat("copper", "b"), seg=10)
		if not inner:  # copper finial at the top
			kit.cone(0.05, 0.015, 0.16, G((tip[0], tip[1] + 0.1, tip[2])), kit.tex_mat("copper", "b"), verts=8, bevel=0)
			kit.rivet(G((tip[0], tip[1] + 0.2, tip[2])), kit.tex_mat("copper", "b"), r=0.035)


def gable(w=2.0, rise=1.0, d=0.3):
	if S == "shack":
		fr = Frame()
		xl = lambda y: -w / 2 + y / rise * w
		y = 0.12
		while y < rise - 0.08:
			hh = min(rng.uniform(0.17, 0.22), rise - 0.05 - y)
			ya, yb = y + 0.006, y + hh - 0.006
			xr = w / 2 - 0.12
			if xr - xl(yb) > 0.06:
				m = T("greywood") if rng.random() < 0.6 else T("wood")
				slab_poly(fr, [(xl(ya) + 0.05, ya), (xr, ya), (xr, yb), (xl(yb) + 0.05, yb)], J(0.01), d * 0.33, m)
			y += hh
		log((-w / 2, 0.09, 0), (w / 2, 0.09, 0), 0.09)
		log((w / 2 - 0.1, 0, 0), (w / 2 - 0.1, rise - 0.02, 0), 0.1)
		log((-w / 2 + 0.03, 0.12, 0.0), (w / 2 - 0.12, rise - 0.06, 0.0), 0.075)
		return
	wall_body(w, rise, d, slope=True)
	coping(w, rise, d)
	if rise >= 1.5:  # a round vent with a brick ring
		c = (0.45, 0.62, 0)
		kit.cylinder(0.17, d + 0.01, G(c), kit.mat("charcoal", 0.0), rot=(90, 0, 0), verts=14, bevel=0)
		for i in range(12):
			a = 2 * math.pi * i / 12
			blk((c[0] + math.cos(a) * 0.23, c[1] + math.sin(a) * 0.23, 0), (0.12, 0.1, d + 0.03), brick_tone(), bevel=0,
				rz=math.degrees(a) + 90)


# ---------------- Stonehold flat roof ----------------
def flat_roof(w=2.0, t=0.3, dd=2.0):
	joists((-0.55, 0.55), -dd / 2 + 0.03, dd / 2 - 0.03, 0, 0.07)
	deck(-w / 2, w / 2, -dd / 2, dd / 2, 0.14, t - 0.14)
	# drip edge: a slightly lower outer course on the front and back
	for z in (-dd / 2 + 0.05, dd / 2 - 0.05):
		blk((0, t - 0.06, z), (w - 0.04, 0.1, 0.1), T("basalt", "b"), bevel=0.015, rx=J(0.6))


def battlement(w=2.0, h=0.9, d=0.4):
	blocks, mortar = layout(-w / 2, w / 2, 0, 0.45, (0.2, 0.25), (0.4, 0.7))
	masonry(Frame(), blocks, mortar, d, stone_tone, mortar_m(), bevel=0.02, moss=2)
	blk((0, 0.475, 0), (w, 0.05, d + 0.02), kit.tex_mat("copper", "b"), bevel=0.004)
	for x in (-w / 2 + 0.15, -0.3, 0.3, w / 2 - 0.15):
		peg((x, 0.475, d / 2 + 0.012), kit.tex_mat("copper", "dark"))
	for cx in (-0.5, 0.5):
		blocks, mortar = layout(cx - 0.3, cx + 0.3, 0.5, h - 0.06, (0.16, 0.2), (0.25, 0.4))
		masonry(Frame(), blocks, mortar, d - 0.04, stone_tone, mortar_m(), bevel=0.02)
		blk((cx, h - 0.03, 0), (0.64, 0.06, d), T("limestone", "c"), bevel=0.015, rz=J(1))


def battlement_corner(w=0.6, h=1.3):
	blk((0, h / 2, 0), (w - 0.14, h - 0.05, w - 0.14), mortar_m(), bevel=0)
	y = 0.0
	k = 0
	while y < h - 0.12:
		hh = min(rng.uniform(0.24, 0.32), h - 0.1 - y)
		blk((J(0.01), y + hh / 2, J(0.01)), (w - 0.04 - (0.04 if k % 2 else 0), hh - 0.02, w - 0.04 - (0 if k % 2 else 0.04)), stone_tone(),
			bevel=0.02, ry=J(3))
		if k == 1:
			blk((0, y + hh + 0.01, 0), (w - 0.02, 0.04, w - 0.02), kit.tex_mat("copper", "b"), bevel=0.004)
		y += hh
		k += 1
	blk((0, h - 0.05, 0), (w, 0.1, w), T("limestone", "c"), bevel=0.02)
	kit.cone(0.16, 0.05, 0.08, G((0, h + 0.02, 0)), T("limestone", "b"), verts=8, bevel=0) if False else None


# ---------------- catalogue ----------------
COMMON = {
	"foundation": foundation, "foundation_half": lambda: foundation(2.0, 1.0, 1.0), "foundation_triangle": foundation_triangle, "floor": floor, "floor_triangle": floor_triangle,
	"wall": wall, "half_wall": half_wall, "window_wall": window_wall, "sloped_wall": sloped_wall,
	"doorway": doorway, "door": door, "pillar": pillar, "beam": beam, "railing": railing, "stairs": stairs,
	"foundation_steps": lambda: stairs(2.0, 1.0, 2.0, 4), "beam_half": lambda: beam(1.0), "ceiling_panel": floor,
}
SLOPED = {
	"gable_26": lambda: gable(2, 1.0), "gable_45": lambda: gable(2, 2.0),
	"roof_26": lambda: roof(2, 1.0), "roof_45": lambda: roof(2, 2.0),
	"roof_26_ridge": lambda: ridge(2, 0.5), "roof_45_ridge": lambda: ridge(2, 1.0),
	"roof_26_outer": lambda: roof_corner(2, 1.0), "roof_26_inner": lambda: roof_corner(2, 1.0, inner=True),
	"roof_45_outer": lambda: roof_corner(2, 2.0), "roof_45_inner": lambda: roof_corner(2, 2.0, inner=True),
}
FLAT = {"flat_roof": flat_roof, "battlement": battlement, "battlement_corner": battlement_corner}
KIT = {
	"plank_root": {**COMMON, **SLOPED},
	"cut_stone": {**COMMON, **FLAT, "arch_doorway": arch_doorway},
	"clay_brick": {**COMMON, **SLOPED, "arch_doorway": arch_doorway},
}


def all_keys():
	return [f"{p}__{f}" for f in KIT for p in KIT[f]]


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	keys = args or all_keys()
	if len(keys) == 1 and keys[0] in KIT:
		keys = [f"{p}__{keys[0]}" for p in KIT[keys[0]]]
	OUT.mkdir(parents=True, exist_ok=True)
	JOUR.mkdir(parents=True, exist_ok=True)
	for key in keys:
		piece, family = key.split("__")
		S = STYLE_OF[family]
		globals()["S"] = S
		rng.seed(sum(map(ord, key)))
		kit.reset()
		try:
			KIT[family][piece]()
			out = OUT / f"{key}.glb"
			kit.save(str(out), str(JOUR / f"{key}.png"), recenter=False, tex_size=256)
			print(f"PIECE_OK {key}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"PIECE_FAILED {key}: {e!r}")
