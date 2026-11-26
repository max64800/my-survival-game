extends TestCase
## Ruin 14, the Sinkhole Ring (owner, Nov 26, F915; plan: docs/design/ruin14/SINKHOLE-RING-PLAN.md). It stands on
## the cave's own ground (the deep hole, its ledge, the rim, the high shelf behind), so the checks every
## learnable blueprint gets are run on it here: real pieces inside the box, nothing overlaps, nothing stands in the
## rock, nothing falls, every stair's way in and out is open, every door has room on both sides and a floor level with
## its sill (RUIN-RULES doors 9), no bracket on a window, railings don't poke out, no stairs under a ceiling. Plus the
## owner's pick (Nov 26, "stone + wood"): every building is stone below, wood above.

const ID := "sinkhole_ring"
var lib_t = load("res://tests/test_blueprint_library.gd").new()
var walk = load("res://tests/test_walk_through.gd").new()


func test_sinkhole_ring_is_sound() -> void:
	var bp := BlueprintLibrary.make(ID)
	var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
	var s := Structure.new()
	var uid := 1
	var bad := 0
	for p in bp.pieces:
		var v: Vector3 = p.pos
		var msgs := []
		if not Pieces.allowed(p.id, p.mat):
			msgs.append("%s can't be made of %s" % [p.id, p.mat])
		if p.id in ["floor_half", "small_floor", "roof_cap"]:
			msgs.append("no %s (F626)" % p.id)
		if not (absf(v.x) <= half.x and v.y >= 0.0 and v.y <= half.y and absf(v.z) <= half.z):
			msgs.append("outside the box")
		if BlueprintLibrary.sink_rock(v.x, v.y + 0.3, v.z):
			msgs.append("inside the rock")
		if s.overlaps(p.id, p.pos, p.rot):
			msgs.append("overlaps another piece")
		for m in msgs:
			bad += 1
			check(false, "%s at %s rot %d: %s" % [p.id, v, p.rot, m])
		s.add(uid, p.id, p.mat, p.pos, p.rot, BlueprintLibrary.sink_rock(v.x, v.y - 0.05, v.z))
		uid += 1
	var names := []
	for u in s.recompute():
		names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
	check(names.is_empty(), "nothing falls down (%d: %s)" % [names.size(), ", ".join(names.slice(0, 60))])
	check(bad == 0, "%d pieces, every one real, inside the box, out of the rock, not overlapping" % bp.pieces.size())


func test_sinkhole_ring_walk_through() -> void:
	var bp := BlueprintLibrary.make(ID)
	var doors := 0
	for p in bp.pieces:
		if p.id == "stairs":
			var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
			for w in [[p.pos + up, p.pos.y + 2.0, "top"], [p.pos - up, p.pos.y, "foot"]]:
				var by: String = walk._edge_blocker(bp, w[0], w[1])
				check(by == "", "stairs at %s rot %d: the %s is open (blocked by %s)" % [p.pos, p.rot, w[2], by])
			var foot: Vector3 = p.pos - up * 2.0
			var top: Vector3 = p.pos + up * 2.0
			var after := _flight_at(bp, p.pos + up * 2.0 + Vector3(0, 2, 0), p.rot)   # (two flights straight on, F838)
			var before := _flight_at(bp, p.pos - up * 2.0 - Vector3(0, 2, 0), p.rot)
			check(before or lib_t._any_floor_at(bp, foot, p.pos.y - 0.25) or lib_t._any_floor_at(bp, foot, p.pos.y),
				"stairs at %s: their foot is on open floor" % p.pos)
			check(after or lib_t._any_floor_at(bp, top, p.pos.y + 2.0) or lib_t._any_floor_at(bp, top, p.pos.y + 2.25),
				"stairs at %s: their top lands on floor" % p.pos)
		if p.id in ["door", "doorway"]:
			doors += 1
			var by: String = walk._door_blocker(bp, p)
			check(by == "", "the %s at %s rot %d has room on both sides (blocked by %s)" % [p.id, p.pos, p.rot, by])
	check(doors >= 16, "checked every door (%d)" % doors)
	for msg in lib_t.railing_ends_poking_out(bp.pieces):
		check(false, msg)
	for msg in lib_t.stairs_under_a_ceiling(bp.pieces):
		check(false, msg)


func _flight_at(bp: Blueprint, at: Vector3, rot: int) -> bool:
	return bp.pieces.any(func(q): return q.id == "stairs" and q.rot == rot and (q.pos as Vector3).distance_to(at) < 0.05)


