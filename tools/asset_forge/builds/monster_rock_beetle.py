# Rock Beetle, hand-built to match the owner's approved pictures (Claude 3; MODEL-RULES Rule 1: hand-built only).
#
#   blender --background --factory-startup --python builds/monster_rock_beetle.py -- <out.glb> [preview.png] [look=mossy]
#
# Reference: assets/concepts/creatures/rock_beetle.png (the approved picture) and rock_beetle_turnaround.png (the same
# beetle from the front, side, back and top, made for this). Sizes below are read off the turnaround at 400 px = 1 m
# (tools/asset_forge/creature_fit.py measures how well the outline matches, per view).
#
# What the pictures show:
# - An egg-shaped dome shell, ~1.2 m long, ~0.9 m wide, top at ~1.03 m; its lower edge at ~0.42 m, right over the eyes.
#   ~20 big, puffy, faceted stone plates fitted edge to edge, moss in the cracks.
# - A smooth glowing amber dome: a window in the upper back, framed by plates all round.
# - One thick flat-sided stone horn on the front plate, leaning forward, tip at ~1 m.
# - A big red-brown face under the front edge: two big round eyes (cream, brown iris, black pupil, white shine), heavy
#   stone brows, two pale hooked jaws like tusks, short segmented feelers with a club tip.
# - A dark red-brown segmented belly; six fat legs of stacked faceted barrels (~14 cm thick) standing well clear of the
#   body, each ending in one big pale curved claw.
#
# Moving parts (docs/design/creature-craft.md): leg_l0..2 / leg_r0..2 turn at the hip. Materials: "eye" flashes before an
# attack; "glow*" (the amber back) blazes when it charges.
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402
import kit  # noqa: E402

out, preview = kit.args()
ARGS = sys.argv[sys.argv.index("--") + 1:]
LOOK = next((a[5:] for a in ARGS if a.startswith("look=")), "mossy")
ck.reset()
rnd = random.Random(17)

# ---------------------------------------------------------------- materials (plain colours for the shape stage)
stone = ck.color("stone_plate", (0.5, 0.46, 0.42), rough=0.85)
crack = ck.color("crack", (0.05, 0.05, 0.03), rough=1.0)
crack.node_tree.nodes["Principled BSDF"].inputs["Specular IOR Level"].default_value = 0.0
chitin = ck.color("chitin", (0.36, 0.17, 0.09), rough=0.55)
chitin_dark = ck.color("chitin_dark", (0.22, 0.1, 0.05), rough=0.6)
claw = ck.color("claw", (0.8, 0.64, 0.42), rough=0.5)
amber = ck.color("glow_back", (1.0, 0.55, 0.08), rough=0.2)
amber.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1.0, 0.55, 0.1, 1)
amber.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.5
eye = ck.eye_mat((0.95, 0.9, 0.8))
iris = ck.color("iris", (0.35, 0.2, 0.09), rough=0.3)
pupil = ck.color("pupil", (0.03, 0.02, 0.02), rough=0.2)
shine = ck.color("shine", (1, 1, 1), rough=0.1, glow=0.6)

# ---------------------------------------------------------------- the shell: the top of an ellipsoid
C = Vector((0.0, 0.03, 0.52))       # centre
A, B, CZ = 0.39, 0.53, 0.42          # half-width, half-length, half-height of the dome UNDER the plates (plates add ~0.1)
RIM_Z = 0.42                         # the shell's lower edge


FULL = 0.74    # < 1: a fuller, boxier dome than an ellipsoid (the drawing's shell is full at the front top)
TAPER = 0.14   # egg shape seen from above: narrower at the head, wider at the back


def _sp(c):
	return math.copysign(abs(c) ** FULL, c)


