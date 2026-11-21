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
## Rule clashes the owner hasn't answered yet (catalogue, top list): not placed.
const WAITING := ["decor/mg_lantern_post.glb", "decor/mg_toll_table.glb"]


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
	for m in WAITING:
		check(not kinds.has(m), "%s waits for the owner's answer (rule clash)" % m)


func test_decor_stands_on_the_floor_inside_the_rooms() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		for p in _decor(mp[1]):
			var at := _xz(p.mid)
			var floor_y := -99.0
			for s in map.spaces:
				if _inside(s, at):
					floor_y = maxf(floor_y, float(s[5]))
			check(absf(float(p.pos[1]) - floor_y - 0.25) < 0.06, "%s decor %s at %s stands on the floor" % [map.id, p.model, at])
			for c in _corners(p):
				var inside := false
				for s in map.spaces:
					if _inside(s, c, -0.1) and float(s[5]) >= 0.0:
						inside = true
				check(inside, "%s decor %s: its corner %s is inside a room, not in a wall" % [map.id, p.model, c])


func test_decor_keeps_off_doors_paths_and_chests() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		var plan: Dictionary = mp[1]
		var doors := []
		for pc in plan.pieces:
			if pc.id == "doorway" or String(pc.id).begins_with("stairs"):
				doors.append(_xz(pc.pos))
		var keep := []
		for p in plan.props:
			if String(p.model) in DOORS:
				doors.append(_xz(p.pos))
			if String(p.get("role", "")) == "door" or String(p.model).contains("lever"):
				keep.append([_xz(p.pos), p.model])
		for c in plan.chests:
			keep.append([_xz(c.pos), "chest " + String(c.kind)])
		if plan.has("recipe_stand"):
			keep.append([_xz(plan.recipe_stand.pos), "recipe stand"])
		for p in _decor(plan):
			var cs := _corners(p)
			var at := _xz(p.mid)
			for dv in doors:
				check(_dist(cs, dv) >= DOOR_EDGE, "%s decor %s keeps out of the doorway at %s" % [map.id, p.model, dv])
			for k in keep:
				check(_dist(cs, k[0]) >= THING_EDGE, "%s decor %s keeps 1.5 m from %s at %s" % [map.id, p.model, k[1], k[0]])
			for s in map.spaces:
				if not _inside(s, at) or float(s[5]) < 0.0:
					continue
				var ds := []
				for dv in doors:
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
				check(Geometry2D.intersect_polygons(a, b).is_empty(), "%s decor %s and %s don't overlap" % [mp[0].id, d[i].model, d[j].model])
