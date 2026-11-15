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

STYLE_OF = {"plank_root": "shack", "cut_stone": "stone", "clay_brick": "brick", "copper_ingot": "copper"}
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


def log(p0, p1, r, m=None, seg=8, rings=3, ends=True, bend=0.08, end_m=None, ru=1.0, rv=1.0):
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
			verts.append(tuple(c + u * math.cos(a) * rr * ru + v * math.sin(a) * rr * rv))
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
			log(tuple(p + ax * s_ * 0.004), tuple(p + ax * s_ * 0.016), r * 0.8, em, seg=seg, rings=1, ends=False, bend=0, ru=ru, rv=rv)
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
	if mortar:  # mortar stays well inside the outer blocks: never seen at the wall's ends or top (grey strips)
		mx0, mx1 = min(m_[0] for m_ in mortar), max(m_[1] for m_ in mortar)
		my1 = max(m_[3] for m_ in mortar)
		ends = [bl[0] for bl in blocks] + [bl[1] for bl in blocks]
		ins = next((i_ for i_ in (0.03, 0.037, 0.044, 0.051) if all(abs(abs(e_ - x_) + 0.013 - i_) > 0.006 for e_ in ends for x_ in (mx0, mx1))), 0.03)
	for (a, b, ya, yb) in mortar:
		a = a + (ins if a <= mx0 + 0.001 else 0.006)
		b = b - (ins if b >= mx1 - 0.001 else 0.006)
		ya, yb = ya + 0.004, yb - (0.03 if yb >= my1 - 0.001 else 0.004)
		rect = [(a, ya), (b, ya), (b, yb), (a, yb)]
		md = min(d * 0.8, d - 0.06)
		if clip and needs_clip(rect, clip):
			poly = clip_poly(rect, [(pa, pb, pc - 0.02 * math.hypot(pa, pb)) for (pa, pb, pc) in clip])
			if poly:
				slab_poly(fr, poly, z, md, mortar_m)
			continue
		fr.box(((a + b) / 2, (ya + yb) / 2, z), (b - a, yb - ya, md), mortar_m, bevel=0)
	for (a, b, ya, yb, r, end) in blocks:
		m = quoin_m if (end and quoin_m) else tones()
		dd = d - (0.014 if end else rng.uniform(0.022, 0.034))  # faces stay >= 0.7 cm inside the piece
		g2 = gap / 2
		rect = [(a + g2, ya + g2), (b - g2, ya + g2), (b - g2, yb - g2), (a + g2, yb - g2)]
		if clip and needs_clip(rect, clip):
			poly = clip_poly(rect, clip)
			if poly and area(poly) > 0.004:
				slab_poly(fr, poly, z + J(min(jit, 0.003)), dd, m)
			continue
		fr.box(((a + b) / 2 + J(0.003), (ya + yb) / 2, z + J(min(jit, 0.003))), (b - a - gap - 0.006, yb - ya - gap, dd), m, bevel=bevel,
			rz=J(min(tilt, 0.6)), rx=J(0.2))
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
			m = T("wood")
			dz = z + J(0.008)
			dd = d * rng.uniform(0.9, 1.0)
			lift = J(0.012)
			top = lambda x: y_top(x) + lift
			if not inside:
				if top((a + b) / 2) > y0 + 0.06 and top(a) > y0 + 0.01:
					plank_shape(fr, a, b, lambda x: y0, lambda x: max(y0 + 0.01, top(x)), dz, dd, m)
			else:
				if hole_bot and hole_bot > y0 + 0.05:
					plank_shape(fr, a, b, lambda x: y0, lambda x: hole_bot, dz, dd, m)
				if y_top((a + b) / 2) - hole_top((a + b) / 2) > 0.05:
					plank_shape(fr, a, b, hole_top, top, dz, dd, m, k=6)
			xx += pw


# ---------------- tones per style ----------------
def stone_tone():
	"""Stonehold (F73): one calm grey family, about 1 stone in 8 a little warmer. Never white/black/brown."""
	return T("warmstone") if rng.random() < 0.12 else T("greystone")


def brick_tone():
	"""Hearthbrick (F74): close warm reds, about 1 in 8 a slightly more orange brick. No yellow, no near-black."""
	return T("rooftile", rng.choice("bc")) if rng.random() < 0.12 else T("brick")


def LIME():
	"""Trim stone (caps, sills, keystones, quoins): grey stone for Stonehold, terracotta for Hearthbrick (no cream)."""
	return T("greystone", "c") if S != "brick" else T("rooftile", rng.choice("ab"))


def mortar_m():
	return kit.tex_mat("greystone", "dark") if S == "stone" else kit.tex_mat("limestone", "dark")


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
		rh, bl, quoin, qm = 0.125, 0.25, ((0.3, 0.18) if not slope else None), LIME()
		gap, bev = 0.016, 0.0
	cut = None
	if hole:
		ring = 0.16 if S == "stone" else 0.13
		if hole[0] == "round":
			cut = round_hole(hole[1], hole[2], ring)
		elif hole[0] == "circle":
			_, ccx, ccy, cR = hole

			def cut(ya, yb):
				y = (ya + yb) / 2
				if abs(y - ccy) >= cR:
					return None
				hw = math.sqrt(cR * cR - (y - ccy) ** 2) + 0.02
				return (ccx - hw, ccx + hw)
		elif hole[0] == "round_win":
			cut = round_hole(hole[1], hole[3], ring, bottom=hole[2] - 0.06)
		else:
			cut = rect_hole(hole[1], hole[2], hole[3], 0.06)
	blocks, mortar = layout(-w / 2, w / 2, 0, h, rh, bl, limit=lim, hole=cut, quoin=quoin)
	masonry(fr, blocks, mortar, d, stone_tone if S == "stone" else brick_tone, mortar_m(), gap=gap, bevel=bev,
		tilt=1.2 if S == "stone" else 0.7, jit=0.014 if S == "stone" else 0.006, quoin_m=qm, moss=0 if S == "stone" else 0,
		clip=slope_clip(w, h) if slope else None)


def shack_frame(w, h, d, slope=False, gap=None, door=False):
	"""Bark-log frame of a Shack wall: sill log, corner posts, top plate (or slope log), rope lashings."""
	r = 0.1
	if door:  # the sill log stops at the doorway's stone jambs
		log((-w / 2 + 0.03, 0.11, 0), (gap[0] + 0.02, 0.11, 0), 0.095)
		log((gap[1] - 0.02, 0.11, 0), (w / 2 - 0.03, 0.11, 0), 0.095)
	else:
		log((-w / 2 + 0.03, 0.11, 0), (w / 2 - 0.03, 0.11, 0), 0.095)
	if slope:
		log((w / 2 - r - 0.03, 0.006, 0), (w / 2 - r - 0.03, h - 0.03, 0), r, ends=False)
		lash((w / 2 - r - 0.03, h - 0.25, 0), r)
		log((-w / 2 + 0.08, 0.14, 0), (w / 2 - 0.16, h - 0.12, 0), 0.08)
		return
	for x in (-w / 2 + r + 0.03, w / 2 - r - 0.03):
		log((x, 0.006, 0), (x, h - 0.006, 0), r, ends=False)
		if h > 1.2:
			lash((x, h - 0.25, 0), r)
	log((-w / 2 + 0.035, h - 0.105, 0), (w / 2 - 0.035, h - 0.105, 0), 0.09)
	if h > 1.2:  # inside cross batten (in two parts around an opening)
		spans = [(-w / 2 + 0.2, w / 2 - 0.2)] if not gap else [(-w / 2 + 0.2, gap[0]), (gap[1], w / 2 - 0.2)]
		for a, b in spans:
			if b - a > 0.1:
				blk(((a + b) / 2, h * 0.5 + (0.45 if gap and gap[2] else 0), -d * 0.27), (b - a, 0.14, 0.05), T("wood", "dark"), rz=J(1.5))


def wall(w=2.0, h=2.0, d=0.3):
	wall_body(w, h - (0.1 if S == "stone" else 0), d)
	if S == "shack":
		shack_frame(w, h, d)
	elif S == "stone":
		cap_row(w, h, d)


