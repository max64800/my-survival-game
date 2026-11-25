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
## The world is a row of biomes (world doc 1): Mossy Hollows in the middle, the Fungal Jungle to
## the east. Between them is a 20 m slab of border rock with two gate tunnels dug most of the way
## through; a copper pickaxe breaks the last 4 m. Outside everything is the world's edge, which
## nothing can dig.
##
## Two cave layouts (F211, Nov 16, 2026). A save remembers which one it was made with, so old saves
## keep their old caves (the owner's choice):
##   1 = the first caves: 400 m areas (Mossy x -200…200, Jungle x 220…620), squashed balls and tubes.
##   2 = real-shaped caves: 800 m areas (Mossy x -400…400, Jungle x 420…1220), about 4x the rooms,
##       passages and halls shaped the way water shapes real caves (see "layout 2" below).
const LAYOUT_LATEST := 19
## What brand-new worlds get. Layout 2: the real-shaped caves (F211 step 1, OK'd by the owner Nov 17). Layout 3: the
## same plus tall/wide/joined caverns and cliff exits with ledge paths (F230, F231). Old saves keep the layout they were
## made with; robots can try older caves with "-- layout=1" or "-- layout=2". Layout 4: the same plus a huge first
## cavern, its ceiling all glow-worm stars with several snakes (owner, Nov 17, F260). Layout 5: the same plus huge
## natural stone columns standing in that cavern (owner, Nov 17, F263). Layout 6: the columns keep out of the ruined
## watchtower's ground (owner, Nov 17: "the pillars are spawning inside the tower"). Layout 7: back to layout 3's
## caves, the first cavern its old size again (owner, Nov 17: the huge one "is too big... half of the cave or more is
## empty... the cave where we introduced the snakes was the best size"; huge caverns come back later, with big outposts).
## Layout 8: the same plus 1 or 2 smaller stone columns in the plain big caverns (owner, Nov 17: "yes, add one or two").
## Layout 9: the same plus natural rock bridges across some tall caverns (owner, Nov 17, F189).
## Layout 10: many more bridges (every tall cavern, the tallest get two; owner: "I didn't manage to find rock bridges").
## Layout 11: the first cavern always gets a bridge too, at least 4 m up (owner, Nov 17: "at least one bridge in the
## starting area").
## Layout 12: the first cave itself always gets a bridge (owner, Nov 18: "make sure the first cave always has some kind
## of a bridge"): if the usual tries fail, a patient second search there.
## Layout 13: every bridge has at least BRIDGE_AIR of air under it (owner, Nov 18: "the bridge should not be so close
## to the ground").
## Layout 14: the first dungeon, Mossgate Hold, dug into solid rock behind a cave wall (owner, Nov 19: DungeonMap).
## Layout 15: the second dungeon too, Lampwick Drift (owner, Nov 20: F477), kept well clear of the first.
## Layout 16: the third, Old Pell's Diggings (owner, Nov 20: "start working on dung 3"), clear of both.
## Layout 17: the fourth, Mossprop Workings (owner, Nov 21: a timber prop tower to climb), clear of all three.
## Layout 18: the Twin Gate stands in a natural cave that fits it, its back in the cave's own rock wall; no rock is
## grown round it (owner, Nov 23, F657: "use the caves that already exist"). See RuinTwinGate.natural.
## Layout 19: the Prow Hall the same way: a natural cave that fits it, the keep's back in the cave's own rock, no rock
## grown round it (owner, Nov 23, F657). See RuinProwHall.natural.
const LAYOUT_DEFAULT := 19
## The dungeon test world (owner, Nov 20: "do not build any caves at all, the way in should be a small cave like where
## you spawn"): one small cave with Mossgate Hold behind its wall, nothing else. A layout number of its own (higher
## than every real one, so every "layout 14 or later" rule holds), so saves, friends and the planning caches keep it
## apart from real worlds by themselves.
const DUNGEON_ONLY := 1014
## The Dungeon 2 test world: the same small cave with Lampwick Drift behind it (its own number, like DUNGEON_ONLY).
const DUNGEON_ONLY_2 := 1015
## The Dungeon 3 test world: the same small cave with Old Pell's Diggings behind it.
const DUNGEON_ONLY_3 := 1016
## The Dungeon 4 test world: the same small cave with Mossprop Workings behind it.
const DUNGEON_ONLY_4 := 1017
## The Dungeon 5 test world: the same small cave with the Tomb of Hald Ironbrow behind it.
const DUNGEON_ONLY_5 := 1018
## Test world layout -> which DungeonMap.MAPS it holds.
const DUNGEON_TESTS := {DUNGEON_ONLY: 0, DUNGEON_ONLY_2: 1, DUNGEON_ONLY_3: 2, DUNGEON_ONLY_4: 3, DUNGEON_ONLY_5: 4}
static var layout := LAYOUT_DEFAULT


## The sizes below are layout 1's until use_layout() runs: make them match the default as soon as the class loads.
static func _static_init() -> void:
	use_layout(LAYOUT_DEFAULT)

# --- Size of one biome (meters; 1 voxel = 1 meter). Set by use_layout(); these are layout 1's. ---
static var HALF_SIZE := 200.0
const Y_MIN := -64.0
const Y_MAX := 16.0
## Biomes: id, center x. Each is a box ±HALF_SIZE around its center.
static var BIOMES: Array = [{id = "mossy", cx = 0.0}, {id = "fungal", cx = 420.0}]
static var SLAB_X := 200.0  ## the Mossy/Fungal border slab runs from SLAB_X to SLAB_X + 20
const SLAB_W := 20.0
const PLUG := 4.0  ## rock left in the middle of each gate tunnel
static var X_MIN := -200.0
static var X_MAX := 620.0


## Picks the cave layout for the next CaveMaker (and the World, map and borders that go with it).
static func use_layout(v: int) -> void:
	layout = v if DUNGEON_TESTS.has(v) or not RuinTests.of_layout(v).is_empty() else clampi(v, 1, LAYOUT_LATEST)
	var half := 200.0 if layout == 1 else 400.0
	HALF_SIZE = half
	SLAB_X = half
	X_MIN = -half
	# Changed in place, never replaced: rock builders on other threads may be reading the list right now (a test
	# switching layouts while an earlier test's terrain was still building crashed on the freed list).
	BIOMES[0].cx = 0.0
	BIOMES[1].cx = half + SLAB_W + half
	X_MAX = half + SLAB_W + half * 2.0

# --- Shape tuning ---
const WALL_NOISE_AMP := 2.2  ## how bumpy walls are (meters)
const BLEND := 3.0  ## how softly tunnels melt into caverns (meters)
const CULL_MARGIN := 6.0  ## blocks farther than this from every shape are solid rock
const ORE_CELL := 2  ## ore veins are decided on a 2 m grid
const ORE_THRESHOLD := 0.66  ## Jungle silver
## Mossy copper is very rare (feedback F14): about 1.3% of wall rock, 1/6 of before (was 0.66 → 8%).
const COPPER_THRESHOLD := 0.915
## Zone 1 tin (F697): grey-silver specks in ordinary Mossy walls everywhere, a little rarer than the old all-over copper.
const TIN_THRESHOLD := 0.93
## Tin keeps this far (m) from anything built: ruins, towers, dungeons and their paths and stairs (placement rule, Nov 17).
const TIN_KEEP_CLEAR := 4.0
const TIN_POI_CLEAR := 7.0  ## and this far from a place's middle (camps, shrines, halls)
const SOLID_FILL := -6.0  ## SDF value used for blocks that are all rock

var seed: int
var made_layout := LAYOUT_DEFAULT  ## the layout this cave was made with (fixed when it's made)
## Layout 2: which way the rock layers tilt (meters up per meter along x and z). Flat ceilings and
## the stacked ledges on walls follow it, like real bedding planes.
var _dip := Vector2.ZERO
## The Copper Deeps (owner, Nov 15, F115): the only copper in Mossy Hollows, around 1-2 far, low caverns.
## {center, reach}: ore can appear in rock within `reach` of the center.
var deeps: Array[Dictionary] = []
const DEEPS_COUNT := 2
const DEEPS_THRESHOLD := 0.80  ## rich veins there (it's the only copper in the zone)
var rooms: Array[Dictionary] = []  ## {center: Vector3, radii: Vector3, big: bool, kind: String, sealed: bool}
## Special places (world doc 3.1): {id, type, pos, normal, room}. type: great_hall, ruin, nest, camp, shrine, geode
## (and outpost, ...). The boss places (lair altar, side-boss caverns, wall markings) were taken out (owner, Nov 19).
## Room kinds can still be nest_cavern, silver_vault, brood_hollow, lantern_grove (plain caverns with their old labels)
## and hollow (the old lair: sealed and empty).
var pois: Array[Dictionary] = []
## Where the first cave's start faces away from (the spot the old boss lair was rolled at, so old saves keep their start).
var _start_away := Vector3.INF
## Where the old boss places stood (Nov 19): new shrines and geodes still keep away from them, like before.
var _old_spots: Array[Vector3] = []
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
var _seg_k := PackedInt32Array()  ## passage kind (TUBE, CANYON, ...); layout 1 = all tubes
var _seg_h := PackedFloat32Array()  ## the kind's size number (canyon height, low passage half-width...)
var _room_shape := PackedInt32Array()  ## SHAPE_DOME, SHAPE_FLAT or SHAPE_FALLEN
## Lookup grid: which shapes are near each 16 m cell, so sdf_at() only checks those.
const GRID := 16
var _grid := {}  ## Vector3i cell -> [PackedInt32Array rooms, PackedInt32Array segments]

var _poi_biome := "mossy"  ## while planning: which biome new places belong to
var _wall_noise := FastNoiseLite.new()
var _ore_noise := FastNoiseLite.new()
var _tin_noise := FastNoiseLite.new()
var _dirt_noise := FastNoiseLite.new()
var _rock_noise := FastNoiseLite.new()
var _style_noise := FastNoiseLite.new()
## Rock styles to compare (owner, Nov 16: "try a few different things"). "blocks" = step 1's chunky
## blocks; the others keep the smooth surface and add broken-stone shapes on walls and ceilings:
## "slabs" (irregular slabs pushed in/out), "ledges" (stacked layers), "mixed" (both + small chips).
static var rock_style := "mixed":
	set(v):
		rock_style = v
		_style = STYLES.find(v)
## The same as a number, read by the rock checks (F211 speed): many threads build rock at once, and every one of them
## reading the shared text made them all queue for it (the plants took 40 s instead of 3.5 s while the rock loaded).
const STYLES := ["blocks", "slabs", "ledges", "mixed"]
const BLOCKS := 0
const SLABS := 1
const LEDGES := 2
const MIXED := 3
static var _style := MIXED
var _slab_noise := FastNoiseLite.new()
var _layer_noise := FastNoiseLite.new()
var _chip_noise := FastNoiseLite.new()
var _block_noise := FastNoiseLite.new()  ## layout 2: fallen blocks (one height per cell)
var _block_dist_noise := FastNoiseLite.new()  ## the same cells: how far from a block's middle
const SLAB_AMP := 1.2  ## how far a slab sticks out or sinks in (m)
const LEDGE_AMP := 1.0  ## how far a rock layer steps in or out (m)
const LAYER_H := 1.1  ## how tall one rock layer is (m)
const CHIP_AMP := 0.8  ## small chipped facets (m)
const ROCKY_AMP := 2.8  ## how far sharp rock juts out or cuts in (meters)


func _init(p_seed: int = 1, big_caverns: int = 3, small_rooms: int = 12) -> void:
	seed = p_seed
	made_layout = layout
	_start_away = Vector3.INF
	_old_spots.clear()
	_setup_noise()
	if made_layout >= 2:
		var drng := RandomNumberGenerator.new()
		drng.seed = p_seed + 6060
		_dip = Vector2(drng.randf_range(-0.05, 0.05), drng.randf_range(-0.05, 0.05))
	if DUNGEON_TESTS.has(made_layout):
		_make_dungeon_only(int(DUNGEON_TESTS[made_layout]))
		return
	if not RuinTests.of_layout(made_layout).is_empty():
		_make_ruin_only(RuinTests.of_layout(made_layout))
		return
	# Mossy Hollows first, with the same dice as before biomes existed (old caves stay the same).
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	_lay_out(rng, big_caverns, small_rooms, 0.0, "mossy")
	_bake_shapes()
	spawn_point = _find_spawn()
	_pick_deeps(rooms.size())
	var poi_rng := RandomNumberGenerator.new()
	poi_rng.seed = p_seed + 999  # its own dice, so adding places never moves the caves
	_plan_pois(poi_rng, 0, rooms.size(), 0, segments.size(), rooms[0].center, "mossy", 0.0)
	# The Fungal Jungle, then the gates that join them.
	var frng := RandomNumberGenerator.new()
	frng.seed = p_seed + 7000
	var r0 := rooms.size()
	var s0 := segments.size()
	_lay_out(frng, big_caverns, small_rooms, BIOMES[1].cx, "fungal")
	var s1 := segments.size()  # the gate tunnels (added next) cross both biomes: no jungle shrines on them
	_dig_gates(frng, r0)
	_bake_shapes()
	var fpoi := RandomNumberGenerator.new()
	fpoi.seed = p_seed + 7999
	_plan_pois(fpoi, r0, rooms.size(), s0, s1, gates[0].pos, "fungal", BIOMES[1].cx)
	# Last, so it never moves anything above: the small room where you wake up.
	cavern_spawn = spawn_point
	_plan_columns()
	_plan_cavern_columns()
	if made_layout >= 12:
		_plan_start()  # (layout 12: the wake-up room first, so the watchtower's spot is final before the bridges)
		_corner_cache.clear()
	_plan_bridges()
	_plan_colonnades()
	if made_layout < 12:
		_plan_start()
	_corner_cache.clear()  # the start room was just carved: forget block corners remembered before it
	if not start.is_empty():
		spawn_point = start.spawn
	_reserve_tower()
	if made_layout >= 14:
		_plan_dungeons()  # last, so nothing above moves
	if made_layout >= 2:
		_plan_trail()  # after everything built is known, so it keeps off it (uses no dice: nothing moves)


## One biome's rooms and the tunnels that join them, in this cave's layout.
func _lay_out(rng: RandomNumberGenerator, big_caverns: int, small_rooms: int, cx: float, biome: String) -> void:
	var r0 := rooms.size()
	if made_layout >= 2:
		_place_rooms_v2(rng, cx, biome)
		_connect_rooms_v2(rng, r0, cx)
	else:
		_place_rooms(rng, big_caverns, small_rooms, cx, biome)
		_connect_rooms(rng, r0, cx)


var _cols: Array[Vector4] = []  ## layout 5: the first cavern's stone columns (x, z, radius, twist)
var _col_span: Array[Vector2] = []  ## each column's floor and top height (its hourglass runs between them)
var _col_grid := {}  ## Vector2i (32 m square) -> PackedInt32Array: the columns that reach into it (fast lookups)
var _col_floor := 0.0  ## (the huge first cavern's floor and top)
var _col_top := 0.0
const COL_CELL := 32.0


func _add_column(at: Vector2, rad: float, twist: float, fl: float, top: float) -> void:
	var i := _cols.size()
	_cols.append(Vector4(at.x, at.y, rad, twist))
	_col_span.append(Vector2(fl, top))
	var reach := rad * 1.8 + 6.0  # (the farthest it reaches, leaning included)
	for gx in range(floori((at.x - reach) / COL_CELL), floori((at.x + reach) / COL_CELL) + 1):
		for gz in range(floori((at.y - reach) / COL_CELL), floori((at.y + reach) / COL_CELL) + 1):
			var k := Vector2i(gx, gz)
			if not _col_grid.has(k):
				_col_grid[k] = PackedInt32Array()
			_col_grid[k].append(i)


## Does this tunnel piece lie in the open middle of the room (within 70% of its size), where it's just floor?
## Its mouths near the walls are not, and ramps and ledge paths never count as floor.
func _seg_inside_room(sg: Dictionary, c: Vector3, r: Vector3) -> bool:
	for p in [sg.a, sg.b]:
		if Vector2((p.x - c.x) / r.x, (p.z - c.z) / r.z).length() > 0.7:
			return false
	return true


