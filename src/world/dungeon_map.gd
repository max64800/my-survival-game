class_name DungeonMap
## Dungeons dug into solid rock (owner, Nov 19, 2026: docs/decisions/2026-11-19-dungeons.md).
## A dungeon is part of how the world is made: the Cave Maker picks a spot behind a cave wall and carves the
## dungeon's rooms into the rock, lined with old dwarf stone (Mat.DWARF) that no pickaxe breaks. Every computer
## makes the same dungeon from the same world number, so nothing has to be sent to friends (co-op ready).
##
## A map is a list of boxes in its own metres (the 2 m building grid): x to the right, z toward the cave you come
## in from, y up from the floor. The way in ("mouth") is at `mouth`; the entry tunnel runs out from there through
## the cave wall. Root wood walls stand on the box edges; the rock is cut GAP further out, behind them.

const SHELL := 3.0  ## metres of old dwarf stone round every room (you can't dig round a trap)
const GAP := 0.5    ## the rock stands this far behind the line the root wood walls stand on
## The round stone door stands FACE metres out from the map's mouth, at the end of the root wood corridor. From there
## to the cave a hole just smaller than the door's stone frame (DOOR_HOLE wide x high) runs through the rock, so the
## frame always covers its edges (owner, Nov 19: you could see the corridor and rock beside the frame).
const FACE := 4.0
const DOOR_HOLE := Vector2(2.8, 2.55)

## Map 1, "Mossgate Hold" (small, 84 x 56 m, the sketch the owner OK'd on Nov 19). Each space:
## [name, x0, z0, x1, z1, floor_y, height]. Rooms are numbered like the sketch.
const MOSSGATE := {
	id = "mossgate",
	name = "Mossgate Hold",
	mouth = Vector2(34, 56),  ## the middle of the way in, on the dungeon's outer face
	spaces = [
		["entry", 32, 44, 36, 56, 0, 3.5],           # the way in (it runs on out through the cave wall)
		["gate_hall", 26, 36, 42, 46, 0, 5],          # 1
		["dart_hall", 42, 38, 50, 42, 0, 3.5],        # 2
		["guard_room", 50, 34, 60, 46, 0, 5],         # 3
		["guard_store", 60, 38, 62, 42, 0, 3.5],
		["store_room", 62, 36, 70, 44, 0, 4.5],       # 4
		["vault_way", 64, 32, 66, 36, 0, 3],          # behind the cracked wall
		["vault", 62, 26, 68, 32, 0, 4.5],            # 5 (hidden)
		["rubble_tunnel", 18, 38, 26, 42, 0, 3.5],    # 6
		["tombs", 6, 34, 18, 46, 0, 4.5],             # 7
		["tombs_shrine", 10, 26, 14, 34, 0, 3.5],
		["shrine", 6, 16, 18, 26, 0, 4.5],            # 8
		["shrine_pillars", 18, 18, 24, 22, 0, 3.5],
		["gate_pillars", 32, 30, 36, 36, 0, 3.5],
		["pillar_hall", 24, 16, 46, 30, 0, 8],        # 9 (the tall one)
		["spike_pit", 36, 20, 42, 26, -4, 5],         # under the breaking floor (reaches 1 m up into the hall: no rock skin at 0)
		["pillar_chasm", 32, 12, 36, 16, 0, 3.5],
		["chasm_room", 24, 0, 46, 12, 0, 7],          # 10
		["chasm", 36, 0, 42, 12, -4, 11],             # the drop: 4 m onto spikes, like the spike pit (owner, Nov 20, 3rd play)
		["boulder_way", 46, 4, 50, 8, 0, 3],          # 11 the hidden boulder fills it (low, so it fills it)
		["crusher_hall", 50, 4, 56, 8, 0, 4.5],       # 12 the small hall before the Pack Hall's shut round door
		["pack_hall", 56, 0, 72, 18, 0, 6],           # 13 (the crushers hang just inside its door, owner Nov 20)
		["loot_door", 72, 8, 74, 12, 0, 3.5],
		["loot_room", 74, 4, 84, 16, 0, 4.5],         # 14
		["way_out_n", 76, 16, 80, 42, 0, 3.5],        # 15 the way out
		["way_out_w", 70, 38, 80, 42, 0, 3.5],
	],
}

