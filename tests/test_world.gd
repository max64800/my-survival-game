extends TestCase
## Checks that need the real Voxel Tools terrain loaded.


func _make_world(seed: int, viewer_pos: Vector3) -> World:
	var world := World.new()
	tree.root.add_child(world)
	world.setup(seed)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_visuals = false
	world.add_child(viewer)
	viewer.global_position = viewer_pos
	return world


func _wait_ready(world: World, p: Vector3) -> bool:
	for i in 600:
		if world.is_ready_at(p, 3.0):
			return true
		await tree.process_frame
	return false


func test_world_loads_and_matches_cave_maker() -> void:
	var world := _make_world(42, Vector3.ZERO)
	world.get_child(-1).global_position = world.maker.cavern_spawn
	var spawn := world.maker.cavern_spawn
	check(await _wait_ready(world, spawn), "terrain should load around spawn")
	var below := Vector3i((spawn + Vector3.DOWN * 3.0).round())
	check(world.sdf_at(Vector3(below)) < 0.0, "rock under spawn")
	check_eq(world.material_at(Vector3(below)), world.maker.material_at(below), "material under spawn")
	world.queue_free()


func test_digging_makes_air_and_counts_rock() -> void:
	var world := _make_world(42, Vector3.ZERO)
	var spawn := world.maker.cavern_spawn
	world.get_child(-1).global_position = spawn
	check(await _wait_ready(world, spawn), "terrain should load")
	var target := spawn + Vector3.DOWN * 3.0
	check(world.sdf_at(target) < 0.0, "target starts as rock")
	var counts := world.apply_dig(target, 1.5)
	var total := 0
	for k in counts:
		total += counts[k]
	check(total >= 5, "a dig should remove several voxels (removed %d)" % total)
	check(world.sdf_at(target) > 0.0, "target is air after digging")
	world.queue_free()


func test_border_rock_cannot_be_dug() -> void:
	var edge := Vector3(CaveMaker.HALF_SIZE + 1.0, -30.0, CaveMaker.gate_free_z(42))  # just outside the biome box, not at a gate
	var world := _make_world(42, edge)
	check(await _wait_ready(world, edge), "terrain should load at the border")
	check_eq(world.material_at(edge), Mat.BORDER, "edge is border rock")
	var counts := world.apply_dig(edge, 1.5)
	check(not counts.has(Mat.BORDER), "border rock must not be removed")
	check(world.sdf_at(edge) < 0.0, "border spot is still solid")
	world.queue_free()


func test_dig_size_survives_the_network_packing() -> void:
	for t in [0, 1, 2]:
		for r in [0.8, 1.35]:
			var u := GameAuthority.unpack_dig(GameAuthority.pack_dig(t, r))
			check_eq(int(u.x), t, "tier %d" % t)
			check_near(u.y, r, 0.0001, "radius %.2f exactly" % r)
