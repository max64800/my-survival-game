extends TestCase


func test_wear_numbers() -> void:
	var s := {id = "pickaxe_stone", count = 1}
	check_eq(Durability.max_uses("pickaxe_stone"), 150, "stone tools last 150 uses")
	check_eq(Durability.max_uses("axe_copper"), 300, "copper 300")
	check(not Durability.wears("stone"), "rocks don't wear")
	check(not Durability.wears("tunic_leather"), "clothes don't wear (yet)")
	check(Durability.repair_cost(s).is_empty(), "a new pickaxe needs no repair")
	var said := []
	for i in 150:
		var w := Durability.wear(s)
		if w != "":
			said.append(w)
	check_eq(said, ["warn", "broke"], "it warns at 10% left, then breaks")
	check(Durability.broken(s), "broken after 150 uses")
	check_eq(Durability.wear(s), "", "a broken tool doesn't wear further")
	check_eq(Durability.repair_cost(s), {stone = 2}, "fixing a broken stone pickaxe: half its 3 stone, rounded up")
	check_eq(Durability.repair_cost({id = "sword_copper", count = 1, used = 150}), {copper_ingot = 8}, "a half-worn copper sword: 30 bars x 0.5 x 0.5, rounded up")
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
	check_eq(auth.request_repair(1, 0, 1), "Needs 2 Stone.", "a repair costs material")
	ps.inventory.add("stone", 5)
	check_eq(auth.request_repair(1, 0, 1), "", "repaired at the Workbench")
	check_eq(ps.inventory.count_of("stone"), 3, "2 stone used")
	check_eq(ps.selected_item(), "axe_stone", "and it works again")
	check_eq(auth.request_repair(1, 0, 1), "It's like new.", "nothing left to fix")
	ps.inventory.slots[0]["used"] = 75
	ps.progress.perks["thrifty"] = 3
	check_eq(Durability.repair_cost(ps.inventory.get_slot(0), GameAuthority.repair_discount(ps.progress)), {stone = 1}, "Thrifty 3: 30% off, never below 1")
	ps.progress.perks["quick_fix"] = 1
	auth.request_ability(1, "quick_fix")
	check_eq(Durability.used(ps.inventory.get_slot(0)), 0, "Quick Fix repairs what's in your hand for free")
	for i in 10:
		auth.wear_slot(ps, 0)
	check_eq(Durability.used(ps.inventory.get_slot(0)), 10, "each use wears it once")
	root.queue_free()
