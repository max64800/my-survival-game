extends TestCase
## The Lantern Spire (owner, Nov 20, F479): the fourth ruin, a tall round Stonehold beacon tower whose top half lies
## fallen across the cave floor. Its plan, its Fire Bowl, where it goes (and the placement rule: nothing the world grows
## in the tower or on its wreckage), rebuilding it in wood or in stone, and the save.

var world: World
var auth: GameAuthority


func _setup(sd := 42) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(sd)


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinSpire.PLAN_PATH)
	check(not plan.is_empty(), "the Spire's plan file loads")
	var wreck := {}
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		if p.id in RuinSpire.WRECKAGE:
			wreck[p.id] = wreck.get(p.id, 0) + 1
			check(p.id in Builder.RUIN_DEBRIS, "%s is cleared when it's rebuilt" % p.id)
	check_eq(wreck, {spire_top_fallen = 1, spire_wall_chunk = 1, beacon_bowl_fallen = 1}, "its top, a wall piece and its fire bowl lie fallen")
	check(plan.get("chests", []).size() >= 2, "chests to find in it")
	check(float(plan.get("reach", 0)) <= RuinSpire.REACH, "its plan reaches no further than the ruin says")


func _whole_pieces(plan: Array) -> Array:
	return plan.filter(func(p): return not String(p.id).begins_with("ruin_") and not String(p.id) in RuinTower.RUBBLE \
		and not String(p.id) in Builder.RUIN_DEBRIS)


## The blueprint and the ruin line up piece for piece: nothing whole is torn down. The Fire Bowl is in the blueprint.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("lantern_spire")
	var plan := RuinTower.load_plan(RuinSpire.PLAN_PATH)
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
	var wood := BlueprintLibrary.make("wooden_spire")
	check(wood != null and wood.pieces.size() == bp.pieces.size(), "a Wooden Spire blueprint, piece for piece")
	for b in [bp, wood]:
		var bowls: Array = b.pieces.filter(func(p): return p.id == "beacon_bowl")
		check(bowls.size() == 1 and bowls[0].mat == "cut_stone" and (bowls[0].pos as Vector3).is_equal_approx(Vector3(0, 10, 0)),
			"%s: one stone Fire Bowl in the middle of the roof" % b.name)
	check_eq([BlueprintLibrary.NAMES.get("lantern_spire"), BlueprintLibrary.NAMES.get("wooden_spire")], ["Lantern Spire", "Wooden Spire"], "its names")
	check(BlueprintLibrary.REBUILD_ONLY.has("lantern_spire") and BlueprintLibrary.REBUILD_ONLY.has("wooden_spire"),
		"both learned only by rebuilding the ruin")


## Owner, Nov 20: the Fire Bowl is a real piece you can build (cut stone + a few copper ingots); its fire burns on the
## model's fire spot.
func test_fire_bowl_is_a_real_piece_with_a_fire() -> void:
	var info: Dictionary = Pieces.LIST.get("beacon_bowl", {})
	check(info.get("group", "") == "decor", "the Fire Bowl is in the build menu (decor)")
	var cost := Pieces.cost("beacon_bowl", "cut_stone")
	check(cost.get("cut_stone", 0) > 0 and cost.get("copper_ingot", 0) in [2, 3, 4], "it costs cut stone and a few copper ingots (%s)" % [cost])
	check(not Pieces.allowed("beacon_bowl", "plank_root"), "never wooden (it would burn)")
	check(PieceNode.forged_mesh("beacon_bowl", "cut_stone") != null, "its model fits the piece")
	var n := PieceNode.new()
	n.piece = "beacon_bowl"
	n.family = "cut_stone"
	tree.root.add_child(n)
	var fires := n.get_children().filter(func(c): return c is Fire)
	check_eq(fires.size(), 1, "one fire burns in it")
	if fires.size() == 1:
		var at: Vector3 = (fires[0] as Fire).position
		check(at.y > 1.3 and at.y < 1.7 and Vector2(at.x, at.z).length() < 0.1, "on the coals in the bowl (%s)" % at)
	n.queue_free()


