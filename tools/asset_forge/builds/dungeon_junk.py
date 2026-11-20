# Dungeon junk (owner's picks, Nov 20, 2026): small floor models just for looks, lying along walls and in corners
# of all the dungeons. List, sizes and placement rule: docs/design/zone1-dungeons/traps-and-variety.md
# ("Dungeon junk"). Concept pictures (look only): docs/art/dungeon-model-sheets/junk_*.jpg.
#
#   blender --background --factory-startup --python builds/dungeon_junk.py -- <out_dir> [only=junk_bones,...] [grey=1]
#
# Axes like the other dungeon scripts: x across, y up, z = front. Origin bottom-centre on the floor (y = 0).
# Everything lies flat and low (under 0.4 m), one part "model", no moving parts, no collision needed.
# Batch 1 (all 12 dungeons):
#   junk_bones          two long dwarf bones crossed, a short one, a skull on its side and a few small bits
#   junk_sword_snapped  a short sword in two pieces: brass guard + pommel, leather grip, the blade snapped
#   junk_axe_head       an iron axe head with no handle, a chip out of its edge, the empty eye
#   junk_spear_broken   a spear shaft snapped in two (splinters), the iron head still on the front half
# Batch 2 (rest of junk_shared.jpg):
#   junk_rags           a torn crumpled cloth, a small scrap, a burst empty sack (gathered neck)
#   junk_rags_b .. _f   (owner, Nov 20) five more rag piles, two rags each, all different shapes and places
#   junk_shield_wood    a round 6-board shield (0.6 m) broken in two, iron boss, a loose board, chunks (small dungeons)
#   junk_shield_iron    the same shield with an iron rim and rivets, broken in two (medium and big dungeons)
#   junk_rubble_wood    a low pile of snapped planks in three layers and some chips (small dungeons)
#   junk_rubble_wood_b .. _f  (owner, Nov 20) five more plank piles, more spread out, each stacked its own way
# Batch 3 (junk_small_mine.jpg, small dungeons):
#   junk_pickaxe_broken a pickaxe head, its handle snapped off short in the socket, the broken piece beside it
#   junk_shovel_bent    a dented shovel with a bent shaft and a D grip
#   junk_beam_snapped   a hand-hewn mine beam snapped in two: torn fibres, cracks, moss, a hugging iron band each
#   junk_helmet         a dented miner's helmet on its brim: band with rivets, front badge, a dent
#   junk_lantern        a square lantern lying on its side, top pane smashed, a fallen candle, shards on the floor
# Batch 4 (junk_medium_stone.jpg, medium dungeons):
#   junk_urns           three burial urns: whole, cracked, smashed (its bottom and shards)
#   junk_urn_broken_a .. _e  (owner, Nov 20: "another 5 different ones of the broken vase") one smashed urn each:
#                       low stump, tall tooth, lying on its side, a small one with its lid, a wide one split in half
#   junk_statue_head    a dwarf statue's head lying on its side, face showing, braided beard, stone chips
#   junk_armour_pile    a rusty breastplate on its back (ridge, rolled edges, skirt plates, straps), two hollow helms
#                       (one upside down, showing inside), a shoulder plate, an arm guard, stones (owner round 2)
#   junk_coffin_lid     a carved stone coffin lid in three flat chunks: raised rim, a diamond knot on each
#   junk_coffin_piece_a .. _c  (owner, Nov 20) the lid's three chunks as models of their own, to scatter about
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import shack_v2 as S  # noqa: E402
import dungeon_rootwood as R  # noqa: E402  (save_parts, pictures, age_paint; same OUT/ONLY/GREY)

J, T = K.J, K.T


# ---------------------------------------------------------------- helpers
def meshes():
	return {o.name for o in bpy.data.objects if o.type == "MESH"}


def tinted(kind, v, rgb, tag):
	"""A painted texture with its colours multiplied by rgb (bone from limestone, brass from copper). Baked into a
	copy of the picture so the game shows it as it is (the model file can't carry a colour-mixing step)."""
	import numpy as np
	name = f"{kind}_{v}_{tag}"
	if name in bpy.data.materials:
		return bpy.data.materials[name]
	base = kit.tex_mat(kind, v)
	m = base.copy()
	m.name = name
	m["tile"] = base["tile"]
	tex = [nd for nd in m.node_tree.nodes if nd.type == "TEX_IMAGE"][0]
	img = tex.image.copy()
	img.name = name
	px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
	px[:, :3] = np.clip(px[:, :3] * np.array(rgb, dtype=np.float32), 0, 1)
	img.pixels.foreach_set(px.ravel())
	img.pack()
	tex.image = img
	return m


def BONE(v="a"):
	return tinted("limestone", v, (1.08, 0.98, 0.78), "bone")


def BRASS():
	return tinted("silver", "a", (1.3, 0.92, 0.38), "brass")


def STEEL(v="a"):
	return tinted("iron", v, (1.55, 1.55, 1.5), "steel")


def DARK():
	return kit.mat("charcoal", shade=-0.7, rough=1.0)


def lump(c, r, m, seed, seg=8, ring=5, jit=0.12, yaw=0.0, roll=0.0):
	"""A chunky rounded lump (bone knobs, skull, pommel): a low sphere, every corner nudged, flat cut faces.
	c = centre, r = (x, y, z) radii (game axes), yaw = turn round up (degrees)."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=1, location=K.G(c))
	o = bpy.context.object
	rr = random.Random(seed)
	for v in o.data.vertices:
		v.co *= rr.uniform(1 - jit, 1 + jit)
	o.scale = K.GS(r)
	o.rotation_euler = (0, math.radians(-roll), math.radians(yaw))   # (roll: a lean sideways, round the front axis)
	bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
	return kit._finish(o, m, 0, 0)


def rod(p0, p1, r0, r1, m, sides=8, seed=1, jit=0.1, rings=3, role=None):
	"""A rough round rod from p0 to p1 (game coords), radius r0 -> r1, capped both ends (bone shafts, spear shafts)."""
	rr = random.Random(seed)
	a, b = Vector(p0), Vector(p1)
	ax = (b - a).normalized()
	up = Vector((0, 1, 0)) if abs(ax.y) < 0.9 else Vector((1, 0, 0))
	u = ax.cross(up).normalized()
	w = ax.cross(u)
	verts, faces = [], []
	for i in range(rings):
		t = i / (rings - 1)
		c = a + (b - a) * t
		r = r0 + (r1 - r0) * t
		for k in range(sides):
			ang = 2 * math.pi * k / sides
			rk = r * rr.uniform(1 - jit, 1 + jit)
			p = c + (u * math.cos(ang) + w * math.sin(ang)) * rk
			verts.append(tuple(p))
	for i in range(rings - 1):
		for k in range(sides):
			k2 = (k + 1) % sides
			faces.append((i * sides + k, i * sides + k2, (i + 1) * sides + k2, (i + 1) * sides + k))
	faces.append(tuple(range(sides - 1, -1, -1)))
	faces.append(tuple((rings - 1) * sides + k for k in range(sides)))
	o = K.mesh(verts, faces, m)
	if role:
		o["role"] = role
	return o


def slab(outline, y0, te, tm, m, inner=None, k=0.4, toward=None):
	"""A flat blade lying on the floor: outline = [(x, z), ...] counter-clockwise seen from above. Its rim is te
	thick, its middle rises to tm (a chunky bevel up to the inner outline). inner: the inner outline, or the outline
	pulled k of the way to `toward` (default: its middle)."""
	n = len(outline)
	if inner is None:
		cx = sum(p[0] for p in outline) / n
		cz = sum(p[1] for p in outline) / n
		tx, tz = toward or (cx, cz)
		inner = [(x + (tx - x) * k, z + (tz - z) * k) for (x, z) in outline]
	verts = [(x, y0, z) for (x, z) in outline] + [(x, y0 + te, z) for (x, z) in outline] + [(x, y0 + tm, z) for (x, z) in inner]
	faces = [tuple(range(n - 1, -1, -1)), tuple(2 * n + i for i in range(n))]
	for i in range(n):
		j = (i + 1) % n
		faces.append((i, j, n + j, n + i))
		faces.append((n + i, n + j, 2 * n + j, 2 * n + i))
	return K.mesh(verts, faces, m)


def turn(objs, deg, pivot, off=(0.0, 0.0, 0.0)):
	"""Turn finished parts round the up axis through pivot (game coords), then slide them by off."""
	piv = Vector(K.G(pivot))
	rot = Matrix.Rotation(math.radians(deg), 4, "Z")  # Blender z = game up
	d = Vector(K.G(off))
	for name in objs:
		o = bpy.data.objects[name]
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)
		for v in o.data.vertices:
			v.co = piv + (rot @ (v.co - piv)) + d


def jag(x, z0, z1, n, amp, seed):
	"""A jagged break line across a blade at about x, from z0 to z1 (n points)."""
	rr = random.Random(seed)
	return [(x + rr.uniform(-amp, amp) * (0.4 if i in (0, n - 1) else 1.0), z0 + (z1 - z0) * i / (n - 1)) for i in range(n)]


# ---------------------------------------------------------------- junk_bones
def long_bone(p0, p1, r, seed, m):
	"""A dwarf's leg or arm bone: a slightly narrow-waisted shaft with two knobs at each end."""
	a, b = Vector(p0), Vector(p1)
	ax = (b - a).normalized()
	side = ax.cross(Vector((0, 1, 0))).normalized()
	rod(a + ax * r * 0.6, (a + b) / 2, r * 1.15, r * 0.9, m, seed=seed)
	rod((a + b) / 2, b - ax * r * 0.6, r * 0.9, r * 1.15, m, seed=seed + 1)
	for end, s in ((a, 1), (b, -1)):
		for k, sd in enumerate((-1, 1)):
			c = end + side * sd * r * 0.75 + ax * s * r * 0.3
			lump(tuple(c), (r * 1.25, r * 1.2, r * 1.25), m, seed + 10 + k + (5 if s < 0 else 0), seg=7, ring=5)


def skull(m):
	"""A dwarf skull lying a little turned, built facing +z, its bottom on the floor."""
	before = meshes()
	lump((0.0, 0.092, -0.01), (0.085, 0.082, 0.098), m, 31, seg=10, ring=7, jit=0.07)        # the round top
	lump((0.0, 0.066, 0.062), (0.066, 0.052, 0.05), m, 32, seg=9, ring=6, jit=0.07)          # the face
	lump((0.0, 0.112, 0.074), (0.072, 0.02, 0.03), m, 33, seg=8, ring=5, jit=0.08)           # brow ridge
	for sx in (-1, 1):
		lump((sx * 0.052, 0.062, 0.064), (0.022, 0.018, 0.03), m, 34 + sx, seg=7, ring=5)    # cheekbone
		lump((sx * 0.031, 0.082, 0.09), (0.024, 0.021, 0.0175), DARK(), 36 + sx, seg=8, ring=5, jit=0.06)  # eye hole
	lump((0.0, 0.058, 0.108), (0.011, 0.015, 0.012), DARK(), 38, seg=6, ring=4)              # nose hole
	lump((0.0, 0.032, 0.078), (0.045, 0.02, 0.03), m, 39, seg=8, ring=5, jit=0.06)           # upper jaw
	for i in range(6):
		x = -0.027 + i * 0.0108
		K.blk((x, 0.026 + J(0.002), 0.1 - abs(x) * 0.35), (0.0095, 0.016 + J(0.002), 0.011), BONE("b"), bevel=0.002)
	return meshes() - before


def junk_bones():
	m = BONE("a")
	long_bone((-0.24, 0.022, 0.06), (0.12, 0.022, -0.04), 0.017, 1, m)        # thigh bone on the floor
	long_bone((-0.14, 0.022, -0.1), (0.16, 0.048, 0.08), 0.015, 3, BONE("b"))  # shin bone resting across it
	long_bone((0.16, 0.017, 0.14), (0.33, 0.017, 0.1), 0.012, 5, BONE("c"))    # a short arm bone
	sk = skull(BONE("c"))
	turn(sk, 20, (0.0, 0.0, 0.0), off=(0.25, 0.0, -0.12))
	for i, (x, z, r) in enumerate(((-0.32, -0.08, 0.017), (-0.05, 0.17, 0.014), (0.05, 0.2, 0.012), (0.36, -0.05, 0.015),
			(-0.2, 0.17, 0.011))):
		lump((x, r * 0.85, z), (r * 1.2, r, r * 0.9), BONE("abc"[i % 3]), 60 + i, seg=6, ring=4, jit=0.18)  # small bits


