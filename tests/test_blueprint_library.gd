extends TestCase
## The 4 ready-made blueprints (building polish spec §7).


func test_four_blueprints_exist() -> void:
	check_eq(BlueprintLibrary.IDS.size(), 21, "twenty-one blueprints (the starter hut, six found in ruins, the Wooden Watchtower, the Wooden Outpost, the two Brewhalls, the two Spires, the two Manors, the two Twin Gates, the two Cliff Watches and the two Prow Halls learned by rebuilding ruins)")
	for id in BlueprintLibrary.IDS:
		check(BlueprintLibrary.make(id) != null, "%s can be made" % id)


func test_every_piece_is_real_and_inside_the_box() -> void:
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		check(bp.pieces.size() >= 15, "%s has a real building in it (%d pieces)" % [id, bp.pieces.size()])
		var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
		for p in bp.pieces:
			check(Pieces.allowed(p.id, p.mat), "%s: %s can be made of %s" % [id, p.id, p.mat])
			var v: Vector3 = p.pos
			var low := -1.5 if id.ends_with("brewhall") else 0.0  # (the Brewhall's cellar, F479: dug by its ruin)
			check(absf(v.x) <= half.x and v.y >= low and v.y <= half.y and absf(v.z) <= half.z, "%s: %s at %s is inside the box" % [id, p.id, v])


func test_no_two_pieces_overlap() -> void:
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		var s := Structure.new()
		var uid := 1
		for p in bp.pieces:
			check(not s.overlaps(p.id, p.pos, p.rot), "%s: %s at %s doesn't overlap another piece" % [id, p.id, p.pos])
			s.add(uid, p.id, p.mat, p.pos, p.rot, p.pos.y < 0.3)
			uid += 1


func test_everything_stands_up() -> void:
	# Built on flat ground (anything at floor level touches it): nothing should fall.
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		var s := Structure.new()
		var uid := 1
		for p in bp.pieces:
			s.add(uid, p.id, p.mat, p.pos, p.rot, p.pos.y < 0.3)
			uid += 1
		var falling := s.recompute()
		var names := []
		for u in falling:
			names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
		check(falling.is_empty(), "%s: nothing falls down (%s)" % [id, ", ".join(names)])


## F656 (owner, Nov 22): the big 12-sided ring (2 rings wide) is sound: real pieces, nothing overlaps or falls, and
## every full layer is 24 squares + 48 triangles (squares = 6 R^2, triangles = 12 R^2).
func test_big_round_tower_is_sound() -> void:
	var bp := BlueprintLibrary.make("stonehold_round_test")
	var s := Structure.new()
	var uid := 1
	var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
	for p in bp.pieces:
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		check(absf(p.pos.x) <= half.x and absf(p.pos.z) <= half.z and p.pos.y <= half.y, "%s at %s is inside the box" % [p.id, p.pos])
		check(not s.overlaps(p.id, p.pos, p.rot), "%s at %s doesn't overlap another piece" % [p.id, p.pos])
		s.add(uid, p.id, p.mat, p.pos, p.rot, p.pos.y < 0.3)
		uid += 1
	check(s.recompute().is_empty(), "nothing falls down")
	var sq := bp.pieces.filter(func(p): return p.id == "foundation").size()
	var tri := bp.pieces.filter(func(p): return p.id == "foundation_triangle").size()
	check_eq([sq, tri], [24, 48], "the 2-ring base: 24 squares + 48 triangles")
	check_eq(bp.pieces.filter(func(p): return p.id == "battlement").size(), 24 + 12, "battlements on both rings' 12 sides")


