extends TestCase
## The 12 Zone 1 dungeons (owner, Nov 20, F237): 4 small wooden, 5 medium stone, 3 big clay, and together they teach
## every bronze recipe exactly once (copper is the ruins' job). Each dungeon always teaches the same one (owner, Nov 24, F844).


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
	# F844 step 5 (owner's plan): dungeons teach bronze; copper comes from the ruins (test_ruin_loot).
	var bronze := Recipes.LIST.keys().filter(func(r): return Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "dungeon" and r != "pickaxe_bronze")
	bronze.sort()
	var got := DungeonList.LIST.map(func(d): return DungeonList.recipe_of(d.id))
	for r in got:
		check(Recipes.LIST.has(r), "%s is a real recipe" % r)
		check(String(r).ends_with("_bronze"), "%s is a bronze recipe" % r)
	got.sort()
	check_eq(got, bronze, "all 12 bronze recipes, each taught by a different dungeon")
	var order := ["helm", "boots", "greaves", "crossbow", "mail", "spear", "axe", "shield", "sword", "mace", "mace_2h", "axe_2h"]
	check_eq(DungeonList.LIST.map(func(d): return DungeonList.recipe_of(d.id).trim_suffix("_bronze")), order, "in the owner's order")
	check_eq(DungeonList.recipe_of("nowhere"), "", "unknown dungeon: nothing")


## F844 step 5: every dungeon the game really builds has a stand whose scroll teaches that dungeon's bronze recipe.
## The same in every world: what a stand holds comes from the dungeon's plan, never from the seed.
func test_every_built_dungeon_teaches_a_bronze_recipe() -> void:
	check_eq(DungeonBuild.PLANS.size(), 8, "8 dungeons are built so far (the other 4 come later, F742)")
	for key in DungeonBuild.PLANS:
		var lid := String(DungeonBuild.LIST_ID.get(key, ""))
		check(DungeonList.get_dungeon(lid).size() > 0, "%s is in the dungeon list" % key)
		var stand: Dictionary = DungeonBuild.load_plan(String(key)).get("recipe_stand", {})
		check(not stand.is_empty(), "%s has a recipe stand" % key)
		var page := String(stand.get("page", ""))
		var taught := String(Items.info(page).get("teaches_recipe", ""))
		check_eq(taught, DungeonList.recipe_of(lid), "%s: its stand's %s teaches its own recipe" % [key, page])
		check(taught.ends_with("_bronze") and Recipes.LIST.get(taught, {}).get("unlock", "") == "dungeon", "%s teaches bronze (%s)" % [key, taught])


## F844 step 5: Mossgate Hold's big chest always holds the Bronze Pickaxe page, and only Mossgate's.
func test_mossgate_big_chest_holds_the_bronze_pickaxe_page() -> void:
	check(Items.exists("page_pickaxe_bronze"), "the Bronze Pickaxe page is a real item")
	check_eq(String(Items.info("page_pickaxe_bronze").get("teaches_recipe", Items.info("page_pickaxe_bronze").get("recipe", ""))), "pickaxe_bronze", "it teaches the Bronze Pickaxe")
	check_eq(DungeonBuild.BIG_CHEST_EXTRA, {"mossgate_hold": {"page_pickaxe_bronze": 1}}, "only Mossgate's big chest gets it")
	var bigs: Array = DungeonBuild.load_plan("mossgate").get("chests", []).filter(func(c): return String(c.get("loot", "")) == "big")
	check_eq(bigs.size(), 1, "Mossgate has one big chest")
	check(bigs.size() == 1 and bigs[0].get("always", false), "and it is always there (never left out by chance)")
