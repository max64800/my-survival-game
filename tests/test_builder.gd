extends TestCase
## Building and cave-ins in the real cave, through the referee.

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	var viewer := VoxelViewer.new()
	viewer.view_distance = 64
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 600:
		if world.is_ready_at(player.global_position, 8.0):
			break
		await tree.process_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


## A spot on the floor a few meters from the player, snapped like the build ghost does it.
## A flat, open spot about `dx` m from the player for this piece (looks around if the first try is in rock).
func _floor_spot(piece: String, dx: float) -> Dictionary:
	var first := {}
	for off in [Vector2(dx, 0), Vector2(-dx, 0), Vector2(0, dx), Vector2(0, -dx), Vector2(dx, dx), Vector2(-dx, -dx), Vector2(dx, -dx), Vector2(-dx, dx)]:
		var p := world.maker.find_floor(player.global_position.x + off.x, player.global_position.z + off.y, player.global_position.y + 2.0)
		var s := Pieces.snap(piece, p, Vector3.UP, 0.0, 0)
		if first.is_empty():
			first = s
		if Pieces.rock_problem(piece, s.pos, s.rot, world.sdf_at) == "":
			return s
	return first


func test_needs_a_workbench_and_materials() -> void:
	await _setup()
	var s := _floor_spot("floor", 3.0)
	check_eq(auth.builder.problem(ps, "floor", "plank_root", s.pos, s.rot), "Needs a Workbench within 20 m", "no workbench yet")
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	check(auth.builder.problem(ps, "floor", "plank_root", s.pos, s.rot).begins_with("Needs 4"), "no planks yet")
	ps.inventory.add("plank_root", 10)
	check_eq(auth.builder.request_place(1, "floor", "plank_root", s.pos, s.rot), "", "placed")
	check_eq(ps.inventory.count_of("plank_root"), 6, "4 planks used")
	check_eq(auth.builder.structure.pieces.size(), 1, "one piece")
	check(auth.builder.structure.pieces.values()[0].anchored, "a floor on the cave floor touches rock")
	check_eq(auth.builder.request_place(1, "floor", "plank_root", s.pos, s.rot), "Something is already there", "can't double-place")
	_teardown()


## Soft physics (building polish spec §5): a piece that loses its support creaks and shakes for
## about 2 s, then tumbles away harmlessly, dropping half its materials. Propped up in time = saved.
func test_soft_collapse_warns_then_tumbles() -> void:
	await _setup()
	var b: Builder = auth.builder
	var at := player.global_position + Vector3(0, 30, 0)  # up in the air: only what we say holds it
	b._ev_add_piece(1, "pillar", "plank_root", at, 0, true)
	b._ev_add_piece(2, "floor", "plank_root", at + Vector3(1, 2, 1), 0, false)
	b._ev_add_piece(3, "floor", "plank_root", at + Vector3(3, 2, 1), 0, false)
	var health := ps.vitals.health
	var drops_before := auth.drops_root.get_child_count()
	b._ev_remove_piece(1)  # the support goes
	await frames(5)
	check((b.nodes[2] as PieceNode)._shaking, "the floor starts shaking right away")
	for i in 60:
		await tree.physics_frame
	check(b.structure.pieces.has(2), "...but is still there after 1 s (a warning, not an instant fall)")
	for i in 120:
		await tree.physics_frame
	check(not b.structure.pieces.has(2) and not b.structure.pieces.has(3), "after the warning both floors gave way")
	check_eq(b.rubble.size(), 2, "both landed as rubble (F90)")
	check_near(ps.vitals.health, health, 0.01, "falling pieces don't hurt anyone")
	var rb: Rubble = b.rubble.values()[0]
	check(rb.collision_layer & World.TERRAIN_LAYER, "rubble is solid: you bump into it and can stand on it")
	ps.node.global_position = rb.global_position + Vector3(1, 0, 0)
	for i in Rubble.HITS - 1:
		check_eq(b.request_hit_rubble(1, rb.rubble_id), "hit", "pickaxe hit on rubble")
	check_eq(b.request_hit_rubble(1, rb.rubble_id), "cleared", "cleared after %d hits" % Rubble.HITS)
	check(auth.drops_root.get_child_count() > drops_before, "clearing it gives back half its materials")
	var snap := b.snapshot()
	check_eq(snap.rubble.size(), 1, "the other rubble is saved with the world")
	_teardown()


