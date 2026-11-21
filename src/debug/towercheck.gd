extends Node
## Tower check (F254): starts a fresh world, waits until the ruined Stone Watchtower in the first cave is built,
## then photographs it from the front and from the side, and quits.
## Run:  godot --audio-driver Dummy --path . -- towercheck seed=42 shots=<folder>

var _main: Node
var _shots := "user://towercheck"


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
	while (not _main.is_ready_to_play() or RuinTower.last_origin == Vector3.INF) and waited < 120.0:
		await _wait(0.25)
		waited += 0.25
	if RuinTower.last_origin == Vector3.INF:
		print("TOWERCHECK no tower was built")
		get_tree().quit()
		return
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var o: Vector3 = RuinTower.last_origin
	var basis := Basis(Vector3.UP, RuinTower.last_turn * PI / 2.0)
	var dwarf: Dwarf = _main.dwarf
	for v in [["front", Vector3(0, 0, 13.0)], ["side", Vector3(-10.0, 0, 8.0)], ["back", Vector3(4.0, 0, -12.0)]]:
		var p: Vector3 = o + basis * v[1]
		var fl: Vector3 = _main.world.maker.find_floor(p.x, p.z, o.y + 4.0)
		await _teleport(dwarf, fl + Vector3.UP * 0.2, o + Vector3.UP * 4.0)
		await RenderingServer.frame_post_draw
		print("TOWERCHECK shot ", _main.take_screenshot(_shots.path_join("tower_%s.png" % v[0])))
	# The ruin camp (ruin junk step 3): stand 3 m from its cold campfire, toward the tower, and look down at it.
	for j in RuinJunk.load_list("tower"):
		if j.get("free", false) and String(j.model).ends_with("junk_campfire_cold.glb"):
			var c: Vector3 = o + basis * Vector3(float(j.pos[0]), 0.0, float(j.pos[2]))
			var back: Vector3 = (o - c).normalized()
			var p: Vector3 = c + back * 4.5
			var fl: Vector3 = _main.world.maker.find_floor(p.x, p.z, o.y + 4.0)
			var cf: Vector3 = _main.world.maker.find_floor(c.x, c.z, o.y + 4.0)
			await _teleport(dwarf, fl + Vector3.UP * 0.2, cf + back.cross(Vector3.UP) * 1.3)  # (aim beside it: the dwarf hides the middle)
			await RenderingServer.frame_post_draw
			print("TOWERCHECK shot ", _main.take_screenshot(_shots.path_join("tower_camp.png")))
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
