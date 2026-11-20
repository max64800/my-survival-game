# Hearthbrick v2 roofs (owner, Nov 20, F427): curved terracotta tiles, like the old dwarven kilns made them.
# Each slope, in layers from below (rule 4: a thin panel, open underneath): square dark timber rafters, dark
# underlay boards, then rows of hand-pressed curved tiles: concave "pans" side by side with convex "caps" over
# the joints between them, every row lapping over the one below. A pale limestone eave course along the low edge
# (the same limestone as the walls' corners). Ridge: big round ridge tiles bedded in pale lime mortar.
# Outer corner = a HOLLOW HIP (owner): two slopes meeting on a diagonal capped by ridge tiles in mortar, open
# underneath (a hip rafter), never a pyramid. Inner corner: the tiles stop short of a copper valley flashing.
#   blender --background --factory-startup --python builds/hearthbrick_v2_roofs.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Slope: the same Slope frame as the old Hearthbrick roofs (kit_zone1, top_v 0.2), so gables and sloped walls
# that follow k = (rise - 0.2 - 2 * E_IN) / run sit right under the underlay.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import hearthbrick_v2 as HB  # noqa: E402
import stonehold_v2 as SV  # noqa: E402

E = K.E_IN
TOP_V = 0.2          # vertical thickness budget of a slope (as the old Hearthbrick roofs: gables match)
RAFT_H, RAFT_W = 0.0445, 0.075    # square rafters (perpendicular to the slope)
UL0, UL1 = 0.045, 0.06            # underlay boards
PB, PTH, PSAG, PHW = 0.062, 0.011, 0.024, 0.094   # pans: bottom, thickness, dip, half width
CTH, CSAG, CHW = 0.011, 0.026, 0.068              # caps
CE = PB + PTH + 0.2 * PSAG + 0.003              # cap edges rest just above the pans beside the joint (also where the cap narrows)
PITCH = 0.2
COURSE, LAP = 0.3, 0.07
LIFT = (max(PTH, CTH) + 0.009) / (COURSE / (COURSE + LAP))   # upper row's foot clears the row below
N_TOP = CE + CSAG + CTH + LIFT    # highest tile surface above the underside (perpendicular)
FD = 0.085           # depth of the limestone eave course


def tag(objs, role, **kv):
	for o in objs:
		o["role"] = role
		for k, v in kv.items():
			o[k] = v
	return objs


def since(before):
	return [o for o in bpy.data.objects if o not in before]


def col_range(sl, v, pl):
	"""Where the line at across-position v is inside the planes a*u + b*v <= c, as (d0, d1) along the slope."""
	lo, hi = 0.0, sl.run
	for (a, b, c) in pl:
		A = a * sl.sg
		R = c - b * v - a * sl.ulo
		if abs(A) < 1e-9:
			if R < 0:
				return None
			continue
		if A > 0:
			hi = min(hi, R / A)
		else:
			lo = max(lo, R / A)
	return (lo, hi) if hi > lo else None


def tile_mesh(point, rows, th, m):
	"""A curved tile from profile rows [(x0, d0, n0, x1, d1, n1)...]: point(d, x, n) -> Godot point; n0/n1 =
	the tile's underside at its two ends; the top is th above."""
	verts, faces = [], []
	for (x0, d0, n0, x1, d1, n1) in rows:
		verts += [point(d0, x0, n0), point(d0, x0, n0 + th), point(d1, x1, n1), point(d1, x1, n1 + th)]
	k = len(rows) - 1
	for i in range(k):
		a, b = 4 * i, 4 * (i + 1)
		faces += [(a, b, b + 2, a + 2), (a + 1, a + 3, b + 3, b + 1), (a, a + 1, b + 1, b), (a + 2, b + 2, b + 3, a + 3)]
	faces += [(0, 2, 3, 1), (4 * k, 4 * k + 1, 4 * k + 3, 4 * k + 2)]
	o = K.mesh(verts, faces, m)
	for p in o.data.polygons:
		p.use_smooth = False
	return o


def slope_point(sl):
	cs = math.cos(sl.ang)
	return lambda vc: (lambda d, x, n: sl.P(sl.u(d), vc + x, n / cs))


