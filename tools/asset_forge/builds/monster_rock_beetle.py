# Rock Beetle, hand-built to match the owner's approved pictures (assets/concepts/creatures/rock_beetle*.png).
# By Claude 3, November 15, 2026 (rebuild of the Nov 14 script; MODEL-RULES Rule 1: hand-built only).
#
#   blender --background --factory-startup --python builds/monster_rock_beetle.py -- <out.glb> [preview.png] look=mossy
#
# What the picture shows (written down before building):
# - A wide, low dome, about 1.6x longer than tall. The shell covers almost everything; the body is a
#   dark red-brown band underneath, the face is small and tucked under the front rim.
# - Shell: ~14 big chunky faceted stone slabs (warm grey) with moss in the cracks between them.
#   The back third is an open, faceted amber dome that glows (the weak spot).
# - One thick, flat-sided stone horn rising from the front of the shell, curving up and back.
# - Face: dark red-brown, big cream eyes with a brown iris, black pupil and a white shine; angry lids;
#   two pale hooked mandibles like tusks; two segmented feelers with a club at the end.
# - Six chunky red-brown legs, each 3 faceted segments, spread wide, ending in 2-3 pale curved claws.
# The 4 looks share this ONE body (same slabs, legs, face); only paint and extras change:
#   mossy: grey stone, moss in cracks, amber back        frost: blue-grey stone, snow caps, ice spikes, forked ice horn, cyan back
#   ember: basalt with glowing lava cracks, amber crystals, hammer horn, orange back
#   spore: purple stone, little glowing mushrooms, antler horn with mushrooms, violet back
#
# Moving parts (the game finds them by name, see docs/design/creature-craft.md): leg_l0..2 / leg_r0..2 turn at
# the hip. Materials: "eye" flashes before an attack; "glow*" (the back, ember cracks) blazes when it charges.
import math
import random
import sys
import tempfile
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402
import kit  # noqa: E402

out, preview = kit.args()
ARGS = sys.argv[sys.argv.index("--") + 1:]
LOOK = next((a[5:] for a in ARGS if a.startswith("look=")), "mossy")
ck.reset()
rnd = random.Random(17)          # the body is the same for every look
xr = random.Random({"mossy": 1, "frost": 2, "ember": 3, "spore": 4}[LOOK] * 101)  # extras differ per look

# ---------------------------------------------------------------- paint
TMP = Path(tempfile.gettempdir()) / "rock_beetle_tex"
TMP.mkdir(exist_ok=True)


def painted(name, kind, variant, mult=(1, 1, 1), add=0.0, tile=None, rough=0.85):
	"""A kit hand-painted texture, re-coloured (multiply + lighten), as its own material."""
	src = kit.TEX / f"{kind}_{variant}.png"
	dst = TMP / f"{name}.png"
	img = bpy.data.images.load(str(src), check_existing=False)
	w, h = img.size
	px = np.empty(w * h * 4, dtype=np.float32)
	img.pixels.foreach_get(px)
	px = px.reshape(-1, 4)
	px[:, :3] = np.clip(px[:, :3] * np.array(mult, dtype=np.float32) + add, 0, 1)
	img.pixels.foreach_set(px.ravel())
	img.filepath_raw = str(dst)
	img.file_format = "PNG"
	img.save()
	bpy.data.images.remove(img)
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = rough
	t = m.node_tree.nodes.new("ShaderNodeTexImage")
	t.image = bpy.data.images.load(str(dst))
	m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
	m["tile"] = tile or kit.TILE[kind]
	return m


def glow_mat(name, rgb, strength):
	m = ck.color(name, rgb, rough=0.3)
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Emission Color"].default_value = (*rgb, 1)
	b.inputs["Emission Strength"].default_value = strength
	return m


