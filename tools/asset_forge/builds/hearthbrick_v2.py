# Hearthbrick, version 2 (owner, Nov 20): the dwarven brick style the owner picked, idea B on
# assets/concepts/building-kit/hearthbrick_dwarven_wall_ideas.png, built from the turnaround sheet
# assets/concepts/building-kit/hearthbrick_turnaround_4pieces.png. Hand-pressed bumpy bricks (some proud, some sunk),
# thick pale lime mortar, heavy rough limestone corner quoins and base row, a row of upright bricks under a carved
# limestone rune band, a diamond of dark burnt bricks on the plain wall; arches under the foundation; herringbone
# floors framed in limestone (owner: floor, ceiling and foundation get the same pale border as the wall).
#   blender --background --factory-startup --python builds/hearthbrick_v2.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Pieces: wall, doorway, window_wall, foundation, floor. "grey" = one plain white material (shape check).
# Default output folder: journey/hearthbrick_v2/glb (the game's files are only replaced after the owner's OK).
# Uses the Stonehold v2 helpers (chisel cut, cut-to-curve stones, dark backing sheet) with brick sizes.
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402

K.S = "brick"
J, blk = K.J, K.blk
E = SV.E
DOOR_R, DOOR_CY = SV.DOOR_R, SV.DOOR_CY
OUT_DEFAULT = K.GAME / "journey" / "hearthbrick_v2" / "glb"

MORT = 0.013            # thick lime mortar between bricks
BASE_H = 0.22           # the rough limestone base row
FIELD_TOP = 1.64        # top of the brick field = bottom of the upright-brick row
SOLDIER_TOP = 1.82      # top of the upright-brick row = bottom of the rune band
COURSES = 12            # brick courses in the field (2 per quoin row; owner: thicker bricks)
QUOIN_W = (0.31, 0.19)  # long / short corner stones, alternating row to row
BRICK_L = (0.29, 0.37)
KEY_W = 0.095           # half width of the doorway's keystone where it meets the ring


def tag(objs, role):
	for o in objs:
		o["role"] = role
	return objs


def since(before):
	return [o for o in bpy.data.objects if o not in before]


def cbox(c, s, m, cut=0.02, dent=0.014, free="z", seeds=1):
	"""A chisel-cut box: built and dented at the centre of the world (the dent tool measures from there), then
	moved to its spot c (Godot space). `free` = the Godot axes whose faces get dents."""
	o = blk((0, 0, 0), s, m, bevel=0)
	SV.chisel(o, cut=cut, dent=dent, seed_cuts=seeds, axes=tuple(SV.GODOT_AXIS[a] for a in free))
	o.data.transform(Matrix.Translation(Vector(K.G(c))))
	return o


def m_brick():
	return kit.tex_mat("brick", K.rng.choice("abc"))


def m_lime():
	return kit.tex_mat("limestone", K.rng.choice("abc"))


def m_mortar():
	return kit.tex_mat("limestone", "a")


class Panel:
	"""A flat brick panel in its own space (u along it, y up, its centre plane at depth zc), placed facing +z
	(yaw 0) or turned to face +x/-x (yaw +-90) for the foundation's sides."""
	def __init__(self, oz=0.0, ox=0.0, yaw=0):
		self.fr = K.Frame(ox=ox, oz=oz, yaw=yaw)
		self.yaw = yaw

	def box(self, u, y, w, h, t, m, role, zoff=0.0, cut=0.02, dent=0.014, free="z", seeds=1):
		"""One chisel-cut brick or stone, centre (u, y), size w x h, t deep (its face may sit zoff proud or sunk)."""
		c = self.fr.p(u, y, zoff)
		s = (w, h, t) if self.yaw == 0 else (t, h, w)
		fz = free.replace("z", "Z")
		if self.yaw != 0:
			fz = fz.replace("x", "Q").replace("Z", "x").replace("Q", "z")
		fz = fz.replace("Z", "z")
		before = set(bpy.data.objects)
		o = cbox(c, s, m, cut=cut * K.rng.uniform(0.8, 1.2), dent=dent, free=fz, seeds=seeds)
		tag(since(before), role)
		return o

	def poly(self, pts, t, m, role, zoff=0.0, cut=0.018):
		"""A brick or stone with any outline (cut to a curve), chisel-edged."""
		o = SV.prism(self.fr, pts, zoff, t, m, cut=cut, role=role)
		return o


# ---------------- cutting bricks round openings ----------------
def cut_circle(a, b, ya, yb, cx, cy, R):
	"""The outline of rectangle [a,b] x [ya,yb] with a round opening (centre (cx, cy), radius R) taken out.
	Returns None when the rectangle doesn't touch the opening, [] when nothing is left."""
	corners = [(a, ya), (b, ya), (b, yb), (a, yb)]
	nx = min(max(cx, a), b)
	ny = min(max(cy, ya), yb)
	if (nx - cx) ** 2 + (ny - cy) ** 2 >= R * R:
		return None
	pts = SV._cut_by_circle(a - cx, b - cx, ya, yb, cy, R)
	return simplify([(x + cx, y) for (x, y) in pts])


