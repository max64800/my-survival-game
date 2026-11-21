# Decor set VO (Nov 21): the Vigil of Orrin Stonejaw, a MEDIUM dungeon in cut stone (Stonehold style).
# Orrin Stonejaw kept a lifelong watch over a sealed deep passage. His sign: an open eye over a bar (the seal).
# Every carving is CUT INTO the stone (boolean difference, dark groove walls). One stone family (greystone),
# iron + bronze metal, one wood family (dark wood) where wood shows.
#   blender --background --factory-startup --python builds/decor_nov21_vo.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y). Wall pieces: flat back at +Y, stand on the floor.
#
# The 30 objects:
#  vo_vigil_brazier      the ever-burning brazier: carved pedestal, square stone fire basin with bronze bands, low embers
#  vo_brazier_cold       (story) an iron fire basket on a round step gone cold: black coals, poker dropped, coal scuttle tipped
#  vo_lookout_seat       the watchman's high stone seat on a two-step dais, eye carved in the back, hourglass on the arm
#  vo_spyhole_wall       (wall) a wall block with a stepped spyhole cut clean through (see through it), iron shutter swung open, stand-stone
#  vo_signal_horn        the great signal horn with bronze bands resting in two cut saddles on a carved stone stand
#  vo_vigil_candles      (wall) three stepped stone ledges of vigil candles, some lit, wax runs down the ledges
#  vo_kneeling_stone     his worn kneeling stone: two knee hollows cut deep, rune border, prayer rail, burnt candle stubs
#  vo_oath_tablet        (wall) a tall round-topped oath stele: his eye sign, a raised oath hand, seven rune lines cut in
#  vo_prayer_tablets     (wall) a stone shelf wall with two ledges of small carved prayer tablets standing in a row
#  vo_sealed_passage     (wall) the round sealed passage door, three great iron locking bars in staples, centre lock
#  vo_bar_rack           (wall) spare great locking bars resting in notched corbels, iron wedges, a ring of keys
#  vo_jawhelm_stand      his jaw-guard helm on a stone head-stand atop a carved plinth with bronze finials
#  vo_armour_stand       his lamellar coat on a stone cross-post: rows of iron lames, layered pauldrons, belt, boots
#  vo_warning_relief     (wall) warning carving: stairs down into a pit, clawed hands reaching up, pale eyes, the watching eye
#  vo_relief_oath        (wall) carved panel: Orrin raising his hand to swear the vigil before the king at the sealed door
#  vo_relief_last_watch  (wall) carved panel: old Orrin on his lookout seat, horn in hand, candles, the door below
#  vo_log_lectern        a stone lectern with the open watch log chained on, inkpot and quill, a small hourglass
#  vo_log_shelf          (wall) a stone shelf wall packed with leather watch logs, scroll tubes, carved bookends
#  vo_hourglass_stand    a big hourglass in a bronze turning cradle on a pedestal with a carved twelve-mark dial
#  vo_tally_wall         (wall) a panel of day-tallies cut in rows with year runes, the last row unfinished, chisel and mallet
#  vo_final_vigil        (story) Orrin's bones seated on his stone bench, the signal horn across his lap, candle burnt out
#  vo_horn_fallen        (story) the horn stand with one saddle broken off, the horn rolled on the floor, chips
#  vo_bar_snapped        (story, wall) a locking bar snapped, its staple torn from the cracked stone, halves on the floor
#  vo_claw_marks         (story, wall) a block wall gouged by four deep claw marks, a corner block broken out on the floor
#  vo_dropped_lantern    (story) his lantern dropped on its side, candle rolled out, log face-down, quill, stool knocked over
#  vo_oil_niche          (wall) an arched niche full of clay oil jars, bronze flasks, a funnel and a hanging ladle
#  vo_candle_rack        (wall) iron pegs hung with pairs of spare candles by their wicks, a candle mould and wax pot below
#  vo_wall_brazier       (wall) an iron fire basket on a carved stone corbel, strap to the wall, low embers, eye above
#  vo_axe_rest           his great axe standing in a carved socket block with a bronze collar, whetstone and oil flask
#  vo_orrin_bust         a stone bust of Orrin in his jaw-guard helm, braided beard, on a plinth with his name cut in
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import bar, chain, circ, prism, rod, shift, slim, turn  # noqa: E402
from decor_nov21_b import bone, skull  # noqa: E402
from decor_nov21_d import tube  # noqa: E402
from decor_nov21_f import glass  # noqa: E402
from decor_nov21_th import (bounds, candle, carve, coal_heap, cy, foot, frame_band, gline, group, lathe,  # noqa: E402
	niche_block, panel_wall, plinth, ring_at, rough_chips, runes, flat_back, face, beard)

S = lambda v=None: T("greystone", v)  # noqa: E731  (the one stone family)
GROOVE = lambda: C((0.018, 0.016, 0.014), 1.0)  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
LEA = lambda v="dark": kit.tex_mat("leather", v)  # noqa: E731
WOOD = lambda: T("wood", "dark")  # noqa: E731
BONE = lambda s=0.0: kit.mat("bone", s, rough=0.9)  # noqa: E731
COAL = lambda: C((0.012, 0.011, 0.011), 0.3)  # noqa: E731
EMBER = lambda: kit.glow("ember", 1.2)  # noqa: E731
WAX = lambda: C((0.55, 0.47, 0.32), 0.85)  # noqa: E731
PAPER = lambda: C((0.62, 0.55, 0.4), 0.95)  # noqa: E731
INK = lambda: C((0.04, 0.035, 0.03), 0.4)  # noqa: E731
HORN = lambda: C((0.3, 0.2, 0.1), 0.55)  # noqa: E731
SAND = lambda: C((0.55, 0.42, 0.25), 0.95)  # noqa: E731
CLAY = lambda: kit.tex_mat("clay", "b")  # noqa: E731
PI = math.pi


# ================= helpers =================
def czt(pts, zt, depth=0.012):
	"""A cutter for a TOP face at z = zt, outline in (x, y)."""
	return prism(pts, zt - depth, zt + 0.03, GROOVE(), axis="z")


def gtop(pts, w, zt, depth=0.01):
	out = [czt(bar(a, b, w), zt, depth) for a, b in zip(pts, pts[1:])]
	return out + [czt(circ(x, y, w * 0.55, n=6, wob=0), zt, depth) for x, y in pts[1:-1]]


def arcpts(cx, cz, r, a0, a1, n=12, sz=1.0):
	return [(cx + math.cos(a0 + (a1 - a0) * i / n) * r, cz + math.sin(a0 + (a1 - a0) * i / n) * r * sz) for i in range(n + 1)]


def eye_sign(cx, cz, s, yf, w=0.016, depth=0.013):
	"""Orrin's sign, cut in: an open almond eye with a deep pupil, five lashes, and the seal bar under it."""
	cuts = gline(arcpts(cx, cz, s, 0, PI, 10, 0.55), w, yf, depth)
	cuts += gline(arcpts(cx, cz, s, PI, 2 * PI, 10, 0.45), w, yf, depth)
	cuts += gline(arcpts(cx, cz, s * 0.32, 0, 2 * PI, 12), w * 0.8, yf, depth)
	cuts.append(cy(circ(cx, cz, s * 0.16, n=10, wob=0), yf, depth * 1.4))
	for k in range(5):
		a = PI * (0.2 + 0.15 * k)
		cuts += gline([(cx + math.cos(a) * s * 0.68, cz + math.sin(a) * s * 0.45), (cx + math.cos(a) * s * 0.95, cz + math.sin(a) * s * 0.75)], w * 0.8, yf, depth)
	cuts.append(cy(bar((cx - s, cz - s * 0.72), (cx + s, cz - s * 0.72), w * 1.6), yf, depth))
	for x in (cx - s, cx + s):
		cuts.append(cy(circ(x, cz - s * 0.72, w * 1.4, n=8, wob=0), yf, depth))
	return cuts


def arc_plate(cx, cy_, r0, r1, z0, z1, a0, a1, t, m, n=10, sy=1.0):
	"""A curved plate (part of a cone wall) around (cx, cy_): radius r0 at z0, r1 at z1, angles a0..a1, thickness t inward."""
	v, f = [], []
	for i in range(n + 1):
		a = a0 + (a1 - a0) * i / n
		ca, sa = math.cos(a), math.sin(a) * sy
		for r, z in ((r0, z0), (r1, z1), (r1 - t, z1), (r0 - t, z0)):
			v.append((cx + ca * r, cy_ + sa * r, z))
	for i in range(n):
		b, c = i * 4, i * 4 + 4
		for k in range(4):
			f.append((b + k, c + k, c + (k + 1) % 4, b + (k + 1) % 4))
	f += [(0, 1, 2, 3), (n * 4 + 3, n * 4 + 2, n * 4 + 1, n * 4)]
	return mesh(v, f, m)


# ----- round-2 helpers (owner Nov 22): the real dwarf as a form, armour that wraps all round, hollow horns/pots -----
DWARF = GAME / "assets" / "characters" / "dwarf"


def dwarf_form(keep, m, cuts=(), src="dwarf_body.glb", ratio=0.3, mats=None):
	"""The game's real dwarf (rest pose, 1.24 m, feet at z=0, face to -Y) as a carved/turned form: only the meshes whose
	name has a word in `keep`, cut by planes [(point, normal)] (the side the normal points to is thrown away and the hole
	closed), thinned to `ratio` of its faces, painted m (mats = {word: material} for some parts). Returns the objects."""
	before = set(bpy.data.objects[:])
	bpy.ops.import_scene.gltf(filepath=str(DWARF / src))
	bpy.context.view_layer.update()
	new = [o for o in bpy.data.objects if o not in before]
	out = []
	for o in new:
		if o.type != "MESH" or not any(k in o.name.lower() for k in keep):
			continue
		me = o.data.copy()
		me.transform(o.matrix_world)
		for a in list(me.color_attributes):  # unused vertex colours: half the file size (Nov 21 slim-down)
			me.color_attributes.remove(a)
		bm = bmesh.new()
		bm.from_mesh(me)
		for p, nrm in cuts:
			r = bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-5, plane_co=p, plane_no=nrm, clear_outer=True)
			edges = [e for e in r["geom_cut"] if isinstance(e, bmesh.types.BMEdge) and e.is_valid]
			if edges:
				bmesh.ops.holes_fill(bm, edges=edges, sides=0)
		bm.to_mesh(me)
		bm.free()
		if not me.vertices:
			continue
		mm = next((v for k, v in (mats or {}).items() if k in o.name.lower()), m)
		me.materials.clear()
		me.materials.append(mm)
		ob = bpy.data.objects.new("part", me)
		bpy.context.scene.collection.objects.link(ob)
		if "tile" in mm:
			kit._uv_box(ob, mm["tile"])
		if ratio < 1:
			ob.modifiers.new("thin", "DECIMATE").ratio = ratio
		out.append(ob)
	for o in new:
		bpy.data.objects.remove(o, do_unlink=True)
	return out


def body_pts(objs):
	return [o.matrix_world @ v.co for o in objs for v in o.data.vertices]


def body_ring(pts, z, n=36, band=0.02, c=None):
	"""How far a body reaches from its middle at height z, all the way round: (cx, cy, [radius per angle step])."""
	sel = [p for p in pts if abs(p.z - z) < band]
	if c is None:
		c = ((min(p.x for p in sel) + max(p.x for p in sel)) / 2, (min(p.y for p in sel) + max(p.y for p in sel)) / 2)
	cx, cy_ = c
	R = [0.0] * n
	for p in sel:
		k = int(round(math.atan2(p.y - cy_, p.x - cx) / (2 * PI) * n)) % n
		R[k] = max(R[k], math.hypot(p.x - cx, p.y - cy_))
	for _ in range(n):
		if all(R):
			break
		R = [r or max(R[k - 1], R[(k + 1) % n]) for k, r in enumerate(R)]
	R = [max(R[k - 1] * 0.5 + R[(k + 1) % n] * 0.5, r) for k, r in enumerate(R)]  # no deep notches between bins
	return cx, cy_, R


def ring_r(R, a):
	n = len(R)
	f = (a / (2 * PI) * n) % n
	k = int(f)
	return R[k] + (R[(k + 1) % n] - R[k]) * (f - k)


def lame_row(top, bot, z_top, z_bot, n, mats, off_t=0.012, off_b=0.03, t=0.008, gap=0.1, phase=0.0, seg=3, round_bot=0.0,
		rivet_m=None, rivet_r=0.006, a_skip=None):
	"""One row of n curved armour lames all the way round a body (top/bot = body_ring at z_top/z_bot): each lame follows
	the body, flares out at its foot (so the row below tucks under it), mats alternate. round_bot = how far the middle of
	each lame's foot hangs lower (scales). a_skip(a) -> True leaves a lame out (e.g. under an arm)."""
	(cxt, cyt, Rt), (cxb, cyb, Rb) = top, bot
	parts = {i: ([], []) for i in range(len(mats))}
	for k in range(n):
		a0 = 2 * PI * (k + phase + gap / 2) / n
		a1 = 2 * PI * (k + 1 + phase - gap / 2) / n
		if a_skip and a_skip((a0 + a1) / 2):
			continue
		v, f = parts[k % len(mats)]
		b0 = len(v)
		for i in range(seg + 1):
			a = a0 + (a1 - a0) * i / seg
			ca, sa = math.cos(a), math.sin(a)
			rt, rb = ring_r(Rt, a) + off_t, ring_r(Rb, a) + off_b
			zb = z_bot - round_bot * math.sin(PI * i / seg)
			v += [(cxt + ca * rt, cyt + sa * rt, z_top), (cxb + ca * rb, cyb + sa * rb, zb), (cxb + ca * (rb - t), cyb + sa * (rb - t), zb),
				(cxt + ca * (rt - t), cyt + sa * (rt - t), z_top)]
		for i in range(seg):
			b, c = b0 + i * 4, b0 + i * 4 + 4
			f += [(b + q, c + q, c + (q + 1) % 4, b + (q + 1) % 4) for q in range(4)]
		f += [(b0, b0 + 1, b0 + 2, b0 + 3), (b0 + seg * 4 + 3, b0 + seg * 4 + 2, b0 + seg * 4 + 1, b0 + seg * 4)]
		if rivet_m:
			a = (a0 + a1) / 2
			r = ring_r(Rt, a) + off_t + (off_b - off_t) * 0.25
			kit.rivet((cxt + math.cos(a) * r, cyt + math.sin(a) * r, z_top - (z_top - z_bot) * 0.25), rivet_m, r=rivet_r)
	return [mesh(v, f, mats[i]) for i, (v, f) in parts.items() if v]


def two_mat(o, m2, pick):
	"""Give the faces of one mesh for which pick(face index) is True a second material (inside of a horn or pot)."""
	o.data.materials.append(m2)
	for i, poly in enumerate(o.data.polygons):
		if pick(i):
			poly.material_index = 1
	return o


