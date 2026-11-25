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
	var full := Items.stack_size("stone")  # (50 since F793)
	check_eq(inv.add("stone", 12 * full + 100), 100, "12 stacks fit, 100 left over")


func test_chest_place_fill_and_empty() -> void:
	await _setup()
	ps.inventory.add("chest_small", 1)
	ps.inventory.add("stone", 50)
	auth.request_select_slot(1, first_item_slot(ps))  # the chest (the start pickaxe is in the hotbar, F243)
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


## F886 (owner, Nov 25): drag a stack onto the slot you choose, in the chest or in your bag.
func test_drag_to_a_chosen_slot() -> void:
	await _setup()
	var st := auth.storage
	var id := st.create_box("chest_small", player.global_position + Vector3(1.5, 0, 0), 0.0)
	var bag := ps.inventory
	var b0 := Inventory.HOTBAR_SIZE + 3  # a bag slot
	bag.slots[b0] = {id = "stone", count = 20}
	check(st.request_place(1, id, false, b0, true, 5), "bag -> chest slot 5")
	check_eq(st.get_box(id).inv.slots[5].get("count", 0), 20, "the stones are in slot 5")
	check(bag.slots[b0].is_empty(), "gone from the bag")
	check(st.request_place(1, id, true, 5, true, 9), "chest slot 5 -> chest slot 9")
	check(st.get_box(id).inv.slots[5].is_empty() and st.get_box(id).inv.slots[9].get("id", "") == "stone", "moved inside the chest")
	bag.slots[b0] = {id = "stone", count = 10}
	check(st.request_place(1, id, false, b0, true, 9), "the same kind tops up")
	check_eq(st.get_box(id).inv.slots[9].get("count", 0), 30, "30 stones in slot 9")
	bag.slots[b0 + 1] = {id = "copper_ore", count = 4}
	check(st.request_place(1, id, true, 9, false, b0 + 1), "chest -> a bag slot with something else: they swap")
	check_eq(bag.slots[b0 + 1].get("id", ""), "stone", "stones in that bag slot")
	check_eq(st.get_box(id).inv.slots[9].get("id", ""), "copper_ore", "the ore went into the chest")
	var bid := st.create_box("builder", player.global_position + Vector3(-1.5, 0, 0), 0.0)
	bag.slots[b0 + 2] = {id = "dish_jungle_pie", count = 1}
	check(not st.request_place(1, bid, false, b0 + 2, true, 0), "a Builder's Chest still won't take a pie")
	var far := st.create_box("chest_small", player.global_position + Vector3(20, 0, 0), 0.0)
	check(not st.request_place(1, far, false, b0 + 2, true, 0), "not from 20 m away")
	_teardown()


## F888 (owner, Nov 25): crafting takes what the bag is short of from the chests and barrels nearby; never from a
## chest that's far away, a grave or a Builder's Chest, and nothing moves if it still can't be made.
func test_crafting_takes_from_nearby_chests() -> void:
	await _setup()
	var st := auth.storage
	var bag := ps.inventory
	bag.remove("stone", bag.count_of("stone"))
	bag.remove("rootwood", bag.count_of("rootwood"))
	bag.add("stone", 2)
	var far := st.create_box("chest_small", player.global_position + Vector3(20, 0, 0), 0.0)
	st.put(far, "rootwood", 50)
	var builder := st.create_box("builder", player.global_position + Vector3(0, 0, 2), 0.0)
	st.put(builder, "stone", 50)
	check(not auth.request_craft(1, "campfire"), "a far chest and a Builder's Chest don't count")
	check_eq(st.get_box(builder).inv.count_of("stone"), 50, "the Builder's Chest kept its stone")
	var near := st.create_box("chest_small", player.global_position + Vector3(2, 0, 0), 0.0)
	var keg := st.create_box("barrel", player.global_position + Vector3(-2, 0, 0), 0.0)
	st.put(near, "stone", 2)
	st.put(keg, "rootwood", 7)
	check(not auth.request_craft(1, "campfire"), "still 1 stone short: no campfire")
	check_eq(st.get_box(near).inv.count_of("stone"), 2, "and nothing was taken")
	check_eq(CraftPanel.can_make_count("campfire", st.craft_stock(bag, player.global_position)), 0, "the list says it can't be made")
	st.put(near, "stone", 3)
	check_eq(CraftPanel.can_make_count("campfire", st.craft_stock(bag, player.global_position)), 1, "the list counts the chests")
	check(auth.request_craft(1, "campfire"), "bag + chest + barrel: a campfire")
	check_eq(bag.count_of("campfire"), 1, "the campfire is in the bag")
	check_eq(bag.count_of("stone"), 0, "the bag's 2 stones were used first")
	check_eq(st.get_box(near).inv.count_of("stone"), 2, "3 stones came from the chest")
	check_eq(st.get_box(keg).inv.count_of("rootwood"), 4, "3 rootwood came from the barrel")
	check_eq(st.get_box(far).inv.count_of("rootwood"), 50, "the far chest wasn't touched")
	_teardown()


