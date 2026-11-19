extends TestCase
## Checks the referee (request → approve → everyone updates) with a real cave.

var world: World
var auth: GameAuthority
var glow: GlowField
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup(seed: int, at: Vector3 = Vector3.INF) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var stations_root := Node3D.new()
	root.add_child(stations_root)
	world = World.new()
	root.add_child(world)
	world.setup(seed)
	glow = GlowField.new()
	root.add_child(glow)
	glow.build(GlowPlacer.place(world.maker))
	var drops := Node3D.new()
	root.add_child(drops)
	auth = GameAuthority.new()
	auth.world = world
	auth.glow = glow
	auth.drops_root = drops
	auth.stations_root = stations_root
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn if at == Vector3.INF else at
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 600:
		if world.is_ready_at(player.global_position, 6.0):
			break
		await tree.process_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


## Finds a rock spot of material `mat` near spawn, then stands the player right above it.
func _find_rock(mat: int) -> Vector3:
	var base := player.global_position
	for r in range(0, 8):
		for x in range(-r, r + 1):
			for z in range(-r, r + 1):
				for y in range(-6, 3):
					var p := base + Vector3(x, y, z)
					if world.sdf_at(p) < -0.5 and world.rock_material_near(p - Vector3.UP * 0.3, 1.1) == mat:
						player.global_position = p + Vector3.UP * 1.5
						return p
	return Vector3.INF


func test_stone_takes_three_hits_and_drops_stone() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	check(p != Vector3.INF, "found stone near spawn")
	if p == Vector3.INF:
		_teardown()
		return
	var r1 := auth.request_hit(1, p, Vector3.UP)
	var r2 := auth.request_hit(1, p, Vector3.UP)
	check_eq(r1.get("state"), "hit", "1st hit")
	check_eq(r2.get("state"), "hit", "2nd hit")
	check_eq(r1.get("needed"), 3, "stone needs 3 hits with a stone pickaxe")
	var before := auth.drop_count()
	var r3 := auth.request_hit(1, p, Vector3.UP)
	check_eq(r3.get("state"), "dug", "3rd hit digs")
	check(auth.drop_count() > before, "digging stone drops something")
	_teardown()


## F89: lost your pickaxe? Bare hands still dig stone, just three times slower, so you can't get stuck.
func test_bare_hands_dig_stone_slowly() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	if p == Vector3.INF:
		_teardown()
		return
	for i in ps.inventory.slots.size():
		if Items.kind(ps.inventory.get_slot(i).get("id", "")) == "pickaxe":
			ps.inventory.slots[i] = {}
	var r := auth.request_hit(1, p, Vector3.UP)
	check_eq(r.get("state"), "hit", "bare hands hit the rock")
	var needed: int = r.get("needed", 0)
	check(needed >= 7 and needed <= 9, "stone takes about 3 times the hits by hand (3 with a stone pickaxe), got %d" % needed)
	for i in needed - 1:
		r = auth.request_hit(1, p, Vector3.UP)
	check_eq(r.get("state"), "dug", "and then it breaks")
	_teardown()


func test_dirt_is_one_hit_moss_two() -> void:
	await _setup(42)
	var p := _find_rock(Mat.DIRT)
	if p != Vector3.INF:
		check_eq(auth.request_hit(1, p, Vector3.UP).get("state"), "dug", "dirt digs in 1 hit")
	var m := _find_rock(Mat.MOSS)
	check(p != Vector3.INF or m != Vector3.INF, "found moss/dirt near spawn")
	if m != Vector3.INF:  # the mossy top layer takes 2 hits (owner, F196)
		check_eq(auth.request_hit(1, m, Vector3.UP).get("state"), "hit", "moss: the first hit only cracks it")
		check_eq(auth.request_hit(1, m, Vector3.UP).get("state"), "dug", "moss: the second hit digs it")
	_teardown()


func test_border_rock_is_blocked() -> void:
	var edge := Vector3(CaveMaker.HALF_SIZE + 1.5, -30.0, CaveMaker.gate_free_z(42))  # not at a gate (gates are open on purpose)
	await _setup(42, edge + Vector3(-2.5, -1.0, 0))
	var r := auth.request_hit(1, edge, Vector3.LEFT)
	check_eq(r.get("state"), "blocked", "border rock can't be dug")
	check(world.sdf_at(edge) < 0.0, "border rock is still there")
	_teardown()


func test_needs_pickaxe_selected() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	auth.request_select_slot(1, 3)
	check(auth.request_hit(1, p, Vector3.UP).get("state") != "no_tool", "empty hand digs with the equipped pickaxe (F23)")
	auth.get_player(1).inventory.slots[Inventory.equip_index("pickaxe")] = {}
	check(auth.request_hit(1, p, Vector3.UP).get("state") != "no_tool", "no pickaxe at all: bare hands still dig (F89)")
	auth.get_player(1).inventory.slots[3] = {id = "sword_stone", count = 1}
	check_eq(auth.request_hit(1, p, Vector3.UP).get("state"), "no_tool", "but a sword in your hand doesn't dig")
	_teardown()


