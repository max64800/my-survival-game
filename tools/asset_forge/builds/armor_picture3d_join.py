# Picture-to-3D armour TEST: joins the game copies made by armor_picture3d.py (game=1) into one file on one skeleton,
# the file DwarfRig wears as the copper TEST look (ARMOR_PIC3D).
#   blender --background --factory-startup --python tools/asset_forge/builds/armor_picture3d_join.py -- <out.glb> <in.glb>...
import sys
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "asset_forge"))
ARGS = sys.argv[sys.argv.index("--") + 1:]
OUT, INS = ARGS[0], ARGS[1:]

bpy.ops.wm.read_factory_settings(use_empty=True)
ARM = None
for f in INS:
	before = set(bpy.context.scene.objects)
	bpy.ops.import_scene.gltf(filepath=f)
	new = set(bpy.context.scene.objects) - before
	arm = next(o for o in new if o.type == "ARMATURE")
	if ARM is None:
		ARM = arm
		continue
	for o in new:
		if o.type == "MESH":
			mw = o.matrix_world.copy()
			o.parent = ARM
			o.matrix_world = mw
			for m in o.modifiers:
				if m.type == "ARMATURE":
					m.object = ARM
	bpy.data.objects.remove(arm, do_unlink=True)
for o in list(bpy.context.scene.objects):  # (empties the importer adds; the skeleton's stray Icosphere bone shape)
	if o.type not in ("ARMATURE", "MESH") or (o.type == "MESH" and not o.name.startswith("armor_")):
		bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_image_format="JPEG", export_image_quality=88)
import glb_jpeg_fix  # noqa: E402  (Godot shows Blender's JPEG pictures white without it: F164)
glb_jpeg_fix.fix(OUT)
print("PIC3D JOINED", OUT, sorted(o.name for o in bpy.context.scene.objects if o.type == "MESH"), flush=True)
