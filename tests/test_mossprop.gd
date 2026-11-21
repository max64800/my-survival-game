extends TestCase
## Mossprop Workings, the fourth dungeon (owner, Nov 21: skeletons again, a timber prop tower to climb, a new boss: the
## Prop Warden with his plank shield). Its map (DungeonMap.MOSSPROP), its plan (tools/dungeons/make_mossprop.py) and
## what's new for it: the rope slide from the top deck back down to Base Camp, and the Warden's front shield.

const SEEDS := [42, 7, 1234]
var _makers := {}
var _test_maker: CaveMaker


func _maker(sd: int) -> CaveMaker:
	if not _makers.has(sd):
		var was := CaveMaker.layout
		CaveMaker.use_layout(17)
		_makers[sd] = CaveMaker.new(sd)
		CaveMaker.use_layout(was)
	return _makers[sd]


## The Dungeon 4 test world: one small cave with Mossprop Workings behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_4)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _moss(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == "mossprop":
			return d
	return {}


func _apart(a: Dictionary, b: Dictionary) -> bool:
	return a.wlo.x > b.whi.x or a.whi.x < b.wlo.x or a.wlo.z > b.whi.z or a.whi.z < b.wlo.z \
		or a.wlo.y > b.whi.y or a.whi.y < b.wlo.y


func test_new_worlds_get_mossprop_too() -> void:
	var found := 0
	for sd in SEEDS:
		var m := _maker(sd)
		var d := _moss(m)
		if d.is_empty():
			continue
		found += 1
		for o in m.dungeons:
			if o != d:
				check(_apart(d, o), "seed %d: Mossprop never shares rock with %s" % [sd, o.id])
		var far := Vector2(d.mouth.x - m.cavern_spawn.x, d.mouth.z - m.cavern_spawn.z).length()
		check(far > 60.0 and far < 320.0, "seed %d: a walk away from the start (%.0f m)" % [sd, far])
	check(found >= 2, "most new worlds have Mossprop Workings (%d of %d)" % [found, SEEDS.size()])


func test_layout_16_worlds_keep_three() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(16)
	var m := CaveMaker.new(42)
	CaveMaker.use_layout(was)
	check(_moss(m).is_empty(), "an older world gets no Mossprop (its save stays the same)")


func test_the_dungeon_4_test_world() -> void:
	var m := _test_world()
	check_eq(m.rooms.size(), 1, "one small cave")
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _moss(m)
	check(not d.is_empty(), "it is Mossprop Workings")
	if d.is_empty():
		return
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var mouth: Vector2 = d.map.mouth
	var tip := DungeonMap.to_world(d, Vector3(mouth.x, 1.5, mouth.y + float(d.entry_out) - 0.5))
	check(m.sdf_at(tip) > 0.3, "the way in comes out in the small cave")


## The placement rule (CLAUDE.md, owner Nov 17): nothing the world grows inside the dungeon or in its doorway.
func test_nothing_grows_inside_mossprop() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		var d := _moss(m)
		if d.is_empty():
			continue
		for s in d.map.spaces:
			if float(s[5]) >= 0.0:
				check(m.is_reserved(DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * 0.3), "seed %d: %s kept clear" % [sd, s[0]])
		var door := DungeonMap.to_world(d, Vector3(d.map.mouth.x, 0.2, d.map.mouth.y + float(d.entry_out) + 1.0))
		check(m.is_reserved(door), "seed %d: the doorway kept clear" % sd)
		for p in m.pois:
			check(not DungeonMap.covers(d, p.pos, 1.0), "seed %d: no %s inside Mossprop" % [sd, p.type])
		for o in m._cols:
			check(not DungeonMap.covers(d, Vector3(o.x, d.mouth.y + 2.0, o.y), o.z), "seed %d: no stone column in Mossprop" % sd)
	var m42 := _maker(42)
	var d42 := _moss(m42)
	if not d42.is_empty():
		var bad := 0
		for spot in GlowPlacer.place(m42):
			if not spot.get("hidden", false) and DungeonMap.covers(d42, spot.pos, 0.5):
				bad += 1
		check_eq(bad, 0, "no crystals, roots or twigs in Mossprop or its doorway")


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan("mossprop")
	check(not plan.is_empty(), "Mossprop's plan loads")
	if plan.is_empty():
		return
	var d := _moss(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_mossprop", "the recipe stand holds Mossprop's scroll")
	check_eq(String(Items.info("scroll_mossprop").get("teaches_recipe", "")), "axe_copper", "it always teaches the Copper Axe")
	check_eq(Gems.dungeon_key(DungeonBuild.list_id(d)), "mossprop_workings", "its last chest knows its gems")
	var kinds := {}
	for c in plan.creatures:
		kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
	check_eq(int(kinds.get("prop_warden", 0)), 1, "the Prop Warden is its boss (owner's pick)")
	check_eq(int(kinds.get("foreman", 0)), 0, "not the Pit Boss again (F468: every mine its own boss)")
	var rotten := 0
	for p in plan.props:
		if "_old" in String(p.model) or "rubble_wood" in String(p.model) or "beam_snapped" in String(p.model):
			rotten += 1
	check(rotten >= 300, "lots of rotten wood (owner, Nov 21: 'right now it looks perfect'): %d" % rotten)


## Every creature stands in a space of its own map (the decks' ones in the tall cave).
func test_creatures_stand_in_their_rooms() -> void:
	var d := _moss(_test_world())
	for c in DungeonBuild.load_plan("mossprop").creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and room != "chasm", "a %s stands in a room (%s)" % [c.kind, room])


