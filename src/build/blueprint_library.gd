class_name BlueprintLibrary
## The ready-made blueprints that come with the game (building polish spec §7). Built here in
## code from the piece catalog, so they only ever use real pieces. Simple for now (the owner:
## "later we will have bigger and more elaborate").
##
## Coordinates: like every blueprint, relative to the box's bottom centre; the FRONT is +z
## (doors face +z, and the Builder's Chest appears in front). Pieces sit on a 1 m grid; 2 m pieces.
## Every cell of the box is marked "air", so placed inside rock the chest carves the room out first.

const IDS := ["delvers_hut", "miners_homestead", "stone_hall", "forge_workshop", "watchtower_cabin", "stone_watchtower",
	"stone_outpost", "wooden_watchtower", "wooden_outpost", "hearthbrick_brewhall", "wooden_brewhall", "lantern_spire", "wooden_spire",
	"hearthbrick_manor", "wooden_manor", "stonehold_twin_gate", "wooden_twin_gate", "stonehold_cliff_watch", "wooden_cliff_watch"]
## Known from the very start (F161): you place them and bring the materials. The rest are learned from
## Old Blueprints found in ruins (F98).
const STARTER := ["delvers_hut"]
## Learned only by rebuilding a ruin (owner, Nov 19), never from an Old Blueprint page.
## The Brewhall's two (F479): its cellar goes below the ground line, which only the ruin digs out.
## The Lantern Spire's two (F479): a landmark you rebuild where it stands. The Hearth Manor's two (F479) the same, and the Twin Gate's and Cliff Watch's (owner, Nov 22: so the dev menu has them).
const REBUILD_ONLY := ["wooden_watchtower", "wooden_outpost", "hearthbrick_brewhall", "wooden_brewhall", "lantern_spire", "wooden_spire",
	"hearthbrick_manor", "wooden_manor", "stonehold_twin_gate", "wooden_twin_gate", "stonehold_cliff_watch", "wooden_cliff_watch"]
const NAMES := {
	"delvers_hut": "Delver's Hut",
	"miners_homestead": "Miner's Homestead",
	"stone_hall": "Stone Hall",
	"forge_workshop": "Forge Workshop",
	"watchtower_cabin": "Watchtower & Cabin",
	"stone_watchtower": "Stone Watchtower",
	"stone_outpost": "Stone Outpost",
	"wooden_watchtower": "Wooden Watchtower",
	"wooden_outpost": "Wooden Outpost",
	"hearthbrick_brewhall": "Hearthbrick Brewhall",
	"wooden_brewhall": "Wooden Brewhall",
	"lantern_spire": "Lantern Spire",
	"wooden_spire": "Wooden Spire",
	"hearthbrick_manor": "Hearth Manor",
	"wooden_manor": "Wooden Manor",
	"stonehold_twin_gate": "Twin Gate",
	"wooden_twin_gate": "Wooden Twin Gate",
	"stonehold_cliff_watch": "Cliff Watch",
	"wooden_cliff_watch": "Wooden Cliff Watch",
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
		"lantern_spire": lib._lantern_spire()  # (owner, Nov 20: ruin 4, F479; learned by rebuilding its ruin)
		"wooden_spire":  # (its fire bowl stays stone: a wooden one would burn)
			lib._lantern_spire()
			lib._to_wood()
		"watchtower_cabin": lib._watchtower()
		"stone_watchtower": lib._stone_watchtower()
		"stone_outpost": lib._stone_outpost()
		"wooden_watchtower":  # (owner, Nov 19: rebuilding the ruined tower with wood teaches this one)
			lib._stone_watchtower()
			lib._to_wood()
		"wooden_outpost":  # (owner, Nov 20, F478: rebuilding the Fallen Outpost teaches this one)
			lib._stone_outpost()
			lib._to_wood()
		"stone_outpost_grid":  # (not a blueprint you learn: the old grid layout, which tools/ruins/make_outpost_ruin.py breaks)
			lib._stone_outpost(false)
		"hearthbrick_brewhall": lib._brewhall()
		"wooden_brewhall":  # (owner, Nov 20, F479: rebuilding the Brewhall in wood teaches this one)
			lib._brewhall()
			lib._to_wood()
			lib._brewhall_chimney_stays_brick()
		"hearthbrick_kiln": lib._old_kiln()  # (owner, Nov 21: ruin 5, F479; not learnable yet, its 3D page first)
		"wooden_kiln":  # (the kiln itself stays brick: a wooden oven would burn)
			lib._old_kiln()
			lib._to_wood()
			lib._kiln_stays_brick()
		"stonehold_twin_gate": lib._twin_gate()  # (owner, Nov 21: ruin 6, the first showpiece; not learnable yet, its 3D page first)
		"wooden_twin_gate":
			lib._twin_gate()
			lib._to_wood()
		"hearthbrick_manor": lib._hearth_manor()  # (owner, Nov 22: ruin 7, a showpiece; not learnable yet, its 3D page first)
		"wooden_manor":  # (its trims, brackets, short railings and roof windows are Hearthbrick only: they stay brick)
			lib._hearth_manor()
			lib._to_wood()
		"stonehold_cliff_watch": lib._cliff_watch()  # (owner, Nov 22: ruin 8, layered; not learnable yet, its 3D page first)
		"wooden_cliff_watch":  # (its brackets and trim bands have no wooden version: they stay stone)
			lib._cliff_watch()
			lib._to_wood()
		_: return null
	lib._bp.name = NAMES.get(id, id)
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
func _ring_layer(square_id: String, tri_id: String, y: float, skip_square: int = -1, mat := STONE, middle := true) -> void:
	for k in 6:
		var n := _dir(2 * k)
		if middle:
			_add(tri_id, mat, n * (_APO * 2.0 / 3.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))          # middle hexagon
		if k != skip_square:
			_add(square_id, mat, n * (_APO + 1.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))         # square on its edge
		var u := _dir(2 * k + 1)
		_add(tri_id, mat, u * (2.0 + 2.0 / sqrt(3.0)) + Vector3(0, y, 0) + _ring_off, _rot(2 * k + 1))  # triangle in the gap


## The 12 outer edges at height y: `pick(j)` says which piece goes on edge j ("" = nothing).
func _ring_edges(y: float, pick: Callable, mat := STONE) -> void:
	for j in 12:
		var id: String = pick.call(j)
		if id != "":
			_add(id, mat, _dir(j) * _EDGE + Vector3(0, y, 0) + _ring_off, _rot(j))


## Stone pillars on the 12 outer corners (they cover the joints where two walls meet at an angle). Not the ones in
## `skip`: corner j sits between edges j and j+1, and a pillar beside a doorway cut into its arch stones (owner).
func _ring_pillars(y: float, skip: Array = [], mat := STONE) -> void:
	for j in 12:
		if j in skip:
			continue
		var a := (j + 0.5) * PI / 6.0
		_add("pillar", mat, Vector3(sin(a), 0, cos(a)) * (_CORNER - 0.05) + Vector3(0, y, 0) + _ring_off, _rot(j))


## Stairs in square `k` climbing along the ring (toward yaw step 2k+3). Stairs are 2 m tall but Stonehold floors are
## 2.25 m apart: a floor slab under them lifts them so their top step meets the next floor (owner: a lip at the top
## made the dwarf hop going down and struggle going up).
func _ring_stairs(k: int, y: float, mat := STONE) -> void:
	_add("floor", mat, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))
	_add("stairs", mat, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y + 0.25, 0) + _ring_off, _rot(2 * k + 9))


## Railings round the stairs hole in square `k` on the floor above: its inner edge and the side the stairs
## start from (the far side stays open: that's where you step off).
func _ring_rails(k: int, y: float, mat := STONE) -> void:
	var n := _dir(2 * k)
	var t := _dir(2 * k + 3)
	_add("railing", mat, n * _APO + Vector3(0, y, 0) + _ring_off, _rot(2 * k))
	_add("railing", mat, n * (_APO + 1.0) - t + Vector3(0, y, 0) + _ring_off, _rot(2 * k + 3))


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


## Owner, Nov 20 (ruin 4 of Zone 1): the Lantern Spire, a tall thin round Stonehold beacon tower, a landmark to find.
## The watchtower's 12-sided ring (every flat side 3.73 m from the middle), three walled floors, then an open lantern
## gallery (pillars on every corner, railings between) under a flat battlement roof; the fire bowl stands in the
## roof's middle (the Fire Bowl, a decor piece: its fire burns forever). Heights: foundations 0-1, walls
## from 1, 3.25 and 5.5, floors at 3, 5.25 and 7.5, the gallery from 7.75, the roof at 9.75 (battlements from 10).
## Few windows (owner, Nov 20): two narrow ones a floor, none beside the door. The stairs climb a different side on
## every floor, their foot on open floor; each stairs hole has a railing round it.
func _lantern_spire() -> void:
	_start(Vector3(10, 12, 12))
	_ring_layer("foundation", "foundation_triangle", 0.0)
	_add("foundation_steps", STONE, _dir(0) * (_EDGE + 1.0), 0)                        # up to the round front door
	var g := 1.0
	_ring_edges(g, func(j): return "doorway" if j == 0 else ("window_wall" if j in [4, 8] else "wall"))
	_add("door", STONE, _dir(0) * _EDGE + Vector3(0, g, 0), 0)
	_ring_pillars(g, [11, 0])
	_ring_stairs(2, g)
	var f2 := 3.0
	_ring_layer("floor", "floor_triangle", f2, 2)
	_ring_rails(2, f2 + 0.25)
	var w2 := f2 + 0.25
	_ring_edges(w2, func(j): return "window_wall" if j in [1, 7] else "wall")
	_ring_pillars(w2)
	_ring_stairs(4, w2)
	var f3 := w2 + 2.0
	_ring_layer("floor", "floor_triangle", f3, 4)
	_ring_rails(4, f3 + 0.25)
	var w3 := f3 + 0.25
	_ring_edges(w3, func(j): return "window_wall" if j in [4, 10] else "wall")
	_ring_pillars(w3)
	_ring_stairs(0, w3)
	var f4 := w3 + 2.0                                                                  # the lantern gallery
	_ring_layer("floor", "floor_triangle", f4, 0)
	_ring_rails(0, f4 + 0.25)
	_ring_edges(f4 + 0.25, func(_j): return "railing")
	_ring_pillars(f4 + 0.25)
	_ring_stairs(3, f4 + 0.25)
	var roof := f4 + 2.25
	_ring_layer("floor", "floor_triangle", roof, 3)
	_ring_rails(3, roof + 0.25)
	_ring_edges(roof + 0.25, func(_j): return "battlement")
	_add("beacon_bowl", STONE, Vector3(0, roof + 0.25, 0), 0)


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


