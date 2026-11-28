extends TestCase
## Lootable decor (handover Nov 22, section 4; LootProps): E gives the prop's few items once, the model swaps to its
## _empty twin for everyone, and it stays looted after save/load. One code path for dungeon and ruin plans.
## The special pieces: bv_strongbox's lid opens, bv_vault_door_forced's round doorway is walk-through and
## vo_spyhole_wall's spyhole is see-through (their collision boxes leave the openings free).

var root: Node3D
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	root = Node3D.new()
	tree.root.add_child(root)
	auth = GameAuthority.new()
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	player = Node3D.new()
	root.add_child(player)
	ps = auth.add_player(1, player)


func _teardown() -> void:
	root.queue_free()


static func _shown(lp: LootProps, key: String) -> String:
	return String((lp.props[key].inst as Node).scene_file_path).get_file()


func test_the_loot_table() -> void:
	for id in LootProps.LOOT:
		check(ResourceLoader.exists("res://assets/models/decor/%s.glb" % id), "%s has its model" % id)
		var lid: bool = id == "bv_strongbox"
		check(lid or ResourceLoader.exists("res://assets/models/decor/%s_empty.glb" % id), "%s has its _empty twin" % id)
		for item in LootProps.LOOT[id]:
			check(Items.exists(String(item)), "%s gives %s, an item the game has" % [id, item])
		check(LootProps.NAMES.has(id), "%s has a name for the aim line" % id)
	for f in DirAccess.get_files_at("res://assets/models/decor"):
		if f.ends_with("_empty.glb"):
			check(LootProps.LOOT.has(f.trim_suffix("_empty.glb")), "%s's full model is in the loot table" % f)
	check(LootProps.is_lootable({model = "decor/hw_ingot_cart.glb", role = "lootable"}), "role lootable + a table id")
	check(not LootProps.is_lootable({model = "decor/hw_ingot_cart.glb", role = "decor"}), "the same model as decor isn't")
	check(not LootProps.is_lootable({model = "decor/keg.glb", role = "lootable"}), "nothing in the table: not lootable")


func test_it_gives_its_items_once_and_goes_empty() -> void:
	_setup()
	var lp := auth.loot_props
	check(lp != null and lp.get_parent() == auth and lp.name == "LootProps", "LootProps sits on the GameAuthority (same path everywhere)")
	lp.place("d:test:3", "decor/ro_quiver_rack.glb", Transform3D(Basis.IDENTITY, Vector3(1, 0, 0)), "Old crossbow rack")
	var info := lp.use_info("d:test:3")
	check_eq(info.get("loot_key", ""), "d:test:3", "E takes")
	check_eq(String(info.get("name", "")), "Old crossbow rack · E to take", "named by the plan's label (the HUD shows only \"E to take\")")
	check_eq(LootProps.key_of(lp.props["d:test:3"].node), "d:test:3", "aiming at it finds it")
	check_eq(_shown(lp, "d:test:3"), "ro_quiver_rack.glb", "full at first")
	check(lp.request_loot(1, "d:test:3"), "looted")
	check_eq(ps.inventory.count_of("crossbow_stone"), 1, "the crossbow")
	check_eq(ps.inventory.count_of("bolt_stone"), 5, "and 5 bolts")
	check_eq(_shown(lp, "d:test:3"), "ro_quiver_rack_empty.glb", "it swaps to its empty twin")
	check(auth.world_state.props_looted.has("d:test:3"), "kept in the world state (saved, sent to friends)")
	check(lp.use_info("d:test:3").is_empty(), "empty: E does nothing")
	check(not lp.request_loot(1, "d:test:3"), "it gives only once")
	check_eq(ps.inventory.count_of("bolt_stone"), 5, "no more bolts")
	lp.place("d:test:4", "decor/cf_charcoal_bay.glb", Transform3D(Basis.IDENTITY, Vector3(30, 0, 0)))
	check(not lp.request_loot(1, "d:test:4"), "too far away: nothing")
	check_eq(ps.inventory.count_of("coal"), 0, "no coal from 30 m")
	check_eq(String(lp.use_info("d:test:4").name), "Charcoal bay · E to take", "no label: the table's name")
	check(lp.props["d:test:4"].node.is_in_group(RuinKit.GROUP), "the pickaxe doesn't dig through it")
	_teardown()


