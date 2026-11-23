extends Node
## Robot (Nov 23, jump animation F807/F798): sprints forward then jumps (a real running "long jump").
## Prints a line every physics tick (cheap: true simulated seconds, not wall-clock, so screenshot overhead can't
## skew the numbers) and takes real photos at only a handful of key moments, so the jump pose can be checked
## against what actually happened instead of guessed at.
## Run: godot --audio-driver Dummy --path . -- jumpcheck claude=jump_check seed=42 shots=<folder>

var _main: Node
var _shots := ""
var _dwarf: Dwarf
var _rig: DwarfRig
var _shot_i := 0
var _launch_y := 0.0
var _was_on_floor := true
var _photo_at := []  # simulated seconds since launch, still to photograph


func _ready() -> void:
	_main = get_parent()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			_shots = a.trim_prefix("shots=")
	_run.call_deferred()


func _sim_now() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


func _photo(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ""
	if _shots != "":
		path = _main.take_screenshot(_shots.path_join("jump_%02d_%s.png" % [_shot_i, tag]))
	print("JUMPCHECK PHOTO %02d %-6s %s" % [_shot_i, tag, path])
	_shot_i += 1


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	_dwarf = _main.dwarf
	_rig = _dwarf.model.dwarf_rig
	print("JUMPCHECK rig=%s" % [_rig != null])
	await get_tree().create_timer(6.0).timeout  # let the first-load hitch (cave streaming in) settle before timing anything
	_dwarf.bot_move = Vector2(0, -1)
	_dwarf.bot_run = true
	await get_tree().create_timer(1.0).timeout  # full sprint well before the jump (SPRINT_RAMP_TIME = 0.45 s)
	await _photo("sprint")
	_dwarf.bot_jump = true
	await get_tree().physics_frame  # let the jump actually apply before we read velocity/expected hang
	var launch_t := _sim_now()
	_launch_y = _dwarf.global_position.y
	var expected: float = _dwarf._jump_air_expected
	print("JUMPCHECK left the ground, expected hang %.2f s (sim t=%.2f)" % [expected, launch_t])
	_photo_at = [0.0, expected * 0.25, expected * 0.5, expected * 0.75, expected]
	_was_on_floor = false
	while _sim_now() - launch_t < 4.0:
		await get_tree().physics_frame
		var t := _sim_now() - launch_t
		var on_floor: bool = _dwarf.is_on_floor()
		print("JUMPCHECK t=%.3f dy=%+.2f vy=%+.2f on_floor=%s air=%.2f jscale=%.2f expected=%.2f" % [
				t, _dwarf.global_position.y - _launch_y, _dwarf.velocity.y, on_floor,
				_rig._air if _rig else -1.0, _rig.tree.get("parameters/jump_speed/scale") if _rig else -1.0,
				_dwarf._jump_air_expected])
		if _was_on_floor != on_floor and not on_floor:
			pass
		if not on_floor and _photo_at.size() > 0 and t >= _photo_at[0]:
			_photo_at.pop_front()
			await _photo("air")
		if _was_on_floor == false and on_floor:
			print("JUMPCHECK landed at t=%.3f" % t)
			await _photo("land")
			break
		_was_on_floor = on_floor
	await get_tree().create_timer(0.4).timeout
	await _photo("land_settled")
	_dwarf.bot_move = Vector2.ZERO
	_dwarf.bot_run = false
	print("JUMPCHECK done")
	get_tree().quit()