func test_too_far_is_refused() -> void:
	await _setup(42)
	var far := player.global_position + Vector3(0, -2, 12)
	check_eq(auth.request_hit(1, far, Vector3.UP).get("state"), "too_far", "can't dig 12 m away")
	_teardown()


func test_pickup_puts_items_in_bag() -> void:
	await _setup(42)
	auth.spawn_drop("copper_ore", 3, player.global_position + Vector3.UP)
	var id: int = auth._drops.keys()[0]
	check(auth.request_pickup(1, id), "pickup approved")
	check_eq(ps.inventory.count_of("copper_ore"), 3, "3 copper in the bag")
	check_eq(auth.drop_count(), 0, "drop is gone")
	auth.spawn_drop("stone", 1, player.global_position + Vector3(0, 0, 30))
	var far_id: int = auth._drops.keys()[0]
	check(not auth.request_pickup(1, far_id), "can't pick up from 30 m away")
	_teardown()


## Lantern Bearer perk (N3, owner said yes): each rank makes the lantern reach 25% further.
func test_lantern_bearer_reaches_further() -> void:
	await _setup(42)
	check_near(ps.progress.lantern_range_mult(), 1.0, 0.001, "no perk: normal reach")
	ps.progress.perks["lantern_bearer"] = 2
	check_near(ps.progress.lantern_range_mult(), 1.5, 0.001, "rank 2: 50% further")
	var lamp := Lantern.new()
	lamp.peer_id = 1
	tree.root.add_child(lamp)
	for i in 120:
		await tree.process_frame
	check(lamp.light.omni_range > Lantern.FULL_RANGE * 1.3, "the light really reaches further (%.1f m)" % lamp.light.omni_range)
	lamp.queue_free()
	_teardown()


func test_lantern_refill_uses_a_crystal() -> void:
	await _setup(42)
	check(not auth.request_refill(1), "full lantern can't be refilled")
	ps.fuel = 10.0
	check(not auth.request_refill(1), "no crystal, no refill")
	ps.inventory.add("crystal_blue", 2)
	check(auth.request_refill(1), "refill with a crystal")
	check_eq(ps.inventory.count_of("crystal_blue"), 1, "one crystal used")
	check_near(ps.fuel, 10.0 + Items.fuel_seconds("crystal_blue"), 0.01, "fuel went up")
	_teardown()


func test_fuel_burns_down_but_not_below_zero() -> void:
	await _setup(42)
	ps.fuel = 0.05
	await frames(10)
	check_eq(ps.fuel, 0.0, "fuel stops at zero")
	_teardown()


func test_breaking_glow_crystal_gives_crystals() -> void:
	await _setup(42)
	var spot := _first_spot(GlowPlacer.CRYSTAL)
	player.global_position = spot.pos + spot.normal * 1.5 - Vector3.UP
	check_eq(auth.request_harvest(1, spot.id).get("state"), "hit", "crystal needs 2 hits with a stone pickaxe")
	check_eq(auth.request_harvest(1, spot.id).get("state"), "done", "second hit breaks it")
	check(glow.get_spot(spot.id).is_empty(), "crystal removed")
	check_eq(auth.drop_count(), 1, "crystal drop spawned")
	check_eq(auth.request_harvest(1, spot.id).get("state"), "gone", "can't break it twice")
	check(ps.progress.skill_xp.mining > 0, "mining XP for the crystal")
	_teardown()


func _first_spot(kind: String) -> Dictionary:
	for id in glow._spots:
		if glow._spots[id].kind == kind:
			return glow._spots[id]
	return {}


func test_roots_give_wood_four_times() -> void:
	await _setup(42)
	var root := _first_spot(GlowPlacer.ROOT)
	check(not root.is_empty(), "the cave has roots")
	if root.is_empty():
		_teardown()
		return
	player.global_position = root.pos + Vector3(1.2, 0.9, 0.0)  # beside the root (they grow out of the floor)
	# A stone pickaxe is poor at wood (0.3 power): 30 / 3 = 10 hits per chop-through.
	var chops := 0
	for i in 60:
		if auth.request_harvest(1, root.id).get("state") == "done":
			chops += 1
	check_eq(chops, 4, "4 chop-throughs before the root is gone")
	check(glow.get_spot(root.id).is_empty(), "root gone after 4")
	check_eq(auth.drop_count(), 8, "4 piles of rootwood + 4 bits of fiber (F182)")
	_teardown()


## Owner, Nov 17: "axes aren't better at cutting wood". A stone axe needs 2 hits, a stone pickaxe about 10.
func test_axe_beats_pickaxe_on_wood() -> void:
	await _setup(42)
	var root := _first_spot(GlowPlacer.ROOT)
	if root.is_empty():
		_teardown()
		return
	player.global_position = root.pos + Vector3(1.2, 0.9, 0.0)
	var pick: int = auth.request_harvest(1, root.id).get("needed", 0)
	ps.inventory.slots[0] = {id = "axe_stone", count = 1}
	auth.request_select_slot(1, 0)
	var axe: int = auth.request_harvest(1, root.id).get("needed", 0)
	check(axe > 0 and axe <= 2, "a stone axe chops a root in 2 hits (got %d)" % axe)
	check(pick >= 4 * axe, "a pickaxe takes far longer (%d vs %d)" % [pick, axe])
	_teardown()