func test_propped_up_in_time_is_saved() -> void:
	await _setup()
	var b: Builder = auth.builder
	var at := player.global_position + Vector3(0, 30, 0)
	b._ev_add_piece(1, "pillar", "plank_root", at, 0, true)
	b._ev_add_piece(2, "floor", "plank_root", at + Vector3(1, 2, 1), 0, false)
	b._ev_remove_piece(1)
	await frames(5)
	b._ev_add_piece(4, "pillar", "copper_ingot", at + Vector3(2, 0, 2), 0, true)  # a new support, in time
	for i in 180:
		await tree.physics_frame
	check(b.structure.pieces.has(2), "propped up during the warning: the floor stays")
	check(not (b.nodes[2] as PieceNode)._shaking, "...and stops shaking")
	_teardown()


## Building polish spec §3: stations and their levels.
func test_station_levels_unlock_pieces() -> void:
	await _setup()
	var at := player.global_position + Vector3(-3, 0, 0)
	auth._ev_place_station(1, "workbench", at, 0.0)
	ps.inventory.add("plank_root", 20)
	ps.inventory.add("cut_stone", 20)
	var s := _floor_spot("roof_45", 3.0)
	check_eq(auth.builder.station_problem("roof_45", "plank_root", s.pos), "Needs Workbench level 2 (build a Chopping Block next to it)",
		"a steep wooden roof needs Workbench level 2")
	check_eq(auth.builder.station_problem("roof_26", "plank_root", s.pos), "", "a gentle roof is fine with any Workbench (F133)")
	auth._ev_place_station(2, "chopping_block", at + Vector3(6, 0, 0), 0.0)
	check_eq((auth.stations[1] as Station).level(), 1, "an extra 6 m away doesn't count")
	auth._ev_place_station(3, "chopping_block", at + Vector3(2, 0, 0), 0.0)
	auth._ev_place_station(4, "chopping_block", at + Vector3(0, 0, 2), 0.0)
	check_eq((auth.stations[1] as Station).level(), 2, "two Chopping Blocks nearby: still only level 2 (each extra counts once)")
	check_eq(auth.builder.station_problem("roof_45", "plank_root", s.pos), "", "now the steep roof is allowed")
	check_eq(auth.builder.station_problem("floor", "cut_stone", s.pos), "Needs a Mason's Table within 20 m", "stone needs a Mason's Table")
	auth._ev_place_station(5, "masonry_table", at + Vector3(0, 0, -3), 0.0)
	check_eq(auth.builder.station_problem("floor", "cut_stone", s.pos), "", "with the Mason's Table, stone floors are fine")
	check_eq(auth.builder.station_problem("column", "cut_stone", s.pos), "Needs Mason's Table level 2 (build a Chisel Rack next to it)",
		"carved columns need a Chisel Rack")
	check_eq(Station.max_level("workbench"), 4, "the Workbench goes up to level 4")
	_teardown()


func test_pick_up_right_after_placing_or_break_for_80_percent() -> void:
	await _setup()
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	auth._ev_place_station(2, "masonry_table", player.global_position + Vector3(-3, 0, 3), 0.0)
	ps.inventory.add("cut_stone", 4)
	var s := _floor_spot("floor", 3.0)
	auth.builder.request_place(1, "floor", "cut_stone", s.pos, s.rot)
	var uid: int = auth.builder.structure.pieces.keys()[0]
	check_eq(auth.builder.request_remove(1, uid), "", "picked up right after placing")
	check_eq(ps.inventory.count_of("cut_stone"), 4, "100% back")
	check(auth.builder.structure.pieces.is_empty(), "gone")
	# Later than 10 s: no free pick-up; breaking it gives 80% (4 stone -> 3).
	auth.builder.request_place(1, "floor", "cut_stone", s.pos, s.rot)
	uid = auth.builder.structure.pieces.keys()[0]
	auth.builder._clock += Builder.PICKUP_TIME + 1.0
	check(auth.builder.request_remove(1, uid) != "", "too late for a careful pick-up")
	check(auth.builder.structure.pieces.has(uid), "so it stays")
	check_eq(auth.builder.request_remove(1, uid, true), "", "breaking it works any time")
	check_eq(ps.inventory.count_of("cut_stone"), 3, "and gives back 80%")
	# Crafting stations always come back whole.
	auth._ev_place_station(9, "campfire", player.global_position + Vector3(2, 0, 0), 0.0)
	check_eq(auth.request_pickup_station(1, 9), "", "a station can be picked up any time")
	check(not auth.stations.has(9) and ps.inventory.count_of("campfire") == 1, "and you get the campfire back")
	_teardown()


