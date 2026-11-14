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
##
## The world is a row of biomes (world doc 1): Mossy Hollows in the middle (x -200…200), the
## Fungal Jungle to the east (x 220…620). Between them is a 20 m slab of border rock with
## two gate tunnels dug most of the way through; a copper pickaxe breaks the last 4 m.
## Outside everything is the world's edge, which nothing can dig.

# --- Size of one biome (meters; 1 voxel = 1 meter) ---
const HALF_SIZE := 200.0
const Y_MIN := -64.0
const Y_MAX := 16.0
## Biomes: id, center x. Each is a box ±HALF_SIZE around its center.
const BIOMES := [{id = "mossy", cx = 0.0}, {id = "fungal", cx = 420.0}]
const SLAB_X := 200.0  ## the Mossy/Fungal border slab runs from x 200 to 220
const SLAB_W := 20.0
const PLUG := 4.0  ## rock left in the middle of each gate tunnel
const X_MIN := -HALF_SIZE
const X_MAX := 620.0

# --- Shape tuning ---
const WALL_NOISE_AMP := 2.2  ## how bumpy walls are (meters)
const BLEND := 3.0  ## how softly tunnels melt into caverns (meters)
const CULL_MARGIN := 6.0  ## blocks farther than this from every shape are solid rock
const ORE_CELL := 2  ## ore veins are decided on a 2 m grid
const ORE_THRESHOLD := 0.66
const SOLID_FILL := -6.0  ## SDF value used for blocks that are all rock

var seed: int
var rooms: Array[Dictionary] = []  ## {center: Vector3, radii: Vector3, big: bool, kind: String, sealed: bool}
## Special places (world doc 3.1): {id, type, pos, normal, room}. type: lair, nest_cavern,
## great_hall, ruin, nest, camp, shrine, geode, marking.
var pois: Array[Dictionary] = []
var segments: Array[Dictionary] = []  ## {a: Vector3, b: Vector3, r: float}
var spawn_point := Vector3.ZERO
## Gate tunnels through the border slab: {pos (the middle of the plug), min, max (the open stubs' box)}
var gates: Array[Dictionary] = []
var _gate_min := PackedVector3Array()
var _gate_max := PackedVector3Array()

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
## Lookup grid: which shapes are near each 16 m cell, so sdf_at() only checks those.
const GRID := 16
var _grid := {}  ## Vector3i cell -> [PackedInt32Array rooms, PackedInt32Array segments]

var _poi_biome := "mossy"  ## while planning: which biome new places belong to
var _wall_noise := FastNoiseLite.new()
var _ore_noise := FastNoiseLite.new()
var _dirt_noise := FastNoiseLite.new()


func _init(p_seed: int = 1, big_caverns: int = 3, small_rooms: int = 12) -> void:
	seed = p_seed
	_setup_noise()
	# Mossy Hollows first, with the same dice as before biomes existed (old caves stay the same).
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	_place_rooms(rng, big_caverns, small_rooms, 0.0, "mossy")
	_connect_rooms(rng, 0, 0.0)
	_bake_shapes()
	spawn_point = _find_spawn()
	var poi_rng := RandomNumberGenerator.new()
	poi_rng.seed = p_seed + 999  # its own dice, so adding places never moves the caves
	_plan_pois(poi_rng, 0, rooms.size(), 0, segments.size(), rooms[0].center, "mossy", 0.0)
	# The Fungal Jungle, then the gates that join them.
	var frng := RandomNumberGenerator.new()
	frng.seed = p_seed + 7000
	var r0 := rooms.size()
	var s0 := segments.size()
	_place_rooms(frng, big_caverns, small_rooms, BIOMES[1].cx, "fungal")
	_connect_rooms(frng, r0, BIOMES[1].cx)
	var s1 := segments.size()  # the gate tunnels (added next) cross both biomes: no jungle shrines on them
	_dig_gates(frng, r0)
	_bake_shapes()
	var fpoi := RandomNumberGenerator.new()
	fpoi.seed = p_seed + 7999
	_plan_pois(fpoi, r0, rooms.size(), s0, s1, gates[0].pos, "fungal", BIOMES[1].cx)
	# Last, so it never moves anything above: the small room where you wake up.
	cavern_spawn = spawn_point
	_plan_start()
	if not start.is_empty():
		spawn_point = start.spawn


# ---------------------------------------------------------------- the start (feedback F10)
# You wake in a small, sealed room. Through a peephole in a soft dirt wall you can see a glow.
# Dig through the wall, follow a short tunnel, and you come out in the first big cavern.
# These shapes are exact (no bumpy-wall noise), so the thin wall and the hole stay as planned.

const START_ROOM_R := Vector3(3.2, 2.4, 3.2)
const START_TUNNEL_R := 1.7
const START_PLUG := 1.8   ## how thick the dirt wall is
const START_HOLE_R := 0.45  ## the peephole
const START_HOLE_Y := 1.45  ## peephole height above the room floor

