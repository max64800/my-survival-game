extends Node
## Speed check: turns off the frame cap (vsync), stands in the first big cavern and measures
## how fast the game really runs, then switches things off one at a time to see what each costs.
##   godot --audio-driver Dummy --path . -- seed=42 perfcheck autopilot
## Prints a table: frames per second, milliseconds per frame, and where the time goes.

var _main: Node


func _ready() -> void:
	_main = get_parent()
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## Average over `seconds`: fps, frame ms, script (process) ms, physics ms, draw calls.
func _measure(seconds: float) -> Dictionary:
	await _wait(0.5)  # let a change settle
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var proc := 0.0
	var phys := 0.0
	var draws := 0.0
	while Time.get_ticks_usec() - t0 < seconds * 1000000.0:
		await get_tree().process_frame
		frames += 1
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var total := (Time.get_ticks_usec() - t0) / 1000000.0
	return {fps = frames / total, ms = total * 1000.0 / frames, proc = proc * 1000.0 / frames,
		phys = phys * 1000.0 / frames, draws = draws / frames}


func _line(name: String, r: Dictionary, base: Dictionary = {}) -> void:
	var gain := "" if base.is_empty() else "   (%+.1f ms per frame)" % (base.ms - r.ms)
	print("  %-34s %6.0f fps  %6.2f ms  script %5.2f  physics %5.2f  draws %5.0f%s" % [name, r.fps, r.ms, r.proc, r.phys, r.draws, gain])


func _run() -> void:
	while not _main.is_ready_to_play():
		await _wait(0.25)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var dwarf: Dwarf = _main.dwarf
	var hall: Dictionary = _main.world.maker.pois_of("great_hall")[0]
	dwarf.global_position = hall.pos + Vector3(0, 1.0, 12.0)
	dwarf._yaw = 0.0
	dwarf._pitch = -0.1
	await _wait(4.0)  # let the cave around us finish building
	print("\n===== SPEED CHECK (no frame cap) =====")
	var base := await _measure(4.0)
	_line("everything on", base)
	var env: Environment = (_main.get_node("Ambience") as Ambience).env
	env.volumetric_fog_enabled = false
	_line("- volumetric fog", await _measure(3.0), base)
	env.volumetric_fog_enabled = true
	env.ssil_enabled = false
	_line("- bounced light (SSIL)", await _measure(3.0), base)
	env.ssil_enabled = true
	env.ssao_enabled = false
	_line("- corner shadows (SSAO)", await _measure(3.0), base)
	env.ssao_enabled = true
	env.glow_enabled = false
	_line("- glow", await _measure(3.0), base)
	env.glow_enabled = true
	var lights := get_tree().root.find_children("*", "OmniLight3D", true, false)
	for l: OmniLight3D in lights:
		l.set_meta("had_shadow", l.shadow_enabled)
		l.shadow_enabled = false
	_line("- all light shadows (%d lights)" % lights.size(), await _measure(3.0), base)
	for l: OmniLight3D in lights:
		l.shadow_enabled = l.get_meta("had_shadow")
	var clutter := _main.get_node_or_null("Clutter") as Node3D
	if clutter:
		clutter.visible = false
		_line("- cave clutter + stalactites", await _measure(3.0), base)
		clutter.visible = true
	var parts := get_tree().root.find_children("*", "GPUParticles3D", true, false)
	for p: GPUParticles3D in parts:
		p.visible = false
	_line("- particles (%d)" % parts.size(), await _measure(3.0), base)
	for p: GPUParticles3D in parts:
		p.visible = true
	var glow := _main.get_node_or_null("Glow") as Node3D
	if glow:
		glow.visible = false
		_line("- mushrooms/crystals/roots", await _measure(3.0), base)
		glow.visible = true
	dwarf.visible = false
	_line("- the dwarf", await _measure(3.0), base)
	dwarf.visible = true
	get_viewport().scaling_3d_scale = 0.5
	_line("- half resolution (GPU test)", await _measure(3.0), base)
	get_viewport().scaling_3d_scale = 1.0
	await _hitches(dwarf)
	print("  objects drawn: %d, lights: %d, window %s" % [Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), lights.size(), get_viewport().get_visible_rect().size])
	print("======================================")
	get_tree().quit()


## Walk and dig for a while with no frame cap, and list the slowest frames (hitches).
func _hitches(dwarf: Dwarf) -> void:
	print("  monitor refresh rate: %.0f Hz" % DisplayServer.screen_get_refresh_rate())
	var times: Array[float] = []
	var t_end := Time.get_ticks_msec() + 8000
	dwarf.bot_move = Vector2(0, -1)
	var dig_t := 0.0
	var dig_ms := []
	var last := Time.get_ticks_usec()
	while Time.get_ticks_msec() < t_end:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		dig_t += times[-1]
		if dig_t > 700.0:  # dig in front every 0.7 s (new holes = the cave rebuilding)
			dig_t = 0.0
			dwarf._yaw += 0.6
			var at := dwarf.global_position - dwarf.global_basis.z * 1.5 + Vector3.DOWN * 0.3
			var auth := GameAuthority.instance
			var d0 := Time.get_ticks_usec()
			var r := auth._judge_hit(auth.get_player(1), at, Vector3.UP)
			var d1 := Time.get_ticks_usec()
			auth._tell_feedback(1, r)
			var d2 := Time.get_ticks_usec()
			dig_ms.append([(d1 - d0) / 1000.0, r.get("state", "?"), (d2 - d1) / 1000.0])
	dwarf.bot_move = Vector2.ZERO
	print("  each dig: [decide ms, result, show ms]: ", dig_ms.map(func(d): return "%.1f %s %.1f" % [d[0], d[1], d[2]]))
	var root := get_tree().current_scene
	for k in 3:
		var t0 := Time.get_ticks_usec()
		Fx.burst(root, dwarf.global_position, Color(0.5, 0.48, 0.45), 16, 4.0)
		var t1 := Time.get_ticks_usec()
		ChunkSwarm.burst(root, dwarf.global_position, Color(0.5, 0.48, 0.45), dwarf)
		var t2 := Time.get_ticks_usec()
		Sfx.play("dig_rock", dwarf.global_position, 2.0, 0.85)
		var t3 := Time.get_ticks_usec()
		print("  chips+dust %.2f ms, bits swarm %.2f ms, sound %.2f ms" % [(t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0])
		await get_tree().process_frame
	times.sort()
	var n := times.size()
	print("  walking + digging, %d frames: median %.1f ms, 99%% %.1f ms, worst %.1f ms, frames over 33 ms: %d" % [
		n, times[n / 2], times[int(n * 0.99)], times[n - 1], times.filter(func(t): return t > 33.0).size()])
