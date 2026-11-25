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
	"hearthbrick_manor", "wooden_manor", "stonehold_twin_gate", "wooden_twin_gate", "stonehold_cliff_watch", "wooden_cliff_watch",
	"stonehold_prow_hall", "wooden_prow_hall", "hearthbrick_smeltery", "wooden_smeltery"]
## Known from the very start (F161): you place them and bring the materials. The rest are learned from
## Old Blueprints found in ruins (F98).
const STARTER := ["delvers_hut"]
## Learned only by rebuilding a ruin (owner, Nov 19), never from an Old Blueprint page.
## The Brewhall's two (F479): its cellar goes below the ground line, which only the ruin digs out.
## The Lantern Spire's two (F479): a landmark you rebuild where it stands. The Hearth Manor's two (F479) the same, and the Twin Gate's and Cliff Watch's (owner, Nov 22: so the dev menu has them),
## and the Prow Hall's (owner, Nov 22: its ruin teaches both), and the Smeltery's (owner, Nov 25, F845: the same).
const REBUILD_ONLY := ["wooden_watchtower", "wooden_outpost", "hearthbrick_brewhall", "wooden_brewhall", "lantern_spire", "wooden_spire",
	"hearthbrick_manor", "wooden_manor", "stonehold_twin_gate", "wooden_twin_gate", "stonehold_cliff_watch", "wooden_cliff_watch",
	"stonehold_prow_hall", "wooden_prow_hall", "hearthbrick_smeltery", "wooden_smeltery"]
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
	"stonehold_prow_hall": "Prow Hall",
	"wooden_prow_hall": "Wooden Prow Hall",
	"hearthbrick_smeltery": "Smeltery Terraces",
	"wooden_smeltery": "Wooden Smeltery Terraces",
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
		"stonehold_twin_gate": lib._twin_gate()  # (owner, Nov 21: ruin 6, the first showpiece; learned by rebuilding its ruin, F657 cave shapes Nov 22)
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
		"stonehold_round_test": lib._round_tower_test()  # (owner, Nov 22, F656: the big-ring test, not a blueprint you learn)
		"stonehold_prow_hall": lib._prow_hall()  # (owner, Nov 22: ruin 9, F656 + F657; learned by rebuilding its ruin)
		"wooden_prow_hall":  # (owner, Nov 22: "rebuild it in wood"; cornices, corbels, fire bowl and the keep's top tower stay stone)
			lib._prow_hall()
			lib._to_wood()
			lib._stairs_on_the_floor()  # (before the stone top: it matches the stone hall piece by piece)
			lib._prow_keep_top_stays_stone()
		"hearthbrick_smeltery": lib._smeltery()  # (owner, Nov 24: ruin 10, F845; learned by rebuilding its ruin)
		"wooden_smeltery":  # (its trims, brackets and roof windows are Hearthbrick only: they stay brick)
			lib._smeltery()
			lib._to_wood()
			lib._smelt_top_stays_brick()
		_: return null
	if id != "wooden_prow_hall":
		lib._stairs_on_the_floor()
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
## made the dwarf hop going down and struggle going up). `back`: climbing the other way round (toward 2k+9), for a
## mirrored building (F783: the Twin Gate's right tower).
func _ring_stairs(k: int, y: float, mat := STONE, back := false) -> void:
	_add("floor", mat, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y, 0) + _ring_off, _rot(2 * k))
	_add("stairs", mat, _dir(2 * k) * (_APO + 1.0) + Vector3(0, y + 0.25, 0) + _ring_off, _rot(2 * k + (3 if back else 9)))


## Railings round the stairs hole in square `k` on the floor above: its inner edge and the side the stairs
## start from (the far side stays open: that's where you step off).
func _ring_rails(k: int, y: float, mat := STONE, back := false) -> void:
	var n := _dir(2 * k)
	var t := _dir(2 * k + (9 if back else 3))
	_add("railing", mat, n * _APO + Vector3(0, y, 0) + _ring_off, _rot(2 * k))
	_add("railing", mat, n * (_APO + 1.0) - t + Vector3(0, y, 0) + _ring_off, _rot(2 * k + 3))


## 6-sided turrets (owner, Nov 25, F845: the smallest round shape real pieces make, 3.5 m across): the 12-sided
## ring's middle hexagon on its own, centred at `c` (its y = the height). `flat` 0: flat sides face sides 0, 2 .. 10
## (front and back flat); 1: sides 1, 3 .. 11 (left and right flat). Side j faces _dir(j).
func _hex_layer(tri_id: String, c: Vector3, flat: int, skip := -1, mat := STONE) -> void:
	for j in range(flat, 12, 2):
		if j != skip:
			_add(tri_id, mat, c + _dir(j) * (_APO * 2.0 / 3.0), _rot(j))


func _hex_edges(c: Vector3, flat: int, pick: Callable, mat := STONE) -> void:
	for j in range(flat, 12, 2):
		var id: String = pick.call(j)
		if id != "":
			_add(id, mat, c + _dir(j) * _APO, _rot(j))


## Pillars on its 6 corners (corner j + 1 sits between sides j and j + 2, 2 m from the middle).
func _hex_pillars(c: Vector3, flat: int, mat := STONE) -> void:
	for j in range(flat, 12, 2):
		_add("pillar", mat, c + _dir(j + 1) * 1.95, _rot(j + 1))


## A ladder up the inside of side j (leave triangle j open in the floor above: the hole you climb through).
func _hex_ladder(c: Vector3, j: int, mat := STONE) -> void:
	_add("ladder", mat, c + _dir(j) * (_APO - 0.27), _rot(j))


## A trim band round its outside at height c.y.
func _hex_bands(c: Vector3, flat: int, mat := STONE) -> void:
	for j in range(flat, 12, 2):
		_add("cornice", mat, c + _dir(j) * (_APO + 0.15 + Pieces.LIST["cornice"].size.z * 0.5), _rot(j))


## BIG rings (owner, Nov 22, F656): the 12-sided ring `r` times wider. The same plan scaled up: each big triangle
## is r*r small 2 m triangles, each big square r*r small squares; 12 flat sides of r walls each, every side
## r * 3.73 m from the middle (r = 1 is the watchtower's ring, r = 2 is 7.46 m, r = 3 is 11.2 m).
## Squares: 6 r^2, triangles: 12 r^2. `skip` = small squares left open, as [k, a, b]: big square k, row a outward,
## column b along it (stairs holes).
func _big_ring_layer(r: int, square_id: String, tri_id: String, y: float, skip: Array = [], mat := STONE) -> void:
	var up := Vector3(0, y, 0) + _ring_off
	for k in 6:
		var n := _dir(2 * k)
		var t := _dir(2 * k + 3)
		# the middle hexagon's big triangle k: apex in the middle, flat side facing n
		_tri_fan(r, Vector3.ZERO, _dir(2 * k - 1) * 2.0, _dir(2 * k + 1) * 2.0, 2 * k, tri_id, mat, up)
		# the big square on that side
		for a in r:
			for b in r:
				if [k, a, b] in skip:
					continue
				var c := n * (r * _APO + 1.0 + 2.0 * a) + t * (1.0 - r + 2.0 * b)
				_add(square_id, mat, c + up, _rot(2 * k))
		# the big triangle in the gap between two big squares: apex inward, flat side facing u
		var u := _dir(2 * k + 1)
		var tu := _dir(2 * k + 4)
		_tri_fan(r, u * 2.0, u * _APO + tu, u * _APO - tu, 2 * k + 1, tri_id, mat, up)


## Fills a big triangle (corners o, o + r*a, o + r*b, its far side facing yaw step `face`) with r*r small triangles.
func _tri_fan(r: int, o: Vector3, a: Vector3, b: Vector3, face: int, tri_id: String, mat: String, up: Vector3) -> void:
	o *= r
	for i in r:
		for j in r - i:
			_add(tri_id, mat, o + a * (i + 1.0 / 3.0) + b * (j + 1.0 / 3.0) + up, _rot(face))            # points inward
			if i + j <= r - 2:
				_add(tri_id, mat, o + a * (i + 2.0 / 3.0) + b * (j + 2.0 / 3.0) + up, _rot(face + 6))  # points outward


## The 12 sides of a big ring at height y: `pick(j, m)` says which piece goes on side j, slot m (0..r-1).
func _big_ring_edges(r: int, y: float, pick: Callable, mat := STONE, out := 0.0) -> void:
	for j in 12:
		for m in r:
			var id: String = pick.call(j, m)
			if id != "":
				var p := _dir(j) * (r * _EDGE + out) + _dir(j + 3) * (1.0 - r + 2.0 * m)
				_add(id, mat, p + Vector3(0, y, 0) + _ring_off, _rot(j))


## Something on each of a big ring's 12 corners (pillars, battlement corners), not the ones in `skip`.
func _big_ring_corners(r: int, y: float, id: String, skip: Array = [], mat := STONE) -> void:
	for j in 12:
		if j not in skip:
			var a := (j + 0.5) * PI / 6.0
			_add(id, mat, Vector3(sin(a), 0, cos(a)) * (r * _CORNER - 0.05) + Vector3(0, y, 0) + _ring_off, _rot(j))


## Stairs in the outer row of big square k, small square b, climbing along the ring (toward yaw step 2k+3),
## lifted on a floor slab like _ring_stairs. Leave [k, r-1, b] open on the floor above.
func _big_ring_stairs(r: int, k: int, b: int, y: float, mat := STONE) -> void:
	var c := _dir(2 * k) * (r * _APO + 2.0 * r - 1.0) + _dir(2 * k + 3) * (1.0 - r + 2.0 * b) + _ring_off
	_add("floor", mat, c + Vector3(0, y, 0), _rot(2 * k))
	_add("stairs", mat, c + Vector3(0, y + 0.25, 0), _rot(2 * k + 9))


## Railings round that stairs hole: its inner side and the side the stairs start from.
func _big_ring_rails(r: int, k: int, b: int, y: float, mat := STONE) -> void:
	var n := _dir(2 * k)
	var t := _dir(2 * k + 3)
	var c := n * (r * _APO + 2.0 * r - 1.0) + t * (1.0 - r + 2.0 * b) + _ring_off + Vector3(0, y, 0)
	_add("railing", mat, c - n, _rot(2 * k))
	_add("railing", mat, c - t, _rot(2 * k + 3))


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
	# stairs up: left wall (to the front-left tower) and back wall (to the back-right tower). F838 (owner, Nov 24): two
	# flights straight on, no landing; the curtain wall closes their outer side, walls close the courtyard side.
	_stacked_stairs(Vector3(-13, 0.0, 5), 2, STONE, [-1])   # climbs toward the front (+z)
	_stacked_stairs(Vector3(7, 0.0, -13), 3, STONE, [1])    # climbs toward the right (+x)
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
## Its trims (_twin_trims: brackets under the jutting floors, trim bands at the floor lines, buttresses, the little
## corner turrets) are the same as tools/ruins/make_twin_gate_ruin.py adds to the ruin. No furniture: you furnish it.
const _TWIN_L := -11.0
const _TWIN_R := 11.0
var _tw_c := 0.0   # the tower being built: its middle (x) and which way its gate side faces (+1: +x)
var _tw_m := 1


