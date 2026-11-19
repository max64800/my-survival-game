extends Node
## Art pack lineup: today's placeholder dwarf next to free CC0 character candidates, in the
## cave with lantern light, squashed into dwarf proportions. Takes screenshots, then quits.
##   godot --path . -- seed=42 nomonsters artpreview shots=/some/folder
## With "creatures": each creature (Rock Snail, Cave Bat, Rock Beetle) in all 4 looks (mossy, frost,
## ember, spore) next to the Forge workbench, same cave light (docs/art/CREATURE-STYLE.md, step 8).

const CANDIDATES := [
	["res://assets/art_candidates/quaternius_adventurer.glb", "Quaternius Adventurer (CC0, 24 animations)"],
	["res://assets/art_candidates/quaternius_hooded.glb", "Quaternius Hooded Adventurer (CC0, 24 animations)"],
	["res://assets/art_candidates/polygonalmind_adventurer.glb", "Polygonal Mind Adventurer (CC0, no animations)"],
]
const DWARF_SHAPE := Vector3(1.15, 0.78, 1.15)  ## shorter and stockier than a human

var _main: Node
var _shots := "user://artpreview"


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _run() -> void:
	while not (_main.world and _main.is_ready_to_play()):
		await _wait(0.25)
	await _wait(1.0)
	if "procbench" in OS.get_cmdline_user_args():
		await _procbench()
		get_tree().quit()
		return
	if "vinetest" in OS.get_cmdline_user_args():
		await _vinetest()
		get_tree().quit()
		return
	if "perfbench" in OS.get_cmdline_user_args():
		await _perfbench()
		get_tree().quit()
		return
	if "treestages" in OS.get_cmdline_user_args():
		await _treestages()
		get_tree().quit()
		return
	if "digbench" in OS.get_cmdline_user_args():
		await _digbench()
		get_tree().quit()
		return
	if "chunkbench" in OS.get_cmdline_user_args():
		await _chunkbench()
		get_tree().quit()
		return
	if "boulders" in OS.get_cmdline_user_args():
		await _boulders()
		print("ARTPREVIEW done: ", _shots)
		get_tree().quit()
		return
	if "creatures" in OS.get_cmdline_user_args():
		await _creatures()
		print("ARTPREVIEW done: ", _shots)
		get_tree().quit()
		return
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	var base := dwarf.global_position + fwd * 4.0
	var lineup := Node3D.new()
	_main.add_child(lineup)
	for i in CANDIDATES.size():
		var c: Array = CANDIDATES[i]
		var scene: PackedScene = load(c[0])
		var m: Node3D = scene.instantiate()
		lineup.add_child(m)
		var spot := base + side * (1.6 * (i + 1) - 1.6)
		m.global_position = _main.world.maker.find_floor(spot.x, spot.z, dwarf.global_position.y + 2.0)
		m.rotation.y = dwarf._yaw + PI  # face the camera
		_fit(m, 1.35)
		for ap in m.find_children("*", "AnimationPlayer", true, false):
			var names: PackedStringArray = ap.get_animation_list()
			for want in ["CharacterArmature|Idle", "Idle"]:
				if want in names:
					ap.play(want)
					break
		var label := Label3D.new()
		label.text = "%d. %s" % [i + 2, c[1]]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.004
		label.font_size = 40
		label.outline_size = 8
		label.position = Vector3.UP * 1.9
		m.add_child(label)
	var me := Label3D.new()
	me.text = "1. Today's placeholder dwarf"
	me.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	me.pixel_size = 0.004
	me.font_size = 40
	me.outline_size = 8
	me.position = Vector3.UP * 1.9
	dwarf.add_child(me)
	dwarf.global_position = base - side * 1.6
	dwarf.global_position = _main.world.maker.find_floor(dwarf.global_position.x, dwarf.global_position.z, dwarf.global_position.y + 2.0)
	dwarf.model.rotation.y = dwarf._yaw + PI
	# Camera: step back and look at the lineup.
	dwarf._yaw += PI
	dwarf._pitch = -0.1
	var cam_pos := base + side * 0.8 - fwd * -5.5 + Vector3.UP * 1.6
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.global_position = cam_pos
	cam.look_at(base + side * 0.8 + Vector3.UP * 0.8)
	cam.current = true
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.52)
	light.omni_range = 12.0
	light.light_energy = 1.7
	_main.add_child(light)
	light.global_position = cam_pos + Vector3.UP * 0.5
	_main.hud.visible = false
	cam.global_position = base + side * 0.8 + fwd * 4.0 + Vector3.UP * 1.4
	cam.look_at(base + side * 0.8 + Vector3.UP * 0.7)
	light.global_position = cam.global_position + Vector3.UP * 0.5
	await _wait(1.5)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("art_lineup.png"))
	cam.global_position = base + side * 1.6 + fwd * 2.2 + Vector3.UP * 1.0
	cam.look_at(base + side * 1.6 + Vector3.UP * 0.7)
	light.global_position = cam.global_position + Vector3.UP * 0.4
	await _wait(0.5)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("art_closeup.png"))
	print("ARTPREVIEW done: ", _shots)
	get_tree().quit()


