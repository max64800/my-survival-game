# Home decor batch Nov 21 (group hm): things the player builds for their own home, in the spirit of the owner's
# 10/10 favourites (crossed_axes, gem_case, ore_sample_shelf, spice_shelf, dish_rack, tool_wall, writing_desk ...).
#   blender --background --factory-startup --python builds/decor_nov21_hm.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on a floor post or their own legs, so they never float.
# One wood family (wood) and at most one stone family per model; copper/iron only as fittings.
#
# Wall trophies and displays
#   hm_spider_trophy        the real cave spider's head (eyes, fangs, palps) mounted on one wooden wall panel
#   hm_beetle_shell_trophy  the real rock beetle's head (stone brow, eyes, tusks, feelers) on one wooden wall panel
#   hm_snail_shell_trophy   the real rock snail's head (eye stalks, moustache) on one wooden wall panel
#   hm_pickaxe_progression  long board with four pickaxes on peg pairs: stone, copper, iron, master iron; rank plates
#   hm_crossed_hammers      round carved greystone medallion with two crossed war hammers, copper bands and grips
#   hm_shield_spears        round plank shield with iron boss and rim in front of two crossed leaf-head spears
#   hm_lamp_history_board   plank board with three iron hook arms: old clay oil lamp, iron candle lantern, copper lamp
#   hm_bat_skull_plaque     the real cave bat's head (ears, snout, eyes) on one wooden wall panel
#   hm_heirloom_axe         double-bit family axe lying on two iron hooks above a carved limestone rune lintel
#   hm_vein_slice_frame     framed polished basalt slice with copper, silver and gold veins cut into it
# Shelves and racks full of small ordered things
#   hm_potion_rack          three-tier rack of corked and wax-sealed potion flasks behind front rails, labels
#   hm_scroll_lattice       diamond lattice rack, a rolled scroll or a leather scroll case resting in every cell
#   hm_preserve_shelf       pantry shelf: tied-top clay crocks, glass jars of preserves, sealed pots and a jug
#   hm_tankard_shelf        two-tier wall shelf: lidded pewter tankards, banded wooden tankards, horns, goblets, cups
#   hm_ingot_display        stepped wooden stand with neat ingot stacks (copper, iron, silver, gold) and rank plates
#   hm_gem_jar_shelf        wall shelf of glass jars, each sorted with one kind of gem, plus a small gem balance
#   hm_herb_ladder          A-frame drying ladder with tied bundles of dried stalks and seed heads hanging from rungs
#   hm_book_nook            limestone arched wall niche with two wooden shelves of books, bookend, candle, tomes
# Furniture (bare)
#   hm_carved_high_chair    high-backed armchair with carved mountain crest and hammer panel, finials, copper caps
#   hm_delve_game_table     square game table with a carved 7x7 board, a stone mountain in the middle, copper and
#                           iron miner pieces with their chiefs, and a drawer for the pieces
#   hm_map_table            trestle map table: a cave map held by four stone weights, dividers, candle, rolled maps below
#   hm_trophy_pedestal      carved greystone pedestal holding a rock beetle's jaw pair in a copper socket on a wooden base
#   hm_banded_sideboard     long sideboard: three drawers, three carved doors with copper bands, strap hinges, keyhole
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, plank, rivet, rng  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import CU, IRON, lantern_body, plank_board, plank_top, wall_post  # noqa: E402
from decor_nov21_a import GROOVE_M, carve, groove, groove_path, groove_ring, rune_row, tube  # noqa: E402
from decor_nov21_d import rot2, slab  # noqa: E402
from decor_nov21_f import glass, lathe, place_glb  # noqa: E402

GOLD = lambda: C((0.82, 0.6, 0.2), 0.3, metal=0.85)  # noqa: E731
SILVER = lambda: kit.tex_mat("silver", "a")  # noqa: E731
BONEC = lambda: C((0.7, 0.64, 0.52), 0.8)  # noqa: E731
PAPER = lambda: C((0.82, 0.74, 0.56), 0.95)  # noqa: E731
LEATHER = lambda: kit.tex_mat("leather", "dark")  # noqa: E731
ROPE = lambda: kit.tex_mat("rope", "a")  # noqa: E731
W = lambda v="b": T("wood", v)  # noqa: E731  the one wood family


# ================= helpers =================
def tube_r(pts, radii, m, seg=10):
	"""A tube along points with its own radius at every point (snail coil, jaws, horns)."""
	pts = [Vector(p) for p in pts]
	n = len(pts)
	verts = []
	for i, p in enumerate(pts):
		d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
		up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
		u = d.cross(up).normalized()
		v = d.cross(u)
		for k in range(seg):
			a = 2 * math.pi * k / seg
			verts.append(tuple(p + (u * math.cos(a) + v * math.sin(a)) * radii[i]))
	faces = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	faces += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	return mesh(verts, faces, m, smooth=True)


def dome(cx, cz, rx, rz, depth, y0, m, nu=12, nv=3):
	"""Half an egg lying on the wall: flat back at y0, bulging `depth` towards the front (-Y)."""
	v = []
	for i in range(nv):
		t = (math.pi / 2) * i / nv
		for k in range(nu):
			a = 2 * math.pi * k / nu
			v.append((cx + rx * math.cos(t) * math.cos(a), y0 - depth * math.sin(t), cz + rz * math.cos(t) * math.sin(a)))
	v.append((cx, y0 - depth, cz))
	f = [tuple(range(nu))]
	for i in range(nv - 1):
		f += [(i * nu + k, i * nu + (k + 1) % nu, (i + 1) * nu + (k + 1) % nu, (i + 1) * nu + k) for k in range(nu)]
	top = nv * nu
	f += [((nv - 1) * nu + k, (nv - 1) * nu + (k + 1) % nu, top) for k in range(nu)]
	return mesh(v, f, m)


def aim_obj(o, d):
	o.rotation_euler = Vector(d).to_track_quat("Z", "Y").to_euler()
	return o


def top_groove(p0, p1, z, w=0.006, depth=0.004, m=None):
	"""Cutter for a stroke carved down into a top face at height z."""
	(x0, y0), (x1, y1) = p0, p1
	ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
	return B((math.hypot(x1 - x0, y1 - y0) + w * 0.9, w, depth + 0.03), ((x0 + x1) / 2, (y0 + y1) / 2, z - depth + (depth + 0.03) / 2),
		m or GROOVE_M(), bevel=0, rot=(0, 0, ang))


def label(x, z, y_back, w=0.15, h=0.038, marks=0):
	"""A brass name plate pressed onto a front face at y_back: two engraved lines, `marks` rank ticks, two rivets."""
	t = 0.012
	p = B((w, t, h), (x, y_back - t / 2 + 0.004, z), CU("b"), bevel=0.002)
	fy = y_back - t + 0.004
	cut = []
	if marks:
		for k in range(marks):
			xx = x + (k - (marks - 1) / 2) * 0.016
			cut += groove((xx, z - h * 0.28), (xx, z + h * 0.28), fy, w=0.005, depth=0.003)
	else:
		for dz in (0.007, -0.007):
			cut += groove((x - w * 0.3, z + dz), (x + w * 0.3, z + dz), fy, w=0.004, depth=0.003)
	carve(p, cut)
	for s_ in (-1, 1):
		kit.rivet((x + s_ * (w / 2 - 0.012), fy - 0.001, z), CU("dark"), r=0.006)
	return p


def flame_at(x, y, z, s=1.0):
	kit.flame((x, y, z), 0.016 * s, 0.06 * s, kit.glow("fire", 1.6), twist=x * 40)
	kit.flame((x, y, z + 0.004), 0.008 * s, 0.036 * s, kit.glow("fire_core", 2.0), twist=x * 40 + 1)


def posts2(xs, top, y=0.04):
	"""Two floor posts with feet holding up a wide wall board."""
	for x in xs:
		B((0.06, 0.05, top), (x, y, top / 2), W("dark"), bevel=0.008)
		B((0.24, 0.2, 0.04), (x, y - 0.04, 0.02), W("dark"), bevel=0.008)


def board(w, z0, z1, d=0.05, n=None):
	"""Vertical planks between z0 and z1, front face at y = 0, flat back at y = d."""
	n = n or max(2, round(w / 0.27))
	for i in range(n):
		B((w / n - 0.008, d, z1 - z0 + J(0.01)), (-w / 2 + w / n * (i + 0.5), d / 2, (z0 + z1) / 2), W("abc"[i % 3]), bevel=0.01)


def flatten_floor():
	"""Nothing may sink below the floor (round log end caps, tilted parts): flatten it onto z = 0."""
	bpy.context.view_layer.update()
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		mw = o.matrix_world
		inv = mw.inverted()
		for v in o.data.vertices:
			wv = mw @ v.co
			if wv.z < 0:
				wv.z = 0.0
				v.co = inv @ wv


# ================= Wall trophies: the real monster's head on one wooden panel =================
def monster_head(name, size, keep, cuts):
	"""Import the game's own monster (place_glb), keep only the parts named in `keep`, and slice away everything on
	the far side of each cut plane (co, normal) given at size 1 (the normal points at the part removed). Cut faces
	are filled, so the head is closed and its back is flat. Returns the head's meshes."""
	import bmesh
	ms = place_glb(name, (0, 0, 0), size)
	head = []
	for o in ms:
		if not any(o.name.startswith(k) for k in keep):
			bpy.data.objects.remove(o, do_unlink=True)
			continue
		o.data.transform(o.matrix_world)
		o.matrix_world = Matrix.Identity(4)
		bm = bmesh.new()
		bm.from_mesh(o.data)
		for co, no in cuts:
			geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
			r = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=Vector(co) * size, plane_no=Vector(no), clear_outer=True)
			edges = [e for e in r["geom_cut"] if isinstance(e, bmesh.types.BMEdge) and e.is_valid and e.is_boundary]
			if edges:
				bmesh.ops.holes_fill(bm, edges=edges, sides=0)
		bm.to_mesh(o.data)
		bm.free()
		if len(o.data.vertices) < 4:
			bpy.data.objects.remove(o, do_unlink=True)
			continue
		head.append(o)
	return head


