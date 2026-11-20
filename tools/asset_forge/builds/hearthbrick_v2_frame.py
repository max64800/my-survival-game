# Hearthbrick v2, the frame pieces (owner, Nov 20: "work through all of the batches"): beam, short beam, brace,
# arch, railing with little arches, ladder, mine prop. Same look as the approved Hearthbrick wall
# (hearthbrick_v2.py): bumpy hand-pressed bricks in pale lime mortar, rough limestone, dark timber, hammered copper.
#   blender --background --factory-startup --python builds/hearthbrick_v2_frame.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Default output folder: journey/hearthbrick_v2/glb (the game's files are only replaced after the owner's OK).
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402
import hearthbrick_v2 as HB  # noqa: E402

E = HB.E
MORT = HB.MORT
blk = K.blk
K.SIZE.update({"brace": (2, 2, 0.25), "arch": (2, 1, 0.4), "ladder": (1, 2, 0.2), "mine_prop": (2, 3, 0.4)})


def timber_m():
	return kit.tex_mat("wood", "dark")


def copper_m():
	return kit.tex_mat("copper", "b")


def tagged(role, fn, *a, **kw):
	"""Run one builder call and tag everything it made with `role`."""
	before = set(bpy.data.objects)
	o = fn(*a, **kw)
	HB.tag(HB.since(before), role)
	return o


def rivet(c, r=0.012):
	tagged("copper", kit.rivet, K.G(c), kit.tex_mat("copper", "dark"), r=r)


# ---------------- beams ----------------
def beam(w=2.0, h=0.3, d=0.3):
	"""A brick beam: two courses of bumpy bricks over a pale mortar core, a rough limestone block at each end."""
	p = HB.Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	end = 0.26 if w > 1.5 else 0.2
	tagged("mortar", blk, (0, h / 2, 0), (x1 - x0 - 2 * end + 0.04, h - 2 * E - 0.03, d * 0.7), HB.m_mortar(), bevel=0)
	for (a, b) in ((x0, x0 + end), (x1 - end, x1)):
		HB.stone(p, a, b, E, h - E, d)
	ym = E + (h - 2 * E) / 2
	reach = MORT / 2 - 0.0025
	for c, (ya, yb) in enumerate(((E, ym), (ym, h - E))):
		off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
		for (a, b) in HB.lay_row(x0 + end + 0.002 - reach, x1 - end - 0.002 + reach, off):
			HB.brick(p, a, b, ya, yb, d, None, dark=K.rng.random() < 0.08)


def beam_half():
	beam(1.0)


