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