## Empty if no good spot was found (then you start in the cavern like before).
## Keys: room_c, dir (from the room toward the cavern), floor_y, tunnel [{a,b,r}], hole_a, hole_b,
## plug_a, plug_b, spawn, loose [Vector3], roots [Vector3], caps [Vector3], tunnel_glow [Vector3], min, max.
var start := {}
## The old start in the middle of the first cavern (test robots still start here).
var cavern_spawn := Vector3.ZERO


func _plan_start() -> void:
	if rooms.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 4242
	var cav: Dictionary = rooms[0]
	var c: Vector3 = cav.center
	var r: Vector3 = cav.radii
	# Try the side of the cavern facing away from the boss lair first, then fan out both ways.
	var first := rng.randf_range(0.0, TAU)
	var lair := lair_poi()
	if not lair.is_empty():
		var away: Vector3 = c - (lair.pos as Vector3)
		first = atan2(away.z, away.x)
	for attempt in 32:
		var k := (attempt + 1) / 2
		var ang := first + (k if attempt % 2 == 1 else -k) * TAU / 32.0
		var d := Vector3(cos(ang), 0.0, sin(ang))  # from the cavern center outward
		var reach := 1.0 / sqrt(pow(d.x / r.x, 2) + pow(d.z / r.z, 2))  # cavern radius this way
		var inside := c + d * reach * 0.7
		var fl := find_floor(inside.x, inside.z, c.y)
		if sdf_at(fl + Vector3.UP * 1.5) <= 0.0 or fl.y <= Y_MIN + 6.0:
			continue
		var tunnel_len := rng.randf_range(15.0, 20.0)
		var floor_y := fl.y + rng.randf_range(-0.5, 1.5)
		var room_c := Vector3(c.x, 0.0, c.z) + d * (reach + tunnel_len)
		room_c.y = floor_y + START_ROOM_R.y * 0.55
		var u := -d  # from the room toward the cavern
		var side := Vector3(-u.z, 0.0, u.x)
		var tr := START_TUNNEL_R
		var a0 := room_c + u * (START_ROOM_R.x + START_PLUG + tr)
		a0.y = floor_y + tr * 0.6
		var end := fl + Vector3.UP * (tr * 0.6)
		var m1 := a0.lerp(end, 0.4) + side * rng.randf_range(-2.5, 2.5)
		var m2 := a0.lerp(end, 0.75) + side * rng.randf_range(-2.0, 2.0)
		var plan := {
			room_c = room_c, dir = u, floor_y = floor_y,
			tunnel = [{a = a0, b = m1, r = tr}, {a = m1, b = m2, r = tr}, {a = m2, b = end, r = tr + 0.3}],
			hole_a = room_c + u * (START_ROOM_R.x - 0.8) + Vector3.UP * (floor_y + START_HOLE_Y - room_c.y),
			hole_b = room_c + u * (START_ROOM_R.x + START_PLUG + 0.8) + Vector3.UP * (floor_y + START_HOLE_Y - room_c.y),
			plug_a = room_c + u * (START_ROOM_R.x - 0.6),
			plug_b = room_c + u * (START_ROOM_R.x + START_PLUG + 0.4),
		}
		if not _start_fits(plan):
			continue
		var lo := room_c - START_ROOM_R - Vector3.ONE * 3.0
		var hi := room_c + START_ROOM_R + Vector3.ONE * 3.0
		for s in plan.tunnel:
			lo = lo.min(s.a.min(s.b) - Vector3.ONE * (s.r + 3.0))
			hi = hi.max(s.a.max(s.b) + Vector3.ONE * (s.r + 3.0))
		plan.min = lo
		plan.max = hi
		start = plan
		_place_start_things(rng)
		return


## The room, wall and most of the tunnel must sit in solid rock, away from every other cave
## (so nothing else breaks into the room), and inside the world.
func _start_fits(plan: Dictionary) -> bool:
	var rc: Vector3 = plan.room_c
	var checks: Array[Vector3] = []
	for x in [-1.0, 0.0, 1.0]:
		for y in [-1.0, 0.0, 1.0]:
			for z in [-1.0, 0.0, 1.0]:
				checks.append(rc + Vector3(x, y, z) * (START_ROOM_R + Vector3.ONE * 2.5))
	checks.append(plan.plug_a)
	checks.append(plan.plug_b)
	var t0: Dictionary = plan.tunnel[0]
	var t2: Dictionary = plan.tunnel[2]
	for k in 8:
		var t := float(k) / 8.0
		# Only the first part: the far end is meant to open into the cavern.
		var p: Vector3 = (t0.a as Vector3).lerp(t2.b, t * 0.4)
		var side := Vector3(-(plan.dir as Vector3).z, 0.0, (plan.dir as Vector3).x)
		checks.append(p + side * 3.0)
		checks.append(p - side * 3.0)
		checks.append(p + Vector3.UP * 3.0)
	for p in checks:
		if sdf_at(p) > -1.0 or _region_dist(p) < 4.0:
			return false
	return true


