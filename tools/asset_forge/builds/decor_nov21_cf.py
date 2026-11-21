# Decor set CF (Nov 21): CINDERHOLD FOUNDRY, a big clay-brick dungeon where dwarves melted metal and cast bells,
# ingots and pots. Hearthbrick look: brick / brickochre / clay, copper, iron, glow only where metal is hot.
#   blender --background --factory-startup --python builds/decor_nov21_cf.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on the floor (they never float when placed in the open).
#
# The 30 models (W = wall piece, S = story scene):
#   cf_tongs_wall          W  board of seven foundry tongs (ring, flat, hook and pick jaws) hung on iron hooks
#   cf_ladle_rack          W  five pouring ladles with crusted bowls on hooks, a row of clay pouring cups below
#   cf_pattern_shelf       W  shelves of pale wooden patterns: bells, pot, candlestick, gear, ingots, hinge straps
#   cf_crucible_shelf      W  three shelves of clay crucibles in graded sizes, some upside down, some lidded
#   cf_skimmer_rack        W  long foundry tools standing in a rack: skimmers, slag rakes, pokers, stirring rods
#   cf_mould_board         W  iron moulds hung by ring handles: ingot bars, buttons, spoon, coins, arrowheads
#   cf_master_mark_stone   W  the foundry master's mark carved into a stone set in brick piers, with a pour tally
#   cf_strickle_board      W  bell strickle (profile template on its spindle), calipers and a notched measuring rod
#   cf_casting_shelf       W  finished castings: little bells, iron pots, gears, door knockers, candlesticks
#   cf_flux_shelf          W  lidded flux jars with copper tags, an open crock of flux lumps, a small balance scale
#   cf_crucible_furnace       round brick crucible furnace, iron hoops, a crucible of molten metal in glowing coals
#   cf_crucible_stand         an iron tripod on a brick block holding a crucible of molten metal, tongs leaning on it
#   cf_crucible_shank         a two-dwarf carrying shank with a cooled crucible, resting across two brick blocks
#   cf_flask_stack            three sand casting flasks stacked and clamped, sprue and riser holes in the sand
#   cf_mould_box_open      S  a mould opened: hammer-head cavity in the drag, cope turned over, pattern lifted out
#   cf_ingot_mould_row        long iron ingot mould on bricks: cooled ingots, one just poured and glowing, one tipped out
#   cf_ingot_stack            bronze ingots stacked crosswise on a wooden pallet
#   cf_bell_pit            S  a half-dug bell in its brick pit: crown out of the sand, the loam mould broken around it
#   cf_bell_cracked        S  a failed bell on its side on chocks: a long crack, a chunk out of the lip, a sledge
#   cf_slag_cart              two-wheeled iron-bound slag cart full of dark glassy slag
#   cf_slag_cart_tipped    S  the slag cart tipped forward, loose slag rocks spilled across the floor
#   cf_flux_tub               iron-hooped stave tub of pale flux stone with a wooden scoop
#   cf_cooling_rack           iron rack of fresh castings cooling on grates, the newest pot still glowing
#   cf_crucible_dropped    S  a cracked crucible dropped on a brick floor, its cold metal slug slid out, tongs beside
#   cf_sand_bin               three-sided brick bin of moulding sand with a shovel, a riddle sieve and a rammer
#   cf_moulders_bench         a moulder's bench: half-rammed flask, rammers, trowels, slicks, a sprue pin
#   cf_quench_trough          dry brick quench trough, a cast pot hanging from a pole across it, tongs on the rim
#   cf_scrap_crate            crate of scrap for remelting: bell shards, bent copper sheet, broken gears, rods
#   cf_charcoal_bay           low brick bay of black glossy charcoal, a scoop shovel in it and a full iron scuttle
#   cf_charcoal_bay_empty     the same bay looted: crumbs on the floor, shovel on the back wall, scuttle empty
#   cf_ingot_stack_empty      the ingot pallet looted: bare pallet and its tag
# LOOT (owner round 2, Nov 22; the looting code comes later): cf_charcoal_bay gives 5 coal -> cf_charcoal_bay_empty;
#   cf_ingot_stack gives 3 bronze ingots -> cf_ingot_stack_empty.
# Round 2 fixes (owner notes): bells rebuilt round with bands, cut runes and a crown (bell_big);
#   no water / puddles (quench trough dry, crucible slug instead of a spill, slag
#   and coal piles are loose lumps only); moulding sand painted yellow and grainy.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rivet, rng  # noqa: E402
from night_materials import C, lump, _cm  # noqa: E402
from night_decor import legs4, plank_top  # noqa: E402

def P(rgb, rough=0.6, glow=0.0, metal=0.0):
	"""A plain paint given in display colour (plain colours are linear, so they rendered far too pale)."""
	return C(tuple(c ** 2.2 for c in rgb), rough, glow, metal)


WOOD = lambda: T("wood")  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
MORTAR = lambda: P((0.17, 0.13, 0.1), 0.95)  # noqa: E731  dark joints
MOLTEN = lambda: P((1.0, 0.36, 0.04), 0.35, glow=3.0)  # noqa: E731
HOT = lambda: P((1.0, 0.66, 0.18), 0.3, glow=3.5)  # noqa: E731
CRUST = lambda: kit.mat("charcoal", 0.15)  # noqa: E731
SAND = lambda: P((0.2, 0.14, 0.09), 1.0)  # noqa: E731  dark moulding sand
SLAGS = lambda: (P((0.05, 0.045, 0.045), 0.22), P((0.11, 0.075, 0.05), 0.3), P((0.08, 0.06, 0.07), 0.2), P((0.2, 0.09, 0.04), 0.5))  # noqa: E731
COAL = lambda: P((0.03, 0.03, 0.035), 0.25)  # noqa: E731
GROOVE_M = lambda: P((0.06, 0.05, 0.045), 0.95)  # noqa: E731
BRONZE = lambda: P((0.55, 0.36, 0.18), 0.4, metal=0.6)  # noqa: E731
BRONZE_D = lambda: P((0.4, 0.26, 0.14), 0.5, metal=0.5)  # noqa: E731
LOAM = lambda: P((0.42, 0.3, 0.2), 0.95)  # noqa: E731


def CLAY(v="a"):
	"""Fired crucible clay, buff to scorched (plain paint: the clay texture reads as wood grain on round pots)."""
	return P({"a": (0.42, 0.35, 0.28), "b": (0.36, 0.3, 0.25), "c": (0.47, 0.4, 0.32), "dark": (0.22, 0.2, 0.19)}[v], 0.85)


def BRICK():
	return T("brickochre") if rng.random() < 0.12 else T("brick")


# ================= helpers (small ones copied from decor_nov21_a / _f so this file stands alone) =================
def objs():
	return set(bpy.data.objects)


def since(before):
	return [o for o in bpy.data.objects if o not in before]


def turn(group_, axis, deg, pivot):
	p = Vector(pivot)
	M = Matrix.Translation(p) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-p)
	for o in group_:
		o.matrix_world = M @ o.matrix_world