P = {  # slab texture, crack colour, leg tint, back glow
	"mossy": dict(slab=("stone", (1.02, 1.0, 0.97), 0.0), crack=(0.22, 0.3, 0.08), leg=(1.0, 0.72, 0.62), back=(1.0, 0.38, 0.0)),
	"frost": dict(slab=("basalt", (1.05, 1.2, 1.45), 0.1), crack=(0.08, 0.1, 0.16), leg=(0.6, 0.66, 0.8), back=(0.25, 0.85, 1.0)),
	"ember": dict(slab=("basalt", (1.35, 1.15, 1.0), 0.16), crack=(1.0, 0.27, 0.02), leg=(1.0, 0.68, 0.58), back=(1.0, 0.36, 0.02)),
	"spore": dict(slab=("sporestone", (1.15, 1.0, 1.1), 0.05), crack=(0.2, 0.24, 0.1), leg=(0.95, 0.75, 0.95), back=(0.7, 0.3, 1.0)),
}[LOOK]
kind, mult, add = P["slab"]
slab_m = [painted(f"slab_{LOOK}_{k}", kind, v, tuple(c * s for c in mult), add, tile=2.6)
	for k, (v, s) in enumerate((("a", 1.0), ("b", 0.93), ("c", 1.06)))]
slab_warm = painted(f"slab_{LOOK}_warm", kind, "b", tuple(c * s for c, s in zip(mult, (1.08, 0.98, 0.88))), add, tile=2.6)  # ~1 in 8
if LOOK == "ember":  # lava in the cracks: glows a little always, blazes on a charge (material name glow*)
	crack_m = glow_mat("glow_lava", P["crack"], 0.5)
else:  # deep shadow between the plates (Rule 3: the backing is dark); moss/ice/spores are added on top
	crack_m = ck.color(f"crack_{LOOK}", tuple(c * 0.035 + 0.01 for c in P["leg"]), rough=1.0)
	crack_m.node_tree.nodes["Principled BSDF"].inputs["Specular IOR Level"].default_value = 0.0
LEGTEX, LEGADD = {"frost": ("stone", 0.0), "spore": ("sporestone", 0.04)}.get(LOOK, ("brownrock", 0.0))  # legs match the look
leg_m = painted(f"leg_{LOOK}", LEGTEX, "a", P["leg"], LEGADD, tile=0.35)
leg_dark = painted(f"legj_{LOOK}", LEGTEX, "dark" if LEGTEX == "brownrock" else "b", tuple(c * 0.8 for c in P["leg"]), LEGADD, tile=0.35)
face_m = painted(f"face_{LOOK}", LEGTEX, "a", tuple(c * 0.85 for c in P["leg"]), LEGADD, tile=0.3)
claw_m = painted("claw", "limestone", "a", (1.0, 0.82, 0.6), -0.05, tile=0.25, rough=0.6)
back_m = glow_mat("glow_back", P["back"], 0.22)
back_m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*[c * 0.8 for c in P["back"]], 1)
back_m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.15
eye_m = ck.eye_mat((0.93, 0.87, 0.72))  # cream: the game flashes it before an attack
iris_m = ck.color("iris", (0.33, 0.18, 0.08), rough=0.3)
pupil_m = ck.color("pupil", (0.03, 0.02, 0.02), rough=0.2)
shine_m = ck.color("shine", (1.0, 1.0, 1.0), rough=0.1, glow=0.6)

# ---------------------------------------------------------------- the shell dome (Blender: faces -Y, +Z up)
C = Vector((0.0, 0.03, 0.22))
A, B, CZ = 0.42, 0.5, 0.36   # half-width, half-length, height of the dome


def on_dome(t, a, lift=0.0):
	"""t: -1 front .. 1 back; a: 0 = left side .. pi/2 = top .. pi = right side. Returns point, normal."""
	k = math.sqrt(max(0.0, 1 - t * t))
	p = Vector((-math.cos(a) * A * k, C.y + B * t, C.z + math.sin(a) * CZ * k))
	n = Vector((p.x / A ** 2, (p.y - C.y) / B ** 2, (p.z - C.z) / CZ ** 2)).normalized()
	return p + n * lift, n


BACK_AXIS = Vector((0, 0.85, 0.55)).normalized()   # where the glowing back pokes out
FACE_AXIS = Vector((0, -1, -0.25)).normalized()    # the face, under the front rim


