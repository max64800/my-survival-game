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
		# (and Cave Spiders: owner, Nov 25, "add lots of tiny spiders like in the 1st dungeon, but more")
		check(Monsters.info(String(c.kind)).get("ghost", false) or c.kind == "cave_spider",
			"%s is a ghost or a spider (owner: 'there should be ghosts now')" % c.kind)
	check(int(kinds.get("cave_spider", 0)) > 7, "more spiders than Mossgate's 7 (%d)" % int(kinds.get("cave_spider", 0)))
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
	for deadly in ["stair_pit", "chasm", "candle_pit", "names_pit"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, deadly) + Vector3.UP * 0.3), deadly, "%s kills" % deadly)


## Owner, Nov 25: "add a few spikes and fake floor, we don't have a full death trap anywhere": four loose slabs give
## way (two over new spike pits, two on the Bridge of Oaths over the chasm), and right under each one you die.
func test_the_fake_floors_give_way_over_a_deadly_drop() -> void:
	var d := _hald(_test_world())
	var fakes: Array = DungeonBuild.load_plan("hald").props.filter(func(p): return DungeonBuild.thing_kind(p) == "floor")
	check_eq(fakes.size(), 4, "four fake floor slabs")
	for p in fakes:
		check_eq(String(p.model), "dungeon/floor_loose_flagstone.glb", "a stone slab, not boards (a stone tomb, F856)")
		var hit := ""
		for drop in [3.0, 10.0]:  # (a pit 3 m down, the chasm 10 m)
			var under := DungeonMap.to_world(d, Vector3(float(p.pos[0]), float(p.pos[1]) - drop + 0.3, float(p.pos[2])))
			if hit == "":
				hit = DungeonBuild.deadly_space(d, under)
		check(hit != "", "under the slab at %s: a deadly drop (%s)" % [p.pos, hit])
		var on := DungeonMap.to_world(d, Vector3(float(p.pos[0]), float(p.pos[1]) + 0.5, float(p.pos[2])))
		check_eq(DungeonBuild.deadly_space(d, on), "", "(standing on it is safe till it breaks)")
	var bridge: Array = fakes.filter(func(p): return float(p.pos[1]) < -7.0 and float(p.pos[0]) > 30.0 and float(p.pos[2]) < 17.0)
	check_eq(bridge.size(), 2, "two cracked slabs on the bridge")
	if bridge.size() == 2:
		check(absf(float(bridge[0].pos[2]) - float(bridge[1].pos[2])) > 1.0, "on opposite sides: a careful dwarf gets across")


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


## F846 (owner, Nov 25: died twice at 100 HP just before the boss room): the Broken Stair's spike pit only kills down
## in the pit, not on the stairs over it and not in the tomb door and Hald's Tomb 5 m under it.
func test_over_and_under_the_spike_pit_is_safe() -> void:
	var d := _hald(_test_world())
	for q in [Vector3(41, 0.6, 35), Vector3(43, 2.6, 35), Vector3(41, 0.6, 37), Vector3(43, 4.3, 35.5),  # on the stairs
			Vector3(42.5, -7.7, 34.5), Vector3(43.5, -7.7, 35.8), Vector3(42, -7.7, 36.8), Vector3(43, -6.5, 35)]:  # under
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, q)), "", "standing at %s is safe" % q)
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(42, -2.7, 35))), "stair_pit", "down in the pit kills")


