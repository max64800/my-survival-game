# Treasure and table things for the ruins (owner, Nov 19, 2026: batch 4 in docs/research/asset-picks-placement.md):
# books, scrolls, maps, coins, keys, mugs, the chalice, plate and cutlery, candles, a pouch and the loot chest that won
# the cup (Props MegaKit "Chest Wood"). Free CC0 models (Quaternius Fantasy Props MegaKit, KayKit RPG Tools) rebuilt
# by script like the furniture (furniture.py does the work): wood, iron, copper, silver, leather and cloth repainted
# with our own hand-painted pictures.
#
#   blender --background --factory-startup --python builds/treasure.py -- [only=tr_books_stack_1,...]
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy  # noqa: E402
import furniture as fu  # noqa: E402

# name: (pack file, scale). Every name spelled out: the model-rules test finds a model's build script by its name.
TREASURE = {
	"tr_book_red": ("Book_5", 1.0),
	"tr_book_clasped": ("Book_7", 1.0),
	"tr_books_stack_1": ("Book_Stack_1", 1.0),
	"tr_books_stack_2": ("Book_Stack_2", 1.0),
	"tr_books_row_1": ("BookGroup_Small_1", 1.0),
	"tr_books_row_2": ("BookGroup_Small_2", 1.0),
	"tr_books_row_3": ("BookGroup_Small_3", 1.0),
	"tr_books_shelf_1": ("BookGroup_Medium_1", 1.0),
	"tr_books_shelf_2": ("BookGroup_Medium_2", 1.0),
	"tr_books_shelf_3": ("BookGroup_Medium_3", 1.0),
	"tr_scroll_1": ("Scroll_1", 1.0),
	"tr_scroll_2": ("Scroll_2", 1.0),
	"tr_map": ("kaykit_rpg_tools_bits/map", 0.3),
	"tr_map_blank": ("kaykit_rpg_tools_bits/map_empty", 0.3),
	"tr_coins": ("Coin_Pile", 1.3),
	"tr_coins_wide": ("Coin_Pile_2", 1.3),
	"tr_key_copper": ("Key_Gold", 1.5),
	"tr_key_iron": ("Key_Metal", 1.5),
	"tr_mug": ("Mug", 1.0),
	"tr_chalice": ("Chalice", 1.0),
	"tr_plate": ("Table_Plate", 1.0),
	"tr_fork": ("Table_Fork", 1.0),
	"tr_knife": ("Table_Knife", 1.0),
	"tr_spoon": ("Table_Spoon", 1.0),
	"tr_candle_short": ("Candle_1", 1.0),
	"tr_candle_tall": ("Candle_2", 1.0),
	"tr_candlestick": ("CandleStick", 1.0),
	"tr_pouch": ("Pouch_Large", 1.0),
	"chest_loot": ("Chest_Wood", 0.6),  # a ruin's loot chest (the cup winner); saved with the station chests
}
LEATHER = {"MI_Trim_Props_Vertex": ("leather", "b")}
PAINT = {
	"tr_book_red": {"MI_Trim_Props_Vertex": ("leather", "a")},
	"tr_book_clasped": {"MI_Trim_Props_Vertex": ("leather", "dark")},
	"tr_books_stack_1": LEATHER, "tr_books_stack_2": {"MI_Trim_Props_Vertex": ("leather", "c")},
	"tr_books_row_1": LEATHER, "tr_books_row_2": {"MI_Trim_Props_Vertex": ("leather", "a")},
	"tr_books_row_3": {"MI_Trim_Props_Vertex": ("leather", "c")},
	"tr_books_shelf_1": LEATHER, "tr_books_shelf_2": {"MI_Trim_Props_Vertex": ("leather", "a")},
	"tr_books_shelf_3": {"MI_Trim_Props_Vertex": ("leather", "dark")},
	"tr_scroll_1": {"MI_Page_Empty": ("sack", "a"), "MI_Trim_Props_Vertex": ("wood", "c")},
	"tr_scroll_2": {"MI_Page_Empty": ("sack", "a"), "MI_Trim_Props_Vertex": ("wood", "c")},
	"tr_coins": {"MI_Trim_Metal_Vertex": ("copper", "a")}, "tr_coins_wide": {"MI_Trim_Metal_Vertex": ("copper", "b")},
	"tr_key_copper": {"MI_Trim_Metal_Vertex": ("copper", "a")}, "tr_key_iron": {"MI_Trim_Metal": ("silver", "a")},
	"tr_chalice": {"MI_Trim_Metal": ("silver", "a")}, "tr_candlestick": {"MI_Trim_Metal": ("copper", "b")},
	"tr_pouch": {"MI_Trim_Props_Vertex": ("leather", "b")},
}

