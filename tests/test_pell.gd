extends TestCase
## Old Pell's Diggings, the third dungeon (owner, Nov 20: "start working on dung 3"; the Foreman again as its boss).
## Its map (DungeonMap.PELL: a hut at the cave's level, the diggings 6 m below, two ladder shafts), its plan
## (tools/dungeons/make_pell.py) and what's new for it: dungeon ladders, the working dart plate, the crushers that
## never sleep, and only the spike pit killing you (its whole lower level is under 0).

const SEEDS := [42, 7, 1234]
var _makers := {}
var _test_maker: CaveMaker


func _maker(sd: int) -> CaveMaker:
	if not _makers.has(sd):
		var was := CaveMaker.layout
		CaveMaker.use_layout(16)
		_makers[sd] = CaveMaker.new(sd)
		CaveMaker.use_layout(was)
	return _makers[sd]


## The Dungeon 3 test world: one small cave with Old Pell's Diggings behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_3)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _pell(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == "pell":
			return d
	return {}


func _apart(a: Dictionary, b: Dictionary) -> bool:
	return a.wlo.x > b.whi.x or a.whi.x < b.wlo.x or a.wlo.z > b.whi.z or a.whi.z < b.wlo.z \
		or a.wlo.y > b.whi.y or a.whi.y < b.wlo.y


func test_new_worlds_get_old_pells_too() -> void:
	var found := 0
	for sd in SEEDS:
		var m := _maker(sd)
		var d := _pell(m)
		if d.is_empty():
			continue  # (a world without room for it keeps two: checked below that most have it)
		found += 1
		check_eq(String(m.dungeons[0].id), "mossgate", "seed %d: Mossgate Hold first" % sd)
		for o in m.dungeons:
			if o != d:
				check(_apart(d, o), "seed %d: Old Pell's never shares rock with %s" % [sd, o.id])
		var far := Vector2(d.mouth.x - m.cavern_spawn.x, d.mouth.z - m.cavern_spawn.z).length()
		check(far > 60.0 and far < 300.0, "seed %d: a walk away from the start (%.0f m)" % [sd, far])
	check(found >= 2, "most new worlds have Old Pell's Diggings (%d of %d)" % [found, SEEDS.size()])


func test_layout_15_worlds_keep_two() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(15)
	var m := CaveMaker.new(42)
	CaveMaker.use_layout(was)
	check(_pell(m).is_empty(), "an older world gets no Old Pell's (its save stays the same)")


func test_the_dungeon_3_test_world() -> void:
	var m := _test_world()
	check_eq(m.rooms.size(), 1, "one small cave")
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _pell(m)
	check(not d.is_empty(), "it is Old Pell's Diggings")
	if d.is_empty():
		return
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var mouth: Vector2 = d.map.mouth
	var tip := DungeonMap.to_world(d, Vector3(mouth.x, 1.5, mouth.y + float(d.entry_out) - 0.5))
	check(m.sdf_at(tip) > 0.3, "the way in comes out in the small cave")


## Walk the dungeon 1 m at a time from the way in, on both levels; the two shafts join them.
func test_every_space_can_be_reached() -> void:
	var m := _test_world()
	var d := _pell(m)
	if d.is_empty():
		return
	var ys := [1.0, DungeonMap.DOWN + 1.0]
	var open := func(c: Vector3i) -> bool:
		return m.sdf_at(DungeonMap.to_world(d, Vector3(c.x + 0.5, ys[c.y], c.z + 0.5))) > 0.3
	var shafts := []
	for s in d.map.spaces:
		if s[0] in ["shaft", "lift"]:
			shafts.append(Rect2(float(s[1]), float(s[2]), float(s[3]) - float(s[1]), float(s[4]) - float(s[2])))
	var mouth: Vector2 = d.map.mouth
	var start := Vector3i(int(mouth.x), 0, int(mouth.y) - 2)
	var seen := {start: true}
	var todo := [start]
	while not todo.is_empty():
		var c: Vector3i = todo.pop_back()
		var next := [c + Vector3i(1, 0, 0), c - Vector3i(1, 0, 0), c + Vector3i(0, 0, 1), c - Vector3i(0, 0, 1)]
		for r in shafts:
			if (r as Rect2).has_point(Vector2(c.x + 0.5, c.z + 0.5)):
				next.append(Vector3i(c.x, 1 - c.y, c.z))  # (the ladder)
		for n in next:
			if seen.has(n) or n.x < 0 or n.x > 60 or n.z < 10 or n.z > 66:
				continue
			if open.call(n):
				seen[n] = true
				todo.append(n)
	for s in d.map.spaces:
		if s[0] == "spike_pit":
			continue
		var lvl := 0 if float(s[5]) >= 0.0 else 1
		var c := Vector3i(int((float(s[1]) + float(s[3])) * 0.5), lvl, int((float(s[2]) + float(s[4])) * 0.5))
		check(seen.has(c), "%s can be walked to" % s[0])