func _stone_outpost(line_up := true) -> void:
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
	# (owner, Nov 20: the right wall's walkway goes on over the armoury/forge, z -6..2)
	for c in [[-9, 13], [-7, 13], [-13, 9], [13, -9], [13, -7], [13, -5], [13, -3], [13, -1], [13, 1]]:
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
		if pp.x == 12 and pp.y >= -6 and pp.y <= 2:
			# Over the armoury/forge (floor 0-0.25, roof 2.25-2.5): posts stand on its floor and go up through its roof's
			# edge (0.25-2.25, 2.25-4.25), not on its end walls (z -6 and 2: there the upper post stands on the wall).
			if pp.y > -6 and pp.y < 2:
				_add("pillar", STONE, Vector3(pp.x, 0.25, pp.y), 0)
			_add("pillar", STONE, Vector3(pp.x, 2.25, pp.y), 0)
			continue
		if key in ["-6,12", "-12,10", "12,-10", "-10,12"]:
			continue  # a building's wall or a round tower is already there
		for y in [0.0, 2.0]:
			_add("pillar", STONE, Vector3(pp.x, y, pp.y), 0)
	_wall_x("railing", 13, 2, 4.5, STONE)  # across the walkway's end over the forge (it stops before the breach)
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
	if line_up:
		_outpost_line_up()


## Owner, Nov 17 (F305) and Nov 20 (F478): the outpost as its ruin stands, so it can be rebuilt over the ruin. A 12-sided
## tower can't match the 2 m grid on two sides, so two parts slide (the same numbers as tools/ruins/make_outpost_ruin.py):
## the whole front (gate, gatehouse, front wall, front-right tower, the right wall up to the breach) 0.73 m out and 0.27 m
## left, so the front walkway meets the front-left round tower's flat side; the right wall from the breach back (with its
## walkway and the armoury/forge) 0.73 m out and 0.27 m back, to meet the back-right round tower. The posts that closed
## the old 27 cm seams go. Where the two parts meet (the breach in the right wall) they are 1 m apart sideways and 3 m
## apart along the wall: a 2 m wall, a 1 m wall across and a 1 m wall close it (owner, Nov 20: "there is a gap").
const _OUT_FRONT := Vector3(-0.27, 0, 0.73)
const _OUT_RIGHT := Vector3(0.73, 0, -0.27)


func _outpost_part(id: String, x: float, z: float) -> String:
	var near := func(px: float, pz: float) -> bool: return absf(x - px) < 0.2 and absf(z - pz) < 0.2
	if id == "pillar" and (near.call(-9.1, 14.0) or near.call(14.0, -9.1)):
		return "gone"
	if absf(x - 14.0) < 0.1 and absf(z - 5.0) < 0.1:
		return "gone"  # the one wall cell between the two parts: replaced by the step below
	if (x > -9.35 and z >= 7.9) or (id == "foundation_steps" and near.call(11.0, 7.0)) or (x >= 13.9 and z >= 5.9 and z < 7.9):
		return "front"
	if x >= 9.9 and z >= -9.35 and z < 4.5 and Vector2(x - _OUT_RT, z + 13.0).length() > 4.0:
		return "right"
	return ""


func _outpost_line_up() -> void:
	var kept: Array[Dictionary] = []
	for p in _bp.pieces:
		var part := _outpost_part(String(p.id), p.pos.x, p.pos.z)
		if part == "gone":
			continue
		if part != "":
			p.pos += _OUT_FRONT if part == "front" else _OUT_RIGHT
		kept.append(p)
	_bp.pieces = kept
	# The step in the right wall: the back part's wall line (x 14.73) ends at z 3.73, the front part's (x 13.73) at 6.73.
	for y in [0.0, 2.0]:
		_add("wall", STONE, Vector3(14.73, y, 4.73), 1)         # z 3.73 .. 5.73
		_add("wall_narrow", STONE, Vector3(14.23, y, 5.73), 0)  # across, x 13.73 .. 14.73
		_add("wall_narrow", STONE, Vector3(13.73, y, 6.23), 1)  # z 5.73 .. 6.73
	_add("battlement", STONE, Vector3(14.73, 4.0, 4.73), 1)


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


## F479 (owner, Nov 20): the third ruin's whole version, the Brewhall: a Hearthbrick (clay brick) dwarf tavern and
## brewery, an L round a yard (about 15 x 12 m). Plan on the 2 m grid (x right, z front):
##   - The main hall (x -8..0, z -6..4): two floors on foundations, a peaked roof (ridge along z, gables front and
##     back), the round front door in the front gable wall; stairs up to the sleeping loft (railing round their hole);
##     a side door to the yard and a doorway into the brewery.
##   - The brewery wing (x 0..6, z -6..-2): one tall floor, its roof (ridge along x) running into the hall's side wall;
##     a cellar under its right part (floor 1.25 m below the ground), stairs down along the wing; a door to the yard.
##   - The chimney: a 2 x 1.3 m brick stack (two walls and two narrow walls per 2 m) outside the wing's end, 8 m tall.
##   - The yard (x 0..6, z -2..4): railings round it with a gap in the front, a railed brick well in its corner.
## Heights: foundations 0..1, ground walls 1..3, the loft floor at 3, loft walls 3.25..5.25, the hall roof from 5.25
## (ridge 7.25); the wing roof from 3 (ridge 4); cellar floor -1.5, cellar walls -1.25..0.75, the wing floor over it 0.75.
const _BREW_CHIMNEY := Vector3(7.17, 0, -4)   # the chimney's middle (2 cm off the wing's end wall)