def head_panel(w, h, head, sink=0.008):
	"""ONE wooden wall panel (rounded top, flat back at y = 0.05, carved border, pegged corners) with the head
	mounted in its middle, the head's flat cut back pressed `sink` into the panel front (y = 0)."""
	pts = [(-w / 2 + 0.035, 0.0), (w / 2 - 0.035, 0.0), (w / 2, 0.035), (w / 2, h * 0.62)]
	for k in range(1, 10):
		a = math.pi * k / 10
		pts.append((math.cos(a) * w / 2, h * 0.62 + math.sin(a) * h * 0.38))
	pts.append((-w / 2, h * 0.62))
	pts.append((-w / 2, 0.035))
	panel = slab(pts, 0.0, 0.05, W("b"))
	inner = [(x * (1 - 0.09 / w), 0.045 + z * (1 - 0.09 / h)) for x, z in pts]
	carve(panel, groove_path(inner, 0.0, w=0.012, depth=0.008, closed=True))
	for x, z in ((-w / 2 + 0.08, 0.08), (w / 2 - 0.08, 0.08), (-w / 2 + 0.08, h * 0.66), (w / 2 - 0.08, h * 0.66)):
		sphere((x, 0.0, z), 0.014, W("dark"), scale=(1, 0.7, 1), seg=8, rings=5)
	bpy.context.view_layer.update()
	vs = [o.matrix_world @ v.co for o in head for v in o.data.vertices]
	lo = Vector([min(v[i] for v in vs) for i in range(3)])
	hi = Vector([max(v[i] for v in vs) for i in range(3)])
	d = Vector((-(lo.x + hi.x) / 2, sink - hi.y, h * 0.52 - (lo.z + hi.z) / 2))
	for o in head:
		o.matrix_world = Matrix.Translation(d) @ o.matrix_world


def hm_spider_trophy():
	head = monster_head("monsters/cave_spider_v0", 1.3, ("body", "leg_l0", "leg_r0"),
		[((0, 0.02, 0), (0, 1, 0)), ((0.15, 0, 0), (1, 0, 0)), ((-0.15, 0, 0), (-1, 0, 0))])  # head only, leg stubs
	head_panel(0.5, 0.55, head)


def hm_beetle_shell_trophy():
	head = monster_head("creatures/rock_beetle_frost", 0.8, ("body", "mandible", "soft_stalk"), [((0, -0.22, 0), (0, 1, 0)), ((0, 0, 0.52), (0, 0, 1))])
	head_panel(0.6, 0.6, head)


def hm_snail_shell_trophy():
	head = monster_head("creatures/rock_snail_mossy", 0.85, ("soft_body", "soft_stalk", "stalktip"),
		[((0, -0.2, 0), (0, 1, 0)), ((0, 0, 0.1), (0, 0, -1))])
	head_panel(0.56, 0.66, head)


def pick(x, y, hz, kind):
	handle = W("c") if kind else W("dark")
	log((x, y, 0.9), (x, y, hz + 0.03), 0.021, handle, seg=7, rings=2, bend=0.01)
	head = {0: T("greystone", "b"), 1: CU("b"), 2: IRON("a"), 3: IRON("dark")}[kind]
	B((0.06, 0.055, 0.07), (x, y, hz), head, bevel=0.01)
	for s_ in (-1, 1):
		tube([(x, y, hz), (x + s_ * 0.06, y, hz + 0.012), (x + s_ * 0.12, y, hz - 0.008), (x + s_ * 0.165, y, hz - 0.055)],
			0.026 if kind else 0.03, 0.006 if kind else 0.012, head, seg=8)
	for z in (0.93, 0.96, 0.99):  # leather grip
		kit.ring(0.023, 0.006, (x, y, z), LEATHER(), seg=10)
	if kind == 0:  # stone head lashed on with rope
		for dz in (-0.045, -0.06):
			kit.ring(0.026, 0.007, (x, y, hz + dz), ROPE(), seg=10)
		for s_ in (-1, 1):
			kit.ring(0.03, 0.007, (x + s_ * 0.04, y, hz + 0.008), ROPE(), rot=(0, 90, 0), seg=10)
	elif kind == 1:
		kit.ring(0.026, 0.007, (x, y, hz - 0.05), CU("dark"), seg=10)
	else:
		B((0.03, 0.02, 0.015), (x, y, hz + 0.04), IRON("dark" if kind == 2 else "a"), bevel=0.003)  # wedge
		kit.ring(0.026, 0.007, (x, y, hz - 0.05), IRON("dark"), seg=10)
		if kind == 3:
			for s_ in (-1, 1):
				kit.ring(0.031, 0.006, (x + s_ * 0.045, y, hz + 0.008), CU("b"), rot=(0, 90, 0), seg=10)
			kit.ring(0.024, 0.006, (x, y, 1.08), CU("b"), seg=10)
			kit.cylinder(0.024, 0.02, (x, y, 0.905), CU("b"), verts=10, bevel=0.003)


def hm_pickaxe_progression():
	Wd = 1.56
	posts2((-0.5, 0.5), 0.86)
	board(Wd, 0.78, 1.46)
	for z in (0.8, 1.44):
		B((Wd + 0.04, 0.03, 0.05), (0, -0.012, z), W("dark"), bevel=0.006)
		for x in (-0.74, 0.74):
			kit.rivet((x, -0.03, z), CU("dark"), r=0.011)
	hz = 1.36
	for i, x in enumerate((-0.57, -0.19, 0.19, 0.57)):
		for dx in (-0.055, 0.055):
			log((x + dx, 0.005, 1.336), (x + dx, -0.088, 1.34), 0.014, W("c"), seg=6, rings=1, ends=False, bend=0)
		pick(x, -0.06, hz, i)
		label(x, 0.86, 0.0, w=0.13, h=0.034, marks=i + 1)


def hm_crossed_hammers():
	wall_post(1.0)
	cz = 1.3
	med = kit.cylinder(0.33, 0.07, (0, 0.03, cz), T("greystone", "b"), rot=(90, 0, 0), verts=28, bevel=0.01)
	cut = groove_ring(0, cz, 0.29, -0.005, w=0.016, depth=0.012, n=28) + groove_ring(0, cz, 0.24, -0.005, w=0.01, depth=0.008, n=24)
	for k in range(12):  # notches between the two rings
		a = 2 * math.pi * k / 12 + 0.13
		cut += groove((math.cos(a) * 0.25, cz + math.sin(a) * 0.25), (math.cos(a) * 0.28, cz + math.sin(a) * 0.28), -0.005, w=0.012, depth=0.01)
	carve(med, cut)
	kit.ring(0.335, 0.02, (0, 0.03, cz), CU("dark"), rot=(90, 0, 0), seg=32)
	c = (0, cz)
	for s_, y0 in ((1, -0.035), (-1, -0.068)):
		ang = -s_ * 40
		slab([(-0.02, -0.42), (0.02, -0.42), (0.018, 0.3), (-0.018, 0.3)], y0, y0 + 0.035, W("c"), ang, c)
		slab([(-0.11, 0.26), (0.11, 0.26), (0.11, 0.38), (-0.11, 0.38)], y0 - 0.025, y0 + 0.055, IRON("a"), ang, c)
		for xe in (-1, 1):
			slab([(xe * 0.1, 0.255), (xe * 0.125, 0.25), (xe * 0.125, 0.39), (xe * 0.1, 0.385)], y0 - 0.03, y0 + 0.06, IRON("dark"), ang, c)
			slab([(xe * 0.06, 0.252), (xe * 0.082, 0.252), (xe * 0.082, 0.388), (xe * 0.06, 0.388)], y0 - 0.03, y0 + 0.06, CU("b"), ang, c)
		slab([(-0.03, 0.22), (0.03, 0.22), (0.03, 0.262), (-0.03, 0.262)], y0 - 0.01, y0 + 0.045, CU("dark"), ang, c)  # collar
		for z in (-0.36, -0.31, -0.26):
			slab([(-0.024, z - 0.018), (0.024, z - 0.018), (0.024, z + 0.018), (-0.024, z + 0.018)], y0 - 0.005, y0 + 0.04, LEATHER(), ang, c)
		px, pz = rot2(0, -0.43, ang, c)
		sphere((px, y0 + 0.0175, pz), 0.03, CU("b"), seg=10, rings=6)
		hx, hz = rot2(0, 0.32, ang, c)
		kit.rivet((hx, y0 - 0.032, hz), CU("dark"), r=0.012)


def hm_shield_spears():
	wall_post(1.0)
	c = (0, 1.3)
	for s_, yc in ((1, -0.02), (-1, -0.05)):
		ang = -s_ * 38
		x0, z0 = rot2(0, -0.7, ang, c)
		x1, z1 = rot2(0, 0.52, ang, c)
		log((x0, yc, z0), (x1, yc, z1), 0.018, W("c"), seg=7, rings=3, ends=False, bend=0.01)
		slab([(-0.022, 0.48), (0.022, 0.48), (0.017, 0.56), (-0.017, 0.56)], yc - 0.022, yc + 0.022, IRON("dark"), ang, c)
		slab([(-0.012, 0.55), (0.012, 0.55), (0.045, 0.63), (0.03, 0.7), (0, 0.79), (-0.03, 0.7), (-0.045, 0.63)], yc - 0.008, yc + 0.008, IRON("a"), ang, c)
		slab([(-0.004, 0.57), (0.004, 0.57), (0.004, 0.75), (-0.004, 0.75)], yc - 0.012, yc + 0.012, IRON("dark"), ang, c)  # mid rib
		slab([(-0.022, -0.74), (0.022, -0.74), (0.022, -0.68), (-0.022, -0.68)], yc - 0.022, yc + 0.022, CU("b"), ang, c)  # butt cap
		for z in (-0.52, -0.47):
			slab([(-0.022, z - 0.016), (0.022, z - 0.016), (0.022, z + 0.016), (-0.022, z + 0.016)], yc - 0.021, yc + 0.021, LEATHER(), ang, c)
	B((0.1, 0.1, 0.13), (0, -0.015, 1.06), W("dark"), bevel=0.008)  # mount block from post to shield
	sz, R = 1.3, 0.28
	kit.cylinder(R - 0.01, 0.012, (0, -0.064, sz), W("dark"), rot=(90, 0, 0), verts=24, bevel=0.002)
	n = 5
	for i in range(n):
		xa, xb = -R + 2 * R * i / n + 0.003, -R + 2 * R * (i + 1) / n - 0.003
		xs = [xa + (xb - xa) * k / 4 for k in range(5)]
		top = [(x, sz + math.sqrt(max(0.0, (R - 0.01) ** 2 - x * x))) for x in xs]
		bot = [(x, sz - math.sqrt(max(0.0, (R - 0.01) ** 2 - x * x))) for x in reversed(xs)]
		slab(top + bot, -0.11, -0.068, W("abc"[i % 3]))
	kit.ring(R, 0.018, (0, -0.09, sz), IRON("dark"), rot=(90, 0, 0), seg=32)
	for k in range(12):
		a = 2 * math.pi * k / 12
		kit.rivet((math.cos(a) * R, -0.108, sz + math.sin(a) * R), CU("dark"), r=0.009)
	for z in (sz + 0.14, sz - 0.14):  # two iron straps across the planks
		B((0.44 if abs(z - sz) < 0.2 else 0.4, 0.008, 0.03), (0, -0.113, z), IRON("a"), bevel=0.002)
		for x in (-0.15, 0.0, 0.15):
			kit.rivet((x, -0.118, z), CU("dark"), r=0.007)
	kit.cylinder(0.095, 0.012, (0, -0.114, sz), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.003)
	sphere((0, -0.11, sz), 0.07, IRON("a"), scale=(1, 0.6, 1), seg=16, rings=8)
	for k in range(6):
		a = 2 * math.pi * k / 6 + 0.3
		kit.rivet((math.cos(a) * 0.083, -0.121, sz + math.sin(a) * 0.083), CU("b"), r=0.008)


