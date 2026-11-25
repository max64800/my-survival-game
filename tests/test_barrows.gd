extends TestCase
## The Quiet Barrows, the sixth dungeon (owner, Nov 25, F906): Stonehold stone, three levels each older than the one
## above, ghosts and spiders, the Barrow Keeper (a rune ghost) the boss with the Barrow Key. Its map
## (DungeonMap.BARROWS), its plan (tools/dungeons/make_barrows.py), its decisions
## (docs/design/zone1-dungeons/2026-11-25-barrows-decisions.md).

var _test_maker: CaveMaker


## The Dungeon 6 test world: one small cave with the Quiet Barrows behind its wall.
func _test_world() -> CaveMaker:
	if _test_maker == null:
		var was := CaveMaker.layout
		CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY_6)
		_test_maker = CaveMaker.new(42)
		CaveMaker.use_layout(was)
	return _test_maker


func _barrows(m: CaveMaker) -> Dictionary:
	for d in m.dungeons:
		if d.id == "barrows":
			return d
	return {}


func test_the_dungeon_6_test_world() -> void:
	var m := _test_world()
	check_eq(m.dungeons.size(), 1, "one dungeon")
	var d := _barrows(m)
	check(not d.is_empty(), "it is the Quiet Barrows")
	if d.is_empty():
		return
	check(d.map.spaces.size() >= 21, "at least 21 spaces (%d)" % d.map.spaces.size())
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var floors := {}
	for s in d.map.spaces:
		floors[float(s[5])] = true
	for f in [0.0, DungeonMap.OLDER, DungeonMap.OLDEST]:
		check(floors.has(f), "a level at %.0f m (owner: 3 levels)" % f)


func test_the_plan() -> void:
	var plan := DungeonBuild.load_plan("barrows")
	check(not plan.is_empty(), "the Barrows' plan loads")
	if plan.is_empty():
		return
	var d := _barrows(_test_world())
	var all := DungeonBuild.placements(d, plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check_eq(String(plan.recipe_stand.page), "scroll_barrows", "the recipe stand holds the Barrows' scroll")
	check_eq(String(Items.info("scroll_barrows").get("teaches_recipe", "")), DungeonList.recipe_of("the_quiet_barrows"),
		"the scroll teaches the Barrows' recipe")
	var stone := 0
	for p in plan.pieces:
		stone += 1 if String(p.mat) == "cut_stone" else 0
	check(stone > plan.pieces.size() * 0.9, "Stonehold stone (owner): %d of %d" % [stone, plan.pieces.size()])
	var kinds := {}
	for c in plan.creatures:
		kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
		check(Monsters.info(String(c.kind)).get("ghost", false) or c.kind == "cave_spider",
			"%s is a ghost or a spider (owner: 'ghosts and spiders')" % c.kind)
	check(int(kinds.get("cave_spider", 0)) > 16, "lots of spiders (%d)" % int(kinds.get("cave_spider", 0)))
	check_eq(int(kinds.get("barrow_keeper", 0)), 1, "the Barrow Keeper is the boss")
	check(Monsters.info("barrow_keeper").get("boss", false), "(a boss)")


## Owner: "older each floor": the deeper the level, the more of its walls and ceilings fell in.
func test_each_level_is_older_than_the_one_above() -> void:
	var plan := DungeonBuild.load_plan("barrows")
	var ruined := [0, 0, 0]
	var total := [0, 0, 0]
	for p in plan.pieces:
		if not String(p.id) in ["wall", "ruin_wall_worn", "ruin_wall_collapsed"]:
			continue
		var y := float(p.pos[1])
		var lvl := 0 if y > -4.5 else 1 if y > -12.5 else 2
		total[lvl] += 1
		ruined[lvl] += 1 if "ruin" in String(p.id) else 0
	var share := [0.0, 0.0, 0.0]
	for i in 3:
		share[i] = float(ruined[i]) / maxf(1.0, float(total[i]))
	check(share[0] < share[1] and share[1] < share[2], "more broken walls each level down: %s" % [share])


func test_creatures_stand_in_their_rooms() -> void:
	var d := _barrows(_test_world())
	for c in DungeonBuild.load_plan("barrows").creatures:
		var at := DungeonMap.to_world(d, Vector3(c.pos[0], float(c.floor) + 1.0, c.pos[2]))
		var room := DungeonMap.space_at(d, at)
		check(room != "" and not room in d.map.deadly, "a %s stands in a room (%s)" % [c.kind, room])


func test_only_the_chasm_kills() -> void:
	var d := _barrows(_test_world())
	for safe in ["barrow_door", "first_ring", "second_ring", "shrine", "hall_of_bones", "kings_barrow", "kings_grave"]:
		check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, safe) + Vector3.UP * 0.3), "", "standing in %s is safe" % safe)
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.space_floor(d, "chasm") + Vector3.UP * 0.3), "chasm", "the chasm kills")


func test_the_kings_grave_needs_the_keepers_key() -> void:
	check_eq(DungeonKeys.keys_of("the_quiet_barrows").map(func(k): return String(k)), ["key_barrow"], "one key: the Barrow Key")
	check_eq(String(Monsters.info("barrow_keeper").get("key", "")), "key_barrow", "the Barrow Keeper drops it")
	var doors: Array = DungeonBuild.load_plan("barrows").props.filter(func(p): return String(p.label).contains("Barrow Key"))
	check_eq(doors.size(), 1, "one locked door")
	if doors.size() == 1:
		check(absf(float(doors[0].pos[0]) - 30.0) < 0.1 and float(doors[0].pos[1]) < -15.0, "between the King's Barrow and his grave")


## The way out: a ladder up the Air Shaft from the King's Grave's level to the exit ledge (+6) over the Barrow Door.
func test_the_air_shaft_ladder_reaches_the_ledge() -> void:
	var plan := DungeonBuild.load_plan("barrows")
	var rungs: Array = plan.pieces.filter(func(p): return String(p.id) == "ladder")
	check(rungs.size() >= 11, "a ladder all the way (%d pieces)" % rungs.size())
	var lo := 99.0
	var hi := -99.0
	for p in rungs:
		lo = minf(lo, float(p.pos[1]))
		hi = maxf(hi, float(p.pos[1]))
	check(lo < DungeonMap.OLDEST + 0.5, "it starts on the shaft's floor (%.2f)" % lo)
	check(hi + 2.0 > 6.0 + 1.5, "it reaches past the ledge's floor, to step off (%.2f)" % (hi + 2.0))
	var floors: Array = plan.pieces.filter(func(p): return String(p.id) == "floor" and absf(float(p.pos[0]) - 31.0) < 0.1 and absf(float(p.pos[2]) - 59.0) < 0.1)
	for f in floors:
		## the ledge's own ceiling (+9) may cover the hole; nothing between the shaft's floor and the ledge
		check(float(f.pos[1]) < -11.0 or float(f.pos[1]) > 8.0, "nothing closes the hole (a slab at %.1f)" % float(f.pos[1]))


## The Placement rule: no spider or ghost waits on a stair or in a doorway, and the Keeper's fight is free of spiders.
func test_no_spiders_in_the_keepers_fight() -> void:
	for c in DungeonBuild.load_plan("barrows").creatures:
		if String(c.kind) != "cave_spider":
			continue
		var x := float(c.pos[0])
		var z := float(c.pos[2])
		check(not (x > 14.0 and x < 28.0 and z > 44.0 and z < 56.0 and float(c.floor) < -15.0), "no spider in the King's Barrow (%s)" % [c.pos])
