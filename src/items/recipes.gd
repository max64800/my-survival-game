class_name Recipes
## Every recipe (progression doc sections 1.6, 3.2, 4, 5.4, 6, 10.2).
## Each recipe: station, inputs {item: count}, output item + count, seconds (0 = instant),
## unlock = the items that make it appear when first picked up ([] = known from the start),
##          or "rune"/"ruin" (taught by a rune or a ruin scroll).
## "water" in the doc means 1 water_bucket here (a clean waterskin sip comes later).

const HAND := "hand"

const LIST := {
	# --- by hand (bag menu)
	# Your first tools, made from what's lying in the starting room (feedback F11).
	"pickaxe_stone": {station = HAND, inputs = {stone = 3, rootwood = 2}, output = "pickaxe_stone", count = 1, unlock = []},
	"lantern": {station = HAND, inputs = {stone = 2, rootwood = 1, crystal_blue = 1}, output = "lantern", count = 1, unlock = []},
	"rope":{station = HAND, inputs = {fiber = 3}, output = "rope", count = 1, unlock = []},
	"campfire": {station = HAND, inputs = {stone = 5, rootwood = 3}, output = "campfire", count = 1, unlock = []},
	"workbench": {station = HAND, inputs = {rootwood = 10, stone = 6}, output = "workbench", count = 1, unlock = []},
	"waterskin": {station = HAND, inputs = {critter_hide = 2, rope = 1}, output = "waterskin_empty", count = 1, unlock = ["critter_hide"]},
	"drink_bellcap_juice": {station = HAND, inputs = {bellcap = 2}, output = "drink_bellcap_juice", count = 1, unlock = ["bellcap"]},
	# --- workbench
	"plank_root": {station = "workbench", inputs = {rootwood = 1}, output = "plank_root", count = 2, unlock = []},
	"plank_mushroom": {station = "workbench", inputs = {mushroom_wood = 1}, output = "plank_mushroom", count = 2, unlock = ["mushroom_wood"]},
	"axe_stone": {station = "workbench", inputs = {stone = 3, rootwood = 2, rope = 2}, output = "axe_stone", count = 1, unlock = []},
	"build_hammer": {station = "workbench", inputs = {stone = 3, rootwood = 2}, output = "build_hammer", count = 1, unlock = []},
	"bed": {station = "workbench", inputs = {plank_root = 6, moss = 4, leather = 2}, output = "bed", count = 1, unlock = []},
	"tanning_rack": {station = "workbench", inputs = {plank_root = 6, rope = 4}, output = "tanning_rack", count = 1, unlock = ["critter_hide"]},
	"smelter": {station = "workbench", inputs = {stone = 20, clay = 15}, output = "smelter", count = 1, unlock = ["copper_ore"]},
	"farm_plot": {station = "workbench", inputs = {dirt = 10, moss = 5, plank_root = 4}, output = "farm_plot", count = 1, unlock = ["glowcap", "hollowcap", "bellcap", "root_tuber"]},
	"chest_small": {station = "workbench", inputs = {plank_root = 8, rope = 2}, output = "chest_small", count = 1, unlock = []},
	"chest_stone": {station = "workbench", inputs = {cut_stone = 10, copper_ingot = 2}, output = "chest_stone", count = 1, unlock = ["cut_stone"]},
	"drip_bucket": {station = "workbench", inputs = {plank_root = 4, rope = 1}, output = "drip_bucket", count = 1, unlock = []},
	"rune_slab": {station = "workbench", inputs = {stone = 15, cut_stone = 5}, output = "rune_slab", count = 1, unlock = ["rune"]},
	"gem_bench": {station = "workbench", inputs = {plank_root = 8, copper_ingot = 4, crystal_blue = 2}, output = "gem_bench", count = 1,
		unlock = ["gem_ember", "gem_rime", "gem_blight", "gem_leech", "gem_jolt", "gem_swift", "gem_bulwark", "gem_keen", "gem_burrow"]},
	"anvil": {station = "workbench", inputs = {stone = 10, copper_ingot = 6}, output = "anvil", count = 1, unlock = ["copper_ingot"]},
	"cooking_pot": {station = "workbench", inputs = {copper_ingot = 4, stone = 4}, output = "cooking_pot", count = 1, unlock = ["copper_ingot"]},
	"masonry_table": {station = "workbench", inputs = {stone = 10, plank_root = 6, copper_ingot = 2}, output = "masonry_table", count = 1, unlock = ["copper_ingot"]},
	# Clothes and a backpack (feedback F23): leather from the tanning rack.
	"cap_leather": {station = "workbench", inputs = {leather = 2, fiber = 2}, output = "cap_leather", count = 1, unlock = ["leather"]},
	"tunic_leather": {station = "workbench", inputs = {leather = 4, rope = 1}, output = "tunic_leather", count = 1, unlock = ["leather"]},
	"trousers_leather": {station = "workbench", inputs = {leather = 3, rope = 1}, output = "trousers_leather", count = 1, unlock = ["leather"]},
	"boots_leather": {station = "workbench", inputs = {leather = 2, fiber = 2}, output = "boots_leather", count = 1, unlock = ["leather"]},
	"satchel": {station = "workbench", inputs = {leather = 4, rope = 2}, output = "satchel", count = 1, unlock = ["leather"]},
	# --- tanning rack (60 s each)
	"leather": {station = "tanning_rack", inputs = {critter_hide = 1}, output = "leather", count = 1, seconds = 60, unlock = ["critter_hide"]},
	# --- smelter (needs wood fuel; times from doc 4.2)
	"copper_ingot": {station = "smelter", inputs = {copper_ore = 2}, output = "copper_ingot", count = 1, seconds = 20, fuel = 1, unlock = ["copper_ore"]},
	"copper_from_scrap": {station = "smelter", inputs = {rusty_scrap = 3}, output = "copper_ingot", count = 1, seconds = 20, fuel = 1, unlock = ["rusty_scrap"]},
	"silver_ingot": {station = "smelter", inputs = {silver_ore = 2}, output = "silver_ingot", count = 1, seconds = 30, fuel = 1, unlock = ["silver_ore"]},
	"clay_brick": {station = "smelter", inputs = {clay = 2}, output = "clay_brick", count = 2, seconds = 10, fuel = 1, unlock = ["clay"]},
	"lantern_lens": {station = "smelter", inputs = {crystal_blue = 3, clay = 1}, output = "lantern_lens", count = 1, seconds = 30, fuel = 1, unlock = ["crystal_blue"]},
	# --- anvil
	"helm_copper": {station = "anvil", inputs = {copper_ingot = 4, leather = 1}, output = "helm_copper", count = 1, unlock = ["copper_ingot"]},
	"mail_copper": {station = "anvil", inputs = {copper_ingot = 8, leather = 2}, output = "mail_copper", count = 1, unlock = ["copper_ingot"]},
	"greaves_copper": {station = "anvil", inputs = {copper_ingot = 6, leather = 1}, output = "greaves_copper", count = 1, unlock = ["copper_ingot"]},
	"boots_copper": {station = "anvil", inputs = {copper_ingot = 3, leather = 1}, output = "boots_copper", count = 1, unlock = ["copper_ingot"]},
	"axe_copper": {station = "anvil", inputs = {copper_ingot = 6, plank_root = 3, leather = 1}, output = "axe_copper", count = 1, unlock = ["copper_ingot"]},
	"pickaxe_copper": {station = "anvil", inputs = {copper_ingot = 8, plank_root = 4, leather = 2, keeper_heartstone = 1}, output = "pickaxe_copper", count = 1, unlock = ["keeper_heartstone"]},
	"axe_silver": {station = "anvil", inputs = {silver_ingot = 6, plank_mushroom = 3, chitin_plate = 2}, output = "axe_silver", count = 1, unlock = ["silver_ingot"]},
	"pickaxe_silver": {station = "anvil", inputs = {silver_ingot = 8, plank_mushroom = 4, chitin_plate = 2, bloomheart_core = 1}, output = "pickaxe_silver", count = 1, unlock = ["bloomheart_core"]},
	# --- weapons. STARTING VALUES (the design docs had no weapon recipes yet): tune in play-testing.
	"sword_stone": {station = "workbench", inputs = {stone = 5, rootwood = 2, rope = 1}, output = "sword_stone", count = 1, unlock = []},
	"mace_stone": {station = "workbench", inputs = {stone = 6, rootwood = 2, rope = 1}, output = "mace_stone", count = 1, unlock = []},
	"spear_stone": {station = "workbench", inputs = {stone = 3, rootwood = 3, rope = 2}, output = "spear_stone", count = 1, unlock = []},
	"shield_stone": {station = "workbench", inputs = {plank_root = 6, rope = 2}, output = "shield_stone", count = 1, unlock = []},
	"axe_2h_stone": {station = "workbench", inputs = {stone = 8, rootwood = 3, rope = 2}, output = "axe_2h_stone", count = 1, unlock = []},
	"mace_2h_stone": {station = "workbench", inputs = {stone = 10, rootwood = 3, rope = 2}, output = "mace_2h_stone", count = 1, unlock = []},
	"sword_copper": {station = "anvil", inputs = {copper_ingot = 5, plank_root = 2, leather = 1}, output = "sword_copper", count = 1, unlock = ["copper_ingot"]},
	"sword_silver": {station = "anvil", inputs = {silver_ingot = 5, plank_mushroom = 2, chitin_plate = 1}, output = "sword_silver", count = 1, unlock = ["silver_ingot"]},
	"mace_copper": {station = "anvil", inputs = {copper_ingot = 6, plank_root = 2, leather = 1}, output = "mace_copper", count = 1, unlock = ["copper_ingot"]},
	"mace_silver": {station = "anvil", inputs = {silver_ingot = 6, plank_mushroom = 2, chitin_plate = 1}, output = "mace_silver", count = 1, unlock = ["silver_ingot"]},
	"spear_copper": {station = "anvil", inputs = {copper_ingot = 4, plank_root = 3, leather = 1}, output = "spear_copper", count = 1, unlock = ["copper_ingot"]},
	"spear_silver": {station = "anvil", inputs = {silver_ingot = 4, plank_mushroom = 3, chitin_plate = 1}, output = "spear_silver", count = 1, unlock = ["silver_ingot"]},
	"shield_copper": {station = "anvil", inputs = {copper_ingot = 5, plank_root = 4, leather = 2}, output = "shield_copper", count = 1, unlock = ["copper_ingot"]},
	"shield_silver": {station = "anvil", inputs = {silver_ingot = 5, plank_mushroom = 4, chitin_plate = 2}, output = "shield_silver", count = 1, unlock = ["silver_ingot"]},
	"axe_2h_copper": {station = "anvil", inputs = {copper_ingot = 8, plank_root = 3, leather = 2}, output = "axe_2h_copper", count = 1, unlock = ["copper_ingot"]},
	"axe_2h_silver": {station = "anvil", inputs = {silver_ingot = 8, plank_mushroom = 3, chitin_plate = 2}, output = "axe_2h_silver", count = 1, unlock = ["silver_ingot"]},
	"mace_2h_copper": {station = "anvil", inputs = {copper_ingot = 9, plank_root = 3, leather = 2}, output = "mace_2h_copper", count = 1, unlock = ["copper_ingot"]},
	"mace_2h_silver": {station = "anvil", inputs = {silver_ingot = 9, plank_mushroom = 3, chitin_plate = 2}, output = "mace_2h_silver", count = 1, unlock = ["silver_ingot"]},
	# Crossbows and bolts (combat doc 3.6; "starting idea" recipes, tune in play-testing).
	"crossbow_stone": {station = "workbench", inputs = {plank_root = 4, rope = 3, stone = 4}, output = "crossbow_stone", count = 1, unlock = ["rope"]},
	"crossbow_copper": {station = "anvil", inputs = {copper_ingot = 4, plank_root = 3, rope = 2}, output = "crossbow_copper", count = 1, unlock = ["copper_ingot"]},
	"crossbow_silver": {station = "anvil", inputs = {silver_ingot = 4, plank_mushroom = 3, sivix_silk = 1}, output = "crossbow_silver", count = 1, unlock = ["silver_ingot"]},
	"bolt_stone": {station = "workbench", inputs = {plank_root = 1, stone = 2}, output = "bolt_stone", count = 10, unlock = ["rope"]},
	"bolt_metal": {station = "anvil", inputs = {plank_root = 1, copper_ingot = 1}, output = "bolt_metal", count = 10, unlock = ["copper_ingot"]},
	"bolt_metal_needle": {station = "workbench", inputs = {plank_mushroom = 1, needle = 3}, output = "bolt_metal", count = 10, unlock = ["needle"]},
	"bolt_thumper": {station = "workbench", inputs = {plank_root = 1, stone = 2, rope = 1}, output = "bolt_thumper", count = 10, unlock = ["rope"]},
	"bolt_ember": {station = "workbench", inputs = {bolt_metal = 10, crystal_red = 1}, output = "bolt_ember", count = 10, unlock = ["crystal_red"]},
	"bolt_rime": {station = "workbench", inputs = {bolt_metal = 10, crystal_blue = 2}, output = "bolt_rime", count = 10, unlock = ["bolt_metal"]},
	"bolt_blight": {station = "workbench", inputs = {bolt_metal = 10, venom_sac = 1}, output = "bolt_blight", count = 10, unlock = ["venom_sac"]},
	"bolt_glow": {station = "workbench", inputs = {plank_root = 1, crystal_blue = 1}, output = "bolt_glow", count = 10, unlock = ["rope"]},
	# Taught by runes (progression doc 8). unlock = "rune": you learn it by carving the rune.
	"crystal_sconce": {station = "workbench", inputs = {stone = 4, crystal_blue = 2}, output = "crystal_sconce", count = 1, unlock = "rune"},
	"rope_ladder": {station = "workbench", inputs = {rope = 3, plank_root = 2}, output = "rope_ladder", count = 4, unlock = "rune"},
	"blasting_pod": {station = "workbench", inputs = {spitter_gill = 1, crystal_red = 1, clay = 2}, output = "blasting_pod", count = 2, unlock = "rune"},
	"glow_marker": {station = "workbench", inputs = {plank_mushroom = 2, crystal_amber = 1}, output = "glow_marker", count = 3, unlock = "rune"},
	"prospectors_lens": {station = "anvil", inputs = {silver_ingot = 1, crystal_white = 1, scythe_blade = 1}, output = "prospectors_lens", count = 1, unlock = "rune"},
	"training_dummy": {station = "workbench", inputs = {plank_root = 4, fiber = 6, critter_hide = 1}, output = "training_dummy", count = 1, unlock = "rune"},
	"whetstone": {station = "workbench", inputs = {stone = 4, copper_ingot = 1}, output = "whetstone", count = 2, unlock = "rune"},
	"spore_bomb": {station = "workbench", inputs = {spore_powder = 2, spitter_gill = 1, rope = 1}, output = "spore_bomb", count = 3, unlock = "rune"},
	"bugbane_oil": {station = "cooking_pot", inputs = {venom_sac = 1, spore_powder = 2, mushroom_flesh = 1}, output = "bugbane_oil", count = 2, seconds = 20, unlock = "rune"},
	"war_horn": {station = "anvil", inputs = {ironshell_plate = 1, silver_ingot = 2, critter_hide = 2}, output = "war_horn", count = 1, unlock = "rune"},
	"ruin_style": {station = "masonry_table", inputs = {stone = 3, clay = 1}, output = "ancient_brick", count = 2, unlock = "rune"},
	"chest_copper": {station = "anvil", inputs = {plank_root = 10, copper_ingot = 6}, output = "chest_copper", count = 1, unlock = "rune"},
	"crate_ore": {station = "anvil", inputs = {plank_root = 12, copper_ingot = 4}, output = "crate_ore", count = 1, unlock = "rune"},
	"mushroom_style": {station = "masonry_table", inputs = {mushroom_flesh = 2, sporestone = 1}, output = "mushroom_brick", count = 3, unlock = "rune"},
	"twin_smelter": {station = "anvil", inputs = {silver_ingot = 4, clay = 10, sporestone = 10}, output = "twin_smelter", count = 1, unlock = "rune"},
	"copper_drip_basin": {station = "anvil", inputs = {copper_ingot = 4, plank_root = 2}, output = "copper_drip_basin", count = 1, unlock = "rune"},
	"drink_moss_ale": {station = "cooking_pot", inputs = {root_tuber = 3, hollowcap = 1, water_bucket = 2}, output = "drink_moss_ale", count = 3, seconds = 30, unlock = "rune"},
	"drink_spore_mead": {station = "cooking_pot", inputs = {spore_truffle = 2, ember_morel = 1, water_bucket = 2}, output = "drink_spore_mead", count = 3, seconds = 30, unlock = "rune"},
	"spore_mask": {station = "workbench", inputs = {leather = 2, spore_powder = 3, fiber = 4}, output = "spore_mask", count = 1, unlock = "rune"},
	"lantern_back": {station = "anvil", inputs = {copper_ingot = 4, leather = 2, lantern_lens = 1, rope = 2}, output = "lantern_back", count = 1, unlock = ["copper_ingot"]},
	# --- masonry table
	"cut_stone": {station = "masonry_table", inputs = {stone = 2}, output = "cut_stone", count = 1, unlock = []},
	"cut_marble": {station = "masonry_table", inputs = {marble = 2}, output = "cut_marble", count = 1, unlock = ["marble"]},
	"sporestone_block": {station = "masonry_table", inputs = {sporestone = 2}, output = "sporestone_block", count = 1, unlock = ["sporestone"]},
	"amber_block": {station = "masonry_table", inputs = {amberrock = 2}, output = "amber_block", count = 1, unlock = ["amberrock"]},
	"mushroom_brick": {station = "masonry_table", inputs = {mushroom_flesh = 2, clay = 1}, output = "mushroom_brick", count = 2, unlock = ["mushroom_flesh"]},
	# --- campfire (10 s)
	"dish_glowcap_skewer": {station = "campfire", inputs = {glowcap = 2}, output = "dish_glowcap_skewer", count = 1, seconds = 10, unlock = []},
	"dish_seared_critter": {station = "campfire", inputs = {critter_meat = 1}, output = "dish_seared_critter", count = 1, seconds = 10, unlock = []},
	"dish_firecap_skewer": {station = "campfire", inputs = {critter_meat = 1, firecap = 1}, output = "dish_firecap_skewer", count = 1, seconds = 10, unlock = "ruin"},
	"dish_beetle_roast": {station = "campfire", inputs = {beetle_meat = 1}, output = "dish_beetle_roast", count = 1, seconds = 10, unlock = ["beetle_meat"]},
	# ---- The first three creatures (docs/design/monsters-first-three.md)
	"dish_cooked_snail": {station = "campfire", inputs = {snail_meat = 1}, output = "dish_cooked_snail", count = 1, seconds = 10, unlock = ["snail_meat"]},
	"dish_roasted_bug": {station = "campfire", inputs = {bug_meat = 1}, output = "dish_roasted_bug", count = 1, seconds = 10, unlock = ["bug_meat"]},
	"dish_snail_stew": {station = "cooking_pot", inputs = {snail_meat = 2, hollowcap = 2}, output = "dish_snail_stew", count = 1, seconds = 20, unlock = ["snail_meat"]},
	"dish_bug_stew": {station = "cooking_pot", inputs = {bug_meat = 2, glowcap = 2}, output = "dish_bug_stew", count = 1, seconds = 20, unlock = ["bug_meat"]},
	"leather_from_wing": {station = "tanning_rack", inputs = {wing_leather = 1}, output = "leather", count = 1, seconds = 40, unlock = ["wing_leather"]},
	"waterskin_wing": {station = HAND, inputs = {wing_leather = 2, rope = 1}, output = "waterskin_empty", count = 1, unlock = ["wing_leather"]},
	"shield_shell": {station = "workbench", inputs = {shell_piece = 6, leather = 1}, output = "shield_shell", count = 1, unlock = ["shell_piece"]},
	"bolt_fang": {station = "workbench", inputs = {plank_root = 1, bat_fang = 1}, output = "bolt_fang", count = 6, unlock = ["bat_fang"]},
	"pickaxe_fang": {station = "workbench", inputs = {pickaxe_stone = 1, bat_fang = 4, leather = 1}, output = "pickaxe_fang", count = 1, unlock = ["bat_fang"]},
	"bolt_glow_gland": {station = "workbench", inputs = {plank_root = 1, glow_gland = 1}, output = "bolt_glow", count = 10, unlock = ["glow_gland"]},
	"glow_lamp": {station = "workbench", inputs = {stone = 3, glow_gland = 2}, output = "glow_lamp", count = 1, unlock = ["glow_gland"]},
	"helm_shell": {station = "workbench", inputs = {shell_piece = 3, leather = 1}, output = "helm_shell", count = 1, unlock = ["shell_piece"]},
	"plate_shell": {station = "workbench", inputs = {shell_piece = 5, leather = 2}, output = "plate_shell", count = 1, unlock = ["shell_piece"]},
	"greaves_shell": {station = "workbench", inputs = {shell_piece = 4, leather = 1}, output = "greaves_shell", count = 1, unlock = ["shell_piece"]},
	"boots_shell": {station = "workbench", inputs = {shell_piece = 3, leather = 1}, output = "boots_shell", count = 1, unlock = ["shell_piece"]},
	"dish_stalk_steak": {station = "campfire", inputs = {mushroom_flesh = 2}, output = "dish_stalk_steak", count = 1, seconds = 10, unlock = ["mushroom_flesh"]},
	"dish_ember_skewer": {station = "campfire", inputs = {beetle_meat = 1, ember_morel = 2}, output = "dish_ember_skewer", count = 1, seconds = 10, unlock = ["ember_morel"]},
	"boil_water": {station = "campfire", inputs = {waterskin_dirty = 1}, output = "waterskin_clean", count = 1, seconds = 10, unlock = ["waterskin_dirty"]},
	# --- cooking pot (20 s)
	"dish_tuber_mash": {station = "cooking_pot", inputs = {root_tuber = 3, water_bucket = 1}, output = "dish_tuber_mash", count = 1, seconds = 20, unlock = []},
	"dish_hollowcap_stew": {station = "cooking_pot", inputs = {hollowcap = 2, critter_meat = 1, water_bucket = 1}, output = "dish_hollowcap_stew", count = 1, seconds = 20, unlock = []},
	"dish_glow_broth": {station = "cooking_pot", inputs = {glowcap = 3, water_bucket = 1}, output = "dish_glow_broth", count = 1, seconds = 20, unlock = "rune"},
	"dish_miners_pie": {station = "cooking_pot", inputs = {critter_meat = 2, root_tuber = 2, hollowcap = 1}, output = "dish_miners_pie", count = 1, seconds = 20, unlock = "ruin"},
	"dish_hearth_stew": {station = "cooking_pot", inputs = {critter_meat = 2, hollowcap = 1, firecap = 1, root_tuber = 1, water_bucket = 1}, output = "dish_hearth_stew", count = 1, seconds = 20, unlock = "ruin"},
	"dish_truffle_risotto": {station = "cooking_pot", inputs = {spore_truffle = 2, root_tuber = 1, water_bucket = 1}, output = "dish_truffle_risotto", count = 1, seconds = 20, unlock = "ruin"},
	"dish_chitin_crunch": {station = "cooking_pot", inputs = {beetle_meat = 2, spore_truffle = 1, moss = 1}, output = "dish_chitin_crunch", count = 1, seconds = 20, unlock = "ruin"},
	"dish_spore_ward_stew": {station = "cooking_pot", inputs = {bellcap = 2, ember_morel = 1, moss = 1, water_bucket = 1}, output = "dish_spore_ward_stew", count = 1, seconds = 20, unlock = "rune"},
	"dish_bug_hotpot": {station = "cooking_pot", inputs = {beetle_meat = 2, ember_morel = 1, mushroom_flesh = 1, water_bucket = 1}, output = "dish_bug_hotpot", count = 1, seconds = 20, unlock = "ruin"},
	"dish_jungle_pie": {station = "cooking_pot", inputs = {beetle_meat = 2, root_tuber = 2, spore_truffle = 1}, output = "dish_jungle_pie", count = 1, seconds = 20, unlock = "rune"},
	"drink_glowcap_tea": {station = "cooking_pot", inputs = {glowcap = 2, water_bucket = 1}, output = "drink_glowcap_tea", count = 1, seconds = 20, unlock = []},
	"drink_firecap_cordial": {station = "cooking_pot", inputs = {firecap = 1, water_bucket = 2}, output = "drink_firecap_cordial", count = 1, seconds = 20, unlock = "ruin"},
}


static func get_recipe(id: String) -> Dictionary:
	return LIST.get(id, {})


## The Twin Smelter makes everything a Smelter does (two at a time).
static func station_type(kind: String) -> String:
	return "smelter" if kind == "twin_smelter" else kind


static func for_station(station: String) -> Array:
	var out := []
	station = station_type(station)
	for id in LIST:
		if LIST[id].station == station:
			out.append(id)
	return out


## True if picking up/having these items makes the recipe show up.
## `seen` = every item id the player (or world) has ever held. `taught` = recipe ids learned from runes/ruins.
static func is_unlocked(id: String, seen: Dictionary, taught: Dictionary) -> bool:
	var u = LIST[id].unlock
	if u is String:
		return taught.has(id)
	if u.is_empty():
		return true
	for item in u:
		if seen.has(item):
			return true
	return false
