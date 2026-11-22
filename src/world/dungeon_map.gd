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
		["chasm", 36, 0, 44, 12, -4, 11],             # the drop: 4 m onto spikes, like the spike pit (owner, Nov 20, 3rd play)
		["boulder_way", 46, 4, 50, 8, 0, 3],          # 11 the hidden boulder fills it (low, so it fills it)
		["crusher_hall", 50, 4, 56, 8, 0, 4.5],       # 12 the small hall before the Pack Hall's shut round door
		["pack_hall", 56, 0, 72, 18, 0, 6],           # 13 (the crushers hang just inside its door, owner Nov 20)
		["loot_door", 72, 8, 74, 12, 0, 3.5],
		["loot_room", 74, 4, 84, 16, 0, 4.5],         # 14
		["way_out_n", 76, 16, 80, 42, 0, 3.5],        # 15 the way out
		["way_out_w", 70, 38, 80, 42, 0, 3.5],
	],
}

## Map 2, "Lampwick Drift" (small; docs/design/zone1-dungeons/02-lampwick-drift.md, owner Nov 20: "Dungeon 2 should be a
## new dungeon. We planned it."). A dark old mine: you light its lamps as you go. Two levels: the Lamp Room and the Rail
## Tunnel at 0, then the Cart Junction's rails climb 3 m (UP) to everything else; the Back Rails run down again to the
## Lamp Room's barred gate (the way out). Corridors are 4 m wide like Mossgate's (the round doorway needs 3 m).
## The short "_door" spaces join two rooms with a 4 m opening (a round doorway). In new worlds from layout 15 on.
const UP := 3.0
const LAMPWICK := {
	id = "lampwick",
	name = "Lampwick Drift",
	mouth = Vector2(26, 60),
	since = 15,     ## the first cave layout that has it (older worlds keep only Mossgate)
	best = 120.0,   ## metres from the start it likes best (Mossgate: 150)
	chase_out = true,  ## owner, Nov 20: a woken creature follows you out of its room (Monster.chases_out)
	spaces = [
		["entry", 24, 52, 28, 60, 0, 3.5],            # the way in
		["lamp_room", 22, 46, 28, 52, 0, 4.5],        # 1 (the barred gate on its east wall)
		["rail_tunnel", 24, 36, 28, 46, 0, 3.5],      # 2 (the tripwire)
		["rail_bend", 22, 34, 28, 38, 0, 3.5],        #   (the tunnel turns west into the junction's foot)
		["cart_junction", 16, 22, 22, 40, 0, 8],      # 3 three rails climbing 3 m north (z 33.6 -> 22), the carts
		                                              #   (its level foot runs on 2 m past the way in: owner, Nov 20,
		                                              #   a crashed cart blocked the doorway after you died)
		["junction_top", 16, 18, 22, 22, UP, 4.5],    #   the landing at the top of the rails
		["tool_store", 10, 16, 16, 22, UP, 4.5],      # 4 (the loose stone)
		["drip_tunnel", 18, 8, 22, 18, UP, 4.5],      # 5 (stalactites)
		["bat_gallery", 14, 0, 24, 8, UP, 7],         # 6 (tall and dark; the cracked wall on its west side)
		["vault", 10, 2, 14, 4, UP, 3],               # 7 (hidden: the trapped chest on its spike floor)
		["shaft_door", 24, 2, 26, 6, UP, 3.5],
		["old_shaft", 26, 0, 36, 8, UP, 6],           # 8 the plank walk (z 2-6) and the swinging boulder
		["shaft_n", 28, 0, 36, 2, UP - 6.0, 7],       #   the deep shaft each side of the walk (falling in kills)
		["shaft_s", 28, 6, 36, 8, UP - 6.0, 7],
		["copper_door", 36, 2, 38, 6, UP, 3.5],
		["copper_face", 38, 0, 44, 6, UP, 4.5],       # 9 (bear jaws in the rubble)
		["niche", 44, 2, 50, 6, UP, 3],               #   behind the hidden boulder (a chest)
		["prop_corridor", 40, 6, 44, 16, UP, 3.5],    # 10
		["rest_door", 38, 12, 40, 16, UP, 3.5],
		["miners_rest", 32, 10, 38, 16, UP, 4.5],     # 11 (the healing basin)
		["office_door", 40, 16, 44, 18, UP, 3.5],
		["office", 38, 18, 48, 28, UP, 5],            # 12 the Foreman's Office
		["back_rails", 40, 28, 44, 46, 0, 7],         # 13 two rails down 3 m south (z 28 -> 39.6), then level
		["back_rails_w", 28, 46, 44, 50, 0, 3.5],     #   west to the gate
	],
}

