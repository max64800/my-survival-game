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
	for i in 4:
		auth.builder.structure.add(100 + i, "floor", "cut_stone", Vector3(i * 2, 0, 0), 0, true)
	check(Goals.next_steps(ps, auth).is_empty(), "all done: the list disappears")
	root.queue_free()
