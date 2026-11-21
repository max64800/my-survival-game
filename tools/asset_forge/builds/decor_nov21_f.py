# Decor batch F (Nov 21): kitchen, lights, workshop and plant decorations, hand-built in the night_decor style.
#   blender --background --factory-startup --python builds/decor_nov21_f.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces (shelves, racks, tool wall, lantern hook) have a flat back at +Y so they sit flush on a wall.
# Hanging pieces (crystal_hanging_light, fern_basket) have a ceiling plate on top.
# Owner fix round (Nov 21): blueprint_table drawn tower plan, candle flames in fire colours, both crystal lights
# with hollow cups (crystals inside), fern_basket + glowcap_pot use the game's own fern/glowcap/tinycaps models,
# geode_stand real split geode, glowworm_jar corked lid, kitchen_block + mushroom_lamp more detail, pantry_crates
# straight empty planting crates, parts_bin toothed gears and bolts (no ash). Deleted by the owner: moss_bowl.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, cband, disc, kit, log, mesh, plank, rivet, rng, stone  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import CU, IRON, WOOD, lantern_body, legs4, plank_top, rope_tie  # noqa: E402

GLOW_BLUE = lambda: C((0.3, 0.7, 1.0), 0.15, glow=1.0)  # noqa: E731
GLOW_AMBER = lambda: C((0.95, 0.55, 0.2), 0.3, glow=0.8)  # noqa: E731
GLOW_TEAL = lambda: C((0.25, 0.8, 0.65), 0.35, glow=0.7)  # noqa: E731
WAX = lambda: C((0.93, 0.86, 0.66), 0.85)  # noqa: E731
STEM = lambda: C((0.86, 0.8, 0.68), 0.7)  # noqa: E731
FLAME = lambda: C((1.0, 0.7, 0.3), 0.3, glow=2.0)  # noqa: E731  (old pale flame, used by decor_nov21_lw)
PAPER = lambda: C((0.86, 0.78, 0.6), 0.95)  # noqa: E731


# ================= helpers =================
def place_glb(name, at, size, rotz=0.0, drop=(), height=False):
	"""Put one of the game's own models (assets/models/<name>.glb) in this model: its widest side (or its height,
	height=True) scaled to `size`, bottom-centre at `at`, turned rotz degrees. Parts whose name contains a word in
	`drop` are left out. Returns the new mesh objects."""
	before = set(bpy.data.objects[:])
	imgs = set(bpy.data.images[:])
	bpy.ops.import_scene.gltf(filepath=str(GAME / "assets" / "models" / f"{name}.glb"))
	bpy.context.view_layer.update()
	for img in [i for i in bpy.data.images if i not in imgs]:  # the same picture imported again: share the first copy (smaller file)
		base, _, n = img.name.rpartition(".")
		old = bpy.data.images.get(base) if n.isdigit() else None
		if old in imgs and tuple(old.size) == tuple(img.size):
			img.user_remap(old)
			bpy.data.images.remove(img)
	new = [o for o in bpy.data.objects if o not in before]
	meshes = [o for o in new if o.type == "MESH" and not any(d in o.name.lower() for d in drop)]
	for o in meshes:
		mw = o.matrix_world.copy()
		o.parent = None
		o.matrix_world = mw
	for o in new:
		if o not in meshes:
			bpy.data.objects.remove(o, do_unlink=True)
	pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
	lo = Vector([min(p[i] for p in pts) for i in range(3)])
	hi = Vector([max(p[i] for p in pts) for i in range(3)])
	s = size / ((hi.z - lo.z) if height else max(hi.x - lo.x, hi.y - lo.y))
	M = (Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(rotz), 4, "Z") @ Matrix.Scale(s, 4)
		@ Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))))
	for o in meshes:
		o.matrix_world = M @ o.matrix_world
	return meshes

def tint(meshes, key, rgb, glow=0.0):
	"""Paint the game's pale tint_* parts the way the game tints them (texture x colour, optional glow)."""
	for o in meshes:
		for sl in o.material_slots:
			if not sl.material or key not in sl.material.name:
				continue
			m = sl.material.copy()
			sl.material = m
			nt, b = m.node_tree, m.node_tree.nodes["Principled BSDF"]
			src = b.inputs["Base Color"].links[0].from_node.outputs["Color"] if b.inputs["Base Color"].links else None
			if src is None:
				b.inputs["Base Color"].default_value = (*rgb, 1)
				continue
			mix = nt.nodes.new("ShaderNodeMix")
			mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
			mix.inputs["Factor"].default_value = 1.0
			nt.links.new(src, mix.inputs[6])
			mix.inputs[7].default_value = (*rgb, 1)
			nt.links.new(mix.outputs[2], b.inputs["Base Color"])
			if glow:
				nt.links.new(mix.outputs[2], b.inputs["Emission Color"])
				b.inputs["Emission Strength"].default_value = glow


def glass(rgb=(0.7, 0.85, 0.9), alpha=0.3, glow=0.0):
	"""See-through glass or water (so what is inside shows)."""
	m = bpy.data.materials.new("glass")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*rgb, 1)
	b.inputs["Roughness"].default_value = 0.1
	b.inputs["Alpha"].default_value = alpha
	if glow:
		b.inputs["Emission Color"].default_value = (*rgb, 1)
		b.inputs["Emission Strength"].default_value = glow
	if hasattr(m, "surface_render_method"):
		m.surface_render_method = "BLENDED"
	if hasattr(m, "blend_method"):
		m.blend_method = "BLEND"
	return m

def aim(loc, d, r, h, m):
	"""A crystal standing on loc and pointing along direction d."""
	o = kit.crystal(loc, r, h, m)
	o.rotation_euler = Vector(d).to_track_quat("Z", "Y").to_euler()
	return o

def geode_half(R, Ri, m_shell, seed):
	"""Half a geode, cut face on y = 0 facing -Y: rough rock shell, agate bands on the cut face, a crystal-lined hollow."""
	import random
	r = random.Random(seed)
	nt, nph = 20, 6
	noise = [[1 + r.uniform(-0.08, 0.08) for _ in range(nt)] for _ in range(nph + 1)]
	cav = [1 + r.uniform(-0.12, 0.08) for _ in range(nt)]

	def d(t, ph):  # direction: ph = 0 points to +Y (the back), ph = 90 lies on the cut face
		th, p = 2 * math.pi * t / nt, math.radians(ph)
		return Vector((math.cos(th) * math.sin(p), math.cos(p), math.sin(th) * math.sin(p)))
	phs = [90 * j / nph for j in range(nph + 1)]
	# outer shell
	v = [tuple(d(0, 0) * R)]
	for j in range(1, nph + 1):
		v += [tuple(d(i, phs[j]) * R * noise[j][i]) for i in range(nt)]
	f = [(0, 1 + (i + 1) % nt, 1 + i) for i in range(nt)]
	for j in range(1, nph):
		a, b = 1 + (j - 1) * nt, 1 + j * nt
		f += [(a + i, a + (i + 1) % nt, b + (i + 1) % nt, b + i) for i in range(nt)]
	kit.roughen(mesh(v, f, m_shell), 0.004, 1, seed=seed)
	# the cut face: rind, white quartz, blue-grey agate, lavender, then the hollow
	bands = [(1.0, 0.86, C((0.42, 0.36, 0.32), 0.7)), (0.86, 0.76, C((0.82, 0.8, 0.78), 0.4)), (0.76, 0.62, C((0.45, 0.5, 0.6), 0.4)),
		(0.62, 0.5, C((0.6, 0.5, 0.7), 0.35))]
	for (o, i_, m) in bands:
		vv, ff = [], []
		for i in range(nt):
			ro = Ri + (R * noise[nph][i] - Ri) * o if o < 1 else R * noise[nph][i]
			ri_ = Ri + (R * noise[nph][i] - Ri) * i_ if i_ > 0.5 else Ri * cav[i]
			vv += [tuple(d(i, 90) * ro), tuple(d(i, 90) * ri_)]
		for i in range(nt):
			j = (i + 1) % nt
			ff.append((2 * i, 2 * j, 2 * j + 1, 2 * i + 1))
		mesh(vv, ff, m)
	# the hollow: a bowl lined with crystals that point into it
	gm = C((0.45, 0.18, 0.62), 0.3, glow=0.25)
	v = [tuple(d(0, 0) * Ri * 0.8)]
	for j in range(1, nph + 1):
		v += [tuple(d(i, phs[j]) * Ri * cav[i] * (0.8 + 0.2 * j / nph)) for i in range(nt)]
	f = [(0, 1 + i, 1 + (i + 1) % nt) for i in range(nt)]
	for j in range(1, nph):
		a, b = 1 + (j - 1) * nt, 1 + j * nt
		f += [(a + i, b + i, b + (i + 1) % nt, a + (i + 1) % nt) for i in range(nt)]
	mesh(v, f, C((0.22, 0.08, 0.3), 0.4))
	for k in range(48):
		t, ph = r.uniform(0, nt), r.uniform(8, 70)
		dd = d(t, ph)
		base = dd * Ri * cav[int(t) % nt] * (0.8 + 0.2 * ph / 90) * 1.02
		into = (-dd + Vector((0, -0.3, 0)) + Vector((r.uniform(-0.3, 0.3), 0, r.uniform(-0.3, 0.3)))).normalized()
		aim(tuple(base), into, 0.008 + 0.006 * r.random(), 0.025 + 0.02 * r.random() * (1 - ph / 100), gm)

