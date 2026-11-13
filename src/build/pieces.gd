class_name Pieces
## The building catalog (world doc section 5). Every piece comes in every material family.
## size = width (x) × height (y) × depth (z) in meters, before turning. Origin = bottom centre.
## place = how it snaps to the 2 m grid: "cell" (cell centre), "edge" (cell edge), "corner",
##         "free" (0.5 m steps), "ceiling" (hangs up against the rock ceiling).

const GRID := 2.0

const LIST := {
	"floor": {name = "Floor", size = Vector3(2, 0.25, 2), units = 4, place = "cell"},
	"small_floor": {name = "Small Floor", size = Vector3(1, 0.25, 1), units = 1, place = "free"},
	"wall": {name = "Wall", size = Vector3(2, 2, 0.3), units = 4, place = "edge"},
	"half_wall": {name = "Half Wall", size = Vector3(2, 1, 0.3), units = 2, place = "edge"},
	"doorway": {name = "Doorway", size = Vector3(2, 2, 0.3), units = 4, place = "edge", extra = {copper_ingot = 2}, opening = Vector3(1.0, 1.8, 0)},
	"window_wall": {name = "Window Wall", size = Vector3(2, 2, 0.3), units = 3, place = "edge", opening = Vector3(1.0, 0.8, 0.6)},
	"beam": {name = "Beam", size = Vector3(2, 0.3, 0.3), units = 2, place = "edge"},
	"pillar": {name = "Pillar", size = Vector3(0.4, 2, 0.4), units = 3, place = "corner"},
	"stairs": {name = "Stairs", size = Vector3(2, 2, 2), units = 6, place = "cell", walkable_slope = true},
	"ceiling_panel": {name = "Ceiling Panel", size = Vector3(2, 0.25, 2), units = 4, place = "ceiling", supports_rock = true},
	"mine_prop": {name = "Mine Prop", size = Vector3(2, 3, 0.4), units = 4, place = "free", extra = {copper_ingot = 1}, supports_rock = true,
		families = ["plank_root", "cut_stone", "copper_ingot"]},
}

## Material families (world doc 5.3 + 5.6). hp = for a 2×2 wall (4 units). up/side = stability lost per piece.
const FAMILIES := {
	"plank_root": {name = "Rootwood", hp = 200, up = 0.10, side = 0.20, color = Color(0.62, 0.45, 0.28), damage = 1.0},
	"plank_mushroom": {name = "Capwood", hp = 260, up = 0.10, side = 0.20, color = Color(0.82, 0.74, 0.6), damage = 0.9},
	"mushroom_brick": {name = "Mushroom Brick", hp = 300, up = 0.08, side = 0.25, color = Color(0.8, 0.7, 0.6), damage = 0.8},
	"cut_stone": {name = "Cut Stone", hp = 500, up = 0.05, side = 0.30, color = Color(0.6, 0.58, 0.55), damage = 0.6},
	"cut_marble": {name = "Marble", hp = 600, up = 0.05, side = 0.30, color = Color(0.92, 0.92, 0.9), damage = 0.55},
	"clay_brick": {name = "Clay Brick", hp = 500, up = 0.05, side = 0.30, color = Color(0.78, 0.42, 0.25), damage = 0.6},
	"basalt": {name = "Basalt", hp = 550, up = 0.05, side = 0.30, color = Color(0.22, 0.22, 0.25), damage = 0.6},
	"brown_rock": {name = "Brown Rock", hp = 450, up = 0.05, side = 0.30, color = Color(0.45, 0.33, 0.24), damage = 0.6},
	"copper_ingot": {name = "Copper", hp = 800, up = 0.04, side = 0.12, color = Color(0.85, 0.5, 0.28), damage = 0.4},
	"crystal_blue": {name = "Crystal", hp = 150, up = 0.15, side = 0.40, color = Color(0.45, 0.75, 1.0), damage = 1.2, glow = true},
}

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
static func snap(piece: String, p: Vector3, n: Vector3, yaw: float, rot: int, lift: float = 0.0) -> Dictionary:
	var info: Dictionary = LIST[piece]
	var q := (posmod(roundi(yaw / (PI / 2.0)), 4) + rot) % 4
	var cx := floorf(p.x / GRID) * GRID + GRID * 0.5
	var cz := floorf(p.z / GRID) * GRID + GRID * 0.5
	var h: float = info.size.y
	var y := snappedf(p.y, 0.5) if n.y > 0.5 else snappedf(p.y - h * 0.5, 0.5)
	var pos := Vector3(cx, y, cz)
	match info.place:
		"edge":
			# Spans X when q is even (sits on a north/south edge), spans Z when odd.
			if q % 2 == 0:
				pos.z = cz + signf(p.z - cz + 0.0001) * GRID * 0.5
			else:
				pos.x = cx + signf(p.x - cx + 0.0001) * GRID * 0.5
		"corner":
			pos.x = cx + signf(p.x - cx + 0.0001) * GRID * 0.5
			pos.z = cz + signf(p.z - cz + 0.0001) * GRID * 0.5
		"free":
			pos.x = snappedf(p.x, 0.5)
			pos.z = snappedf(p.z, 0.5)
		"ceiling":
			pos.y = snappedf(p.y, 0.5) - h if n.y < -0.5 else snappedf(p.y, 0.5)
	pos.y += lift
	return {pos = pos, rot = q}


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
