class_name BlueprintLibrary
## The ready-made blueprints that come with the game (building polish spec §7). Built here in
## code from the piece catalog, so they only ever use real pieces. Simple for now (the owner:
## "later we will have bigger and more elaborate").
##
## Coordinates: like every blueprint, relative to the box's bottom centre; the FRONT is +z
## (doors face +z, and the Builder's Chest appears in front). Pieces sit on a 1 m grid; 2 m pieces.
## Every cell of the box is marked "air", so placed inside rock the chest carves the room out first.

const IDS := ["delvers_hut", "miners_homestead", "stone_hall", "forge_workshop", "watchtower_cabin", "stone_watchtower",
	"stone_outpost", "wooden_watchtower"]
## Known from the very start (F161): you place them and bring the materials. The rest are learned from
## Old Blueprints found in ruins (F98).
const STARTER := ["delvers_hut"]
## Learned only by rebuilding a ruin (owner, Nov 19), never from an Old Blueprint page.
const REBUILD_ONLY := ["wooden_watchtower"]
const NAMES := {
	"delvers_hut": "Delver's Hut",
	"miners_homestead": "Miner's Homestead",
	"stone_hall": "Stone Hall",
	"forge_workshop": "Forge Workshop",
	"watchtower_cabin": "Watchtower & Cabin",
	"stone_watchtower": "Stone Watchtower",
	"stone_outpost": "Stone Outpost",
	"wooden_watchtower": "Wooden Watchtower",
}

const WOOD := "plank_root"
const STONE := "cut_stone"
const BRICK := "clay_brick"
const COPPER := "copper_ingot"

var _bp: Blueprint


static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in IDS:
		out.append({id = id, name = NAMES[id], file = "res://blueprints/%s.dwbp" % id})
	return out


static func make(id: String) -> Blueprint:
	var lib := BlueprintLibrary.new()
	match id:
		"delvers_hut": lib._delvers_hut()
		"miners_homestead": lib._homestead()
		"stone_hall": lib._stone_hall()
		"forge_workshop": lib._forge()
		"watchtower_cabin": lib._watchtower()
		"stone_watchtower": lib._stone_watchtower()
		"stone_outpost": lib._stone_outpost()
		"wooden_watchtower":  # (owner, Nov 19: rebuilding the ruined tower with wood teaches this one)
			lib._stone_watchtower()
			lib._to_wood()
		_: return null
	lib._bp.name = NAMES[id]
	lib._bp.author = "Dwarf Game"
	lib._bp.source = "ancient"
	return lib._bp


# ---------------------------------------------------------------- the buildings

## F161, the starter hut (Delver's Shack pieces), made bigger on Nov 16 (owner: two stories, a less simple
## shape, the yard closed off). A two-story main house (8 x 4 m) with a peaked roof; a one-story wing coming
## forward on the left with its own peaked roof running into the house wall; between them a yard closed by
## railings, with an entrance gap. Round front door (steps) at the front of the wing, a second door from the
## yard into the house (steps), stairs inside up to the second floor. All on log-leg foundations (they reach
## the ground on uneven floors). No copper anywhere: it can be built from day one. Empty inside: you furnish it.
## Box: x -4..4, z -5..5. House cells x -3|-1|1|3, z -4|-2. Wing cells x -3|-1, z 0|2. Yard x 0..4, z -1..3.
func _delvers_hut() -> void:
	_start(Vector3(8, 7, 10))
	for x in [-3, -1, 1, 3]:
		for z in [-4, -2]:
			_add("foundation", WOOD, Vector3(x, 0, z), 0)
	for x in [-3, -1]:
		for z in [0, 2]:
			_add("foundation", WOOD, Vector3(x, 0, z), 0)
	_add("foundation_steps", WOOD, Vector3(-3, 0, 4), 0)  # up to the round front door
	_add("foundation_steps", WOOD, Vector3(3, 0, 0), 0)   # from the yard up to the house door
	var y := 1.0
	# --- ground floor: the house
	_wall_x("wall", -3, -5, y, WOOD)
	_wall_x("window_wall", -1, -5, y, WOOD)
	_wall_x("window_wall", 1, -5, y, WOOD)
	_wall_x("wall", 3, -5, y, WOOD)
	_wall_z("wall", -4, -4, y, WOOD)
	_wall_z("window_wall", -4, -2, y, WOOD)
	_wall_z("window_wall", 4, -4, y, WOOD)
	_wall_z("wall", 4, -2, y, WOOD)
	_wall_x("window_wall", 1, -1, y, WOOD)        # facing the yard
	_wall_x("doorway", 3, -1, y, WOOD)            # the yard door
	_add("door", WOOD, Vector3(3, y, -1), 0)
	# --- ground floor: the wing (open into the house at the back)
	_wall_z("window_wall", -4, 0, y, WOOD)
	_wall_z("wall", -4, 2, y, WOOD)
	_wall_z("wall", 0, 0, y, WOOD)
	_wall_z("window_wall", 0, 2, y, WOOD)
	_wall_x("doorway", -3, 3, y, WOOD)            # the round front door
	_add("door", WOOD, Vector3(-3, y, 3), 0)
	_wall_x("window_wall", -1, 3, y, WOOD)
	# --- stairs in the house's front-left room, climbing to the back, up to the second floor
	_add("stairs", WOOD, Vector3(-3, y, -2), 0)
	# --- second floor over the house (a hole over the stairs, a railing round it)
	var y2 := y + 2.0
	for x in [-3, -1, 1, 3]:
		for z in [-4, -2]:
			if not (x == -3 and z == -2):
				_add("floor", WOOD, Vector3(x, y2, z), 0)
	var y3 := y2 + 0.25
	_wall_z("railing", -2, -2, y3, WOOD)
	_wall_x("wall", -3, -5, y3, WOOD)
	_wall_x("window_wall", -1, -5, y3, WOOD)
	_wall_x("window_wall", 1, -5, y3, WOOD)
	_wall_x("wall", 3, -5, y3, WOOD)
	_wall_x("wall", -3, -1, y3, WOOD)            # behind the wing's roof
	_wall_x("wall", -1, -1, y3, WOOD)
	_wall_x("window_wall", 1, -1, y3, WOOD)      # looking down into the yard
	_wall_x("window_wide", 3, -1, y3, WOOD)
	_wall_z("window_wall", -4, -4, y3, WOOD)
	_wall_z("wall", -4, -2, y3, WOOD)
	_wall_z("wall", 4, -4, y3, WOOD)
	_wall_z("window_wall", 4, -2, y3, WOOD)
	# --- the house roof: peaked, ridge along x, gables at both ends
	var top := y3 + 2.0
	for x in [-3, -1, 1, 3]:
		_add("roof_26", WOOD, Vector3(x, top, -2), 0)   # front slope
		_add("roof_26", WOOD, Vector3(x, top, -4), 2)   # back slope
	for side in [-4, 4]:
		_add("gable_26", WOOD, Vector3(side, top, -2), 1)
		_add("gable_26", WOOD, Vector3(side, top, -4), 3)
	# --- the wing roof: peaked, ridge along z, running into the house wall; gables over the front door
	var wtop := y + 2.0
	for z in [0, 2]:
		_add("roof_26", WOOD, Vector3(-3, wtop, z), 3)  # left slope
		_add("roof_26", WOOD, Vector3(-1, wtop, z), 1)  # right slope
	_add("gable_26", WOOD, Vector3(-3, wtop, 3), 0)
	_add("gable_26", WOOD, Vector3(-1, wtop, 3), 2)
	# --- the yard: railings round it, a gap at the front-left to walk in
	_wall_z("railing", 4, 0, 0.0, WOOD)
	_wall_z("railing", 4, 2, 0.0, WOOD)
	_wall_x("railing", 3, 3, 0.0, WOOD)
	# No furniture: you furnish it yourself (owner, Nov 16).


