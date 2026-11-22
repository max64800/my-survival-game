extends TestCase
## The Prow Hall (owner, Nov 22, F656 + F657 + F479): the ninth ruin, a Stonehold castle built into the cave. Its plan,
## where it goes (and the placement rule: nothing the world grows stands inside it), the cave's shape round it (the
## lump, the dip, the rock wall), and rebuilding it in stone.

var world: World
var auth: GameAuthority


func _setup(sd := 42) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(sd)


func _inside(v: Vector3) -> bool:
	return v.x >= RuinProwHall.LO.x and v.x <= RuinProwHall.HI.x and v.z >= RuinProwHall.LO.y and v.z <= RuinProwHall.HI.y


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinProwHall.PLAN_PATH)
	check(not plan.is_empty(), "the Prow Hall's plan file loads")
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		var v := Vector3(p.pos[0], p.pos[1], p.pos[2])
		check(_inside(v) and v.y >= -3.1, "the ruin's %s at %s is inside the ground it keeps clear" % [p.id, v])
		check(Vector2(v.x, v.z).length() <= RuinProwHall.REACH, "the ruin's %s at %s is within its reach" % [p.id, v])
	check(plan.get("chests", []).size() >= 3, "chests to find in it")
	check(plan.pieces.filter(func(p): return p.id == "door").is_empty(), "no doors left (they rotted away)")
	var anchored: Array = plan.pieces.filter(func(p): return p.get("anchor", false))
	check(anchored.size() >= 8, "the lone tower's foundations rest on its rock lump (%d)" % anchored.size())
	for p in anchored:
		var v := Vector3(p.pos[0], p.pos[1], p.pos[2])
		check(RuinProwHall.lump_at(v.x, v.z) > 6.9, "anchored %s at %s is on the lump's flat top" % [p.id, v])


## Nothing in the ruin falls when it is built (its floors hang on their walls; the lone tower stands on its lump).
func test_ruin_stands_up() -> void:
	var plan := RuinTower.load_plan(RuinProwHall.PLAN_PATH)
	var s := Structure.new()
	var uid := 1
	for p in plan.pieces:
		if String(p.id) in RuinTower.RUBBLE:
			continue
		s.add(uid, p.id, p.mat, Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), float(p.pos[1]) < 0.3 or p.get("anchor", false))
		uid += 1
	var fell: Array = s.recompute()
	check_eq(fell.size(), 0, "no piece of the ruin falls")
	for f in fell.slice(0, 5):
		print("PROW_FALLS %s" % [s.pieces[f] if s.pieces.has(f) else f])


func _whole_pieces(plan: Array) -> Array:
	return plan.filter(func(p): return not String(p.id).begins_with("ruin_") and not String(p.id) in RuinTower.RUBBLE \
		and not String(p.id) in Builder.RUIN_DEBRIS)


## The blueprint and the ruin line up piece for piece: nothing whole is torn down.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("stonehold_prow_hall")
	var plan := RuinTower.load_plan(RuinProwHall.PLAN_PATH)
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
	var wood := BlueprintLibrary.make("wooden_prow_hall")
	check(wood != null and wood.pieces.size() == bp.pieces.size(), "a Wooden Prow Hall blueprint, piece for piece")
	check(BlueprintLibrary.REBUILD_ONLY.has("wooden_prow_hall") and BlueprintLibrary.REBUILD_ONLY.has("stonehold_prow_hall"),
		"both learned only by rebuilding the ruin")
	for bx in bp.pieces:
		check(_inside(bx.pos), "the whole castle's %s at %s fits the ground the ruin keeps clear" % [bx.id, bx.pos])


