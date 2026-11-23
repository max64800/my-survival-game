extends Node
## Camera check (F807): builds a small stone room up in the air, stands the dwarf inside and takes pictures from
## outside, so the see-through circle round him shows on the wall in the way.
## Run:  godot --audio-driver Dummy --path . -- camcheck claude=camera_circle seed=42 shots=/some/folder

var _main: Node
var _shots := "user://camcheck"
var _uid := 910000


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


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var dwarf: Dwarf = _main.dwarf
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_main.hud.visible = false
	var base := (_main.world.maker.cavern_spawn as Vector3).round() + Vector3(0, 3, 0)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 18.0
	lamp.light_energy = 2.5
	lamp.shadow_enabled = true
	add_child(lamp)
	var fam := "cut_stone"
	var s: float = Pieces.LIST["wall"].size.x
	for x in range(-2, 3):
		for z in range(-2, 3):
			_place("foundation", fam, base + Vector3(x * s, 0, z * s), 0)
	var top: float = Pieces.LIST["foundation"].size.y
	for i in range(-1, 2):   # a wall on every side, 3 wide
		_place("wall", fam, base + Vector3(i * s, top, s * 1.5), 0)
		_place("wall", fam, base + Vector3(i * s, top, -s * 1.5), 0)
		_place("wall", fam, base + Vector3(s * 1.5, top, i * s), 1)
		_place("wall", fam, base + Vector3(-s * 1.5, top, i * s), 1)
	dwarf.set_physics_process(false)
	dwarf.global_position = base + Vector3(0, top, 0)
	await _wait(1.0)
	var n := 0
	for view in [[0.0, -0.25], [0.0, -0.6], [0.6, -0.3]]:   # yaw (looking -z = through the far wall... ), pitch
		dwarf._yaw = view[0]
		dwarf._pitch = view[1]
		dwarf.model.rotation.y = view[0]
		dwarf.set_physics_process(true)
		await _wait(1.2)   # (the fade takes a quarter second)
		lamp.global_position = dwarf.camera.global_position + Vector3(0, 0.5, 0)
		await _shot("%02d_circle" % n)
		n += 1
	# Owner, Nov 23: an upper floor just over his head, camera zoomed far out and looking down (it stayed solid).
	var wall_h: float = Pieces.LIST["wall"].size.y
	for x in range(-1, 2):
		for z in range(-1, 2):
			_place("floor", fam, base + Vector3(x * s, top + wall_h, z * s), 0)
	dwarf._zoom = 7.0
	for view in [[0.0, -0.9], [2.4, -0.7]]:
		dwarf._yaw = view[0]
		dwarf._pitch = view[1]
		dwarf.model.rotation.y = view[0]
		await _wait(1.5)
		lamp.global_position = dwarf.global_position + Vector3(0, 1.2, 0)
		await _shot("%02d_ceiling" % n)
		n += 1
	get_tree().quit()
