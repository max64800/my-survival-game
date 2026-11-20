# Hearthbrick, version 2, the wall family (owner, Nov 20: "work through all of the batches"): half wall, narrow
# wall, wide window, sloped wall and the two gables, in the same idea-B look as the approved wall
# (builds/hearthbrick_v2.py: limestone base row, alternating quoins, bumpy bricks, upright bricks under a carved
# rune band). Triangle pieces: bricks cut exactly to the slope under a limestone coping; the steep gable gets a
# carved rune roundel in a brick ring.
#   blender --background --factory-startup --python builds/hearthbrick_v2_walls.py -- [grey] [out=<folder>] [install=1] [piece ...]
# The gables' top line follows the Shack v3 gables (builds/shack_v2.py gable_v3): it runs 15 cm up into the roof
# piece's underside, so no gap shows under a roof.
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
CH = HB._CH            # one brick course (same as the 2 m wall: the bricks keep their thickness)
MORT = HB.MORT
BASE_H = HB.BASE_H


def slope_line(w, rise):
	"""The gable's top = the Hearthbrick roof's underside line (hearthbrick_v2_roofs.py: Slope with top_v 0.2,
	rafters hang from this line), so the coping meets the rafters with no gap and nothing inside the roof."""
	k = (rise - 0.2 - 2 * K.E_IN) / w
	return k, (lambda x: K.E_IN + k * (x + w / 2))


