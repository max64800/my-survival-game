# Creature add-on for the hand-built model kit (kit.py, by Claude 2). By Claude 3.
#
# kit.save() melts everything into one piece, which is right for an anvil, but a creature's legs,
# wings and soft body must move in the game. So parts made inside `with part("leg_l0", hinge)`
# stay separate, named pieces, each turning around its hinge (hip, shoulder, shell mouth).
#
# The game (src/combat/monster_model.gd) looks for these names:
#   leg*    walks (swings forward/back)       wing_l / wing_r   flaps (around the forward axis)
#   soft*   shrinks into the shell (snail)    material "eye"    the eyes that flash before an attack
# Everything else becomes "body".
#
# Same rules as kit.py: meters, +Z up, the creature FACES -Y in Blender (= +Z in Godot; the game turns
# it), origin at the bottom centre.
import math
import random
import sys
from contextlib import contextmanager
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402

_parts = {}    # part name -> hinge (Vector)
_current = ["body"]


def reset():
	kit.reset()
	_parts.clear()
	_parts["body"] = Vector((0, 0, 0))
	_current[0] = "body"


@contextmanager
def part(name, hinge=(0, 0, 0)):
	"""Everything made inside this block becomes one movable piece turning around `hinge`."""
	before = set(bpy.context.scene.objects)
	_parts[name] = Vector(hinge)
	yield
	for o in set(bpy.context.scene.objects) - before:
		o["part"] = name


def color(name, rgb, rough=0.8, glow=0.0, metal=0.0):
	"""Add a color to the kit palette and return its material."""
	kit.COLORS[name] = rgb
	return kit.mat(name, rough=rough, glow=glow, metal=metal)


CTEX = Path(__file__).resolve().parents[2] / "assets" / "textures" / "creatures"


def skin(name, tile=0.5, rough=0.8, metal=0.0):
	"""A material with one of the creature textures (made by creature_textures.py)."""
	key = ("skin", name)
	if key in kit._mats:
		return kit._mats[key]
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	nt = m.node_tree
	b = nt.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = rough
	b.inputs["Metallic"].default_value = metal
	t = nt.nodes.new("ShaderNodeTexImage")
	t.image = bpy.data.images.load(str(CTEX / f"{name}.png"), check_existing=True)
	nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
	m["tile"] = tile
	kit._mats[key] = m
	return m


def eye_mat(rgb=(1.0, 0.82, 0.35)):
	"""The eyes: the game finds this material by name to make it flash (and turn red on a charge)."""
	m = bpy.data.materials.get("eye") or bpy.data.materials.new("eye")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*rgb, 1)
	b.inputs["Emission Color"].default_value = (*rgb, 1)
	b.inputs["Emission Strength"].default_value = 0.6
	b.inputs["Roughness"].default_value = 0.2
	return m


def _frame(tangent, up=Vector((0, 0, 1))):
	t = tangent.normalized()
	if abs(t.dot(up)) > 0.95:
		up = Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0))
	side = t.cross(up).normalized()
	n = side.cross(t).normalized()
	return side, n


def loft(name, rings, material, sides=12, caps=(True, True), smooth=True, up=Vector((0, 0, 1)), subsurf=1, wobble=0.0, seed=1):
	"""A smooth organic tube through `rings`: each ring = (centre, width, height[, twist_deg]).
	Width runs sideways, height runs "up" (relative to `up`). Like pulling clay through rings."""
	r = random.Random(seed)
	pts = [Vector(c[0]) for c in rings]
	verts, faces = [], []
	for i, c in enumerate(rings):
		p = pts[i]
		tan = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)])
		side, n = _frame(tan, up)
		w, h = c[1], c[2]
		tw = math.radians(c[3]) if len(c) > 3 else 0.0
		for k in range(sides):
			a = 2 * math.pi * k / sides + tw
			j = 1 + (r.uniform(-1, 1) * wobble if wobble else 0)
			verts.append(tuple(p + side * math.cos(a) * w * j + n * math.sin(a) * h * j))
	for i in range(len(rings) - 1):
		for k in range(sides):
			a, b = i * sides + k, i * sides + (k + 1) % sides
			faces.append((a, a + sides, b + sides, b))
	if caps[0]:
		verts.append(tuple(pts[0] - (pts[1] - pts[0]).normalized() * min(rings[0][1], rings[0][2]) * 0.4))
		cidx = len(verts) - 1
		for k in range(sides):
			faces.append((cidx, k, (k + 1) % sides)[::-1])
	if caps[1]:
		last = (len(rings) - 1) * sides
		verts.append(tuple(pts[-1] + (pts[-1] - pts[-2]).normalized() * min(rings[-1][1], rings[-1][2]) * 0.4))
		cidx = len(verts) - 1
		for k in range(sides):
			faces.append((cidx, last + (k + 1) % sides, last + k)[::-1])
	o = kit._mesh_obj(name, verts, faces, material, smooth=smooth)
	_fix_normals(o)
	if subsurf:
		kit.soft(o, subsurf)
	return o


