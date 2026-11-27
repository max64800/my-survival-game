# Hand-built model kit for Blender: chunky stylized parts (stone blocks, planks, beams, metal bands,
# rivets, gems) with slightly uneven, rounded edges. Station scripts in tools/asset_forge/builds/ use it.
#
#   blender --background --factory-startup --python tools/asset_forge/builds/<name>.py -- <out.glb> [preview.png]
#
# Rules (same as forged models): meters, +Z up in Blender (= +Y in Godot), front faces -Y in Blender
# (= +Z in Godot), origin at the bottom centre. Colors are plain materials, so Godot shows them as-is.
import math
import random
import sys

import bmesh
import bpy
from mathutils import Vector

from pathlib import Path

rng = random.Random(7)
_mats = {}
# Hand-painted tiling textures (made with ChatGPT, see CREDITS.md). Variants a/b/c/dark = brightness copies.
TEX = Path(__file__).resolve().parents[2] / "assets" / "textures" / "kit"
TILE = {"stone": 0.9, "wood": 0.7, "iron": 0.5, "copper": 0.5, "bronze": 0.5, "tin": 0.5, "cloth": 0.8, "straw": 0.5,
	"leather": 0.6, "soil": 0.8, "rope": 0.22, "ropev": 0.22, "silver": 0.5, "sack": 0.75, "marble": 0.9, "basalt": 0.9, "clay": 0.9, "brownrock": 0.9, "amberrock": 0.9, "sporestone": 0.9, "brick": 0.9, "mushwood": 0.7, "shingle": 0.6, "slate": 0.6, "rooftile": 0.6, "bannercloth": 0.8, "rugcloth": 0.8, "bark": 0.6, "greywood": 0.7, "limestone": 0.9, "brickochre": 0.9, "greenpaint": 0.7, "greystone": 0.9, "warmstone": 0.9, "shackbark": 1.0, "shackplank": 1.0, "shackshingle": 1.0, "shacklogend": 1.0, "shackstone": 1.0, "shackdark": 1.0}   # meters one texture repeat covers

# Palette: earthy and a little warm (style bible: muted colors, bright only for gems/fire/magic).
COLORS = {
	"stone": (0.50, 0.47, 0.42), "stone_dark": (0.36, 0.34, 0.31), "wood": (0.52, 0.31, 0.15),
	"wood_dark": (0.36, 0.21, 0.10), "iron": (0.30, 0.31, 0.33), "copper": (0.50, 0.24, 0.10),
	"moss": (0.38, 0.45, 0.16), "gem_violet": (0.30, 0.06, 0.72), "rope": (0.66, 0.54, 0.33),
	"fire": (1.0, 0.38, 0.05), "fire_core": (1.0, 0.68, 0.18), "ember": (0.9, 0.25, 0.05), "water": (0.18, 0.4, 0.55),
	"crystal_blue": (0.25, 0.6, 1.0), "crystal_amber": (0.95, 0.5, 0.1), "rune_glow": (0.25, 0.85, 0.9),
	"mushroom_red": (0.75, 0.22, 0.12), "sprout": (0.35, 0.6, 0.2), "bone": (0.85, 0.8, 0.68),
	"linen": (0.78, 0.72, 0.6), "target_red": (0.6, 0.12, 0.08), "water_light": (0.55, 0.78, 0.9),
	"gill": (0.86, 0.78, 0.62), "spot": (0.95, 0.92, 0.85), "glow_cyan": (0.3, 0.9, 0.95), "charcoal": (0.12, 0.1, 0.09),
}


def reset():
	bpy.ops.wm.read_factory_settings(use_empty=True)
	_mats.clear()


def mat(name, shade=0.0, rough=0.85, metal=0.0, glow=0.0):
	"""A material from the palette. shade: -0.1..0.1 makes a slightly darker/lighter copy (hand-made variety)."""
	key = (name, round(shade, 2), glow)
	if key in _mats:
		return _mats[key]
	m = bpy.data.materials.new(f"{name}{'_%+.2f' % shade if shade else ''}")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	c = tuple(max(0.0, min(1.0, v * (1 + shade))) for v in COLORS[name])
	b.inputs["Base Color"].default_value = (*c, 1)
	b.inputs["Roughness"].default_value = rough
	b.inputs["Metallic"].default_value = metal
	if glow:
		b.inputs["Emission Color"].default_value = (*c, 1)
		b.inputs["Emission Strength"].default_value = glow
	_mats[key] = m
	return m