def iron_lantern(x, y, z):
	B((0.13, 0.13, 0.02), (x, y, z + 0.01), IRON("dark"), bevel=0.004)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.016, 0.016, 0.2), (x + cx * 0.055, y + cy * 0.055, z + 0.11), IRON("a"), bevel=0.002)
	B((0.1, 0.1, 0.18), (x, y, z + 0.11), C((1.0, 0.72, 0.35), 0.3, glow=0.8), bevel=0.004)  # horn panes
	for zz in (z + 0.07, z + 0.15):
		for (sx, sy, w, d) in ((0, -0.053, 0.11, 0.008), (0, 0.053, 0.11, 0.008), (-0.053, 0, 0.008, 0.11), (0.053, 0, 0.008, 0.11)):
			B((w, d, 0.008), (x + sx, y + sy, zz), IRON("dark"), bevel=0)
	B((0.13, 0.13, 0.02), (x, y, z + 0.215), IRON("dark"), bevel=0.004)
	kit.cone(0.095, 0.02, 0.07, (x, y, z + 0.255), IRON("a"), rot=(0, 0, 45), verts=4, bevel=0.003)
	kit.ring(0.02, 0.006, (x, y, z + 0.31), IRON("a"), rot=(90, 0, 0), seg=10)


def clay_lamp(x, y, zb, ztop):
	m = kit.tex_mat("clay", "b")
	lathe([(0, zb), (0.05, zb + 0.005), (0.07, zb + 0.03), (0.072, zb + 0.05), (0.062, zb + 0.052), (0.058, zb + 0.032), (0, zb + 0.03)], (x, y), m)
	kit.cylinder(0.056, 0.006, (x, y, zb + 0.036), C((0.2, 0.14, 0.06), 0.3), verts=16, bevel=0)  # oil
	B((0.06, 0.032, 0.02), (x + 0.085, y, zb + 0.045), m, bevel=0.006)
	B((0.006, 0.006, 0.014), (x + 0.108, y, zb + 0.06), kit.mat("charcoal"), bevel=0)
	flame_at(x + 0.108, y, zb + 0.064)
	kit.ring(0.02, 0.006, (x, y, ztop), IRON("a"), rot=(90, 0, 0), seg=10)
	for k in range(3):
		a = math.pi / 2 + k * 2 * math.pi / 3
		log((x + math.cos(a) * 0.066, y + math.sin(a) * 0.066, zb + 0.048), (x, y, ztop - 0.017), 0.004, IRON("dark"), seg=5, rings=1, ends=False, bend=0)


def hm_lamp_history_board():
	posts2((-0.42, 0.42), 1.06)
	board(1.1, 1.0, 1.75)
	B((1.14, 0.08, 0.04), (0, 0.0, 1.77), W("dark"), bevel=0.006)
	B((1.14, 0.03, 0.05), (0, -0.012, 1.03), W("dark"), bevel=0.006)
	for x in (-0.53, 0.53):
		kit.rivet((x, -0.03, 1.03), CU("dark"), r=0.011)
	for i, x in enumerate((-0.35, 0.0, 0.35)):
		B((0.07, 0.014, 0.24), (x, -0.004, 1.55), IRON("dark"), bevel=0.004)
		for z in (1.46, 1.64):
			kit.rivet((x, -0.012, z), CU("dark"), r=0.009)
		log((x, 0.0, 1.62), (x, -0.23, 1.62), 0.014, IRON("a"), seg=6, rings=2, ends=False, bend=0.01)
		log((x, 0.0, 1.47), (x, -0.15, 1.62), 0.01, IRON("a"), seg=5, rings=1, ends=False, bend=0)
		kit.cylinder(0.018, 0.02, (x, -0.235, 1.62), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.003)
		if i == 0:
			clay_lamp(x, -0.2, 1.33, 1.6)
		elif i == 1:
			iron_lantern(x, -0.2, 1.276)
		else:
			lantern_body((x, -0.2, 1.25))
		label(x, 1.13, 0.0, w=0.13, h=0.034, marks=i + 1)


def hm_bat_skull_plaque():
	head = monster_head("creatures/cave_bat_mossy", 0.9, ("body",), [((0, 0.03, 0), (0, 1, 0)), ((0, 0, 0.16), (0, 0, -1))])
	head_panel(0.5, 0.56, head)


def hm_heirloom_axe():
	wall_post(1.0)
	board(0.8, 0.95, 1.6)
	B((0.84, 0.07, 0.04), (0, 0.01, 1.62), W("dark"), bevel=0.006)
	lint = B((0.7, 0.09, 0.16), (0, -0.03, 1.05), T("limestone", "b"), bevel=0.012)
	cut = rune_row(-0.28, 0.28, 1.05, -0.075, h=0.075, w=0.012, depth=0.01, seed=11)
	cut += groove_path([(-0.32, 0.993), (0.32, 0.993)], -0.075, w=0.01, depth=0.008) + groove_path([(-0.32, 1.107), (0.32, 1.107)], -0.075, w=0.01, depth=0.008)
	cut += [kit.gem((0.35, -0.075, 1.13), (0.03, 0.03, 0.03), T("limestone", "a"), seed=2), kit.gem((-0.35, -0.07, 0.975), (0.025, 0.03, 0.025), T("limestone", "a"), seed=5)]
	carve(lint, cut)
	for x in (-0.22, 0.2):
		B((0.05, 0.012, 0.1), (x, -0.003, 1.33), IRON("dark"), bevel=0.003)
		log((x, 0.0, 1.3), (x, -0.1, 1.3), 0.012, IRON("a"), seg=6, rings=1, ends=False, bend=0)
		log((x, -0.1, 1.3), (x, -0.1, 1.36), 0.01, IRON("a"), seg=6, rings=1, ends=False, bend=0)
		kit.rivet((x, -0.01, 1.365), CU("dark"), r=0.008)
	hy, hz = -0.07, 1.333
	log((-0.38, hy, hz), (0.33, hy, hz), 0.022, W("dark"), seg=8, rings=3, bend=0.01)
	cheek = [(0.27, 1.3), (0.235, 1.215), (0.365, 1.215), (0.33, 1.3), (0.33, 1.366), (0.365, 1.451), (0.235, 1.451), (0.27, 1.366)]
	slab(cheek, -0.1, -0.04, IRON("dark"))
	for (za, zb) in ((1.213, 1.17), (1.453, 1.496)):
		slab([(0.235, za), (0.365, za), (0.392, zb), (0.208, zb)], -0.083, -0.057, IRON("a"))
	slab([(0.262, 1.31), (0.338, 1.31), (0.338, 1.356), (0.262, 1.356)], -0.106, -0.034, CU("b"))  # copper band round the eye
	for x in (0.28, 0.32):
		kit.rivet((x, -0.108, hz), CU("dark"), r=0.007)
	for x in (-0.33, -0.3, -0.27, -0.24):
		kit.ring(0.024, 0.006, (x, hy, hz), LEATHER(), rot=(0, 90, 0), seg=10)
	kit.cylinder(0.026, 0.025, (-0.385, hy, hz), CU("b"), rot=(0, 90, 0), verts=10, bevel=0.003)
	kit.ring(0.03, 0.006, (-0.41, hy, hz - 0.04), CU("dark"), rot=(90, 0, 0), seg=10)
	log((-0.4, hy, hz - 0.02), (-0.408, hy, hz - 0.012), 0.005, CU("dark"), seg=5, rings=1, ends=False, bend=0)


def hm_vein_slice_frame():
	wall_post(1.0)
	cz = 1.3
	for (w, h, x, z) in ((0.62, 0.06, 0, cz + 0.25), (0.62, 0.06, 0, cz - 0.25), (0.06, 0.44, -0.28, cz), (0.06, 0.44, 0.28, cz)):
		B((w, 0.06, h), (x, 0.03, z), W("b"), bevel=0.01)
	B((0.52, 0.02, 0.46), (0, 0.05, cz), W("dark"), bevel=0.004)
	for (cx, cz_) in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
		B((0.07, 0.012, 0.07), (cx * 0.28, -0.002, cz + cz_ * 0.25), CU("b"), bevel=0.003)
	r = __import__("random").Random(4)
	outline = [(math.cos(2 * math.pi * k / 14) * 0.2 * r.uniform(0.86, 1.04), cz + math.sin(2 * math.pi * k / 14) * 0.17 * r.uniform(0.86, 1.04)) for k in range(14)]
	slab([(x * 1.05, cz + (z - cz) * 1.06) for x, z in outline], 0.0, 0.045, T("basalt", "a"))  # rough outer rind
	sl = slab(outline, -0.02, 0.04, T("basalt", "b"))
	cut = groove_path([(-0.19, 1.24), (-0.1, 1.27), (-0.02, 1.25), (0.07, 1.3), (0.19, 1.33)], -0.02, w=0.022, depth=0.01, m=CU("b"))
	cut += groove_path([(-0.02, 1.25), (0.02, 1.19), (0.08, 1.16)], -0.02, w=0.012, depth=0.008, m=CU("b"))
	cut += groove_path([(-0.12, 1.42), (-0.05, 1.36), (0.03, 1.38), (0.1, 1.33)], -0.02, w=0.016, depth=0.008, m=SILVER())
	cut += groove_path([(-0.15, 1.18), (-0.06, 1.15), (0.0, 1.13)], -0.02, w=0.014, depth=0.008, m=GOLD())
	carve(sl, cut)
	for k in (2, 5, 9, 12):  # copper clips over the rim
		x, z = outline[k]
		B((0.035, 0.03, 0.035), (x, -0.012, z), CU("dark"), bevel=0.004)
	label(0, cz - 0.25, -0.0, w=0.14, h=0.03)