def _fix_normals(o):
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	bm.to_mesh(o.data)
	bm.free()


def path_rings(path, radii, heights=None):
	"""Rings along a list of points with matching radii (round tubes when heights is None)."""
	heights = heights or radii
	return [(p, w, h) for p, w, h in zip(path, radii, heights)]


def bezier(p0, p1, p2, n=8, p3=None):
	"""Points along a smooth curve (quadratic, or cubic when p3 is given)."""
	p0, p1, p2 = Vector(p0), Vector(p1), Vector(p2)
	out = []
	for i in range(n):
		t = i / (n - 1)
		if p3 is None:
			out.append((1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t * t * p2)
		else:
			q = Vector(p3)
			out.append((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t * t * p2 + t ** 3 * q)
	return out


def limb(name, points, r0, r1, material, sides=8, knobs=(), subsurf=1):
	"""A tapered limb (leg segment, finger, horn, tentacle) through points, from radius r0 to r1.
	knobs: indices where a joint bulges a little."""
	n = len(points)
	rings = []
	for i, p in enumerate(points):
		t = i / (n - 1)
		r = r0 + (r1 - r0) * t
		if i in knobs:
			r *= 1.35
		rings.append((p, r, r))
	return loft(name, rings, material, sides=sides, subsurf=subsurf)


def blob(loc, size, material, seed=1, subsurf=1, jitter=0.12, detail=2):
	"""A soft lumpy blob (moss tuft, wart, fur clump). detail 1 = cheap (for many small ones)."""
	bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=detail, radius=1, location=loc)
	o = bpy.context.object
	r = random.Random(seed)
	for v in o.data.vertices:
		v.co *= 1 + r.uniform(-jitter, jitter)
	o.scale = size
	bpy.ops.object.transform_apply(scale=True)
	o.data.materials.append(material)
	if "tile" in material:
		kit._uv_box(o, material["tile"])
	for p in o.data.polygons:
		p.use_smooth = True
	if subsurf:
		kit.soft(o, subsurf)
	return o


def membrane(name, outline, material, thick=0.012, sag=0.0, center=None):
	"""A thin skin stretched over an outline (list of points, in order around the edge): bat wings.
	Built as a fan from `center` (default: the outline's average point), with a little thickness."""
	pts = [Vector(p) for p in outline]
	c = Vector(center) if center else sum(pts, Vector()) / len(pts)
	c.z -= sag
	verts, faces = [], []
	n = len(pts)
	for off in (thick / 2, -thick / 2):
		verts.append(tuple(c + Vector((0, 0, off))))
		for p in pts:
			verts.append(tuple(p + Vector((0, 0, off))))
	m = n + 1
	for i in range(n):
		j = (i + 1) % n
		faces.append((0, 1 + i, 1 + j))
		faces.append((m, m + 1 + j, m + 1 + i))
		faces.append((1 + i, m + 1 + i, m + 1 + j, 1 + j))
	o = kit._mesh_obj(name, verts, faces, material, smooth=True)
	_fix_normals(o)
	return o


def wrap_sheet(name, ys, radii, axis_z, a0, a1, material, side=1, thick=0.012, steps=8, scallop=0.0):
	"""A curved sheet wrapped around a body running along Y (a folded wing, a cloak):
	for each y, an arc from angle a0 to a1 (radians, 0 = the side, +pi/2 = the top) at radius (rx, rz).
	side = -1 mirrors it to the left. scallop: the bottom edge dips in between the y rings."""
	verts, faces = [], []
	cols = steps + 1
	for layer, off in enumerate((0.0, -thick)):
		for i, (y, (rx, rz)) in enumerate(zip(ys, radii)):
			for j in range(cols):
				a = a0 + (a1 - a0) * j / steps
				dip = scallop * (0.5 - 0.5 * math.cos(i * math.pi)) if j == cols - 1 else 0.0
				verts.append((side * math.cos(a) * (rx + off), y, axis_z + math.sin(a) * (rz + off) + dip))
	n = len(ys) * cols
	for i in range(len(ys) - 1):
		for j in range(steps):
			a, b, c, d = i * cols + j, i * cols + j + 1, (i + 1) * cols + j + 1, (i + 1) * cols + j
			faces.append((a, b, c, d))
			faces.append((n + d, n + c, n + b, n + a))
	for i in range(len(ys) - 1):  # close the edges between the two layers
		for j in (0, steps):
			a, d = i * cols + j, (i + 1) * cols + j
			faces.append((a, d, n + d, n + a))
	for j in range(steps):
		for i in (0, len(ys) - 1):
			a, b = i * cols + j, i * cols + j + 1
			faces.append((a, n + a, n + b, b))
	o = kit._mesh_obj(name, verts, faces, material, smooth=True)
	_fix_normals(o)
	return o


# ---------------------------------------------------------------- saving

def save(out, preview=None):
	"""Apply modifiers, join each part into one piece with its hinge as origin, put the whole creature's
	bottom centre at the origin, export .glb with the pieces as separate named nodes, render previews."""
	meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	for o in meshes:
		bpy.context.view_layer.objects.active = o
		for m in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=m.name)
		o.select_set(False)
	for o in meshes:
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
		o.select_set(False)
	# Whole-creature bounds: shift so the bottom centre is at the origin.
	vs = [v.co for o in meshes for v in o.data.vertices]
	lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
	hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
	shift = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
	joined = []
	tris = 0
	groups = {name: [o for o in meshes if o.get("part", "body") == name] for name in _parts}  # before joining removes objects
	for name, hinge in _parts.items():
		group = groups[name]
		if not group:
			continue
		bpy.ops.object.select_all(action="DESELECT")
		for o in group:
			o.select_set(True)
		bpy.context.view_layer.objects.active = group[0]
		if len(group) > 1:
			bpy.ops.object.join()
		obj = bpy.context.object
		obj.name = name
		obj.data.name = name
		piv = hinge - shift
		for v in obj.data.vertices:
			v.co -= shift + piv
		obj.location = piv
		tris += sum(len(p.vertices) - 2 for p in obj.data.polygons)
		joined.append(obj)
	bpy.ops.object.select_all(action="DESELECT")
	for o in joined:
		o.select_set(True)
	bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="JPEG", export_image_quality=85)
	import glb_jpeg_fix  # Blender's JPEGs carry an EXIF block Godot can't read (models turn white)
	glb_jpeg_fix.fix(out)
	d = hi - lo
	print(f"KIT_DONE {out} size {d.x:.2f} x {d.y:.2f} x {d.z:.2f} m, {tris} triangles, parts {[o.name for o in joined]}")
	if preview:
		_previews(preview, d)


def _previews(path, dims):
	"""Three pictures: front three-quarter, side, top-ish back."""
	scene = bpy.context.scene
	engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
	scene.render.resolution_x = scene.render.resolution_y = 640
	scene.view_settings.view_transform = "Standard"
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
	scene.camera = cam
	d = max(dims) * 0.72
	t = Vector((0, 0, dims.z * 0.45))
	views = {"front": Vector((d * 0.9, -d * 1.8, d * 0.8)), "side": Vector((d * 2.0, 0, d * 0.45)),
		"back": Vector((-d * 1.1, d * 1.5, d * 1.2))}
	stem = path[:-4] if path.endswith(".png") else path
	for k, off in views.items():
		cam.location = t + off
		cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
		scene.render.filepath = f"{stem}_{k}.png"
		bpy.ops.render.render(write_still=True)