def simplify(pts, tol=0.00002):   # tiny: curve points stay, only exact straight-side points go
	"""Drop the corner points that lie on a straight line between their neighbours (the cut helper samples each
	side of the brick 24 times; a straight side needs only its two ends)."""
	changed = True
	while changed and len(pts) > 3:
		changed = False
		for i in range(len(pts)):
			p, q, r = pts[i - 1], pts[i], pts[(i + 1) % len(pts)]
			cross = (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
			if abs(cross) < tol * math.hypot(r[0] - p[0], r[1] - p[1]):
				del pts[i]
				changed = True
				break
	return pts


def arch_cut(a, b, ya, yb, cx, spring, R):
	"""The outline of a brick next to a round-topped opening (straight sides |x-cx| < R up to `spring`, a half
	circle above). Brick courses always change exactly at the spring line, so a brick is either beside the
	straight part or above it. None = untouched, [] = fully inside the opening."""
	if yb <= spring + 1e-6:
		if b <= cx - R or a >= cx + R:
			return None
		if a >= cx - R and b <= cx + R:
			return []
		if a < cx - R:   # the brick reaches in from the left: cut at the opening's side
			return [(a, ya), (cx - R, ya), (cx - R, yb), (a, yb)] if cx - R - a > 0.03 else []
		return [(cx + R, ya), (b, ya), (b, yb), (cx + R, yb)] if b - cx - R > 0.03 else []
	return cut_circle(a, b, ya, yb, cx, spring, R)


def mortar_arc(p, cx, cy, r0, r1, t0, t1, depth, rect, skip=None, n=40):
	"""A band of pale mortar just outside an opening's ring (radius r0 to r1, angles t0..t1), almost as deep as
	the bricks: where a sliver of brick was left out next to the curve, thick mortar shows, never a dark crack."""
	before = set(bpy.data.objects)
	x0, x1, y0, y1 = rect
	planes = [(-1, 0, -x0), (1, 0, x1), (0, -1, -y0), (0, 1, y1)]
	for i in range(n):
		a, b = t0 + (t1 - t0) * i / n, t0 + (t1 - t0) * (i + 1) / n
		q = [(cx + math.cos(a) * r0, cy + math.sin(a) * r0), (cx + math.cos(b) * r0, cy + math.sin(b) * r0),
			(cx + math.cos(b) * r1, cy + math.sin(b) * r1), (cx + math.cos(a) * r1, cy + math.sin(a) * r1)]
		if K.area(q) and (q[1][0] - q[0][0]) * (q[2][1] - q[0][1]) - (q[1][1] - q[0][1]) * (q[2][0] - q[0][0]) < 0:
			q.reverse()
		mx = sum(v[0] for v in q) / 4
		my = sum(v[1] for v in q) / 4
		if skip and skip(mx, my):
			continue
		q = K.clip_poly(q, planes)
		if q and K.area(q) > 1e-5:
			K.slab_poly(p.fr, q, 0.0, depth, m_mortar())
	tag(since(before), "mortar")


def thickness(pts):
	"""About how thick a cut shape is (twice its area over its outline length: a brick 6.6 cm tall gives ~5 cm)."""
	per = sum(math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]) for i in range(len(pts)))
	return 2 * K.area(pts) / per if per else 0.0


def thin(pts, lim=0.028):
	"""A sliver left over by a cut (also long thin triangles): too narrow to be a real brick or stone."""
	return thickness(pts) < lim * 0.8


def lay_row(x0, x1, offset):
	"""Brick lengths across one course from x0 to x1, starting with a part brick `offset` long (half bond)."""
	xs = [x0]
	x = x0 + offset if offset > 0.06 else x0
	if x > x0:
		xs.append(x)
	while x1 - x > BRICK_L[1] + 0.06:
		x += K.rng.uniform(*BRICK_L)
		xs.append(x)
	if x1 - x > 0.0:
		xs.append(x1)
	return [(xs[i], xs[i + 1]) for i in range(len(xs) - 1)]


def brick(p, a, b, ya, yb, t, cutter=None, dark=False, role="brick"):
	"""One hand-pressed brick in the gap-free box [a,b] x [ya,yb] (the mortar gap is taken off here): its depth
	and how far it sits proud or sunk vary, its faces are lumpy. cutter(a, b, ya, yb) -> outline / None / []."""
	g = MORT / 2
	a, b, ya, yb = a + g, b - g, ya + g, yb - g
	if b - a < 0.03 or yb - ya < 0.02:
		return
	dd = t - 2 * E - K.rng.uniform(0.002, 0.018)
	zoff = K.rng.uniform(-0.5, 0.5) * (t - 2 * E - dd)   # some bricks a little proud, some a little sunk (never behind the mortar)
	m = kit.tex_mat("brick", "dark") if dark else m_brick()
	if cutter:
		pts = cutter(a, b, ya, yb)
		if pts == []:
			return
		if pts is not None:
			if K.area(pts) > 0.003 and not thin(pts):
				o = p.poly(pts, dd, m, role, zoff=zoff, cut=min(0.014, thickness(pts) * 0.3))
				o["dark"] = dark
			return
	o = p.box((a + b) / 2, (ya + yb) / 2, b - a, yb - ya, dd, m, role, zoff=zoff, cut=0.016, dent=0.016, seeds=0)
	o["dark"] = dark


