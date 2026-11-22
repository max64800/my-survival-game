extends TestCase
## F780 / F781 (owner, Nov 22, night): spiral stairs snap on top of each other into a tall stair tower, and the
## dwarf climbs them smoothly (no hops or drops).

const Walking := preload("res://tests/test_walking.gd")

var _root: Node3D


## A dwarf-like walker (same body, floor settings and step-up as Dwarf), counting its step-ups, the frames
## it loses the floor, and its height each frame.
class Probe extends CharacterBody3D:
	var goal := Vector3.ZERO
	var done := false
	var speed := 3.0
	var step_ups := 0
	var wall_frames := 0
	var floor_off := 0
	var frames := 0
	var ys := PackedFloat32Array()  ## the height you see: the body plus the step-up glide (= Dwarf._step_dy)
	var dy := 0.0

	func _init() -> void:
		collision_layer = 0
		collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER  # (= Dwarf: a spiral stair's rails and post are on the piece layer only)
		floor_max_angle = deg_to_rad(52)
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
			return
		var dir := to.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		move_and_slide()
		frames += 1
		if is_on_floor() and is_on_wall() and velocity.y <= 0.01 and get_wall_normal().dot(dir) < -0.3:  # (= Dwarf)
			var y0 := global_position.y
			_step_up(dir * speed * delta)
			if global_position.y - y0 > 0.02:
				step_ups += 1
			dy = clampf(dy - (global_position.y - y0), -0.5, 0.0)
		if is_on_wall():
			wall_frames += 1
		if not is_on_floor() and frames > 8:
			floor_off += 1
		dy = move_toward(dy, 0.0, delta * 1.5)
		ys.append(global_position.y + dy)

	## Same as Dwarf._try_step_up.
	func _step_up(motion: Vector3) -> void:
		motion = motion.normalized() * maxf(motion.length(), 0.12)
		var up := Vector3.UP * 0.5
		if test_move(global_transform, up):
			return
		var raised := global_transform.translated(up)
		if test_move(raised, motion):
			return
		var ahead := raised.translated(motion)
		var hit := KinematicCollision3D.new()
		if not test_move(ahead, -up, hit) or hit.get_normal().angle_to(Vector3.UP) > floor_max_angle:
			return
		global_position = ahead.origin + hit.get_travel()


func _ground() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	var ground := StaticBody3D.new()
	ground.collision_layer = World.TERRAIN_LAYER
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(200, 1, 200)
	gs.shape = gb
	gs.position = Vector3(0, -0.5, 0)
	ground.add_child(gs)
	_root.add_child(ground)


func _piece(id: String, fam: String, pos: Vector3, turn := 0) -> PieceNode:
	var n: PieceNode = preload("res://src/build/piece_node.gd").new()
	n.piece = id
	n.family = fam
	_root.add_child(n)
	n.global_position = pos
	n.rotation.y = Pieces.yaw_of(turn)
	return n


## Round the post at radius r, from angle a0 to a1 (degrees, 0 = +x, 90 = −z), seen from o.
func _round(o: Vector3, r: float, a0: float, a1: float, turn_deg := 0.0) -> Array:
	var pts := []
	for a in range(int(a0), int(a1) + 1, 10):
		var t := deg_to_rad(a + turn_deg)
		pts.append(o + Vector3(cos(t), 0, -sin(t)) * r)
	return pts


func _walk_one(path: Array, speed := 3.0) -> Probe:
	var w := Probe.new()
	w.speed = speed
	_root.add_child(w)
	w.global_position = path[0] + Vector3.UP * 0.05
	var left := path.slice(1)
	w.goal = left.pop_front()
	for f in 1200:
		await tree.physics_frame
		if w.done:
			if left.is_empty():
				break
			w.goal = left.pop_front()
			w.done = false
	return w


## The worst hop (up) and drop (down) between frames while climbing, after the start.
static func _bumps(ys: PackedFloat32Array) -> Vector2:
	var hop := 0.0
	var drop := 0.0
	for i in range(1, ys.size()):
		var d := ys[i] - ys[i - 1]
		hop = maxf(hop, d)
		drop = maxf(drop, -d)
	return Vector2(hop, drop)


## F781: the dwarf's height only goes up while he climbs (one smooth ramp, no hops or drops), at walking and
## running speed, near the post, in the middle and by the rail.
func test_climbing_is_smooth() -> void:
	for r in [0.8, 1.05, 1.45]:
		for sp in [3.0, 5.2]:
			_ground()
			_piece("stairs_spiral", "plank_root", Vector3.ZERO)
			var w := await _walk_one([Vector3(1.0, 0, 0.9)] + _round(Vector3.ZERO, r, 10, 300), sp)
			var b := _bumps(w.ys.slice(10))
			var tag := "r %.2f at %.1f m/s" % [r, sp]
			check(w.done and w.global_position.y > 1.9, "%s: up on the landing (y %.2f)" % [tag, w.global_position.y])
			check(b.y < 0.03, "%s: never drops (%.3f m)" % [tag, b.y])
			check(b.x < 0.03 + sp / 60.0 * 0.45, "%s: no hops (%.3f m)" % [tag, b.x])
			check_eq(w.floor_off, 0, "%s: feet always on the stairs" % tag)
			_root.free()


