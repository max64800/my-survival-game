# Material items remade from the night pictures materials_1..4 (F56), one object per picture cell.
#   blender --background --factory-startup --python builds/night_materials.py -- [item_id ...]   (none = all)
# Items lie on the ground: origin bottom-centre, about a hand to a forearm big. Every part touches.
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, disc, kit, log, mesh, rng  # noqa: E402

_cm = {}


def C(rgb, rough=0.6, glow=0.0, metal=0.0):
	"""A plain painted colour (for things no texture fits: gems, slime, flesh)."""
	key = (tuple(round(c, 3) for c in rgb), rough, glow, metal)
	if key in _cm:
		return _cm[key]
	m = bpy.data.materials.new("c")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*rgb, 1)
	b.inputs["Roughness"].default_value = rough
	b.inputs["Metallic"].default_value = metal
	if glow:
		b.inputs["Emission Color"].default_value = (*rgb, 1)
		b.inputs["Emission Strength"].default_value = glow
	_cm[key] = m
	return m


def lump(loc, size, m, seed=1, rough=0.02, soft=False):
	"""A chunky faceted lump (rock, ore, coal, amber)."""
	o = kit.gem(loc, size, m, seed=seed)
	kit.roughen(o, rough, 1, seed=seed)
	if soft:
		kit.soft(o, 1)
	return o


def sphere(loc, r, m, scale=(1, 1, 1), seg=14, rings=8, cut=None):
	bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=r, location=loc)
	o = bpy.context.object
	if cut is not None:
		for v in o.data.vertices:
			v.co.z = max(v.co.z, cut)
	o.scale = scale
	bpy.ops.object.transform_apply(scale=True)
	return kit._finish(o, m, 0, 0)


# ---------------- crafted (materials_1) ----------------
def rootwood():
	log((-0.17, 0, 0.08), (0.15, 0, 0.08), 0.08, T("bark"), seg=10, rings=3, end_m=kit.tex_mat("wood", "c"))
	for k in range(4):
		a = k * 1.4 + 0.3
		log((-0.14, math.cos(a) * 0.05, 0.08 + math.sin(a) * 0.05), (-0.25, math.cos(a) * 0.14, max(0.01, 0.08 + math.sin(a) * 0.1)), 0.022,
			T("bark"), seg=6, rings=2, r1=0.008, ends=False, bend=0.2)
	for k in range(3):
		kit.gem((-0.05 + k * 0.08, J(0.03), 0.155), (0.04, 0.03, 0.012), kit.mat("moss", J(0.1)), seed=k)


def plank_root():
	for i, (y, z) in enumerate(((-0.06, 0.03), (0.0, 0.03), (0.06, 0.03), (-0.03, 0.085), (0.03, 0.085))):
		B((0.34 + J(0.02), 0.055, 0.05), (J(0.015), y, z), T("wood"), bevel=0.008, rot=(J(2), J(1), J(3)))
	for x in (-0.08, 0.08):
		kit.ring(0.075, 0.012, (x, 0, 0.06), kit.tex_mat("rope"), rot=(0, 90, 0), seg=14).scale = (1, 1.2, 0.9)


def mushroom_wood():
	log((-0.16, 0, 0.08), (0.15, 0, 0.08), 0.08, kit.tex_mat("mushwood", "b"), seg=10, rings=2, end_m=kit.tex_mat("mushwood", "c"))
	for k in range(6):  # spongy holes on the end
		a = k * 1.05
		B((0.012, 0.025, 0.025), (0.165, math.cos(a) * 0.04, 0.08 + math.sin(a) * 0.04), C((0.35, 0.28, 0.2)), bevel=0.004)
	for (x, a) in ((-0.02, 0.4), (0.06, 1.2)):
		kit.cylinder(0.05, 0.012, (x, math.cos(a) * 0.06, 0.15), C((0.78, 0.62, 0.45), 0.7), verts=10, bevel=0.003)


