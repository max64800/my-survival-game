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
	var inv := ps.inventory
	inv.add("pickaxe_stone", 1)  # hotbar slot 0
	inv.add("sword_copper", 1)  # hotbar slot 1
	check(not inv.swap(1, Inventory.equip_index("weapon")), "the old weapon slot takes nothing now (F825)")
	check(inv.set_worn(0, true) and inv.set_worn(1, true), "right-click puts them on where they lie (gold E)")
	check(inv.is_worn(0) and inv.is_worn(1), "both worn")
	check_eq(inv.equipped("weapon"), "sword_copper", "the worn sword counts as equipped")
	inv.add("stone", 4)
	ps.selected_slot = 2  # the stones
	check_eq(ps.selected_item(), "stone", "picking rocks: you hold the rocks (F151)")
	for k in Inventory.HOTBAR_SIZE:
		if inv.get_slot(k).is_empty():
			ps.selected_slot = k
			break
	check_eq(ps.selected_item(), "pickaxe_stone", "an empty hotbar slot: your worn pickaxe")
	ps.weapon_drawn = true
	check_eq(ps.selected_item(), "sword_copper", "F draws the worn weapon")
	ps.weapon_drawn = false
	inv.add("sword_stone", 1)
	var other := -1
	for k in Inventory.HOTBAR_SIZE:
		if inv.get_slot(k).get("id", "") == "sword_stone":
			other = k
	ps.selected_slot = other
	check_eq(ps.selected_item(), "", "an unworn sword does nothing until it's on (F826)")
	inv.set_worn(other, true)
	check(not inv.is_worn(1) and inv.is_worn(other), "one weapon worn at a time: the old one comes off")
	inv.add("dish_hollowcap_stew", 1)
	for k in Inventory.HOTBAR_SIZE:
		if inv.get_slot(k).get("id", "") == "dish_hollowcap_stew":
			ps.selected_slot = k
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
	for k in Inventory.HOTBAR_SIZE:
		match ps.inventory.get_slot(k).get("id", ""):
			"shield_stone": sh = k
			"stone": st = k
	check(Hud.wants_equip_click(sh, ps.inventory), "right-click on a shield equips it")
	check(not Hud.wants_equip_click(st, ps.inventory), "right-click on stones still splits them")
	check(not ps.can_draw(), "an unworn shield can't be raised")
	check(ps.inventory.toggle_equip(sh), "the shield goes on")
	check(ps.inventory.is_worn(sh), "...and stays in its hotbar slot, marked worn")
	check(Hud.wants_equip_click(sh, ps.inventory), "right-click again takes it off")
	check(ps.can_draw(), "F works with only a shield worn")
	ps.weapon_drawn = true
	check_eq(ps.selected_item(), "shield_stone", "F with only a shield: you raise the shield")
	ps.inventory.add("lantern", 1)  # the hand lantern goes in its slot
	check(not DwarfFight.off_hand_free(ps), "the hand lantern fills the off hand")
	ps.lantern_stowed = true
	check(DwarfFight.off_hand_free(ps), "L puts the lantern away: the shield can be used")
	check(ps.inventory.toggle_equip(sh) and not ps.inventory.is_worn(sh), "taking it off is instant")


## F826 (owner, Nov 23): putting things on takes a moment; armour longer; a hit stops it.
func test_equip_ring_takes_time_and_a_hit_stops_it() -> void:
	check_near(EquipTime.seconds_for("sword_copper"), 0.5, 0.001, "a weapon: half a second")
	check_near(EquipTime.seconds_for("helm_copper"), 1.5, 0.001, "armour: a second and a half")
	var auth := GameAuthority.new()
	tree.root.add_child(auth)
	var ps := auth.add_player(1, null, false)
	ps.inventory.add("sword_copper", 1)
	ps.selected_slot = 0
	auth.ask_equip(0)
	check(not ps.equip_job.is_empty(), "right-click starts the ring")
	check_eq(ps.hand_slot(), -1, "hands busy while it fills")
	auth.tick_equip(0.3)
	check(not ps.inventory.is_worn(0), "not on yet after 0.3 s")
	check_near(EquipTime.progress(ps.equip_job), 0.6, 0.01, "the ring is 60% full")
	auth.tick_equip(0.3)
	check(ps.equip_job.is_empty() and ps.inventory.is_worn(0), "full ring: the sword is on")
	ps.inventory.add("helm_copper", 1)  # goes straight on the head
	var hat := Inventory.equip_index("head")
	ps.inventory.swap(hat, 5)  # take it off into the bag
	auth.ask_equip(5)
	auth.tick_equip(1.0)
	ps.vitals.take_damage(5.0)
	check(ps.equip_job.is_empty(), "a hit stops putting it on")
	auth.tick_equip(1.0)
	check_eq(ps.inventory.equipped("head"), "", "...and the helm stays in the bag")
	auth.ask_equip(0)
	check(not ps.inventory.is_worn(0), "taking the sword off is instant")
	auth.queue_free()


