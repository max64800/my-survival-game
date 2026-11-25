extends Node
## Dungeon check: starts a fresh world, takes the dwarf to the first dungeon (Mossgate Hold) and photographs the way in
## from the cave and a few rooms from inside (a bright work light hangs over the camera: no torches yet), then quits.
## Run:  godot --audio-driver Dummy --path . -- dungeoncheck claude=dungeon seed=42 shots=<folder>

var _main: Node
var _shots := "user://dungeoncheck"
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
	while not _main.is_ready_to_play() and waited < 120.0:
		await _wait(0.25)
		waited += 0.25
	var maker: CaveMaker = _main.world.maker
	if maker.dungeons.is_empty():
		print("DUNGEONCHECK no dungeon in this world (layout %d)" % maker.made_layout)
		get_tree().quit()
		return
	var d: Dictionary = maker.dungeons[0]
	print("DUNGEONCHECK %s at %s, turn %d (%.0f m from the start)" % [d.map.name, d.mouth, d.turn,
		Vector2(d.mouth.x - maker.cavern_spawn.x, d.mouth.z - maker.cavern_spawn.z).length()])
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_light = OmniLight3D.new()
	_light.omni_range = 26.0
	_light.light_energy = 0.0 if "dark" in OS.get_cmdline_user_args() else 2.5  # "dark": only the game's own lights
	_light.shadow_enabled = true
	_main.add_child(_light)
	var mx: float = d.map.mouth.x
	var mz: float = d.map.mouth.y
	var eo: float = d.entry_out
	# [name, where the dwarf stands, where he looks] in the dungeon's own metres
	var views := [
		["door", Vector3(mx + 2.0, 0.3, mz + eo + 7.0), Vector3(mx, 1.5, mz)],
		["gate_hall", Vector3(34.0, 0.3, 44.0), Vector3(30.0, 1.5, 36.0)],
		["pillar_hall", Vector3(34.0, 0.3, 29.0), Vector3(34.0, 3.0, 17.0)],
		["chasm", Vector3(34.0, 0.3, 6.0), Vector3(39.0, -6.0, 6.0)],
		["pack_hall", Vector3(58.0, 0.3, 6.0), Vector3(70.0, 2.0, 12.0)],
	]
	if "views=hald" in OS.get_cmdline_user_args():  # (F860, Nov 25: the Tomb of Hald, before/after darkening)
		views = [
			["hald_mourners", Vector3(42.0, 0.3, 60.5), Vector3(42.0, 1.8, 55.0)],
			["hald_wardens", Vector3(21.0, 0.3, 40.5), Vector3(21.0, 2.0, 31.0)],
			["hald_names", Vector3(21.0, DungeonMap.DEEP + 0.3, 18.5), Vector3(21.0, DungeonMap.DEEP + 2.0, 9.0)],
		]
	if "views=decor" in OS.get_cmdline_user_args():  # (Nov 22: the decor catalogue's pieces, one corner per photo)
		views = [
			["decor_gatekeeper", Vector3(33.0, 0.3, 41.0), Vector3(29.0, 0.6, 45.5)],
			["decor_gate_winch", Vector3(34.5, 0.3, 40.0), Vector3(38.5, 0.8, 45.8)],
			["decor_guard_cots", Vector3(55.0, 0.3, 40.5), Vector3(53.5, 0.4, 35.0)],
			["decor_guard_south", Vector3(53.0, 0.3, 39.0), Vector3(57.0, 0.4, 44.5)],
			["decor_store", Vector3(64.5, 0.3, 38.6), Vector3(66.0, 0.5, 43.5)],
			["decor_pillar_east", Vector3(41.0, 0.3, 28.6), Vector3(45.0, 0.5, 22.5)],
		]
	for v in views:
		await _teleport(DungeonMap.to_world(d, v[1]), DungeonMap.to_world(d, v[2]))
		print("DUNGEONCHECK %s: standing in '%s', looking at '%s' (open %.1f)" % [v[0], DungeonMap.space_at(d, DungeonMap.to_world(d, v[1] + Vector3.UP)), DungeonMap.space_at(d, DungeonMap.to_world(d, v[2])), maker.sdf_at(DungeonMap.to_world(d, v[2]))])
		if String(v[0]).begins_with("hald_"):
			await _wait(4.0)  # (the room's mood blends in over a few seconds: Ambience.BLEND_SPEED)
		await RenderingServer.frame_post_draw
		print("DUNGEONCHECK shot ", _main.take_screenshot(_shots.path_join("dungeon_%s.png" % v[0])))
	get_tree().quit()


func _teleport(to: Vector3, look_at: Vector3) -> void:
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	dwarf.global_position = to
	_light.global_position = to + Vector3.UP * 2.6
	for i in 600:
		if _main.world.terrain.is_area_meshed(AABB(to - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await get_tree().process_frame
	var dir := look_at - (to + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(1.5)
