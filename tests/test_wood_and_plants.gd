extends TestCase
## Owner play notes Nov 21: pickaxe on wood (F550), wood sounds (F558), no 45-min message (F552), more fiber (F575), E on vines (F569).

var world: World
var auth: GameAuthority
var glow: GlowField
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup(seed: int, at: Vector3 = Vector3.INF) -> void:
	# The last test's cave is only thrown away at the end of a frame. Two whole caves at once go over Jolt physics'
	# 10240-body limit, so wait until the old one is really gone.
	for k in 2:
		await tree.physics_frame
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

func _first_spot(kind: String) -> Dictionary:
	for id in glow._spots:
		if glow._spots[id].kind == kind:
			return glow._spots[id]
	return {}


## F550: a stone pickaxe cuts a root in 5 hits (was 10); a stone axe still wins with 2.
func test_pickaxe_on_wood_takes_half_as_long() -> void:
	await _setup(42)
	var root := _first_spot(GlowPlacer.ROOT)
	check(not root.is_empty(), "the cave has roots")
	if root.is_empty():
		_teardown()
		return
	player.global_position = root.pos + Vector3(1.2, 0.9, 0.0)
	var first := auth.request_harvest(1, root.id)
	check_eq(first.get("needed", 0), 5, "a stone pickaxe needs 5 hits on a root")
	# F558: the hit says what it hit, so the dwarf plays a wood sound, not the rock "dig" sound.
	check_eq(first.get("kind", ""), GlowPlacer.ROOT, "the hit says it was a root")
	ps.inventory.slots[0] = {id = "axe_stone", count = 1}
	auth.request_select_slot(1, 0)
	var axe: int = auth.request_harvest(1, root.id).get("needed", 0)
	check(axe > 0 and axe < 5, "the axe is still better (%d hits)" % axe)
	_teardown()


## F552: a chopped-out Root Tree gives no "grows back in 45 min" message, just a dull wooden knock.
func test_used_up_tree_says_nothing() -> void:
	await _setup(42)
	var rp := RootPillars.new()
	auth.get_parent().add_child(rp)
	rp.build(world.maker)
	auth.pillars = rp
	var p := rp.pillar(0)
	if p.is_empty():
		check(false, "there's a Root Tree")
		_teardown()
		return
	player.global_position = (p.bottom as Vector3) + Vector3(p.width * 0.15 + 1.0, 0.4, 0.0)
	var got: Array = []
	auth.dig_feedback.connect(func(_peer: int, r: Dictionary) -> void: got.append(r))
	for i in RootPillars.CHOPS + 1:
		auth.request_chop_pillar(1, 0)
	var last: Dictionary = got.back() if not got.is_empty() else {}
	check_eq(last.get("state", ""), "blocked", "one more chop is turned away")
	check_eq(last.get("why", "-"), "", "with no message on screen")
	check_eq(last.get("kind", ""), "root", "and it knocks like wood")
	_teardown()


## F575: ferns and grass give more fiber, and there is more of it to pick.
func test_more_fiber() -> void:
	check(CaveLife.FIBER_PER_PLANT >= 3, "a fern or grass tuft gives 3 fiber (was 1)")
	check(CaveLife.FIBER_PER_VINE >= 2, "a glowing vine gives 2 fiber")
	var tuft: Array = GlowPlacer.KINDS.fiber.count
	check(tuft[0] >= 4, "a fiber tuft gives 4-6 (was 2-3)")


## F569: looking at a glowing vine shows "E to pick", and E asks the host to break that vine.
func test_vines_pick_with_e() -> void:
	var src := FileAccess.get_file_as_string("res://src/player/dwarf.gd")
	check(src.contains("E to pick") and src.contains("pick_strand"), "aiming at a vine offers E to pick")
	var main_src := FileAccess.get_file_as_string("res://src/main.gd")
	check(main_src.contains("ask_break_hanging(\"strand\", str(info.pick_strand))"), "E breaks the vine via the host")

