# Materials, crystals, gems, runes, monster parts and odds and ends (folder: items), hand-built from the kit.
#   blender --background --factory-startup --python builds/items_materials.py -- [item_id ...]
# Dropped items lie on the ground; origin bottom-centre; largest side about 0.2-0.45 m. See STYLE_NOTES.md.
import math
import random
import shutil
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "items"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "items"


def col(name, rgb, **kw):
	kit.COLORS[name] = rgb
	return kit.mat(name, **kw)


def lump(size, loc, material, seed=1, rough=0.012):
	"""A chunky rock lump: a squashed faceted ball, chipped."""
	o = kit.gem(loc, size, material, seed=seed)
	kit.roughen(o, amount=rough, cuts=1, seed=seed)
	return o


def rock(kind, seed=1):
	lump((0.16, 0.13, 0.11), (0, 0, 0.1), kit.tex_mat(kind), seed=seed)
	lump((0.08, 0.07, 0.06), (0.13, 0.05, 0.055), kit.tex_mat(kind, "b"), seed=seed + 1)
	lump((0.06, 0.05, 0.045), (-0.12, -0.06, 0.04), kit.tex_mat(kind, "dark"), seed=seed + 2)


def ore(metal, seed=3, rock="stone", variant="c"):
	lump((0.17, 0.14, 0.12), (0, 0, 0.11), kit.tex_mat(rock, "b"), seed=seed)
	m = kit.tex_mat(metal, variant)
	r = random.Random(seed)
	for k in range(6):
		a = r.uniform(0, 6.28)
		kit.gem((math.cos(a) * 0.13, math.sin(a) * 0.1, 0.1 + r.uniform(-0.04, 0.06)), (0.05, 0.04, 0.035), m, seed=k)
	lump((0.07, 0.06, 0.05), (0.16, -0.06, 0.04), kit.tex_mat("stone", "dark"), seed=seed + 9)


def crystal(colour, rgb):
	lump((0.12, 0.1, 0.06), (0, 0, 0.05), kit.tex_mat("basalt"), seed=4)
	kit.crystal_cluster((0, 0, 0.07), 0.9, col(colour, rgb, glow=0.6, rough=0.2), seed=len(colour), n=6)


def block(kind, size=0.24, glow=0.0):
	o = kit.tbox(kind, (size, size, size), (0, 0, size / 2), bevel=0.02, wobble=0.003)
	kit.roughen(o, amount=0.003, cuts=1, seed=2)
	if glow:
		o.data.materials[0] = kit.tex_mat(kind)
		kit.box((size * 0.6, 0.004, size * 0.6), (0, -size / 2 - 0.002, size / 2), kit.glow("crystal_amber", glow), bevel=0, wobble=0)


def bricks(kind, mossy=False):
	for i, (x, z, rz) in enumerate(((-0.07, 0.04, 3), (0.08, 0.04, -4), (0.0, 0.12, 8))):
		kit.tbox(kind, (0.2, 0.1, 0.075), (x, 0, z), rot=(0, 0, rz), variant="abc"[i], bevel=0.012, wobble=0.004)
	if mossy:
		o = kit.gem((0.04, -0.03, 0.165), (0.06, 0.04, 0.02), kit.mat("moss"), seed=3)
		kit.soft(o, 1)


def ingot(metal):
	for i, (x, y, z, rz) in enumerate(((0, -0.05, 0, 3), (0.02, 0.06, 0, -5), (0.01, 0.0, 0.06, 88))):
		kit.taper(0.22, 0.09, 0.17, 0.06, 0.055, (x, y, z), kit.tex_mat(metal, "abc"[i]), bevel=0.008).rotation_euler.z = math.radians(rz)


def planks(kind):
	for i, z in enumerate((0.0, 0.045, 0.09)):
		kit.tbox(kind, (0.42, 0.09 - i * 0.005, 0.04), (0, (i - 1) * 0.015, z + 0.02), rot=(0, 0, (i - 1) * 6), variant="abc"[i], bevel=0.01, wobble=0.003)
	kit.rope_wrap((0, 0), 0.075, -0.12, -0.09, 2, thick=0.008, axis="x")


