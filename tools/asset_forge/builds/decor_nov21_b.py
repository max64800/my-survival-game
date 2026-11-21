# Decor group B (Nov 21): dungeon and ruin story pieces: old, abandoned, worn. Same style as night_decor.py.
#   blender --background --factory-startup --python builds/decor_nov21_b.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (spider_eggs, cobweb_corner) have a flat back at +Y (cobweb_corner also at -X).
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, plank, rivet, rng, stone  # noqa: E402,F401
from night_materials import C, lump, sphere, _cm  # noqa: E402
from decor_nov21_f import lathe  # noqa: E402
from decor_nov21_a import (slim, BONE, CHAR, CU, IRON, PAPER, bar, carve, chip, circ, floor_cut, groove_path, low_z, objs, prism, rest,  # noqa: E402
	rod, rune_row, shift, spin, tube, turn)  # noqa: E402

WEB = lambda: C((0.8, 0.78, 0.72), 0.9)  # noqa: E731
GROOVE = lambda: kit.mat("stone_dark", -0.45, rough=1.0)  # noqa: E731
CRACK = lambda: kit.mat("charcoal", -0.3, rough=1.0)  # noqa: E731
RUST = lambda: C((0.4, 0.2, 0.1), 0.85)  # noqa: E731
GOLD = lambda s=0.0: C((0.62 + s, 0.47 + s, 0.16), 0.45, metal=0.6)  # noqa: E731


# ---------------- helpers ----------------
def flat_back(group, back=0.0, side=None):
	"""Cut every vertex of these parts flat at the wall: y <= back (and x <= side for a corner piece)."""
	for o in group:
		if o.type != "MESH":
			continue
		mw = o.matrix_world.copy()
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			w.y = min(w.y, back)
			if side is not None:
				w.x = min(w.x, side)
			v.co = inv @ w


def strip(p0, p1, w, t, m, n=(0, 1, 0)):
	"""A thin flat strip (web strand) from p0 to p1, its flat side facing n."""
	a, b = Vector(p0), Vector(p1)
	nn = Vector(n).normalized()
	side = (b - a).cross(nn).normalized() * (w / 2)
	nt = nn * (t / 2)
	v = [tuple(p) for p in (a - side - nt, b - side - nt, b + side - nt, a + side - nt,
		a - side + nt, b - side + nt, b + side + nt, a + side + nt)]
	f = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
	return mesh(v, f, m)


def bone(p0, p1, r, m):
	"""A long bone: a shaft with two knobs at each end."""
	a, b = Vector(p0), Vector(p1)
	ax = (b - a).normalized()
	sd = ax.cross(Vector((0, 0, 1)))
	sd = sd.normalized() if sd.length > 1e-3 else Vector((1, 0, 0))
	log(p0, p1, r, m, seg=7, rings=2, ends=False, bend=0.1)
	for e in (a, b):
		for s_ in (-1, 1):
			sphere(tuple(e + sd * s_ * r * 0.7), r * 1.35, m, seg=8, rings=5)


def skull(c, s, m, face=(0, -1, 0)):
	"""A dwarf skull at c (centre of the round top), looking along `face` (a flat x/y direction)."""
	c = Vector(c)
	f = Vector(face).normalized()
	sd = f.cross(Vector((0, 0, 1)))
	sphere(tuple(c), 0.1 * s, m, scale=(0.95, 1.0, 0.92), seg=12, rings=7)
	fc = c + f * 0.055 * s - Vector((0, 0, 0.045 * s))
	sphere(tuple(fc), 0.07 * s, m, scale=(1, 1, 0.85), seg=10, rings=6)  # face
	for k in (-1, 1):
		sphere(tuple(fc + f * 0.045 * s + sd * k * 0.032 * s + Vector((0, 0, 0.022 * s))), 0.024 * s, CHAR(-0.4), seg=8, rings=5)  # eye holes
	sphere(tuple(fc + f * 0.06 * s - Vector((0, 0, 0.012 * s))), 0.011 * s, CHAR(-0.4), seg=6, rings=4)  # nose hole
	jaw = fc + f * 0.02 * s - Vector((0, 0, 0.05 * s))
	sphere(tuple(jaw), 0.05 * s, m, scale=(1.1, 1.0, 0.55), seg=10, rings=5)
	for i in range(5):  # teeth
		tp = fc + f * (0.058 * s) + sd * ((i - 2) * 0.012 * s) - Vector((0, 0, 0.038 * s))
		B((0.009 * s, 0.012 * s, 0.014 * s), tuple(tp), BONE(0.05), bevel=0.001)


def crack_line(pts, y, m=None, r=0.008):
	"""A dark crack: thin rods from point to point (x, z) half sunk into a face at y."""
	m = m or CRACK()
	for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
		rod((x0, y, z0), (x1, y, z1), r, m, seg=5)


def coin(loc, m=None, tilt=(0, 0, 0)):
	return kit.cylinder(0.024, 0.007, loc, m or GOLD(J(0.05)), rot=tilt, verts=10, bevel=0.001)


DWARF = GAME / "assets" / "characters" / "dwarf"


def _aim(arm, name, target):
	"""Turn one pose bone (armature space) so its tail points at target (world)."""
	pb = arm.pose.bones[name]
	inv = arm.matrix_world.inverted()
	M = pb.matrix.copy()
	h = M.translation.copy()
	q = (pb.tail - pb.head).rotation_difference(inv @ Vector(target) - h)
	pb.matrix = Matrix.Translation(h) @ q.to_matrix().to_4x4() @ Matrix.Translation(-h) @ M
	bpy.context.view_layer.update()


def _curl(arm, side, deg):
	"""Bend every finger joint of one hand by deg (a loose fist round a haft)."""
	for f in ("index", "middle", "ring", "pinky"):
		for j in ("01", "02", "03"):
			pb = arm.pose.bones[f"{f}_{j}_{side}"]
			pb.rotation_mode = "XYZ"
			pb.rotation_euler.x += math.radians(deg)
	bpy.context.view_layer.update()


def stone_dwarf(m, aims, curl=0.0, voxel=0.011, tris=16000):
	"""The game's real dwarf (body + hide helm and breastplate) posed by `aims` [(bone, world target)], turned into
	ONE solid carved-stone figure (voxel remesh: no clothes layers left to shimmer) painted with stone `m`.
	Stands on z = 0, faces -Y, ~1.24 m tall. Returns the mesh object."""
	before = objs()
	bpy.ops.import_scene.gltf(filepath=str(DWARF / "dwarf_body.glb"))
	bpy.ops.import_scene.gltf(filepath=str(DWARF / "armor_hide.glb"))
	new = objs() - before
	keep = ("body_hand", "body_foot", "body_pants", "body_shirt", "body_shorts", "body_torso", "body_rings",
		"armor_head_hair", "armor_head_leather", "armor_head_brass", "armor_chest_brass", "armor_chest_leather", "armor_feet_leather")
	arms = [o for o in new if o.type == "ARMATURE"]
	for arm in arms:
		for name, tgt in aims:
			_aim(arm, name, tgt)
		if curl:
			for sd in ("l", "r"):
				_curl(arm, sd, curl)
	parts = []
	for o in new:
		if o.type == "MESH" and o.name.startswith(keep):
			bpy.context.view_layer.objects.active = o
			for md in list(o.modifiers):
				bpy.ops.object.modifier_apply(modifier=md.name)
			mw = o.matrix_world.copy()
			o.parent = None
			o.matrix_world = mw
			parts.append(o)
	for o in new:
		if o not in parts:
			bpy.data.objects.remove(o, do_unlink=True)
	bpy.ops.object.select_all(action="DESELECT")
	for o in parts:
		o.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	bpy.ops.object.join()
	o = bpy.context.object
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	r = o.modifiers.new("solid", "REMESH")
	r.mode, r.voxel_size, r.use_smooth_shade = "VOXEL", voxel, False
	bpy.ops.object.modifier_apply(modifier=r.name)
	d = o.modifiers.new("less", "DECIMATE")
	d.ratio = min(1.0, tris / max(1, len(o.data.polygons) * 2))
	bpy.ops.object.modifier_apply(modifier=d.name)
	o.data.materials.clear()
	o.data.materials.append(m)
	for p in o.data.polygons:
		p.use_smooth = False
	kit._uv_box(o, m["tile"])
	o.name = "statue"
	return o