func _place_start_things(rng: RandomNumberGenerator) -> void:
	var rc: Vector3 = start.room_c
	var u: Vector3 = start.dir
	var side := Vector3(-u.z, 0.0, u.x)
	var fy: float = start.floor_y
	# You wake at the back of the room, facing the peephole.
	start.spawn = Vector3(rc.x, fy, rc.z) - u * 1.3 + Vector3.UP * 1.0
	# Loose rocks and one small crystal on the floor (feedback F11).
	# Scattered toward the front of the room, never right under your feet (you walk over to them).
	var loose: Array[Vector3] = []
	var wake: Vector3 = start.spawn
	var tries := 0
	while loose.size() < 7 and tries < 200:
		tries += 1
		var a := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(0.6, 2.3)
		var p := rc + Vector3(cos(a), 0.0, sin(a)) * dist
		if Vector2(p.x - wake.x, p.z - wake.z).length() < 2.2:
			continue
		var ok := true
		for q in loose:
			if Vector2(p.x - q.x, p.z - q.z).length() < 0.6:
				ok = false
		if ok:
			loose.append(Vector3(p.x, fy + 0.25, p.z))
	start.loose = loose
	# Roots dangling from the ceiling (pull them by hand) and a couple of glowing mushrooms.
	var roots: Array[Vector3] = []
	for i in 3:
		var p := rc + side * (float(i) - 1.0) * 1.4 - u * 0.4
		roots.append(Vector3(p.x, rc.y + START_ROOM_R.y * 0.8, p.z))
	start.roots = roots
	start.caps = [Vector3(rc.x, fy, rc.z) + side * 2.2 - u * 1.6, Vector3(rc.x, fy, rc.z) - side * 2.3 + u * 0.6]
	# The glow you see through the peephole: crystals just past the wall.
	var t0: Dictionary = start.tunnel[0]
	var a0: Vector3 = t0.a
	start.tunnel_glow = [a0 + u * 1.2 + side * 1.4 + Vector3.UP * 0.4, a0 + u * 2.5 - side * 1.3 + Vector3.UP * 0.9,
		a0 + Vector3.UP * 1.3]


## Distance to the start's open air (negative = inside the air).
func _start_dist(p: Vector3) -> float:
	var rc: Vector3 = start.room_c
	var q := (p - rc) / START_ROOM_R
	var d := (q.length() - 1.0) * minf(START_ROOM_R.x, minf(START_ROOM_R.y, START_ROOM_R.z))
	d = maxf(d, (rc.y - START_ROOM_R.y * 0.55) - p.y)  # flat floor
	var t := 1e9
	for s in start.tunnel:
		t = _smin(t, _capsule_dist(p, s.a, s.b, s.r, true), 1.0)
	# (No real hole in the wall: with 1 m blocks it would either close up or be big enough
	# to squeeze through. The Peephole node draws a glowing crack instead.)
	return minf(d, t)


static func _capsule_dist(p: Vector3, a: Vector3, b: Vector3, r: float, flat_floor: bool) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var cp := a + ab * t
	var d := p.distance_to(cp) - r
	return maxf(d, (cp.y - r * 0.6) - p.y) if flat_floor else d


func _near_start(p: Vector3) -> bool:
	if start.is_empty():
		return false
	var mn: Vector3 = start.min
	var mx: Vector3 = start.max
	return p.x >= mn.x and p.y >= mn.y and p.z >= mn.z and p.x <= mx.x and p.y <= mx.y and p.z <= mx.z


func _start_overlaps(lo: Vector3, hi: Vector3) -> bool:
	return not start.is_empty() and _overlaps(lo, hi, start.min, start.max)


## The soft dirt wall between the room and the tunnel (1 hit with a stone pickaxe).
func in_start_plug(p: Vector3) -> bool:
	if start.is_empty():
		return false
	var a: Vector3 = start.plug_a
	var b: Vector3 = start.plug_b
	var ab := b - a
	var t := (p - a).dot(ab) / ab.length_squared()
	if t < 0.0 or t > 1.0:
		return false
	return p.distance_to(a + ab * t) < 3.0


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


func _place_rooms(rng: RandomNumberGenerator, big_count: int, small_count: int, cx: float, biome: String) -> void:
	var r0 := rooms.size()
	# Big caverns: spread far apart so there's a journey between them.
	var tries := 0
	while _count_big(r0) < big_count and tries < 500:
		tries += 1
		var c := Vector3(cx + rng.randf_range(-140, 140), rng.randf_range(-38, -18), rng.randf_range(-140, 140))
		var r := Vector3(rng.randf_range(24, 34), rng.randf_range(10, 14), rng.randf_range(24, 34))
		if _far_from_rooms(c, 120.0 if tries < 300 else 70.0):
			rooms.append({center = c, radii = r, big = true, kind = "cavern", sealed = false, biome = biome})
	# Small chambers: little rooms along the way.
	tries = 0
	while rooms.size() - r0 < big_count + small_count and tries < 1000:
		tries += 1
		var c := Vector3(cx + rng.randf_range(-170, 170), rng.randf_range(-54, -2), rng.randf_range(-170, 170))
		var r := Vector3(rng.randf_range(7, 12), rng.randf_range(5, 7), rng.randf_range(7, 12))
		if _far_from_rooms(c, 45.0):
			rooms.append({center = c, radii = r, big = false, kind = "room", sealed = false, biome = biome})


