# Stations rebuilt from the night pictures (assets/concepts/night-2026-11-15/), one object per picture,
# following each picture's "fix when modelling" note and FEEDBACK.md F34-F65.
#   blender --background --factory-startup --python builds/night_stations.py -- [name ...]   (none = all)
# Blender coords: x right, y back (the front faces -Y), z up; kit.save() puts the origin at the bottom centre.
# Rules: every part touches, nothing floats, no perfect shapes, fire is the game's effect (fire_spot).
import math
import random
import shutil
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
rng = random.Random(3)


def J(a):
	return rng.uniform(-a, a)


def T(kind, v=None):
	return kit.tex_mat(kind, v or rng.choice("abc"))


def B(size, loc, m, bevel=0.012, rot=(0, 0, 0)):
	return kit.box(size, loc, m, bevel=bevel, wobble=0, rot=rot)


def _fix(o):
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	bm.to_mesh(o.data)
	bm.free()
	return o


def mesh(verts, faces, m, smooth=False):
	return _fix(kit._mesh_obj("part", verts, faces, m, smooth=smooth))


def log(p0, p1, r, m=None, seg=8, rings=3, ends=True, bend=0.07, end_m=None, r1=None):
	"""An uneven log/pole/rod from p0 to p1 (r1 = radius at p1 for a taper)."""
	p0, p1 = Vector(p0), Vector(p1)
	d = p1 - p0
	ax = d.normalized()
	up = Vector((0, 0, 1)) if abs(ax.z) < 0.9 else Vector((1, 0, 0))
	u = ax.cross(up).normalized()
	v = ax.cross(u)
	prof = [1 + J(0.08) for _ in range(seg)]
	r1 = r if r1 is None else r1
	verts = []
	for i in range(rings + 1):
		t = i / rings
		c = p0 + d * t
		rr0 = r + (r1 - r) * t
		if 0 < i < rings:
			c = c + (u * J(1) + v * J(1)) * rr0 * bend
		for k in range(seg):
			a = 2 * math.pi * k / seg
			rr = rr0 * prof[k] * (1 + J(0.03))
			verts.append(tuple(c + u * math.cos(a) * rr + v * math.sin(a) * rr))
	faces = []
	for i in range(rings):
		for k in range(seg):
			a, b = i * seg + k, i * seg + (k + 1) % seg
			faces.append((a, b, b + seg, a + seg))
	faces.append(tuple(reversed(range(seg))))
	faces.append(tuple(range(rings * seg, (rings + 1) * seg)))
	o = mesh(verts, faces, m or T("bark"), smooth=True)
	if ends and min(r, r1) > 0.03:
		em = end_m or kit.tex_mat("wood", "c")
		for p, s_, rr in ((p0, -1, r), (p1, 1, r1)):
			log(tuple(p + ax * s_ * 0.003), tuple(p + ax * s_ * 0.012), rr * 0.8, em, seg=seg, rings=1, ends=False, bend=0)
	return o


def stone(size, loc, tone=None, rotz=0.0, bevel=0.03):
	return B((size[0] * (1 + J(0.08)), size[1] * (1 + J(0.08)), size[2] * (1 + J(0.06))), loc, tone or stone_tone(), bevel=bevel,
		rot=(J(3), J(3), rotz + J(6)))


def stone_tone():
	k = rng.random()
	return T("stone") if k < 0.6 else T("basalt", "b") if k < 0.75 else T("brownrock", "b") if k < 0.9 else T("limestone", "b")


def rivet(loc, m=None, r=0.016):
	kit.rivet(loc, m or kit.tex_mat("copper", "dark"), r=r)


def cband(size, loc, rivets=3, axis="x", face=-1, m=None, rot=(0, 0, 0)):
	"""A copper band with rivets on its front face (face -1 = -Y, +1 = +Y; axis = its long direction)."""
	m = m or kit.tex_mat("copper", "b")
	B(size, loc, m, bevel=0.005, rot=rot)
	k = {"x": 0, "z": 2, "y": 1}[axis]
	f = 1 if axis != "y" else 0
	for i in range(rivets):
		p = list(loc)
		p[k] += (i - (rivets - 1) / 2) * (size[k] - 0.08) / max(1, rivets - 1)
		p[f if axis == "y" else 1] += face * size[f if axis == "y" else 1] / 2
		rivet(tuple(p))


