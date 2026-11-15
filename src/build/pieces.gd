class_name Pieces
## The building catalog (world doc section 5 + the building polish spec, Nov 14 2026).
## size = width (x) × height (y) × depth (z) in meters, before turning. Origin = bottom centre.
## place = how it snaps (1 m grid, see snap()): "cell" (footprint on grid lines), "edge" (on a grid line,
##         like a wall), "corner" (on a grid point), "free" (0.5 m steps), "ceiling" (hangs from rock).
## group  = which tab of the build menu.
## shape  = how it's drawn ("box" if missing): roof, ridge, roof_outer, roof_inner, gable, arch,
##          arch_doorway, column, brace, ladder, railing, door, steps.
## rise   = how high a roof/gable climbs over its depth (26° roofs: 1 m over 2 m; 45°: 2 m over 2 m).
## station= the station level that unlocks it, per station (workbench = wood, mason = stone/brick,
##          anvil = copper). A station missing from the list can't make this piece.
## families (optional) = the only materials it can be made from. Old pieces allow every material.

const GRID := 2.0  ## the main piece size
const FINE := 1.0  ## the snapping grid (2 m pieces + 1 m halves)
const ALL := {"workbench": 1, "mason": 1, "anvil": 1}

const LIST := {
	# --- foundations: thick blocks that can sink into uneven ground; always steady.
	# Rootwood foundations are the Delver's Shack's log-leg platforms (building kit, Nov 15).
	"foundation": {name = "Foundation", group = "foundation", size = Vector3(2, 1, 2), units = 8, place = "cell", foundation = true,
		families = ["plank_root", "cut_stone", "clay_brick"], station = {"workbench": 1, "mason": 1}},
	"foundation_half": {name = "Half Foundation", group = "foundation", size = Vector3(2, 1, 1), units = 4, place = "cell", foundation = true,
		families = ["plank_root", "cut_stone", "clay_brick"], station = {"workbench": 1, "mason": 1}},
	"foundation_steps": {name = "Foundation Steps", group = "foundation", size = Vector3(2, 1, 2), units = 6, place = "cell", foundation = true,
		shape = "steps", walkable_slope = true, families = ["cut_stone", "clay_brick"], station = {"mason": 2}},
	# --- floors
	"floor": {name = "Floor", group = "floor", size = Vector3(2, 0.25, 2), units = 4, place = "cell", station = ALL},
	"floor_half": {name = "Half Floor", group = "floor", size = Vector3(2, 0.25, 1), units = 2, place = "cell", station = ALL},
	"small_floor": {name = "Small Floor", group = "floor", size = Vector3(1, 0.25, 1), units = 1, place = "cell", station = ALL},
	# --- walls
	"wall": {name = "Wall", group = "wall", size = Vector3(2, 2, 0.3), units = 4, place = "edge", station = ALL},
	"wall_narrow": {name = "Narrow Wall", group = "wall", size = Vector3(1, 2, 0.3), units = 2, place = "edge",
		station = {"workbench": 2, "mason": 1, "anvil": 1}},
	"half_wall": {name = "Half Wall", group = "wall", size = Vector3(2, 1, 0.3), units = 2, place = "edge", station = ALL},
	"doorway": {name = "Doorway", group = "wall", size = Vector3(2, 2, 0.3), units = 4, place = "edge", extra = {copper_ingot = 2},
		opening = Vector3(1.0, 1.8, 0), round = true, station = ALL},  # round-topped (F57)
	# Round doors only (MODEL-RULES rule 5, F75): the arched doorway stays only so old saves load.
	"arch_doorway": {name = "Arched Doorway", group = "legacy", size = Vector3(2, 2, 0.3), units = 4, place = "edge", shape = "arch_doorway",
		opening = Vector3(1.2, 1.8, 0), families = ["cut_stone", "clay_brick"], station = {"mason": 2}},
	"window_wall": {name = "Small Window", group = "wall", size = Vector3(2, 2, 0.3), units = 3, place = "edge",
		opening = Vector3(1.0, 0.8, 0.6), station = {"workbench": 2, "mason": 1, "anvil": 1}},
	"window_wide": {name = "Wide Window", group = "wall", size = Vector3(2, 2, 0.3), units = 3, place = "edge",
		opening = Vector3(1.6, 0.9, 0.6), station = {"workbench": 2, "mason": 2, "anvil": 1}},
	"gable_26": {name = "Gable (gentle)", group = "roof", size = Vector3(2, 1, 0.3), units = 2, place = "edge", shape = "gable", rise = 1.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"gable_45": {name = "Gable (steep)", group = "roof", size = Vector3(2, 2, 0.3), units = 3, place = "edge", shape = "gable", rise = 2.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	# Building kit (docs/design/building-kit-zone1.md): a wall cut corner to corner (beside stairs,
	# under the sides of a sloped roof), Stonehold's flat roof and its battlements.
	"sloped_wall": {name = "Sloped Wall", group = "wall", size = Vector3(2, 2, 0.3), units = 3, place = "edge", shape = "gable", rise = 2.0,
		station = {"workbench": 1, "mason": 1, "anvil": 1}},
	"flat_roof": {name = "Flat Roof", group = "roof", size = Vector3(2, 0.3, 2), units = 4, place = "cell", shape = "flat_roof",
		station = {"workbench": 2, "mason": 1, "anvil": 2}},
	"battlement": {name = "Battlement", group = "roof", size = Vector3(2, 0.9, 0.4), units = 3, place = "edge", shape = "battlement",
		families = ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"], station = {"mason": 1}},
	"battlement_corner": {name = "Battlement Corner", group = "roof", size = Vector3(0.6, 1.3, 0.6), units = 2, place = "corner",
		shape = "battlement_corner", families = ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"], station = {"mason": 1}},
	"door": {name = "Door", group = "wall", size = Vector3(1, 1.8, 0.12), units = 2, place = "edge", shape = "door",
		families = ["plank_root", "plank_mushroom", "cut_stone", "clay_brick", "copper_ingot"], station = {"workbench": 1, "mason": 1, "anvil": 1}},
	# --- roofs: they climb `rise` meters from the front (z = +depth/2) to the back. Q turns them.
	"roof_26": {name = "Roof (gentle)", group = "roof", size = Vector3(2, 1, 2), units = 3, place = "cell", shape = "roof", rise = 1.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"roof_45": {name = "Roof (steep)", group = "roof", size = Vector3(2, 2, 2), units = 4, place = "cell", shape = "roof", rise = 2.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"roof_26_ridge": {name = "Roof Ridge (gentle)", group = "roof", size = Vector3(2, 0.5, 2), units = 3, place = "cell", shape = "ridge", rise = 0.5,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"roof_45_ridge": {name = "Roof Ridge (steep)", group = "roof", size = Vector3(2, 1, 2), units = 4, place = "cell", shape = "ridge", rise = 1.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"roof_26_outer": {name = "Roof Corner Out (gentle)", group = "roof", size = Vector3(2, 1, 2), units = 3, place = "cell", shape = "roof_outer", rise = 1.0,
		station = {"workbench": 3, "mason": 3, "anvil": 2}},
	"roof_26_inner": {name = "Roof Corner In (gentle)", group = "roof", size = Vector3(2, 1, 2), units = 3, place = "cell", shape = "roof_inner", rise = 1.0,
		station = {"workbench": 3, "mason": 3, "anvil": 2}},
	"roof_45_outer": {name = "Roof Corner Out (steep)", group = "roof", size = Vector3(2, 2, 2), units = 4, place = "cell", shape = "roof_outer", rise = 2.0,
		station = {"workbench": 3, "mason": 3, "anvil": 2}},
	"roof_45_inner": {name = "Roof Corner In (steep)", group = "roof", size = Vector3(2, 2, 2), units = 4, place = "cell", shape = "roof_inner", rise = 2.0,
		station = {"workbench": 3, "mason": 3, "anvil": 2}},
	# --- supports
	"beam": {name = "Beam", group = "support", size = Vector3(2, 0.3, 0.3), units = 2, place = "edge", station = ALL},
	"beam_half": {name = "Short Beam", group = "support", size = Vector3(1, 0.3, 0.3), units = 1, place = "edge", station = ALL},
	"brace": {name = "Diagonal Brace", group = "support", size = Vector3(2, 2, 0.25), units = 2, place = "edge", shape = "brace",
		families = ["plank_root", "plank_mushroom", "silver_ingot"], station = {"workbench": 2, "anvil": 1}},
	"pillar": {name = "Pillar", group = "support", size = Vector3(0.4, 2, 0.4), units = 3, place = "corner", station = ALL},
	"column": {name = "Carved Column", group = "support", size = Vector3(0.8, 2, 0.8), units = 4, place = "corner", shape = "column",
		families = ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"], station = {"mason": 2}},
	"arch": {name = "Stone Arch", group = "support", size = Vector3(2, 1, 0.4), units = 3, place = "edge", shape = "arch",
		families = ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"], station = {"mason": 2}},
	# --- getting around
	"stairs": {name = "Stairs", group = "around", size = Vector3(2, 2, 2), units = 6, place = "cell", walkable_slope = true, station = ALL},
	"ramp": {name = "Ramp", group = "around", size = Vector3(2, 1, 2), units = 4, place = "cell", shape = "ramp", walkable_slope = true,
		station = ALL},  # a smooth slope, rising toward the back (−z) like stairs
	"ladder": {name = "Ladder", group = "around", size = Vector3(1, 2, 0.2), units = 2, place = "edge", shape = "ladder",
		families = ["plank_root", "plank_mushroom"], station = {"workbench": 1, "anvil": 1}},
	"railing": {name = "Railing", group = "around", size = Vector3(2, 1, 0.15), units = 1, place = "edge", shape = "railing",
		families = ["plank_root", "plank_mushroom", "silver_ingot"], station = {"workbench": 1, "anvil": 1}},
	# --- triangles (building kit, Nov 15): EQUILATERAL, every side 2 m (one wall length), so any wall
	# fits any edge and six make a hexagon. The origin is the triangle's middle (centroid); rot 0 has
	# one edge facing +z (at z = +0.577) and the point at z = −1.155. They turn in 30° steps and
	# snap edge to edge onto squares and other triangles. size.z = the triangle's depth (1.732).
	"foundation_triangle": {name = "Triangle Foundation", group = "foundation", size = Vector3(2, 1, TRI_DEPTH), units = 4, place = "cell",
		foundation = true, shape = "tri", families = ["plank_root", "cut_stone", "clay_brick"], station = {"workbench": 1, "mason": 1}},
	"floor_triangle": {name = "Triangle Floor", group = "floor", size = Vector3(2, 0.25, TRI_DEPTH), units = 2, place = "cell", shape = "tri",
		station = {"workbench": 2, "mason": 1, "anvil": 1}},
	# The old 45° diagonal pieces stay only so old saves still load (hidden from the build menu).
	"wall_diagonal": {name = "Diagonal Wall", group = "legacy", size = Vector3(2, 2, 2), units = 6, place = "cell", shape = "diagonal",
		families = ["plank_root", "plank_mushroom", "cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"],
		station = {"workbench": 2, "mason": 2}},
	"half_wall_diagonal": {name = "Diagonal Half Wall", group = "legacy", size = Vector3(2, 1, 2), units = 3, place = "cell", shape = "diagonal",
		families = ["plank_root", "plank_mushroom", "cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"],
		station = {"workbench": 2, "mason": 2}},
	"window_diagonal": {name = "Diagonal Window", group = "legacy", size = Vector3(2, 2, 2), units = 5, place = "cell", shape = "diagonal",
		opening = Vector3(1.0, 0.8, 0.6), families = ["plank_root", "plank_mushroom", "cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"],
		station = {"workbench": 3, "mason": 2}},
	"railing_diagonal": {name = "Diagonal Railing", group = "legacy", size = Vector3(2, 1, 2), units = 2, place = "cell", shape = "diagonal",
		families = ["plank_root", "plank_mushroom", "copper_ingot", "silver_ingot"], station = {"workbench": 2, "anvil": 1}},
	# --- mining
	"ceiling_panel": {name = "Ceiling Panel", group = "mining", size = Vector3(2, 0.25, 2), units = 4, place = "ceiling", supports_rock = true, station = ALL},
	"mine_prop": {name = "Mine Prop", group = "mining", size = Vector3(2, 3, 0.4), units = 4, place = "free", extra = {copper_ingot = 1}, supports_rock = true,
		families = ["plank_root", "cut_stone"], station = ALL},
	# --- decor (Claude 2 hand-makes models for these; code shapes until then). on_wall = snaps flat onto
	# the face of a built wall you aim at. cloth = the colour of its cloth part. light = a glow it gives.
	"column_base": {name = "Column Base", group = "decor", size = Vector3(0.8, 0.5, 0.8), units = 1, place = "corner", shape = "column_base",
		families = STONE_KINDS, station = {"mason": 1}},
	"column_shaft": {name = "Column Shaft", group = "decor", size = Vector3(0.8, 1.0, 0.8), units = 1, place = "corner", shape = "column_shaft",
		families = STONE_KINDS, station = {"mason": 1}},
	"column_capital": {name = "Column Capital", group = "decor", size = Vector3(0.8, 0.5, 0.8), units = 1, place = "corner", shape = "column_capital",
		families = STONE_KINDS, station = {"mason": 2}},
	"table": {name = "Table", group = "decor", size = Vector3(2.0, 0.9, 1.0), units = 3, place = "free", shape = "table",
		families = WOODS + ["cut_stone"], station = {"workbench": 1, "mason": 2}},
	"bench": {name = "Bench", group = "decor", size = Vector3(2.0, 0.5, 0.5), units = 2, place = "free", shape = "bench",
		families = WOODS + ["cut_stone"], station = {"workbench": 1, "mason": 2}},
	"chair": {name = "Chair", group = "decor", size = Vector3(0.6, 1.1, 0.6), units = 1, place = "free", shape = "chair",
		families = WOODS, station = {"workbench": 1}},
	"shelf": {name = "Shelf", group = "decor", size = Vector3(1.6, 1.8, 0.4), units = 3, place = "free", shape = "shelf",
		families = WOODS, station = {"workbench": 2}},
	"barrel": {name = "Barrel", group = "decor", size = Vector3(0.7, 0.9, 0.7), units = 2, place = "free", shape = "barrel",
		families = WOODS, extra = {copper_ingot = 1}, station = {"workbench": 2}},
	"crate": {name = "Supply Crate", group = "decor", size = Vector3(0.9, 0.8, 0.9), units = 2, place = "free", shape = "crate",
		families = WOODS, station = {"workbench": 1}},
	"rug": {name = "Rug", group = "decor", size = Vector3(2.0, 0.03, 1.4), units = 1, place = "free", shape = "rug",
		families = WOODS, extra = {fiber = 8}, cloth = Color(0.55, 0.18, 0.14), station = {"workbench": 1}},
	"banner": {name = "Banner", group = "decor", size = Vector3(1.0, 2.0, 0.1), units = 1, place = "edge", shape = "banner", on_wall = true,
		families = WOODS + ["copper_ingot"], extra = {fiber = 6}, cloth = Color(0.5, 0.12, 0.12), station = {"workbench": 1, "anvil": 1}},
	"wall_shield": {name = "Wall Shield", group = "decor", size = Vector3(0.7, 0.7, 0.12), units = 2, place = "edge", shape = "wall_shield", on_wall = true,
		families = WOODS + ["copper_ingot"], station = {"workbench": 2, "anvil": 1}},
	"wall_sconce": {name = "Wall Sconce", group = "decor", size = Vector3(0.4, 0.6, 0.3), units = 1, place = "edge", shape = "wall_sconce", on_wall = true,
		families = ["copper_ingot", "cut_stone"], extra = {crystal_blue = 1}, light = Color(0.5, 0.8, 1.0), station = {"anvil": 1, "mason": 1}},
	# Wall decor (owner, Nov 15): hand-made models in assets/models/decor (model = folder/name), hung flat
	# on a wall like the banner. Size agreed with the 3D Claudes: back flat at z = -depth/2, nothing behind it.
	"banner_anvil": {name = "Anvil Banner", group = "decor", size = Vector3(1.0, 1.6, 0.1), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/banner_anvil", families = WOODS, extra = {fiber = 6}, station = {"workbench": 1}},
	"banner_landscape": {name = "Hollow Banner", group = "decor", size = Vector3(1.0, 1.6, 0.1), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/banner_landscape", families = WOODS, extra = {fiber = 6}, station = {"workbench": 1}},
	"bat_trophy": {name = "Bat Trophy", group = "decor", size = Vector3(0.8, 0.6, 0.25), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/bat_trophy", families = WOODS, station = {"workbench": 1}},
	"crossed_pickaxes": {name = "Crossed Pickaxes", group = "decor", size = Vector3(0.9, 0.7, 0.15), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/crossed_pickaxes", families = WOODS, extra = {copper_ingot = 1}, station = {"workbench": 1}},
	"fossil_plaque": {name = "Fossil Plaque", group = "decor", size = Vector3(0.7, 0.5, 0.12), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/fossil_plaque", families = WOODS, station = {"workbench": 1}},
	"horn_plaque": {name = "Horn Plaque", group = "decor", size = Vector3(0.6, 0.5, 0.4), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/horn_plaque", families = WOODS, station = {"workbench": 1}},
	"map_board": {name = "Map Board", group = "decor", size = Vector3(1.0, 0.8, 0.1), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/map_board", families = WOODS, extra = {fiber = 2}, station = {"workbench": 1}},
	"rune_shield": {name = "Rune Shield", group = "decor", size = Vector3(0.7, 0.7, 0.15), units = 2, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/rune_shield", families = WOODS, station = {"workbench": 2}},
	"peg_rack": {name = "Peg Rack", group = "decor", size = Vector3(1.0, 0.5, 0.25), units = 1, place = "edge", shape = "plaque", on_wall = true,
		model = "decor/shack_peg_rack", families = WOODS, station = {"workbench": 1}},
	"wall_torch": {name = "Wall Torch", group = "decor", size = Vector3(0.3, 0.7, 0.35), units = 1, place = "edge", shape = "wall_sconce", on_wall = true,
		model = "decor/wall_torch", families = WOODS, light = Color(1.0, 0.65, 0.3), station = {"workbench": 1}},
	"weapon_rack": {name = "Weapon Rack", group = "decor", size = Vector3(1.4, 1.6, 0.5), units = 3, place = "free", shape = "weapon_rack",
		families = WOODS, station = {"workbench": 2}},
}
const WOODS := ["plank_root", "plank_mushroom"]
const STONE_KINDS := ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"]

## The materials offered in Mossy Hollows' build menu (owner's choice): wood, stone, brick, copper.
const MOSSY_FAMILIES := ["plank_root", "cut_stone", "clay_brick", "copper_ingot"]

## Material families (world doc 5.3 + 5.6). hp = for a 2×2 wall (4 units). up/side = steadiness lost per
## piece away from support. Soft physics (spec §5): wood 0.08/0.16, stone & brick 0.04/0.10, metal 0.03/0.06.
const FAMILIES := {
	"plank_root": {name = "Rootwood", hp = 200, up = 0.08, side = 0.16, color = Color(0.62, 0.45, 0.28), damage = 1.0},
	"plank_mushroom": {name = "Capwood", hp = 260, up = 0.08, side = 0.16, color = Color(0.82, 0.74, 0.6), damage = 0.9},
	"mushroom_brick": {name = "Mushroom Brick", hp = 300, up = 0.04, side = 0.10, color = Color(0.8, 0.7, 0.6), damage = 0.8},
	"cut_stone": {name = "Cut Stone", hp = 500, up = 0.04, side = 0.10, color = Color(0.6, 0.58, 0.55), damage = 0.6},
	"cut_marble": {name = "Marble", hp = 600, up = 0.04, side = 0.10, color = Color(0.92, 0.92, 0.9), damage = 0.55},
	"clay_brick": {name = "Clay Brick", hp = 500, up = 0.04, side = 0.10, color = Color(0.78, 0.42, 0.25), damage = 0.6},
	"basalt": {name = "Basalt", hp = 550, up = 0.04, side = 0.10, color = Color(0.22, 0.22, 0.25), damage = 0.6},
	"brown_rock": {name = "Brown Rock", hp = 450, up = 0.04, side = 0.10, color = Color(0.45, 0.33, 0.24), damage = 0.6},
	"copper_ingot": {name = "Copper", hp = 800, up = 0.03, side = 0.06, color = Color(0.85, 0.5, 0.28), damage = 0.4},
	"crystal_blue": {name = "Crystal", hp = 150, up = 0.12, side = 0.30, color = Color(0.45, 0.75, 1.0), damage = 1.2, glow = true},
	# Fungal Jungle styles (world doc 6.3): Spore Brick (dark) and Kiln Clay (warm amber + silver trim).
	"sporestone_block": {name = "Sporestone", hp = 520, up = 0.04, side = 0.10, color = Color(0.36, 0.3, 0.42), damage = 0.6},
	"amber_block": {name = "Amber", hp = 450, up = 0.04, side = 0.10, color = Color(0.88, 0.64, 0.25), damage = 0.65},
	"ancient_brick": {name = "Ancient Brick", hp = 650, up = 0.04, side = 0.10, color = Color(0.55, 0.42, 0.35), damage = 0.55},
	"silver_ingot": {name = "Silver", hp = 1000, up = 0.03, side = 0.06, color = Color(0.82, 0.85, 0.92), damage = 0.35},
}

const PILLAR_UP_LOSS := 0.02  ## pillars and columns carry weight straight down very well


## Which station works this material: wood → Workbench, stone/brick → Mason's Table, metal → Anvil.
static func station_for(family: String) -> String:
	if family in ["plank_root", "plank_mushroom", "crystal_blue"]:
		return "workbench"
	if family in ["copper_ingot", "silver_ingot"]:
		return "anvil"
	return "mason"


## The station level needed to build `piece` from `family` (99 = this station can't make it).
static func needed_level(piece: String, family: String) -> int:
	return int(LIST[piece].get("station", ALL).get(station_for(family), 99))

const MIN_STABILITY := 0.10
const ROCK_SINK_OK := 0.35  ## pieces may poke this far into rock
const BOTTOM_SINK_OK := 0.6  ## floors/pillars/stairs/props may sink their bottom this deep
const BUILD_REACH := 8.0
const WORKBENCH_RANGE := 20.0


static func cost(piece: String, family: String) -> Dictionary:
	var p: Dictionary = LIST[piece]
	var c := {family: p.units}
	for item in p.get("extra", {}):
		c[item] = c.get(item, 0) + p.extra[item]
	return c


## Roof rules (MODEL-RULES rule 4, F79): Stonehold has flat roofs and battlements only; the Delver's
## Shack and Hearthbrick have sloped roofs only.
const SLOPED_ROOFS := ["roof_26", "roof_45", "roof_26_ridge", "roof_45_ridge", "roof_26_outer", "roof_26_inner",
	"roof_45_outer", "roof_45_inner", "gable_26", "gable_45"]
const NOT_FOR := {
	"cut_stone": SLOPED_ROOFS,
	"plank_root": ["flat_roof"],
	"clay_brick": ["flat_roof"],
}
## Copper is for decor and doors only (owner, Nov 15): a piece is made of copper only when it names it.
const DECOR_ONLY := ["copper_ingot"]


static func allowed(piece: String, family: String) -> bool:
	if not (LIST.has(piece) and FAMILIES.has(family)):
		return false
	if piece in NOT_FOR.get(family, []):
		return false
	if LIST[piece].has("families"):
		return family in LIST[piece].families
	return not family in DECOR_ONLY


static func hp(piece: String, family: String) -> float:
	return FAMILIES[family].hp * LIST[piece].units / 4.0


## Turning. `rot` is one small number, saved and sent as it always was:
##   0..3  = quarter turns (90°), as before, so old saves and blueprints still work;
##   4..15 = 30° steps: rot 4 + k means k × 30° (only made when a 30°/60° angle is needed).
const FINE_ROT := 4
const TRI_DEPTH := 1.7320508  ## an equilateral triangle with 2 m sides is √3 m deep
const TRI_IN := 0.57735027  ## centre → edge, for 2 m sides (scaled by size.x / 2)
const TRI_OUT := 1.1547005  ## centre → corner


static func steps_of(rot: int) -> int:
	return rot * 3 if rot < FINE_ROT else rot - FINE_ROT


## The number to store for k × 30° (a quarter turn when it is one).
static func rot_from_steps(k: int) -> int:
	k = posmod(k, 12)
	return k / 3 if k % 3 == 0 else FINE_ROT + k


static func yaw_of(rot: int) -> float:
	return steps_of(rot) * PI / 6.0


static func valid_rot(rot: int) -> bool:
	return rot >= 0 and rot < FINE_ROT + 12


static func add_rot(a: int, b: int) -> int:
	return rot_from_steps(steps_of(a) + steps_of(b))


static func is_tri(piece: String) -> bool:
	return LIST[piece].get("shape", "") == "tri"


## A piece is "square-turned" when it lies on the normal grid (0/90/180/270° and not a triangle).
static func on_square_grid(piece: String, rot: int) -> bool:
	return rot < FINE_ROT and not is_tri(piece)


## Size after turning by `rot` quarter turns (odd turns swap width and depth).
static func turned_size(piece: String, rot: int) -> Vector3:
	var s: Vector3 = LIST[piece].size
	return Vector3(s.z, s.y, s.x) if steps_of(rot) % 6 == 3 else s


## The piece's outline seen from above, in its own space (x, z): a rectangle, or the triangle.
static func outline(piece: String, grow: float = 0.0) -> PackedVector2Array:
	var s: Vector3 = LIST[piece].size
	if is_tri(piece):
		var k := s.x * 0.5
		var r_in := TRI_IN * k
		var f := maxf(r_in + grow, 0.01) / r_in  # grow/shrink every edge by `grow`
		return PackedVector2Array([Vector2(-k, r_in) * f, Vector2(k, r_in) * f, Vector2(0, -TRI_OUT * k) * f])
	var hx := maxf(s.x * 0.5 + grow, 0.005)
	var hz := maxf(s.z * 0.5 + grow, 0.005)
	return PackedVector2Array([Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)])


## The outline in the world (x, z), turned and moved. `grow` < 0 shrinks it (never past its middle).
static func footprint(piece: String, pos: Vector3, rot: int, grow: float = 0.0) -> PackedVector2Array:
	var b := Basis(Vector3.UP, yaw_of(rot))
	var out := PackedVector2Array()
	for q in outline(piece, grow):
		var w := b * Vector3(q.x, 0, q.y)
		out.append(Vector2(pos.x + w.x, pos.z + w.z))
	return out


static func box(piece: String, pos: Vector3, rot: int) -> AABB:
	if on_square_grid(piece, rot):
		var s := turned_size(piece, rot)
		return AABB(pos - Vector3(s.x * 0.5, 0, s.z * 0.5), s)
	var fp := footprint(piece, pos, rot)
	var lo := fp[0]
	var hi := fp[0]
	for q in fp:
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	return AABB(Vector3(lo.x, pos.y, lo.y), Vector3(hi.x - lo.x, LIST[piece].size.y, hi.y - lo.y))


## The sides of a piece's outline: [{mid: Vector3 (at the piece's base), normal: Vector3 (out), len}].
static func edges(piece: String, pos: Vector3, rot: int) -> Array:
	var fp := footprint(piece, pos, rot)
	var c := Vector2.ZERO
	for q in fp:
		c += q
	c /= fp.size()
	var out := []
	for i in fp.size():
		var a := fp[i]
		var b2 := fp[(i + 1) % fp.size()]
		var mid := (a + b2) * 0.5
		var d := (b2 - a).normalized()
		var nrm := Vector2(d.y, -d.x)
		if nrm.dot(mid - c) < 0.0:
			nrm = -nrm
		out.append({mid = Vector3(mid.x, pos.y, mid.y), normal = Vector3(nrm.x, 0, nrm.y), len = a.distance_to(b2)})
	return out


## Do two convex outlines overlap (more than just touching)? Separating-axis test.
static func outlines_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for poly in [a, b]:
		for i in poly.size():
			var e: Vector2 = poly[(i + 1) % poly.size()] - poly[i]
			var axis := Vector2(-e.y, e.x)
			var a_lo := INF
			var a_hi := -INF
			for q in a:
				var t := axis.dot(q)
				a_lo = minf(a_lo, t)
				a_hi = maxf(a_hi, t)
			var b_lo := INF
			var b_hi := -INF
			for q in b:
				var t := axis.dot(q)
				b_lo = minf(b_lo, t)
				b_hi = maxf(b_hi, t)
			if a_hi <= b_lo + 0.0001 or b_hi <= a_lo + 0.0001:
				return false
	return true


## Yaw (radians) whose front (+z) points along `dir` (flat).
static func _yaw_toward(dir: Vector3) -> float:
	return atan2(dir.x, dir.z)


static func _steps_for(yaw: float) -> int:
	return roundi(yaw / (PI / 6.0))


## Where a piece goes when you aim at `p` (surface point) with surface normal `n`,
## facing `yaw`, turned `rot` extra quarter turns, lifted `lift` meters.
## `anchor` = the box of the built piece under the crosshair (empty AABB = aiming at rock):
##  - aiming at its TOP: the new piece stands on it. Walls go to its nearest edge, pillars to its
##    nearest corner, roofs/floors line up on the 1 m grid (so a wall never lands mid-floor).
##  - aiming at the SIDE of a floor/foundation with a floor/foundation: the new one goes right next to it.
##  - otherwise: the 1 m grid (2 m pieces + 1 m halves), heights in 0.5 m steps.
## `anchor_piece` = that built piece's entry ({piece, pos, rot}); with it, triangles and anything
## turned 30°/60° snap edge to edge (see _snap_to_edges). `rot` = Q presses: quarter turns, or
## 30° steps for triangles.
static func snap(piece: String, p: Vector3, n: Vector3, yaw: float, rot: int, lift: float = 0.0, anchor: AABB = AABB(),
		anchor_piece: Dictionary = {}) -> Dictionary:
	var info: Dictionary = LIST[piece]
	if not anchor_piece.is_empty():
		var e := _snap_to_edges(piece, p, n, anchor_piece)
		if not e.is_empty():
			e.pos.y += lift
			return e
	if is_tri(piece):
		return _snap_tri_free(piece, p, n, yaw, rot, lift)
	var q := (posmod(roundi(yaw / (PI / 2.0)), 4) + rot) % 4
	var s := turned_size(piece, q)
	var h: float = info.size.y
	var pos := _on_grid(info.place, p, s, q)
	pos.y = snappedf(p.y, 0.5) if n.y > 0.5 else snappedf(p.y - h * 0.5, 0.5)
	var has_anchor := anchor.size != Vector3.ZERO
	if has_anchor and n.y > 0.5:
		pos.y = anchor.end.y
		match info.place:
			"edge":
				# Across the wall: the anchor's nearest face, or its middle line if it's thin (a wall on a wall).
				var axis := 2 if q % 2 == 0 else 0
				if anchor.size[axis] < 0.9:
					pos[axis] = anchor.get_center()[axis]
				else:
					pos[axis] = anchor.position[axis] if absf(p[axis] - anchor.position[axis]) < absf(p[axis] - anchor.end[axis]) else anchor.end[axis]
			"corner":
				for axis in [0, 2]:
					if anchor.size[axis] < 0.9:
						pos[axis] = anchor.get_center()[axis]
					else:
						pos[axis] = anchor.position[axis] if absf(p[axis] - anchor.position[axis]) < absf(p[axis] - anchor.end[axis]) else anchor.end[axis]
	elif has_anchor and absf(n.y) < 0.5 and (info.get("shape", "") == "ladder" or info.get("on_wall", false)):
		# A ladder (or a banner, shield, sconce) on the side of a wall: flat against the face we're
		# looking at, not inside the wall.
		var across := 0 if absf(n.x) > absf(n.z) else 2
		var side := signf(n[across])
		q = (0 if side > 0.0 else 2) if across == 2 else (1 if side > 0.0 else 3)  # its front (+z) faces out
		s = turned_size(piece, q)
		pos = _on_grid("edge", p, s, q)
		pos[across] = (anchor.end[across] if side > 0.0 else anchor.position[across]) + side * s[across] * 0.5
		pos.y = anchor.position.y
		if info.get("on_wall", false):  # hangs where you aim, in 25 cm steps, but stays on the wall
			pos.y = clampf(snappedf(p.y - h * 0.5, 0.25), anchor.position.y, maxf(anchor.position.y, anchor.end.y - h))
	elif has_anchor and absf(n.y) < 0.5 and info.place == "cell" and info.get("group", "") in ["floor", "foundation"] and anchor.size.y <= 1.05:
		# Next to the floor/foundation we're looking at, at the same height.
		var axis := 0 if absf(n.x) > absf(n.z) else 2
		var side := signf(n[axis])
		pos[axis] = (anchor.end[axis] if side > 0.0 else anchor.position[axis]) + side * s[axis] * 0.5
		pos.y = anchor.position.y
	if info.place == "ceiling":
		pos.y = snappedf(p.y, 0.5) - h if n.y < -0.5 else snappedf(p.y, 0.5)
	pos.y += lift
	return {pos = pos, rot = q}


## Snapping to the real edges of a built piece (60° triangles, and anything turned 30°/60°).
## Returns {} when the normal square-grid rules should decide instead.
static func _snap_to_edges(piece: String, p: Vector3, n: Vector3, a: Dictionary) -> Dictionary:
	var info: Dictionary = LIST[piece]
	var ainfo: Dictionary = LIST[a.piece]
	var a_cell: bool = ainfo.place == "cell" and ainfo.get("group", "") in ["floor", "foundation"]
	var me_cell: bool = info.place == "cell" and info.get("group", "") in ["floor", "foundation"]
	var a_odd := not on_square_grid(a.piece, a.rot)
	var a_top: float = (a.pos as Vector3).y + float(ainfo.size.y)
	# The anchor's side nearest to where we aim.
	var best := {}
	var best_d := INF
	for e in edges(a.piece, a.pos, a.rot):
		var d := Vector2(p.x - e.mid.x, p.z - e.mid.z).length()
		if d < best_d:
			best_d = d
			best = e
	if best.is_empty():
		return {}
	var nrm: Vector3 = best.normal
	var mid: Vector3 = best.mid
	# A floor/foundation next to the side of a floor/foundation (any shape): edge to edge, same height.
	if me_cell and a_cell and absf(n.y) < 0.5 and (a_odd or is_tri(piece)):
		var k: int
		var centre: Vector3
		if is_tri(piece):
			k = _steps_for(_yaw_toward(-nrm))  # our front edge lies on theirs
			centre = mid + nrm * TRI_IN * float(info.size.x) * 0.5
		else:
			k = _steps_for(_yaw_toward(nrm))
			centre = mid + nrm * float(info.size.z) * 0.5
		return {pos = Vector3(centre.x, (a.pos as Vector3).y, centre.z), rot = rot_from_steps(k)}
	# Standing on top of a triangle (or a turned piece).
	if n.y > 0.5 and a_odd:
		if info.place == "edge":  # walls, doorways, windows, railings, gables: on the nearest side
			return {pos = Vector3(mid.x, a_top, mid.z), rot = rot_from_steps(_steps_for(_yaw_toward(nrm)))}
		if info.place == "corner":  # pillars and columns: on the nearest corner
			var fp := footprint(a.piece, a.pos, a.rot)
			var c := fp[0]
			for q in fp:
				if Vector2(p.x, p.z).distance_to(q) < Vector2(p.x, p.z).distance_to(c):
					c = q
			return {pos = Vector3(c.x, a_top, c.y), rot = rot_from_steps(steps_of(a.rot))}
		if me_cell and is_tri(piece) == is_tri(a.piece) and absf(float(info.size.x) - float(ainfo.size.x)) < 0.01:
			return {pos = Vector3((a.pos as Vector3).x, a_top, (a.pos as Vector3).z), rot = a.rot}  # stacking the same shape
	return {}


## A triangle on open ground: its front edge on a 1 m grid line, its middle 1 m along it.
## `rot` = 30° steps added by Q.
static func _snap_tri_free(piece: String, p: Vector3, n: Vector3, yaw: float, rot: int, lift: float) -> Dictionary:
	var k := posmod(roundi(yaw / (PI / 2.0)), 4) * 3 + rot
	var r := rot_from_steps(k)
	var f := Basis(Vector3.UP, yaw_of(r)) * Vector3(0, 0, 1)
	var r_in := TRI_IN * float(LIST[piece].size.x) * 0.5
	var m := p + f * r_in
	var centre: Vector3
	if steps_of(r) % 3 == 0:
		m = Vector3(roundf(m.x / FINE) * FINE, 0, roundf(m.z / FINE) * FINE)
		centre = m - f * r_in
	else:
		centre = Vector3(snappedf(p.x, 0.5), 0, snappedf(p.z, 0.5))
	var h: float = LIST[piece].size.y
	centre.y = (snappedf(p.y, 0.5) if n.y > 0.5 else snappedf(p.y - h * 0.5, 0.5)) + lift
	return {pos = centre, rot = r}


## The piece's spot on the 1 m grid (x and z only).
static func _on_grid(place: String, p: Vector3, s: Vector3, q: int) -> Vector3:
	# Footprint edges on grid lines: centre = nearest grid line from the low edge, + half the size.
	var x := snappedf(p.x - s.x * 0.5, FINE) + s.x * 0.5
	var z := snappedf(p.z - s.z * 0.5, FINE) + s.z * 0.5
	match place:
		"edge":
			# Spans X when q is even (sits on a north/south line), spans Z when odd.
			if q % 2 == 0:
				z = roundf(p.z / FINE) * FINE
			else:
				x = roundf(p.x / FINE) * FINE
		"corner":
			x = roundf(p.x / FINE) * FINE
			z = roundf(p.z / FINE) * FINE
		"free":
			x = snappedf(p.x, 0.5)
			z = snappedf(p.z, 0.5)
	return Vector3(x, 0, z)


## Points used to test for rock: 8 corners (shrunk 0.1 m), the centre and 6 face centres.
## Returns [[point, is_bottom], ...].
static func check_points(piece: String, pos: Vector3, rot: int) -> Array:
	if not on_square_grid(piece, rot):
		# Triangles and turned pieces: the corners of their real outline, at the bottom and the top.
		var h: float = LIST[piece].size.y
		var pts := []
		var c := Vector2.ZERO
		var fp := footprint(piece, pos, rot, -0.1)
		for q in fp:
			c += q
			pts.append([Vector3(q.x, pos.y + minf(0.1, h * 0.3), q.y), true])
			pts.append([Vector3(q.x, pos.y + h - minf(0.1, h * 0.3), q.y), false])
		c /= fp.size()
		pts.append([Vector3(c.x, pos.y + h * 0.5, c.y), false])
		pts.append([Vector3(c.x, pos.y + minf(0.1, h * 0.3), c.y), true])
		return pts
	var b := box(piece, pos, rot).grow(-0.1)
	var out := []
	for i in 8:
		var c := b.get_endpoint(i)
		out.append([c, c.y < b.position.y + 0.01])
	var mid := b.get_center()
	out.append([mid, false])
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var f := mid
			f[axis] += sgn * b.size[axis] * 0.5
			out.append([f, axis == 1 and sgn < 0.0])
	return out


## Why a piece can't go here because of rock ("" = fine). `sdf` = Callable(Vector3) -> float.
static func rock_problem(piece: String, pos: Vector3, rot: int, sdf: Callable) -> String:
	var sinks: bool = LIST[piece].place in ["cell", "corner", "free"]
	for cp in check_points(piece, pos, rot):
		var d: float = sdf.call(cp[0])
		var limit := BOTTOM_SINK_OK if (cp[1] and sinks) else ROCK_SINK_OK
		if d < -limit:
			return "Inside rock"
	return ""


## Does this piece touch rock (and so is 100% steady)?
static func touches_rock(piece: String, pos: Vector3, rot: int, sdf: Callable) -> bool:
	var b := box(piece, pos, rot)
	var mid := b.get_center()
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var f := mid
			f[axis] += sgn * (b.size[axis] * 0.5 + 0.5)
			if sdf.call(f) < 0.0:
				return true
	# Corners of the bottom face (uneven floors). AABB endpoints 0, 1, 4, 5 are the bottom ones.
	# The cave is made of 1 m voxels, so look up to 0.75 m down.
	for i in [0, 1, 4, 5]:
		var c := b.get_endpoint(i)
		if sdf.call(c + Vector3.DOWN * 0.75) < 0.0:
			return true
	return false