def cap_row(w, h, d):
	"""Stonehold: a row of flat capstones on top of the wall, overlapping the top course (no shared faces)."""
	for x0, x1 in ((-w / 2 + 0.006, -w / 4 + J(0.1)), (-w / 4 + 0.03, w / 4 + J(0.1)), (w / 4 + 0.13, w / 2 - 0.006)):
		blk(((x0 + x1) / 2, h - 0.062, 0), (x1 - x0 - 0.02, 0.11, d - 0.012), LIME(), bevel=0.02, rz=J(0.4))


def half_wall(w=2.0, h=1.0, d=0.3):
	wall(w, h, d)


def sloped_wall(w=2.0, h=2.0, d=0.3):
	wall_body(w, h, d, slope=True)
	if S == "shack":
		shack_frame(w, h, d, slope=True)
	else:
		coping(w, h, d)


def coping(w, rise, d, fr=None):
	"""Coping stones laid along the slope, cut EXACTLY to the slope line and the piece outline (nothing pokes out)."""
	fr = fr or Frame()
	n = max(2, round(math.hypot(w, rise) / 0.5))
	m = LIME if S == "brick" else stone_tone
	e = 0.02
	k = rise / w
	band = 0.11 * math.hypot(1, k)  # vertical height of a 11 cm band
	for i in range(n):
		xa = -w / 2 + e + (w - 2 * e) * i / n + (0.008 if i else 0)
		xb = -w / 2 + e + (w - 2 * e) * (i + 1) / n - (0.008 if i < n - 1 else 0)
		top = lambda x: max(e + 0.02, min(rise - e, (x + w / 2) * k - e * 1.5))
		pts = [(xa, max(e, top(xa) - band)), (xb, max(e, top(xb) - band)), (xb, top(xb)), (xa, top(xa))]
		if top(xa) - band < e:
			pts = [(xa, e)] + pts[1:]
		slab_poly(fr, pts, 0.0, d - 0.012, m())


def arch_ring(fr, cx, cy, r_in, r_out, n, d, mat, z=0.0, gap=0.012, a0=0.0, a1=math.pi, key_m=None, steps=4):
	"""Wedge stones/bricks around a round top, each cut EXACTLY to the circle (sectors of a ring), so the inner
	edge of the arch is a clean curve and nothing pokes into the opening (F59/F76)."""
	for i in range(n):
		ga = gap / 2 / max(r_in, 0.05)
		sa = a0 + (a1 - a0) * i / n + ga
		sb = a0 + (a1 - a0) * (i + 1) / n - ga
		inner = [(cx + math.cos(sa + (sb - sa) * t / steps) * r_in, cy + math.sin(sa + (sb - sa) * t / steps) * r_in) for t in range(steps + 1)]
		outer = [(cx + math.cos(sb - (sb - sa) * t / steps) * r_out, cy + math.sin(sb - (sb - sa) * t / steps) * r_out) for t in range(steps + 1)]
		m = key_m if (key_m and i == n // 2) else mat()
		slab_poly(fr, inner + outer, z + J(0.002), d, m)


def doorway(w=2.0, h=2.0, d=0.3, ow=1.0, top=1.8):
	r = ow / 2
	spring = top - r
	wall_body(w, h - (0.1 if S == "stone" else 0), d, hole=("round", ow, top))
	if S == "shack":
		shack_frame(w, h, d, gap=(-r - 0.14, r + 0.14, False), door=True)
		# The round opening is framed with bent dark-wood segments and plank jambs (no stones in the Shack).
		arch_ring(Frame(), 0.0, spring, r + 0.004, r + 0.12, 7, d * 0.62, wood_dark, gap=0.01)
		for s_ in (-1, 1):
			blk((s_ * (r + 0.064), spring / 2 + 0.002, 0), (0.116, spring - 0.004, d * 0.62), wood_dark(), bevel=0.01)
			for y in (0.35, spring - 0.25):
				peg((s_ * (r + 0.064), y, d * 0.31 + 0.004))
		return
	ring = 0.16 if S == "stone" else 0.13
	arch_backing(w, h, d, r + 0.015, spring)
	voussoirs(r, spring, ring, d, keystone=True)
	if S == "stone":
		cap_row(w, h, d)


def arch_backing(w, h, d, r, spring, fr=None):
	"""Two dark wall halves cut EXACTLY to the round opening (set 1.5 cm back from the arch faces, so no two
	surfaces share a place: F76), behind the blocks, so the opening always reads round (F57)."""
	fr = fr or Frame()
	m = T("greystone", "dark") if S == "stone" else T("brick", "dark")
	e = 0.006
	for s_ in (-1, 1):
		arc = [(s_ * r * math.cos(math.pi / 2 * k / 10), spring + r * math.sin(math.pi / 2 * k / 10)) for k in range(11)]
		pts = [(s_ * (w / 2 - 0.03), 0.02), (s_ * r, 0.02)] + arc + [(0.0, h - 0.05), (s_ * (w / 2 - 0.03), h - 0.05)]
		if s_ < 0:
			pts = list(reversed(pts))
		slab_poly(fr, pts, 0.0, d * 0.66, m)


def voussoirs(r, spring, ring, d, keystone=True, n=None):
	"""Arch of wedge stones (stone) or bricks (brick) cut exactly to the round top, plus jambs down to the floor."""
	n = n or (9 if S == "stone" else max(11, round(math.pi * (r + ring / 2) / 0.1)))
	arch_ring(Frame(), 0.0, spring, r, r + ring, n, d - 0.05, stone_tone if S == "stone" else brick_tone,
		gap=0.014 if S == "stone" else 0.01, key_m=LIME() if keystone else None)
	for s_ in (-1, 1):
		y = 0.006
		k = 0
		while y < spring - 0.04:
			hh = min(rng.uniform(0.3, 0.45) if S == "stone" else 0.25, spring - y)
			wide = ring + (0.08 if k % 2 else 0)
			m = stone_tone() if S == "stone" else brick_tone()
			blk((s_ * (r + 0.002 + (wide - 0.02) / 2), y + hh / 2 - 0.006, 0), (wide - 0.02, hh - 0.014, d - 0.05), m,
				bevel=0.018 if S == "stone" else 0.004, rz=J(0.3))
			y += hh
			k += 1


def window_wall(w=2.0, h=2.0, d=0.3, ow=1.0, oh=0.8, ob=0.6):
	top = ob + oh
	dd = d - 0.012
	if S == "brick":  # a tall arched window with leaded panes
		wall_body(w, h, d, hole=("round_win", ow, ob, top))
		r = ow / 2
		spring = top - r
		ring = 0.13
		arch_ring(Frame(), 0.0, spring, r, r + ring, 11, d - 0.014, brick_tone, gap=0.01, key_m=LIME())
		for s_ in (-1, 1):
			y = ob
			while y < spring - 0.03:
				hh = min(0.125, spring - y)
				blk((s_ * (r + 0.002 + (ring - 0.012) / 2), y + hh / 2, 0), (ring - 0.012, hh - 0.012, d - 0.014), brick_tone(), bevel=0.004)
				y += hh
		blk((0, ob - 0.05, 0), (ow + 0.36, 0.1, dd), LIME(), bevel=0.015)
		leaded(ow - 0.02, ob, spring, r - 0.01)
		return
	if S == "shack":
		wall_body(w, h, d, hole=("rect", ow, ob, top))
		shack_frame(w, h, d, gap=(-ow / 2 - 0.12, ow / 2 + 0.12, False))
		# Split-log frame, cross bars, and two warm plank shutters swung open, held 1 cm off the wall on hinges.
		log((-ow / 2 - 0.1, ob - 0.04, 0.02), (ow / 2 + 0.1, ob - 0.04, 0.02), 0.06)
		log((-ow / 2 - 0.12, top + 0.05, 0.02), (ow / 2 + 0.12, top + 0.05, 0.02), 0.065)
		for s_ in (-1, 1):
			log((s_ * (ow / 2 + 0.04), ob - 0.07, 0.02), (s_ * (ow / 2 + 0.04), top + 0.08, 0.02), 0.05)
		blk((0, ob + oh / 2, 0), (0.05, oh, 0.05), T("wood", "dark"), bevel=0.008)
		blk((0, ob + oh / 2, 0), (ow, 0.05, 0.05), T("wood", "dark"), bevel=0.008)
		for s_ in (-1, 1):
			sx = s_ * (ow / 2 + 0.24)
			for k in range(2):
				blk((sx + (k - 0.5) * 0.15, ob + oh / 2, 0.0915), (0.145, oh - 0.04 + J(0.02), 0.035), T("wood", rng.choice("ab")), bevel=0.008, rz=J(0.6))
			for yy in (ob + 0.15, top - 0.15):
				strap((sx, yy, 0.115), (0.28, 0.05, 0.012), rivets=2)
				blk((s_ * 0.6, yy, 0.068), (0.06, 0.06, 0.03), T("wood", "dark"), bevel=0.006)  # hinge block
		return
	# Stonehold: heavy timber lintel, stone sill, iron grille, capstones on top like the plain wall.
	wall_body(w, h - 0.1, d, hole=("rect", ow, ob, top))
	cap_row(w, h, d)
	blk((0, top + 0.1, 0), (ow + 0.5, 0.2, d - 0.04), wood_dark(), bevel=0.02, rz=J(0.5))
	for s_ in (-1, 1):
		peg((s_ * (ow / 2 + 0.15), top + 0.1, d / 2 - 0.02), kit.tex_mat("copper", "dark"))
	blk((0, ob - 0.06, 0), (ow + 0.3, 0.12, dd), LIME(), bevel=0.02)
	for x in (-ow / 4, 0.0, ow / 4):
		blk((x, ob + oh / 2, 0), (0.035, oh + 0.04, 0.035), kit.tex_mat("iron"), bevel=0.004)
	for y in (ob + oh * 0.33, ob + oh * 0.66):
		blk((0, y, 0), (ow + 0.04, 0.03, 0.03), kit.tex_mat("iron"), bevel=0.004)
	for s_ in (-1, 1):
		blk((s_ * (ow / 2 + 0.03), ob + oh / 2, 0), (0.06, oh, dd), wood_dark(), bevel=0.01)


def leaded(ow, ob, spring, r):
	"""Leaded glass: pale glass and a diamond lattice of thin dark strips, cut to the round-topped window."""
	glass = kit.mat("water_light", -0.15, rough=0.25)
	blk((0, (ob + spring) / 2, 0), (ow, spring - ob, 0.012), glass, bevel=0)
	prof = [(-ow / 2, spring)] + [(-math.cos(math.pi * i / 10) * r, spring + math.sin(math.pi * i / 10) * r) for i in range(1, 10)] + [(ow / 2, spring)]
	verts = [(x, y, -0.006) for x, y in prof] + [(x, y, 0.006) for x, y in prof]
	n = len(prof)
	faces = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, i + 1, i + 1 + n, i + n) for i in range(n - 1)]
	mesh(verts, faces, glass)
	lead = kit.mat("iron", -0.3)

	def inside(x, y):
		if abs(x) > ow / 2 - 0.015 or y < ob + 0.01:
			return False
		return y <= spring or x * x + (y - spring) ** 2 <= (r - 0.015) ** 2
	for s_ in (-1, 1):
		ang = math.radians(55)
		for k in range(-6, 7):
			x0 = k * 0.22
			run = []
			for i in range(121):
				t = i * 0.015
				x, y = x0 + s_ * t * math.cos(ang), ob + t * math.sin(ang)
				if inside(x, y):
					run.append((x, y))
				if run and (not inside(x, y) or i == 120):
					if len(run) > 2:
						(xa, ya), (xb, yb) = run[0], run[-1]
						L = math.hypot(xb - xa, yb - ya)
						blk(((xa + xb) / 2, (ya + yb) / 2, s_ * 0.004), (0.016, L, 0.03), lead, bevel=0, rz=-s_ * (90 - 55))
					run = []
	for s_ in (-1, 1):
		blk((s_ * (ow / 2 + 0.005), (ob + spring) / 2, 0), (0.03, spring - ob, 0.06), wood_dark(), bevel=0.005)


