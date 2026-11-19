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
	print("ready to play %.1f s after the program started (cave layout %d)" % [Time.get_ticks_msec() / 1000.0, CaveMaker.layout])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var dwarf: Dwarf = _main.dwarf
	# `at=nest_cavern` (or any place type) stands there instead of the great hall (owner, Nov 19: 12 fps in the
	# Nipper Queen's nest cavern).
	var place := "great_hall"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("at="):
			place = a.substr(3)
	var spots: Array = _main.world.maker.pois_of(place, "mossy")
	if spots.is_empty():
		spots = _main.world.maker.pois_of(place)
	var hall: Dictionary = spots[0]
	dwarf.global_position = hall.pos + Vector3(0, 1.0, 12.0)
	for a in OS.get_cmdline_user_args():  # `pos=x,y,z`: stand on an exact spot (from a LOW FPS line in a play log)
		if a.begins_with("pos="):
			var p := a.substr(4).split(",")
			dwarf.global_position = Vector3(float(p[0]), float(p[1]) + 1.0, float(p[2]))
			place = a
	dwarf._yaw = 0.0
	dwarf._pitch = -0.1
	await _wait(8.0 if place != "great_hall" else 4.0)  # let the cave around us finish building (and a boss wake)
	print("\n===== SPEED CHECK at %s (no frame cap) =====" % place)
	var base := await _measure(4.0)
	_line("everything on", base)
	for a in OS.get_cmdline_user_args():  # `fight=<monster>`: it appears next to you; measure every 2 s while it fights
		if a.begins_with("fight="):
			await _fight(dwarf, a.substr(6))
			get_tree().quit()
			return
	for n in ["GlowGroves", "Boulders", "MushroomGrass", "CaveWater", "CaveCritters", "GlowSwarms", "RootPillars",
			"RootCurtains", "Pois", "Authority/Monsters"]:
		var node := _main.get_node_or_null(n) as Node3D
		if node:
			node.visible = false
			_line("- %s" % n, await _measure(3.0), base)
			node.visible = true
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
	var life := _main.get_node_or_null("CaveLife") as Node3D
	if life:
		life.visible = false
		_line("- cave life (moss, grass, small roots, lichen, ferns)", await _measure(3.0), base)
		life.visible = true
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


## A monster (a boss too) appears 6 m in front of the dwarf; 30 s of measuring while it fights (owner, Nov 19:
## 12 fps fighting the Nipper Queen).
func _fight(dwarf: Dwarf, kind: String) -> void:
	var mgr: MonsterManager = _main.get_node("Authority/Monsters")
	var count := 1
	if "*" in kind:
		count = int(kind.get_slice("*", 1))
		kind = kind.get_slice("*", 0)
	for k in count:
		var uid := mgr._next_uid
		mgr._next_uid += 1
		mgr._ev_spawn(uid, kind, dwarf.global_position + Vector3(k * 1.2, 0.5, -6.0), false, 99999)
	print("  %s appears in front of the dwarf" % kind)
	await _wait(1.0)
	var q := PhysicsShapeQueryParameters3D.new()  # what solid things are near (and how heavy their shapes are)
	var sph := SphereShape3D.new()
	sph.radius = 10.0
	q.shape = sph
	q.transform = Transform3D(Basis(), dwarf.global_position)
	q.collision_mask = 0xFFFFFFFF
	for h in dwarf.get_world_3d().direct_space_state.intersect_shape(q, 64):
		var c: Object = h.collider
		var owner_id: int = (c as CollisionObject3D).shape_find_owner(h.shape) if c is CollisionObject3D else -1
		var sh: Shape3D = (c as CollisionObject3D).shape_owner_get_shape(owner_id, 0) if owner_id >= 0 else null
		var faces := (sh as ConcavePolygonShape3D).get_faces().size() / 3 if sh is ConcavePolygonShape3D else 0
		if sh == null:  # the cave rock: ask the physics server for the chunk's shape
			var srid := PhysicsServer3D.body_get_shape(h.rid, h.shape)
			var data = PhysicsServer3D.shape_get_data(srid)
			if data is Dictionary and data.has("faces"):
				faces = (data.faces as PackedVector3Array).size() / 3
		print("    near: %s  %s  (%s, %d triangles)" % [c.get_class(), (c as Node).get_path() if c is Node else "", sh.get_class() if sh else "?", faces])
	for i in 10:
		if i == 5:
			print("    -- root pillars' solid shapes off --")
			for b: StaticBody3D in _main.get_node("RootPillars").find_children("*", "StaticBody3D", true, false):
				b.collision_layer = 0
		var r := await _measure(2.0)
		var bodies := Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
		var pairs := Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS)
		var timed := "think_us" in mgr  # per-monster timing only when the monster code still records it
		if timed:
			mgr.think_us.clear()
		var steps0 := Engine.get_physics_frames()
		var r2 := await _measure(1.0)
		var steps := maxi(1, Engine.get_physics_frames() - steps0)
		var costs := []
		if timed:
			for k in mgr.think_us:
				costs.append("%s %.2f" % [k, mgr.think_us[k] / 1000.0 / steps])
		costs.append("physics %.2f ms per step" % (r2.phys))
		_line("fight %2d s (%d monsters, %d bodies, %d pairs)" % [(i + 1) * 2, mgr.monsters.size(), bodies, pairs], r, {})
		print("      ms per physics step: ", ", ".join(costs))


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
