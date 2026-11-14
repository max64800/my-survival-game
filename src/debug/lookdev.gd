extends Node
## Look test: visits a few fixed spots (Mossy spawn, a ruin, the great hall, the Fungal Jungle),
## takes the same screenshots every time, prints the frame rate, then quits.
## Use it to compare "before" and "after" for any visual change.
##   godot --audio-driver Dummy --path . -- seed=42 lookdev shots=/some/folder
## (Tip: put "autopilot" in the shots folder name so the OBS auto-recorder skips the run.)

var _main: Node
var _shots := "user://lookdev"
var _fps: Array[float] = []
var _clean := false  ## true = hide the HUD in the pictures


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
		elif arg == "clean":
			_clean = true
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _process(_delta: float) -> void:
	if _main.is_ready_to_play():
		_fps.append(Engine.get_frames_per_second())


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	print("  screenshot: ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _teleport(dwarf: Dwarf, to: Vector3, look_at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = to
	var w: World = _main.world
	for i in 400:
		if w.terrain.is_area_meshed(AABB(to - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await get_tree().process_frame
	var dir := look_at - (to + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(0.6)
	dwarf.set_physics_process(true)
	await _wait(1.2)


## A camera in front of the dwarf, looking at them (the normal camera only sees their back).
func _portrait(dwarf: Dwarf, name: String, delay: float = 0.3, side_amount: float = 0.9) -> void:
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	cam.global_position = dwarf.global_position + fwd * 2.6 + side * side_amount * 2.6 + Vector3.UP * 1.3
	cam.look_at(dwarf.global_position + Vector3.UP * 0.75)
	cam.make_current()
	await _wait(delay)
	await _shot(name)
	dwarf.camera.make_current()
	cam.queue_free()


func _run() -> void:
	while not _main.is_ready_to_play():
		await _wait(0.25)
	var dwarf: Dwarf = _main.dwarf
	var maker: CaveMaker = _main.world.maker
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_main.hud.set_paused(false)
	if _clean:
		_main.hud.visible = false
	await _wait(2.0)
	await _shot("a_spawn")
	await _portrait(dwarf, "b_dwarf_portrait")
	await _portrait(dwarf, "b1_dwarf_side", 0.3, -1.0)
	dwarf.model.swing(0.55)
	await _portrait(dwarf, "b2_dig_windup", 0.18, 1.2)
	dwarf.model.swing(0.55)
	await _wait(0.6)
	dwarf.model.swing(0.55)
	await _portrait(dwarf, "b3_dig_strike", 0.32, 1.2)
	await _wait(0.6)
	dwarf.bot_move = Vector2(0, -1)
	await _wait(0.6)
	await _portrait(dwarf, "b4_walking", 0.02, 1.4)
	dwarf.bot_move = Vector2.ZERO
	dwarf._yaw += PI * 0.66
	dwarf._pitch = 0.1
	await _wait(0.8)
	await _shot("c_spawn_look")
	# Walk forward for a moment (animations).
	dwarf.bot_move = Vector2(0, -1)
	await _wait(0.7)
	await _shot("d_walking")
	dwarf.bot_move = Vector2.ZERO
	var ruin: Dictionary = maker.pois_of("ruin")[0]
	await _teleport(dwarf, ruin.pos + Vector3(0, 1.0, 6.0), ruin.pos)
	await _shot("e_ruin")
	var hall: Dictionary = maker.pois_of("great_hall")[0]
	await _teleport(dwarf, hall.pos + Vector3(0, 1.0, 12.0), hall.pos + Vector3.UP * 2.0)
	await _shot("f_great_hall")
	var grove: Dictionary = maker.pois_of("lantern_grove")[0]
	await _teleport(dwarf, grove.pos + Vector3(0, 1.5, 14.0), grove.pos + Vector3.UP * 2.5)
	await _shot("g_jungle_grove")
	await _portrait(dwarf, "h_jungle_portrait")
	var avg := 0.0
	var low := 9999.0
	for f in _fps:
		avg += f
		low = minf(low, f)
	if not _fps.is_empty():
		avg /= _fps.size()
	print("  fps: average %.0f, lowest %.0f" % [avg, low])
	get_tree().quit()
