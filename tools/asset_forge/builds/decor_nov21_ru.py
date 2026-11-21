# Decor group RU (Nov 21): what lies around inside the two surface-cave ruins, and what fits once they are rebuilt.
#   blender --background --factory-startup --python builds/decor_nov21_ru.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (marked [wall]) have a flat back at +Y so they sit flush on a wall.
#
# RUINED TOWER (old dwarf stone watchtower: greystone, tower wood, iron, bronze)
#   rt_stair_landing_broken  [story] snapped newel column with a tread stub, fallen spiral treads, a cracked step, bent iron rail
#   rt_lookout_brazier       iron fire bowl with claws on a stone plinth, cold coal, poker and an empty coal scuttle
#   rt_signal_mirror_stand   bronze signal mirror tilted in an iron fork on a banded post, crank, carved code tablet
#   rt_watch_table_map       [story] watchman's table: inked map with weights, dividers, candle stub, tipped mug, stool knocked over
#   rt_arrow_slit_shutter    [wall] cut-stone arrow slit (cross slot) with a carved lintel and a shutter hanging off one hinge, a bolt stuck in it
#   rt_fallen_bell           [story] round bronze bell fallen on its side: true bell curve, cast mouldings, studs, rune band cut in,
#                            cracked lip, headstock beam still strapped on, the snapped half, clapper and rubble
#   rt_weapon_rack           [wall] wall rack: two spears, a poleaxe, a snapped spear put back, round shield on the middle rail
#   rt_water_cistern         stone-ring cistern with iron bands, winch with rope and bucket, lid pushed off onto the floor, ladle on a peg
#   rt_watch_hooks           [wall] watchman's hook board: hollow signal horn on a strap (clear of the lantern), iron lantern, key ring, hand bell, spyglass on pegs
#   rt_watch_roster_slab     [wall] stone slab with a carved tower sign, watch roster runes and tally marks, iron candle bracket, stylus on a chain
#   rt_arrow_crate_spill     [story][LOOT: 10 bolt_stone] bolt crate knocked on its side, lid on the floor, 4 bolts inside and 6
#                            spilled in front, smashed top board.  + rt_arrow_crate_spill_empty (same crate, bolts gone)
#   rt_map_tube_rack         [wall] pigeon-hole cabinet full of leather map tubes and tied map rolls, copper label plates
#
# FALLEN OUTPOST (wooden frontier camp and training yard: shack bark/planks, rope, iron)
#   ro_stake_bundle          [story] roped bundle of sharpened palisade stakes on chocks, loose stakes, maul, hatchet in a stump, chips
#   ro_gate_wing_broken      [story] palisade gate wing fallen back-up across its hinge post, two stakes snapped, a broken tip beside it
#   ro_supply_cart           [story] handcart lost a wheel and slumped onto its axle, keg roped in, broken wheel and an empty crate beside
#   ro_camp_cookery          stone fire ring with cold coals, iron tripod and hanging pot, spit on forked sticks, stump with bowls, log seat
#   ro_duty_board            [wall] notice board with a little shingle roof: pinned torn notices, carved duty tally plank, peg box
#   ro_armour_bench          [story] armour-repair bench: helmet on a stake with a half-riveted patch, anvil stake, hammer, tongs, rivet tin
#   ro_archery_bale          straw target with painted rings on a roped bale, propped by two poles, crossbow bolts stuck in, one on the ground
#   ro_flag_pole             pole on a notched cross foot with braces, guy ropes, a yard and a torn standard with a sewn anvil sign
#   ro_ladder_platform       lookout platform on four posts: plank floor (one board missing), railings (one snapped), X braces, ladder
#   ro_quiver_rack           [wall][LOOT: 1 crossbow_stone + 5 bolt_stone] plank wall rack: the game's tier-1 crossbow on two pegs,
#                            a wooden bolt case with 5 bolts, a spare string coil.  + ro_quiver_rack_empty (crossbow and bolts gone)
# Owner's round-2 rule: there are NO bows or arrows in our world, only crossbow bolts (helper bolt(), short and thick).
#   ro_gate_bar_brackets     [wall] palisade logs with two iron bar brackets holding the gate bar, a snapped third bracket, ring knocker, peep hatch
#   ro_palisade_section      [wall] short palisade: pointed stakes lashed to two back rails, one snapped with its top lying in front
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, disc, kit, log, mesh, plank, rivet, rng, stone  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import GROOVE_M, carve, chain, chip, floor_cut, groove, groove_path, low_z, prism, rest, rune_row, shift, spin, tube, turn  # noqa: E402
from decor_nov21_f import lathe, place_glb  # noqa: E402
from decor_nov21_rx import hollow_tube  # noqa: E402

# ---- materials ----
GS = lambda v=None: T("greystone", v)  # noqa: E731  tower stone family
WD = lambda v=None: T("wood", v)  # noqa: E731  tower wood family
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
IRD = lambda: kit.tex_mat("iron", "dark")  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
BRONZE = lambda: C((0.26, 0.15, 0.06), 0.45, metal=0.75)  # noqa: E731
MIRROR = lambda: C((0.66, 0.52, 0.3), 0.12, metal=0.95)  # noqa: E731
COAL = lambda: C((0.03, 0.028, 0.03), 0.22)  # noqa: E731  near-black, glossy
CHAR = lambda: C((0.07, 0.06, 0.055), 0.95)  # noqa: E731
PARCH = lambda: C((0.7, 0.6, 0.42), 0.95)  # noqa: E731
INK = lambda: C((0.18, 0.12, 0.08), 0.9)  # noqa: E731
RED_INK = lambda: C((0.45, 0.1, 0.06), 0.9)  # noqa: E731
LEATH = lambda v=None: kit.tex_mat("leather", v)  # noqa: E731
ROPE = lambda: kit.tex_mat("rope")  # noqa: E731
STRAW = lambda v=None: kit.tex_mat("straw", v)  # noqa: E731
FEATH = lambda: C((0.62, 0.6, 0.54), 0.9)  # noqa: E731
FEATH2 = lambda: C((0.38, 0.14, 0.08), 0.9)  # noqa: E731
SHADOW = lambda: C((0.03, 0.03, 0.035), 0.95)  # noqa: E731
PL = lambda: T("shackplank", "v%d" % rng.randrange(8))  # noqa: E731  outpost wood family
BK = lambda: T("shackbark", "v%d" % rng.randrange(4))  # noqa: E731
LE = lambda: T("shacklogend", "v%d" % rng.randrange(4))  # noqa: E731
SH = lambda: T("shackshingle", "v%d" % rng.randrange(8))  # noqa: E731
SST = lambda: T("shackstone")  # noqa: E731


# ================= helpers =================
def made(fn):
	"""Run fn and return the objects it made (move them with this list, never bpy.data.objects[-1])."""
	before = set(bpy.data.objects[:])
	fn()
	bpy.context.view_layer.update()
	return [o for o in bpy.data.objects if o not in before]


def place(g, at=(0, 0, 0), rot=(0, 0, 0)):
	M = Matrix.Translation(Vector(at)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
	for o in g:
		o.matrix_world = M @ o.matrix_world
	bpy.context.view_layer.update()
	return g


def settle(g, z=0.0):
	bpy.context.view_layer.update()
	shift(g, (0, 0, z - low_z(g)))
	bpy.context.view_layer.update()
	return g


def carve1(target, cutters):
	"""Cut one cutter at a time (overlapping cutters in one go can wipe a part)."""
	for c in cutters:
		carve([target], [c])
	return target


def top_cut(p0, p1, z, w=0.014, depth=0.012):
	"""A cutter for a groove on a TOP face at height z, from (x, y) p0 to p1."""
	(x0, y0), (x1, y1) = p0, p1
	ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
	return B((math.hypot(x1 - x0, y1 - y0) + w * 0.9, w, depth + 0.03), ((x0 + x1) / 2, (y0 + y1) / 2, z - depth + 0.015), GROOVE_M(), bevel=0, rot=(0, 0, ang))


def gem_at(loc, size, m, seed, rot):
	"""A faceted lump turned around its own centre, then put at loc (kit.gem + spin alone turns it around the world origin)."""
	o = kit.gem((0, 0, 0), size, m, seed=seed)
	spin(o, *rot)
	o.location = loc
	bpy.context.view_layer.update()
	return o


def hexa(v, m):
	return mesh(v, [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)], m)


def rodm(p0, p1, r, m, seg=6):
	return log(p0, p1, r, m, seg=seg, rings=1, ends=False, bend=0)


def stake(p0, p1, r, tip=0.2, m=None):
	"""A sharpened stake: bark body and a fresh-cut point (no end cap at the point)."""
	a, b = Vector(p0), Vector(p1)
	ax = (b - a).normalized()
	e = b - ax * tip
	log(tuple(a), tuple(e), r, m or BK(), seg=8, rings=3, bend=0.03, end_m=LE())
	log(tuple(e - ax * 0.02), tuple(b), r * 0.97, LE(), seg=8, rings=2, ends=False, bend=0, r1=0.006)


def splinters(p, ax=(0, 0, 1), n=4, r=0.03, m=None):
	"""Wood splinters sticking out of a snapped end at p, pointing along ax."""
	ax = Vector(ax).normalized()
	q = Vector((0, 0, 1)).rotation_difference(ax)
	u = ax.orthogonal().normalized()
	v = ax.cross(u)
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.4)
		c = Vector(p) + (u * math.cos(a) + v * math.sin(a)) * r * 0.55 + ax * 0.02
		o = kit.cone(0.012 + r * 0.15, 0.0, 0.06 + J(0.02), tuple(c), m or LE(), verts=4, bevel=0)
		o.rotation_euler = q.to_euler()


def bolt(nock, tip, head="iron", L=0.36, roll=0.0):
	"""A crossbow bolt (short, thick, fletched) pointing from the nock side to its tip; only the direction of nock
	counts, the bolt is always L long and ends at tip. head: "iron" (square point) or a stone material (knapped
	point, like the game's bolt_stone). Returns its parts."""
	a, b = Vector(nock), Vector(tip)
	d = (b - a).normalized()

	def parts():
		log((0, 0, 0.004), (0, 0, L - 0.045), 0.0085, WD("b"), seg=7, rings=1, ends=False, bend=0)
		kit.cylinder(0.011, 0.012, (0, 0, 0.006), IRD(), verts=8, bevel=0.002)  # nock cap
		for z in (0.022, 0.118):
			kit.ring(0.0095, 0.0028, (0, 0, z), ROPE(), seg=10)  # cord bindings
		for k in range(3):  # three stiff leather vanes
			ang = 2 * math.pi * k / 3
			B((0.026, 0.003, 0.08), (math.cos(ang) * 0.019, math.sin(ang) * 0.019, 0.068), FEATH2() if k == 0 else FEATH(), bevel=0,
				rot=(0, 0, math.degrees(ang)))
		kit.cylinder(0.012, 0.022, (0, 0, L - 0.052), IRD(), verts=8, bevel=0.002)  # head socket
		if head == "iron":
			kit.cone(0.017, 0.0, 0.05, (0, 0, L - 0.025), IRON("b"), verts=4, bevel=0)
		else:
			kit.gem((0, 0, L - 0.028), (0.017, 0.015, 0.03), head, seed=7)
	g = made(parts)
	M = Matrix.Translation(b - d * L) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4() @ Matrix.Rotation(math.radians(roll), 4, "Z")
	for o in g:
		o.matrix_world = M @ o.matrix_world
	bpy.context.view_layer.update()
	return g


def lying_bolt(cx, cy, ang, z=0.0, head="iron", roll=0.0):
	"""A bolt lying on a surface at height z, centred at (cx, cy), turned ang degrees."""
	d = Vector((math.cos(math.radians(ang)), math.sin(math.radians(ang)), 0)) * 0.18
	c = Vector((cx, cy, z + 0.05))
	return settle(bolt(tuple(c - d), tuple(c + d), head=head, roll=roll), z - 0.002)


def wheel(R, w=0.07, spokes=8, broken=(), m=None):
	"""A cart wheel at the origin, axle along X: felloes, iron tyre with nails, hub with bands, spokes."""
	n = 10
	for k in range(n):
		a = 2 * math.pi * (k + 0.5) / n
		B((w - 0.004 * (k % 2), 2 * R * math.sin(math.pi / n) + 0.02, 0.075), (0, math.cos(a) * (R - 0.04), math.sin(a) * (R - 0.04)), m or PL(), bevel=0.008,
			rot=(math.degrees(a) + 90, 0, 0))
		aj = 2 * math.pi * k / n
		rivet((w / 2 + 0.003, math.cos(aj) * (R - 0.04), math.sin(aj) * (R - 0.04)), IRD(), r=0.011)
	kit.ring(R - 0.004, 0.016, (0, 0, 0), IRD(), rot=(0, 90, 0), seg=36)
	kit.cylinder(0.085, w + 0.1, (0, 0, 0), m or PL(), rot=(0, 90, 0), verts=12, bevel=0.01)
	for s_ in (-1, 1):
		kit.ring(0.086, 0.012, (s_ * (w / 2 + 0.035), 0, 0), IRD(), rot=(0, 90, 0), seg=14)
	kit.cylinder(0.035, w + 0.14, (0, 0, 0), IRD(), rot=(0, 90, 0), verts=8, bevel=0.004)
	for k in range(spokes):
		a = 2 * math.pi * k / spokes + 0.2
		c, s = math.cos(a), math.sin(a)
		if k in broken:
			log((0, c * 0.07, s * 0.07), (0, c * R * 0.42, s * R * 0.42), 0.022, m or PL(), seg=6, rings=1, ends=False, bend=0)
			splinters((0, c * R * 0.42, s * R * 0.42), (0, c, s), n=3, r=0.022)
			log((0, c * (R - 0.06), s * (R - 0.06)), (0, c * R * 0.72, s * R * 0.72), 0.022, m or PL(), seg=6, rings=1, ends=False, bend=0)
			splinters((0, c * R * 0.72, s * R * 0.72), (0, -c, -s), n=3, r=0.022)
		else:
			log((0, c * 0.07, s * 0.07), (0, c * (R - 0.06), s * (R - 0.06)), 0.022, m or PL(), seg=6, rings=1, ends=False, bend=0)


def keg(x, y, z0, r=0.16, h=0.38, m=None):
	m = m or PL()
	lathe([(0, z0), (r * 0.86, z0), (r * 0.97, z0 + h * 0.25), (r, z0 + h * 0.5), (r * 0.97, z0 + h * 0.75), (r * 0.86, z0 + h), (0, z0 + h)], (x, y), m, seg=16)
	for t, rr in ((0.07, 0.885), (0.3, 0.985), (0.7, 0.985), (0.93, 0.885)):
		kit.ring(r * rr + 0.004, 0.011, (x, y, z0 + h * t), IRD(), seg=18)
	kit.cylinder(r * 0.55, 0.02, (x, y, z0 + h + 0.004), LE(), verts=14, bevel=0.003)
	kit.cylinder(0.025, 0.03, (x + r * 0.4, y, z0 + h + 0.02), LE(), verts=8, bevel=0.003)


