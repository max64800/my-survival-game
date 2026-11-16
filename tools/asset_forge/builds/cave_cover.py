# Cave ground cover, batch 1 of docs/design/cave-life-plan.md (F188; owner: "I want moss to be fluffy, some grass here
# and there, small roots that stick out of the ground, so the caves don't look hollow"). Hand-built the cave-plants
# way (builds/cave_plants.py: melt pieces into one skin, carve, paint, bake); MODEL-RULES Rule 1: every shape comes
# from this script.
#
#   blender --background --factory-startup --python builds/cave_cover.py -- <out_dir> [only=moss,grass,...] [grey=1]
#
# Writes <out_dir>/<name>.glb and <out_dir>/<name>_a.png / _b.png (pictures). grey=1 skips the paint.
#
# The models (Blender: +Z up, origin on the ground or wall where it grows; the game turns +Z to the rock's normal):
#   moss        a moss cushion: soft pillows of different sizes melted together (the game draws its fuzz as ~10
#               stacked see-through layers, src/art/moss_shell.gdshader).
#   moss_drape  moss on a ledge spilling over its edge (the edge runs along X at y = 0, the drop is toward +Y):
#               pillows on top, ragged tongues hanging down the face.
#   grass       a tuft of pale cave grass: thin limp blades from a clump of soil, tips drooping (painted pale, the
#               game tints it whitish-yellow or blue-green and bends it away from dwarves).
#   rootlet     a small root poking out of the ground and curling over at the end, a smaller loop beside it, hair
#               roots, soil heaped where they come out.
#   rootlet_b   three thin roots out of one crack: one curled, one broken, one snaking along the ground.
#   lichen      a lichen crust for walls: lobes in rough rings, ruffled raised rims, little cups (painted pale, the
#               game tints it orange or teal).
#   fern        a small curly cave fern: fronds arching out of a hairy crown, curling at the tips, leaflets with
#               lobed edges, two young fronds still rolled up (painted green, the game tints it a little).
#
# Parts: anything the game tints per plant starts with tint_ (multiplied by the plant's colour).
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Quaternion, Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_plants as cp  # noqa: E402  (its helpers: tube, smooth_path, lump, carve, join, finish, pictures, export)
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

Z = Vector((0, 0, 1))


def fix_xf(o):
	"""Bake the object's position/turn into its points (melt keeps the first piece's position), so v.co = world."""
	cs._select_only(o)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	return o


def cut_below(o, z):
	"""Remove everything under height z (the part hidden in the ground), leaving the bottom open."""
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, z), plane_no=(0, 0, 1), clear_inner=True)
	bm.to_mesh(o.data)
	bm.free()
	return o


def ribbon(name, pts, widths, side_dir, twist=0.0, fold=0.0, grad=None):
	"""A thin strip along pts (a grass blade, a leaflet): widths = half-widths per point, side_dir = which way it is
	wide, twist (radians) turns it along its length, fold lifts its edges into a shallow V. Stores 'grad' (0 at the
	base, 1 at the tip) for the paint."""
	bm = bmesh.new()
	g = bm.verts.layers.float.new("grad")
	n = len(pts)
	rows = []
	for i, p in enumerate(pts):
		u = i / (n - 1)
		t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
		side = (side_dir - t * side_dir.dot(t)).normalized()
		if twist:
			side.rotate(Quaternion(t, twist * u))
		up = side.cross(t)
		w = max(widths[i], 0.0004)
		row = [bm.verts.new(p - side * w + up * w * fold), bm.verts.new(p), bm.verts.new(p + side * w + up * w * fold)] if fold else \
			[bm.verts.new(p - side * w), bm.verts.new(p + side * w)]
		for v in row:
			v[g] = u if grad is None else grad[i]
		rows.append(row)
	for i in range(n - 1):
		a, b = rows[i], rows[i + 1]
		for k in range(len(a) - 1):
			bm.faces.new((a[k], a[k + 1], b[k + 1], b[k]))
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(cp.grey())
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def self_bake(o, paint, tex, name):
	"""Bake a part's paint straight onto its own UV map (thin parts, already light: a blade or leaflet has no dense
	sculpt to bake from, and a bake from a copy would pick up the blade next to it). Gives it a double-sided game
	material with the painted colour."""
	cs.uv_only(o)
	scene = bpy.context.scene
	scene.render.engine = "CYCLES"
	scene.cycles.samples = 24
	scene.cycles.device = "CPU"
	img = bpy.data.images.new(f"{name}_col", tex, tex)
	nt = paint.node_tree
	node = nt.nodes.new("ShaderNodeTexImage")
	node.image = img
	nt.nodes.active = node
	o.data.materials.clear()
	o.data.materials.append(paint)
	cs._select_only(o)
	bpy.ops.object.bake(type="EMIT", margin=4)
	img.pack()
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = 0.9
	b.inputs["Specular IOR Level"].default_value = 0.15
	t = m.node_tree.nodes.new("ShaderNodeTexImage")
	t.image = img
	m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
	m.use_backface_culling = False
	o.data.materials.clear()
	o.data.materials.append(m)
	return o


