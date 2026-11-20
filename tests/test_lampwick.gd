extends TestCase
## Lampwick Drift, the second dungeon (owner, Nov 20, F477: "Dungeon 2 should be a new dungeon. We planned it.").
## Its map (DungeonMap.LAMPWICK), its plan (tools/dungeons/make_lampwick.py), and its mine traps (MineTraps):
## lamps you light, the triple carts, the swinging boulder, bear jaws, the tripwire dart, the vault's spike floor.

const SEEDS := [42, 7, 1234]
var _makers := {}
var _test_maker: CaveMaker


func _maker(sd: int) -> CaveMaker:
	if not _makers.has(sd):
		var was := CaveMaker.layout
		CaveMaker.use_layout(15)
		_makers[sd] = CaveMaker.new(sd)
		CaveMaker.use_layout(was)
	return _makers[sd]


## The Dungeon 2 test world: one small cave with Lampwick Drift behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_2)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _lampwick(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == "lampwick":
			return d
	return {}


func test_new_worlds_get_lampwick_too() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		check_eq(m.dungeons.size(), 2, "seed %d: two dungeons" % sd)
		if m.dungeons.size() < 2:
			continue
		check_eq(String(m.dungeons[0].id), "mossgate", "seed %d: Mossgate Hold first" % sd)
		var d := _lampwick(m)
		var o: Dictionary = m.dungeons[0]
		var apart: bool = d.wlo.x > o.whi.x or d.whi.x < o.wlo.x or d.wlo.z > o.whi.z or d.whi.z < o.wlo.z \
			or d.wlo.y > o.whi.y or d.whi.y < o.wlo.y
		check(apart, "seed %d: the two dungeons never share rock" % sd)
		var far := Vector2(d.mouth.x - m.cavern_spawn.x, d.mouth.z - m.cavern_spawn.z).length()
		check(far > 60.0 and far < 300.0, "seed %d: a walk away from the start (%.0f m)" % [sd, far])


func test_layout_14_worlds_keep_only_mossgate() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(14)
	var m := CaveMaker.new(42)
	CaveMaker.use_layout(was)
	check_eq(m.dungeons.size(), 1, "an older world keeps just Mossgate Hold (its save stays the same)")


func test_the_dungeon_2_test_world() -> void:
	var m := _test_world()
	check_eq(m.rooms.size(), 1, "one small cave")
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _lampwick(m)
	check(not d.is_empty(), "it is Lampwick Drift")
	if d.is_empty():
		return
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var mouth: Vector2 = d.map.mouth
	var tip := DungeonMap.to_world(d, Vector3(mouth.x, 1.5, mouth.y + float(d.entry_out) - 0.5))
	check(m.sdf_at(tip) > 0.3, "the way in comes out in the small cave")


