extends Node
## The dev "Ruins" test worlds (owner, Nov 21; RuinTests): waits for the ruin to stand, puts the dwarf beside its
## Rebuilding Chest facing it, with a Build Hammer, pickaxe and axe. Opening the chest ("when u open the chest it
## rebuilds instantly") puts one of the chosen material in it: that picks the version (stone/brick, or wood with the
## menu's "Wood" button) and the Builder (instant_ruins) puts the whole ruin up at once, free.
## Dev builds only (DevMenu.enabled()): the buttons never show in the game players get.

const HOTBAR := [["build_hammer", 1], ["pickaxe_copper", 1], ["axe_copper", 1], ["crystal_torch", 10]]

var _main: Node
var _box := -1


func _ready() -> void:
	_main = get_parent()
	_run.call_deferred()


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var auth: GameAuthority = _main.authority
	var e := RuinTests.of_key(_main.ruin_test)
	var ps := auth.get_player(auth.local_peer_id())
	if ps:
		var inv: Inventory = ps.inventory
		for i in Inventory.HOTBAR_SIZE:
			inv.slots[i] = {id = HOTBAR[i][0], count = HOTBAR[i][1]} if i < HOTBAR.size() else {}
		inv.slots[Inventory.equip_index("lantern")] = {id = "lantern_back", count = 1}
		inv.changed.emit()
	_main.hud.show_toast("Ruin test: the %s is being put up…" % e.get("name", "ruin"), 4.0)
	# The ruin carves its space and stands, then adds its Rebuilding Chest to the world record.
	var rec := {}
	var found := -1
	for i in 3600:
		for k in auth.world_state.get("ruins", {}):
			found = int(k)
			rec = auth.world_state.ruins[k]
		if found >= 0 and not auth.storage.get_box(found).is_empty():
			break
		await get_tree().process_frame
	if rec.is_empty():
		_main.hud.show_toast("Ruin test: the ruin didn't appear (see the log)", 6.0)
		push_warning("RUIN_TEST no Rebuilding Chest after 60 s")
		queue_free()
		return
	_box = found
	# Beside the chest, on the path side, looking at it.
	var chest: Node3D = auth.storage.get_box(_box).node
	var origin: Vector3 = rec.origin
	var basis := Basis(Vector3.UP, int(rec.turn) * PI / 2.0)
	var out := basis * Vector3(0, 0, 1)  # (the ruin's front)
	var side := chest.global_position - origin
	side.y = 0.0
	var stand := chest.global_position + out * 1.6 - side.normalized().slide(out).normalized() * 0.6
	var fl: Vector3 = _main.world.maker.find_floor(stand.x, stand.z, stand.y + 2.0)
	if fl != Vector3.INF:
		stand = fl
	var dwarf: Dwarf = _main.dwarf
	dwarf.global_position = stand + Vector3.UP * 0.3
	dwarf.velocity = Vector3.ZERO
	var dir := chest.global_position - (dwarf.global_position + Vector3.UP * 1.0)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = 0.0
	dwarf.model.rotation.y = dwarf._yaw
	_main.world.maker.spawn_point = dwarf.global_position  # (wake here after dying)
	var version: String = "wood" if _main.ruin_test_wood else String(e.get("hard", "Stone")).to_lower()
	_main.hud.show_toast("Ruin test: open the Rebuilding Chest (E) to rebuild the %s in %s at once." % [e.get("name", "ruin"), version], 8.0)
	print("RUIN_TEST %s at the chest %d %s (%s)" % [_main.ruin_test, _box, dwarf.global_position, version])
	for a in OS.get_cmdline_user_args():  # robots: open the chest by itself, picture before and after, then quit
		if a.begins_with("shots="):
			await _robot_shots(a.trim_prefix("shots="), origin, out)


func _process(_delta: float) -> void:
	if _box < 0:
		return
	var panel: Node = _main.hud.box_panel
	if panel.visible and panel.box_id == _box:
		_rebuild()


