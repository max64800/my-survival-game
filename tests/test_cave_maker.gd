extends TestCase


func test_same_seed_same_cave() -> void:
	var a := CaveMaker.new(1234)
	var b := CaveMaker.new(1234)
	check_eq(a.rooms.size(), b.rooms.size(), "room count")
	check_eq(a.segments.size(), b.segments.size(), "tunnel count")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 200:
		var p := Vector3(rng.randf_range(-200, 200), rng.randf_range(-64, 16), rng.randf_range(-200, 200))
		if a.sdf_at(p) != b.sdf_at(p):
			check(false, "sdf differs at %s" % p)
			return


func test_different_seed_different_cave() -> void:
	var a := CaveMaker.new(1)
	var b := CaveMaker.new(2)
	check(a.rooms[0].center != b.rooms[0].center, "seeds 1 and 2 should differ")


func test_two_big_caverns_far_apart() -> void:
	for s in [1, 2, 3, 77, 4242]:
		var c := CaveMaker.new(s)
		var big := c.rooms.filter(func(r): return r.big)
		check_eq(big.size(), 2, "seed %d big cavern count" % s)
		if big.size() == 2:
			check(big[0].center.distance_to(big[1].center) > 60.0, "seed %d caverns too close" % s)


func test_spawn_is_standing_on_rock() -> void:
	for s in [1, 2, 3, 77, 4242]:
		var c := CaveMaker.new(s)
		check(c.sdf_at(c.spawn_point) > 0.0, "seed %d: spawn should be in air" % s)
		check(c.sdf_at(c.spawn_point + Vector3.UP * 1.5) > 0.0, "seed %d: head room at spawn" % s)
		check(c.sdf_at(c.spawn_point + Vector3.DOWN * 2.0) < 0.0, "seed %d: rock under spawn" % s)


func test_room_centers_are_open_air() -> void:
	var c := CaveMaker.new(55)
	for room in c.rooms:
		check(c.sdf_at(room.center) > 0.0, "room at %s should be air" % room.center)


func test_tunnels_join_every_room() -> void:
	# Walk the tunnel tubes as a graph: every room must touch the network.
	var c := CaveMaker.new(31)
	for room in c.rooms:
		var touched := false
		for s in c.segments:
			if s.a.distance_to(room.center) < 1.0 or s.b.distance_to(room.center) < 1.0:
				touched = true
				break
		check(touched, "room at %s has no tunnel" % room.center)


func test_outside_box_is_border_rock() -> void:
	var c := CaveMaker.new(7)
	for p in [Vector3i(205, -20, 0), Vector3i(0, -70, 0), Vector3i(0, 20, 0), Vector3i(-210, 0, -210)]:
		check(c.sdf_at(Vector3(p)) < 0.0, "%s should be solid" % p)
		check_eq(c.material_at(p), Mat.BORDER, "%s should be border rock" % p)


func test_copper_is_present_but_rare() -> void:
	var c := CaveMaker.new(8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ore := 0
	const N := 4000
	for i in N:
		var p := Vector3i(rng.randi_range(-190, 190), rng.randi_range(-60, 10), rng.randi_range(-190, 190))
		if c._is_ore(p):
			ore += 1
	var frac := float(ore) / N
	check(frac > 0.01 and frac < 0.12, "copper fraction %.3f should be 1%%-12%%" % frac)


func test_generated_block_matches_queries() -> void:
	var c := CaveMaker.new(99)
	var room: Dictionary = c.rooms[0]
	# Pick a block that contains the cavern floor.
	var origin := Vector3i(floori(room.center.x / 16) * 16, floori((room.center.y - room.radii.y * 0.55) / 16) * 16, floori(room.center.z / 16) * 16)
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	c.generate_block(buf, origin)
	var air := 0
	var solid := 0
	for z in range(0, 16, 3):
		for x in range(0, 16, 3):
			for y in range(0, 16, 3):
				var p := origin + Vector3i(x, y, z)
				var want := c.sdf_at(Vector3(p))
				var got := buf.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
				check_near(got, clampf(want, -500, 500), 0.05, "sdf at %s" % p)
				if want > 0:
					air += 1
				else:
					solid += 1
					check_eq(buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_INDICES), c.material_at(p), "material at %s" % p)
	check(air > 0 and solid > 0, "test block should contain both air and rock (air %d, rock %d)" % [air, solid])


func test_solid_block_fast_path() -> void:
	var c := CaveMaker.new(5)
	# Deep corner, far from caves but inside the box.
	var origin := Vector3i(176, -64, 176)
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	c.generate_block(buf, origin)
	check(buf.get_voxel_f(8, 8, 8, VoxelBuffer.CHANNEL_SDF) < 0.0, "deep block should be rock")


func test_generation_speed() -> void:
	var c := CaveMaker.new(99)
	var room: Dictionary = c.rooms[0]
	var origin := Vector3i(floori(room.center.x / 16) * 16, floori(room.center.y / 16) * 16, floori(room.center.z / 16) * 16)
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	var t := Time.get_ticks_usec()
	for i in 5:
		c.generate_block(buf, origin + Vector3i(16 * i, 0, 0))
	var ms := (Time.get_ticks_usec() - t) / 5000.0
	print("        (cave block takes %.1f ms)" % ms)
	check(ms < 150.0, "a cave block should generate in under 150 ms (took %.1f)" % ms)


func test_there_is_clay_for_a_smelter() -> void:
	# The smelter needs 15 clay, so every cave must have clay near its open spaces.
	for s in [1, 42, 99]:
		var c := CaveMaker.new(s)
		var clay := 0
		for room in c.rooms:
			for i in 400:
				var a := float(i) * 0.37
				var p := Vector3i((room.center + Vector3(cos(a) * room.radii.x, -room.radii.y * 0.6 - (i % 4), sin(a) * room.radii.z) * (0.3 + 0.7 * fmod(i * 0.618, 1.0))).round())
				if c.sdf_at(Vector3(p)) < 0.0 and c.material_at(p) == Mat.CLAY:
					clay += 1
		check(clay >= 15, "seed %d: clay voxels near rooms (found %d)" % [s, clay])
