extends TestCase
## The Smeltery Terraces (owner, Nov 24-25, F845): the tenth ruin, a Hearthbrick smelting works built into a natural
## cave. Its plan, where it goes (and the placement rule: nothing the world grows stands inside it or on its stairs),
## the cave's shape round it (the dip under the bridge, the cave's own rock behind it), rebuilding it in brick, and its
## turret ladders.

var world: World
var auth: GameAuthority


func _setup(sd := 42) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(sd)


func _plan_pieces() -> Array:
	var ps := []
	for q in RuinTower.load_plan(RuinSmeltery.PLAN_PATH).pieces:
		ps.append({id = q.id, mat = q.mat, pos = Vector3(q.pos[0], q.pos[1], q.pos[2]), rot = int(q.rot)})
	return ps


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinSmeltery.PLAN_PATH)
	check(not plan.is_empty(), "the Smeltery's plan file loads")
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		var v := Vector3(p.pos[0], p.pos[1], p.pos[2])
		check(Vector2(v.x, v.z).length() <= RuinSmeltery.REACH and v.y >= -3.1 and v.y < RuinSmeltery.HEIGHT,
			"the ruin's %s at %s is within its reach" % [p.id, v])
		check(RuinSmeltery.clear_at(v.x, v.z) < 1.5, "the ruin's %s at %s is on the ground it keeps clear" % [p.id, v])
	check(plan.get("chests", []).size() >= 3, "chests to find in it")
	check(plan.pieces.filter(func(p): return p.id == "door").is_empty(), "no doors left (they rotted away)")
	var lootable: Array = plan.get("props", []).filter(func(p): return p.get("role", "") == "lootable")
	check(lootable.size() >= 3, "loot to find (ingots, coal: %d)" % lootable.size())
	for p in lootable:
		check(LootProps.LOOT.has(String(p.model).get_file().get_basename()), "the %s is something you can loot" % p.model)
	var copper: Array = plan.chests.filter(func(c): return c.kind == "chest_copper")
	check(copper.size() == 1 and float(copper[0].pos[1]) > 14.0, "its best chest is up in the tower's ring room")


## Nothing in the ruin falls when it is built (its floors hang on their walls).
func test_ruin_stands_up() -> void:
	var plan := RuinTower.load_plan(RuinSmeltery.PLAN_PATH)
	var s := Structure.new()
	var uid := 1
	for p in plan.pieces:
		if String(p.id) in RuinTower.RUBBLE:
			continue
		s.add(uid, p.id, p.mat, Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), float(p.pos[1]) < 0.3 or p.get("anchor", false))
		uid += 1
	var fell: Array = s.recompute()
	check_eq(fell.size(), 0, "no piece of the ruin falls")
	for f in fell.slice(0, 8):
		print("SMELT_FALLS %s" % [s.pieces[f] if s.pieces.has(f) else f])


## The blueprint and the ruin line up piece for piece: nothing whole is torn down. Both blueprints are learned only
## by rebuilding the ruin.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("hearthbrick_smeltery")
	var off := 0
	for q in _plan_pieces():
		if String(q.id).begins_with("ruin_") or String(q.id) in RuinTower.RUBBLE or String(q.id) in Builder.RUIN_DEBRIS:
			continue
		var found := false
		for p in bp.pieces:
			if p.id == q.id and int(p.rot) == int(q.rot) and (p.pos as Vector3).distance_to(q.pos) < 0.05:
				found = true
				break
		if not found:
			off += 1
			if off <= 3:
				check(false, "the ruin's %s at %s is in the blueprint" % [q.id, q.pos])
	check_eq(off, 0, "every whole piece of the ruin is in the blueprint")
	check(BlueprintLibrary.IDS.has("hearthbrick_smeltery") and BlueprintLibrary.IDS.has("wooden_smeltery"), "both in the library")
	check(BlueprintLibrary.REBUILD_ONLY.has("hearthbrick_smeltery") and BlueprintLibrary.REBUILD_ONLY.has("wooden_smeltery"),
		"both learned only by rebuilding the ruin")
	check_eq(BlueprintLibrary.make("wooden_smeltery").pieces.size(), bp.pieces.size(), "a Wooden Smeltery, piece for piece")
	for bx in bp.pieces:
		check(RuinSmeltery.clear_at(bx.pos.x, bx.pos.z) < 1.5, "the whole works' %s at %s is on the ground the ruin keeps clear" % [bx.id, bx.pos])