def plank_mushroom():
	for z in (0.025, 0.075):
		B((0.3, 0.12, 0.045), (J(0.02), J(0.01), z), kit.tex_mat("mushwood", "b"), bevel=0.012, rot=(0, 0, J(4)))
		for k in range(4):
			B((0.03, 0.02, 0.012), (-0.1 + k * 0.065, J(0.03), z + 0.018), C((0.62, 0.5, 0.35)), bevel=0.003)


def rope():
	for k in range(4):
		kit.ring(0.11 - k * 0.006, 0.022, (0, 0, 0.025 + k * 0.038), kit.tex_mat("rope"), seg=22)
	log((0.1, -0.03, 0.03), (0.17, -0.1, 0.015), 0.02, kit.tex_mat("rope"), seg=6, rings=1, ends=False, bend=0)


def leather():
	for k in range(3):
		B((0.3 - k * 0.03, 0.22 - k * 0.02, 0.022), (J(0.01), J(0.01), 0.012 + k * 0.022), kit.tex_mat("leather", "a" if k % 2 else "b"),
			bevel=0.01, rot=(J(3), J(3), J(6)))
	kit.cylinder(0.022, 0.2, (0.13, 0, 0.04), kit.tex_mat("leather", "b"), rot=(90, 0, 0), verts=8, bevel=0)
	for k in range(6):
		B((0.012, 0.004, 0.004), (-0.12 + k * 0.045, -0.1, 0.067), C((0.85, 0.75, 0.5)), bevel=0)


def ingot(kind):
	o = kit.taper(0.3, 0.13, 0.24, 0.09, 0.075, (0, 0, 0), kit.tex_mat(kind, "a"), bevel=0.012)
	kit.roughen(o, 0.004, 1, seed=3)


def clay_brick():
	B((0.28, 0.13, 0.08), (0, -0.035, 0.04), T("brick"), bevel=0.012, rot=(0, 0, J(4)))
	B((0.28, 0.13, 0.08), (0.03, 0.05, 0.12), T("brick"), bevel=0.012, rot=(0, 0, 8))


def block(kind):
	o = B((0.22, 0.2, 0.18), (0, 0, 0.09), kit.tex_mat(kind, "a"), bevel=0.02, rot=(0, 0, J(5)))
	kit.roughen(o, 0.006, 1, seed=4)


def lantern_lens():
	kit.ring(0.1, 0.025, (0, 0, 0.1), kit.tex_mat("copper", "b"), rot=(90, 0, 0), seg=22)
	kit.cylinder(0.088, 0.03, (0, 0, 0.1), C((0.55, 0.85, 1.0), 0.05, glow=0.25), rot=(90, 0, 0), verts=8, bevel=0.012)
	for k in range(8):
		a = 2 * math.pi * k / 8
		kit.rivet((math.cos(a) * 0.1, -0.026, 0.1 + math.sin(a) * 0.1), kit.tex_mat("copper", "dark"), r=0.011)
	B((0.08, 0.05, 0.02), (0, 0, 0.01), kit.tex_mat("copper", "dark"), bevel=0.005)


# ---------------- raw (materials_2) ----------------
def rock(kind, size=(0.13, 0.11, 0.09), seed=2, veins=None):
	lump((0, 0, size[2]), size, kit.tex_mat(kind, "a"), seed=seed, rough=0.018)
	lump((0.08, 0.04, size[2] * 0.6), (size[0] * 0.5, size[1] * 0.5, size[2] * 0.6), kit.tex_mat(kind, "b"), seed=seed + 1, rough=0.012)
	if veins:
		for k in range(5):
			a = k * 1.3
			lump((math.cos(a) * size[0] * 0.75, math.sin(a) * size[1] * 0.75, size[2] * (1.0 + 0.3 * math.sin(k))), (0.035, 0.03, 0.025),
				veins, seed=k + 20, rough=0.006)