## F781: the camera doesn't jump in and out while the real dwarf climbs (the rails and post no longer catch it).
func test_camera_stays_calm_on_the_climb() -> void:
	Controls.setup()
	for r in [0.8, 1.1, 1.45]:
		_ground()
		_piece("stairs_spiral", "plank_root", Vector3.ZERO)
		var dwarf := Dwarf.new()
		_root.add_child(dwarf)
		dwarf.global_position = Vector3(1.0, 0.05, 1.2)
		for i in 20:
			await tree.physics_frame
		var log := []
		await _drive(dwarf, _round(Vector3.ZERO, r, 10, 260), log)
		var jumps := 0
		var drop := 0.0
		for i in range(1, log.size()):
			jumps += int(absf(log[i][2] - log[i - 1][2]) > 0.15)
			drop = maxf(drop, log[i - 1][0] - log[i][0])
		check(dwarf.global_position.y > 1.6, "r %.2f: the dwarf climbed (y %.2f)" % [r, dwarf.global_position.y])
		check(drop < 0.03, "r %.2f: never dropped (%.3f m)" % [r, drop])
		check(jumps <= 1, "r %.2f: the camera stayed put (%d jumps)" % [r, jumps])
		_root.free()


## Drives the real Dwarf (its camera and animation too) along a path by steering its view. Logs each frame.
func _drive(dwarf: Dwarf, path: Array, log: Array) -> void:
	var left := path.duplicate()
	var goal: Vector3 = left.pop_front()
	dwarf.bot_move = Vector2(0, -1)
	for f in 900:
		var to: Vector3 = goal - dwarf.global_position
		to.y = 0.0
		if to.length() < 0.3:
			if left.is_empty():
				break
			goal = left.pop_front()
			continue
		dwarf._yaw = atan2(-to.x, -to.z)
		await tree.physics_frame
		log.append([dwarf.global_position.y, dwarf.is_on_floor(), dwarf._cam_len])
	dwarf.bot_move = Vector2.ZERO


## F780: snapping, without a world. On top of a spiral (aiming at its landing or the top of its side): the next
## flight 2 m up, turned the same way. Beside a floor: flush, landing level with the floor, landing quarter next to it.
func test_spiral_snaps_onto_a_spiral_and_beside_a_floor() -> void:
	for rot in [0, 1, 2, 3]:
		var a := {piece = "stairs_spiral", pos = Vector3(4, 1, -6), rot = rot}
		var box := Pieces.box(a.piece, a.pos, a.rot)
		var s := Pieces.snap("stairs_spiral", Vector3(5, 3, -5), Vector3.UP, 0.7, 0, 0.0, box, a)
		check_eq(s.pos, Vector3(4, 3, -6), "turn %d: on the landing -> 2 m up" % rot)
		check_eq(s.rot, rot, "turn %d: same turn (the steps carry on round)" % rot)
		s = Pieces.snap("stairs_spiral", Vector3(6, 2.6, -6.5), Vector3.RIGHT, 0.7, 1, 0.0, box, a)
		check_eq(s.pos, Vector3(4, 3, -6), "turn %d: the top of its side -> 2 m up too" % rot)
	var f := {piece = "floor", pos = Vector3(1, 4, 1), rot = 0}
	var fbox := Pieces.box(f.piece, f.pos, f.rot)
	for n in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		for q in [0, 1]:
			var hit: Vector3 = f.pos + Vector3(n.x, 0.1, n.z) + Vector3(0.3 * n.z, 0, 0.3 * n.x)
			var s := Pieces.snap("stairs_spiral", hit, n, 0.0, q, 0.0, fbox, f)
			var sb := Pieces.box("stairs_spiral", s.pos, s.rot)
			check(is_equal_approx(sb.end.y, fbox.end.y), "%s: landing level with the floor" % n)
			var axis := 0 if absf(n.x) > 0.5 else 2
			var touch: float = sb.position[axis] if n[axis] > 0 else sb.end[axis]
			var face: float = fbox.end[axis] if n[axis] > 0 else fbox.position[axis]
			check(is_equal_approx(touch, face), "%s: flush against the floor" % n)
			var land := Basis(Vector3.UP, Pieces.yaw_of(s.rot)) * Vector3(1, 0, 1)
			check(land[axis] * n[axis] < 0.0, "%s: the landing quarter is next to the floor (turn %d)" % [n, s.rot])
			check(is_zero_approx(fposmod(sb.position[2 - axis] - fbox.position[2 - axis] + 0.001, 1.0) - 0.001), "%s: on the floor's grid" % n)
	var fd := {piece = "foundation", pos = Vector3(1, 0, 1), rot = 0}
	var s := Pieces.snap("stairs_spiral", Vector3(2, 0.5, 1), Vector3.RIGHT, 0.0, 0, 0.0, Pieces.box(fd.piece, fd.pos, fd.rot), fd)
	check(is_zero_approx(s.pos.y), "beside a foundation: on the same ground")


