extends TestCase
## Farm Plots (owner F176), crystal torches (F177), hand recipes at the workbench (F174).

var auth: GameAuthority
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations := Node3D.new()
	root.add_child(stations)
	var drops := Node3D.new()
	root.add_child(drops)
	auth = GameAuthority.new()
	auth.stations_root = stations
	auth.drops_root = drops
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	ps = auth.add_player(1, me)
	await tree.process_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_plant_grow_and_pick() -> void:
	await _setup()
	auth._ev_place_station(1, "farm_plot", Vector3(1, 0, 0), 0.0)
	var plot: Station = auth.stations[1]
	check_eq(auth.request_farm(1, 1), "no_seed", "nothing to plant: nothing happens")
	ps.inventory.add("glowcap", 2)
	check_eq(auth.request_farm(1, 1, "glowcap"), "planted", "a glowcap gets planted")
	check_eq(ps.inventory.count_of("glowcap"), 1, "planting uses one")
	check_eq(plot.crop, "glowcap", "the plot knows what's growing")
	check_eq(auth.request_farm(1, 1), "growing", "can't pick it before it's ready")
	plot._process(Station.CROPS.glowcap.grow + 1.0)
	check(plot.crop_ripe(), "after the grow time it's ready")
	check_eq(auth.request_farm(1, 1), "picked", "pick it")
	check_eq(ps.inventory.count_of("glowcap"), 1 + Station.CROPS.glowcap.give, "you get more than you planted")
	check_eq(plot.crop, "", "the plot is empty again")
	ps.inventory.add("bellcap", 1)
	check_eq(auth.request_farm(1, 1, "rootwood"), "planted", "not a seed in hand: uses one from the bag")
	var snap := auth.snapshot()
	check_eq(snap.stations[0][7], plot.crop, "what's growing is saved")
	_teardown()


func test_tuber_seeds_and_firecaps_grow() -> void:
	await _setup()
	auth._ev_place_station(1, "farm_plot", Vector3(1, 0, 0), 0.0)
	var plot: Station = auth.stations[1]
	ps.inventory.add("root_tuber", 2)
	check_eq(auth.request_farm(1, 1, "root_tuber"), "no_seed", "a Root Tuber can't be planted, only Tuber Seeds")
	ps.inventory.add("tuber_seed", 1)
	check_eq(auth.request_farm(1, 1, "tuber_seed"), "planted", "a Tuber Seed gets planted")
	check_eq(plot.crop, "root_tuber", "and grows into Root Tubers")
	plot._process(Station.CROPS.root_tuber.grow + 1.0)
	check_eq(auth.request_farm(1, 1), "picked", "pick it")
	check_eq(ps.inventory.count_of("root_tuber"), 2 + 5, "5 tubers from one seed")
	check_eq(Station.CROPS.glowcap.grow, 900.0, "mushrooms take 15 minutes")
	ps.inventory.add("firecap", 1)
	check_eq(auth.request_farm(1, 1, "firecap"), "planted", "firecaps grow too")
	_teardown()


func test_crystal_torch_is_cheap_and_by_hand() -> void:
	var r := Recipes.get_recipe("crystal_torch")
	check_eq(r.station, Recipes.HAND, "made by hand")
	check(r.inputs.size() <= 2, "only two things go in")
	check_eq(Items.kind("crystal_torch"), "station", "you can place it")


func test_more_fiber_and_roots_give_some() -> void:
	check_eq(GlowPlacer.KINDS.root.get("extra", ""), "fiber", "chopping a root also drops fiber")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var fiber := 0
	for i in 1000:
		if GlowPlacer._pick_kind(Vector3.UP, rng) == "fiber":
			fiber += 1
	check(fiber > 330, "lots of fiber on the floor (%d of 1000)" % fiber)


## F892 (owner, Nov 25): E opens the plot's menu, you pick a seed, the plant grows on the plot. No mushrooms on an
## empty plot, no timer or "growing" text.
func test_plot_menu_plants_and_it_grows_on_the_plot() -> void:
	await _setup()
	auth._ev_place_station(1, "farm_plot", Vector3(1, 0, 0), 0.0)
	var plot: Station = auth.stations[1]
	check(plot.get_node_or_null("Crop") == null, "an empty plot shows no plants")
	var panel := FarmPanel.new()
	tree.root.add_child(panel)
	panel.open(plot)
	check_eq(panel._row.get_child_count(), 0, "nothing to plant: no buttons")
	ps.inventory.add("glowcap", 2)
	ps.inventory.add("tuber_seed", 1)
	ps.inventory.add("root_tuber", 3)
	panel._refresh()
	var names := []
	for b in panel._row.get_children():
		if not b.is_queued_for_deletion():
			names.append(str(b.name))
	names.sort()
	check_eq(names, ["glowcap", "tuber_seed"], "a button for each thing you can plant (not Root Tubers)")
	var planted := [false]
	panel.done.connect(func() -> void: planted[0] = true)
	(panel._row.get_node("glowcap") as Button).pressed.emit()
	check(planted[0], "planting closes the menu")
	check_eq(plot.crop, "glowcap", "the Glowcap is planted")
	check_eq(ps.inventory.count_of("glowcap"), 1, "it used one")
	var crop: Node3D = plot.get_node_or_null("Crop")
	check(crop != null and crop.get_child_count() == 5, "five Glowcaps show on the plot")
	var small: float = crop.get_child(0).scale.x
	check(not plot.farm_text().contains(":") and not plot.farm_text().to_lower().contains("grow"), "no timer or 'growing' text (%s)" % plot.farm_text())
	plot._process(Station.CROPS.glowcap.grow * 0.5)
	plot._process(0.6)
	check(crop.get_child(0).scale.x > small * 2.0, "they get bigger as they grow")
	plot._process(Station.CROPS.glowcap.grow)
	panel._refresh()
	check(panel._row.get_node_or_null("glowcap") != null and plot.crop_ripe(), "ready: a Pick button")
	(panel._row.get_node("glowcap") as Button).pressed.emit()
	check_eq(plot.crop, "", "picked: the plot is empty")
	plot._process(0.6)
	check(plot.get_node_or_null("Crop") == null or plot.get_node("Crop").is_queued_for_deletion(), "and shows no plants again")
	panel.queue_free()
	_teardown()
