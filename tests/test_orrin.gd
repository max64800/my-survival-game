extends TestCase
## The Vigil of Orrin Stonejaw, the ninth dungeon (owner, Nov 28, F980): very old Hearthbrick brick with a little Stonehold
## stone, three levels climbing a bell tower, skeletons and Rune Callers, the Bell-Ringer the boss with the Rune Key.
## Its map (DungeonMap.ORRIN), its plan (tools/dungeons/make_orrin.py), its decisions
## (docs/design/zone1-dungeons/2026-11-28-orrin-decisions.md).

const ID := "orrin"
var _test_maker: CaveMaker


## The Dungeon 9 test world: one small cave with the Vigil behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_9)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _vigil(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == ID:
			return d
	return {}


## The bell tower's top (Orrin's Vigil, the Rune Door, Orrin's Rest): the one part someone kept repaired (owner).
func _tower_top(p: Dictionary) -> bool:
	return p.pos[0] > 34.0 and p.pos[0] <= 56.0 and p.pos[2] >= 56.0 and p.pos[2] <= 70.0 and p.pos[1] >= DungeonMap.BELL - 0.1


func test_the_dungeon_9_test_world() -> void:
	var m := _test_world()
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _vigil(m)
	check(not d.is_empty(), "it is the Vigil of Orrin Stonejaw")
	if d.is_empty():
		return
	check(d.map.spaces.size() >= 30, "at least 30 spaces (%d)" % d.map.spaces.size())
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var floors := {}
	for s in d.map.spaces:
		floors[float(s[5])] = true
	check(floors.has(0.0) and floors.has(DungeonMap.RUNE) and floors.has(DungeonMap.BELL),
		"three levels: 0, the rune halls at %.0f m and the bell tower at %.0f m" % [DungeonMap.RUNE, DungeonMap.BELL])


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan(ID)
	check(not plan.is_empty(), "the Vigil's plan loads")
	if plan.is_empty():
		return
	var d := _vigil(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_orrin", "the recipe stand holds the Vigil's scroll")
	check_eq(String(Items.info("scroll_orrin").get("teaches_recipe", "")), DungeonList.recipe_of("vigil_of_orrin_stonejaw"),
		"the scroll teaches the Vigil's recipe (the Bronze Sword)")


## Owner: "very old brick. Most of it is old, some of it may be new, maybe a mix of stone here and there, but not too much."
func test_very_old_brick_with_a_little_stone() -> void:
	var plan := DungeonBuild.load_plan(ID)
	var brick := 0
	var stone := 0
	var walls := 0
	var old := 0
	var top_old := 0
	for p in plan.pieces:
		brick += 1 if String(p.mat) in ["clay_brick", "ancient_brick"] else 0
		stone += 1 if String(p.mat) == "cut_stone" else 0
		var whole_wall: bool = String(p.id) in ["wall", "ruin_wall_worn", "ruin_wall_collapsed"]
		var is_old: bool = "ruin" in String(p.id)
		if _tower_top(p):
			top_old += 1 if is_old else 0
		elif whole_wall:
			walls += 1
			old += 1 if is_old else 0
	check(brick > plan.pieces.size() * 0.9, "brick: %d of %d" % [brick, plan.pieces.size()])
	check(stone > 0 and stone < plan.pieces.size() * 0.1, "stone here and there, not too much: %d of %d" % [stone, plan.pieces.size()])
	check(old > walls * 0.5, "most walls are old: %d of %d" % [old, walls])
	check_eq(top_old, 0, "the tower top is repaired: no old pieces there")


## Owner: skeletons and Rune Callers (no ghosts); one boss, the Bell-Ringer.
func test_skeletons_rune_callers_and_one_boss() -> void:
	var bosses := []
	var callers := 0
	for c in DungeonBuild.load_plan(ID).creatures:
		var info := Monsters.info(String(c.kind))
		check(not info.is_empty(), "%s is a monster the game knows" % c.kind)
		check(not info.get("ghost", false), "a %s is a skeleton, no ghost" % c.kind)
		callers += 1 if String(c.kind) == "rune_caller" else 0
		if info.get("boss", false):
			bosses.append(c.kind)
	check_eq(bosses, ["bell_ringer"], "one boss: the Bell-Ringer")
	check(callers >= 3, "Rune Callers (%d)" % callers)


func test_creatures_stand_in_their_rooms() -> void:
	var d := _vigil(_test_world())
	for c in DungeonBuild.load_plan(ID).creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and not room in d.map.deadly, "a %s stands in a room (%s)" % [c.kind, room])


