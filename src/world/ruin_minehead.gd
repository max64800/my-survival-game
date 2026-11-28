class_name RuinMinehead
extends RuinTower
## The Mine-head Works (owner, Nov 25, F899): the twelfth ruin, an old mine's top: a stone terrace, the engine house
## and its boiler shed in niches of the rock wall, the wooden headframe over the shaft (its Head Wheel fallen), a
## broken trestle over a dip to the ore shed on a lower ledge, and the 8 m shaft down to a mine room (half caved in).
## Its plan is blueprints/ruins/minehead_ruin.json (tools/ruins/make_minehead_ruin.py: the owner-approved 3D page's
## breakage, made sound for the game). Works like Brickcrown (ruin_brickcrown.gd): the world remembers
## "minehead: pending" and builds it the first time someone comes close. Built into a natural cave (F657): it finds a
## cave whose own rock stands behind it and under it. Its box: the mine room's floor is the box's floor and the cave
## floor is 8 m up it (BlueprintLibrary.MINE_SHIFT), so its origin is 8 m under the ground. It digs the blueprint's own
## air cells, the yard in front, the dip and the lower ledge (with ramps out of them at the front), and the shaft and
## the mine room (with small balls: their rock walls stay square to the timbers). Rebuilt as itself (one blueprint).

const PLAN_PATH := "res://blueprints/ruins/minehead_ruin.json"
const BLUEPRINT := "minehead_works"
const WANT_DIST := 300.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 29.0        ## its far corners (the engine house's back, the ore shed's) are about 28.8 m from the middle
const HEIGHT := 21.0       ## the headframe's hood is about 19.2 m over its ground
const TRIES := 10
const FUNGAL_TRIES := 3
const FUNGAL_COST := 1000.0  ## a Fungal cavern's spot counts this much worse: any Mossy spot that fits wins
const G := 8.0             ## its ground in its box (BlueprintLibrary.MINE_SHIFT.y)
const SMALL_R := 0.8       ## the balls the shaft and the mine room are dug with
static var built_origin := Vector3.INF
static var built_turn := 0

var room := -1
var _check := 0.0
var _small: Array = []


## Its caverns, best first: Mossy's plain big caverns (not the start's, nor a grand ruin's), the widest first (it is
## 54 m long), then the tallest, each lot nearest 300 m from the start; then the Fungal zone's the same way (Mossy has
## only about 8 big caverns and the grand ruins take most: seed 7 had none left; a Fungal one only wins if no Mossy
## one fits, see FUNGAL_COST). Only the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [int(maker.manor_spot.get("room", -1)), int(maker.prow_hall_spot.get("room", -1)),
		int(maker.twin_gate_spot.get("room", -1)), int(maker.smeltery_spot.get("room", -1)),
		int(maker.brickcrown_spot.get("room", -1))]
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
		var wide := 0 if maxf(r.x, r.z) >= 26.0 else (1 if maxf(r.x, r.z) >= 22.0 else 2)
		var tall := 0 if r.y >= 11.0 else 1
		found.append([0 if biome == "mossy" else 1, wide, tall, absf(d - WANT_DIST), i])
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


# ---------------------------------------------------------------- its own frame (box metres; keep in step with make_minehead_ruin.py)
static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## The ground the blueprint was made on at (x, z) of its box, over its ground line (0 the cave floor, -4 the dip, -2.25
## the lower ledge; 99 = the rock wall behind).
static func _plan_ground(x: float, z: float) -> float:
	return BlueprintLibrary._mine_ground(x - BlueprintLibrary.MINE_SHIFT.x, z - BlueprintLibrary.MINE_SHIFT.z)


## Where the cave's own rock is meant to be: the rock wall behind it, with its niches.
static func in_rock_zone(x: float, z: float) -> bool:
	return _plan_ground(x, z) > 50.0


## How deep it digs the floor at (x, z) of its box, under its ground line (0 = no digging down): the dip under the
## trestle, the lower ledge and the steps down to it, ramping back up to the cave floor in front (local z 3.5..12) so
## you can walk into them.
static func dip_at(x: float, z: float) -> float:
	var h := _plan_ground(x, z)
	if h > 50.0 or h > -0.1:
		return 0.0
	var lz := z - BlueprintLibrary.MINE_SHIFT.z
	if lz > 3.5 and h < -2.25:
		h = lerpf(h, -2.25, _smooth((lz - 3.5) / 4.0))
	if lz > 5.0:
		h = lerpf(h, 0.0, _smooth((lz - 5.0) / 7.0))
	return h


