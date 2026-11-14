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


func test_stations_by_material() -> void:
	check_eq(Pieces.station_for("plank_root"), "workbench", "wood → Workbench")
	check_eq(Pieces.station_for("cut_stone"), "mason", "stone → Mason's Table")
	check_eq(Pieces.station_for("clay_brick"), "mason", "brick → Mason's Table")
	check_eq(Pieces.station_for("copper_ingot"), "anvil", "copper → Anvil")
	check_eq(Pieces.needed_level("roof_26", "plank_root"), 2, "wooden roofs need Workbench level 2")
	check_eq(Pieces.needed_level("column", "cut_stone"), 2, "carved columns need Mason level 2")
	check(not Pieces.allowed("foundation", "plank_root"), "no wooden foundations")
	check(not Pieces.allowed("arch", "plank_root"), "arches are stone or brick")
