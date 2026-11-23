extends TestCase
## F806 (owner, Nov 23, BIG PRIORITY): "walking toward a door the camera jumps in drastically; standing still near a
## door it zooms in, out, in, out". Standing in a round doorway, the camera must settle and stay put.


func _floor() -> Node3D:
	var root := Node3D.new()
	tree.root.add_child(root)
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, -0.5, 0)
	root.add_child(body)
	return root


func _doorway(root: Node3D, pos: Vector3) -> PieceNode:
	var n := PieceNode.new()
	n.piece = "doorway"
	n.family = "cut_stone"
	n.position = pos
	root.add_child(n)
	return n


## Stands the dwarf `dz` m in front of a doorway (the camera looks back through it) and watches the camera.
func _watch(dz: float) -> Dictionary:
	Controls.setup()
	var root := _floor()
	_doorway(root, Vector3(0, 0, 0))
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, -dz)
	dwarf._yaw = 0.0
	dwarf._pitch = 0.0
	for i in 90:
		await tree.physics_frame
	var lo := 99.0
	var hi := 0.0
	for i in 120:
		await tree.process_frame
		lo = minf(lo, dwarf._cam_len)
		hi = maxf(hi, dwarf._cam_len)
	root.free()
	return {lo = lo, hi = hi}


func test_the_camera_stays_put_in_a_doorway() -> void:
	for dz in [0.0, 0.3, 0.8]:
		var r: Dictionary = await _watch(dz)
		check(r.hi - r.lo < 0.05, "%.1f m in front of the doorway the camera stays put (it went %.2f to %.2f m)" % [dz, r.lo, r.hi])
		check(r.lo > 1.0, "%.1f m in front of the doorway the camera isn't jammed into his head (%.2f m back)" % [dz, r.lo])


func test_walking_through_a_doorway_doesnt_jam_the_camera() -> void:
	Controls.setup()
	var root := _floor()
	_doorway(root, Vector3(0, 0, 0))
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 3.0)   # behind the doorway, walking away from the camera through it
	dwarf._yaw = 0.0
	dwarf._pitch = 0.0
	for i in 60:
		await tree.physics_frame
	var lo := 99.0
	var jumps := 0
	var last := dwarf._cam_len
	for i in 200:   # 1.5 m/s, from 3 m behind it to 2 m past it
		dwarf.global_position = Vector3(0, 0.05, 3.0 - i * 0.025)
		await tree.physics_frame
		await tree.process_frame
		if dwarf.global_position.z < 2.0:  # (once the camera's line back reaches the doorway)
			lo = minf(lo, dwarf._cam_len)
			if last - dwarf._cam_len > 0.4:
				jumps += 1
		last = dwarf._cam_len
	root.free()
	check(lo > 1.0, "walking through, the camera never jams into his head (closest %.2f m)" % lo)
	check(jumps == 0, "and it never jumps in (%d jumps)" % jumps)
