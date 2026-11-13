extends TestCase
## Building and cave-ins in the real cave, through the referee.

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
	var viewer := VoxelViewer.new()
	viewer.view_distance = 64
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 600:
		if world.is_ready_at(player.global_position, 8.0):
			break
		await tree.process_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


## A spot on the floor a few meters from the player, snapped like the build ghost does it.
func _floor_spot(piece: String, dx: float) -> Dictionary:
	var p := world.maker.find_floor(player.global_position.x + dx, player.global_position.z, player.global_position.y + 2.0)
	return Pieces.snap(piece, p, Vector3.UP, 0.0, 0)


func test_needs_a_workbench_and_materials() -> void:
	await _setup()
	var s := _floor_spot("floor", 3.0)
	check_eq(auth.builder.problem(ps, "floor", "plank_root", s.pos, s.rot), "Needs a Workbench within 20 m", "no workbench yet")
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	check(auth.builder.problem(ps, "floor", "plank_root", s.pos, s.rot).begins_with("Needs 4"), "no planks yet")
	ps.inventory.add("plank_root", 10)
	check_eq(auth.builder.request_place(1, "floor", "plank_root", s.pos, s.rot), "", "placed")
	check_eq(ps.inventory.count_of("plank_root"), 6, "4 planks used")
	check_eq(auth.builder.structure.pieces.size(), 1, "one piece")
	check(auth.builder.structure.pieces.values()[0].anchored, "a floor on the cave floor touches rock")
	check_eq(auth.builder.request_place(1, "floor", "plank_root", s.pos, s.rot), "Something is already there", "can't double-place")
	_teardown()


func test_remove_gives_everything_back() -> void:
	await _setup()
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	ps.inventory.add("cut_stone", 4)
	var s := _floor_spot("floor", 3.0)
	auth.builder.request_place(1, "floor", "cut_stone", s.pos, s.rot)
	var uid: int = auth.builder.structure.pieces.keys()[0]
	check(auth.builder.request_remove(1, uid), "removed")
	check_eq(ps.inventory.count_of("cut_stone"), 4, "100% back")
	check(auth.builder.structure.pieces.is_empty(), "gone")
	_teardown()


func test_cant_build_inside_rock() -> void:
	await _setup()
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	ps.inventory.add("plank_root", 10)
	var s := _floor_spot("wall", 3.0)
	check_eq(auth.builder.problem(ps, "wall", "plank_root", s.pos + Vector3.DOWN * 3.0, s.rot), "Inside rock", "buried wall refused")
	_teardown()


func test_normal_digging_no_cave_in() -> void:
	await _setup()
	var below := player.global_position + Vector3.DOWN * 3.0
	world.apply_dig(below, 1.35)
	var box := CaveIns.box_for(below)
	for i in 900:
		if world.copy_area(box[0], box[1]) != null:
			break
		await tree.process_frame
	check(world.copy_area(box[0], box[1]) != null, "the area around the dig loaded")
	var t := Time.get_ticks_usec()
	var falls := auth.builder._run_check(below, 1.35)
	print("        (real-cave check: %.1f ms)" % ((Time.get_ticks_usec() - t) / 1000.0))
	check(falls.is_empty(), "digging the floor doesn't make rock fall")
	_teardown()


func test_cave_in_removes_rock_and_drops_rubble() -> void:
	await _setup()
	var spot := player.global_position + Vector3(0, -4, 0)
	var pts := PackedVector3Array()
	for x in 2:
		for y in 2:
			for z in 2:
				pts.append((spot + Vector3(x, y, z)).round())
	check(world.sdf_at(spot) < 0.0, "rock there before")
	auth.builder._ev_cave_in(pts)
	check(world.sdf_at(spot) > 0.0, "air after the cave-in")
	check_eq(auth.builder.fall_log.size(), 1, "logged for late joiners")
	check(auth.drop_count() >= 1, "rubble dropped some items")
	_teardown()


func test_mine_prop_marks_support() -> void:
	await _setup()
	auth.builder._ev_add_piece(5, "mine_prop", "plank_root", Vector3(0, 0, 0), 0, true)
	var sp := auth.builder.support_points()
	check_eq(sp.size(), 3, "a prop holds rock at 3 points on its top")
	check(sp[0].y > 3.0, "points are above the prop (it's 3 m tall)")
	_teardown()