def group(build, at=(0, 0, 0), rot=(0, 0, 0)):
	"""Build parts around the origin, then turn them by rot (degrees, XYZ) and move them to `at`. Returns the parts."""
	before = objs()
	build()
	bpy.context.view_layer.update()
	M = Matrix.Translation(Vector(at)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
	new = since(before)
	for o in new:
		o.matrix_world = M @ o.matrix_world
	return new


def low_z(parts):
	bpy.context.view_layer.update()
	return min((o.matrix_world @ v.co).z for o in parts if o.type == "MESH" for v in o.data.vertices)


def settle(parts, z=0.0):
	"""Move a group so its lowest point sits at z."""
	d = z - low_z(parts)
	for o in parts:
		o.location.z += d


def rod(p0, p1, r, m, seg=7):
	return log(p0, p1, r, m, seg=seg, rings=1, ends=False, bend=0)


def prism(pts, a0, a1, m, axis="y"):
	"""A flat shape (2D outline) given thickness: axis y = outline in (x, z) from y=a0 to a1; axis z = (x, y) outline."""
	n = len(pts)
	if axis == "y":
		v = [(x, a0, z) for x, z in pts] + [(x, a1, z) for x, z in pts]
	elif axis == "x":
		v = [(a0, y, z) for y, z in pts] + [(a1, y, z) for y, z in pts]
	else:
		v = [(x, y, a0) for x, y in pts] + [(x, y, a1) for x, y in pts]
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def strip(pts, w, ya, yb, m):
	"""A flat iron bar bent along points in (x, z), one clean piece (no overlapping joints), from y=ya to yb."""
	n = len(pts)
	ws = w if isinstance(w, (list, tuple)) else [w] * n
	v = []
	for i in range(n):
		a, b = Vector(pts[max(i - 1, 0)]), Vector(pts[min(i + 1, n - 1)])
		d = (b - a).normalized()
		nr = Vector((-d.y, d.x)) * ws[i] / 2
		p = Vector(pts[i])
		for q, y in ((p + nr, ya), (p - nr, ya), (p - nr, yb), (p + nr, yb)):
			v.append((q.x, y, q.y))
	f = []
	for i in range(n - 1):
		a, b = 4 * i, 4 * (i + 1)
		f += [(a + k, a + (k + 1) % 4, b + (k + 1) % 4, b + k) for k in range(4)]
	f += [(0, 1, 2, 3), (4 * n - 1, 4 * n - 2, 4 * n - 3, 4 * n - 4)]
	return mesh(v, f, m)


def lathe(prof, loc, m, seg=18):
	"""A turned shape: profile [(r, z), ...] spun around the z axis at loc = (x, y). r = 0 rows close the ends."""
	x0, y0 = loc
	v, rows = [], []
	for r, z in prof:
		if r == 0:
			rows.append([len(v)])
			v.append((x0, y0, z))
		else:
			rows.append(list(range(len(v), len(v) + seg)))
			v += [(x0 + math.cos(2 * math.pi * k / seg) * r, y0 + math.sin(2 * math.pi * k / seg) * r, z) for k in range(seg)]
	f = []
	for a, b in zip(rows, rows[1:]):
		for k in range(seg):
			if len(a) == 1:
				f.append((a[0], b[(k + 1) % seg], b[k]))
			elif len(b) == 1:
				f.append((a[k], a[(k + 1) % seg], b[0]))
			else:
				f.append((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
	return mesh(v, f, m)


def carve(target, cutters):
	"""Cut each cutter INTO the target one at a time (boolean difference, cut walls take the cutter's dark colour)."""
	bpy.context.view_layer.objects.active = target
	for md in list(target.modifiers):
		bpy.ops.object.modifier_apply(modifier=md.name)
	for c in cutters:
		bpy.context.view_layer.objects.active = c
		for md in list(c.modifiers):
			bpy.ops.object.modifier_apply(modifier=md.name)
		md = target.modifiers.new("carve", "BOOLEAN")
		md.operation, md.object, md.solver = "DIFFERENCE", c, "EXACT"
		md.material_mode = "TRANSFER"
		c.hide_set(True)
		bpy.context.view_layer.objects.active = target
		bpy.ops.object.modifier_apply(modifier=md.name)
		bpy.data.objects.remove(c, do_unlink=True)
	return target


def groove(p0, p1, y, w=0.014, depth=0.012):
	"""Cutter for one carved stroke on a front face (front = -Y at y), from 3 cm in front of it to `depth` deep."""
	(x0, z0), (x1, z1) = p0, p1
	ang = math.degrees(math.atan2(z1 - z0, x1 - x0))
	return [B((math.hypot(x1 - x0, z1 - z0) + w * 0.9, depth + 0.03, w), ((x0 + x1) / 2, y + (depth - 0.03) / 2, (z0 + z1) / 2),
		GROOVE_M(), bevel=0, rot=(0, -ang, 0))]


def groove_path(pts, y, w=0.014, depth=0.012, closed=False):
	out = []
	for a, b in zip(pts, pts[1:] + (pts[:1] if closed else [])):
		out += groove(a, b, y, w, depth)
	return out


def hole(x, z, y, r, depth=0.015, n=12):
	"""Cutter for a round pit in a front face."""
	return [kit.cylinder(r, depth + 0.03, (x, y + (depth - 0.03) / 2, z), GROOVE_M(), rot=(90, 0, 0), verts=n, bevel=0)]


def rune_row(x0, x1, z, y, h=0.07, w=0.012, depth=0.012, seed=1):
	import random
	r = random.Random(seed)
	out = []
	n = max(2, int((x1 - x0) / (h * 0.62)))
	for i in range(n):
		x = x0 + (x1 - x0) * (i + 0.5) / n
		lo, hi = z - h / 2, z + h / 2
		out += groove((x, lo), (x, hi), y, w, depth)
		k, s_ = r.randrange(4), r.choice((-1, 1))
		if k == 0:
			out += groove((x, hi - h * 0.15), (x + s_ * h * 0.3, hi - h * 0.45), y, w * 0.9, depth)
		elif k == 1:
			out += groove((x - h * 0.25, z + h * 0.2), (x + h * 0.25, z - h * 0.2), y, w * 0.9, depth)
		elif k == 2:
			out += groove((x, hi), (x + s_ * h * 0.28, hi - h * 0.25), y, w * 0.9, depth)
			out += groove((x, z), (x + s_ * h * 0.28, z - h * 0.25), y, w * 0.9, depth)
		else:
			out += groove((x - h * 0.22, hi - h * 0.1), (x + h * 0.22, hi - h * 0.1), y, w * 0.9, depth)
	return out


def floor_cut():
	"""Flatten anything that dips below the floor so the whole model stands on z = 0."""
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		mw = o.matrix_world.copy()
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.z < 0:
				w.z = 0.0
				v.co = inv @ w


def spin(o, rx, ry, rz):
	o.data.transform(Matrix.Rotation(math.radians(rz), 4, "Z") @ Matrix.Rotation(math.radians(ry), 4, "Y") @ Matrix.Rotation(math.radians(rx), 4, "X"))
	return o


def heap(cx, cy, rx, ry, H, tones, n=60, smax=0.12, smin=0.03, fill=None, seed=1):
	"""A settled heap: a fill mound (open underneath) with many angular pieces of different sizes half sunk into it,
	big ones low, small ones high. Returns the height function h(x, y)."""
	import random
	r = random.Random(seed)

	def h(x, y):
		d = math.hypot((x - cx) / rx, (y - cy) / ry)
		return H * max(0.0, 1 - d) ** 0.85

	rings, segs = 8, 18
	v = [(cx, cy, H * 0.92)]
	for i in range(1, rings + 1):
		t = i / rings * 1.03
		for k in range(segs):
			a = 2 * math.pi * k / segs
			x, y = cx + math.cos(a) * rx * t, cy + math.sin(a) * ry * t
			v.append((x, y, max(0.0, h(x, y) * 0.9 + (r.uniform(-0.01, 0.01) if i < rings else 0))))
	f = [(0, 1 + k, 1 + (k + 1) % segs) for k in range(segs)]
	for i in range(rings - 1):
		a0, a1 = 1 + i * segs, 1 + (i + 1) * segs
		f += [(a0 + k, a1 + k, a1 + (k + 1) % segs, a0 + (k + 1) % segs) for k in range(segs)]
	mesh(v, f, fill or tones[0])
	for i in range(n):
		s = smin + (smax - smin) * (1 - i / n) ** 1.1 * r.uniform(0.7, 1.0)
		for _ in range(20):
			a, d = r.uniform(0, 2 * math.pi), math.sqrt(r.uniform(0, 1))
			x, y = cx + math.cos(a) * rx * d, cy + math.sin(a) * ry * d
			if h(x, y) > 0.015:
				break
		o = kit.gem((0, 0, 0), (s * r.uniform(0.8, 1.2), s * r.uniform(0.7, 1.05), s * r.uniform(0.45, 0.75)), tones[i % len(tones)], seed=seed * 100 + i)
		spin(o, r.uniform(-25, 25), r.uniform(-25, 25), r.uniform(0, 360))
		o.location = (x, y, h(x, y) * 0.9 + s * 0.12)
		bpy.context.view_layer.update()
		lo = min((o.matrix_world @ vv.co).z for vv in o.data.vertices)
		if lo < 0.002:
			o.location.z += 0.002 - lo
	return h


# ---------------- foundry parts ----------------
def brick_block(w, d, h, loc=(0, 0, 0), hc=0.085, L=0.25):
	"""Solid brickwork: courses of bricks with staggered joints around a dark mortar core (joints read dark)."""
	x0, y0, z0 = loc
	n = max(1, round(h / hc))
	hc = h / n
	B((w - 0.024, d - 0.024, h - 0.012), (x0, y0, z0 + (h - 0.012) / 2), MORTAR(), bevel=0)
	for i in range(n):
		zc = z0 + hc * (i + 0.5)
		cuts, x = [-w / 2], -w / 2 + (L / 2 if i % 2 else L) * (1 + J(0.1))
		while x < w / 2 - L * 0.35:
			cuts.append(x)
			x += L * (1 + J(0.12))
		cuts.append(w / 2)
		for a, b in zip(cuts, cuts[1:]):
			B((b - a - 0.014, d, hc - 0.014), (x0 + (a + b) / 2, y0, zc), BRICK(), bevel=0.009)


def brick_ring(cx, cy, ri, ro, z0, z1, hc=0.085, L=0.24):
	"""A round wall of wedge bricks (inner joints as wide as outer ones) around a hidden mortar ring."""
	n = max(1, round((z1 - z0) / hc))
	hc = (z1 - z0) / n
	nb = max(6, round(2 * math.pi * (ri + ro) / 2 / L))
	rc = ro * math.cos(math.pi / nb) - 0.012  # stay inside the flat outer face of every brick
	lathe([(ri + 0.012, z0), (rc, z0), (rc, z1 - 0.016), (ri + 0.012, z1 - 0.016), (ri + 0.012, z0)], (cx, cy), MORTAR(), seg=nb * 3)
	for i in range(n):
		zb, zt = z0 + hc * i + 0.007, z0 + hc * (i + 1) - 0.007
		for k in range(nb):
			a0 = 2 * math.pi * (k + 0.5 * (i % 2)) / nb
			a1 = a0 + 2 * math.pi / nb
			v = []
			for a, g in ((a0, 1), (a1, -1)):
				for r_, z in ((ri, zb), (ro, zb), (ro, zt), (ri, zt)):
					aa = a + g * 0.007 / r_
					v.append((cx + math.cos(aa) * r_, cy + math.sin(aa) * r_, z))
			f = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
			o = mesh(v, f, BRICK())
			md = o.modifiers.new("bevel", "BEVEL")
			md.width, md.segments, md.limit_method = 0.008, 2, "ANGLE"


def crucible(x, y, z, r, h, fill=None, m=None, lip=True):
	"""A clay crucible (thick wall, belly, pouring lip). fill: None, 'molten', 'crust' (cooled metal skin)."""
	m = m or CLAY("abc"[rng.randrange(3)])
	t = max(0.014, r * 0.16)
	rb, rt = r * 0.68, r * 0.84
	lathe([(0, z), (rb, z), (r, z + h * 0.45), (r * 0.97, z + h * 0.8), (rt, z + h), (rt - t, z + h), (r * 0.97 - t, z + h * 0.8),
		(r - t, z + h * 0.45), (rb - t, z + t), (0, z + t)], (x, y), m, seg=16)
	if lip:  # pouring lip: a small spout pinched out of the rim at -Y
		kit.cone(0.03 * r / 0.1, 0.01, 0.05 * r / 0.1, (x, y - rt + 0.004, z + h - 0.012), m, rot=(-100, 0, 0), verts=6, bevel=0.003)
	if fill:
		zf = z + h * 0.72
		rf = r * 0.98 - t + 0.006
		top = MOLTEN() if fill == "molten" else CU("dark")
		kit.cylinder(rf, 0.016, (x, y, zf - 0.008), top, verts=16, bevel=0)
		for k in range(4 if fill == "molten" else 6):  # skin of dross / slag flecks on the surface
			a, d = k * 2.3 + 0.4, rf * (0.25 + 0.15 * (k % 3))
			kit.gem((x + math.cos(a) * d, y + math.sin(a) * d, zf + 0.002), (0.018 * r / 0.1, 0.015 * r / 0.1, 0.008), CRUST() if fill == "molten" else P((0.12, 0.08, 0.05), 0.4), seed=k + int(r * 100))
		if fill == "molten":
			kit.gem((x + rf * 0.2, y - rf * 0.15, zf + 0.001), (0.03 * r / 0.1, 0.025 * r / 0.1, 0.006), HOT(), seed=3)
	return z + h


def bell(x, y, z, H, m, crown=True):
	"""A cast bell standing on its lip: hollow inside, raised bands, crown loops on top."""
	R = H * 0.62
	lathe([(0, z + H), (0.46 * R, z + H), (0.56 * R, z + 0.95 * H), (0.6 * R, z + 0.8 * H), (0.65 * R, z + 0.55 * H), (0.76 * R, z + 0.3 * H),
		(0.93 * R, z + 0.1 * H), (R, z + 0.03 * H), (R * 0.97, z), (R * 0.85, z), (R * 0.83, z + 0.08 * H), (0.67 * R, z + 0.3 * H),
		(0.56 * R, z + 0.55 * H), (0.5 * R, z + 0.8 * H), (0.36 * R, z + 0.88 * H), (0, z + 0.88 * H)], (x, y), m, seg=22)
	for (zz, rr) in ((0.82, 0.598), (0.2, 0.86)):  # raised bands
		kit.ring(rr * R, max(0.004, H * 0.012), (x, y, z + zz * H), m, seg=22)
	if crown:
		for a in (0, 90):
			kit.ring(0.14 * R, max(0.006, H * 0.03), (x, y, z + H + 0.08 * R), m, rot=(90, 0, a), seg=12)


def settle_pile(cx, cy, rx, ry, H, tones, n, smax, smin, z0=0.0, seed=1, sink=0.35, ground=None):
	"""A heap of loose angular lumps that really settle (round 2: no smooth mound or puddle underneath). Biggest
	first; each lump drops onto the floor (z0) or onto the lumps already under it, sunk a little into them, and the
	heap stays inside a cone H high. ground(x, y): a hidden core the lumps settle on (it must end up fully covered).
	Returns the lumps."""
	import random
	r = random.Random(seed)
	cell, top, out = 0.01, {}, []
	for i in range(n):
		s = smin + (smax - smin) * (1 - i / n) ** 1.2 * r.uniform(0.75, 1.0)
		o = kit.gem((0, 0, 0), (s * r.uniform(0.8, 1.2), s * r.uniform(0.7, 1.05), s * r.uniform(0.45, 0.75)), tones[i % len(tones)], seed=seed * 1000 + i)
		spin(o, r.uniform(-30, 30), r.uniform(-30, 30), r.uniform(0, 360))
		vs = [v.co for v in o.data.vertices]
		lo = Vector([min(v[k] for v in vs) for k in range(3)])
		hi = Vector([max(v[k] for v in vs) for k in range(3)])
		hz = hi.z - lo.z
		for _ in range(30):
			a, d = r.uniform(0, 2 * math.pi), math.sqrt(r.uniform(0, 1))
			x, y = cx + math.cos(a) * rx * d, cy + math.sin(a) * ry * d
			cells = [(i_, j_) for i_ in range(math.floor((x + lo.x * 0.6) / cell), math.floor((x + hi.x * 0.6) / cell) + 1)
				for j_ in range(math.floor((y + lo.y * 0.6) / cell), math.floor((y + hi.y * 0.6) / cell) + 1)]
			g = ground(x, y) if ground else z0
			base = max(top.get(c, g) for c in cells)
			bottom = z0 + 0.001 if base <= z0 + 1e-6 else max(z0 + 0.001, base - sink * hz)
			if bottom + hz * 0.6 <= z0 + H * (1 - d) ** 0.9 + 0.01:
				break
		else:
			bpy.data.objects.remove(o, do_unlink=True)
			continue
		o.location = (x, y, bottom - lo.z)
		for c in cells:
			top[c] = max(top.get(c, z0), bottom + hz * 0.85)
		out.append(o)
	return out


def coal_tones():
	"""Near-black glossy charcoal, a few lumps with a cold blue-grey sheen."""
	return (COAL(), P((0.05, 0.048, 0.05), 0.2), P((0.025, 0.024, 0.028), 0.18), P((0.08, 0.08, 0.09), 0.22))


def bell_profile(H):
	"""Outer and inner (r, z) of a proper bell: crown, shoulder, waist, flaring sound bow, thick lip."""
	R = H * 0.62
	out = [(0.0, H), (0.3 * R, H), (0.45 * R, 0.985 * H), (0.53 * R, 0.95 * H), (0.57 * R, 0.88 * H), (0.585 * R, 0.78 * H),
		(0.6 * R, 0.66 * H), (0.63 * R, 0.52 * H), (0.68 * R, 0.4 * H), (0.76 * R, 0.28 * H), (0.86 * R, 0.17 * H),
		(0.95 * R, 0.09 * H), (R, 0.035 * H), (R * 0.985, 0.0)]
	inn = [(R * 0.88, 0.0), (R * 0.86, 0.04 * H), (0.8 * R, 0.13 * H), (0.71 * R, 0.25 * H), (0.635 * R, 0.38 * H),
		(0.59 * R, 0.52 * H), (0.565 * R, 0.66 * H), (0.55 * R, 0.78 * H), (0.52 * R, 0.87 * H), (0.42 * R, 0.93 * H),
		(0.22 * R, 0.955 * H), (0.0, 0.955 * H)]
	return out, inn


def bell_r(H, zf):
	"""Outer radius of the bell at height fraction zf."""
	out = bell_profile(H)[0][::-1]
	for (r0, z0), (r1, z1) in zip(out, out[1:]):
		if z0 <= zf * H <= z1 and z1 > z0:
			return r0 + (r1 - r0) * (zf * H - z0) / (z1 - z0)
	return out[-1][0]


def bell_big(x, y, z, H, m, crown=True, rune_band=True, seed=1):
	"""Round 2 (owner: "more details, more round bell"): a smooth 48-sided bell with a real bell curve, a thick lip,
	pairs of raised bands, a ring of runes cut into the shoulder and a crown plate with six loops round a centre loop.
	Returns the bell body (for cutting cracks)."""
	import random
	rr = random.Random(seed)
	out, inn = bell_profile(H)
	o = lathe([(r_, z + z_) for r_, z_ in out + inn], (x, y), m, seg=48)
	for p_ in o.data.polygons:
		p_.use_smooth = True
	es = o.modifiers.new("edges", "EDGE_SPLIT")
	es.split_angle = math.radians(35)
	for zf in (0.155, 0.185, 0.6, 0.63, 0.86):  # raised bands
		kit.ring(bell_r(H, zf) - 0.002, max(0.004, H * 0.008), (x, y, z + zf * H), m, seg=48)
	if rune_band:  # runes cut into the shoulder between two bands
		cuts, n = [], 16
		zc, h = 0.73 * H, 0.08 * H
		w = max(0.008, H * 0.014)
		for k in range(n):
			ph = 2 * math.pi * (k + 0.5) / n
			rc = bell_r(H, 0.73) + 0.012
			loc = (x + math.cos(ph) * rc, y + math.sin(ph) * rc, z + zc)
			rz = math.degrees(ph) - 90
			cuts.append(B((w, 0.04, h), loc, GROOVE_M(), bevel=0, rot=(0, 0, rz)))
			kind = rr.randrange(3)
			if kind == 0:
				cuts.append(B((h * 0.5, 0.04, w), (loc[0], loc[1], loc[2] + h * 0.18), GROOVE_M(), bevel=0, rot=(0, 30, rz)))
			elif kind == 1:
				cuts.append(B((h * 0.55, 0.04, w), (loc[0], loc[1], loc[2]), GROOVE_M(), bevel=0, rot=(0, -40, rz)))
			else:
				for dz in (h * 0.3, -h * 0.05):
					cuts.append(B((h * 0.4, 0.04, w), (loc[0], loc[1], loc[2] + dz), GROOVE_M(), bevel=0, rot=(0, 35, rz)))
		carve(o, cuts)
	if crown:  # crown plate, six loops (canons) round a bigger centre loop
		R = H * 0.62
		kit.cylinder(0.34 * R, 0.035 * H, (x, y, z + H + 0.01 * H), m, verts=32, bevel=0.006)
		zt = z + H + 0.027 * H
		ra, rm = 0.07 * R, max(0.008, 0.022 * H)
		for k in range(6):
			ph = 2 * math.pi * k / 6
			kit.ring(ra, rm, (x + math.cos(ph) * 0.22 * R, y + math.sin(ph) * 0.22 * R, zt + ra * 0.7), m, rot=(90, 0, math.degrees(ph) + 90), seg=14)
		kit.ring(0.11 * R, rm * 1.2, (x, y, zt + 0.11 * R * 0.85), m, rot=(90, 0, 0), seg=16)
	return o


def sandy():
	"""Moulding sand, round 2 (owner: "more yellow, better texture"): the grainy soil painting turned sandy yellow."""
	key = ("sandy", "a")
	if key in kit._mats:
		return kit._mats[key]
	m = kit.tex_mat("soil", "a").copy()
	m.name = "sandy"
	nt, b = m.node_tree, m.node_tree.nodes["Principled BSDF"]
	src = b.inputs["Base Color"].links[0].from_node.outputs["Color"]
	hs = nt.nodes.new("ShaderNodeHueSaturation")
	hs.inputs["Hue"].default_value = 0.575
	hs.inputs["Saturation"].default_value = 0.85
	hs.inputs["Value"].default_value = 2.3
	nt.links.new(src, hs.inputs["Color"])
	nt.links.new(hs.outputs["Color"], b.inputs["Base Color"])
	m["tile"] = 0.45
	kit._mats[key] = m
	return m


def ingot(x, y, z, L, W, Hh, m, rotz=0.0, tilt=(0, 0)):
	"""A tapered cast ingot (wide at the bottom like the mould cavity it came from)."""
	o = kit.taper(L, W, L * 0.84, W * 0.74, Hh, (0, 0, 0), m, bevel=0.006)
	o.location = (x, y, z)
	o.rotation_euler = (math.radians(tilt[0]), math.radians(tilt[1]), math.radians(rotz))
	return o


def wall_board(w, h, d=0.05, z0=0.0, m=None):
	"""Vertical planks with a flat back at y = d (each plank its own painting)."""
	n = max(2, round(w / 0.25))
	for i in range(n):
		B((w / n - 0.008, d, h + J(0.02)), (-w / 2 + w / n * (i + 0.5), d / 2, z0 + h / 2), m or WOOD(), bevel=0.01)


def rack_back(W, H):
	"""Plank back for wall pieces: planks, two dark cross rails pressed into them, copper corner plates."""
	wall_board(W, H)
	for z in (0.05, H - 0.06):
		B((W + 0.04, 0.03, 0.07), (0, -0.012, z), T("wood", "dark"), bevel=0.008)
		for x in (-W / 2 + 0.05, W / 2 - 0.05):
			B((0.08, 0.008, 0.08), (x, -0.029, z), CU(), bevel=0.003)
			rivet((x, -0.034, z), CU("dark"), r=0.009)


def wall_shelf(w, z, depth=0.24):
	"""A shelf plank on two brackets against the board front (y = 0), with a front lip. Returns the top height."""
	B((w, depth, 0.035), (0, -depth / 2 + 0.003, z), T("wood", "b"), bevel=0.01)
	for x in (-w / 2 + 0.08, w / 2 - 0.08):
		B((0.04, depth * 0.7, 0.09), (x, -depth * 0.35 + 0.002, z - 0.06), T("wood", "dark"), bevel=0.008)
		rivet((x, -depth * 0.7 + 0.01, z - 0.06), IRON())
	B((w - 0.04, 0.015, 0.03), (0, -depth + 0.012, z + 0.03), T("wood", "dark"), bevel=0.004)
	return z + 0.0175


def iron_hook(x, z, out=0.09, m=None):
	"""An iron wall hook: a bar out of the board with an upturned tip."""
	m = m or IRON("dark")
	rod((x, 0.02, z), (x, -out, z), 0.009, m)
	rod((x, -out + 0.004, z - 0.004), (x, -out + 0.004, z + 0.035), 0.008, m)
	B((0.04, 0.012, 0.05), (x, -0.003, z), m, bevel=0.003)
	rivet((x, -0.01, z + 0.016), IRON("a"), r=0.006)


def peg(x, z, out=0.09):
	log((x, 0.01, z), (x, -out, z + 0.012), 0.014, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)


def tongs(x, zt, L, yy, kind):
	"""Foundry tongs hanging by their ring from (x, zt): two crossed reins, a pivot rivet, jaws of the given kind."""
	m = IRON("dark")
	kit.ring(0.026, 0.007, (x, yy, zt), m, rot=(90, 0, 0), seg=12)
	zp, zb = zt - L * 0.66, zt - L
	for s, (ya, yb) in ((-1, (yy - 0.016, yy - 0.0015)), (1, (yy + 0.0015, yy + 0.016))):
		j = -s  # the rein from one side becomes the jaw on the other side
		pts = [(x + s * 0.02, zt - 0.02), (x + s * 0.012, zt - L * 0.35), (x, zp)]
		if kind == "flat":
			pts += [(x + j * 0.03, zp - 0.07), (x + j * 0.012, zb + 0.05), (x + j * 0.009, zb)]
			ws = [0.016, 0.018, 0.024, 0.02, 0.018, 0.03]
		elif kind == "ring":
			pts += [(x + j * 0.03, zp - 0.035), (x + j * 0.046, zp - 0.07)]
			ws = [0.016, 0.018, 0.024, 0.02, 0.018]
		elif kind == "hook":
			pts += [(x + j * 0.035, zp - 0.08), (x + j * 0.035, zb + 0.035), (x + j * 0.02, zb + 0.006), (x - j * 0.004, zb + 0.012)]
			ws = [0.016, 0.018, 0.024, 0.02, 0.018, 0.016, 0.014]
		else:  # pick: long pointed jaws
			pts += [(x + j * 0.022, zp - 0.06), (x + j * 0.004, zb)]
			ws = [0.016, 0.018, 0.024, 0.018, 0.006]
		strip(pts, ws, ya, yb, m)
	if kind == "ring":
		kit.ring(0.058, 0.0095, (x, yy, zp - 0.115), m, rot=(90, 0, 0), seg=18)
	kit.cylinder(0.014, 0.046, (x, yy, zp), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.003)


def bowl(r, t, m, seg=16):
	"""A hollow round bowl around the origin, rim at z = 0, opening up."""
	out = [(r * math.cos(math.radians(a)), -r * math.sin(math.radians(a))) for a in (0, 25, 50, 70, 85)]
	inn = [((r - t) * math.cos(math.radians(a)), -(r - t) * math.sin(math.radians(a))) for a in (85, 70, 50, 25, 0)]
	return lathe([(0, -r)] + out[::-1] + [(r - t, 0)] + inn[1:] + [(0, -r + t)], (0, 0), m, seg=seg)


def ladle_hang(x, zt, L, r, yy):
	"""A pouring ladle hanging by the eye on its handle; the bowl opens to the front, crusted inside."""
	m = IRON("dark")
	zc = zt - 0.026 - L - r
	kit.ring(0.026, 0.0075, (x, yy, zt), m, rot=(90, 0, 0), seg=12)
	rod((x, yy, zt - 0.03), (x, yy, zc + r - 0.004), 0.011, m)
	log((x, yy, zt - L * 0.35), (x, yy, zt - L * 0.7), 0.021, T("wood", "b"), seg=8, rings=1, bend=0)
	for zz in (zt - L * 0.35, zt - L * 0.7):
		kit.ring(0.022, 0.005, (x, yy, zz), IRON("a"), seg=10)

	def b():
		bowl(r, 0.011, m)
		kit.ring(r, 0.007, (0, 0, 0), m, seg=18)
		kit.cone(0.03, 0.012, 0.035, (r * 0.98, 0, -0.004), m, rot=(0, 90, 0), verts=6, bevel=0.002)  # pouring spout
		for k in range(5):  # crust of cooled metal and slag in the bottom
			a = k * 1.3
			kit.gem((math.cos(a) * r * 0.3, math.sin(a) * r * 0.3, -r + 0.03 + 0.004 * k), (r * 0.3, r * 0.26, 0.02),
				CU("dark") if k % 2 else CRUST(), seed=k + 7)
	group(b, (x, yy, zc), (90, 0, 0))


def shell(cx, cy, r, t, a0, a1, z0, z1, m, n=6, lean=0.0):
	"""A curved shard of a round mould shell (arc from angle a0 to a1 in degrees)."""
	v = []
	for i in range(n + 1):
		a = math.radians(a0 + (a1 - a0) * i / n)
		zt_ = z1 + J(0.02)
		for rr, z in ((r, z0), (r + lean * (zt_ - z0), zt_), (r - t + lean * (zt_ - z0), zt_), (r - t, z0)):
			v.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr, z))
	f = []
	for i in range(n):
		a, b = 4 * i, 4 * (i + 1)
		f += [(a + k, a + (k + 1) % 4, b + (k + 1) % 4, b + k) for k in range(4)]
	f += [(0, 1, 2, 3), (4 * n + 3, 4 * n + 2, 4 * n + 1, 4 * n)]
	return mesh(v, f, m)


def flask(w, d, h, loc, sand=True, handles=True):
	"""A wooden moulding flask: four planks, iron corner straps, side pins; sand rammed in level with the top."""
	x, y, z = loc
	t = 0.035
	for s in (-1, 1):
		B((w, t, h), (x, y + s * (d / 2 - t / 2), z + h / 2), T("wood", "b"), bevel=0.008)
		B((t, d - 2 * t + 0.006, h), (x + s * (w / 2 - t / 2), y, z + h / 2), T("wood", "c"), bevel=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.07, 0.008, h - 0.02), (x + cx * (w / 2 - 0.04), y + cy * (d / 2 + 0.002), z + h / 2), IRON("dark"), bevel=0.002)
			rivet((x + cx * (w / 2 - 0.04), y + cy * (d / 2 + 0.007), z + h / 2), IRON("a"), r=0.007)
	if handles:
		for s in (-1, 1):
			kit.cylinder(0.014, 0.08, (x + s * (w / 2 + 0.035), y, z + h / 2), IRON("dark"), rot=(0, 90, 0), verts=8, bevel=0.003)
			B((0.012, 0.05, 0.05), (x + s * (w / 2 + 0.004), y, z + h / 2), IRON("dark"), bevel=0.003)
	if sand:
		B((w - 2 * t + 0.008, d - 2 * t + 0.008, h - 0.02), (x, y, z + h / 2 - 0.004), SAND(), bevel=0)
	return z + h