func _twin_gate() -> void:
	_start(Vector3(40, 17, 36))
	_twin_tower(_TWIN_L, 1)
	_twin_ring_stage(_TWIN_L, 3, 3, 5, true)
	_twin_tower(_TWIN_R, -1)
	_twin_ring_stage(_TWIN_R, 9, 3, 1, false, true)
	_twin_gatehouse()
	_twin_yard()
	_twin_barracks()
	_twin_trims()
	for p in _bp.pieces:
		p.pos.z += 8.0   # centred in its box (z -15..15)
	# F657 (owner, Nov 22: "yes, add cave shapes"): it digs only round itself; the rock wall behind the barracks and
	# the two lumps the ruin grows (RuinTwinGate) stay rock.
	_air_only_round_pieces(func(lx: float, y: float, lz: float) -> bool: return y < RuinTwinGate.rock_at(lx, lz))


const _OUT_ROT := {Vector2i(0, 1): 0, Vector2i(1, 0): 1, Vector2i(0, -1): 2, Vector2i(-1, 0): 3}  # +z of the piece faces this way
const _TURRET_SH := 0.32   # a corner turret's middle sits this far in from the tower corner (both ways)


## The Twin Gate's Stonehold trims (the same as tools/ruins/make_twin_gate_ruin.py extras()): trim bands at the floor
## lines with corner blocks, buttresses, brackets under the jutting floors, a walk-in turret on 6 tower corners (each
## takes the place of the two deck battlements beside its corner), short battlements closing the wings' roof ends.
## They stay stone in the wooden version (no wooden trims).
func _twin_trims() -> void:
	var S := STONE
	var band := func(along_x: bool, line: float, sd: int, cells: Array, y: float) -> void:
		for c in cells:
			if along_x:
				_add("cornice", S, Vector3(c, y, line + sd * 0.245), _OUT_ROT[Vector2i(0, sd)])
			else:
				_add("cornice", S, Vector3(line + sd * 0.245, y, c), _OUT_ROT[Vector2i(sd, 0)])
	var corner := func(x: float, z: float, sx: int, sz: int, y: float) -> void:
		_add("cornice_corner", S, Vector3(x + sx * 0.17, y, z + sz * 0.17), 0)
	var gaps: Array[Vector3] = []
	for cx in [_TWIN_L, _TWIN_R]:
		var o: int = 1 if cx > 0 else -1
		var xs := [cx - 4, cx - 2, cx, cx + 2, cx + 4]
		for y in [2.95, 5.2]:
			band.call(true, 5.0, 1, xs, y)
			band.call(true, -5.0, -1, xs.filter(func(x): return not (y < 3 and absf(absf(x) - 13) < 0.1)), y)  # (the yard wall)
			band.call(false, cx + 5 * o, o, [-4, -2, 0, 2, 4], y)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					corner.call(cx + 5 * sx, 5 * sz, sx, sz, y)
		for j in [-3, -1, 1, 3]:
			_add("buttress", S, Vector3(cx + j, 0, 5.626), 0)
			_add("buttress", S, Vector3(cx + 5.626 * o, 0, j), _OUT_ROT[Vector2i(o, 0)])
		for j in [-3, 3]:
			_add("buttress", S, Vector3(cx + j, 0, -5.626), 2)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				if sx == -o and sz == 1:
					continue                                  # (the gate room's roof juts past this corner: no room)
				var x: float = cx + 5 * sx
				var z: float = 5.0 * sz
				var rot: int = {Vector2i(1, 1): 0, Vector2i(1, -1): 1, Vector2i(-1, -1): 2, Vector2i(-1, 1): 3}[Vector2i(sx, sz)]
				_add("bartizan", S, Vector3(x - sx * _TURRET_SH, 6.0, z - sz * _TURRET_SH), rot)
				gaps.append(Vector3(x - sx, 7.75, z))
				gaps.append(Vector3(x, 7.75, z - sz))
	for sx in [-1, 1]:   # the gate room's jutting floor (z 3 -> 4): brackets under it on the guard rooms' fronts
		for a in [2.5, 3.5, 4.5, 5.5]:
			_add("corbel", S, Vector3(sx * a, 4.25, 3.57), 0)
	for sx in [-1, 1]:   # the barracks wings' jutting upper floor
		for i in 8:
			var a := 5.5 + i
			if absf(a - 10) >= 1.0:                           # (never in front of the wing's door)
				_add("corbel", S, Vector3(sx * a, 2.0, -14.43), 0)
	for y in [2.95, 5.2]:
		band.call(true, -15.0, 1, [-2, 0, 2], y)
		if y > 3:
			band.call(true, -14.0, 1, [-12, -10, -8, -6, 6, 8, 10, 12], y)
		band.call(false, -13.0, -1, [-22, -20, -18, -16], y)
		corner.call(-13, -23, -1, -1, y)
	band.call(true, -23.0, -1, range(-12, 17, 2), 2.95)
	band.call(true, -23.0, -1, range(-12, 13, 2), 5.2)
	band.call(false, 13.0, 1, [-22, -20, -18, -16], 5.2)
	corner.call(13, -23, 1, -1, 5.2)
	band.call(true, -17.0, 1, [14, 16], 2.95)                 # the kitchen
	band.call(false, 17.0, 1, [-22, -20, -18], 2.95)
	corner.call(17, -23, 1, -1, 2.95)
	corner.call(17, -17, 1, 1, 2.95)
	for x in [-11, -7, -3, 3, 7, 11, 15]:
		_add("buttress", S, Vector3(x, 0, -23.626), 2)
	for sx in [-1, 1]:   # a 1 m battlement on both ends of the strip the wings' roofs jut out
		for ex in [5, 13]:
			_add("battlement_narrow", S, Vector3(sx * ex, 5.5, -14.5), 1)
	_bp.pieces.assign(_bp.pieces.filter(func(p): return not (p.id == "battlement" and gaps.any(func(g: Vector3) -> bool:
		return absf(p.pos.x - g.x) < 0.15 and absf(p.pos.z - g.z) < 0.15 and absf(p.pos.y - g.y) < 0.05))))


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
	# side climbing to the front; 3 -> the deck straight stairs in the middle (F626: they were spiral stairs you
	# couldn't climb).
	# Each foot on open floor, each starting where the last ends.
	# F783 (owner, Nov 23: "the doors opening towards the towers are blocked by railings"): the deck flight used to
	# climb to the back, so its hole lay right behind the stage's door and a railing stood 0.7 m inside it. It now
	# climbed toward the gate side, out at that door. F811 (Nov 23): now it climbs to the back from the stage's middle
	# (see i == 2 below), so both its ends have a whole free 2 m block.
	var flights := [[Vector2(0, 2), 1.0, 0, "stairs"], [Vector2(-2, 0), 3.25, 2, "stairs_corner"],
		[Vector2(0, 2), 5.5, 0, "stairs"]]
	for f in flights:
		var c: Vector2 = f[0]
		_add("floor", S, _tp(c.x, f[1], c.y), 0)                        # (a slab lifts each top step to the floor)
		_add(f[3], S, _tp(c.x, f[1] + 0.25, c.y), f[2])
	_add("railing_stairs", S, _tp(1, 1.25, 2), 1)                       # (climbs with the steps toward -z)
	_add("sloped_wall_down", S, _tp(-1, 1.0, 2), 1)                     # (full at the stairs' foot, under the floor above)
	var floors := [3.0, 5.25, 7.5]
	for i in 3:
		var hole: Vector2 = flights[i][0]
		var foot := 1 if flights[i][2] == 0 else -1                     # (which way the stairs' foot faces)
		var holes := [hole]
		if flights[i][3] == "stairs_corner":
			holes.append(hole + Vector2(0, 2 * foot))                   # (its tall steps start at the edge: head room)
		for u in cells:
			for v in cells:
				if not Vector2(u, v) in holes:
					_add("floor", S, _tp(u, floors[i], v), 0)
		var ry: float = floors[i] + 0.25
		if i == 2:
			# F811 (owner, Nov 23: "don't make half-railing models, rebuild the spot"): the deck flight stands in the
			# round stage's middle and climbs toward -v, so its top lands in the stage's middle with a whole free
			# 2 m block (the door to the gate roof on its right, the stage stairs' foot ahead-left), and its foot has
			# the free cell at the back wall. Railings on both long sides and the foot's end. (Before: it climbed
			# toward the door, which left only 0.7 m between its top and the door, F783.)
			_add("railing", S, _tp(hole.x - 1, ry, hole.y), 1)
			_add("railing", S, _tp(hole.x + 1, ry, hole.y), 1)
			_add("railing", S, _tp(hole.x, ry, hole.y + 1), 0)
			continue
		# round the hole: both sides and the foot's end (not over the stair railing, never across its way out).
		# F783 (owner, Nov 23: "the spiral staircase is blocked"): corner stairs come out SIDEWAYS (in at their front,
		# out at their left side), so the side they come out of gets no railing. The piece turns the same way in both
		# towers but the right tower is mirrored, so that side is +u in the left tower and -u in the right one.
		for h: Vector2 in holes:
			var corner_out: bool = flights[i][3] == "stairs_corner" and h == hole
			if not (corner_out and _tw_m == -1):
				_add("railing", S, _tp(h.x - 1, ry, h.y), 1)
			if i >= 1 and not (corner_out and _tw_m == 1):
				_add("railing", S, _tp(h.x + 1, ry, h.y), 1)
		_add("railing", S, _tp(hole.x, ry, holes[-1].y + foot), 0)
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
## `back`: the first stairs climb the other way round. F783 round 3 (robot walk, Nov 23): the right tower is the
## left one mirrored, but its first stairs weren't, so their foot was on the far side, behind a 0.7 m gap between the
## deck stairs' railings and the steps (too narrow for the dwarf). Now both feet are beside the deck stairs' top.
func _twin_ring_stage(cx: float, door_j: int, k1: int, k2: int, lantern: bool, back := false) -> void:
	_ring_off = Vector3(cx, 0, 0)
	var y := 7.75
	_ring_edges(y, func(j): return "doorway" if j == door_j else ("window_wall" if j in [0, 6, (door_j + 6) % 12] else "wall"))
	_add("door", STONE, _dir(door_j) * _EDGE + Vector3(0, y, 0) + _ring_off, _rot(door_j))
	_ring_pillars(y, [posmod(door_j - 1, 12), door_j])
	_ring_stairs(k1, y, STONE, back)
	_ring_layer("floor", "floor_triangle", 9.75, k1)
	_ring_rails(k1, 10.0, STONE, back)
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
	# --- the tower (cells x 8..14, z -6..0): 4 by 4, three
	# storeys, then a lookout room on its roof with a gallery of whole floors round it
	var tx := [8, 10, 12, 14]
	var tz := [-6, -4, -2, 0]
	for x in tx:
		for z in tz:
			_add("foundation", B, Vector3(x, 0, z), 0)
	var lv := [g, u, 5.5]          # its three storeys' walls
	var fys := [3.0, 5.25, 7.5]    # the floors above them
	# Straight stairs (F626, 2nd time: the spiral stairs couldn't be climbed): each starts on open floor and comes out
	# onto open floor. Up from the ground along the right wall toward the back, from the first floor along the left
	# wall toward the front, from the second along the right wall toward the front (out onto the gallery by the
	# lookout's door). [cell, turn (0: climbs toward -z, 2: toward +z)]
	var flights := [[Vector2(14, -2), 0], [Vector2(8, -4), 2], [Vector2(14, -2), 2]]
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
		_add("stairs", B, Vector3(c.x, y + 0.25, c.y), flights[i][1])
		for x in tx:
			for z in tz:
				if x != int(c.x) or z != int(c.y):
					_add("floor", B, Vector3(x, fys[i], z), 0)
		# railings round the hole above: across its foot end, and its inner side (not where a wall or room stands)
		var up: int = flights[i][1]
		_wall_x("railing", c.x, c.y + (1 if up == 0 else -1), fys[i] + 0.25, B)
		var inner := c.x + (1 if c.x < 11 else -1)
		if i < 2:
			_wall_z("railing", inner, c.y, fys[i] + 0.25, B)
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
	# its flat roof deck with railings round it (F626, 2nd time: the owner chose this over the odd pyramid roof)
	var py := ry + 2.0
	for x in [10, 12]:
		for z in [-4, -2]:
			_add("floor", B, Vector3(x, py, z), 0)
		_wall_x("railing", x, -5, py + 0.25, B)
		_wall_x("railing", x, -1, py + 0.25, B)
	for z in [-4, -2]:
		_wall_z("railing", 9, z, py + 0.25, B)
		_wall_z("railing", 13, z, py + 0.25, B)
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