def root_log():
	r = random.Random(3)
	for k in range(4):
		a = k * 1.6
		o = kit.cone(0.05 - k * 0.008, 0.02, 0.42 - k * 0.06, (0, math.cos(a) * 0.03, 0.06), kit.tex_mat("wood", "dark"),
			rot=(0, 90, r.uniform(-12, 12)), verts=8, bevel=0.01)
		kit.roughen(o, 0.006, 1, seed=k)


def mush_log():
	kit.tcyl("mushwood", 0.09, 0.36, (0, 0, 0.09), rot=(0, 90, 0), verts=12)
	for s in (-1, 1):
		kit.cylinder(0.085, 0.01, (s * 0.181, 0, 0.09), kit.mat("gill"), rot=(0, 90, 0), verts=12, bevel=0)


def fiber():
	r = random.Random(2)
	for k in range(14):
		a = r.uniform(0, 6.28)
		d = r.uniform(0, 0.03)
		kit.cylinder(0.006, 0.34, (r.uniform(-0.02, 0.02), math.cos(a) * d, 0.03 + math.sin(a) * d), col("fiber", (0.72, 0.68, 0.48)),
			rot=(0, 90, r.uniform(-8, 8)), verts=5, bevel=0)
	kit.rope_wrap((0, 0.03), 0.04, -0.03, 0.03, 3, thick=0.006, axis="x")


def moss():
	r = random.Random(1)
	for k in range(5):
		o = kit.gem((r.uniform(-0.08, 0.08), r.uniform(-0.06, 0.06), 0.035), (0.08, 0.07, 0.04), kit.mat("moss", r.uniform(-0.15, 0.1)), seed=k)
		kit.soft(o, 1)


def dirt():
	o = kit.cone(0.16, 0.05, 0.1, (0, 0, 0.05), kit.tex_mat("soil"), verts=12, bevel=0)
	kit.roughen(o, 0.012, 2, seed=4)
	kit.soft(o, 1)
	lump((0.03, 0.025, 0.02), (0.1, 0.06, 0.03), kit.tex_mat("stone", "b"), seed=7)


def rope_coil():
	for k in range(4):
		kit.ring(0.12 - k * 0.005, 0.016, (0, 0, 0.016 + k * 0.028), kit.tex_mat("rope"), seg=24)
	kit.rope((0.11, 0, 0.1), (0.2, -0.06, 0.02), r=0.016)


def leather(hide_shape=False, colour="leather"):
	if hide_shape:
		o = kit.hide(0.38, 0.3, (0, 0, 0.0), kit.tex_mat(colour) if colour in kit.TILE else kit.mat(colour), seed=5)
		o.rotation_euler.x = math.radians(90)
		return
	for i in range(3):
		kit.tbox("leather", (0.32, 0.22, 0.02), (0, 0, 0.012 + i * 0.022), rot=(0, 0, i * 7 - 7), variant="abc"[i], bevel=0.01, wobble=0.004)
	kit.rope_wrap((0, 0.04), 0.13, -0.03, 0.03, 2, thick=0.007, axis="x")


def scrap():
	r = random.Random(6)
	for k in range(7):
		m = kit.tex_mat("iron", "dark") if k % 2 else kit.tex_mat("copper", "dark")
		o = kit.box((r.uniform(0.06, 0.14), r.uniform(0.04, 0.08), 0.015), (r.uniform(-0.08, 0.08), r.uniform(-0.06, 0.06), 0.012 + k * 0.012), m,
			bevel=0.003, wobble=0.004, rot=(r.uniform(-15, 15), r.uniform(-15, 15), r.uniform(0, 180)))
	kit.ring(0.04, 0.01, (0.08, -0.06, 0.03), kit.tex_mat("iron", "dark"), rot=(70, 0, 20), seg=12)