# ---------------- doors ----------------
def door(w=1.0, h=1.8, d=0.12):
	r = w / 2
	spring = h - r
	m = (lambda: T("wood")) if S == "shack" else (lambda: T("wood", "dark")) if S in ("stone", "copper") else (lambda: T("greenpaint"))
	n = 5
	pw = w / n
	fr = Frame()
	ctop = lambda x: spring + math.sqrt(max(0.0, r * r - min(x * x, r * r)))
	for i in range(n):
		a, b = -r + i * pw + 0.006, -r + (i + 1) * pw - 0.006
		plank_shape(fr, a, b, lambda x: 0.006, lambda x: ctop(x) - 0.006, J(0.003), d * 0.7, m(), k=6)
	# Back battens and a brace.
	for y in (0.3, spring - 0.1):
		blk((0, y, -0.044), (w - 0.1, 0.1, 0.024), wood_dark() if S != "brick" else T("greenpaint", "dark"), bevel=0.008)
	seg = math.hypot(w - 0.2, spring - 0.4)
	blk((0, (spring + 0.2) / 2, -0.041), (0.09, seg, 0.022), wood_dark(), bevel=0.006, rz=math.degrees(math.atan2(w - 0.2, spring - 0.4)))
	# Copper hinges from the hinge side (x = -0.5), and a ring pull.
	hm = kit.tex_mat("iron") if S == "shack" else kit.tex_mat("copper", "b")
	for y in (0.32, spring - 0.08):
		blk((-r + 0.3, y, 0.053), (0.58, 0.07, 0.012), hm, bevel=0.004)
		for x in (-r + 0.08, -r + 0.3, -r + 0.52):
			kit.rivet(G((x, y, 0.051)), hm, r=0.01)
		log((-r + 0.03, y - 0.05, d * 0.3), (-r + 0.03, y + 0.05, d * 0.3), 0.025, hm, seg=6, rings=1, ends=False, bend=0)
	ring_m = kit.tex_mat("copper", "b") if S != "shack" else kit.tex_mat("iron")
	blk((r * 0.62, spring * 0.62, 0.053), (0.07, 0.07, 0.012), ring_m, bevel=0.004)
	kit.ring(0.05, 0.008, G((r * 0.62, spring * 0.62 - 0.06, 0.05)), ring_m, rot=(90, 0, 0), seg=12)
	if S == "copper":  # copper door: three wide copper plates over dark planks, a copper rim on the round top
		for y in (0.58, 0.98):
			blk((0.02, y, 0.053), (w - 0.1, 0.2, 0.012), kit.tex_mat("copper", rng.choice("ab")), bevel=0.006)
			for x in (-0.36, -0.12, 0.12, 0.36):
				for dy in (-0.07, 0.07):
					kit.rivet(G((x + 0.02, y + dy, 0.051)), kit.tex_mat("copper", "dark"), r=0.009)
		arch_ring(Frame(), 0.0, spring, r - 0.07, r - 0.012, 7, 0.012, lambda: kit.tex_mat("copper", "b"), z=0.053, gap=0.004)
	if S == "stone":  # Stonehold's own door: two copper bands with rows of studs across the heavy dark planks
		for y in (0.62, 1.12):
			blk((0.03, y, 0.053), (w - 0.12, 0.08, 0.012), kit.tex_mat("copper", "b"), bevel=0.004)
			for x in (-0.3, -0.1, 0.1, 0.3):
				kit.rivet(G((x + 0.03, y, 0.051)), kit.tex_mat("copper", "dark"), r=0.01)


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


def edge_planes(x0, x1, z0, z1, e=0.006, tri=False, k=1.0):
	"""Half-planes (x, z) keeping a floor inside its outline, `e` inside every edge (Rule 2)."""
	if tri:
		return tri_planes(k, e)
	return [(-1.0, 0.0, -(x0 + e)), (1.0, 0.0, x1 - e), (0.0, -1.0, -(z0 + e)), (0.0, 1.0, z1 - e)]


def tile_piece(rect, planes, y0, y1, m, bevel=0.01, tilt=0.0):
	"""A floor tile/plank: a bevelled box when it fits, else cut EXACTLY to the outline (triangles, edges)."""
	if needs_clip(rect, planes):
		poly = clip_poly(rect, planes)
		if poly and area(poly) > 0.004:
			floor_poly(poly, y0, y1, m)
		return
	(a, za), (b, zb) = rect[0], rect[2]
	blk(((a + b) / 2, (y0 + y1) / 2, (za + zb) / 2), (b - a, y1 - y0, zb - za), m, bevel=bevel, rx=J(tilt), rz=J(tilt))


