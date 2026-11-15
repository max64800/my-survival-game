extends TestCase
## Gear upgrades +1 to +3 (building polish spec §4).


func test_rules() -> void:
	var stone := {id = "pickaxe_stone", count = 1}
	check_eq(Upgrades.station_for("pickaxe_stone"), "workbench", "stone gear at the Workbench")
	check_eq(Upgrades.station_for("sword_copper"), "anvil", "copper gear at the Anvil")
	check_eq(Upgrades.station_for("helm_shell"), "workbench", "shell gear at the Workbench")
	check_eq(Upgrades.next_cost(stone), {stone = 2, crystal_blue = 1}, "+1 costs 2 stone and a blue crystal")
	check_eq(Upgrades.needed_level(stone), 2, "+1 needs Workbench level 2")
	var three := {id = "sword_copper", count = 1, up = 2}
	check_eq(Upgrades.next_cost(three), {copper_ingot = 6, crystal_green = 1}, "+3 costs 6 copper and a green crystal")
	check_eq(Upgrades.needed_level(three), 3, "the Anvil tops out at level 3, so +3 needs level 3")
	check(Upgrades.next_cost({id = "sword_copper", count = 1, up = 3}).is_empty(), "nothing past +3")
	check(Upgrades.next_cost({id = "stone", count = 5}).is_empty(), "rocks can't be upgraded")
	check_eq(Upgrades.display_name(three), "Copper Sword +2", "the name shows the level")


func test_upgrading_at_a_station() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations := Node3D.new()
	root.add_child(stations)
	var auth := GameAuthority.new()
	auth.stations_root = stations
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	var ps := auth.add_player(auth.local_peer_id(), me)  # gets a stone pickaxe (equipped)
	auth._ev_place_station(1, "workbench", Vector3(2, 0, 0), 0.0)
	var pick := Inventory.equip_index("pickaxe")
	ps.inventory.add("stone", 10)
	ps.inventory.add("crystal_blue", 3)
	check_eq(auth.request_upgrade(1, pick, 1), "Needs Workbench level 2.", "a plain Workbench can't upgrade yet")
	auth._ev_place_station(2, "chopping_block", Vector3(3, 0, 1), 0.0)
	check_eq(auth.request_upgrade(1, pick, 1), "", "with a Chopping Block it can")
	check_eq(Upgrades.level(ps.inventory.get_slot(pick)), 1, "the pickaxe is +1")
	check_eq(ps.inventory.count_of("stone"), 8, "2 stone used")
	check_eq(ps.inventory.count_of("crystal_blue"), 2, "1 crystal used")
	check_near(Upgrades.bonus(ps.inventory.get_slot(pick)), 0.15, 0.001, "+15% dig power")
	check_eq(auth.request_upgrade(1, pick, 1), "Needs Workbench level 3.", "+2 needs level 3")
	root.queue_free()


func test_upgraded_armor_and_weapons_are_stronger() -> void:
	var ps := GameAuthority.PlayerState.new()
	ps.inventory.add("tunic_leather", 1)
	var plain := ps.armor_cut()
	ps.inventory.slots[Inventory.equip_index("chest")]["up"] = 3
	check_near(ps.armor_cut(), plain * 1.45, 0.001, "a +3 tunic soaks up 45% more")
	var base := Combat.damage("sword", false, 1, {armor = 0}, 0)
	var up3 := Combat.damage("sword", false, 1, {armor = 0}, 0, 1.0, 0.0, 0.45)
	check(up3 > base, "a +3 sword hits harder (%d vs %d)" % [up3, base])


func test_upgrade_level_is_saved() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.add("pickaxe_stone", 1)
	inv.slots[Inventory.equip_index("pickaxe")]["up"] = 2
	var copy := Inventory.new(Inventory.PLAYER_SIZE)
	copy.load_data(inv.to_data())
	check_eq(Upgrades.level(copy.get_slot(Inventory.equip_index("pickaxe"))), 2, "+2 survives saving/sending")