## The placement rule (CLAUDE.md, owner Nov 17): nothing the world grows inside the dungeon or in its doorway.
func test_nothing_grows_inside_old_pells() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		var d := _pell(m)
		if d.is_empty():
			continue
		for s in d.map.spaces:
			if float(s[5]) >= 0.0:
				check(m.is_reserved(DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * 0.3), "seed %d: %s kept clear" % [sd, s[0]])
		var door := DungeonMap.to_world(d, Vector3(d.map.mouth.x, 0.2, d.map.mouth.y + float(d.entry_out) + 1.0))
		check(m.is_reserved(door), "seed %d: the doorway kept clear" % sd)
		for p in m.pois:
			check(not DungeonMap.covers(d, p.pos, 1.0), "seed %d: no %s inside Old Pell's" % [sd, p.type])
		for o in m._cols:
			check(not DungeonMap.covers(d, Vector3(o.x, d.mouth.y + 2.0, o.y), o.z), "seed %d: no stone column in Old Pell's" % sd)
	var m42 := _maker(42)
	var d42 := _pell(m42)
	if not d42.is_empty():
		var bad := 0
		for spot in GlowPlacer.place(m42):
			if not spot.get("hidden", false) and DungeonMap.covers(d42, spot.pos, 0.5):
				bad += 1
		check_eq(bad, 0, "no crystals, roots or twigs in Old Pell's or its doorway")


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan("pell")
	check(not plan.is_empty(), "Old Pell's plan loads")
	if plan.is_empty():
		return
	var d := _pell(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_pell", "the recipe stand holds Old Pell's scroll")
	check_eq(String(Items.info("scroll_pell").get("teaches_recipe", "")), "greaves_copper", "it always teaches the Copper Greaves")
	check_eq(Gems.dungeon_key(DungeonBuild.list_id(d)), "old_pells_diggings", "its last chest knows its gems")
	var kinds := {}
	for c in plan.creatures:
		kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
	check_eq(int(kinds.get("foreman", 0)), 1, "the Foreman is its boss (owner's pick)")


## Every creature stands on its own room's floor (the lower level's are 6 m down).
func test_creatures_stand_in_their_rooms() -> void:
	var d := _pell(_test_world())
	for c in DungeonBuild.load_plan("pell").creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and not room in ["shaft", "lift", "spike_pit"], "a %s stands in a room (%s)" % [c.kind, room])


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
	for want in [["tripwire", 1], ["dart_wall", 2], ["plate", 1], ["jaws", 2], ["floor", 6], ["crusher", 2], ["rubble", 1],
			["boulder", 1], ["gate", 1], ["lever", 1], ["hand_door", 1], ["spears", 4], ["push", 2],
			["lift", 1], ["lift_call", 2]]:
		check(_all(db, want[0]).size() >= want[1], "%d+ %s (%d)" % [want[1], want[0], _all(db, want[0]).size()])
	check_eq(db.heals.size(), 1, "one healing basin")
	r.root.free()


## The shaft has a ladder from the lower floor up past the upper one (you climb it like a built ladder).
func test_the_ladders() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	for spot in [[24.6, 45.55]]:
		for y in [DungeonMap.DOWN + 0.3, DungeonMap.DOWN + 3.0, -1.0, 0.3]:
			check(db.ladder_at(DungeonMap.to_world(d, Vector3(spot[0], y, spot[1]))), "a ladder at %s, %.1f m" % [spot, y])
	check(not db.ladder_at(DungeonMap.to_world(d, Vector3(36.0, 0.3, 48.0))), "no ladder in the middle of the hut")
	r.root.free()


## Only the spike pit kills: the diggings' floor is 6 m down, and that is fine.
func test_only_the_spike_pit_kills() -> void:
	var d := _pell(_test_world())
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "sorting") + Vector3.UP * 0.3), "", "standing in the Sorting Room is safe")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "dig") + Vector3.UP * 0.3), "", "so is the Last Dig")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "spike_pit") + Vector3.UP * 0.3), "spike_pit", "the spike pit kills")