# ---------------------------------------------------------------- junk_sword_snapped
def junk_sword_snapped():
	W = 0.036   # half the blade's width
	brass, grip = BRASS(), T("leather", "dark")
	# the hilt half: pommel, leather grip with two bindings, the bent crossguard, a blade stub snapped off
	lump((-0.19, 0.022, 0.0), (0.024, 0.022, 0.027), brass, 71, seg=8, ring=5, jit=0.08)
	rod((-0.172, 0.019, 0.0), (-0.035, 0.019, 0.0), 0.015, 0.016, grip, sides=8, seed=72, jit=0.05)
	for x in (-0.15, -0.06):
		rod((x - 0.006, 0.019, 0.0), (x + 0.006, 0.019, 0.0), 0.0185, 0.0185, T("leather", "a"), sides=8, seed=73, jit=0.04)
	for sz in (-1, 1):  # the guard, each arm bent down a little at its tip
		K.blk((-0.022, 0.018, sz * 0.045), (0.028, 0.034, 0.09), brass, bevel=0.005, rx=sz * 4)
		K.blk((-0.02, 0.014, sz * 0.097), (0.03, 0.028, 0.03), brass, bevel=0.005, rx=sz * 14)
	brk = jag(0.2, -W, W, 6, 0.012, 74)
	stub = [(-0.012, -W - 0.002), (0.2, -W + 0.002)] + brk[1:-1] + [(0.2, W - 0.002), (-0.012, W + 0.002)]
	slab(stub, 0.006, 0.006, 0.017, STEEL("a"), k=0.6, toward=None)
	# the point half: starts at the same break (pushed 4 cm away) and narrows to the tip; lies turned beside it
	before = meshes()
	tip_brk = [(x + 0.04, z) for (x, z) in reversed(brk)]
	tip = [(0.24, W - 0.002)] + tip_brk[1:-1] + [(0.24, -W + 0.002), (0.42, -W * 0.8), (0.48, -W * 0.3), (0.505, 0.0),
		(0.48, W * 0.35), (0.42, W * 0.82)]
	slab(tip, 0.0, 0.006, 0.016, STEEL("b"), k=0.6)
	turn(meshes() - before, -14, (0.24, 0.0, 0.0), off=(0.03, 0.0, 0.05))


# ---------------------------------------------------------------- junk_axe_head
def junk_axe_head():
	iron, dark = STEEL("a"), T("iron", "a")
	# the eye: a thick oval ring along z (the handle went through it), and a lumpy poll at its back
	kit.ring(0.026, 0.014, K.G((0.0, 0.0285, 0.0)), dark, rot=(90, 0, 0), seg=9)
	o = bpy.context.object
	rr = random.Random(91)
	for v in o.data.vertices:
		v.co *= rr.uniform(0.94, 1.06)
	o.scale = (1.12, 0.98, 3.1)  # its own z (turned to the game's z): the ring stretched into a short tube
	bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
	lump((-0.046, 0.027, 0.0), (0.02, 0.026, 0.04), dark, 92, seg=7, ring=5, jit=0.08)   # the poll (hammer back)
	# the blade: flares from the eye to a curved edge with a chip knocked out of it; thickest at the eye
	edge = []
	for i in range(9):
		a = math.radians(-62 + i * 124 / 8)
		edge.append((0.11 + math.cos(a) * 0.1, math.sin(a) * 0.115 - 0.012))
	chip = [(edge[5][0] - 0.004, edge[5][1]), (edge[5][0] - 0.022, edge[5][1] + 0.008), (edge[6][0] - 0.012, edge[6][1] - 0.006)]
	outline = [(0.02, -0.04)] + edge[:5] + chip + edge[6:] + [(0.02, 0.035)]
	slab(outline, 0.012, 0.006, 0.03, iron, k=0.55, toward=(0.0, 0.0))
	# a bright worn rim along the cutting edge (a thin strip, just inside the outline and above the rim)
	for i in range(len(edge) - 1):
		if i in (4, 5):
			continue
		(x0, z0), (x1, z1) = edge[i], edge[i + 1]
		mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
		ln = math.hypot(x1 - x0, z1 - z0)
		ang = math.degrees(math.atan2(z1 - z0, x1 - x0))
		nx, nz = (0.11 - mx), (-0.012 - mz)
		nl = math.hypot(nx, nz)
		K.blk((mx + nx / nl * 0.006, 0.0205, mz + nz / nl * 0.006), (ln * 1.02, 0.004, 0.009), T("iron", "c"),
			bevel=0.0015, ry=-ang)  # (round 1: kept)


# ---------------------------------------------------------------- junk_spear_broken
def splinters(end, ax, r, seed, n=5):
	"""Wood splinters sticking out of a snapped shaft end, along ax."""
	rr = random.Random(seed)
	e, a = Vector(end), Vector(ax).normalized()
	side = a.cross(Vector((0, 1, 0))).normalized()
	upv = side.cross(a)
	for i in range(n):
		ang = 2 * math.pi * i / n + rr.uniform(-0.3, 0.3)
		off = (side * math.cos(ang) + upv * math.sin(ang)) * r * 0.55
		ln = rr.uniform(0.025, 0.075)
		bend = (side * rr.uniform(-0.15, 0.15) + upv * rr.uniform(-0.1, 0.1))
		p0 = e - a * 0.01 + off
		rod(tuple(p0), tuple(p0 + (a + bend).normalized() * ln), r * rr.uniform(0.28, 0.4), 0.0015, T("wood", "b"), sides=5,
			seed=seed + i, jit=0.15, rings=2)


def junk_spear_broken():
	R_ = 0.027
	y = R_ * 0.95
	# the back half: shaft on the floor, splintered at its front end
	rod((-0.8, y, 0.0), (-0.12, y, 0.0), R_ * 0.95, R_, T("wood", "dark"), sides=8, seed=81, jit=0.05, rings=4)
	splinters((-0.12, y, 0.0), (1, 0, 0), R_, 82)
	# the front half: splintered back end, iron socket and ring, a leaf-shaped head; it lies turned a little
	before = meshes()
	rod((-0.07, y, 0.0), (0.36, y, 0.0), R_, R_ * 0.97, T("wood", "dark"), sides=8, seed=83, jit=0.05, rings=3)
	splinters((-0.07, y, 0.0), (-1, 0, 0), R_, 84)
	iron = T("iron", "dark")
	rod((0.33, y, 0.0), (0.47, y, 0.0), R_ * 1.22, R_ * 0.8, iron, sides=8, seed=85, jit=0.03, rings=3)  # socket
	rod((0.335, y, 0.0), (0.355, y, 0.0), R_ * 1.42, R_ * 1.42, iron, sides=8, seed=86, jit=0.03, rings=2)  # ring
	head = [(0.45, -0.018), (0.53, -0.052), (0.6, -0.05), (0.75, -0.016), (0.8, 0.0), (0.75, 0.015), (0.6, 0.049),
		(0.53, 0.053), (0.45, 0.018)]
	slab(head, y - 0.011, 0.006, 0.022, STEEL("a"), k=0.6, toward=(0.62, 0.0))
	turn(meshes() - before, 9, (-0.07, 0.0, 0.0), off=(0.0, 0.0, 0.035))


# ================================================================ batch 2 (junk_shared.jpg, the rest of the top rows)
def board_slab(poly, y0, t, seed, m=None):
	"""One shield or rubble board: a flat chunky slab, painted as a plank (role "board")."""
	o = slab(poly, y0, t * 0.75, t, m or T("wood"), k=0.12)
	o["role"] = "board"
	return o


