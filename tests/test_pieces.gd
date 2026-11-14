extends TestCase
## The building pieces (building polish spec §1-§2): the catalog, the soft numbers, and snapping.

const PLACES := ["cell", "edge", "corner", "free", "ceiling"]
const GROUPS := ["foundation", "floor", "wall", "roof", "support", "around", "mining"]


func test_every_piece_is_valid() -> void:
	check(Pieces.LIST.size() >= 30, "about 30 pieces (%d)" % Pieces.LIST.size())
	for id in Pieces.LIST:
		var p: Dictionary = Pieces.LIST[id]
		check((p.size as Vector3).x > 0 and (p.size as Vector3).y > 0 and (p.size as Vector3).z > 0, "%s has a size" % id)
		check(int(p.units) > 0, "%s costs something" % id)
		check(p.place in PLACES, "%s snaps a known way" % id)
		check(p.get("group", "") in GROUPS, "%s is in a menu group" % id)
		var mossy := 0
		for f in Pieces.MOSSY_FAMILIES:
			if Pieces.allowed(id, f) and Pieces.needed_level(id, f) < 99:
				mossy += 1
		check(mossy > 0, "%s can be built from a Mossy material" % id)


func test_old_ids_still_exist() -> void:
	for id in ["floor", "small_floor", "wall", "half_wall", "doorway", "window_wall", "beam", "pillar", "stairs", "ceiling_panel", "mine_prop"]:
		check(Pieces.LIST.has(id), "old piece '%s' still exists (saved blueprints use it)" % id)


func test_starter_lodge_pieces_exist() -> void:
	var r := Blueprint.from_json(FileAccess.get_file_as_string("res://blueprints/small_rootwood_lodge.dwbp"))
	check(r.ok, "the starter lodge still loads (%s)" % r.get("error", ""))
	var bp: Blueprint = r.get("blueprint")
	if bp:
		for p in bp.pieces:
			check(Pieces.LIST.has(p.id) and Pieces.allowed(p.id, p.mat), "lodge piece %s in %s is still allowed" % [p.id, p.mat])


func test_soft_numbers() -> void:
	var f := Pieces.FAMILIES
	check(f.plank_root.up == 0.08 and f.plank_root.side == 0.16, "wood loses 0.08 up / 0.16 sideways")
	check(f.cut_stone.up == 0.04 and f.cut_stone.side == 0.10, "stone 0.04 / 0.10")
	check(f.clay_brick.up == 0.04 and f.clay_brick.side == 0.10, "brick 0.04 / 0.10")
	check(f.copper_ingot.up == 0.03 and f.copper_ingot.side == 0.06, "copper 0.03 / 0.06")


# ---------------------------------------------------------------- snapping (spec §2)

const FLOOR := AABB(Vector3(0, 0, 0), Vector3(2, 0.25, 2))


func test_wall_snaps_to_floor_edge() -> void:
	var s := Pieces.snap("wall", Vector3(1.0, 0.25, 1.7), Vector3.UP, 0.0, 0, 0.0, FLOOR)
	check_eq(s.pos, Vector3(1, 0.25, 2), "wall on the floor's near edge, standing on top of it")
	var t := Pieces.snap("wall", Vector3(1.0, 0.25, 0.9), Vector3.UP, 0.0, 0, 0.0, FLOOR)
	check(t.pos.z == 0.0 or t.pos.z == 2.0, "never mid-floor (z=%s)" % t.pos.z)


func test_roof_sits_on_wall_top() -> void:
	var wall := AABB(Vector3(0, 0.25, 1.85), Vector3(2, 2, 0.3))
	var r := Pieces.snap("roof_26", Vector3(1.0, 2.25, 2.0), Vector3.UP, 0.0, 0, 0.0, wall)
	check_eq(r.pos.y, 2.25, "roof base at the wall's top")
	var w := Pieces.snap("wall", Vector3(1.0, 2.25, 2.0), Vector3.UP, 0.0, 0, 0.0, wall)
	check_eq(w.pos, Vector3(1, 2.25, 2.0), "a wall on a wall stacks exactly on it")


func test_pillar_snaps_to_floor_corner() -> void:
	var s := Pieces.snap("pillar", Vector3(1.8, 0.25, 0.3), Vector3.UP, 0.0, 0, 0.0, FLOOR)
	check_eq(s.pos, Vector3(2, 0.25, 0), "pillar on the nearest corner")


