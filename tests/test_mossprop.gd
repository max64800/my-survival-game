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
	for spot in [[15.0, 46.4, [0.5, 2.5]], [19.0, 24.4, [2.5, 4.5, 6.0]], [45.0, 34.4, [5.5, 8.0, 10.5]]]:
		for y in spot[2]:
			check(db.ladder_at(DungeonMap.to_world(d, Vector3(spot[0], y, spot[1]))), "a ladder at %s, %.1f m" % [[spot[0], spot[1]], y])
	check(not db.ladder_at(DungeonMap.to_world(d, Vector3(31.0, 0.5, 44.0))), "no ladder in Base Camp")
	r.root.free()


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
