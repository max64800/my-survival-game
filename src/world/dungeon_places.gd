class_name DungeonPlaces
## Where the 12 Zone 1 dungeons (DungeonList) sit in a world (owner, Nov 20, F237). Only the world seed (through its
## CaveMaker) decides, so every computer gets the same answer. Each dungeon is a round patch of solid rock next to a
## Mossy Hollows tunnel: its door opens onto that tunnel. Rings from the start: small 40-100 m, medium 100-170 m,
## big 170 m+, at least 40 m apart. The placement rule (owner, Nov 17): never in a cave, a place, the watchtower's or
## the Fallen Outpost's ground, a stone column or a path (the solid-rock check keeps tunnels out).
## Mossgate Hold is placed by its own code on the PC: pass its spot in and the others keep clear of it.

## Per size: how wide (radius, m), how deep below the door and how high above it the dungeon may dig.
const FOOT := {
	small = {r = 16.0, down = 12.0, up = 7.0},
	medium = {r = 22.0, down = 14.0, up = 7.0},
	big = {r = 28.0, down = 20.0, up = 7.0},
}
const APART := 40.0  ## centre to centre, and never closer than the two patches plus this gap's first 6 m
const GAP := 6.0
const POI_CLEAR := 10.0  ## a place's spot stays this far outside a dungeon
const TRIES := 900


## [{id, size, pos (the door's floor), door_dir (from the dungeon toward its tunnel), turn (quarter turns, the door
## side), r}], in DungeonList order. A dungeon that found no spot is {} (the robot check catches it).
## `mossgate`: Mossgate Hold's own spot from the PC ({pos, ...}); kept as it is, and the others keep clear of it.
static func pick(maker: CaveMaker, mossgate: Dictionary = {}) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 2370  # its own dice, so nothing else in the world moves
	var start := maker.spawn_point
	var placed := {}  # id -> place
	if not mossgate.is_empty():
		placed["mossgate_hold"] = mossgate.merged({id = "mossgate_hold", size = "small", r = FOOT.small.r})
	# The big ones first: they need the most room.
	for size in ["big", "medium", "small"]:
		for d in DungeonList.LIST:
			if d.size == size and not placed.has(d.id):
				placed[d.id] = _find(maker, rng, d, start, placed.values())
	var out: Array[Dictionary] = []
	for d in DungeonList.LIST:
		out.append(placed[d.id])
	return out


## Keep each dungeon's patch clear of pebbles, plants and crystals (CaveMaker.reserve: the placement rule).
static func reserve_all(maker: CaveMaker, places: Array[Dictionary]) -> void:
	for p in places:
		if not p.is_empty():
			var f: Dictionary = FOOT[p.size]
			maker.reserve(middle(p) - Vector3(0, f.down, 0), f.r, f.down + f.up)


static func _find(maker: CaveMaker, rng: RandomNumberGenerator, d: Dictionary, start: Vector3, others: Array) -> Dictionary:
	var f: Dictionary = FOOT[d.size]
	var ring: Array = DungeonList.SIZES[d.size].ring
	var x_max: float = CaveMaker.SLAB_X - f.r - 10.0  # Mossy Hollows only (west of the border slab)
	var lim: float = CaveMaker.HALF_SIZE - f.r - 10.0
	var near: Array[Dictionary] = []  # only tunnels around the ring, so the tries aren't wasted far away
	for sg in maker.segments:
		var m: Vector3 = (sg.a + sg.b) * 0.5
		var md := Vector2(m.x - start.x, m.z - start.z).length()
		if md > ring[0] - f.r - 20.0 and md < ring[1] + 20.0 and m.x < x_max:
			near.append(sg)
	if near.is_empty():
		return {}
	for t in TRIES:
		var sg: Dictionary = near[rng.randi() % near.size()]
		var on: Vector3 = sg.a.lerp(sg.b, rng.randf())
		var along: Vector3 = sg.b - sg.a
		along.y = 0.0
		if along.length() < 0.5:
			continue
		var side := along.normalized().cross(Vector3.UP) * (1.0 if rng.randf() < 0.5 else -1.0)
		var door := maker.find_floor(on.x + side.x * sg.r * 0.7, on.z + side.z * sg.r * 0.7, on.y)
		if maker.sdf_at(door + Vector3.UP * 1.0) <= 0.0:
			continue  # (rock there, not the tunnel's floor)
		var mid: Vector3 = door + side * (f.r + 3.0)
		var dist := Vector2(mid.x - start.x, mid.z - start.z).length()
		if dist < ring[0] or dist > ring[1] or mid.x > x_max or absf(mid.x) > lim or absf(mid.z) > lim:
			continue
		if door.y - f.down < CaveMaker.Y_MIN + 4.0 or door.y + f.up > CaveMaker.Y_MAX - 2.0:
			continue
		var place := {id = d.id, size = d.size, pos = door, door_dir = -side, turn = posmod(roundi(atan2(-side.x, -side.z) / (PI / 2.0)), 4), r = f.r}
		if _clear(maker, place, mid, others) and _solid(maker, mid, door.y, f):
			return place
	return {}


static func middle(p: Dictionary) -> Vector3:
	return Vector3( p.pos) - p.get("door_dir", Vector3.ZERO) * (float(p.r) + 3.0)


## Far enough from the other dungeons, the places, the kept-clear ground and the stone columns.
static func _clear(maker: CaveMaker, place: Dictionary, mid: Vector3, others: Array) -> bool:
	var r: float = place.r
	for o in others:
		if o.is_empty():
			continue
		var gap := maxf(APART, r + float(o.r) + GAP)
		if _flat(mid).distance_to(_flat(middle(o))) < gap:
			return false
	for q in maker.pois:
		if _flat(mid).distance_to(_flat(q.pos)) < r + POI_CLEAR or _flat(place.pos).distance_to(_flat(q.pos)) < POI_CLEAR:
			return false
	for z in maker.reserved:
		if _flat(mid).distance_to(_flat(z.pos)) < r + float(z.r) + GAP:
			return false
	return not maker._in_column(mid, r + GAP) and not maker._in_column(place.pos, GAP)


## Every sample in the dungeon's round patch, from `down` below the door to `up` above it, is solid rock (no cave or
## tunnel inside), except the last metres by the door, where it opens onto its tunnel.
static func _solid(maker: CaveMaker, mid: Vector3, door_y: float, f: Dictionary) -> bool:
	var r: float = f.r
	var y: float = door_y - f.down
	while y <= door_y + f.up:
		for ring in [0.0, 0.5, 0.92]:
			var n := 1 if ring == 0.0 else (8 if ring == 0.5 else 14)
			for k in n:
				var a := k * TAU / n
				if maker.sdf_at(Vector3(mid.x + cos(a) * r * ring, y, mid.z + sin(a) * r * ring)) > -0.5:
					return false
		y += 4.0
	return true


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
