class_name MapData
extends RefCounted
## The explored map: one parchment page per "floor" (20 m of height), 1 pixel = 1 meter.
## As you walk around, the area around you gets drawn in: open cave = light parchment,
## rock = darker. ▲/▼ marks show where you climbed to another floor.
## shortcut: each player keeps their own map; the doc's "shared co-op map" comes with saving (Step 7).

const FLOOR_HEIGHT := 20.0
const REVEAL_RADIUS := 13
const STEP := 2  ## sample every 2 m (fast enough to run twice a second)

const UNSEEN := Color(0, 0, 0, 0)
const OPEN := Color(0.86, 0.78, 0.6)
const ROCK := Color(0.45, 0.37, 0.28)

var size := int(CaveMaker.HALF_SIZE * 2)
var floors: Array[Image] = []
var markers: Array[Dictionary] = []  ## {pos: Vector3, up: bool}
var _last_floor := -1


func _init() -> void:
	for i in floor_count():
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(UNSEEN)
		floors.append(img)


static func floor_count() -> int:
	return ceili((CaveMaker.Y_MAX - CaveMaker.Y_MIN) / FLOOR_HEIGHT)


static func floor_of(y: float) -> int:
	return clampi(floori((y - CaveMaker.Y_MIN) / FLOOR_HEIGHT), 0, floor_count() - 1)


## Pixel for a world position.
func to_pixel(p: Vector3) -> Vector2i:
	return Vector2i(int(p.x + CaveMaker.HALF_SIZE), int(p.z + CaveMaker.HALF_SIZE))


## Draws in the area around `p`. `sdf` is a Callable(Vector3) -> float (negative = rock).
func reveal(p: Vector3, sdf: Callable) -> void:
	var f := floor_of(p.y)
	if _last_floor >= 0 and f != _last_floor:
		markers.append({pos = p, up = f > _last_floor, floor = _last_floor})
		markers.append({pos = p, up = f < _last_floor, floor = f, arrived = true})
	_last_floor = f
	var img := floors[f]
	var center := to_pixel(p)
	for dz in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1, STEP):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1, STEP):
			if dx * dx + dz * dz > REVEAL_RADIUS * REVEAL_RADIUS:
				continue
			var px := center + Vector2i(dx, dz)
			if px.x < 0 or px.y < 0 or px.x >= size - STEP or px.y >= size - STEP:
				continue
			# Open if there's air at the dwarf's height (± 2 m) at this spot.
			var w := Vector3(p.x + dx, p.y, p.z + dz)
			var open := false
			for h in [0.5, 2.0, -1.5]:
				if sdf.call(w + Vector3.UP * h) > 0.0:
					open = true
					break
			var col := OPEN if open else ROCK
			for oy in STEP:
				for ox in STEP:
					img.set_pixel(px.x + ox, px.y + oy, col)


func seen_fraction(f: int) -> float:
	var n := 0
	var img := floors[f]
	for y in range(0, size, 4):
		for x in range(0, size, 4):
			if img.get_pixel(x, y).a > 0.0:
				n += 1
	return n / float((size / 4) * (size / 4))