## One of the chosen material into the chest: it picks the version and the rebuild starts (Builder.ruin_chest_changed).
func _rebuild() -> void:
	var auth: GameAuthority = _main.authority
	var rec: Dictionary = auth.world_state.get("ruins", {}).get(str(_box), {})
	var mat := BlueprintLibrary.WOOD if _main.ruin_test_wood else Builder.ruin_hard(rec)
	auth.storage.put(_box, mat, 1)
	print("RUIN_TEST chest opened: rebuilding in %s" % mat)
	_box = -1
	set_process(false)


func _robot_shots(folder: String, origin: Vector3, out: Vector3) -> void:
	var cam_at := origin + out * 22.0 + Vector3.UP * 9.0
	await get_tree().create_timer(4.0).timeout
	await _shot(folder, "ruintest_%s_before.png" % _main.ruin_test, cam_at, origin + Vector3.UP * 3.0)
	_main.hud.open_box(_box)
	var t0 := Time.get_ticks_msec()
	for i in 600:
		if _main.authority.builder.sites.is_empty() and i > 10:
			break
		await get_tree().process_frame
	print("RUIN_TEST rebuilt in %d ms; done = %s" % [Time.get_ticks_msec() - t0, _main.authority.world_state.get("ruins", {}).values().map(func(r): return r.get("done", false))])
	_main.hud.box_panel.visible = false
	_main.hud._bag_panel.visible = false
	await get_tree().create_timer(2.0).timeout
	await _shot(folder, "ruintest_%s_after.png" % _main.ruin_test, cam_at, origin + Vector3.UP * 3.0)
	if OS.get_cmdline_user_args().has("perf"):
		await _perf(cam_at, origin + Vector3.UP * 3.0)
	if OS.get_cmdline_user_args().has("walk"):   # (the real dwarf over every stair and through every door)
		var w: Node = preload("res://src/debug/tower_walk.gd").new()
		add_child(w)
		await w.run(_main, folder)
	get_tree().quit()


## F565 🔁 (`perf`): how fast the rebuilt ruin draws from out front, no frame cap, then each suspect switched off
## one at a time: what that saves per frame (CPU = the game preparing the frame, GPU = the graphics card drawing it).
func _measure(seconds: float) -> Dictionary:
	await get_tree().create_timer(0.5).timeout
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var r := {proc = 0.0, phys = 0.0, draws = 0.0, objs = 0.0, prims = 0.0, cpu = 0.0, gpu = 0.0}
	while Time.get_ticks_usec() - t0 < seconds * 1000000.0:
		await get_tree().process_frame
		frames += 1
		r.proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		r.phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		r.draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		r.objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		r.prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		r.cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
		r.gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var total := (Time.get_ticks_usec() - t0) / 1000.0
	for k in r:
		r[k] /= frames
	r.ms = total / frames
	return r


func _perf_line(name: String, r: Dictionary, base: Dictionary = {}) -> void:
	var gain := "" if base.is_empty() else "  (%+.1f ms)" % (base.ms - r.ms)
	print("PERF %-36s %5.1f ms  render-cpu %5.2f  gpu %5.2f  script %5.2f  physics %5.2f  draws %5.0f  objects %5.0f  tris %6.0fk%s" % [
		name, r.ms, r.cpu, r.gpu, r.proc, r.phys, r.draws, r.objs, r.prims / 1000.0, gain])


