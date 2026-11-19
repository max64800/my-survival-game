extends SceneTree
## Finds what eats the physics time (Claude, Nov 19: the owner had 5 FPS with "physics 25 ms").
## Starts a world (saving OFF, so a real save is never touched), stands at the start, then switches off each kind of
## node that runs every physics step, one kind at a time, and prints how much physics time that saved.
##   godot --audio-driver Dummy --path . --script res://tools/perf_probe.gd -- seed=594196
var main: Node
var _t := 0.0


func _init() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate()
	main.set("_saving", false)
	root.add_child.call_deferred(main)
	_run.call_deferred()


## The typical (median) physics time per step over `seconds` (a median ignores one-off spikes).
func _avg_physics(seconds: float) -> float:
	var vals := []
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await physics_frame
		vals.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	vals.sort()
	return vals[vals.size() / 2] if vals.size() > 0 else 0.0


func _kind(n: Node) -> String:
	var s: Script = n.get_script()
	return s.resource_path.get_file() if s else n.get_class()


func _run() -> void:
	var waited := 0
	while not main.call("is_ready_to_play") and waited < 240 * 60:
		await process_frame
		waited += 1
	print("PROBE ready after %d frames" % waited)
	for i in 600:
		await process_frame  # let things settle (10 s)
	var base := await _avg_physics(4.0)
	var groups := {}
	var bodies := {}
	for n in _all(root):
		if n.is_physics_processing():
			groups.get_or_add(_kind(n), []).append(n)
		if n is RigidBody3D and not (n as RigidBody3D).sleeping and not (n as RigidBody3D).freeze:
			var k := "%s (under %s)" % [_kind(n), _kind(n.get_parent())]
			bodies[k] = bodies.get(k, 0) + 1
	print("PROBE physics %.2f ms per step, %d moving physics bodies" % [base, Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)])
	print("PROBE awake rigid bodies: ", bodies)
	await _monster_breakdown()
	# Exact: switch every node's own physics step off and run it by hand, timing each kind; whatever is left in the
	# physics time is the engine itself (bodies, collisions).
	var nodes := []
	for k in groups:
		for n in groups[k]:
			if n.has_method("_physics_process"):
				n.set_physics_process(false)
				nodes.append(n)
	var spent := {}
	var worst := {}
	var frames := []
	var end := Time.get_ticks_msec() + 15000
	var steps := 0
	while Time.get_ticks_msec() < end:
		await physics_frame
		steps += 1
		var frame := {}
		for n in nodes:
			if not is_instance_valid(n):
				continue
			var t := Time.get_ticks_usec()
			n._physics_process(1.0 / 60.0)
			var us := Time.get_ticks_usec() - t
			var k := _kind(n)
			frame[k] = frame.get(k, 0) + us
		var total := 0
		for k in frame:
			spent[k] = spent.get(k, 0) + frame[k]
			worst[k] = maxi(worst.get(k, 0), frame[k])
			total += frame[k]
		frames.append([total, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
	for n in nodes:
		if is_instance_valid(n):
			n.set_physics_process(true)
	var keys := spent.keys()
	keys.sort_custom(func(a, b): return spent[a] > spent[b])
	for k in keys.slice(0, 12):
		print("PROBE  %-30s average %.2f ms, worst step %.2f ms" % [k, spent[k] / 1000.0 / steps, worst[k] / 1000.0])
	frames.sort_custom(func(a, b): return a[1] > b[1])
	print("PROBE  worst physics steps (scripts ms / whole physics ms): ", frames.slice(0, 8).map(func(f): return "%.1f/%.1f" % [f[0] / 1000.0, f[1]]))
	var med = frames[frames.size() / 2]
	print("PROBE  typical step: scripts %.1f ms of %.1f ms" % [med[0] / 1000.0, med[1]])
	print("PROBE_END")
	quit()


## Runs the creatures' step by hand for a few seconds, timing each part and each kind's thinking.
func _monster_breakdown() -> void:
	var mm: Node = GameAuthority.instance.monsters
	mm.set_physics_process(false)
	var parts := {}
	var counts := {}
	var steps := 0
	var end := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < end:
		await physics_frame
		var d := get_root().get_physics_process_delta_time() if false else 1.0 / 60.0
		steps += 1
		var t := Time.get_ticks_usec()
		mm._update_boosts()
		parts["boosts"] = parts.get("boosts", 0) + Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		mm._statues_step(d)
		mm._check_boss_resets(d)
		parts["statues+bosses"] = parts.get("statues+bosses", 0) + Time.get_ticks_usec() - t
		for m in mm.monsters.values():
			if m.is_alive():
				t = Time.get_ticks_usec()
				m.think(d, mm)
				var k: String = "think " + m.kind
				parts[k] = parts.get(k, 0) + Time.get_ticks_usec() - t
				counts[k] = counts.get(k, 0) + 1
		t = Time.get_ticks_usec()
		mm._spawn_timer -= d
		if mm._spawn_timer <= 0.0:
			mm._spawn_timer = mm.SPAWN_CHECK
			if mm.enabled:
				mm._spawn_and_despawn()
		parts["spawn/despawn"] = parts.get("spawn/despawn", 0) + Time.get_ticks_usec() - t
		t = Time.get_ticks_usec()
		mm._judge_incoming()
		mm._clouds_step(d)
		parts["incoming+clouds"] = parts.get("incoming+clouds", 0) + Time.get_ticks_usec() - t
	for m in mm.monsters.values():
		if m.kind == "rock_snail" and m.is_alive():
			var shapes := 0
			for n in _all(m):
				if n is CollisionShape3D or n is CollisionPolygon3D:
					shapes += 1
			var t0 := Time.get_ticks_usec()
			for i in 20:
				m._move(1.0 / 60.0, Vector3.ZERO, 0.0)
			var t1 := Time.get_ticks_usec()
			for i in 20:
				m._perceive(mm)
			var t2 := Time.get_ticks_usec()
			for i in 20:
				m.think(1.0 / 60.0, mm)
			var t3 := Time.get_ticks_usec()
			var near := {}
			var q := PhysicsShapeQueryParameters3D.new()
			var sph := SphereShape3D.new()
			sph.radius = 3.0
			q.shape = sph
			q.transform = Transform3D(Basis(), m.global_position)
			q.collision_mask = 0xFFFFFFFF
			for h in m.get_world_3d().direct_space_state.intersect_shape(q, 64):
				var co: Object = h.collider
				var key := "%s L%d" % [_kind(co), (co as CollisionObject3D).collision_layer if co is CollisionObject3D else -1]
				var sh := PhysicsServer3D.body_get_shape(h.rid, h.shape) if co is PhysicsBody3D else RID()
				if sh.is_valid():
					var sd = PhysicsServer3D.shape_get_data(sh)
					key += " type%d" % PhysicsServer3D.shape_get_type(sh) + (" faces %d" % (sd.size() / 3) if sd is PackedVector3Array else "")
				near[key] = near.get(key, 0) + 1
			print("PROBE    near snail %d: %s" % [m.uid, near])
			print("PROBE  snail %d state %s on_floor %s shapes %d at %s: move %.2f ms, perceive %.2f ms, think %.2f ms, slides %d, velocity %s, stuck in rock %s, capsule %s" % [m.uid, m.state, m.is_on_floor(), shapes, m.global_position.snapped(Vector3.ONE * 0.1),
				(t1 - t0) / 20000.0, (t2 - t1) / 20000.0, (t3 - t2) / 20000.0, m.get_slide_collision_count(), m.velocity.snapped(Vector3.ONE * 0.1), m.test_move(m.global_transform, Vector3.ZERO), _cap(m)])
	mm.set_physics_process(true)
	var keys := parts.keys()
	keys.sort_custom(func(a, b): return parts[a] > parts[b])
	for k in keys:
		print("PROBE  monsters: %-28s %.2f ms per step%s" % [k, parts[k] / 1000.0 / steps,
			"  (%d of them)" % (counts[k] / steps) if counts.has(k) else ""])


func _cap(m: Node) -> String:
	for n in m.get_children():
		if n is CollisionShape3D and n.shape is CapsuleShape3D:
			return "r %.2f h %.2f" % [n.shape.radius, n.shape.height]
	return "?"


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