def blob(colour, rgb, glow=0.0, size=(0.13, 0.11, 0.07), seed=2, bumps=0.012, veins=False, drips=False):
	"""A soft organic lump: bumpy, a little uneven, optionally veined or dripping."""
	o = kit.gem((0, 0, size[2]), size, col(colour, rgb, glow=glow, rough=0.25), seed=seed)
	kit.roughen(o, bumps, 1, seed=seed)
	kit.soft(o, 2)
	if veins:
		dark = col(colour + "_v", tuple(c * 0.55 for c in rgb), glow=glow * 0.5)
		for k in range(3):
			a = k * 2.1
			kit.rope((math.cos(a) * size[0] * 0.3, math.sin(a) * size[1] * 0.3, size[2] * 1.9),
				(math.cos(a) * size[0] * 0.9, math.sin(a) * size[1] * 0.9, size[2] * 0.8), r=0.004).data.materials[0] = dark
	if drips:
		for k in range(4):
			a = k * 1.7
			d = kit.gem((math.cos(a) * size[0] * 0.85, math.sin(a) * size[1] * 0.85, 0.012), (0.04, 0.032, 0.012), col(colour, rgb, glow=glow, rough=0.2), seed=k)
			kit.soft(d, 1)
	return o


def snail_meat():
	r = random.Random(2)
	m = col("snailmeat", (0.7, 0.52, 0.52), rough=0.35)
	for k in range(5):
		a = k * 0.8
		o = kit.gem((math.cos(a) * 0.06 * (1 - k * 0.12), math.sin(a) * 0.06 * (1 - k * 0.12), 0.035), (0.045 - k * 0.004, 0.04 - k * 0.004, 0.03), m, seed=k)
		kit.soft(o, 1)


def bug_meat():
	m = col("bugmeat", (0.86, 0.78, 0.6), rough=0.4)
	for k in range(3):
		o = kit.gem((-0.08 + k * 0.08, 0, 0.04), (0.05, 0.05, 0.04), m, seed=k + 3)
		kit.roughen(o, 0.006, 1, seed=k)
		kit.soft(o, 1)
	kit.gem((0.12, 0.0, 0.05), (0.04, 0.045, 0.02), col("chitin", (0.2, 0.28, 0.2), rough=0.4), seed=9)


def flesh():
	o = kit.gem((0, 0, 0.06), (0.14, 0.1, 0.06), col("mflesh", (0.88, 0.82, 0.74), rough=0.5), seed=4)
	kit.roughen(o, 0.01, 1, seed=4)
	kit.soft(o, 1)
	for k in range(7):
		kit.box((0.005, 0.18, 0.012), (-0.07 + k * 0.022, 0, 0.012), kit.mat("gill", -0.15), bevel=0, wobble=0.002)


def amber_block():
	o = kit.box((0.24, 0.24, 0.24), (0, 0, 0.12), kit.tex_mat("amberrock", "c", rough=0.15, metal=0.15), bevel=0.025, wobble=0.004)
	kit.roughen(o, 0.004, 1, seed=3)
	kit.gem((0.03, -0.02, 0.13), (0.03, 0.02, 0.02), kit.mat("charcoal", 0.2), seed=5)
	kit.gem((-0.05, 0.03, 0.07), (0.02, 0.02, 0.015), kit.mat("charcoal", 0.3), seed=6)


def tuber():
	o = kit.gem((0, 0, 0.06), (0.12, 0.08, 0.06), kit.tex_mat("brownrock", "c"), seed=3)
	kit.soft(o, 1)
	for k in range(4):
		a = k * 1.7
		kit.cone(0.008, 0.0, 0.06, (math.cos(a) * 0.1, math.sin(a) * 0.06, 0.04), kit.tex_mat("wood", "dark"), rot=(0, 90, math.degrees(a)), verts=5, bevel=0)