func test_mushrooms_by_hand() -> void:
	await _setup(42)
	var cap := _first_spot("glowcap")
	player.global_position = cap.pos + Vector3.UP * 0.2
	auth.request_select_slot(1, 5)  # empty hand
	check_eq(auth.request_harvest(1, cap.id).get("state"), "done", "picked by hand in one go")
	_teardown()


## Which hotbar slot holds this item (-1 = none).
func _slot_of(id: String) -> int:
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == id:
			return i
	return -1


func test_eat_from_hotbar() -> void:
	await _setup(42)
	ps.inventory.add("dish_hollowcap_stew", 1)
	auth.request_select_slot(1, _slot_of("dish_hollowcap_stew"))  # the start pickaxe is in the hotbar (F243)
	ps.vitals.hunger = 20
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "ate", "ate the stew")
	check_eq(ps.inventory.count_of("dish_hollowcap_stew"), 0, "stew used up")
	check_near(ps.vitals.hunger, 70.0, 0.01, "+50 hunger")
	check_near(ps.vitals.max_health(), 120.0, 0.01, "+20% max health buff")
	_teardown()


func test_waterskin_has_five_sips() -> void:
	await _setup(42)
	ps.inventory.add("waterskin_clean", 1)
	auth.request_select_slot(1, _slot_of("waterskin_clean"))  # the start pickaxe is in the hotbar (F243)
	for i in 5:
		ps.vitals.thirst = 0
		auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0)
	check_eq(ps.inventory.count_of("waterskin_empty"), 1, "empty after 5 sips")
	check_near(ps.vitals.thirst, 35.0, 0.01, "each sip +35")
	_teardown()


func test_craft_campfire_and_place_it() -> void:
	await _setup(42)
	ps.inventory.add("stone", 5)
	ps.inventory.add("rootwood", 3)
	check(auth.request_craft(1, "campfire"), "campfire crafted by hand")
	check(ps.progress.skill_xp.crafting > 0, "smithing XP for crafting")
	var slot := -1
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "campfire":
			slot = i
	auth.request_select_slot(1, slot)
	var floor_p := world.maker.find_floor(player.global_position.x + 1.5, player.global_position.z, player.global_position.y + 1.0)
	check_eq(auth.request_use(1, floor_p, Vector3.UP, 0.0), "placed", "placed on the floor")
	check_eq(auth.stations.size(), 1, "one station in the world")
	check_eq(ps.inventory.count_of("campfire"), 0, "campfire left the bag")
	_teardown()


func test_smelter_takes_time_and_fuel() -> void:
	await _setup(42)
	auth._ev_place_station(7, "smelter", player.global_position + Vector3(1.5, 0, 0), 0.0)
	ps.inventory.add("copper_ore", 4)
	check(not auth.request_craft(1, "copper_ingot", 7), "no fuel, no smelting")
	ps.inventory.add("rootwood", 2)
	check(not auth.request_craft(1, "copper_ingot", 7), "raw wood isn't fuel: only Bloomery coal (F404)")
	ps.inventory.add("coal", 2)
	check(auth.request_craft(1, "copper_ingot", 7), "smelting started")
	check_eq(ps.inventory.count_of("copper_ore"), 2, "ore went in")
	check_eq(ps.inventory.count_of("coal"), 1, "one coal burned")
	check_eq(ps.inventory.count_of("rootwood"), 2, "the wood is untouched")
	check_eq(auth.drop_count(), 0, "not done yet")
	var st: Station = auth.stations[7]
	st.jobs[0].left = 0.05
	await tree.create_timer(0.2).timeout
	check_eq(auth.drop_count(), 1, "ingot popped out")
	check(not auth.request_craft(1, "copper_ingot", 99), "unknown station refused")
	_teardown()


func test_digging_gives_mining_xp() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	for i in 3:
		auth.request_hit(1, p, Vector3.UP)
	check_eq(ps.progress.skill_xp.mining, Mat.DIG_XP[Mat.STONE], "2 mining XP for stone")
	check_eq(ps.progress.xp, Mat.DIG_XP[Mat.STONE], "and 2 character XP")
	_teardown()


func test_unknown_player_is_ignored() -> void:
	await _setup(42)
	check(auth.request_hit(99, Vector3.ZERO, Vector3.UP).is_empty(), "unknown player gets nothing")
	check(not auth.request_pickup(99, 1), "unknown player can't pick up")
	_teardown()