# ---------------------------------------------------------------- the four found in ruins

## Carved into the mountain: a front hall with 2 columns, a door and 2 windows; a bedroom and a
## storage room behind it, each through its own doorway.
func _homestead() -> void:
	_start(Vector3(10, 3, 10))
	_floors(-3, -1, 3, 5, 0.0, STONE)        # hall
	_floors(-5, -5, -1, -1, 0.0, WOOD)       # bedroom
	_floors(1, -5, 5, -1, 0.0, STONE)        # storage
	var y := 0.25
	# Hall: front wall (doorway in the middle, windows on the sides), side walls.
	_wall_x("window_wall", -2, 5, y, STONE)
	_wall_x("doorway", 0, 5, y, STONE)
	_add("door", WOOD, Vector3(0, y, 5), 0)
	_wall_x("window_wall", 2, 5, y, STONE)
	for z in [0, 2, 4]:
		_wall_z("wall", -3, z, y, STONE)
		_wall_z("wall", 3, z, y, STONE)
	# Back of the hall: doorways into the two rooms, a wall in the middle.
	_wall_x("doorway", -2, -1, y, WOOD)
	_wall_x("wall", 0, -1, y, STONE)
	_wall_x("doorway", 2, -1, y, STONE)
	# Bedroom and storage room walls.
	_wall_x("wall", -4, -1, y, WOOD)
	_wall_x("wall", 4, -1, y, STONE)
	for x in [-4, -2]:
		_wall_x("wall", x, -5, y, WOOD)
	for x in [2, 4]:
		_wall_x("wall", x, -5, y, STONE)
	for z in [-4, -2]:
		_wall_z("wall", -5, z, y, WOOD)
		_wall_z("wall", -1, z, y, WOOD)
		_wall_z("wall", 1, z, y, STONE)
		_wall_z("wall", 5, z, y, STONE)
	# Two carved columns holding up the hall.
	_add("column", STONE, Vector3(-1, y, 2), 0)
	_add("column", STONE, Vector3(1, y, 2), 0)
	# Furnishing: a table with two chairs, a banner, sconces; a rug and a shelf in the bedroom;
	# barrels and crates in the storage room.
	_add("table", WOOD, Vector3(0, y, 0.6), 0)
	_add("chair", WOOD, Vector3(-1.45, y, 0.6), 1)
	_add("chair", WOOD, Vector3(1.45, y, 0.6), 3)
	_on_wall_z("banner", WOOD, 0, -1, y, 1)
	_on_wall_x("wall_sconce", COPPER, -3, 2, y + 1.2, 1)
	_on_wall_x("wall_sconce", COPPER, 3, 2, y + 1.2, -1)
	_add("rug", WOOD, Vector3(-3, y, -3), 0)
	_on_wall_z("shelf", WOOD, -3, -5, y, 1)
	_on_wall_z("barrel", WOOD, 2, -5, y, 1)
	_on_wall_z("barrel", WOOD, 2.8, -5, y, 1)
	_on_wall_z("crate", WOOD, 4.2, -5, y, 1)
	_add("crate", WOOD, Vector3(4.2, y, -3.1), 0)