# the guardian pose (the dwarf's arms are short): right hand gripping a great axe standing at his side, left fist on his belly
AX = (-0.37, -0.15)
GUARD = [("upperarm_r", (-0.34, 0.0, 0.6)), ("lowerarm_r", (-0.365, -0.15, 0.62)), ("hand_r", (-0.37, -0.2, 0.63)),
	("upperarm_l", (0.33, -0.02, 0.62)), ("lowerarm_l", (0.21, -0.22, 0.57)), ("hand_l", (0.17, -0.26, 0.57))]


def statue_stone():
	"""Greystone painted at a big scale: reads as one carved block, not a wall of cobbles."""
	m = T("greystone", "b").copy()
	m["tile"] = 3.0
	return m


def stone_axe(base, top, m, m2, rotz=90):
	"""A carved great axe standing on its double-bit head: the haft from the head up to a pommel at `top`.
	rotz turns it round the haft (90 = bits pointing front and back)."""
	before = objs()
	b, t = Vector(base), Vector(top)
	x, y, z = b
	B((0.09, 0.07, 0.22), (x, y, z + 0.11), m2, bevel=0.012)  # the head's socket
	for s_ in (-1, 1):  # the two bearded bits, resting on their lower tips
		prism([(x + s_ * 0.035, z + 0.05), (x + s_ * 0.16, z + 0.005), (x + s_ * 0.2, z + 0.13), (x + s_ * 0.17, z + 0.26),
			(x + s_ * 0.035, z + 0.2)][::s_], y - 0.022, y + 0.022, m2)
	log((x, y, z + 0.215), tuple(t), 0.03, m, seg=8, rings=2, ends=False, bend=0)
	kit.cylinder(0.044, 0.05, tuple(t), m2, verts=10, bevel=0.008)  # pommel
	for f in (0.3, 0.55):
		kit.ring(0.033, 0.009, tuple(b + (t - b) * f), m2, seg=12)  # carved grip bands
	turn(objs() - before, "Z", rotz, (x, y, z))


def plinth_runes(slab, y, x0, x1, z, h=0.07):
	"""Carve a row of runes and a border INTO the plinth's front face (y)."""
	cut = rune_row(x0, x1, z, y, h=h, w=0.013, depth=0.012, seed=5)
	cut += groove_path([(x0 - 0.05, z - h), (x1 + 0.05, z - h), (x1 + 0.05, z + h), (x0 - 0.05, z + h)], y, w=0.012, closed=True)
	carve(slab, cut)


# ================= models =================
def statue_toppled():
	"""The game's own dwarf as a carved stone guardian, toppled off its plinth onto its back: the head snapped off at
	the neck and rolled beside it, the broken stump of the plinth with his boots still on it, chips everywhere."""
	m = statue_stone()
	st = stone_dwarf(m, GUARD, curl=60)
	# snap at the neck: cut into a body and a head
	hd = st.copy()
	hd.data = st.data.copy()
	bpy.context.scene.collection.objects.link(hd)
	import bmesh
	for o, top in ((st, False), (hd, True)):
		bm = bmesh.new()
		bm.from_mesh(o.data)
		res = bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0.93 + (0.006 if top else -0.006)),
			plane_no=(0, 0.25, 1), clear_inner=top, clear_outer=not top)
		bmesh.ops.holes_fill(bm, edges=[e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)], sides=0)
		bm.to_mesh(o.data)
		bm.free()
	# the boots broke off and stayed on the plinth stump
	ft = st.copy()
	ft.data = st.data.copy()
	bpy.context.scene.collection.objects.link(ft)
	for o, top in ((st, True), (ft, False)):
		bm = bmesh.new()
		bm.from_mesh(o.data)
		res = bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, 0.14 + (0.006 if top else -0.006)),
			plane_no=(0, -0.2, 1), clear_inner=top, clear_outer=not top)
		bmesh.ops.holes_fill(bm, edges=[e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)], sides=0)
		bm.to_mesh(o.data)
		bm.free()
	ax = objs()
	stone_axe((AX[0], AX[1], 0.12), (AX[0], AX[1], 0.74), m, m, rotz=60)
	body = [st] + list(objs() - ax)
	# plinth stump on the left, his boots still standing on it
	px, py = -0.78, 0.0
	stone((0.56, 0.6, 0.12), (px, py, 0.06), tone=T("greystone", "c"), bevel=0.02)
	slab = B((0.46, 0.5, 0.2), (px, py, 0.215), T("greystone", "a"), bevel=0.025)
	carve(slab, rune_row(px - 0.15, px + 0.15, 0.215, py - 0.25, h=0.06, w=0.012, depth=0.012, seed=5) +
		groove_path([(px - 0.19, 0.15), (px + 0.19, 0.15), (px + 0.19, 0.28), (px - 0.19, 0.28)], py - 0.25, w=0.012, closed=True))
	shift([ft], (px, py + 0.04, 0.315 - 0.004))
	# the body lying on its left side along +X, feet toward the plinth, front (face, beard, axe) to the front
	turn(body, "Y", 90, (0, 0, 0))
	turn(body, "X", -12, (0, 0, 0))  # rolled a little onto its back, face up to the light
	bpy.context.view_layer.update()
	lo_x = min((o.matrix_world @ v.co).x for o in body for v in o.data.vertices)
	shift(body, (px + 0.29 - lo_x, 0.08, -low_z(body) + 0.004))
	# the head rolled off to the front-right, lying on its side, face to the front
	turn([hd], "Y", 85, (0, 0, 1.05))
	turn([hd], "X", -15, (0, 0, 0))
	turn([hd], "Z", 12, (0, 0, 0))
	bpy.context.view_layer.update()
	shift([hd], (0.72, -0.42, -low_z([hd]) + 0.004))
	r = __import__("random").Random(4)
	for k in range(10):  # chips and shards from the neck
		s = 0.02 + 0.035 * r.random()
		o = kit.gem((r.uniform(0.3, 0.95), r.uniform(-0.75, 0.35), 0.1), (s, s * 0.8, s * 0.6), T("greystone", "abc"[k % 3]), seed=40 + k)
		spin(o, r.uniform(-20, 20), r.uniform(-20, 20), r.uniform(0, 360))
		rest(o)
	floor_cut()


def statue_cracked_plinth():
	"""The game's own dwarf as a carved stone guardian on a stepped plinth, hands on the pommel of a great axe; a
	crack is cut down the plinth and up his leg, runes cut into the plinth, a corner broken off at his feet."""
	gm = statue_stone()
	z0 = 0.52
	stone((1.0, 0.9, 0.12), (0, 0, 0.06), tone=T("greystone", "c"), bevel=0.02)
	slab = B((0.82, 0.72, 0.3), (0, 0, 0.27), T("greystone", "a"), bevel=0.03)
	cap = B((0.96, 0.8, 0.1), (0, 0, z0 - 0.055), T("greystone", "c"), bevel=0.02)
	y = -0.36
	cut = rune_row(-0.26, 0.26, 0.3, y, h=0.075, w=0.014, depth=0.013, seed=7)
	cut += groove_path([(-0.33, 0.2), (0.33, 0.2), (0.33, 0.4), (-0.33, 0.4)], y, w=0.013, closed=True)
	cut += groove_path([(0.12, 0.13), (0.07, 0.19), (0.11, 0.26), (0.05, 0.33), (0.09, 0.4)], y, w=0.016, depth=0.02)  # the crack
	cut.append(chip((0.41, -0.36, 0.41), (0.09, 0.08, 0.09), seed=3))  # a corner knocked off
	carve(slab, cut)
	carve(cap, groove_path([(0.09, z0 - 0.105), (0.13, z0 - 0.06), (0.1, z0 - 0.005)], -0.4, w=0.016, depth=0.02) +
		[chip((0.48, -0.4, z0 - 0.06), (0.06, 0.05, 0.05), seed=6)])
	st = stone_dwarf(gm, GUARD, curl=60)
	st.location.z = z0 - 0.006
	bpy.context.view_layer.update()
	stone_axe((AX[0], AX[1], z0 - 0.004), (AX[0], AX[1], z0 + 0.74), gm, gm, rotz=60)
	# the broken-off corner lying at the plinth's foot
	o = kit.gem((0.55, -0.5, 0.05), (0.08, 0.06, 0.05), T("greystone", "a"), seed=11)
	rest(o)
	floor_cut()