def frame(n, spin):
	"""A rotation matrix whose Z points along n, turned by `spin` around it."""
	z = n.normalized()
	x = Vector((1, 0, 0)) if abs(z.x) < 0.9 else Vector((0, 1, 0))
	y = z.cross(x).normalized()
	x = y.cross(z).normalized()
	m = Matrix((x, y, z)).transposed()
	return m @ Matrix.Rotation(spin, 3, "Z")


def slab(name, at, n, sx, sy, thick, material, seed, sink=0.55):
	"""One chunky stone slab: an uneven 5-7 sided block with a smaller faceted top (like the picture's
	hand-cut plates), its bottom sunk into the dome so it never floats."""
	r = random.Random(seed)
	k = r.choice((5, 6, 6, 7))
	rot = frame(n, r.uniform(0, math.tau))
	base_a = r.uniform(0, math.tau)
	radii = [r.uniform(0.88, 1.1) for _ in range(k)]
	bm = bmesh.new()
	rings = []
	for z, s in ((-thick * sink, 0.95), (thick * 0.18, 1.0), (thick * 0.4, 0.84)):
		ring = []
		for i in range(k):
			a = base_a + math.tau * i / k + r.uniform(-0.12, 0.12)
			v = Vector((math.cos(a) * sx * radii[i] * s, math.sin(a) * sy * radii[i] * s, z + (r.uniform(-0.04, 0.04) * thick if z > 0.2 * thick else 0)))
			ring.append(bm.verts.new(at + rot @ v))
		rings.append(ring)
	bot = bm.verts.new(at + rot @ Vector((0, 0, -thick * sink)))
	for a, b in zip(rings, rings[1:]):
		for i in range(k):
			j = (i + 1) % k
			bm.faces.new((a[i], a[j], b[j], b[i]))
	bm.faces.new(rings[-1])  # one broad flat cut face on top, like the picture's plates
	for i in range(k):
		j = (i + 1) % k
		bm.faces.new((rings[0][j], rings[0][i], bot))
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(material)
	kit._uv_box(o, material["tile"])
	for p in o.data.polygons:
		p.use_smooth = False
	bv = o.modifiers.new("bevel", "BEVEL")
	bv.width = 0.008
	bv.segments = 1
	bv.limit_method = "ANGLE"
	return o


# The hidden layer under the slabs: the colour seen in the cracks (moss / ice-dark / lava / spore moss).
def dome_cap(name, scale, material, keep, subdiv=3, flat=False, jitter=0.0, seed=1, bulge=None):
	"""Part of the shell's ellipsoid (scaled), keeping only vertices where keep(direction) is true."""
	bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=(0, 0, 0))
	o = bpy.context.object
	o.name = name
	r = random.Random(seed)
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep(v.co.normalized())], context="VERTS")
	for v in bm.verts:
		sc = scale + (bulge(v.co.normalized()) if bulge else 0.0)
		v.co = Vector((v.co.x * A * sc, v.co.y * B * sc, v.co.z * CZ * sc)) * (1 + r.uniform(-jitter, jitter)) + C
	bm.to_mesh(o.data)
	bm.free()
	o.data.materials.append(material)
	if "tile" in material:
		kit._uv_box(o, material["tile"])
	for p in o.data.polygons:
		p.use_smooth = not flat
	return o


# The hidden layer under the slabs: the colour seen in the cracks (moss / ice-dark / lava / spore moss).
dome_cap("shell_under", 0.975, crack_m, lambda d: d.z > -0.3)

# Slabs in rows from front to back, each row an arc from the left rim over the top to the right rim.
def hull2d(pts):
	"""Convex outline of 2D points (monotone chain), counter-clockwise."""
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