def body(w=2.0, h=2.0, d=0.3, courses=12, diamond=False, window=None, slope=None, roundel=None):
	"""The idea-B wall at any size. courses: brick courses in the field (2 per quoin row); above them a row of
	upright bricks and the rune band share what's left up to h.
	window = (bottom, spring, radius, ring, sill half width, keystone half width): an arched leaded window.
	slope = rise: a gable (high at +x): a limestone coping along the slope, everything under it cut to it,
	quoins only at the high end. roundel = (cx, cy, r_in, r_out): a carved rune disc in a ring of bricks."""
	p = HB.Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	field_top = BASE_H + CH * courses
	soldier_top = field_top + (h - E - field_top) / 2
	cutter = None
	key_x = 0.0
	planes = None
	if slope:
		k, top = slope_line(w, slope)
		ct = 0.13 / math.cos(math.atan(k))            # the coping: 13 cm thick across the slope
		low = lambda x: top(x) - ct
		c_lo = top(0.0) - ct - 0.006
		planes = [(-k, 1.0, c_lo)]                     # y <= the coping's underside, 6 mm joint

		def slope_cut(a, b, ya, yb):
			if yb <= low(a) - 0.006:
				return None
			if ya >= low(b) - 0.006:
				return []
			return K.clip_poly([(a, ya), (b, ya), (b, yb), (a, yb)], planes)
		cutter = slope_cut
		if roundel:
			rcx, rcy, r_in, r_out = roundel
			circ = HB.round_cutter(rcx, rcy, r_out + 0.002)

			def both(a, b, ya, yb):
				r = circ(a, b, ya, yb)
				if r == []:
					return []
				s = slope_cut(a, b, ya, yb)
				if r is None:
					return s
				if s is None:
					return r
				if s == []:
					return []
				return K.clip_poly(r, planes) or []
			cutter = both
	if window:
		wb, wsp, wr, wring, sill_hw, wk = window
		w_out = wr + wring
		key_x = wk + 0.024
		y_out = wsp + math.sqrt(w_out * w_out - wk * wk)
		arch = HB.round_cutter(0.0, wsp, w_out + 0.002, key_x, y_out - 0.05)
		# only stones above the spring line are cut to the arch (this low arch's circle reaches the ground)
		cutter = lambda a, b, ya, yb: None if yb <= wsp + 1e-6 else arch(a, b, ya, yb)
		HB.arch_backing(p, x0 + 0.01, x1 - 0.01, E + 0.004, h - 0.01, 0.0, wb, wsp, wr + 0.009, d)
	elif slope:
		before = set(bpy.data.objects)
		bx0, bx1 = x0 + 0.01, x1 - 0.01
		sheet = [(bx0, E + 0.004), (bx1, E + 0.004), (bx1, top(bx1) - 0.03), (bx0, top(bx0) - 0.03)]
		sheet = K.clip_poly(sheet, [(0.0, -1.0, -(E + 0.004))])   # the low tip: never below the ground line
		K.slab_poly(p.fr, HB.simplify(sheet), 0.0, d * 1.13 * 0.62, HB.m_mortar())
		HB.tag(HB.since(before), "mortar")
	else:
		before = set(bpy.data.objects)
		SV.backing(p.fr, x0, x1, E, h - E, d * 1.13)
		HB.tag(HB.since(before), "mortar")
	# base row: rough limestone blocks
	x = x0
	while x < x1 - 0.01:
		nx = min(x1, x + K.rng.uniform(0.34, 0.52))
		if x1 - nx < 0.2:
			nx = x1
		HB.stone(p, x, nx, E, BASE_H, d, cutter)
		x = nx
	# quoins: rows of 2 brick courses, then (flat tops) one beside the upright bricks and one beside the band
	rows = [(BASE_H + 2 * CH * j, BASE_H + 2 * CH * (j + 1)) for j in range(courses // 2)]
	if not slope:
		rows += [(field_top, soldier_top), (soldier_top, h - E)]
	inner = []
	for j, (ya, yb) in enumerate(rows):
		qw = HB.QUOIN_W[j % 2]
		for sx in ((1,) if slope else (-1, 1)):
			a, b = (x0, x0 + qw) if sx < 0 else (x1 - qw, x1)
			HB.stone(p, a, b, ya, yb, d, cutter)
		inner.append((ya, yb, x0 if slope else x0 + qw, x1 - qw))
	# the brick field
	reach = MORT / 2 - 0.0025
	for c in range(courses):
		ya, yb = BASE_H + CH * c, BASE_H + CH * (c + 1)
		if slope and ya >= low(x1) - 0.03:
			break
		row = inner[c // 2]
		a0 = row[2] if slope else row[2] + 0.002 - reach
		a1 = row[3] - 0.002 + reach
		cuts = []
		cut_here = cutter
		if window:
			if yb <= wb + 1e-6 and ya >= wb - CH - 1e-6:
				cuts = [(-sill_hw, sill_hw)]
			elif ya >= wb - 1e-6 and yb <= wsp + 1e-6:
				cuts = [(-wr - MORT / 2, wr + MORT / 2)]
			if yb <= wsp + 1e-6:
				cut_here = None
		if roundel and ya < roundel[1] + roundel[3] and yb > roundel[1] - roundel[3]:
			cuts = [(roundel[0], roundel[0])]   # a joint at the disc's centre line: no brick reaches round both sides of it
		off = K.rng.uniform(0.1, 0.17) if c % 2 else 0.0
		for (sa, sb) in HB.segments(a0, a1, cuts):
			for (a, b) in HB.lay_row(sa, sb, off if sa == a0 else 0.0):
				dark = diamond and HB.in_diamond((a + b) / 2, (ya + yb) / 2)
				if not dark and K.rng.random() < 0.06:
					dark = True
				HB.brick(p, a, b, ya, yb, d, cut_here, dark=dark)
	if slope:
		coping(p, x0, x1, top, low, d)
		if roundel:
			rune_roundel(p, roundel, d)
		return
	# the upright bricks under the band
	a0, a1 = inner[-2][2] + 0.002 - reach, inner[-2][3] - 0.002 + reach
	n = max(1, round((a1 - a0) / 0.12))
	for j in range(n):
		a, b = a0 + (a1 - a0) * j / n, a0 + (a1 - a0) * (j + 1) / n
		HB.brick(p, a, b, field_top, soldier_top, d, None)
	# the carved limestone band (runes painted on): 3 stones, 2 on a narrow wall
	a0, a1 = inner[-1][2] + 0.002, inner[-1][3] - 0.002
	cuts_b = [a0, a0 + (a1 - a0) * K.rng.uniform(0.3, 0.38), a0 + (a1 - a0) * K.rng.uniform(0.62, 0.7), a1] if a1 - a0 > 0.9 \
		else [a0, a0 + (a1 - a0) * K.rng.uniform(0.45, 0.55), a1]
	for j in range(len(cuts_b) - 1):
		o = HB.stone(p, cuts_b[j], cuts_b[j + 1], soldier_top, h - E, d, role="band")
		if o is not None:
			o["band0"], o["bandh"] = soldier_top, h - E - soldier_top
	if window:
		HB.ring(p, 0.0, wsp, wr, w_out, 0.0, math.pi, d, 14, wk)
		HB.mortar_arc(p, 0.0, wsp, w_out - 0.01, w_out + 0.06, 0.0, math.pi, d - 2 * E - 0.075,   # deeper than the wall's: a dented brick face sat 2 mm off it
			(x0 + 0.01, x1 - 0.01, wsp, field_top - 0.004), skip=lambda x, y: abs(x) < key_x + 0.01 and y > y_out - 0.08)
		HB.keystone(p, 0.0, wsp, wr, w_out, wk, y_out + 0.09, d)
		HB.stone(p, -sill_hw + MORT / 2 - 0.004, sill_hw - MORT / 2 + 0.004, wb - CH, wb, d, role="lime")
		HB.leaded_glass(p, wb, wsp, wr + 0.012)


def coping(p, x0, x1, top, low, d):
	"""Rough limestone coping stones along the slope (the low tip down to the ground), each cut to the slope."""
	x = x0
	floor_pl = [(0.0, -1.0, -(E + 0.002))]
	while x < x1 - 0.01:
		nx = min(x1, x + K.rng.uniform(0.38, 0.55))
		if x1 - nx < 0.22:
			nx = x1
		a, b = x + (0.002 if x > x0 else 0.0), nx - (0.002 if nx < x1 else 0.0)
		pts = K.clip_poly([(a, low(a)), (b, low(b)), (b, top(b)), (a, top(a))], floor_pl)
		if pts and K.area(pts) > 0.004:   # the low tip's stone is a thin wedge: its chisel edge must stay small
			pts = HB.simplify(pts)
			p.poly(pts, d - 2 * E - K.rng.uniform(0.002, 0.008), HB.m_lime(), "lime", cut=min(0.022, HB.thickness(pts) * 0.25))
		x = nx


def rune_roundel(p, roundel, d):
	"""A carved limestone disc with runes, set a little back inside a ring of wedge bricks."""
	cx, cy, r_in, r_out = roundel
	HB.ring(p, cx, cy, r_in, r_out, 0.0, 2 * math.pi, d, 12)
	pts = [(cx + math.cos(2 * math.pi * i / 24) * (r_in - 0.006), cy + math.sin(2 * math.pi * i / 24) * (r_in - 0.006)) for i in range(24)]
	o = p.poly(pts, d - 2 * E - 0.05, HB.m_lime(), "roundel", cut=0.018)
	o["rc"] = (cx, cy, r_in)


# ---------------- the pieces ----------------
def half_wall():
	body(h=1.0, courses=4)


def wall_narrow():
	body(w=1.0)


def window_wide():
	# a wider, lower arch than the window wall (1.24 m across); its ring cuts into the corner stones a little
	wb, wsp = BASE_H + 2 * CH, BASE_H + 4 * CH
	body(window=(wb, wsp, 0.62, 0.1, 0.66, 0.08))


def trim_tri_ends(w=2.0, d=0.3):
	"""Owner, Nov 20: on a triangle foundation the sloped wall's square ends stuck out past the triangle's slanted
	sides. On a triangle the game puts the wall fully on top (its front face on the side, owner's choice), so each end
	is cut at 30 degrees from the front face's corner, along the neighbouring side of the 60-degree corner (the back
	face ends 17 cm sooner). The front face keeps its full length; on square corners the cut wedge is mostly covered by
	the wall round the corner."""
	import bmesh
	t = math.tan(math.radians(30))
	dg = bpy.context.evaluated_depsgraph_get()
	for o in list(bpy.data.objects):
		if o.type != "MESH":
			continue
		me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))   # modifiers (chisel bevels) applied
		o.modifiers.clear()
		o.data = me
		bm = bmesh.new()
		bm.from_mesh(me)
		bm.transform(o.matrix_world)
		# Blender y = -Godot z: remove x > w/2 + t*(z_godot - d/2), a plane through the front face's corner
		# (Blender y = -d/2), and its mirror at -x
		back = 0.012 if o.get("role") == "mortar" else 0.0   # the mortar sheet's cut face sits 1.2 cm behind the stones' (no shimmer)
		for sx in (1, -1):
			geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
			res = bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=(sx * (w / 2 - back), -d / 2, 0), plane_no=(sx, t, 0), clear_outer=True)
			cut = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
			if cut:
				bmesh.ops.holes_fill(bm, edges=cut, sides=0)
		bm.transform(o.matrix_world.inverted())
		if not bm.faces:
			bm.free()
			bpy.data.objects.remove(o)
			continue
		bm.to_mesh(me)
		bm.free()


