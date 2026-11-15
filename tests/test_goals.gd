extends TestCase
## "Next steps" (F103): the list starts at the beginning and ticks off as you go.


func test_next_steps_tick_off() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var stations := Node3D.new()
	root.add_child(stations)
	var drops := Node3D.new()
	root.add_child(drops)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	var player := Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	var ps := auth.add_player(1, player)
	ps.seen.clear()
	var steps := Goals.next_steps(ps, auth)
	check_eq(steps.size(), Goals.SHOWN, "three steps on screen")
	check(steps[0].contains("root"), "it starts with rootwood")
	for id in ["rootwood", "stone", "pickaxe_stone"]:
		ps.seen[id] = true
	check(Goals.next_steps(ps, auth)[0].contains("Workbench"), "then the Workbench")
	auth._ev_place_station(5, "workbench", player.global_position + Vector3(2, 0, 0), 0.0)
	ps.seen["rope"] = true
	check(Goals.next_steps(ps, auth)[0].contains("Stone Sword"), "then the stone sword (F103)")
	check(Goals.next_steps(ps, auth)[1].contains("Shield"), "and a shield")
	for s in Goals.STEPS:
		ps.seen[s[0]] = true
	auth._ev_place_station(6, "masonry_table", player.global_position + Vector3(-2, 0, 0), 0.0)
	auth._ev_place_station(7, "chisel_rack", player.global_position + Vector3(-3.5, 0, 0), 0.0)  # Mason's Table level 2: brick
	for i in 4:
		auth.builder.structure.add(100 + i, "floor", "cut_stone", Vector3(i * 2, 0, 0), 0, true)
	for poi in world.maker.pois_of("marking", "mossy"):
		auth.world_state.clues.append(poi.id)
	auth.world_state.bosses_dead.append("orrumhal")
	check(Goals.next_steps(ps, auth).is_empty(), "all done: the list disappears")
	root.queue_free()


## F96: the placing preview uses the host's rules: floors yes, walls only for wall stations, not on top of another.
func test_placing_preview_rules() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations := Node3D.new()
	root.add_child(stations)
	var auth := GameAuthority.new()
	auth.stations_root = stations
	root.add_child(auth)
	var me := Vector3.ZERO
	var floor_spot := PlaceGhost.where("workbench", Vector3(2, 0, 0), Vector3.UP, 0.0, me, auth)
	check(floor_spot.ok, "a workbench fits on the floor nearby")
	check(not PlaceGhost.where("workbench", Vector3(2, 1, 0), Vector3.LEFT, 0.0, me, auth).ok, "not on a wall")
	check(PlaceGhost.where("tool_rack", Vector3(2, 1, 0), Vector3.LEFT, 0.0, me, auth).ok, "the tool rack goes on a wall")
	check(not PlaceGhost.where("workbench", Vector3(20, 0, 0), Vector3.UP, 0.0, me, auth).ok, "not too far away")
	auth._ev_place_station(1, "campfire", Vector3(2.5, 0, 0), 0.0)
	check(not PlaceGhost.where("workbench", Vector3(2, 0, 0), Vector3.UP, 0.0, me, auth).ok, "not on top of another station")
	root.queue_free()