def board_poly(x0, x1, r, zcut=None, keep="lo", seed=0):
	"""A shield board from x0 to x1, cut round by the shield's circle (radius r). zcut: snapped across at about
	that z (a jagged line); keep "lo" = the part below it, "hi" = above."""
	def zc(x):
		return math.sqrt(max(r * r - x * x, 1e-6))
	xs = [x0 + (x1 - x0) * t for t in (0.0, 0.34, 0.67, 1.0)]
	lo = [(x, -zc(x)) for x in xs]
	hi = [(x, zc(x)) for x in reversed(xs)]
	if zcut is None:
		return lo + hi
	rr = random.Random(seed)
	cut = [(x0 + (x1 - x0) * t, zcut + rr.uniform(-0.03, 0.03)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
	if keep == "lo":
		return lo + list(reversed(cut))
	return cut + hi


def arc_band(r0, r1, y0, y1, a0, a1, m, n=12, seed=1):
	"""An iron rim: a band round part of a circle, from angle a0 to a1 (degrees, in the floor plane)."""
	rr = random.Random(seed)
	verts, faces = [], []
	for k in range(n + 1):
		a = math.radians(a0 + (a1 - a0) * k / n)
		w = rr.uniform(-0.002, 0.002)
		for r in (r0 + w, r1 + w):
			for y in (y0, y1 + rr.uniform(-0.002, 0.002)):
				verts.append((math.cos(a) * r, y, math.sin(a) * r))
	for k in range(n):
		b = 4 * k
		q = [b, b + 1, b + 3, b + 2, b + 4, b + 5, b + 7, b + 6]
		faces += [(q[0], q[1], q[5], q[4]), (q[2], q[3], q[7], q[6]), (q[0], q[2], q[6], q[4]), (q[1], q[3], q[7], q[5])]
	faces += [(0, 1, 3, 2), (4 * n, 4 * n + 1, 4 * n + 3, 4 * n + 2)]
	return K.mesh(verts, faces, m)


def shield(rim):
	"""A round shield of 6 boards, lying face up, broken in two: the left half keeps the boss, the right half lies
	pushed away and turned. rim=True: an iron rim with rivets (broken where the crack is)."""
	r, t, n = 0.3, 0.032, 6
	w = 2 * r / n
	left, right = set(), set()
	for i in range(n):
		x0, x1 = -r + i * w + 0.006, -r + (i + 1) * w - 0.006   # (1.2 cm dark gaps between the boards)
		if i == 3:   # the board the crack runs through: its top stays, its bottom goes with the right half
			before = meshes()
			board_slab(board_poly(x0, x1, r * 0.995, -0.09, "hi", seed=40 + i), 0.0, t, i)
			left |= meshes() - before
			before = meshes()
			board_slab(board_poly(x0, x1, r * 0.995, -0.09, "lo", seed=40 + i), 0.0, t, i)
			right |= meshes() - before
			continue
		if not rim and i == 5:
			continue   # the wooden shield's last board lies loose (below)
		before = meshes()
		board_slab(board_poly(x0, x1, r * 0.995), 0.0, t + (0.006 if i % 2 else -0.002) + J(0.002), i)
		new = meshes() - before
		if i < 3:
			left |= new
		else:
			right |= new
	before = meshes()
	iron = T("iron", "dark")
	kit.cylinder(0.075, 0.008, K.G((0.0, t + 0.003, 0.0)), iron, verts=11, bevel=0.002)   # the boss plate
	lump((0.0, t + 0.01, 0.0), (0.055, 0.035, 0.055), STEEL("a"), 41, seg=10, ring=6, jit=0.05)  # the round boss
	for k in range(5):
		a = math.radians(18 + k * 72)
		lump((math.cos(a) * 0.064, t + 0.008, math.sin(a) * 0.064), (0.008, 0.007, 0.008), iron, 42 + k, seg=6, ring=4)
	left |= meshes() - before
	if rim:
		top = math.degrees(math.atan2(math.sqrt(r * r - 0.1 ** 2), 0.1))   # where the crack leaves the rim
		for (a0, a1, side, sd) in ((top + 4, 266.0, left, 50), (-86.0, top - 4, right, 60)):
			before = meshes()
			arc_band(r * 0.975, r + 0.03, 0.0, t + 0.012, a0, a1, iron, n=14, seed=sd)
			span = a1 - a0
			for k in range(int(span // 32) + 1):
				a = math.radians(a0 + 10 + k * 32)
				lump((math.cos(a) * (r + 0.012), t + 0.012, math.sin(a) * (r + 0.012)), (0.011, 0.008, 0.011), STEEL("b"), sd + k,
					seg=7, ring=4)
			side |= meshes() - before
	turn(right, -11, (0.1, 0.0, 0.0), off=(0.08, 0.0, 0.035))
	if not rim:   # the loose board, a broken bit of another and two splinter chunks
		before = meshes()
		board_slab([(-0.21, -0.05), (0.2, -0.052), (0.215, 0.0), (0.2, 0.048), (-0.2, 0.05), (-0.215, 0.01)], 0.0, t, 50)
		turn(meshes() - before, 28, (0.0, 0.0, 0.0), off=(0.56, 0.0, 0.18))
		before = meshes()
		board_slab([(-0.08, -0.045), (0.07, -0.05), (0.09, -0.01), (0.075, 0.045), (-0.08, 0.05), (-0.095, 0.0)], 0.0, t * 0.9, 51)
		turn(meshes() - before, -35, (0.0, 0.0, 0.0), off=(0.5, 0.0, -0.28))
		for i, (x, z, a) in enumerate(((-0.4, -0.18, 20), (-0.38, 0.26, -40))):
			before = meshes()
			board_slab([(-0.035, -0.022), (0.04, -0.024), (0.03, 0.022), (-0.04, 0.02)], 0.0, 0.022, 52 + i)
			turn(meshes() - before, a, (0.0, 0.0, 0.0), off=(x, 0.0, z))


def junk_shield_wood():
	shield(False)


def junk_shield_iron():
	shield(True)


# ---------------------------------------------------------------- junk_rubble_wood
def rubble_board(x, z, ln, wd, yaw, y0, t, seed):
	rr = random.Random(seed)
	h = ln / 2
	a = jag(-h, wd / 2, -wd / 2, 5, 0.03, seed)      # the left end, snapped (top to bottom)
	b = jag(h, -wd / 2, wd / 2, 5, 0.03, seed + 1)   # the right end
	before = meshes()
	board_slab([(px, pz * rr.uniform(0.97, 1.03)) for (px, pz) in a + b], y0, t, seed)
	turn(meshes() - before, yaw, (0.0, 0.0, 0.0), off=(x, 0.0, z))


def junk_rubble_wood():
	# (x, z, length, width, turn, height it lies at, thickness): same-height boards never overlap (no flicker)
	for i, b in enumerate((
			(-0.05, 0.1, 0.85, 0.12, 8, 0.0, 0.03), (0.05, -0.13, 0.6, 0.11, -12, 0.0, 0.03), (0.52, 0.0, 0.36, 0.12, 80, 0.0, 0.03),
			(-0.05, 0.0, 0.7, 0.12, 55, 0.026, 0.03), (-0.42, 0.02, 0.4, 0.1, -70, 0.026, 0.028),
			(0.12, -0.02, 0.55, 0.11, -40, 0.052, 0.03))):
		rubble_board(*b, seed=100 + 7 * i)
	for i, (x, z, a, s) in enumerate(((0.42, -0.27, 30, 1.0), (-0.58, -0.17, -15, 0.8), (0.3, 0.3, 60, 0.7), (-0.32, 0.3, 10, 0.9),
			(0.7, 0.22, -25, 0.6))):
		before = meshes()
		board_slab([(-0.05 * s, -0.018), (0.055 * s, -0.02), (0.07 * s, 0.0), (0.05 * s, 0.02), (-0.06 * s, 0.017)], 0.0, 0.018, 130 + i)
		turn(meshes() - before, a, (0.0, 0.0, 0.0), off=(x, 0.0, z))


def _footprint(x, z, ln, wd, yaw):
	"""The four floor corners of a board turned by yaw (the same way turn() turns it)."""
	c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
	return [(x + px * c + pz * s, z - px * s + pz * c) for (px, pz) in
		((-ln / 2, -wd / 2), (ln / 2, -wd / 2), (ln / 2, wd / 2), (-ln / 2, wd / 2))]


def _overlap(a, b):
	"""Do two turned rectangles (corner lists) overlap? (separating-axis test)"""
	for poly in (a, b):
		for i in range(4):
			(x0, z0), (x1, z1) = poly[i], poly[(i + 1) % 4]
			nx, nz = z1 - z0, x0 - x1
			pa = [nx * px + nz * pz for (px, pz) in a]
			pb = [nx * px + nz * pz for (px, pz) in b]
			if max(pa) < min(pb) or max(pb) < min(pa):
				return False
	return True


def rubble_pile(seed):
	"""Owner, Nov 20 ("I really like how you made them"): more plank piles, each its own spread and stacking. Boards
	are dropped one by one; a board that lands on others rests on the highest one under it (4 mm into it, so it
	touches), so no two boards ever lie at the same height in the same place (no flicker). Piles stay 3 boards high."""
	rr = random.Random(seed)
	sx, sz = rr.uniform(0.55, 0.95), rr.uniform(0.3, 0.5)   # how far the pile spreads (half sizes)
	laid = []   # (corners, top)
	n = rr.randint(6, 9)
	tries = 0
	while len(laid) < n and tries < 80:
		tries += 1
		ln, wd, t = rr.uniform(0.3, 0.85), rr.uniform(0.09, 0.13), rr.uniform(0.026, 0.034)
		x, z = rr.uniform(-sx, sx) * (0.6 if ln > 0.6 else 1.0), rr.uniform(-sz, sz)
		yaw = rr.uniform(-90, 90)
		fp = _footprint(x, z, ln + 0.06, wd + 0.01, yaw)       # (with its jagged ends: keep clear of this)
		core = _footprint(x, z, ln - 0.06, wd - 0.02, yaw)     # (surely solid board: rest only on this)
		near = [(c, cc, top) for (c, cc, top) in laid if _overlap(fp, c)]
		if any(not _overlap(core, cc) for (c, cc, top) in near):
			continue   # it would only graze a board's edge (it would hover or sink into it): drop it somewhere else
		y0 = max(top for (c, cc, top) in near) - 0.004 if near else 0.0
		if y0 > 0.075:
			continue
		rubble_board(x, z, ln, wd, yaw, y0, t, seed=seed + 11 * len(laid))
		laid.append((fp, core, y0 + t))
	for i in range(rr.randint(4, 8)):   # chips and splinters, lying about (more of them further out)
		for _ in range(20):
			x, z, a, s = rr.uniform(-sx - 0.2, sx + 0.2), rr.uniform(-sz - 0.15, sz + 0.15), rr.uniform(0, 180), rr.uniform(0.6, 1.1)
			fp = _footprint(x, z, 0.14 * s, 0.045, a)
			if not any(_overlap(fp, c) for (c, cc, top) in laid):
				break
		else:
			continue
		before = meshes()
		board_slab([(-0.05 * s, -0.018), (0.055 * s, -0.02), (0.07 * s, 0.0), (0.05 * s, 0.02), (-0.06 * s, 0.017)], 0.0, 0.018,
			seed + 300 + i)
		turn(meshes() - before, a, (0.0, 0.0, 0.0), off=(x, 0.0, z))
		laid.append((fp, fp, 0.018))


# ---------------------------------------------------------------- junk_rags
def rag(cx, cz, rx, rz, seed, m, holes=2, fold=0.03):
	"""A torn cloth lying crumpled on the floor: a wavy sheet with a ragged edge, holes and one fold."""
	import bmesh
	rr = random.Random(seed)
	bm = bmesh.new()
	bmesh.ops.create_grid(bm, x_segments=26, y_segments=26, size=1.0)
	mx = max(max(abs(v.co.x), abs(v.co.y)) for v in bm.verts)
	for v in bm.verts:
		v.co.x /= mx
		v.co.y /= mx
	ph = [rr.uniform(0, 6.28) for _ in range(3)]
	hole_c = [(rr.uniform(-0.45, 0.45), rr.uniform(-0.45, 0.45), rr.uniform(0.1, 0.17)) for _ in range(holes)]
	kill = []
	for f in bm.faces:
		c = f.calc_center_median()
		a = math.atan2(c.y, c.x)
		edge = 0.82 + 0.09 * math.sin(3 * a + ph[0]) + 0.06 * math.sin(7 * a + ph[1]) + rr.uniform(-0.05, 0.05)
		if math.hypot(c.x, c.y) > edge or any(math.hypot(c.x - hx, c.y - hy) < hr for (hx, hy, hr) in hole_c):
			kill.append(f)
	bmesh.ops.delete(bm, geom=kill, context="FACES")
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
	cell = 2.0 / 26
	for v in bm.verts:   # a ragged, frayed edge instead of the grid's steps
		if v.is_boundary:
			v.co.x += rr.uniform(-0.45, 0.45) * cell
			v.co.y += rr.uniform(-0.45, 0.45) * cell
	fa = rr.uniform(0, 3.14)
	for v in bm.verts:
		u, w = v.co.x, v.co.y
		d = u * math.cos(fa) + w * math.sin(fa)
		v.co.z = 0.004 + 0.006 * (1 + math.sin(u * 5 + ph[2]) * math.cos(w * 4)) + fold * math.exp(-((d - 0.2) / 0.16) ** 2) + rr.uniform(0, 0.003)
		v.co.x = cx + u * rx
		v.co.y = -cz + w * rz
	me = bpy.data.meshes.new("rag")
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new("rag", me)
	bpy.context.scene.collection.objects.link(o)
	sol = o.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.006
	sol.offset = 1.0
	return kit._finish(o, m, 0, 0)


def junk_rags():
	rag(-0.18, 0.02, 0.27, 0.22, 7, tinted("sack", "a", (1.25, 1.18, 1.0), "rag"), holes=3, fold=0.035)
	rag(0.04, 0.24, 0.1, 0.08, 9, tinted("sack", "b", (1.15, 1.08, 0.9), "rag"), holes=1, fold=0.012)
	# the burst sack: slumped, empty, its neck gathered
	sack = T("sack", "a")
	bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=9, radius=1, location=(0, 0, 0))
	o = bpy.context.object
	rr = random.Random(11)
	for v in o.data.vertices:
		v.co *= rr.uniform(0.93, 1.07)
		if v.co.z < -0.55:
			v.co.z = -0.55 + (v.co.z + 0.55) * 0.15   # flat bottom where it sits
		if v.co.z > 0.62:
			k = 0.42 + 0.25 * (1.0 - v.co.z)          # the gathered neck
			v.co.x *= k
			v.co.y *= k
			v.co.z = 0.62 + (v.co.z - 0.62) * 1.6
	o.scale = (0.17, 0.15, 0.12)
	o.location = K.G((0.22, 0.068, -0.08))
	o.rotation_euler = (math.radians(12), math.radians(-8), math.radians(20))
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	mz = min(v.co.z for v in o.data.vertices) - 0.004   # sit it on the floor (4 mm into it: the soft round-off lifts it)
	for v in o.data.vertices:
		v.co.z -= mz
	kit._finish(o, sack, 0, 0)
	kit.soft(o, 1)   # cloth: soft and round, not cut faces
	top = max((v.co for v in o.data.vertices), key=lambda c: c.z).copy()
	tx, ty, tz = top.x, -top.y, top.z   # (back to game axes: x, z, y)
	lump((tx, tz - 0.004, ty), (0.032, 0.012, 0.03), DARK(), 12, seg=8, ring=4)   # the open neck, dark inside
	lump((tx, tz + 0.004, ty), (0.045, 0.014, 0.042), sack, 13, seg=9, ring=4, jit=0.15)  # the frayed top round it
	# (owner, Nov 20: no rope tie and no torn hole on its side: both looked like blobs)


def rags_pair(seed):
	"""Owner, Nov 20 ("I really like the rag texture"): more rag piles, two pieces each, every one different: a big
	rag and a small one, their own sizes, shapes, holes, folds and places."""
	rr = random.Random(seed)
	big = (rr.uniform(0.2, 0.3), rr.uniform(0.15, 0.24))
	if rr.random() < 0.5:
		big = (big[1], big[0])
	before = meshes()
	rag(0.0, 0.0, big[0], big[1], seed, tinted("sack", "a", (1.25, 1.18, 1.0), "rag"), holes=rr.randint(1, 3),
		fold=rr.uniform(0.015, 0.04))
	turn(meshes() - before, rr.uniform(0, 360), (0.0, 0.0, 0.0))
	a = rr.uniform(0, 6.28)
	d = max(big) + rr.uniform(0.04, 0.14)
	s = (rr.uniform(0.07, 0.15), rr.uniform(0.06, 0.12))
	before = meshes()
	rag(0.0, 0.0, s[0], s[1], seed + 50, tinted("sack", "b", (1.15, 1.08, 0.9), "rag"), holes=rr.randint(0, 1),
		fold=rr.uniform(0.0, 0.015))
	turn(meshes() - before, rr.uniform(0, 360), (0.0, 0.0, 0.0), off=(math.cos(a) * d, 0.0, math.sin(a) * d))


# ================================================================ batch 3 (junk_small_mine.jpg, small dungeons)
def dull(m):
	"""A rougher, less shiny copy of a metal (old dented iron that doesn't mirror the light)."""
	name = m.name + "_dull"
	if name in bpy.data.materials:
		return bpy.data.materials[name]
	d = m.copy()
	d.name = name
	d["tile"] = m["tile"]
	b = d.node_tree.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = 0.8
	b.inputs["Metallic"].default_value = 0.25
	return d


def GLASS():
	"""Old smoky lantern glass: dark green-grey, shiny."""
	if "lantern_glass" in bpy.data.materials:
		return bpy.data.materials["lantern_glass"]
	m = bpy.data.materials.new("lantern_glass")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (0.2, 0.26, 0.25, 1)
	b.inputs["Roughness"].default_value = 0.12
	return m


def RUST(v="a"):
	return tinted("iron", v, (1.18, 0.98, 0.8), "rust")


def bolt(c, up=True, r=0.011, m=None):
	"""A six-sided bolt head: facing up (up=True) or facing the front (+z)."""
	return kit.cylinder(r, 0.008, K.G(c), m or T("iron", "dark"), rot=(0, 0, 0) if up else (90, 0, 0), verts=6, bevel=0.002)


def junk_pickaxe_broken():
	"""A pickaxe head lying flat, its handle snapped off short in the socket, the broken-off piece beside it."""
	head = RUST("a")
	out, inner = [], []
	ts = [i / 10 for i in range(-10, 11)]
	for t in ts:   # a crescent: the picks bend toward the handle (+z) to sharp tips (owner, Nov 20: it bent the wrong way)
		x, zc, w = 0.29 * t, 0.17 * t * t, 0.038 * (1 - abs(t)) ** 0.7 + 0.004
		out.append((x, zc + w))
		inner.append((x, zc + w * 0.25))
	for t in reversed(ts):
		x, zc, w = 0.29 * t, 0.17 * t * t, 0.038 * (1 - abs(t)) ** 0.7 + 0.004
		out.append((x, zc - w))
		inner.append((x, zc - w * 0.25))
	slab(out, 0.012, 0.012, 0.04, head, inner=inner)
	K.blk((0.0, 0.032, 0.0), (0.085, 0.064, 0.092), RUST("b"), bevel=0.008)   # the socket (its faces 7 mm past the head's edges)
	for x in (-0.025, 0.025):
		bolt((x, 0.066, 0.0))
	bolt((0.0, 0.032, 0.047), up=False)
	R_, y = 0.024, 0.031
	rod((0.0, y, 0.03), (0.0, y, 0.15), R_, R_ * 0.97, T("wood", "dark"), sides=8, seed=301, jit=0.05)   # the stub
	splinters((0.0, y, 0.15), (0, 0, 1), R_, 302)
	before = meshes()   # the broken-off piece, lying turned beside it, with its iron end band
	rod((0.0, R_, 0.0), (0.0, R_, 0.21), R_ * 0.97, R_, T("wood", "dark"), sides=8, seed=303, jit=0.05)
	splinters((0.0, R_, 0.0), (0, 0, -1), R_, 304)
	rod((0.0, R_, 0.17), (0.0, R_, 0.215), R_ * 1.22, R_ * 1.22, RUST("c"), sides=8, seed=305, jit=0.03, rings=2)
	bolt((0.0, R_ * 2.22 + 0.002, 0.193))
	turn(meshes() - before, -78, (0.0, 0.0, 0.0), off=(-0.08, 0.0, 0.3))


def junk_shovel_bent():
	"""A dented shovel lying flat, its shaft bent, a D-shaped grip at the end."""
	blade = []
	for i in range(13):   # a rounded spade: square shoulders, round pointed tip (toward -x)
		a = math.radians(90 + i * 180 / 12)
		r = 1.0 + 0.1 * math.sin(i * 1.7)
		blade.append((-0.29 + math.cos(a) * 0.19 * r, math.sin(a) * 0.14 * r))
	blade += [(-0.1, -0.135), (-0.08, -0.04), (-0.08, 0.04), (-0.1, 0.135)]
	slab(blade, 0.0, 0.01, 0.018, RUST("a"), k=0.25, toward=(-0.2, 0.0))
	for sz in (-1, 1):   # the blade's raised side edges (a scoop), dented
		rod((-0.4, 0.012, sz * 0.122), (-0.12, 0.014, sz * 0.13), 0.009, 0.011, RUST("b"), sides=6, seed=310 + sz, jit=0.2)
	y = 0.022
	rod((-0.12, y, 0.0), (-0.02, y, 0.0), 0.03, 0.024, RUST("c"), sides=8, seed=312, jit=0.04)   # the socket
	bolt((-0.07, y + 0.03, 0.0))
	wood = T("wood", "dark")
	pts = [(-0.03, y, 0.0), (0.17, y, 0.012), (0.3, y, 0.07), (0.48, y, 0.1)]   # the shaft, bent in the middle
	for i in range(3):
		rod(pts[i], pts[i + 1], 0.02, 0.02, wood, sides=8, seed=313 + i, jit=0.04, rings=2)
	for p in pts[1:3]:
		lump(p, (0.021, 0.021, 0.021), wood, 320 + int(p[0] * 100), seg=8, ring=5, jit=0.03)   # (knuckles at the bends)
	# the D grip: two iron straps from the shaft end and a wooden cross grip
	ex, ez = pts[-1][0], pts[-1][2]
	for sz in (-1, 1):
		rod((ex - 0.01, y, ez), (ex + 0.1, y, ez + sz * 0.065), 0.011, 0.011, RUST("b"), sides=6, seed=325 + sz, jit=0.05, rings=2)
	rod((ex + 0.1, y, ez - 0.075), (ex + 0.1, y, ez + 0.075), 0.019, 0.019, wood, sides=8, seed=327, jit=0.04, rings=2)
	rod((ex - 0.02, y, ez), (ex + 0.02, y, ez), 0.025, 0.025, RUST("c"), sides=8, seed=328, jit=0.03, rings=2)   # ferrule


def hewn_beam(x0, x1, H, D, seed, brk=0, tear=0.16, cracks=((-0.4, 0.1, 1.2),), moss=2):
	"""A hand-hewn beam lying along x (owner, Nov 20: two plain boxes with spikes were not good enough): a rounded,
	uneven square cross-section that changes along its length, real cracks cut into the wood (dark grooves), moss
	patches, and at a snapped end (brk = +1: the x1 end, -1: the x0 end) torn fibres: every strip of the surface ends
	at its own length (the top ones longest, peeling), closed by a spiky fan, not a flat cut. Returns (object, rings)."""
	import bmesh
	rr = random.Random(seed)
	NA = 32                                   # points round the beam
	n_r = max(8, int((x1 - x0) / 0.035))      # rings along it
	ph = [rr.uniform(0, 6.28) for _ in range(8)]
	cy = 0.016 + H / 2
	tear_len = [tear * (0.25 + 0.75 * max(0.0, math.sin(2 * math.pi * k / NA))) * rr.uniform(0.35, 1.0) for k in range(NA)]
	for k in range(NA):   # fibres come in strips of 2-3 neighbours
		if rr.random() < 0.5:
			tear_len[(k + 1) % NA] = tear_len[k] * rr.uniform(0.85, 1.05)
	crack_lines = [(cx0, cx1, ca + rr.uniform(-0.2, 0.2), rr.uniform(0, 6.28)) for (cx0, cx1, ca) in cracks]
	moss_spots = [(rr.uniform(x0 + 0.1, x1 - 0.1), rr.uniform(1.2, 1.9), rr.uniform(0.03, 0.055)) for _ in range(moss)]

	def section(x, k):
		"""The surface point at length x, angle step k (game coords)."""
		a = 2 * math.pi * k / NA
		c, s = math.cos(a), math.sin(a)
		ex = 2 / 4.5   # a rounded square (no perfect box, no perfect circle)
		pz = math.copysign(abs(c) ** ex, c) * D / 2
		py = math.copysign(abs(s) ** ex, s) * H / 2
		bump = (0.0045 * math.sin(x * 9 + ph[0] + a * 3) + 0.003 * math.sin(x * 23 + ph[1] + a * 5)
			+ 0.0025 * math.sin(a * 7 + ph[2]) + 0.0015 * math.sin(x * 41 + a * 2 + ph[3]))
		bump += 0.003 * math.sin(math.floor(x / 0.18 + ph[4]) * 2.7 + math.floor(a / 1.57) * 1.3)   # adze facets
		r = 1 + bump / (0.5 * min(H, D))
		bend_y = 0.004 * math.sin(x * 2.2 + ph[5])
		bend_z = 0.005 * math.sin(x * 1.7 + ph[6])
		p = Vector((x, cy + bend_y + py * r, bend_z + pz * r))
		for (cx0, cx1, ca, cp) in crack_lines:   # cut the cracks in
			if cx0 <= x <= cx1:
				aa = ca + 0.12 * math.sin(x * 11 + cp)
				d = abs(math.atan2(math.sin(a - aa), math.cos(a - aa)))
				if d < 0.12:
					f = min(1.0, (x - cx0) / 0.08, (cx1 - x) / 0.08)
					p -= Vector((0, py, pz)).normalized() * 0.017 * f * (1 - d / 0.12)
		return p

	bm = bmesh.new()
	uv = bm.loops.layers.uv.new("UVMap")   # (the same name as every other part: one map when they are joined)
	rings = []
	xs = [x0 + (x1 - x0) * i / n_r for i in range(n_r + 1)]
	for i, x in enumerate(xs):
		ring = []
		for k in range(NA):
			xx = x
			at_end = (brk > 0 and i == n_r) or (brk < 0 and i == 0)
			dist = (n_r - i) if brk > 0 else i
			if brk and not at_end and dist <= 2:   # the wood loosens just before the break
				xx += brk * tear_len[k] * 0.15 * (1 - dist / 3)
			if at_end:
				xx += brk * tear_len[k]
			p = section(xx, k)
			if at_end:   # the torn fibres pinch in a little
				p = Vector((p.x, cy + (p.y - cy) * rr.uniform(0.82, 0.97), p.z * rr.uniform(0.82, 0.97)))
			ring.append(bm.verts.new((p.x, -p.z, p.y)))   # (game -> Blender)
		rings.append(ring)
	faces = []
	for i in range(n_r):
		for k in range(NA):
			k2 = (k + 1) % NA
			f = bm.faces.new((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]))
			faces.append((f, k))
	for (end_i, sgn) in ((0, -1), (n_r, 1)):
		ring = rings[end_i]
		if (brk > 0 and end_i == n_r) or (brk < 0 and end_i == 0):
			mean = sum((v.co for v in ring), Vector()) / NA
			ctr = bm.verts.new(mean - Vector((sgn * 0.05, 0, 0)))   # (the fan's centre sits back: the fibres stick out)
			for k in range(NA):
				bm.faces.new((ring[k], ring[(k + 1) % NA], ctr))
		else:
			bm.faces.new(ring)
	# paint: the plank painting wrapped round (one painting per face width), along the grain; cracks dark; moss green
	for f, k in faces:
		xm = sum(v.co.x for v in f.verts) / 4
		am = 2 * math.pi * (k + 0.5) / NA
		for (cx0, cx1, ca, cp) in crack_lines:
			aa = ca + 0.12 * math.sin(xm * 11 + cp)
			if cx0 + 0.03 <= xm <= cx1 - 0.03 and abs(math.atan2(math.sin(am - aa), math.cos(am - aa))) < 0.1:
				f.material_index = 0   # (owner, Nov 20: no dark patches; the groove itself shows the crack)
				f.tag = True
		if not f.tag:
			for (mx, ma, mr) in moss_spots:
				if math.hypot(xm - mx, (am - ma) * 0.075) < mr * rr.uniform(0.7, 1.0):
					f.material_index = 2
		for lp, kk in zip(f.loops, (k, k + 1, k + 1, k)):
			lp[uv].uv = (kk / NA * 4.0 + seed * 0.13, lp.vert.co.x / 1.1)
	for f in bm.faces:
		if len(f.verts) != 4:   # the end caps: the painting laid flat across them
			for lp in f.loops:
				lp[uv].uv = (lp.vert.co.y * 4 + 0.5, lp.vert.co.z * 4 + 0.5)
	ring_pts = [[(v.co.x, v.co.z, -v.co.y) for v in ring] for ring in rings]   # (back in game coords)
	me = bpy.data.meshes.new("beam")
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new("beam", me)
	bpy.context.scene.collection.objects.link(o)
	for m in (kit.tex_mat("shackplank", f"v{seed % 8}"), tinted("shackplank", f"v{seed % 8}", (0.42, 0.36, 0.3), "crack"),
			tinted("soil", "a", (0.62, 0.85, 0.35), "moss")):   # (cracks: the same wood, much darker; round 2 black looked like patches)
		me.materials.append(m)
	for p in me.polygons:   # smooth: with this many small faces, flat shading looked like blocks (round 1)
		p.use_smooth = len(p.vertices) == 4 and p.material_index != 1
	K.fix_normals(o)
	return o, ring_pts


def beam_band(rings, i, cy, m):
	"""An iron band hugging the beam's own uneven shape round ring i: 1 cm proud, 5.4 cm wide, with bolts."""
	ring = rings[i]
	x = sum(p[0] for p in ring) / len(ring)
	n = len(ring)
	verts, faces = [], []
	for (xx, g) in ((x - 0.027, 0.011), (x + 0.027, 0.011), (x + 0.027, -0.012), (x - 0.027, -0.012)):
		for (_, y, z) in ring:
			dy, dz = y - cy, z
			ln = math.hypot(dy, dz)
			verts.append((xx, cy + dy * (1 + g / ln), dz * (1 + g / ln)))
	for k in range(n):
		k2 = (k + 1) % n
		for (a, b) in ((0, 1), (1, 2), (2, 3), (3, 0)):
			faces.append((a * n + k, a * n + k2, b * n + k2, b * n + k))
	K.mesh(verts, faces, m)
	top = max(ring, key=lambda p: p[1])
	front = max(ring, key=lambda p: p[2])
	bolt((x, top[1] + 0.012, top[2]))
	bolt((x, front[1], front[2] + 0.012), up=False)


def junk_beam_snapped():
	"""A cracked, hand-hewn mine support beam, snapped in two: torn fibres at the break, moss, an iron band with bolts
	on each piece, a few chips on the floor."""
	H, D = 0.15, 0.17
	cy = 0.016 + H / 2
	_, rings = hewn_beam(-0.72, 0.2, H, D, 381, brk=1, tear=0.26,
		cracks=((-0.5, 0.14, 1.35), (-0.2, 0.15, 0.25), (-0.65, -0.25, 2.2)), moss=0)   # (owner, Nov 20: no dark spots)
	beam_band(rings, 4, cy, RUST("a"))
	for k in range(4):   # a few long fibres peeling off the top at the break
		a = math.radians(60 + k * 20)
		y0, z0 = cy + math.sin(a) * H * 0.4, math.cos(a) * D * 0.4
		rod((0.14, y0, z0), (0.3 + k * 0.015, y0 + 0.01 + k * 0.004, z0 * 1.12), 0.011, 0.0015, T("wood", "b"), sides=4,
			seed=390 + k, jit=0.25, rings=3)
	before = meshes()
	_, rings2 = hewn_beam(0.44, 0.84, H, D, 385, brk=-1, tear=0.22, cracks=((0.45, 0.72, 0.6),), moss=0)
	beam_band(rings2, len(rings2) - 5, cy, RUST("b"))
	turn(meshes() - before, 8, (0.44, 0.0, 0.0), off=(0.0, 0.0, 0.04))
	for i, (x, z, a, s) in enumerate(((0.12, 0.22, 20, 1.0), (0.3, 0.27, -30, 0.8), (0.42, 0.2, 60, 0.6), (0.2, -0.2, 100, 0.7))):
		before = meshes()   # chips on the floor
		board_slab([(-0.05 * s, -0.012), (0.055 * s, -0.014), (0.065 * s, 0.0), (0.05 * s, 0.014), (-0.06 * s, 0.011)], 0.0, 0.014, 350 + i)
		turn(meshes() - before, a, (0.0, 0.0, 0.0), off=(x, 0.0, z))


def junk_helmet():
	"""A dented miner's helmet sitting on its brim: a dome, a riveted band and a front badge, a dent."""
	metal = dull(RUST("b"))   # (round 1: shiny facets looked like mirrors)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=22, ring_count=11, radius=1, location=(0, 0, 0))
	o = bpy.context.object
	rr = random.Random(361)
	dent = Vector((-0.55, -0.45, 0.7)).normalized()   # (Blender axes) front left, up high
	for v in o.data.vertices:
		v.co *= rr.uniform(0.97, 1.03)
		if v.co.z < 0:
			v.co.z = 0.0
		d = (v.co.normalized() - dent).length if v.co.length > 0.1 else 9
		if d < 0.45:
			v.co *= 1 - 0.16 * (1 - d / 0.45)
	o.scale = (0.125, 0.135, 0.12)
	o.location = (0, 0, 0.016)
	bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
	kit._finish(o, metal, 0, 0)
	ring = []   # the brim: a wavy flat ring
	n = 18
	verts, faces = [], []
	for k in range(n):
		a = 2 * math.pi * k / n
		r0, r1 = 0.118, 0.175 + rr.uniform(-0.008, 0.008) + (0.012 if 2 < k < 6 else 0)
		y = rr.uniform(0.0, 0.005)
		for r in (r0, r1):
			for yy in (y, y + 0.016):
				verts.append((math.cos(a) * r, yy, math.sin(a) * r))
	for k in range(n):
		b, c = 4 * k, 4 * ((k + 1) % n)
		faces += [(b, c, c + 2, b + 2), (b + 1, b + 3, c + 3, c + 1), (b, b + 1, c + 1, c), (b + 2, c + 2, c + 3, b + 3)]
	K.mesh(verts, faces, dull(RUST("a")))
	arc_band(0.122, 0.136, 0.014, 0.05, 0, 360, dull(RUST("c")), n=18, seed=362)   # the band round the dome
	for k in range(6):
		a = math.radians(30 + k * 60)
		lump((math.cos(a) * 0.137, 0.032, math.sin(a) * 0.137), (0.009, 0.009, 0.009), T("iron", "dark"), 363 + k, seg=6, ring=4)
	kit.cylinder(0.034, 0.012, K.G((0.0, 0.05, 0.14)), RUST("c"), rot=(90 - 18, 0, 0), verts=8, bevel=0.003)   # the badge
	for sx in (-1, 1):   # a raised mountain mark on it
		K.blk((sx * 0.009, 0.052, 0.148), (0.006, 0.026, 0.006), T("iron", "dark"), bevel=0.0015, rz=-sx * 28, rx=-18)


def junk_lantern():
	"""A square miner's lantern lying on its side, its top pane smashed, glass shards on the floor."""
	fr = RUST("a")
	L, S = 0.3, 0.17
	for x in (-L / 2, L / 2):   # the two end caps
		K.blk((x, S / 2 + 0.002, 0.0), (0.04, S + 0.004, S + 0.012), RUST("b"), bevel=0.008)
	for (yy, zz) in ((0.018, -0.07), (0.018, 0.07), (S - 0.014, -0.07), (S - 0.014, 0.07)):   # four corner bars
		K.blk((0.0, yy, zz), (L - 0.02, 0.026, 0.026), fr, bevel=0.005)
	glass = GLASS()
	K.blk((0.0, 0.016, 0.0), (L - 0.04, 0.004, 0.12), glass, bevel=0)   # the bottom pane (on the floor side)
	K.blk((0.0, S / 2, -0.07), (L - 0.04, 0.12, 0.004), glass, bevel=0)   # the back pane, whole
	K.blk((-0.03, 0.045, 0.07), (0.2, 0.04, 0.004), glass, bevel=0)        # the front pane: only a low strip left
	K.blk((0.09, 0.14, 0.07), (0.06, 0.035, 0.004), glass, bevel=0, rz=25)  # and a shard in the top corner
	# the top pane, smashed: only jagged pieces left round its edges
	for i, poly in enumerate(([(-0.13, -0.065), (-0.02, -0.065), (-0.05, -0.03), (-0.1, -0.035), (-0.13, 0.01)],
			[(0.04, 0.065), (0.13, 0.065), (0.13, -0.02), (0.1, 0.01), (0.07, 0.03)])):
		slab(poly, S - 0.017, 0.003, 0.004, glass, k=0.1)
	kit.cylinder(0.018, 0.06, K.G((0.02, 0.036, 0.0)), kit.mat("linen"), rot=(0, 90, 0), verts=8, bevel=0.003)   # a candle stub, fallen
	for x in (-L / 2, L / 2):
		bolt((x, S + 0.006, 0.0))   # (on the end caps)
	K.blk((-L / 2 - 0.03, 0.012, 0.0), (0.03, 0.024, 0.024), RUST("c"), bevel=0.004)   # the hanging eye
	kit.ring(0.036, 0.009, K.G((-L / 2 - 0.075, 0.01, 0.0)), RUST("c"), seg=12)            # the ring, lying flat
	for i, (x, z, a, s) in enumerate(((0.26, 0.12, 20, 1.0), (0.32, 0.03, 75, 0.7), (0.22, 0.22, -30, 0.8), (0.34, 0.17, 140, 0.6))):
		before = meshes()   # glass shards on the floor
		slab([(-0.03 * s, -0.015 * s), (0.035 * s, -0.02 * s), (0.02 * s, 0.022 * s), (-0.02 * s, 0.016 * s)], 0.0, 0.003, 0.004, glass, k=0.1)
		turn(meshes() - before, a, (0.0, 0.0, 0.0), off=(x, 0.0, z))



# ================================================================ batch 4 (junk_medium_stone.jpg, medium dungeons)
# (owner, Nov 20: no black spots; so no dark paint patches or moss on these either)
def spin(objs, axis, deg, pivot=(0.0, 0.0, 0.0)):
	"""Turn finished parts round a game-space axis ("x", "y" or "z") through pivot (game coords)."""
	ax = {"x": (1, 0, 0), "y": (0, 0, 1), "z": (0, -1, 0)}[axis]   # (the same axis in Blender)
	piv = Vector(K.G(pivot))
	rot = Matrix.Rotation(math.radians(deg), 4, Vector(ax))
	for name in objs:
		o = bpy.data.objects[name]
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)
		for v in o.data.vertices:
			v.co = piv + (rot @ (v.co - piv))


def drop(objs, sink=0.004):
	"""Set turned parts down so their lowest point is on the floor (sink: this far into it, so they touch)."""
	# (matrix_basis, not matrix_world: after spin() the world matrix is out of date until Blender redraws, so the
	# statue head was measured wrong and left 10 cm in the air, owner Nov 20)
	lo = min((bpy.data.objects[n].matrix_basis @ v.co).z for n in objs for v in bpy.data.objects[n].data.vertices)
	for n in objs:
		o = bpy.data.objects[n]
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)
		for v in o.data.vertices:
			v.co.z -= lo + sink