def surf(d):
	"""Point on the shell for a direction d (unit sphere) and its outward normal (close enough for placing plates)."""
	q = Vector((_sp(d.x), _sp(d.y), _sp(d.z)))
	front = max(0.0, -q.y)  # the shell slopes down toward the head (the drawing's side view)
	p = Vector((q.x * A * (1 + TAPER * q.y), q.y * B, q.z * CZ * (1 - 0.22 * front * max(0.0, q.z)))) + C
	n = Vector((d.x / A, d.y / B, d.z / CZ)).normalized()
	return p, n


def dir_of(p):
	return Vector(((p.x - C.x) / A, (p.y - C.y) / B, (p.z - C.z) / CZ)).normalized()


def dir_xy(x, y):
	"""Direction of the shell point seen from above at (x, y)."""
	u, v = x / A, (y - C.y) / B
	w = math.sqrt(max(0.0, 1 - u * u - v * v))
	return Vector((u, v, w)).normalized()


def dir_back(x, z):
	"""Direction of the shell point seen from the back at (x, z)."""
	u, w = x / A, (z - C.z) / CZ
	v = math.sqrt(max(0.0, 1 - u * u - w * w))
	return Vector((u, v, w)).normalized()


def dir_side(y, z, s):
	"""Direction of the shell point seen from the side at (y, z) on side s (+1 = +X)."""
	v, w = (y - C.y) / B, (z - C.z) / CZ
	u = math.sqrt(max(0.0, 1 - v * v - w * w))
	return Vector((s * u, v, w)).normalized()


# The glowing window in the upper back: an oval, measured on the drawings (back view: from just above the shell's
# widest point up to near the top; top view: reaching forward to the middle of the back).
AMB_EL, AMB_ELH, AMB_AZW = math.radians(47), math.radians(29), math.radians(50)


def amber_at(d, grow=0.0):
	"""How far inside the glowing window direction d is: > 0 inside (1 = its middle), < 0 outside."""
	if d.y <= 0:
		return -1.0
	el = math.asin(max(-1.0, min(1.0, d.z)))
	az = math.atan2(d.x, d.y)
	return 1 - (az / (AMB_AZW + grow)) ** 2 - ((el - AMB_EL) / (AMB_ELH + grow)) ** 2
FACE_DIR = Vector((0, -1, -0.12)).normalized()

# Plate seeds, read off the top view (x, y) and the side view (y, z), mirrored left/right.
SEEDS = [dir_xy(0, -0.38), dir_xy(0, -0.15)]
for s in (-1, 1):
	for x, y in ((0.21, -0.3), (0.32, -0.08), (0.13, -0.02), (0.33, 0.17), (0.1, 0.16), (0.3, 0.42), (0.13, 0.6)):
		SEEDS.append(dir_xy(s * x, y))            # top, read off the top view
	for y in (-0.4, -0.12, 0.16, 0.42):
		SEEDS.append(dir_side(y, 0.5, s))         # the lower row along each side (the skirt over the legs)
	for y in (-0.25, 0.05):
		SEEDS.append(dir_side(y, 0.73, s))        # the middle row along each side
	SEEDS.append(dir_back(s * 0.24, 0.52))        # under the glowing window, seen from the back
SEEDS.append(dir_back(0, 0.5))
HOLES = [FACE_DIR, (FACE_DIR + Vector((0.25, 0, 0))).normalized(), (FACE_DIR + Vector((-0.25, 0, 0))).normalized()]
jr = random.Random(5)
SEEDS = [(d + Vector((jr.uniform(-1, 1), jr.uniform(-1, 1), jr.uniform(-1, 1))) * 0.035).normalized() for d in SEEDS]  # hand-laid, not in rows
SEEDS = [d for d in SEEDS if amber_at(d, math.radians(5)) < 0 and d.dot(FACE_DIR) < 0.93]


def frame(n, spin=0.0):
	z = n.normalized()
	x = Vector((1, 0, 0)) if abs(z.x) < 0.9 else Vector((0, 1, 0))
	y = z.cross(x).normalized()
	x = y.cross(z).normalized()
	return Matrix((x, y, z)).transposed() @ Matrix.Rotation(spin, 3, "Z")