func _count_big(r0: int) -> int:
	var n := 0
	for i in range(r0, rooms.size()):
		if rooms[i].big:
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
func _connect_rooms(rng: RandomNumberGenerator, r0: int, cx: float) -> void:
	var n := rooms.size()
	if n <= r0:
		return
	var in_tree := {r0: true}
	var edges: Array[Vector2i] = []
	while in_tree.size() < n - r0:
		var best := Vector2i(-1, -1)
		var best_d := INF
		for i in in_tree:
			for j in range(r0, n):
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
		var i := rng.randi_range(r0, n - 1)
		var j := rng.randi_range(r0, n - 1)
		if i != j:
			edges.append(Vector2i(i, j))
	for e in edges:
		_dig_worm(rng, rooms[e.x].center, rooms[e.y].center, cx)
	# Dead ends.
	for k in 4:
		var start: Vector3 = rooms[rng.randi_range(r0, n - 1)].center
		var angle := rng.randf_range(0, TAU)
		var end := start + Vector3(cos(angle), rng.randf_range(-0.3, 0.3), sin(angle)) * rng.randf_range(40, 80)
		_dig_worm(rng, start, _clamp_inside(end, cx), cx)


## Two gate tunnels through the Mossy/Fungal slab (world doc 1.3). Each side's tunnel stops
## 2 m before the middle, leaving a 4 m plug of border rock.
func _dig_gates(rng: RandomNumberGenerator, fungal_r0: int) -> void:
	var tries := 0
	while gates.size() < 2 and tries < 100:
		tries += 1
		var gz := rng.randf_range(-150, 150)
		var gy := rng.randf_range(-40, -12)
		if gates.size() == 1 and absf(gates[0].pos.z - gz) < 90.0:
			continue
		var mid := Vector3(SLAB_X + SLAB_W * 0.5, gy, gz)
		var west_end := Vector3(mid.x - PLUG * 0.5, gy, gz)
		var east_end := Vector3(mid.x + PLUG * 0.5, gy, gz)
		_dig_worm(rng, _nearest_room(mid, 0, fungal_r0), Vector3(BIOMES[0].cx + 185.0, gy, gz), BIOMES[0].cx)
		segments.append({a = Vector3(BIOMES[0].cx + 185.0, gy, gz), b = west_end, r = 3.4})
		_dig_worm(rng, _nearest_room(mid, fungal_r0, rooms.size()), Vector3(BIOMES[1].cx - 185.0, gy, gz), BIOMES[1].cx)
		segments.append({a = Vector3(BIOMES[1].cx - 185.0, gy, gz), b = east_end, r = 3.4})
		# The stubs' box reaches 6 m into each biome so there's no paper-thin wall where they meet.
		var half := Vector3(6.0, 5.5, 5.5)
		gates.append({pos = mid, min = Vector3(SLAB_X, gy, gz) - half, max = Vector3(SLAB_X + SLAB_W, gy, gz) + half})
		# A carved sign on each face of the plug, so you know what this wall is.
		_poi_biome = "mossy"
		_add_poi("gate", west_end + Vector3(-0.05, -0.6, 0), Vector3.LEFT, -1)
		_poi_biome = "fungal"
		_add_poi("gate", east_end + Vector3(0.05, -0.6, 0), Vector3.RIGHT, -1)
	_gate_min.clear()
	_gate_max.clear()
	for g in gates:
		_gate_min.append(g.min)
		_gate_max.append(g.max)


func _nearest_room(p: Vector3, r0: int, r1: int) -> Vector3:
	var best := p
	var best_d := INF
	for i in range(r0, r1):
		if rooms[i].sealed:
			continue
		var d: float = rooms[i].center.distance_to(p)
		if d < best_d:
			best_d = d
			best = rooms[i].center
	return best


## A wandering tunnel from a to b, made of short tubes.
func _dig_worm(rng: RandomNumberGenerator, a: Vector3, b: Vector3, cx: float) -> void:
	const STEP := 6.0
	var pos := a
	var guard := 0
	while pos.distance_to(b) > STEP and guard < 300:
		guard += 1
		var dir := (b - pos).normalized()
		var wander := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1))
		dir = (dir + wander * 0.65).normalized()
		dir.y = clampf(dir.y, -0.42, 0.42)  # keep slopes walkable for a dwarf
		var next := _clamp_inside(pos + dir.normalized() * STEP, cx)
		segments.append({a = pos, b = next, r = rng.randf_range(2.3, 3.3)})
		pos = next
	segments.append({a = pos, b = b, r = rng.randf_range(2.3, 3.3)})


