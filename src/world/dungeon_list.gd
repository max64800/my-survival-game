class_name DungeonList
## The 12 dungeons of Zone 1 (owner, Nov 20, F237; docs/design/zone1-dungeons/). Only the list: placing and building
## them lives with Mossgate Hold's code (PC). Each size has its own material. Each dungeon always teaches the same
## recipe, in the owner's order (Nov 24, F844: docs/decisions/2026-11-24-zone1-metal-and-loot.md). Copper for now;
## they switch to bronze once bronze is in (build order step 5).

const LIST := [
	{id = "mossgate_hold", name = "Mossgate Hold", size = "small", recipe = "helm_copper"},
	{id = "lampwick_drift", name = "Lampwick Drift", size = "small", recipe = "boots_copper"},
	{id = "old_pells_diggings", name = "Old Pell's Diggings", size = "small", recipe = "greaves_copper"},
	{id = "mossprop_workings", name = "Mossprop Workings", size = "small", recipe = "crossbow_copper"},
	{id = "tomb_of_hald_ironbrow", name = "Tomb of Hald Ironbrow", size = "medium", recipe = "mail_copper"},
	{id = "the_quiet_barrows", name = "The Quiet Barrows", size = "medium", recipe = "spear_copper"},
	{id = "brassgate_vault", name = "Brassgate Vault", size = "medium", recipe = "axe_copper"},
	{id = "hall_of_the_shieldbearers", name = "Hall of the Shieldbearers", size = "medium", recipe = "shield_copper"},
	{id = "vigil_of_orrin_stonejaw", name = "Vigil of Orrin Stonejaw", size = "medium", recipe = "sword_copper"},
	{id = "emberdeep_forge", name = "Emberdeep Forge", size = "big", recipe = "mace_copper"},
	{id = "the_hammerfall_works", name = "The Hammerfall Works", size = "big", recipe = "mace_2h_copper"},
	{id = "cinderhold_foundry", name = "Cinderhold Foundry", size = "big", recipe = "axe_2h_copper"},
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