def hull2d(pts):
	pts = sorted(set(pts))
	if len(pts) < 3:
		return pts

	def cross(o, a, b):
		return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
	lo, hi = [], []
	for p in pts:
		while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
			lo.pop()
		lo.append(p)
	for p in reversed(pts):
		while len(hi) >= 2 and cross(hi[-2], hi[-1], p) <= 0:
			hi.pop()
		hi.append(p)
	return lo[:-1] + hi[:-1]


def simplify(poly, n=7):
	"""Keep the n corners that matter most (biggest turn), so plates read as chunky cut stones."""
	poly = list(poly)
	while len(poly) > n:
		best, bi = 9e9, 0
		for i in range(len(poly)):
			a, b, c = Vector((*poly[i - 1], 0)), Vector((*poly[i], 0)), Vector((*poly[(i + 1) % len(poly)], 0))
			area = abs((b - a).cross(c - a).z)
			if area < best:
				best, bi = area, i
		poly.pop(bi)
	return poly


def plate(name, outline, centre, n, thick, material, seed, gap=0.013, sink=0.06, curved=False):
	"""One chunky stone plate fitted to its patch of the shell, rounded chamfer. curved: it bends with the dome
	(each corner sits on the shell and stands out along the shell's normal), like the drawing's armour plates."""
	r = random.Random(seed)
	rot = frame(n)
	pts = [Vector((x, y, 0)) for x, y in outline]
	mid = sum(pts, Vector()) / len(pts)
	bm = bmesh.new()
	rings = []
	tilt = (r.uniform(-0.05, 0.05), r.uniform(-0.05, 0.05))  # each slab's top a little off-level: hand-cut
	for z, shrink in ((-sink, gap + 0.004), (thick * 0.6, gap), (thick, gap + 0.035)):
		ring = []
		for p in pts:
			d = p - mid
			q = mid + d * max(0.05, 1 - shrink / max(d.length, 1e-4))
			h = z + ((tilt[0] * q.x + tilt[1] * q.y) if z > 0 else 0.0)
			if curved:
				sp, sn = surf(dir_of(centre + rot @ Vector((q.x, q.y, 0))))
				ring.append(bm.verts.new(sp + sn * h))
			else:
				ring.append(bm.verts.new(centre + rot @ Vector((q.x, q.y, h))))
		rings.append(ring)
	k = len(pts)
	for a, b in zip(rings, rings[1:]):
		for i in range(k):
			j = (i + 1) % k
			bm.faces.new((a[i], a[j], b[j], b[i]))
	if curved:  # a gently domed top (a fan from the middle), so it follows the shell
		sp, sn = surf(dir_of(centre))
		top = bm.verts.new(sp + sn * thick * 1.03)
		for i in range(k):
			bm.faces.new((rings[-1][i], rings[-1][(i + 1) % k], top))
	else:
		bm.faces.new(rings[-1])
	bm.faces.new(list(reversed(rings[0])))
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(material)
	for p in o.data.polygons:
		p.use_smooth = False
	bv = o.modifiers.new("bevel", "BEVEL")
	bv.width = 0.028
	bv.segments = 2
	bv.limit_method = "ANGLE"
	bv.angle_limit = math.radians(25)
	return o


# The dark layer under the plates (seen in the cracks), only on the shell part.
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1)
under = bpy.context.object
under.name = "shell_under"
bm = bmesh.new()
bm.from_mesh(under.data)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if surf(v.co.normalized())[0].z < RIM_Z - 0.03], context="VERTS")
for v in bm.verts:
	v.co = C + (surf(v.co.normalized())[0] - C) * 0.975
bm.to_mesh(under.data)
bm.free()
under.data.materials.append(crack)
for p in under.data.polygons:
	p.use_smooth = True

# The plates: the shell's own surface cut into patches (each seed gets the part of the shell nearest to it), each
# patch's edge smoothed and pulled in for the crack, then lifted into a cushion (thick in the middle, rounded at the
# edge) with a few flat chisel cuts on top, so it reads as a hand-cut stone that bends with the shell.
GAP = 0.012       # half the crack between two plates (m)
ROUND = 0.04      # how far in from the edge a plate reaches its full thickness (m)