def finish(model, parts):
	"""Like cave_plants.finish, plus tris = "self" for thin parts painted straight onto themselves."""
	lows = []
	for part in parts:
		high, tris, tex, paint = part
		if tris != "self":
			lows += cp.finish(model, [part])
			continue
		pname = high.name
		if not cp.GREY:
			self_bake(high, paint(f"{pname}_{model}_paint"), tex, f"{pname}_{model}")
		high.name = pname
		lows.append(high)
	return lows


# ---------------------------------------------------------------- moss
MOSS = ((0.36, 0.46, 0.17), (0.12, 0.19, 0.06), (0.64, 0.74, 0.33))


def moss_paint(n, seed):
	return cs.paint_material(n, *MOSS, moss=(0.55, 0.52, 0.22), moss_amount=0.2, strokes=0.2, top_light=0.35, edge=0.25, grime=0.25, seed=seed)


def moss_skin(s):
	"""Moss grows in tiny tight clumps: a fine bumpy surface (the fuzz on top is drawn by the game)."""
	return 0.004 * noise.fractal(s * 30, 0.6, 2.2, 3) + 0.003 * (1 - abs(noise.noise(s * 70))) - 0.004 * max(0.0, noise.noise(s * 9) - 0.35)


def build_moss(seed=61):
	r = random.Random(seed)
	pads = [cp.lump("pad0", (0, 0, 0), (0.22, 0.19, 0.13), seed, jitter=0.2, detail=3)]
	for k in range(5):  # pillows round the big one, different sizes, overlapping (no perfect circle)
		a = k * 2 * math.pi / 5 + r.uniform(-0.4, 0.4)
		d = r.uniform(0.17, 0.3)
		w = r.uniform(0.09, 0.16)
		pads.append(cp.lump(f"pad{k + 1}", (math.cos(a) * d, math.sin(a) * d * 0.85, 0), (w, w * r.uniform(0.75, 1.0), w * r.uniform(0.65, 0.85)), seed + 1 + k, jitter=0.22, detail=3))
	for k in range(4):  # little tufts a bit apart, joined on by thin moss
		a = r.uniform(0, 2 * math.pi)
		d = r.uniform(0.34, 0.42)
		w = r.uniform(0.035, 0.06)
		pads.append(cp.lump(f"tuft{k}", (math.cos(a) * d, math.sin(a) * d * 0.85, 0), (w, w, w * 0.7), seed + 10 + k, jitter=0.25, detail=2))
		pads.append(cp.lump(f"link{k}", (math.cos(a) * d * 0.75, math.sin(a) * d * 0.64, -0.01), (w * 1.4, w * 1.1, 0.025), seed + 20 + k, jitter=0.2, detail=2))
	skin = fix_xf(cs.melt(pads, voxel=0.006, smooth=4, name="moss"))
	cp.carve(skin, lambda p, n: moss_skin(p), soften=1)
	cut_below(skin, -0.012)
	return [(skin, 560, 512, lambda n: moss_paint(n, 14.0))]


