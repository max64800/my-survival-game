extends TestCase
## Build menu tabs, the blueprint book and where a blueprint's chest goes (building polish B5).


func test_every_piece_is_on_a_tab() -> void:
	var seen := 0
	for g in BuildMenu.TABS:
		seen += BuildMenu.pieces_in(g).size()
	var legacy := BuildMenu.pieces_in("legacy").size()
	check_eq(seen + legacy, Pieces.LIST.size(), "every piece shows up on exactly one tab (old 45° pieces hidden)")
	check(BuildMenu.pieces_in("roof").has("roof_45"), "roofs on the Roofs tab")
	check_eq(BuildMenu.station_item("cut_stone"), "masonry_table", "stone is worked at the Mason's Table")


## Ready-made buildings are learned from Old Blueprint pages (F98); once known, all are in the book and load.
func test_blueprint_book_has_the_ready_made_buildings() -> void:
	var root := Node.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	root.add_child(auth)
	auth.world_state = {blueprints = BlueprintMenu.ready_made_keys()}
	var names := []
	for e in BlueprintMenu.entries():
		var r := Blueprint.from_json(e.json)
		check(r.ok, "%s loads" % e.name)
		if r.ok:
			names.append(r.blueprint.name)
	for id in BlueprintLibrary.IDS:
		check(names.has(BlueprintLibrary.NAMES[id]), "%s is in the book" % BlueprintLibrary.NAMES[id])
	root.queue_free()


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


## Owner (Nov 17): "every time I click a button the build menu grows until I can't see it".
## Refilling a menu must drop the old buttons right away, and the panel must shrink back.
func test_menu_refill_does_not_grow() -> void:
	var p := PanelContainer.new()
	tree.root.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	for _r in 3:
		UiKit.clear(box)
		for i in 4:
			var b := Button.new()
			b.custom_minimum_size = Vector2(100, 50)
			box.add_child(b)
	check_eq(box.get_child_count(), 4, "only the newest buttons are in the menu")
	p.reset_size()
	check(p.size.y < 4 * 50 + 4 * 8 + 1, "the panel is only as tall as one set of buttons")
	p.queue_free()


## Owner (Nov 19): "it turns when you walk; it should be Q and E". The turn is only changed by Q (+1) / E (-1), and the
## piece is snapped with no walking direction in it.
func test_q_and_e_turn_the_piece_walking_does_not() -> void:
	var bm := BuildMode.new()
	tree.root.add_child(bm)
	bm.rot = 0
	bm.turn(1)
	check_eq(bm.rot, 1, "Q turns a quarter left")
	bm.turn(-1)
	bm.turn(-1)
	check_eq(bm.rot, 3, "E turns right (and wraps round)")
	bm.choose("floor_triangle", "plank_root")
	check_eq(bm.rot, 9, "a triangle keeps facing the same way (30° steps)")
	bm.turn(-1)
	check_eq(bm.rot, 8, "triangles turn 30° per press")
	var a := Pieces.snap("floor", Vector3(3.2, 0, 1.4), Vector3.UP, 0.0, 1)
	check_eq(a.rot, 1, "the piece faces exactly its turn")
	bm.queue_free()
	PlaceGhost.yaw = 0.0
	var g := PlaceGhost.new()
	g.turn(1)
	check_near(PlaceGhost.yaw, PI / 4.0, 0.001, "stations turn 45° per press")
	g.turn(-1)
	g.turn(-1)
	check_near(PlaceGhost.yaw, -PI / 4.0, 0.001, "and back the other way")
	g.free()


## F100 (owner, Nov 19): the screen says how to take the aimed piece down.
func test_take_down_text_says_how() -> void:
	check(Hud.take_down_text(7.2).contains("8 s left"), "seconds left to pick up")
	check(Hud.take_down_text(0.0).begins_with("X: break"), "too late: only breaking")
	check(Hud.take_down_text(-1.0).contains("80% back"), "a friend's computer still shows both ways")
	check(not Hud.take_down_text(0.0).contains("%%") and not Hud.take_down_text(3.0).contains("%%"), "no doubled % signs")