## Co-op: a friend asks -> the host gives the items to the friend -> every computer shows it empty (a friend's
## computer gets the host's world state and shows it the same).
func test_request_host_everyone() -> void:
	_setup()
	var lp := auth.loot_props
	var friend := Node3D.new()
	root.add_child(friend)
	friend.global_position = Vector3(0, 0, 1)
	var fs := auth.add_player(2, friend)
	lp.place("r:5:0", "decor/bv_coin_chest_tipped.glb", Transform3D.IDENTITY)
	check(lp.request_loot(2, "r:5:0"), "the friend's E: the host lets them take it")
	check_eq(fs.inventory.count_of("gold_coin"), 60, "the friend gets the 60 coins")
	check_eq(ps.inventory.count_of("gold_coin"), 0, "the host gets none")
	check(not lp.request_loot(1, "r:5:0"), "first come, first served")
	check_eq(_shown(lp, "r:5:0"), "bv_coin_chest_tipped_empty.glb", "the host sees it empty")
	# The friend's computer: its own GameAuthority with the same prop, told the host's world state.
	var root2 := Node3D.new()
	tree.root.add_child(root2)
	var auth2 := GameAuthority.new()
	root2.add_child(auth2)
	auth2.loot_props.place("r:5:0", "decor/bv_coin_chest_tipped.glb", Transform3D.IDENTITY)
	check_eq(_shown(auth2.loot_props, "r:5:0"), "bv_coin_chest_tipped.glb", "full until the news arrives")
	auth2._ev_state(auth.world_state)
	auth2.loot_props.apply_looted()
	check_eq(_shown(auth2.loot_props, "r:5:0"), "bv_coin_chest_tipped_empty.glb", "everyone sees it empty")
	root2.free()
	_teardown()


func test_it_stays_looted_after_save_and_load() -> void:
	_setup()
	auth.loot_props.place("d:mossgate:12", "decor/hw_ingot_cart.glb", Transform3D.IDENTITY)
	auth.loot_props.request_loot(1, "d:mossgate:12")
	check_eq(ps.inventory.count_of("copper_ingot"), 3, "3 ingots")
	var saved: Dictionary = bytes_to_var(var_to_bytes(auth.world_state))  # (the save file keeps the world state like this)
	_teardown()
	_setup()  # a new game loads the save: the world state first, then the props are placed (a ruin's come later)
	auth._ev_state(saved)
	auth.loot_props.place("d:mossgate:12", "decor/hw_ingot_cart.glb", Transform3D.IDENTITY)
	check_eq(_shown(auth.loot_props, "d:mossgate:12"), "hw_ingot_cart_empty.glb", "still empty after loading")
	check(not auth.loot_props.request_loot(1, "d:mossgate:12"), "and it gives nothing again")
	_teardown()
	_setup()  # or the props first, then the world state (a friend joining)
	auth.loot_props.place("d:mossgate:12", "decor/hw_ingot_cart.glb", Transform3D.IDENTITY)
	auth._ev_state(saved)
	auth.loot_props.apply_looted()
	check_eq(_shown(auth.loot_props, "d:mossgate:12"), "hw_ingot_cart_empty.glb", "empty once the world state arrives")
	_teardown()