def lathe(prof, loc, m, seg=18):
	"""A turned shape (hollow bowl, cup): profile [(r, z), ...] spun around the z axis at loc = (x, y)."""
	x0, y0 = loc
	v, rows = [], []
	for r, z in prof:
		if r == 0:
			rows.append([len(v)])
			v.append((x0, y0, z))
		else:
			rows.append(list(range(len(v), len(v) + seg)))
			v += [(x0 + math.cos(2 * math.pi * k / seg) * r, y0 + math.sin(2 * math.pi * k / seg) * r, z) for k in range(seg)]
	f = []
	for a, b in zip(rows, rows[1:]):
		for k in range(seg):
			if len(a) == 1:
				f.append((a[0], b[(k + 1) % seg], b[k]))
			elif len(b) == 1:
				f.append((a[k], a[(k + 1) % seg], b[0]))
			else:
				f.append((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
	return mesh(v, f, m)


def group(build, at=(0, 0, 0), rot=(0, 0, 0)):
	"""Build parts around the origin, then turn them by rot (degrees) and move them to `at`."""
	before = set(bpy.data.objects[:])
	build()
	bpy.context.view_layer.update()
	M = Matrix.Translation(Vector(at)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
	for o in bpy.data.objects[:]:
		if o not in before:
			o.matrix_world = M @ o.matrix_world


def wall_board(w, h, d=0.05, z0=0.0):
	"""Vertical planks with a flat back at y = d (each plank its own painting)."""
	n = max(2, round(w / 0.25))
	for i in range(n):
		B((w / n - 0.008, d, h + J(0.02)), (-w / 2 + w / n * (i + 0.5), d / 2, z0 + h / 2), WOOD(), bevel=0.01)


def wall_shelf(w, z, depth=0.2, lip=True):
	"""A shelf plank on two brackets, back against the board front (y = 0). Returns the top height."""
	B((w, depth, 0.035), (0, -depth / 2, z), T("wood", "b"), bevel=0.01)
	for x in (-w / 2 + 0.08, w / 2 - 0.08):
		B((0.04, depth * 0.7, 0.09), (x, -depth * 0.35 - 0.002, z - 0.06), T("wood", "dark"), bevel=0.008)
		rivet((x, -depth * 0.7 + 0.01, z - 0.06), IRON())
	if lip:
		B((w - 0.04, 0.015, 0.03), (0, -depth + 0.012, z + 0.03), T("wood", "dark"), bevel=0.004)
	return z + 0.0175


def jar(x, y, z, r, h, m, lid=None):
	kit.cylinder(r, h, (x, y, z + h / 2 - 0.003), m, verts=10, bevel=0.008)
	kit.cylinder(r * 0.68, 0.03, (x, y, z + h + 0.01), lid or C((0.7, 0.55, 0.35), 0.9), verts=8, bevel=0.005)
	kit.ring(r * 0.72, 0.008, (x, y, z + h - 0.005), kit.tex_mat("rope"), seg=10)


def pouch(x, y, z, s, rgb):
	sphere((x, y, z + 0.05 * s), 0.055 * s, C(rgb, 0.95), scale=(1, 0.9, 1.05))
	kit.cone(0.03 * s, 0.02 * s, 0.04 * s, (x, y, z + 0.11 * s), C(rgb, 0.95), verts=8, bevel=0.003)
	kit.ring(0.024 * s, 0.007, (x, y, z + 0.1 * s), kit.tex_mat("rope"), seg=8)


def open_crate(w, d, h, loc):
	"""An open slatted crate: bottom, two slats per side, four corner posts."""
	x, y, z = loc
	B((w - 0.04, d - 0.04, 0.03), (x, y, z + 0.02), T("wood", "dark"), bevel=0.006)
	for s_ in (-1, 1):
		for k in range(2):
			zz = z + h * (0.27 + 0.48 * k)
			B((w, 0.025, h * 0.44), (x, y + s_ * (d / 2 - 0.0125), zz), WOOD(), bevel=0.008)
			B((0.025, d - 0.05, h * 0.44), (x + s_ * (w / 2 - 0.0125), y, zz), WOOD(), bevel=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.05, 0.05, h), (x + cx * (w / 2 - 0.015), y + cy * (d / 2 - 0.015), z + h / 2), T("wood", "dark"), bevel=0.008)


def veg_pile(xc, yc, z, w, d, seed):
	"""Root vegetables and mushrooms heaped on a surface at height z."""
	import random
	r = random.Random(seed)
	for k in range(15):
		px, py = xc + r.uniform(-w * 0.34, w * 0.34), yc + r.uniform(-d * 0.3, d * 0.3)
		kind = k % 4
		if kind == 0:  # carrot lying down, leaves at the thick end
			a, b = r.uniform(75, 95), r.uniform(0, 180)
			kit.cone(0.03, 0.005, 0.17, (px, py, z + 0.025), C((0.85, 0.42, 0.12), 0.7), rot=(a, 0, b), verts=8)
			ax = Vector((math.sin(math.radians(a)) * math.sin(math.radians(b)), -math.sin(math.radians(a)) * math.cos(math.radians(b)), math.cos(math.radians(a))))
			kit.gem(tuple(Vector((px, py, z + 0.025)) - ax * 0.09), (0.03, 0.03, 0.022), kit.mat("sprout"), seed=k)
		elif kind == 1:  # turnip
			sphere((px, py, z + 0.04), 0.048, C((0.6, 0.38, 0.52), 0.7), scale=(1, 1, 0.9))
			kit.cone(0.02, 0.0, 0.05, (px, py, z + 0.09), kit.mat("sprout"), verts=6)
		elif kind == 2:  # potato
			lump((px, py, z + 0.028), (0.05, 0.038, 0.032), C((0.6, 0.45, 0.28), 0.85), seed=k, rough=0.006)
		else:
			kit.mushroom((px, py, z - 0.005), 0.45, cap="mushroom_red" if k % 2 else "wood", seed=k)


def candle(x, y, z, r, h):
	kit.cylinder(r + 0.02, 0.015, (x, y, z + 0.007), CU(), verts=10, bevel=0.003)
	kit.cylinder(r, h, (x, y, z + 0.012 + h / 2), WAX(), verts=10, bevel=0.008)
	kit.gem((x + r * 0.85, y - r * 0.3, z + h * 0.75), (0.012, 0.012, 0.03), WAX(), seed=int(h * 100))
	B((0.006, 0.006, 0.025), (x, y, z + h + 0.02), kit.mat("charcoal"), bevel=0)
	# warm orange outer flame around a yellow core, the game's fire colours (owner Nov 21)
	kit.flame((x, y, z + h + 0.02), 0.018, 0.065, kit.glow("fire", 1.6), twist=h * 30)
	kit.flame((x, y, z + h + 0.024), 0.009, 0.04, kit.glow("fire_core", 2.0), twist=h * 30 + 1)


# ================= Kitchen =================
def spice_shelf():
	W = 0.8
	wall_board(W, 0.66)
	for i, z in enumerate((0.12, 0.42)):
		top = wall_shelf(W + 0.04, z)
		xs = (-0.3, -0.16, -0.02, 0.12, 0.27)
		for k, x in enumerate(xs):
			if (k + i) % 3 == 2:
				pouch(x, -0.09, top, 1.0 - 0.15 * i, [(0.62, 0.5, 0.33), (0.5, 0.42, 0.3), (0.55, 0.35, 0.22)][k % 3])
			else:
				h = 0.1 + 0.05 * ((k * 7 + i) % 3)
				jar(x, -0.09, top, 0.045 + 0.01 * (k % 2), h, kit.tex_mat("clay", "abc"[(k + i) % 3]))
	for x in (-0.3, 0.3):
		rivet((x, -0.002, 0.6), IRON())


def pantry_crates():
	"""Three straight, tidy planting crates filled with soil and nothing else (owner Nov 21: ready to plant in)."""
	def crate(x, w=0.56, d=0.42, h=0.3):
		B((w - 0.04, d - 0.04, 0.03), (x, 0, 0.025), T("wood", "dark"), bevel=0.006)
		bh = h - 0.04
		for s_ in (-1, 1):  # straight upright boards, small even gaps, held by a batten inside
			for k in range(4):
				bw = (w - 0.1) / 4
				B((bw - 0.008, 0.025, bh), (x - (w - 0.1) / 2 + bw * (k + 0.5), s_ * (d / 2 - 0.0125), 0.02 + bh / 2), WOOD(), bevel=0.006)
			for k in range(3):
				bw = (d - 0.1) / 3
				B((0.025, bw - 0.008, bh), (x + s_ * (w / 2 - 0.0125), -(d - 0.1) / 2 + bw * (k + 0.5), 0.02 + bh / 2), WOOD(), bevel=0.006)
			B((w - 0.1, 0.03, 0.05), (x, s_ * (d / 2 + 0.008), 0.08), T("wood", "dark"), bevel=0.006)  # outside battens
		for cx in (-1, 1):
			for cy in (-1, 1):
				B((0.05, 0.05, h), (x + cx * (w / 2 - 0.025), cy * (d / 2 - 0.025), h / 2), T("wood", "dark"), bevel=0.008)
				for z in (0.08, h - 0.06):
					rivet((x + cx * (w / 2 - 0.025), cy * (d / 2 + 0.001), z), IRON("dark"), r=0.009)
		B((w - 0.02, 0.03, 0.035), (x, -d / 2 + 0.005, h + 0.005), T("wood", "dark"), bevel=0.006)  # top rims
		B((w - 0.02, 0.03, 0.035), (x, d / 2 - 0.005, h + 0.005), T("wood", "dark"), bevel=0.006)
		B((0.03, d - 0.07, 0.035), (x - w / 2 + 0.005, 0, h + 0.005), T("wood", "dark"), bevel=0.006)
		B((0.03, d - 0.07, 0.035), (x + w / 2 - 0.005, 0, h + 0.005), T("wood", "dark"), bevel=0.006)
		B((w - 0.06, d - 0.06, h - 0.1), (x, 0, 0.04 + (h - 0.1) / 2), kit.tex_mat("soil", "a"), bevel=0.01)
		for k in range(3):  # raked rows in the soil
			B((w - 0.1, 0.035, 0.02), (x, -0.1 + k * 0.1, h - 0.06), kit.tex_mat("soil", "b"), bevel=0.008)
		B((0.12, 0.012, 0.06), (x, -d / 2 - 0.012, h * 0.55), T("wood", "c"), bevel=0.004)  # name tag
		for dx in (-0.045, 0.045):
			rivet((x + dx, -d / 2 - 0.019, h * 0.55), IRON(), r=0.007)
		for s_ in (-1, 1):  # rope handles on the ends
			kit.ring(0.045, 0.01, (x + s_ * (w / 2 + 0.003), 0, h * 0.62), kit.tex_mat("rope"), rot=(0, 90, 0), seg=10)
	for x in (-0.6, 0.0, 0.6):
		crate(x)


def pie(x, y, z, kind):
	kit.cone(0.12, 0.145, 0.04, (x, y, z + 0.02), kit.tex_mat("clay", "b"), verts=16, bevel=0.006)
	crust = C([(0.82, 0.58, 0.3), (0.75, 0.5, 0.25), (0.86, 0.64, 0.36)][kind], 0.8)
	if kind == 1:  # berry pie with a lattice
		disc(0.13, z + 0.03, z + 0.05, (x, y), C((0.5, 0.12, 0.15), 0.6), seg=16, wob=0.01)
		for k in range(4):
			B((0.24, 0.025, 0.014), (x, y - 0.075 + k * 0.05, z + 0.055), crust, bevel=0.004)
			B((0.025, 0.24, 0.014), (x - 0.075 + k * 0.05, y, z + 0.068), crust, bevel=0.004)
	else:
		sphere((x, y, z + 0.035), 0.132, crust, scale=(1, 1, 0.38), cut=0.0)
		for k in range(3):
			B((0.04, 0.01, 0.01), (x, y - 0.03 + k * 0.03, z + 0.083), C((0.45, 0.25, 0.12), 0.8), bevel=0, rot=(0, 0, 30))
	kit.ring(0.138, 0.016, (x, y, z + 0.045), crust, seg=20)


def pie_rack():
	W, D, H = 0.6, 0.36, 0.95
	for x in (-W / 2, W / 2):
		for y in (-D / 2 + 0.03, D / 2 - 0.03):
			B((0.05, 0.05, H), (x, y, H / 2), T("wood", "dark"), bevel=0.01)
	for i, z in enumerate((0.1, 0.43, 0.76)):
		for x in (-W / 2, W / 2):
			B((0.04, D - 0.04, 0.04), (x * 0.93, 0, z - 0.035), T("wood", "b"), bevel=0.006)
		for j in range(4):
			plank((W - 0.05, D / 4 - 0.008, 0.03), (0, -D / 2 + D / 4 * (j + 0.5), z))
		pie(0, -0.01, z + 0.015, i)
	B((W + 0.08, 0.04, 0.05), (0, D / 2 - 0.03, H - 0.02), T("wood", "b"), bevel=0.01)


def kitchen_block():
	"""Chopping block (owner Nov 21: more detail): banded log, axe-cut top, cleaver, knife strap, vegetables, ladle."""
	top = 0.75
	log((0, 0, 0.42), (0, 0, top - 0.01), 0.26, T("bark"), seg=12, rings=1, bend=0.02, end_m=kit.tex_mat("wood", "c"))
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		log((math.cos(a) * 0.14, math.sin(a) * 0.14, 0.46), (math.cos(a) * 0.26, math.sin(a) * 0.26, 0.0), 0.05, T("bark"), seg=7, rings=2)
		rivet((math.cos(a) * 0.15, math.sin(a) * 0.15, 0.44), IRON("dark"), r=0.014)
	kit.ring(0.27, 0.014, (0, 0, 0.5), IRON("dark"), seg=24)
	kit.ring(0.268, 0.014, (0, 0, top - 0.06), IRON("dark"), seg=24)
	for k in range(6):
		a = 2 * math.pi * k / 6
		rivet((math.cos(a) * 0.285, math.sin(a) * 0.285, 0.5), IRON(), r=0.009)
	cut = kit.mat("charcoal", 0.35)  # axe cuts sunk into the top (dark slits, not sticks on it)
	for k, (x, y, a) in enumerate(((-0.1, 0.05, 20), (0.0, -0.15, -35), (0.12, -0.05, 60), (-0.16, -0.08, -70))):
		B((0.12, 0.008, 0.02), (x, y, top - 0.006), cut, bevel=0, rot=(0, 0, a))
	# cleaver stuck in the block
	B((0.2, 0.012, 0.13), (0.06, 0.06, top + 0.05), IRON("a"), bevel=0.003, rot=(0, -10, 0))
	B((0.2, 0.016, 0.02), (0.07, 0.06, top + 0.115), IRON("dark"), bevel=0.003, rot=(0, -10, 0))
	log((0.15, 0.06, top + 0.09), (0.3, 0.06, top + 0.12), 0.02, T("wood", "dark"), seg=7, rings=1)
	rivet((0.21, 0.04, top + 0.105), CU("dark"))
	# leather strap on the side holding two knives
	kit.ring(0.27, 0.012, (0, 0, 0.62), kit.tex_mat("leather", "dark"), seg=24)
	for k, a in enumerate((-2.0, -1.7)):
		x, y = math.cos(a) * 0.29, math.sin(a) * 0.29
		B((0.02, 0.008, 0.16), (x, y, 0.56), IRON("a"), bevel=0.002, rot=(0, 0, math.degrees(a) + 90))
		kit.cylinder(0.016, 0.1, (x, y, 0.69), T("wood", "dark"), verts=8, bevel=0.004)
		kit.ring(0.017, 0.004, (x, y, 0.645), CU(), seg=8)
	# a hook with a ladle on the other side
	log((0.27, 0.0, 0.64), (0.31, 0.0, 0.66), 0.008, IRON(), seg=5, rings=1, ends=False, bend=0)
	log((0.31, 0.0, 0.66), (0.31, 0.0, 0.43), 0.01, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
	kit.ring(0.012, 0.004, (0.31, 0.0, 0.665), IRON(), rot=(90, 0, 0), seg=8)
	kit.cone(0.05, 0.035, 0.04, (0.31, 0.0, 0.41), T("wood", "c"), verts=12, bevel=0.004)
	# vegetables and slices, a salt pot
	kit.cone(0.032, 0.006, 0.18, (-0.1, -0.08, top + 0.026), C((0.85, 0.42, 0.12), 0.7), rot=(90, 0, 70), verts=8)
	kit.gem((-0.18, -0.05, top + 0.03), (0.035, 0.03, 0.022), kit.mat("sprout"), seed=2)
	sphere((-0.05, 0.12, top + 0.045), 0.05, C((0.82, 0.62, 0.38), 0.6), scale=(1, 1, 0.9))
	kit.cone(0.02, 0.0, 0.05, (-0.05, 0.12, top + 0.1), C((0.7, 0.55, 0.3), 0.7), verts=6)
	sphere((0.05, -0.2, top + 0.001), 0.045, C((0.82, 0.62, 0.38), 0.6), scale=(1, 1, 0.45), cut=0.0)  # an onion half, cut side down
	for k in range(5):
		kit.cylinder(0.026, 0.012, (0.03 + k * 0.035, -0.12 + 0.004 * (k % 2), top + 0.006 + 0.002 * (k % 2)), C((0.88, 0.48, 0.15), 0.7), verts=8, bevel=0.002)
	kit.cylinder(0.035, 0.06, (-0.14, 0.14, top + 0.03), kit.tex_mat("clay", "b"), verts=10, bevel=0.006)
	kit.ring(0.035, 0.007, (-0.14, 0.14, top + 0.058), kit.tex_mat("clay", "a"), seg=10)


def plate(c, r, rgb, tilt=75):
	kit.cylinder(r, 0.016, c, C(rgb, 0.6), rot=(tilt, 0, 0), verts=18, bevel=0.004)
	n = Vector((0, -math.sin(math.radians(tilt)), math.cos(math.radians(tilt))))
	kit.ring(r * 0.8, 0.006, tuple(Vector(c) + n * 0.009), C((0.35, 0.42, 0.55), 0.6), rot=(tilt, 0, 0), seg=18)


def dish_rack():
	W = 0.86
	wall_board(W, 0.8)
	top = wall_shelf(W + 0.04, 0.1, depth=0.22, lip=False)
	for k, x in enumerate((-0.3, -0.1, 0.1, 0.3)):  # bowls, some stacked
		for j in range(1 + (k % 2)):
			z = top + j * 0.05
			kit.cone(0.05, 0.08, 0.06, (x, -0.11, z + 0.03), kit.tex_mat("clay", "abc"[(k + j) % 3]), verts=14, bevel=0.006)
	# plate ledge with a retaining bar held by two cheeks
	B((W, 0.12, 0.03), (0, -0.06, 0.42), T("wood", "b"), bevel=0.008)
	for x in (-W / 2 + 0.01, W / 2 - 0.01):
		B((0.045, 0.14, 0.16), (x * 1.02, -0.07, 0.49), T("wood", "dark"), bevel=0.008)
	B((W - 0.06, 0.025, 0.03), (0, -0.125, 0.47), T("wood", "dark"), bevel=0.006)
	cols = [(0.85, 0.8, 0.68), (0.78, 0.6, 0.42), (0.85, 0.8, 0.68), (0.7, 0.45, 0.3)]
	for k in range(4):
		x = -0.29 + k * 0.193
		plate((x, -0.075, 0.535), 0.095, cols[k])
	B((W, 0.06, 0.04), (0, -0.03, 0.74), T("wood", "b"), bevel=0.008)
	for x in (-0.25, 0.0, 0.25):  # mug hooks under the top rail
		log((x, -0.03, 0.72), (x, -0.05, 0.68), 0.006, IRON(), seg=5, rings=1, ends=False, bend=0)
	kit.cylinder(0.04, 0.08, (0.0, -0.05, 0.63), kit.tex_mat("clay", "a"), verts=10, bevel=0.006)
	kit.ring(0.025, 0.008, (0.0, -0.05, 0.672), kit.tex_mat("clay", "a"), rot=(90, 0, 0), seg=8)


# ================= Lights =================
def crystal_floor_lamp():
	"""Tripod lamp: the crystals stand fully inside a deep copper cup, three claws hold them (owner Nov 21)."""
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.28, math.sin(a) * 0.28, 0), (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.5), 0.04, T("bark"), seg=7, rings=2)
		stone((0.1, 0.1, 0.05), (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.025))
	rope_tie((0, 0, 0.4), 0.1)
	log((0, 0, 0.38), (0.0, 0, 1.17), 0.045, T("wood", "b"), seg=8, rings=2, bend=0.03)
	for z in (0.75, 0.9):
		kit.ring(0.05, 0.012, (0.0, 0, z), CU(), seg=12)
	zc = 1.16  # cup: a narrow foot, then a deep bowl with a thick rim
	kit.cylinder(0.06, 0.04, (0, 0, zc + 0.02), CU("dark"), verts=12, bevel=0.005)
	lathe([(0, zc + 0.04), (0.06, zc + 0.04), (0.13, zc + 0.16), (0.115, zc + 0.16), (0.062, zc + 0.1), (0, zc + 0.1)], (0, 0), CU(), seg=16)
	kit.ring(0.13, 0.016, (0, 0, zc + 0.16), CU("dark"), seg=18)
	for k in range(6):
		a = 2 * math.pi * k / 6
		rivet((math.cos(a) * 0.1, math.sin(a) * 0.1, zc + 0.1), CU("dark"), r=0.009)
	g = GLOW_BLUE()
	floor = zc + 0.095  # all crystals start just under the cup's inner floor, well inside its walls
	aim((0, 0, floor), (0, 0, 1), 0.042, 0.34, g)
	for k in range(4):
		a = 2 * math.pi * k / 4 + 0.3
		aim((math.cos(a) * 0.038, math.sin(a) * 0.038, floor), (math.cos(a) * 0.16, math.sin(a) * 0.16, 1), 0.02, 0.17 + 0.03 * (k % 2), g)
	for k in range(3):  # copper claws from the rim up against the crystals
		a = 2 * math.pi * k / 3 + 0.9
		p0 = (math.cos(a) * 0.125, math.sin(a) * 0.125, zc + 0.16)
		p1 = (math.cos(a) * 0.1, math.sin(a) * 0.1, zc + 0.27)
		p2 = (math.cos(a) * 0.07, math.sin(a) * 0.07, zc + 0.31)
		log(p0, p1, 0.011, CU(), seg=6, rings=1, ends=False, bend=0)
		log(p1, p2, 0.009, CU(), seg=6, rings=1, ends=False, bend=0)
		rivet(p2, CU("dark"), r=0.012)


def mushroom_lamp():
	"""A big glowcap lamp in a clay pot (owner Nov 21: more detail): gill fins, spots, banded stem, pot with lugs and pebbles."""
	kit.cylinder(0.15, 0.03, (0, 0, 0.015), kit.tex_mat("clay", "b"), verts=14, bevel=0.006)  # foot ring
	kit.cone(0.14, 0.19, 0.2, (0, 0, 0.13), kit.tex_mat("clay", "a"), verts=14, bevel=0.01)
	kit.ring(0.19, 0.022, (0, 0, 0.23), kit.tex_mat("clay", "b"), seg=16)
	kit.ring(0.165, 0.012, (0, 0, 0.12), kit.tex_mat("clay", "c"), seg=16)
	for k in range(14):  # a band of pressed dots round the pot (sunk in: dark dents)
		a = 2 * math.pi * k / 14
		kit.cylinder(0.012, 0.008, (math.cos(a) * 0.172, math.sin(a) * 0.172, 0.17), kit.mat("charcoal", 0.3), rot=(90, 0, math.degrees(a) + 90), verts=8, bevel=0)
	for s_ in (-1, 1):  # two lugs
		B((0.04, 0.06, 0.05), (s_ * 0.19, 0, 0.19), kit.tex_mat("clay", "b"), bevel=0.012)
	disc(0.18, 0.215, 0.235, (0, 0), kit.tex_mat("soil", "a"), seg=12)
	for k in range(5):
		a = k * 1.3 + 0.4
		lump((math.cos(a) * 0.13, math.sin(a) * 0.13, 0.238), (0.025, 0.02, 0.015), T("stone", "abc"[k % 3]), seed=k, rough=0.003)
	log((0, 0, 0.21), (0.04, 0, 0.8), 0.05, STEM(), seg=8, rings=3, bend=0.15, r1=0.035)
	for z, r in ((0.35, 0.052), (0.6, 0.044)):
		kit.ring(r, 0.012, (0.01 + (z - 0.2) * 0.05, 0, z), CU(), seg=12)
	cz = 0.83
	sphere((0.04, 0, cz), 0.27, GLOW_AMBER(), scale=(1, 1, 0.5), cut=0.0)
	kit.ring(0.262, 0.014, (0.04, 0, cz + 0.005), C((0.85, 0.5, 0.2), 0.4, glow=0.5), seg=28)
	gill = C((0.9, 0.7, 0.4), 0.5, glow=0.4)
	kit.cylinder(0.235, 0.012, (0.04, 0, cz - 0.004), gill, verts=20, bevel=0)
	for k in range(24):  # gill fins under the cap
		a = 2 * math.pi * k / 24
		r0, r1 = 0.06, 0.215
		B((r1 - r0, 0.006, 0.03), (0.04 + math.cos(a) * (r0 + r1) / 2, math.sin(a) * (r0 + r1) / 2, cz - 0.022), gill, bevel=0, rot=(0, 0, math.degrees(a)))
	for k in range(9):
		a, d = k * 2.4, 0.05 + 0.17 * math.sqrt((k + 0.5) / 9)
		h = math.sqrt(max(0.0, 1 - (d / 0.27) ** 2)) * 0.135
		kit.gem((0.04 + math.cos(a) * d, math.sin(a) * d, cz + h - 0.004), (0.026, 0.026, 0.012), C((0.98, 0.9, 0.7), 0.5), seed=k)
	for (x, y, s) in ((-0.1, -0.06, 0.4), (0.11, -0.05, 0.3), (-0.04, 0.11, 0.25)):
		log((x, y, 0.22), (x, y, 0.22 + s * 0.2), 0.015, STEM(), seg=6, rings=1, ends=False, bend=0)
		sphere((x, y, 0.22 + s * 0.2), 0.06 * s / 0.4, GLOW_AMBER(), scale=(1, 1, 0.5), cut=0.0)


def crystal_hanging_light():
	"""Hanging light: crystals stand inside a copper cradle cup, chains from the rim up to a ceiling plate (owner Nov 21)."""
	top = 1.0
	kit.cylinder(0.16, 0.04, (0, 0, top), T("wood", "dark"), verts=12, bevel=0.008)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		rivet((math.cos(a) * 0.12, math.sin(a) * 0.12, top - 0.022), IRON())
	z = top - 0.045
	i = 0
	while z > 0.62:
		kit.ring(0.028, 0.007, (0, 0, z), IRON(), rot=(90, 0, 90 * (i % 2)), seg=10)
		z -= 0.042
		i += 1
	hub = z + 0.042 - 0.03
	kit.ring(0.035, 0.01, (0, 0, hub - 0.01), IRON("dark"), seg=12)
	zr = hub - 0.32  # cup rim
	lathe([(0, zr - 0.13), (0.05, zr - 0.13), (0.14, zr), (0.125, zr), (0.057, zr - 0.07), (0, zr - 0.07)], (0, 0), CU(), seg=16)
	kit.ring(0.14, 0.016, (0, 0, zr), CU("dark"), seg=18)
	kit.cone(0.04, 0.0, 0.08, (0, 0, zr - 0.17), CU("dark"), rot=(180, 0, 0), verts=10, bevel=0.003)  # finial under the cup
	kit.ring(0.03, 0.008, (0, 0, zr - 0.135), CU(), seg=10)
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.14, math.sin(a) * 0.14, zr), (math.cos(a) * 0.03, math.sin(a) * 0.03, hub - 0.012), 0.007, IRON(), seg=5, rings=1, ends=False, bend=0)
	g = GLOW_BLUE()
	floor = zr - 0.075
	aim((0, 0, floor), (0, 0, 1), 0.04, 0.22, g)
	for k in range(4):
		a = 2 * math.pi * k / 4 + 0.5
		aim((math.cos(a) * 0.035, math.sin(a) * 0.035, floor), (math.cos(a) * 0.15, math.sin(a) * 0.15, 1), 0.019, 0.13, g)


