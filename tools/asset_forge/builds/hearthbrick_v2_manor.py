# Hearth Manor (owner, Nov 21: ruin 7, a grand Hearthbrick manor, docs/design/GRAND-RUIN-RECIPE.md; the owner's wish:
# "more roofs ... and maybe some balconies"): the new Hearthbrick pieces the manor needs. Same look as the approved
# Hearthbrick wall (hearthbrick_v2.py): bumpy hand-pressed bricks in pale lime mortar, rough limestone, dark timber,
# curved terracotta roof tiles. Pieces are centred in their box like every piece; front (outward) is +z.
#   corbel          a bracket under a floor that juts 1 m out past the wall below (jetties, balconies, the tower's
#                   gallery): a rounded limestone drop, five brick courses each stepping further out, a limestone
#                   cap reaching the jutting floor's edge. Its back 1 cm off the wall's face.
#   cornice         a trim band at a floor line (2 m) on a wall's outside face: a limestone string course, a row of
#                   little brick teeth (dentils), a brick course and a limestone coping, each stepping further out.
#   cornice_corner  the band's outer corner block.
#   railing_narrow  a 1 m railing (one little arch) for the 1 m ends of a balcony.
#   dormer          a little roof window that sits on a steep roof slope (roof_45, same cell, same turn): a brick
#                   front with a round-topped leaded window, its own little tiled gable roof with ridge tiles,
#                   dark timber boarded sides; its roof runs back into the big roof's tiles.
# Saved in journey/hearthbrick_v2/glb until the owner's OK (not game pieces yet); install=1 puts them in the game.
#   blender --background --factory-startup --python builds/hearthbrick_v2_manor.py -- [grey] [out=<folder>] [install=1] [piece ...]
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402
import hearthbrick_v2 as HB  # noqa: E402
import hearthbrick_v2_walls as HW  # noqa: E402
import hearthbrick_v2_roofs as HR  # noqa: E402

E = HB.E
MORT = HB.MORT
SIZES = {"corbel": (0.5, 1.0, 0.82), "cornice": (2.0, 0.4, 0.17), "cornice_corner": (0.32, 0.4, 0.32),
	"railing_narrow": (1.0, 1.0, 0.15), "dormer": (2.0, 2.0, 2.0)}
K.SIZE.update(SIZES)


def meshes():
	return [o for o in bpy.data.objects if o.type == "MESH"]


def side():
	"""Outlines drawn as (z, y) (z = out from the wall), extruded across the piece's width (x)."""
	return K.Frame(yaw=-90)


def stone(pts, w, role, m):
	o = SV.prism(side(), pts, 0.0, w, m, cut=0.016, role=role)
	HB.tag([o], role)
	return o


def place(objs, yaw_deg, t):
	"""Turn objects about the up axis (Godot yaw) and move them by t (Godot x, y, z)."""
	mt = Matrix.Translation(Vector(K.G(t))) @ Matrix.Rotation(math.radians(yaw_deg), 4, "Z")
	for o in objs:
		o.matrix_world = mt @ o.matrix_world