## Scale a model so it's `height` meters tall, with dwarf proportions.
func _fit(m: Node3D, height: float) -> void:
	var aabb := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	if aabb.size.y > 0.001:
		var s := height / aabb.size.y  # same height as our dwarf…
		m.scale = Vector3(s * 1.25, s, s * 1.25)  # …but wider and stockier, like a dwarf


# ---------------------------------------------------------------- creatures next to the workbench
const LOOKS := {"": "mossy", "blue": "frost", "red": "ember", "green": "spore"}
const CREATURES := [["rock_snail", "Rock Snail"], ["cave_bat", "Cave Bat"], ["rock_beetle", "Rock Beetle"]]


func _creatures() -> void:
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	Controls.set_captured(true)
	_main.hud.visible = false
	dwarf.visible = false
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	var base := dwarf.global_position + fwd * 4.0
	var floor_at := func(p: Vector3) -> Vector3:
		return _main.world.maker.find_floor(p.x, p.z, dwarf.global_position.y + 2.0)
	# The workbench, exactly as the game shows it.
	var bench: Node3D = Look.forged("stations", "workbench")
	if bench:
		_main.add_child(bench)
		bench.global_position = floor_at.call(base)
		bench.rotation.y = dwarf._yaw + PI * 0.85
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.current = true
	var light := OmniLight3D.new()  # a lantern beside the camera, like the player's
	light.light_color = Color(1.0, 0.78, 0.52)
	light.omni_range = 12.0
	light.light_energy = 1.8
	_main.add_child(light)
	var fill := OmniLight3D.new()  # a second lantern for the group pictures
	fill.light_color = Color(1.0, 0.85, 0.65)
	fill.omni_range = 9.0
	fill.light_energy = 1.2
	_main.add_child(fill)
	for c in CREATURES:
		var data: Dictionary = Monsters.LIST[c[0]]
		var lineup := Node3D.new()
		_main.add_child(lineup)
		var i := 0
		for variant in LOOKS:
			var m := MonsterModel.build(data.shape, data.color, data.size, false, c[0], 0, variant)
			var stand := Node3D.new()
			lineup.add_child(stand)
			stand.add_child(m)
			var spot: Vector3 = base + side * (1.6 + 1.7 * i) + fwd * 0.2
			stand.global_position = floor_at.call(spot) + (Vector3.UP * 0.9 if c[0] == "cave_bat" else Vector3.ZERO)
			stand.rotation.y = dwarf._yaw + {"rock_snail": -0.5, "cave_bat": 0.0, "rock_beetle": -0.45}[c[0]]  # facing the camera like the pictures
			MonsterModel.animate(m, 0.0 if c[0] != "cave_bat" else 1.5, data.size, 0.3)
			var label := Label3D.new()
			label.text = "%s: %s" % [c[1], LOOKS[variant]]
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.pixel_size = 0.004
			label.font_size = 36
			label.outline_size = 8
			label.position = Vector3.UP * 1.7
			stand.add_child(label)
			i += 1
		# Close-up: the mossy one right next to the workbench.
		var mid: Vector3 = base + side * 0.8
		cam.global_position = mid + fwd * 3.2 + Vector3.UP * 1.3 - side * 0.3
		cam.look_at(mid + Vector3.UP * 0.6)
		light.global_position = cam.global_position + Vector3.UP * 0.4 + side * 0.5
		fill.global_position = mid + fwd * 1.5 + Vector3.UP * 2.0
		await _wait(0.6)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("creature_%s_closeup.png" % c[0]))
		# All four looks, with the workbench on the left.
		var mid4: Vector3 = base + side * 3.2
		cam.global_position = mid4 + fwd * 4.8 + Vector3.UP * 1.5
		cam.look_at(mid4 + Vector3.UP * 0.45)
		light.global_position = cam.global_position + Vector3.UP * 0.3
		fill.global_position = mid4 + fwd * 2.0 + Vector3.UP * 2.0
		await _wait(0.4)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("creature_%s_looks.png" % c[0]))
		lineup.queue_free()
		await _wait(0.1)
	await _live(base, fwd, side, cam, light, fill)