def deck(x0, x1, z0, z1, y0, t, tri=False, k=1.0, inset=0.006):
	"""The walking surface: planks (shack), flagstones (stone), basket-weave bricks (brick), all cut exactly to
	the square or triangle outline (no stair-stepped edges, nothing past the edge: F77)."""
	pl = edge_planes(x0, x1, z0, z1, inset, tri, k)
	top = y0 + t - 0.005
	if S == "shack":
		zz = z0
		while zz < z1 - 0.03:
			pw = min(rng.uniform(0.18, 0.27), z1 - zz)
			if z1 - (zz + pw) < 0.08:
				pw = z1 - zz
			a, b = zz + 0.007, zz + pw - 0.007
			rect = [(x0, a), (x1, a), (x1, b), (x0, b)]
			poly = clip_poly(rect, pl)
			if poly and area(poly) > 0.01 and (not tri or (a + b) / 2 > -TRI_OUT * k + 0.22):
				floor_poly(poly, y0, top - rng.uniform(0, 0.006), T("wood", rng.choice("ab")))
				xs = [p[0] for p in poly]
				for x in (min(xs) + 0.1, max(xs) - 0.1):
					if in_tri(x, (a + b) / 2, k, 0.05) or not tri:
						peg((x, top - 0.016, (a + b) / 2))
			zz += pw
		return
	# mortar bed under the tiles (inside the outline)
	bed = clip_poly([(x0, z0), (x1, z0), (x1, z1), (x0, z1)], edge_planes(x0, x1, z0, z1, inset + 0.03, tri, k))
	floor_poly(bed, y0, y0 + t * 0.6, mortar_m())
	y0 = y0 + t * 0.3  # tiles sit in the bed
	if S == "stone":
		blocks, _ = layout(x0, x1, z0, z1, (0.38, 0.6), (0.4, 0.7))
		for (a, b, za, zb, r, e) in blocks:
			rect = [(a + 0.015, za + 0.015), (b - 0.015, za + 0.015), (b - 0.015, zb - 0.015), (a + 0.015, zb - 0.015)]
			tile_piece(rect, pl, y0, top - rng.uniform(0, 0.008), stone_tone(), bevel=0.02, tilt=0.4)
		return
	cell = 0.25  # basket weave: squares of two bricks, turning each square
	n = int(round((x1 - x0) / cell))
	m_ = int(round((z1 - z0) / cell))
	for i in range(n):
		for j in range(m_):
			cx, cz = x0 + cell * (i + 0.5), z0 + cell * (j + 0.5)
			for hh in (-1, 1):
				if (i + j) % 2:
					c, sz = (cx + hh * cell / 4, cz), (cell / 2 - 0.016, cell - 0.016)
				else:
					c, sz = (cx, cz + hh * cell / 4), (cell - 0.016, cell / 2 - 0.016)
				rect = [(c[0] - sz[0] / 2, c[1] - sz[1] / 2), (c[0] + sz[0] / 2, c[1] - sz[1] / 2), (c[0] + sz[0] / 2, c[1] + sz[1] / 2), (c[0] - sz[0] / 2, c[1] + sz[1] / 2)]
				tile_piece(rect, pl, y0, top - rng.uniform(0, 0.004), brick_tone(), bevel=0.0, tilt=0.3)


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
			log((x, y0 + r + 0.014, a + 0.02), (x, y0 + r + 0.014, b - 0.02), r)
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
			log((-w / 2 + 0.035, js + 0.014, z), (w / 2 - 0.035, js + 0.014, z), js)
	deck(-w / 2, w / 2, -dd / 2, dd / 2, js * 2 - 0.01, t - js * 2 + 0.01)


def floor_triangle(t=0.25):
	js = 0.07 if S == "shack" else 0.06
	joists((-0.35, 0.35), 0, 0, 0, js, tri=True)
	if S == "shack":
		for (mx, mz, yaw) in tri_edges():
			fr = Frame(mx, mz, yaw)
			a, b = fr.p(-0.7, js + 0.014, -0.12), fr.p(0.7, js + 0.014, -0.12)
			log(a, b, js)
	deck(-1, 1, -TRI_OUT, TRI_IN, js * 2 - 0.01, t - js * 2 + 0.01, tri=True)


def shack_legs(corners, h_frame, pl=None):
	"""Tall log legs on flat stone footings (cut to the piece outline `pl`), with diagonal braces."""
	for (x, z) in corners:
		a = math.radians(J(15))
		sq = [(x + math.cos(a + math.pi / 4 + k * math.pi / 2) * 0.24, z + math.sin(a + math.pi / 4 + k * math.pi / 2) * 0.24) for k in range(4)]
		poly = clip_poly(sq, pl) if pl else sq
		floor_poly(poly, 0.006, 0.1, T("greystone"))
		log((x, 0.1, z), (x + J(0.01), h_frame + 0.02, z + J(0.01)), 0.11, ends=False)
	return corners


def foundation(w=2.0, h=1.0, dd=2.0):
	if S == "shack":
		cx, cz = w / 2 - 0.2, dd / 2 - 0.2
		legs = shack_legs([(-cx, -cz), (cx, -cz), (cx, cz), (-cx, cz)], h - 0.25, edge_planes(-w / 2, w / 2, -dd / 2, dd / 2, 0.006))
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
		L = (dd - 2 * t - 0.03) if yaw in (90, -90) else w
		foundation_side(fr, L, h - 0.13, t, full=yaw in (0, 180))
	cap_top(w, h, dd)


def foundation_side(fr, L, h, t, full=True):
	if S == "stone":
		blocks, mortar = layout(-L / 2, L / 2, 0.16, h, (0.28, 0.4), (0.4, 0.7), quoin=(0.5, 0.3) if full else None)
		masonry(fr, blocks, mortar, t, stone_tone, mortar_m(), bevel=0.02, moss=0, quoin_m=None)
		fr.box((0, 0.088, 0), (L - (0.012 if full else 0.35), 0.164, t - 0.012), T("greystone", "dark"), bevel=0.02)  # plinth course
		return
	# Hearthbrick: brick piers with a little round arch between them, dark crawl space behind.
	ow = min(1.1, L - 0.5)
	cut = round_hole(ow, 0.72, 0.12) if ow > 0.5 else None
	blocks, mortar = layout(-L / 2, L / 2, 0, h, 0.125, 0.25, hole=cut, quoin=(0.3, 0.18) if full else None)
	masonry(fr, blocks, mortar, t, brick_tone, mortar_m(), gap=0.016, bevel=0.0, tilt=0.4, jit=0.003, quoin_m=None)
	if cut:
		r = ow / 2
		spring = 0.72 - r
		fr.box((0, 0.36, -t * 0.3), (ow + 0.02, 0.72, 0.03), kit.mat("charcoal", -0.6), bevel=0)  # dark crawl space
		arch_ring(fr, 0.0, spring, r, r + 0.12, 11, t - 0.014, brick_tone, gap=0.01)
		for s_ in (-1, 1):
			fr.box((s_ * (r + 0.062), spring / 2 + 0.003, 0), (0.116, spring - 0.006, t - 0.014), brick_tone(), bevel=0)


def ring_band(outer, inner, n_of, y0, y1, mat):
	"""A border of bricks/stones between two outlines (lists of corners): one trapezoid strip per edge, split into
	pieces, mitred exactly at the corners. Used for clean foundation tops (F80)."""
	k = len(outer)
	for i in range(k):
		A, B, A2, B2 = outer[i], outer[(i + 1) % k], inner[i], inner[(i + 1) % k]
		L = math.hypot(B[0] - A[0], B[1] - A[1])
		n = n_of(L)
		for j in range(n):
			f0, f1 = j / n, (j + 1) / n
			q = [(A[0] + (B[0] - A[0]) * f0, A[1] + (B[1] - A[1]) * f0), (A[0] + (B[0] - A[0]) * f1, A[1] + (B[1] - A[1]) * f1),
				(A2[0] + (B2[0] - A2[0]) * f1, A2[1] + (B2[1] - A2[1]) * f1), (A2[0] + (B2[0] - A2[0]) * f0, A2[1] + (B2[1] - A2[1]) * f0)]
			cx, cz = sum(p[0] for p in q) / 4, sum(p[1] for p in q) / 4
			q = [(cx + (p[0] - cx) * 0.97, cz + (p[1] - cz) * 0.97) for p in q]  # small mortar gaps
			floor_poly(q, y0, y1 - rng.uniform(0, 0.004), mat())


