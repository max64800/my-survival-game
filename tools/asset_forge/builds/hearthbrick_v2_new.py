# Hearthbrick v2, the new pieces (owner, Nov 21: "rebuild all of the pieces that were missing for all three of
# them"): corner stairs, spiral stairs, stair railing, and the batch-2 pieces. Same look as the approved
# Hearthbrick wall (hearthbrick_v2.py): bumpy hand-pressed bricks in pale lime mortar, rough limestone, dark
# timber, hammered copper. Plan: docs/design/new-pieces-plan.md.
#   blender --background --factory-startup --python builds/hearthbrick_v2_new.py -- [grey] [out=<folder>] [install=1] [piece ...]
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402   (also sets the new pieces' outline sizes)
import hearthbrick_v2 as HB  # noqa: E402
import hearthbrick_v2_round as HR  # noqa: E402
import hearthbrick_v2_walls as HW  # noqa: E402
import new_pieces_common as NC  # noqa: E402

E = HB.E
MORT = HB.MORT
blk = K.blk


def _brick_slab(poly, y0, y1, dark=None):
	"""One hand-pressed brick seen from above (any outline), the mortar gap taken off all round."""
	before = set(bpy.data.objects)
	m = kit.tex_mat("brick", "dark") if dark else HB.m_brick()
	o = SV.slab_xz(SV._inset(poly, MORT / 2), y0 + MORT / 2, y1 - MORT / 2 - K.rng.uniform(0, 0.003), m,
		c=K.rng.uniform(0.009, 0.013), role="brick")
	HB.tag(HB.since(before), "brick")
	o["dark"] = bool(dark)
	return o


def _lime_slab(poly, y0, y1):
	o = SV.slab_xz(SV._inset(poly, 0.002), y0 + 0.0015, y1, HB.m_lime(), c=K.rng.uniform(0.02, 0.03), role="lime")
	return o


def _mortar_slab(poly, y0, y1, c=0.014):
	before = set(bpy.data.objects)
	SV.slab_xz(SV._inset(poly, c), y0, y1, HB.m_mortar(), c=0.004, role="mortar")
	HB.tag(HB.since(before), "mortar")


def _brick_pier(cx, cz, pw, y0, y1):
	"""A square brick pier: a rough limestone foot, courses of two bricks each (turned every other course, like
	a real pier), a mortar core the joints show, a limestone cap."""
	foot, cap = 0.15, 0.12
	HR.lime_block((cx, y0 + foot / 2 + 0.001, cz), (pw - 0.004, foot - 0.004, pw - 0.004))
	HR.lime_block((cx, y1 - cap / 2, cz), (pw - 0.004, cap - 0.003, pw - 0.004))
	a, b = y0 + foot, y1 - cap
	before = set(bpy.data.objects)
	blk((cx, (a + b) / 2, cz), (pw - 0.03, b - a - 0.006, pw - 0.03), HB.m_mortar(), bevel=0)
	HB.tag(HB.since(before), "mortar")
	n = max(2, round((b - a) / HB._CH))
	ch = (b - a) / n
	h2 = pw / 2
	for c in range(n):
		ya, yb = a + ch * c, a + ch * (c + 1)
		for s in (-1, 1):
			if c % 2:
				poly = [(cx - h2, cz + s * h2), (cx + h2, cz + s * h2), (cx + h2, cz), (cx - h2, cz)]
			else:
				poly = [(cx + s * h2, cz - h2), (cx + s * h2, cz + h2), (cx, cz + h2), (cx, cz - h2)]
			if s < 0:
				poly = list(reversed(poly))
			_brick_slab(_ccw(poly), ya, yb, dark=K.rng.random() < 0.07)


def _ccw(poly):
	"""Outline turned the way slab_xz wants it (counter-clockwise seen from above, in x / -z)."""
	a = sum(poly[i][0] * -poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * -poly[i][1] for i in range(len(poly)))
	return poly if a > 0 else list(reversed(poly))


# ---------------- corner stairs ----------------
def stairs_corner(w=2.0, h=2.0, dd=2.0, n=8):
	"""Corner stairs: 8 brick steps fan a quarter turn round a square brick pier in the front-left corner, 2 m up
	in one cell. Each step is built of brick courses cut to its wedge (half bond, the joints moving course to
	course) round a hidden mortar core, with a rough limestone tread on top."""
	cx, cz = -w / 2 + E, dd / 2 - E
	X1, Z0 = w / 2 - E, -dd / 2 + E
	pw = 0.3
	rise = (h - E) / n

	def ray(a):
		return math.cos(a), -math.sin(a)

	def far(a):
		dx, dz = ray(a)
		return min((X1 - cx) / dx if dx > 1e-6 else 9, (Z0 - cz) / dz if dz < -1e-6 else 9)

	def near(a):
		dx, dz = ray(a)
		return min(pw / dx if dx > 1e-6 else 9, pw / -dz if dz < -1e-6 else 9) + 0.004

	def pt(a, t):
		dx, dz = ray(a)
		return (cx + dx * t, cz + dz * t)

	ca = math.atan2(-(Z0 - cz), X1 - cx)

	def piece(a0, a1, s0, s1):
		m0a, m1a = near(a0) + s0 * (far(a0) - near(a0)), near(a1) + s0 * (far(a1) - near(a1))
		m0b, m1b = near(a0) + s1 * (far(a0) - near(a0)), near(a1) + s1 * (far(a1) - near(a1))
		corner = [(X1, Z0)] if (s1 >= 0.999 and a0 < ca < a1) else []
		return _ccw([pt(a0, m0a), pt(a0, m0b)] + corner + [pt(a1, m1b), pt(a1, m1a)])

	_brick_pier(cx + pw / 2, cz - pw / 2, pw, E, h - E)
	for i in range(n):
		a0, a1 = math.radians(90 * i / n), math.radians(90 * (i + 1) / n)
		top = E + (i + 1) * rise - (E if i == n - 1 else 0.0)
		ch = rise / 2
		_mortar_slab(piece(a0, a1, 0.0, 1.0), E + 0.03, top - ch + 0.03)
		for k in range(i + 1):
			for c in range(2):
				ya = E + k * rise + c * ch
				yb = min(top, ya + ch)
				if k == i and c == 1:   # the limestone tread: an inner and an outer stone
					s = 0.5 + K.J(0.08)
					for (s0, s1) in ((0.0, s), (s, 1.0)):
						_lime_slab(piece(a0, a1, s0, s1), ya, yb)
					continue
				# brick course: 4-5 bricks running out from the pier, joints staggered course to course
				nb = 5 if (k + c) % 2 else 4
				ss = [0.0] + [(j + K.rng.uniform(-0.12, 0.12)) / nb for j in range(1, nb)] + [1.0]
				for j in range(nb):
					_brick_slab(piece(a0, a1, ss[j], ss[j + 1]), ya, yb, dark=K.rng.random() < 0.06)


# ---------------- spiral stairs ----------------
def stairs_spiral(w=2.0, h=2.0, dd=2.0, n=12):
	"""Spiral stairs: a round brick column (curved bricks round a mortar core, a limestone foot drum) and 12
	rough limestone treads set into it, one full turn up 2 m in one cell. Each tread overlaps the one below a
	little, so from above there are no gaps; every tread is two stones, an inner and an outer one."""
	R = min(w, dd) / 2 - E - 0.03
	r_out, r_in = 0.19, 0.08
	foot = 0.2
	HR.lime_ring(E, foot, 0.06, r_out, 5, K.rng.uniform(0, 1))
	HR.mortar_core(foot + 0.002, h - E - 0.004, r_out - 0.03)
	HR.courses(foot, h - E, r_in, r_out)
	tt = 0.13
	ri = r_out - 0.008   # set a little into the column (its bricks sit up to 1.2 cm sunk)
	step = math.tau / n
	for i in range(n):
		a0, a1 = step * i, step * (i + 1) + 0.05
		top = E + (h - 2 * E) * (i + 1) / n
		rm = ri + (R - ri) * (0.48 + K.J(0.06))
		for (ra, rb) in ((ri, rm), (rm, R)):
			pts = [(rb * math.cos(a0 + (a1 - a0) * k / 5), -rb * math.sin(a0 + (a1 - a0) * k / 5)) for k in range(6)]
			kn = 3 if ra == ri else 5
			pts += [(ra * math.cos(a1 - (a1 - a0) * k / kn), -ra * math.sin(a1 - (a1 - a0) * k / kn)) for k in range(kn + 1)]
			_lime_slab(_ccw(pts), top - tt, top)


# ---------------- stair railing ----------------
def railing_stairs(w=2.0, h=3.0, d=0.15):
	"""The stair railing (owner: dark wood, like a real railing): the same turned dark-timber railing with
	copper-banded newels as Stonehold's, painted with the Hearthbrick timber and copper."""
	SV.railing_stairs(w, h, d)


# ---------------- batch 2 ----------------
K.SIZE.update({"roof_cap": (1.1, 0.5, 1.1)})


def sloped_wall_down():
	"""Upside-down sloped wall: the Hearthbrick sloped wall turned half a turn round its front-back line (full
	along the top, the limestone trim now running along the slanted underside)."""
	HW.sloped_wall()
	NC.flip_down(2.0)


def edge_strip(w=2.0, h=0.3, d=0.07):
	"""A thin brick lip along a floor's edge: three courses of bricks laid on their side (joints staggered) round
	a mortar core, under a rough limestone coping."""
	x0, x1 = -w / 2 + E, w / 2 - E
	z0, z1 = -d / 2 + E, d / 2 - E
	cap = 0.075
	yb = h - E - cap
	_mortar_slab(_ccw([(x0, z0), (x1, z0), (x1, z1), (x0, z1)]), E + 0.02, yb - 0.004, c=0.012)
	n_c = 3
	ch = (yb - E) / n_c
	for c in range(n_c):
		ya, yc = E + c * ch, E + (c + 1) * ch
		cuts = [x0] + [x0 + (j + (0.5 if c % 2 else 0.0) + K.rng.uniform(-0.1, 0.1)) * 0.26 for j in range(1, 8)] + [x1]
		cuts = sorted(min(x1, max(x0, v)) for v in cuts)
		for a, b in zip(cuts, cuts[1:]):
			if b - a > 0.06:
				_brick_slab(_ccw([(a, z0), (b, z0), (b, z1), (a, z1)]), ya, yc, dark=K.rng.random() < 0.07)
	xm = K.J(0.3)
	for (a, b) in ((x0, xm - 0.002), (xm + 0.002, x1)):
		_lime_slab(_ccw([(a, z0), (b, z0), (b, z1), (a, z1)]), yb, h - E)


def floor_hatch(w=2.0, h=0.25, dd=2.0):
	"""Floor with a round hatch: the Hearthbrick floor with a round hole near its front, lined with a ring of six
	curved limestones, and the round dark-timber lid (copper straps, hinge knuckles) swung open behind it."""
	HB.floor(w, h, dd)
	cx, cz, r_in, r_out = SV.HATCH
	NC.cut_round_hole(cx, cz, r_out + 0.003, deeper=("mortar",))
	n = 6
	for i in range(n):
		a0, a1 = math.tau * i / n + 0.004 / r_out, math.tau * (i + 1) / n - 0.004 / r_out
		o = NC.ring_mesh(cx, cz, r_in, r_out, E + 0.003, h - E - 0.004, HB.m_lime(), n=8, a0=a0, a1=a1)
		NC.bevel(o, 0.01)
		o["role"] = "lime"
	SV._hatch_lid(h)


def lattice_wall(w=2.0, h=2.0, d=0.3):
	"""Open lattice wall: two brick piers (limestone foot and cap), a limestone sill and lintel between them, and
	a see-through lattice of dark timber laths crossing on the diagonal, a copper stud at every crossing."""
	pw, sill, lint = 0.28, 0.2, 0.24
	x0, x1 = -w / 2 + E, w / 2 - E
	for sx in (-1, 1):
		_brick_pier(sx * (x1 - pw / 2), 0.0, pw, E, h - E)
	dd = 0.24
	for (ya, yb) in ((E + 0.003, sill), (h - E - lint, h - E - 0.003)):
		xm = K.J(0.25)
		for (a, b) in ((x0 + pw + 0.004, xm - 0.002), (xm + 0.002, x1 - pw - 0.004)):
			HR.lime_block(((a + b) / 2, (ya + yb) / 2, 0.0), (b - a, yb - ya, dd), free="yz")
	ox0, ox1, oy0, oy1 = x0 + pw - 0.02, x1 - pw + 0.02, sill - 0.02, h - E - lint + 0.02
	pts = NC.lattice(ox0, ox1, oy0, oy1, 0.0, 0.34, 0.065, 0.075, lambda: kit.tex_mat("wood", "dark"), "timber")
	before = set(bpy.data.objects)
	for (x, y) in pts:
		kit.rivet(K.G((x, y, 0.075 * 0.82 + 0.002)), kit.tex_mat("copper", "dark"), r=0.013)
	HB.tag(HB.since(before), "copper")


def roof_cap():
	"""Roof peak cap: closes the tip where four sloped roofs meet. Four faces of clay tiles in overlapping rows
	(open underneath, like the roof pieces) and a ridge-tile strip along each hip; no knob on top (owner)."""
	NC.pyramid_cap(0.49, E + 0.026, 0.40, 4, 0.03, HB.m_brick, "tile", HB.m_brick, "ridge")


PIECES = {"stairs_corner": stairs_corner, "stairs_spiral": stairs_spiral, "railing_stairs": railing_stairs,
	"sloped_wall_down": sloped_wall_down, "edge_strip": edge_strip, "floor_hatch": floor_hatch,
	"lattice_wall": lattice_wall, "roof_cap": roof_cap}


def paint():
	HW.paint()   # HB.paint plus the wall pieces' band and roundel faces


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
			paint()
		png = str(K.JOUR / f"{name}__clay_brick.png") if install else None
		kit.save(str(out_dir / f"{name}__clay_brick.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
