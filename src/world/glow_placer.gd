class_name GlowPlacer
## Glow Placer: picks spots on cave surfaces for things you can harvest:
## glowing crystals (walls), hanging roots (ceilings, the first wood!), and mushrooms
## and fiber tufts (floors). Same seed = same spots, so every co-op player sees the
## same things, and each spot has an id the host can refer to.
##
## How: shoot pretend rays from inside each room/tunnel until they hit rock
## (using the Cave Maker's distance numbers), then put something there.

const CRYSTAL := "crystal"
const MUSHROOM := "glowcap"  ## the glowing blue mushroom
const ROOT := "root"
const MIN_SPACING := 2.5

## What each kind is. tool: "hand" (anything, even bare hands), "pickaxe", or "axe"
## (axe at full power, pickaxe at half). hardness uses the ×10 dig scale.
## chops: a root can be chopped through this many times before it's gone.
const KINDS := {
	"crystal": {item = "crystal_blue", count = [2, 4], tool = "pickaxe", hardness = 18, glow = true, color = Color(0.35, 0.75, 1.0), xp = 4, skill = "mining"},
	"crystal_green": {item = "crystal_green", count = [2, 4], tool = "pickaxe", hardness = 18, glow = true, color = Color(0.35, 1.0, 0.5), xp = 4, skill = "mining"},
	"glowcap": {item = "glowcap", count = [1, 1], tool = "hand", glow = true, color = Color(0.25, 0.95, 0.85), xp = 1, skill = "survival"},
	"hollowcap": {item = "hollowcap", count = [1, 1], tool = "hand", color = Color(0.55, 0.38, 0.26), xp = 1, skill = "survival"},
	"bellcap": {item = "bellcap", count = [1, 1], tool = "hand", color = Color(0.55, 0.7, 1.0), xp = 1, skill = "survival"},
	"firecap": {item = "firecap", count = [1, 1], tool = "hand", glow = true, color = Color(1.0, 0.35, 0.2), xp = 1, skill = "survival"},
	"fiber": {item = "fiber", count = [2, 2], tool = "hand", color = Color(0.5, 0.65, 0.3), xp = 1, skill = "survival"},
	"root": {item = "rootwood", count = [3, 3], tool = "axe", hardness = 30, chops = 4, color = Color(0.42, 0.29, 0.18), xp = 3, skill = "survival"},
	# Fungal Jungle. Giant mushrooms are the jungle's wood: tall stalks that need a copper axe
	# (or copper pickaxe at half power), and each chop also drops some flesh.
	"giant_mushroom": {item = "mushroom_wood", count = [3, 3], extra = "mushroom_flesh", tool = "axe", hardness = 40, min_tier = 1, chops = 4, color = Color(0.72, 0.5, 0.78), xp = 4, skill = "survival"},
	"crystal_amber": {item = "crystal_amber", count = [2, 3], tool = "pickaxe", hardness = 22, glow = true, color = Color(1.0, 0.72, 0.28), xp = 5, skill = "mining"},
	"spore_truffle": {item = "spore_truffle", count = [1, 2], tool = "hand", color = Color(0.45, 0.33, 0.52), xp = 1, skill = "survival"},
	"ember_morel": {item = "ember_morel", count = [1, 1], tool = "hand", glow = true, color = Color(1.0, 0.45, 0.15), xp = 2, skill = "survival"},
}
const GIANT := "giant_mushroom"
## Kinds that stand tall (or hang long): their size is `length`, not `scale`.
const TALL := ["root", "giant_mushroom"]

static var _placed := {}  ## seed -> spots (copied out, because a GlowField changes its own copy)


## Returns an Array of {id, pos, normal, kind, color, scale, spin, length}.
static func place(maker: CaveMaker) -> Array[Dictionary]:
	if not _placed.has(maker.seed):
		_placed[maker.seed] = _place(maker)
	var out: Array[Dictionary] = []
	for s in _placed[maker.seed]:
		out.append(s.duplicate())
	return out