def lathe(profile, c, m, seed, n=20, jit=0.025, crack=None, top_cap=True):
	"""A pot turned on a wheel: profile = [(radius, height), ...] bottom to top, spun round an upright axis at c (x, z)
	with a little hand-made wobble. crack = (angle, from height, to height): a zigzag groove pressed into it."""
	rr = random.Random(seed)
	wob = [rr.uniform(1 - jit, 1 + jit) for _ in range(n)]
	verts, faces = [], []
	for j, (r, y) in enumerate(profile):
		for k in range(n):
			a = 2 * math.pi * k / n
			rk = r * (wob[k] * 0.6 + 0.4 * rr.uniform(1 - jit, 1 + jit))
			if crack and crack[1] <= y <= crack[2]:
				ca = crack[0] + 0.18 * math.sin(y * 60)
				d = abs(math.atan2(math.sin(a - ca), math.cos(a - ca)))
				if d < 0.2:
					rk -= 0.01 * (1 - d / 0.2)
			verts.append((c[0] + math.cos(a) * rk, y, c[1] + math.sin(a) * rk))
	rows = len(profile)
	for j in range(rows - 1):
		for k in range(n):
			k2 = (k + 1) % n
			faces.append((j * n + k, j * n + k2, (j + 1) * n + k2, (j + 1) * n + k))
	faces.append(tuple(range(n - 1, -1, -1)))
	if top_cap:
		faces.append(tuple((rows - 1) * n + k for k in range(n)))
	return K.mesh(verts, faces, m)


