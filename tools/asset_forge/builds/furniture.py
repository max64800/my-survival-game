# Furniture for the Decor tab (owner, Nov 19, 2026: "some do something": beds, seats, shelves, lights; decisions in
# docs/research/asset-picks-placement.md, batch 3). Free CC0 models from Quaternius' Fantasy Props MegaKit
# (tools/asset_forge/packs/quaternius_fantasy_props_megakit/), rebuilt by script (MODEL-RULES rule 1 as bent for
# free packs): the pack shape kept, its wood and metal repainted with our own hand-painted wood and iron pictures,
# cloth, wax and pottery keep the pack's painted look. One model per piece, origin bottom-centre, front +Z.
#
#   blender --background --factory-startup --python builds/furniture.py -- <out_dir> [only=furn_bed_1,...]
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import glow_trees as gt  # noqa: E402  (pack import helper)
import kit  # noqa: E402

P = gt.PACKS / "quaternius_fantasy_props_megakit"
ROOT = Path(__file__).resolve().parents[3]
JOURNEY = ROOT / "journey" / "furniture"

# name: (pack file, scale). Every name spelled out: the model-rules test finds a model's build script by its name.
FURNITURE = {
	"furn_bed_1": ("Bed_Twin1", 1.0),
	"furn_bed_2": ("Bed_Twin2", 1.0),
	"furn_bench_long": ("Bench", 0.8),
	"furn_table_long": ("Table_Large", 0.85),
	"furn_chair": ("Chair_1", 1.0),
	"furn_stool": ("Stool", 1.0),
	"furn_cabinet": ("Cabinet", 1.0),
	"furn_bookcase": ("Bookcase_2", 0.75),
	"furn_nightstand": ("Nightstand_Shelf", 0.85),
	"furn_shelf_arch": ("Shelf_Arch", 1.0),
	"furn_shelf_wall": ("Shelf_Simple", 1.0),
	"furn_shelf_bottles": ("Shelf_Small_Bottles", 1.0),
	"furn_weapon_stand": ("WeaponStand", 1.0),
	"furn_vase_wide": ("Vase_2", 1.0),
	"furn_vase_tall": ("Vase_4", 1.2),
	"furn_book_stand": ("BookStand", 1.0),
	"furn_bucket_wood": ("Bucket_Wooden_1", 1.0),
	"furn_bucket_metal": ("Bucket_Metal", 1.0),
	"furn_barrel_rack": ("Barrel_Holder", 1.0),
	"furn_crate_iron": ("Crate_Metal", 1.0),
	"furn_work_table": ("Workbench", 0.9),
	"furn_drawers": ("Workbench_Drawers", 1.6),
	"furn_candles": ("CandleStick_Triple", 1.0),
	"furn_candle_stand": ("CandleStick_Stand", 1.0),
	"furn_chandelier": ("Chandelier", 0.9),
	"furn_wall_torch_iron": ("Torch_Metal", 1.2),
	"furn_banner_tall_1": ("Banner_1", 0.75),
	"furn_banner_tall_2": ("Banner_2", 0.8),
	"furn_dummy": ("Dummy", 0.9),
	"furn_cauldron": ("Cauldron", 1.0),
	"furn_whetstone": ("Whetstone", 0.9),
	"furn_anvil_log": ("Anvil_Log", 0.9),
}

# The pack's painted strips ("trim sheets") we swap for our own pictures; the rest keep the pack's look.
REPAINT = {"MI_Trim_Furniture": ("wood", "b"), "MI_Trim_Metal": ("iron", "a"), "MI_Trim_Metal_Vertex": ("iron", "b"),
	"MI_Trim_Props_Vertex": ("clay", "b")}  # pots and bottles: their pack paint is in corner colours glTF loses
CUSTOM_SAVE = {}  # name -> function(out, preview) saving it instead of kit.save (a chest with a hinged lid)
CUSTOM_IMPORT = {}  # name -> function(path) returning the joined object (models that need special care)
REPAINT_ONE = {"furn_dummy": {"MI_Trim_Cloth": ("sack", "b")}}  # a straw-sack training dummy


def build(name, out_dir):
	src, scale = FURNITURE[name]
	path = gt.PACKS / f"{src}.gltf" if "/" in src else P / f"{src}.gltf"  # "pack/file" = another pack
	obj = CUSTOM_IMPORT[name](path) if name in CUSTOM_IMPORT else gt.import_tree(path)
	obj.scale = (scale, scale, scale)
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.separate(type="MATERIAL")
	bpy.ops.object.mode_set(mode="OBJECT")
	for o in [o for o in bpy.data.objects if o.type == "MESH"]:
		m = o.material_slots[0].material if o.material_slots else None
		key = m.name.split(".")[0] if m else ""
		pick = REPAINT_ONE.get(name, {}).get(key) or REPAINT.get(key)
		if pick:
			mat = kit.tex_mat(*pick)
			o.data.materials.clear()
			o.data.materials.append(mat)
			kit._uv_box(o, mat["tile"])
	JOURNEY.mkdir(parents=True, exist_ok=True)
	if name in CUSTOM_SAVE:
		CUSTOM_SAVE[name](str(Path(out_dir) / f"{name}.glb"), str(JOURNEY / f"{name}.png"))
	else:
		kit.save(str(Path(out_dir) / f"{name}.glb"), preview=str(JOURNEY / f"{name}.png"), tex_size=1024)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	out_dir = args[0] if args and not args[0].startswith("only=") else str(ROOT / "assets" / "models" / "decor")
	only = next((a.split("=", 1)[1].split(",") for a in args if a.startswith("only=")), list(FURNITURE))
	for n in only:
		build(n, out_dir)