def mushroom(cap, glow=0.0, scale=1.4, bell=False):
	if glow:
		kit.COLORS[cap + "_g"] = kit.COLORS[cap]
		kit.mushroom((0, 0, 0), scale, cap=cap, seed=2)
		for o in bpy.context.scene.objects:
			if o.type == "MESH" and o.data.materials and o.data.materials[0].name.startswith(cap):
				o.data.materials[0] = kit.glow(cap, glow)
	else:
		kit.mushroom((0, 0, 0), scale, cap=cap, seed=2)
	if bell:
		for o in list(bpy.context.scene.objects):
			if o.type == "MESH" and o.data.materials and o.data.materials[0].name.startswith(cap):
				for v in o.data.vertices:
					v.co.z += (v.co.z - 0.3) * 0.8


def morel():
	kit.cylinder(0.035, 0.12, (0, 0, 0.06), kit.mat("bone"), verts=10, bevel=0.005)
	o = kit.cone(0.07, 0.02, 0.17, (0, 0, 0.19), kit.glow("fire", 0.35), verts=12, bevel=0)
	kit.roughen(o, 0.014, 2, seed=8)


def meat(shell=False, kind="target_red"):
	"""A raw cut: a lumpy red chunk wrapped in a fat layer, with a bone sticking out."""
	o = kit.gem((0, 0, 0.065), (0.13, 0.1, 0.065), col("meat", (0.55, 0.14, 0.12), rough=0.55), seed=4)
	kit.roughen(o, 0.01, 1, seed=4)
	kit.soft(o, 1)
	f = kit.gem((-0.01, 0.0, 0.06), (0.14, 0.11, 0.05), col("fat", (0.9, 0.8, 0.7), rough=0.5), seed=5)
	kit.soft(f, 1)
	kit.cylinder(0.02, 0.12, (0.15, 0, 0.06), kit.mat("bone"), rot=(0, 90, 0), verts=8, bevel=0.005)
	kit.gem((0.21, 0, 0.06), (0.03, 0.035, 0.03), kit.mat("bone"), seed=2)
	if shell:
		d = kit.gem((0.04, 0.05, 0.1), (0.1, 0.07, 0.03), col("chitin", (0.2, 0.28, 0.2), rough=0.4), seed=6)


def plate(rgb, name, size=0.3):
	bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1, location=(0, 0, 0))
	o = bpy.context.object
	for v in o.data.vertices:
		if v.co.z < 0.3:
			v.co.z = 0.3
	o.scale = (size / 2, size / 2.6, size / 3)
	bpy.ops.object.transform_apply(scale=True)
	kit._finish(o, col(name, rgb, rough=0.35, metal=0.2), 0, 0)
	# Growth ridges pressed into the surface, then chipped edges.
	for v in o.data.vertices:
		d = math.hypot(v.co.x / (size / 2), v.co.y / (size / 2.6))
		v.co.z += 0.006 * math.sin(d * 18)
	kit.roughen(o, 0.004, 1, seed=3)
	for p_ in o.data.polygons:
		p_.use_smooth = True
	o.location.z = -0.1 * size / 0.3


def curved_blade(length, width, rgb, name, glow=0.0):
	width *= 1.8
	verts, faces = [], []
	n = 10
	for i in range(n):
		t = i / (n - 1)
		a = t * 1.6
		cx, cy = math.sin(a) * length * 0.6, (1 - math.cos(a)) * length * 0.5
		w = width * (1 - t) + 0.004
		nx, ny = math.cos(a), -math.sin(a)
		for (dx, dz) in ((-w / 2, -0.016), (w / 2, -0.003), (w / 2, 0.003), (-w / 2, 0.016)):
			verts.append((cx + ny * dx, cy - nx * dx * -1 if False else cy + nx * dx, 0.02 + dz))
	for i in range(n - 1):
		for k in range(4):
			a, b = i * 4 + k, i * 4 + (k + 1) % 4
			faces.append((a, b, b + 4, a + 4))
	faces.append((3, 2, 1, 0))
	faces.append(tuple(range((n - 1) * 4, n * 4)))
	kit._mesh_obj("blade", verts, faces, col(name, rgb, glow=glow, rough=0.4), smooth=False)