def stone(p, a, b, ya, yb, t, cutter=None, role="lime", gap=0.004):
	"""One rough limestone block (quoin, base row, band)."""
	a, b, ya, yb = a + gap / 2, b - gap / 2, ya + gap / 2, yb - gap / 2
	dd = t - 2 * E - K.rng.uniform(0.002, 0.008)
	if cutter:
		pts = cutter(a, b, ya, yb)
		if pts == []:
			return
		if pts is not None:
			if K.area(pts) > 0.004 and not thin(pts, 0.04):
				p.poly(pts, dd, m_lime(), role, cut=min(0.022, thickness(pts) * 0.3))
			return
	return p.box((a + b) / 2, (ya + yb) / 2, b - a, yb - ya, dd, m_lime(), role, cut=K.rng.uniform(0.03, 0.045), dent=0.022, seeds=1)


def in_diamond(u, y, cu=0.0, cy=0.95, r=0.42, ring=0.11):
	"""The dark burnt-brick diamond on the plain wall: a band round a diamond plus its centre."""
	k = abs(u - cu) + abs(y - cy)
	return (r - ring < k < r) or k < 0.14


# ---------------- walls ----------------
_CH = (FIELD_TOP - BASE_H) / COURSES
# the arched window: bottom, spring line (exactly on brick-course lines, so the sill's row really is left out:
# 0.574 was 1 mm under the line and the sill sat inside bricks = shimmer, Nov 20), radius, brick ring
WIN_B, WIN_SP, WIN_R, WIN_RING = BASE_H + 3 * _CH, BASE_H + 6 * _CH, 0.5, 0.1
SILL_HW = 0.62


def segments(a0, a1, cuts):
	"""The parts of [a0, a1] left beside openings `cuts` [(lo, hi)...]: bricks are laid to end exactly at an
	opening's edge (owner, Nov 20: no gaps beside openings), never cut afterwards."""
	out, x = [], a0
	for (lo, hi) in sorted(cuts):
		if lo > x + 0.03:
			out.append((x, lo))
		x = max(x, hi)
	if a1 > x + 0.03:
		out.append((x, a1))
	return out


def round_cutter(cx, cy, R, key_x=0.0, y_key=9.0):
	"""Bricks above an opening's spring line: cut to the circle (radius R round (cx, cy)); with a keystone, the
	bricks beside it stop at its straight column |x - cx| < key_x above height y_key."""
	def cut(a, b, ya, yb):
		r = cut_circle(a, b, ya, yb, cx, cy, R)
		if r == []:
			return []
		if key_x and yb > y_key and a < cx + key_x and b > cx - key_x:
			if r is not None:
				return []
			if a < cx - key_x:
				pts = [(a, ya), (cx - key_x, ya), (cx - key_x, yb), (a, yb)]
			elif b > cx + key_x:
				pts = [(cx + key_x, ya), (b, ya), (b, yb), (cx + key_x, yb)]
			else:
				return []
			return pts if K.area(pts) > 0.0012 else []
		return r
	return cut


def ring(p, cx, cy, r_in, r_out, a0, a1, d, n, key_w=0.0):
	"""Wedge-shaped bricks round an opening from angle a0 to a1, every third one dark, a gap on top for the
	keystone (half width key_w where it meets the ring, 0.7 x that at the opening)."""
	top = math.pi / 2
	parts = [(a0, a1, a0, a1)]
	if key_w:
		go = math.asin(min(1.0, (key_w + 0.002) / r_out))
		gi = math.asin(min(1.0, (key_w * 0.7 + 0.002) / r_in))
		parts = [(a0, top - go, a0, top - gi), (top + go, a1, top + gi, a1)]
	g = 0.006
	m = n // len(parts)
	for (lo, hi, lo_i, hi_i) in parts:
		for i in range(m):
			t0o, t1o = lo + (hi - lo) * i / m, lo + (hi - lo) * (i + 1) / m
			t0i, t1i = lo_i + (hi_i - lo_i) * i / m, lo_i + (hi_i - lo_i) * (i + 1) / m
			pts = []
			for k in range(3):
				t = t0i + g / r_in + (t1i - t0i - 2 * g / r_in) * k / 2
				pts.append((cx + math.cos(t) * r_in, cy + math.sin(t) * r_in))
			for k in range(3):
				t = t1o - g / r_out - (t1o - t0o - 2 * g / r_out) * k / 2
				pts.append((cx + math.cos(t) * r_out, cy + math.sin(t) * r_out))
			pts = [(x, max(E, y)) for (x, y) in pts]
			if K.area(pts) < 0.001:
				continue
			dark = (i % 3 == 1)
			o = p.poly(pts, d - 2 * E - K.rng.uniform(0.004, 0.014), kit.tex_mat("brick", "dark") if dark else m_brick(), "brick", cut=0.016)
			o["dark"] = dark