# ================= WALL PIECES =================
def cf_tongs_wall():
	W, H = 1.3, 1.35
	rack_back(W, H)
	B((W, 0.045, 0.09), (0, -0.02, 1.17), T("wood", "dark"), bevel=0.01)
	kinds = ("ring", "flat", "hook", "ring", "pick", "flat", "hook")
	lens = (0.9, 0.95, 0.78, 1.0, 0.82, 0.88, 0.72)
	for i, x in enumerate((-0.54, -0.36, -0.18, 0.0, 0.18, 0.36, 0.54)):
		iron_hook(x, 1.15, out=0.1)
		tongs(x, 1.15 - 0.016, lens[i], -0.084, kinds[i])
		B((0.06, 0.008, 0.04), (x, -0.046, 1.24), CU("b" if i % 2 else "c"), bevel=0.003)  # copper number tag
		rivet((x, -0.051, 1.24), CU("dark"), r=0.006)
	B((W - 0.06, 0.1, 0.035), (0, -0.08, 0.06), T("wood", "dark"), bevel=0.008)  # drip ledge under the jaws
	for x in (-0.57, 0.57):
		B((0.04, 0.1, 0.07), (x, -0.05, 0.07), T("wood", "dark"), bevel=0.006)


def cf_ladle_rack():
	W, H = 1.3, 1.55
	rack_back(W, H)
	B((W, 0.05, 0.09), (0, -0.022, 1.38), T("wood", "dark"), bevel=0.01)
	spec = ((-0.47, 0.13, 0.55), (-0.22, 0.1, 0.62), (0.02, 0.085, 0.66), (0.25, 0.11, 0.58), (0.48, 0.075, 0.68))
	for (x, r, L) in spec:
		yy = -r - 0.025
		rod((x, 0.02, 1.37), (x, yy - 0.012, 1.37), 0.009, IRON("dark"))
		rod((x, yy - 0.008, 1.366), (x, yy - 0.008, 1.4), 0.008, IRON("dark"))
		B((0.04, 0.012, 0.05), (x, -0.05, 1.37), IRON("dark"), bevel=0.003)
		ladle_hang(x, 1.37 - 0.018, L, r, yy)
	top = wall_shelf(W - 0.06, 0.26, depth=0.24)
	for i, x in enumerate((-0.45, -0.27, -0.09, 0.09, 0.27, 0.45)):  # clay pouring cups, small funnels
		y = -0.11
		lathe([(0, top - 0.003), (0.03, top - 0.003), (0.07, top + 0.08), (0.075, top + 0.1), (0.06, top + 0.1),
			(0.055, top + 0.085), (0.02, top + 0.012), (0, top + 0.012)], (x, y), CLAY("abc"[i % 3]), seg=14)
		if i % 2:
			kit.gem((x, y, top + 0.02), (0.03, 0.03, 0.012), CU("dark"), seed=i)


