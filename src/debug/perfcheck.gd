extends Node
## Speed check: turns off the frame cap (vsync), stands in the first big cavern and measures
## how fast the game really runs, then switches things off one at a time to see what each costs.
##   godot --audio-driver Dummy --path . -- seed=42 perfcheck autopilot
## Prints a table: frames per second, milliseconds per frame, and where the time goes.

var _main: Node


func _ready() -> void:
	_main = get_parent()
	if OS.get_cmdline_user_args().has("hitch"):
		if OS.get_cmdline_user_args().has("monsters"):
			_main._monsters = true
		_hitch_start()
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## Over `seconds`: average fps + frame ms, and (F337, Nov 26) the median frame, the "1% low" (the fps of the slowest
## 1 in 100 frames: what a stutter feels like) and the worst frame; graphics card ms; script/physics ms; draw calls.
func _measure(seconds: float) -> Dictionary:
	await _wait(0.5)  # let a change settle
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var proc := 0.0
	var phys := 0.0
	var draws := 0.0
	var gpu := 0.0
	var vp := get_viewport().get_viewport_rid()
	var times := PackedFloat32Array()
	var last := t0
	while Time.get_ticks_usec() - t0 < seconds * 1000000.0:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		frames += 1
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var total := (Time.get_ticks_usec() - t0) / 1000000.0
	var r := frame_stats(times)
	r.merge({fps = frames / total, ms = total * 1000.0 / frames, proc = proc * 1000.0 / frames,
		phys = phys * 1000.0 / frames, draws = draws / frames, gpu = gpu / frames})
	return r


## Median frame ms, 1% low (fps of the 99th-percentile frame) and worst frame ms, from a list of frame times in ms.
static func frame_stats(times: PackedFloat32Array) -> Dictionary:
	if times.is_empty():
		return {median = 0.0, low1 = 0.0, worst = 0.0}
	var s := times.duplicate()
	s.sort()
	var n := s.size()
	var p99: float = s[mini(n - 1, int(n * 0.99))]
	return {median = s[n / 2], low1 = 1000.0 / maxf(p99, 0.001), worst = s[n - 1]}