const MAPS := [MOSSGATE]


## One placed dungeon: where its mouth is in the world, which way it faces, and its boxes in world terms.
## entry_out = how far the way in runs on past the dungeon's face (through the cave wall, into the cave).
static func place(map: Dictionary, mouth_world: Vector3, turn: int, entry_out: float) -> Dictionary:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var mouth: Vector2 = map.mouth
	var boxes: Array = []  # [local min, local max] with the GAP and the entry's run-out added
	var lo := Vector3.ONE * 1e9
	var hi := -Vector3.ONE * 1e9
	for s in map.spaces:
		var mn := Vector3(float(s[1]) - GAP, float(s[5]), float(s[2]) - GAP)
		var mx := Vector3(float(s[3]) + GAP, float(s[5]) + float(s[6]), float(s[4]) + GAP)
		if s[0] == "entry":
			mx.z = mouth.y + FACE  # the corridor ends at the round door, in solid rock
		boxes.append([mn, mx])
		lo = lo.min(mn)
		hi = hi.max(mx)
	# The door hole: from just behind the door's frame out into the cave (always the last box).
	var hmn := Vector3(mouth.x - DOOR_HOLE.x * 0.5, 0.0, mouth.y + FACE - 0.3)
	var hmx := Vector3(mouth.x + DOOR_HOLE.x * 0.5, DOOR_HOLE.y, mouth.y + entry_out)
	boxes.append([hmn, hmx])
	hi = hi.max(hmx)
	lo -= Vector3.ONE * SHELL
	hi += Vector3.ONE * SHELL
	# The world box round it all (for quick "nowhere near" answers).
	var wlo := Vector3.ONE * 1e9
	var whi := -Vector3.ONE * 1e9
	for cx in [lo.x, hi.x]:
		for cy in [lo.y, hi.y]:
			for cz in [lo.z, hi.z]:
				var w := mouth_world + basis * (Vector3(cx, cy, cz) - Vector3(mouth.x, 0.0, mouth.y))
				wlo = wlo.min(w)
				whi = whi.max(w)
	return {map = map, id = String(map.id), mouth = mouth_world, turn = turn, basis = basis, inv = basis.inverse(),
		boxes = boxes, lo = lo, hi = hi, wlo = wlo, whi = whi, entry_out = entry_out}


## Where the round door stands, in the map's own z.
static func mouth_z(map: Dictionary) -> float:
	return (map.mouth as Vector2).y + FACE


## A spot in the world -> the dungeon's own metres.
static func to_local(d: Dictionary, p: Vector3) -> Vector3:
	var mouth: Vector2 = d.map.mouth
	return (d.inv as Basis) * (p - (d.mouth as Vector3)) + Vector3(mouth.x, 0.0, mouth.y)


## The dungeon's own metres -> the world.
static func to_world(d: Dictionary, local: Vector3) -> Vector3:
	var mouth: Vector2 = d.map.mouth
	return (d.mouth as Vector3) + (d.basis as Basis) * (local - Vector3(mouth.x, 0.0, mouth.y))


static func near_box(d: Dictionary, p: Vector3, margin: float) -> bool:
	var wlo: Vector3 = d.wlo
	var whi: Vector3 = d.whi
	return p.x > wlo.x - margin and p.x < whi.x + margin and p.y > wlo.y - margin and p.y < whi.y + margin \
		and p.z > wlo.z - margin and p.z < whi.z + margin


