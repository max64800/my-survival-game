extends Node
## Outpost check: starts a fresh world, moves the dwarf to the Fallen Outpost's cavern (so its rock loads and the
## fort gets built), then photographs it from outside the gate, from a side, and from inside the yard, and quits.
## Run:  godot --audio-driver Dummy --path . -- outpostcheck seed=42 shots=<folder>

var _main: Node
var _shots := "user://outpostcheck"


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
	while not _main.is_ready_to_play() and waited < 120.0:
		await _wait(0.25)
		waited += 0.25
	var plan := RuinTower.load_plan(RuinOutpost.OUTPOST_PLAN)
	var spot := RuinOutpost.pick(_main.world.maker, float(plan.radius), float(plan.height))
	if spot.is_empty():
		print("OUTPOSTCHECK no cavern found")
		get_tree().quit()
		return
	print("OUTPOSTCHECK spot ", spot, " (%.0f m from the start)" % Vector2(spot.pos.x - _main.world.maker.cavern_spawn.x, spot.pos.z - _main.world.maker.cavern_spawn.z).length())
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var o: Vector3 = spot.pos
	var basis := Basis(Vector3.UP, spot.turn * PI / 2.0)
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	dwarf.global_position = o + basis * Vector3(0, 2.0, 24.0)
	waited = 0.0
	while RuinOutpost.built_origin == Vector3.INF and waited < 240.0:
		await _wait(0.5)
		waited += 0.5
	if RuinOutpost.built_origin == Vector3.INF:
		print("OUTPOSTCHECK it was never built")
		get_tree().quit()
		return
	print("OUTPOSTCHECK built after %.0f s" % waited)
	await _wait(2.0)
	for v in [["front", Vector3(0, 0, 27.0), 6.0], ["side", Vector3(-26.0, 0, 10.0), 6.0], ["yard", Vector3(4.0, 0, 6.0), 2.0]]:
		var p: Vector3 = o + basis * v[1]
		await _teleport(dwarf, Vector3(p.x, o.y + 0.3, p.z), o + Vector3.UP * v[2])
		await RenderingServer.frame_post_draw
		print("OUTPOSTCHECK shot ", _main.take_screenshot(_shots.path_join("outpost_%s.png" % v[0])))
	get_tree().quit()


func _teleport(dwarf: Dwarf, to: Vector3, look_at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = to
	for i in 400:
		if _main.world.terrain.is_area_meshed(AABB(to - Vector3.ONE * 6, Vector3.ONE * 12)):
			break
		await get_tree().process_frame
	var dir := look_at - (to + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(1.0)
