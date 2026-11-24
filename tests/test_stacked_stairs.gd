extends TestCase
## F838 (owner, Nov 24): where a storey is taller than one stair (2 m), the blueprints (and so the ruins and towers
## built from them) put the second flight straight on where the first ends, same way: no landing floor or pillars
## between them, nothing under them but walls. Both sides of the pair are closed: a sloped wall beside the lower
## flight, a wall with a sloped wall on top beside the upper one (like the owner's rebuild of the Prow Hall).


## Every blueprint: two straight flights that climb one after another the same way must be straight on (no landing).
func test_no_landing_between_stacked_stairs() -> void:
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		var bad := []
		for a in bp.pieces:
			for c in bp.pieces:
				if a.id == "stairs" and c.id == "stairs" and a.rot == c.rot:
					var l := _local(a, c.pos)
					if absf(l.x) < 0.1 and l.z < -1.9 and l.z > -6.1 and l.y > 1.9 and l.y < 2.6 \
							and not (absf(l.z + 2.0) < 0.05 and absf(l.y - 2.0) < 0.05):
						bad.append("%s -> %s" % [a.pos, c.pos])
		check(bad.is_empty(), "%s: stacked stairs go straight on, no landing between %s" % [id, bad])


## Every straight-on pair: nothing between or under them but the side walls, and both sides closed.
func test_stacked_stairs_are_closed_at_both_sides() -> void:
	var pairs := 0
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		var bad := []
		for a in bp.pieces:
			if a.id != "stairs":
				continue
			var b := Basis(Vector3.UP, Pieces.yaw_of(a.rot))
			var top_pos: Vector3 = a.pos + b * Vector3(0, 2, -2)
			var upper := bp.pieces.filter(func(p): return p.id == "stairs" and p.rot == a.rot and (p.pos as Vector3).distance_to(top_pos) < 0.05)
			if upper.is_empty():
				continue
			pairs += 1
			var low_y: float = a.pos.y
			# The upper flight ends 25 cm under a floor (Builder._relip_stairs then gives it the lip slope, F803) or level.
			var past: Vector3 = a.pos + b * Vector3(0, 4.0 + PieceNode.LIP * 0.5, -3.15)
			var lip_ok: bool = bp.pieces.any(func(p): return p.id in ["floor", "foundation", "floor_half", "floor_triangle", "floor_hatch"] \
					and absf(p.pos.y + Pieces.LIST[p.id].size.y - (low_y + 4.0 + PieceNode.LIP)) < 0.03 and Pieces.box(p.id, p.pos, p.rot).has_point(past))
			var level: bool = bp.pieces.any(func(p): return Pieces.LIST[p.id].get("group", "") in ["floor", "foundation"] \
					and absf(p.pos.y + Pieces.LIST[p.id].size.y - (low_y + 4.0)) < 0.03 and Pieces.box(p.id, p.pos, p.rot).grow(0.01).has_point(past - Vector3(0, PieceNode.LIP, 0)))
			if not (lip_ok or level):
				bad.append("the flight at %s ends without a floor 25 cm up (lip) or level" % [upper[0].pos])
			for sx in [-1.0, 1.0]:   # (a sloped wall, a wall, or the curtain wall the stairs stand against)
				var e1: Vector3 = a.pos + b * Vector3(sx, 0, 0)
				var e2: Vector3 = a.pos + b * Vector3(sx, 0, -2)
				if not _closed(bp, e1, low_y):
					bad.append("open beside the lower flight at %s" % e1)
				if not _closed(bp, e2, low_y + 2.0):
					bad.append("open beside the upper flight at %s" % e2)
				if not _closed(bp, e2, low_y):
					bad.append("open under the upper flight at %s" % e2)
			# Nothing else in the two cells under the flights (no landing, no ceiling, no pillars).
			for p in bp.pieces:
				if p.id in ["stairs", "sloped_wall", "wall", "railing_stairs"] or Pieces.LIST[p.id].get("on_wall", false):
					continue
				var l := _local(a, p.pos)
				if absf(l.x) < 0.9 and l.z < 0.9 and l.z > -2.9 and l.y > 0.05 and l.y < 3.9:
					bad.append("%s at %s under the flights" % [p.id, p.pos])
		check(bad.is_empty(), "%s: stacked stairs closed at both sides, nothing under them %s" % [id, bad])
	check(pairs > 0, "some blueprint has stacked stairs (%d pairs)" % pairs)


static func _local(a: Dictionary, p: Vector3) -> Vector3:
	return Basis(Vector3.UP, Pieces.yaw_of(a.rot)).inverse() * (p - (a.pos as Vector3))


## A wall-like piece stands on the edge at `at`, its foot within 30 cm of `y` (it closes that 2 m band).
static func _closed(bp: Blueprint, at: Vector3, y: float) -> bool:
	return bp.pieces.any(func(p): return Pieces.LIST[p.id].get("group", "") == "wall" and Pieces.LIST[p.id].get("place", "") == "edge" \
			and Vector2(p.pos.x - at.x, p.pos.z - at.z).length() < 0.05 and absf(p.pos.y - y) < 0.3)
