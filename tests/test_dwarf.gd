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
	var spawn := world.maker.spawn_point
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