## The ruin rules in the ruin itself: no railing end out past its floor, a stair hole over every stair, no chest at a
## stair's top, and every ladder goes from a floor that stands to a floor that stands (the turrets' tops fell).
func test_ruin_rules() -> void:
	var lib := preload("res://tests/test_blueprint_library.gd")
	var ps := _plan_pieces()
	for msg in lib.railing_ends_poking_out(ps) + lib.stairs_under_a_ceiling(ps):
		check(false, "the ruin: %s" % msg)
	for c in RuinTower.load_plan(RuinSmeltery.PLAN_PATH).chests:
		var cv := Vector3(c.pos[0], c.pos[1], c.pos[2])
		for p in ps:
			if p.id == "stairs":
				var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
				var top: Vector3 = p.pos + up * 2.0 + Vector3.UP * 2.0
				check(not (Vector2(cv.x - top.x, cv.z - top.z).length() < 1.5 and absf(cv.y - top.y) < 0.6),
					"the %s at %s is clear of the top of the stairs at %s" % [c.kind, cv, p.pos])
	var ladders := 0
	for p in ps:
		if p.id != "ladder":
			continue
		ladders += 1
		for y in [p.pos.y, p.pos.y + 2.25]:
			var floor_there := false
			for q in ps:
				if q.id in ["floor", "floor_triangle", "foundation", "foundation_triangle"] \
						and absf(Pieces.box(q.id, q.pos, q.rot).end.y - y) < 0.1 and Vector2(q.pos.x - p.pos.x, q.pos.z - p.pos.z).length() < 1.7:
					floor_there = true
			check(floor_there, "the ladder at %s has a floor at %.2f" % [p.pos, y])
	check(ladders >= 3, "the turrets keep ladders to climb (%d)" % ladders)


## The cave's shape: a dip just in front of the bridge's fallen span (about 2.5 m deep), none under the vaults, the side door's
## steps or the pier, and it only digs round its own pieces (rebuilding never flattens the cave).
func test_cave_shape() -> void:
	check(RuinSmeltery.dip_at(-10.15, 2.75) < -2.3, "the dip in front of the bridge is about 2.5 m deep")
	for x in [-14.0, -12.0, -10.0]:  # (the bridge's 3 rows of columns, owner, Nov 25)
		for z in [-2.4, -2.0, 0.0, 0.4]:
			check_eq(RuinSmeltery.dip_at(x, z), 0.0, "no dip under the bridge's column at %s" % Vector2(x, z))
	check_eq(RuinSmeltery.dip_at(-7.0, -1.0), 0.0, "no dip under the vaults")
	check_eq(RuinSmeltery.dip_at(-9.0, -7.0), 0.0, "no dip under the side door's steps")
	check_eq(RuinSmeltery.dip_at(-13.0, -1.0), 0.0, "no dip under the bridge's pier")
	var bp := BlueprintLibrary.make("hearthbrick_smeltery")
	var air := 0
	for v in bp.air:
		air += int(v)
	check(air < bp.air.size() * 0.75, "the blueprint only digs round the works (%d of %d cells)" % [air, bp.air.size()])
	var pts := RuinSmeltery.carve_points(Vector3.ZERO, 0)
	var dip := 0
	var behind := 0
	for c in pts:
		if c.y < -1.0:
			dip += 1
		if c.z < -10.6:
			behind += 1
	check(dip >= 8, "it digs the dip under the bridge (%d digs below the floor)" % dip)
	check_eq(behind, 0, "it never digs into the cave's rock behind its back")
	check(pts.size() > 1000, "it digs its space (%d digs)" % pts.size())
	var rubble: Array = _plan_pieces().filter(func(p): return p.id == "ruin_rubble")
	check(rubble.size() >= 6, "rubble lies where things fell (%d)" % rubble.size())
	for r in rubble:
		check(r.pos.y >= RuinSmeltery.dip_at(r.pos.x, r.pos.z) - 0.05, "the rubble at %s lies on the ground, not in it" % r.pos)


