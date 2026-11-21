extends TestCase
## Dungeon decor from the decor catalogue (docs/art/DECOR-CATALOG.md, owner Nov 22: every piece in its own room and
## spot; laid out by tools/dungeons/decor.py). The owner's placement rules, like the junk's (test_dungeon_junk):
## every catalogue piece (`cat` in the plan) stands on the floor, its whole footprint inside the dungeon's rooms (never
## inside a wall), off the walk lines between doorways, 2 m from a doorway's middle, 1.5 m from a door, lever, chest or
## the recipe stand, and no two pieces overlap. Pieces with an unanswered rule clash stay out.

const PATH_MID := 1.1    # its middle from a walk line (decor.py uses 1.2; a little slack for rounding)
const PATH_EDGE := 0.9   # every footprint corner from a walk line (decor.py: 1.0)
const DOOR_EDGE := 1.9   # its footprint from a doorway's middle (decor.py: 2.0)
const THING_EDGE := 1.4  # from a door, lever, chest, the recipe stand (decor.py: 1.5)
const DOORS := ["dungeon/dungeon_entrance.glb", "dungeon/wall_cracked.glb", "dungeon/door_loot.glb", "dungeon/gate_round.glb"]
## The rule-clash pieces, placed once the owner said the rules are fluid (Nov 22): lit, rails, stains, coins.
const CLASH_PIECES := {
	"mossgate": ["mg_barricade", "mg_lantern_post", "mg_toll_table"],
	"lampwick": ["lw_lamp_rack_wall", "lw_lamp_barrow", "lw_ledger_desk", "lw_spare_rail_rack", "lw_ore_sorting_table",
		"lw_ore_sieve_cradle", "lw_last_shift_stool", "lw_rail_switch_lever", "lw_signal_lamp_post", "lw_walkway_ladder",
		"lw_lamp_fallen_spill", "lw_cart_jammed", "lw_broken_lamp_rack"],
	"pell": ["op_trapmaker_table", "op_trap_parts_rack", "op_wire_spools", "op_still", "op_rat_traps", "op_ore_scale",
		"op_hearth_tripod", "op_bell_tripwire"],
}


func _plans() -> Array:
	var out := []
	for map in DungeonMap.MAPS:
		var plan := DungeonBuild.load_plan(String(map.id))
		if not plan.is_empty():
			out.append([map, plan])
	return out


static func _decor(plan: Dictionary) -> Array:
	return plan.props.filter(func(p): return p.get("cat", false))


static func _xz(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1] if a.size() == 2 else a[2]))


## The four corners of a piece's footprint (its middle, size and turn; +yaw turns x toward -z, like Godot).
static func _corners(p: Dictionary) -> Array:
	var m := _xz(p.mid)
	var h := Vector2(float(p.foot[0]), float(p.foot[1])) / 2.0
	var a := deg_to_rad(float(p.yaw))
	var out := []
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var l := Vector2(s.x * h.x, s.y * h.y)
		out.append(m + Vector2(l.x * cos(a) + l.y * sin(a), -l.x * sin(a) + l.y * cos(a)))
	return out


static func _dist(cs: Array, p: Vector2) -> float:
	if Geometry2D.is_point_in_polygon(p, PackedVector2Array(cs)):
		return 0.0
	var best := INF
	for i in 4:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, cs[i], cs[(i + 1) % 4])))
	return best


static func _inside(s: Array, p: Vector2, margin := 0.0) -> bool:
	return p.x >= float(s[1]) - margin and p.x <= float(s[3]) + margin and p.y >= float(s[2]) - margin and p.y <= float(s[4]) + margin


## The rooms a piece standing at height `py` can be in (Old Pell's two levels overlap seen from above: the hut at 0 over the
## Last Dig at -6): the floors at or below it, within 3.5 m.
static func _on(map: Dictionary, py: float) -> Array:
	return map.spaces.filter(func(s): return float(s[5]) <= py + 0.1 and py - float(s[5]) < 3.5)


## Is something at height `y` on the same level as a piece standing at `py`?
static func _same_level(y: float, py: float) -> bool:
	return absf(y - py) < 3.5


static func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func test_mossgate_has_its_catalogue_decor() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var d := _decor(plan)
	check(d.size() >= 25, "Mossgate has its catalogue decor (%d pieces)" % d.size())
	var kinds := {}
	for p in d:
		kinds[p.model] = true
		check(ResourceLoader.exists("res://assets/models/" + String(p.model)), "decor model %s exists" % p.model)
	check(kinds.size() >= 25, "each catalogue piece once or so, not one copied (%d kinds)" % kinds.size())


func test_the_rule_clash_pieces_are_in() -> void:
	for id in CLASH_PIECES:
		var kinds := {}
		for p in _decor(DungeonBuild.load_plan(id)):
			kinds[String(p.model)] = true
		for n in CLASH_PIECES[id]:
			check(kinds.has("decor/%s.glb" % n), "%s has %s (owner, Nov 22: the rules are fluid)" % [id, n])