func _rig(player: Node3D = null) -> Dictionary:
	var m := _test_world()
	var root := Node3D.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	if player == null:
		player = Node3D.new()
	root.add_child(player)
	var ps := auth.add_player(1, player)
	var db := DungeonBuild.new()
	db.maker = m
	root.add_child(db)
	return {root = root, auth = auth, player = player, ps = ps, db = db, d = m.dungeons[0]}


func _all(db: DungeonBuild, kind: String) -> Array:
	return db.things.keys().filter(func(id): return db.things[id].kind == kind)


## The three ladders: onto the Lower Walk, from the Rockfall Ledge up through the deck, and the upper one to the top deck.
func test_the_ladders() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	for spot in [[15.0, 46.4, [0.5, 2.5]], [19.0, 24.4, [2.5, 4.5, 6.0]], [45.2, 34.5, [5.5, 8.0, 10.5]]]:
		for y in spot[2]:
			check(db.ladder_at(DungeonMap.to_world(d, Vector3(spot[0], y, spot[1]))), "a ladder at %s, %.1f m" % [[spot[0], spot[1]], y])
	check(not db.ladder_at(DungeonMap.to_world(d, Vector3(31.0, 0.5, 44.0))), "no ladder in Base Camp")
	# Owner, Nov 21 (F541: "way too long"): no ladder sticks up past where you step off.
	for top in [[15.0, 46.4, 3.0, "the Lower Walk's"], [19.0, 24.4, 7.0, "the Rockfall Ledge's"], [45.2, 34.5, 11.0, "the upper"]]:
		check(not db.ladder_at(DungeonMap.to_world(d, Vector3(top[0], top[2], top[1]))), "%s ladder ends at its floor" % top[3])
	var tops := {}
	for q in DungeonBuild.load_plan("mossprop").pieces:
		if q.id == "ladder":
			var key := "%.1f,%.1f" % [q.pos[0], q.pos[2]]
			tops[key] = maxf(float(tops.get(key, 0.0)), float(q.pos[1]) + 2.0 * float(q.get("scale", 1.0)))
	check(is_equal_approx(float(tops.get("15.0,46.2", 0.0)), 2.24), "the Lower Walk's ladder ends level with its boards")
	check(is_equal_approx(float(tops.get("45.2,34.2", 0.0)), 10.24), "the upper ladder ends level with the top deck")
	check(float(tops.get("19.0,24.2", 99.0)) <= 6.3, "the Rockfall ladder ends 1 m over the deck")
	r.root.free()


