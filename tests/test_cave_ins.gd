extends TestCase
## The cave-in rules (world doc 6.5) on a hand-made block of voxels.
## The test world: solid rock everywhere, with a big room of air carved in the middle.

const CENTER := Vector3(0, 0, 0)


func _world() -> Array:
	var b := CaveIns.box_for(CENTER)
	var buf := VoxelBuffer.new()
	var size: Vector3i = b[1]
	buf.create(size.x, size.y, size.z)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	buf.fill_f(-1.0, VoxelBuffer.CHANNEL_SDF)  # all rock
	buf.fill(Mat.STONE, VoxelBuffer.CHANNEL_INDICES)
	return [buf, b[0]]


func _put(w: Array, p: Vector3i, rock: bool) -> void:
	var v: Vector3i = p - w[1]
	w[0].set_voxel_f(-1.0 if rock else 1.0, v.x, v.y, v.z, VoxelBuffer.CHANNEL_SDF)


func _air_box(w: Array, lo: Vector3i, hi: Vector3i) -> void:
	for z in range(lo.z, hi.z + 1):
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				_put(w, Vector3i(x, y, z), false)


func _rock_ball(w: Array, c: Vector3i, r: float) -> void:
	var ri := ceili(r)
	for z in range(-ri, ri + 1):
		for y in range(-ri, ri + 1):
			for x in range(-ri, ri + 1):
				if Vector3(x, y, z).length() <= r:
					_put(w, c + Vector3i(x, y, z), true)


func _total(falls: Array) -> int:
	var n := 0
	for f in falls:
		n += f.size()
	return n


func test_normal_mining_never_falls() -> void:
	var w := _world()
	_air_box(w, Vector3i(-1, -1, -1), Vector3i(1, 1, 1))  # a small dug hole in solid rock
	var t := Time.get_ticks_usec()
	var falls := CaveIns.find_falls(w[0], w[1], CENTER, 1.35)
	print("        (solid-rock check: %.2f ms)" % ((Time.get_ticks_usec() - t) / 1000.0))
	check(falls.is_empty(), "digging in solid rock never causes a cave-in")


func test_loose_ball_falls() -> void:
	var w := _world()
	_air_box(w, Vector3i(-8, -8, -8), Vector3i(8, 8, 8))  # a 17 m room
	_rock_ball(w, Vector3i(0, 0, 0), 2.0)  # a 4 m rock ball floating in it (we just dug around it)
	var falls := CaveIns.find_falls(w[0], w[1], Vector3(0, 0, 3.4), 1.35)
	check_eq(falls.size(), 1, "one island")
	check(_total(falls) > 20, "the whole ball falls (%d voxels)" % _total(falls))


func test_ball_on_a_mine_prop_stays() -> void:
	var w := _world()
	_air_box(w, Vector3i(-8, -8, -8), Vector3i(8, 8, 8))
	_rock_ball(w, Vector3i(0, 0, 0), 2.0)
	var falls := CaveIns.find_falls(w[0], w[1], Vector3(0, 0, 3.4), 1.35, [Vector3(0, -2, 0)])
	check(falls.is_empty(), "a prop under it holds it up")


func test_long_icicle_falls_short_one_stays() -> void:
	for length in [22, 18]:
		var w := _world()
		_air_box(w, Vector3i(-10, -24, -10), Vector3i(10, 20, 10))  # tall room, ceiling at y = 21
		# A 1×1 spike hanging from the ceiling down `length` voxels.
		for y in range(21 - length, 21):
			_put(w, Vector3i(0, y, 0), true)
		var falls := CaveIns.find_falls(w[0], w[1], Vector3(1, 21 - length, 1), 1.0)
		if length == 22:
			check(_total(falls) >= 20, "22 m spike falls (%d voxels)" % _total(falls))
		else:
			check(falls.is_empty(), "18 m spike stays")


func test_thick_ledge_and_arch_stay() -> void:
	var w := _world()
	_air_box(w, Vector3i(-14, -10, -14), Vector3i(14, 10, 14))
	# A 4 m thick ledge sticking out of the -x wall, 14 m long.
	for z in range(-2, 2):
		for y in range(0, 4):
			for x in range(-15, 0):
				_put(w, Vector3i(x, y, z), true)
	check(CaveIns.find_falls(w[0], w[1], Vector3(1, 1, 0), 1.35).is_empty(), "thick ledge stays")
	# An arch standing on the floor (floor rock is at y = -11), 2 voxels thick.
	for x in range(-6, 7):
		var top := -10 + int(10.0 - x * x * 0.25)
		var bottom := -11 if absi(x) >= 5 else top - 4
		for y in range(bottom, top + 1):
			_put(w, Vector3i(x, y, 6), true)
	check(CaveIns.find_falls(w[0], w[1], Vector3(0, 0, 7), 1.0).is_empty(), "arch stays")


func test_border_rock_is_an_anchor() -> void:
	var w := _world()
	_air_box(w, Vector3i(-8, -8, -8), Vector3i(8, 8, 8))
	_rock_ball(w, Vector3i(0, 0, 0), 2.0)
	var v: Vector3i = Vector3i(0, 0, 0) - w[1]
	w[0].set_voxel(Mat.BORDER, v.x, v.y, v.z, VoxelBuffer.CHANNEL_INDICES)
	check(CaveIns.find_falls(w[0], w[1], Vector3(0, 0, 3.4), 1.35).is_empty(), "border rock never falls")
