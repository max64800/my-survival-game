class_name CaveMaker
extends RefCounted
## Cave Maker: turns a seed number into a cave.
##
## It answers two questions for any spot in the world:
##   sdf_at(p)      -> how far is this spot from open air? (negative = inside rock)
##   material_at(p) -> what kind of rock is here?
## Same seed = same answers, every time, on every computer (important for co-op).
##
## The cave is made from simple shapes of "air": big caverns (squashed balls with
## flat floors) and twisty tunnels (chains of tubes with flat floors).
## Everything outside the biome box is undiggable border rock.

# --- Size of the Mossy Hollows biome (meters; 1 voxel = 1 meter) ---
const HALF_SIZE := 200.0
const Y_MIN := -64.0
const Y_MAX := 16.0

# --- Shape tuning ---
const WALL_NOISE_AMP := 2.2  ## how bumpy walls are (meters)
const BLEND := 3.0  ## how softly tunnels melt into caverns (meters)
const CULL_MARGIN := 6.0  ## blocks farther than this from every shape are solid rock
const ORE_CELL := 2  ## ore veins are decided on a 2 m grid
const ORE_THRESHOLD := 0.6
const SOLID_FILL := -6.0  ## SDF value used for blocks that are all rock

var seed: int
var rooms: Array[Dictionary] = []  ## {center: Vector3, radii: Vector3, big: bool}
var segments: Array[Dictionary] = []  ## {a: Vector3, b: Vector3, r: float}
var spawn_point := Vector3.ZERO

# Flat copies of the shapes, so the hot loops don't touch Dictionaries.
var _room_c := PackedVector3Array()
var _room_r := PackedVector3Array()
var _room_min := PackedVector3Array()
var _room_max := PackedVector3Array()
var _seg_a := PackedVector3Array()
var _seg_b := PackedVector3Array()
var _seg_r := PackedFloat32Array()
var _seg_min := PackedVector3Array()
var _seg_max := PackedVector3Array()

var _wall_noise := FastNoiseLite.new()
var _ore_noise := FastNoiseLite.new()
var _dirt_noise := FastNoiseLite.new()


func _init(p_seed: int = 1, big_caverns: int = 2, small_rooms: int = 7) -> void:
	seed = p_seed
	_setup_noise()
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	_place_rooms(rng, big_caverns, small_rooms)
	_connect_rooms(rng)
	_bake_shapes()
	spawn_point = _find_spawn()


# ---------------------------------------------------------------- layout

func _setup_noise() -> void:
	_wall_noise.seed = seed
	_wall_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_wall_noise.frequency = 0.07
	_wall_noise.fractal_octaves = 2
	_ore_noise.seed = seed + 101
	_ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_ore_noise.frequency = 0.11
	_ore_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_dirt_noise.seed = seed + 202
	_dirt_noise.frequency = 0.05


func _place_rooms(rng: RandomNumberGenerator, big_count: int, small_count: int) -> void:
	# Big caverns: spread far apart so there's a journey between them.
	var tries := 0
	while _count_big() < big_count and tries < 500:
		tries += 1
		var c := Vector3(rng.randf_range(-140, 140), rng.randf_range(-38, -18), rng.randf_range(-140, 140))
		var r := Vector3(rng.randf_range(24, 34), rng.randf_range(10, 14), rng.randf_range(24, 34))
		if _far_from_rooms(c, 120.0 if tries < 300 else 70.0):
			rooms.append({center = c, radii = r, big = true})
	# Small chambers: little rooms along the way.
	tries = 0
	while rooms.size() < big_count + small_count and tries < 1000:
		tries += 1
		var c := Vector3(rng.randf_range(-170, 170), rng.randf_range(-54, -2), rng.randf_range(-170, 170))
		var r := Vector3(rng.randf_range(7, 12), rng.randf_range(5, 7), rng.randf_range(7, 12))
		if _far_from_rooms(c, 45.0):
			rooms.append({center = c, radii = r, big = false})


func _count_big() -> int:
	var n := 0
	for room in rooms:
		if room.big:
			n += 1
	return n


func _far_from_rooms(c: Vector3, min_dist: float) -> bool:
	for room in rooms:
		if c.distance_to(room.center) < min_dist:
			return false
	return true


## Joins every room with tunnels. A "minimum spanning tree" guarantees every room
## can be reached without digging; a few extra tunnels make loops, and some
## dead ends make exploring less predictable.
func _connect_rooms(rng: RandomNumberGenerator) -> void:
	var n := rooms.size()
	if n == 0:
		return
	var in_tree := {0: true}
	var edges: Array[Vector2i] = []
	while in_tree.size() < n:
		var best := Vector2i(-1, -1)
		var best_d := INF
		for i in in_tree:
			for j in n:
				if in_tree.has(j):
					continue
				var d: float = rooms[i].center.distance_to(rooms[j].center)
				if d < best_d:
					best_d = d
					best = Vector2i(i, j)
		in_tree[best.y] = true
		edges.append(best)
	# Two loops.
	for k in 2:
		var i := rng.randi_range(0, n - 1)
		var j := rng.randi_range(0, n - 1)
		if i != j:
			edges.append(Vector2i(i, j))
	for e in edges:
		_dig_worm(rng, rooms[e.x].center, rooms[e.y].center)
	# Dead ends.
	for k in 4:
		var start: Vector3 = rooms[rng.randi_range(0, n - 1)].center
		var angle := rng.randf_range(0, TAU)
		var end := start + Vector3(cos(angle), rng.randf_range(-0.3, 0.3), sin(angle)) * rng.randf_range(40, 80)
		_dig_worm(rng, start, _clamp_inside(end))


