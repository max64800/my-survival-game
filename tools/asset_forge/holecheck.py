# See-through check (owner, Nov 17: "I don't want any holes"): renders a building piece straight from the front
# and the back with an empty, transparent background and counts background pixels INSIDE the piece's outline
# (its box, minus a round door opening if given). Any count above 0 = a hole you can see through.
#   blender --background --factory-startup --python holecheck.py -- <a.glb> [door] [rect=x0,x1,y0,y1] [maxz=<m>] [out.png]
import math
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
path = args[0]
door = "door" in args
png = next((a for a in args if a.endswith(".png")), None)
rect = next((tuple(map(float, a[5:].split(","))) for a in args if a.startswith("rect=")), None)  # a window: x0,x1,y0,y1
maxz = next((float(a[5:]) for a in args if a.startswith("maxz=")), None)   # battlements: only below the gaps
RES = 800
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.render.resolution_x = sc.render.resolution_y = RES
sc.render.film_transparent = True
sc.render.image_settings.color_mode = "RGBA"
bpy.ops.import_scene.gltf(filepath=path)
objs = [o for o in bpy.data.objects if o.type == "MESH"]
lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
for o in objs:
	for c in o.bound_box:
		w = o.matrix_world @ Vector(c)
		lo, hi = Vector(map(min, lo, w)), Vector(map(max, hi, w))
ctr = (lo + hi) / 2
cd = bpy.data.cameras.new("c")
cd.type = "ORTHO"
cd.ortho_scale = 2.2
cam = bpy.data.objects.new("c", cd)
sc.collection.objects.link(cam)
sc.camera = cam
total = 0
for name, dv in (("front", Vector((0, -1, 0))), ("back", Vector((0, 1, 0)))):
	cam.location = ctr + dv * 10
	cam.rotation_euler = (-dv).to_track_quat("-Z", "Y").to_euler()
	sc.render.filepath = (png or "//tmp_hole.png").replace(".png", f"_{name}.png")
	bpy.ops.render.render(write_still=True)
	im = bpy.data.images.load(sc.render.filepath)
	px = im.pixels[:]
	scale = RES / cd.ortho_scale
	holes = 0
	for yy in range(RES):
		wz = ctr.z + (yy - RES / 2) / scale          # world height of this pixel row
		if wz < lo.z + 0.03 or wz > (maxz if maxz is not None else hi.z) - 0.03:
			continue
		for xx in range(RES):
			wx = (xx - RES / 2) / scale * (1 if name == "front" else -1) + ctr.x
			if wx < lo.x + 0.03 or wx > hi.x - 0.03:
				continue
			if door and wx * wx + (wz - 0.70) ** 2 < 0.86 ** 2:
				continue   # the doorway's opening (radius 0.79) and the notches between ring stones along its edge
			if rect and rect[0] - 0.03 < wx < rect[1] + 0.03 and rect[2] - 0.03 < wz < rect[3] + 0.03:
				continue   # the window opening is meant to be open
			if px[(yy * RES + xx) * 4 + 3] < 0.5:
				holes += 1
	print(f"HOLES {name} {holes}")
	total += holes
print("HOLES_TOTAL", total)