def tex_mat(kind, variant=None, metal=None, rough=None):
	"""A material showing a hand-painted texture. variant: a, b, c or dark."""
	variant = variant or rng.choice("abc")
	key = (kind, variant)
	if key in _mats:
		return _mats[key]
	m = bpy.data.materials.new(f"{kind}_{variant}")
	m.use_nodes = True
	nt = m.node_tree
	b = nt.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = rough if rough is not None else (0.45 if kind in ("iron", "copper", "bronze", "silver", "tin") else 0.9)
	b.inputs["Metallic"].default_value = metal if metal is not None else (0.6 if kind in ("iron", "copper", "bronze", "silver", "tin") else 0.0)
	t = nt.nodes.new("ShaderNodeTexImage")
	t.image = bpy.data.images.load(str(TEX / f"{kind}_{variant}.png"), check_existing=True)
	nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
	m["tile"] = TILE[kind]
	_mats[key] = m
	return m


def _uv_box(obj, tile):
	"""Wrap the texture around the part like paper on a box, same texel size everywhere."""
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.uv.cube_project(cube_size=tile, scale_to_bounds=False)
	bpy.ops.object.mode_set(mode="OBJECT")
	# Shift each part's texture a little so neighbours don't show the same spot.
	uv = obj.data.uv_layers.active.data
	du, dv = rng.random(), rng.random()
	for d in uv:
		d.uv = (d.uv[0] + du, d.uv[1] + dv)


def _finish(obj, material, bevel, wobble):
	if wobble:
		me = obj.data
		bm = bmesh.new()
		bm.from_mesh(me)
		bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True)
		for v in bm.verts:
			v.co += Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * wobble
		bm.to_mesh(me)
		bm.free()
	if bevel:
		m = obj.modifiers.new("bevel", "BEVEL")
		m.width = bevel
		m.segments = 2
		m.limit_method = "ANGLE"
	obj.data.materials.append(material)
	if "tile" in material:
		_uv_box(obj, material["tile"])
	for p in obj.data.polygons:
		p.use_smooth = False
	return obj


def box(size, loc, material, bevel=0.015, wobble=0.006, rot=(0, 0, 0)):
	"""A block: size (x, y, z) in meters, loc = its centre."""
	bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=[math.radians(a) for a in rot])
	o = bpy.context.object
	o.scale = size
	bpy.ops.object.transform_apply(scale=True)
	return _finish(o, material, bevel, wobble)


def stone(size, loc, rot_z=0.0, dark=False):
	"""A cut stone block with a slightly random shade and tilt (no two the same)."""
	r = (rng.uniform(-2, 2), rng.uniform(-2, 2), rot_z + rng.uniform(-3, 3))
	s = tuple(v * rng.uniform(0.96, 1.03) for v in size)
	return box(s, loc, tex_mat("stone", "dark" if dark else None), bevel=0.025, wobble=0.01, rot=r)


def plank(size, loc, rot=(0, 0, 0), dark=False):
	return box(size, loc, tex_mat("wood", "dark" if dark else None), bevel=0.012, wobble=0.004, rot=rot)


def tbox(kind, size, loc, rot=(0, 0, 0), variant=None, bevel=0.012, wobble=0.004):
	"""A block with a hand-painted texture (any kind: stone, wood, iron, copper, cloth, straw, leather, soil)."""
	return box(size, loc, tex_mat(kind, variant), bevel=bevel, wobble=wobble, rot=rot)


def tcyl(kind, radius, depth, loc, rot=(0, 0, 0), verts=12, variant=None, bevel=0.008):
	return cylinder(radius, depth, loc, tex_mat(kind, variant), rot=rot, verts=verts, bevel=bevel)


