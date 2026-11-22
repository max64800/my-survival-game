# F716 (owner, Nov 22: "my dwarf had a very hard time climbing them, and they should come to a solid block"):
# the 4×4 m spiral stairs, shared by the three kits (stonehold_v2.py, hearthbrick_v2_new.py, shack_v2.py). The
# game's src/build/piece_mesh.gd (SPIRAL_*) uses the same numbers for bumping and the space underneath.
#
# Piece frame: middle at (0, 0), floor at y 0, top (the landing) at y 2. A point at angle a is
# (cos a, -sin a) * r in (x, z): 0 = +x, 90° = -z. Nine 30° treads climb from +x toward -z, 3/4 of a turn, round a
# thick post; the landing fills the last quarter (x, z > 0) at the top, over the way in. A rail runs round the
# outside on corner pillars, and along the landing's drop.
#
# Each kit calls build() with its own parts:
#   post(y1)                    the middle post, floor to y1
#   tread(poly, top, inner)     one tread stone/board, outline (x, z), its top (inner = the half by the post)
#   flag(poly, y0, y1)          one landing flag/board
#   pier(cx, cz, w, y0, y1)     a square pillar or newel post
#   rail(p0, top0, p1, top1)    a straight rail bar from (x, z) p0 to p1, its top at each end
#   baluster(x, z, y0, y1)      a baluster standing at (x, z) from y0 up to y1 (the rail's underside)
import math

H = 2.0           # the landing's top (the piece's height in the game)
STEPS = 9
STEP = math.pi / 6
POST = 0.32       # the post's radius
REACH = 1.84      # treads reach the square this far out (a wall's inner face is at 1.85)
LANDING = 1.75    # the landing's underside
LAND = 1.99       # the landing reaches this far along x and z
RAIL = 1.73       # the rail's (and its pillars') middle line, from the post along x or z
RAIL_H = 0.85     # the rail's top over the slope
BAR = 0.14        # the rail bar's height
PW = 0.22         # pillar / newel width
CORNERS = (math.pi * 0.25, math.pi * 0.75, math.pi * 1.25)


def at(a, r):
	return (math.cos(a) * r, -math.sin(a) * r)


def sq(a, h):
	c, s = math.cos(a), -math.sin(a)
	k = h / max(abs(c), abs(s))
	return (c * k, s * k)


def tread_top(i):
	return H * 0.1 * (i + 1)


def slope_y(a):
	u = a / STEP
	return min(H, H * (0.1 * u + 0.05 * min(1.0, u)))


def rail_top(a):
	return slope_y(a) + RAIL_H


def _notch(c, p0):
	"""The outline round a corner pillar's square (instead of the square's corner point), in walking order."""
	C = sq(c, REACH)
	P = sq(c, RAIL)
	g = PW / 2 + 0.005
	N = (P[0] - math.copysign(g, P[0]), P[1] - math.copysign(g, P[1]))
	if abs(abs(p0[0]) - REACH) < 1e-6:   # coming along the x edge
		return [(C[0], N[1]), N, (N[0], C[1])]
	return [(N[0], C[1]), N, (C[0], N[1])]


def tread_polys(i, rm=0.95):
	"""Tread i's two halves (x, z): inner (post to rm) and outer (rm to the square, notched round a corner pillar).
	Each laps 3° over the next tread (seen from above: no gaps), the last one stops at the landing."""
	a0 = STEP * i
	a1 = STEP * (i + 1) + (math.radians(3) if i < STEPS - 1 else 0.0)
	ri = POST - 0.02   # set 2 cm into the post (a tread touches it, never floats)
	inner = [at(a0, ri), at(a0, rm), at(a1, rm), at(a1, ri), at((a0 + a1) / 2, ri)]
	p0 = sq(a0, REACH)
	outer = [at(a0, rm), p0]
	for c in CORNERS:
		if a0 < c < a1:
			outer += _notch(c, p0)
	outer += [sq(a1, REACH), at(a1, rm)]
	return inner, outer


def _ccw(poly):
	"""Counter-clockwise seen from above in (x, -z), the way slab_xz wants it."""
	a = sum(poly[i][0] * -poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * -poly[i][1] for i in range(len(poly)))
	return poly if a > 0 else list(reversed(poly))


def _side_point(a):
	return sq(a, RAIL)