## Owner, Nov 21 (F546): the upper ladder's spikes. They come out of the rock on its right, two rows of stakes with a gap
## between them; asleep until you come near, then in and out for good. They hit you on the ladder, never on a deck.
func test_the_ladder_spikes() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var ps: GameAuthority.PlayerState = r.ps
	var walls := _all(db, "spears").filter(func(id): return db.things[id].prop.get("climb", false))
	check_eq(walls.size(), 2, "two spike walls by the upper ladder")
	if walls.size() != 2:
		r.root.free()
		return
	walls.sort_custom(func(a, b): return (db.things[a].xform as Transform3D).origin.y < (db.things[b].xform as Transform3D).origin.y)
	var lo: Dictionary = db.things[walls[0]]
	var hi: Dictionary = db.things[walls[1]]
	var rows := MineTraps.SPEAR_ROWS_AT.y - MineTraps.SPEAR_ROWS_AT.x
	var gap := (hi.xform as Transform3D).origin.y - (lo.xform as Transform3D).origin.y - rows
	check(gap >= 1.0, "at least a block between the stake rows (%.2f m)" % gap)
	var at := func(x: float, y: float, z: float) -> Vector3: return DungeonMap.to_world(d, Vector3(x, y, z))
	var player: Node3D = r.player
	player.global_position = at.call(30.0, 0.24, 44.0)  # far away, in Base Camp
	var t0 := 1000.0
	for id in walls:
		db.mine._move_spears(id, db.things[id], t0 + MineTraps.SPEAR_OUT + 0.1, r.auth)
		check_eq(float(db.things[id].get("out", 0.0)), 0.0, "asleep while nobody is near: the stakes stay in")
	player.global_position = at.call(45.2, 5.24, 34.9)  # at the ladder's foot, on deck 2
	db.mine._move_spears(walls[0], lo, t0, r.auth)
	check(float(lo.get("woke", -1.0)) >= 0.0, "coming near wakes it")
	var hp0: float = ps.vitals.health
	db.mine._move_spears(walls[0], lo, t0 + MineTraps.SPEAR_OUT + 0.1, r.auth)
	check(float(lo.get("out", 0.0)) > 0.9, "then it stabs")
	check_eq(ps.vitals.health, hp0, "standing on deck 2 at its foot, the stakes miss you")
	db.mine._move_spears(walls[0], lo, t0 + MineTraps.SPEAR_CYCLE - 0.2, r.auth)
	check_eq(float(lo.get("out", 1.0)), 0.0, "back in")
	db.mine._move_spears(walls[0], lo, t0 + 5.0 * MineTraps.SPEAR_CYCLE + MineTraps.SPEAR_OUT + 0.1, r.auth)
	check(float(lo.get("out", 0.0)) > 0.9, "and out again, for good")
	for y in [5.9, 6.8, 7.3]:
		check(MineTraps.in_spears(lo, at.call(45.2, y, 34.6), 1.0), "the lower row hits a climber (feet at %.1f m)" % y)
	for y in [7.9, 8.8, 9.3]:
		check(MineTraps.in_spears(hi, at.call(45.2, y, 34.6), 1.0), "the upper row hits a climber (feet at %.1f m)" % y)
	for w in [lo, hi]:
		check(not MineTraps.in_spears(w, at.call(45.2, 5.24, 34.6), 1.0), "never someone on deck 2")
		check(not MineTraps.in_spears(w, at.call(45.0, 10.24, 33.5), 1.0), "never someone on the top deck")
	r.root.free()


