# F782 round 3 (owner, Nov 22): the owner picked the TRELLIS shape over the hand-built fountain, as a one-time
# exception to model rule 1 (owner's OK). This script reworks it into our style:
#   - turned to face the front (-Y), sized to 1.2 m tall, bottom on the floor
#   - paint brightened (TRELLIS came out very dark)
#   - all the glowing water (basin pool + the pour from the mouth) cut out: hard to animate
#   - the basin filled with pebbles and our glowing green healing crystals, a small crystal in the mouth
#   - fewer triangles (65k -> about 16k), loose crumbs removed
# Source: journey/3d/trellis_f706/healing_fountain_trellis.glb (TRELLIS website, MIT, from our 4 ChatGPT views).
#   blender --background --factory-startup --python builds/healing_fountain_trellis.py -- [out.glb] [preview.png]
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import GAME, T, kit, rng  # noqa: E402
from night_materials import C, lump, _cm  # noqa: E402
from decor_nov21_a import floor_cut  # noqa: E402

SRC = GAME / "journey" / "3d" / "trellis_f706" / "healing_fountain_trellis.glb"
HEIGHT = 1.2
TARGET_TRIS = 16000
GEM = lambda: C((0.18, 0.8, 0.42), 0.15, glow=0.8)  # noqa: E731
GEM_PALE = lambda: C((0.35, 0.95, 0.6), 0.15, glow=0.9)  # noqa: E731


def load():
	bpy.ops.import_scene.gltf(filepath=str(SRC))
	o = [x for x in bpy.context.scene.objects if x.type == "MESH"][0]
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	# TRELLIS faces +X: turn the points (x, y) -> (y, -x) so the face and basin look to the front (-Y)
	for v in o.data.vertices:
		v.co = (v.co.y, -v.co.x, v.co.z)
	zs = [v.co.z for v in o.data.vertices]
	k = HEIGHT / (max(zs) - min(zs))
	z0 = min(zs)
	for v in o.data.vertices:
		v.co = ((v.co.x) * k, (v.co.y) * k, (v.co.z - z0) * k)
	return o


def brighten(o):
	img = [n.image for n in o.active_material.node_tree.nodes if n.type == "TEX_IMAGE"][0]
	px = np.array(img.pixels[:]).reshape(-1, 4)
	px[:, :3] = np.clip((px[:, :3] ** 0.6) * 1.2, 0, 1)   # lift the dark paint a lot, the darkest parts most
	img.pixels[:] = px.ravel()
	img.update()
	img.pack()
	m = o.active_material.node_tree.nodes["Principled BSDF"]
	m.inputs["Metallic"].default_value = 0.0    # TRELLIS leaves metal unset (= full metal, looks black)
	m.inputs["Roughness"].default_value = 0.9
	return img


def face_colours(o, img):
	w, h = img.size
	px = np.array(img.pixels[:]).reshape(h, w, 4)
	uv = o.data.uv_layers.active.data
	out = []
	for p in o.data.polygons:
		u = sum(uv[i].uv[0] for i in p.loop_indices) / p.loop_total
		v = sum(uv[i].uv[1] for i in p.loop_indices) / p.loop_total
		out.append(px[min(h - 1, int(v * h)), min(w - 1, int(u * w)), :3])
	return np.array(out)


def cut_water(o, cols_before):
	"""Delete every glowing-mint face (the pool and the pour). Returns the pool's centre, radius and height."""
	r, g, b = cols_before[:, 0], cols_before[:, 1], cols_before[:, 2]
	cents = np.array([tuple(p.center) for p in o.data.polygons])
	bright = (g > 0.3) & (g > r * 1.5) & (b > r * 1.1)   # the glowing pour and pool top
	dark = (g > 0.08) & (g > r * 1.3) & (b > r * 1.05) & (cents[:, 2] < 0.42)   # the darker teal water lower in the basin
	water = bright | dark
	pool = bright & (cents[:, 2] < 0.42)
	pc = cents[pool]
	centre = np.median(pc[:, :2], 0)
	radius = float(np.percentile(np.linalg.norm(pc[:, :2] - centre, axis=1), 99)) + 0.02
	level = float(np.median(pc[:, 2]))
	mouth = cents[water & (cents[:, 2] > 0.5)]
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bm.faces.ensure_lookup_table()
	bmesh.ops.delete(bm, geom=[bm.faces[i] for i in np.nonzero(water)[0]], context="FACES")
	bm.to_mesh(o.data)
	bm.free()
	print(f"CUT water faces {int(water.sum())}, pool centre {centre.round(2)} r {radius:.2f} level {level:.2f}, mouth faces {len(mouth)}")
	return centre, radius, level, (mouth.mean(0) if len(mouth) else None)


