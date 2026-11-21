extends TestCase
## F554 (owner, Nov 21): a ruin gave a copper mace and copper greaves recipe. Ruins now teach food and copper tools;
## copper armour and weapons come from the dungeons.


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


func test_dungeons_teach_every_copper_weapon_and_armour() -> void:
	var taught := []
	for size in DungeonList.SIZES:
		taught.append_array(DungeonList.SIZES[size].recipes)
	for r in Recipes.LIST:
		if Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin" and Recipes.page_kind(r) in ["armour", "weapon"]:
			check(taught.has(r), "%s can still be learned: a dungeon teaches it" % r)
