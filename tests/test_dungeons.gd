extends TestCase
## Zone 1 dungeons (owner, Nov 19, F237; docs/design/zone1-dungeons-plan.md): each one's page always teaches the same
## copper recipe and says which, and its chests fill up again an hour of play after someone takes from them.

var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	auth = GameAuthority.new()
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_every_copper_recipe_has_its_own_page() -> void:
	var copper := Recipes.LIST.keys().filter(func(r): return Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin" and Recipes.LIST[r].station in ["anvil", "armoury_bench"])
	check_eq(copper.size(), 12, "12 copper recipes, one per dungeon")
	for r in copper:
		var page: String = "page_" + r
		check(Items.exists(page) and Items.kind(page) == "page", "%s has a page" % r)
		check(Items.display_name(page).ends_with(Items.display_name(Recipes.LIST[r].output)), "its name says what it teaches: " + Items.display_name(page))
		check(Items.icon(page) != null, "%s has a picture" % page)
	check_eq(Items.display_name("page_mace_copper"), "Weaponsmith's Page: Copper Mace", "named like the owner picked")


func test_a_dungeon_page_teaches_its_one_recipe() -> void:
	await _setup()
	ps.inventory.slots[2] = {id = "page_mace_copper", count = 2}
	ps.selected_slot = 2
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "learned", "the page teaches")
	check_eq(auth.world_state.learned, ["mace_copper"], "always the mace")
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "nothing_new", "a second copy teaches nothing new")
	check_eq(ps.inventory.count_of("page_mace_copper"), 1, "and isn't used up")
	_teardown()


func test_dungeon_chests_fill_up_again_after_an_hour_of_play() -> void:
	await _setup()
	player.global_position = Vector3(100, 0, 0)
	var box := auth.storage.create_box("chest_loot", Vector3.ZERO, 0.0)
	DungeonLoot.add(auth, box, {page_sword_copper = 1, rusty_scrap = 4})
	var inv: Inventory = auth.storage.get_box(box).inv
	check_eq(inv.count_of("page_sword_copper"), 1, "the page is in it")
	inv.remove("page_sword_copper", 1)
	inv.remove("rusty_scrap", 3)
	auth.world_state.played = 100.0
	DungeonLoot.tick(auth)  # someone took things: the clock starts
	auth.world_state.played = 100.0 + DungeonLoot.REFILL - 1.0
	DungeonLoot.tick(auth)
	check_eq(inv.count_of("page_sword_copper"), 0, "not yet before the hour is up")
	player.global_position = Vector3(5, 0, 0)
	auth.world_state.played = 100.0 + DungeonLoot.REFILL
	DungeonLoot.tick(auth)
	check_eq(inv.count_of("page_sword_copper"), 0, "not while someone stands right there")
	player.global_position = Vector3(100, 0, 0)
	DungeonLoot.tick(auth)
	check_eq(inv.count_of("page_sword_copper"), 1, "the same page comes back")
	check_eq(inv.count_of("rusty_scrap"), 4, "and the scrap is topped back up")
	check_eq(float(auth.world_state.dungeon_chests[str(box)].taken_at), -1.0, "the clock is reset")
	_teardown()