def tidy(o):
	"""Fewer triangles, and no little crumbs floating loose."""
	bpy.ops.object.mode_set(mode="EDIT")   # glue the paint-seam edges back together first, or it all falls apart
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.remove_doubles(threshold=0.002)
	bpy.ops.object.mode_set(mode="OBJECT")
	tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
	d = o.modifiers.new("dec", "DECIMATE")
	d.ratio = min(1.0, TARGET_TRIS / tris)
	d.use_collapse_triangulate = True
	bpy.ops.object.modifier_apply(modifier=d.name)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.separate(type="LOOSE")
	bpy.ops.object.mode_set(mode="OBJECT")
	parts = [x for x in bpy.context.scene.objects if x.type == "MESH"]
	big = max(parts, key=lambda x: len(x.data.polygons))
	for x in parts:
		if len(x.data.polygons) < 60:
			bpy.data.objects.remove(x)
	print("TIDY parts kept", len([x for x in bpy.context.scene.objects if x.type == "MESH"]), "of", len(parts))
	return big


def crystals(centre, radius, level, mouth):
	cx, cy = float(centre[0]), float(centre[1])
	bed = level - 0.03   # a pebble bed just under where the water was, covering the cut
	kit.cylinder(radius + 0.03, 0.05, (cx, cy, bed - 0.025), T("stone", "a"), verts=16, bevel=0.01)
	for i in range(10):
		a = i * 2.4
		rr = radius * (0.25 + (i % 3) * 0.3)
		lump((cx + math.cos(a) * rr, cy + math.sin(a) * rr, bed + 0.004), (0.06, 0.05, 0.035), T("limestone", "a"),
			seed=80 + i, rough=0.008)
	g, gp = GEM(), GEM_PALE()
	kit.crystal_cluster((cx, cy + 0.02, bed), 1.1, g, seed=7, n=6)
	for i, a in enumerate((200, 250, 300, 340, 20, 140)):
		rr = radius * 0.55
		x, y = cx + math.cos(math.radians(a)) * rr, cy + math.sin(math.radians(a)) * rr
		kit.crystal_cluster((x, y, bed), 0.6 + 0.1 * (i % 3), gp if i % 2 else g, seed=11 + i, n=3 + i % 3)
	if mouth is not None:   # a small crystal where the water poured out
		kit.crystal((float(mouth[0]), float(mouth[1]) + 0.06, float(mouth[2])), 0.03, 0.13, gp, tilt=(90, 0, 0), sides=6)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	jdir.mkdir(parents=True, exist_ok=True)
	out = Path(args[0]).resolve() if args else jdir / "healing_fountain_tr.glb"
	prev = Path(args[1]).resolve() if len(args) > 1 else jdir / "healing_fountain_tr.png"
	rng.seed(sum(map(ord, "healing_fountain_trellis")))
	kit.reset()
	_cm.clear()
	o = load()
	img = bpy.data.images[[n.image.name for n in o.active_material.node_tree.nodes if n.type == "TEX_IMAGE"][0]]
	# find the water on the ORIGINAL colours, before brightening
	w, h = img.size
	cols = face_colours(o, img)
	centre, radius, level, mouth = cut_water(o, cols)
	brighten(o)
	tidy(o)
	crystals(centre, radius, level, mouth)
	floor_cut()
	kit.save(str(out), str(prev))
	print(f"MODEL_OK healing_fountain_tr {out}")
