class_name RuinCliffGalleries
extends RuinTower
## The Cliff Galleries (owner, Nov 26, F913): the thirteenth ruin, dwarf homes up a tall cave wall, stone below and
## brick above: the Stone Hall in the cliff's foot, a bridge over a crack to the Ledge House, brick stairs up the
## cliff, the Hanging Gallery (its middle fallen onto the hall's roof), and the Watch Tower on a high rock shelf with
## the best chest in its lookout. Its plan is blueprints/ruins/cliff_galleries_ruin.json
## (tools/ruins/make_cliff_galleries_ruin.py: the owner-approved 3D page's breakage, made sound for the game). Works
## like the Mine-head Works (ruin_minehead.gd): the world remembers "cliff_galleries: pending" and builds it the first
## time someone comes close. Built into a natural cave (F657): it finds a tall cavern whose own rock makes the cliff
## behind it, the shelf (10.75 m up) and the ledge (4.5 m up), and picks the spot where the least has to change. Its
## box: the crack's floor is near the box's floor and the cave floor is 5 m up it (BlueprintLibrary.CG_SHIFT). It digs
## the blueprint's own air cells, the yard in front and the crack (ramping out in front). Where the cave's own rock is
## missing under the shelf or the ledge (so the tower would stand on air), it fills just those holes with rock first,
## as saved rock edits (like Brickcrown's rock lump). Rebuilt as itself (one blueprint).

const PLAN_PATH := "res://blueprints/ruins/cliff_galleries_ruin.json"
const BLUEPRINT := "cliff_galleries"
const WANT_DIST := 320.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 27.0        ## its box's corners (the shelf's and the ledge's backs) are about 26.8 m from the middle
const HEIGHT := 24.0       ## the lookout's roof tip is about 22.5 m over the cave floor
const TRIES := 10
const FUNGAL_TRIES := 3
const FUNGAL_COST := 1000.0  ## a Fungal cavern's spot counts this much worse: any Mossy spot that fits wins
const G := 5.0             ## the cave floor in its box (BlueprintLibrary.CG_SHIFT.y)
const FILL_R := 1.6        ## the balls of rock its missing shelf and ledge rock is filled with
const FILL_STEP := 1.8     ## (on this grid: the balls overlap, no gaps)
const FILLS_PER_FRAME := 20
static var built_origin := Vector3.INF
static var built_turn := 0

var room := -1
var _check := 0.0
var _fill: Array = []


