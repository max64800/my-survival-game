extends Node
## Autopilot: plays a short scripted run by itself, takes screenshots, prints a report
## and quits. Used to check the game works without a person at the keyboard.
## Run:  godot --path . -- autopilot shots=/some/folder seed=42

var _main: Node
var _shots := "user://autopilot"
var _report: Array[String] = []
var _fps_samples: Array[float] = []


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _process(_d: float) -> void:
	_fps_samples.append(Engine.get_frames_per_second())


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = _main.take_screenshot(_shots.path_join(name + ".png"))
	_report.append("screenshot: " + path)


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	_report.append("load time: %.1f s (ready=%s)" % [(Time.get_ticks_msec() - t0) / 1000.0, _main.is_ready_to_play()])
	var dwarf: Dwarf = _main.dwarf
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_main.hud.set_paused(false)
	await _wait(1.5)
	_report.append("glow spots: %d" % _main.glow.spot_count())
	await _shot("01_spawn")

	# Look around the cavern.
	dwarf._pitch = -0.05
	for i in 3:
		dwarf._yaw += TAU / 3.0
		await _wait(0.6)
		await _shot("02_look_%d" % i)

	# Dig straight down-forward at the floor.
	var start_pos := dwarf.global_position
	dwarf._pitch = -0.75
	Input.action_press("dig")
	await _wait(5.0)
	Input.action_release("dig")
	await _wait(1.5)
	await _shot("03_after_digging")
	_report.append("after digging: stone=%d dirt=%d copper=%d crystals=%d, drops lying around=%d" % [
		ps.inventory.count_of("stone"), ps.inventory.count_of("dirt"), ps.inventory.count_of("copper_ore"),
		ps.inventory.count_of("crystal_blue"), auth.drop_count()])

	# Walk forward and dig a tunnel into a wall.
	dwarf._pitch = 0.0
	Input.action_press("move_forward")
	await _wait(3.0)
	Input.action_release("move_forward")
	Input.action_press("dig")
	await _wait(6.0)
	Input.action_release("dig")
	await _wait(1.0)
	await _shot("04_walked_and_dug")
	_report.append("walked %.1f m; still above the cave floor: %s" % [
		start_pos.distance_to(dwarf.global_position), dwarf.global_position.y > CaveMaker.Y_MIN])

	# Run out of fuel to check the dim glow, then refill.
	ps.fuel = 0.0
	await _wait(1.0)
	await _shot("05_lantern_empty")
	ps.inventory.add("crystal_blue", 1)
	_report.append("refill worked: %s (fuel %.0f s)" % [auth.request_refill(auth.local_peer_id()), ps.fuel])
	await _wait(1.0)

	# Step 3: craft a campfire and a workbench, place them, eat something.
	ps.inventory.add("stone", 12)
	ps.inventory.add("rootwood", 14)
	ps.inventory.add("dish_hollowcap_stew", 1)
	_main._set_bag(true)
	await _wait(0.5)
	await _shot("06_bag_and_crafting")
	_main._set_bag(false)
	var made_fire := auth.request_craft(auth.local_peer_id(), "campfire")
	var made_bench := auth.request_craft(auth.local_peer_id(), "workbench")
	var placed := []
	for item in ["campfire", "workbench"]:
		_to_hotbar(ps, item)
		var fwd := -Basis(Vector3.UP, dwarf._yaw).z
		var side := Basis(Vector3.UP, dwarf._yaw).x * (1.5 if item == "workbench" else -1.0)
		var spot := dwarf.global_position + fwd * 2.8 + side
		var floor_p: Vector3 = _main.world.maker.find_floor(spot.x, spot.z, dwarf.global_position.y + 1.5)
		placed.append(auth.request_use(auth.local_peer_id(), floor_p, Vector3.UP, dwarf._yaw))
	_to_hotbar(ps, "dish_hollowcap_stew")
	var ate := auth.request_use(auth.local_peer_id(), Vector3.INF, Vector3.ZERO, 0.0)
	auth.request_select_slot(auth.local_peer_id(), 0)
	dwarf._pitch = -0.35
	await _wait(1.0)
	await _shot("07_campfire_and_workbench")
	_report.append("step 3: crafted fire=%s bench=%s, placed=%s, ate=%s, max health now %.0f, level %d" % [
		made_fire, made_bench, placed, ate, ps.vitals.max_health(), ps.progress.level])
	var st: Station = auth.station_near(dwarf.global_position, 6.0)
	if st:
		_main.hud.open_station(st)
		await _wait(0.5)
		await _shot("08_station_menu")
		_main._set_bag(false)
	ps.progress.add_xp(3000, "mining")
	_main.hud.set_skills_open(true)
	await _wait(0.5)
	await _shot("10_skills")
	_main.hud.set_skills_open(false)
	_main.hud.set_map_open(true)
	await _wait(0.5)
	await _shot("11_map")
	_main.hud.set_map_open(false)
	# Step 4: build a little hut with the Build Hammer.
	ps.inventory.add("build_hammer", 1)
	ps.inventory.add("plank_root", 80)
	ps.inventory.add("cut_stone", 40)
	ps.inventory.add("copper_ingot", 6)
	_to_hotbar(ps, "build_hammer")
	dwarf._pitch = -0.3
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var base: Vector3 = _main.world.maker.find_floor(dwarf.global_position.x + fwd.x * 5.0, dwarf.global_position.z + fwd.z * 5.0, dwarf.global_position.y + 2.0)
	var results := []
	var plan := [["floor", "cut_stone", Vector3(0, 0, 0), 0], ["floor", "cut_stone", Vector3(2, 0, 0), 0],
		["wall", "plank_root", Vector3(0, 0.25, -1.0), 0], ["wall", "plank_root", Vector3(2, 0.25, -1.0), 0],
		["doorway", "plank_root", Vector3(0, 0.25, 1.0), 0], ["wall", "plank_root", Vector3(2, 0.25, 1.0), 0],
		["wall", "plank_root", Vector3(-1.0, 0.25, 0), 1], ["wall", "plank_root", Vector3(3.0, 0.25, 0), 1],
		["pillar", "cut_stone", Vector3(3.0, 0.25, 1.0), 0]]
	var origin: Vector3 = Pieces.snap("floor", base, Vector3.UP, 0.0, 0).pos
	for step in plan:
		var pos: Vector3 = origin + step[2]
		pos.y = _main.world.maker.find_floor(pos.x, pos.z, origin.y + 2.0).y + step[2].y if step[0] != "floor" else _main.world.maker.find_floor(pos.x, pos.z, origin.y + 2.0).y
		results.append("%s:%s" % [step[0], auth.builder.request_place(auth.local_peer_id(), step[0], step[1], pos, step[3])])
	await _wait(1.2)
	_report.append("step 4: " + ", ".join(results))
	_report.append("step 4: %d pieces stand" % auth.builder.structure.pieces.size())
	await _shot("12_hut")
	_main.hud.set_build_menu_open(true)
	await _wait(0.5)
	await _shot("13_build_menu")
	_main.hud.set_build_menu_open(false)
	# Step 4: place the starter lodge blueprint and feed its Builder's Chest.
	var json := FileAccess.get_file_as_string("res://blueprints/small_rootwood_lodge.dwbp")
	var bp_origin: Vector3 = _main.world.maker.find_floor(dwarf.global_position.x - fwd.x * 8.0, dwarf.global_position.z - fwd.z * 8.0, dwarf.global_position.y + 3.0).round()
	var chest_at: Vector3 = _main.world.maker.find_floor(bp_origin.x + 5.0, bp_origin.z, bp_origin.y + 3.0)
	var placed_bp := auth.builder.request_place_blueprint(auth.local_peer_id(), json, bp_origin, 0, chest_at)
	_report.append("step 4: blueprint placed: '%s'" % placed_bp)
	dwarf._yaw += PI
	dwarf._pitch = -0.25
	await _wait(1.0)
	await _shot("14_blueprint_ghost")
	if not auth.builder.sites.is_empty():
		var box_id: int = auth.builder.sites.keys()[0]
		for item in {plank_root = 39, cut_stone = 36, copper_ingot = 2}:
			auth.storage.put(box_id, item, {plank_root = 39, cut_stone = 36, copper_ingot = 2}[item])
		await _wait(12.0)
		_report.append("step 4: builder's chest says: %s" % auth.builder.site_status(box_id))
		await _shot("15_lodge_building")
	auth.request_select_slot(auth.local_peer_id(), 0)
	# Step 5: a fight. Sword in hand, back lantern on, a pack of monsters in front.
	ps.inventory.add("sword_stone", 1)
	ps.inventory.add("shield_stone", 1)
	ps.inventory.add("lantern_back", 1)
	_to_hotbar(ps, "sword_stone")
	var mm: MonsterManager = auth.monsters
	var ahead := dwarf.global_position - Basis(Vector3.UP, dwarf._yaw).z * 3.5
	for k in [["mossnipper", Vector3(0, 0, 0), true], ["mossnipper", Vector3(1.2, 0, 0.6), false], ["rustwight", Vector3(-1.4, 0, 0.5), false], ["cairnling", Vector3(0.5, 0, -2.0), false]]:
		var at: Vector3 = _main.world.maker.find_floor(ahead.x + k[1].x, ahead.z + k[1].z, dwarf.global_position.y + 2.0)
		mm._ev_spawn(mm._next_uid, k[0], at + Vector3.UP * 0.3, k[2], 99)
	dwarf._pitch = -0.2
	await _wait(1.5)
	await _shot("16_monsters")
	var hp_before := 0.0
	for m: Monster in mm.monsters.values():
		hp_before += m.hp
	for i in 6:
		Input.action_press("dig")
		await _wait(0.1)
		Input.action_release("dig")
		await _wait(0.6)
	await _shot("17_fighting")
	var hp_after := 0.0
	for m: Monster in mm.monsters.values():
		hp_after += m.hp
	_report.append("step 5: monsters lost %.0f HP to 6 sword swings; %d still alive; our health %.0f, fighting skill XP %d" % [
		hp_before - hp_after, mm.monsters.size(), ps.vitals.health, ps.progress.skill_xp.fighting])
	for m: Monster in mm.monsters.values():
		mm._ev_remove(m.uid)
	ps.vitals.health = ps.vitals.max_health()
	auth.request_select_slot(auth.local_peer_id(), 0)
	# Step 6: visit the special places.
	var maker: CaveMaker = _main.world.maker
	var mark: Dictionary = maker.pois_of("marking")[0]
	await _teleport(dwarf, mark.pos + mark.normal * 3.0, mark.pos + Vector3.UP * 1.2)
	await _shot("18_wall_marking")
	_report.append("step 6: read marking -> %s" % auth.request_poi(auth.local_peer_id(), mark.id))
	var shrine: Dictionary = maker.pois_of("shrine")[0]
	await _teleport(dwarf, shrine.pos + shrine.normal * 2.5, shrine.pos)
	await _shot("19_rune_shrine")
	var ruin: Dictionary = maker.pois_of("ruin")[0]
	await _teleport(dwarf, ruin.pos + Vector3(0, 1.0, 6.0), ruin.pos)
	await _shot("20_ruin")
	_main.hud.set_map_open(true)
	await _wait(0.5)
	await _shot("21_map_with_clue")
	_main.hud.set_map_open(false)
	auth.monsters.enabled = true
	var hall: Dictionary = maker.pois_of("great_hall")[0]
	await _teleport(dwarf, hall.pos + Vector3(0, 1.0, 12.0), hall.pos + Vector3.UP * 2.0)
	auth.monsters._wake_bosses()
	await _wait(2.0)
	await _shot("22_brask")
	var lair: Dictionary = maker.lair_poi()
	await _teleport(dwarf, lair.pos + Vector3(0, 1.0, 12.0), lair.pos + Vector3.UP * 3.0)
	auth.monsters._wake_bosses()
	await _wait(2.5)
	await _shot("23_orrumhal")
	var bosses := []
	for m: Monster in auth.monsters.monsters.values():
		if m.is_boss():
			bosses.append(m.data.name.get_slice(",", 0))
	_report.append("step 6: bosses awake: %s; raid sources found: %s" % [bosses, auth.world_state.lairs_found])
	for m: Monster in auth.monsters.monsters.values():
		auth.monsters._ev_remove(m.uid)
	await _visit_jungle(dwarf, ps)
	# Look up at the ceiling for hanging roots.
	dwarf._pitch = 0.6
	await _wait(0.8)
	await _shot("09_ceiling_roots")

	var avg := 0.0
	var low := 9999.0
	for f in _fps_samples:
		avg += f
		low = minf(low, f)
	if not _fps_samples.is_empty():
		avg /= _fps_samples.size()
	_report.append("fps: average %.0f, lowest %.0f" % [avg, low])
	print("\n===== AUTOPILOT REPORT =====")
	for line in _report:
		print("  ", line)
	print("============================")
	get_tree().quit()


