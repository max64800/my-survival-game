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


## F631 (owner, Nov 22: "putting materials in a Rebuilding Chest should start the rebuild by itself, no hammer, no
## swinging") + F567 (bundled by the owner: no blue plan at ruins at all) + F633 (the cursor sometimes stayed
## hidden opening this menu) + F634/F689 (both cards show from the start, matching "planks or cut stone" above
## them; F634 used to hide the stone card until you had the material, F689 reversed that) + F635 (bigger
## pictures, each with its own name, not just on hover) + F636 (a clear line when the tower's done, and where
## to see what it taught) + F565 (10 FPS and freezes while rebuilding).
func test_rebuilds_itself_no_hammer_no_blue_plan() -> void:
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
	# F633: opening the Rebuilding Chest always shows the cursor again.
	Controls.set_captured(true)
	var panel := BoxPanel.new()
	auth.get_parent().add_child(panel)
	panel.open(box)
	check(not Controls.captured(), "opening the Rebuilding Chest shows the cursor (F633)")
	# F560/F689: both cards (wood and stone) show from the start, matching the "planks or cut stone" line above them.
	var cards := panel._ways.get_children().filter(func(c): return c is PanelContainer)
	var pics := panel._ways.find_children("*", "TextureRect", true, false)
	check(cards.size() == 2 and pics.size() >= 3, "both cards show even with nothing cut yet (F689, %d cards, %d pictures)" % [cards.size(), pics.size()])
	check(panel._status.text.length() < 50, "one short line above them: \"%s\"" % panel._status.text)
	# F635: each picture says its own name under it, not just on hover.
	var names := panel._ways.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("Rootwood Plank" in names, "the wood picture names itself (F635): %s" % [names])
	var t0 := Time.get_ticks_usec()
	auth.storage.put(box, "plank_root", 5)
	var start_ms := (Time.get_ticks_usec() - t0) / 1000
	check(b.sites.has(box), "planks start the rebuild by themselves, with no hammer and nobody swinging (F631)")
	check(start_ms < 250, "putting the first planks in doesn't freeze the game (%d ms)" % start_ms)
	var site: Dictionary = b.sites[box]
	check(not (site.ghosts as Node3D).visible, "a ruin never shows the blue plan, hammer or not (F567)")
	# F578: after something went in, the chest shows what still has to go in.
	var left_need := b.still_needed(box)
	check(int(left_need.get("plank_root", 0)) > 0 and int(left_need.get("plank_root", 0)) <= planks,
		"the chest knows the planks still missing (%s; F578)" % [left_need])
	panel.refresh()
	check(panel._ways.visible and "Still to put in" in str(panel._ways.find_children("*", "Label", true, false).map(func(l): return l.text)),
		"opening the chest shows the pictures of what's still missing (F578)")
	panel.queue_free()
	var todo := []
	for i in site.plan.size():
		if not site.plan[i].built:
			todo.append(i)
	var need := Builder.missing_for(site.plan, todo, auth.storage.get_box(box).inv)
	for item in need:
		auth.storage.put(box, item, int(need[item]) + 10)
	# F631: nobody stands by the chest and nobody holds the Build Hammer for any of this; the player stays at spawn.
	var whys := []
	auth.learned_blueprint.connect(func(_w, _p, why): whys.append(why))
	var rebuilt_lines := []
	auth.hud_message.connect(func(t: String): rebuilt_lines.append(t))
	var worst := 0
	var carving := 0
	var ghost_shown := false
	check((b.sites[box].fill as Array).is_empty(), "a ruin levels no ground round it (F559)")
	for k in 3000:
		if not b.sites.has(box):
			break
		b._site_ticks += 1
		var t := Time.get_ticks_usec()
		b._tick_sites()
		worst = maxi(worst, Time.get_ticks_usec() - t)
		if b.sites.has(box) and (b.sites[box].ghosts as Node3D).visible:
			ghost_shown = true
		if "arving" in b.site_status(box):
			carving += 1
	check_eq(carving, 0, "rebuilding never says \"carving rock\" (F559)")
	check(not ghost_shown, "the blue plan never once showed while it rebuilt (F567)")
	check(not b.sites.has(box), "the rebuild finished with nobody standing by it or holding the hammer (F631)")
	check(whys.size() == 2 and whys.all(func(w): return "rebuilding the old tower" in w),
		"the blueprints learned say why: %s (F580)" % [whys])
	check(rebuilt_lines.any(func(t): return "tower" in t and "stands" in t), "a clear line says the tower's done (F636): %s" % [rebuilt_lines])
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
		if String(lp.props[key].get("ruin", "")) == k:
			left += 1
	check(had > 0 and left == 0, "the tower's spilt bolt crate (its lootable junk) goes after the rebuild (%d before, %d left; F581)" % [had, left])
	# Owner, Nov 21: the ruin's mess goes, inside and outside; F864 (Nov 25): its whole things stay.
	var rj := RuinJunk.new(auth)
	auth.add_child(rj)
	rj._check = 0.0
	rj._process(0.1)
	var all_junk: Array = auth.world_state.ruins[k].get("junk", [])
	check(rj.shown.size() <= all_junk.size() and rj.shown.all(func(m): return not RuinJunk.is_mess(m)),
		"only its whole things are still drawn (%d of %d), none of the mess" % [rj.shown.size(), all_junk.size()])
	auth.get_parent().queue_free()