def plank(size, loc, rot=(0, 0, 0), m=None):
	return B((size[0] * (1 + J(0.02)), size[1], size[2]), loc, m or T("wood"), bevel=0.012, rot=(rot[0] + J(1), rot[1] + J(1), rot[2] + J(1.5)))


def ring_of(r, z, n, part):
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.1)
		part(math.cos(a) * r, math.sin(a) * r, z, a)


def ember_bed(cx, cy, z, r, n=9):
	for k in range(n):
		a, d = rng.uniform(0, 6.28), rng.uniform(0, r)
		hot = k % 3 == 0
		kit.gem((cx + math.cos(a) * d, cy + math.sin(a) * d, z + 0.02), (0.055, 0.05, 0.03),
			kit.glow("ember", 1.0) if hot else kit.mat("charcoal", rng.uniform(-0.2, 0.3)), seed=k + 11)


def disc(r, z0, z1, loc, m, seg=20, wob=0.04):
	"""A flat uneven disc (water, stew, soil patch)."""
	cx, cy = loc
	pts = [(cx + math.cos(2 * math.pi * i / seg) * r * (1 + J(wob)), cy + math.sin(2 * math.pi * i / seg) * r * (1 + J(wob))) for i in range(seg)]
	v = [(x, y, z0) for x, y in pts] + [(x, y, z1) for x, y in pts]
	f = [tuple(range(seg)), tuple(range(seg, 2 * seg))] + [(i, (i + 1) % seg, (i + 1) % seg + seg, i + seg) for i in range(seg)]
	return mesh(v, f, m, smooth=False)


def water_disc(r, z, loc, depth=0.03):
	"""Water with a gradient: a deep dark layer and a lighter, smaller top with a pale ring (F40)."""
	disc(r, z - depth, z - 0.006, loc, kit.mat("water", -0.25, rough=0.15))
	disc(r * 0.82, z - 0.007, z, loc, kit.mat("water", 0.05, rough=0.1))
	disc(r * 0.45, z - 0.0005, z + 0.002, loc, kit.mat("water_light", -0.1, rough=0.1), seg=16, wob=0.1)


def stream(p0, p1, r=0.012):
	"""A thin falling stream of water joining two things (so nothing floats)."""
	log(p0, p1, r, kit.mat("water_light", 0.0, rough=0.1), seg=6, rings=2, ends=False, bend=0.15)