def shield_round(x, y, z, R, face=-1, split=False):
	"""A round plank shield facing -Y: carved plank seams, iron rim, boss, rivets."""
	t = 0.035
	o = kit.cylinder(R, t, (x, y, z), WD("b"), rot=(90, 0, 0), verts=24, bevel=0.006)
	fy = y - t / 2
	cuts = []
	for dx in (-R * 0.5, 0, R * 0.5):
		hh = math.sqrt(max(0.0, R * R - dx * dx)) - 0.02
		cuts += groove((x + dx, z - hh), (x + dx, z + hh), fy, 0.01, 0.008)
	carve1(o, cuts)
	kit.ring(R, 0.014, (x, y, z), IRD(), rot=(90, 0, 0), seg=28)
	sphere((x, fy, z), 0.07, IRD(), scale=(1, 0.6, 1), seg=12, rings=8)
	kit.ring(0.075, 0.01, (x, fy, z), IRON("b"), rot=(90, 0, 0), seg=16)
	for k in range(8):
		a = 2 * math.pi * k / 8 + 0.2
		rivet((x + math.cos(a) * (R - 0.04), fy - 0.002, z + math.sin(a) * (R - 0.04)), IRD(), r=0.011)


# ================= RUINED TOWER =================
def _tread(a0, a1, ri, ro, t, m, nose=True, chips=2, seed=1):
	n = 7
	pts = [(math.cos(a0) * ri, math.sin(a0) * ri), (math.cos(a1) * ri, math.sin(a1) * ri)]
	pts += [(math.cos(a1 + (a0 - a1) * i / (n - 1)) * ro, math.sin(a1 + (a0 - a1) * i / (n - 1)) * ro) for i in range(n)]
	o = prism(pts, 0, t, m, axis="z")
	cuts = []
	if nose:
		ad = a1 - 0.07
		cuts.append(top_cut((math.cos(ad) * (ri + 0.06), math.sin(ad) * (ri + 0.06)), (math.cos(ad) * (ro - 0.05), math.sin(ad) * (ro - 0.05)), t, 0.016, 0.01))
	r = random.Random(seed)
	for k in range(chips):
		aa = r.choice((a0, a1))
		cuts.append(chip((math.cos(aa) * ro, math.sin(aa) * ro, t * r.uniform(0.5, 1.0)), (0.06, 0.05, 0.05), seed=seed * 10 + k))
	carve1(o, cuts)
	return o


def rt_stair_landing_broken():
	# the newel column stump: three drums, the top one broken off, iron collars at the joints
	kit.cylinder(0.17, 0.32, (0, 0, 0.16), GS("b"), verts=16, bevel=0.012)
	kit.cylinder(0.165, 0.32, (0, 0, 0.475), GS("c"), verts=16, bevel=0.012)
	top = kit.cylinder(0.16, 0.26, (0, 0, 0.755), GS("a"), verts=16, bevel=0.012)
	carve1(top, [chip((0.07, 0.04, 0.9), (0.2, 0.17, 0.12), seed=3), chip((-0.1, -0.06, 0.88), (0.12, 0.12, 0.08), seed=4)])
	for z in (0.318, 0.632):
		kit.ring(0.168, 0.011, (0, 0, z), IRD(), seg=20)
	# a tread stub still keyed into the middle drum, its outer end snapped
	stub = _tread(math.radians(-16), math.radians(16), 0.1, 0.52, 0.15, GS("c"), seed=5)
	shift([stub], (0, 0, 0.45))
	carve1(stub, [chip((0.52, 0.0, 0.52), (0.12, 0.14, 0.1), seed=6)])
	# fallen treads: one flat, one settled on it, one cracked in two
	g = made(lambda: _tread(math.radians(-17), math.radians(17), 0.12, 0.92, 0.16, GS("b"), seed=7))
	place(g, (-0.12, -0.25, 0.0), (0, 0, 205))
	g = made(lambda: _tread(math.radians(-17), math.radians(17), 0.12, 0.92, 0.16, GS("a"), seed=8))
	place(g, (-0.16, -0.3, 0.155), (0, 0, 216))
	g = made(lambda: (_tread(math.radians(-17), math.radians(17), 0.12, 0.5, 0.16, GS("c"), seed=9, chips=1),))
	place(g, (0.25, -0.35, 0.0), (0, 0, -62))
	g = made(lambda: (_tread(math.radians(-17), math.radians(17), 0.525, 0.92, 0.16, GS("c"), nose=True, seed=10, chips=1),))
	place(g, (0.3, -0.31, 0.0), (0, 0, -50))
	# the bent iron handrail with two balusters, lying on the floor
	rodm((0.35, 0.35, 0.018), (1.05, 0.05, 0.018), 0.018, IRD(), seg=8)
	for t in (0.3, 0.75):
		p = Vector((0.35, 0.35, 0.018)).lerp(Vector((1.05, 0.05, 0.018)), t)
		rodm(tuple(p), tuple(p + Vector((-0.12, -0.3, 0))), 0.013, IRD(), seg=6)
		kit.cylinder(0.022, 0.03, tuple(p + Vector((-0.12, -0.3, 0.004))), IRD(), rot=(0, 90, 0), verts=8, bevel=0.003)
	tube([(1.05, 0.05, 0.018), (1.13, 0.02, 0.03), (1.15, 0.08, 0.06), (1.1, 0.1, 0.05)], 0.016, 0.012, IRD())
	# rubble chips from the stair
	for i, (x, y, s) in enumerate(((0.45, 0.15, 0.09), (0.6, -0.05, 0.07), (-0.35, 0.25, 0.08), (0.2, 0.3, 0.06), (-0.55, -0.1, 0.1), (0.05, -0.75, 0.07), (-0.7, -0.45, 0.06))):
		o = gem_at((x, y, 0.2), (s, s * 0.8, s * 0.55), GS("abc"[i % 3]), 40 + i, (J(20), J(20), J(180)))
		rest(o)


def rt_lookout_brazier():
	o = kit.cylinder(0.36, 0.1, (0, 0, 0.05), GS("c"), verts=8, bevel=0.02)
	carve1(o, [chip((0.36, 0.0, 0.1), (0.07, 0.07, 0.05), seed=2), chip((-0.25, -0.25, 0.1), (0.06, 0.06, 0.05), seed=3)])
	kit.cylinder(0.28, 0.1, (0, 0, 0.145), GS("b"), verts=8, bevel=0.015)
	kit.cylinder(0.075, 0.07, (0, 0, 0.225), IRD(), verts=10, bevel=0.005)
	for x in (-0.05, 0.05):
		rivet((x, -0.07, 0.225), IRON("b"), r=0.012)
	rodm((0, 0, 0.2), (0, 0, 0.74), 0.045, IRD(), seg=8)
	for z in (0.4, 0.6):
		kit.ring(0.05, 0.012, (0, 0, z), IRON("b"), seg=12)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		c, s = math.cos(a), math.sin(a)
		tube([(c * 0.03, s * 0.03, 0.5), (c * 0.15, s * 0.15, 0.56), (c * 0.24, s * 0.24, 0.66), (c * 0.235, s * 0.235, 0.77)], 0.017, 0.012, IRD())
		tube([(c * 0.24, s * 0.24, 0.66), (c * 0.3, s * 0.3, 0.62), (c * 0.29, s * 0.29, 0.57), (c * 0.25, s * 0.25, 0.585)], 0.012, 0.008, IRD())
	z0 = 0.7
	lathe([(0, z0), (0.16, z0), (0.28, z0 + 0.1), (0.34, z0 + 0.2), (0.36, z0 + 0.23), (0.33, z0 + 0.235), (0.30, z0 + 0.2), (0.25, z0 + 0.1), (0.14, z0 + 0.04), (0, z0 + 0.04)],
		(0, 0), IRD(), seg=20)
	kit.ring(0.352, 0.016, (0, 0, z0 + 0.238), IRON("b"), seg=24)
	kit.ring(0.29, 0.012, (0, 0, z0 + 0.12), IRON("b"), seg=22)
	for k in range(12):
		a = 2 * math.pi * k / 12
		rivet((math.cos(a) * 0.335, math.sin(a) * 0.335, z0 + 0.19), IRON("b"), r=0.012)
	for k in range(6):
		a = 2 * math.pi * k / 6 + 0.26
		c, s = math.cos(a), math.sin(a)
		tube([(c * 0.35, s * 0.35, z0 + 0.22), (c * 0.355, s * 0.355, z0 + 0.3), (c * 0.33, s * 0.33, z0 + 0.36), (c * 0.29, s * 0.29, z0 + 0.37)], 0.013, 0.007, IRD())
	disc(0.275, z0 + 0.14, z0 + 0.16, (0, 0), CHAR(), seg=20, wob=0.02)
	r = random.Random(5)
	for i in range(22):
		a, d = r.uniform(0, 6.28), math.sqrt(r.uniform(0, 1)) * 0.22
		s = r.uniform(0.04, 0.08)
		o = gem_at((math.cos(a) * d, math.sin(a) * d, z0 + 0.16 + s * 0.2), (s, s * 0.8, s * 0.6), COAL(), 60 + i, (r.uniform(-30, 30), r.uniform(-30, 30), r.uniform(0, 360)))
	# poker leaning on the rim
	rodm((0.6, -0.36, 0.01), (0.31, -0.19, z0 + 0.25), 0.011, IRD(), seg=6)
	kit.ring(0.03, 0.008, (0.295, -0.18, z0 + 0.28), IRD(), rot=(90, 0, 35), seg=10)
	tube([(0.6, -0.36, 0.01), (0.64, -0.38, 0.02), (0.65, -0.38, 0.06)], 0.01, 0.008, IRD())
	# coal scuttle beside the plinth
	lathe([(0, 0.0), (0.12, 0.0), (0.14, 0.2), (0.125, 0.2), (0.108, 0.02), (0, 0.02)], (-0.55, -0.15), IRD(), seg=24)
	kit.ring(0.141, 0.01, (-0.55, -0.15, 0.198), IRON("b"), seg=16)
	tube([(-0.55 - 0.14, -0.15, 0.19)] + [(-0.55 - math.cos(t) * 0.14, -0.15, 0.19 + math.sin(t) * 0.12) for t in (0.6, 1.2, 1.9, 2.5)] + [(-0.55 + 0.14, -0.15, 0.19)], 0.008, 0.008, IRD())


def rt_signal_mirror_stand():
	foot = B((0.5, 0.5, 0.14), (0, 0, 0.07), GS("b"), bevel=0.025)
	carve1(foot, [chip((0.25, -0.25, 0.14), (0.07, 0.07, 0.06), seed=2)] + rune_row(-0.17, 0.17, 0.07, -0.25, h=0.06, seed=4))
	B((0.36, 0.36, 0.1), (0, 0, 0.185), GS("c"), bevel=0.02)
	B((0.12, 0.12, 1.06), (0, 0, 0.75), WD("dark"), bevel=0.012)
	for z in (0.33, 0.98):
		B((0.134, 0.134, 0.045), (0, 0, z), IRD(), bevel=0.004)
		for x in (-0.035, 0.035):
			rivet((x, -0.068, z), IRON("b"), r=0.01)
	for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		log((dx * 0.17, dy * 0.17, 0.22), (dx * 0.055, dy * 0.055, 0.56), 0.026, WD("dark"), seg=6, rings=1, bend=0)
	B((0.7, 0.08, 0.06), (0, 0, 1.3), IRD(), bevel=0.006)
	for s_ in (-1, 1):
		B((0.04, 0.07, 0.4), (s_ * 0.31, 0, 1.49), IRD(), bevel=0.005)
		rivet((s_ * 0.31, -0.036, 1.33), IRON("b"), r=0.011)
	B((0.1, 0.1, 0.06), (0, 0, 1.29), IRON("b"), bevel=0.005)

	def mir():
		kit.cylinder(0.25, 0.03, (0, 0.022, 0), WD("dark"), rot=(90, 0, 0), verts=24, bevel=0.005)
		kit.cylinder(0.23, 0.016, (0, 0.0, 0), MIRROR(), rot=(90, 0, 0), verts=28, bevel=0.003)
		kit.ring(0.24, 0.02, (0, 0.0, 0), IRD(), rot=(90, 0, 0), seg=32)
		for k in range(10):
			a = 2 * math.pi * k / 10
			rivet((math.cos(a) * 0.24, -0.018, math.sin(a) * 0.24), IRON("b"), r=0.01)
		for s_ in (-1, 1):
			kit.cylinder(0.022, 0.07, (s_ * 0.275, 0, 0), IRON("b"), rot=(0, 90, 0), verts=10, bevel=0.003)
		B((0.012, 0.012, 0.06), (0, -0.01, 0.285), IRD(), bevel=0)
		kit.ring(0.028, 0.006, (0, -0.01, 0.33), IRD(), rot=(90, 0, 0), seg=12)
		for s_ in (-1, 1):
			B((0.004, 0.004, 0.05), (s_ * 0.0, -0.01, 0.33), IRD(), bevel=0, rot=(0, s_ * 45, 0))
	place(made(mir), (0, 0, 1.56), (-25, 0, 0))
	# crank on the right pin
	kit.cylinder(0.03, 0.06, (0.36, 0, 1.56), IRD(), rot=(0, 90, 0), verts=10, bevel=0.003)
	kit.ring(0.075, 0.01, (0.37, 0, 1.56), IRON("b"), rot=(0, 90, 0), seg=16)
	for k in range(4):
		a = math.pi / 2 * k
		rodm((0.37, math.cos(a) * 0.028, 1.56 + math.sin(a) * 0.028), (0.37, math.cos(a) * 0.075, 1.56 + math.sin(a) * 0.075), 0.007, IRON("b"))
	rodm((0.37, 0.0, 1.635), (0.44, 0.0, 1.635), 0.009, IRD())
	kit.cylinder(0.016, 0.06, (0.47, 0, 1.635), WD("b"), rot=(0, 90, 0), verts=8, bevel=0.004)
	# carved signal code tablet set in a slot on the foot
	tab = B((0.24, 0.045, 0.17), (0, -0.215, 0.215), GS("a"), bevel=0.01)
	cuts = []
	for i, z in enumerate((0.27, 0.215, 0.165)):
		cuts += groove((-0.09, z), (-0.05, z), -0.2375, 0.012, 0.01)
		cuts += rune_row(-0.02, 0.1, z, -0.2375, h=0.04, w=0.008, depth=0.008, seed=20 + i)
	carve1(tab, cuts)


def _stool(r=0.17, h=0.42):
	kit.cylinder(r, 0.05, (0, 0, h), WD("b"), verts=14, bevel=0.01)
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.09, math.sin(a) * 0.09, h - 0.01), (math.cos(a) * 0.17, math.sin(a) * 0.17, 0.0), 0.022, WD("dark"), seg=6, rings=2, bend=0.02)
	kit.ring(0.12, 0.012, (0, 0, 0.18), WD("dark"), seg=14)


