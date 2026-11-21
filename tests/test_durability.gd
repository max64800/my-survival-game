extends TestCase


func test_wear_numbers() -> void:
	var s := {id = "pickaxe_stone", count = 1}
	check_eq(Durability.max_uses("pickaxe_stone"), 150, "stone tools last 150 uses")
	check_eq(Durability.max_uses("axe_copper"), 300, "copper 300")
	check(not Durability.wears("stone"), "rocks don't wear")
	check(not Durability.wears("tunic_leather"), "clothes don't wear (yet)")
	check(not Durability.needs_repair(s), "a new pickaxe needs no repair")
	var said := []
	for i in 150:
		var w := Durability.wear(s)
		if w != "":
			said.append(w)
	check_eq(said, ["warn", "broke"], "it warns at 10% left, then breaks")
	check(Durability.broken(s), "broken after 150 uses")
	check_eq(Durability.wear(s), "", "a broken tool doesn't wear further")
	check(Durability.needs_repair(s), "a broken pickaxe needs a repair")
	var copy := Inventory.new(Inventory.PLAYER_SIZE)
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.add("axe_stone", 1)
	inv.slots[inv.best_of_kind("axe")]["used"] = 40
	copy.load_data(inv.to_data())
	check_eq(Durability.used(copy.get_slot(copy.best_of_kind("axe"))), 40, "wear survives saving and sending")


func test_broken_tools_do_nothing_and_repair_at_the_bench() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations := Node3D.new()
	root.add_child(stations)
	var auth := GameAuthority.new()
	auth.stations_root = stations
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	var ps := auth.add_player(auth.local_peer_id(), me)
	ps.inventory.slots[0] = {id = "axe_stone", count = 1, used = 150}
	ps.selected_slot = 0
	check_eq(ps.selected_item(), "", "a broken axe in hand works like empty hands")
	auth._ev_place_station(1, "workbench", Vector3(2, 0, 0), 0.0)
	check_eq(auth.request_repair(1, 0, 1), "", "repaired at the Workbench with an empty bag (F568: repairs are free)")
	check_eq(ps.inventory.count_of("stone"), 0, "nothing was used")
	check_eq(ps.selected_item(), "axe_stone", "and it works again")
	check_eq(auth.request_repair(1, 0, 1), "It's like new.", "nothing left to fix")
	ps.inventory.slots[0]["used"] = 75
	ps.progress.perks["quick_fix"] = 1
	auth.request_ability(1, "quick_fix")
	check_eq(Durability.used(ps.inventory.get_slot(0)), 0, "Quick Fix repairs what's in your hand for free")
	for i in 10:
		auth.wear_slot(ps, 0)
	check_eq(Durability.used(ps.inventory.get_slot(0)), 10, "each use wears it once")
	root.queue_free()


## F568 (owner, Nov 21: "a menu to upgrade and repair gear; repairing should cost nothing, like Valheim").
func test_repair_all_is_free_and_only_fixes_what_the_station_fixes() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations := Node3D.new()
	root.add_child(stations)
	var auth := GameAuthority.new()
	auth.stations_root = stations
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	var ps := auth.add_player(auth.local_peer_id(), me)
	ps.inventory.slots[0] = {id = "axe_stone", count = 1, used = 150}
	ps.inventory.slots[1] = {id = "pickaxe_stone", count = 1, used = 30}
	ps.inventory.slots[2] = {id = "sword_copper", count = 1, used = 100}  # copper: the Anvil fixes it, not the Workbench
	auth._ev_place_station(1, "workbench", Vector3(2, 0, 0), 0.0)
	check_eq(CraftPanel.repairable_here(ps.inventory, "workbench"), 2, "the panel counts 2 things to fix here")
	check_eq(auth.request_repair_all(1, 1), 2, "Repair all fixes both stone tools")
	check_eq(Durability.used(ps.inventory.get_slot(0)) + Durability.used(ps.inventory.get_slot(1)), 0, "both like new, for nothing")
	check_eq(Durability.used(ps.inventory.get_slot(2)), 100, "the copper sword waits for an Anvil")
	check_eq(auth.request_repair_all(1, 1), 0, "nothing left to fix")
	me.position = Vector3(30, 0, 0)
	ps.inventory.slots[0]["used"] = 5
	check_eq(auth.request_repair_all(1, 1), 0, "too far from the bench: nothing happens")
	root.queue_free()


## Thrifty: repairs are free now, so the perk makes gear last longer instead (owner's pick, Nov 21).
func test_thrifty_makes_gear_wear_slower() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	var ps := auth.add_player(auth.local_peer_id(), me)
	ps.inventory.slots[0] = {id = "axe_stone", count = 1}
	ps.progress.perks["thrifty"] = 3
	for i in 100:
		auth.wear_slot(ps, 0)
	var used := Durability.used(ps.inventory.get_slot(0))
	check(used >= 69 and used <= 71, "Thrifty 3: 100 uses wear it only ~70 times (got %d)" % used)
	root.queue_free()
