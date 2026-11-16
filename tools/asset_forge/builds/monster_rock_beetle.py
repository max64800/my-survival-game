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
face_skin = ck.color("face_skin", (0.32, 0.14, 0.08), rough=0.6)  # the face: one melted skin in the sculpt pass
claw = ck.color("claw", (0.8, 0.64, 0.42), rough=0.5)
mandible_mat = ck.color("mandible", (0.6, 0.58, 0.55), rough=0.5)  # grey (owner, round 6)
amber = ck.color("glow_back", (1.0, 0.55, 0.08), rough=0.2)
amber.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1.0, 0.55, 0.1, 1)
amber.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.5
eye = ck.eye_mat((0.95, 0.9, 0.8))
iris = ck.color("iris", (0.35, 0.2, 0.09), rough=0.3)
pupil = ck.color("pupil", (0.03, 0.02, 0.02), rough=0.2)
shine = ck.color("shine", (1, 1, 1), rough=0.1, glow=0.6)

# ---------------------------------------------------------------- the shell: the top of an ellipsoid
C = Vector((0.0, 0.03, 0.52))       # centre
A, B, CZ = 0.47, 0.56, 0.38         # half-width, half-length, half-height of the dome UNDER the plates (plates add ~0.1)
RIM_Z = 0.37                         # the shell's lower edge at the front and back (see rim_z)


def rim_z(y):
	"""The shell's lower edge is a curve, not a flat cut (owner, round 7): it sweeps down over the legs in the middle
	of each side and rises toward the head and the tail, so the dome rounds under like the picture."""
	v = max(-1.0, min(1.0, (y - C.y) / B))
	return 0.29 + (RIM_Z + 0.03 - 0.29) * v * v


FULL = 0.86    # < 1: a little fuller than an ellipsoid, but round from head to tail like the picture
TAPER = 0.14   # egg shape seen from above: narrower at the head, wider at the back


def _sp(c):
	return math.copysign(abs(c) ** FULL, c)


def surf(d):
	"""Point on the shell for a direction d (unit sphere) and its outward normal (close enough for placing plates)."""
	q = Vector((_sp(d.x), _sp(d.y), _sp(d.z)))
	front = max(0.0, -q.y)  # the shell slopes down toward the head (the drawing's side view)
	p = Vector((q.x * A * (1 + TAPER * q.y), q.y * B, q.z * CZ * (1 - 0.12 * front * max(0.0, q.z)))) + C
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
AMB_C, AMB_W, AMB_L, AMB_Z = 0.28, 0.34, 0.26, 0.56   # oval seen from above: centre y, half-width, half-length; lowest z


def amber_at(d, grow=0.0):
	"""How far inside the glowing window direction d is: > 0 inside (1 = its middle), < 0 outside.
	The window is an oval seen from above (the drawings' top and side views); grow (radians, ~0.45 m each) enlarges it."""
	p = surf(d)[0]
	g = grow * 0.45
	if p.z < AMB_Z - g:
		return -1.0
	return 1 - (p.x / (AMB_W + g)) ** 2 - ((p.y - AMB_C) / (AMB_L + g)) ** 2


FACE_DIR = Vector((0, -1, -0.12)).normalized()

# Plate centres read off the turnaround's top view one by one (x, y in metres; y = back), mirrored left/right.
SEEDS = [dir_xy(0, -0.37), dir_xy(0, -0.18), dir_xy(0, 0.0)]
for s in (-1, 1):
	for x, y in ((0.17, -0.3), (0.3, -0.18), (0.14, -0.1), (0.36, 0.0), (0.15, 0.1), (0.37, 0.2), (0.35, 0.4), (0.24, 0.56), (0.09, 0.63)):
		SEEDS.append(dir_xy(s * x, y))
	for y in (-0.4, -0.12, 0.16, 0.42):
		SEEDS.append(dir_side(y, 0.41, s))        # the lower row along each side (the skirt over the legs)
	for y in (-0.25, 0.05):
		SEEDS.append(dir_side(y, 0.73, s))        # the middle row along each side
	SEEDS.append(dir_back(s * 0.24, 0.52))        # under the glowing window, seen from the back