# ---------------------------------------------------------------- ground kept clear for built things
# Rule (owner, Nov 17): nothing the world grows stands inside something built or on its paths. Pebbles, plants, crystals
# and the old columns are made fresh every time a world loads, so they ask is_reserved() and skip that ground.

var tower_spot := {}  ## only in a ruin test world (RuinTests); real worlds work it out with RuinTower.find_spot
var outpost_spot := {}  ## where the Fallen Outpost goes ({room, pos, turn}; worked out once, in _reserve_tower)
var brewhall_spot := {}  ## where the Brewhall goes (F479; the same)
var spire_spot := {}  ## where the Lantern Spire goes (F479; the same)
var manor_spot := {}  ## where the Hearth Manor goes (F479; the same)
var prow_hall_spot := {}  ## where the Prow Hall goes (F656 + F657; the same)
var twin_gate_spot := {}  ## where the Twin Gate goes (F479 + F656 + F657; the same)
var smeltery_spot := {}  ## where the Smeltery Terraces go (F845; the same)
var reserved: Array[Dictionary] = []  ## {pos, r, h}: a circle of ground (r wide), from pos.y up to pos.y + h
var dungeons: Array[Dictionary] = []  ## layout 14: the dungeons dug into the rock (DungeonMap.place)


## Layout 14 (owner, Nov 19): the dungeons. Each picks its spot from the cave alone (same world number = same spot on
## every computer), then its rooms are cut into the rock and lined with old dwarf stone (sdf, material_at).
func _plan_dungeons() -> void:
	for map in DungeonMap.MAPS:
		if int(map.get("since", 14)) > made_layout:
			continue  # (layout 14 worlds keep only Mossgate Hold)
		var d := DungeonMap.find_spot(self, map)
		if d.is_empty():
			continue
		dungeons.append(d)
		# The cave floor in front of its door is kept clear too (no rocks, plants or crystals in the doorway).
		var door := DungeonMap.to_world(d, Vector3(map.mouth.x, 0.0, map.mouth.y + float(d.entry_out) + 1.0))
		reserve(door, 4.5, 5.0)
	_corner_cache.clear()


## The dungeon test world: a small cave (like the one you wake up in) and one dungeon (Mossgate Hold, or Lampwick
## Drift for the Dungeon 2 test) dug in behind its north wall.
func _make_dungeon_only(map_i := 0) -> void:
	var c := Vector3(0.0, -20.0, 0.0)
	rooms.append({center = c, radii = Vector3(10.0, 5.5, 10.0), big = false, kind = "room", sealed = false, biome = "mossy"})
	_bake_shapes()
	spawn_point = _find_spawn()
	cavern_spawn = spawn_point
	var fl := find_floor(c.x, c.z, c.y)
	var map: Dictionary = DungeonMap.MAPS[map_i]
	# Its round door 4 m into the rock behind the cave's wall (about 10 m out, its bumps up to 2 m), the hole from it running
	# 4 m into the cave.
	var mouth := Vector3(0.0, roundf(fl.y), -18.0)
	var d := DungeonMap.place(map, mouth, 0, -4.0 - mouth.z)
	dungeons.append(d)
	reserve(DungeonMap.to_world(d, Vector3(map.mouth.x, 0.0, map.mouth.y + float(d.entry_out) + 1.0)), 4.5, 5.0)
	_corner_cache.clear()


## A ruin test world (owner, Nov 21; RuinTests): one dome cave with a flat floor, the ruin's middle a little behind its
## middle, its door (+z) facing you. You arrive in front of it. Nothing else is planned.
func _make_ruin_only(e: Dictionary) -> void:
	var c := Vector3(0.0, -20.0, 0.0)
	rooms.append({center = c, radii = e.cave, big = true, kind = "room", sealed = false, biome = "mossy", shape = SHAPE_DOME})
	_bake_shapes()
	var mid := Vector3(0.0, c.y, -float(e.back))
	var low := INF  # the lowest ground under its body, like the real worlds' picks (it never floats)
	for sx in 5:
		for sz in 5:
			var h := float(e.half)
			low = minf(low, find_floor(mid.x + (sx - 2) * h / 2.0, mid.z + (sz - 2) * h / 2.0, c.y).y)
	var spot := {room = 0, pos = Vector3(mid.x, low - 0.05, mid.z), turn = 0}
	set(String(e.key) + "_spot", spot)
	var front := find_floor(0.0, float(e.cave.z) * 0.55, c.y)
	spawn_point = front + Vector3.UP * 1.0
	cavern_spawn = spawn_point
	_corner_cache.clear()


## The most-open dungeon number at p (positive = in a dungeon room), or a big negative number.
func _dungeon_sdf(p: Vector3) -> float:
	var best := -1e9
	for d in dungeons:
		best = maxf(best, DungeonMap.sdf(d, p))
	return best


## Is p old dwarf stone (a dungeon's walls, floor and ceiling, which no pickaxe breaks)?
func in_dungeon_stone(p: Vector3) -> bool:
	for d in dungeons:
		if DungeonMap.covers(d, p):
			return true
	return false


func _overlaps_dungeon(lo: Vector3, hi: Vector3) -> bool:
	for d in dungeons:
		if _overlaps(lo, hi, d.wlo, d.whi):
			return true
	return false


func reserve(pos: Vector3, r: float, h: float) -> void:
	reserved.append({pos = pos, r = r, h = h})


## Is p on ground kept clear for something built (or within `margin` of it)?
func is_reserved(p: Vector3, margin := 0.0) -> bool:
	for z in reserved:
		var c: Vector3 = z.pos
		if p.y > c.y - 1.5 and p.y < c.y + float(z.h) + 6.0 				and Vector2(p.x - c.x, p.z - c.z).length() < float(z.r) + margin:
			return true
	for d in dungeons:
		if DungeonMap.covers(d, p, margin):
			return true
	return false


# ---------------------------------------------------------------- the old dirt path (F870 step 5, OldTrail)

const TRAIL_HALF := 1.0  ## half the path's width (m); its edges wear in and out a little
const TRAIL_CELL := 4.0
var trail := PackedVector3Array()  ## floor spots along the old path, about 1.5 m apart
var trail_along := PackedVector3Array()  ## which way the path runs at each spot (flat)
var _trail_grid := {}  ## Vector2i (4 m square) -> PackedInt32Array of spots


func _plan_trail() -> void:
	# (read from the saved file when this cave was planned before: PlanCache, faster second load)
	var t: Dictionary = PlanCache.get_or_make("trail", self, "res://src/world/old_trail.gd", func() -> Dictionary: return OldTrail.plan(self))
	trail = t.points
	trail_along = t.along
	_trail_grid.clear()
	for i in trail.size():
		var g := Vector2i(floori(trail[i].x / TRAIL_CELL), floori(trail[i].z / TRAIL_CELL))
		if not _trail_grid.has(g):
			_trail_grid[g] = PackedInt32Array()
		_trail_grid[g].append(i)


## Is p on the old dirt path (or within `margin` of it)? Nothing the world grows may stand there (placement rule).
func on_trail(p: Vector3, margin := 0.0) -> bool:
	return _trail_dist2(p, TRAIL_HALF + margin) < INF


## Squared flat distance from p to the nearest path spot within `reach` (and 2.5 m up or down), or INF.
func _trail_dist2(p: Vector3, reach: float) -> float:
	if _trail_grid.is_empty():
		return INF
	var best := INF
	var r2 := reach * reach
	for gx in range(floori((p.x - reach) / TRAIL_CELL), floori((p.x + reach) / TRAIL_CELL) + 1):
		for gz in range(floori((p.z - reach) / TRAIL_CELL), floori((p.z + reach) / TRAIL_CELL) + 1):
			var cell = _trail_grid.get(Vector2i(gx, gz))
			if cell == null:
				continue
			for i: int in cell:
				var q := trail[i]
				if absf(p.y - q.y) > 2.5:
					continue
				var d := (p.x - q.x) * (p.x - q.x) + (p.z - q.z) * (p.z - q.z)
				if d < r2 and d < best:
					best = d
	return best


## Does the path come near this box (so its floor voxels need a look)?
func _trail_near_box(lo: Vector3, hi: Vector3) -> bool:
	if _trail_grid.is_empty():
		return false
	for gx in range(floori((lo.x - 2.0) / TRAIL_CELL), floori((hi.x + 2.0) / TRAIL_CELL) + 1):
		for gz in range(floori((lo.z - 2.0) / TRAIL_CELL), floori((hi.z + 2.0) / TRAIL_CELL) + 1):
			var cell = _trail_grid.get(Vector2i(gx, gz))
			if cell == null:
				continue
			for i: int in cell:
				if trail[i].y > lo.y - 3.0 and trail[i].y < hi.y + 3.0:
					return true
	return false


## Is this floor voxel worn into packed dirt? The edges go in and out, and here and there the moss creeps back in.
func is_trail_floor(p: Vector3i) -> bool:
	var d := _trail_dist2(Vector3(p) + Vector3(0.5, 1.0, 0.5), TRAIL_HALF + 0.4)
	if d == INF:
		return false
	var wear := _hash01(Vector3i(p.x, 7, p.z))
	var edge := TRAIL_HALF * (0.75 + 0.5 * wear)
	if _hash01(Vector3i(p.x >> 2, 11, p.z >> 2)) < 0.12:
		edge *= 0.55  # (a patch where the moss has grown back over most of it)
	return d < edge * edge


## The ruined watchtower by the first cavern (owner F254): it always picks the same spot from the cave (RuinTower.
## find_spot), so its ground is known here. Its round body, and the steps in front of its door, plus a little room.
## (Worlds made before the tower existed just get an empty patch there.)
func _reserve_tower() -> void:
	if made_layout < 3:
		return
	var plan := RuinTower.load_plan()
	if plan.is_empty():
		return
	var spot := RuinTower.find_spot(self, float(plan.get("radius", 4.2)), float(plan.get("height", 9.0)))
	if not spot.is_empty():
		reserve(spot.pos, maxf(float(plan.get("radius", 4.2)), float(plan.get("front", 6.8))) + 1.5, float(plan.get("height", 9.0)))
	# The Fallen Outpost (owner, Nov 17): its square (36 m across, round towers at two corners) kept clear too, so no
	# pebbles, plants or loose stones are left hanging after it digs out its space. The spot is remembered for it.
	var op := RuinTower.load_plan(RuinOutpost.OUTPOST_PLAN)
	if not op.is_empty():
		outpost_spot = RuinOutpost.pick(self, float(op.get("radius", 18.5)), float(op.get("height", 7.5)))
		if not outpost_spot.is_empty():
			# (a circle round a square fort: out past its corner towers, 25.5 m from the middle; F478, Nov 20)
			reserve(outpost_spot.pos, float(op.get("radius", 18.5)) * 1.42 + 1.5, float(op.get("height", 7.5)))
	# The Brewhall (owner, Nov 20, F479): the same, a circle out past its corners (its chimney, its front steps).
	var bh := RuinTower.load_plan(RuinBrewhall.PLAN_PATH)
	if not bh.is_empty():
		brewhall_spot = RuinBrewhall.pick(self, float(bh.get("radius", 8.6)), float(bh.get("height", 8.0)))
		if not brewhall_spot.is_empty():
			reserve(brewhall_spot.pos, float(bh.get("radius", 8.6)) * 1.42 + 1.5, float(bh.get("height", 8.0)))
	# The Lantern Spire (owner, Nov 20, F479): no flat base round it, but nothing the world grows may stand in the tower
	# or on its wreckage, which lies up to 19 m out: a circle out past all of it.
	var sp := RuinTower.load_plan(RuinSpire.PLAN_PATH)
	if not sp.is_empty():
		spire_spot = RuinSpire.pick(self, sp)
		if not spire_spot.is_empty():
			reserve(spire_spot.pos, RuinSpire.REACH + 1.5, float(sp.get("height", 12.0)))
	# The Hearth Manor (owner, Nov 22, F479): a circle out past its far corners and its terrace steps (after the Spire,
	# whose cavern it leaves alone).
	var mn := RuinTower.load_plan(RuinManor.PLAN_PATH)
	if not mn.is_empty():
		manor_spot = RuinManor.pick(self, float(mn.get("height", 13.5)))
		if not manor_spot.is_empty():
			reserve(manor_spot.pos, Vector2(RuinManor.HALF_X, RuinManor.FRONT).length() + 1.5, float(mn.get("height", 13.5)))
	# The Prow Hall (owner, Nov 22, F656 + F657): a circle out past the lone tower, the prow's yard and the rock it grows
	# (after the Manor, whose cavern it leaves alone).
	if not RuinTower.load_plan(RuinProwHall.PLAN_PATH).is_empty():
		prow_hall_spot = RuinProwHall.pick(self)
		if not prow_hall_spot.is_empty():
			reserve(prow_hall_spot.pos, RuinProwHall.REACH + 3.0, RuinProwHall.WALL_TOP)
	# The Twin Gate (owner, Nov 22, F479 + F656 + F657): a circle out past its moat, its lumps and the rock wall it grows
	# (after the Prow Hall, whose cavern it leaves alone).
	if not RuinTower.load_plan(RuinTwinGate.PLAN_PATH).is_empty():
		twin_gate_spot = RuinTwinGate.pick(self)
		if twin_gate_spot.is_empty():
			# No spot clear of the stone columns (seed 42, Nov 22: the Prow Hall took the other big cavern): it takes
			# the best spot anyway and the columns standing in it are never grown (moved far off the map), so the
			# placement rule still holds. Worlds that found a spot the first way don't change.
			twin_gate_spot = RuinTwinGate.pick(self, true)
			if not twin_gate_spot.is_empty():
				for i in RuinTwinGate.columns_in(self, twin_gate_spot):
					_cols[i] = Vector4(1.0e7, 1.0e7, _cols[i].z, _cols[i].w)
		if not twin_gate_spot.is_empty():
			reserve(twin_gate_spot.pos, RuinTwinGate.REACH + 3.0, RuinTwinGate.WALL_TOP)
	# The Smeltery Terraces (owner, Nov 25, F845): a circle out past the furnace and the watch turret, up past the
	# chimney (after the Twin Gate, whose cavern it leaves alone). No spot clear of the columns: like the Twin Gate.
	if not RuinTower.load_plan(RuinSmeltery.PLAN_PATH).is_empty():
		smeltery_spot = RuinSmeltery.pick(self)
		if smeltery_spot.is_empty():
			smeltery_spot = RuinSmeltery.pick(self, true)
			if not smeltery_spot.is_empty():
				for i in RuinSmeltery.columns_in(self, smeltery_spot):
					_cols[i] = Vector4(1.0e7, 1.0e7, _cols[i].z, _cols[i].w)
		if not smeltery_spot.is_empty():
			reserve(smeltery_spot.pos, RuinSmeltery.REACH + 3.0, RuinSmeltery.HEIGHT + 2.0)