func test_the_dart_plate_fires_and_can_be_used_up() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var plate: int = _all(db, "plate")[0]
	var at: Vector3 = (db.things[plate].xform as Transform3D).origin
	var hp0: float = ps.vitals.health
	(r.player as Node3D).global_position = at
	db.mine.host_check(r.auth, 1, at, 0.1)
	check(db.is_broken(plate), "stepping on the plate presses it")
	var dart := db.mine._dart_of(plate)
	check(dart >= 0 and db.is_broken(dart), "its dart wall fires")
	check(ps.vitals.health < hp0, "the dart hits whoever stepped on it")
	r.root.free()
	var r2 := _rig()
	var db2: DungeonBuild = r2.db
	var plate2: int = _all(db2, "plate")[0]
	(r2.player as Node3D).global_position = DungeonMap.space_floor(r2.d, "cave_in")
	var hp1: float = (r2.ps as GameAuthority.PlayerState).vitals.health
	db2.mine.on_hit(1, plate2, true)
	check(db2.is_broken(plate2), "a bolt sets it off from afar")
	check_eq((r2.ps as GameAuthority.PlayerState).vitals.health, hp1, "nobody in the dart's line: nobody hurt")
	r2.root.free()


func test_the_crushers_never_sleep() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	check(db.crushers_awake(r.d), "the Deep Seam's crushers run from the start")
	check_eq(db.crushers.size(), 2, "two of them")
	var a: Dictionary = db.things[db.crushers[0]]
	var b: Dictionary = db.things[db.crushers[1]]
	check(int(a.turn) != int(b.turn), "they run half a turn apart (one is always up)")
	r.root.free()


func test_the_spear_walls_stab_in_rhythm() -> void:
	check_eq(MineTraps.spear_out(0.0), 0.0, "a stab starts in the wall")
	check_eq(MineTraps.spear_out(MineTraps.SPEAR_OUT + 0.1), 1.0, "then the stakes are out")
	check_eq(MineTraps.spear_out(MineTraps.SPEAR_CYCLE - 0.3), 0.0, "and back in for the rest of the turn (time to go)")
	var r := _rig()
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	var id: int = _all(db, "spears")[0]
	var th: Dictionary = db.things[id]
	var front: Vector3 = (th.xform as Transform3D) * Vector3(0.0, 0.0, 0.5)
	check(MineTraps.in_spears(th, front, 1.0), "half a metre in front: out, they reach you")
	check(not MineTraps.in_spears(th, front, 0.0), "in the wall, they don't")
	check(not MineTraps.in_spears(th, (th.xform as Transform3D) * Vector3(0.0, 0.0, 1.4), 1.0), "1.4 m away: safe")
	(r.player as Node3D).global_position = front
	var hp0: float = ps.vitals.health
	var stab := float(th.prop.get("phase", 0.0)) + MineTraps.SPEAR_OUT + 0.1
	db.mine._move_spears(id, th, stab, r.auth)
	check(ps.vitals.health < hp0, "a stab hurts")
	var hp1: float = ps.vitals.health
	db.mine._move_spears(id, th, stab + 0.1, r.auth)
	check_eq(ps.vitals.health, hp1, "once per stab")
	r.root.free()


func test_the_push_wall_fires_once_and_rests() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var id: int = _all(db, "push")[0]
	var th: Dictionary = db.things[id]
	var front: Vector3 = (th.xform as Transform3D) * Vector3(0.0, 0.0, 0.8)
	db.mine.host_check(r.auth, 1, front, 0.1)
	check_eq(int(th.pushes), 1, "stepping in front of it fires it")
	db.mine.host_check(r.auth, 1, front, 0.1)
	check_eq(int(th.pushes), 1, "it doesn't fire again while it is out")
	check_eq(MineTraps.push_out(0.1), 0.0, "a moment's click first (jump back!)")
	check_eq(MineTraps.push_out(MineTraps.PUSH_WAIT + MineTraps.PUSH_SLAM + 0.1), 1.0, "then it is out")
	check(MineTraps.in_push(th, front, 1.0), "out, it reaches where you stood")
	var away := (th.xform as Transform3D).basis.z
	var q := DungeonMap.to_local(r.d, (th.xform as Transform3D).origin + away * 2.2)
	check(q.z > 22.0, "its shove sends you out over the rotten boards (z %.1f)" % q.z)
	check(DungeonMap.space_at(r.d, (th.xform as Transform3D).origin + away * 2.2 + Vector3.UP) == "gallery", "in the gallery, over the pit")
	r.root.free()