## Map 3, "Old Pell's Diggings" (small; docs/design/zone1-dungeons/03-old-pells-diggings.md, owner Nov 20: "start
## working on dung 3", no 3D page, the Foreman again as the boss). A miner's hut at the cave's level, then a ladder
## shaft 6 m DOWN to what Pell dug out below; the way out is a lift shaft from Pell's Last Dig up behind the hut's
## barred gate. "shaft" and "lift" are the two 2 x 2 m holes joining the levels (a ladder in each). Only the spaces in
## `deadly` kill you when you fall in (the lower level is under 0 too). In new worlds from layout 16 on.
const DOWN := -6.0
const PELL := {
	id = "pell",
	name = "Old Pell's Diggings",
	mouth = Vector2(36, 60),
	since = 16,
	best = 100.0,
	chase_out = true,
	deadly = ["spike_pit"],
	crushers_always = true,  ## the Deep Seam's crushers never sleep (you watch their rhythm and run)
	spaces = [
		["entry", 34, 52, 38, 60, 0, 3.5],            # the way in
		["pells_hut", 32, 44, 40, 52, 0, 4.5],        # 1 bed, table, chest; the barred gate on its east wall
		["shed_door", 30, 46, 32, 50, 0, 3.5],
		["winch_shed", 24, 44, 30, 50, 0, 4.5],       # 2 the tripwire; the shaft in its north-west corner
		["pantry", 20, 48, 24, 52, 0, 3],             # 3 behind the cracked wall (Pell's stash)
		["lift_top", 40, 46, 46, 50, 0, 4.5],         #   behind the gate: the lever, the lift shaft's top
		["shaft", 24, 44, 26, 46, DOWN, 6.5],         # 4 the ladder down
		["lift", 44, 46, 46, 48, DOWN, 6.5],          #   the way out: up from the Last Dig
		["landing", 24, 40, 30, 46, DOWN, 4.5],       # 5 the shaft's foot (rats)
		["cave_in", 24, 36, 28, 40, DOWN, 3.5],       # 6 half fallen in: 4 m wide at its ends,
		["cave_squeeze", 24, 32, 26, 36, DOWN, 3.5],  #   2 m in the middle, a spear wall on each side there
		["cave_in_s", 24, 30, 28, 32, DOWN, 3.5],
		["sorting", 22, 22, 30, 30, DOWN, 4.5],       # 7 dart plate, bear jaws, Lost Miners
		["spoil", 14, 24, 22, 28, DOWN, 3.5],         # 8
		["den", 8, 22, 14, 28, DOWN, 4.5],            # 9 the rat pack, the loose stone
		["gallery_door", 30, 24, 32, 28, DOWN, 3.5],
		["gallery", 32, 20, 42, 28, DOWN, 5],         # 10 rotten boards over the spike pit
		["spike_pit", 34, 22, 38, 28, DOWN - 4.0, 5], #    (4 m down onto spikes: falling in kills)
		["seam", 38, 28, 42, 38, DOWN, 6],            # 11 the crushers (rock overhead)
		["shrine_door", 36, 32, 38, 36, DOWN, 3.5],
		["shrine", 30, 32, 36, 38, DOWN, 4.5],        # 12 the healing basin; the hidden boulder on its south side
		["niche", 32, 38, 34, 42, DOWN, 3],           #    behind the boulder (a chest)
		["dig_door", 38, 38, 42, 40, DOWN, 3.5],
		["pell_passage", 30, 38, 38, 48, DOWN, 5],    #    corridor from landing to dig; without this the rats stop at the room edge
		["dig", 36, 40, 50, 56, DOWN, 5],             # 13 Pell's Last Dig: the Foreman, the recipe stand, the lift (owner,
		                                              #    Nov 20: "a lot bigger", 14 x 16 m: 3 miners and the boss)
	],
}

