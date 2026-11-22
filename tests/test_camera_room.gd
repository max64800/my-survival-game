extends TestCase
## F783 (owner, Nov 23: "the camera jitters" on the Twin Gate's wall walks): a railing or battlement passing behind
## the dwarf no longer pushes the camera in (it slips past thin pieces); a wall still does (you'd see inside it).


func _piece(id: String, pos: Vector3, rot: int) -> PieceNode:
	var n := PieceNode.new()
	n.piece = id
	n.family = "cut_stone"
	n.position = pos
	n.rotation.y = Pieces.yaw_of(rot)
	tree.root.add_child(n)
	return n


func _spring_at(pos: Vector3) -> SpringArm3D:
	var s := SpringArm3D.new()
	s.spring_length = 4.0
	s.collision_mask = World.TERRAIN_LAYER
	var sh := SphereShape3D.new()
	sh.radius = 0.25
	s.shape = sh
	s.margin = 0.25
	s.position = pos      # (it reaches back along +z, like the dwarf's)
	tree.root.add_child(s)
	return s


func test_thin_pieces_dont_push_the_camera_in() -> void:
	var far := Vector3(500, 200, 500)   # (up in the air, away from anything else in the test world)
	var spring := _spring_at(far + Vector3(0, 0.6, 0))
	var rail := _piece("railing", far + Vector3(0, 0, 2), 0)
	for i in 4:
		await tree.physics_frame
	check(spring.get_hit_length() < 3.0, "the spring arm alone bumps the railing (%.2f m)" % spring.get_hit_length())
	check_near(CameraRoom.room(spring), 4.0, 0.01, "but the camera goes all the way back past it")
	rail.free()
	var wall := _piece("wall", far + Vector3(0, 0, 2), 0)
	for i in 4:
		await tree.physics_frame
	var r := CameraRoom.room(spring)
	check(r < 2.0, "a wall still stops the camera (%.2f m)" % r)
	wall.free()
	spring.free()
