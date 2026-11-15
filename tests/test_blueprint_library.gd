extends TestCase
## The 4 ready-made blueprints (building polish spec §7).


func test_four_blueprints_exist() -> void:
	check_eq(BlueprintLibrary.IDS.size(), 4, "four blueprints")
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
			check(absf(v.x) <= half.x and v.y >= 0.0 and v.y <= half.y and absf(v.z) <= half.z, "%s: %s at %s is inside the box" % [id, p.id, v])


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
