extends Node
## Robot (Nov 23, dash/dodge roll F798): holds the real "dodge" input (Ctrl) for a long dash, like the owner's
## keyboard does, and prints every physics tick's dodge state + roll animation stretch + real position, so the
## "animation finishes, then I get propelled forward" bug can be seen in numbers instead of guessed at.
## Run: godot --audio-driver Dummy --path . -- dashcheck claude=dash_check seed=42 shots=<folder>

var _main: Node
var _shots := ""
var _dwarf: Dwarf
var _fight: DwarfFight
var _rig: DwarfRig
var _shot_i := 0
var _start_pos := Vector3.ZERO


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
		path = _main.take_screenshot(_shots.path_join("dash_%02d_%s.png" % [_shot_i, tag]))
	print("DASHCHECK PHOTO %02d %-6s %s" % [_shot_i, tag, path])
	_shot_i += 1


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	_dwarf = _main.dwarf
	_fight = _dwarf.fight
	_rig = _dwarf.model.dwarf_rig
	print("DASHCHECK fight=%s rig=%s" % [_fight != null, _rig != null])
	await get_tree().create_timer(6.0).timeout  # let the first-load hitch (cave streaming in) settle before timing anything
	Controls.set_captured(true)  # the real dodge key only registers while "playing" (Controls.captured()), like a real game
	_start_pos = _dwarf.global_position
	await _photo("before")

	# Hold the real "dodge" input, exactly like the owner holding Ctrl on a keyboard, past DODGE_TIME (0.45s)
	# toward DASH_HOLD_MAX (0.75s) for a long dash.
	Input.action_press("dodge")
	await get_tree().physics_frame  # let the trigger apply before we read state
	var press_t := _sim_now()
	var release_t := press_t + 0.95  # release after DASH_HOLD_MAX (0.75s) so the hold runs its full course
	var released := false
	var photo_marks := [0.0, 0.45, 0.75]  # DODGE_TIME, DASH_HOLD_MAX
	while _sim_now() - press_t < 3.0:
		await get_tree().physics_frame
		var t := _sim_now() - press_t
		if not released and _sim_now() >= release_t:
			Input.action_release("dodge")
			released = true
			print("DASHCHECK released dodge key at t=%.3f" % t)
		var dist := (_dwarf.global_position - _start_pos).length()
		print(("DASHCHECK t=%.3f dodging=%s dt=%.3f grace=%.3f expect=%.2f full_len=%.2f rolling=%s " +
				"scale=%.2f active=%s dist=%.2f vel=%.2f") % [
				t, _fight.dodging(), _fight._dodge_t, _fight._dodge_held_grace,
				_fight.dodge_expected_duration(), _rig._full_length, _rig._rolling,
				_rig.tree.get("parameters/full_speed/scale"), _rig.tree.get("parameters/full/active"),
				dist, Vector2(_dwarf.velocity.x, _dwarf.velocity.z).length()])
		if photo_marks.size() > 0 and t >= photo_marks[0]:
			photo_marks.pop_front()
			await _photo("t%02d" % int(round(t * 100)))
		if released and not _fight.dodging():
			print("DASHCHECK roll ended at t=%.3f, total dist=%.2f" % [t, dist])
			await _photo("ended")
			break
	await get_tree().create_timer(0.4).timeout
	await _photo("settled")
	print("DASHCHECK done")
	get_tree().quit()
