extends TestCase
## Can a dwarf walk on what you build? (owner's test list, Nov 15)
## A "walker" with the dwarf's exact body (capsule 0.36 × 1.35, 52° slopes, 0.5 m step-up) walks
## across floors, up stairs, ramps and roofs, over triangle seams and through the round doorway.
## Every walk must reach its goal at the right height without getting stuck.


class Walker extends CharacterBody3D:
	var goal := Vector3.ZERO
	var done := false
	var stuck_time := 0.0
	var max_y := -INF
	var gravity := 9.8

	func _init() -> void:
		collision_layer = 0
		collision_mask = World.TERRAIN_LAYER
		floor_max_angle = deg_to_rad(52)  # = Dwarf
		floor_snap_length = 0.45
		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.36
		cap.height = 1.35
		shape.shape = cap
		shape.position = Vector3.UP * 0.675
		add_child(shape)

	func _physics_process(delta: float) -> void:
		if done:
			return
		var to := goal - global_position
		to.y = 0.0
		if to.length() < 0.25:
			done = true
			velocity = Vector3.ZERO
			return
		var dir := to.normalized()
		velocity.x = dir.x * 4.0  # Dwarf.WALK_SPEED
		velocity.z = dir.z * 4.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		var before := global_position
		move_and_slide()
		if is_on_floor() and is_on_wall():
			_try_step_up(dir * 4.0 * delta)
		max_y = maxf(max_y, global_position.y)
		stuck_time = stuck_time + delta if global_position.distance_to(before) < 0.01 else 0.0

	## Same as Dwarf._try_step_up.
	func _try_step_up(motion: Vector3) -> void:
		motion = motion.normalized() * maxf(motion.length(), 0.12)
		var start := global_transform
		var up := Vector3.UP * 0.5
		if test_move(start, up):
			return
		var raised := start.translated(up)
		if test_move(raised, motion):
			return
		var ahead := raised.translated(motion)
		var hit := KinematicCollision3D.new()
		if not test_move(ahead, -up, hit):
			return
		if hit.get_normal().angle_to(Vector3.UP) > floor_max_angle:
			return
		global_position = ahead.origin + hit.get_travel()


var _root: Node3D


func _piece(id: String, fam: String, pos: Vector3, rot: int) -> void:
	var n: PieceNode = preload("res://src/build/piece_node.gd").new()
	n.piece = id
	n.family = fam
	_root.add_child(n)
	n.global_position = pos
	n.rotation.y = Pieces.yaw_of(rot)