# =====================================================================================
def twin_smelter():
	"""Two stone furnaces joined by a stone bridge with a chimney, leather bellows between them,
	a stone ledge with crucibles, an ingot mould and ore, on a stone plinth with copper bands."""
	W = 2.5
	# plinth
	B((W, 1.1, 0.16), (0, 0, 0.08), T("basalt", "b"), bevel=0.03)
	for x in (-W / 2 + 0.3, -0.4, 0.4, W / 2 - 0.3):
		pass
	cband((W + 0.02, 0.05, 0.08), (0, -0.55, 0.1), rivets=8)
	B((W - 0.1, 0.12, 0.12), (0, -0.5, 0.22), T("wood", "dark"), bevel=0.015)  # timber kerb
	for cx in (-0.72, 0.72):
		furnace_dome(cx, 0.05, 0.16)
	# bellows in a wooden frame between the domes
	for x in (-0.28, 0.28):
		B((0.1, 0.1, 0.95), (x, 0.1, 0.16 + 0.475), T("wood", "b"), bevel=0.015)
	B((0.66, 0.12, 0.1), (0, 0.1, 1.12), T("wood", "dark"), bevel=0.015)
	for k in range(5):
		z = 0.32 + k * 0.1
		B((0.44 - (k % 2) * 0.05, 0.42 - (k % 2) * 0.05, 0.1), (0, 0.06, z), kit.tex_mat("leather", "dark" if k % 2 else "a"), bevel=0.02)
	B((0.5, 0.48, 0.05), (0, 0.06, 0.82), T("wood", "c"), bevel=0.012)
	B((0.5, 0.48, 0.05), (0, 0.06, 0.25), T("wood", "c"), bevel=0.012)
	log((0, 0.06, 0.85), (0, -0.08, 1.12), 0.035, T("wood", "dark"), seg=6, rings=1)  # lever up to the cross bar
	log((-0.1, -0.12, 1.06), (0.1, -0.12, 1.1), 0.03, T("wood", "c"), seg=6, rings=1)
	# stone ledge across the front with crucibles, mould and ore
	z = 0.3
	for i in range(5):
		x = -W / 2 + 0.25 + i * (W - 0.5) / 4
		stone((0.5, 0.36, 0.14), (x, -0.42, 0.22))
	for i in range(6):
		x = -W / 2 + 0.22 + i * (W - 0.44) / 5
		stone((0.42, 0.4, 0.07), (x, -0.42, z), tone=T("stone", "c"), bevel=0.02)
	for cx in (-0.72, 0.72):
		crucible((cx, -0.45, z + 0.035))
	B((0.32, 0.18, 0.06), (0.0, -0.45, z + 0.065), kit.tex_mat("iron"), bevel=0.008)  # ingot mould
	for dx in (-0.075, 0.075):
		B((0.11, 0.1, 0.02), (dx, -0.45, z + 0.09), kit.mat("charcoal", -0.2), bevel=0.003)
	for (x, mm) in ((-0.35, "iron"), (-0.27, "iron"), (0.3, "copper")):
		kit.gem((x, -0.47, z + 0.075), (0.05, 0.045, 0.04), kit.tex_mat(mm, "dark") if mm == "iron" else kit.tex_mat("copper", "a"), seed=int(x * 100) + 50)
	# stone bridge over the bellows joining the two domes, with a chimney on top
	for i in range(7):
		t = (i + 0.5) / 7
		x = -0.5 + t * 1.0
		zz = 1.02 + math.sin(t * math.pi) * 0.14
		stone((0.18, 0.36, 0.22), (x, 0.06, zz), rotz=0)
	for x in (-0.42, 0.42):
		cband((0.06, 0.4, 0.26), (x, 0.06, 1.06), rivets=1, axis="z")
	kit.tcyl("stone", 0.18, 0.32, (0, 0.06, 1.3), verts=10, variant="b")
	kit.ring(0.19, 0.03, (0, 0.06, 1.44), kit.tex_mat("copper", "b"), seg=14)
	kit.cylinder(0.13, 0.02, (0, 0.06, 1.46), kit.mat("charcoal"), verts=10, bevel=0)