## F115: copper is too hard for a stone pickaxe (or bare hands); the Fang Pickaxe mines it.
func test_copper_needs_the_fang_pickaxe() -> void:
	check(GameAuthority.ore_too_hard(Mat.COPPER, "pickaxe_stone").contains("Fang Pickaxe"), "stone bounces off copper and says what you need")
	check(GameAuthority.ore_too_hard(Mat.COPPER, "") != "", "so do bare hands")
	check_eq(GameAuthority.ore_too_hard(Mat.COPPER, "pickaxe_fang"), "", "the Fang Pickaxe mines it")
	check_eq(GameAuthority.ore_too_hard(Mat.COPPER, "pickaxe_copper"), "", "and anything better")
	check_eq(GameAuthority.ore_too_hard(Mat.STONE, "pickaxe_stone"), "", "plain stone is still fine")


## Owner, Nov 17: pressing the picked hotbar number again puts the tool away (empty hands); again takes it back out.
func test_same_hotbar_number_puts_the_tool_away() -> void:
	await _setup(42)
	auth.ask_select_slot(1)
	auth.ask_select_slot(0)  # pick slot 1 (index 0)
	check(not ps.hands_empty, "picked: something in hand")
	auth.ask_select_slot(0)  # the same number again
	check(ps.hands_empty, "pressed again: hands empty")
	check_eq(ps.hand_slot(), -1, "nothing in hand")
	check_eq(ps.selected_item(), "", "holding nothing")
	auth.ask_select_slot(0)
	check(not ps.hands_empty, "pressed again: the tool is back")
	auth.ask_select_slot(0)
	auth.ask_select_slot(1)
	check(not ps.hands_empty, "another number: that slot, hands not empty")
	_teardown()


## Owner, Nov 17: L puts the lantern away: no light, no fuel used; L again takes it out.
func test_lantern_put_away_uses_no_fuel() -> void:
	await _setup(42)
	ps.fuel = 100.0
	auth.ask_stow_lantern(true)
	check(ps.lantern_stowed, "put away")
	await frames(30)
	check_eq(ps.fuel, 100.0, "no fuel burnt while it's put away")
	auth.ask_stow_lantern(false)
	await frames(30)
	check(ps.fuel < 100.0, "burning again once it's out")
	_teardown()


## Natural ramps (owner, Nov 17): digging up and in front of you also clears a slope from your feet to the hole,
## so you can walk up it; digging straight ahead doesn't.
func test_digging_up_ahead_leaves_a_ramp() -> void:
	await _setup(42)
	var feet := player.global_position
	var fl := world.maker.find_floor(feet.x, feet.z, feet.y + 1.0)
	if fl != Vector3.INF:
		player.global_position = fl
		feet = fl
	var before := auth.edit_log.size()
	# a scoop 3 m ahead whose floor is 1.2 m above the feet
	var center := feet + Vector3(3.0, 1.2 + GameAuthority.DIG_RADIUS, 0.0)
	var counts := auth._host_dig(center, 0)
	auth._dig_ramp(ps, center, 0, counts)
	check(auth.edit_log.size() >= before + 4, "a few extra scoops clear the ramp (%d)" % (auth.edit_log.size() - before - 1))
	var mid := feet + Vector3(1.6, 0.6 + 0.9, 0.0)  # above the slope halfway: room for a dwarf
	check(world.sdf_at(mid) > 0.0, "there's room to walk up halfway")
	before = auth.edit_log.size()
	auth._dig_ramp(ps, feet + Vector3(3.0, GameAuthority.DIG_RADIUS, 0.0), 0, {})
	check_eq(auth.edit_log.size(), before, "digging straight ahead adds no ramp")
	_teardown()


## Owner, Nov 17: a work table touching the wall can't be placed (its ghost is red), and the tables are dwarf-sized.
func test_station_in_the_wall_is_refused() -> void:
	await _setup(42)
	var c: Vector3 = world.maker.rooms[0].center
	var fl := world.maker.find_floor(c.x, c.z, c.y)
	check(fl != Vector3.INF, "found the cavern floor")
	if fl != Vector3.INF:
		check(not Station.in_rock("workbench", fl, 0.0, world), "a workbench fits on the open floor")
	var p := _find_rock(Mat.STONE)
	if p != Vector3.INF:
		check(Station.in_rock("workbench", p - Vector3.UP * 0.5, 0.0, world), "a workbench inside the rock doesn't fit")
	check(Station.size_of("workbench").y <= 0.85, "the workbench is dwarf-sized (%.2f m)" % Station.size_of("workbench").y)
	_teardown()