def clay():
	o = sphere((0, 0, 0.0), 0.13, kit.tex_mat("clay", "a"), scale=(1, 0.85, 0.6), cut=0.0)
	kit.roughen(o, 0.012, 1, seed=6)
	for (x, y) in ((0.13, 0.05), (-0.1, -0.1)):
		disc(0.035, 0.0, 0.012, (x, y), kit.tex_mat("clay", "b"), seg=10, wob=0.2)


def coal():
	m = C((0.07, 0.07, 0.08), 0.45)
	for k in range(5):
		a = k * 1.25
		r = 0.0 if k == 0 else 0.07
		lump((math.cos(a) * r, math.sin(a) * r, 0.06 if k == 0 else 0.04), (0.07, 0.06, 0.055) if k == 0 else (0.05, 0.045, 0.04),
			m, seed=k + 2, rough=0.01)


def fiber():
	for k in range(14):
		a = k * 0.45
		r = 0.03 * math.sqrt(k / 14)
		log((-0.17, math.cos(a) * r, 0.04 + math.sin(a) * r), (0.17, math.cos(a) * r * 1.5, 0.04 + math.sin(a) * r * 1.3), 0.008,
			C((0.45, 0.55, 0.2), 0.8), seg=5, rings=2, ends=False, bend=0.6)
	kit.ring(0.045, 0.012, (0.0, 0, 0.04), kit.tex_mat("rope"), rot=(0, 90, 0), seg=12)


def moss():
	o = sphere((0, 0, 0.0), 0.12, kit.tex_mat("soil", "a"), scale=(1, 0.9, 0.35), cut=0.0)
	for k in range(16):
		a, r = rng.uniform(0, 6.28), rng.uniform(0, 0.1)
		h = 0.04 * (1 - (r / 0.12) ** 2) + 0.01
		kit.gem((math.cos(a) * r, math.sin(a) * r, h), (0.03, 0.03, 0.02), kit.mat("moss", J(0.15)), seed=k)


def dirt():
	o = sphere((0, 0, 0.0), 0.13, kit.tex_mat("soil", "a"), scale=(1, 0.9, 0.5), cut=0.0)
	kit.roughen(o, 0.012, 1, seed=8)
	for k in range(5):
		a = k * 1.3
		lump((math.cos(a) * 0.12, math.sin(a) * 0.11, 0.02), (0.03, 0.028, 0.02), kit.tex_mat("soil", "b"), seed=k + 4, rough=0.006)


def amberrock():
	lump((0, 0, 0.09), (0.12, 0.1, 0.09), C((1.0, 0.55, 0.12), 0.35, glow=0.6), seed=5, rough=0.015)
	lump((0.07, 0.03, 0.05), (0.05, 0.05, 0.05), C((0.95, 0.42, 0.08), 0.35, glow=0.5), seed=6, rough=0.01)


def rusty_scrap():
	rust = kit.tex_mat("copper", "dark")
	o = kit.cylinder(0.075, 0.025, (0, 0, 0.0125), rust, verts=10, bevel=0.004)
	for k in range(10):
		a = 2 * math.pi * k / 10
		B((0.03, 0.03, 0.025), (math.cos(a) * 0.085, math.sin(a) * 0.085, 0.0125), rust, bevel=0.003, rot=(0, 0, math.degrees(a)))
	kit.cylinder(0.025, 0.03, (0, 0, 0.02), kit.mat("charcoal"), verts=8, bevel=0)
	B((0.16, 0.08, 0.012), (0.06, 0.06, 0.03), kit.tex_mat("iron", "dark"), bevel=0.003, rot=(8, 0, 30))
	kit.cylinder(0.018, 0.1, (-0.05, 0.08, 0.02), kit.tex_mat("iron", "c"), rot=(0, 90, 20), verts=6, bevel=0.002)
	kit.cylinder(0.028, 0.02, (-0.1, 0.08, 0.02), kit.tex_mat("iron", "dark"), rot=(0, 90, 20), verts=6, bevel=0.002)