## A wandering tunnel from a to b, made of short tubes.
func _dig_worm(rng: RandomNumberGenerator, a: Vector3, b: Vector3) -> void:
	const STEP := 6.0
	var pos := a
	var guard := 0
	while pos.distance_to(b) > STEP and guard < 300:
		guard += 1
		var dir := (b - pos).normalized()
		var wander := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1))
		dir = (dir + wander * 0.65).normalized()
		dir.y = clampf(dir.y, -0.42, 0.42)  # keep slopes walkable for a dwarf
		var next := _clamp_inside(pos + dir.normalized() * STEP)
		segments.append({a = pos, b = next, r = rng.randf_range(2.3, 3.3)})
		pos = next
	segments.append({a = pos, b = b, r = rng.randf_range(2.3, 3.3)})


func _clamp_inside(p: Vector3) -> Vector3:
	const M := 185.0
	return Vector3(clampf(p.x, -M, M), clampf(p.y, Y_MIN + 8.0, Y_MAX - 8.0), clampf(p.z, -M, M))


func _bake_shapes() -> void:
	var pad := Vector3.ONE * (WALL_NOISE_AMP + BLEND + 1.0)
	for room in rooms:
		_room_c.append(room.center)
		_room_r.append(room.radii)
		_room_min.append(room.center - room.radii - pad)
		_room_max.append(room.center + room.radii + pad)
	for s in segments:
		_seg_a.append(s.a)
		_seg_b.append(s.b)
		_seg_r.append(s.r)
		var rv: Vector3 = Vector3.ONE * float(s.r)
		_seg_min.append(s.a.min(s.b) - rv - pad)
		_seg_max.append(s.a.max(s.b) + rv + pad)


func _find_spawn() -> Vector3:
	var c: Vector3 = rooms[0].center if not rooms.is_empty() else Vector3.ZERO
	return find_floor(c.x, c.z, c.y) + Vector3.UP * 1.0


## Walks down from (x, y_start, z) until it hits rock. Returns the point just above the rock.
func find_floor(x: float, z: float, y_start: float) -> Vector3:
	var y := y_start
	while y > Y_MIN and sdf_at(Vector3(x, y, z)) > 0.0:
		y -= 0.25
	return Vector3(x, y, z)


# ---------------------------------------------------------------- queries

## Signed distance: positive = open air, negative = inside rock.
func sdf_at(p: Vector3) -> float:
	return _sdf_with(p, _all_rooms(), _all_segments())


## What rock is at p (only meaningful inside rock).
func material_at(p: Vector3i) -> int:
	var pf := Vector3(p)
	if _bound_dist(pf) < 0.0:
		return Mat.BORDER
	if _is_ore(p):
		return Mat.COPPER
	var s := sdf_at(pf)
	if sdf_at(pf + Vector3.UP) > 0.0:
		return Mat.MOSS
	if sdf_at(pf + Vector3.UP * 2.0) > 0.0:
		return Mat.DIRT
	if s > -2.5 and _dirt_noise.get_noise_3dv(pf) > 0.35:
		return Mat.DIRT
	return Mat.STONE


func _all_rooms() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(_room_c.size())
	for i in out.size():
		out[i] = i
	return out


func _all_segments() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(_seg_a.size())
	for i in out.size():
		out[i] = i
	return out


func _sdf_with(p: Vector3, room_ids: PackedInt32Array, seg_ids: PackedInt32Array) -> float:
	var d := 1e9
	for i in room_ids:
		d = _smin(d, _room_dist(p, i), BLEND)
	for i in seg_ids:
		d = _smin(d, _seg_dist(p, i), BLEND)
	var s := -d + _wall_noise.get_noise_3dv(p) * WALL_NOISE_AMP
	return minf(s, _bound_dist(p))


## Distance to the inside of a room (negative = inside the air).
func _room_dist(p: Vector3, i: int) -> float:
	var c := _room_c[i]
	var r := _room_r[i]
	var q := (p - c) / r
	var d := (q.length() - 1.0) * minf(r.x, minf(r.y, r.z))
	var floor_y := c.y - r.y * 0.55  # flat floor
	return maxf(d, floor_y - p.y)


func _seg_dist(p: Vector3, i: int) -> float:
	var a := _seg_a[i]
	var ab := _seg_b[i] - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var cp := a + ab * t
	var r := _seg_r[i]
	var d := p.distance_to(cp) - r
	return maxf(d, (cp.y - r * 0.6) - p.y)  # flat floor