## Owner, Nov 22 (F656): a test of the BIG ring, not a blueprint you learn. A wide 2-ring round base (24 squares +
## 48 triangles a layer, 15 m across, two floors) and the small watchtower ring standing on its roof (two more floors):
## a round tower that steps in as it rises. Heights like the watchtower: foundations 0-1, walls from 1 and 3.25,
## the base's roof at 5.25 (battlements from 5.5); the top tower's walls from 5.5 and 7.75, its roof at 9.75.
func _round_tower_test() -> void:
	_start(Vector3(18, 12, 18))
	var R := 2
	var trim := 0.15 + Pieces.LIST["cornice"].size.z * 0.5
	_big_ring_layer(R, "foundation", "foundation_triangle", 0.0)
	_add("foundation_steps", STONE, _dir(0) * (R * _EDGE + 1.0), 0)
	var g := 1.0
	# the front side: narrow wall, round doorway in the middle, narrow wall (a 2-ring side is 4 m: two 2 m slots)
	_big_ring_edges(R, g, func(j, _m): return "" if j == 0 else ("window_wall" if j in [3, 9] else "wall"))
	var front := _dir(0) * (R * _EDGE)
	for sx in [-1.5, 1.5]:
		_add("wall_narrow", STONE, front + Vector3(sx, g, 0), 0)
	_add("doorway", STONE, front + Vector3(0, g, 0), 0)
	_add("door", STONE, front + Vector3(0, g, 0), 0)
	_big_ring_corners(R, g, "pillar")
	_big_ring_stairs(R, 2, 0, g)
	var f2 := 3.0
	_big_ring_layer(R, "floor", "floor_triangle", f2, [[2, R - 1, 0]])
	_big_ring_rails(R, 2, 0, f2 + 0.25)
	_big_ring_edges(R, f2 - 0.05, func(_j, _m): return "cornice", STONE, trim)
	var w2 := f2 + 0.25
	_big_ring_edges(R, w2, func(j, _m): return "window_wall" if j % 3 == 0 else "wall")
	_big_ring_corners(R, w2, "pillar")
	_big_ring_stairs(R, 5, 1, w2)
	var roof := w2 + 2.0
	_big_ring_layer(R, "floor", "floor_triangle", roof, [[5, R - 1, 1]])
	_big_ring_rails(R, 5, 1, roof + 0.25)
	_big_ring_edges(R, roof - 0.05, func(_j, _m): return "cornice", STONE, trim)
	_big_ring_edges(R, roof + 0.25, func(_j, _m): return "battlement")
	_big_ring_corners(R, roof + 0.25, "battlement_corner")
	# the top tower: the small ring, standing on the base's roof
	var t1 := roof + 0.25
	_ring_edges(t1, func(j): return "doorway" if j == 0 else ("window_wall" if j in [4, 8] else "wall"))
	_add("door", STONE, _dir(0) * _EDGE + Vector3(0, t1, 0), 0)
	_ring_pillars(t1, [11, 0])
	_ring_stairs(2, t1)
	var f4 := t1 + 2.0
	_ring_layer("floor", "floor_triangle", f4, 2)
	_ring_rails(2, f4 + 0.25)
	_big_ring_edges(1, f4 - 0.05, func(_j, _m): return "cornice", STONE, trim)
	var t2 := f4 + 0.25
	_ring_edges(t2, func(j): return "window_wall" if j % 2 == 1 else "wall")
	_ring_pillars(t2)
	_ring_stairs(4, t2)
	var top := t2 + 2.0
	_ring_layer("floor", "floor_triangle", top, 4)
	_ring_rails(4, top + 0.25)
	_big_ring_edges(1, top - 0.05, func(_j, _m): return "cornice", STONE, trim)
	_ring_edges(top + 0.25, func(_j): return "battlement")
	_big_ring_corners(1, top + 0.25, "battlement_corner")


## Owner, Nov 22 (ruin 9, F656 + F657): the Prow Hall, Stonehold, set INTO the cave. Plan B of the castle plans page
## (tools/ruins/castle_plans_page.html). Laid out round the hall's middle, then moved by PROW_SHIFT so the box is centred.
##   - The great hall: 20 x 12 m (x -10..10, z -6..6), two storeys (walls 1 and 3.25), a roof walk at 5.25 with
##     battlements. Trim bands at the floor line and under the battlements.
##   - Four small round towers, each meeting the hall on ONE flat side: the side wall's end slot IS the tower's doorway
##     side (BLUEPRINT-RECIPE: a ring meets the 2 m grid flush on one side only). Doorways from the hall on both storeys
##     and out onto the roof walk. Front pair 4 storeys (roof 9.75), back pair 5 storeys (roof 12).
##   - The prow: an 8 m wide room on the front ending in a point of triangles (a ship's bow), 3 storeys (roof 7.5),
##     open to the hall below, a door out onto the roof walk at the top. Its two side doors are the main doors, wide
##     steps up to each.
##   - The keep: a BIG ring (R = 2, 15 m) behind the hall; its front side is the middle of the hall's back wall. Four
##     storeys (roof 9.75), the small ring standing on its roof (two storeys, roof 14.25), and on top a crown of six
##     balconies jutting 2 m out on brackets: the tallest part. Its back half sits in the cave wall (F657 idea 1).
##   - The bridge: 10 m long, 9.75 m up, from the back-left tower out to a lone tower (F657 idea 2: the ruin digs a
##     dip under the bridge). The lone tower stands on the cave floor, five storeys up to the bridge (owner, Nov 23,
##     F657: no grown rock lump under it any more). The blueprint keeps the cave wall behind the keep as rock (not
##     "air"), so the Builder's Chest never carves it away.
##   - Heights all differ (F710): hall roof walk 10, front towers and lone tower 12.25, prow and back towers 14.5,
##     keep 10 + its small tower 16.75 + crown.
##   - Every stair's foot is on open floor and its top lands on floor; railings round every stairs hole.
const PROW_SHIFT := Vector3(8, 0, 2)
const PROW_LONE := Vector3(-20.856, 0.0, -11.732)   # the lone tower's middle (it stands on the cave floor)
const PROW_KEEP := Vector3(8, 0, -11.464)            # the keep's middle: the cave wall wraps round its back half
## F710 (owner, Nov 22): the hall's and the prow's storeys are twice a tower storey (2 x 2.25 m), so every doorway
## from the hall still opens onto a tower's or the keep's floor. Each one: a wall, a stone beam band, a wall.
const PROW_STOREY := 4.5


## F710: stairs up one tall storey of the Prow Hall. `c` = the cell before the first flight (its floor at c.y),
## `rot` 3 climbs toward +x, 1 toward -x; the upper flight ends in the hole in the floor above the third cell.
## F838 (owner, Nov 24, from their own rebuild): two flights straight on, the second starting exactly where the first
## ends, no landing or pillars between. Under them only walls: a sloped wall each side of the lower flight, a wall
## with a sloped wall on it each side of the upper one. A slab lifts both, so the upper one ends 25 cm under the
## floor above (the lip, F803), like every tower flight.
func _prow_tall_stairs(c: Vector3, rot: int) -> void:
	_stacked_stairs(c + Vector3(2 if rot == 3 else -2, 0, 0), rot, STONE)


## F838: two straight flights one after the other (the second starts where the first ends, same way), with a slab under
## both cells and closed sides. `c` = the lower flight's cell, its slab at c.y (the flights' feet at c.y + 0.25).
## `sides`: which sides get the walls (the stairs' own -x / +x); leave out a side that already stands against a
## wall (a curtain wall closes it).
func _stacked_stairs(c: Vector3, rot: int, mat: String, sides := [-1, 1]) -> void:
	var b := Basis(Vector3.UP, Pieces.yaw_of(rot))
	var ahead: Vector3 = (b * Vector3(0, 0, -2)).round()
	var side: Vector3 = (b * Vector3(1, 0, 0)).round()
	var y := c.y + 0.25
	for i in 2:
		var cell: Vector3 = c + ahead * i
		_add("floor", mat, cell, 0)
		_add("stairs", mat, cell + Vector3(0, 0.25 + 2.0 * i, 0), rot)
		for sx in sides:
			var e: Vector3 = cell + side * sx
			if i == 1:
				_add("wall", mat, Vector3(e.x, y, e.z), (rot + 1) % 4)
			_add("sloped_wall", mat, Vector3(e.x, y + 2.0 * i, e.z), (rot + 1) % 4)   # (high end toward the climb)