def rt_watch_table_map():
	W, D, H = 1.3, 0.78, 0.78
	for x in (-W / 2 + 0.08, W / 2 - 0.08):
		for y in (-D / 2 + 0.08, D / 2 - 0.08):
			B((0.09, 0.09, H - 0.055), (x, y, (H - 0.055) / 2), WD("dark"), bevel=0.012)
		B((0.07, D - 0.16, 0.06), (x, 0, 0.16), WD("dark"), bevel=0.008)
	B((W - 0.16, 0.06, 0.06), (0, 0, 0.16), WD("dark"), bevel=0.008)
	for y in (-D / 2 + 0.08, D / 2 - 0.08):
		B((W - 0.17, 0.035, 0.1), (0, y, H - 0.11), WD("b"), bevel=0.008)
	for i in range(4):
		plank((W, D / 4 - 0.008, 0.06), (0, -D / 2 + D / 4 * (i + 0.5), H - 0.03), m=WD("abc"[i % 3]))
	for x in (-W / 2 + 0.08, W / 2 - 0.08):
		B((0.1, 0.012, 0.09), (x, -D / 2 + 0.03, H - 0.11), IRD(), bevel=0.003)
		rivet((x, -D / 2 + 0.023, H - 0.09), IRON("b"), r=0.009)
		rivet((x, -D / 2 + 0.023, H - 0.13), IRON("b"), r=0.009)

	def mapsheet():
		B((0.64, 0.46, 0.006), (0, 0, 0.001), PARCH(), bevel=0)
		kit.cylinder(0.02, 0.46, (0.33, 0, 0.018), PARCH(), rot=(90, 0, 0), verts=10, bevel=0.002)
		zi = 0.0055
		coast = [(-0.29, 0.2), (-0.2, 0.12), (-0.18, 0.02), (-0.24, -0.08), (-0.2, -0.19), (-0.1, -0.21)]
		river = [(0.27, 0.18), (0.18, 0.1), (0.12, 0.12), (0.03, 0.04), (0.0, -0.06), (-0.08, -0.1), (-0.19, -0.13)]
		for path, w in ((coast, 0.008), (river, 0.006)):
			for a, b in zip(path, path[1:]):
				ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
				B((math.hypot(b[0] - a[0], b[1] - a[1]) + w, w, 0.002), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, zi), INK(), bevel=0, rot=(0, 0, ang))
		for (x, y) in ((0.05, 0.16), (0.12, 0.17), (0.19, 0.15), (-0.05, 0.17)):
			for s_ in (-1, 1):
				B((0.04, 0.006, 0.002), (x + s_ * 0.014, y, zi), INK(), bevel=0, rot=(0, 0, s_ * 55))
		B((0.03, 0.03, 0.002), (0.12, -0.05, zi), INK(), bevel=0)
		for k in range(3):
			B((0.007, 0.007, 0.002), (0.108 + k * 0.012, -0.05, zi + 0.0015), INK(), bevel=0)
		for k in range(6):
			B((0.025, 0.006, 0.002), (0.1 - k * 0.04, -0.03 - k * 0.012, zi), RED_INK(), bevel=0, rot=(0, 0, 15))
		for s_ in (-1, 1):
			B((0.04, 0.007, 0.002), (-0.13, -0.11, zi), RED_INK(), bevel=0, rot=(0, 0, s_ * 45))
		for ang, ln in ((0, 0.09), (90, 0.09), (45, 0.05), (-45, 0.05)):
			B((ln, 0.005, 0.002), (0.23, -0.15, zi), INK(), bevel=0, rot=(0, 0, ang))
		for (x, y) in ((-0.3, -0.21), (0.27, 0.21), (-0.3, 0.21)):
			B((0.05, 0.05, 0.035), (x, y, 0.02), IRD(), bevel=0.005)
			kit.ring(0.014, 0.004, (x, y, 0.04), IRON("b"), rot=(90, 0, 0), seg=8)
	place(made(mapsheet), (-0.12, -0.04, H), (0, 0, 4))
	# dividers lying on the map
	for ang in (-8, 8):
		B((0.2, 0.008, 0.006), (0.12 + 0.1 * math.cos(math.radians(ang)), 0.12 + 0.1 * math.sin(math.radians(ang)), H + 0.0095), IRD(), bevel=0, rot=(0, 0, ang))
	kit.cylinder(0.014, 0.012, (0.12, 0.12, H + 0.012), CU(), verts=10, bevel=0.002)
	# candle stub in an iron dish
	kit.cylinder(0.06, 0.012, (-0.5, 0.25, H + 0.005), IRD(), verts=14, bevel=0.003)
	kit.ring(0.06, 0.007, (-0.5, 0.25, H + 0.012), IRON("b"), seg=14)
	kit.cylinder(0.026, 0.05, (-0.5, 0.25, H + 0.035), C((0.86, 0.79, 0.6), 0.85), verts=10, bevel=0.005)
	kit.cylinder(0.003, 0.012, (-0.5, 0.25, H + 0.065), INK(), verts=5, bevel=0)
	kit.ring(0.02, 0.006, (-0.565, 0.25, H + 0.01), IRD(), rot=(90, 0, 0), seg=10)
	# map tube and tipped mug
	kit.cylinder(0.04, 0.42, (0.3, 0.27, H + 0.037), LEATH("b"), rot=(0, 90, 0), verts=12, bevel=0.004)
	for x in (0.09, 0.51):
		kit.cylinder(0.044, 0.04, (x, 0.27, H + 0.037), CU(), rot=(0, 90, 0), verts=12, bevel=0.004)
	ang = 30
	kit.cylinder(0.05, 0.12, (0.42, -0.2, H + 0.047), WD("b"), rot=(90, 0, ang), verts=10, bevel=0.006)
	a = math.radians(ang)
	for t in (-0.035, 0.035):
		kit.ring(0.052, 0.008, (0.42 + math.sin(a) * t, -0.2 - math.cos(a) * t, H + 0.047), CU("dark"), rot=(90, 0, ang), seg=12)
	# the stool knocked over beside the table
	g = made(_stool)
	turn(g, "X", 90, (0, 0, 0))
	place(g, (0.35, -0.85, 0), (0, 0, 20))
	settle(g)


def rt_arrow_slit_shutter():
	BK_Y = 0.12
	B((0.86, 0.04, 1.46), (0, BK_Y - 0.02, 0.73), SHADOW(), bevel=0)
	rows = (0.0, 0.26, 0.5, 0.76, 1.0, 1.24, 1.46)
	r = random.Random(3)
	stones = []
	for i in range(len(rows) - 1):
		z0, z1 = rows[i] + 0.004, rows[i + 1] - 0.004
		x = -0.43 + (0.12 if i % 2 else 0.0)
		widths = []
		while x < 0.43:
			w = r.uniform(0.22, 0.34)
			widths.append((max(-0.43, x), min(0.43, x + w)))
			x += w
		if i % 2:
			widths.insert(0, (-0.43, -0.31))
		for (xa, xb) in widths:
			if xb - xa < 0.05:
				continue
			d = 0.14 + r.uniform(-0.012, 0.012)
			stones.append(B((xb - xa - 0.008, d, z1 - z0), ((xa + xb) / 2, BK_Y - 0.035 - d / 2, (z0 + z1) / 2), GS("abc"[r.randrange(3)]), bevel=0.02))
	for s in stones:
		c = B((0.13, 0.4, 0.86), (0, 0.0, 0.76), GROOVE_M(), bevel=0)
		carve([s], [c])
	for s in stones:
		c = B((0.38, 0.4, 0.075), (0, 0.0, 0.84), GROOVE_M(), bevel=0)
		carve([s], [c])
	for k in range(2):
		chip_target = stones[r.randrange(len(stones))]
		carve([chip_target], [chip((r.uniform(-0.4, 0.4), BK_Y - 0.17, r.uniform(0.1, 1.4)), (0.06, 0.05, 0.05), seed=30 + k)])
	# sill and carved lintel
	B((0.46, 0.13, 0.07), (0, -0.075, 0.31), GS("b"), bevel=0.015)
	lin = B((0.56, 0.07, 0.2), (0, -0.075, 1.3), GS("a"), bevel=0.015)
	fy = -0.11
	cuts = groove_path([(-0.2, 1.22), (-0.2, 1.3), (-0.12, 1.36), (0.0, 1.38), (0.12, 1.36), (0.2, 1.3), (0.2, 1.22)], fy, 0.013, 0.01)
	cuts += rune_row(-0.12, 0.12, 1.28, fy, h=0.06, w=0.009, depth=0.009, seed=7)
	carve1(lin, cuts)
	# the shutter, hanging off its top hinge (the lower hinge snapped)

	def shutter():
		for i in range(3):
			B((0.112, 0.03, 0.7 + J(0.02)), (0.057 + i * 0.114, -0.015, -0.35), WD("abc"[i]), bevel=0.008)
		for z in (-0.12, -0.58):
			B((0.33, 0.025, 0.07), (0.17, -0.04, z), WD("dark"), bevel=0.006)
		B((0.06, 0.025, 0.5), (0.17, -0.04, -0.35), WD("dark"), bevel=0.006, rot=(0, 52, 0))
		for z in (-0.12, -0.58):
			B((0.26, 0.012, 0.035), (0.12, -0.058, z), IRD(), bevel=0.003)
			for x in (0.03, 0.12, 0.22):
				rivet((x, -0.065, z), IRON("b"), r=0.009)
		kit.cylinder(0.018, 0.06, (0.0, -0.02, -0.12), IRD(), verts=8, bevel=0.002)
		kit.ring(0.03, 0.007, (0.26, -0.06, -0.38), IRON("b"), rot=(90, 0, 0), seg=12)
		rivet((0.26, -0.035, -0.35), IRD(), r=0.012)
	g = made(shutter)
	place(g, (-0.22, -0.065, 1.08), (0, 22, 0))
	kit.cylinder(0.016, 0.1, (-0.22, -0.07, 1.08 - 0.12), IRD(), rot=(90, 0, 0), verts=8, bevel=0.002)
	B((0.05, 0.06, 0.03), (-0.22, -0.07, 0.62), IRD(), bevel=0.004)
	tube([(-0.22, -0.1, 0.62), (-0.2, -0.13, 0.6), (-0.19, -0.14, 0.57)], 0.009, 0.007, IRD())
	# a crossbow bolt stuck in the shutter
	bpy.context.view_layer.update()
	bolt((0.05, -0.55, 0.92), (-0.05, -0.06, 0.76), roll=20)


BELL_OUT = [(0.35, 0.0), (0.354, 0.03), (0.338, 0.075), (0.298, 0.13), (0.258, 0.2), (0.234, 0.28), (0.224, 0.36), (0.221, 0.44),
	(0.213, 0.5), (0.199, 0.555), (0.166, 0.597), (0.1, 0.617), (0.0, 0.622)]


def bell_r(z):
	"""Outer radius of the bell at height z (standing, mouth down)."""
	for (r0, z0), (r1, z1) in zip(BELL_OUT, BELL_OUT[1:]):
		if z0 <= z <= z1:
			return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
	return 0.0


def rt_fallen_bell():
	# a true bell curve: rounded crown, long waist, flared sound-bow and a thick lip (mouth really hollow)
	inner = [(0, 0.585), (0.1, 0.578), (0.15, 0.56), (0.175, 0.52), (0.18, 0.44), (0.185, 0.36), (0.2, 0.27), (0.23, 0.19), (0.265, 0.12),
		(0.29, 0.06), (0.302, 0.0)]
	prof = inner + BELL_OUT

	def bell():
		lathe(prof, (0, 0), BRONZE(), seg=40)
		for z, mn in ((0.04, 0.009), (0.1, 0.007), (0.27, 0.007), (0.29, 0.005), (0.41, 0.005), (0.43, 0.007), (0.52, 0.008)):
			kit.ring(bell_r(z) + mn - 0.004, mn, (0, 0, z), BRONZE(), seg=40)  # cast mouldings
		for k in range(16):  # a row of cast studs round the shoulder
			a = 2 * math.pi * (k + 0.5) / 16
			rr = bell_r(0.475)
			sphere((math.cos(a) * rr, math.sin(a) * rr, 0.475), 0.011, BRONZE(), seg=8, rings=5)
		for k in range(6):  # crown loops (canons)
			kit.ring(0.045, 0.014, (0, 0, 0.66), BRONZE(), rot=(90, 0, k * 30), seg=12)
		kit.cylinder(0.06, 0.03, (0, 0, 0.63), BRONZE(), verts=16, bevel=0.004)
		B((0.17, 0.62, 0.15), (0, -0.05, 0.765), WD("dark"), bevel=0.012)
		for y in (-0.07, 0.07):
			B((0.19, 0.035, 0.19), (0, y, 0.74), IRD(), bevel=0.004)
			for z in (0.72, 0.8):
				rivet((0.096, y, z), IRON("b"), r=0.012)
				rivet((-0.096, y, z), IRON("b"), r=0.012)
		kit.cylinder(0.035, 0.1, (0, 0.29, 0.765), IRD(), rot=(90, 0, 0), verts=10, bevel=0.003)
		splinters((0, -0.36, 0.765), (0, -1, 0), n=5, r=0.07, m=WD("c"))
	g = made(bell)
	runes_cut = []
	for i in range(9):
		a = math.pi + (i - 4) * 0.12
		rr = bell_r(0.35)
		for tilt, dz, hh in ((0, 0, 0.075), (35 if i % 2 else -35, 0.012, 0.04)):
			runes_cut.append(B((0.03, 0.011, hh), (math.cos(a) * rr, math.sin(a) * rr, 0.35 + dz), GROOVE_M(), bevel=0, rot=(tilt, 0, math.degrees(a))))
	bell_o = max((o for o in g if o.type == "MESH"), key=lambda o: len(o.data.vertices))
	carve1(bell_o, runes_cut)
	turn(g, "Y", 90 + 12, (0, 0, 0))
	settle(g)
	b = bell_o
	bpy.context.view_layer.update()
	mw = b.matrix_world
	pts = [mw @ v.co for v in b.data.vertices]
	xlip = min(p.x for p in pts)
	cuts = []
	for i in range(6):
		x = xlip + 0.02 + i * 0.05
		yy = 0.03 * math.sin(i * 1.7)
		zt = max((p.z for p in pts if abs(p.x - x) < 0.03 and abs(p.y - yy) < 0.04), default=0.5)
		cuts.append(B((0.06, 0.012, 0.06), (x, yy, zt), GROOVE_M(), bevel=0, rot=(0, 0, 30 * math.sin(i))))
	cuts.append(chip((xlip, -0.25, 0.45), (0.08, 0.08, 0.08), seed=5, m=BRONZE()))
	carve1(b, cuts)
	# clapper on the floor in front of the mouth
	rodm((xlip - 0.15, 0.32, 0.022), (xlip - 0.55, 0.42, 0.022), 0.022, IRD(), seg=8)
	sphere((xlip - 0.58, 0.43, 0.06), 0.06, IRD(), seg=12, rings=8)
	kit.ring(0.035, 0.01, (xlip - 0.13, 0.315, 0.035), IRD(), rot=(90, 0, 15), seg=10)
	# the snapped other half of the headstock
	o = made(lambda: (B((0.6, 0.15, 0.17), (0, 0, 0.085), WD("dark"), bevel=0.012), splinters((-0.3, 0, 0.085), (-1, 0, 0), n=5, r=0.07, m=WD("c")),
		B((0.035, 0.18, 0.19), (0.18, 0, 0.09), IRD(), bevel=0.004)))
	place(o, (0.8, -0.62, 0), (0, 0, 70))  # snapped half lies clear of the piece still on the crown
	for i, (x, y, s) in enumerate(((0.2, 0.5, 0.11), (-0.1, -0.5, 0.09), (0.9, 0.2, 0.08), (-0.6, -0.2, 0.07), (0.2, -0.85, 0.1), (1.0, 0.55, 0.06))):
		o = gem_at((x, y, 0.3), (s, s * 0.8, s * 0.55), GS("abc"[i % 3]), 70 + i, (J(20), J(20), J(180)))
		rest(o)