## Ruin 7, the Hearth Manor (owner, Nov 22, F479): in IDS now (learned by rebuilding it), so the checks above cover
## it too; kept as its own quick check while working on it.
func test_hearth_manor_is_sound() -> void:
	for id in ["hearthbrick_manor", "wooden_manor"]:
		var bp := BlueprintLibrary.make(id)
		var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
		var s := Structure.new()
		var uid := 1
		for p in bp.pieces:
			check(Pieces.allowed(p.id, p.mat), "%s: %s can be made of %s" % [id, p.id, p.mat])
			var v: Vector3 = p.pos
			check(absf(v.x) <= half.x and v.y >= 0.0 and v.y <= half.y and absf(v.z) <= half.z, "%s: %s at %s is inside the box" % [id, p.id, v])
			check(not s.overlaps(p.id, p.pos, p.rot), "%s: %s at %s doesn't overlap another piece" % [id, p.id, p.pos])
			s.add(uid, p.id, p.mat, p.pos, p.rot, p.pos.y < 0.3)
			uid += 1
		var names := []
		for u in s.recompute():
			names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
		check(names.is_empty(), "%s: nothing falls down (%s)" % [id, ", ".join(names)])


## F626: the dwarf can walk everywhere in the manor: no half or small floors (balconies are whole cells), no roof
## cap, and the tower's three straight flights (F169/F626, Nov 22: no more spirals) start and land on open floor.
func test_hearth_manor_stairs_lead_onto_floor() -> void:
	var bp := BlueprintLibrary.make("hearthbrick_manor")
	var flights := 0
	for p in bp.pieces:
		check(not p.id in ["floor_half", "small_floor", "roof_cap", "stairs_spiral"], "no %s in the manor (at %s)" % [p.id, p.pos])
		if p.id != "stairs":
			continue
		flights += 1
		var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
		var foot: Vector3 = p.pos - up * 2.0
		var top: Vector3 = p.pos + up * 2.0
		# (F169: with no slab under a flight, its top step is one ordinary 25 cm step below the floor above)
		check(_floor_top_at(bp, foot.x, foot.z, p.pos.y - 0.25) or _floor_top_at(bp, foot.x, foot.z, p.pos.y),
			"stairs at %s: their foot is on open floor" % p.pos)
		check(_floor_top_at(bp, top.x, top.z, p.pos.y + 2.0) or _floor_top_at(bp, top.x, top.z, p.pos.y + 2.25), "stairs at %s: their top lands on floor" % p.pos)
		check(not _blocked_edge(bp, (p.pos + up).x, (p.pos + up).z, p.pos.y + 1.75), "stairs at %s: nothing blocks their top" % p.pos)
	check(flights >= 3, "the tower has three straight flights (%d stairs)" % flights)
	# the lookout room has a flat deck now (owner, Nov 22: no odd pyramid roof)
	for p in bp.pieces:
		check(not (p.id.begins_with("roof_45") and p.pos.y > 9.0), "no pyramid roof on the lookout (%s at %s)" % [p.id, p.pos])


## Ruin 8, Cliff Watch (owner, Nov 22, F479): layered ("up, out, up, out"). Sound like the manor, every stair lands on
## floor at both ends (F626), and the outline steps OUT above a step IN twice.
func test_cliff_watch_is_layered_and_sound() -> void:
	for id in ["stonehold_cliff_watch", "wooden_cliff_watch"]:
		var bp := BlueprintLibrary.make(id)
		var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
		var s := Structure.new()
		var uid := 1
		for p in bp.pieces:
			check(Pieces.allowed(p.id, p.mat), "%s: %s can be made of %s" % [id, p.id, p.mat])
			check(not p.id in ["floor_half", "small_floor", "roof_cap"], "%s: no %s (F626)" % [id, p.id])
			var v: Vector3 = p.pos
			check(absf(v.x) <= half.x and v.y >= 0.0 and v.y <= half.y and absf(v.z) <= half.z, "%s: %s at %s is inside the box" % [id, p.id, v])
			check(not s.overlaps(p.id, p.pos, p.rot), "%s: %s at %s doesn't overlap another piece" % [id, p.id, p.pos])
			s.add(uid, p.id, p.mat, p.pos, p.rot, p.pos.y < 0.3)
			uid += 1
		var names := []
		for u in s.recompute():
			names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
		check(names.is_empty(), "%s: nothing falls down (%s)" % [id, ", ".join(names)])
	var bp := BlueprintLibrary.make("stonehold_cliff_watch")
	var flights := 0
	for p in bp.pieces:
		if p.id != "stairs":
			continue
		flights += 1
		var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
		var foot: Vector3 = p.pos - up * 2.0
		var top: Vector3 = p.pos + up * 2.0
		check(_floor_top_at(bp, foot.x, foot.z, p.pos.y - 0.25) or _floor_top_at(bp, foot.x, foot.z, p.pos.y),
			"stairs at %s: their foot is on open floor" % p.pos)
		check(_floor_top_at(bp, top.x, top.z, p.pos.y + 2.0) or _floor_top_at(bp, top.x, top.z, p.pos.y + 2.25), "stairs at %s: their top lands on floor" % p.pos)
		check(not _blocked_edge(bp, (p.pos + up).x, (p.pos + up).z, p.pos.y + 1.75), "stairs at %s: nothing blocks their top" % p.pos)
	check_eq(flights, 4, "four flights: up to every storey and the roof deck")
	# the widest wall of each storey: 1 (10 m), 2 out (14 m), 3 in (6 m), 4 out (10 m)
	var widest := {}
	for p in bp.pieces:
		if p.id in ["wall", "window_wall", "doorway"] and p.rot == 1:
			widest[p.pos.y] = maxf(widest.get(p.pos.y, 0.0), absf(p.pos.x - 1.0))
	check(widest[3.25] > widest[1.0] and widest[5.5] < widest[3.25] and widest[7.75] > widest[5.5],
		"the outline steps out, in, out again (%s)" % widest)


