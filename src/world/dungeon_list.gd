class_name DungeonList
## The 12 dungeons of Zone 1 (owner, Nov 20, F237; docs/design/zone1-dungeons/). Only the list: placing and building
## them lives with Mossgate Hold's code (PC). Each size has its own material. Each dungeon always teaches the same
## bronze recipe, in the owner's order (Nov 24, F844: docs/decisions/2026-11-24-zone1-metal-and-loot.md, step 5).
## Copper recipes come from the ruins instead (Recipes.RUIN_COPPER).

const LIST := [
	{id = "mossgate_hold", name = "Mossgate Hold", size = "small", recipe = "helm_bronze"},
	{id = "lampwick_drift", name = "Lampwick Drift", size = "small", recipe = "boots_bronze"},
	{id = "old_pells_diggings", name = "Old Pell's Diggings", size = "small", recipe = "greaves_bronze"},
	{id = "mossprop_workings", name = "Mossprop Workings", size = "small", recipe = "crossbow_bronze"},
	{id = "tomb_of_hald_ironbrow", name = "Tomb of Hald Ironbrow", size = "medium", recipe = "mail_bronze"},
	{id = "the_quiet_barrows", name = "The Quiet Barrows", size = "medium", recipe = "spear_bronze"},
	{id = "brassgate_vault", name = "Brassgate Vault", size = "medium", recipe = "axe_bronze"},
	{id = "hall_of_the_shieldbearers", name = "Hall of the Shieldbearers", size = "medium", recipe = "shield_bronze"},
	{id = "vigil_of_orrin_stonejaw", name = "Vigil of Orrin Stonejaw", size = "medium", recipe = "sword_bronze"},
	{id = "emberdeep_forge", name = "Emberdeep Forge", size = "big", recipe = "mace_bronze"},
	{id = "the_hammerfall_works", name = "The Hammerfall Works", size = "big", recipe = "mace_2h_bronze"},
	{id = "cinderhold_foundry", name = "Cinderhold Foundry", size = "big", recipe = "axe_2h_bronze"},
]

## Per size: building material and how far from the start (m).
const SIZES := {
	small = {material = "plank_root", ring = [40.0, 100.0]},
	medium = {material = "cut_stone", ring = [100.0, 170.0]},
	big = {material = "clay_brick", ring = [170.0, INF]},
}


static func get_dungeon(id: String) -> Dictionary:
	for d in LIST:
		if d.id == id:
			return d
	return {}


## The recipe this dungeon's stand teaches, the same in every world ("" for an unknown id).
static func recipe_of(id: String) -> String:
	return String(get_dungeon(id).get("recipe", ""))
