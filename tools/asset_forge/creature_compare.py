"""Side-by-side check: the approved picture next to the hand-built model, seen from the same angle (by Claude 3).

    blender --background --factory-startup --python tools/asset_forge/creature_compare.py -- <model.glb> <picture.png> <out.png> [az=-55] [el=24] [crop=x0,y0,x1,y1]

The model is photographed with an orthographic camera on the same light-grey background as the
ChatGPT pictures. az = degrees around the creature (0 = straight from the side it faces right on screen,
-90 = from the front), el = degrees from above. crop = the part of the picture to show (pixels), for grids.
"""
import math
from pathlib import Path
import sys

import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1:]
glb, pic, out = a[0], a[1], a[2]
opt = dict(x.split("=", 1) for x in a[3:] if "=" in x)
az, el = float(opt.get("az", -55)), float(opt.get("el", 24))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
ctr = (lo + hi) / 2
scene = bpy.context.scene
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y = 768, 512
scene.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.42, 0.43, 1)  # the pictures' light grey
w.node_tree.nodes["Background"].inputs[1].default_value = 1.4
scene.world = w
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(40), math.radians(-15), math.radians(-40))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = max((hi - lo).x, (hi - lo).y, (hi - lo).z) * 1.45
scene.collection.objects.link(cam)
scene.camera = cam
# Blender: the creature faces -Y. az=0: camera on -X (head on the right of the picture).
r = 6.0
th, ph = math.radians(az), math.radians(el)
cam.location = ctr + Vector((-math.cos(th) * math.cos(ph), math.sin(th) * math.cos(ph), math.sin(ph))) * r
cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
render = out[:-4] + "_model.png"
scene.render.filepath = render
bpy.ops.render.render(write_still=True)

# Paste the two side by side (Blender images, no extra Python packages needed).
ref = bpy.data.images.load(str(Path(pic).resolve()))
mod = bpy.data.images.load(render)
rw, rh = ref.size
rp = np.array(ref.pixels[:], dtype=np.float32).reshape(rh, rw, 4)
if "crop" in opt:
	x0, y0, x1, y1 = (int(v) for v in opt["crop"].split(","))
	rp = rp[rh - y1:rh - y0, x0:x1]  # Blender pixels start at the bottom row
H = 512
ys = (np.arange(H) * rp.shape[0] / H).astype(int)
Wr = int(rp.shape[1] * H / rp.shape[0])
xs = (np.arange(Wr) * rp.shape[1] / Wr).astype(int)
rp = rp[ys][:, xs]
mp = np.array(mod.pixels[:], dtype=np.float32).reshape(512, 768, 4)
canvas = np.concatenate([rp, mp], axis=1)
img = bpy.data.images.new("cmp", canvas.shape[1], H)
img.pixels = canvas.ravel()
img.filepath_raw = out
img.file_format = "PNG"
img.save()
print("COMPARE", out)