def fang(length=0.2):
	verts, faces = [], []
	n, s = 8, 8
	for i in range(n):
		t = i / (n - 1)
		r = 0.028 * (1 - t) + 0.002
		a = t * 0.9
		cx, cz = math.sin(a) * length, 0.03 + (1 - math.cos(a)) * length * 0.6
		for k in range(s):
			b = 2 * math.pi * k / s
			verts.append((cx - math.sin(a) * math.cos(b) * r * 0, math.sin(b) * r, cz + math.cos(b) * r))
	for i in range(n - 1):
		for k in range(s):
			p, q = i * s + k, i * s + (k + 1) % s
			faces.append((p, q, q + s, p + s))
	faces.append(tuple(reversed(range(s))))
	kit._mesh_obj("fang", verts, faces, kit.mat("bone"), smooth=True)


def silk():
	for k in range(3):
		kit.rope_wrap((0, 0, 0), 0.07 - k * 0.012, 0.01 + k * 0.012, 0.05 + k * 0.012, 3, thick=0.01, material=col("silk", (0.92, 0.92, 0.95), glow=0.05))


def pouch(powder_rgb, name):
	o = kit.gem((0, 0, 0.08), (0.09, 0.08, 0.08), kit.tex_mat("sack"), seed=3)
	kit.soft(o, 1)
	kit.rope_wrap((0, 0, 0), 0.04, 0.14, 0.16, 2, thick=0.007)
	kit.cone(0.04, 0.03, 0.04, (0, 0, 0.18), kit.tex_mat("sack", "b"), verts=10, bevel=0)
	p = kit.cone(0.08, 0.0, 0.04, (0.12, -0.05, 0.02), col(name, powder_rgb, rough=0.9), verts=12, bevel=0)
	kit.soft(p, 1)


def brilliant(rgb, name, size=0.1, glow=0.25, setting=False):
	"""A game gem: a six-sided crystal pointed at both ends, lying on its side (epic gems: in a silver claw setting)."""
	deep = tuple(c * 0.8 for c in rgb)
	m = col(name, deep, glow=glow * 0.5, rough=0.06, metal=0.35)
	verts, faces = [], []
	L, R = size * 1.3, size * 0.55
	for x in (-L * 0.3, L * 0.3):
		for k in range(6):
			a = 2 * math.pi * k / 6
			verts.append((x, math.cos(a) * R, math.sin(a) * R))
	verts += [(-L * 0.65, 0, 0), (L * 0.65, 0, 0)]
	for k in range(6):
		a, b = k, (k + 1) % 6
		faces.append((a, b, b + 6, a + 6))
		faces.append((12, b, a))
		faces.append((13, a + 6, b + 6))
	o = kit._mesh_obj("gem", verts, faces, m, smooth=False)
	o.rotation_euler = (math.radians(30), 0, math.radians(25))
	o.location = (0, 0, R * 0.9)
	if setting:
		kit.ring(R * 1.15, 0.014, (0, 0, R * 0.9), kit.tex_mat("silver"), rot=(0, 90, 25), seg=16)
		for k in range(4):
			a = k * math.pi / 2 + 0.4
			kit.cone(0.012, 0.004, 0.07, (math.cos(a) * 0.05, math.sin(a) * R * 1.1, R * 0.9), kit.tex_mat("silver"), rot=(0, 0, 0), verts=5)
		kit.crystal((0, 0, R * 1.5), R * 0.25, R * 0.8, kit.glow("spot", 0.3))


