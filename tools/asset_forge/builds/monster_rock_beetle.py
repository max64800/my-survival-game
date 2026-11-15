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
amber = ck.color("glow_back", (1.0, 0.55, 0.08), rough=0.2)
amber.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1.0, 0.55, 0.1, 1)
amber.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.5
eye = ck.eye_mat((0.95, 0.9, 0.8))
iris = ck.color("iris", (0.35, 0.2, 0.09), rough=0.3)
pupil = ck.color("pupil", (0.03, 0.02, 0.02), rough=0.2)
shine = ck.color("shine", (1, 1, 1), rough=0.1, glow=0.6)

# ---------------------------------------------------------------- the shell: the top of an ellipsoid
C = Vector((0.0, 0.03, 0.52))       # centre
A, B, CZ = 0.43, 0.56, 0.4          # half-width, half-length, half-height of the dome UNDER the plates (plates add ~0.1)
RIM_Z = 0.37                         # the shell's lower edge (it comes down over the tops of the legs)


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
		SEEDS.append(dir_side(y, 0.46, s))        # the lower row along each side (the skirt over the legs)
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
bmesh.ops.delete(bm, geom=[v for v in bm.verts if surf(v.co.normalized())[0].z < RIM_Z - 0.06],
	context="VERTS")  # (no moss under the glowing window)
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
	return p.z >= RIM_Z and amber_at(d) <= 0 and not (d.dot(FACE_DIR) > math.cos(math.radians(30)) and p.z < 0.62)


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

# The glowing amber window: a smooth bulging dome (lit from inside), its edge tucked under the framing plates.
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1)
glow = bpy.context.object
glow.name = "amber"
bm = bmesh.new()
bm.from_mesh(glow.data)
GROW = math.radians(9)  # its edge reaches well under the framing plates
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
# Read off the drawings: a wide red-brown face mask, cheeks, a ridge down the middle to a pouty mouth, big eyes in
# dark sockets under thick angry lids, stone brows (shell plates) in a V, two pale tusks, segmented feelers.
EYE_R = 0.088
EYES = [Vector((s * 0.128, -0.6, 0.45)) for s in (-1, 1)]
ck.loft("head", [((0, -0.32, 0.38), 0.23, 0.16), ((0, -0.45, 0.39), 0.27, 0.19), ((0, -0.55, 0.39), 0.25, 0.18),
	((0, -0.61, 0.37), 0.19, 0.14), ((0, -0.645, 0.35), 0.1, 0.09)], face_skin, sides=20)
for s in (-1, 1):
	ck.blob((s * 0.19, -0.57, 0.36), (0.085, 0.07, 0.095), face_skin, seed=21 + s, jitter=0.05)        # cheeks
	c = EYES[(s + 1) // 2]
	# eye socket: a thick rim around the eye, so it sits IN the face
	look = Vector((s * 0.3, -1, 0.05)).normalized()
	ck.loft(f"socket{s}", [(c - look * 0.035, EYE_R * 1.02, EYE_R * 1.02), (c + look * 0.005, EYE_R * 1.2, EYE_R * 1.18),
		(c + look * 0.03, EYE_R * 1.1, EYE_R * 1.08)], face_skin, sides=24, subsurf=0, up=Vector((0, 0, 1)))
	# angry upper lid: a thick cap over the top of the eye, lower toward the nose
	bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=EYE_R * 1.12, location=(0, 0, 0))
	lid = bpy.context.object
	cut = Vector((-s * 0.5, -0.85, 0.8)).normalized()  # the lid comes down over the front of the eye, lower toward the nose
	bm = bmesh.new()
	bm.from_mesh(lid.data)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.normalized().dot(cut) < 0.3], context="VERTS")
	bm.to_mesh(lid.data)
	bm.free()
	lid.location = c
	lid.data.materials.append(face_skin)
	sol = lid.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.022
	for p in lid.data.polygons:
		p.use_smooth = True
	# lower lid: a thin cap from below (the squint)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=EYE_R * 1.1, location=(0, 0, 0))
	low = bpy.context.object
	bm = bmesh.new()
	bm.from_mesh(low.data)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.normalized().dot(Vector((s * 0.2, -0.3, -1)).normalized()) < 0.55], context="VERTS")
	bm.to_mesh(low.data)
	bm.free()
	low.location = c
	low.data.materials.append(face_skin)
	sol = low.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.016
	for p in low.data.polygons:
		p.use_smooth = True