# ---------------- the corbel ----------------
def corbel():
	"""Limestone drop, five brick courses stepping out (two bricks deep each, joints swapped course to course,
	a mortar core behind them), a limestone cap reaching the jutting floor's edge."""
	b = -0.41 + E
	f = 0.41 - E
	lime = HB.m_lime
	foot = [(b, E), (b + 0.15, E)] + [(b + 0.15 + 0.13 * math.sin(math.radians(a)), E + 0.19 * (1 - math.cos(math.radians(a))))
		for a in (25, 50, 75)] + [(b + 0.29, 0.2), (b, 0.2)]
	stone(foot, 0.34, "lime", lime())
	y = 0.203
	ch = 0.114
	before = set(bpy.data.objects)
	K.blk(((b + b + 0.3) / 2 - 0.0, (0.2 + 0.78) / 2, 0), (0.28, 0.57, 0.3), HB.m_mortar(), bevel=0)   # (Godot: x is out)
	for o in HB.since(before):   # the core sits behind the bricks: turn it to run out from the wall
		o.matrix_world = Matrix.Rotation(math.radians(-90), 4, "Z") @ o.matrix_world
	HB.tag(HB.since(before), "mortar")
	for c in range(5):
		reach = 0.36 + 0.075 * c
		w = 0.4 if c % 2 == 0 else 0.44
		split = b + (0.2 if c % 2 == 0 else 0.15) + K.rng.uniform(-0.02, 0.02)
		for (z0, z1) in ((b, split - MORT / 2), (split + MORT / 2, b + reach)):
			o = stone([(z0, y), (z1, y), (z1, y + ch - 0.003), (z0, y + ch - 0.003)], w, "brick",
				kit.tex_mat("brick", "dark") if K.rng.random() < 0.12 else HB.m_brick())
		y += ch
	cap = [(b, y), (f - 0.05, y), (f, y + 0.05), (f, 1.0 - E), (b, 1.0 - E)]
	stone(cap, 0.5 - 2 * E - 0.002, "lime", lime())


# ---------------- the cornice and its corner ----------------
BACK = -0.085 + E
# (y0, y1, out from the back, what)
COURSES = [(E, 0.085, 0.07, "lime"), (0.088, 0.215, 0.05, "teeth"), (0.218, 0.305, 0.125, "brick"), (0.308, 0.4 - E, 0.158, "lime")]


def cornice(w=2.0):
	x0, x1 = -w / 2 + E, w / 2 - E
	for (y0, y1, f, kind) in COURSES:
		if kind == "lime":
			cuts = [x0]
			while cuts[-1] < x1 - 0.01:
				nx = min(x1, cuts[-1] + K.rng.uniform(0.5, 0.75))
				if x1 - nx < 0.3:
					nx = x1
				cuts.append(nx)
			for a, c in zip(cuts, cuts[1:]):
				HB.tag([HB.cbox(((a + c) / 2, (y0 + y1) / 2, BACK + f / 2), (c - a - 0.004, y1 - y0, f), HB.m_lime(),
					cut=0.012, dent=0.008, free="yz")], "lime")
		elif kind == "teeth":
			# a brick backing band, little brick teeth standing out of it every 18 cm
			for (a, c) in HB.lay_row(x0, x1, 0.0):
				HB.tag([HB.cbox(((a + c) / 2, (y0 + y1) / 2, BACK + f / 2), (c - a - MORT, y1 - y0, f), HB.m_brick(),
					cut=0.008, dent=0.006, free="z")], "brick")
			n = int(round((x1 - x0) / 0.18))
			for i in range(n):
				cx = x0 + (i + 0.5) * (x1 - x0) / n
				HB.tag([HB.cbox((cx, (y0 + y1) / 2 - 0.004, BACK + f + 0.04), (0.085, y1 - y0 - 0.012, 0.08),
					kit.tex_mat("brick", "dark") if K.rng.random() < 0.15 else HB.m_brick(), cut=0.008, dent=0.005, free="xz")], "brick")
		else:
			for (a, c) in HB.lay_row(x0, x1, K.rng.uniform(0.1, 0.17)):
				HB.tag([HB.cbox(((a + c) / 2, (y0 + y1) / 2, BACK + f / 2), (c - a - MORT, y1 - y0, f), HB.m_brick(),
					cut=0.01, dent=0.006, free="yz")], "brick")


def cornice_corner():
	lo = -0.16 + E
	for (y0, y1, f, kind) in COURSES:
		hi = (f + 0.08 if kind == "teeth" else f) - 0.008
		m = HB.m_lime() if kind == "lime" else HB.m_brick()
		HB.tag([HB.cbox(((lo + hi) / 2, (y0 + y1) / 2, (lo + hi) / 2), (hi - lo, y1 - y0 - 0.003, hi - lo), m,
			cut=0.012, dent=0.006, free="xyz")], "lime" if kind == "lime" else "brick")