## Real game monsters (with their real collision) beside the workbench: a beetle winding up its charge
## (the attack warning: red eyes, its glow blazing, head down), a snail hiding, a bat in the air.
func _live(base: Vector3, fwd: Vector3, side: Vector3, cam: Camera3D, light: OmniLight3D, fill: OmniLight3D) -> void:
	var mm: MonsterManager = GameAuthority.instance.monsters
	var spots := {"rock_beetle": [1.6, "red"], "rock_snail": [3.3, "green"], "cave_bat": [4.9, "blue"]}
	var made := {}
	for kind in spots:
		var at: Vector3 = base + side * float(spots[kind][0])
		at = _main.world.maker.find_floor(at.x, at.z, at.y + 2.0) + Vector3.UP * (1.2 if kind == "cave_bat" else 0.3)
		var uid: int = mm._next_uid
		mm._ev_spawn(uid, kind, at, false, 99, spots[kind][1])
		mm._next_uid = uid + 1
		made[kind] = mm.monsters[uid]
		(made[kind] as Monster).state = Monster.State.IDLE  # awake (a sleeping bat would hang from the floor)
	mm.set_physics_process(false)  # a still life
	await _wait(0.3)
	for kind in made:
		var m: Monster = made[kind]
		m.model.rotation.y = atan2(-fwd.x, -fwd.z) + PI - 0.4  # face the camera
		var cap: CapsuleShape3D = (m.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D).shape
		print("LIVE ", kind, " ", m.variant, ": collision capsule radius %.2f height %.2f, look %s" % [cap.radius, cap.height, m.model.get_meta("variant_look", false)])
	(made["rock_beetle"] as Monster).show_tell(3.0, "Charge")
	MonsterModel.set_shell((made["rock_snail"] as Monster).model, true)
	(made["rock_snail"] as Monster).shell_shut = true
	await _wait(1.2)
	var mid: Vector3 = base + side * 3.2
	cam.global_position = mid + fwd * 4.6 + Vector3.UP * 1.6
	cam.look_at(mid + Vector3.UP * 0.5)
	light.global_position = cam.global_position + Vector3.UP * 0.3
	fill.global_position = mid + fwd * 2.0 + Vector3.UP * 2.0
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("creature_live_attack_warning.png"))
	var b: Vector3 = (made["rock_beetle"] as Monster).global_position
	cam.global_position = b + fwd * 2.4 + Vector3.UP * 1.0 + side * 0.4
	cam.look_at(b + Vector3.UP * 0.35)
	light.global_position = cam.global_position + Vector3.UP * 0.3
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("creature_live_charge_closeup.png"))


## The breakable boulders (owner, Nov 18): the 3 nearest to the start, each from a few metres away with a lantern.
func _boulders() -> void:
	var bo: Boulders = _main.get_node_or_null("Boulders")
	if bo == null:
		return
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	_main.hud.set_paused(false)
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.current = true
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.52)
	light.omni_range = 12.0
	light.light_energy = 1.8
	_main.add_child(light)
	var list := []
	for i in 200:
		var r := bo.rock(i)
		if r.is_empty():
			break
		list.append([(r.pos as Vector3).distance_to(dwarf.global_position), i])
	list.sort()
	for k in mini(3, list.size()):
		var r := bo.rock(list[k][1])
		var p: Vector3 = r.pos
		var away := Vector3(cos(k * 2.0), 0, sin(k * 2.0))
		cam.global_position = p + away * 3.2 + Vector3.UP * 1.6
		cam.look_at(p + Vector3.UP * 0.5)
		light.global_position = cam.global_position + Vector3.UP * 0.5
		await _wait(1.0)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("boulder_%d.png" % k))


