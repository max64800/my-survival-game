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


func test_three_big_caverns_far_apart() -> void:
	if CaveMaker.layout >= 2:
		return  # layout 1's own numbers (layout 2: tests/test_cave_layout2.gd)
	for s in [1, 2, 3, 77, 4242]:
		var c := CaveMaker.new(s)
		var big := c.rooms.filter(func(r): return r.big and r.biome == "mossy")
		big = big.filter(func(r): return not r.sealed)
		check_eq(big.size(), 3, "seed %d big cavern count" % s)
		if big.size() >= 2:
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
		if room.sealed or room.kind == "shrine":
			continue  # sealed places are reached by digging; shrines are alcoves on a tunnel
		var touched := false
		for s in c.segments:
			var m := CaveMaker.mouth(room)  # tunnels leave at floor height (F141)
			if s.a.distance_to(m) < 1.0 or s.b.distance_to(m) < 1.0:
				touched = true
				break
		check(touched, "room at %s has no tunnel" % room.center)


func test_outside_box_is_border_rock() -> void:
	var c := CaveMaker.new(7)
	var h := int(CaveMaker.HALF_SIZE)  # (200 m in layout 1, 400 m in layout 2)
	for p in [Vector3i(0, -70, 0), Vector3i(0, 20, 0), Vector3i(-h - 10, 0, -h - 10), Vector3i(int(CaveMaker.X_MAX) + 10, -20, 0),
			Vector3i(int(CaveMaker.BIOMES[1].cx), -20, h + 5)]:
		check(c.sdf_at(Vector3(p)) < 0.0, "%s should be solid" % p)
		check_eq(c.material_at(p), Mat.EDGE, "%s is the world's edge" % p)
	# The slab between Mossy and Fungal is border rock, except the gate stubs.
	var gz: float = c.gates[0].pos.z
	var z := gz + 60.0 if absf(c.gates[1].pos.z - (gz + 60.0)) > 20.0 else gz - 60.0
	var sx := int(CaveMaker.SLAB_X)
	for x in [sx + 1, sx + 10, sx + 19]:
		var p := Vector3i(x, -20, int(z))
		check(c.sdf_at(Vector3(p)) < 0.0, "%s should be solid" % p)
		check_eq(c.material_at(p), Mat.BORDER, "%s is border rock" % p)


func test_two_biomes_joined_by_gates() -> void:
	var c := CaveMaker.new(7)
	check_eq(c.gates.size(), 2, "two gates")
	var fungal := c.rooms.filter(func(r): return r.biome == "fungal")
	check(fungal.size() >= 12, "the Jungle has rooms")
	for r in fungal:
		check(r.center.x > CaveMaker.SLAB_X + CaveMaker.SLAB_W and r.center.x < CaveMaker.X_MAX, "jungle room inside its box")
	for g in c.gates:
		var p: Vector3 = g.pos
		check(c.sdf_at(p) < 0.0, "the plug is rock")
		check_eq(c.material_at(Vector3i(p.round())), Mat.BORDER, "the plug is border rock (copper pickaxe)")
		var floor_y: float = p.y - 1.0
		check(c.sdf_at(Vector3(p.x - 4.0, floor_y + 0.5, p.z)) > 0.0, "open tunnel on the Mossy side of the plug")
		check(c.sdf_at(Vector3(p.x + 4.0, floor_y + 0.5, p.z)) > 0.0, "open tunnel on the Jungle side of the plug")
	check(not c.lair_poi("fungal").is_empty(), "the Jungle has a hidden lair")
	check_eq(c.clue_circles("fungal").size(), 3, "and its own clue circles")
	check_eq(c.pois_of("marking", "fungal").size(), 3, "3 jungle markings")
	check(c.pois_of("silver_vault").size() == 1, "side-boss caverns are planned")
	check_eq(c.material_at(Vector3i(c.rooms[0].center.round()) + Vector3i(0, -40, 0)) in [Mat.STONE, Mat.COPPER, Mat.DIRT, Mat.CLAY, Mat.MOSS], true, "Mossy rock under the start")


## F115: Mossy copper only in the Copper Deeps (far from the start, low down), and rich there.
func test_copper_only_in_the_deeps() -> void:
	for sd in [8, 42, 1234]:
		var c := CaveMaker.new(sd)
		check_eq(c.deeps.size(), CaveMaker.DEEPS_COUNT, "seed %d: two Copper Deeps" % sd)
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		var outside := 0
		for i in 3000:
			var p := Vector3i(rng.randi_range(-190, -10), rng.randi_range(-60, 10), rng.randi_range(-190, 190))
			if not c.in_deeps(Vector3(p)) and c._is_ore(p):
				outside += 1
		check_eq(outside, 0, "seed %d: no copper outside the Deeps" % sd)
		var inside := 0
		var tries := 0
		for d in c.deeps:
			for i in 1500:
				var p := Vector3i((d.center + Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * d.reach).round())
				if c.in_deeps(Vector3(p)):
					tries += 1
					if c._is_ore(p):
						inside += 1
		var frac := float(inside) / maxf(tries, 1)
		check(frac > 0.02, "seed %d: the Deeps are rich in copper (%.3f)" % [sd, frac])
		var far := 0.0
		for d in c.deeps:
			far = maxf(far, Vector2(d.center.x - c.spawn_point.x, d.center.z - c.spawn_point.z).length())
		check(far > 40.0, "seed %d: the Deeps are far from the start (%.0f m)" % [sd, far])


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
				# Chunky rock (F109): the terrain stores "rock or air" with a fixed random strength.
				if CaveMaker.rock_style == "blocks":
					check_near(got, c.block_value(c._smooth_at(Vector3(p)), p, c._smooth_at(Vector3(p + Vector3i.UP))), 0.03, "block value at %s (the terrain stores it a little rounded)" % p)
				elif c.made_layout < 2 or (want > -3.0 and want <= 0.0):
					# (layout 2 blends the depth deep in rock and out in the air: only rock near a wall needs it exact)
					check_near(got, clampf(want, -500, 500), 0.05, "sdf at %s" % p)
				check(signf(got) == signf(want) or want == 0.0, "rock/air at %s agrees with the query" % p)
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
	if CaveMaker.layout >= 2:
		return  # layout 1's own numbers (layout 2: tests/test_cave_layout2.gd)
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



