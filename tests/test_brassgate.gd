extends TestCase
## The Brassgate Vault, the seventh dungeon (owner, Nov 28, F975): Stonehold stone, grand and mostly whole, lost miners
## in the toll halls and ghosts in the old mint below, the Vault Captain (a big armoured lost miner) the boss with the
## Vault Key. Its map (DungeonMap.BRASSGATE), its plan (tools/dungeons/make_brassgate.py), its decisions
## (docs/design/zone1-dungeons/2026-11-28-brassgate-decisions.md).

var _test_maker: CaveMaker


## The Dungeon 7 test world: one small cave with the Brassgate Vault behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_7)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _vault(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == "brassgate":
			return d
	return {}


func test_the_dungeon_7_test_world() -> void:
	var m := _test_world()
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _vault(m)
	check(not d.is_empty(), "it is the Brassgate Vault")
	if d.is_empty():
		return
	check(d.map.spaces.size() >= 21, "at least 21 spaces (%d)" % d.map.spaces.size())
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var floors := {}
	for s in d.map.spaces:
		floors[float(s[5])] = true
	check(floors.has(0.0) and floors.has(DungeonMap.MINT), "the toll halls at 0 and the old mint at %.0f m" % DungeonMap.MINT)


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan("brassgate")
	check(not plan.is_empty(), "the Vault's plan loads")
	if plan.is_empty():
		return
	var d := _vault(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_brassgate", "the recipe stand holds the Vault's scroll")
	check_eq(String(Items.info("scroll_brassgate").get("teaches_recipe", "")), DungeonList.recipe_of("brassgate_vault"),
		"the scroll teaches the Vault's recipe")
	var stone := 0
	var worn := 0
	for p in plan.pieces:
		stone += 1 if String(p.mat) == "cut_stone" else 0
		worn += 1 if "ruin" in String(p.id) else 0
	check(stone > plan.pieces.size() * 0.9, "Stonehold stone (owner): %d of %d" % [stone, plan.pieces.size()])
	check(worn < plan.pieces.size() * 0.1, "grand, mostly whole (owner): %d worn of %d" % [worn, plan.pieces.size()])


## Owner: lost miners up in the toll halls, ghosts down in the mint; one boss, the Vault Captain.
func test_lost_miners_above_and_ghosts_below() -> void:
	var bosses := []
	for c in DungeonBuild.load_plan("brassgate").creatures:
		var info := Monsters.info(String(c.kind))
		check(not info.is_empty(), "%s is a monster the game knows" % c.kind)
		if info.get("boss", false):
			bosses.append(c.kind)
		if float(c.floor) < -5.0 and c.kind != "vault_guard" and c.kind != "lost_miner":
			check(info.get("ghost", false), "a %s in the old mint is a ghost" % c.kind)
		if float(c.floor) > -1.0:
			check(not info.get("ghost", false), "a %s in the toll halls is no ghost (lost miners up there)" % c.kind)
	check_eq(bosses, ["vault_captain"], "one boss: the Vault Captain")
	check(Monsters.info("vault_captain").get("front_shield", false), "he holds a big shield (owner)")


func test_creatures_stand_in_their_rooms() -> void:
	var d := _vault(_test_world())
	for c in DungeonBuild.load_plan("brassgate").creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and not room in d.map.deadly, "a %s stands in a room (%s)" % [c.kind, room])


func test_the_strongroom_needs_the_vault_key() -> void:
	check_eq(DungeonKeys.keys_of("brassgate_vault").map(func(k): return String(k)), ["key_vault"], "one key: the Vault Key")
	check_eq(String(Monsters.info("vault_captain").get("key", "")), "key_vault", "the Vault Captain drops it")
	var doors: Array = DungeonBuild.load_plan("brassgate").props.filter(func(p): return String(p.label).contains("Vault Key"))
	check_eq(doors.size(), 1, "one locked door")
	if doors.size() == 1:
		check(absf(float(doors[0].pos[0]) - 16.0) < 0.1 and absf(float(doors[0].pos[2]) - 50.0) < 0.1,
			"between the Vault Hall and the Strongroom (%s)" % [doors[0].pos])


## The way out: the barred gate from the Bolt-hole into the Brass Gate, with its lever on the Bolt-hole's side.
func test_the_way_out_gate_and_lever() -> void:
	var props: Array = DungeonBuild.load_plan("brassgate").props
	var gates: Array = props.filter(func(p): return String(p.model) == "dungeon/gate_iron.glb")
	var levers: Array = props.filter(func(p): return String(p.model) == "dungeon/lever_iron.glb")
	check_eq(gates.size(), 1, "one way-out gate")
	check_eq(levers.size(), 1, "one lever")
	if gates.size() == 1 and levers.size() == 1:
		check(float(levers[0].pos[0]) < float(gates[0].pos[0]), "the lever is on the Bolt-hole's side (west of the gate)")


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
	var stairs: Array = DungeonBuild.placements(r.d, DungeonBuild.load_plan("brassgate")).get("build/stairs__cut_stone.glb", [])
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


func test_a_ghost_follows_you_up_the_mint_stair() -> void:
	await _follows("ghost_a", Vector3(50.0, DungeonMap.MINT, 34.0), "mint_foot", Vector3(40.0, 0.3, 30.0))


func test_a_ghost_follows_you_up_the_back_stair() -> void:
	await _follows("ghost_c", Vector3(28.0, DungeonMap.MINT, 7.0), "back_foot", Vector3(28.0, 0.3, 22.0))


## Step 2 (owner, F975): the Vault Captain's big shield blocks from the front; hit him from the side, or right after a
## swing or a charge, when he lowers it. He wears his own brass look (not the Prop Warden's).
func test_the_captain_lowers_his_shield() -> void:
	var r := _rig()
	var mgr: MonsterManager = r.auth.monsters
	await tree.physics_frame
	var uid: int = mgr._next_uid
	mgr._ev_spawn(uid, "vault_captain", Vector3(0, 0.5, 0), false, 0, "")
	var m: Monster = mgr.get_monster(uid)
	await tree.process_frame
	check(m.rig != null and m.rig.shield != null, "he holds his shield up in front")
	check(m.model.find_child("shield", true, false) != null, "his own shield is on his model")
	check(MonsterModel.RIG_LOOKS.vault_captain == ["vault_captain"], "his own brass look")
	if m.rig == null or m.rig.shield == null:
		r.root.free()
		return
	var front := m.global_position - m.model.global_basis.z * 2.0
	var side := m.global_position + m.model.global_basis.x * 2.0
	m.state = Monster.State.CHASE
	check(mgr._shield_blocks(m, front, false), "it blocks from the front")
	check(not mgr._shield_blocks(m, side, false), "not from the side")
	m.rig.lower_shield(1.0)
	check(m.rig.shield_lowered(), "after a swing he lowers it")
	check(not mgr._shield_blocks(m, front, false), "so a hit from the front gets through then")
	await tree.create_timer(1.5).timeout
	check(not m.rig.shield_lowered(), "and then he lifts it again")
	m.state = Monster.State.RECOVER
	check(not mgr._shield_blocks(m, front, false), "it is down while he gets his breath back (the host's word)")
	r.root.free()