CLAY = lambda v="a": tinted("clay", v, (1.12, 0.82, 0.62), "urn")


def urn_body(cx, cz, seed, crack=None):
	"""A burial urn with its lid on: a fat belly, a carved band of raised diamonds round it, a knob on top."""
	prof = [(0.07, 0.0), (0.1, 0.012), (0.135, 0.06), (0.152, 0.12), (0.15, 0.18), (0.13, 0.24), (0.098, 0.275),
		(0.085, 0.29), (0.096, 0.296), (0.098, 0.31)]
	lathe(prof, (cx, cz), CLAY("a"), seed, crack=crack)
	lathe([(0.104, 0.304), (0.106, 0.322), (0.088, 0.338), (0.05, 0.35), (0.03, 0.352)], (cx, cz), CLAY("b"), seed + 1)   # the lid
	lump((cx, 0.372, cz), (0.032, 0.026, 0.032), CLAY("b"), seed + 2, seg=8, ring=5, jit=0.06)                          # the knob
	for y in (0.105, 0.195):   # two raised rings round the belly
		lathe([(0.152, y - 0.006), (0.158, y - 0.004), (0.158, y + 0.004), (0.152, y + 0.006)], (cx, cz), CLAY("c"), seed + 3 + int(y * 100), jit=0.01)
	for k in range(10):   # the carved band: raised diamonds between the rings
		a = 2 * math.pi * (k + 0.5) / 10
		r = 0.152
		K.blk((cx + math.cos(a) * r, 0.15, cz + math.sin(a) * r), (0.034, 0.034, 0.012), CLAY("c"), bevel=0.003,
			ry=-math.degrees(a) + 90, rz=45)