def build(post, tread, flag, pier, rail, baluster, rng, post_top=2.95):
	J = lambda s: rng.uniform(-s, s)
	post(post_top)
	# treads
	for i in range(STEPS):
		inner, outer = tread_polys(i, 0.95 + J(0.06))
		tread(_ccw(inner), tread_top(i), True)
		tread(_ccw(outer), tread_top(i), False)
	# the landing: 3 × 3 flags, the one by the post cut round it
	g = 0.003
	xs = [g, 0.66 + J(0.05), 1.33 + J(0.05), LAND]
	zs = [g, 0.66 + J(0.05), 1.33 + J(0.05), LAND]
	ri = POST - 0.02   # set 2 cm into the post (a tread touches it, never floats)
	for ix in range(3):
		for iz in range(3):
			x0, x1, z0, z1 = xs[ix] + (g if ix else 0), xs[ix + 1] - g, zs[iz] + (g if iz else 0), zs[iz + 1] - g
			if ix == 0 and iz == 0:
				poly = [(ri, z0), (x1, z0), (x1, z1), (x0, z1), (x0, ri)]
				poly += [(ri * math.cos(t), ri * math.sin(t)) for t in (math.radians(67.5), math.radians(45), math.radians(22.5))]
			else:
				poly = [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]
			flag(_ccw(poly), LANDING, H - 0.006)
	pier(1.72, 1.72, 0.24, 0.0, LANDING - 0.003)   # the landing's corner pillar
	# corner pillars on the floor, the rail on them round the outside
	tops = {}
	for c in CORNERS:
		cx, cz = sq(c, RAIL)
		tops[c] = rail_top(c)
		pier(cx, cz, PW, 0.0, tops[c] + 0.08)
	end = (-0.14, RAIL)                                # the rail's top end: a newel on the last tread
	a_end = math.atan2(-end[1], end[0]) % math.tau
	ends = [(CORNERS[0], CORNERS[1]), (CORNERS[1], CORNERS[2]), (CORNERS[2], None)]
	mids = {CORNERS[0]: (-0.2, -RAIL, 3), CORNERS[1]: (-RAIL, 0.2, 6)}   # a post under each long rail, on tread 3 / 6
	h2 = PW / 2 + 0.005
	for (ca, cb) in ends:
		pa = sq(ca, RAIL)
		ta = tops[ca]
		if cb is None:
			pb, tb = end, rail_top(a_end)
		else:
			pb, tb = sq(cb, RAIL), tops[cb]
		d = (pb[0] - pa[0], pb[1] - pa[1])
		L = math.hypot(*d)
		u = (d[0] / L, d[1] / L)
		qa = (pa[0] + u[0] * h2, pa[1] + u[1] * h2)
		qb = (pb[0] - u[0] * h2, pb[1] - u[1] * h2)
		rail(qa, ta + (tb - ta) * h2 / L, qb, tb - (tb - ta) * h2 / L)

		def under(x, z):   # the rail's underside over (x, z)
			t = ((x - pa[0]) * u[0] + (z - pa[1]) * u[1]) / L
			return ta + (tb - ta) * t - BAR - 0.003
		if ca in mids:
			mx, mz, k = mids[ca]
			pier(mx, mz, 0.16, tread_top(k) + 0.002, under(mx, mz))
		posts = [pa, pb] + ([mids[ca][:2]] if ca in mids else [])
		for i in range(STEPS):
			for f in (0.25, 0.75):
				a = STEP * (i + f)
				x, z = sq(a, RAIL)
				t = ((x - pa[0]) * u[0] + (z - pa[1]) * u[1]) / L
				if not (0.0 < t < 1.0) or abs(abs((x - pa[0]) * u[1] - (z - pa[1]) * u[0])) > 0.01:
					continue   # not on this rail's side
				if min(math.hypot(x - p[0], z - p[1]) for p in posts) < 0.25:
					continue
				baluster(x, z, tread_top(i) + 0.002, under(x, z))
	pier(end[0], end[1], PW, tread_top(STEPS - 1) + 0.002, rail_top(a_end) + 0.1)
	# the landing's rail, along its drop (z ≈ 0.11), from the post to a newel at the far edge
	lz = 0.11
	pier(1.83, lz, PW, H - 0.004, H + 0.95)
	lt = H + 0.85
	x0 = math.sqrt(max(0.0, (POST + 0.004) ** 2 - lz ** 2))
	rail((x0, lz), lt, (1.83 - h2, lz), lt)
	for x in (0.72, 1.07, 1.42):
		baluster(x, lz, H - 0.004, lt - BAR - 0.003)