def furnace_dome(cx, cy, z0, r=0.52, h=1.0):
	"""A round beehive furnace: a bumpy stone dome with a copper ring round its top opening, big foot stones,
	and an arched glowing mouth at the front."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=9, radius=1, location=(cx, cy, z0))
	d = bpy.context.object
	for v in d.data.vertices:
		if v.co.z < 0:
			v.co.z = 0
		if v.co.z > 0.86:
			v.co.z = 0.86
	d.scale = (r, r * 0.95, h)
	bpy.ops.object.transform_apply(scale=True)
	kit._finish(d, T("stone", "b"), 0, 0)
	kit.roughen(d, 0.025, 1, seed=int(cx * 10) + 7)
	# course lines: thin dark mortar rings so it reads as stacked stone
	for t in (0.25, 0.5, 0.7):
		zz = z0 + h * t
		rr = r * math.sqrt(max(0.0, 1 - t * t)) + 0.004
		kit.ring(rr, 0.012, (cx, cy, zz), kit.mat("charcoal", 0.3), seg=20)
	top_r = r * math.sqrt(1 - 0.86 ** 2)
	kit.ring(top_r + 0.01, 0.04, (cx, cy, z0 + h * 0.86), kit.tex_mat("copper", "b"), seg=16)
	kit.cylinder(top_r - 0.01, 0.02, (cx, cy, z0 + h * 0.86 + 0.005), kit.mat("charcoal"), verts=12, bevel=0)
	n = 10
	for k in range(n):
		a = 2 * math.pi * k / n
		if abs(math.atan2(math.sin(a + math.pi / 2), math.cos(a + math.pi / 2))) < 0.5:
			continue
		stone((0.3, 0.2, 0.24), (cx + math.cos(a) * (r - 0.03), cy + math.sin(a) * (r - 0.03), z0 + 0.12), rotz=math.degrees(a) + 90)
	kit.ring(r + 0.005, 0.03, (cx, cy, z0 + 0.27), kit.tex_mat("copper", "b"), seg=22)
	my = cy - r + 0.1
	B((0.38, 0.3, 0.42), (cx, my + 0.02, z0 + 0.21), kit.mat("charcoal", -0.4), bevel=0.02)
	ember_bed(cx, my - 0.05, z0, 0.12, n=6)
	kit.fire_spot((cx, my - 0.05, z0 + 0.08), 0.4)
	for ang in (-80, -45, 0, 45, 80):
		a = math.radians(ang)
		stone((0.14, 0.2, 0.13), (cx + math.sin(a) * 0.25, my - 0.1, z0 + 0.24 + math.cos(a) * 0.2), rotz=0)


def crucible(loc):
	x, y, z = loc
	kit.cone(0.055, 0.075, 0.09, (x, y, z + 0.045), kit.tex_mat("copper", "a"), verts=12, bevel=0.004)
	disc(0.06, z + 0.07, z + 0.085, (x, y), kit.glow("ember", 1.4), seg=10)


# =====================================================================================
def gem_bench():
	"""Gem cutter's bench: heavy timber bench with copper corners, a treadle grinding wheel, a box tray of
	coloured gems, a magnifying glass on a jointed copper arm, a crystal in a holder, a hanging red cloth."""
	W, D, H = 1.25, 0.72, 0.82
	for x in (-W / 2 + 0.1, W / 2 - 0.1):
		for y in (-D / 2 + 0.1, D / 2 - 0.1):
			stone((0.2, 0.2, 0.08), (x, y, 0.04), tone=T("stone"), bevel=0.02)
			B((0.14, 0.14, H - 0.12), (x + J(0.01), y, 0.08 + (H - 0.12) / 2), T("wood", "b"), bevel=0.02)
			cband((0.155, 0.155, 0.06), (x, y, 0.2), rivets=1)
	for y in (-D / 2 + 0.1, D / 2 - 0.1):
		B((W - 0.2, 0.08, 0.1), (0, y, 0.28), T("wood", "dark"), bevel=0.012)
	for i in range(5):
		y = -D / 2 + D * (i + 0.5) / 5
		plank((W + 0.06, D / 5 - 0.01, 0.08), (0, y, H - 0.02))
	for x in (-W / 2 - 0.02, W / 2 + 0.02):
		for y in (-D / 2 - 0.02, D / 2 + 0.02):
			B((0.1, 0.1, 0.1), (x * 0.97, y * 0.97, H - 0.03), kit.tex_mat("copper", "b"), bevel=0.008)
	# apron and drawer at the front
	B((W - 0.24, 0.05, 0.16), (0, -D / 2 + 0.06, H - 0.14), T("wood", "dark"), bevel=0.01)
	B((0.34, 0.05, 0.1), (0.25, -D / 2 + 0.035, H - 0.14), T("wood", "c"), bevel=0.01)
	B((0.12, 0.02, 0.03), (0.25, -D / 2 + 0.005, H - 0.14), kit.tex_mat("copper", "b"), bevel=0.004)
	# hanging red cloth over the front edge
	mesh_cloth((-0.12, -D / 2 - 0.012), H + 0.02, 0.26, 0.24)
	# treadle grinding wheel on the left
	gx = -W / 2 + 0.22
	kit.cylinder(0.2, 0.06, (gx, -0.06, H + 0.16), T("stone", "c"), rot=(0, 90, 0), verts=20, bevel=0.01)
	for y in (-0.16, 0.04):
		B((0.06, 0.05, 0.22), (gx, y, H + 0.09), T("wood", "dark"), bevel=0.008)
	log((gx - 0.06, -0.06, H + 0.16), (gx + 0.12, -0.06, H + 0.16), 0.018, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	log((gx - 0.06, -0.06, H + 0.16), (gx - 0.06, -0.12, H + 0.06), 0.014, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	log((gx - 0.06, -0.12, H + 0.06), (gx - 0.06, -D / 2 - 0.08, 0.1), 0.012, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	plank((0.22, 0.14, 0.04), (gx + 0.02, -D / 2 - 0.08, 0.09), m=T("wood", "c"))  # treadle
	B((0.04, 0.12, 0.06), (gx + 0.02, -D / 2 + 0.04, 0.07), kit.tex_mat("iron"), bevel=0.004)
	# gem tray box at the back with 6 compartments
	tx, ty = 0.05, D / 2 - 0.16
	B((0.5, 0.26, 0.04), (tx, ty, H + 0.04), T("wood", "dark"), bevel=0.008)
	for x in (-0.25, -0.083, 0.083, 0.25):
		B((0.025, 0.26, 0.1), (tx + x, ty, H + 0.09), T("wood", "b"), bevel=0.005)
	for y in (-0.13, 0.0, 0.13):
		B((0.5, 0.025, 0.1), (tx, ty + y, H + 0.09), T("wood", "b"), bevel=0.005)
	cols = [(1.0, 0.1, 0.1), (0.15, 0.4, 1.0), (0.1, 0.8, 0.2), (0.6, 0.2, 0.9), (1.0, 0.6, 0.1), (0.9, 0.15, 0.2)]
	for i in range(6):
		cx = tx + (-0.166 + (i % 3) * 0.166)
		cy = ty + (-0.065 if i < 3 else 0.065)
		mm = gem_mat(cols[i])
		for k in range(3):
			kit.gem((cx + J(0.03), cy + J(0.025), H + 0.08), (0.03, 0.03, 0.028), mm, seed=i * 5 + k)
	# magnifier on a jointed copper arm (back right)
	mx, my = W / 2 - 0.2, D / 2 - 0.15
	kit.cylinder(0.07, 0.03, (mx, my, H + 0.035), kit.tex_mat("copper", "b"), verts=12, bevel=0.005)
	a1 = (mx, my, H + 0.05)
	a2 = (mx - 0.02, my - 0.05, H + 0.36)
	a3 = (mx - 0.2, my - 0.12, H + 0.42)
	for p, q in ((a1, a2), (a2, a3)):
		log(p, q, 0.016, kit.tex_mat("copper", "b"), seg=6, rings=1, ends=False, bend=0)
	for p in (a2, a3):
		kit.rivet(p, kit.tex_mat("copper", "dark"), r=0.028)
	kit.ring(0.09, 0.014, (a3[0] - 0.07, a3[1], a3[2] - 0.05), kit.tex_mat("copper", "b"), rot=(90, 0, 0), seg=18)
	kit.cylinder(0.085, 0.008, (a3[0] - 0.07, a3[1], a3[2] - 0.05), kit.mat("water_light", 0.1, rough=0.05), rot=(90, 0, 0), verts=16, bevel=0)
	log((a3[0] - 0.005, a3[1], a3[2]), (a3[0] - 0.05, a3[1], a3[2] - 0.035), 0.012, kit.tex_mat("copper", "b"), seg=6, rings=1, ends=False, bend=0)
	# crystal in a copper holder (back left corner)
	hx, hy = -W / 2 + 0.2, D / 2 - 0.12
	kit.cylinder(0.07, 0.07, (hx, hy, H + 0.06), kit.tex_mat("copper", "b"), verts=10, bevel=0.005)
	kit.crystal_cluster((hx, hy, H + 0.09), 0.5, kit.glow("crystal_amber", 0.5), seed=4, n=4)
	# a dagger blank clamped in a small vise on the right
	vx = 0.38
	B((0.12, 0.14, 0.1), (vx, -0.05, H + 0.07), kit.tex_mat("iron"), bevel=0.01)
	B((0.04, 0.14, 0.08), (vx - 0.07, -0.05, H + 0.09), kit.tex_mat("iron", "dark"), bevel=0.006)
	B((0.3, 0.012, 0.05), (vx - 0.2, -0.05, H + 0.1), kit.tex_mat("iron", "a"), bevel=0.003)
	B((0.03, 0.08, 0.03), (vx - 0.04, -0.05, H + 0.1), kit.tex_mat("copper", "b"), bevel=0.004)
	kit.gem((vx - 0.04, -0.09, H + 0.1), (0.018, 0.012, 0.018), gem_mat((1, 0.1, 0.1)), seed=3)
	# a leather tool roll on the lower rail
	log((-0.25, -D / 2 + 0.1, 0.36), (0.15, -D / 2 + 0.1, 0.36), 0.045, kit.tex_mat("leather"), seg=8, rings=1, end_m=kit.tex_mat("leather", "dark"))


def gem_mat(rgb):
	m = bpy.data.materials.new("gem")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*rgb, 1)
	b.inputs["Roughness"].default_value = 0.2
	b.inputs["Emission Color"].default_value = (*rgb, 1)
	b.inputs["Emission Strength"].default_value = 0.35
	return m


def mesh_cloth(xy, ztop, w, h, m=None):
	"""A cloth hanging over an edge: a wavy sheet with a ragged bottom (XZ plane at y)."""
	x0, y = xy
	m = m or kit.tex_mat("bannercloth")
	n = 8
	verts = []
	for j in range(4):
		zz = ztop - h * j / 3
		for i in range(n + 1):
			xx = x0 - w / 2 + w * i / n
			rag = J(0.03) if j == 3 else 0
			verts.append((xx, y - 0.005 * math.sin(i * 1.7 + j), zz + rag))
	faces = []
	for j in range(3):
		for i in range(n):
			a = j * (n + 1) + i
			faces.append((a, a + 1, a + n + 2, a + n + 1))
	o = mesh(verts, faces, m)
	sol = o.modifiers.new("t", "SOLIDIFY")
	sol.thickness = 0.012
	# drape over the bench top
	B((w, 0.06, 0.012), (x0, y + 0.03, ztop + 0.004), m, bevel=0.002)
	return o


# =====================================================================================
def drip_bucket():
	"""A stave bucket with rope bands on stones, a copper funnel on a lashed post feeding it a thin stream."""
	R, H = 0.24, 0.36
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.4
		stone((0.16, 0.14, 0.09), (math.cos(a) * 0.18, math.sin(a) * 0.18, 0.045), tone=T("stone"))
	z0 = 0.08
	B((R * 1.7, R * 1.7, 0.04), (0, 0, z0 + 0.02), T("wood", "dark"), bevel=0.01)
	n = 14
	for k in range(n):
		a = 2 * math.pi * k / n
		B((2 * math.pi * R / n * 1.04, 0.04, H + J(0.015)), (math.cos(a) * R, math.sin(a) * R, z0 + H / 2), T("wood"), bevel=0.006,
			rot=(0, 0, math.degrees(a) + 90))
	for z in (z0 + 0.07, z0 + H - 0.08):
		kit.ring(R + 0.022, 0.018, (0, 0, z), kit.tex_mat("rope"), seg=24)
	water_disc(R - 0.02, z0 + H - 0.05, (0, 0))
	# post with a funnel
	px = R + 0.08
	log((px, 0.0, 0.0), (px, 0.0, 0.78), 0.045, T("wood", "b"), seg=8, rings=2, end_m=kit.tex_mat("wood", "c"))
	kit.rope_wrap((px, 0.0), 0.05, z0 + 0.05, z0 + 0.14, 3, thick=0.012, material=kit.tex_mat("rope"))  # lashed to the bucket
	log((px, 0, 0.68), (0.02, 0, 0.68), 0.025, T("wood", "dark"), seg=6, rings=1)
	kit.rope_wrap((px, 0.0), 0.05, 0.64, 0.72, 3, thick=0.012, material=kit.tex_mat("rope"))
	kit.cone(0.09, 0.025, 0.12, (0, 0, 0.66), kit.tex_mat("copper", "b"), verts=14, bevel=0.004)
	kit.ring(0.09, 0.012, (0, 0, 0.72), kit.tex_mat("copper", "dark"), seg=16)
	stream((0, 0, 0.6), (0, 0, z0 + H - 0.05))


def copper_drip_basin():
	"""A riveted copper basin on a stone plinth with a carved knot, a copper hoop holding a funnel above it,
	a spout pouring into a mug on a side stone (F40: water with depth and light, not one flat shade)."""
	R = 0.42
	for k in range(7):
		a = 2 * math.pi * k / 7
		stone((0.32, 0.26, 0.3), (math.cos(a) * 0.22, math.sin(a) * 0.22, 0.15))
	kit.cylinder(0.26, 0.3, (0, 0, 0.15), kit.mat("charcoal", 0.4), verts=12, bevel=0)
	stone((0.3, 0.12, 0.3), (0, -0.33, 0.16), tone=T("stone", "c"), bevel=0.02)  # knot panel
	for (dx, dz, ang) in ((-0.05, 0.05, 45), (0.05, 0.05, -45), (-0.05, -0.05, -45), (0.05, -0.05, 45)):
		B((0.12, 0.02, 0.025), (dx, -0.39, 0.16 + dz), T("stone", "dark"), bevel=0.004, rot=(0, ang, 0))
	z = 0.32
	kit.cone(0.26, R, 0.2, (0, 0, z + 0.1), kit.tex_mat("copper", "a"), verts=20, bevel=0.01)
	kit.ring(R, 0.03, (0, 0, z + 0.2), kit.tex_mat("copper", "b"), seg=24)
	kit.ring(R - 0.08, 0.022, (0, 0, z + 0.08), kit.tex_mat("copper", "dark"), seg=22)
	for k in range(10):
		a = 2 * math.pi * k / 10
		rivet((math.cos(a) * (R - 0.08), math.sin(a) * (R - 0.08), z + 0.1))
	water_disc(R - 0.03, z + 0.215, (0, 0), depth=0.02)
	# spout and mug on a side stone
	log((R - 0.02, -0.05, z + 0.12), (R + 0.12, -0.05, z + 0.09), 0.028, kit.tex_mat("copper", "b"), seg=8, rings=1, ends=False, bend=0)
	stone((0.2, 0.2, 0.26), (R + 0.16, -0.05, 0.13), tone=T("stone"))
	kit.cylinder(0.045, 0.08, (R + 0.16, -0.05, 0.3), kit.tex_mat("copper", "a"), verts=10, bevel=0.004)
	kit.ring(0.03, 0.01, (R + 0.21, -0.05, 0.3), kit.tex_mat("copper", "b"), rot=(90, 0, 0), seg=10)
	stream((R + 0.13, -0.05, z + 0.09), (R + 0.16, -0.05, 0.33), r=0.009)
	# copper hoop over the basin with a funnel hanging in the middle
	pts = []
	for i in range(13):
		t = i / 12
		a = math.pi * t
		pts.append((-math.cos(a) * (R - 0.02), 0.0, z + 0.2 + math.sin(a) * 0.55))
	for p, q in zip(pts, pts[1:]):
		log(p, q, 0.022, kit.tex_mat("copper", "b"), seg=6, rings=1, ends=False, bend=0)
	for p in pts[::3]:
		rivet(p, r=0.026)
	top = pts[6]
	log(top, (0, 0, top[2] - 0.12), 0.012, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	kit.cone(0.08, 0.02, 0.1, (0, 0, top[2] - 0.17), kit.tex_mat("copper", "b"), verts=14, bevel=0.004)
	kit.ring(0.08, 0.01, (0, 0, top[2] - 0.12), kit.tex_mat("copper", "dark"), seg=14)
	stream((0, 0, top[2] - 0.22), (0, 0, z + 0.215))
	for (x, y) in ((-0.2, 0.36), (0.25, 0.3)):
		kit.gem((x, y, 0.31), (0.06, 0.03, 0.02), kit.mat("moss"), seed=int(x * 10) + 9)


def crystal_sconce():
	"""A standing carved stone slab (spiral and rune grooves) holding a glowing blue crystal in a riveted copper cage."""
	H = 0.72
	B((0.34, 0.24, 0.07), (0, 0.02, 0.035), T("stone", "dark"), bevel=0.02)
	B((0.3, 0.12, H - 0.15), (0, 0.06, 0.07 + (H - 0.15) / 2), T("stone"), bevel=0.03)
	kit.cylinder(0.15, 0.12, (0, 0.06, H - 0.08), T("stone"), rot=(90, 0, 0), verts=14, bevel=0.02)
	# carved spiral (a stepped groove of small dark blocks) and a rune
	for i in range(16):
		a = i * 0.55
		r = 0.02 + i * 0.006
		B((0.03, 0.02, 0.018), (math.cos(a) * r, -0.005, 0.2 + math.sin(a) * r), T("stone", "dark"), bevel=0.003)
	for (x, z, rz) in ((0, 0.6, 0), (-0.03, 0.62, 40), (0.03, 0.62, -40)):
		B((0.012, 0.012, 0.08), (x, -0.003, z), T("stone", "dark"), bevel=0.002, rot=(0, rz, 0))
	kit.gem((-0.12, -0.01, 0.12), (0.05, 0.02, 0.06), kit.mat("moss"), seed=2)
	# bracket and cage
	B((0.1, 0.12, 0.06), (0, -0.06, 0.36), kit.tex_mat("copper", "b"), bevel=0.008)
	cz = 0.43
	kit.cone(0.09, 0.05, 0.1, (0, -0.15, cz - 0.03), kit.tex_mat("copper", "b"), verts=10, bevel=0.005)
	kit.crystal((0, -0.15, cz), 0.06, 0.26, kit.glow("crystal_blue", 0.7), tilt=(0, 0, 0), sides=6)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		x, y = math.cos(a) * 0.075, -0.15 + math.sin(a) * 0.075
		B((0.02, 0.02, 0.2), (x, y, cz + 0.08), kit.tex_mat("copper", "b"), bevel=0.003)
	kit.ring(0.08, 0.012, (0, -0.15, cz + 0.17), kit.tex_mat("copper", "b"), seg=12)
	B((0.04, 0.1, 0.03), (0, -0.09, cz + 0.17), kit.tex_mat("copper", "b"), bevel=0.004)
	kit.ring(0.09, 0.014, (0, -0.15, cz + 0.02), kit.tex_mat("copper", "dark"), seg=12)


def glow_marker():
	"""A pointed wooden stake with a copper cup, a glowing fungus bulb on top (not a flame), and a red rag tied on."""
	log((0, 0, 0.0), (0, 0, 1.05), 0.012, T("wood", "b"), seg=8, rings=1, ends=False, bend=0, r1=0.05)
	log((0, 0, 0.12), (0, 0, 1.05), 0.05, T("wood", "b"), seg=8, rings=2, ends=False)
	kit.cone(0.065, 0.1, 0.12, (0, 0, 1.1), kit.tex_mat("copper", "b"), verts=12, bevel=0.005)
	kit.ring(0.1, 0.014, (0, 0, 1.16), kit.tex_mat("copper", "dark"), seg=14)
	for k in range(4):
		a = k * math.pi / 2 + 0.3
		rivet((math.cos(a) * 0.08, math.sin(a) * 0.08, 1.1))
	# fungus bulb: a cluster of glowing caps
	glow = kit.glow("crystal_amber", 0.8)
	for (x, y, z, s) in ((0, 0, 1.22, 0.11), (0.06, 0.03, 1.28, 0.07), (-0.05, -0.02, 1.3, 0.08), (0.01, -0.05, 1.36, 0.06)):
		kit.cylinder(0.02, z - 1.15, (x * 0.5, y * 0.5, 1.15 + (z - 1.15) / 2), kit.mat("gill", 0.1), verts=6, bevel=0)
		bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=s, location=(x, y, z))
		o = bpy.context.object
		o.scale = (1, 1, 0.55)
		bpy.ops.object.transform_apply(scale=True)
		kit._finish(o, glow, 0, 0)
	# a red rag tied below the cup
	kit.ring(0.055, 0.018, (0, 0, 0.88), kit.tex_mat("bannercloth"), seg=12)
	for (dx, ang) in ((0.06, 15), (0.09, -10)):
		B((0.06, 0.012, 0.22), (dx, -0.04, 0.78), kit.tex_mat("bannercloth"), bevel=0.003, rot=(8, ang, 0))


MODELS = {
	"twin_smelter": twin_smelter, "gem_bench": gem_bench, "drip_bucket": drip_bucket,
	"copper_drip_basin": copper_drip_basin, "crystal_sconce": crystal_sconce, "glow_marker": glow_marker,
}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		try:
			MODELS[name]()
			out = GAME / "assets" / "models" / "stations" / f"{name}.glb"
			jdir = GAME / "journey" / "3d" / "v2_hand_built" / "stations"
			kit.save(str(out), str(jdir / f"{name}.png"))
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
