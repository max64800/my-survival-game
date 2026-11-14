extends TestCase
## Checks the referee (request → approve → everyone updates) with a real cave.

var world: World
var auth: GameAuthority
var glow: GlowField
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup(seed: int, at: Vector3 = Vector3.INF) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations_root := Node3D.new()
	root.add_child(stations_root)
	world = World.new()
	root.add_child(world)
	world.setup(seed)
	glow = GlowField.new()
	root.add_child(glow)
	glow.build(GlowPlacer.place(world.maker))
	var drops := Node3D.new()
	root.add_child(drops)
	auth = GameAuthority.new()
	auth.world = world
	auth.glow = glow
	auth.drops_root = drops
	auth.stations_root = stations_root
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn if at == Vector3.INF else at
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 600:
		if world.is_ready_at(player.global_position, 6.0):
			break
		await tree.process_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


## Finds a rock spot of material `mat` near spawn, then stands the player right above it.
func _find_rock(mat: int) -> Vector3:
	var base := player.global_position
	for r in range(0, 8):
		for x in range(-r, r + 1):
			for z in range(-r, r + 1):
				for y in range(-6, 3):
					var p := base + Vector3(x, y, z)
					if world.sdf_at(p) < -0.5 and world.rock_material_near(p - Vector3.UP * 0.3, 1.1) == mat:
						player.global_position = p + Vector3.UP * 1.5
						return p
	return Vector3.INF


func test_stone_takes_three_hits_and_drops_stone() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	check(p != Vector3.INF, "found stone near spawn")
	if p == Vector3.INF:
		_teardown()
		return
	var r1 := auth.request_hit(1, p, Vector3.UP)
	var r2 := auth.request_hit(1, p, Vector3.UP)
	check_eq(r1.get("state"), "hit", "1st hit")
	check_eq(r2.get("state"), "hit", "2nd hit")
	check_eq(r1.get("needed"), 3, "stone needs 3 hits with a stone pickaxe")
	var before := auth.drop_count()
	var r3 := auth.request_hit(1, p, Vector3.UP)
	check_eq(r3.get("state"), "dug", "3rd hit digs")
	check(auth.drop_count() > before, "digging stone drops something")
	_teardown()


func test_moss_or_dirt_is_one_hit() -> void:
	await _setup(42)
	var p := _find_rock(Mat.MOSS)
	if p == Vector3.INF:
		p = _find_rock(Mat.DIRT)
	check(p != Vector3.INF, "found moss/dirt near spawn")
	if p != Vector3.INF:
		check_eq(auth.request_hit(1, p, Vector3.UP).get("state"), "dug", "soft ground digs in 1 hit")
	_teardown()


func test_border_rock_is_blocked() -> void:
	var edge := Vector3(CaveMaker.HALF_SIZE + 1.5, -30.0, 0.0)
	await _setup(42, edge + Vector3(-2.5, -1.0, 0))
	var r := auth.request_hit(1, edge, Vector3.LEFT)
	check_eq(r.get("state"), "blocked", "border rock can't be dug")
	check(world.sdf_at(edge) < 0.0, "border rock is still there")
	_teardown()


func test_needs_pickaxe_selected() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	auth.request_select_slot(1, 3)
	check_eq(auth.request_hit(1, p, Vector3.UP).get("state"), "no_tool", "empty hand can't dig")
	_teardown()


func test_too_far_is_refused() -> void:
	await _setup(42)
	var far := player.global_position + Vector3(0, -2, 12)
	check_eq(auth.request_hit(1, far, Vector3.UP).get("state"), "too_far", "can't dig 12 m away")
	_teardown()


func test_pickup_puts_items_in_bag() -> void:
	await _setup(42)
	auth.spawn_drop("copper_ore", 3, player.global_position + Vector3.UP)
	var id: int = auth._drops.keys()[0]
	check(auth.request_pickup(1, id), "pickup approved")
	check_eq(ps.inventory.count_of("copper_ore"), 3, "3 copper in the bag")
	check_eq(auth.drop_count(), 0, "drop is gone")
	auth.spawn_drop("stone", 1, player.global_position + Vector3(0, 0, 30))
	var far_id: int = auth._drops.keys()[0]
	check(not auth.request_pickup(1, far_id), "can't pick up from 30 m away")
	_teardown()


func test_lantern_refill_uses_a_crystal() -> void:
	await _setup(42)
	check(not auth.request_refill(1), "full lantern can't be refilled")
	ps.fuel = 10.0
	check(not auth.request_refill(1), "no crystal, no refill")
	ps.inventory.add("crystal_blue", 2)
	check(auth.request_refill(1), "refill with a crystal")
	check_eq(ps.inventory.count_of("crystal_blue"), 1, "one crystal used")
	check_near(ps.fuel, 10.0 + Items.fuel_seconds("crystal_blue"), 0.01, "fuel went up")
	_teardown()


func test_fuel_burns_down_but_not_below_zero() -> void:
	await _setup(42)
	ps.fuel = 0.05
	await frames(10)
	check_eq(ps.fuel, 0.0, "fuel stops at zero")
	_teardown()