func _clamp_inside(p: Vector3, cx: float) -> Vector3:
	const M := 185.0
	return Vector3(clampf(p.x, cx - M, cx + M), clampf(p.y, Y_MIN + 8.0, Y_MAX - 8.0), clampf(p.z, -M, M))


func _bake_shapes() -> void:
	for arr in [_room_c, _room_r, _room_min, _room_max, _seg_a, _seg_b, _seg_r, _seg_min, _seg_max]:
		arr.clear()
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
	_grid.clear()
	for i in _room_c.size():
		_grid_add(_room_min[i], _room_max[i], 0, i)
	for i in _seg_a.size():
		_grid_add(_seg_min[i], _seg_max[i], 1, i)


func _grid_add(mn: Vector3, mx: Vector3, which: int, id: int) -> void:
	var m := Vector3.ONE * CULL_MARGIN
	var a := Vector3i(((mn - m) / GRID).floor())
	var b := Vector3i(((mx + m) / GRID).floor())
	for x in range(a.x, b.x + 1):
		for y in range(a.y, b.y + 1):
			for z in range(a.z, b.z + 1):
				var k := Vector3i(x, y, z)
				if not _grid.has(k):
					_grid[k] = [PackedInt32Array(), PackedInt32Array()]
				_grid[k][which].append(id)


func _find_spawn() -> Vector3:
	var c: Vector3 = rooms[0].center if not rooms.is_empty() else Vector3.ZERO
	return find_floor(c.x, c.z, c.y) + Vector3.UP * 1.0


## Walks down from (x, y_start, z) until it hits rock. Returns the point just above the rock.
func find_floor(x: float, z: float, y_start: float) -> Vector3:
	var y := y_start
	while y > Y_MIN and sdf_at(Vector3(x, y, z)) > 0.0:
		y -= 0.25
	return Vector3(x, y, z)


# ---------------------------------------------------------------- special places (POIs)

## Plans one biome's special places. r0..r1 = its rooms, s0..s1 = its tunnels, `spawn` = where
## players arrive (the start, or the gate), cx = the biome's center x.
func _plan_pois(rng: RandomNumberGenerator, r0: int, r1: int, s0: int, s1: int, spawn: Vector3, biome: String, cx: float) -> void:
	_poi_biome = biome
	if biome == "mossy":
		rooms[r0].kind = "spawn"
	var bigs := []
	for i in range(r0 + (1 if biome == "mossy" else 0), r1):
		if rooms[i].big:
			bigs.append(i)
	# Side-boss caverns (Mossy: Skerra's nest and Brask's hall; Fungal: the doc's three).
	var cavern_kinds: Array = ["nest_cavern", "great_hall"] if biome == "mossy" else ["silver_vault", "brood_hollow", "lantern_grove"]
	for k in mini(bigs.size(), cavern_kinds.size()):
		var bi: int = bigs[k]
		rooms[bi].kind = cavern_kinds[k]
		_add_poi(cavern_kinds[k], find_floor(rooms[bi].center.x, rooms[bi].center.z, rooms[bi].center.y), Vector3.UP, bi)
	# Small rooms: ruins, nests and camps (no nests within 60 m of the start).
	var smalls := []
	for i in range(r0, r1):
		if not rooms[i].big:
			smalls.append(i)
	smalls.sort_custom(func(a, b): return rooms[a].center.distance_to(spawn) > rooms[b].center.distance_to(spawn))
	var plan := ["ruin", "nest", "ruin", "camp", "nest", "ruin", "camp", "nest", "camp", "camp"]
	var k := 0
	for i in smalls:
		if k >= plan.size():
			break
		var t: String = plan[k]
		if t == "nest" and rooms[i].center.distance_to(spawn) < 60.0:
			t = "camp"
		rooms[i].kind = t
		_add_poi(t, find_floor(rooms[i].center.x, rooms[i].center.z, rooms[i].center.y), Vector3.UP, i)
		k += 1
	# The main boss lair: a sealed dome, 6+ m of rock all around, 150+ m from the start.
	for attempt in 600:
		var c := Vector3(cx + rng.randf_range(-165, 165), rng.randf_range(-40, -16), rng.randf_range(-165, 165))
		if c.distance_to(spawn) < 150.0:
			continue
		var r := Vector3(18, 9, 18)
		if _solid_around(c, r + Vector3.ONE * 6.0):
			rooms.append({center = c, radii = r, big = true, kind = "lair", sealed = true, biome = biome})
			_add_poi("lair", c - Vector3.UP * r.y * 0.55, Vector3.UP, rooms.size() - 1)
			break
	# Crystal geodes (sealed pockets near tunnels) and rune shrines (3 open alcoves, 2 sealed).
	var geodes := 0
	var shrines_open := 0
	var shrines_sealed := 0
	for attempt in 800:
		if geodes >= 6 and shrines_open >= 3 and shrines_sealed >= 2:
			break
		var sgi := rng.randi_range(s0, s1 - 1)
		var sg: Dictionary = segments[sgi]
		var mid: Vector3 = (sg.a + sg.b) * 0.5
		if mid.distance_to(spawn) < 25.0:
			continue
		var along: Vector3 = (sg.b - sg.a).normalized()
		var side := along.cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			continue
		side *= -1.0 if rng.randf() < 0.5 else 1.0
		if shrines_open < 3:
			var c: Vector3 = mid + side * (sg.r + 1.2)
			if _far_from_pois(c, 20.0):
				rooms.append({center = c, radii = Vector3(2.8, 2.8, 2.8), big = false, kind = "shrine", sealed = false, biome = biome})
				_add_poi("shrine", c, -side, rooms.size() - 1)
				shrines_open += 1
				continue
		var dist: float = sg.r + rng.randf_range(5.0, 8.0)
		var c := mid + side * dist
		if geodes < 6:
			# Pockets must be bigger than the wall bumpiness (2.2 m), or bumps could close them.
			var gr := rng.randf_range(3.0, 4.5)
			if _solid_around(c, Vector3.ONE * (gr + 2.5)) and _far_from_pois(c, 15.0):
				rooms.append({center = c, radii = Vector3(gr, gr * 0.9, gr), big = false, kind = "geode", sealed = true, biome = biome})
				_add_poi("geode", c, -side, rooms.size() - 1)
				geodes += 1
				continue
		if shrines_sealed < 2 and _solid_around(c, Vector3.ONE * 5.3) and _far_from_pois(c, 20.0):
			rooms.append({center = c, radii = Vector3(2.8, 2.8, 2.8), big = false, kind = "shrine", sealed = true, biome = biome})
			_add_poi("shrine", c, -side, rooms.size() - 1)
			shrines_sealed += 1
	_bake_shapes()
	_place_markings(rng, biome)