## F828 (owner, Nov 24): armour comes off with a ring too; several pieces go on one after another; dragging into
## a gear slot fills the ring first. F829: swapping to a one-hand weapon keeps the shield on.
func test_armour_off_ring_queue_and_drag() -> void:
	var auth := GameAuthority.new()
	tree.root.add_child(auth)
	var ps := auth.add_player(1, null, false)
	var inv := ps.inventory
	inv.slots[10] = {id = "helm_copper", count = 1}
	inv.slots[11] = {id = "boots_leather", count = 1}
	inv.changed.emit()
	auth.ask_equip(10)
	auth.ask_equip(11)
	check_eq(ps.equip_queue.size(), 1, "the boots wait their turn")
	auth.tick_equip(1.6)
	check_eq(inv.equipped("head"), "helm_copper", "the helm is on")
	check_eq(inv.equipped("feet"), "", "the boots not yet")
	auth.tick_equip(0.01)
	auth.tick_equip(1.6)
	check_eq(inv.equipped("feet"), "boots_leather", "then the boots go on")
	auth.ask_equip(Inventory.equip_index("head"))
	check_eq(inv.equipped("head"), "helm_copper", "taking the helm off isn't instant")
	auth.tick_equip(1.6)
	check_eq(inv.equipped("head"), "", "...it comes off when the ring is full")
	var hat := -1
	for i in Inventory.EQUIP_START:
		if inv.get_slot(i).get("id", "") == "helm_copper":
			hat = i
	auth.ask_equip_move(hat, Inventory.equip_index("head"))
	check_eq(inv.equipped("head"), "", "dragging it onto the head slot fills the ring first")
	check_eq(int(ps.equip_job.get("ring", -1)), Inventory.equip_index("head"), "the ring shows on the head slot")
	auth.tick_equip(1.6)
	check_eq(inv.equipped("head"), "helm_copper", "...then it's on")
	auth.ask_equip(Inventory.equip_index("head"))
	auth.ask_equip(Inventory.equip_index("feet"))
	ps.vitals.take_damage(5.0)
	check(ps.equip_job.is_empty() and ps.equip_queue.is_empty(), "a hit stops the ring and everything waiting")
	auth.queue_free()


## F829: sword + shield worn, putting on a one-hand mace: the shield stays on the arm while the ring fills.
func test_shield_stays_while_a_one_hand_weapon_goes_on() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	var ps := auth.add_player(1, dwarf)
	ps.inventory.slots[1] = {id = "sword_copper", count = 1}
	ps.inventory.slots[2] = {id = "shield_stone", count = 1}
	ps.inventory.slots[3] = {id = "mace_stone", count = 1}
	ps.inventory.set_worn(1, true)
	ps.inventory.set_worn(2, true)
	ps.lantern_stowed = true  # (a hand lantern would fill the shield hand)
	ps.weapon_drawn = true
	check_eq(dwarf.fight.shield_item(), "shield_stone", "sword drawn: the shield is on the arm")
	auth.ask_equip(3)
	check_eq(dwarf.fight.shield_item(), "shield_stone", "putting the mace on: the shield stays")
	auth.tick_equip(0.6)
	check_eq(ps.inventory.equipped("weapon"), "mace_stone", "the mace is on")
	check_eq(dwarf.fight.shield_item(), "shield_stone", "...and the shield still is")
	root.queue_free()


## F825 (owner, Nov 23): Q over a slot throws it away; picking it back up keeps its wear and upgrades.
func test_q_throw_keeps_the_items_data() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.add("sword_copper", 1)
	inv.slots[0]["up"] = 2
	inv.set_worn(0, true)
	var s := inv.take_slot(0)
	check(inv.get_slot(0).is_empty(), "the slot is empty")
	check_eq(int(s.get("up", 0)), 2, "the thrown sword keeps its +2")
	check(not s.has("worn"), "...but isn't worn any more")
	inv.slots[Inventory.equip_index("pack")] = {id = "satchel", count = 1}
	inv.slots[Inventory.PACK_START] = {id = "stone", count = 3}
	check(inv.take_slot(Inventory.equip_index("pack")).is_empty(), "a backpack with things in it can't be thrown")