def lantern_hook():
	B((0.12, 0.03, 0.34), (0, 0.015, 0.85), IRON("dark"), bevel=0.008)
	for z in (0.72, 0.98):
		rivet((0, -0.002, z), CU("dark"))
	log((0, 0.0, 0.95), (0, -0.32, 0.95), 0.018, IRON(), seg=6, rings=2, ends=False, bend=0.02)
	log((0, 0.0, 0.76), (0, -0.2, 0.95), 0.014, IRON(), seg=6, rings=1, ends=False, bend=0)
	kit.ring(0.03, 0.009, (0, -0.335, 0.975), IRON(), rot=(0, 90, 0), seg=10)
	log((0, -0.3, 0.95), (0, -0.3, 0.912), 0.008, IRON(), seg=5, rings=1, ends=False, bend=0)
	lantern_body((0, -0.3, 0.56))


def glowworm_jar():
	"""Glow-worm jar on a little tripod (owner Nov 21): corked neck under a tied leather cap, iron bands, bail handle."""
	kit.cylinder(0.15, 0.04, (0, 0, 0.3), T("wood", "b"), verts=12, bevel=0.01)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.4
		log((math.cos(a) * 0.09, math.sin(a) * 0.09, 0.3), (math.cos(a) * 0.15, math.sin(a) * 0.15, 0.0), 0.025, T("wood", "dark"), seg=6, rings=2)
	kit.ring(0.115, 0.012, (0, 0, 0.13), kit.tex_mat("rope"), seg=14)
	gl = glass((0.55, 0.75, 0.6), 0.28, glow=0.08)
	kit.cylinder(0.1, 0.24, (0, 0, 0.44), gl, verts=16, bevel=0.03)
	kit.cone(0.1, 0.065, 0.04, (0, 0, 0.58), gl, verts=16, bevel=0.005)
	kit.cylinder(0.065, 0.03, (0, 0, 0.615), gl, verts=16, bevel=0.005)
	for z in (0.34, 0.54):
		kit.ring(0.101, 0.008, (0, 0, z), IRON("dark"), seg=20)
	kit.cylinder(0.055, 0.05, (0, 0, 0.64), C((0.62, 0.45, 0.28), 0.9), verts=12, bevel=0.008)  # cork
	sphere((0, 0, 0.655), 0.078, kit.tex_mat("leather", "b"), scale=(1, 1, 0.42), seg=14, rings=6, cut=0.0)  # leather cap
	kit.ring(0.069, 0.008, (0, 0, 0.63), kit.tex_mat("rope"), seg=14)
	kit.cylinder(0.018, 0.01, (0.0, 0.0, 0.69), C((0.5, 0.12, 0.1), 0.5), verts=10, bevel=0.003)  # wax seal
	for s_ in (-1, 1):  # bail handle from ears on the top band, arching over the cap
		rivet((s_ * 0.105, 0, 0.54), IRON(), r=0.012)
		log((s_ * 0.11, 0, 0.54), (s_ * 0.1, 0, 0.66), 0.006, IRON(), seg=5, rings=1, ends=False, bend=0)
	pts = [(math.cos(math.pi * t / 8) * 0.1, 0, 0.66 + math.sin(math.pi * t / 8) * 0.09) for t in range(9)]
	for p, q in zip(pts, pts[1:]):
		log(p, q, 0.006, IRON(), seg=5, rings=1, ends=False, bend=0)
	worm = C((0.5, 1.0, 0.35), 0.3, glow=1.2)
	disc(0.085, 0.33, 0.345, (0, 0), kit.tex_mat("soil", "b"), seg=14, wob=0.02)  # soil floor inside
	for k in range(6):  # worms curled on the soil and up a twig, all well inside the glass
		a = k * 1.05
		c = (math.cos(a) * 0.05, math.sin(a) * 0.05, 0.352)
		pts = [(c[0] + math.cos(a + t) * 0.02, c[1] + math.sin(a + t) * 0.02, c[2] + 0.004 * t) for t in (0, 1.2, 2.4, 3.6)]
		for p, q in zip(pts, pts[1:]):
			log(p, q, 0.008, worm, seg=6, rings=1, ends=False, bend=0)
	log((0.0, 0.0, 0.34), (0.02, 0.01, 0.5), 0.008, T("wood", "c"), seg=5, rings=2, ends=False, bend=0.1)