def shrine_broken():
	"""A small stone shrine niche: side pillars, back wall, a roof stone cracked in two, the idol toppled on its floor."""
	stone((0.98, 0.58, 0.15), (0, 0, 0.075), tone=T("greystone", "c"), bevel=0.025)
	B((0.62, 0.12, 0.72), (0, 0.18, 0.5), T("greystone", "dark"), bevel=0.02)  # back wall
	B((0.16, 0.42, 0.72), (-0.38, 0.03, 0.5), T("greystone", "b"), bevel=0.025)  # left pillar, whole
	B((0.16, 0.42, 0.44), (0.38, 0.03, 0.36), T("greystone", "a"), bevel=0.025)  # right pillar, broken short
	for k in range(3):  # its broken top: jagged chunks
		lump((0.33 + k * 0.05, 0.03 + J(0.08), 0.58), (0.05, 0.06, 0.04), T("greystone", "a"), seed=k + 2, rough=0.006)
	# roof: left half level on the left pillar + back wall, right half cracked off and sloping down onto the broken pillar
	B((0.5, 0.52, 0.1), (-0.21, 0.04, 0.9), T("greystone", "c"), bevel=0.02)
	B((0.52, 0.5, 0.1), (0.23, 0.035, 0.755), T("greystone", "b"), bevel=0.02, rot=(0, 28, 0))
	kit.cylinder(0.07, 0.04, (-0.2, 0.04, 0.965), T("greystone", "a"), verts=8, bevel=0.01)  # little top knob
	# a carved sun-ring on the back wall
	kit.ring(0.1, 0.016, (0, 0.117, 0.62), T("greystone", "b"), rot=(90, 0, 0), seg=16)
	# the idol's empty little stand and the idol lying fallen in front of it
	B((0.16, 0.14, 0.08), (0, 0.06, 0.185), T("greystone", "a"), bevel=0.012)
	before = objs()
	kit.cylinder(0.065, 0.2, (0, 0, 0.07), T("marble", "b"), verts=10, bevel=0.012)
	sphere((0, 0, 0.21), 0.06, T("marble", "b"), seg=10, rings=6)
	kit.cone(0.06, 0.02, 0.06, (0, 0, 0.27), T("marble", "a"), verts=8)
	for s_ in (-1, 1):
		sphere((s_ * 0.06, -0.01, 0.12), 0.025, T("marble", "b"), seg=6, rings=4)
	idol = objs() - before
	turn(idol, "Y", 80, (0, 0, 0))
	turn(idol, "Z", 20, (0, 0, 0))
	shift(idol, (0.05, -0.12, 0.15 + 0.058))
	for k in range(4):
		lump((0.55 + J(0.08), -0.3 + k * 0.12, 0.04), (0.06, 0.05, 0.04), T("greystone", "abc"[k % 3]), seed=k + 20, rough=0.006)
	floor_cut()


def thin_coin(loc, n=(0, 0, 1), m=None, r=0.021, t=0.0045, spin_=0.0):
	"""One thin worn coin (12 sides, soft worn rim) lying with its face along normal n."""
	n = Vector(n).normalized()
	rx, ry = math.degrees(math.atan2(-n.y, n.z)), math.degrees(math.atan2(n.x, math.hypot(n.y, n.z)))
	o = kit.cylinder(r, t, loc, m or GOLD(J(0.05)), rot=(rx, ry, spin_), verts=11, bevel=0.0012)
	for md in o.modifiers:
		if md.type == "BEVEL":
			md.segments = 1  # one worn facet is enough at coin size (keeps the hoard light)
	return o


def coin_stack(x, y, z, k, tones, seed=1):
	"""A little stack of k coins, each nudged and turned a bit, the top one slid half off."""
	r = __import__("random").Random(seed)
	for i in range(k):
		thin_coin((x + r.uniform(-0.004, 0.004), y + r.uniform(-0.004, 0.004), z + 0.00225 + i * 0.0047),
			(r.uniform(-0.02, 0.02), r.uniform(-0.02, 0.02), 1), tones[i % len(tones)], spin_=r.uniform(0, 30))
	thin_coin((x + 0.016, y - 0.008, z + 0.0047 * k + 0.004), (0.18, 0.05, 1), tones[k % len(tones)])


def offering_bowl_coins():
	"""A carved stone offering bowl on a banded pedestal, heaped with hundreds of thin worn coins lying every way
	like fish scales, little stacks of coins on the base stone, a few spilled and rolled across the floor."""
	tones = [GOLD(-0.12), GOLD(-0.04), GOLD(0.04), C((0.5, 0.31, 0.15), 0.5, metal=0.6)]  # old gold and a few bronze
	B((0.56, 0.56, 0.09), (0, 0, 0.045), T("greystone", "c"), bevel=0.02)
	B((0.42, 0.42, 0.06), (0, 0, 0.115), T("greystone", "a"), bevel=0.015)  # plinth step
	col = kit.cylinder(0.1, 0.36, (0, 0, 0.32), T("greystone", "b"), verts=8, bevel=0.012)  # eight-sided column
	carve(col, [kit.ring(0.1, 0.008, (0, 0, z), GROOVE(), seg=16) for z in (0.2, 0.44)])  # bands cut round it
	kit.cylinder(0.15, 0.05, (0, 0, 0.165), T("greystone", "c"), verts=12, bevel=0.012)  # foot
	kit.cylinder(0.16, 0.05, (0, 0, 0.515), T("greystone", "c"), verts=12, bevel=0.012)  # capital
	z0 = 0.535
	bowl = lathe([(0.0, z0), (0.13, z0), (0.22, z0 + 0.05), (0.29, z0 + 0.13), (0.315, z0 + 0.17), (0.3, z0 + 0.185),
		(0.275, z0 + 0.165), (0.2, z0 + 0.08), (0.1, z0 + 0.045), (0.0, z0 + 0.04)], (0, 0), T("greystone", "b"), seg=24)
	kit._uv_box(bowl, bowl.data.materials[0]["tile"])
	carve(bowl, [chip((0.24, -0.2, z0 + 0.18), (0.05, 0.04, 0.04), seed=2)])  # a chip off the rim
	# the hoard: a dark gold bed hidden under hundreds of coins lying on a dome
	R, H, zb = 0.27, 0.1, z0 + 0.13
	hb = lambda x, y: zb + H * max(0.0, 1 - (x * x + y * y) / (R * R)) ** 0.8  # noqa: E731
	bed = lathe([(0.0, zb + H - 0.006)] + [(R * f, hb(R * f, 0) - 0.006) for f in (0.3, 0.55, 0.75, 0.9, 1.0)] + [(R * 0.8, zb - 0.06)],
		(0, 0), C((0.42, 0.31, 0.1), 0.5, metal=0.6), seg=20)
	r = __import__("random").Random(12)
	placed = []
	for i in range(270):
		d, a = R * math.sqrt(r.uniform(0, 0.97)), r.uniform(0, 2 * math.pi)
		x, y = math.cos(a) * d, math.sin(a) * d
		e = 0.004
		nx, ny = -(hb(x + e, y) - hb(x - e, y)) / (2 * e), -(hb(x, y + e) - hb(x, y - e)) / (2 * e)
		z = hb(x, y) + 0.001
		for _ in range(3):  # lie ON the coins already there (scales, never two in one place)
			for px, py, pz in placed:
				if math.hypot(px - x, py - y) < 0.046 and abs(pz - z) < 0.0055:
					z = pz + 0.0056
		if z > hb(x, y) + 0.02:
			continue
		placed.append((x, y, z))
		thin_coin((x, y, z), (nx + r.uniform(-0.3, 0.3), ny + r.uniform(-0.3, 0.3), 1), tones[i % 4], spin_=r.uniform(0, 30))
	for k in range(5):  # coins slid over the rim
		a = math.radians(-120 + k * 22)
		thin_coin((math.cos(a) * 0.29, math.sin(a) * 0.29, z0 + 0.187), (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), tones[k % 4])
	# stacks on the base stone and plinth step, spills on the floor
	coin_stack(0.17, -0.16, 0.145, 6, tones, seed=1)
	coin_stack(-0.23, -0.245, 0.09, 4, tones, seed=2)
	coin_stack(-0.14, 0.18, 0.145, 3, tones, seed=3)
	for k, (x, y) in enumerate(((0.36, -0.3), (0.43, -0.12), (-0.32, -0.38), (0.2, -0.42), (0.05, -0.47), (-0.42, -0.2), (0.33, 0.22))):
		thin_coin((x, y, 0.0026 + 0.0004 * k), (J(0.06), J(0.06), 1), tones[k % 4], spin_=k * 17)
	floor_cut()
	slim(small=0.03, fine=0.005, few=0.02)  # lighter file (under 2 MB), same look