func test_cant_build_inside_rock() -> void:
	await _setup()
	auth._ev_place_station(1, "workbench", player.global_position + Vector3(-3, 0, 0), 0.0)
	ps.inventory.add("plank_root", 10)
	var s := _floor_spot("wall", 3.0)
	check(auth.builder.problem(ps, "wall", "plank_root", s.pos + Vector3.DOWN * 3.0, s.rot).begins_with("Inside rock"), "buried wall refused")
	_teardown()


func test_normal_digging_no_cave_in() -> void:
	await _setup()
	var below := player.global_position + Vector3.DOWN * 3.0
	world.apply_dig(below, 1.35)
	var box := CaveIns.box_for(below)
	for i in 900:
		if world.copy_area(box[0], box[1]) != null:
			break
		await tree.process_frame
	check(world.copy_area(box[0], box[1]) != null, "the area around the dig loaded")
	var t := Time.get_ticks_usec()
	var falls := auth.builder._run_check(below, 1.35)
	print("        (real-cave check: %.1f ms)" % ((Time.get_ticks_usec() - t) / 1000.0))
	check(falls.is_empty(), "digging the floor doesn't make rock fall")
	_teardown()


func test_cave_in_removes_rock_and_drops_rubble() -> void:
	await _setup()
	var spot := player.global_position + Vector3(0, -4, 0)
	var pts := PackedVector3Array()
	for x in 2:
		for y in 2:
			for z in 2:
				pts.append((spot + Vector3(x, y, z)).round())
	check(world.sdf_at(spot) < 0.0, "rock there before")
	auth.builder._ev_cave_in(pts)
	check(world.sdf_at(spot) > 0.0, "air after the cave-in")
	check_eq(auth.builder.fall_log.size(), 1, "logged for late joiners")
	check(auth.drop_count() >= 1, "rubble dropped some items")
	_teardown()


func test_mine_prop_marks_support() -> void:
	await _setup()
	auth.builder._ev_add_piece(5, "mine_prop", "plank_root", Vector3(0, 0, 0), 0, true)
	var sp := auth.builder.support_points()
	check_eq(sp.size(), 3, "a prop holds rock at 3 points on its top")
	check(sp[0].y > 3.0, "points are above the prop (it's 3 m tall)")
	_teardown()