## The Mason's Shovel (owner, Nov 17): one swing flattens the patch you aim at to your feet height: bumps go,
## dips are filled with dirt from the bag. Fills are saved like digs.
func test_masons_shovel_levels_the_ground() -> void:
	await _setup(42)
	var feet := player.global_position
	var fl := world.maker.find_floor(feet.x, feet.z, feet.y + 1.0)
	if fl != Vector3.INF:
		player.global_position = fl
		feet = fl
	var at := feet + Vector3(2.0, 0.0, 0.0)
	world.apply_fill(at + Vector3.UP * 0.3, 1.0, Mat.STONE)  # a bump on the floor (the rock is stored in 1 m steps)
	world.apply_dig(at + Vector3(0.6, -1.0, 0.0), 1.0, 0)  # and a dip beside it
	check(world.sdf_smooth(at + Vector3.UP * 0.5) < 0.0, "there's a bump to flatten")
	ps.inventory.slots[0] = {id = "masons_shovel", count = 1}
	auth.request_select_slot(1, 0)
	ps.inventory.add("dirt", 3)
	var r := auth.request_hit(1, at, Vector3.UP)
	check_eq(r.get("state"), "dug", "the shovel works")
	check(world.sdf_smooth(at + Vector3.UP * 0.5) > 0.0, "the bump is gone")
	check(world.sdf_smooth(at + Vector3(0.6, -0.3, 0.0)) < 0.0, "the dip is filled")
	check_eq(ps.inventory.count_of("dirt"), 2, "filling used 1 dirt")
	var fills := 0
	for e in auth.edit_log:
		if e.w < 0.0:
			fills += 1
	check(fills > 0, "the fill is saved with the digs")
	check(Recipes.LIST.has("masons_shovel") and Recipes.LIST.masons_shovel.station == "workbench", "made at the Workbench")
	_teardown()


## F261 (owner, Nov 17): every hit pays, like Conan Exiles: a stone on each hit, the rest when it breaks. The early
## stones are an advance on that rock, so over many digs the total is what it was.
func test_every_hit_pays() -> void:
	await _setup(42)
	var p := _find_rock(Mat.STONE)
	if p == Vector3.INF:
		_teardown()
		return
	var before := auth.drop_count()
	check_eq(auth.request_hit(1, p, Vector3.UP).get("state"), "hit", "1st hit")
	check_eq(auth.drop_count(), before + 1, "the first hit already gives a stone")
	check(ps.leftovers.get(Mat.STONE, 0) < 0, "it's an advance on that rock")
	auth.request_hit(1, p, Vector3.UP)
	check_eq(auth.request_hit(1, p, Vector3.UP).get("state"), "dug", "3rd hit breaks it")
	check(ps.leftovers.get(Mat.STONE, 0) > -Mat.VOXELS_PER_ITEM[Mat.STONE] * 3, "the advance is paid back")
	_teardown()


## Owner, Nov 17: root-curtain strands break for fiber, big ceiling roots for wood; both stay broken in a save.
func test_hanging_roots_break() -> void:
	await _setup(42)
	var rc := RootCurtains.new()
	auth.get_parent().add_child(rc)
	rc.build(world.maker, world, true)
	auth.curtains = rc
	var strands := RootCurtains.plan(world.maker)
	check(strands.size() > 0, "there are curtains")
	if strands.is_empty():
		_teardown()
		return
	var top: Vector3 = (strands[0][0] as Transform3D).origin
	player.global_position = top - Vector3.UP * 2.0
	var before := auth.drop_count()
	auth.request_break_hanging(1, "strand", "0")
	check(auth.drop_count() > before, "breaking a curtain gives fiber")
	check(auth.removed_strands.has(0), "the strand is gone")
	check_eq(rc.top_of(0), Vector3.INF, "and hidden")
	check(auth.snapshot().strands.has(0), "a save remembers it")
	_teardown()

## F189: chopping a giant root pillar gives wood, 2 a hit with an axe, until it's chopped bare.
func test_root_pillar_chops() -> void:
	await _setup(42)
	var rp := RootPillars.new()
	auth.get_parent().add_child(rp)
	rp.build(world.maker)
	auth.pillars = rp
	var p := rp.pillar(0)
	check(not p.is_empty(), "there's a pillar")
	if p.is_empty():
		_teardown()
		return
	player.global_position = (p.bottom as Vector3) + Vector3(p.width * 0.15 + 1.0, 0.1, 0.0)
	var before := auth.drop_count()
	for i in RootPillars.CHOPS + 3:
		auth.request_chop_pillar(1, 0)
	check(auth.drop_count() > before, "chopping gives wood")
	check_eq(auth.pillar_chops.get(0, 0), RootPillars.CHOPS, "up to the limit, then it cracks")
	_teardown()

