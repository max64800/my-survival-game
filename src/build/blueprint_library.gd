class_name BlueprintLibrary
## The ready-made blueprints that come with the game (building polish spec §7). Built here in
## code from the piece catalog, so they only ever use real pieces. Simple for now (the owner:
## "later we will have bigger and more elaborate").
##
## Coordinates: like every blueprint, relative to the box's bottom centre; the FRONT is +z
## (doors face +z, and the Builder's Chest appears in front). Pieces sit on a 1 m grid; 2 m pieces.
## Every cell of the box is marked "air", so placed inside rock the chest carves the room out first.

const IDS := ["delvers_hut", "miners_homestead", "stone_hall", "forge_workshop", "watchtower_cabin", "stone_watchtower",
	"wooden_watchtower"]
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


static func _dir(steps: int) -> Vector3:
	var a := steps * PI / 6.0
	return Vector3(sin(a), 0.0, cos(a))


func _rot(steps: int) -> int:
	return Pieces.rot_from_steps(steps)


## One flat layer of the 12-sided plan (foundations or floors); `skip_square` = a square left open (stairs hole).
func _ring_layer(square_id: String, tri_id: String, y: float, skip_square: int = -1) -> void:
	for k in 6:
		var n := _dir(2 * k)
		_add(tri_id, STONE, n * (_APO * 2.0 / 3.0) + Vector3(0, y, 0), _rot(2 * k))          # middle hexagon
		if k != skip_square:
			_add(square_id, STONE, n * (_APO + 1.0) + Vector3(0, y, 0), _rot(2 * k))         # square on its edge
		var u := _dir(2 * k + 1)
		_add(tri_id, STONE, u * (2.0 + 2.0 / sqrt(3.0)) + Vector3(0, y, 0), _rot(2 * k + 1))  # triangle in the gap


## The 12 outer edges at height y: `pick(j)` says which piece goes on edge j ("" = nothing).
func _ring_edges(y: float, pick: Callable) -> void:
	for j in 12:
		var id: String = pick.call(j)
		if id != "":
			_add(id, STONE, _dir(j) * _EDGE + Vector3(0, y, 0), _rot(j))


## Stone pillars on the 12 outer corners (they cover the joints where two walls meet at an angle).
func _ring_pillars(y: float) -> void:
	for j in 12:
		var a := (j + 0.5) * PI / 6.0
		_add("pillar", STONE, Vector3(sin(a), 0, cos(a)) * (_CORNER - 0.05) + Vector3(0, y, 0), _rot(j))


## Stairs in square `k` climbing along the ring (toward yaw step 2k+3).
func _ring_stairs(k: int, y: float) -> void:
	_add("stairs", STONE, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y, 0), _rot(2 * k + 9))


## Railings round the stairs hole in square `k` on the floor above: its inner edge and the side the stairs
## start from (the far side stays open: that's where you step off).
func _ring_rails(k: int, y: float) -> void:
	var n := _dir(2 * k)
	var t := _dir(2 * k + 3)
	_add("railing", STONE, n * _APO + Vector3(0, y, 0), _rot(2 * k))
	_add("railing", STONE, n * (_APO + 1.0) - t + Vector3(0, y, 0), _rot(2 * k + 3))


func _stone_watchtower() -> void:
	_start(Vector3(10, 9, 12))
	_ring_layer("foundation", "foundation_triangle", 0.0)
	_add("foundation_steps", STONE, _dir(0) * (_EDGE + 1.0), 0)                        # up to the front door
	var g := 1.0
	_ring_edges(g, func(j): return "doorway" if j == 0 else ("window_wall" if j in [4, 8] else "wall"))
	_add("door", STONE, _dir(0) * _EDGE + Vector3(0, g, 0), 0)
	_ring_pillars(g)
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