func test_blueprint_builds_itself() -> void:
	await _setup()
	var json := FileAccess.get_file_as_string("res://blueprints/small_rootwood_lodge.dwbp")
	var origin := world.maker.find_floor(player.global_position.x + 6.0, player.global_position.z, player.global_position.y + 2.0).round()
	var chest_pos := world.maker.find_floor(origin.x, origin.z + 5.0, origin.y + 3.0)
	check_eq(auth.builder.request_place_blueprint(1, "nonsense", origin, 0, chest_pos), "This isn't a blueprint file.", "junk refused")
	check_eq(auth.builder.request_place_blueprint(1, json, origin, 0, chest_pos), "", "lodge placed")
	check_eq(auth.builder.sites.size(), 1, "one build site")
	var box_id: int = auth.builder.sites.keys()[0]
	check_eq(auth.storage.get_box(box_id).kind, "builder", "a Builder's Chest came with it")
	# Run the site with an empty chest: it carves, then waits for materials.
	for i in 400:
		auth.builder._site_ticks += 1
		auth.builder._tick_sites()
		if auth.builder.site_status(box_id).contains("needs"):
			break
	var status := auth.builder.site_status(box_id)
	check(status.begins_with("Step 1 of"), "asks for materials step by step (%s)" % status)
	# Step 1 asks for ALL of its materials at once, not a few at a time.
	var site: Dictionary = auth.builder.sites[box_id]
	var steps := Builder.site_steps(site.plan)
	if steps.count > 1:
		check(status.contains("Whole building still needs"), "and shows what the whole building needs (F112)")
	var step1 := []
	for i in site.plan.size():
		if steps.band_of[i] == steps.current:
			step1.append(i)
	var need := Builder.missing_for(site.plan, step1, auth.storage.get_box(box_id).inv)
	for item in need:
		check(status.contains("%d %s" % [need[item], Items.display_name(item)]), "step 1 asks for all %d %s" % [need[item], Items.display_name(item)])
	for item in {plank_root = 39, cut_stone = 36, copper_ingot = 2}:
		auth.storage.put(box_id, item, {plank_root = 39, cut_stone = 36, copper_ingot = 2}[item])
	for i in 120:
		auth.builder._site_ticks += 1
		auth.builder._tick_sites()
		if auth.builder.sites.is_empty():
			break
	var built := auth.builder.structure.pieces.size()
	print("        (lodge: %d of 20 pieces built, status: %s)" % [built, auth.builder.site_status(box_id)])
	check(built >= 15, "most of the lodge got built (%d of 20)" % built)
	_teardown()


## Dev menu (P): any ready-made blueprint, then P in its Builder's Chest fills it with everything still needed.
func test_dev_fill_builders_chest() -> void:
	await _setup()
	check_eq(DevMenu.all_blueprints().size(), BlueprintLibrary.IDS.size() + 1, "every ready-made blueprint, learned or not")
	var json := BlueprintLibrary.make("delvers_hut").to_json()
	var origin := world.maker.find_floor(player.global_position.x + 6.0, player.global_position.z, player.global_position.y + 2.0).round()
	var chest_pos := world.maker.find_floor(origin.x, origin.z + 7.0, origin.y + 3.0)
	check_eq(auth.builder.request_place_blueprint(1, json, origin, 0, chest_pos), "", "hut placed")
	var box_id: int = auth.builder.sites.keys()[0]
	check(auth.builder.request_dev_fill(1, box_id).begins_with("Dev: filled"), "P fills the chest")
	var site: Dictionary = auth.builder.sites[box_id]
	var all := range(site.plan.size())
	var in_chest: int = auth.storage.get_box(box_id).inv.count_of("plank_root")
	var dropped := 0
	for d in auth.drops_root.get_children():
		if d.get("item_id") == "plank_root":
			dropped += int(d.get("count"))
	check_eq(in_chest + dropped, 296, "exactly what the hut needs: 296 planks (in the chest, the rest beside it)")
	check(Builder.missing_for(site.plan, all, auth.storage.get_box(box_id).inv).is_empty() or dropped > 0, "nothing missing")
	check(auth.builder.request_dev_fill(1, 9999).begins_with("Dev: that's not"), "only Builder's Chests")
	_teardown()


