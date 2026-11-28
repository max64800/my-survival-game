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


func _all(db: DungeonBuild, kind: String) -> Array:
	return db.things.keys().filter(func(id): return db.things[id].kind == kind)


## Step 3 (owner, F975): the Guard Corridor's thin wire fires a crossbow from a guard slot in the west wall: a heavy
## bolt (no poison, unlike the old dart walls).
func test_the_tripwire_fires_the_crossbow() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var wires := _all(db, "tripwire")
	check_eq(wires.size(), 1, "one tripwire (the Guard Corridor)")
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
	player.global_position = DungeonMap.to_world(d, Vector3(40.0, 0.24, 34.88))  # walking down the corridor
	var hp0: float = r.ps.vitals.health
	db.mine.host_check(r.auth, 1, player.global_position, 0.1)
	check(db.is_broken(wire), "walked into: the wire snaps")
	check(db.is_broken(bow), "and the crossbow shoots")
	var lost: float = hp0 - r.ps.vitals.health
	check(absf(lost - MineTraps.CROSSBOW_DAMAGE) < 0.5, "a heavy bolt hits you (%.0f lost)" % lost)
	r.root.free()


## Step 3: the Treasury Corridor's two chests stand on spike holes. Walking past is safe; opening one unshot stabs you;
## shoot it first and the spikes go off harmlessly.
func test_the_treasury_chests_stab_when_opened() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var traps: Array = _all(db, "chest_spikes").filter(func(id): return MineTraps.fires_on_open(db.things[id]))
	check_eq(traps.size(), 2, "two treasury chests on spike holes")
	if traps.size() < 2:
		r.root.free()
		return
	var id: int = traps[0]
	var th: Dictionary = db.things[id]
	var on: Vector3 = (th.xform as Transform3D) * Vector3(0, 0.25, 0.9)
	(r.player as Node3D).global_position = on
	var hp0: float = ps.vitals.health
	for i in 6:
		db.mine.host_check(r.auth, 1, on, 0.1)
	check(not db.is_broken(id), "walking over the spike holes: nothing happens")
	check_eq(db.mine.open_spikes_near(th.centre), id, "opening the chest finds its spikes")
	db.ask_use(id)  # (what main.gd asks when you open a chest: host -> everyone)
	check(db.is_broken(id), "opened unshot: the spikes fire")
	await tree.create_timer(0.3).timeout
	check(ps.vitals.health < hp0 - 20.0, "and stab you (%.0f -> %.0f)" % [hp0, ps.vitals.health])
	check_eq(db.mine.open_spikes_near(th.centre), -1, "spent: the chest is safe now")
	# The other one: shoot it first.
	var id2: int = traps[1]
	var th2: Dictionary = db.things[id2]
	db.request_hit(1, id2, true)
	check(db.is_broken(id2), "shot: its spikes go off with nobody on them")
	await tree.create_timer(0.3).timeout
	check_eq(db.mine.open_spikes_near(th2.centre), -1, "then it is safe to open")
	r.root.free()


## Step 3: the Coin Chute's south wall has three push walls; each slams out and shoves you north into the chute.
func test_the_push_walls_shove_you_into_the_chute() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var walls := _all(db, "push")
	check_eq(walls.size(), 3, "three push walls")
	for id in walls:
		var th: Dictionary = db.things[id]
		var t: Transform3D = th.xform
		check(th.get("block") != null, "it has a block that moves")
		check_eq(DungeonMap.space_at(d, t.origin + t.basis.z * 0.5 + Vector3.UP), "coin_chute", "in the Coin Chute")
		var front: Vector3 = t * Vector3(0.0, 0.0, 0.8)
		db.mine.host_check(r.auth, 1, front, 0.1)
		check_eq(int(th.pushes), 1, "stepping in front of it fires it")
		db.mine.host_check(r.auth, 1, front, 0.1)
		check_eq(int(th.pushes), 1, "it doesn't fire again while it is out")
		check(MineTraps.in_push(th, front, 1.0), "out, it reaches where you stood")
		var land := t.origin + t.basis.z * 2.2
		check_eq(DungeonBuild.deadly_space(d, land + Vector3.DOWN * 3.7), "chute_pit", "its shove sends you down the chute")
	r.root.free()


## Step 3: only the chute's spike pit kills (the map's deadly list); its floor is open, the walkway beside it is not.
func test_only_the_chute_kills() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	check_eq(d.map.deadly, ["chute_pit"], "the spike pit is the only deadly place")
	for safe in ["coin_chute", "workers_hall", "captains_quarters", "old_mint", "guard_shrine", "treasury_corridor"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, safe) + Vector3.UP * 0.3), "", "standing in %s is safe" % safe)
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "chute_pit") + Vector3.UP * 0.3), "chute_pit", "the chute's bottom kills")
	await tree.physics_frame
	check(not _blocked(db, DungeonMap.to_world(d, Vector3(47.0, DungeonMap.MINT - 0.1, 15.0))), "no floor over the chute")
	check(_blocked(db, DungeonMap.to_world(d, Vector3(47.0, DungeonMap.MINT - 0.1, 17.0))), "a stone floor on the walkway beside it")
	r.root.free()