SEEDS.append(dir_back(0, 0.5))
HOLES = [FACE_DIR, (FACE_DIR + Vector((0.25, 0, 0))).normalized(), (FACE_DIR + Vector((-0.25, 0, 0))).normalized()]
jr = random.Random(5)
_jit = {}


def _jitter(d):
	"""Hand-laid, not in rows, but mirror-matched left/right (the drawing is symmetric)."""
	key = (round(abs(d.x), 4), round(d.y, 4), round(d.z, 4))
	if key not in _jit:
		_jit[key] = Vector((jr.uniform(-1, 1), jr.uniform(-1, 1), jr.uniform(-1, 1))) * 0.03
	j = _jit[key]
	return (d + Vector((math.copysign(j.x, d.x) if abs(d.x) > 1e-4 else 0.0, j.y, j.z))).normalized()


SEEDS = [_jitter(d) for d in SEEDS]
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


def plate(name, outline, centre, n, thick, material, seed, gap=0.013, sink=0.06, curved=False, tilt=None):
	"""One chunky stone plate fitted to its patch of the shell, rounded chamfer. curved: it bends with the dome
	(each corner sits on the shell and stands out along the shell's normal), like the drawing's armour plates."""
	r = random.Random(seed)
	rot = frame(n)
	pts = [Vector((x, y, 0)) for x, y in outline]
	mid = sum(pts, Vector()) / len(pts)
	bm = bmesh.new()
	rings = []
	tilt = tilt or (r.uniform(-0.05, 0.05), r.uniform(-0.05, 0.05))  # each slab's top a little off-level: hand-cut
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
bmesh.ops.delete(bm, geom=[v for v in bm.verts if surf(v.co.normalized())[0].z < rim_z(surf(v.co.normalized())[0].y) - 0.06
	or amber_at(v.co.normalized(), math.radians(4)) > 0
	or (v.co.normalized().dot(FACE_DIR) > math.cos(math.radians(30)) and surf(v.co.normalized())[0].z < 0.62)],
	context="VERTS")  # no moss behind the amber or the face: the sculpt grows it up to 7.5 cm, through the lids
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
GAP = -0.014      # < 0: each plate grows past its boundary, so neighbours press together (only a V-canyon between)
ROUND = 0.065     # how far in from the edge a plate reaches its full thickness (m)


def in_plate_area(d):
	p = surf(d)[0]
	return p.z >= rim_z(p.y) and amber_at(d) <= 0 and not (d.dot(FACE_DIR) > math.cos(math.radians(30)) and p.z < 0.62)