## Its caverns, best first: Mossy's big caverns (not the start's, nor another grand ruin's), the tallest first (its
## tower stands 22.5 m over the floor), then the widest (it is 48 m long), each lot nearest 320 m from the start; then
## the Fungal zone's the same way (only if no Mossy one fits, see FUNGAL_COST). Only the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [int(maker.manor_spot.get("room", -1)), int(maker.prow_hall_spot.get("room", -1)),
		int(maker.twin_gate_spot.get("room", -1)), int(maker.smeltery_spot.get("room", -1)),
		int(maker.brickcrown_spot.get("room", -1)), int(maker.minehead_spot.get("room", -1))]
	var found: Array = []
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		var biome: String = rm.get("biome", "mossy")
		if i in taken or not rm.big or biome not in ["mossy", "fungal"] or rm.get("kind", "") not in ["cavern", "ruin", "nest_cavern"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d < 80.0:
			continue
		var r: Vector3 = rm.radii
		var tall := 0 if r.y >= 13.0 else (1 if r.y >= 11.0 else 2)
		var wide := 0 if maxf(r.x, r.z) >= 24.0 else (1 if maxf(r.x, r.z) >= 20.0 else 2)
		found.append([0 if biome == "mossy" else 1, tall, wide, absf(d - WANT_DIST), i])
	found.sort()
	var out: Array[int] = []
	var fungal := 0
	for f in found:
		if int(f[0]) == 1:
			fungal += 1
			if fungal > FUNGAL_TRIES:
				break  # (a few Fungal ones are plenty: each costs a second or two to look over)
		out.append(int(f[4]))
	return out


# ---------------------------------------------------------------- its own frame (box metres; keep in step with make_cliff_galleries_ruin.py)
static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Box metres -> the blueprint's local metres (x, z).
static func _lx(x: float) -> float:
	return x - BlueprintLibrary.CG_SHIFT.x


static func _lz(z: float) -> float:
	return z - BlueprintLibrary.CG_SHIFT.z


## Where the cave's own rock is meant to be: the cliff behind it (its niches are dug with the blueprint's air).
static func in_rock_zone(x: float, z: float) -> bool:
	return _lz(z) < -11.2


## How high its ground stands at (x, z) of its box over the cave floor: the shelf 10.75, the ledge 4.5, the crack
## -4.75 (ramping back up to the cave floor in front, local z 0..7, so you can walk out of it), else 0.
static func rise_at(x: float, z: float) -> float:
	if in_rock_zone(x, z):
		return 0.0
	var lz := _lz(z)
	var h := BlueprintLibrary._cliff_ground(_lx(x), lz)
	if h < 0.0 and lz > 0.0:
		h = lerpf(h, 0.0, _smooth(lz / 7.0))
	return h


## The ground in its box at (x, z).
static func ground_at(x: float, z: float) -> float:
	return G + rise_at(x, z)


## Is (x, z) of its box in the crack (dug down)?
static func in_crack(x: float, z: float) -> bool:
	return rise_at(x, z) < -0.3


## The dug yard in front of the grand stair and the shed (local x -21..6, z 6..12) and the crack's dug part.
const YARD_X := Vector2(-23.0, 4.0)
const YARD_Z := Vector2(11.0, 17.0)

static var _ground: Array = []
static var _tops := {}   ## Vector2i 2 m cell -> how high its pieces reach there over its own ground (m)
static var _clear := PackedFloat32Array()  ## how far each 1 m cell of its frame is from its ground (see clear_at)
const CLEAR_X := 36   ## that map covers x -36..36, z -32..32
const CLEAR_Z := 32


## Its ground in its own frame, every 2 m: under every piece, the shelf's and the ledge's tops, the crack and its ramp
## out, and the yard in front. [Vector2, ...]
static func ground() -> Array:
	if _ground.is_empty():
		var cells := {}
		for p in BlueprintLibrary.make(BLUEPRINT).pieces:
			var c := Vector2i(roundi(p.pos.x / 2.0), roundi(p.pos.z / 2.0))
			cells[c] = true
			_tops[c] = maxf(float(_tops.get(c, 0.0)), p.pos.y - ground_at(c.x * 2.0, c.y * 2.0) + 2.25)
		for x in range(-12, 13):
			for z in range(-6, 9):
				var bx := x * 2.0
				var bz := z * 2.0
				if in_rock_zone(bx, bz):
					continue
				if rise_at(bx, bz) > 1.0 or in_crack(bx, bz):
					cells[Vector2i(x, z)] = true  # the shelf, the ledge, the crack and its ramp
				if bx >= YARD_X.x and bx <= YARD_X.y and bz >= YARD_Z.x - 1.0 and bz <= YARD_Z.y:
					cells[Vector2i(x, z)] = true  # the yard
		for c in cells:
			_ground.append(Vector2(c.x * 2.0, c.y * 2.0))
		_ground.sort()
	return _ground


## How high its pieces reach over the 2 m cell at (x, z) of its own frame (0 = only ground there).
static func top_at(x: float, z: float) -> float:
	ground()
	return float(_tops.get(Vector2i(roundi(x / 2.0), roundi(z / 2.0)), 0.0))


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


## Where the cave's own rock should be ([local x, y over the cave floor, local z]): the tall cliff behind it (beside
## and behind its three niches, up to 22 m), the shelf's body under the tower, the ledge's body under the Ledge House,
## the crack's walls and floor and the floor under the hall and the shed.
const CLIFF := [
	[-21.0, 3.0, -12.5], [-21.0, 9.0, -12.5], [-21.0, 15.0, -12.5], [-21.0, 21.0, -12.5],
	[-7.0, 3.0, -12.5], [-7.0, 9.0, -12.5], [-7.0, 15.0, -12.5], [-7.0, 21.0, -12.5],
	[8.0, 3.0, -12.5], [8.0, 9.0, -12.5], [8.0, 15.0, -12.5], [8.0, 21.0, -12.5],
	[24.0, 3.0, -12.5], [24.0, 9.0, -12.5], [24.0, 15.0, -12.5],
	[0.0, 9.0, -12.5], [0.0, 15.0, -12.5], [0.0, 3.0, -16.5], [16.0, 12.0, -12.5], [16.0, 6.0, -16.5],
	[-13.0, 20.0, -12.5], [-13.0, 13.0, -14.5],
]
const SHELF := [
	[-20.0, 2.0, -9.0], [-15.0, 2.0, -9.0], [-10.0, 2.0, -9.0], [-20.0, 2.0, -4.0], [-15.0, 2.0, -4.0], [-10.0, 2.0, -4.0],
	[-20.0, 5.5, -9.0], [-15.0, 5.5, -9.0], [-10.0, 5.5, -9.0], [-20.0, 5.5, -4.0], [-15.0, 5.5, -4.0], [-10.0, 5.5, -4.0],
	[-20.0, 9.0, -9.0], [-15.0, 9.0, -9.0], [-10.0, 9.0, -9.0], [-20.0, 9.0, -4.0], [-15.0, 9.0, -4.0], [-10.0, 9.0, -4.0],
	[-13.0, 9.5, -12.2],
]
const LEDGE := [
	[14.0, 1.5, -9.0], [18.0, 1.5, -9.0], [22.0, 1.5, -9.0], [14.0, 1.5, -4.0], [18.0, 1.5, -4.0], [22.0, 1.5, -4.0],
	[14.0, 3.5, -9.0], [18.0, 3.5, -9.0], [22.0, 3.5, -9.0], [14.0, 3.5, -4.0], [18.0, 3.5, -4.0], [22.0, 3.5, -4.0],
	[16.0, 3.5, -12.5],
]
const UNDER := [
	[9.0, -6.5, -7.0], [9.0, -6.5, -3.0], [9.0, -6.5, 0.0], [5.8, -2.5, -5.0], [5.8, -2.5, 0.0], [12.2, -2.5, 0.5],
	[-2.0, -1.5, -6.0], [0.0, -1.5, 1.0], [-16.0, -1.5, 1.5], [18.0, -1.5, 2.0],
]
const BACK_MISS := 3.0   ## how much each rock sample that's open air counts against a spot (it would be filled)
const FRONT_COST := 8.0  ## and a way in that has to be dug out


static func _samples() -> Array:
	return CLIFF + SHELF + LEDGE + UNDER


## A rock sample -> where it is from its ground line under its middle (box x, y over the cave floor, box z).
static func _off(s: Array) -> Vector3:
	return Vector3(float(s[0]) + BlueprintLibrary.CG_SHIFT.x, float(s[1]), float(s[2]) + BlueprintLibrary.CG_SHIFT.z)


## How many of the rock samples are rock at this spot (p: its ground line under its middle).
static func back_rock(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var n := 0
	for s in _samples():
		if maker.sdf_at(p + basis * _off(s)) < 0.0:
			n += 1
	return n


## The way in: in front of the grand stair and the shed's steps (the owner rule F350). The yard is dug out, so rock
## there only costs a little digging: 0 = open, level ground already; 1 = rock or a bump to dig out; 2 = a drop (no
## spot for it). p: its ground line under its middle.
static func front_state(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var st := 0
	for z in [13.0, 16.0, 19.0]:
		for x in [-20.0, -14.0, -8.0, -2.0, 3.0]:
			var at: Vector3 = p + basis * Vector3(x, 0, z)
			if maker.sdf_at(Vector3(at.x, p.y + 4.0, at.z)) <= 0.0:
				st = 1
				continue
			var f := maker.find_floor(at.x, at.z, p.y + 4.0).y
			if f < p.y - 1.5:
				return 2
			if f > p.y + 1.1:
				st = 1
	return st


## The spot (in the tallest caverns) with the flattest floor under its cave-floor parts, no column or other ruin on
## any of its ground, the cave's own rock where its cliff, shelf and ledge go (each miss would be filled), the least
## rock in the way of its pieces out in the open (up to each piece's own height), and the way in open; its front
## turned toward the way you come from if it fits that way. Besides a grid round the cavern's middle, it tries spots
## slid straight back until its back meets the cave wall (like the Mine-head). past_columns = its second try.
## Returns {room, pos (its ground line under its middle, the cave floor), turn}.
static func pick(maker: CaveMaker, past_columns := false) -> Dictionary:
	var c0 := maker.cavern_spawn
	var best := {}
	var best_score := [INF]
	var pts := ground()
	for best_room in rooms_to_try(maker).slice(0, TRIES):
		var rc: Vector3 = maker.rooms[best_room].center
		var fungal := FUNGAL_COST if maker.rooms[best_room].get("biome", "mossy") != "mossy" else 0.0
		if fungal > 0.0 and not best.is_empty() and best_score[0] < FUNGAL_COST:
			break  # (a Mossy spot fits: no need to look at the Fungal ones)
		var cols := []  # (only the columns near this cavern: quick)
		for o in maker._cols:
			if Vector2(o.x - rc.x, o.y - rc.z).length() < 90.0:
				cols.append(o)
		var tries := []  # [p, turn, how far from the middle (m)]: the ones slid back to the wall first
		for t in 4:  # slid back to the wall
			var basis := Basis(Vector3.UP, t * PI / 2.0)
			for lx in [-8.0, -4.0, 0.0, 4.0, 8.0]:
				var d := 0.0
				while d <= 44.0:
					var p: Vector3 = rc + basis * Vector3(lx, 0, -d)
					if maker.sdf_at(p + Vector3(0, 2.0, 0)) < 0.0:
						break  # (into the rock itself)
					var fy := maker.find_floor(p.x, p.z, rc.y + 4.0).y
					var n := 0
					for i in 15:  # (the cliff's first 15 samples: beside the niches)
						var s: Array = CLIFF[i]
						if maker.sdf_at(Vector3(p.x, fy, p.z) + basis * _off(s)) < 0.0:
							n += 1
					if n >= 9:  # its back meets the wall here
						tries.append([p, t, Vector2(lx, d).length() * 0.5])
						break
					d += 2.0
		for gx in range(-3, 4):  # (a grid round the middle, every 4 m)
			for gz in range(-3, 4):
				var p := rc + Vector3(gx * 4.0, 0, gz * 4.0)
				for t in 4:
					tries.append([p, t, Vector2(gx, gz).length() * 4.0])
		for tr in tries:
			var p: Vector3 = tr[0]
			var to: Vector3 = c0 - p  # its front (local +z) faces the way you come from, if it can
			var facing := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
			var pen: float = [0, 5, 10, 5][posmod(int(tr[1]) - facing, 4)] + float(tr[2]) * 0.075 + fungal
			var sc := _score(maker, p, int(tr[1]), pen, cols, pts, rc, past_columns, best_score[0])
			if sc < best_score[0]:
				best_score[0] = sc
				best = {room = best_room, pos = Vector3(p.x, _last_base, p.z), turn = int(tr[1])}
	return best


static var _last_base := 0.0  ## where its ground line goes at the spot _score last passed


## How bad a spot is (lower = better; INF = no good, or no better than `beat`).
static func _score(maker: CaveMaker, p: Vector3, turn: int, pen: float, cols: Array, pts: Array, rc: Vector3,
		past_columns: bool, beat: float) -> float:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var inv := basis.inverse()
	if not past_columns:  # (its second try: the columns in the way are taken out after, see columns_in)
		for o in cols:
			if _column_in(o, p, inv):
				return INF  # a stone column would stand in it (the placement rule)
	var mid := maker.find_floor(p.x, p.z, rc.y)
	var ys := []
	var lo := INF
	var hi := -INF
	for i in range(0, pts.size(), 3):
		var g: Vector2 = pts[i]
		var w: Vector3 = p + basis * Vector3(g.x, 0, g.y)
		if maker.is_reserved(Vector3(w.x, mid.y + 0.3, w.z), 2.0):
			return INF  # another ruin's (or a dungeon's) ground
		if absf(rise_at(g.x, g.y)) > 0.3:
			continue  # (the shelf, the ledge and the crack: looked at below)
		var q := Vector3(w.x, mid.y + 4.0, w.z)  # (its floor, looked for only 3 m below the middle's: quick)
		while q.y > mid.y - 3.25 and maker.sdf_at(q) > 0.0:
			q.y -= 0.75
		if q.y > mid.y - 3.25:
			while maker.sdf_at(q + Vector3(0, 0.25, 0)) <= 0.0 and q.y < mid.y + 4.0:
				q.y += 0.25  # (back up to the floor's top, 0.25 m at a time)
		if q.y < mid.y - 3.0:
			return INF  # a drop or a chasm under it
		ys.append(q.y)
		lo = minf(lo, q.y)
		hi = maxf(hi, q.y)
		if (hi - lo) * 4.0 + pen >= beat:
			return INF  # already worse than the best spot so far (quick)
	if ys.size() < 8:
		return INF
	ys.sort()
	var base: float = ys[0] - 0.05
	var at := Vector3(p.x, base, p.z)
	var score: float = (ys[-1] - ys[0]) * 4.0 + pen
	score += (_samples().size() - back_rock(maker, at, basis)) * BACK_MISS  # (cheap, so first: it often rules a
	if score >= beat:                                                        # spot out already)
		return INF
	for i in range(0, pts.size(), 2):  # rock in the way of its pieces out in the open, up to their own height
		var g: Vector2 = pts[i]
		var r0 := rise_at(g.x, g.y)
		var top := top_at(g.x, g.y)
		var h := r0 + 2.0
		while h <= r0 + top:
			if maker.sdf_at(at + basis * Vector3(g.x, h, g.y)) < 0.0:
				score += 1.0
			h += 4.0
		if score >= beat:
			return INF  # already worse than the best spot so far (quick)
	var front := front_state(maker, at, basis)
	if front == 2:
		return INF  # a drop in front of the grand stair
	score += front * FRONT_COST
	if score >= beat:
		return INF
	_last_base = base
	return score


static func _column_in(o: Vector4, p: Vector3, inv: Basis) -> bool:
	var l: Vector3 = inv * (Vector3(o.x, 0, o.y) - Vector3(p.x, 0, p.z))
	return clear_at(l.x, l.z) - 0.75 < o.z * 1.4 + 1.5


## The stone columns that would stand in it at this spot (its second try takes them out: the placement rule).
static func columns_in(maker: CaveMaker, spot: Dictionary) -> Array[int]:
	var inv := Basis(Vector3.UP, int(spot.turn) * PI / 2.0).inverse()
	var out: Array[int] = []
	for i in maker._cols.size():
		if _column_in(maker._cols[i], spot.pos, inv):
			out.append(i)
	return out


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinCliffGalleries"
	drop_rubble = false   # (its rubble lies where the plan says: on the floors and the ground it fell onto)
	stone_key = BLUEPRINT  # (one blueprint, stone below and brick above: rebuilt as itself)
	wood_key = BLUEPRINT
	ruin_name = "cliff_galleries"
	hard_mat = "cut_stone"
	reach = REACH
	ground_y = G


## The Rebuilding Chest stands in the yard in front of the grand stair, beside its steps (local x -3..3, z 3..5).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(-7.5, 11.5), Vector2(2.5, 11.5), Vector2(-10.5, 12.0), Vector2(-5.0, 14.0), Vector2(0.0, 14.5)]


func _path_z(_rad: float) -> float:
	return 14.0  # (4 m out from the grand stair's foot: the chest's last spot, never in the steps' way)


func _ready() -> void:
	var st: String = auth.world_state.get("cliff_galleries", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Cliff Galleries
		return
	var spot: Dictionary = auth.world.maker.cliff_galleries_spot
	if spot.is_empty():
		spot = pick(auth.world.maker)
	if spot.is_empty():
		push_warning("RuinCliffGalleries: no cavern for the Cliff Galleries")
		queue_free()
		return
	room = spot.room
	auth.world.maker.rooms[room].kind = "ruin"  # rock beetles guard it (every run, also after it's built)
	origin = spot.pos - Vector3(0, G, 0)   # (its box's bottom, near the crack's floor: the cave floor is 5 m up it)
	turn = spot.turn
	if st != "pending":
		built_origin = origin
		built_turn = turn
		set_process(false)
		return
	_carve = carve_points(origin, turn)


## Where its shelf and its ledge should be solid rock (box metres): balls on a 1.8 m grid, kept one ball in from the
## open faces (so the rock ends where the plan says), from 1.5 m under the cave floor up to their tops; and the niches'
## floors behind them. Only the ones with open air round them are filled (see _process): the cave's own rock stays.
static func fill_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var sh := BlueprintLibrary.CG_SHIFT
	# [x from, x to, z back, top]: the shelf (its inner face x -7.2, front -1.2), the ledge (inner face x 11)
	for b in [[-23.0, -7.2 - FILL_R, -14.0, 10.75], [11.0 + FILL_R, 27.0, -15.0, 4.5]]:
		var x: float = b[0]
		while x <= float(b[1]) + 0.01:
			var z: float = b[2]
			while z <= -1.2 - FILL_R + 0.01:
				var y := G - 1.5
				while y <= G + float(b[3]) - FILL_R + 0.01:
					out.append(Vector3(x + sh.x, y, z + sh.z))
					y += FILL_STEP
				if y - FILL_STEP < G + float(b[3]) - FILL_R - 0.3:
					out.append(Vector3(x + sh.x, G + float(b[3]) - FILL_R, z + sh.z))  # (right up to its top)
				z += FILL_STEP
			x += FILL_STEP
	return out


## What it digs (ordinary digs: saved and sent to friends), in world space: the blueprint's own air cells over its
## ground (only round its pieces), the yard in front, and the crack with its ramp out.
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
					if c.y >= ground_at(c.x, c.z) + 0.9:
						out.append(at + basis * c)
				i += 1
	var y := G + 0.9
	while y <= G + 4.5:  # the yard in front of the grand stair and the shed (the Rebuilding Chest stands there)
		for x in range(int(YARD_X.x), int(YARD_X.y) + 1):
			for z in range(int(YARD_Z.x), int(YARD_Z.y) + 1):
				out.append(at + basis * Vector3(x, y, z))
		y += 1.2
	var sh := BlueprintLibrary.CG_SHIFT
	for lx in [8.2, 9.0, 9.8]:  # the crack (1.2 m in from its rock sides) and its ramp out in front
		var lz := -9.2 + 1.1
		while lz <= 8.0:
			var x: float = lx + sh.x
			var z: float = lz + sh.z
			var h := rise_at(x, z)
			if h < -0.3:
				y = G + h + 1.0
				while y <= G + 1.5:
					out.append(at + basis * Vector3(x, y, z))
					y += 1.0
			lz += 1.0
	return out


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = REACH + 4.0
		var box := AABB(origin + Vector3(-half, -2.0, -half), Vector3(half * 2.0, G + HEIGHT + 6.0, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			_fill = fill_here()
			print("RUIN_CLIFF_GALLERIES filling %d holes under its shelf and ledge, then digging %d balls" % [_fill.size(), _carve.size()])
			_state = "fill"
		return
	if _state == "fill":
		var n := 0
		while not _fill.is_empty() and n < FILLS_PER_FRAME:
			auth.host_fill(_fill.pop_back(), FILL_R, Mat.STONE)
			n += 1
		if _fill.is_empty():
			_state = "carve"
		return
	if _state == "build":
		_build()
		auth.world_state["cliff_galleries"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_CLIFF_GALLERIES built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)


## The fill balls this spot needs (world space): only where the cave has open air (its own rock stays as it is).
func fill_here() -> Array:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var out := []
	for s in fill_spots():
		var w: Vector3 = origin + basis * s
		if auth.world.sdf_at(w) > -0.8:
			out.append(w)
	return out