## Layout 8 (owner, Nov 17): 1 or 2 smaller stone columns (5 to 11 m wide) in the plain big caverns, the same kind as
## the huge cavern's. Never in the Fallen Outpost's cavern or on the watchtower's ground (the placement rule), and
## clear of paths and places. Their own dice, so nothing else moves.
func _plan_cavern_columns() -> void:
	if made_layout < 8:
		return
	var outpost := -1
	if ResourceLoader.exists("res://src/world/ruin_outpost.gd"):
		var ro: Script = load("res://src/world/ruin_outpost.gd")
		for m in ro.get_script_method_list():
			if m.name == "pick_room":
				outpost = ro.call("pick_room", self)  # the outpost's cavern (the same answer on every computer)
				break
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 8900
	for ri in rooms.size():
		var room: Dictionary = rooms[ri]
		if not room.big or room.get("kind", "") not in ["cavern", "spawn", "great_hall", "nest_cavern", "lantern_grove"] \
				or room.get("sealed", false) or ri == outpost or int(room.get("shape", SHAPE_DOME)) == SHAPE_FALLEN:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		if r.y < 6.5:
			continue  # too low for a column to look like one
		var fl := c.y - r.y * 0.55
		var top := fl + r.y * 1.55
		var reach := maxf(r.x, r.z) + 10.0
		var near_segs: Array[int] = []
		for i in segments.size():
			var sg: Dictionary = segments[i]
			if Vector2(sg.a.x - c.x, sg.a.z - c.z).length() < reach or Vector2(sg.b.x - c.x, sg.b.z - c.z).length() < reach:
				if sg.get("ramp", false) or sg.get("ledge", false) or not _seg_inside_room(sg, c, r):
					near_segs.append(i)  # (a tunnel's line through the open middle of the cavern is just floor)
		var want := rng.randi_range(1, 2)
		var placed := 0
		for attempt in 30:
			if placed >= want:
				break
			var a := rng.randf_range(0.0, TAU)
			var dist := rng.randf_range(0.15, 0.5)
			var at := Vector2(c.x + cos(a) * r.x * dist, c.z + sin(a) * r.z * dist)
			var rad := rng.randf_range(2.5, 4.0)
			var twist := rng.randf_range(0.0, TAU)
			if sdf_at(Vector3(at.x, fl + 2.0, at.y)) <= 0.5 or sdf_at(Vector3(at.x, fl + r.y, at.y)) <= 0.5:
				continue  # a rock lump or a low ceiling here
			if _column_fits(at, rad, near_segs):
				_add_column(at, rad, twist, fl, top)
				placed += 1


## Layout 5 (owner, Nov 17, F263): huge natural stone columns in the huge first cavern, like a stalactite and a
## stalagmite that grew together long ago: wide where they meet the floor and the roof, narrower in the middle,
## leaning a little, with ribs running down them. 5 to 7 of them (fewer if paths leave no room), 7 to 21 m wide, kept clear of where you start,
## the places, and every path that runs through the cavern. Their own dice, so nothing else moves.
func _plan_columns() -> void:
	if made_layout < 5 or not huge_first():
		return
	var c: Vector3 = rooms[0].center
	var r: Vector3 = rooms[0].radii
	_col_floor = c.y - r.y * 0.55
	_col_top = c.y + r.y
	var near_segs: Array[int] = []  # the paths that run through the cavern (tunnel mouths, ramps, ledges)
	for i in segments.size():
		var sg: Dictionary = segments[i]
		if Vector2(sg.a.x - c.x, sg.a.z - c.z).length() < FIRST_CAVERN_R + 10.0 				or Vector2(sg.b.x - c.x, sg.b.z - c.z).length() < FIRST_CAVERN_R + 10.0:
			near_segs.append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 8800
	var want := rng.randi_range(5, 7)
	for attempt in 300:
		if _cols.size() >= want:
			break
		var a := rng.randf_range(0.0, TAU)
		var dist := sqrt(rng.randf()) * FIRST_CAVERN_R * 0.72
		var at := Vector2(c.x + cos(a) * dist, c.z + sin(a) * dist)
		var rad := rng.randf_range(4.5, 8.0)
		var twist := rng.randf_range(0.0, TAU)
		if _column_fits(at, rad, near_segs):
			_add_column(at, rad, twist, _col_floor, _col_top)


func _column_fits(at: Vector2, rad: float, near_segs: Array[int]) -> bool:
	var foot := rad * 1.4  # how wide its foot spreads
	for o in _cols:
		if at.distance_to(Vector2(o.x, o.y)) < foot + o.z * 1.4 + 12.0:
			return false
	if at.distance_to(Vector2(cavern_spawn.x, cavern_spawn.z)) < foot + 14.0:
		return false
	# Rule (owner, Nov 17): what the world grows never stands inside something built. The ruined watchtower
	# (RuinTower.find_spot) stands up to 24 m from where you come in, 4.2 m wide each way: keep all of that clear.
	if made_layout >= 6 and at.distance_to(Vector2(cavern_spawn.x, cavern_spawn.z)) < foot + TOWER_GROUND:
		return false
	for q in pois:
		if at.distance_to(Vector2(q.pos.x, q.pos.z)) < foot + 7.0:
			return false
	for i in near_segs:
		var sg: Dictionary = segments[i]
		var a2 := Vector2(sg.a.x, sg.a.z)
		var b2 := Vector2(sg.b.x, sg.b.z)
		var ab := b2 - a2
		var t := clampf((at - a2).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if at.distance_to(a2 + ab * t) < foot + float(sg.r) + 4.0:
			return false
	return true


## Is p inside (or within `margin` of) one of the first cavern's columns? (Layout 5; always false before.)
func _in_column(p: Vector3, margin: float) -> bool:
	for o in _cols:
		if Vector2(p.x - o.x, p.z - o.y).length() < o.z * 1.4 + margin:
			return true
	return false


# ---------------------------------------------------------------- rock bridges (layout 9)
# Owner, Nov 17 (F189; round 2: "I didn't manage to find rock bridges": every tall cavern now, the tallest get two): natural stone bridges spanning tall caverns, some you can walk across to reach high tunnels.
# A bridge is a flat-topped slab of the cave's own rock, wall to wall: about 3.5 m wide and 2.2 m thick in the middle,
# wider and much thicker where it grows out of the walls, so from below it's an arch. Where a tunnel opens high in the
# wall, the bridge runs out from that tunnel's floor across the cavern.

const BRIDGE_W := 3.5
const BRIDGE_T := 2.2
var _bridges: Array[Dictionary] = []  ## {a, b (ends, at the top surface), w, t}
var _br_grid := {}  ## Vector2i (32 m square) -> PackedInt32Array


func _plan_bridges() -> void:
	if made_layout < 9:
		return
	if made_layout >= 11:
		_plan_bridges_v11()
		return
	var outpost := -1
	if ResourceLoader.exists("res://src/world/ruin_outpost.gd"):
		var ro: Script = load("res://src/world/ruin_outpost.gd")
		for m in ro.get_script_method_list():
			if m.name == "pick_room":
				outpost = ro.call("pick_room", self)
				break
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 9100
	for ri in rooms.size():
		var room: Dictionary = rooms[ri]
		var roll := rng.randf()
		var ang := rng.randf_range(0.0, TAU)
		if not room.big or room.get("sealed", false) or ri == outpost or roll > (1.0 if made_layout >= 10 else 0.5) \
				or room.get("kind", "") not in ["cavern", "spawn", "great_hall", "nest_cavern", "lantern_grove"]:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var fl := c.y - r.y * 0.55
		var tall := r.y * 1.55
		if tall < (10.0 if made_layout >= 10 else 12.0):
			continue  # too low for a bridge to be worth it
		var h := fl + tall * 0.5
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var mouth := -1
		for i in segments.size():  # a tunnel coming in high up: the bridge starts at its floor
			var sg: Dictionary = segments[i]
			for e in [sg.a, sg.b]:
				var rel := Vector2((e.x - c.x) / r.x, (e.z - c.z) / r.z).length()
				var floor_e: float = e.y - float(sg.r) * 0.6
				if rel > 0.75 and rel < 1.25 and floor_e > fl + 5.0 and floor_e < fl + tall - 4.0:
					mouth = i
					h = floor_e
					dir = Vector3(c.x - e.x, 0.0, c.z - e.z).normalized()
					break
			if mouth >= 0:
				break
		# From the high tunnel if there is one and it's clear; else up to 6 directions at mid-height.
		var tries: Array = []
		if mouth >= 0:
			tries.append([dir, h, mouth])
		for k in 6:
			tries.append([Vector3(cos(ang), 0.0, sin(ang)).rotated(Vector3.UP, k * PI / 6.0), fl + tall * 0.5, -1])
		var made := 0
		var want := 2 if tall >= 16.0 and made_layout >= 10 else 1  # the tallest caverns get a second one, higher up, crossing the first
		for t in tries:
			var dk: Vector3 = t[0]
			var y: float = t[1] if made == 0 else fl + tall * 0.72
			if made == 1:
				dk = dk.rotated(Vector3.UP, PI / 2.0)
			var reach := Vector2(dk.x * r.x, dk.z * r.z).length() * 1.05  # just into the wall, not through it
			var a := Vector3(c.x, y, c.z) - dk * reach
			var b := Vector3(c.x, y, c.z) + dk * reach
			if not _bridge_blocks(a, b, t[2] if made == 0 else -1, c, r):
				_add_bridge(a, b)
				made += 1
				if made >= want:
					break


## Layout 11 (owner, Nov 17: "a lot more bridges, even small ones, also in small rooms"; "at least one in the starting
## area"; "two in one room is fine as long as they're not parallel"): every cavern 7 m+ tall may get one (big rooms
## always, small rooms 3 in 5, the starting cave always), small rooms get narrower, thinner ones; a room 14 m+ tall gets
## a second one, higher and crossing the first at 50 degrees or more. Each needs room to walk on top and air under it.
func _plan_bridges_v11() -> void:
	var outpost := -1
	if ResourceLoader.exists("res://src/world/ruin_outpost.gd"):
		var ro: Script = load("res://src/world/ruin_outpost.gd")
		for m in ro.get_script_method_list():
			if m.name == "pick_room":
				outpost = ro.call("pick_room", self)
				break
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 9200
	# The starting area: the first cavern, and the next nearest cavern in case the first has no room for one.
	var near_start := -1
	var near_d := 110.0
	for ri in range(1, rooms.size()):
		var d := Vector2(rooms[ri].center.x - cavern_spawn.x, rooms[ri].center.z - cavern_spawn.z).length()
		if rooms[ri].big and not rooms[ri].get("sealed", false) and ri != outpost and d < near_d:
			near_d = d
			near_start = ri
	var start_has := false
	# Where the ruined watchtower will stand (RuinTower.find_spot picks the same spot later: a bridge elsewhere only adds
	# rock away from it, which can't make another spot better).
	_tower_pre = {}
	var tplan := RuinTower.load_plan()
	if not tplan.is_empty():
		_tower_pre = RuinTower.find_spot(self, float(tplan.get("radius", 4.2)), float(tplan.get("height", 9.0)))
	for ri in rooms.size():
		var room: Dictionary = rooms[ri]
		var roll := rng.randf()
		var ang := rng.randf_range(0.0, TAU)
		var start_room := ri == 0 or (ri == near_start and not start_has)
		if room.get("sealed", false) or ri == outpost or room.get("kind", "") in ["hollow", "geode", "shrine"]:
			continue
		if not start_room and not room.big and roll > 0.6:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var fl := c.y - r.y * 0.55
		var tall := r.y * 1.55
		if tall < 7.0:
			continue
		var w := BRIDGE_W if room.big else 2.6
		var t := BRIDGE_T if room.big else 2.0
		var h := fl + maxf(6.5 if start_room else 4.0, tall * 0.5)
		if made_layout >= 13:
			h = maxf(h, fl + BRIDGE_AIR + t)
		var mouth := -1
		for i in segments.size():  # a tunnel coming in high up: the first bridge starts at its floor
			var sg: Dictionary = segments[i]
			for e in [sg.a, sg.b]:
				var rel := Vector2((e.x - c.x) / r.x, (e.z - c.z) / r.z).length()
				var floor_e: float = e.y - float(sg.r) * 0.6
				if rel > 0.75 and rel < 1.25 and floor_e > fl + 4.0 and floor_e < fl + tall - 3.0:
					mouth = i
					h = floor_e
					ang = atan2(c.z - e.z, c.x - e.x)
					break
			if mouth >= 0:
				break
		var want := 2 if tall >= 14.0 else 1
		var first_dir := Vector3.ZERO
		var first_y := 0.0
		for n in want:
			var y := h if n == 0 else maxf(first_y + 3.5 + t, fl + tall * 0.75)
			for k in 12:
				var dk := Vector3(cos(ang), 0.0, sin(ang)).rotated(Vector3.UP, k * PI / 12.0)
				if n == 1 and absf(dk.dot(first_dir)) > 0.64:
					continue  # not parallel to the first one (owner's rule): at least 50 degrees apart
				var reach := Vector2(dk.x * r.x, dk.z * r.z).length() * 1.05
				var a := Vector3(c.x, y, c.z) - dk * reach
				var b := Vector3(c.x, y, c.z) + dk * reach
				if _bridge_blocks(a, b, mouth if (n == 0 and k == 0) else -1, c, r, w, t, 0.5, 0.8, true) or not _bridge_has_room(a, b, t):
					continue
				if _over_tower_ground(a, b, y - t, w):
					continue
				_add_bridge(a, b, w, t, 0.5)  # (ends only 1.5x as thick: low bridges stay clear of floors and tunnel mouths)
				if ri == 0 or ri == near_start:
					start_has = true
				first_dir = dk
				first_y = y
				break
			if first_dir == Vector3.ZERO:
				if n == 0 and ri == 0 and made_layout >= 12:
					first_dir = _first_cave_bridge(c, r, fl, tall, w, t)
				if first_dir == Vector3.ZERO:
					break  # no first one: no second either
				first_y = _bridges[-1].a.y


## The ruined watchtower, up to 9 m tall: a bridge (its lowest part at `bottom`) must cross well above it, or keep away
## from its ground (the placement rule).
var _tower_pre := {}  ## where the watchtower will stand ({pos, turn}), worked out before the bridges


func _over_tower_ground(a: Vector3, b: Vector3, bottom: float, w: float) -> bool:
	if _tower_pre.is_empty():
		return false
	var tp: Vector3 = _tower_pre.pos
	var p2 := Vector2(tp.x, tp.z)
	var d := Geometry2D.get_closest_point_to_segment(p2, Vector2(a.x, a.z), Vector2(b.x, b.z)).distance_to(p2)
	return d < 8.5 + w and bottom < tp.y + (12.5 if made_layout >= 12 else 10.5)  # (its body and steps; 3.5 m+ of air over its roof)


## Layout 12: the first cave's patient search: every height from 4 m up, 24 directions, a slightly smaller gap over
## tunnel tops; still clear of the tower, ramps, ledges and places. Returns the bridge's direction (ZERO = none).
func _first_cave_bridge(c: Vector3, r: Vector3, fl: float, tall: float, w: float, t: float) -> Vector3:
	var hh := (BRIDGE_AIR + t) if made_layout >= 13 else 4.0
	while hh <= tall - 3.0:
		for k in 24:
			var dk := Vector3(1, 0, 0).rotated(Vector3.UP, k * PI / 24.0)
			var reach := Vector2(dk.x * r.x, dk.z * r.z).length() * 1.05
			var a := Vector3(c.x, fl + hh, c.z) - dk * reach
			var b := Vector3(c.x, fl + hh, c.z) + dk * reach
			if _bridge_blocks(a, b, -1, c, r, w, t, 0.4, 0.4, true) or not _bridge_has_room(a, b, t):
				continue
			if _over_tower_ground(a, b, fl + hh - t, w):
				continue
			_add_bridge(a, b, w, t, 0.4)
			return dk
		hh += 1.5
	if made_layout >= 13:  # (owner, Nov 18: no bridge in his first cave) also lines off to the side of the middle
		hh = BRIDGE_AIR + t
		while hh <= tall - 3.0:
			for off in [0.3, -0.3, 0.5, -0.5]:
				for k in 24:
					var dk := Vector3(1, 0, 0).rotated(Vector3.UP, k * PI / 24.0)
					var side := Vector3(-dk.z, 0, dk.x)
					var mid: Vector3 = Vector3(c.x, fl + hh, c.z) + side * Vector2(side.x * r.x, side.z * r.z).length() * off
					var reach := Vector2(dk.x * r.x, dk.z * r.z).length() * sqrt(1.0 - off * off) * 1.08
					var a: Vector3 = mid - dk * reach
					var b: Vector3 = mid + dk * reach
					if _bridge_blocks(a, b, -1, c, r, w, t, 0.4, 0.4, true) or not _bridge_has_room(a, b, t):
						continue
					if _over_tower_ground(a, b, fl + hh - t, w):
						continue
					_add_bridge(a, b, w, t, 0.4)
					return dk
			hh += 1.5
	return Vector3.ZERO


## Room to walk on top (2.2 m of air above it) and air under it, at a quarter, half and three quarters of the way.
const BRIDGE_AIR := 4.5  ## layout 13: metres of air between a bridge's underside and the floor


func _bridge_has_room(a: Vector3, b: Vector3, t: float) -> bool:
	for f in ([0.2, 0.35, 0.5, 0.65, 0.8] if made_layout >= 13 else [0.25, 0.5, 0.75]):
		var p := a.lerp(b, f)
		if sdf_at(p + Vector3.UP * 2.2) < 0.3 or sdf_at(p - Vector3.UP * (t + 1.2)) < 0.3:
			return false
		if made_layout >= 13 and sdf_at(p - Vector3.UP * (t + BRIDGE_AIR)) < 0.3:
			return false  # too close to the floor here
	return true


## Where the glowing veins gather (owner, Nov 18: "they appear where there are entrances to other caves... helping the
## player find where to go next; not at dead ends"): the points where a tunnel leaves a big cave and, following the
## tunnel pieces on, really reaches another cave. Worked out once (the same on every computer).
var _guides: PackedVector3Array
var _guides_done := false


func guide_points() -> PackedVector3Array:
	if _guides_done:
		return _guides
	_guides_done = true
	_guides = PackedVector3Array()
	var ends := {}  # a tunnel piece's end (rounded to 0.5 m) -> the pieces that touch it
	for i in segments.size():
		for e in [segments[i].a, segments[i].b]:
			var k := Vector3i(((e as Vector3) * 2.0).round())
			if not ends.has(k):
				ends[k] = []
			ends[k].append(i)
	for ri in rooms.size():
		var room: Dictionary = rooms[ri]
		if not room.big or room.get("sealed", false):
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		for i in segments.size():
			var sg: Dictionary = segments[i]
			var ra := _rel(sg.a, c, r)
			var rb := _rel(sg.b, c, r)
			if (ra < 1.0) == (rb < 1.0):
				continue  # not crossing this cave's wall
			var inside: Vector3 = sg.a if ra < 1.0 else sg.b
			var outside: Vector3 = sg.b if ra < 1.0 else sg.a
			var t := (1.0 - minf(ra, rb)) / maxf(absf(rb - ra), 0.001)
			var mouth := inside.lerp(outside, clampf(t, 0.0, 1.0))
			if _leads_on(i, outside, ri, ends):
				_guides.append(mouth)
	return _guides


func _rel(p: Vector3, c: Vector3, r: Vector3) -> float:
	return Vector2((p.x - c.x) / r.x, (p.z - c.z) / r.z).length()


## Following the tunnel pieces on from `start`, do we reach a cave other than `from_room` (before running out)?
func _leads_on(first: int, start: Vector3, from_room: int, ends: Dictionary) -> bool:
	var seen := {first: true}
	var todo: Array[Vector3] = [start]
	var steps := 0
	while not todo.is_empty() and steps < 400:
		steps += 1
		var p: Vector3 = todo.pop_back()
		for ri in rooms.size():
			if ri != from_room and _rel(p, rooms[ri].center, rooms[ri].radii) < 1.0 and absf(p.y - rooms[ri].center.y) < rooms[ri].radii.y * 1.3:
				return true
		for j in ends.get(Vector3i((p * 2.0).round()), []):
			if seen.has(j):
				continue
			seen[j] = true
			var sg: Dictionary = segments[j]
			todo.append(sg.b if (sg.a as Vector3).distance_to(p) < 0.6 else sg.a)
	return false


## Is p on top of a rock bridge (or within `margin` of its top)? Nothing is placed there (owner, Nov 18: "a lot of
## things on the bridge, some of them floating").
func on_bridge(p: Vector3, margin := 0.8) -> bool:
	if _bridges.is_empty():
		return false
	return _bridges_min(p) < margin


## Would a bridge from a to b cut through a ramp, a ledge path, a column or a place?
func _bridge_blocks(a: Vector3, b: Vector3, mouth: int, c: Vector3, r: Vector3, w := BRIDGE_W, t := BRIDGE_T, flare := 2.2, gap := 1.5, inner_free := false) -> bool:
	var probe := {a = a, b = b, w = w, t = t, flare = flare}
	for i in segments.size():
		if i == mouth:
			continue
		var sg: Dictionary = segments[i]
		if Vector2(sg.a.x - c.x, sg.a.z - c.z).length() > maxf(r.x, r.z) * 1.4 and Vector2(sg.b.x - c.x, sg.b.z - c.z).length() > maxf(r.x, r.z) * 1.4:
			continue
		if not (sg.get("ramp", false) or sg.get("ledge", false)) and _seg_inside_room(sg, c, r):
			continue  # a tunnel's line through the open middle is just floor, far below
		for k in 5:
			var q: Vector3 = (sg.a as Vector3).lerp(sg.b, k / 4.0)
			var rel := Vector2((q.x - c.x) / r.x, (q.z - c.z) / r.z).length()
			if rel > 1.1:
				continue  # deep in the rock beyond the wall: the bridge doesn't reach there
			if inner_free and rel < 0.75 and not (sg.get("ramp", false) or sg.get("ledge", false)):
				continue  # (layout 11) a tunnel's piece in the open middle of the cave is just its floor
			if _bridge_dist(q, probe) < float(sg.r) + gap:
				return true
	for o in _cols:
		if _bridge_dist(Vector3(o.x, a.y, o.y), probe) < o.z * 1.4 + 2.0:
			return true
	for q in pois:
		if _bridge_dist(q.pos, probe) < 3.0:
			return true
	return false


func _add_bridge(a: Vector3, b: Vector3, w := BRIDGE_W, t := BRIDGE_T, flare := 2.2) -> void:
	var i := _bridges.size()
	_bridges.append({a = a, b = b, w = w, t = t, flare = flare})
	var lo := Vector2(minf(a.x, b.x), minf(a.z, b.z)) - Vector2.ONE * (w * 2.0 + 8.0)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.z, b.z)) + Vector2.ONE * (w * 2.0 + 8.0)
	for gx in range(floori(lo.x / COL_CELL), floori(hi.x / COL_CELL) + 1):
		for gz in range(floori(lo.y / COL_CELL), floori(hi.y / COL_CELL) + 1):
			var k := Vector2i(gx, gz)
			if not _br_grid.has(k):
				_br_grid[k] = PackedInt32Array()
			_br_grid[k].append(i)