## Owner, Nov 21 (F543): many more rotten boards on levels 1 and 2, but deck 2 always keeps a safe way along.
func test_rotten_boards_leave_a_way() -> void:
	var plan := DungeonBuild.load_plan("mossprop")
	var bad := {}
	var boards := {}
	for p in plan.props:
		var key := "%d,%d,%d" % [roundi(p.pos[0]), roundi(p.pos[2]), roundi(p.pos[1])]
		if String(p.model) == "dungeon/trap_floor_break.glb":
			bad[key] = true
		elif String(p.model) == "dungeon/floor_old.glb":
			boards[key] = true
	for q in plan.pieces:
		if q.id == "floor":
			boards["%d,%d,%d" % [roundi(q.pos[0]), roundi(q.pos[2]), roundi(q.pos[1])]] = true
	var on := func(y: int) -> int: return bad.keys().filter(func(k): return String(k).ends_with(",%d" % y)).size()
	check(on.call(5) >= 5, "at least 5 rotten boards on deck 2 (%d)" % on.call(5))
	check(on.call(2) >= 3, "and some on level 1's walk and ledge (%d)" % on.call(2))
	# The safe way along deck 2, from the Rockfall ladder's hole to the east arm (cells' middles, each next to the last;
	# the bridge between them has no rotten boards).
	var way := [[21, 25], [23, 25], [25, 25], [27, 25], [27, 27], [29, 27], [39, 27], [41, 27], [43, 27], [45, 27]]
	for c in way:
		var key := "%d,%d,5" % [c[0], c[1]]
		check(boards.has(key) and not bad.has(key), "a sound board on deck 2 at %s" % [c])
	# The top deck (owner, Nov 21, F589): many more rotten boards, and still one sound way from the upper ladder's top,
	# past the rope slide and the Top Hall's gate, to the Crusher Gallery's door.
	check(on.call(10) >= 8, "many rotten boards on the top deck (%d)" % on.call(10))
	var top := [[45, 33], [45, 31], [45, 29], [45, 27], [43, 27], [41, 27], [39, 27], [39, 25], [37, 25], [35, 25], [33, 25],
		[31, 25], [29, 25], [29, 27], [27, 27], [25, 27], [25, 25], [23, 25], [21, 25]]
	for c in top:
		var key := "%d,%d,10" % [c[0], c[1]]
		check(boards.has(key) and not bad.has(key), "a sound board on the top deck at %s" % [c])
	for z in [31, 33, 35, 37, 39, 41, 43]:
		check(not (bad.has("15,%d,2" % z) and bad.has("15,%d,2" % (z + 2))), "never two rotten boards in a row on the Lower Walk (z %d)" % z)


## Owner, Nov 21 (F539): a real cave, many stalactites. Placement rule: none of it stands in anything built,
## hangs into the rope slide's way, or leaves less than 2 m of head room over a floor. Uses each model's real size.
func test_the_cave_keeps_clear() -> void:
	var plan := DungeonBuild.load_plan("mossprop")
	var built: Array[AABB] = []
	for q in plan.pieces:
		var sc := float(q.get("scale", 1.0))
		var h: float = {"doorway": 3.0, "floor": 0.24, "railing": 1.0, "half_wall": 1.0}.get(String(q.id), 2.0) * sc
		built.append(AABB(Vector3(q.pos[0] - sc, q.pos[1], q.pos[2] - sc), Vector3(2.0 * sc, h, 2.0 * sc)))
	for c in plan.creatures + plan.chests:
		built.append(AABB(Vector3(c.pos[0] - 0.6, c.pos[1], c.pos[2] - 0.6), Vector3(1.2, 2.0, 1.2)))
	for p in plan.props:
		if String(p.model).ends_with("floor_old.glb") or String(p.model).ends_with("trap_floor_break.glb"):
			built.append(AABB(Vector3(p.pos[0] - 1.0, p.pos[1], p.pos[2] - 1.0), Vector3(2.0, 0.24, 2.0)))
	var sizes := {}
	var drips := 0
	var lumps := 0
	var bad := 0
	for p in plan.props:
		if not p.get("grown", false):
			continue
		if not sizes.has(p.model):
			sizes[p.model] = _model_box(String(p.model))
		var short := _place_box(sizes[p.model], p).grow(-0.05)  # (a few cm of round rock corners)
		for w in built:
			if short.intersects(AABB(w.position, w.size + Vector3(0, 2.0, 0))):  # what's built, and 2 m of head room
				bad += 1
				print("  a %s at %s pokes into something built or its head room" % [p.model, p.pos])
				break
		for k in 41:  # the rope slide's rope (from its top post down to Base Camp)
			if short.grow(0.8).has_point(Vector3(38.6, 12.54, 27.4).lerp(Vector3(35.4, 2.0, 46.0), k / 40.0)):
				bad += 1
				print("  a %s at %s hangs in the rope slide's way" % [p.model, p.pos])
				break
		drips += 1 if "drip" in String(p.model) else 0
	for p in plan.props:
		lumps += 1 if "grock" in String(p.model) or "cave/shelf" in String(p.model) else 0
	check_eq(bad, 0, "the cave's stalactites keep clear of everything built and the rope slide")
	check(drips >= 16 and drips <= 40, "far fewer grown stalactites (F584: %d)" % drips)
	check_eq(lumps, 0, "no rock lumps or rock shelves (F582: \"they look awful\")")