func test_breaking_glow_crystal_gives_crystals() -> void:
	await _setup(42)
	var spot := _first_spot(GlowPlacer.CRYSTAL)
	player.global_position = spot.pos + spot.normal * 1.5 - Vector3.UP
	check_eq(auth.request_harvest(1, spot.id).get("state"), "hit", "crystal needs 2 hits with a stone pickaxe")
	check_eq(auth.request_harvest(1, spot.id).get("state"), "done", "second hit breaks it")
	check(glow.get_spot(spot.id).is_empty(), "crystal removed")
	check_eq(auth.drop_count(), 1, "crystal drop spawned")
	check_eq(auth.request_harvest(1, spot.id).get("state"), "gone", "can't break it twice")
	check(ps.progress.skill_xp.mining > 0, "mining XP for the crystal")
	_teardown()


func _first_spot(kind: String) -> Dictionary:
	for id in glow._spots:
		if glow._spots[id].kind == kind:
			return glow._spots[id]
	return {}


func test_roots_give_wood_four_times() -> void:
	await _setup(42)
	var root := _first_spot(GlowPlacer.ROOT)
	check(not root.is_empty(), "the cave has hanging roots")
	if root.is_empty():
		_teardown()
		return
	player.global_position = root.pos + Vector3.DOWN * (root.length + 0.5)
	# Stone pickaxe chops at half power: 30 / 5 = 6 hits per chop-through.
	var chops := 0
	for i in 30:
		if auth.request_harvest(1, root.id).get("state") == "done":
			chops += 1
	check_eq(chops, 4, "4 chop-throughs before the root is gone")
	check(glow.get_spot(root.id).is_empty(), "root gone after 4")
	check_eq(auth.drop_count(), 4, "4 piles of rootwood")
	_teardown()


func test_mushrooms_by_hand() -> void:
	await _setup(42)
	var cap := _first_spot("glowcap")
	player.global_position = cap.pos + Vector3.UP * 0.2
	auth.request_select_slot(1, 5)  # empty hand
	check_eq(auth.request_harvest(1, cap.id).get("state"), "done", "picked by hand in one go")
	_teardown()


func test_eat_from_hotbar() -> void:
	await _setup(42)
	ps.inventory.add("dish_hollowcap_stew", 1)
	auth.request_select_slot(1, 1)
	ps.vitals.hunger = 20
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "ate", "ate the stew")
	check_eq(ps.inventory.count_of("dish_hollowcap_stew"), 0, "stew used up")
	check_near(ps.vitals.hunger, 70.0, 0.01, "+50 hunger")
	check_near(ps.vitals.max_health(), 120.0, 0.01, "+20% max health buff")
	_teardown()


func test_waterskin_has_five_sips() -> void:
	await _setup(42)
	ps.inventory.add("waterskin_clean", 1)
	auth.request_select_slot(1, 1)
	for i in 5:
		ps.vitals.thirst = 0
		auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0)
	check_eq(ps.inventory.count_of("waterskin_empty"), 1, "empty after 5 sips")
	check_near(ps.vitals.thirst, 35.0, 0.01, "each sip +35")
	_teardown()


func test_craft_campfire_and_place_it() -> void:
	await _setup(42)
	ps.inventory.add("stone", 5)
	ps.inventory.add("rootwood", 3)
	check(auth.request_craft(1, "campfire"), "campfire crafted by hand")
	check(ps.progress.skill_xp.smithing > 0, "smithing XP for crafting")
	var slot := -1
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "campfire":
			slot = i
	auth.request_select_slot(1, slot)
	var floor_p := world.maker.find_floor(player.global_position.x + 1.5, player.global_position.z, player.global_position.y + 1.0)
	check_eq(auth.request_use(1, floor_p, Vector3.UP, 0.0), "placed", "placed on the floor")
	check_eq(auth.stations.size(), 1, "one station in the world")
	check_eq(ps.inventory.count_of("campfire"), 0, "campfire left the bag")
	_teardown()


func test_smelter_takes_time_and_fuel() -> void:
	await _setup(42)
	auth._ev_place_station(7, "smelter", player.global_position + Vector3(1.5, 0, 0), 0.0)
	ps.inventory.add("copper_ore", 4)
	check(not auth.request_craft(1, "copper_ingot", 7), "no wood fuel, no smelting")
	ps.inventory.add("rootwood", 2)
	check(auth.request_craft(1, "copper_ingot", 7), "smelting started")
	check_eq(ps.inventory.count_of("copper_ore"), 2, "ore went in")
	check_eq(ps.inventory.count_of("rootwood"), 1, "one wood burned")
	check_eq(auth.drop_count(), 0, "not done yet")
	var st: Station = auth.stations[7]
	st.jobs[0].left = 0.05
	await tree.create_timer(0.2).timeout
	check_eq(auth.drop_count(), 1, "ingot popped out")
	check(not auth.request_craft(1, "copper_ingot", 99), "unknown station refused")
	_teardown()


func test_digging_gives_mining_xp() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	for i in 3:
		auth.request_hit(1, p, Vector3.UP)
	check_eq(ps.progress.skill_xp.mining, Mat.DIG_XP[Mat.STONE], "2 mining XP for stone")
	check_eq(ps.progress.xp, Mat.DIG_XP[Mat.STONE], "and 2 character XP")
	_teardown()


func test_unknown_player_is_ignored() -> void:
	await _setup(42)
	check(auth.request_hit(99, Vector3.ZERO, Vector3.UP).is_empty(), "unknown player gets nothing")
	check(not auth.request_pickup(99, 1), "unknown player can't pick up")
	_teardown()