def sloped_wall():
	body(h=2.0, slope=2.0)
	trim_tri_ends()


def gable_26():
	body(h=1.0, slope=1.0)


def gable_45():
	body(h=2.0, slope=2.0, roundel=(0.3, 0.6, 0.17, 0.27))


def battlement(w=2.0, h=0.9, d=0.4):
	"""Owner, Nov 20: brick battlements. Like Stonehold's (same box, merlons at both ends and in the middle, low sills
	in the gaps) but in the Hearthbrick look: rough limestone base row, two courses of bumpy bricks with limestone
	quoins at the ends, a limestone string course, brick merlons under chunky limestone caps, and a carved rune stone
	as the middle merlon. A pale mortar sheet inside, one outline (no two sheets on top of each other)."""
	p = HB.Panel()
	x0, x1 = -w / 2 + E, w / 2 - E
	mw = 0.44
	y_base, y_str, y_mer, y_cap, y_sill = 0.17, 0.41, 0.48, 0.72, 0.54
	mer = [(x0, x0 + mw), (-mw / 2, mw / 2), (x1 - mw, x1)]
	# the mortar sheet: the lower wall plus the three merlons, in one outline
	xa, xb, yb0, yt, ycr = x0 + 0.01, x1 - 0.01, E + 0.004, y_cap + 0.03, y_sill - 0.01
	(l0, l1), (m0, m1), (r0, r1) = [(a + 0.01, b - 0.01) for (a, b) in mer]
	sheet = [(xa, yb0), (xb, yb0), (xb, yt), (r0, yt), (r0, ycr), (m1, ycr), (m1, yt), (m0, yt), (m0, ycr), (l1, ycr), (l1, yt), (xa, yt)]
	before = set(bpy.data.objects)
	K.slab_poly(p.fr, sheet, 0.0, d * 0.62, HB.m_mortar())
	HB.tag(HB.since(before), "mortar")
	# base row of rough limestone
	x = x0
	while x < x1 - 0.01:
		nx = min(x1, x + K.rng.uniform(0.38, 0.55))
		if x1 - nx < 0.22:
			nx = x1
		HB.stone(p, x, nx, E, y_base, d)
		x = nx
	# two brick courses with limestone quoins at both ends
	ch = (y_str - y_base) / 2
	for c in range(2):
		ya, yb = y_base + ch * c, y_base + ch * (c + 1)
		qw = (0.26, 0.16)[c]
		HB.stone(p, x0, x0 + qw, ya, yb, d)
		HB.stone(p, x1 - qw, x1, ya, yb, d)
		for (a, b) in HB.lay_row(x0 + qw, x1 - qw, K.rng.uniform(0.1, 0.17) if c else 0.0):
			HB.brick(p, a, b, ya, yb, d, dark=K.rng.random() < 0.06)
	# the limestone string course along the top of the wall
	cuts = [x0, x0 + (x1 - x0) * K.rng.uniform(0.3, 0.37), x0 + (x1 - x0) * K.rng.uniform(0.63, 0.7), x1]
	for k in range(3):
		HB.stone(p, cuts[k], cuts[k + 1], y_str, y_mer, d)
	# merlons: two brick courses (quoins on the battlement's outer ends) under a chunky limestone cap
	mh = (y_cap - y_mer) / 2
	for i, (a0, a1) in enumerate(mer):
		if i == 1:   # the middle one: one carved rune stone
			o = HB.stone(p, a0, a1, y_mer, y_cap, d, role="band")
			o["band0"], o["bandh"] = y_mer, y_cap - y_mer
		else:
			for c in range(2):
				ya, yb = y_mer + mh * c, y_mer + mh * (c + 1)
				qw = (0.2, 0.13)[c]
				if i == 0:
					HB.stone(p, a0, a0 + qw, ya, yb, d)
					HB.brick(p, a0 + qw, a1, ya, yb, d, dark=K.rng.random() < 0.1)
				else:
					HB.brick(p, a0, a1 - qw, ya, yb, d, dark=K.rng.random() < 0.1)
					HB.stone(p, a1 - qw, a1, ya, yb, d)
		HB.stone(p, a0, a1, y_cap, h - E, d)
	# low limestone sills in the two gaps
	for (a, b) in ((mer[0][1], mer[1][0]), (mer[1][1], mer[2][0])):
		HB.stone(p, a, b, y_mer, y_sill, d - 0.02)