## Owner, Nov 21 (F587): the wall on the left after the second ladder (the Prop Room's dart wall) was easy to spot and did
## nothing: it was the show-only model, with no wire or plate to fire it. Now it's the working dart wall (as at Old Pell's
## and Lampwick) with a tripwire across the room from its sill: walk into the wire and the dart hits you; walls only.
func test_the_prop_room_dart_wall_fires() -> void:
	var plan := DungeonBuild.load_plan("mossprop")
	for p in plan.props:
		check(String(p.model) != "dungeon/trap_dart_wall.glb", "no show-only dart wall left")
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var ps = r.ps
	var wires := _all(db, "tripwire")
	check_eq(wires.size(), 1, "one tripwire")
	if wires.size() != 1:
		r.root.free()
		return
	var dart: int = db.mine._dart_of(wires[0])
	check(dart >= 0, "the wire fires a dart wall")
	if dart < 0:
		r.root.free()
		return
	var wall := (db.things[dart].xform as Transform3D).origin
	check(wall.distance_to(DungeonMap.to_world(d, Vector3(16.0, 5.0, 21.0))) < 0.5, "the Prop Room's west wall")
	var player: Node3D = r.player
	player.global_position = DungeonMap.to_world(d, Vector3(18.5, 5.24, 21.0 - 0.12))  # walking north across the wire
	var hp0: float = ps.vitals.health
	db.mine.host_check(r.auth, 1, player.global_position, 0.1)
	check(db.is_broken(wires[0]), "walked into: the wire snaps")
	check(db.is_broken(dart), "and the dart fires")
	check(ps.vitals.health < hp0, "it hits you (%.0f -> %.0f)" % [hp0, ps.vitals.health])
	r.root.free()


## Owner, Nov 21 (F585, said twice): shooting the Rockfall Ledge's trapped chest with a crossbow did nothing. The cause:
## a bolt's line didn't see chests at all (their layer wasn't in its mask), so it flew through. Now it stops on the chest,
## finds the chest's spike floor, the spikes slam up with nobody on them, and the chest's lid springs open.
func test_shooting_the_trapped_chest() -> void:
	check(DwarfFight.BOLT_MASK & Storage.BOX_LAYER != 0, "a bolt can hit a chest")
	var r := _rig()
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	DungeonBuild.add_chests(auth, db.maker)
	var chest: Node3D = null
	var at := DungeonMap.to_world(r.d, Vector3(11.0, 2.84, 28.0))  # (the trapped chest's middle)
	for bid in auth.storage.boxes:
		var node: Node3D = auth.storage.boxes[bid].node
		if node.global_position.distance_to(at) < 1.0:
			chest = node
	check(chest != null, "the trapped chest is there")
	var id: int = db.mine.spikes_near(at)
	check(id >= 0, "a bolt at the chest finds its spike floor")
	if chest == null or id < 0:
		r.root.free()
		return
	var lid := ChestOpen.lid_of(chest)
	var shut := lid.rotation.x if lid else 0.0
	db.request_hit(1, id, true)
	check(db.is_broken(id), "shot: its spikes slam up")
	await tree.create_timer(0.5).timeout
	check(lid != null and absf(lid.rotation.x - shut) > 0.3, "and the chest springs open")
	r.root.free()


## Owner, Nov 21 (F590, said twice): "the crushers still don't work". They slept until someone crossed a Pack Hall,
## and Mossprop has none. Now they run from the start (like Old Pell's) and crush a dwarf under them as they slam.
func test_the_crushers_work() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	check_eq(db.crushers.size(), 2, "two crushers in the Crusher Gallery")
	if db.crushers.size() != 2:
		r.root.free()
		return
	var id: int = db.crushers[0]
	var th: Dictionary = db.things[id]
	check(db.crushers_awake(th.d), "awake from the start, with nobody near")
	var t := 1000.0 * DungeonBuild.CRUSH_CYCLE
	db._move_crusher(id, t + DungeonBuild.CRUSH_SLAM + 0.1, r.auth)
	check(float(th.down) >= 1.0, "its weight comes down")
	db._move_crusher(id, t + DungeonBuild.CRUSH_CYCLE * 0.9, r.auth)
	check(float(th.down) < 0.5, "and goes back up")
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 100.0
	(r.player as Node3D).global_position = (th.xform as Transform3D).origin + Vector3.UP * 0.25
	db._clock = 100.0
	db._move_crusher(id, t + 0.05, r.auth)  # (0.05 s into its slam)
	check(ps.vitals.health <= 0.0, "a dwarf under it while it slams is crushed")
	r.root.free()


