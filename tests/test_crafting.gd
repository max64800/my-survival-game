extends TestCase


func test_every_recipe_uses_real_items() -> void:
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		check(Items.exists(r.output), "%s makes unknown item %s" % [id, r.output])
		for item in r.inputs:
			check(Items.exists(item), "%s needs unknown item %s" % [id, item])
		if r.unlock is Array:
			for item in r.unlock:
				check(Items.exists(item) or item == "rune", "%s unlocks from unknown item %s" % [id, item])


func test_every_station_can_be_made() -> void:
	var outputs := {}
	for id in Recipes.LIST:
		outputs[Recipes.LIST[id].output] = true
	for id in Recipes.LIST:
		var st: String = Recipes.LIST[id].station
		check(st == Recipes.HAND or outputs.has(st), "station %s (for %s) has no recipe" % [st, id])


func test_every_dish_has_a_recipe() -> void:
	var made := {}
	for id in Recipes.LIST:
		made[Recipes.LIST[id].output] = true
	for dish in Foods.DISHES:
		var deferred: bool = dish in ["drink_moss_ale", "drink_spore_mead", "drink_deep_stout"]  # Brewing Barrel comes later
		check(made.has(dish) or deferred, "%s has no recipe" % dish)


func test_craft_campfire_by_hand() -> void:
	var inv := Inventory.new()
	inv.add("stone", 7)
	inv.add("rootwood", 2)
	check(not Crafting.can_craft(inv, "campfire"), "1 rootwood short")
	check_eq(Crafting.missing(inv, "campfire"), {rootwood = 1}, "says what's missing")
	inv.add("rootwood", 1)
	check(Crafting.craft(inv, "campfire"), "crafted")
	check_eq(inv.count_of("campfire"), 1, "got a campfire")
	check_eq(inv.count_of("stone"), 2, "used 5 stone")
	check_eq(inv.count_of("rootwood"), 0, "used 3 rootwood")


func test_planks_make_two() -> void:
	var inv := Inventory.new()
	inv.add("rootwood", 1)
	Crafting.craft(inv, "plank_root")
	check_eq(inv.count_of("plank_root"), 2, "1 rootwood → 2 planks")


func test_full_bag_takes_nothing() -> void:
	var inv := Inventory.new()
	inv.add("stone", 100 * (Inventory.SIZE - 1))
	inv.add("rootwood", 100)  # bag now completely full
	# Planks need a new slot (rootwood stack shrinks by 1 but doesn't empty).
	check(not Crafting.craft(inv, "plank_root"), "no room for planks")
	check_eq(inv.count_of("rootwood"), 100, "nothing taken")


func test_inputs_free_room_for_output() -> void:
	var inv := Inventory.new()
	inv.add("stone", 100 * (Inventory.SIZE - 1))
	inv.add("rootwood", 1)  # last slot: 1 rootwood
	check(Crafting.craft(inv, "plank_root"), "the rootwood's slot frees up for the planks")


func test_boss_part_needed_for_copper_pickaxe() -> void:
	var inv := Inventory.new()
	inv.add("copper_ingot", 8)
	inv.add("plank_root", 4)
	inv.add("leather", 2)
	check(not Crafting.can_craft(inv, "pickaxe_copper"), "no heartstone, no copper pickaxe")
	inv.add("keeper_heartstone", 1)
	check(Crafting.craft(inv, "pickaxe_copper"), "with it, yes")
	check_eq(Items.tier("pickaxe_copper"), 1, "copper tier")


func test_unlocks() -> void:
	check(Recipes.is_unlocked("campfire", {}, {}), "campfire known from start")
	check(not Recipes.is_unlocked("smelter", {}, {}), "smelter hidden at start")
	check(Recipes.is_unlocked("smelter", {copper_ore = true}, {}), "smelter after first copper")
	check(not Recipes.is_unlocked("dish_glow_broth", {glowcap = true}, {}), "rune recipe stays hidden")
	check(Recipes.is_unlocked("dish_glow_broth", {}, {dish_glow_broth = true}), "until the rune teaches it")


func test_copper_pickaxe_digs_border_rock() -> void:
	check_eq(Mat.hits_needed(Mat.BORDER, Items.dig_power("pickaxe_stone"), Items.tier("pickaxe_stone")), 0, "stone pickaxe can't")
	check_eq(Mat.hits_needed(Mat.BORDER, Items.dig_power("pickaxe_copper"), Items.tier("pickaxe_copper")), 7, "copper pickaxe: 7 hits (doc 2.3)")
	check_eq(Mat.hits_needed(Mat.COPPER, 13, 1), 4, "copper pickaxe on copper ore: 4 hits")
	check_eq(Mat.hits_needed(Mat.STONE, 10, 0), 3, "stone pickaxe on stone: 3 hits")