def junk_urns():
	"""Three burial urns side by side: one whole, one cracked from rim to belly, one smashed with its shards about."""
	urn_body(-0.36, 0.0, 401)
	urn_body(0.0, -0.02, 411, crack=(math.radians(-80), 0.05, 0.33))
	smashed_urn(0.38, 0.02, 421)
	for i, (x, z, a, sc) in enumerate(((0.6, 0.12, 20, 1.0), (0.58, -0.12, 75, 0.8), (0.42, 0.24, -30, 0.9), (0.68, 0.0, 140, 0.6),
			(0.24, 0.22, 60, 0.5), (0.52, 0.28, 10, 0.55))):
		shard(x, z, a, sc, i)


def shard(x, z, a, sc, i):
	"""A curved-looking bit of urn wall lying flat on the floor."""
	before = meshes()
	slab([(-0.05 * sc, -0.03 * sc), (0.045 * sc, -0.04 * sc), (0.06 * sc, 0.0), (0.03 * sc, 0.035 * sc), (-0.04 * sc, 0.03 * sc)],
		0.0, 0.009, 0.013, CLAY("abc"[i % 3]), k=0.3)
	turn(meshes() - before, a, (0.0, 0.0, 0.0), off=(x, 0.0, z))


def smashed_urn(cx, cz, seed, size=1.0, tall=1.0, low=0.07, high=0.2, teeth=0.4, band=True, wide=1.0):
	"""What is left of a smashed urn: its bottom, broken off at a different height all round (low..high), a clay
	wall 1.3 cm thick with its inner floor. size scales it, tall stretches it up, wide makes it squat and fat."""
	rr = random.Random(seed)
	n = 20
	belly = 0.152 * size * wide
	foot = 0.07 * size * wide
	outer = lambda y: foot + (belly - foot) * min(1.0, y / (0.12 * size * tall)) ** 0.6
	tops = [rr.uniform(low, high) * size * tall for _ in range(n)]
	for k in range(n):   # broken in a few big teeth
		if rr.random() < teeth:
			tops[(k + 1) % n] = tops[k] * rr.uniform(0.9, 1.05)
	verts, faces = [], []
	R_ = 5
	for j in range(R_ + 1):   # the outside, up to each column's broken top
		for k in range(n):
			a = 2 * math.pi * k / n
			y = tops[k] * j / R_
			r = outer(y) * rr.uniform(0.98, 1.02)
			verts.append((cx + math.cos(a) * r, y, cz + math.sin(a) * r))
	for j in range(R_ + 1):   # the inside, 1.3 cm in, back down to the inner floor
		for k in range(n):
			a = 2 * math.pi * k / n
			y = max(0.018, tops[k] * (R_ - j) / R_)
			r = max(0.035, outer(y) - 0.013)
			verts.append((cx + math.cos(a) * r, y, cz + math.sin(a) * r))
	rows = 2 * (R_ + 1)
	for j in range(rows - 1):
		for k in range(n):
			k2 = (k + 1) % n
			faces.append((j * n + k, j * n + k2, (j + 1) * n + k2, (j + 1) * n + k))
	faces.append(tuple(range(n - 1, -1, -1)))                      # the outside bottom
	faces.append(tuple((rows - 1) * n + k for k in range(n)))      # the inner floor
	K.mesh(verts, faces, CLAY("a"))
	yb = 0.15 * size * tall
	if band:
		for k in range(0, n, 2):   # part of the carved band still on it (only where the wall still stands that high)
			a = 2 * math.pi * k / n
			if min(tops[k], tops[(k + 1) % n], tops[k - 1]) > yb + 0.03 * size:
				r = outer(yb)
				K.blk((cx + math.cos(a) * r, yb, cz + math.sin(a) * r), (0.034 * size, 0.034 * size, 0.012), CLAY("c"),
					bevel=0.003, ry=-math.degrees(a) + 90, rz=45)


def lid_on_floor(x, z, seed, size=1.0):
	"""An urn's lid knocked off, lying right way up on the floor, its knob on top."""
	prof = [(0.104 * size, 0.0), (0.106 * size, 0.018 * size), (0.088 * size, 0.034 * size), (0.05 * size, 0.046 * size),
		(0.03 * size, 0.048 * size)]
	lathe(prof, (x, z), CLAY("b"), seed)
	lump((x, 0.066 * size, z), (0.032 * size, 0.026 * size, 0.032 * size), CLAY("b"), seed + 1, seg=8, ring=5, jit=0.06)


def urn_broken(v):
	"""Five more smashed urns (owner, Nov 20), each broken its own way, its shards lying about it."""
	rr = random.Random(700 + v * 31)
	if v == 0:     # a low stump, shards spread wide all round
		smashed_urn(0.0, 0.0, 731, low=0.04, high=0.1, band=False)
		spots = [(rr.uniform(0.2, 0.42), a) for a in range(0, 360, 45)]
	elif v == 1:   # one tall tooth left standing, the rest low
		smashed_urn(0.0, 0.0, 762, size=1.08, low=0.06, high=0.27, teeth=0.75)
		spots = [(rr.uniform(0.2, 0.32), a) for a in (-40, 10, 60, 200)]
	elif v == 2:   # knocked over: lying on its side, its broken mouth to the right, shards spilled out of it
		before = meshes()
		smashed_urn(0.0, 0.0, 793, low=0.17, high=0.26, teeth=0.5)
		parts = meshes() - before
		spin(parts, "z", -84, (0.0, 0.0, 0.0))
		drop(parts, 0.01)
		spots = [(rr.uniform(0.3, 0.45), a) for a in (-25, 0, 20, 45)] + [(0.22, 160)]
	elif v == 3:   # a small urn smashed low, its lid knocked off beside it
		smashed_urn(0.0, 0.0, 824, size=0.75, low=0.05, high=0.14)
		lid_on_floor(-0.24, 0.12, 825, size=0.75)
		spots = [(rr.uniform(0.16, 0.26), a) for a in (-60, 20, 80)]
	else:          # a wide squat urn split down the middle: one half stands, the other half lies on its back beside it
		smashed_urn(0.0, 0.0, 855, wide=1.25, tall=0.8, low=0.05, high=0.22, teeth=0.85)
		rh = random.Random(856)
		ends = [rh.uniform(0.1, 0.17) for _ in range(9)]
		def half(si, t):   # the other half lying on its back: a curved clay trough, broken ends ragged
			ang = math.pi * si
			rad = 0.185 - 0.03 * t
			ln = ends[min(8, int(si * 8.999))]
			return (0.4 + math.cos(ang) * rad, rad * (1.0 - math.sin(ang)) + 0.006, 0.05 - ln + 2 * ln * t)
		sheet(half, 16, 6, CLAY("b"), 0.013)
		spots = [(rr.uniform(0.28, 0.36), a) for a in (-70, 120, 200)]
	for i, (r, a) in enumerate(spots):
		a2 = math.radians(a + rr.uniform(-12, 12))
		shard(math.cos(a2) * r, math.sin(a2) * r, rr.uniform(0, 360), rr.uniform(0.45, 1.0), i + v)


# ---------------------------------------------------------------- junk_statue_head
def plait(top, bottom, r, m, seed, n=6):
	"""A thick stone braid: long knots leaning left, right, left (a plait), a band and a tuft at the end."""
	a, b = Vector(top), Vector(bottom)
	d = (b - a).normalized()
	for i in range(n):
		t = i / (n - 1)
		p = a + (b - a) * t
		rk = r * (1.0 - 0.25 * t)
		lump((p.x, p.y, p.z), (rk * 1.0, rk * 1.55, rk * 0.85), m, seed + i, seg=8, ring=6, jit=0.04, roll=(28 if i % 2 else -28))
	rk = r * 0.75
	lump(tuple(b + d * 0.02), (rk * 1.2, 0.014, rk * 1.05), m, seed + 20, seg=9, ring=4, jit=0.03)   # the band
	lump(tuple(b + d * 0.045), (rk * 0.75, 0.03, rk * 0.7), m, seed + 21, seg=7, ring=5, jit=0.1)    # the tuft


