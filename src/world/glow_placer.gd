class_name GlowPlacer
## Glow Placer: picks spots on cave walls for glowing crystals (walls and ceilings)
## and glowing mushrooms (floors). Same seed = same spots, so every co-op player
## sees the same crystals, and each spot has an id the host can refer to.
##
## How: shoot pretend rays from inside each room/tunnel until they hit rock
## (using the Cave Maker's distance numbers), then sit a crystal or mushroom there.

const CRYSTAL := "crystal"
const MUSHROOM := "mushroom"
const MIN_SPACING := 2.5

## Returns an Array of {id, pos, normal, kind, color}.
static func place(maker: CaveMaker) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 777
	var spots: Array[Dictionary] = []
	for room in maker.rooms:
		var count := 60 if room.big else 12
		for i in count:
			var dir := _random_dir(rng)
			if i % 3 == 0:
				dir.y = -absf(dir.y) - 0.6  # every third ray aims at the floor (mushrooms)
			_try_add(maker, rng, spots, room.center, dir.normalized(), 70.0)
	for i in range(0, maker.segments.size(), 2):
		var s: Dictionary = maker.segments[i]
		var mid: Vector3 = (s.a + s.b) * 0.5
		_try_add(maker, rng, spots, mid, _random_dir(rng), 12.0)
	for i in spots.size():
		spots[i].id = i
	return spots


static func _random_dir(rng: RandomNumberGenerator) -> Vector3:
	var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	return v.normalized() if v.length() > 0.01 else Vector3.UP


static func _try_add(maker: CaveMaker, rng: RandomNumberGenerator, spots: Array[Dictionary], start: Vector3, dir: Vector3, max_dist: float) -> void:
	if maker.sdf_at(start) <= 0.0:
		return
	var hit := _march(maker, start, dir, max_dist)
	if hit == Vector3.INF:
		return
	for s in spots:
		if s.pos.distance_to(hit) < MIN_SPACING:
			return
	var n := normal_at(maker, hit)
	var kind := MUSHROOM if n.y > 0.65 else CRYSTAL
	var color := Color(0.35, 0.75, 1.0) if kind == CRYSTAL else Color(0.25, 0.95, 0.85)
	if kind == CRYSTAL and rng.randf() < 0.15:
		color = Color(0.65, 0.45, 1.0)  # a few violet ones for variety
	spots.append({id = -1, pos = hit, normal = n, kind = kind, color = color, scale = rng.randf_range(0.7, 1.3) * (1.8 if kind == CRYSTAL else 1.0), spin = rng.randf_range(0, TAU)})


## Sphere tracing: jump forward by the distance to the nearest wall until we touch it.
static func _march(maker: CaveMaker, start: Vector3, dir: Vector3, max_dist: float) -> Vector3:
	var t := 0.0
	var p := start
	while t < max_dist:
		p = start + dir * t
		var d := maker.sdf_at(p)
		if d < 0.05:
			return p
		t += maxf(d * 0.8, 0.2)
	return Vector3.INF


## Points away from the rock, into the air.
static func normal_at(maker: CaveMaker, p: Vector3) -> Vector3:
	const E := 0.4
	var g := Vector3(
		maker.sdf_at(p + Vector3(E, 0, 0)) - maker.sdf_at(p - Vector3(E, 0, 0)),
		maker.sdf_at(p + Vector3(0, E, 0)) - maker.sdf_at(p - Vector3(0, E, 0)),
		maker.sdf_at(p + Vector3(0, 0, E)) - maker.sdf_at(p - Vector3(0, 0, E)))
	return g.normalized() if g.length() > 0.0001 else Vector3.UP
