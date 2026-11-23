extends TestCase
## The Prow Hall (owner, Nov 22, F656 + F657 + F479): the ninth ruin, a Stonehold castle built into the cave. Its plan,
## where it goes (and the placement rule: nothing the world grows stands inside it), the cave's shape round it (the
## dip, and from layout 19 a natural cave with no rock grown round it), and rebuilding it in stone.

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
	# F657 (owner, Nov 23): no rock lump grown under the lone tower any more; it stands on the cave floor
	var anchored: Array = plan.pieces.filter(func(p): return p.get("anchor", false))
	check_eq(anchored.size(), 0, "nothing rests on a grown rock lump (the lone tower stands on the cave floor)")
	var lone := BlueprintLibrary.PROW_LONE
	var low := 99.0
	for p in plan.pieces:
		if Vector2(p.pos[0] - lone.x, p.pos[2] - lone.z).length() < 5.0:
			low = minf(low, float(p.pos[1]))
	check(low < 0.3, "the lone tower's lowest piece is on the floor (%.2f m)" % low)


## Nothing in the ruin falls when it is built (its floors hang on their walls; the lone tower stands on the floor).
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
	# (F820: the wood version drops the battlement corners that became whole railings sticking out of the corners)
	var corners := 0
	for p in bp.pieces:
		if p.id == "battlement_corner":
			corners += 1
	check(wood != null and wood.pieces.size() <= bp.pieces.size() and wood.pieces.size() >= bp.pieces.size() - corners,
		"a Wooden Prow Hall blueprint, piece for piece (bar the corners: %d of %d)" % [wood.pieces.size() if wood else 0, bp.pieces.size()])
	check(BlueprintLibrary.REBUILD_ONLY.has("wooden_prow_hall") and BlueprintLibrary.REBUILD_ONLY.has("stonehold_prow_hall"),
		"both learned only by rebuilding the ruin")
	for bx in bp.pieces:
		check(_inside(bx.pos), "the whole castle's %s at %s fits the ground the ruin keeps clear" % [bx.id, bx.pos])


## The owner's Nov 23 play test (F819 to F822) in the ruin itself: no railing end out past its floor, a stair hole
## over every stair and no chest at a stair's top, no battlement indoors, and nothing of the old, lower plan left.
func test_play_test_fixes_in_the_ruin() -> void:
	var lib := preload("res://tests/test_blueprint_library.gd")
	var plan := RuinTower.load_plan(RuinProwHall.PLAN_PATH)
	var ps := []
	for q in plan.pieces:
		ps.append({id = q.id, mat = q.mat, pos = Vector3(q.pos[0], q.pos[1], q.pos[2]), rot = int(q.rot)})
	for msg in lib.railing_ends_poking_out(ps) + lib.stairs_under_a_ceiling(ps) + lib.merlons_indoors(ps, BlueprintLibrary.WOOD):
		check(false, "the ruin: %s" % msg)
	var blocked := 0
	for c in plan.chests:
		var cv := Vector3(c.pos[0], c.pos[1], c.pos[2])
		for p in ps:
			if p.id == "stairs":
				var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
				var top: Vector3 = p.pos + up * 2.0 + Vector3.UP * 2.0
				if Vector2(cv.x - top.x, cv.z - top.z).length() < 1.5 and absf(cv.y - top.y) < 0.6:
					blocked += 1
					check(false, "the %s at %s sits at the top of the stairs at %s" % [c.kind, cv, p.pos])
	check_eq(blocked, 0, "no chest blocks a stair's top")