## RUIN-RULES doors 9: every door has a floor level with its sill on both sides (or steps up to it): a floor, a
## foundation or steps whose top is within 5 cm of the door's foot, 1 m in front of it and 1 m behind it.
func test_every_door_has_a_floor_at_its_sill() -> void:
	var bp := BlueprintLibrary.make(ID)
	var doors := bp.pieces.filter(func(q): return q.id == "door")
	check(doors.size() >= 8, "the doors are there (%d)" % doors.size())
	for d in doors:
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, Pieces.yaw_of(d.rot)).round()
		for side in [-1.0, 1.0]:
			var at: Vector3 = d.pos + out * side
			var ok := bp.pieces.any(func(q): return q.id in ["floor", "floor_triangle", "foundation", "foundation_steps", "stairs"] \
				and _top_at(q, at, d.pos.y))
			check(ok, "the door at %s rot %d has floor at its sill on the %s side (%s)" % [d.pos, d.rot,
				"front" if side > 0 else "back", at])


func _top_at(q: Dictionary, at: Vector3, y: float) -> bool:
	var b := Pieces.box(q.id, q.pos, q.rot)
	if at.x < b.position.x - 0.01 or at.x > b.end.x + 0.01 or at.z < b.position.z - 0.01 or at.z > b.end.z + 0.01:
		return false
	if q.id == "foundation_steps" or q.id == "stairs":
		return absf(b.position.y - y) < 0.3 or absf(b.end.y - y) < 0.3
	return absf(b.end.y - y) < 0.05


## No bracket sits on a window's glass (the windows the brackets would hang on are moved by _brackets_off_windows).
func test_brackets_are_off_windows() -> void:
	var bp := BlueprintLibrary.make(ID)
	var corbels := bp.pieces.filter(func(q): return q.id == "corbel")
	check(corbels.size() >= 14, "the brackets are there (%d)" % corbels.size())
	var wins := bp.pieces.filter(func(q): return BlueprintLibrary.GLASS_HALF.has(q.id))
	for c in corbels:
		for w in wins:
			check(not BlueprintLibrary.bracket_on_glass(c, w), "the bracket at %s is not on the window at %s" % [c.pos, w.pos])


## The owner's change (Nov 26): every building is Stonehold stone below and Shack wood above. Foundations,
## battlements, brackets and trim bands are stone; every sloped roof is wood; nothing stone stands over wood in the
## same spot; and the tower's lookout roof is the one highest point.
func test_stone_below_wood_above() -> void:
	var bp := BlueprintLibrary.make(ID)
	var wood := 0
	var stone := 0
	var top := -99.0
	var top_id := ""
	for p in bp.pieces:
		var id: String = p.id
		if id.begins_with("roof_") or id.begins_with("gable"):
			check(p.mat == BlueprintLibrary.WOOD, "%s at %s is wood" % [id, p.pos])
		if id.begins_with("foundation") or id.begins_with("battlement") or id in ["cornice", "corbel"]:
			check(p.mat == BlueprintLibrary.STONE, "%s at %s is stone" % [id, p.pos])
		check(p.mat in [BlueprintLibrary.WOOD, BlueprintLibrary.STONE, BlueprintLibrary.COPPER], "%s at %s is stone or wood (%s)" % [id, p.pos, p.mat])
		if p.mat == BlueprintLibrary.WOOD:
			wood += 1
		elif p.mat == BlueprintLibrary.STONE:
			stone += 1
		var b := Pieces.box(p.id, p.pos, p.rot)
		if b.end.y > top:
			top = b.end.y
			top_id = "%s@%s" % [id, p.pos]
	for p in bp.pieces:
		if p.mat != BlueprintLibrary.STONE or p.id in ["foundation", "foundation_steps", "railing", "corbel", "cornice"]:
			continue
		for q in bp.pieces:
			if q.mat == BlueprintLibrary.WOOD and q.id in ["wall", "window_wall", "window_wide", "doorway"] \
					and Vector2(q.pos.x - p.pos.x, q.pos.z - p.pos.z).length() < 0.1 and q.pos.y < p.pos.y - 0.1:
				check(false, "stone %s at %s stands over wood %s at %s" % [p.id, p.pos, q.id, q.pos])
	check(wood > 150 and stone > 150, "lots of both (wood %d, stone %d)" % [wood, stone])
	check(top_id.begins_with("roof_45_outer"), "the lookout's roof is the highest point (%s, %.2f)" % [top_id, top])