static func _place(maker: CaveMaker) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 777
	var spots: Array[Dictionary] = []
	# One biome after the other, so adding a biome never moves the spots of the ones before it.
	for biome in ["mossy", "fungal"]:
		for room in maker.rooms:
			if room.get("biome", "mossy") != biome:
				continue
			var count := 70 if room.big else 14
			for i in count:
				var dir := _random_dir(rng)
				if i % 3 == 0:
					dir.y = -absf(dir.y) - 0.6  # aim at the floor (mushrooms, fiber)
				elif i % 5 == 1:
					dir.y = absf(dir.y) + 0.8  # aim at the ceiling (roots)
				_try_add(maker, rng, spots, room.center, dir.normalized(), 70.0, biome)
		for i in range(0, maker.segments.size(), 2):
			var s: Dictionary = maker.segments[i]
			var mid: Vector3 = (s.a + s.b) * 0.5
			if CaveMaker.biome_at(mid) == biome:
				_try_add(maker, rng, spots, mid, _random_dir(rng), 12.0, biome)
	for i in spots.size():
		spots[i].id = i
	return spots


static func _random_dir(rng: RandomNumberGenerator) -> Vector3:
	var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	return v.normalized() if v.length() > 0.01 else Vector3.UP


static func _try_add(maker: CaveMaker, rng: RandomNumberGenerator, spots: Array[Dictionary], start: Vector3, dir: Vector3, max_dist: float, biome: String) -> void:
	if maker.sdf_at(start) <= 0.0:
		return
	var hit := _march(maker, start, dir, max_dist)
	if hit == Vector3.INF:
		return
	for s in spots:
		if s.pos.distance_to(hit) < MIN_SPACING:
			return
	var n := normal_at(maker, hit)
	var kind := _pick_kind(n, rng) if biome == "mossy" else _pick_fungal(n, rng)
	if kind == ROOT and maker.sdf_at(hit + Vector3.DOWN * 0.6) <= 0.3:
		kind = CRYSTAL  # too close to a wall to hang straight down here
	var length := 0.0
	if kind == ROOT:
		# Roots hang straight down toward the floor, ending about a dwarf's reach above it.
		n = Vector3.DOWN
		var below := _march(maker, hit + Vector3.DOWN * 0.6, Vector3.DOWN, 40.0)
		var gap := hit.distance_to(below) if below != Vector3.INF else 3.0
		length = maxf(gap - 1.6, 1.2)
	elif kind == GIANT:
		# Giant mushrooms stand straight up, 3-6 m tall, never touching the ceiling.
		n = Vector3.UP
		var above := _march(maker, hit + Vector3.UP * 0.5, Vector3.UP, 12.0)
		var room := hit.distance_to(above) if above != Vector3.INF else 12.0
		length = minf(rng.randf_range(3.0, 6.0), room - 1.2)
		if length < 2.5:
			kind = "spore_truffle"
			length = 0.0
	var scale := rng.randf_range(0.7, 1.3) * (1.8 if kind.begins_with("crystal") else 1.0)
	if kind in TALL:
		scale = 1.0  # stretched by `length` instead
	spots.append({id = -1, pos = hit, normal = n, kind = kind, color = KINDS[kind].color, scale = scale,
		spin = rng.randf_range(0, TAU), length = length, chops = KINDS[kind].get("chops", 1)})


static func _pick_kind(n: Vector3, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if n.y > 0.65:  # floor
		if r < 0.40: return "glowcap"
		if r < 0.58: return "hollowcap"
		if r < 0.70: return "bellcap"
		if r < 0.92: return "fiber"
		return "firecap"
	if n.y < -0.55 and r < 0.6:  # ceiling
		return ROOT
	return "crystal_green" if r > 0.88 else CRYSTAL


## Jungle choices. Wood comes from giant mushrooms on the floor instead of roots.
static func _pick_fungal(n: Vector3, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if n.y > 0.65:  # floor
		if r < 0.22: return GIANT
		if r < 0.45: return "spore_truffle"
		if r < 0.58: return "bellcap"
		if r < 0.78: return "fiber"
		if r < 0.88: return "ember_morel"
		return "hollowcap"
	if r < 0.3:
		return "crystal_amber"
	return "crystal_green" if r > 0.9 else CRYSTAL


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


static func is_plant(kind: String) -> bool:
	return KINDS.get(kind, {}).get("tool", "") == "hand"