def junk_statue_head():
	"""A dwarf's head broken off a big stone statue, lying on its side, face to the front (owner: show the face, not
	only the beard): a stone helm with a rim, a heavy brow over the eyes, a big nose, a drooping moustache, a beard
	of three thick plaits. Round 2: one size of lump everywhere read as a heap of rocks, so the parts are bolder."""
	st = lambda v=None: T("greystone", v)
	before = meshes()
	lump((0.0, 0.3, -0.04), (0.155, 0.165, 0.155), st("a"), 431, seg=11, ring=8, jit=0.04)        # the head
	lump((0.0, 0.37, -0.03), (0.172, 0.12, 0.172), st("b"), 432, seg=12, ring=7, jit=0.03)        # the helm
	arc_band(0.168, 0.196, 0.325, 0.355, 0, 360, st("c"), n=20, seed=433)                         # its rim
	lump((0.0, 0.302, 0.105), (0.13, 0.034, 0.055), st("b"), 434, seg=9, ring=6, jit=0.05)        # the heavy brow
	for sx in (-1, 1):
		lump((sx * 0.05, 0.272, 0.112), (0.028, 0.02, 0.02), st("c"), 435 + sx, seg=8, ring=5, jit=0.03)          # eyes
		lump((sx * 0.088, 0.228, 0.088), (0.055, 0.045, 0.045), st("a"), 437 + sx, seg=8, ring=5, jit=0.05)       # cheeks
		lump((sx * 0.15, 0.27, -0.02), (0.03, 0.055, 0.04), st("b"), 439 + sx, seg=7, ring=5, jit=0.05)           # ears
		lump((sx * 0.068, 0.188, 0.148), (0.078, 0.022, 0.03), st("c"), 441 + sx, seg=8, ring=5, jit=0.04, yaw=-sx * 15,
			roll=sx * 18)                                                                                         # moustache
	lump((0.0, 0.235, 0.148), (0.04, 0.058, 0.05), st("c"), 443, seg=8, ring=6, jit=0.04)         # the nose
	lump((0.0, 0.205, 0.168), (0.036, 0.03, 0.034), st("c"), 444, seg=8, ring=5, jit=0.04)        # its bulb
	lump((0.0, 0.11, 0.07), (0.15, 0.11, 0.09), st("b"), 445, seg=10, ring=6, jit=0.05)           # the beard's mass
	for i, x in enumerate((-0.075, 0.0, 0.075)):
		plait((x, 0.15, 0.135 - abs(x) * 0.2), (x * 1.2, -0.07, 0.14 - abs(x) * 0.3), 0.042, st("abc"[i]), 450 + i * 30)
	lump((0.0, 0.01, -0.03), (0.12, 0.05, 0.1), st("a"), 446, seg=9, ring=5, jit=0.12)            # the broken neck stump
	head = meshes() - before
	spin(head, "z", 78, (0.0, 0.17, 0.0))   # lying on its side: the top of the head to the left, the face to the front
	spin(head, "x", -14, (0.0, 0.17, 0.0))  # a little tipped back, face up to the light
	drop(head, 0.012)   # (sunk a little so it rests on the floor, not on one point)
	for i, (x, z, s) in enumerate(((0.36, 0.18, 1.0), (0.32, -0.2, 0.7), (-0.4, 0.22, 0.8), (0.44, -0.02, 0.6))):
		lump((x, 0.02 * s, z), (0.04 * s, 0.028 * s, 0.034 * s), st("abc"[i % 3]), 470 + i, seg=6, ring=4, jit=0.2)   # stone chips


# ---------------------------------------------------------------- junk_armour_pile
def sheet(fn, NA, NB, m, thick, wrap=False, cap=False):
	"""A thin bent sheet of metal (or leather or clay): fn(s, t) -> a game point, s and t from 0 to 1. wrap: s goes
	all the way round (a closed ring); cap: close the t = 1 end with a flat face. Solidified to thick (both ways)."""
	cols = NA if wrap else NA + 1
	verts, faces = [], []
	for i in range(NB + 1):
		for k in range(cols):
			verts.append(fn(k / NA, i / NB))
	for i in range(NB):
		for k in range(NA):
			k2 = (k + 1) % cols if wrap else k + 1
			faces.append((i * cols + k, i * cols + k2, (i + 1) * cols + k2, (i + 1) * cols + k))
	if cap:
		faces.append(tuple(NB * cols + k for k in range(cols)))
	o = K.mesh(verts, faces, m)
	sol = o.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = thick
	sol.offset = 0.0
	return o


def tube(pts, r, m, sides=6):
	"""A round rod bent along a line of points (a rolled metal edge, a wire)."""
	verts, faces = [], []
	P = [Vector(p) for p in pts]
	for i, p in enumerate(P):
		d = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
		up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
		u = d.cross(up).normalized()
		v = d.cross(u)
		for k in range(sides):
			a = 2 * math.pi * k / sides
			verts.append(tuple(p + (u * math.cos(a) + v * math.sin(a)) * r))
	for i in range(len(P) - 1):
		for k in range(sides):
			k2 = (k + 1) % sides
			faces.append((i * sides + k, i * sides + k2, (i + 1) * sides + k2, (i + 1) * sides + k))
	faces.append(tuple(range(sides - 1, -1, -1)))
	faces.append(tuple((len(P) - 1) * sides + k for k in range(sides)))
	return K.mesh(verts, faces, m)


def ring(rx, rz, dr, y0, y1, m, n=24, seed=1):
	"""A band all the way round an oval (rx, rz): dr thick outward, from height y0 to y1."""
	rr = random.Random(seed)
	verts, faces = [], []
	for k in range(n):
		a = 2 * math.pi * k / n
		w = rr.uniform(-0.0015, 0.0015)
		for sc in (1.0, 1.0 + dr):
			for y in (y0, y1):
				verts.append((math.cos(a) * (rx * sc + w), y, math.sin(a) * (rz * sc + w)))
	for k in range(n):
		b, c = 4 * k, 4 * ((k + 1) % n)
		faces += [(b, b + 1, c + 1, c), (b + 2, c + 2, c + 3, b + 3), (b, c, c + 2, b + 2), (b + 1, b + 3, c + 3, c + 1)]
	return K.mesh(verts, faces, m)


def old_helm(c, seed, upside_down=False, tilt=0.0, yaw=0.0, dent=None):
	"""A rusty dwarf helm, hollow (owner, Nov 20: a helm must be open underneath): a thin dome, a riveted brow band
	round its rim, two crossed bands over the top, a knob, a nose guard. upside_down: lying on its dome, the open
	inside up. dent = (angle, height 0..1): one knock pushed into the dome."""
	m, band = dull(RUST("b")), dull(RUST("a"))
	RX, RY, RZ = 0.105, 0.11, 0.115
	rr = random.Random(seed)
	wob = [rr.uniform(0.99, 1.01) for _ in range(20)]
	before = meshes()

	def dome(s, t):
		a = 2 * math.pi * s
		el = -0.04 + 1.4 * t
		k = wob[int(s * 20) % 20] * (1.0 - 0.6 * t) + 1.0 * 0.6 * t
		if dent:
			da = math.atan2(math.sin(a - dent[0]), math.cos(a - dent[0]))
			k -= 0.09 * math.exp(-(da * da) / 0.12 - ((t - dent[1]) ** 2) / 0.02)
		return (RX * math.cos(el) * math.cos(a) * k, RY * math.sin(el) * k, RZ * math.cos(el) * math.sin(a) * k)
	sheet(dome, 20, 8, m, 0.008, wrap=True, cap=True)
	lump((0.0, RY * 1.02, 0.0), (0.024, 0.022, 0.024), band, seed + 9, seg=8, ring=5, jit=0.05)        # the knob on top
	ring(RX * 1.03, RZ * 1.03, 0.065, 0.006, 0.03, band, n=24, seed=seed)   # the brow band (inner side inside the wall: no shimmer)
	for k in range(8):   # its rivets
		a = 2 * math.pi * (k + 0.5) / 8
		lump((math.cos(a) * RX * 1.095, 0.011, math.sin(a) * RZ * 1.095), (0.007, 0.007, 0.007), T("iron", "b"), seed + k,
			seg=6, ring=4)
	for pa in (0.0, 90.0):   # the two crossed bands, hugging the dome from brow band to brow band
		ux, uz = math.cos(math.radians(pa)), math.sin(math.radians(pa))
		wx, wz = -uz, ux
		verts, faces = [], []
		N = 14
		for i in range(N + 1):
			ph = math.radians(12 + 156 * i / N)
			for sc in (1.03, 1.1):
				for sw in (-0.013, 0.013):
					px = ux * math.cos(ph) * RX * sc + wx * sw
					py = math.sin(ph) * RY * sc
					pz = uz * math.cos(ph) * RZ * sc + wz * sw
					verts.append((px, py, pz))
		for i in range(N):
			b0, b1 = 4 * i, 4 * (i + 1)
			faces += [(b0, b0 + 1, b1 + 1, b1), (b0 + 2, b1 + 2, b1 + 3, b0 + 3), (b0, b1, b1 + 2, b0 + 2), (b0 + 1, b0 + 3, b1 + 3, b1 + 1)]
		faces += [(0, 2, 3, 1), (4 * N, 4 * N + 1, 4 * N + 3, 4 * N + 2)]
		K.mesh(verts, faces, band)
	K.blk((0.0, -0.02, RZ * 1.1 + 0.01), (0.03, 0.09, 0.012), band, bevel=0.004)   # the nose guard, hanging off the band
	lump((0.0, 0.011, RZ * 1.1 + 0.017), (0.008, 0.008, 0.006), T("iron", "b"), seed + 20, seg=6, ring=4)
	parts = meshes() - before
	if upside_down:
		spin(parts, "x", 180.0)
	spin(parts, "x", tilt)
	turn(parts, yaw, (0.0, 0.0, 0.0), off=(c[0], 0.0, c[2]))
	drop(parts, 0.006)


def plate_w(t):
	"""Half the breastplate's width t of the way down it: narrow at the shoulders, scooped armholes, a waist."""
	u = min(1.0, t / 0.38)
	return 0.15 + 0.055 * (3 * u * u - 2 * u ** 3) - 0.012 * max(0.0, t - 0.6) / 0.4


def plate_pt(sx, t, lift=0.0):
	"""A point on the breastplate lying on its back (sx -1..1 across, t 0..1 neck to waist), lift above its middle."""
	ztop = -0.2 + 0.065 * max(0.0, 1 - (sx / 0.5) ** 2)   # the neck scoop
	z = ztop + (0.21 - ztop) * t
	x = sx * plate_w(t)
	y = 0.11 * math.sqrt(max(0.0, 1 - sx * sx)) * (1 - 0.22 * (2 * t - 1) ** 2)
	y += 0.014 * max(0.0, 1 - abs(sx) / 0.12)            # the ridge down the middle
	y -= 0.013 * math.exp(-((x - 0.08) ** 2 + (z + 0.04) ** 2) / 0.0025)   # a dent (a hammer blow)
	y -= 0.009 * math.exp(-((x + 0.11) ** 2 + (z - 0.12) ** 2) / 0.0015)   # a smaller one
	return (x, y + 0.012 + lift, z)


def chest_plate(c, seed, yaw=0.0):
	"""A rusty breastplate lying on its back (owner round 2: much more detail): a curved shell with a ridge down
	the middle, a scooped neck and armholes, rolled edges, a riveted waist band, two skirt plates below it and two
	torn leather shoulder straps with brass buckles, lying off onto the floor."""
	m, edge, band = dull(RUST("a")), dull(RUST("b")), dull(RUST("c"))
	riv = T("iron", "b")
	before = meshes()
	sheet(lambda s, t: plate_pt(-1 + 2 * s, t), 18, 12, m, 0.01)
	# the rolled edges: round the neck and armholes (top), and along the waist
	top = [plate_pt(-0.98 + 1.96 * k / 16, 0.0, 0.004) for k in range(17)]
	tube(top, 0.008, edge, sides=6)
	for sg in (-1, 1):   # down each armhole
		tube([plate_pt(sg * 0.985, 0.4 * k / 6, 0.002) for k in range(7)], 0.007, edge, sides=6)
	tube([plate_pt(-0.97 + 1.94 * k / 16, 1.0, 0.004) for k in range(17)], 0.007, edge, sides=6)
	# the waist band, sunk a little into the shell so it is joined to it, with rivets
	sheet(lambda s, t: plate_pt(-0.98 + 1.96 * s, 0.74 + 0.07 * t, 0.006), 18, 2, band, 0.008)
	for k in range(9):
		sx = -0.88 + 1.76 * k / 8
		p = plate_pt(sx, 0.775, 0.012)
		lump(p, (0.007, 0.006, 0.007), riv, seed + k, seg=6, ring=4)
	# two skirt plates (lames) below the waist, each overlapping the one above
	for j in range(2):
		z0 = 0.2 + 0.05 * j
		wj = 0.19 - 0.012 * j
		def lame(s, t, j=j, z0=z0, wj=wj):
			sx = -1 + 2 * s
			# (the same curve for both: each lies 4 mm clear above the one before it, no shimmer)
			y = 0.11 * 0.72 * math.sqrt(max(0.0, 1 - sx * sx)) + 0.012 + 0.016 * (1 - t) + 0.004
			return (sx * wj, y, z0 + 0.065 * t)
		sheet(lame, 16, 3, edge if j else m, 0.008)
		for sx in (-0.82, 0.82):
			x, y, z = lame((sx + 1) / 2, 0.2)
			lump((x, y + 0.006, z), (0.007, 0.006, 0.007), riv, seed + 30 + j, seg=6, ring=4)
	# two leather shoulder straps, torn, lying off the top edge onto the floor, a brass buckle on each
	lea = T("leather", "a")
	for sg, ln in ((-1, 0.15), (1, 0.11)):
		x0, y0, z0 = plate_pt(sg * 0.72, 0.0, 0.0)
		def strap(s, t, x0=x0, y0=y0, z0=z0, ln=ln, sg=sg):
			return (x0 + (s - 0.5) * 0.036 + sg * 0.03 * t, max(0.004, y0 * (1 - t) ** 2.2 + 0.004), z0 + 0.012 - ln * t)
		sheet(strap, 2, 6, lea, 0.006)
		bx, by, bz = strap(0.5, 0.62)
		for dz in (-0.012, 0.012):   # the buckle: a small brass frame, two bars and two sides
			K.blk((bx, by + 0.005, bz + dz), (0.048, 0.008, 0.007), BRASS(), bevel=0.002)
		for dx in (-0.021, 0.021):
			K.blk((bx + dx, by + 0.005, bz), (0.007, 0.008, 0.03), BRASS(), bevel=0.002)
		lump((x0, y0 + 0.006, z0 + 0.012), (0.008, 0.007, 0.008), riv, seed + 40 + sg, seg=6, ring=4)   # its rivet
	turn(meshes() - before, yaw, (0.0, 0.0, 0.0), off=c)


