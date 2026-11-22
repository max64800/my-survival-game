extends TestCase
## The 4 ready-made blueprints (building polish spec §7).


func test_four_blueprints_exist() -> void:
	check_eq(BlueprintLibrary.IDS.size(), 19, "nineteen blueprints (the starter hut, six found in ruins, the Wooden Watchtower, the Wooden Outpost, the two Brewhalls, the two Spires, the two Manors, the two Twin Gates and the two Cliff Watches learned by rebuilding ruins)")
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
## cap, and every spiral stair goes in and comes out (its turned +x side) onto a floor, with no wall or railing there.
func test_hearth_manor_stairs_lead_onto_floor() -> void:
	var bp := BlueprintLibrary.make("hearthbrick_manor")
	var spirals := 0
	for p in bp.pieces:
		check(not p.id in ["floor_half", "small_floor", "roof_cap"], "no %s in the manor (at %s)" % [p.id, p.pos])
		if p.id != "stairs_spiral":
			continue
		spirals += 1
		var out := Vector3(1, 0, 0).rotated(Vector3.UP, Pieces.yaw_of(p.rot))
		var cell: Vector3 = p.pos + out * 2.0
		var edge: Vector3 = p.pos + out
		for top in [p.pos.y - 0.25, p.pos.y + 2.0]:   # (it stands on a slab: one small step up at its foot)
			check(_floor_top_at(bp, cell.x, cell.z, top), "spiral at %s: floor at %s, top %.2f" % [p.pos, cell, top])
			check(not _blocked_edge(bp, edge.x, edge.z, top), "spiral at %s: nothing blocks its side at %.2f" % [p.pos, top])
	check_eq(spirals, 3, "the tower has three spiral flights")


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
		check(_floor_top_at(bp, top.x, top.z, p.pos.y + 2.0), "stairs at %s: their top lands on floor" % p.pos)
		check(not _blocked_edge(bp, (p.pos + up).x, (p.pos + up).z, p.pos.y + 1.75), "stairs at %s: nothing blocks their top" % p.pos)
	check_eq(flights, 4, "four flights: up to every storey and the roof deck")
	# the widest wall of each storey: 1 (10 m), 2 out (14 m), 3 in (6 m), 4 out (10 m)
	var widest := {}
	for p in bp.pieces:
		if p.id in ["wall", "window_wall", "doorway"] and p.rot == 1:
			widest[p.pos.y] = maxf(widest.get(p.pos.y, 0.0), absf(p.pos.x - 1.0))
	check(widest[3.25] > widest[1.0] and widest[5.5] < widest[3.25] and widest[7.75] > widest[5.5],
		"the outline steps out, in, out again (%s)" % widest)


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