## F657: the cave's shape is the 3D page's: the lump is flat at 7 m under the lone tower, the dip is 3 m deep under
## the bridge, the rock wall rises behind the keep but never touches it or the hall, and the blueprint keeps all of
## that rock (it only digs round the castle itself, so rebuilding never flattens the cave).
func test_cave_shape() -> void:
	var lump := BlueprintLibrary.PROW_LUMP
	check_near(RuinProwHall.lump_at(lump.x, lump.z), 7.0, 0.01, "the lump's top is flat at 7 m")
	check_near(RuinProwHall.lump_at(lump.x + 4.0, lump.z), 7.0, 0.01, "all under the lone tower")
	check(RuinProwHall.lump_at(lump.x, lump.z + 12.0) < 0.5, "and gone 12 m away")
	var deepest := 0.0
	for t in range(0, 10):
		var at := RuinProwHall._b0() + RuinProwHall._d8() * t
		deepest = minf(deepest, RuinProwHall.dip_at(at.x, at.y))
	check(deepest < -2.5, "the dip under the bridge is about 3 m deep (%.1f)" % deepest)
	check_eq(RuinProwHall.dip_at(8.0, 2.0), 0.0, "no dip under the hall")
	var k := BlueprintLibrary.PROW_KEEP
	check(RuinProwHall.wall_at(k.x + 12.0, k.z - 7.0) > 4.0, "a rock wall behind the keep")
	var bp := BlueprintLibrary.make("stonehold_prow_hall")
	var touching := 0
	for p in bp.pieces:
		var b := Pieces.box(p.id, p.pos, p.rot).grow(0.3)
		for c in [b.position, b.end, Vector3(b.position.x, 0, b.end.z), Vector3(b.end.x, 0, b.position.z)]:
			if p.pos.y + 0.1 < RuinProwHall.wall_at(c.x, c.z):
				touching += 1
	check_eq(touching, 0, "the rock wall never reaches into the castle")
	var sx := int(bp.size.x)
	var sz := int(bp.size.z)
	var air := 0
	for v in bp.air:
		air += int(v)
	check(air < bp.air.size() * 0.75, "the blueprint only digs round the castle (%d of %d cells)" % [air, bp.air.size()])
	var pts := RuinProwHall.carve_points(Vector3.ZERO, 0)
	var into := 0
	for c in pts:
		if c.y - RuinTower.CARVE_RADIUS < RuinProwHall.rock_at(c.x, c.z) - 0.31:
			into += 1
	check_eq(into, 0, "the ruin never digs into its lump or wall")
	check(sx > 0 and sz > 0 and pts.size() > 1000, "it digs its space (%d digs)" % pts.size())


## Where it goes, on a few worlds: a big cavern of its own, a fair walk out, found quickly, and the placement rule
## (owner, Nov 17): no stone column inside it and its whole ground (the castle, the lone tower, the yard) kept clear.
func test_spot_keeps_clear_of_what_the_world_grows() -> void:
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		var t0 := Time.get_ticks_msec()
		RuinProwHall.pick(c)  # (only timed: its own spot is reserved now)
		var ms := Time.get_ticks_msec() - t0
		var spot: Dictionary = c.prow_hall_spot
		check(not spot.is_empty(), "seed %d: a cavern for the Prow Hall is found" % sd)
		if spot.is_empty():
			continue
		check(ms < 4000, "seed %d: finding the spot takes under 4 s (%d ms)" % [sd, ms])
		var taken := [RuinOutpost.pick_room(c), RuinBrewhall.pick_room(c), int(c.spire_spot.get("room", -1)), int(c.manor_spot.get("room", -1))]
		check(not spot.room in taken, "seed %d: not another ruin's cavern" % sd)
		var d := Vector2(spot.pos.x - c.cavern_spawn.x, spot.pos.z - c.cavern_spawn.z).length()
		check(d > 80.0, "seed %d: a fair walk from the start (%.0f m)" % [sd, d])
		var basis := Basis(Vector3.UP, int(spot.turn) * PI / 2.0)
		var bad := 0
		for g: Vector2 in RuinProwHall.ground():
			var at: Vector3 = spot.pos + basis * Vector3(g.x, 0.3, g.y)
			if c._in_column(at, 1.0) or not c.is_reserved(at):
				bad += 1
		check_eq(bad, 0, "seed %d: no column in the Prow Hall, all of its ground kept clear" % sd)
		if sd == 42:  # (a new world takes a few seconds: once is enough)
			check_eq(CaveMaker.new(sd).prow_hall_spot, spot, "seed %d: always the same spot" % sd)