## F780 through the referee in the real cave: build a tower of spiral stairs with the build hammer's own snap
## (standing on the landing below doesn't count as "in the way"), the lower flights drop their landing rail, and a
## dwarf-like walker climbs from the bottom to the top.
func test_spiral_tower_builds_and_climbs() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	var player := Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	var viewer := VoxelViewer.new()
	viewer.view_distance = 64
	viewer.requires_visuals = false
	player.add_child(viewer)
	var ps := auth.add_player(1, player)
	ps.vitals.god = true
	for i in 600:
		if world.is_ready_at(player.global_position, 8.0):
			break
		await tree.process_frame
	var b: Builder = auth.builder
	# a spot with room for three flights (6 m) clear of rock (two if the cave is too low)
	var spot := {}
	var flights := 3
	for want in [3, 2]:
		for dx in [3.0, 4.0, 5.0, 6.0]:
			for off in [Vector2(dx, 0), Vector2(-dx, 0), Vector2(0, dx), Vector2(0, -dx), Vector2(dx, dx), Vector2(-dx, -dx), Vector2(dx, -dx), Vector2(-dx, dx)]:
				var p := world.maker.find_floor(player.global_position.x + off.x, player.global_position.z + off.y, player.global_position.y + 2.0)
				var s := Pieces.snap("stairs_spiral", p, Vector3.UP, 0.0, 0)
				var clear := true
				for k in want:
					clear = clear and Pieces.rock_problem("stairs_spiral", s.pos + Vector3.UP * 2.0 * k, s.rot, world.sdf_at) == ""
				if clear:
					spot = s
					break
			if not spot.is_empty():
				break
		if not spot.is_empty():
			flights = want
			break
	check(not spot.is_empty(), "found room for a spiral stair tower")
	if spot.is_empty():
		root.queue_free()
		return
	var o: Vector3 = spot.pos
	player.global_position = o + Vector3(-3, 0, 3)
	check_eq(b.request_place(1, "stairs_spiral", "plank_root", o, spot.rot), "", "first flight")
	var uids := [b._spiral_at(o)]
	for k in range(1, flights):
		var below: Dictionary = b.structure.pieces[uids[-1]]
		var bpos: Vector3 = below.pos
		player.global_position = bpos + Vector3(1.2, 2.0, 1.2)  # standing on the landing below, aiming at it
		var s := Pieces.snap("stairs_spiral", bpos + Vector3(1.0, 2.0, 0.8), Vector3.UP, 0.0, 0, 0.0, Pieces.box("stairs_spiral", bpos, below.rot), below)
		check_eq(b.request_place(1, "stairs_spiral", "plank_root", s.pos, s.rot), "", "flight %d snaps on top" % (k + 1))
		uids.append(b._spiral_at(s.pos))
	for k in uids.size():
		check(uids[k] >= 0, "flight %d is built" % (k + 1))
		check_eq((b.nodes[uids[k]] as PieceNode).capped, k < uids.size() - 1, "flight %d: landing rail only on the top one" % (k + 1))
	# climb: round and round, from the way in up to the top landing
	player.global_position = o + Vector3(-6, 0, 6)
	for i in 120:  # the cave's rock collision near the stairs
		await tree.physics_frame
	_root = root
	var path := _round(o + Vector3.UP * 0.1, 1.1, 0, 360 * (flights - 1) + 300)  # (from the first step: the rock by it is rough)
	var w := await _walk_one(path, 3.0)
	var bumps := _bumps(w.ys.slice(20))
	check(w.global_position.y > o.y + 2.0 * flights - 0.15, "the walker reached the top landing (%.2f of %.2f m)" % [w.global_position.y - o.y, 2.0 * flights])
	check(bumps.y < 0.03, "no drops on the way up (%.3f m)" % bumps.y)
	check(bumps.x < 0.06, "no hops on the way up (%.3f m)" % bumps.x)
	# taking the top one down puts the rail back on the one below
	player.global_position = o + Vector3(-3, 2.0 * flights - 2.0, 3)
	b._clock += Builder.PICKUP_TIME + 1.0
	check_eq(b.request_remove(1, uids[-1], true), "", "top flight taken down")
	check(not (b.nodes[uids[-2]] as PieceNode).capped, "the flight below gets its landing rail back")
	root.queue_free()