# ================= Shelves and racks =================
def flask(x, y, z, kind, rgb, gl=0.0, seal=False):
	m = C(rgb, 0.15, glow=gl)
	if kind == 0:
		lathe([(0, z), (0.03, z + 0.002), (0.048, z + 0.03), (0.05, z + 0.055), (0.04, z + 0.085), (0.016, z + 0.11), (0.014, z + 0.15), (0, z + 0.15)], (x, y), m)
		top, nr, fr, lz = z + 0.15, 0.014, 0.05, z + 0.05
	elif kind == 1:
		B((0.068, 0.068, 0.15), (x, y, z + 0.075), m, bevel=0.01)
		kit.cone(0.04, 0.015, 0.04, (x, y, z + 0.168), m, verts=4, rot=(0, 0, 45), bevel=0.003)
		kit.cylinder(0.013, 0.04, (x, y, z + 0.2), m, verts=10, bevel=0.002)
		top, nr, fr, lz = z + 0.22, 0.013, 0.038, z + 0.07
	else:
		lathe([(0, z), (0.045, z + 0.003), (0.05, z + 0.06), (0.034, z + 0.08), (0.03, z + 0.1), (0, z + 0.1)], (x, y), m)
		top, nr, fr, lz = z + 0.1, 0.03, 0.049, z + 0.035
	kit.cylinder(nr * 0.95, 0.03, (x, y, top + 0.008), C((0.55, 0.4, 0.26), 0.9), verts=10, bevel=0.003)
	if seal:
		kit.cylinder(nr * 1.2, 0.012, (x, y, top + 0.022), C((0.42, 0.1, 0.08), 0.5), verts=10, bevel=0.003)
	B((0.036, 0.006, 0.03), (x, y - fr + 0.002, lz), PAPER(), bevel=0.001)


def hm_potion_rack():
	board(0.84, 0.0, 0.95)
	for x in (-0.42, 0.42):
		B((0.04, 0.17, 0.95), (x, -0.075, 0.475), W("dark"), bevel=0.008)
	B((0.92, 0.2, 0.04), (0, -0.07, 0.97), W("dark"), bevel=0.008)
	cols = [((0.45, 0.12, 0.1), 0.0), ((0.15, 0.3, 0.5), 0.3), ((0.25, 0.42, 0.18), 0.25), ((0.55, 0.36, 0.1), 0.0), ((0.32, 0.18, 0.42), 0.2)]
	for t, z in enumerate((0.04, 0.35, 0.66)):
		B((0.82, 0.17, 0.03), (0, -0.075, z), W("abc"[t]), bevel=0.006)
		top = z + 0.015
		B((0.82, 0.02, 0.025), (0, -0.142, top + 0.055), W("dark"), bevel=0.004)
		for x in (-0.38, 0.38):
			kit.rivet((x, -0.153, top + 0.055), CU("dark"), r=0.007)
		for k, x in enumerate((-0.3, -0.15, 0.0, 0.15, 0.3)):
			rgb, gl = cols[(k + t * 2) % 5]
			flask(x, -0.08, top - 0.002, (k + t) % 3, rgb, gl, seal=(k + t) % 2 == 0)


def scroll(x, y0, y1, z, r, seal=None):
	kit.cylinder(r, y1 - y0, (x, (y0 + y1) / 2, z), PAPER(), rot=(90, 0, 0), verts=12, bevel=0.003)
	kit.cylinder(r * 0.35, 0.006, (x, y0 - 0.001, z), C((0.6, 0.52, 0.38), 0.95), rot=(90, 0, 0), verts=8, bevel=0)  # rolled core
	kit.ring(r * 0.75, 0.003, (x, y0 - 0.001, z), C((0.68, 0.6, 0.44), 0.95), rot=(90, 0, 0), seg=12)
	if seal:
		kit.ring(r + 0.002, 0.005, (x, y0 + 0.05, z), C(seal, 0.9), rot=(90, 0, 0), seg=12)
		kit.cylinder(0.013, 0.008, (x, y0 + 0.05, z - r - 0.004), C((0.5, 0.1, 0.08), 0.5), verts=8, bevel=0.002)


def hm_scroll_lattice():
	H, Wd, D = 1.0, 0.9, 0.3
	for x in (-Wd / 2, Wd / 2):
		B((0.05, D, H), (x, 0, H / 2), W("dark"), bevel=0.01)
	for z in (0.035, H - 0.025):
		B((Wd + 0.05, D, 0.05), (0, 0, z), W("dark"), bevel=0.01)
	B((Wd + 0.1, D + 0.04, 0.04), (0, -0.01, H + 0.015), W("b"), bevel=0.01)
	B((Wd - 0.02, 0.02, H - 0.04), (0, D / 2 - 0.012, H / 2), W("c"), bevel=0.004)
	xl, xr, zb, zt = -Wd / 2 + 0.025, Wd / 2 - 0.025, 0.06, H - 0.05
	sp = 0.2
	for sgn in (1, -1):  # boards along x + sgn*z = c
		for i in range(-8, 9):
			cc = i * sp + 0.0 + (0.5 if sgn > 0 else -0.5) * 1.0
			pts = []
			for x in (xl, xr):
				z = (cc - x) * sgn
				if zb <= z <= zt:
					pts.append((x, z))
			for z in (zb, zt):
				x = cc - sgn * z
				if xl <= x <= xr:
					pts.append((x, z))
			if len(pts) < 2:
				continue
			(ax, az), (bx, bz) = pts[0], pts[1]
			L = math.hypot(bx - ax, bz - az)
			if L < 0.05:
				continue
			B((L, D - 0.04 - 0.016 * (sgn < 0), 0.02), ((ax + bx) / 2, -0.01 + 0.007 * (sgn < 0), (az + bz) / 2), W("abc"[i % 3]), bevel=0.003, rot=(0, sgn * 45, 0))
	seals = [None, (0.55, 0.15, 0.12), None, (0.25, 0.35, 0.55), None, (0.55, 0.45, 0.2)]
	n = 0
	for i in range(-8, 9):
		for j in range(-8, 9):
			c1 = i * sp + 0.5  # x + z
			c2 = j * sp - 0.5  # x - z
			cx, czc = (c1 + sp / 2 + c2 + sp / 2) / 2, ((c1 + sp / 2) - (c2 + sp / 2)) / 2
			if not (xl + 0.1 <= cx <= xr - 0.1 and zb + 0.1 <= czc <= zt - 0.1):
				continue
			r = 0.038
			zc = czc - 0.1 + 0.0141 + r * math.sqrt(2) - 0.003
			if n % 5 == 3:  # leather scroll case with copper caps
				kit.cylinder(r, 0.22, (cx, -0.03, zc), LEATHER(), rot=(90, 0, 0), verts=12, bevel=0.004)
				for yy in (-0.135, 0.075):
					kit.cylinder(r + 0.004, 0.025, (cx, yy, zc), CU("b"), rot=(90, 0, 0), verts=12, bevel=0.003)
			else:
				scroll(cx, -0.13 + 0.01 * (n % 3), 0.12, zc, r, seals[n % 6])
			n += 1


def crock(x, y, z, r, h, v):
	m = kit.tex_mat("clay", v)
	lathe([(0, z), (r * 0.8, z + 0.003), (r, z + h * 0.35), (r * 0.95, z + h * 0.75), (r * 0.72, z + h * 0.92), (r * 0.75, z + h), (0, z + h)], (x, y), m)
	kit.ring(r * 0.76, 0.008, (x, y, z + h - 0.004), m, seg=16)
	kit.cylinder(r * 0.88, 0.012, (x, y, z + h + 0.004), C((0.66, 0.56, 0.42), 0.95), verts=16, bevel=0.004)  # tied cloth top
	kit.ring(r * 0.77, 0.007, (x, y, z + h - 0.02), ROPE(), seg=16)
	B((r * 0.7, 0.005, h * 0.22), (x, y - r * 0.98, z + h * 0.45), PAPER(), bevel=0.001)


def preserve_jar(x, y, z, r, h, rgb):
	kit.cylinder(r * 0.92, h * 0.78, (x, y, z + h * 0.39 + 0.002), C(rgb, 0.4), verts=14, bevel=0.004)
	kit.cylinder(r, h, (x, y, z + h / 2), glass((0.75, 0.85, 0.8), 0.3), verts=14, bevel=0.004)
	kit.cylinder(r * 1.05, 0.025, (x, y, z + h + 0.01), W("c"), verts=14, bevel=0.004)
	kit.ring(r + 0.003, 0.006, (x, y, z + h - 0.008), ROPE(), seg=14)
	kit.cylinder(0.012, 0.012, (x, y, z + h + 0.027), W("c"), verts=8, bevel=0.002)


def hm_preserve_shelf():
	Wd, D, H = 0.94, 0.36, 1.25
	for x in (-Wd / 2 + 0.03, Wd / 2 - 0.03):
		for y in (-D / 2 + 0.03, D / 2 - 0.03):
			B((0.055, 0.055, H), (x, y, H / 2), W("dark"), bevel=0.008)
		for z in (0.3, 0.7, 1.08):
			B((0.03, D - 0.06, 0.05), (x, 0, z), W("dark"), bevel=0.005)
	for z in (0.4, 0.82, 1.18):
		B((Wd - 0.06, 0.02, 0.07), (0, D / 2 - 0.03, z), W("b"), bevel=0.005)
	shelves = (0.08, 0.5, 0.92)
	for k, z in enumerate(shelves):
		for i in range(3):
			plank((Wd - 0.01, D / 3 - 0.008, 0.03), (0, -D / 2 + D / 3 * (i + 0.5), z), m=W("abc"[(i + k) % 3]))
	B((Wd + 0.04, D + 0.04, 0.04), (0, 0, H + 0.015), W("b"), bevel=0.008)
	t0, t1, t2 = (z + 0.015 for z in shelves)
	crock(-0.27, -0.01, t0, 0.12, 0.3, "a")
	crock(0.27, -0.01, t0, 0.12, 0.28, "c")
	crock(0.0, 0.0, t0, 0.09, 0.22, "b")
	for k, (x, rgb) in enumerate(((-0.32, (0.55, 0.5, 0.15)), (-0.11, (0.55, 0.22, 0.14)), (0.11, (0.7, 0.48, 0.14)), (0.32, (0.35, 0.42, 0.16)))):
		preserve_jar(x, -0.02, t1, 0.07, 0.2 - 0.03 * (k % 2), rgb)
	for k, x in enumerate((-0.36, -0.22, -0.08, 0.06)):  # little sealed pots
		m = kit.tex_mat("clay", "abc"[k % 3])
		lathe([(0, t2), (0.045, t2 + 0.002), (0.05, t2 + 0.06), (0.036, t2 + 0.09), (0.04, t2 + 0.1), (0, t2 + 0.1)], (x, -0.05), m)
		kit.cylinder(0.034, 0.012, (x, -0.05, t2 + 0.102), C((0.45, 0.12, 0.08), 0.5), verts=10, bevel=0.003)
		B((0.04, 0.005, 0.03), (x, -0.099, t2 + 0.045), PAPER(), bevel=0.001)
	m = kit.tex_mat("clay", "b")  # stoneware jug
	lathe([(0, t2), (0.08, t2 + 0.004), (0.095, t2 + 0.09), (0.07, t2 + 0.17), (0.035, t2 + 0.21), (0.04, t2 + 0.24), (0, t2 + 0.24)], (0.27, -0.01), m)
	kit.ring(0.06, 0.012, (0.35, -0.01, t2 + 0.15), m, rot=(90, 0, 0), seg=12)
	kit.cylinder(0.03, 0.03, (0.27, -0.01, t2 + 0.25), C((0.55, 0.4, 0.26), 0.9), verts=10, bevel=0.003)
	for x in (-0.2, 0.0, 0.2):  # ladle and spoons on hooks under the top shelf front
		log((x, -D / 2 + 0.02, 0.9), (x, -D / 2 - 0.01, 0.86), 0.005, IRON("a"), seg=5, rings=1, ends=False, bend=0)
		B((0.02, 0.01, 0.2), (x, -D / 2 - 0.01, 0.75), W("c"), bevel=0.003)
		kit.ring(0.009, 0.004, (x, -D / 2 - 0.01, 0.86), IRON("a"), rot=(90, 0, 0), seg=8)
		lathe([(0, 0.6), (0.035 if x == 0 else 0.025, 0.615), (0.04 if x == 0 else 0.028, 0.645), (0, 0.64)], (x, -D / 2 - 0.01), W("c"))


