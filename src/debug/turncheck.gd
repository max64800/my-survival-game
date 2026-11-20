extends Node
## Turn check (F397, owner Nov 19): holds a workbench, taps Q and holds Q, and writes down how far
## the see-through copy turned, with a photo at each step.
## Run:  godot --audio-driver Dummy --path . -- turncheck claude=turning seed=42 shots=/some/folder

var _main: Node
var _shots := "user://turncheck"


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


func _deg() -> float:
	return snappedf(rad_to_deg(PlaceGhost.yaw), 0.1)


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	_main.hud.set_paused(false)
	Controls.set_captured(true)
	ps.inventory.add("workbench", 1)
	for i in Inventory.SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "workbench":
			if i != 0:
				auth.request_swap(auth.local_peer_id(), i, 0)
			auth.request_select_slot(auth.local_peer_id(), 0)
			break
	var dwarf: Dwarf = _main.dwarf
	dwarf.model.rotation.y = deg_to_rad(17.0)  # look an "odd" way: the first facing must not snap to 45°
	await _wait(1.0)
	print("turncheck: first facing ", _deg(), "°  (dwarf faces 17° + 180°, no snapping)")
	await _shot("01_start")
	var g: PlaceGhost = _main.place_ghost
	for n in 3:
		_tap()
		await _wait(0.15)
	print("turncheck: after 3 taps ", _deg(), "°  (should be 15° more)")
	await _shot("02_three_taps")
	var before := _deg()
	Input.action_press("rotate_piece")
	g.turn(1)
	var marks := []
	for s in 4:
		await _wait(1.0)
		marks.append(_deg())
	Input.action_release("rotate_piece")
	print("turncheck: holding Q, from ", before, "° -> each second: ", marks, " (same step every second)")
	await _shot("03_after_holding")
	await _wait(0.5)
	print("turncheck: after letting go ", _deg(), "°  (stopped)")
	get_tree().quit()


func _tap() -> void:
	var ev := InputEventAction.new()
	ev.action = "rotate_piece"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	ev = InputEventAction.new()
	ev.action = "rotate_piece"
	ev.pressed = false
	Input.parse_input_event(ev)