def rune(rgb, name):
	o = kit.tbox("stone", (0.2, 0.06, 0.26), (0, 0, 0.13), variant="b", bevel=0.02, wobble=0.004)
	kit.roughen(o, 0.004, 1, seed=3)
	g = col(name, rgb, glow=0.4, rough=0.3)
	y = -0.031
	kit.box((0.02, 0.01, 0.17), (0, y, 0.13), g, bevel=0.002, wobble=0)
	for s in (-1, 1):
		kit.box((0.018, 0.01, 0.08), (s * 0.035, y, 0.17), g, bevel=0.002, wobble=0, rot=(0, s * 40, 0))
		kit.box((0.018, 0.01, 0.07), (s * 0.035, y, 0.08), g, bevel=0.002, wobble=0, rot=(0, -s * 40, 0))
	o.rotation_euler.x = math.radians(-12)


def bottle(liquid_rgb, name):
	glass = kit.mat("water_light", -0.2, rough=0.08)
	kit.cylinder(0.06, 0.14, (0, 0, 0.07), glass, verts=12, bevel=0.02)
	kit.cylinder(0.052, 0.1, (0, 0, 0.055), col(name, liquid_rgb, glow=0.2, rough=0.1), verts=12, bevel=0.01)
	kit.cone(0.06, 0.02, 0.06, (0, 0, 0.17), glass, verts=12, bevel=0)
	kit.cylinder(0.022, 0.04, (0, 0, 0.21), kit.tex_mat("wood", "c"), verts=8, bevel=0.004)
	kit.rope_wrap((0, 0, 0), 0.025, 0.19, 0.2, 2, thick=0.005)


def bomb(rgb, name, pod=False):
	o = kit.gem((0, 0, 0.09), (0.09, 0.09, 0.085), col(name, rgb, rough=0.7), seed=4)
	kit.roughen(o, 0.01, 1, seed=4) if pod else kit.soft(o, 2)
	if not pod:
		for k in range(10):
			a, b = random.Random(k).uniform(0, 6.28), random.Random(k + 9).uniform(0.2, 1.2)
			kit.gem((math.cos(a) * math.sin(b) * 0.09, math.sin(a) * math.sin(b) * 0.09, 0.09 + math.cos(b) * 0.085), (0.015, 0.015, 0.012),
				col(name + "_d", tuple(c * 0.7 for c in rgb)), seed=k)
	kit.cylinder(0.02, 0.03, (0, 0, 0.185), kit.tex_mat("iron"), verts=8, bevel=0.003)
	kit.rope((0, 0, 0.2), (0.04, 0.0, 0.27), r=0.005)
	kit.gem((0.04, 0, 0.27), (0.012, 0.012, 0.012), kit.glow("fire", 0.8), seed=1)


def page():
	o = kit.box((0.26, 0.2, 0.006), (0, 0, 0.004), kit.tex_mat("sack", "c"), bevel=0.002, wobble=0.004)
	kit.roughen(o, 0.004, 3, seed=6)
	for k in range(4):
		kit.box((0.16 - k * 0.02, 0.004, 0.001), (-0.01, -0.05 + k * 0.03, 0.009), kit.mat("charcoal", 0.3), bevel=0, wobble=0)
	kit.cylinder(0.03, 0.002, (0.06, 0.05, 0.009), kit.mat("target_red", -0.3), verts=10, bevel=0)


def whetstone():
	kit.tbox("leather", (0.26, 0.1, 0.01), (0, 0, 0.005), variant="dark", bevel=0.003)
	o = kit.tbox("basalt", (0.2, 0.06, 0.04), (0, 0, 0.03), variant="c", bevel=0.01, wobble=0.002)
	kit.roughen(o, 0.002, 1, seed=2)


def heartstone(rgb, name, flower=False):
	lump((0.14, 0.12, 0.08), (0, 0, 0.06), kit.tex_mat("basalt"), seed=5)
	g = col(name, rgb, glow=0.8, rough=0.15)
	if flower:
		for k in range(6):
			a = 2 * math.pi * k / 6
			kit.crystal((math.cos(a) * 0.03, math.sin(a) * 0.03, 0.09), 0.025, 0.12, g, tilt=(-math.sin(a) * 45, math.cos(a) * 45, 0))
		kit.gem((0, 0, 0.12), (0.04, 0.04, 0.04), g, seed=2)
	else:
		brilliant(rgb, name + "_h", size=0.09, glow=0.8)
		bpy.context.scene.objects[-1].location.z = 0.15


