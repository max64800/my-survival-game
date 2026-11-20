extends TestCase
## The Fallen Outpost (owner, Nov 17): its plan, where it goes, and that building it doesn't freeze the game.

var world: World


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinOutpost.OUTPOST_PLAN)
	check(not plan.is_empty(), "the outpost's plan file loads")
	var leaves := 0
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		if p.id == "gate_broken":
			leaves += 1
	check_eq(leaves, 2, "the gate's two leaves lie apart (owner)")
	var plans: Array = plan.chests.filter(func(c): return c.loot.has("outpost_plans"))
	check_eq(plans.size(), 1, "one chest holds the Outpost Plans")


func test_spot_is_found_quickly() -> void:
	_setup()
	var t0 := Time.get_ticks_msec()
	var spot := RuinOutpost.pick(world.maker, 18.5, 7.5)
	var ms := Time.get_ticks_msec() - t0
	check(not spot.is_empty(), "a cavern for the outpost is found")
	if spot.is_empty():
		return
	var d := Vector2(spot.pos.x - world.maker.cavern_spawn.x, spot.pos.z - world.maker.cavern_spawn.z).length()
	check(d > 70.0 and d < 320.0, "it's a fair walk from the start, not at the far edge (%.0f m)" % d)
	check(ms < 3000, "finding the spot takes under 3 s (%d ms)" % ms)


func test_many_pieces_check_fast() -> void:
	# The strength check used to compare every piece with every other: 700 ruin pieces froze the game.
	var plan := RuinTower.load_plan(RuinOutpost.OUTPOST_PLAN)
	var s := Structure.new()
	var uid := 1
	for p in plan.pieces:
		if String(p.id) in RuinTower.RUBBLE:
			continue
		s.add(uid, String(p.id), String(p.mat), Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), float(p.pos[1]) < 0.3)
		uid += 1
	var t0 := Time.get_ticks_msec()
	s.recompute()
	var ms := Time.get_ticks_msec() - t0
	check(ms < 1500, "checking %d pieces' strength takes under 1.5 s (%d ms)" % [uid - 1, ms])


# ------------------------------------------------------------ rebuilding it (owner, Nov 20, F478)
var auth: GameAuthority


