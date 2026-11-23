extends TestCase


func test_every_recipe_uses_real_items() -> void:
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		check(Items.exists(r.output), "%s makes unknown item %s" % [id, r.output])
		for item in r.inputs:
			check(Items.exists(item), "%s needs unknown item %s" % [id, item])
		if r.unlock is Array:
			for item in r.unlock:
				check(Items.exists(item) or item == "rune_*", "%s unlocks from unknown item %s" % [id, item])  # rune_* = any rune (F399)


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
	inv.add("stone", Items.stack_size("stone") * (Inventory.SIZE - 1))  # (stacks by kind since F793)
	var wood := Items.stack_size("rootwood")
	inv.add("rootwood", wood)  # bag now completely full
	# Planks need a new slot (rootwood stack shrinks by 1 but doesn't empty).
	check(not Crafting.craft(inv, "plank_root"), "no room for planks")
	check_eq(inv.count_of("rootwood"), wood, "nothing taken")


func test_inputs_free_room_for_output() -> void:
	var inv := Inventory.new()
	inv.add("stone", Items.stack_size("stone") * (Inventory.SIZE - 1))
	inv.add("rootwood", 1)  # last slot: 1 rootwood
	check(Crafting.craft(inv, "plank_root"), "the rootwood's slot frees up for the planks")


func test_heartwood_needed_for_copper_pickaxe() -> void:
	var inv := Inventory.new()
	inv.add("copper_ingot", 15)  # copper tools cost 15 bars (owner, Nov 19)
	inv.add("plank_root", 4)
	inv.add("leather", 2)
	check(not Crafting.can_craft(inv, "pickaxe_copper"), "no Root Tree Heartwood, no copper pickaxe")
	inv.add("heartwood", 1)
	check(Crafting.craft(inv, "pickaxe_copper"), "with it, yes")
	check_eq(Items.tier("pickaxe_copper"), 1, "copper tier")


## F398: bats' wing leather showed "tan it on a Tanning Rack", but the rack only showed up after critter hide.
## Holding a recipe's ingredients must always make the station it needs show up too.
func test_holding_the_ingredients_shows_the_station_too() -> void:
	var maker := {}  # station id -> the recipe that makes it
	for id in Recipes.LIST:
		maker[Recipes.LIST[id].output] = id
	var stuck := []
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		if r.station == Recipes.HAND or not r.unlock is Array or r.unlock.is_empty() or not maker.has(r.station):
			continue
		for x in r.unlock:
			var seen := {x: true, "copper_ore": true, "copper_ingot": true}  # copper comes early for everyone
			for i in r.inputs:
				seen[i] = true
			if Recipes.is_unlocked(id, seen, {}) and not Recipes.is_unlocked(maker[r.station], seen, {}):
				stuck.append("%s (found %s, but no %s)" % [id, x, r.station])
	check(stuck.is_empty(), "every shown recipe's station can be made: %s" % ", ".join(stuck))


## F399: the Rune Slab shows up once you've found any rune (it waited for an item "rune" that doesn't exist).
func test_rune_slab_shows_after_any_rune() -> void:
	check(not Recipes.is_unlocked("rune_slab", {}, {}), "hidden at the start")
	check(Recipes.is_unlocked("rune_slab", {"rune_ochre_m1": true}, {}), "shows after finding a rune")
	check(not Recipes.is_unlocked("rune_slab", {"rope": true}, {}), "rope isn't a rune")


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


func test_dwarf_makes_the_in_between_items_first() -> void:
	var inv := Inventory.new(20)
	inv.add("rootwood", 3)
	inv.add("rope", 4)
	var any := func(_id): return true
	var steps := Crafting.plan(inv, "tanning_rack", "workbench", any)
	check_eq(steps, ["plank_root", "plank_root", "plank_root", "tanning_rack"], "3 rootwood become 6 planks, then the rack")
	inv.remove("rootwood", 1)
	check_eq(Crafting.plan(inv, "tanning_rack", "workbench", any), [], "not enough wood: can't be done")
	var bag := Inventory.new(20)
	bag.add("bug_meat", 2)
	bag.add("root_tuber", 2)
	bag.add("hollowcap", 1)
	check_eq(Crafting.plan(bag, "dish_miners_pie", "campfire", any), ["dish_roasted_bug", "dish_roasted_bug", "dish_miners_pie"],
		"the kitchen is one station now: raw bug meat gets roasted first, then the pie")


func test_helpers_link_to_stations_within_10_m() -> void:
	check_eq(Station.EXTRA_RANGE, 10.0, "helpers count from 10 m away")
	check_eq(Station.helps_kind("bellows"), "anvil", "bellows help the anvil")
	check_eq(Station.helps_kind("anvil"), "", "an anvil isn't a helper")
	var near := StationLinks.ghost_links("bellows", Vector3(8, 0, 0), [_fake("anvil", Vector3.ZERO), _fake("workbench", Vector3(1, 0, 0))])
	check_eq(near.size(), 1, "bellows 8 m away: one line, to the anvil only")
	check_eq(StationLinks.ghost_links("bellows", Vector3(12, 0, 0), [_fake("anvil", Vector3.ZERO)]).size(), 0, "12 m: too far, no line")


class _FakeStation:
	var kind := ""
	var global_position := Vector3.ZERO


func _fake(k: String, at: Vector3) -> _FakeStation:
	var f := _FakeStation.new()
	f.kind = k
	f.global_position = at
	return f



func test_kitchen_levels() -> void:
	check_eq(Recipes.get_recipe("dish_snail_stew").station, "campfire", "stews cook at the campfire")
	check_eq(int(Recipes.get_recipe("dish_snail_stew").get("level", 1)), 2, "with a pot on it (level 2)")
	check_eq(int(Recipes.get_recipe("dish_miners_pie").get("level", 1)), 3, "the best meals need the Stone Oven (level 3)")
	check_eq(Station.helps_kind("cooking_pot"), "campfire", "the pot helps the campfire")
	var fire := _fake("campfire", Vector3(2, 0, 0))
	check_eq(Station.on_fire_spot("cooking_pot", Vector3(2.5, 0, 0), [fire]), Vector3(2, Station.POT_HEIGHT, 0), "a pot aimed near a fire sits on top of it")
	check_eq(Station.on_fire_spot("cooking_pot", Vector3(6, 0, 0), [fire]), Vector3.INF, "far from a fire: placed normally")
	check_eq(Station.on_fire_spot("cooking_pot", Vector3(2.5, 0, 0), [fire, _fake("cooking_pot", Vector3(2, 0.35, 0))]), Vector3.INF, "one pot per fire")
