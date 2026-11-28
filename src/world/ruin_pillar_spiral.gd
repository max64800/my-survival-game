class_name RuinPillarSpiral
extends RuinTower
## The Pillar Spiral (owner, Nov 28, F942): the fifteenth ruin, a town wound round a rock column: the stone Ring Hall
## round the column's foot, four houses (brick below, wood on top) climbing round it on the hall's roof, a wooden stair
## winding round the column from house to house, the Eyrie lookout on top with the best chest, the Arch Bridge over a
## crack to the Kiln House on its rock lump, and the Shrine Bridge to the Rock Shrine on a high shelf. Its plan is
## blueprints/ruins/pillar_spiral_ruin.json (tools/ruins/make_pillar_spiral_ruin.py: the owner-approved page's ruin
## sketch, made sound for the game). Works like the Cliff Galleries (ruin_cliff_galleries.gd): the world remembers
## "pillar_spiral: pending" and builds it the first time someone comes close.
## The owner chose (Nov 28): its rock column is GROWN just for it (never hunted for). It picks a tall cavern spot where
## the least has to change, then fills with rock (saved rock edits, like Brickcrown's lump): the column from the floor
## up into the ceiling (BlueprintLibrary.ps_column, its top widening into the ceiling wherever that is), the Kiln
## House's lump, the high shelf behind and a slab of cave wall behind that. Then it digs the blueprint's own air
## cells, the crack under the Arch Bridge (ramping up to the cave floor in front, so you can walk out of it) and the
## yard in front of the grand stair (1 m down). Its box: the cave floor is 4.5 m up it (BlueprintLibrary.PS_SHIFT).
## Rebuilt as itself (one blueprint).

const PLAN_PATH := "res://blueprints/ruins/pillar_spiral_ruin.json"
const BLUEPRINT := "pillar_spiral"
const WANT_DIST := 340.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 29.0        ## its ground's far corners (the shelf's back corners, the lower floor's front ones) are 31 m out
const HEIGHT := 26.0       ## the Eyrie's spire is about 22 m over the cave floor; the column goes on into the ceiling
const MIN_CEIL := 24.0     ## the cave's ceiling over the column and the Eyrie must be at least this high (m)
const TRIES := 10
const FUNGAL_TRIES := 3
const FUNGAL_COST := 1000.0  ## a Fungal cavern's spot counts this much worse: any Mossy spot that fits wins
const G := 4.5             ## the cave floor in its box (BlueprintLibrary.PS_SHIFT.y)
const FILL_R := 1.6        ## the balls of rock it grows its column, lump and shelf with
const FILL_STEP := 1.8     ## (on this grid: the balls overlap, no gaps)
const FILLS_PER_FRAME := 20
const WALL_BACK := 29.0    ## the slab of cave wall behind the shelf: local z -26 .. -29
static var built_origin := Vector3.INF
static var built_turn := 0

var room := -1
var _check := 0.0
var _fill: Array = []


## Its caverns, best first: Mossy's big caverns (not the start's, nor another grand ruin's), the tallest first (the
## column must reach a ceiling 24 m+ up), then the widest, each lot nearest 340 m from the start; then the Fungal zone's
## the same way (only if no Mossy one fits, see FUNGAL_COST). Only the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [int(maker.manor_spot.get("room", -1)), int(maker.prow_hall_spot.get("room", -1)),
		int(maker.twin_gate_spot.get("room", -1)), int(maker.smeltery_spot.get("room", -1)),
		int(maker.brickcrown_spot.get("room", -1)), int(maker.minehead_spot.get("room", -1)),
		int(maker.cliff_galleries_spot.get("room", -1))]
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
		var tall := 0 if r.y >= 14.0 else (1 if r.y >= 12.0 else 2)
		var wide := 0 if maxf(r.x, r.z) >= 24.0 else (1 if maxf(r.x, r.z) >= 20.0 else 2)
		found.append([0 if biome == "mossy" else 1, tall, wide, absf(d - WANT_DIST), i])
	found.sort()
	var out: Array[int] = []
	var fungal := 0
	for f in found:
		if int(f[0]) == 1:
			fungal += 1
			if fungal > FUNGAL_TRIES:
				break
		out.append(int(f[4]))
	return out