## Distance from p to a bridge's rock (below 0 = inside it).
func _bridge_dist(p: Vector3, br: Dictionary) -> float:
	var a: Vector3 = br.a
	var b: Vector3 = br.b
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var t := clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var lat := Vector2(p.x - (a.x + ab.x * t), p.z - (a.z + ab.y * t)).length()
	var e := 2.0 * t - 1.0
	var e4 := e * e * e * e
	var half_w: float = float(br.w) * 0.5 * (1.0 + 0.6 * e4)  # wider where it meets the walls
	var thick: float = float(br.t) * (1.0 + float(br.get("flare", 2.2)) * e4)  # much thicker there: an arch from below
	var top: float = a.y
	var dx := lat - half_w
	var dy := maxf(p.y - top, (top - thick) - p.y)
	return Vector2(maxf(dx, 0.0), maxf(dy, 0.0)).length() + minf(maxf(dx, dy), 0.0)


## Distance to the nearest bridge's rock (1e9 = none near).
func _bridges_min(p: Vector3) -> float:
	var near = _br_grid.get(Vector2i(floori(p.x / COL_CELL), floori(p.z / COL_CELL)))
	var best := 1e9
	if near != null:
		for i in near:
			best = minf(best, _bridge_dist(p, _bridges[i]))
	return best


## The columns cut into the open air of their cavern (d: distance to the air shape, below 0 = air).
func _with_columns(p: Vector3, d: float) -> float:
	var near = _col_grid.get(Vector2i(floori(p.x / COL_CELL), floori(p.z / COL_CELL)))
	if near == null:
		return d
	for i in near:
		var o := _cols[i]
		var sp := _col_span[i]
		var t := clampf((p.y - sp.x) / (sp.y - sp.x), 0.0, 1.0)
		var w := 2.0 * t - 1.0
		var flare := 0.75 + 0.55 * w * w  # an hourglass: wide at the floor and the roof, narrower in the middle
		var dx := p.x - o.x - sin(p.y * 0.13 + o.w) * o.z * 0.2  # (leans and bends a little)
		var dz := p.z - o.y - cos(p.y * 0.1 + o.w * 1.7) * o.z * 0.2
		var reach := o.z * 1.6 + 6.0
		if absf(dx) > reach or absf(dz) > reach:
			continue
		var rad := o.z * flare + 0.35 * sin(atan2(dz, dx) * 5.0 + p.y * 0.05 + o.w)  # ribs, like dripped stone
		d = -_smin(-d, Vector2(dx, dz).length() - rad, 4.0)  # soft where it meets the floor and the roof
	return d


## Rows of great old columns standing in the big caverns (feedback F9/F21), 1-2 per cavern,
## only where the floor is open and the ceiling is high enough. Planned last, with their own
## dice, so nothing else moves.
func _plan_colonnades() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 5150
	for ri in rooms.size():
		var room: Dictionary = rooms[ri]
		if not room.big or room.get("sealed", false) or room.get("shape", SHAPE_DOME) == SHAPE_FALLEN:
			continue  # (fallen-roof halls have their own big blocks instead)
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var placed := 0
		var want := rng.randi_range(1, 2)
		for attempt in 12:
			if placed >= want:
				break
			var a := rng.randf_range(0.0, TAU)
			var dist := rng.randf_range(0.25, 0.55)
			var at := c + Vector3(cos(a) * r.x * dist, 0.0, sin(a) * r.z * dist)
			var fl := find_floor(at.x, at.z, c.y)
			if sdf_at(fl + Vector3.UP * 8.0) <= 0.0 or not _far_from_pois(fl, 12.0) or _in_column(fl, 6.0):
				continue  # ceiling too low, or something else is already here
			_poi_biome = room.get("biome", "mossy")
			_add_poi("colonnade", fl, Vector3.UP, ri)
			pois[-1].yaw = rng.randf_range(0.0, TAU)
			placed += 1


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
	# Try the side of the cavern facing away from the old lair spot first, then fan out both ways.
	var first := rng.randf_range(0.0, TAU)
	if _start_away.is_finite():
		var away: Vector3 = c - _start_away
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
		if _smooth_at(p) > -1.0 or _region_dist(p) < 4.0:  # planning: the plain shape, before blocks
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
	# Broken-stone detail (rock styles): one flat value per irregular cell = a slab; layers by height.
	_slab_noise.seed = seed + 404
	_slab_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_slab_noise.frequency = 0.24
	_slab_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_slab_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_layer_noise.seed = seed + 505
	_layer_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_layer_noise.frequency = 1.0
	_chip_noise.seed = seed + 606
	_chip_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_chip_noise.frequency = 0.55
	_chip_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	_chip_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	# Fallen blocks (layout 2): cells about 7 m across, each one flat block.
	for n: FastNoiseLite in [_block_noise, _block_dist_noise]:
		n.seed = seed + 707
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.frequency = 0.14
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
		n.cellular_jitter = 0.8
	_block_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	_block_dist_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	_wall_noise.seed = seed
	_wall_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_wall_noise.frequency = 0.07
	_wall_noise.fractal_octaves = 2
	_ore_noise.seed = seed + 101
	_ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_ore_noise.frequency = 0.11
	_ore_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_tin_noise.seed = seed + 404
	_tin_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_tin_noise.frequency = 0.13
	_tin_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_dirt_noise.seed = seed + 202
	_dirt_noise.frequency = 0.05
	# Sharp, rocky walls (feedback F19): "cellular" noise makes angular facets, like broken stone.
	_rock_noise.seed = seed + 303
	_rock_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_rock_noise.frequency = 0.11
	_rock_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_rock_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	_rock_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	# Which parts of the cave are rocky and which are round: big slow patches, about half each.
	_style_noise.seed = seed + 404
	_style_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_style_noise.frequency = 0.012
	_style_noise.fractal_type = FastNoiseLite.FRACTAL_NONE


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
	var s0 := segments.size()
	# Loops (6, was 2): more than one way between places.
	for k in 6:
		var i := rng.randi_range(r0, n - 1)
		var j := rng.randi_range(r0, n - 1)
		if i != j:
			edges.append(Vector2i(i, j))
	for e in edges:
		_dig_worm(rng, mouth(rooms[e.x]), mouth(rooms[e.y]), cx)
	# Dead ends.
	for k in 6:
		var start: Vector3 = mouth(rooms[rng.randi_range(r0, n - 1)])
		var angle := rng.randf_range(0, TAU)
		var end := start + Vector3(cos(angle), rng.randf_range(-0.3, 0.3), sin(angle)) * rng.randf_range(40, 80)
		_dig_worm(rng, start, _clamp_inside(end, cx), cx)
	# Side passages (feedback F20, "more tunnels like Minecraft"): narrower, twisty tunnels that
	# branch off the ones above, wander up and down, cross each other, and sometimes go nowhere.
	var s1 := segments.size()
	for k in 16:
		var seg: Dictionary = segments[rng.randi_range(s0 if s1 > s0 else 0, s1 - 1)]
		var from: Vector3 = (seg.a + seg.b) * 0.5
		var angle := rng.randf_range(0, TAU)
		var dir := Vector3(cos(angle), rng.randf_range(-0.4, 0.4), sin(angle)).normalized()
		var end := _clamp_inside(from + dir * rng.randf_range(35.0, 110.0), cx)
		_dig_worm(rng, from, end, cx, 1.7, 2.6)


## Two gate tunnels through the Mossy/Fungal slab (world doc 1.3). Each side's tunnel stops
## 2 m before the middle, leaving a 4 m plug of border rock.
func _dig_gates(rng: RandomNumberGenerator, fungal_r0: int) -> void:
	var tries := 0
	while gates.size() < 2 and tries < 100:
		tries += 1
		var gz := rng.randf_range(-(HALF_SIZE - 50.0), HALF_SIZE - 50.0)  # (±150 m in layout 1)
		var gy := rng.randf_range(-40, -12)
		if gates.size() == 1 and absf(gates[0].pos.z - gz) < 90.0:
			continue
		var mid := Vector3(SLAB_X + SLAB_W * 0.5, gy, gz)
		var west_end := Vector3(mid.x - PLUG * 0.5, gy, gz)
		var east_end := Vector3(mid.x + PLUG * 0.5, gy, gz)
		var stub := HALF_SIZE - 15.0  # where each side's tunnel reaches the slab (185 m in layout 1)
		_dig_worm(rng, _nearest_room(mid, 0, fungal_r0), Vector3(BIOMES[0].cx + stub, gy, gz), BIOMES[0].cx)
		segments.append({a = Vector3(BIOMES[0].cx + stub, gy, gz), b = west_end, r = 3.4})
		_dig_worm(rng, _nearest_room(mid, fungal_r0, rooms.size()), Vector3(BIOMES[1].cx - stub, gy, gz), BIOMES[1].cx)
		segments.append({a = Vector3(BIOMES[1].cx - stub, gy, gz), b = east_end, r = 3.4})
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
## Where a tunnel leaves a room: in the middle, but down at floor height, so you can walk in and out
## (owner F141: exits high up in a tall cavern's wall needed lots of stairs). Tunnels are about 2.3-3.3 m
## wide around this line, so their floor meets the room's flat floor.
static func mouth(room: Dictionary) -> Vector3:
	var c: Vector3 = room.center
	var floor_y: float = c.y - (room.radii as Vector3).y * 0.55
	return Vector3(c.x, minf(c.y, floor_y + 1.9), c.z)


func _dig_worm(rng: RandomNumberGenerator, a: Vector3, b: Vector3, cx: float, r_min: float = 2.3, r_max: float = 3.3) -> void:
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
		segments.append({a = pos, b = next, r = rng.randf_range(r_min, r_max)})
		pos = next
	segments.append({a = pos, b = b, r = rng.randf_range(r_min, r_max)})


func _clamp_inside(p: Vector3, cx: float) -> Vector3:
	var M := HALF_SIZE - 15.0  # (185 m in layout 1)
	return Vector3(clampf(p.x, cx - M, cx + M), clampf(p.y, Y_MIN + 8.0, Y_MAX - 8.0), clampf(p.z, -M, M))