def _spear(x, y, z0, z1, broken=False):
	log((x, y, z0), (x, y, z1), 0.021, WD("b"), seg=8, rings=3, bend=0.01, ends=False)
	kit.cylinder(0.026, 0.05, (x, y, z0 + 0.02), IRD(), verts=8, bevel=0.003)
	if broken:
		splinters((x, y, z1), (0, 0, 1), n=4, r=0.021, m=WD("c"))
		return
	kit.cone(0.024, 0.014, 0.1, (x, y, z1 + 0.04), IRD(), verts=8, bevel=0.002)
	prism([(x, z1 + 0.06), (x + 0.038, z1 + 0.12), (x + 0.03, z1 + 0.22), (x, z1 + 0.33), (x - 0.03, z1 + 0.22), (x - 0.038, z1 + 0.12)], y - 0.006, y + 0.006, IRON("b"))
	B((0.008, 0.018, 0.24), (x, y, z1 + 0.18), IRD(), bevel=0)
	B((0.07, 0.012, 0.012), (x, y, z1 + 0.025), IRD(), bevel=0)


def rt_weapon_rack():
	BY = 0.1
	for s_ in (-1, 1):
		B((0.1, 0.08, 1.75), (s_ * 0.6, BY - 0.04, 0.875), WD("dark"), bevel=0.012)
	for z in (1.45, 0.95):
		B((1.26, 0.08, 0.1), (0, BY - 0.045, z), WD("b"), bevel=0.01)
		for s_ in (-1, 1):
			rivet((s_ * 0.6, BY - 0.088, z), IRD(), r=0.014)
	B((1.26, 0.24, 0.06), (0, BY - 0.13, 0.12), WD("b"), bevel=0.01)
	B((1.26, 0.03, 0.06), (0, BY - 0.24, 0.17), WD("dark"), bevel=0.006)
	sy = -0.01
	for x in (-0.42, -0.24, 0.05, 0.24):
		lathe([(0, 0.15), (0.032, 0.15), (0.036, 0.19), (0.028, 0.19), (0.024, 0.16), (0, 0.16)], (x, sy), IRD(), seg=12)
		B((0.075, 0.012, 0.03), (x, sy - 0.03, 1.45), IRD(), bevel=0.002)
		for s_ in (-1, 1):
			B((0.012, 0.05, 0.03), (x + s_ * 0.034, sy - 0.008, 1.45), IRD(), bevel=0.002)
	_spear(-0.42, sy, 0.16, 1.62)
	_spear(-0.24, sy, 0.16, 1.55)
	_spear(0.24, sy, 0.16, 1.08, broken=True)
	# poleaxe
	x = 0.05
	log((x, sy, 0.16), (x, sy, 1.62), 0.023, WD("b"), seg=8, rings=3, bend=0.01, ends=False)
	kit.cylinder(0.028, 0.05, (x, sy, 0.18), IRD(), verts=8, bevel=0.003)
	zc = 1.5
	prism([(x + 0.01, zc - 0.1), (x + 0.12, zc - 0.16), (x + 0.2, zc - 0.13), (x + 0.23, zc), (x + 0.2, zc + 0.13), (x + 0.12, zc + 0.15), (x + 0.01, zc + 0.08)],
		sy - 0.007, sy + 0.007, IRON("b"))
	prism([(x - 0.01, zc - 0.03), (x - 0.13, zc + 0.01), (x - 0.01, zc + 0.05)], sy - 0.006, sy + 0.006, IRD())
	kit.cone(0.024, 0.0, 0.16, (x, sy, 1.7), IRON("b"), verts=6, bevel=0)
	for s_ in (-1, 1):
		B((0.012, 0.022, 0.3), (x + s_ * 0.022, sy, 1.42), IRD(), bevel=0)
	for z in (1.36, 1.6):
		rivet((x, sy - 0.024, z), IRON("b"), r=0.008)
	kit.ring(0.026, 0.008, (x, sy, 0.8), LEATH("dark"), seg=10)
	kit.ring(0.026, 0.008, (x, sy, 0.84), LEATH("dark"), seg=10)
	# round shield on a peg of the middle rail
	kit.cylinder(0.02, 0.09, (0.44, -0.01, 1.42), WD("dark"), rot=(90, 0, 0), verts=8, bevel=0.003)
	tube([(0.44, -0.035, 1.43), (0.44, -0.03, 1.3), (0.44, -0.012, 1.17)], 0.007, 0.007, LEATH("dark"), seg=6)
	shield_round(0.44, 0.012, 0.95, 0.24)


def rt_water_cistern():
	R, N = 0.55, 12
	r = random.Random(4)
	for c, (z0, z1, off, dr) in enumerate(((0.0, 0.26, 0, 0.17), (0.255, 0.51, 0.5, 0.17), (0.505, 0.6, 0.0, 0.2))):
		for k in range(N):
			a = 2 * math.pi * (k + off) / N
			stone((2 * math.pi * R / N + 0.015, dr, z1 - z0), (math.cos(a) * R, math.sin(a) * R, (z0 + z1) / 2), tone=GS("abc"[r.randrange(3)]),
				rotz=math.degrees(a) + 90, bevel=0.02)
	disc(0.5, 0.02, 0.1, (0, 0), GS("dark"), seg=20, wob=0.02)
	for z in (0.18, 0.42):
		kit.ring(0.645, 0.016, (0, 0, z), IRD(), seg=40)
		for k in range(8):
			a = 2 * math.pi * k / 8 + 0.2
			rivet((math.cos(a) * 0.66, math.sin(a) * 0.66, z), IRON("b"), r=0.012)
	# carved plaque with water waves on the front
	pl = B((0.28, 0.06, 0.16), (0, -0.635, 0.36), GS("a"), bevel=0.01)
	cuts = []
	for z in (0.33, 0.38):
		cuts += groove_path([(-0.11 + i * 0.044, z + (0.015 if i % 2 else -0.015)) for i in range(6)], -0.665, 0.01, 0.009)
	carve1(pl, cuts)
	# spout
	sp = B((0.14, 0.24, 0.07), (0.0, -0.7, 0.57), GS("b"), bevel=0.012)
	carve1(sp, [top_cut((0, -0.8), (0, -0.6), 0.605, 0.05, 0.03)])
	# winch
	for s_ in (-1, 1):
		B((0.1, 0.1, 1.12), (s_ * 0.7, 0.0, 0.56), WD("dark"), bevel=0.012)
		B((0.06, 0.12, 0.12), (s_ * 0.645, 0.0, 0.3), IRD(), bevel=0.004)
		rivet((s_ * 0.7, -0.052, 0.3), IRON("b"), r=0.012)
	log((-0.78, 0, 1.02), (0.79, 0, 1.02), 0.05, WD("b"), seg=10, rings=2, bend=0.0)
	for i in range(7):
		kit.ring(0.058, 0.011, (-0.07 + i * 0.022, 0, 1.02), ROPE(), rot=(0, 90, 0), seg=14)
	B((0.03, 0.03, 0.22), (0.81, 0, 0.92), IRD(), bevel=0.003)
	rodm((0.8, 0, 0.82), (0.93, 0, 0.82), 0.012, IRD())
	kit.cylinder(0.02, 0.08, (0.9, 0, 0.82), WD("b"), rot=(0, 90, 0), verts=8, bevel=0.004)
	log((0.0, -0.05, 0.98), (0.0, -0.05, 0.42), 0.01, ROPE(), seg=6, rings=2, ends=False, bend=0.02)
	# the bucket, hanging inside
	lathe([(0, 0.2), (0.11, 0.2), (0.13, 0.38), (0.115, 0.38), (0.097, 0.215), (0, 0.215)], (0, -0.05), WD("b"), seg=14)
	for z in (0.24, 0.35):
		kit.ring(0.118 + (z - 0.2) * 0.1, 0.008, (0, -0.05, z), IRD(), seg=14)
	tube([(-0.13, -0.05, 0.37)] + [(-math.cos(t) * 0.13, -0.05, 0.37 + math.sin(t) * 0.06) for t in (0.5, 1.1, 1.57, 2.0, 2.6)] + [(0.13, -0.05, 0.37)], 0.007, 0.007, IRD())
	# the lid, slid half off

	def lid():
		Rl = 0.5
		for i in range(5):
			x = -Rl + Rl * 2 / 5 * (i + 0.5)
			L = 2 * math.sqrt(max(0.01, Rl * Rl - x * x))
			B((Rl * 2 / 5 - 0.008, L, 0.04), (x, 0, 0.02), WD("abc"[i % 3]), bevel=0.008)
		for y in (-0.22, 0.22):
			B((0.8, 0.07, 0.035), (0, y, 0.055), WD("dark"), bevel=0.006)
			for x in (-0.3, 0.0, 0.3):
				rivet((x, y, 0.073), IRD(), r=0.009)
		kit.ring(0.045, 0.009, (0, 0, 0.045), IRD(), rot=(90, 0, 0), seg=12)
		B((0.04, 0.03, 0.02), (0, 0, 0.045), IRD(), bevel=0.002)
	place(made(lid), (1.08, 0.72, 0.0), (0, 0, 20))  # pushed off, lying flat on the floor (clear of the rope)
	# ladle on a peg
	kit.cylinder(0.016, 0.1, (-0.7, -0.09, 0.8), WD("b"), rot=(90, 0, 0), verts=8, bevel=0.003)
	kit.ring(0.022, 0.006, (-0.7, -0.12, 0.79), CU(), rot=(90, 0, 0), seg=10)
	rodm((-0.7, -0.12, 0.77), (-0.7, -0.12, 0.48), 0.008, CU())
	lathe([(0, 0.4), (0.05, 0.41), (0.065, 0.47), (0.056, 0.47), (0.042, 0.42), (0, 0.415)], (-0.7, -0.12), CU(), seg=14)


def _lantern(x, y, zt):
	kit.ring(0.022, 0.006, (x, y, zt - 0.022), IRD(), rot=(90, 0, 0), seg=10)
	kit.cone(0.085, 0.02, 0.07, (x, y, zt - 0.075), IRD(), verts=4, rot=(0, 0, 45), bevel=0.003)
	B((0.13, 0.13, 0.015), (x, y, zt - 0.112), IRD(), bevel=0.003)
	for dx in (-0.058, 0.058):
		for dy in (-0.058, 0.058):
			B((0.016, 0.016, 0.2), (x + dx, y + dy, zt - 0.215), IRD(), bevel=0.002)
	B((0.106, 0.106, 0.19), (x, y, zt - 0.215), C((0.32, 0.34, 0.27), 0.12), bevel=0)
	B((0.11, 0.012, 0.012), (x, y - 0.06, zt - 0.215), IRD(), bevel=0)
	B((0.14, 0.14, 0.025), (x, y, zt - 0.322), IRD(), bevel=0.004)


def _key(ang):
	def k():
		kit.ring(0.022, 0.006, (0, 0, -0.022), IRD(), rot=(90, 0, 0), seg=10)
		rodm((0, 0, -0.04), (0, 0, -0.16), 0.006, IRD())
		B((0.03, 0.007, 0.035), (0.017, 0, -0.148), IRD(), bevel=0)
		kit.ring(0.009, 0.004, (0, 0, -0.05), IRD(), seg=8)
	return k