def battlement_corner(w=0.6, h=1.3):
	"""The corner post: a square brick pier laid in a pinwheel (four bricks round a mortar core, turning the other
	way every course), on a limestone plinth, with a limestone string course and a chunky limestone cap."""
	hw = w / 2 - E
	g = MORT / 2
	before = set(bpy.data.objects)
	# the core sits 3.5 cm behind the brick faces (their dents reach 1.6 cm in: 1.5 cm behind made shimmer)
	K.blk((0, (0.225 + h - 0.17) / 2, 0), (2 * hw - 0.07, h - 0.17 - 0.225, 2 * hw - 0.07), HB.m_mortar(), bevel=0)
	HB.tag(HB.since(before), "mortar")

	def course(ya, yb, k, lime=False):
		tb = 0.2
		quads = [(-hw, hw - tb, hw - tb, hw), (hw - tb, hw, -hw + tb, hw), (-hw + tb, hw, -hw, -hw + tb), (-hw, -hw + tb, -hw, hw - tb)]
		if k % 2:   # mirrored pinwheel: joints never sit above each other
			quads = [(-hw + tb, hw, hw - tb, hw), (hw - tb, hw, -hw, hw - tb), (-hw, hw - tb, -hw, -hw + tb), (-hw, -hw + tb, -hw + tb, hw)]
		for (xa, xb, za, zb) in quads:
			sink = K.rng.uniform(0.0, 0.008)   # some bricks sit a little back (never past the outline)
			xa2, xb2, za2, zb2 = xa + g, xb - g, za + g, zb - g
			if xb >= hw - 1e-6 and xa > -hw + 1e-6 and xb - xa < 0.25:
				xb2 -= sink
			if za >= hw - 1e-6 and zb - za < 0.25:
				zb2 -= sink
			m = HB.m_lime() if lime else (kit.tex_mat("brick", "dark") if K.rng.random() < 0.08 else HB.m_brick())
			o = HB.cbox(((xa2 + xb2) / 2, (ya + yb) / 2, (za2 + zb2) / 2), (xb2 - xa2, yb - ya - 2 * g, zb2 - za2), m,
				cut=0.022 if lime else 0.016, dent=0.02 if lime else 0.016, free="xz", seeds=1 if lime else 0)
			HB.tag([o], "lime" if lime else "brick")
			o["dark"] = (not lime) and m.name.startswith("brick_dark")

	before = set(bpy.data.objects)   # the limestone plinth
	HB.tag([HB.cbox((0, (E + 0.22) / 2, 0), (2 * hw, 0.22 - E - 0.002, 2 * hw), HB.m_lime(), cut=0.035, dent=0.022, free="xz", seeds=1)], "lime")
	ys = [0.22 + 0.12 * i for i in range(7)]   # six brick courses to 0.94
	for i in range(6):
		course(ys[i], ys[i + 1], i)
	course(0.94, 1.02, 6, lime=True)            # limestone string course
	course(1.02, 1.14, 7)
	HB.tag([HB.cbox((0, (1.14 + h - E) / 2 + 0.001, 0), (2 * hw, h - E - 1.14 - 0.002, 2 * hw), HB.m_lime(), cut=0.04, dent=0.022, free="xz", seeds=1)], "lime")


PIECES = {"half_wall": half_wall, "wall_narrow": wall_narrow, "window_wide": window_wide, "sloped_wall": sloped_wall,
	"gable_26": gable_26, "gable_45": gable_45, "battlement": battlement, "battlement_corner": battlement_corner}


def band_uv(o, y0, row_h):
	"""Like HB.band_uv, for a band starting at y0 and row_h tall (one row of runes fills it)."""
	me = o.data
	if not me.uv_layers:
		me.uv_layers.new()
	uv = me.uv_layers.active.data
	for poly in me.polygons:
		for li in poly.loop_indices:
			v = me.vertices[me.loops[li].vertex_index].co
			uv[li].uv = (v.x / (3 * row_h), (v.z - y0) / (3 * row_h))


def paint():
	HB.paint()
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		if o.get("role") == "band" and "band0" in o:
			band_uv(o, o["band0"], o["bandh"])
		elif o.get("role") == "roundel":
			o.data.materials.clear()
			o.data.materials.append(HB.hb("hbrune", "a"))
			cx, cy, r = o["rc"]
			band_uv(o, cy - r, 2 * r)   # one row of runes across the disc


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