def tankard(x, y, z, lidded, m):
	kit.cone(0.052, 0.045, 0.13, (x, y, z + 0.065), m, verts=14, bevel=0.005)
	for zz in (z + 0.025, z + 0.105):
		kit.ring(0.05, 0.006, (x, y, zz), CU("b") if not lidded else m, seg=14)
	kit.ring(0.04, 0.01, (x + 0.06, y, z + 0.07), m, rot=(90, 0, 0), seg=10)
	if lidded:
		kit.cylinder(0.05, 0.012, (x, y, z + 0.135), m, verts=14, bevel=0.003)
		kit.cylinder(0.02, 0.012, (x, y, z + 0.146), m, verts=10, bevel=0.003)
		B((0.03, 0.02, 0.025), (x + 0.055, y, z + 0.14), m, bevel=0.004)  # thumb lift


def horn(x, y, z):
	kit.cylinder(0.04, 0.03, (x, y, z + 0.015), W("dark"), verts=10, bevel=0.004)
	pts = [(x, y, z + 0.03), (x + 0.01, y, z + 0.09), (x + 0.04, y, z + 0.16), (x + 0.03, y, z + 0.23)]
	tube_r(pts, [0.018, 0.026, 0.036, 0.045], C((0.42, 0.33, 0.22), 0.6), seg=12)
	kit.ring(0.045, 0.008, (x + 0.03, y, z + 0.228), CU("b"), seg=14)
	kit.cylinder(0.02, 0.025, (x, y, z + 0.035), CU("b"), verts=8, bevel=0.003)


def hm_tankard_shelf():
	wall_post(1.0)
	B((0.96, 0.05, 0.64), (0, 0.025, 1.27), W("b"), bevel=0.012)
	for x in (-0.46, 0.46):
		B((0.04, 0.2, 0.66), (x, -0.08, 1.27), W("dark"), bevel=0.008)
	for z in (0.97, 1.27):
		B((0.9, 0.2, 0.035), (0, -0.08, z), W("abc"[int(z * 10) % 3]), bevel=0.008)
		B((0.9, 0.015, 0.03), (0, -0.175, z + 0.03), W("dark"), bevel=0.004)
	B((1.0, 0.24, 0.04), (0, -0.09, 1.6), W("dark"), bevel=0.008)
	pewter = C((0.42, 0.42, 0.42), 0.35, metal=0.7)
	t0 = 0.9875
	for k, x in enumerate((-0.33, -0.165, 0.0, 0.165, 0.33)):
		tankard(x - 0.02, -0.09, t0, k % 2 == 0, pewter if k % 2 == 0 else W("c"))
	t1 = 1.2875
	horn(-0.33, -0.09, t1)
	horn(0.3, -0.09, t1)
	for x in (-0.11, 0.07):  # copper goblets
		lathe([(0, t1), (0.04, t1 + 0.002), (0.035, t1 + 0.01), (0.008, t1 + 0.03), (0.008, t1 + 0.1), (0.04, t1 + 0.12), (0.045, t1 + 0.17), (0.04, t1 + 0.17), (0.035, t1 + 0.125), (0, t1 + 0.12)], (x, -0.09), CU("b"))
		kit.ring(0.044, 0.004, (x, -0.09, t1 + 0.168), CU("dark"), seg=14)
	for x in (-0.3, -0.1, 0.1, 0.3):  # cups hanging under the bottom shelf
		log((x, -0.04, 0.955), (x, -0.07, 0.92), 0.005, IRON("a"), seg=5, rings=1, ends=False, bend=0)
		kit.ring(0.02, 0.007, (x, -0.07, 0.905), W("c"), rot=(90, 0, 0), seg=10)
		kit.cylinder(0.04, 0.08, (x - 0.045, -0.07, 0.89), W("c"), verts=12, bevel=0.005)
		kit.ring(0.04, 0.005, (x - 0.045, -0.07, 0.925), CU("b"), seg=12)


def ingot(x, y, z, along, m):
	if along == "y":
		kit.taper(0.05, 0.12, 0.04, 0.104, 0.032, (x, y, z), m, bevel=0.004)
	else:
		kit.taper(0.12, 0.05, 0.104, 0.04, 0.032, (x, y, z), m, bevel=0.004)


def ingot_stack(x, y, z, m):
	for dx in (-0.056, 0.0, 0.056):
		ingot(x + dx, y, z, "y", m)
	for dy in (-0.028, 0.028):
		ingot(x, y + dy, z + 0.029, "x", m)
	ingot(x, y, z + 0.058, "y", m)


