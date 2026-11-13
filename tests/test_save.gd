extends TestCase
## Saving and loading a world.

const SEED := 4242


## Just enough of "Main" for SaveGame to work with.
class FakeMain extends Node:
	var authority: GameAuthority
	var seed := SEED
	var player_slots := {1: 0}
	var hud = null


func _world(root: Node) -> Array:
	var world := World.new()
	root.add_child(world)
	world.setup(SEED)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	var player := Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.spawn_point
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_visuals = false
	player.add_child(viewer)
	var ps := auth.add_player(1, player)
	for i in 600:
		if world.is_ready_at(player.global_position, 6.0):
			break
		await tree.process_frame
	return [auth, ps, world]


func _clean() -> void:
	for f in [SaveGame.path_for(SEED), SaveGame.path_for(SEED) + ".1", SaveGame.path_for(SEED) + ".2", SaveGame.path_for(SEED) + ".3"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)


func test_save_and_load_a_world() -> void:
	_clean()
	var root_a := Node3D.new()
	tree.root.add_child(root_a)
	var a: Array = await _world(root_a)
	var auth: GameAuthority = a[0]
	var ps: GameAuthority.PlayerState = a[1]
	var world: World = a[2]
	# Change things: dig, place a workbench and a floor, read a clue, carve a rune, fill the bag.
	var hole: Vector3 = ps.node.global_position + Vector3.DOWN * 3.0
	auth._host_dig(hole, 0)
	auth._ev_place_station(1, "workbench", ps.node.global_position + Vector3(-3, 0, 0), 0.0)
	auth._ev_place_station(2, "rune_slab", ps.node.global_position + Vector3(3, 0, 0), 0.0)
	auth.builder._ev_add_piece(1, "floor", "cut_stone", Vector3(10, -20, 10), 0, true)
	auth.world_state.clues.append(world.maker.pois_of("marking")[0].id)
	ps.inventory.add("rune_ochre_m2", 1)
	auth.request_carve(1, "rune_ochre_m2")
	ps.inventory.add("copper_ingot", 17)
	ps.progress.add_xp(5000, "mining")
	ps.fuel = 123.0
	var level: int = ps.progress.level
	var main := FakeMain.new()
	main.authority = auth
	root_a.add_child(main)
	check_eq(SaveGame.save(main), "", "saved")
	root_a.queue_free()
	await tree.process_frame

	var data := SaveGame.read(SaveGame.path_for(SEED))
	check(not data.is_empty(), "the save reads back")
	check_eq(data.seed, SEED, "seed kept")
	var root_b := Node3D.new()
	tree.root.add_child(root_b)
	var b: Array = await _world(root_b)
	var auth2: GameAuthority = b[0]
	var ps2: GameAuthority.PlayerState = b[1]
	var world2: World = b[2]
	auth2.load_snapshot(data.snap)
	SaveGame.apply_player(ps2, data.players[0])
	for i in 60:
		await tree.process_frame
	check(world2.sdf_at(hole) > 0.0, "the hole is still dug")
	check_eq(auth2.stations.size(), 2, "stations are back")
	check_eq(auth2.builder.structure.pieces.size(), 1, "the floor piece is back")
	check_eq(auth2.world_state.clues.size(), 1, "clue remembered")
	check(auth2.rune_slab.carved_runes.has("ochre_m2"), "carved rune remembered")
	check_eq(ps2.inventory.count_of("copper_ingot"), 17, "bag is back")
	check_eq(ps2.progress.level, level, "level is back")
	check_near(ps2.fuel, 123.0, 2.0, "lantern fuel is back (it keeps burning while we wait)")
	root_b.queue_free()
	_clean()


func test_backups_and_broken_saves() -> void:
	_clean()
	var root := Node3D.new()
	tree.root.add_child(root)
	var a: Array = await _world(root)
	var main := FakeMain.new()
	main.authority = a[0]
	root.add_child(main)
	for i in 4:
		SaveGame.save(main)
	for i in [1, 2, 3]:
		check(FileAccess.file_exists("%s.%d" % [SaveGame.path_for(SEED), i]), "backup .%d kept" % i)
	# Break the newest save: loading falls back to a backup.
	var f := FileAccess.open(SaveGame.path_for(SEED), FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	check(SaveGame.read(SaveGame.path_for(SEED)).is_empty(), "a broken save is refused")
	check(not SaveGame.newest().is_empty(), "Continue still works from a backup")
	root.queue_free()
	_clean()
