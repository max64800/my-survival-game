extends TestCase
## F727 (owner, Nov 22): "the bed is the spawn point, one per person". Each player owns one bed: their wake-up spot.

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
	var viewer := VoxelViewer.new()
	viewer.view_distance = 64
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 600:
		if world.is_ready_at(player.global_position, 8.0):
			break
		await tree.process_frame
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	ps.inventory.add("plank_root", 80)
	ps.inventory.add("fiber", 40)


func _teardown() -> void:
	auth.get_parent().queue_free()


## A flat, open floor spot about `dx` m from the player for this piece.
func _floor_spot(piece: String, dx: float) -> Dictionary:
	var first := {}
	for off in [Vector2(dx, 0), Vector2(-dx, 0), Vector2(0, dx), Vector2(0, -dx), Vector2(dx, dx), Vector2(-dx, -dx), Vector2(dx, -dx), Vector2(-dx, dx)]:
		var p := world.maker.find_floor(player.global_position.x + off.x, player.global_position.z + off.y, player.global_position.y + 2.0)
		var s := Pieces.snap(piece, p, Vector3.UP, 0.0, 0)
		if first.is_empty():
			first = s
		if Pieces.rock_problem(piece, s.pos, s.rot, world.sdf_at) == "" and auth.builder.problem(ps, piece, "plank_root", s.pos, s.rot) == "":
			return s
	return first


func _uid_of(piece: String) -> Array:
	return auth.builder.structure.pieces.keys().filter(func(k): return auth.builder.structure.pieces[k].piece == piece)


func test_one_bed_per_person_and_it_moves() -> void:
	await _setup()
	var a := _floor_spot("furn_bed_1", 3.0)
	check_eq(auth.builder.request_place(1, "furn_bed_1", "plank_root", a.pos, a.rot), "", "first bed placed")
	var first := "p%d" % _uid_of("furn_bed_1")[0]
	check_eq(auth.bed_owners.get(first, -1), 0, "it's the host's bed")
	check(ps.bed_pos.distance_to(a.pos) < 1.5, "you wake up in it")
	check_eq(auth.bed_label(first, "Rootwood Bed"), "Your bed", "looking at it says Your bed")
	var b := _floor_spot("furn_bed_2", 6.0)
	check_eq(auth.builder.request_place(1, "furn_bed_2", "plank_root", b.pos, b.rot), "", "second bed placed")
	var second := "p%d" % _uid_of("furn_bed_2")[0]
	check_eq(auth.bed_owners.get(second, -1), 0, "the new bed is yours")
	check(not auth.bed_owners.has(first), "the old bed is a plain bed now")
	check(ps.bed_pos.distance_to(b.pos) < 1.5, "you wake up in the newest bed")
	check(auth.bed_label(first, "Rootwood Bed").contains("E to make it your bed"), "a plain bed offers E")
	check_eq(auth.request_claim_bed(1, first), "", "E on the plain bed makes it yours again")
	check(ps.bed_pos.distance_to(a.pos) < 1.5, "and moves your wake-up spot back")
	check(not auth.bed_owners.has(second), "one per person: the other one is plain again")
	_teardown()


func test_a_friends_bed_isnt_yours() -> void:
	await _setup()
	var a := _floor_spot("furn_bed_1", 3.0)
	auth.builder.request_place(1, "furn_bed_1", "plank_root", a.pos, a.rot)
	var key := "p%d" % _uid_of("furn_bed_1")[0]
	auth._ev_bed_owner(key, 2)  # pretend Friend 2 owns it
	ps.bed_pos = Vector3.INF
	check(auth.request_claim_bed(1, key).contains("Friend 2's bed"), "can't take a friend's bed")
	check(not ps.bed_pos.is_finite(), "your wake-up spot didn't move")
	check_eq(auth.bed_label(key, "Rootwood Bed"), "Friend 2's bed", "looking at it says whose it is")
	_teardown()


func test_bed_taken_down_sends_you_to_the_world_start() -> void:
	await _setup()
	var a := _floor_spot("furn_bed_1", 3.0)
	auth.builder.request_place(1, "furn_bed_1", "plank_root", a.pos, a.rot)
	var uid: int = _uid_of("furn_bed_1")[0]
	var told := []
	auth.hud_message.connect(func(t): told.append(t))
	auth.builder.request_remove(1, uid, true)
	check(not ps.bed_pos.is_finite(), "bed broken: back to the world start")
	check(auth.bed_owners.is_empty(), "nobody owns a gone bed")
	check(told.any(func(t): return String(t).contains("bed is gone")), "you're told: %s" % [told])
	# The Bed station works the same way.
	auth._ev_place_station(7, "bed", player.global_position + Vector3(0, 0, 3), 0.0)
	auth.set_bed(1, "s7")
	check_eq(auth.bed_owners.get("s7", -1), 0, "a Bed station is yours too")
	check(ps.bed_pos.is_finite(), "you wake up there")
	check_eq(auth.snapshot().beds, {"s7": 0}, "saved with the world")
	auth.request_pickup_station(1, 7)
	check(not ps.bed_pos.is_finite(), "picked up: back to the world start")
	_teardown()


func test_owners_load_from_a_save() -> void:
	await _setup()
	auth.load_snapshot({glow = [], edits = [], drops = [], next_drop = 0, beds = {"p5": 1, "s3": 0}})
	check_eq(auth.bed_owners, {"p5": 1, "s3": 0}, "whose bed is whose comes back")
	_teardown()