def keystone(p, cx, cy, r_in, r_out, key_w, top, d):
	"""The carved limestone keystone in the ring's top gap, from the opening up to `top`, flaring a little."""
	kin = key_w * 0.7
	y_in = cy + math.sqrt(r_in * r_in - kin * kin)
	y_out = cy + math.sqrt(r_out * r_out - key_w * key_w)
	pts = [(cx + kin, y_in), (cx + key_w, y_out), (cx + key_w + 0.02, top), (cx - key_w - 0.02, top), (cx - key_w, y_out), (cx - kin, y_in)]
	p.poly(pts, d - 2 * E - 0.004, m_lime(), "keystone", cut=0.03)


def arch_backing(p, x0, x1, y0, y1, cx, bottom, spring, R, t, depth=0.7):
	"""The pale mortar sheet inside a wall or foundation side, with a round-topped hole (straight sides from
	`bottom` up to `spring`, a half circle above, radius R) reaching to the opening's edge, so no joint beside
	the opening is see-through. Made as a left and a right half, each one simple outline."""
	before = set(bpy.data.objects)
	for side in (-1, 1):
		xe = x0 if side < 0 else x1
		pts = [(xe, y0), (cx, y0)] if bottom > y0 + 0.01 else [(xe, y0)]
		if bottom > y0 + 0.01:
			pts.append((cx, bottom))
		pts.append((cx + side * R, bottom if bottom > y0 + 0.01 else y0))
		pts.append((cx + side * R, spring))
		for k in range(1, 16):
			tt = (0.0 if side > 0 else math.pi) + (math.pi / 2) * k / 16 * (1 if side > 0 else -1)
			pts.append((cx + math.cos(tt) * R, spring + math.sin(tt) * R))
		pts += [(cx, spring + R), (cx, y1), (xe, y1)]
		K.slab_poly(p.fr, simplify(pts), 0.0, t * depth, m_mortar())
	tag(since(before), "mortar")


