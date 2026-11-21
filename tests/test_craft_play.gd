extends TestCase
## The owner's crafting notes from the tower-rebuild play (Nov 21): F561 (a free shield), F555 (craft many at once).

var world: World
var auth: GameAuthority
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	auth.stations_root = Node3D.new()
	root.add_child(auth.drops_root)
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	me.global_position = world.maker.cavern_spawn
	auth.add_player(1, me)
	ps = auth.players[1]
	auth._ev_place_station(7, "workbench", me.global_position + Vector3(1.5, 0, 0), 0.0)


## F561 (owner: "I crafted a wooden shield without having the resources on me").
func test_no_free_shield() -> void:
	await _setup()
	check(not auth.request_craft(1, "shield_stone", 7), "an empty bag makes no shield")
	check_eq(ps.inventory.count_of("shield_stone"), 0, "no shield appeared")
	ps.inventory.add("plank_root", 5)
	ps.inventory.add("rope", 2)
	check(not auth.request_craft(1, "shield_stone", 7), "one plank short: no shield")
	check_eq(ps.inventory.count_of("plank_root"), 5, "and nothing was taken")
	ps.inventory.add("plank_root", 1)
	var said := []
	auth.hud_message.connect(func(t): said.append(t))
	check(auth.request_craft(1, "shield_stone", 7), "6 planks + 2 rope make a shield")
	check_eq(ps.inventory.count_of("plank_root") + ps.inventory.count_of("rope"), 0, "and they were used up")
	check(said.any(func(t): return "Made a Wooden Shield from 6" in t), "it says what it used: %s (F561)" % [said])
	auth.get_parent().queue_free()


## F555 🔁 (owner: "I'm crafting 1 by 1, it takes so long"): one bar for the whole amount, all made together.
func test_craft_the_whole_amount_in_one_go() -> void:
	await _setup()
	check_near(CraftPanel.batch_time(1.0, 1), 1.0, 0.01, "one plank: the normal time")
	check_near(CraftPanel.batch_time(1.0, 10), 4.0, 0.01, "ten: 4 s, not 10 × 1 s")
	check_near(CraftPanel.batch_time(2.0, 99), CraftPanel.BATCH_MAX_SECONDS, 0.01, "never longer than 8 s")
	check_near(CraftPanel.batch_time(1.0, 10, true), 1.0, 0.01, "Crafting ★75: no extra wait")
	ps.inventory.add("rootwood", 12)
	var panel := CraftPanel.new()
	panel.peer_id = 1
	auth.get_parent().add_child(panel)
	panel.open_for(auth.stations[7])
	panel.visible = true
	panel.amount = 10
	panel.start_making("plank_root")
	check_eq(panel._making.get("count", 0), 10, "the Craft button takes the chosen amount (10)")
	var made_at := -1.0
	var t := 0.0
	while t < 12.0 and made_at < 0.0:
		panel._process(0.1)
		t += 0.1
		if not panel._making.is_empty():
			continue
		made_at = t
	check(made_at > 0.0 and made_at < 4.5, "the whole batch finished in one bar (%.1f s)" % made_at)
	check_eq(ps.inventory.count_of("plank_root"), 20, "all 10 made at once: 20 planks")
	check_eq(ps.inventory.count_of("rootwood"), 2, "10 rootwood used, 2 left")
	panel.amount = 50
	panel.start_making("plank_root")
	check_eq(panel._making.get("count", 0), 2, "asking for more than you can make: only what the bag allows")
	auth.get_parent().queue_free()