## A stone hall on a foundation: columns inside, a round doorway, brick gables and a steep roof.
func _stone_hall() -> void:
	_start(Vector3(6, 8, 8))
	for x in [-2, 0, 2]:
		for z in [-3, -1, 1, 3]:
			_add("foundation", STONE, Vector3(x, 0, z), 0)
	var y := 1.0
	_wall_x("wall", -2, 4, y, STONE)
	_wall_x("doorway", 0, 4, y, STONE)
	_add("door", WOOD, Vector3(0, y, 4), 0)
	_wall_x("wall", 2, 4, y, STONE)
	for x in [-2, 0, 2]:
		_wall_x("window_wide" if x == 0 else "wall", x, -4, y, STONE)
	for z in [-3, -1, 1, 3]:
		_wall_z("window_wall" if z == -1 or z == 1 else "wall", -3, z, y, STONE)
		_wall_z("window_wall" if z == -1 or z == 1 else "wall", 3, z, y, STONE)
	for z in [-2, 0, 2]:
		_add("column", STONE, Vector3(-1, y, z), 0)
		_add("column", STONE, Vector3(1, y, z), 0)
	# A long rug up the middle, a table at the far end, banners and sconces.
	_add("rug", WOOD, Vector3(0, y, 0), 1)
	_add("table", STONE, Vector3(0, y, -3), 0)
	for x in [-2, 2]:
		_on_wall_z("banner", WOOD, x, -4, y, 1)
	for z in [-3, 3]:
		_on_wall_x("wall_sconce", COPPER, -3, z, y + 1.2, 1)
		_on_wall_x("wall_sconce", COPPER, 3, z, y + 1.2, -1)
	# Steep roof: two rows each side, rising to the ridge at z = 0.
	var top := y + 2.0
	for x in [-2, 0, 2]:
		_add("roof_45", BRICK, Vector3(x, top, 3), 0)
		_add("roof_45", BRICK, Vector3(x, top + 2.0, 1), 0)
		_add("roof_45", BRICK, Vector3(x, top, -3), 2)
		_add("roof_45", BRICK, Vector3(x, top + 2.0, -1), 2)
	# Closing the ends under the roof: gables and the wall pieces under the upper gables.
	for side in [-3, 3]:
		_add("gable_45", BRICK, Vector3(side, top, 3), 1)
		_add("gable_45", BRICK, Vector3(side, top, -3), 3)
		_add("wall", STONE, Vector3(side, top, 1), 1)
		_add("wall", STONE, Vector3(side, top, -1), 1)
		_add("gable_45", BRICK, Vector3(side, top + 2.0, 1), 1)
		_add("gable_45", BRICK, Vector3(side, top + 2.0, -1), 3)


## An open-front workshop: stone floor, half walls on three sides, a roof sloping to the back,
## and a tall stone chimney. Room inside for a Smelter, an Anvil and a Workbench.
func _forge() -> void:
	_start(Vector3(6, 7, 8))  # 8 deep: room for the chimney behind the back wall
	_floors(-3, -3, 3, 3, 0.0, STONE)
	var y := 0.25
	for x in [-2, 0, 2]:
		_wall_x("half_wall", x, -3, y, BRICK)
	for z in [-2, 0, 2]:
		_wall_z("half_wall", -3, z, y, BRICK)
		_wall_z("half_wall", 3, z, y, BRICK)
	# Posts: short at the front, taller at the back, so the roof slopes down to the front.
	for x in [-3, 3]:
		_add("pillar", WOOD, Vector3(x, y, 3), 0)
		_add("pillar", WOOD, Vector3(x, y, 1), 0)
		_add("pillar", WOOD, Vector3(x, y + 2.0, 1), 0)
		_add("pillar", WOOD, Vector3(x, y, -1), 0)
		_add("pillar", WOOD, Vector3(x, y + 2.0, -1), 0)
		_add("pillar", WOOD, Vector3(x, y, -3), 0)
		_add("pillar", WOOD, Vector3(x, y + 2.0, -3), 0)
	for x in [-2, 0, 2]:
		_add("roof_26", WOOD, Vector3(x, y + 2.0, 2), 0)
		_add("roof_26", WOOD, Vector3(x, y + 3.0, 0), 0)
		_add("roof_26", WOOD, Vector3(x, y + 4.0, -2), 0)
	# A weapon rack and a barrel by the back wall, shields on the side walls.
	_on_wall_z("weapon_rack", WOOD, -1.6, -3, y, 1)
	_on_wall_z("barrel", WOOD, 2.2, -3, y, 1)
	_on_wall_x("wall_shield", WOOD, -3, 0, y + 0.15, 1)
	_on_wall_x("wall_shield", COPPER, 3, 0, y + 0.15, -1)
	# The chimney: a stack of stone pillars just behind the back wall, rising past the roof.
	for i in 3:
		_add("pillar", STONE, Vector3(1.4, y + i * 2.0, -3.6), 0)