func test_pell_has_its_catalogue_decor() -> void:
	var plan := DungeonBuild.load_plan("pell")
	var d := _decor(plan)
	check(d.size() >= 20, "Old Pell's Diggings has its catalogue decor (%d pieces)" % d.size())
	var kinds := {}
	for p in d:
		kinds[p.model] = true
		check(ResourceLoader.exists("res://assets/models/" + String(p.model)), "decor model %s exists" % p.model)
	for m in ["decor/op_diary_table.glb", "decor/table_overturned.glb", "decor/last_meal.glb"]:
		check(kinds.has(m), "%s is placed (owner, Nov 22: the rules are fluid, place it if it works)" % m)


func test_decor_stands_on_the_floor_inside_the_rooms() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		for p in _decor(mp[1]):
			var at := _xz(p.mid)
			var floor_y := -99.0
			for s in _on(map, float(p.pos[1])):
				if _inside(s, at):
					floor_y = maxf(floor_y, float(s[5]))
			var up := float(p.get("hung", 0.0))   # (a wall-hung board: its bottom this high over the floor)
			check(absf(float(p.pos[1]) - floor_y - 0.25 - up) < 0.06, "%s decor %s at %s stands on the floor (or hangs %.1f m up)" % [map.id, p.model, at, up])
			for c in _corners(p):
				var inside := false
				for s in _on(map, float(p.pos[1])):
					if _inside(s, c, -0.1):
						inside = true
				check(inside, "%s decor %s: its corner %s is inside a room, not in a wall" % [map.id, p.model, c])


func test_decor_keeps_off_doors_paths_and_chests() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		var plan: Dictionary = mp[1]
		var doors := []
		for pc in plan.pieces:
			if pc.id == "doorway" or String(pc.id).begins_with("stairs"):
				doors.append([_xz(pc.pos), float(pc.pos[1])])
		var keep := []
		for p in plan.props:
			if String(p.model) in DOORS:
				doors.append([_xz(p.pos), float(p.pos[1])])
			# (a real lever; the decor switch lever by Lampwick's back rails is just furniture)
			if String(p.get("role", "")) == "door" or (String(p.model).contains("lever") and not String(p.model).begins_with("decor/")):
				keep.append([_xz(p.pos), p.model, float(p.pos[1])])
		for c in plan.chests:
			keep.append([_xz(c.pos), "chest " + String(c.kind), float(c.pos[1])])
		if plan.has("recipe_stand"):
			keep.append([_xz(plan.recipe_stand.pos), "recipe stand", float(plan.recipe_stand.pos[1])])
		for p in _decor(plan):
			if float(p.get("hung", 0.0)) > 0.3:
				continue  # (hung on a wall over your head: you walk under it)
			var cs := _corners(p)
			var at := _xz(p.mid)
			var py := float(p.pos[1])
			var dlist := []
			for dd in doors:
				if _same_level(dd[1], py):
					dlist.append(dd[0])
			for dv in dlist:
				check(_dist(cs, dv) >= DOOR_EDGE, "%s decor %s keeps out of the doorway at %s" % [map.id, p.model, dv])
			for k in keep:
				if not _same_level(k[2], py):
					continue
				check(_dist(cs, k[0]) >= THING_EDGE, "%s decor %s keeps 1.5 m from %s at %s" % [map.id, p.model, k[1], k[0]])
			for s in _on(map, py):
				if not _inside(s, at):
					continue
				var ds := []
				for dv in dlist:
					if _inside(s, dv, 0.3) and not _inside(s, dv, -0.3):
						ds.append(dv)
				var mid := Vector2((float(s[1]) + float(s[3])) / 2.0, (float(s[2]) + float(s[4])) / 2.0)
				var lines := []
				if ds.size() == 1:
					lines.append([ds[0], mid])
				for i in ds.size():
					for k2 in range(i + 1, ds.size()):
						lines.append([ds[i], ds[k2]])
				for ln in lines:
					var edge := INF
					for c in cs:
						edge = minf(edge, _seg(c, ln[0], ln[1]))
					check(_seg(at, ln[0], ln[1]) >= PATH_MID and edge >= PATH_EDGE,
						"%s decor %s at %s is off the walk line %s-%s in %s" % [map.id, p.model, at, ln[0], ln[1], s[0]])


func test_decor_pieces_do_not_overlap() -> void:
	for mp in _plans():
		var d := _decor(mp[1])
		for i in d.size():
			for j in range(i + 1, d.size()):
				var a := PackedVector2Array(_corners(d[i]))
				var b := PackedVector2Array(_corners(d[j]))
				var ha := float(d[i].get("hung", 0.0)) > 0.3
				var hb := float(d[j].get("hung", 0.0)) > 0.3
				if ha != hb:
					continue  # (a board hung over a standing piece: decor.py checks their heights)
				check(Geometry2D.intersect_polygons(a, b).is_empty(), "%s decor %s and %s don't overlap" % [mp[0].id, d[i].model, d[j].model])