# ---------------- creature parts (materials_3) ----------------
def critter_hide():
	"""A rolled-up furry hide: a fur roll with the spiral showing at both ends and a loose flap."""
	kit.cylinder(0.08, 0.22, (0, 0, 0.08), kit.tex_mat("cloth", "b"), rot=(0, 90, 0), verts=14, bevel=0.02)
	for x in (-0.112, 0.112):
		for k, r in enumerate((0.06, 0.035)):
			kit.ring(r, 0.012, (x, 0, 0.08), kit.tex_mat("cloth", "dark" if k else "a"), rot=(0, 90, 0), seg=14)
	B((0.2, 0.1, 0.02), (0, -0.1, 0.012), kit.tex_mat("cloth", "a"), bevel=0.008, rot=(0, 0, 4))


def chitin_plate(rgb=(0.2, 0.55, 0.15), studs=False):
	o = sphere((0, 0, 0.0), 0.16, C(rgb, 0.3), scale=(1.0, 0.8, 0.45), seg=16, rings=8, cut=0.0)
	kit.roughen(o, 0.004, 1, seed=3)
	dark = C(tuple(c * 0.55 for c in rgb), 0.4)
	for k, (y, ln) in enumerate(((-0.05, 0.2), (0.0, 0.24), (0.05, 0.2))):
		B((ln, 0.012, 0.012), (0, y, 0.066 - abs(y) * 0.2), dark, bevel=0.003)
	B((0.012, 0.16, 0.012), (0, 0, 0.07), dark, bevel=0.003)


def shell_piece():
	m = kit.tex_mat("limestone", "b")
	n = 22
	for i in range(n):
		t = i / n
		a = t * 4.2 * math.pi
		r = 0.12 * (1 - t * 0.85)
		kit.ring(0.015 + 0.05 * (1 - t), 0.012 + 0.018 * (1 - t), (math.cos(a) * r, 0, 0.13 + math.sin(a) * r), m, rot=(90, 0, math.degrees(a)), seg=10)
	B((0.2, 0.08, 0.03), (0, 0, 0.015), m, bevel=0.01)


def wing(rgb=(0.4, 0.2, 0.28)):
	pts = [(-0.18, 0.0), (-0.12, 0.13), (-0.04, 0.17), (0.0, 0.12), (0.06, 0.18), (0.13, 0.13), (0.19, 0.0), (0.09, 0.04), (0.0, 0.0), (-0.09, 0.04)]
	v = [(x, y, 0.01 + 0.02 * math.sin(i)) for i, (x, y) in enumerate(pts)] + [(x, y, 0.022 + 0.02 * math.sin(i)) for i, (x, y) in enumerate(pts)]
	n = len(pts)
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	mesh(v, f, C(rgb, 0.7))
	for (x, y) in pts[1:7:2] + [pts[6], pts[0]]:
		log((0, -0.02, 0.02), (x * 0.95, y * 0.95, 0.02), 0.008, C(tuple(c * 0.6 for c in rgb), 0.6), seg=5, rings=1, ends=False, bend=0)
	B((0.06, 0.05, 0.03), (0, -0.02, 0.015), C(tuple(c * 0.7 for c in rgb), 0.6), bevel=0.01)


def bat_fang():
	o = kit.cone(0.035, 0.003, 0.24, (0, 0, 0.0), kit.mat("bone", 0.1), rot=(0, 75, 0), verts=10, bevel=0)
	bpy.ops.object.select_all(action="DESELECT")
	o.location = (0.0, 0, 0.035)
	sb = o.modifiers.new("b", "SIMPLE_DEFORM")
	sb.deform_method, sb.angle, sb.deform_axis = "BEND", math.radians(40), "Y"
	lump((-0.11, 0, 0.04), (0.045, 0.045, 0.04), kit.tex_mat("leather", "b"), seed=2, rough=0.006)


