extends TestCase
## Ruin 15, the Pillar Spiral (owner, Nov 28, F942; plan: docs/design/ruin15/PILLAR-SPIRAL-PLAN.md). It stands on
## the cave's own ground round a rock column (the cave floor, the crack, the Kiln's lump, the high shelf), so the checks every
## learnable blueprint gets are run on it here: real pieces inside the box, nothing overlaps, nothing stands in the
## rock, nothing falls, every stair's way in and out is open, every door has room on both sides and a floor level with
## its sill (RUIN-RULES doors 9), no bracket on a window, railings don't poke out, no stairs under a ceiling. Plus: no
## ladders or ramps (F912), the ring meets the plinth and the Arch Bridge flush, nothing inside the column, the three
## materials where the plan puts them, the Eyrie's spire the highest point.

const ID := "pillar_spiral"
var lib_t = load("res://tests/test_blueprint_library.gd").new()
var walk = load("res://tests/test_walk_through.gd").new()


func test_pillar_spiral_is_sound() -> void:
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
		if BlueprintLibrary.pillar_rock(v.x, v.y + 0.3, v.z):
			msgs.append("inside the rock")
		if s.overlaps(p.id, p.pos, p.rot):
			msgs.append("overlaps another piece")
		for m in msgs:
			bad += 1
			check(false, "%s at %s rot %d: %s" % [p.id, v, p.rot, m])
		s.add(uid, p.id, p.mat, p.pos, p.rot, BlueprintLibrary.pillar_rock(v.x, v.y - 0.05, v.z))
		uid += 1
	var names := []
	for u in s.recompute():
		names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
	check(names.is_empty(), "nothing falls down (%d: %s)" % [names.size(), ", ".join(names.slice(0, 60))])
	check(bad == 0, "%d pieces, every one real, inside the box, out of the rock, not overlapping" % bp.pieces.size())


func test_pillar_spiral_walk_through() -> void:
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


## F912: you walk up everything, no ladders or ramps.
func test_no_ladders_or_ramps() -> void:
	for p in BlueprintLibrary.make(ID).pieces:
		check(not ("ladder" in p.id or "ramp" in p.id), "no %s (at %s)" % [p.id, p.pos])


## The plinth's top and the Arch Bridge's deck meet the ring's flat sides exactly (no gap, no step): the plinth's
## back edge on the front flat side at the hall floor (1.0), the bridge's end on the right flat side at the terrace.
func test_ring_meets_plinth_and_bridge_flush() -> void:
	var bp := BlueprintLibrary.make(ID)
	var sh := BlueprintLibrary.PS_SHIFT
	var rf := BlueprintLibrary.PS_RF
	var plinth := bp.pieces.filter(func(q): return q.id == "foundation" and q.mat == BlueprintLibrary.STONE 		and q.pos.z - sh.z > rf + 0.5 and q.pos.z - sh.z < rf + 1.5 and absf(q.pos.y - sh.y) < 0.01)
	check(plinth.size() == 6, "six plinth blocks along the front flat side (%d)" % plinth.size())
	for q in plinth:
		var b := Pieces.box(q.id, q.pos, q.rot)
		check(absf(b.position.z - (sh.z + rf)) < 0.02, "the plinth block at %s starts at the ring (%.3f)" % [q.pos, b.position.z - sh.z])
		check(absf(b.end.y - (sh.y + 1.0)) < 0.02, "the plinth block at %s is level with the hall floor" % q.pos)
	var deck := bp.pieces.filter(func(q): return q.id == "floor" and q.mat == BlueprintLibrary.STONE 		and absf(q.pos.z - sh.z) < 0.1 and q.pos.x - sh.x > rf and q.pos.x - sh.x < rf + 2.0 and q.pos.y - sh.y > 5.0)
	check(deck.size() == 1, "the bridge's first deck slab is there (%d)" % deck.size())
	for q in deck:
		var b := Pieces.box(q.id, q.pos, q.rot)
		check(absf(b.position.x - (sh.x + rf)) < 0.02, "the bridge starts at the ring (%.3f)" % (b.position.x - sh.x))
		check(absf(b.end.y - (sh.y + 5.5)) < 0.02, "the bridge is level with the terrace")


## Nothing stands inside the rock column (its 6-sided foot up to the terrace, the round part above it): points over
## each piece's own turned footprint (a 3 x 3 grid, 6 cm in from its sides) at its bottom, middle and top.
func test_nothing_inside_the_column() -> void:
	var sh := BlueprintLibrary.PS_SHIFT
	for p in BlueprintLibrary.make(ID).pieces:
		var size: Vector3 = Pieces.LIST[p.id].size
		var yaw := Pieces.yaw_of(p.rot)
		var tri: bool = Pieces.LIST[p.id].get("tri", false)
		var inside := false
		for fx in [-1.0, 0.0, 1.0]:
			for fz in [-1.0, 0.0, 1.0]:
				var k := 0.3 if tri else 1.0   # (triangles: only near their middle)
				var off := Vector3(fx * (size.x * 0.5 - 0.06) * k, 0, fz * (size.z * 0.5 - 0.06) * k).rotated(Vector3.UP, yaw)
				for fy in [0.06, size.y * 0.5, size.y - 0.06]:
					var at: Vector3 = p.pos + off + Vector3(0, fy, 0) - sh
					if at.y < 25.0 and BlueprintLibrary.ps_column(at.x, at.y, at.z):
						inside = true
		check(not inside, "%s at %s is not inside the column" % [p.id, p.pos])


## The plan's materials (Nov 28): the Ring Hall, its plinth, the Arch Bridge and the Rock Shrine cut stone; the houses
## and the Kiln House clay brick below, the top storeys, the winding stair, the Shrine Bridge and the Eyrie plank-root
## wood (the Eyrie's spire clay brick: spire tiles only come in brick); brackets clay brick; only the hall's lanterns
## copper. And the Eyrie's spire is the highest point.
func test_materials_and_the_eyrie_on_top() -> void:
	var bp := BlueprintLibrary.make(ID)
	var n := {}
	var top := -99.0
	var top_id := ""
	for p in bp.pieces:
		n[p.mat] = n.get(p.mat, 0) + 1
		check(p.mat in [BlueprintLibrary.STONE, BlueprintLibrary.BRICK, BlueprintLibrary.WOOD, BlueprintLibrary.COPPER],
			"%s at %s is stone, brick or wood (%s)" % [p.id, p.pos, p.mat])
		if p.id == "corbel":
			check(p.mat == BlueprintLibrary.BRICK, "the bracket at %s is brick" % p.pos)
		if p.mat == BlueprintLibrary.COPPER:
			check(p.id == "wall_sconce", "only lanterns are copper (%s)" % p.id)
		var b := Pieces.box(p.id, p.pos, p.rot)
		if b.end.y > top:
			top = b.end.y
			top_id = "%s@%s" % [p.id, p.pos]
	for m in [BlueprintLibrary.STONE, BlueprintLibrary.BRICK, BlueprintLibrary.WOOD]:
		check(n.get(m, 0) > 100, "lots of %s (%d)" % [m, n.get(m, 0)])
	check(top_id.begins_with("roof_spire"), "the Eyrie's spire is the highest point (%s, %.2f)" % [top_id, top])
