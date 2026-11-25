extends TestCase
## Ruin 10, the Smeltery Terraces (owner, Nov 24, F845): a design-stage blueprint (not in IDS yet, its 3D page first),
## so the checks every learnable blueprint gets are run on it here: real pieces inside the box, nothing overlaps,
## nothing stands in the cave rock behind it, nothing falls, every stair's way in and out is open, every door has room
## on both sides, railings don't poke out past a floor, no stairs under a ceiling. Brick and wood.

const IDS := ["hearthbrick_smeltery", "wooden_smeltery"]
var lib_t = load("res://tests/test_blueprint_library.gd").new()
var walk = load("res://tests/test_walk_through.gd").new()


func test_smeltery_is_sound() -> void:
	for id in IDS:
		var bp := BlueprintLibrary.make(id)
		var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
		var s := Structure.new()
		var uid := 1
		var bad := 0
		for p in bp.pieces:
			var v: Vector3 = p.pos
			var rock := BlueprintLibrary.smelt_rock_top(v.x, v.z)
			var msgs := []
			if not Pieces.allowed(p.id, p.mat):
				msgs.append("%s can't be made of %s" % [p.id, p.mat])
			if p.id in ["floor_half", "small_floor", "roof_cap"]:
				msgs.append("no %s (F626)" % p.id)
			if not (absf(v.x) <= half.x and v.y >= 0.0 and v.y <= half.y and absf(v.z) <= half.z):
				msgs.append("outside the box")
			if v.y < rock - 0.3:
				msgs.append("inside the rock")
			if s.overlaps(p.id, p.pos, p.rot):
				msgs.append("overlaps another piece")
			for m in msgs:
				bad += 1
				check(false, "%s: %s at %s rot %d: %s" % [id, p.id, v, p.rot, m])
			s.add(uid, p.id, p.mat, p.pos, p.rot, v.y < 0.3 or (rock > 0.0 and v.y < rock + 0.05))
			uid += 1
		var names := []
		for u in s.recompute():
			names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
		check(names.is_empty(), "%s: nothing falls down (%d: %s)" % [id, names.size(), ", ".join(names.slice(0, 12))])
		check(bad == 0, "%s: %d pieces, every one real, inside the box, out of the rock, not overlapping" % [id, bp.pieces.size()])


func test_smeltery_walk_through() -> void:
	for id in IDS:
		var bp := BlueprintLibrary.make(id)
		var doors := 0
		for p in bp.pieces:
			if p.id == "stairs":
				var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
				for w in [[p.pos + up, p.pos.y + 2.0, "top"], [p.pos - up, p.pos.y, "foot"]]:
					var by: String = walk._edge_blocker(bp, w[0], w[1])
					check(by == "", "%s: stairs at %s rot %d: the %s is open (blocked by %s)" % [id, p.pos, p.rot, w[2], by])
				var foot: Vector3 = p.pos - up * 2.0
				var top: Vector3 = p.pos + up * 2.0
				var after := _flight_at(bp, p.pos + up * 2.0 + Vector3(0, 2, 0), p.rot)   # (two flights straight on, F838)
				var before := _flight_at(bp, p.pos - up * 2.0 - Vector3(0, 2, 0), p.rot)
				check(before or lib_t._any_floor_at(bp, foot, p.pos.y - 0.25) or lib_t._any_floor_at(bp, foot, p.pos.y),
					"%s: stairs at %s: their foot is on open floor" % [id, p.pos])
				check(after or lib_t._any_floor_at(bp, top, p.pos.y + 2.0) or lib_t._any_floor_at(bp, top, p.pos.y + 2.25),
					"%s: stairs at %s: their top lands on floor" % [id, p.pos])
			if p.id in ["door", "doorway"]:
				doors += 1
				var by: String = walk._door_blocker(bp, p)
				check(by == "", "%s: the %s at %s rot %d has room on both sides (blocked by %s)" % [id, p.id, p.pos, p.rot, by])
		check(doors > 10, "%s: checked every door (%d)" % [id, doors])
		for msg in lib_t.railing_ends_poking_out(bp.pieces):
			check(false, "%s: %s" % [id, msg])
		for msg in lib_t.stairs_under_a_ceiling(bp.pieces):
			check(false, "%s: %s" % [id, msg])


func _flight_at(bp: Blueprint, at: Vector3, rot: int) -> bool:
	return bp.pieces.any(func(q): return q.id == "stairs" and q.rot == rot and (q.pos as Vector3).distance_to(at) < 0.05)


## A bracket (corbel) never covers a window's glass (owner, Nov 25, F845: "these things cannot touch walls with
## glass, it doesn't make sense"). Brick and wood.
func test_brackets_keep_off_windows() -> void:
	for id in IDS:
		var bp := BlueprintLibrary.make(id)
		var wins := bp.pieces.filter(func(q): return q.id in ["window_wall", "window_wide", "window_diagonal"])
		var bad := []
		for p in bp.pieces:
			if p.id != "corbel":
				continue
			for w in wins:
				if BlueprintLibrary.bracket_on_glass(p, w):
					bad.append("%s on %s@%s" % [p.pos, w.id, w.pos])
					break
		check(bad.is_empty(), "%s: no bracket on a window's glass (%d: %s)" % [id, bad.size(), ", ".join(bad.slice(0, 10))])
