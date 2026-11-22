extends TestCase
## F726 (owner, Nov 22): furniture showed only as a box while placing and turned only in 90° steps.
## Now it turns 5° a tap like the crafting bench, goes where you aim, and its ghost is the real model.


func test_furniture_turns_in_5_degree_steps() -> void:
	check(Pieces.turns_freely("table"), "a table turns freely")
	check(Pieces.turns_freely("furn_stool"), "a stool turns freely")
	check(not Pieces.turns_freely("wall"), "walls stay on the grid")
	check(not Pieces.turns_freely("bartizan"), "a corner turret stays on the grid")
	var r := Pieces.rot_from_fives(7)
	check_near(Pieces.yaw_of(r), deg_to_rad(35.0), 0.001, "7 steps = 35°")
	check(Pieces.valid_rot(r), "the host accepts a 5° turn")
	# Old numbers keep their meaning (saves, blueprints, ruins).
	check_eq(Pieces.rot_from_fives(18), 1, "90° is still stored as a quarter turn")
	check_eq(Pieces.rot_from_fives(6), Pieces.FINE_ROT + 1, "30° is still stored as a 30° step")
	check_near(Pieces.yaw_of(Pieces.FINE_ROT + 2), deg_to_rad(60.0), 0.001, "a 30° step still means 30°")
	check_eq(Pieces.add_rot(Pieces.rot_from_fives(7), 1), Pieces.rot_from_fives(25), "turning a turned table by a quarter")
	check_eq(Pieces.turned_size("table", 1), Vector3(1.0, 0.9, 2.0), "a quarter-turned table swaps width and depth")


func test_furniture_snaps_where_you_aim_with_its_turn() -> void:
	var t := Pieces.snap("table", Vector3(3.23, 0.0, 1.41), Vector3.UP, 0.0, 7)
	check_near(t.pos.x, 3.2, 0.001, "10 cm steps across")
	check_near(t.pos.z, 1.4, 0.001, "10 cm steps along")
	check_near(Pieces.yaw_of(t.rot), deg_to_rad(35.0), 0.001, "it keeps its 35° turn")
	var box := Pieces.box("table", t.pos, t.rot)
	check(box.size.x > 2.0 * cos(deg_to_rad(35.0)), "its outline is turned too (the room it takes)")
	var w := Pieces.snap("wall", Vector3(3.23, 0.0, 1.41), Vector3.UP, 0.0, 1)
	check_eq(w.rot, 1, "walls still take quarter turns")


func test_build_mode_turns_furniture_5_degrees_and_keeps_facing() -> void:
	var bm := BuildMode.new()
	tree.root.add_child(bm)
	bm.choose("table", "plank_root")
	bm.rot = 0
	bm._step(1)
	check_eq(bm.rot, 1, "Q turns a table one 5° step")
	bm._step(-1)
	bm._step(-1)
	check_eq(bm.rot, Pieces.FREE_STEPS - 1, "and back round the other way")
	bm.rot = 18  # 90°
	bm.choose("wall", "plank_root")
	check_eq(bm.rot, 1, "a wall picked next faces the same way (one quarter)")
	bm.choose("furn_stool", "plank_root")
	check_eq(bm.rot, 18, "and back to furniture: 90° again")
	var steps := 0
	var t := 0.0
	while t < 1.0 + PlaceGhost.HOLD_DELAY:  # held: smooth like a station, 60° a second
		steps += BuildMode.held_steps(t, t + 1.0 / 60.0, BuildMode.FREE_HOLD_DELAY, BuildMode.FREE_REPEAT)
		t += 1.0 / 60.0
	check(steps >= 11 and steps <= 13, "about 12 steps (60°) in a second of holding (%d)" % steps)
	bm.queue_free()


func test_furniture_ghost_shows_its_real_model() -> void:
	var ids := ["table", "bench", "chair", "furn_stool", "furn_table_long"]
	var shown := 0
	for id in ids:
		var made := PieceNode.forged_mesh(id, "plank_root")
		if made == null:
			continue  # no model for it yet: the code shape is all there is
		var g := PieceNode.new()
		g.ghost = true
		g.piece = id
		g.family = "plank_root"
		tree.root.add_child(g)
		check(g._look.mesh == made, "%s: the ghost is its real model, not a box" % id)
		shown += 1
		g.free()
	check(shown > 0, "at least one furniture model to check")