func _line(name: String, r: Dictionary, base: Dictionary = {}) -> void:
	var gain := "" if base.is_empty() else "   (%+.1f ms per frame)" % (base.ms - r.ms)
	print("  %-34s %5.0f fps  %6.2f ms  median %5.1f  1%% low %4.0f fps  worst %5.0f ms  gpu %5.2f  script %5.2f  physics %5.2f  draws %5.0f%s" % [
		name, r.fps, r.ms, r.median, r.low1, r.worst, r.gpu, r.proc, r.phys, r.draws, gain])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var nofog := args.has("nofog")
	while not _main.is_ready_to_play():
		if nofog:  # from the very start, so the fog's drawing never warms up
			var amb := _main.get_node_or_null("Ambience") as Ambience
			if amb and amb.env:
				amb.env.volumetric_fog_enabled = false
		await _wait(0.25)
	if args.has("warm"):
		await _warmup(nofog)
		get_tree().quit()
		return
	if args.has("spawncost"):
		await _spawn_cost()
		get_tree().quit()
		return
	if args.has("hitch"):
		await _hitch_walk()
		get_tree().quit()
		return
	print("ready to play %.1f s after the program started (cave layout %d)" % [Time.get_ticks_msec() / 1000.0, CaveMaker.layout])
	print("loading steps (0.3 s or more): ", ", ".join(FreezeWatch.steps.map(func(s): return "%s %.1f s" % s)))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	var dwarf: Dwarf = _main.dwarf
	# `at=ruin` (or any place type) stands there instead of the great hall. `at=dungeon`: in the first dungeon's first
	# room past its way in.
	var place := "great_hall"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("at="):
			place = a.substr(3)
	if place == "dungeon":
		dwarf.global_position = dungeon_room_spot(_main.world.maker.dungeons[0])
	else:
		var spots: Array = _main.world.maker.pois_of(place, "mossy")
		if spots.is_empty():
			spots = _main.world.maker.pois_of(place)
		var hall: Dictionary = spots[0]
		dwarf.global_position = hall.pos + Vector3(0, 1.0, 12.0)
	if args.has("base"):  # F777: a big finished base all round you (the biggest blueprints, side by side)
		place += " + big base (%d pieces)" % stamp_big_base(dwarf.global_position)
	for a in OS.get_cmdline_user_args():  # `pos=x,y,z`: stand on an exact spot (from a LOW FPS line in a play log)
		if a.begins_with("pos="):
			var p := a.substr(4).split(",")
			dwarf.global_position = Vector3(float(p[0]), float(p[1]) + 1.0, float(p[2]))
			place = a
	dwarf._yaw = 0.0
	dwarf._pitch = -0.1
	await _wait(8.0 if place != "great_hall" else 4.0)  # let the cave around us finish building
	print("\n===== SPEED CHECK at %s (no frame cap) =====" % place)
	var base := await _measure(4.0)
	_line("everything on", base)
	for a in OS.get_cmdline_user_args():  # `fight=<monster>`: it appears next to you; measure every 2 s while it fights
		if a.begins_with("fight="):
			await _fight(dwarf, a.substr(6))
			get_tree().quit()
			return
	if args.has("lantern"):  # F337: the lantern's shadow: 6-side cube vs 2-side paraboloid vs none, each twice
		await _lantern_modes(dwarf)
		print("======================================")
		get_tree().quit()
		return
	if args.has("split"):  # F337: where the main processor's time goes, part by part (averaged)
		await _split_avg(5.0)
		print("  objects drawn: %d, draw calls %.0f, nodes %d" % [Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
		print("======================================")
		get_tree().quit()
		return
	if args.has("quick"):  # only "everything on" + walking and digging (for before/after checks of one fix)
		await _hitches(dwarf)
		print("======================================")
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


## The middle of a dungeon's first room past its way in, 1 m above its floor (map spaces: [name, x0, z0, x1, z1, y, h]).
static func dungeon_room_spot(d: Dictionary) -> Vector3:
	for s in d.map.spaces:
		if String(s[0]) != "entry":
			var local := Vector3((float(s[1]) + float(s[3])) * 0.5, float(s[5]) + 1.0, (float(s[2]) + float(s[4])) * 0.5)
			return DungeonMap.to_world(d, local)
	return d.mouth


const BIG_BASE := [["stonehold_prow_hall", Vector2(0, -34)], ["hearthbrick_manor", Vector2(-40, 0)],
	["hearthbrick_brewhall", Vector2(40, 0)], ["hearthbrick_smeltery", Vector2(0, 34)]]


## F777: the four biggest blueprints stood up finished round `at` (like a big late-game base), all in one batch the
## way a ruin is placed. Returns how many pieces went up.
func stamp_big_base(at: Vector3) -> int:
	var b: Builder = GameAuthority.instance.builder
	var n := 0
	b.batch = true
	for e in BIG_BASE:
		var bp := BlueprintLibrary.make(e[0])
		var o: Vector3 = _main.world.maker.find_floor(at.x + e[1].x, at.z + e[1].y, at.y + 3.0)
		if not o.is_finite():
			o = Vector3(at.x + e[1].x, at.y - 1.0, at.z + e[1].y)
		for p in bp.world_pieces(o.round(), 0):
			b._ev_add_piece(b._next_uid, p.piece, p.family, p.pos, p.rot, true)
			n += 1
	b.end_batch()
	return n


## F417 (Nov 20): the owner's play log showed 10-19 FPS for the first ~1.5 min after loading, the graphics card taking
## 55-72 ms a frame, then a steady 60 in the same place. `perfcheck warm [nofog]`: stand where you wake up, look slowly
## all the way round (like the owner did), and print the graphics card's time every 2 s for 2 minutes (frame cap on, like
## a real game). `nofog` keeps the volumetric fog off from the start.
func _warmup(nofog: bool) -> void:
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var dwarf: Dwarf = _main.dwarf
	var env: Environment = (_main.get_node("Ambience") as Ambience).env
	if nofog:
		env.volumetric_fog_enabled = false
	print("\n===== WARM-UP CHECK (fog %s) at %s =====" % ["off" if nofog else "on", dwarf.global_position.round()])
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 120000:
		var frames := 0
		var gpu := 0.0
		var worst := 0.0
		var s0 := Time.get_ticks_usec()
		while Time.get_ticks_usec() - s0 < 2000000:
			await get_tree().process_frame
			dwarf._yaw += 0.0035  # one slow turn about every 30 s
			var g := RenderingServer.viewport_get_measured_render_time_gpu(vp)
			gpu += g
			worst = maxf(worst, g)
			frames += 1
		var secs := (Time.get_ticks_usec() - s0) / 1000000.0
		print("  %5.0f s  %3.0f fps  graphics card %5.1f ms (worst %5.1f)  draws %4.0f" % [(Time.get_ticks_msec() - t0) / 1000.0,
			frames / secs, gpu / frames, worst, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("======================================")


## F417/F266 (Nov 20): play logs show single physics steps of 0.3-1.4 s (Godot's physics number is the worst step of
## the last second). `perfcheck hitch`: walk the dwarf around for 90 s and split every step into game code
## (_physics_process scripts, timed between a first and a last script) and the engine (everything else in the step).
var _ph_start := 0
var _ph_end := 0
var _ph_scripts := 0.0
var _ph_last_proc := 0
var _ph_t0 := 0
var _new_bodies := 0
var _new_shapes := 0
var _new_faces := 0
var _new_nodes := 0


class _Stamp extends Node:
	var cb: Callable
	var pcb: Callable
	func _physics_process(_d: float) -> void:
		if cb.is_valid():
			cb.call()
	func _process(_d: float) -> void:
		if pcb.is_valid():
			pcb.call()


var _pr_start := 0
var _pr_ms := 0.0


func _hitch_start() -> void:
	var first := _Stamp.new()
	first.process_physics_priority = -1000000
	first.cb = func() -> void: _ph_start = Time.get_ticks_usec()
	var last := _Stamp.new()
	last.process_physics_priority = 1000000
	last.cb = func() -> void:
		_ph_end = Time.get_ticks_usec()
		_ph_scripts = (_ph_end - _ph_start) / 1000.0
	var pfirst := _Stamp.new()
	pfirst.process_priority = -1000000
	pfirst.pcb = func() -> void: _pr_start = Time.get_ticks_usec()
	var plast := _Stamp.new()
	plast.process_priority = 1000000
	plast.pcb = func() -> void: _pr_ms = (Time.get_ticks_usec() - _pr_start) / 1000.0
	add_child(first)
	add_child(last)
	add_child(pfirst)
	add_child(plast)
	get_tree().node_added.connect(func(n: Node) -> void:
		_new_nodes += 1
		if n is CollisionObject3D:
			_new_bodies += 1
		elif n is CollisionShape3D:
			_new_shapes += 1
			var sh := (n as CollisionShape3D).shape
			if sh is ConcavePolygonShape3D:
				_new_faces += (sh as ConcavePolygonShape3D).get_faces().size() / 3)
	_ph_t0 = Time.get_ticks_msec()
	_ph_last_proc = Time.get_ticks_usec()
	_hitch_loop()


func _hitch_loop() -> void:
	while true:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var frame := (now - _ph_last_proc) / 1000.0
		_ph_last_proc = now
		var engine_after := (now - _ph_end) / 1000.0 if _ph_end > 0 else 0.0  # physics engine step after the scripts
		if frame > 100.0:
			print("  HITCH %6.1f s  frame %6.0f ms · process scripts (last frame) %6.1f ms · physics scripts %6.1f ms · engine after scripts %6.1f ms · new: %d nodes, %d bodies, %d shapes, %d mesh faces · doing %s" % [
				(Time.get_ticks_msec() - _ph_t0) / 1000.0, frame, _pr_ms, _ph_scripts, engine_after,
				_new_nodes, _new_bodies, _new_shapes, _new_faces, FreezeWatch.doing])
		_new_nodes = 0
		_new_bodies = 0
		_new_shapes = 0
		_new_faces = 0


## Which part of the world is slow in _process: a timer stamp before every child of main (and of their children
## that hold many nodes). Same priority (0) runs in tree order, so the gap between two stamps = that part's cost.
var _split_names: Array[String] = []
var _split_min := 40.0  ## print a frame's split when its game code takes this long (`why`: 12 ms)
var _split_t: PackedInt64Array = []


func _split_process() -> void:
	var targets: Array[Node] = []
	for c in _main.get_children():
		targets.append(c)
		for g in c.get_children():
			if g.get_child_count() > 0 or g.is_processing():
				targets.append(g)
	_split_t.resize(targets.size() + 1)
	var i := 0
	for n in targets:
		var st := _Stamp.new()
		var k := i
		st.pcb = func() -> void: _split_t[k] = Time.get_ticks_usec()
		n.get_parent().add_child(st)
		n.get_parent().move_child(st, n.get_index())
		_split_names.append(String(n.get_path()).trim_prefix(String(_main.get_path())))
		i += 1
	var endst := _Stamp.new()
	endst.process_priority = 999999
	endst.pcb = func() -> void:
		_split_t[i] = Time.get_ticks_usec()
		var costs := []
		for j in _split_names.size():
			if _split_t[j] > 0 and _split_t[j + 1] >= _split_t[j]:
				costs.append([(_split_t[j + 1] - _split_t[j]) / 1000.0, _split_names[j]])
		costs.sort_custom(func(a, b): return a[0] > b[0])
		var tot := 0.0
		for c in costs:
			tot += c[0]
		if tot > _split_min:
			var top := ""
			for c in costs.slice(0, 4):
				top += "%s %.0f ms, " % [c[1], c[0]]
			print("    process split (%.0f ms): %s" % [tot, top])
	add_child(endst)


## F337 (Nov 28): the lantern's shadow three ways, in turn twice (so another program's load shows up as a mismatch),
## with a screenshot of each in user://perf_lantern_<mode>.png to compare the look.
func _lantern_modes(dwarf: Dwarf) -> void:
	var lights := dwarf.find_children("*", "OmniLight3D", true, false)
	var lamp: OmniLight3D = null
	for l: OmniLight3D in lights:
		if l.shadow_enabled:
			lamp = l
	if lamp == null:
		print("  no shadowed lantern light found")
		return
	for round_i in 2:
		for mode in ["cube", "paraboloid", "off"]:
			lamp.shadow_enabled = mode != "off"
			lamp.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID if mode == "paraboloid" else OmniLight3D.SHADOW_CUBE
			var r := await _measure(3.0)
			_line("lantern shadow: %s" % mode, r)
			if round_i == 0:
				get_viewport().get_texture().get_image().save_png("user://perf_lantern_%s.png" % mode)
	lamp.shadow_enabled = true
	lamp.omni_shadow_mode = OmniLight3D.SHADOW_CUBE


## F337 (Nov 28): `split`: the AVERAGE cost per frame of each part of the world, for game code (_process) and for
## physics scripts (_physics_process), over `seconds`. Same stamps as _split_process, but summed, not only spikes.
func _split_avg(seconds: float) -> void:
	var targets: Array[Node] = []
	for c in _main.get_children():
		targets.append(c)
		for g in c.get_children():
			if g.get_child_count() > 0 or g.is_processing() or g.is_physics_processing():
				targets.append(g)
	var names: Array[String] = []
	var n := targets.size()
	var tp := []  # plain Arrays: the little timer functions below share them (packed arrays would be copied)
	var tq := []
	var sum_p := []
	var sum_q := []
	for a in [tp, tq]:
		a.resize(n + 1)
		a.fill(0)
	for a in [sum_p, sum_q]:
		a.resize(n)
		a.fill(0.0)
	var stamps: Array[Node] = []
	for i in n:
		var t := targets[i]
		var st := _Stamp.new()
		st.pcb = func() -> void: tp[i] = Time.get_ticks_usec()
		st.cb = func() -> void: tq[i] = Time.get_ticks_usec()
		t.get_parent().add_child(st)
		t.get_parent().move_child(st, t.get_index())
		stamps.append(st)
		names.append(String(t.get_path()).trim_prefix(String(_main.get_path())))
	var counts := [0, 0]
	var endst := _Stamp.new()
	endst.process_priority = 999999
	endst.process_physics_priority = 999999
	endst.pcb = func() -> void:
		tp[n] = Time.get_ticks_usec()
		for j in n:
			if tp[j] > 0 and tp[j + 1] >= tp[j]:
				sum_p[j] += (tp[j + 1] - tp[j]) / 1000.0
		counts[0] += 1
	endst.cb = func() -> void:
		tq[n] = Time.get_ticks_usec()
		for j in n:
			if tq[j] > 0 and tq[j + 1] >= tq[j]:
				sum_q[j] += (tq[j + 1] - tq[j]) / 1000.0
		counts[1] += 1
	_main.add_child(endst)
	stamps.append(endst)
	await _wait(seconds)
	for s in stamps:
		s.queue_free()
	for pair in [["game code (_process), ms per frame", sum_p, counts[0]], ["physics scripts, ms per physics step", sum_q, counts[1]]]:
		var sums: Array = pair[1]
		var cnt: int = maxi(1, pair[2])
		var rows := []
		var tot := 0.0
		for j in n:
			rows.append([sums[j] / cnt, names[j]])
			tot += sums[j] / cnt
		rows.sort_custom(func(a, b): return a[0] > b[0])
		print("  %s: total %.2f" % [pair[0], tot])
		for r in rows.slice(0, 14):
			if r[0] >= 0.05:
				print("    %6.2f  %s" % r)


## Walk a slow circle for 90 s, then jump 60 m away twice (new cave to load), like exploring.
func _hitch_walk() -> void:
	var dwarf: Dwarf = _main.dwarf
	var home := dwarf.global_position
	print("
===== HITCH WALK from %s =====" % home.round())
	_split_process()
	var t0 := Time.get_ticks_msec()
	var jumps := [30.0, 60.0]
	while Time.get_ticks_msec() - t0 < 90000:
		await get_tree().physics_frame
		var s := (Time.get_ticks_msec() - t0) / 1000.0
		dwarf._yaw = s * 0.2
		if not jumps.is_empty() and s >= jumps[0]:
			jumps.pop_front()
			dwarf.global_position = home + Vector3(60 if jumps.size() == 1 else -60, 0, 0)
			print("  jump at %.0f s to %s" % [s, dwarf.global_position.round()])
		var sws := _main.get_node_or_null("GlowSwarms")
		if sws and int(s) % 10 == 0 and absf(s - roundf(s)) < 0.01:
			print("  %.0f s: swarms finished %d of %d" % [s, sws._todo, sws._swarms.size()])
	print("======================================")


## F417/F266: how long each creature takes to appear (its first time and its second), and the next frame after it
## (first-time drawing of its looks). `perfcheck spawncost`.
func _spawn_cost() -> void:
	var mgr: MonsterManager = _main.get_node("Authority/Monsters")
	var dwarf: Dwarf = _main.dwarf
	await _wait(3.0)
	print("
===== SPAWN COST =====")
	if OS.get_cmdline_user_args().has("preload"):
		var t := Time.get_ticks_usec()
		for f in DirAccess.get_files_at("res://assets/models/creatures"):
			if f.ends_with(".glb"):
				Look.forged("creatures", f.get_basename()).free()
		print("  preloaded every creature look in %.0f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
	for kind: String in ["rock_snail", "rock_beetle", "cave_bat"]:
		var d: Dictionary = Monsters.LIST[kind]
		for round in 2:
			var t := Time.get_ticks_usec()
			var mdl := MonsterModel.build(d.shape, d.color, d.size, false, kind, 5, "", -1)
			var t_build := (Time.get_ticks_usec() - t) / 1000.0
			var count := MonsterModel.variant_count(kind)
			t = Time.get_ticks_usec()
			var f := Look.forged("monsters", "%s_v0" % kind) if count > 0 else null
			var t_inst := (Time.get_ticks_usec() - t) / 1000.0
			var meshes: Array = f.find_children("*", "MeshInstance3D", true, false) if f else []
			var tris := 0
			for mi: MeshInstance3D in meshes:
				for i in mi.mesh.get_surface_count():
					tris += mi.mesh.surface_get_array_index_len(i) / 3
			print("  %-12s build %6.1f ms · instantiate only %6.1f ms · %d variants · %d parts · %d triangles" % [kind, t_build, t_inst, count, meshes.size(), tris])
			t = Time.get_ticks_usec()
			add_child(mdl)
			print("      add to tree %6.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
			mdl.queue_free()
			if f:
				f.free()
	for kind: String in Monsters.LIST.keys():
		for round in 2:
			var uid := mgr._next_uid
			mgr._next_uid += 1
			var t := Time.get_ticks_usec()
			mgr._ev_spawn(uid, kind, dwarf.global_position + Vector3(0, 0.5, -5.0), false, 99999, "")
			var make := (Time.get_ticks_usec() - t) / 1000.0
			await get_tree().process_frame
			t = Time.get_ticks_usec()
			await get_tree().process_frame
			await get_tree().process_frame
			var draw := (Time.get_ticks_usec() - t) / 1000.0
			print("  %-18s %s  made in %7.1f ms · next 2 frames %7.1f ms" % [kind, "1st" if round == 0 else "2nd", make, draw])
			await _wait(0.5)
			var m: Node = mgr.monsters.get(uid)
			if m:
				mgr.monsters.erase(uid)
				m.queue_free()
			await _wait(0.3)
	print("======================================")


## A monster appears 6 m in front of the dwarf; 30 s of measuring while it fights.
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
	var why := OS.get_cmdline_user_args().has("why")  # F337: explain each slow frame
	if why:
		_split_min = 12.0
		_split_process()
	var dug_now := false
	var last := Time.get_ticks_usec()
	while Time.get_ticks_msec() < t_end:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		if why and times[-1] > 33.0:
			print("    SLOW %.0f ms%s · physics (worst this second) %.1f ms · doing %s" % [times[-1], " (dug last frame)" if dug_now else "",
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, FreezeWatch.doing])
		dug_now = false
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
			dug_now = true
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