## The 3 wall markings (boss clues): one in the Great Hall, one in a ruin, one on a
## cavern wall near the start. Each ≥ 80 m from the lair and ≥ 60 m from the others (world doc 3.2).
func _place_markings(rng: RandomNumberGenerator, biome: String) -> void:
	var lair := lair_poi(biome)
	var candidates := []
	for kind in ["great_hall", "lantern_grove", "ruin", "spawn", "cavern", "nest_cavern", "silver_vault", "brood_hollow", "camp", "room"]:
		for i in rooms.size():
			if rooms[i].kind == kind and rooms[i].get("biome", "mossy") == biome:
				candidates.append(i)
	var placed := []
	for i in candidates:
		if placed.size() >= 3:
			break
		var room: Dictionary = rooms[i]
		for attempt in 16:
			var a := rng.randf_range(0, TAU)
			var start: Vector3 = room.center + Vector3.DOWN * room.radii.y * 0.25
			var hit := _march_wall(start, Vector3(cos(a), 0, sin(a)), 60.0)
			if hit == Vector3.INF:
				continue
			var n := _normal(hit)
			if absf(n.y) > 0.3:
				continue
			if not lair.is_empty() and hit.distance_to(lair.pos) < 80.0:
				break
			var ok := true
			for p in placed:
				if p.distance_to(hit) < 60.0:
					ok = false
			if not ok:
				break
			placed.append(hit)
			_add_poi("marking", hit + n * 0.05, n, i)
			break


func _add_poi(type: String, pos: Vector3, normal: Vector3, room: int) -> void:
	pois.append({id = pois.size(), type = type, pos = pos, normal = normal, room = room, biome = _poi_biome})


func _far_from_pois(p: Vector3, d: float) -> bool:
	for q in pois:
		if q.pos.distance_to(p) < d:
			return false
	return true


## True if a box of half-size `half` around `c` is rock everywhere we sample.
func _solid_around(c: Vector3, half: Vector3) -> bool:
	if _region_dist(c) < half.x + 4.0:
		return false
	for x in [-1.0, 0.0, 1.0]:
		for y in [-1.0, 0.0, 1.0]:
			for z in [-1.0, 0.0, 1.0]:
				if sdf_at(c + Vector3(x, y, z) * half) >= -0.5:
					return false
	return true


func _march_wall(start: Vector3, dir: Vector3, max_dist: float) -> Vector3:
	var t := 0.0
	while t < max_dist:
		var p := start + dir * t
		var d := sdf_at(p)
		if d < 0.05:
			return p
		t += maxf(d * 0.8, 0.2)
	return Vector3.INF