## Root Trees (owner, Nov 18): 30 wood, then it cracks and drops Root Seeds; a seed planted with the Mason's Shovel
## grows into a full tree (a sprout halfway).
func test_root_tree_cracks_and_replants() -> void:
	await _setup(42)
	var rp := RootPillars.new()
	auth.get_parent().add_child(rp)
	rp.build(world.maker)
	auth.pillars = rp
	var p := rp.pillar(0)
	if p.is_empty():
		check(false, "there's a Root Tree")
		_teardown()
		return
	player.global_position = (p.bottom as Vector3) + Vector3(p.width * 0.15 + 1.0, 0.4, 0.0)
	for i in RootPillars.CHOPS + 3:
		auth.request_chop_pillar(1, 0)
	check_eq(auth.pillar_chops.get(0, 0), RootPillars.CHOPS, "30 wood, then nothing more")
	check_eq(rp.pillar(0).stage, "broken", "it cracked: a stump and a crown are left")
	# plant a seed with the shovel where the ceiling is 5-14 m up
	ps.inventory.slots[0] = {id = "masons_shovel", count = 1}
	auth.request_select_slot(1, 0)
	ps.inventory.add("root_seed", 1)
	var spot := Vector3.INF
	var base: Vector3 = world.maker.cavern_spawn
	for r in range(4, 40, 2):
		for k in 12:
			var q := base + Vector3(cos(k * TAU / 12.0) * r, 2.0, sin(k * TAU / 12.0) * r)
			var fl := world.maker.find_floor(q.x, q.z, q.y + 2.0)
			if fl == Vector3.INF or rp.near(fl, 7.0) or world.maker.is_reserved(fl, 3.5):
				continue
			var up := 0.0
			while up < 15.0 and world.sdf_at(fl + Vector3.UP * (up + 0.5)) >= 0.0:
				up += 0.25
			if up > 5.5 and up < 13.5:
				spot = fl
				break
		if spot != Vector3.INF:
			break
	if spot == Vector3.INF:
		_teardown()
		return
	player.global_position = spot + Vector3(1.5, 0.2, 0.0)
	check_eq(auth.request_use(1, spot, Vector3.UP, 0.0), "planted", "a Root Seed planted with the shovel")
	check_eq(ps.inventory.count_of("root_seed"), 0, "the seed is used")
	var id: int = auth.planted[0].id
	check_eq(rp.pillar(id).want_stage, "seed", "a seed in the ground")
	auth._tick_trees(RootPillars.GROW_TIME * 0.6)
	check_eq(rp.pillar(id).want_stage, "sprout", "after 30 minutes: a sprout")
	auth._tick_trees(RootPillars.GROW_TIME)
	check_eq(rp.pillar(id).want_stage, "tree", "after an hour: a full Root Tree")
	check(auth.snapshot().planted.size() == 1, "saved with the world")
	_teardown()


## Boulders (owner, Nov 18, like Conan Exiles): stone every hit, it bursts after Boulders.HITS hits, comes back later.
func test_boulder_breaks_and_comes_back() -> void:
	await _setup(42)
	var bo := Boulders.new()
	auth.get_parent().add_child(bo)
	bo.build(world.maker, Callable(), true)
	auth.boulders = bo
	var r := bo.rock(0)
	check(not r.is_empty(), "there's a boulder")
	if r.is_empty():
		_teardown()
		return
	player.global_position = (r.pos as Vector3) + Vector3(1.6, 0.1, 0.0)
	var before := auth.drop_count()
	for i in Boulders.HITS + 3:
		auth.request_hit_boulder(1, 0)
	check(auth.drop_count() > before, "hitting it gives stone")
	check(bo.rock(0).broken, "it broke after %d hits" % Boulders.HITS)
	check(auth.boulder_back.has(0), "a new one is on its way")
	var snap := auth.snapshot()
	check(snap.boulder_back.has(0), "saved")
	auth._tick_boulders(Boulders.RESPAWN + 1.0)
	check(not auth.boulder_back.has(0), "after 20 minutes it comes back")
	check(bo.rock(0).want_back, "it appears when nobody is looking")
	_teardown()


## Owner, Nov 19 ("yes"): dig the rock out from under a boulder and it drops into the hole, never floating in the air.
func test_boulder_drops_when_dug_under() -> void:
	await _setup(42)
	var plan := Boulders.cached_plan(world.maker)
	var best := -1
	for i in plan.size():
		if not plan[i].get("gone", false) and (best < 0 or (plan[i].pos as Vector3).distance_to(player.global_position) < (plan[best].pos as Vector3).distance_to(player.global_position)):
			best = i
	check(best >= 0, "a boulder near the start")
	if best < 0:
		_teardown()
		return
	var at: Vector3 = plan[best].pos
	player.global_position = at + Vector3(3.0, 1.0, 0.0)
	var solid := VoxelViewer.new()  # (the real rock surface, so rays find the floor: the test viewer only loads data)
	solid.view_distance = 24
	player.add_child(solid)
	for i in 900:
		if world.terrain.is_area_meshed(AABB(at - Vector3.ONE * 8.0, Vector3.ONE * 16.0)):
			break
		await tree.physics_frame
	var had: GroundSnap = GroundSnap.instance
	var snap := GroundSnap.new()
	snap.world = world
	auth.get_parent().add_child(snap)
	GroundSnap.instance = snap
	var bo := Boulders.new()
	auth.get_parent().add_child(bo)
	bo.build(world.maker, Callable(), true)
	for i in 120:
		await tree.physics_frame
	bo._settle(best)  # (the snapper works round all the cave's boulders; settle this one now)
	var r := bo.rock(best)
	check(not r.broken, "it stands on the floor")
	var y0: float = r.pos.y
	var scale: float = r.scale
	var dug := world.apply_dig((r.pos as Vector3) + Vector3.DOWN * 0.6, 1.0 + 1.0 * scale, 4)
	check(not dug.is_empty(), "rock dug out under it")
	for i in 240:
		await tree.physics_frame
	r = bo.rock(best)
	check(not r.broken, "still there")
	check((r.pos as Vector3).y < y0 - 0.5, "it dropped into the hole (%.2f -> %.2f)" % [y0, (r.pos as Vector3).y])
	check_near((r.body as Node3D).global_position.y, (r.pos as Vector3).y, 0.01, "its body moved with it")
	GroundSnap.instance = had
	_teardown()