def plate(name, outline, centre, n, rot, thick, material, seed, gap=0.012, sink=0.05):
	"""One fitted shell plate: its outline is its patch of the dome (so plates fit together like armour),
	pulled in by `gap` (the crack), with one flat cut top face and a chamfered edge."""
	r = random.Random(seed)
	pts = [Vector(p) for p in outline]
	mid = sum(pts, Vector()) / len(pts)
	tilt = Vector((r.uniform(-0.12, 0.12), r.uniform(-0.12, 0.12), 0))
	bm = bmesh.new()
	rings = []
	for z, shrink in ((-sink, gap + 0.004), (thick * 0.72, gap), (thick, gap + 0.014)):
		ring = []
		for p in pts:
			d = p - mid
			q = mid + d * max(0.0, 1 - shrink / max(d.length, 1e-4))
			h = z + (tilt.x * q.x + tilt.y * q.y if z > 0 else 0.0)
			ring.append(bm.verts.new(centre + rot @ Vector((q.x, q.y, h))))
		rings.append(ring)
	k = len(pts)
	for a, b in zip(rings, rings[1:]):
		for i in range(k):
			j = (i + 1) % k
			bm.faces.new((a[i], a[j], b[j], b[i]))
	bm.faces.new(rings[-1])
	bm.faces.new(list(reversed(rings[0])))
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(material)
	kit._uv_box(o, material["tile"])
	for p in o.data.polygons:
		p.use_smooth = False
	bv = o.modifiers.new("bevel", "BEVEL")
	bv.width = 0.007
	bv.segments = 1
	bv.limit_method = "ANGLE"
	return o


# Seeds for the plates, in loose rows. Seeds over the glowing back and the face are "holes": they
# claim their patch of the dome but get no plate.
seeds = []
for ri, t in enumerate([-0.86, -0.5, -0.12, 0.26, 0.62, 0.9]):
	k = math.sqrt(1 - t * t)
	n_here = max(2, round(math.pi * 0.5 * (A + CZ) * k * 1.3 / 0.24))
	for i in range(n_here):
		f = (i + (0.25 if ri % 2 else 0.75) + rnd.uniform(-0.15, 0.15)) / n_here
		a = -0.45 + (math.pi + 0.9) * f
		p, n = on_dome(t + rnd.uniform(-0.05, 0.05), a)
		hole = n.dot(BACK_AXIS) > math.cos(math.radians(56)) or (n.dot(FACE_AXIS) > math.cos(math.radians(32)) and n.z < 0.3)
		seeds.append((p, n, hole))
# Sample the dome finely and give each sample to its nearest seed.
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5, radius=1)
probe = bpy.context.object
samples = []
for v in probe.data.vertices:
	d = v.co.normalized()
	if d.z < -0.42:
		continue
	samples.append(Vector((d.x * A, d.y * B, d.z * CZ)) + C)
bpy.data.objects.remove(probe)
cells = [[] for _ in seeds]
for q in samples:
	cells[min(range(len(seeds)), key=lambda i: (seeds[i][0] - q).length_squared)].append(q)
slabs = []  # (point, normal, size) for moss/snow/crystals later
for i, ((p, n, hole), cell) in enumerate(zip(seeds, cells)):
	if hole or len(cell) < 3:
		continue
	cen = sum(cell, Vector()) / len(cell)
	nn = Vector((cen.x / A ** 2, (cen.y - C.y) / B ** 2, (cen.z - C.z) / CZ ** 2)).normalized()
	base_pt = C + Vector(((cen - C).x, (cen - C).y, (cen - C).z)) * 1.0
	rot = frame(nn, 0)
	inv = rot.transposed()
	flat = [tuple(round(c, 4) for c in (inv @ (q - base_pt))[:2]) for q in cell]
	outline = hull2d(flat)
	if len(outline) < 3:
		continue
	mat_ = slab_warm if rnd.random() < 0.12 else rnd.choice(slab_m)
	thick = rnd.uniform(0.085, 0.11)
	plate(f"plate{i}", [(x, y, 0) for x, y in outline], base_pt, nn, rot, thick, mat_, seed=i, gap=0.011)
	size = max(Vector((x, y, 0)).length for x, y in outline)
	slabs.append((base_pt, nn, size * 0.6, thick))
# Brow slabs: two heavy plates hanging over the eyes (the grumpy look).
for s in (-1, 1):
	p = Vector((s * 0.1, -0.49, 0.4))
	n = Vector((s * 0.3, -0.8, 0.5)).normalized()
	slab(f"brow{s}", p, n, 0.12, 0.08, 0.07, slab_m[0], seed=900 + s)

