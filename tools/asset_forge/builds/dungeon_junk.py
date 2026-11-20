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


def lump(c, r, m, seed, seg=8, ring=5, jit=0.12, yaw=0.0):
	"""A chunky rounded lump (bone knobs, skull, pommel): a low sphere, every corner nudged, flat cut faces.
	c = centre, r = (x, y, z) radii (game axes), yaw = turn round up (degrees)."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=1, location=K.G(c))
	o = bpy.context.object
	rr = random.Random(seed)
	for v in o.data.vertices:
		v.co *= rr.uniform(1 - jit, 1 + jit)
	o.scale = K.GS(r)
	o.rotation_euler = (0, 0, math.radians(yaw))
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
	"junk_rubble_wood": junk_rubble_wood}
# five more rag piles, two rags each, all different (names written out: the model checker looks for them)
for _i, _name in enumerate(("junk_rags_b", "junk_rags_c", "junk_rags_d", "junk_rags_e", "junk_rags_f")):
	BUILDS[_name] = (lambda sd: (lambda: rags_pair(sd)))(200 + 37 * _i)
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