def needle():
	kit.cone(0.025, 0.002, 0.3, (0.04, 0, 0.025), C((0.55, 0.8, 0.95), 0.15, glow=0.2), rot=(0, 85, 0), verts=8, bevel=0)
	kit.cylinder(0.03, 0.05, (-0.13, 0, 0.03), kit.tex_mat("silver", "a"), rot=(0, 90, 0), verts=10, bevel=0.006)


def glow_gland():
	sphere((0, 0, 0.08), 0.08, C((0.55, 0.9, 0.15), 0.15, glow=0.4))
	for k in range(4):
		a = k * 1.4 + 0.3
		tip = (math.cos(a) * 0.075, math.sin(a) * 0.075, 0.07 - k * 0.012)
		log((0.0, 0, 0.165), tip, 0.011, kit.tex_mat("leather", "b"), seg=5, rings=2, r1=0.005, ends=False, bend=0.15)
	B((0.05, 0.05, 0.03), (0, 0, 0.17), kit.tex_mat("leather", "b"), bevel=0.01)


def spitter_gill():
	for k in range(7):
		a = math.radians(-60 + k * 20)
		B((0.03, 0.17 - abs(k - 3) * 0.015, 0.012), (math.sin(a) * 0.08, -math.cos(a) * 0.08 + 0.08, 0.02 + 0.01 * (k % 2)),
			C((0.95, 0.45, 0.15), 0.5), bevel=0.006, rot=(15, 0, math.degrees(a)))
	kit.cylinder(0.025, 0.06, (0, 0.08, 0.03), C((0.85, 0.35, 0.12), 0.5), verts=8, bevel=0.005)


def ironshell_plate():
	for k in range(2):
		o = sphere((J(0.01), k * 0.02, 0.0 + k * 0.045), 0.14, kit.tex_mat("iron", "dark"), scale=(1.0, 0.85, 0.3), seg=14, rings=6, cut=0.0)
		kit.roughen(o, 0.004, 1, seed=k)
	for k in range(5):
		a = k * 1.25
		kit.gem((math.cos(a) * 0.07, 0.02 + math.sin(a) * 0.06, 0.075), (0.022, 0.022, 0.018), kit.tex_mat("iron", "c"), seed=k)


def sivix_silk():
	for k in range(2):
		kit.ring(0.07, 0.025, (k * 0.09 - 0.045, 0, 0.032), C((0.92, 0.9, 0.84), 0.4, glow=0.05), seg=18).scale = (1.0, 0.8, 1.0)
	kit.ring(0.03, 0.012, (0, 0, 0.032), C((0.85, 0.83, 0.75), 0.4), rot=(0, 90, 0), seg=10)


def spore_powder():
	o = sphere((0, 0, 0.0), 0.1, kit.tex_mat("sack", "a"), scale=(1, 1, 1.0), cut=0.0)
	kit.roughen(o, 0.01, 1, seed=3)
	kit.ring(0.045, 0.012, (0, 0, 0.1), kit.tex_mat("rope"), seg=12)
	kit.cone(0.05, 0.07, 0.04, (0, 0, 0.12), kit.tex_mat("sack", "b"), verts=10, bevel=0.004)
	disc(0.06, 0.135, 0.145, (0, 0), C((0.85, 0.75, 0.5), 0.9), seg=10)
	sphere((0.11, -0.04, 0.0), 0.045, C((0.85, 0.75, 0.5), 0.9), scale=(1, 1, 0.4), cut=0.0)