def lens():
	kit.ring(0.075, 0.016, (0, 0, 0.02), kit.tex_mat("copper"), seg=24)
	o = kit.gem((0, 0, 0.02), (0.07, 0.07, 0.02), kit.mat("water_light", -0.1, rough=0.05, glow=0.1), seed=1)
	kit.soft(o, 2)


def shell_piece():
	for k in range(4):
		kit.ring(0.1 * (1 - k * 0.2), 0.03 * (1 - k * 0.15), (0, 0, 0.03 + k * 0.025), kit.tex_mat("stone", "c"), seg=18)


B = {
	"dirt": dirt, "moss": moss, "stone": lambda: rock("stone"), "clay": lambda: rock("clay"), "marble": lambda: rock("marble"),
	"basalt": lambda: rock("basalt"), "brown_rock": lambda: rock("brownrock"), "sporestone": lambda: rock("sporestone"),
	"amberrock": lambda: rock("amberrock"), "ancient_brick": lambda: bricks("brick", True),
	"copper_ore": lambda: ore("copper"), "silver_ore": lambda: ore("silver"),
	"tin_ore": lambda: ore("silver", seed=8, rock="greystone", variant="b"),  # F697: dull grey chips in grey stone
	"crystal_blue": lambda: crystal("c_blue", (0.25, 0.6, 1.0)), "crystal_green": lambda: crystal("c_green", (0.35, 0.95, 0.4)),
	"crystal_violet": lambda: crystal("c_violet", (0.6, 0.35, 1.0)), "crystal_amber": lambda: crystal("c_amber", (1.0, 0.65, 0.2)),
	"crystal_white": lambda: crystal("c_white", (0.92, 0.94, 1.0)), "crystal_red": lambda: crystal("c_red", (1.0, 0.3, 0.25)),
	"rusty_scrap": scrap, "glow_slime": lambda: blob("slime", (0.35, 0.9, 0.35), glow=0.35, size=(0.14, 0.12, 0.05), drips=True),
	"rootwood": root_log, "mushroom_wood": mush_log, "fiber": fiber, "rope": rope_coil, "leather": leather,
	"critter_hide": lambda: leather(True), "wing_leather": lambda: leather(True, "wingskin"),
	"root_tuber": tuber, "glowcap": lambda: mushroom("glow_cyan", 0.5), "hollowcap": lambda: mushroom("hollow"),
	"bellcap": lambda: mushroom("bell", 0.2, bell=True), "firecap": lambda: mushroom("fire", 0.5),
	"mushroom_flesh": flesh,
	"spore_truffle": lambda: blob("truffle", (0.3, 0.2, 0.34), size=(0.09, 0.08, 0.07), seed=7, bumps=0.02), "ember_morel": morel,
	"critter_meat": meat, "beetle_meat": lambda: meat(True), "snail_meat": snail_meat,
	"bug_meat": bug_meat,
	"chitin_plate": lambda: plate((0.22, 0.3, 0.22), "chitin"), "ironshell_plate": lambda: plate((0.4, 0.42, 0.45), "ironshell"),
	"spore_powder": lambda: pouch((0.5, 0.35, 0.6), "spores"), "needle": lambda: fang(0.32),
	"venom_sac": lambda: blob("venom", (0.4, 0.75, 0.25), glow=0.3, size=(0.1, 0.08, 0.08), seed=4),
	"glow_gland": lambda: blob("gland", (0.4, 0.95, 0.5), glow=0.45, size=(0.09, 0.08, 0.08), seed=6),
	"spitter_gill": lambda: plate((0.4, 0.55, 0.35), "gill_green", 0.26),
	"scythe_blade": lambda: curved_blade(0.36, 0.07, (0.85, 0.8, 0.7), "boneblade"),
	"gloam_scythe": lambda: curved_blade(0.42, 0.09, (0.25, 0.15, 0.3), "gloam", glow=0.15),
	"sivix_silk": silk, "bat_fang": lambda: fang(0.18), "shell_piece": shell_piece,
	"plank_root": lambda: planks("wood"), "plank_mushroom": lambda: planks("mushwood"),
	"copper_ingot": lambda: ingot("copper"), "silver_ingot": lambda: ingot("silver"),
	"clay_brick": lambda: bricks("brick"), "mushroom_brick": lambda: bricks("mushwood"),
	"cut_stone": lambda: block("stone"), "cut_marble": lambda: block("marble"), "sporestone_block": lambda: block("sporestone"),
	"amber_block": amber_block, "lantern_lens": lens,
	"keeper_heartstone": lambda: heartstone((1.0, 0.3, 0.3), "heart"), "bloomheart_core": lambda: heartstone((0.6, 1.0, 0.4), "bloom", True),
	"whetstone": whetstone, "bugbane_oil": lambda: bottle((0.85, 0.85, 0.3), "bugbane"),
	"spore_bomb": lambda: bomb((0.5, 0.3, 0.6), "sporebomb"), "blasting_pod": lambda: bomb((0.5, 0.36, 0.2), "pod", pod=True),
	"recipe_page": page,
	"rune_ochre": lambda: rune((1.0, 0.7, 0.25), "r_ochre"), "rune_crimson": lambda: rune((1.0, 0.25, 0.25), "r_crimson"),
	"rune_cobalt": lambda: rune((0.3, 0.5, 1.0), "r_cobalt"), "rune_verdant": lambda: rune((0.35, 1.0, 0.45), "r_verdant"),
}
kit.COLORS.update({"hollow": (0.55, 0.38, 0.25), "bell": (0.55, 0.7, 1.0), "wingskin": (0.25, 0.2, 0.22), "glow_cyan": (0.3, 0.9, 0.95)})
GEMS = {"ember": (1.0, 0.35, 0.2), "rime": (0.45, 0.75, 1.0), "blight": (0.4, 1.0, 0.4), "leech": (0.6, 0.1, 0.15),
	"jolt": (1.0, 0.9, 0.25), "swift": (0.7, 0.45, 1.0), "bulwark": (1.0, 0.7, 0.25), "keen": (0.95, 0.95, 1.0), "burrow": (0.55, 0.38, 0.22)}