## F889 (owner, Nov 25): "Store same" puts in only the kinds already in the box, from the bag, not the hotbar.
func test_store_same() -> void:
	await _setup()
	var st := auth.storage
	var bag := ps.inventory
	var id := st.create_box("barrel", player.global_position + Vector3(1.5, 0, 0), 0.0)
	st.put(id, "stone", 1)
	var b := Inventory.HOTBAR_SIZE
	bag.slots[b] = {id = "stone", count = 30}
	bag.slots[b + 1] = {id = "copper_ore", count = 5}
	bag.slots[b + 2] = {id = "stone", count = 7}
	bag.slots[2] = {id = "stone", count = 4}  # in the hotbar: stays
	check_eq(st.request_store_same(1, id), 37, "37 stones went in")
	check_eq(st.get_box(id).inv.count_of("stone"), 38, "the barrel has 38")
	check_eq(bag.count_of("copper_ore"), 5, "the ore stayed in the bag")
	check_eq(bag.get_slot(2).get("count", 0), 4, "the hotbar's stones stayed")
	var far := st.create_box("barrel", player.global_position + Vector3(20, 0, 0), 0.0)
	st.put(far, "copper_ore", 1)
	check_eq(st.request_store_same(1, far), 0, "not from 20 m away")
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


## Owner (Nov 18): take everything out of a chest and its menu closes by itself; an empty chest you open to fill
## stays open.
func test_box_menu_closes_when_emptied() -> void:
	await _setup()
	var spot := world.maker.find_floor(player.global_position.x + 1.5, player.global_position.z, player.global_position.y + 1.0)
	var id := auth.storage.create_box("chest_small", spot, 0.0)
	var panel := BoxPanel.new()
	tree.root.add_child(panel)
	var closed := [0]
	panel.emptied.connect(func() -> void: closed[0] += 1)
	panel.open(id)  # empty: opened to fill it
	panel.refresh()
	await tree.process_frame
	check_eq(closed[0], 0, "an empty chest you open stays open")
	auth.storage.put(id, "stone", 5)
	panel.open(id)
	auth.storage.request_take_all(1, id)
	panel.refresh()
	await tree.process_frame
	check_eq(closed[0], 1, "take all: the menu closes")
	panel.queue_free()
	_teardown()


## F886: a real mouse drag in the chest menu moves the stack to the slot you let go on; a plain click still takes it.
func test_drag_in_the_chest_menu() -> void:
	await _setup()
	var spot := world.maker.find_floor(player.global_position.x + 1.5, player.global_position.z, player.global_position.y + 1.0)
	var id := auth.storage.create_box("chest_small", spot, 0.0)
	auth.storage.put(id, "stone", 5)
	var was_size := tree.root.size
	tree.root.size = Vector2i(1280, 800)  # (the test window is tiny: the slots must be inside it)
	var panel := BoxPanel.new()
	tree.root.add_child(panel)
	panel.open(id)
	panel.refresh()
	await tree.process_frame
	await tree.process_frame
	var g: GridContainer = panel._grid
	var from: Vector2 = (g.get_child(0) as Control).get_global_rect().get_center()
	var to: Vector2 = (g.get_child(3) as Control).get_global_rect().get_center()
	await _mouse(MOUSE_BUTTON_LEFT, true, from)
	for k in 6:
		await _move(from.lerp(to, (k + 1) / 6.0))
	await _mouse(MOUSE_BUTTON_LEFT, false, to)
	var inv: Inventory = auth.storage.get_box(id).inv
	check(inv.slots[0].is_empty() and inv.slots[3].get("count", 0) == 5, "dragged from slot 1 to slot 4 (%s)" % str(inv.slots.slice(0, 4)))
	check_eq(ps.inventory.count_of("stone"), 0, "a drag doesn't also take it into the bag")
	await _mouse(MOUSE_BUTTON_LEFT, true, to)
	await _mouse(MOUSE_BUTTON_LEFT, false, to)
	check_eq(ps.inventory.count_of("stone"), 5, "a click takes it")
	panel.queue_free()
	tree.root.size = was_size
	_teardown()