def hm_ingot_display():
	Wd = 0.94
	for i, (d, yc, h) in enumerate(((0.45, 0.0, 0.15), (0.3, 0.075, 0.3), (0.15, 0.15, 0.45))):
		B((Wd, d, 0.15), (0, yc, h - 0.075), W("abc"[i]), bevel=0.01)
		B((Wd + 0.02, d + 0.02, 0.025), (0, yc - 0.005, h + 0.008), W("dark"), bevel=0.006)
		for x in (-Wd / 2, Wd / 2):
			B((0.03, 0.035, 0.15), (x, yc - d / 2 + 0.01, h - 0.075), CU("b"), bevel=0.004)
			kit.rivet((x * 1.02, yc - d / 2 - 0.006, h - 0.075), CU("dark"), r=0.008)
	for x in (-0.5, 0.5):
		B((0.03, 0.47, 0.47), (x * 0.97, 0.0, 0.235), W("dark"), bevel=0.006)
	top = lambda h: h + 0.02  # noqa: E731
	ingot_stack(-0.22, -0.15, top(0.15), CU("b"))
	ingot_stack(0.22, -0.15, top(0.15), IRON("a"))
	ingot_stack(-0.2, 0.0, top(0.3), SILVER())
	ingot_stack(0.2, 0.0, top(0.3), CU("dark"))
	B((0.16, 0.08, 0.03), (0, 0.15, top(0.45) + 0.012), CU("dark"), bevel=0.004)  # the gold bar's little stand
	ingot(0, 0.15, top(0.45) + 0.025, "x", GOLD())
	for i, (x, y, z) in enumerate(((-0.22, -0.225, 0.075), (0.22, -0.225, 0.075), (-0.2, -0.075, 0.225), (0.2, -0.075, 0.225), (0, 0.075, 0.375))):
		label(x, z, y, w=0.12, h=0.03, marks=i // 2 + 1)


def gem_jar(x, y, z, rgb, seed):
	kit.cylinder(0.05, 0.014, (x, y, z + 0.007), CU("dark"), verts=14, bevel=0.003)
	g = C(rgb, 0.15, glow=0.3)
	r = __import__("random").Random(seed)
	for k in range(9):
		a = r.uniform(0, 6.28)
		rr = 0.026 if k < 6 else 0.012
		kit.gem((x + math.cos(a + k) * rr, y + math.sin(a + k) * rr, z + 0.022 + 0.02 * (k // 6) + 0.004 * (k % 2)), (0.017, 0.015, 0.013), g, seed=seed + k)
	kit.cylinder(0.046, 0.13, (x, y, z + 0.078), glass((0.8, 0.9, 0.92), 0.22), verts=14, bevel=0.004)
	kit.cylinder(0.05, 0.02, (x, y, z + 0.15), CU("b"), verts=14, bevel=0.004)
	kit.cylinder(0.014, 0.02, (x, y, z + 0.168), CU("dark"), verts=8, bevel=0.003)


def hm_gem_jar_shelf():
	wall_post(1.0)
	B((0.86, 0.05, 0.6), (0, 0.025, 1.29), W("b"), bevel=0.012)
	for x in (-0.41, 0.41):
		B((0.04, 0.18, 0.62), (x, -0.07, 1.29), W("dark"), bevel=0.008)
	B((0.92, 0.22, 0.04), (0, -0.08, 1.61), W("dark"), bevel=0.008)
	gems = [(0.3, 0.6, 0.95), (0.85, 0.2, 0.15), (0.25, 0.75, 0.35), (0.55, 0.25, 0.75), (0.95, 0.75, 0.2), (0.4, 0.85, 0.85), (0.9, 0.45, 0.55)]
	for t, z in enumerate((1.0, 1.3)):
		B((0.8, 0.18, 0.035), (0, -0.08, z), W("abc"[t]), bevel=0.008)
		B((0.8, 0.015, 0.035), (0, -0.168, z + 0.025), W("dark"), bevel=0.004)
		xs = (-0.3, -0.1, 0.1, 0.3) if t == 0 else (-0.3, -0.1, 0.1)
		for k, x in enumerate(xs):
			gem_jar(x, -0.08, z + 0.0175, gems[(k + t * 4) % 7], seed=k * 11 + t)
			B((0.06, 0.006, 0.02), (x, -0.178, z + 0.025), CU("b"), bevel=0.002)
	x, y, z = 0.3, -0.08, 1.3175  # small balance for weighing gems
	kit.cylinder(0.05, 0.015, (x, y, z + 0.0075), W("dark"), verts=12, bevel=0.003)
	kit.cylinder(0.008, 0.16, (x, y, z + 0.09), CU("dark"), verts=8, bevel=0.002)
	B((0.17, 0.012, 0.012), (x, y, z + 0.17), CU("b"), bevel=0.002)
	kit.cone(0.012, 0.0, 0.02, (x, y, z + 0.186), CU("b"), verts=6, bevel=0)
	for s_ in (-1, 1):
		px = x + s_ * 0.075
		for k in range(3):
			a = 2 * math.pi * k / 3
			log((px, y, z + 0.165), (px + math.cos(a) * 0.03, y + math.sin(a) * 0.03, z + 0.075), 0.002, CU("dark"), seg=4, rings=1, ends=False, bend=0)
		lathe([(0, z + 0.07), (0.035, z + 0.075), (0.036, z + 0.082), (0, z + 0.076)], (px, y), CU("b"))
	kit.gem((x - 0.075, y, z + 0.085), (0.012, 0.011, 0.01), C(gems[1], 0.15, glow=0.3), seed=3)


def bundle(x, y, z, ln, rgb, seed):
	"""Dried stalks tied together and hung upside down from (x, y, z): twine loop, tie, stalks, seed heads."""
	r = __import__("random").Random(seed)
	stem, head = C((0.45, 0.4, 0.24), 0.9), C(rgb, 0.9)
	tie = z - 0.06
	log((x, y, z - 0.01), (x, y, tie), 0.004, ROPE(), seg=5, rings=1, ends=False, bend=0)
	kit.ring(0.016, 0.006, (x, y, tie), ROPE(), seg=10)
	kit.ring(0.014, 0.006, (x, y, tie - 0.015), ROPE(), seg=10)
	for k in range(9):
		a = 2 * math.pi * k / 9 + r.uniform(-0.2, 0.2)
		sp = 0.03 + 0.03 * r.random()
		end = (x + math.cos(a) * sp, y + math.sin(a) * sp, tie - ln * r.uniform(0.85, 1.05))
		log((x + math.cos(a) * 0.011, y + math.sin(a) * 0.011, tie + 0.01), end, 0.0035, stem, seg=4, rings=1, ends=False, bend=0)
		d = Vector(end) - Vector((x, y, tie))
		aim_obj(kit.cone(0.011, 0.002, 0.05, tuple(Vector(end) + d.normalized() * 0.02), head, verts=6, bevel=0), d)


def hm_herb_ladder():
	H = 1.42
	m = lambda: W("abc"[rng.randrange(3)])  # noqa: E731
	for sy in (-1, 1):
		for x in (-0.36, 0.36):
			log((x, sy * 0.3, 0.0), (x, sy * 0.035, H), 0.025, m(), seg=7, rings=3, bend=0.01)
		for z in (0.42, 0.78, 1.12):
			yy = sy * (0.3 - 0.265 * z / H)
			log((-0.39, yy, z), (0.39, yy, z), 0.016, m(), seg=6, rings=2, ends=False, bend=0.01)
	log((-0.43, 0.0, H + 0.01), (0.43, 0.0, H + 0.01), 0.028, m(), seg=8, rings=2, bend=0.01)
	for x in (-0.36, 0.36):
		for dz in (-0.03, 0.0, 0.03):
			kit.ring(0.04, 0.009, (x, 0.0, H - 0.04 + dz), ROPE(), rot=(0, 90, 0), seg=12)
	for x in (-0.36, 0.36):  # rope spreaders so the legs can't slide apart
		log((x, -0.27, 0.12), (x, 0.27, 0.12), 0.007, ROPE(), seg=5, rings=1, ends=False, bend=0)
	cols = [(0.42, 0.35, 0.55), (0.72, 0.6, 0.25), (0.42, 0.48, 0.32), (0.6, 0.38, 0.22)]
	n = 0
	for z in (0.78, 1.12):
		yy = -(0.3 - 0.265 * z / H)
		for x in (-0.24, -0.08, 0.08, 0.24):
			bundle(x, yy, z - 0.012, 0.2, cols[n % 4], n * 7 + 1)
			n += 1
	for x in (-0.25, 0.0, 0.25):
		bundle(x, 0.0, H - 0.016, 0.22, cols[n % 4], n * 7 + 1)
		n += 1


def book_up(x, y, z, t, d, h, rgb, m_band):
	cover = C(rgb, 0.85)
	for s_ in (-1, 1):
		B((0.006, d, h), (x + s_ * (t / 2 - 0.003), y, z + h / 2), cover, bevel=0.0015)
	B((t, 0.008, h), (x, y - d / 2 + 0.004, z + h / 2), cover, bevel=0.002)
	B((t - 0.01, d - 0.012, h - 0.012), (x, y + 0.004, z + h / 2), PAPER(), bevel=0.001)
	for zz in (z + h * 0.2, z + h * 0.8):
		B((t + 0.003, 0.006, 0.008), (x, y - d / 2 - 0.001, zz), cover, bevel=0.001)
	B((t * 0.55, 0.004, h * 0.22), (x, y - d / 2 - 0.0005, z + h * 0.5), m_band, bevel=0.0005)


def book_flat(x, y, z, w, d, t, rgb):
	cover = C(rgb, 0.85)
	for zz in (z + 0.003, z + t - 0.003):
		B((w, d, 0.006), (x, y, zz), cover, bevel=0.0015)
	B((0.008, d, t), (x - w / 2 + 0.004, y, z + t / 2), cover, bevel=0.002)
	B((w - 0.012, d - 0.012, t - 0.01), (x + 0.002, y, z + t / 2), PAPER(), bevel=0.001)


def hm_book_nook():
	st = lambda v: T("limestone", v)  # noqa: E731
	D = 0.3
	B((0.76, 0.04, 1.55), (0, 0.13, 0.775), st("dark"), bevel=0.006)
	for s_ in (-1, 1):  # two piers of stacked blocks
		for i in range(6):
			h = 0.2
			B((0.14 + J(0.006), D - 0.03, h - 0.008), (s_ * 0.33, 0.0, 0.1 + i * h), st("abc"[(i + (s_ > 0)) % 3]), bevel=0.012)
	B((0.84, D + 0.02, 0.1), (0, -0.005, 0.05), st("b"), bevel=0.012)
	sill = B((0.52, D - 0.04, 0.06), (0, 0.0, 0.12), st("c"), bevel=0.008)
	carve(sill, rune_row(-0.2, 0.2, 0.12, -0.13, h=0.04, w=0.008, depth=0.007, seed=3))
	cz, ri, ro = 1.2, 0.26, 0.4
	n = 7
	for k in range(n):
		a0, a1 = math.pi * k / n + 0.006, math.pi * (k + 1) / n - 0.006
		pts = []
		for a in (a0, (a0 + a1) / 2, a1):
			pts.append((math.cos(a) * ri, cz + math.sin(a) * ri))
		for a in (a1, (a0 + a1) / 2, a0):
			rr = ro + (0.04 if k == n // 2 else 0.0)
			pts.append((math.cos(a) * rr, cz + math.sin(a) * rr))
		slab(pts, -D / 2 + (-0.015 if k == n // 2 else 0.005), D / 2 - 0.018, st("abc"[k % 3]))
	for z in (0.42, 0.82):
		B((0.54, D - 0.06, 0.03), (0, 0.0, z), W("b"), bevel=0.006)
	cols = [(0.42, 0.14, 0.1), (0.2, 0.25, 0.38), (0.3, 0.32, 0.18), (0.45, 0.3, 0.14), (0.28, 0.16, 0.22), (0.18, 0.28, 0.24)]
	band = GOLD()
	x = -0.245
	t0 = 0.435
	for k in range(8):
		t, h = 0.03 + 0.008 * (k % 3), 0.2 + 0.03 * ((k * 5) % 3)
		book_up(x + t / 2, 0.0, t0, t, 0.17, h, cols[k % 6], band)
		x += t + 0.002
	B((0.012, 0.1, 0.14), (x + 0.008, 0.0, t0 + 0.07), IRON("dark"), bevel=0.003)  # bookend
	B((0.06, 0.1, 0.012), (x + 0.03, 0.0, t0 + 0.006), IRON("dark"), bevel=0.002)
	t1 = 0.835
	for k, (w, tt) in enumerate(((0.2, 0.05), (0.18, 0.04), (0.16, 0.045))):
		book_flat(-0.13 + J(0.01), 0.0, t1 + sum(q[1] for q in ((0.2, 0.05), (0.18, 0.04), (0.16, 0.045))[:k]), w, 0.15, tt, cols[k + 2])
	x = 0.02
	for k in range(5):
		t, h = 0.028 + 0.006 * (k % 2), 0.17 + 0.025 * (k % 3)
		book_up(x + t / 2, 0.0, t1, t, 0.15, h, cols[(k + 3) % 6], band)
		x += t + 0.002
	kit.cylinder(0.04, 0.012, (0.2, -0.04, t1 + 0.006), CU("b"), verts=12, bevel=0.003)
	kit.cylinder(0.018, 0.08, (0.2, -0.04, t1 + 0.052), C((0.93, 0.86, 0.66), 0.85), verts=10, bevel=0.004)
	B((0.004, 0.004, 0.016), (0.2, -0.04, t1 + 0.098), kit.mat("charcoal"), bevel=0)
	flame_at(0.2, -0.04, t1 + 0.1)
	b0 = 0.15
	book_flat(-0.1, 0.0, b0, 0.26, 0.2, 0.07, cols[0])
	book_flat(-0.09, 0.0, b0 + 0.07, 0.22, 0.17, 0.06, cols[1])
	kit.cylinder(0.035, 0.22, (0.15, 0.0, b0 + 0.033), LEATHER(), rot=(90, 0, 0), verts=12, bevel=0.004)
	for yy in (-0.095, 0.095):
		kit.cylinder(0.039, 0.022, (0.15, yy, b0 + 0.033), CU("b"), rot=(90, 0, 0), verts=12, bevel=0.003)


# ================= Furniture =================
def hm_carved_high_chair():
	Wd, D = 0.54, 0.46
	sh = 0.42
	for x in (-Wd / 2 + 0.035, Wd / 2 - 0.035):
		B((0.065, 0.065, 0.66), (x, -D / 2 + 0.035, 0.33), W("b"), bevel=0.01)  # front legs rise to hold the arms
		B((0.075, 0.075, 1.3), (x, D / 2 - 0.04, 0.65), W("b"), bevel=0.012)  # back posts
		kit.cylinder(0.04, 0.025, (x, -D / 2 + 0.035, 0.0125), CU("dark"), verts=8, bevel=0.003)
		kit.cylinder(0.045, 0.025, (x, D / 2 - 0.04, 0.0125), CU("dark"), verts=8, bevel=0.003)
		B((0.035, D - 0.08, 0.04), (x, 0, 0.13), W("dark"), bevel=0.005)  # side stretchers
		B((0.07, D + 0.03, 0.04), (x * 1.05, -0.015, 0.68), W("c"), bevel=0.008)  # arm
		kit.cylinder(0.035, 0.08, (x * 1.05, -D / 2 - 0.035, 0.665), W("c"), rot=(0, 90, 0), verts=12, bevel=0.006)
		kit.cone(0.05, 0.03, 0.06, (x, D / 2 - 0.04, 1.33), W("dark"), verts=8, bevel=0.004)
		kit.cylinder(0.034, 0.03, (x, D / 2 - 0.04, 1.375), W("dark"), verts=8, bevel=0.004)
		kit.cone(0.034, 0.004, 0.07, (x, D / 2 - 0.04, 1.425), W("dark"), verts=8, bevel=0.003)
		kit.ring(0.045, 0.006, (x, D / 2 - 0.04, 1.3), CU("b"), seg=12)
	B((Wd - 0.07, 0.035, 0.04), (0, -D / 2 + 0.035, 0.13), W("dark"), bevel=0.005)
	front = B((Wd - 0.07, 0.03, 0.09), (0, -D / 2 + 0.035, sh - 0.06), W("b"), bevel=0.006)
	carve(front, groove_path([(-0.18, sh - 0.06), (-0.12, sh - 0.03), (-0.06, sh - 0.08), (0.0, sh - 0.03), (0.06, sh - 0.08), (0.12, sh - 0.03), (0.18, sh - 0.06)],
		-D / 2 + 0.02, w=0.009, depth=0.007))
	plank_top(Wd + 0.02, D, sh, t=0.045, n=3)
	for x in (-Wd / 2 + 0.01, Wd / 2 - 0.01):
		B((0.04, 0.04, 0.05), (x, -D / 2 + 0.01, sh), CU("b"), bevel=0.004)
	by = D / 2 - 0.04
	B((Wd - 0.08, 0.05, 0.06), (0, by, 0.52), W("c"), bevel=0.006)
	panel = B((Wd - 0.08, 0.04, 0.48), (0, by, 0.81), W("b"), bevel=0.006)
	fy = by - 0.02
	cut = groove_path([(-0.17, 0.6), (0.17, 0.6), (0.17, 1.02), (-0.17, 1.02)], fy, w=0.01, depth=0.008, closed=True)
	cut += groove_path([(0.0, 0.66), (0.0, 0.93)], fy, w=0.016, depth=0.01)  # hammer handle
	cut += groove_path([(-0.07, 0.93), (0.07, 0.93), (0.07, 0.98), (-0.07, 0.98)], fy, w=0.012, depth=0.01, closed=True)  # hammer head
	cut += groove_path([(-0.12, 0.68), (-0.05, 0.75)], fy, w=0.008, depth=0.006) + groove_path([(0.12, 0.68), (0.05, 0.75)], fy, w=0.008, depth=0.006)
	carve(panel, cut)
	crest = B((Wd - 0.04, 0.06, 0.18), (0, by, 1.15), W("c"), bevel=0.01)
	cut = groove_path([(-0.2, 1.08), (-0.12, 1.18), (-0.06, 1.12), (0.0, 1.21), (0.06, 1.12), (0.12, 1.18), (0.2, 1.08)], by - 0.03, w=0.012, depth=0.01)
	carve(crest, cut)
	for x in (-0.2, 0.2):
		kit.rivet((x, by - 0.032, 1.2), CU("b"), r=0.01)


def hm_delve_game_table():
	S, H = 0.82, 0.6
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.08, 0.08, H - 0.03), (cx * (S / 2 - 0.07), cy * (S / 2 - 0.07), (H - 0.03) / 2), W("dark"), bevel=0.012)
			kit.cylinder(0.05, 0.03, (cx * (S / 2 - 0.07), cy * (S / 2 - 0.07), 0.015), CU("dark"), verts=8, bevel=0.003)
	for s_ in (-1, 1):
		B((S - 0.2, 0.03, 0.1), (0, s_ * (S / 2 - 0.07), H - 0.09), W("b"), bevel=0.006)
		B((0.03, S - 0.2, 0.1), (s_ * (S / 2 - 0.07), 0, H - 0.09), W("b"), bevel=0.006)
		B((0.03, S - 0.2, 0.04), (s_ * (S / 2 - 0.07), 0, 0.12), W("dark"), bevel=0.005)
	B((S - 0.15, 0.04, 0.04), (0, 0, 0.12), W("dark"), bevel=0.005)
	B((0.3, 0.025, 0.07), (0, -S / 2 + 0.05, H - 0.09), W("c"), bevel=0.005)  # drawer for the pieces
	kit.cylinder(0.016, 0.03, (0, -S / 2 + 0.03, H - 0.09), CU("b"), rot=(90, 0, 0), verts=10, bevel=0.003)
	plank_top(S, S, H - 0.01, t=0.05, n=4)
	tz = H + 0.015
	B((0.6, 0.6, 0.02), (0, 0, tz + 0.005), W("dark"), bevel=0.004)
	brd = B((0.53, 0.53, 0.03), (0, 0, tz + 0.01), W("c"), bevel=0.003)
	bt = tz + 0.025
	cell = 0.07
	cut = []
	for i in range(8):
		v = -0.245 + i * cell
		cut.append(top_groove((v, -0.245), (v, 0.245), bt, w=0.008, depth=0.006))
		cut.append(top_groove((-0.245, v), (0.245, v), bt, w=0.008, depth=0.006))
	for (a, b) in (((-0.245, -0.245), (-0.035, -0.035)), ((0.245, 0.245), (0.035, 0.035)), ((-0.245, 0.245), (-0.035, 0.035)), ((0.245, -0.245), (0.035, -0.035))):
		cut.append(top_groove(a, b, bt, w=0.008))  # four diagonal tunnels to the mountain
	carve(brd, cut)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.05, 0.05, 0.006), (cx * 0.21, cy * 0.21, bt + 0.001), CU("b"), bevel=0.001)  # copper gate squares
	kit.taper(0.06, 0.06, 0.02, 0.02, 0.07, (0, 0, bt - 0.002), T("greystone", "b"), bevel=0.004)
	kit.taper(0.065, 0.065, 0.058, 0.058, 0.012, (0, 0, bt - 0.003), T("greystone", "c"), bevel=0.002)
	for team, (m, row) in enumerate(((CU("b"), -0.21), (IRON("a"), 0.21))):
		for k in range(6):
			x = -0.175 + k * cell
			if abs(x) < 0.01:
				x = 0.0
			px = -0.175 + k * 0.07 if k < 3 else -0.175 + (k + 1) * 0.07
			kit.cylinder(0.022, 0.012, (px, row, bt + 0.006), m, verts=10, bevel=0.003)
			kit.cylinder(0.013, 0.03, (px, row, bt + 0.027), m, verts=8, bevel=0.003)
			kit.cone(0.016, 0.005, 0.02, (px, row, bt + 0.05), m, verts=8, bevel=0.002)
		kx, ky = 0.0, row
		kit.cylinder(0.026, 0.014, (kx, ky, bt + 0.007), m, verts=10, bevel=0.003)
		kit.cylinder(0.015, 0.05, (kx, ky, bt + 0.038), m, verts=8, bevel=0.003)
		B((0.05, 0.018, 0.02), (kx, ky, bt + 0.07), m, bevel=0.003)  # chief's hammer head
	for k in range(3):  # two pieces already taken, standing by the board
		kit.cylinder(0.022, 0.012, (0.34, -0.3 + k * 0.05, tz + 0.006 - 0.01 + 0.01), (CU("b"), IRON("a"))[k % 2], verts=10, bevel=0.003)


def hm_map_table():
	L, D, H = 1.15, 0.7, 0.74
	for s_ in (-1, 1):  # trestle ends
		x = s_ * (L / 2 - 0.16)
		B((0.08, D - 0.08, 0.07), (x, 0, 0.035), W("dark"), bevel=0.01)
		B((0.09, 0.12, H - 0.13), (x, 0, 0.07 + (H - 0.13) / 2 - 0.005), W("b"), bevel=0.01)
		B((0.08, D - 0.12, 0.06), (x, 0, H - 0.09), W("dark"), bevel=0.01)
		for y in (-0.06, 0.06):
			kit.rivet((x, y, H - 0.06 + 0.005), W("c"), r=0.014)
		for y in (-1, 1):
			kit.rivet((x - s_ * 0.0, y * (D / 2 - 0.08), 0.075), W("c"), r=0.014)
	B((L - 0.3, 0.07, 0.08), (0, 0, 0.22), W("dark"), bevel=0.008)  # stretcher
	for y in (-0.1, 0.1):
		B((L - 0.38, 0.14, 0.02), (0, y, 0.27), W("abc"[int(y > 0)]), bevel=0.004)  # map shelf on the stretcher
	for k, (y, r) in enumerate(((-0.12, 0.04), (-0.03, 0.035), (0.06, 0.042), (0.15, 0.03))):
		zz = 0.28 + r
		kit.cylinder(r, 0.5 - 0.04 * k, (0.02 * k, y, zz), PAPER(), rot=(0, 90, 0), verts=12, bevel=0.003)
		kit.ring(r + 0.002, 0.004, (0.02 * k + 0.1, y, zz), C((0.5, 0.15, 0.1), 0.9), rot=(0, 90, 0), seg=12)
	plank_top(L, D, H - 0.02, t=0.05, n=4)
	tz = H + 0.005
	mp = B((0.72, 0.5, 0.006), (0, -0.02, tz + 0.003), PAPER(), bevel=0.001)
	ink = C((0.22, 0.15, 0.1), 0.9)
	path = [(-0.3, -0.15), (-0.18, -0.08), (-0.05, -0.12), (0.06, 0.0), (0.18, 0.05), (0.28, 0.16)]
	for (a, b) in zip(path, path[1:]):
		L2 = math.hypot(b[0] - a[0], b[1] - a[1])
		B((L2, 0.01, 0.002), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 0.02, tz + 0.0065), ink, bevel=0, rot=(0, 0, math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))))
	for (a, b) in (((-0.05, -0.12), (-0.12, -0.2)), ((0.06, 0.0), (0.02, 0.15)), ((0.18, 0.05), (0.26, -0.08))):
		L2 = math.hypot(b[0] - a[0], b[1] - a[1])
		B((L2, 0.007, 0.002), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 0.02, tz + 0.0065), ink, bevel=0, rot=(0, 0, math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))))
	for (x, y, r) in ((-0.3, -0.17, 0.035), (0.06, -0.02, 0.04), (0.28, 0.14, 0.03), (0.02, 0.13, 0.025)):  # chambers
		o = kit.ring(r, 0.003, (x, y, tz + 0.0065), ink, seg=14)
		o.scale = (1, 1, 0.5)
	for s_ in (-1, 1):  # a red X where the vein is
		B((0.04, 0.006, 0.002), (0.26, -0.1, tz + 0.007), C((0.6, 0.12, 0.08), 0.9), bevel=0, rot=(0, 0, s_ * 45))
	for (x, y) in ((-0.34, -0.25), (0.34, -0.25), (-0.34, 0.21), (0.34, 0.21)):  # stone weights with copper rings
		B((0.07, 0.06, 0.045), (x, y, tz + 0.025), T("greystone", "b"), bevel=0.008)
		kit.ring(0.018, 0.005, (x, y, tz + 0.05), CU("b"), rot=(90, 0, 0), seg=10)
	for a in (-12, 14):  # brass dividers, opened
		B((0.15, 0.008, 0.006), (-0.14 + 0.07 * math.cos(math.radians(a)), 0.12 + 0.07 * math.sin(math.radians(a)), tz + 0.01), CU("b"), bevel=0.001, rot=(0, 0, a))
	kit.cylinder(0.01, 0.012, (-0.14, 0.12, tz + 0.012), CU("dark"), verts=8, bevel=0.002)
	kit.cylinder(0.045, 0.014, (0.47, 0.22, tz + 0.007), CU("b"), verts=12, bevel=0.003)
	kit.cylinder(0.02, 0.1, (0.47, 0.22, tz + 0.064), C((0.93, 0.86, 0.66), 0.85), verts=10, bevel=0.004)
	B((0.004, 0.004, 0.016), (0.47, 0.22, tz + 0.12), kit.mat("charcoal"), bevel=0)
	flame_at(0.47, 0.22, tz + 0.122)
	kit.ring(0.02, 0.005, (0.52, 0.22, tz + 0.01), CU("b"), rot=(90, 0, 0), seg=10)


