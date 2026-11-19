# Glow trees for the glow groves (owner, Nov 19, 2026: "the trees glow ... sometimes the main source of light in some
# caves"; decisions in docs/research/asset-picks-placement.md). Free CC0 pack trees (Quaternius Stylized Nature
# MegaKit, flo-bit Low Poly Nature; sources in tools/asset_forge/packs/) rebuilt by script (MODEL-RULES rule 1, as
# bent by the owner for free packs): the pack's tree shape and leaf cards are kept, the trunk is repainted with our
# hand-painted bark (kit "bark_tree", a different variant per tree) with a little hand-made wobble, and the leaves
# glow (one colour per grove; the game can tint it). Dead and twisted trees keep dark bark with faint glowing cracks.
#
#   blender --background --factory-startup --python builds/glow_trees.py -- <out_dir> [only=gtree_common_1,...]
#
# Exported as .glb with PNG pictures (the leaf cards need their see-through edges; JPEG has none). z = 0 is the
# ground, origin at the bottom centre of the trunk.
import json
import math
import random
import struct
import zlib
import sys
from pathlib import Path

import bpy
from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

PACKS = Path(__file__).resolve().parents[1] / "packs"
Q = PACKS / "quaternius_stylized_nature"
F = PACKS / "flobit_low_poly_nature"
GLOW_TEAL = (0.25, 0.95, 0.85)
kit.TILE.setdefault("bark_tree", 0.8)  # the Root Tree bark repeats every ~0.8 m (MODEL-RULES rule 6)

# name: (source file, kind, height in metres, bark variant)
TREES = {
	"gtree_common_1": (Q / "CommonTree_1.gltf", "leafy", 7.0, "a"),
	"gtree_common_3": (Q / "CommonTree_3.gltf", "leafy", 6.4, "b"),
	"gtree_pine_1": (Q / "Pine_1.gltf", "leafy", 7.6, "c"),
	"gtree_pine_3": (Q / "Pine_3.gltf", "leafy", 7.0, "moss"),
	"gtree_common_2": (Q / "CommonTree_2.gltf", "leafy", 6.6, "c"),
	"gtree_common_4": (Q / "CommonTree_4.gltf", "leafy", 7.2, "moss"),
	"gtree_common_5": (Q / "CommonTree_5.gltf", "leafy", 6.2, "a"),
	"gtree_pine_2": (Q / "Pine_2.gltf", "leafy", 7.4, "b"),
	"gtree_pine_4": (Q / "Pine_4.gltf", "leafy", 6.8, "a"),
	"gtree_pine_5": (Q / "Pine_5.gltf", "leafy", 7.8, "c"),
	# The dark trees between them (owner: "dark trees in glow groves"): dark bark, a faint glow in the cracks.
	"dtree_dead_1": (Q / "DeadTree_1.gltf", "dark", 7.0, "c"),
	"dtree_dead_2": (Q / "DeadTree_2.gltf", "dark", 6.4, "b"),
	"dtree_dead_3": (Q / "DeadTree_3.gltf", "dark", 7.6, "moss"),
	"dtree_dead_4": (Q / "DeadTree_4.gltf", "dark", 6.8, "a"),
	"dtree_dead_5": (Q / "DeadTree_5.gltf", "dark", 7.2, "c"),
	"dtree_twisted_1": (Q / "TwistedTree_1.gltf", "twisted", 8.5, "b"),
	"dtree_twisted_2": (Q / "TwistedTree_2.gltf", "twisted", 9.0, "moss"),
	"dtree_twisted_3": (Q / "TwistedTree_3.gltf", "twisted", 8.0, "a"),
	"dtree_twisted_4": (Q / "TwistedTree_4.gltf", "twisted", 8.8, "c"),
	"dtree_twisted_5": (Q / "TwistedTree_5.gltf", "twisted", 9.4, "b"),
	"dtree_bare_1": (F / "common_tree_dead_1.glb", "dark", 5.0, "a"),
	"dtree_bare_2": (F / "common_tree_dead_2.glb", "dark", 5.0, "moss"),
	"dtree_bare_3": (F / "common_tree_dead_3.glb", "dark", 5.8, "b"),
	"dtree_bare_4": (F / "dead_tree_1.glb", "dark", 5.4, "c"),
	"dtree_bare_5": (F / "dead_tree_2.glb", "dark", 7.0, "a"),
	"dtree_bare_6": (F / "dead_tree_3.glb", "dark", 7.2, "moss"),
}
LEAF_GLOW = {"leafy": 1.6, "twisted": 0.6}  # twisted trees: only a faint glow in their few leaves
CRACK_GLOW = {"twisted": 0.9}   # twisted trees: the bark's deepest grooves glow faintly. Trees with no leaves don't glow at all (owner, Nov 19)