## How high the Prow Hall's own rock reaches at (x, z) in its box (0 = the cave floor): the cave wall behind the keep.
static func prow_rock_top(x: float, z: float) -> float:
	if z < PROW_KEEP.z and x > -6.0 and Vector2(x - PROW_KEEP.x, z - PROW_KEEP.z).length() > 8.6:
		return 99.0
	return 0.0


func _prow_hall() -> void:
	_start(Vector3(52, 20, 40))
	var S := STONE
	var H := sqrt(3.0)
	var trim := 0.15 + Pieces.LIST["cornice"].size.z * 0.5
	# --- the great hall (cells x -9..9, z -5..5): foundations, the upper floor (5.25), the roof walk (9.75)
	for x in range(-9, 10, 2):
		for z in range(-5, 6, 2):
			_add("foundation", S, Vector3(x, 0, z), 0)
			if Vector2(x, z) != Vector2(-3, -3):
				_add("floor", S, Vector3(x, PROW_STOREY + 0.75, z), 0)
			if Vector2(x, z) != Vector2(3, 3):
				_add("floor", S, Vector3(x, 2.0 * PROW_STOREY + 0.75, z), 0)
	_prow_tall_stairs(Vector3(-7, 1.0, -3), 3)          # storey 1 -> 2: toward +x along the back row
	_prow_tall_stairs(Vector3(7, 1.0 + PROW_STOREY, 3), 1)   # storey 2 -> the roof walk: toward -x along the front row
	for e in [[-3, -3, 1.0 + PROW_STOREY, -1], [3, 3, 1.0 + 2.0 * PROW_STOREY, 1]]:   # railings round both holes
		_wall_x("railing", e[0], e[1] - 1, e[2], S)
		_wall_x("railing", e[0], e[1] + 1, e[2], S)
		_wall_z("railing", e[0] + e[3], e[1], e[2], S)
	for s in 2:                                           # each storey: a wall, a stone beam band, a wall
		var y := 1.0 + PROW_STOREY * s
		var up := s == 1
		for hi in [false, true]:
			var wy: float = y + (2.25 if hi else 0.0)
			for x in [-9, -7, -5, 5, 7, 9]:                # front (the prow takes the middle)
				_wall_x("window_wall" if absi(x) == 7 and not hi else "wall", x, 6, wy, S)
			for x in [-9, -7, -5, -3, 3, 5, 7, 9]:         # back (the keep takes the middle)
				_wall_x("window_wall" if up and not hi and absi(x) in [5, 9] else "wall", x, -6, wy, S)
			for z in [-3, -1, 1, 3]:                       # sides (the towers take both ends); high windows let light in
				for sx in [-10, 10]:
					var id := "wall"
					if not hi:
						id = "window_wide" if up and z in [-1, 1] else ("window_wall" if not up and absi(z) == 3 else "wall")
					elif z in [-1, 1]:
						id = "window_wall"
					_wall_z(id, sx, z, wy, S)
		for x in [-9, -7, -5, 5, 7, 9]:
			_wall_x("beam", x, 6, y + 2.0, S)
		for x in [-9, -7, -5, -3, 3, 5, 7, 9]:
			_wall_x("beam", x, -6, y + 2.0, S)
		for z in [-3, -1, 1, 3]:
			_wall_z("beam", -10, z, y + 2.0, S)
			_wall_z("beam", 10, z, y + 2.0, S)
	var roof := 1.0 + 2.0 * PROW_STOREY
	for x in [-9, -7, -5, 5, 7, 9]:
		_wall_x("battlement", x, 6, roof, S)
	for x in [-9, -7, -5, -3, 3, 5, 7, 9]:
		_wall_x("battlement", x, -6, roof, S)
	for z in [-3, -1, 1, 3]:
		_wall_z("battlement", -10, z, roof, S)
		_wall_z("battlement", 10, z, roof, S)
	for band in [PROW_STOREY + 0.7, 2.0 * PROW_STOREY + 0.7]:   # trim bands on the hall's outside faces (the floor lines)
		for x in [-9, -7, -5, 5, 7, 9]:
			_on_wall_z("cornice", S, x, 6, band, 1)
		for x in [-9, -7, -5, -3, 3, 5, 7, 9]:
			_on_wall_z("cornice", S, x, -6, band, -1)
		for z in [-3, -1, 1, 3]:
			_on_wall_x("cornice", S, -10, z, band, -1)
			_on_wall_x("cornice", S, 10, z, band, 1)
	# --- the four corner towers: each one's doorway side is the hall's side-wall end slot (z = +-5)
	var left := [[9], [7, 11, 0], [9], [6, 0], [9]]
	var right := [[3], [5, 1, 0], [3], [6, 0], [3]]
	# (F710: their storeys stay 2.25 m; the hall's floors meet every other one, so doors on storeys 1, 3 and 5)
	_prow_tower(Vector3(-10.0 - _EDGE, 0, 5), 0.0, [4, 0, 5, 2, 0], {0: [3], 2: [3], 4: [3]}, left, trim)
	_prow_tower(Vector3(10.0 + _EDGE, 0, 5), 0.0, [1, 3, 0, 4, 2], {0: [9], 2: [9], 4: [9]}, right, trim)
	var bl := Vector3(-10.0 - _EDGE, 0, -5)
	_prow_tower(bl, 0.0, [4, 0, 5, 2, 0, 5], {0: [3], 2: [3], 4: [3, 8]}, left, trim)
	_prow_tower(Vector3(10.0 + _EDGE, 0, -5), 0.0, [1, 3, 0, 4, 2, 0], {0: [9], 2: [9], 4: [9]}, right, trim)
	# --- the bridge: from the back-left tower's side 8, 9.75 m up, 10 m out to the lone tower
	var d := _dir(8)
	var b0 := bl + d * _EDGE
	for i in 5:
		var c := b0 + d * (1.0 + 2.0 * i)
		_add("floor", S, c + Vector3(0, 9.75, 0), _rot(8))
		for sd in [-1, 1]:
			_add("railing", S, c + _dir(11) * sd + Vector3(0, 10.0, 0), _rot(11))
	var lone := b0 + d * (10.0 + _EDGE)
	var cdepth: float = 0.15 + Pieces.LIST["corbel"].size.z * 0.5
	for sd in [-0.65, 0.65]:                              # brackets under both ends of the bridge
		_add("corbel", S, bl + d * (_EDGE + cdepth) + _dir(11) * sd + Vector3(0, 8.75, 0), _rot(8))
		_add("corbel", S, lone - d * (_EDGE + cdepth) + _dir(11) * sd + Vector3(0, 8.75, 0), _rot(2))
	# the lone tower: the back-left tower's plan turned half round (its door out to the bridge on side 2, 10 m up),
	# on the cave floor (F657, owner Nov 23: no rock lump grown under it); its ground door faces away from the hall
	var lt := _prow_tower(lone, 0.0, [1, 3, 2, 5, 3], {0: [9], 4: [2]}, [[8, 11], [6, 10]], trim)
	_add("beacon_bowl", S, lone + Vector3(0, lt, 0), 0)
	# --- the prow: cells x -3..3, z 7..9, then a point of triangles (4 rows, z 10 .. 10 + 4 * sqrt 3)
	var tris := []                                        # [centre, rot]: up-pointing ones point to the front
	for row in 4:
		var half := 4 - row
		for i in half:
			var a := -half + 2 * i
			tris.append([Vector3(a + 1, 0, 10 + row * H + H / 3.0), _rot(6)])
			if i < half - 1:
				tris.append([Vector3(a + 2, 0, 10 + (row + 1) * H - H / 3.0), _rot(0)])
	var ps := PROW_STOREY
	for lay in [["foundation", "foundation_triangle", 0.0], ["floor", "floor_triangle", ps + 0.75], ["floor", "floor_triangle", 2.0 * ps + 0.75], ["floor", "floor_triangle", 3.0 * ps + 0.75]]:
		for x in [-3, -1, 1, 3]:
			for z in [7, 9]:
				if not (lay[2] > 14.0 and Vector2(x, z) == Vector2(1, 7)):
					_add(lay[0], S, Vector3(x, lay[2], z), 0)
		for t in tris:
			_add(lay[1], S, t[0] + Vector3(0, lay[2], 0), t[1])
	var slant := []                                       # the point's 8 wall slots: [centre, rot, outward]
	for i in 4:
		var off := Vector3(0.5 * (2 * i + 1), 0, 10 + H * 0.5 * (2 * i + 1))
		slant.append([Vector3(4 - off.x, 0, off.z), _rot(2), _dir(2)])
		slant.append([Vector3(off.x - 4, 0, off.z), _rot(10), _dir(10)])
	for s in 3:                                           # 4.5 m storeys like the hall's: wall, beam band, wall
		var y := 1.0 + ps * s
		for hi in [false, true]:
			var wy: float = y + (2.25 if hi else 0.0)
			for sx in [-4, 4]:
				for z in [7, 9]:
					var id := "wall"
					if not hi:
						id = "doorway" if s == 0 and z == 9 else ("window_wall" if s > 0 and z == 9 else "wall")
					_wall_z(id, sx, z, wy, S)
				_add("pillar", S, Vector3(sx * 0.9875, wy, 10), 0)   # where the side turns into the point
			for i in 8:
				var w: Array = slant[i]
				var win := false
				if not hi:
					win = (i / 2) == 1 if s == 0 else ((i / 2) % 2 == 0 if s == 1 else (i / 2) in [1, 2])
				else:
					win = s > 0 and (i / 2) in [0, 3]
				_add("window_wall" if win else "wall", S, w[0] + Vector3(0, wy, 0), w[1])
			_add("pillar", S, Vector3(0, wy, 10 + 4 * H - 0.18), 0)   # the very point
		for sx in [-4, 4]:
			for z in [7, 9]:
				_wall_z("beam", sx, z, y + 2.0, S)
		for w in slant:
			_add("beam", S, w[0] + Vector3(0, y + 2.0, 0), w[1])
	for sx in [-4, 4]:                                    # the main doors, wide steps up to each
		_add("door", S, Vector3(sx, 1.0, 9), 1)
		for z in [7, 9]:
			_add("foundation_steps", S, Vector3(sx * 1.25, 0, z), 1 if sx > 0 else 3)
	var y3 := 1.0 + 2.0 * ps                              # storey 3's back: a door out onto the hall's roof walk
	for e in [["wall", -3.0], ["wall_narrow", -1.5], ["doorway", 0.0], ["wall_narrow", 1.5], ["wall", 3.0]]:
		_wall_x(e[0], e[1], 6, y3, S)
		_wall_x("beam" if e[0] != "wall_narrow" else "beam_half", e[1], 6, y3 + 2.0, S)
		_wall_x("wall" if e[0] != "wall_narrow" else "wall_narrow", e[1], 6, y3 + 2.25, S)
	_add("door", S, Vector3(0, y3, 6), 0)
	# up to the prow's roof: a flight toward -x, a landing on pillars, a flight back toward +x (never a spiral)
	_add("floor", S, Vector3(1, y3, 9), 0)
	_add("stairs", S, Vector3(1, y3 + 0.25, 9), 1)
	for c in [Vector2(-1, 9), Vector2(-1, 7), Vector2(1, 7)]:
		_add("floor", S, Vector3(c.x, y3 + 2.0, c.y), 0)
	_add("floor", S, Vector3(1, y3 + 2.25, 7), 0)
	_add("stairs", S, Vector3(1, y3 + 2.5, 7), 3)
	for p in [Vector2(-1.8, 9.8), Vector2(-1.8, 6.4), Vector2(1.8, 6.4), Vector2(-0.2, 8.2)]:
		_add("pillar", S, Vector3(p.x, y3, p.y), 0)
	var ptop := 1.0 + 3.0 * ps
	_wall_x("railing", 1, 8, ptop, S)
	_wall_z("railing", 0, 7, ptop, S)
	for sx in [-4, 4]:
		for z in [7, 9]:
			_wall_z("battlement", sx, z, ptop, S)
	for x in [-3, -1, 1, 3]:
		_wall_x("battlement", x, 6, ptop, S)
	for w in slant:
		_add("battlement", S, w[0] + Vector3(0, ptop, 0), w[1])
	for band in [ps + 0.7, 2.0 * ps + 0.7, 3.0 * ps + 0.7]:
		for sx in [-4, 4]:
			for z in [7, 9]:
				_on_wall_x("cornice", S, sx, z, band, signi(sx))
		for w in slant:
			_add("cornice", S, w[0] + w[2] * trim + Vector3(0, band, 0), w[1])
	# --- the keep: a big ring (R = 2) behind the hall, its front side the middle of the hall's back wall
	var R := 2
	_ring_off = Vector3(0, 0, -6.0 - R * _EDGE)
	_big_ring_layer(R, "foundation", "foundation_triangle", 0.0)
	var front := _dir(0) * (R * _EDGE) + _ring_off
	var kst := [[2, 0], [4, 0], [1, 0], [3, 0]]          # each storey's stairs: [big square, small square]
	var wins := [[3, 9], [2, 10], [3, 9], [2, 4, 8, 10]]
	var y := 1.0
	for s in 4:
		var door := s in [0, 2]                           # into the hall's two tall storeys (F710: they meet storeys 1 and 3)
		var wj: Array = wins[s]
		_big_ring_edges(R, y, func(j, _m): return "" if (j == 0 and door) else ("window_wall" if j in wj else "wall"))
		if door:
			for sx in [-1.5, 1.5]:
				_add("wall_narrow", S, front + Vector3(sx, y, 0), 0)
			_add("doorway", S, front + Vector3(0, y, 0), 0)
		_big_ring_corners(R, y, "pillar")
		_big_ring_stairs(R, kst[s][0], kst[s][1], y)
		var f := y + 2.0
		_big_ring_layer(R, "floor", "floor_triangle", f, [[kst[s][0], R - 1, kst[s][1]]])
		_big_ring_rails(R, kst[s][0], kst[s][1], f + 0.25)
		var hidden := [11, 0, 1, 5, 6, 7]                 # (no bands where the hall meets it, or in the rock)
		_big_ring_edges(R, f - 0.05, func(j, _m): return "" if j in hidden else "cornice", S, trim)
		y = f + 0.25
	# its roof is level with the hall's roof walk (both 10 m): no battlement on the hall's side, you walk straight on
	_big_ring_edges(R, y, func(j, _m): return "" if j == 0 else "battlement")
	_big_ring_corners(R, y, "battlement_corner")
	# the small ring on the keep's roof: three storeys, then the crown
	var top := y
	for k in 3:
		var sk: int = [2, 4, 0][k]
		if k == 0:
			_ring_edges(top, func(j): return "doorway" if j == 0 else ("window_wall" if j in [4, 8] else "wall"))
			_add("door", S, _dir(0) * _EDGE + _ring_off + Vector3(0, top, 0), 0)
			_ring_pillars(top, [11, 0])
		else:
			_ring_edges(top, func(j): return "window_wall" if j % 2 == k % 2 else "wall")
			_ring_pillars(top)
		_ring_stairs(sk, top)
		var fk := top + 2.0
		_ring_layer("floor", "floor_triangle", fk, sk)
		_ring_rails(sk, fk + 0.25)
		if k < 2:
			_big_ring_edges(1, fk - 0.05, func(_j, _m): return "cornice", S, trim)
		top = fk + 0.25
	top -= 0.25
	# the crown: on every square side a balcony 2 m out on two brackets, battlements round it; plain battlements between
	for j in 12:
		var n := _dir(j)
		var ty := Vector3(0, top + 0.25, 0)
		if j % 2 == 1:
			_add("battlement", S, n * _EDGE + _ring_off + ty, _rot(j))
			continue
		var c := n * (_EDGE + 1.0) + _ring_off
		_add("floor", S, c + Vector3(0, top, 0), _rot(j))
		_add("battlement", S, n * (_EDGE + 2.0) + _ring_off + ty, _rot(j))
		for sd in [-1, 1]:
			_add("battlement", S, c + _dir(j + 3) * sd + ty, _rot(j + 3))
			_add("corbel", S, n * (_EDGE + cdepth) + _dir(j + 3) * (0.65 * sd) + _ring_off + Vector3(0, top - 1.0, 0), _rot(j))
	_ring_off = Vector3.ZERO
	# --- move it so the box is centred. Only the space round the castle itself is "air" (dug out when you build
	# it): its pieces plus 1.5 m round and over them (F657: the cave keeps its own shape round it, and the dip
	# under the bridge stays a dip); the cave wall behind the keep stays rock.
	for p in _bp.pieces:
		p.pos += PROW_SHIFT
	_air_only_round_pieces(func(lx: float, y: float, lz: float) -> bool: return y < prow_rock_top(lx, lz))