def in_plate_area(d):
	p = surf(d)[0]
	return p.z >= RIM_Z and amber_at(d) <= 0 and not (d.dot(FACE_DIR) > math.cos(math.radians(30)) and p.z < 0.62)


def boundary_loop(bm):
	"""The plate's outer edge as one ordered loop of vertices (the longest loop if there are several)."""
	edges = {e for e in bm.edges if e.is_boundary}
	loops = []
	while edges:
		e = edges.pop()
		loop = [e.verts[0], e.verts[1]]
		while True:
			nxt = [x for x in loop[-1].link_edges if x in edges]
			if not nxt:
				break
			edges.discard(nxt[0])
			v = nxt[0].other_vert(loop[-1])
			if v is loop[0]:
				break
			loop.append(v)
		loops.append(loop)
	return max(loops, key=len)


def cushion_plates(seeds, material, seed=1):
	r = random.Random(seed)
	bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=1)
	probe = bpy.context.object
	base = bmesh.new()
	base.from_mesh(probe.data)
	bpy.data.objects.remove(probe)
	for v in base.verts:
		v.co = v.co.normalized()
	owner = {}
	for f in base.faces:
		c = f.calc_center_median().normalized()
		if not in_plate_area(c):
			continue
		owner[f] = max(range(len(seeds)), key=lambda i: c.dot(seeds[i]))
	made = []
	for i, sd in enumerate(seeds):
		faces = [f for f, o in owner.items() if o == i]
		if len(faces) < 6:
			continue
		bm = bmesh.new()
		vmap = {}
		for f in faces:
			vs = []
			for v in f.verts:
				if v not in vmap:
					vmap[v] = bm.verts.new(v.co.copy())
				vs.append(vmap[v])
			bm.faces.new(vs)
		bm.verts.ensure_lookup_table()
		loop = boundary_loop(bm)
		inner = [v for v in bm.verts if v not in set(loop)]
		cdir = sum((v.co for v in bm.verts), Vector()).normalized()
		# Round off the jagged triangle edge (on the unit sphere) without shrinking the plate, then pull it in for the crack.
		before = [v.co.angle(cdir) for v in loop]
		for _ in range(4):
			new = [((loop[k - 1].co + loop[k].co * 2 + loop[(k + 1) % len(loop)].co) / 4).normalized() for k in range(len(loop))]
			for v, n in zip(loop, new):
				v.co = n
		grow = (sum(before) / len(before)) / max(1e-6, sum(v.co.angle(cdir) for v in loop) / len(loop))
		for v in loop:
			ang = v.co.angle(cdir)
			if ang > 1e-6:
				axis = cdir.cross(v.co).normalized()
				v.co = Matrix.Rotation(ang * grow, 3, axis) @ cdir
		for _ in range(2):  # relax the inside so it follows the new edge
			for v in inner:
				nb = [e.other_vert(v).co for e in v.link_edges]
				v.co = (v.co + sum(nb, Vector()) / len(nb)).normalized()
		R = (surf(cdir)[0] - C).length
		for v in loop:
			ang = v.co.angle(cdir)
			v.co = cdir.slerp(v.co, max(0.0, (ang - GAP / R) / max(ang, 1e-6))) if ang > 1e-6 else v.co
		# Distance from the edge (walking over the plate), for the cushion profile.
		dist = {v: (0.0 if v in set(loop) else 9.0) for v in bm.verts}
		changed = True
		while changed:
			changed = False
			for e in bm.edges:
				a, b = e.verts
				L = (a.co - b.co).length * R
				if dist[a] + L < dist[b] - 1e-9:
					dist[b] = dist[a] + L
					changed = True
				if dist[b] + L < dist[a] - 1e-9:
					dist[a] = dist[b] + L
					changed = True
		thick = r.uniform(0.085, 0.11)
		dirs = {v: v.co.copy() for v in bm.verts}
		top = {}
		for v in bm.verts:
			sp, sn = surf(dirs[v])
			k = min(1.0, dist[v] / ROUND)
			top[v] = sp + sn * thick * (0.42 + 0.58 * k)  # a straight bevel up to a flat-ish top
		# Chisel cuts: 3-4 flat planes slice the top, leaving big flat facets like a hand-cut stone.
		cp, cn = surf(cdir)
		peak = cp + cn * thick
		for _ in range(r.randint(3, 4)):
			pn = (cn + Vector((r.uniform(-1, 1), r.uniform(-1, 1), r.uniform(-1, 1))) * 0.45).normalized()
			off = r.uniform(-0.022, -0.008)
			for v in bm.verts:
				h = (top[v] - peak).dot(pn) - off
				if h > 0:
					top[v] -= pn * h
		for v in bm.verts:
			v.co = top[v]
		# Side wall down into the shell, and a bottom.
		bottoms = []
		for v in loop:
			sp, sn = surf(dirs[v])
			bottoms.append(bm.verts.new(sp - sn * 0.05))
		n = len(loop)
		for k in range(n):
			try:
				bm.faces.new((loop[k], bottoms[k], bottoms[(k + 1) % n], loop[(k + 1) % n]))
			except ValueError:
				pass
		try:
			bm.faces.new(list(reversed(bottoms)))
		except ValueError:
			pass
		bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
		me = bpy.data.meshes.new(f"plate{i}")
		bm.to_mesh(me)
		bm.free()
		o = bpy.data.objects.new(f"plate{i}", me)
		bpy.context.scene.collection.objects.link(o)
		o.data.materials.append(material)
		bpy.context.view_layer.objects.active = o
		o.select_set(True)
		bpy.ops.object.shade_smooth_by_angle(angle=math.radians(32))
		o.select_set(False)
		made.append((cp, cn, thick))
	base.free()
	return made


