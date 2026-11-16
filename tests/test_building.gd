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
	check(Pieces.rock_problem("wall", Vector3(1, -1, 0), 0, flat_ground).begins_with("Inside rock"), "half buried wall is refused")
	check(Pieces.rock_problem("wall", Vector3(1, -1, 0), 0, flat_ground).contains("bottom"), "and it says where: the bottom (F139)")
	check_eq(Pieces.rock_problem("floor", Vector3(1, -0.4, 1), 0, flat_ground), "", "floors may sink a little")


func test_ground_pieces_are_anchored() -> void:
	check(Pieces.touches_rock("floor", Vector3(1, 0, 1), 0, flat_ground), "floor on the ground touches rock")
	check(not Pieces.touches_rock("floor", Vector3(1, 3, 1), 0, flat_ground), "floating floor doesn't")


## F162: on a slope, each Shack foundation leg reaches down to the rock by itself.
func test_foundation_legs_reach_the_ground() -> void:
	var slope := func(p: Vector3) -> float: return p.y + p.x  # ground falls away toward +x (45 degrees)
	var drops := Pieces.leg_drops("foundation", "plank_root", Vector3(0, 0, 0), 0, slope)
	check_eq(drops.size(), 4, "four legs")
	check(drops[0] < 0.1 and drops[3] < 0.1, "the uphill legs stand on the floor")
	check(absf(drops[1] - 0.8) < 0.15 and absf(drops[2] - 0.8) < 0.15, "the downhill legs reach 0.8 m down")
	check(Pieces.touches_rock("foundation", Vector3(0, 2, 0), 0, flat_ground, "plank_root"), "a Shack foundation 2 m up stands on its legs")
	check(not Pieces.touches_rock("foundation", Vector3(0, 2, 0), 0, flat_ground, "cut_stone"), "a stone one (no legs) doesn't")
	check(not Pieces.touches_rock("foundation", Vector3(0, 4, 0), 0, flat_ground, "plank_root"), "legs reach at most 3 m")
	check_eq(Pieces.leg_drops("foundation_triangle", "plank_root", Vector3.ZERO, 0, flat_ground).size(), 3, "triangles have 3 legs")
	var n: PieceNode = preload("res://src/build/piece_node.gd").new()
	n.piece = "foundation"
	n.family = "plank_root"
	tree.root.add_child(n)
	n.set_legs([0.0, 1.6, 1.6, 0.0])
	check_eq(n._legs.get_child_count(), 6, "two legs of 2 sections each + 2 foot stones")
	n.queue_free()


func test_wood_tower_and_bridge() -> void:
	var s := Structure.new()
	s.add(1, "wall", "plank_root", Vector3(1, 0, 0), 0, true)
	s.add(2, "wall", "plank_root", Vector3(1, 2, 0), 0, false)
	s.add(3, "wall", "plank_root", Vector3(1, 4, 0), 0, false)
	s.recompute()
	# Soft physics (building polish spec §5): wood loses 0.08 going up, 0.16 sideways.
	check_near(s.pieces[2].stability, 0.92, 0.001, "one up: -8%")
	check_near(s.pieces[3].stability, 0.84, 0.001, "two up: -16%")
	# A wooden bridge sticking out sideways from the top.
	for i in 6:
		s.add(10 + i, "floor", "plank_root", Vector3(3 + i * 2, 6, 0), 0, false)
	var falling := s.recompute()
	check_near(s.pieces[10].stability, 0.76, 0.001, "first bridge floor rests on the wall's top: 0.84 - 0.08")
	check_near(s.pieces[11].stability, 0.60, 0.001, "next one is sideways: 0.76 - 0.16")
	check(falling.has(15), "far end of a long wooden bridge (6th piece) falls")
	check(not falling.has(14), "5 pieces out still hold (softer than before)")


func test_metal_reaches_further_than_stone() -> void:
	for fam in ["cut_stone", "copper_ingot"]:
		var s := Structure.new()
		s.add(1, "floor", fam, Vector3(1, 0, 1), 0, true)
		for i in 11:
			s.add(2 + i, "floor", fam, Vector3(3 + i * 2, 0, 1), 0, false)
		var falling := s.recompute()
		# Soft physics: stone loses 0.10 sideways (9 pieces out hold), copper 0.06 (11 hold).
		if fam == "cut_stone":
			check(falling.size() == 2, "stone: the 10th and 11th pieces out fall (falling %d)" % falling.size())
		else:
			check(falling.is_empty(), "copper: 11 pieces sideways is fine")


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


## Owner, Nov 16: you can walk under the stairs (the solid shape is a slanted slab, not a solid wedge).
func test_room_under_the_stairs() -> void:
	var n: PieceNode = preload("res://src/build/piece_node.gd").new()
	n.piece = "stairs"
	n.family = "plank_root"
	tree.root.add_child(n)
	var shape: Shape3D = null
	for c in n.get_children():
		if c is CollisionShape3D:
			shape = (c as CollisionShape3D).shape
	check(shape is ConvexPolygonShape3D, "the stairs have a solid shape to walk up")
	var lowest_under_back := INF
	for p in (shape as ConvexPolygonShape3D).points:
		if p.z < -0.9:
			lowest_under_back = minf(lowest_under_back, p.y)
	check(lowest_under_back > 1.4, "under the high end there's room to walk (underside at %.2f m)" % lowest_under_back)
	n.queue_free()