## F847 (owner, Nov 25: "all of the stairs are broken", you stand on air): every stone stairs is a slope you walk up,
## not a 2 m block. Along each flight, the ground is where its steps are, and there is room for a dwarf over them.
func test_walk_up_every_stair() -> void:
	var r := _rig()
	var d: Dictionary = r.d
	var db: DungeonBuild = r.db
	await tree.physics_frame
	await tree.physics_frame
	var stairs: Array = DungeonBuild.placements(d, DungeonBuild.load_plan("hald")).get("build/stairs__cut_stone.glb", [])
	check_eq(stairs.size(), 20, "Hald's 20 stairs")
	var space := db.get_world_3d().direct_space_state
	for t: Transform3D in stairs:
		for f in [0.15, 0.5, 0.85]:
			var on := t * Vector3(0, 2.0 * f, 1.0 - 2.0 * f)  # (a stairs climbs from its front, +z, to its back)
			var ray := PhysicsRayQueryParameters3D.create(on + Vector3.UP * 1.5, on + Vector3.DOWN * 1.0, World.TERRAIN_LAYER)
			var hit := space.intersect_ray(ray)
			var top: float = (hit.position as Vector3).y if not hit.is_empty() else -INF
			check(absf(top - on.y) < 0.3, "the stairs at %s: ground %.2f where its step is (%.2f)" % [t.origin, top, on.y])
			if f < 0.7:  # (the top 60 cm: a dwarf there touches the real wall round the doorway at the top)
				check(not _blocked(db, on + Vector3.UP * 1.0), "the stairs at %s: no invisible wall %d%% up" % [t.origin, f * 100])
	r.root.free()


## F848 (owner, Nov 25: the door in Hald's Tomb didn't open after he died): E on the Bronze door unlocks it with the
## Bronze Key (nothing called DungeonKeys.ask_unlock, so it never opened); without the key it stays shut.
func test_the_bronze_door_opens_with_its_key() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var ids: Array = db.things.keys().filter(func(id): return db.things[id].kind == "door")
	check_eq(ids.size(), 1, "one key door: the Bronze door")
	if ids.size() != 1:
		r.root.free()
		return
	var id: int = ids[0]
	var th: Dictionary = db.things[id]
	(r.player as Node3D).global_position = (th.xform as Transform3D) * Vector3(0, 0.2, -1.5)
	check(String(db.use_info(id).get("name", "")).contains("Bronze Key"), "E aims at it: '%s'" % db.use_info(id).get("name", ""))
	db.ask_use(id)
	check(not db.is_door_open(th.d), "no key: it stays shut")
	r.ps.inventory.add("key_bronze", 1)
	db.ask_use(id)
	check(db.is_door_open(th.d), "with the Bronze Key: it opens")
	check(db.use_info(id).is_empty(), "open: nothing more to do with E")
	r.root.free()


