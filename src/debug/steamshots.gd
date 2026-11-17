extends Node
## Steam shots: store-page pictures at full window size, no HUD (owner, Nov 18: dwarf facing the camera with the
## star ceiling and the watchtower behind; the tower; the Rock Beetle; the Rock Snail; no bat yet).
## Run:  godot --audio-driver Dummy --resolution 1920x1080 --path . -- steamshots ruin=1 seed=42 shots=<folder>

var _main: Node
var _shots := "user://steamshots"
var _cam: Camera3D
var _light: OmniLight3D


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
	# shortcut: on the Mac is_ready_to_play() never turned true for robots (autopilot said ready=false too), so wait
	# for the tower and the rock around it instead; switch back to is_ready_to_play() once that's fixed.
	while RuinTower.last_origin == Vector3.INF and waited < 300.0:
		await _wait(0.25)
		waited += 0.25
	print("STEAMSHOTS tower found after %.0f s, ready=%s" % [waited, _main.is_ready_to_play()])
	while not _main.is_ready_to_play() and waited < 400.0:  # the Mac needs ~110 s to build the rock around you
		await _wait(0.5)
		waited += 0.5
	print("STEAMSHOTS ready=%s after %.0f s" % [_main.is_ready_to_play(), waited])
	_main.hud.set_loading(false)  # lift the "Digging out the cave…" cover either way
	await _wait(3.0)
	if RuinTower.last_origin == Vector3.INF:
		print("STEAMSHOTS no tower was built")
		get_tree().quit()
		return
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_main.hud.visible = false
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	var o: Vector3 = RuinTower.last_origin
	var b := Basis(Vector3.UP, RuinTower.last_turn * PI / 2.0)
	var out: Vector3 = b * Vector3(0, 0, 1)  # from the tower towards its front
	var side: Vector3 = b * Vector3(1, 0, 0)
	_cam = Camera3D.new()
	_cam.fov = 60.0
	_main.add_child(_cam)
	_cam.current = true
	_light = OmniLight3D.new()  # a soft lantern near the camera
	_light.light_color = Color(1.0, 0.8, 0.55)
	_light.omni_range = 10.0
	_light.light_energy = 1.4
	_main.add_child(_light)

	# 1. The dwarf facing us, the tower and the star ceiling behind him.
	var stand := _floor(o + out * 9.0, o.y + 4.0)
	await _mesh_around(stand)
	dwarf.global_position = stand + Vector3.UP * 0.05
	dwarf._yaw = atan2(-out.x, -out.z)  # look along +out: away from the tower, at the camera (same rule as towercheck)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(1.5)
	_light.light_energy = 0.0  # his own lantern is enough; the extra lamp burned him white
	await _shoot("01_dwarf_tower_stars", stand + out * 4.2 + side * 1.6 + Vector3.UP * 1.0, stand + Vector3.UP * 2.2 - out * 4.0)
	await _shoot("02_dwarf_closeup", stand + out * 2.0 + side * 0.4 + Vector3.UP * 1.2, stand + Vector3.UP * 1.25)

	_light.light_energy = 1.4
	# 2. The tower on its own, wide, with the dwarf small in front for scale.
	dwarf.global_position = _floor(o + out * 6.0 + side * 2.0, o.y + 4.0)
	await _shoot("03_tower_wide", o + out * 17.0 - side * 4.0 + Vector3.UP * 3.0, o + Vector3.UP * 4.5)
	await _shoot("04_tower_low", o + out * 11.0 + side * 6.0 + Vector3.UP * 0.6, o + Vector3.UP * 6.0)

	# 3. The star ceiling: look up from beside the tower.
	await _shoot("05_star_ceiling", o + out * 11.0 + side * 6.0 + Vector3.UP * 0.6, o + side * 2.0 + Vector3.UP * 16.0)

	# 4. The Rock Beetle winding up its charge, and the Rock Snail, a few steps from the tower.
	dwarf.visible = false
	var mm: MonsterManager = GameAuthority.instance.monsters
	var made := {}
	for kind in ["rock_beetle", "rock_snail"]:
		var at := _floor(o + out * 7.0 + side * (-2.5 if kind == "rock_beetle" else 2.5), o.y + 4.0) + Vector3.UP * 0.3
		var uid: int = mm._next_uid
		mm._ev_spawn(uid, kind, at, false, 99, "")
		mm._next_uid = uid + 1
		made[kind] = mm.monsters[uid]
		(made[kind] as Monster).state = Monster.State.IDLE
	mm.set_physics_process(false)  # a still life
	await _wait(0.5)
	for kind in made:
		var m: Monster = made[kind]
		var to_cam := out + side * (0.5 if kind == "rock_beetle" else -0.5)
		m.model.rotation.y = atan2(to_cam.x, to_cam.z) + (PI if kind == "rock_snail" else 0.0)  # face the camera (the snail model is built facing the other way)
		for tag in m.find_children("*", "Label3D", true, false):
			(tag as Label3D).visible = false  # no name tags on store pictures
	(made["rock_beetle"] as Monster).show_tell(3.0, "Charge")
	await _wait(1.0)
	var beetle: Vector3 = (made["rock_beetle"] as Monster).global_position
	await _shoot("06_rock_beetle_charge", beetle + out * 2.8 + side * 0.6 + Vector3.UP * 1.3, beetle + Vector3.UP * 0.35)
	var snail: Vector3 = (made["rock_snail"] as Monster).global_position
	await _shoot("07_rock_snail", snail + out * 2.6 - side * 0.6 + Vector3.UP * 1.2, snail + Vector3.UP * 0.45)
	await _shoot("08_beetle_snail_tower", o + out * 10.5 + Vector3.UP * 1.6, o + out * 6.5 + Vector3.UP * 1.0)
	print("STEAMSHOTS done: ", _shots)
	get_tree().quit()


func _floor(p: Vector3, from_y: float) -> Vector3:
	return _main.world.maker.find_floor(p.x, p.z, from_y)


func _mesh_around(p: Vector3) -> void:
	for i in 600:
		if _main.world.terrain.is_area_meshed(AABB(p - Vector3.ONE * 10, Vector3.ONE * 20)):
			return
		await get_tree().process_frame


func _shoot(name: String, cam_at: Vector3, look: Vector3) -> void:
	await _mesh_around(cam_at)
	_cam.global_position = cam_at
	_cam.look_at(look)
	_light.global_position = cam_at + Vector3.UP * 0.5
	await _wait(0.8)
	await RenderingServer.frame_post_draw
	print("STEAMSHOTS shot ", _main.take_screenshot(_shots.path_join(name + ".png")))