## Owner, Nov 21 (F584): "far too many stalactites, and very few of them actually fall". The cave's loose ones (not
## the Rockfall Ledge's 3) are real falling traps: a dwarf walking under each brings it down, and it lands on him.
func test_the_cave_stalactites_fall() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var player: Node3D = r.player
	var fell := 0
	var drips := 0
	for id in _all(db, "drip"):
		var th: Dictionary = db.things[id]
		var local := DungeonMap.to_local(th.d, th.centre)
		if local.x < 21.0 and local.z < 31.0:
			continue  # (the Rockfall Ledge's: test_dungeon's)
		drips += 1
		var c: Vector3 = th.centre
		var under := Vector3(c.x, float(th.landing) + 0.05, c.z)
		for k in 30:  # walking past at 4 m/s, 0.6 m to one side, through the host's check
			player.global_position = under + Vector3(-3.0 + 0.4 * k, 0, 0.6)
			db._host_tick = 0.0
			db._physics_process(0.1)
			if db.is_broken(id):
				break
		if not db.is_broken(id):
			print("  stalactite %d at %s did not fall (landing %.2f)" % [id, local, float(th.landing)])
			continue
		if db.drip_damage(th, under) >= 50.0:  # (where it lands: right under it)
			fell += 1
		else:
			print("  stalactite %d at %s fell but didn't hurt" % [id, local])
	check(drips >= 8 and drips <= 16, "a handful of loose stalactites in the cave (%d)" % drips)
	check_eq(fell, drips, "every one of them falls on a dwarf walking under it and hurts")
	r.root.free()


## Owner, Nov 21 (F583): the cave isn't a dug-out box: its side walls, south wall and roof bulge and dimple (the floor
## stays flat). The rock never moves into anything built (placement rule), and every stalactite hangs from the real roof.
func test_the_rock_keeps_off_the_tower() -> void:
	var rough := DungeonMap.place(DungeonMap.MOSSPROP, Vector3(30.0, 0.0, 60.0), 0, 8.0)
	var flat_map: Dictionary = DungeonMap.MOSSPROP.duplicate(true)
	flat_map.erase("rough")
	var flat := DungeonMap.place(flat_map, Vector3(30.0, 0.0, 60.0), 0, 8.0)
	check(DungeonMap.to_local(rough, Vector3(20.0, 3.0, 40.0)).is_equal_approx(Vector3(20.0, 3.0, 40.0)), "(the test map's metres are the plan's)")
	# It really is rough: how far in or out each wall goes along its length, high up (no keep-clear zones there).
	var r: Dictionary = DungeonMap.MOSSPROP.rough
	for wall in 4:
		var lo := 99.0
		var hi := -99.0
		for k in 27:
			var a := 24.0 + k if wall < 2 else 15.0 + k * 1.15
			var v := DungeonMap.rough_bump(r, wall, a, 11.0 if wall < 3 else 40.0 + (k % 5), Vector3(30.0, 16.0, 40.0))
			lo = minf(lo, v)
			hi = maxf(hi, v)
		check(lo < -0.8 and hi > 0.8, "wall %d bulges in (%.1f m) and dimples out (%.1f m)" % [wall, -lo, hi])
	check(absf(DungeonMap.sdf(rough, Vector3(30.0, 0.2, 40.0)) - DungeonMap.sdf(flat, Vector3(30.0, 0.2, 40.0))) < 0.01, "the floor stays flat")
	# Nothing built has rock pushed into it: at each thing's corners the rock is no nearer than before (or over 1 m off).
	var plan := DungeonBuild.load_plan("mossprop")
	var spots: Array = []
	for q in plan.pieces:
		var sc := float(q.get("scale", 1.0))
		var h: float = {"doorway": 3.0, "floor": 0.24, "railing": 1.0, "half_wall": 1.0}.get(String(q.id), 2.0) * sc
		for c in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1), Vector3.ZERO]:
			for y in [0.1, h]:
				spots.append([String(q.id), Vector3(q.pos[0], q.pos[1], q.pos[2]) + c * 0.95 * sc + Vector3.UP * y])
	for p in plan.props + plan.creatures + plan.chests:
		if p.get("grown", false) or "trap_drip" in String(p.get("model", "")):
			continue  # (stalactites hang from the roof: checked below)
		for y in [0.1, 1.5]:
			spots.append([String(p.get("model", p.get("kind", ""))), Vector3(p.pos[0], p.pos[1], p.pos[2]) + Vector3.UP * y])
	var bad := 0
	for sp in spots:
		var at: Vector3 = sp[1]
		var was := DungeonMap.sdf(flat, at)
		if DungeonMap.sdf(rough, at) < minf(was, 1.0) - 0.02:
			bad += 1
			if bad < 6:
				print("  the rock moves into %s at %s" % [sp[0], at])
	check_eq(bad, 0, "the rough rock keeps off everything built (%d spots checked)" % spots.size())
	# Every stalactite's top is in the roof's rock, and 1.5 m under it is the cave's air (none float, none are buried).
	var floating := 0
	var drips := 0
	for p in plan.props:
		var loose: bool = "trap_drip" in String(p.model) and not (p.pos[0] < 21.0 and p.pos[2] < 31.0)  # (F584's fallers)
		if not loose and (not p.get("grown", false) or not "drip" in String(p.model)):
			continue
		drips += 1
		var top := Vector3(p.pos[0], p.pos[1], p.pos[2]) + Vector3.UP * (0.1 if loose else 0.0)
		if DungeonMap.sdf(rough, top) > 0.05 or DungeonMap.sdf(rough, top - Vector3.UP * 1.5) < 0.0:
			floating += 1
			if floating < 6:
				print("  a stalactite at %s doesn't hang from the roof (%.2f, %.2f)" % [top, DungeonMap.sdf(rough, top), DungeonMap.sdf(rough, top - Vector3.UP * 1.5)])
	check(drips > 30, "(the stalactites were checked: %d)" % drips)
	check_eq(floating, 0, "every stalactite hangs from the bumpy roof")


