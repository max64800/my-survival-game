extends Node
## Spire check (F479): starts a fresh world, moves the dwarf to the Lantern Spire's cavern (so its rock loads and the
## ruin gets built), then photographs it from the front, from beside its fallen top, and from further off, and quits.
## Run:  godot --audio-driver Dummy --path . -- spirecheck seed=42 shots=<folder>

var _main: Node
var _shots := "user://spirecheck"


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
	var spot: Dictionary = _main.world.maker.spire_spot
	if spot.is_empty():
		print("SPIRECHECK no cavern found")
		get_tree().quit()
		return
	print("SPIRECHECK spot ", spot, " (%.0f m from the start)" % Vector2(spot.pos.x - _main.world.maker.cavern_spawn.x, spot.pos.z - _main.world.maker.cavern_spawn.z).length())
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var o: Vector3 = spot.pos
	var basis := Basis(Vector3.UP, spot.turn * PI / 2.0)
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	dwarf.global_position = o + basis * Vector3(-6.0, 2.0, 16.0)
	waited = 0.0
	while RuinSpire.built_origin == Vector3.INF and waited < 240.0:
		await _wait(0.5)
		waited += 0.5
	if RuinSpire.built_origin == Vector3.INF:
		print("SPIRECHECK it was never built")
		get_tree().quit()
		return
	print("SPIRECHECK built after %.0f s" % waited)
	for l in [[Vector3(0, 16.0, 0), 45.0], [Vector3(8.0, 6.0, 6.0), 18.0]]:  # work lights: its fire bowl lies fallen, so it's dark
		var light := OmniLight3D.new()
		light.omni_range = l[1]
		light.light_energy = 2.5
		_main.add_child(light)
		light.global_position = o + basis * (l[0] as Vector3)
	dwarf.model.visible = false  # (out of the photo)
	await _wait(2.0)
	# [name, where the dwarf stands, what it looks at] in the ruin's own frame (the top fell toward +x +z)
	for v in [["front", Vector3(-2.0, 0, 15.0), Vector3(0, 5.0, 0)], ["wreck", Vector3(-4.0, 0, 15.0), Vector3(9.0, 1.0, 6.0)],
			["far", Vector3(-17.0, 0, 17.0), Vector3(4.0, 4.0, 3.0)]]:
		var p: Vector3 = o + basis * v[1]
		var f: float = _main.world.maker.find_floor(p.x, p.z, o.y + 4.0).y
		await _teleport(dwarf, Vector3(p.x, f + 0.3, p.z), o + basis * v[2])
		await RenderingServer.frame_post_draw
		print("SPIRECHECK shot ", _main.take_screenshot(_shots.path_join("spire_%s.png" % v[0])))
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
