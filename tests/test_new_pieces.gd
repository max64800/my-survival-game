extends TestCase
## The 8 new building pieces (owner, Nov 21; docs/design/new-pieces-plan.md): every kit's model is used,
## a dwarf walks up the corner and spiral stairs, and drops through the floor hatch's hole.

const NEW := ["stairs_corner", "stairs_spiral", "railing_stairs", "sloped_wall_down", "edge_strip", "floor_hatch",
	"lattice_wall", "roof_cap"]
const Walking := preload("res://tests/test_walking.gd")

var _root: Node3D


## A falling body the size of a dwarf (no walking): where does it land?
class Faller extends CharacterBody3D:
	func _init() -> void:
		collision_layer = 0
		collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER  # (= Dwarf: a spiral stair's rails and post are on the piece layer only)
		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.36
		cap.height = 1.35
		shape.shape = cap
		shape.position = Vector3.UP * 0.675
		add_child(shape)

	func _physics_process(delta: float) -> void:
		velocity = Vector3(0, velocity.y - 9.8 * delta, 0)
		move_and_slide()


func test_every_kit_has_its_model() -> void:
	var missing := []
	for id in NEW:
		for fam in Pieces.KIT_FAMILIES:
			if Pieces.allowed(id, fam) and PieceNode.forged_mesh(id, fam) == null:
				missing.append("%s/%s" % [id, fam])
	check(missing.is_empty(), "every new piece uses its hand-made model in all its kits (missing: %s)" % [missing])
	check(not Pieces.allowed("roof_cap", "cut_stone"), "no roof cap for Stonehold (flat roofs only)")
	check(Pieces.allowed("roof_cap", "plank_root") and Pieces.allowed("roof_cap", "clay_brick"), "roof cap for Shack and Hearthbrick")


## Hearth Manor's 5 Hearthbrick pieces (owner OK Nov 22, F479): the game uses their hand-made models.
func test_manor_pieces_use_their_models() -> void:
	for id in ["corbel", "cornice", "cornice_corner", "railing_narrow", "dormer"]:
		check(Pieces.allowed(id, "clay_brick"), "%s is made in Hearthbrick" % id)
		check(PieceNode.forged_mesh(id, "clay_brick") != null, "%s uses its hand-made model" % id)
	for id in ["railing_narrow", "dormer"]:
		check(not Pieces.allowed(id, "cut_stone"), "%s is Hearthbrick only" % id)
	# Cliff Watch (ruin 8, Nov 22): the Twin Gate's stone bracket, trim band and corner are game pieces too.
	for id in ["corbel", "cornice", "cornice_corner"]:
		check(Pieces.allowed(id, "cut_stone"), "%s is made in Stonehold" % id)
		check(PieceNode.forged_mesh(id, "cut_stone") != null, "%s uses its stone model" % id)


func test_down_sloped_wall_is_full_along_the_top() -> void:
	var pts := PieceMesh.solid("sloped_wall_down").get_faces()
	var low_right := INF
	var low_left := INF
	for p in pts:
		if p.x > 0.9:
			low_right = minf(low_right, p.y)
		if p.x < -0.9:
			low_left = minf(low_left, p.y)
	check_near(low_right, 2.0, 0.01, "the right end is only the top edge (open underneath)")
	check_near(low_left, 0.0, 0.01, "the left end reaches the floor")


func test_stair_railing_climbs_with_the_stairs() -> void:
	var top_left := -INF
	var top_right := -INF
	for p in PieceMesh.solid("railing_stairs").get_faces():
		if p.x < -0.9:
			top_left = maxf(top_left, p.y)
		if p.x > 0.9:
			top_right = maxf(top_right, p.y)
	check_near(top_left, 1.0, 0.01, "1 m tall at the low end, like a plain railing")
	check_near(top_right, 3.0, 0.01, "3 m above the floor at the high end (2 m of stairs + 1 m)")


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


func _piece(id: String, fam: String, pos: Vector3) -> void:
	var n: PieceNode = preload("res://src/build/piece_node.gd").new()
	n.piece = id
	n.family = fam
	_root.add_child(n)
	n.global_position = pos


## Walks each path (a list of points), one walker per path, at most 15 s. Returns the walkers.
func _walk(paths: Dictionary) -> Dictionary:
	var walkers := {}
	var left := {}
	for name in paths:
		var w = Walking.Walker.new()
		_root.add_child(w)
		w.global_position = paths[name][0] + Vector3.UP * 0.05
		left[name] = (paths[name] as Array).slice(1)
		w.goal = left[name].pop_front()
		walkers[name] = w
	for f in 900:
		await tree.physics_frame
		var all_done := true
		for name in walkers:
			var w = walkers[name]
			if w.done and not left[name].is_empty():
				w.goal = left[name].pop_front()
				w.done = false
			all_done = all_done and w.done
		if all_done:
			break
	return walkers


