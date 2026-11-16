extends TestCase
## The "dwarf workshop" menus (owner F187): the kit pieces, and the fewer-clicks bag actions.


func test_kit_pieces_load_and_stretch_without_smearing() -> void:
	for piece in UiKit.MARGINS:
		var s := UiKit.style(piece)
		check(s.texture != null, "%s picture loads" % piece)
		if s.texture == null:
			continue
		var m: Vector4 = UiKit.MARGINS[piece]
		check(m.x + m.z < s.texture.get_width() and m.y + m.w <= s.texture.get_height(),
			"%s: corners fit inside the picture (9-slice)" % piece)
	check(UiKit.style("panel", 22) == UiKit.style("panel", 22), "styles are shared, not remade")


func test_right_click_splits_a_stack_in_half() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.slots[Inventory.HOTBAR_SIZE] = {id = "stone", count = 9}
	check(inv.split(Inventory.HOTBAR_SIZE), "9 stone split")
	check_eq(int(inv.get_slot(Inventory.HOTBAR_SIZE).count), 5, "5 stay")
	check_eq(inv.count_of("stone"), 9, "nothing lost or made")
	inv.slots[2] = {id = "rope", count = 1}
	check(not inv.split(2), "a single item can't be split")


func test_shift_click_moves_between_hotbar_and_bag() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.slots[0] = {id = "stone", count = 7}
	inv.slots[Inventory.HOTBAR_SIZE + 3] = {id = "stone", count = 5}
	check(inv.quick_move(0), "hotbar stone moves to the bag")
	check(inv.get_slot(0).is_empty(), "the hotbar slot is empty now")
	check_eq(int(inv.get_slot(Inventory.HOTBAR_SIZE + 3).count), 12, "it topped up the stone already in the bag")
	check(inv.quick_move(Inventory.HOTBAR_SIZE + 3), "and back to the hotbar")
	check_eq(int(inv.get_slot(0).count), 12, "into the first hotbar slot")
	check_eq(inv.count_of("stone"), 12, "nothing lost or made")
	for i in Inventory.HOTBAR_SIZE:
		inv.slots[i] = {id = "rope", count = 1}
	inv.slots[Inventory.HOTBAR_SIZE] = {id = "stone", count = 3}
	check(not inv.quick_move(Inventory.HOTBAR_SIZE), "a full hotbar: nothing moves")
	check_eq(int(inv.get_slot(Inventory.HOTBAR_SIZE).count), 3, "the stone stays put")