def tiles(sl, pl, mg=0.004):
	"""Rows of pans and caps over one slope, every tile cut exactly to the planes (diagonals included)."""
	pt = slope_point(sl)
	n_col = int(round((sl.vhi - sl.vlo) / PITCH))
	cs = math.cos(sl.ang)
	CO, LA = COURSE * cs, LAP * cs   # d runs level: rows are the same tile length on gentle and steep roofs
	i = 0
	while i * CO < sl.run - 0.06:
		c0, c1 = i * CO, min(i * CO + CO + LA, sl.run)
		lift = lambda d, c0=c0: LIFT * max(0.0, 1 - (d - c0) / (CO + LA))
		for kind in ("pan", "cap"):
			centres = [sl.vlo + PITCH / 2 + PITCH * j for j in range(n_col)] if kind == "pan" else [sl.vlo + PITCH * j for j in range(n_col + 1)]
			for j, vc in enumerate(centres):
				# side faces of tiles in neighbouring rows (and at the piece's edges) never share a plane (shimmer):
				# each column keeps its own small offset, every other row is 3.5 % narrower, edge margins differ
				edge_col = j == 0 or j == len(centres) - 1
				if not edge_col:   # (edge columns stay put: their ends are spaced from the edge cuts below)
					vc += ((j * 7919 + (0 if kind == "pan" else 3)) % 9 - 4) * 0.001
				hw = (PHW if kind == "pan" else CHW) * (1.0 if i % 2 else 0.965)
				# one dip per column (rows lapping over each other keep a steady gap: no shimmer in the lap)
				sag = (PSAG if kind == "pan" else CSAG) * (0.88 + 0.2 * ((j * 31 + (0 if kind == "pan" else 2)) % 7) / 6)
				tap = 1.0 if kind == "pan" else 0.93    # caps narrow toward their top end
				em = (0.002 if kind == "pan" else 0.0075) + 0.0025 * (i % 2)
				xa = max(-hw, sl.vlo + E + em - vc)
				xb = min(hw, sl.vhi - E - em - vc)
				cut_a, cut_b = xa > -hw, xb < hw   # cut by the piece's edge: that side stays straight (no taper)
				if xb - xa < 0.035:
					continue
				dn = K.rng.uniform(-0.002, 0.0) if kind == "pan" else K.rng.uniform(0.001, 0.003)   # caps never sink onto pans
				tilt = K.rng.uniform(-0.001, 0.001)
				rows, run_ = [], []
				kk = 4
				for s in range(kk + 1):
					fs = s / kk + (0.04 if i % 2 and 0 < s < kk else 0.0)   # a tile cut at a hip keeps an inner line as its side: rows differ
					x = xa + (xb - xa) * fs
					xn = x / hw
					xt = x if (s == 0 and cut_a) or (s == kk and cut_b) else x * tap
					r0, r1 = col_range(sl, vc + x, pl), col_range(sl, vc + xt, pl)
					if not r0 or not r1:
						run_.append(None)
						continue
					ce = 0.008 if kind == "cap" else 0.0   # caps start/stop 8 mm in from the pans: their ends never share a plane
					top_c = c1 if kind == "pan" else min(c1, c0 + CO)   # caps end where the next row's pans begin (they sit higher)
					d0, d1 = max(c0 + ce + (0.004 if i == 0 else 0.0), r0[0] + mg), min((top_c - 0.004 if top_c >= sl.run else top_c) - ce, r1[1] - mg)
					if d1 - d0 < (0.03 if kind == "pan" else 0.09):   # a tiny cap with no pans under it would float
						run_.append(None)
						continue
					if kind == "pan":
						nb = PB + sag * xn * xn
					else:
						nb = CE + sag * (1 - xn * xn)
					nb += dn + tilt * xn
					run_.append((x, d0, nb + lift(d0), xt, d1, nb + lift(d1)))
				best, cur = [], []
				for r in run_ + [None]:
					if r is None:
						if len(cur) > len(best):
							best = cur
						cur = []
					else:
						cur.append(r)
				if len(best) < 2:
					continue
				o = tile_mesh(pt(vc), best, PTH if kind == "pan" else CTH, HB.m_brick())
				tag([o], "brick", dark=K.rng.random() < 0.08)
		i += 1


