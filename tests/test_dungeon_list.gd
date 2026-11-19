extends TestCase
## The 12 Zone 1 dungeons (owner, Nov 20, F237): 4 small wooden, 5 medium stone, 3 big clay, and together they teach
## every copper recipe exactly once in every world.


func test_twelve_dungeons_in_three_sizes() -> void:
	check_eq(DungeonList.LIST.size(), 12, "12 dungeons")
	var count := {}
	for d in DungeonList.LIST:
		count[d.size] = count.get(d.size, 0) + 1
		check(DungeonList.SIZES.has(d.size), "%s has a known size" % d.name)
	check_eq(count, {small = 4, medium = 5, big = 3}, "4 small, 5 medium, 3 big")
	for s in DungeonList.SIZES:
		check_eq(DungeonList.SIZES[s].recipes.size(), count[s], "%s: one recipe per dungeon" % s)
		check(Items.exists("pillar__" + DungeonList.SIZES[s].material) or Items.exists(DungeonList.SIZES[s].material), "%s is built from a real material" % s)


func test_every_copper_recipe_once_per_world() -> void:
	var copper := Recipes.LIST.keys().filter(func(r): return Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin" and Recipes.LIST[r].station == "anvil")
	copper.sort()
	for world_seed in [1, 42, 9001]:
		var got := DungeonList.LIST.map(func(d): return DungeonList.recipe_of(world_seed, d.id))
		for r in got:
			check(Items.exists("page_" + r), "%s has a dungeon page" % r)
		got.sort()
		check_eq(got, copper, "world %d: all 12 copper recipes, each once" % world_seed)
	check_eq(DungeonList.recipe_of(42, "mossgate_hold"), DungeonList.recipe_of(42, "mossgate_hold"), "the same world always gives the same answer")
	check_eq(DungeonList.recipe_of(42, "nowhere"), "", "unknown dungeon: nothing")