## A dark STONE dungeon (owner, Nov 25: F856-F860, F862, F863): stone and iron twins of the wooden dungeons' models,
## no planks under any chest, each with its own boxes (F847) and its moving part.
func test_stone_and_iron_not_wood() -> void:
	var plan := DungeonBuild.load_plan("hald")
	var models := {}
	for p in plan.props:
		models[String(p.model)] = true
	for m in ["dungeon/entrance_stone.glb", "dungeon/gate_iron.glb", "dungeon/lever_iron.glb", "dungeon/portcullis.glb",
			"dungeon/wall_cracked_stone.glb", "dungeon/trap_chest_spikes_stone.glb", "dungeon/trap_tripwire_wall_stone.glb",
			"dungeon/tripwire_iron.glb"]:
		check(models.has(m), "Hald has %s" % m)
	for m in ["dungeon/dungeon_entrance.glb", "dungeon/gate_round.glb", "dungeon/lever.glb", "dungeon/wall_cracked.glb",
			"dungeon/trap_chest_spikes.glb", "dungeon/trap_tripwire_wall.glb", "dungeon/tripwire.glb"]:
		check(not models.has(m), "no wooden %s" % m)
	for m in models:
		check(not ("plank" in m or "wood" in m), "no planks or wood: %s" % m)
	for p in plan.pieces:
		check(not ("plank" in String(p.get("mat", "")) or "root" in String(p.get("mat", ""))), "a stone piece: %s %s" % [p.id, p.get("mat", "")])
	for m in ["dungeon/entrance_stone.glb", "dungeon/gate_iron.glb", "dungeon/lever_iron.glb", "dungeon/wall_cracked_stone.glb",
			"dungeon/trap_chest_spikes_stone.glb", "dungeon/trap_tripwire_wall_stone.glb", "dungeon/tripwire_iron.glb"]:
		check(DungeonBuild.BOXES.has(m), "%s has its own boxes (F847)" % m)
	check_eq(DungeonBuild.thing_kind({model = "dungeon/wall_cracked_stone.glb"}), "rubble", "the stone cracked wall breaks")
	check_eq(DungeonBuild.thing_kind({model = "dungeon/gate_iron.glb"}), DungeonBuild.thing_kind({model = "dungeon/gate_round.glb"}), "the iron gate is a gate")
	check_eq(DungeonBuild.thing_kind({model = "dungeon/lever_iron.glb"}), DungeonBuild.thing_kind({model = "dungeon/lever.glb"}), "the iron lever is a lever")
	check_eq(MineTraps.kind_of({model = "dungeon/trap_chest_spikes_stone.glb"}), "chest_spikes", "the stone spike holes fire")
	check_eq(MineTraps.kind_of({model = "dungeon/trap_tripwire_wall_stone.glb"}), "dart_wall", "the stone dart wall is a dart wall (F853)")
	check_eq(MineTraps.kind_of({model = "dungeon/tripwire_iron.glb"}), "tripwire", "the iron wire is a tripwire (F853)")
	for mp in [["dungeon/lever_iron.glb", "handle"], ["dungeon/portcullis.glb", "gate"], ["dungeon/trap_chest_spikes_stone.glb", "spikes"],
			["dungeon/trap_tripwire_wall_stone.glb", "bolt"], ["dungeon/tripwire_iron.glb", "wire_l"], ["dungeon/tripwire_iron.glb", "wire_r"]]:
		var inst := (load("res://assets/models/" + mp[0]) as PackedScene).instantiate()
		check(inst.find_child(mp[1], true, false) != null, "%s has its moving '%s'" % mp)
		inst.free()
	var wall := (load("res://assets/models/dungeon/wall_cracked_stone.glb") as PackedScene).instantiate()
	check(wall.find_children("*", "MeshInstance3D", true, false).size() >= 6, "the stone wall falls in pieces")
	wall.free()


## F860 🔁 (owner, Nov 25: "make it darker"): fewer, dimmer torches and a cold dark tomb mood inside.
func test_the_tomb_is_dark() -> void:
	var plan := DungeonBuild.load_plan("hald")
	check(plan.lights.size() <= 32, "fewer torches (%d; were 48)" % plan.lights.size())
	var d := _hald(_test_world())
	check(float(d.map.get("torch_energy", 1.6)) < 1.6 and float(d.map.get("torch_range", 9.0)) < 9.0, "dimmer torches")
	check_eq(String(d.map.get("mood", "")), "tomb", "the tomb mood")
	check(float(Ambience.MOODS.tomb.ambient_energy) < float(Ambience.MOODS.mossy.ambient_energy) * 0.5, "much less soft light")
	for map in DungeonMap.MAPS:
		if not map.id in ["hald", "barrows"]:  # (the Quiet Barrows is a dark tomb too: F906)
			check(not map.has("mood") and not map.has("torch_energy"), "%s keeps its light" % map.id)


## The Shield-Brother drops the Bronze Key when he dies (or the Grave Chamber stays shut).
## F849 (owner, Nov 25: "too easy"): two weak Tomb Shades fight with Hald, and he runs faster than you walk.
func test_hald_has_two_easy_shades() -> void:
	var kinds := {}
	for c in DungeonBuild.load_plan("hald").creatures:
		kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
	check_eq(int(kinds.get("hald_shade", 0)), 2, "two Tomb Shades")
	check(Monsters.info("hald_shade").hp < Monsters.info("ghost_a").hp, "weaker than a Drifting Shade")
	check(Monsters.info("hald_ironbrow").run >= 4.0, "Hald runs you down")
	# (owner, Nov 25: "the boss stands too close to the door, I couldn't come in"): all three wait well inside,
	# further than they wake, so you walk into the room before the fight starts.
	var door := Vector2(44.0, 36.0)  # the tomb door's middle (tomb_door: x 42-46, z 32-36)
	for c in DungeonBuild.load_plan("hald").creatures:
		if String(c.kind) in ["hald_ironbrow", "hald_shade"]:
			var far := Vector2(float(c.pos[0]), float(c.pos[2])).distance_to(door)
			check(far > float(Monsters.info(String(c.kind)).rise_near) - 0.5 and far > 8.0,
				"%s waits %.1f m from the door" % [c.kind, far])


