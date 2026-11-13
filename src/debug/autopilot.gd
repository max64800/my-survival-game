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