def build_moss_drape(seed=62):
	"""The ledge edge runs along X at y = 0, the rock top is y < 0 (z = 0), the face drops down at y = 0 toward -Z."""
	r = random.Random(seed)
	pads = []
	for k in range(4):  # pillows on the ledge top, the front ones bulging over the edge
		x = -0.3 + k * 0.2 + r.uniform(-0.04, 0.04)
		w = r.uniform(0.11, 0.16)
		pads.append(cp.lump(f"top{k}", (x, -w * 0.55, 0.0), (w, w * 0.9, w * 0.5), seed + k, jitter=0.2, detail=3))
		pads.append(cp.lump(f"lip{k}", (x + r.uniform(-0.05, 0.05), 0.0, -0.01), (w * 0.85, 0.05, 0.06), seed + 10 + k, jitter=0.2, detail=2))
	for k in range(9):  # ragged tongues hanging down the face, different lengths, side by side into one curtain
		x = -0.36 + k * 0.09 + r.uniform(-0.02, 0.02)
		ln = r.uniform(0.1, 0.38)
		steps = max(2, int(ln / 0.05))
		for j in range(steps):
			f = j / steps
			w = 0.075 * (1 - 0.5 * f) + 0.015
			pads.append(cp.lump(f"tongue{k}_{j}", (x + 0.015 * math.sin(j * 1.3 + k), 0.032, -0.03 - j * 0.05), (w, 0.034, 0.045), seed + 30 + 10 * k + j, jitter=0.2, detail=2))
	skin = fix_xf(cs.melt(pads, voxel=0.006, smooth=4, name="moss"))
	cp.carve(skin, lambda p, n: moss_skin(p), soften=1)
	bm = bmesh.new()  # the part hidden in the rock under the ledge top (the curtain stays closed: an open one bakes stripy)
	bm.from_mesh(skin.data)
	gone = [v for v in bm.verts if v.co.y < -0.004 and v.co.z < -0.012]
	bmesh.ops.delete(bm, geom=gone, context="VERTS")
	bm.to_mesh(skin.data)
	bm.free()
	return [(skin, 640, 512, lambda n: moss_paint(n, 15.0))]


# ---------------------------------------------------------------- pale cave grass
def build_grass(seed=51):
	r = random.Random(seed)
	blades = []
	for k in range(32):
		a = r.uniform(0, 2 * math.pi)
		o = Vector((math.cos(a), math.sin(a), 0))
		base = o * r.uniform(0.0, 0.045) + Vector((0, 0, -0.012))
		L = r.uniform(0.15, 0.3)
		lean = r.uniform(0.2, 0.75)  # 0 = straight up, 1 = far out
		droop = r.uniform(0.25, 0.7)  # limp tips (no sun to grow toward)
		ctrl = [base, base + Z * L * 0.35 + o * L * lean * 0.12, base + Z * L * 0.62 + o * L * lean * 0.45,
			base + Z * L * (0.72 - droop * 0.22) + o * L * (lean * 0.8 + 0.12), base + Z * L * (0.62 - droop * 0.45) + o * L * (lean + 0.22)]
		path = cp.smooth_path(ctrl, 8)
		wid = [0.0048 * (1 - (i / 7) ** 1.7) + 0.0005 for i in range(8)]
		blades.append(ribbon(f"blade{k}", path, wid, o.cross(Z), twist=r.uniform(-0.9, 0.9), fold=0.35))
	clump = [cp.lump("clump", (0, 0, -0.018), (0.065, 0.055, 0.03), seed, jitter=0.25, detail=3)]
	for k in range(4):
		a = k * 1.7
		clump.append(cp.lump(f"clod{k}", (math.cos(a) * 0.06, math.sin(a) * 0.05, -0.012), (0.025, 0.02, 0.016), seed + 1 + k, jitter=0.3, detail=2))
	soil = fix_xf(cs.melt(clump, voxel=0.004, smooth=3, name="soil"))
	cp.carve(soil, lambda p, n: 0.003 * noise.fractal(p * 40, 0.6, 2.2, 3))
	cut_below(soil, -0.02)
	gl = cp.join(blades, "tint_blades")
	return [
		(soil, 160, 256, lambda n: cs.paint_material(n, (0.34, 0.26, 0.19), (0.14, 0.1, 0.07), (0.5, 0.41, 0.3), grime=0.3, seed=16.0)),
		(gl, "self", 256, lambda n: cs.paint_material(n, (0.9, 0.88, 0.72), (0.6, 0.58, 0.44), (1.0, 0.99, 0.9), root=(0.42, 0.36, 0.22), strokes=0.14, edge=0.15,
			top_light=0.1, grime=0.12, ao_samples=8, seed=17.0)),
	]