def corner_indices(pts, most=7):
	"""Indices of the few points that keep a closed outline's shape (Douglas-Peucker, loosened until <= most)."""
	n = len(pts)
	start = max(range(n), key=lambda i: pts[i].length)
	far = max(range(n), key=lambda i: (pts[i] - pts[start]).length)

	def dp(i, j, eps, keep):
		a, b = pts[i], pts[j]
		best, bi = -1.0, None
		k = (i + 1) % n
		while k != j:
			ab = b - a
			d = abs(ab.cross(pts[k] - a).z) / max(ab.length, 1e-9)
			if d > best:
				best, bi = d, k
			k = (k + 1) % n
		if bi is not None and best > eps:
			keep.add(bi)
			dp(i, bi, eps, keep)
			dp(bi, j, eps, keep)
	eps = 0.006
	while True:
		keep = {start, far}
		dp(start, far, eps, keep)
		dp(far, start, eps, keep)
		if len(keep) <= most:
			return sorted(keep)
		eps *= 1.25


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
		# Straight-sided outline, like a cut stone: find the 5-7 corners that matter (Douglas-Peucker on a flat map of
		# the plate, where straight lines stay straight on the shell), then lay the edge on straight lines between them.
		e1 = (Vector((0, 0, 1)) if abs(cdir.z) < 0.95 else Vector((1, 0, 0))).cross(cdir).normalized()
		e2 = cdir.cross(e1)
		flat2 = [Vector((v.co.dot(e1) / v.co.dot(cdir), v.co.dot(e2) / v.co.dot(cdir), 0)) for v in loop]
		corners = corner_indices(flat2, 7)
		for ci, cj in zip(corners, corners[1:] + corners[:1]):
			idx = [(ci + k) % len(loop) for k in range(((cj - ci) % len(loop)) + 1)]
			lens = [0.0]
			for u, w in zip(idx, idx[1:]):
				lens.append(lens[-1] + (flat2[w] - flat2[u]).length)
			for k, vi in enumerate(idx[1:-1], 1):
				q = flat2[ci].lerp(flat2[cj], lens[k] / max(lens[-1], 1e-9))
				loop[vi].co = (cdir + e1 * q.x + e2 * q.y).normalized()
		# Round the corners a little (river-stone slabs, like the painting), keeping the plate's size.
		before = sum(v.co.angle(cdir) for v in loop)
		for _ in range(3):
			new = [((loop[k - 1].co + loop[k].co * 2 + loop[(k + 1) % len(loop)].co) / 4).normalized() for k in range(len(loop))]
			for v, nv in zip(loop, new):
				v.co = nv
		grow = before / max(1e-6, sum(v.co.angle(cdir) for v in loop))
		for v in loop:
			ang = v.co.angle(cdir)
			if ang > 1e-6:
				v.co = Matrix.Rotation(ang * grow, 3, cdir.cross(v.co).normalized()) @ cdir
		for _ in range(2):  # relax the inside so it follows the new edge
			for v in inner:
				nb = [e.other_vert(v).co for e in v.link_edges]
				v.co = (v.co + sum(nb, Vector()) / len(nb)).normalized()
		R = (surf(cdir)[0] - C).length
		for v in loop:
			ang = v.co.angle(cdir)
			if ang > 1e-6:
				v.co = Matrix.Rotation(max(0.0, ang - GAP / R), 3, cdir.cross(v.co).normalized()) @ cdir
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
		thick = r.uniform(0.1, 0.13)
		dirs = {v: v.co.copy() for v in bm.verts}
		top = {}
		for v in bm.verts:
			sp, sn = surf(dirs[v])
			k = min(1.0, dist[v] / ROUND)
			dome = 0.018 * min(1.0, dist[v] / 0.12)  # a gentle dome over the whole top
			top[v] = sp + sn * (thick * (0.12 + 0.88 * math.sin(k * math.pi / 2) ** 0.75) + dome)  # rounded down into a small canyon
		# Chisel cuts: 3-4 flat planes slice the top, leaving big flat facets like a hand-cut stone.
		cp, cn = surf(cdir)
		peak = cp + cn * thick
		for _ in range(r.randint(2, 3)):  # gentle cuts: the plate still lies along the shell
			pn = (cn + Vector((r.uniform(-1, 1), r.uniform(-1, 1), r.uniform(-1, 1))) * 0.3).normalized()
			off = r.uniform(-0.016, -0.006)
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

# The glowing amber window: a cut gem like the picture's amber. Points are spread over the bulging dome and wrapped
# in the tightest flat-sided shell around them (a convex hull), so every facet is perfectly flat with crisp straight
# edges; the edge points sit a little lower, tucked under the framing plates.
GROW = math.radians(9)  # its edge reaches well under the framing plates


def amber_point(d, sink=0.0):
	t = max(0.0, amber_at(d, GROW))
	return C + (surf(d)[0] - C) * (1.0 + 0.1 * math.sqrt(t) - sink)


bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=1)
probe = bpy.context.object
pb = bmesh.new()
pb.from_mesh(probe.data)
bpy.data.objects.remove(probe)
inside = {v for v in pb.verts if amber_at(v.co.normalized(), GROW) >= 0}
rim = [v.co.normalized() for v in inside if any(e.other_vert(v) not in inside for e in v.link_edges)]
fr = random.Random(23)
inner = []
for v in sorted(inside, key=lambda _: fr.random()):
	d = v.co.normalized()
	if amber_at(d, GROW) > 0.12 and all(d.angle(q) > 0.16 for q in inner):  # big chunky facets
		inner.append(d)
pb.free()
bm = bmesh.new()
for d in rim:
	bm.verts.new(amber_point(d, sink=0.03))
for d in inner:
	bm.verts.new(amber_point(d, sink=fr.uniform(-0.004, 0.012)))  # each facet point a little in or out: hand-cut
hull = bmesh.ops.convex_hull(bm, input=bm.verts[:])
bm.faces.ensure_lookup_table()
bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.normal.dot((f.calc_center_median() - C).normalized()) < 0.3], context="FACES")
bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
me = bpy.data.meshes.new("amber")
bm.to_mesh(me)
bm.free()
glow = bpy.data.objects.new("amber", me)
bpy.context.scene.collection.objects.link(glow)
glow.data.materials.append(amber)
for p in glow.data.polygons:
	p.use_smooth = False  # flat facets

# ---------------------------------------------------------------- body underneath: dark segmented belly
BELLY = [(-0.44, 0.16, 0.1), (-0.3, 0.26, 0.15), (0.0, 0.31, 0.16), (0.35, 0.28, 0.14), (0.55, 0.16, 0.09)]


def belly_at(y):
	j = max(k for k in range(len(BELLY) - 1) if BELLY[k][0] <= y) if y > BELLY[0][0] else 0
	j = min(j, len(BELLY) - 2)
	f = max(0.0, min(1.0, (y - BELLY[j][0]) / (BELLY[j + 1][0] - BELLY[j][0])))
	return BELLY[j][1] + (BELLY[j + 1][1] - BELLY[j][1]) * f, BELLY[j][2] + (BELLY[j + 1][2] - BELLY[j][2]) * f


ck.loft("belly", [((0, y, 0.35), w * 0.94, h * 0.88) for y, w, h in BELLY], chitin_dark, sides=16)
# Shingled bands, front to back: each band flares at its back edge and covers the front of the next one (no joints seen).
YS = [-0.42, -0.3, -0.17, -0.04, 0.09, 0.22, 0.35, 0.47]
for i, (y0, y1) in enumerate(zip(YS, YS[1:])):
	ln = y1 - y0
	w0, h0 = belly_at(y0)
	w1, h1 = belly_at(y1)
	ck.loft(f"belly_band{i}", [((0, y0, 0.35), w0 * 0.96, h0 * 0.9), ((0, y0 + ln * 0.5, 0.35), (w0 + w1) / 2 + 0.01, (h0 + h1) / 2 * 0.95 + 0.008),
		((0, y1 + ln * 0.12, 0.352), w1 + 0.022, h1 + 0.02), ((0, y1 + ln * 0.2, 0.352), w1 + 0.012, h1 + 0.012)], chitin, sides=16, subsurf=0)

# ---------------------------------------------------------------- the face, under the front edge
# Round 5 (owner): a small face tucked in under the shell (not puffy), no nose, a mouth you barely see; each eye one
# clean ball (iris, pupil and shine are PAINTED on in the sculpt pass, no stacked discs); a heavy lid under each stone
# brow for the grumpy look; sickle fangs with a blade edge, growth rings and one sharp tip; feelers growing out of the
# gaps above the brows, their roots melted into the face skin.
EYE_R = 0.084
EYE_LOOK = [Vector((s * 0.12, -1, -0.1)).normalized() for s in (-1, 1)]   # (sculpt_test_beetle.py paints along these)
EYES = [Vector((s * 0.122, -0.585, 0.455)) for s in (-1, 1)]
ck.loft("head", [((0, -0.3, 0.39), 0.2, 0.15), ((0, -0.44, 0.4), 0.215, 0.16), ((0, -0.54, 0.39), 0.2, 0.15),
	((0, -0.6, 0.355), 0.14, 0.11), ((0, -0.625, 0.325), 0.075, 0.07)], face_skin, sides=20)