def box_between(pa, pb, side, up, w, h, m, role):
	"""A square timber from pa to pb (its bottom middle line), w wide along `side`, h tall along `up`."""
	pa, pb, side, up = Vector(pa), Vector(pb), Vector(side).normalized(), Vector(up)
	vs = []
	for p in (pa, pb):
		for sx in (-1, 1):
			for hh in (0.0, h):
				vs.append(tuple(p + side * (sx * w / 2) + up * hh))
	f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
	o = K.mesh(vs, f, m)
	tag([o], role)
	return o


def normal(sl):
	a = Vector(sl.P(sl.u(0.0), 0.0, 0.0))
	b = Vector(sl.P(sl.u(1.0), 0.0, 0.0))
	c = Vector(sl.P(sl.u(0.0), 1.0, 0.0))
	n = (b - a).cross(c - a).normalized()
	return n if n.y > 0 else -n


def slope_panel(sl, extra=(), eave=True, rafters=(-0.72, 0.0, 0.72), tile_cut=()):
	"""Rafters, underlay, limestone eave course and tiles for one slope."""
	cs = math.cos(sl.ang)
	pl = sl.planes(list(extra))
	nrm = normal(sl)
	side = (1, 0, 0) if sl.axis == "z" else (0, 0, 1)
	d_start = FD + 0.004 if eave else 0.0
	for v in rafters:
		r = None
		rr = [col_range(sl, v + s * RAFT_W / 2, pl) for s in (-1, 1)]
		if all(rr):
			r = (max(x[0] for x in rr), min(x[1] for x in rr))
		if not r or r[1] - r[0] < 0.3:
			continue
		d0, d1 = max(r[0] + 0.005, d_start), r[1] - 0.006
		box_between(sl.P(sl.u(d0), v, 0.0), sl.P(sl.u(d1), v, 0.0), side, nrm, RAFT_W, RAFT_H, kit.tex_mat("wood", "dark"), "timber")
	before = set(bpy.data.objects)
	sl.strip(d_start - (0.001 if eave else 0.0), sl.run, sl.vlo, sl.vhi, pl, lambda u: UL0 / cs, lambda u: UL1 / cs, kit.tex_mat("wood", "dark"))
	tag(since(before), "timber")
	if eave:   # the limestone eave course, in blocks, mitred where it meets a hip
		v = sl.vlo
		while v < sl.vhi - 0.01:
			nv = min(sl.vhi, v + K.rng.uniform(0.42, 0.62))
			if sl.vhi - nv < 0.25:
				nv = sl.vhi
			before = set(bpy.data.objects)
			sl.strip(0.0, FD, v + 0.002, nv - 0.002, pl, lambda u: 0.0, lambda u: (UL1 - 0.004) / cs, HB.m_lime(), min_area=0.002)
			for o in since(before):
				b = o.modifiers.new("chisel", "BEVEL")
				b.width, b.segments, b.limit_method, b.angle_limit = 0.008, 1, "ANGLE", math.radians(35)
			tag(since(before), "lime")
			v = nv
	tiles(sl, sl.planes(list(extra) + list(tile_cut)))


def top_h(sl):
	"""Height (vertical, above the underside line) of the highest tile surface."""
	return N_TOP / math.cos(sl.ang)


# ---------------- pieces ----------------
def roof(w=2.0, rise=1.0, dd=2.0):
	sl = K.Slope("z", dd / 2, -dd / 2, rise, TOP_V, vlo=-w / 2, vhi=w / 2)
	slope_panel(sl)


def ridge_tiles(x0, x1, y_edge, hw=0.13, sag=0.075, th=0.014, n=5):
	"""Big round ridge tiles along x, each lapping over the next, edges at y_edge (bedded in mortar)."""
	L = (x1 - x0) / n
	for i in range(n):
		a, b = x0 + L * i, min(x1, x0 + L * (i + 1) + 0.06)
		sg = K.rng.uniform(0.95, 1.05) * sag
		dy = K.rng.uniform(0.0, 0.003)
		rows = []
		for s in range(7):
			x = -hw + 2 * hw * s / 6
			xn = x / hw
			nb = y_edge + dy + sg * (1 - xn * xn)
			rows.append((x, 0.0, nb + 0.022, x * 0.93, b - a, nb))
		pt = (lambda a_: (lambda d, x, nn: (a_ + d, nn, x)))(a)
		tag([tile_mesh(pt, rows, th, HB.m_brick())], "brick", dark=K.rng.random() < 0.1)