def cf_pattern_shelf():
	W, H = 1.3, 1.55
	rack_back(W, H)
	P = lambda: T("wood", "c")  # noqa: E731  pale pattern wood
	t3 = wall_shelf(W - 0.06, 1.08)
	bell(-0.42, -0.12, t3 - 0.004, 0.3, P())
	bell(-0.12, -0.12, t3 - 0.004, 0.2, T("wood", "a"))
	lathe([(0, t3 - 0.004), (0.06, t3 - 0.004), (0.1, t3 + 0.06), (0.11, t3 + 0.12), (0.09, t3 + 0.18), (0.075, t3 + 0.2),
		(0.08, t3 + 0.22), (0, t3 + 0.22)], (0.17, -0.12), P(), seg=18)  # pot pattern
	for s in (-1, 1):
		kit.cylinder(0.025, 0.04, (0.17 + s * 0.115, -0.12, t3 + 0.13), P(), rot=(0, 90, 0), verts=8, bevel=0.004)
	lathe([(0, t3 - 0.004), (0.065, t3 - 0.004), (0.065, t3 + 0.02), (0.03, t3 + 0.04), (0.022, t3 + 0.2), (0.045, t3 + 0.22),
		(0.045, t3 + 0.24), (0.02, t3 + 0.24), (0, t3 + 0.24)], (0.43, -0.12), P(), seg=14)  # candlestick pattern
	t2 = wall_shelf(W - 0.06, 0.6)
	from decor_nov21_f import toothed_gear
	toothed_gear((-0.42, -0.06, t2 + 0.132), 0.12, 0.035, P(), rot=(90 - 8, 0, 0), n=12, spokes=4)
	B((0.3, 0.014, 0.03), (-0.42, -0.012, t2 + 0.012), T("wood", "dark"), bevel=0.004)  # stop strip behind the gear
	for k in range(3):  # ingot patterns in a row
		o = kit.taper(0.16, 0.07, 0.13, 0.05, 0.045, (0, 0, 0), P(), bevel=0.006)
		o.location = (-0.14 + k * 0.0, -0.18 + k * 0.07, t2 - 0.003)
	for k in range(3):  # hinge strap patterns stacked
		zz = t2 - 0.003 + k * 0.022
		B((0.26, 0.06, 0.024), (0.18, -0.12 + J(0.01), zz + 0.012), P(), bevel=0.005, rot=(0, 0, J(4)))
		kit.cylinder(0.018, 0.08, (0.05, -0.12, zz + 0.016), P(), rot=(90, 0, 0), verts=8, bevel=0.003)
	B((0.12, 0.12, 0.09), (0.45, -0.12, t2 + 0.042), P(), bevel=0.012)  # hammer head pattern
	B((0.05, 0.05, 0.08), (0.45, -0.12, t2 + 0.09), GROOVE_M(), bevel=0)
	t1 = wall_shelf(W - 0.06, 0.15)
	for i, x in enumerate((-0.42, -0.14)):  # split patterns: two halves with dowel pins
		for k in range(2):
			B((0.2, 0.15, 0.06), (x, -0.12, t1 + 0.027 + k * 0.058), T("wood", "ac"[k]), bevel=0.01)
		for dx in (-0.06, 0.06):
			kit.cylinder(0.012, 0.03, (x + dx, -0.12, t1 + 0.125), T("wood", "dark"), verts=8, bevel=0.002)
	for k in range(5):  # core prints (short round plugs) in a row
		kit.cylinder(0.03, 0.1, (0.1 + k * 0.08, -0.12, t1 + 0.047), P(), verts=10, bevel=0.005)


def cf_crucible_shelf():
	W, H = 1.25, 1.45
	rack_back(W, H)
	for z, r, h, xs in ((1.02, 0.055, 0.12, (-0.48, -0.29, -0.1, 0.09, 0.28, 0.47)), (0.56, 0.075, 0.16, (-0.42, -0.14, 0.14, 0.42)),
		(0.1, 0.11, 0.22, (-0.38, 0.0, 0.38))):
		top = wall_shelf(W - 0.06, z, depth=max(0.24, 2 * r + 0.06))
		for i, x in enumerate(xs):
			y = -max(0.24, 2 * r + 0.06) / 2
			m = CLAY("dark") if i % 3 == 1 else CLAY("abc"[i % 3])
			if i % 3 == 2:  # stored upside down
				group(lambda: crucible(0, 0, 0, r, h, m=m, lip=False), (x, y, top - 0.004 + h), (180, 0, 0))
			else:
				crucible(x, y, top - 0.004, r, h, m=m)
				if i % 3 == 0:  # lid with a knob
					kit.cylinder(r * 0.86, 0.014, (x, y, top - 0.004 + h + 0.005), CLAY("c"), verts=14, bevel=0.003)
					kit.cylinder(r * 0.22, 0.02, (x, y, top - 0.004 + h + 0.02), CLAY("c"), verts=8, bevel=0.003)


def cf_skimmer_rack():
	W, H = 1.25, 1.5
	rack_back(W, H)
	for x in (-0.58, 0.58):  # side posts
		B((0.06, 0.08, H - 0.02), (x, -0.045, (H - 0.02) / 2), T("wood", "dark"), bevel=0.01)
	B((W - 0.06, 0.05, 0.07), (0, -0.04, 1.22), T("wood", "b"), bevel=0.008)  # holder bar
	# floor box the tool feet stand in
	B((W - 0.08, 0.17, 0.03), (0, -0.1, 0.015), T("wood", "dark"), bevel=0.006)
	B((W - 0.08, 0.025, 0.136), (0, -0.175, 0.08), T("wood", "b"), bevel=0.006)
	for i in range(9):
		x = -0.53 + i * 0.1325
		log((x, -0.06, 1.22), (x, -0.17, 1.23), 0.012, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)  # holder pegs
	tools = ("skimmer", "rake", "poker", "stir", "skimmer", "bar", "rake", "poker")
	for i, kind in enumerate(tools):
		x = -0.465 + i * 0.1325
		yb, yt = -0.12, -0.11
		top = 1.38 + 0.05 * (i % 3)
		rod((x, yb, 0.03), (x, yt, top), 0.011, IRON("dark"))
		log((x, yb, 0.03), (x, yb + 0.001, 0.32), 0.02, T("wood", "b"), seg=8, rings=1, bend=0)  # wooden grip at the foot
		kit.ring(0.021, 0.005, (x, yb, 0.33), IRON("a"), seg=10)
		if kind == "skimmer":
			d = kit.cylinder(0.065, 0.008, (x, yt - 0.003, top + 0.06), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.002)
			cuts = []
			for (dx, dz) in ((0, 0), (0.03, 0.02), (-0.03, 0.02), (0.03, -0.02), (-0.03, -0.02), (0, 0.04), (0, -0.04)):
				cuts.append(kit.cylinder(0.008, 0.04, (x + dx, yt - 0.003, top + 0.06 + dz), GROOVE_M(), rot=(90, 0, 0), verts=8, bevel=0))
			carve(d, cuts)
			kit.ring(0.066, 0.008, (x, yt - 0.003, top + 0.06), IRON("a"), rot=(90, 0, 0), seg=16)
		elif kind == "rake":
			B((0.13, 0.012, 0.06), (x, yt - 0.008, top + 0.02), IRON("dark"), bevel=0.003)
			B((0.03, 0.04, 0.03), (x, yt, top), IRON("a"), bevel=0.004)
		elif kind == "poker":
			strip([(x, top - 0.01), (x, top + 0.05), (x + 0.035, top + 0.085), (x + 0.05, top + 0.065)], [0.022, 0.02, 0.016, 0.01], yt - 0.011, yt + 0.011, IRON("dark"))
		elif kind == "stir":
			kit.cylinder(0.018, 0.14, (x, yt, top - 0.04), IRON("a"), verts=8, bevel=0.004)
		else:  # slag bar: flat chisel tip
			strip([(x, top - 0.01), (x, top + 0.07), (x, top + 0.1)], [0.024, 0.03, 0.008], yt - 0.008, yt + 0.008, IRON("a"))


def cf_mould_board():
	W, H = 1.2, 1.35
	rack_back(W, H)
	m = IRON("dark")
	for row, z in enumerate((1.14, 0.62)):
		for col, x in enumerate((-0.37, 0.0, 0.37)):
			kind = row * 3 + col
			peg(x, z, out=0.1)
			w, h, d = (0.28, 0.2, 0.06) if kind != 2 else (0.22, 0.26, 0.06)
			yf = -0.055 - d / 2  # mould front face
			zc = z - 0.06 - h / 2
			blk = B((w, d, h), (x, -0.055, zc), m, bevel=0.008)
			kit.ring(0.04, 0.008, (x, -0.075, z - 0.035), IRON("a"), rot=(90, 0, 0), seg=12)  # hanging ring over the peg
			B((0.05, 0.03, 0.03), (x, -0.075, z - 0.072), IRON("a"), bevel=0.004)  # ring lug
			cuts = []
			if kind == 0:  # three ingot bars
				for k in range(3):
					cuts += [B((0.22, 0.06, 0.035), (x, yf + 0.006, zc - 0.06 + k * 0.06), GROOVE_M(), bevel=0)]
			elif kind == 1:  # buttons
				for k in range(6):
					cuts += hole(x - 0.09 + (k % 3) * 0.09, zc + (0.04 if k < 3 else -0.04), yf, 0.026, 0.015)
			elif kind == 2:  # spoon
				cuts += hole(x, zc + 0.06, yf, 0.05, 0.016, n=14)
				cuts += [B((0.025, 0.06, 0.14), (x, yf + 0.006, zc - 0.05), GROOVE_M(), bevel=0)]
			elif kind == 3:  # coin blanks
				for k in range(8):
					cuts += hole(x - 0.105 + (k % 4) * 0.07, zc + (0.045 if k < 4 else -0.045), yf, 0.022, 0.008)
			elif kind == 4:  # medallion with a ring channel
				cuts += hole(x, zc, yf, 0.07, 0.014, n=18)
				cuts += [B((0.02, 0.06, 0.05), (x, yf + 0.006, zc + 0.085), GROOVE_M(), bevel=0)]
			else:  # arrowheads
				for k in range(3):
					xx = x - 0.08 + k * 0.08
					c = kit.cone(0.03, 0.0, 0.1, (xx, yf + 0.004, zc + 0.01), GROOVE_M(), rot=(0, 0, 0), verts=3, bevel=0)
					c.scale = (1, 0.5, 1)
					cuts.append(c)
					cuts += [B((0.014, 0.05, 0.05), (xx, yf + 0.006, zc - 0.06), GROOVE_M(), bevel=0)]
			carve(blk, cuts)
			for s in (-1, 1):  # side ears
				B((0.03, 0.04, 0.05), (x + s * (w / 2 + 0.01), -0.055, zc + h * 0.3), IRON("a"), bevel=0.004)


def cf_master_mark_stone():
	brick_block(1.2, 0.3, 0.26, (0, -0.15, 0))
	for x in (-0.5, 0.5):
		brick_block(0.2, 0.3, 1.34, (x, -0.15, 0.26))
	S = T("warmstone", "b")
	slab = B((0.82, 0.18, 1.08), (0, -0.14, 0.26 + 0.54 - 0.004), S, bevel=0.02)
	B((1.32, 0.36, 0.12), (0, -0.16, 1.6 + 0.055), T("warmstone", "a"), bevel=0.025)  # capstone
	yf = -0.23
	cut = []
	cut += groove_path([(-0.36, 0.33), (0.36, 0.33), (0.36, 1.27), (-0.36, 1.27)], yf, 0.016, 0.012, closed=True)  # border
	# the master's mark: a crucible pouring three drops over crossed tongs, inside a ring
	mz = 1.0
	cut += groove_path([(0.15 * math.cos(2 * math.pi * k / 20), mz + 0.17 * math.sin(2 * math.pi * k / 20)) for k in range(20)], yf, 0.016, 0.014, closed=True)
	cut += groove_path([(-0.07, 1.1), (0.07, 1.1), (0.05, 1.0), (-0.05, 1.0)], yf, 0.016, 0.014, closed=True)  # crucible
	cut += groove((0.07, 1.1), (0.1, 1.12), yf, 0.012, 0.012)  # lip
	for k, dz in enumerate((0.96, 0.92, 0.88)):
		cut += groove((0.0, dz), (0.0, dz - 0.016), yf, 0.014 - k * 0.002, 0.012)
	for s in (-1, 1):
		cut += groove((s * -0.09, 0.87), (s * 0.08, 0.95), yf, 0.013, 0.012)
	cut += rune_row(-0.3, 0.3, 0.74, yf, h=0.07, seed=3)
	cut += rune_row(-0.26, 0.26, 0.63, yf, h=0.06, seed=8)
	cut += groove((-0.3, 0.57), (0.3, 0.57), yf, 0.008, 0.01)
	# tally of pours: groups of four strokes struck through
	for g in range(5):
		gx = -0.3 + g * 0.13
		n = 4 if g < 4 else 2
		for k in range(n):
			cut += groove((gx + k * 0.02, 0.4), (gx + k * 0.02, 0.5), yf, 0.01, 0.011)
		if g < 4:
			cut += groove((gx - 0.012, 0.42), (gx + 0.072, 0.48), yf, 0.009, 0.011)
	carve(slab, cut)
	for x in (-0.38, 0.38):  # copper pins holding the stone in the piers
		kit.cylinder(0.02, 0.04, (x, -0.231, 1.25), CU(), rot=(90, 0, 0), verts=8, bevel=0.004)


