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
	check_eq(plan.chests.size(), 4, "a chest on every floor and the roof")


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
	check_eq(auth.builder.structure.pieces.size(), plan.pieces.size(), "every piece of the ruin was built")
	check_eq(auth.storage.boxes.size(), 4, "its four chests are there")
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
