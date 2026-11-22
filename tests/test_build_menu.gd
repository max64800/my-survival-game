extends TestCase
## Build menu tabs, the blueprint book and where a blueprint's chest goes (building polish B5).


func test_every_piece_is_on_a_tab() -> void:
	var seen := {}
	for t in BuildMenu.TABS:
		for g in BuildMenu.TABS[t].groups:
			for id in BuildMenu.pieces_in(g):
				check(not seen.has(id), "%s is on only one tab" % id)
				seen[id] = true
	var legacy := BuildMenu.pieces_in("legacy").size()
	check_eq(seen.size() + legacy, Pieces.LIST.size(), "every piece shows up on exactly one tab (old 45° pieces hidden)")
	check(BuildMenu.tab_pieces("roofs").has("roof_45"), "roofs on the Roofs tab")
	check_eq(BuildMenu.station_item("cut_stone"), "masonry_table", "stone is worked at the Mason's Table")
	for g in BuildMenu.HOME_SUBS:
		check_eq(BuildMenu.tab_of(g), "home", "%s is a sub-button inside Home" % g)
		check(not BuildMenu.tab_pieces("home", g).is_empty(), "the %s button shows pieces" % g)


## F709 (owner OK'd mock-up): only 6 big tabs, and a piece you can build right now gets a green tick;
## one you can't is faded and says on the card what's missing.
func test_six_tabs_and_buildable_pieces_get_a_tick() -> void:
	check_eq(BuildMenu.TABS.keys(), ["floors", "walls", "roofs", "stairs", "home", "lights"], "the 6 tabs, in order")
	var menu := BuildMenu.new()
	menu.mode = BuildMode.new()
	menu.mode.piece = "wall"
	menu.mode.family = "plank_root"
	var inv := Inventory.new()
	var cost := Pieces.cost("wall", "plank_root")
	check(not cost.is_empty(), "a wall costs something")
	var poor := menu._piece_button("wall", "plank_root", "", inv)
	check(poor.get_node_or_null("Tick") == null, "nothing in the bag: no tick")
	var first: String = cost.keys()[0]
	check(BuildMenu.card_note("wall", "plank_root", inv, "").begins_with("need %d more" % cost[first]), "the card says what's missing")
	check_eq(BuildMenu.card_note("wall", "plank_root", inv, "Needs a Workbench within 20 m"), "Needs a Workbench within 20 m", "or the station lock")
	for item in cost:
		inv.add(item, cost[item])
	var rich := menu._piece_button("wall", "plank_root", "", inv)
	check(rich.get_node_or_null("Tick") != null, "enough in the bag: a green tick")
	check(menu._piece_button("wall", "plank_root", "Needs a Workbench within 20 m", inv).get_node_or_null("Tick") == null, "no station nearby: no tick")
	for n in [poor, rich, menu.mode, menu]:
		n.free()


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
	# Holding Q / E on a building piece: one step at a time on the grid, at one calm pace (owner, Nov 19).
	check_eq(BuildMode.held_steps(0.0, 0.3), 0, "a quick tap is just the one step")
	check_eq(BuildMode.held_steps(0.0, 0.4), 1, "held a moment: one more step")
	var steps := 0
	var t := 0.0
	while t < 4.0:  # held 4 s at 60 frames a second: steps at 0.35, 0.75 ... 3.95 s
		steps += BuildMode.held_steps(t, t + 1.0 / 60.0)
		t += 1.0 / 60.0
	check_eq(steps, 10, "then one step every 0.4 s, not faster the longer you hold (%d)" % steps)
	bm.queue_free()
	PlaceGhost.yaw = 0.0
	var g := PlaceGhost.new()
	g.turn(1)
	check_near(PlaceGhost.yaw, deg_to_rad(5.0), 0.001, "stations turn 5° per tap (F397)")
	g.turn(-1)
	g.turn(-1)
	check_near(PlaceGhost.yaw, deg_to_rad(-5.0), 0.001, "and back the other way")
	check_eq(PlaceGhost.held_turn(1, 0.1, 0.1), 0.0, "a quick tap doesn't keep turning")
	var early := PlaceGhost.held_turn(1, 0.5, 0.1)
	check(early > 0.0, "holding Q keeps turning")
	check_near(PlaceGhost.held_turn(1, 8.0, 0.1), early, 0.0001, "at the same calm speed, not faster the longer you hold")
	check(PlaceGhost.held_turn(-1, 1.0, 0.1) < 0.0, "holding E turns the other way")
	g.free()


## F632 (owner, Nov 22, "big note"): a chest turned before placing went down facing the other way. The ghost
## must show the same model facing the same way as the real chest or station placed with that turn.
func test_the_ghost_faces_the_same_way_as_what_is_placed() -> void:
	for id in ["chest_small", "workbench"]:
		var g := PlaceGhost.new()
		tree.root.add_child(g)
		g._show(id)
		var ghost_y: float = g._look.rotation.y if g._look else -1.0
		var real: Node3D
		if Items.kind(id) == "chest":
			var body := StaticBody3D.new()
			var st := Storage.new()
			st._build_look(body, id)
			real = body
			st.free()
		else:
			var s: Station = Station.new()
			s.kind = id
			s._build_look()
			real = s
		var real_y := -1.0
		for c in real.get_children():
			if c is Node3D and not c is CollisionShape3D:
				real_y = (c as Node3D).rotation.y
				break
		check(real_y != -1.0, "%s has a real model to compare" % id)
		check_near(ghost_y, real_y, 0.001, "the %s ghost is turned like the real one" % id)
		real.free()
		g.free()


## F100 (owner, Nov 19): the screen says how to take the aimed piece down.
func test_take_down_text_says_how() -> void:
	check(Hud.take_down_text(7.2).contains("8 s left"), "seconds left to pick up")
	check(Hud.take_down_text(0.0).begins_with("X: break"), "too late: only breaking")
	check(Hud.take_down_text(-1.0).contains("pick up") and Hud.take_down_text(-1.0).contains("half back"), "a friend's computer still shows both ways")
	check(not Hud.take_down_text(0.0).contains("%%") and not Hud.take_down_text(3.0).contains("%%"), "no doubled % signs")


## F708 (owner, Nov 22: "in the build menu the mouse cursor sometimes disappears"): like the chest menu (F633), the
## build menu always shows the cursor when it appears, even if something had grabbed the mouse just before.
func test_build_menu_always_shows_the_cursor() -> void:
	var was_robot := Controls.robot
	Controls.robot = true  # (pretend mouse: never grabs the real one)
	var root := Control.new()
	tree.root.add_child(root)
	var menu := BuildMenu.new()
	menu.visible = false
	root.add_child(menu)
	for i in 3:
		Controls.set_captured(true)  # the game had the mouse (playing, or a stray click grabbed it)
		menu.visible = false
		menu.visible = true
		check(not Controls.captured(), "opening the build menu shows the cursor (try %d)" % (i + 1))
	root.queue_free()
	Controls.robot = was_robot