# ---------------- brace ----------------
def brace(w=2.0, h=2.0, d=0.25):
	"""A dark timber strut from bottom left to top right, its ends resting on rough limestone pads, held by
	riveted copper straps near both ends."""
	p = HB.Panel()
	pad_h, pad_w = 0.24, 0.42
	x0, x1 = -w / 2 + E, w / 2 - E
	HB.stone(p, x0, x0 + pad_w, E, pad_h, d)
	HB.stone(p, x1 - pad_w, x1, h - pad_h, h - E, d)
	hw = 0.16 * math.sqrt(2) / 2   # half the strut's width, measured across (sideways)
	ya, yb = pad_h + 0.002, h - pad_h - 0.002
	ca = x0 + pad_w / 2 + 0.03     # the strut's centre line where it meets each pad
	cb = ca + (yb - ya)
	pts = [(ca - hw, ya), (ca + hw, ya), (cb + hw, yb), (cb - hw, yb)]
	p.poly(pts, 0.16, timber_m(), "timber", cut=0.02)
	fr = K.Frame()
	ux, uy = 1 / math.sqrt(2), 1 / math.sqrt(2)
	nx, ny = -uy, ux
	for t in (0.3, 0.7):   # copper straps on the front and back
		cx, cy = ca + (cb - ca) * t, ya + (yb - ya) * t
		for zs in (1, -1):
			q = [(cx + ux * s * 0.06 + nx * n * 0.066, cy + uy * s * 0.06 + ny * n * 0.066) for (s, n) in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
			tagged("copper", K.slab_poly, fr, q, zs * 0.0865, 0.011, copper_m())
			for n in (-0.035, 0.035):
				rivet((cx + nx * n, cy + ny * n, zs * 0.093), r=0.011)


# ---------------- arch ----------------
def arch(w=2.0, h=1.0, d=0.4):
	"""A brick arch: a ring of wedge bricks (every third one burnt dark) round a round-topped opening with a carved
	limestone keystone, bumpy bricks cut round it, limestone corner stones up both ends and the carved rune band
	on top, like the round doorway."""
	p = HB.Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	spring, r_in, r_out = 0.06, 0.55, 0.67
	band0 = h - E - 0.174
	nc = 6
	ch = (band0 - E) / nc
	kw = 0.08
	key_x = kw + 0.024
	y_out = spring + math.sqrt(r_out * r_out - kw * kw)
	cutter = HB.round_cutter(0.0, spring, r_out + 0.002, key_x, y_out - 0.05)
	HB.arch_backing(p, x0 + 0.01, x1 - 0.01, E + 0.004, h - 0.01, 0.0, E + 0.004, spring, r_in + 0.009, d)
	rows = [(E + 2 * ch * k, E + 2 * ch * (k + 1)) for k in range(3)] + [(band0, h - E)]
	qws = (0.29, 0.2)
	inner = []
	for k, (ya, yb) in enumerate(rows):
		qw = qws[k % 2]
		for sx in (-1, 1):
			a, b = (x0, x0 + qw) if sx < 0 else (x1 - qw, x1)
			HB.stone(p, a, b, ya, yb, d, cutter)
		inner.append((x0 + qw, x1 - qw))
	reach = MORT / 2 - 0.0025
	for c in range(nc):
		ya, yb = E + ch * c, E + ch * (c + 1)
		a0, a1 = inner[c // 2][0] + 0.002 - reach, inner[c // 2][1] - 0.002 + reach
		off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
		for (a, b) in HB.lay_row(a0, a1, off):
			HB.brick(p, a, b, ya, yb, d, cutter, dark=K.rng.random() < 0.06)
	a0, a1 = inner[3][0] + 0.002, inner[3][1] - 0.002
	cuts = [a0, a0 + (a1 - a0) * K.rng.uniform(0.3, 0.38), a0 + (a1 - a0) * K.rng.uniform(0.62, 0.7), a1]
	for k in range(3):
		o = HB.stone(p, cuts[k], cuts[k + 1], band0, h - E, d, role="band")
		if o is not None:
			o["band_y0"] = band0
	a_lo = math.asin(max(-1.0, -(spring - E) / r_out))
	HB.ring(p, 0.0, spring, r_in, r_out, a_lo, math.pi - a_lo, d, 16, kw)
	a_lo = math.asin(max(-1.0, -(spring - E) / (r_out + 0.06)))
	HB.mortar_arc(p, 0.0, spring, r_out - 0.01, r_out + 0.06, a_lo, math.pi - a_lo, d - 2 * E - 0.045,
		(x0 + 0.01, x1 - 0.01, E + 0.004, band0 - 0.004), skip=lambda x, y: abs(x) < key_x + 0.01 and y > y_out - 0.08)
	HB.keystone(p, 0.0, spring, r_in, r_out, kw, band0 - 0.003, d)


# ---------------- railing with little arches ----------------
def railing(w=2.0, h=1.0, d=0.15):
	"""Owner: a railing with little arches. A rough limestone plinth along the bottom, a limestone coping on
	top, and between them a low brick wall with three little round-topped openings, each under a ring of
	wedge bricks."""
	p = HB.Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	y_pl, y_cop = 0.13, h - E - 0.15
	nc = 6
	ch = (y_cop - y_pl) / nc
	spring = y_pl + 2 * ch
	R, r_out = 0.14, 0.22
	cxs = [-0.6, 0.0, 0.6]
	mids = [-0.3, 0.3]
	edges = [x0 + 0.01] + mids + [x1 - 0.01]
	for i, cx in enumerate(cxs):
		HB.arch_backing(p, edges[i], edges[i + 1], y_pl + 0.004, y_cop - 0.004, cx, y_pl + 0.004, spring, R + 0.009, d, depth=0.5)
	for (ya, yb) in ((E, y_pl), (y_cop, h - E)):   # plinth and coping: long limestone blocks
		x = x0
		while x < x1 - 0.01:
			nx = min(x1, x + K.rng.uniform(0.4, 0.62))
			if x1 - nx < 0.25:
				nx = x1
			HB.stone(p, x, nx, ya, yb, d)
			x = nx
	reach = MORT / 2 - 0.0025
	a0, a1 = x0 - reach + 0.002, x1 + reach - 0.002
	for c in range(nc):
		ya, yb = y_pl + ch * c, y_pl + ch * (c + 1)
		dark = lambda: K.rng.random() < 0.07
		if yb <= spring + 1e-6:   # beside the openings: little brick piers
			for (sa, sb) in HB.segments(a0, a1, [(cx - R - MORT / 2, cx + R + MORT / 2) for cx in cxs]):
				if c % 2 and sb - sa > 0.26:   # every other course the middle piers are two half bricks
					m = (sa + sb) / 2
					HB.brick(p, sa, m, ya, yb, d, None, dark=dark())
					HB.brick(p, m, sb, ya, yb, d, None, dark=dark())
				else:
					HB.brick(p, sa, sb, ya, yb, d, None, dark=dark())
		elif ya < spring + r_out:   # round the little arches: each brick reaches one opening only
			xs = [a0] + sorted(cxs + mids) + [a1]
			for k in range(len(xs) - 1):
				a, b = xs[k], xs[k + 1]
				cx = min(cxs, key=lambda q: abs(q - (a + b) / 2))
				cut = (lambda cx_: lambda aa, bb, yy0, yy1: HB.cut_circle(aa, bb, yy0, yy1, cx_, spring, r_out + 0.002))(cx)
				HB.brick(p, a, b, ya, yb, d, cut, dark=dark())
		else:
			off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
			for (a, b) in HB.lay_row(a0, a1, off):
				HB.brick(p, a, b, ya, yb, d, None, dark=dark())
	for cx in cxs:
		HB.ring(p, cx, spring, R, r_out, 0.0, math.pi, d, 6)


# ---------------- ladder ----------------
def ladder(w=1.0, h=2.0, d=0.2):
	"""Two chunky dark timber rails with timber rungs between them, bound by hammered copper bands."""
	rx, rw, rd = 0.38, 0.08, 0.09
	for sx in (-1, 1):
		tagged("timber", HB.cbox, (sx * rx, h / 2, 0), (rw, h - 2 * E - 0.004, rd), timber_m(), cut=0.016, dent=0.008, free="xz")
		for y in (0.12, 1.02, h - E - 0.03):
			tagged("copper", blk, (sx * rx, y, 0), (rw + 0.014, 0.036, rd + 0.014), copper_m(), bevel=0.004)
			rivet((sx * rx, y, rd / 2 + 0.009), r=0.009)
	inner = rx - rw / 2 + 0.004
	y = 0.27
	while y < h - 0.15:
		tagged("timber", HB.cbox, (0, y + K.rng.uniform(-0.01, 0.01), 0), (2 * inner, 0.055, 0.062), timber_m(), cut=0.012, dent=0.008, free="yz")
		y += 0.3


# ---------------- mine prop ----------------
def mine_prop(w=2.0, h=3.0, d=0.4):
	"""Holds the rock up: two big dark timber posts on rough limestone pads, a timber cap beam across the top,
	two knee braces, and riveted copper brackets over the post-to-cap joints (it costs one copper bar)."""
	px, pw, pd = 0.78, 0.22, 0.24
	pad_h = 0.15
	cap_y0 = h - E - 0.232
	fr = K.Frame()
	for sx in (-1, 1):
		x = sx * px
		tagged("lime", HB.cbox, (x, (E + pad_h) / 2, 0), (0.4, pad_h - E - 0.002, 0.36), HB.m_lime(), cut=0.03, dent=0.018, free="xz")
		tagged("timber", HB.cbox, (x, (pad_h + cap_y0) / 2, 0), (pw, cap_y0 - pad_h - 0.004, pd), timber_m(), cut=0.02, dent=0.01, free="xz")
		f = x - sx * (pw / 2 + 0.001)   # the post's inner face
		pts = [(f, cap_y0 - 0.46), (f - sx * 0.43, cap_y0 - 0.002), (f - sx * 0.27, cap_y0 - 0.002), (f, cap_y0 - 0.3)]
		if sx > 0:
			pts.reverse()
		HB.Panel().poly(pts, 0.14, timber_m(), "timber", cut=0.016)
		for zs in (1, -1):   # an L-shaped copper bracket over the joint, front and back
			z = zs * (pd / 2 + 0.0065)
			o0, o1 = x - sx * 0.08, x + sx * 0.08
			q = [(o0, cap_y0 - 0.26), (o1, cap_y0 - 0.26), (o1, cap_y0 + 0.05), (x - sx * 0.3, cap_y0 + 0.05), (x - sx * 0.3, cap_y0 + 0.18), (o0, cap_y0 + 0.18)]
			if sx < 0:
				q.reverse()
			tagged("copper", K.slab_poly, fr, q, z, 0.011, copper_m())
			for (rx_, ry_) in ((x, cap_y0 - 0.2), (x, cap_y0 + 0.11), (x - sx * 0.22, cap_y0 + 0.11)):
				rivet((rx_, ry_, zs * (pd / 2 + 0.014)), r=0.011)
	tagged("timber", HB.cbox, (0, (cap_y0 + h - E) / 2, 0), (w - 2 * E - 0.004, h - E - cap_y0 - 0.002, pd), timber_m(), cut=0.022, dent=0.01, free="z")


PIECES = {"beam": beam, "beam_half": beam_half, "brace": brace, "arch": arch, "railing": railing, "ladder": ladder,
	"mine_prop": mine_prop}


def paint():
	HB.paint()
	for o in bpy.data.objects:   # the arch's rune band sits lower than the wall's: lay its runes from its own bottom
		if o.type == "MESH" and o.get("role") == "band" and "band_y0" in o:
			me = o.data
			uv = me.uv_layers.active.data
			row_h = 0.174
			for poly in me.polygons:
				for li in poly.loop_indices:
					v = me.vertices[me.loops[li].vertex_index].co
					uv[li].uv = (v.x / (3 * row_h), (v.z - o["band_y0"]) / (3 * row_h))


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