## The same code path from a dungeon plan and a ruin plan (the contract other chats write).
func test_dungeon_and_ruin_plans() -> void:
	var plan := {props = [
		{model = "decor/rune_shield.glb", pos = [1, 0, 1], yaw = 0, role = "decor"},
		{model = "decor/cf_ingot_stack.glb", pos = [4, 0, 2], yaw = 90, scale = 1.0, role = "lootable", label = "Bronze pile"},
	]}
	var m := CaveMaker.new(42)
	if not m.dungeons.is_empty():
		var d: Dictionary = m.dungeons[0]
		var batched := DungeonBuild.placements(d, plan, true)
		check(not batched.has("decor/cf_ingot_stack.glb"), "a lootable prop isn't drawn in the batches")
		check(batched.has("decor/rune_shield.glb"), "ordinary decor still is")
		check(DungeonBuild.placements(d, plan, false).has("decor/cf_ingot_stack.glb"), "the full list (3D page) still shows it")
		_setup()
		DungeonBuild.place_lootables(auth.loot_props, d, plan)
		var key := "d:%s:1" % d.id
		check(auth.loot_props.props.has(key), "the dungeon's lootable prop is placed, keyed by its prop index")
		check_eq(auth.loot_props.props.size(), 1, "only the lootable one")
		var at: Vector3 = (auth.loot_props.props[key].xform as Transform3D).origin
		check(at.distance_to(DungeonMap.to_world(d, Vector3(4, 0, 2))) < 0.01, "where the plan says")
		check_eq(String(auth.loot_props.use_info(key).name), "Bronze pile · E to take", "with its label")
		_teardown()
	_setup()
	auth.loot_props.place_ruin("7", {name = "tower", origin = Vector3(10, 2, 5), turn = 1}, plan)
	check(auth.loot_props.props.has("r:7:1"), "a ruin's lootable prop is placed, keyed by the ruin and its index")
	var jk: Array = auth.loot_props.props.keys().filter(func(k): return String(k).begins_with("r:7:j"))
	check_eq(jk.size(), 1, "the tower's lootable catalogue piece (its junk list) is placed too")
	if jk.size() == 1:
		check(String(auth.loot_props.props[jk[0]].model).ends_with("rt_arrow_crate_spill.glb"), "the bolt crate")
	var t: Transform3D = auth.loot_props.props["r:7:1"].xform
	check(t.origin.distance_to(Vector3(10, 2, 5) + Basis(Vector3.UP, PI / 2.0) * Vector3(4, 0, 2)) < 0.01, "turned with the ruin")
	player.global_position = t.origin
	check(auth.loot_props.request_loot(1, "r:7:1"), "looted in the ruin")
	check_eq(ps.inventory.count_of("copper_ingot"), 3, "3 ingots (bronze: the closest ingot the game has)")
	# The ruins in the world state are read on their own (every computer, the same keys).
	auth.world_state["ruins"] = {"9": {name = "outpost", origin = Vector3(50, 0, 0), turn = 0}}
	auth.loot_props._process(1.0)
	check(auth.loot_props._ruins_placed.has("9"), "a ruin in the world state is looked at once")
	_teardown()


## bv_strongbox: a chest-like prop. E opens its lid (it swings up on its back hinge and stays open), gives its coins.
func test_the_strongbox_lid_opens() -> void:
	_setup()
	var lp := auth.loot_props
	lp.place("d:brassgate:1", "decor/bv_strongbox.glb", Transform3D.IDENTITY)
	var body: StaticBody3D = lp.props["d:brassgate:1"].node
	var lid := ChestOpen.lid_of(body)
	check(lid != null, "the model has its lid part (kit.save lid=) named \"lid\"")
	if lid == null:
		_teardown()
		return
	check(is_zero_approx(lid.rotation.x), "shut at first")
	check(lp.request_loot(1, "d:brassgate:1"), "E opens it")
	check_eq(ps.inventory.count_of("gold_coin"), 30, "its coins")
	check_eq(_shown(lp, "d:brassgate:1"), "bv_strongbox.glb", "the same model (the lid opens, no swap)")
	var tw: Tween = lid.get_meta("lid_tween") if lid.has_meta("lid_tween") else null
	check(tw != null and tw.is_valid(), "the lid swings open")
	if tw and tw.is_valid():
		await tw.finished
	check_near(lid.rotation.x, ChestOpen.OPEN_ANGLE, 0.05, "the lid stands open")
	_teardown()
	_setup()  # after loading: it is open at once
	auth.world_state["props_looted"] = ["d:brassgate:1"]
	auth.loot_props.place("d:brassgate:1", "decor/bv_strongbox.glb", Transform3D.IDENTITY)
	check_near(ChestOpen.lid_of(auth.loot_props.props["d:brassgate:1"].node).rotation.x, ChestOpen.OPEN_ANGLE, 0.01, "loaded: open")
	_teardown()


