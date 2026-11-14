extends TestCase
## Chests, graves and dying.

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_inventory_any_size() -> void:
	var inv := Inventory.new(12)
	check_eq(inv.slots.size(), 12, "a 12-slot chest")
	check_eq(inv.add("stone", 1300), 100, "12 stacks fit, 100 left over")


func test_chest_place_fill_and_empty() -> void:
	await _setup()
	ps.inventory.add("chest_small", 1)
	ps.inventory.add("stone", 50)
	auth.request_select_slot(1, 0)
	auth.request_select_slot(1, 1)  # the chest is in slot 2 (pickaxe is in slot 1)
	var spot := world.maker.find_floor(player.global_position.x + 1.5, player.global_position.z, player.global_position.y + 1.0)
	check_eq(auth.request_use(1, spot, Vector3.UP, 0.0), "placed", "chest placed")
	check_eq(auth.storage.boxes.size(), 1, "one chest")
	var id: int = auth.storage.boxes.keys()[0]
	var stone_slot := -1
	for i in Inventory.SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "stone":
			stone_slot = i
	check(auth.storage.request_transfer(1, id, false, stone_slot), "stone into the chest")
	check_eq(ps.inventory.count_of("stone"), 0, "bag has none")
	check_eq(auth.storage.get_box(id).inv.count_of("stone"), 50, "chest has 50")
	check_eq(auth.storage.request_take_all(1, id), 50, "take all")
	check_eq(ps.inventory.count_of("stone"), 50, "back in the bag")
	_teardown()


func test_too_far_from_chest() -> void:
	await _setup()
	var id := auth.storage.create_box("chest_small", player.global_position + Vector3(20, 0, 0), 0.0)
	auth.storage.put(id, "copper_ore", 5)
	check_eq(auth.storage.request_take_all(1, id), 0, "can't loot from 20 m away")
	_teardown()


func test_builder_chest_only_takes_building_stuff() -> void:
	check(Storage.accepts("builder", "plank_root"), "planks yes")
	check(Storage.accepts("builder", "cut_stone"), "cut stone yes")
	check(not Storage.accepts("builder", "dish_jungle_pie"), "pie no")
	check(Storage.accepts("chest_small", "dish_jungle_pie"), "normal chests take anything")


func test_dying_makes_a_grave_and_keeps_tools() -> void:
	await _setup()
	ps.inventory.add("copper_ore", 30)
	ps.inventory.add("crystal_blue", 4)
	player.global_position += Vector3(5, 0, 0)
	var died_at := player.global_position
	ps.vitals.take_damage(500)
	auth._tick_vitals(ps, 0.016)
	check_eq(auth.storage.boxes.size(), 1, "a grave appeared")
	var grave: Dictionary = auth.storage.boxes.values()[0]
	check_eq(grave.kind, "grave", "it's a grave")
	check(grave.node.global_position.distance_to(died_at) < 0.1, "where you fell")
	check_eq(grave.inv.count_of("copper_ore"), 30, "your copper is in it")
	check_eq(ps.inventory.count_of("copper_ore"), 0, "not in your bag")
	check_eq(ps.inventory.count_of("pickaxe_stone"), 1, "you kept your pickaxe")
	check(not ps.vitals.is_dead(), "you're alive again")
	check(player.global_position.distance_to(world.maker.spawn_point) < 0.1, "woke at the start (no bed)")
	_teardown()


func test_empty_grave_crumbles() -> void:
	await _setup()
	ps.inventory.add("stone", 5)
	ps.vitals.take_damage(500)
	auth._tick_vitals(ps, 0.016)
	var id: int = auth.storage.boxes.keys()[0]
	player.global_position = auth.storage.get_box(id).node.global_position
	auth.storage.request_take_all(1, id)
	check(auth.storage.boxes.is_empty(), "grave gone after you emptied it")
	check_eq(ps.inventory.count_of("stone"), 5, "stone back")
	_teardown()
