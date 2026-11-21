extends TestCase
## The owner's tower-rebuild play (Nov 21, F557-F581): the Rebuilding Chest, its menu, the blue plan, the speed.

var world: World
var auth: GameAuthority


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


## Builds the ruined tower and returns its Rebuilding Chest's id (-1 if it failed).
func _tower() -> int:
	await _setup()
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var box := RuinTower.last_rebuild_box
	check(auth.storage.boxes.has(box), "the ruin has a Rebuilding Chest")
	return box if auth.storage.boxes.has(box) else -1


func _hold(item: String) -> void:
	var ps: GameAuthority.PlayerState = auth.players[1]
	if ps.inventory.count_of(item) == 0:
		ps.inventory.add(item, 1)
	ps.selected_slot = ps.inventory.slots.find_custom(func(s): return not s.is_empty() and s.id == item)


## F567 (blue only while holding the hammer) + F565 (10 FPS and freezes while rebuilding).
func test_blue_plan_only_with_the_hammer_and_no_freezes() -> void:
	var box := await _tower()
	if box < 0:
		auth.get_parent().queue_free()
		return
	var b: Builder = auth.builder
	# F557: the owner gathered all the first cave's wood: "100, maybe 120 planks". The wooden tower must cost well under.
	var r: Dictionary = auth.world_state.ruins[str(box)]
	var wood_need := b.ruin_needs(String(r.wood), r)
	var planks := int(wood_need.get("plank_root", 0))
	check(planks > 20 and planks <= 85, "the wooden tower costs %d planks (the first cave gave the owner ~110; F557)" % planks)
	print("TOWER_PRICE wood %s | stone %s" % [wood_need, b.ruin_needs(String(r.stone), r)])
	# F560: the untouched chest shows two cards of pictures, nothing else.
	var panel := BoxPanel.new()
	auth.get_parent().add_child(panel)
	panel.open(box)
	var cards := panel._ways.get_children().filter(func(c): return c is PanelContainer)
	var pics := panel._ways.find_children("*", "TextureRect", true, false)
	check(cards.size() == 2 and pics.size() >= 3, "the chest shows two picture cards (%d cards, %d pictures; F560)" % [cards.size(), pics.size()])
	check(panel._status.text.length() < 50, "one short line above them: \"%s\"" % panel._status.text)
	var t0 := Time.get_ticks_usec()
	auth.storage.put(box, "plank_root", 5)
	var start_ms := (Time.get_ticks_usec() - t0) / 1000
	check(b.sites.has(box), "planks start the rebuild")
	check(start_ms < 250, "putting the first planks in doesn't freeze the game (%d ms)" % start_ms)
	# F578: after something went in, the chest shows what still has to go in.
	var left_need := b.still_needed(box)
	check(int(left_need.get("plank_root", 0)) > 0 and int(left_need.get("plank_root", 0)) <= planks,
		"the chest knows the planks still missing (%s; F578)" % [left_need])
	panel.refresh()
	check(panel._ways.visible and "Still to put in" in str(panel._ways.find_children("*", "Label", true, false).map(func(l): return l.text)),
		"opening the chest shows the pictures of what's still missing (F578)")
	panel.queue_free()
	_hold("stone")
	await tree.process_frame
	var site: Dictionary = b.sites[box]
	check(not (site.ghosts as Node3D).visible, "no blue pieces without the hammer (F567)")
	_hold("build_hammer")
	await tree.process_frame
	check((site.ghosts as Node3D).visible, "the blue plan shows with the hammer")
	var steps := Builder.site_steps(site.plan)
	var shown := 0
	var wrong := 0
	for i in site.plan.size():
		var p: Dictionary = site.plan[i]
		if (p.ghost as Node3D).visible:
			shown += 1
			if p.built or steps.band_of[i] != steps.current:
				wrong += 1
	check(shown > 0 and wrong == 0, "only the floor being built shows blue (%d shown, %d wrong; F565)" % [shown, wrong])
	var todo := []
	for i in site.plan.size():
		if not site.plan[i].built:
			todo.append(i)
	var need := Builder.missing_for(site.plan, todo, auth.storage.get_box(box).inv)
	for item in need:
		auth.storage.put(box, item, int(need[item]) + 10)
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.node.global_position = auth.storage.get_box(box).node.global_position + Vector3(1.2, 0.2, 0.0)
	var whys := []
	auth.learned_blueprint.connect(func(_w, _p, why): whys.append(why))
	var worst := 0
	var carving := 0
	check((b.sites[box].fill as Array).is_empty(), "a ruin levels no ground round it (F559)")
	for k in 3000:
		if not b.sites.has(box):
			break
		b._site_ticks += 1
		var t := Time.get_ticks_usec()
		b._tick_sites()
		worst = maxi(worst, Time.get_ticks_usec() - t)
		if "arving" in b.site_status(box):
			carving += 1
	check_eq(carving, 0, "rebuilding never says \"carving rock\" (F559)")
	check(not b.sites.has(box), "the rebuild finished")
	check(whys.size() == 2 and whys.all(func(w): return "rebuilding the old tower" in w),
		"the blueprints learned say why: %s (F580)" % [whys])
	check(worst < 80000, "no step of the rebuild freezes the game (slowest %d ms; was up to 700)" % (worst / 1000))
	# F581: the bolt crate lying inside goes with the rest of the inside junk.
	var lp := auth.loot_props
	var k := str(box)
	lp.place_ruin(k, auth.world_state.ruins[k])
	var had := 0
	for key in lp.props:
		if String(key).begins_with("r:%s:j" % k):
			had += 1
	lp._check = 0.0
	lp._process(0.1)
	var left := 0
	for key in lp.props:
		if String(lp.props[key].get("ruin", "")) == k and lp.props[key].get("inside", false):
			left += 1
	check(had > 0 and left == 0, "the bolt crate inside the tower goes after the rebuild (%d before, %d left; F581)" % [had, left])
	auth.get_parent().queue_free()