func _brewhall() -> void:
	_start(Vector3(18, 9, 12))
	var B := BRICK
	var hx := [-7, -5, -3, -1]
	var hz := [-5, -3, -1, 1, 3]
	# --- foundations: the hall and the wing's left cells (the cellar is under the rest of the wing)
	for x in hx:
		for z in hz:
			_add("foundation", B, Vector3(x, 0, z), 0)
	for z in [-5, -3]:
		_add("foundation", B, Vector3(1, 0, z), 0)
	_add("foundation_steps", B, Vector3(-5, 0, 5), 0)    # up to the round front door
	_add("foundation_steps", B, Vector3(1, 0, 1), 1)     # from the yard up to the hall's side door
	_add("foundation_steps", B, Vector3(3, 0, -1), 0)    # from the yard up to the brewery door
	# (owner, Nov 20: no steps in a corner, every one lands on open yard; no window right beside a door; fewer windows)
	# --- the hall, ground floor (walls 1..3)
	var y := 1.0
	for e in [["wall", -7], ["doorway", -5], ["wall", -3], ["window_wall", -1]]:
		_wall_x(e[0], e[1], 4, y, B)
	for e in [["wall", -7], ["window_wall", -5], ["wall", -3], ["wall", -1]]:
		_wall_x(e[0], e[1], -6, y, B)
	for e in [["wall", -5], ["window_wall", -3], ["wall", -1], ["wall", 1], ["window_wall", 3]]:
		_wall_z(e[0], -8, e[1], y, B)
	for e in [["wall", -5], ["doorway", -3], ["wall", -1], ["doorway", 1], ["wall", 3]]:
		_wall_z(e[0], 0, e[1], y, B)
	_add("door", B, Vector3(-5, y, 4), 0)
	_add("door", B, Vector3(0, y, -3), 1)
	_add("door", B, Vector3(0, y, 1), 1)
	# stairs in the middle of the hall's left half, climbing to the back; their foot on open floor (a slab under them
	# lifts their top step level with the loft floor)
	_add("floor", B, Vector3(-5, y, -1), 0)
	_add("stairs", B, Vector3(-5, y + 0.25, -1), 0)
	# --- the sleeping loft (floor at 3, walls 3.25..5.25), a railing round the stairs hole (not its top end)
	var y2 := 3.0
	for x in hx:
		for z in hz:
			if not (x == -5 and z == -1):
				_add("floor", B, Vector3(x, y2, z), 0)
	var y3 := y2 + 0.25
	_wall_z("railing", -6, -1, y3, B)
	_wall_z("railing", -4, -1, y3, B)
	_wall_x("railing", -5, 0, y3, B)
	for e in [["wall", -7], ["window_wide", -5], ["wall", -3], ["window_wall", -1]]:
		_wall_x(e[0], e[1], 4, y3, B)
	for e in [["wall", -7], ["window_wall", -5], ["wall", -3], ["wall", -1]]:
		_wall_x(e[0], e[1], -6, y3, B)
	for e in [["wall", -5], ["window_wall", -3], ["wall", -1], ["window_wall", 1], ["wall", 3]]:
		_wall_z(e[0], -8, e[1], y3, B)
	for e in [["wall", -5], ["wall", -3], ["wall", -1], ["window_wall", 1], ["wall", 3]]:
		_wall_z(e[0], 0, e[1], y3, B)   # (behind the wing's roof at the back)
	# --- the hall roof: ridge along z at x = -4, two rows each side; gables front and back, a half wall under the
	# upper gables
	var top := y3 + 2.0
	for z in hz:
		_add("roof_26", B, Vector3(-7, top, z), 3)
		_add("roof_26", B, Vector3(-5, top + 1.0, z), 3)
		_add("roof_26", B, Vector3(-3, top + 1.0, z), 1)
		_add("roof_26", B, Vector3(-1, top, z), 1)
	for gz in [4, -6]:
		_add("gable_26", B, Vector3(-7, top, gz), 0)
		_add("gable_26", B, Vector3(-1, top, gz), 2)
		_wall_x("half_wall", -5, gz, top, B)
		_wall_x("half_wall", -3, gz, top, B)
		_add("gable_26", B, Vector3(-5, top + 1.0, gz), 0)
		_add("gable_26", B, Vector3(-3, top + 1.0, gz), 2)
	# --- the brewery wing (walls 1..3); its floor over the cellar at 0.75
	for e in [["wall", 1], ["window_wall", 3], ["wall", 5]]:
		_wall_x(e[0], e[1], -6, y, B)
	for e in [["wall", 1], ["doorway", 3], ["wall", 5]]:
		_wall_x(e[0], e[1], -2, y, B)
	_add("door", B, Vector3(3, y, -2), 0)
	_wall_z("wall", 6, -5, y, B)
	_wall_z("wall", 6, -3, y, B)
	for c in [Vector2(3, -3), Vector2(5, -5), Vector2(5, -3)]:
		_add("floor", B, Vector3(c.x, 0.75, c.y), 0)
	_wall_x("railing", 3, -4, y, B)   # round the cellar stairs' hole at the back (their top end, at x 2, stays open)
	_wall_z("railing", 4, -5, y, B)
	for z in [-3, -5]:
		_add("roof_26", B, Vector3(1, 3.0, z), 0 if z == -3 else 2)
		_add("roof_26", B, Vector3(3, 3.0, z), 0 if z == -3 else 2)
		_add("roof_26", B, Vector3(5, 3.0, z), 0 if z == -3 else 2)
	_add("gable_26", B, Vector3(6, 3.0, -3), 1)
	_add("gable_26", B, Vector3(6, 3.0, -5), 3)
	# --- the cellar (x 2..6, z -6..-2): floor at -1.5, walls -1.25..0.75, stairs up along the wing toward the hall
	_floors(2, -6, 6, -2, -1.5, B)
	for x in [3, 5]:
		_wall_x("wall", x, -6, -1.25, B)
		_wall_x("wall", x, -2, -1.25, B)
	for z in [-5, -3]:
		_wall_z("wall", 2, z, -1.25, B)
		_wall_z("wall", 6, z, -1.25, B)
	_add("floor", B, Vector3(3, -1.25, -5), 0)
	_add("stairs", B, Vector3(3, -1.0, -5), 1)          # climbs toward -x, its foot on the open cellar floor
	# --- the chimney (outside the wing's end wall)
	for lvl in 4:
		_brew_chimney_level(lvl * 2.0, B)
	# --- the yard: railings round it (a gap in the middle of the front), a railed brick well in the front-right corner
	# (its own railings close the fence there), clear of every step
	for z in [-1, 1]:
		_wall_z("railing", 6, z, 0.0, B)
	_wall_x("railing", 1, 4, 0.0, B)
	_floors(4, 2, 6, 4, 0.0, B)
	_wall_x("railing", 5, 2, 0.25, B)
	_wall_x("railing", 5, 4, 0.25, B)
	_wall_z("railing", 4, 3, 0.25, B)
	_wall_z("railing", 6, 3, 0.25, B)
	# No furniture: you furnish it yourself (owner, Nov 16).


## One 2 m level of the Brewhall's chimney: walls on its long sides, narrow walls across its ends.
func _brew_chimney_level(y: float, mat: String) -> void:
	var c := _BREW_CHIMNEY
	_wall_x("wall", c.x, c.z - 0.5, y, mat)
	_wall_x("wall", c.x, c.z + 0.5, y, mat)
	_wall_z("wall_narrow", c.x - 0.83, c.z, y, mat)
	_wall_z("wall_narrow", c.x + 0.83, c.z, y, mat)


## The Wooden Brewhall keeps a brick chimney (a wooden one would burn; asked the owner, Nov 20).
func _brewhall_chimney_stays_brick() -> void:
	for p in _bp.pieces:
		if p.pos.x > 6.1:
			p.mat = BRICK


## Owner, Nov 21 (ruin 5 of Zone 1, F479): the Old Kiln, where the kiln-master fired Hearthbrick. Clay brick.
## Plan on the 2 m grid (x right, z front):
##   - The kiln (centre x 6.27, z -1): a fat round brick oven tower on the watchtower's 12-sided ring, open on top
##     like a giant chimney. The firing floor on foundations (0..1), its round door at the front (steps up to it), a
##     second round door on its right into the shed. Walls 1..3, then a gallery floor at 3 round the inside (its
##     middle open: you look down into the firing floor, railings round the hole), stairs up to it on the back left
##     (their foot on open floor), walls 3.25..5.25 with two small windows. On top (owner, Nov 21): a ring of
##     sloped tile roof rising inward to a stone lip round a six-sided hole (still open like a chimney, right over
##     the gallery's open middle), railings on the lip: the Kiln Crown, one new piece (kiln_crown, 5.25..6.25);
##     tools/ruins/make_kiln_ruin.py adds it and its railings until it is a game piece.
##   - The lean-to shed (x 10..14, z -2..0) against the kiln's right side (its flat side is exactly on x 10): one
##     slope from the kiln wall down to its end wall, open at the front (a pillar at the corner), for firewood.
##   - The kiln-master's house (x -14..-2, z -6..2): two floors on foundations, a peaked roof (ridge along x, gables
##     at both ends), the round front door into the yard, a side door toward the kiln (steps up to both, landing on
##     open ground), stairs inside climbing to the back (railings round their hole). Few windows, none beside a door.
##   - The yard (x -14..-2, z 2..8) in front of the house: brick half walls round it, a gate gap in front of the
##     door and one on the kiln side.
## Heights: foundations 0..1, walls 1..3, floors at 3, walls 3.25..5.25, the house roof from 5.25 (ridge 7.25).
## No flat roof anywhere (Hearthbrick roofs slope); no furniture (you furnish it yourself).
const _KILN := Vector3(6.268, 0, -1)   # the kiln's middle: its right flat side lands on x = 10 (3.732 m out)


func _old_kiln() -> void:
	_start(Vector3(30, 8, 18))
	var B := BRICK
	# --- the kiln
	_ring_off = _KILN
	_ring_layer("foundation", "foundation_triangle", 0.0, -1, B)
	_add("foundation_steps", B, _dir(0) * (_EDGE + 1.0) + _KILN, 0)                    # up to its round front door
	var g := 1.0
	_ring_edges(g, func(j): return "doorway" if j in [0, 3] else "wall", B)
	_add("door", B, _dir(0) * _EDGE + Vector3(0, g, 0) + _KILN, 0)
	_add("door", B, _dir(3) * _EDGE + Vector3(0, g, 0) + _KILN, _rot(3))              # into the shed
	_ring_pillars(g, [11, 0, 2, 3], B)                                                  # (none beside a doorway)
	_ring_stairs(4, g, B)                                                               # back left, up to the gallery
	var f2 := 3.0
	_ring_layer("floor", "floor_triangle", f2, 4, B, false)                             # the gallery: its middle open
	for k in 6:                                                                         # railings round the open middle
		_add("railing", B, _dir(2 * k) * _APO + Vector3(0, f2 + 0.25, 0) + _KILN, _rot(2 * k))
	_add("railing", B, _dir(8) * (_APO + 1.0) - _dir(11) + Vector3(0, f2 + 0.25, 0) + _KILN, _rot(11))   # stairs' foot side
	var w2 := f2 + 0.25
	_ring_edges(w2, func(j): return "window_wall" if j in [6, 9] else "wall", B)
	_ring_pillars(w2, [], B)
	# (the Kiln Crown on top, 5.25: added by tools/ruins/make_kiln_ruin.py until it is a game piece)
	_ring_off = Vector3.ZERO
	# --- the lean-to shed against the kiln's right side (x 10..14, z -2..0)
	_add("foundation", B, Vector3(11, 0, -1), 0)
	_add("foundation", B, Vector3(13, 0, -1), 0)
	_wall_x("wall", 11, -2, g, B)
	_wall_x("wall", 13, -2, g, B)
	_wall_z("wall", 14, -1, g, B)
	_add("pillar", B, Vector3(13.95, g, -0.05), 0)                                      # the open front's corner
	_add("roof_26", B, Vector3(11, 4.0, -1), 1)                                         # one slope, high by the kiln
	_add("roof_26", B, Vector3(13, 3.0, -1), 1)
	_wall_x("half_wall", 11, -2, 3.0, B)
	_add("gable_26", B, Vector3(11, 4.0, -2), 2)
	_add("gable_26", B, Vector3(13, 3.0, -2), 2)
	# --- the kiln-master's house (x -14..-2, z -6..2)
	var hx := [-13, -11, -9, -7, -5, -3]
	var hz := [-5, -3, -1, 1]
	for x in hx:
		for z in hz:
			_add("foundation", B, Vector3(x, 0, z), 0)
	_add("foundation_steps", B, Vector3(-9, 0, 3), 0)     # from the yard up to the front door
	_add("foundation_steps", B, Vector3(-1, 0, -3), 1)    # from the kiln side up to the side door
	var y := 1.0
	for e in [["window_wall", -13], ["wall", -11], ["doorway", -9], ["wall", -7], ["window_wall", -5], ["wall", -3]]:
		_wall_x(e[0], e[1], 2, y, B)
	for e in [["wall", -13], ["wall", -11], ["window_wall", -9], ["wall", -7], ["wall", -5], ["wall", -3]]:
		_wall_x(e[0], e[1], -6, y, B)
	for e in [["wall", -5], ["window_wall", -3], ["wall", -1], ["wall", 1]]:
		_wall_z(e[0], -14, e[1], y, B)
	for e in [["wall", -5], ["doorway", -3], ["wall", -1], ["wall", 1]]:
		_wall_z(e[0], -2, e[1], y, B)
	_add("door", B, Vector3(-9, y, 2), 0)
	_add("door", B, Vector3(-2, y, -3), 1)
	# stairs in the left half climbing to the back, their foot on open floor (a slab lifts their top to the floor)
	_add("floor", B, Vector3(-11, y, -3), 0)
	_add("stairs", B, Vector3(-11, y + 0.25, -3), 0)
	var y2 := 3.0
	for x in hx:
		for z in hz:
			if not (x == -11 and z == -3):
				_add("floor", B, Vector3(x, y2, z), 0)
	var y3 := y2 + 0.25
	_wall_z("railing", -12, -3, y3, B)
	_wall_z("railing", -10, -3, y3, B)
	_wall_x("railing", -11, -2, y3, B)
	for e in [["wall", -13], ["window_wall", -11], ["wall", -9], ["wall", -7], ["window_wall", -5], ["wall", -3]]:
		_wall_x(e[0], e[1], 2, y3, B)
	for e in [["wall", -13], ["wall", -11], ["wall", -9], ["window_wall", -7], ["wall", -5], ["wall", -3]]:
		_wall_x(e[0], e[1], -6, y3, B)
	for e in [["wall", -5], ["wall", -3], ["window_wall", -1], ["wall", 1]]:
		_wall_z(e[0], -14, e[1], y3, B)
	for e in [["wall", -5], ["wall", -3], ["window_wall", -1], ["wall", 1]]:
		_wall_z(e[0], -2, e[1], y3, B)
	# the roof: ridge along x at z = -2, two rows each side; gables at both ends (half walls under the upper ones)
	var top := y3 + 2.0
	for x in hx:
		_add("roof_26", B, Vector3(x, top, 1), 0)
		_add("roof_26", B, Vector3(x, top + 1.0, -1), 0)
		_add("roof_26", B, Vector3(x, top + 1.0, -3), 2)
		_add("roof_26", B, Vector3(x, top, -5), 2)
	for gx in [-14, -2]:
		_add("gable_26", B, Vector3(gx, top, 1), 1)
		_wall_z("half_wall", gx, -1, top, B)
		_add("gable_26", B, Vector3(gx, top + 1.0, -1), 1)
		_wall_z("half_wall", gx, -3, top, B)
		_add("gable_26", B, Vector3(gx, top + 1.0, -3), 3)
		_add("gable_26", B, Vector3(gx, top, -5), 3)
	# --- the yard: brick half walls round it on the ground, a gate gap in front of the door and one toward the kiln
	for x in [-13, -11, -7, -5, -3]:
		_wall_x("half_wall", x, 8, 0.0, B)
	for z in [3, 5, 7]:
		_wall_z("half_wall", -14, z, 0.0, B)
	for z in [3, 7]:
		_wall_z("half_wall", -2, z, 0.0, B)


