class_name Recipes
## Every recipe (progression doc sections 1.6, 3.2, 4, 5.4, 6, 10.2).
## Each recipe: station, inputs {item: count}, output item + count, seconds (0 = instant),
## unlock = the items that make it appear when first picked up ([] = known from the start),
##          or "rune"/"ruin" (taught by a rune or a ruin scroll).
## "water" in the doc means 1 water_bucket here (a clean waterskin sip comes later).

const HAND := "hand"

const LIST := {
	# --- by hand (bag menu)
	"rope": {station = HAND, inputs = {fiber = 3}, output = "rope", count = 1, unlock = []},
	"campfire": {station = HAND, inputs = {stone = 5, rootwood = 3}, output = "campfire", count = 1, unlock = []},
	"workbench": {station = HAND, inputs = {rootwood = 10, stone = 6}, output = "workbench", count = 1, unlock = []},
	"waterskin": {station = HAND, inputs = {critter_hide = 2, rope = 1}, output = "waterskin_empty", count = 1, unlock = ["critter_hide"]},
	"drink_bellcap_juice": {station = HAND, inputs = {bellcap = 2}, output = "drink_bellcap_juice", count = 1, unlock = ["bellcap"]},
	# --- workbench
	"plank_root": {station = "workbench", inputs = {rootwood = 1}, output = "plank_root", count = 2, unlock = []},
	"plank_mushroom": {station = "workbench", inputs = {mushroom_wood = 1}, output = "plank_mushroom", count = 2, unlock = ["mushroom_wood"]},
	"pickaxe_stone": {station = "workbench", inputs = {stone = 4, rootwood = 2, rope = 2}, output = "pickaxe_stone", count = 1, unlock = []},
	"axe_stone": {station = "workbench", inputs = {stone = 3, rootwood = 2, rope = 2}, output = "axe_stone", count = 1, unlock = []},
	"build_hammer": {station = "workbench", inputs = {stone = 3, rootwood = 2}, output = "build_hammer", count = 1, unlock = []},
	"bed": {station = "workbench", inputs = {plank_root = 6, moss = 4, leather = 2}, output = "bed", count = 1, unlock = []},
	"tanning_rack": {station = "workbench", inputs = {plank_root = 6, rope = 4}, output = "tanning_rack", count = 1, unlock = ["critter_hide"]},
	"smelter": {station = "workbench", inputs = {stone = 20, clay = 15}, output = "smelter", count = 1, unlock = ["copper_ore"]},
	"farm_plot": {station = "workbench", inputs = {dirt = 10, moss = 5, plank_root = 4}, output = "farm_plot", count = 1, unlock = ["glowcap", "hollowcap", "bellcap", "root_tuber"]},
	"drip_bucket": {station = "workbench", inputs = {plank_root = 4, rope = 1}, output = "drip_bucket", count = 1, unlock = []},
	"rune_slab": {station = "workbench", inputs = {stone = 15, cut_stone = 5}, output = "rune_slab", count = 1, unlock = ["rune"]},
	"anvil": {station = "workbench", inputs = {stone = 10, copper_ingot = 6}, output = "anvil", count = 1, unlock = ["copper_ingot"]},
	"cooking_pot": {station = "workbench", inputs = {copper_ingot = 4, stone = 4}, output = "cooking_pot", count = 1, unlock = ["copper_ingot"]},
	"masonry_table": {station = "workbench", inputs = {stone = 10, plank_root = 6, copper_ingot = 2}, output = "masonry_table", count = 1, unlock = ["copper_ingot"]},
	# --- tanning rack (60 s each)
	"leather": {station = "tanning_rack", inputs = {critter_hide = 1}, output = "leather", count = 1, seconds = 60, unlock = ["critter_hide"]},
	# --- smelter (needs wood fuel; times from doc 4.2)
	"copper_ingot": {station = "smelter", inputs = {copper_ore = 2}, output = "copper_ingot", count = 1, seconds = 20, fuel = 1, unlock = ["copper_ore"]},
	"copper_from_scrap": {station = "smelter", inputs = {rusty_scrap = 3}, output = "copper_ingot", count = 1, seconds = 20, fuel = 1, unlock = ["rusty_scrap"]},
	"silver_ingot": {station = "smelter", inputs = {silver_ore = 2}, output = "silver_ingot", count = 1, seconds = 30, fuel = 1, unlock = ["silver_ore"]},
	"clay_brick": {station = "smelter", inputs = {clay = 2}, output = "clay_brick", count = 2, seconds = 10, fuel = 1, unlock = ["clay"]},
	"lantern_lens": {station = "smelter", inputs = {crystal_blue = 3, clay = 1}, output = "lantern_lens", count = 1, seconds = 30, fuel = 1, unlock = ["crystal_blue"]},
	# --- anvil
	"axe_copper": {station = "anvil", inputs = {copper_ingot = 6, plank_root = 3, leather = 1}, output = "axe_copper", count = 1, unlock = ["copper_ingot"]},
	"pickaxe_copper": {station = "anvil", inputs = {copper_ingot = 8, plank_root = 4, leather = 2, keeper_heartstone = 1}, output = "pickaxe_copper", count = 1, unlock = ["keeper_heartstone"]},
	"axe_silver": {station = "anvil", inputs = {silver_ingot = 6, plank_mushroom = 3, chitin_plate = 2}, output = "axe_silver", count = 1, unlock = ["silver_ingot"]},
	"pickaxe_silver": {station = "anvil", inputs = {silver_ingot = 8, plank_mushroom = 4, chitin_plate = 2, bloomheart_core = 1}, output = "pickaxe_silver", count = 1, unlock = ["bloomheart_core"]},
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
	"dish_beetle_roast": {station = "campfire", inputs = {beetle_meat = 1}, output = "dish_beetle_roast", count = 1, seconds = 10, unlock = []},
	"dish_stalk_steak": {station = "campfire", inputs = {mushroom_flesh = 2}, output = "dish_stalk_steak", count = 1, seconds = 10, unlock = []},
	"dish_ember_skewer": {station = "campfire", inputs = {beetle_meat = 1, ember_morel = 2}, output = "dish_ember_skewer", count = 1, seconds = 10, unlock = []},
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


static func for_station(station: String) -> Array:
	var out := []
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
