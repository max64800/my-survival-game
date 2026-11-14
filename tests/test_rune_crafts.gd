extends TestCase
## Water, and the things rune carvings teach (progression doc 6.4 and 8).

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_every_rune_recipe_exists() -> void:
	for r in RuneSlab.RUNES:
		var e: Dictionary = RuneSlab.RUNES[r]
		if e.has("recipe"):
			check(Recipes.LIST.has(e.recipe), "rune %s teaches a real recipe (%s)" % [r, e.recipe])
	for id in Recipes.LIST:
		var rc: Dictionary = Recipes.LIST[id]
		check(Items.exists(rc.output), "%s makes a real item" % id)
		for i in rc.inputs:
			check(Items.exists(i), "%s needs a real item (%s)" % [id, i])


func test_drip_bucket_fills_and_gives_water() -> void:
	await _setup()
	auth._ev_place_station(5, "drip_bucket", player.global_position + Vector3(1.5, 0, 0), 0.0)
	var st: Station = auth.stations[5]
	st.tick_water(300.0)
	check_eq(st.water, 0, "no drip above: stays empty")
	auth._ev_water(5, 0, true)
	for i in 5:
		st.tick_water(241.0)
	check_eq(st.water, 5, "1 bucket every 4 minutes")
	st.tick_water(241.0)
	check_eq(st.water, 5, "holds 5")
	ps.inventory.add("waterskin_empty", 1)
	check_eq(auth.request_collect_water(1, 5), 5, "took it all")
	check_eq(ps.inventory.count_of("waterskin_clean"), 1, "the empty waterskin got filled first")
	check_eq(ps.inventory.count_of("water_bucket"), 4, "the rest are buckets of water")
	check_eq(st.water, 0, "empty again")
	_teardown()


func test_drips_exist_in_the_cave() -> void:
	var n := 0
	for s in GlowPlacer.place(CaveMaker.new(42)):
		if s.kind == GlowPlacer.DRIP:
			n += 1
	check(n >= 20, "plenty of dripping stalactites (%d)" % n)


func test_whetstone_and_bug_oil_boost_damage() -> void:
	await _setup()
	ps.inventory.slots[2] = {id = "whetstone", count = 1}
	ps.selected_slot = 2
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "used", "whetstone used")
	check_near(auth.damage_boost(ps), 0.05, 0.0001, "+5% damage")
	ps.inventory.slots[2] = {id = "bugbane_oil", count = 1}
	auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0)
	check_near(auth.damage_boost(ps, "needlemite"), 0.20, 0.0001, "+15% more against bugs")
	check_near(auth.damage_boost(ps, "cairnling"), 0.05, 0.0001, "but not against stone golems")
	_teardown()


func test_twin_smelter_runs_two_jobs() -> void:
	await _setup()
	auth._ev_place_station(6, "twin_smelter", player.global_position + Vector3(2, 0, 0), 0.0)
	var st: Station = auth.stations[6]
	st.queue_job("copper_ingot", 1, 10.0)
	st.queue_job("copper_ingot", 1, 10.0)
	check_eq(st.tick(11.0).size(), 2, "both finished together")
	check(Recipes.for_station("twin_smelter").has("copper_ingot"), "it makes what a smelter makes")
	_teardown()


func test_ore_crate_only_takes_ore() -> void:
	check(Storage.accepts("crate_ore", "copper_ore"), "ore yes")
	check(Storage.accepts("crate_ore", "crystal_blue"), "crystals yes")
	check(not Storage.accepts("crate_ore", "sword_stone"), "swords no")


func test_recipe_pages_from_ruins() -> void:
	await _setup()
	var ruin_recipes := Recipes.LIST.keys().filter(func(r): return Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin")
	check(ruin_recipes.size() <= 2 * world.maker.pois_of("ruin").size(), "enough ruin pages to find every ruin recipe")
	ps.inventory.slots[2] = {id = "recipe_page", count = 2}
	ps.selected_slot = 2
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "learned", "the page teaches a recipe")
	check_eq(auth.world_state.learned.size(), 1, "remembered by the world")
	check(auth.taught_recipes().has(auth.world_state.learned[0]), "and it shows up in the crafting list")
	_teardown()