def ring(major, minor, loc, material, rot=(0, 0, 0), seg=24):
	"""A torus: pot rims, barrel hoops, handles."""
	bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=seg, minor_segments=6,
		location=loc, rotation=[math.radians(a) for a in rot])
	return _finish(bpy.context.object, material, 0, 0)


def cone(r1, r2, depth, loc, material, rot=(0, 0, 0), verts=10, bevel=0.006):
	bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc,
		rotation=[math.radians(a) for a in rot])
	return _finish(bpy.context.object, material, bevel, 0)


def glow(name, strength=3.0):
	"""Glowing material (fire, embers, crystals): bright color that lights itself."""
	return mat(name, glow=strength, rough=0.4)


def cylinder(radius, depth, loc, material, rot=(0, 0, 0), verts=10, bevel=0.006):
	bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc,
		rotation=[math.radians(a) for a in rot])
	return _finish(bpy.context.object, material, bevel, 0)


def rivet(loc, material=None, r=0.018):
	bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=5, radius=r, location=loc)
	o = bpy.context.object
	o.scale = (1, 1, 1)
	return _finish(o, material or mat("iron", metal=0.6, rough=0.5), 0, 0)


def band(size, loc, material, rivets=2):
	"""A metal strap plate with rivets on its front (-Y) face."""
	b = box(size, loc, material, bevel=0.006, wobble=0.002)
	x0 = loc[0] - size[0] / 2
	for i in range(rivets):
		x = x0 + size[0] * (i + 1) / (rivets + 1)
		rivet((x, loc[1] - size[1] / 2, loc[2]))
	return b


def gem(loc, size, material, seed=1):
	"""A faceted crystal lump: a jittered icosphere with flat faces."""
	bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1, location=loc)
	o = bpy.context.object
	r = random.Random(seed)
	for v in o.data.vertices:
		v.co *= r.uniform(0.8, 1.15)
	o.scale = size
	bpy.ops.object.transform_apply(scale=True)
	return _finish(o, material, 0, 0)


# ---------- organic / special parts ----------

def roughen(obj, amount=0.008, cuts=2, seed=1):
	"""Chip a part: cut it into smaller faces and nudge every corner a little (knapped stone, rough edges)."""
	r = random.Random(seed)
	bm = bmesh.new()
	bm.from_mesh(obj.data)
	bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
	for v in bm.verts:
		v.co += Vector((r.uniform(-1, 1), r.uniform(-1, 1), r.uniform(-1, 1))) * amount
	bm.to_mesh(obj.data)
	bm.free()
	return obj


def soft(obj, levels=2):
	"""Round off a part (cloth, pillows, mushroom caps): subdivision + smooth shading."""
	m = obj.modifiers.new("soft", "SUBSURF")
	m.levels = levels
	m.render_levels = levels
	for p in obj.data.polygons:
		p.use_smooth = True
	return obj


def _mesh_obj(name, verts, faces, material, smooth=True):
	me = bpy.data.meshes.new(name)
	me.from_pydata(verts, [], faces)
	me.update()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(material)
	if "tile" in material:
		_uv_box(o, material["tile"])
	for p in o.data.polygons:
		p.use_smooth = smooth
	return o


def flame(base, r, h, material, lean=(0.0, 0.0), twist=0.0, rings=7, sides=7):
	"""One curling flame tongue: wide at the bottom, swaying, ending in a sharp tip."""
	verts, faces = [], []
	for i in range(rings):
		t = i / rings
		rad = r * (1 - t) ** 0.85 * (1 + 0.18 * math.sin(t * 9 + twist))
		ox = lean[0] * t * t + 0.12 * r * math.sin(t * 6.3 + twist)
		oy = lean[1] * t * t + 0.12 * r * math.cos(t * 5.1 + twist)
		for k in range(sides):
			a = 2 * math.pi * k / sides
			verts.append((base[0] + ox + math.cos(a) * rad, base[1] + oy + math.sin(a) * rad, base[2] + t * h))
	verts.append((base[0] + lean[0] + 0.1 * r * math.sin(twist), base[1] + lean[1], base[2] + h))
	top = len(verts) - 1
	for i in range(rings - 1):
		for k in range(sides):
			a, b = i * sides + k, i * sides + (k + 1) % sides
			faces.append((a, b, b + sides, a + sides))
	last = (rings - 1) * sides
	for k in range(sides):
		faces.append((last + k, last + (k + 1) % sides, top))
	faces.append(tuple(reversed(range(sides))))
	return _mesh_obj("flame", verts, faces, material)