## Mossprop Workings: one tall mossy cave you climb. A rotten timber prop tower stands against its north cliff (decks at
## 5 and 10 m); the rooms are dug into the rock behind it. Boss: the Prop Warden. Built by tools/dungeons/make_mossprop.py
## (docs/design/zone1-dungeons/04-mossprop-workings.md). The way back down: a rope slide from the top deck to Base Camp.
const MOSSPROP := {
	id = "mossprop",
	name = "Mossprop Workings",
	mouth = Vector2(30, 60),
	since = 17,
	best = 130.0,
	chase_out = true,
	deadly = ["chasm"],
	no_raising = true,  ## (owner, Nov 21, F592: the Prop Warden doesn't bring the miners back here; kept for the next boss)
	crushers_always = true,  ## (owner, Nov 21, F590: "the crushers still don't work": they waited for a Pack Hall it hasn't got)
	spaces = [
		["entry", 28, 50, 32, 60, 0, 3.5],            # the way in
		["great_cave", 14, 24, 46, 50, 0, 16],        # the tall cave (natural rock, 16 m up): the tower stands in it
		["base_camp", 26, 40, 36, 50, 0, 4],          # 1 old camp at the cliff foot; the rope slide lands here
		["lower_walk", 14, 30, 16, 46, 2, 3],         # 2 rotten boards 2 m up along the west wall (Lost Miners shove)
		["rockfall_ledge", 14, 24, 20, 30, 2, 4],     # 3 under loose stalactites; the ladder up through the deck
		["second_floor_hall", 23, 23, 32, 29, 4, 7],  # the landing at the top of the first ladder (guards here wake when you arrive on floor 2)
		["tool_niche", 10, 26, 14, 30, 2, 3],         # 4 behind the hidden boulder: the spiked chest
		["prop_room", 16, 18, 24, 24, 5, 4],          # 5 dart wall
		["store_shed", 24, 18, 30, 24, 5, 4],         # 6 supplies, the cracked north wall
		["vault", 24, 14, 28, 18, 5, 3],              # 7 the hidden vault
		["chasm", 30, 24, 38, 34, -5, 5],             # 8 10 m under the bridge: spikes (falling in kills)
		["climbers_rest", 46, 28, 52, 34, 5, 4],      # 10 healing basin; a spear wall by the upper ladder
		["gallery", 20, 12, 24, 24, 10, 6],           # 12 crushers (rock overhead)
		["roost", 14, 12, 20, 18, 10, 4],             # 13 Tunnel Rats' roost, the loose stone
		["hall_door", 24, 12, 30, 16, 10, 4],
		["top_hall", 30, 10, 44, 24, 10, 6],          # 14 the Prop Warden; the barred gate out onto the top deck
	],
	## The great cave is natural rock (owner, Nov 21, F583: "still one big square"): its west, east and south walls and
	## its roof bulge in and dimple out (rough_bump); the floor and the north cliff (the tower's) stay flat. Near built
	## things the rock stays where the box puts it (mode 0) or may only dimple out (mode 1): [mode, x0, y0, z0, x1, y1, z1].
	## tools/dungeons/make_mossprop.py reads these to hang its stalactites from the roof; test_the_rock_keeps_off_the_tower.
	rough = {space = "great_cave", amp = 1.8, keep = [
		[0, 11.0, 0.0, 22.0, 21.0, 18.0, 31.5],   # the Rockfall Ledge, its doorway and its falling stalactites
		[1, 11.0, 0.0, 31.5, 17.5, 6.5, 45.0],    # behind the Lower Walk (its boards stand 0.5 m off the wall)
		[0, 11.0, 0.0, 45.0, 18.0, 4.0, 48.5],    # the ladder up onto the Lower Walk
		[0, 41.5, 0.0, 22.0, 49.0, 13.5, 37.5],   # the tower's east arm, the Climbers' Rest door, the ladder spikes
		[0, 24.5, 0.0, 46.0, 35.5, 5.5, 53.0],    # the way in and Base Camp's back
		[0, 30.5, 11.0, 22.0, 37.5, 18.0, 29.5],  # the swinging boulder's chain up to the roof
	]},
}