# ---------------------------------------------------------------- small roots poking out
def hook_path(base, out, height, curl, seed):
	"""A root rising out of the ground at base, leaning toward `out`, then curling over and rolling in at the end."""
	r = random.Random(seed)
	side = out.cross(Z).normalized()
	pts = [base - Z * 0.08, base + Z * height * 0.4 + out * height * 0.05, base + Z * height * 0.85 + out * height * 0.25]
	c = base + Z * height * 0.78 + out * height * 0.55  # middle of the curl
	for k in range(7):  # over the top and rolling inward, the circle getting smaller
		a = math.pi * 0.62 - k * 0.62
		rr = curl * (1 - 0.1 * k)
		pts.append(c + (out * math.cos(a) + Z * math.sin(a)) * rr + side * r.uniform(-0.012, 0.012))
	return cp.smooth_path(pts, 26)


def hairs(path, count, seed, length=(0.03, 0.06), name="hair"):
	"""Hair roots growing from a root, pointing out and down, wavy."""
	r = random.Random(seed)
	out = []
	for k in range(count):
		i = int(len(path) * r.uniform(0.12, 0.7))
		p = path[i]
		t = (path[min(i + 1, len(path) - 1)] - path[i - 1]).normalized()
		a = r.uniform(0, 2 * math.pi)
		side = t.cross(Z if abs(t.z) < 0.9 else Vector((1, 0, 0))).normalized()
		o = (side * math.cos(a) + t.cross(side) * math.sin(a) - Z * 0.5).normalized()
		ln = r.uniform(*length)
		ctrl = [p, p + o * ln * 0.5 + t * 0.006, p + o * ln - Z * ln * 0.25]
		out.append(cp.tube(f"{name}{k}", cp.smooth_path(ctrl, 5), [0.0026 - 0.0004 * j for j in range(5)], sides=4, wobble=0.1, seed=seed + k))
	return out


def soil_heaps(ends, seed, size=0.065):
	"""Soil heaped where roots come out of the ground, a few clods and pebbles round it."""
	r = random.Random(seed)
	soil, pebbles = [], []
	for k, e in enumerate(ends):
		c = Vector((e.x, e.y, -0.022))
		soil.append(cp.lump(f"heap{k}", tuple(c), (size, size * 0.85, 0.05), seed + k, jitter=0.22, detail=3))
		for j in range(3):
			a = r.uniform(0, 2 * math.pi)
			soil.append(cp.lump(f"clod{k}{j}", tuple(c + Vector((math.cos(a), math.sin(a), 0.02)) * size * 0.95), (0.022, 0.019, 0.016), seed + 10 + 3 * k + j, jitter=0.3, detail=2))
		a = r.uniform(0, 2 * math.pi)
		pebbles.append(cp.lump(f"pebble{k}", tuple(c + Vector((math.cos(a) * size * 1.25, math.sin(a) * size * 1.25, 0.035))), (0.018, 0.015, 0.012), seed + 30 + k, jitter=0.12, detail=2))
	return soil, pebbles


