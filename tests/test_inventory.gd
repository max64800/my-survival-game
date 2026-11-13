extends TestCase


func test_add_and_count() -> void:
	var inv := Inventory.new()
	check_eq(inv.add("stone", 12), 0, "12 stone fit")
	check_eq(inv.count_of("stone"), 12, "count stone")
	check_eq(inv.get_slot(0), {id = "stone", count = 12}, "goes into first slot")


func test_full_stack_starts_new_slot() -> void:
	var inv := Inventory.new()
	inv.add("stone", 100)
	inv.add("stone", 5)
	check_eq(inv.get_slot(0).count, 100, "first slot is a full stack")
	check_eq(inv.get_slot(1), {id = "stone", count = 5}, "extra goes to the next slot")


func test_fills_existing_stack_first() -> void:
	var inv := Inventory.new()
	inv.add("stone", 50)
	inv.add("dirt", 1)
	inv.add("stone", 60)
	check_eq(inv.get_slot(0).count, 100, "topped up first stone stack")
	check_eq(inv.get_slot(2), {id = "stone", count = 10}, "rest after the dirt")


func test_full_bag_returns_leftover() -> void:
	var inv := Inventory.new()
	check_eq(inv.add("stone", Inventory.SIZE * 100 + 7), 7, "7 stone don't fit")
	check_eq(inv.add("dirt", 3), 3, "nothing fits in a full bag")


func test_tools_do_not_stack() -> void:
	var inv := Inventory.new()
	inv.add("stone_pickaxe", 2)
	check_eq(inv.get_slot(0).count, 1, "one pickaxe per slot")
	check_eq(inv.get_slot(1).count, 1, "second pickaxe in next slot")


func test_remove() -> void:
	var inv := Inventory.new()
	inv.add("glow_crystal", 3)
	check(not inv.remove("glow_crystal", 4), "can't remove more than you have")
	check_eq(inv.count_of("glow_crystal"), 3, "failed remove changes nothing")
	check(inv.remove("glow_crystal", 3), "remove all")
	check(inv.get_slot(0).is_empty(), "slot empty after removing all")


func test_unknown_item_rejected() -> void:
	var inv := Inventory.new()
	check_eq(inv.add("banana", 1), 1, "unknown items don't go in")


func test_data_roundtrip() -> void:
	var inv := Inventory.new()
	inv.add("copper_ore", 7)
	var other := Inventory.new()
	other.load_data(inv.to_data())
	check_eq(other.count_of("copper_ore"), 7, "copy has the copper")