## Ruin 9, the Prow Hall (owner, Nov 22, F656 + F657): real stone pieces, inside its box, nothing overlaps, nothing
## stands inside the cave rock behind the keep, and nothing falls when the
## pieces resting on the cave floor or the rock hold (in the game the rock anchors them: Pieces.touches_rock).
## Both the stone hall and its wooden rebuild (owner, Nov 22).
func test_prow_hall_is_sound() -> void:
	for id in ["stonehold_prow_hall", "wooden_prow_hall"]:
		_check_prow_hall(id)


func _check_prow_hall(id: String) -> void:
	var bp := BlueprintLibrary.make(id)
	var half := Vector3(bp.size.x * 0.5 + 0.5, bp.size.y + 0.5, bp.size.z * 0.5 + 0.5)
	var s := Structure.new()
	var uid := 1
	for p in bp.pieces:
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		check(not p.id in ["floor_half", "small_floor", "roof_cap"], "no %s (F626)" % p.id)
		var v: Vector3 = p.pos
		check(absf(v.x) <= half.x and v.y >= 0.0 and v.y <= half.y and absf(v.z) <= half.z, "%s at %s is inside the box" % [p.id, v])
		var rock := BlueprintLibrary.prow_rock_top(v.x, v.z)
		check(v.y >= rock - 0.3, "%s at %s isn't inside the rock (top %.2f)" % [p.id, v, rock])
		check(not s.overlaps(p.id, p.pos, p.rot), "%s at %s doesn't overlap another piece" % [p.id, p.pos])
		s.add(uid, p.id, p.mat, p.pos, p.rot, v.y < 0.3 or (rock > 0.0 and v.y < rock + 0.05))
		uid += 1
	var names := []
	for u in s.recompute():
		names.append("%s@%s" % [s.pieces[u].piece, s.pieces[u].pos])
	check(names.is_empty(), "%s: nothing falls down (%s)" % [id, ", ".join(names)])
	var rock_cells := 0
	for a in bp.air:
		rock_cells += 1 if a == 0 else 0
	check(rock_cells > 500, "the cave rock behind the keep stays rock (%d cells)" % rock_cells)


