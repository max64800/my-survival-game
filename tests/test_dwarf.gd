extends TestCase
## The dwarf standing in the real cave, with real physics.


func test_dwarf_does_not_fall_through_floor() -> void:
	Controls.setup()
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	var spawn := world.maker.cavern_spawn
	dwarf.global_position = spawn
	dwarf.set_physics_process(false)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	dwarf.add_child(viewer)
	auth.add_player(1, dwarf)
	var meshed := false
	for i in 900:
		if world.terrain.is_area_meshed(AABB(spawn - Vector3.ONE * 6, Vector3.ONE * 12)):
			meshed = true
			break
		await tree.physics_frame
	check(meshed, "floor got built around spawn")
	dwarf.set_physics_process(true)
	for i in 180:  # 3 seconds of falling and standing
		await tree.physics_frame
	check(dwarf.is_on_floor(), "dwarf is standing on the floor")
	check(dwarf.global_position.y > spawn.y - 3.0, "dwarf didn't sink (y %.2f, spawn %.2f)" % [dwarf.global_position.y, spawn.y])
	root.queue_free()


# ---------------------------------------------------------------- jump, step up, lantern
# These use a simple test room (flat floor + blocks), not the cave, so the shape is exact.

func _room(blocks: Array) -> Node3D:
	var root := Node3D.new()
	tree.root.add_child(root)
	_block(root, Vector3(0, -0.5, 0), Vector3(30, 1, 30))  # floor, top at y = 0
	for b in blocks:
		_block(root, b[0], b[1])
	return root


func _block(root: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	root.add_child(body)


func _dwarf_in(root: Node3D) -> Dwarf:
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	return dwarf


func _walk_forward(dwarf: Dwarf, seconds: float) -> float:
	var highest := dwarf.global_position.y
	dwarf.bot_move = Vector2(0, -1)  # forward = -z
	for i in int(seconds * 60):
		await tree.physics_frame
		highest = maxf(highest, dwarf.global_position.y)
	dwarf.bot_move = Vector2.ZERO
	return highest


func test_jump_goes_up_and_lands() -> void:
	Controls.setup()
	var root := _room([])
	var dwarf := _dwarf_in(root)
	for i in 30:
		await tree.physics_frame
	check(dwarf.is_on_floor(), "dwarf stands before jumping")
	dwarf.bot_jump = true
	var highest := 0.0
	for i in 90:
		await tree.physics_frame
		highest = maxf(highest, dwarf.global_position.y)
	check(highest > 1.2, "jump is at least 1.2 m high (got %.2f)" % highest)
	check(dwarf.is_on_floor(), "dwarf landed again")
	root.queue_free()


func test_jump_pressed_just_before_landing_still_counts() -> void:
	Controls.setup()
	var root := _room([])
	var dwarf := _dwarf_in(root)
	dwarf.global_position = Vector3(0, 0.6, 0)  # falling
	var pressed := false
	var highest_after := 0.0
	for i in 90:
		await tree.physics_frame
		if not pressed and dwarf.global_position.y < 0.25 and not dwarf.is_on_floor():
			dwarf.bot_jump = true  # a little too early
			pressed = true
		if pressed:
			highest_after = maxf(highest_after, dwarf.global_position.y)
	check(pressed, "test pressed jump while falling")
	check(highest_after > 1.0, "early jump press still jumped (got %.2f)" % highest_after)
	root.queue_free()


func test_steps_up_small_ledge() -> void:
	Controls.setup()
	# A 35 cm ledge starting 2 m ahead.
	var root := _room([[Vector3(0, 0.175, -6), Vector3(4, 0.35, 8)]])
	var dwarf := _dwarf_in(root)
	for i in 20:
		await tree.physics_frame
	await _walk_forward(dwarf, 2.0)
	check(dwarf.global_position.z < -3.0, "dwarf got past the ledge edge (z %.2f)" % dwarf.global_position.z)
	check(dwarf.global_position.y > 0.3, "dwarf is standing on top of the ledge (y %.2f)" % dwarf.global_position.y)
	root.queue_free()


func test_does_not_step_up_tall_wall() -> void:
	Controls.setup()
	# A 1.2 m wall 2 m ahead: needs a jump (or digging), not a step.
	var root := _room([[Vector3(0, 0.6, -4), Vector3(4, 1.2, 4)]])
	var dwarf := _dwarf_in(root)
	for i in 20:
		await tree.physics_frame
	var highest := await _walk_forward(dwarf, 2.0)
	check(highest < 0.3, "dwarf did not climb a 1.2 m wall by walking (highest %.2f)" % highest)
	root.queue_free()


func test_lantern_ignores_dwarf_body_for_shadows() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	await tree.process_frame
	var light := dwarf.lantern.light
	check(light.shadow_enabled, "lantern still makes shadows on the cave")
	check((light.shadow_caster_mask & DwarfModel.VISUAL_LAYER) == 0, "dwarf's body can't block own lantern")
	var meshes := dwarf.model.find_children("*", "MeshInstance3D", true, false)
	var bad := 0
	for m in meshes:
		var mi := m as MeshInstance3D
		var in_lantern := dwarf.lantern.is_ancestor_of(mi)
		if in_lantern and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			bad += 1
		if not in_lantern and mi.layers != DwarfModel.VISUAL_LAYER:
			bad += 1
	check(meshes.size() > 10, "found the dwarf's parts")
	check(bad == 0, "every body part is on the dwarf layer and the lantern casts no shadow (%d wrong)" % bad)
	root.queue_free()