def altar_candles():
	"""A stone altar slab on two blocks, burnt-down candle stubs on it, wax running over the front edge."""
	for x in (-0.42, 0.42):
		stone((0.26, 0.48, 0.7), (x, 0, 0.35), tone=T("greystone", "b"), bevel=0.03)
	B((1.3, 0.64, 0.12), (0, 0, 0.75), T("greystone", "c"), bevel=0.03)
	carve = kit.mat("stone_dark", -0.35)
	for i in range(5):  # runes along the slab front
		B((0.02, 0.02, 0.07), (-0.3 + i * 0.15, -0.322, 0.75), carve, bevel=0.002, rot=(0, J(20) + (30 if i % 2 else -10), 0))
	wax = C((0.84, 0.78, 0.62), 0.7)
	wax2 = C((0.78, 0.72, 0.56), 0.7)
	top = 0.81
	cands = ((-0.48, -0.12, 0.16), (-0.34, 0.08, 0.09), (-0.12, 0.14, 0.22), (0.12, -0.05, 0.06), (0.3, 0.12, 0.14), (0.5, -0.1, 0.08))
	for k, (x, y, h) in enumerate(cands):
		pz = top + 0.002 + 0.003 * (k % 3)  # each wax puddle at its own height (no shimmer)
		kit.cylinder(0.075 + 0.012 * (k % 2), 0.01, (x + 0.01, y - 0.01, pz), wax2, verts=11, bevel=0.002)
		r = 0.05 - 0.006 * (k % 3)
		kit.cylinder(r, h, (x, y, top + h / 2), wax, verts=9, bevel=0.004)
		kit.cylinder(0.004, 0.02, (x, y, top + h + 0.008), CHAR(), verts=5, bevel=0)  # burnt wick
		for d in range(2):  # wax runs down its side
			sphere((x + r * (0.75 if d else -0.55), y - r * 0.6, top + h * 0.55), 0.014, wax, scale=(1, 0.8, 2.2), seg=8, rings=5)
	before = objs()  # one stub fallen on its side
	kit.cylinder(0.03, 0.09, (0, 0, 0.03), wax, verts=9, bevel=0.004)
	kit.cylinder(0.004, 0.018, (0, 0, 0.083), CHAR(), verts=5, bevel=0)
	fl = objs() - before
	turn(fl, "Y", 90, (0, 0, 0.03))
	turn(fl, "Z", 30, (0, 0, 0))
	shift(fl, (-0.1, -0.2, top - 0.004))
	for x in (-0.5, -0.12, 0.3):  # drips over the front edge
		sphere((x, -0.318, 0.77), 0.014, wax2, scale=(1.6, 0.6, 2.0), seg=8, rings=5)
	floor_cut()


def _sarcophagus(open_):
	L, W, H = 1.6, 0.74, 0.55
	stone((1.78, 0.9, 0.1), (0, 0, 0.05), tone=T("greystone", "c"), bevel=0.02)
	z0 = 0.095
	for s_ in (-1, 1):
		B((L, 0.1, H), (0, s_ * (W / 2 - 0.05), z0 + H / 2), T("greystone", "b"), bevel=0.02)  # long sides
		B((0.1, W - 0.2 + 0.01, H - 0.01), (s_ * (L / 2 - 0.055), 0, z0 + (H - 0.01) / 2), T("greystone", "a"), bevel=0.015)  # ends
	B((L - 0.21, W - 0.21, 0.04), (0, 0, z0 + 0.06), CHAR(-0.2), bevel=0.005)  # dark inside floor
	carve = kit.mat("stone_dark", -0.3)
	for i in range(3):  # carved panels on the front
		x = -0.5 + i * 0.5
		for (a, b) in (((x - 0.18, 0.2), (x + 0.18, 0.2)), ((x - 0.18, 0.5), (x + 0.18, 0.5)), ((x - 0.18, 0.2), (x - 0.18, 0.5)), ((x + 0.18, 0.2), (x + 0.18, 0.5))):
			rod((a[0], -W / 2, a[1]), (b[0], -W / 2, b[1]), 0.012, carve, seg=5)
		kit.ring(0.06, 0.012, (x, -W / 2, 0.35), carve, rot=(90, 0, 0), seg=12)
	ztop = z0 + H
	before = objs()
	lz = ztop - 0.005
	B((L + 0.1, W + 0.08, 0.12), (0, 0, lz + 0.06), T("greystone", "c"), bevel=0.03)  # lid
	lt = lz + 0.12
	fx = -0.5  # the carved dwarf face at the head end of the lid
	sphere((fx, 0, lt - 0.01), 0.13, T("greystone", "b"), scale=(1, 0.85, 0.35), seg=12, rings=7)
	sphere((fx - 0.08, 0, lt), 0.15, T("greystone", "a"), scale=(0.6, 0.95, 0.4), seg=12, rings=6)  # helmet
	sphere((fx + 0.04, 0, lt + 0.04), 0.03, T("greystone", "b"), scale=(1.4, 1, 0.8), seg=8, rings=5)  # nose
	for s_ in (-1, 1):
		sphere((fx - 0.02, s_ * 0.05, lt + 0.03), 0.02, carve, seg=6, rings=4)  # closed eyes
	prism([(fx + 0.08, -0.13), (fx + 0.08, 0.13), (fx + 0.45, 0.07), (fx + 0.55, 0.0), (fx + 0.45, -0.07)], lt - 0.01, lt + 0.035, T("greystone", "b"), axis="z")  # beard
	for y in (-0.06, 0.0, 0.06):
		rod((fx + 0.12, y, lt + 0.036), (fx + 0.44, y * 0.5, lt + 0.036), 0.007, carve, seg=5)
	B((0.5, 0.04, 0.02), (0.45, 0, lt + 0.005), T("greystone", "a"), bevel=0.006)  # carved sword blade
	B((0.04, 0.16, 0.025), (0.2, 0, lt + 0.008), T("greystone", "a"), bevel=0.006)  # its guard
	lid = objs() - before
	if open_:
		turn(lid, "Z", -22, (0, 0, 0))
		shift(lid, (0.6, 0.3, 0))
		bn = BONE(-0.08)
		skull((-0.5, 0.05, z0 + 0.15), 0.85, bn, face=(0.3, -1, 0))
		bone((-0.3, -0.08, z0 + 0.1), (0.15, 0.04, z0 + 0.1), 0.02, bn)
		bone((0.0, 0.14, z0 + 0.1), (0.4, -0.02, z0 + 0.1), 0.02, BONE(-0.12))
		for k in range(4):
			sphere((-0.15 + k * 0.06, 0.12, z0 + 0.1), 0.025, bn, seg=8, rings=5)  # spine bits