## Walk the dungeon 1 m at a time from the way in (on either level: the climbing rails join them).
func test_every_space_can_be_reached() -> void:
	var m := _test_world()
	var d := _lampwick(m)
	if d.is_empty():
		return
	var open := func(c: Vector2i) -> bool:
		for y in [1.0, DungeonMap.UP + 1.0]:
			if m.sdf_at(DungeonMap.to_world(d, Vector3(c.x + 0.5, y, c.y + 0.5))) > 0.3:
				return true
		return false
	var mouth: Vector2 = d.map.mouth
	var start := Vector2i(int(mouth.x), int(mouth.y) - 2)
	var seen := {start: true}
	var todo := [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for n in [c + Vector2i(1, 0), c - Vector2i(1, 0), c + Vector2i(0, 1), c - Vector2i(0, 1)]:
			if seen.has(n) or n.x < 4 or n.x > 56 or n.y < -4 or n.y > 66:
				continue
			if open.call(n):
				seen[n] = true
				todo.append(n)
	for s in d.map.spaces:
		var c := Vector2i(int((float(s[1]) + float(s[3])) * 0.5), int((float(s[2]) + float(s[4])) * 0.5))
		check(seen.has(c), "%s can be walked to" % s[0])


## The placement rule (CLAUDE.md, owner Nov 17): nothing the world grows inside the dungeon or in its doorway.
func test_nothing_grows_inside_lampwick() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		var d := _lampwick(m)
		if d.is_empty():
			continue
		for s in d.map.spaces:
			if float(s[5]) >= 0.0:
				check(m.is_reserved(DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * 0.3), "seed %d: %s kept clear" % [sd, s[0]])
		var door := DungeonMap.to_world(d, Vector3(d.map.mouth.x, 0.2, d.map.mouth.y + float(d.entry_out) + 1.0))
		check(m.is_reserved(door), "seed %d: the doorway kept clear" % sd)
		for p in m.pois:
			check(not DungeonMap.covers(d, p.pos, 1.0), "seed %d: no %s inside Lampwick" % [sd, p.type])
		for o in m._cols:
			check(not DungeonMap.covers(d, Vector3(o.x, d.mouth.y + 2.0, o.y), o.z), "seed %d: no stone column in Lampwick" % sd)
	var m42 := _maker(42)
	var d42 := _lampwick(m42)
	if not d42.is_empty():
		var bad := 0
		for spot in GlowPlacer.place(m42):
			if not spot.get("hidden", false) and DungeonMap.covers(d42, spot.pos, 0.5):
				bad += 1
		check_eq(bad, 0, "no crystals, roots or twigs in Lampwick or its doorway")


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan("lampwick")
	check(not plan.is_empty(), "Lampwick's plan loads")
	if plan.is_empty():
		return
	var d := _lampwick(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_lampwick", "the recipe stand holds Lampwick's scroll")
	check_eq(String(Items.info("scroll_lampwick").get("teaches_recipe", "")), "crossbow_copper", "it always teaches the Copper Crossbow")
	check_eq(Gems.dungeon_key("lampwick"), "lampwick_drift", "its last chest knows its gems")
	check_eq(DungeonBuild.list_id(d), "lampwick_drift", "its id in the dungeon list")
	var kinds := {}
	for c in plan.creatures:
		kinds[String(c.kind)] = int(kinds.get(String(c.kind), 0)) + 1
		check(Monsters.LIST.has(String(c.kind)) and Monsters.LIST[String(c.kind)].get("dungeon_only", false), "%s is a dungeon creature" % c.kind)
	check(kinds.get("tunnel_rat", 0) >= 10, "Tunnel Rats in four rooms")
	check(kinds.get("lost_miner", 0) >= 4, "Lost Miners")
	check_eq(kinds.get("foreman", 0), 1, "one Foreman")
	check(plan.chests.any(func(c): return c.loot == "big"), "the Foreman's big chest")


## The upper level is 3 m up: its creatures are found in their rooms and stand on its floor.
func test_creatures_stand_in_their_rooms() -> void:
	var d := _lampwick(_test_world())
	for c in DungeonBuild.load_plan("lampwick").creatures:
		var fl := float(c.get("floor", 0.0))
		var room := DungeonMap.space_at(d, DungeonMap.to_world(d, Vector3(c.pos[0], fl + 1.0, c.pos[2])))
		check(room != "", "%s at %s is in a room" % [c.kind, c.pos])
		for s in d.map.spaces:
			if s[0] == room:
				check(is_equal_approx(float(s[5]), fl) or room == "cart_junction", "%s stands on %s's floor" % [c.kind, room])
	var foreman: Array = DungeonBuild.load_plan("lampwick").creatures.filter(func(c): return c.kind == "foreman")
	check_eq(DungeonMap.space_at(d, DungeonMap.to_world(d, Vector3(foreman[0].pos[0], DungeonMap.UP + 1.0, foreman[0].pos[2]))), "office",
		"the Foreman waits in his office")


# ---------------------------------------------------------------- the traps, in a built dungeon

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


func _all(db: DungeonBuild, kind: String) -> Array:
	return db.things.keys().filter(func(id): return db.things[id].kind == kind)


func test_every_trap_is_built() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	for want in [["lamp", 20], ["cart", 3], ["wedge", 3], ["swing", 1], ["jaws", 4], ["tripwire", 1], ["dart_wall", 1],
			["chest_spikes", 1], ["drip", 3], ["rubble", 1], ["boulder", 1], ["gate", 1], ["lever", 1]]:
		check(_all(db, want[0]).size() >= want[1], "%d+ %s (%d)" % [want[1], want[0], _all(db, want[0]).size()])
	for id in _all(db, "drip"):
		var c: Vector3 = db.things[id].centre
		var land := DungeonMap.to_local(r.d, Vector3(c.x, float(db.things[id].landing), c.z)).y
		var fl := float(db.things[id].prop.get("floor", 0.0))
		check(absf(land - (fl + 0.24)) < 0.01, "a stalactite lands on its own floor (%.2f, floor %.0f)" % [land, fl])
	check_eq(db.heals.size(), 1, "one healing basin")
	r.root.free()


func test_lamps_light_for_everyone() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var id: int = _all(db, "lamp")[0]
	check(not db.use_info(id).is_empty(), "an unlit lamp: E lights it")
	(r.player as Node3D).global_position = db.things[id].centre
	db.request_use(1, id)
	check(db.mine.lit(id), "it is lit (saved in the world)")
	check(db.things[id].get("lit", false), "its flame shows")
	check(db.things[id].get("light") is OmniLight3D, "it gives light")
	check(db.use_info(id).is_empty(), "lit: nothing more to do")
	r.root.free()


## Step into a lane and its cart comes down it (after its rattle) and hits you; then it stays at the stopper.
func test_a_cart_comes_down_its_lane() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var id: int = _all(db, "cart")[0]
	var th: Dictionary = db.things[id]
	var lane: Rect2 = th.lane
	var foot := DungeonMap.to_world(r.d, Vector3(lane.get_center().x, 0.0, 35.0))
	(r.player as Node3D).global_position = foot
	var hp0: float = ps.vitals.health
	db.mine.host_check(r.auth, 1, foot, 0.1)
	check(db.is_broken(id), "stepping into the lane snaps its wedge")
	check(_all(db, "wedge").any(func(w): return db.is_broken(w)), "the wedge is gone")
	var t := 0.0
	while t < 5.0:
		db.mine.step(1.0 / 60.0)
		t += 1.0 / 60.0
	check(ps.vitals.health < hp0 - 20.0, "the cart hit the dwarf standing in its lane (%.0f)" % (hp0 - ps.vitals.health))
	var stop: Vector3 = th.path[th.path.size() - 1]
	check((th.pos as Vector3).distance_to(stop) < 0.05, "it stopped at the stopper")
	r.root.free()


func test_the_other_lanes_wait() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var carts := _all(db, "cart")
	var lane: Rect2 = db.things[carts[1]].lane
	db.mine.host_check(r.auth, 1, DungeonMap.to_world(r.d, Vector3(lane.get_center().x, 0.0, 36.0)), 0.1)
	check(db.is_broken(carts[1]), "the middle lane's cart comes")
	check(not db.is_broken(carts[0]) and not db.is_broken(carts[2]), "the other two wait")
	r.root.free()


func test_the_swinging_boulder_hits_and_can_be_shot_down() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var id: int = _all(db, "swing")[0]
	var th: Dictionary = db.things[id]
	var low := db.mine.ball_at(th, 0.0)
	var q := DungeonMap.to_local(r.d, low)
	check(q.z > 2.5 and q.z < 5.5 and q.x > 29.0 and q.x < 33.0, "at the bottom of its swing it is over the walk (%s)" % q)
	check(q.y > DungeonMap.UP + 0.6 and q.y < DungeonMap.UP + 1.6, "chest high (%.2f m over the walk)" % (q.y - DungeonMap.UP))
	var out := db.mine.ball_at(th, MineTraps.SWING_MAX)
	check(Vector2(out.x - low.x, out.z - low.z).length() > 1.8, "it swings far along the walk")
	var now := Time.get_unix_time_from_system()
	var ball := db.mine.ball_at(th, MineTraps.swing_angle(now))
	(r.player as Node3D).global_position = ball + Vector3.DOWN * 0.9
	var hp0: float = ps.vitals.health
	db.mine.step(0.0)
	check(ps.vitals.health < hp0, "standing where it swings: it hits you")
	db.request_hit(1, id, true)
	check(db.is_broken(id), "a bolt in its chain drops it")
	ps.vitals.health = hp0
	db.mine._swing_hit.clear()
	db.mine.step(0.5)
	check_eq(ps.vitals.health, hp0, "fallen, it hurts nobody")
	r.root.free()


func test_bear_jaws_bite_and_hold() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var id: int = _all(db, "jaws")[0]
	var at: Vector3 = (db.things[id].xform as Transform3D).origin
	var hp0: float = ps.vitals.health
	db.mine.host_check(r.auth, 1, at, 0.1)
	check(db.is_broken(id), "stepped on: they snap shut")
	check(hp0 - ps.vitals.health > 20.0, "and bite (%.0f)" % (hp0 - ps.vitals.health))
	check(db.mine._held.has(id), "they hold your leg")
	check(not db.use_info(id).is_empty(), "a friend can pry them open")
	var hp1: float = ps.vitals.health
	db.mine.host_check(r.auth, 1, at, 0.1)
	check_eq(ps.vitals.health, hp1, "shut jaws don't bite again")
	r.root.free()


func test_the_tripwire_fires_the_dart_and_a_jump_clears_it() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var wire: int = _all(db, "tripwire")[0]
	var at: Vector3 = (db.things[wire].xform as Transform3D).origin
	db.mine.host_check(r.auth, 1, at + Vector3.UP * 0.7, 0.1)
	check(not db.is_broken(wire), "jumping over the wire: nothing")
	var hp0: float = ps.vitals.health
	(r.player as Node3D).global_position = at
	db.mine.host_check(r.auth, 1, at, 0.1)
	check(db.is_broken(wire), "walking into it snaps it")
	check(db.is_broken(_all(db, "dart_wall")[0]), "the dart fires")
	check(ps.vitals.health < hp0, "the dart hits whoever tripped it")
	r.root.free()


func test_the_tripwire_can_be_cut() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var wire: int = _all(db, "tripwire")[0]
	(r.player as Node3D).global_position = (db.things[wire].centre as Vector3) + Vector3(0.0, -0.1, 1.2)
	db.request_hit(1, wire)
	check(db.is_broken(wire), "a hit cuts the wire")
	check(not db.is_broken(_all(db, "dart_wall")[0]), "cut, the dart never fires")
	r.root.free()


func test_the_vault_chest_spikes() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var id: int = _all(db, "chest_spikes")[0]
	var on: Vector3 = (db.things[id].xform as Transform3D) * Vector3(0, 0.25, 0.9)
	(r.player as Node3D).global_position = on
	var hp0: float = ps.vitals.health
	for i in 4:
		db.mine.host_check(r.auth, 1, on, 0.1)
	check(db.is_broken(id), "standing at the chest: the spikes slam up")
	await tree.create_timer(0.3).timeout
	check(ps.vitals.health < hp0 - 20.0, "and hurt you")
	r.root.free()
	# Shoot the chest first (any bolt near it): they go off harmlessly and stay down.
	var r2 := _rig()
	var db2: DungeonBuild = r2.db
	var id2: int = _all(db2, "chest_spikes")[0]
	var chest_at: Vector3 = (db2.things[id2].xform as Transform3D) * Vector3(0, 0.6, -1.0)
	check_eq(db2.mine.spikes_near(chest_at), id2, "a bolt at the chest finds its spikes")
	db2.request_hit(1, id2, true)
	check(db2.is_broken(id2), "shot: they slam up with nobody on them")
	await tree.create_timer(0.3).timeout  # (you shot it from across the vault: you walk on after)
	var ps2: GameAuthority.PlayerState = r2.ps
	var hp2: float = ps2.vitals.health
	(r2.player as Node3D).global_position = on
	for i in 4:
		db2.mine.host_check(r2.auth, 1, on, 0.1)
	await tree.create_timer(0.3).timeout
	check_eq(ps2.vitals.health, hp2, "then the chest is safe to open")
	r2.root.free()


func test_each_basin_keeps_its_own_water() -> void:
	check_eq(DungeonBuild.basin_key({id = "mossgate"}), "dungeon_basin", "Mossgate's basin as before")
	check(DungeonBuild.basin_key({id = "lampwick"}) != "dungeon_basin", "Lampwick's basin has its own")


# ---------------------------------------------------------------- the owner's first play of Lampwick (Nov 20)

func test_the_dart_poisons_and_carts_hurt_through_armour() -> void:
	check(MineTraps.DART_POISON >= Ailments.FULL, "one dart is a full dose of poison")
	check(MineTraps.CART_DAMAGE >= 40.0, "a cart hurts")


func test_bear_jaws_can_be_sprung_safely() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var jaws := _all(db, "jaws")
	db.request_hit(1, jaws[0], true)
	check(db.is_broken(jaws[0]), "a bolt springs them")
	(r.player as Node3D).global_position = db.things[jaws[1]].centre
	db.request_hit(1, jaws[1])
	check(db.is_broken(jaws[1]), "a hit springs them")
	var hp0: float = ps.vitals.health
	db.mine.host_check(r.auth, 1, (db.things[jaws[0]].xform as Transform3D).origin, 0.1)
	check_eq(ps.vitals.health, hp0, "sprung jaws don't bite")
	check(db.mine._held.is_empty(), "nobody is held")
	r.root.free()


## After you die and come back, the crashed carts must not block the Rail Tunnel's doorway (x 22, z 35-37).
func test_crashed_carts_leave_the_way_in_free() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	for id in _all(db, "cart"):
		var stop: Vector3 = db.things[id].path[db.things[id].path.size() - 1]
		var q := DungeonMap.to_local(r.d, stop)
		check(q.z - 0.86 > 37.1, "a stopped cart (lane x %.0f) ends at z %.2f, past the doorway" % [q.x, q.z - 0.86])
	r.root.free()


func test_the_boss_room_has_a_door() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var found := false
	for id in _all(db, "hand_door"):
		var q := DungeonMap.to_local(r.d, (db.things[id].xform as Transform3D).origin)
		if absf(q.z - 18.0) < 0.5 and q.x > 40.0 and q.x < 44.0:
			found = true
			check(not db.use_info(id).is_empty(), "E opens it")
	check(found, "a round door into the Foreman's Office")
	r.root.free()


func test_stalactites_fall_slower_here_and_quieter() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	for id in _all(db, "drip"):
		check(db.drip_time(db.things[id]) >= 0.7, "a stalactite takes a moment to come down (%.2f s)" % db.drip_time(db.things[id]))
	r.root.free()


func test_the_healing_basin_can_be_reached() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 40.0
	(r.player as Node3D).global_position = db.heals[0] + Vector3(1.0, 0, 0)
	db._check_heal(r.auth, 1, db.heals[0] + Vector3(1.0, 0, 0), 1.0)
	check(ps.vitals.health > 40.0, "standing by the basin heals you")
	var q := PhysicsRayQueryParameters3D.create(db.heals[0] + Vector3(3.0, 0.3, 0), db.heals[0] + Vector3(0.6, 0.3, 0))
	await tree.physics_frame
	var hit := db.get_world_3d().direct_space_state.intersect_ray(q)
	check(hit.is_empty() or (hit.position as Vector3).distance_to(db.heals[0]) < 0.7, "nothing blocks the walk to it (the rubble is walked over)")
	r.root.free()


func test_lampwick_creatures_follow_you_out() -> void:
	var d := _lampwick(_test_world())
	check(bool(d.map.get("chase_out", false)), "Lampwick's creatures follow you out of their room")
	check(not bool(DungeonMap.MOSSGATE.get("chase_out", false)), "Mossgate's stay in their rooms (as before)")
	var rats: Array = DungeonBuild.load_plan("lampwick").creatures.filter(func(c): return c.get("wake", []).has("cart_junction"))
	check_eq(rats.size(), 3, "the rats above the carts wake when you come into the junction")


func test_the_foreman_is_weaker_and_smashes_stone() -> void:
	var boss: Dictionary = Monsters.LIST.foreman
	check(boss.hp <= 300, "30%% less health (%d)" % boss.hp)
	check(boss.get("smashes_statues", false), "his swings break fallen miners' stone")


# ---------------------------------------------------------------- the owner's second play of Lampwick (Nov 20)

## Nothing built stands in front of a doorway (a mine prop blocked the way to the healing basin).
func test_no_prop_in_front_of_a_doorway() -> void:
	var plan := DungeonBuild.load_plan("lampwick")
	var doors: Array = plan.pieces.filter(func(p): return p.id == "doorway")
	var bad := 0
	for p in plan.pieces:
		if p.id in ["mine_prop", "column", "pillar", "beam"]:
			for dw in doors:
				var dd := Vector2(float(p.pos[0]) - float(dw.pos[0]), float(p.pos[2]) - float(dw.pos[2])).length()
				if dd < 1.8 and absf(float(p.pos[1]) - float(dw.pos[1])) < 1.0:
					bad += 1
					print("  a %s at %s in front of the doorway at %s" % [p.id, p.pos, dw.pos])
	check_eq(bad, 0, "every doorway is free to walk through")


func test_the_back_rails_have_stalactites() -> void:
	var d := _lampwick(_test_world())
	var n := 0
	for p in DungeonBuild.load_plan("lampwick").props:
		if DungeonBuild.thing_kind(p) == "drip":
			var room := DungeonMap.space_at(d, DungeonMap.to_world(d, Vector3(p.pos[0], float(p.get("floor", 0.0)) + 1.0, p.pos[2])))
			if room.begins_with("back_rails"):
				n += 1
	check(n >= 2, "stalactites at the end of the Back Rails (%d)" % n)


## It knocked him down, then hit him again and again as he got up: after a hit it leaves you alone a while.
func test_the_boulder_spares_you_while_you_get_up() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var th: Dictionary = db.things[_all(db, "swing")[0]]
	var hp0: float = ps.vitals.health
	for i in 20:  # 2 s of standing right where it swings
		var ball := db.mine.ball_at(th, MineTraps.swing_angle(Time.get_unix_time_from_system()))
		(r.player as Node3D).global_position = ball + Vector3.DOWN * 0.9
		db.mine.step(0.1)
	check_near(hp0 - ps.vitals.health, MineTraps.SWING_DAMAGE * (1.0 - ps.armor_cut()), 0.5, "hit once, not again while getting up")
	r.root.free()


func test_the_foremans_spin_shows_a_red_outline() -> void:
	var whirl: Dictionary = Monsters.LIST.foreman.attacks.filter(func(a): return a.anim == "2H_Melee_Attack_Spin")[0]
	check_eq(String(whirl.parry), "shield", "only a shield parries his spin (so it gets the red outline)")
