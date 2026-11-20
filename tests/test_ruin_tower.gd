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
	check_eq(auth.storage.boxes.size(), 7, "its four chests, two barrels and the Rebuilding Chest are there")
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


## F350 🔁 (owner, Nov 19: "there is no chest to rebuild the tower"; a merge had wiped the code): the Rebuilding Chest
## is there, in open air beside the path (never buried, never on the steps), and opening it says what it is, what it
## needs and what you get.
func test_rebuilding_chest_is_there_and_explains_itself() -> void:
	await _setup()
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var box := RuinTower.last_rebuild_box
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the ruin has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		auth.get_parent().queue_free()
		return
	var at: Vector3 = (auth.storage.boxes[box].node as Node3D).global_position
	check(world.maker.sdf_at(at + Vector3.UP * 0.6) > 0.3 and world.maker.sdf_at(at + Vector3.UP * 1.4) > 0.3, "it stands in open air, not buried")
	check(world.maker.sdf_at(at + Vector3.DOWN * 0.3) <= 0.2, "it stands on the floor, not floating")
	var local := Basis(Vector3.UP, RuinTower.last_turn * PI / 2.0).inverse() * (at - RuinTower.last_origin)
	check(absf(local.x) > 2.6 or local.z > 6.5, "it stands beside the steps, not on them (%.1f, %.1f)" % [local.x, local.z])
	var text := auth.builder.ruin_intro(box)
	check("Fix the old tower" in text and "broken" in text, "opening it says what it is: only the broken parts")
	check(text.length() < 120, "short (owner F411: it was far too long): %d letters" % text.length())
	var ways := auth.builder.ruin_choices(box)
	check_eq(ways.size(), 2, "two pictures: wood and stone")
	if ways.size() == 2:
		check_eq(String(ways[0].key), "wooden_watchtower", "wood -> the wooden tower")
		check_eq(String(ways[1].key), "stone_watchtower", "stone -> the stone tower")
		check(Items.display_name("plank_root") in String(ways[0].needs), "the wood picture lists the planks it needs")
		check(Items.display_name("cut_stone") in String(ways[1].needs), "the stone picture lists the stone it needs")
	var pic := auth.builder.ruin_picture(box)  # F431: one picture of the ruin, the broken parts marked
	var kinds := {}
	for p in pic:
		kinds[p.fix] = kinds.get(p.fix, 0) + 1
	check(kinds.get("", 0) > 0, "the picture shows the whole pieces that stay (%s)" % kinds)
	check(kinds.get("broken", 0) + kinds.get("missing", 0) > 0, "and marks the broken or missing ones (%s)" % kinds)
	var r: Dictionary = auth.world_state.ruins[str(box)]
	var wood := auth.builder.ruin_needs("wooden_watchtower", r)
	var whole := 0
	var bp := BlueprintLibrary.make("wooden_watchtower")
	for p in bp.pieces:
		whole += int(Pieces.cost(p.id, p.mat).get("plank_root", 0))
	check(wood.get("plank_root", 0) > 0, "the wooden tower needs root planks (%s)" % [wood])
	check(int(wood.get("plank_root", 0)) < whole, "what still stands isn't counted (%d of %d planks)" % [wood.get("plank_root", 0), whole])
	# Owner, Nov 20: walls with only a stone or two missing (worn walls) stay as they are: not rebuilt, not paid for.
	var worn_marked := pic.filter(func(e): return e.piece == "ruin_wall_worn" and e.fix != "")
	check_eq(worn_marked.size(), 0, "worn walls are shown as staying, not as broken")
	check(int(wood.get("plank_root", 0)) <= 260, "worn walls aren't paid for: %d planks (was 447)" % wood.get("plank_root", 0))
	# ...but fixing in stone closes those gaps too (owner, Nov 20): the worn walls are rebuilt and paid for.
	var stone := auth.builder.ruin_needs("stone_watchtower", r)
	check(int(stone.get("cut_stone", 0)) >= 450, "stone rebuilds the worn walls too: %d cut stone" % stone.get("cut_stone", 0))
	auth.get_parent().queue_free()


## Old worlds (owner, Nov 19): a save from before the Rebuilding Chest has the tower but no chest; loading it adds one
## in the same place a new world would get it. A world without the tower standing there gets none.
func test_old_world_gets_its_rebuilding_chest() -> void:
	await _setup()
	var none := RuinTower.add_missing_chest(auth)  # nothing built yet: like a world from before the tower
	check(none != null, "a world with no ruin chest is looked at")
	check(not is_instance_valid(none) or none.is_queued_for_deletion(), "no tower standing: it gives up at once")
	await tree.process_frame
	check_eq(auth.storage.boxes.values().filter(func(b): return b.kind == "rebuild").size(), 0, "and adds no chest")
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var first := RuinTower.last_rebuild_box
	var first_at: Vector3 = (auth.storage.boxes[first].node as Node3D).global_position
	auth.storage._ev_remove_box(first)  # now it's an old world: the tower, but no chest and no ruin record
	auth.world_state.erase("ruins")
	RuinTower.last_rebuild_box = -1
	var again := RuinTower.add_missing_chest(auth)
	check(again != null and is_instance_valid(again) and not again.is_queued_for_deletion(), "the tower is found standing")
	if again:
		again._state = "chest"  # (no camera in the test world to load rock around)
	for i in 30:
		if not is_instance_valid(again):
			break
		await tree.process_frame
	var box := RuinTower.last_rebuild_box
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "loading the old world adds the Rebuilding Chest")
	if auth.storage.boxes.has(box):
		var at: Vector3 = (auth.storage.boxes[box].node as Node3D).global_position
		check(at.distance_to(first_at) < 0.05, "in the same place a new world gets it (%s vs %s)" % [at, first_at])
		check("Fix the old tower" in auth.builder.ruin_intro(box), "and it works like a new world's")
	check(RuinTower.add_missing_chest(auth) == null, "loading it again adds no second chest")
	auth.get_parent().queue_free()


## Rebuilding a ruin (owner, Nov 19; docs/design/ruin-rebuild-plan.md): root planks in the Rebuilding Chest rebuild
## the tower in wood, piece by piece; broken walls and rubble go; at the end everyone knows the Wooden Watchtower,
## gets crafting experience, and the chest is gone.
func test_rebuild_the_ruin_in_wood() -> void:
	await _setup()
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var box := RuinTower.last_rebuild_box
	check(auth.storage.boxes.has(box), "the ruin has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
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
	var worn_left := 0
	for uid in b.structure.pieces:
		var id := String(b.structure.pieces[uid].piece)
		if id in Builder.RUIN_KEEP:
			worn_left += 1  # owner, Nov 20: worn walls (a stone or two missing) stay
		elif id.begins_with("ruin_"):
			ruin_left += 1
	check_eq(ruin_left, 0, "no collapsed walls left")
	check(worn_left > 0, "the worn walls still stand (%d)" % worn_left)
	check((auth.world_state.get("blueprints", []) as Array).has("wooden_watchtower"), "everyone knows the Wooden Watchtower")
	check(auth.world_state.ruins[str(box)].done, "the world remembers it's rebuilt")
	check(not auth.storage.boxes.has(box), "the Rebuilding Chest is gone once the tower stands (owner)")
	var xp_after: int = int(ps.progress.skill_xp.get("crafting", 0)) + int(ps.progress.skill_level.get("crafting", 0)) * 100000
	check(xp_after > xp_before, "crafting experience for it")
	auth.get_parent().queue_free()