## F657 (the grand ruins built into the cave): only the space round the building itself is "air" (dug out when you
## build it): its pieces plus 1.5 m round and over them, so the cave keeps its own shape round it. `keep_rock`
## (x, y, z in the box's frame, y = the cell's middle) says where the ruin's own rock (lumps, cave wall) stays rock.
func _air_only_round_pieces(keep_rock: Callable) -> void:
	var sx := int(_bp.size.x)
	var sy := int(_bp.size.y)
	var sz := int(_bp.size.z)
	var near := PackedByteArray()
	near.resize(sx * sy * sz)
	for p in _bp.pieces:
		var b := Pieces.box(p.id, p.pos, p.rot).grow(1.5)
		b.position.y += 1.5  # (not under it: only round and over it)
		b.size.y -= 1.5
		for cy in range(maxi(0, floori(b.position.y)), mini(sy, ceili(b.end.y))):
			for cz in range(maxi(0, floori(b.position.z + sz * 0.5)), mini(sz, ceili(b.end.z + sz * 0.5))):
				for cx in range(maxi(0, floori(b.position.x + sx * 0.5)), mini(sx, ceili(b.end.x + sx * 0.5))):
					near[(cy * sz + cz) * sx + cx] = 1
	var i := 0
	for cy in sy:
		for cz in sz:
			for cx in sx:
				if near[i] == 0 or keep_rock.call(cx + 0.5 - sx * 0.5, cy + 0.5, cz + 0.5 - sz * 0.5):
					_bp.air[i] = 0
				i += 1


## A small round tower of the Prow Hall, centred at `c`, foundations at `y0`. `stairs[s]` = the square storey s's
## stairs climb from (one per storey; the last one leads onto the roof), `doors[s]` = its sides with a doorway,
## `windows[s]` its small windows. A flat roof with battlements and a trim band under them. Returns the roof's top.
func _prow_tower(c: Vector3, y0: float, stairs: Array, doors: Dictionary, windows: Array, trim: float) -> float:
	_ring_off = Vector3(c.x, 0, c.z)
	_ring_layer("foundation", "foundation_triangle", y0)
	var y := y0 + 1.0
	for s in stairs.size():
		var dj: Array = doors.get(s, [])
		var wj: Array = windows[s % windows.size()]
		_ring_edges(y, func(j): return "doorway" if j in dj else ("window_wall" if j in wj else "wall"))
		var skip := []
		for j in dj:
			skip.append_array([posmod(j - 1, 12), j])
		_ring_pillars(y, skip)
		_ring_stairs(stairs[s], y)
		var f := y + 2.0
		_ring_layer("floor", "floor_triangle", f, stairs[s])
		_ring_rails(stairs[s], f + 0.25)
		y = f + 0.25
	_big_ring_edges(1, y - 0.3, func(_j, _m): return "cornice", STONE, trim)
	_ring_edges(y, func(_j): return "battlement")
	_big_ring_corners(1, y, "battlement_corner")
	_ring_off = Vector3.ZERO
	return y


## Owner, Nov 24 (F845, ruin 10 of Zone 1, a GRAND ruin: docs/design/ruin10/SMELTERY-PLAN.md): the Smeltery Terraces,
## a Hearthbrick bronze-works climbing out of the cave in three tiers, its back set into the rock. Not learnable yet:
## its 3D page first. Plan on the 2 m grid (numbers before the shift at the end):
##   - The yard (x -6..6, z 6..10, ground) with steps in front; a grand stair three cells wide up to the terrace.
##   - The vaults (x -12..16, z 2..4 and x -12..8, z -6..0): one storey of ore vaults; their roof (3.0) is the terrace.
##   - The Smelting Hall (x -6..6, z -6..0) on the terrace: a tall storey (4.5 m, two walls), stacked stairs (F838).
##     Its upper storey (7.75) juts OUT 2 m both sides: on brackets over the left terrace, and over a covered alley on
##     the right that ends at the tower. A steep roof (top 13.75) running into the tower, roof windows on the front.
##   - The Chimney Tower (x 10..16, z -6..0, the tallest): six square storeys from the ground, then a 12-sided room,
##     then a crown of balconies on brackets (square, round, star: two shape changes).
##   - A bridge (8 m) from the left terrace over a dip in the cave floor to the round Furnace Tower (3 storeys + deck).
const SMELT_SHIFT := Vector3(5, 0, -3)
const SMELT_TOWER := Vector3(13, 0, -3)          # the chimney tower's middle (its ring room stands on its roof)
const SMELT_FURNACE := Vector3(-24.732051, 0, 2)  # the furnace tower's middle: its right flat side meets the bridge at x -21
const SMELT_STAIR_TURRET := Vector3(-9.05, 0, -0.5)  # the hall's 6-sided stair turret: its right flat side 1 cm off the hall
const SMELT_WATCH := Vector3(19.052, 0, 3.0)       # the watch turret: its whole left flat side 2 cm off the vaults' side wall (F867)