def pauldron(c, seed, yaw=0.0):
	"""A loose shoulder plate: three curved plates riveted together, lying curved side up."""
	before = meshes()
	riv = T("iron", "b")
	for j in range(3):
		def plate(s, t, j=j):
			sx = -1 + 2 * s
			w = 0.1 - 0.012 * j
			y = 0.065 * (1 - 0.14 * j) * math.sqrt(max(0.0, 1 - sx * sx)) * (1 - 0.3 * t * t) + 0.004 + 0.012 * (1 - t)
			return (sx * w, y, -0.06 + 0.05 * j + 0.07 * t)
		sheet(plate, 12, 3, dull(RUST("abc"[j])), 0.008)
		for sx in (-0.8, 0.8):
			x, y, z = plate((sx + 1) / 2, 0.15)
			lump((x, y + 0.006, z), (0.007, 0.006, 0.007), riv, seed + j * 2 + (sx > 0), seg=6, ring=4)
	tube([(x, 0.006, 0.105 + 0.03 * math.sin(x * 20)) for x in (-0.05, -0.02, 0.01, 0.04)], 0.006, T("leather", "a"), sides=5)
	turn(meshes() - before, yaw, (0.0, 0.0, 0.0), off=c)


def vambrace(c, seed, yaw=0.0):
	"""An arm guard: a half tube of iron lying curved side up, wider at the elbow, a rolled edge and two leather
	straps across it."""
	before = meshes()
	L = 0.22
	r = lambda t: 0.05 - 0.014 * t + 0.008 * max(0.0, 0.15 - t) / 0.15
	sheet(lambda s, t: (r(t) * math.cos(math.pi * s), r(t) * math.sin(math.pi * s) + 0.004, -L / 2 + L * t), 10, 6,
		dull(RUST("b")), 0.007)
	tube([(r(0.0) * math.cos(math.pi * k / 10), r(0.0) * math.sin(math.pi * k / 10) + 0.004, -L / 2) for k in range(11)], 0.006,
		dull(RUST("a")), sides=6)
	for tt in (0.3, 0.75):   # the straps hug the curve, sunk a little into it
		sheet(lambda s, t, tt=tt: ((r(tt) + 0.004) * math.cos(math.pi * (-0.06 + 1.12 * s)),
			max(0.003, (r(tt) + 0.004) * math.sin(math.pi * (-0.06 + 1.12 * s)) + 0.004), -L / 2 + L * tt - 0.014 + 0.028 * t),
			8, 1, T("leather", "a"), 0.006)
	turn(meshes() - before, yaw, (0.0, 0.0, 0.0), off=c)


def junk_armour_pile():
	"""Dented rusty armour in a heap (owner round 2): the breastplate on its back, one helm sitting on its rim, one
	upside down on its dome showing it is hollow, a shoulder plate, an arm guard, a few stones."""
	chest_plate((0.08, 0.0, 0.04), 481, yaw=-18)
	old_helm((-0.36, 0.0, -0.12), 491, tilt=0.0, yaw=25, dent=(math.radians(200), 0.45))
	old_helm((-0.3, 0.0, 0.2), 497, upside_down=True, tilt=14.0, yaw=-40)
	pauldron((0.42, 0.0, -0.2), 505, yaw=35)
	vambrace((0.44, 0.0, 0.24), 507, yaw=-70)
	for i, (x, z, s) in enumerate(((-0.12, -0.3, 0.8), (-0.55, 0.06, 0.9), (0.2, 0.34, 0.7), (0.6, 0.02, 0.6))):
		lump((x, 0.028 * s, z), (0.05 * s, 0.035 * s, 0.045 * s), T("greystone", "abc"[i % 3]), 500 + i, seg=7, ring=5, jit=0.18)


# ---------------------------------------------------------------- junk_coffin_lid
def coffin_w(x):
	"""Half the coffin lid's width at x (wider at the shoulders, x = -0.55)."""
	if x < -0.55:
		return 0.21 + (0.3 - 0.21) * (x + 0.92) / 0.37
	return 0.3 - (0.3 - 0.24) * (x + 0.55) / 1.47


def junk_coffin_lid(only=None):
	"""A carved stone coffin lid broken in three flat chunks, pulled a little apart: a raised rim round the edge and
	a raised diamond knot carved on each chunk. only = 0, 1 or 2: just that chunk, as a model of its own."""
	st = lambda v=None: T("greystone", v)
	T_, RIM = 0.1, 0.022
	cuts = [-0.92, -0.3, 0.38, 0.92]
	jags = {1: jag(-0.3, -0.31, 0.31, 7, 0.05, 511), 2: jag(0.38, -0.31, 0.31, 7, 0.05, 512)}
	for ci in range(3):
		if only is not None and ci != only:
			continue
		xa, xb = cuts[ci], cuts[ci + 1]
		before = meshes()
		poly = []
		left = jags.get(ci)       # (the break on this chunk's left, from -z to +z)
		right = jags.get(ci + 1)
		xs = [xa + (xb - xa) * t for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
		if ci == 0:
			xs = [-0.92, -0.75, -0.55, -0.42] + [x for x in xs if x > -0.42]
		lo = [(x, -coffin_w(x)) for x in xs]
		hi = [(x, coffin_w(x)) for x in reversed(xs)]
		if right:
			lo = [p for p in lo if p[0] < min(q[0] for q in right) - 0.005]
			hi = [p for p in hi if p[0] < min(q[0] for q in right) - 0.005]
			mid = [(x, max(-coffin_w(x), min(coffin_w(x), z))) for (x, z) in right]
		else:
			mid = []
		if left:
			lo = [p for p in lo if p[0] > max(q[0] for q in left) + 0.005]
			hi = [p for p in hi if p[0] > max(q[0] for q in left) + 0.005]
			back = [(x, max(-coffin_w(x), min(coffin_w(x), z))) for (x, z) in reversed(left)]
		else:
			back = []
		poly = lo + mid + hi + back
		slab(poly, 0.0, T_ - 0.012, T_, st("abc"[ci]), k=0.04)
		# the raised rim along the long edges (inset 1.5 cm, kept clear of the breaks)
		x0 = (max(q[0] for q in left) + 0.03) if left else xa + 0.085
		x1 = (min(q[0] for q in right) - 0.03) if right else xb - 0.085
		for sgn in (-1, 1):
			rim = []
			xs2 = [x0 + (x1 - x0) * t / 6 for t in range(7)]
			for x in xs2:
				rim.append((x, sgn * (coffin_w(x) - 0.015)))
			for x in reversed(xs2):
				rim.append((x, sgn * (coffin_w(x) - 0.075)))
			slab(rim, T_ - 0.004, RIM - 0.004, RIM + 0.004, st("b"), k=0.15)
		if ci in (0, 2):   # the rim across the end
			xe = xa + 0.06 if ci == 0 else xb - 0.06
			w = coffin_w(xe) - 0.015
			slab([(xe - 0.03, -w), (xe + 0.03, -w), (xe + 0.03, w), (xe - 0.03, w)], T_ - 0.004, RIM - 0.01, RIM - 0.002, st("b"), k=0.15)
		# the diamond knot: two diamond frames, one inside the other, and a small raised centre
		cxm = (x0 + x1) / 2
		for (a, wd) in ((0.17, 0.026), (0.095, 0.022)):
			for (sx, sz) in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
				ln = a * math.sqrt(2)
				K.blk((cxm + sx * a / 2, T_ + 0.007, sz * a / 2), (ln + wd * 0.4, 0.016, wd), st("c"), bevel=0.004,
					ry=45 * sx * sz)
		K.blk((cxm, T_ + 0.008, 0.0), (0.04, 0.018, 0.04), st("c"), bevel=0.005, ry=45)
		parts = meshes() - before
		turn(parts, (-3.0, 2.5, -2.0)[ci], ((xa + xb) / 2, 0.0, 0.0), off=((-0.05, 0.0, 0.05)[ci], 0.0, (0.02, -0.01, 0.03)[ci]))

def settle():
	"""Set the finished pile down: its lowest point on the floor (y = 0), its middle at the origin (x, z)."""
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)
	vs = [v.co for o in objs for v in o.data.vertices]
	lo = Vector([min(v[k] for v in vs) for k in range(3)])
	hi = Vector([max(v[k] for v in vs) for k in range(3)])
	d = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))  # (Blender axes: z is up)
	for o in objs:
		for v in o.data.vertices:
			v.co -= d


BUILDS = {"junk_bones": junk_bones, "junk_sword_snapped": junk_sword_snapped, "junk_axe_head": junk_axe_head,
	"junk_spear_broken": junk_spear_broken,
	"junk_rags": junk_rags, "junk_shield_wood": junk_shield_wood, "junk_shield_iron": junk_shield_iron,
	"junk_rubble_wood": junk_rubble_wood,
	"junk_pickaxe_broken": junk_pickaxe_broken, "junk_shovel_bent": junk_shovel_bent, "junk_beam_snapped": junk_beam_snapped,
	"junk_helmet": junk_helmet, "junk_lantern": junk_lantern,
	"junk_urns": junk_urns, "junk_statue_head": junk_statue_head, "junk_armour_pile": junk_armour_pile,
	"junk_coffin_lid": junk_coffin_lid}
# five more rag piles, two rags each, all different (names written out: the model checker looks for them)
for _i, _name in enumerate(("junk_rags_b", "junk_rags_c", "junk_rags_d", "junk_rags_e", "junk_rags_f")):
	BUILDS[_name] = (lambda sd: (lambda: rags_pair(sd)))(200 + 37 * _i)
# five more smashed urns and the coffin lid's three chunks on their own (owner, Nov 20)
for _i, _name in enumerate(("junk_urn_broken_a", "junk_urn_broken_b", "junk_urn_broken_c", "junk_urn_broken_d",
		"junk_urn_broken_e")):
	BUILDS[_name] = (lambda v: (lambda: urn_broken(v)))(_i)
for _i, _name in enumerate(("junk_coffin_piece_a", "junk_coffin_piece_b", "junk_coffin_piece_c")):
	BUILDS[_name] = (lambda v: (lambda: junk_coffin_lid(v)))(_i)
# five more plank piles, each spread and stacked its own way (owner, Nov 20)
for _i, _name in enumerate(("junk_rubble_wood_b", "junk_rubble_wood_c", "junk_rubble_wood_d", "junk_rubble_wood_e",
		"junk_rubble_wood_f")):
	BUILDS[_name] = (lambda sd: (lambda: rubble_pile(sd)))(500 + 53 * _i)

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if R.ONLY and name not in R.ONLY:
			continue
		K.rng.seed(sum(map(ord, name)))
		kit.reset()
		fn()
		settle()
		if R.GREY:
			S.make_grey()
		else:
			S.paint3()       # wood gets the Shack's plank paintings
			R.age_paint(0.35)  # old junk: everything a little greyer and darker
		parts = R.save_parts(name)
		R.pictures(name, parts)