## A small 2-floor wooden cabin with stairs, windows and a gentle roof; and a 3-floor lookout
## tower next to it with a ladder and a railing on top.
func _watchtower() -> void:
	_start(Vector3(8, 9, 4))
	# Cabin: x -4..0, z -2..2.
	_floors(-4, -2, 0, 2, 0.0, WOOD)
	var y := 0.25
	_wall_x("doorway", -3, 2, y, WOOD)
	_add("door", WOOD, Vector3(-3, y, 2), 0)
	_wall_x("window_wall", -1, 2, y, WOOD)
	for x in [-3, -1]:
		_wall_x("wall", x, -2, y, WOOD)
	for z in [-1, 1]:
		_wall_z("wall", -4, z, y, WOOD)
		_wall_z("wall", 0, z, y, WOOD)
	_add("stairs", WOOD, Vector3(-1, y, -1), 2)  # climbs toward the back
	_on_wall_x("bench", WOOD, -4, 0, y, 1)
	_add("barrel", WOOD, Vector3(-3.5, y, -1.5), 0)
	_on_wall_z("wall_sconce", COPPER, -3, -2, y + 1.2, 1)
	# Upstairs: floor with a hole over the stairs, windows all round, roof.
	var y2 := y + 2.0
	_add("floor", WOOD, Vector3(-3, y2, -1), 0)
	_add("floor", WOOD, Vector3(-3, y2, 1), 0)
	_add("floor", WOOD, Vector3(-1, y2, 1), 0)
	var y3 := y2 + 0.25
	for x in [-3, -1]:
		_wall_x("window_wall", x, 2, y3, WOOD)
		_wall_x("wall", x, -2, y3, WOOD)
	for z in [-1, 1]:
		_wall_z("window_wall", -4, z, y3, WOOD)
		_wall_z("wall", 0, z, y3, WOOD)
	_add("rug", WOOD, Vector3(-3, y2 + 0.25, 0), 1)
	var top := y3 + 2.0
	for x in [-3, -1]:
		_add("roof_26", WOOD, Vector3(x, top, 1), 0)
		_add("roof_26", WOOD, Vector3(x, top, -1), 2)
	for side in [-4, 0]:
		_add("gable_26", WOOD, Vector3(side, top, 1), 1)
		_add("gable_26", WOOD, Vector3(side, top, -1), 3)
	# Tower: x 1..3, z -1..1, floors every 2.25 m, pillars at the corners, ladder up the front.
	for level in 4:
		var ly := level * 2.25
		_add("floor", WOOD, Vector3(2, ly, 0), 0)
		if level < 3:
			for cx in [1, 3]:
				for cz in [-1, 1]:
					_add("pillar", WOOD, Vector3(cx, ly + 0.25, cz), 0)
			_add("ladder", WOOD, Vector3(2, ly + 0.25, 1.1), 0)
	var deck := 3 * 2.25 + 0.25
	_wall_x("railing", 2, -1, deck, WOOD)
	_wall_z("railing", 1, 0, deck, WOOD)
	_wall_z("railing", 3, 0, deck, WOOD)


## Owner, Nov 17: the first stone place to find, a round 12-sided watchtower (3 floors + a lookout roof with
## battlements), also a blueprint you learn from a page found inside its ruined twin. Stonehold (cut stone).
## Plan from above: a hexagon of 6 triangles in the middle, a square on each of its 6 edges, and a triangle in
## each gap between two squares: 12 outer edges, all 2 m (walls fit every one). Every outer edge is 3.73 m from
## the middle, every outer corner 3.86 m. Directions are "yaw" steps of 30° (0 = +z, the front door's side).
## Floors: foundations 0-1 m, walls from 1, 3.25 and 5.5 m, floors at 3 and 5.25 m, the roof deck at 7.5 m.
## Stairs climb along the ring on a different side each floor; their hole has a railing round it.
const _APO := 1.7320508      # middle hexagon: centre to edge
const _EDGE := 3.7320508     # centre to every outer edge (apothem + one square)
const _CORNER := 3.8637033   # centre to every outer corner
var _ring_off := Vector3.ZERO  # where a 12-sided ring is centred (the watchtower: the middle; the outpost: its corners)


static func _dir(steps: int) -> Vector3:
	var a := steps * PI / 6.0
	return Vector3(sin(a), 0.0, cos(a))


func _rot(steps: int) -> int:
	return Pieces.rot_from_steps(steps)


## One flat layer of the 12-sided plan (foundations or floors); `skip_square` = a square left open (stairs hole).
func _ring_layer(square_id: String, tri_id: String, y: float, skip_square: int = -1) -> void:
	for k in 6:
		var n := _dir(2 * k)
		_add(tri_id, STONE, n * (_APO * 2.0 / 3.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))          # middle hexagon
		if k != skip_square:
			_add(square_id, STONE, n * (_APO + 1.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))         # square on its edge
		var u := _dir(2 * k + 1)
		_add(tri_id, STONE, u * (2.0 + 2.0 / sqrt(3.0)) + Vector3(0, y, 0) + _ring_off, _rot(2 * k + 1))  # triangle in the gap


## The 12 outer edges at height y: `pick(j)` says which piece goes on edge j ("" = nothing).
func _ring_edges(y: float, pick: Callable) -> void:
	for j in 12:
		var id: String = pick.call(j)
		if id != "":
			_add(id, STONE, _dir(j) * _EDGE + Vector3(0, y, 0) + _ring_off, _rot(j))


## Stone pillars on the 12 outer corners (they cover the joints where two walls meet at an angle). Not the ones in
## `skip`: corner j sits between edges j and j+1, and a pillar beside a doorway cut into its arch stones (owner).
func _ring_pillars(y: float, skip: Array = []) -> void:
	for j in 12:
		if j in skip:
			continue
		var a := (j + 0.5) * PI / 6.0
		_add("pillar", STONE, Vector3(sin(a), 0, cos(a)) * (_CORNER - 0.05) + Vector3(0, y, 0) + _ring_off, _rot(j))


## Stairs in square `k` climbing along the ring (toward yaw step 2k+3). Stairs are 2 m tall but Stonehold floors are
## 2.25 m apart: a floor slab under them lifts them so their top step meets the next floor (owner: a lip at the top
## made the dwarf hop going down and struggle going up).
func _ring_stairs(k: int, y: float) -> void:
	_add("floor", STONE, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))
	_add("stairs", STONE, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y + 0.25, 0) + _ring_off, _rot(2 * k + 9))


## Railings round the stairs hole in square `k` on the floor above: its inner edge and the side the stairs
## start from (the far side stays open: that's where you step off).
func _ring_rails(k: int, y: float) -> void:
	var n := _dir(2 * k)
	var t := _dir(2 * k + 3)
	_add("railing", STONE, n * _APO + Vector3(0, y, 0) + _ring_off, _rot(2 * k))
	_add("railing", STONE, n * (_APO + 1.0) - t + Vector3(0, y, 0) + _ring_off, _rot(2 * k + 3))