## How far inside the dungeon's air p is (positive = in a room, negative = in rock; like the Cave Maker's numbers).
## Far away: a big negative number.
static func sdf(d: Dictionary, p: Vector3) -> float:
	if not near_box(d, p, 0.0):
		return -1e9
	var q := to_local(d, p)
	var best := -1e9
	for b in d.boxes:
		best = maxf(best, _box_in(q, b[0], b[1]))
	return best


## Is p on the dungeon's ground: in a room, in its walls, or within `margin` of them?
static func covers(d: Dictionary, p: Vector3, margin := 0.0) -> bool:
	return near_box(d, p, margin) and sdf(d, p) > -(SHELL + margin)


## The name of the space p is in ("" = none).
static func space_at(d: Dictionary, p: Vector3) -> String:
	if not near_box(d, p, 0.0):
		return ""
	var q := to_local(d, p)
	for i in d.boxes.size():
		if _box_in(q, d.boxes[i][0], d.boxes[i][1]) > 0.0:
			return String(d.map.spaces[i][0]) if i < d.map.spaces.size() else "entry"
	return ""


## The middle of a space's floor, in the world.
static func space_floor(d: Dictionary, space: String) -> Vector3:
	for s in d.map.spaces:
		if s[0] == space:
			return to_world(d, Vector3((float(s[1]) + float(s[3])) * 0.5, float(s[5]), (float(s[2]) + float(s[4])) * 0.5))
	return Vector3.INF


## Positive inside the box (how far to its nearest side), negative outside.
static func _box_in(q: Vector3, mn: Vector3, mx: Vector3) -> float:
	var c := (mn + mx) * 0.5
	var h := (mx - mn) * 0.5
	var e := Vector3(absf(q.x - c.x) - h.x, absf(q.y - c.y) - h.y, absf(q.z - c.z) - h.z)
	var outside := Vector3(maxf(e.x, 0.0), maxf(e.y, 0.0), maxf(e.z, 0.0)).length()
	var inside := minf(maxf(e.x, maxf(e.y, e.z)), 0.0)
	return -(outside + inside)


## Where a dungeon goes (the Cave Maker asks once, while making the world). Looks out of Mossy caverns 80-260 m from
## where you arrive (best near 150 m) for a cave wall with solid rock behind it, big enough for the whole map, kept
## away from built things, the start and the zone's border. Straight lines only (the 2 m grid): the dungeon faces
## one of the 4 ways. Returns place(...) or {} when nothing fits.
static func find_spot(maker: CaveMaker, map: Dictionary) -> Dictionary:
	var c0 := maker.cavern_spawn
	var tries: Array = []
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if rm.get("biome", "mossy") != "mossy":
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d < 80.0 or d > 260.0:
			continue
		for turn in 4:
			for side in [0.0, -10.0, 10.0]:
				tries.append([absf(d - 150.0) + absf(side) * 0.3 + turn * 0.01, i, turn, side])
	tries.sort_custom(func(a, b): return a[0] < b[0])
	for t in tries:
		for back in [0.0, 2.0, 4.0]:  # (a slanted cave wall: set it deeper into the rock, see _try)
			_side_open = false
			var spot := _try(maker, map, maker.rooms[t[1]], int(t[2]), float(t[3]), back)
			if not spot.is_empty():
				return spot
			if not _side_open:
				break
	return {}


static var _side_open := false  ## the last _try failed only because the cave is open beside the door


