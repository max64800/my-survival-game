extends TestCase
## The Cliff Galleries (owner, Nov 26, F913): the thirteenth ruin, dwarf homes up a tall cave wall. Its plan, where it
## goes (and the placement rule: nothing the world grows stands inside it or on its stairs), the cave's shape round it
## (the shelf, the ledge, the crack, the cliff behind), and rebuilding it.

var world: World
var auth: GameAuthority


func _setup(sd := 42) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(sd)


func _plan_pieces(with_fallen := false) -> Array:
	var ps := []
	for q in RuinTower.load_plan(RuinCliffGalleries.PLAN_PATH).pieces:
		if q.get("fallen", false) and not with_fallen:
			continue
		ps.append({id = q.id, mat = q.mat, pos = Vector3(q.pos[0], q.pos[1], q.pos[2]), rot = int(q.rot)})
	return ps


## The local frame the blueprint was made in (the cave floor y 0, the Stone Hall's door at x 0).
func _box(l: Vector3) -> Vector3:
	return l + BlueprintLibrary.CG_SHIFT


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinCliffGalleries.PLAN_PATH)
	check(not plan.is_empty(), "the Galleries' plan file loads")
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		var v := Vector3(p.pos[0], p.pos[1], p.pos[2])
		check(Vector2(v.x, v.z).length() <= RuinCliffGalleries.REACH and v.y >= -0.1
			and v.y < RuinCliffGalleries.G + RuinCliffGalleries.HEIGHT, "the ruin's %s at %s is within its reach" % [p.id, v])
		check(RuinCliffGalleries.clear_at(v.x, v.z) < 1.5, "the ruin's %s at %s is on the ground it keeps clear" % [p.id, v])
	check(plan.get("chests", []).size() >= 3, "chests to find in it")
	check(plan.pieces.filter(func(p): return p.id == "door").is_empty(), "no doors left (they rotted away)")
	var lootable: Array = plan.get("props", []).filter(func(p): return p.get("role", "") == "lootable")
	check(lootable.size() >= 3, "loot to find (%d)" % lootable.size())
	for p in lootable:
		check(LootProps.LOOT.has(String(p.model).get_file().get_basename()), "the %s is something you can loot" % p.model)
	var copper: Array = plan.chests.filter(func(c): return c.kind == "chest_copper")
	check(copper.size() == 1 and float(copper[0].pos[1]) > RuinCliffGalleries.G + 18.0,
		"its best chest is up in the tower's lookout")
	var fallen: Array = plan.pieces.filter(func(p): return p.get("fallen", false))
	check(fallen.size() >= 3, "the gallery's middle and the bridge's far span lie fallen (%d)" % fallen.size())
	check(plan.get("torches", []).size() >= 3, "crystal torches light it")


## Nothing in the ruin falls when it is built (its floors hang on their walls; the fallen pieces lie as rubble).
func test_ruin_stands_up() -> void:
	var plan := RuinTower.load_plan(RuinCliffGalleries.PLAN_PATH)
	var s := Structure.new()
	var uid := 1
	for p in plan.pieces:
		if String(p.id) in RuinTower.RUBBLE or p.get("fallen", false):
			continue
		s.add(uid, p.id, p.mat, Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), float(p.pos[1]) < 0.3 or p.get("anchor", false))
		uid += 1
	var fell: Array = s.recompute()
	check_eq(fell.size(), 0, "no piece of the ruin falls")
	for f in fell.slice(0, 8):
		print("CLIFF_FALLS %s" % [s.pieces[f] if s.pieces.has(f) else f])


## The blueprint and the ruin line up piece for piece: nothing whole is torn down. It is learned only by rebuilding.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("cliff_galleries")
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
	check(BlueprintLibrary.IDS.has("cliff_galleries") and BlueprintLibrary.REBUILD_ONLY.has("cliff_galleries"),
		"in the library, learned only by rebuilding the ruin")
	for bx in bp.pieces:
		check(RuinCliffGalleries.clear_at(bx.pos.x, bx.pos.z) < 1.5,
			"the whole Galleries' %s at %s is on the ground the ruin keeps clear" % [bx.id, bx.pos])


## The ruin rules in the ruin itself: no railing end out past its floor, a stair hole over every stair, no chest at a
## stair's top.
func test_ruin_rules() -> void:
	var lib := preload("res://tests/test_blueprint_library.gd")
	var ps := _plan_pieces()
	for msg in lib.railing_ends_poking_out(ps) + lib.stairs_under_a_ceiling(ps):
		check(false, "the ruin: %s" % msg)
	for c in RuinTower.load_plan(RuinCliffGalleries.PLAN_PATH).chests:
		var cv := Vector3(c.pos[0], c.pos[1], c.pos[2])
		for p in ps:
			if p.id == "stairs":
				var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
				var top: Vector3 = p.pos + up * 2.0 + Vector3.UP * 2.0
				check(not (Vector2(cv.x - top.x, cv.z - top.z).length() < 1.5 and absf(cv.y - top.y) < 0.6),
					"the %s at %s is clear of the top of the stairs at %s" % [c.kind, cv, p.pos])