def sarcophagus_closed():
	"""A stone coffin with carved front panels; its lid shows a sleeping dwarf face and beard."""
	_sarcophagus(False)


def sarcophagus_open():
	"""The same stone coffin, its lid pushed aside at an angle, bones inside."""
	_sarcophagus(True)


def bone_pile():
	"""A heap of old bones and a skull on top."""
	A, Bb, Hh = 0.32, 0.26, 0.14
	o = sphere((0, 0, 0), 1.0, kit.tex_mat("stone", "dark"), scale=(A, Bb, Hh), seg=12, rings=7, cut=0.0)
	kit.roughen(o, 0.01, 1, seed=4)

	def surf(x, y):
		d = 1 - (x / A) ** 2 - (y / Bb) ** 2
		return Hh * math.sqrt(d) if d > 0 else 0.0

	bones = ((-0.42, -0.1, 0.2, 0.15, 0.022), (-0.3, 0.25, 0.35, -0.05, 0.02), (0.4, -0.25, -0.2, 0.2, 0.021),
		(-0.15, -0.35, 0.12, 0.3, 0.018), (0.05, 0.32, 0.38, 0.12, 0.017), (-0.2, 0.05, 0.25, -0.12, 0.02), (0.1, -0.2, 0.3, 0.05, 0.016))
	for k, (x0, y0, x1, y1, r) in enumerate(bones):
		p0 = (x0, y0, surf(x0, y0) + r * 1.1)
		p1 = (x1, y1, surf(x1, y1) + r * 1.1)
		bone(p0, p1, r, BONE(-0.05 * (k % 3)))
	for k in range(4):  # ribs: bent half rings on the heap
		x, y = -0.1 + k * 0.08, -0.08 + J(0.03)
		rg = kit.ring(0.09, 0.011, (x, y, surf(x, y) + 0.01), BONE(-0.06), rot=(90, 0, 20 + k * 10), seg=14)
		rg.scale = (1, 1, 0.8)
	skull((0.05, 0.05, surf(0.05, 0.05) + 0.1), 1.0, BONE(0.0), face=(0.6, -1, 0))
	for k in range(6):  # small bits around the foot of the heap
		a = k * 1.1
		lump((math.cos(a) * 0.4, math.sin(a) * 0.33, 0.012), (0.025, 0.018, 0.014), BONE(-0.1), seed=k + 30, rough=0.004)
	floor_cut()


def skull_spike():
	"""A warning: a skull stuck on a sharpened wooden stake, the stake wedged in a pile of rocks."""
	for k in range(6):
		a = k * 1.05
		lump((math.cos(a) * 0.17, math.sin(a) * 0.17, 0.07), (0.12, 0.1, 0.09), T("stone", "abc"[k % 3]), seed=k + 1, rough=0.01)
	lump((0.02, 0.0, 0.16), (0.14, 0.12, 0.1), T("basalt", "b"), seed=11, rough=0.01)
	log((0, 0, 0.05), (0.03, 0.01, 1.08), 0.045, T("bark"), seg=8, rings=3, bend=0.05, ends=False, r1=0.035)
	kit.cone(0.035, 0.004, 0.16, (0.03, 0.01, 1.15), T("wood", "c"), verts=8, bevel=0)  # sharpened tip
	skull((0.03, 0.02, 1.1), 1.0, BONE(-0.05), face=(0.1, -1, 0))
	kit.rope_wrap((0.015, 0.005), 0.05, 0.62, 0.7, 3, thick=0.012)  # rope binding
	cloth = kit.tex_mat("sack", "dark")
	prism([(0.04, 0.68), (0.2, 0.62), (0.17, 0.5), (0.22, 0.38), (0.12, 0.42), (0.05, 0.6)], -0.04, -0.05, cloth)  # torn rag
	floor_cut()


def spider_eggs():
	"""A cluster of pale spider egg sacs stuck to the wall in webbing. Flat back at +Y."""
	sac = (C((0.86, 0.83, 0.72), 0.8), C((0.8, 0.77, 0.66), 0.8), C((0.9, 0.87, 0.78), 0.8))
	before = objs()
	eggs = ((0, 0.35, 0.13), (-0.14, 0.45, 0.1), (0.15, 0.48, 0.11), (-0.1, 0.22, 0.1), (0.12, 0.24, 0.09), (0.02, 0.56, 0.09),
		(-0.22, 0.32, 0.08), (0.25, 0.36, 0.08), (0.0, 0.13, 0.08))
	for k, (x, z, r) in enumerate(eggs):
		o = sphere((x, -0.02, z), r, sac[k % 3], scale=(0.95, 0.85, 1.15), seg=12, rings=7)
		flat_back([o], back=-0.003 - 0.0025 * k)  # each egg's back at its own depth (no shimmer)
	sphere((0.25, -0.03, 0.36), 0.05, CHAR(-0.3), scale=(1, 0.6, 1.2), seg=8, rings=5)  # one hatched open
	flat_back(objs() - before)
	w = WEB()
	n = 12
	for i in range(n):  # webbing on the wall, radiating out
		a = 2 * math.pi * (i + 0.3) / n
		r0, r1 = 0.12, 0.42 + 0.08 * ((i * 5) % 3)
		strip((math.cos(a) * r0, -0.004, 0.35 + math.sin(a) * r0), (math.cos(a) * r1, -0.004, max(0.01, 0.35 + math.sin(a) * r1)), 0.01, 0.008, w)
	for ring_r in (0.3, 0.4):
		for i in range(n):
			a0, a1 = 2 * math.pi * (i + 0.3) / n, 2 * math.pi * (i + 1.3) / n
			p0 = (math.cos(a0) * ring_r, -0.007, max(0.012, 0.35 + math.sin(a0) * ring_r))
			p1 = (math.cos(a1) * ring_r, -0.007, max(0.012, 0.35 + math.sin(a1) * ring_r))
			strip(p0, p1, 0.007, 0.006, w)
	for k in range(5):  # strands wrapped over the sacs
		x = -0.2 + k * 0.1
		rod((x, -0.1, 0.18 + 0.05 * (k % 2)), (x * 0.8 + 0.05, -0.1, 0.5 - 0.04 * (k % 2)), 0.004, w, seg=4)
	flat_back(objs() - before)