## `back`: metres further into the rock than usual (when the cave wall runs at a slant to the dungeon).
static func _try(maker: CaveMaker, map: Dictionary, rm: Dictionary, turn: int, side: float, back := 0.0) -> Dictionary:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var out := basis * Vector3(0, 0, 1)  # from the dungeon toward the cave
	var across := basis * Vector3(1, 0, 0)
	var c: Vector3 = rm.center
	var fl := maker.find_floor(c.x, c.z, c.y)
	if fl == Vector3.INF:
		return {}
	var start := Vector3(c.x, fl.y + 1.5, c.z) + across * side
	if maker._smooth_at(start) < 1.0:
		return {}
	# Walk from the room's middle into the rock (away from `out`) until the wall.
	var wall := Vector3.INF
	for k in 70:
		var p := start - out * float(k)
		if maker._smooth_at(p) < 0.0:
			wall = p
			break
	if wall == Vector3.INF:
		return {}
	# The cave floor just in front of the wall: the dungeon's floor is level with it.
	var front := wall + out * 2.5
	var ffl := maker.find_floor(front.x, front.z, front.y + 1.0)
	if ffl == Vector3.INF or absf(ffl.y - fl.y) > 3.0:
		return {}
	# The round door 1-3 m inside the rock (the wall is found to 1 m, the mouth then snaps to the 2 m grid).
	var mouth := wall - out * (FACE + 2.0 + back)
	mouth = Vector3(roundf(mouth.x / 2.0) * 2.0, roundf(ffl.y), roundf(mouth.z / 2.0) * 2.0)  # on the 2 m grid
	var entry_out := FACE + 2.0 + back + 3.0  # through the wall and about 3 m into the cave
	var d := place(map, mouth, turn, entry_out)
	# Its end must come out in the cave's air, and its start must be in rock.
	var tip := to_world(d, Vector3(map.mouth.x, 1.5, map.mouth.y + entry_out - 0.5))
	if maker._smooth_at(tip) < 0.5:
		return {}
	# No small sealed room (a geode) or place may sit in its walls: they are smaller than the 3 m check below.
	for other in maker.rooms:
		var rr: Vector3 = other.radii
		if other != rm and covers(d, other.center, maxf(rr.x, maxf(rr.y, rr.z)) + 1.0):
			return {}
	for p in maker.pois:
		if covers(d, p.pos, 2.0):
			return {}
	# The cave floor in front of the door stays open: no stone column or rock bridge in the way (owner, Nov 19: a
	# column stood right in front of the door). Checked 0-12 m out from where the way in comes out, 4 m to each side.
	for k in range(0, 13, 2):
		for s in [-4.0, 0.0, 4.0]:
			var q := to_world(d, Vector3(map.mouth.x + s, 1.0, map.mouth.y + entry_out + float(k)))
			if maker._in_column(q, 1.0) or maker.on_bridge(q, 1.0):
				return {}
			for p in maker.pois:  # (a row of old columns reaches 7.6 m from its middle)
				if Vector2(q.x - p.pos.x, q.z - p.pos.z).length() < 10.0 and absf(q.y - p.pos.y) < 8.0:
					return {}
	# The way in stays in rock up to its door (no cave air beside it: you'd see in round the door's frame).
	var e: Array = map.spaces[0]
	var ez := mouth_z(map) - 6.0
	while ez <= mouth_z(map) - 0.5:
		for ex in [float(e[1]) - GAP - 0.3, float(e[3]) + GAP + 0.3]:
			for ey in [0.5, 2.5]:
				if maker._smooth_at(to_world(d, Vector3(ex, ey, ez))) > 0.0:
					_side_open = true
					return {}
		ez += 1.0
	# Every room (and its stone round it) in solid rock, inside Mossy, off built ground and away from the start.
	for i in map.spaces.size():
		var s: Array = map.spaces[i]
		if s[0] == "entry":
			continue
		var mn: Vector3 = d.boxes[i][0] - Vector3.ONE * (SHELL + 1.0)
		var mx: Vector3 = d.boxes[i][1] + Vector3.ONE * (SHELL + 1.0)
		var x := mn.x
		while x <= mx.x + 0.01:
			var z := mn.z
			while z <= mx.z + 0.01:
				var y := mn.y
				while y <= mx.y + 0.01:
					var w := to_world(d, Vector3(x, y, z))
					if maker._smooth_at(w) > -0.5 or CaveMaker.biome_at(w) != "mossy" or maker._region_dist(w) < 4.0 \
							or maker.is_reserved(w, 4.0) or maker._near_start(w):
						return {}
					y += 3.0
				z += 3.0
			x += 3.0
	return d