## The Wooden Kiln keeps its kiln in brick (a wooden oven would burn): only the house, the yard and the shed are wood.
func _kiln_stays_brick() -> void:
	for p in _bp.pieces:
		if p.pos.x > 0.0 and p.pos.x < 10.5:
			p.mat = BRICK


## Owner, Nov 21 (ruin 6 of Zone 1, the first showpiece: docs/design/GRAND-RUIN-RECIPE.md): the Twin Gate, a Stonehold
## gate fort across a tunnel. Plan on the 2 m grid (x right, z front = the tunnel side; numbers before the 8 m shift
## at the end, which centres it in its box):
##   - Two gate towers (10 x 10 m, centres x -11 and 11, z -5..5) on foundations: a square base of three floors (walls
##     1, 3.25, 5.5; floors 3, 5.25; the deck 7.5), stairs climbing a different way on every floor (feet on open floor,
##     railings round the holes), a door to the drill yard and one into the guard room. On the deck the watchtower's
##     12-sided ring rises two more floors (walls 7.75 and 10, floor 9.75, its own deck 12), so each tower changes shape
##     as it climbs. The left tower then has a 6-sided lantern room on the ring's middle hexagon (walls 12.25, roof 14.25,
##     the fire bowl on top: the tallest point, about 16 m); the right twin stops at its ring's battlements (symmetry
##     broken once, on purpose).
##   - The gatehouse between them (x -6..6, z -3..3) on foundations: the outer gate (a 4 m gateway with two leaves) at
##     z 3, a passage, the inner gate at z -3 (two gates: the Twin Gate), a tall guard room either side (round doors into
##     the passage and the towers). In front, between the towers, a porch and a 12 m grand stair up to it. Over it all the
##     gate room (walls 5.5..7.5, level with the towers' third floor, doors into both): it juts 1 m out over the porch.
##     Its roof (7.75) joins the towers' decks: one wall walk from tower to tower.
##   - The drill yard behind (x -13..13, z -13..-5), closed by two-high walls with battlements and pillars.
##   - The barracks (x -13..13, z -23..-15) on foundations, a terrace in front (railings, a 6 m stair down to the yard):
##     a three-floor middle block (the mess hall with the main door, the sergeants' floor, the captain's floor, roof
##     7.75), two two-floor wings (bunk rooms) whose upper floors jut 1 m out over the terrace, roof 5.5; doors from the
##     middle block onto both wing roofs. A low kitchen (x 13..17) on the right wing's end, its own door outside.
## The new kit pieces (owner, Nov 21: "rebuild the ruin" with them): in each tower a spiral stair up to the deck, corner
## stairs, a stair railing and a down-sloped wall on the first flight; two floor hatches (murder holes) in the gate
## room over the passage; lattice walls on its back over the yard; edge strips along the jutting floors.
## tools/ruins/make_twin_gate_ruin.py adds the new pieces (the brackets under the jutting floors, the trim bands at the
## floor lines, the buttresses, the little corner turrets) until they are game pieces. No furniture: you furnish it.
const _TWIN_L := -11.0
const _TWIN_R := 11.0
var _tw_c := 0.0   # the tower being built: its middle (x) and which way its gate side faces (+1: +x)
var _tw_m := 1


func _twin_gate() -> void:
	_start(Vector3(40, 17, 36))
	_twin_tower(_TWIN_L, 1)
	_twin_ring_stage(_TWIN_L, 3, 3, 5, true)
	_twin_tower(_TWIN_R, -1)
	_twin_ring_stage(_TWIN_R, 9, 3, 1, false)
	_twin_gatehouse()
	_twin_yard()
	_twin_barracks()
	for p in _bp.pieces:
		p.pos.z += 8.0   # centred in its box (z -15..15)


## A spot in the tower being built: u across it (+5 = its gate side), v along z.
func _tp(u: float, y: float, v: float) -> Vector3:
	return Vector3(_tw_c + _tw_m * u, y, v)


## The tower's square base (see _twin_gate). Its wall pieces by side ("front", "back", "outer", "inner") and floor.
func _twin_tower(cx: float, m: int) -> void:
	_tw_c = cx
	_tw_m = m
	var S := STONE
	var cells := [-4, -2, 0, 2, 4]
	for u in cells:
		for v in cells:
			_add("foundation", S, _tp(u, 0, v), 0)
	_add("foundation_steps", S, _tp(0, 0, -6), 2)                       # down to the drill yard
	var ys := [1.0, 3.25, 5.5]
	for lvl in 3:
		var y: float = ys[lvl]
		for c in cells:
			_add(_twin_wall("front", c, lvl), S, _tp(c, y, 5), 0)
			_add(_twin_wall("back", c, lvl), S, _tp(c, y, -5), 0)
			_add(_twin_wall("outer", c, lvl), S, _tp(-5, y, c), 1)
			_add(_twin_wall("inner", c, lvl), S, _tp(5, y, c), 1)
	_add("door", S, _tp(0, 1.0, -5), 0)                                 # to the yard
	_add("door", S, _tp(5, 1.0, 0), 1)                                  # into the guard room
	_add("door", S, _tp(5, 5.5, 0), 1)                                  # into the gate room
	# Stairs (owner, Nov 21: the new pieces worked in): floor 1 -> 2 straight in the front middle climbing to the back,
	# a stair railing on its gate side and a down-sloped wall closing its outer side; 2 -> 3 corner stairs on the outer
	# side climbing to the front; 3 -> the deck a spiral stair on the gate side, in and out toward the gate side.
	# Each foot on open floor, each starting where the last ends.
	var flights := [[Vector2(0, 2), 1.0, 0, "stairs"], [Vector2(-2, 0), 3.25, 2, "stairs_corner"],
		[Vector2(2, 0), 5.5, 0 if m == 1 else 2, "stairs_spiral"]]
	for f in flights:
		var c: Vector2 = f[0]
		_add("floor", S, _tp(c.x, f[1], c.y), 0)                        # (a slab lifts each top step to the floor)
		_add(f[3], S, _tp(c.x, f[1] + 0.25, c.y), f[2])
	_add("railing_stairs", S, _tp(1, 1.25, 2), 1)                       # (climbs with the steps toward -z)
	_add("sloped_wall_down", S, _tp(-1, 1.0, 2), 1)                     # (full at the stairs' foot, under the floor above)
	var floors := [3.0, 5.25, 7.5]
	for i in 3:
		var hole: Vector2 = flights[i][0]
		for u in cells:
			for v in cells:
				if not (u == hole.x and v == hole.y):
					_add("floor", S, _tp(u, floors[i], v), 0)
		var ry: float = floors[i] + 0.25
		# round the hole: both sides and the foot's end (not over the stair railing; the spiral: not its way out)
		_add("railing", S, _tp(hole.x - 1, ry, hole.y), 1)
		if i == 2:
			_add("railing", S, _tp(hole.x, ry, hole.y - 1), 0)
		elif i == 1:
			_add("railing", S, _tp(hole.x + 1, ry, hole.y), 1)
		_add("railing", S, _tp(hole.x, ry, hole.y + (1 if flights[i][2] == 0 or i == 2 else -1)), 0)
	for c in cells:
		_add("battlement", S, _tp(c, 7.75, 5), 0)
		_add("battlement", S, _tp(c, 7.75, -5), 0)
		_add("battlement", S, _tp(-5, 7.75, c), 1)
		if absi(c) == 4:                                                 # (open where the gate room's roof joins)
			_add("battlement", S, _tp(5, 7.75, c), 1)


