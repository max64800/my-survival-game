class_name RuinProwHall
extends RuinTower
## The Prow Hall (owner, Nov 22, F656 + F657 + F479): the ninth ruin, a Stonehold castle: a great hall with four round
## towers, a keep at its back, a pointed prow at its front, and a lone tower on a rock lump reached by a bridge, half
## fallen in. It is huge (52 x 40 m, 14.5 m tall), so it needs one of the biggest Mossy caverns, about 280 m from the
## start. Its plan is blueprints/ruins/prow_hall_ruin.json (tools/ruins/make_prow_hall_ruin.py). Works like the Hearth
## Manor (ruin_manor.gd): the world remembers "prow_hall: pending" and builds it the first time someone comes close.
## Built INTO the cave (F657, docs/design/GRAND-RUIN-RECIPE.md "Built into the cave"): before its pieces go in, the
## world digs only the space round the castle (the blueprint's own "air" cells, a yard in front, the way under the
## bridge and a dip below it) and grows rock where the 3D page shows it: the lump under the lone tower (flat on top at
## 7 m) and a rough rock wall wrapped round the keep's back. Rebuilt in cut stone or wood; rock beetles guard it.

const PLAN_PATH := "res://blueprints/ruins/prow_hall_ruin.json"
const BLUEPRINT := "stonehold_prow_hall"
const WANT_DIST := 280.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 30.0        ## its far corners (the lone tower's back, the prow's point) are about 29 m from the middle
const HEIGHT := 16.0
const TRIES := 5
## Its ground, in its own frame: the whole castle and the lone tower (x -26..26, z -20..19), the yard in front to z 21.
const LO := Vector2(-26.0, -20.0)
const HI := Vector2(26.0, 21.0)
const FILL_R := 1.6        ## the balls of rock the lump and the wall are grown from
const FILL_STEP := 1.8
const FILLS_PER_FRAME := 20
const WALL_TOP := 20.0     ## the rock wall never grows higher than this
const KEEP_GAP := 9.4      ## and stays this far from the keep's middle (its corners are 7.7 m out)
static var built_origin := Vector3.INF
static var built_turn := 0

var room := -1
var _check := 0.0
var _fill: Array = []
var _grown := 0