## F850: the Honour Chapel is bigger (room to step round the Shield-Brother).
func test_the_honour_chapel_is_bigger() -> void:
	for s in DungeonMap.HALD.spaces:
		if s[0] == "honour_chapel":
			check((s[3] - s[1]) * (s[4] - s[2]) >= 100, "at least 10 x 10 m (%d x %d)" % [s[3] - s[1], s[4] - s[2]])


## F872: a ghost finds its way room by room through the doorways.
func test_ghosts_find_the_doorways() -> void:
	var d := _hald(_test_world())
	var link := Ghost.links(d)
	for pair in [["antechamber", "halds_tomb"], ["names_hall", "halds_tomb"], ["ossuary", "honour_chapel"]]:
		var a := Ghost.boxes_at(d, DungeonMap.space_floor(d, pair[0]))
		var b := Ghost.boxes_at(d, DungeonMap.space_floor(d, pair[1]))
		var step := Ghost.first_door(link, a, b)
		check(not step.is_empty(), "a way from %s to %s" % pair)
	var deadly: Array = []
	for i in d.map.spaces.size():
		if d.map.spaces[i][0] in d.map.deadly:
			deadly.append(i)
	for i in link:
		for l in link[i]:
			check(not (l[0] in deadly) and not (i in deadly), "never through the pit or chasm")


## F856 🔁 (owner, Nov 25: "the buried chest sits on wooden boards"): Hald's loose floor stone and recipe stand are stone.
func test_the_niche_and_the_stand_are_stone() -> void:
	var plan := DungeonBuild.load_plan("hald")
	var models := {}
	for p in plan.props:
		models[String(p.model)] = true
	for m in ["dungeon/floor_loose_flagstone.glb", "dungeon/recipe_stand_stone.glb"]:
		check(models.has(m), "Hald has %s" % m)
		check(DungeonBuild.BOXES.has(m), "%s has its own boxes" % m)
	for m in ["dungeon/floor_loose_stone.glb", "dungeon/recipe_stand.glb"]:
		check(not models.has(m), "no wooden %s" % m)
	check_eq(String(plan.recipe_stand.get("kind", "")), "recipe_stand_stone", "the Storage box draws the stone stand")
	var fl := (load("res://assets/models/dungeon/floor_loose_flagstone.glb") as PackedScene).instantiate()
	for part in ["frame", "stone"]:
		check(fl.find_child(part, true, false) != null, "the loose flagstone has its '%s' (the stone lifts off)" % part)
	fl.free()