def build_rootlet(seed=71, variant="a"):
	r = random.Random(seed)
	roots, fine, ends = [], [], []
	if variant == "a":
		p = hook_path(Vector((0, 0, 0)), Vector((1, 0.15, 0)).normalized(), 0.26, 0.06, seed)
		roots.append(cp.tube("main", p, [0.032 * (1 - 0.82 * i / 25) + 0.004 for i in range(26)], sides=9, wobble=0.06, seed=seed))
		ends.append(p[0])
		fine += hairs(p, 10, seed + 50)
		loop = cp.arch_path((-0.2, 0.06, -0.06), (-0.07, 0.13, -0.06), 0.08, n=14, seed=seed)  # a small loop beside it
		roots.append(cp.tube("loop", loop, [0.016] * 14, sides=8, wobble=0.06, seed=seed + 1))
		ends += [loop[0], loop[-1]]
	else:
		p1 = hook_path(Vector((0.03, 0, 0)), Vector((-0.2, 1, 0)).normalized(), 0.17, 0.04, seed)
		roots.append(cp.tube("curl", p1, [0.022 * (1 - 0.8 * i / 25) + 0.003 for i in range(26)], sides=8, wobble=0.06, seed=seed))
		p2 = cp.smooth_path([(-0.02, -0.03, -0.08), (-0.03, -0.035, 0.08), (-0.01, -0.03, 0.17)], 12)  # broken off, splintered top
		roots.append(cp.tube("broken", p2, [0.024 - 0.004 * i / 11 for i in range(12)], sides=8, wobble=0.06, seed=seed + 1))
		for j in range(5):
			a = j * 2 * math.pi / 5 + r.uniform(-0.3, 0.3)
			o = Vector((math.cos(a), math.sin(a), 0))
			base = p2[-1] + o * 0.012 - Z * 0.012
			roots.append(cp.tube(f"splinter{j}", [base, base + Z * 0.02 + o * 0.003, base + Z * r.uniform(0.03, 0.05)], [0.007, 0.005, 0.0015], sides=5, wobble=0.15, seed=seed + 10 + j))
		p3 = cp.smooth_path([(0.0, 0.02, -0.04), (0.08, 0.05, 0.03), (0.17, 0.0, 0.02), (0.25, 0.06, 0.03), (0.32, 0.03, -0.04)], 20)  # snaking along the ground
		roots.append(cp.tube("snake", p3, [0.017 * (1 - 0.4 * i / 19) for i in range(20)], sides=8, wobble=0.06, seed=seed + 2))
		ends += [p1[0], p3[-1]]
		fine += hairs(p1, 6, seed + 50) + hairs(p3, 6, seed + 60, length=(0.02, 0.04))
	bark = fix_xf(cs.melt(roots, voxel=0.0035, smooth=3, name="bark"))

	def bark_fn(p, n):  # cracked bark plates, knocked-off patches, fine grain (like the big roots)
		plates = -0.0025 * (1 - abs(noise.noise(p * 60 + Vector((seed, 0, 0)))) ** 0.5)
		chipped = -0.002 if noise.noise(p * 14 + Vector((3, seed, 1))) > 0.42 else 0.0
		return plates + chipped + 0.0006 * noise.fractal(p * 180, 0.5, 2.0, 3)
	cp.carve(bark, bark_fn, soften=1)
	soil, pebbles = soil_heaps(ends, seed + 100)
	earth = fix_xf(cs.melt(soil, voxel=0.004, smooth=3, name="soil"))
	cp.carve(earth, lambda p, n: 0.004 * noise.fractal(p * 35, 0.6, 2.2, 3) - 0.003 * max(0.0, noise.noise(p * 16) - 0.3))
	cut_below(earth, -0.025)
	stones = cp.join(pebbles, "rock")
	cs.carve_stone(stones, seed=seed, grain=0.0008, crack=0.001, chips=0.003, soften=1)
	hr = cp.join(fine, "rootlets")
	B = ((0.4, 0.28, 0.18), (0.15, 0.1, 0.06), (0.64, 0.5, 0.35))
	return [
		(bark, 900, 512, lambda n: cs.paint_material(n, *B, moss=(0.36, 0.42, 0.2), moss_amount=0.2, strokes=0.15, edge=0.55, scratches=0.6, grime=0.35, seed=18.0)),
		(earth, 260, 256, lambda n: cs.paint_material(n, (0.34, 0.26, 0.19), (0.14, 0.1, 0.07), (0.52, 0.42, 0.31), moss=(0.33, 0.4, 0.18), moss_amount=0.15, grime=0.3, seed=19.0)),
		(stones, 120, 128, lambda n: cs.paint_material(n, (0.47, 0.45, 0.42), (0.2, 0.19, 0.18), (0.68, 0.65, 0.6), edge=0.5, grime=0.3, seed=20.0)),
		(hr, "self", 128, lambda n: cs.paint_material(n, (0.55, 0.43, 0.3), (0.3, 0.22, 0.14), (0.7, 0.58, 0.44), grime=0.2, ao_samples=8, seed=21.0)),
	]