def fire(cx, cy, z, size=1.0, seed=1, tongues=6):
	"""A stylized fire: outer orange tongues around a taller yellow core."""
	r = random.Random(seed)
	outer, inner = glow("fire", 0.7), glow("fire_core", 0.9)
	for k in range(tongues):
		a = 2 * math.pi * k / tongues + r.uniform(-0.3, 0.3)
		d = 0.09 * size * r.uniform(0.6, 1.0)
		flame((cx + math.cos(a) * d, cy + math.sin(a) * d, z), 0.07 * size, r.uniform(0.22, 0.34) * size, outer,
			lean=(math.cos(a) * 0.05 * size, math.sin(a) * 0.05 * size), twist=r.uniform(0, 6))
	for k in range(3):
		a = 2 * math.pi * k / 3
		flame((cx + math.cos(a) * 0.03 * size, cy + math.sin(a) * 0.03 * size, z), 0.06 * size,
			r.uniform(0.36, 0.46) * size, inner, twist=r.uniform(0, 6))


def crystal(loc, r, h, material, tilt=(0, 0, 0), sides=6):
	"""A six-sided crystal with a pointed tip (built standing on loc, then tilted)."""
	verts, faces = [], []
	body = h * 0.72
	for ring_z in (0.0, body):
		for k in range(sides):
			a = 2 * math.pi * k / sides
			verts.append((math.cos(a) * r, math.sin(a) * r, ring_z))
	verts.append((0, 0, h))
	tip = len(verts) - 1
	for k in range(sides):
		a, b = k, (k + 1) % sides
		faces.append((a, b, b + sides, a + sides))
		faces.append((a + sides, b + sides, tip))
	faces.append(tuple(reversed(range(sides))))
	o = _mesh_obj("crystal", verts, faces, material, smooth=False)
	o.location = loc
	o.rotation_euler = [math.radians(v) for v in tilt]
	return o


def crystal_cluster(loc, scale, material, seed=1, n=5):
	r = random.Random(seed)
	crystal(loc, 0.05 * scale, 0.3 * scale, material, tilt=(r.uniform(-6, 6), r.uniform(-6, 6), r.uniform(0, 60)))
	for k in range(n - 1):
		a = 2 * math.pi * k / (n - 1) + r.uniform(-0.3, 0.3)
		lean = 22 + r.uniform(0, 14)
		crystal((loc[0] + math.cos(a) * 0.04 * scale, loc[1] + math.sin(a) * 0.04 * scale, loc[2]),
			0.035 * scale * r.uniform(0.7, 1.1), r.uniform(0.14, 0.24) * scale, material,
			tilt=(-math.sin(a) * lean, math.cos(a) * lean, r.uniform(0, 60)))


def mushroom(loc, s, cap="mushroom_red", seed=1):
	"""A cave mushroom: pale stem, domed cap with a lighter underside and a few spots."""
	r = random.Random(seed)
	x, y, z = loc
	stem = cone(0.045 * s, 0.032 * s, 0.22 * s, (x, y, z + 0.11 * s), mat("bone", r.uniform(-0.08, 0.03)),
		rot=(r.uniform(-8, 8), r.uniform(-8, 8), 0), verts=10)
	soft(stem, 1)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1, location=(x, y, z + 0.22 * s))
	c = bpy.context.object
	for v in c.data.vertices:
		if v.co.z < 0:
			v.co.z *= 0.25
	c.scale = (0.14 * s, 0.14 * s, 0.09 * s)
	bpy.ops.object.transform_apply(scale=True)
	_finish(c, mat(cap, r.uniform(-0.1, 0.05)), 0, 0)
	for p in c.data.polygons:
		p.use_smooth = True
	cylinder(0.12 * s, 0.01 * s, (x, y, z + 0.215 * s), mat("gill"), verts=14, bevel=0)
	for k in range(4):
		a = r.uniform(0, 6.28)
		d = r.uniform(0.03, 0.09) * s
		h = math.sqrt(max(0.0, 1 - (d / (0.14 * s)) ** 2)) * 0.088 * s
		bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=4, radius=0.018 * s,
			location=(x + math.cos(a) * d, y + math.sin(a) * d, z + 0.22 * s + h))
		sp = bpy.context.object
		sp.scale = (1, 1, 0.45)
		_finish(sp, mat("spot"), 0, 0)