func _stone_watchtower() -> void:
	_start(Vector3(10, 9, 12))
	_ring_layer("foundation", "foundation_triangle", 0.0)
	_add("foundation_steps", STONE, _dir(0) * (_EDGE + 1.0), 0)                        # up to the front door
	var g := 1.0
	_ring_edges(g, func(j): return "doorway" if j == 0 else ("window_wall" if j in [4, 8] else "wall"))
	_add("door", STONE, _dir(0) * _EDGE + Vector3(0, g, 0), 0)
	_ring_pillars(g, [11, 0])
	_ring_stairs(2, g)
	var f2 := 3.0
	_ring_layer("floor", "floor_triangle", f2, 2)
	_ring_rails(2, f2 + 0.25)
	var w2 := f2 + 0.25
	_ring_edges(w2, func(j): return "window_wall" if j % 2 == 0 else "wall")
	_ring_pillars(w2)
	_ring_stairs(4, w2)
	var f3 := w2 + 2.0
	_ring_layer("floor", "floor_triangle", f3, 4)
	_ring_rails(4, f3 + 0.25)
	var w3 := f3 + 0.25
	_ring_edges(w3, func(j): return "window_wall" if j % 2 == 1 else "wall")
	_ring_pillars(w3)
	_ring_stairs(0, w3)
	var roof := w3 + 2.0
	_ring_layer("floor", "floor_triangle", roof, 0)
	_ring_rails(0, roof + 0.25)
	_ring_edges(roof + 0.25, func(_j): return "battlement")


## Owner, Nov 17: the second stone place, "a lot bigger": a small fortress (the Fallen Outpost; this is the whole
## version, learnable as a blueprint; its ruin is made from it). 28 x 28 m inside a curtain wall, Stonehold.
## Plan on the 2 m grid (x right, z front; the gate is at the front, +z):
##   - Four towers: two square (6 x 6 m) at the back-left and front-right, two round (the watchtower's 12-sided
##     ring, 2 floors + a battlement roof) at the front-left and back-right. A round tower sits 27 cm in from the
##     corner, so two of its flat sides meet the curtain walls' ends exactly (no gap, no overlap).
##   - Barracks: an L (wing A along the back wall, wing B along the left wall) wrapped round the back-left square
##     tower, a doorway from each wing into it on both floors (owner: "the barracks have an entrance to the tower").
##   - A walkway along the top of the curtain wall for archers (owner's pick: floors on pillars, stairs up from the
##     courtyard): stairs on the left and the back wall; it joins the round towers' roofs and the gatehouse roof.
##   - Gatehouse: two small towers and a big stone gateway with a double gate (two leaves that swing like doors).
##   - Armoury and forge against the right curtain wall (it is the shed's back wall), open toward the well.
##   - A training yard (straw dummies, an archery target, a spear rack) and a railed well.
## Heights: square towers and barracks stand on foundations (floors at 1, 3, roof 5.25); the round towers on ground
## floors (0, 2.25, roof 4.5); curtain walls 4 m with the walkway at 4 m; the gatehouse roof at 4 m.
const _OUT_RT := 13.732051   # round towers' centres: 27 cm in from the corners (14 - 0.268)


