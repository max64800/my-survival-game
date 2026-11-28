extends TestCase
## The Hall of the Shieldbearers, the eighth dungeon (owner, Nov 28, F977): Stonehold stone, a lived-in barracks, skeleton
## soldiers, Sergeant Halfhelm (a shield-bash skeleton) the boss with the Armoury Key. Its map (DungeonMap.SHIELDBEARERS),
## its plan (tools/dungeons/make_shieldbearers.py), its decisions
## (docs/design/zone1-dungeons/2026-11-28-shieldbearers-decisions.md).

const ID := "shieldbearers"
var _test_maker: CaveMaker


## The Dungeon 8 test world: one small cave with the Hall behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_8)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _hall(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == ID:
			return d
	return {}


func test_the_dungeon_8_test_world() -> void:
	var m := _test_world()
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _hall(m)
	check(not d.is_empty(), "it is the Hall of the Shieldbearers")
	if d.is_empty():
		return
	check(d.map.spaces.size() >= 21, "at least 21 spaces (%d)" % d.map.spaces.size())
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var floors := {}
	for s in d.map.spaces:
		floors[float(s[5])] = true
	check(floors.has(0.0) and floors.has(DungeonMap.CELLAR), "the barracks at 0 and the drill cellars at %.0f m" % DungeonMap.CELLAR)


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan(ID)
	check(not plan.is_empty(), "the Hall's plan loads")
	if plan.is_empty():
		return
	var d := _hall(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_shieldbearers", "the recipe stand holds the Hall's scroll")
	check_eq(String(Items.info("scroll_shieldbearers").get("teaches_recipe", "")), DungeonList.recipe_of("hall_of_the_shieldbearers"),
		"the scroll teaches the Hall's recipe (the Bronze Shield)")
	var stone := 0
	var worn := 0
	for p in plan.pieces:
		stone += 1 if String(p.mat) == "cut_stone" else 0
		worn += 1 if "ruin" in String(p.id) else 0
	check(stone > plan.pieces.size() * 0.9, "Stonehold stone: %d of %d" % [stone, plan.pieces.size()])
	check(worn < plan.pieces.size() * 0.1, "a lived-in barracks, mostly whole (owner): %d worn of %d" % [worn, plan.pieces.size()])


## Owner: skeleton soldiers (no ghosts); one boss, Sergeant Halfhelm, with a shield.
func test_skeleton_soldiers_and_one_boss() -> void:
	var bosses := []
	for c in DungeonBuild.load_plan(ID).creatures:
		var info := Monsters.info(String(c.kind))
		check(not info.is_empty(), "%s is a monster the game knows" % c.kind)
		check(not info.get("ghost", false), "a %s is a skeleton, no ghost" % c.kind)
		if info.get("boss", false):
			bosses.append(c.kind)
	check_eq(bosses, ["halfhelm"], "one boss: Sergeant Halfhelm")
	check(Monsters.info("halfhelm").get("front_shield", false), "he holds a big shield (owner)")


func test_creatures_stand_in_their_rooms() -> void:
	var d := _hall(_test_world())
	for c in DungeonBuild.load_plan(ID).creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and not room in d.map.deadly, "a %s stands in a room (%s)" % [c.kind, room])


func test_the_captains_armoury_needs_the_armoury_key() -> void:
	check_eq(DungeonKeys.keys_of("hall_of_the_shieldbearers").map(func(k): return String(k)), ["key_armoury"], "one key: the Armoury Key")
	check_eq(String(Monsters.info("halfhelm").get("key", "")), "key_armoury", "Sergeant Halfhelm drops it")
	var doors: Array = DungeonBuild.load_plan(ID).props.filter(func(p): return String(p.label).contains("Armoury Key"))
	check_eq(doors.size(), 1, "one locked door")
	if doors.size() == 1:
		check(absf(float(doors[0].pos[0]) - 14.0) < 0.1 and absf(float(doors[0].pos[2]) - 60.0) < 0.1,
			"between the Captain's Hall and the Captain's Armoury (%s)" % [doors[0].pos])


## The way out: the barred gate from the bolt-hole into the Muster Gate, with its lever on the bolt-hole's side.
func test_the_way_out_gate_and_lever() -> void:
	var props: Array = DungeonBuild.load_plan(ID).props
	var gates: Array = props.filter(func(p): return String(p.model) == "dungeon/gate_iron.glb")
	var levers: Array = props.filter(func(p): return String(p.model) == "dungeon/lever_iron.glb")
	check_eq(gates.size(), 1, "one way-out gate")
	check_eq(levers.size(), 1, "one lever")
	if gates.size() == 1 and levers.size() == 1:
		check(float(levers[0].pos[0]) < float(gates[0].pos[0]), "the lever is on the bolt-hole's side (west of the gate)")