def cf_strickle_board():
	W, H = 1.15, 1.55
	rack_back(W, H)
	sx = -0.42
	for z in (0.22, 1.36):  # spindle brackets
		B((0.05, 0.1, 0.05), (sx, -0.05, z), IRON("dark"), bevel=0.004)
		rivet((sx, -0.005 - 0.004, z + 0.016), IRON("a"), r=0.006)
	rod((sx, -0.08, 0.2), (sx, -0.08, 1.4), 0.016, IRON("dark"))
	# the strickle: a board whose edge is the outer profile of the bell, swept round the spindle to shape the mould
	Hb, R, z0 = 1.0, 0.46, 0.28
	prof = [(0.46, 1.0), (0.56, 0.95), (0.6, 0.8), (0.65, 0.55), (0.76, 0.3), (0.93, 0.1), (1.0, 0.03), (0.97, 0.0)]
	pts = [(sx + 0.012, z0 + Hb + 0.02)] + [(sx + 0.012 + p * R * 0.82, z0 + q * Hb) for p, q in prof] + [(sx + 0.012, z0 - 0.02)]
	prism(pts, -0.095, -0.065, T("wood", "c"))
	for z in (0.4, 0.75, 1.1):
		B((0.08, 0.036, 0.03), (sx + 0.03, -0.08, z), IRON("a"), bevel=0.003)
		rivet((sx + 0.05, -0.1, z), IRON("dark"), r=0.006)
	# calipers on a peg
	peg(0.25, 1.3, out=0.08)
	for s in (-1, 1):
		strip([(0.25, 1.27), (0.25 + s * 0.09, 1.1), (0.25 + s * 0.11, 0.9), (0.25 + s * 0.07, 0.78)], [0.03, 0.026, 0.022, 0.012],
			-0.05 + s * 0.0085 - 0.0065, -0.05 + s * 0.0085 + 0.0065, T("wood", "b"))
	kit.cylinder(0.02, 0.035, (0.25, -0.05, 1.27), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.003)
	# notched measuring rod on two pegs
	for x in (0.05, 0.45):
		peg(x, 0.42, out=0.09)
	rr = B((0.6, 0.035, 0.05), (0.25, -0.06, 0.462), T("wood", "a"), bevel=0.006)
	carve(rr, [c for k in range(11) for c in groove((0.0 + k * 0.05, 0.47 if k % 2 else 0.455), (0.0 + k * 0.05, 0.49), -0.0775, 0.006, 0.006)])
	# smaller core strickle hanging below the calipers
	peg(0.25, 0.7, out=0.08)
	prism([(0.13, 0.71), (0.37, 0.71), (0.36, 0.62), (0.31, 0.56), (0.27, 0.53), (0.18, 0.53), (0.13, 0.58)], -0.07, -0.045, T("wood", "c"))
	# three small bell gauges (profile templates for hand bells) on their own pegs
	for i, x in enumerate((0.04, 0.24, 0.44)):
		peg(x, 0.3, out=0.08)
		k = 0.7 + 0.15 * i
		prism([(x - 0.06 * k, 0.315), (x + 0.06 * k, 0.315), (x + 0.07 * k, 0.24), (x + 0.1 * k, 0.12), (x + 0.11 * k, 0.09), (x - 0.03 * k, 0.09),
			(x - 0.03 * k, 0.22)], -0.068, -0.046, T("wood", "ac"[i % 2]))


def cf_casting_shelf():
	W, H = 1.3, 1.45
	rack_back(W, H)
	t3 = wall_shelf(W - 0.06, 1.0)
	for i, (x, h) in enumerate(((-0.46, 0.15), (-0.24, 0.18), (0.0, 0.2), (0.24, 0.17), (0.46, 0.14))):
		bell(x, -0.12, t3 - 0.003, h, CU("abc"[i % 3]))
	t2 = wall_shelf(W - 0.06, 0.55)
	for i, x in enumerate((-0.42, -0.15)):  # cast iron pots on three stubby legs
		r = 0.1
		z = t2 + 0.04
		lathe([(0, z), (r * 0.7, z), (r, z + 0.06), (r * 0.98, z + 0.13), (r * 0.86, z + 0.16), (r * 0.9, z + 0.175), (r * 0.8, z + 0.175),
			(r * 0.75, z + 0.16), (r * 0.88, z + 0.13), (r * 0.9, z + 0.06), (r * 0.62, z + 0.012), (0, z + 0.012)], (x, -0.12), IRON("dark"), seg=18)
		for k in range(3):
			a = 2 * math.pi * k / 3 + 0.5
			kit.cone(0.018, 0.012, 0.05, (x + math.cos(a) * 0.055, -0.12 + math.sin(a) * 0.055, t2 + 0.022), IRON("dark"), verts=6, bevel=0.003)
		for s in (-1, 1):
			kit.ring(0.022, 0.006, (x + s * 0.1, -0.12, z + 0.15), IRON("dark"), rot=(90, 0, 0), seg=10)
	from decor_nov21_f import toothed_gear
	toothed_gear((0.14, -0.06, t2 + 0.1), 0.08, 0.03, CU("c"), rot=(85, 0, 0), n=10, spokes=4)
	toothed_gear((0.4, -0.06, t2 + 0.07), 0.055, 0.03, CU("a"), rot=(85, 0, 0), n=8, spokes=3)
	B((0.6, 0.014, 0.03), (0.27, -0.025, t2 + 0.012), T("wood", "dark"), bevel=0.004)
	t1 = wall_shelf(W - 0.06, 0.1)
	for i, x in enumerate((-0.44, -0.24)):  # stacked hinge straps
		for k in range(4):
			B((0.18, 0.05, 0.012), (x, -0.12 + J(0.006), t1 + 0.004 + k * 0.0135), IRON("dark" if k % 2 else "a"), bevel=0.003, rot=(0, 0, J(5)))
		kit.cylinder(0.014, 0.05, (x - 0.09, -0.12, t1 + 0.03), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.002)
	for i, x in enumerate((-0.02, 0.17)):  # door knockers leaning on the board
		B((0.11, 0.02, 0.13), (x, -0.03, t1 + 0.062), CU("abc"[i]), bevel=0.006, rot=(-6, 0, 0))
		kit.ring(0.045, 0.009, (x, -0.048, t1 + 0.05), CU("dark"), rot=(84, 0, 0), seg=14)
		rivet((x, -0.045, t1 + 0.1), CU("dark"), r=0.01)
	for x in (0.36, 0.48):  # candlesticks
		lathe([(0, t1 - 0.003), (0.045, t1 - 0.003), (0.045, t1 + 0.015), (0.02, t1 + 0.035), (0.014, t1 + 0.16), (0.035, t1 + 0.175),
			(0.035, t1 + 0.19), (0.012, t1 + 0.19), (0, t1 + 0.19)], (x, -0.12), CU("b"), seg=12)


def cf_flux_shelf():
	W, H = 1.1, 1.35
	rack_back(W, H)
	for z in (0.95, 0.52, 0.1):
		top = wall_shelf(W - 0.06, z)
		if z > 0.9:  # small balance scale and a scoop
			x = -0.3
			B((0.14, 0.1, 0.02), (x, -0.12, top + 0.008), T("wood", "dark"), bevel=0.004)
			rod((x, -0.12, top + 0.015), (x, -0.12, top + 0.28), 0.008, CU("b"))
			B((0.34, 0.012, 0.014), (x, -0.12, top + 0.28), CU("b"), bevel=0.002)
			for s in (-1, 1):
				px = x + s * 0.16
				rod((px, -0.12, top + 0.28), (px, -0.12, top + 0.13), 0.003, IRON("dark"), seg=4)
				lathe([(0, top + 0.11), (0.05, top + 0.12), (0.055, top + 0.135), (0.048, top + 0.135), (0.044, top + 0.124), (0, top + 0.12)], (px, -0.12), CU("c"), seg=12)
			kit.cone(0.012, 0.0, 0.04, (x, -0.12, top + 0.307), CU("b"), verts=6)
			for i, xx in enumerate((0.05, 0.22, 0.4)):
				lathe([(0, top - 0.003), (0.05, top - 0.003), (0.065, top + 0.08), (0.055, top + 0.15), (0.06, top + 0.16), (0.045, top + 0.16),
					(0.04, top + 0.15), (0, top + 0.15)], (xx, -0.12), CLAY("abc"[i]), seg=14)
				kit.cylinder(0.05, 0.014, (xx, -0.12, top + 0.164), T("wood", "b"), verts=12, bevel=0.003)
				kit.cylinder(0.014, 0.02, (xx, -0.12, top + 0.177), T("wood", "dark"), verts=8, bevel=0.002)
				B((0.05, 0.006, 0.035), (xx, -0.12 - 0.063, top + 0.08), CU("b"), bevel=0.002, rot=(-8, 0, 0))
		elif z > 0.5:  # open crock of pale flux lumps and a wooden scoop
			x = -0.27
			lathe([(0, top - 0.003), (0.1, top - 0.003), (0.13, top + 0.08), (0.12, top + 0.15), (0.13, top + 0.16), (0.115, top + 0.16),
				(0.105, top + 0.15), (0.115, top + 0.08), (0.088, top + 0.012), (0, top + 0.012)], (x, -0.12), CLAY("dark"), seg=18)
			for k in range(12):
				a, d = k * 2.4, 0.03 + 0.06 * ((k * 7) % 5) / 5
				kit.gem((x + math.cos(a) * d, -0.12 + math.sin(a) * d, top + 0.13 + 0.006 * (k % 3)), (0.04, 0.035, 0.03), T("limestone", "ab"[k % 2]), seed=k + 5)
			rod((x + 0.04, -0.12, top + 0.15), (x + 0.16, -0.14, top + 0.26), 0.012, T("wood", "b"))
			for i, xx in enumerate((0.0, 0.17, 0.34)):
				r = 0.06
				lathe([(0, top - 0.003), (r, top - 0.003), (r * 1.12, top + 0.06), (r, top + 0.12), (r * 0.7, top + 0.13), (0, top + 0.13)], (xx, -0.12), CLAY("abc"[i]), seg=14)
				kit.cylinder(r * 0.66, 0.02, (xx, -0.12, top + 0.138), P((0.42, 0.12, 0.06), 0.6), verts=10, bevel=0.003)  # wax seal
				B((0.05, 0.006, 0.035), (xx, -0.12 - r * 1.08, top + 0.06), CU("b"), bevel=0.002)
		else:  # two big stoneware crocks with wooden lids
			for i, xx in enumerate((-0.25, 0.1, 0.38)):
				r = 0.11 if i < 2 else 0.08
				lathe([(0, top - 0.003), (r * 0.85, top - 0.003), (r, top + 0.12), (r * 0.9, top + 0.24), (0, top + 0.24)], (xx, -0.12), CLAY("abc"[i]), seg=16)
				kit.cylinder(r * 0.88, 0.02, (xx, -0.12, top + 0.248), T("wood", "b"), verts=14, bevel=0.004)
				B((r * 1.1, 0.025, 0.02), (xx, -0.12, top + 0.265), T("wood", "dark"), bevel=0.003)
				kit.ring(r * 0.97, 0.006, (xx, -0.12, top + 0.14), kit.tex_mat("rope"), seg=16)


def brick_block_y(w, d, h, loc=(0, 0, 0)):
	"""brick_block with the bricks running along y (side walls)."""
	return group(lambda: brick_block(d, w, h), loc, (0, 0, 90))


def brick_floor(w, d, h=0.06, loc=(0, 0, 0), L=0.24, bw=0.12):
	"""A patch of brick paving: rows of flat bricks with staggered joints over a dark bed."""
	x0, y0, z0 = loc
	B((w - 0.024, d - 0.024, h - 0.012), (x0, y0, z0 + (h - 0.012) / 2), MORTAR(), bevel=0)
	n = max(1, round(d / bw))
	bw = d / n
	for i in range(n):
		cuts, x = [-w / 2], -w / 2 + (L / 2 if i % 2 else L) * (1 + J(0.1))
		while x < w / 2 - L * 0.35:
			cuts.append(x)
			x += L * (1 + J(0.12))
		cuts.append(w / 2)
		for a, b in zip(cuts, cuts[1:]):
			B((b - a - 0.013, bw - 0.013, h - 0.008 + J(0.004)), (x0 + (a + b) / 2, y0 - d / 2 + bw * (i + 0.5), z0 + (h - 0.008) / 2), BRICK(), bevel=0.008)
	return z0 + h - 0.008


def embers(cx, cy, z, r0, r1, n, seed=1):
	"""A bed of glowing coals: hot pieces between near-black ones."""
	import random
	r = random.Random(seed)
	for k in range(n):
		a, d = r.uniform(0, 2 * math.pi), r.uniform(r0, r1)
		hot = k % 3 != 0
		kit.gem((cx + math.cos(a) * d, cy + math.sin(a) * d, z + r.uniform(0, 0.02)), (r.uniform(0.04, 0.07), r.uniform(0.035, 0.06), 0.035),
			P((1.0, 0.3, 0.04), 0.4, glow=1.6) if hot else COAL(), seed=seed * 50 + k)


def tongs_at(at, L, kind, rot):
	"""Tongs built hanging at the origin, then turned and moved (lying or leaning). Returns the parts."""
	return group(lambda: tongs(0, L, L, 0, kind), at, rot)