def cap_top(w, h, dd, tri=False):
	"""Top of a stone/brick foundation: the floor surface inside a clean border course (no cut-up bricks, F80),
	plus a copper band (stone)."""
	e = 0.006
	band = 0.25
	if tri:
		sc = lambda ins: [(x * (TRI_IN - ins) / TRI_IN, z * (TRI_IN - ins) / TRI_IN) for x, z in tri_pts()]
		outer, inner = sc(e), sc(band)
	else:
		outer = [(-w / 2 + e, dd / 2 - e), (w / 2 - e, dd / 2 - e), (w / 2 - e, -dd / 2 + e), (-w / 2 + e, -dd / 2 + e)]
		inner = [(-w / 2 + band, dd / 2 - band), (w / 2 - band, dd / 2 - band), (w / 2 - band, -dd / 2 + band), (-w / 2 + band, -dd / 2 + band)]
	if S == "stone":
		ring_band(outer, inner, lambda L: max(1, round(L / 0.55)), h - 0.13, h - 0.005, stone_tone)
	else:
		ring_band(outer, inner, lambda L: max(2, round(L / 0.13)), h - 0.13, h - 0.005, brick_tone)
	if tri:
		k_in = (TRI_IN - band + 0.01) / TRI_IN
		deck(-k_in, k_in, -TRI_OUT * k_in, TRI_IN * k_in, h - 0.12, 0.12, tri=True, k=k_in, inset=0.0)
	else:
		deck(-w / 2 + band - 0.01, w / 2 - band + 0.01, -dd / 2 + band - 0.01, dd / 2 - band + 0.01, h - 0.12, 0.12, inset=0.0)
	if S == "stone" and not tri:
		for (ox, oz, yaw, L) in ((0, dd / 2, 0, w), (0, -dd / 2, 180, w), (w / 2, 0, 90, dd), (-w / 2, 0, -90, dd)):
			fr = Frame(ox, oz, yaw)
			fr.box((0, h - 0.175, -0.017), (L - 0.06, 0.08, 0.03), kit.tex_mat("copper", "b"), bevel=0.004)
			for x in (-L / 2 + 0.2, -L / 6, L / 6, L / 2 - 0.2):
				peg(fr.p(x, h - 0.175, -0.024), kit.tex_mat("copper", "dark"))


def foundation_triangle(h=1.0):
	if S == "shack":
		pts = [(x * 0.66, z * 0.66) for x, z in tri_pts()]
		shack_legs(pts, h - 0.25, tri_planes(1.0, 0.006))
		yb = h - 0.21
		for i in range(3):
			a, b = pts[i], pts[(i + 1) % 3]
			log((a[0], yb, a[1]), (b[0], yb, b[1]), 0.11)
			lash((a[0], yb - 0.15, a[1]), 0.12)
		log((0, yb - 0.01, -TRI_OUT * 0.66), (0, yb - 0.01, TRI_IN * 0.85), 0.09)
		for i in range(3):
			a, b = pts[i], pts[(i + 1) % 3]
			log((a[0], 0.15, a[1]), (a[0] + (b[0] - a[0]) * 0.6, yb - 0.06, a[1] + (b[1] - a[1]) * 0.6), 0.05)
		deck(-1, 1, -TRI_OUT, TRI_IN, h - 0.1, 0.1, tri=True)
		return
	t = 0.3
	for (mx, mz, yaw) in tri_edges():
		# the side sits inside the edge; corners get piers
		fr = Frame(mx - math.sin(math.radians(yaw)) * (t / 2 + 0.006), mz - math.cos(math.radians(yaw)) * (t / 2 + 0.006), yaw)
		foundation_side(fr, 2 - t * 2.4, h - 0.13, t, full=False)
	pl = tri_planes(1.0, 0.006)
	for (x, z) in tri_pts():
		# corner pier: courses cut exactly to the triangle's corner
		cx, cz = x * 0.72, z * 0.72
		y = 0.006
		k = 0
		while y < h - 0.15:
			hh = min(0.3 if S == "stone" else 0.25, h - 0.13 - y)
			s2 = 0.3 + (0.04 if k % 2 else 0)
			sq = [(cx - s2, cz - s2), (cx + s2, cz - s2), (cx + s2, cz + s2), (cx - s2, cz + s2)]
			poly = clip_poly(sq, pl)
			if poly:
				floor_poly(poly, y, y + hh - 0.014, stone_tone() if S == "stone" else brick_tone())
			y += hh
			k += 1
	cap_top(2, h, 2, tri=True)
	mesh_tri_slab(h - 0.15, h - 0.12, 1.0, mortar_m(), inset=0.03)


# ---------------- stairs, supports, railings ----------------
def stairs(w=2.0, h=2.0, dd=2.0, n=5):
	dz = dd / n
	if S == "shack":
		for s_ in (-1, 1):
			x = s_ * (w / 2 - 0.16)
			log((x, 0.12, dd / 2 - 0.12), (x, h - 0.14, -dd / 2 + 0.14), 0.1, ends=False)
			log((x, 0.095, -dd / 2 + 0.16), (x, h - 0.12, -dd / 2 + 0.16), 0.1, ends=False)  # back leg: holds the top up
			blk((x, 0.05, -dd / 2 + 0.16), (0.26, 0.09, 0.26), T("greystone"), bevel=0.02, ry=J(8))
			blk((x, 0.05, dd / 2 - 0.16), (0.26, 0.09, 0.26), T("greystone"), bevel=0.02, ry=J(8))
		for i in range(n):
			y = (i + 1) * h / n
			z = dd / 2 - (i + 0.5) * dz
			blk((J(0.01), y - 0.05, z), (w - 0.06, 0.08, dz - 0.012), T("wood"), bevel=0.01, rx=J(0.4), rz=J(0.4))
			for x in (-w / 2 + 0.16, w / 2 - 0.16):
				peg((x, y - 0.018, z))
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
		# the tread reaches 2.4 cm back under the next step, so the steps hold together
		ext = 0.024 if i < n - 1 else 0.0
		blk((0, y1 - 0.047, z - 0.003 - ext / 2), (w - 0.012, 0.08, dz - 0.006 + ext), brick_tone() if S == "brick" else stone_tone(), bevel=0.02, rx=J(0.3))
		if S == "stone":
			blk((0, y1 - 0.03, z + dz / 2 - 0.018), (w - 0.1, 0.05, 0.02), kit.tex_mat("copper", "b"), bevel=0.004)


def pillar(w=0.4, h=2.0):
	if S == "shack":
		blk((0, 0.056, 0), (w - 0.03, 0.1, w - 0.04), T("greystone"), bevel=0.025)
		log((0, 0.08, 0), (J(0.01), h - 0.06, J(0.01)), 0.16)
		blk((0, h - 0.04, 0), (w, 0.08, w * 0.7), T("wood", "dark"), bevel=0.012, ry=J(4))
		lash((0, h - 0.3, 0), 0.16)
		lash((0, 0.35, 0), 0.16)
		return
	cap = (lambda: stone_tone()) if S == "stone" else (lambda: LIME())
	blk((0, 0.116, 0), (w - 0.014, 0.22, w - 0.014), cap(), bevel=0.025)
	blk((0, h - 0.106, 0), (w - 0.014, 0.2, w - 0.014), cap(), bevel=0.025)
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
		y = 0.23
		k = 0
		while y < h - 0.33:
			for j in range(8):
				a = 2 * math.pi * (j + 0.5 * (k % 2)) / 8
				blk((math.cos(a) * w * 0.33, y + 0.0625, math.sin(a) * w * 0.33), (0.13, 0.11, 0.1), brick_tone(), bevel=0, ry=-math.degrees(a) + 90)
			y += 0.125
			k += 1


def beam(w=2.0, s=0.3):
	if S == "shack":
		log((-w / 2 + 0.03, s / 2, 0), (w / 2 - 0.03, s / 2, 0), s / 2 - 0.035)
		for x in (-w / 2 + 0.25, w / 2 - 0.25):
			lash((x, s / 2, 0), s / 2 - 0.035, axis="x")
		return
	blk((0, s / 2, 0), (w - 0.02, s - 0.02, s - 0.02), wood_dark(), bevel=0.03, rz=J(0.5))
	for s_ in (-1, 1):
		blk((s_ * (w / 2 - 0.051), s / 2, 0), (0.09, s - 0.012, s - 0.012), kit.tex_mat("copper", "b"), bevel=0.008)
		for dy in (-0.07, 0.07):
			peg((s_ * (w / 2 - 0.051), s / 2 + dy, s / 2 - 0.022), kit.tex_mat("copper", "dark"))
	if S == "brick":
		for x in (-w / 4, 0.0, w / 4):
			for dy in (-0.08, 0.08):
				peg((x, s / 2 + dy, s / 2 - 0.022), kit.tex_mat("copper", "dark"))