## Root Trees are solid all round (owner, Nov 18: "I can walk fully inside them"): from every side, a ray at chest
## height toward the trunk hits the bark before it gets near the middle.
func test_root_tree_is_solid_outside() -> void:
	await _setup(42)
	var rp := RootPillars.new()
	auth.get_parent().add_child(rp)
	rp.build(world.maker)
	var p := rp.pillar(0)
	check(not p.is_empty(), "there's a tree")
	if p.is_empty():
		_teardown()
		return
	for k in 3:
		await tree.physics_frame
	var space := rp.get_world_3d().direct_space_state
	var mid := Vector3(p.top.x, (p.bottom as Vector3).y + 1.5, p.top.z)
	for k in 6:
		var a := k * TAU / 6.0
		var from := mid + Vector3(cos(a), 0, sin(a)) * (float(p.width) * 0.8 + 2.0)
		var q := PhysicsRayQueryParameters3D.create(from, mid, World.TERRAIN_LAYER)
		var hit := space.intersect_ray(q)
		var ok := not hit.is_empty() and Vector2(hit.position.x - mid.x, hit.position.z - mid.z).length() > float(p.width) * 0.15
		check(ok, "side %d: bumps into the bark, not into the middle" % k)
	_teardown()


## A broken Root Tree grows back from both ends (owner, Nov 18): steps at 15 and 30 minutes, whole at 45, and it can't
## be chopped until then; then it gives wood again.
func test_root_tree_regrows_from_both_ends() -> void:
	await _setup(42)
	var rp := RootPillars.new()
	auth.get_parent().add_child(rp)
	rp.build(world.maker)
	auth.pillars = rp
	var p := rp.pillar(0)
	if p.is_empty():
		check(false, "there's a tree")
		_teardown()
		return
	player.global_position = (p.bottom as Vector3) + Vector3(p.width * 0.15 + 1.0, 0.1, 0.0)
	for i in RootPillars.CHOPS:
		auth.request_chop_pillar(1, 0)
	check(auth.tree_regrow.has(0), "it starts growing back")
	check_eq(rp.pillar(0).want_stage, "broken", "a stump and a crown")
	auth._tick_trees(16 * 60.0)
	check_eq(rp.pillar(0).want_stage, "regrow1", "after 15 minutes: step 1")
	var before: int = auth.pillar_chops.get(0, 0)
	auth.request_chop_pillar(1, 0)
	check_eq(auth.pillar_chops.get(0, 0), before, "can't chop it while it grows")
	auth._tick_trees(15 * 60.0)
	check_eq(rp.pillar(0).want_stage, "regrow2", "after 30 minutes: step 2")
	check(auth.snapshot().tree_regrow.has(0), "saved")
	auth._tick_trees(15 * 60.0)
	check_eq(rp.pillar(0).want_stage, "tree", "after 45 minutes: whole again")
	check(not auth.tree_regrow.has(0), "done growing")
	auth.request_chop_pillar(1, 0)
	check(auth.pillar_chops.get(0, 0) == 0 or rp.pillar(0).stage != "tree", "waits until nobody looks, then chops again")
	_teardown()


## Floor things sit on the REAL rock (owner, Nov 18: boulders, mushrooms, bones and moss floating): something planned
## half a metre above the floor is put down onto it once the rock there is built; something over empty air is hidden.
func test_floor_things_are_put_down_on_the_real_rock() -> void:
	await _setup(42)
	var snap := GroundSnap.new()
	snap.world = world
	auth.get_parent().add_child(snap)
	var space := player.get_world_3d().direct_space_state
	var p := player.global_position
	var fl := Vector3.INF
	for i in 600:
		fl = GroundSnap.floor_at(space, p, 2.0, 6.0)
		if fl != Vector3.INF and world.terrain.is_area_meshed(AABB(p - Vector3.ONE * 3, Vector3.ONE * 6)):
			break
		await tree.physics_frame
	check(fl != Vector3.INF, "the rock under the player is built")
	if fl == Vector3.INF:
		_teardown()
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 2
	mm.set_instance_transform(0, Transform3D(Basis(), fl + Vector3.UP * 0.5))  # floating
	mm.set_instance_transform(1, Transform3D(Basis(), fl + Vector3.DOWN * 5.0))  # deep in solid rock: no floor to stand on
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	auth.get_parent().add_child(mmi)
	var list := [Transform3D(Basis(), fl + Vector3.UP * 0.5), Transform3D(Basis(), fl + Vector3.DOWN * 5.0)]
	GroundSnap.add_batch(mmi, {xforms = list}, 0.0)
	for i in 120:
		await tree.physics_frame
		if snap.moved + snap.hidden >= 2:
			break
	check(absf((list[0] as Transform3D).origin.y - fl.y) < 0.08, "the floating one now sits on the floor")
	check((list[1] as Transform3D).basis.get_scale().x < 0.01, "one with no rock under it is hidden")
	check(absf((list[0] as Transform3D).origin.y - fl.y) < 0.08, "its owner's list knows the new place")
	_teardown()