# nose ridge down to the mouth, and a pouty mouth
ck.loft("ridge", [((0, -0.63, 0.5), 0.035, 0.03), ((0, -0.66, 0.41), 0.048, 0.035), ((0, -0.675, 0.34), 0.06, 0.04)], face_skin, sides=12)
ck.blob((0, -0.665, 0.3), (0.06, 0.035, 0.028), face_skin, seed=31, jitter=0.03)    # upper lip
ck.blob((0, -0.655, 0.268), (0.048, 0.032, 0.024), face_skin, seed=32, jitter=0.03)  # lower lip
ck.blob((0, -0.66, 0.285), (0.046, 0.02, 0.008), pupil, seed=33, jitter=0.0, subsurf=0)  # the mouth line
for s in (-1, 1):
	c = EYES[(s + 1) // 2]
	bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=EYE_R, location=c)
	o = bpy.context.object
	o.data.materials.append(eye)
	for p in o.data.polygons:
		p.use_smooth = True
	look = Vector((s * 0.12, -1, -0.12)).normalized()  # a glare, a little down and in
	for rad, off, flat, m in ((0.066, 0.069, 0.4, iris), (0.035, 0.083, 0.4, pupil)):
		bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1)
		q = bpy.context.object
		q.scale = (rad, rad, rad * flat)
		bpy.ops.object.transform_apply(scale=True)
		q.matrix_world = Matrix.Translation(c + look * off) @ frame(look).to_4x4()
		q.data.materials.append(m)
		for p in q.data.polygons:
			p.use_smooth = True
	ck.blob(tuple(c + look * 0.09 + Vector((s * -0.02, 0, 0.026))), (0.016, 0.009, 0.016), shine, seed=3, subsurf=0)
	# tusks: thick pale jaws from the corners of the mouth, curving forward, down and in
	root = Vector((s * 0.105, -0.6, 0.36))
	pts = ck.bezier(root, root + Vector((s * 0.07, -0.13, -0.07)), Vector((s * 0.03, -0.71, 0.22)), n=12, p3=Vector((s * 0.012, -0.69, 0.25)))
	ck.loft(f"tusk{s}", [(p, 0.056 * (1 - 0.95 * (j / 11) ** 1.3), 0.048 * (1 - 0.95 * (j / 11) ** 1.3)) for j, p in enumerate(pts)], claw,
		sides=12, subsurf=0, smooth=True, up=Vector((s, 0, 0)))
	# feelers: shingled segments (like the legs), from above the eye, curving up and out, ending in a club
	path = ck.bezier((s * 0.12, -0.6, 0.56), (s * 0.27, -0.7, 0.7), (s * 0.4, -0.74, 0.6), n=8)
	for i in range(len(path) - 1):
		a, b = path[i], path[i + 1]
		d = b - a
		ck.loft(f"feeler{s}{i}", [(a - d * 0.1, 0.022, 0.022), (a + d * 0.5, 0.027, 0.027), (b - d * 0.05, 0.031, 0.031), (b + d * 0.02, 0.026, 0.026)],
			chitin, sides=10, subsurf=0)
	ck.loft(f"club{s}", [(path[-1], 0.034, 0.034), (path[-1] + (path[-1] - path[-2]).normalized() * 0.05, 0.04, 0.038),
		(path[-1] + (path[-1] - path[-2]).normalized() * 0.09, 0.03, 0.03)], chitin, sides=12, subsurf=1)