func test_half_floor_fills_1m() -> void:
	var s := Pieces.snap("small_floor", Vector3(2.4, 0.0, 0.6), Vector3.UP, 0.0, 0)
	check_eq(s.pos, Vector3(2.5, 0, 0.5), "a 1 m floor fills one 1 m square")


func test_no_anchor_uses_1m_grid() -> void:
	check_eq(Pieces.snap("floor", Vector3(3.4, 0.0, 0.0), Vector3.UP, 0.0, 0).pos.x, 3.0, "2 m floor: edges on grid lines")


func test_floor_extends_from_side() -> void:
	var s := Pieces.snap("floor", Vector3(2.0, 0.1, 1.0), Vector3.RIGHT, 0.0, 0, 0.0, FLOOR)
	check_eq(s.pos, Vector3(3, 0, 1), "aiming at a floor's side: the new one goes right next to it")


func test_rotation_cycles() -> void:
	var a := Pieces.snap("roof_45", Vector3(1, 0, 1), Vector3.UP, 0.0, 0)
	var b := Pieces.snap("roof_45", Vector3(1, 0, 1), Vector3.UP, 0.0, 4)
	check_eq(a.rot, b.rot, "four turns = back where you started")
	check_eq(a.pos, b.pos, "...in the same spot")


# ---------------------------------------------------------------- soft steadiness (spec §5)

func test_foundation_always_anchored() -> void:
	var s := Structure.new()
	s.add(1, "foundation", "cut_stone", Vector3(1, 5, 1), 0, false)  # not touching rock
	s.add(2, "wall", "plank_root", Vector3(1, 6, 0), 0, false)
	s.recompute()
	check_near(s.pieces[1].stability, 1.0, 0.001, "a foundation is always fully steady")
	check_near(s.pieces[2].stability, 0.92, 0.001, "a wooden wall on it: 1 - 0.08")
	check_near(s.preview_stability("foundation", "cut_stone", Vector3(9, 9, 9), 0, false), 1.0, 0.001, "...even in the preview")


func test_stone_reaches_farther_than_wood() -> void:
	var reach := {}
	for fam in ["plank_root", "cut_stone", "copper_ingot"]:
		var s := Structure.new()
		s.add(1, "floor", fam, Vector3(1, 0, 1), 0, true)
		for i in 20:
			s.add(2 + i, "floor", fam, Vector3(3 + i * 2, 0, 1), 0, false)
		reach[fam] = 20 - s.recompute().size()
	check(reach.plank_root < reach.cut_stone and reach.cut_stone < reach.copper_ingot,
		"wood < stone < copper sideways reach (%s)" % str(reach))
	check_eq(reach.plank_root, 5, "wood: 5 floors out")


func test_pillar_stack_stays_strong() -> void:
	var s := Structure.new()
	s.add(1, "pillar", "plank_root", Vector3(0, 0, 0), 0, true)
	for i in 5:
		s.add(2 + i, "pillar", "plank_root", Vector3(0, 2 + i * 2, 0), 0, false)
	s.recompute()
	check(s.pieces[6].stability > 0.85, "5 wooden pillars up still strong (%.2f)" % s.pieces[6].stability)


func test_strength_colors() -> void:
	check_eq(Structure.strength_color(0.9), Color(0.35, 0.6, 1.0), "strong = blue")
	check_eq(Structure.strength_color(0.6), Color(0.35, 0.9, 0.4), "good = green")
	check_eq(Structure.strength_color(0.3), Color(1.0, 0.85, 0.25), "weak = yellow")
	check_eq(Structure.strength_color(0.12), Color(1.0, 0.3, 0.25), "barely = red")


func test_stations_by_material() -> void:
	check_eq(Pieces.station_for("plank_root"), "workbench", "wood → Workbench")
	check_eq(Pieces.station_for("cut_stone"), "mason", "stone → Mason's Table")
	check_eq(Pieces.station_for("clay_brick"), "mason", "brick → Mason's Table")
	check_eq(Pieces.station_for("copper_ingot"), "anvil", "copper → Anvil")
	check_eq(Pieces.needed_level("roof_26", "plank_root"), 2, "wooden roofs need Workbench level 2")
	check_eq(Pieces.needed_level("column", "cut_stone"), 2, "carved columns need Mason level 2")
	check(not Pieces.allowed("foundation", "plank_root"), "no wooden foundations")
	check(not Pieces.allowed("arch", "plank_root"), "arches are stone or brick")
