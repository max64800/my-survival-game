extends TestCase
## F554 (owner, Nov 21): a ruin gave a copper mace and copper greaves recipe. Ruins now teach food and copper tools;
## copper armour and weapons come from named pages, each ruin always the same (owner, Nov 24, F844).


func test_ruin_pages_are_food_or_tools() -> void:
	var seen := {}
	for i in 200:
		seen[Recipes.random_page(i / 200.0)] = true
	check(seen.has("cook_page"), "ruins still give Cook's Pages")
	check(seen.has("tool_page"), "and Toolmaker's Pages (copper tools)")
	check(not seen.has("armour_page"), "never an Armourer's Page")
	check(not seen.has("weapon_page"), "never a Weaponsmith's Page")
	for r in Recipes.page_recipes("tool_page"):
		check(not Recipes.page_kind(r) in ["armour", "weapon"], "a tool page teaches no armour or weapon (%s)" % r)


func test_each_copper_recipe_is_taught_by_exactly_one_ruin() -> void:
	var where := {}
	for ruin in Recipes.RUIN_COPPER:
		for r in Recipes.RUIN_COPPER[ruin]:
			check(Items.exists("page_" + r), "%s: a named page exists" % r)
			where[r] = where.get(r, []) + [ruin]
	for r in Recipes.LIST:
		if Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin" and Recipes.page_kind(r) in ["armour", "weapon"]:
			check_eq(where.get(r, []).size(), 1, "%s is taught by exactly one ruin %s" % [r, where.get(r, [])])
	check(not where.has("pickaxe_copper"), "the Copper Pickaxe stays free (heartwood), no ruin page")
	check_eq(Recipes.LIST.pickaxe_copper.unlock, ["heartwood"], "the Copper Pickaxe unlocks on heartwood")


func test_each_ruin_page_lands_in_a_chest_that_spawns() -> void:
	# The ruins the game builds (main.gd), by the name each one saves as (RuinTower.ruin_name).
	var built := {tower = RuinTower.PLAN, outpost = RuinOutpost.OUTPOST_PLAN, brewhall = RuinBrewhall.PLAN_PATH,
		spire = RuinSpire.PLAN_PATH, manor = RuinManor.PLAN_PATH, prow_hall = RuinProwHall.PLAN_PATH, twin_gate = RuinTwinGate.PLAN_PATH, smeltery = RuinSmeltery.PLAN_PATH,
		minehead = RuinMinehead.PLAN_PATH,
		cliff_galleries = RuinCliffGalleries.PLAN_PATH}
	for ruin in Recipes.RUIN_COPPER:
		if Recipes.RUIN_COPPER[ruin].is_empty():
			continue
		check(built.has(ruin), "%s is a ruin the game really builds" % ruin)
		var plan := RuinTower.load_plan(String(built.get(ruin, "")))
		var main := RuinTower.main_chest(plan.get("chests", []))
		check(main >= 0, "%s has a main chest for its copper page(s)" % ruin)
		if main >= 0:
			check(String(plan.chests[main].kind).begins_with("chest"), "%s: the main chest is a real chest (%s)" % [ruin, plan.chests[main].kind])
