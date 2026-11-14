extends TestCase
## Equipment slots (feedback F23): pickaxe, lantern, weapon, shield, head, chest, legs, feet, pack.


func _dwarf_inv() -> Inventory:
	return Inventory.new(Inventory.PLAYER_SIZE)


func test_tools_and_clothes_go_into_their_slots_by_themselves() -> void:
	var inv := _dwarf_inv()
	inv.add("pickaxe_stone", 1)
	inv.add("lantern", 1)
	inv.add("cap_leather", 1)
	check_eq(inv.equipped("pickaxe"), "pickaxe_stone", "a new pickaxe goes in the pickaxe slot")
	check_eq(inv.equipped("lantern"), "lantern", "a new lantern goes in the lantern slot")
	check_eq(inv.equipped("head"), "cap_leather", "a cap goes on your head")
	check(inv.get_slot(0).is_empty(), "the hotbar stays free")
	inv.add("pickaxe_stone", 1)
	check_eq(inv.get_slot(0).get("id", ""), "pickaxe_stone", "a second pickaxe goes in the bag (slot already used)")
	check(Inventory.new().equipped("pickaxe") == "", "chests have no equipment slots")


func test_slots_only_take_the_right_things() -> void:
	var inv := _dwarf_inv()
	inv.add("stone", 5)
	inv.add("boots_leather", 1)  # goes on the feet
	inv.swap(Inventory.equip_index("feet"), 3)  # take the boots off into hotbar slot 3
	check(not inv.swap(0, Inventory.equip_index("head")), "stone can't be worn as a hat")
	check(not inv.swap(3, Inventory.equip_index("head")), "boots don't go on your head")
	check(inv.swap(3, Inventory.equip_index("feet")), "boots go on your feet")
	check_eq(inv.equipped("feet"), "boots_leather", "wearing the boots")


func test_backpack_opens_ten_slots_and_must_be_empty_to_take_off() -> void:
	var inv := _dwarf_inv()
	inv.add("stone", Items.stack_size("stone") * Inventory.SIZE)  # fill hotbar + bag
	check_eq(inv.add("stone", 5), 5, "a full bag takes no more")
	check(not inv.pack_open(), "no backpack: the 10 backpack slots are closed")
	inv.slots[Inventory.equip_index("pack")] = {id = "satchel", count = 1}
	check(inv.pack_open(), "wearing a satchel opens them")
	check_eq(inv.add("stone", 5), 0, "now there's room")
	var spare := 0
	for i in range(Inventory.PACK_START, Inventory.EQUIP_START):
		if inv.get_slot(i).is_empty():
			spare = i
			break
	check(not inv.swap(Inventory.equip_index("pack"), spare), "can't take the satchel off while it has things in it")


func test_hand_uses_equipped_pickaxe_and_drawn_weapon() -> void:
	var ps := GameAuthority.PlayerState.new()
	ps.inventory.add("pickaxe_stone", 1)  # equips itself
	ps.inventory.add("sword_copper", 1)  # weapons go to the hotbar (slot 0)...
	check(ps.inventory.swap(0, Inventory.equip_index("weapon")), "...and right-click equips it")
	ps.inventory.add("stone", 4)
	ps.selected_slot = 0  # the stones
	check_eq(ps.selected_item(), "pickaxe_stone", "holding rocks: you still dig with the equipped pickaxe")
	ps.weapon_drawn = true
	check_eq(ps.selected_item(), "sword_copper", "F draws the equipped weapon")
	ps.weapon_drawn = false
	ps.inventory.add("dish_hollowcap_stew", 1)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "dish_hollowcap_stew":
			ps.selected_slot = i
	check_eq(ps.selected_item(), "dish_hollowcap_stew", "picking food: you hold the food")


func test_armor_soaks_up_damage() -> void:
	var ps := GameAuthority.PlayerState.new()
	check_near(ps.armor_cut(), 0.0, 0.001, "no clothes, no armor")
	for id in ["cap_leather", "tunic_leather", "trousers_leather", "boots_leather"]:
		ps.inventory.add(id, 1)
	check_near(ps.armor_cut(), 0.22, 0.001, "full leather: 11 armor = 22% less damage")
	for part in ["head", "chest", "legs", "feet"]:
		ps.inventory.slots[Inventory.equip_index(part)] = {}
	for id in ["helm_copper", "mail_copper", "greaves_copper", "boots_copper"]:
		ps.inventory.add(id, 1)
	check_near(ps.armor_cut(), 0.48, 0.001, "full copper: 24 armor = 48% less damage")


func test_lantern_lights_only_from_its_slot() -> void:
	var ps := GameAuthority.PlayerState.new()
	ps.needs_lantern = true
	check(not Lantern.has_lantern(ps), "no lantern")
	ps.inventory.add("lantern", 1)
	check(Lantern.has_lantern(ps), "crafted: it goes in the lantern slot and lights")
	ps.inventory.swap(Inventory.equip_index("lantern"), 5)
	check(not Lantern.has_lantern(ps), "taken off into the bag: no light")