## The cave's shape: the shelf 10.75 m up, the ledge 4.5 m up, the crack 4.75 m down (ramping up in front), the cliff
## behind; it digs the crack and the yard, and fills only where its shelf and ledge should be (never in their open air).
func test_cave_shape() -> void:
	var b := func(lx: float, lz: float) -> Vector2: return Vector2(_box(Vector3(lx, 0, lz)).x, _box(Vector3(lx, 0, lz)).z)
	var at: Vector2 = b.call(-14.0, -6.0)
	check(absf(RuinCliffGalleries.rise_at(at.x, at.y) - 10.75) < 0.05, "the shelf under the tower is 10.75 m up")
	at = b.call(16.0, -6.0)
	check(absf(RuinCliffGalleries.rise_at(at.x, at.y) - 4.5) < 0.05, "the ledge under the Ledge House is 4.5 m up")
	at = b.call(9.0, -4.0)
	check(absf(RuinCliffGalleries.rise_at(at.x, at.y) + 4.75) < 0.05, "the crack is 4.75 m deep")
	at = b.call(9.0, 7.5)
	check(RuinCliffGalleries.rise_at(at.x, at.y) > -0.05, "the crack ramps back up to the cave floor in front")
	at = b.call(0.0, -1.0)
	check_eq(RuinCliffGalleries.rise_at(at.x, at.y), 0.0, "the cave floor in front of the Stone Hall")
	at = b.call(0.0, -13.0)
	check(RuinCliffGalleries.in_rock_zone(at.x, at.y), "the cliff behind it")
	var crack := 0
	for c in RuinCliffGalleries.carve_points(Vector3.ZERO, 0):
		if c.y < RuinCliffGalleries.G - 0.5:
			crack += 1
	check(crack >= 60, "it digs the crack (%d digs below the floor)" % crack)
	var fills := RuinCliffGalleries.fill_spots()
	check(fills.size() >= 100, "rock to fill the shelf and the ledge with, if the cave lacks it (%d)" % fills.size())
	var out := 0
	for f in fills:
		var l: Vector3 = f - BlueprintLibrary.CG_SHIFT
		var top := RuinCliffGalleries.rise_at(f.x, f.z) if not RuinCliffGalleries.in_rock_zone(f.x, f.z) else 99.0
		if l.z > -1.2 - RuinCliffGalleries.FILL_R + 0.01 or f.y - RuinCliffGalleries.G + RuinCliffGalleries.FILL_R > top + 0.01 \
				or (l.x > -7.2 - RuinCliffGalleries.FILL_R + 0.01 and l.x < 11.0 + RuinCliffGalleries.FILL_R - 0.01):
			out += 1
	check_eq(out, 0, "the fill keeps inside the shelf and the ledge (never in front of them or over their tops)")
	var rubble: Array = _plan_pieces().filter(func(p): return p.id == "ruin_rubble")
	check(rubble.size() >= 5, "rubble lies where things fell (%d)" % rubble.size())


## Where it goes, on a few worlds: a tall cavern of its own, a fair walk out, found quickly, and the placement rule
## (owner, Nov 17): no stone column inside it and its whole ground (the Galleries, its stairs, the yard, the shelf, the
## ledge, the crack) kept clear, so no rock, crystal or plant grows in it.
func test_spot_keeps_clear_of_what_the_world_grows() -> void:
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		var t0 := Time.get_ticks_msec()
		RuinCliffGalleries.pick(c)  # (only timed: its own spot is reserved now)
		var ms := Time.get_ticks_msec() - t0
		var spot: Dictionary = c.cliff_galleries_spot
		check(not spot.is_empty(), "seed %d: a cavern for the Galleries is found" % sd)
		if spot.is_empty():
			continue
		check(ms < 8000, "seed %d: finding the spot takes under 8 s (%d ms)" % [sd, ms])
		var taken := [int(c.manor_spot.get("room", -1)), int(c.prow_hall_spot.get("room", -1)), int(c.twin_gate_spot.get("room", -1)),
			int(c.smeltery_spot.get("room", -1)), int(c.brickcrown_spot.get("room", -1)), int(c.minehead_spot.get("room", -1))]
		check(not spot.room in taken, "seed %d: not a grand ruin's cavern (it may share a small ruin's)" % sd)
		var d := Vector2(spot.pos.x - c.cavern_spawn.x, spot.pos.z - c.cavern_spawn.z).length()
		check(d > 80.0, "seed %d: a fair walk from the start (%.0f m)" % [sd, d])
		var basis := Basis(Vector3.UP, int(spot.turn) * PI / 2.0)
		var bad := 0
		for g: Vector2 in RuinCliffGalleries.ground():
			var at: Vector3 = spot.pos + basis * Vector3(g.x, RuinCliffGalleries.rise_at(g.x, g.y) + 0.3, g.y)
			if c._in_column(at, 1.0) or not c.is_reserved(at):
				bad += 1
		check_eq(bad, 0, "seed %d: no column in the Galleries, all of its ground kept clear" % sd)
		var stairs := 0  # (its stairs, up the tower too: kept clear all the way)
		for p in _plan_pieces():
			if p.id in ["stairs", "foundation_steps"]:
				var at: Vector3 = spot.pos + basis * (p.pos + Vector3(0, 0.3 - RuinCliffGalleries.G, 0))
				if c._in_column(at, 1.0) or not c.is_reserved(at):
					stairs += 1
		check_eq(stairs, 0, "seed %d: its stairs kept clear" % sd)
		var rock := RuinCliffGalleries.back_rock(c, spot.pos, basis)
		var all := RuinCliffGalleries._samples().size()
		var front := RuinCliffGalleries.front_state(c, spot.pos, basis)
		print("CLIFF_NATURAL seed %d: rock %d of %d, way in %s, turn %d, room %d (radii %s)" % [sd, rock, all,
			["open", "dug out", "a drop"][front], spot.turn, spot.room, c.rooms[spot.room].radii])
		check(front < 2, "seed %d: no drop in front of the yard" % sd)
		check(rock >= all / 2, "seed %d: its cliff, shelf and ledge are mostly the cave's own rock (F657: %d of %d)" % [sd, rock, all])
		if sd == 42:  # (a new world takes a few seconds: once is enough)
			check_eq(CaveMaker.new(sd).cliff_galleries_spot, spot, "seed %d: always the same spot" % sd)