## How high the Smeltery's own rock reaches at (x, z) in its box: the cave wall behind it (everything behind the back walls).
static func smelt_rock_top(_x: float, z: float) -> float:
	return 99.0 if z < -7.2 + SMELT_SHIFT.z else 0.0


func _smeltery() -> void:
	_start(Vector3(52, 24, 22))
	var B := BRICK
	var W := WOOD
	var g := 1.0
	var u := 3.25
	var trim := 0.15 + Pieces.LIST["cornice"].size.z * 0.5
	# --- the vaults: foundations, the terrace floor on top (3.0)
	var vault := []
	for x in range(-12, 17, 2):
		for z in [2, 4]:
			vault.append(Vector2(x, z))
	for x in range(-12, 9, 2):
		for z in [-6, -4, -2, 0]:
			vault.append(Vector2(x, z))
	for c in vault:
		_add("foundation", B, Vector3(c.x, 0, c.y), 0)
		_add("floor", B, Vector3(c.x, 3.0, c.y), 0)
	# the front: three doors to the yard and the cave floor, windows, plain wall behind the grand stair
	var front := {-12: "wall", -10: "window_wall", -8: "wall", -6: "doorway", -4: "window_wall", -2: "wall", 0: "wall",
		2: "wall", 4: "window_wall", 6: "doorway", 8: "wall", 10: "window_wall", 12: "wall", 14: "doorway", 16: "window_wall"}
	for x in front:
		_wall_x(front[x], x, 5, g, B)
		if front[x] == "doorway":
			_add("door", B, Vector3(x, g, 5), 0)
	_add("foundation_steps", B, Vector3(14, 0, 6), 0)
	for z in [-6, -4, -2, 0, 2, 4]:
		_wall_z("doorway" if z == -4 else ("window_wall" if z == 0 else "wall"), -13, z, g, B)
	_add("door", B, Vector3(-13, g, -4), 1)
	_add("foundation_steps", B, Vector3(-14, 0, -4), 3)
	_wall_z("wall", 17, 2, g, B)
	_wall_z("wall", 17, 4, g, B)                                             # (the watch turret stands against it)
	for x in range(-12, 9, 2):
		_wall_x("wall", x, -7, g, B)
	# inside: walls under the hall's walls (they carry it), with open arches through
	for x in range(-6, 7, 2):
		_wall_x("doorway" if x in [-2, 2] else "wall", x, 1, g, B)   # (solid under the hall's doors and windows)
	for z in [-6, -4, -2, 0]:
		_wall_z("doorway" if z == -2 else "wall", -7, z, g, B)
		_wall_z("doorway" if z == -4 else "wall", 7, z, g, B)
	# --- the yard (ground), steps in front, railings round it; the grand stair (3 wide) up to the terrace
	for x in range(-6, 7, 2):
		for z in [6, 8, 10]:
			_add("foundation", B, Vector3(x, 0, z), 0)
	for x in [-4, 4]:                                                       # the split stair: two side flights
		_add("foundation_steps", B, Vector3(x, 0, 12), 0)
	for x in [-2, 0, 2]:                                                    # (the landing between them: the yard)
		_add("floor", B, Vector3(x, g, 6), 0)
		_add("stairs", B, Vector3(x, g + 0.25, 6), 0)
	for z in [6, 8, 10]:
		_wall_z("railing", -7, z, g, B)
		_wall_z("railing", 7, z, g, B)
	for x in [-6, -2, 0, 2, 6]:
		_wall_x("railing", x, 11, g, B)
	# the terrace's railings (open at the grand stair's top and where the bridge leaves)
	for x in range(-12, 17, 2):
		if absi(x) > 2:
			_wall_x("railing", x, 5, u, B)
	for z in [-6, -4, -2, 0, 4]:
		_wall_z("railing", -13, z, u, B)
	# (no railings on the right end, x 17: the watch turret stands there, its door onto the terrace, F867)
	# --- the Smelting Hall: storey 1 is tall (walls at 3.25 and 5.5), the upper floor at 7.5
	var lo := {-6: "wall", -4: "window_wall", -2: "wall", 0: "doorway", 2: "wall", 4: "window_wall", 6: "wall"}
	var hi := {-6: "window_wall", -4: "wall", -2: "window_wall", 0: "window_wide", 2: "window_wall", 4: "wall", 6: "window_wall"}
	for x in lo:
		_wall_x(lo[x], x, 1, u, B)
		_wall_x(hi[x], x, 1, u + 2.25, B)
		_wall_x("wall", x, -7, u, B)
		_wall_x("wall", x, -7, u + 2.25, B)
	_add("door", B, Vector3(0, u, 1), 0)
	for z in [-6, -4, -2, 0]:
		_wall_z("window_wall" if z in [-6, -4] else "wall", -7, z, u, B)    # (plain where the stair turret stands)
		_wall_z("wall", -7, z, u + 2.25, B)
		_wall_z("doorway" if z == -2 else ("window_wall" if z == -4 else "wall"), 7, z, u, B)
		_wall_z("wall", 7, z, u + 2.25, B)
	_add("door", B, Vector3(7, u, -2), 1)                                   # from the covered alley
	for x in lo:                                                            # the beam band between its two walls
		_wall_x("beam", x, 1, u + 2.0, B)
		_wall_x("beam", x, -7, u + 2.0, B)
	for z in [-6, -4, -2, 0]:
		_wall_z("beam", -7, z, u + 2.0, B)
		_wall_z("beam", 7, z, u + 2.0, B)
	_stacked_stairs(Vector3(-4, u, -6), 3, B, [1])                          # up the back wall toward +x (F838)
	var f2 := 7.5
	for x in range(-6, 9, 2):
		for z in [-6, -4, -2, 0]:
			if Vector2(x, z) != Vector2(-2, -6):
				_add("floor", B, Vector3(x, f2, z), 0)
	_wall_x("railing", -2, -5, f2 + 0.25, B)
	_wall_z("railing", -3, -6, f2 + 0.25, B)
	# storey 2 (walls 7.75): 2 m wider on the right, over the covered alley (its right wall is the tower's); its left
	# side is flush (shape model v2: the round stair turret stands there). A door onto the front balcony.
	var w2 := f2 + 0.25
	var up2 := {-6: "window_wall", -4: "wall", -2: "window_wall", 0: "doorway", 2: "window_wall", 4: "wall",
		6: "window_wall", 8: "wall"}
	for x in up2:
		_wall_x(up2[x], x, 1, w2, B)
		_wall_x("wall", x, -7, w2, B)
	_add("door", B, Vector3(0, w2, 1), 0)
	for z in [-6, -4, -2, 0]:
		_wall_z("window_wall" if z in [-6, -4] else "wall", -7, z, w2, B)
	# the long wooden front balcony (7.5) on brackets, railed all round
	for x in range(-6, 7, 2):
		_add("floor", W, Vector3(x, f2, 2), 0)
		_wall_x("railing", x, 3, w2, W)
		_on_wall_z("corbel", B, x, 1, f2 - 1.0, 1)
	for x in [-7, 7]:
		_wall_z("railing", x, 2, w2, W)
	# the round stair turret (6-sided, owner Nov 25: the smallest round shape real pieces make) on the hall's
	# front-left corner: one flat side against the hall, a door from the terrace, a ladder up its back, a railed top
	var st := Vector3(SMELT_STAIR_TURRET.x, 0, SMELT_STAIR_TURRET.z)
	_hex_edges(st + Vector3(0, u, 0), 1, func(j): return "doorway" if j == 11 else ("window_wall" if j == 9 else "wall"), B)
	_add("door", B, st + _dir(11) * _APO + Vector3(0, u, 0), _rot(11))
	var sy := u
	for i in 4:
		if i > 0:
			var wj: int = [1, 9, 1][i - 1]
			_hex_edges(st + Vector3(0, sy, 0), 1, func(j): return "window_wall" if j == wj else "wall", B)
		_hex_pillars(st + Vector3(0, sy, 0), 1, B)
		_hex_ladder(st + Vector3(0, sy, 0), 7, B)
		_hex_layer("floor_triangle", st + Vector3(0, sy + 2.0, 0), 1, 7, B)
		sy += 2.25
	_hex_edges(st + Vector3(0, sy, 0), 1, func(_j): return "railing", B)
	_hex_bands(st + Vector3(0, sy - 0.3, 0), 1, B)
	# the steep roof: ridge along x at z -3, gables at the left end, its right end runs into the tower; roof windows
	var top := w2 + 2.0
	for x in range(-6, 9, 2):
		_add("roof_45", B, Vector3(x, top, 0), 0)
		_add("roof_45", B, Vector3(x, top + 2.0, -2), 0)
		_add("roof_45", B, Vector3(x, top + 2.0, -4), 2)
		_add("roof_45", B, Vector3(x, top, -6), 2)
	_add("gable_45", B, Vector3(-7, top, 0), 1)
	_wall_z("wall", -7, -2, top, B)
	_add("gable_45", B, Vector3(-7, top + 2.0, -2), 1)
	_wall_z("wall", -7, -4, top, B)
	_add("gable_45", B, Vector3(-7, top + 2.0, -4), 3)
	_add("gable_45", B, Vector3(-7, top, -6), 3)
	for x in [-4, 4]:
		_add("dormer", B, Vector3(x, top, 0), 0)
	# --- the Chimney Tower (cells x 10..16, z -6..0): six square storeys
	var tx := [10, 12, 14, 16]
	var tz := [-6, -4, -2, 0]
	for x in tx:
		for z in tz:
			_add("foundation", B, Vector3(x, 0, z), 0)
	var lv := [g, u, 5.5, 7.75, 10.0, 12.25]
	# each storey's stairs: [cell, turn (0: toward -z, 2: toward +z, 3: toward +x)]; each foot on open floor, each
	# top onto open floor, never by a door
	var flights := [[Vector2(16, -2), 0], [Vector2(10, -4), 2], [Vector2(16, -2), 2], [Vector2(12, -2), 0],
		[Vector2(14, -4), 2], [Vector2(12, -2), 3]]
	for i in 6:
		var y: float = lv[i]
		var fy := y + 2.0
		for x in tx:
			var fw := "wall"
			if i == 0 or i == 1:
				fw = "doorway" if x == 12 else ("window_wall" if i == 1 and x == 16 else "wall")
			elif i == 3 and x == 14:
				fw = "doorway"                                              # onto the balcony halfway up
			elif (x in [10, 14]) == (i % 2 == 0):
				fw = "window_wall"
			_wall_x(fw, x, 1, y, B)
			_wall_x("wall", x, -7, y, B)
		for z in tz:
			var rw := "window_wall" if i > 0 and z in [-4, -2] and (z == -4) == (i % 2 == 1) else "wall"
			if (i == 0 or i == 3) and z == -4:
				rw = "doorway"
			_wall_z(rw, 17, z, y, B)
			_wall_z("doorway" if (i == 0 or i == 3) and z == -2 else "wall", 9, z, y, B)
		var c: Vector2 = flights[i][0]
		var r: int = flights[i][1]
		_add("floor", B, Vector3(c.x, y, c.y), 0)          # (a slab lifts its top level with the floor)
		_add("stairs", B, Vector3(c.x, y + 0.25, c.y), r)
		for x in tx:
			for z in tz:
				if x != int(c.x) or z != int(c.y):
					_add("floor", B, Vector3(x, fy, z), 0)
		# railings round the hole above: across its foot end and both sides (not on the tower's own walls)
		var ry := fy + 0.25
		if r == 3:
			_wall_z("railing", c.x - 1, c.y, ry, B)
			for s in [-1, 1]:
				_wall_x("railing", c.x, c.y + s, ry, B)
		else:
			_wall_x("railing", c.x, c.y + (1 if r == 0 else -1), ry, B)
			for s in [-1, 1]:
				if c.x + s > 9 and c.x + s < 17:
					_wall_z("railing", c.x + s, c.y, ry, B)
	_add("door", B, Vector3(12, g, 1), 0)
	_add("door", B, Vector3(12, u, 1), 0)                                   # onto the terrace
	_add("door", B, Vector3(17, g, -4), 1)
	_add("foundation_steps", B, Vector3(18, 0, -4), 1)
	_add("door", B, Vector3(9, 7.75, -2), 1)                                # from the hall's upper storey
	_add("door", B, Vector3(14, 7.75, 1), 0)                                # onto the wrap-round balcony
	_add("door", B, Vector3(17, 7.75, -4), 1)
	# the wrap-round balcony halfway up (7.5): along the front and down the right side, on brackets
	var bal := []   # (not at x 18, z 2: the watch turret's top is there, F867)
	for x in tx:
		bal.append(Vector2(x, 2))
		_on_wall_z("corbel", B, x, 1, 6.5, 1)
	for z in tz:
		bal.append(Vector2(18, z))
		_on_wall_x("corbel", B, 17, z, 6.5, 1)
	for c in bal:
		_add("floor", B, Vector3(c.x, 7.5, c.y), 0)
	for x in [10, 12, 14, 16]:
		_wall_x("railing", x, 3, 7.75, B)
	for z in [-6, -4, -2, 0]:
		_wall_z("railing", 19, z, 7.75, B)
	_wall_x("railing", 18, 1, 7.75, B)                                      # (its end, at the watch turret's back)
	_wall_z("railing", 9, 2, 7.75, B)
	_wall_x("railing", 18, -7, 7.75, B)
	# trim bands at its floor lines (where nothing leans on it), corner blocks
	for by in [2.95, 5.2, 9.7, 11.95, 14.2]:                                 # (not at 7.45: the balcony's brackets)
		for z in tz:
			_on_wall_x("cornice", B, 17, z, by, 1)
			if by > 14.0:
				_on_wall_x("cornice", B, 9, z, by, -1)
		if by > 3.0:
			for x in tx:
				_on_wall_z("cornice", B, x, 1, by, 1)
			_add("cornice_corner", B, Vector3(17.17, by, 1.17), 0)
		if by > 14.0:
			_add("cornice_corner", B, Vector3(8.83, by, 1.17), 0)
	# --- its 12-sided room on the roof (walls 14.5), then the crown: a deck with a balcony on brackets on every square
	# side (not the back one, in the rock), railings round it all
	_ring_off = SMELT_TOWER
	var ry0 := 14.5
	_ring_edges(ry0, func(j): return "window_wall" if j in [0, 2, 4, 10] else "wall", B)
	_ring_pillars(ry0, [], B)
	_ring_stairs(2, ry0, B)
	var deck := ry0 + 2.0
	_ring_layer("floor", "floor_triangle", deck, 2, B)
	_ring_rails(2, deck + 0.25, B)
	var cdepth := 0.15 + Pieces.LIST["corbel"].size.z * 0.5
	for j in 12:
		var n := _dir(j)
		var ty := Vector3(0, deck + 0.25, 0)
		if j % 2 == 1 or j == 6:
			_add("railing", B, n * _EDGE + _ring_off + ty, _rot(j))
			continue
		var bc := n * (_EDGE + 1.0) + _ring_off
		_add("floor", B, bc + Vector3(0, deck, 0), _rot(j))
		_add("railing", B, n * (_EDGE + 2.0) + _ring_off + ty, _rot(j))
		for sd in [-1, 1]:
			_add("railing", B, bc + _dir(j + 3) * sd + ty, _rot(j + 3))
			_add("corbel", B, n * (_EDGE + cdepth) + _dir(j + 3) * (0.65 * sd) + _ring_off + Vector3(0, deck - 1.0, 0), _rot(j))
	# the square chimney stack on the deck, a trim band round its top
	_ring_off = Vector3.ZERO
	var cy := deck + 0.25
	for k in 3:
		for z in [SMELT_TOWER.z - 1, SMELT_TOWER.z + 1]:
			_wall_x("wall", SMELT_TOWER.x, z, cy + 2.0 * k, B)
		for x in [SMELT_TOWER.x - 1, SMELT_TOWER.x + 1]:
			_wall_z("wall", x, SMELT_TOWER.z, cy + 2.0 * k, B)
	var ctop := cy + 6.0 - 0.4
	for s in [-1, 1]:
		_on_wall_z("cornice", B, SMELT_TOWER.x, SMELT_TOWER.z + s, ctop, s)
		_on_wall_x("cornice", B, SMELT_TOWER.x + s, SMELT_TOWER.z, ctop, s)
		for s2 in [-1, 1]:
			_add("cornice_corner", B, Vector3(SMELT_TOWER.x + s * 1.17, ctop, SMELT_TOWER.z + s2 * 1.17), 0)
	# (no pinnacles on the square top's front corners: owner, Nov 25, F845: "remove the 2 columns from the roof")
	# --- the bridge (x -20..-14, z 2) over the dip, brackets under both ends, three rows of tall columns under it (the dip is in front),
	# roofed in wood on posts
	for x in [-20, -18, -16, -14]:
		_add("floor", B, Vector3(x, 3.0, 2), 0)
		_wall_x("railing", x, 1, u, B)
		_wall_x("railing", x, 3, u, B)
		_add("roof_45_ridge", W, Vector3(x, u + 2.0, 2), 0)
	for x in [-19, -17, -15, -13]:  # (-13: posts at the hall end too, owner, Nov 25, F845)
		for z in [1, 3]:
			_add("pillar", W, Vector3(x, u, z), 0)
	for z in [1.35, 2.65]:
		_on_wall_x("corbel", B, -13, z, 2.0, -1)
		_on_wall_x("corbel", B, -21, z, 2.0, 1)
	# three rows of tall columns from the cave floor up to it, no brick block under them (owner, Nov 25, F845)
	for x in [-19, -17, -15]:
		for z in [1, 3]:
			_add("column_base", B, Vector3(x, 0, z), 0)
			_add("column", B, Vector3(x, 0.5, z), 0)
			_add("column_capital", B, Vector3(x, 2.5, z), 0)
	# --- the Furnace Tower (12-sided): the ground door at its front, the bridge door on its right, stairs up a
	# different side each storey, a deck with railings on top
	_ring_off = SMELT_FURNACE
	_ring_layer("foundation", "foundation_triangle", 0.0, -1, B)
	# the square porch on its front flat side: one storey, a lean-to roof against the ring, steps in front
	var pc := _ring_off + Vector3(0, 0, _EDGE + 0.17 + 1.0)
	_add("foundation", B, pc, 0)
	_add("foundation_steps", B, pc + Vector3(0, 0, 2), 0)
	_wall_x("doorway", pc.x, pc.z + 1, g, B)
	_add("door", B, Vector3(pc.x, g, pc.z + 1), 0)
	for s in [-1, 1]:
		_wall_z("window_wall", pc.x + s, pc.z, g, B)
		_add("sloped_wall", B, Vector3(pc.x + s, u - 0.25, pc.z), 1)
	_add("roof_45", B, Vector3(pc.x, u - 0.25, pc.z), 0)
	_ring_edges(g, func(j): return "doorway" if j == 0 else ("window_wall" if j in [5, 8] else "wall"), B)
	_add("door", B, _dir(0) * _EDGE + _ring_off + Vector3(0, g, 0), 0)
	_ring_pillars(g, [11, 0], B)
	_ring_stairs(4, g, B)
	_ring_layer("floor", "floor_triangle", 3.0, 4, B)
	_ring_rails(4, u, B)
	_ring_edges(u, func(j): return "doorway" if j == 3 else ("window_wall" if j in [6, 9] else "wall"), B)   # (porch roof at 0)
	_add("door", B, _dir(3) * _EDGE + _ring_off + Vector3(0, u, 0), _rot(3))
	_ring_pillars(u, [2, 3], B)
	_ring_stairs(0, u, B)
	_ring_layer("floor", "floor_triangle", 5.25, 0, B)
	_ring_rails(0, 5.5, B)
	_ring_edges(5.5, func(j): return "window_wall" if j in [1, 5, 9] else "wall", B)
	_ring_pillars(5.5, [], B)
	_ring_stairs(2, 5.5, B)
	_ring_layer("floor", "floor_triangle", 7.5, 2, B)
	_add("railing", B, _dir(4) * (_APO + 1.0) - _dir(7) + Vector3(0, 7.75, 0) + _ring_off, _rot(7))   # (the neck's wall is its inner side)
	_ring_edges(7.75, func(_j): return "railing", B)
	_big_ring_edges(1, 7.45, func(_j, _m): return "cornice", B, trim)
	_big_ring_edges(1, 5.2, func(j, _m): return "" if j == 3 else "cornice", B, trim)    # (the bridge roof at 3)
	_big_ring_edges(1, 2.95, func(j, _m): return "" if j in [0, 3] else "cornice", B, trim)
	# the thinner round neck on the deck (kiln bottle, 6-sided): two storeys, a ladder up its back, a railed top
	var nk := _ring_off
	for i in 2:
		var ny := 7.75 + 2.25 * i
		var nw: Array = [2, 10] if i == 0 else [4, 8]
		var first := i == 0
		_hex_edges(nk + Vector3(0, ny, 0), 0, func(j): return "doorway" if first and j == 0 else (
			"window_wall" if j in nw else "wall"), B)
		_hex_pillars(nk + Vector3(0, ny, 0), 0, B)
		_hex_ladder(nk + Vector3(0, ny, 0), 6, B)
		_hex_layer("floor_triangle", nk + Vector3(0, ny + 2.0, 0), 0, 6, B)
	_add("door", B, nk + _dir(0) * _APO + Vector3(0, 7.75, 0), 0)
	_hex_edges(nk + Vector3(0, 12.25, 0), 0, func(_j): return "railing", B)
	_hex_bands(nk + Vector3(0, 11.95, 0), 0, B)
	_ring_off = Vector3.ZERO
	# --- the watch turret (6-sided) on the vaults' right side wall, its whole flat side against it (owner, Nov 25, F867:
	# it stood on its own past the front corner): a ground door toward the yard, a door from the terrace, a ladder up,
	# a railed top level with the tower's balcony, right at its end
	var wt := Vector3(SMELT_WATCH.x, 0, SMELT_WATCH.z)
	_hex_layer("foundation_triangle", wt, 1, -1, B)
	_add("foundation_steps", B, wt + _dir(1) * (_APO + 1.17), _rot(1))
	_add("door", B, wt + _dir(1) * _APO + Vector3(0, g, 0), _rot(1))
	_add("door", B, wt + _dir(9) * _APO + Vector3(0, u, 0), _rot(9))
	for wy in [g, u, 5.5]:
		var low: bool = wy == g
		var mid: bool = wy == u
		_hex_edges(wt + Vector3(0, wy, 0), 1, func(j): return "doorway" if (low and j == 1) or (mid and j == 9) else (
			"window_wall" if j in [3, 11] else "wall"), B)
		_hex_pillars(wt + Vector3(0, wy, 0), 1, B)
		_hex_ladder(wt + Vector3(0, wy, 0), 7, B)
		_hex_layer("floor_triangle", wt + Vector3(0, wy + 2.0, 0), 1, 7, B)
	_hex_edges(wt + Vector3(0, 7.75, 0), 1, func(_j): return "railing", B)
	_hex_bands(wt + Vector3(0, 7.45, 0), 1, B)
	# --- the vaults' trim band at the terrace line (not behind the grand stair or where the bridge's brackets are)
	for x in range(-12, 17, 2):
		if absi(x) > 2:
			_on_wall_z("cornice", B, x, 5, 2.95, 1)
	for z in [-6, -4, -2, 0, 4]:
		_on_wall_x("cornice", B, -13, z, 2.95, -1)
	# (none on the right side wall: the watch turret covers it all, F867)
	_add("cornice_corner", B, Vector3(-13.17, 2.95, 5.17), 0)
	_brackets_off_windows()
	# --- move it so the box is centred; only the space round the pieces is dug (F657), the cave wall behind stays
	for p in _bp.pieces:
		p.pos += SMELT_SHIFT
	_air_only_round_pieces(func(lx: float, _y: float, lz: float) -> bool: return smelt_rock_top(lx, lz) > 0.0)