func _model_box(model: String) -> AABB:
	var n: Node3D = (load("res://assets/models/" + model) as PackedScene).instantiate()
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t := Transform3D.IDENTITY
		var up: Node = mi
		while up != n and up != null:
			t = (up as Node3D).transform * t
			up = up.get_parent()
		var mb := t * mi.mesh.get_aabb()
		box = mb if first else box.merge(mb)
		first = false
	n.free()
	return box


## Owner, Nov 21 (F588, said twice): the wall hiding the stone chest had gaps at both sides (the cracked wall is 2 m wide,
## its hole in the shed's wall 4 m). Along that wall, 1 m up, every spot is covered by a wall, a narrow wall or the
## cracked wall itself: you only see in by breaking it.
func test_the_vault_wall_has_no_gaps() -> void:
	var plan := DungeonBuild.load_plan("mossprop")
	var walls: Array[AABB] = []
	var cracked := 0
	for q in plan.pieces:
		var w: float = {"wall": 2.0, "wall_narrow": 1.0}.get(String(q.id), 0.0)
		if w > 0.0 and absf(float(q.pos[2]) - 18.0) < 0.3 and int(q.get("rot", 0)) == 0:
			walls.append(AABB(Vector3(q.pos[0] - w * 0.5, q.pos[1], 17.8), Vector3(w, 2.0, 0.4)))
	for p in plan.props:
		if String(p.model) in ["dungeon/wall_cracked.glb", "dungeon/wall_old.glb"] and absf(float(p.pos[2]) - 18.0) < 0.3:
			var b := _place_box(_model_box(String(p.model)), p)
			walls.append(AABB(Vector3(b.position.x, b.position.y, 17.8), Vector3(b.size.x, b.size.y, 0.4)))
			cracked += 1 if "cracked" in String(p.model) else 0
	check_eq(cracked, 1, "the cracked wall is there")
	var gaps := 0
	for k in 37:
		var at := Vector3(22.4 + 0.2 * k, 6.0, 18.0)  # (the shed's floor is 5 m up)
		if not walls.any(func(b: AABB) -> bool: return b.grow(0.02).has_point(at)):
			gaps += 1
			print("  a gap in the vault's wall at x %.1f" % at.x)
	check_eq(gaps, 0, "no gaps beside the cracked wall")