## F857 🔁: the stone stash wall has the junction's narrow walls on both sides, and a small hole (one stone) through it.
func test_the_cracked_wall_has_walls_beside_it_and_a_hole() -> void:
	var plan := DungeonBuild.load_plan("hald")
	var at := Vector3.ZERO
	for p in plan.props:
		if String(p.model) == "dungeon/wall_cracked_stone.glb":
			at = Vector3(p.pos[0], p.pos[1], p.pos[2])
	var sides := {}
	for p in plan.pieces:
		if p.id == "wall_narrow" and absf(float(p.pos[1]) - at.y) < 0.1 and absf(float(p.pos[2]) - at.z) < 0.3:
			var dx := float(p.pos[0]) - at.x
			if absf(dx) > 1.2 and absf(dx) < 1.8:
				sides[signf(dx)] = true
	check(sides.has(-1.0) and sides.has(1.0), "a narrow wall on each side (%s)" % [sides.keys()])
	var wall := (load("res://assets/models/dungeon/wall_cracked_stone.glb") as PackedScene).instantiate() as Node3D
	var shapes := []
	for mi in wall.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		shapes.append([DungeonBuild._rel_xform(wall, m), m.mesh.generate_triangle_mesh()])
	var see_through := func(x: float, y: float) -> bool:
		for sh in shapes:
			var rel: Transform3D = sh[0]
			var tm: TriangleMesh = sh[1]
			if not tm.intersect_ray(rel.affine_inverse() * Vector3(x, y, 2.0), rel.basis.inverse() * Vector3(0, 0, -1)).is_empty():
				return false
		return true
	# F857 🔁 3rd time (owner, Nov 25: "this hole is too big, too obvious: fill it, only one part open"): one stone out.
	var open_at := []
	for i in 11:
		var y := 0.5 + i * 0.05
		if see_through.call(0.1, y):
			open_at.append(y)
	check(not open_at.is_empty(), "you can see through the one missing stone")
	check(open_at.size() <= 7, "the hole is one stone tall, not more (open at %s)" % [open_at])
	var mid: float = open_at[open_at.size() / 2] if not open_at.is_empty() else 0.78
	check(not see_through.call(0.1, 1.2) and not see_through.call(0.1, 0.35), "closed above and below it")
	check(not see_through.call(-0.4, mid) and not see_through.call(0.6, mid), "closed to the left and right of it")
	wall.free()


## F871: the sign on the way-in's lintel is cut deep and its runes glow (it was far too faint).
func test_the_lintel_runes_glow() -> void:
	var ent := (load("res://assets/models/dungeon/entrance_stone.glb") as PackedScene).instantiate()
	var glows := false
	for mi in ent.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh
		for k in m.get_surface_count():
			var mat := m.surface_get_material(k) as StandardMaterial3D
			if mat and mat.emission_enabled:
				glows = true
	check(glows, "the runes glow")
	ent.free()


## F875 (owner, Nov 25: "it only works when I look at the foot of its post"): the stand's touch box reaches its book.
func test_the_recipe_stand_works_from_its_book() -> void:
	for kind in ["recipe_stand", "recipe_stand_stone"]:
		var st := Storage.new()
		var body := StaticBody3D.new()
		st.add_child(body)
		st._build_look(body, kind)
		var top := 0.0
		for cs in body.find_children("*", "CollisionShape3D", true, false):
			var sh := (cs as CollisionShape3D).shape as BoxShape3D
			if sh:
				top = maxf(top, (cs as CollisionShape3D).position.y + sh.size.y * 0.5)
		check(top >= 1.15, "%s: the touch box reaches over the book (top %.2f m)" % [kind, top])
		st.free()


## F844 (owner, said 2x): a signpost at the way in: skulls for how hard, the recipe's picture, a tick once learned.
func test_the_signpost_at_the_way_in() -> void:
	check_eq(DungeonBuild.SIGN_SKULLS.small.size(), 1, "small: 1 skull")
	check_eq(DungeonBuild.SIGN_SKULLS.medium.size(), 2, "medium: 2 skulls")
	check_eq(DungeonBuild.SIGN_SKULLS.big.size(), 3, "big: 3 skulls")
	var m := _test_world()
	var d := _hald(m)
	var spot := DungeonBuild.sign_spot(m, d)
	check(not spot.is_empty(), "there is a spot for it")
	if spot.is_empty():
		return
	var t: Transform3D = spot.xform
	check(DungeonBuild.sign_clear(m, t), "open air round it (no rock through it)")
	check(m.sdf_at(t.origin + Vector3.DOWN * 0.15) <= 0.0, "it stands on the floor")
	var mouth: Vector2 = d.map.mouth
	var local := (d.basis as Basis).inverse() * (t.origin - (d.mouth as Vector3))
	check(absf(local.x) >= DungeonMap.DOOR_HOLE.x * 0.5 + 0.6, "off the path (%.1f m to the side)" % local.x)
	var kept := false  # (the placement rule: inside the doorway's clear circle, so nothing the world grows stands in it)
	for r in m.reserved:
		var flat := Vector2(t.origin.x - r.pos.x, t.origin.z - r.pos.z)
		if flat.length() + 0.4 <= float(r.r):
			kept = true
	check(kept, "nothing grows on it")
	var rig := _rig()
	var db: DungeonBuild = rig.db
	var sp: Node3D = db.signs.get("tomb_of_hald_ironbrow")
	check(sp != null, "the game puts it up")
	if sp:
		var shown := []
		for part in ["skull_l", "skull_mid", "skull_r"]:
			if (sp.find_child(part, true, false) as Node3D).visible:
				shown.append(part)
		check_eq(shown.size(), 2, "a medium dungeon: 2 skulls")
		var pic := sp.find_child("Picture", true, false) as Sprite3D
		check(pic != null and pic.texture != null, "the recipe's picture on the board")
		var tick := sp.find_child("tick", true, false) as Node3D
		check(tick != null and not tick.visible, "no tick before the recipe is learned")
		rig.auth.world_state.learned = [DungeonList.recipe_of("tomb_of_hald_ironbrow")]
		db.update_signs()
		check(tick != null and tick.visible, "a tick once it is learned")
	rig.root.queue_free()