func test_running_jumping_and_shield_xp_are_checked_by_the_host() -> void:
	await _setup(42)
	ps.body_xp_at = GameAuthority.now() - 5.0  # last report 5 s ago
	auth.request_body_xp(1, 4.8, 2, 1)
	check_eq(ps.progress.skill_xp.running, 4, "4.8 s of running = 4 Running XP")
	check_eq(ps.progress.skill_xp.jumping, 6, "2 jumps = 6 Jumping XP")
	check_eq(ps.progress.skill_xp.shield, 4, "1 block = 4 Shield XP")
	ps.body_xp_at = GameAuthority.now() - 5.0
	auth.request_body_xp(1, 9999.0, 9999, 9999)  # made-up numbers from a cheater
	check(ps.progress.skill_xp.running <= 4 + 5, "running capped by the time that passed")
	check(ps.progress.skill_xp.jumping <= 6 + 3 * 9, "jumps capped too")
	_teardown()


func test_active_perks_need_the_perk_and_recharge() -> void:
	await _setup(42)
	check_eq(auth.request_ability(1, "stone_stance"), "", "can't use a perk you don't have")
	ps.progress.perks.stone_stance = 1
	check_eq(auth.request_ability(1, "stone_stance"), "used", "Stone Stance works")
	check_near(ps.vitals.buff_total("damage_taken"), -0.4, 0.0001, "40% less damage taken")
	check(ps.vitals.effects.has("cd_stone_stance"), "our screen knows it's recharging")
	check_eq(auth.request_ability(1, "stone_stance"), "cooldown", "then it has to recharge")
	ps.progress.perks.war_horn = 2
	auth.request_ability(1, "war_horn")
	check_near(auth.damage_boost(ps), 0.20, 0.0001, "War Horn rank 2: +20% damage")
	ps.progress.perks.clan_banner = 1
	auth.request_ability(1, "clan_banner")
	ps.vitals.add_ailment("poison", 40.0)
	check_near(ps.vitals.ailments.buildup.poison, 20.0, 0.5, "Clan Banner: half the poison")
	_teardown()


func test_perk_reset_costs_gold() -> void:
	await _setup(42)
	ps.progress.add_xp(Progression.total_xp_for_level(10))
	ps.progress.buy_perk("thick_skin")
	check(not auth.request_respec(1), "no gold: no reset")
	ps.inventory.add("gold_coin", ps.progress.respec_cost())
	check(auth.request_respec(1), "pay gold: reset")
	check_eq(ps.progress.perk_rank("thick_skin"), 0, "perk refunded")
	check_eq(ps.inventory.count_of("gold_coin"), 0, "the gold is spent")
	_teardown()


func test_toughness_perks_on_the_body() -> void:
	await _setup(42)
	ps.progress.perks = {thick_skin = 3, big_lungs = 2, unbreakable = 1, fire_and_frost = 2}
	check_near(ps.vitals.max_health(), Vitals.BASE_HEALTH + 15.0, 0.001, "Thick Skin 3: +15 health")
	check_near(ps.vitals.max_stamina(), Vitals.BASE_STAMINA + 20.0, 0.001, "Big Lungs 2: +20 stamina")
	ps.vitals.health = 10.0
	ps.vitals.take_damage(50.0)
	check_near(ps.vitals.health, 1.0, 0.001, "Unbreakable: a killing hit leaves 1 health")
	check(ps.vitals.take_damage(50.0), "but only once every 10 minutes")
	ps.vitals.add_ailment("burn", 50.0)
	check_near(ps.vitals.ailments.buildup.burn, 35.0, 0.5, "Fire and Frost 2: 30% less burn")
	_teardown()


func test_skills_window_shows_perk_pictures() -> void:
	await _setup(42)
	var sp := SkillsPanel.new()
	auth.add_child(sp)
	sp.peer_id = 1
	sp.refresh()
	check(sp.has_node("Background"), "the painted hall is behind the window")
	var card := sp.find_child("Perk_whirlwind", true, false)
	check(card != null, "Whirlwind has a card")
	var pics := card.find_children("*", "TextureRect", true, false) if card else []
	check(pics.size() > 0 and pics[0].texture != null, "and a picture")
	sp.queue_free()
	_teardown()