def candle_wall_shelf():
	W = 0.8
	wall_board(W, 0.55)
	kit.cylinder(0.12, 0.012, (0, -0.006, 0.36), CU("a"), rot=(90, 0, 0), verts=16, bevel=0.003)
	top = wall_shelf(W + 0.04, 0.12, depth=0.18, lip=False)
	for (x, r, h) in ((-0.3, 0.03, 0.12), (-0.15, 0.04, 0.2), (0.0, 0.045, 0.27), (0.15, 0.035, 0.16), (0.3, 0.03, 0.09)):
		candle(x, -0.09, top, r, h)


# ================= Workshop =================
def tool_wall():
	W = 1.1
	wall_board(W, 0.82)
	for z in (0.05, 0.78):
		B((W + 0.04, 0.03, 0.05), (0, -0.015, z), T("wood", "dark"), bevel=0.006)
		for x in (-0.48, 0.48):
			rivet((x, -0.031, z), IRON())

	def peg(x, z):
		log((x, 0.0, z), (x, -0.09, z + 0.015), 0.014, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)

	# saw resting on two pegs
	for x in (-0.38, -0.12):
		peg(x, 0.55)
	B((0.46, 0.01, 0.12), (-0.25, -0.04, 0.635), C((0.62, 0.62, 0.6), 0.4, metal=0.5), bevel=0.002)
	for k in range(14):
		kit.cone(0.012, 0.0, 0.018, (-0.46 + k * 0.03, -0.04, 0.568), C((0.62, 0.62, 0.6), 0.4, metal=0.5), rot=(180, 0, 0), verts=3, bevel=0)
	B((0.12, 0.03, 0.14), (0.04, -0.04, 0.64), T("wood", "dark"), bevel=0.012)
	# two hammers hanging by their heads between peg pairs
	for (x, big) in ((-0.35, False), (-0.05, True)):
		for dx in (-0.04, 0.04):
			peg(x + dx, 0.3)
		hl = 0.32 if big else 0.26
		B((0.03, 0.03, hl), (x, -0.04, 0.33 - hl / 2), T("wood", "b"), bevel=0.006)
		if big:
			kit.cylinder(0.055, 0.2, (x, -0.04, 0.37), T("wood", "dark"), rot=(0, 90, 0), verts=10, bevel=0.008)
			for s_ in (-1, 1):
				kit.ring(0.055, 0.008, (x + s_ * 0.08, -0.04, 0.37), IRON(), rot=(0, 90, 0), seg=12)
		else:
			B((0.16, 0.05, 0.05), (x, -0.04, 0.345), IRON("dark"), bevel=0.006)
	# tongs hanging over one peg
	peg(0.33, 0.62)
	for s_ in (-1, 1):
		B((0.018, 0.015, 0.42), (0.33, -0.05 - s_ * 0.008, 0.42), IRON("dark"), bevel=0.003, rot=(0, s_ * 7, 0))
		B((0.04, 0.015, 0.05), (0.33 + s_ * 0.015, -0.05 - s_ * 0.008, 0.2), IRON("dark"), bevel=0.003)
	rivet((0.33, -0.068, 0.42), CU("dark"))
	# a file and chisel on small pegs
	for (x, h) in ((0.12, 0.2), (0.2, 0.17)):
		peg(x, 0.62)
		B((0.022, 0.012, h), (x, -0.03, 0.615 - h / 2), IRON("a"), bevel=0.003)
		kit.cylinder(0.018, 0.08, (x, -0.03, 0.615 - h - 0.035), T("wood", "b"), verts=8, bevel=0.004)