# (round 6, owner: no mouth and no muzzle; the mandibles are the mouth)


def mandible(name, pts, r0, material, s, seed):
	"""A beetle mandible (pincer): thick where it grows out of the jaw, flattened top to bottom, a cutting edge with
	3 jagged teeth along the inside of the curve, tapering to one point. Hand-made, not perfect: every ring is a little
	lumpy and the two sides differ (owner, round 6). The cross-section is carried along the curve without twisting."""
	r = random.Random(seed)
	n = len(pts)
	pts = [p + Vector((r.uniform(-1, 1), r.uniform(-1, 1), r.uniform(-1, 1))) * 0.003 * math.sin(math.pi * i / (n - 1)) for i, p in enumerate(pts)]
	tans = [(pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized() for i in range(n)]
	ref = Vector((-s, 0, -0.15))  # the cutting edge faces in toward the other mandible
	sides = 16
	teeth = [(r.uniform(0.3, 0.36), r.uniform(0.5, 0.65)), (r.uniform(0.5, 0.56), r.uniform(0.6, 0.8)), (r.uniform(0.68, 0.74), r.uniform(0.4, 0.6))]
	verts, faces = [], []
	x = (ref - tans[0] * ref.dot(tans[0])).normalized()
	ctrl = [r.uniform(0.9, 1.1) for _ in range(7)]  # a few gentle bumps along it (not rings at every slice)
	lumps = []
	for i in range(n):
		f = i / (n - 1) * 6
		j = min(int(f), 5)
		w = (1 - math.cos(math.pi * (f - j))) / 2
		lumps.append(ctrl[j] * (1 - w) + ctrl[j + 1] * w)
	for i in range(n - 1):
		if i:
			x = (x - tans[i] * x.dot(tans[i])).normalized()
		y = tans[i].cross(x)
		t = i / (n - 1)
		groove = 1 - 0.08 * math.exp(-((t - 0.1) / 0.025) ** 2)
		rr = r0 * (1 - t) ** 0.75 * groove * lumps[i]
		tooth = sum(h * math.exp(-((t - tt) / 0.03) ** 2) for tt, h in teeth)
		for k in range(sides):
			a = 2 * math.pi * k / sides
			edge = max(0.0, math.cos(a)) ** 5
			blade = 1 + (0.35 + tooth) * edge
			verts.append(tuple(pts[i] + x * math.cos(a) * rr * blade + y * math.sin(a) * rr * 0.62))
	for i in range(n - 2):
		for k in range(sides):
			a0, a1 = i * sides + k, i * sides + (k + 1) % sides
			faces.append((a0, a1, a1 + sides, a0 + sides))
	verts.append(tuple(pts[-1]))  # the point
	tip = len(verts) - 1
	last = (n - 2) * sides
	for k in range(sides):
		faces.append((last + k, last + (k + 1) % sides, tip))
	verts.append(tuple(pts[0] - tans[0] * r0 * 0.3))  # root cap (buried in the jaw)
	base = len(verts) - 1
	for k in range(sides):
		faces.append(((k + 1) % sides, k, base))
	o = kit._mesh_obj(name, verts, faces, material, smooth=True)
	ck._fix_normals(o)
	return o


for s in (-1, 1):
	k = (s + 1) // 2
	c, look = EYES[k], EYE_LOOK[k]
	# socket: a rim of face skin hugging the eye (a ring), so the eye sits IN the face
	bpy.ops.mesh.primitive_torus_add(major_radius=EYE_R * 1.04, minor_radius=0.022, major_segments=32, minor_segments=12)
	ring = bpy.context.object
	ring.name = f"socket{s}"
	ring.matrix_world = Matrix.Translation(c - look * 0.004) @ frame(look).to_4x4()
	ring.data.materials.append(face_skin)
	# heavy upper lid: a thick cap over the top of the eye, coming lower on the nose side; its edge stops above the
	# pupil, so the eye glares from under it
	bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=18, radius=EYE_R + 0.01, location=(0, 0, 0))
	lid = bpy.context.object
	lid.name = f"lid{s}"
	cut = Vector((-s * 0.3, -0.25, 1)).normalized()
	bm = bmesh.new()
	bm.from_mesh(lid.data)
	bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=cut * (EYE_R + 0.01) * 0.42,
		plane_no=cut, clear_inner=True)  # one clean straight cut (no saw-tooth edge)
	bm.to_mesh(lid.data)
	bm.free()
	lid.location = c
	lid.data.materials.append(face_skin)
	sol = lid.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.022  # (inward: it sinks into the eye, no gap)
	for p in lid.data.polygons:
		p.use_smooth = True
	# the eyeball: plain cream here; sculpt_test_beetle.py paints the iris, pupil and shine on it
	bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=18, radius=EYE_R, location=c)
	o = bpy.context.object
	o.name = f"eye{s}"
	o.data.materials.append(eye)
	for p in o.data.polygons:
		p.use_smooth = True
	# mandibles: from a jaw knob low on each side of the face, forward and a little down, curling in like pincers
	ck.blob((s * 0.09, -0.58, 0.33), (0.055, 0.05, 0.045), face_skin, seed=41 + s, jitter=0.05)   # jaw knob
	pts = ck.bezier((s * 0.09, -0.585, 0.33), (s * 0.2, -0.67, 0.325), (s * 0.18, -0.81, 0.315), n=48, p3=(s * 0.05, -0.83, 0.3))  # flat pincers
	mandible(f"mandible{s}", pts, 0.048, mandible_mat, s, seed=70 + s)
	# feelers (round 6): each comes out of a ROUND hole in the gap between the horn and the brow: a ring of stone
	# (melted into the shell in the sculpt pass) with dark skin at the bottom; shingled segments curve up, out and
	# forward, ending in a club
	ck.blob((s * 0.15, -0.5, 0.54), (0.075, 0.07, 0.07), face_skin, seed=51, jitter=0.02)      # forehead
	path = ck.bezier((s * 0.105, -0.515, 0.62), (s * 0.2, -0.63, 0.8), (s * 0.34, -0.71, 0.75), n=8)
	axis = (path[1] - path[0]).normalized()
	ck.blob(tuple(path[0] - axis * 0.03), (0.045, 0.045, 0.045), face_skin, seed=61, jitter=0.02)  # the hole's bottom
	bpy.ops.mesh.primitive_torus_add(major_radius=0.045, minor_radius=0.02, major_segments=24, minor_segments=10)
	rim = bpy.context.object
	rim.name = f"feeler_hole{s}"
	rim.matrix_world = Matrix.Translation(path[0] + axis * 0.012) @ frame(axis).to_4x4()
	rim.data.materials.append(stone)
	with ck.part(f"soft_stalk_{'l' if s < 0 else 'r'}", hinge=tuple(path[0])):  # its own part: the game twitches it
		for i in range(len(path) - 1):
			a, b2 = path[i], path[i + 1]
			d = b2 - a
			r0 = 0.03 - 0.0015 * i
			ck.loft(f"feeler{s}{i}", [(a - d * 0.12, r0 * 0.8, r0 * 0.8), (a + d * 0.5, r0, r0), (b2 - d * 0.05, r0 * 1.12, r0 * 1.12),
				(b2 + d * 0.02, r0 * 0.95, r0 * 0.95)], chitin, sides=10, subsurf=0)
		ck.loft(f"club{s}", [(path[-1], 0.03, 0.03), (path[-1] + (path[-1] - path[-2]).normalized() * 0.05, 0.038, 0.036),
			(path[-1] + (path[-1] - path[-2]).normalized() * 0.09, 0.028, 0.028)], chitin, sides=12, subsurf=1)