# ================= FLOOR PIECES =================
def cf_crucible_furnace():
	ri, ro, H = 0.28, 0.48, 0.78
	brick_ring(0, 0, ri, ro, 0, H)
	kit.cylinder(ri + 0.006, 0.5, (0, 0, 0.25), P((0.12, 0.09, 0.08), 0.95), verts=24, bevel=0)  # fire bed inside
	embers(0, 0, 0.49, 0.17, 0.26, 16, seed=4)
	crucible(0, 0, 0.47, 0.15, 0.3, fill="molten", m=CLAY("dark"))
	for z in (0.2, 0.6):
		kit.ring(ro + 0.006, 0.013, (0, 0, z), IRON("dark"), seg=32)
		B((0.06, 0.03, 0.06), (0, -ro - 0.012, z), IRON("a"), bevel=0.004)
		for dx in (-0.018, 0.018):
			rivet((dx, -ro - 0.028, z), IRON("dark"), r=0.007)
	kit.ring((ri + ro) / 2 + 0.01, 0.03, (0, 0, H + 0.005), IRON("dark"), seg=32)  # iron rim on the top course
	# blast pipe from the bellows side, on a little brick pier
	a = math.radians(-35)
	po, pi = (math.cos(a) * 0.82, math.sin(a) * 0.82, 0.2), (math.cos(a) * 0.4, math.sin(a) * 0.4, 0.17)
	log(po, pi, 0.05, CLAY("b"), seg=10, rings=2, bend=0.02, end_m=P((0.08, 0.07, 0.06), 0.9))
	kit.ring(0.054, 0.01, (math.cos(a) * 0.78, math.sin(a) * 0.78, 0.198), CU(), rot=(90, 0, math.degrees(a) + 90), seg=12)
	group(lambda: brick_block(0.16, 0.16, 0.152), (math.cos(a) * 0.74, math.sin(a) * 0.74, 0), (0, 0, math.degrees(a)))
	# the furnace lid lying beside, handle up
	lx, ly = -0.55, -0.5
	kit.cylinder(0.22, 0.045, (lx, ly, 0.0225), CLAY("a"), verts=20, bevel=0.006)
	kit.ring(0.222, 0.014, (lx, ly, 0.03), IRON("dark"), seg=24)
	strip([(lx - 0.08, 0.04), (lx - 0.07, 0.1), (lx + 0.07, 0.1), (lx + 0.08, 0.04)], 0.02, ly - 0.01, ly + 0.01, IRON("dark"))
	for k in range(5):
		kit.gem((0.35 + 0.08 * k, -0.62 + 0.05 * (k % 2), 0.02), (0.06, 0.05, 0.04), COAL(), seed=k + 30)


def cf_crucible_stand():
	brick_block(0.6, 0.6, 0.3)
	kit.cylinder(0.2, 0.02, (0, 0, 0.308), IRON("dark"), verts=18, bevel=0.004)  # drip pan
	kit.ring(0.2, 0.008, (0, 0, 0.318), IRON("dark"), seg=18)
	zr = 0.62
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.3
		rod((math.cos(a) * 0.25, math.sin(a) * 0.25, 0.3), (math.cos(a) * 0.165, math.sin(a) * 0.165, zr), 0.014, IRON("dark"))
		B((0.06, 0.06, 0.02), (math.cos(a) * 0.25, math.sin(a) * 0.25, 0.306), IRON("a"), bevel=0.004)
	kit.ring(0.165, 0.014, (0, 0, zr), IRON("dark"), seg=24)
	crucible(0, 0, zr - 0.45 * 0.3, 0.155, 0.3, fill="molten", m=CLAY("b"))
	tongs_at((0.24, -0.42, 0.0), 0.8, "ring", (-20, 0, 0))
	floor_cut()


def cf_crucible_shank():
	for x in (-0.6, 0.6):
		brick_block(0.3, 0.4, 0.5, (x, 0, 0))
	zr = 0.5
	kit.ring(0.17, 0.018, (0, 0, zr), IRON("dark"), seg=24)
	crucible(0, 0, zr - 0.45 * 0.34, 0.165, 0.34, fill="crust", m=CLAY("dark"))
	for s in (-1, 1):
		B((0.72, 0.045, 0.045), (s * 0.52, 0, zr + 0.0025), IRON("dark"), bevel=0.006)
		B((0.08, 0.06, 0.07), (s * 0.18, 0, zr), IRON("a"), bevel=0.006)  # clamp where the bar meets the ring
		rivet((s * 0.18, -0.033, zr), IRON("dark"), r=0.008)
		rod((s * 0.88, -0.28, zr + 0.0025), (s * 0.88, 0.28, zr + 0.0025), 0.018, IRON("dark"))  # T handle
		for yy in (-1, 1):
			log((s * 0.88, yy * 0.12, zr + 0.0025), (s * 0.88, yy * 0.27, zr + 0.0025), 0.03, T("wood", "b"), seg=8, rings=1, bend=0)
			kit.ring(0.031, 0.006, (s * 0.88, yy * 0.27, zr + 0.0025), IRON("a"), rot=(90, 0, 0), seg=10)


def cf_flask_stack():
	B((0.74, 0.56, 0.04), (0, 0, 0.02), T("wood", "dark"), bevel=0.008)  # bottom board
	w, d, h = 0.62, 0.46, 0.15
	z = 0.04
	for i in range(3):
		flask(w, d, h, (0, 0, z + 0.002))
		z += h + 0.004
	top = z - 0.004 + 0.002 - 0.014
	sand = [o for o in bpy.data.objects if o.data and o.data.materials and o.data.materials[0] is SAND()][-1]
	cuts = [kit.cylinder(0.035, 0.08, (-0.12, 0.02, top), GROOVE_M(), verts=12, bevel=0)]
	for (x, y) in ((0.16, 0.1), (0.16, -0.1)):
		cuts.append(kit.cylinder(0.025, 0.08, (x, y, top), GROOVE_M(), verts=10, bevel=0))
	carve(sand, cuts)
	lathe([(0.04, top - 0.002), (0.1, top - 0.002), (0.085, top + 0.05), (0.07, top + 0.05), (0.06, top + 0.01), (0.045, top + 0.004),
		(0.04, top - 0.002)], (-0.12, 0.02), SAND(), seg=14)  # pouring basin built up round the sprue
	for s in (-1, 1):  # clamps over the whole stack
		for yy in (-0.13, 0.13):
			x0 = s * (w / 2 + 0.03)
			strip([(x0 - s * 0.06, top + 0.03), (x0, top + 0.03), (x0, 0.035), (x0 - s * 0.06, 0.035)], 0.024, yy - 0.012, yy + 0.012, IRON("dark"))
			B((0.04, 0.04, 0.02), (x0 - s * 0.05, yy, top + 0.009 + 0.004), IRON("a"), bevel=0.004)
	# iron weight on one corner
	B((0.16, 0.12, 0.07), (0.18, -0.13, top + 0.004 + 0.035), IRON("dark"), bevel=0.01)
	kit.ring(0.03, 0.008, (0.18, -0.13, top + 0.08), IRON("a"), rot=(0, 90, 0), seg=10)


def cf_mould_box_open():
	B((1.3, 0.6, 0.05), (0, 0, 0.025), T("wood", "dark"), bevel=0.008)  # moulding board
	z0 = 0.05
	w, d, h = 0.46, 0.4, 0.15
	# drag (left), opened: the hammer-head cavity, the handle print and the runner to the sprue
	flask(w, d, h, (-0.3, 0.0, z0 - 0.003), handles=True)
	sand = [o for o in bpy.data.objects if o.data and o.data.materials and o.data.materials[0] is SAND()][-1]
	top = z0 - 0.003 + h - 0.014
	cuts = [B((0.2, 0.085, 0.08), (-0.33, 0.02, top), GROOVE_M(), bevel=0), B((0.09, 0.035, 0.06), (-0.19, 0.02, top), GROOVE_M(), bevel=0),
		B((0.035, 0.12, 0.04), (-0.3, -0.09, top), GROOVE_M(), bevel=0), kit.cylinder(0.03, 0.08, (-0.3, -0.15, top), GROOVE_M(), verts=10, bevel=0)]
	carve(sand, cuts)
	# cope (right), turned over sand side up: its half of the cavity and the sprue hole right through
	flask(w, d, h, (0.32, 0.0, z0 - 0.003), handles=True)
	sand2 = [o for o in bpy.data.objects if o.data and o.data.materials and o.data.materials[0] is SAND()][-1]
	carve(sand2, [B((0.2, 0.085, 0.06), (0.35, 0.02, top), GROOVE_M(), bevel=0), kit.cylinder(0.03, 0.4, (0.32, -0.15, top), GROOVE_M(), verts=10, bevel=0)])
	# the wooden pattern, lifted out and laid on the board in front
	B((0.2, 0.085, 0.08), (-0.05, -0.27 + 0.0, z0 + 0.04 - 0.003), T("wood", "c"), bevel=0.01)
	B((0.09, 0.035, 0.035), (0.095, -0.27, z0 + 0.0175 - 0.003), T("wood", "c"), bevel=0.006)
	kit.cylinder(0.006, 0.03, (-0.05, -0.27, z0 + 0.09), IRON("a"), verts=6, bevel=0)  # draw spike still in it
	kit.ring(0.014, 0.004, (-0.05, -0.27, z0 + 0.108), IRON("a"), rot=(90, 0, 0), seg=8)
	# rapping bar and a small trowel on the board
	rod((-0.5, -0.24, z0 + 0.008), (-0.25, -0.2, z0 + 0.008), 0.008, IRON("dark"), seg=6)
	B((0.11, 0.05, 0.006), (0.3, -0.25, z0 + 0.003), IRON("a"), bevel=0.002, rot=(0, 0, 15))
	log((0.36, -0.235, z0 + 0.02), (0.47, -0.2, z0 + 0.02), 0.016, T("wood", "b"), seg=6, rings=1, bend=0)
	B((0.012, 0.012, 0.03), (0.355, -0.235, z0 + 0.012), IRON("a"), bevel=0)


def cf_ingot_mould_row():
	brick_block(1.52, 0.36, 0.17)
	z0 = 0.17
	m = B((1.42, 0.26, 0.12), (0, 0, z0 + 0.06 - 0.004), IRON("dark"), bevel=0.01)
	top = z0 + 0.116
	xs = [-0.6 + i * 0.2 for i in range(7)]
	cuts = []
	for x in xs:
		c = kit.taper(0.13, 0.075, 0.17, 0.11, 0.09, (x, 0, top - 0.065), GROOVE_M(), bevel=0)
		cuts.append(c)
	cuts += rune_row(-0.55, 0.55, z0 + 0.05, -0.13, h=0.05, w=0.01, depth=0.008, seed=11)
	carve(m, cuts)
	for i, x in enumerate(xs):
		if i in (0, 1, 2, 3, 6):  # cooled ingots, shrunk a little from the walls
			if i == 6:
				continue
			kit.taper(0.124, 0.069, 0.153, 0.097, 0.05, (x, 0, top - 0.063), CU("abc"[i % 3]), bevel=0.005)
		elif i == 4:  # just poured, still glowing
			kit.taper(0.126, 0.071, 0.158, 0.1, 0.052, (x, 0, top - 0.063), MOLTEN(), bevel=0.004)
			kit.gem((x + 0.02, 0.01, top - 0.01), (0.04, 0.03, 0.008), CRUST(), seed=2)
	for s in (-1, 1):  # end lugs
		B((0.06, 0.12, 0.06), (s * 0.73, 0, z0 + 0.06), IRON("a"), bevel=0.008)
		kit.ring(0.035, 0.009, (s * 0.77, 0, z0 + 0.06), IRON("dark"), rot=(90, 0, 90), seg=12)
	# a tipped-out ingot upside down on the floor, and a skimmer across the empty end
	ingot(0.35, -0.38, 0.05, 0.155, 0.1, 0.05, CU("b"), rotz=18, tilt=(180, 0))
	rod((0.5, 0.1, top + 0.01), (1.0, 0.3, 0.01), 0.009, IRON("dark"))
	floor_cut()


def cf_ingot_stack(loot=True):
	for x in (-0.25, 0.0, 0.25):
		B((0.08, 0.6, 0.08), (x, 0, 0.04), T("wood", "dark"), bevel=0.008)
	for k in range(5):
		B((0.66, 0.11, 0.03), (0, -0.24 + k * 0.12, 0.095), T("wood", "abc"[k % 3]), bevel=0.006)
		for x in (-0.25, 0.25):
			rivet((x, -0.24 + k * 0.12, 0.111), IRON("dark"), r=0.006)
	z = 0.11 - 0.003
	L, W, Hh = 0.26, 0.09, 0.05
	bronzes = (BRONZE(), BRONZE_D(), P((0.48, 0.31, 0.16), 0.45, metal=0.6))
	for layer in range(5 if loot else 0):
		n = 5 if layer < 4 else 3
		for col in (-1, 1):
			for k in range(n):
				off = -0.22 + k * 0.11
				m = bronzes[(layer + k + col) % 3]
				if layer % 2 == 0:
					ingot(col * 0.14, off, z, L, W, Hh, m)
				else:
					ingot(off, col * 0.14, z, L, W, Hh, m, rotz=90)
		z += Hh - 0.004
	B((0.12, 0.008, 0.06), (0.0, -0.304, 0.07), CU("dark"), bevel=0.003)  # pallet tag
	for x in (-0.045, 0.045):
		rivet((x, -0.309, 0.07), IRON("dark"), r=0.006)


def cf_ingot_stack_empty():
	cf_ingot_stack(loot=False)


def cf_bell_pit():
	brick_ring(0, 0, 0.72, 0.9, 0, 0.34)
	kit.ring(0.81, 0.025, (0, 0, 0.345), T("warmstone", "b"), seg=36)
	kit.cylinder(0.726, 0.3, (0, 0, 0.15), SAND(), verts=32, bevel=0)  # rammed sand around the mould
	bell_big(0, 0, 0.02, 0.92, BRONZE(), seed=2)
	loam = LOAM()
	shell(0, 0, 0.55, 0.07, 35, 165, 0.29, 0.66, loam, n=8, lean=0.06)  # the back of the mould shell, still standing
	shell(0, 0, 0.56, 0.06, 200, 235, 0.29, 0.44, loam, n=4, lean=0.12)
	import random
	r = random.Random(4)
	for k in range(10):  # broken pieces of the shell lying on the sand and on the rim
		a = r.uniform(190, 360)
		d = r.uniform(0.52, 0.66) if k < 7 else 0.81
		zz = 0.3 if k < 7 else 0.37
		o = kit.gem((math.cos(math.radians(a)) * d, math.sin(math.radians(a)) * d, zz + 0.01), (r.uniform(0.08, 0.14), r.uniform(0.06, 0.1), 0.035), loam, seed=k + 3)
		spin(o, r.uniform(-12, 12), r.uniform(-12, 12), r.uniform(0, 180))
		settle([o], zz - 0.008)
	# crowbar leaning into the pit, a shovel stuck in the sand
	rod((0.62, -0.55, 0.3), (0.35, -0.85, 0.75), 0.013, IRON("dark"))
	log((-0.55, -0.25, 0.28), (-0.85, -0.35, 1.05), 0.022, T("wood", "b"), seg=7, rings=2)
	B((0.16, 0.025, 0.2), (-0.54, -0.245, 0.3), IRON("a"), bevel=0.004, rot=(0, 20, 18))