## F657: the cave's shape: the dip is 3 m deep under the bridge; in old worlds (before layout 19) the rock wall rises
## behind the keep but never touches it or the hall, and the blueprint keeps all of that rock (it only digs round the
## castle itself, so rebuilding never flattens the cave). No rock lump under the lone tower in any world (Nov 23).
func test_cave_shape() -> void:
	var lone := BlueprintLibrary.PROW_LONE
	check_eq(RuinProwHall.rock_at(lone.x, lone.z), 0.0, "no rock lump grown under the lone tower")
	check_eq(RuinProwHall.rock_at(12.0, -19.0, false), 0.0, "a natural cave grows no rock at all")
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
	var dip := 0
	for c in pts:
		var r := RuinProwHall.rock_at(c.x, c.z)
		if r > 0.0 and c.y - RuinTower.CARVE_RADIUS < r - 0.31:
			into += 1
		if c.y < -1.0:
			dip += 1
	# (before Nov 23 the lump check stopped the dip being dug at all, so the rubble fallen into it lay buried)
	check(dip >= 8, "it digs the dip under the bridge (%d digs below the floor)" % dip)
	check_eq(into, 0, "the ruin never digs into the wall it grows (old worlds)")
	check(sx > 0 and sz > 0 and pts.size() > 1000, "it digs its space (%d digs)" % pts.size())
	check(RuinProwHall.carve_points(Vector3.ZERO, 0, false).size() >= pts.size(), "in a natural cave it digs all its air")


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
		# F657 (owner, Nov 23: "use the caves that already exist"): a natural cave that fits, the keep's back in the cave's
		# own rock, and the way in open (10 m in front of the doors, F350).
		check(RuinProwHall.natural(c), "seed %d: new worlds put it in a natural cave" % sd)
		var back := RuinProwHall.back_rock(c, spot.pos, basis)
		print("PROW_NATURAL seed %d: back rock %d of %d, turn %d" % [sd, back, RuinProwHall.BACK_ALL, spot.turn])
		check(back * 2 >= RuinProwHall.BACK_ALL, "seed %d: the keep's back is set into the cave's own rock (%d of %d)" % [sd, back, RuinProwHall.BACK_ALL])
		var front := RuinProwHall.front_state(c, spot.pos, basis)
		print("PROW_NATURAL seed %d: the way in is %s" % [sd, ["open", "dug out", "a drop"][front]])
		check(front < 2, "seed %d: no drop in the 10 m in front of the doors (the yard is dug out that far)" % sd)
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
	# The cave's shape (F657, owner Nov 23): a natural cave, no rock placed round it at all, open air over the yard.
	check(RuinProwHall.natural(world.maker), "a new world puts it in a natural cave")
	var job: RuinProwHall = null
	for n in auth.get_children():
		if n is RuinProwHall:
			job = n
	check(job != null and job._grown == 0 and not job.has_meta("filled"), "no placed rock lump or wall round the Prow Hall")
	var lone := BlueprintLibrary.PROW_LONE
	check(world.sdf_at(o + basis * Vector3(lone.x + 2.0, 6.0, lone.z)) > 0.0, "air where the old rock lump stood")
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
		var plan: Array = b.sites[box].plan
		var way := {}
		for i in plan.size():
			var q: Dictionary = plan[i]
			if not q.built and (b.structure.overlaps(q.piece, q.pos, q.rot) or Pieces.rock_problem(q.piece, q.pos, q.rot, auth.world.sdf_at) != ""):
				way[i] = true
		var steps := Builder.site_steps(plan, way)
		print("PROW_STUCK band %s of %s" % [steps.current, steps.count])
		for i in plan.size():
			var p: Dictionary = plan[i]
			if not p.built and n < 20:
				n += 1
				var anch := Pieces.touches_rock(p.piece, p.pos, p.rot, auth.world.sdf_at, p.family)
				var hits := []
				for uid in b.structure.overlapping(p.piece, p.pos, p.rot):
					hits.append("%s@%s" % [b.structure.pieces[uid].piece, inv * (b.structure.pieces[uid].pos - o)])
				print("PROW_STUCK %s %s at %s band=%s overlaps=%s %s rock='%s' stab=%.2f" % [p.piece, p.family, inv * (p.pos - o),
					steps.band_of[i], b.structure.overlaps(p.piece, p.pos, p.rot), hits, Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at),
					b.structure.preview_stability(p.piece, p.family, p.pos, p.rot, anch)])
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_prow_hall") and known.has("stonehold_prow_hall"), "rebuilt in stone: you learn both blueprints")
	check(RuinProwHall.back_rock(world.maker, o, basis) * 2 >= RuinProwHall.BACK_ALL, "the cave's own rock behind the keep, still there after rebuilding")
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
