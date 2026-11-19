extends TestCase
## F254: the ruined Stone Watchtower in the first cave of a new world (owner, Nov 17).

var world: World
var auth: GameAuthority


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	auth.stations_root = Node3D.new()
	root.add_child(auth.drops_root)
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	me.global_position = world.maker.cavern_spawn
	auth.add_player(1, me)


func test_plan_has_the_ruin() -> void:
	var plan := RuinTower.load_plan()
	check(not plan.is_empty(), "the ruin's plan file loads")
	var ids := {}
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		ids[p.id] = true
	check(not ids.has("door"), "no door hangs in the doorway (owner)")
	check(ids.has("door_broken") and ids.has("ruin_wall_collapsed") and ids.has("ruin_wall_worn") and ids.has("ruin_rubble"),
		"it's broken: the door lies outside, walls worn and collapsed, rubble")
	var roof: Array = plan.chests.filter(func(c): return float(c.pos[1]) > 7.0)
	check(roof.size() == 1 and roof[0].loot.has("watchtower_plans"), "the roof chest holds the Watchtower Plans")
	var kinds: Array = plan.chests.filter(func(c): return c.kind != "barrel").map(func(c): return [float(c.pos[1]), c.kind])
	kinds.sort()
	check_eq(kinds.map(func(k): return k[1]), ["chest_stone", "chest_small", "chest_small", "chest_small"],
		"a stone chest downstairs, two-row chests on the floors above and the roof (owner)")
	check_eq(plan.chests.filter(func(c): return c.kind == "barrel").size(), 2, "two storage barrels to live with (owner)")
	# Rubble up on a floor lies on whole floor, not over a hole (owner: "pebbles where the triangle floor should be").
	for p in plan.pieces:
		if p.id != "ruin_rubble" or float(p.pos[1]) < 0.5:
			continue
		var under := false
		for f in plan.pieces:
			var top := float(f.pos[1]) + (1.0 if String(f.id).begins_with("foundation") else 0.25)  # floor 1 = foundations
			if (f.id in ["floor", "floor_triangle"] or String(f.id).begins_with("foundation")) and absf(top - float(p.pos[1])) < 0.05 \
					and Vector2(float(f.pos[0]) - float(p.pos[0]), float(f.pos[2]) - float(p.pos[2])).length() < 1.0:
				under = true
		check(under, "rubble at %s lies on a floor" % [p.pos])


func test_built_in_the_first_cave_without_monsters() -> void:
	await _setup()
	var spot := RuinTower.find_spot(world.maker, 4.2, 9.0)
	check(not spot.is_empty(), "there's room for the tower in the first cave")
	if spot.is_empty():
		auth.get_parent().queue_free()
		return
	var d := Vector2(spot.pos.x - world.maker.cavern_spawn.x, spot.pos.z - world.maker.cavern_spawn.z).length()
	check(d >= 8.0 and d <= 26.0, "it stands near where you arrive, not on top of you (%.1f m away)" % d)
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"  # the test world has no camera to load rock around: carve straight away
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var plan := RuinTower.load_plan()
	var rubble: Array = plan.pieces.filter(func(p): return RuinTower.RUBBLE.has(p.id))
	check_eq(auth.builder.structure.pieces.size(), plan.pieces.size() - rubble.size(), "every piece of the ruin was built")
	check_eq(auth.builder.rubble.size(), rubble.size(), "the rubble and the broken door are rubble you can hit to clear (owner)")
	var o: Vector3 = RuinTower.last_origin  # (static: the job frees itself when done)
	var basis := Basis(Vector3.UP, RuinTower.last_turn * PI / 2.0)
	var floating := 0
	for rid in auth.builder.rubble:
		var at: Vector3 = auth.builder.rubble[rid].global_position
		if at.y - o.y < 0.5 and world.maker.sdf_at(at + Vector3.DOWN * 0.3) > 0.0:
			floating += 1
	check_eq(floating, 0, "no rubble on the ground floats (it rests on the rock)")
	var under := 0
	for k in 12:  # under every outer foundation corner there is rock (the tower stands on the floor, owner)
		var a := (k + 0.5) * TAU / 12.0
		var c: Vector3 = o + basis * Vector3(sin(a) * 3.6, 0, cos(a) * 3.6)
		if world.maker.sdf_at(c + Vector3.DOWN * 0.15) <= 0.0:
			under += 1
	check(under >= 1, "the tower touches the ground (%d of 12 corners on rock, the rest over lower dips)" % under)
	var blocked := 0
	for p in plan.pieces:
		if RuinTower.RUBBLE.has(p.id) and absf(float(p.pos[0])) < 1.6 and float(p.pos[2]) > 0.0 and float(p.pos[1]) < 1.5:
			blocked += 1
	check_eq(blocked, 0, "no rubble in the doorway, on the steps or in front of them (owner: I couldn't get in)")
	# F264: inside, nothing stands where you walk (between the middle and 2.6 m out), so you reach the roof without breaking anything
	var in_way := 0
	for p in plan.pieces:
		if RuinTower.RUBBLE.has(p.id) or p.id == "barrel":
			if float(p.pos[1]) > 0.5 and Vector2(float(p.pos[0]), float(p.pos[2])).length() < 2.75:
				in_way += 1
	for c in plan.chests + plan.get("props", []):
		if Vector2(float(c.pos[0]), float(c.pos[2])).length() < 2.75 and float(c.pos[1]) < 7.0:
			in_way += 1
	check_eq(in_way, 0, "inside, rubble, crates and chests stand against the walls, off the way up (F264)")
	check_eq(auth.storage.boxes.size(), 6, "its four chests and two barrels are there")
	check_eq(auth.stations.values().filter(func(st): return st.kind == "crystal_torch").size(), plan.get("torches", []).size(), "its crystal torches stand inside (F264)")
	var found := false
	for id in auth.storage.boxes:
		if auth.storage.boxes[id].inv.count_of("watchtower_plans") > 0:
			found = true
	check(found, "one chest holds the Watchtower Plans")
	check_eq(auth.monsters.count() if auth.monsters and auth.monsters.has_method("count") else 0, 0, "no monsters in the first-cave tower (owner)")
	auth.get_parent().queue_free()


func test_plans_teach_the_watchtower() -> void:
	check_eq(Items.info("watchtower_plans").get("teaches", ""), "stone_watchtower", "the plans teach the Stone Watchtower")
	check(BlueprintMenu.ready_made_keys().has("stone_watchtower"), "the watchtower can be learned (not a starter)")