# Heavy stone brows over the eyes (the grumpy V): lower on the inner side, pressing on the lids.
for s in (-1, 1):
	c = Vector((s * 0.13, -0.59, 0.588))
	n = Vector((s * 0.12, -0.7, 0.7)).normalized()
	pts = [(-0.125, -0.035), (-0.03, -0.07), (0.115, -0.085), (0.14, 0.0), (0.1, 0.07), (-0.06, 0.08), (-0.115, 0.045)]
	outline = [(x * s, y + 0.3 * x) for x, y in pts]  # the inner end lower: the grumpy V
	if s < 0:
		outline.reverse()
	o = plate(f"brow{s}", outline, c, n, 0.07, stone, seed=900, gap=0.0, tilt=(0.0, 0.04), sink=0.02)  # mirror images; sunk only
	# 2 cm (deeper, its buried bottom ran along the lid and poked through it in dark patches)
	o.modifiers["bevel"].width = 0.022
	o.modifiers["bevel"].segments = 3  # a rough cut stone like the shell's, not a box

# ---------------------------------------------------------------- the horn: thick, flat-sided, leaning forward
# Round 7 (owner): bigger, but still flat-sided like a cut stone slab; it leans forward and its tip curls back.
hp = ck.bezier((0, -0.39, 0.63), (0, -0.6, 0.88), (0, -0.57, 1.1), n=10)
ck.loft("horn", [(p, 0.115 - 0.055 * i / 9, 0.21 - 0.1 * i / 9) for i, p in enumerate(hp)], stone, sides=6, subsurf=0, smooth=False, up=Vector((0, -1, 0)))
ck.loft("horn_root", [((0, -0.35, 0.61), 0.135, 0.19), ((0, -0.43, 0.72), 0.115, 0.17)], stone, sides=6, subsurf=0, smooth=False, up=Vector((0, -1, 0)))


