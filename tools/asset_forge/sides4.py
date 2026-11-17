# Four-side picture of building pieces, laid out like a turnaround sheet: one row per model, columns
# FRONT, SIDE (right), BACK, TOP, plus a 3/4 view. Flat orthographic views to compare with the ChatGPT sheet.
#   blender --background --factory-startup --python sides4.py -- <out.png> <a.glb> [b.glb ...]
# Godot front (+z) = Blender -y. Every row uses the same scale, so sizes compare.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

args = [a for a in sys.argv[sys.argv.index("--") + 1:] if a != "--tex"]
out, files = args[0], [Path(a) for a in args[1:]]
TILE = 360
VIEWS = [("front", (0, -1, 0)), ("side", (1, 0, 0)), ("back", (0, 1, 0)), ("top", (0, 0, 1)), ("3/4", (0.75, -1, 0.55))]

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sh = sc.display.shading
sh.light = "STUDIO"
sh.color_type = "TEXTURE" if "--tex" in sys.argv else "MATERIAL"   # --tex: show the paintings
sh.show_cavity = True
sh.cavity_type = "BOTH"
sh.show_shadows = False
sc.render.resolution_x = sc.render.resolution_y = TILE
sc.render.film_transparent = False
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.62, 0.62, 0.63)
cam_d = bpy.data.cameras.new("cam")
cam_d.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_d)
sc.collection.objects.link(cam)
sc.camera = cam

tmp = Path(out).with_suffix("")
tmp.mkdir(parents=True, exist_ok=True)
rows = []
for f in files:
	for o in list(bpy.data.objects):
		if o.type == "MESH":
			bpy.data.objects.remove(o)
	bpy.ops.import_scene.gltf(filepath=str(f))
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	lo = Vector((1e9,) * 3)
	hi = Vector((-1e9,) * 3)
	for o in objs:
		for c in o.bound_box:
			w = o.matrix_world @ Vector(c)
			lo = Vector(map(min, lo, w))
			hi = Vector(map(max, hi, w))
	ctr = (lo + hi) / 2
	cam_d.ortho_scale = 2.6
	row = []
	for name, d in VIEWS:
		dv = Vector(d).normalized()
		cam.location = ctr + dv * 10
		up = Vector((0, 1, 0)) if name == "top" else Vector((0, 0, 1))
		cam.rotation_euler = (-dv).to_track_quat("-Z", "Y").to_euler() if name != "top" else (0, 0, 0)
		p = tmp / f"{f.stem}_{name.replace('/', '')}.png"
		sc.render.filepath = str(p)
		bpy.ops.render.render(write_still=True)
		row.append(str(p))
	rows.append(row)

# Stitch with Blender's own image API (no PIL inside Blender).
W, H = TILE * len(VIEWS), TILE * len(rows)
canvas = bpy.data.images.new("sheet", W, H)
px = [0.0] * (W * H * 4)
for r, row in enumerate(rows):
	for c, p in enumerate(row):
		im = bpy.data.images.load(p)
		src = list(im.pixels)
		oy = (len(rows) - 1 - r) * TILE
		for y in range(TILE):
			a = (y * TILE) * 4
			b = ((oy + y) * W + c * TILE) * 4
			px[b:b + TILE * 4] = src[a:a + TILE * 4]
canvas.pixels = px
canvas.filepath_raw = out
canvas.file_format = "PNG"
canvas.save()
print("SHEET_OK", out)
