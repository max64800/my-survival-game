extends TestCase
## Building pieces, snapping and stability (world doc section 5).

var flat_ground := func(p: Vector3) -> float: return p.y  # rock below y = 0, air above


func test_costs() -> void:
	check_eq(Pieces.cost("wall", "plank_root"), {plank_root = 4}, "wall = 4 planks")
	check_eq(Pieces.cost("doorway", "cut_stone"), {cut_stone = 4, copper_ingot = 2}, "door hinges cost copper")
	check(not Pieces.allowed("mine_prop", "crystal_blue"), "no crystal mine props")
	check(Pieces.allowed("mine_prop", "plank_root"), "wooden props are fine")
	check_near(Pieces.hp("beam", "cut_stone"), 250.0, 0.01, "beam = half a wall's HP")


func test_snap_floor_to_grid() -> void:
	var s := Pieces.snap("floor", Vector3(3.3, 0.1, -0.7), Vector3.UP, 0.0, 0)
	check_eq(s.pos, Vector3(3, 0, -1), "floor sits on the 2 m cell centre")


func test_snap_wall_to_edge() -> void:
	var a := Pieces.snap("wall", Vector3(3.3, 0.0, -0.2), Vector3.UP, 0.0, 0)
	check_eq(a.pos, Vector3(3, 0, 0), "facing north: wall on the cell's z edge")
	check_eq(a.rot, 0, "spans X")
	var b := Pieces.snap("wall", Vector3(3.8, 0.0, -0.7), Vector3.UP, PI / 2.0, 0)
	check_eq(b.pos, Vector3(4, 0, -1), "turned: wall on the x edge")
	check_eq(b.rot, 1, "spans Z")
	check_eq(Pieces.turned_size("wall", 1), Vector3(0.3, 2, 2), "turned wall is thin along X")


func test_inside_rock_is_refused() -> void:
	check_eq(Pieces.rock_problem("wall", Vector3(1, 0, 0), 0, flat_ground), "", "wall standing on the ground is fine")
	check_eq(Pieces.rock_problem("wall", Vector3(1, -1, 0), 0, flat_ground), "Inside rock", "half buried wall is refused")
	check_eq(Pieces.rock_problem("floor", Vector3(1, -0.4, 1), 0, flat_ground), "", "floors may sink a little")


func test_ground_pieces_are_anchored() -> void:
	check(Pieces.touches_rock("floor", Vector3(1, 0, 1), 0, flat_ground), "floor on the ground touches rock")
	check(not Pieces.touches_rock("floor", Vector3(1, 3, 1), 0, flat_ground), "floating floor doesn't")


func test_wood_tower_and_bridge() -> void:
	var s := Structure.new()
	s.add(1, "wall", "plank_root", Vector3(1, 0, 0), 0, true)
	s.add(2, "wall", "plank_root", Vector3(1, 2, 0), 0, false)
	s.add(3, "wall", "plank_root", Vector3(1, 4, 0), 0, false)
	s.recompute()
	check_near(s.pieces[2].stability, 0.9, 0.001, "one up: -10%")
	check_near(s.pieces[3].stability, 0.8, 0.001, "two up: -20%")
	# A wooden bridge sticking out sideways from the top.
	for i in 6:
		s.add(10 + i, "floor", "plank_root", Vector3(3 + i * 2, 6, 0), 0, false)
	var falling := s.recompute()
	check_near(s.pieces[10].stability, 0.7, 0.001, "first bridge floor rests on the wall's top: 0.8 - 0.1")
	check_near(s.pieces[11].stability, 0.5, 0.001, "next one is sideways: 0.7 - 0.2")
	check(falling.has(14) and falling.has(15), "far end of a long wooden bridge falls")
	check(not falling.has(12), "near part stays")


func test_metal_reaches_further_than_stone() -> void:
	for fam in ["cut_stone", "copper_ingot"]:
		var s := Structure.new()
		s.add(1, "floor", fam, Vector3(1, 0, 1), 0, true)
		for i in 7:
			s.add(2 + i, "floor", fam, Vector3(3 + i * 2, 0, 1), 0, false)
		var falling := s.recompute()
		if fam == "cut_stone":
			check(falling.size() >= 4, "stone: only ~3 pieces sideways (falling %d)" % falling.size())
		else:
			check(falling.is_empty(), "copper: 7 pieces sideways is fine")


func test_overlap_blocks_duplicates() -> void:
	var s := Structure.new()
	s.add(1, "wall", "cut_stone", Vector3(1, 0, 0), 0, true)
	check(s.overlaps("wall", Vector3(1, 0, 0), 0), "same spot is taken")
	check(not s.overlaps("wall", Vector3(1, 2, 0), 0), "stacking on top is fine")
	check(not s.overlaps("floor", Vector3(1, 0, 1), 0), "floor next to the wall is fine")
	check(not s.overlaps("wall", Vector3(0, 0, 1), 1), "a wall meeting it at the corner is fine")
	check(s.overlaps("wall", Vector3(1.5, 0, 0), 0), "a wall half on top of it is not")


func test_removing_support_drops_the_rest() -> void:
	var s := Structure.new()
	s.add(1, "pillar", "cut_stone", Vector3(0, 0, 0), 0, true)
	s.add(2, "floor", "plank_root", Vector3(1, 2, 1), 0, false)
	check(s.recompute().is_empty(), "floor resting on a pillar is fine")
	s.remove(1)
	check_eq(s.recompute(), [2], "without the pillar the floor falls")