## A test world with the outpost built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_outpost() -> int:
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
	auth.world_state["outpost"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinOutpost.new(auth)
	auth.add_child(job)
	await tree.process_frame
	job._state = "carve"  # (no camera in the test world to load rock around)
	for i in 3000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


func _whole_pieces(plan: Array) -> Array:
	return plan.filter(func(p): return not String(p.id).begins_with("ruin_") and not String(p.id) in RuinTower.RUBBLE \
		and not String(p.id) in Builder.RUIN_DEBRIS)


## Owner, Nov 20: "there is a gap" in the right wall. The blueprint is lined up like its ruin (F305), so every whole
## piece of the ruin is a piece of the blueprint (nothing whole gets torn down and put back crooked), and the step in
## the right wall where the two moved parts meet is closed.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("stone_outpost")
	var plan := RuinTower.load_plan(RuinOutpost.OUTPOST_PLAN)
	var off := 0
	for q in _whole_pieces(plan.pieces):
		var qp := Vector3(q.pos[0], q.pos[1], q.pos[2])
		var found := false
		for p in bp.pieces:
			if p.id == q.id and int(p.rot) == int(q.rot) and (p.pos as Vector3).distance_to(qp) < 0.05:
				found = true
				break
		if not found and String(q.id) in Builder.RUIN_MAKE_WAY:
			for p in bp.pieces:  # (an old battlement where the walkway now runs over the forge: it goes back up higher)
				if p.id == q.id and (p.pos as Vector3).distance_to(qp) < 0.6:
					found = true
		if not found:
			off += 1
			if off <= 3:
				check(false, "the ruin's %s at %s is in the blueprint" % [q.id, qp])
	check_eq(off, 0, "every whole piece of the ruin is in the blueprint")
	# The right wall: no stretch of it is left open between z 0 and 9 at either level (the step at the breach).
	for y in [0.0, 2.0]:
		var covered := []
		for p in bp.pieces:
			if not String(p.id) in ["wall", "wall_narrow", "window_wall", "doorway"] or absf(p.pos.y - y) > 0.01 or p.pos.x < 13.5:
				continue
			if int(p.rot) % 2 == 1:
				var half: float = Pieces.LIST[p.id].size.x * 0.5
				covered.append([p.pos.z - half, p.pos.z + half])
		covered.sort()
		var z := 0.0
		for c in covered:
			if c[1] < 0.0 or c[0] > 9.0:
				continue
			check(c[0] <= z + 0.02, "y %.0f: the right wall has no gap between z %.2f and %.2f" % [y, z, c[0]])
			z = maxf(z, c[1])
		check(z >= 8.7, "y %.0f: the right wall runs on to the front-right tower (to z %.2f)" % [y, z])
	var wood := BlueprintLibrary.make("wooden_outpost")
	check(wood != null and wood.pieces.size() == bp.pieces.size(), "a Wooden Outpost blueprint, piece for piece")
	check(BlueprintLibrary.REBUILD_ONLY.has("wooden_outpost"), "learned only by rebuilding the ruin")


func _rebuild(box: int, material: String) -> Dictionary:
	auth.storage.put(box, material, 5)
	var b: Builder = auth.builder
	var site: Dictionary = b.sites.get(box, {})
	if site.is_empty():
		return {}
	var todo := []
	for i in site.plan.size():
		if not site.plan[i].built:
			todo.append(i)
	var need := Builder.missing_for(site.plan, todo, auth.storage.get_box(box).inv)
	for item in need:
		auth.storage.put(box, item, int(need[item]) + 10)
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	var info := {key = site.ruin, done_at_start = site.plan.size() - todo.size(), plan = site.plan.size()}
	for k in 8000:
		if not b.sites.has(box):
			break
		if k % 25 == 0:  # (the chest holds 24 stacks, less than the whole stone rebuild: top it up as it goes, like a player)
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
	return info


func _count(id: String) -> int:
	var n := 0
	for uid in auth.builder.structure.pieces:
		if auth.builder.structure.pieces[uid].piece == id:
			n += 1
	return n


func test_rebuild_the_outpost_in_wood() -> void:
	var box: int = await _build_outpost()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the outpost has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone], ["wooden_outpost", "stone_outpost"], "its chest rebuilds the outpost, not a watchtower")
	check("Fix the old outpost" in auth.builder.ruin_intro(box), "opening it says it's the outpost")
	var at: Vector3 = (auth.storage.boxes[box].node as Node3D).global_position
	var local := Basis(Vector3.UP, RuinOutpost.built_turn * PI / 2.0).inverse() * (at - RuinOutpost.built_origin)
	check(local.z > 15.5 and absf(local.x) > 1.5, "it stands in front of the gate, beside the way in (%.1f, %.1f)" % [local.x, local.z])
	var worn := _count("ruin_wall_worn")
	var info := await _rebuild(box, "plank_root")
	check_eq(info.get("key", ""), "wooden_outpost", "planks first: rebuilt in wood")
	check(int(info.get("done_at_start", 0)) * 3 > int(info.get("plan", 0)) * 2,
		"most of it still stands and counts as done (%s of %s)" % [info.get("done_at_start"), info.get("plan")])
	check(info.get("finished", false), "the rebuilding finished (%s)" % auth.builder.site_status(box))
	check_eq(_count("ruin_wall_collapsed"), 0, "no collapsed walls left")
	check_eq(_count("gate_broken"), 0, "the torn-off gate halves are cleared away")
	check(_count("ruin_wall_worn") > worn / 2, "most worn walls stay as they are in wood (owner): %d of %d" % [_count("ruin_wall_worn"), worn])
	var over_hole := 0  # owner, Nov 20: a new railing stood on a worn wall's missing top stones
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if q.piece != "ruin_wall_worn":
			continue
		for u2 in auth.builder.structure.pieces:
			var a: Dictionary = auth.builder.structure.pieces[u2]
			if a.family == "plank_root" and absf(a.pos.y - q.pos.y - 2.0) < 0.1 and Vector2(a.pos.x - q.pos.x, a.pos.z - q.pos.z).length() < 0.1:
				over_hole += 1
	check_eq(over_hole, 0, "nothing new stands on top of a worn wall")
	var walk := 0  # owner, Nov 20: the walkway runs on over the forge
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		var l: Vector3 = Basis(Vector3.UP, RuinOutpost.built_turn * PI / 2.0).inverse() * (q.pos - RuinOutpost.built_origin)
		if q.piece == "floor" and absf(l.y - 4.25) < 0.05 and absf(l.x - 13.73) < 0.1 and l.z > -6.5 and l.z < 2.0:
			walk += 1
	check_eq(walk, 4, "the walkway over the forge is there (4 floors)")
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_outpost") and known.has("stone_outpost"), "rebuilt in wood: you learn both blueprints (owner, Nov 20)")
	check(auth.world_state.ruins[str(box)].done and not auth.storage.boxes.has(box), "the world remembers; the chest is gone")
	world.get_parent().queue_free()