EPIC = {"cinder_wake": (1.0, 0.45, 0.1), "hoarfrost_pulse": (0.6, 0.85, 1.0), "echoing_guard": (0.85, 0.85, 0.6),
	"rootbound_heart": (0.45, 0.75, 0.3), "bloomrot": (0.55, 0.9, 0.35), "shiftstep": (0.75, 0.5, 1.0)}
for g, rgb in GEMS.items():
	B[f"gem_{g}"] = (lambda g=g, rgb=rgb: brilliant(rgb, "gem_" + g))
for g, rgb in EPIC.items():
	B[f"gem_{g}"] = (lambda g=g, rgb=rgb: brilliant(rgb, "gem_" + g, size=0.14, glow=0.55, setting=True))

ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ids = ids or list(B)
OUT.mkdir(parents=True, exist_ok=True)
JOUR.mkdir(parents=True, exist_ok=True)
for item_id in ids:
	kit.reset()
	kit.COLORS.update({"hollow": (0.55, 0.38, 0.25), "bell": (0.55, 0.7, 1.0), "wingskin": (0.25, 0.2, 0.22)})
	try:
		B[item_id]()
		out = OUT / f"{item_id}.glb"
		kit.save(str(out), str(JOUR / f"{item_id}.png"))
		shutil.copy(out, JOUR / f"{item_id}.glb")
	except Exception as e:  # keep going; report at the end
		print(f"ITEM_FAILED {item_id}: {e!r}")