def hm_trophy_pedestal():
	st = lambda v: T("greystone", v)  # noqa: E731
	B((0.5, 0.5, 0.12), (0, 0, 0.06), st("b"), bevel=0.015)
	B((0.42, 0.42, 0.08), (0, 0, 0.155), st("c"), bevel=0.012)
	col = kit.cylinder(0.15, 0.56, (0, 0, 0.47), st("a"), rot=(0, 0, 22.5), verts=8, bevel=0.008)
	fy = -0.15 * math.cos(math.pi / 8)
	cut = groove_path([(0, 0.33), (0, 0.58)], fy, w=0.014, depth=0.01)
	cut += groove_path([(-0.04, 0.58), (0.04, 0.58), (0.04, 0.63), (-0.04, 0.63)], fy, w=0.012, depth=0.01, closed=True)
	cut += groove_path([(-0.045, 0.28), (0.045, 0.28)], fy, w=0.01, depth=0.008) + groove_path([(-0.045, 0.69), (0.045, 0.69)], fy, w=0.01, depth=0.008)
	carve(col, cut)
	for z in (0.215, 0.725):
		kit.cylinder(0.175, 0.05, (0, 0, z), st("c"), rot=(0, 0, 22.5), verts=8, bevel=0.008)
	cap = B((0.42, 0.42, 0.08), (0, 0, 0.785), st("b"), bevel=0.012)
	carve(cap, rune_row(-0.15, 0.15, 0.785, -0.21, h=0.045, w=0.009, depth=0.008, seed=8))
	z0 = 0.825
	B((0.3, 0.22, 0.07), (0, 0, z0 + 0.033), W("dark"), bevel=0.01)
	B((0.32, 0.24, 0.02), (0, 0, z0 + 0.073), W("b"), bevel=0.006)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.035, 0.035, 0.07), (cx * 0.145, cy * 0.105, z0 + 0.033), CU("b"), bevel=0.004)
	label(0, z0 + 0.033, -0.11, w=0.12, h=0.03)
	zt = z0 + 0.083
	kit.cylinder(0.06, 0.04, (0, 0, zt + 0.02), CU("b"), verts=12, bevel=0.005)
	kit.ring(0.06, 0.009, (0, 0, zt + 0.038), CU("dark"), seg=14)
	jaw = st("dark")
	for s_ in (-1, 1):
		pts = [(s_ * 0.025, 0, zt + 0.03), (s_ * 0.06, 0, zt + 0.12), (s_ * 0.075, 0, zt + 0.22), (s_ * 0.055, 0, zt + 0.31), (s_ * 0.012, 0, zt + 0.36)]
		tube_r(pts, [0.032, 0.03, 0.024, 0.016, 0.005], jaw, seg=9)
		for (zz, xx) in ((0.14, 0.05), (0.2, 0.058), (0.26, 0.045)):  # teeth on the inner edge
			kit.cone(0.011, 0.0, 0.035, (s_ * (xx - 0.022), 0, zt + zz), jaw, rot=(0, -s_ * 90, 0), verts=5, bevel=0)