func test_dwarf_walks_on_buildings() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	# Flat open ground.
	var ground := StaticBody3D.new()
	ground.collision_layer = World.TERRAIN_LAYER
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(200, 1, 200)
	gs.shape = gb
	gs.position = Vector3(0, -0.5, 0)
	ground.add_child(gs)
	_root.add_child(ground)
	var walks := {}  # name -> [walker, expected end height]
	# 1. A row of three wooden floors (step up 0.25 m, walk over the seams).
	var o := Vector3(0, 0, 0)
	for i in 3:
		_piece("floor", "plank_root", o + Vector3(0, 0, -2.0 * i), 0)
	walks["floors"] = [o + Vector3(0, 0, 2.0), o + Vector3(0, 0, -4.5), 0.25]
	# 2. Stairs up onto a 2 m platform (two foundations stacked).
	o = Vector3(10, 0, 0)
	_piece("stairs", "cut_stone", o, 0)
	for y in [0.0, 1.0]:
		_piece("foundation", "cut_stone", o + Vector3(0, y, -2.0), 0)
	walks["stairs"] = [o + Vector3(0, 0, 2.5), o + Vector3(0, 0, -2.3), 2.0]
	# 3. Ramp up onto a 1 m foundation.
	o = Vector3(20, 0, 0)
	_piece("ramp", "cut_stone", o, 0)
	_piece("foundation", "cut_stone", o + Vector3(0, 0, -2.0), 0)
	walks["ramp"] = [o + Vector3(0, 0, 2.5), o + Vector3(0, 0, -2.3), 1.0]
	# 4. Up a gentle roof and 5. a steep roof (from the low edge to the top).
	o = Vector3(30, 0, 0)
	_piece("roof_26", "plank_root", o, 0)
	walks["gentle roof"] = [o + Vector3(0, 0, 2.5), o + Vector3(0, 0, -0.7), 0.85]
	o = Vector3(40, 0, 0)
	_piece("roof_45", "plank_root", o, 0)
	walks["steep roof"] = [o + Vector3(0, 0, 2.5), o + Vector3(0, 0, -0.7), 1.75]
	# 6. Over the seams of a triangle floor and a square floor (and back off the far side).
	o = Vector3(50, 0, 0)
	_piece("floor", "cut_stone", o, 0)
	var e: Dictionary = Pieces.edges("floor", o, 0)[0]
	for cand in Pieces.edges("floor", o, 0):
		if (cand.normal as Vector3).z < -0.5:
			e = cand
	var t := Pieces.snap("floor_triangle", e.mid + e.normal * 0.01 + Vector3.UP * 0.1, e.normal, 0.0, 0, 0.0,
		Pieces.box("floor", o, 0), {piece = "floor", pos = o, rot = 0})
	_piece("floor_triangle", "cut_stone", t.pos, t.rot)
	walks["triangle seam"] = [o + Vector3(0, 0, 2.5), o + Vector3(0, 0, -1.6), 0.25]
	# 7. Through the round doorway, standing on the ground.
	o = Vector3(60, 0, 0)
	_piece("doorway", "cut_stone", o, 0)
	walks["round doorway"] = [o + Vector3(0, 0, 2.0), o + Vector3(0, 0, -2.0), 0.0]
	# 8. Through the stone arched doorway.
	o = Vector3(70, 0, 0)
	_piece("arch_doorway", "cut_stone", o, 0)
	walks["arched doorway"] = [o + Vector3(0, 0, 2.0), o + Vector3(0, 0, -2.0), 0.0]
	# 9. Up onto a flat roof slab and along a triangle foundation's top (1 m: needs the stairs).
	o = Vector3(80, 0, 0)
	_piece("foundation_steps", "cut_stone", o, 0)
	_piece("foundation", "cut_stone", o + Vector3(0, 0, -2.0), 0)
	walks["foundation steps"] = [o + Vector3(0, 0, 2.5), o + Vector3(0, 0, -2.3), 1.0]
	# Control: a plain wall in the way must stop the walker (proves this test can catch "stuck").
	o = Vector3(90, 0, 0)
	_piece("wall", "cut_stone", o, 0)
	_piece("wall", "cut_stone", o + Vector3(2, 0, 0), 0)
	_piece("wall", "cut_stone", o + Vector3(-2, 0, 0), 0)
	var walkers := {}
	var blocked := Walker.new()
	_root.add_child(blocked)
	blocked.global_position = o + Vector3(0, 0.05, 2.0)
	blocked.goal = o + Vector3(0, 0, -2.0)
	for w_name in walks:
		var w := Walker.new()
		_root.add_child(w)
		w.global_position = walks[w_name][0] + Vector3.UP * 0.05
		w.goal = walks[w_name][1]
		walkers[w_name] = w
	for f in 600:  # up to 10 s of walking
		await tree.physics_frame
		var all_done := true
		for w_name in walkers:
			all_done = all_done and walkers[w_name].done
		if all_done:
			break
	check(not blocked.done and blocked.global_position.z > o.z, "control: a wall stops the walker")
	for w_name in walks:
		var w: Walker = walkers[w_name]
		var want: float = walks[w_name][2]
		check(w.done, "%s: reached the end (stopped at %s, stuck %.1f s)" % [w_name, w.global_position, w.stuck_time])
		check_near(w.global_position.y, want, 0.2, "%s: standing at the right height" % w_name)
	_root.queue_free()