func test_orrins_rest_needs_the_rune_key() -> void:
	check_eq(DungeonKeys.keys_of("vigil_of_orrin_stonejaw").map(func(k): return String(k)), ["key_rune"], "one key: the Rune Key")
	check_eq(String(Monsters.info("bell_ringer").get("key", "")), "key_rune", "the Bell-Ringer drops it")
	var doors: Array = DungeonBuild.load_plan(ID).props.filter(func(p): return String(p.label).contains("Rune Key"))
	check_eq(doors.size(), 1, "one locked door")
	if doors.size() == 1:
		check(absf(float(doors[0].pos[0]) - 46.0) < 0.1 and absf(float(doors[0].pos[2]) - 62.0) < 0.1,
			"between Orrin's Vigil and Orrin's Rest (%s)" % [doors[0].pos])


## The way out: the ledge 8 m up the Pilgrims' Door's wall, with the soft rag heap under it.
func test_the_way_out_ledge_and_rags() -> void:
	var d := _vigil(_test_world())
	check_eq(DungeonMap.space_floor(d, "exit_ledge").y - DungeonMap.space_floor(d, "pilgrims_door").y, DungeonMap.RUNE, "the ledge is 8 m up")
	var rags: Array = DungeonBuild.load_plan(ID).props.filter(func(p): return String(p.label).contains("soft heap"))
	check_eq(rags.size(), 1, "one heap of old rags")
	if rags.size() == 1:
		var under := DungeonMap.to_world(d, Vector3(rags[0].pos[0], 1.0, rags[0].pos[2]))
		check_eq(DungeonMap.space_at(d, under), "pilgrims_door", "the heap lies in the Pilgrims' Door")


## The old traps the decisions reuse are all there.
func test_the_reused_traps() -> void:
	var props: Array = DungeonBuild.load_plan(ID).props
	var count := func(model: String) -> int: return props.filter(func(p): return String(p.model) == model).size()
	check_eq(count.call("dungeon/trap_tripwire_wall_stone.glb"), 2, "two dart walls (Hall of Pillars, Rune Gallery)")
	check_eq(count.call("dungeon/tripwire_iron.glb"), 1, "one tripwire (Hall of Pillars)")
	check_eq(count.call("dungeon/trap_dart_plate.glb"), 1, "one dart plate (Rune Gallery)")
	check_eq(count.call("dungeon/trap_spear_wall.glb"), 2, "two spear walls (Bell Run)")
	check_eq(count.call("dungeon/trap_chest_spikes_stone.glb"), 1, "the spike-hole chest behind the boulder")
	check_eq(count.call("dungeon/wall_cracked_stone.glb"), 1, "the cracked wall to the Carvers' Vault")
	check(count.call("dungeon/trap_drip_fat.glb") + count.call("dungeon/trap_drip_thin.glb") + count.call("dungeon/trap_drip_cluster.glb") >= 3,
		"falling stones over the First Stair")


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


## Both flights are slopes you walk up, with room for a dwarf over them (the lesson of Hald's F847).
func test_walk_up_every_stair() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	await tree.physics_frame
	await tree.physics_frame
	var stairs: Array = DungeonBuild.placements(r.d, DungeonBuild.load_plan(ID)).get("build/stairs__cut_stone.glb", []) + DungeonBuild.placements(r.d, DungeonBuild.load_plan(ID)).get("build/stairs__clay_brick.glb", [])
	check_eq(stairs.size(), 24, "three flights of 4 steps, 2 wide (two in old stone, one in brick)")
	var space := db.get_world_3d().direct_space_state
	for t: Transform3D in stairs:
		for f in [0.15, 0.5, 0.85]:
			var on := t * Vector3(0, 2.0 * f, 1.0 - 2.0 * f)
			var ray := PhysicsRayQueryParameters3D.create(on + Vector3.UP * 1.5, on + Vector3.DOWN * 1.0, World.TERRAIN_LAYER)
			var hit := space.intersect_ray(ray)
			var top: float = (hit.position as Vector3).y if not hit.is_empty() else -INF
			check(absf(top - on.y) < 0.3, "the stairs at %s: ground %.2f where its step is (%.2f)" % [t.origin, top, on.y])
			if f < 0.7:
				check(not _blocked(db, on + Vector3.UP * 1.0), "the stairs at %s: no invisible wall %d%% up" % [t.origin, f * 100])
	r.root.free()