# Heavy stone brows over the eyes (the grumpy V): lower on the inner side.
for s in (-1, 1):
	c = Vector((s * 0.135, -0.6, 0.555))
	n = Vector((s * 0.12, -0.7, 0.7)).normalized()
	pts = [(-0.13, -0.045), (0.12, -0.09), (0.135, 0.045), (-0.11, 0.075)]
	outline = [(x * s, y) for x, y in pts]
	if s < 0:
		outline.reverse()
	plate(f"brow{s}", outline, c, n, 0.075, stone, seed=900 + s, gap=0.0)

# ---------------------------------------------------------------- the horn: thick, flat-sided, leaning forward
hp = ck.bezier((0, -0.4, 0.64), (0, -0.56, 0.86), (0, -0.6, 1.05), n=8)
ck.loft("horn", [(p, 0.1 - 0.045 * i / 7, 0.2 - 0.085 * i / 7) for i, p in enumerate(hp)], stone, sides=6, subsurf=0, smooth=False, up=Vector((0, -1, 0)))
ck.loft("horn_root", [((0, -0.36, 0.62), 0.12, 0.17), ((0, -0.43, 0.72), 0.1, 0.15)], stone, sides=6, subsurf=0, smooth=False, up=Vector((0, -1, 0)))


# ---------------------------------------------------------------- six fat legs, each its own part (turns at the hip)
def barrel(name, a, b, r0, r1, material, sides=8):
	"""One leg segment like the painting's: a chunky faceted armour piece (8 flat sides) that widens toward its far end
	into a lip, so it covers the start of the next segment like a shingle (the joint stays hidden inside)."""
	d = b - a
	o = ck.loft(name, [(a, r0 * 0.78, r0 * 0.72), (a + d * 0.12, r0 * 0.9, r0 * 0.84), (a + d * 0.55, (r0 + r1) / 2, (r0 + r1) / 2 * 0.93),
		(b - d * 0.14, r1 * 1.1, r1 * 1.02), (b - d * 0.02, r1 * 1.16, r1 * 1.08), (b, r1 * 1.08, r1 * 1.0)],
		material, sides=sides, subsurf=0, smooth=False, seed=len(name))
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
		barrel("coxa", hip - up_dir * 0.04, c1, 0.1, 0.104, chitin)
		barrel("femur", c1 - up_dir * 0.04, knee + low_dir * 0.01, 0.097, 0.1, chitin)
		t1 = knee + (ankle - knee) * 0.52
		barrel("tibia", knee - low_dir * 0.035, t1, 0.092, 0.088, chitin)
		barrel("tarsus", t1 - low_dir * 0.04, ankle, 0.08, 0.072, chitin)
		out_dir = Vector((toe.x - ankle.x, toe.y - ankle.y, 0)).normalized()
		root = ankle - low_dir * 0.05  # a short hooked claw tip grows out of the end of the foot
		tip = Vector((ankle.x, ankle.y, -0.11)) + out_dir * 0.075  # the claw is the foot's tip and reaches the ground
		talon("claw", root, tip, 0.062, out_dir * 0.035 + Vector((0, 0, 0.03)), claw)


LEGS = [  # hip, knee, ankle, claw tip   (+X side; mirrored)
	((0.18, -0.25, 0.28), (0.44, -0.34, 0.24), (0.5, -0.43, -0.03), (0.54, -0.52, -0.11)),
	((0.24, 0.0, 0.27), (0.54, 0.04, 0.24), (0.63, 0.1, -0.03), (0.68, 0.17, -0.11)),
	((0.22, 0.28, 0.28), (0.5, 0.37, 0.24), (0.58, 0.48, -0.03), (0.62, 0.57, -0.11)),
	# (the foot almost on the ground; the save puts the lowest point on the ground, lifting the body ~11 cm)
]
for s in (-1, 1):
	for i, pts in enumerate(LEGS):
		leg(s, i, *[(s * p[0], p[1], p[2]) for p in pts])

ck.save(out, preview)
