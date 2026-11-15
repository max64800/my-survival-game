"""Outline check for a creature against its turnaround sheet (by Claude 3).

    blender --background --factory-startup --python tools/asset_forge/creature_fit.py -- <model.glb> <turnaround.png> <boxes.json> <out_folder> [px=400] [grey]

The turnaround sheet shows the creature straight from the front, side (head on the left), back and top (head up),
all at one scale. boxes.json gives each view's box in the picture: {"front": {"x0","x1","y0","y1"}, ...}.
For each view the model's outline is drawn with the same scale (px pixels per metre), standing on the same ground
line (the lowest pixel), centred like the drawing, and compared:
    overlap score (IoU) = pixels in both / pixels in either.  1.0 = identical outline.
Writes <out>/fit_<view>.png (drawing, model outline in red, missing parts blue, extra parts red-tinted),
<out>/fit_all.png and, with "grey", <out>/grey_all.png (drawing | grey model, same view) for the shape review.
Prints FIT <view> <score> for each view.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

a = sys.argv[sys.argv.index("--") + 1:]
glb, pic, boxes_file, out = a[0], a[1], a[2], Path(a[3])
opt = dict(x.split("=", 1) for x in a[4:] if "=" in x)
PX = float(opt.get("px", 400))
GREY = "grey" in a[4:]
out.mkdir(parents=True, exist_ok=True)
boxes = json.load(open(boxes_file))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(Path(glb).resolve()))
objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
scene = bpy.context.scene
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
scene.collection.objects.link(cam)
scene.camera = cam

ref = bpy.data.images.load(str(Path(pic).resolve()))
RW, RH = ref.size
refpx = np.array(ref.pixels[:], dtype=np.float32).reshape(RH, RW, 4)[::-1, :, :3]  # top row first
bg = np.median(refpx[:20].reshape(-1, 3), axis=0)

# Blender: the creature faces -Y, +Z up. Camera direction and the screen's right/up axes for each view.
VIEWS = {
	"front": dict(loc=Vector((0, -10, 0)), right=Vector((1, 0, 0)), up=Vector((0, 0, 1))),
	"side": dict(loc=Vector((10, 0, 0)), right=Vector((0, 1, 0)), up=Vector((0, 0, 1))),
	"back": dict(loc=Vector((0, 10, 0)), right=Vector((-1, 0, 0)), up=Vector((0, 0, 1))),
	"top": dict(loc=Vector((0, 0, 10)), right=Vector((-1, 0, 0)), up=Vector((0, -1, 0))),
}


def model_extent(v):
	pts = [o.matrix_world @ Vector(c) for o in objs for vv in [o.data.vertices] for c in (x.co for x in vv)]
	r = [p.dot(v["right"]) for p in pts]
	u = [p.dot(v["up"]) for p in pts]
	return min(r), max(r), min(u), max(u)


def render_mask(name, v, w, h, centre_r, centre_u, flat=True):
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "FLAT" if flat else "STUDIO"
	scene.display.shading.color_type = "SINGLE"
	scene.display.shading.single_color = (1, 1, 1) if flat else (0.62, 0.6, 0.57)
	scene.display.shading.show_cavity = not flat
	scene.display.shading.cavity_type = "BOTH"
	scene.view_settings.view_transform = "Standard"
	world = bpy.data.worlds.get("w") or bpy.data.worlds.new("w")
	world.color = (0, 0, 0) if flat else (0.6, 0.6, 0.61)
	scene.world = world
	scene.render.film_transparent = False
	scene.render.resolution_x, scene.render.resolution_y = w, h
	cam.data.ortho_scale = max(w, h) / PX
	d = v["loc"].normalized()
	cam.location = v["right"] * centre_r + v["up"] * centre_u + d * 10
	# camera: local X = screen right, local Y = screen up, local Z = back toward the camera
	cam.rotation_euler = Matrix((v["right"], v["up"], d)).transposed().to_euler()
	path = str(out / f"_{name}.png")
	scene.render.filepath = path
	bpy.ops.render.render(write_still=True)
	img = bpy.data.images.load(path, check_existing=False)
	px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1, :, :3]
	bpy.data.images.remove(img)
	return px


def save_png(arr, path):
	h, w, _ = arr.shape
	img = bpy.data.images.new("o", w, h)
	rgba = np.concatenate([arr, np.ones((h, w, 1), np.float32)], axis=2)[::-1]
	img.pixels = rgba.ravel()
	img.filepath_raw = str(path)
	img.file_format = "PNG"
	img.save()
	bpy.data.images.remove(img)


rows, greys, scores = [], [], {}
M = 30
for name, v in VIEWS.items():
	b = boxes[name]
	x0, x1, y0, y1 = max(0, b["x0"] - M), min(RW, b["x1"] + M), max(0, b["y0"] - M), min(RH, b["y1"] + M)
	crop = refpx[y0:y1, x0:x1]
	w, h = crop.shape[1], crop.shape[0]
	want = np.abs(crop - bg).sum(2) > 40 / 255
	lr, hr, lu, hu = model_extent(v)
	cr = (lr + hr) / 2  # model centred on the drawing's centre
	# vertical: ground line (lowest drawn pixel) = model bottom, except the top view (centred)
	if name == "top":
		cu = (lu + hu) / 2
	else:
		ground = b["y1"] - y0  # pixel row of the ground in the crop
		cu = lu + (ground - h / 2) / PX  # put model bottom on that row
	mask0 = render_mask(name, v, w, h, cr, cu)[:, :, 0] > 0.5
	# Slide the model a little to find the best line-up (the drawings are not exactly centred; the ground stays put
	# except in the top view).
	best = (-1.0, 0, 0)
	for dy in (range(-24, 25, 4) if name == "top" else (0,)):
		for dx in range(-30, 31, 3):
			m = np.roll(np.roll(mask0, dy, 0), dx, 1)
			sc = (m & want).sum() / max(1, (m | want).sum())
			if sc > best[0]:
				best = (sc, dx, dy)
	score, dx, dy = best
	mask = np.roll(np.roll(mask0, dy, 0), dx, 1)
	cr -= dx / PX  # (so the grey picture lines up the same way)
	cu += dy / PX
	scores[name] = score
	print(f"FIT {name} {score:.3f}")
	vis = crop * 0.75 + 0.25
	vis[want & ~mask] = vis[want & ~mask] * 0.4 + np.array([0.1, 0.3, 1.0]) * 0.6   # drawing has it, model doesn't: blue
	vis[mask & ~want] = vis[mask & ~want] * 0.4 + np.array([1.0, 0.1, 0.1]) * 0.6   # model has it, drawing doesn't: red
	edge = mask ^ np.roll(mask, 1, 0) | mask ^ np.roll(mask, 1, 1)
	vis[edge] = (1, 0, 0)
	save_png(vis, out / f"fit_{name}.png")
	rows.append(vis)
	if GREY:
		g = render_mask(name, v, w, h, cr, cu, flat=False)
		greys.append(np.concatenate([crop, g], axis=1))


def stack(imgs, horizontal=True):
	H = max(i.shape[0] for i in imgs)
	pad = [np.concatenate([i, np.full((H - i.shape[0], i.shape[1], 3), 0.8, np.float32)], axis=0) for i in imgs]
	return np.concatenate(pad, axis=1)


save_png(stack(rows), out / "fit_all.png")
if GREY:
	save_png(np.concatenate([np.concatenate([g, np.full((g.shape[0], max(x.shape[1] for x in greys) - g.shape[1], 3), 0.8, np.float32)], axis=1) for g in greys], axis=0), out / "grey_all.png")
print("FIT mean %.3f" % (sum(scores.values()) / len(scores)))