def wall_body(w=2.0, h=2.0, d=0.3, door=False, window=False, diamond=False):
	"""The idea-B wall: limestone base row, alternating limestone quoins up both ends, a field of bumpy bricks,
	a row of upright bricks, a carved limestone band on top; a pale mortar sheet inside behind everything.
	door: the round doorway (rule 5); window: a tall arched window with leaded panes and a limestone sill."""
	p = Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	ch = (FIELD_TOP - BASE_H) / COURSES
	cutter = None
	key_x = 0.0
	if door:
		r_in = DOOR_R + 0.01
		r_out = r_in + 0.13
		key_x = KEY_W + 0.024   # the keystone's column (it flares a little toward the top)
		y_out = DOOR_CY + math.sqrt(r_out * r_out - KEY_W * KEY_W)
		cutter = round_cutter(0.0, DOOR_CY, r_out + 0.002, key_x, y_out - 0.05)
		before = set(bpy.data.objects)
		SV.backing(p.fr, x0, x1, E, h - E, d * 1.13, hole=(DOOR_CY, r_in + 0.004))   # 0.7 x the wall deep
		tag(since(before), "mortar")
	elif window:
		w_out = WIN_R + WIN_RING
		wk = 0.075
		key_x = wk + 0.024
		y_out = WIN_SP + math.sqrt(w_out * w_out - wk * wk)
		cutter = round_cutter(0.0, WIN_SP, w_out + 0.002, key_x, y_out - 0.05)
		arch_backing(p, x0 + 0.01, x1 - 0.01, E + 0.004, h - 0.01, 0.0, WIN_B, WIN_SP, WIN_R + 0.009, d)
	else:
		before = set(bpy.data.objects)
		SV.backing(p.fr, x0, x1, E, h - E, d * 1.13)
		tag(since(before), "mortar")
	# base row: rough limestone blocks
	x = x0
	while x < x1 - 0.01:
		nx = min(x1, x + K.rng.uniform(0.34, 0.52))
		if x1 - nx < 0.2:
			nx = x1
		stone(p, x, nx, E, BASE_H, d, cutter)
		x = nx
	# quoins: 6 rows of 2 brick courses, then one beside the upright bricks and one beside the band
	rows = [(BASE_H + 2 * ch * k, BASE_H + 2 * ch * (k + 1)) for k in range(6)] + [(FIELD_TOP, SOLDIER_TOP), (SOLDIER_TOP, h - E)]
	inner = []
	for k, (ya, yb) in enumerate(rows):
		qw = QUOIN_W[k % 2]
		for sx in (-1, 1):
			a, b = (x0, x0 + qw) if sx < 0 else (x1 - qw, x1)
			stone(p, a, b, ya, yb, d, cutter)   # beside the doorway ring the corner stones are cut round it
		inner.append((ya, yb, x0 + qw, x1 - qw))
	# the brick field: rows reach right up to the corner stones (only a thin joint between)
	reach = MORT / 2 - 0.0025
	for c in range(COURSES):
		ya, yb = BASE_H + ch * c, BASE_H + ch * (c + 1)
		row = inner[c // 2]
		a0, a1 = row[2] + 0.002 - reach, row[3] - 0.002 + reach
		cuts = []
		cut_here = cutter
		if window:
			if yb <= WIN_B + 1e-6 and ya >= WIN_B - ch - 1e-6:
				cuts = [(-SILL_HW, SILL_HW)]                  # the sill's row
			elif ya >= WIN_B - 1e-6 and yb <= WIN_SP + 1e-6:
				cuts = [(-WIN_R - MORT / 2, WIN_R + MORT / 2)]  # beside the opening: bricks end at its edge
			if yb <= WIN_SP + 1e-6:
				cut_here = None
		off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
		for (sa, sb) in segments(a0, a1, cuts):
			for (a, b) in lay_row(sa, sb, off if sa == a0 else 0.0):
				dark = diamond and in_diamond((a + b) / 2, (ya + yb) / 2)
				if not dark and K.rng.random() < 0.06:
					dark = True   # a few burnt bricks anywhere (about 1 in 16)
				brick(p, a, b, ya, yb, d, cut_here, dark=dark)
	# the upright bricks under the band
	a0, a1 = inner[6][2] + 0.002 - reach, inner[6][3] - 0.002 + reach
	n = max(1, round((a1 - a0) / 0.12))
	for k in range(n):
		a, b = a0 + (a1 - a0) * k / n, a0 + (a1 - a0) * (k + 1) / n
		if door and a < key_x + 0.004 and b > -key_x - 0.004:
			continue
		brick(p, a, b, FIELD_TOP, SOLDIER_TOP, d, None, role="brick")
	# the carved limestone band (its runes are painted on)
	a0, a1 = inner[7][2] + 0.002, inner[7][3] - 0.002
	cuts_b = [a0, a0 + (a1 - a0) * K.rng.uniform(0.3, 0.38), a0 + (a1 - a0) * K.rng.uniform(0.62, 0.7), a1]
	for k in range(3):
		stone(p, cuts_b[k], cuts_b[k + 1], SOLDIER_TOP, h - E, d, role="band")
	if door:
		a_lo = math.asin(max(-1.0, -(DOOR_CY - E) / r_out))
		ring(p, 0.0, DOOR_CY, r_in, r_out, a_lo, math.pi - a_lo, d, 22, KEY_W)
		a_lo = math.asin(max(-1.0, -(DOOR_CY - E) / (r_out + 0.06)))
		mortar_arc(p, 0.0, DOOR_CY, r_out - 0.01, r_out + 0.06, a_lo, math.pi - a_lo, d - 2 * E - 0.045,
			(x0 + 0.01, x1 - 0.01, E + 0.004, SOLDIER_TOP - 0.004), skip=lambda x, y: abs(x) < key_x + 0.01 and y > y_out - 0.08)
		keystone(p, 0.0, DOOR_CY, r_in, r_out, KEY_W, SOLDIER_TOP - 0.003, d)
	if window:
		ring(p, 0.0, WIN_SP, WIN_R, w_out, 0.0, math.pi, d, 14, wk)
		mortar_arc(p, 0.0, WIN_SP, w_out - 0.01, w_out + 0.06, 0.0, math.pi, d - 2 * E - 0.045,
			(x0 + 0.01, x1 - 0.01, WIN_SP, FIELD_TOP - 0.004), skip=lambda x, y: abs(x) < key_x + 0.01 and y > y_out - 0.08)
		keystone(p, 0.0, WIN_SP, WIN_R, w_out, wk, y_out + 0.09, d)
		# the limestone sill: one long stone in the row under the opening
		stone(p, -SILL_HW + MORT / 2 - 0.004, SILL_HW - MORT / 2 + 0.004, WIN_B - ch, WIN_B, d, role="lime")
		leaded_glass(p, WIN_B, WIN_SP, WIN_R + 0.012)


def leaded_glass(p, bottom, spring, R):
	"""The leaded window: a thin pane of greenish glass in the middle of the wall, held by a diamond lattice of
	dark lead strips; both run 1.2 cm into the bricks round the opening (never past the wall's faces)."""
	poly = [(-R, bottom), (R, bottom)]
	for k in range(17):
		tt = math.pi * k / 16
		poly.append((math.cos(tt) * R, spring + math.sin(tt) * R))
	planes = []
	for i in range(len(poly)):   # the outline is convex: one half-plane per side (inside = left of each side)
		(ax, ay), (bx, by) = poly[i], poly[(i + 1) % len(poly)]
		nx, ny = by - ay, -(bx - ax)
		L = math.hypot(nx, ny)
		if L < 1e-6:
			continue
		nx, ny = nx / L, ny / L
		planes.append((nx, ny, nx * ax + ny * ay))
	before = set(bpy.data.objects)
	K.slab_poly(p.fr, simplify(poly[:]), 0.0, 0.012, glass_m())
	tag(since(before), "glass")
	before = set(bpy.data.objects)
	s, wd = 0.17, 0.016
	for sign in (1, -1):
		dx, dy = 1 / math.sqrt(2), sign / math.sqrt(2)
		nx, ny = -dy, dx
		for k in range(-12, 13):
			L2 = 2.0
			mx, my = 0.0, spring + k * s
			strip = [(mx - dx * L2 - nx * wd / 2, my - dy * L2 - ny * wd / 2), (mx + dx * L2 - nx * wd / 2, my + dy * L2 - ny * wd / 2),
				(mx + dx * L2 + nx * wd / 2, my + dy * L2 + ny * wd / 2), (mx - dx * L2 + nx * wd / 2, my - dy * L2 + ny * wd / 2)]
			if K.area(strip) and (strip[1][0] - strip[0][0]) * (strip[2][1] - strip[0][1]) - (strip[1][1] - strip[0][1]) * (strip[2][0] - strip[0][0]) < 0:
				strip.reverse()
			strip = K.clip_poly(strip, planes)
			if strip and K.area(strip) > 1e-4:
				K.slab_poly(p.fr, strip, 0.0, 0.024 if sign > 0 else 0.02, kit.tex_mat("iron", "dark"))
	tag(since(before), "lead")


def glass_m():
	m = bpy.data.materials.get("hb_glass")
	if m:
		return m
	m = bpy.data.materials.new("hb_glass")
	m.use_nodes = True
	bsdf = m.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.42, 0.55, 0.42, 1)
	bsdf.inputs["Roughness"].default_value = 0.15
	bsdf.inputs["Alpha"].default_value = 0.45
	if hasattr(m, "surface_render_method"):
		m.surface_render_method = "BLENDED"
	if hasattr(m, "blend_method"):
		m.blend_method = "BLEND"
	return m


