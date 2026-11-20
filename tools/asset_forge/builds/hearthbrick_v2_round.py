# Hearthbrick, version 2: the round pieces (owner, Nov 20, F427): the deep green round door with big hammered
# copper strap hinges and a copper ring, the round brick pillar, and the carved column with its three stackable
# parts (base 0.5 + shaft 1.0 + capital 0.5 = the 2 m column). Same bricks, mortar and limestone as
# builds/hearthbrick_v2.py (its helpers and painter are reused).
#   blender --background --factory-startup --python builds/hearthbrick_v2_round.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Pieces: door, pillar, column, column_base, column_shaft, column_capital.
# Default output folder: journey/hearthbrick_v2/glb (the game's files are only replaced after the owner's OK).
# The green door paint (hbgreen_a/b) is made here from hbtimber_a (our own texture sheet), tinted deep green.
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import hearthbrick_v2 as HB  # noqa: E402
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402

E = HB.E
MORT = HB.MORT
TEXDIR = K.GAME / "assets" / "textures" / "kit"


# ---------------- the green door paint ----------------
GREENS = {"a": (0.10, 0.27, 0.16), "b": (0.08, 0.23, 0.15)}   # deep green, a hair different plank to plank


def make_green():
	"""hbgreen_a/b.png: the dark timber painting (vertical grain, knots) turned deep green, keeping its light and
	shade, so the door's planks are painted wood, not plastic."""
	import numpy as np
	src = bpy.data.images.load(str(TEXDIR / "hbtimber_a.png"))
	w, h = src.size
	px = np.empty(w * h * 4, dtype=np.float32)
	src.pixels.foreach_get(px)
	px = px.reshape(-1, 4)
	lum = px[:, 0] * 0.3 + px[:, 1] * 0.59 + px[:, 2] * 0.11
	lum = lum / max(1e-4, float(lum.mean()))
	for v, col in GREENS.items():
		out = np.empty_like(px)
		for k in range(3):
			out[:, k] = np.clip(col[k] * lum ** 0.9, 0.0, 1.0)
		out[:, 3] = 1.0
		im = bpy.data.images.new(f"hbgreen_{v}", w, h)
		im.pixels.foreach_set(out.ravel())
		im.filepath_raw = str(TEXDIR / f"hbgreen_{v}.png")
		im.file_format = "PNG"
		im.save()
		bpy.data.images.remove(im)
	bpy.data.images.remove(src)


kit.TILE["hbgreen"] = 0.6
HB.HB_TILE["hbgreen"] = 0.6


# ---------------- round brick courses ----------------
def arc(cx, cz, r, a0, a1, n):
	return [(cx + math.cos(a0 + (a1 - a0) * k / n) * r, cz + math.sin(a0 + (a1 - a0) * k / n) * r) for k in range(n + 1)]


def sector(cx, cz, r_in, r_out, a0, a1, n_out=4):
	"""A curved brick seen from above: the outer arc (bumpy bricks: r_out already varied), straight inside."""
	return arc(cx, cz, r_out, a0, a1, n_out) + list(reversed(arc(cx, cz, r_in, a0, a1, 1)))


def chisel_edges(o, w=0.008):
	b = o.modifiers.new("chisel", "BEVEL")
	b.width, b.segments, b.limit_method, b.angle_limit = w, 1, "ANGLE", math.radians(35)
	for pp in o.data.polygons:
		pp.use_smooth = False


def brick_course(y0, y1, r_in, r_out, n, phase, cx=0.0, cz=0.0, upright=False):
	"""One round course of hand-pressed bricks: n curved bricks with pale mortar joints between them, each a
	little sunk or proud (never past r_out), a few burnt dark. upright = the tall upright-brick row."""
	g = MORT / 2
	for i in range(n):
		a0 = phase + 2 * math.pi * i / n
		a1 = phase + 2 * math.pi * (i + 1) / n
		ro = r_out - K.rng.uniform(0.0, 0.012)
		a0g, a1g = a0 + g / ro, a1 - g / ro
		pts = sector(cx, cz, r_in, ro, a0g, a1g, 2 if upright else 4)
		ya, yb = y0 + g, y1 - g - K.rng.uniform(0.0, 0.004)
		before = set(bpy.data.objects)
		o = K.floor_poly(pts, ya, yb, HB.m_brick())
		chisel_edges(o, 0.007 if upright else 0.009)
		HB.tag(HB.since(before), "brick")
		o["dark"] = K.rng.random() < 0.07