## Where it goes, on a few worlds: a tall Mossy cavern of its own, a fair walk from the start. The placement rule
## (owner, Nov 17): no stone column in the tower or on its wreckage, and all of it on ground the world keeps clear.
func test_spot_keeps_clear_of_what_the_world_grows() -> void:
	var plan := RuinTower.load_plan(RuinSpire.PLAN_PATH)
	var wreck := RuinSpire.wreck_spots(plan)
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		var spot: Dictionary = c.spire_spot
		check(not spot.is_empty(), "seed %d: a cavern for the Spire is found" % sd)
		if spot.is_empty():
			continue
		check(spot.room != RuinOutpost.pick_room(c) and spot.room != RuinBrewhall.pick_room(c), "seed %d: not the outpost's or the Brewhall's cavern" % sd)
		var d := Vector2(spot.pos.x - c.cavern_spawn.x, spot.pos.z - c.cavern_spawn.z).length()
		check(d > 45.0, "seed %d: a fair walk from the start (%.0f m)" % [sd, d])
		check(not c._in_column(spot.pos, 4.2 + 1.0), "seed %d: no column inside the tower" % sd)
		var basis := Basis(Vector3.UP, int(spot.turn) * PI / 2.0)
		var bad := 0
		for w in wreck:
			var at: Vector3 = spot.pos + basis * w + Vector3.UP * 0.2
			if c._in_column(at, 1.0) or not c.is_reserved(at):
				bad += 1
		check_eq(bad, 0, "seed %d: no column on its wreckage, all of it on kept-clear ground" % sd)
		for a in 12:
			var at: Vector3 = spot.pos + Vector3(cos(a * TAU / 12.0), 0.3, sin(a * TAU / 12.0)) * 4.4
			check(c.is_reserved(at), "seed %d: the tower's ground is kept clear" % sd)


func test_spot_is_found_quickly() -> void:
	var c := CaveMaker.new(42)
	var t0 := Time.get_ticks_msec()
	var spot := RuinSpire.pick(c, RuinTower.load_plan(RuinSpire.PLAN_PATH))
	var ms := Time.get_ticks_msec() - t0
	check(not spot.is_empty(), "found again from the seed")
	check(spot.hash() == c.spire_spot.hash(), "the same spot every time")
	check(ms < 3000, "finding the spot takes under 3 s (%d ms)" % ms)