def wall():
	wall_body(diamond=True)


def doorway():
	wall_body(door=True)


def window_wall():
	wall_body(window=True)


# ---------------- herringbone tops ----------------
HB_W, HB_L = 0.11, 0.33


def herringbone(x0, x1, z0, z1, y0, y1, role="brick", under=False):
	"""Herringbone bricks (a zig-zag, laid at 45 degrees) over the rectangle seen from above, each cut exactly
	to the rectangle. Pale mortar shows between them (a mortar bed sits under them)."""
	w, L = HB_W, HB_L
	cs, sn = math.cos(math.pi / 4), math.sin(math.pi / 4)
	g = MORT / 2
	planes = [(-1, 0, -x0), (1, 0, x1), (0, -1, -z0), (0, 1, z1)]
	before = set(bpy.data.objects)
	bed = (y0 + (y1 - y0) * 0.45, y1 - 0.004) if under else (y0 + 0.004, y0 + (y1 - y0) * 0.55)   # under: seen from below
	K.floor_poly([(x0 + 0.01, z0 + 0.01), (x1 - 0.01, z0 + 0.01), (x1 - 0.01, z1 - 0.01), (x0 + 0.01, z1 - 0.01)], bed[0], bed[1], m_mortar())
	tag(since(before), "mortar")
	reach = 2.2
	N = int(reach / w) + 2
	for k in range(-12, 13):
		ou, ov = k * 3 * w, -k * 3 * w
		for nn in range(-N, N):
			for (ua, ub, va, vb) in ((ou + nn * w, ou + nn * w + L, ov + nn * w, ov + nn * w + w),
					(ou + nn * w, ou + nn * w + w, ov + nn * w + w, ov + nn * w + w + L)):
				ua, ub, va, vb = ua + g, ub - g, va + g, vb - g
				corners = [(ua, va), (ub, va), (ub, vb), (ua, vb)]
				pts = [((u - v) * cs, (u + v) * sn) for (u, v) in corners]   # turned 45 degrees
				cx = sum(q[0] for q in pts) / 4
				cz = sum(q[1] for q in pts) / 4
				if not (x0 - 0.3 < cx < x1 + 0.3 and z0 - 0.3 < cz < z1 + 0.3):
					continue
				pts = K.clip_poly(pts, planes)
				if not pts or K.area(pts) < 0.0012:
					continue
				th = (y1 - y0) - K.rng.uniform(0.0, 0.012)
				before = set(bpy.data.objects)
				o = K.floor_poly(pts, y0, y0 + th, m_brick()) if under else K.floor_poly(pts, y1 - th, y1, m_brick())
				if not under:   # the underside stays plain (seen from below in the shade; keeps the piece light)
					b = o.modifiers.new("chisel", "BEVEL")
					b.width, b.segments, b.limit_method, b.angle_limit = 0.01, 1, "ANGLE", math.radians(35)
				for pp in o.data.polygons:
					pp.use_smooth = False
				tag(since(before), role)
				o["dark"] = K.rng.random() < 0.06


