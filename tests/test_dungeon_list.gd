extends TestCase
## The 12 Zone 1 dungeons (owner, Nov 20, F237): 4 small wooden, 5 medium stone, 3 big clay, and together they teach
## every copper recipe exactly once. Each dungeon always teaches the same one (owner, Nov 24, F844).


func test_twelve_dungeons_in_three_sizes() -> void:
	check_eq(DungeonList.LIST.size(), 12, "12 dungeons")
	var count := {}
	for d in DungeonList.LIST:
		count[d.size] = count.get(d.size, 0) + 1
		check(DungeonList.SIZES.has(d.size), "%s has a known size" % d.name)
	check_eq(count, {small = 4, medium = 5, big = 3}, "4 small, 5 medium, 3 big")
	for s in DungeonList.SIZES:
		check(Items.exists("pillar__" + DungeonList.SIZES[s].material) or Items.exists(DungeonList.SIZES[s].material), "%s is built from a real material" % s)


func test_each_dungeon_teaches_its_own_recipe() -> void:
	var copper := Recipes.LIST.keys().filter(func(r): return Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin" and Recipes.LIST[r].station == "anvil")
	copper.sort()
	var got := DungeonList.LIST.map(func(d): return DungeonList.recipe_of(d.id))
	for r in got:
		check(Recipes.LIST.has(r), "%s is a real recipe" % r)
	got.sort()
	check_eq(got, copper, "all 12 copper recipes, each taught by a different dungeon")
	var order := ["helm", "boots", "greaves", "crossbow", "mail", "spear", "axe", "shield", "sword", "mace", "mace_2h", "axe_2h"]
	check_eq(DungeonList.LIST.map(func(d): return DungeonList.recipe_of(d.id).trim_suffix("_copper")), order, "in the owner's order")
	check_eq(DungeonList.recipe_of("nowhere"), "", "unknown dungeon: nothing")
	# The same in every world: what a stand holds comes from the dungeon's plan, never from the seed.
	for d in DungeonList.LIST:
		var plan := DungeonBuild.load_plan(String(d.id))
		var stand: Dictionary = plan.get("recipe_stand", {})
		if stand.is_empty():
			continue
		var page := String(stand.page)
		var taught: String = Items.info(page).get("teaches_recipe", Items.info(page).get("recipe", ""))
		check_eq(taught, DungeonList.recipe_of(d.id), "%s: its stand's %s teaches its own recipe" % [d.name, page])