func _stone_outpost() -> void:
	_start(Vector3(36, 7, 36))
	# --- the two square towers and the barracks round the back one
	_sq_tower(-14, -14, func(side, c, lvl): return "doorway" if (side == "e" and c == -11) or (side == "s" and c == -11) else ("window_wall" if lvl == 1 and c == -11 else "wall"))
	_sq_tower(8, 8, func(side, c, lvl): return "doorway" if lvl == 0 and ((side == "w" and c == 11) or (side == "n" and c == 11)) else ("window_wall" if lvl == 1 and c == 11 else "wall"))
	_add("foundation_steps", STONE, Vector3(7, 0, 11), 3)   # up to the front-right tower's west door
	_add("foundation_steps", STONE, Vector3(11, 0, 7), 2)   # and its north door
	_hall(-8, -14, 2, -8, {"w": "skip", "s": {-1: "doorway", -5: "window_wall", 1: "window_wall"}, "e": {}})   # (no east door: its steps crowded the walkway stairs)
	_hall(-14, -8, -8, 0, {"n": "skip", "e": {-3: "doorway", -7: "window_wall", -1: "window_wall"}})
	_add("foundation_steps", STONE, Vector3(-1, 0, -7), 0)  # into wing A from the courtyard
	_add("foundation_steps", STONE, Vector3(-7, 0, -3), 1)  # into wing B
	# --- the two round towers (front-left, back-right): door toward the courtyard; no battlement where a walkway or
	# the stairs arrive, so you can step onto the roof
	# Each sits so the side where the stairs arrive lines up exactly with them (owner's pick, Nov 17): the
	# front-left one over the left walkway (x -14..-12), the back-right one at the back stairs' top (z -14..-12).
	_round_tower(Vector3(-13, 0, _OUT_RT), 4, 0, 5, [3, 6])
	_round_tower(Vector3(_OUT_RT, 0, -13), 10, 3, 2, [9, 0])
	# --- the gatehouse: two little towers either side of the big gateway, a roof over the passage
	for gx in [-6, 2]:
		for lvl in 2:
			var y := lvl * 2.0
			for cx in [gx + 1, gx + 3]:
				_wall_x("wall", cx, 14, y, STONE)                                               # front (the outer wall)
				_wall_x("doorway" if lvl == 0 and cx == (gx + 3 if gx < 0 else gx + 1) else ("window_wall" if lvl == 1 else "wall"), cx, 10, y, STONE)
			for cz in [11, 13]:
				_wall_z("wall", gx, cz, y, STONE)
				_wall_z("wall", gx + 4, cz, y, STONE)
		_floors(gx, 10, gx + 4, 14, 4.0, STONE)
		_floors(gx, 10, gx + 4, 14, 4.25, STONE)   # two slabs thick: level with the walkway and the round towers' roofs
	_add("door", STONE, Vector3(-3, 0, 10), 0)
	_add("door", STONE, Vector3(3, 0, 10), 0)
	_wall_x("gateway", 0, 14, 0.0, STONE)                                                       # the big gate
	_add("gate_leaf", STONE, Vector3(-0.8, 0.0, 14), 0)                                        # left leaf, hinged at the left
	_add("gate_leaf", STONE, Vector3(0.8, 0.0, 14), 2)                                         # right leaf, turned round
	_floors(-2, 10, 2, 14, 4.0, STONE)                                                          # the roof over the passage
	_floors(-2, 10, 2, 14, 4.25, STONE)
	for x in [-5, -3, -1, 1, 3, 5]:
		_wall_x("battlement", x, 14, 4.5, STONE)
		_wall_x("battlement", x, 10, 4.5, STONE)
	_wall_z("battlement", -6, 11, 4.5, STONE)                                                  # (not at -6, 13: the walkway joins there)
	for z in [11, 13]:
		_wall_z("battlement", 6, z, 4.5, STONE)
	# --- the curtain wall (two walls high) wherever no building stands on its line
	var walk := {}   # cells with the walkway on top: "x,z" -> true
	for c in [[-9, 13], [-7, 13], [-13, 9], [13, -9], [13, -7]]:
		walk["%d,%d" % c] = true
	var runs := [["x", 14, [-9, -7, 7]], ["x", -14, [3, 5, 7, 9]], ["z", -14, [1, 3, 5, 7, 9]], ["z", 14, [-9, -7, -5, -3, -1, 1, 3, 5, 7]]]
	# Where the walkway meets a round tower's other side (not the stairs side), the tower's flat face is 0.73 m into
	# that 2 m cell: a 1 m wall, a post closing the last 27 cm, a half floor on top, no battlement (owner, Nov 17).
	var short := {"x,14,-9": Vector3(-8.5, 0, 14), "z,14,-9": Vector3(14, 0, -8.5)}
	for r in runs:
		for c in r[2]:
			var sk := "%s,%d,%d" % [r[0], r[1], c]
			if short.has(sk):
				var sp: Vector3 = short[sk]
				var post := Vector3(-9.1, 0, 14) if r[0] == "x" else Vector3(14, 0, -9.1)
				for y in [0.0, 2.0]:
					_add("wall_narrow", STONE, sp + Vector3(0, y, 0), 0 if r[0] == "x" else 1)
					_add("pillar", STONE, post + Vector3(0, y, 0), 0)
				continue
			for y in [0.0, 2.0]:
				if r[0] == "x":
					_wall_x("wall", c, r[1], y, STONE)
				else:
					_wall_z("wall", r[1], c, y, STONE)
			var cell := Vector2i(c, r[1] - signi(r[1])) if r[0] == "x" else Vector2i(r[1] - signi(r[1]), c)
			var on_walk: bool = walk.has("%d,%d" % [cell.x, cell.y])
			var by := 4.5 if on_walk else 4.0
			if r[0] == "x":
				_wall_x("battlement", c, r[1], by, STONE)
			else:
				_wall_z("battlement", r[1], c, by, STONE)
	# --- the walkway: floors on top of the wall, stone pillars under their inner edge
	var pillars := {}
	for key in walk:
		var xz: PackedStringArray = key.split(",")
		var cx := int(xz[0])
		var cz := int(xz[1])
		for fy in [4.0, 4.25]:  # two slabs: its top (4.5 m) meets the round towers' roofs
			if key == "-9,13":
				_add("floor_half", STONE, Vector3(-8.5, fy, 13), 1)   # (the round tower's face is at x -9.27)
			elif key == "13,-9":
				_add("floor_half", STONE, Vector3(13, fy, -8.5), 0)   # (and here at z -9.27)
			else:
				_add("floor", STONE, Vector3(cx, fy, cz), 0)
		if absi(cz) == 13:
			for px in [cx - 1, cx + 1]:
				pillars["%d,%d" % [px, cz - signi(cz)]] = Vector2i(px, cz - signi(cz))
		else:
			for pz in [cz - 1, cz + 1]:
				pillars["%d,%d" % [cx - signi(cx), pz]] = Vector2i(cx - signi(cx), pz)
	for key in pillars:
		var pp: Vector2i = pillars[key]
		if key in ["-6,12", "12,-6", "-12,10", "12,-10", "-10,12"]:
			continue  # a building's wall or a round tower is already there
		for y in [0.0, 2.0]:
			_add("pillar", STONE, Vector3(pp.x, y, pp.y), 0)
	# stairs up: left wall (to the front-left tower) and back wall (to the back-right tower), with a landing
	_add("floor", STONE, Vector3(-13, 0.0, 3), 0)         # a slab under the first flight: it then meets the landing
	_add("stairs", STONE, Vector3(-13, 0.25, 3), 2)       # climbs toward the front (+z)
	_floors(-14, 4, -12, 8, 2.0, STONE)                   # the landing, and the floor under the second flight
	_add("floor", STONE, Vector3(-13, 2.25, 7), 0)
	_add("stairs", STONE, Vector3(-13, 2.5, 7), 2)
	_add("floor", STONE, Vector3(5, 0.0, -13), 0)
	_add("stairs", STONE, Vector3(5, 0.25, -13), 3)       # climbs toward the right (+x)
	_floors(6, -14, 10, -12, 2.0, STONE)
	_add("floor", STONE, Vector3(9, 2.25, -13), 0)
	_add("stairs", STONE, Vector3(9, 2.5, -13), 3)
	for pp in [Vector2i(-12, 4), Vector2i(-12, 6), Vector2i(6, -12), Vector2i(8, -12)]:
		_add("pillar", STONE, Vector3(pp.x, 0.0, pp.y), 0)
	# --- armoury and forge: against the right curtain wall (its back wall), open toward the well on pillars
	_floors(10, -6, 14, 2, 0.0, STONE)
	for x in [11, 13]:
		_wall_x("wall", x, -6, 0.25, STONE)
		_wall_x("wall", x, 2, 0.25, STONE)
	for z in [-6, -4, -2, 0, 2]:
		_add("pillar", STONE, Vector3(10, 0.25, z), 0)
	_floors(10, -6, 14, 2, 2.25, STONE)
	# --- the training yard (front-left of the courtyard) and the well
	_add("straw_dummy", WOOD, Vector3(-8, 0, 4), 0)
	_add("straw_dummy", WOOD, Vector3(-6, 0, 5.5), 4 + 1)
	_add("archery_target", WOOD, Vector3(-10.5, 0, 7.5), 1)
	_add("spear_rack", WOOD, Vector3(-5, 0, 9.63), 2)    # against the left gate tower's back wall (owner), off its door
	_floors(0, 2, 2, 4, 0.0, STONE)
	_wall_x("railing", 1, 2, 0.25, STONE)
	_wall_x("railing", 1, 4, 0.25, STONE)
	_wall_z("railing", 0, 3, 0.25, STONE)
	_wall_z("railing", 2, 3, 0.25, STONE)