# ---------------------------------------------------------------- six fat legs, each its own part (turns at the hip)
LEG_RND = random.Random(77)


def barrel(name, a, b, r0, r1, material, sides=8):
	"""One leg segment like the painting's: a chunky faceted armour piece (8 flat sides) that widens toward its far end
	into a lip, so it covers the start of the next segment like a shingle (the joint stays hidden inside).
	Round 6 (owner: "too perfect"): every segment is a little different: thickness, squash, a twist so the flat sides
	don't line up, uneven facets, and a lip that sits a bit off-centre."""
	r = LEG_RND
	d = b - a
	k, sq, tw = r.uniform(0.92, 1.08), r.uniform(0.9, 1.04), r.uniform(-14, 14)
	side = d.cross(Vector((0, 0, 1)))
	side = side.normalized() if side.length > 1e-6 else Vector((1, 0, 0))
	off = side * r.uniform(-0.008, 0.008) + Vector((0, 0, r.uniform(-0.006, 0.006)))
	r0, r1 = r0 * k, r1 * k * r.uniform(0.95, 1.05)
	o = ck.loft(name, [(a, r0 * 0.78, r0 * 0.72 * sq, tw), (a + d * 0.12, r0 * 0.9, r0 * 0.84 * sq, tw),
		(a + d * 0.55, (r0 + r1) / 2, (r0 + r1) / 2 * 0.93 * sq, tw + r.uniform(-4, 4)),
		(b - d * 0.14 + off, r1 * 1.1, r1 * 1.02 * sq, tw), (b - d * 0.02 + off, r1 * 1.16, r1 * 1.08 * sq, tw), (b + off, r1 * 1.08, r1 * 1.0 * sq, tw)],
		material, sides=sides, subsurf=0, smooth=False, wobble=0.045, seed=r.randint(1, 9999))
	bv = o.modifiers.new("bevel", "BEVEL")
	bv.width = 0.006
	bv.segments = 2
	bv.limit_method = "ANGLE"
	bv.angle_limit = math.radians(20)
	return o