plates = cushion_plates(SEEDS, stone)

# The glowing amber window: a smooth bulging dome (lit from inside), its edge tucked under the framing plates.
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1)
glow = bpy.context.object
glow.name = "amber"
bm = bmesh.new()
bm.from_mesh(glow.data)
GROW = math.radians(5)  # its edge reaches a little under the framing plates
bmesh.ops.delete(bm, geom=[v for v in bm.verts if amber_at(v.co.normalized(), GROW) < 0], context="VERTS")
for v in bm.verts:
	d = v.co.normalized()
	t = max(0.0, amber_at(d, GROW))
	v.co = C + (surf(d)[0] - C) * (1.0 + 0.1 * math.sqrt(t))
bm.to_mesh(glow.data)
bm.free()
glow.data.materials.append(amber)
for p in glow.data.polygons:
	p.use_smooth = True

# ---------------------------------------------------------------- body underneath: dark segmented belly
BELLY = [(-0.44, 0.16, 0.1), (-0.3, 0.26, 0.15), (0.0, 0.31, 0.16), (0.35, 0.28, 0.14), (0.55, 0.16, 0.09)]
ck.loft("belly", [((0, y, 0.35), w, h * 0.92) for y, w, h in BELLY], chitin_dark, sides=16)
for i, y in enumerate((-0.28, -0.12, 0.04, 0.2, 0.36)):
	j = max(k for k in range(len(BELLY) - 1) if BELLY[k][0] <= y)
	f = (y - BELLY[j][0]) / (BELLY[j + 1][0] - BELLY[j][0])
	w = BELLY[j][1] + (BELLY[j + 1][1] - BELLY[j][1]) * f + 0.014
	h = BELLY[j][2] + (BELLY[j + 1][2] - BELLY[j][2]) * f + 0.014
	ck.loft(f"belly_ring{i}", [((0, y - 0.025, 0.35), w * 0.97, h * 0.89), ((0, y, 0.35), w, h * 0.92), ((0, y + 0.025, 0.35), w * 0.97, h * 0.89)], chitin, sides=16, subsurf=0)