func test_special_places_are_planned() -> void:
	for s in [1, 42, 99]:
		var c := CaveMaker.new(s)
		var lair := c.lair_poi()
		check(not lair.is_empty(), "seed %d: a boss lair" % s)
		if lair.is_empty():
			continue
		check(lair.pos.distance_to(c.spawn_point) >= 145.0, "seed %d: lair far from the start" % s)
		var room: Dictionary = c.rooms[lair.room]
		check(room.sealed, "seed %d: lair is sealed" % s)
		check(c._solid_around(room.center, room.radii + Vector3.ONE * 5.0) == false, "seed %d: (lair is air inside now)" % s)
		check(c.sdf_at(room.center) > 0.0, "seed %d: lair is open inside" % s)
		var shell := 0
		for dir in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			if c.sdf_at(room.center + dir * (room.radii.x + 4.0)) < 0.0:
				shell += 1
		check_eq(shell, 4, "seed %d: rock all around the lair" % s)
		check_eq(c.pois_of("marking", "mossy").size(), 3, "seed %d: 3 wall markings" % s)
		for m in c.pois_of("marking", "mossy"):
			check(m.pos.distance_to(lair.pos) >= 79.0, "seed %d: marking far from the lair" % s)
		check(c.pois_of("ruin").size() >= 2, "seed %d: ruins" % s)
		check(c.pois_of("shrine").size() >= 3, "seed %d: rune shrines (%d)" % [s, c.pois_of("shrine").size()])
		check(c.pois_of("geode").size() >= 2, "seed %d: crystal geodes (%d)" % [s, c.pois_of("geode").size()])
		check(not c.pois_of("nest_cavern").is_empty() and not c.pois_of("great_hall").is_empty(), "seed %d: side-boss caverns" % s)


## F141: tunnels leave a room at floor height, not high up in its walls.
func test_tunnel_mouths_are_at_floor_height() -> void:
	var c := CaveMaker.new(31)
	for room in c.rooms:
		if room.sealed:
			continue
		var floor_y: float = room.center.y - room.radii.y * 0.55
		check(CaveMaker.mouth(room).y - floor_y <= 2.0, "a tunnel mouth at most 2 m above the floor (room at %s)" % room.center)


## F109: chunky rock. The terrain stores only "rock" or "air" at each 1 m point, with a random strength
## between BLOCK_MIN and 1 that never changes; sdf_at follows the same blocks near walls.
func test_rock_is_chunky_blocks() -> void:
	var style := CaveMaker.rock_style
	CaveMaker.rock_style = "blocks"
	var c := CaveMaker.new(42)
	var room: Dictionary = c.rooms[0]
	var strengths := {}
	for i in 200:
		var g := Vector3i((room.center + Vector3(randf_range(-8, 8), randf_range(-6, 6), randf_range(-8, 8))).round())
		var up := c._smooth_at(Vector3(g + Vector3i.UP))
		var v := c.block_value(c._smooth_at(Vector3(g)), g, up)
		check(absf(v) >= CaveMaker.BLOCK_MIN - 0.001 and absf(v) <= 1.001, "a block point is plain rock or air (%.2f)" % v)
		check_near(c.block_value(c._smooth_at(Vector3(g)), g, up), v, 0.0001, "the same point always gets the same strength")
		strengths[snappedf(absf(v), 0.05)] = true
	check(strengths.size() > 4, "blocks are lopsided: different strengths (%d kinds)" % strengths.size())
	# Exactly at a grid point, sdf_at gives the stored block value (so things sit on the real surface).
	var g0 := Vector3i(room.center.round())
	while absf(c._smooth_at(Vector3(g0))) > CaveMaker.NEAR_BLOCKS and g0.y > room.center.y - 30:
		g0.y -= 1  # walk down to the floor: near a wall
	CaveMaker.rock_style = style  # (checked below with blocks on; put the style back after)
	CaveMaker.rock_style = "blocks"
	check_near(c.sdf_at(Vector3(g0)), CaveMaker.BLEND_SAFE * c.block_value(c._smooth_at(Vector3(g0)), g0, c._smooth_at(Vector3(g0 + Vector3i.UP))), 0.0001, "near a wall, sdf_at matches the blocks at grid points")
	CaveMaker.rock_style = style