def workbench_clutter():
	W, D, H = 0.9, 0.55, 0.75
	legs4(W, D, H - 0.05, r=0.045)
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		log((-W / 2 + 0.06, y, 0.2), (W / 2 - 0.06, y, 0.2), 0.035, T("bark"), seg=7, rings=2)
	plank_top(W, D, H - 0.03, n=4)
	# mallet
	kit.cylinder(0.05, 0.15, (-0.25, -0.06, H + 0.05), T("wood", "c"), rot=(90, 0, 0), verts=10, bevel=0.008)
	log((-0.205, -0.06, H + 0.05), (0.0, -0.08, H + 0.018), 0.016, T("wood", "b"), seg=6, rings=1)
	# files
	for (x, y, a) in ((0.12, -0.15, 15), (0.18, -0.08, -10)):
		B((0.2, 0.024, 0.008), (x, y, H + 0.004), IRON("a"), bevel=0.002, rot=(0, 0, a))
		ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
		kit.cylinder(0.016, 0.08, (x - ca * 0.13, y - sa * 0.13, H + 0.016), T("wood", "b"), rot=(0, 90, a), verts=8, bevel=0.003)
	# nail tray and loose nails
	B((0.18, 0.12, 0.02), (0.28, 0.14, H + 0.01), T("wood", "dark"), bevel=0.004)
	for s_ in (-1, 1):
		B((0.18, 0.015, 0.05), (0.28, 0.14 + s_ * 0.06, H + 0.025), T("wood", "dark"), bevel=0.004)
		B((0.015, 0.12, 0.05), (0.28 + s_ * 0.09, 0.14, H + 0.025), T("wood", "dark"), bevel=0.004)
	for k in range(6):
		kit.cylinder(0.009, 0.006, (0.23 + (k % 3) * 0.045, 0.115 + (k // 3) * 0.05, H + 0.045), IRON("dark"), verts=6, bevel=0)
		kit.cylinder(0.004, 0.03, (0.23 + (k % 3) * 0.045, 0.115 + (k // 3) * 0.05, H + 0.03), IRON(), verts=5, bevel=0)
	for k in range(5):
		x, y, a = -0.05 + k * 0.05, 0.05 + J(0.04), rng.uniform(0, 180)
		kit.cylinder(0.004, 0.06, (x, y, H + 0.004), IRON(), rot=(0, 90, a), verts=5, bevel=0)
		kit.cylinder(0.009, 0.004, (x + math.cos(math.radians(a)) * 0.03, y + math.sin(math.radians(a)) * 0.03, H + 0.008), IRON("dark"), rot=(0, 90, a), verts=6, bevel=0)
	# board being worked and its shavings
	B((0.38, 0.1, 0.03), (-0.12, 0.15, H + 0.015), T("wood", "c"), bevel=0.006, rot=(0, 0, 8))
	shav = C((0.86, 0.66, 0.4), 0.85)
	for k in range(10):  # curls and flat chips
		x, y = -0.35 + k * 0.065 + J(0.02), 0.04 + J(0.06)
		if k % 2:
			kit.ring(0.02, 0.0035, (x, y, H + 0.012), shav, rot=(75, 0, rng.uniform(0, 180)), seg=10)
		else:
			kit.gem((x, y, H + 0.004), (0.03, 0.018, 0.005), shav, seed=k)


def blueprint_table():
	"""Drafting table (owner Nov 21: a real picture): a pinned parchment plan of a Stonehold gate tower (round door,
	arched windows, battlements, a crane arm) with measuring lines, dividers, a set square, ink and quill."""
	A, ZC = 25.0, 0.9

	def top():
		B((0.95, 0.7, 0.04), (0, 0, 0), T("wood", "b"), bevel=0.012)
		B((0.95, 0.04, 0.04), (0, -0.33, 0.035), T("wood", "dark"), bevel=0.008)
		pz = 0.023
		B((0.6, 0.44, 0.006), (0.04, 0.06, pz), C((0.62, 0.52, 0.34), 0.95), bevel=0.001)  # parchment
		ink = C((0.12, 0.08, 0.06), 0.8)
		lz = pz + 0.004  # lines stand 1 mm proud of the paper and are pressed 2 mm into it

		def ln(x0, y0, x1, y1, w=0.005):
			cx, cy, L = (x0 + x1) / 2, (y0 + y1) / 2, math.hypot(x1 - x0, y1 - y0)
			B((L + w, w, 0.003), (0.04 + cx, 0.06 + cy, lz), ink, bevel=0, rot=(0, 0, math.degrees(math.atan2(y1 - y0, x1 - x0))))

		def arc(cx, cy, r, a0, a1, n=8, w=0.004):
			pts = [(cx + math.cos(a0 + (a1 - a0) * i / n) * r, cy + math.sin(a0 + (a1 - a0) * i / n) * r) for i in range(n + 1)]
			for p, q in zip(pts, pts[1:]):
				ln(p[0], p[1], q[0], q[1], w)
		# the tower: ground line, walls, battlements on a flat roof
		ln(-0.24, -0.17, 0.24, -0.17, 0.006)
		ln(-0.12, -0.17, -0.12, 0.1)
		ln(0.12, -0.17, 0.12, 0.1)
		ln(-0.14, 0.1, 0.14, 0.1)
		for i in range(5):
			x = -0.14 + i * 0.07
			ln(x, 0.1, x, 0.13)
			ln(x, 0.13, x + 0.035, 0.13)
			ln(x + 0.035, 0.13, x + 0.035, 0.1)
		arc(0.0, -0.17, 0.06, 0.0, math.pi, n=10)  # round door, cut flat at the floor
		ln(0, -0.17, 0, -0.11, 0.003)
		for x in (-0.07, 0.07):  # arched windows
			ln(x - 0.02, -0.02, x - 0.02, 0.03)
			ln(x + 0.02, -0.02, x + 0.02, 0.03)
			ln(x - 0.02, -0.02, x + 0.02, -0.02)
			arc(x, 0.03, 0.02, 0.0, math.pi, n=6)
		for k in range(4):  # stone courses
			y = -0.13 + k * 0.05
			ln(-0.12, y, -0.09, y, 0.003)
			ln(0.09, y, 0.12, y, 0.003)
		# a crane arm out of the side with a rope and hook
		ln(0.12, 0.06, 0.23, 0.08)
		ln(0.12, 0.02, 0.23, 0.08)
		ln(0.215, 0.08, 0.215, 0.0, 0.003)
		arc(0.205, -0.005, 0.01, -math.pi, 0.4, n=5, w=0.003)
		# measuring line with end ticks under the drawing, and a title box
		ln(-0.12, -0.195, 0.12, -0.195, 0.003)
		for x in (-0.12, 0.12):
			ln(x, -0.205, x, -0.185, 0.003)
		ln(-0.28, 0.17, -0.16, 0.17, 0.004)
		ln(-0.28, 0.2, -0.16, 0.2, 0.004)
		ln(-0.28, 0.17, -0.28, 0.2, 0.004)
		ln(-0.16, 0.17, -0.16, 0.2, 0.004)
		ln(-0.265, 0.185, -0.18, 0.185, 0.003)
		for cx in (-1, 1):
			for cy in (-1, 1):
				rivet((0.04 + cx * 0.28, 0.06 + cy * 0.2, 0.03), CU(), r=0.012)
		# rolled plan, ink pot and quill, brass dividers, a set square
		kit.cylinder(0.035, 0.5, (-0.08, -0.27, 0.055), PAPER(), rot=(0, 90, 0), verts=12, bevel=0.004)
		kit.ring(0.037, 0.008, (0.05, -0.27, 0.055), C((0.55, 0.2, 0.15), 0.8), rot=(0, 90, 0), seg=10)
		kit.cylinder(0.035, 0.05, (0.38, 0.25, 0.045), kit.mat("charcoal", 0.2), verts=10, bevel=0.004)
		log((0.38, 0.25, 0.06), (0.43, 0.3, 0.2), 0.008, C((0.85, 0.82, 0.75), 0.8), seg=5, rings=1, ends=False, bend=0)
		brass = CU("a")
		for s_ in (-1, 1):
			B((0.008, 0.16, 0.008), (0.4 + s_ * 0.02, -0.04, 0.025), brass, bevel=0.002, rot=(0, 0, s_ * 8))
		kit.cylinder(0.014, 0.012, (0.4, 0.04, 0.028), brass, verts=10, bevel=0.002)
		for (sx, sy, x, y) in ((0.16, 0.012, 0.4, -0.2), (0.012, 0.12, 0.326, -0.146)):
			B((sx, sy, 0.008), (x, y, 0.024), T("wood", "c"), bevel=0.002)

	group(top, at=(0, 0, ZC), rot=(A, 0, 0))
	a = math.radians(A)
	for x in (-0.4, 0.4):
		for yw in (-0.25, 0.25):
			yl = (yw - 0.02 * math.sin(a)) / math.cos(a)
			zt = ZC + yl * math.sin(a) - 0.02 * math.cos(a) + 0.015
			B((0.06, 0.06, zt), (x, yw, zt / 2), T("wood", "dark"), bevel=0.01)
	for yw in (-0.25, 0.25):
		B((0.86, 0.04, 0.05), (0, yw, 0.18), T("wood", "dark"), bevel=0.006)
	B((0.84, 0.5, 0.03), (0, 0, 0.22), T("wood", "b"), bevel=0.008)
	for k in range(3):
		kit.cylinder(0.035, 0.55 - k * 0.06, (0.02 * k, -0.12 + k * 0.075, 0.235 + 0.035), PAPER(), rot=(0, 90, 0), verts=12, bevel=0.004)


def gear(c, r, t, m, rot=(0, 0, 0), n=8):
	"""The first simple gear (disc + block teeth), kept because decor_nov21_lw.py uses it."""
	def build():
		kit.cylinder(r, t, (0, 0, 0), m, verts=16, bevel=0.004)
		for k in range(n):
			a = 2 * math.pi * k / n
			B((r * 0.35, r * 0.3, t * 0.9), (math.cos(a) * r * 1.1, math.sin(a) * r * 1.1, 0), m, bevel=0.003, rot=(0, 0, math.degrees(a)))
		kit.cylinder(r * 0.3, t + 0.006, (0, 0, 0), IRON("dark"), verts=8, bevel=0.002)
	group(build, c, rot)


def toothed_gear(c, r, t, m, rot=(0, 0, 0), n=10, spokes=4):
	"""A proper toothed gear: a toothed rim (trapezoid teeth) around a hole, spokes and a hub with a square axle hole."""
	def build():
		ri, rr, rt = r * 0.72, r, r * 1.16
		out = []
		for k in range(n):  # tooth outline: root, flank up, tip, flank down
			a = 2 * math.pi * k / n
			da = math.pi / n
			for aa, rad in ((a - da * 0.5, rr), (a - da * 0.3, rt), (a + da * 0.3, rt), (a + da * 0.5, rr)):
				out.append((math.cos(aa) * rad, math.sin(aa) * rad))
		m_ = len(out)
		inn = [(math.cos(2 * math.pi * i / m_) * ri, math.sin(2 * math.pi * i / m_) * ri) for i in range(m_)]
		v = [(x, y, -t / 2) for x, y in out] + [(x, y, t / 2) for x, y in out] + [(x, y, -t / 2) for x, y in inn] + [(x, y, t / 2) for x, y in inn]
		f = []
		for i in range(m_):
			j = (i + 1) % m_
			f += [(i, j, m_ + j, m_ + i), (2 * m_ + j, 2 * m_ + i, 3 * m_ + i, 3 * m_ + j),
				(m_ + i, m_ + j, 3 * m_ + j, 3 * m_ + i), (j, i, 2 * m_ + i, 2 * m_ + j)]
		mesh(v, f, m)
		for k in range(spokes):
			a = 2 * math.pi * k / spokes
			B((ri - r * 0.2, r * 0.16, t * 0.8), (math.cos(a) * (ri + r * 0.2) / 2, math.sin(a) * (ri + r * 0.2) / 2, 0), m, bevel=0.002, rot=(0, 0, math.degrees(a)))
		kit.cylinder(r * 0.26, t * 1.3, (0, 0, 0), m, verts=12, bevel=0.002)
		B((r * 0.14, r * 0.14, t * 1.3 + 0.004), (0, 0, 0), kit.mat("charcoal", -0.2), bevel=0)
	group(build, c, rot)


def bolt(c, rot, nut=True):
	"""A hex-head bolt with a thread and (sometimes) a nut screwed on."""
	def build():
		kit.cylinder(0.011, 0.09, (0, 0, 0), IRON(), verts=8, bevel=0.002)
		for k in range(4):
			kit.ring(0.011, 0.0025, (0, 0, -0.04 + k * 0.012), IRON("dark"), seg=8)
		kit.cylinder(0.022, 0.016, (0, 0, 0.05), IRON("dark"), verts=6, bevel=0.003)
		if nut:
			kit.cylinder(0.02, 0.014, (0, 0, -0.02), IRON("a"), verts=6, bevel=0.002)
	group(build, c, rot)


def parts_bin():
	"""A workshop bin of spare parts (owner Nov 21: proper gears, no ash): toothed gears, bolts, nuts, washers, a chain."""
	W, D, H = 0.66, 0.46, 0.42
	open_crate(W, D, H, (0, 0, 0))
	for s_ in (-1, 1):
		kit.ring(0.05, 0.012, (s_ * (W / 2 + 0.005), 0, H * 0.7), kit.tex_mat("rope"), rot=(0, 90, 0), seg=10)
	B((0.16, 0.012, 0.07), (0, -D / 2 - 0.007, H * 0.5), T("wood", "c"), bevel=0.004)  # tag with a cut-in gear sign
	kit.ring(0.02, 0.005, (0, -D / 2 - 0.013, H * 0.5), kit.mat("charcoal", 0.2), rot=(90, 0, 0), seg=10)
	ff = H - 0.13  # a false floor inside, so the bin looks full without being solid
	B((W - 0.06, D - 0.06, 0.02), (0, 0, ff), T("wood", "b"), bevel=0.004)
	toothed_gear((-0.15, -0.06, ff + 0.025), 0.1, 0.03, CU(), rot=(4, -3, 10), n=12)
	toothed_gear((0.13, 0.04, ff + 0.03), 0.075, 0.025, IRON("a"), rot=(-6, 8, 0), n=9)
	toothed_gear((0.04, -0.11, ff + 0.025), 0.055, 0.02, CU("a"), rot=(10, 5, 0), n=8, spokes=3)
	toothed_gear((-0.1, 0.1, ff + 0.03), 0.06, 0.02, CU("b"), rot=(-8, 0, 30), n=8, spokes=3)
	toothed_gear((0.02, D / 2 - 0.05, ff + 0.12), 0.12, 0.03, CU("a"), rot=(72, 0, 0), n=14)  # big gear leaning on the back
	for (x, y, z, a, nut) in ((0.2, -0.12, 0.03, 30, True), (-0.22, 0.12, 0.03, -50, False), (0.09, 0.13, 0.04, 80, True), (-0.02, 0.0, 0.032, 10, False)):
		bolt((x, y, ff + z), (90, 0, a), nut)
	for (x, y) in ((0.22, 0.1), (-0.03, -0.17), (0.16, -0.17)):  # loose nuts and washers
		kit.cylinder(0.02, 0.014, (x, y, ff + 0.018), IRON("a"), verts=6, bevel=0.002)
		kit.ring(0.02, 0.005, (x + 0.04, y, ff + 0.015), IRON("dark"), seg=10)
	for k in range(6):  # a short chain lying across the parts
		kit.ring(0.02, 0.005, (-0.26 + k * 0.03, -0.15, ff + 0.02 + 0.008 * (k % 2)), IRON(), rot=(90 * (k % 2), 0, 0), seg=10)


# ================= Plants =================
def glowcap_pot():
	"""Clay pot of the game's own glowcaps (owner Nov 21: more detail): foot, rim, carved band, handles, tiny caps, pebbles."""
	kit.cylinder(0.16, 0.03, (0, 0, 0.015), kit.tex_mat("clay", "b"), verts=16, bevel=0.006)
	kit.cone(0.15, 0.21, 0.2, (0, 0, 0.13), kit.tex_mat("clay", "c"), verts=16, bevel=0.01)
	kit.ring(0.21, 0.022, (0, 0, 0.23), kit.tex_mat("clay", "a"), seg=18)
	kit.ring(0.18, 0.012, (0, 0, 0.13), kit.tex_mat("clay", "a"), seg=18)
	for k in range(10):  # a zig-zag band cut into the clay
		a = 2 * math.pi * k / 10
		B((0.05, 0.012, 0.008), (math.cos(a) * 0.192, math.sin(a) * 0.192, 0.18), kit.mat("charcoal", 0.3), bevel=0,
			rot=(0, 30 if k % 2 else -30, math.degrees(a) + 90))
	for s_ in (-1, 1):
		kit.ring(0.04, 0.012, (s_ * 0.21, 0, 0.19), kit.tex_mat("clay", "a"), rot=(90, 0, 0), seg=10)
	disc(0.2, 0.215, 0.236, (0, 0), kit.tex_mat("soil", "a"), seg=14)
	tint(place_glb("cave/glowcap", (0.0, 0.01, 0.232), 0.34, rotz=20, drop=("soil",)), "glow_cap", (0.25, 0.95, 0.85), glow=0.8)
	for (x, y, sz, rz) in ((-0.11, -0.09, 0.12, 60), (0.12, 0.08, 0.1, 200)):
		tint(place_glb("cave/tinycaps", (x, y, 0.234), sz, rotz=rz), "tint", (0.3, 0.8, 0.75), glow=0.5)
	for k in range(5):
		a = k * 1.3 + 0.2
		lump((math.cos(a) * 0.17, math.sin(a) * 0.17, 0.238), (0.025, 0.02, 0.014), T("stone", "abc"[k % 3]), seed=k, rough=0.003)


def fern_basket():
	"""Hanging wicker basket with the game's own fern in it, fronds over the rim (owner Nov 21)."""
	lathe([(0, 0), (0.1, 0), (0.22, 0.2), (0.2, 0.2), (0.09, 0.03), (0, 0.03)], (0, 0), kit.tex_mat("straw", "a"), seg=16)
	for k in range(12):  # wicker ribs
		a = 2 * math.pi * k / 12
		log((math.cos(a) * 0.1, math.sin(a) * 0.1, 0.0), (math.cos(a) * 0.222, math.sin(a) * 0.222, 0.2), 0.007, kit.tex_mat("straw", "b"), seg=5, rings=1, ends=False, bend=0)
	for z in (0.05, 0.13):
		kit.ring(0.105 + z * 0.6, 0.012, (0, 0, z), kit.tex_mat("rope"), seg=18)
	kit.ring(0.22, 0.02, (0, 0, 0.2), kit.tex_mat("straw", "b"), seg=18)
	disc(0.175, 0.15, 0.17, (0, 0), kit.tex_mat("soil", "a"), seg=12)
	for k in range(3):
		a = 2 * math.pi * k / 3
		log((math.cos(a) * 0.22, math.sin(a) * 0.22, 0.21), (0, 0, 0.74), 0.008, kit.tex_mat("rope"), seg=4, rings=1, ends=False, bend=0)
	kit.ring(0.03, 0.009, (0, 0, 0.76), IRON(), rot=(90, 0, 0), seg=10)
	log((0, 0, 0.78), (0, 0, 0.84), 0.01, IRON(), seg=5, rings=1, ends=False, bend=0)
	kit.cylinder(0.1, 0.03, (0, 0, 0.855), T("wood", "dark"), verts=10, bevel=0.006)
	place_glb("cave/fern", (0, 0, 0.165), 0.62, rotz=15)


def geode_stand():
	"""A split geode on a carved stand (owner Nov 21: real geode): one half upright in a cradle, the other lying beside it."""
	wood, dark = kit.tex_mat("wood", "b"), kit.tex_mat("wood", "dark")
	B((0.72, 0.34, 0.05), (0, 0.02, 0.045), wood, bevel=0.012)  # plinth on four bun feet, stepped top
	B((0.66, 0.28, 0.03), (0, 0.02, 0.085), dark, bevel=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			sphere((cx * 0.31, 0.02 + cy * 0.12, 0.02), 0.035, dark, scale=(1, 1, 0.7), seg=10, rings=6)
	for k in range(11):  # carved notches along the front edge (cut in: dark slits)
		B((0.012, 0.008, 0.03), (-0.3 + k * 0.06, -0.1495, 0.045), kit.mat("charcoal", 0.3), bevel=0)
	B((0.14, 0.012, 0.03), (0.0, -0.124, 0.085), CU(), bevel=0.004)  # brass plaque on the top step
	for x in (-0.055, 0.055):
		rivet((x, -0.131, 0.085), CU("dark"), r=0.007)
	zc = 0.31
	for s_ in (-1, 1):  # cradle arms
		B((0.07, 0.16, 0.18), (s_ * 0.11 - 0.12, 0.06, 0.17), wood, bevel=0.012, rot=(0, s_ * 30, 0))
		rivet((s_ * 0.13 - 0.12, -0.025, 0.17), CU("dark"), r=0.012)
	group(lambda: geode_half(0.2, 0.12, T("brownrock", "b"), 5), at=(-0.12, 0.0, zc), rot=(0, 0, 0))
	# the other half lying face-up on the plinth
	group(lambda: geode_half(0.11, 0.065, T("brownrock", "b"), 9), at=(0.22, 0.03, 0.2), rot=(-90, 0, 20))


MODELS = {
	"spice_shelf": spice_shelf, "pantry_crates": pantry_crates, "pie_rack": pie_rack, "kitchen_block": kitchen_block,
	"dish_rack": dish_rack,
	"crystal_floor_lamp": crystal_floor_lamp, "mushroom_lamp": mushroom_lamp, "crystal_hanging_light": crystal_hanging_light,
	"lantern_hook": lantern_hook, "glowworm_jar": glowworm_jar, "candle_wall_shelf": candle_wall_shelf,
	"tool_wall": tool_wall, "workbench_clutter": workbench_clutter, "blueprint_table": blueprint_table, "parts_bin": parts_bin,
	"glowcap_pot": glowcap_pot, "fern_basket": fern_basket, "geode_stand": geode_stand,
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