# The glowing back (weak spot): a big faceted dome poking out of the shell's back.
# Same ellipsoid, a bit bigger (it bulges out between the slabs), big flat facets like cut amber.
def _back_dot(d):
	return Vector((d.x / A, d.y / B, d.z / CZ)).normalized().dot(BACK_AXIS)


EDGE = math.cos(math.radians(66))
amber = dome_cap("back", 1.06, back_m, lambda d: _back_dot(d) > EDGE, subdiv=3, flat=True, jitter=0.012, seed=5,
	bulge=lambda d: 0.24 * min(1.0, max(0.0, (_back_dot(d) - EDGE) / (1 - EDGE)) * 1.6) ** 0.7)
for k, (shade, glow) in enumerate(((1.15, 0.32), (0.7, 0.16))):  # cut-gem facets: some lighter, some deeper
	m = glow_mat(f"glow_back{k}", tuple(min(1.0, c * shade) for c in P["back"]), glow)
	m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*[min(1.0, c * shade * 0.8) for c in P["back"]], 1)
	amber.data.materials.append(m)
r3 = random.Random(9)
for poly in amber.data.polygons:
	poly.material_index = r3.choice((0, 0, 1, 2))

# ---------------------------------------------------------------- body underneath
ck.loft("belly", [((0, -0.4, 0.18), 0.17, 0.08), ((0, -0.2, 0.17), 0.29, 0.12), ((0, 0.15, 0.17), 0.32, 0.13),
	((0, 0.42, 0.19), 0.24, 0.1), ((0, 0.52, 0.2), 0.1, 0.06)], leg_dark, sides=14)
BELLY = [(-0.4, 0.17, 0.08), (-0.2, 0.29, 0.12), (0.15, 0.32, 0.13), (0.42, 0.24, 0.1)]
for i, y in enumerate((-0.25, -0.05, 0.15, 0.33)):  # segment rings on the belly, 1.5 cm proud of it (no shimmer)
	j = max(k for k in range(len(BELLY) - 1) if BELLY[k][0] <= y)
	f = (y - BELLY[j][0]) / (BELLY[j + 1][0] - BELLY[j][0])
	w, h = (BELLY[j][1] + (BELLY[j + 1][1] - BELLY[j][1]) * f + 0.015, BELLY[j][2] + (BELLY[j + 1][2] - BELLY[j][2]) * f + 0.015)
	ck.loft(f"belly_ring{i}", [((0, y - 0.015, 0.17), w, h), ((0, y + 0.015, 0.17), w, h)], leg_m, sides=14, subsurf=0)

# ---------------------------------------------------------------- face (under the front rim)
ck.loft("head", [((0, -0.34, 0.24), 0.21, 0.16), ((0, -0.45, 0.25), 0.22, 0.17), ((0, -0.53, 0.23), 0.17, 0.14),
	((0, -0.57, 0.2), 0.08, 0.08)], face_m, sides=14)