def web(hub, anchors, m, closed=True, rings=9, frame=0.86, sag=0.05, broken=(), seed=1, f0=0.1, f1=0.92, thick=1.0, wob=0.0):
	"""A real orb web made of thin round silk threads: radials from the hub, a frame thread, anchor threads out to
	what holds it, one long sagging capture spiral (a fan goes back and forth when not closed), a tangle round the hub.
	`broken` = spiral steps that snapped: their loose ends hang straight down. Threads cross, so all of it joins."""
	r = __import__("random").Random(seed)
	hub = Vector(hub)
	A = [Vector(a) for a in anchors]
	n = len(A)
	F = [hub + (a - hub) * frame for a in A]
	down = Vector((0, 0, -1))

	def thread(p, q, rad, s_=sag):
		rad *= thick
		mid = (p + q) / 2 + down * s_ * (q - p).length
		tube([tuple(p), tuple((p + mid) / 2 + down * s_ * 0.25 * (q - p).length), tuple(mid),
			tuple((mid + q) / 2 + down * s_ * 0.25 * (q - p).length), tuple(q)], rad, rad * 0.9, m, seg=5)

	for i in range(n):
		thread(hub + (F[i] - hub) * 0.03, F[i], 0.0042, sag * 0.2)  # radials, nearly straight
		thread(F[i], A[i], 0.005, sag * 0.3)  # anchor threads
	for i in range(n if closed else n - 1):
		thread(F[i], F[(i + 1) % n], 0.0055, sag * 0.6)  # frame
	order = list(range(n)) if closed else list(range(n)) + list(range(n - 2, 0, -1))
	steps = rings * len(order)
	pts = []
	for s_ in range(steps + 1):
		i = order[s_ % len(order)]
		f = f0 + (f1 - f0) * s_ / steps + (r.uniform(-wob, wob) if 0 < s_ < steps else 0)
		pts.append(hub + (F[i] - hub) * f)
	for s_, (p, q) in enumerate(zip(pts, pts[1:])):
		if s_ in broken:
			for e, d in ((p, 1), (q, -1)):  # snapped: each loose end hangs straight down
				ln = r.uniform(0.04, 0.12)
				off = Vector((0, -0.006, 0))  # a little in front, never lying along a radial
				tube([tuple(e), tuple(e + (q - p) * 0.12 * d + down * ln * 0.5 + off), tuple(e + (q - p) * 0.14 * d + down * ln + off)], 0.0034, 0.0025, m, seg=5)
			continue
		thread(p, q, 0.0034)
	for k in range(5):  # the tight tangle round the hub, between the radials and a little in front of them
		i = k * n // 5
		p = hub + ((F[i] + F[(i + 1) % n]) / 2 - hub) * 0.05 + Vector((0, -0.004, 0))
		q = hub + ((F[(i + n // 2) % n] + F[(i + n // 2 + 1) % n]) / 2 - hub) * 0.06 + Vector((0, -0.004, 0))
		thread(p, q, 0.0034, 0.0)


def cobweb_corner():
	"""An old cobweb filling a wall corner: a fan web of thin round silk threads from the corner out to a sagging free
	edge, a back-and-forth capture spiral with snapped threads hanging straight down, a dense tangle of threads in the
	corner and loose old threads sagging below it. Flat backs at +Y and -X."""
	w = WEB()
	cx, H, L = 0.4, 1.0, 0.85
	apex = Vector((cx - 0.03, -0.03, H))
	k = 11
	ends = []
	for i in range(k):  # anchor points: on the left wall (y = 0) round the sagging free edge to the right wall (x = cx)
		t = i / (k - 1)
		ends.append(Vector((min(cx - 0.004, cx - L * (1 - t)), min(-0.004, -L * t), H - 0.72 - 0.22 * math.sin(math.pi * t))))
	ends[0].y, ends[-1].x = 0.0, cx  # the edge threads are glued to the walls
	web(apex, ends, w, closed=False, rings=6, frame=0.9, sag=0.05, broken=(23, 24, 41, 58), seed=3, f0=0.12, f1=0.88, thick=0.75, wob=0.025)
	r = __import__("random").Random(5)
	for _ in range(26):  # dense tangle in the corner, threads from wall to wall
		p = Vector((cx, r.uniform(-0.22, -0.03), H - r.uniform(0.0, 0.25)))
		q = Vector((cx - r.uniform(0.03, 0.22), 0.0, H - r.uniform(0.0, 0.25)))
		tube([tuple(p), tuple((p + q) / 4 + apex / 2), tuple(q)], 0.0025, 0.0025, w, seg=5)  # through the radials' bundle
	for _ in range(9):  # stray threads across the fan: an old web gets messy
		a, b = r.sample(range(k), 2)
		p, q = apex + (ends[a] - apex) * r.uniform(0.3, 0.8), apex + (ends[b] - apex) * r.uniform(0.3, 0.8)
		tube([tuple(p), tuple((p + q) / 2 + Vector((0, 0, -0.04 * (q - p).length))), tuple(q)], 0.0025, 0.0025, w, seg=5)
	for a, b in ((1, 4), (3, 7), (6, 9), (2, 5)):  # loose old threads sagging below the free edge, each with a strand hanging off
		p, q = ends[a], ends[b]
		mid = (p + q) / 2 + Vector((0, 0, -min(0.14, (p.z + q.z) / 2 - 0.05)))
		tube([tuple(p), tuple((p + mid) / 2 + Vector((0, 0, -0.03))), tuple(mid), tuple((mid + q) / 2 + Vector((0, 0, -0.03))), tuple(q)], 0.0028, 0.0028, w, seg=5)
		ln = min(0.1, mid.z - 0.02)
		tube([tuple(mid), tuple(mid + Vector((0, 0, -ln / 2))), tuple(mid + Vector((0.002, 0, -ln)))], 0.0028, 0.002, w, seg=5)
	for i in (2, 5, 8):  # torn strands hanging straight down from the big web's edge
		e = ends[i]
		ln = min(0.3, e.z - 0.03)
		tube([tuple(e), tuple(e + Vector((0, 0, -ln / 2))), tuple(e + Vector((0.003, 0.0, -ln)))], 0.0035, 0.0025, w, seg=5)
	flat_back([o for o in bpy.data.objects if o.type == "MESH"], back=0.0, side=cx)
	for o in bpy.data.objects:  # mirror: the corner walls end up at +Y and -X, so the web faces the room's front-right
		if o.type == "MESH":
			mw = o.matrix_world.copy()
			o.matrix_world = Matrix.Identity(4)
			for v in o.data.vertices:
				w_ = mw @ v.co
				v.co = (-w_.x, w_.y, w_.z)
			o.data.flip_normals()


def cobweb_beams():
	"""A big orb web of thin round silk threads stretched in an old timber frame: two hewn posts on stone footings, a
	log beam pegged on top with knee braces, the web's frame thread tied to posts and beam, a capture spiral with a
	torn gap and hanging threads, loose strands down to the footings."""
	for x in (-0.65, 0.65):
		stone((0.3, 0.28, 0.12), (x, 0, 0.06), tone=T("greystone", "b"))
		chip_ = kit.gem((x + 0.14, -0.13, 0.03), (0.04, 0.03, 0.03), T("greystone", "c"), seed=int(x * 10 + 9))
		rest(chip_)
		log((x, 0, 0.11), (x + J(0.012), 0, 1.58), 0.068, T("bark"), seg=9, rings=4, bend=0.03)
		kit.cylinder(0.078, 0.035, (x, 0, 0.13), IRON("dark"), verts=12, bevel=0.004)  # iron shoe on the post foot
	log((-0.82, 0, 1.64), (0.82, 0, 1.64), 0.075, T("bark"), seg=9, rings=4, bend=0.02)  # top beam
	for s_ in (-1, 1):
		log((s_ * 0.64, 0, 1.3), (s_ * 0.36, 0, 1.6), 0.04, T("wood", "b"), seg=7, rings=2, bend=0.0, ends=False)  # knee brace
		for z in (1.64,):
			kit.cylinder(0.018, 0.17, (s_ * 0.65, 0, z), T("wood", "c"), rot=(90, 0, 0), verts=7, bevel=0.003)  # peg through beam end
	w = WEB()
	hub = (0.03, -0.004, 0.98)
	anchors = [(-0.33, 0, 1.57), (0.0, 0, 1.57), (0.32, 0, 1.57), (0.45, 0, 1.47), (0.585, 0, 1.15), (0.585, 0, 0.8),
		(0.585, 0, 0.45), (0.3, 0, 0.2), (-0.1, 0, 0.18), (-0.585, 0, 0.4), (-0.585, 0, 0.78), (-0.585, 0, 1.16), (-0.46, 0, 1.45)]
	web(hub, anchors, w, closed=True, rings=11, frame=0.88, sag=0.03, broken=(40, 41, 53, 54, 66, 92), seed=2)
	for p, q in (((0.3, 0, 0.2), (0.56, -0.03, 0.12)), ((-0.1, 0, 0.18), (-0.58, 0.03, 0.12))):  # loose strands to the footings
		tube([p, ((p[0] + q[0]) / 2, 0, (p[2] + q[2]) / 2 - 0.02), q], 0.004, 0.0035, w, seg=5)


def stave(a0, a1, z0, tops, R, m, th=0.026, bulge=0.035, H=0.9, rows=5):
	"""One curved barrel stave: a bent board from angle a0 to a1 (radians) round the barrel axis, bottom at z0, its
	top edge at heights `tops` across its width (uneven = snapped and splintered). Bulges like a real barrel."""
	nc = len(tops)
	rr = lambda z: R + bulge * math.sin(math.pi * min(max(z, 0.0), H) / H)  # noqa: E731
	v = []
	for inner in (0, 1):
		for k in range(rows + 1):
			for c in range(nc):
				a = a0 + (a1 - a0) * c / (nc - 1)
				z = z0 + (tops[c] - z0) * k / rows
				r = rr(z) - th * inner
				v.append((math.cos(a) * r, math.sin(a) * r, z))
	n = (rows + 1) * nc
	idx = lambda i, k, c: i * n + k * nc + c  # noqa: E731
	f = []
	for k in range(rows):
		for c in range(nc - 1):
			f.append((idx(0, k, c), idx(0, k, c + 1), idx(0, k + 1, c + 1), idx(0, k + 1, c)))
			f.append((idx(1, k, c), idx(1, k + 1, c), idx(1, k + 1, c + 1), idx(1, k, c + 1)))
	for k in range(rows):  # the two long edges
		for c in (0, nc - 1):
			f.append((idx(0, k, c), idx(0, k + 1, c), idx(1, k + 1, c), idx(1, k, c)))
	for c in range(nc - 1):  # bottom and the broken top
		for k in (0, rows):
			f.append((idx(0, k, c), idx(1, k, c), idx(1, k, c + 1), idx(0, k, c + 1)))
	return mesh(v, f, m)


def round_board(cx, cy, Rr, y0, y1, z0, z1, m, n=7):
	"""One board of a round barrel head: the strip y0..y1 of a circle (radius Rr, centre cx, cy), ends cut round."""
	ys = [y0 + (y1 - y0) * k / n for k in range(n + 1)]
	pts = [(cx + math.sqrt(max(1e-4, Rr * Rr - y * y)), cy + y) for y in ys]
	pts += [(cx - math.sqrt(max(1e-4, Rr * Rr - y * y)), cy + y) for y in reversed(ys)]
	return prism(pts, z0, z1, m, axis="z")


def barrel_smashed():
	"""A smashed barrel: curved bulging staves still standing in their bottom hoops, snapped off at jagged splintered
	heights, two broken out; the round barrel head (three pegged boards) lying on the floor, one board split off;
	loose curved staves, a sprung iron hoop with rivets and wood splinters around it. Empty and dry."""
	r = __import__("random").Random(21)
	R, n = 0.27, 14
	wd = ("a", "b", "c")
	hs = (0.62, 0.34, 0.45, 0.26, 0.0, 0.31, 0.55, 0.72, 0.4, 0.0, 0.29, 0.5, 0.36, 0.44)  # 0 = broken out
	gap = 0.012  # radians between staves (no shimmer between neighbours)
	for i in range(n):
		if not hs[i]:
			continue
		a0, a1 = 2 * math.pi * i / n + gap, 2 * math.pi * (i + 1) / n - gap
		h = hs[i]
		tops = [h + r.uniform(-0.05, 0.03), h + r.uniform(0.02, 0.11), h + r.uniform(-0.08, 0.0), h + r.uniform(-0.02, 0.06)]
		if h > 0.5:
			tops = [h - 0.04, h + 0.12, h - 0.1, h]  # tall ones end in a long splinter
		stave(a0, a1, 0.0, tops, R, T("wood", wd[i % 3]))
	# the barrel bottom: three boards set in the staves, dark with age
	for y0, y1 in ((-0.25, -0.088), (-0.082, 0.082), (0.088, 0.25)):
		round_board(0, 0, R - 0.016, y0, y1, 0.055, 0.085, T("wood", "dark"))
	# hoops: bottom two still on, with rivets
	for z in (0.06, 0.21):
		rad = R + 0.035 * math.sin(math.pi * z / 0.9) + 0.004
		kit.ring(rad, 0.012, (0, 0, z), IRON("dark"), seg=28).scale = (1, 1, 2.4)
		for k in range(4):
			a = math.radians(30 + k * 90 + z * 100)
			kit.rivet((math.cos(a) * (rad + 0.012), math.sin(a) * (rad + 0.012), z), IRON("a"), r=0.008)
	# the round barrel head lying on the floor: two boards together, the third split off beside it
	hx, hy, Rh = 0.5, -0.32, 0.25
	for k, (y0, y1) in enumerate(((-0.165, -0.04), (-0.036, 0.08))):
		round_board(hx, hy, Rh, y0, y1, 0.0, 0.025 + 0.002 * k, T("wood", wd[k]))
	B((0.06, 0.22, 0.012), (hx, hy - 0.04, 0.031), T("wood", "dark"), bevel=0.004)  # the batten that held them
	for y in (-0.11, 0.03):
		kit.rivet((hx, hy + y, 0.038), IRON("dark"), r=0.008)
	before = objs()
	round_board(0, 0, Rh, 0.084, 0.2, 0.0, 0.025, T("wood", "c"))  # the split-off board
	turn(objs() - before, "Z", 35, (0, 0, 0))
	shift(objs() - before, (0.6, -0.02, 0))
	# loose staves lying around, curved, broken at one end
	for k, (x, y, rz, ln) in enumerate(((-0.55, -0.25, 25, 0.62), (0.05, -0.62, 95, 0.5), (-0.5, 0.35, -40, 0.4), (0.45, 0.4, 60, 0.33))):
		before = objs()
		stave(-0.27, 0.27, 0.0, [ln, ln + 0.06, ln - 0.04, ln + 0.02], R, T("wood", wd[k % 3]))
		g = objs() - before
		shift(g, (-R, 0, 0))
		turn(g, "Y", -90, (0, 0, 0))  # lying down, outer (bulging) face down
		turn(g, "Z", rz, (0, 0, 0))
		bpy.context.view_layer.update()
		shift(g, (x, y, -low_z(g) + 0.001))
	# a sprung hoop lying flat on the floor, rivets on it
	o = kit.ring(0.3, 0.012, (-0.12, -0.5, 0.012), IRON("dark"), seg=28)
	o.scale = (1.15, 0.85, 2.0)
	for k in range(3):
		a = math.radians(40 + k * 120)
		kit.rivet((-0.12 + math.cos(a) * 0.3 * 1.15, -0.5 + math.sin(a) * 0.3 * 0.85, 0.016), IRON("a"), r=0.008)
	# splinters on the floor
	for k in range(14):
		a, d = r.uniform(0, 2 * math.pi), r.uniform(0.34, 0.75)
		ln = r.uniform(0.05, 0.13)
		sp = kit.gem((math.cos(a) * d, math.sin(a) * d, 0.02), (ln, 0.012, 0.008), T("wood", wd[k % 3]), seed=60 + k)
		spin(sp, 0, r.uniform(-8, 8), r.uniform(0, 180))
		rest(sp, 0.001)
	floor_cut()


def well_dry():
	"""A round stone well, dry and dark inside, under a little plank roof on two posts, a rope down to a bucket on the rim."""
	R, D, n = 0.55, 0.2, 12
	for c in range(3):
		h = 0.2 if c < 2 else 0.12
		z = c * 0.195
		for i in range(n):
			a = 2 * math.pi * (i + 0.5 * (c % 2)) / n
			ln = 2 * math.pi * R / n - 0.012
			tone = T("greystone", "abc"[(i + c) % 3]) if (i + c) % 5 else T("brownrock", "b")
			B((ln, D + (0.03 if c == 2 else 0), h), (math.cos(a) * R, math.sin(a) * R, z + h / 2), tone, bevel=0.025, rot=(0, 0, math.degrees(a) + 90))
	top = 0.195 * 2 + 0.12
	disc_pts = circ(0, 0, R - D / 2 + 0.02, n=16, wob=0.0)
	prism(disc_pts, 0.06, 0.1, CHAR(-0.5), axis="z")  # deep dark hole
	px = R + D / 2 + 0.08
	for s_ in (-1, 1):
		stone((0.22, 0.22, 0.1), (s_ * px, 0, 0.05))
		log((s_ * px, 0, 0.08), (s_ * px, 0, 1.62), 0.06, T("bark"), seg=8, rings=3, bend=0.03)
	log((-px - 0.05, 0, 1.6), (px + 0.05, 0, 1.6), 0.055, T("bark"), seg=8, rings=2, bend=0.02)  # ridge beam
	log((-px, 0, 1.12), (px, 0, 1.12), 0.06, T("wood", "b"), seg=8, rings=2, bend=0.0, ends=False)  # windlass
	kit.rope_wrap((0.0, 1.12), 0.07, -0.15, 0.15, 5, axis="x")  # rope wound on it
	rod((px + 0.04, 0, 1.12), (px + 0.12, 0, 1.12), 0.018, IRON("dark"))  # crank
	rod((px + 0.12, 0.0, 1.12), (px + 0.12, -0.18, 1.12), 0.016, IRON("dark"))
	rod((px + 0.12, -0.18, 1.12), (px + 0.2, -0.18, 1.12), 0.022, T("wood", "c"))
	a = math.radians(35)
	for s_ in (-1, 1):  # plank roof, one plank missing on the back
		for k in range(4):
			if s_ == 1 and k == 3:
				continue
			dk = 0.08 + k * 0.165
			plank((1.7 - 0.06 * (k % 2), 0.16, 0.03), (0, s_ * dk * math.cos(a), 1.665 - dk * math.sin(a)), rot=(-s_ * 35, 0, 0))
	# a round stave bucket standing on the front rim, its rope up to the windlass
	bx, by = 0.18, -R
	bz = top - 0.004
	before = objs()
	wood_bucket(0.115, 0.24)
	g = objs() - before
	shift(g, (bx, by, bz))
	bpy.context.view_layer.update()
	kit.rope((bx, by, bz + 0.36), (bx - 0.05, -0.03, 1.12 - 0.075), r=0.012)


def wood_bucket(R, H, n=12):
	"""A round bucket of curved staves standing at the origin: two iron hoops with rivets, a round board bottom, dark
	empty inside, iron ears and a bent iron bail handle over the top."""
	wd = ("a", "b", "c")
	for i in range(n):
		a0, a1 = 2 * math.pi * i / n + 0.012, 2 * math.pi * (i + 1) / n - 0.012
		h = H + (0.012 if i % 4 == 0 else 0.0)  # two staves stand taller: the ears
		stave(a0, a1, 0.0, [h, h, h], R, T("wood", wd[i % 3]), th=0.018, bulge=0.012, H=H, rows=3)
	round_board(0, 0, R - 0.008, -R + 0.01, R - 0.01, 0.025, 0.045, T("wood", "dark"), n=9)  # the bottom, dark
	for z in (0.05, H - 0.05):
		rad = R + 0.012 * math.sin(math.pi * z / H) + 0.003
		kit.ring(rad, 0.008, (0, 0, z), IRON("dark"), seg=24).scale = (1, 1, 2.2)
		for k in range(3):
			a = math.radians(20 + k * 120)
			kit.rivet((math.cos(a) * (rad + 0.008), math.sin(a) * (rad + 0.008), z), IRON("a"), r=0.006)
	for s_ in (-1, 1):  # iron ears
		B((0.012, 0.03, 0.06), (s_ * (R + 0.006), 0, H - 0.01), IRON("dark"), bevel=0.003)
	arc = [(math.cos(math.radians(a)) * (R + 0.012), 0.0, H + 0.005 + math.sin(math.radians(a)) * 0.12) for a in range(0, 181, 15)]
	tube(arc, 0.007, 0.007, IRON("dark"), seg=6)  # the bail handle


def bookshelf_collapsed():
	"""An old bookshelf leaning back, one shelf snapped, books spilled across the floor."""
	before = objs()
	W, Dp, H = 0.9, 0.3, 1.6
	for x in (-W / 2, W / 2):
		B((0.05, Dp, H), (x, 0, H / 2), T("wood", "dark"), bevel=0.01)
	B((W - 0.04, 0.02, H - 0.04), (0, Dp / 2 - 0.015, H / 2), T("wood", "c"), bevel=0.004)  # back
	B((W + 0.08, Dp + 0.03, 0.05), (0, 0, H + 0.02), T("wood", "dark"), bevel=0.012)  # top
	cols = ((0.4, 0.14, 0.1), (0.2, 0.28, 0.18), (0.45, 0.32, 0.16), (0.22, 0.2, 0.3), (0.5, 0.42, 0.3), (0.3, 0.16, 0.12))
	for zi, zs in enumerate((0.06, 0.45, 0.85, 1.25)):
		if zi == 2:
			continue  # this one is snapped (below)
		plank((W - 0.04, Dp - 0.02, 0.035), (0, -0.005, zs))
		x = -W / 2 + 0.05
		k = 0
		while x < W / 2 - 0.12:  # a row of books, some leaning
			bw = 0.035 + 0.02 * ((k * 7 + zi) % 3)
			bh = 0.22 + 0.04 * ((k * 3 + zi) % 4)
			if (k + zi) % 5 == 4:
				x += bw + 0.06  # a gap where books fell out
				k += 1
				continue
			B((bw, 0.2, bh), (x + bw / 2, -0.02, zs + 0.0175 + bh / 2 - 0.003), C(cols[(k + zi) % 6], 0.9), bevel=0.005)
			x += bw + 0.003
			k += 1
	# the snapped shelf: two halves drooping into a V, its books slid off
	for s_ in (-1, 1):
		plank((W / 2 - 0.04, Dp - 0.02, 0.035), (s_ * (W / 4 - 0.005), -0.005, 0.8), rot=(0, s_ * 14, 0))
	sh = objs() - before
	turn(sh, "X", -10, (0, Dp / 2, 0))  # leaning back against the wall
	# books spilled on the floor in front
	fl = ((-0.3, -0.45, 20, (0.4, 0.14, 0.1)), (0.05, -0.55, -35, (0.2, 0.28, 0.18)), (0.35, -0.38, 70, (0.22, 0.2, 0.3)), (-0.05, -0.85, 10, (0.45, 0.32, 0.16)))
	for k, (x, y, rz, col) in enumerate(fl):
		B((0.2, 0.26, 0.045), (x, y, 0.0225), C(col, 0.9), bevel=0.006, rot=(0, 0, rz))
		B((0.18, 0.24, 0.035), (x + 0.008, y, 0.0225), PAPER(-0.08), bevel=0.003, rot=(0, 0, rz))  # pages showing at the edges
	B((0.2, 0.26, 0.045), (-0.28, -0.44, 0.064), C((0.5, 0.42, 0.3), 0.9), bevel=0.006, rot=(0, 0, -15))  # one on top of another
	# an open book lying face up
	for s_ in (-1, 1):
		B((0.17, 0.24, 0.02), (0.45 + s_ * 0.09, -0.75, 0.01 + 0.004 * (s_ + 1)), C((0.4, 0.14, 0.1), 0.9), bevel=0.004, rot=(0, s_ * -6, 0))
		B((0.15, 0.22, 0.012), (0.45 + s_ * 0.085, -0.75, 0.025 + 0.004 * (s_ + 1)), PAPER(0.02), bevel=0.002, rot=(0, s_ * -6, 0))
	floor_cut()


MODELS = {
	"statue_toppled": statue_toppled, "statue_cracked_plinth": statue_cracked_plinth, "shrine_broken": shrine_broken,
	"offering_bowl_coins": offering_bowl_coins, "altar_candles": altar_candles, "sarcophagus_closed": sarcophagus_closed,
	"sarcophagus_open": sarcophagus_open, "bone_pile": bone_pile, "skull_spike": skull_spike, "spider_eggs": spider_eggs,
	"cobweb_corner": cobweb_corner, "cobweb_beams": cobweb_beams,
	"barrel_smashed": barrel_smashed, "well_dry": well_dry,
	"bookshelf_collapsed": bookshelf_collapsed,
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
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
