extends Node
## Ruin check: visits old dwarf stonework (ruins, column rows, the Great Hall) and takes a
## picture of each, so the looks can be checked without playing to them.
## Run:  godot --audio-driver Dummy --path . -- ruincheck seed=42 shots=/some/folder

var _main: Node
var _shots := "user://ruincheck"


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var dwarf: Dwarf = _main.dwarf
	var maker: CaveMaker = _main.world.maker
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_main.hud.set_paused(false)
	_main.hud.visible = false
	var counts := {}
	for p in maker.pois:
		counts[p.type] = counts.get(p.type, 0) + 1
	print("  places: ", counts)
	var n := 0
	for type in ["colonnade", "ruin", "great_hall", "colonnade"]:
		var list := maker.pois_of(type, "mossy")
		if list.is_empty():
			continue
		var p: Dictionary = list[mini(n % 2, list.size() - 1)]
		var c: Vector3 = p.pos
		var back := 11.0 if type != "ruin" else 8.0
		var from := maker.find_floor(c.x + back, c.z + back * 0.4, c.y + 2.0) + Vector3.UP * 1.0
		dwarf.set_physics_process(false)
		dwarf.global_position = from
		for i in 400:
			if _main.world.terrain.is_area_meshed(AABB(c - Vector3.ONE * 8, Vector3.ONE * 16)):
				break
			await get_tree().process_frame
		var dir := c + Vector3.UP * 2.5 - (from + Vector3.UP * 1.5)
		dwarf._yaw = atan2(-dir.x, -dir.z)
		dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -0.6, 0.6)
		dwarf._zoom = 5.0
		await _wait(1.2)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("%02d_%s.png" % [n, type]))
		n += 1
	get_tree().quit()