## The old traps the decisions reuse are all there.
func test_the_reused_traps() -> void:
	var props: Array = DungeonBuild.load_plan(ID).props
	var count := func(model: String) -> int: return props.filter(func(p): return String(p.model) == model).size()
	check_eq(count.call("dungeon/trap_spear_wall.glb"), 2, "two spear walls (Barracks Row)")
	check_eq(count.call("dungeon/trap_bear_jaws.glb"), 3, "three bear jaws (Training Yard)")
	check_eq(count.call("dungeon/tripwire_iron.glb"), 1, "one tripwire (Drill Cellar)")
	check_eq(count.call("dungeon/trap_crossbow_wall_stone.glb"), 1, "its crossbow in a guard slot")
	check_eq(count.call("dungeon/portcullis.glb"), 1, "one portcullis (Sergeant's Quarters)")
	check_eq(count.call("dungeon/trap_chest_spikes_stone.glb"), 1, "the spike-hole chest behind the boulder")
	check_eq(count.call("dungeon/wall_cracked_stone.glb"), 1, "the cracked wall to the Deserter's Stash")
	check_eq(count.call("dungeon/floor_loose_flagstone.glb"), 7, "6 fake slabs + the Kitchens' loose stone")


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
	var stairs: Array = DungeonBuild.placements(r.d, DungeonBuild.load_plan(ID)).get("build/stairs__cut_stone.glb", [])
	check_eq(stairs.size(), 16, "two flights of 4 steps, 2 wide")
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


func test_a_skeleton_follows_you_up_the_cellar_stair() -> void:
	await _follows("lost_miner", Vector3(44.0, DungeonMap.CELLAR, 16.0), "cellar_foot", Vector3(30.0, 0.3, 16.0))


func test_a_skeleton_follows_you_up_the_back_stair() -> void:
	await _follows("lost_miner", Vector3(20.0, DungeonMap.CELLAR, 6.0), "back_foot", Vector3(20.0, 0.3, 19.0))


func _all(db: DungeonBuild, kind: String) -> Array:
	return db.things.keys().filter(func(id): return db.things[id].kind == kind)


## The Drill Cellar's thin wire fires the crossbow in the guard slot of its west wall.
func test_the_tripwire_fires_the_crossbow() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var wires := _all(db, "tripwire")
	check_eq(wires.size(), 1, "one tripwire (the Drill Cellar)")
	if wires.is_empty():
		r.root.free()
		return
	var wire: int = wires[0]
	var bow: int = db.mine._dart_of(wire)
	check(bow >= 0 and MineTraps.is_crossbow(db.things[bow]), "the wire fires the crossbow in the guard slot")
	if bow < 0:
		r.root.free()
		return
	var player: Node3D = r.player
	player.global_position = DungeonMap.to_world(d, Vector3(48.0, DungeonMap.CELLAR + 0.24, 12.88))
	db.mine.host_check(r.auth, 1, player.global_position, 0.1)
	check(db.is_broken(wire), "walked into: the wire snaps")
	check(db.is_broken(bow), "and the crossbow shoots")
	r.root.free()


## Only the chasm under the Shield Bridge and the Practice Pit's spikes kill; the safe edges have stone floors.
func test_only_the_chasm_and_the_pit_kill() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	check_eq(d.map.deadly, ["practice_spikes", "chasm"], "the pit and the chasm are the deadly places")
	for safe in ["parade_ground", "training_yard", "drill_cellar", "sergeants_quarters", "captains_hall", "banner_hall"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, safe) + Vector3.UP * 0.3), "", "standing in %s is safe" % safe)
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "chasm") + Vector3.UP * 0.3), "chasm", "the chasm's bottom kills")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "practice_spikes") + Vector3.UP * 0.3), "practice_spikes",
		"the pit's bottom kills")
	await tree.physics_frame
	check(not _blocked(db, DungeonMap.to_world(d, Vector3(5.0, -0.1, 30.0))), "no floor in the bridge's open strip")
	check(_blocked(db, DungeonMap.to_world(d, Vector3(7.0, -0.1, 30.0))), "a stone slab down the bridge's middle")
	check(_blocked(db, DungeonMap.to_world(d, Vector3(43.0, DungeonMap.CELLAR - 0.1, 1.0))), "a stone floor round the pit's edge")
	r.root.free()
