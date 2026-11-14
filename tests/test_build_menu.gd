extends TestCase
## Build menu tabs, the blueprint book and where a blueprint's chest goes (building polish B5).


func test_every_piece_is_on_a_tab() -> void:
	var seen := 0
	for g in BuildMenu.TABS:
		seen += BuildMenu.pieces_in(g).size()
	check_eq(seen, Pieces.LIST.size(), "every piece shows up on exactly one tab")
	check(BuildMenu.pieces_in("roof").has("roof_45"), "roofs on the Roofs tab")
	check_eq(BuildMenu.station_item("cut_stone"), "masonry_table", "stone is worked at the Mason's Table")


func test_blueprint_book_has_the_ready_made_buildings() -> void:
	var names := []
	for e in BlueprintMenu.entries():
		var r := Blueprint.from_json(e.json)
		check(r.ok, "%s loads" % e.name)
		if r.ok:
			names.append(r.blueprint.name)
	for id in BlueprintLibrary.IDS:
		check(names.has(BlueprintLibrary.NAMES[id]), "%s is in the book" % BlueprintLibrary.NAMES[id])


func test_chest_goes_on_the_open_side_nearest_you() -> void:
	var size := Vector3(6, 4, 8)
	var flat := func(p: Vector3) -> float: return p.y  # open floor everywhere at y = 0
	var c := Builder.chest_spot(size, Vector3.ZERO, 0, Vector3(0, 0, 20), flat)
	check(c.is_finite(), "found a spot")
	check_near(c.z, 5.5, 0.01, "in front (+z), just outside the building")
	check_near(c.y, 0.25, 0.3, "on the floor")
	var side := Builder.chest_spot(size, Vector3.ZERO, 0, Vector3(20, 0, 0), flat)
	check_near(side.x, 4.5, 0.01, "on the side facing you when you stand to the side")
	# A building pushed into a rock wall: everything at z > 0 is solid mountain.
	var wall := func(p: Vector3) -> float: return minf(p.y, -p.z)
	var back := Builder.chest_spot(size, Vector3.ZERO, 0, Vector3(0, 0, 20), wall)
	check(back.is_finite() and back.z < 0.0, "the chest goes on the open side, not into the rock")
	var solid := func(_p: Vector3) -> float: return -1.0
	check(not Builder.chest_spot(size, Vector3.ZERO, 0, Vector3.ZERO, solid).is_finite(), "no open floor anywhere = no spot")


func test_steadiness_words() -> void:
	check(Hud.steadiness_text({anchored = true, stability = 1.0}).begins_with("rock-steady"), "on rock")
	check_eq(Hud.steadiness_text({anchored = false, stability = 0.8}), "80% steady", "held up by others")
	check(Hud.steadiness_text({anchored = false, stability = 0.2}).begins_with("shaky"), "about to fall")
