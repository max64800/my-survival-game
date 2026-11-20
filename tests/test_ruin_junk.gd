extends TestCase
## Ruin junk (owner, Nov 20; laid out by tools/ruins/ruin_junk.py, drawn by RuinJunk). The owner's placement rule, like
## test_columns_keep_out_of_the_tower: junk hugs the ruin's walls (outside: its walls and foundations); never inside a
## building piece, on a doorway, the gateway, stairs or foundation steps, within 1.5 m of a chest or where the
## Rebuilding Chest may stand, or on the path in front of the door. Checked against the plan's pieces.

const HUG := ["wall", "wall_narrow", "half_wall", "window_wall", "window_wide", "ruin_wall_worn", "ruin_wall_collapsed"]
const NEAR_WALL := 1.3    # its middle is at most this far from a wall (or, outside, a foundation's side)
const DOOR_CLEAR := 2.0
const GATE_CLEAR := 3.0
const THING_CLEAR := 1.5
const STAIR_CLEAR := 0.9  # (the tool keeps 1.0)
const PATH_CLEAR := 0.9   # from the path out of the door / gateway (the tool keeps 1.0)
## The way in, in each ruin's frame: from just inside the door (gateway) straight out.
const PATHS := {"tower": [Vector2(0.0, 3.0), Vector2(0.0, 12.0)], "outpost": [Vector2(-0.27, 13.0), Vector2(-0.27, 25.0)]}


func _ruins() -> Array:
	var out := []
	for n in RuinJunk.PLANS:
		out.append([n, RuinTower.load_plan(RuinJunk.PLANS[n]), RuinJunk.load_list(n)])
	return out


static func _top(p: Dictionary) -> float:
	return float(p.pos[1]) + Pieces.LIST[String(p.id)].size.y


static func _fp(p: Dictionary, grow := 0.0) -> PackedVector2Array:
	return Pieces.footprint(String(p.id), Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), grow)


static func _seg_dist(q: Vector2, a: Vector2, b: Vector2) -> float:
	return q.distance_to(Geometry2D.get_closest_point_to_segment(q, a, b))


static func _poly_dist(q: Vector2, poly: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(q, poly):
		return 0.0
	var d := INF
	for i in poly.size():
		d = minf(d, _seg_dist(q, poly[i], poly[(i + 1) % poly.size()]))
	return d


func test_both_ruins_have_junk() -> void:
	for r in _ruins():
		var junk: Array = r[2]
		check(junk.size() >= 10, "%s: some junk (got %d)" % [r[0], junk.size()])
		check(junk.any(func(j): return not j.inside), "%s: junk outside the walls" % r[0])
		check(junk.any(func(j): return j.inside and not j.ground), "%s: junk inside, on its floors" % r[0])
		for j in junk:
			check(ResourceLoader.exists("res://assets/models/" + String(j.model)), "%s: model %s exists" % [r[0], j.model])
	var yard: Array = _ruins()[1][2].filter(func(j): return j.inside and j.ground)
	check(yard.size() >= 5, "outpost: junk in its yard (got %d)" % yard.size())


func test_ruin_junk_keeps_off_the_ruin() -> void:
	for r in _ruins():
		var plan: Dictionary = r[1]
		var pieces: Array = plan.pieces.filter(func(p): return Pieces.LIST.has(String(p.id)))
		for j in r[2]:
			var at := Vector2(float(j.pos[0]), float(j.pos[2]))
			var y := float(j.pos[1])
			var tag := "%s: %s at %s" % [r[0], j.model, at]
			var on_floor := false
			var near_wall := INF
			for p in pieces:
				var id := String(p.id)
				var lo := float(p.pos[1])
				var hi := _top(p)
				var fp := _fp(p)
				var group: String = Pieces.LIST[id].get("group", "")
				if id in ["stairs", "foundation_steps"]:
					check(not (lo - 0.3 < y and y < hi + 0.3 and Geometry2D.is_point_in_polygon(at, _fp(p, STAIR_CLEAR))), tag + ": clear of the %s" % id)
					continue
				if group in ["floor", "foundation"] and absf(hi - y) < 0.06 and Geometry2D.is_point_in_polygon(at, fp):
					on_floor = true
					continue
				if hi > y + 0.05 and lo < y + 0.3:
					check(not Geometry2D.is_point_in_polygon(at, _fp(p, 0.05)), tag + ": not inside a %s" % id)
				if id == "doorway" and absf(lo - y) < 1.0:
					check(at.distance_to(Vector2(p.pos[0], p.pos[2])) >= DOOR_CLEAR, tag + ": off the doorway")
				if id == "gateway" and absf(lo - y) < 1.0:
					check(at.distance_to(Vector2(p.pos[0], p.pos[2])) >= GATE_CLEAR, tag + ": off the gateway")
				if id in HUG and lo - y > -0.1 and lo - y <= 0.35:
					near_wall = minf(near_wall, _poly_dist(at, fp))
				if j.ground and group == "foundation" and lo < 0.1:
					near_wall = minf(near_wall, _poly_dist(at, fp))
			check(on_floor != bool(j.ground), tag + (": on the ground (no floor piece under it)" if j.ground else ": on a floor piece"))
			check(near_wall <= NEAR_WALL, tag + ": hugs a wall (%.2f m)" % near_wall)
			for c in plan.get("chests", []):
				if absf(float(c.pos[1]) - y) < 1.0:
					check(at.distance_to(Vector2(c.pos[0], c.pos[2])) >= THING_CLEAR, tag + ": 1.5 m from the %s" % c.kind)


func test_ruin_junk_keeps_off_the_way_in() -> void:
	var tower := RuinTower.new(null)
	var outpost := RuinOutpost.new(null)
	for r in _ruins():
		var n: String = r[0]
		var spots: Array[Vector2] = (tower if n == "tower" else outpost)._chest_spots(float(r[1].get("radius", 4.2)))
		var path: Array = PATHS[n]
		for j in r[2]:
			if not j.ground:
				continue
			var at := Vector2(float(j.pos[0]), float(j.pos[2]))
			check(_seg_dist(at, path[0], path[1]) >= PATH_CLEAR, "%s: %s at %s off the way in" % [n, j.model, at])
			for s in spots:
				check(at.distance_to(s) >= THING_CLEAR, "%s: %s at %s clear of the Rebuilding Chest spot %s" % [n, j.model, at, s])
	tower.free()
	outpost.free()


## The junk inside goes when the ruin is being rebuilt; the junk outside stays.
func test_rebuilt_ruin_drops_its_inside_junk() -> void:
	var ruins := {"5": {name = "tower", junk = [["res://assets/models/dungeon/junk_bones.glb", Vector3(1, 0, 0), 0.0, true],
		["res://assets/models/dungeon/junk_rags.glb", Vector3(9, 0, 0), 0.0, false]]}}
	var rj := RuinJunk.new(null)
	rj._draw(ruins)
	check_eq(rj.count, 2, "both drawn while the ruin stands")
	rj._gone["5"] = true
	rj._draw(ruins)
	check_eq(rj.count, 1, "only the outside junk once it is rebuilt")
	rj.free()

