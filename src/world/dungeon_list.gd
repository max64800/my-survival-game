class_name DungeonList
## The 12 dungeons of Zone 1 (owner, Nov 20, F237; docs/design/zone1-dungeons/). Only the list: placing and building
## them lives with Mossgate Hold's code (PC). Each size has its own material and its own group of copper recipes;
## which dungeon of a group teaches which recipe is shuffled per world, so every recipe is taught exactly once.

const LIST := [
	{id = "mossgate_hold", name = "Mossgate Hold", size = "small"},
	{id = "lampwick_drift", name = "Lampwick Drift", size = "small"},
	{id = "old_pells_diggings", name = "Old Pell's Diggings", size = "small"},
	{id = "mossprop_workings", name = "Mossprop Workings", size = "small"},
	{id = "tomb_of_hald_ironbrow", name = "Tomb of Hald Ironbrow", size = "medium"},
	{id = "the_quiet_barrows", name = "The Quiet Barrows", size = "medium"},
	{id = "brassgate_vault", name = "Brassgate Vault", size = "medium"},
	{id = "hall_of_the_shieldbearers", name = "Hall of the Shieldbearers", size = "medium"},
	{id = "vigil_of_orrin_stonejaw", name = "Vigil of Orrin Stonejaw", size = "medium"},
	{id = "emberdeep_forge", name = "Emberdeep Forge", size = "big"},
	{id = "the_hammerfall_works", name = "The Hammerfall Works", size = "big"},
	{id = "cinderhold_foundry", name = "Cinderhold Foundry", size = "big"},
]

## Per size: building material, how far from the start (m), and the copper recipes its dungeons teach.
const SIZES := {
	small = {material = "plank_root", ring = [40.0, 100.0], recipes = ["axe_copper", "crossbow_copper", "spear_copper", "boots_copper"]},
	medium = {material = "cut_stone", ring = [100.0, 170.0], recipes = ["helm_copper", "mail_copper", "greaves_copper", "shield_copper", "sword_copper"]},
	big = {material = "clay_brick", ring = [170.0, INF], recipes = ["mace_copper", "axe_2h_copper", "mace_2h_copper"]},
}


static func get_dungeon(id: String) -> Dictionary:
	for d in LIST:
		if d.id == id:
			return d
	return {}


## The copper recipe this dungeon teaches in this world ("" for an unknown id).
static func recipe_of(world_seed: int, id: String) -> String:
	var d := get_dungeon(id)
	if d.is_empty():
		return ""
	var group := LIST.filter(func(x): return x.size == d.size)
	return DungeonLoot.recipes_for(world_seed, SIZES[d.size].recipes)[group.find(d)]
