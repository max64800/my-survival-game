# Blender cleanup for AI-made 3D models ("asset forge", step 4).
#
# Run by forge.py like this (no window opens):
#   blender --background --factory-startup --python blender_cleanup.py -- in.glb out.glb [options]
#
# What it does, in order:
#   1. Loads the raw model (glb / gltf / obj).
#   2. Glues all its pieces into one object and throws away tiny floating crumbs.
#   3. Turns it so "up" is up, scales it to a real size in meters, and puts its feet on the floor.
#   4. Cuts the triangle count down to a budget (games need light models).
#   5. Shrinks textures to a small size and tints them toward our palette.
#   6. Saves a .glb for Godot and a preview picture (front three-quarter view).
import argparse
import json
import math
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector


def parse_args():
	argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	p = argparse.ArgumentParser()
	p.add_argument("src")
	p.add_argument("dst")
	p.add_argument("--size", type=float, default=1.0, help="largest side in meters (or height, see --fit)")
	p.add_argument("--fit", choices=["largest", "height"], default="largest")
	p.add_argument("--tris", type=int, default=3000, help="triangle budget")
	p.add_argument("--tex", type=int, default=256, help="max texture size in pixels")
	p.add_argument("--saturation", type=float, default=0.85, help="1 = unchanged, lower = more muted")
	p.add_argument("--warmth", type=float, default=0.04, help="push colors a little toward warm")
	p.add_argument("--rotate-x", type=float, default=0.0, help="extra turn in degrees if the model lies on its side")
	p.add_argument("--rotate-z", type=float, default=0.0, help="extra turn in degrees to face forward")
	p.add_argument("--srgb-corners", action="store_true",
		help="the model's corner colors are stored as screen colors (TripoSR does this); convert them")
	p.add_argument("--crumbs", type=float, default=0.02, help="drop loose parts smaller than this share of the model")
	p.add_argument("--preview", default="", help="png path for a preview picture")
	return p.parse_args(argv)


def load(path):
	bpy.ops.wm.read_factory_settings(use_empty=True)
	low = path.lower()
	if low.endswith((".glb", ".gltf")):
		bpy.ops.import_scene.gltf(filepath=path)
	elif low.endswith(".obj"):
		bpy.ops.wm.obj_import(filepath=path)
	else:
		raise SystemExit("Unknown model type: " + path)
	meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	if not meshes:
		raise SystemExit("No mesh found in " + path)
	return meshes


def join(meshes):
	bpy.ops.object.select_all(action="DESELECT")
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	if len(meshes) > 1:
		bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	# Unparent (glTF import can add empty "root" nodes) and bake all moves into the mesh.
	bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	for o in list(bpy.context.scene.objects):
		if o.type != "MESH":
			bpy.data.objects.remove(o)
	obj.name = "model"
	return obj


def drop_crumbs(obj, share):
	bm = bmesh.new()
	bm.from_mesh(obj.data)
	# Model files often store every face with its own corners. Weld corners that sit in the same
	# spot first, or every single face looks like a separate "crumb".
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5 * max(obj.dimensions))
	bm.faces.ensure_lookup_table()
	seen, islands = set(), []
	for f in bm.faces:
		if f.index in seen:
			continue
		stack, island = [f], []
		seen.add(f.index)
		while stack:
			cur = stack.pop()
			island.append(cur)
			for e in cur.edges:
				for nb in e.link_faces:
					if nb.index not in seen:
						seen.add(nb.index)
						stack.append(nb)
		islands.append(island)
	total = len(bm.faces)
	gone = [f for isl in islands if len(isl) < total * share for f in isl]
	if gone:
		bmesh.ops.delete(bm, geom=gone, context="FACES")
	bm.to_mesh(obj.data)
	bm.free()
	obj.data.update()
	bpy.context.view_layer.update()
	return len(islands), len(gone)


def _bounds(obj):
	vs = [v.co for v in obj.data.vertices]
	lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
	hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
	return lo, hi


