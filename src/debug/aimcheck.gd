extends Node
## Aim camera check (F452): photos while aiming the crossbow, zoomed right in and at the normal zoom, plus one not
## aiming for comparison, and one halfway through a reload (the bar under the crosshair). The crosshair should sit just past his right shoulder.
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
	ps.inventory.add_worn("crossbow_copper")  # (worn and in hand, like the tests: F959)
	for id in ["bolt_metal", "bolt_fang", "bolt_glow"]:  # (for the bolt wheel, F956)
		ps.inventory.add(id, 6)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_copper":
			auth.request_select_slot(auth.local_peer_id(), i)
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
	# F962: aiming up at bats near a tall cave's roof (the camera stays behind him, the view tilts right up).
	dwarf._zoom = Dwarf.CAMERA_DISTANCE
	Input.action_press("use")
	for pitch in [0.9, 1.25, Dwarf.AIM_PITCH_MAX]:
		dwarf._pitch = pitch
		await _wait(1.0)
		await _shot("aiming_up_%.2f" % pitch)
	Input.action_release("use")
	dwarf._pitch = -0.05
	await _wait(1.0)
	# F956: the bolt wheel (hold R with a bolt in), the mouse pushed right.
	Input.action_press("reload")
	await _wait(0.5)
	dwarf.fight.wheel_aim = Vector2(90, 0)
	await _wait(0.2)
	await _shot("bolt_wheel")
	Input.action_release("reload")
	await _wait(0.3)
	# The reload bar under the crosshair (owner, Nov 20): halfway through a reload.
	ps.inventory.add("bolt_stone", 5)
	dwarf.fight.loaded = false
	dwarf.fight.start_reload()
	dwarf._zoom = Dwarf.ZOOM_MIN  # close, to see his hands work the crossbow
	var t := dwarf.fight.reload_total
	for f in [0.2, 0.5, 0.9]:  # the reload move should still be going near the end (owner, Nov 20)
		await _wait(t * f - (t - dwarf.fight.reload_left))
		print("aimcheck: reloading %.1f of %.1f s" % [t - dwarf.fight.reload_left, t])
		await _shot("reload_%d" % roundi(f * 100))
	get_tree().quit()