## Where it goes, on a few worlds: a tall cavern of its own, a fair walk out, found quickly, and the placement rule
## (owner, Nov 17): no stone column inside it and its whole ground (the works, its stairs, the yard) kept clear, so no
## rock, crystal or plant grows in it.
func test_spot_keeps_clear_of_what_the_world_grows() -> void:
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		var t0 := Time.get_ticks_msec()
		RuinSmeltery.pick(c)  # (only timed: its own spot is reserved now)
		var ms := Time.get_ticks_msec() - t0
		var spot: Dictionary = c.smeltery_spot
		check(not spot.is_empty(), "seed %d: a cavern for the Smeltery is found" % sd)
		if spot.is_empty():
			continue
		check(ms < 5000, "seed %d: finding the spot takes under 5 s (%d ms)" % [sd, ms])
		var taken := [int(c.manor_spot.get("room", -1)), int(c.prow_hall_spot.get("room", -1)), int(c.twin_gate_spot.get("room", -1))]
		check(not spot.room in taken, "seed %d: not a grand ruin's cavern (it may share a small ruin's)" % sd)
		var d := Vector2(spot.pos.x - c.cavern_spawn.x, spot.pos.z - c.cavern_spawn.z).length()
		check(d > 80.0, "seed %d: a fair walk from the start (%.0f m)" % [sd, d])
		var basis := Basis(Vector3.UP, int(spot.turn) * PI / 2.0)
		var bad := 0
		for g: Vector2 in RuinSmeltery.ground():
			var at: Vector3 = spot.pos + basis * Vector3(g.x, 0.3, g.y)
			if c._in_column(at, 1.0) or not c.is_reserved(at):
				bad += 1
		check_eq(bad, 0, "seed %d: no column in the Smeltery, all of its ground kept clear" % sd)
		var stairs := 0  # (its stairs and ladders, up the tower too: kept clear all the way up)
		for p in _plan_pieces():
			if p.id in ["stairs", "foundation_steps", "ladder"]:
				var at: Vector3 = spot.pos + basis * (p.pos + Vector3(0, 0.3, 0))
				if c._in_column(at, 1.0) or not c.is_reserved(at):
					stairs += 1
		check_eq(stairs, 0, "seed %d: its stairs and ladders kept clear" % sd)
		var back := RuinSmeltery.back_rock(c, spot.pos, basis)
		var front := RuinSmeltery.front_state(c, spot.pos, basis)
		print("SMELT_NATURAL seed %d: back rock %d of %d, way in %s, turn %d, room %d (radii %s)" % [sd, back, RuinSmeltery.BACK_ALL,
			["open", "dug out", "a drop"][front], spot.turn, spot.room, c.rooms[spot.room].radii])
		check(front < 2, "seed %d: no drop in the 10 m in front of the yard" % sd)
		if sd == 42:  # (a new world takes a few seconds: once is enough)
			check_eq(CaveMaker.new(sd).smeltery_spot, spot, "seed %d: always the same spot" % sd)


## A test world with the Smeltery built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_smeltery() -> int:
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
	auth.world_state["smeltery"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinSmeltery.new(auth)
	auth.add_child(job)
	await tree.process_frame
	# Load its rock (the test world has no camera): its digging needs it.
	var eye := Node3D.new()
	root.add_child(eye)
	eye.global_position = job.origin + Vector3(0, 8, 0)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 72
	viewer.requires_visuals = false
	eye.add_child(viewer)
	for i in 4000:  # (slower in the full suite; the rock checks below tell if it never loaded)
		if world.is_ready_at(job.origin + Vector3(0, 8, 0), 36.0):
			break
		await tree.process_frame
	if not world.is_ready_at(job.origin + Vector3(0, 8, 0), 36.0):
		print("SMELT_TEST rock not fully loaded yet, going on")
	job._state = "carve"  # (no meshes in the test world: start digging now)
	for i in 8000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


func test_rebuild_the_smeltery_in_brick() -> void:
	var box: int = await _build_smeltery()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the Smeltery has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var o := RuinSmeltery.built_origin
	var basis := Basis(Vector3.UP, RuinSmeltery.built_turn * PI / 2.0)
	check(world.sdf_at(o + basis * Vector3(5.0, 2.5, 11.0)) > 0.0, "an open yard in front of the steps")
	check(world.sdf_at(o + basis * Vector3(-10.15, -1.2, 2.75)) > 0.0, "the dip in front of the bridge is dug")
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", "")], ["wooden_smeltery", "hearthbrick_smeltery", "clay_brick"], "its chest rebuilds the Smeltery")
	var b: Builder = auth.builder
	var weak := 0
	for uid in b.structure.pieces:
		if b.structure.pieces[uid].stability < Pieces.MIN_STABILITY:
			weak += 1
	check_eq(weak, 0, "every piece of the placed ruin holds (has its strength)")
	auth.storage.put(box, "clay_brick", 5)
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	for k in 60000:
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
		for i in plan.size():
			var p: Dictionary = plan[i]
			if not p.built and n < 20:
				n += 1
				var hits := []
				for uid in b.structure.overlapping(p.piece, p.pos, p.rot):
					hits.append("%s@%s" % [b.structure.pieces[uid].piece, inv * (b.structure.pieces[uid].pos - o)])
				print("SMELT_STUCK %s %s at %s overlaps=%s rock='%s'" % [p.piece, p.family, inv * (p.pos - o), hits,
					Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_smeltery") and known.has("hearthbrick_smeltery"), "rebuilt in brick: you learn both blueprints")
	# The placement rule: every piece of the rebuilt works stands on ground the world keeps clear.
	var outside := 0
	var ladders := 0
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if q.piece == "ladder":
			ladders += 1
		if (q.pos as Vector3).distance_to(o) < RuinSmeltery.REACH + 2.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - o])
	check_eq(outside, 0, "every piece of the rebuilt works stands on ground the world keeps clear")
	check_eq(ladders, 9, "the rebuilt turrets and furnace have all 9 ladders back")
	world.get_parent().queue_free()
