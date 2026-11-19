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
	check_eq(auth.storage.boxes.size(), 5, "its four chests and the Rebuilding Chest are there")
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


## Rebuilding a ruin (owner, Nov 19; docs/design/ruin-rebuild-plan.md): root planks in the Rebuilding Chest rebuild
## the tower in wood, piece by piece; broken walls and rubble go; at the end everyone knows the Wooden Watchtower and
## gets crafting experience.
func test_rebuild_the_ruin_in_wood() -> void:
	await _setup()
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var box := -1
	for id in auth.storage.boxes:
		if auth.storage.boxes[id].kind == "rebuild":
			box = id
	check(box >= 0, "the ruin has a Rebuilding Chest")
	if box < 0:
		auth.get_parent().queue_free()
		return
	auth.storage.put(box, "plank_root", 5)
	var b: Builder = auth.builder
	check(b.sites.has(box), "planks in the chest start rebuilding")
	check_eq(b.sites.get(box, {}).get("ruin", ""), "wooden_watchtower", "in wood")
	var site: Dictionary = b.sites[box]
	var already := 0
	for p in site.plan:
		if p.built:
			already += 1
	check(already > site.plan.size() / 3, "what still stands whole counts as done (%d of %d)" % [already, site.plan.size()])
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
	var chest: Dictionary = auth.storage.get_box(box)
	ps.node.global_position = chest.node.global_position + Vector3(1.2, 0.2, 0.0)
	var xp_before: int = int(ps.progress.skill_xp.get("crafting", 0)) + int(ps.progress.skill_level.get("crafting", 0)) * 100000
	for k in 3000:
		if not b.sites.has(box):
			break
		b._site_ticks += 1  # (as the game's clock does: it builds every second step)
		b._tick_sites()
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var ruin_left := 0
	for uid in b.structure.pieces:
		if String(b.structure.pieces[uid].piece).begins_with("ruin_"):
			ruin_left += 1
	check_eq(ruin_left, 0, "no broken walls left")
	check((auth.world_state.get("blueprints", []) as Array).has("wooden_watchtower"), "everyone knows the Wooden Watchtower")
	check(auth.world_state.ruins[str(box)].done, "the world remembers it's rebuilt")
	var xp_after: int = int(ps.progress.skill_xp.get("crafting", 0)) + int(ps.progress.skill_level.get("crafting", 0)) * 100000
	check(xp_after > xp_before, "crafting experience for it")
	auth.get_parent().queue_free()
