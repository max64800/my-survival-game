extends Node
## Aim camera check (F452): photos while aiming the crossbow, zoomed right in and at the normal zoom, plus one not
## aiming for comparison. The crosshair should sit just past his right shoulder.
## Run:  godot --audio-driver Dummy --path . -- aimcheck claude=aim_camera seed=42 shots=/some/folder

var _main: Node
var _shots := "user://aimcheck"


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
	print("aimcheck: shot ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 120.0:
		await _wait(0.25)
		waited += 0.25
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	var dwarf: Dwarf = ps.node
	ps.inventory.slots[0] = {id = "crossbow_copper", count = 1}
	ps.inventory.changed.emit()
	auth.request_select_slot(auth.local_peer_id(), 0)
	_main.hud.set_paused(false)
	Controls.set_captured(true)
	await _wait(1.0)
	for zoom in [Dwarf.ZOOM_MIN, Dwarf.CAMERA_DISTANCE]:
		dwarf._zoom = zoom
		dwarf._pitch = -0.05  # looking straight ahead, as you aim at a creature
		await _wait(1.0)
		await _shot("zoom_%.1f_not_aiming" % zoom)
		Input.action_press("use")
		await _wait(1.0)
		await _shot("zoom_%.1f_aiming" % zoom)
		Input.action_release("use")
	get_tree().quit()