func _perf(at: Vector3, look: Vector3) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.global_position = at
	cam.look_at(look)
	cam.make_current()
	_main.dwarf.global_position = at + Vector3.UP * 0.5  # (the dwarf's lantern and the light culling follow the dwarf)
	await get_tree().create_timer(3.0).timeout
	var pieces: Array = []
	var looks: Array = []
	var shapes := 0
	var lights: Array = []
	for n in get_tree().root.find_children("*", "", true, false):
		if n is PieceNode:
			pieces.append(n)
			if (n as PieceNode)._look:
				looks.append((n as PieceNode)._look)
			for c in n.get_children():
				if c is CollisionShape3D:
					shapes += 1
		if n is Light3D and (n as Light3D).visible:
			lights.append(n)
	var shadowed := lights.filter(func(l: Light3D): return l.shadow_enabled)
	var models := {}
	for mi: MeshInstance3D in looks:
		models[mi.mesh] = true
	print("PERF %d pieces (%d looks, %d different meshes, %d collision shapes), %d lights (%d with shadows), window %s" % [
		pieces.size(), looks.size(), models.size(), shapes, lights.size(), shadowed.size(), get_viewport().get_visible_rect().size])
	var base := await _measure(4.0)
	_perf_line("everything on", base)
	var b: Builder = _main.authority.builder
	for box_id in b.sites:
		var site: Dictionary = b.sites[box_id]
		var t0 := Time.get_ticks_usec()
		b._build_step(box_id, site, _main.authority.storage.get_box(box_id))
		print("PERF one builder step of the unfinished site: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		t0 = Time.get_ticks_usec()
		b.structure.recompute()
		print("PERF   of which a whole strength check: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		b.instant_ruins = false  # the real game's way (every 0.5 s / 1 s, not rushed)
		t0 = Time.get_ticks_usec()
		b._ruin_step(box_id, site)
		print("PERF   normal game: ruin clearing step %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		t0 = Time.get_ticks_usec()
		b._carve_step(box_id, site, _main.authority.storage.get_box(box_id))
		b._fill_step(box_id, site, _main.authority.storage.get_box(box_id))
		print("PERF   normal game: carve + fill step %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		t0 = Time.get_ticks_usec()
		b._build_step(box_id, site, _main.authority.storage.get_box(box_id))
		print("PERF   normal game: whole build step %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
		b.instant_ruins = true
		for p: Dictionary in site.plan:
			if p.built:
				continue
			var why: Array = []
			for uid in b.structure.overlapping(p.piece, p.pos, p.rot):
				var q: Dictionary = b.structure.pieces[uid]
				why.append("%s %s at %s rot %d" % [q.piece, q.family, q.pos, q.rot])
			print("PERF unbuilt %s %s at %s rot %d · overlaps %s · rock '%s'" % [p.piece, p.family, p.pos, p.rot, why,
				Pieces.rock_problem(p.piece, p.pos, p.rot, _main.authority.world.sdf_at)])
	b.set_process(false)
	_perf_line("- builder (site steps)", await _measure(3.0), base)
	b.set_process(true)
	b.instant_ruins = false
	_perf_line("builder like the real game (not rushed)", await _measure(4.0), base)
	b.instant_ruins = true
	for mi: MeshInstance3D in looks:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_perf_line("- piece shadows", await _measure(3.0), base)
	for mi: MeshInstance3D in looks:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.visible = false
	_perf_line("- piece looks (hidden)", await _measure(3.0), base)
	for mi: MeshInstance3D in looks:
		mi.visible = true
	for l: Light3D in shadowed:
		l.shadow_enabled = false
	_perf_line("- all light shadows", await _measure(3.0), base)
	for l: Light3D in shadowed:
		l.shadow_enabled = true
	for l: Light3D in lights:
		l.visible = false
	_perf_line("- all lights", await _measure(3.0), base)
	for l: Light3D in lights:
		l.visible = true
	for p: Node in pieces:
		(p as PieceNode).process_mode = Node.PROCESS_MODE_DISABLED  # (takes its solid shapes out of physics too)
	_perf_line("- piece collision", await _measure(3.0), base)
	for p: Node in pieces:
		(p as PieceNode).process_mode = Node.PROCESS_MODE_INHERIT
	for n in ["GlowSwarms", "Ambience"]:
		var node := _main.get_node_or_null(n)
		if node is Node3D:
			(node as Node3D).visible = false
			_perf_line("- %s" % n, await _measure(3.0), base)
			(node as Node3D).visible = true
	var env: Environment = (_main.get_node("Ambience") as Ambience).env
	env.volumetric_fog_enabled = false
	_perf_line("- volumetric fog", await _measure(3.0), base)
	env.volumetric_fog_enabled = true
	get_viewport().scaling_3d_scale = 0.5
	_perf_line("- half resolution (GPU test)", await _measure(3.0), base)
	get_viewport().scaling_3d_scale = 1.0


func _shot(folder: String, file: String, at: Vector3, look: Vector3) -> void:
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.global_position = at
	cam.look_at(look)
	cam.make_current()
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	print("RUIN_TEST shot ", _main.take_screenshot(folder.path_join(file)))
	cam.queue_free()
