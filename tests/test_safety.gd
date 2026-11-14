extends TestCase
## Fixes from the code review: bad messages from a friend's computer, and items that
## lost their data or vanished.

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
	player.global_position = world.maker.spawn_point
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_a_stretched_aim_cant_dig_far_away() -> void:
	await _setup()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_visuals = false
	player.add_child(viewer)
	for i in 600:
		if world.is_ready_at(player.global_position, 6.0):
			break
		await tree.process_frame
	var floor_pt := world.maker.find_floor(player.global_position.x + 1.0, player.global_position.z, player.global_position.y + 1.0)
	var r := {}
	for i in 12:
		r = auth.request_hit(1, floor_pt, Vector3.UP * 40.0)
		if r.get("state") != "hit":
			break
	check_eq(r.get("state"), "dug", "dug")
	var last: Vector4 = auth.edit_log[-1]
	check(Vector3(last.x, last.y, last.z).distance_to(floor_pt) < 1.0, "the dig stays next to where you hit")
	check(auth.request_hit(1, floor_pt, Vector3.ZERO).get("state") == "air", "a zero aim does nothing")
	_teardown()


func test_broken_numbers_are_refused() -> void:
	await _setup()
	var nan := Vector3(NAN, 0, 0)
	check_eq(auth.builder.request_place(1, "floor", "plank_root", nan, 0), "?", "piece at NaN refused")
	check_eq(auth.builder.request_place_blueprint(1, "{}", nan, 0, Vector3.ZERO), "?", "blueprint at NaN refused")
	ps.inventory.add("workbench", 1)
	ps.selected_slot = ps.inventory.slots.find(ps.inventory.slots.filter(func(s): return s.get("id", "") == "workbench")[0])
	check_eq(auth.request_use(1, nan, Vector3.UP, 0.0), "", "station at NaN refused")
	check_eq(ps.inventory.count_of("workbench"), 1, "and the workbench wasn't used up")
	_teardown()


func test_waterskin_keeps_its_sips_in_a_chest() -> void:
	await _setup()
	var box := auth.storage.create_box("chest_small", player.global_position + Vector3(1, 0, 0), 0.0, 1)
	ps.inventory.add("waterskin_clean", 1)
	var i := -1
	for j in ps.inventory.slots.size():
		if ps.inventory.slots[j].get("id", "") == "waterskin_clean":
			i = j
	ps.inventory.slots[i].sips = 1
	check(auth.storage.request_transfer(1, box, false, i), "into the chest")
	check_eq(auth.storage.request_take_all(1, box), 1, "and back out")
	var back := {}
	for s in ps.inventory.slots:
		if s.get("id", "") == "waterskin_clean":
			back = s
	check_eq(back.get("sips", -1), 1, "still only 1 sip left (not refilled for free)")
	_teardown()


func test_unknown_rune_is_not_eaten() -> void:
	await _setup()
	auth._ev_place_station(3, "rune_slab", player.global_position + Vector3(1.5, 0, 0), 0.0)
	ps.inventory.slots[20] = {id = "rune_made_up", count = 1}
	check_eq(auth.request_carve(1, "rune_made_up"), "", "nothing carved")
	check_eq(ps.inventory.count_of("rune_made_up"), 1, "the item is still in the bag")
	_teardown()


func test_smelting_jobs_survive_a_save() -> void:
	await _setup()
	auth._ev_place_station(4, "smelter", player.global_position + Vector3(2, 0, 0), 0.0)
	auth.stations[4].queue_job("copper_ingot", 2, 30.0)
	var snap := auth.snapshot()
	auth.stations[4].jobs.clear()
	auth.stations[4].queue_free()
	auth.stations.erase(4)
	auth.load_snapshot({edits = [], glow = [], drops = [], next_drop = 1, stations = snap.stations})
	check_eq(auth.stations[4].jobs.size(), 1, "the job came back")
	check_eq(auth.stations[4].jobs[0].item, "copper_ingot", "same job")
	_teardown()