const MAPS := [MOSSGATE, LAMPWICK, PELL, MOSSPROP]


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
	var rough_i := -1
	var pad := 0.0  # (a rough cave dimples out up to amp: its old dwarf stone shell goes out with it)
	if map.has("rough"):
		pad = float(map.rough.amp)
		for i in map.spaces.size():
			if map.spaces[i][0] == map.rough.space:
				rough_i = i
	lo -= Vector3.ONE * (SHELL + pad)
	hi += Vector3.ONE * (SHELL + pad)
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
		boxes = boxes, lo = lo, hi = hi, wlo = wlo, whi = whi, entry_out = entry_out, rough_i = rough_i}


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
	var ri: int = d.get("rough_i", -1)
	for i in d.boxes.size():
		var b: Array = d.boxes[i]
		best = maxf(best, _rough_in(q, b[0], b[1], d.map.rough) if i == ri else _box_in(q, b[0], b[1]))
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


## A rough box (map.rough): like _box_in, but each wall and the roof moved in or out by rough_bump. Inside it is the
## distance to the nearest (moved) side; outside, how far past the furthest one (close enough for carving rock).
static func _rough_in(q: Vector3, mn: Vector3, mx: Vector3, r: Dictionary) -> float:
	var w := q.x - mn.x + rough_bump(r, 0, q.z, q.y, q)
	var e := mx.x - q.x + rough_bump(r, 1, q.z, q.y, q)
	var s := mx.z - q.z + rough_bump(r, 2, q.x, q.y, q)
	var c := mx.y - q.y + rough_bump(r, 3, q.x, q.z, q) * clampf((q.z - mn.z - 1.5) / 2.5, 0.0, 1.0)
	return minf(minf(minf(w, e), minf(s, q.z - mn.z)), minf(c, q.y - mn.y))


## How far wall `wall` (0 west, 1 east, 2 south, 3 the roof) is pushed out (+, a dimple) or in (-, a bulge) at its spot
## (a, b) along it: three waves of about 12, 8 and 4 m, up to amp. q (the map's metres) fades it out near built things
## (map.rough.keep). Same numbers on every computer (no dice): make_mossprop.py works it out the same way.
const ROUGH_PHASE := [[0.3, 2.1, 4.0], [1.7, 5.2, 0.9], [3.3, 0.6, 2.8], [5.0, 3.9, 1.4]]
static func rough_bump(r: Dictionary, wall: int, a: float, b: float, q: Vector3) -> float:
	var ph: Array = ROUGH_PHASE[wall]
	var v := (0.55 * sin(0.52 * a + 0.31 * b + float(ph[0])) + 0.30 * sin(0.23 * a - 0.83 * b + float(ph[1])) \
		+ 0.15 * sin(1.37 * a + 1.1 * b + float(ph[2]))) * float(r.amp)
	for k: Array in r.keep:
		if int(k[0]) == 1 and v >= 0.0:
			continue
		var out := Vector3(maxf(maxf(float(k[1]) - q.x, q.x - float(k[4])), 0.0),
			maxf(maxf(float(k[2]) - q.y, q.y - float(k[5])), 0.0), maxf(maxf(float(k[3]) - q.z, q.z - float(k[6])), 0.0))
		v *= clampf(out.length() / 1.5, 0.0, 1.0)
	return v


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
				tries.append([absf(d - float(map.get("best", 150.0))) + absf(side) * 0.3 + turn * 0.01, i, turn, side])
	tries.sort_custom(func(a, b): return a[0] < b[0])
	for t in tries:
		for back in [0.0, 2.0, 4.0]:  # (a slanted cave wall: set it deeper into the rock, see _try)
			_side_open = false
			var spot := _try(maker, map, maker.rooms[t[1]], int(t[2]), float(t[3]), back)
			if not spot.is_empty() and _clear_of_dungeons(maker, spot):
				return spot
			if not _side_open:
				break
	return {}


## Is a new dungeon's ground (rooms and their stone) well clear of every dungeon placed before it (Lampwick and
## Mossgate never share rock)?
static func _clear_of_dungeons(maker: CaveMaker, d: Dictionary) -> bool:
	var gap := Vector3.ONE * (SHELL + 4.0)
	for o in maker.dungeons:
		var lo: Vector3 = o.wlo - gap
		var hi: Vector3 = o.whi + gap
		var dlo: Vector3 = d.wlo
		var dhi: Vector3 = d.whi
		if dlo.x < hi.x and dhi.x > lo.x and dlo.y < hi.y and dhi.y > lo.y and dlo.z < hi.z and dhi.z > lo.z:
			return false
	return true


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