def mortar_core(y0, y1, r, cx=0.0, cz=0.0):
	"""The pale mortar filling the middle of a round shaft: the joints between the bricks show it, never a hole."""
	before = set(bpy.data.objects)
	kit.cylinder(r, y1 - y0, K.G((cx, (y0 + y1) / 2, cz)), HB.m_mortar(), verts=16, bevel=0)
	HB.tag(HB.since(before), "mortar")


def lime_block(c, s, cut=0.035, free="xz"):
	HB.tag([HB.cbox(c, s, HB.m_lime(), cut=cut, dent=0.02, free=free, seeds=1)], "lime")


def lime_ring(y0, y1, r_in, r_out, n, phase=0.0, role="lime", n_out=6):
	"""A round drum of n curved rough limestone blocks (the column's base drum and its rune band)."""
	g = 0.003
	for i in range(n):
		a0 = phase + 2 * math.pi * i / n + g / r_out
		a1 = phase + 2 * math.pi * (i + 1) / n - g / r_out
		before = set(bpy.data.objects)
		o = K.floor_poly(sector(0.0, 0.0, r_in, r_out, a0, a1, n_out), y0 + 0.0015, y1 - 0.0015, HB.m_lime())
		chisel_edges(o, 0.014)
		HB.tag(HB.since(before), role)
		o["a0"], o["a1"], o["y0"], o["y1"], o["r"] = a0, a1, y0, y1, r_out


def courses(y0, y1, r_in, r_out, ch=HB._CH):
	"""Round brick courses from y0 to y1 (about the wall's course height), joints staggered course to course."""
	n_c = max(1, round((y1 - y0) / ch))
	h = (y1 - y0) / n_c
	n_b = max(3, round(2 * math.pi * r_out / 0.31))
	ph = K.rng.uniform(0, 1)
	for c in range(n_c):
		brick_course(y0 + h * c, y0 + h * (c + 1), r_in, r_out, n_b, ph + (math.pi / n_b if c % 2 else 0.0))


# ---------------- pillar ----------------
def pillar(w=0.4, h=2.0):
	"""Round brick pillar: a square rough limestone foot block, round courses of curved bricks round a mortar
	core, a ring of upright bricks (like the wall's row under its band), a square limestone cap."""
	s = w - 2 * E - 0.004
	foot, top = 0.24, h - E - 0.2
	lime_block((0, (E + foot) / 2 + 0.001, 0), (s, foot - E - 0.004, s))
	lime_block((0, (top + h - E) / 2, 0), (s, h - E - top - 0.003, s))
	r_out, r_in = 0.165, 0.075
	mortar_core(foot + 0.002, top - 0.002, r_out - 0.025)
	soldier = top - 0.17
	courses(foot, soldier, r_in, r_out)
	brick_course(soldier, top, r_in, r_out, 9, K.rng.uniform(0, 1), upright=True)


# ---------------- column and its three parts ----------------
COL_R = 0.28     # the brick shaft's radius
COL_IN = 0.16


def col_base(y=0.0, core=True):
	"""Column base (0.5): a square limestone plinth, a round limestone drum, a ring of upright bricks."""
	s = 0.8 - 2 * E - 0.004
	lime_block((0, y + (E + 0.17) / 2 + 0.001, 0), (s, 0.17 - E - 0.004, s))
	lime_ring(y + 0.17, y + 0.31, 0.14, 0.345, 6, K.rng.uniform(0, 1))
	if core:
		mortar_core(y + 0.312, y + 0.5 - E - 0.012, COL_R - 0.03)
	brick_course(y + 0.31, y + 0.5 - E + MORT / 2, COL_IN, COL_R, 16, K.rng.uniform(0, 1), upright=True)


def col_shaft(y=0.0, core=True):
	"""Column shaft (1.0): round courses of curved bricks, joints staggered."""
	if core:
		mortar_core(y + E + 0.012, y + 1.0 - E - 0.012, COL_R - 0.03)
	courses(y + E - MORT / 2, y + 1.0 - E + MORT / 2, COL_IN, COL_R)