func _twin_wall(side: String, c: int, lvl: int) -> String:
	match side:
		"inner":
			return "doorway" if c == 0 and lvl != 1 else "wall"
		"back":
			if lvl == 0:
				return "doorway" if c == 0 else "wall"
			return "window_wall" if (lvl == 1 and absi(c) == 2) or (lvl == 2 and c == 0) else "wall"
		"front":
			if lvl == 2 and c == 0:
				return "window_wide"
			return "window_wall" if lvl == 1 and absi(c) == 2 else "wall"
		"outer":
			return "window_wall" if (lvl == 1 and c == 0) or (lvl == 2 and absi(c) == 2) else "wall"
	return "wall"


## The 12-sided stage on a tower's deck (7.75): a door out onto the wall walk on edge door_j, stairs in squares k1
## (deck -> 9.75) and k2 (-> 12); then battlements, or (lantern) the 6-sided lantern room with the fire bowl on top.
func _twin_ring_stage(cx: float, door_j: int, k1: int, k2: int, lantern: bool) -> void:
	_ring_off = Vector3(cx, 0, 0)
	var y := 7.75
	_ring_edges(y, func(j): return "doorway" if j == door_j else ("window_wall" if j in [0, 6, (door_j + 6) % 12] else "wall"))
	_add("door", STONE, _dir(door_j) * _EDGE + Vector3(0, y, 0) + _ring_off, _rot(door_j))
	_ring_pillars(y, [posmod(door_j - 1, 12), door_j])
	_ring_stairs(k1, y)
	_ring_layer("floor", "floor_triangle", 9.75, k1)
	_ring_rails(k1, 10.0)
	_ring_edges(10.0, func(j): return "window_wall" if j % 4 == 1 else "wall")
	_ring_pillars(10.0)
	_ring_stairs(k2, 10.0)
	_ring_layer("floor", "floor_triangle", 12.0, k2)
	var top := 12.25
	_ring_edges(top, func(_j): return "battlement")
	if not lantern:
		_ring_rails(k2, top)
		_ring_off = Vector3.ZERO
		return
	# the lantern room: walls on the middle hexagon's six edges (its door on the front edge, by the stairs' top);
	# one railing on the stairs' foot side (the lantern's wall closes the other)
	_add("railing", STONE, _dir(2 * k2) * (_APO + 1.0) - _dir(2 * k2 + 3) + Vector3(0, top, 0) + _ring_off, _rot(2 * k2 + 3))
	for k in 6:
		_add("doorway" if k == 0 else "window_wall", STONE, _dir(2 * k) * _APO + Vector3(0, top, 0) + _ring_off, _rot(2 * k))
		if k not in [0, 5]:                                              # (no pillar beside the doorway)
			_add("pillar", STONE, _dir(2 * k + 1) * 1.95 + Vector3(0, top, 0) + _ring_off, _rot(2 * k + 1))
		_add("floor_triangle", STONE, _dir(2 * k) * (_APO * 2.0 / 3.0) + Vector3(0, top + 2.0, 0) + _ring_off, _rot(2 * k))
		_add("battlement", STONE, _dir(2 * k) * _APO + Vector3(0, top + 2.25, 0) + _ring_off, _rot(2 * k))
	_add("door", STONE, _dir(0) * _APO + Vector3(0, top, 0) + _ring_off, 0)
	_add("beacon_bowl", STONE, Vector3(0, top + 2.25, 0) + _ring_off, 0)
	_ring_off = Vector3.ZERO


## The gatehouse between the towers, its porch and grand stair, and the gate room over it (see _twin_gate).
func _twin_gatehouse() -> void:
	var S := STONE
	for x in [-5, -3, -1, 1, 3, 5]:
		for z in [-2, 0, 2, 4]:
			_add("foundation", S, Vector3(x, 0, z), 0)                  # (z 4: the porch)
		_add("foundation_steps", S, Vector3(x, 0, 6), 0)                # the grand stair up to the outer gate
		if absi(x) < 5:                                                 # (not against the towers' walls)
			_add("foundation_steps", S, Vector3(x, 0, -4), 2)           # down from the inner gate to the yard
	for y in [1.0, 3.0]:                                                # the guard rooms: one tall floor (1..5)
		for x in [-5, -3, 3, 5]:
			var id := "window_wall" if y > 2.0 and absi(x) == 5 else "wall"
			_wall_x(id, x, 3, y, S)
			_wall_x(id, x, -3, y, S)
		for x in [-2, 2]:                                               # the passage's sides
			for z in [-2, 0, 2]:
				_wall_z("doorway" if y < 2.0 and z == 0 else "wall", x, z, y, S)
	_add("door", S, Vector3(-2, 1, 0), 1)
	_add("door", S, Vector3(2, 1, 0), 1)
	for z in [3, -3]:                                                   # the two gates
		_wall_x("gateway", 0, z, 1.0, S)
		_add("gate_leaf", S, Vector3(-0.8, 1.0, z), 0)
		_add("gate_leaf", S, Vector3(0.8, 1.0, z), 2)
	for z in [3, -3]:                                                   # lanterns either side of both gates
		for x in [-3, 3]:
			_on_wall_z("wall_sconce", S, x, z, 3.2, 1 if z > 0 else -1)
	# the gate room: two slabs (5..5.5, level with the towers' third floor), its front 1 m out over the porch
	for x in [-5, -3, -1, 1, 3, 5]:
		for z in [-2, 0, 2]:
			if absi(x) == 1 and z == 2:                                 # two murder holes over the passage, behind the outer gate
				_add("floor_hatch", S, Vector3(x, 5.25, z), 0)
			else:
				_add("floor", S, Vector3(x, 5.0, z), 0)
				_add("floor", S, Vector3(x, 5.25, z), 0)
			_add("floor", S, Vector3(x, 7.5, z), 0)
		_add("floor_half", S, Vector3(x, 5.25, 3.5), 0)                 # the jutting strip (on brackets)
		_add("floor_half", S, Vector3(x, 7.5, 3.5), 0)
		_add("edge_strip", S, Vector3(x, 5.25, 4), 0)                   # a lip along both its floor lines
		_add("edge_strip", S, Vector3(x, 7.5, 4), 0)
		var front := "window_wide" if absi(x) == 1 else ("window_wall" if absi(x) == 3 else "wall")
		_wall_x(front, x, 4, 5.5, S)
		var back := "window_wall" if absi(x) == 1 else ("lattice_wall" if absi(x) == 3 else "wall")   # (looks down on the yard)
		_wall_x(back, x, -3, 5.5, S)
		_wall_x("battlement", x, 4, 7.75, S)
		_wall_x("battlement", x, -3, 7.75, S)


## The drill yard's side walls (two walls high, battlements, a pillar on the middle joint).
func _twin_yard() -> void:
	for side in [-13, 13]:
		for z in [-6, -8, -10, -12]:
			_wall_z("wall", side, z, 0.0, STONE)
			_wall_z("wall", side, z, 2.0, STONE)
			_wall_z("battlement", side, z, 4.0, STONE)
		for y in [0.0, 2.0]:
			_add("pillar", STONE, Vector3(side, y, -9), 0)


