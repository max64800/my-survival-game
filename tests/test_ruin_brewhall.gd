extends TestCase
## The Brewhall (owner, Nov 20, F479): the third ruin, a clay-brick tavern and brewery. Its plan, where it goes,
## rebuilding it in wood or in brick, the save, and the placement rule.

var world: World
var auth: GameAuthority


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinBrewhall.PLAN_PATH)
	check(not plan.is_empty(), "the Brewhall's plan file loads")
	var chimney := 0
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		if p.id == "chimney_fallen":
			chimney += 1
	check_eq(chimney, 1, "its chimney lies fallen across the yard")
	check(plan.get("chests", []).size() >= 3, "chests to find in it")


func _whole_pieces(plan: Array) -> Array:
	return plan.filter(func(p): return not String(p.id).begins_with("ruin_") and not String(p.id) in RuinTower.RUBBLE \
		and not String(p.id) in Builder.RUIN_DEBRIS)


## The blueprint and the ruin line up piece for piece (the outpost's didn't at first): nothing whole is torn down.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("hearthbrick_brewhall")
	var plan := RuinTower.load_plan(RuinBrewhall.PLAN_PATH)
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
	var wood := BlueprintLibrary.make("wooden_brewhall")
	check(wood != null and wood.pieces.size() == bp.pieces.size(), "a Wooden Brewhall blueprint, piece for piece")
	var chimney := wood.pieces.filter(func(p): return p.pos.x > 6.1)
	check(chimney.size() == 16 and chimney.all(func(p): return p.mat == "clay_brick"), "the wooden one keeps its brick chimney")
	check(BlueprintLibrary.REBUILD_ONLY.has("wooden_brewhall") and BlueprintLibrary.REBUILD_ONLY.has("hearthbrick_brewhall"),
		"both learned only by rebuilding the ruin")


## Owner, Nov 20: no steps in a corner (every set lands on open ground) and no window right beside a door.
func test_steps_land_on_open_ground_and_doors_have_no_window_beside() -> void:
	var bp := BlueprintLibrary.make("hearthbrick_brewhall")
	for s in bp.pieces.filter(func(p): return p.id == "foundation_steps"):
		var out := Basis(Vector3.UP, Pieces.yaw_of(int(s.rot))) * Vector3(0, 0, 1)   # the way you walk down them
		var land: Vector3 = s.pos + out * 2.0 + Vector3.UP * 0.5                    # the 2 m in front of their foot
		for p in bp.pieces:
			if p == s or p.id in ["door"]:
				continue
			var hit: bool = Vector2(p.pos.x - land.x, p.pos.z - land.z).length() < 0.95 and p.pos.y < 1.5
			check(not hit, "the steps at %s land on open ground (%s at %s in the way)" % [s.pos, p.id, p.pos])
	for d in bp.pieces.filter(func(p): return p.id == "doorway"):
		var along := Basis(Vector3.UP, Pieces.yaw_of(int(d.rot))) * Vector3(2, 0, 0)
		for p in bp.pieces:
			if p.id in ["window_wall", "window_wide"] and absf(p.pos.y - d.pos.y) < 0.1 and int(p.rot) % 2 == int(d.rot) % 2:
				var next: bool = (p.pos as Vector3).distance_to(d.pos + along) < 0.1 or (p.pos as Vector3).distance_to(d.pos - along) < 0.1
				check(not next, "no window right beside the door at %s" % d.pos)


func test_spot_is_found_quickly() -> void:
	_setup()
	var t0 := Time.get_ticks_msec()
	var spot := RuinBrewhall.pick(world.maker, 8.6, 8.0)
	var ms := Time.get_ticks_msec() - t0
	check(not spot.is_empty(), "a cavern for the Brewhall is found")
	if spot.is_empty():
		return
	check(spot.room != RuinOutpost.pick_room(world.maker), "not the Fallen Outpost's cavern")
	var d := Vector2(spot.pos.x - world.maker.cavern_spawn.x, spot.pos.z - world.maker.cavern_spawn.z).length()
	check(d > 45.0 and d < 260.0, "a fair walk from the start (%.0f m)" % d)
	check(ms < 3000, "finding the spot takes under 3 s (%d ms)" % ms)
	world.get_parent().queue_free()