# ---------------------------------------------------------------- layout 2: real-shaped caves (F211)
# Real caves are carved by water following rock layers and cracks (research, docs/design/epic-caves-plan.md):
# along a layer you get flat ceilings and wide, low passages; along a crack, tall narrow slots; a stream
# cutting down makes a canyon, and a round tube over a canyon is a "keyhole". The biggest rooms are where
# the roof fell in: a tall arched ceiling over a floor of big fallen blocks. F110 (owner): 800 m areas,
# many more caverns and rooms, twisting branching tunnels with side passages and dead ends.

const V2_BIG := 8  ## big caverns per area (layout 1: 3)
const V2_HALLS := 14  ## middle-sized halls, 26-38 m across (new)
const V2_SMALL := 40  ## small chambers (layout 1: 12)
const V2_LOOPS := 18  ## extra tunnels between near rooms, so there's more than one way round
const V2_DEAD_ENDS := 20
const V2_SIDE := 90  ## narrower side passages that wander off, cross and sometimes go nowhere (layout 1: 16)

## Room shapes.
const SHAPE_DOME := 0  ## a squashed ball with a flat floor (all of layout 1)
const SHAPE_FLAT := 1  ## follows a rock layer: steep walls and a flat, slightly tilted ceiling
const SHAPE_FALLEN := 2  ## the roof fell in: a tall arched ceiling over big fallen blocks
const SHAPE_NAMES := ["dome", "flat", "fallen"]
## Passage kinds. Every kind has its floor at the same height (centre line - 0.6 r), so they join cleanly.
const TUBE := 0  ## a round tube (all of layout 1)
const CANYON := 1  ## a stream cut down: tall and narrow (h = height)
const KEYHOLE := 2  ## a slot below, a round tube above (h = slot height)
const LOW := 3  ## along a rock layer: wide and low with a flat ceiling (h = half-width)
const RIFT := 4  ## along a crack: very tall and narrow, fairly straight (h = height)
const KIND_NAMES := ["tube", "canyon", "keyhole", "low", "rift"]
## How much the bumpy-wall noise may move a kind's walls near its floor. Both walls of a passage move
## the same way, so narrow kinds get less, or they'd pinch shut. Higher up they get the full amount.
const KIND_BUMPS := [1.0, 0.3, 0.3, 0.4, 0.25]
const LOW_CEIL := 3.4  ## clear height of a low passage before the rock detail (the dwarf is 1.35 m)


func _place_rooms_v2(rng: RandomNumberGenerator, cx: float, biome: String) -> void:
	var r0 := rooms.size()
	var span := HALF_SIZE - 50.0
	# Big caverns, spread out so there's a journey between them. The first one (you start next to it)
	# is near the middle, so there's cave to explore in every direction.
	var tries := 0
	while _count_big(r0) < V2_BIG and tries < 1200:
		tries += 1
		var reach := 110.0 if rooms.size() == r0 else span
		var c := Vector3(cx + rng.randf_range(-reach, reach), rng.randf_range(-38, -18), rng.randf_range(-reach, reach))
		var r := Vector3(rng.randf_range(24, 34), rng.randf_range(10, 14), rng.randf_range(24, 34))
		if _far_from_rooms(c, 170.0 if tries < 700 else 120.0):
			if huge_first() and biome == "mossy" and rooms.size() == r0:
				# The first cavern, the one you start beside, is huge (owner, Nov 17: "the very first cave should be really
				# big"): ~120 m across under a high dome; its floor stays where it was.
				var floor_y := c.y - r.y * 0.55
				r = Vector3(FIRST_CAVERN_R, minf(20.0, (Y_MAX - 6.0 - floor_y) / 1.55), FIRST_CAVERN_R)
				c.y = floor_y + r.y * 0.55
			rooms.append({center = c, radii = r, big = true, kind = "cavern", sealed = false, biome = biome})
	# Middle-sized halls.
	var placed := 0
	tries = 0
	while placed < V2_HALLS and tries < 2000:
		tries += 1
		var c := Vector3(cx + rng.randf_range(-span, span), rng.randf_range(-48, -10), rng.randf_range(-span, span))
		var r := Vector3(rng.randf_range(13, 19), rng.randf_range(6, 9), rng.randf_range(13, 19))
		if _far_from_rooms(c, 75.0) and _clear_of_first(r0, biome, c, 19.0):
			rooms.append({center = c, radii = r, big = false, kind = "room", sealed = false, biome = biome, hall = true})
			placed += 1
	# Small chambers along the way, on every level.
	placed = 0
	tries = 0
	while placed < V2_SMALL and tries < 4000:
		tries += 1
		var c := Vector3(cx + rng.randf_range(-span, span), rng.randf_range(-54, -2), rng.randf_range(-span, span))
		var r := Vector3(rng.randf_range(7, 12), rng.randf_range(5, 7), rng.randf_range(7, 12))
		if _far_from_rooms(c, 45.0) and _clear_of_first(r0, biome, c, 12.0):
			rooms.append({center = c, radii = r, big = false, kind = "room", sealed = false, biome = biome})
			placed += 1
	if made_layout >= 3:
		_set_proportions(r0)


# ---------------------------------------------------------------- layout 3: cavern proportions (F230, F231)
# The owner (Nov 17): "I really like the wide but not tall caves... some tall and narrow, some tall and wide... a tall
# cavern goes into a wide cavern... some exits at the very top, like a cliff". Decided after the rooms are placed, with
# their own dice, so the places don't move; each keeps its floor height (tunnels are dug after, to the new mouths).

const TOWER_GROUND := 31.0  ## layout 6: no column within this of where you come in (the watchtower's ground)
const FIRST_CAVERN_R := 58.0  ## layout 4: the first cavern's half-width (m)


## Layout 4: other rooms keep clear of the huge first cavern (it would swallow them).
func _clear_of_first(r0: int, biome: String, c: Vector3, own_r: float) -> bool:
	if not huge_first() or biome != "mossy" or rooms.size() <= r0:
		return true
	var f: Vector3 = rooms[r0].center
	return Vector2(c.x - f.x, c.z - f.z).length() > FIRST_CAVERN_R + own_r + 10.0


## Layouts 4 to 6 have the huge first cavern (with stars, extra snakes and, from 5, stone columns); 7 doesn't.
func huge_first() -> bool:
	return made_layout >= 4 and made_layout <= 6


## Where the glow-worm stars get thicker and the snakes come in a group: the huge first cavern (layouts 4-6, 1 extra
## snake), or from layout 8 the ordinary first cavern (2 extra snakes: owner, Nov 17, "I was looking for some and
## couldn't see them... 2 or 3 snakes here and there"). {} = nowhere. Keys: center, radius, snakes (extra ones).
func star_room() -> Dictionary:
	if huge_first():
		var f := first_cavern()
		return {center = f.center, radius = maxf(f.radii.x, f.radii.z), snakes = 1}
	if made_layout >= 8 and not rooms.is_empty():
		return {center = rooms[0].center, radius = maxf(rooms[0].radii.x, rooms[0].radii.z), snakes = 2}
	return {}


## Where you wake up has no glow-worm stars (owner, Nov 19: "the spawn location shouldn't have stars", the first
## cavern keeps them): the wake-up room and a little round it. {} = none. Keys: center, radius.
func quiet_room() -> Dictionary:
	if start.is_empty() or not start.has("room_c"):
		return {}
	return {center = start.room_c, radius = START_ROOM_R.x + 3.0}  # (the room itself and its doorway, not the cavern)


## Layouts 4-6: the huge first cavern (where the ceiling is all stars), or {} in other layouts.
func first_cavern() -> Dictionary:
	if not huge_first() or rooms.is_empty():
		return {}
	return rooms[0]


const PROP_NORMAL := 0
const PROP_WIDE_LOW := 1  ## wider, low, flat rock-layer ceiling
const PROP_TALL_NARROW := 2  ## a deep shaft-like hall
const PROP_TALL_WIDE := 3  ## a cathedral
const PROP_NAMES := ["normal", "wide_low", "tall_narrow", "tall_wide"]
const LEDGE_SLOPE := 0.32  ## the ledge path down a cliff: gentler than a tunnel

func _set_proportions(r0: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 4242 + r0
	var r1 := rooms.size()
	for i in range(r0, r1):
		var rm: Dictionary = rooms[i]
		var roll := rng.randf()
		if i == r0 or not (rm.big or rm.get("hall", false)):
			continue  # the first cavern (you start beside it) stays easy
		var prop := PROP_NORMAL
		if rm.big:
			prop = PROP_WIDE_LOW if roll < 0.3 else (PROP_TALL_NARROW if roll < 0.5 else (PROP_TALL_WIDE if roll < 0.7 else PROP_NORMAL))
		else:
			prop = PROP_WIDE_LOW if roll < 0.3 else (PROP_TALL_NARROW if roll < 0.5 else (PROP_TALL_WIDE if roll < 0.6 else PROP_NORMAL))
		_reshape(rm, prop)
	# Joined caverns: some big caverns open sideways into a second part of the other kind, on the same floor.
	for i in range(r0, r1):
		var rm: Dictionary = rooms[i]
		var roll := rng.randf()
		var ang := rng.randf() * TAU
		if i == r0 or not rm.big or roll > 0.45:
			continue
		var prop := int(rm.get("prop", PROP_NORMAL))
		var lobe_prop := PROP_WIDE_LOW if prop in [PROP_TALL_NARROW, PROP_TALL_WIDE] else PROP_TALL_NARROW
		var r: Vector3 = rm.radii
		var lobe := {center = rm.center, radii = Vector3(r.x * 0.65, r.y, r.z * 0.65), big = false, kind = "room",
			sealed = false, biome = rm.biome, hall = true, lobe_of = i}
		_reshape(lobe, lobe_prop)
		var lr: Vector3 = lobe.radii
		var dir := Vector3(cos(ang), 0, sin(ang))
		var reach_p := 1.0 / Vector2(dir.x / r.x, dir.z / r.z).length()
		var reach_l := 1.0 / Vector2(dir.x / lr.x, dir.z / lr.z).length()
		var c: Vector3 = lobe.center + dir * (reach_p * 0.7 + reach_l * 0.7)
		var m := HALF_SIZE - 20.0
		var bx: float = BIOMES[0 if rm.biome == "mossy" else 1].cx
		if absf(c.x - bx) > m - lr.x or absf(c.z) > m - lr.z:
			continue
		var clear := true
		for j in rooms.size():
			if j != i and (rooms[j].center as Vector3).distance_to(c) < maxf(lr.x, lr.z) + maxf(rooms[j].radii.x, rooms[j].radii.z) + 8.0:
				clear = false
				break
		if clear:
			lobe.center = c
			rooms.append(lobe)


## New radii for a room's proportion, keeping its floor where it was (and its ceiling under the world's roof).
func _reshape(rm: Dictionary, prop: int) -> void:
	var c: Vector3 = rm.center
	var r: Vector3 = rm.radii
	var floor_y := c.y - r.y * 0.55
	match prop:
		PROP_WIDE_LOW:
			r = Vector3(r.x * 1.25, r.y * 0.62, r.z * 1.25)
		PROP_TALL_NARROW:
			r = Vector3(maxf(r.x * 0.5, 9.0), r.y * 2.3, maxf(r.z * 0.5, 9.0))
		PROP_TALL_WIDE:
			r = Vector3(r.x * 1.05, r.y * 2.0, r.z * 1.05)
	r.y = minf(r.y, (Y_MAX - 6.0 - floor_y) / 1.55)
	rm.radii = r
	rm.center = Vector3(c.x, floor_y + r.y * 0.55, c.z)
	rm.prop = prop


## Tall caverns: a tunnel can come in high up the wall (F231).
func _is_tall(i: int) -> bool:
	return int(rooms[i].get("prop", PROP_NORMAL)) in [PROP_TALL_NARROW, PROP_TALL_WIDE]


## Where a cliff tunnel comes into room i, on the side facing `toward`: high up (a bit over half its height), just
## inside the wall.
func _cliff_mouth(i: int, toward: Vector3) -> Vector3:
	var c: Vector3 = rooms[i].center
	var r: Vector3 = rooms[i].radii
	var dir := Vector3(toward.x - c.x, 0, toward.z - c.z).normalized()
	var y := c.y + r.y * 0.5
	var f := sqrt(1.0 - 0.25)  # how wide the ellipsoid still is at that height
	var reach := 1.0 / Vector2(dir.x / r.x, dir.z / r.z).length()
	return Vector3(c.x + dir.x * reach * f * 0.85, y, c.z + dir.z * reach * f * 0.85)


## The ledge path from a cliff mouth down to the floor: a low, flat-floored groove cut into the wall, open to the cavern
## on one side, winding round the wall at LEDGE_SLOPE.
func _dig_ledge(i: int, top: Vector3) -> void:
	var c: Vector3 = rooms[i].center
	var r: Vector3 = rooms[i].radii
	var floor_y := c.y - r.y * 0.55
	const R := 2.0  # the groove's floor is 1.2 m under its centre line
	var y0 := top.y - 0.6
	var y1 := floor_y + 1.2
	var run := maxf((y0 - y1) / LEDGE_SLOPE, 10.0)
	var n := ceili(run / 6.0)
	var ang := atan2((top.z - c.z) / r.z, (top.x - c.x) / r.x)
	var prev := Vector3.ZERO
	for k in n + 1:
		var y := lerpf(y0, y1, float(k) / n)
		var f := sqrt(maxf(0.1, 1.0 - pow((y - c.y) / r.y, 2.0)))
		var edge := Vector3(c.x + cos(ang) * r.x * f, y, c.z + sin(ang) * r.z * f)
		var out := Vector3(edge.x - c.x, 0, edge.z - c.z).normalized()
		var p := edge + out * 1.4
		if k > 0:
			segments.append({a = prev, b = p, r = R, k = LOW, h = 2.6, ledge = true})
		prev = p
		ang += (run / n) / maxf(Vector2(r.x, r.z).length() * 0.707 * f, 4.0)


## Going up or down costs more, so tunnels prefer to stay on one level (world doc 2.3).
static func _link_cost(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length() + 2.5 * absf(a.y - b.y)


func _connect_rooms_v2(rng: RandomNumberGenerator, r0: int, cx: float) -> void:
	var n := rooms.size() - r0
	if n <= 0:
		return
	# The cheapest set of tunnels that reaches every room (Prim's method): nothing needs digging.
	var key := PackedFloat32Array()
	key.resize(n)
	key.fill(INF)
	var parent := PackedInt32Array()
	parent.resize(n)
	parent.fill(-1)
	var done := PackedByteArray()
	done.resize(n)
	key[0] = 0.0
	var edges: Array[Vector2i] = []
	var linked := {}
	for step in n:
		var u := -1
		for j in n:
			if done[j] == 0 and (u < 0 or key[j] < key[u]):
				u = j
		done[u] = 1
		if parent[u] >= 0:
			edges.append(Vector2i(r0 + parent[u], r0 + u))
			linked[Vector2i(mini(parent[u], u), maxi(parent[u], u))] = true
		for j in n:
			if done[j] == 0:
				var cost := _link_cost(rooms[r0 + u].center, rooms[r0 + j].center)
				if cost < key[j]:
					key[j] = cost
					parent[j] = u
	# Loops: a room joins one of its nearest rooms that it isn't joined to yet (a real shortcut).
	for k in V2_LOOPS:
		var i := rng.randi_range(0, n - 1)
		var near := []
		for j in n:
			if j != i and not linked.has(Vector2i(mini(i, j), maxi(i, j))):
				near.append([_link_cost(rooms[r0 + i].center, rooms[r0 + j].center), j])
		if near.is_empty():
			continue
		near.sort_custom(func(x, y): return x[0] < y[0])
		var j: int = near[rng.randi_range(0, mini(2, near.size() - 1))][1]
		linked[Vector2i(mini(i, j), maxi(i, j))] = true
		edges.append(Vector2i(r0 + i, r0 + j))
	var s0 := segments.size()
	for e in edges:
		_dig_passage(rng, e.x, e.y, cx)
	# Dead ends: a wander away from a room that just stops.
	for k in V2_DEAD_ENDS:
		var from_room := r0 + rng.randi_range(0, n - 1)
		var start := mouth(rooms[from_room])
		var angle := rng.randf_range(0, TAU)
		var end := _clamp_inside(start + Vector3(cos(angle), rng.randf_range(-0.25, 0.25), sin(angle)) * rng.randf_range(30, 80), cx)
		_dig_worm_v2(rng, start, end, cx, _pick_kind(rng, start, end, true), 2.0, 2.8, from_room)
	# Side passages (F20, F110): narrower tunnels that branch off the ones above, wander up and down,
	# cross each other, and sometimes go nowhere.
	var s1 := segments.size()
	for k in V2_SIDE:
		var seg: Dictionary = segments[rng.randi_range(s0, s1 - 1)]
		var from: Vector3 = (seg.a + seg.b) * 0.5
		var angle := rng.randf_range(0, TAU)
		var dir := Vector3(cos(angle), rng.randf_range(-0.35, 0.35), sin(angle)).normalized()
		var end := _clamp_inside(from + dir * rng.randf_range(35.0, 110.0), cx)
		_dig_worm_v2(rng, from, end, cx, _pick_kind(rng, from, end, true), 1.8, 2.6)


## A tunnel between two rooms. Just outside a big cavern it pinches into a low or keyhole passage, so
## the cavern opens up all at once when you step in ("squeeze, then wow").
func _dig_passage(rng: RandomNumberGenerator, i: int, j: int, cx: float) -> void:
	var a := mouth(rooms[i])
	var b := mouth(rooms[j])
	var ra := i
	var rb := j
	var cliff := -1
	if made_layout >= 3:
		# One tunnel into most tall caverns comes in high up the wall, with a ledge path down (F231).
		for idx in [i, j]:
			if cliff < 0 and _is_tall(idx) and not rooms[idx].has("cliff") and posmod(idx * 7919 + seed, 10) < 7:
				cliff = idx
		if cliff == i:
			a = _cliff_mouth(i, rooms[j].center)
			ra = -1
			rooms[i].cliff = a
		elif cliff == j:
			b = _cliff_mouth(j, rooms[i].center)
			rb = -1
			rooms[j].cliff = b
	var s0 := segments.size()
	_dig_worm_v2(rng, a, b, cx, _pick_kind(rng, a, b, false), 2.3, 3.3, ra, rb)
	for idx in [i, j]:
		var room: Dictionary = rooms[idx]
		if not room.big:
			continue
		var c: Vector3 = room.center
		var rr: Vector3 = room.radii
		for k in range(s0, segments.size()):
			var sg: Dictionary = segments[k]
			var mid: Vector3 = (sg.a + sg.b) * 0.5
			var e := Vector2((mid.x - c.x) / rr.x, (mid.z - c.z) / rr.z).length()
			if e > 1.0 and e < 1.0 + 16.0 / minf(rr.x, rr.z):
				var level := absf((sg.b as Vector3).y - (sg.a as Vector3).y) < 1.0
				sg.k = LOW if level else KEYHOLE
				sg.h = rng.randf_range(5.0, 8.0) if level else rng.randf_range(2.6, 3.2)
	if cliff >= 0:
		_dig_ledge(cliff, rooms[cliff].cliff)


## Which kind a passage from a to b is. LOW only where it can stay nearly level (rock layers are flat).
func _pick_kind(rng: RandomNumberGenerator, a: Vector3, b: Vector3, side: bool) -> int:
	var level := absf(b.y - a.y) <= 0.12 * Vector2(b.x - a.x, b.z - a.z).length()
	var roll := rng.randf()
	var kind: int
	if side:
		kind = TUBE if roll < 0.25 else (CANYON if roll < 0.5 else (RIFT if roll < 0.7 else LOW))
	else:
		kind = TUBE if roll < 0.3 else (CANYON if roll < 0.5 else (KEYHOLE if roll < 0.7 else LOW))
	if kind == LOW and not level:
		kind = TUBE if side else KEYHOLE
	return kind


## The kind's size number (see the kinds above).
static func _kind_size(rng: RandomNumberGenerator, kind: int) -> float:
	match kind:
		CANYON:
			return rng.randf_range(6.0, 11.0)
		RIFT:
			return rng.randf_range(8.0, 13.0)
		KEYHOLE:
			return rng.randf_range(2.6, 3.4)
		LOW:
			return rng.randf_range(5.0, 9.0)
	return 0.0


## A wandering tunnel of one kind from a to b, made of 6 m pieces. Low passages stay nearly level;
## rifts wander less (cracks run fairly straight).
## `room_a` / `room_b`: the rooms it starts and ends in (-1 = none), for tidying up inside them.
func _dig_worm_v2(rng: RandomNumberGenerator, a: Vector3, b: Vector3, cx: float, kind: int, r_min: float, r_max: float,
		room_a: int = -1, room_b: int = -1) -> void:
	const STEP := 6.0
	var climb := 0.1 if kind == LOW else 0.42
	var wander_amount := 0.35 if kind == RIFT else 0.65
	var h := _kind_size(rng, kind)
	var s0 := segments.size()
	var pos := a
	var guard := 0
	while pos.distance_to(b) > STEP and guard < 300:
		guard += 1
		var dir := (b - pos).normalized()
		var wander := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1))
		dir = (dir + wander * wander_amount).normalized()
		dir.y = clampf(dir.y, -climb, climb)
		var next := _clamp_inside(pos + dir.normalized() * STEP, cx)
		segments.append({a = pos, b = next, r = rng.randf_range(r_min, r_max), k = kind, h = h})
		pos = next
	segments.append({a = pos, b = b, r = rng.randf_range(r_min, r_max), k = kind, h = h})
	if room_a >= 0 or room_b >= 0:
		_trim_in_rooms(s0, room_a, room_b)