def import_tree(path):
	for o in list(bpy.data.objects):
		bpy.data.objects.remove(o, do_unlink=True)
	if path.suffix == ".gltf" or path.suffix == ".glb":
		bpy.ops.import_scene.gltf(filepath=str(path))
	meshes = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in bpy.data.objects:
		o.select_set(o in meshes)
	bpy.context.view_layer.objects.active = meshes[0]
	if len(meshes) > 1:
		bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	return obj


def split_leaves(obj):
	"""Separate the leaf cards (any material with 'leaf' in its name) into their own object."""
	leaf_idx = [i for i, s in enumerate(obj.material_slots) if s.material and ("leaf" in s.material.name.lower() or "leaves" in s.material.name.lower())]
	if not leaf_idx:
		return obj, None
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="DESELECT")
	for i in leaf_idx:
		obj.active_material_index = i
		bpy.ops.object.material_slot_select()
	bpy.ops.mesh.separate(type="SELECTED")
	bpy.ops.object.mode_set(mode="OBJECT")
	leaves = [o for o in bpy.context.selected_objects if o is not obj][0]
	return obj, leaves


def glow_leaf_material(src_mat, colour, strength=1.6):
	"""The pack's leaf picture as a cut-out mask; painted dark-to-bright in the grove colour, glowing."""
	img = None
	for n in src_mat.node_tree.nodes:
		if n.type == "TEX_IMAGE" and n.image and "lea" in n.image.name.lower() and not n.image.name.lower().endswith("_normal"):
			img = n.image  # the leaf painting (not a normal map)
	# glTF carries only plain pictures, so the grove colour is painted into a new leaf picture here: the pack picture's
	# brightness picks a shade from dark to bright grove colour; its see-through edges are kept.
	import numpy as np
	if img.size[0] == 0:  # the importer leaves pictures unread until something draws them
		img.reload()
	if img.size[0] == 0 and img.filepath:
		img = bpy.data.images.load(bpy.path.abspath(img.filepath), check_existing=False)
	w, h = img.size
	px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
	# Even the pictures out (owner, Nov 19: the round trees glowed too much, the pines only in one spot): the pack's
	# leaf pictures differ a lot in brightness, so each is stretched between its own darkest and brightest leaf
	# pixels, then kept in a narrow band: every leaf glows, with only a little light-and-dark texture inside.
	raw = px[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
	solid = px[..., 3] > 0.5
	lo, hi = np.percentile(raw[solid], [5, 95]) if solid.any() else (0.0, 1.0)
	lum = np.clip((raw - lo) / max(hi - lo, 1e-3), 0, 1)[..., None]
	g = 0.55 + 0.45 * lum  # grey shades: the grove colour is a tint on top (set in _leaves_cutout / by the game)
	rgb = np.repeat(g, 3, axis=2)
	out = np.concatenate([rgb, px[..., 3:4]], axis=2)
	glow_img = bpy.data.images.new(f"{img.name.split('.')[0]}_glow", w, h, alpha=True)
	glow_img.pixels = out.ravel().tolist()
	glow_img.file_format = "PNG"
	glow_img.pack()
	m = bpy.data.materials.new("glow_leaves")
	m.use_nodes = True
	nt = m.node_tree
	b = nt.nodes["Principled BSDF"]
	t = nt.nodes.new("ShaderNodeTexImage")
	t.image = glow_img
	nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
	nt.links.new(t.outputs["Color"], b.inputs["Emission Color"])
	b.inputs["Emission Strength"].default_value = strength
	nt.links.new(t.outputs["Alpha"], b.inputs["Alpha"])
	b.inputs["Roughness"].default_value = 0.8
	return m


def wobble(obj, amount, seed):
	"""A little hand-made unevenness (no perfect cylinders, owner's art rule)."""
	for v in obj.data.vertices:
		p = v.co
		n = noise.noise_vector(Vector((p.x * 1.7 + seed, p.y * 1.7, p.z * 0.9)))
		v.co = p + n * amount


_crack_mats = {}


def crack_bark_material(variant, strength):
	"""Our bark painting, plus a glow picture made from its deepest grooves (the darkest parts of the same
	painting), so the dark trees glow faintly in their cracks (owner, Nov 19). Tinted by the grove colour."""
	key = (variant, strength)
	if key in _crack_mats:
		return _crack_mats[key]
	import numpy as np
	bark = bpy.data.images.load(str(kit.TEX / f"bark_tree_{variant}.png"), check_existing=True)
	w, h = bark.size
	px = np.array(bark.pixels[:], dtype=np.float32).reshape(h, w, 4)
	lum = px[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
	lo = np.percentile(lum, 4)
	crack = np.clip(1 - (lum - lo) / 0.12, 0, 1) ** 2  # only the darkest grooves
	cimg = bpy.data.images.new(f"bark_crack_{variant}", w, h, alpha=False)
	cimg.pixels = np.concatenate([np.repeat(crack[..., None], 3, axis=2), np.ones((h, w, 1), np.float32)], axis=2).ravel().tolist()
	cimg.file_format = "PNG"
	cimg.pack()
	m = bpy.data.materials.new(f"bark_crack_{variant}")
	m.use_nodes = True
	nt = m.node_tree
	b = nt.nodes["Principled BSDF"]
	t = nt.nodes.new("ShaderNodeTexImage")
	t.image = bark
	c = nt.nodes.new("ShaderNodeTexImage")
	c.image = cimg
	nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
	nt.links.new(c.outputs["Color"], b.inputs["Emission Color"])
	b.inputs["Emission Strength"].default_value = strength
	b.inputs["Roughness"].default_value = 0.9
	m["tile"] = kit.TILE["bark_tree"]
	_crack_mats[key] = m
	return m


def repaint_bark(obj, variant, crack=0.0):
	mat = crack_bark_material(variant, crack) if crack else kit.tex_mat("bark_tree", variant)
	obj.data.materials.clear()
	obj.data.materials.append(mat)
	kit._uv_box(obj, mat["tile"])


def scale_to(objs, height):
	pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
	h = max(p.z for p in pts) - min(p.z for p in pts)
	s = height / h
	for o in objs:
		o.scale = (s * 1.12, s * 1.12, s)  # a touch chunkier than the pack (our style)
		bpy.context.view_layer.update()
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def export(out, objs):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	obj.name = "model"
	vs = [v.co for v in obj.data.vertices]
	lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
	hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
	shift = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
	for v in obj.data.vertices:
		v.co -= shift
	for img in bpy.data.images:  # placed by the dozen: bark and crack pictures at 512 px, leaf pictures at 1024
		lim = 1024 if "lea" in img.name.lower() else 512
		if img.size[0] > lim:
			img.scale(lim, lim)
	_bark_as_jpeg()
	bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="AUTO")
	_leaves_cutout(out)
	import glb_jpeg_fix  # Blender's JPEGs carry an EXIF block Godot can't read (models turn white): strip it
	glb_jpeg_fix.fix(out)
	tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
	d = hi - lo
	print(f"KIT_DONE {out} size {d.x:.2f} x {d.y:.2f} x {d.z:.2f} m, {tris} triangles")
	return obj


_jpeg_cache = {}


def _bark_as_jpeg():
	"""Bark and crack pictures need no see-through edges: save them as JPEG files (~5x smaller) and use those, so
	the exporter writes JPEG. Leaf pictures stay PNG (their cut-out edges)."""
	import tempfile
	for m in bpy.data.materials:
		if not m.node_tree:
			continue
		for n in m.node_tree.nodes:
			if n.type != "TEX_IMAGE" or not n.image or "lea" in n.image.name.lower() or n.image.name.endswith("_jpg"):
				continue
			if n.image.size[0] == 0:
				continue  # an unused picture (the pack's own bark, replaced by ours)
			if n.image.name not in _jpeg_cache:
				tmp = str(Path(tempfile.gettempdir()) / f"{n.image.name}.jpg")
				src = n.image
				src.filepath_raw = tmp
				src.file_format = "JPEG"
				bpy.context.scene.render.image_settings.quality = 85
				src.save(filepath=tmp, quality=85)
				j = bpy.data.images.load(tmp, check_existing=False)
				j.name = src.name + "_jpg"
				_jpeg_cache[src.name] = j
			n.image = _jpeg_cache[n.image.name]


def _leaves_cutout(path):
	"""Mark the leaf material as a cut-out (alphaMode MASK) and double-sided in the .glb, so the game draws leaf
	shapes, not grey squares, from both sides."""
	b = bytearray(Path(path).read_bytes())
	n = struct.unpack_from("<I", b, 12)[0]
	j = json.loads(b[20:20 + n])
	for m in j.get("materials", []):
		if "leaves" in m.get("name", ""):
			m["alphaMode"] = "MASK"
			m["alphaCutoff"] = 0.5
			m["doubleSided"] = True
			m.setdefault("pbrMetallicRoughness", {})["baseColorFactor"] = [*GLOW_TEAL, 1.0]
			m["emissiveFactor"] = list(GLOW_TEAL)
		if m.get("name", "").startswith("bark_crack"):
			m["emissiveFactor"] = list(GLOW_TEAL)  # the crack glow takes the grove colour too
	s = json.dumps(j, separators=(",", ":")).encode()
	s += b" " * ((4 - len(s) % 4) % 4)
	rest = b[20 + n:]
	out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(s) + len(rest)) + struct.pack("<II", len(s), 0x4E4F534A) + s + rest
	Path(path).write_bytes(out)


def build(name, out_dir):
	src, kind, height, variant = TREES[name]
	obj = import_tree(src)
	trunk, leaves = split_leaves(obj)
	scale_to([o for o in (trunk, leaves) if o], height)
	wobble(trunk, 0.035, zlib.crc32(name.encode()) % 100)  # the same wobble every build
	repaint_bark(trunk, variant, CRACK_GLOW.get(kind, 0.0))
	parts = [trunk]
	if leaves:
		src_mat = next(s.material for s in leaves.material_slots if s.material and "lea" in s.material.name.lower())
		gm = glow_leaf_material(src_mat, GLOW_TEAL, LEAF_GLOW.get(kind, 1.6))
		leaves.data.materials.clear()
		leaves.data.materials.append(gm)
		parts.append(leaves)
	return export(str(Path(out_dir) / f"{name}.glb"), parts)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	out_dir = args[0] if args else str(Path(__file__).resolve().parents[3] / "assets" / "models" / "cave")
	only = next((a.split("=", 1)[1].split(",") for a in args if a.startswith("only=")), list(TREES))
	for n in only:
		build(n, out_dir)
