extends TestCase
## The Tomb of Hald Ironbrow, the fifth dungeon (owner, Nov 24, F843): Stonehold stone, half of it fallen in, ghosts only,
## the Shield-Brother (the Bronze Key) and Hald Ironbrow's ghost as the boss. Its map (DungeonMap.HALD), its plan
## (tools/dungeons/make_hald.py), its decisions (docs/design/zone1-dungeons/2026-11-24-hald-decisions.md).

var _test_maker: CaveMaker


## The Dungeon 5 test world: one small cave with the Tomb of Hald Ironbrow behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_5)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _hald(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == "hald":
			return d
	return {}


func test_the_dungeon_5_test_world() -> void:
	var m := _test_world()
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _hald(m)
	check(not d.is_empty(), "it is the Tomb of Hald Ironbrow")
	if d.is_empty():
		return
	check(d.map.spaces.size() >= 21, "at least 21 spaces (%d)" % d.map.spaces.size())
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan("hald")
	check(not plan.is_empty(), "Hald's plan loads")
	if plan.is_empty():
		return
	var d := _hald(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_hald", "the recipe stand holds Hald's scroll")
	check(Items.info("scroll_hald").get("teaches_recipe", "") != "", "the scroll teaches a recipe")
	var stone := 0
	for p in plan.pieces:
		stone += 1 if String(p.mat) == "cut_stone" else 0
	check(stone > plan.pieces.size() * 0.9, "Stonehold stone (owner): %d of %d" % [stone, plan.pieces.size()])
	var kinds := {}
	for c in plan.creatures:
		kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
		check(Monsters.info(String(c.kind)).get("ghost", false), "%s is a ghost (owner: 'there should be ghosts now')" % c.kind)
	check_eq(int(kinds.get("hald_ironbrow", 0)), 1, "Hald Ironbrow is the boss")
	check_eq(int(kinds.get("shield_brother", 0)), 1, "the Shield-Brother is the mini boss")
	var ruined: int = plan.pieces.filter(func(p): return "ruin" in String(p.id)).size()
	check(ruined > 50, "about half of it fell in (owner): %d broken pieces" % ruined)


func test_creatures_stand_in_their_rooms() -> void:
	var d := _hald(_test_world())
	for c in DungeonBuild.load_plan("hald").creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and not room in d.map.deadly, "a %s stands in a room (%s)" % [c.kind, room])


func test_only_the_pit_and_chasm_kill() -> void:
	var d := _hald(_test_world())
	for safe in ["mourners_gate", "candle_hall", "honour_chapel", "names_hall", "quiet_chapel", "halds_tomb"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, safe) + Vector3.UP * 0.3), "", "standing in %s is safe" % safe)
	for deadly in ["stair_pit", "chasm"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, deadly) + Vector3.UP * 0.3), deadly, "%s kills" % deadly)


func test_the_bronze_door_needs_the_shield_brothers_key() -> void:
	check_eq(DungeonKeys.keys_of("tomb_of_hald_ironbrow").map(func(k): return String(k)), ["key_bronze"], "one key: the Bronze Key")
	check_eq(String(DungeonKeys.KEYS.key_bronze.boss), "The Shield-Brother", "the Shield-Brother carries it")
	check_eq(String(Monsters.info("shield_brother").get("key", "")), "key_bronze", "and drops it")
	check(Monsters.info("shield_brother").get("front_shield", false), "his ghost shield blocks hits from the front")


func _rig() -> Dictionary:
	var m := _test_world()
	var root := Node3D.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	var player := Node3D.new()
	root.add_child(player)
	var ps := auth.add_player(1, player)
	var db := DungeonBuild.new()
	db.maker = m
	root.add_child(db)
	return {root = root, auth = auth, player = player, ps = ps, db = db, d = m.dungeons[0]}


## Every trap really fires (lesson from #1-#4): the Hall of Candles' wire shoots its dart wall.
func test_the_candle_hall_dart_wall_fires() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var wires: Array = db.things.keys().filter(func(id): return db.things[id].kind == "tripwire")
	check_eq(wires.size(), 2, "two tripwires (Hall of Candles, Collapsed Tunnel)")
	var wire := -1
	for id in wires:
		if DungeonMap.space_at(d, (db.things[id].xform as Transform3D).origin + Vector3.UP * 0.5) == "candle_hall":
			wire = id
	check(wire >= 0, "one is in the Hall of Candles")
	if wire < 0:
		r.root.free()
		return
	var dart: int = db.mine._dart_of(wire)
	check(dart >= 0, "the wire fires a dart wall")
	if dart < 0:
		r.root.free()
		return
	var player: Node3D = r.player
	player.global_position = DungeonMap.to_world(d, Vector3(29.0, 0.24, 58.0))  # walking east across the wire
	var hp0: float = r.ps.vitals.health
	db.mine.host_check(r.auth, 1, player.global_position, 0.1)
	check(db.is_broken(wire), "walked into: the wire snaps")
	check(db.is_broken(dart), "and the dart fires")
	check(r.ps.vitals.health < hp0, "it hits you (%.0f -> %.0f)" % [hp0, r.ps.vitals.health])
	r.root.free()


