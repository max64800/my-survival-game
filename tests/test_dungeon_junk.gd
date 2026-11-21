extends TestCase
## Dungeon junk (owner, Nov 20; traps-and-variety.md "Dungeon junk"; laid out by tools/dungeons/junk.py). The owner's
## placement rule, like test_columns_keep_out_of_the_tower: junk lies only along walls and in room corners, on the
## floor; never on a walk line, a stair, a bridge, a doorway, within 1.5 m in front of a door, a lever, a chest or the
## recipe stand, on a trap, on rails or on the Old Shaft's plank walk. Checked in every dungeon plan that has junk.
## Owner, Nov 22 (F506): "all of it should be across the entire room": about half lies out in the room (`spot` "room").
## Those keep off doors, chests and traps too; flat junk (no body) may lie on a walk line, solid junk keeps a lane free.

const NEAR_WALL := 1.0   # its middle is at most this far from rock (a wall or a corner; owner: not near the middle)
const DOOR_CLEAR := 2.0  # from a doorway's middle (its 3 m opening + the 1.5 m in front of it)
const THING_CLEAR := 1.5 # from a door, a lever, a chest, the recipe stand (the owner's 1.5 m)
const PATH_CLEAR := 1.1  # from the walk line between a room's doorways
const TRAP_CLEAR := 1.0
const LANE_CLEAR := 0.9  # solid junk out in the room: its middle from a walk line (junk.py: 1.0)
const DOORS := ["dungeon/dungeon_entrance.glb", "dungeon/wall_cracked.glb", "dungeon/door_loot.glb", "dungeon/gate_round.glb"]


func _plans() -> Array:
	var out := []
	for map in DungeonMap.MAPS:
		var plan := DungeonBuild.load_plan(String(map.id))
		if not plan.is_empty():
			out.append([map, plan])
	return out


static func _junk(plan: Dictionary) -> Array:
	return plan.props.filter(func(p): return p.get("role", "") == "junk")


static func _xz(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[2]))


static func _inside(s: Array, p: Vector2, margin := 0.0) -> bool:
	return p.x >= float(s[1]) - margin and p.x <= float(s[3]) + margin and p.y >= float(s[2]) - margin and p.y <= float(s[4]) + margin


static func _in_any(map: Dictionary, p: Vector2, py := 0.0) -> bool:
	for s in _on(map, py):
		if _inside(s, p):
			return true
	return false


## The rooms a piece lying at height `py` can be in (Old Pell's two levels overlap seen from above: the hut at 0 over the
## Last Dig at -6): the floors at or below it, within 3.5 m.
static func _on(map: Dictionary, py: float) -> Array:
	return map.spaces.filter(func(s): return float(s[5]) <= py + 0.1 and py - float(s[5]) < 3.5)


static func _same_level(y: float, py: float) -> bool:
	return absf(y - py) < 3.5


static func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


## The doorways of one space: doorway pieces and doors on its edge.
static func _doors_of(s: Array, doors: Array) -> Array:
	var out := []
	for d in doors:
		var dv: Vector2 = d
		if _inside(s, dv, 0.3) and not _inside(s, dv, -0.3):
			out.append(dv)
	return out


func test_mossgate_has_junk() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var j := _junk(plan)
	check(j.size() >= 120 and j.size() <= 230, "Mossgate is full of junk (%d; owner, Nov 20: \"a lot more\")" % j.size())
	var kinds := {}
	for p in j:
		kinds[p.model] = true
	check(kinds.size() >= 15, "many kinds of junk, not one copied (%d kinds)" % kinds.size())
	for m in kinds:
		check(ResourceLoader.exists("res://assets/models/" + String(m)), "junk model %s exists" % m)


func test_pell_has_junk_on_both_levels() -> void:
	var j := _junk(DungeonBuild.load_plan("pell"))
	var up := j.filter(func(p): return float(p.pos[1]) > -3.0).size()
	check(up >= 3 and j.size() - up >= 25, "Old Pell's Diggings has junk up in the hut (%d) and down in the diggings (%d)" % [up, j.size() - up])


func test_junk_lies_on_the_floor_by_a_wall() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		for p in _junk(mp[1]):
			var at := _xz(p.pos)
			var floor_y := -99.0
			for s in _on(map, float(p.pos[1])):
				if _inside(s, at):
					floor_y = maxf(floor_y, float(s[5]))
			check(floor_y > -99.0, "%s junk %s at %s is inside a room" % [map.id, p.model, at])
			check(absf(float(p.pos[1]) - floor_y - 0.25) < 0.06, "%s junk %s at %s lies on the floor" % [map.id, p.model, at])
			if p.get("spot", "") == "room":
				continue  # (out in the room: owner, Nov 22)
			var by_wall := false
			for dir in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				if not _in_any(map, at + dir * NEAR_WALL, float(p.pos[1])):
					by_wall = true
			check(by_wall, "%s junk %s at %s is along a wall or in a corner" % [map.id, p.model, at])
			check(float(p.get("tilt", 0.0)) == 0.0 and float(p.get("scale", 1.0)) == 1.0, "%s junk %s lies flat, normal size" % [map.id, p.model])