ck.blob((0, -0.575, 0.15), (0.045, 0.025, 0.022), pupil_m, seed=11, jitter=0.05)  # the mouth
for s in (-1, 1):
	c = Vector((s * 0.1, -0.51, 0.3))
	fwd = Vector((s * 0.4, -1, 0.05)).normalized()
	bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.076, location=c)
	o = bpy.context.object
	o.data.materials.append(eye_m)
	for p in o.data.polygons:
		p.use_smooth = True
	look = fwd.lerp(Vector((0, -1, -0.1)).normalized(), 0.35).normalized()  # looks a little inward: grumpy
	for rad, off, flat, m in ((0.052, 0.061, 0.45, iris_m), (0.028, 0.073, 0.4, pupil_m)):
		bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1, location=(0, 0, 0))
		q = bpy.context.object
		q.scale = (rad, rad, rad * flat)
		bpy.ops.object.transform_apply(scale=True)
		q.matrix_world = Matrix.Translation(c + look * off) @ frame(look, 0).to_4x4()
		q.data.materials.append(m)
		for p in q.data.polygons:
			p.use_smooth = True
	ck.blob(tuple(c + look * 0.08 + Vector((s * -0.012, 0, 0.02))), (0.011, 0.007, 0.011), shine_m, seed=3, subsurf=0)
	# Angry lid: a thick cap over the top of the eye, lower on the inner side.
	bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.083, location=(0, 0, 0))
	lid = bpy.context.object
	cut = Vector((-s * 0.55, -0.15, 1)).normalized()
	bm = bmesh.new()
	bm.from_mesh(lid.data)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.normalized().dot(cut) < 0.3], context="VERTS")
	bm.to_mesh(lid.data)
	bm.free()
	lid.location = c
	lid.data.materials.append(face_m)
	kit._uv_box(lid, face_m["tile"])
	sol = lid.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.012
	for p in lid.data.polygons:
		p.use_smooth = True
	# Mandibles: pale hooked tusks curving down and in.
	jaw = ck.bezier((s * 0.065, -0.54, 0.17), (s * 0.13, -0.64, 0.15), (s * 0.045, -0.67, 0.07), n=8)
	ck.limb(f"jaw{s}", jaw, 0.036, 0.007, claw_m, sides=7)
	# Feelers: a chain of short segments ending in a club.
	path = ck.bezier((s * 0.07, -0.5, 0.37), (s * 0.18, -0.64, 0.52), (s * 0.31, -0.64, 0.45), n=9)
	for i in range(len(path) - 1):
		a, b = path[i], path[i + 1]
		ck.loft(f"feeler{s}{i}", [(a.lerp(b, -0.12), 0.016, 0.016), (a.lerp(b, 0.5), 0.02, 0.02), (b.lerp(a, -0.12), 0.016, 0.016)], leg_m, sides=7, subsurf=0)
	ck.blob(tuple(path[-1] + (path[-1] - path[-2]).normalized() * 0.02), (0.03, 0.026, 0.026), leg_m, seed=12, jitter=0.1)

# ---------------------------------------------------------------- the horn
hb, hn = on_dome(-0.6, math.pi / 2)
base = hb - hn * 0.04


def horn_loft(name, pts, w0, w1, d0, d1, material, sides=6):
	rings = []
	for i, p in enumerate(pts):
		f = i / (len(pts) - 1)
		rings.append((p, w0 + (w1 - w0) * f, d0 + (d1 - d0) * f))
	return ck.loft(name, rings, material, sides=sides, subsurf=0, smooth=False, up=Vector((0, -1, 0)))


ice = ck.color("ice", (0.62, 0.86, 1.0), rough=0.08, glow=0.25) if LOOK == "frost" else None
if LOOK == "frost":  # a forked ice horn: two crystal prongs from one icy root
	horn_loft("horn", ck.bezier(base, base + Vector((0, -0.02, 0.12)), base + Vector((0, 0.02, 0.2)), n=4), 0.075, 0.06, 0.1, 0.08, ice)
	top = base + Vector((0, 0.02, 0.19))
	for s, lean in ((-1, 0.09), (1, 0.12)):
		horn_loft(f"prong{s}", ck.bezier(top, top + Vector((s * lean, 0.0, 0.14)), top + Vector((s * lean * 1.4, 0.06, 0.3)), n=5), 0.05, 0.008, 0.06, 0.01, ice, sides=5)
elif LOOK == "ember":  # a hammer horn: a thick stem with a heavy cross block on top
	horn_loft("horn", ck.bezier(base, base + Vector((0, -0.01, 0.14)), base + Vector((0, 0.03, 0.24)), n=4), 0.075, 0.06, 0.11, 0.09, slab_m[0])
	top = base + Vector((0, 0.03, 0.27))
	horn_loft("hammer", [top + Vector((0, -0.17, -0.01)), top + Vector((0, -0.06, 0.02)), top + Vector((0, 0.06, 0.02)), top + Vector((0, 0.16, 0.0))],
		0.075, 0.07, 0.09, 0.08, slab_m[1], sides=6)
