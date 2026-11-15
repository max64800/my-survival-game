# Overview picture of many forged models, side by side (to check them all at a glance).
#   blender --background --factory-startup --python overview.py -- <folder with .glb> <out.png> [columns]
# Every model is scaled to the same size for the picture only and shown from the front-right, a bit above.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
folder, out = Path(args[0]), args[1]
cols = int(args[2]) if len(args) > 2 else 10
files = sorted(folder.glob("*.glb"))

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
for i, f in enumerate(files):
	before = set(bpy.data.objects)
	bpy.ops.import_scene.gltf(filepath=str(f))
	new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
	if not new:
		continue
	o = new[0]
	o.rotation_mode = "XYZ"
	d = max(o.dimensions)
	s = 1.0 / d if d > 0 else 1.0
	o.scale = (s, s, s)
	col, row = i % cols, i // cols
	o.location = (col * 1.6, 0, -row * 1.6)
	# Name label under each model.
	txt = bpy.data.curves.new("t", "FONT")
	txt.body = f.stem
	txt.size = 0.13
	txt.align_x = "CENTER"
	t = bpy.data.objects.new("t", txt)
	t.location = (col * 1.6, 0, -row * 1.6 - 0.3)
	t.rotation_euler = (math.radians(90), 0, 0)
	scene.collection.objects.link(t)

rows = (len(files) + cols - 1) // cols
cx, cz = (cols - 1) * 1.6 / 2, -(rows - 1) * 1.6 / 2 + 0.4
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = max(cols, rows) * 1.6 + 0.4
scene.collection.objects.link(cam)
cam.location = (cx, -20, cz)
cam.rotation_euler = (math.radians(90), 0, 0)
scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.5
sun.rotation_euler = (math.radians(60), math.radians(10), math.radians(-30))
scene.collection.objects.link(sun)
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.33, 0.3, 1)
scene.world = world
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.resolution_x = cols * 150
scene.render.resolution_y = int(rows * 150 * 1.0) if rows <= cols else cols * 150
scene.render.resolution_x = scene.render.resolution_y = max(scene.render.resolution_x, scene.render.resolution_y)
# Turn every model a little so we see front + side (front faces -Y in Blender = +Z in Godot).
for o in scene.objects:
	if o.type == "MESH":
		o.rotation_euler = (0, 0, math.radians(-30))
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("OVERVIEW", len(files), out)
