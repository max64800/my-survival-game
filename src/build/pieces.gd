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
	"foundation": {name = "Foundation", group = "foundation", size = Vector3(2, 1, 2), units = 8, place = "cell", foundation = true,
		families = ["cut_stone", "clay_brick"], station = {"mason": 1}},
	"foundation_half": {name = "Half Foundation", group = "foundation", size = Vector3(2, 1, 1), units = 4, place = "cell", foundation = true,
		families = ["cut_stone", "clay_brick"], station = {"mason": 1}},
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
		opening = Vector3(1.0, 1.8, 0), station = ALL},
	"arch_doorway": {name = "Arched Doorway", group = "wall", size = Vector3(2, 2, 0.3), units = 4, place = "edge", shape = "arch_doorway",
		opening = Vector3(1.2, 1.9, 0), families = ["cut_stone", "clay_brick"], station = {"mason": 2}},
	"window_wall": {name = "Small Window", group = "wall", size = Vector3(2, 2, 0.3), units = 3, place = "edge",
		opening = Vector3(1.0, 0.8, 0.6), station = {"workbench": 2, "mason": 1, "anvil": 1}},
	"window_wide": {name = "Wide Window", group = "wall", size = Vector3(2, 2, 0.3), units = 3, place = "edge",
		opening = Vector3(1.6, 0.9, 0.6), station = {"workbench": 2, "mason": 2, "anvil": 1}},
	"gable_26": {name = "Gable (gentle)", group = "roof", size = Vector3(2, 1, 0.3), units = 2, place = "edge", shape = "gable", rise = 1.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"gable_45": {name = "Gable (steep)", group = "roof", size = Vector3(2, 2, 0.3), units = 3, place = "edge", shape = "gable", rise = 2.0,
		station = {"workbench": 2, "mason": 2, "anvil": 2}},
	"door": {name = "Door", group = "wall", size = Vector3(1, 1.8, 0.12), units = 2, place = "edge", shape = "door",
		families = ["plank_root", "plank_mushroom", "copper_ingot"], station = {"workbench": 1, "anvil": 1}},
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
		families = ["plank_root", "plank_mushroom", "copper_ingot", "silver_ingot"], station = {"workbench": 2, "anvil": 1}},
	"pillar": {name = "Pillar", group = "support", size = Vector3(0.4, 2, 0.4), units = 3, place = "corner", station = ALL},
	"column": {name = "Carved Column", group = "support", size = Vector3(0.8, 2, 0.8), units = 4, place = "corner", shape = "column",
		families = ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"], station = {"mason": 2}},
	"arch": {name = "Stone Arch", group = "support", size = Vector3(2, 1, 0.4), units = 3, place = "edge", shape = "arch",
		families = ["cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"], station = {"mason": 2}},
	# --- getting around
	"stairs": {name = "Stairs", group = "around", size = Vector3(2, 2, 2), units = 6, place = "cell", walkable_slope = true, station = ALL},
	"ladder": {name = "Ladder", group = "around", size = Vector3(1, 2, 0.2), units = 2, place = "edge", shape = "ladder",
		families = ["plank_root", "plank_mushroom", "copper_ingot"], station = {"workbench": 1, "anvil": 1}},
	"railing": {name = "Railing", group = "around", size = Vector3(2, 1, 0.15), units = 1, place = "edge", shape = "railing",
		families = ["plank_root", "plank_mushroom", "copper_ingot", "silver_ingot"], station = {"workbench": 1, "anvil": 1}},
	# --- triangles (owner's Conan Exiles idea; 45°): a triangle is half a 2×2 square, cut corner to
	# corner. Rot 0 keeps the half on the −x/+z side of the line (−1,−1)→(1,1); Q turns which corner
	# is cut. Diagonal pieces stand on that line (2.83 m long). Octagons and cut corners on our grid.
	"foundation_triangle": {name = "Triangle Foundation", group = "foundation", size = Vector3(2, 1, 2), units = 4, place = "cell",
		foundation = true, shape = "triangle", families = ["cut_stone", "clay_brick"], station = {"mason": 1}},
	"floor_triangle": {name = "Triangle Floor", group = "floor", size = Vector3(2, 0.25, 2), units = 2, place = "cell", shape = "triangle",
		station = {"workbench": 2, "mason": 1, "anvil": 1}},
	"wall_diagonal": {name = "Diagonal Wall", group = "wall", size = Vector3(2, 2, 2), units = 6, place = "cell", shape = "diagonal",
		families = ["plank_root", "plank_mushroom", "cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"],
		station = {"workbench": 2, "mason": 2}},
	"half_wall_diagonal": {name = "Diagonal Half Wall", group = "wall", size = Vector3(2, 1, 2), units = 3, place = "cell", shape = "diagonal",
		families = ["plank_root", "plank_mushroom", "cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"],
		station = {"workbench": 2, "mason": 2}},
	"window_diagonal": {name = "Diagonal Window", group = "wall", size = Vector3(2, 2, 2), units = 5, place = "cell", shape = "diagonal",
		opening = Vector3(1.0, 0.8, 0.6), families = ["plank_root", "plank_mushroom", "cut_stone", "cut_marble", "clay_brick", "basalt", "ancient_brick"],
		station = {"workbench": 3, "mason": 2}},
	"railing_diagonal": {name = "Diagonal Railing", group = "around", size = Vector3(2, 1, 2), units = 2, place = "cell", shape = "diagonal",
		families = ["plank_root", "plank_mushroom", "copper_ingot", "silver_ingot"], station = {"workbench": 2, "anvil": 1}},
	# --- mining
	"ceiling_panel": {name = "Ceiling Panel", group = "mining", size = Vector3(2, 0.25, 2), units = 4, place = "ceiling", supports_rock = true, station = ALL},
	"mine_prop": {name = "Mine Prop", group = "mining", size = Vector3(2, 3, 0.4), units = 4, place = "free", extra = {copper_ingot = 1}, supports_rock = true,
		families = ["plank_root", "cut_stone", "copper_ingot"], station = ALL},
}

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


static func allowed(piece: String, family: String) -> bool:
	return LIST.has(piece) and FAMILIES.has(family) and (not LIST[piece].has("families") or family in LIST[piece].families)


static func hp(piece: String, family: String) -> float:
	return FAMILIES[family].hp * LIST[piece].units / 4.0


## Size after turning by `rot` quarter turns (odd turns swap width and depth).
static func turned_size(piece: String, rot: int) -> Vector3:
	var s: Vector3 = LIST[piece].size
	return Vector3(s.z, s.y, s.x) if rot % 2 == 1 else s


static func box(piece: String, pos: Vector3, rot: int) -> AABB:
	var s := turned_size(piece, rot)
	return AABB(pos - Vector3(s.x * 0.5, 0, s.z * 0.5), s)


## Where a piece goes when you aim at `p` (surface point) with surface normal `n`,
## facing `yaw`, turned `rot` extra quarter turns, lifted `lift` meters.
## `anchor` = the box of the built piece under the crosshair (empty AABB = aiming at rock):
##  - aiming at its TOP: the new piece stands on it. Walls go to its nearest edge, pillars to its
##    nearest corner, roofs/floors line up on the 1 m grid (so a wall never lands mid-floor).
##  - aiming at the SIDE of a floor/foundation with a floor/foundation: the new one goes right next to it.
##  - otherwise: the 1 m grid (2 m pieces + 1 m halves), heights in 0.5 m steps.
static func snap(piece: String, p: Vector3, n: Vector3, yaw: float, rot: int, lift: float = 0.0, anchor: AABB = AABB()) -> Dictionary:
	var info: Dictionary = LIST[piece]
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