# ---------------------------------------------------------------- its own frame (box metres; keep in step with make_pillar_spiral_ruin.py)
static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Box metres -> the blueprint's local metres (x, z): the column's middle is local 0, 0.
static func _lx(x: float) -> float:
	return x - BlueprintLibrary.PS_SHIFT.x


static func _lz(z: float) -> float:
	return z - BlueprintLibrary.PS_SHIFT.z


## The cave wall behind the shelf (local z < -26): rock it grows (a slab) or the cave's own.
static func in_rock_zone(_x: float, z: float) -> bool:
	return _lz(z) < -26.0


## How high its ground stands at (x, z) of its box over the cave floor: the shelf 9.75, the Kiln House's lump 2.25,
## the crack -4.5 (ramping back up to the cave floor in front, local z 6..16, so you can walk out of it), the yard in
## front of the grand stair -1, else 0 (also under the column: the column is grown on the cave floor).
static func rise_at(x: float, z: float) -> float:
	if in_rock_zone(x, z):
		return 0.0
	var lx := _lx(x)
	var lz := _lz(z)
	var h := BlueprintLibrary._ps_ground(lx, lz)
	if h < -2.0:
		h = lerpf(h, -1.0 if lz > 15.2 else 0.0, _smooth((lz - 6.0) / 10.0))
	return h


## The ground in its box at (x, z).
static func ground_at(x: float, z: float) -> float:
	return G + rise_at(x, z)


## Is (x, z) of its box in the crack (dug down)?
static func in_crack(x: float, z: float) -> bool:
	return rise_at(x, z) < -1.3


## The dug yard in front of the grand stair (local x -7..7, z 15.2..24: 1 m down, like the blueprint's lower floor).
const YARD_X := Vector2(-7.0, 7.0)
const YARD_Z := Vector2(15.6, 24.0)

static var _ground: Array = []
static var _tops := {}   ## Vector2i 2 m cell -> how high its pieces reach there over its own ground (m)
static var _clear := PackedFloat32Array()  ## how far each 1 m cell of its frame is from its ground (see clear_at)
const CLEAR_X := 36   ## that map covers x -36..36, z -36..36
const CLEAR_Z := 36


## Its ground in its own frame, every 2 m: under every piece, the column, the lump, the shelf, the crack and its ramp
## out, and the yard in front. [Vector2, ...]
static func ground() -> Array:
	if _ground.is_empty():
		var cells := {}
		for p in BlueprintLibrary.make(BLUEPRINT).pieces:
			var c := Vector2i(roundi(p.pos.x / 2.0), roundi(p.pos.z / 2.0))
			cells[c] = true
			_tops[c] = maxf(float(_tops.get(c, 0.0)), p.pos.y - ground_at(c.x * 2.0, c.y * 2.0) + 2.25)
		for x in range(-10, 11):
			for z in range(-12, 13):
				var bx := x * 2.0
				var bz := z * 2.0
				if in_rock_zone(bx, bz):
					continue
				if absf(rise_at(bx, bz)) > 0.3 or Vector2(_lx(bx), _lz(bz)).length() < 15.0:
					cells[Vector2i(x, z)] = true  # the shelf, the lump, the crack and its ramp, the lower floor, round the hall
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


## How high (m over the cave floor at p) the cave's ceiling is above p (straight up; 60 = none found).
static func ceiling_over(sdf: Callable, p: Vector3) -> float:
	var y := 3.0
	while y < 60.0:
		if float(sdf.call(p + Vector3(0, y, 0))) < 0.0:
			return y
		y += 1.0
	return 60.0


## The column's radius at height y over the cave floor (local), with the cave's ceiling `ceil` up: its round part
## (BlueprintLibrary.ps_column) widens into the ceiling over its top 8 m (the blueprint's own when ceil is 25).
static func column_r(y: float, ceil: float) -> float:
	var flare := maxf(ceil - 8.0, 17.0)
	return 3.8 + pow(clampf((y - flare) / 8.0, 0.0, 1.5), 2.0) * 6.0