## A model's box placed like DungeonBuild does it (yaw, then tilt, then scale), in the plan's metres.
func _place_box(box: AABB, p: Dictionary) -> AABB:
	var b := Basis(Vector3.UP, deg_to_rad(float(p.yaw))) * Basis(Vector3.RIGHT, deg_to_rad(float(p.get("tilt", 0.0))))
	var t := Transform3D(b.scaled_local(Vector3.ONE * float(p.get("scale", 1.0))), Vector3(p.pos[0], p.pos[1], p.pos[2]))
	return t * box


## Only the chasm kills: the decks are 5 and 10 m up, and that is fine.
func test_only_the_chasm_kills() -> void:
	var d := _moss(_test_world())
	for safe in ["base_camp", "prop_room", "top_hall", "climbers_rest"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, safe) + Vector3.UP * 0.3), "", "standing in %s is safe" % safe)
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "chasm") + Vector3.UP * 0.3), "chasm", "the chasm kills")


## The rope slide (owner, Nov 21): E at its top post on the top deck sends you down the rope to Base Camp.
func test_the_rope_slide() -> void:
	var rider := Node3D.new()
	var s := GDScript.new()
	s.source_code = "extends Node3D\nvar got := []\nfunc slide_down(a: Vector3, b: Vector3) -> void:\n\tgot = [a, b]\n"
	s.reload()
	rider.set_script(s)
	var r := _rig(rider)
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var slides := _all(db, "slide")
	check_eq(slides.size(), 1, "one rope slide")
	if slides.is_empty():
		r.root.free()
		return
	var id: int = slides[0]
	check(String(db.use_info(id).get("name", "")).begins_with("Rope slide"), "E on it says Rope slide")
	var top: Vector3 = (db.things[id].xform as Transform3D).origin
	check_eq(DungeonMap.space_at(d, top + Vector3.UP * 1.0), "great_cave", "its top post stands on the top deck, in the cave")
	check(absf(DungeonMap.to_local(d, top).y - 10.24) < 0.05, "on the top deck's boards")
	rider.global_position = DungeonMap.to_world(d, Vector3(31.0, 0.3, 44.0))
	db.request_use(1, id)
	check(rider.get("got").is_empty(), "from Base Camp you can't ride it (climb to the top post)")
	rider.global_position = top + Vector3(0.5, 0.1, 0.0)
	db.request_use(1, id)
	var got: Array = rider.get("got")
	check_eq(got.size(), 2, "at the top post, E starts the ride")
	if got.size() == 2:
		var a := DungeonMap.to_local(d, got[0])
		var b := DungeonMap.to_local(d, got[1])
		check(a.y > 11.5 and a.y < 12.5, "you grab the rope over the deck (%.1f m)" % a.y)
		var feet := DungeonMap.to_local(d, got[1]) - Vector3.UP * 1.45
		check(absf(feet.y) < 0.3, "you let go just over Base Camp's floor (feet at %.2f m)" % feet.y)
		check(b.x > 26.0 and b.x < 40.0 and b.z > 40.0 and b.z < 49.5, "and you land by Base Camp, far from the chasm (%.1f, %.1f)" % [b.x, b.z])
		check(b.z > a.z + 15.0, "the rope runs out over the cave")
	r.root.free()


## The Prop Warden's plank shield: front hits do a fifth, heavy swings and hits from behind go through.
func test_the_prop_warden() -> void:
	var w := Monsters.info("prop_warden")
	check(w.get("boss", false), "the Prop Warden is a boss")
	check(w.get("front_shield", false), "he has the plank shield")
	check_eq(String(w.get("shape", "")), "foreman", "the Pit Boss's body for now")
	check(MonsterManager.SHIELD_BLOCK > 0.0 and MonsterManager.SHIELD_BLOCK < 0.5, "a blocked hit does a little")
	# F548 (owner, Nov 21): his own moves, not the Pit Boss's; F547: less health.
	var boss_moves := {}
	for a in Monsters.info("foreman").attacks:
		boss_moves[a.name] = true
	for a in w.attacks:
		check(not boss_moves.has(a.name), "%s is his own move, not the Pit Boss's" % a.name)
	check(w.attacks.any(func(a): return a.get("lunge", false) and a.get("straight", false) and a.get("knockdown", false)), "he charges behind his shield")
	check_eq(int(w.hp), 300, "300 health (F547: 420 was way too much)")
	check(not w.get("smashes_statues", false), "he raises his miners' stone, he doesn't smash it (owner kept it, Nov 21)")
