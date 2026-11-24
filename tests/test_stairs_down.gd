extends TestCase
## F803 (owner, Nov 23: going down the stairs "feels like jumping instead of walking down"): a body like the dwarf's
## walks down each kind of tower flight and must keep its feet on the steps the whole way.

const Walking := preload("res://tests/test_walking.gd")

var _root: Node3D


func _piece(id: String, fam: String, pos: Vector3, rot: int) -> void:
	var n: PieceNode = preload("res://src/build/piece_node.gd").new()
	n.piece = id
	n.family = fam
	_root.add_child(n)
	n.global_position = pos
	n.rotation.y = Pieces.yaw_of(rot)


func test_walking_down_the_stairs_keeps_your_feet_on_them() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	# The Twin Gate's first tower flight: stairs on the floor (top 1.0), the next floor's slab at 3.0 (top 3.25).
	for z in [4, 2]:
		_piece("floor", "cut_stone", Vector3(0, 0.75, z), 0)
	_piece("stairs", "cut_stone", Vector3(0, 1.0, 0), 0)
	(_root.get_child(-1) as PieceNode).set_lip(true)   # (as Builder._relip_stairs does: a slab 25 cm above its top)
	for z in [-2, -4]:
		_piece("floor", "cut_stone", Vector3(0, 3.0, z), 0)
	var worst := await _walk_down([Vector3(0, 3.3, -3.5), Vector3(0, 1.0, 3.5)])
	check(worst >= 0, "he got down the straight stairs")
	check(worst <= 2, "straight stairs: his feet stay on the steps (longest time in the air: %d frames)" % worst)
	_root.free()


func test_walking_down_the_corner_stairs_keeps_your_feet_on_them() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	# Corner stairs: you step on at the foot (+z) and come off its side (-x) at the top.
	for z in [4, 2]:
		_piece("floor", "cut_stone", Vector3(0, 0.75, z), 0)
	_piece("stairs_corner", "cut_stone", Vector3(0, 1.0, 0), 0)
	(_root.get_child(-1) as PieceNode).set_lip(true)   # (the next floor's slab is 25 cm above its top step)
	for x in [-2, -4]:
		_piece("floor", "cut_stone", Vector3(x, 3.0, 0), 0)
	var worst := await _walk_down([Vector3(-3.5, 3.3, 0), Vector3(-0.4, 0, 0), Vector3(0, 0, 0.4), Vector3(0, 1.0, 3.5)])
	check(worst >= 0, "he got down the corner stairs")
	check(worst <= 2, "corner stairs: his feet stay on the steps (longest time in the air: %d frames)" % worst)
	# ...and climbing them still works (F781: the owner liked going up).
	var up := Walking.Walker.new()
	_root.add_child(up)
	up.global_position = Vector3(0, 1.05, 3.5)
	var pop := 0.0     # the biggest height jump in one frame
	var stalls := 0    # frames he hardly moved while still on the way
	var last := up.global_position
	for g in [Vector3(0, 0, 0.4), Vector3(-0.4, 0, 0), Vector3(-3.5, 0, 0)]:
		up.goal = g
		up.done = false
		for i in 200:
			await tree.physics_frame
			if up.done:
				break
			var now := up.global_position
			if now.z < 1.2 and now.x > -1.2:   # (on the stairs)
				pop = maxf(pop, now.y - last.y)
				if now.distance_to(last) < 0.02:
					stalls += 1
			last = now
	check(up.done and up.global_position.y > 3.2, "and he climbs them too (ended at %s)" % up.global_position)
	# F781 🔁 (owner, Nov 23: "still jitter when you walk up"): no step pops and no stops on the way up.
	check(pop < 0.15 and stalls == 0, "climbing is smooth (biggest pop %.2f m, %d stalls)" % [pop, stalls])
	_root.free()