## The Honour Chapel's ambush (F843): the portcullis hangs raised (its teeth show), slams down behind you once you are
## 2.5 m into the room while the Shield-Brother's room lives, and lifts when he dies or when nobody living is inside.
func test_the_honour_chapel_portcullis() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var auth: GameAuthority = r.auth
	var player: Node3D = r.player
	var ids: Array = db.things.keys().filter(func(id): return db.things[id].kind == "portcullis")
	check_eq(ids.size(), 1, "one portcullis")
	if ids.size() != 1:
		r.root.free()
		return
	var id: int = ids[0]
	var th: Dictionary = db.things[id]
	check_eq(String(th.prop.get("room", "")), "honour_chapel", "it guards the Honour Chapel")
	var door := (th.xform as Transform3D).origin + Vector3.UP * 1.0
	check_eq(DungeonMap.space_at(d, door + Vector3(1.0, 0, 0)), "honour_chapel", "it stands in the chapel's doorway")
	await tree.physics_frame
	await tree.physics_frame
	check(not _blocked(db, door), "raised: you walk through under it")
	check(not db.is_portcullis_shut(id), "it starts raised")
	var mid := DungeonMap.space_floor(d, "honour_chapel") + Vector3.UP * 0.3
	player.global_position = DungeonMap.to_world(d, Vector3(44.8, 4.24, 36.0))  # (just through the doorway)
	db._on_dungeon_room("hald", "honour_chapel", false)  # (his room's ghosts came)
	db._check_portcullises(auth)
	check(not db.is_portcullis_shut(id), "not yet: only half a step in")
	player.global_position = mid
	db._check_portcullises(auth)
	check(db.is_portcullis_shut(id), "walked in on him: it slams down")
	await tree.physics_frame
	await tree.physics_frame
	check(_blocked(db, door), "shut: it blocks the doorway")
	db._on_dungeon_room("hald", "honour_chapel", true)  # (the Shield-Brother and his ghosts died)
	db._check_portcullises(auth)
	check(not db.is_portcullis_shut(id), "he died: it lifts")
	db._on_dungeon_room("hald", "honour_chapel", false)
	db._check_portcullises(auth)
	check(db.is_portcullis_shut(id), "an hour later, again")
	player.global_position = DungeonMap.space_floor(d, "broken_stair") + Vector3.UP * 0.3
	db._check_portcullises(auth)
	check(not db.is_portcullis_shut(id), "nobody living inside: it lifts (nobody is locked out for good)")
	r.root.free()


## Hald's stone doorways let you through (F843: without their own boxes, the box round the whole model shut them).
func test_the_stone_doorways_are_open() -> void:
	check(DungeonBuild.BOXES.has("build/doorway__cut_stone.glb"), "the Stonehold doorway has its own boxes")
	var r := _rig()
	var d: Dictionary = r.d
	await tree.physics_frame
	await tree.physics_frame
	var plan := DungeonBuild.load_plan("hald")
	var doors := {}  # (the doorways with a real door or gate in them are shut on purpose)
	for p in plan.props:
		if String(p.get("role", "")) == "door":
			doors[str(p.pos)] = true
	var n := 0
	for p in plan.pieces:
		if String(p.id) != "doorway" or doors.has(str(p.pos)):
			continue
		n += 1
		var at := DungeonMap.to_world(d, Vector3(p.pos[0], float(p.pos[1]) + 1.0, p.pos[2]))
		check(not _blocked(r.db, at), "the doorway at %s lets you through" % [p.pos])
	check(n > 10, "Hald has doorways (%d)" % n)
	r.root.free()


## Is there anything solid of the dungeon's at `at` (a dwarf-sized ball)?
func _blocked(db: DungeonBuild, at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.35
	q.shape = ball
	q.transform = Transform3D(Basis(), at)
	q.collision_mask = World.TERRAIN_LAYER
	for hit in db.get_world_3d().direct_space_state.intersect_shape(q, 8):
		if (hit.collider as Node).is_ancestor_of(db) == false and db.is_ancestor_of(hit.collider as Node):
			return true
	return false


## The Shield-Brother drops the Bronze Key when he dies (or the Grave Chamber stays shut).
func test_the_shield_brother_drops_the_bronze_key() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	auth.stations_root = Node3D.new()
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var player := Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	auth.add_player(1, player)
	check(auth.keys.boss_has_key("key_bronze"), "he starts with the key")
	var uid: int = auth.monsters._next_uid
	auth.monsters._ev_spawn(uid, "shield_brother", player.global_position + Vector3(4, 0.3, 0), false, 0, "")
	var m: Monster = auth.monsters.get_monster(uid)
	check(m != null, "the Shield-Brother appears")
	if m != null:
		await tree.process_frame
		for i in 20:
			if not is_instance_valid(m) or m.hp <= 0.0:
				break
			auth.monsters._hurt_monster(m, 1, 9999, 0.0)
		check(not auth.keys.boss_has_key("key_bronze"), "the key is out in the world")
		check_eq(auth._drops.values().filter(func(dr): return dr.item_id == "key_bronze").size(), 1, "the Bronze Key drops once")
	root.queue_free()  # (keep this test last: the World it frees at the frame's end throws a
	# harmless 'material is null' error into whatever test runs next)