def prism(points_fn, n, m, role):
	"""A bed along a line: points_fn(f) -> the cross-section [Godot points] at fraction f; n segments."""
	secs = [points_fn(i / n) for i in range(n + 1)]
	k = len(secs[0])
	verts = [p for s in secs for p in s]
	faces = [tuple(range(k)), tuple(range(n * k + k - 1, n * k - 1, -1))]
	for i in range(n):
		for j in range(k):
			a, b = i * k + j, i * k + (j + 1) % k
			faces.append((a, b, b + k, a + k))
	o = K.mesh(verts, faces, m)
	tag([o], role)
	return o


def ridge(w=2.0, rise=0.5, dd=2.0):
	"""Two short slopes leaning on a dark ridge beam, the peak closed by big round ridge tiles on pale mortar."""
	capd = 0.11
	sls = []
	for lo in (dd / 2, -dd / 2):
		sl = K.Slope("z", lo, 0.0, rise - capd, TOP_V, vlo=-w / 2, vhi=w / 2)
		slope_panel(sl)
		sls.append(sl)
	sl = sls[0]
	cs = math.cos(sl.ang)
	y_at = lambda z, h: sl.y0 + sl.k * (sl.run - abs(z)) + h
	# the ridge beam under the peak
	bw = 0.1
	yt = y_at(bw / 2, UL0 / cs) - 0.002   # just under the underlay: the rafters rest in it
	before = set(bpy.data.objects)
	K.blk((0, yt - 0.04, 0), (w - 2 * E - 0.02, 0.08, bw), kit.tex_mat("wood", "dark"), bevel=0.006)
	tag(since(before), "timber")
	hw = 0.13
	y_edge = y_at(hw, N_TOP / cs) + 0.004
	sag = min(0.075, rise - E - 0.014 - 0.022 - y_edge - 0.004)
	ridge_tiles(-w / 2 + E, w / 2 - E, y_edge, hw=hw, sag=sag)
	a = hw - 0.02

	def sec(f):
		x = -w / 2 + E + 0.018 + (w - 2 * E - 0.036) * f   # ends clear of the tiles' cut edges
		top = lambda z: y_edge + sag * (1 - (z / hw) ** 2) - 0.004
		bot = lambda z: y_at(z, UL1 / cs) - 0.004
		return [(x, bot(-a), -a), (x, bot(0.0), 0.0), (x, bot(a), a), (x, top(a), a), (x, top(0.0), 0.0), (x, top(-a), -a)]
	prism(sec, 1, HB.m_mortar(), "mortar")