## A test world with the Prow Hall built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_prow() -> int:
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
	auth.world_state["prow_hall"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinProwHall.new(auth)
	auth.add_child(job)
	await tree.process_frame
	# Load its rock (the test world has no camera): its digging and the rock it grows need it.
	var eye := Node3D.new()
	root.add_child(eye)
	eye.global_position = job.origin + Vector3(0, 6, 0)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 72
	viewer.requires_visuals = false
	eye.add_child(viewer)
	for i in 4000:  # (slower in the full suite; the rock checks below tell if it never loaded)
		if world.is_ready_at(job.origin + Vector3(0, 6, 0), 36.0):
			break
		await tree.process_frame
	if not world.is_ready_at(job.origin + Vector3(0, 6, 0), 36.0):
		print("PROW_TEST rock not fully loaded yet, going on")
	job._state = "carve"  # (no meshes in the test world: start digging now)
	for i in 8000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


func test_rebuild_the_prow_hall_in_stone() -> void:
	var box: int = await _build_prow()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the Prow Hall has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var o := RuinProwHall.built_origin
	var basis := Basis(Vector3.UP, RuinProwHall.built_turn * PI / 2.0)
	# The cave's shape (F657): rock on the lump's top and in the wall, open air over the yard.
	var lump := BlueprintLibrary.PROW_LUMP
	check(world.sdf_at(o + basis * Vector3(lump.x + 2.0, 6.0, lump.z)) < 0.0, "rock in the lump under the lone tower")
	check(world.sdf_at(o + basis * Vector3(lump.x + 2.0, 8.5, lump.z)) > 0.0, "air over its top")
	check(world.sdf_at(o + basis * Vector3(8.0, 2.5, 18.0)) > 0.0, "an open yard in front of the prow")
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", "")], ["wooden_prow_hall", "stonehold_prow_hall", "cut_stone"], "its chest rebuilds the Prow Hall")
	auth.storage.put(box, "cut_stone", 5)
	var b: Builder = auth.builder
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	for k in 40000:
		if not b.sites.has(box):
			break
		if k % 25 == 0:
			var left := []
			for i in b.sites[box].plan.size():
				if not b.sites[box].plan[i].built:
					left.append(i)
			var short := Builder.missing_for(b.sites[box].plan, left, auth.storage.get_box(box).inv)
			for item in short:
				auth.storage.put(box, item, mini(int(short[item]), 400))
		b._site_ticks += 1
		b._tick_sites()
	if b.sites.has(box):  # (what holds it up, to fix)
		var inv := basis.inverse()
		var n := 0
		for p in b.sites[box].plan:
			if not p.built and n < 6:
				n += 1
				print("PROW_STUCK %s %s at %s overlap=%s rock='%s'" % [p.piece, p.family, inv * (p.pos - o),
					b.structure.overlapping(p.piece, p.pos, p.rot).size(), Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_prow_hall") and known.has("stonehold_prow_hall"), "rebuilt in stone: you learn both blueprints")
	check(world.sdf_at(o + basis * Vector3(lump.x + 2.0, 6.0, lump.z)) < 0.0, "the lump is still there after rebuilding")
	check(world.sdf_at(o + basis * Vector3(18.0, 6.0, -19.0)) < 0.0, "and the rock wall behind the keep")
	# The placement rule: every piece of the rebuilt castle stands on ground the world keeps clear.
	var outside := 0
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(o) < RuinProwHall.REACH + 2.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - o])
	check_eq(outside, 0, "every piece of the rebuilt castle stands on ground the world keeps clear")
	world.get_parent().queue_free()
