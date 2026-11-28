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
	auth._ev_place_station(8, "armoury_bench", me.global_position + Vector3(-1.5, 0, 0), 0.0)  # shields are made here (F894)


## F561 (owner: "I crafted a wooden shield without having the resources on me").
func test_no_free_shield() -> void:
	await _setup()
	check(not auth.request_craft(1, "shield_stone", 8), "an empty bag makes no shield")
	check_eq(ps.inventory.count_of("shield_stone"), 0, "no shield appeared")
	ps.inventory.add("plank_root", 5)
	ps.inventory.add("rope", 2)
	check(not auth.request_craft(1, "shield_stone", 8), "one plank short: no shield")
	check_eq(ps.inventory.count_of("plank_root"), 5, "and nothing was taken")
	ps.inventory.add("plank_root", 1)
	var said := []
	auth.hud_message.connect(func(t): said.append(t))
	check(auth.request_craft(1, "shield_stone", 8), "6 planks + 2 rope make a shield")
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
	check_eq(panel.amount, 1, "F920: after the batch the amount is back to ×1")
	panel.amount = 5
	panel._picked = "plank_root"
	panel._amount_for = "plank_root"
	panel._picked = "torch"
	panel.refresh()
	check_eq(panel.amount, 1, "F920: picking something else starts at ×1 again")
	check(not panel._amount_slider.scrollable, "F920: the mouse wheel never moves the amount")
	panel.amount = 50
	panel.start_making("plank_root")
	check_eq(panel._making.get("count", 0), 2, "asking for more than you can make: only what the bag allows")
	auth.get_parent().queue_free()


## Owner, Nov 22: the "Upgrade and repair gear" panel stayed on screen alone and couldn't be closed. A craft that ended
## (or was stopped) after the bench window closed redrew the window and turned the panel back on.
func test_upgrade_panel_never_shows_without_the_bench_window() -> void:
	await _setup()
	ps.inventory.add("rootwood", 4)
	var panel := CraftPanel.new()
	panel.peer_id = 1
	auth.get_parent().add_child(panel)
	var up := panel.make_upgrade_panel()
	auth.get_parent().add_child(up)
	panel.open_for(auth.stations[7])
	check(up.visible, "at a Workbench the upgrade panel shows beside it")
	panel.start_making("plank_root")
	panel.visible = false
	check(not up.visible, "closing the bench window hides it")
	panel.cancel_making("Stopped")
	check(not up.visible, "a craft stopped after closing doesn't bring it back")
	panel.refresh()
	check(not up.visible, "nor does any later redraw")
	auth.get_parent().queue_free()


## Owner, Nov 22: "crafted shield with no planks but with wood ... we need to highlight that it will be created
## from wood --> planks and then the shield, otherwise looks like a bug". The bench says it makes planks first.
func test_bench_says_it_makes_planks_from_wood_first() -> void:
	await _setup()
	ps.inventory.add("rootwood", 3)
	ps.inventory.add("rope", 2)
	var panel := CraftPanel.new()
	panel.peer_id = 1
	auth.get_parent().add_child(panel)
	panel.open_for(auth.stations[7])
	var lines := panel.chain_lines("barrel", ps.inventory)
	check_eq(lines, ["First makes 6 %s from 3 %s" % [Items.display_name("plank_root"), Items.display_name("rootwood")]],
		"no planks, 3 rootwood: it says it turns them into 6 planks first")
	ps.inventory.add("plank_root", 6)
	check(panel.chain_lines("barrel", ps.inventory).is_empty(), "with the planks already in the bag: no extra line")
	auth.get_parent().queue_free()


## F629 (owner, Nov 22): 10 ropes finished at once played 10 identical sounds at the same moment. Now one sound, plus
## at most two more a little later, at different moments.
func test_a_batch_finishes_with_one_sound_and_a_few_spread_out() -> void:
	var auth := GameAuthority.new()
	var delays := []
	for i in 10:
		delays.append(auth.craft_sound_delay(100.0))
	check_eq(delays[0], 0.0, "the first craft rings right away")
	var later := delays.filter(func(d): return d > 0.0)
	check_eq(later.size(), GameAuthority.CRAFT_SFX_EXTRA, "only %d more follow" % GameAuthority.CRAFT_SFX_EXTRA)
	check(later.size() < 2 or absf(later[0] - later[1]) > 0.1, "and not at the same moment")
	check_eq(delays.filter(func(d): return d < 0.0).size(), 10 - 1 - GameAuthority.CRAFT_SFX_EXTRA, "the rest are quiet")
	check_eq(auth.craft_sound_delay(105.0), 0.0, "the next batch later rings again")
	auth.free()


## F882 (owner, Nov 25): stone gear said "needs station level 2" at the repair bench; only copper gear should.
func test_stone_gear_upgrades_at_a_plain_workbench() -> void:
	await _setup()
	var panel := CraftPanel.new()
	panel.peer_id = 1
	auth.get_parent().add_child(panel)
	var up := panel.make_upgrade_panel()
	auth.get_parent().add_child(up)
	panel.open_for(auth.stations[7])
	var texts := []
	for n in up.find_children("*", "Label", true, false):  # (F918: plain labels on picture cards now)
		texts.append((n as Label).text)
	var pick := " ".join(texts)
	check(pick.contains("Pickaxe"), "the stone pickaxe is listed (%s)" % pick)
	var card := up.find_child("UpgradeCard", true, false)
	check(card != null and (card.find_child("Pic", true, false) as TextureRect).texture != null, "F918: its card shows its picture")
	check(card != null and card.find_child("Upgrade", true, false) is Button, "F918: and an Upgrade button")
	check(not pick.contains("must be level"), "and needs no higher station level")
	auth.get_parent().queue_free()


## F935 (owner, Nov 27): you couldn't tell which stations are upgrades of another and which are their own.
func test_station_cards_say_upgrade_or_own_station() -> void:
	check(CraftPanel.station_role("cooking_pot").begins_with("Upgrade for the Campfire"), "the pot is a campfire upgrade")
	check(CraftPanel.station_role("tool_rack").begins_with("Upgrade for the Workbench"), "the tool rack is a workbench upgrade")
	check(CraftPanel.station_role("kiln").begins_with("Its own station"), "the Charcoal Kiln is its own station")
	check(CraftPanel.station_role("workbench").contains("Tool Rack"), "the workbench names its upgrades")
	check_eq(CraftPanel.station_role("stone"), "", "stone is no station")


## F949 (owner, Nov 28): at the workbench, Materials -> Stations often stretched the whole menu, with a big empty
## space at the bottom right. The station's "what it does" line wraps; the menu must end up exactly as big as it shows.
func test_stations_tab_does_not_stretch_the_menu() -> void:
	await _setup()
	for id in Recipes.LIST:
		var u = Recipes.LIST[id].unlock
		if u is Array:
			for item in u:
				ps.seen[str(item).trim_suffix("*")] = true
	var panel := CraftPanel.new()
	panel.peer_id = 1
	auth.get_parent().add_child(panel)
	panel.open_for(auth.stations[7])
	for tab in ["Materials", "Stations", "Materials", "Stations"]:
		panel._tab = tab
		panel._picked = ""
		panel.refresh()
		for i in 4:
			await tree.process_frame
		check_eq(panel._tab, tab, "the %s tab is open" % tab)
		var want := panel.get_combined_minimum_size()
		check(panel.size.y <= want.y + 1.0 and panel.size.x <= want.x + 1.0,
			"%s: the menu is as big as what it shows (%s, needs %s)" % [tab, panel.size, want])
	auth.get_parent().queue_free()
