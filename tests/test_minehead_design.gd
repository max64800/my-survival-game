extends TestCase
## Ruin 12, the Mine-head Works (owner, Nov 25, F899; plan: docs/design/ruin12/MINEHEAD-PLAN.md). It stands on the
## cave's own ground (the cave floor 8 m up its box, the dip, the lower ledge, the shaft down to the mine room), so the
## checks every learnable blueprint gets are run on it here: real pieces inside the box, nothing overlaps, nothing
## stands in the rock, nothing falls, every stair's way in and out is open, every door has room on both sides,
## railings don't poke out past a floor, no stairs under a ceiling. Plus: the Head Wheel hangs on its two bearing
## beams, and every building is stone below, wood above.

const ID := "minehead_works"
var lib_t = load("res://tests/test_blueprint_library.gd").new()
var walk = load("res://tests/test_walk_through.gd").new()


func test_minehead_is_sound() -> void:
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
		if BlueprintLibrary.mine_rock(v.x, v.y + 0.3, v.z):
			msgs.append("inside the rock")
		if s.overlaps(p.id, p.pos, p.rot):
			msgs.append("overlaps another piece")
		for m in msgs:
			bad += 1
			check(false, "%s at %s rot %d: %s" % [p.id, v, p.rot, m])
		s.add(uid, p.id, p.mat, p.pos, p.rot, BlueprintLibrary.mine_rock(v.x, v.y - 0.05, v.z))
		uid += 1
	var names := []
	for u in s.recompute():
		names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
	check(names.is_empty(), "nothing falls down (%d: %s)" % [names.size(), ", ".join(names.slice(0, 12))])
	check(bad == 0, "%d pieces, every one real, inside the box, out of the rock, not overlapping" % bp.pieces.size())


func test_minehead_walk_through() -> void:
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
	check(doors >= 12, "checked every door (%d)" % doors)
	for msg in lib_t.railing_ends_poking_out(bp.pieces):
		check(false, msg)
	for msg in lib_t.stairs_under_a_ceiling(bp.pieces):
		check(false, msg)


func _flight_at(bp: Blueprint, at: Vector3, rot: int) -> bool:
	return bp.pieces.any(func(q): return q.id == "stairs" and q.rot == rot and (q.pos as Vector3).distance_to(at) < 0.05)


## The Head Wheel (step 1) hangs on top of the headframe: both its bearings (2 m each side of it along its axle) sit
## on a beam's top, 1.75 m over the wheel's foot.
func test_head_wheel_sits_on_its_bearing_beams() -> void:
	var bp := BlueprintLibrary.make(ID)
	var wheels := bp.pieces.filter(func(q): return q.id == "head_wheel")
	check_eq(wheels.size(), 1, "one Head Wheel")
	if wheels.is_empty():
		return
	var w: Dictionary = wheels[0]
	var axle := Vector3(0, 0, 1).rotated(Vector3.UP, Pieces.yaw_of(w.rot))
	var top: float = w.pos.y + Pieces.LIST["head_wheel"].hang_on
	for side in [-1.0, 1.0]:
		var at: Vector3 = w.pos + axle * side * Pieces.LIST["head_wheel"].hang_apart * 0.5
		var under := bp.pieces.filter(func(q): return q.id == "beam" \
			and Pieces.box(q.id, q.pos, q.rot).grow(0.05).has_point(Vector3(at.x, top - 0.02, at.z)) \
			and absf(Pieces.box(q.id, q.pos, q.rot).end.y - top) < 0.03)
		check(not under.is_empty(), "a beam's top holds the wheel's bearing at %s (%.2f m up)" % [at, top])
	check(w.pos.y > BlueprintLibrary.MINE_SHIFT.y + 12.0, "the wheel is high on the headframe (%.1f m over the floor)" % (w.pos.y - BlueprintLibrary.MINE_SHIFT.y))


## The owner's plan: every building stone below, wood above. Foundations, the collar and the battlements are stone;
## every sloped roof is wood; nothing stone stands higher than a wooden piece's foot under it in the same spot.
func test_stone_below_wood_above() -> void:
	var bp := BlueprintLibrary.make(ID)
	var wood := 0
	var stone := 0
	for p in bp.pieces:
		var id: String = p.id
		if id.begins_with("roof_") or id.begins_with("gable") or id in ["head_wheel", "brace", "beam", "ladder"]:
			check(p.mat == BlueprintLibrary.WOOD, "%s at %s is wood" % [id, p.pos])
		if id.begins_with("foundation") or id.begins_with("battlement") or id == "cornice":
			check(p.mat == BlueprintLibrary.STONE, "%s at %s is stone" % [id, p.pos])
		if p.mat == BlueprintLibrary.WOOD:
			wood += 1
		else:
			stone += 1
	for p in bp.pieces:
		if p.mat != BlueprintLibrary.STONE or p.id in ["foundation", "foundation_triangle", "foundation_steps", "railing"]:
			continue
		for q in bp.pieces:
			if q.mat == BlueprintLibrary.WOOD and q.id in ["wall", "window_wall", "window_wide", "doorway", "floor"] \
					and Vector2(q.pos.x - p.pos.x, q.pos.z - p.pos.z).length() < 0.1 and q.pos.y < p.pos.y - 0.1:
				check(false, "stone %s at %s stands over wooden %s at %s" % [p.id, p.pos, q.id, q.pos])
	check(wood > 200 and stone > 150, "lots of both (wood %d, stone %d)" % [wood, stone])