## F825: an old save with a sword/shield/pickaxe in the old equipment slots: they move into the bag, still worn.
func test_old_save_hand_slots_move_into_the_bag() -> void:
	var old := Inventory.new(Inventory.PLAYER_SIZE)
	old.slots[Inventory.equip_index("weapon")] = {id = "sword_copper", count = 1}
	old.slots[Inventory.equip_index("shield")] = {id = "shield_stone", count = 1}
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.load_data(old.to_data())
	check(inv.get_slot(Inventory.equip_index("weapon")).is_empty(), "the old weapon slot is empty")
	check_eq(inv.equipped("weapon"), "sword_copper", "the sword is still worn")
	check_eq(inv.equipped("shield"), "shield_stone", "so is the shield")
	check(inv.get_slot(inv.worn_slot("weapon")).get("worn", false), "it carries the gold E")

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


## F613 (owner, Nov 22): the Hip Lantern swings on the belt when he walks and stops, then settles.
func test_hip_lantern_swings_when_he_stops() -> void:
	var dm := DwarfModel.new()
	tree.root.add_child(dm)
	var lantern := Lantern.new()
	dm.left_hand.add_child(lantern)
	lantern.set_process(false)
	lantern.place("hip")
	for i in 5:
		await tree.process_frame
	var dt := 1.0 / 60.0
	var step := func(move: Vector3) -> void:
		dm.global_position += move
		lantern._to_belt()
		lantern._hang("hip")
		lantern._swing_step(dt)
	for i in 30:
		step.call(Vector3.ZERO)
	check(lantern.swing_degrees() < 0.5, "standing still: it hangs straight (%.1f°)" % lantern.swing_degrees())
	for i in 40:  # walk forward at 3 m/s...
		step.call(Vector3(0, 0, 3.0 * dt))
	var most := 0.0
	for i in 20:  # ...and stop dead
		step.call(Vector3.ZERO)
		most = maxf(most, lantern.swing_degrees())
	check(most > 8.0, "stopping makes it swing forward (%.1f°)" % most)
	check(most < 35.0, "but not wildly (%.1f°)" % most)
	var belt := lantern.global_position + Vector3(0, Lantern.BELT_ABOVE * Lantern.HIP_SCALE, 0)
	var hook_top := lantern.to_global(Vector3(0, Lantern.BELT_ABOVE, 0))
	check(hook_top.distance_to(dm.hip_point()) < 0.02, "it swings around the belt ring, which stays on the belt (%.3f m)" % hook_top.distance_to(dm.hip_point()))
	for i in 180:
		step.call(Vector3.ZERO)
	check(lantern.swing_degrees() < 1.5, "a few seconds later it hangs still again (%.1f°)" % lantern.swing_degrees())
	var bottom := dm.to_local(lantern.to_global(Vector3(0, -0.25, 0))).y
	check(bottom > 0.02, "still clear of the ground (%.2f)" % bottom)
	dm.queue_free()


## F825: the host throws the slot on the floor, and picking the drop back up gives the same item, upgrades and all.
func test_q_throw_makes_a_drop_and_picks_back_up() -> void:
	var auth := GameAuthority.new()
	var root := Node3D.new()
	tree.root.add_child(root)
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	var body := Node3D.new()
	root.add_child(body)
	var ps := auth.add_player(1, body, false)
	ps.inventory.add("coal", 12)
	ps.inventory.add("sword_copper", 1)
	ps.inventory.slots[1]["up"] = 3
	check(auth.request_throw(1, 0), "Q throws the coal")
	check(ps.inventory.get_slot(0).is_empty(), "the coal slot is empty")
	check(auth.request_throw(1, 1), "Q throws the sword")
	check_eq(auth.drops_root.get_child_count(), 2, "two drops on the floor")
	root.queue_free()


## F831 (owner, Nov 24): weapon tips say what slash / blunt / pierce mean in plain words, in a framed box.
func test_weapon_tips_explain_the_damage_kind() -> void:
	check(Combat.type_text("mace_stone").contains("Blunt") and Combat.type_text("mace_stone").contains("shield allowed"),
			"a mace: blunt, one hand, shield allowed")
	check(Combat.type_text("sword_copper").contains("Slash"), "a sword: slash")
	check(Combat.type_text("mace_2h_copper").contains("two hands"), "a great mace: two hands")
	check(Combat.type_text("crossbow_stone").contains("armour"), "the crossbow goes through armour")
	check_eq(Combat.type_text("stone"), "", "a rock: nothing")
	var slot := ItemTipSlot.new()
	tree.root.add_child(slot)
	var tip = slot._make_custom_tooltip("[b]Stone Mace[/b]\n" + Combat.type_text("mace_stone"))
	check(tip is PanelContainer and (tip.get_child(0) as RichTextLabel).get_parsed_text().begins_with("Stone Mace"),
			"the tip box shows the name without the [b] marks")
	tip.free()
	slot.queue_free()