# ---------------- the 1 m railing ----------------
def railing_narrow(w=1.0, h=1.0, d=0.15):
	"""The Hearthbrick railing (hearthbrick_v2_frame.railing) 1 m long: one little arch in its middle."""
	p = HB.Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	y_pl, y_cop = 0.13, h - E - 0.15
	nc = 6
	ch = (y_cop - y_pl) / nc
	spring = y_pl + 2 * ch
	R, r_out = 0.14, 0.22
	HB.arch_backing(p, x0 + 0.01, x1 - 0.01, y_pl + 0.004, y_cop - 0.004, 0.0, y_pl + 0.004, spring, R + 0.009, d, depth=0.5)
	for (ya, yb) in ((E, y_pl), (y_cop, h - E)):
		m = x0 + (x1 - x0) * K.rng.uniform(0.42, 0.58)
		HB.stone(p, x0, m, ya, yb, d)
		HB.stone(p, m, x1, ya, yb, d)
	reach = MORT / 2 - 0.0025
	a0, a1 = x0 - reach + 0.002, x1 + reach - 0.002
	for c in range(nc):
		ya, yb = y_pl + ch * c, y_pl + ch * (c + 1)
		dark = K.rng.random() < 0.07
		if yb <= spring + 1e-6:
			for (sa, sb) in HB.segments(a0, a1, [(-R - MORT / 2, R + MORT / 2)]):
				HB.brick(p, sa, sb, ya, yb, d, None, dark=dark)
		elif ya < spring + r_out:
			cut = lambda aa, bb, yy0, yy1: HB.cut_circle(aa, bb, yy0, yy1, 0.0, spring, r_out + 0.002)
			HB.brick(p, a0, 0.0, ya, yb, d, cut, dark=dark)
			HB.brick(p, 0.0, a1, ya, yb, d, cut, dark=K.rng.random() < 0.07)
		else:
			off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
			for (a, b) in HB.lay_row(a0, a1, off):
				HB.brick(p, a, b, ya, yb, d, None, dark=K.rng.random() < 0.07)
	HB.ring(p, 0.0, spring, R, r_out, 0.0, math.pi, d, 6)


# ---------------- the dormer ----------------
K_M = (2.0 - HR.TOP_V - 2 * K.E_IN) / 2.0          # the big roof_45's slope (its underside line, from the front)
TOP_M = HR.N_TOP / math.cos(math.atan(K_M))         # its tiles' top above that line
UNDER = lambda z: K.E_IN + K_M * (1.0 - z)          # the big roof's underside at z (low edge at the front, z = +1)
HALF = 0.5          # the dormer's front wall: 1 m wide
OVER = 0.06         # its roof's eaves reach 6 cm past the side boards
RISE = 0.58         # its gable's rise over HALF (matches its roof slopes' underside)
ZW = 0.62           # the front wall's middle (16 cm thick)
WD = 0.16