def cf_bell_cracked():
	H = 0.86
	R = H * 0.62

	def build():
		o = bell_big(0, 0, 0, H, BRONZE(), seed=5)
		cuts = []  # the long crack up from the lip, right through the wall
		pts = [(0.0, 0.0), (0.03, 0.08), (-0.01, 0.16), (0.035, 0.26), (0.0, 0.36), (0.03, 0.45), (0.005, 0.52)]
		for (xa, za), (xb, zb) in zip(pts, pts[1:]):
			zm = (za + zb) / 2
			ang = math.degrees(math.atan2(zb - za, xb - xa))
			cuts.append(B((math.hypot(xb - xa, zb - za) + 0.012, 0.1, 0.011), ((xa + xb) / 2, -bell_r(H, zm / H) + 0.01, zm), GROOVE_M(), bevel=0, rot=(0, -ang, 0)))
		cuts.append(kit.gem((-0.22, -R * 0.9, 0.0), (0.2, 0.16, 0.16), GROOVE_M(), seed=5))  # the chunk out of the lip
		carve(o, cuts)
	parts = group(build, (0, 0, 0), (0, -74, 0))
	settle(parts, 0.0)
	# wooden chocks against the lip and the shoulder so it cannot roll, each with an iron cleat
	for x, y in ((-0.25, -0.5), (-0.25, 0.5), (0.45, -0.32), (0.45, 0.32)):
		kit.taper(0.16, 0.12, 0.16, 0.03, 0.11, (x, y, 0), T("wood", "b"), bevel=0.008)
		B((0.17, 0.02, 0.02), (x, y - 0.05, 0.04), IRON("dark"), bevel=0.003)
	# the broken chunks of lip on the floor (angular, the dark break face up) and the sledge meant to free the casting
	for k, (x, y, sz) in enumerate(((-0.1, -0.72, 0.1), (0.05, -0.85, 0.06), (-0.32, -0.8, 0.045))):
		o = kit.gem((x, y, 0), (sz, sz * 0.75, sz * 0.35), BRONZE_D() if k else BRONZE(), seed=60 + k)
		settle([o], 0.0)
	log((0.15, -0.75, 0.04), (0.75, -0.55, 0.04), 0.024, T("wood", "b"), seg=7, rings=1, bend=0)
	B((0.08, 0.2, 0.08), (0.12, -0.76, 0.04), IRON("dark"), bevel=0.008, rot=(0, 0, 18))
	floor_cut()


def slag_cart(legs=True, full=True):
	"""Two-wheeled slag cart around its axle (x axis through (0, 0, 0.25)), mouth at -Y, handles at +Y."""
	Rw = 0.25
	z0 = Rw + 0.045
	for s in (-1, 1):  # side boards
		B((0.04, 0.7, 0.28), (s * 0.29, -0.13, z0 + 0.14), WOOD(), bevel=0.01)
	B((0.545, 0.66, 0.04), (0, -0.13, z0 + 0.025), T("wood", "dark"), bevel=0.01)  # floor, ends inside the front lip and back board
	B((0.54, 0.04, 0.28), (0, 0.2, z0 + 0.14), WOOD(), bevel=0.01)  # back board
	B((0.54, 0.04, 0.14), (0, -0.46, z0 + 0.07), WOOD(), bevel=0.01)  # low front lip to tip over
	for s in (-1, 1):  # iron corner bands and rivets
		for yy in (-0.46, 0.2):
			B((0.025, 0.06, 0.26 if yy > 0 else 0.13), (s * 0.312, yy, z0 + (0.14 if yy > 0 else 0.07)), IRON("dark"), bevel=0.003)
			rivet((s * 0.326, yy, z0 + 0.1), IRON("a"), r=0.008)
		B((0.025, 0.66, 0.035), (s * 0.317, -0.13, z0 + 0.26), IRON("dark"), bevel=0.003)
	B((0.66, 0.06, 0.05), (0, 0, z0 - 0.02), T("wood", "dark"), bevel=0.006)  # axle block
	rod((-0.42, 0, Rw), (0.42, 0, Rw), 0.025, IRON("dark"))
	for s in (-1, 1):  # wheels: hub, spokes, felloes, iron tyre
		x = s * 0.38
		kit.cylinder(0.05, 0.1, (x, 0, Rw), T("wood", "dark"), rot=(0, 90, 0), verts=10, bevel=0.006)
		kit.ring(Rw - 0.03, 0.03, (x, 0, Rw), T("wood", "b"), rot=(0, 90, 0), seg=20)
		kit.ring(Rw - 0.012, 0.014, (x, 0, Rw), IRON("dark"), rot=(0, 90, 0), seg=20)
		for k in range(8):
			a = math.pi * k / 4
			B((0.03, 0.03, Rw - 0.07), (x, math.cos(a) * (Rw - 0.02) / 2, Rw + math.sin(a) * (Rw - 0.02) / 2), T("wood", "c"), bevel=0.005, rot=(math.degrees(a) - 90, 0, 0))
	for s in (-1, 1):  # handles out of the back
		log((s * 0.26, 0.16, z0 + 0.2), (s * 0.3, 0.85, z0 + 0.16), 0.03, T("wood", "b"), seg=8, rings=2, bend=0.03)
	if legs:
		for s in (-1, 1):
			B((0.05, 0.05, z0 - 0.0), (s * 0.24, -0.4, z0 / 2), T("wood", "dark"), bevel=0.008)
	if full:
		group(lambda: heap(0, 0, 0.23, 0.29, 0.26, SLAGS(), n=45, smax=0.09, smin=0.03, fill=SLAGS()[0], seed=3), (0, -0.13, z0 + 0.035))


def cf_slag_cart():
	slag_cart()


def cf_slag_cart_tipped():
	Rw = 0.25
	parts = group(lambda: slag_cart(legs=False, full=False))
	# lumps that stayed stuck in the back corner
	before = objs()
	for k in range(6):
		kit.gem((-0.18 + 0.07 * k, 0.15, Rw + 0.09 + 0.015 * (k % 2)), (0.07, 0.06, 0.05), SLAGS()[k % 4], seed=k + 40)
	parts += since(before)
	# tip forward about the axle until the front corner of the box rests on the floor (wheels stay on the floor)
	yc, zc = -0.48, 0.045
	lo, hi = 0.0, 1.5
	for _ in range(40):
		mid = (lo + hi) / 2
		if yc * math.sin(mid) + zc * math.cos(mid) > -Rw:
			lo = mid
		else:
			hi = mid
	turn(parts, "X", math.degrees(lo), (0, 0, Rw))
	settle_pile(0, -0.85, 0.45, 0.36, 0.2, SLAGS()[:3], n=90, smax=0.1, smin=0.03, seed=8)  # round 2: just the rocks
	floor_cut()


def cf_flux_tub():
	n, r, h = 18, 0.3, 0.46
	for k in range(n):
		a = 2 * math.pi * k / n
		B((2 * math.pi * r / n - 0.006, 0.032, h + J(0.015)), (math.cos(a) * r, math.sin(a) * r, h / 2), WOOD(), bevel=0.006, rot=(0, 0, math.degrees(a) + 90))
	kit.cylinder(r - 0.008, 0.04, (0, 0, 0.03), T("wood", "dark"), verts=24, bevel=0)
	for z in (0.08, 0.38):
		kit.ring(r + 0.02, 0.012, (0, 0, z), IRON("dark"), seg=32)
	for s in (-1, 1):  # iron ring handles
		kit.ring(0.035, 0.009, (s * (r + 0.05), 0, 0.31), IRON("dark"), rot=(90, 0, 0), seg=12)
		B((0.055, 0.04, 0.04), (s * (r + 0.0325), 0, 0.35), IRON("a"), bevel=0.004)
	kit.cylinder(r - 0.01, 0.06, (0, 0, h - 0.07), T("limestone", "b"), verts=24, bevel=0)
	import random
	rr = random.Random(5)
	for k in range(34):
		a, d = rr.uniform(0, 2 * math.pi), math.sqrt(rr.uniform(0, 1)) * (r - 0.07)
		s = rr.uniform(0.04, 0.075)
		o = kit.gem((math.cos(a) * d, math.sin(a) * d, h - 0.045 + rr.uniform(0, 0.03) * (1 - d / r)), (s, s * 0.85, s * 0.6), T("limestone", "abc"[k % 3]), seed=k + 60)
		spin(o, rr.uniform(-20, 20), rr.uniform(-20, 20), rr.uniform(0, 180))
	# wooden scoop resting in the stone, handle over the rim
	group(lambda: (bowl(0.07, 0.01, T("wood", "c")), log((0.06, 0, 0.0), (0.34, 0, 0.12), 0.016, T("wood", "b"), seg=6, rings=1, bend=0)),
		(-0.05, -0.08, h - 0.0), (0, 0, -30))


def cf_cooling_rack():
	W, D = 1.1, 0.5
	for x in (-W / 2, W / 2):
		for y in (-D / 2, D / 2):
			B((0.045, 0.045, 1.0), (x, y, 0.5), IRON("dark"), bevel=0.005)
			B((0.09, 0.09, 0.02), (x, y, 0.01), IRON("a"), bevel=0.004)
	tops = []
	for z in (0.32, 0.72):
		for y in (-D / 2, D / 2):
			B((W, 0.04, 0.04), (0, y, z), IRON("dark"), bevel=0.004)
		for x in (-W / 2, W / 2):
			B((0.04, D, 0.04), (x, 0, z), IRON("dark"), bevel=0.004)
		for k in range(8):  # grate bars
			B((0.025, D - 0.01, 0.02), (-0.42 + k * 0.12, 0, z + 0.008), IRON("a"), bevel=0.003)
		tops.append(z + 0.018)
	B((W, 0.04, 0.04), (0, D / 2, 0.975), IRON("dark"), bevel=0.004)
	t1, t2 = tops
	for i, (x, h) in enumerate(((-0.36, 0.16), (-0.12, 0.2), (0.12, 0.15))):
		bell(x, 0.02, t2 - 0.003, h, CU("abc"[i]))
	from decor_nov21_f import toothed_gear
	toothed_gear((0.36, 0.0, t2 + 0.015 - 0.003), 0.09, 0.03, CU("c"), rot=(0, 0, 10), n=10)
	for i, x in enumerate((-0.33, 0.0, 0.32)):  # iron pots upside down, the newest still glowing dull red
		r = 0.11
		m = P((0.45, 0.12, 0.05), 0.5, glow=0.7) if i == 1 else IRON("dark")

		def pot(r=r, m=m):
			lathe([(0, 0), (r * 0.7, 0), (r, 0.06), (r * 0.98, 0.13), (r * 0.86, 0.16), (r * 0.9, 0.175), (r * 0.8, 0.175),
				(r * 0.75, 0.16), (r * 0.88, 0.13), (r * 0.9, 0.06), (r * 0.62, 0.012), (0, 0.012)], (0, 0), m, seg=18)
			for k in range(3):
				a = 2 * math.pi * k / 3 + 0.5
				kit.cone(0.018, 0.012, 0.05, (math.cos(a) * 0.055, math.sin(a) * 0.055, -0.022), m, verts=6, bevel=0.003)
		group(pot, (x, 0.0, t1 + 0.175 - 0.003), (180, 0, 0))
	floor_cut()


def cf_crucible_dropped():
	# round 2 (owner: "no puddle"): the metal set solid inside long ago and the slug slid out whole when it dropped
	top = brick_floor(1.3, 1.0, 0.06)

	def cru():
		crucible(0, 0, 0, 0.17, 0.36, m=CLAY("b"))
		o = [ob for ob in bpy.data.objects if ob.type == "MESH"][0]
		carve(o, [B((0.012, 0.09, 0.2), (-0.17 * 0.95, 0, 0.27), GROOVE_M(), bevel=0, rot=(0, 8, 0)),
			kit.gem((-0.14, 0.0, 0.37), (0.1, 0.1, 0.07), GROOVE_M(), seed=4)])
	parts = group(cru, (-0.3, 0.05, 0.3), (0, 84, 0))
	settle(parts, top - 0.004)
	# the cold metal slug: the crucible's inside shape (tapered, a crusty top), lying on the bricks
	slug = group(lambda: (lathe([(0, 0), (0.08, 0), (0.115, 0.1), (0.118, 0.2), (0.1, 0.22), (0, 0.225)], (0, 0), CU("dark"), seg=16),
		[kit.gem((math.cos(k * 2.1) * 0.05, math.sin(k * 2.1) * 0.05, 0.222), (0.03, 0.025, 0.012), CRUST(), seed=k + 30) for k in range(3)]),
		(0.32, 0.02, 0.4), (0, 96, 20))
	settle(slug, top - 0.004)
	for k in range(5):  # shards of the crucible
		o = kit.gem((-0.15 + 0.09 * k, -0.3 - 0.04 * k + 0.02 * (k % 2), 0), (0.06, 0.045, 0.022), CLAY("b"), seed=k + 20)
		settle([o], top - 0.004)
	parts = tongs_at((0, 0, 0), 0.85, "ring", (-90, 0, 70))
	for o in parts:
		o.location += Vector((0.1, -0.3, 0))
	settle(parts, top - 0.003)