def venom_sac():
	"""A ribbed green pod with leafy claws closing over its top and a short stem."""
	o = sphere((0, 0, 0.1), 0.09, C((0.55, 0.85, 0.15), 0.3, glow=0.25), scale=(1, 1, 1.15))
	for z, r in ((0.05, 0.078), (0.1, 0.09), (0.15, 0.078)):
		kit.ring(r, 0.006, (0, 0, z), C((0.35, 0.6, 0.1), 0.4), seg=18)
	for k in range(4):
		a = k * 1.57 + 0.4
		kit.gem((math.cos(a) * 0.04, math.sin(a) * 0.04, 0.195), (0.05, 0.022, 0.012), C((0.3, 0.42, 0.12), 0.6), seed=k)
	log((0, 0, 0.19), (0.03, 0.02, 0.26), 0.014, C((0.35, 0.4, 0.15), 0.6), seg=6, rings=2, ends=False, bend=0.3)


def crystal_on_rock(rgb):
	for k in range(5):
		a = k * 1.25
		lump((math.cos(a) * 0.06, math.sin(a) * 0.05, 0.03), (0.05, 0.045, 0.03), T("stone"), seed=k + 3, rough=0.008)
	kit.gem((0, 0, 0.03), (0.08, 0.07, 0.03), kit.mat("moss", -0.1), seed=1)
	g = C(rgb, 0.15, glow=0.6)
	kit.crystal((0, 0, 0.03), 0.04, 0.22, g, sides=6)
	for (x, y, h, tx, ty) in ((-0.05, 0.02, 0.14, -20, 0), (0.05, -0.01, 0.16, 18, 5), (0.01, 0.05, 0.11, 0, -18), (-0.02, -0.05, 0.1, -8, 22)):
		kit.crystal((x, y, 0.03), 0.026, h, g, tilt=(ty, tx, 0), sides=6)


def slime():
	o = sphere((0, 0, 0.0), 0.12, C((0.5, 0.9, 0.2), 0.15, glow=0.35), scale=(1, 0.85, 0.55), cut=0.0)
	kit.roughen(o, 0.01, 1, seed=4)
	for (x, y, r) in ((0.12, 0.04, 0.035), (-0.1, -0.08, 0.03)):
		disc(r, 0.0, 0.012, (x, y), C((0.5, 0.9, 0.2), 0.15, glow=0.35), seg=10, wob=0.2)


def root_tuber():
	log((-0.12, 0, 0.06), (0.12, 0, 0.06), 0.06, kit.tex_mat("soil", "b"), seg=9, rings=3, end_m=kit.tex_mat("soil", "a"), r1=0.04)
	for k in range(6):
		a = k * 1.05
		x = -0.1 + (k % 3) * 0.1
		log((x, 0, 0.06), (x + 0.05 * math.cos(a), math.sin(a) * 0.14, 0.0), 0.012, kit.tex_mat("soil", "b"), seg=5, rings=2, r1=0.004, ends=False, bend=0.3)
	for k in range(3):
		log((-0.12, 0, 0.1), (-0.15 + J(0.03), J(0.04), 0.2), 0.006, kit.mat("sprout"), seg=5, rings=2, ends=False, bend=0.3)
		kit.gem((-0.15 + k * 0.02, J(0.03), 0.2), (0.025, 0.012, 0.01), kit.mat("sprout"), seed=k)