def water(loc, r, ripples=2):
	"""A still water surface with faint ripple rings."""
	cylinder(r, 0.012, loc, mat("water", rough=0.05, metal=0.2, glow=0.08), verts=24, bevel=0)
	for k in range(ripples):
		ring(r * (0.25 + 0.3 * k), 0.004, (loc[0] + 0.03, loc[1], loc[2] + 0.007), mat("water_light", glow=0.1), seg=24)


def drop(loc, s=1.0):
	"""A water drop: round bottom, pointed top."""
	m = mat("water_light", rough=0.05, glow=0.25)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=0.022 * s, location=loc)
	o = bpy.context.object
	_finish(o, m, 0, 0)
	for p in o.data.polygons:
		p.use_smooth = True
	cone(0.02 * s, 0.0, 0.04 * s, (loc[0], loc[1], loc[2] + 0.025 * s), m, verts=12, bevel=0)


def rope_wrap(center, radius, z0, z1, turns, thick=0.016, axis="z", material=None):
	"""Rope wound in a spiral. axis "z" (default): around an upright post at center (x, y), from height z0 to z1.
	axis "x": around a lying log; then center = (y, z) of the log and z0..z1 are x positions."""
	if axis == "x":
		o = rope_wrap((0, 0, 0), radius, z0, z1, turns, thick, material=material)
		for v in o.data.vertices:
			x, y, z = v.co.x, v.co.y, v.co.z
			v.co = (z, center[0] + x, center[1] + y)
		return o
	return _rope_wrap_z(center, radius, z0, z1, turns, thick, material)


def _rope_wrap_z(center, radius, z0, z1, turns, thick=0.016, material=None):
	"""Rope wound around a post in a spiral (a curve turned into a tube)."""
	cu = bpy.data.curves.new("wrap", "CURVE")
	cu.dimensions = "3D"
	sp = cu.splines.new("POLY")
	n = int(turns * 16)
	sp.points.add(n)
	for i in range(n + 1):
		t = i / n
		a = t * turns * 2 * math.pi
		sp.points[i].co = (center[0] + math.cos(a) * radius, center[1] + math.sin(a) * radius, z0 + (z1 - z0) * t, 1)
	cu.bevel_depth = thick
	cu.bevel_resolution = 2
	o = bpy.data.objects.new("wrap", cu)
	bpy.context.scene.collection.objects.link(o)
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	bpy.ops.object.convert(target="MESH")
	o = bpy.context.object
	m = material or tex_mat("rope", "a")
	o.data.materials.append(m)
	_uv_box(o, m["tile"] if "tile" in m else TILE["rope"])
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def rope(p0, p1, r=0.03):
	"""A straight textured rope between two points."""
	a, b = Vector(p0), Vector(p1)
	d = b - a
	kind = "ropev" if abs(d.z) > max(abs(d.x), abs(d.y)) else "rope"
	o = cylinder(r, d.length, (0, 0, 0), tex_mat(kind, "a"), verts=10, bevel=0)
	o.rotation_mode = "QUATERNION"
	o.rotation_quaternion = d.to_track_quat("Z", "Y")
	o.location = (a + b) / 2
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def hide_tips(w, h, loc, inset=0.04):
	"""Where to tie ropes on a hide made by hide(): the 4 leg flaps, top, bottom, left, right (just inside the edge)."""
	tips = []
	for ang in (45, 135, 225, 315, 90, 270, 180, 0):
		a = math.radians(ang)
		k = 1.0 + 0.08 * math.sin(a * 3 + 1) + (0.28 if ang % 90 else 0.0)
		rx, rz = math.cos(a) * w / 2 * k * 0.8, math.sin(a) * h / 2 * k * 0.8
		d = math.hypot(rx, rz)
		f = max(0.0, d - inset) / d if d else 0
		tips.append((loc[0] + rx * f, loc[1], loc[2] + rz * f))
	return tips