func test_dwarf_walks_up_the_turning_stairs() -> void:
	_ground()
	var paths := {}
	for k in 3:
		var fam: String = Pieces.KIT_FAMILIES[k]
		# Corner stairs: in at the front, round the turn, off the back-left onto a 2 m platform behind.
		var o := Vector3(12 * k, 0, 0)
		_piece("stairs_corner", fam, o)
		for y in [0.0, 1.0]:
			_piece("foundation", fam, o + Vector3(0, y, -2))
		paths["corner stairs " + fam] = [o + Vector3(0.4, 0, 2.2), o + Vector3(0.4, 0, 0.6), o + Vector3(0.1, 0, -0.1),
			o + Vector3(-0.5, 0, -0.5), o + Vector3(-0.6, 0, -2.3)]
		# F716 spiral stairs (4×4): start under the landing, go round 3/4 of a turn, onto the landing, then
		# step off to the right onto a 2 m platform.
		o = Vector3(12 * k, 0, 12)
		_piece("stairs_spiral", fam, o)
		for y in [0.0, 1.0]:
			_piece("foundation", fam, o + Vector3(3, y, 1))
		var path := [o + Vector3(1.0, 0, 0.9)]
		for a in range(10, 270, 20):  # round the post at 1.05 m (the dwarf is 0.36 wide each side)
			path.append(o + Vector3(cos(deg_to_rad(a)), 0, -sin(deg_to_rad(a))) * 1.05)
		path.append(o + Vector3(1.0, 0, 1.0))
		path.append(o + Vector3(3.0, 0, 1.0))
		paths["spiral stairs " + fam] = path
		# The same inside a tower (walls all round but the way in and out, F716: the old one was worst there).
		o = Vector3(12 * k, 0, 24)
		_piece("stairs_spiral", fam, o)
		for y in [0.0, 1.0]:
			_piece("foundation", fam, o + Vector3(3, y, 1))
		for e in [[Vector3(-1, 0, -2), 0], [Vector3(1, 0, -2), 0], [Vector3(-1, 0, 2), 0], [Vector3(1, 0, 2), 0],
				[Vector3(-2, 0, -1), 1], [Vector3(-2, 0, 1), 1], [Vector3(2, 0, -1), 1]]:
			_piece("wall", fam, o + e[0])
			_root.get_child(-1).rotation.y = Pieces.yaw_of(e[1])
		var tower := [o + Vector3(1.0, 0, 0.9)]
		for a in range(10, 270, 20):
			tower.append(o + Vector3(cos(deg_to_rad(a)), 0, -sin(deg_to_rad(a))) * 1.05)
		tower.append(o + Vector3(1.0, 0, 1.0))
		tower.append(o + Vector3(3.0, 0, 1.0))
		paths["spiral stairs in a tower " + fam] = tower
	var walkers := await _walk(paths)
	for name in walkers:
		var w = walkers[name]
		check(w.done, "%s: reached the top (stopped at %s, stuck %.1f s)" % [name, w.global_position, w.stuck_time])
		check_near(w.global_position.y, 2.0, 0.2, "%s: standing 2 m up" % name)
	_root.queue_free()


func test_dwarf_drops_through_the_hatch() -> void:
	_ground()
	var fallers := {}
	for k in 3:
		var fam: String = Pieces.KIT_FAMILIES[k]
		var o := Vector3(6 * k, 3, 0)
		_piece("floor_hatch", fam, o)
		for spot in ["hole", "floor"]:
			var f := Faller.new()
			_root.add_child(f)
			f.global_position = o + Vector3(0, 0.5, PieceMesh.HATCH_Z if spot == "hole" else -0.5)
			fallers["%s %s" % [fam, spot]] = f
	for i in 90:
		await tree.physics_frame
	for name: String in fallers:
		var y: float = fallers[name].global_position.y
		if name.ends_with("hole"):
			check(y < 0.3, "%s: a dwarf falls through the hatch's hole (at %.2f m)" % [name, y])
		else:
			check_near(y, 3.25, 0.05, "%s: the floor beside the hole holds a dwarf" % name)
	_root.queue_free()