def _chest_import(path):
	"""The pack chest has a hinge skeleton and a hidden helper ball: keep only the box and its lid, at rest, closed."""
	for o in list(bpy.data.objects):
		bpy.data.objects.remove(o, do_unlink=True)
	bpy.ops.import_scene.gltf(filepath=str(path))
	for o in list(bpy.data.objects):
		if o.type != "MESH" or o.name.lower().startswith("icosphere"):
			if o.type == "MESH":
				bpy.data.objects.remove(o, do_unlink=True)
	meshes = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in meshes:
		for m in list(o.modifiers):
			o.modifiers.remove(m)
		mw = o.matrix_world.copy()
		o.parent = None
		o.matrix_world = mw
	for o in list(bpy.data.objects):
		if o.type != "MESH":
			bpy.data.objects.remove(o, do_unlink=True)
	bpy.ops.object.select_all(action="DESELECT")
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	return obj


def _chest_save(out, preview):
	"""Like kit.save, but the lid (the corners on the pack's hinge bone "Chest_Top") becomes its own part named "lid"
	with its origin on the back top edge, so the game swings it open (owner F345, ChestOpen)."""
	import kit
	from mathutils import Vector
	meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	bpy.ops.object.select_all(action="DESELECT")
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	obj.name = "model"
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	vs = [v.co for v in obj.data.vertices]
	shift = Vector(((min(v.x for v in vs) + max(v.x for v in vs)) / 2, (min(v.y for v in vs) + max(v.y for v in vs)) / 2, min(v.z for v in vs)))
	for v in obj.data.vertices:
		v.co -= shift
	g = obj.vertex_groups["Chest_Top"].index
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="DESELECT")
	bpy.ops.object.mode_set(mode="OBJECT")
	for v in obj.data.vertices:
		v.select = any(e.group == g and e.weight > 0.5 for e in v.groups)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.separate(type="SELECTED")
	bpy.ops.object.mode_set(mode="OBJECT")
	lid = [o for o in bpy.context.scene.objects if o.type == "MESH" and o != obj][0]
	lid.name = "lid"
	for o in (obj, lid):
		o.vertex_groups.clear()
	lv = [v.co for v in lid.data.vertices]
	hinge = Vector((0.0, max(v.y for v in lv), 0.4286 * TREASURE["chest_loot"][1] - shift.z))  # the pack's hinge bone height
	for v in lid.data.vertices:
		v.co -= hinge
	lid.location = hinge
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	lid.select_set(True)
	for img in bpy.data.images:
		if img.size[0] > 1024:
			img.scale(1024, 1024)
	bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="JPEG", export_image_quality=85)
	import glb_jpeg_fix
	glb_jpeg_fix.fix(out)
	print(f"KIT_DONE {out} lid hinge at {hinge.y:.2f}, {hinge.z:.2f}")
	kit._preview(obj, preview)


if __name__ == "__main__":
	fu.CUSTOM_IMPORT["chest_loot"] = _chest_import
	fu.CUSTOM_SAVE["chest_loot"] = _chest_save
	fu.FURNITURE.update(TREASURE)
	fu.REPAINT_ONE.update(PAINT)
	fu.JOURNEY = fu.ROOT / "journey" / "treasure"
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	only = next((a.split("=", 1)[1].split(",") for a in args if a.startswith("only=")), list(TREASURE))
	out = fu.ROOT / "assets" / "models" / "treasure"
	out.mkdir(parents=True, exist_ok=True)
	for n in only:
		fu.build(n, str(fu.ROOT / "assets" / "models" / "stations") if n == "chest_loot" else str(out))