def roof_corner(w=2.0, rise=1.0, dd=2.0, inner=False):
	g = 0.005
	cut = [(-1.0, 1.0, -g)] if not inner else [(1.0, -1.0, -g)]
	slz = K.Slope("z", dd / 2, -dd / 2, rise, TOP_V, vlo=-w / 2, vhi=w / 2)
	slx = K.Slope("x", w / 2, -w / 2, rise, TOP_V, vlo=-dd / 2, vhi=dd / 2)
	cs = math.cos(slz.ang)
	k = slz.k
	r2 = math.sqrt(2)
	if inner:   # tiles stop short of the valley flashing; the underlay runs to the valley
		tcut = [(1.0, -1.0, -0.13)]
		for sl in (slz, slx):
			slope_panel(sl, cut, eave=False, tile_cut=tcut)   # no level eave: its outer edges slope down to the low corner
	else:
		for sl in (slz, slx):
			slope_panel(sl, cut, eave=True)

	def H(u):   # the diagonal (u = z = x): its underside height
		return slz.y0 + k * (dd / 2 - u)
	s_dir = Vector((1, 0, -1)).normalized()   # across the diagonal, level
	u0, u1 = dd / 2 - E - 0.01, -dd / 2 + E + 0.01

	def at(f, x, y):
		u = u0 + (u1 - u0) * f
		p = Vector((u, 0, u)) + s_dir * x
		lim_x, lim_z = w / 2 - E - 0.002, dd / 2 - E - 0.002   # the ends of the diagonal stay inside the box
		return (max(-lim_x, min(lim_x, p.x)), y, max(-lim_z, min(lim_z, p.z)))
	# the hip / valley rafter along the diagonal (its top edges meet the underside)
	rw = 0.08
	drop = k * (rw / 2) / r2
	top_off = -drop if not inner else 0.0
	f_lo = 0.0
	while H(u0 + (u1 - u0) * f_lo) + top_off - 0.07 < 0.004:
		f_lo += 0.01
	pa = at(f_lo, 0.0, H(u0 + (u1 - u0) * f_lo) + top_off - 0.07)
	pb = at(0.985, 0.0, H(u0 + (u1 - u0) * 0.985) + top_off - 0.07)
	box_between(pa, pb, s_dir, (0, 1, 0), rw, 0.07 - 0.001, kit.tex_mat("wood", "dark"), "timber")
	if inner:
		# the copper valley flashing: one bent sheet across the diagonal, on the underlay
		hw = 0.17
		nf = 8

		def sec(f):
			u = u0 + (u1 - u0) * f
			y = lambda x: H(u) + k * abs(x) / r2 + UL1 / cs + 0.002   # the valley rises to both sides
			ys = [min(rise - E - 0.004, y(x)) for x in (-hw, 0.0, hw)]
			pts = [at(f, -hw, ys[0]), at(f, 0.0, ys[1]), at(f, hw, ys[2]), at(f, hw, ys[2] + 0.008), at(f, 0.0, ys[1] + 0.008), at(f, -hw, ys[0] + 0.008)]
			return pts
		prism(sec, nf, kit.tex_mat("copper", "b"), "copper")
		return
	# the hollow hip: a mortar bed along the diagonal and big round hip tiles on it
	hw = 0.13
	y_tile = N_TOP / cs
	edge = lambda u: H(u) + y_tile - k * hw / r2 + 0.006   # the tiles' tops beside the hip
	sag = 0.04 + k * hw / r2
	th = 0.014
	lim = rise - E - 0.002
	n = 6
	f_hi = 0.98
	while edge(u0 + (u1 - u0) * f_hi) + sag + th + 0.022 > lim and f_hi > 0.5:
		f_hi -= 0.01
	L = f_hi / n
	diag_len = (u0 - u1) * r2
	up_dir = None
	for i in range(n):
		fa, fb = L * i, min(f_hi, L * (i + 1) + 0.03)
		rows = []
		for s in range(7):
			x = -hw + 2 * hw * s / 6
			xn = x / hw
			ra = edge(u0 + (u1 - u0) * fa) + sag * (1 - xn * xn) + K.rng.uniform(0, 0.002)
			rb = edge(u0 + (u1 - u0) * fb) + sag * (1 - xn * xn)
			rows.append((x, fa, ra + 0.022, x * 0.93, fb, rb))
		pt = lambda f, x, y: at(f, x, y)
		tag([tile_mesh(pt, rows, th, HB.m_brick())], "brick", dark=K.rng.random() < 0.1)
	a = hw - 0.02

	def bed(f):
		f = 0.02 + (0.975 - 0.02) * f
		u = u0 + (u1 - u0) * f
		top = lambda x: min(lim - 0.004, edge(u) + sag * (1 - (x / hw) ** 2) - 0.004) if f <= f_hi + 0.03 else min(lim - 0.004, H(u) + y_tile + 0.004)
		bot = lambda x: H(u) + UL1 / cs - k * abs(x) / r2 - 0.004
		return [at(f, -a, bot(-a)), at(f, 0.0, bot(0.0)), at(f, a, bot(a)), at(f, a, max(bot(a) + 0.01, top(a))), at(f, 0.0, max(bot(0) + 0.01, top(0.0))), at(f, -a, max(bot(-a) + 0.01, top(-a)))]
	prism(bed, 12, HB.m_mortar(), "mortar")


PIECES = {
	"roof_26": lambda: roof(2.0, 1.0), "roof_45": lambda: roof(2.0, 2.0),
	"roof_26_ridge": lambda: ridge(2.0, 0.5), "roof_45_ridge": lambda: ridge(2.0, 1.0),
	"roof_26_outer": lambda: roof_corner(2.0, 1.0), "roof_45_outer": lambda: roof_corner(2.0, 2.0),
	"roof_26_inner": lambda: roof_corner(2.0, 1.0, inner=True), "roof_45_inner": lambda: roof_corner(2.0, 2.0, inner=True),
}


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
		print("PIECE_OK", name)