## The ground in its box at (x, z): 8 m up, down in the dip and on the ledge.
static func ground_at(x: float, z: float) -> float:
	return G + dip_at(x, z)


## The dug part in front of the dip and the ledge (box): where the ramps run out to the cave floor.
const DIG_X := Vector2(7.2, 27.0)   ## (local 11.2..31: from the dip's cliff to the box's end)
const DIG_Z_FRONT := 16.0           ## (local 12)

static var _ground: Array = []
static var _tops := {}   ## Vector2i 2 m cell -> how high its pieces reach there over its ground (m)
static var _clear := PackedFloat32Array()  ## how far each 1 m cell of its frame is from its ground (see clear_at)
const CLEAR_X := 36   ## that map covers x -36..36, z -32..32
const CLEAR_Z := 32


## Its ground in its own frame, every 2 m: under every piece, the dip, the ledge and their ramps, and the yard in front
## of the terrace. [Vector2, ...]
static func ground() -> Array:
	if _ground.is_empty():
		var cells := {}
		for p in BlueprintLibrary.make(BLUEPRINT).pieces:
			var c := Vector2i(roundi(p.pos.x / 2.0), roundi(p.pos.z / 2.0))
			cells[c] = true
			_tops[c] = maxf(float(_tops.get(c, 0.0)), p.pos.y - G + 2.25)
		for x in range(-14, 15):
			for z in range(-6, 9):
				var bx := x * 2.0
				var bz := z * 2.0
				if bx >= DIG_X.x and bx <= DIG_X.y and bz <= DIG_Z_FRONT and not in_rock_zone(bx, bz):
					cells[Vector2i(x, z)] = true  # the dip, the ledge and their ramps
				if z >= 4 and z <= 6 and x >= -10 and x <= 4:
					cells[Vector2i(x, z)] = true  # the yard in front of the terrace (z 8..12, x -20..8: what it digs)
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


## Where the cave's own rock should be (x, z in its box, y over its ground): behind the engine house and the boiler
## shed (their niches end at z -7.2), behind the headframe (z -5.2) and behind the ore shed.
const BACK := [
	[-22.0, -8.5, 3.0], [-17.0, -8.5, 3.0], [-12.0, -8.5, 3.0], [-22.0, -8.5, 7.0], [-17.0, -8.5, 7.0], [-12.0, -8.5, 7.0],
	[-22.0, -8.5, 11.0], [-17.0, -8.5, 11.0], [-12.0, -8.5, 11.0], [-22.0, -9.8, 15.0], [-12.0, -9.8, 15.0],
	[-5.0, -6.8, 3.0], [0.0, -6.8, 3.0], [5.0, -6.8, 3.0], [-5.0, -6.8, 8.0], [0.0, -6.8, 8.0], [5.0, -6.8, 8.0],
	[0.0, -8.5, 13.0], [5.0, -8.5, 13.0],
	[15.0, -8.5, 1.0], [20.0, -8.5, 1.0], [25.0, -8.5, 1.0], [15.0, -8.5, 5.0], [20.0, -8.5, 5.0], [25.0, -8.5, 5.0],
]
## And under it, round the shaft, the mine room and the dip (an open cave there would leave them in the air).
const UNDER := [
	[-6.5, -1.0, -6.0], [-2.0, -12.5, -6.0], [-2.0, 0.5, -6.0], [2.0, -12.5, -6.0], [2.0, 0.5, -6.0], [-3.0, -1.0, -9.5],
	[3.0, -1.0, -9.5], [1.0, 0.5, -3.0], [4.5, -1.0, -3.5], [10.0, -2.0, -5.5], [10.0, 4.0, -5.5], [20.0, -3.0, -3.5],
]
const BACK_MISS := 3.0   ## how much each back (or under) sample that's open air counts against a spot
const FRONT_COST := 8.0  ## and a way in that has to be dug out