# ---------------------------------------------------------------- lichen crust (walls)
def build_lichen(seed=81):
	r = random.Random(seed)
	lobes = []
	rings = [(0.0, 1, 0.045), (0.055, 6, 0.032), (0.105, 10, 0.036), (0.15, 15, 0.038)]
	for ring, (rad, count, size) in enumerate(rings):
		for k in range(count):
			a = 2 * math.pi * k / count + r.uniform(-0.2, 0.2) + ring * 0.4
			d = rad * r.uniform(0.85, 1.15) * (1 + 0.22 * math.sin(3 * a + seed))  # lopsided, never a circle
			o = cp.lump(f"lobe{ring}_{k}", (math.cos(a) * d, math.sin(a) * d * 0.85, -0.006), (size * r.uniform(1.25, 1.6), size * r.uniform(0.95, 1.2), 0.014 + 0.002 * ring),
				seed + 10 * ring + k, jitter=0.25, detail=2)
			o.rotation_euler.z = a
			lobes.append(o)
	lobes.append(cp.lump("bed", (0, 0, -0.008), (0.15, 0.13, 0.012), seed + 99, jitter=0.15, detail=3))
	cups = []
	for k in range(9):  # little cups (where the lichen makes its spores), on the older middle part
		a, d = r.uniform(0, 2 * math.pi), r.uniform(0.0, 0.1)
		p = Vector((math.cos(a) * d, math.sin(a) * d * 0.85, 0.008))
		w = r.uniform(0.007, 0.013)
		cups.append(ck.loft(f"cup{k}", [(p - Z * 0.004, w * 0.55, w * 0.55), (p + Z * 0.004, w * 0.9, w * 0.9), (p + Z * 0.008, w * 1.05, w * 1.05),
			(p + Z * 0.0075, w * 0.75, w * 0.75), (p + Z * 0.004, w * 0.5, w * 0.5)], cp.grey(), sides=10, subsurf=0, seed=seed + 50 + k))
	crust = fix_xf(cs.melt(lobes + cups, voxel=0.0025, smooth=2, name="tint_crust"))
	reach = max(rings[-1][0] * 1.25, 0.01)

	def crust_fn(p, n):  # ruffled raised rims round the outside, wrinkles, crumbly grain
		edge = min(1.0, Vector((p.x, p.y / 0.85, 0)).length / reach)
		ruffle = 0.004 * max(0.0, edge - 0.55) / 0.45 * (0.6 + 0.4 * math.sin(math.atan2(p.y, p.x) * 23 + seed))
		wrinkle = -0.0015 * abs(noise.noise(p * 90))
		return ruffle + wrinkle + 0.0006 * noise.fractal(p * 260, 0.5, 2.0, 2)
	cp.carve(crust, crust_fn, soften=0)
	cut_below(crust, -0.003)
	return [(crust, 700, 512, lambda n: cs.paint_material(n, (0.86, 0.83, 0.75), (0.46, 0.43, 0.38), (1.0, 0.99, 0.94), strokes=0.16, edge=0.5, grime=0.4,
		scratches=0.3, top_light=0.1, seed=22.0))]