elif LOOK == "spore":  # an antler of old mushroom wood, with little mushrooms on its tips
	wood = painted("antler", "mushwood", "a", (0.9, 0.82, 0.8), 0.0, tile=0.3)
	stem = ck.bezier(base, base + Vector((0, -0.04, 0.18)), base + Vector((0, 0.06, 0.34)), n=6)
	ck.limb("horn", stem, 0.06, 0.03, wood, sides=8)
	tips = [stem[-1]]
	for s, at in ((-1, 2), (1, 3)):
		b = ck.bezier(stem[at], stem[at] + Vector((s * 0.08, -0.02, 0.06)), stem[at] + Vector((s * 0.13, 0.0, 0.16)), n=4)
		ck.limb(f"branch{s}", b, 0.032, 0.018, wood, sides=7)
		tips.append(b[-1])
	kit.COLORS["mush_violet"] = (0.55, 0.16, 0.8)
	for i, tp in enumerate(tips):
		kit.mushroom(tuple(tp - Vector((0, 0, 0.01))), 0.62 + 0.15 * (i == 0), cap="mush_violet", seed=40 + i)
else:  # mossy: the picture's thick, flat-sided stone horn
	pts = ck.bezier(base, base + Vector((0, -0.05, 0.25)), base + Vector((0, 0.15, 0.36)), n=12)
	ck.loft("horn", [(p, 0.115 - 0.06 * i / 11, 0.16 - 0.08 * i / 11) for i, p in enumerate(pts)], slab_m[0], sides=7, subsurf=0, smooth=True, up=Vector((0, -1, 0)))


def tilt_to(d):
	return [math.degrees(v) for v in Vector((0, 0, 1)).rotation_difference(d.normalized()).to_euler()]


# ---------------------------------------------------------------- extras per look (on top of the same body)
up_slabs = [s for s in slabs if s[1].z > 0.5]
if LOOK == "mossy":
	moss = painted("moss", "stone", "c", (0.42, 0.62, 0.22), 0.0, tile=0.3, rough=0.95)
	for k, (p, n, sz, _) in enumerate(slabs):  # moss growing in the cracks: thin strips between neighbouring plates
		near = sorted((q for q in slabs if q[0] != p), key=lambda q: (q[0] - p).length)[:2]
		for j, (q, qn, qs, _) in enumerate(near):
			if xr.random() < 0.45 or (q - p).length > 0.32:
				continue
			mid = (p + q) / 2
			nn = (n + qn).normalized()
			along = (q - p).cross(nn).normalized()
			ck.loft(f"moss{k}{j}", [(mid - along * 0.07 + nn * 0.012, 0.012, 0.008), (mid + nn * 0.02, 0.022, 0.012), (mid + along * 0.07 + nn * 0.012, 0.012, 0.008)],
				moss, sides=6, subsurf=0, wobble=0.3, seed=k * 3 + j)
elif LOOK == "frost":
	snow = ck.color("snow", (0.88, 0.94, 1.0), rough=0.6)
	for k, (p, n, sz, th) in enumerate(up_slabs):  # snow lying on the upper plates (its bottom half sunk into the plate)
		cap = ck.blob((0, 0, 0), (sz * 1.05, sz * 0.95, 0.016), snow, seed=k, jitter=0.18, detail=2, subsurf=1)
		cap.matrix_world = Matrix.Translation(p + n * (th + 0.006)) @ frame(n, xr.uniform(0, math.tau)).to_4x4() @ Matrix.Rotation(0.12, 4, "X")
	for a_t in (-0.35, -0.05, 0.25):  # ice spikes along the ridge
		p, n = on_dome(a_t, math.pi / 2 + xr.uniform(-0.15, 0.15), 0.03)
		for c in range(3):
			d = Vector((xr.uniform(-0.25, 0.25), xr.uniform(-0.2, 0.2), 1))
			kit.crystal(tuple(p + Vector((xr.uniform(-0.04, 0.04), xr.uniform(-0.04, 0.04), -xr.uniform(0.02, 0.05)))), 0.025, xr.uniform(0.12, 0.2), ice, tilt=tilt_to(d))
	for s in (-1, 1):  # ice crystal clusters on the flanks, by the glowing back
		p, n = on_dome(0.3, math.pi / 2 - s * 1.35, 0.02)
		for c in range(4):
			d = n + Vector((xr.uniform(-0.35, 0.35), xr.uniform(-0.35, 0.35), xr.uniform(0, 0.3)))
			kit.crystal(tuple(p + d.normalized() * 0.03 * c - n * xr.uniform(0.02, 0.04)), 0.02, xr.uniform(0.07, 0.12), ice, tilt=tilt_to(d))