## F169 / F626 (owner, Nov 22: "I can't climb the spiral stairs in the Hearth Manor"): the Manor's and the Twin
## Gate's towers now climb by straight (and corner) stairs; a dwarf walks up every flight, built as real pieces.
## F783 🔁 (owner, Nov 23: "the stairs in both towers are still blocked"): every flight climbed fine on its own (the
## test below), yet the Twin Gate's deck stairs came up INSIDE the round stage with railings on both long sides, so
## their top only led out of the door and the stage's own stairs were fenced off. This pours "water" from the foot
## of each tower's first flight (ReachMap: the dwarf's own body, 25 cm steps) and checks the foot and top of every
## flight in that tower and both sides of every door are wet.
func test_every_tower_flight_and_door_can_be_reached() -> void:
	_ground()
	var bp := BlueprintLibrary.make("stonehold_twin_gate")
	var towers := {-1: [], 1: []}
	var doors := []
	for p in bp.pieces:
		var n: PieceNode = preload("res://src/build/piece_node.gd").new()
		n.piece = p.id
		n.family = p.mat
		if p.id in Pieces.DOORS and p.id != "gate_leaf":
			doors.append(p)                                             # (left out: a player opens a door away from
			continue                                                    # themselves: the leaf never fences their side)
		_root.add_child(n)
		n.global_position = p.pos
		n.rotation.y = Pieces.yaw_of(p.rot)
		if p.id in ["stairs", "stairs_corner"] and absf(p.pos.x) > 6.0:
			towers[signi(p.pos.x)].append(p)
	var body := CharacterBody3D.new()
	body.collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.35
	shape.shape = cap
	shape.position = Vector3.UP * 0.675
	body.add_child(shape)
	_root.add_child(body)
	body.global_position = Vector3(0, -50, 0)
	await tree.physics_frame
	await tree.physics_frame
	for side in towers:
		var flights: Array = towers[side]
		check(flights.size() >= 5, "tower %d: its five flights (%d)" % [side, flights.size()])
		if flights.is_empty():
			continue
		flights.sort_custom(func(a, c): return a.pos.y < c.pos.y)
		var box := AABB(Vector3(11.0 * side - 7.0, 0, flights[0].pos.z - 9.0), Vector3(14, 0, 18))
		var spots := ReachMap.flood(body, ReachMap.flight_ends(flights[0].id, flights[0].pos, flights[0].rot)[0], box, 60000)
		for p in flights:
			var ends := ReachMap.flight_ends(p.id, p.pos, p.rot)
			check(ReachMap.distance(spots, ends[0]) < 0.6, "tower %d: the foot of the %s at %s can be reached" % [side, p.id, p.pos])
			check(ReachMap.distance(spots, ends[1]) < 0.6, "tower %d: the top of the %s at %s can be reached" % [side, p.id, p.pos])
		for p in doors:
			if p.pos.x > box.position.x and p.pos.x < box.end.x and p.pos.z > box.position.z and p.pos.z < box.end.z and p.pos.y > 4.0:   # (the tower's upper doors)
				var bs := Basis(Vector3.UP, Pieces.yaw_of(p.rot))
				for f in [1.0, -1.0]:
					check(ReachMap.distance(spots, p.pos + bs * Vector3(0, 0, f)) < 0.6, "tower %d: the %s at %s, %s side, can be reached" % [side, p.id, p.pos, "front" if f > 0 else "back"])
	_root.queue_free()
	await tree.physics_frame


func test_dwarf_walks_up_every_tower_flight() -> void:
	for id in ["hearthbrick_manor", "stonehold_twin_gate"]:
		_ground()
		var bp := BlueprintLibrary.make(id)
		var paths := {}
		for p in bp.pieces:
			var n: PieceNode = preload("res://src/build/piece_node.gd").new()
			n.piece = p.id
			n.family = p.mat
			_root.add_child(n)
			n.global_position = p.pos
			n.rotation.y = Pieces.yaw_of(p.rot)
			var b := Basis(Vector3.UP, Pieces.yaw_of(p.rot))
			var local := []
			if p.id == "stairs":
				# (-1.25: a step past the top onto the floor; F783: the Twin Gate deck flights end at a door 0.73 m on)
				local = [Vector3(0, 0, 1.9), Vector3(0, 0, 0.8), Vector3(0, 0, -1.25)]
			elif p.id == "stairs_corner":
				local = [Vector3(0.4, 0, 2.2), Vector3(0.4, 0, 0.6), Vector3(0.1, 0, -0.1), Vector3(-0.5, 0, -0.5), Vector3(-0.6, 0, -1.8)]
			if local.is_empty():
				continue
			var path := []
			for q: Vector3 in local:
				path.append(p.pos + b * q + Vector3.UP * 0.3)
			paths["%s %s at %s" % [id, p.id, p.pos]] = [path, p.pos.y + 2.0]
		check(paths.size() >= 3, "%s: at least three flights (%d)" % [id, paths.size()])
		await tree.physics_frame
		var only := {}
		for k in paths:
			only[k] = paths[k][0]
		var walkers := await _walk(only)
		for name in walkers:
			var w = walkers[name]
			check(w.done, "%s: reached the top (stopped at %s, stuck %.1f s)" % [name, w.global_position, w.stuck_time])
			check_near(w.global_position.y, paths[name][1], 0.3, "%s: standing on the floor above" % name)
		_root.queue_free()
		await tree.physics_frame