## Is (lx, y, lz) (local, y over the cave floor) inside the column with the ceiling `ceil` up?
static func in_column(lx: float, y: float, lz: float, ceil: float) -> bool:
	if y < 5.5:
		return BlueprintLibrary.ps_column(lx, y, lz)
	return Vector2(lx, lz).length() < column_r(y, ceil)


## Where it grows rock (box metres, its ground line under its middle at y G): balls on a 1.8 m grid, kept one ball in
## from the open faces (so the rock ends where the plan says): the column from 1.5 m under the cave floor up into the
## ceiling, the Kiln House's lump, the high shelf and the cave wall slab behind it (up to the ceiling). Only the ones
## with open air round them are filled (see fill_here): the cave's own rock stays.
static func fill_spots(ceil: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var sh := BlueprintLibrary.PS_SHIFT
	var top := ceil + 2.0
	# the column: its middle at local 0, 0 (6-sided foot 5 m out to the terrace, then round)
	var y := -1.5
	while y <= top:
		var r := 5.0 / 0.8660254 if y < 5.5 else column_r(y, ceil)
		var x := -snappedf(r, FILL_STEP)
		while x <= r:
			var z := -snappedf(r, FILL_STEP)
			while z <= r:
				if _inside_by(x, y, z, ceil, FILL_R):
					out.append(Vector3(x + sh.x, G + y, z + sh.z))
				z += FILL_STEP
			x += FILL_STEP
		y += FILL_STEP
	# the lump (local x 17..27, z -8..8, top 2.25) and the shelf (z -26..-16 across the box, top 9.75) and the wall
	for b in [[17.0, 27.0, -8.0, 8.0, 2.25], [-14.0, 28.0, -26.0, -16.0, 9.75], [-14.0, 28.0, -WALL_BACK, -26.0, top]]:
		var x0: float = float(b[0]) + FILL_R
		var x1: float = float(b[1]) - FILL_R
		var z0: float = float(b[2]) + FILL_R
		var z1: float = float(b[3]) - FILL_R
		var yt: float = float(b[4]) - FILL_R
		var x := x0
		while x <= x1 + 0.01:
			var z := z0
			while z <= z1 + 0.01:
				var yy := -1.5
				while yy <= yt + 0.01:
					out.append(Vector3(x + sh.x, G + yy, z + sh.z))
					yy += FILL_STEP
				if yy - FILL_STEP < yt - 0.3:
					out.append(Vector3(x + sh.x, G + yt, z + sh.z))  # (right up to its top)
				z += FILL_STEP
			x += FILL_STEP
	return out


## Is the ball at (lx, y, lz) (local) wholly in the column (its middle at least r in from the column's face)?
static func _inside_by(lx: float, y: float, lz: float, ceil: float, r: float) -> bool:
	if y + r > 5.5 and y - r < 5.5:  # (where the 6-sided foot meets the round part: inside both)
		return _inside_by(lx, 5.4 - r, lz, ceil, r) and _inside_by(lx, 5.6 + r, lz, ceil, r)
	if y < 5.5:
		return maxf(absf(lz), maxf(absf(0.8660254 * lx + 0.5 * lz), absf(0.8660254 * lx - 0.5 * lz))) < 5.0 - r
	return Vector2(lx, lz).length() < column_r(y, ceil) - r


## The spot (in the tallest caverns) with the flattest floor under its ground, no column or other ruin on any of its
## ground, a ceiling at least MIN_CEIL up over the column and the Eyrie, the least rock in the way of its pieces (up to
## each piece's own height), the most of its shelf and wall already the cave's own rock, and the way in open; its front
## turned toward the way you come from if it fits that way. past_columns = its second try.
## Returns {room, pos (its ground line under its middle, the cave floor), turn, ceil (the column's ceiling, m)}.
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
		var cols := []
		for o in maker._cols:
			if Vector2(o.x - rc.x, o.y - rc.z).length() < 90.0:
				cols.append(o)
		for gx in range(-3, 4):  # (a grid round the middle, every 4 m)
			for gz in range(-3, 4):
				var p := rc + Vector3(gx * 4.0, 0, gz * 4.0)
				var to: Vector3 = c0 - p  # its front (local +z) faces the way you come from, if it can
				var facing := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
				for t in 4:
					var pen: float = [0, 5, 10, 5][posmod(t - facing, 4)] + Vector2(gx, gz).length() * 0.3 + fungal
					var sc := _score(maker, p, t, pen, cols, pts, rc, past_columns, best_score[0])
					if sc < best_score[0]:
						best_score[0] = sc
						best = {room = best_room, pos = Vector3(p.x, _last_base, p.z), turn = t, ceil = _last_ceil}
	return best


static var _last_base := 0.0  ## where its ground line goes at the spot _score last passed
static var _last_ceil := 25.0


## How bad a spot is (lower = better; INF = no good, or no better than `beat`).
static func _score(maker: CaveMaker, p: Vector3, turn: int, pen: float, cols: Array, pts: Array, rc: Vector3,
		past_columns: bool, beat: float) -> float:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var inv := basis.inverse()
	if not past_columns:
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
			continue  # (the shelf, the lump, the crack, the yard: grown or dug anyway)
		var q := Vector3(w.x, mid.y + 4.0, w.z)
		while q.y > mid.y - 3.25 and maker.sdf_at(q) > 0.0:
			q.y -= 0.75
		if q.y > mid.y - 3.25:
			while maker.sdf_at(q + Vector3(0, 0.25, 0)) <= 0.0 and q.y < mid.y + 4.0:
				q.y += 0.25
		if q.y < mid.y - 3.0:
			return INF  # a drop or a chasm under it
		ys.append(q.y)
		lo = minf(lo, q.y)
		hi = maxf(hi, q.y)
		if (hi - lo) * 4.0 + pen >= beat:
			return INF
	if ys.size() < 8:
		return INF
	ys.sort()
	var base: float = ys[0] - 0.05
	var at := Vector3(p.x, base, p.z)
	var sh := BlueprintLibrary.PS_SHIFT
	var sdf := func(q: Vector3) -> float: return maker.sdf_at(q)
	var ceil := ceiling_over(sdf, at + basis * Vector3(sh.x, 6.0, sh.z) - Vector3(0, 6.0, 0))
	if ceil < MIN_CEIL or ceiling_over(sdf, at + basis * Vector3(sh.x + 3.0, 0, sh.z + 8.0)) < MIN_CEIL - 1.0:
		return INF  # too low for the column's top and the Eyrie's spire
	var score: float = (ys[-1] - ys[0]) * 4.0 + pen + minf(ceil - MIN_CEIL, 20.0) * 0.3  # (a ceiling just high enough is best)
	for lx in [-10.0, -2.0, 6.0, 14.0, 22.0]:  # the shelf and the wall behind: the cave's own rock means less to grow
		for s in [[-18.0, 4.0], [-24.0, 8.0], [-27.0, 14.0], [-27.0, 20.0]]:
			if maker.sdf_at(at + basis * Vector3(lx + sh.x, float(s[1]), float(s[0]) + sh.z)) > 0.0:
				score += 0.5
	if score >= beat:
		return INF
	for i in range(0, pts.size(), 2):  # rock in the way of its pieces, up to their own height
		var g: Vector2 = pts[i]
		var r0 := rise_at(g.x, g.y)
		var top := top_at(g.x, g.y)
		var h := r0 + 2.0
		while h <= r0 + top:
			if not in_column(_lx(g.x), h, _lz(g.y), ceil) and maker.sdf_at(at + basis * Vector3(g.x, h, g.y)) < 0.0:
				score += 1.0
			h += 4.0
		if score >= beat:
			return INF
	var front := front_state(maker, at, basis)
	if front == 2:
		return INF  # a drop in front of the grand stair
	score += front * 8.0
	if score >= beat:
		return INF
	_last_base = base
	_last_ceil = ceil
	return score


## The way in, in front of the grand stair (owner rule F350): 0 = open, 1 = rock or a bump to dig out, 2 = a drop.
static func front_state(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var st := 0
	var sh := BlueprintLibrary.PS_SHIFT
	for z in [22.0, 25.0, 28.0]:
		for x in [-6.0, -2.0, 2.0, 6.0]:
			var at: Vector3 = p + basis * Vector3(x + sh.x, 0, z + sh.z)
			if maker.sdf_at(Vector3(at.x, p.y + 4.0, at.z)) <= 0.0:
				st = 1
				continue
			var f := maker.find_floor(at.x, at.z, p.y + 4.0).y
			if f < p.y - 2.5:
				return 2
			if f > p.y + 1.1:
				st = 1
	return st


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
	name = "RuinPillarSpiral"
	drop_rubble = false   # (its rubble lies where the plan says: on the floors and the ground it fell onto)
	stone_key = BLUEPRINT  # (one blueprint, stone, brick and wood: rebuilt as itself)
	wood_key = BLUEPRINT
	ruin_name = "pillar_spiral"
	hard_mat = "cut_stone"
	reach = REACH
	ground_y = G


## The Rebuilding Chest stands in the yard in front of the grand stair, beside its steps (local x -1..1, z 15.2..19.2).
func _chest_spots(_rad: float) -> Array[Vector2]:
	var sh := BlueprintLibrary.PS_SHIFT
	var out: Array[Vector2] = []
	for o in [Vector2(-3.5, 18.0), Vector2(3.5, 18.0), Vector2(-4.5, 20.5), Vector2(4.5, 20.5)]:
		out.append(Vector2(o.x + sh.x, o.y + sh.z))
	return out


func _path_z(_rad: float) -> float:
	return 21.5 + BlueprintLibrary.PS_SHIFT.z  # (2 m out from the grand stair's foot)


func _ready() -> void:
	var st: String = auth.world_state.get("pillar_spiral", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Pillar Spiral
		return
	var spot: Dictionary = auth.world.maker.pillar_spiral_spot
	if spot.is_empty():
		spot = pick(auth.world.maker)
	if spot.is_empty():
		push_warning("RuinPillarSpiral: no cavern for the Pillar Spiral")
		queue_free()
		return
	room = spot.room
	auth.world.maker.rooms[room].kind = "ruin"  # rock beetles guard it (every run, also after it's built)
	origin = spot.pos - Vector3(0, G, 0)   # (its box's bottom, near the crack's floor: the cave floor is 4.5 m up it)
	turn = spot.turn
	if st != "pending":
		built_origin = origin
		built_turn = turn
		set_process(false)
		return
	_carve = carve_points(origin, turn)


## What it digs (ordinary digs: saved and sent to friends), in world space: the blueprint's own air cells over its
## ground (only round its pieces, never in the column), the yard in front, and the crack with its ramp out.
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
	var sh := BlueprintLibrary.PS_SHIFT
	var y := G - 1.0 + 0.9
	while y <= G + 4.5:  # the yard in front of the grand stair (the Rebuilding Chest stands there)
		for x in range(int(YARD_X.x), int(YARD_X.y) + 1):
			for z in range(int(YARD_Z.x), int(YARD_Z.y) + 1):
				out.append(at + basis * Vector3(x + sh.x, y, z + sh.z))
		y += 1.2
	for lx in [14.4, 15.25, 16.1]:  # the crack (1.1 m in from its rock sides) and its ramp out in front
		var lz := -16.0 + 1.1
		while lz <= 20.0:
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
			print("RUIN_PILLAR_SPIRAL growing its column, lump and shelf: %d balls, then digging %d" % [_fill.size(), _carve.size()])
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
		if not _build():
			return  # (a little each frame, F417)
		auth.world_state["pillar_spiral"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_PILLAR_SPIRAL built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)


## The column's ceiling here (m over the cave floor, straight up from the column's middle).
func ceiling_here() -> float:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var sh := BlueprintLibrary.PS_SHIFT
	return ceiling_over(func(q: Vector3) -> float: return auth.world.sdf_at(q), origin + basis * Vector3(sh.x, G, sh.z))


## The fill balls this spot needs (world space): only where the cave has open air (its own rock stays as it is).
func fill_here() -> Array:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var out := []
	for s in fill_spots(ceiling_here()):
		var w: Vector3 = origin + basis * s
		if auth.world.sdf_at(w) > -0.8:
			out.append(w)
	return out