## A round tower for the outpost (the watchtower's 12-sided ring, 2 floors + a battlement roof) centred at `c`:
## its door on edge `door_j`, stairs in squares k1 and k2, no battlement on the edges in `open_js`.
func _round_tower(c: Vector3, door_j: int, k1: int, k2: int, open_js: Array) -> void:
	# Walls stand right on the ground like the curtain walls (no bottom floor), so the roof's top is at 4.5 m, level
	# with the walkway and the gatehouse roof (owner: "not aligned... even if someone tries to rebuild it").
	_ring_off = c
	_ring_edges(0.0, func(j): return "doorway" if j == door_j else "wall")
	_add("door", STONE, _dir(door_j) * _EDGE + c, _rot(door_j))
	_ring_pillars(0.0, [posmod(door_j - 1, 12), door_j])
	_ring_stairs(k1, 0.0)
	_ring_layer("floor", "floor_triangle", 2.0, k1)
	_ring_rails(k1, 2.25)
	_ring_edges(2.25, func(j): return "window_wall" if j % 2 == 0 and j not in open_js else "wall")
	_ring_pillars(2.25)
	_ring_stairs(k2, 2.25)
	_ring_layer("floor", "floor_triangle", 4.25, k2)
	_ring_rails(k2, 4.5)
	_ring_edges(4.5, func(j): return "" if j in open_js else "battlement")
	_ring_off = Vector3.ZERO


## A square stone tower (3 x 3 cells from x0, z0): foundations, 2 floors, a battlement roof; stairs inside from
## floor 1 to 2 and from 2 to the roof, railings round their holes. `pick(side, c, lvl)` names each outer wall
## piece (side n/s/e/w, c = the cell's centre along that side, lvl 0 or 1).
func _sq_tower(x0: int, z0: int, pick: Callable) -> void:
	var x1 := x0 + 6
	var z1 := z0 + 6
	for x in range(x0 + 1, x1, 2):
		for z in range(z0 + 1, z1, 2):
			_add("foundation", STONE, Vector3(x, 0, z), 0)
	# half walls close the gaps between the foundations' corner posts (owner, Nov 17), not under a doorway
	for c in range(x0 + 1, x1, 2):
		for side in ["n", "s"]:
			if pick.call(side, c, 0) != "doorway":
				_wall_x("half_wall", c, z0 if side == "n" else z1, 0.0, STONE)
	for c in range(z0 + 1, z1, 2):
		for side in ["w", "e"]:
			if pick.call(side, c, 0) != "doorway":
				_wall_z("half_wall", x0 if side == "w" else x1, c, 0.0, STONE)
	var ys := [1.0, 3.25]
	for lvl in 2:
		var y: float = ys[lvl]
		for c in range(x0 + 1, x1, 2):
			_wall_x(pick.call("n", c, lvl), c, z0, y, STONE)
			_wall_x(pick.call("s", c, lvl), c, z1, y, STONE)
		for c in range(z0 + 1, z1, 2):
			_wall_z(pick.call("w", c, lvl), x0, c, y, STONE)
			_wall_z(pick.call("e", c, lvl), x1, c, y, STONE)
	# Stairs never start against a wall or in a corner (owner, Nov 17: "you cannot get to them"): the first flight
	# stands in the middle square and climbs toward the back, its foot on open floor; the second starts by the spot
	# where the first arrives (the back-left corner) and climbs toward the front along the left wall's middle.
	_add("floor", STONE, Vector3(x0 + 3, 1.0, z0 + 3), 0)             # (slabs under the stairs: their tops meet the floors)
	_add("stairs", STONE, Vector3(x0 + 3, 1.25, z0 + 3), 0)           # floor 1 -> 2
	_add("floor", STONE, Vector3(x0 + 1, 3.25, z0 + 3), 0)
	_add("stairs", STONE, Vector3(x0 + 1, 3.5, z0 + 3), 2)            # floor 2 -> the roof
	for x in range(x0 + 1, x1, 2):
		for z in range(z0 + 1, z1, 2):
			if not (x == x0 + 3 and z == z0 + 3):
				_add("floor", STONE, Vector3(x, 3.0, z), 0)
			if not (x == x0 + 1 and z == z0 + 3):
				_add("floor", STONE, Vector3(x, 5.25, z), 0)
	_wall_x("railing", x0 + 3, z0 + 4, 3.25, STONE)                   # round the first flight's hole (not its top end)
	_wall_z("railing", x0 + 4, z0 + 3, 3.25, STONE)
	_wall_z("railing", x0 + 2, z0 + 3, 5.5, STONE)                    # round the second flight's hole on the roof
	_wall_x("railing", x0 + 1, z0 + 2, 5.5, STONE)
	for c in range(x0 + 1, x1, 2):
		_wall_x("battlement", c, z0, 5.5, STONE)
		_wall_x("battlement", c, z1, 5.5, STONE)
	for c in range(z0 + 1, z1, 2):
		_wall_z("battlement", x0, c, 5.5, STONE)
		_wall_z("battlement", x1, c, 5.5, STONE)
	# its doors (round doors in the doorways)
	for p in _bp.pieces.duplicate():
		if p.id == "doorway" and absf(p.pos.x - (x0 + 3)) <= 3.1 and absf(p.pos.z - (z0 + 3)) <= 3.1 and p.pos.y > 0.5:
			_add("door", STONE, p.pos, p.rot)


