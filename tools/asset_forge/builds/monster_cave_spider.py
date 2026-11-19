# Cave Spider, a small Zone 1 pest (owner, Nov 19, 2026: "the spider is a Zone 1 pest"; decisions in
# docs/research/asset-picks-placement.md). The free CC0 spider from Quaternius' Easy Animated Enemy Pack
# (tools/asset_forge/packs/quaternius_easy_enemies/Spider.blend) rebuilt by script the Rock Beetle way
# (MODEL-RULES rule 1 as bent for free packs): its shape kept at rest, cut into moving parts by its own bones
# (body + leg_l0..3 / leg_r0..3, each turning at the hip, see docs/design/creature-craft.md), repainted with our
# hand-painted creature skins; the eyes use the "eye" material the game flashes before a bite.
#
#   blender --background --factory-startup --python builds/monster_cave_spider.py -- <out.glb> [preview.png] [v=0..3]
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402

SRC = Path(__file__).resolve().parents[1] / "packs" / "quaternius_easy_enemies" / "Spider.blend"
SIZE = 0.95  ## across the legs (m): a small pest next to the 1.2 m Rock Beetle
LEGS = ["FrontLeg", "MidFrontLeg", "MidBackLeg", "BackLeg"]  ## front to back -> leg_?0..3
# Versions (every spider a bit different): skin, eye colour.
VERSIONS = [("chitin", (1.0, 0.25, 0.15)), ("beetle_rock_dark", (1.0, 0.55, 0.15)),
	("shell_rock_dark", (0.6, 1.0, 0.35)), ("chitin", (0.75, 0.35, 1.0))]
MODELS = ["cave_spider_v0", "cave_spider_v1", "cave_spider_v2", "cave_spider_v3"]  ## (spelled out for the model-rules test)


def build(out, preview=None, v=0):
	ck.reset()
	for o in list(bpy.data.objects):
		bpy.data.objects.remove(o, do_unlink=True)
	with bpy.data.libraries.load(str(SRC)) as (src, dst):
		dst.objects = ["Cube", "HumanArmature"]
	mesh, arm = dst.objects
	for o in (mesh, arm):
		bpy.context.scene.collection.objects.link(o)
	hips = {}  # leg bone -> hip in the mesh's space (rest pose)
	for b in arm.data.bones:
		hips[b.name] = arm.matrix_world @ b.head_local
	for m in list(mesh.modifiers):
		mesh.modifiers.remove(m)  # the spider at rest (its bind pose), no animation
	mw = mesh.matrix_world.copy()
	mesh.parent = None
	mesh.matrix_world = mw
	bpy.data.objects.remove(arm, do_unlink=True)
	bpy.context.view_layer.objects.active = mesh
	mesh.select_set(True)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	# Face -Y (the kit's front): the head must be on the -Y side.
	turn = hips["Head"].y > hips["Abdomen"].y
	# Each vertex belongs to the bone that moves it most.
	names = {g.index: g.name for g in mesh.vertex_groups}
	owner = {}
	for vx in mesh.data.vertices:
		if vx.groups:
			g = max(vx.groups, key=lambda e: e.weight)
			owner[vx.index] = names[g.group]
	skin_name, eye_rgb = VERSIONS[v % len(VERSIONS)]
	shell = ck.skin(skin_name, tile=0.35, rough=0.6)
	eye = ck.eye_mat(eye_rgb)
	small = min(range(len(mesh.data.materials)), key=lambda i: sum(1 for p in mesh.data.polygons if p.material_index == i))
	mesh.data.materials[small] = eye  # the pack's second colour is the eyes
	for i in range(len(mesh.data.materials)):
		if i != small:
			mesh.data.materials[i] = shell
	for side, s in (("L", "l"), ("R", "r")):
		for i, leg in enumerate(LEGS):
			bones = {f"{leg}.{side}", f"{leg}2.{side}", f"{leg}3.{side}"}
			bpy.ops.object.select_all(action="DESELECT")
			mesh.select_set(True)
			bpy.context.view_layer.objects.active = mesh
			bpy.ops.object.mode_set(mode="EDIT")
			bpy.ops.mesh.select_all(action="DESELECT")
			bpy.ops.object.mode_set(mode="OBJECT")
			for vx in mesh.data.vertices:
				vx.select = owner.get(vx.index, "") in bones
			bpy.ops.object.mode_set(mode="EDIT")
			bpy.ops.mesh.separate(type="SELECTED")
			bpy.ops.object.mode_set(mode="OBJECT")
			new = [o for o in bpy.context.selected_objects if o != mesh]
			if not new:
				print("NO LEG", leg, side)
				continue
			# Blender's left is +X when facing -Y; turned around, the pack's L leg ends up on our right.
			name = f"leg_{('r' if s == 'l' else 'l') if turn else s}{i}"
			new[0]["part"] = name
			ck._parts[name] = hips[f"{leg}.{side}"]
	for o in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
		o.vertex_groups.clear()
		if "part" not in o:
			o["part"] = "body"
	# Size and facing: scale everything (and the hinges) about the origin.
	allv = [o.matrix_world @ vx.co for o in bpy.context.scene.objects if o.type == "MESH" for vx in o.data.vertices]
	span = max(max(p.x for p in allv) - min(p.x for p in allv), max(p.y for p in allv) - min(p.y for p in allv))
	k = SIZE / span
	for o in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
		o.scale = (k, k, k)
		o.location = o.location * k
		if turn:
			o.rotation_euler.z += 3.14159265
			o.location = Vector((-o.location.x, -o.location.y, o.location.z))
	for name in list(ck._parts):
		h = ck._parts[name] * k
		ck._parts[name] = Vector((-h.x, -h.y, h.z)) if turn else h
	for o in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
		mat = o.data.materials[0] if o.data.materials else None
		if mat and mat.get("tile"):
			ck.kit._uv_box(o, mat["tile"])
	ck.save(out, preview)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	v = next((int(a.split("=")[1]) for a in args if a.startswith("v=")), 0)
	files = [a for a in args if not a.startswith("v=")]
	out = files[0] if files else str(Path(__file__).resolve().parents[3] / "assets" / "models" / "monsters" / MODELS[v % len(MODELS)] + ".glb")
	build(out, files[1] if len(files) > 1 else None, v)