func _mouse(button: MouseButton, down: bool, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = down
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	tree.root.push_input(e)
	await tree.process_frame


func _move(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.relative = Vector2(8, 0)
	tree.root.push_input(e)
	await tree.process_frame


## F345 (owner): the chest's lid swings open on its hinge when you open it, and shuts when the menu closes.
## A box without a lid (the stone chest) still opens fine.
func test_chest_lid_swings_open_and_shut() -> void:
	await _setup()
	var spot := world.maker.find_floor(player.global_position.x + 1.5, player.global_position.z, player.global_position.y + 1.0)
	for kind in ["chest_small", "chest_copper", "chest_stone"]:
		var id := auth.storage.create_box(kind, spot, 0.0)
		var node: Node3D = auth.storage.get_box(id).node
		var lid := ChestOpen.lid_of(node)
		check(lid != null, "%s has its own lid part" % kind)
		if lid == null:
			continue
		var hinge_z := lid.global_position.z - node.global_position.z
		var panel := BoxPanel.new()
		tree.root.add_child(panel)
		ChestOpen.open(node)
		panel.open(id)
		for i in 30:
			await tree.process_frame
		check(lid.rotation.x < -1.5, "%s: the lid swung up (%.2f rad)" % [kind, lid.rotation.x])
		check(absf(hinge_z) > 0.2, "%s: the hinge is on an edge, not the middle (%.2f m)" % [kind, hinge_z])
		panel.visible = false
		for i in 30:
			await tree.process_frame
		check(absf(lid.rotation.x) < 0.01, "%s: menu closed, the lid shut (%.2f rad)" % [kind, lid.rotation.x])
		panel.queue_free()
	# A barrel's lid lifts and slides aside, then comes back (owner, Nov 19). (Only once loot barrels exist.)
	var blid: Node3D = null
	var bnode: Node3D = null
	if Storage.SIZES.has("barrel"):
		var bid := auth.storage.create_box("barrel", spot + Vector3(-2, 0, 0), 0.0)
		bnode = auth.storage.get_box(bid).node
		blid = ChestOpen.lid_of(bnode)
		check(blid != null, "the barrel has its own lid part")
	if blid:
		var home := blid.position
		ChestOpen.open(bnode)
		await tree.create_timer(0.6).timeout
		check(absf(blid.position.x - home.x) > 0.2 and is_zero_approx(blid.rotation.x), "the barrel lid slid aside (not swung)")
		ChestOpen.close(bnode)
		await tree.create_timer(0.6).timeout
		check(blid.position.distance_to(home) < 0.01, "the barrel lid is back on")
	var sid := auth.storage.create_box("crate_ore", spot + Vector3(2, 0, 0), 0.0)
	ChestOpen.open(auth.storage.get_box(sid).node)  # (an ore crate has no lid: just a pop, no error)
	_teardown()


## F8 item menu tabs (owner, Nov 24, F842).
func test_dev_item_menu_tabs() -> void:
	var untabbed := []
	for id in Items.ids():
		var t := DevItems.tabs_of(id)
		if t.size() < 2 or not t.has("All"):
			untabbed.append(id)
	check(untabbed.is_empty(), "every item is in a tab (%s)" % str(untabbed))
	check(DevItems.all_ids("", "Food").has("root_tuber"), "a food is under Food")
	check(DevItems.all_ids("", "Drinks").has("water_bucket"), "a drink is under Drinks")
	check(not DevItems.all_ids("", "Food").has("water_bucket"), "a drink is not under Food")
	check(DevItems.all_ids("", "Equipment").has("pickaxe_stone"), "a pickaxe is under Equipment")
	check(DevItems.all_ids("", "Farmable").has("tuber_seed"), "a seed is under Farmable")
	check(DevItems.all_ids("", "Craftable").has("pickaxe_stone"), "a made thing is under Craftable")
	check(DevItems.all_ids("tuber", "Food").has("root_tuber"), "search finds it inside its tab")
	check(not DevItems.all_ids("tuber", "Drinks").has("root_tuber"), "and not inside another tab")
	check(DevItems.all_ids("tuber").has("root_tuber"), "and in All")
	for t in DevItems.TABS:
		check(DevItems.all_ids("", t).size() > 0, "tab %s has items" % t)


## F8 item menu (owner, Nov 19): every item is listed, search works, a click puts it straight into your bag.
func test_dev_item_menu_gives_items() -> void:
	await _setup()
	check(DevItems.all_ids().size() > 50, "lots of items listed (%d)" % DevItems.all_ids().size())
	check(DevItems.all_ids("bolt").has("bolt_stone"), "search finds the stone bolt")
	check(not DevItems.all_ids("bolt").has("pickaxe_stone"), "and leaves other things out")
	var before: int = ps.inventory.count_of("bolt_stone")
	DevItems.give("bolt_stone", 5)
	check_eq(ps.inventory.count_of("bolt_stone"), before + 5, "5 bolts straight into the bag")
	DevItems.give("crossbow_stone", 1)
	check_eq(ps.inventory.count_of("crossbow_stone"), 1, "and a crossbow")
	var menu := DevItems.new()
	tree.root.add_child(menu)
	await tree.process_frame
	check(menu._grid.get_child_count() > 50, "the menu shows a button for every item")
	# Scrolling over a picture gives nothing; only a click does (owner, Nov 19: items came just from hovering).
	menu._search.text = "bolt_stone"
	menu.refresh()
	await tree.process_frame
	var btn: Button = null
	for c in menu._grid.get_children():
		if not c.is_queued_for_deletion() and (c as Button).tooltip_text == Items.display_name("bolt_stone"):
			btn = c
	check(btn != null, "the stone bolt's button")
	if btn:
		var n0: int = ps.inventory.count_of("bolt_stone")
		for wheel in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			var ev := InputEventMouseButton.new()
			ev.button_index = wheel
			ev.pressed = true
			btn.gui_input.emit(ev)
		check_eq(ps.inventory.count_of("bolt_stone"), n0, "scrolling over it gives nothing")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		btn.gui_input.emit(click)
		check_eq(ps.inventory.count_of("bolt_stone"), n0 + 1, "a click gives one")
	menu.queue_free()
	_teardown()