## How far the glass reaches from a window piece's middle, along its wall (the rest is the frame's brick or wood).
const GLASS_HALF := {window_wall = 0.6, window_wide = 0.75}


## Does this bracket (corbel) cover a window's glass? (owner, Nov 25, F845: "these things cannot touch walls with
## glass, it doesn't make sense"). Next to the window, on the frame or the wall between, is fine.
static func bracket_on_glass(c: Dictionary, w: Dictionary) -> bool:
	if not GLASS_HALF.has(w.id):
		return false
	var along := Vector3.RIGHT.rotated(Vector3.UP, Pieces.yaw_of(w.rot))
	var d: Vector3 = c.pos - w.pos
	var out := Vector3(d.x, 0, d.z) - along * d.dot(along)
	var cy: float = c.pos.y
	if out.length() > 0.8 or cy + Pieces.LIST["corbel"].size.y <= w.pos.y or cy >= w.pos.y + Pieces.LIST[w.id].size.y:
		return false
	return absf(d.dot(along)) < GLASS_HALF[w.id] + Pieces.LIST["corbel"].size.x * 0.5 - 0.01


## Every bracket that would cover a window's glass slides along its wall to the seam beside the window (where two
## wall pieces meet); if that is taken or on glass too, it goes.
func _brackets_off_windows() -> void:
	var wins := _bp.pieces.filter(func(q): return GLASS_HALF.has(q.id))
	var gone := []
	for c in _bp.pieces:
		if c.id != "corbel":
			continue
		for w in wins:
			if not bracket_on_glass(c, w):
				continue
			var along := Vector3.RIGHT.rotated(Vector3.UP, Pieces.yaw_of(w.rot))
			var t: float = (c.pos - w.pos).dot(along)
			var moved := false
			for side in ([1.0, -1.0] if t >= 0.0 else [-1.0, 1.0]):
				var np: Vector3 = c.pos + along * (side * 1.0 - t)
				var free := true
				for q in _bp.pieces:
					if q != c and q.id == "corbel" and q.pos.distance_to(np) < 0.3:
						free = false
				var at := {id = "corbel", pos = np, rot = c.rot}
				for w2 in wins:
					if bracket_on_glass(at, w2):
						free = false
				if free:
					c.pos = np
					moved = true
					break
			if not moved:
				gone.append(c)
			break
	for c in gone:
		_bp.pieces.erase(c)