# ---------------------------------------------------------------- the face, under the front edge
ck.loft("head", [((0, -0.36, 0.38), 0.19, 0.15), ((0, -0.47, 0.38), 0.2, 0.15), ((0, -0.55, 0.36), 0.17, 0.13),
	((0, -0.6, 0.33), 0.1, 0.08)], chitin, sides=16)
ck.loft("snout", [((0, -0.56, 0.32), 0.09, 0.06), ((0, -0.62, 0.31), 0.08, 0.05)], chitin, sides=12)
ck.loft("lip", [((0, -0.6, 0.27), 0.06, 0.025), ((0, -0.625, 0.27), 0.055, 0.02)], chitin_dark, sides=12)
for s in (-1, 1):
	c = Vector((s * 0.105, -0.555, 0.465))
	bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, radius=0.076, location=c)
	o = bpy.context.object
	o.data.materials.append(eye)
	for p in o.data.polygons:
		p.use_smooth = True
	look = Vector((s * 0.25, -1, 0.0)).normalized()
	for rad, off, flat, m in ((0.054, 0.062, 0.4, iris), (0.029, 0.074, 0.4, pupil)):
		bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=1)
		q = bpy.context.object
		q.scale = (rad, rad, rad * flat)
		bpy.ops.object.transform_apply(scale=True)
		q.matrix_world = Matrix.Translation(c + look * off) @ frame(look).to_4x4()
		q.data.materials.append(m)
		for p in q.data.polygons:
			p.use_smooth = True
	ck.blob(tuple(c + look * 0.079 + Vector((s * -0.014, 0, 0.02))), (0.012, 0.007, 0.011), shine, seed=3, subsurf=0)
	# A dark eye socket ring, so the eye sits in the face.
	ck.loft(f"socket{s}", [(c - look * 0.02, 0.083, 0.083), (c + look * 0.014, 0.086, 0.086), (c + look * 0.034, 0.079, 0.079)], chitin_dark, sides=20,
		subsurf=0, up=Vector((0, 0, 1)))
	# Jaws: pale hooked tusks curving down and in.
	jaw = ck.bezier((s * 0.08, -0.58, 0.36), (s * 0.14, -0.67, 0.31), (s * 0.05, -0.66, 0.22), n=9)
	ck.loft(f"jaw{s}", [(p, 0.04 * (1 - 0.82 * i / 8), 0.05 * (1 - 0.82 * i / 8)) for i, p in enumerate(jaw)], claw, sides=8, subsurf=0)
	# Feelers: segments ending in a club, from above the eyes.
	path = ck.bezier((s * 0.12, -0.5, 0.55), (s * 0.26, -0.58, 0.66), (s * 0.34, -0.66, 0.58), n=8)
	for i in range(len(path) - 1):
		a, b = path[i], path[i + 1]
		ck.loft(f"feeler{s}{i}", [(a.lerp(b, -0.1), 0.026, 0.026), (a.lerp(b, 0.5), 0.032, 0.032), (b.lerp(a, -0.1), 0.026, 0.026)], chitin, sides=8, subsurf=0)
	ck.loft(f"club{s}", [(path[-1], 0.04, 0.04), (path[-1] + (path[-1] - path[-2]).normalized() * 0.07, 0.044, 0.044)], chitin, sides=10, subsurf=1)
# Heavy brow plates over the eyes (the grumpy look): lower on the inner side.
for s in (-1, 1):
	c = Vector((s * 0.11, -0.55, 0.555))
	n = Vector((s * 0.15, -0.75, 0.65)).normalized()
	pts = [(-0.1, -0.035), (0.1, -0.06), (0.11, 0.04), (-0.08, 0.06)]
	outline = [(x * s, y) for x, y in pts]
	if s < 0:
		outline.reverse()
	plate(f"brow{s}", outline, c, n, 0.07, stone, seed=900 + s, gap=0.0)