def hollow_lathe(outer, inner, c, m_out, m_in, seg=20):
	"""A turned shape that is really hollow (pot, cup, bucket): outer profile [(r, z)] bottom -> lip, inner profile lip ->
	deep bottom; the inside is painted m_in (dark). c = (x, y, z0)."""
	prof = list(outer) + list(inner)
	x0, y0, z0 = c
	v = [(x0 + math.cos(2 * PI * k / seg) * r, y0 + math.sin(2 * PI * k / seg) * r, z0 + z) for r, z in prof for k in range(seg)]
	n = len(prof)
	f = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	f += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	first_in = len(outer) * seg  # rows after the lip ring are inside
	return two_mat(mesh(v, f, m_out, smooth=True), m_in, lambda i: first_in <= i < (n - 1) * seg or i == len(f) - 1)


def hollow_horn(pts, rs, m_out, m_in, m_bell=None, bell_from=None, wall=0.007, back=4, seg=16):
	"""A horn swept along pts with radii rs that is really hollow at its wide end: the outside skin turns over a lip and
	runs `back` points down the inside (painted m_in, dark) to a deep closed throat. Outer faces from point bell_from on
	use m_bell (a bronze bell). One closed piece: the bell can't come loose from the horn."""
	pts = [Vector(p) for p in pts]
	n = len(pts)
	ds = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
	up = Vector((0, 0, 1)) if abs(ds[0].z) < 0.9 else Vector((1, 0, 0))
	us = [ds[0].cross(up).normalized()]
	for d in ds[1:]:  # carry the side vector along the bend (no twist)
		u = us[-1] - d * us[-1].dot(d)
		us.append(u.normalized())
	ring = lambda i, r: [tuple(pts[i] + (us[i] * math.cos(2 * PI * k / seg) + ds[i].cross(us[i]) * math.sin(2 * PI * k / seg)) * r) for k in range(seg)]  # noqa: E731
	rows = [ring(i, rs[i]) for i in range(n)]
	back = min(back, n - 1)
	rows += [ring(i, rs[i] - wall) for i in range(n - 1, n - 2 - back, -1)]
	v = [p for r in rows for p in r]
	m = len(rows)
	f = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(m - 1) for k in range(seg)]
	f += [tuple(reversed(range(seg))), tuple(range((m - 1) * seg, m * seg))]
	o = two_mat(mesh(v, f, m_out, smooth=True), m_in, lambda i: n * seg <= i < (m - 1) * seg or i == len(f) - 1)
	if m_bell and bell_from is not None:
		o.data.materials.append(m_bell)
		for i, poly in enumerate(o.data.polygons):
			if bell_from * seg <= i < n * seg:  # the bell's outside and its lip
				poly.material_index = 2
	return o


def jaw_helm(c, s=1.0, mi=None, mt=None, mr=None, ml=None, jaw=True, open_face=False):
	"""Orrin's jaw-guard helm, rim centre c, facing -Y: ribbed dome with a finial, crest, brow plate with brow arches and
	a nasal, riveted cheek plates, a three-lame neck guard at the back, and (jaw=True) three jaw lames.
	open_face=True leaves off the nasal, cheek plates and hinge bosses so the face shows."""
	mi, mt, mr = mi or IRON("dark"), mt or CU("b"), mr or CU("dark")
	ml = ml or (IRON("dark"), IRON("a"))
	x, y, z = c
	r = 0.2 * s
	dome = sphere((x, y, z), r, mi, scale=(1, 1.05, 0.95), seg=24, rings=12, cut=0.0)
	for pl in dome.data.polygons:
		pl.use_smooth = True
	kit.ring(r, 0.018 * s, (x, y, z + 0.012 * s), mt, seg=22).scale = (1, 1.05, 1)
	for k in range(14):
		a = 2 * PI * k / 14
		kit.rivet((x + math.cos(a) * r * 1.07, y + math.sin(a) * r * 1.12, z + 0.014 * s), mr, r=0.011 * s)
	tube([(x, y - r * 0.98, z + 0.05 * s), (x, y - r * 0.6, z + r * 0.8), (x, y, z + r * 0.97), (x, y + r * 0.6, z + r * 0.8),
		(x, y + r * 0.98, z + 0.05 * s)], 0.02 * s, 0.02 * s, mt, seg=6)  # crest comb
	arc_plate(x, y, r * 1.04, r * 1.0, z - 0.012 * s, z + 0.075 * s, -PI / 2 - 0.85, -PI / 2 + 0.85, 0.014 * s, mi, sy=1.05)  # brow
	for k in range(5):
		a = -PI / 2 - 0.6 + k * 0.3
		kit.rivet((x + math.cos(a) * r * 1.05, y + math.sin(a) * r * 1.1, z + 0.03 * s), mr, r=0.01 * s)
	for sd in (() if open_face else (-1, 1)):  # cheek plates down the sides
		a0, a1 = (-PI / 2 - 1.65, -PI / 2 - 0.85) if sd < 0 else (-PI / 2 + 0.85, -PI / 2 + 1.65)
		arc_plate(x, y, r * 0.96, r * 1.01, z - 0.2 * s, z + 0.006 * s, a0, a1, 0.014 * s, mi, sy=1.05)
	for phi in (0.0, PI, PI / 4, 3 * PI / 4, -PI / 4, -3 * PI / 4):  # raised ribs from the band to the crown
		rib = [(x + math.sin(th) * math.cos(phi) * r * 1.005, y + math.sin(th) * math.sin(phi) * r * 1.055, z + math.cos(th) * r * 0.955)
			for th in [PI / 2 * (1 - k / 6) * 0.93 + 0.1 for k in range(6)]]
		tube(rib, 0.009 * s, 0.006 * s, mt, seg=6)
		kit.rivet(rib[0], mr, r=0.01 * s)
		kit.rivet(rib[2], mr, r=0.008 * s)
	kit.cylinder(0.03 * s, 0.03 * s, (x, y, z + r * 0.95 + 0.006 * s), mt, verts=10, bevel=0.004)  # crown finial
	sphere((x, y, z + r * 0.95 + 0.035 * s), 0.022 * s, mr, seg=10, rings=6)
	for sd in (-1, 1):  # brow arches over the eyes
		arch = []
		for k in range(7):
			dx = sd * (0.015 + 0.1 * k / 6) * s
			arch.append((x + dx, y - math.sqrt((r * 1.035) ** 2 - dx * dx) * 1.05, z + (0.02 + 0.035 * math.sin(PI * k / 6)) * s))
		tube(arch, 0.007 * s, 0.007 * s, mt, seg=6)
	if not open_face:
		tube([(x, y - r * 1.07, z + 0.04 * s), (x, y - r * 1.11, z - 0.03 * s), (x, y - r * 1.1, z - 0.09 * s)], 0.012 * s, 0.009 * s, mt, seg=6)  # nasal
	for k in range(3):  # neck guard at the back: three lames, each lower one a little further out
		zt = z + 0.01 * s - k * 0.045 * s
		rk = r * 1.03 + k * 0.016 * s
		arc_plate(x, y, rk + 0.01 * s, rk, zt - 0.065 * s, zt, PI / 2 - 1.15, PI / 2 + 1.15, 0.012 * s, ml[k % 2], sy=1.05)
		for q in (-2, -1, 0, 1, 2):
			a = PI / 2 + q * 0.45
			kit.rivet((x + math.cos(a) * (rk + 0.002 * s), y + math.sin(a) * (rk + 0.002 * s) * 1.05, zt - 0.018 * s), mr, r=0.008 * s)
	for sd in (() if open_face else (-1, 1)):  # rivets down the cheek plates
		for q in range(3):
			a = -PI / 2 + sd * (1.0 + 0.25 * q)
			for zz in (z - 0.06 * s, z - 0.14 * s):
				kit.rivet((x + math.cos(a) * r * 1.0, y + math.sin(a) * r * 1.06, zz), mr, r=0.008 * s)
	for i in range(3 if jaw else 0):  # the jaw guard: three overlapping lames closing over the chin
		zt = z - 0.07 * s - i * 0.045 * s
		rt = r * (1.05 - i * 0.13)  # each lower lame tucks inside the one above (no two surfaces in one place)
		arc_plate(x, y, rt - 0.008 * s, rt, zt - 0.06 * s, zt, -PI / 2 - 0.86, -PI / 2 + 0.86, 0.012 * s, ml[i % 2], sy=1.05)
		for k in (-1, 0, 1):
			a = -PI / 2 + k * 0.5
			kit.rivet((x + math.cos(a) * (rt - 0.006 * s), y + math.sin(a) * (rt - 0.006 * s) * 1.05, zt - 0.02 * s), mr, r=0.009 * s)
	for sd in (() if open_face else (-1, 1)):  # big hinge bosses where the jaw meets the cheeks
		a = -PI / 2 + sd * 0.95
		sphere((x + math.cos(a) * r * 1.07, y + math.sin(a) * r * 1.1, z - 0.11 * s), 0.024 * s, mt, scale=(1, 1, 1), seg=10, rings=6)


def hourglass(c, s=1.0, frame=None):
	"""An hourglass standing at c (bottom centre): wood end plates, three bronze posts, glass bulbs, sand mostly run down."""
	x, y, z = c
	fm = frame or WOOD()
	H = 0.3 * s
	kit.cylinder(0.08 * s, 0.025 * s, (x, y, z + 0.0125 * s), fm, verts=12, bevel=0.004)
	kit.cylinder(0.08 * s, 0.025 * s, (x, y, z + H - 0.0125 * s), fm, verts=12, bevel=0.004)
	g = glass((0.75, 0.82, 0.8), 0.28)
	h2 = (H - 0.05 * s) / 2
	lathe([(0.012 * s, 0), (0.05 * s, h2 * 0.15), (0.056 * s, h2 * 0.5), (0.035 * s, h2 * 0.85), (0.008 * s, h2)], (x, y, z + 0.024 * s), g, seg=14)
	lathe([(0.008 * s, 0), (0.035 * s, h2 * 0.15), (0.056 * s, h2 * 0.5), (0.05 * s, h2 * 0.85), (0.012 * s, h2)], (x, y, z + 0.024 * s + h2), g, seg=14)
	lathe([(0.044 * s, 0), (0.046 * s, h2 * 0.25), (0.003 * s, h2 * 0.62)], (x, y, z + 0.03 * s), SAND(), seg=12)  # sand heap below
	lathe([(0.02 * s, 0), (0.035 * s, h2 * 0.12), (0.022 * s, h2 * 0.22)], (x, y, z + 0.026 * s + h2 * 1.02), SAND(), seg=10)  # last sand above
	rod((x, y, z + 0.024 * s + h2 * 0.5), (x, y, z + 0.024 * s + h2 * 1.1), 0.003 * s, SAND(), seg=4)  # the falling thread
	for k in range(3):
		a = 2 * PI * k / 3 + 0.3
		px, py = x + math.cos(a) * 0.066 * s, y + math.sin(a) * 0.066 * s
		rod((px, py, z + 0.02 * s), (px, py, z + H - 0.02 * s), 0.008 * s, CU("b"), seg=6)
		for zz in (z + H * 0.35, z + H * 0.65):
			kit.ring(0.011 * s, 0.004 * s, (px, py, zz), CU("dark"), seg=8)


def book_flat(x, y, z, w, d, h, m, rotz=0.0):
	"""A closed book lying flat: two covers, pages between (set back), spine with two bronze bands."""
	def b():
		B((w, d, 0.007), (0, 0, 0.0035), m, bevel=0.002)
		B((w, d, 0.007), (0, 0, h - 0.0035), m, bevel=0.002)
		B((0.012, d - 0.004, h + 0.004), (-w / 2 + 0.003, 0, h / 2), m, bevel=0.003)
		B((w - 0.016, d - 0.012, h - 0.01), (0.002, 0, h / 2), PAPER(), bevel=0.001)
		for yy in (-d * 0.3, d * 0.3):
			B((0.016, 0.012, h + 0.012), (-w / 2 + 0.002, yy, h / 2), CU("dark"), bevel=0.001)
	return group(b, at=(x, y, z), rot=(0, 0, rotz))


def book_stand(x, y, z, w, d, h, m, tilt=0.0):
	"""A book standing on a shelf, spine to the front (-Y), two raised spine bands and a label plate."""
	def b():
		B((w, d, h), (0, 0, h / 2), m, bevel=0.004)
		for zz in (h * 0.22, h * 0.78):
			B((w + 0.004, 0.012, 0.01), (0, -d / 2 + 0.003, zz), m, bevel=0.002)  # raised bands (books stand 8 mm apart)
		B((w * 0.6, 0.006, h * 0.18), (0, -d / 2 - 0.001, h * 0.5), CU("b"), bevel=0.001)
	return group(b, at=(x, y, z), rot=(0, tilt, 0))


def open_log(c, w=0.42, d=0.3, rx=0.0):
	"""An open watch log, centre c, pages with ink lines, a ribbon; tilted by rx degrees (lectern slope)."""
	def b():
		B((w, d, 0.008), (0, 0, 0.004), LEA("dark"), bevel=0.002)
		for sd in (-1, 1):
			B((w / 2 - 0.02, d - 0.025, 0.022), (sd * (w / 4 - 0.002), 0, 0.019), PAPER(), bevel=0.003)
			for k in range(8):
				ln = (0.6 + 0.4 * ((k * 7 + (sd > 0) * 3) % 5) / 4) * (w / 2 - 0.07)
				B((ln, 0.006, 0.003), (sd * (w / 4), -d / 2 + 0.05 + k * (d - 0.09) / 7, 0.0305), INK(), bevel=0)
		tube([(0.0, -0.02, 0.03), (0.01, -d / 2 + 0.02, 0.03), (0.015, -d / 2 - 0.01, 0.0), (0.02, -d / 2 - 0.02, -0.06)], 0.006, 0.005, C((0.25, 0.04, 0.03), 0.8), seg=4)
	return group(b, at=c, rot=(rx, 0, 0))


def inkpot_quill(x, y, z):
	lathe([(0.03, 0), (0.036, 0.01), (0.033, 0.045), (0.016, 0.055), (0.017, 0.066), (0.012, 0.067), (0.01, 0.02)], (x, y, z), CU("b"), seg=12)
	kit.cylinder(0.011, 0.004, (x, y, z + 0.05), INK(), verts=10, bevel=0)
	rod((x, y, z + 0.03), (x + 0.04, y + 0.03, z + 0.2), 0.003, C((0.7, 0.65, 0.55), 0.8), seg=4)
	q = prism([(0.0, 0.0), (0.012, 0.03), (0.014, 0.11), (0.0, 0.13), (-0.006, 0.06)], -0.0015, 0.0015, C((0.62, 0.58, 0.5), 0.9))  # feather vane
	q.matrix_world = Matrix.Translation((x + 0.02, y + 0.015, z + 0.085)) @ Matrix.Rotation(math.radians(-14), 4, "Y") @ Matrix.Rotation(math.radians(-35), 4, "Z")


def lantern(lit=False):
	"""An iron watch lantern around the origin, bottom at z = 0: horn panes, four posts, cone top, ring handle."""
	kit.cylinder(0.085, 0.03, (0, 0, 0.015), IRON("dark"), verts=8, bevel=0.004)
	for k in range(4):
		a = PI / 4 + k * PI / 2
		rod((math.cos(a) * 0.075, math.sin(a) * 0.075, 0.02), (math.cos(a) * 0.075, math.sin(a) * 0.075, 0.23), 0.009, IRON("dark"), seg=6)
	for k in range(4):
		a = k * PI / 2
		B((0.1, 0.004, 0.19), (math.cos(a) * 0.05, math.sin(a) * 0.05, 0.125), HORN() if not lit else C((0.75, 0.5, 0.2), 0.4, glow=0.6),
			bevel=0.001, rot=(0, 0, math.degrees(a) + 90))
	kit.ring(0.078, 0.008, (0, 0, 0.23), IRON("a"), seg=12)
	kit.cone(0.09, 0.025, 0.07, (0, 0, 0.268), IRON("dark"), verts=8)
	kit.ring(0.035, 0.007, (0, 0, 0.33), IRON("a"), rot=(90, 0, 0), seg=12)
	kit.cylinder(0.018, 0.06, (0, 0, 0.06), WAX(), verts=8)