def stone_frame(x0, x1, z0, z1, y0, y1, bw):
	"""A frame of rough limestone blocks round the edge of a rectangle (seen from above), bw wide:
	front and back strips run the full length, the side strips fit between them."""
	for (za, zb) in ((z1 - bw, z1), (z0, z0 + bw)):   # front / back strips
		x = x0
		while x < x1 - 0.01:
			nx = min(x1, x + K.rng.uniform(0.4, 0.6))
			if x1 - nx < 0.25:
				nx = x1
			g = 0.002
			tag([cbox(((x + nx) / 2, (y0 + y1) / 2, (za + zb) / 2), (nx - x - g, y1 - y0 - 0.002, zb - za - g), m_lime(),
				cut=0.035, dent=0.02, free="y", seeds=1)], "lime")
			x = nx
	for (xa, xb) in ((x0, x0 + bw), (x1 - bw, x1)):   # side strips
		z = z0 + bw
		while z < z1 - bw - 0.01:
			nz = min(z1 - bw, z + K.rng.uniform(0.4, 0.6))
			if z1 - bw - nz < 0.25:
				nz = z1 - bw
			g = 0.002
			tag([cbox(((xa + xb) / 2, (y0 + y1) / 2, (z + nz) / 2), (xb - xa - g, y1 - y0 - 0.002, nz - z - g), m_lime(),
				cut=0.035, dent=0.02, free="y", seeds=1)], "lime")
			z = nz
	for o in bpy.data.objects:
		if o.get("role") == "stone":
			o["role"] = "lime"


# ---------------- floor (the ceiling seen from below) ----------------
def floor(w=2.0, h=0.25, dd=2.0):
	"""Limestone border all round (full height, so the joists never show from the side), herringbone bricks on
	top, and underneath: herringbone again, held by dark timber joists with copper brackets."""
	bw = 0.2
	x0, x1, z0, z1 = -w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E
	stone_frame(x0, x1, z0, z1, E, h - E, bw)
	ix0, ix1, iz0, iz1 = x0 + bw + 0.003, x1 - bw - 0.003, z0 + bw + 0.003, z1 - bw - 0.003
	herringbone(ix0, ix1, iz0, iz1, 0.185, h - E)   # the walking surface
	before = set(bpy.data.objects)   # a dark core between the two brick layers
	blk((0, 0.165, 0), (ix1 - ix0 - 0.01, 0.03, iz1 - iz0 - 0.01), kit.tex_mat("wood", "dark"), bevel=0)
	tag(since(before), "mortar")
	# the underside's bricks (seen from below as the ceiling): flat rows, bottom face visible
	under_y0, under_y1 = 0.105, 0.152
	herringbone(ix0, ix1, iz0, iz1, under_y0, under_y1, role="brick", under=True)
	for o in bpy.data.objects:   # the underside's mortar bed sits on top, out of sight; nothing to change
		pass
	# joists: 3 dark timbers across, under the underside bricks, ends resting against the border
	jw, jy0, jy1 = 0.1, E + 0.004, under_y0 + 0.003
	for zc in (-0.42, 0.0, 0.42):
		before = set(bpy.data.objects)
		blk((0, (jy0 + jy1) / 2, zc), (ix1 - ix0 - 0.006, jy1 - jy0, jw), kit.tex_mat("wood", "dark"), bevel=0.01)
		tag(since(before), "timber")
		for sx in (-1, 1):   # copper brackets on both sides of each joist end
			for sz in (-1, 1):
				before = set(bpy.data.objects)
				blk((sx * (ix1 - 0.07), (jy0 + jy1) / 2, zc + sz * (jw / 2 + 0.006)), (0.12, (jy1 - jy0) * 0.7, 0.01), kit.tex_mat("copper", "b"), bevel=0.002)
				tag(since(before), "copper")


# ---------------- foundation ----------------
def foundation(w=2.0, h=1.0, dd=2.0):
	"""Brick sides with two little round-topped arches each (open crawl space), limestone corner columns, a
	limestone capping border on top round a herringbone brick top."""
	cap0 = 0.84
	t = 0.24
	cw = 0.3
	x0, x1, z0, z1 = -w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E
	stone_frame(x0, x1, z0, z1, cap0, h - E, t)
	herringbone(x0 + t + 0.003, x1 - t - 0.003, z0 + t + 0.003, z1 - t - 0.003, 0.90, h - E)
	before = set(bpy.data.objects)   # the dark slab under the top (seen through the arches)
	blk((0, (cap0 + 0.9) / 2 + 0.004, 0), (w - 2 * t - 0.03, 0.9 - cap0 - 0.006, dd - 2 * t - 0.03), kit.tex_mat("wood", "dark"), bevel=0)
	tag(since(before), "mortar")
	# corner columns of limestone blocks
	ys = [E, 0.23, 0.42, 0.63, cap0]
	for sx in (-1, 1):
		for sz in (-1, 1):
			cx, cz = sx * (w / 2 - E - cw / 2), sz * (dd / 2 - E - cw / 2)
			for k in range(4):
				tag([cbox((cx, (ys[k] + ys[k + 1]) / 2, cz), (cw - 0.004, ys[k + 1] - ys[k] - 0.004, cw - 0.004), m_lime(),
					cut=0.035, dent=0.02, free="xz", seeds=1)], "lime")
	for o in bpy.data.objects:
		if o.get("role") == "stone":
			o["role"] = "lime"
	# four brick sides between the columns, each with one round-topped arch (owner, Nov 20: one, not two)
	nc = 7
	ch = (cap0 - E) / nc
	spring = E + ch * 3
	R = 0.34
	ring_t = 0.1
	sides = [Panel(oz=dd / 2 - E - t / 2), Panel(oz=-(dd / 2 - E - t / 2)),
		Panel(ox=w / 2 - E - t / 2, yaw=90), Panel(ox=-(w / 2 - E - t / 2), yaw=90)]
	reach = MORT / 2 - 0.0025
	for p in sides:
		L = (w if p.yaw == 0 else dd) - 2 * E - 2 * cw
		u0, u1 = -L / 2, L / 2   # the corner columns' faces
		arch_backing(p, u0 - 0.002, u1 + 0.002, E + 0.004, cap0 - 0.004, 0.0, E + 0.004, spring, R + 0.009, t)
		cutter = round_cutter(0.0, spring, R + ring_t + 0.002)
		for c in range(nc):
			ya, yb = E + ch * c, E + ch * (c + 1)
			below = yb <= spring + 1e-6
			cuts = [(-R - MORT / 2, R + MORT / 2)] if below else []
			off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
			for (sa, sb) in segments(u0 - reach, u1 + reach, cuts):
				for (a, b) in lay_row(sa, sb, off if sa < u0 else 0.0):
					brick(p, a, b, ya, yb, t, None if below else cutter, dark=K.rng.random() < 0.06)
		ring(p, 0.0, spring, R, R + ring_t, 0.0, math.pi, t, 11)
		mortar_arc(p, 0.0, spring, R + ring_t - 0.01, R + ring_t + 0.06, 0.0, math.pi, t - 2 * E - 0.04,
			(u0, u1, spring, cap0 - 0.004))
	# (a hollow inside: the crawl space shows the brick backs and the dark slab under the top)


