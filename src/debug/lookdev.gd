extends Node
## Look test: visits a few fixed spots (Mossy spawn, a ruin, the great hall, the Fungal Jungle),
## takes the same screenshots every time, prints the frame rate, then quits.
## Use it to compare "before" and "after" for any visual change.
##   godot --audio-driver Dummy --path . -- seed=42 lookdev shots=/some/folder
## (Tip: put "autopilot" in the shots folder name so the OBS auto-recorder skips the run.)

var _main: Node
var _shots := "user://lookdev"
var _fps: Array[float] = []
var _clean := false  ## true = hide the HUD in the pictures
var _plants := false  ## true = only close-ups of the cave plants and crystals (cave_plants.py models), then quit
var _kinds := false  ## true = one picture of each passage kind and room shape (cave layout 2, F211), then quit
var _cover := false  ## true = only close-ups of the cave life (moss, grass, small roots, lichen, ferns; cave_cover.py)


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
		elif arg == "clean":
			_clean = true
		elif arg == "plants":
			_plants = true
		elif arg == "cover":
			_cover = true
		elif arg == "kinds":
			_kinds = true
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _process(_delta: float) -> void:
	if _main.is_ready_to_play():
		_fps.append(Engine.get_frames_per_second())


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	print("  screenshot: ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _teleport(dwarf: Dwarf, to: Vector3, look_at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = to
	var w: World = _main.world
	for i in 400:
		if w.terrain.is_area_meshed(AABB(to - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await get_tree().process_frame
	var dir := look_at - (to + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(0.6)
	dwarf.set_physics_process(true)
	await _wait(1.2)


## A camera in front of the dwarf, looking at them (the normal camera only sees their back).
func _portrait(dwarf: Dwarf, name: String, delay: float = 0.3, side_amount: float = 0.9) -> void:
	var cam := Camera3D.new()
	cam.fov = 45.0
	add_child(cam)
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	cam.global_position = dwarf.global_position + fwd * 2.6 + side * side_amount * 2.6 + Vector3.UP * 1.3
	cam.look_at(dwarf.global_position + Vector3.UP * 0.75)
	cam.make_current()
	await _wait(delay)
	await _shot(name)
	dwarf.camera.make_current()
	cam.queue_free()


## A free camera 3.5 m from the nearest wall of the first cavern, looking at it with a warm light.
func _wall_shot(maker: CaveMaker, name: String, turn: float) -> void:
	var from: Vector3 = maker.cavern_spawn + Vector3.UP * 1.6
	var best := Vector3.INF
	for k in 16:
		var a := turn + k * TAU / 16.0
		var hit := GlowPlacer._march(maker, from, Vector3(cos(a), 0.0, sin(a)), 30.0)
		if hit != Vector3.INF and from.distance_to(hit) > 4.5:
			best = hit
			break
	if best == Vector3.INF:
		return
	var cam := Camera3D.new()
	add_child(cam)
	var back := (from - best).normalized()
	cam.global_position = best + back * 3.5 + Vector3.UP * 0.4
	cam.look_at(best + Vector3.UP * 0.2)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 14.0
	lamp.light_energy = 2.2
	lamp.light_color = Color(1.0, 0.85, 0.65)
	cam.add_child(lamp)
	cam.make_current()
	await _wait(0.8)
	await _shot(name)
	_main.dwarf.camera.make_current()
	cam.queue_free()


## Close-ups of the nearest root, mushroom, crystal and giant mushroom, lit like a lantern, from two sides each.
func _plant_shots(dwarf: Dwarf) -> void:
	var glow: GlowField = _main.glow
	var want := {"root": [GlowPlacer.ROOT], "glowcap": ["glowcap", "hollowcap", "bellcap"], "crystal": ["crystal", "crystal_green"],
		"giant": [GlowPlacer.GIANT]}
	var all := glow._spots.values()
	for name in want:
		var best := {}
		for s in all:
			if s.kind in want[name] and (best.is_empty() or s.pos.distance_to(dwarf.global_position) < best.pos.distance_to(dwarf.global_position)):
				best = s
		if best.is_empty():
			continue
		var size := 6.0 if name == "giant" else (2.2 if name == "root" else 1.6)
		var n: Vector3 = best.normal
		for k in 2:
			var a := float(k) * 2.0 + 0.6
			var side := n.cross(Vector3.FORWARD if absf(n.y) > 0.9 else Vector3.UP).normalized().rotated(n, a)
			var target: Vector3 = best.pos + n * size * 0.3
			await _teleport(dwarf, target + side * (size + 1.5) + Vector3.UP * 0.5, target)
			var cam := Camera3D.new()
			cam.fov = 45.0
			add_child(cam)
			cam.global_position = target + side * size + n * size * 0.35
			cam.look_at(target, Vector3.UP)
			var lamp := OmniLight3D.new()
			lamp.omni_range = 12.0
			lamp.light_energy = 1.6
			lamp.light_color = Color(1.0, 0.85, 0.65)
			cam.add_child(lamp)
			cam.make_current()
			await _wait(1.0)
			await _shot("p_%s_%d" % [name, k])
			dwarf.camera.make_current()
			cam.queue_free()


## Close-ups of the cave life nearest the start (moss, moss over a ledge, grass, both small roots, lichen, a fern),
## lit like a lantern; then the patch round the first moss from a dwarf's height, and the dwarf standing in grass
## (it leans away).
func _cover_shots(dwarf: Dwarf) -> void:
	var life: CaveLife = _main.cave_life
	if life == null:
		return
	print("  cave life: %d plants" % life.count())
	var home := dwarf.global_position
	var lamp_cam := func(at: Vector3, look: Vector3, name: String) -> void:
		var cam := Camera3D.new()
		cam.fov = 45.0
		add_child(cam)
		cam.global_position = at
		cam.look_at(look, Vector3.UP)
		var lamp := OmniLight3D.new()
		lamp.omni_range = 12.0
		lamp.light_energy = 1.6
		lamp.light_color = Color(1.0, 0.85, 0.65)
		cam.add_child(lamp)
		cam.make_current()
		await _wait(1.0)
		await _shot(name)
		dwarf.camera.make_current()
		cam.queue_free()
	for kind in ["moss", "moss_drape", "grass", "rootlet", "rootlet_b", "lichen", "fern"]:
		var xf := life.nearest(kind, home)
		if xf.origin == Vector3.INF:
			print("  no %s in this cave" % kind)
			continue
		var n := xf.basis.y.normalized()
		var size := 1.7 if kind == "moss_drape" else 1.2
		var target := xf.origin + n * 0.12
		var side := n.cross(Vector3.FORWARD if absf(n.y) > 0.9 else Vector3.UP).normalized()
		if kind == "moss_drape":  # look at the curtain from the drop side
			side = xf.basis.z.normalized() * -1.0
			n = Vector3.UP
			target = xf.origin + Vector3.DOWN * 0.15
		await _teleport(dwarf, target + n * 1.2 + n.cross(side) * 2.4, target)  # loads the rock round it; the dwarf stands aside
		var at := _clear_view(dwarf, target, n, side, size, size * 0.5)
		if at == Vector3.INF:
			print("  %s: no clear view" % kind)
			continue
		await lamp_cam.call(at, target, "q_" + kind)
	# What a player sees: the normal camera behind the dwarf, a few metres from the patch round the nearest moss.
	var m := life.nearest("moss", home)
	if m.origin != Vector3.INF:
		var stand := _clear_view(dwarf, m.origin + Vector3.UP * 0.3, Vector3.UP, Vector3.RIGHT, 4.5, 0.6)
		if stand != Vector3.INF:
			await _teleport(dwarf, stand, m.origin)
			await _shot("q_patch")
	# The dwarf standing in grass: it leans away.
	var g := life.nearest("grass", home)
	if g.origin != Vector3.INF:
		await _teleport(dwarf, g.origin + Vector3.UP * 0.4, g.origin + Vector3(1, 0, 0))
		var at := _clear_view(dwarf, g.origin + Vector3.UP * 0.35, Vector3.UP, Vector3.RIGHT, 2.8, 1.0)
		if at != Vector3.INF:
			await lamp_cam.call(at, g.origin + Vector3.UP * 0.35, "q_grass_push")


## A camera spot `dist` from target (lifted `lift` along up) with nothing in between: no ruin wall, rock or dwarf in
## the way, and not inside anything. Tries 8 directions round `up`, starting at `side`. INF when all are blocked.
func _clear_view(dwarf: Dwarf, target: Vector3, up: Vector3, side: Vector3, dist: float, lift: float) -> Vector3:
	var space := dwarf.get_world_3d().direct_space_state
	for k in 8:
		var at := target + side.rotated(up, k * TAU / 8.0) * dist + up * lift + Vector3.UP * 0.15
		var there := PhysicsRayQueryParameters3D.create(at, target)
		there.exclude = [dwarf.get_rid()]
		var hit := space.intersect_ray(there)
		if not hit.is_empty() and (hit.position as Vector3).distance_to(target) > 0.3:
			continue
		var back := PhysicsRayQueryParameters3D.create(target + up * 0.05, at)  # (a ray from inside a wall doesn't see it)
		back.exclude = [dwarf.get_rid()]
		if space.intersect_ray(back).is_empty():
			return at
	return Vector3.INF


## The nearest passage of each kind (tube, canyon, keyhole, low, rift) and room of each shape (dome, flat ceiling,
## fallen roof) to the start, seen from a dwarf's eye height with a strong lantern (the owner's check, F211).
##   godot --audio-driver Dummy --path . -- seed=42 layout=2 lookdev kinds clean shots=/folder_autopilot
func _kind_shots(dwarf: Dwarf, maker: CaveMaker) -> void:
	var home := dwarf.global_position
	for k in CaveMaker.KIND_NAMES.size():
		var best: Dictionary = {}
		var bd := INF
		for s in maker.segments:
			if int(s.get("k", 0)) != k:
				continue
			var mid: Vector3 = ((s.a as Vector3) + s.b) * 0.5
			var d := mid.distance_to(home)
			if d < bd and (s.a as Vector3).distance_to(s.b) > 4.0 and maker.sdf_at(mid) > 0.5:
				bd = d
				best = s
		if best.is_empty():
			print("  no %s passage" % CaveMaker.KIND_NAMES[k])
			continue
		var a: Vector3 = best.a
		var b: Vector3 = best.b
		var fl := maker.find_floor(a.x, a.z, a.y)
		var eye := (fl if fl != Vector3.INF else a) + Vector3.UP * 1.5
		await _lamp_shot(dwarf, eye, b + (b - a).normalized() * 6.0 + Vector3.UP * 0.5, "k_%d_%s" % [k, CaveMaker.KIND_NAMES[k]], 14.0)
	for shape in CaveMaker.SHAPE_NAMES.size():
		var best: Dictionary = {}
		var bd := INF
		for r in maker.rooms:
			if int(r.get("shape", 0)) != shape or r.get("sealed", false) or (r.radii as Vector3).x < 8.0:
				continue
			var d: float = (r.center as Vector3).distance_to(home)
			if d < bd:
				bd = d
				best = r
		if best.is_empty():
			print("  no %s room" % CaveMaker.SHAPE_NAMES[shape])
			continue
		var c: Vector3 = best.center
		var rad: Vector3 = best.radii
		# From the room's edge, low down, looking across to the far side and up a little.
		var at := c + Vector3(-rad.x * 0.7, 0, 0)
		var fl := maker.find_floor(at.x, at.z, c.y)
		var eye := (fl if fl != Vector3.INF else at) + Vector3.UP * 1.6
		await _lamp_shot(dwarf, eye, c + Vector3(rad.x * 0.6, rad.y * 0.15, 0), "r_%d_%s" % [shape, CaveMaker.SHAPE_NAMES[shape]], 40.0)
	# Layout 3 (F230, F231): one of each cavern proportion, a joined cavern, and a cliff exit (from the top, and the
	# ledge path seen from the floor).
	for prop in range(1, CaveMaker.PROP_NAMES.size()):
		var best := _nearest_room(maker, home, func(r: Dictionary) -> bool: return int(r.get("prop", 0)) == prop and not r.has("lobe_of"))
		if best.is_empty():
			continue
		var c: Vector3 = best.center
		var rad: Vector3 = best.radii
		var at := c + Vector3(-rad.x * 0.75, 0, 0)
		var fl := maker.find_floor(at.x, at.z, c.y)
		var eye := (fl if fl != Vector3.INF else at) + Vector3.UP * 1.6
		var look := c + Vector3(rad.x * 0.6, rad.y * (0.6 if prop >= CaveMaker.PROP_TALL_NARROW else 0.1), 0)
		await _lamp_shot(dwarf, eye, look, "p_%d_%s" % [prop, CaveMaker.PROP_NAMES[prop]], 70.0)
	var lobe := _nearest_room(maker, home, func(r: Dictionary) -> bool: return r.has("lobe_of"))
	if not lobe.is_empty():
		var main_c: Vector3 = maker.rooms[int(lobe.lobe_of)].center
		var lc: Vector3 = lobe.center
		var fl := maker.find_floor(main_c.x, main_c.z, main_c.y)
		var eye := (fl if fl != Vector3.INF else main_c) + Vector3.UP * 1.6 + (main_c - lc).normalized() * 6.0
		await _lamp_shot(dwarf, eye, lc + Vector3.UP * 4.0, "j_joined", 80.0)
	var cliff := _nearest_room(maker, home, func(r: Dictionary) -> bool: return r.has("cliff"))
	if not cliff.is_empty():
		var top: Vector3 = cliff.cliff
		var c: Vector3 = cliff.center
		var out := Vector3(top.x - c.x, 0, top.z - c.z).normalized()
		await _lamp_shot(dwarf, top + out * 3.0 + Vector3.UP * 0.8, c + Vector3.DOWN * (cliff.radii as Vector3).y * 0.4, "c_cliff_top", 80.0)
		var fl := maker.find_floor(c.x, c.z, c.y)
		await _lamp_shot(dwarf, (fl if fl != Vector3.INF else c) + Vector3.UP * 1.6 - out * 4.0, top, "c_cliff_from_floor", 80.0)
	# Dripstone (F232): the nearest few to the start, from below, lit like a lantern.
	var clutter := _main.get_node_or_null("Clutter") as Clutter
	if clutter:
		var shots := 0
		for kind in Clutter.DRIPS:
			var best := Vector3.INF
			for it in clutter._drips[kind]:
				var p: Vector3 = (it[0] as Transform3D).origin
				if best == Vector3.INF or p.distance_to(home) < best.distance_to(home):
					best = p
			if best == Vector3.INF:
				continue
			var bx: Transform3D = clutter._drips[kind][0][0]
			for it in clutter._drips[kind]:
				if (it[0] as Transform3D).origin == best:
					bx = it[0]
			print("  %s: %d placed; nearest at %s (rock here %.2f, 0.5 m below %.2f, 1.5 m below %.2f), size %.2f, its up %s" % [kind,
				clutter._drips[kind].size(), best.round(), maker.sdf_at(best), maker.sdf_at(best + Vector3.DOWN * 0.5),
				maker.sdf_at(best + Vector3.DOWN * 1.5), bx.basis.get_scale().x, bx.basis.y.normalized().round()])
			var eye := best + Vector3(2.6, -3.2, 1.8)  # close, a little below and to the side (in the air is fine)
			await _lamp_shot(dwarf, eye, best + Vector3.DOWN * 0.9, "d_%s" % kind, 14.0)
			shots += 1
	# Rock shelves (F232): the nearest of each kind, from in front of it.
	if clutter:
		for kind in Clutter.SHELVES:
			var best := Transform3D()
			var bd := INF
			for mmi: MultiMeshInstance3D in clutter._drip_cells.get(kind, []):
				for i in mmi.multimesh.instance_count:
					var xf := mmi.multimesh.get_instance_transform(i)
					var d := xf.origin.distance_to(home)
					if d < bd:
						bd = d
						best = xf
			if bd == INF:
				print("  no %s" % kind)
				continue
			var out := best.basis.z.normalized()
			var sz := best.basis.get_scale().x
			await _lamp_shot(dwarf, best.origin + out * 1.7 * sz + Vector3.UP * 0.5 * sz + best.basis.x.normalized() * 0.6 * sz,
				best.origin + out * 0.15 * sz, "s_%s" % kind, 8.0)
	# Layout 4: the huge first cavern's star ceiling, from its floor (owner F260).
	var first := maker.first_cavern()
	if not first.is_empty():
		var fc: Vector3 = first.center
		var ffl := maker.find_floor(fc.x + 20.0, fc.z, fc.y)
		var feye := (ffl if ffl != Vector3.INF else fc) + Vector3.UP * 1.7
		await _lamp_shot(dwarf, feye, fc + Vector3(-25.0, (first.radii as Vector3).y * 0.9, 5.0), "f_first_cavern", 1.0)
		# Layout 5: its stone columns (owner F263), with every light on (F7) so the whole hall shows.
		if not maker._cols.is_empty():
			var amb: Ambience = _main.get_node_or_null("Ambience")
			if amb:
				amb.set_dev_bright(true)
			var o: Vector4 = maker._cols[0]
			var away := (Vector2(o.x, o.y) - Vector2(fc.x, fc.z)).normalized()
			var ep := Vector2(o.x, o.y) - away * (o.z * 1.4 + 22.0)  # in front of it, toward the middle
			var efl := maker.find_floor(ep.x, ep.y, fc.y)
			var ceye := (efl if efl != Vector3.INF else Vector3(ep.x, fc.y, ep.y)) + Vector3.UP * 9.0
			await _lamp_shot(dwarf, ceye, Vector3(o.x, (maker._col_floor + maker._col_top) * 0.5, o.y), "f_columns_lit", 1.0)
			if amb:
				amb.set_dev_bright(false)
	# The star snake (terrain.gdshader snake()): where the head of the snake over the nearest big cavern is now.
	var big := _nearest_room(maker, home, func(r: Dictionary) -> bool: return r.big and (r.radii as Vector3).y > 9.0)
	if not big.is_empty():
		var c: Vector3 = big.center
		var cell := ((Vector2(c.x, c.z)) / 40.0).floor()
		var mid := (cell + Vector2(0.5, 0.5)) * 40.0
		var t := fmod(Time.get_ticks_msec() / 1000.0 + 2.5, 3600.0)  # (+ the shot's own wait)
		var h1 := GlowPlacer._shader_hash(Vector3(cell.x, cell.y, 11.0))
		var h2 := GlowPlacer._shader_hash(Vector3(cell.x, cell.y, 23.0))
		var tt := t * (0.05 + 0.05 * h1) + h2 * 50.0
		var head := mid + Vector2(sin(tt * 1.7) * 11.0 + sin(tt * 3.1 + 1.3) * 5.0, sin(tt * 1.3 + 2.0) * 11.0 + cos(tt * 2.7) * 5.0)
		var up := GlowPlacer._march(maker, Vector3(head.x, c.y, head.y), Vector3.UP, 60.0)
		if up != Vector3.INF:
			await _lamp_shot(dwarf, up + Vector3(4.0, -9.0, 3.0), up, "z_star_snake", 1.0)
	# The water drip (the ringed dripstone with falling drops) in the first cavern, from the side.
	for s in GlowPlacer.place(maker):
		if s.kind == GlowPlacer.DRIP:
			await _lamp_shot(dwarf, s.pos + Vector3(2.0, -1.6, 1.2), s.pos + Vector3.DOWN * 0.6, "w_water_drip", 8.0)
			break
	# Hanging roots (F232): the nearest of each kind, from below and to the side.
	if clutter:
		for kind in Clutter.HROOTS:
			var best := Transform3D()
			var bd := INF
			for mmi: MultiMeshInstance3D in clutter._drip_cells.get(kind, []):
				for i in mmi.multimesh.instance_count:
					var xf := mmi.multimesh.get_instance_transform(i)
					if xf.origin.distance_to(home) < bd:
						bd = xf.origin.distance_to(home)
						best = xf
			if bd == INF:
				print("  no %s" % kind)
				continue
			var sz := best.basis.get_scale().x
			print("  %s: nearest size %.1f" % [kind, sz])
			await _lamp_shot(dwarf, best.origin + Vector3(1.0, 0, 0.6).normalized() * 2.2 * sz + Vector3.DOWN * 1.1 * sz,
				best.origin + Vector3.DOWN * 0.6 * sz, "h_%s" % kind, 6.0 * sz)
	print("  kinds: done")


func _nearest_room(maker: CaveMaker, home: Vector3, ok: Callable) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	for r in maker.rooms:
		if r.get("sealed", false) or not ok.call(r):
			continue
		var d: float = (r.center as Vector3).distance_to(home)
		if d < bd:
			bd = d
			best = r
	return best


func _lamp_shot(dwarf: Dwarf, eye: Vector3, look: Vector3, name: String, reach: float) -> void:
	await _teleport(dwarf, eye - Vector3.UP * 1.4, look)
	var cam := Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	var lamp := OmniLight3D.new()
	lamp.omni_range = reach
	lamp.light_energy = 2.2
	lamp.light_color = Color(1.0, 0.86, 0.68)
	cam.add_child(lamp)
	cam.make_current()
	dwarf.visible = false  # the camera stands where the dwarf is: its lantern and pickaxe would fill the picture
	await _wait(1.5)
	await _shot(name)
	dwarf.visible = true
	dwarf.camera.make_current()
	cam.queue_free()


func _run() -> void:
	while not _main.is_ready_to_play():
		await _wait(0.25)
	var dwarf: Dwarf = _main.dwarf
	var maker: CaveMaker = _main.world.maker
	Controls.set_captured(true)  # robots never grab the real mouse (Controls handles it)
	_main.hud.set_paused(false)
	if _clean:
		_main.hud.visible = false
	await _wait(2.0)
	if _plants:
		await _plant_shots(dwarf)
		get_tree().quit()
		return
	if _cover:
		await _cover_shots(dwarf)
		get_tree().quit()
		return
	if _kinds:
		await _kind_shots(dwarf, maker)
		get_tree().quit()
		return
	await _shot("a_spawn")
	# Cave walls up close, lit like a lantern (to compare rock styles: rock=blocks|slabs|ledges|mixed|round).
	await _wall_shot(maker, "w_wall", 0.0)
	await _wall_shot(maker, "w_wall2", PI)
	await _portrait(dwarf, "b_dwarf_portrait")
	await _portrait(dwarf, "b1_dwarf_side", 0.3, -1.0)
	dwarf.model.swing(0.55)
	await _portrait(dwarf, "b2_dig_windup", 0.18, 1.2)
	dwarf.model.swing(0.55)
	await _wait(0.6)
	dwarf.model.swing(0.55)
	await _portrait(dwarf, "b3_dig_strike", 0.32, 1.2)
	await _wait(0.6)
	dwarf.bot_move = Vector2(0, -1)
	await _wait(0.6)
	await _portrait(dwarf, "b4_walking", 0.02, 1.4)
	dwarf.bot_move = Vector2.ZERO
	dwarf._yaw += PI * 0.66
	dwarf._pitch = 0.1
	await _wait(0.8)
	await _shot("c_spawn_look")
	dwarf._pitch = 0.75  # look up: ceiling roots and stalactites
	await _wait(0.6)
	await _shot("c2_ceiling")
	dwarf._pitch = 0.1
	# Walk forward for a moment (animations).
	dwarf.bot_move = Vector2(0, -1)
	await _wait(0.7)
	await _shot("d_walking")
	dwarf.bot_move = Vector2.ZERO
	# The first three creatures, in the cave: a snail and a beetle ahead, a bat hanging above.
	var mm: MonsterManager = GameAuthority.instance.monsters
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	var place := func(kind: String, off: Vector3) -> void:
		var at: Vector3 = maker.find_floor(dwarf.global_position.x + off.x, dwarf.global_position.z + off.z, dwarf.global_position.y + 2.0)
		mm._ev_spawn(mm._next_uid, kind, at + Vector3.UP * 0.3, false, 0)
		mm._next_uid += 1
	place.call("rock_snail", fwd * 4.0 - side * 1.5)
	place.call("rock_beetle", fwd * 4.5 + side * 1.6)
	place.call("cave_bat", fwd * 6.0 + Vector3.UP * 2.5)
	await _wait(1.5)
	await _shot("d2_creatures")
	for m in mm.monsters.values():
		mm._ev_remove(m.uid)
	var ruin: Dictionary = maker.pois_of("ruin")[0]
	await _teleport(dwarf, ruin.pos + Vector3(0, 1.0, 6.0), ruin.pos)
	await _shot("e_ruin")
	var hall: Dictionary = maker.pois_of("great_hall")[0]
	await _teleport(dwarf, hall.pos + Vector3(0, 1.0, 12.0), hall.pos + Vector3.UP * 2.0)
	await _shot("f_great_hall")
	var grove: Dictionary = maker.pois_of("lantern_grove")[0]
	await _teleport(dwarf, grove.pos + Vector3(0, 1.5, 14.0), grove.pos + Vector3.UP * 2.5)
	await _shot("g_jungle_grove")
	await _portrait(dwarf, "h_jungle_portrait")
	var avg := 0.0
	var low := 9999.0
	for f in _fps:
		avg += f
		low = minf(low, f)
	if not _fps.is_empty():
		avg /= _fps.size()
	print("  fps: average %.0f, lowest %.0f" % [avg, low])
	get_tree().quit()