## A test world with the Spire built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_spire() -> int:
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
	auth.world_state["spire"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinSpire.new(auth)
	auth.add_child(job)
	await tree.process_frame
	job._state = "carve"  # (no camera in the test world to load rock around)
	for i in 3000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


## Rebuilds with `material` first in the chest, then tops the chest up as it goes (it holds 24 stacks).
func _rebuild(box: int, material: String) -> Dictionary:
	auth.storage.put(box, material, 5)
	var b: Builder = auth.builder
	var site: Dictionary = b.sites.get(box, {})
	if site.is_empty():
		return {}
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	var todo := (site.plan as Array).filter(func(p): return not p.built).size()
	var info := {key = site.ruin, done_at_start = site.plan.size() - todo, plan = site.plan.size()}
	for k in 8000:
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
	info.finished = not b.sites.has(box)
	if not info.finished:  # (what holds it up, to fix)
		var basis := Basis(Vector3.UP, RuinSpire.built_turn * PI / 2.0).inverse()
		var n := 0
		for p in b.sites[box].plan:
			if not p.built and n < 6:
				n += 1
				print("SPIRE_STUCK %s %s at %s overlap=%s rock='%s'" % [p.piece, p.family, basis * (p.pos - RuinSpire.built_origin),
					b.structure.overlapping(p.piece, p.pos, p.rot).map(func(u): return "%s@%s r%d" % [b.structure.pieces[u].piece, basis * (b.structure.pieces[u].pos - RuinSpire.built_origin), b.structure.pieces[u].rot]), Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	return info


func _count(id: String) -> int:
	var n := 0
	for uid in auth.builder.structure.pieces:
		if auth.builder.structure.pieces[uid].piece == id:
			n += 1
	return n


func _wreck_count() -> int:
	var n := 0
	for id in RuinSpire.WRECKAGE:
		n += _count(id)
	return n


func test_rebuild_the_spire_in_wood() -> void:
	var box: int = await _build_spire()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the Spire has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", ""), r.get("over", 0.0)], ["wooden_spire", "lantern_spire", "cut_stone", 2.35], "its chest rebuilds the Spire")
	check("Fix the old spire" in auth.builder.ruin_intro(box), "opening it says it's the Spire")
	check_eq(_wreck_count(), 3, "the ruin stands: its fallen top, wall piece and fire bowl lie on the floor")
	var ok_floor := 0
	for uid in auth.builder.structure.pieces:  # the wreckage lies on the cave floor: no end floats, none deeply buried
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if not q.piece in RuinSpire.WRECKAGE:
			continue
		var s: Vector3 = Pieces.LIST[q.piece].size
		var b := Basis(Vector3.UP, Pieces.yaw_of(int(q.rot)))
		var pts := []
		for o in [Vector3.ZERO, Vector3(0.35, 0, 0.35), Vector3(-0.35, 0, 0.35), Vector3(0.35, 0, -0.35), Vector3(-0.35, 0, -0.35)]:
			pts.append(q.pos + b * (o * s))
		var g: Vector2 = RuinSpire.ground_under(world.maker, pts, RuinSpire.built_origin.y + 5.0) - Vector2.ONE * float(q.pos.y)
		print("SPIRE_WRECK %s ground under it from %.2f to %.2f m" % [q.piece, g.x, g.y])
		if g.x > -0.1 and g.x < 0.3 and g.y < RuinSpire.FLAT + 0.1:
			ok_floor += 1
	check_eq(ok_floor, 3, "the wreckage lies on the cave floor")
	var worn := _count("ruin_wall_worn")
	var info := await _rebuild(box, "plank_root")
	check_eq(info.get("key", ""), "wooden_spire", "planks first: rebuilt in wood")
	check(int(info.get("done_at_start", 0)) * 3 > int(info.get("plan", 0)), "a good part still stands and counts as done (%s of %s)" % [info.get("done_at_start"), info.get("plan")])
	check(info.get("finished", false), "the rebuilding finished (%s)" % auth.builder.site_status(box))
	check_eq(_count("ruin_wall_collapsed") + _wreck_count(), 0, "no collapsed walls left, the wreckage cleared")
	check(_count("ruin_wall_worn") > 0 and _count("ruin_wall_worn") < worn, "worn walls stay in wood, unless something new stands on one: %d of %d" % [_count("ruin_wall_worn"), worn])
	var over_hole := 0  # (Stonehold floors are 2.25 m apart: nothing new on a worn wall's broken top)
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if q.piece != "ruin_wall_worn":
			continue
		for u2 in auth.builder.structure.pieces:
			var a: Dictionary = auth.builder.structure.pieces[u2]
			var dy: float = a.pos.y - q.pos.y
			if a.family == "plank_root" and dy > 1.9 and dy < 2.35 and Vector2(a.pos.x - q.pos.x, a.pos.z - q.pos.z).length() < 0.1:
				over_hole += 1
	check_eq(over_hole, 0, "nothing new stands on top of a worn wall")
	check_eq(_count("beacon_bowl"), 1, "the Fire Bowl is back on top")
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_spire") and known.has("lantern_spire"), "rebuilt in wood: you learn both blueprints")
	check(auth.world_state.ruins[str(box)].done and not auth.storage.boxes.has(box), "the world remembers; the chest is gone")
	world.get_parent().queue_free()


func test_rebuild_the_spire_in_stone() -> void:
	var box: int = await _build_spire()
	if not auth.storage.boxes.has(box):
		check(false, "the Spire has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	var info := await _rebuild(box, "cut_stone")
	check_eq(info.get("key", ""), "lantern_spire", "cut stone first: rebuilt in stone")
	check(info.get("finished", false), "the rebuilding finished (%s)" % auth.builder.site_status(box))
	check_eq(_count("ruin_wall_worn") + _count("ruin_wall_collapsed") + _wreck_count(), 0, "stone closes the worn walls too: nothing broken left")
	var bowl := auth.builder.structure.pieces.values().filter(func(q): return q.piece == "beacon_bowl")
	check(bowl.size() == 1 and absf(bowl[0].pos.y - RuinSpire.built_origin.y - 10.0) < 0.05, "the Fire Bowl stands on the roof")
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_spire") and known.has("lantern_spire"), "rebuilt in stone: you learn both blueprints")
	# The placement rule (owner, Nov 17): the whole tower stands on ground the world keeps clear.
	var outside := 0
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(RuinSpire.built_origin) < 16.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - RuinSpire.built_origin])
	check_eq(outside, 0, "every piece of the rebuilt Spire stands on ground the world keeps clear")
	world.get_parent().queue_free()


## Saved, and the same for a friend who joins halfway (co-op: the host's world, sent as a snapshot).
func test_a_half_rebuilt_spire_saves_and_is_shared() -> void:
	var box: int = await _build_spire()
	if not auth.storage.boxes.has(box):
		check(false, "the Spire has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	auth.storage.put(box, "plank_root", 300)
	var b: Builder = auth.builder
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	for k in 60:
		b._site_ticks += 1
		b._tick_sites()
	check(b.sites.has(box), "the rebuilding started")
	if not b.sites.has(box):
		world.get_parent().queue_free()
		return
	var built := (b.sites[box].plan as Array).filter(func(p): return p.built).size()
	var snap: Dictionary = str_to_var(var_to_str(auth.snapshot()))
	var old_root := world.get_parent()
	_setup()
	var guest := GameAuthority.new()
	guest.world = world
	guest.drops_root = Node3D.new()
	guest.stations_root = Node3D.new()
	world.get_parent().add_child(guest.drops_root)
	world.get_parent().add_child(guest.stations_root)
	world.get_parent().add_child(guest)
	guest.load_snapshot(snap)
	check(guest.builder.sites.has(box), "the rebuilding is still going after loading")
	if guest.builder.sites.has(box):
		check_eq(guest.builder.sites[box].get("ruin", ""), "wooden_spire", "still in wood")
		check_eq((guest.builder.sites[box].plan as Array).filter(func(p): return p.built).size(), built, "the same pieces done")
	check_eq(float(guest.world_state.ruins[str(box)].get("over", 0.0)), 2.35, "it still looks 2.35 m above worn walls")
	old_root.queue_free()
	world.get_parent().queue_free()