## A test world with the Galleries built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_galleries() -> int:
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
	auth.world_state["cliff_galleries"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinCliffGalleries.new(auth)
	auth.add_child(job)
	await tree.process_frame
	# Load its rock (the test world has no camera): its digging needs it.
	var mid := job.origin + Vector3(0, RuinCliffGalleries.G, 0)
	var eye := Node3D.new()
	root.add_child(eye)
	eye.global_position = mid
	var viewer := VoxelViewer.new()
	viewer.view_distance = 80
	viewer.requires_visuals = false
	eye.add_child(viewer)
	for i in 4000:  # (slower in the full suite; the rock checks below tell if it never loaded)
		if world.is_ready_at(mid, 40.0):
			break
		await tree.process_frame
	if not world.is_ready_at(mid, 40.0):
		print("CLIFF_TEST rock not fully loaded yet, going on")
	if job._state == "wait":  # (no meshes in the test world: fill and dig now)
		job._fill = job.fill_here()
		job._state = "fill"
	for i in 12000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


func test_rebuild_the_galleries() -> void:
	var box: int = await _build_galleries()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the Galleries have a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var o := RuinCliffGalleries.built_origin
	var basis := Basis(Vector3.UP, RuinCliffGalleries.built_turn * PI / 2.0)
	var w := func(l: Vector3) -> Vector3: return o + basis * _box(l)
	check(world.sdf_at(w.call(Vector3(-8.0, 3.0, 9.0))) > 0.0, "an open yard in front of the grand stair")
	check(world.sdf_at(w.call(Vector3(9.0, -3.0, -4.0))) > 0.0, "the crack under the bridge is dug")
	check(world.sdf_at(w.call(Vector3(0.0, 3.0, -13.0))) > 0.0, "the Stone Hall's niche is dug")
	check(world.sdf_at(w.call(Vector3(-15.0, 8.0, -6.0))) < 0.0, "the shelf under the tower is rock")
	check(world.sdf_at(w.call(Vector3(18.0, 2.5, -6.0))) < 0.0, "the ledge under the Ledge House is rock")
	check(world.sdf_at(w.call(Vector3(-2.0, -2.0, -6.0))) < 0.0, "rock under the Stone Hall")
	var cp: Vector3 = auth.storage.get_box(box).node.global_position
	check(absf(cp.y - o.y - RuinCliffGalleries.G) < 1.0 and world.sdf_at(cp + Vector3.DOWN * 0.4) < 0.3,
		"the Rebuilding Chest stands on the ground in front (%.2f m up)" % (cp.y - o.y - RuinCliffGalleries.G))
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", "")], ["cliff_galleries", "cliff_galleries", "cut_stone"], "its chest rebuilds the Galleries")
	var b: Builder = auth.builder
	check_eq(b.ruin_choices(box).size(), 1, "one way to rebuild it (one picture in its chest)")
	var weak := 0
	for uid in b.structure.pieces:
		if b.structure.pieces[uid].stability < Pieces.MIN_STABILITY:
			weak += 1
	check_eq(weak, 0, "every piece of the placed ruin holds (has its strength)")
	auth.storage.put(box, "cut_stone", 5)
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	for k in 80000:
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
				print("CLIFF_STUCK %s %s at %s overlaps=%s rock='%s'" % [p.piece, p.family, inv * (p.pos - o), hits,
					Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("cliff_galleries"), "rebuilt: you learn its blueprint")
	# The placement rule: every piece of the rebuilt Galleries stands on ground the world keeps clear.
	var outside := 0
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(o + Vector3(0, RuinCliffGalleries.G, 0)) < RuinCliffGalleries.REACH + 2.0 \
				and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - o])
	check_eq(outside, 0, "every piece of the rebuilt Galleries stands on ground the world keeps clear")
	world.get_parent().queue_free()
