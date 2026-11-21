extends TestCase
## Equipment slots (feedback F23): pickaxe, lantern, weapon, shield, head, chest, legs, feet, pack.


func _dwarf_inv() -> Inventory:
	return Inventory.new(Inventory.PLAYER_SIZE)


func test_tools_and_clothes_go_into_their_slots_by_themselves() -> void:
	var inv := _dwarf_inv()
	inv.add("pickaxe_stone", 1)
	inv.add("lantern", 1)
	inv.add("cap_leather", 1)
	check_eq(inv.equipped("pickaxe"), "", "a new pickaxe does NOT go in the pickaxe slot (owner F243)")
	check_eq(inv.get_slot(0).get("id", ""), "pickaxe_stone", "it goes in the hotbar instead")
	check_eq(inv.equipped("lantern"), "lantern", "a new lantern goes in the lantern slot")
	check_eq(inv.equipped("head"), "cap_leather", "a cap goes on your head")
	for i in Inventory.HOTBAR_SIZE:
		inv.slots[i] = {id = "stone", count = 1}
	inv.add("pickaxe_stone", 1)
	check_eq(inv.get_slot(Inventory.HOTBAR_SIZE).get("id", ""), "pickaxe_stone", "hotbar full: the next pickaxe goes in the bag")
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
	ps.inventory.slots[Inventory.equip_index("pickaxe")] = {id = "pickaxe_stone", count = 1}  # put on by hand (F243)
	ps.inventory.add("sword_copper", 1)  # weapons go to the hotbar (slot 0)...
	check(ps.inventory.swap(0, Inventory.equip_index("weapon")), "...and right-click equips it")
	ps.inventory.add("stone", 4)
	ps.selected_slot = 0  # the stones
	check_eq(ps.selected_item(), "stone", "picking rocks: you hold the rocks (F151)")
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).is_empty():
			ps.selected_slot = i
			break
	check_eq(ps.selected_item(), "pickaxe_stone", "an empty hotbar slot: your equipped pickaxe")
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


## Owner, Nov 17: "I cannot use the shield. Right-click a shield or anything equipable: it should go in its slot."
func test_right_click_equips_and_shield_is_usable() -> void:
	var ps := GameAuthority.PlayerState.new()
	ps.needs_lantern = true
	ps.inventory.add("shield_stone", 1)  # shields go to the hotbar
	ps.inventory.add("stone", 6)
	var sh := -1
	var st := -1
	for i in Inventory.HOTBAR_SIZE:
		match ps.inventory.get_slot(i).get("id", ""):
			"shield_stone": sh = i
			"stone": st = i
	check(Hud.wants_equip_click(sh, ps.inventory), "right-click on a shield equips it")
	check(not Hud.wants_equip_click(st, ps.inventory), "right-click on stones still splits them")
	check(ps.inventory.swap(sh, Inventory.equip_index("shield")), "the shield fits its slot")
	check(Hud.wants_equip_click(Inventory.equip_index("shield"), ps.inventory), "right-click in the slot takes it off")
	check(ps.can_draw(), "F works with only a shield equipped")
	ps.weapon_drawn = true
	check_eq(ps.selected_item(), "shield_stone", "F with only a shield: you raise the shield")
	ps.inventory.add("lantern", 1)  # the hand lantern goes in its slot
	check(not DwarfFight.off_hand_free(ps), "the hand lantern fills the off hand")
	ps.lantern_stowed = true
	check(DwarfFight.off_hand_free(ps), "L puts the lantern away: the shield can be used")


## F562 (owner, Nov 21: "an item that puts the lantern on the dwarf's hip, so fighting is easy").
func test_hip_lantern_frees_both_hands() -> void:
	var ps := GameAuthority.PlayerState.new()
	ps.needs_lantern = true
	ps.inventory.add("lantern_hip", 1)
	check_eq(ps.inventory.equipped("lantern"), "lantern_hip", "the Hip Lantern goes in the lantern slot")
	check(Lantern.has_lantern(ps), "and it lights")
	check_eq(Lantern.spot_of(ps), "hip", "it hangs on the hip")
	check(DwarfFight.off_hand_free(ps), "both hands free: shield and two-handers work")
	check(not ps.lantern_stowed, "without putting it away")
	var r := Recipes.get_recipe("lantern_hip")
	check_eq(r.get("station", ""), "workbench", "made at the Workbench (early, no copper needed)")
	check(not r.inputs.has("lantern"), "it doesn't eat the lantern you're wearing (equipped things can't be used up)")
	check(not Recipes.LIST.lantern_hip.unlock.has("copper_ingot"), "no copper needed")
	ps.inventory.slots[Inventory.equip_index("lantern")] = {id = "lantern", count = 1}
	check_eq(Lantern.spot_of(ps), "hand", "the plain lantern is still held in the hand")


## The Hip Lantern hangs at the dwarf's side, at belt height, with its hook on (and gives a bit less light).
func test_hip_lantern_hangs_at_the_belt() -> void:
	var dm := DwarfModel.new()
	tree.root.add_child(dm)
	var lantern := Lantern.new()
	dm.left_hand.add_child(lantern)
	lantern.set_process(false)  # (no player here: it would go back to the hand)
	lantern.place("hip")
	for i in 5:  # (the hip bone is posed after a few frames)
		await tree.process_frame
	lantern._to_belt()
	lantern._hang("hip")
	var local := dm.to_local(lantern.global_position + Vector3(0, Lantern.BELT_ABOVE * Lantern.HIP_SCALE, 0))
	check(absf(local.x) > 0.2, "out at the side (x %.2f)" % local.x)
	check(local.y > 0.2 and local.y < 0.9, "at belt height (y %.2f)" % local.y)
	var bottom := dm.to_local(lantern.to_global(Vector3(0, -0.25, 0))).y  # (the base, as drawn: the rig scales it)
	check(bottom > 0.02, "its bottom swings clear of the ground (owner, Nov 22: it hung by his feet) (%.2f)" % bottom)
	check(lantern._hook != null and lantern._hook.visible, "the belt hook shows")
	lantern.place("hand")
	check(not lantern._hook.visible, "no hook when it's back in the hand")
	check(Lantern.HIP_RANGE < Lantern.FULL_RANGE, "a bit less light than in the hand")
	dm.queue_free()