## A test world with the Brewhall built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_brewhall() -> int:
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
	auth.world_state["brewhall"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinBrewhall.new(auth)
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
	for k in 6000:
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
		var basis := Basis(Vector3.UP, RuinBrewhall.built_turn * PI / 2.0).inverse()
		var n := 0
		for p in b.sites[box].plan:
			if not p.built and n < 6:
				n += 1
				print("BREW_STUCK %s %s at %s overlap=%s rock='%s'" % [p.piece, p.family, basis * (p.pos - RuinBrewhall.built_origin),
					b.structure.overlapping(p.piece, p.pos, p.rot).map(func(u): return "%s@%s r%d" % [b.structure.pieces[u].piece, basis * (b.structure.pieces[u].pos - RuinBrewhall.built_origin), b.structure.pieces[u].rot]), Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	return info


func _count(id: String) -> int:
	var n := 0
	for uid in auth.builder.structure.pieces:
		if auth.builder.structure.pieces[uid].piece == id:
			n += 1
	return n


func test_rebuild_the_brewhall_in_wood() -> void:
	var box: int = await _build_brewhall()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the Brewhall has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", "")], ["wooden_brewhall", "hearthbrick_brewhall", "clay_brick"], "its chest rebuilds the Brewhall")
	check("Fix the old brewhall" in auth.builder.ruin_intro(box) and "clay brick" in auth.builder.ruin_intro(box),
		"opening it says it's the Brewhall, fixed with planks or clay bricks")
	check(_count("chimney_fallen") == 1 and _count("ruin_wall_worn") > 5, "the ruin stands: worn walls, the fallen chimney")
	var worn := _count("ruin_wall_worn")
	var info := await _rebuild(box, "plank_root")
	check_eq(info.get("key", ""), "wooden_brewhall", "planks first: rebuilt in wood")
	check(int(info.get("done_at_start", 0)) * 3 > int(info.get("plan", 0)) * 2,
		"most of it still stands and counts as done (%s of %s)" % [info.get("done_at_start"), info.get("plan")])
	check(info.get("finished", false), "the rebuilding finished (%s)" % auth.builder.site_status(box))
	check_eq(_count("ruin_wall_collapsed") + _count("chimney_fallen"), 0, "no collapsed walls left, the fallen chimney cleared")
	check(_count("ruin_wall_worn") > worn / 3, "worn walls stay as they are in wood (owner): %d of %d" % [_count("ruin_wall_worn"), worn])
	var over_hole := 0  # (Hearthbrick floors are 2.25 m apart: nothing new on a worn wall's broken top)
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if q.piece != "ruin_wall_worn":
			continue
		for u2 in auth.builder.structure.pieces:
			var a: Dictionary = auth.builder.structure.pieces[u2]
			var dy: float = a.pos.y - q.pos.y
			if a.family == "plank_root" and dy > 1.9 and dy < 2.1 and Vector2(a.pos.x - q.pos.x, a.pos.z - q.pos.z).length() < 0.1:
				over_hole += 1
	check_eq(over_hole, 0, "nothing new stands on top of a worn wall")
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_brewhall") and known.has("hearthbrick_brewhall"), "rebuilt in wood: you learn both blueprints")
	check(auth.world_state.ruins[str(box)].done and not auth.storage.boxes.has(box), "the world remembers; the chest is gone")
	world.get_parent().queue_free()


func test_rebuild_the_brewhall_in_brick() -> void:
	var box: int = await _build_brewhall()
	if not auth.storage.boxes.has(box):
		check(false, "the Brewhall has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	var info := await _rebuild(box, "clay_brick")
	check_eq(info.get("key", ""), "hearthbrick_brewhall", "clay bricks first: rebuilt in brick")
	check(info.get("finished", false), "the rebuilding finished (%s)" % auth.builder.site_status(box))
	check_eq(_count("ruin_wall_worn") + _count("ruin_wall_collapsed") + _count("chimney_fallen"), 0, "brick closes the worn walls too")
	var planks := auth.builder.structure.pieces.values().filter(func(q): return q.family == "plank_root" and q.piece in ["wall", "floor", "roof_26"])
	check_eq(planks.size(), 0, "no wooden walls, floors or roofs in a brick rebuild")
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_brewhall") and known.has("hearthbrick_brewhall"), "rebuilt in brick: you learn both blueprints")
	# The placement rule (owner, Nov 17): nothing the world grows inside it. Its whole ground (corners too) is kept clear.
	var outside := 0
	for uid in auth.builder.structure.pieces:
		var q: Dictionary = auth.builder.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(RuinBrewhall.built_origin) < 14.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - RuinBrewhall.built_origin])
	check_eq(outside, 0, "every piece of the rebuilt Brewhall stands on ground the world keeps clear")
	# Its cellar is dug out: open air where its floor and stairs are.
	var basis := Basis(Vector3.UP, RuinBrewhall.built_turn * PI / 2.0)
	for l in [Vector3(4.0, -0.6, -3.0), Vector3(5.0, -0.6, -5.0)]:
		var at: Vector3 = RuinBrewhall.built_origin + basis * l
		check(world.sdf_at(at) > 0.3, "the cellar is dug out at %s (%.2f)" % [l, world.sdf_at(at)])
	world.get_parent().queue_free()


## Saved, and the same for a friend who joins halfway (co-op: the host's world, sent as a snapshot).
func test_a_half_rebuilt_brewhall_saves_and_is_shared() -> void:
	var box: int = await _build_brewhall()
	if not auth.storage.boxes.has(box):
		check(false, "the Brewhall has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	auth.storage.put(box, "clay_brick", 300)
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
		check_eq(guest.builder.sites[box].get("ruin", ""), "hearthbrick_brewhall", "still in brick")
		check_eq((guest.builder.sites[box].plan as Array).filter(func(p): return p.built).size(), built, "the same pieces done")
	check_eq(String(guest.world_state.ruins[str(box)].mat), "clay_brick", "the chest still takes clay bricks")
	old_root.queue_free()
	world.get_parent().queue_free()