## Distance to the edge of the biome box. Negative = outside (border rock).
func _bound_dist(p: Vector3) -> float:
	return minf(minf(HALF_SIZE - absf(p.x), HALF_SIZE - absf(p.z)), minf(p.y - Y_MIN, Y_MAX - p.y))


static func _smin(a: float, b: float, k: float) -> float:
	var h := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


func _is_ore(p: Vector3i) -> bool:
	var cell := Vector3(floori(p.x / float(ORE_CELL)), floori(p.y / float(ORE_CELL)), floori(p.z / float(ORE_CELL)))
	var n := _ore_noise.get_noise_3dv(cell * ORE_CELL + Vector3.ONE * (ORE_CELL * 0.5))
	# Deeper = a bit more copper.
	var depth_bonus := clampf((-p.y) / 64.0, 0.0, 1.0) * 0.08
	return n + depth_bonus > ORE_THRESHOLD


# ---------------------------------------------------------------- voxel generation

## Fills a Voxel Tools buffer for the block starting at `origin`.
## Called on worker threads, so it only reads data (never changes this object).
func generate_block(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var bmin := Vector3(origin)
	var bmax := bmin + Vector3(size)
	var room_ids := PackedInt32Array()
	var seg_ids := PackedInt32Array()
	var lo := bmin - Vector3.ONE * CULL_MARGIN
	var hi := bmax + Vector3.ONE * CULL_MARGIN
	for i in _room_c.size():
		if _overlaps(lo, hi, _room_min[i], _room_max[i]):
			room_ids.append(i)
	for i in _seg_a.size():
		if _overlaps(lo, hi, _seg_min[i], _seg_max[i]):
			seg_ids.append(i)

	const SDF := VoxelBuffer.CHANNEL_SDF
	const IDX := VoxelBuffer.CHANNEL_INDICES
	var touches_border := bmin.x < -HALF_SIZE or bmax.x > HALF_SIZE or bmin.z < -HALF_SIZE \
		or bmax.z > HALF_SIZE or bmin.y < Y_MIN or bmax.y > Y_MAX

	if room_ids.is_empty() and seg_ids.is_empty():
		# Solid rock block: fast path.
		buf.fill_f(SOLID_FILL, SDF)
		buf.fill(Mat.STONE, IDX)
		_fill_ore(buf, origin, size)
		if touches_border:
			_fill_border(buf, origin, size)
		return

	# Block near caves: compute every voxel. One extra layer on top lets us find floors.
	var sx := size.x
	var sy := size.y
	var sz := size.z
	var grid := PackedFloat32Array()
	grid.resize(sx * (sy + 2) * sz)
	var gi := 0
	for z in sz:
		for x in sx:
			for y in sy + 2:
				var p := Vector3(origin.x + x, origin.y + y, origin.z + z)
				grid[gi] = _sdf_with(p, room_ids, seg_ids)
				gi += 1
	var col := sy + 2
	gi = 0
	for z in sz:
		for x in sx:
			var base := gi
			for y in sy:
				var s := grid[base + y]
				buf.set_voxel_f(s, x, y, z, SDF)
				if s > 0.0:
					buf.set_voxel(Mat.STONE, x, y, z, IDX)  # air: material unused
					continue
				var pi := Vector3i(origin.x + x, origin.y + y, origin.z + z)
				var m := Mat.STONE
				if _bound_dist(Vector3(pi)) < 0.0:
					m = Mat.BORDER
				elif _is_ore(pi):
					m = Mat.COPPER
				elif grid[base + y + 1] > 0.0:
					m = Mat.MOSS
				elif grid[base + y + 2] > 0.0:
					m = Mat.DIRT
				elif s > -2.5 and _dirt_noise.get_noise_3dv(Vector3(pi)) > 0.35:
					m = Mat.DIRT
				buf.set_voxel(m, x, y, z, IDX)
			gi += col


func _fill_ore(buf: VoxelBuffer, origin: Vector3i, size: Vector3i) -> void:
	for cz in range(0, size.z, ORE_CELL):
		for cx in range(0, size.x, ORE_CELL):
			for cy in range(0, size.y, ORE_CELL):
				var p := origin + Vector3i(cx, cy, cz)
				if _is_ore(p):
					var mn := Vector3i(cx, cy, cz)
					buf.fill_area(Mat.COPPER, mn, (mn + Vector3i.ONE * ORE_CELL).min(size), VoxelBuffer.CHANNEL_INDICES)


func _fill_border(buf: VoxelBuffer, origin: Vector3i, size: Vector3i) -> void:
	for z in size.z:
		for x in size.x:
			for y in size.y:
				if _bound_dist(Vector3(origin + Vector3i(x, y, z))) < 0.0:
					buf.set_voxel(Mat.BORDER, x, y, z, VoxelBuffer.CHANNEL_INDICES)


static func _overlaps(amin: Vector3, amax: Vector3, bmin: Vector3, bmax: Vector3) -> bool:
	return amin.x <= bmax.x and amax.x >= bmin.x and amin.y <= bmax.y and amax.y >= bmin.y \
		and amin.z <= bmax.z and amax.z >= bmin.z
