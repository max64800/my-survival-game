# Put a blueprint together from the game's real models (Blender, for photos):
#   blender --background --factory-startup --python tools/blueprint_viewer/assemble_blueprint.py -- <blueprint.json> assets/models/build <out.glb>
import json, math, sys
import bpy

args = sys.argv[sys.argv.index("--") + 1:]
bp = json.load(open(args[0], encoding="utf-8"))
models, out = args[1], args[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
missing = []
for p in bp["pieces"]:
	path = f"{models}/{p['id']}__{p['mat']}.glb"
	before = set(bpy.data.objects)
	try:
		bpy.ops.import_scene.gltf(filepath=path)
	except Exception:
		missing.append(path)
		continue
	new = [o for o in bpy.data.objects if o not in before]
	x, y, z = p["pos"]
	root = bpy.data.objects.new(f"{p['id']}@{y:g}@{p['rot']}", None)  # the page finds roof/door by name
	bpy.context.scene.collection.objects.link(root)
	root.location = (x, -z, y)                       # Godot -> Blender
	root.rotation_euler = (0, 0, p["rot"] * math.pi / 2)  # a turn about Godot's up = Blender's up
	for o in new:
		if o.parent is None:
			o.parent = root
import re
for img in list(bpy.data.images):  # every piece brought its own copy of the same painting: share one
	base = re.sub(r"\.\d{3}$", "", img.name)
	if base != img.name and base in bpy.data.images:
		img.user_remap(bpy.data.images[base])
for mat in list(bpy.data.materials):
	base = re.sub(r"\.\d{3}$", "", mat.name)
	if base != mat.name and base in bpy.data.materials:
		mat.user_remap(bpy.data.materials[base])
print("IMAGES", len([i for i in bpy.data.images if i.users]))
for img in bpy.data.images:  # keep the file small: the page only needs 256 px paint
	if img.size[0] > 256:
		img.scale(256, 256)
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="JPEG")
print("ASSEMBLED", len(bp["pieces"]), "pieces; missing:", missing)