def vfig(x, z, s, f, pose, yf, depth=0.014, helmed=True):
	"""A carved dwarf in profile (facing +x when f = 1) as sunk shapes on a panel at y = yf.
	Poses: oath (hand raised), staff (king with crown and staff), horn (blowing the horn), seated (on a seat, horn in lap)."""
	P = []
	hip = 0.13 if pose == "seated" else 0.0
	if pose == "seated":
		for dx in (-0.02, 0.02):
			P.append(bar((x + dx * s, z + 0.17 * s), (x + f * 0.15 * s, z + 0.16 * s), 0.055 * s))  # thighs
			P.append(bar((x + f * 0.15 * s, z + 0.16 * s), (x + f * 0.16 * s, z + 0.02 * s), 0.05 * s))  # shins
		P.append([(x + f * 0.13 * s, z), (x + f * 0.22 * s, z), (x + f * 0.21 * s, z + 0.035 * s), (x + f * 0.13 * s, z + 0.035 * s)])
		P.append([(x - 0.1 * s, z), (x + 0.06 * s, z), (x + 0.06 * s, z + 0.13 * s), (x - 0.1 * s, z + 0.13 * s)])  # the seat
		P.append(bar((x - f * 0.1 * s, z + 0.12 * s), (x - f * 0.13 * s, z + 0.6 * s), 0.035 * s))  # high seat back
	else:
		for dx in (-0.035, 0.035):
			P.append(bar((x + dx * s, z), (x + dx * s * 0.8 + f * 0.01 * s, z + 0.13 * s), 0.055 * s))
			P.append([(x + dx * s - 0.035 * s, z), (x + dx * s + f * 0.06 * s, z), (x + dx * s + f * 0.05 * s, z + 0.035 * s), (x + dx * s - 0.03 * s, z + 0.035 * s)])
	zb = z + hip * s * 0.4
	P.append([(x - 0.09 * s, zb + 0.11 * s), (x + 0.09 * s, zb + 0.11 * s), (x + 0.075 * s, zb + 0.3 * s), (x - 0.075 * s, zb + 0.3 * s)])
	P.append(circ(x, zb + 0.35 * s, 0.065 * s, n=12, wob=0))
	if helmed:  # the jaw-guard helm: dome and the jaw plate
		P.append([(x - 0.075 * s, zb + 0.37 * s), (x + 0.075 * s, zb + 0.37 * s), (x + 0.06 * s, zb + 0.43 * s), (x, zb + 0.455 * s), (x - 0.06 * s, zb + 0.43 * s)])
		P.append([(x + f * 0.02 * s, zb + 0.33 * s), (x + f * 0.095 * s, zb + 0.33 * s), (x + f * 0.085 * s, zb + 0.28 * s), (x + f * 0.03 * s, zb + 0.27 * s)])
	if pose == "staff":  # a king: crown points instead of a helm, a long staff
		P.append([(x - 0.06 * s, zb + 0.4 * s), (x - 0.06 * s, zb + 0.47 * s), (x - 0.03 * s, zb + 0.43 * s), (x, zb + 0.48 * s), (x + 0.03 * s, zb + 0.43 * s),
			(x + 0.06 * s, zb + 0.47 * s), (x + 0.06 * s, zb + 0.4 * s)])
	P.append([(x, zb + 0.33 * s), (x + f * 0.085 * s, zb + 0.31 * s), (x + f * 0.06 * s, zb + 0.14 * s), (x + f * 0.02 * s, zb + 0.1 * s)])  # beard
	sx, sz = x + f * 0.03 * s, zb + 0.27 * s
	if pose == "oath":
		P.append(bar((sx, sz), (x + f * 0.13 * s, zb + 0.5 * s), 0.04 * s))
		hx, hz = x + f * 0.14 * s, zb + 0.53 * s
		P.append(circ(hx, hz, 0.03 * s, n=10, wob=0))
		for k in range(4):
			P.append(bar((hx - 0.018 * s + k * 0.012 * s, hz), (hx - 0.02 * s + k * 0.013 * s, hz + 0.06 * s), 0.009 * s))
		P.append(bar((hx - f * 0.02 * s, hz - 0.01 * s), (hx - f * 0.05 * s, hz + 0.02 * s), 0.01 * s))
	elif pose == "staff":
		P.append(bar((sx, sz), (x + f * 0.14 * s, zb + 0.22 * s), 0.04 * s))
		P.append(bar((x + f * 0.15 * s, z), (x + f * 0.15 * s, zb + 0.66 * s), 0.022 * s))
		P.append(circ(x + f * 0.15 * s, zb + 0.68 * s, 0.035 * s, n=10, wob=0))
		P.append([(x - f * 0.08 * s, zb + 0.3 * s), (x - f * 0.16 * s, z + 0.02 * s), (x - f * 0.04 * s, z + 0.02 * s)])  # cloak
	elif pose in ("horn", "seated"):
		mx, mz = x + f * 0.07 * s, zb + 0.32 * s
		P.append(bar((sx, sz), (x + f * 0.12 * s, zb + (0.33 if pose == "horn" else 0.2) * s), 0.04 * s))
		if pose == "horn":
			P.append(bar((mx, mz), (x + f * 0.42 * s, zb + 0.46 * s), 0.025 * s, 0.07 * s))
			P.append(circ(x + f * 0.43 * s, zb + 0.465 * s, 0.05 * s, n=10, sz=1.3, wob=0))
		else:
			P.append(bar((x - f * 0.05 * s, zb + 0.18 * s), (x + f * 0.3 * s, zb + 0.24 * s), 0.025 * s, 0.065 * s))
	return [cy(p, yf, depth) for p in P]


def round_door_cuts(cx, cz, r, yf, w=0.016, depth=0.013, bars=3):
	"""A sealed round door drawn in grooves: door circle, a ring of arch stones with a keystone, the locking bars."""
	cuts = gline(arcpts(cx, cz, r, -0.25 * PI, 1.25 * PI, 18), w, yf, depth)
	cuts += gline(arcpts(cx, cz, r * 1.25, -0.2 * PI, 1.2 * PI, 18), w, yf, depth)
	for k in range(9):  # arch stone joints
		a = -0.15 * PI + k * 1.3 * PI / 8
		if abs(a - PI / 2) < 0.2:
			continue
		cuts.append(cy(bar((cx + math.cos(a) * r, cz + math.sin(a) * r), (cx + math.cos(a) * r * 1.25, cz + math.sin(a) * r * 1.25), w * 0.8), yf, depth))
	cuts.append(cy([(cx - r * 0.1, cz + r * 1.0), (cx + r * 0.1, cz + r * 1.0), (cx + r * 0.15, cz + r * 1.32), (cx - r * 0.15, cz + r * 1.32)], yf, depth))  # keystone
	cuts.append(cy(bar((cx - r * 1.3, cz - r * 0.72), (cx + r * 1.3, cz - r * 0.72), w), yf, depth))  # floor line
	for k in range(bars):
		zz = cz - r * 0.4 + k * r * 0.4
		ww = math.sqrt(max(0.0, r * r - (zz - cz) ** 2)) * 0.95
		cuts.append(cy(bar((cx - ww, zz), (cx + ww, zz), w * 1.6), yf, depth))
	return cuts


def hand_cuts(hx, hz, s, yf, depth=0.013):
	"""An open hand held up (an oath, or 'stop'), cut in: palm, four fingers, thumb, wrist."""
	cuts = [cy(circ(hx, hz, 0.05 * s, n=12, sz=1.1, wob=0), yf, depth)]
	for k in range(4):
		cuts.append(cy(bar((hx - 0.033 * s + k * 0.022 * s, hz + 0.02 * s), (hx - 0.036 * s + k * 0.024 * s, hz + (0.1 - abs(k - 1.5) * 0.012) * s), 0.016 * s), yf, depth))
	cuts.append(cy(bar((hx + 0.04 * s, hz - 0.01 * s), (hx + 0.085 * s, hz + 0.04 * s), 0.016 * s), yf, depth))
	cuts.append(cy(bar((hx - 0.02 * s, hz - 0.04 * s), (hx - 0.01 * s, hz - 0.1 * s), 0.05 * s), yf, depth))
	return cuts


def iron_bar(x0, x1, y, z, h=0.1, d=0.11, m=None):
	"""A great square locking bar from x0 to x1 with flared end caps and rivet bands."""
	m = m or IRON("dark")
	B((x1 - x0, d, h), ((x0 + x1) / 2, y, z), m, bevel=0.012)
	for x in (x0 + 0.03, x1 - 0.03):
		B((0.05, d + 0.024, h + 0.024), (x, y, z), IRON("a"), bevel=0.008)
	n = max(2, int((x1 - x0) / 0.35))
	for i in range(1, n):
		x = x0 + (x1 - x0) * i / n
		B((0.035, d + 0.016, h + 0.016), (x, y, z), IRON("a"), bevel=0.005)
		kit.rivet((x, y - d / 2 - 0.009, z), IRON("b"), r=0.012)


def horn(L=1.1, r0=0.028, r1=0.1, m=None, bell=True):
	"""The signal horn lying along +X from the origin (mouthpiece) and curving up, ONE closed piece: the horn flares into
	a bronze bell that is open and dark deep inside (owner: horns are really hollow). Returns centre points+radii."""
	m = m or HORN()
	pts, rs = [], []
	for i in range(11):
		t = i / 10
		pts.append((L * t, 0, 0.16 * t * t))
		rs.append(r0 + (r1 - r0) * t)
	d = Vector((1, 0, 0.32)).normalized()
	end = Vector(pts[-1])
	nb = len(pts)
	if bell:
		for dl, rr in ((0.035, 1.12), (0.07, 1.32), (0.1, 1.6), (0.112, 1.85), (0.122, 1.97), (0.128, 1.9)):  # flare, rolled lip
			pts.append(tuple(end + d * dl))
			rs.append(r1 * rr)
	hollow_horn(pts, rs, m, GROOVE(), CU("a"), bell_from=nb - 1, wall=0.008, back=9, seg=18)
	kit.cylinder(r0 * 0.9, 0.05, (-0.02, 0, 0), CU("b"), rot=(0, 90, 0), verts=10)  # mouthpiece
	kit.ring(r0 * 1.3, 0.008, (-0.045, 0, 0), CU("dark"), rot=(0, 90, 0), seg=10)
	for t in (0.12, 0.4, 0.7):
		p = Vector((L * t, 0, 0.16 * t * t))
		ring_at(p, (1, 0, 0.32 * t), r0 + (r1 - r0) * t + 0.004, 0.011, CU("b"))
	if bell:
		ring_at(end, d, r1 + 0.005, 0.012, CU("dark"))  # where horn meets bell
	return pts[:nb], rs[:nb]


def chisel_mallet(x, y, z):
	rod((x - 0.12, y, z + 0.011), (x + 0.06, y - 0.02, z + 0.011), 0.01, IRON("dark"), seg=6)
	prism([(0, -0.01), (0.04, -0.004), (0.04, 0.004), (0, 0.01)], z + 0.003, z + 0.017, IRON("a"), axis="z").location = (x + 0.06, y - 0.02, 0)
	kit.cylinder(0.016, 0.05, (x - 0.14, y + 0.001, z + 0.016), WOOD(), rot=(0, 90, 0), verts=8)
	log((x - 0.02, y + 0.09, z + 0.018), (x - 0.26, y + 0.11, z + 0.018), 0.016, WOOD(), seg=8, rings=1, ends=False, bend=0)
	kit.cylinder(0.042, 0.12, (x + 0.03, y + 0.088, z + 0.042), WOOD(), rot=(0, 0, 0), verts=10, bevel=0.008)
	kit.ring(0.042, 0.006, (x + 0.03, y + 0.088, z + 0.075), IRON("a"), seg=12)
	kit.ring(0.042, 0.006, (x + 0.03, y + 0.088, z + 0.01), IRON("a"), seg=12)


# ================= models =================
def vo_vigil_brazier():
	body, top = plinth(0.55, 0.55, 0.6)
	carve(body, eye_sign(0, 0.38, 0.14, -0.275) + runes(-0.2, 0.2, 0.16, -0.275, h=0.05, gap=0.05, under=False))
	bz = top - 0.005
	basin = B((0.82, 0.82, 0.25), (0, 0, bz + 0.125), S("b"), bevel=0.02)
	cuts = [B((0.64, 0.64, 0.3), (0, 0, bz + 0.08 + 0.15), S("c"), bevel=0.01)]
	for k in range(6):  # a row of cut flame-tongue notches round the front
		x = -0.3 + k * 0.12
		cuts.append(cy([(x - 0.035, bz + 0.05), (x + 0.035, bz + 0.05), (x + 0.008, bz + 0.17), (x - 0.01, bz + 0.12)], -0.41, 0.013))
	carve(basin, cuts)
	for s_ in (-1, 1):  # bronze bands round the basin
		B((0.86, 0.022, 0.045), (0, s_ * 0.41, bz + 0.215), CU("b"), bevel=0.005)
		B((0.022, 0.8, 0.045), (s_ * 0.41, 0, bz + 0.215), CU("b"), bevel=0.005)
		for x in (-0.33, 0.0, 0.33):
			kit.rivet((x, s_ * 0.423, bz + 0.215), CU("dark"), r=0.012)
			kit.rivet((s_ * 0.423, x, bz + 0.215), CU("dark"), r=0.012)
	for sx in (-1, 1):  # carved horn stones on the corners
		for sy in (-1, 1):
			kit.cone(0.06, 0.02, 0.12, (sx * 0.36, sy * 0.36, bz + 0.3), S("a"), verts=6)
	coal_heap(0, 0, bz + 0.08, 0.27, 46, hot=12, seed=3)
	kit.fire_spot((0, 0, bz + 0.2), 0.35)
	rod((0.43, -0.12, 0.012), (0.285, -0.08, 0.5), 0.011, IRON("dark"))  # poker leaning on the pedestal
	tube([(0.285, -0.08, 0.5), (0.27, -0.075, 0.56), (0.3, -0.08, 0.6)], 0.011, 0.008, IRON("dark"), seg=6)
	kit.ring(0.02, 0.006, (0.43, -0.12, 0.03), IRON("a"), rot=(90, 0, 15), seg=8)


