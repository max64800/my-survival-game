# Bronze try-on (F697, Nov 26): the dwarf body wearing the bronze set, for the 3D page (not the worn set in the game).
# The hand-built mail/greaves/boots are made round the dwarf at half size (items_gear.py to_item), so they only
# grow 2x and go back in place; the TRELLIS helm has no real size, so it is fitted to the head.
#   blender --background --factory-startup --python tools/asset_forge/bronze_tryon.py -- <out_dir> [render]
#   then: python tools/asset_forge/dwarf_page_copy.py <out_dir>/tryon.glb <out_dir>/tryon.json size=512
import sys, math
from pathlib import Path
import bpy, numpy as np
from mathutils import Matrix, Vector

G = str(Path(__file__).resolve().parents[2])
S = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=G + "/assets/characters/dwarf/dwarf_body.glb")
for o in list(bpy.context.scene.objects):
	if o.name == "Icosphere":
		bpy.data.objects.remove(o)


def bbox(objs):
	co = np.array([o.matrix_world @ v.co for o in objs for v in o.data.vertices])
	return co.min(0), co.max(0)


def fit(objs, lo, hi):
	a, b = bbox(objs)
	k = (np.array(hi) - np.array(lo)) / (b - a)
	for o in objs:
		mw = o.matrix_world.copy()
		for v in o.data.vertices:
			p = np.array(mw @ v.co)
			v.co = Vector((np.array(lo) + (p - a) * k).tolist())
		o.matrix_world = o.matrix_world.Identity(4)
		o.data.update()


def load(name):
	before = set(bpy.context.scene.objects)
	bpy.ops.import_scene.gltf(filepath=G + f"/assets/models/items/{name}.glb")
	objs = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
	for o in objs:  # bake transforms into the points
		o.data.transform(o.matrix_world)
		o.matrix_world = o.matrix_world.Identity(4)
		o.parent = None
	return objs


def split_lr(objs):
	"""Pairs: separate loose parts, then sort them into the x<0 and x>0 piece."""
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.separate(type="LOOSE")
	bpy.ops.object.mode_set(mode="OBJECT")
	parts = [o for o in bpy.context.selected_objects if o.type == "MESH"]
	left, right = [], []
	for o in parts:
		cx = np.mean([v.co.x for v in o.data.vertices])
		(right if cx < 0 else left).append(o)
	return right, left


fit(load("helm_bronze"), (-0.25, -0.2, 1.07), (0.25, 0.27, 1.39))  # TRELLIS helm: no real size, fitted to the head


def wear(name, y, z):
	"""Hand-built pieces are made round the dwarf at half size: only grow them 2x and put them back in place."""
	for o in load(name):
		o.data.transform(Matrix.Translation((0, y, z)) @ Matrix.Scale(2, 4))


wear("mail_bronze", -0.0398, 0.2805)
wear("greaves_bronze", -0.0198, 0.158)
wear("boots_bronze", -0.0393, 0.0)

if "render" in sys.argv:
	sc = bpy.context.scene
	sc.render.engine = "BLENDER_EEVEE"
	sc.render.resolution_x, sc.render.resolution_y = 700, 800
	w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
	w.node_tree.nodes["Background"].inputs[0].default_value = (0.45, 0.43, 0.42, 1)
	w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sc.collection.objects.link(sun)
	sun.data.energy = 3.5; sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
	for name, ang in (("front", -90), ("side", -40)):
		a = math.radians(ang)
		cam.location = (3.2 * math.cos(a), 3.2 * math.sin(a), 0.75)
		d = Vector((0, 0, 0.65)) - cam.location
		cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
		cam.data.lens = 50
		sc.render.filepath = S + f"/tryon_{name}.png"
		bpy.ops.render.render(write_still=True)
else:
	for o in bpy.context.scene.objects:  # static preview: drop the skeleton link (he stays in his rest pose)
		for m in list(getattr(o, "modifiers", [])):
			if m.type == "ARMATURE":
				o.modifiers.remove(m)
	for o in list(bpy.context.scene.objects):
		if o.type == "ARMATURE":
			bpy.data.objects.remove(o)
	bpy.ops.export_scene.gltf(filepath=S + "/tryon.glb", export_format="GLB", export_animations=False, export_skins=False)