## The Fungal Jungle: the gate, digging the plug, giant mushrooms, jungle monsters, Thallus.
func _visit_jungle(dwarf: Dwarf, ps: GameAuthority.PlayerState) -> void:
	var auth: GameAuthority = _main.authority
	var maker: CaveMaker = _main.world.maker
	auth.monsters.enabled = false
	var gate: Dictionary = maker.pois_of("gate", "mossy")[0]
	await _teleport(dwarf, gate.pos + Vector3(-6.0, 0.6, 0), gate.pos + Vector3.UP * 1.0)
	await _shot("24_jungle_gate")
	dwarf.global_position = gate.pos + Vector3(-2.0, 0.2, 0)
	var stone_try := auth.request_hit(auth.local_peer_id(), gate.pos + Vector3(0.05, 0.4, 0), Vector3.LEFT)
	ps.inventory.add("pickaxe_copper", 1)
	_to_hotbar(ps, "pickaxe_copper")
	var digs := 0
	for step in 8:
		dwarf.global_position = gate.pos + Vector3(-2.0 + step * 0.7, 0.2, 0)
		var at: Vector3 = gate.pos + Vector3(step * 0.7 + 0.3, 0.4, 0)
		for i in 12:
			var r := auth.request_hit(auth.local_peer_id(), at, Vector3.LEFT)
			if r.get("state") != "hit":
				if r.get("state") == "dug":
					digs += 1
				break
		await _wait(0.15)
	var open: bool = _main.world.sdf_at(maker.gates[0].pos + Vector3(0, -0.6, 0)) > 0.0
	_report.append("step 7: stone pickaxe on the plug -> %s; copper pickaxe dug %d times; plug open: %s" % [stone_try.get("state"), digs, open])
	await _teleport(dwarf, gate.pos + Vector3(-4.0, 0.6, 0), gate.pos + Vector3(6.0, 0.6, 0))
	await _shot("25_through_the_plug")
	var grove: Dictionary = maker.pois_of("lantern_grove")[0]
	await _teleport(dwarf, grove.pos + Vector3(0, 1.5, 14.0), grove.pos + Vector3.UP * 2.5)
	await _shot("26_giant_mushrooms")
	var mm := auth.monsters
	mm.set_physics_process(false)  # a still life: they'd knock the robot out before the picture
	var kinds := ["wheezecap", "needlemite", "husk_charger", "gill_stalker", "cap_spitter"]
	var fwd := Vector3(-sin(dwarf._yaw), 0, -cos(dwarf._yaw))
	var side := fwd.cross(Vector3.UP)
	for i in kinds.size():
		var at: Vector3 = dwarf.global_position + fwd * 6.0 + side * (i - 2) * 2.2
		at = maker.find_floor(at.x, at.z, dwarf.global_position.y + 2.0)
		mm._ev_spawn(mm._next_uid, kinds[i], at + Vector3.UP * 0.3, i == 1, 999)
		mm._next_uid += 1
	await _wait(0.8)
	var look := dwarf.global_position + fwd * 6.0
	await _teleport(dwarf, dwarf.global_position, look)
	await _shot("27_jungle_monsters")
	for m: Monster in mm.monsters.values():
		mm._ev_remove(m.uid)
	mm.set_physics_process(true)
	_main.hud.set_map_open(true)
	await _wait(0.5)
	await _shot("28_jungle_map")
	_main.hud.set_map_open(false)
	mm.enabled = true
	var lair: Dictionary = maker.lair_poi("fungal")
	await _teleport(dwarf, lair.pos + Vector3(0, 1.0, 13.0), lair.pos + Vector3.UP * 3.0)
	mm._wake_bosses()
	await _wait(2.5)
	await _shot("29_thallus")
	var bosses := []
	for m: Monster in mm.monsters.values():
		if m.is_boss():
			bosses.append(m.data.name.get_slice(",", 0))
	_report.append("step 7: jungle bosses awake: %s" % [bosses])
	for m: Monster in mm.monsters.values():
		mm._ev_remove(m.uid)
	mm.enabled = false


## Like a player dragging an item onto hotbar slot 8 and selecting it.
func _to_hotbar(ps: GameAuthority.PlayerState, item: String) -> void:
	var auth: GameAuthority = _main.authority
	for i in Inventory.SIZE:
		if ps.inventory.get_slot(i).get("id", "") == item:
			if i >= Inventory.HOTBAR_SIZE:
				auth.request_swap(auth.local_peer_id(), i, Inventory.HOTBAR_SIZE - 1)
				i = Inventory.HOTBAR_SIZE - 1
			auth.request_select_slot(auth.local_peer_id(), i)
			return


## Jump somewhere for a screenshot: wait until the cave there is built, then look at `look_at`.
func _teleport(dwarf: Dwarf, to: Vector3, look_at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = to
	var w: World = _main.world
	for i in 400:
		if w.terrain.is_area_meshed(AABB(to - Vector3.ONE * 6, Vector3.ONE * 12)):
			break
		await get_tree().process_frame
	var dir := look_at - (to + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(0.6)
	dwarf.set_physics_process(true)
	await _wait(0.4)