def split_big_faces():
	"""Every face with more than 4 corners (the fronts of stones cut to a curve, the mortar sheets round openings)
	is split into triangles by ear clipping, which handles bent outlines. Left to the exporter, a bent face got
	split the wrong way and showed a black line across the stone (Nov 20)."""
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		bm = bmesh.new()
		bm.from_mesh(o.data)
		big = [f for f in bm.faces if len(f.verts) > 4]
		if big:
			bmesh.ops.triangulate(bm, faces=big, quad_method="BEAUTY", ngon_method="EAR_CLIP")
			bm.to_mesh(o.data)
		bm.free()


PIECES = {"wall": wall, "doorway": doorway, "window_wall": window_wall, "foundation": foundation, "floor": floor}


HB_TILE = {"hbbrick": 0.36, "hblime": 0.6, "hbmortar": 0.5, "hbrune": 0.52, "hbtimber": 0.6, "hbcopper": 0.4}
kit.TILE.update(HB_TILE)


def hb(kind, v):
	return kit.tex_mat(kind, v)


def band_uv(o, row_h):
	"""The rune band's painting (three rows of carved runes, one above the other) laid flat on the band's face, so
	exactly one row of runes fills the band from bottom to top (it is never stretched)."""
	me = o.data
	if not me.uv_layers:
		me.uv_layers.new()
	uv = me.uv_layers.active.data
	for poly in me.polygons:
		for li in poly.loop_indices:
			v = me.vertices[me.loops[li].vertex_index].co
			uv[li].uv = (v.x / (3 * row_h), (v.z - SOLDIER_TOP) / (3 * row_h))


def paint():
	"""The Hearthbrick texture sheet (ChatGPT, Nov 20; cut by derive_tex_hearthbrick.py): six warm brick colours
	(neighbours differ), about 1 in 8 an ochre brick, the burnt bricks (diamond, a few strays) dark; four pale
	limestones; gritty pale lime mortar; the carved rune band on the top band; dark timber; hammered copper."""
	bricks = "abcdef"
	for o in list(bpy.data.objects):
		if o.type != "MESH" or not o.data.materials:
			continue
		role = o.get("role")
		m = o.data.materials[0]
		if role == "glass" or role == "lead":
			continue
		if role == "brick":
			if o.get("dark"):
				m = hb("hbbrick", "dark")
			elif K.rng.random() < 0.12:
				m = hb("hbbrick", "ochre")
			else:
				m = hb("hbbrick", K.rng.choice(bricks))
		elif role in ("lime", "keystone"):
			m = hb("hblime", K.rng.choice("abcd"))
		elif role == "band":
			o.data.materials.clear()
			o.data.materials.append(hb("hbrune", "a"))
			band_uv(o, 2.0 - E - SOLDIER_TOP)
			continue
		elif role == "mortar":
			m = hb("hbtimber", "a") if m.name.startswith("wood") else hb("hbmortar", "a")
		elif role == "timber":
			m = hb("hbtimber", "a")
		elif role == "copper":
			m = hb("hbcopper", "a")
		o.data.materials.clear()
		o.data.materials.append(m)
		kind = m.name.rsplit("_", 1)[0]
		kit._uv_box(o, HB_TILE.get(kind, kit.TILE.get(kind, 0.6)))


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), OUT_DEFAULT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in names:
		K.rng.seed(sum(map(ord, name + "hearthbrick2")))
		kit.reset()
		PIECES[name]()
		split_big_faces()
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			paint()
		png = str(K.JOUR / f"{name}__clay_brick.png") if install else None
		kit.save(str(out_dir / f"{name}__clay_brick.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