def railing(w=2.0, h=1.0, d=0.15):
	if S == "shack":
		for x in (-w / 2 + 0.1, 0.0, w / 2 - 0.1):
			log((x, 0.006, 0), (x, h - 0.006, 0), 0.048, ends=False)
		log((-w / 2 + 0.03, h - 0.08, 0), (w / 2 - 0.03, h - 0.08, 0.0), 0.055)
		log((-w / 2 + 0.05, h * 0.45, 0), (w / 2 - 0.05, h * 0.45, 0), 0.045)
		for s_ in (-1, 1):
			log((s_ * (w / 2 - 0.1), 0.08, 0), (s_ * 0.08, h * 0.45 - 0.04, 0), 0.035)
		for x in (-w / 2 + 0.1, 0.0, w / 2 - 0.1):
			lash((x, h - 0.08, 0), 0.048)
		return
	if S == "stone":  # balustrade: base rail, turned balusters, top rail, square end posts
		blk((0, 0.076, 0), (w - 0.05, 0.14, d - 0.02), stone_tone(), bevel=0.015)
		blk((0, h - 0.066, 0), (w - 0.05, 0.12, d - 0.02), LIME(), bevel=0.015)
		for s_ in (-1, 1):
			blk((s_ * (w / 2 - 0.086), h / 2, 0), (0.16, h - 0.1, d - 0.012), stone_tone(), bevel=0.015)
		n = 7
		for i in range(n):
			x = -w / 2 + 0.25 + i * (w - 0.5) / (n - 1)
			kit.cone(0.035, 0.06, 0.28, G((x, 0.29, 0)), T("greystone", "c"), verts=8, bevel=0)
			kit.cone(0.06, 0.035, 0.28, G((x, 0.57, 0)), T("greystone", "c"), verts=8, bevel=0)
			kit.cylinder(0.04, 0.24, G((x, 0.82, 0)), T("greystone", "c"), verts=8, bevel=0)
		blk((0, h - 0.135, d / 2 - 0.012), (w - 0.2, 0.03, 0.01), kit.tex_mat("copper", "b"), bevel=0.003)
		return
	# Hearthbrick: brick base, small brick arches, limestone top rail.
	blocks, mortar = layout(-w / 2, w / 2, 0, 0.25, 0.125, 0.25)
	masonry(Frame(), blocks, mortar, d, brick_tone, mortar_m(), gap=0.016, bevel=0.0, tilt=0.5, jit=0.004)
	for x in (-w / 2 + 0.09, -0.33, 0.33, w / 2 - 0.09):
		blocks, mortar = layout(x - 0.09, x + 0.09, 0.235, h - 0.1, 0.125, 0.18)
		masonry(Frame(), blocks, mortar, d, brick_tone, mortar_m(), gap=0.016, bevel=0.0, tilt=0.5, jit=0.004)
	for (a, b) in ((-w / 2 + 0.18, -0.42), (-0.24, 0.24), (0.42, w / 2 - 0.18)):
		cx, r = (a + b) / 2, (b - a) / 2
		spring = h - 0.1 - r - 0.09
		arch_ring(Frame(), cx, spring, r, r + 0.08, 7, d - 0.014, brick_tone, gap=0.008)
		blk((cx, h - 0.1 - 0.035, 0), (b - a, 0.07, d - 0.02), brick_tone(), bevel=0)
	blk((0, h - 0.056, 0), (w - 0.012, 0.1, d - 0.012), LIME(), bevel=0.012)


# ---------------- roofs: thin panels, open underneath (Rule 4) ----------------
# Built in layers from below: rafters (seen from inside), battens / underlay, then shingles (Shack) or curved
# terracotta tiles (Hearthbrick). Everything stays inside the box of the piece, so each 2 m piece is a little
# flatter than its nominal pitch and the next piece up overlaps it like a big course.
E_IN = 0.007


class Slope:
	"""One roof slope. axis 'z': runs along z (u = z, v = x); 'x': runs along x (u = x, v = z).
	ulo/uhi = the piece edges on the low/high side; the panel rises `rise` in the box; top_v = its vertical
	thickness budget. Points: P(u, v, h) with h = height above the underside line (vertical)."""
	def __init__(self, axis, ulo, uhi, rise, top_v, vlo=-1.0, vhi=1.0, y0=0.0):
		self.axis, self.ulo, self.uhi, self.vlo, self.vhi = axis, ulo, uhi, vlo, vhi
		self.sg = 1 if uhi > ulo else -1
		self.run = abs(uhi - ulo)
		self.y0 = y0 + E_IN
		self.k = (rise - top_v - 2 * E_IN) / self.run
		self.ang = math.atan(self.k)

	def d(self, u):
		return self.sg * (u - self.ulo)

	def u(self, d):
		return self.ulo + self.sg * d

	def P(self, u, v, h):
		y = self.y0 + self.k * self.d(u) + h
		return (v, y, u) if self.axis == "z" else (u, y, v)

	def planes(self, extra=(), e=E_IN):
		"""(u, v) half-planes a*u + b*v <= c: inside the piece, plus extra cuts (hips, valleys)."""
		lo, hi = min(self.ulo, self.uhi), max(self.ulo, self.uhi)
		return [(-1.0, 0.0, -(lo + e)), (1.0, 0.0, hi - e), (0.0, -1.0, -(self.vlo + e)), (0.0, 1.0, self.vhi - e)] + list(extra)

	def slab(self, poly, hb, ht, m):
		"""A flat board/shingle with outline `poly` [(u, v)...] seen from above, from height hb(u) to ht(u)."""
		n = len(poly)
		vb = [self.P(u, v, hb(u)) for u, v in poly]
		vt = [self.P(u, v, ht(u)) for u, v in poly]
		f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
		return mesh(vb + vt, f, m)

	def strip(self, d0, d1, v0, v1, pl, hb, ht, m, min_area=0.004):
		"""A rectangle (d along the slope, v across), cut exactly by the planes `pl`."""
		rect = [(self.u(d0), v0), (self.u(d1), v0), (self.u(d1), v1), (self.u(d0), v1)]
		poly = clip_poly(rect, pl)
		if poly and area(poly) > min_area:
			self.slab(poly, hb, ht, m)
			return poly
		return None

	def d_range(self, v, pl, half=0.0):
		"""The part of the line at v (and v +- half) inside the planes, as (d0, d1) or None."""
		ds = [i * 0.01 for i in range(int(self.run * 100) + 1)]
		ok = [d for d in ds if all(a * self.u(d) + b * vv <= c for (a, b, c) in pl for vv in (v - half, v + half))]
		return (ok[0], ok[-1]) if len(ok) > 1 else None


def half_tube(a, b, r0, r1, side, m, th=0.014, k=7):
	"""A curved terracotta tile: half a tube from a to b (Godot points), radius r0 -> r1, opening downward."""
	a, b, side = Vector(a), Vector(b), Vector(side).normalized()
	ax = (b - a).normalized()
	up = ax.cross(side)
	if up.y < 0:
		up = -up
	side = up.cross(ax).normalized()
	verts = []
	for (c, r) in ((a, r0), (b, r1)):
		for rr in (r, r - th):
			for i in range(k + 1):
				t = math.pi * i / k
				verts.append(tuple(c + side * math.cos(t) * rr + up * math.sin(t) * rr))
	n = k + 1
	o_a, i_a, o_b, i_b = 0, n, 2 * n, 3 * n
	faces = []
	for i in range(k):
		faces.append((o_a + i, o_a + i + 1, o_b + i + 1, o_b + i))
		faces.append((i_a + i, i_b + i, i_b + i + 1, i_a + i + 1))
		faces.append((o_a + i, i_a + i, i_a + i + 1, o_a + i + 1))
		faces.append((o_b + i, o_b + i + 1, i_b + i + 1, i_b + i))
	faces.append((o_a, o_b, i_b, i_a))
	faces.append((o_a + k, i_a + k, i_b + k, o_b + k))
	return mesh(verts, faces, m)