def rt_watch_hooks():
	BY = 0.06
	for i, z in enumerate((0.09, 0.25, 0.41)):
		B((1.0, 0.03, 0.155), (0, BY - 0.015, z), WD("abc"[i]), bevel=0.008)
	for x in (-0.44, 0.44):
		B((0.05, 0.012, 0.5), (x, BY - 0.035, 0.25), IRD(), bevel=0.003)
		for z in (0.07, 0.25, 0.43):
			rivet((x, BY - 0.042, z), IRON("b"), r=0.01)
	hooks = (-0.3, 0.0, 0.2, 0.37)
	for x in hooks:
		B((0.035, 0.008, 0.06), (x, BY - 0.032, 0.4), IRD(), bevel=0.002)
		rivet((x, BY - 0.037, 0.415), IRON("b"), r=0.007)
		tube([(x, BY - 0.03, 0.39), (x, -0.04, 0.39), (x, -0.075, 0.405), (x, -0.08, 0.44)], 0.008, 0.006, IRD())
	# signal horn on a strap
	hx = hooks[0]
	# 0.34 long (x -0.47 .. -0.13): 6 cm clear of the lantern; the wide end is really hollow
	pts = [(hx - 0.17 + 0.34 * t, -0.07, 0.25 - 0.08 * math.sin(math.pi * t) - 0.04 * t) for t in [i / 8 for i in range(9)]]
	rs = [0.014 + (0.06 - 0.014) * i / 8 for i in range(9)]
	hollow_tube(list(reversed(pts)), list(reversed(rs)), kit.mat("bone", -0.05, rough=0.8), wall=0.006, depth=4, seg=14)
	for i in (1, 4):
		p0, p1 = Vector(pts[i]), Vector(pts[i + 1])
		rr = rs[i] + (rs[i + 1] - rs[i]) * 0.35
		tube([tuple(p0.lerp(p1, 0.15)), tuple(p0.lerp(p1, 0.55))], rr + 0.004, rr + 0.006, CU(), seg=14)
	dm = (Vector(pts[-1]) - Vector(pts[-2])).normalized()
	rim = made(lambda: kit.ring(0.059, 0.007, (0, 0, 0), CU(), seg=18))
	Mr = Matrix.Translation(Vector(pts[-1])) @ dm.to_track_quat("Z", "Y").to_matrix().to_4x4()
	for o in rim:
		o.matrix_world = Mr @ o.matrix_world
	for i in (2, 6):
		tube([(hx, -0.075, 0.395), pts[i]], 0.006, 0.006, LEATH("dark"), seg=6)
	# lantern
	_lantern(hooks[1], -0.08, 0.445)
	# key ring with keys
	kx = hooks[2]
	kit.ring(0.05, 0.007, (kx, -0.08, 0.36), IRD(), rot=(90, 0, 0), seg=16)
	for i, ang in enumerate((-25, 5, 30)):
		a = math.radians(-90 + ang)
		place(made(_key(ang)), (kx + math.cos(a) * 0.05, -0.08, 0.36 + math.sin(a) * 0.05), (0, -ang, 0))
	# hand bell hung by its handle loop
	bx = hooks[3]
	kit.ring(0.02, 0.005, (bx, -0.08, 0.425), LEATH("dark"), rot=(90, 0, 0), seg=10)
	kit.cylinder(0.016, 0.08, (bx, -0.08, 0.37), WD("dark"), verts=8, bevel=0.003)
	lathe([(0, 0.335), (0.03, 0.33), (0.05, 0.28), (0.07, 0.235), (0.062, 0.235), (0.042, 0.28), (0.022, 0.32), (0, 0.322)], (bx, -0.08), BRONZE(), seg=16)
	kit.ring(0.068, 0.006, (bx, -0.08, 0.245), BRONZE(), seg=16)
	# spyglass on two cradle pegs
	for x in (-0.15, 0.15):
		kit.cylinder(0.012, 0.11, (x, BY - 0.085, 0.07), WD("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
		kit.cylinder(0.012, 0.03, (x, -0.06, 0.09), WD("dark"), verts=8, bevel=0.002)
	gy, gz = -0.06, 0.112
	kit.cylinder(0.03, 0.26, (-0.08, gy, gz), CU(), rot=(0, 90, 0), verts=14, bevel=0.003)
	kit.cylinder(0.025, 0.18, (0.13, gy, gz), CU("c"), rot=(0, 90, 0), verts=14, bevel=0.003)
	kit.cylinder(0.02, 0.12, (0.27, gy, gz), CU(), rot=(0, 90, 0), verts=12, bevel=0.003)
	kit.cylinder(0.034, 0.1, (-0.08, gy, gz), LEATH("b"), rot=(0, 90, 0), verts=14, bevel=0.003)
	for x in (-0.21, 0.04, 0.22):
		kit.ring(0.03 if x < 0 else 0.025, 0.006, (x, gy, gz), CU("dark"), rot=(0, 90, 0), seg=14)
	kit.cylinder(0.022, 0.006, (-0.212, gy, gz), C((0.15, 0.2, 0.2), 0.1), rot=(0, 90, 0), verts=14, bevel=0)


def rt_watch_roster_slab():
	BY = 0.06
	slab = B((0.8, 0.12, 0.99), (0, BY - 0.06, 0.515), GS("b"), bevel=0.015)
	B((0.86, 0.13, 0.08), (0, BY - 0.065, 1.035), GS("a"), bevel=0.012)
	B((0.84, 0.13, 0.06), (0, BY - 0.065, 0.03), GS("c"), bevel=0.012)
	fy = BY - 0.12
	cuts = [chip((0.4, fy, 0.95), (0.06, 0.06, 0.06), seed=2), chip((-0.4, fy, 0.12), (0.05, 0.05, 0.05), seed=3)]
	cuts += groove_path([(-0.34, 0.1), (0.34, 0.1), (0.34, 0.95), (-0.34, 0.95)], fy, 0.014, 0.011, closed=True)
	# tower sign: crenellated tower with a door
	cuts += groove_path([(-0.07, 0.72), (0.07, 0.72), (0.07, 0.86), (0.045, 0.86), (0.045, 0.83), (0.015, 0.83), (0.015, 0.86), (-0.015, 0.86), (-0.015, 0.83),
		(-0.045, 0.83), (-0.045, 0.86), (-0.07, 0.86)], fy, 0.011, 0.01, closed=True)
	cuts += groove_path([(-0.018, 0.722), (-0.018, 0.76), (0, 0.775), (0.018, 0.76), (0.018, 0.722)], fy, 0.009, 0.01)
	for s_ in (-1, 1):
		cuts += groove((s_ * 0.12, 0.79), (s_ * 0.28, 0.79), fy, 0.01, 0.009)
	cuts += groove((-0.3, 0.68), (0.3, 0.68), fy, 0.01, 0.009)
	r = random.Random(6)
	for i in range(5):
		z = 0.61 - i * 0.1
		cuts += rune_row(-0.29, 0.02, z, fy, h=0.06, w=0.009, depth=0.009, seed=40 + i)
		n = r.randint(2, 7)
		for k in range(n):
			x = 0.08 + k * 0.03 + (0.02 if k >= 5 else 0)
			cuts += groove((x, z - 0.03), (x, z + 0.03), fy, 0.008, 0.009)
		if n >= 5:
			cuts += groove((0.07, z - 0.025), (0.21, z + 0.025), fy, 0.008, 0.009)
	carve1(slab, cuts)
	# iron candle bracket on the right side
	B((0.025, 0.07, 0.16), (0.41, BY - 0.07, 0.7), IRD(), bevel=0.003)
	for z in (0.65, 0.75):
		rivet((0.424, BY - 0.07, z), IRON("b"), r=0.009)
	tube([(0.42, BY - 0.07, 0.68), (0.48, BY - 0.09, 0.68), (0.52, BY - 0.12, 0.7)], 0.01, 0.009, IRD())
	kit.cylinder(0.05, 0.012, (0.53, BY - 0.12, 0.71), IRD(), verts=12, bevel=0.003)
	kit.ring(0.05, 0.006, (0.53, BY - 0.12, 0.716), IRON("b"), seg=12)
	kit.cylinder(0.022, 0.07, (0.53, BY - 0.12, 0.75), C((0.86, 0.79, 0.6), 0.85), verts=10, bevel=0.005)
	kit.cylinder(0.003, 0.012, (0.53, BY - 0.12, 0.79), INK(), verts=5, bevel=0)
	# stylus on a chain from a ring bolt on the left side
	B((0.025, 0.05, 0.05), (-0.41, BY - 0.07, 0.6), IRD(), bevel=0.003)
	kit.ring(0.02, 0.005, (-0.43, BY - 0.07, 0.575), IRD(), rot=(90, 0, 0), seg=10)
	chain((-0.43, BY - 0.07, 0.56), (-0.43, BY - 0.07, 0.36), link=0.016, wire=0.004)
	rodm((-0.43, BY - 0.07, 0.36), (-0.43, BY - 0.07, 0.22), 0.007, IRON("b"))
	kit.cone(0.007, 0.0, 0.03, (-0.43, BY - 0.07, 0.205), IRON("b"), verts=6, rot=(180, 0, 0), bevel=0)


def rt_arrow_crate_spill(empty=False):
	"""Bolt crate on its side (LOOT: 10 bolt_stone: 4 inside, 6 spilled). empty=True: the same crate, bolts gone."""
	L, Hc, Dc = 0.52, 0.45, 0.35
	for i in range(3):
		B((L - 0.012, Dc / 3 - 0.006, 0.025), (0, -Dc / 2 + Dc / 3 * (i + 0.5), 0.0125), WD("abc"[i]), bevel=0.006)
	tops = []
	ln = L * 0.55
	for i in range(3):
		lt = L - 0.012 if i != 1 else ln
		x = 0.0 if i != 1 else L / 2 - 0.006 - lt / 2
		tops.append(B((lt, Dc / 3 - 0.006, 0.025), (x, -Dc / 2 + Dc / 3 * (i + 0.5), Hc - 0.0125), WD("abc"[(i + 1) % 3]), bevel=0.006))
	splinters((L / 2 - 0.006 - ln, -Dc / 2 + Dc / 3 * 1.5, Hc - 0.0125), (-1, 0, 0), n=4, r=0.05, m=WD("c"))
	carve1(tops[2], [top_cut((-0.18, Dc / 2 - 0.09), (-0.02, Dc / 2 - 0.03), Hc), top_cut((-0.18, Dc / 2 - 0.03), (-0.02, Dc / 2 - 0.09), Hc)])
	for i in range(4):
		B((L - 0.012, 0.025, Hc / 4 - 0.006), (0, Dc / 2 - 0.0125, 0.02 + (Hc - 0.04) / 4 * (i + 0.5)), WD("abc"[i % 3]), bevel=0.006)
	for s_ in (-1, 1):
		for i in range(3):
			B((0.025, Dc / 3 - 0.006, Hc - 0.01), (s_ * (L / 2 - 0.0125), -Dc / 2 + Dc / 3 * (i + 0.5), Hc / 2), WD("abc"[(i + 2) % 3]), bevel=0.006)
		kit.ring(0.06, 0.012, (s_ * (L / 2 + 0.002), 0.0, Hc / 2), ROPE(), rot=(0, 90, 0), seg=14)
		for z in (0.0, Hc):
			for y in (-Dc / 2, Dc / 2):
				B((0.06, 0.06, 0.012), (s_ * (L / 2 - 0.02), y + (0.02 if y < 0 else -0.02), z + (0.008 if z == 0 else -0.008)), IRD(), bevel=0.002)
	for k in range(4):
		B((0.02, 0.016, 0.06), (k * (L - 0.12) / 3 - (L - 0.12) / 2, -Dc / 2 + 0.005, 0.06 + (Hc - 0.12) * (k % 2)), IRD(), bevel=0.002)
	if not empty:
		for k, y in enumerate((-0.11, -0.04, 0.03, 0.1)):  # 4 still inside, lying on the crate's side wall
			lying_bolt(-0.02 + 0.02 * (k % 2), y, 180 if k % 2 else 0, z=0.025, head=SST(), roll=k * 37)
		for k, (cx, cy, ang) in enumerate(((0.0, -0.3, -5), (0.08, -0.42, 185), (-0.33, -0.55, 70), (0.05, -0.56, -12), (0.42, -0.7, 220), (-0.02, -0.72, 8))):
			lying_bolt(cx, cy, ang, head=SST(), roll=k * 53)

	def lid():
		for i in range(3):
			B((L, Dc / 3 - 0.006, 0.022), (0, -Dc / 2 + Dc / 3 * (i + 0.5), 0.011), WD("abc"[i]), bevel=0.005)
		for x in (-0.16, 0.16):
			B((0.07, Dc - 0.02, 0.022), (x, 0, 0.032), WD("dark"), bevel=0.004)
			rivet((x, 0.1, 0.044), IRD(), r=0.008)
			rivet((x, -0.1, 0.044), IRD(), r=0.008)
	place(made(lid), (0.92, -0.3, 0), (0, 0, 75))
	floor_cut()


def rt_map_tube_rack():
	BY = 0.12
	W, Hh, Dd = 0.9, 0.78, 0.24
	B((W - 0.02, 0.02, Hh), (0, BY - 0.01, Hh / 2), WD("dark"), bevel=0.005)
	for s_ in (-1, 1):
		B((0.03, Dd, Hh), (s_ * (W / 2 - 0.015), BY - Dd / 2, Hh / 2), WD("b"), bevel=0.008)
	shelves = (0.03, 0.27, 0.51, 0.75)
	for z in shelves:
		B((W - 0.05, Dd - 0.02, 0.025), (0, BY - Dd / 2 - 0.005, z), WD("abc"[int(z * 10) % 3]), bevel=0.006)
	B((W + 0.06, Dd + 0.04, 0.045), (0, BY - Dd / 2 - 0.02, Hh + 0.0), WD("dark"), bevel=0.01)
	B((W + 0.02, 0.03, 0.03), (0, BY - Dd - 0.03, Hh - 0.035), WD("b"), bevel=0.006)
	cw = (W - 0.06 - 3 * 0.02) / 4
	xs = [-W / 2 + 0.03 + cw * (i + 0.5) + 0.02 * i for i in range(4)]
	for z0, z1 in zip(shelves, shelves[1:]):
		for i in range(3):
			B((0.02, Dd - 0.025, z1 - z0 - 0.02), ((xs[i] + xs[i + 1]) / 2, BY - Dd / 2 - 0.005, (z0 + z1) / 2), WD("b"), bevel=0.004)
	fy = BY - Dd - 0.004
	r = random.Random(9)
	kinds = ["tube3", "roll4", "tube2", "roll3", "empty", "roll4", "tube3", "roll2", "tube2", "roll3", "tube1", "roll4"]
	for row, z0 in enumerate(shelves[:3]):
		for col, x in enumerate(xs):
			B((0.08, 0.006, 0.024), (x, fy - 0.0005, z0), CU(), bevel=0.001)
			for s_ in (-1, 1):
				rivet((x + s_ * 0.03, fy - 0.003, z0), CU("dark"), r=0.006)
			k = kinds[row * 4 + col]
			zt = z0 + 0.0125
			if k == "empty":
				continue
			tubes = k.startswith("tube")
			n = int(k[-1])
			rr = 0.038 if tubes else 0.027
			spots = {1: [(0, 0)], 2: [(-0.5, 0), (0.5, 0)], 3: [(-0.5, 0), (0.5, 0), (0, 1)], 4: [(-1.5, 0), (-0.5, 0), (0.5, 0), (1.5, 0)]}[n]
			if not tubes and n == 4:
				spots = [(-1, 0), (0, 0), (1, 0), (-0.5, 1)]
			for (sx, sz) in spots:
				cx = x + sx * rr * 2.02
				cz = zt + rr - 0.002 + sz * rr * 1.72
				ln = Dd - 0.05 + r.uniform(-0.02, 0.02)
				cy = BY - 0.03 - ln / 2
				if tubes:
					kit.cylinder(rr, ln, (cx, cy, cz), LEATH("abc"[r.randrange(3)]), rot=(90, 0, 0), verts=12, bevel=0.003)
					kit.cylinder(rr + 0.004, 0.035, (cx, cy - ln / 2 + 0.012, cz), CU(), rot=(90, 0, 0), verts=12, bevel=0.003)
					kit.ring(rr + 0.002, 0.005, (cx, cy + 0.02, cz), LEATH("dark"), rot=(90, 0, 0), seg=12)
				else:
					kit.cylinder(rr, ln, (cx, cy, cz), PARCH(), rot=(90, 0, 0), verts=12, bevel=0.003)
					kit.cylinder(rr * 0.45, 0.006, (cx, cy - ln / 2 - 0.001, cz), C((0.5, 0.42, 0.28), 0.95), rot=(90, 0, 0), verts=10, bevel=0)
					kit.ring(rr + 0.002, 0.005, (cx, cy + r.uniform(-0.03, 0.03), cz), RED_INK(), rot=(90, 0, 0), seg=12)


# ================= FALLEN OUTPOST =================
def ro_stake_bundle():
	for x in (-0.5, 0.45):
		log((x, -0.5, 0.07), (x, 0.5, 0.07), 0.07, BK(), seg=9, rings=2, bend=0.02, end_m=LE())
	cz = 0.14 + 0.162
	r = random.Random(2)
	spots = [(0.0, 0.0)] + [(math.cos(a) * 0.107, math.sin(a) * 0.107) for a in [2 * math.pi * k / 6 + 0.5 for k in range(6)]]
	for (dy, dz) in spots:
		x0, x1 = -r.uniform(0.8, 0.95), r.uniform(0.85, 1.0)
		stake((x0, dy, cz + dz), (x1, dy, cz + dz), 0.055, tip=0.2)
	for x in (-0.3, 0.25):
		for k in range(2):
			kit.ring(0.164, 0.014, (x + k * 0.032, 0, cz), ROPE(), rot=(0, 90, 0), seg=24)
		kit.ring(0.03, 0.01, (x + 0.016, -0.12, cz - 0.12), ROPE(), rot=(0, 0, 0), seg=10)
	stake((-0.85, 0.38, 0.14 + 0.05), (0.95, 0.4, 0.14 + 0.05), 0.05, tip=0.18)
	stake((-0.6, -0.62, 0.05), (0.75, -0.8, 0.05), 0.05, tip=0.18)
	# maul lying on the ground
	log((-0.6, 0.85, 0.075), (-0.6, 0.62, 0.075), 0.075, BK(), seg=10, rings=2, bend=0, end_m=LE())
	for y in (0.83, 0.64):
		kit.ring(0.077, 0.01, (-0.6, y, 0.075), IRD(), rot=(90, 0, 0), seg=14)
	log((-0.6, 0.735, 0.075), (-1.1, 0.68, 0.03), 0.022, PL(), seg=6, rings=2, ends=False, bend=0)
	# stump with a hatchet in it, and chips around the points
	log((1.35, -0.1, 0.0), (1.35, -0.1, 0.32), 0.18, BK(), seg=11, rings=2, bend=0.02, end_m=LE())
	g = made(lambda: (prism([(-0.02, -0.04), (0.1, -0.06), (0.13, 0.0), (0.1, 0.07), (-0.02, 0.04)], -0.007, 0.007, IRON("b")),
		kit.cylinder(0.022, 0.05, (-0.03, 0, 0), IRD(), rot=(90, 0, 0), verts=8, bevel=0.003),
		log((-0.03, 0, 0.0), (-0.42, 0, 0.0), 0.018, PL(), seg=6, rings=2, ends=False, bend=0)))
	place(g, (1.33, -0.1, 0.33), (0, 70, 20))
	for i in range(12):
		a = r.uniform(0, 6.28)
		d = r.uniform(0.15, 0.45)
		B((r.uniform(0.04, 0.07), r.uniform(0.02, 0.035), 0.008), (1.1 + math.cos(a) * d * 0.6, -0.1 + math.sin(a) * d, 0.004), LE(), bevel=0.002, rot=(J(6), J(6), r.uniform(0, 180)))
	floor_cut()


def ro_gate_wing_broken():
	def gate():
		xs = [-0.6 + 0.2 * i for i in range(7)]
		for i, x in enumerate(xs):
			if i == 2:
				log((x, 0, 0), (x, 0, 1.12), 0.088, BK(), seg=8, rings=3, bend=0.02, end_m=LE())
				splinters((x, 0, 1.12), (0, 0, 1), n=5, r=0.088)
			elif i == 5:
				log((x, 0, 0), (x, 0, 1.32), 0.088, BK(), seg=8, rings=3, bend=0.02, end_m=LE())
				splinters((x, 0, 1.32), (0, 0, 1), n=5, r=0.088)
			else:
				stake((x, 0, 0), (x, 0, 1.72 + J(0.06)), 0.088, tip=0.22)
		for z in (0.35, 1.05):
			log((-0.74, 0.12, z), (0.74, 0.12, z), 0.065, BK(), seg=8, rings=2, bend=0.02, end_m=LE())
			for x in xs:
				rivet((x, -0.088, z), LE(), r=0.017)
		log((-0.58, 0.12, 0.42), (0.58, 0.12, 0.98), 0.05, BK(), seg=8, rings=2, bend=0.02, end_m=LE())
		for z in (0.35, 1.05):
			B((0.95, 0.012, 0.05), (-0.3, 0.188, z), IRD(), bevel=0.003)
			for x in (-0.65, -0.4, -0.15, 0.1):
				rivet((x, 0.195, z), IRON("b"), r=0.01)
			kit.ring(0.035, 0.011, (-0.8, 0.165, z), IRD(), seg=12)
	g = made(gate)
	turn(g, "X", 78, (0, 0, 0))
	settle(g)
	Y = -1.25
	pts = [o.matrix_world @ v.co for o in g if o.type == "MESH" for v in o.data.vertices]
	under = min((p.z for p in pts if abs(p.y - Y) < 0.05 and -0.7 < p.x < 0.7), default=0.25)
	R = min(0.2, max(0.1, (under + 0.012) / 2))  # the fallen hinge post is just thick enough to hold the gate up
	log((-0.95, Y, R), (0.95, Y, R), R, BK(), seg=11, rings=3, bend=0.0, end_m=LE())
	for x in (-0.85, -0.55):
		B((0.06, 0.29, 0.29), (x, Y, R), IRD(), bevel=0.004)
		rodm((x, Y - 0.16, R + 0.02), (x, Y - 0.16, R + 0.13), 0.014, IRD())
	stake((1.1, -0.35, 0.06), (0.75, -0.8, 0.06), 0.07, tip=0.2)
	splinters((1.1, -0.35, 0.06), (0.62, 0.78, 0), n=4, r=0.07)
	floor_cut()


def ro_supply_cart():
	R = 0.42

	def cart():
		B((1.18, 0.1, 0.1), (0, 0, R), PL(), bevel=0.01)
		for s_ in (-1, 1):
			kit.cylinder(0.03, 0.12, (s_ * 0.62, 0, R), IRD(), rot=(0, 90, 0), verts=8, bevel=0.003)
		for s_ in (-1, 1):
			B((0.08, 1.3, 0.08), (s_ * 0.42, 0.07, R + 0.09), PL(), bevel=0.01)
			for y in (-0.05, 0.05):
				B((0.03, 0.03, 0.18), (s_ * 0.42, y, R + 0.02), IRD(), bevel=0.002)
		for i in range(8):
			B((0.92, 0.15, 0.03), (0, -0.5 + i * 0.16, R + 0.145), PL(), bevel=0.006)
		for s_ in (-1, 1):
			for k in range(2):
				B((0.03, 1.28, 0.13), (s_ * 0.455, 0.07, R + 0.24 + k * 0.145), PL(), bevel=0.006)
			for y in (-0.55, 0.07, 0.69):
				B((0.05, 0.05, 0.38), (s_ * 0.49, y, R + 0.3), PL(), bevel=0.006)
				kit.cylinder(0.032, 0.03, (s_ * 0.49, y, R + 0.5), IRD(), verts=8, bevel=0.003)
		for y in (-0.57, 0.71):
			for k in range(2):
				B((0.88, 0.03, 0.13), (0, y, R + 0.24 + k * 0.145), PL(), bevel=0.006)
		for s_ in (-1, 1):
			log((s_ * 0.36, -0.5, R + 0.09), (s_ * 0.33, -1.75, R + 0.09), 0.04, BK(), seg=8, rings=3, bend=0.02, end_m=LE())
		log((-0.36, -1.5, R + 0.09), (0.36, -1.5, R + 0.09), 0.03, BK(), seg=8, rings=2, bend=0.0, end_m=LE())
		keg(0.15, 0.3, R + 0.16, r=0.16, h=0.38)
		for z in (R + 0.3,):
			log((0.15, 0.3 + 0.17, z), (0.45, 0.69, z + 0.05), 0.012, ROPE(), seg=6, rings=1, ends=False, bend=0)
			log((0.15 + 0.165, 0.3, z), (0.47, 0.07, z + 0.05), 0.012, ROPE(), seg=6, rings=1, ends=False, bend=0)
		kit.ring(0.172, 0.012, (0.15, 0.3, R + 0.3), ROPE(), seg=18)
		place(made(lambda: wheel(R, broken=())), (-0.58, 0, R))
	g = made(cart)
	# lost its right wheel: rolls onto the right axle stub, then tips forward until the right shaft tip meets the ground
	piv = Vector((-0.58, 0, 0))
	turn(g, "Y", 17, piv)
	tip = Matrix.Translation(piv) @ Matrix.Rotation(math.radians(17), 4, "Y") @ Matrix.Translation(-piv) @ Vector((0.33, -1.75, R + 0.09))
	turn(g, "X", math.degrees(math.atan2(tip.z - 0.04, -tip.y)), (0, 0, 0))
	settle(g)
	gw = made(lambda: wheel(R, broken=(1, 2)))
	turn(gw, "Y", 90, (0, 0, 0))
	place(gw, (1.15, 0.45, 0))
	settle(gw)
	# empty crate slid off the back
	g = made(lambda: (B((0.46, 0.36, 0.03), (0, 0, 0.02), PL(), bevel=0.006),
		[B((0.46, 0.025, 0.12), (0, s_ * 0.168, 0.06 + 0.15 * k + 0.02), PL(), bevel=0.006) for s_ in (-1, 1) for k in range(2)],
		[B((0.025, 0.31, 0.12), (s_ * 0.218, 0, 0.06 + 0.15 * k + 0.02), PL(), bevel=0.006) for s_ in (-1, 1) for k in range(2)],
		[B((0.045, 0.045, 0.32), (cx * 0.21, cy * 0.16, 0.16), PL(), bevel=0.006) for cx in (-1, 1) for cy in (-1, 1)]))
	place(g, (-0.2, 1.25, 0), (0, 0, 20))
	floor_cut()


def ro_camp_cookery():
	r = random.Random(3)
	for k in range(11):
		a = 2 * math.pi * k / 11
		s = r.uniform(0.13, 0.18)
		o = gem_at((math.cos(a) * 0.4, math.sin(a) * 0.4, 0.2), (s, s * 0.85, s * 0.6), SST(), 20 + k, (J(10), J(10), math.degrees(a)))
		rest(o, 0.0)
	disc(0.33, 0.0, 0.012, (0, 0), CHAR(), seg=18, wob=0.08)
	for k in range(4):
		a = 2 * math.pi * k / 4 + 0.3
		c, s = math.cos(a), math.sin(a)
		log((c * 0.52, s * 0.52, 0.05), (c * 0.2, s * 0.2, 0.05), 0.045, BK(), seg=8, rings=2, bend=0.02, end_m=LE())
		log((c * 0.215, s * 0.215, 0.05), (c * 0.05, s * 0.05, 0.04), 0.042, CHAR(), seg=8, rings=2, bend=0.03, ends=False, r1=0.03)
	for i in range(12):
		a, d = r.uniform(0, 6.28), r.uniform(0.0, 0.2)
		s = r.uniform(0.03, 0.06)
		o = gem_at((math.cos(a) * d, math.sin(a) * d, 0.0), (s, s * 0.8, s * 0.55), COAL(), 50 + i, (J(30), J(30), J(180)))
		rest(o, 0.006)
	# iron tripod with chain and pot
	apex = Vector((0, 0, 1.25))
	for k in range(3):
		a = math.radians(90 + 120 * k)
		foot = Vector((math.cos(a) * 0.68, math.sin(a) * 0.68, 0.0))
		rodm(tuple(foot), tuple(apex + (foot - apex).normalized() * -0.03), 0.017, IRD(), seg=6)
		B((0.06, 0.06, 0.012), tuple(foot + Vector((0, 0, 0.006))), IRD(), bevel=0.002)
	kit.ring(0.04, 0.012, tuple(apex), IRD(), seg=12)
	pz = 0.36
	chain((0, 0, 1.22), (0, 0, pz + 0.24 + 0.2), link=0.024, wire=0.006)
	lathe([(0, pz), (0.12, pz), (0.19, pz + 0.07), (0.21, pz + 0.16), (0.19, pz + 0.24), (0.175, pz + 0.24), (0.192, pz + 0.16), (0.172, pz + 0.075), (0.11, pz + 0.018), (0, pz + 0.018)],
		(0, 0), IRD(), seg=20)
	kit.ring(0.19, 0.012, (0, 0, pz + 0.24), IRON("b"), seg=20)
	for s_ in (-1, 1):
		kit.ring(0.022, 0.007, (s_ * 0.2, 0, pz + 0.235), IRD(), rot=(90, 0, 0), seg=10)
	tube([(math.cos(t) * 0.2, 0, pz + 0.24 + math.sin(t) * 0.2) for t in [i * math.pi / 10 for i in range(11)]], 0.008, 0.008, IRD())
	for k in range(3):
		kit.cone(0.04, 0.0, 0.06, (math.cos(k * 2.1) * 0.08, math.sin(k * 2.1) * 0.08, pz - 0.02), IRD(), verts=6, rot=(180, 0, 0), bevel=0)
	# spit on two forked sticks
	for s_ in (-1, 1):
		x = s_ * 0.62
		log((x, -0.45, 0.0), (x, -0.45, 0.48), 0.028, BK(), seg=7, rings=2, bend=0.03, end_m=LE())
		log((x, -0.45, 0.46), (x - 0.06, -0.45, 0.6), 0.018, BK(), seg=6, rings=1, bend=0, ends=False)
		log((x, -0.45, 0.46), (x + 0.06, -0.45, 0.6), 0.018, BK(), seg=6, rings=1, bend=0, ends=False)
	rodm((-0.78, -0.45, 0.5), (0.72, -0.45, 0.5), 0.012, IRD())
	rodm((-0.78, -0.45, 0.5), (-0.78, -0.45, 0.38), 0.01, IRD())
	rodm((-0.78, -0.45, 0.38), (-0.86, -0.45, 0.38), 0.01, IRD())
	kit.cylinder(0.016, 0.07, (-0.88, -0.45, 0.38), PL(), rot=(0, 90, 0), verts=8, bevel=0.003)
	# stump table with stacked bowls, ladle and knife
	log((0.95, 0.5, 0.0), (0.95, 0.5, 0.42), 0.2, BK(), seg=11, rings=2, bend=0.02, end_m=LE())
	for i in range(3):
		z = 0.43 + i * 0.022
		lathe([(0, z), (0.05, z), (0.1, z + 0.05), (0.093, z + 0.052), (0.045, z + 0.012), (0, z + 0.012)], (0.98, 0.45), PL(), seg=16)
	log((0.85, 0.62, 0.435), (0.75, 0.38, 0.435), 0.01, PL(), seg=6, rings=1, ends=False, bend=0)
	lathe([(0, 0.425), (0.03, 0.428), (0.04, 0.455), (0.034, 0.455), (0.025, 0.433), (0, 0.432)], (0.73, 0.34), PL(), seg=12)
	g = made(lambda: (prism([(0.0, 0.0), (0.14, -0.012), (0.12, 0.014), (0.0, 0.012)], 0.0, 0.005, IRON("b"), axis="z"),
		B((0.08, 0.022, 0.018), (-0.04, 0.0, 0.009), PL(), bevel=0.004)))
	place(g, (1.0, 0.62, 0.42), (0, 0, 200))
	# log seat
	log((-1.0, 0.25, 0.14), (-0.85, 0.95, 0.14), 0.14, BK(), seg=11, rings=3, bend=0.02, end_m=LE())
	floor_cut()


def ro_duty_board():
	BY = 0.08
	for s_ in (-1, 1):
		B((0.12, 0.08, 2.0), (s_ * 0.62, BY - 0.04, 1.0), BK(), bevel=0.012)
	for i in range(5):
		B((1.14, 0.03, 0.175), (0, BY - 0.025, 0.78 + i * 0.18), PL(), bevel=0.006)
	B((1.2, 0.05, 0.05), (0, BY - 0.06, 0.66), PL(), bevel=0.006)

	def roof():
		B((1.46, 0.42, 0.025), (0, -0.17, 0.0), PL(), bevel=0.004)
		for row in range(4):
			y = -0.32 + row * 0.1
			z = 0.022 + row * 0.014
			off = 0.08 if row % 2 else 0.0
			x = -0.73 + off
			while x < 0.72:
				w = 0.15 + J(0.02)
				B((min(w, 0.73 - x) - 0.008, 0.15, 0.012), (x + min(w, 0.73 - x) / 2, y, z), SH(), bevel=0.002, rot=(0, 0, J(2)))
				x += w
		B((1.5, 0.05, 0.04), (0, 0.02, 0.07), PL(), bevel=0.004)
	place(made(roof), (0, BY - 0.04, 2.0), (25, 0, 0))
	for s_ in (-1, 1):
		B((0.05, 0.05, 0.36), (s_ * 0.62, BY - 0.2, 1.82), PL(), bevel=0.005, rot=(-50, 0, 0))
	# pinned notices (torn outlines, inked lines, wooden pins)
	front = BY - 0.04
	notes = [(-0.36, 1.3, 0.26, 0.32, 3), (-0.04, 1.36, 0.22, 0.26, -4), (0.3, 1.28, 0.28, 0.34, 2), (-0.2, 0.95, 0.2, 0.22, 5)]
	r = random.Random(4)
	for (x, z, w, h, tilt) in notes:
		pts = [(-w / 2, h / 2), (w / 2, h / 2), (w / 2, -h / 2 + 0.05)]
		for k in range(6):
			pts.append((w / 2 - w * (k + 1) / 7, -h / 2 + r.uniform(0.0, 0.04)))
		pts.append((-w / 2, -h / 2 + 0.02))

		def note(pts=pts, w=w, h=h):
			prism(pts, -0.004, 0.0015, PARCH())
			for k in range(int(h / 0.04) - 1):
				ln = w * r.uniform(0.5, 0.8)
				B((ln, 0.002, 0.006), (-w / 2 + 0.025 + ln / 2, -0.0045, h / 2 - 0.05 - k * 0.035), INK(), bevel=0)
			rivet((0, -0.006, h / 2 - 0.02), LE(), r=0.012)
		place(made(note), (x, front, z), (0, tilt, 0))
	# carved duty tally plank
	tp = B((0.46, 0.03, 0.13), (0.28, front - 0.012, 0.92), PL(), bevel=0.006)
	cuts = []
	for k in range(13):
		x = 0.09 + k * 0.026 + (k // 5) * 0.012
		cuts += groove((x, 0.88), (x, 0.96), front - 0.027, 0.008, 0.008)
	for k in range(2):
		x0 = 0.09 + k * 5 * 0.026 + k * 0.012
		cuts += groove((x0 - 0.01, 0.89), (x0 + 0.115, 0.95), front - 0.027, 0.008, 0.008)
	carve1(tp, cuts)
	for x in (0.08, 0.48):
		rivet((x, front - 0.028, 0.92), LE(), r=0.012)
	# peg box on the ledge
	g = made(lambda: (B((0.2, 0.1, 0.012), (0, 0, 0.006), PL(), bevel=0.002),
		[B((0.2, 0.012, 0.07), (0, s_ * 0.044, 0.035), PL(), bevel=0.002) for s_ in (-1, 1)],
		[B((0.012, 0.08, 0.07), (s_ * 0.094, 0, 0.035), PL(), bevel=0.002) for s_ in (-1, 1)],
		[rodm((J(0.06), J(0.025), 0.01), (J(0.07), J(0.03), 0.1), 0.006, LE()) for _ in range(7)]))
	place(g, (-0.3, BY - 0.06, 0.685))


def ro_armour_bench():
	W, D, H = 1.5, 0.5, 0.68
	for i in range(2):
		B((W, D / 2 - 0.006, 0.09), (0, -D / 4 + D / 2 * i, H - 0.045), PL(), bevel=0.012)
	for x in (-0.6, 0.6):
		for y in (-0.16, 0.16):
			log((x * 1.05, y * 1.25, 0.0), (x, y, H - 0.08), 0.045, BK(), seg=7, rings=2, bend=0.02, end_m=LE())
		log((x * 1.03, -0.19, 0.22), (x * 1.03, 0.19, 0.22), 0.03, BK(), seg=7, rings=1, bend=0, end_m=LE())
	log((-0.62, 0, 0.22), (0.62, 0, 0.22), 0.035, BK(), seg=7, rings=2, bend=0.02, end_m=LE())
	for x in (-0.6, 0.6):
		for y in (-0.16, 0.16):
			rivet((x, y, H + 0.001), LE(), r=0.02)
	# anvil stake set in a block at the right end
	B((0.26, 0.2, 0.08), (0.52, 0.02, H + 0.04), LE(), bevel=0.012)
	g = made(lambda: prism([(-0.09, 0.0), (0.07, 0.0), (0.07, 0.05), (0.1, 0.07), (0.1, 0.11), (0.03, 0.12), (-0.06, 0.115), (-0.17, 0.1), (-0.06, 0.08), (-0.05, 0.05)],
		-0.045, 0.045, IRD(), axis="y"))
	place(g, (0.53, 0.02, H + 0.075))
	# helmet on a stake at the left end, a patch plate half riveted
	hx = -0.5
	hz = H + 0.27
	log((hx, 0.05, H - 0.02), (hx, 0.05, hz + 0.19), 0.032, BK(), seg=7, rings=2, bend=0, end_m=LE())
	lathe([(0, hz + 0.2), (0.06, hz + 0.19), (0.11, hz + 0.15), (0.14, hz + 0.08), (0.15, hz), (0.138, hz), (0.128, hz + 0.08), (0.1, hz + 0.14),
		(0.055, hz + 0.177), (0, hz + 0.187)], (hx, 0.05), IRD(), seg=22)
	kit.ring(0.153, 0.013, (hx, 0.05, hz + 0.022), IRON("b"), seg=22)
	B((0.022, 0.2, 0.03), (hx, 0.05, hz + 0.192), IRON("b"), bevel=0.006)
	B((0.032, 0.014, 0.12), (hx, 0.05 - 0.16, hz - 0.03), IRON("b"), bevel=0.003)
	for k in range(10):
		a = 2 * math.pi * k / 10
		rivet((hx + math.cos(a) * 0.165, 0.05 + math.sin(a) * 0.165, hz + 0.022), IRON("c"), r=0.009)
	B((0.012, 0.1, 0.07), (hx + 0.137, 0.02, hz + 0.08), IRON("c"), bevel=0.003, rot=(0, -22, 0))
	rivet((hx + 0.142, -0.015, hz + 0.08), IRON("b"), r=0.009)
	rivet((hx + 0.142, 0.055, hz + 0.08), IRON("b"), r=0.009)
	# tools: rivet hammer, tongs, punch, rivet tin, whetstone, straps
	log((-0.15, -0.12, H + 0.018), (0.12, -0.17, H + 0.018), 0.016, PL(), seg=6, rings=1, ends=False, bend=0)
	B((0.04, 0.1, 0.04), (-0.16, -0.12, H + 0.022), IRD(), bevel=0.004, rot=(0, 0, -10))
	for ang in (-6, 6):
		B((0.32, 0.014, 0.012), (0.1, 0.12, H + 0.007), IRD(), bevel=0.002, rot=(0, 0, ang))
	kit.cylinder(0.014, 0.014, (-0.06, 0.12, H + 0.012), IRON("b"), verts=8, bevel=0.002)
	rodm((-0.05, 0.0, H + 0.008), (0.1, 0.03, H + 0.008), 0.008, IRON("b"))
	lathe([(0, H), (0.05, H), (0.05, H + 0.04), (0.044, H + 0.04), (0.044, H + 0.006), (0, H + 0.006)], (0.25, -0.1), IRD(), seg=14)
	for k in range(6):
		a = k * 1.05
		rivet((0.25 + math.cos(a) * 0.025, -0.1 + math.sin(a) * 0.025, H + 0.014), IRON("b"), r=0.008)
	for (x, y) in ((0.33, -0.18), (0.36, -0.15), (-0.32, 0.0)):
		rivet((x, y, H + 0.006), IRON("b"), r=0.008)
	B((0.16, 0.05, 0.03), (0.3, 0.17, H + 0.013), SST(), bevel=0.008, rot=(0, 0, 12))
	for (y, ang) in ((-0.02, 8), (0.06, -5)):
		B((0.5, 0.035, 0.006), (-0.05, y, H + (0.002 if ang > 0 else 0.007)), LEATH("b"), bevel=0, rot=(0, 0, ang))
		kit.ring(0.02, 0.004, (0.2, y + 0.04 * math.sin(math.radians(ang)) * 6, H + 0.006), IRON("b"), seg=8)
	# empty quench bucket under the bench
	lathe([(0, 0), (0.13, 0), (0.15, 0.26), (0.135, 0.26), (0.117, 0.015), (0, 0.015)], (0.25, 0.0), PL(), seg=16)
	for z in (0.05, 0.21):
		kit.ring(0.134 + z * 0.08, 0.009, (0.25, 0.0, z), IRD(), seg=16)


def ro_archery_bale():
	B((0.9, 0.45, 0.42), (0, 0.05, 0.21), STRAW("a"), bevel=0.03)
	for x in (-0.25, 0.25):
		B((0.03, 0.46, 0.42), (x, 0.05, 0.215), ROPE(), bevel=0.004)
	cz, cy, R = 0.42 + 0.42 - 0.02, -0.02, 0.42
	kit.cylinder(R, 0.18, (0, cy, cz), STRAW("b"), rot=(90, 0, 0), verts=28, bevel=0.02)
	for y in (cy - 0.07, cy + 0.07):
		kit.ring(R, 0.022, (0, y, cz), STRAW("c"), rot=(90, 0, 0), seg=30)
	fy = cy - 0.09
	for i, (rr, col) in enumerate(((0.36, (0.6, 0.53, 0.38)), (0.27, (0.42, 0.11, 0.07)), (0.18, (0.6, 0.53, 0.38)), (0.09, (0.42, 0.11, 0.07)), (0.035, (0.08, 0.07, 0.06)))):
		front = fy - 0.003 - i * 0.003
		back = fy + 0.01 + i * 0.004
		kit.cylinder(rr, back - front, (0, (front + back) / 2, cz), C(col, 0.95), rot=(90, 0, 0), verts=28, bevel=0)
	for s_ in (-1, 1):
		log((s_ * 0.33, 0.36, 0.0), (s_ * 0.24, cy + 0.095, cz + 0.3), 0.035, BK(), seg=7, rings=2, bend=0.02, end_m=LE())
	log((-0.36, 0.27, 0.62), (0.36, 0.27, 0.62), 0.03, BK(), seg=7, rings=1, bend=0, end_m=LE())
	for s_ in (-1, 1):
		kit.ring(0.045, 0.011, (s_ * 0.27, 0.2, 0.86), ROPE(), seg=10)
	r = random.Random(5)
	for (x, z) in ((0.05, 0.03), (-0.12, 0.1), (0.2, -0.15), (-0.25, -0.2), (0.02, 0.22), (0.3, 0.12)):
		dx, dz = r.uniform(-0.12, 0.12), r.uniform(-0.05, 0.12)
		bolt((x + dx, fy - 0.5, cz + z + dz), (x, fy + 0.07, cz + z), roll=r.uniform(0, 120))
	bolt((0.32, 0.05 - 0.225 - 0.45, 0.25), (0.3, 0.05 - 0.225 + 0.06, 0.22), roll=15)
	lying_bolt(-0.45, -0.62, -30, roll=40)  # one bolt that missed, lying on the ground
	log((-0.78, -0.33, 0.0085), (-0.62, -0.4, 0.0085), 0.0085, WD("b"), seg=7, rings=1, ends=False, bend=0)  # a snapped bolt shaft
	splinters((-0.62, -0.4, 0.0085), (1, -0.45, 0), n=3, r=0.009, m=WD("c"))
	floor_cut()


def ro_flag_pole():
	R0 = 0.075
	log((-0.75, 0, 0.075), (0.75, 0, 0.075), 0.075, BK(), seg=10, rings=3, bend=0.02, end_m=LE())
	log((0, -0.75, 0.2), (0, 0.75, 0.2), 0.075, BK(), seg=10, rings=3, bend=0.02, end_m=LE())
	log((0, 0, 0.1), (0, 0, 3.0), R0, BK(), seg=10, rings=5, bend=0.01, end_m=LE(), r1=0.05)
	for (dx, dy, z0) in ((0.6, 0, 0.12), (-0.6, 0, 0.12), (0, 0.6, 0.26), (0, -0.6, 0.26)):
		log((dx, dy, z0), (dx * 0.1, dy * 0.1, 0.9), 0.035, BK(), seg=7, rings=2, bend=0.02, end_m=LE())
	for z in (0.88, 0.32):
		for k in range(2):
			kit.ring(0.085, 0.013, (0, 0, z + k * 0.03), ROPE(), seg=14)
	kit.cone(0.05, 0.0, 0.22, (0, 0, 3.1), IRON("b"), verts=6, bevel=0)
	kit.ring(0.054, 0.012, (0, 0, 2.97), IRD(), seg=12)
	sphere((0, 0, 3.0), 0.055, CU(), seg=12, rings=8)
	yz = 2.75
	log((0.0, 0, yz), (0.9, 0, yz), 0.028, BK(), seg=7, rings=2, bend=0, end_m=LE())
	log((0.0, 0, yz - 0.32), (0.32, 0, yz - 0.01), 0.022, BK(), seg=6, rings=1, bend=0, end_m=LE())
	kit.ring(0.062, 0.012, (0, 0, yz), IRD(), seg=12)
	r = random.Random(7)
	top = yz - 0.03
	pts = [(0.08, top), (0.84, top), (0.84, top - 0.42), (0.78, top - 0.46), (0.82, top - 0.52), (0.84, top - 0.7)]
	xs = [0.84 - k * 0.76 / 9 for k in range(1, 9)]
	for x in xs:
		pts.append((x, top - r.uniform(0.6, 0.86)))
	pts.append((0.08, top - 0.82))
	wave = lambda o: [setattr(v.co, "y", v.co.y + 0.025 * math.sin((v.co.x - 0.08) * 7.0)) for v in o.data.vertices]  # noqa: E731
	ban = prism(pts, -0.005, 0.005, kit.tex_mat("bannercloth", "a"))
	wave(ban)
	anv = prism([(0.32, top - 0.3), (0.6, top - 0.3), (0.56, top - 0.36), (0.5, top - 0.37), (0.5, top - 0.44), (0.56, top - 0.47), (0.36, top - 0.47), (0.42, top - 0.44),
		(0.42, top - 0.37), (0.3, top - 0.34)], -0.0085, -0.004, C((0.62, 0.52, 0.3), 0.9))
	wave(anv)
	ham = prism([(0.43, top - 0.13), (0.55, top - 0.13), (0.55, top - 0.2), (0.5, top - 0.2), (0.5, top - 0.27), (0.48, top - 0.27), (0.48, top - 0.2), (0.43, top - 0.2)],
		-0.0085, -0.004, C((0.62, 0.52, 0.3), 0.9))
	wave(ham)
	for x in (0.12, 0.3, 0.48, 0.66, 0.82):
		kit.ring(0.036, 0.008, (x, 0.025 * math.sin((x - 0.08) * 7.0), yz), ROPE(), rot=(0, 90, 0), seg=10)
	log((0.06, 0.02, 2.7), (0.065, 0.06, 1.25), 0.008, ROPE(), seg=5, rings=2, ends=False, bend=0)
	B((0.04, 0.05, 0.16), (0.06, 0.05, 1.25), PL(), bevel=0.006)
	for k in range(3):
		kit.ring(0.035, 0.007, (0.06, 0.05, 1.2 + k * 0.035), ROPE(), seg=10)
	for k in range(3):
		a = math.radians(45 + 120 * k)
		gx, gy = math.cos(a) * 1.15, math.sin(a) * 1.15
		log((math.cos(a) * 0.05, math.sin(a) * 0.05, 2.05), (gx, gy, 0.16), 0.008, ROPE(), seg=5, rings=1, ends=False, bend=0)
		stake((gx * 1.08, gy * 1.08, 0.3), (gx * 0.95, gy * 0.95, -0.05), 0.03, tip=0.1)
	kit.ring(0.06, 0.014, (0, 0, 2.05), ROPE(), seg=12)
	floor_cut()


def ro_ladder_platform():
	P, TOP = 0.5, 2.1
	for x in (-P, P):
		for y in (-P, P):
			log((x, y, 0), (x, y, TOP), 0.07, BK(), seg=9, rings=4, bend=0.015, end_m=LE())
	for y in (-P, P):
		log((-0.62, y, 1.35), (0.62, y, 1.35), 0.06, BK(), seg=8, rings=2, bend=0.01, end_m=LE())
	xs = [-0.5 + i * 0.2 for i in range(6)]
	for i, x in enumerate(xs):
		if i == 4:
			continue
		ln = 1.18 if i != 1 else 0.7
		y = 0 if i != 1 else 0.24
		plank((0.19, ln, 0.04), (x, y, 1.43), m=PL())
		if i == 1:
			splinters((x, y - ln / 2, 1.43), (0, -1, 0), n=4, r=0.05)
	for (a, b) in (((-P, P), (P, P)), ((-P, -P), (-P, P))):
		log((a[0], a[1], 1.95), (b[0], b[1], 1.95), 0.04, BK(), seg=7, rings=2, bend=0.01, end_m=LE())
		log((a[0], a[1], 1.7), (b[0], b[1], 1.7), 0.035, BK(), seg=7, rings=2, bend=0.01, end_m=LE())
	log((P, P, 1.95), (P, 0.05, 1.95), 0.04, BK(), seg=7, rings=1, bend=0, end_m=LE())
	splinters((P, 0.05, 1.95), (0, -1, 0), n=4, r=0.04)
	log((P, -P, 1.95), (P - 0.02, -0.12, 1.5), 0.04, BK(), seg=7, rings=1, bend=0, end_m=LE())
	splinters((P - 0.02, -0.12, 1.5), (0, 0.6, -0.8), n=4, r=0.04)
	for x in (-P, P):
		log((x, -P, 0.15), (x, P, 1.25), 0.04, BK(), seg=7, rings=2, bend=0.02, end_m=LE())
		log((x, P, 0.15), (x, -P, 1.25), 0.04, BK(), seg=7, rings=2, bend=0.02, end_m=LE())
	for x in (-P, P):
		for y in (-P, P):
			for z in (1.35, 1.95, 1.7):
				if z != 1.35 and (y == -P and x == -P and z == 1.7):
					continue
				kit.ring(0.078, 0.012, (x, y, z), ROPE(), seg=14)
	# ladder leaning on the front beam
	b0, b1 = Vector((0, -1.05, 0)), Vector((0, -P - 0.08, 1.55))
	for s_ in (-1, 1):
		log((s_ * 0.2, b0.y, 0.0), (s_ * 0.2, b1.y, b1.z), 0.035, BK(), seg=7, rings=3, bend=0.01, end_m=LE())
	for k in range(6):
		p = b0.lerp(b1, (k + 0.6) / 6.5)
		log((-0.24, p.y, p.z), (0.24, p.y, p.z), 0.022, BK(), seg=6, rings=1, bend=0, end_m=LE())
		for s_ in (-1, 1):
			kit.ring(0.04, 0.009, (s_ * 0.2, p.y, p.z), ROPE(), seg=10)
	floor_cut()


def _fix_crossbow_clamp(objs):
	"""The game's crossbow_stone.glb has its stirrup clamp face lying flat on the stirrup plate (shimmer, flagged by
	the checker in items/crossbow_stone too). Make the clamp 2 mm thicker each side so the plate sits inside it.
	shortcut: matches that one item's numbers; fix it in the item's own build script when someone owns that file."""
	import bmesh
	for o in objs:
		bm = bmesh.new()
		bm.from_mesh(o.data)
		seen = set()
		for f in bm.faces:
			if f.index in seen:
				continue
			isl, stack = [], [f]
			seen.add(f.index)
			while stack:
				g = stack.pop()
				isl.append(g)
				for e in g.edges:
					for h in e.link_faces:
						if h.index not in seen:
							seen.add(h.index)
							stack.append(h)
			vs = {v for g in isl for v in g.verts}
			inside = all(abs(v.co.x) <= 0.0321 and -0.0212 <= v.co.y <= -0.0008 and 0.5535 <= v.co.z <= 0.6905 for v in vs)
			zmin = min(v.co.z for v in vs)
			if inside and (zmin < 0.6 or zmin > 0.684):
				for v in vs:
					v.co.y = -0.011 + (v.co.y + 0.011) * 1.2
		bm.to_mesh(o.data)
		bm.free()


def ro_quiver_rack(empty=False):
	"""(wall) Crossbow rack. LOOT: 1 crossbow_stone (the game's own model) + 5 bolt_stone. empty=True: both gone."""
	BY = 0.06
	for i in range(6):
		B((0.195, 0.03, 1.25 + J(0.03)), (-0.5 + i * 0.2, BY - 0.015, 0.625), PL(), bevel=0.006)
	for z in (0.2, 1.05):
		B((1.22, 0.03, 0.08), (0, BY - 0.043, z), PL(), bevel=0.006)
		for x in (-0.5, -0.1, 0.3):
			rivet((x, BY - 0.06, z), LE(), r=0.013)
	B((1.28, 0.09, 0.05), (0, BY - 0.05, 1.27), PL(), bevel=0.008)  # cap board
	# the crossbow, hung by its bow arms on two pegs (pegs fitted to where the arms are)
	cx = -0.2
	cb = place_glb("items/crossbow_stone", (cx, -0.073, 0.36), 0.74)
	_fix_crossbow_clamp(cb)
	bpy.context.view_layer.update()
	pts = [o.matrix_world @ v.co for o in cb for v in o.data.vertices]
	for px in (cx - 0.21, cx + 0.21):
		zb = min((p.z for p in pts if abs(p.x - px) < 0.02 and p.z > 0.8), default=0.95)
		zp = zb - 0.016 + 0.004
		kit.cylinder(0.016, 0.2, (px, -0.055, zp), PL(), rot=(90, 0, 0), verts=8, bevel=0.003)
		sphere((px, -0.155, zp + 0.008), 0.021, LE(), seg=8, rings=5)
	if empty:
		for o in cb:
			bpy.data.objects.remove(o, do_unlink=True)
	# the wooden bolt case, its back against the planks, hung by a strap from a peg
	bx, w, d, h, z0 = 0.35, 0.26, 0.14, 0.26, 0.42
	yb = BY - 0.03 + 0.004  # back face of the case, 4 mm into the planks
	yc = yb - d / 2
	B((w, 0.02, h), (bx, yb - 0.01, z0 + h / 2), PL(), bevel=0.004)
	B((w, 0.02, h * 0.8), (bx, yb - d + 0.01, z0 + h * 0.4), PL(), bevel=0.004)
	for s_ in (-1, 1):
		B((0.02, d - 0.036, h - 0.006), (bx + s_ * (w / 2 - 0.01), yc, z0 + h / 2), PL(), bevel=0.004)
	B((w - 0.036, d - 0.036, 0.02), (bx, yc, z0 + 0.015), PL(), bevel=0.003)
	for z in (z0 + 0.04, z0 + h * 0.8 - 0.04):  # copper bands round the front
		B((w + 0.008, 0.008, 0.024), (bx, yb - d - 0.001, z), CU(), bevel=0.002)
		for x in (bx - w / 2 + 0.03, bx + w / 2 - 0.03):
			rivet((x, yb - d - 0.006, z), IRD(), r=0.007)
	kit.cylinder(0.016, 0.12, (bx, BY - 0.09, 0.9), PL(), rot=(90, 0, 0), verts=8, bevel=0.003)
	for s_ in (-1, 1):
		tube([(bx + s_ * (w / 2 + 0.002), yc, z0 + h - 0.03), (bx + s_ * (w / 2 + 0.004), yc, z0 + h + 0.03), (bx + s_ * 0.1, -0.02, 0.84),
			(bx + s_ * 0.012, -0.03, 0.915)], 0.007, 0.007, LEATH("dark"), seg=6)  # strap outside the case, clear of the bolts
	if not empty:
		for k, (x, y) in enumerate(((-0.08, -0.03), (0.0, -0.03), (0.08, -0.03), (-0.04, 0.03), (0.04, 0.03))):
			tip = (bx + x, yc + y, z0 + 0.026)
			bolt((tip[0], tip[1], tip[2] + 1), tip, head=SST(), roll=k * 47 + 10)
	# a coil of spare crossbow string on its own peg
	kit.cylinder(0.014, 0.11, (0.35, BY - 0.085, 1.16), PL(), rot=(90, 0, 0), verts=8, bevel=0.003)
	for k in range(3):
		kit.ring(0.065 - k * 0.006, 0.005, (0.35, -0.06 + k * 0.011, 1.16 - 0.065 + 0.012 + k * 0.006), ROPE(), rot=(90, 0, 0), seg=18)


def ro_gate_bar_brackets():
	BY = 0.09
	logs = []
	for i in range(6):
		x = -0.75 + i * 0.3
		h = 1.55 + J(0.05)
		logs += made(lambda x=x, h=h: (log((x, 0, 0), (x, 0, h), 0.152, BK(), seg=9, rings=3, bend=0.02, ends=False),
			log((x, 0, h - 0.02), (x, 0, h + 0.25), 0.148, LE(), seg=9, rings=2, ends=False, bend=0, r1=0.006)))
	for o in logs:
		mw = o.matrix_world
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.y > BY:
				w.y = BY
				v.co = inv @ w
	for k, x in enumerate((-0.45, 0.45, 0.0)):
		fy = -0.145
		if k == 2:
			B((0.12, 0.02, 0.2), (x + 0.15, fy, 0.62), IRD(), bevel=0.003)
			for z in (0.56, 0.68):
				rivet((x + 0.15, fy - 0.012, z), IRON("b"), r=0.012)
			B((0.04, 0.1, 0.03), (x + 0.15, fy - 0.05, 0.535), IRD(), bevel=0.002, rot=(30, 0, 0))
			continue
		B((0.13, 0.02, 0.32), (x, fy, 0.97), IRD(), bevel=0.003)
		for z in (0.85, 0.97, 1.09):
			rivet((x, fy - 0.012, z), IRON("b"), r=0.013)
		B((0.08, 0.2, 0.035), (x, fy - 0.1, 0.875), IRD(), bevel=0.003)
		B((0.08, 0.03, 0.2), (x, fy - 0.2, 0.96), IRD(), bevel=0.003)
		rivet((x, fy - 0.215, 1.03), IRON("b"), r=0.011)
	B((1.72, 0.16, 0.16), (0, -0.245, 0.972), PL(), bevel=0.014)
	for s_ in (-1, 1):
		B((0.03, 0.17, 0.17), (s_ * 0.86, -0.245, 0.972), IRD(), bevel=0.004)
		rivet((s_ * 0.86, -0.33, 0.972), IRON("b"), r=0.012)
	B((0.03, 0.02, 0.06), (0.15, -0.15, 0.6), IRD(), bevel=0.003)
	kit.ring(0.07, 0.012, (0.15, -0.165, 0.52), IRD(), rot=(90, 0, 0), seg=16)
	B((0.26, 0.025, 0.2), (-0.15, -0.135, 1.35), PL(), bevel=0.006)
	B((0.15, 0.012, 0.1), (-0.15, -0.152, 1.35), SHADOW(), bevel=0)
	B((0.13, 0.02, 0.12), (-0.11, -0.163, 1.35), PL(), bevel=0.004)
	kit.cylinder(0.012, 0.03, (-0.07, -0.18, 1.35), IRD(), rot=(90, 0, 0), verts=8, bevel=0.002)


def ro_palisade_section():
	BY = 0.085
	rails = []
	for z in (0.35, 1.15):
		rails += made(lambda z=z: log((-0.92, 0.03, z), (0.92, 0.03, z), 0.07, BK(), seg=9, rings=3, bend=0.01, end_m=LE()))
	for o in rails:
		mw = o.matrix_world
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.y > BY:
				w.y = BY
				v.co = inv @ w
	for i in range(6):
		x = -0.75 + i * 0.3
		if i == 3:
			log((x, -0.07, 0.0), (x, -0.07, 0.92), 0.085, BK(), seg=8, rings=3, bend=0.02, end_m=LE())
			splinters((x, -0.07, 0.92), (0, 0, 1), n=5, r=0.085)
		else:
			stake((x, -0.07, 0.0), (x, -0.07, 1.55 + J(0.12)), 0.085, tip=0.24)
		for z in (0.35, 1.15):
			if i == 3 and z > 0.9:
				continue
			kit.ring(0.095, 0.012, (x, -0.07, z - 0.04), ROPE(), seg=14)
			kit.ring(0.095, 0.012, (x, -0.07, z + 0.04), ROPE(), seg=14)
			rivet((x, -0.157, z), LE(), r=0.018)
	stake((0.2, -0.32, 0.075), (0.85, -0.45, 0.075), 0.075, tip=0.24)
	splinters((0.2, -0.32, 0.075), (-1, 0.2, 0), n=4, r=0.075)
	floor_cut()


MODELS = {
	"rt_stair_landing_broken": rt_stair_landing_broken, "rt_lookout_brazier": rt_lookout_brazier, "rt_signal_mirror_stand": rt_signal_mirror_stand,
	"rt_watch_table_map": rt_watch_table_map, "rt_arrow_slit_shutter": rt_arrow_slit_shutter, "rt_fallen_bell": rt_fallen_bell,
	"rt_weapon_rack": rt_weapon_rack, "rt_water_cistern": rt_water_cistern, "rt_watch_hooks": rt_watch_hooks,
	"rt_watch_roster_slab": rt_watch_roster_slab, "rt_arrow_crate_spill": rt_arrow_crate_spill, "rt_map_tube_rack": rt_map_tube_rack,
	"ro_stake_bundle": ro_stake_bundle, "ro_gate_wing_broken": ro_gate_wing_broken, "ro_supply_cart": ro_supply_cart,
	"ro_camp_cookery": ro_camp_cookery, "ro_duty_board": ro_duty_board, "ro_armour_bench": ro_armour_bench,
	"ro_archery_bale": ro_archery_bale, "ro_flag_pole": ro_flag_pole, "ro_ladder_platform": ro_ladder_platform,
	"ro_quiver_rack": ro_quiver_rack, "ro_quiver_rack_empty": lambda: ro_quiver_rack(empty=True),
	"rt_arrow_crate_spill_empty": lambda: rt_arrow_crate_spill(empty=True), "ro_gate_bar_brackets": ro_gate_bar_brackets, "ro_palisade_section": ro_palisade_section,
}

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
			floor_cut()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
