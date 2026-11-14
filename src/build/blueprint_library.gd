class_name BlueprintLibrary
## The ready-made blueprints that come with the game (building polish spec §7). Built here in
## code from the piece catalog, so they only ever use real pieces. Simple for now (the owner:
## "later we will have bigger and more elaborate").
##
## Coordinates: like every blueprint, relative to the box's bottom centre; the FRONT is +z
## (doors face +z, and the Builder's Chest appears in front). Pieces sit on a 1 m grid; 2 m pieces.
## Every cell of the box is marked "air", so placed inside rock the chest carves the room out first.

const IDS := ["miners_homestead", "stone_hall", "forge_workshop", "watchtower_cabin"]
const NAMES := {
	"miners_homestead": "Miner's Homestead",
	"stone_hall": "Stone Hall",
	"forge_workshop": "Forge Workshop",
	"watchtower_cabin": "Watchtower & Cabin",
}

const WOOD := "plank_root"
const STONE := "cut_stone"
const BRICK := "clay_brick"

var _bp: Blueprint


static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in IDS:
		out.append({id = id, name = NAMES[id], file = "res://blueprints/%s.dwbp" % id})
	return out


static func make(id: String) -> Blueprint:
	var lib := BlueprintLibrary.new()
	match id:
		"miners_homestead": lib._homestead()
		"stone_hall": lib._stone_hall()
		"forge_workshop": lib._forge()
		"watchtower_cabin": lib._watchtower()
		_: return null
	lib._bp.name = NAMES[id]
	lib._bp.author = "Dwarf Game"
	lib._bp.source = "ancient"
	return lib._bp


# ---------------------------------------------------------------- the four buildings

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


## A stone hall on a foundation: columns inside, an arched doorway, gables and a steep roof.
func _stone_hall() -> void:
	_start(Vector3(6, 8, 8))
	for x in [-2, 0, 2]:
		for z in [-3, -1, 1, 3]:
			_add("foundation", STONE, Vector3(x, 0, z), 0)
	var y := 1.0
	_wall_x("wall", -2, 4, y, STONE)
	_wall_x("arch_doorway", 0, 4, y, STONE)
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
	# Steep roof: two rows each side, rising to the ridge at z = 0.
	var top := y + 2.0
	for x in [-2, 0, 2]:
		_add("roof_45", BRICK, Vector3(x, top, 3), 0)
		_add("roof_45", BRICK, Vector3(x, top + 2.0, 1), 0)
		_add("roof_45", BRICK, Vector3(x, top, -3), 2)
		_add("roof_45", BRICK, Vector3(x, top + 2.0, -1), 2)
	# Closing the ends under the roof: gables and the wall pieces under the upper gables.
	for side in [-3, 3]:
		_add("gable_45", STONE, Vector3(side, top, 3), 1)
		_add("gable_45", STONE, Vector3(side, top, -3), 3)
		_add("wall", STONE, Vector3(side, top, 1), 1)
		_add("wall", STONE, Vector3(side, top, -1), 1)
		_add("gable_45", STONE, Vector3(side, top + 2.0, 1), 1)
		_add("gable_45", STONE, Vector3(side, top + 2.0, -1), 3)


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


# ---------------------------------------------------------------- helpers

func _start(size: Vector3) -> void:
	_bp = Blueprint.new()
	_bp.size = size
	var cells := int(size.x * size.y * size.z)
	_bp.air.resize(cells)
	_bp.air.fill(1)


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