def place(obj, a):
	# Turn and scale the points themselves. (Setting the object's rotation does nothing here:
	# the glTF importer stores turns as "quaternions", so rotation_euler is ignored.)
	turn = Matrix.Rotation(math.radians(a.rotate_z), 4, "Z") @ Matrix.Rotation(math.radians(a.rotate_x), 4, "X")
	obj.data.transform(turn)
	lo, hi = _bounds(obj)
	dims = hi - lo
	ref = dims.z if a.fit == "height" else max(dims)
	s = a.size / ref if ref > 0 else 1.0
	# Feet on the floor, centered: Godot's "origin" will be the bottom middle.
	center = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
	obj.data.transform(Matrix.Scale(s, 4) @ Matrix.Translation(-center))
	obj.location = (0, 0, 0)
	obj.data.update()
	bpy.context.view_layer.update()


def tri_count(obj):
	return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def decimate(obj, budget):
	before = tri_count(obj)
	if before > budget:
		m = obj.modifiers.new("decimate", "DECIMATE")
		m.ratio = budget / before
		m.use_collapse_triangulate = True
		bpy.ops.object.modifier_apply(modifier=m.name)
	# Smooth-looking but with crisp hard edges (chunky style).
	bpy.ops.object.shade_auto_smooth(angle=math.radians(40))
	return before, tri_count(obj)


def grade(rgb, sat, warmth):
	gray = rgb @ np.array([0.299, 0.587, 0.114])
	out = gray[:, None] + (rgb - gray[:, None]) * sat
	out[:, 0] += warmth
	out[:, 2] -= warmth
	return np.clip(out, 0.0, 1.0)


def fix_corner_colors(obj):
	"""TripoSR saves corner colors as screen ("sRGB") values, but glTF says they must be "linear".
	Blender trusts glTF, so everything comes out washed out and pale. Convert them back."""
	for attr in obj.data.color_attributes:
		vals = np.empty(len(attr.data) * 4, dtype=np.float32)
		attr.data.foreach_get("color", vals)
		vals = vals.reshape(-1, 4)
		c = vals[:, :3]
		vals[:, :3] = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
		attr.data.foreach_set("color", vals.ravel())