## F626 for the Prow Hall: every stair's foot is on open floor (a square or a triangle) and its top lands on floor,
## with no wall or railing across its top.
func test_prow_hall_stairs_lead_onto_floor() -> void:
	var bp := BlueprintLibrary.make("stonehold_prow_hall")
	var flights := 0
	for p in bp.pieces:
		if p.id != "stairs":
			continue
		flights += 1
		var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
		var foot: Vector3 = p.pos - up * 2.0
		var top: Vector3 = p.pos + up * 2.0
		check(_any_floor_at(bp, foot, p.pos.y - 0.25) or _any_floor_at(bp, foot, p.pos.y), "stairs at %s: their foot is on open floor" % p.pos)
		check(_any_floor_at(bp, top, p.pos.y + 2.0) or _any_floor_at(bp, top, p.pos.y + 2.25), "stairs at %s: their top lands on floor" % p.pos)
		var edge: Vector3 = p.pos + up
		check(not _blocked_edge(bp, edge.x, edge.z, p.pos.y + 1.75), "stairs at %s: nothing blocks their top" % p.pos)
	check_eq(flights, 40, "stairs up every storey (F710: two flights and a landing per tall storey): hall 2x2, prow 2, towers 5+5+6+6, lone tower 5 (on the cave floor, F657), keep 4 + 3")


## The owner's Nov 23 play test of the Prow Hall (F820, F821, F822), in the stone and the wooden blueprint.
func test_prow_hall_play_test_fixes() -> void:
	for id in ["stonehold_prow_hall", "wooden_prow_hall"]:
		var bp := BlueprintLibrary.make(id)
		var ps: Array = bp.pieces
		for msg in railing_ends_poking_out(ps):
			check(false, "%s: %s" % [id, msg])
		for msg in stairs_under_a_ceiling(ps):
			check(false, "%s: %s" % [id, msg])
		for msg in merlons_indoors(ps, BlueprintLibrary.WOOD):
			check(false, "%s: %s" % [id, msg])
		check(true, "%s: railings, stair holes and merlons checked" % id)


const FLOORS := ["floor", "foundation", "floor_triangle", "foundation_triangle"]


static func _floor_under(ps: Array, at: Vector3, grow: float) -> Dictionary:
	for q in ps:
		if q.id in FLOORS and absf(q.pos.y + Pieces.LIST[q.id].size.y - at.y) < 0.06:
			if Geometry2D.is_point_in_polygon(Vector2(at.x, at.z), Pieces.footprint(q.id, q.pos, q.rot, grow)):
				return q
	return {}


## F820 (owner, Nov 23: "the railing ends poke out past the tower's wood deck"): both ends of every railing stand on
## the floor it rails (to 15 cm): none sticks out into the air past a deck's edge.
static func railing_ends_poking_out(ps: Array) -> Array:
	var out := []
	for p in ps:
		if not p.id in ["railing", "railing_narrow"]:
			continue
		var half: float = Pieces.LIST[p.id].size.x * 0.5
		for sgn in [-1.0, 1.0]:
			var end: Vector3 = p.pos + Vector3(half * sgn * 0.95, 0, 0).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
			if _floor_under(ps, end, 0.15).is_empty() and out.size() < 6:
				out.append("the %s at %s pokes out past its floor at %s" % [p.id, p.pos, end])
	return out


## F821 (owner, Nov 23: "the stair ends under the next floor, there's no hole"): no floor or ceiling over any stair
## closer than 1.8 m above its steps.
static func stairs_under_a_ceiling(ps: Array) -> Array:
	var out := []
	for p in ps:
		if p.id != "stairs":
			continue
		var up := Vector3(0, 0, -1).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
		for s in [-0.8, 0.0, 0.8]:
			var at: Vector3 = p.pos + up * s
			var step: float = p.pos.y + 1.0 + s
			for q in ps:
				if q.id in FLOORS and q.pos.y > step - 0.05 and q.pos.y < step + 1.8:
					if Geometry2D.is_point_in_polygon(Vector2(at.x, at.z), Pieces.footprint(q.id, q.pos, q.rot, -0.05)):
						if out.size() < 6:
							out.append("the stairs at %s run up under the %s at %s (no stair hole)" % [p.pos, q.id, q.pos])
						break
	return out