def vo_brazier_cold():
	foot((0.78, 0.78, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	ped = kit.cylinder(0.3, 0.5, (0, 0, 0.345), S("b"), rot=(0, 0, 22.5), verts=8, bevel=0.01)
	yf = -0.3 * math.cos(math.radians(22.5))
	carve(ped, eye_sign(0, 0.42, 0.1, yf, w=0.013) + runes(-0.09, 0.09, 0.22, yf, h=0.045, gap=0.04, under=False))
	kit.cylinder(0.36, 0.06, (0, 0, 0.62), S("a"), rot=(0, 0, 22.5), verts=8, bevel=0.012)
	kit.cylinder(0.32, 0.06, (0, 0, 0.125), S("a"), rot=(0, 0, 22.5), verts=8, bevel=0.012)
	bz = 0.7
	lathe([(0.1, 0), (0.22, 0.04), (0.32, 0.12), (0.35, 0.19), (0.37, 0.215), (0.33, 0.22), (0.3, 0.14), (0.2, 0.06)], (0, 0, bz), CU("b"), seg=22)
	kit.ring(0.35, 0.013, (0, 0, bz + 0.18), CU("dark"), seg=24)
	for k in range(12):
		a = 2 * PI * k / 12
		kit.rivet((math.cos(a) * 0.345, math.sin(a) * 0.345, bz + 0.15), CU("dark"), r=0.011)
	for k in range(4):  # four bronze claw feet on the cap
		a = PI / 4 + k * PI / 2
		ca, sa = math.cos(a), math.sin(a)
		tube([(ca * 0.12, sa * 0.12, bz + 0.03), (ca * 0.2, sa * 0.2, bz - 0.02), (ca * 0.23, sa * 0.23, 0.655)], 0.026, 0.02, CU("dark"), seg=7)
		for f in (-1, 0, 1):
			kit.cone(0.012, 0.004, 0.05, (ca * 0.23 + math.cos(a + f * 0.6) * 0.025, sa * 0.23 + math.sin(a + f * 0.6) * 0.025, 0.655), CU("dark"), rot=(0, 90, math.degrees(a + f * 0.6)), verts=6)
	for sd in (-1, 1):
		ring_at((sd * 0.385, 0, bz + 0.16), (0, 1, 0), 0.045, 0.01, CU("dark"))
	coal_heap(0, 0, bz + 0.07, 0.24, 60, hot=0, seed=7)  # cold: not one ember left
	# the coal scuttle, kicked over, a few cold coals spilled
	def scuttle():
		lathe([(0.1, 0), (0.12, 0.2), (0.11, 0.2), (0.09, 0.012)], (0, 0, 0), IRON("dark"), seg=14)
		kit.ring(0.12, 0.008, (0, 0, 0.2), IRON("a"), seg=14)
		tube([(-0.12, 0, 0.17), (-0.06, 0, 0.27), (0.06, 0, 0.27), (0.12, 0, 0.17)], 0.007, 0.007, IRON("a"), seg=5)
	sc = group(scuttle, rot=(0, 90, 20))
	lo, _ = bounds(sc)
	shift(sc, (0.55, -0.48, -lo.z))
	for k in range(9):
		x, y = 0.74 + k * 0.035 + J(0.03), -0.36 + J(0.07) + k * 0.012
		sz = rng.uniform(0.022, 0.04)
		o = kit.gem((x, y, 0), (sz * 1.2, sz, sz * 0.7), COAL(), seed=k + 60)
		o.location.z = -min(v.co.z for v in o.data.vertices)
	rod((-0.45, -0.55, 0.012), (-0.05, -0.7, 0.012), 0.011, IRON("dark"))  # dropped poker
	tube([(-0.05, -0.7, 0.012), (0.0, -0.72, 0.012), (0.02, -0.68, 0.012)], 0.011, 0.009, IRON("dark"), seg=6)
	kit.ring(0.022, 0.006, (-0.47, -0.545, 0.012), IRON("a"), rot=(0, 0, 0), seg=8)


def vo_lookout_seat():
	B((1.05, 0.95, 0.12), (0, 0, 0.06), S("c"), bevel=0.02)
	B((0.84, 0.76, 0.12), (0, 0.04, 0.175), S("a"), bevel=0.02)
	seat = B((0.6, 0.5, 0.26), (0, 0.06, 0.36), S("b"), bevel=0.02)
	carve(seat, runes(-0.22, 0.22, 0.36, -0.19, h=0.05, gap=0.045, under=False))
	B((0.66, 0.54, 0.05), (0, 0.04, 0.505), S("a"), bevel=0.015)
	back = B((0.66, 0.16, 0.95), (0, 0.27, 0.97), S("b"), bevel=0.02)
	carve(back, eye_sign(0, 1.12, 0.16, 0.19) + gline([(-0.26, 0.62), (0.26, 0.62), (0.26, 1.36), (-0.26, 1.36), (-0.26, 0.62)], 0.016, 0.19)
		+ runes(-0.2, 0.2, 0.78, 0.19, h=0.05, gap=0.045))
	prism([(-0.36, 1.43), (0.36, 1.43), (0.24, 1.53), (0.0, 1.6), (-0.24, 1.53)], 0.21, 0.35, S("a"))  # crest
	for s_ in (-1, 1):  # arms
		B((0.1, 0.46, 0.26), (s_ * 0.31, 0.03, 0.66), S("b"), bevel=0.02)
		kit.cylinder(0.07, 0.11, (s_ * 0.31, -0.2, 0.75), S("a"), rot=(0, 90, 0), verts=12, bevel=0.01)
		B((0.13, 0.5, 0.05), (s_ * 0.31, 0.03, 0.8), S("a"), bevel=0.012)
	hourglass((-0.31, 0.06, 0.823), s=0.6)
	# a lantern hook iron in the side of the back
	B((0.05, 0.06, 0.12), (0.355, 0.27, 1.25), IRON("dark"), bevel=0.006)
	tube([(0.37, 0.27, 1.23), (0.46, 0.27, 1.25), (0.48, 0.27, 1.18)], 0.012, 0.01, IRON("dark"), seg=6)
	group(lambda: lantern(False), at=(0.48, 0.27, 0.85), scale=0.9)
	B((0.4, 0.2, 0.08), (0, -0.33, 0.27), S("c"), bevel=0.015)  # footrest stone


def vo_spyhole_wall():
	foot((1.3, 0.48, 0.1), (0, -0.05, 0.05), tone=S("c"), bevel=0.02)
	wall = B((1.2, 0.36, 1.55), (0, 0.0, 0.095 + 0.775), S("b"), bevel=0.02)
	yf = -0.18
	cz = 1.05
	# the spyhole: a stepped frame in front, a clear opening right through the wall (you can see the room behind before
	# you open the door, owner Nov 22), and a splayed step on the back face too
	cuts = [B((0.34, 0.1, 0.62), (0, yf, cz), S("c"), bevel=0.0), B((0.27, 0.22, 0.46), (0, yf + 0.04, cz), S("c"), bevel=0.0),
		B((0.2, 0.6, 0.3), (0, 0, cz), S("c"), bevel=0.0), B((0.28, 0.1, 0.4), (0, 0.18, cz), S("c"), bevel=0.0)]
	cuts += eye_sign(0, 1.5, 0.11, yf, w=0.014)
	for z in (0.3, 0.62):  # ashlar joints
		cuts.append(cy(bar((-0.6, z), (0.6, z), 0.014), yf, 0.01))
	for x, z0, z1 in ((-0.25, 0.095, 0.3), (0.3, 0.095, 0.3), (0.05, 0.3, 0.62), (-0.4, 0.62, 1.65), (0.4, 0.62, 1.65)):
		cuts.append(cy(bar((x, z0), (x, z1), 0.014), yf, 0.01))
	cuts += runes(-0.5, -0.25, 0.48, yf, h=0.05, gap=0.04) + runes(0.25, 0.5, 0.48, yf, h=0.05, gap=0.04)
	carve(wall, cuts)
	B((0.46, 0.14, 0.06), (0, yf - 0.06, cz - 0.34), S("a"), bevel=0.012)  # sighting sill
	B((1.26, 0.42, 0.07), (0, 0, 1.68), S("a"), bevel=0.015)
	# the iron shutter, swung open on two hinges at the left jamb
	hx = -0.19
	for z in (cz - 0.2, cz + 0.2):
		B((0.05, 0.03, 0.05), (hx, yf - 0.005, z), IRON("dark"), bevel=0.004)
		kit.cylinder(0.013, 0.08, (hx - 0.02, yf - 0.03, z), IRON("a"), verts=8)
	sh = B((0.3, 0.025, 0.56), (hx - 0.02 - 0.15 * math.cos(math.radians(70)), yf - 0.03 - 0.15 * math.sin(math.radians(70)), cz), IRON("b"), bevel=0.006, rot=(0, 0, 70))
	del sh
	for z in (cz - 0.2, cz + 0.2):
		d = Vector((-math.cos(math.radians(70)), -math.sin(math.radians(70)), 0))
		p = Vector((hx - 0.02, yf - 0.03, z))
		B((0.26, 0.032, 0.045), tuple(p + d * 0.13), IRON("dark"), bevel=0.004, rot=(0, 0, 70))
		for t in (0.06, 0.2):
			kit.rivet(tuple(p + d * t + Vector((0.016, -0.006, 0))), IRON("a"), r=0.01)
	B((0.5, 0.36, 0.14), (0, -0.4, 0.07), S("a"), bevel=0.015)  # stand-stone for a short dwarf


def vo_signal_horn():
	body = B((1.15, 0.38, 0.5), (0, 0, 0.1 + 0.25), S("b"), bevel=0.02)
	foot((1.25, 0.48, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	carve(body, runes(-0.48, -0.08, 0.36, -0.19, h=0.06, gap=0.05) + eye_sign(0.24, 0.38, 0.12, -0.19) + gline([(-0.53, 0.15), (0.53, 0.15), (0.53, 0.56), (-0.53, 0.56), (-0.53, 0.15)], 0.014, -0.19))
	top = 0.6
	B((1.2, 0.42, 0.05), (0, 0, top - 0.02), S("a"), bevel=0.012)
	top += 0.005
	group(horn, at=(-0.55, 0, top + 0.17))
	L, r0, r1 = 1.1, 0.028, 0.1
	for xs in (-0.3, 0.3):
		t = (xs + 0.55) / L
		zc = top + 0.17 + 0.16 * t * t
		rr = r0 + (r1 - r0) * t
		h = zc - top
		cr = B((0.12, 0.26, h), (xs, 0, top + h / 2 - 0.004), S("a"), bevel=0.012)
		cutter = prism(circ(0, zc, rr + 0.004, n=18, wob=0), xs - 0.1, xs + 0.1, S("c"), axis="x")
		carve(cr, [cutter])
		B((0.14, 0.28, 0.03), (xs, 0, top + 0.01), S("c"), bevel=0.008)


def vo_vigil_candles():
	p, yf = panel_wall(1.15, 1.15, 0.18)
	carve(p, eye_sign(0, 1.03, 0.12, yf) + runes(-0.4, 0.4, 0.86, yf, h=0.05, gap=0.05, under=False))
	frame_band(1.15, 1.15, yf, z0=0.095, t=0.05)
	rows = ((0.24, 7, 0.95), (0.47, 6, 0.85), (0.68, 5, 0.75))
	for z, n, w in rows:
		dpt = 0.17
		B((w, dpt, 0.06), (0, yf - dpt / 2 + 0.005, z), S("a"), bevel=0.012)
		for k in range(n):
			x = -w / 2 + 0.07 + (w - 0.14) * k / (n - 1) + J(0.012)
			h = rng.uniform(0.05, 0.16)
			candle(x, yf - 0.085 + J(0.02), z + 0.03, rng.uniform(0.016, 0.024), h, lit=(k + n) % 3 != 0)
		for k in range(3):  # wax runs down the ledge front
			x = -w / 2 + 0.12 + k * (w - 0.24) / 2 + J(0.04)
			tube([(x, yf - dpt + 0.004, z + 0.03), (x, yf - dpt - 0.002, z + 0.0), (x + 0.004, yf - dpt - 0.002, z - 0.05)], 0.008, 0.005, WAX(), seg=5)


def vo_kneeling_stone():
	slab = B((0.85, 0.6, 0.16), (0, 0, 0.08), S("b"), bevel=0.025)
	zt = 0.16
	cuts = []
	for x in (-0.13, 0.13):  # the two knee hollows, worn deep
		# worn hollows show smooth pale stone, not dark carving
		cuts.append(prism(circ(x, 0.07, 0.085, n=16, sz=1.4, wob=0.03), zt - 0.03, zt + 0.03, S("a"), axis="z"))
		cuts.append(prism(circ(x, 0.07, 0.06, n=14, sz=1.4, wob=0.03), zt - 0.037, zt, S("a"), axis="z"))
	for x in (-0.13, 0.13):  # toe scuffs behind the knees
		cuts.append(prism(circ(x, -0.17, 0.045, n=10, sz=0.6, wob=0.05), zt - 0.012, zt + 0.03, S("a"), axis="z"))
	cuts += gtop([(-0.38, -0.25), (0.38, -0.25), (0.38, 0.27), (-0.38, 0.27), (-0.38, -0.25)], 0.014, zt)
	for k in range(9):  # rune marks round the border band
		x = -0.32 + k * 0.08
		cuts += gtop([(x, -0.22), (x, -0.16), (x + 0.025, -0.19)], 0.01, zt, 0.008)
	cuts.append(kit.gem((0.42, -0.29, 0.16), (0.07, 0.06, 0.05), S("a"), seed=4))  # worn chips off two corners
	cuts.append(kit.gem((-0.42, 0.3, 0.14), (0.06, 0.05, 0.05), S("a"), seed=5))
	carve(slab, cuts)
	# the low prayer rail beyond the stone (he knelt facing it and the sealed door)
	ry = 0.42
	for x in (-0.3, 0.3):
		kit.cylinder(0.045, 0.42, (x, ry, 0.21), S("a"), verts=8, bevel=0.008)
		B((0.13, 0.13, 0.04), (x, ry, 0.02), S("c"), bevel=0.01)
	rail = B((0.78, 0.12, 0.07), (0, ry, 0.45), S("a"), bevel=0.012)
	carve(rail, runes(-0.3, 0.3, 0.45, ry - 0.06, h=0.04, gap=0.04, w=0.01, under=False))
	B((0.3, 0.11, 0.02), (0, ry, 0.493), S("c"), bevel=0.006)
	for x in (-0.33, 0.33):  # burnt-down candle stubs on wax pools at the slab corners
		kit.cylinder(0.05, 0.008, (x, 0.2, zt + 0.003), WAX(), verts=12, bevel=0.003)
		candle(x, 0.2, zt + 0.005, 0.022, 0.03, lit=False)
	lathe([(0.05, 0), (0.07, 0.01), (0.075, 0.025), (0.068, 0.027), (0.06, 0.012)], (0, ry, 0.502), CU("b"), seg=14)  # offering dish on the rail


def vo_oath_tablet():
	foot((0.9, 0.4, 0.1), (0, -0.04, 0.05), tone=S("c"), bevel=0.02)
	B((0.78, 0.3, 0.12), (0, -0.01, 0.155), S("a"), bevel=0.015)
	W, H, z0 = 0.66, 1.25, 0.21
	out = [(-W / 2, z0), (W / 2, z0)] + arcpts(0, z0 + H - W / 2, W / 2, 0, PI, 14)
	tab = prism(out, -0.09, 0.09, S("b"))
	yf = -0.09
	inner = [(-W / 2 + 0.05, z0 + 0.05), (W / 2 - 0.05, z0 + 0.05)] + arcpts(0, z0 + H - W / 2, W / 2 - 0.05, 0, PI, 14) + [(-W / 2 + 0.05, z0 + 0.05)]
	cuts = gline(inner, 0.016, yf)
	cuts += eye_sign(0, z0 + H - 0.28, 0.13, yf)
	for k in range(7):
		cuts += runes(-0.23, 0.23, z0 + 0.14 + k * 0.085, yf, h=0.05, gap=0.042, w=0.011, under=(k == 6))
	# the raised oath hand, cut between the eye and the runes
	hx, hz = 0, z0 + H - 0.57
	cuts.append(cy(circ(hx, hz, 0.05, n=12, sz=1.1, wob=0), yf, 0.013))
	for k in range(4):
		cuts.append(cy(bar((hx - 0.033 + k * 0.022, hz + 0.02), (hx - 0.036 + k * 0.024, hz + 0.1 - abs(k - 1.5) * 0.012), 0.016), yf, 0.013))
	cuts.append(cy(bar((hx + 0.04, hz - 0.01), (hx + 0.085, hz + 0.04), 0.016), yf, 0.013))
	cuts.append(cy(bar((hx - 0.02, hz - 0.04), (hx - 0.01, hz - 0.1), 0.05), yf, 0.013))
	carve(tab, cuts)
	for x, z in ((-W / 2 + 0.06, z0 + 0.06), (W / 2 - 0.06, z0 + 0.06), (-0.2, z0 + H - 0.16), (0.2, z0 + H - 0.16)):
		sphere((x, yf - 0.004, z), 0.022, CU("b"), scale=(1, 0.6, 1), seg=10, rings=6)


def vo_prayer_tablets():
	p, yf = panel_wall(1.25, 1.1, 0.18)
	carve(p, eye_sign(0, 1.05, 0.1, yf, w=0.013) + runes(-0.5, -0.2, 1.06, yf, h=0.05, gap=0.045, under=False) + runes(0.2, 0.5, 1.06, yf, h=0.05, gap=0.045, under=False))
	for z in (0.3, 0.68):
		B((1.12, 0.16, 0.06), (0, yf - 0.075, z), S("a"), bevel=0.012)
		for k in range(6):
			x = -0.45 + k * 0.18 + J(0.01)
			w, h = rng.uniform(0.11, 0.14), rng.uniform(0.18, 0.26)
			zb = z + 0.025
			pts = [(x - w / 2, zb), (x + w / 2, zb)] + arcpts(x, zb + h - w / 2, w / 2, 0, PI, 8)
			t = prism(pts, yf - 0.06, yf - 0.025, S("c" if k % 2 else "b"))
			cc = runes(x - w / 2 + 0.02, x + w / 2 - 0.02, zb + h * 0.45, yf - 0.06, h=0.03, gap=0.028, w=0.008, depth=0.006, under=False)
			cc += runes(x - w / 2 + 0.02, x + w / 2 - 0.02, zb + h * 0.25, yf - 0.06, h=0.03, gap=0.028, w=0.008, depth=0.006, under=False)
			cc.append(cy(circ(x, zb + h - w / 2, 0.018, n=8, wob=0), yf - 0.06, 0.008))
			carve(t, cc)
			turn([t], "X", -6, (x, yf - 0.025, zb))


def vo_sealed_passage():
	D, R, CZ = 0.3, 0.78, 0.7
	wall = B((2.3, D, 1.95), (0, 0, 0.975), S("b"), bevel=0.015)
	yf = -D / 2
	ring = [(math.cos(a) * (R + 0.01), CZ + math.sin(a) * (R + 0.01)) for a in [math.radians(-64 + k * 308 / 40) for k in range(41)]]
	carve(wall, [prism(ring, yf - 0.05, yf + 0.12, GROOVE())] + eye_sign(0, 1.72, 0.13, yf) + runes(-1.0, -0.35, 1.72, yf, h=0.06, gap=0.05)
		+ runes(0.35, 1.0, 1.72, yf, h=0.06, gap=0.05))
	n = 13
	for k in range(n):
		a0 = math.radians(-60 + k * 300 / n + 1.2)
		a1 = math.radians(-60 + (k + 1) * 300 / n - 1.2)
		pts = [(math.cos(a) * r, CZ + math.sin(a) * r) for r, a in ((R + 0.02, a0), (R + 0.2 + 0.03 * (k % 2), a0), (R + 0.2 + 0.03 * (k % 2), a1), (R + 0.02, a1))]
		pts = [(x, max(z, 0.0)) for x, z in pts]
		prism(pts, yf + 0.006, yf - 0.04, S("a" if k % 2 else "c"))
	door = kit.cylinder(R - 0.01, 0.1, (0, yf + 0.06, CZ), S("c"), rot=(90, 0, 0), verts=40, bevel=0.0)
	dy = yf + 0.01
	cuts = [B((2, 1, 0.5), (0, 0, -0.25 + 0.004), S("c"), bevel=0)]
	for rr in (0.66, 0.5):
		cuts += gline(arcpts(0, CZ, rr, math.radians(-55), math.radians(235), 24), 0.016, dy)
	cuts += eye_sign(0, CZ + 0.16, 0.14, dy)
	carve(door, cuts)
	# three great locking bars in iron staples set into the voussoirs
	for z in (0.3, CZ, 1.1):
		iron_bar(-1.08, 1.08, -0.2625, z)
		yb = -0.185 if z == CZ else -0.155  # staple backs sit on the voussoir (middle) or the wall face
		for x in (-0.93, 0.93):
			for dz in (-1, 1):
				B((0.15, yb + 0.33, 0.04), (x, (yb - 0.33) / 2, z + dz * 0.067), IRON("dark"), bevel=0.005)  # bites 3 mm into the bar
			B((0.15, 0.03, 0.2), (x, -0.34, z), IRON("dark"), bevel=0.005)
			for dz in (-0.06, 0.06):
				kit.rivet((x, -0.357, z + dz), IRON("a"), r=0.013)
	B((0.24, 0.05, 0.24), (0, -0.345, CZ), IRON("b"), bevel=0.012)  # centre lock box on the middle bar
	kit.ring(0.06, 0.013, (0, -0.37, CZ + 0.14), IRON("a"), rot=(90, 0, 0), seg=14)
	B((0.022, 0.012, 0.05), (0, -0.372, CZ - 0.03), C((0.02, 0.02, 0.02), 1.0), bevel=0.002)
	flat_back(D / 2 - 0.002)


def vo_bar_rack():
	p, yf = panel_wall(1.5, 1.2, 0.2)
	carve(p, eye_sign(0, 1.15, 0.1, yf, w=0.013) + runes(-0.6, -0.2, 1.16, yf, h=0.05, gap=0.045, under=False) + runes(0.2, 0.6, 1.16, yf, h=0.05, gap=0.045, under=False))
	for z in (0.42, 0.8):
		for x in (-0.5, 0.5):
			cb = B((0.13, 0.24, 0.16), (x, yf - 0.115, z), S("a"), bevel=0.012)
			carve(cb, [B((0.2, 0.124, 0.104), (x, yf - 0.13, z + 0.05), S("c"), bevel=0)])  # the notch the bar rests in
			prism([(-0.065, 0), (0.065, 0), (0.0, -0.1)], yf - 0.005, yf - 0.2, S("a")).location = (x, 0, z - 0.075)
		iron_bar(-0.68, 0.68, yf - 0.13, z + 0.0495, h=0.095, d=0.11)
	# iron wedges set on a stone ledge, a ring of keys on a peg
	B((1.0, 0.14, 0.05), (0, yf - 0.065, 0.2), S("a"), bevel=0.012)
	for k in range(5):
		x = -0.42 + k * 0.1
		prism([(-0.035, 0.0), (0.035, 0.0), (0.008, 0.13), (-0.008, 0.13)], yf - 0.09, yf - 0.04, IRON("dark" if k % 2 else "b")).location.z = 0.225
	kit.cylinder(0.02, 0.1, (0.3, yf - 0.05, 0.36), IRON("dark"), rot=(90, 0, 0), verts=8)
	kit.ring(0.07, 0.008, (0.3, yf - 0.09, 0.295), IRON("a"), rot=(90, 0, 0), seg=18)
	for k, a in enumerate((-0.5, -0.1, 0.35)):
		bx, bz = 0.3 + math.sin(a) * 0.07, 0.295 - math.cos(a) * 0.07
		kit.ring(0.022, 0.006, (bx, yf - 0.09, bz - 0.018), IRON("b"), rot=(90, 0, 0), seg=10)
		rod((bx, yf - 0.09, bz - 0.04), (bx + math.sin(a) * 0.1, yf - 0.09, bz - 0.04 - math.cos(a) * 0.1), 0.007, IRON("b"))
		B((0.012, 0.012, 0.03), (bx + math.sin(a) * 0.09 + 0.012, yf - 0.09, bz - 0.04 - math.cos(a) * 0.09), IRON("b"), bevel=0.002, rot=(0, -math.degrees(a), 0))


def vo_jawhelm_stand():
	body, top = plinth(0.5, 0.5, 0.95)
	carve(body, eye_sign(0, 0.68, 0.13, -0.25) + runes(-0.18, 0.18, 0.42, -0.25, h=0.05, gap=0.045) + runes(-0.18, 0.18, 0.3, -0.25, h=0.05, gap=0.045, under=False))
	for sx in (-1, 1):
		for sy in (-1, 1):
			kit.cylinder(0.03, 0.04, (sx * 0.23, sy * 0.23, top + 0.015), CU("dark"), verts=8)
			sphere((sx * 0.23, sy * 0.23, top + 0.05), 0.028, CU("b"), seg=10, rings=6)
	B((0.22, 0.22, 0.05), (0, 0, top + 0.02), S("a"), bevel=0.012)
	kit.cylinder(0.06, 0.16, (0, 0, top + 0.12), S("b"), verts=12)
	sphere((0, 0, top + 0.3), 0.165, S("b"), scale=(0.95, 1.0, 1.05), seg=16, rings=10)
	jaw_helm((0, 0, top + 0.32), s=1.0)
	B((0.2, 0.012, 0.06), (0, -0.256, 0.86), CU("b"), bevel=0.004)  # bronze name plate
	for x in (-0.085, 0.085):
		kit.rivet((x, -0.262, 0.86), CU("dark"), r=0.009)


def mannequin(m, z_hip=0.47, x_arm=0.3, z_neck=0.95, ratio=0.25):
	"""A dwarf-shaped armour form: the game's real dwarf body cut at the hips, at the shoulders (no arms) and the neck."""
	return dwarf_form(("torso",), m, cuts=[((0, 0, z_hip), (0, 0, -1)), ((x_arm, 0, 0), (1, 0, 0)), ((-x_arm, 0, 0), (-1, 0, 0)),
		((0, 0, z_neck), (0, 0, 1))], ratio=ratio)


def pauldron(sd, c, m_list, mr, n=4, r=0.115):
	"""Layered shoulder guard over the top of the shoulder at c (sd = +1 left, -1 right): n curved lames stepping out
	along the arm, each a little smaller and tucked under the one before, riveted."""
	def build():
		for k in range(n):
			rk = r - k * 0.012
			arc_plate(0, 0, rk, rk - 0.004, k * 0.034, k * 0.034 + 0.055, PI - 1.85, PI + 1.85, 0.01, m_list[k % len(m_list)], n=12)
			for q in (-1, 0, 1):
				a = PI + q * 0.9
				kit.rivet((math.cos(a) * (rk - 0.001), math.sin(a) * (rk - 0.001), k * 0.034 + 0.04), mr, r=0.007)
	return group(build, at=c, rot=(0, 90 * sd, 0))


def vo_armour_stand():
	"""His lamellar coat on a dwarf-shaped wooden form (the game's real dwarf, cut at hips and shoulders, dwarf height):
	seven rows of curved iron lames all the way round, layered pauldrons, a gorget, belt and buckle, a skirt of tassets,
	a bronze chest boss, his boots on the stone base."""
	foot((0.8, 0.6, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	B((0.66, 0.48, 0.09), (0, 0, 0.14), S("a"), bevel=0.015)
	form = mannequin(WOOD())
	for o in form:  # round 3 (owner: "too fat"): the form slimmed to a normal dwarf's build
		o.data.transform(Matrix.Translation((0, -0.04, 0)) @ Matrix.Diagonal((0.74, 0.8, 1, 1)) @ Matrix.Translation((0, 0.04, 0)))
	pts = body_pts(form)
	hip = body_ring(pts, 0.49)
	kit.cylinder(0.05, 0.31, (hip[0], hip[1], 0.33), WOOD(), verts=10, bevel=0.006)  # post from the base into the form
	kit.ring(0.055, 0.012, (hip[0], hip[1], 0.2), IRON("dark"), seg=14)
	lames = (IRON("a"), IRON("b"), IRON("dark"))
	for row in range(7):  # the coat: each row hangs over the one below, staggered
		zt = 0.87 - row * 0.045
		lame_row(body_ring(pts, zt), body_ring(pts, zt - 0.06), zt, zt - 0.06, 34, lames, off_t=0.012, off_b=0.028,
			phase=0.5 * (row % 2), rivet_m=CU("dark"))
	zb = 0.555  # belt all round, bronze buckle in front
	ring = body_ring(pts, zb)
	lame_row(ring, body_ring(pts, zb - 0.045), zb, zb - 0.045, 1, (LEA("b"),), off_t=0.05, off_b=0.05, t=0.016, gap=0.0, seg=40)
	fy = ring[1] - ring_r(ring[2], -PI / 2) - 0.05
	B((0.08, 0.02, 0.06), (ring[0], fy - 0.006, zb - 0.0225), CU("b"), bevel=0.005)
	B((0.05, 0.022, 0.035), (ring[0], fy - 0.008, zb - 0.0225), LEA("dark"), bevel=0.003)
	for k in range(10):  # belt studs
		a = -PI / 2 + 0.3 + k * 0.6
		r = ring_r(ring[2], a) + 0.05
		kit.rivet((ring[0] + math.cos(a) * r, ring[1] + math.sin(a) * r, zb - 0.0225), CU("b"), r=0.008)
	lame_row(body_ring(pts, 0.5), hip, 0.52, 0.39, 16, (IRON("a"), IRON("dark")), off_t=0.035, off_b=0.052, t=0.01,
		gap=0.06, seg=4, rivet_m=CU("dark"), rivet_r=0.008)  # tassets hanging below the belt
	for sd in (-1, 1):
		pauldron(sd, (sd * 0.155, hip[1] + 0.02, 0.8), (IRON("b"), IRON("dark")), CU("dark"))
	neck = body_ring(pts, 0.9)
	lathe([(0.135, 0), (0.125, 0.035), (0.095, 0.07), (0.078, 0.08)], (neck[0], neck[1], 0.855), IRON("b"), seg=20)  # gorget
	kit.ring(0.13, 0.01, (neck[0], neck[1], 0.86), CU("b"), seg=24)
	sphere((neck[0], neck[1], 1.0), 0.085, WOOD(), scale=(1, 1.05, 1.15), seg=14, rings=8)  # the form's head knob
	chest = body_ring(pts, 0.72)
	cyf = chest[1] - ring_r(chest[2], -PI / 2) - 0.03
	kit.cylinder(0.065, 0.02, (chest[0], cyf, 0.72), CU("b"), rot=(90, 0, 0), verts=18, bevel=0.005)  # chest boss
	sphere((chest[0], cyf - 0.012, 0.72), 0.028, CU("a"), scale=(1, 0.6, 1), seg=12, rings=6)
	for k in range(8):
		a = 2 * PI * k / 8
		kit.rivet((chest[0] + math.cos(a) * 0.05, cyf - 0.011, 0.72 + math.sin(a) * 0.05), CU("dark"), r=0.007)
	for sd in (-1, 1):  # his boots set together on the base
		bx = sd * 0.12
		B((0.12, 0.22, 0.06), (bx, -0.14, 0.215), LEA("dark"), bevel=0.02)
		kit.cylinder(0.055, 0.16, (bx, -0.07, 0.3), LEA("dark"), verts=10)
		kit.ring(0.058, 0.008, (bx, -0.07, 0.37), CU("b"), seg=12)
		B((0.11, 0.05, 0.03), (bx, -0.24, 0.2), IRON("dark"), bevel=0.008)  # iron toe caps
	slim(small=0.03, fine=0.005, few=0.02)  # under 2 MB


def vo_warning_relief():
	p, yf = panel_wall(1.6, 1.35, 0.18)
	cuts = gline([(-0.74, 0.16), (0.74, 0.16), (0.74, 1.39), (-0.74, 1.39), (-0.74, 0.16)], 0.02, yf)
	# the pit: a jagged opening cut deep, with stairs leading down into it from the left
	pit = [(-0.36, 0.22), (0.36, 0.22), (0.4, 0.42), (0.28, 0.55), (0.12, 0.5), (0.0, 0.6), (-0.15, 0.52), (-0.3, 0.57), (-0.42, 0.4)]
	cuts.append(cy(pit, yf, 0.035))
	for k in range(5):
		x0 = -0.72 + k * 0.07
		z0 = 0.62 - k * 0.07
		cuts.append(cy([(x0, z0), (x0 + 0.075, z0), (x0 + 0.075, z0 - 0.02), (x0, z0 - 0.02)], yf, 0.016))
		cuts.append(cy([(x0 + 0.055, z0 - 0.07), (x0 + 0.075, z0 - 0.07), (x0 + 0.075, z0), (x0 + 0.055, z0)], yf, 0.016))
	for k, (x, a) in enumerate(((-0.24, 100), (-0.08, 85), (0.08, 70), (0.24, 60))):  # long clawed fingers reaching out
		sx, sz = x, 0.52
		pts = [(sx, sz)]
		for j in range(1, 5):
			aa = math.radians(a - j * 9)
			pts.append((pts[-1][0] + math.cos(aa) * 0.1, pts[-1][1] + math.sin(aa) * 0.1))
		for (a0, b0), w in zip(zip(pts, pts[1:]), (0.05, 0.042, 0.034, 0.026)):
			cuts.append(cy(bar(a0, b0, w, w * 0.8), yf, 0.02))
		tx, tz = pts[-1]
		cuts.append(cy([(tx - 0.015, tz), (tx + 0.015, tz), (tx + 0.045, tz - 0.05)], yf, 0.02))
	cuts += eye_sign(0, 1.14, 0.2, yf, w=0.02)
	cuts += hand_cuts(-0.56, 1.1, 1.6, yf)  # 'stop': a warning hand held up
	cuts += runes(-0.6, 0.6, 0.86, yf, h=0.06, gap=0.055)
	cuts += runes(0.3, 0.68, 1.12, yf, h=0.05, gap=0.05, under=False)
	carve(p, cuts)
	for k, (x, z) in enumerate(((-0.2, 0.33), (-0.08, 0.36), (0.12, 0.32), (0.25, 0.37), (0.02, 0.28), (-0.3, 0.29))):  # pale eyes in the dark
		sphere((x, yf + 0.035 - 0.004, z), 0.022, S("a"), scale=(1.3, 0.5, 0.8), seg=8, rings=5)
		sphere((x + 0.006, yf + 0.035 - 0.012, z), 0.008, GROOVE(), scale=(0.6, 0.6, 1.6), seg=6, rings=4)
	frame_band(1.6, 1.35, yf, z0=0.095, t=0.05)


def vo_relief_oath():
	p, yf = panel_wall(1.6, 1.3)
	cuts = gline([(-0.74, 0.16), (0.74, 0.16), (0.74, 1.34), (-0.74, 1.34), (-0.74, 0.16)], 0.02, yf)
	cuts += gline([(-0.7, 0.3), (-0.2, 0.31), (0.3, 0.29), (0.7, 0.31)], 0.016, yf)
	cuts += runes(-0.62, 0.62, 0.23, yf, h=0.06, gap=0.055, under=False)
	cuts += vfig(-0.48, 0.31, 1.15, 1, "staff", yf, helmed=False)
	cuts += vfig(-0.02, 0.31, 1.2, 1, "oath", yf)
	cuts += round_door_cuts(0.46, 0.66, 0.34, yf, w=0.018, bars=3)
	cuts += eye_sign(0.46, 1.17, 0.1, yf, w=0.013)
	for k in range(5):
		x = -0.6 + k * 0.28 + J(0.04)
		cuts.append(cy([(x - 0.04, 1.33), (x + 0.04, 1.33), (x + J(0.01), 1.33 - rng.uniform(0.07, 0.12))], yf, 0.012))
	carve(p, cuts)
	frame_band(1.6, 1.3, yf, z0=0.095, t=0.05)
	for x in (-0.74, 0.74):
		for z in (0.15, 1.34):
			kit.rivet((x, yf - 0.04, z), CU("dark"), r=0.016)


def vo_relief_last_watch():
	p, yf = panel_wall(1.6, 1.3)
	cuts = gline([(-0.74, 0.16), (0.74, 0.16), (0.74, 1.34), (-0.74, 1.34), (-0.74, 0.16)], 0.02, yf)
	cuts += gline([(-0.7, 0.62), (0.05, 0.62)], 0.016, yf)  # the lookout floor
	cuts += gline([(0.05, 0.62), (0.05, 0.3), (0.7, 0.3)], 0.016, yf)  # the drop down to the deep floor
	cuts += vfig(-0.32, 0.63, 1.05, 1, "seated", yf)
	for k, x in enumerate((-0.62, -0.56, 0.0 - 0.06)):  # tall candles with flames
		h = (0.22, 0.16, 0.12)[k]
		cuts.append(cy([(x - 0.018, 0.63), (x + 0.018, 0.63), (x + 0.018, 0.63 + h), (x - 0.018, 0.63 + h)], yf, 0.014))
		cuts.append(cy([(x - 0.02, 0.63 + h + 0.02), (x, 0.63 + h + 0.09), (x + 0.02, 0.63 + h + 0.02), (x, 0.63 + h + 0.01)], yf, 0.014))
	cuts += round_door_cuts(0.42, 0.48, 0.16, yf, w=0.014, bars=3)
	for k in range(6):  # stairs down beside the drop
		cuts.append(cy([(0.06 + k * 0.035, 0.6 - k * 0.05), (0.1 + k * 0.035, 0.6 - k * 0.05), (0.1 + k * 0.035, 0.58 - k * 0.05), (0.06 + k * 0.035, 0.58 - k * 0.05)], yf, 0.012))
	cuts += eye_sign(0.42, 1.1, 0.14, yf, w=0.015)
	cuts += runes(-0.62, 0.0, 0.42, yf, h=0.05, gap=0.05)
	cuts += runes(-0.62, 0.0, 0.3, yf, h=0.05, gap=0.05, under=False)
	for k in range(5):
		x = -0.6 + k * 0.28 + J(0.04)
		cuts.append(cy([(x - 0.04, 1.33), (x + 0.04, 1.33), (x + J(0.01), 1.33 - rng.uniform(0.07, 0.12))], yf, 0.012))
	carve(p, cuts)
	frame_band(1.6, 1.3, yf, z0=0.095, t=0.05)
	for x in (-0.74, 0.74):
		for z in (0.15, 1.34):
			kit.rivet((x, yf - 0.04, z), CU("dark"), r=0.016)


def vo_log_lectern():
	foot((0.6, 0.55, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	B((0.46, 0.42, 0.08), (0, 0, 0.135), S("a"), bevel=0.015)
	col = kit.cylinder(0.13, 0.72, (0, 0, 0.53), S("b"), verts=8, bevel=0.008)
	cuts = []
	for z in (0.3, 0.75):
		for k in range(8):
			a = 2 * PI * k / 8 + PI / 8
			cuts.append(B((0.06, 0.06, 0.02), (math.cos(a) * 0.125, math.sin(a) * 0.125, z), S("c"), bevel=0, rot=(0, 0, math.degrees(a))))
	carve(col, cuts + eye_sign(0, 0.53, 0.07, -0.12, w=0.01, depth=0.01))
	B((0.34, 0.34, 0.07), (0, 0, 0.92), S("a"), bevel=0.015)

	def top():
		t = B((0.62, 0.46, 0.08), (0, 0, 0.04), S("b"), bevel=0.015)
		carve(t, runes(-0.26, 0.26, 0.04, -0.23, h=0.035, gap=0.035, w=0.009, under=False))
		B((0.6, 0.04, 0.05), (0, -0.215, 0.095), S("a"), bevel=0.01)  # book lip
		open_log((0, 0.02, 0.078), w=0.46, d=0.33)
	B((0.3, 0.26, 0.1), (0, 0, 0.95), S("a"), bevel=0.01)  # wedge seat under the sloped top
	group(top, at=(0, 0.0, 0.95), rot=(20, 0, 0))
	B((0.27, 0.16, 0.04), (0.25, 0.0, 0.84), S("a"), bevel=0.01)  # side ledge on a corbel, set into the column
	prism([(0.0, 0.0), (0.0, -0.12), (0.14, 0.0)], -0.06, 0.06, S("b")).location = (0.11, 0.0, 0.825)
	inkpot_quill(0.31, 0.0, 0.858)
	chain((-0.21, -0.125, 1.0), (-0.318, -0.108, 0.953), link=0.018, wire=0.005)


def vo_log_shelf():
	foot((1.35, 0.42, 0.1), (0, -0.07, 0.05), tone=S("c"), bevel=0.02)
	back = B((1.25, 0.08, 1.5), (0, 0.11, 0.85), S("b"), bevel=0.012)
	carve(back, eye_sign(0, 1.5, 0.09, 0.07, w=0.012))
	for x in (-0.6, 0.6):
		B((0.07, 0.36, 1.5), (x, -0.03, 0.85), S("a"), bevel=0.012)
	shelves = (0.12, 0.52, 0.92, 1.32)
	for z in shelves:
		B((1.13, 0.3, 0.05), (0, -0.0, z), S("a"), bevel=0.01)
	B((1.33, 0.4, 0.07), (0, -0.03, 1.63), S("a"), bevel=0.015)
	cols = ("dark", "b", "c", "dark", "a", "b")
	for si, z in enumerate(shelves[:3]):
		zt = z + 0.025
		x = -0.54
		k = 0
		while x < 0.5:
			if si == 0 and k == 0:  # scroll tubes lying on the bottom shelf
				for j in range(3):
					kit.cylinder(0.035, 0.26, (x + 0.15, -0.05 + j * 0.0, zt + 0.035 + j * 0.068), CU("b" if j % 2 else "dark"), rot=(90, 0, 0), verts=10)
					kit.ring(0.037, 0.006, (x + 0.15, -0.17, zt + 0.035 + j * 0.068), CU("dark"), rot=(90, 0, 0), seg=10)
				x += 0.32
				k += 1
				continue
			w = rng.uniform(0.04, 0.07)
			h = rng.uniform(0.24, 0.33)
			if si == 1 and k == 7:  # one leaning against its neighbour
				book_stand(x + 0.07, -0.02, zt, w, 0.22, h, LEA(cols[k % 6]), tilt=16)
				x += 0.13
			else:
				book_stand(x + w / 2, -0.02, zt, w, 0.22, h, LEA(cols[(k + si) % 6]))
				x += w + 0.008
			k += 1
			if si == 2 and k == 6:  # a stone bookend carved with the eye
				be = B((0.07, 0.2, 0.18), (x + 0.04, -0.02, zt + 0.09), S("b"), bevel=0.01)
				carve(be, eye_sign(x + 0.04, zt + 0.1, 0.025, -0.12, w=0.006, depth=0.006))
				x += 0.084
			if si == 2 and k == 8:  # a lying stack fills the gap
				for j in range(3):
					book_flat(x + 0.15, -0.02, zt + j * 0.045, 0.22, 0.26, 0.04, LEA(cols[j]), rotz=J(6))
				break
	# top shelf: a few logs and a stone tablet leaning
	for j in range(4):
		book_flat(-0.32, -0.02, 1.345 + j * 0.05, 0.24, 0.27, 0.045, LEA(cols[j + 1]), rotz=J(6))
	hourglass((0.25, -0.03, 1.345), s=0.65)


def vo_hourglass_stand():
	body, top = plinth(0.42, 0.42, 0.72)
	yf = -0.21
	cuts = eye_sign(0, 0.46, 0.12, yf) + runes(-0.16, 0.16, 0.27, yf, h=0.04, gap=0.04)
	cuts += runes(-0.16, 0.16, 0.18, yf, h=0.04, gap=0.04, under=False)
	carve(body, cuts)
	B((0.4, 0.2, 0.03), (0, 0, top + 0.01), CU("dark"), bevel=0.006)
	for sd in (-1, 1):  # cradle uprights
		B((0.04, 0.06, 0.42), (sd * 0.17, 0, top + 0.22), CU("b"), bevel=0.006)
		kit.cylinder(0.035, 0.03, (sd * 0.17, 0, top + 0.31), CU("dark"), rot=(0, 90, 0), verts=10)
		sphere((sd * 0.17, 0, top + 0.45), 0.03, CU("b"), seg=10, rings=6)
	for sd in (-1, 1):  # pivot pins into the hourglass frame
		rod((sd * 0.155, 0, top + 0.31), (sd * 0.1, 0, top + 0.31), 0.014, IRON("dark"))
	hourglass((0, 0, top + 0.12), s=1.25, frame=WOOD())
	for sd in (-1, 1):
		B((0.03, 0.03, 0.39), (sd * 0.1, 0, top + 0.31), CU("b"), bevel=0.004)
	tube([(0.19, 0, top + 0.31), (0.23, 0, top + 0.31), (0.25, 0.0, top + 0.24)], 0.01, 0.01, IRON("dark"), seg=6)  # turning crank
	kit.cylinder(0.018, 0.05, (0.25, -0.025, top + 0.24), WOOD(), rot=(90, 0, 0), verts=8)


def vo_tally_wall():
	p, yf = panel_wall(1.6, 1.3)
	cuts = gline([(-0.74, 0.16), (0.74, 0.16), (0.74, 1.34), (-0.74, 1.34), (-0.74, 0.16)], 0.018, yf)
	rows = 8
	for r_ in range(rows):
		z = 1.22 - r_ * 0.13
		cuts += runes(-0.7, -0.6, z, yf, h=0.07, gap=0.08, under=False)
		groups = 9 if r_ < rows - 1 else 4
		for g in range(groups):
			x0 = -0.55 + g * 0.14
			n = 4
			for k in range(n):
				x = x0 + k * 0.022 + J(0.003)
				cuts.append(cy(bar((x, z - 0.045), (x + J(0.006), z + 0.045), 0.011), yf, 0.011))
			if not (r_ == rows - 1 and g == groups - 1):
				cuts.append(cy(bar((x0 - 0.012, z - 0.04), (x0 + 0.078, z + 0.04), 0.011), yf, 0.011))
	carve(p, cuts)
	frame_band(1.6, 1.3, yf, z0=0.095, t=0.05)
	B((0.6, 0.14, 0.05), (0.3, yf - 0.06, 0.175), S("a"), bevel=0.01)  # a low ledge with his chisel and mallet
	chisel_mallet(0.32, yf - 0.06, 0.2)


def vo_final_vigil():
	back = B((1.15, 0.3, 1.0), (0, 0.22, 0.5), S("b"), bevel=0.02)
	carve(back, eye_sign(0, 0.86, 0.11, 0.07) + runes(-0.45, -0.18, 0.88, 0.07, h=0.05, gap=0.045) + runes(0.18, 0.45, 0.88, 0.07, h=0.05, gap=0.045))
	B((1.2, 0.34, 0.06), (0, 0.22, 1.02), S("a"), bevel=0.015)
	bench = B((1.05, 0.45, 0.36), (0, -0.12, 0.18), S("b"), bevel=0.02)
	carve(bench, runes(-0.4, 0.4, 0.2, -0.345, h=0.05, gap=0.05, under=False))
	B((1.1, 0.5, 0.04), (0, -0.12, 0.375), S("a"), bevel=0.012)
	zt = 0.395
	bn, bn2 = C((0.4, 0.34, 0.24), 0.9), C((0.36, 0.3, 0.21), 0.9)  # old yellowed bone, not bright white
	sphere((0, -0.02, zt + 0.04), 0.075, bn, scale=(1.4, 0.85, 0.6), seg=12, rings=7)  # pelvis
	spine = [(0, 0.0, zt + 0.07), (0, 0.02, zt + 0.17), (0, 0.035, zt + 0.27), (0, 0.04, zt + 0.37)]
	for a, b in zip(spine, spine[1:]):
		for t in (0.0, 0.5):
			p = Vector(a).lerp(Vector(b), t)
			kit.cylinder(0.026, 0.03, tuple(p), bn, verts=8, bevel=0.004)
	rod(spine[0], spine[-1], 0.012, bn2)
	for k in range(5):  # ribs
		z = zt + 0.17 + k * 0.045
		for sd in (-1, 1):
			tube([(sd * 0.01, 0.03, z), (sd * 0.1, 0.0, z - 0.015), (sd * 0.09, -0.08, z - 0.035), (sd * 0.02, -0.1, z - 0.045)], 0.009, 0.007, bn, seg=5)
	rod((0, -0.1, zt + 0.12), (0, -0.1, zt + 0.35), 0.012, bn2)  # breastbone
	top = Vector(spine[-1])
	for sd in (-1, 1):
		sh = (sd * 0.15, 0.02, zt + 0.35)
		rod(tuple(top), sh, 0.012, bn)
		el = (sd * 0.17, -0.1, zt + 0.12)
		bone(sh, el, 0.017, bn)
		hand = (sd * 0.08, -0.27, zt + 0.07)
		bone((sd * 0.16, -0.115, zt + 0.11), hand, 0.014, bn2)  # joints start 2 cm apart so knobs never overlap
		hip = (sd * 0.07, -0.03, zt + 0.03)
		knee = (sd * 0.1, -0.34, zt + 0.03)
		bone(hip, knee, 0.02, bn)
		ankle = (sd * 0.11, -0.4, 0.04)
		rod((knee[0], knee[1] - 0.01, knee[2] - 0.02), ankle, 0.017, bn2, seg=7)  # shin (straight: a bent log shimmered)
		for s_ in (-1, 1):
			sphere((ankle[0] + s_ * 0.012, ankle[1], ankle[2]), 0.022, bn2, seg=8, rings=5)
		for f in range(3):  # toe bones fanning out from the ankle (start points apart: no shimmer)
			rod((sd * (0.095 + f * 0.015), -0.41, 0.03), (sd * (0.08 + f * 0.03), -0.5, 0.01), 0.008, bn, seg=5)
		for f in range(3):  # finger bones over the horn
			rod(hand, (hand[0] + (f - 1) * 0.015, hand[1] - 0.05, hand[2] + 0.03), 0.006, bn, seg=5)
	group(lambda: skull((0, 0, 0), 0.85, bn, face=(0, -1, 0)), at=(0.02, -0.03, zt + 0.43), rot=(28, 0, 8))
	# the signal horn across his lap
	group(lambda: horn(L=0.6, r0=0.02, r1=0.055), at=(-0.28, -0.29, zt + 0.1), rot=(0, -5, -8))
	kit.cylinder(0.06, 0.008, (0.4, -0.15, zt + 0.003), WAX(), verts=12, bevel=0.003)  # his last candle, burnt out
	candle(0.4, -0.15, zt + 0.006, 0.02, 0.025, lit=False)
	group(lambda: lantern(False), at=(-0.42, -0.08, zt - 0.001), scale=0.85)
	book_flat(0.15, -0.6, 0.0, 0.24, 0.3, 0.05, LEA("dark"), rotz=12)


def horn_stand(broken=False):
	body = B((1.15, 0.38, 0.5), (0, 0, 0.1 + 0.25), S("b"), bevel=0.02)
	foot((1.25, 0.48, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	cuts = runes(-0.48, -0.08, 0.36, -0.19, h=0.06, gap=0.05) + eye_sign(0.24, 0.38, 0.12, -0.19)
	if broken:  # a crack runs down from the broken saddle
		cuts += gline([(0.3, 0.6), (0.26, 0.48), (0.31, 0.38), (0.24, 0.24), (0.28, 0.1)], 0.014, -0.19, 0.02)
		cuts.append(kit.gem((0.42, -0.2, 0.6), (0.14, 0.1, 0.08), S("a"), seed=9))
	carve(body, cuts)
	B((1.2, 0.42, 0.05), (0, 0, 0.58), S("a"), bevel=0.012)
	return 0.605


def vo_horn_fallen():
	top = horn_stand(broken=True)
	L, r0, r1 = 1.1, 0.028, 0.1
	xs = -0.3
	t = (xs + 0.55) / L
	zc = top + 0.17 + 0.16 * t * t
	rr = r0 + (r1 - r0) * t
	cr = B((0.12, 0.26, zc - top), (xs, 0, top + (zc - top) / 2 - 0.004), S("a"), bevel=0.012)
	carve(cr, [prism(circ(0, zc, rr + 0.004, n=18, wob=0), xs - 0.1, xs + 0.1, S("c"), axis="x")])
	B((0.14, 0.28, 0.03), (xs, 0, top + 0.01), S("c"), bevel=0.008)
	B((0.14, 0.28, 0.03), (0.3, 0, top + 0.01), S("c"), bevel=0.008)  # the other saddle's foot, its block gone
	# the broken saddle block on the floor
	o = B((0.12, 0.26, 0.15), (0.0, 0.0, 0.0), S("a"), bevel=0.012, rot=(0, 0, 0))
	carve(o, [prism(circ(0, 0.075 + 0.02, 0.09, n=18, wob=0), -0.1, 0.1, S("c"), axis="x"), kit.gem((0.06, 0.1, 0.07), (0.05, 0.06, 0.07), S("a"), seed=12)])
	turn([o], "Y", 75, (0, 0, 0))
	turn([o], "Z", 30, (0, 0, 0))
	lo = min((o.matrix_world @ v.co).z for v in o.data.vertices)
	shift([o], (0.85, -0.45, -lo))
	# the horn rolled off onto the floor in front of the stand
	hg = group(lambda: horn(), rot=(14, 0, 168))
	lo, _ = bounds(hg)
	shift(hg, (0.55, -0.55, -lo.z))
	rough_chips([(0.62, -0.28, 0.03), (0.75, -0.2, 0.025), (0.4, -0.3, 0.02), (1.0, -0.3, 0.03)])


def vo_bar_snapped():
	foot((1.2, 0.5, 0.1), (0, 0.0, 0.05), tone=S("c"), bevel=0.02)
	wall = B((1.1, 0.3, 1.3), (0, 0.1, 0.095 + 0.65), S("b"), bevel=0.02)
	yf = -0.05
	cuts = [cy(bar((-0.55, z), (0.55, z), 0.014), yf, 0.01) for z in (0.45, 0.85)]
	cuts += [cy(bar((x, z0), (x, z1), 0.014), yf, 0.01) for x, z0, z1 in ((-0.1, 0.1, 0.45), (0.3, 0.45, 0.85), (-0.3, 0.85, 1.4))]
	# torn-out staple socket: a ragged pit with cracks running off it
	cuts.append(cy([(0.0, 0.62), (0.2, 0.6), (0.26, 0.72), (0.22, 0.86), (0.04, 0.88), (-0.03, 0.76)], yf, 0.05))
	cuts += gline([(0.22, 0.86), (0.3, 1.0), (0.27, 1.12), (0.36, 1.3)], 0.012, yf, 0.02)
	cuts += gline([(0.0, 0.62), (-0.12, 0.5), (-0.1, 0.38), (-0.2, 0.22)], 0.012, yf, 0.02)
	cuts += gline([(0.26, 0.7), (0.42, 0.66), (0.52, 0.72)], 0.01, yf, 0.016)
	cuts += runes(-0.48, -0.15, 1.2, yf, h=0.05, gap=0.045)
	carve(wall, cuts)
	B((1.16, 0.36, 0.06), (0, 0.1, 1.42), S("a"), bevel=0.015)
	# the staple hangs by one twisted bolt
	bolt = (0.04, yf + 0.0, 0.84)
	rod((0.04, yf + 0.03, 0.84), (0.05, yf - 0.06, 0.82), 0.014, IRON("dark"))

	def staple():
		for dz in (-1, 1):
			B((0.15, 0.15, 0.04), (0, -0.075, dz * 0.074), IRON("dark"), bevel=0.005)
		B((0.15, 0.03, 0.2), (0, -0.165, 0), IRON("dark"), bevel=0.005)
		kit.rivet((0, -0.182, 0.06), IRON("a"), r=0.013)
	group(staple, at=(0.05, yf - 0.04, 0.72), rot=(0, 25, -10))
	del bolt
	# the snapped bar: two halves on the floor, jagged break ends
	def half(L, sd):
		B((L, 0.11, 0.1), (sd * L / 2, 0, 0.05), IRON("dark"), bevel=0.012)
		B((0.05, 0.134, 0.124), (sd * (L - 0.03), 0, 0.05), IRON("a"), bevel=0.008)
		B((0.035, 0.126, 0.116), (sd * L * 0.5, 0, 0.05), IRON("a"), bevel=0.005)
		kit.rivet((sd * L * 0.5, -0.064, 0.05), IRON("b"), r=0.012)
		prism([(-0.05, 0.0), (-0.02, 0.0), (0.0, 0.03), (-0.025, 0.05), (0.005, 0.075), (-0.02, 0.1), (-0.05, 0.1)], -0.054, 0.054, IRON("b")).scale.x = sd
	h1 = group(lambda: half(0.75, 1), rot=(0, 0, 0))
	shift(h1, (-0.62, -0.5, 0.0))
	h2 = group(lambda: half(0.6, -1), rot=(0, 0, -25))
	shift(h2, (0.6, -0.55, 0.0))
	rough_chips([(0.15, -0.3, 0.03), (0.25, -0.38, 0.025), (-0.05, -0.33, 0.02), (0.32, -0.25, 0.035)])
	for k in range(3):  # sheared rivets
		kit.rivet((0.0 + k * 0.08, -0.62 + J(0.04), 0.008), IRON("b"), r=0.011)


def vo_claw_marks():
	foot((1.5, 0.42, 0.1), (0, -0.03, 0.05), tone=S("c"), bevel=0.02)
	W, H = 1.4, 1.4
	wall = B((W, 0.3, H), (0, 0.06, 0.095 + H / 2), S("b"), bevel=0.02)
	yf = -0.09
	cuts = []
	courses = (0.095, 0.45, 0.8, 1.15, 1.495)
	for i, (z0, z1) in enumerate(zip(courses, courses[1:])):
		cuts.append(cy(bar((-W / 2, z1), (W / 2, z1), 0.016), yf, 0.012))
		for x in ((-0.35, 0.25) if i % 2 else (-0.05, 0.5)):
			cuts.append(cy(bar((x, z0), (x, z1), 0.016), yf, 0.012))
	for k in range(4):  # four deep claw gouges dragged down and across
		x0, z0 = -0.38 + k * 0.13, 1.28 - k * 0.03
		x1, z1 = x0 + 0.36, z0 - 0.82
		mid = ((x0 + x1) / 2 + 0.04, (z0 + z1) / 2)
		cuts.append(cy(bar((x0, z0), mid, 0.012, 0.05), yf, 0.035))
		cuts.append(cy(bar(mid, (x1, z1), 0.05, 0.01), yf, 0.035))
	# the broken corner block (lower right)
	cuts.append(prism([(0.5, 0.095), (0.71, 0.095), (0.71, 0.42), (0.6, 0.45), (0.52, 0.32)], yf - 0.05, yf + 0.2, S("c")))  # broken face: fresh stone
	carve(wall, cuts)
	B((W + 0.06, 0.36, 0.06), (0, 0.06, 0.095 + H + 0.03), S("a"), bevel=0.015)
	o = B((0.22, 0.26, 0.2), (0, 0, 0), S("a"), bevel=0.012)
	carve(o, [kit.gem((0.1, -0.1, 0.1), (0.08, 0.08, 0.1), S("c"), seed=21)])
	turn([o], "Y", 70, (0, 0, 0))
	turn([o], "Z", 25, (0, 0, 0))
	lo = min((o.matrix_world @ v.co).z for v in o.data.vertices)
	shift([o], (0.45, -0.38, -lo))
	rough_chips([(0.15, -0.25, 0.03), (0.0, -0.3, 0.02), (0.32, -0.6, 0.035), (0.7, -0.35, 0.03), (-0.2, -0.22, 0.02)])


def vo_dropped_lantern():
	lg = group(lambda: lantern(False), rot=(0, 90, 30))
	lo, _ = bounds(lg)
	shift(lg, (-0.2, -0.05, -lo.z))
	o = kit.cylinder(0.018, 0.06, (0.1, -0.12, 0.018), WAX(), rot=(0, 90, 20), verts=8)  # candle rolled out
	del o
	# the watch log fallen open face-down
	def log_down():
		for sd in (-1, 1):
			B((0.2, 0.28, 0.008), (sd * 0.1, 0, 0.004), LEA("dark"), bevel=0.002, rot=(0, sd * -8, 0))
			B((0.18, 0.26, 0.02), (sd * 0.1, 0, 0.016), PAPER(), bevel=0.003, rot=(0, sd * -8, 0))
		B((0.02, 0.28, 0.03), (0, 0, 0.022), LEA("dark"), bevel=0.005)
	g = group(log_down, rot=(180, 0, 25))
	lo, _ = bounds(g)
	shift(g, (0.35, -0.3, -lo.z))
	rod((0.05, -0.45, 0.004), (0.24, -0.52, 0.004), 0.003, C((0.7, 0.65, 0.55), 0.8), seg=4)  # quill
	prism([(0.0, -0.004), (0.12, -0.014), (0.16, 0.0), (0.12, 0.012)], 0.002, 0.006, C((0.62, 0.58, 0.5), 0.9), axis="z").location = (0.1, -0.48, 0)
	kit.cylinder(0.11, 0.004, (-0.08, -0.45, 0.002), INK(), verts=14, bevel=0)  # spilled ink
	lp = group(lambda: lathe([(0.03, 0), (0.036, 0.01), (0.033, 0.045), (0.016, 0.055), (0.017, 0.066), (0.012, 0.067), (0.01, 0.02)], (0, 0, 0), CU("b"), seg=12),
		rot=(0, 90, -40))
	lo, _ = bounds(lp)
	shift(lp, (-0.14, -0.42, -lo.z))

	def stool():  # his little three-legged stool, knocked over
		kit.cylinder(0.17, 0.05, (0, 0, 0.36), WOOD(), verts=14, bevel=0.01)
		for k in range(3):
			a = 2 * PI * k / 3
			log((math.cos(a) * 0.1, math.sin(a) * 0.1, 0.34), (math.cos(a) * 0.16, math.sin(a) * 0.16, 0.0), 0.022, WOOD(), seg=7, rings=1, ends=False, bend=0)
		kit.ring(0.115, 0.01, (0, 0, 0.15), IRON("a"), seg=16)
	sg = group(stool, rot=(0, 98, 0))
	lo, _ = bounds(sg)
	shift(sg, (0.62, 0.15, -lo.z))


def vo_oil_niche():
	yf, nz, nd, body = niche_block(w=1.05, h=1.35, d=0.44, nw=0.74, nh=0.82, nz=0.32, nd=0.3)
	zf = nz
	for k, x in enumerate((-0.24, -0.06, 0.13)):  # clay oil jars on the niche floor
		h = (0.26, 0.3, 0.24)[k]
		lathe([(0.05, 0), (0.08, 0.04), (0.085, h * 0.55), (0.06, h * 0.85), (0.035, h * 0.9), (0.04, h), (0.03, h), (0.026, h * 0.8)], (x, yf + 0.17, zf - 0.004), CLAY(), seg=14)
		kit.ring(0.083, 0.007, (x, yf + 0.17, zf - 0.004 + h * 0.55), CU("dark"), seg=14)
		kit.cylinder(0.03, 0.02, (x, yf + 0.17, zf + h + 0.006), WOOD(), verts=8)
	for x in (0.27,):
		lathe([(0.035, 0), (0.045, 0.02), (0.045, 0.1), (0.015, 0.14), (0.016, 0.17), (0.01, 0.17), (0.008, 0.13)], (x, yf + 0.13, zf - 0.004), CU("b"), seg=12)
		kit.ring(0.02, 0.005, (x + 0.045, yf + 0.13, zf + 0.08), CU("dark"), rot=(90, 0, 0), seg=8)
	lathe([(0.008, 0), (0.01, 0.0), (0.06, 0.07), (0.055, 0.075), (0.006, 0.01)], (0.24, yf + 0.06, zf - 0.004 + 0.0), CU("dark"), seg=12)  # funnel
	# a hanging ladle from an iron hook driven into the niche crown
	top = nz + 0.82 - 0.06
	rod((0.0, yf + 0.18, top + 0.05), (0.0, yf + 0.18, top - 0.04), 0.008, IRON("dark"))
	tube([(0.0, yf + 0.18, top - 0.04), (0.0, yf + 0.15, top - 0.07), (0.0, yf + 0.12, top - 0.04)], 0.007, 0.006, IRON("dark"), seg=5)
	rod((0.0, yf + 0.12, top - 0.045), (0.04, yf + 0.12, top - 0.3), 0.007, IRON("a"))
	lathe([(0.0, 0), (0.035, 0.012), (0.045, 0.04), (0.04, 0.042), (0.03, 0.016)], (0.0, yf + 0.12, top - 0.34), IRON("a"), seg=12)
	B((0.6, 0.04, 0.04), (0, yf - 0.02, 0.22), CU("b"), bevel=0.004)  # bronze plate under the sill
	for x in (-0.26, 0.26):
		kit.rivet((x, yf - 0.042, 0.22), CU("dark"), r=0.01)


def vo_candle_rack():
	p, yf = panel_wall(1.2, 1.15, 0.18)
	carve(p, eye_sign(0, 1.08, 0.09, yf, w=0.012) + runes(-0.45, -0.18, 1.08, yf, h=0.045, gap=0.04, under=False) + runes(0.18, 0.45, 1.08, yf, h=0.045, gap=0.04, under=False))
	B((1.08, 0.06, 0.08), (0, yf - 0.025, 0.92), S("a"), bevel=0.012)  # peg rail
	for k in range(5):
		x = -0.4 + k * 0.2
		py = yf - 0.055
		rod((x, yf - 0.04, 0.9), (x, yf - 0.16, 0.92), 0.012, IRON("dark"))
		sphere((x, yf - 0.165, 0.922), 0.017, IRON("a"), seg=8, rings=5)
		n = 2 + (k % 2)
		for j in range(n):  # candles hanging by their wicks in pairs over the peg
			off = (j - (n - 1) / 2) * 0.045
			cx, ctop = x + off, 0.78 - (j % 2) * 0.03
			h = 0.18 + (j % 2) * 0.03
			rod((x, yf - 0.12, 0.915), (cx, yf - 0.12, ctop + 0.004), 0.003, C((0.2, 0.17, 0.12), 0.9), seg=4)
			kit.cylinder(0.014, h, (cx, yf - 0.12, ctop - h / 2), WAX(), verts=8, bevel=0.004)
		del py
	B((1.0, 0.18, 0.05), (0, yf - 0.085, 0.3), S("a"), bevel=0.012)  # ledge
	mz = 0.325
	B((0.3, 0.1, 0.12), (-0.25, yf - 0.09, mz + 0.06), CU("dark"), bevel=0.008)  # candle mould
	for k in range(6):
		kit.cylinder(0.015, 0.012, (-0.375 + k * 0.05, yf - 0.09, mz + 0.123), INK(), verts=8, bevel=0)
	lathe([(0.06, 0), (0.08, 0.02), (0.085, 0.09), (0.09, 0.1), (0.083, 0.1), (0.075, 0.025)], (0.15, yf - 0.09, mz - 0.003), IRON("dark"), seg=14)  # wax pot
	kit.cylinder(0.077, 0.01, (0.15, yf - 0.09, mz + 0.08), WAX(), verts=14, bevel=0)
	rod((0.15, yf - 0.09, mz + 0.06), (0.25, yf - 0.12, mz + 0.18), 0.008, WOOD())
	for k in range(4):  # a few finished candles laid in a row
		kit.cylinder(0.014, 0.2, (0.36, yf - 0.04 - k * 0.032, mz + 0.012), WAX(), rot=(0, 90, 0), verts=8)


def vo_wall_brazier():
	foot((0.8, 0.35, 0.1), (0, -0.03, 0.05), tone=S("c"), bevel=0.02)
	st = B((0.68, 0.2, 1.6), (0, 0.04, 0.095 + 0.8), S("b"), bevel=0.02)
	yf = -0.06
	carve(st, eye_sign(0, 1.42, 0.12, yf) + runes(-0.22, 0.22, 0.42, yf, h=0.05, gap=0.045) + runes(-0.22, 0.22, 0.3, yf, h=0.05, gap=0.045, under=False)
		+ gline([(-0.28, 0.2), (0.28, 0.2), (0.28, 1.6), (-0.28, 1.6), (-0.28, 0.2)], 0.014, yf))
	B((0.74, 0.24, 0.06), (0, 0.04, 1.72), S("a"), bevel=0.015)
	cz = 0.86
	for k, (w_, d_) in enumerate(((0.36, 0.42), (0.32, 0.31), (0.28, 0.21), (0.24, 0.11))):  # stepped corbel
		cb = B((w_, d_, 0.08), (0, yf + 0.005 - d_ / 2, cz - 0.04 - k * 0.075), S("a" if k % 2 == 0 else "b"), bevel=0.012)
		if k == 0:
			carve(cb, runes(-0.13, 0.13, cz - 0.04, yf + 0.005 - d_, h=0.035, gap=0.035, w=0.009, under=False))
	bz = cz - 0.005
	lathe([(0.05, 0), (0.14, 0.02), (0.2, 0.08), (0.22, 0.14), (0.205, 0.145), (0.185, 0.085), (0.12, 0.03)], (0, yf - 0.2, bz), IRON("dark"), seg=16)
	for k in range(10):
		a = 2 * PI * k / 10
		tube([(math.cos(a) * 0.215, yf - 0.2 + math.sin(a) * 0.215, bz + 0.12), (math.cos(a) * 0.225, yf - 0.2 + math.sin(a) * 0.225, bz + 0.22)], 0.008, 0.007, IRON("dark"), seg=5)
	kit.ring(0.225, 0.009, (0, yf - 0.2, bz + 0.22), IRON("a"), seg=20)
	kit.ring(0.21, 0.01, (0, yf - 0.2, bz + 0.135), IRON("a"), seg=20)
	tube([(0.0, yf + 0.0, bz + 0.45), (0.0, yf - 0.1, bz + 0.38), (0.0, yf - 0.2, bz + 0.25)], 0.012, 0.01, IRON("dark"), seg=6)  # strap to the wall
	B((0.08, 0.03, 0.1), (0, yf + 0.0, bz + 0.45), IRON("dark"), bevel=0.005)
	kit.rivet((0, yf - 0.016, bz + 0.47), IRON("a"), r=0.012)
	coal_heap(0, yf - 0.2, bz + 0.1, 0.16, 26, hot=8, seed=11)
	kit.fire_spot((0, yf - 0.2, bz + 0.2), 0.3)


def vo_axe_rest():
	foot((0.62, 0.56, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	blk = B((0.48, 0.42, 0.36), (0, 0, 0.27), S("b"), bevel=0.02)
	carve(blk, [czt(circ(0, 0, 0.05, n=12, wob=0), 0.45, 0.1)] + eye_sign(0, 0.29, 0.08, -0.21, w=0.011) + runes(-0.18, 0.18, 0.16, -0.21, h=0.04, gap=0.04, under=False))
	B((0.52, 0.46, 0.04), (0, 0, 0.465), S("a"), bevel=0.012)
	kit.ring(0.06, 0.016, (0, 0, 0.49), CU("b"), seg=16)  # bronze socket collar
	for k in range(6):
		a = 2 * PI * k / 6
		kit.rivet((math.cos(a) * 0.07, math.sin(a) * 0.07, 0.49), CU("dark"), r=0.009)
	log((0, 0, 0.36), (0, 0, 1.45), 0.03, WOOD(), seg=8, rings=3, bend=0.0, ends=False)  # haft
	for k in range(6):
		kit.ring(0.031, 0.007, (0, 0, 0.6 + k * 0.035), LEA("dark"), seg=10)
	hz = 1.32
	for sd in (-1, 1):  # double-bitted head, a brighter ground edge on each bit
		prism([(sd * x, hz + z) for x, z in ((0.0, -0.06), (0.1, -0.08), (0.19, -0.15), (0.225, -0.02), (0.225, 0.02), (0.19, 0.15), (0.1, 0.08), (0.0, 0.06))], -0.02, 0.02, IRON("a"))
		prism([(sd * x, hz + z) for x, z in ((0.2, -0.155), (0.248, -0.03), (0.248, 0.03), (0.2, 0.155), (0.225, 0.0))], -0.026, 0.026, IRON("b"))
	B((0.08, 0.07, 0.16), (0, 0, hz), IRON("dark"), bevel=0.01)
	for z in (hz - 0.06, hz + 0.06):
		kit.rivet((0, -0.036, z), CU("dark"), r=0.01)
	kit.cone(0.025, 0.004, 0.08, (0, 0, 1.49), IRON("dark"), verts=6)
	B((0.2, 0.06, 0.04), (0.12, -0.15, 0.505), S("c"), bevel=0.01)  # whetstone
	lathe([(0.03, 0), (0.04, 0.02), (0.04, 0.07), (0.014, 0.1), (0.015, 0.12), (0.009, 0.12), (0.007, 0.09)], (-0.15, -0.12, 0.485), CU("b"), seg=12)  # oil flask
	kit.cylinder(0.012, 0.02, (-0.15, -0.12, 0.615), WOOD(), verts=8)


def vo_orrin_bust():
	"""A stone bust of Orrin: the game's real dwarf head (beard, braids, beard rings) and chest carved in greystone, in his
	ribbed jaw-guard helm, gorget and layered pauldrons, on a plinth with his name runes and eye sign cut in."""
	body, top = plinth(0.62, 0.52, 0.76)
	carve(body, runes(-0.2, 0.2, 0.52, -0.26, h=0.06, gap=0.05) + runes(-0.2, 0.2, 0.4, -0.26, h=0.05, gap=0.045, under=False) + eye_sign(0, 0.24, 0.09, -0.26))
	m, ma, mc = S("b"), S("a"), S("c")
	z_cut = 0.55
	z_mouth = 0.99
	lift = top - z_cut - 0.006  # the carved chest sits 6 mm down into the plinth top

	def head():
		# round 3 (owner: "face is not seen, I see only beard"): beard pulled in shorter, narrower and flatter below the
		# mouth, dark carved eyes, helm raised above the brow, the head tipped up a little
		hd = dwarf_form(("head_hair",), m, cuts=[((0, 0, z_cut), (0, 0, -1))], src="armor_hide.glb", ratio=0.33)
		hd += dwarf_form(("rings",), ma, cuts=[((0, 0, z_cut), (0, 0, -1))], ratio=0.3)  # beard rings move with the beard
		for o in hd:
			for v in o.data.vertices:
				x, y, z = v.co
				t = min(1.0, max(0.0, (z_mouth - z) / 0.07)) * min(1.0, max(0.0, -y / 0.1))
				if t > 0:
					v.co = (x * (1 - 0.25 * t), -0.06 + (y + 0.06) * (1 - 0.4 * t) if y < -0.06 else y, z_mouth - (z_mouth - z) * (1 - 0.42 * t))
		for sd in (-1, 1):  # the game's eyes sit deep under his bushy brows: carved dark eyes set out at the brow line
			sphere((sd * 0.05, -0.1, 1.074), 0.02, GROOVE(), scale=(1.3, 0.6, 0.8), seg=10, rings=6)
		jaw_helm((0, 0.09, 1.15), s=1.02, mi=ma, mt=m, mr=mc, ml=(ma, mc), jaw=False, open_face=True)

	def bust():
		turn(group(head), "X", -12, (0, 0, 0.92))
		dwarf_form(("torso", "shirt"), m, cuts=[((0, 0, z_cut), (0, 0, -1)), ((0.31, 0, 0), (1, 0, 0)), ((-0.31, 0, 0), (-1, 0, 0))],
			ratio=0.3)
		for sd in (-1, 1):
			pauldron(sd, (sd * 0.2, 0.0, 0.79), (ma, mc), m, n=4, r=0.12)
		lathe([(0.19, 0), (0.17, 0.035), (0.13, 0.065), (0.11, 0.072)], (0, 0.03, 0.8), ma, seg=22)  # gorget under the beard
	group(bust, at=(0, 0, lift))


MODELS = {k: v for k, v in globals().items() if k.startswith("vo_") and callable(v)}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