def taper(w0, d0, w1, d1, h, loc, material, bevel=0.012):
	"""A block that narrows (or widens) from bottom (w0 x d0) to top (w1 x d1); loc = bottom centre."""
	x, y, z = loc
	v = [(x - w0 / 2, y - d0 / 2, z), (x + w0 / 2, y - d0 / 2, z), (x + w0 / 2, y + d0 / 2, z), (x - w0 / 2, y + d0 / 2, z),
		(x - w1 / 2, y - d1 / 2, z + h), (x + w1 / 2, y - d1 / 2, z + h), (x + w1 / 2, y + d1 / 2, z + h), (x - w1 / 2, y + d1 / 2, z + h)]
	f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
	o = _mesh_obj("taper", v, f, material, smooth=False)
	if bevel:
		m = o.modifiers.new("bevel", "BEVEL")
		m.width, m.segments = bevel, 2
	return o


def fire_spot(loc, size=1.0):
	"""An invisible marker where the GAME plays its animated fire (src/art/fire.gd). Name: fire_spot_<size>."""
	o = bpy.data.objects.new(f"fire_spot_{size:.2f}", None)
	o.location = loc
	bpy.context.scene.collection.objects.link(o)
	return o


def hide_outline(w, h, seed=3, n=40):
	"""The real edge of a hide made by hide(w, h, seed=...): n (x, z) points round it, point i at angle 360*i/n degrees.
	Tie ropes to these (F932: ropes aimed at w/2 stopped 5 cm short, the hide's edge is at about 0.8 * w/2)."""
	r = random.Random(seed)
	pts = []
	for i in range(n):
		a = 2 * math.pi * i / n
		k = 1.0 + 0.08 * math.sin(a * 3 + 1) + r.uniform(-0.04, 0.04)
		for la in (math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4):
			k += 0.28 * math.exp(-((math.atan2(math.sin(a - la), math.cos(a - la))) / 0.16) ** 2)
		pts.append((math.cos(a) * w / 2 * k * 0.8, math.sin(a) * h / 2 * k * 0.8))
	return pts


def hide(w, h, loc, material, thick=0.02, seed=3):
	"""A stretched animal hide: an uneven outline with four leg flaps, flat and slightly wavy (XZ plane)."""
	n = 40
	pts = hide_outline(w, h, seed, n)
	verts, faces = [], []
	for side in (-1, 1):
		verts.append((loc[0], loc[1] + side * thick / 2, loc[2]))
		for (x, z) in pts:
			verts.append((loc[0] + x, loc[1] + side * thick / 2 + 0.01 * math.sin(x * 9), loc[2] + z))
	m = n + 1
	for i in range(n):
		j = (i + 1) % n
		faces.append((0, 1 + j, 1 + i))
		faces.append((m, m + 1 + i, m + 1 + j))
		faces.append((1 + i, 1 + j, m + 1 + j, m + 1 + i))
	return _mesh_obj("hide", verts, faces, material, smooth=True)