## F822 (owner, Nov 23: "grey battlement blocks on a tower's wood deck and inside a wood-walled room"): no battlement
## stands under a floor (inside a building), and in a wooden castle none stands on a wood deck.
static func merlons_indoors(ps: Array, wood: String) -> Array:
	var out := []
	for p in ps:
		if not String(p.id).begins_with("battlement"):
			continue
		var pts: Array[Vector3] = [p.pos]
		if p.id != "battlement_corner":
			var n := Vector3(0, 0, 0.35).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
			pts = [p.pos + n, p.pos - n]
		for q in ps:
			if q.id in FLOORS and q.pos.y > p.pos.y + 0.5 and q.pos.y < p.pos.y + 4.6:
				var fp := Pieces.footprint(q.id, q.pos, q.rot, -0.05)
				if pts.all(func(v): return Geometry2D.is_point_in_polygon(Vector2(v.x, v.z), fp)):
					if out.size() < 6:
						out.append("the %s at %s is indoors, under the %s at %s" % [p.id, p.pos, q.id, q.pos])
					break
		if p.mat != wood:
			for v in pts:
				var deck := _floor_under(ps, v, -0.05)
				if not deck.is_empty() and deck.mat == wood and out.size() < 6:
					out.append("the stone %s at %s stands on a wood deck" % [p.id, p.pos])
					break
	return out


## Any floor-like piece (square or triangle) whose top is at `top` and whose outline holds the point `at`.
func _any_floor_at(bp: Blueprint, at: Vector3, top: float) -> bool:
	for q in bp.pieces:
		if q.id in ["floor", "foundation", "floor_triangle", "foundation_triangle"]:
			if absf(q.pos.y + Pieces.LIST[q.id].size.y - top) < 0.06:
				if Geometry2D.is_point_in_polygon(Vector2(at.x, at.z), Pieces.footprint(q.id, q.pos, q.rot)):
					return true
	return false


func _floor_top_at(bp: Blueprint, x: float, z: float, top: float) -> bool:
	for q in bp.pieces:
		if q.id in ["floor", "foundation"] and absf(q.pos.x - x) < 0.1 and absf(q.pos.z - z) < 0.1:
			if absf(q.pos.y + Pieces.LIST[q.id].size.y - top) < 0.06:
				return true
	return false


func _blocked_edge(bp: Blueprint, x: float, z: float, y: float) -> bool:
	for q in bp.pieces:
		if q.id in ["wall", "window_wall", "window_wide", "railing", "railing_narrow"]:
			if absf(q.pos.x - x) < 0.1 and absf(q.pos.z - z) < 0.1 and absf(q.pos.y - y) < 0.3:
				return true
	return false


func test_json_round_trip() -> void:
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		var r := Blueprint.from_json(bp.to_json())
		check(r.ok, "%s saves and loads (%s)" % [id, r.get("error", "")])
		if r.ok:
			check_eq((r.blueprint as Blueprint).pieces.size(), bp.pieces.size(), "%s keeps every piece" % id)


func test_homestead_carves_its_rooms() -> void:
	var bp := BlueprintLibrary.make("miners_homestead")
	check(bp.carve_cells(Vector3.ZERO, 0).size() >= 200, "the homestead carves out its rooms when placed in rock")


## F161: the Delver's Hut is in the blueprint book from the start; ruin pages only teach the others.
func test_starter_hut_known_from_the_start() -> void:
	check(not BlueprintMenu.ready_made_keys().has("delvers_hut"), "old blueprint pages never 'teach' the hut")
	var names := BlueprintMenu.entries().map(func(e): return e.name)
	check(names.has("delvers_hut"), "the hut is in the book right away")
	var bp := BlueprintLibrary.make("delvers_hut")
	var cells := {}
	var upstairs := 0
	for p in bp.pieces:
		if p.id == "foundation":
			cells[Vector2(p.pos.x, p.pos.z)] = true
		if p.id == "floor" and p.pos.y > 2.5:
			upstairs += 1
	check_eq(cells.size(), 12, "a house of 8 rooms plus a wing of 4")
	check(not cells.has(Vector2(1, 0)) and cells.has(Vector2(-1, 2)), "an L round a yard, not a box")
	check(upstairs >= 6, "two stories")
	check(bp.pieces.any(func(p): return p.id == "railing" and p.pos.y < 0.5), "the yard is closed off with railings")