## The barracks on its terrace, and the kitchen (see _twin_gate).
func _twin_barracks() -> void:
	var S := STONE
	var xs := range(-12, 13, 2)
	var zs := [-22, -20, -18, -16]
	for x in xs:
		for z in zs:
			_add("foundation", S, Vector3(x, 0, z), 0)
		_add("foundation", S, Vector3(x, 0, -14), 0)                    # the terrace
		if absi(x) > 2:
			_wall_x("railing", x, -13, 1.0, S)
		else:
			_add("foundation_steps", S, Vector3(x, 0, -12), 0)          # the stair down to the yard
	for s in [-13, 13]:   # (owner, Nov 21: a wall, not a fence, where the yard wall meets the wings)
		_wall_z("wall", s, -14, 1.0, S)
		_add("wall_narrow", S, Vector3(s, 3.0, -13.5), 1)
	# --- the middle block (x -5..5): three floors, the main door, stairs zig-zagging up, the roof 7.5
	var ys := [1.0, 3.25, 5.5]
	for lvl in 3:
		var y: float = ys[lvl]
		for x in [-4, -2, 0, 2, 4]:
			var f := "wall"
			match lvl:
				0: f = "doorway" if x == 0 else ("window_wall" if absi(x) == 4 else "wall")
				1: f = "window_wall" if absi(x) <= 2 else "wall"
				2: f = "window_wide" if x == 0 else ("window_wall" if absi(x) == 2 else "wall")
			_wall_x(f, x, -15, y, S)
			var bk := "window_wall" if (lvl == 1 and absi(x) == 2) or (lvl == 2 and x == 0) else "wall"
			_wall_x("doorway" if lvl == 0 and x == 0 else bk, x, -23, y, S)   # (the back door: out into the big cave)
		for side in [-5, 5]:
			for z in zs:
				var w := "doorway" if z == -20 else ("window_wall" if lvl == 2 and z == -16 else "wall")
				_wall_z(w, side, z, y, S)
			_add("door", S, Vector3(side, y, -20), 1)
	_add("door", S, Vector3(0, 1.0, -15), 0)
	_add("door", S, Vector3(0, 1.0, -23), 0)
	_add("foundation_steps", S, Vector3(0, 0, -24), 2)                  # (owner, Nov 21: the way on, into the big cave)
	var flights := [[Vector2(-2, -18), 1.0, 0], [Vector2(2, -18), 3.25, 2], [Vector2(-2, -18), 5.5, 0]]
	for f in flights:
		var c: Vector2 = f[0]
		_add("floor", S, Vector3(c.x, f[1], c.y), 0)
		_add("stairs", S, Vector3(c.x, f[1] + 0.25, c.y), f[2])
	var floors := [3.0, 5.25, 7.5]
	for i in 3:
		var hole: Vector2 = flights[i][0]
		for x in [-4, -2, 0, 2, 4]:
			for z in zs:
				if not (x == hole.x and z == hole.y):
					_add("floor", S, Vector3(x, floors[i], z), 0)
		var ry: float = floors[i] + 0.25
		_add("railing", S, Vector3(hole.x - 1, ry, hole.y), 1)
		_add("railing", S, Vector3(hole.x + 1, ry, hole.y), 1)
		_add("railing", S, Vector3(hole.x, ry, hole.y + (1 if flights[i][2] == 0 else -1)), 0)
	for x in [-4, -2, 0, 2, 4]:
		_wall_x("battlement", x, -15, 7.75, S)
		_wall_x("battlement", x, -23, 7.75, S)
	for side in [-5, 5]:
		for z in zs:
			_wall_z("battlement", side, z, 7.75, S)
	# --- the wings (x -13..-5 and 5..13): two floors, the upper one 1 m out over the terrace, the roof 5.25
	for s in [-1, 1]:
		var wx := [6 * s, 8 * s, 10 * s, 12 * s]
		for x in wx:
			_wall_x("doorway" if absi(x) == 10 else "wall", x, -15, 1.0, S)   # (plain: brackets sit over it)
			_wall_x("wall", x, -23, 1.0, S)
			_wall_x("wall" if absi(x) == 10 else "window_wall", x, -14, 3.25, S)
			_wall_x("window_wall" if absi(x) == 10 else "wall", x, -23, 3.25, S)
			for z in zs:
				_add("floor", S, Vector3(x, 3.0, z), 0)
				_add("floor", S, Vector3(x, 5.25, z), 0)
			_add("floor_half", S, Vector3(x, 3.0, -14.5), 0)
			_add("edge_strip", S, Vector3(x, 3.0, -14), 0)              # (the lip on the jutting floor's edge)
			_add("floor_half", S, Vector3(x, 5.25, -14.5), 0)
			_wall_x("battlement", x, -14, 5.5, S)
			_wall_x("battlement", x, -23, 5.5, S)
		_add("door", S, Vector3(10 * s, 1.0, -15), 0)
		for z in zs:
			_wall_z("doorway" if s > 0 and z == -20 else "wall", 13 * s, z, 1.0, S)   # (the right one: into the kitchen)
			_wall_z("window_wall" if z == -18 else "wall", 13 * s, z, 3.25, S)
			_wall_z("battlement", 13 * s, z, 5.5, S)
		for ex in [13 * s, 5 * s]:                                      # the jutting floor's two ends
			_add("wall_narrow", S, Vector3(ex, 3.25, -14.5), 1)
	_add("door", S, Vector3(13, 1.0, -20), 1)
	# --- the kitchen (x 13..17, z -23..-17): one floor, its own door and steps outside
	for x in [14, 16]:
		for z in [-22, -20, -18]:
			_add("foundation", S, Vector3(x, 0, z), 0)
			_add("floor", S, Vector3(x, 3.0, z), 0)
		_wall_x("doorway" if x == 16 else "wall", x, -17, 1.0, S)
		_wall_x("wall", x, -23, 1.0, S)
		_wall_x("battlement", x, -17, 3.25, S)
		_wall_x("battlement", x, -23, 3.25, S)
	for z in [-22, -20, -18]:
		_wall_z("window_wall" if z == -20 else "wall", 17, z, 1.0, S)
		_wall_z("battlement", 17, z, 3.25, S)
	_add("door", S, Vector3(16, 1.0, -17), 0)
	_add("foundation_steps", S, Vector3(16, 0, -16), 0)