## F873 (owner, Nov 25, 3rd round: "I haven't seen a single teleport"): in the Tomb the floor tiles stand 0.25 m over
## the rock, and the body check at knee height hit them, so no spot was ever open. Now a ghost finds one behind you.
func test_ghosts_find_a_spot_behind_you_in_the_tomb() -> void:
	var r := _rig()
	var d: Dictionary = r.d
	await tree.physics_frame
	await tree.physics_frame
	for room in ["mourners_gate", "halds_tomb", "honour_chapel"]:
		var mid := DungeonMap.space_floor(d, room)
		r.player.global_position = mid + Vector3.UP * 0.3
		var m := Node3D.new()  # (where the ghost stood: 3 m in front of you)
		r.root.add_child(m)
		m.global_position = mid + Vector3(3, 0.3, 0)
		await tree.physics_frame
		var spot := Ghost.spot_behind(m, r.player, r.db.maker, d)
		check(spot != Vector3.INF, "in %s it finds an open spot" % room)
		if spot != Vector3.INF:
			var was: Vector3 = (m.global_position - r.player.global_position) * Vector3(1, 0, 1)
			var now: Vector3 = (spot - r.player.global_position) * Vector3(1, 0, 1)
			check(now.normalized().dot(was.normalized()) < -0.3, "behind you in %s" % room)
	r.root.free()


## Owner, Nov 25 (4th round: "I can bait them and they get stuck on the stairs"): a Wrathful Shade from the Hall of
## Names follows you all the way up the Grand Stair (it stood at the foot of the Grand Stair, then on its top step, for good).
func test_a_ghost_follows_you_up_the_grand_stair() -> void:
	var r := _rig()
	var d: Dictionary = r.d
	var mgr: MonsterManager = r.auth.monsters
	await tree.physics_frame
	await tree.physics_frame
	r.player.global_position = DungeonMap.to_world(d, Vector3(20.0, 0.3, 33.0))  # in the Wardens' Hall, at the top
	var uid: int = mgr._next_uid
	mgr._ev_spawn(uid, "ghost_b", DungeonMap.to_world(d, Vector3(20.0, -8.0 + 0.55, 21.5)), false, 0, "")
	var m: Monster = mgr.get_monster(uid)
	m.dungeon = d
	m.dungeon_room = "names_hall"
	await tree.physics_frame
	m.alert(1)
	var best := INF
	var top_y := -INF
	for i in 900:
		await tree.physics_frame
		var to: Vector3 = r.player.global_position - m.global_position
		best = minf(best, Vector2(to.x, to.z).length())
		top_y = maxf(top_y, m.global_position.y)
		if best < 3.2:
			break
	check(best < 3.2, "it reaches you at the top (closest %.1f m, highest it got %.1f m)" % [best, top_y - DungeonMap.to_world(d, Vector3.ZERO).y])
	r.root.free()


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