## Walks a dwarf-like body from path[0] through the rest; the longest run of frames off the floor (after first
## landing), or -1 if he didn't get there.
func _walk_down(path: Array) -> int:
	var w := Walking.Walker.new()
	_root.add_child(w)
	w.global_position = path[0]
	var leg := 1
	w.goal = path[leg]
	await tree.physics_frame
	var air := 0
	var worst := 0
	var landed := false
	var log := []
	for i in 300:
		await tree.physics_frame
		if w.done:
			if leg == path.size() - 1:
				break
			leg += 1
			w.goal = path[leg]
			w.done = false
		if w.is_on_floor() or w.stepped_down:
			air = 0
			landed = true
		elif landed:   # (it starts with a little drop onto the floor)
			air += 1
			worst = maxi(worst, air)
		if i % 3 == 0:
			log.append("%.2f,%.2f/%.2f%s" % [w.global_position.x, w.global_position.z, w.global_position.y, "" if w.is_on_floor() or w.stepped_down else "*"])
	print("STAIRS_DOWN ", " ".join(log))
	return worst if w.done else -1


## F839 (owner, Nov 24: a big gap and a stutter between stairs): a stair aimed at another stair snaps flush, straight
## on (where the first ends, same way) or right beside it, and a dwarf walks up and down two flights without a stop.
func test_stairs_snap_flush_on_stairs() -> void:
	var a := {piece = "stairs", pos = Vector3(4, 1, 6), rot = 1}
	var b := Basis(Vector3.UP, Pieces.yaw_of(1))
	var on := Pieces.snap("stairs", Vector3(4, 2, 6), (b * Vector3(0, 1, 1)).normalized(), 0.0, 0, 0.0, AABB(), a)
	check(on.pos.is_equal_approx(Vector3(4, 1, 6) + b * Vector3(0, 2, -2)) and on.rot == 1, "straight on: %s" % [on])
	var side := Pieces.snap("stairs", Vector3(4, 1.5, 6), b * Vector3(1, 0, 0), 0.0, 0, 0.0, AABB(), a)
	check(side.pos.is_equal_approx(Vector3(4, 1, 6) + b * Vector3(2, 0, 0)) and side.rot == 1, "beside: %s" % [side])
	var turned := Pieces.snap("stairs", Vector3(4, 1.5, 6), b * Vector3(-1, 0, 0), 0.0, 2, 0.0, AABB(), a)
	check(turned.pos.is_equal_approx(Vector3(4, 1, 6) + b * Vector3(-2, 0, 0)) and turned.rot == 3, "beside, Q turns it: %s" % [turned])


func test_two_flights_straight_on_walk_smoothly() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	for z in [4, 2]:
		_piece("floor", "cut_stone", Vector3(0, 0.75, z), 0)
	var a := {piece = "stairs", pos = Vector3(0, 1, 0), rot = 0}
	_piece("stairs", "cut_stone", a.pos, 0)
	var t := Pieces.snap("stairs", Vector3(0, 2, 0), Vector3(0, 0.7, 0.7), 0.0, 0, 0.0, AABB(), a)
	_piece("stairs", "cut_stone", t.pos, t.rot)
	for z in [-4, -6]:
		_piece("floor", "cut_stone", Vector3(0, 4.75, z), 0)
	var up := Walking.Walker.new()
	_root.add_child(up)
	up.global_position = Vector3(0, 1.05, 3.5)
	up.goal = Vector3(0, 0, -5.5)
	var pop := 0.0
	var stalls := 0
	var last := up.global_position
	for i in 400:
		await tree.physics_frame
		if up.done:
			break
		var now := up.global_position
		if now.z < 1.2 and now.z > -3.2:
			pop = maxf(pop, now.y - last.y)
			if now.distance_to(last) < 0.02:
				stalls += 1
		last = now
	check(up.done and up.global_position.y > 4.9, "he climbs both flights (ended at %s)" % up.global_position)
	check(pop < 0.15 and stalls == 0, "climbing over the join is smooth (biggest pop %.2f m, %d stalls)" % [pop, stalls])
	var worst := await _walk_down([Vector3(0, 5.1, -5.5), Vector3(0, 1.0, 3.5)])
	check(worst >= 0 and worst <= 2, "and down again with his feet on the steps (longest in the air: %d frames)" % worst)
	_root.free()
