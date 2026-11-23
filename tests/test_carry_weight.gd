extends TestCase
## Carry weight (F793): docs/decisions/2026-11-23-carry-weight.md


func test_every_item_has_a_real_weight() -> void:
	var missing := []
	for id in Items._data():
		if ItemWeights.is_unsorted(id):
			missing.append(id)
	check_eq(missing, [], "every item is in a weight group (add new items to ItemWeights)")


func test_owner_weight_table() -> void:
	check_eq(ItemWeights.weight("stone"), 1.0, "stone = 1")
	check_eq(ItemWeights.weight("copper_ore"), 1.5, "ore 1.5")
	check_eq(ItemWeights.weight("copper_ingot"), 2.0, "bars 2")
	check_eq(ItemWeights.weight("fiber"), 0.1, "fiber 0.1")
	check_eq(ItemWeights.weight("glowcap"), 0.2, "food 0.2")
	check_eq(ItemWeights.weight("sword_copper"), 5.0, "weapons 5")
	check_eq(ItemWeights.weight("axe_2h_copper"), 8.0, "two-handed 8")
	check_eq(ItemWeights.weight("recipe_page"), 0.0, "pages weigh nothing")
	check(ItemWeights.weight("workbench") >= 8.0, "stations are chunky")


func test_stack_sizes_by_kind() -> void:
	check_eq(Items.stack_size("stone"), 50, "stone stacks 50")
	check_eq(Items.stack_size("copper_ingot"), 30, "bars 30")
	check_eq(Items.stack_size("glowcap"), 20, "food 20")
	check_eq(Items.stack_size("bolt_fang"), 100, "ammo 100")
	check_eq(Items.stack_size("gold_coin"), 100, "coins keep their own 100")
	check_eq(Items.stack_size("pickaxe_stone"), 1, "tools 1")


func test_total_counts_worn_gear_half() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	inv.add("stone", 40)
	check_eq(ItemWeights.total(inv), 40.0, "40 stone = 40")
	inv.slots[Inventory.equip_index("chest")] = {id = "mail_copper", count = 1}
	check_eq(ItemWeights.total(inv), 44.0, "worn copper mail (8) counts as 4")


func test_slowdown_two_steps() -> void:
	var lim := Vector2(ItemWeights.HEAVY, ItemWeights.MAX)
	check_eq(ItemWeights.speed_mult(150.0, lim), 1.0, "light: full speed")
	check_eq(ItemWeights.load_of(150.0, lim), ItemWeights.Load.LIGHT, "light")
	var mid := ItemWeights.speed_mult(250.0, lim)
	check(mid < 1.0 and mid > ItemWeights.HEAVY_SLOWEST, "heavy: a bit slower (%s)" % mid)
	check_eq(ItemWeights.load_of(250.0, lim), ItemWeights.Load.HEAVY, "heavy")
	check_eq(ItemWeights.speed_mult(301.0, lim), ItemWeights.OVERLOADED_SPEED, "overloaded: slow plod")
	check_eq(ItemWeights.load_of(301.0, lim), ItemWeights.Load.OVERLOADED, "overloaded")


func test_backpack_perk_and_food_raise_the_limit() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	var prog := Progression.new()
	check_eq(ItemWeights.limits(inv, prog), Vector2(200, 300), "base 200 / 300")
	inv.slots[Inventory.equip_index("pack")] = {id = "satchel", count = 1}
	check_eq(ItemWeights.limits(inv, prog), Vector2(260, 360), "satchel +60")
	prog.perks["deep_pockets"] = 2
	check_eq(ItemWeights.limits(inv, prog), Vector2(310, 410), "Deep Pockets rank 2 = +50")
	check_eq(ItemWeights.limits(inv, prog, 0.1), Vector2(341, 451), "a +10% carry food")


func test_old_big_stacks_split_on_load() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	var data := inv.to_data()
	data[0] = {id = "stone", count = 100}  # an old save from when stone stacked 100
	inv.load_data(data)
	check_eq(inv.get_slot(0).count, 50, "kept 50 in its slot")
	check_eq(inv.count_of("stone"), 100, "nothing lost")


func test_old_big_stack_stays_when_bag_is_full() -> void:
	var inv := Inventory.new(Inventory.PLAYER_SIZE)
	var data := inv.to_data()
	for i in Inventory.SIZE:
		data[i] = {id = "fiber", count = 1}
	data[0] = {id = "stone", count = 100}
	inv.load_data(data)
	check_eq(inv.count_of("stone"), 100, "no room: the big stack stays, nothing deleted")


func test_overloaded_dwarf_is_slow_and_cannot_jump_or_dodge() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := Node3D.new()
	tree.root.add_child(root)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(60, 1, 60)
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	root.add_child(floor_body)
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	auth.add_player(1, dwarf)
	for i in 20:
		await tree.physics_frame
	var light := await _walk(dwarf, 1.5)
	auth.get_player(1).inventory.add("stone", 320)  # past the 300 max
	for i in 15:  # (the load is checked 5 times a second)
		await tree.physics_frame
	check(dwarf.is_overloaded(), "320 stone = overloaded")
	var heavy := await _walk(dwarf, 1.5)
	check(heavy < light * 0.6, "overloaded walks much slower (%.2f m vs %.2f m)" % [heavy, light])
	dwarf.bot_jump = true
	var top := 0.0
	for i in 40:
		await tree.physics_frame
		top = maxf(top, dwarf.global_position.y)
	check(top < 0.3, "overloaded can't jump (rose %.2f m)" % top)
	dwarf.bot_dodge = true
	await tree.physics_frame
	check(not dwarf.fight.dodging(), "overloaded can't dodge roll")
	dwarf.bot_dodge = false  # (Controls.robot stays on: the test runner keeps it on for every test)
	root.queue_free()


func _walk(dwarf: Dwarf, seconds: float) -> float:
	var p0 := dwarf.global_position
	dwarf.bot_move = Vector2(0, -1)
	for i in int(seconds * 60):
		await tree.physics_frame
	dwarf.bot_move = Vector2.ZERO
	for i in 30:
		await tree.physics_frame
	return Vector2(dwarf.global_position.x - p0.x, dwarf.global_position.z - p0.z).length()