RAFT_R = 0.04          # rafters: logs (Shack) / dark timbers (Hearthbrick), h 0 .. 0.08
BAT_H = (0.08, 0.105)  # battens across the rafters (Shack) / underlay boards (Hearthbrick)
TOP_V = {"shack": 0.17, "brick": 0.2}


def roof_panel(sl, extra=()):
	"""Rafters + battens/underlay + shingles/tiles for one slope, all cut exactly to the planes."""
	pl = sl.planes(extra)
	for v in (-0.72, 0.0, 0.72):  # rafters, seen from below
		rg = sl.d_range(v, pl, half=RAFT_R)
		if not rg or rg[1] - rg[0] < 0.25:
			continue
		d0, d1 = rg[0] + RAFT_R * 1.3, rg[1] - RAFT_R
		pa, pb = sl.P(sl.u(d0), v, RAFT_R), sl.P(sl.u(d1), v, RAFT_R)
		if S == "shack":
			log(pa, pb, RAFT_R, ends=False)
		else:
			log(pa, pb, RAFT_R, wood_dark(), seg=6, rings=1, ends=False)
	if S == "shack":
		v = sl.vlo
		while v < sl.vhi - 0.05:  # sarking boards along the slope, on the rafters
			bw = min(0.24, sl.vhi - v)
			sl.strip(0.0, sl.run, v, v + bw, pl, lambda u: BAT_H[0] - 0.012, lambda u: BAT_H[1] - 0.006, T("wood", rng.choice("ab")))
			v += bw
		E, OV, TH = 0.3, 0.14, 0.022
		LF = 0.012 * (E + OV) / E + 0.004
		i = 0
		while i * E < sl.run:
			pl = sl.planes([(a, b, c - 0.004 * (i % 2)) for (a, b, c) in extra], e=E_IN + 0.004 * (i % 2))
			d0, d1 = i * E, min(i * E + E + OV, sl.run)
			hb = (lambda a_: (lambda u: BAT_H[1] - 0.004 + LF * (1 - (sl.d(u) - a_) / (E + OV))))(d0)
			ht = (lambda f: (lambda u: f(u) + TH))(hb)
			v = sl.vlo + (rng.uniform(-0.2, 0.0) if i % 2 else 0.0)
			while v < sl.vhi - 0.02:
				sw = rng.uniform(0.2, 0.34)
				if sl.vhi - (v + sw) < 0.1:
					sw = sl.vhi - v
				sl.strip(d0, d1, v + 0.006, v + sw - 0.006, pl, hb, ht, T("shingle", "a"), min_area=0.003)
				v += sw
			i += 1
		return
	# Hearthbrick: dark underlay boards, then columns of curved tiles in overlapping rows
	sl.strip(0.0, sl.run, sl.vlo, sl.vhi, pl, lambda u: BAT_H[0] - 0.01, lambda u: BAT_H[1], T("rooftile", "dark"))
	R0, R1, E, OV = 0.08, 0.068, 0.3, 0.07
	pitch = 0.18
	n = int((sl.vhi - sl.vlo - 2 * E_IN) / pitch)
	v_first = (sl.vlo + sl.vhi) / 2 - (n - 1) * pitch / 2
	sn = math.sin(sl.ang)
	side = (1, 0, 0) if sl.axis == "z" else (0, 0, 1)
	for j in range(n):
		v = v_first + j * pitch
		rg = sl.d_range(v, pl, half=R0 + 0.004)
		if not rg:
			continue
		lo, hi = rg[0] + R0 * sn + 0.004, rg[1] - 0.004
		i = 0
		while i * E < hi:
			d0, d1 = max(lo, i * E), min(hi, i * E + E + OV)
			if d1 - d0 > 0.08:
				f0, f1 = (d0 - i * E) / (E + OV), (d1 - i * E) / (E + OV)
				h0, h1 = BAT_H[1] - 0.004 + 0.012 * (1 - f0), BAT_H[1] - 0.004 + 0.012 * (1 - f1)
				half_tube(sl.P(sl.u(d0), v, h0), sl.P(sl.u(d1), v, h1), R0 + (R1 - R0) * f0, R0 + (R1 - R0) * f1, side,
					T("rooftile", rng.choice("abc")))
			i += 1


def fascia(sl):
	"""A dark board across the low edge, on the rafter ends."""
	u = sl.ulo + sl.sg * (E_IN + 0.022)
	a, b = sl.P(u, sl.vlo + E_IN + 0.008, 0.0), sl.P(u, sl.vhi - E_IN - 0.008, 0.0)
	c = tuple((a[i] + b[i]) / 2 for i in range(3))
	size = (abs(b[0] - a[0]) or 0.04, 0.11, abs(b[2] - a[2]) or 0.04)
	blk((c[0], c[1] + 0.055, c[2]), size, kit.tex_mat("wood", "dark"), bevel=0.008)


def roof(w=2.0, rise=1.0, dd=2.0):
	sl = Slope("z", dd / 2, -dd / 2, rise, TOP_V[S])
	roof_panel(sl)
	fascia(sl)


def ridge_cap(w, rise):
	"""Ridge cover along x at the top: a lashed log (Shack) or a row of big curved ridge tiles (Hearthbrick)."""
	if S == "shack":
		r = 0.07
		y = rise - E_IN - r - 0.03
		log((-w / 2 + 0.03, y, 0), (w / 2 - 0.03, y, 0), r)
		for x in (-0.6, 0.0, 0.6):
			lash((x, y, 0), r, axis="x", n=2)
		return
	r = 0.095
	y = rise - E_IN - r - 0.002
	blk((0, y - 0.03, 0), (w - 0.02, 0.06, 0.15), T("rooftile", "dark"), bevel=0)  # mortar bed
	n = 6
	for i in range(n):
		x0 = -w / 2 + E_IN + (w - 2 * E_IN) * i / n
		x1 = min(w / 2 - E_IN, -w / 2 + E_IN + (w - 2 * E_IN) * (i + 1) / n + 0.04)
		half_tube((x0, y, 0), (x1, y - 0.004, 0), r, r - 0.006, (0, 0, 1), T("rooftile", rng.choice("ab")))


def ridge(w=2.0, rise=0.5, dd=2.0):
	capd = 0.07 if S == "shack" else 0.095
	for lo in (dd / 2, -dd / 2):
		sl = Slope("z", lo, 0.0, rise - capd, TOP_V[S] - 0.03)
		roof_panel(sl)
		fascia(sl)
	ridge_cap(w, rise)


