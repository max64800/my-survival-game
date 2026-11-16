"""The Rock Beetle's sculpt-and-bake pass (by Claude 3): the grey hand-built beetle in, the finished game beetle out.

    blender --background --factory-startup --python tools/asset_forge/sculpt_test_beetle.py -- <grey beetle.glb> <out folder>

Writes <out>/before.png, <out>/after.png (same camera), <out>/leg_before.png, <out>/leg_after.png and <out>/test.glb:
the game model (body + moving parts leg_l0..r2 and soft_stalk_l/r, each turning at its own hinge, baked pictures).
build_creatures.py runs this for the mossy look. Recipe and rules: docs/art/CREATURE-RECIPE.md.
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
LOOK = next((x[5:] for x in a[2:] if x.startswith("look=")), "mossy")
# Each look's paint (approved variants picture). Colours as picked by eye: (base, dark, light).
PALETTE = {
	"mossy": dict(stone=((0.52, 0.45, 0.39), (0.3, 0.25, 0.26), (0.78, 0.7, 0.6)), stone_moss=((0.44, 0.5, 0.2), 0.85), cap=None,
		moss=((0.42, 0.48, 0.18), (0.15, 0.19, 0.06), (0.62, 0.68, 0.3)), moss_h=0.075, moss_glow=0.0,
		amber=((1.0, 0.66, 0.16), (0.72, 0.2, 0.0)), chitin=((0.4, 0.29, 0.22), (0.2, 0.14, 0.1), (0.6, 0.47, 0.37)),
		belly=((0.3, 0.18, 0.12), (0.13, 0.07, 0.05), (0.5, 0.34, 0.24)), face=((0.37, 0.23, 0.15), (0.16, 0.09, 0.06), (0.6, 0.42, 0.3)),
		eyes=((0.12, 0.3, 0.08), (0.5, 0.78, 0.25), (0.04, 0.1, 0.03))),  # green (owner)
	"frost": dict(stone=((0.27, 0.31, 0.39), (0.1, 0.12, 0.17), (0.47, 0.53, 0.63)), stone_moss=((0.85, 0.9, 0.97), 0.4),
		cap=((0.93, 0.96, 1.0), 0.75),  # snow on the tops of the stones
		moss=((0.86, 0.91, 0.98), (0.58, 0.67, 0.8), (1.0, 1.0, 1.0)), moss_h=0.05, moss_glow=0.0,  # snow in the cracks
		amber=((0.75, 1.0, 1.0), (0.05, 0.5, 0.8)), chitin=((0.36, 0.38, 0.45), (0.15, 0.16, 0.21), (0.58, 0.61, 0.7)),
		belly=((0.26, 0.27, 0.32), (0.11, 0.12, 0.15), (0.44, 0.46, 0.53)), face=((0.33, 0.34, 0.4), (0.14, 0.15, 0.19), (0.55, 0.57, 0.65)),
		eyes=((0.08, 0.3, 0.48), (0.55, 0.88, 1.0), (0.03, 0.1, 0.18))),  # icy blue
	"ember": dict(stone=((0.29, 0.26, 0.25), (0.1, 0.08, 0.08), (0.5, 0.44, 0.41)), stone_moss=((0.95, 0.4, 0.08), 0.35), cap=None,
		moss=((1.0, 0.45, 0.08), (0.65, 0.12, 0.0), (1.0, 0.8, 0.35)), moss_h=0.012, moss_glow=0.9,  # glowing lava in the cracks
		amber=((1.0, 0.6, 0.12), (0.72, 0.12, 0.0)), chitin=((0.4, 0.26, 0.2), (0.19, 0.11, 0.08), (0.6, 0.44, 0.35)),
		belly=((0.28, 0.16, 0.11), (0.12, 0.06, 0.04), (0.48, 0.32, 0.22)), face=((0.36, 0.22, 0.15), (0.15, 0.08, 0.06), (0.58, 0.4, 0.29)),
		eyes=((0.55, 0.18, 0.02), (1.0, 0.68, 0.15), (0.2, 0.05, 0.0))),  # fiery orange
	"spore": dict(stone=((0.52, 0.36, 0.52), (0.23, 0.13, 0.25), (0.76, 0.58, 0.74)), stone_moss=((0.4, 0.46, 0.2), 0.55), cap=None,
		moss=((0.34, 0.4, 0.18), (0.13, 0.15, 0.07), (0.52, 0.58, 0.28)), moss_h=0.06, moss_glow=0.0,
		amber=((0.95, 0.7, 1.0), (0.45, 0.08, 0.68)), chitin=((0.43, 0.3, 0.39), (0.2, 0.12, 0.18), (0.63, 0.48, 0.59)),
		belly=((0.3, 0.19, 0.27), (0.13, 0.07, 0.12), (0.5, 0.35, 0.46)), face=((0.39, 0.26, 0.34), (0.16, 0.09, 0.14), (0.6, 0.44, 0.54)),
		eyes=((0.32, 0.1, 0.5), (0.8, 0.55, 1.0), (0.12, 0.03, 0.2))),  # violet
}
P = PALETTE[LOOK]
# The looks' own parts: material name -> (base, dark, light, glow strength)
EXTRA_PAINT = {
	"ice": ((0.72, 0.88, 0.98), (0.3, 0.52, 0.74), (0.96, 1.0, 1.0), 0.0),
	"glow_crystal": ((1.0, 0.66, 0.2), (0.8, 0.28, 0.02), (1.0, 0.9, 0.55), 0.6),
	"wood": ((0.45, 0.34, 0.25), (0.2, 0.14, 0.1), (0.66, 0.53, 0.4), 0.0),
	"glow_spore": ((0.74, 0.42, 0.92), (0.38, 0.12, 0.55), (0.95, 0.75, 1.0), 0.5),
	"mush_stem": ((0.84, 0.79, 0.74), (0.55, 0.48, 0.45), (0.97, 0.94, 0.9), 0.0),
}
out.mkdir(parents=True, exist_ok=True)
t0 = time.time()

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(Path(glb).resolve()))
HINGES = {o.name: o.matrix_world.translation.copy() for o in bpy.context.scene.objects if o.type == "MESH"}  # moving parts turn here
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
LEG_NAMES = [o.name for o in bpy.context.scene.objects if o.name.startswith(("leg_", "soft_stalk", "mandible_"))]  # moving parts
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
stone_pieces = cs.island_kd(stone)  # which stone is which, remembered before melting (each gets its own shade)
high_stone = cs.melt([stone], voxel=0.004, smooth=2, name="stone_high")
high_moss = cs.melt([parts["crack"]], voxel=0.006, smooth=1, name="moss_high")
cs.carve_moss(high_moss, height=P["moss_h"], cover=0.3)
amber_obj = parts["glow_back"]  # the cut gem: its flat facets stay the game copy; a dense copy gets painted
high_amber = cs.detail_copy(amber_obj, 3, "amber_high")
cs.uv_only(amber_obj)
cs.carve_stone(high_stone, seed=3)
cs.tint_islands(high_stone, stone_pieces, seed=3, spread=0.2)  # visible mix of shades (owner, round 8)
# Legs: the armour segments stay separate hard pieces (like a real beetle leg); each gets a dense detailed copy
# (dents, grain) whose detail is baked onto the original faceted segment.
LEG_JOBS = []
for n, lp in all_legs.items():
	if "chitin" not in lp:
		continue  # (the mandibles: below)
	lo = lp["chitin"]
	hi = cs.detail_copy(lo, 2, n + "_high")
	cs.carve_chitin(hi, dents=0.004, grain=0.001, seed=len(LEG_JOBS) + 2, grooves=0.0025, groove_scale=7.0, pits=0.0018)  # worn armour
	cs.uv_only(lo)
	clo = lp.get("claw")
	chi = None
	if clo:
		chi = cs.detail_copy(clo, 1, n + "_claw_high")
		cs.carve_chitin(chi, dents=0.001, grain=0.0004)
		cs.gradient_attr(chi)
		cs.uv_only(clo)
	LEG_JOBS.append((hi, lo, chi, clo, lp.get("chitin_dark")))
# Face: one melted skin (head, cheeks, sockets, lids, nose ridge, lips), sculpted; tusks and feelers/belly as hard pieces.
high_face = cs.melt([parts["face_skin"]], voxel=0.0028, smooth=3, name="face_high")
cs.carve_chitin(high_face, dents=0.0035, grain=0.0012, seed=7, grooves=0.003, groove_scale=9.0, pits=0.002)  # rough armour, not smooth
body_chitin = parts["chitin"]
high_body = cs.detail_copy(body_chitin, 1, "bodychitin_high")
cs.carve_chitin(high_body, dents=0.002, grain=0.0007, seed=8)
cs.uv_only(body_chitin)
belly = parts["chitin_dark"]  # the belly core (round 7: painted too)
high_belly = cs.detail_copy(belly, 1, "belly_high")
cs.carve_chitin(high_belly, dents=0.003, grain=0.0008, seed=9, grooves=0.002, groove_scale=6.0)
cs.uv_only(belly)
TUSK_JOBS = []  # the mandibles: moving parts (they click), each sculpted and baked on its own
for n, lp in all_legs.items():
	if "mandible" in lp:
		lo = lp["mandible"]
		hi = cs.detail_copy(lo, 2, n + "_high")
		cs.carve_chitin(hi, dents=0.0025, grain=0.0008, seed=11 + len(TUSK_JOBS), pits=0.0015)  # worn, chipped
		cs.gradient_attr(hi)
		cs.uv_only(lo)
		TUSK_JOBS.append((hi, lo))
# Eyes: one ball each; the iris, pupil and shine are painted on (looking where the build aims them: EYE_LOOK).
eyes = parts["eye"]
high_eyes = cs.detail_copy(eyes, 3, "eyes_high")
cs.eye_attrs(high_eyes, lambda side: (side * 0.12, -1, -0.1))
cs.uv_only(eyes)
EXTRA_JOBS = []
for name, (eb, ed, el, eg) in EXTRA_PAINT.items():
	if name in parts:
		lo = parts[name]
		hi = cs.detail_copy(lo, 1, name + "_high")
		cs.carve_chitin(hi, dents=0.002, grain=0.0008, seed=13 + len(EXTRA_JOBS))
		cs.uv_only(lo)
		hi.data.materials.clear()
		hi.data.materials.append(cs.glow_paint("paint_" + name, core=el, rim=ed, lines=0.3, cells=4.0, facets=0.4) if eg else
			cs.paint_material("paint_" + name, base=eb, dark=ed, light=el, strokes=0.12, top_light=0.2, edge=0.6, seed=14, grime=0.2))
		EXTRA_JOBS.append((hi, lo, name, eg))
print("melt+carve", round(time.time() - t0), "s; stone tris", len(high_stone.data.polygons))

# ---- paint materials on the dense sculpts
high_stone.data.materials.clear()
high_stone.data.materials.append(cs.paint_material("paint_stone", base=P["stone"][0], dark=P["stone"][1], light=P["stone"][2],
	moss=P["stone_moss"][0], moss_amount=P["stone_moss"][1], cap=P["cap"], strokes=0.16, edge=0.5, seed=1, tint_attr="tint", scratches=1.0, grime=0.35,
	scratch_width=2.2))  # big, readable scratches (owner, round 6)
high_moss.data.materials.clear()
high_moss.data.materials.append(cs.paint_material("paint_moss", base=P["moss"][0], dark=P["moss"][1], light=P["moss"][2],
	strokes=0.16, top_light=0.25, edge=0.3, seed=4))
high_amber.data.materials.clear()
high_amber.data.materials.append(cs.glow_paint("paint_amber", core=P["amber"][0], rim=P["amber"][1], lines=0.45, cells=3.0,
	facets=0.45, cloud=0.45, bubbles=0.85, creases=0.6, depth=0.3))  # deep orange, a lantern-bright middle
paint_chitin = cs.paint_material("paint_chitin", base=P["chitin"][0], dark=P["chitin"][1], light=P["chitin"][2],
	strokes=0.14, top_light=0.3, edge=0.7, seed=2, key=0.22, grime=0.3)  # worn legs (carved wear; painted scratches blotch on small parts)
paint_claw = cs.paint_material("paint_claw", base=(0.8, 0.66, 0.46), dark=(0.52, 0.38, 0.22), light=(0.95, 0.87, 0.7),
	strokes=0.08, top_light=0.1, edge=0.4, seed=3, root=(0.33, 0.2, 0.12))
for hi, lo, chi, clo, jo in LEG_JOBS:
	hi.data.materials.clear()
	hi.data.materials.append(paint_chitin)
	if chi:
		chi.data.materials.clear()
		chi.data.materials.append(paint_claw)
high_belly.data.materials.clear()
high_belly.data.materials.append(cs.paint_material("paint_belly", base=P["belly"][0], dark=P["belly"][1], light=P["belly"][2],
	strokes=0.14, top_light=0.1, edge=0.6, seed=12, grime=0.3))
high_face.data.materials.clear()
high_face.data.materials.append(cs.paint_material("paint_face", base=P["face"][0], dark=P["face"][1], light=P["face"][2],
	strokes=0.16, top_light=0.25, edge=0.7, seed=5, key=0.4, ao_local=True, grime=0.4))  # (painted scratches blotch on small parts)
high_body.data.materials.clear()
high_body.data.materials.append(paint_chitin)
paint_mandible = (cs.paint_material("paint_mandible", base=(0.6, 0.58, 0.55), dark=(0.32, 0.31, 0.3),
	light=(0.86, 0.85, 0.82), strokes=0.1, top_light=0.15, edge=0.5, seed=6, root=(0.3, 0.27, 0.25), grime=0.25))
for hi, lo in TUSK_JOBS:
	hi.data.materials.clear()
	hi.data.materials.append(paint_mandible)
high_eyes.data.materials.clear()
high_eyes.data.materials.append(cs.paint_eye("paint_eye", iris_out=P["eyes"][0], iris_in=P["eyes"][1],
	ring=P["eyes"][2]))  # each look its own colour (mossy green, frost blue, ember orange, spore violet)
for name, rgb in ():  # (nothing plain left on the body)
	if name in parts:
		bsdf = parts[name].data.materials[0].node_tree.nodes["Principled BSDF"]
		bsdf.inputs["Base Color"].default_value = (*cs.lin(rgb), 1)
		bsdf.inputs["Roughness"].default_value = 0.9
# ---- 3. light game copies + 4. bake
low_stone = cs.game_copy(high_stone, 9000, "stone_low")
low_moss = cs.game_copy(high_moss, 3000, "moss_low")
cs.bake(high_stone, low_stone, 2048, "stone_baked")
low_face = cs.game_copy(high_face, 0, "face_low", remesh=0.007)
cs.bake(high_face, low_face, 1024, "face_baked")
cs.bake(high_body, body_chitin, 1024, "bodychitin_baked")
for k, (hi, lo) in enumerate(TUSK_JOBS):
	cs.bake(hi, lo, 512, f"tusks{k}_baked")
cs.bake(high_belly, belly, 512, "belly_baked")
cs.bake(high_moss, low_moss, 1024, "glow_lava_baked" if P["moss_glow"] else "moss_baked", emissive=P["moss_glow"])  # ember: lava glows
cs.bake(high_amber, amber_obj, 1024, "glow_amber_baked", normal=False, emissive=0.35)
cs.bake(high_eyes, eyes, 512, "eye_baked", normal=False)
for hi, lo, name, eg in EXTRA_JOBS:
	cs.bake(hi, lo, 512, name + "_baked", normal=not eg, emissive=eg)
eyes.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.2  # wet shine
for k, (hi, lo, chi, clo, jo) in enumerate(LEG_JOBS):
	cs.bake(hi, lo, 512, f"leg{k}_baked")
	if chi:
		cs.bake(chi, clo, 256, f"claw{k}_baked")
	if jo:
		jo.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*cs.lin((0.24, 0.14, 0.09)), 1)
print("bake", round(time.time() - t0), "s")
for o in [high_stone, high_moss, high_amber, high_face, high_body, high_eyes, high_belly] + [j[0] for j in TUSK_JOBS] + [j[0] for j in EXTRA_JOBS] + [j[0] for j in LEG_JOBS] + [j[2] for j in LEG_JOBS if j[2]]:
	o.hide_render = True
	o.hide_set(True)
shoot("after.png", (0, 0, 0.5), 1.7)
shoot("leg_after.png", lc, 0.6, az=-80, el=12, res=(600, 600))
# ---- 5. the game model: each moving part joined into one piece turning at its hinge; everything else is the body
moving = set()
for n, lp in all_legs.items():
	pieces = [o for o in lp.values() if o.name in bpy.data.objects and not o.hide_get()]
	bpy.ops.object.select_all(action="DESELECT")
	for o in pieces:
		o.select_set(True)
	bpy.context.view_layer.objects.active = pieces[0]
	if len(pieces) > 1:
		bpy.ops.object.join()
	part = bpy.context.view_layer.objects.active
	part.name = n
	scene.cursor.location = HINGES[n]
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	moving.add(part)
rest = [o for o in scene.objects if o.type == "MESH" and not o.hide_get() and o not in moving]
bpy.ops.object.select_all(action="DESELECT")
for o in rest:
	o.select_set(True)
bpy.context.view_layer.objects.active = rest[0]
bpy.ops.object.join()
bpy.context.view_layer.objects.active.name = "body"
bpy.ops.object.select_all(action="DESELECT")
for o in bpy.context.scene.objects:
	if o.type == "MESH" and not o.hide_get():
		o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out / "test.glb"), export_format="GLB", use_selection=True, export_yup=True,
	export_image_format="JPEG", export_image_quality=88)
print("SCULPT_TEST done", round(time.time() - t0), "s; parts", sorted(o.name for o in scene.objects if o.type == "MESH" and not o.hide_get()))