func _normal(p: Vector3) -> Vector3:
	const E := 0.4
	var g := Vector3(sdf_at(p + Vector3(E, 0, 0)) - sdf_at(p - Vector3(E, 0, 0)),
		sdf_at(p + Vector3(0, E, 0)) - sdf_at(p - Vector3(0, E, 0)),
		sdf_at(p + Vector3(0, 0, E)) - sdf_at(p - Vector3(0, 0, E)))
	return g.normalized() if g.length() > 0.0001 else Vector3.UP


## The three map circles the wall markings reveal (world doc 3.2): [center_xz, radius] ×3.
## 1st: 120 m circle with the lair inside (not in the middle), 2nd: 45 m inside the 1st, 3rd: exact.
func clue_circles(biome: String = "mossy") -> Array:
	var lair := lair_poi(biome)
	if lair.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 555 + (0 if biome == "mossy" else 1000)
	var L := Vector2(lair.pos.x, lair.pos.z)
	var c1 := L + _in_disc(rng, 60.0)
	var c2 := L
	for i in 50:
		c2 = L + _in_disc(rng, 22.5)
		if c2.distance_to(c1) + 45.0 <= 120.0:
			break
	return [[c1, 120.0], [c2, 45.0], [L, 6.0]]


static func _in_disc(rng: RandomNumberGenerator, r: float) -> Vector2:
	var a := rng.randf() * TAU
	return Vector2(cos(a), sin(a)) * r * sqrt(rng.randf())


func lair_poi(biome: String = "mossy") -> Dictionary:
	for p in pois:
		if p.type == "lair" and p.biome == biome:
			return p
	return {}


## Special places of one type ("" biome = all biomes).
func pois_of(type: String, biome: String = "") -> Array:
	return pois.filter(func(p): return p.type == type and (biome == "" or p.biome == biome))


## Which biome a spot is in (by its x position; the slab counts as Mossy's side up to its middle).
static func biome_at(p: Vector3) -> String:
	return "fungal" if p.x >= SLAB_X + SLAB_W * 0.5 else "mossy"


# ---------------------------------------------------------------- queries

## Signed distance: positive = open air, negative = inside rock.
func sdf_at(p: Vector3) -> float:
	var cell = _grid.get(Vector3i((p / GRID).floor()))
	if cell == null:
		var s := minf(SOLID_FILL, _region_dist(p))  # no cave within 6 m: solid rock (like generate_block)
		if _near_start(p):
			s = minf(maxf(s, -_start_dist(p)), _region_dist(p))
		return s
	return _sdf_with(p, cell[0], cell[1])


## What rock is at p (only meaningful inside rock).
func material_at(p: Vector3i) -> int:
	var pf := Vector3(p)
	var wall := _wall_rock(pf)
	if wall >= 0:
		return wall
	if in_start_plug(pf):
		return Mat.DIRT
	var pal: Dictionary = Mat.PALETTES[biome_at(pf)]
	if _is_ore(p):
		return pal.ore
	var s := sdf_at(pf)
	if sdf_at(pf + Vector3.UP) > 0.0:
		return pal.floor
	if sdf_at(pf + Vector3.UP * 2.0) > 0.0:
		return pal.under
	if s > -3.0 and _is_patch(pf, pal.patch):
		return pal.patch
	if s > -2.5 and _dirt_noise.get_noise_3dv(pf) > 0.35:
		return pal.under
	return pal.rock


## Edge or border rock at p, or -1 if p is inside a biome (or an open gate stub).
func _wall_rock(p: Vector3) -> int:
	if _region_dist(p) >= 0.0:
		return -1
	if p.x < X_MIN or p.x > X_MAX or absf(p.z) > HALF_SIZE or p.y < Y_MIN or p.y > Y_MAX:
		return Mat.EDGE
	return Mat.BORDER


func _sdf_with(p: Vector3, room_ids: PackedInt32Array, seg_ids: PackedInt32Array) -> float:
	var d := 1e9
	for i in room_ids:
		d = _smin(d, _room_dist(p, i), BLEND)
	for i in seg_ids:
		d = _smin(d, _seg_dist(p, i), BLEND)
	var s := -d + _wall_noise.get_noise_3dv(p) * WALL_NOISE_AMP
	if _near_start(p):
		s = maxf(s, -_start_dist(p))
	return minf(s, _region_dist(p))


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


## How far inside the open part of the world p is: inside a biome box or a gate stub.
## Negative = in border or edge rock.
func _region_dist(p: Vector3) -> float:
	var d := -1e9
	for b in BIOMES:
		d = maxf(d, minf(minf(HALF_SIZE - absf(p.x - b.cx), HALF_SIZE - absf(p.z)), minf(p.y - Y_MIN, Y_MAX - p.y)))
	for i in _gate_min.size():
		d = maxf(d, _gate_dist(p, i))
	return d