def cf_sand_bin():
	h = 0.55
	brick_block(1.3, 0.24, h, (0, 0.33, 0))
	for s in (-1, 1):
		brick_block_y(0.24, 0.5, h, (s * 0.53, -0.045, 0))
	sd = sandy()  # round 2 (owner: "more yellow, better texture"): a grainy yellow sand heap, a few rammed clods on it
	group(lambda: heap(0, 0, 0.42, 0.42, 0.46, (sd,), n=9, smax=0.045, smin=0.025, fill=sd, seed=2), (0, -0.02, 0))
	# shovel stuck in the sand
	B((0.2, 0.02, 0.24), (0.12, -0.08, 0.32), IRON("a"), bevel=0.004, rot=(-14, 10, 0))
	log((0.13, -0.06, 0.42), (0.27, 0.12, 1.05), 0.022, T("wood", "b"), seg=7, rings=2)
	B((0.12, 0.03, 0.03), (0.27, 0.12, 1.06), T("wood", "dark"), bevel=0.006)
	# riddle (sand sieve) leaning on the right wall
	def riddle():
		lathe([(0.2, 0), (0.22, 0), (0.22, 0.07), (0.2, 0.07), (0.2, 0)], (0, 0), T("wood", "b"), seg=22)
		for k in range(5):
			B((0.4, 0.006, 0.006), (0, -0.16 + k * 0.08, 0.02), IRON("dark"), bevel=0)
			B((0.006, 0.4 - 0.0, 0.006), (-0.16 + k * 0.08, 0, 0.028), IRON("dark"), bevel=0)
		kit.ring(0.21, 0.01, (0, 0, 0.035), IRON("a"), seg=22)
	rp = group(riddle, (0.69, -0.34, 0.0), (0, -72, 0))
	settle(rp, 0.0)
	# rammer leaning on the left wall
	rod((-0.72, -0.36, 0.04), (-0.66, -0.3, 0.62), 0.016, T("wood", "b"))
	kit.cylinder(0.04, 0.08, (-0.72, -0.36, 0.04), IRON("dark"), verts=10, bevel=0.006)
	floor_cut()


def cf_moulders_bench():
	W, D, Hb = 1.15, 0.6, 0.62
	legs4(W, D, Hb - 0.03, r=0.045, logs=False, m=T("wood", "dark"))
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		B((W - 0.1, 0.05, 0.06), (0, y, 0.2), T("wood", "dark"), bevel=0.008)
	for k in range(4):  # lower shelf
		B((W - 0.1, 0.12, 0.025), (0, -0.2 + k * 0.133, 0.2 + 0.04), WOOD(), bevel=0.005)
	plank_top(W, D, Hb, t=0.06, n=4)
	t = Hb + 0.03
	# half-rammed flask with the pattern half pressed in
	flask(0.44, 0.36, 0.14, (-0.24, 0.02, t - 0.003))
	ts = t - 0.003 + 0.14 - 0.014
	B((0.18, 0.1, 0.05), (-0.25, 0.02, ts), T("wood", "c"), bevel=0.01)
	kit.cone(0.02, 0.012, 0.15, (-0.36, -0.08, ts + 0.06), T("wood", "b"), verts=8)  # sprue pin
	# rammer, trowel, slick and lifter laid out
	log((0.1, -0.2, t + 0.025), (0.5, -0.14, t + 0.025), 0.022, T("wood", "b"), seg=7, rings=1, bend=0)
	kit.taper(0.06, 0.05, 0.03, 0.05, 0.07, (0.08, -0.2, t + 0.004), T("wood", "dark"), bevel=0.006)
	B((0.12, 0.06, 0.006), (0.18, 0.02, t + 0.003), IRON("a"), bevel=0.002, rot=(0, 0, -10))
	log((0.24, 0.01, t + 0.018), (0.36, -0.01, t + 0.018), 0.016, T("wood", "b"), seg=6, rings=1, bend=0)
	B((0.012, 0.012, 0.016), (0.24, 0.012, t + 0.01), IRON("a"), bevel=0)
	B((0.2, 0.025, 0.008), (0.32, 0.18, t + 0.004), IRON("dark"), bevel=0.002)  # lifter
	B((0.018, 0.025, 0.05), (0.42, 0.18, t + 0.025), IRON("dark"), bevel=0.002)
	lathe([(0, t - 0.003), (0.03, t - 0.003), (0.035, t + 0.01), (0.012, t + 0.02), (0.01, t + 0.1), (0, t + 0.1)], (0.5, 0.15), IRON("a"), seg=10)  # slick
	# bucket of water on the shelf, spare flask boards
	lathe([(0, 0.252), (0.12, 0.252), (0.14, 0.45), (0.125, 0.45), (0.108, 0.265), (0, 0.265)], (0.3, -0.05), WOOD(), seg=18)
	kit.cylinder(0.128, 0.012, (0.3, -0.05, 0.41), P((0.12, 0.2, 0.22), 0.1), verts=18, bevel=0)
	for z in (0.3, 0.42):
		kit.ring(0.13 + (z - 0.25) * 0.1, 0.007, (0.3, -0.05, z), IRON("dark"), seg=18)
	for k in range(4):
		B((0.45, 0.1, 0.03), (-0.22, -0.05 + J(0.01), 0.268 + k * 0.03), T("wood", "abc"[k % 3]), bevel=0.005, rot=(0, 0, J(3)))


def cf_quench_trough():
	h = 0.5
	for s in (-1, 1):
		brick_block(1.2, 0.12, h, (0, s * 0.215, 0))
		brick_block_y(0.12, 0.3, h, (s * 0.54, 0, 0))
	brick_floor(0.95, 0.3, 0.05)  # round 2 (owner: "no water"): the trough stands dry, its brick floor showing
	for k in range(9):  # flakes of black scale left on the floor from old quenching
		kit.gem((-0.4 + 0.1 * k + J(0.02), J(0.09), 0.052), (0.022, 0.016, 0.004), IRON("dark"), seed=k + 50)
	for s in (-1, 1):  # iron coping strips on the long walls
		B((1.22, 0.14, 0.012), (0, s * 0.215, h + 0.004), IRON("dark"), bevel=0.002)
		for x in (-0.5, -0.17, 0.17, 0.5):
			rivet((x, s * 0.215, h + 0.012), IRON("a"), r=0.008)
	# a pole across the trough with a cast pot hanging from it by its bail
	log((0.18, -0.29, h + 0.04), (0.18, 0.29, h + 0.04), 0.03, T("wood", "b"), seg=8, rings=1, bend=0)
	rod((0.18, 0.0, h + 0.04), (0.18, 0.0, h - 0.17), 0.005, IRON("dark"), seg=5)
	lathe([(0, h - 0.33), (0.08, h - 0.33), (0.11, h - 0.27), (0.1, h - 0.2), (0.09, h - 0.2), (0.095, h - 0.27), (0.07, h - 0.315), (0, h - 0.315)], (0.18, 0.0), IRON("dark"), seg=16)
	strip([(0.09, h - 0.2), (0.12, h - 0.17), (0.18, h - 0.16), (0.24, h - 0.17), (0.27, h - 0.2)], 0.008, -0.005, 0.005, IRON("dark"))
	# tongs laid on the coping
	parts = tongs_at((0, 0, 0), 0.8, "flat", (-90, 0, 90))
	bpy.context.view_layer.update()
	xs = [(o.matrix_world @ v.co).x for o in parts for v in o.data.vertices]
	ys = [(o.matrix_world @ v.co).y for o in parts for v in o.data.vertices]
	for o in parts:
		o.location += Vector((-0.12 - (min(xs) + max(xs)) / 2, -0.215 - (min(ys) + max(ys)) / 2, 0))
	settle(parts, h + 0.01)
	kit.cylinder(0.03, 0.04, (-0.6, 0.0, 0.1), T("wood", "dark"), rot=(0, 90, 0), verts=10, bevel=0.005)  # drain bung


def cf_scrap_crate():
	w, d, hh = 0.85, 0.56, 0.45
	B((w - 0.04, d - 0.04, 0.03), (0, 0, 0.015), T("wood", "dark"), bevel=0.006)
	for s in (-1, 1):
		for k in range(2):
			zz = hh * (0.27 + 0.48 * k)
			B((w, 0.025, hh * 0.44), (0, s * (d / 2 - 0.0125), zz), WOOD(), bevel=0.008)
			B((0.025, d - 0.05, hh * 0.44), (s * (w / 2 - 0.0125), 0, zz), WOOD(), bevel=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.05, 0.05, hh), (cx * (w / 2 - 0.015), cy * (d / 2 - 0.015), hh / 2), T("wood", "dark"), bevel=0.008)
			B((0.06, 0.008, 0.1), (cx * (w / 2 - 0.03), cy * (d / 2 + 0.002), hh - 0.06), IRON("dark"), bevel=0.002)
	tones = (CU("dark"), IRON("dark"), CU("c"), IRON("a"))
	group(lambda: heap(0, 0, 0.36, 0.23, 0.44, tones, n=40, smax=0.09, smin=0.03, fill=IRON("dark"), seed=9), (0, 0, 0.03))
	zt = 0.03 + 0.44 * 0.9
	# recognisable scrap on top: bell shards, bent sheet, a broken gear, rods
	shell(0.0, 0.05, 0.2, 0.025, 200, 250, zt - 0.08, zt + 0.02, CU("b"), n=4)
	shell(-0.15, -0.02, 0.15, 0.02, 20, 70, zt - 0.14, zt - 0.04, CU("a"), n=4)
	for k, (x, y, a) in enumerate(((0.2, -0.05, 25), (-0.22, 0.08, -15), (0.08, 0.12, 60))):
		B((0.2, 0.12, 0.006), (x, y, zt - 0.06 - 0.02 * k), CU("abc"[k]), bevel=0.002, rot=(18 - 12 * k, 10 + 8 * k, a))
	from decor_nov21_f import toothed_gear
	toothed_gear((0.15, 0.05, zt - 0.04), 0.07, 0.025, IRON("dark"), rot=(25, 10, 0), n=9)
	for k in range(3):
		rod((-0.3 + 0.1 * k, -0.15 + 0.04 * k, zt - 0.12), (-0.05 + 0.12 * k, 0.15 - 0.05 * k, zt + 0.16 - 0.04 * k), 0.01, IRON("dark") if k % 2 else CU("dark"))


def cf_charcoal_bay(loot=True):
	# round 2 (owner: "better coal pile, it looks like a blob"): a heap of loose angular lumps only, no mound under it
	h = 0.5
	brick_block(1.2, 0.22, h, (0, 0.25, 0))
	for s in (-1, 1):
		brick_block_y(0.22, 0.5, h, (s * 0.49, -0.105, 0))
	coal = coal_tones()
	sx, sy = 0.78, -0.3
	if loot:
		# a hidden dark core (kept well inside), then lumps settled all over it
		core = heap(0, -0.04, 0.27, 0.29, 0.3, (COAL(),), n=0, fill=P((0.02, 0.02, 0.022), 0.6), seed=6)
		settle_pile(0, -0.04, 0.36, 0.4, 0.44, coal, n=380, smax=0.075, smin=0.028, seed=6, sink=0.3,
			ground=lambda x, y: max(0.0, core(x, y) * 0.9))
		# scoop shovel stuck in the heap
		B((0.22, 0.03, 0.2), (-0.1, -0.2, 0.25), IRON("dark"), bevel=0.004, rot=(-20, 0, 8))
		for s in (-1, 1):
			B((0.012, 0.06, 0.2), (-0.1 + s * 0.105, -0.18, 0.26), IRON("dark"), bevel=0.002, rot=(-20, 0, 8))
		log((-0.09, -0.16, 0.34), (-0.02, 0.02, 0.98), 0.022, T("wood", "b"), seg=7, rings=2)
		B((0.13, 0.03, 0.03), (-0.02, 0.02, 0.99), T("wood", "dark"), bevel=0.006)
	else:  # emptied: a few crumbs on the floor, the shovel leaning on the back wall
		settle_pile(0, -0.05, 0.3, 0.32, 0.03, coal, n=26, smax=0.03, smin=0.018, seed=6)
		B((0.22, 0.03, 0.2), (-0.1, -0.2, 0.087), IRON("dark"), bevel=0.004, rot=(-40, 0, 0))  # blade on the floor
		log((-0.1, -0.136, 0.164), (-0.1, 0.378, 0.777), 0.022, T("wood", "b"), seg=7, rings=2, bend=0)  # handle over the wall top
		B((0.13, 0.03, 0.03), (-0.1, 0.39, 0.79), T("wood", "dark"), bevel=0.006, rot=(-40, 0, 0))
	# an iron scuttle beside the bay (full of coal when the bay is full)
	lathe([(0, 0), (0.12, 0), (0.15, 0.24), (0.138, 0.24), (0.11, 0.015), (0, 0.015)], (sx, sy), IRON("dark"), seg=18)
	kit.ring(0.145, 0.009, (sx, sy, 0.238), IRON("a"), seg=18)
	strip([(sx - 0.145, 0.22), (sx - 0.13, 0.36), (sx, 0.42), (sx + 0.13, 0.36), (sx + 0.145, 0.22)], 0.012, sy - 0.006, sy + 0.006, IRON("a"))
	if loot:
		settle_pile(sx, sy, 0.085, 0.085, 0.27, coal, n=30, smax=0.045, smin=0.025, z0=0.015, seed=12)


def cf_charcoal_bay_empty():
	cf_charcoal_bay(loot=False)


MODELS = {f.__name__: f for f in (
	cf_tongs_wall, cf_ladle_rack, cf_pattern_shelf, cf_crucible_shelf, cf_skimmer_rack, cf_mould_board, cf_master_mark_stone,
	cf_strickle_board, cf_casting_shelf, cf_flux_shelf,
	cf_crucible_furnace, cf_crucible_stand, cf_crucible_shank, cf_flask_stack, cf_mould_box_open, cf_ingot_mould_row, cf_ingot_stack,
	cf_ingot_stack_empty, cf_bell_pit, cf_bell_cracked, cf_slag_cart, cf_slag_cart_tipped, cf_flux_tub, cf_cooling_rack, cf_crucible_dropped,
	cf_sand_bin, cf_moulders_bench, cf_quench_trough, cf_scrap_crate, cf_charcoal_bay, cf_charcoal_bay_empty,
)}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name.removesuffix("_empty"))))  # an _empty twin matches its full model
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			floor_cut()
			for o in bpy.data.objects:  # plain-painted parts have no UV map; joining them first would drop every texture
				if o.type == "MESH" and not o.data.uv_layers:
					o.data.uv_layers.new(name="UVMap")
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