## Its caverns, best first: Mossy's plain big caverns (not the start's, nor another ruin's), the widest first, each lot
## nearest 280 m from the start. Only the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [RuinOutpost.pick_room(maker), RuinBrewhall.pick_room(maker), int(maker.spire_spot.get("room", -1)),
		int(maker.manor_spot.get("room", -1))]
	var found: Array = []
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if i in taken or not rm.big or rm.get("biome", "mossy") != "mossy" or rm.get("kind", "") not in ["cavern", "ruin", "nest_cavern"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d < 80.0:
			continue
		var r: Vector3 = rm.radii
		var wide := maxf(r.x, r.z)
		found.append([0 if wide >= 20.0 else (1 if wide >= 16.0 else 2), absf(d - WANT_DIST), i])
	found.sort()
	var out: Array[int] = []
	for f in found:
		out.append(int(f[2]))
	return out


static var _ground: Array = []
static var _clear := PackedFloat32Array()  ## how far each 1 m cell of its frame is from its ground (see clear_at)
const CLEAR_X := 40   ## that map covers x -40..40, z -36..36
const CLEAR_Z := 36


## Its ground in its own frame, every 2 m: under every piece (the bridge too, and the dip under it), the yard in front
## of the prow and the rock lump. Not the empty corners of its box, nor the rock wall it grows (a column may stand in
## that rock). [Vector2, ...]; `main` = also under the main body (not the lone tower's side), for how flat it is.
static func ground() -> Array:
	if _ground.is_empty():
		var cells := {}
		for p in BlueprintLibrary.make(BLUEPRINT).pieces:
			if p.pos.y < 10.5:
				cells[Vector2i(roundi(p.pos.x / 2.0), roundi(p.pos.z / 2.0))] = true
		for x in range(0, 9):
			for z in range(5, 11):
				cells[Vector2i(x, z)] = true  # the yard (x 0..16, z 10..20)
		var l := BlueprintLibrary.PROW_LUMP
		for x in range(-15, -5):
			for z in range(-11, 0):
				if Vector2(x * 2.0 - l.x, z * 2.0 - l.z).length() < 9.0:
					cells[Vector2i(x, z)] = true
		for c in cells:
			_ground.append(Vector2(c.x * 2.0, c.y * 2.0))
		_ground.sort()
	return _ground


## How far (m) the point (x, z) of its own frame is from its ground (a quick map, made once; 99 off the map).
static func clear_at(x: float, z: float) -> float:
	var w := CLEAR_X * 2 + 1
	var h := CLEAR_Z * 2 + 1
	if _clear.is_empty():
		_clear.resize(w * h)
		_clear.fill(999.0)
		for g: Vector2 in ground():
			_clear[(roundi(g.y) + CLEAR_Z) * w + roundi(g.x) + CLEAR_X] = 0.0
		var d2 := sqrt(2.0)
		for pass_i in 2:  # (two sweeps: a quick distance map)
			var zs: Array = range(h) if pass_i == 0 else range(h - 1, -1, -1)
			var xs: Array = range(w) if pass_i == 0 else range(w - 1, -1, -1)
			var s: int = 1 if pass_i == 0 else -1
			for zi in zs:
				for xi in xs:
					var i: int = zi * w + xi
					var best := _clear[i]
					for o in [[-s, 0, 1.0], [0, -s, 1.0], [-s, -s, d2], [s, -s, d2]]:
						var nx: int = xi + int(o[0])
						var nz: int = zi + int(o[1])
						if nx >= 0 and nx < w and nz >= 0 and nz < h:
							best = minf(best, _clear[nz * w + nx] + float(o[2]))
					_clear[i] = best
	var cx := roundi(x)
	var cz := roundi(z)
	if absi(cx) > CLEAR_X or absi(cz) > CLEAR_Z:
		return 99.0
	return _clear[(cz + CLEAR_Z) * w + cx + CLEAR_X]


## The spot (in the first few caverns) with the flattest floor under its main body, no column or other ruin on any
## of its ground, the least rock in the way; its prow turned toward the way you come from if it fits that way (else
## another way). Returns {room, pos, turn}.
static func pick(maker: CaveMaker) -> Dictionary:
	var c0 := maker.cavern_spawn
	var best := {}
	var best_score := INF
	var pts := ground()
	for best_room in rooms_to_try(maker).slice(0, TRIES):
		var rc: Vector3 = maker.rooms[best_room].center
		var cols := []  # (only the columns near this cavern: quick)
		for o in maker._cols:
			if Vector2(o.x - rc.x, o.y - rc.z).length() < 80.0:
				cols.append(o)
		for gx in range(-4, 5):
			for gz in range(-4, 5):
				var p := rc + Vector3(gx * 4.0, 0, gz * 4.0)
				var to: Vector3 = c0 - p  # the prow (local +z) faces the way you come from, if it can
				var facing := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
				var mid := maker.find_floor(p.x, p.z, rc.y)
				for k in 4:
					var turn := posmod(facing + [0, 1, 3, 2][k], 4)
					var basis := Basis(Vector3.UP, turn * PI / 2.0)
					var ok := true
					var inv := basis.inverse()
					for o in cols:
						var l: Vector3 = inv * (Vector3(o.x, 0, o.y) - Vector3(p.x, 0, p.z))
						if clear_at(l.x, l.z) - 0.75 < o.z * 1.4 + 1.5:
							ok = false  # a stone column would stand in it (the placement rule)
							break
					if not ok:
						continue
					var ys := []
					var lo := INF
					var hi := -INF
					for i in range(0, pts.size(), 4):
						var g: Vector2 = pts[i]
						var w: Vector3 = p + basis * Vector3(g.x, 0, g.y)
						if maker.is_reserved(Vector3(w.x, mid.y + 0.3, w.z), 2.0):
							ok = false  # another ruin's (or a dungeon's) ground
							break
						var q := Vector3(w.x, mid.y + 4.0, w.z)  # (its floor, looked for only 3 m below the middle's: quick)
						while q.y > mid.y - 3.25 and maker.sdf_at(q) > 0.0:
							q.y -= 0.75
						if q.y > mid.y - 3.25:
							while maker.sdf_at(q + Vector3(0, 0.25, 0)) <= 0.0 and q.y < mid.y + 4.0:
								q.y += 0.25  # (back up to the floor's top, 0.25 m at a time)
						var on_lump := Vector2(g.x - BlueprintLibrary.PROW_LUMP.x, g.y - BlueprintLibrary.PROW_LUMP.z).length() < 9.0
						if q.y < mid.y - 3.0 and not on_lump:
							ok = false  # a drop or a chasm under it (the lump is grown from the floor, whatever its depth)
							break
						if g.x > -11.0:
							ys.append(q.y)  # (the main body)
							lo = minf(lo, q.y)
							hi = maxf(hi, q.y)
							if (hi - lo) * 4.0 + [0, 5, 5, 10][k] >= best_score:
								ok = false  # already worse than the best spot so far (quick)
								break
					if not ok:
						continue
					ys.sort()
					var base: float = ys[0] - 0.05
					var rock := 0
					for h in [2.0, 6.0, 10.0, HEIGHT]:
						for sx in 6:
							for sz in 5:
								var o: Vector3 = basis * Vector3(lerpf(-22.0, 22.0, sx / 5.0), h, lerpf(-14.0, 18.0, sz / 4.0))
								if maker.sdf_at(Vector3(p.x, base, p.z) + o) < 0.0:
									rock += 1
					var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 1.0 + Vector2(gx, gz).length() * 0.3 + [0, 5, 5, 10][k]
					if score < best_score:
						best_score = score
						best = {room = best_room, pos = Vector3(p.x, base, p.z), turn = turn}
	return best


# ---------------------------------------------------------------- the cave's shape (the same as its 3D page)
static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _hash(x: float, z: float) -> float:
	var h := sin(x * 127.1 + z * 311.7) * 43758.5453
	return h - floorf(h)


static func _vnoise(x: float, z: float) -> float:
	var xi := floorf(x)
	var zi := floorf(z)
	var fx := _smooth(x - xi)
	var fz := _smooth(z - zi)
	var a := _hash(xi, zi)
	var b := _hash(xi + 1, zi)
	var c := _hash(xi, zi + 1)
	var d := _hash(xi + 1, zi + 1)
	return a + (b - a) * fx + (c - a) * fz + (a - b - c + d) * fx * fz


static func _fbm(x: float, z: float) -> float:
	return _vnoise(x, z) * 0.5 + _vnoise(x * 2 + 5.2, z * 2 + 1.3) * 0.3 + _vnoise(x * 4 + 9.1, z * 4 + 3.7) * 0.2


## Flat shelves every `step` m with short steep faces between them.
static func _ledges(h: float, step: float) -> float:
	var k := h / step
	var f := k - floorf(k)
	return (floorf(k) + _smooth((f - 0.3) / 0.7)) * step


static func _d8() -> Vector2:
	return Vector2(-sqrt(3.0) / 2.0, -0.5)


## Where the bridge starts (the back-left tower's side) in its own frame.
static func _b0() -> Vector2:
	return Vector2(-5.732, -3.0) + _d8() * 3.732


## How far along the bridge, and how far to its side.
static func _bridge(x: float, z: float) -> Vector2:
	var d := _d8()
	var b := _b0()
	return Vector2((x - b.x) * d.x + (z - b.y) * d.y, absf((x - b.x) * -d.y + (z - b.y) * d.x))


## The dip under the bridge: how deep the floor goes (0 elsewhere, -3 at its deepest).
static func dip_at(x: float, z: float) -> float:
	var t := _bridge(x, z)
	return -3.0 * _smooth(minf(t.x - 0.5, 9.0 - t.x) / 2.0) * _smooth(1.0 - t.y / 4.5)


## The rock lump under the lone tower: its height (7 m flat on top where the tower stands, a rough ledged side).
static func lump_at(x: float, z: float) -> float:
	var l := BlueprintLibrary.PROW_LUMP
	var r := Vector2(x - l.x, z - l.z).length() - 1.4 * _fbm(x * 0.35 + 7, z * 0.35)
	if Vector2(x - l.x, z - l.z).length() <= BlueprintLibrary.PROW_LUMP_R or r <= 5.5:
		return l.y
	var u := l.y * (1.0 - _smooth((r - 5.5) / 3.2))
	return _ledges(u, 3.5) + ((_fbm(x * 0.8, z * 0.8) - 0.5) * 0.5 if u > 0.2 else 0.0)


## The rock wall wrapped round the keep's back: its height (0 where there is none). The noise only pulls it back.
static func wall_at(x: float, z: float) -> float:
	var k := BlueprintLibrary.PROW_KEEP
	var s := minf(minf(k.z - z, x + 6.0), Vector2(x - k.x, z - k.z).length() - KEEP_GAP) - 1.8 * _fbm(x * 0.12, z * 0.12)
	if s <= 0.0:
		return 0.0
	var h := 16.0 + 7.0 * _fbm(x * 0.05 + 3, z * 0.05) + 7.0 * _fbm(x * 0.16 + 1, z * 0.16 + 4)
	var w := _ledges(h * _smooth(s / 4.0), 4.5) + (_fbm(x * 0.45, z * 0.45) - 0.5) * 2.6 * _smooth(s / 2.0)
	return minf(w, WALL_TOP)


## The rock the world grows round it, at (x, z) in its own frame (0 = none).
static func rock_at(x: float, z: float) -> float:
	return maxf(lump_at(x, z), wall_at(x, z))


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinProwHall"
	drop_rubble = false   # (its rubble lies where the plan says: on floors, the ground line, down in the dip)
	stone_key = "stonehold_prow_hall"
	wood_key = "wooden_prow_hall"
	ruin_name = "prow_hall"
	hard_mat = "cut_stone"
	reach = REACH


## The Rebuilding Chest stands in front, beside the prow (x 4..12) and its doorway steps (x 3 and 13).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(0.0, 13.0), Vector2(16.0, 13.0), Vector2(0.0, 15.0), Vector2(16.0, 15.0), Vector2(-1.0, 11.0), Vector2(17.0, 11.0)]


func _path_z(_rad: float) -> float:
	return 20.0


func _ready() -> void:
	var st: String = auth.world_state.get("prow_hall", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Prow Hall
		return
	var spot: Dictionary = auth.world.maker.prow_hall_spot
	if spot.is_empty():
		spot = pick(auth.world.maker)
	if spot.is_empty():
		push_warning("RuinProwHall: no cavern for the Prow Hall")
		queue_free()
		return
	room = spot.room
	auth.world.maker.rooms[room].kind = "ruin"  # rock beetles guard it (every run, also after it's built)
	origin = spot.pos
	turn = spot.turn
	if st != "pending":
		built_origin = origin
		built_turn = turn
		set_process(false)
		return
	_carve = carve_points(origin, turn)


## What it digs (ordinary digs: saved and sent to friends), in world space: the blueprint's own air cells (only round
## the castle; never down into the rock lump or below its ground line), the yard in front, the way under the bridge,
## and the dip below it.
static func carve_points(at: Vector3, trn: int) -> Array:
	var basis := Basis(Vector3.UP, trn * PI / 2.0)
	var out := []
	var bp := BlueprintLibrary.make(BLUEPRINT)
	var sx := int(bp.size.x)
	var sz := int(bp.size.z)
	var i := 0
	for cy in int(bp.size.y):
		for cz in sz:
			for cx in sx:
				if bp.air[i] == 1:
					var c := Vector3(cx + 0.5 - sx * 0.5, cy + 0.5, cz + 0.5 - sz * 0.5)
					if c.y >= 0.9 and c.y - CARVE_RADIUS >= rock_at(c.x, c.z) - 0.3:
						out.append(at + basis * c)
				i += 1
	var y := 1.5
	while y <= 4.5:  # the yard in front of the prow
		for x in range(-1, 18):
			for z in range(6, 22):
				out.append(at + basis * Vector3(x, y, z))
		y += 1.2
	var d := _d8()
	var side := Vector2(-d.y, d.x)
	var b := _b0()
	var t := -1.0
	while t <= 14.0:  # under the bridge (down to the dip), never into the lump
		var s := -3.0
		while s <= 3.0:
			var xz := b + d * t + side * s
			var h := dip_at(xz.x, xz.y)
			y = (h + 1.0) if h < -0.3 else 1.5
			while y <= 9.0:
				if y - CARVE_RADIUS >= lump_at(xz.x, xz.y) - 0.3:  # (the lump wins over the dip, like on the page)
					out.append(at + basis * Vector3(xz.x, y, xz.y))
				y += 1.2
			s += 1.2
		t += 1.2
	return out


## Where it grows rock (after the digging): the lump and the wall, balls of rock from the top of each column down to
## the rock that's already there. Only where the cave is open (no ball is wasted inside solid rock).
func _fill_points() -> Array:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var out := []
	var x := LO.x - 6.0
	while x <= HI.x + 4.0:
		var z := LO.y - 6.0
		while z <= 0.0:
			var h := rock_at(x, z)
			if h > 0.8:
				var y := h - FILL_R
				var started := false
				while y >= -4.0:
					var w: Vector3 = origin + basis * Vector3(x, y, z)
					var solid: bool = auth.world.sdf_at(w) < -0.5
					if solid and started:
						break  # down to the cave's floor
					if not solid:
						started = true
						out.append(w)
					y -= FILL_STEP
			z += FILL_STEP
		x += FILL_STEP
	return out


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = REACH + 4.0
		var box := AABB(origin + Vector3(-half, -4.0, -half), Vector3(half * 2.0, WALL_TOP + 6.0, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			_state = "carve"
		return
	if _state == "build" and _fill.is_empty() and not has_meta("filled"):
		_fill = _fill_points()
		set_meta("filled", true)
		print("RUIN_PROW_HALL growing its rock: %d balls" % _fill.size())
		_state = "fill"
	if _state == "fill":
		var n := 0
		while not _fill.is_empty() and n < FILLS_PER_FRAME:
			_grown += 1 if auth.host_fill(_fill.pop_back(), FILL_R, Mat.STONE) > 0 else 0
			n += 1
		if _fill.is_empty():
			_state = "build"
		return
	if _state == "build":
		_build()
		auth.world_state["prow_hall"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_PROW_HALL built at %s (turn %d), %d balls of rock grown" % [origin, turn, _grown])
		_state = "done"
		set_process(false)
		return
	super(delta)