def shroom(cap, stem=(0.85, 0.8, 0.7), glow=0.0, holes=False, drips=False, small=True):
	sphere((0, 0, 0.0), 0.11, kit.tex_mat("soil", "a"), scale=(1, 1, 0.25), cut=0.0)
	kit.gem((0.03, 0.02, 0.02), (0.06, 0.05, 0.015), kit.mat("moss"), seed=2)
	log((0, 0, 0.0), (0, 0, 0.16), 0.035, C(stem, 0.7), seg=8, rings=2, ends=False, bend=0.1, r1=0.03)
	o = sphere((0, 0, 0.15), 0.1, C(cap, 0.45, glow=glow), scale=(1, 1, 0.6), cut=0.0)
	kit.cylinder(0.095, 0.01, (0, 0, 0.152), C(tuple(c * 0.75 for c in cap), 0.6, glow=glow * 0.5), verts=14, bevel=0)
	if holes:
		for k in range(6):
			a = k * 1.05
			B((0.02, 0.02, 0.012), (math.cos(a) * 0.06, math.sin(a) * 0.06, 0.2), C((0.25, 0.18, 0.1), 0.8), bevel=0.004)
	else:
		for k in range(5):
			a = k * 1.25
			kit.gem((math.cos(a) * 0.055, math.sin(a) * 0.055, 0.205), (0.014, 0.014, 0.008), C((0.95, 0.95, 0.85), 0.5, glow=glow), seed=k)
	if drips:
		for k in range(3):
			a = k * 2.0
			log((math.cos(a) * 0.098, math.sin(a) * 0.098, 0.152), (math.cos(a) * 0.1, math.sin(a) * 0.1, 0.11), 0.008, C(cap, 0.2, glow=glow), seg=5, rings=1, ends=False, bend=0)
	if small:
		log((0.08, -0.03, 0.01), (0.09, -0.04, 0.07), 0.012, C(stem, 0.7), seg=6, rings=1, ends=False, bend=0)
		sphere((0.09, -0.04, 0.065), 0.035, C(cap, 0.45, glow=glow), scale=(1, 1, 0.6), cut=0.0)


MODELS = {
	"rootwood": rootwood, "plank_root": plank_root, "mushroom_wood": mushroom_wood, "plank_mushroom": plank_mushroom,
	"rope": rope, "leather": leather, "copper_ingot": lambda: ingot("copper"), "silver_ingot": lambda: ingot("silver"),
	"clay_brick": clay_brick, "cut_stone": lambda: block("stone"), "cut_marble": lambda: block("marble"), "lantern_lens": lantern_lens,
	"stone": lambda: rock("stone"), "clay": clay, "marble": lambda: rock("marble"), "basalt": lambda: rock("basalt", seed=4),
	"copper_ore": lambda: rock("brownrock", veins=kit.tex_mat("copper", "a")), "silver_ore": lambda: rock("stone", seed=7, veins=kit.tex_mat("silver", "a")),
	"rusty_scrap": rusty_scrap, "coal": coal, "fiber": fiber, "moss": moss, "dirt": dirt, "amberrock": amberrock,
	"critter_hide": critter_hide, "chitin_plate": chitin_plate, "shell_piece": shell_piece, "wing_leather": lambda: wing((0.45, 0.25, 0.2)),
	"wingskin": wing, "bat_fang": bat_fang, "needle": needle, "glow_gland": glow_gland, "spitter_gill": spitter_gill,
	"ironshell_plate": ironshell_plate, "sivix_silk": sivix_silk, "spore_powder": spore_powder, "venom_sac": venom_sac,
	"crystal_blue": lambda: crystal_on_rock((0.25, 0.6, 1.0)), "crystal_green": lambda: crystal_on_rock((0.35, 0.9, 0.25)),
	"crystal_violet": lambda: crystal_on_rock((0.6, 0.3, 0.95)), "crystal_amber": lambda: crystal_on_rock((1.0, 0.65, 0.15)),
	"crystal_white": lambda: crystal_on_rock((0.92, 0.95, 1.0)), "crystal_red": lambda: crystal_on_rock((0.95, 0.2, 0.15)),
	"glow_slime": slime, "root_tuber": root_tuber,
	"glowcap": lambda: shroom((0.2, 0.8, 0.85), glow=0.6), "hollowcap": lambda: shroom((0.55, 0.38, 0.22), holes=True),
	"bellcap": lambda: shroom((0.6, 0.75, 1.0), glow=0.3, drips=True), "firecap": lambda: shroom((0.95, 0.3, 0.12), glow=0.5),
}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			out = GAME / "assets" / "models" / "items" / f"{name}.glb"
			kit.save(str(out), str(GAME / "journey" / "3d" / "v2_hand_built" / "items" / f"{name}.png"))
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