## The wooden Smeltery's chimney tower is six storeys plus its ring room, crown and chimney (about 23 m): wood loses
## too much strength that high (Structure: 8% a storey up, floors count too), so the whole tower above its ground
## floor stays brick, and so does its wrap-round balcony, like the Prow Hall's keep top.
func _smelt_top_stays_brick() -> void:
	for p in _bp.pieces:
		var lx: float = p.pos.x - SMELT_SHIFT.x
		var lz: float = p.pos.z - SMELT_SHIFT.z
		var balcony: bool = p.pos.y > 6.4 and p.pos.y < 8.8 and lz < 3.2
		if lx > 8.9 and lx < 19.2 and p.pos.y > 0.9 and (lz < 1.7 or balcony):
			p.mat = BRICK


# ---------------------------------------------------------------- helpers

func _start(size: Vector3) -> void:
	_bp = Blueprint.new()
	_bp.size = size
	var cells := int(size.x * size.y * size.z)
	_bp.air.resize(cells)
	_bp.air.fill(1)


## The wooden Prow Hall's keep is 7 storeys tall: wood loses too much strength that high (Structure: 8% a storey up,
## 16% sideways), so the small tower on the keep's roof and its crown stay stone, like the stone hall's. The same
## for the prow's top storey and roof (F710: its storeys are two walls high now, so its roof sits 14.5 m up).
func _prow_keep_top_stays_stone() -> void:
	var stone := BlueprintLibrary.make("stonehold_prow_hall")
	for i in _bp.pieces.size():
		var q: Dictionary = stone.pieces[i]
		var keep_top: bool = q.pos.y > 9.9 and Vector2(q.pos.x - PROW_KEEP.x, q.pos.z - PROW_KEEP.z).length() < 8.0
		# F822 (owner, Nov 23: grey merlons on a tower's wood deck): the keep's roof deck (10 m) is wood, so the
		# battlements round it are wooden railings too; only the small tower above stays stone
		if String(q.id).begins_with("battlement") and q.pos.y < 10.5:
			keep_top = false
		var prow_top: bool = q.pos.y > 9.9 and q.pos.z > PROW_SHIFT.z + 6.1
		if keep_top or prow_top:
			_bp.pieces[i].id = q.id
			_bp.pieces[i].mat = q.mat
	# F820 (owner, Nov 23: railing ends poke out past every tower's wood deck): _to_wood turns each 0.6 m battlement
	# corner into a whole 2 m railing, which juts out of the corner. The edge railings already meet there: drop them.
	var keep: Array[Dictionary] = []
	for i in _bp.pieces.size():
		if not (stone.pieces[i].id == "battlement_corner" and _bp.pieces[i].mat == WOOD):
			keep.append(_bp.pieces[i])
	_bp.pieces = keep


## The same building in root planks (docs/design/ruin-rebuild-plan.md): every piece that has a wooden version becomes
## wood; battlements (stone only) become wooden railings.
func _to_wood() -> void:
	for p in _bp.pieces:
		if Pieces.allowed(p.id, WOOD):
			p.mat = WOOD
		elif String(p.id).begins_with("battlement") and p.id != "battlement_narrow":
			p.id = "railing"
			p.mat = WOOD


## F169 (owner, Nov 22: "do you have to build this little platform under the stairs?"): the stairs are open now,
## so the floor slab that lifted a flight 25 cm (its top step level with the floor above) is a step in the way under
## them. Where that slab lies on a floor or foundation, it goes and the flight stands on that floor; its top step is
## then one ordinary 25 cm step below the floor above.
func _stairs_on_the_floor() -> void:
	var tops := {}  # "x,y,z" of the top middle of every floor and foundation
	var slabs := {}  # "x,y,z" of a floor's bottom middle -> its index
	for i in _bp.pieces.size():
		var p: Dictionary = _bp.pieces[i]
		if p.id == "floor" or p.id == "foundation":
			tops[_key(p.pos + Vector3(0, Pieces.LIST[p.id].size.y, 0))] = true
		if p.id == "floor":
			slabs[_key(p.pos)] = i
	var gone := {}
	for p: Dictionary in _bp.pieces:
		if p.id != "stairs" and p.id != "stairs_corner":
			continue
		var under: Vector3 = p.pos - Vector3(0, 0.25, 0)
		# F838: under two flights straight on (4 m) the slab stays, so the upper one still ends one 25 cm step
		# under a tall storey's floor (the Prow Hall's 4.5 m).
		var next: Vector3 = p.pos + Basis(Vector3.UP, Pieces.yaw_of(p.rot)) * Vector3(0, 2, -2)
		if p.id == "stairs" and _bp.pieces.any(func(q): return q.id == "stairs" and q.rot == p.rot and (q.pos as Vector3).distance_to(next) < 0.05):
			continue
		if slabs.has(_key(under)) and tops.has(_key(under)):
			gone[slabs[_key(under)]] = true
			# F804 (Nov 23): the stair railing beside them comes down with them (it floated 25 cm over the steps)
			for r: Dictionary in _bp.pieces:
				if r.id == "railing_stairs" and absf(r.pos.y - p.pos.y) < 0.01 \
						and Vector2(r.pos.x - p.pos.x, r.pos.z - p.pos.z).length() < 1.2:
					r.pos = r.pos - Vector3(0, 0.25, 0)
			p.pos = under
	var kept: Array[Dictionary] = []
	for i in _bp.pieces.size():
		if not gone.has(i):
			kept.append(_bp.pieces[i])
	_bp.pieces = kept


func _key(v: Vector3) -> String:
	return "%.2f,%.2f,%.2f" % [v.x, v.y, v.z]


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