func test_junk_keeps_off_doors_paths_and_traps() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		var plan: Dictionary = mp[1]
		var doors := []
		for pc in plan.pieces:
			if pc.id == "doorway" or String(pc.id).begins_with("stairs"):
				doors.append([_xz(pc.pos), float(pc.pos[1])])
		var keep := []   # [point, how far, what]
		for p in plan.props:
			var role := String(p.get("role", ""))
			var at := _xz(p.pos)
			if String(p.model) in DOORS:
				doors.append([at, float(p.pos[1])])
			if role == "door" or String(p.model).contains("lever") or String(p.model).contains("bridge"):
				keep.append([at, THING_CLEAR, p.model, float(p.pos[1])])
			elif (role == "trap" or role == "secret") and float(p.pos[1]) < 1.0:
				keep.append([at, TRAP_CLEAR, p.model, float(p.pos[1])])
			if String(p.model).contains("rail_") or String(p.model).contains("trap_cart") or String(p.model).contains("plank_walk"):
				keep.append([at, 1.0, p.model, float(p.pos[1])])
		for c in plan.chests:
			keep.append([_xz(c.pos), THING_CLEAR, "chest " + String(c.kind), float(c.pos[1])])
		if plan.has("recipe_stand"):
			keep.append([_xz(plan.recipe_stand.pos), THING_CLEAR, "recipe stand", float(plan.recipe_stand.pos[1])])
		for p in _junk(plan):
			var at := _xz(p.pos)
			var py := float(p.pos[1])
			var dlist := []
			for dd in doors:
				if _same_level(dd[1], py):
					dlist.append(dd[0])
			for d in dlist:
				check(at.distance_to(d) >= DOOR_CLEAR, "%s junk %s at %s keeps out of the doorway at %s" % [map.id, p.model, at, d])
			for k in keep:
				if not _same_level(k[3], py):
					continue
				check(at.distance_to(k[0]) >= float(k[1]), "%s junk %s at %s keeps %.1f m from %s at %s" % [map.id, p.model, at, k[1], k[2], k[0]])
			# The walk lines of the space it lies in: doorway to doorway (or to the middle, with one doorway).
			for s in _on(map, py):
				if not _inside(s, at):
					continue
				var ds := _doors_of(s, dlist)
				var mid := Vector2((float(s[1]) + float(s[3])) / 2.0, (float(s[2]) + float(s[4])) / 2.0)
				var out_in_room: bool = p.get("spot", "") == "room"
				if out_in_room and DungeonBuild._is_flat_junk(String(p.model)):
					continue  # (you walk over it)
				var clear := LANE_CLEAR if out_in_room else PATH_CLEAR
				if ds.size() == 1:
					check(_seg(at, ds[0], mid) >= clear, "%s junk %s at %s is off the walk line in %s" % [map.id, p.model, at, s[0]])
				for i in ds.size():
					for k2 in range(i + 1, ds.size()):
						check(_seg(at, ds[i], ds[k2]) >= clear, "%s junk %s at %s is off the walk line %s-%s in %s" % [map.id, p.model, at, ds[i], ds[k2], s[0]])


## Holes and narrow ways: no junk in Mossgate's chasm or spike pit (or on the bridge), none on Lampwick's rails or
## the Old Shaft (its plank walk).
func test_no_junk_over_drops_rails_or_the_plank_walk() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		for p in _junk(mp[1]):
			var at := _xz(p.pos)
			for s in _on(map, float(p.pos[1])):
				var nm := String(s[0])
				var drop: bool = (float(s[5]) < 0.0 and map.id != "pell") or nm == "chasm" or nm.begins_with("shaft_") or nm == "spike_pit"   # (and 0.8 m from its edge)
				var rails := nm.contains("rail") or nm == "old_shaft"   # (the rail pieces themselves: 1 m, test above)
				check(not (drop and _inside(s, at, 0.8)) and not (rails and _inside(s, at)), "%s junk %s at %s keeps off %s" % [map.id, p.model, at, nm])


func test_half_the_junk_lies_out_in_the_rooms() -> void:
	var j := _junk(DungeonBuild.load_plan("mossgate"))
	var out := j.filter(func(p): return p.get("spot", "") == "room").size()
	check(out >= j.size() / 3 and out <= j.size() * 3 / 4, "about half of Mossgate's junk lies out in the rooms (%d of %d; owner, Nov 22)" % [out, j.size()])


## Owner, Nov 22: "no more than one item of each in the same room" (candles and pots may come in numbers).
func test_no_junk_twice_in_a_room() -> void:
	for mp in _plans():
		var map: Dictionary = mp[0]
		var seen := {}
		for p in _junk(mp[1]):
			var m := String(p.model)
			if m.contains("candle") or m.contains("junk_urn"):
				continue
			var at := _xz(p.pos)
			for s in _on(map, float(p.pos[1])):
				if _inside(s, at) and String(s[0]) != "shaft":
					var key := "%s/%s" % [s[0], m]
					check(not seen.has(key), "%s: %s lies only once in %s" % [map.id, m, s[0]])
					seen[key] = true
					break


func test_junk_has_no_body_but_old_props_still_smash() -> void:
	check(DungeonBuild._is_flat_junk("dungeon/junk_rags_b.glb"), "rags: you walk over them")
	check(DungeonBuild._is_flat_junk("treasure/tr_mug.glb"), "a mug on the floor: no body")
	check(not DungeonBuild._is_flat_junk("decor/crate_stack.glb"), "a crate as junk is still solid")
	check("decor/crate_stack.glb" in DungeonBuild.SMASH, "and you can still smash it")