def dormer():
	zb = ZW - WD / 2
	bottom = UNDER(zb) + 0.012                      # inside the big roof's tiles, never through its underside
	wh = 0.74
	top = bottom + wh
	# the front wall: bricks, the limestone base and a round-topped leaded window
	before = set(bpy.data.objects)
	HW.body(w=2 * HALF, h=wh, d=WD, courses=3, window=(0.2, 0.36, 0.17, 0.07, 0.22, 0.05))
	place(HB.since(before), 0, (0, bottom, ZW))
	# the gable over it: two halves rising to the middle
	k = (RISE - 0.2 - 2 * K.E_IN) / HALF
	for s in (-1, 1):
		before = set(bpy.data.objects)
		HW.body(w=HALF, h=RISE, d=WD, courses=2, slope=RISE)
		place(HB.since(before), 0 if s < 0 else 180, (s * HALF / 2, top, ZW))
	# its roof: two short tiled slopes, cut where they run into the big roof's tiles
	v_hi = ZW + WD / 2 + 0.1
	y0 = top - k * OVER
	run = HALF + OVER
	c = -1.0 + (y0 + K.E_IN + k * run - TOP_M + 0.03) / K_M
	sls = []
	for s in (-1, 1):
		sl = K.Slope("x", s * run, 0.0, k * run + 0.2 + 2 * K.E_IN, HR.TOP_V, vlo=-0.9, vhi=v_hi, y0=y0)
		# keep where its underside is above the big roof's tiles: v >= 1 - (y_d(u) - top)/K_M
		HR.slope_panel(sl, extra=[(s * k / K_M, -1.0, c)], rafters=(0.1, v_hi - 0.06))
		sls.append(sl)
	sl = sls[0]
	cs = math.cos(sl.ang)
	y_at = lambda x, h: sl.y0 + sl.k * (run - abs(x)) + h
	hw = 0.11
	z_back = 1.0 - (y_at(0.0, 0.0) - TOP_M + 0.03 - K.E_IN) / K_M
	y_edge = y_at(hw, HR.N_TOP / cs) + 0.004
	before = set(bpy.data.objects)
	HR.ridge_tiles(z_back + 0.02, v_hi, y_edge, hw=hw, sag=0.06, n=4)
	place(HB.since(before), -90, (0, 0, 0))
	a = hw - 0.02

	def sec(f):
		z = z_back + 0.04 + (v_hi - z_back - 0.06) * f
		tp = lambda x: y_edge + 0.06 * (1 - (x / hw) ** 2) - 0.004
		bt = lambda x: y_at(x, HR.UL1 / cs) - 0.004
		return [(-a, bt(-a), z), (0.0, bt(0.0), z), (a, bt(a), z), (a, tp(a), z), (0.0, tp(0.0), z), (-a, tp(-a), z)]
	HR.prism(sec, 1, HB.m_mortar(), "mortar")
	# the sides: dark timber boards from the big roof up to the eaves, behind the front wall
	yt = top - 0.004
	z_end = 1.0 - (yt - K.E_IN - 0.012) / K_M
	zs = [zb - 0.002]
	while zs[-1] > z_end + 0.02:
		zs.append(max(z_end, zs[-1] - K.rng.uniform(0.15, 0.19)))
	for s in (-1, 1):
		for za, zc in zip(zs, zs[1:]):
			ylo = lambda z: UNDER(z) + 0.012
			pts = [(zc, max(ylo(zc), yt - 0.001 if zc <= z_end + 1e-6 else ylo(zc))), (za, ylo(za)), (za, yt), (zc, yt)]
			if zc <= z_end + 1e-6:
				pts = [(za, ylo(za)), (za, yt), (zc, yt)]
			pts = [(z + (0.004 if i == 0 else 0), y) for i, (z, y) in enumerate(pts)]
			o = SV.prism(side(), [(z, y) for (z, y) in pts], 0.0, 0.045, kit.tex_mat("wood", "dark"), cut=0.008, role="timber")
			place([o], 0, (s * (HALF - 0.03), 0, 0))
			HB.tag([o], "timber")


PIECES = {"corbel": corbel, "cornice": cornice, "cornice_corner": cornice_corner, "railing_narrow": railing_narrow,
	"dormer": dormer}


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
		K.rng.seed(sum(map(ord, name + "hearth_manor")))
		kit.reset()
		PIECES[name]()
		HB.split_big_faces()
		ps = [o.matrix_world @ v.co for o in meshes() for v in o.data.vertices]
		print("SIZE %s x %.2f y %.2f z %.2f" % (name, max(p.x for p in ps) - min(p.x for p in ps),
			max(p.z for p in ps) - min(p.z for p in ps), max(p.y for p in ps) - min(p.y for p in ps)))
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			HB.paint()
		png = str(K.JOUR / f"{name}__clay_brick.png") if install else None
		kit.save(str(out_dir / f"{name}__clay_brick.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