## Inside the gate stubs = the gate's box minus the plug in the middle.
func _gate_dist(p: Vector3, i: int) -> float:
	var mn := _gate_min[i]
	var mx := _gate_max[i]
	var box := minf(minf(minf(p.x - mn.x, mx.x - p.x), minf(p.y - mn.y, mx.y - p.y)), minf(p.z - mn.z, mx.z - p.z))
	var plug_half := PLUG * 0.5
	var from_plug := absf(p.x - (mn.x + mx.x) * 0.5) - plug_half
	return minf(box, from_plug)


static func _smin(a: float, b: float, k: float) -> float:
	var h := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


## Clay: soft orange patches in the lower parts of the cave (doc: "stream banks").
func _is_clay(p: Vector3) -> bool:
	return _dirt_noise.get_noise_3d(p.x * 0.6 + 500.0, p.y * 0.6, p.z * 0.6) < -0.32 and p.y < -8.0


## Patches of the biome's soft rock: clay low in Mossy, amberrock bands anywhere in the Jungle.
func _is_patch(p: Vector3, patch: int) -> bool:
	if patch == Mat.CLAY:
		return _is_clay(p)
	return _dirt_noise.get_noise_3d(p.x * 0.6 + 500.0, p.y * 1.4, p.z * 0.6) < -0.3


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
	var touches_border := not _block_inside_a_biome(bmin, bmax)
	var mid := biome_at(bmin)
	var one_biome := biome_at(bmax) == mid
	var pal: Dictionary = Mat.PALETTES[mid]

	var near_start := _start_overlaps(lo, hi)
	if room_ids.is_empty() and seg_ids.is_empty() and one_biome and not near_start:
		# Solid rock block: fast path.
		buf.fill_f(SOLID_FILL, SDF)
		buf.fill(pal.rock, IDX)
		_fill_ore(buf, origin, size, pal.ore)
		if touches_border:
			_fill_border(buf, origin, size)
		return

	# Block near caves: compute every voxel. One extra layer on top lets us find floors.
	var fungal: Dictionary = Mat.PALETTES.fungal
	var mossy: Dictionary = Mat.PALETTES.mossy
	var split_x := SLAB_X + SLAB_W * 0.5
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
			if not one_biome:
				pal = fungal if origin.x + x >= split_x else mossy
			var p_rock: int = pal.rock
			var p_floor: int = pal.floor
			var p_under: int = pal.under
			var p_ore: int = pal.ore
			var p_patch: int = pal.patch
			for y in sy:
				var s := grid[base + y]
				buf.set_voxel_f(s, x, y, z, SDF)
				if s > 0.0:
					buf.set_voxel(p_rock, x, y, z, IDX)  # air: material unused
					continue
				var pi := Vector3i(origin.x + x, origin.y + y, origin.z + z)
				var m: int = p_rock
				var wall := _wall_rock(Vector3(pi)) if touches_border else -1
				if wall >= 0:
					m = wall
				elif near_start and in_start_plug(Vector3(pi)):
					m = Mat.DIRT
				elif _is_ore(pi):
					m = p_ore
				elif grid[base + y + 1] > 0.0:
					m = p_floor
				elif grid[base + y + 2] > 0.0:
					m = p_under
				elif s > -3.0 and _is_patch(Vector3(pi), p_patch):
					m = p_patch
				elif s > -2.5 and _dirt_noise.get_noise_3dv(Vector3(pi)) > 0.35:
					m = p_under
				buf.set_voxel(m, x, y, z, IDX)
			gi += col


func _block_inside_a_biome(bmin: Vector3, bmax: Vector3) -> bool:
	if bmin.y < Y_MIN or bmax.y > Y_MAX or bmin.z < -HALF_SIZE or bmax.z > HALF_SIZE:
		return false
	for b in BIOMES:
		if bmin.x >= b.cx - HALF_SIZE and bmax.x <= b.cx + HALF_SIZE:
			return true
	return false


func _fill_ore(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, ore: int) -> void:
	for cz in range(0, size.z, ORE_CELL):
		for cx in range(0, size.x, ORE_CELL):
			for cy in range(0, size.y, ORE_CELL):
				var p := origin + Vector3i(cx, cy, cz)
				if _is_ore(p):
					var mn := Vector3i(cx, cy, cz)
					buf.fill_area(ore, mn, (mn + Vector3i.ONE * ORE_CELL).min(size), VoxelBuffer.CHANNEL_INDICES)


func _fill_border(buf: VoxelBuffer, origin: Vector3i, size: Vector3i) -> void:
	for z in size.z:
		for x in size.x:
			for y in size.y:
				var wall := _wall_rock(Vector3(origin + Vector3i(x, y, z)))
				if wall >= 0:
					buf.set_voxel(wall, x, y, z, VoxelBuffer.CHANNEL_INDICES)


static func _overlaps(amin: Vector3, amax: Vector3, bmin: Vector3, bmax: Vector3) -> bool:
	return amin.x <= bmax.x and amax.x >= bmin.x and amin.y <= bmax.y and amax.y >= bmin.y \
		and amin.z <= bmax.z and amax.z >= bmin.z