def talon(name, root, tip, r, bend, material, sides=12):
	"""A curved hooked claw: wide where it grows out of the foot, curving down to a sharp point. The tube's sideways
	direction is fixed to the horizontal, so it can't twist into a blob where the claw points straight down."""
	pts = ck.bezier(root, root.lerp(tip, 0.5) + bend, tip, n=12)
	rings = [(p, r * (1 - 0.97 * (j / 11) ** 1.35), r * 0.85 * (1 - 0.97 * (j / 11) ** 1.35)) for j, p in enumerate(pts)]
	side = Vector((tip.x - root.x, tip.y - root.y, 0)).normalized()
	return ck.loft(name, rings, material, sides=sides, subsurf=0, smooth=True, up=side)


def leg(s, i, hip, knee, ankle, toe):
	hip, knee, ankle, toe = Vector(hip), Vector(knee), Vector(ankle), Vector(toe)
	up_dir = (knee - hip).normalized()
	low_dir = (ankle - knee).normalized()
	with ck.part(f"leg_{'l' if s < 0 else 'r'}{i}", hinge=tuple(hip)):
		# Segments overlap like shingles: each one starts inside the lip of the one before it.
		c1 = hip + (knee - hip) * 0.34
		barrel("coxa", hip - up_dir * 0.04, c1, 0.125, 0.13, chitin)
		barrel("femur", c1 - up_dir * 0.04, knee + low_dir * 0.01, 0.122, 0.125, chitin)
		t1 = knee + (ankle - knee) * 0.52
		barrel("tibia", knee - low_dir * 0.035, t1, 0.116, 0.11, chitin)
		barrel("tarsus", t1 - low_dir * 0.04, ankle, 0.1, 0.09, chitin)
		out_dir = Vector((toe.x - ankle.x, toe.y - ankle.y, 0)).normalized()
		# One claw lying FLAT on the ground like a toe (owner, round 5): its underside rests on the ground all along,
		# from under the foot out to a point. Its root is tucked into the end of the last segment.
		rings = []
		for j in range(14):
			t = j / 13
			w = 0.06 * (1 - 0.96 * t ** 1.4)
			h = 0.04 * (1 - 0.96 * t ** 1.4)
			hook = 0.016 * max(0.0, (t - 0.7) / 0.3) ** 2  # the last bit bends down: a hooked tip that bites in
			p = Vector((ankle.x, ankle.y, GROUND + h + 0.006 * math.sin(math.pi * t) - hook)) + out_dir * (-0.035 + 0.18 * t)
			rings.append((p, w, h))
		ck.loft("claw", rings, claw, sides=12, subsurf=0, smooth=True, up=Vector((0, 0, 1)))


GROUND = -0.11  # where the claws lie (the save puts the lowest point on the ground, lifting the body 11 cm)
LEGS = [  # hip, knee, ankle, which way the claw points   (+X side; mirrored)
	((0.2, -0.25, 0.27), (0.43, -0.33, 0.2), (0.47, -0.41, -0.04), (0.52, -0.5, -0.11)),
	((0.25, 0.0, 0.26), (0.5, 0.03, 0.2), (0.56, 0.07, -0.04), (0.62, 0.13, -0.11)),
	((0.23, 0.27, 0.27), (0.47, 0.35, 0.2), (0.53, 0.44, -0.04), (0.57, 0.53, -0.11)),
]
for s in (-1, 1):
	for i, pts in enumerate(LEGS):
		leg(s, i, *[(s * p[0], p[1], p[2]) for p in pts])

ck.save(out, preview)