# ---------------------------------------------------------------- small curly fern
def build_fern(seed=91):
	r = random.Random(seed)
	parts = []
	for k in range(7):
		a = k * 2 * math.pi / 7 + r.uniform(-0.25, 0.25)
		o = Vector((math.cos(a), math.sin(a), 0))
		L = r.uniform(0.28, 0.4)
		rise = r.uniform(0.6, 0.9)
		ctrl = [o * 0.008, o * L * 0.12 + Z * L * 0.42 * rise, o * L * 0.42 + Z * L * 0.62 * rise, o * L * 0.75 + Z * L * 0.48 * rise,
			o * L * 0.95 + Z * L * 0.22 * rise, o * L * 0.93 + Z * L * 0.1 * rise, o * L * 0.85 + Z * L * 0.14 * rise]  # the tip rolls under: curly
		path = cp.smooth_path(ctrl, 14)
		parts.append(cp.tube(f"stalk{k}", path, [0.0042 - 0.0028 * i / 13 for i in range(14)], sides=4, wobble=0.05, seed=seed + k))
		side = o.cross(Z).normalized()
		pairs = 9
		for j in range(pairs):
			u = 0.2 + 0.68 * j / (pairs - 1)
			i = int(u * 13)
			p, t = path[i], (path[min(i + 1, 13)] - path[i - 1]).normalized()
			plen = L * 0.2 * math.sin(math.pi * min(1.0, (u - 0.08) / 0.92)) ** 0.7 + 0.008
			for s in (-1, 1):
				sd = (side * s - t * (side * s).dot(t)).normalized()
				d = (sd * 0.85 + t * 0.4 - Z * 0.12).normalized()  # leaflets sweep forward and droop a little
				lp = cp.smooth_path([p, p + d * plen * 0.55 + Z * plen * 0.06, p + d * plen - Z * plen * 0.12], 6)
				w = [plen * 0.2 * math.sin(math.pi * (0.12 + 0.88 * q / 5)) ** 0.6 * (1 + 0.22 * math.sin(q * 3.1 + j)) for q in range(6)]  # lobed edge
				parts.append(ribbon(f"leaf{k}_{j}_{s}", lp, w, t, twist=0.25 * s, grad=[0.25 + 0.75 * q / 5 for q in range(6)]))
	for k in range(2):  # young fronds still rolled up (fiddleheads)
		a = r.uniform(0, 2 * math.pi)
		o = Vector((math.cos(a), math.sin(a), 0))
		h = r.uniform(0.15, 0.2)
		pts = [o * 0.01, o * 0.02 + Z * h * 0.6, o * 0.03 + Z * h]
		c = o * 0.05 + Z * h
		for q in range(9):
			ang = math.pi - q * 0.75
			rr = 0.028 * (1 - 0.09 * q)
			pts.append(c + (o * math.cos(ang) + Z * math.sin(ang)) * rr)
		parts.append(cp.tube(f"fiddle{k}", cp.smooth_path(pts, 18), [0.0055 - 0.0025 * q / 17 for q in range(18)], sides=6, wobble=0.04, seed=seed + 40 + k))
	crown = [cp.lump("crown", (0, 0, -0.005), (0.04, 0.036, 0.025), seed, jitter=0.25, detail=3)]
	for k in range(5):
		a = k * 1.3
		crown.append(cp.lump(f"scale{k}", (math.cos(a) * 0.03, math.sin(a) * 0.03, 0.005), (0.014, 0.01, 0.018), seed + 60 + k, jitter=0.3, detail=2))
	base = fix_xf(cs.melt(crown, voxel=0.003, smooth=2, name="crown"))
	cp.carve(base, lambda p, n: 0.002 * noise.fractal(p * 60, 0.6, 2.2, 3))
	cut_below(base, -0.015)
	fronds = cp.join(parts, "tint_fronds")
	return [
		(base, 200, 256, lambda n: cs.paint_material(n, (0.4, 0.27, 0.16), (0.16, 0.1, 0.06), (0.58, 0.42, 0.28), grime=0.3, seed=23.0)),
		(fronds, "self", 512, lambda n: cs.paint_material(n, (0.46, 0.64, 0.3), (0.2, 0.32, 0.12), (0.72, 0.86, 0.46), root=(0.24, 0.36, 0.14), strokes=0.16, edge=0.2,
			top_light=0.15, grime=0.1, ao_samples=8, seed=24.0)),
	]


TINTS = {"grass": (0.95, 0.93, 0.8), "lichen": (0.95, 0.55, 0.2), "fern": (0.9, 1.0, 0.92)}  # how the pictures tint tint_ parts (the game picks per plant)
BUILDS = {"moss": build_moss, "moss_drape": build_moss_drape, "grass": build_grass, "rootlet": build_rootlet, "rootlet_b": lambda: build_rootlet(72, "b"),
	"lichen": build_lichen, "fern": build_fern}


def tint_for_pictures(name, objs):
	for o in objs:
		for m in o.data.materials:
			if not (m and m.name.startswith("tint_") and name in TINTS and m.use_nodes):
				continue
			nt = m.node_tree
			b = nt.nodes["Principled BSDF"]
			if not b.inputs["Base Color"].links:
				continue
			tex = b.inputs["Base Color"].links[0].from_node
			mul = nt.nodes.new("ShaderNodeMix")
			mul.data_type, mul.blend_type = "RGBA", "MULTIPLY"
			mul.inputs[0].default_value = 1.0
			mul.inputs[7].default_value = (*cs.lin(TINTS[name]), 1)
			nt.links.new(tex.outputs["Color"], mul.inputs[6])
			nt.links.new(mul.outputs[2], b.inputs["Base Color"])


if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = finish(name, fn())
		cp.export(name, objs)
		tint_for_pictures(name, objs)
		cp.pictures(name, objs)