def roof_corner(w=2.0, rise=1.0, dd=2.0, inner=False):
	"""Outer hip (high at the (-x,-z) corner) or inner valley (high along the -x and -z edges). Both slopes are cut
	EXACTLY to the diagonal, 0.5 cm short of it, so nothing crosses and no holes are left (F80)."""
	g = 0.005
	cut = [(-1.0, 1.0, -g)] if not inner else [(1.0, -1.0, -g)]   # outer: v - u <= -g ; inner: u - v <= -g
	slz = Slope("z", dd / 2, -dd / 2, rise, TOP_V[S])
	slx = Slope("x", w / 2, -w / 2, rise, TOP_V[S])
	roof_panel(slz, cut)
	roof_panel(slx, cut)
	if not inner:
		fascia(slz)
		fascia(slx)

	def diag(f, h):
		u = (dd / 2 - E_IN - 0.03) - f * (dd - 2 * E_IN - 0.06)
		return slz.P(u, u, h)
	top_h = BAT_H[1] + (0.04 if S == "shack" else 0.035)
	log(diag(0.03, RAFT_R), diag(0.96, RAFT_R), RAFT_R + 0.01, None if S == "shack" else wood_dark(), ends=False)  # hip/valley rafter
	if inner:
		# sunken valley gutter on the battens/underlay; shingles/tiles stop at it (no log in the valley)
		for sl in (slz, slx):
			pl = sl.planes([(-1.0, 1.0, 0.16), (1.0, -1.0, 0.012)], e=E_IN + 0.008)
			sl.strip(0.0, sl.run, sl.vlo, sl.vhi, pl, lambda u: BAT_H[1] - 0.006, lambda u: BAT_H[1] + 0.006,
				kit.tex_mat("copper", "b") if S == "brick" else kit.tex_mat("wood", "dark"))
		return
	f_hi = 0.93
	if S == "shack":
		r = 0.065
		a, b = diag(0.05, top_h + r * 0.5), diag(f_hi, top_h + r * 0.5)
		while b[1] + r > rise - E_IN:
			f_hi -= 0.02
			b = diag(f_hi, top_h + r * 0.5)
		log(a, b, r)
		return
	r = 0.085
	n = 6
	log(diag(0.06, top_h), diag(f_hi - 0.02, top_h), 0.062, T("rooftile", "dark"), seg=6, rings=1, ends=False, bend=0)
	for i in range(n):
		fa, fb = 0.06 + (f_hi - 0.06) * i / n, min(f_hi, 0.06 + (f_hi - 0.06) * (i + 1) / n + 0.03)
		a, b = diag(fa, top_h), diag(fb, top_h)
		if b[1] + r > rise - E_IN:
			break
		half_tube(a, b, r + 0.006, r, (1, 0, -1), T("rooftile", rng.choice("ab")))


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
				m = T("wood")
				slab_poly(fr, [(xl(ya) + 0.05, ya), (xr, ya), (xr, yb), (xl(yb) + 0.05, yb)], J(0.01), d * 0.33, m)
			y += hh
		log((-w / 2 + 0.03, 0.11, 0), (w / 2 - 0.03, 0.11, 0), 0.085)
		log((w / 2 - 0.11, 0.03, 0), (w / 2 - 0.11, rise - 0.03, 0), 0.09)
		log((-w / 2 + 0.06, 0.12, 0.0), (w / 2 - 0.13, rise - 0.07, 0.0), 0.07)
		return
	wall_body(w, rise, d, slope=True, hole=("circle", 0.45, 0.62, 0.28) if rise >= 1.5 else None)
	coping(w, rise, d)
	if rise >= 1.5:  # a round vent with a brick ring
		c = (0.45, 0.62, 0)
		kit.cylinder(0.175, d - 0.04, G(c), kit.mat("charcoal", -0.6), rot=(90, 0, 0), verts=16, bevel=0)
		arch_ring(Frame(), c[0], c[1], 0.17, 0.28, 12, d - 0.014, brick_tone, gap=0.01, a1=2 * math.pi)


# ---------------- Stonehold flat roof ----------------
def flat_roof(w=2.0, t=0.3, dd=2.0):
	joists((-0.55, 0.55), -dd / 2 + 0.03, dd / 2 - 0.03, 0, 0.07)
	deck(-w / 2, w / 2, -dd / 2, dd / 2, 0.14, t - 0.14)
	# drip edge: a slightly lower outer course on the front and back
	for z in (-dd / 2 + 0.05, dd / 2 - 0.05):
		blk((0, t - 0.06, z), (w - 0.04, 0.1, 0.1), T("greystone", "dark"), bevel=0.015, rx=J(0.6))


def battlement(w=2.0, h=0.9, d=0.4):
	blocks, mortar = layout(-w / 2, w / 2, 0, 0.45, (0.2, 0.25), (0.4, 0.7))
	masonry(Frame(), blocks, mortar, d, stone_tone, mortar_m(), bevel=0.02, moss=0)
	blk((0, 0.475, 0), (w - 0.012, 0.05, d - 0.012), kit.tex_mat("copper", "b"), bevel=0.004)
	for x in (-w / 2 + 0.15, -0.3, 0.3, w / 2 - 0.15):
		peg((x, 0.475, d / 2 - 0.022), kit.tex_mat("copper", "dark"))
	for cx in (-0.5, 0.5):
		blocks, mortar = layout(cx - 0.3, cx + 0.3, 0.5, h - 0.06, (0.16, 0.2), (0.25, 0.4))
		masonry(Frame(), blocks, mortar, d - 0.04, stone_tone, mortar_m(), bevel=0.02)
		blk((cx, h - 0.038, 0), (0.64, 0.06, d - 0.012), LIME(), bevel=0.015, rz=J(0.5))


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
	blk((0, h - 0.05, 0), (w, 0.1, w), LIME(), bevel=0.02)
	kit.cone(0.16, 0.05, 0.08, G((0, h + 0.02, 0)), LIME(), verts=8, bevel=0) if False else None


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
	"cut_stone": {**COMMON, **FLAT},
	"clay_brick": {**COMMON, **SLOPED},
	"copper_ingot": {"door": door},
}


# The piece boxes from src/build/pieces.gd (w, h, d); triangles: side 2 m, centroid origin.
SIZE = {
	"foundation": (2, 1, 2), "foundation_half": (2, 1, 1), "foundation_steps": (2, 1, 2), "floor": (2, 0.25, 2),
	"ceiling_panel": (2, 0.25, 2), "wall": (2, 2, 0.3), "half_wall": (2, 1, 0.3), "doorway": (2, 2, 0.3),
	"window_wall": (2, 2, 0.3), "sloped_wall": (2, 2, 0.3), "gable_26": (2, 1, 0.3), "gable_45": (2, 2, 0.3),
	"flat_roof": (2, 0.3, 2), "battlement": (2, 0.9, 0.4), "battlement_corner": (0.6, 1.3, 0.6), "door": (1.56, 1.48, 0.12),
	"roof_26": (2, 1, 2), "roof_45": (2, 2, 2), "roof_26_ridge": (2, 0.5, 2), "roof_45_ridge": (2, 1, 2),
	"roof_26_outer": (2, 1, 2), "roof_26_inner": (2, 1, 2), "roof_45_outer": (2, 2, 2), "roof_45_inner": (2, 2, 2),
	"beam": (2, 0.3, 0.3), "beam_half": (1, 0.3, 0.3), "pillar": (0.4, 2, 0.4), "railing": (2, 1, 0.15), "stairs": (2, 2, 2),
	"foundation_triangle": ("tri", 1.0), "floor_triangle": ("tri", 0.25),
}


def fit_check(piece, inset=0.005):
	"""Measure how far the model pokes past its box (Rule 3). Prints FIT lines; returns the worst overshoot (m)."""
	size = SIZE.get(piece)
	if not size:
		return 0.0
	worst = 0.0
	where = ""
	pl = tri_planes(1.0, 0.0) if size[0] == "tri" else None
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		mw = o.matrix_world
		for v in o.data.vertices:
			p = mw @ v.co
			x, y, z = p.x, p.z, -p.y  # Blender -> Godot
			if size[0] == "tri":
				over = [(-y + inset, "bottom"), (y - (size[1] - inset), "top")] + [(a * x + b * z - (c - inset), "edge") for (a, b, c) in pl]
			else:
				w, h, d = size
				over = [(abs(x) - (w / 2 - inset), "x"), (-y + inset, "bottom"), (y - (h - inset), "top"), (abs(z) - (d / 2 - inset), "z")]
			for (o_, k) in over:
				if o_ > worst:
					worst, where = o_, f"{k} {o.name} {o.active_material.name if o.active_material else ''}"
	if worst > 0.0005:
		print(f"FIT {piece} pokes out {worst * 100:.1f} cm at {where}")
	return worst


def all_keys():
	return [f"{p}__{f}" for f in KIT for p in KIT[f]]


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	keys = args or all_keys()
	if len(keys) == 1 and keys[0] in KIT:
		keys = [f"{p}__{keys[0]}" for p in KIT[keys[0]]]
	OUT.mkdir(parents=True, exist_ok=True)
	JOUR.mkdir(parents=True, exist_ok=True)
	# These Delver's Shack pieces are now made by builds/shack_v2.py (owner-approved v3 style, Nov 15):
	SHACK_V2 = {"foundation__plank_root", "wall__plank_root", "doorway__plank_root", "door__plank_root", "roof_26__plank_root",
		"window_wall__plank_root"}
	keys = [k for k in keys if k not in SHACK_V2]
	for key in keys:
		piece, family = key.split("__")
		S = STYLE_OF[family]
		globals()["S"] = S
		rng.seed(sum(map(ord, key)))
		kit.reset()
		try:
			KIT[family][piece]()
			fit_check(piece)
			out = OUT / f"{key}.glb"
			kit.save(str(out), str(JOUR / f"{key}.png"), recenter=False, tex_size=256)
			print(f"PIECE_OK {key}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"PIECE_FAILED {key}: {e!r}")