elif LOOK == "ember":
	amber = glow_mat("glow_crystal", (1.0, 0.55, 0.12), 0.8)
	for spot in ((-0.1, math.pi / 2 + 0.3), (0.2, math.pi / 2 - 0.25), (0.35, 0.3), (0.35, math.pi - 0.3), (-0.3, 0.45), (-0.3, math.pi - 0.45)):
		p, n = on_dome(spot[0], spot[1], 0.05)
		for c in range(5):
			d = n + Vector((xr.uniform(-0.4, 0.4), xr.uniform(-0.4, 0.4), xr.uniform(0, 0.3)))
			kit.crystal(tuple(p + d.normalized() * 0.035 * c - n * xr.uniform(0.03, 0.05)), 0.03, xr.uniform(0.1, 0.17), amber, tilt=tilt_to(d))
elif LOOK == "spore":
	kit.COLORS["mush_violet"] = (0.55, 0.16, 0.8)
	for k in range(4):  # little glowing mushrooms growing between the plates
		p, n, sz, _ = up_slabs[xr.randrange(len(up_slabs))]
		d = frame(n, xr.uniform(0, math.tau)) @ Vector((sz * 0.9, 0, 0))
		kit.mushroom(tuple(p + d + n * 0.01), xr.uniform(0.45, 0.65), cap="mush_violet", seed=k)
	spots = glow_mat("glow_spots", (0.95, 0.75, 1.0), 0.8)
	for o in bpy.context.scene.objects:  # the mushroom caps' spots glow softly
		if o.type == "MESH":
			for i, m in enumerate(o.data.materials):
				if m and m.name.startswith("spot"):
					o.data.materials[i] = spots


# ---------------------------------------------------------------- six legs, each its own part turning at the hip
def seg(name, a, b, r0, r1, material, sides=6):
	"""A chunky faceted leg segment from a to b, overlapping its neighbours a little at both ends."""
	d = (b - a)
	return ck.loft(name, [(a - d * 0.08, r0 * 0.9, r0 * 0.9), (a + d * 0.12, r0, r0), (a.lerp(b, 0.6), (r0 + r1) / 2 * 1.04, (r0 + r1) / 2),
		(b - d * 0.05, r1, r1), (b + d * 0.06, r1 * 0.8, r1 * 0.8)], material, sides=sides, subsurf=0, smooth=False, seed=len(name))


def leg(s, i, y, reach):
	hip = Vector((s * 0.22, y, 0.17))
	with ck.part(f"leg_{'l' if s < 0 else 'r'}{i}", hinge=tuple(hip)):
		knee = Vector((s * 0.46, y + reach * 0.55, 0.24))
		ankle = Vector((s * 0.56, y + reach, 0.08))
		seg("coxa", hip, hip.lerp(knee, 0.4), 0.09, 0.088, leg_dark)
		seg("femur", hip.lerp(knee, 0.4), knee, 0.09, 0.08, leg_m)
		seg("tibia", knee, knee.lerp(ankle, 0.55), 0.078, 0.066, leg_m)
		seg("tarsus", knee.lerp(ankle, 0.55), ankle, 0.066, 0.052, leg_m)
		fwd = Vector((s * 0.35, -1 if reach < 0 else 1, 0)).normalized() if abs(reach) > 0.05 else Vector((s, -0.3, 0)).normalized()
		side = Vector((0, 0, 1)).cross(fwd).normalized()
		for c, off in enumerate((-0.022, 0.022) if i == 1 else (-0.026, 0.0, 0.026)):
			root = ankle + side * off
			tip = root + fwd * 0.06 + Vector((0, 0, -0.075))
			claw = ck.bezier(root, root + fwd * 0.05 + Vector((0, 0, -0.01)), tip, n=5)
			ck.limb(f"claw{c}", claw, 0.02, 0.004, claw_m, sides=6, subsurf=0)


for s in (-1, 1):
	leg(s, 0, -0.26, -0.16)
	leg(s, 1, -0.02, 0.02)
	leg(s, 2, 0.24, 0.18)

ck.save(out, preview)
