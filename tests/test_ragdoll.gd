extends TestCase
## Big hits (F237): the dwarf goes floppy, tumbles the way he was pushed, stays on the floor, then gets back up.


func _room() -> Node3D:
	var root := Node3D.new()
	tree.root.add_child(root)
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, -0.5, 0)  # floor, top at y = 0
	root.add_child(body)
	return root


func test_big_hit_tumbles_and_gets_up() -> void:
	Controls.setup()
	var root := _room()
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	for i in 30:
		await tree.physics_frame
	var sk := dwarf.model.dwarf_rig.skeleton
	var pelvis := sk.find_bone("pelvis")
	var standing := sk.get_bone_pose_rotation(pelvis)
	dwarf.big_hit(Vector3(8, 0, 0))
	check(dwarf.ragdoll != null and dwarf.ragdoll.down(), "a big hit makes him floppy")
	var lowest := INF
	var turned := 0.0
	for i in 60:
		await tree.physics_frame
		lowest = minf(lowest, dwarf.global_position.y)
		turned = maxf(turned, standing.angle_to(sk.get_bone_pose_rotation(pelvis)))
	check(dwarf.global_position.x > 1.0, "thrown the way he was pushed (x %.2f)" % dwarf.global_position.x)
	check(turned > 0.5, "his body tumbles, not just slides (hips turned %.2f rad)" % turned)
	check(lowest > -1.0, "didn't fall through the floor (lowest %.2f)" % lowest)
	dwarf.bot_move = Vector2(0, -1)
	for i in 30:
		await tree.physics_frame
	check(dwarf.ragdoll.down(), "can't walk away while floppy")
	for i in int((DwarfRagdoll.DOWN_TIME + DwarfRagdoll.BLEND_TIME) * 60) + 10:
		await tree.physics_frame
	check(not dwarf.ragdoll.down(), "gets back up")
	check(absf(dwarf.global_position.y) < 0.3, "back on the floor (y %.2f)" % dwarf.global_position.y)
	var z := dwarf.global_position.z
	for i in 120:
		await tree.physics_frame
	check(dwarf.global_position.z < z - 0.5, "walks again after getting up")
	root.queue_free()
