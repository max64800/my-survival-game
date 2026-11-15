"""Close-up photos of one part of a creature (face, feet, glowing back) from any angle (by Claude 3).

    blender --background --factory-startup --python tools/asset_forge/creature_closeup.py -- <model.glb> <out_prefix> x,y,z size az,el[;az,el...]

x,y,z = the point to look at (Blender: -Y is the front, Z up), size = how many metres fit in the picture, az = degrees
around (-90 = straight from the front), el = degrees from above. Writes <out_prefix>_0.png, _1.png, ... (700 x 700).
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1:]
glb, out, tgt, size, views = a[0], a[1], Vector([float(v) for v in a[2].split(",")]), float(a[3]), a[4]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(Path(glb).resolve()))
scene = bpy.context.scene
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.resolution_x = scene.render.resolution_y = 700
scene.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.42, 0.43, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
scene.world = w
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(40), math.radians(-15), math.radians(-40))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = size
scene.collection.objects.link(cam)
scene.camera = cam
for k, v in enumerate(views.split(";")):
	az, el = [math.radians(float(x)) for x in v.split(",")]
	cam.location = tgt + Vector((-math.cos(az) * math.cos(el), math.sin(az) * math.cos(el), math.sin(el))) * 6
	cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = f"{out}_{k}.png"
	bpy.ops.render.render(write_still=True)
