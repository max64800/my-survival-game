extends TestCase
## Kiln and smelters that run by themselves from nearby chests (feedback F32).

var auth: GameAuthority


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.stations_root = stations
	root.add_child(auth)
	await tree.process_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_kiln_turns_chest_wood_into_coal() -> void:
	await _setup()
	auth._ev_place_station(1, "kiln", Vector3(0, 0, 0), 0.0)
	var kiln: Station = auth.stations[1]
	var chest := auth.storage.create_box("chest_small", Vector3(2, 0, 0), 0.0)
	check_eq(AutoSmelt.feed(kiln, auth.storage), "", "an empty chest: nothing to do")
	auth.storage.put(chest, "rootwood", 5)
	check_eq(AutoSmelt.feed(kiln, auth.storage), "coal", "wood in the chest: the kiln starts")
	check_eq(auth.storage.get_box(chest).inv.count_of("rootwood"), 3, "it took 2 wood")
	check_eq(AutoSmelt.feed(kiln, auth.storage), "", "busy: one batch at a time")
	auth._process(25.0)
	check_eq(auth.storage.get_box(chest).inv.count_of("coal"), 1, "the coal went into the chest")
	var far := auth.storage.create_box("chest_small", Vector3(20, 0, 0), 0.0)
	auth.storage.put(far, "rootwood", 9)
	check(not AutoSmelt.chests_near(kiln.global_position, auth.storage).has(far), "chests 20 m away don't count")
	_teardown()


func test_smelter_takes_ore_from_the_ore_crate() -> void:
	await _setup()
	auth._ev_place_station(1, "smelter", Vector3(0, 0, 0), 0.0)
	var sm: Station = auth.stations[1]
	var crate := auth.storage.create_box("crate_ore", Vector3(2, 0, 0), 0.0)
	var chest := auth.storage.create_box("chest_small", Vector3(-2, 0, 0), 0.0)
	auth.storage.put(crate, "copper_ore", 4)
	check_eq(AutoSmelt.feed(sm, auth.storage), "", "ore but no fuel: waits")
	auth.storage.put(chest, "coal", 2)
	check_eq(AutoSmelt.feed(sm, auth.storage), "copper_ingot", "ore + coal: smelting copper")
	check_eq(auth.storage.get_box(crate).inv.count_of("copper_ore"), 2, "2 ore taken from the crate")
	check_eq(auth.storage.get_box(chest).inv.count_of("coal"), 1, "1 coal burned")
	auth._process(25.0)
	check_eq(auth.storage.get_box(chest).inv.count_of("copper_ingot"), 1, "the bar went into the chest (the ore crate doesn't take bars)")
	_teardown()


func test_twin_smelter_smelts_and_makes_coal() -> void:
	await _setup()
	auth._ev_place_station(1, "twin_smelter", Vector3(0, 0, 0), 0.0)
	var ts: Station = auth.stations[1]
	var chest := auth.storage.create_box("chest_copper", Vector3(2, 0, 0), 0.0)
	auth.storage.put(chest, "copper_ore", 2)
	auth.storage.put(chest, "rootwood", 6)
	check_eq(AutoSmelt.feed(ts, auth.storage), "copper_ingot", "one side smelts (burning wood)")
	check_eq(AutoSmelt.feed(ts, auth.storage), "coal", "the other side makes coal")
	check_eq(ts.jobs.size(), 2, "both sides busy")
	_teardown()


func test_coal_is_fuel() -> void:
	check_eq(Items.kind("coal"), "fuel", "coal burns")
	check_eq(Recipes.get_recipe("coal").station, "kiln", "made at the kiln")
	check(Recipes.get_recipe("kiln").station == "workbench", "the kiln is made at a workbench")


func test_ore_crate_looks_fuller() -> void:
	var inv := Inventory.new(60)
	check_eq(Storage.fill_level(inv), 0.0, "empty crate: no pile")
	inv.add("copper_ore", 40)
	var some := Storage.fill_level(inv)
	inv.add("stone", 300)
	check(Storage.fill_level(inv) > some and some > 0.0, "more ore, bigger pile")
	inv.add("stone", 500)
	check_eq(Storage.fill_level(inv), 1.0, "heaped up at most")
	var body := Node3D.new()
	var pile := Node3D.new()
	pile.name = "Fill"
	body.add_child(pile)
	Storage.show_fill(body, inv)
	check(pile.visible and pile.scale.y > 1.0, "the pile shows and rises")
	body.free()


func test_builders_chest_takes_decor_extras() -> void:
	check(Storage.accepts("builder", "fiber"), "fiber for rugs and banners")
	check(Storage.accepts("builder", "crystal_blue"), "crystals for sconces")
	check(not Storage.accepts("builder", "sword_stone"), "but not swords")