func test_the_rope_lift() -> void:
	var r := _rig()
	var db: DungeonBuild = r.db
	var lift: int = _all(db, "lift")[0]
	check(not db.mine.lift_up(lift), "the lift waits down in the Last Dig")
	var low: Vector3 = db.mine.lift_pos(lift)
	check(absf(DungeonMap.to_local(r.d, low).y - (DungeonMap.DOWN + 0.04)) < 0.01, "its deck level with the Last Dig's floor")
	(r.player as Node3D).global_position = low + Vector3.UP * 0.3
	db.request_use(1, lift)
	check(db.mine.lift_up(lift), "E on it: it goes up")
	var st: Array = r.auth.world_state.dungeon_lift[str(lift)]
	st[1] = float(st[1]) - MineTraps.LIFT_TIME - 1.0  # (as if it had got there)
	check(absf(DungeonMap.to_local(r.d, db.mine.lift_pos(lift)).y - 0.04) < 0.01, "up top, level with the hut's floor")
	var calls := _all(db, "lift_call")
	for c in calls:
		check_eq(db.mine.lift_of(c), lift, "the winch and the lever call it")
	var lever: int = calls.filter(func(c): return String(db.things[c].model).ends_with("lever.glb"))[0]
	(r.player as Node3D).global_position = db.things[lever].centre
	db.request_use(1, lever)
	check(not db.mine.lift_up(lift), "the lever down in the Last Dig calls it back down")
	db.request_use(1, lever)
	check(not db.mine.lift_up(lift), "not while it is moving")
	r.root.free()


## F729 (owner, Nov 22, said 4×: "the lever for the lift is still floating, has to be attached towards the wall"). It
## was moved by hand three times. Now: every lever's back plate has something solid right behind it (a wall, a wall
## piece, or the lift's post), and the lift's post stands on the floor and reaches up into the shaft's wall, clear of
## the platform riding past it.
func test_the_lift_lever_is_fixed_to_its_post() -> void:
	var plan := DungeonBuild.load_plan("pell")
	var solid: Array[AABB] = []
	for q in plan.pieces:
		var w: float = {"wall": 2.0, "wall_narrow": 1.0, "half_wall": 2.0}.get(String(q.id), 0.0)
		if w > 0.0:
			var h := 1.0 if String(q.id) == "half_wall" else 2.0
			var along_x := int(q.get("rot", 0)) % 2 == 0
			var size := Vector3(w, h, 0.3) if along_x else Vector3(0.3, h, w)
			solid.append(AABB(Vector3(q.pos[0], q.pos[1], q.pos[2]) - Vector3(size.x * 0.5, 0.0, size.z * 0.5), size))
	var post_box := AABB()
	var posts := 0
	for p in plan.props:
		var model := String(p.model)
		if model.begins_with("dungeon/wall_") or model == "dungeon/lift_post.glb":
			var b := _place_box(_model_box(model), p)
			solid.append(b)
			if model == "dungeon/lift_post.glb":
				post_box = b
				posts += 1
	check_eq(posts, 1, "the lift has its lever post")
	var levers := 0
	for p in plan.props:
		if String(p.model) != "dungeon/lever.glb":
			continue
		levers += 1
		var yaw := deg_to_rad(float(p.yaw))
		var back := -Vector3(sin(yaw), 0.0, cos(yaw))  # the lever's back plate faces -z in its model
		var behind := Vector3(p.pos[0], p.pos[1], p.pos[2]) + Vector3.UP * 1.05 + back * 0.01
		check(solid.any(func(b: AABB) -> bool: return b.has_point(behind)),
			"%s: solid right behind its back plate (at %s)" % [p.label, behind])
		check(not solid.any(func(b: AABB) -> bool: return b.has_point(behind - back * 0.15)),
			"%s: its front faces into the room, not into a wall" % p.label)
	check_eq(levers, 2, "both levers checked (the gate's and the lift's)")
	var hole: Vector2 = Vector2(44, 46)  # make_pell.py HOLES["lift"] (x 44-46, z 46-48)
	check(post_box.position.y <= DungeonMap.DOWN + 0.25, "the post stands in the Last Dig's floor boards")
	check(post_box.end.y >= DungeonMap.DOWN + 4.0, "and reaches up into the shaft's wall (%.2f m up)" % (post_box.end.y - DungeonMap.DOWN))
	check(post_box.end.x > hole.x - 0.15, "right under that wall")
	var deck := 0.75  # lift_platform.glb is 1.5 m square, centred in the shaft
	check(post_box.end.x < hole.x + 1.0 - deck, "clear of the platform riding past it")


## A model's box in its own metres (all its meshes).
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


## A model's box placed like DungeonBuild does it (yaw, then tilt, then scale), in the plan's metres.
func _place_box(box: AABB, p: Dictionary) -> AABB:
	var b := Basis(Vector3.UP, deg_to_rad(float(p.yaw))) * Basis(Vector3.RIGHT, deg_to_rad(float(p.get("tilt", 0.0))))
	var t := Transform3D(b.scaled_local(Vector3.ONE * float(p.get("scale", 1.0))), Vector3(p.pos[0], p.pos[1], p.pos[2]))
	return t * box