## A monster that saw you follows you up each flight (the Barrows' lesson: "they can't climb the stairs").
func _follows(kind: String, from: Vector3, room: String, to: Vector3) -> void:
	var r := _rig()
	var d: Dictionary = r.d
	var mgr: MonsterManager = r.auth.monsters
	await tree.physics_frame
	await tree.physics_frame
	r.player.global_position = DungeonMap.to_world(d, to)
	var uid: int = mgr._next_uid
	mgr._ev_spawn(uid, kind, DungeonMap.to_world(d, from + Vector3.UP * 0.55), false, 0, "")
	var m: Monster = mgr.get_monster(uid)
	m.dungeon = d
	m.dungeon_room = room
	await tree.physics_frame
	m.alert(1)
	var best := INF
	for i in 900:
		await tree.physics_frame
		var gap: Vector3 = r.player.global_position - m.global_position
		best = minf(best, Vector2(gap.x, gap.z).length())
		if best < 3.2:
			break
	check(best < 3.2, "a %s from %s reaches you at %s (closest %.1f m)" % [kind, room, to, best])
	r.root.free()


## Skeletons walk straight at you, so each start stands in line with the flight's doorways (F979).
func test_a_skeleton_follows_you_up_the_first_stair() -> void:
	await _follows("lost_miner", Vector3(38.5, 0.0, 42.0), "first_foot", Vector3(26.5, DungeonMap.RUNE + 0.3, 42.0))


func test_a_skeleton_follows_you_up_the_tower_stair() -> void:
	await _follows("lost_miner", Vector3(6.0, DungeonMap.RUNE, 31.5), "tower_foot", Vector3(6.0, DungeonMap.BELL + 0.3, 43.5))


func _all(db: DungeonBuild, kind: String) -> Array:
	return db.things.keys().filter(func(id): return db.things[id].kind == kind)


## The Hall of Pillars' thin wire fires the dart wall in its west wall.
func test_the_tripwire_fires_the_darts() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var wires := _all(db, "tripwire")
	check_eq(wires.size(), 1, "one tripwire (the Hall of Pillars)")
	if wires.is_empty():
		r.root.free()
		return
	var wire: int = wires[0]
	var darts: int = db.mine._dart_of(wire)
	check(darts >= 0, "the wire fires the dart wall")
	if darts < 0:
		r.root.free()
		return
	var player: Node3D = r.player
	player.global_position = DungeonMap.to_world(d, Vector3(42.0, 0.24, 46.88))
	db.mine.host_check(r.auth, 1, player.global_position, 0.1)
	check(db.is_broken(wire), "walked into: the wire snaps")
	check(db.is_broken(darts), "and the darts fly")
	r.root.free()


## Only the Hall of Echoes' pit and the chasm under the Broken Bridge kill; the edges have floors.
func test_only_the_pit_and_the_chasm_kill() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	check_eq(d.map.deadly, ["echo_pit", "chasm"], "the pit and the chasm are the deadly places")
	for safe in ["pilgrims_door", "hall_of_pillars", "rune_gallery", "hall_of_echoes", "bell_walk", "orrins_vigil", "orrins_rest"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, safe) + Vector3.UP * 0.3), "", "standing in %s is safe" % safe)
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "chasm") + Vector3.UP * 0.3), "chasm", "the chasm's bottom kills")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "echo_pit") + Vector3.UP * 0.3), "echo_pit", "the pit's bottom kills")
	await tree.physics_frame
	check(not _blocked(db, DungeonMap.to_world(d, Vector3(5.0, DungeonMap.BELL - 0.1, 58.0))), "no floor in the bridge's open strip")
	check(_blocked(db, DungeonMap.to_world(d, Vector3(7.0, DungeonMap.BELL - 0.1, 58.0))), "a slab down the bridge's middle")
	check(_blocked(db, DungeonMap.to_world(d, Vector3(15.0, DungeonMap.RUNE - 0.1, 16.0))), "a floor round the pit's edge")
	r.root.free()