def hm_banded_sideboard():
	L, D, H = 1.32, 0.46, 0.86
	B((L - 0.04, D - 0.04, 0.08), (0, 0.0, 0.04), W("dark"), bevel=0.01)
	for x in (-L / 2 + 0.06, L / 2 - 0.06):
		B((0.09, 0.09, 0.03), (x, -D / 2 + 0.06, 0.015), CU("dark"), bevel=0.004)
	for x in (-L / 2 + 0.025, L / 2 - 0.025):
		B((0.05, D, H - 0.1), (x, 0, 0.08 + (H - 0.1) / 2), W("b"), bevel=0.01)
		for z in (0.12, H - 0.06):
			B((0.06, 0.06, 0.03), (x, -D / 2 + 0.02, z), CU("b"), bevel=0.004)  # copper corner straps
			kit.rivet((x, -D / 2 - 0.012, z), CU("dark"), r=0.008)
	B((L - 0.04, 0.03, H - 0.1), (0, D / 2 - 0.02, 0.08 + (H - 0.1) / 2), W("dark"), bevel=0.006)
	B((L + 0.06, D + 0.05, 0.045), (0, -0.01, H + 0.002), W("c"), bevel=0.012)
	B((L + 0.04, 0.025, 0.02), (0, -D / 2 - 0.03, H - 0.03), W("dark"), bevel=0.004)
	fy = -D / 2 + 0.015
	dw = (L - 0.1) / 3
	for i in range(3):
		x = -L / 2 + 0.05 + dw * (i + 0.5)
		dr = B((dw - 0.02, 0.03, 0.12), (x, fy, 0.72), W("abc"[i]), bevel=0.006)
		carve(dr, groove_path([(x - dw * 0.38, 0.685), (x + dw * 0.38, 0.685), (x + dw * 0.38, 0.755), (x - dw * 0.38, 0.755)], fy - 0.015, w=0.008, depth=0.006, closed=True))
		kit.cylinder(0.035, 0.008, (x, fy - 0.017, 0.72), CU("dark"), rot=(90, 0, 0), verts=12, bevel=0.002)
		kit.ring(0.026, 0.006, (x, fy - 0.026, 0.7), CU("b"), rot=(90, 0, 0), seg=12)
		door = B((dw - 0.02, 0.03, 0.5), (x, fy, 0.38), W("abc"[(i + 1) % 3]), bevel=0.008)
		cut = groove_path([(x - dw * 0.36, 0.2), (x + dw * 0.36, 0.2), (x + dw * 0.36, 0.56), (x - dw * 0.36, 0.56)], fy - 0.015, w=0.01, depth=0.008, closed=True)
		cut += groove_path([(x, 0.25), (x + dw * 0.26, 0.38), (x, 0.51), (x - dw * 0.26, 0.38)], fy - 0.015, w=0.01, depth=0.008, closed=True)
		carve(door, cut)
		for z in (0.21, 0.55):  # copper bands across the door, riveted
			B((dw - 0.03, 0.008, 0.03), (x, fy - 0.018, z), CU("b"), bevel=0.002)
			for xx in (x - dw * 0.38, x, x + dw * 0.38):
				kit.rivet((xx, fy - 0.022, z), CU("dark"), r=0.007)
		hx = x - dw / 2 + 0.03
		for z in (0.25, 0.51):  # strap hinges
			B((0.1, 0.008, 0.025), (hx + 0.04, fy - 0.019, z), IRON("dark"), bevel=0.002)
			kit.cylinder(0.01, 0.04, (hx - 0.012, fy - 0.017, z), IRON("dark"), verts=8, bevel=0.002)
		kit.ring(0.022, 0.006, (x + dw * 0.3, fy - 0.03, 0.38), CU("b"), rot=(90, 0, 0), seg=12)
		kit.cylinder(0.012, 0.012, (x + dw * 0.3, fy - 0.02, 0.4), CU("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	kp = B((0.05, 0.008, 0.08), (0, fy - 0.019, 0.38), CU("b"), bevel=0.002)  # keyhole plate on the middle door
	carve(kp, [kit.cylinder(0.008, 0.05, (0, fy - 0.03, 0.39), GROOVE_M(), rot=(90, 0, 0), verts=8, bevel=0),
		B((0.006, 0.05, 0.02), (0, fy - 0.03, 0.375), GROOVE_M(), bevel=0)])
	for i in range(1, 3):
		B((0.03, 0.035, H - 0.12), (-L / 2 + 0.05 + dw * i, fy + 0.005, 0.08 + (H - 0.12) / 2 + 0.01), W("dark"), bevel=0.004)


MODELS = {f.__name__: f for f in (
	hm_spider_trophy, hm_beetle_shell_trophy, hm_snail_shell_trophy, hm_pickaxe_progression, hm_crossed_hammers,
	hm_shield_spears, hm_lamp_history_board, hm_bat_skull_plaque, hm_heirloom_axe, hm_vein_slice_frame,
	hm_potion_rack, hm_scroll_lattice, hm_preserve_shelf, hm_tankard_shelf, hm_ingot_display, hm_gem_jar_shelf,
	hm_herb_ladder, hm_book_nook,
	hm_carved_high_chair, hm_delve_game_table, hm_map_table, hm_trophy_pedestal, hm_banded_sideboard)}

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
			flatten_floor()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