func test_rebuild_the_outpost_in_stone() -> void:
	var box: int = await _build_outpost()
	if not auth.storage.boxes.has(box):
		check(false, "the outpost has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	var info := await _rebuild(box, "cut_stone")
	check_eq(info.get("key", ""), "stone_outpost", "cut stone first: rebuilt in stone")
	check(info.get("finished", false), "the rebuilding finished (%s)" % auth.builder.site_status(box))
	check_eq(_count("ruin_wall_worn") + _count("ruin_wall_collapsed") + _count("gate_broken"), 0, "stone closes the worn walls too: nothing broken left")
	var planks := auth.builder.structure.pieces.values().filter(func(q): return q.family == "plank_root" and q.piece in ["wall", "floor"])
	check_eq(planks.size(), 0, "no wooden walls or floors in a stone rebuild")
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_outpost") and known.has("stone_outpost"), "rebuilt in stone: you learn both blueprints (owner, Nov 20)")
	# The placement rule (owner, Nov 17): nothing the world grows inside the rebuilt outpost. Its whole ground is kept clear.
	var outside := 0
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(RuinOutpost.built_origin) < 30.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - RuinOutpost.built_origin])
	check_eq(outside, 0, "every piece of the rebuilt outpost stands on ground the world keeps clear")
	world.get_parent().queue_free()


## Saved, and the same for a friend who joins halfway (co-op: the host's world, sent as a snapshot).
func test_a_half_rebuilt_outpost_saves_and_is_shared() -> void:
	var box: int = await _build_outpost()
	if not auth.storage.boxes.has(box):
		check(false, "the outpost has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	auth.storage.put(box, "plank_root", 400)
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
	var snap: Dictionary = str_to_var(var_to_str(auth.snapshot()))  # (what a save file and a joining friend get)
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
		check_eq(guest.builder.sites[box].get("ruin", ""), "wooden_outpost", "still in wood")
		check_eq((guest.builder.sites[box].plan as Array).filter(func(p): return p.built).size(), built, "the same pieces done")
	check_eq(String(guest.world_state.ruins[str(box)].stone), "stone_outpost", "the chest still knows it's the outpost")
	old_root.queue_free()
	world.get_parent().queue_free()


## Outposts built Nov 19-20 got the tower's chest by mistake: loading such a world sets it right.
func test_old_outpost_chest_is_set_right() -> void:
	var box: int = await _build_outpost()
	if not auth.storage.boxes.has(box):
		check(false, "the outpost has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	var ruins: Dictionary = auth.world_state.ruins.duplicate()
	var r: Dictionary = (ruins[str(box)] as Dictionary).duplicate()
	r.merge({stone = "stone_watchtower", wood = "wooden_watchtower"}, true)
	r.erase("reach")
	ruins[str(box)] = r
	auth.world_state.ruins = ruins
	var job := RuinOutpost.new(auth)  # (the world says "built": it only checks its chest)
	auth.add_child(job)
	await tree.process_frame
	check_eq(String(auth.world_state.ruins[str(box)].stone), "stone_outpost", "the chest now rebuilds the outpost")
	check_eq(auth.world_state.ruins.size(), 1, "and no second chest is added")
	world.get_parent().queue_free()