def save(out, preview=None, recenter=True, tex_size=None, lid=None):
	"""Join everything into one model, put the origin at the bottom centre (unless recenter=False:
	building pieces keep their exact authored origin), export .glb (+ preview).
	lid=<height>: a chest. Everything above that height is cut off into its own part named "lid", with its
	origin on the back top edge (the hinge), so the game can swing it open (owner F345). A 1 cm seam is left
	between lid and body (no shimmer, rule 2)."""
	for o in bpy.context.scene.objects:
		o.select_set(o.type == "MESH")
	bpy.context.view_layer.objects.active = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
	for o in bpy.context.selected_objects:
		if o.type == "MESH" and not o.data.uv_layers:  # a part with no UVs, made active, would wipe everyone's textures on join
			o.data.uv_layers.new(name="UVMap")
		bpy.context.view_layer.objects.active = o
		for m in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=m.name)
	bpy.ops.object.join()
	obj = bpy.context.object
	obj.name = "model"
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	vs = [v.co for v in obj.data.vertices]
	lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
	hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
	shift = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)) if recenter else Vector((0, 0, 0))
	for v in obj.data.vertices:
		v.co -= shift
	if lid is not None:
		_cut_lid(obj, lid - shift.z)
	# Fire-spot markers move with the model and are exported as empty nodes next to it.
	spots = [o for o in bpy.context.scene.objects if o.type == "EMPTY" and o.name.startswith("fire_spot")]
	for s in spots:
		s.location -= shift
		s.select_set(True)
	if tex_size:  # smaller pictures for pieces placed by the hundred (building pieces)
		for img in bpy.data.images:
			if img.size[0] > tex_size:
				img.scale(tex_size, tex_size)
	tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
	bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="JPEG", export_image_quality=85)  # textures as JPEG: ~5x smaller files
	# Blender's JPEGs carry an EXIF block Godot 4.7 can't read (models turn white): strip it (Claude 3's fix).
	sys.path.insert(0, str(Path(__file__).resolve().parent))
	import glb_jpeg_fix
	glb_jpeg_fix.fix(out)
	d = hi - lo
	print(f"KIT_DONE {out} size {d.x:.2f} x {d.y:.2f} x {d.z:.2f} m, {tris} triangles")
	if preview:
		_preview(obj, preview)


def _cut_lid(obj, z):
	"""Split `obj` at height z: the top becomes the "lid" object (hinge at its back top edge), the cut ends are
	closed with flat faces that take the material and a flat wood-grain mapping of the part they close."""
	lid_obj = obj.copy()
	lid_obj.data = obj.data.copy()
	lid_obj.name = "lid"
	bpy.context.scene.collection.objects.link(lid_obj)
	for o, keep_top in ((obj, False), (lid_obj, True)):
		bm = bmesh.new()
		bm.from_mesh(o.data)
		cut_z = z + (0.005 if keep_top else -0.005)
		geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
		res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(0, 0, cut_z), plane_no=(0, 0, 1),
			clear_inner=keep_top, clear_outer=not keep_top)
		edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
		new = bmesh.ops.holes_fill(bm, edges=edges, sides=0)["faces"]
		uv = bm.loops.layers.uv.active
		for f in new:
			near = [g for e in f.edges for g in e.link_faces if g is not f and g not in new]
			if near:
				f.material_index = near[0].material_index
			if uv:
				for lp in f.loops:
					lp[uv].uv = (lp.vert.co.x * 1.5, lp.vert.co.y * 1.5)
		bmesh.ops.recalc_face_normals(bm, faces=new)
		bm.to_mesh(o.data)
		bm.free()
	vs = [v.co for v in lid_obj.data.vertices]
	hinge = Vector((0.0, max(v.y for v in vs), z))  # back top edge (front is -Y)
	for v in lid_obj.data.vertices:
		v.co -= hinge
	lid_obj.location = hinge
	lid_obj.select_set(True)


def _preview(obj, path):
	scene = bpy.context.scene
	engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
	scene.render.resolution_x = scene.render.resolution_y = 700
	scene.view_settings.view_transform = "Standard"  # true colors, like the game (no washed-out film look)
	w = bpy.data.worlds.new("w")
	w.use_nodes = True
	w.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.14, 0.12, 1)
	w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
	scene.world = w
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
	sun.data.energy = 3.2
	sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
	scene.collection.objects.link(sun)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	scene.collection.objects.link(cam)
	d = max(obj.dimensions)
	t = Vector((0, 0, obj.dimensions.z * 0.45))
	cam.location = t + Vector((d * 1.2, -d * 1.7, d * 0.95))
	cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.camera = cam
	scene.render.filepath = path
	bpy.ops.render.render(write_still=True)


def args():
	a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	return a[0], (a[1] if len(a) > 1 else None)
