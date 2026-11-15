"""Small test of the sculpt-and-bake process on the Rock Beetle's shell plates and one leg (by Claude 3).

    blender --background --factory-startup --python tools/asset_forge/sculpt_test_beetle.py -- <grey beetle.glb> <out folder>

Writes <out>/before.png, <out>/after.png (same camera), <out>/leg_before.png, <out>/leg_after.png and <out>/test.glb.
"""
import math
import sys
import time
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creature_sculpt as cs  # noqa: E402

a = sys.argv[sys.argv.index("--") + 1:]
glb, out = a[0], Path(a[1])
out.mkdir(parents=True, exist_ok=True)
t0 = time.time()

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(Path(glb).resolve()))
for o in list(bpy.context.scene.objects):
	if o.type == "MESH":
		cs._select_only(o)
		bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def split_by_material(o):
	cs._select_only(o)
	bpy.ops.mesh.separate(type="MATERIAL")
	return {p.data.materials[0].name: p for p in bpy.context.selected_objects if p.data.materials}


body = bpy.data.objects["body"]
parts = split_by_material(body)
leg = bpy.data.objects["leg_l0"]
legparts = split_by_material(leg)
print("materials:", sorted(parts), sorted(legparts))

# ---- camera + light (shared by before/after)
scene = bpy.context.scene
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.42, 0.43, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
scene.world = w
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(40), math.radians(-15), math.radians(-40))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
scene.collection.objects.link(cam)
scene.camera = cam
scene.view_settings.view_transform = "Standard"


def shoot(path, target, size, az=-42, el=18, res=(900, 700)):
	engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
	scene.render.resolution_x, scene.render.resolution_y = res
	cam.data.ortho_scale = size
	th, ph = math.radians(az), math.radians(el)
	cam.location = Vector(target) + Vector((-math.cos(th) * math.cos(ph), math.sin(th) * math.cos(ph), math.sin(ph))) * 6
	cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = str(out / path)
	bpy.ops.render.render(write_still=True)


legc = sum((Vector(c) for c in leg.bound_box), Vector()) / 8 if leg.name in bpy.data.objects else Vector((-0.4, -0.3, 0.2))
LEGT = [o for o in legparts.values()]
lc = sum((o.matrix_world @ (sum((Vector(c) for c in o.bound_box), Vector()) / 8) for o in LEGT), Vector()) / len(LEGT)
shoot("before.png", (0, 0, 0.5), 1.7)
shoot("leg_before.png", lc, 0.75, az=-70, el=15, res=(600, 600))

# ---- 1. melt + 2. carve
stone = parts["stone_plate"]
high_stone = cs.melt([stone], voxel=0.004, smooth=2, name="stone_high")
cs.carve_stone(high_stone, seed=3)
chitin_objs = [o for k, o in legparts.items() if k.startswith("chitin")]
high_leg = cs.melt(chitin_objs, voxel=0.003, smooth=2, name="leg_high")
cs.carve_chitin(high_leg)
high_claw = cs.melt([legparts["claw"]], voxel=0.0025, smooth=4, name="claw_high")
cs.carve_chitin(high_claw, dents=0.0015, grain=0.0006)
print("melt+carve", round(time.time() - t0), "s; stone tris", len(high_stone.data.polygons), "leg", len(high_leg.data.polygons))

# ---- paint materials on the dense sculpts
high_stone.data.materials.clear()
high_stone.data.materials.append(cs.paint_material("paint_stone", base=(0.56, 0.5, 0.45), dark=(0.36, 0.31, 0.27), light=(0.76, 0.71, 0.64),
	moss=(0.42, 0.5, 0.16), moss_amount=0.55, strokes=0.14, seed=1))
high_leg.data.materials.clear()
high_leg.data.materials.append(cs.paint_material("paint_chitin", base=(0.47, 0.25, 0.16), dark=(0.27, 0.12, 0.07), light=(0.66, 0.4, 0.27),
	strokes=0.1, top_light=0.12, edge=0.45, seed=2))
high_claw.data.materials.clear()
high_claw.data.materials.append(cs.paint_material("paint_claw", base=(0.8, 0.66, 0.46), dark=(0.52, 0.38, 0.22), light=(0.95, 0.87, 0.7),
	strokes=0.08, top_light=0.1, edge=0.4, seed=3))

# ---- 3. light game copies + 4. bake
low_stone = cs.game_copy(high_stone, 9000, "stone_low")
low_leg = cs.game_copy(high_leg, 1600, "leg_low")
low_claw = cs.game_copy(high_claw, 300, "claw_low")
cs.bake(high_stone, low_stone, 2048, "stone_baked")
cs.bake(high_leg, low_leg, 512, "leg_baked")
cs.bake(high_claw, low_claw, 256, "claw_baked")
print("bake", round(time.time() - t0), "s")
for o in (high_stone, high_leg, high_claw):
	o.hide_render = True
	o.hide_set(True)
shoot("after.png", (0, 0, 0.5), 1.7)
shoot("leg_after.png", lc, 0.75, az=-70, el=15, res=(600, 600))
bpy.ops.object.select_all(action="DESELECT")
for o in bpy.context.scene.objects:
	if o.type == "MESH" and not o.hide_get():
		o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out / "test.glb"), export_format="GLB", use_selection=True, export_yup=True,
	export_image_format="JPEG", export_image_quality=88)
print("SCULPT_TEST done", round(time.time() - t0), "s; low tris stone", sum(len(p.vertices) - 2 for p in low_stone.data.polygons))