def fix_textures(obj, a):
	done = []
	for slot in obj.material_slots:
		mat = slot.material
		if not mat or not mat.use_nodes:
			continue
		for n in mat.node_tree.nodes:
			if n.type == "BSDF_PRINCIPLED":
				n.inputs["Metallic"].default_value = 0.0
				n.inputs["Roughness"].default_value = 0.9
				# AI tools often wire in shiny "metal/rough" maps that look plastic: unplug them.
				for name in ("Metallic", "Roughness"):
					for link in list(n.inputs[name].links):
						mat.node_tree.links.remove(link)
			if n.type == "TEX_IMAGE" and n.image and n.image.name not in done:
				img = n.image
				w, h = img.size
				big = max(w, h)
				if big > a.tex:
					img.scale(max(1, w * a.tex // big), max(1, h * a.tex // big))
				is_color = img.colorspace_settings.name.lower().startswith("srgb")
				if is_color:
					px = np.empty(len(img.pixels), dtype=np.float32)
					img.pixels.foreach_get(px)
					px = px.reshape(-1, 4)
					px[:, :3] = grade(px[:, :3], a.saturation, a.warmth)
					img.pixels.foreach_set(px.ravel())
				img.pack()
				done.append(img.name)
	# Models with colors stored on the corners ("vertex colors") instead of a texture.
	for attr in obj.data.color_attributes:
		vals = np.empty(len(attr.data) * 4, dtype=np.float32)
		attr.data.foreach_get("color", vals)
		vals = vals.reshape(-1, 4)
		vals[:, :3] = grade(vals[:, :3], a.saturation, a.warmth)
		attr.data.foreach_set("color", vals.ravel())
	return done


def ensure_material(obj, tex_size):
	"""Give every model one material with a small picture (texture).

	Some models (TripoSR) store colors on the corners ("vertex colors") instead of in a picture.
	Godot ignores those by default, so we "bake" (paint) them into a small texture. Small and a bit
	soft is exactly our style anyway.
	"""
	has_picture = any(
		n.type == "TEX_IMAGE" for s in obj.material_slots if s.material and s.material.use_nodes
		for n in s.material.node_tree.nodes)
	if has_picture or not obj.data.color_attributes:
		if not any(s.material for s in obj.material_slots):
			obj.data.materials.clear()
			obj.data.materials.append(bpy.data.materials.new("model_mat"))
		return
	# 1. Lay the model's skin out flat (a "UV map"), like peeling an orange.
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
	bpy.ops.object.mode_set(mode="OBJECT")
	# 2. Paint the corner colors onto a picture with Blender's renderer (Cycles "bake").
	img = bpy.data.images.new("baked_color", tex_size, tex_size)
	img.colorspace_settings.name = "sRGB"
	mat = bpy.data.materials.new("model_mat")
	mat.use_nodes = True
	nt = mat.node_tree
	nt.nodes.clear()
	col = nt.nodes.new("ShaderNodeVertexColor")
	col.layer_name = obj.data.color_attributes[0].name
	emit = nt.nodes.new("ShaderNodeEmission")
	out = nt.nodes.new("ShaderNodeOutputMaterial")
	tex = nt.nodes.new("ShaderNodeTexImage")
	tex.image = img
	nt.nodes.active = tex
	nt.links.new(col.outputs["Color"], emit.inputs["Color"])
	nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
	obj.data.materials.clear()
	obj.data.materials.append(mat)
	scene = bpy.context.scene
	scene.render.engine = "CYCLES"
	scene.cycles.samples = 1
	scene.cycles.device = "CPU"
	scene.render.bake.margin = 4
	bpy.ops.object.bake(type="EMIT")
	# 3. Swap to a normal, matte material that shows the picture.
	nt.nodes.remove(emit)
	nt.nodes.remove(col)
	bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
	nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
	img.pack()
	# The colors live in the picture now; drop the corner colors so nothing uses them twice.
	while obj.data.color_attributes:
		obj.data.color_attributes.remove(obj.data.color_attributes[0])


def preview(obj, path):
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
	scene.render.resolution_x = scene.render.resolution_y = 512
	scene.render.film_transparent = False
	world = bpy.data.worlds.new("w")
	world.use_nodes = True
	world.node_tree.nodes["Background"].inputs[0].default_value = (0.08, 0.07, 0.06, 1)
	world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
	scene.world = world
	d = max(obj.dimensions)
	h = obj.dimensions.z
	target = Vector((0, 0, h * 0.45))
	cam_data = bpy.data.cameras.new("cam")
	cam = bpy.data.objects.new("cam", cam_data)
	scene.collection.objects.link(cam)
	cam.location = target + Vector((d * 1.5, -d * 1.9, d * 1.0))
	cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.camera = cam
	for loc, power, color in (((d * 2, -d * 2, d * 3), 800, (1.0, 0.85, 0.65)), ((-d * 2, d, d * 1.5), 250, (0.6, 0.7, 1.0))):
		ld = bpy.data.lights.new("l", "POINT")
		ld.energy = power * d * d
		ld.color = color
		lo = bpy.data.objects.new("l", ld)
		lo.location = loc
		scene.collection.objects.link(lo)
	scene.render.filepath = path
	bpy.ops.render.render(write_still=True)
	# Remove helper objects so they don't end up in the export.
	for o in list(scene.objects):
		if o is not obj:
			bpy.data.objects.remove(o)


def main():
	a = parse_args()
	obj = join(load(a.src))
	islands, crumbs = drop_crumbs(obj, a.crumbs)
	place(obj, a)
	before, after = decimate(obj, a.tris)
	if a.srgb_corners:
		fix_corner_colors(obj)
	ensure_material(obj, a.tex)
	textures = fix_textures(obj, a)
	if a.preview:
		preview(obj, a.preview)
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.ops.export_scene.gltf(filepath=a.dst, export_format="GLB", use_selection=True, export_yup=True)
	d = obj.dimensions
	print("FORGE_REPORT " + json.dumps({
		"tris_before": before, "tris_after": after, "parts": islands, "crumb_faces_removed": crumbs,
		"size_m": [round(d.x, 2), round(d.y, 2), round(d.z, 2)], "textures": textures, "out": a.dst,
	}))


main()
