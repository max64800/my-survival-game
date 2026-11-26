# F697 step 7 (owner, Nov 26): the bronze armour is made the healing-fountain way, NOT hand-built:
# ChatGPT painting (tools/art/sheets/bronze_armour_sheet_nov26.png) -> cut out -> TRELLIS.2 website -> this script.
# Owner's OK as an exception to model rule 1 (see docs/art/MODEL-RULES.md). This script:
#   - turns each piece to face the front (-Y), sizes it like the copper piece, bottom on the floor
#   - sets the metal look (TRELLIS leaves "metal" unset = full metal, which renders black)
#   - glues the paint seams, cuts the triangles down, drops loose crumbs
# Source models: journey/3d/trellis_bronze/<id>_trellis.glb (TRELLIS.2 website, MIT).
#   blender --background --factory-startup --python builds/bronze_armour_trellis.py -- [helm_bronze mail_bronze ...]
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
SRC = GAME / "journey" / "3d" / "trellis_bronze"
OUT = GAME / "assets" / "models" / "items"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "items"
TARGET_TRIS = 9000

# id: (height in m, turn in degrees about the up axis so the front faces -Y)
PIECES = {
	"helm_bronze": (0.27, 0.0),
	"mail_bronze": (0.45, 0.0),
	"greaves_bronze": (0.42, 0.0),
	"boots_bronze": (0.26, 0.0),
}


def load(item_id, height, turn):
	bpy.ops.import_scene.gltf(filepath=str(SRC / f"{item_id}_trellis.glb"))
	o = [x for x in bpy.context.scene.objects if x.type == "MESH"][0]
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	co = np.array([v.co for v in o.data.vertices])
	c, s = np.cos(np.radians(turn)), np.sin(np.radians(turn))
	co[:, 0], co[:, 1] = co[:, 0] * c - co[:, 1] * s, co[:, 0] * s + co[:, 1] * c  # turn the points (not the object)
	k = height / (co[:, 2].max() - co[:, 2].min())
	mid = (co.max(0) + co.min(0)) / 2
	co = (co - [mid[0], mid[1], co[:, 2].min()]) * k
	o.data.vertices.foreach_set("co", co.ravel())
	o.data.update()
	return o


def metal_look(o):
	b = o.active_material.node_tree.nodes["Principled BSDF"]
	b.inputs["Metallic"].default_value = 0.45
	b.inputs["Roughness"].default_value = 0.5


def tidy(o):
	"""Glue the paint seams first (or it tears apart), then fewer triangles, then drop loose crumbs."""
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.remove_doubles(threshold=0.001)
	bpy.ops.object.mode_set(mode="OBJECT")
	start = tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
	for _ in range(4):  # one pass stalls (at ~27k for the helm), so repeat until it is small enough
		if tris <= TARGET_TRIS * 1.15:
			break
		d = o.modifiers.new("dec", "DECIMATE")
		d.ratio = TARGET_TRIS / tris
		d.use_collapse_triangulate = True
		bpy.ops.object.modifier_apply(modifier="dec")
		tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
	print("TRIS", start, "->", tris)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.separate(type="LOOSE")
	bpy.ops.object.mode_set(mode="OBJECT")
	parts = [x for x in bpy.context.scene.objects if x.type == "MESH"]
	for x in parts:
		if len(x.data.polygons) < 60:
			bpy.data.objects.remove(x)
	kept = [x for x in bpy.context.scene.objects if x.type == "MESH"]
	print("TIDY parts kept", len(kept), "of", len(parts), [len(x.data.polygons) for x in kept])


ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT.mkdir(parents=True, exist_ok=True)
JOUR.mkdir(parents=True, exist_ok=True)
for item_id in ids or list(PIECES):
	kit.reset()
	height, turn = PIECES[item_id]
	o = load(item_id, height, turn)
	metal_look(o)
	tidy(o)
	out = OUT / f"{item_id}.glb"
	kit.save(str(out), str(JOUR / f"{item_id}.png"))
	shutil.copy(out, JOUR / f"{item_id}.glb")