RUNE_Y0, RUNE_Y1 = 0.16, 0.33


def col_capital(y=0.0, core=True):
	"""Column capital (0.5): a ring of upright bricks, the carved limestone rune band flaring out over them
	(the wall's band, round), a square limestone slab on top."""
	if core:
		mortar_core(y + E + 0.012, y + RUNE_Y0 - 0.002, COL_R - 0.03)
	brick_course(y + E - MORT / 2, y + RUNE_Y0, COL_IN, COL_R, 16, K.rng.uniform(0, 1), upright=True)
	lime_ring(y + RUNE_Y0, y + RUNE_Y1, 0.12, 0.335, 4, K.rng.uniform(0, 1), role="runeband", n_out=10)
	s = 0.8 - 2 * E - 0.004
	lime_block((0, y + (RUNE_Y1 + 0.5 - E) / 2 + 0.0005, 0), (s, 0.5 - E - RUNE_Y1 - 0.003, s))


def column():
	"""The 2 m column = base + shaft + capital, one mortar core all the way up (no joint to see through)."""
	mortar_core(0.32, 1.5 + RUNE_Y0 - 0.002, COL_R - 0.03)
	col_base(0.0, core=False)
	col_shaft(0.5, core=False)
	col_capital(1.5, core=False)


def column_base():
	col_base()


def column_shaft():
	col_shaft()


def column_capital():
	col_capital()


# ---------------- the round door ----------------
def door(d=0.12):
	"""Deep green round door (rule 5): upright planks cut to the circle, two big hammered copper strap hinges
	with spear ends and a round knuckle at the hinge side, a copper boss plate with a ring handle; two battens
	behind. Stays inside the doorway's brick ring (hearthbrick_v2: ring inside radius DOOR_R + 1 cm)."""
	r, cy = HB.DOOR_R - 0.012, HB.DOOR_CY
	fr = K.Frame()
	widths = [0.24, 0.27, 0.25, 0.28, 0.24]
	widths.append(2 * r - sum(widths))
	pz, pd = -0.004, 0.06            # planks: centre depth, thickness (front face at +0.026)
	front = pz + pd / 2
	x = -r
	for i, bw in enumerate(widths):
		a, b = x + K.rng.uniform(0.0015, 0.003), x + bw - K.rng.uniform(0.0015, 0.003)
		lo = lambda xx: max(E, cy - math.sqrt(max(0.0, r * r - xx * xx)))
		hi = lambda xx: cy + math.sqrt(max(0.0, r * r - xx * xx)) - 0.004
		before = set(bpy.data.objects)
		o = K.plank_shape(fr, a, b, lo, hi, pz + K.J(0.002), pd * K.rng.uniform(0.93, 1.0), HB.m_brick(), k=8)
		chisel_edges(o, 0.006)
		HB.tag(HB.since(before), "green")
		o["green"] = "ab"[i % 2]
		x += bw
	# a dark timber sheet inside the planks (its faces buried in them): the joints show dark wood, never light
	rs = r - 0.02
	sheet = [(math.cos(-math.pi / 2 + 2 * math.pi * k / 40) * rs, cy + math.sin(-math.pi / 2 + 2 * math.pi * k / 40) * rs) for k in range(40)]
	sheet = [(xx, max(E + 0.02, yy)) for (xx, yy) in sheet]
	before = set(bpy.data.objects)
	K.slab_poly(fr, HB.simplify(sheet), pz - 0.01, 0.012, kit.tex_mat("wood", "dark"))
	HB.tag(HB.since(before), "timber")
	# the strap hinges (hinge side = left), hammered copper, a spear tip, rivets, a knuckle at the edge
	for dy in (-0.36, 0.34):
		y = cy + dy
		xl = -math.sqrt(max(0.0, (r - 0.025) ** 2 - dy * dy))
		xe, hh = 0.30, 0.06
		pts = [(xl, y - hh), (xe, y - hh), (xe + 0.06, y - hh - 0.035), (xe + 0.19, y), (xe + 0.06, y + hh + 0.035), (xe, y + hh), (xl, y + hh)]
		before = set(bpy.data.objects)
		K.slab_poly(fr, pts, front + 0.003, 0.012, kit.tex_mat("copper", "b"))
		for k in range(6):
			xx = xl + 0.08 + (xe - xl - 0.04) * k / 5
			kit.rivet(K.G((xx, y, front + 0.009)), kit.tex_mat("copper", "dark"), r=0.013)
		kit.cylinder(0.03, 0.17, K.G((xl + 0.012, y, front - 0.002)), kit.tex_mat("copper", "b"), verts=10, bevel=0.003)
		HB.tag(HB.since(before), "copper")
	# the boss plate and ring handle (right side)
	hx, hy = 0.43, cy - 0.02
	before = set(bpy.data.objects)
	kit.cylinder(0.075, 0.012, K.G((hx, hy, front + 0.003)), kit.tex_mat("copper", "b"), rot=(90, 0, 0), verts=14, bevel=0.003)
	kit.cylinder(0.026, 0.02, K.G((hx, hy, front + 0.012)), kit.tex_mat("copper", "dark"), rot=(90, 0, 0), verts=10, bevel=0.004)
	kit.ring(0.07, 0.013, K.G((hx, hy - 0.075, front + 0.014)), kit.tex_mat("copper", "b"), rot=(90, 0, 0), seg=16)
	HB.tag(HB.since(before), "copper")
	# battens on the back
	for dy in (-0.3, 0.3):
		y = cy + dy
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - dy * dy))
		before = set(bpy.data.objects)
		blk = K.blk((0.0, y, pz - pd / 2 - 0.0095), (2 * hw - 0.04, 0.11, 0.02), HB.m_brick(), bevel=0.005)
		HB.tag(HB.since(before), "green")
		blk["green"] = "b"