## A 2-floor stone hall on foundations over cells x0..x1, z0..z1, a flat roof with battlements on its outer edges.
## `sides` per side (n/s/e/w): "skip" (another building's wall is there) or {cell centre: piece} (default "wall").
func _hall(x0: int, z0: int, x1: int, z1: int, sides: Dictionary) -> void:
	for x in range(x0 + 1, x1, 2):
		for z in range(z0 + 1, z1, 2):
			_add("foundation", STONE, Vector3(x, 0, z), 0)
			_add("floor", STONE, Vector3(x, 3.0, z), 0)
			_add("floor", STONE, Vector3(x, 5.25, z), 0)
	for lvl in 2:
		var y: float = [1.0, 3.25][lvl]
		for side in ["n", "s", "w", "e"]:
			var spec = sides.get(side, {})
			if spec is String and spec == "skip":
				continue
			var cells: Array = range(x0 + 1, x1, 2) if side in ["n", "s"] else range(z0 + 1, z1, 2)
			for c in cells:
				var id: String = spec.get(c, "wall")
				if lvl == 0 and id != "doorway":   # half walls close the gaps between the foundations' posts
					match side:
						"n": _wall_x("half_wall", c, z0, 0.0, STONE)
						"s": _wall_x("half_wall", c, z1, 0.0, STONE)
						"w": _wall_z("half_wall", x0, c, 0.0, STONE)
						"e": _wall_z("half_wall", x1, c, 0.0, STONE)
				if id == "doorway" and lvl == 1:
					id = "window_wall"
				elif id == "window_wall" and lvl == 0:
					id = "wall"
				match side:
					"n": _wall_x(id, c, z0, y, STONE)
					"s": _wall_x(id, c, z1, y, STONE)
					"w": _wall_z(id, x0, c, y, STONE)
					"e": _wall_z(id, x1, c, y, STONE)
				if id == "doorway":
					_add("door", STONE, Vector3(c, y, z0 if side == "n" else z1) if side in ["n", "s"] else Vector3(x0 if side == "w" else x1, y, c), 0 if side in ["n", "s"] else 1)
				if lvl == 1:
					match side:
						"n": _wall_x("battlement", c, z0, 5.5, STONE)
						"s": _wall_x("battlement", c, z1, 5.5, STONE)
						"w": _wall_z("battlement", x0, c, 5.5, STONE)
						"e": _wall_z("battlement", x1, c, 5.5, STONE)


# ---------------------------------------------------------------- helpers

func _start(size: Vector3) -> void:
	_bp = Blueprint.new()
	_bp.size = size
	var cells := int(size.x * size.y * size.z)
	_bp.air.resize(cells)
	_bp.air.fill(1)


## The same building in root planks (docs/design/ruin-rebuild-plan.md): every piece that has a wooden version becomes
## wood; battlements (stone only) become wooden railings.
func _to_wood() -> void:
	for p in _bp.pieces:
		if Pieces.allowed(p.id, WOOD):
			p.mat = WOOD
		elif String(p.id).begins_with("battlement"):
			p.id = "railing"
			p.mat = WOOD


func _add(id: String, mat: String, pos: Vector3, rot: int) -> void:
	_bp.pieces.append({id = id, mat = mat, pos = pos, rot = rot})


## 2 m floor tiles covering the rectangle (x0,z0)-(x1,z1) at height y.
func _floors(x0: int, z0: int, x1: int, z1: int, y: float, mat: String) -> void:
	for x in range(x0 + 1, x1, 2):
		for z in range(z0 + 1, z1, 2):
			_add("floor", mat, Vector3(x, y, z), 0)


## A wall-like piece on the line z = `z`, centred at x (spans X).
func _wall_x(id: String, x: float, z: float, y: float, mat: String) -> void:
	_add(id, mat, Vector3(x, y, z), 0)


## A wall-like piece on the line x = `x`, centred at z (spans Z).
func _wall_z(id: String, x: float, z: float, y: float, mat: String) -> void:
	_add(id, mat, Vector3(x, y, z), 1)


## A piece standing against (or hanging on) a wall on the line z = `z`, on the side `side` (+1 = +z),
## its back on the wall's face and its front facing away from the wall.
func _on_wall_z(id: String, mat: String, x: float, z: float, y: float, side: int) -> void:
	var depth: float = Pieces.LIST[id].size.z
	_add(id, mat, Vector3(x, y, z + side * (0.15 + depth * 0.5)), 0 if side > 0 else 2)


## The same against a wall on the line x = `x`.
func _on_wall_x(id: String, mat: String, x: float, z: float, y: float, side: int) -> void:
	var depth: float = Pieces.LIST[id].size.z
	_add(id, mat, Vector3(x + side * (0.15 + depth * 0.5), y, z), 1 if side > 0 else 3)
