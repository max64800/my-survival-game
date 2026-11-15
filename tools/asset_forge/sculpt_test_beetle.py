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
LEG_NAMES = [o.name for o in bpy.context.scene.objects if o.name.startswith("leg_")]
all_legs = {n: split_by_material(bpy.data.objects[n]) for n in LEG_NAMES}
legparts = all_legs["leg_l0"]
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
shoot("leg_before.png", lc, 0.6, az=-80, el=12, res=(600, 600))

# ---- 1. melt + 2. carve
stone = parts["stone_plate"]
high_stone = cs.melt([stone], voxel=0.004, smooth=2, name="stone_high")
high_moss = cs.melt([parts["crack"]], voxel=0.006, smooth=1, name="moss_high")
cs.carve_moss(high_moss, height=0.075, cover=0.3)
amber_obj = parts["glow_back"]
cs.carve_stone(high_stone, seed=3)
# Legs: the armour segments stay separate hard pieces (like a real beetle leg); each gets a dense detailed copy
# (dents, grain) whose detail is baked onto the original faceted segment.
LEG_JOBS = []
for n, lp in all_legs.items():
	lo = lp["chitin"]
	hi = cs.detail_copy(lo, 2, n + "_high")
	cs.carve_chitin(hi, dents=0.0025, grain=0.0008, seed=len(LEG_JOBS) + 2)
	cs.uv_only(lo)
	clo = lp["claw"]
	chi = cs.detail_copy(clo, 1, n + "_claw_high")
	cs.carve_chitin(chi, dents=0.001, grain=0.0004)
	cs.uv_only(clo)
	LEG_JOBS.append((hi, lo, chi, clo, lp["chitin_dark"]))
print("melt+carve", round(time.time() - t0), "s; stone tris", len(high_stone.data.polygons))

# ---- paint materials on the dense sculpts
high_stone.data.materials.clear()
high_stone.data.materials.append(cs.paint_material("paint_stone", base=(0.52, 0.45, 0.39), dark=(0.3, 0.25, 0.26), light=(0.78, 0.7, 0.6),
	moss=(0.5, 0.58, 0.18), moss_amount=0.85, strokes=0.14, seed=1))
high_moss.data.materials.clear()
high_moss.data.materials.append(cs.paint_material("paint_moss", base=(0.5, 0.6, 0.16), dark=(0.16, 0.24, 0.05), light=(0.74, 0.82, 0.32),
	strokes=0.16, top_light=0.25, edge=0.3, seed=4))
amber_obj.data.materials.clear()
amber_obj.data.materials.append(cs.glow_paint("paint_amber", core=(1.0, 0.82, 0.25), rim=(0.88, 0.33, 0.02), lines=0.45))
paint_chitin = cs.paint_material("paint_chitin", base=(0.45, 0.22, 0.13), dark=(0.24, 0.1, 0.06), light=(0.72, 0.44, 0.3),
	strokes=0.1, top_light=0.3, edge=0.6, seed=2, key=0.45)
paint_claw = cs.paint_material("paint_claw", base=(0.8, 0.66, 0.46), dark=(0.52, 0.38, 0.22), light=(0.95, 0.87, 0.7),
	strokes=0.08, top_light=0.1, edge=0.4, seed=3)
for hi, lo, chi, clo, jo in LEG_JOBS:
	hi.data.materials.clear()
	hi.data.materials.append(paint_chitin)
	chi.data.materials.clear()
	chi.data.materials.append(paint_claw)
# ---- 3. light game copies + 4. bake
low_stone = cs.game_copy(high_stone, 9000, "stone_low")
low_moss = cs.game_copy(high_moss, 3000, "moss_low")
low_amber = cs.game_copy(amber_obj, 2000, "amber_low")
cs.bake(high_stone, low_stone, 2048, "stone_baked")
cs.bake(high_moss, low_moss, 1024, "moss_baked")
cs.bake(amber_obj, low_amber, 1024, "glow_amber_baked", normal=False, emissive=0.35)
for k, (hi, lo, chi, clo, jo) in enumerate(LEG_JOBS):
	cs.bake(hi, lo, 512, f"leg{k}_baked")
	cs.bake(chi, clo, 256, f"claw{k}_baked")
	jo.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*cs.lin((0.3, 0.14, 0.08)), 1)
print("bake", round(time.time() - t0), "s")
for o in [high_stone, high_moss, amber_obj] + [j[0] for j in LEG_JOBS] + [j[2] for j in LEG_JOBS]:
	o.hide_render = True
	o.hide_set(True)
shoot("after.png", (0, 0, 0.5), 1.7)
shoot("leg_after.png", lc, 0.6, az=-80, el=12, res=(600, 600))
bpy.ops.object.select_all(action="DESELECT")
for o in bpy.context.scene.objects:
	if o.type == "MESH" and not o.hide_get():
		o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out / "test.glb"), export_format="GLB", use_selection=True, export_yup=True,
	export_image_format="JPEG", export_image_quality=88)
print("SCULPT_TEST done", round(time.time() - t0), "s; low tris stone", sum(len(p.vertices) - 2 for p in low_stone.data.polygons))