PIECES = {"door": door, "pillar": pillar, "column": column, "column_base": column_base,
	"column_shaft": column_shaft, "column_capital": column_capital}


# ---------------- paint ----------------
def rune_uv(o):
	"""The carved rune painting wrapped round the band: one row of runes fills the band's height, one pattern
	repeat (one diamond) across each curved block, so it never stretches and the ends meet."""
	me = o.data
	if not me.uv_layers:
		me.uv_layers.new()
	uv = me.uv_layers.active.data
	a0, a1, y0, y1 = o["a0"], o["a1"], o["y0"], o["y1"]
	row = y1 - y0
	for poly in me.polygons:
		for li in poly.loop_indices:
			v = me.vertices[me.loops[li].vertex_index].co   # Blender: x, -z(godot), y(godot)
			ang = math.atan2(-v.y, v.x)
			t = (ang - a0) % (2 * math.pi)
			if t > math.pi:
				t -= 2 * math.pi
			if abs(poly.normal.z) > 0.7:   # top / bottom: the plain stone strip at the row's edge
				uv[li].uv = (v.x / (3 * row), v.y / (3 * row) * 0.05 + 0.01)
				continue
			uv[li].uv = (t / (a1 - a0), (v.z - y0) / (3 * row))


def paint():
	HB.paint()
	for o in list(bpy.data.objects):
		role = o.get("role")
		if role == "green":
			m = kit.tex_mat("hbgreen", o.get("green", "a"))
			o.data.materials.clear()
			o.data.materials.append(m)
			kit._uv_box(o, 0.6)
		elif role == "runeband":
			o.data.materials.clear()
			o.data.materials.append(kit.tex_mat("hbrune", "a"))
			rune_uv(o)
		elif role == "lime":
			pass


def tri_count():
	dg = bpy.context.evaluated_depsgraph_get()
	n = 0
	for o in bpy.data.objects:
		if o.type == "MESH":
			e = o.evaluated_get(dg)
			me = e.to_mesh()
			me.calc_loop_triangles()
			n += len(me.loop_triangles)
			e.to_mesh_clear()
	return n


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), HB.OUT_DEFAULT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	if not grey and not (TEXDIR / "hbgreen_b.png").exists():
		kit.reset()
		make_green()
	for name in names:
		K.rng.seed(sum(map(ord, name + "hearthbrick2round")))
		kit.reset()
		PIECES[name]()
		HB.split_big_faces()
		K.fit_check(name)
		print("TRIS", name, tri_count())
		if grey:
			SV.make_grey()
		else:
			paint()
		png = str(K.JOUR / f"{name}__clay_brick.png") if install else None
		kit.save(str(out_dir / f"{name}__clay_brick.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