# ---------------------------------------------------------------- the horn: thick, flat-sided, leaning forward
hp = ck.bezier((0, -0.4, 0.64), (0, -0.56, 0.86), (0, -0.6, 1.05), n=8)
ck.loft("horn", [(p, 0.1 - 0.045 * i / 7, 0.2 - 0.085 * i / 7) for i, p in enumerate(hp)], stone, sides=6, subsurf=0, smooth=False, up=Vector((0, -1, 0)))
ck.loft("horn_root", [((0, -0.36, 0.62), 0.12, 0.17), ((0, -0.43, 0.72), 0.1, 0.15)], stone, sides=6, subsurf=0, smooth=False, up=Vector((0, -1, 0)))


# ---------------------------------------------------------------- six fat legs, each its own part (turns at the hip)
def barrel(name, a, b, r0, r1, material, sides=8):
	"""One faceted leg barrel from a to b, bulging a little in the middle, chamfered ends."""
	d = b - a
	return ck.loft(name, [(a, r0 * 0.86, r0 * 0.86), (a + d * 0.12, r0, r0), (a + d * 0.55, (r0 + r1) / 2 * 1.06, (r0 + r1) / 2 * 1.06),
		(a + d * 0.88, r1, r1), (b, r1 * 0.86, r1 * 0.86)], material, sides=sides, subsurf=0, smooth=False, seed=len(name))


def leg(s, i, hip, knee, ankle, toe):
	hip, knee, ankle, toe = Vector(hip), Vector(knee), Vector(ankle), Vector(toe)
	with ck.part(f"leg_{'l' if s < 0 else 'r'}{i}", hinge=tuple(hip)):
		barrel("coxa", hip - (knee - hip).normalized() * 0.04, hip.lerp(knee, 0.5), 0.082, 0.086, chitin)
		barrel("femur", hip.lerp(knee, 0.5), knee, 0.086, 0.082, chitin)
		barrel("tibia", knee, knee.lerp(ankle, 0.5), 0.082, 0.076, chitin)
		barrel("tarsus", knee.lerp(ankle, 0.5), ankle, 0.076, 0.068, chitin)
		for k, p in enumerate((hip.lerp(knee, 0.5), knee, knee.lerp(ankle, 0.5))):  # dark joint rings
			d = ((knee - hip) if k == 0 else (ankle - knee)).normalized()
			rr = 0.064 - 0.005 * k  # narrower than the barrels: a groove between segments
			ck.loft(f"joint{k}", [(p - d * 0.012, rr, rr), (p + d * 0.012, rr, rr)], chitin_dark, sides=8, subsurf=0, smooth=False)
		out_dir = Vector((toe.x - ankle.x, toe.y - ankle.y, 0)).normalized()
		start = ankle - (ankle - knee).normalized() * 0.03
		cl = ck.bezier(start, start + out_dir * 0.09 + Vector((0, 0, 0.0)), Vector((toe.x, toe.y, 0.0)), n=9)
		ck.loft("claw", [(p, 0.064 * (1 - 0.9 * (j / 8) ** 1.5), 0.058 * (1 - 0.9 * (j / 8) ** 1.5)) for j, p in enumerate(cl)], claw, sides=8, subsurf=1)


LEGS = [  # hip, knee, ankle, claw tip   (+X side; mirrored)
	((0.2, -0.25, 0.35), (0.36, -0.33, 0.31), (0.42, -0.41, 0.1), (0.45, -0.5, 0.0)),
	((0.25, 0.0, 0.34), (0.48, 0.04, 0.31), (0.58, 0.1, 0.1), (0.63, 0.16, 0.0)),
	((0.23, 0.28, 0.35), (0.44, 0.36, 0.31), (0.53, 0.46, 0.1), (0.57, 0.56, 0.0)),
]
for s in (-1, 1):
	for i, pts in enumerate(LEGS):
		leg(s, i, *[(s * p[0], p[1], p[2]) for p in pts])

ck.save(out, preview)