func test_doors_open_and_ladders_climb() -> void:
	await _setup()
	var pos := player.global_position + Vector3(1, 0, 0)
	auth.builder._ev_add_piece(500, "door", "plank_root", pos, 0, true)
	var node: PieceNode = auth.builder.nodes[500]
	check(auth.builder.request_door(1, 500), "you can open a door next to you")
	check(auth.builder.structure.pieces[500].open != 0, "it's open")
	check(node.is_open, "the door swings open")
	var saved: Dictionary = auth.builder.snapshot()
	check(auth.builder.request_door(1, 500), "and close it again")
	check_eq(auth.builder.structure.pieces[500].open, 0, "closed")
	check(saved.pieces[0][6] != 0, "an open door stays open after saving")
	# F160: it opens AWAY from you, from either side
	player.global_position = pos + Vector3(0, 0, 1.5)  # in front of the door
	auth.builder.request_door(1, 500)
	check_eq(auth.builder.structure.pieces[500].open, -1, "from the front it swings to the back")
	auth.builder.request_door(1, 500)
	player.global_position = pos + Vector3(0, 0, -1.5)  # behind it
	auth.builder.request_door(1, 500)
	check_eq(auth.builder.structure.pieces[500].open, 1, "from the back it swings to the front")
	auth.builder._ev_door(500, 0)
	auth.builder.load_snapshot({pieces = [[503, "door", "plank_root", pos + Vector3(0, 0, 8), 0, true, true]]})
	check_eq(auth.builder.structure.pieces[503].open, 1, "an old save's open door (true) still opens")
	player.global_position = pos - Vector3(1, 0, 0)
	auth.builder._ev_add_piece(501, "wall", "plank_root", pos + Vector3(4, 0, 0), 0, true)
	check(not auth.builder.request_door(1, 501), "walls don't open")
	auth.builder._ev_add_piece(502, "ladder", "plank_root", pos + Vector3(0, 0, 3), 0, true)
	check(auth.builder.ladder_at(pos + Vector3(0.3, 1.0, 3.2)), "standing at a built ladder = climbing")
	check(not auth.builder.ladder_at(pos + Vector3(0, 1.0, 6)), "away from it = not climbing")
	auth.builder._ev_remove_piece(502)
	check(not auth.builder.ladder_at(pos + Vector3(0.3, 1.0, 3.2)), "a taken-down ladder can't be climbed")
	_teardown()


## F113: cave-in rocks are lumpy rocks in several different shapes, not cubes.
func test_falling_rocks_are_rock_shaped() -> void:
	var a := Builder.rock_mesh(0)
	var b := Builder.rock_mesh(1)
	check(a.get_faces().size() > 36, "more faces than a cube")
	check(a.get_faces() != b.get_faces(), "different variants have different shapes")
	check_eq(Builder.rock_mesh(0), a, "the same variant is reused (no new mesh every time)")
	var box := a.get_aabb()
	check(box.size.x > 0.6 and box.size.x < 1.4, "about 1 m across")


## F112: a two-floor plan is built in two steps, the lower floor first.
func test_blueprint_steps_go_floor_by_floor() -> void:
	var plan := [
		{piece = "floor", family = "plank_root", pos = Vector3(0, 0, 0), rot = 0, built = false},
		{piece = "wall", family = "plank_root", pos = Vector3(0, 0.25, 1), rot = 0, built = false},
		{piece = "floor", family = "plank_root", pos = Vector3(0, 2.25, 0), rot = 0, built = false},
	]
	var steps := Builder.site_steps(plan)
	check_eq(steps.count, 2, "two steps: ground floor, upper floor")
	check_eq(steps.number, 1, "starts with step 1")
	check(steps.band_of[0] == steps.current and steps.band_of[1] == steps.current, "the floor and its walls are step 1")
	check(steps.band_of[2] != steps.current, "the upper floor waits")
	plan[0].built = true
	plan[1].built = true
	check_eq(Builder.site_steps(plan).number, 2, "then step 2")
	var inv := Inventory.new()
	inv.add("plank_root", 3)
	var need := Builder.missing_for(plan, [2], inv)
	check_eq(need.get("plank_root", 0), Pieces.cost("floor", "plank_root").plank_root - 3, "it counts what's already in the chest")


## F115: the Fang Pickaxe needs a level-2 Workbench (a Chopping Block next to it).
func test_fang_pickaxe_needs_workbench_level_2() -> void:
	await _setup()
	auth._ev_place_station(40, "workbench", player.global_position + Vector3(2, 0, 0), 0.0)
	ps.seen["bat_fang"] = true
	ps.inventory.add("pickaxe_stone", 1)
	ps.inventory.add("bat_fang", 4)
	ps.inventory.add("leather", 1)
	check(not auth.request_craft(1, "pickaxe_fang", 40), "a plain Workbench can't make it")
	auth._ev_place_station(41, "chopping_block", player.global_position + Vector3(3.5, 0, 1.5), 0.0)
	check_eq(auth.stations[40].level(), 2, "with a Chopping Block it's level 2")
	check(auth.request_craft(1, "pickaxe_fang", 40), "now it can")
	check_eq(ps.inventory.count_of("pickaxe_fang"), 1, "a Fang Pickaxe")
	_teardown()