## A body with the model's collision boxes (as DungeonBuild gives a placed prop), in the real physics world.
func _body(model: String, t: Transform3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	root.add_child(body)
	var inst := (load("res://assets/models/" + model) as PackedScene).instantiate() as Node3D
	var whole := AABB()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		whole = whole.merge(DungeonBuild._rel_xform(inst, mi as Node3D) * (mi as MeshInstance3D).get_aabb())
	inst.free()
	DungeonBuild.add_boxes(body, model, t, whole)
	return body


func _ray(t: Transform3D, a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(t * a, t * b, World.TERRAIN_LAYER)
	return not root.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## The model itself: does a ray along z at (x, y) pass through its mesh?
static func _mesh_open(model: String, x: float, y: float) -> bool:
	var inst := (load("res://assets/models/" + model) as PackedScene).instantiate()
	var open := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		if not (mi as MeshInstance3D).mesh.generate_triangle_mesh().intersect_ray(Vector3(x, y, 3), Vector3(0, 0, -1)).is_empty():
			open = false
	inst.free()
	return open


func test_the_forced_vault_door_is_walk_through() -> void:
	var model := "decor/bv_vault_door_forced.glb"
	check(DungeonBuild.BOXES.has(model) and not model in DungeonBuild.NO_BODY, "it has its own boxes")
	check(_mesh_open(model, 0, 0.7) and _mesh_open(model, 0, 0.1), "the model's doorway is open")
	_setup()
	var t := Transform3D(Basis(Vector3.UP, 0.7), Vector3(5, 1, -3))  # (turned and moved: the boxes go with it)
	_body(model, t)
	await tree.physics_frame
	for y in [0.15, 0.7, 1.2]:
		check(not _ray(t, Vector3(0, y, 2), Vector3(0, y, -2)), "nothing blocks the doorway %.2f m up" % y)
	for p in [Vector3(-0.95, 1.0, 0), Vector3(0.95, 0.4, 0), Vector3(0, 1.7, 0)]:
		check(_ray(t, Vector3(p.x, p.y, 2), Vector3(p.x, p.y, -2)), "the wall at %s is solid" % p)
	# A dwarf (its capsule) walks straight through the middle, stepping over the threshold.
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.35
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collision_mask = World.TERRAIN_LAYER
	var space := root.get_world_3d().direct_space_state
	var z := -1.6
	while z <= 1.6:
		q.transform = Transform3D(t.basis, t * Vector3(0, 0.675 + 0.04, z))
		check(space.intersect_shape(q, 1).is_empty(), "a dwarf fits through at z %.1f" % z)
		z += 0.2
	_teardown()


func test_the_spyhole_is_see_through() -> void:
	var model := "decor/vo_spyhole_wall.glb"
	check(DungeonBuild.BOXES.has(model) and not model in DungeonBuild.NO_BODY, "it has its own boxes")
	check(_mesh_open(model, 0, 1.05), "the model's spyhole goes right through")
	check(not _mesh_open(model, 0.35, 1.0), "the model's wall is solid beside it")
	_setup()
	var t := Transform3D(Basis(Vector3.UP, -1.2), Vector3(-4, 0.5, 8))
	_body(model, t)
	await tree.physics_frame
	for p in [Vector3(0, 1.05, 0), Vector3(0.05, 0.95, 0), Vector3(-0.05, 1.15, 0)]:
		check(not _ray(t, Vector3(p.x, p.y, 2), Vector3(p.x, p.y, -2)), "you can look (and shoot) through the spyhole at %s" % p)
	for p in [Vector3(0.35, 1.0, 0), Vector3(-0.35, 1.0, 0), Vector3(0, 0.5, 0), Vector3(0, 1.5, 0)]:
		check(_ray(t, Vector3(p.x, p.y, 2), Vector3(p.x, p.y, -2)), "the wall at %s is solid" % p)
	_teardown()


## F919 (owner, Nov 27): you could walk on top of small things like the bolt crate.
func test_small_loot_is_not_a_step() -> void:
	_setup()
	var lp := auth.loot_props
	lp.place("d:test:9", "decor/rt_arrow_crate_spill.glb", Transform3D(Basis.IDENTITY, Vector3(2, 0, 0)))
	check(Dwarf.is_small_thing(lp.props["d:test:9"].node), "the bolt crate is a small thing (bump, don't stand)")
	check(not Dwarf.is_small_thing(null), "nothing isn't")
	# F950 (owner, Nov 28): a flat floor board got a crate's "bump into it" hitbox. Flat pieces are floor.
	lp.place("d:test:10", "decor/floor_grate.glb", Transform3D(Basis.IDENTITY, Vector3(-2, 0, 0)))
	check(not Dwarf.is_small_thing(lp.props["d:test:10"].node), "a flat floor grate is floor you walk over, not a small thing")
