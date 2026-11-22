extends TestCase
## The Hearth Manor (owner, Nov 22, F479): the seventh ruin, a big clay-brick manor house. Its plan, where it goes (and
## the placement rule: nothing the world grows stands inside it), and rebuilding it in brick.

var world: World
var auth: GameAuthority


func _setup(sd := 42) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(sd)


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinManor.PLAN_PATH)
	check(not plan.is_empty(), "the manor's plan file loads")
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		var v := Vector3(p.pos[0], p.pos[1], p.pos[2])
		check(absf(v.x) <= RuinManor.HALF_X and v.z >= -RuinManor.BACK and v.z <= RuinManor.FRONT - 2.0,
			"the ruin's %s at %s is inside the space it digs and keeps clear" % [p.id, v])
	check(plan.get("chests", []).size() >= 3, "chests to find in it")


func _whole_pieces(plan: Array) -> Array:
	return plan.filter(func(p): return not String(p.id).begins_with("ruin_") and not String(p.id) in RuinTower.RUBBLE \
		and not String(p.id) in Builder.RUIN_DEBRIS)


## The blueprint and the ruin line up piece for piece: nothing whole is torn down.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("hearthbrick_manor")
	var plan := RuinTower.load_plan(RuinManor.PLAN_PATH)
	var off := 0
	for q in _whole_pieces(plan.pieces):
		var qp := Vector3(q.pos[0], q.pos[1], q.pos[2])
		var found := false
		for p in bp.pieces:
			if p.id == q.id and int(p.rot) == int(q.rot) and (p.pos as Vector3).distance_to(qp) < 0.05:
				found = true
				break
		if not found:
			off += 1
			if off <= 3:
				check(false, "the ruin's %s at %s is in the blueprint" % [q.id, qp])
	check_eq(off, 0, "every whole piece of the ruin is in the blueprint")
	var wood := BlueprintLibrary.make("wooden_manor")
	check(wood != null and wood.pieces.size() == bp.pieces.size(), "a Wooden Manor blueprint, piece for piece")
	check(BlueprintLibrary.REBUILD_ONLY.has("wooden_manor") and BlueprintLibrary.REBUILD_ONLY.has("hearthbrick_manor"),
		"both learned only by rebuilding the ruin")
	for bx in bp.pieces:
		check(absf(bx.pos.x) <= RuinManor.HALF_X and bx.pos.z >= -RuinManor.BACK and bx.pos.z <= RuinManor.FRONT - 2.0,
			"the whole manor's %s at %s fits the space the ruin keeps clear" % [bx.id, bx.pos])


## Where it goes, on a few worlds: a big cavern of its own, a fair walk out, found quickly, and the placement rule
## (owner, Nov 17): no stone column inside it and its whole ground (corners, terrace steps, chest) kept clear.
func test_spot_keeps_clear_of_what_the_world_grows() -> void:
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		var t0 := Time.get_ticks_msec()
		var again := RuinManor.pick(c, 13.5)
		var ms := Time.get_ticks_msec() - t0
		var spot: Dictionary = c.manor_spot
		check(not spot.is_empty(), "seed %d: a cavern for the manor is found" % sd)
		if spot.is_empty():
			continue
		check_eq(again, spot, "seed %d: always the same spot" % sd)
		check(ms < 4000, "seed %d: finding the spot takes under 4 s (%d ms)" % [sd, ms])
		var taken := [RuinOutpost.pick_room(c), RuinBrewhall.pick_room(c), int(c.spire_spot.get("room", -1))]
		check(not spot.room in taken, "seed %d: not the outpost's, the Brewhall's or the Spire's cavern" % sd)
		var d := Vector2(spot.pos.x - c.cavern_spawn.x, spot.pos.z - c.cavern_spawn.z).length()
		check(d > 60.0, "seed %d: a fair walk from the start (%.0f m)" % [sd, d])
		var basis := Basis(Vector3.UP, int(spot.turn) * PI / 2.0)
		var bad := 0
		for x in range(-18, 19, 3):
			for z in range(-8, 11, 3):
				var at: Vector3 = spot.pos + basis * Vector3(x, 0.3, z)
				if c._in_column(at, 1.0) or not c.is_reserved(at):
					bad += 1
		check_eq(bad, 0, "seed %d: no column in the manor, all of its ground kept clear" % sd)


## A test world with the manor built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_manor() -> int:
	_setup()
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	auth.stations_root = Node3D.new()
	var root := world.get_parent()
	root.add_child(auth.drops_root)
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	me.global_position = world.maker.cavern_spawn
	auth.add_player(1, me)
	auth.world_state["manor"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinManor.new(auth)
	auth.add_child(job)
	await tree.process_frame
	job._state = "carve"  # (no camera in the test world to load rock around)
	for i in 4000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


func test_rebuild_the_manor_in_brick() -> void:
	var box: int = await _build_manor()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the manor has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", "")], ["wooden_manor", "hearthbrick_manor", "clay_brick"], "its chest rebuilds the manor")
	auth.storage.put(box, "clay_brick", 5)
	var b: Builder = auth.builder
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	for k in 12000:
		if not b.sites.has(box):
			break
		if k % 25 == 0:
			var left := []
			for i in b.sites[box].plan.size():
				if not b.sites[box].plan[i].built:
					left.append(i)
			var short := Builder.missing_for(b.sites[box].plan, left, auth.storage.get_box(box).inv)
			for item in short:
				auth.storage.put(box, item, mini(int(short[item]), 150))
		b._site_ticks += 1
		b._tick_sites()
	if b.sites.has(box):  # (what holds it up, to fix)
		var inv := Basis(Vector3.UP, RuinManor.built_turn * PI / 2.0).inverse()
		var n := 0
		for p in b.sites[box].plan:
			if not p.built and n < 6:
				n += 1
				print("MANOR_STUCK %s %s at %s overlap=%s rock='%s'" % [p.piece, p.family, inv * (p.pos - RuinManor.built_origin),
					b.structure.overlapping(p.piece, p.pos, p.rot).size(), Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_manor") and known.has("hearthbrick_manor"), "rebuilt in brick: you learn both blueprints")
	# The placement rule: every piece of the rebuilt manor stands on ground the world keeps clear.
	var outside := 0
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(RuinManor.built_origin) < 24.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - RuinManor.built_origin])
	check_eq(outside, 0, "every piece of the rebuilt manor stands on ground the world keeps clear")
	world.get_parent().queue_free()
