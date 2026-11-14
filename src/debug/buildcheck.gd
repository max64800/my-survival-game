extends Node
## Build check: puts every building piece in each Mossy material in rows, and each ready-made
## blueprint, then takes pictures (building polish spec §8).
## Run:  godot --audio-driver Dummy --path . -- buildcheck seed=42 shots=/some/folder

var _main: Node
var _shots := "user://buildcheck"
var _uid := 900000


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join(name + ".png"))


func _place(piece: String, family: String, pos: Vector3, rot: int) -> void:
	_main.authority.builder._ev_add_piece(_uid, piece, family, pos, rot, true)
	_uid += 1


## Takes down everything this robot built.
func _clear() -> void:
	var b: Builder = _main.authority.builder
	for uid in b.structure.pieces.keys():
		if int(uid) >= 900000:
			b._ev_remove_piece(uid)


func _look(dwarf: Dwarf, from: Vector3, at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = from
	var d := at - (from + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-d.x, -d.z)
	dwarf._pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var dwarf: Dwarf = _main.dwarf
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_main.hud.visible = false
	dwarf._zoom = 3.0
	# Build up in the air above the start, on a big stone foundation, so the cave doesn't get in the way.
	var base := (_main.world.maker.cavern_spawn as Vector3).round() + Vector3(0, 3, 0)
	# A work light for the photos (only in this robot run), following the camera's target.
	var lamp := OmniLight3D.new()
	lamp.omni_range = 18.0
	lamp.light_energy = 2.5
	lamp.shadow_enabled = true
	add_child(lamp)
	var n := 0
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("family="):
			only = arg.trim_prefix("family=")
		if arg == "part=extras":
			await _extras(dwarf, base, lamp)
			get_tree().quit()
			return
	# Six pieces at a time, 3.5 m apart, photographed from 7 m; built where the last batch was
	# (each batch is cleared first), so they never run into the cave walls.
	for fam in Pieces.MOSSY_FAMILIES:
		if only != "" and fam != only:
			continue
		var batch: Array = []
		for id in Pieces.LIST:
			if Pieces.allowed(id, fam) and Pieces.needed_level(id, fam) < 99:
				batch.append(id)
		var i := 0
		while i < batch.size():
			_clear()
			for k in 6:
				if i + k >= batch.size():
					break
				var p := base + Vector3((k - 2.5) * 3.5, 0, 0)
				_place("foundation", "cut_stone", p + Vector3(0, -1, 0), 0)
				_place("foundation", "cut_stone", p + Vector3(0, -1, -2), 0)
				_place(batch[i + k], fam, p, 0)
			await _wait(0.6)
			lamp.global_position = base + Vector3(-4, 6, 6)
			_look(dwarf, base + Vector3(0, 1.5, 7.5), base + Vector3(0, 1.0, 0))
			dwarf._zoom = 5.0
			await _wait(0.8)
			await _shot("%02d_%s_%s" % [n, fam, batch[i]])
			n += 1
			i += 6
	_clear()
	# The blueprints, side by side further along.
	var bx := base + Vector3(0, 0, 20)
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		for p in bp.world_pieces(bx, 0):
			_place(p.piece, p.family, p.pos, p.rot)
		await _wait(0.8)
		lamp.global_position = bx + Vector3(6, 9, 10)
		_look(dwarf, bx + Vector3(7, 4, 12), bx + Vector3(0, 2, 0))
		dwarf._zoom = 6.0
		await _wait(1.0)
		await _shot("%02d_blueprint_%s" % [n, id])
		n += 1
		bx += Vector3(16, 0, 0)
	get_tree().quit()


## `part=extras`: a door (closed, then open), a built ladder, the Kiln and Smelter, and three Ore Crates
## (empty, half, full) to check the ore pile rises.
func _extras(dwarf: Dwarf, base: Vector3, lamp: OmniLight3D) -> void:
	var auth: GameAuthority = _main.authority
	for x in range(-3, 4):
		for z in range(-2, 2):
			_place("foundation", "cut_stone", base + Vector3(x * 2, -1, z * 2), 0)
	_place("doorway", "plank_root", base + Vector3(-4, 0, -1), 0)
	_place("door", "plank_root", base + Vector3(-4, 0, -1), 0)
	var door_uid := _uid - 1
	_place("wall", "plank_root", base + Vector3(-2, 0, -1), 0)
	_place("ladder", "plank_root", base + Vector3(-2, 0, -0.75), 0)
	auth._ev_place_station(990001, "kiln", base + Vector3(1, 0, -1), 0.0)
	auth._ev_place_station(990002, "smelter", base + Vector3(3, 0, -1), 0.0)
	var fills := [0, 150, 500]
	for i in 3:
		var id: int = auth.storage.create_box("crate_ore", base + Vector3(0.5 + i * 1.6, 0, 1.5), 0.0)
		if fills[i] > 0:
			auth.storage.put(id, "copper_ore", fills[i])
	await _wait(0.8)
	lamp.global_position = base + Vector3(0, 5, 5)
	_look(dwarf, base + Vector3(0, 1.8, 6.5), base + Vector3(0, 0.7, 0))
	dwarf._zoom = 5.0
	await _wait(1.0)
	await _shot("extras_closed")
	auth.builder._ev_door(door_uid, true)
	await _wait(0.8)
	await _shot("extras_door_open")
	_look(dwarf, base + Vector3(2.4, 1.2, 4.0), base + Vector3(2.0, 0.2, 1.5))
	dwarf._zoom = 2.5
	await _wait(0.8)
	await _shot("extras_crates")