## Owner, Nov 22 (ruin 7 of Zone 1, F479; a showpiece: docs/design/GRAND-RUIN-RECIPE.md): the Hearth Manor, a rich
## Hearthbrick family's house. Plan on the 2 m grid (x right, z front; numbers before the 1 m shift at the end, which
## puts the cells on odd numbers like every other blueprint):
##   - The hall (x -5..5, z -7..1): two floors on foundations, a steep roof (ridge along x at z -3, 9.25 m) with two
##     roof windows at the front and one at the back, gables at both ends. The round main door in the middle of the
##     front, a wide window over it; stairs inside climbing to the right (railings round their hole).
##   - The front terrace (x -5..5, z 1..5): foundations with railings, a 6 m wide flight of steps up to the main door.
##   - The left wing (x -13..-5, z -7..-3): two floors, its own steep roof (7.25 m) with a roof window, a side door at its
##     end (steps up to it), stairs inside. Its upper floor has a balcony that juts 1 m out over the front on brackets
##     (a door onto it from the upper room; a short railing at its end).
##   - The link (x 5..7, z -3..1): one low storey between the hall and the tower, a back door, its roof (5 m) running
##     into both their walls.
##   - The tower (x 7..11, z -3..1), the tallest part: three square storeys (spiral stairs, each flight on the other
##     side), then a gallery 1 m wider all round on brackets (railings), a lookout room with wide windows, and a
##     pyramid roof with a cap (12.25 m). So it changes shape twice: plain, then jutting out, then a spire.
##   - Trim bands at every floor line on the outside, corner blocks where two bands meet.
## Heights: foundations 0..1, walls 1..3, floors at 3, walls 3.25..5.25 (the tower: floor 5.25, walls 5.5..7.5,
## gallery floor 7.5, lookout walls 7.75..9.75). Every roof slopes (Hearthbrick); no furniture: you furnish it.
func _hearth_manor() -> void:
	_start(Vector3(36, 13, 16))
	var B := BRICK
	var g := 1.0
	var u := 3.25
	# --- the hall (cells x -4..4, z -6..0)
	for x in [-4, -2, 0, 2, 4]:
		for z in [-6, -4, -2, 0]:
			_add("foundation", B, Vector3(x, 0, z), 0)
			if not (x == 2 and z == -6):
				_add("floor", B, Vector3(x, 3.0, z), 0)
	for e in [["window_wall", -4], ["wall", -2], ["doorway", 0], ["wall", 2], ["window_wall", 4]]:
		_wall_x(e[0], e[1], 1, g, B)
	for e in [["window_wall", -4], ["wall", -2], ["window_wide", 0], ["wall", 2], ["window_wall", 4]]:
		_wall_x(e[0], e[1], 1, u, B)
	for y in [g, u]:
		for e in [["wall", -4], ["window_wall", -2], ["wall", 0], ["window_wall", 2], ["wall", 4]]:
			_wall_x(e[0], e[1], -7, y, B)
		for e in [["window_wall", 0], ["wall", -2], ["doorway", -4], ["wall", -6]]:   # the left side, into the wing
			_wall_z(e[0], -5, e[1], y, B)
		_add("door", B, Vector3(-5, y, -4), 1)
	for e in [["doorway", 0], ["wall", -2], ["window_wall", -4], ["wall", -6]]:       # the right side, into the link
		_wall_z(e[0], 5, e[1], g, B)
	for e in [["wall", 0], ["wall", -2], ["window_wall", -4], ["wall", -6]]:
		_wall_z(e[0], 5, e[1], u, B)
	_add("door", B, Vector3(0, g, 1), 0)
	_add("door", B, Vector3(5, g, 0), 1)
	# stairs at the back, climbing to the right (their foot on open floor; a slab lifts their top level with the floor)
	_add("floor", B, Vector3(2, g, -6), 0)
	_add("stairs", B, Vector3(2, g + 0.25, -6), 3)
	_wall_x("railing", 2, -5, u, B)
	_wall_z("railing", 1, -6, u, B)
	# the steep roof: ridge along x at z -3, two rows each side, gables at both ends (walls under the upper ones)
	var top := u + 2.0
	for x in [-4, -2, 0, 2, 4]:
		_add("roof_45", B, Vector3(x, top, 0), 0)
		_add("roof_45", B, Vector3(x, top + 2.0, -2), 0)
		_add("roof_45", B, Vector3(x, top + 2.0, -4), 2)
		_add("roof_45", B, Vector3(x, top, -6), 2)
	for gx in [-5, 5]:
		_add("gable_45", B, Vector3(gx, top, 0), 1)
		_wall_z("wall", gx, -2, top, B)
		_add("gable_45", B, Vector3(gx, top + 2.0, -2), 1)
		_wall_z("wall", gx, -4, top, B)
		_add("gable_45", B, Vector3(gx, top + 2.0, -4), 3)
		_add("gable_45", B, Vector3(gx, top, -6), 3)
	_add("dormer", B, Vector3(-2, top, 0), 0)
	_add("dormer", B, Vector3(2, top, 0), 0)
	_add("dormer", B, Vector3(0, top, -6), 2)
	# --- the front terrace: foundations, railings round it, a 6 m flight of steps up to the main door
	for x in [-4, -2, 0, 2, 4]:
		for z in [2, 4]:
			_add("foundation", B, Vector3(x, 0, z), 0)
	for x in [-2, 0, 2]:
		_add("foundation_steps", B, Vector3(x, 0, 6), 0)
	for z in [2, 4]:
		_wall_z("railing", -5, z, g, B)
		_wall_z("railing", 5, z, g, B)
	_wall_x("railing", -4, 5, g, B)
	_wall_x("railing", 4, 5, g, B)
	# --- the left wing (cells x -12..-6, z -6..-4)
	var wx := [-12, -10, -8, -6]
	for x in wx:
		for z in [-6, -4]:
			_add("foundation", B, Vector3(x, 0, z), 0)
			if not (x == -10 and z == -6):
				_add("floor", B, Vector3(x, 3.0, z), 0)
		_wall_x("wall", x, -3, g, B)                                              # (no door under the brackets)
		_wall_x(["window_wall", "wall", "doorway", "wall"][wx.find(x)], x, -3, u, B)
	for y in [g, u]:
		for e in [["wall", -12], ["window_wall", -10], ["wall", -8], ["window_wall", -6]]:
			_wall_x(e[0], e[1], -7, y, B)
	_wall_z("doorway", -13, -4, g, B)
	_wall_z("wall", -13, -6, g, B)
	_wall_z("window_wall", -13, -4, u, B)
	_wall_z("wall", -13, -6, u, B)
	_add("door", B, Vector3(-13, g, -4), 1)
	_add("foundation_steps", B, Vector3(-14, 0, -4), 3)                           # up to the side door
	_add("door", B, Vector3(-8, u, -3), 0)                                         # onto the balcony
	_add("floor", B, Vector3(-10, g, -6), 0)                                       # stairs climbing to the left
	_add("stairs", B, Vector3(-10, g + 0.25, -6), 1)
	_wall_x("railing", -10, -5, u, B)
	_wall_z("railing", -9, -6, u, B)
	# the balcony: whole floors (one cell deep, F626: no half or small floors) along the wing's front, brackets under
	# them at every wall's two ends and middle, railings round it (its right end is the hall's side wall)
	for x in wx:
		_add("floor", B, Vector3(x, 3.0, -2), 0)
		_wall_x("railing", x, -1, u, B)
	for x in [-12.75, -12, -11, -10, -9, -8, -7, -6, -5.25]:
		_on_wall_z("corbel", B, x, -3, 2.0, 1)
	_wall_z("railing", -13, -2, u, B)
	# its steep roof (ridge along x at z -5, running into the hall's end wall), gables at its end, a roof window
	for x in wx:
		_add("roof_45", B, Vector3(x, top, -4), 0)
		_add("roof_45", B, Vector3(x, top, -6), 2)
	_add("gable_45", B, Vector3(-13, top, -4), 1)
	_add("gable_45", B, Vector3(-13, top, -6), 3)
	_add("dormer", B, Vector3(-10, top, -4), 0)
	# --- the link (x 5..7, z -3..1): one storey, a back door (steps behind), its roof between the hall and the tower
	for z in [-2, 0]:
		_add("foundation", B, Vector3(6, 0, z), 0)
	_wall_x("wall", 6, 1, g, B)
	_wall_x("doorway", 6, -3, g, B)
	_add("door", B, Vector3(6, g, -3), 0)
	_add("foundation_steps", B, Vector3(6, 0, -4), 2)
	_add("roof_45", B, Vector3(6, 3.0, 0), 0)
	_add("roof_45", B, Vector3(6, 3.0, -2), 2)
	# --- the tower (cells x 8..14, z -6..0): 4 by 4 (F626: room for spiral stairs that open onto floor), three
	# storeys, then a lookout room on its roof with a gallery of whole floors round it
	var tx := [8, 10, 12, 14]
	var tz := [-6, -4, -2, 0]
	for x in tx:
		for z in tz:
			_add("foundation", B, Vector3(x, 0, z), 0)
	var lv := [g, u, 5.5]          # its three storeys' walls
	var fys := [3.0, 5.25, 7.5]    # the floors above them
	# Each spiral stair goes in and comes out on the same side (its +x side, turned with it), so that side always faces
	# open floor: up from the ground in the back-right corner, from the first floor in the back-left, from the second
	# in the front-right (out onto the gallery by the lookout's door).
	var flights := [[Vector2(14, -6), 2], [Vector2(8, -6), 0], [Vector2(14, 0), 2]]
	for i in 3:
		var y: float = lv[i]
		for x in tx:
			_wall_x("window_wall" if i < 2 and x in [10, 12] else "wall", x, 1, y, B)
			_wall_x("window_wall" if i == 1 and x in [10, 12] else "wall", x, -7, y, B)
		for z in tz:
			_wall_z("window_wall" if i < 2 and z in [-4, -2] else "wall", 15, z, y, B)
			_wall_z("doorway" if i == 0 and z == 0 else "wall", 7, z, y, B)
		var c: Vector2 = flights[i][0]
		_add("floor", B, Vector3(c.x, y, c.y), 0)                       # (a slab lifts its top level with the floor)
		_add("stairs_spiral", B, Vector3(c.x, y + 0.25, c.y), flights[i][1])
		for x in tx:
			for z in tz:
				if x != int(c.x) or z != int(c.y):
					_add("floor", B, Vector3(x, fys[i], z), 0)
		_wall_x("railing", c.x, -5 if c.y < -3 else -1, fys[i] + 0.25, B)   # the hole's other open side
	_add("door", B, Vector3(7, g, 0), 1)
	# the gallery: railings all round the tower's top
	var ry := 7.75
	for x in tx:
		_wall_x("railing", x, 1, ry, B)
		_wall_x("railing", x, -7, ry, B)
	for z in tz:
		_wall_z("railing", 7, z, ry, B)
		_wall_z("railing", 15, z, ry, B)
	# the lookout room (cells x 10..12, z -4..-2): wide windows all round, a round door at the top of the stairs
	_wall_x("doorway", 12, -1, ry, B)
	_add("door", B, Vector3(12, ry, -1), 0)
	_wall_x("wall", 10, -1, ry, B)
	for k in [10, 12]:
		_wall_x("window_wide", k, -5, ry, B)
	for z in [-4, -2]:
		_wall_z("window_wide", 9, z, ry, B)
		_wall_z("window_wide", 13, z, ry, B)
	# its pyramid roof: four outside corners, each turned so its high corner points at the middle (no cap: F626)
	var py := ry + 2.0
	_add("roof_45_outer", B, Vector3(10, py, -4), 2)
	_add("roof_45_outer", B, Vector3(12, py, -4), 1)
	_add("roof_45_outer", B, Vector3(10, py, -2), 3)
	_add("roof_45_outer", B, Vector3(12, py, -2), 0)
	# --- trim bands at the floor lines (outside only, never where a balcony, roof or gallery is), corner blocks
	var b3 := 2.95
	for x in [-4, -2, 0, 2, 4]:
		_on_wall_z("cornice", B, x, 1, b3, 1)
	for x in [-12, -10, -8, -6, -4, -2, 0, 2, 4]:
		_on_wall_z("cornice", B, x, -7, b3, -1)
	for z in [-6, -4]:
		_on_wall_x("cornice", B, -13, z, b3, -1)
		_on_wall_x("cornice", B, 5, z, b3, 1)
	_on_wall_x("cornice", B, -5, 0, b3, -1)
	for c in [Vector2(-5.17, 1.17), Vector2(-13.17, -7.17), Vector2(-13.17, -2.83), Vector2(5.17, -7.17)]:
		_add("cornice_corner", B, Vector3(c.x, b3, c.y), 0)
	for by in [b3, 5.2, 7.45]:     # the tower's bands (not where the link's roof leans on it)
		for x in tx:
			_on_wall_z("cornice", B, x, 1, by, 1)
			_on_wall_z("cornice", B, x, -7, by, -1)
		for z in tz:
			_on_wall_x("cornice", B, 15, z, by, 1)
			if by > 3.0 or z < -3:
				_on_wall_x("cornice", B, 7, z, by, -1)
		var cs := [Vector2(15.17, 1.17), Vector2(15.17, -7.17), Vector2(6.83, -7.17)]
		if by > 3.0:
			cs.append(Vector2(6.83, 1.17))
		for c in cs:
			_add("cornice_corner", B, Vector3(c.x, by, c.y), 0)
	for p in _bp.pieces:
		p.pos.x += 1.0   # cells on odd numbers, like every other blueprint (box x -18..18)