## How much the rock chunks cost (owner, Nov 18: 6 FPS now and then): break 3 boulders' worth at the dwarf's feet and
## print the frame rate and physics time for the next seconds.
func _chunkbench() -> void:
	var dwarf: Dwarf = _main.dwarf
	var at := dwarf.global_position + -Basis(Vector3.UP, dwarf._yaw).z * 3.0 + Vector3.UP * 0.8
	for k in 4:
		await _wait(0.5)
		print("BENCH before fps=%d phys=%.1fms" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
	for b in 3:
		RockShatter.burst(_main, at, Vector3.UP, Color(0.5, 0.46, 0.41), Mat.STONE)
		RockShatter.burst(_main, at, Vector3(1, 0.5, 0), Color(0.5, 0.46, 0.41), Mat.STONE)
		RockShatter.burst(_main, at, Vector3(-1, 0.5, 0), Color(0.5, 0.46, 0.41), Mat.STONE)
	for k in 12:
		await _wait(0.5)
		print("BENCH after %.1fs fps=%d phys=%.1fms chunks=%d" % [(k + 1) * 0.5, Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, RockShatter._alive.size()])


## Which part of the game's code costs the most each frame: switch each big part off for a moment and see how much
## faster the frame gets.
func _procbench() -> void:
	await _wait(8.0)
	var parts: Array[Node] = []
	for c in _main.get_children():
		parts.append(c)
	if _main.world:
		for c in _main.world.get_children():
			parts.append(c)
	await _wait(15.0)
	for round in 2:
		print("PROC all on: %.2f ms (%d nodes)" % [await _avg_process(), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	for c in parts:
		if c == self:
			continue
		var was := c.process_mode
		var on1 := await _avg_process()
		c.process_mode = Node.PROCESS_MODE_DISABLED
		var off := await _avg_process()
		c.process_mode = was
		var on2 := await _avg_process()
		var saves := (on1 + on2) * 0.5 - off
		if saves > 0.4:
			print("PROC %s (%s): saves %.2f ms (on %.1f/%.1f, off %.1f)" % [c.name, c.get_class(), saves, on1, on2, off])


func _avg_process() -> float:
	await _wait(0.4)
	var sum := 0.0
	for k in 30:
		await get_tree().process_frame
		sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	return sum / 30.0


## Mining's cost (owner, Nov 18: "43-47 FPS when I mine"): swing at the rock in front of the dwarf about twice a
## second for 20 s, like a player, and print the frame time; the worst frames tell what a hit costs.
func _digbench() -> void:
	var dwarf: Dwarf = _main.dwarf
	var auth := GameAuthority.instance
	await _wait(6.0)
	var space := dwarf.get_world_3d().direct_space_state
	var p := dwarf.global_position + Vector3.UP * 0.5
	var parts := {}
	for k in 5:
		var u := Time.get_ticks_usec()
		auth.spawn_drop("stone", 1, p)
		parts["drop"] = parts.get("drop", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		u = Time.get_ticks_usec()
		if auth.cave_life:
			auth.cave_life.breakable_at(p)
		parts["plants"] = parts.get("plants", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		u = Time.get_ticks_usec()
		auth.world.rock_material_near(p, 1.1)
		parts["material"] = parts.get("material", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		u = Time.get_ticks_usec()
		auth._host_dig(p + Vector3(k * 2.0, -1.0, 0.0), 0)
		parts["dig rock"] = parts.get("dig rock", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		u = Time.get_ticks_usec()
		RockShatter.burst(_main, p, Vector3.UP, Color.GRAY, Mat.STONE)
		parts["chunks"] = parts.get("chunks", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		u = Time.get_ticks_usec()
		ChunkSwarm.burst(_main, p, Color.GRAY, dwarf)
		parts["bits"] = parts.get("bits", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		u = Time.get_ticks_usec()
		Fx.burst(_main, p, Color.GRAY, 16, 4.0)
		parts["dust"] = parts.get("dust", "") + " %.1f" % ((Time.get_ticks_usec() - u) / 1000.0)
		await get_tree().process_frame
	print("DIG parts (ms, 5 tries each): ", parts)
	var worst := 0.0
	var frames := 0
	var sum := 0.0
	var t0 := Time.get_ticks_msec()
	var swing := 0.0
	var turns := 0
	var dug := 0
	var after := 0
	var after_kind := ""
	var after_worst := {}
	var slow_after := {}
	var count := {}
	var cost := {}
	while Time.get_ticks_msec() - t0 < 20000:
		var t := Time.get_ticks_usec()
		await get_tree().process_frame
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		frames += 1
		sum += ms
		if frames > 5:
			worst = maxf(worst, ms)
		if after > 0:
			after -= 1
			after_worst[after_kind] = maxf(after_worst.get(after_kind, 0.0), ms)
			if ms > 25.0:
				slow_after[after_kind] = slow_after.get(after_kind, 0) + 1
		swing += ms / 1000.0
		if swing > 0.5:
			swing = 0.0
			var fwd := -Basis(Vector3.UP, dwarf._yaw).z
			var from := dwarf.global_position + Vector3.UP * 1.2
			var q := PhysicsRayQueryParameters3D.create(from, from + (fwd + Vector3.DOWN * 0.9).normalized() * 3.0, World.TERRAIN_LAYER)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				dwarf._yaw += 0.7
				turns += 1
				continue
			var u0 := Time.get_ticks_usec()
			var r: Dictionary = auth.request_hit(1, hit.position, hit.normal)
			var u1 := Time.get_ticks_usec()
			dwarf._on_dig_feedback(1, r)
			var u2 := Time.get_ticks_usec()
			var k := String(r.get("state", "?"))
			cost[k + " host"] = maxf(cost.get(k + " host", 0.0), (u1 - u0) / 1000.0)
			cost[k + " effects"] = maxf(cost.get(k + " effects", 0.0), (u2 - u1) / 1000.0)
			after_kind = String(r.get("state", "?"))
			count[after_kind] = count.get(after_kind, 0) + 1
			after = 20
			if r.get("state", "") == "dug":
				dug += 1
	print("DIG frames=%d avg=%.1fms worst=%.1fms dug=%d turns=%d" % [frames, sum / frames, worst, dug, turns])
	print("DIG worst ms inside the hit itself: ", cost)
	print("DIG results ", count, " worst frame in the 20 frames after: ", after_worst, " frames over 25 ms after: ", slow_after)


## A Root Tree in every stage of growing back (owner, Nov 18): broken, step 1, step 2, whole; same camera each time.
func _treestages() -> void:
	var rp: RootPillars = _main.get_node_or_null("RootPillars")
	if rp == null:
		return
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	_main.hud.visible = false
	var best := -1
	var bd := INF
	for id in 10:
		var t := rp.pillar(id)
		if not t.is_empty() and (t.bottom as Vector3).distance_to(dwarf.global_position) < bd:
			bd = (t.bottom as Vector3).distance_to(dwarf.global_position)
			best = id
	var t := rp.pillar(best)
	var top: Vector3 = t.top
	var bottom: Vector3 = t.bottom
	var h := top.y - bottom.y
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.current = true
	cam.fov = 70.0
	var space := dwarf.get_world_3d().direct_space_state
	var mid := bottom.lerp(top, 0.5)
	var spot := mid
	var best_open := -1.0
	for k in 32:  # stand in open air where the view to the tree is clear, the furthest such spot up to h * 0.8
		var a := k * TAU / 32.0
		for dist in [h * 0.8, h * 0.65, h * 0.5]:
			var want: Vector3 = bottom + Vector3.UP * h * 0.3 + Vector3(cos(a), 0, sin(a)) * (float(t.width) * 0.35 + dist)
			if _main.world.sdf_at(want) < 1.0:
				continue
			var q := PhysicsRayQueryParameters3D.create(want, mid, World.TERRAIN_LAYER)
			var hit := space.intersect_ray(q)
			if (hit.is_empty() or (hit.position as Vector3).distance_to(mid) < float(t.width) * 0.6) and dist > best_open:
				best_open = dist
				spot = want
			break
	cam.global_position = spot
	cam.look_at(mid)
	var lights := []
	for f in [0.15, 0.5, 0.85]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.65)
		l.omni_range = h * 0.9
		l.light_energy = 2.2
		_main.add_child(l)
		l.global_position = spot.lerp(bottom.lerp(top, f), 0.4)
		lights.append(l)
	for stage in ["broken", "regrow1", "regrow2", "tree"]:
		rp._show(best, stage)
		await _wait(1.0)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("tree_%s.png" % stage))


## The speed-up run (owner, Nov 18: "optimize the hell out of it"): no frame cap, the player's own view in the first
## cave, then every big part switched off for a moment: how much faster does a frame get (drawing and game code)?
func _perfbench() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("preset="):  # measure a graphics preset (saved to a bench file, not the player's settings)
			GraphicsSettings.choose(arg.trim_prefix("preset="), "user://bench_graphics.cfg")
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0
	await _wait(20.0)
	if "quick" in OS.get_cmdline_user_args():
		for view in 2:
			if view == 1:
				_main.dwarf._yaw += PI * 0.6
				await _wait(3.0)
			var c := await _frame_cost()
			print("PERF view %d: frame %.2f ms (cpu %.2f, gpu %.2f)" % [view, c.x, c.y, c.z])
		return
	var parts: Array[Node] = []
	for c in _main.get_children():
		if c != self:
			parts.append(c)
	for c in _main.world.get_children():
		parts.append(c)
	for view in 2:
		if view == 1:
			_main.dwarf._yaw += PI * 0.6
			await _wait(3.0)
		var base := await _frame_cost()
		print("PERF view %d: frame %.2f ms (cpu %.2f, gpu %.2f), %d draw calls, %dk triangles, %d nodes" % [view, base.x, base.y, base.z,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
		for c in parts:
			var n3 := c as Node3D
			var cv := c as CanvasLayer
			var was_vis := n3.visible if n3 else (cv.visible if cv else true)
			var was_mode := c.process_mode
			if n3:
				n3.visible = false
			elif cv:
				cv.visible = false
			c.process_mode = Node.PROCESS_MODE_DISABLED
			var off := await _frame_cost()
			if n3:
				n3.visible = was_vis
			elif cv:
				cv.visible = was_vis
			c.process_mode = was_mode
			var on := await _frame_cost()
			var saves := (base + on) * 0.5 - off
			if saves.x > 0.25 or saves.z > 0.25:
				print("PERF   %s: frame -%.2f ms (gpu -%.2f)" % [c.name, saves.x, saves.z])


func _frame_cost() -> Vector3:
	await _wait(0.3)
	var vp := get_viewport().get_viewport_rid()
	var n := 60
	var t := 0.0
	var cpu := 0.0
	var gpu := 0.0
	for k in n:
		var u := Time.get_ticks_usec()
		await get_tree().process_frame
		t += (Time.get_ticks_usec() - u) / 1000.0
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	return Vector3(t / n, cpu / n, gpu / n)


## Vines (owner, Nov 18: "if you break some, the others close by change their position"): a picture of the nearest
## curtain, break one strand, the same picture again.
func _vinetest() -> void:
	var rc: RootCurtains = _main.get_node_or_null("RootCurtains")
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	_main.hud.visible = false
	while not rc._built:
		await _wait(0.5)
	var best := -1
	var bd := INF
	for id in rc._where:
		var t := rc.top_of(id)
		if t != Vector3.INF and t.distance_to(dwarf.global_position) < bd:
			bd = t.distance_to(dwarf.global_position)
			best = id
	var top := rc.top_of(best)
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.current = true
	var light := OmniLight3D.new()
	light.omni_range = 10.0
	light.light_energy = 2.0
	_main.add_child(light)
	cam.global_position = top + Vector3(2.5, -1.2, 0.0)
	cam.look_at(top + Vector3.DOWN * 1.2)
	light.global_position = cam.global_position
	dwarf.global_position = top + Vector3(30, 0, 30)  # (the dwarf away, so it doesn't push them)
	await _wait(1.5)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("vine_before.png"))
	rc.hide_strands(PackedInt32Array([best]))
	await _wait(0.6)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("vine_after.png"))
	print("VINE broke strand ", best, " at ", top)