## How many of the back and under samples are rock at this spot (p: its ground line under its middle).
static func back_rock(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var n := 0
	for b in BACK + UNDER:
		if maker.sdf_at(p + basis * Vector3(b[0], b[2], b[1])) < 0.0:
			n += 1
	return n


## The way in: in front of the terrace's steps (box x -14..-10, z 6) and the ramps out of the dip (the owner rule
## F350). The yard is dug out to z 12, so rock there only costs a little digging: 0 = open, level ground already;
## 1 = rock or a bump to dig out; 2 = a drop (no spot for it). p: its ground line under its middle.
static func front_state(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var st := 0
	for z in [13.0, 16.0, 19.0]:
		for x in [-18.0, -12.0, -5.0, 2.0, 10.0, 18.0]:
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


## The spot (in the widest caverns) with the flattest floor under its cave-floor parts, no column or other ruin on any
## of its ground, the least rock in the way of its pieces out in the open (up to each piece's own height), the cave's
## own rock behind it and round its shaft, and the way in open; its front turned toward the way you come from if it
## fits that way. Besides a grid round the cavern's middle, it tries spots slid straight back until its back meets the
## cave wall (like Brickcrown). past_columns = its second try (see columns_in).
## Returns {room, pos (its ground line under its middle), turn}.
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
		var tries := []  # [p, turn, how far from the middle (m)]: the ones slid back to the wall first (they're often the
		# best: a good score early lets the rest stop sooner)
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
					for x in [-20.0, -14.0, -8.0, 0.0, 16.0, 23.0]:
						for y in [3.0, 7.0]:
							var bz := -6.8 if absf(x) < 6.0 else -8.5  # (behind the headframe, the niches)
							if maker.sdf_at(p + basis * Vector3(x, 0, bz) + Vector3(0, fy - p.y + y, 0)) < 0.0:
								n += 1
					if n >= 8:  # its back meets the wall here
						tries.append([p, t, Vector2(lx, d).length() * 0.5])
						break
					d += 2.0
		for gx in range(-4, 5):
			for gz in range(-4, 5):
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
	for i in range(0, pts.size(), 4):
		var g: Vector2 = pts[i]
		var w: Vector3 = p + basis * Vector3(g.x, 0, g.y)
		if maker.is_reserved(Vector3(w.x, mid.y + 0.3, w.z), 2.0):
			return INF  # another ruin's (or a dungeon's) ground
		if in_rock_zone(g.x, g.y) or dip_at(g.x, g.y) < -0.5:
			continue  # (the rock is wanted there; the dip and the ledge are dug down, looked at below)
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
	score += (BACK.size() + UNDER.size() - back_rock(maker, at, basis)) * BACK_MISS  # (cheap, so first: it often
	if score >= beat:                                                                 # rules a spot out already)
		return INF
	for i in range(0, pts.size(), 3):  # rock in the way of its pieces out in the open, up to their own height
		var g: Vector2 = pts[i]
		if in_rock_zone(g.x, g.y):
			continue
		var dip := dip_at(g.x, g.y)
		if dip < -0.5 and maker.sdf_at(at + basis * Vector3(g.x, dip - 1.0, g.y)) > 0.0:
			score += 4.0  # (the dip's floor would be over open air)
		var top := top_at(g.x, g.y)
		for h in [2.0, 6.0, 10.0, 14.0, 18.0]:
			if h > top:
				break
			if maker.sdf_at(at + basis * Vector3(g.x, h, g.y)) < 0.0:
				score += 1.0
		if score >= beat:
			return INF  # already worse than the best spot so far (quick)
	var front := front_state(maker, at, basis)
	if front == 2:
		return INF  # a drop in front of the terrace
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
	name = "RuinMinehead"
	drop_rubble = false   # (its rubble lies where the plan says: on the floors it fell onto)
	stone_key = BLUEPRINT  # (one blueprint, stone below and wood above: rebuilt as itself)
	wood_key = BLUEPRINT
	ruin_name = "minehead"
	hard_mat = "cut_stone"
	reach = REACH
	ground_y = G


## The Rebuilding Chest stands in the yard in front of the terrace, beside its steps (x -14..-10).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(-17.0, 9.5), Vector2(-6.5, 9.5), Vector2(-20.0, 10.0), Vector2(0.0, 10.0), Vector2(-3.0, 11.0)]


func _path_z(_rad: float) -> float:
	return 11.0


func _ready() -> void:
	var st: String = auth.world_state.get("minehead", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Mine-head Works
		return
	var spot: Dictionary = auth.world.maker.minehead_spot
	if spot.is_empty():
		spot = pick(auth.world.maker)
	if spot.is_empty():
		push_warning("RuinMinehead: no cavern for the Mine-head Works")
		queue_free()
		return
	room = spot.room
	auth.world.maker.rooms[room].kind = "ruin"  # rock beetles guard it (every run, also after it's built)
	origin = spot.pos - Vector3(0, G, 0)   # (its box's bottom, the mine room's floor: the ground is 8 m up it)
	turn = spot.turn
	if st != "pending":
		built_origin = origin
		built_turn = turn
		set_process(false)
		return
	_carve = carve_points(origin, turn)
	_small = small_points(origin, turn)


## What it digs with ordinary balls (saved and sent to friends), in world space: the blueprint's own air cells above
## its ground (only round its pieces), the yard in front, and the dip, the ledge and their ramps.
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
	while y <= G + 4.5:  # the yard in front of the terrace (dug down to its ground: the Rebuilding Chest stands there)
		for x in range(-20, 9):
			for z in range(8, 13):
				out.append(at + basis * Vector3(x, y, z))
		y += 1.2
	var x := DIG_X.x + 1.2   # (1.2 m in from the dip's cliff: the terrace's rock stays)
	while x <= DIG_X.y + 1.0:  # the dip, the ledge, the steps down and the ramps out
		var z := -9.5
		while z <= DIG_Z_FRONT:
			var h := dip_at(x, z)
			if not in_rock_zone(x, z) and not in_rock_zone(x, z - 1.1) and h < -0.3:
				y = G + h + 1.0
				while y <= G + 1.5:
					out.append(at + basis * Vector3(x, y, z))
					y += 1.0
			z += 1.0
		x += 1.0
	return out


## The shaft and the mine room (world space): small balls on a 0.7 m grid, kept 0.75 m in from their walls (their rock
## walls stay straight beside the ladders and the props), and a lumpy ceiling a little higher in the mine room's middle.
static func small_points(at: Vector3, trn: int) -> Array:
	var basis := Basis(Vector3.UP, trn * PI / 2.0)
	var out := []
	var sh := BlueprintLibrary.MINE_SHIFT
	for ix in 4:  # the shaft: local x 3.75..6.25, z -6.25..-3.75, from the mine room up to the cave floor
		for iz in 4:
			var y := -7.25
			while y <= 0.5:
				out.append(at + basis * (Vector3(3.75 + ix * 0.833, y, -6.25 + iz * 0.833) + sh))
				y += 0.7
	for ix in 16:  # the mine room: local x -4.25..6.25, z -6.25..-3.75, y -7.25 up to its ceiling
		for iz in 4:
			var lx := -4.25 + ix * 0.7
			var lz := -6.25 + iz * 0.833
			var top := -5.75 + 0.35 * (1.0 - absf(lz + 5.0) / 1.25) + 0.15 * sin(lx * 1.9)
			var y := -7.25
			while y <= top + 0.01:
				out.append(at + basis * (Vector3(lx, y, lz) + sh))
				y += 0.7
			if y - 0.7 < top - 0.1:
				out.append(at + basis * (Vector3(lx, top, lz) + sh))
	return out


var _sorted: Array[String] = []  ## which carve lists are in patch order already


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = REACH + 4.0
		var box := AABB(origin + Vector3(-half, -2.0, -half), Vector3(half * 2.0, G + HEIGHT + 6.0, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			print("RUIN_MINEHEAD digging: %d balls, %d small ones in the shaft" % [_carve.size(), _small.size()])
			_state = "carve"
		return
	if _state == "carve" or _state == "small":  # (the big balls first, then the small ones in the shaft)
		var big := _state == "carve"
		var list: Array = _carve if big else _small
		var r := CARVE_RADIUS if big else SMALL_R
		if not _sorted.has(_state):  # one patch of rock a frame (F417)
			sort_patches(list)
			_sorted.append(_state)
		carve_patch(auth, list, r)
		if list.is_empty():
			_state = "small" if big else "build"
		return
	if _state == "build":
		if not _build():
			return  # (a little each frame, F417)
		auth.world_state["minehead"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_MINEHEAD built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)