## Every tunnel starts in the middle of its room, so a pile of tunnel pieces lay inside each room,
## adding nothing (it's all open air) but slowing the terrain down. The pieces deep inside a room become
## one straight piece from the middle to where the tunnel leaves.
func _trim_in_rooms(s0: int, room_a: int, room_b: int) -> void:
	var seg := segments.slice(s0)
	segments.resize(s0)
	var first := 0
	if room_a >= 0:
		while first < seg.size() - 1 and _deep_inside(seg[first].b, room_a):
			first += 1
	var last := seg.size() - 1
	if room_b >= 0:
		while last > first and _deep_inside(seg[last].a, room_b):
			last -= 1
	var start_a: Vector3 = seg[0].a
	var end_b: Vector3 = seg[seg.size() - 1].b
	for k in range(first, last + 1):
		var s: Dictionary = seg[k]
		if k == first:
			s.a = start_a
		if k == last:
			s.b = end_b
		segments.append(s)


func _deep_inside(p: Vector3, idx: int) -> bool:
	var rm: Dictionary = rooms[idx]
	var q := (p - (rm.center as Vector3)) / (rm.radii as Vector3)
	return Vector2(q.x, q.z).length() < 0.7 and absf(q.y) < 0.8


## Plain caverns and rooms get their real-cave shapes (special places keep theirs). Own dice, so it
## never moves anything else.
func _assign_shapes(r0: int, r1: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 3131 + r0
	for i in range(r0, r1):
		var rm: Dictionary = rooms[i]
		var roll := rng.randf()
		if rm.kind == "cavern":
			rm.shape = SHAPE_FLAT if roll < 0.3 else (SHAPE_FALLEN if roll < 0.6 else SHAPE_DOME)
			if huge_first() and i == 0:
				rm.shape = SHAPE_DOME  # the huge first cavern: a high dome for its star ceiling
		elif rm.kind == "room" and rm.get("hall", false):
			rm.shape = SHAPE_FLAT if roll < 0.45 else (SHAPE_FALLEN if roll < 0.8 else SHAPE_DOME)
		elif rm.kind == "room":
			rm.shape = SHAPE_FLAT if roll < 0.4 else SHAPE_DOME
		match int(rm.get("prop", PROP_NORMAL)):  # (layout 3)
			PROP_WIDE_LOW:
				rm.shape = SHAPE_FLAT  # a flat rock-layer ceiling over a wide floor
			PROP_TALL_NARROW, PROP_TALL_WIDE:
				rm.shape = SHAPE_DOME  # a tall vault (the ledge path follows its wall)


## Layout 2's distance to open air: like _sdf_with, plus the new shapes, and the bumpy-wall noise
## turned down near the floor of narrow passages so they stay open.
func _sdf_with_v2(p: Vector3, room_ids: PackedInt32Array, seg_ids: PackedInt32Array) -> float:
	var d := 1e9
	var scale := 1.0  # how much wall noise is allowed here: a narrow passage within 3 m turns it down
	for i in room_ids:
		d = _smin(d, _room_dist_v2(p, i), BLEND)
	for i in seg_ids:
		var mn := _seg_min[i]
		var mx := _seg_max[i]
		var gap := Vector3(maxf(maxf(mn.x - p.x, p.x - mx.x), 0.0), maxf(maxf(mn.y - p.y, p.y - mx.y), 0.0), maxf(maxf(mn.z - p.z, p.z - mx.z), 0.0))
		if d < 1e8 and gap.length() >= d + BLEND:
			continue
		if _seg_k[i] == TUBE:
			# (the round tube written out here: it's the most common piece and this runs for every voxel)
			var a := _seg_a[i]
			var ab := _seg_b[i] - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			var cp := a + ab * t
			var r := _seg_r[i]
			var td := maxf(p.distance_to(cp) - r, (cp.y - r * 0.6) - p.y)
			var hh := clampf(0.5 + 0.5 * (td - d) / BLEND, 0.0, 1.0)  # _smin(d, td, BLEND)
			d = lerpf(td, d, hh) - BLEND * hh * (1.0 - hh)
			continue
		var sh := _seg_shape(p, i)
		d = _smin(d, sh.x, BLEND)
		if sh.y < 1.0:
			scale = minf(scale, lerpf(1.0, sh.y, clampf(1.0 - maxf(sh.x, 0.0) / 3.0, 0.0, 1.0)))
	if not _cols.is_empty():
		d = _with_columns(p, d)
	if not _bridges.is_empty():
		var bd := _bridges_min(p)
		if bd < 1e8:
			d = -_smin(-d, bd, 2.5)  # soft where it grows out of the walls
			var calm := 0.08 if made_layout >= 11 else 0.25  # (layout 11: thinner bridges, calmer still)
			scale = minf(scale, clampf(calm + absf(bd) / 4.0, calm, 1.0))  # gentle bumps on a bridge: it stays whole
	var s := -d
	if absf(s) < 6.5:
		s += _wall_bumps(p) * scale
		if _style != BLOCKS and not _near_start(p):
			s += _rock_detail(p) * _floor_guard(p, room_ids) * scale
		for i in room_ids:
			var rr := _room_r[i]
			if maxf(rr.x, maxf(rr.y, rr.z)) < 4.0:
				s = maxf(s, rr.x * 0.6 - p.distance_to(_room_c[i]))
	if _near_start(p):
		s = maxf(s, -_start_dist(p))
	return minf(s, _region_dist(p))


func _room_dist_v2(p: Vector3, i: int) -> float:
	var shape := _room_shape[i]
	if shape == SHAPE_DOME:
		return _room_dist(p, i)
	var c := _room_c[i]
	var r := _room_r[i]
	var floor_y := c.y - r.y * 0.55
	if shape == SHAPE_FLAT:
		# Steep walls; the ceiling is a rock layer: flat, tilted the same way as all the layers here.
		var re := Vector3(r.x, r.y * 1.6, r.z)
		var d := ((p - c) / re).length() - 1.0
		d *= minf(re.x, minf(re.y, re.z))
		var ceil_y := floor_y + r.y * 1.25 + (p.x - c.x) * _dip.x + (p.z - c.z) * _dip.y
		return maxf(maxf(d, floor_y - p.y), p.y - ceil_y)
	# Fallen roof: a taller arch, and big fallen blocks on the floor (not in the middle or at the edges,
	# where tunnels come in).
	var re := Vector3(r.x, r.y * 1.3, r.z)
	var d := (((p - c) / re).length() - 1.0) * minf(re.x, minf(re.y, re.z))
	return maxf(d, floor_y + _fallen_block(p, c, r) - p.y)


## How tall the fallen block at p is (0 = open floor). Each noise cell is one block, 1.5 to 5.5 m tall,
## its top sloping down toward its edges, like a broken slab lying at an angle.
func _fallen_block(p: Vector3, c: Vector3, r: Vector3) -> float:
	var e := Vector2((p.x - c.x) / r.x, (p.z - c.z) / r.z).length()
	var fade := smoothstep(0.28, 0.4, e) * (1.0 - smoothstep(0.78, 0.9, e))
	if fade <= 0.0:
		return 0.0
	var cv := _block_noise.get_noise_2d(p.x, p.z)
	if cv < 0.3:
		return 0.0
	var mid := clampf(_block_dist_noise.get_noise_2d(p.x, p.z) + 1.0, 0.0, 1.0)  # 0 = middle of the block
	return (1.5 + (cv - 0.3) * 5.7) * (1.0 - 0.4 * mid) * fade


## Distance to one passage piece (x) and how much wall noise is allowed at p (y).
## TUBE is the old round tube. The others are measured in an upright cross-section (walls stand
## straight up even where the passage slopes), from the passage's floor.
func _seg_shape(p: Vector3, i: int) -> Vector2:
	var k := _seg_k[i]
	if k == TUBE:
		return Vector2(_seg_dist(p, i), 1.0)
	var a := _seg_a[i]
	var ab := _seg_b[i] - a
	var t := clampf(((p.x - a.x) * ab.x + (p.z - a.z) * ab.z) / maxf(ab.x * ab.x + ab.z * ab.z, 0.0001), 0.0, 1.0)
	var lat := Vector2(p.x - (a.x + ab.x * t), p.z - (a.z + ab.z * t)).length()
	var r := _seg_r[i]
	var h := _seg_h[i]
	var v := p.y - (a.y + ab.y * t - r * 0.6)  # height above this passage's floor
	var d: float
	match k:
		CANYON, RIFT:
			var w := clampf(r * (0.75 if k == CANYON else 0.6), 1.5, 2.2)
			var hh := h * 0.5
			var vc := hh - (1.0 if k == CANYON else 1.6)  # sunk a little, so the floor is wide enough
			d = (Vector2(lat / w, (v - vc) / hh).length() - 1.0) * w
		KEYHOLE:
			var slot := (Vector2(lat / 1.35, (v - h * 0.4) / (h * 0.6)).length() - 1.0) * 1.35
			var rt := r * 0.8
			var tube := Vector2(lat, v - (h + rt * 0.55)).length() - rt
			d = minf(slot, tube)
		LOW:
			d = (Vector2(lat / h, (v - 1.5) / 2.1).length() - 1.0) * 2.1
			d = maxf(d, v - LOW_CEIL)
		_:
			d = _seg_dist(p, i)
	d = maxf(d, -v)  # flat floor
	# Near the floor narrow passages keep their walls; from ~2.5 m up the rock can be as rough as anywhere.
	var bumps: float = lerpf(KIND_BUMPS[k], 1.0, clampf((v - 2.5) / 3.0, 0.0, 1.0)) if k != LOW else KIND_BUMPS[k]
	return Vector2(d, bumps)


func _bake_shapes() -> void:
	_corner_cache.clear()  # the shapes change: remembered block corners are out of date
	for arr in [_room_c, _room_r, _room_min, _room_max, _seg_a, _seg_b, _seg_r, _seg_min, _seg_max, _seg_k, _seg_h, _room_shape]:
		arr.clear()
	var pad := Vector3.ONE * (WALL_NOISE_AMP + BLEND + 1.0)
	for room in rooms:
		var shape := int(room.get("shape", SHAPE_DOME))
		var reach: Vector3 = room.radii
		if shape == SHAPE_FLAT:
			reach.y *= 1.6  # (its ellipsoid is taller; the flat ceiling cuts it)
		elif shape == SHAPE_FALLEN:
			reach.y *= 1.3
		_room_c.append(room.center)
		_room_r.append(room.radii)
		_room_shape.append(shape)
		_room_min.append(room.center - reach - pad)
		_room_max.append(room.center + reach + pad)
	for s in segments:
		var k := int(s.get("k", TUBE))
		var h := float(s.get("h", 0.0))
		_seg_a.append(s.a)
		_seg_b.append(s.b)
		_seg_r.append(s.r)
		_seg_k.append(k)
		_seg_h.append(h)
		# How far the shape reaches from its centre line: sideways (x, z), down, up.
		var r := float(s.r)
		var side := r
		var up := r
		match k:
			CANYON, RIFT:
				side = maxf(r, 2.2)
				up = maxf(r, h)
			LOW:
				side = maxf(r, h)
				up = maxf(r, LOW_CEIL)
			KEYHOLE:
				up = h + 1.6 * r
		_seg_min.append(s.a.min(s.b) - Vector3(side, r, side) - pad)
		_seg_max.append(s.a.max(s.b) + Vector3(side, up, side) + pad)
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
	# The old side-boss caverns (the bosses were taken out, owner Nov 19). They're plain caverns now, but keep their old
	# room labels, so old saves' caves keep the same shapes, columns and creatures. Only the Great Hall (an old ruined
	# hall with columns and treasure) is still a special place.
	var cavern_kinds: Array = ["nest_cavern", "great_hall"] if biome == "mossy" else ["silver_vault", "brood_hollow", "lantern_grove"]
	for k in mini(bigs.size(), cavern_kinds.size()):
		var bi: int = bigs[k]
		rooms[bi].kind = cavern_kinds[k]
		var at := find_floor(rooms[bi].center.x, rooms[bi].center.z, rooms[bi].center.y)
		if cavern_kinds[k] == "great_hall":
			_add_poi("great_hall", at, Vector3.UP, bi)
		else:
			_old_spots.append(at)
	# Small rooms: ruins, nests and camps (no nests within 60 m of the start).
	var smalls := []
	for i in range(r0, r1):
		if not rooms[i].big:
			smalls.append(i)
	smalls.sort_custom(func(a, b): return rooms[a].center.distance_to(spawn) > rooms[b].center.distance_to(spawn))
	var plan := ["ruin", "nest", "ruin", "camp", "nest", "ruin", "camp", "nest", "camp", "camp"]
	if made_layout >= 2:
		plan = plan + plan + plan  # 4x bigger areas: 3x the ruins, nests and camps (owner, Nov 17: "yes, add more")
	if made_layout >= 2 and smalls.size() > plan.size():
		# 800 m areas: spread them from far to near, instead of all at the far edges.
		var spread := []
		for j in plan.size():
			spread.append(smalls[roundi(float(j) * (smalls.size() - 1) / float(plan.size() - 1))])
		smalls = spread
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
	if made_layout >= 2:
		_assign_shapes(r0, r1)  # plain caverns and rooms get their real-cave shapes
		_bake_shapes()
	# Where the main boss lair was (the boss is gone, owner Nov 19): still a sealed hollow deep in the rock, with nothing
	# in it, so old saves' caves, places and the first cave's start stay exactly where they were.
	var lair_reach := HALF_SIZE - 35.0  # (165 m in layout 1)
	for attempt in 600:
		var c := Vector3(cx + rng.randf_range(-lair_reach, lair_reach), rng.randf_range(-40, -16), rng.randf_range(-lair_reach, lair_reach))
		if c.distance_to(spawn) < 150.0:
			continue
		var r := Vector3(18, 9, 18)
		if _solid_around(c, r + Vector3.ONE * 6.0):
			rooms.append({center = c, radii = r, big = true, kind = "hollow", sealed = true, biome = biome})
			_old_spots.append(c - Vector3.UP * r.y * 0.55)
			if biome == "mossy":
				_start_away = c - Vector3.UP * r.y * 0.55
			break
	# Crystal geodes (sealed pockets near tunnels) and rune shrines (3 open alcoves, 2 sealed).
	var geodes := 0
	var shrines_open := 0
	var shrines_sealed := 0
	var more := 3 if made_layout >= 2 else 1  # (the same "add more", Nov 17)
	for attempt in 800 * more:
		if geodes >= 6 * more and shrines_open >= 3 * more and shrines_sealed >= 2 * more:
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
		if shrines_open < 3 * more:
			var c: Vector3 = mid + side * (sg.r + 1.2)
			if _far_from_pois(c, 20.0):
				rooms.append({center = c, radii = Vector3(2.8, 2.8, 2.8), big = false, kind = "shrine", sealed = false, biome = biome})
				_add_poi("shrine", c, -side, rooms.size() - 1)
				shrines_open += 1
				continue
		var dist: float = sg.r + rng.randf_range(5.0, 8.0)
		var c := mid + side * dist
		if geodes < 6 * more:
			# Pockets must be bigger than the wall bumpiness (2.2 m), or bumps could close them.
			var gr := rng.randf_range(3.0, 4.5)
			if _solid_around(c, Vector3.ONE * (gr + 2.5)) and _far_from_pois(c, 15.0):
				rooms.append({center = c, radii = Vector3(gr, gr * 0.9, gr), big = false, kind = "geode", sealed = true, biome = biome})
				_add_poi("geode", c, -side, rooms.size() - 1)
				geodes += 1
				continue
		if shrines_sealed < 2 * more and _solid_around(c, Vector3.ONE * 5.3) and _far_from_pois(c, 20.0):
			rooms.append({center = c, radii = Vector3(2.8, 2.8, 2.8), big = false, kind = "shrine", sealed = true, biome = biome})
			_add_poi("shrine", c, -side, rooms.size() - 1)
			shrines_sealed += 1
	if made_layout >= 2:
		_ramp_high_holes(r0, r1, cx)
	_bake_shapes()


## F141 (owner, Nov 17: "yes, fix it"): a tunnel that passes through a room can open high up in its wall, out of
## reach. For each such hole, a gentle ramp tunnel is dug through the rock beside the wall, from the hole down to the
## room's floor (no steeper than other tunnels). Layout 2 only; uses no dice, so nothing else moves.
const HIGH_HOLE := 3.0  ## an opening whose bottom is more than this above the room's floor is out of reach
const RAMP_SLOPE := 0.38
const RAMP_R := 1.9

func _ramp_high_holes(r0: int, r1: int, cx: float) -> void:
	var seg_count := segments.size()
	for ri in range(r0, r1):
		var room: Dictionary = rooms[ri]
		var rad: Vector3 = room.radii
		if room.get("sealed", false) or minf(rad.x, rad.z) < 6.0:
			continue
		var c: Vector3 = room.center
		var floor_y := c.y - rad.y * 0.55
		var mo := mouth(room)
		var holes: Array[Vector3] = []
		for si in seg_count:
			var sg: Dictionary = segments[si]
			var a: Vector3 = sg.a
			var b: Vector3 = sg.b
			if a.distance_to(mo) < 1.0 or b.distance_to(mo) < 1.0 or sg.get("ledge", false):
				continue  # starts or ends in this room, at floor height (or it's a ledge path down a cliff)
			if room.has("cliff") and ((room.cliff as Vector3).distance_to(a) < 14.0 or (room.cliff as Vector3).distance_to(b) < 14.0):
				continue  # the cliff tunnel: high on purpose, its ledge path is the way down
			var mn := a.min(b) - Vector3.ONE * 3.0
			var mx := a.max(b) + Vector3.ONE * 3.0
			if c.x + rad.x < mn.x or c.x - rad.x > mx.x or c.z + rad.z < mn.z or c.z - rad.z > mx.z 					or c.y + rad.y < mn.y or c.y - rad.y > mx.y:
				continue
			for f in 11:
				var p := a.lerp(b, f / 10.0)
				var q := ((p - c) / rad).length()
				if q < 1.0 and q > 0.75:
					if p.y - float(sg.r) - floor_y > HIGH_HOLE:
						var far := true
						for h in holes:
							far = far and h.distance_to(p) > 10.0
						if far:
							holes.append(p)
					break
		for e in holes:
			_dig_ramp(e, c, rad, floor_y, cx)


## From the hole e round the room's wall and down to its floor: two pieces, the middle pushed out into the rock.
func _dig_ramp(e: Vector3, c: Vector3, rad: Vector3, floor_y: float, cx: float) -> void:
	var drop := e.y - (floor_y + 1.9)  # down to mouth height (tunnels sit there in every room)
	var run := maxf(drop / RAMP_SLOPE, 8.0)
	var ang0 := atan2((e.z - c.z) / rad.z, (e.x - c.x) / rad.x)
	var turn := run / maxf(minf(rad.x, rad.z), 1.0)  # roughly how far round the wall (radians) the ramp needs
	var ang1 := ang0 + turn
	var mid_ang := (ang0 + ang1) * 0.5
	var push := RAMP_R + 1.5
	var mid := Vector3(c.x + cos(mid_ang) * (rad.x + push), (e.y + floor_y + 1.9) * 0.5, c.z + sin(mid_ang) * (rad.z + push))
	var end := Vector3(c.x + cos(ang1) * rad.x * 0.85, floor_y + 1.9, c.z + sin(ang1) * rad.z * 0.85)
	mid = _clamp_inside(mid, cx)
	segments.append({a = e, b = mid, r = RAMP_R, k = TUBE, h = 0.0, ramp = true})
	segments.append({a = mid, b = end, r = RAMP_R, k = TUBE, h = 0.0, ramp = true})


func _add_poi(type: String, pos: Vector3, normal: Vector3, room: int) -> void:
	pois.append({id = pois.size(), type = type, pos = pos, normal = normal, room = room, biome = _poi_biome})


func _far_from_pois(p: Vector3, d: float) -> bool:
	for q in pois:
		if q.pos.distance_to(p) < d:
			return false
	for q in _old_spots:
		if q.distance_to(p) < d:
			return false
	return true


## True if a box of half-size `half` around `c` is rock everywhere we sample.
func _solid_around(c: Vector3, half: Vector3) -> bool:
	if _region_dist(c) < half.x + 4.0:
		return false
	for x in [-1.0, 0.0, 1.0]:
		for y in [-1.0, 0.0, 1.0]:
			for z in [-1.0, 0.0, 1.0]:
				if _smooth_at(c + Vector3(x, y, z) * half) >= -0.5:  # planning: the plain shape, before blocks
					return false
	return true


## Special places of one type ("" biome = all biomes).
func pois_of(type: String, biome: String = "") -> Array:
	return pois.filter(func(p): return p.type == type and (biome == "" or p.biome == biome))


## Which biome a spot is in (by its x position; the slab counts as Mossy's side up to its middle).
static func biome_at(p: Vector3) -> String:
	return "fungal" if p.x >= SLAB_X + SLAB_W * 0.5 else "mossy"


# ---------------------------------------------------------------- queries

# ---------------------------------------------------------------- chunky rock (F19/F109)

## Chunky rock, like 7 Days to Die (owner, Nov 16): every 1 m point of the cave is either rock or air,
## with a random strength between BLOCK_MIN and 1 (always the same for the same point). The terrain
## mesher draws its surface between rock and air points, so it comes out as lopsided 1 m blocks with
## cut corners instead of round shapes.
const BLOCK_MIN := 0.5
## Farther than this from a wall, the blocky field has the same sign as the smooth shape, so sdf_at
## just returns the smooth distance (fast for marching). Nearer, it blends the 8 block points.
const NEAR_BLOCKS := 2.0
const BLEND_SAFE := 0.6  ## near a wall, sdf_at = blended block values x this (a safe distance to step)
const BLOCK_SLACK := 1.5  ## how much nearer the chunky wall can be than the smooth shape (blocks + jagged edges)
var _corner_cache := {}  ## main thread only (the terrain's worker threads use generate_block)


## Cracked, chunky walls: right at a wall or ceiling, single blocks may stick out or be missing,
## up to JAG/2 m from the smooth shape. Floors stay walkable (no random blocks on them).
const JAG := 1.6


## The value the terrain stores at grid point `g`. `s` = the smooth shape there, `s_up` = 1 m above
## (to tell floors from walls). Rock = negative, air = positive.
func block_value(s: float, g: Vector3i, s_up: float) -> float:
	var m := BLOCK_MIN + (1.0 - BLOCK_MIN) * _hash01(g)
	var edge := 0.0
	if absf(s) < JAG * 0.5 and not _near_start(Vector3(g)):  # the room you wake up in stays clean
		var wall := clampf((0.92 - (s_up - s)) / 0.35, 0.0, 1.0)  # flat floor = 0; slopes, walls, ceilings up to 1
		edge = (_hash01(g + Vector3i(911, -337, 1777)) - 0.5) * JAG * wall
	return -m if s < edge else m


## A fixed random number 0..1 for a grid point (same seed, same point = same number).
func _hash01(g: Vector3i) -> float:
	var h: int = (g.x * 73856093) ^ (g.y * 19349663) ^ (g.z * 83492791) ^ (seed * 2654435761)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


func _corner(g: Vector3i) -> float:
	var v = _corner_cache.get(g)
	if v == null:
		if _corner_cache.size() > 400000:
			_corner_cache.clear()
		v = block_value(_smooth_at(Vector3(g)), g, _smooth_at(Vector3(g + Vector3i.UP)))
		_corner_cache[g] = v
	return v


## Signed distance: positive = open air, negative = inside rock. Near walls it follows the chunky
## blocks exactly like the terrain does (along every 1 m edge), so things placed on walls and floors
## sit on the real surface.
func sdf_at(p: Vector3) -> float:
	var s := _smooth_at(p)
	if _style != BLOCKS:
		return s
	if absf(s) > NEAR_BLOCKS:
		# Far from a wall: the real (chunky) wall may be up to BLOCK_SLACK closer than the smooth shape,
		# so say that much less. Searches that step by this distance never jump over a block.
		return s - BLOCK_SLACK if s > 0.0 else s + BLOCK_SLACK
	var g := Vector3i(p.floor())
	var f := p - Vector3(g)
	var x00 := lerpf(_corner(g), _corner(g + Vector3i(1, 0, 0)), f.x)
	var x10 := lerpf(_corner(g + Vector3i(0, 1, 0)), _corner(g + Vector3i(1, 1, 0)), f.x)
	var x01 := lerpf(_corner(g + Vector3i(0, 0, 1)), _corner(g + Vector3i(1, 0, 1)), f.x)
	var x11 := lerpf(_corner(g + Vector3i(0, 1, 1)), _corner(g + Vector3i(1, 1, 1)), f.x)
	# A block value of 1 can be only 0.67 m from the surface (next to a 0.5 point), so the blended value
	# is scaled down: searches that step by it never jump past the tip of a block.
	return lerpf(lerpf(x00, x10, f.y), lerpf(x01, x11, f.y), f.z) * BLEND_SAFE


## The smooth shape before it's cut into blocks (positive = air).
func _smooth_at(p: Vector3) -> float:
	var cell = _grid.get(Vector3i((p / GRID).floor()))
	if cell == null:
		var s := minf(SOLID_FILL, _region_dist(p))  # no cave within 6 m: solid rock (like generate_block)
		if _near_start(p):
			s = minf(maxf(s, -_start_dist(p)), _region_dist(p))
		if not dungeons.is_empty():
			s = minf(maxf(s, _dungeon_sdf(p)), _region_dist(p))
		return s
	return _sdf_with(p, cell[0], cell[1])


## What rock is at p (only meaningful inside rock).
func material_at(p: Vector3i) -> int:
	var pf := Vector3(p)
	var wall := _wall_rock(pf)
	if wall >= 0:
		return wall
	if not dungeons.is_empty() and in_dungeon_stone(pf):
		return Mat.DWARF
	var pal: Dictionary = Mat.PALETTES[biome_at(pf)]
	if made_layout >= 13 and (_near_start(pf) or in_start_plug(pf)):
		return pal.rock  # the room you wake in and its wall: all rock, so you see how breaking rock works (owner, Nov 18)
	if in_start_plug(pf):
		return Mat.DIRT
	if _is_ore(p):
		return pal.ore
	if _is_tin(p):
		return Mat.TIN
	var s := _smooth_at(pf)
	if _smooth_at(pf + Vector3.UP) > 0.0:
		return Mat.PATH if is_trail_floor(p) else pal.floor
	if _smooth_at(pf + Vector3.UP * 2.0) > 0.0:
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
	if made_layout >= 2:
		var s2 := _sdf_with_v2(p, room_ids, seg_ids)
		if not dungeons.is_empty():
			s2 = minf(maxf(s2, _dungeon_sdf(p)), _region_dist(p))
		return s2
	var d := 1e9
	for i in room_ids:
		d = _smin(d, _room_dist(p, i), BLEND)
	for i in seg_ids:
		# Quick skip: a tunnel whose box is farther than (closest so far + blend) can't change
		# the answer (the soft blend only reaches BLEND meters). Many tunnels meet in caverns.
		var mn := _seg_min[i]
		var mx := _seg_max[i]
		var gap := Vector3(maxf(maxf(mn.x - p.x, p.x - mx.x), 0.0), maxf(maxf(mn.y - p.y, p.y - mx.y), 0.0), maxf(maxf(mn.z - p.z, p.z - mx.z), 0.0))
		if d < 1e8 and gap.length() >= d + BLEND:
			continue
		d = _smin(d, _seg_dist(p, i), BLEND)
	# Bumps only matter near a wall (they move it by 3 m at most). Deep inside rock or far out
	# in the air, skip them: much faster to build, and the wall ends up exactly the same.
	var s := -d
	if absf(s) < 6.5:
		s += _wall_bumps(p)
		if _style != BLOCKS and not _near_start(p):
			s += _rock_detail(p) * _floor_guard(p, room_ids)
		# Small rooms (shrines, geodes) keep an open core: wall bumps up to 2.8 m could otherwise fill a
		# 2.8 m room, and the chunky blocks would close what's left (F109).
		for i in room_ids:
			var rr := _room_r[i]
			if maxf(rr.x, maxf(rr.y, rr.z)) < 4.0:
				s = maxf(s, rr.x * 0.6 - p.distance_to(_room_c[i]))
	if _near_start(p):
		s = maxf(s, -_start_dist(p))
	return minf(s, _region_dist(p))


## How much the wall is pushed in or out at p. Round parts: smooth bumps. Rocky parts:
## angular facets, more on walls and ceilings than on floors so you can still walk.
func _wall_bumps(p: Vector3) -> float:
	var round_bumps := _wall_noise.get_noise_3dv(p) * WALL_NOISE_AMP
	var rocky := rockiness_at(p)
	if rocky <= 0.0:
		return round_bumps
	# Cellular noise is mostly near -0.8 (range -1..0): centered so walls stay put on average,
	# with angular ridges cutting in and flat faces jutting out.
	var facets := (_rock_noise.get_noise_3dv(p) + 0.8) * ROCKY_AMP
	return lerpf(round_bumps, facets + round_bumps * 0.35, rocky)


## How much nearer a wall can be than sdf_at says, right where rock slabs and ledges step
## (searches that step by the distance subtract this so they never jump past an edge).
func march_slack() -> float:
	match _style:
		SLABS: return SLAB_AMP
		LEDGES: return LEDGE_AMP
		MIXED: return SLAB_AMP * 0.6 + LEDGE_AMP * 0.7 + CHIP_AMP
	return 0.0


## Broken-stone detail for the rock styles (meters the wall moves; + = more air).
func _rock_detail(p: Vector3) -> float:
	match _style:
		SLABS:
			return _slab_noise.get_noise_3dv(p) * SLAB_AMP
		LEDGES:
			return _ledge(p)
		MIXED:
			return _slab_noise.get_noise_3dv(p) * SLAB_AMP * 0.6 + _ledge(p) * 0.7 + (_chip_noise.get_noise_3dv(p) + 0.8) * CHIP_AMP
	return 0.0


## Stacked rock layers: each ~1 m layer steps in or out a little; the layers tilt and wander.
func _ledge(p: Vector3) -> float:
	var warp := _layer_noise.get_noise_2d(p.x * 0.04, p.z * 0.04) * 2.5
	warp -= p.x * _dip.x + p.z * _dip.y  # layout 2: the layers tilt with the flat ceilings (0 in layout 1)
	var layer := floorf((p.y + warp) / LAYER_H)
	return _layer_noise.get_noise_1d(layer * 13.7 + 0.5) * LEDGE_AMP


## Less detail right at a cavern's floor, so floors stay walkable (no knee-high steps).
func _floor_guard(p: Vector3, room_ids: PackedInt32Array) -> float:
	for i in room_ids:
		var c := _room_c[i]
		var r := _room_r[i]
		var fy := c.y - r.y * 0.55
		if p.y < fy + 1.2 and p.y > fy - 1.5:
			var q := Vector2((p.x - c.x) / r.x, (p.z - c.z) / r.z)
			if q.length() < 0.95:
				return 0.2
	return 1.0


## 0 = smooth and round, 1 = sharp and rocky (soft blend between big patches).
func rockiness_at(p: Vector3) -> float:
	return clampf(_style_noise.get_noise_3dv(p) * 4.0 + 0.5, 0.0, 1.0)


## For tests: a z where the Mossy/Fungal border has no gate tunnel through it.
static func gate_free_z(p_seed: int) -> float:
	var c := CaveMaker.new(p_seed)
	for z in [0.0, 60.0, -60.0, 120.0, -120.0, 30.0, -30.0]:
		var clear := true
		for g in c.gates:
			if absf((g.pos as Vector3).z - z) < 25.0:
				clear = false
		if clear:
			return z
	return 0.0


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


## The Copper Deeps: of Mossy's rooms (0..count-1), the ones that are both far from where you start and
## low down. Picked from the cave's own layout, so the same seed always gives the same Deeps.
func _pick_deeps(count: int) -> void:
	var scored := []
	for i in count:
		var rm: Dictionary = rooms[i]
		if rm.get("biome", "mossy") != "mossy" or rm.get("sealed", false):
			continue
		var c: Vector3 = rm.center
		var far := Vector2(c.x - spawn_point.x, c.z - spawn_point.z).length()
		var score := far + (spawn_point.y - c.y) * 1.5
		if made_layout >= 2:
			# 800 m areas: a real trip (140-320 m), not the far corner; lower = better.
			score = (spawn_point.y - c.y) * 1.5 + (200.0 if far >= 140.0 and far <= 320.0 else -absf(far - 230.0))
		scored.append([score, i])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	for k in mini(DEEPS_COUNT, scored.size()):
		var rm: Dictionary = rooms[scored[k][1]]
		var rr: Vector3 = rm.radii
		deeps.append({center = rm.center, reach = maxf(rr.x, maxf(rr.y, rr.z)) + 6.0, room = scored[k][1]})


func in_deeps(p: Vector3) -> bool:
	for d in deeps:
		if p.distance_to(d.center) < d.reach:
			return true
	return false


func _is_ore(p: Vector3i) -> bool:
	var cell := Vector3(floori(p.x / float(ORE_CELL)), floori(p.y / float(ORE_CELL)), floori(p.z / float(ORE_CELL)))
	var n := _ore_noise.get_noise_3dv(cell * ORE_CELL + Vector3.ONE * (ORE_CELL * 0.5))
	# Deeper = a bit more copper.
	if p.x < SLAB_X + SLAB_W * 0.5:
		# Mossy Hollows: copper only in the Copper Deeps (F115).
		return in_deeps(Vector3(p)) and n > DEEPS_THRESHOLD
	var depth_bonus := clampf((-p.y) / 64.0, 0.0, 1.0) * 0.08
	return n + depth_bonus > ORE_THRESHOLD


## Tin (F697): only in Mossy Hollows (Zone 1), decided on the same 2 m grid as copper, never where copper is, and
## never in or near anything built (`is_reserved`: ruins, towers, dungeons, their paths and stairs; below their floors too).
func _is_tin(p: Vector3i) -> bool:
	if p.x >= SLAB_X + SLAB_W * 0.5:
		return false
	var cell := Vector3(floori(p.x / float(ORE_CELL)), floori(p.y / float(ORE_CELL)), floori(p.z / float(ORE_CELL)))
	var mid := cell * ORE_CELL + Vector3.ONE * (ORE_CELL * 0.5)
	if _tin_noise.get_noise_3dv(mid) <= TIN_THRESHOLD:
		return false
	return not tin_kept_clear(mid)


## Is p ground where tin may never grow? Built places, from a little under their floors to over their tops, and
## the special places (camps, shrines, halls...).
func tin_kept_clear(p: Vector3) -> bool:
	# (tin is decided per 2 m block, so look a little above and below its middle too)
	if is_reserved(p, TIN_KEEP_CLEAR) or is_reserved(p + Vector3.UP * 3.0, TIN_KEEP_CLEAR) or is_reserved(p - Vector3.UP * 2.5, TIN_KEEP_CLEAR):
		return true
	for q in pois:
		if p.distance_squared_to(q.pos) < TIN_POI_CLEAR * TIN_POI_CLEAR:
			return true
	return false


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
	if made_layout >= 2 and size == Vector3i.ONE * GRID and origin % GRID == Vector3i.ZERO:
		# Layout 2 has thousands of tunnel pieces: the lookup grid already lists the ones near this block
		# (no entry = nothing near = solid rock).
		var cell = _grid.get(Vector3i(origin / GRID))
		if cell != null:
			room_ids = cell[0]
			seg_ids = cell[1]
	else:
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
	var blocky := _style == BLOCKS
	var in_dg := not dungeons.is_empty() and _overlaps_dungeon(lo, hi)
	var trail_near := _trail_near_box(bmin, bmax)
	var all_rock := room_ids.is_empty() and seg_ids.is_empty() and not in_dg
	if not all_rock and made_layout >= 2 and one_biome and not near_start and not blocky and not in_dg:
		# Shapes are listed nearby, but if the middle of the block is far inside rock, so is all of it:
		# half the block's diagonal (13.9 m) + the most the wall noise and rock detail move a wall (~5 m)
		# + the soft blend (3 m).
		all_rock = _sdf_with(bmin + Vector3(size) * 0.5, room_ids, seg_ids) < -22.0
	if all_rock and one_biome and not near_start:
		# Solid rock block: fast path.
		buf.fill_f(SOLID_FILL, SDF)
		buf.fill(pal.rock, IDX)
		_fill_ore(buf, origin, size, pal.ore)
		if pal.rock == Mat.STONE:
			_fill_tin(buf, origin, size)
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
	if made_layout >= 2 and not blocky and coarse_blocks:
		_coarse_sdf(grid, origin, size, room_ids, seg_ids)
	else:
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
				var bv := block_value(s, Vector3i(origin.x + x, origin.y + y, origin.z + z), grid[base + y + 1]) if blocky else s
				buf.set_voxel_f(bv, x, y, z, SDF)  # chunky rock
				if bv > 0.0:
					buf.set_voxel(p_rock, x, y, z, IDX)  # air: material unused
					continue
				var pi := Vector3i(origin.x + x, origin.y + y, origin.z + z)
				var m: int = p_rock
				var wall := _wall_rock(Vector3(pi)) if touches_border else -1
				if wall >= 0:
					m = wall
				elif in_dg and in_dungeon_stone(Vector3(pi)):
					m = Mat.DWARF  # old dwarf stone: a dungeon's walls (no pickaxe breaks it)
				elif near_start and made_layout >= 13 and (_near_start(Vector3(pi)) or in_start_plug(Vector3(pi))):
					m = p_rock  # the room you wake in: all rock (owner, Nov 18; the same rule as material_at)
				elif near_start and in_start_plug(Vector3(pi)):
					m = Mat.DIRT
				elif _is_ore(pi):
					m = p_ore
				elif p_rock == Mat.STONE and _is_tin(pi):
					m = Mat.TIN
				elif grid[base + y + 1] > 0.0:
					m = Mat.PATH if trail_near and is_trail_floor(pi) else p_floor
				elif grid[base + y + 2] > 0.0:
					m = p_under
				elif s > -3.0 and _is_patch(Vector3(pi), p_patch):
					m = p_patch
				elif s > -2.5 and _dirt_noise.get_noise_3dv(Vector3(pi)) > 0.35:
					m = p_under
				buf.set_voxel(m, x, y, z, IDX)
			gi += col


## Layout 2 speed (F211): blocks near caves are measured on a coarse 2 m net first. A 2 m box whose 8 corners are all
## deep in rock (or all well in the air) can't hold a wall, so its inside is blended from the corners; only boxes near
## a wall measure every voxel. Margins: the wall can move at most ~1.5 m per metre, half a box's diagonal is 1.73 m,
## and voxels down to 3 m inside the rock still need their exact depth (moss patches, dirt), so rock boxes need every
## corner below -6 m and air boxes above +3 m. The tests compare this against measuring every voxel.
static var coarse_blocks := true  ## false = measure every voxel (for the comparison test)
const COARSE := 2
const COARSE_ROCK := -6.0
const COARSE_AIR := 3.0


func _coarse_sdf(grid: PackedFloat32Array, origin: Vector3i, size: Vector3i, room_ids: PackedInt32Array, seg_ids: PackedInt32Array) -> void:
	var sx := size.x
	var col := size.y + 2  # voxels per column in `grid` (one extra layer on top, like the full pass)
	var sz := size.z
	var nx := sx / COARSE + 1
	var ny := (col - 1 + COARSE - 1) / COARSE + 1  # net points cover y = 0 .. col-1 (and a bit above)
	var nz := sz / COARSE + 1
	var net := PackedFloat32Array()
	net.resize(nx * ny * nz)
	var o := Vector3(origin)
	for k in nz:
		for i in nx:
			for j in ny:
				net[(k * nx + i) * ny + j] = _sdf_with(o + Vector3(i * COARSE, j * COARSE, k * COARSE), room_ids, seg_ids)
	var inv := 1.0 / float(COARSE)
	for k in nz - 1:
		for i in nx - 1:
			for j in ny - 1:
				var c000 := net[(k * nx + i) * ny + j]
				var c010 := net[(k * nx + i) * ny + j + 1]
				var c100 := net[(k * nx + i + 1) * ny + j]
				var c110 := net[(k * nx + i + 1) * ny + j + 1]
				var c001 := net[((k + 1) * nx + i) * ny + j]
				var c011 := net[((k + 1) * nx + i) * ny + j + 1]
				var c101 := net[((k + 1) * nx + i + 1) * ny + j]
				var c111 := net[((k + 1) * nx + i + 1) * ny + j + 1]
				var hi := maxf(maxf(maxf(c000, c010), maxf(c100, c110)), maxf(maxf(c001, c011), maxf(c101, c111)))
				var lo := minf(minf(minf(c000, c010), minf(c100, c110)), minf(minf(c001, c011), minf(c101, c111)))
				var blend := hi < COARSE_ROCK or lo > COARSE_AIR
				for dz in COARSE:
					var z := k * COARSE + dz
					if z >= sz:
						break
					var fz := dz * inv
					for dx in COARSE:
						var x := i * COARSE + dx
						if x >= sx:
							break
						var fx := dx * inv
						var base := (z * sx + x) * col
						for dy in COARSE:
							var y := j * COARSE + dy
							if y >= col:
								break
							if blend:
								var fy := dy * inv
								var a := lerpf(lerpf(c000, c100, fx), lerpf(c001, c101, fx), fz)
								var b := lerpf(lerpf(c010, c110, fx), lerpf(c011, c111, fx), fz)
								grid[base + y] = lerpf(a, b, fy)
							else:
								grid[base + y] = _sdf_with(o + Vector3(x, y, z), room_ids, seg_ids)


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


func _fill_tin(buf: VoxelBuffer, origin: Vector3i, size: Vector3i) -> void:
	for cz in range(0, size.z, ORE_CELL):
		for cx in range(0, size.x, ORE_CELL):
			for cy in range(0, size.y, ORE_CELL):
				var p := origin + Vector3i(cx, cy, cz)
				if not _is_ore(p) and _is_tin(p):
					var mn := Vector3i(cx, cy, cz)
					buf.fill_area(Mat.TIN, mn, (mn + Vector3i.ONE * ORE_CELL).min(size), VoxelBuffer.CHANNEL_INDICES)


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