## Owner, Nov 22 (ruin 8 of Zone 1, F479; a LAYERED showpiece: docs/design/GRAND-RUIN-RECIPE.md "Layered builds"):
## Cliff Watch, a Stonehold lookout whose back is set into the cave's rock wall. "It goes up, then it expands, then it
## goes up, then it expands again." Plan on the 2 m grid (x right, z front; numbers before the shift at the end, which
## puts the cells on odd numbers like every other blueprint). Seen from the front AND from the side, the outline zig-zags:
##   - The plinth (x -9..9, z -5..7): foundations, side terraces, railings, a 6 m flight of steps up to the main door.
##   - Storey 1, the gate hall (x -5..5, z -5..3, walls 1): the round main door in the middle of the front, a side door
##     onto the left terrace, stairs up.
##   - Storey 2 juts OUT (walls 3.25): 2 m past both sides on brackets (the side terraces below stay covered walks),
##     and a bay window juts 2 m out over the main door on brackets.
##   - Storey 3 steps IN (x -3..3, z -5..1, walls 5.5): a narrow block; the roof of storey 2 round it is a walkable
##     terrace with battlements (doors out on both sides and the front).
##   - Storey 4 juts OUT again (x -5..5, z -5..3, walls 7.75): on brackets on the walls of storey 3, a stone pillar under
##     each front corner standing on the terrace.
##   - The roof deck (floor 9.75, battlements), and on it the six-sided lantern room (walls 10, roof 12) with the fire
##     bowl on top: the tallest point (about 14 m). So it changes shape: square, wider, narrow, wider, six-sided.
##   - Stairs climb on every storey, each foot on open floor, each top onto floor, railings round the holes.
##   - Trim bands under the battlements, corner blocks. Every floor a whole tile (F626). No furniture: you furnish it.
func _cliff_watch() -> void:
	_start(Vector3(22, 15, 18))
	var S := STONE
	# --- the plinth: foundations under everything, a 6 m flight of steps in front, railings round the terraces
	for x in range(-8, 9, 2):
		for z in range(-4, 7, 2):
			_add("foundation", S, Vector3(x, 0, z), 0)
	for x in [-2, 0, 2]:
		_add("foundation_steps", S, Vector3(x, 0, 8), 0)
	for x in [-8, -6, -4, 4, 6, 8]:
		_wall_x("railing", x, 7, 1.0, S)
	for z in range(-4, 7, 2):
		_wall_z("railing", -9, z, 1.0, S)
		_wall_z("railing", 9, z, 1.0, S)
	for x in [-8, -6, 6, 8]:
		_wall_x("railing", x, -5, 1.0, S)
	# --- storey 1, the gate hall (cells x -4..4, z -4..2)
	for e in [["window_wall", -4], ["wall", -2], ["doorway", 0], ["wall", 2], ["window_wall", 4]]:
		_wall_x(e[0], e[1], 3, 1.0, S)
	for x in range(-4, 5, 2):
		_wall_x("wall", x, -5, 1.0, S)
	for z in [-4, -2, 0, 2]:
		_wall_z("doorway" if z == 2 else "wall", -5, z, 1.0, S)
		_wall_z("window_wall" if z == -2 else "wall", 5, z, 1.0, S)
	_add("door", S, Vector3(0, 1.0, 3), 0)
	_add("door", S, Vector3(-5, 1.0, 2), 1)
	_add("floor", S, Vector3(-2, 1.0, 0), 0)            # stairs 1 -> 2 climbing to the back (a slab lifts their top)
	_add("stairs", S, Vector3(-2, 1.25, 0), 0)
	# --- storey 2: its floor juts 2 m out at both sides and in the bay over the door
	var f2 := []
	for x in range(-6, 7, 2):
		for z in [-4, -2, 0, 2]:
			f2.append(Vector2(x, z))
	for x in [-2, 0, 2]:
		f2.append(Vector2(x, 4))
	for c in f2:
		if c != Vector2(-2, 0):
			_add("floor", S, Vector3(c.x, 3.0, c.y), 0)
	_wall_z("railing", -3, 0, 3.25, S)
	_wall_z("railing", -1, 0, 3.25, S)
	_wall_x("railing", -2, 1, 3.25, S)
	for x in range(-6, 7, 2):
		_wall_x("wall", x, -5, 3.25, S)
	for z in [-4, -2, 0, 2]:
		for sx in [-7, 7]:
			_wall_z("window_wall" if z in [-2, 2] else "wall", sx, z, 3.25, S)
	for x in [-6, -4, 4, 6]:
		_wall_x("window_wall" if absi(x) == 4 else "wall", x, 3, 3.25, S)
	for e in [["window_wall", -2], ["window_wide", 0], ["window_wall", 2]]:
		_wall_x(e[0], e[1], 5, 3.25, S)
	_wall_z("wall", -3, 4, 3.25, S)
	_wall_z("wall", 3, 4, 3.25, S)
	_add("floor", S, Vector3(2, 3.25, 0), 0)            # stairs 2 -> 3 climbing to the back
	_add("stairs", S, Vector3(2, 3.5, 0), 0)
	# brackets under the jutting floors (a wall's two ends and middle; never over a door)
	for z in [-4.75, -4, -3, -2, -1, 0, 1, 2.75]:
		_on_wall_x("corbel", S, 5, z, 2.0, 1)
		if z < 1.0:
			_on_wall_x("corbel", S, -5, z, 2.0, -1)
	for x in [-2.75, -2, 2, 2.75]:
		_on_wall_z("corbel", S, x, 3, 2.0, 1)
	# --- storey 3 steps in (cells x -2..2, z -4..0); the roof of storey 2 round it is a terrace with battlements
	for x in range(-6, 7, 2):
		for z in [-4, -2, 0, 2]:
			if Vector2(x, z) != Vector2(2, 0):
				_add("floor", S, Vector3(x, 5.25, z), 0)
	for x in [-2, 0, 2]:
		_add("floor", S, Vector3(x, 5.25, 4), 0)
	_wall_z("railing", 1, 0, 5.5, S)
	for x in [-2, 0, 2]:
		_wall_x("wall", x, -5, 5.5, S)
	for x in [-2, 2]:
		_wall_x("window_wall", x, 1, 5.5, S)
	_wall_x("doorway", 0, 1, 5.5, S)
	_add("door", S, Vector3(0, 5.5, 1), 0)
	for sx in [-3, 3]:
		for z in [-4, -2, 0]:
			_wall_z("doorway" if z == -2 else "wall", sx, z, 5.5, S)
		_add("door", S, Vector3(sx, 5.5, -2), 1)
	for z in [-4, -2, 0, 2]:
		_wall_z("battlement", -7, z, 5.5, S)
		_wall_z("battlement", 7, z, 5.5, S)
	for x in [-6, -4, 4, 6]:
		_wall_x("battlement", x, 3, 5.5, S)
		_wall_x("battlement", x, -5, 5.5, S)
	for x in [-2, 0, 2]:
		_wall_x("battlement", x, 5, 5.5, S)
	_wall_z("battlement", -3, 4, 5.5, S)
	_wall_z("battlement", 3, 4, 5.5, S)
	_add("floor", S, Vector3(-2, 5.5, -2), 0)           # stairs 3 -> 4 climbing to the back
	_add("stairs", S, Vector3(-2, 5.75, -2), 0)
	# --- storey 4 juts out again (cells x -4..4, z -4..2): brackets on the walls of storey 3, pillars under its corners
	for x in range(-4, 5, 2):
		for z in [-4, -2, 0, 2]:
			if Vector2(x, z) != Vector2(-2, -2):
				_add("floor", S, Vector3(x, 7.5, z), 0)
	_wall_z("railing", -3, -2, 7.75, S)
	_wall_z("railing", -1, -2, 7.75, S)
	_wall_x("railing", -2, -1, 7.75, S)
	for z in [-4.75, -4, 0, 0.75]:
		_on_wall_x("corbel", S, 3, z, 6.5, 1)
		_on_wall_x("corbel", S, -3, z, 6.5, -1)
	for x in [-2.75, -2, 2, 2.75]:
		_on_wall_z("corbel", S, x, 1, 6.5, 1)
	for sx in [-5, 5]:
		_add("pillar", S, Vector3(sx, 5.5, 3), 0)
	for x in range(-4, 5, 2):
		_wall_x("wall", x, -5, 7.75, S)
		_wall_x("window_wide" if x == 0 else ("window_wall" if absi(x) == 2 else "wall"), x, 3, 7.75, S)
	for z in [-4, -2, 0, 2]:
		_wall_z("window_wall" if z in [-2, 2] else "wall", -5, z, 7.75, S)
		_wall_z("window_wall" if z in [-2, 2] else "wall", 5, z, 7.75, S)
	_add("floor", S, Vector3(4, 7.75, 0), 0)            # stairs 4 -> the roof deck climbing to the back
	_add("stairs", S, Vector3(4, 8.0, 0), 0)
	# --- the roof deck with battlements, the six-sided lantern room on it (door to the front), the fire bowl on top
	for x in range(-4, 5, 2):
		for z in [-4, -2, 0, 2]:
			if Vector2(x, z) != Vector2(4, 0):
				_add("floor", S, Vector3(x, 9.75, z), 0)
	_wall_z("railing", 3, 0, 10.0, S)
	_wall_x("railing", 4, 1, 10.0, S)
	for x in range(-4, 5, 2):
		_wall_x("battlement", x, 3, 10.0, S)
		_wall_x("battlement", x, -5, 10.0, S)
	for z in [-4, -2, 0, 2]:
		_wall_z("battlement", -5, z, 10.0, S)
		_wall_z("battlement", 5, z, 10.0, S)
	var hc := Vector3(0, 10.0, -2)
	for k in 6:
		_add("doorway" if k == 0 else "window_wall", S, _dir(2 * k) * _APO + hc, _rot(2 * k))
		if k not in [0, 5]:                                  # (no pillar beside the doorway)
			_add("pillar", S, _dir(2 * k + 1) * 1.95 + hc, _rot(2 * k + 1))
		_add("floor_triangle", S, _dir(2 * k) * (_APO * 2.0 / 3.0) + hc + Vector3(0, 2.0, 0), _rot(2 * k))
		_add("battlement", S, _dir(2 * k) * _APO + hc + Vector3(0, 2.25, 0), _rot(2 * k))
	_add("door", S, _dir(0) * _APO + hc, 0)
	_add("beacon_bowl", S, hc + Vector3(0, 2.25, 0), 0)
	# --- trim bands under the battlements (outside faces, not the back in the rock), corner blocks
	for z in [-4, -2, 0, 2]:
		_on_wall_x("cornice", S, -7, z, 5.2, -1)
		_on_wall_x("cornice", S, 7, z, 5.2, 1)
		_on_wall_x("cornice", S, -5, z, 9.7, -1)
		_on_wall_x("cornice", S, 5, z, 9.7, 1)
	for x in [-6, -4, 4, 6]:
		_on_wall_z("cornice", S, x, 3, 5.2, 1)
	for x in [-2, 0, 2]:
		_on_wall_z("cornice", S, x, 5, 5.2, 1)
	for x in range(-4, 5, 2):
		_on_wall_z("cornice", S, x, 3, 9.7, 1)
	for c in [Vector3(-7.17, 5.2, 3.17), Vector3(7.17, 5.2, 3.17), Vector3(-3.17, 5.2, 5.17), Vector3(3.17, 5.2, 5.17),
			Vector3(-5.17, 9.7, 3.17), Vector3(5.17, 9.7, 3.17)]:
		_add("cornice_corner", S, c, 0)
	for p in _bp.pieces:
		p.pos.x += 1.0   # cells on odd numbers, like every other blueprint (box x -11..11)
		p.pos.z -= 1.0   # (box z -9..9)


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
