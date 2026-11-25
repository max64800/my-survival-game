class_name RuinSmeltery
extends RuinTower
## The Smeltery Terraces (owner, Nov 24-25, F845): the tenth ruin, a Hearthbrick smelting works stepped up a cave wall:
## vaults and a yard at the bottom, a hall on the terrace, a furnace with its own little bridge on the left, a tall
## chimney tower with a ring room on the right, two 6-sided turrets with ladders. Huge (52 x 22 m, 24 m tall), so it
## needs one of the tallest Mossy caverns. Its plan is blueprints/ruins/smeltery_ruin.json
## (tools/ruins/make_smeltery_ruin.py: the owner-approved 3D page's breakage, made sound for the game). Works like the
## Prow Hall (ruin_prow_hall.gd): the world remembers "smeltery: pending" and builds it the first time someone comes
## close. Built into a natural cave (F657): it finds a cave whose own rock wall stands right behind its back (z < -10.2),
## and only digs the blueprint's own air cells, the yard in front and the dip under the bridge. It grows no rock.
## Rebuilt in hearth brick (the chimney tower stays brick in wood too); rock beetles guard it.

const PLAN_PATH := "res://blueprints/ruins/smeltery_ruin.json"
const BLUEPRINT := "hearthbrick_smeltery"
const WANT_DIST := 240.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 28.0        ## its far ends (the furnace's left side, the watch turret) are about 27 m from the middle
const HEIGHT := 24.0       ## the chimney's cap is at 22.35 m
const TRIES := 10
static var built_origin := Vector3.INF
static var built_turn := 0

var room := -1
var _check := 0.0


## Its caverns, best first: Mossy's plain big caverns (not the start's, nor a grand ruin's), the tallest first, then
## the widest, each lot nearest 240 m from the start. Only the seed. Mossy has 7 big caverns and the other ruins and
## the Great Hall have them all, so it shares one with a small ruin (the Outpost, the Brewhall or the Spire use only a
## corner of theirs): the reserved ground keeps the two apart, and its back wants the cave's wall anyway.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [int(maker.manor_spot.get("room", -1)), int(maker.prow_hall_spot.get("room", -1)),
		int(maker.twin_gate_spot.get("room", -1))]
	var found: Array = []
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if i in taken or not rm.big or rm.get("biome", "mossy") != "mossy" or rm.get("kind", "") not in ["cavern", "ruin", "nest_cavern"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d < 80.0:
			continue
		var r: Vector3 = rm.radii
		var tall := 0 if r.y >= 12.0 else (1 if r.y >= 11.0 else 2)
		var wide := 0 if maxf(r.x, r.z) >= 26.0 else 1
		found.append([tall, wide, absf(d - WANT_DIST), i])
	found.sort()
	var out: Array[int] = []
	for f in found:
		out.append(int(f[3]))
	return out


static var _ground: Array = []
static var _tops := {}   ## Vector2i 2 m cell -> how high its pieces reach there (m)
static var _clear := PackedFloat32Array()  ## how far each 1 m cell of its frame is from its ground (see clear_at)
const CLEAR_X := 40   ## that map covers x -40..40, z -36..36
const CLEAR_Z := 36


## Its ground in its own frame, every 2 m: under every piece (the bridge and its dip too, the crown's balconies), and
## the yard in front of it (to z 12). [Vector2, ...]
static func ground() -> Array:
	if _ground.is_empty():
		var cells := {}
		for p in BlueprintLibrary.make(BLUEPRINT).pieces:
			var c := Vector2i(roundi(p.pos.x / 2.0), roundi(p.pos.z / 2.0))
			cells[c] = true
			_tops[c] = maxf(float(_tops.get(c, 0.0)), p.pos.y + 2.25)
		for x in range(-11, 13):
			for z in range(5, 7):
				cells[Vector2i(x, z)] = true  # the yard (x -22..24, z 10..12)
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


## Where the cave's own rock should be: right behind its back (its back walls are at z -10), 2 to 14 m up, along the
## vaults, the hall and the tower (the terraces lean into the cave wall).
const BACK_XS := [-6.0, -1.0, 4.0, 9.0, 14.0, 19.0]
const BACK_ZS := [-11.5, -14.0]
const BACK_YS := [2.0, 6.0, 10.0, 14.0]
const BACK_ALL := 48     ## BACK_XS x BACK_ZS x BACK_YS
const BACK_MISS := 3.0   ## how much each back sample that's open air counts against a spot (F866: was 1.5)
const FRONT_COST := 8.0  ## and a way in that has to be dug out


## How many of the back samples are rock at this spot (its back set into the rock).
static func back_rock(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var n := 0
	for x in BACK_XS:
		for z in BACK_ZS:
			for y in BACK_YS:
				if maker.sdf_at(p + basis * Vector3(x, y, z)) < 0.0:
					n += 1
	return n


## The way in: 10 m in front of the yard's steps (z 9) and the furnace's door (the owner rule F350). The yard is dug
## out to z 12, so rock there only costs a little digging: 0 = open, level ground already; 1 = rock or a bump to dig
## out; 2 = a drop (no spot for it).
static func front_state(maker: CaveMaker, p: Vector3, basis: Basis) -> int:
	var st := 0
	for z in [13.0, 16.0, 19.0]:
		for x in [-19.7, -6.0, 1.0, 9.0, 18.0]:
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


## The spot (in the tallest caverns) with the flattest floor under it, no column or other ruin on any of its ground,
## the least rock in the way of its pieces (up to each piece's own height: a low ceiling over the chimney tower counts),
## the cave's own rock behind its back and the way in open; its front turned toward the way you come from if it fits
## that way (else another way). Besides a grid round the cavern's middle, it tries spots slid straight back until its
## back meets the cave wall (owner, Nov 25, F866: it stood out in the open in a wide cavern). past_columns = its second
## try (see columns_in). Returns {room, pos, turn}.
static func pick(maker: CaveMaker, past_columns := false) -> Dictionary:
	var c0 := maker.cavern_spawn
	var best := {}
	var best_score := [INF]
	var pts := ground()
	for best_room in rooms_to_try(maker).slice(0, TRIES):
		var rc: Vector3 = maker.rooms[best_room].center
		var cols := []  # (only the columns near this cavern: quick)
		for o in maker._cols:
			if Vector2(o.x - rc.x, o.y - rc.z).length() < 80.0:
				cols.append(o)
		var tries := []  # [p, turn, how far from the middle (m)]
		for gx in range(-4, 5):
			for gz in range(-4, 5):
				var p := rc + Vector3(gx * 4.0, 0, gz * 4.0)
				for t in 4:
					tries.append([p, t, Vector2(gx, gz).length() * 4.0])
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
					for x in BACK_XS:
						for y in [4.0, 8.0]:
							if maker.sdf_at(p + basis * Vector3(x, 0, -11.0) + Vector3(0, fy - p.y + y, 0)) < 0.0:
								n += 1
					if n >= 8:  # its back meets the wall here
						tries.append([p, t, Vector2(lx, d).length() * 0.5])
						break
					d += 2.0
		for tr in tries:
			var p: Vector3 = tr[0]
			var to: Vector3 = c0 - p  # its front (local +z) faces the way you come from, if it can
			var facing := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
			var pen: float = [0, 5, 10, 5][posmod(int(tr[1]) - facing, 4)] + float(tr[2]) * 0.075
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
		var q := Vector3(w.x, mid.y + 4.0, w.z)  # (its floor, looked for only 3 m below the middle's: quick)
		while q.y > mid.y - 3.25 and maker.sdf_at(q) > 0.0:
			q.y -= 0.75
		if q.y > mid.y - 3.25:
			while maker.sdf_at(q + Vector3(0, 0.25, 0)) <= 0.0 and q.y < mid.y + 4.0:
				q.y += 0.25  # (back up to the floor's top, 0.25 m at a time)
		if q.y < mid.y - 3.0 and dip_at(g.x, g.y) > -0.5:
			return INF  # a drop or a chasm under it
		ys.append(q.y)
		lo = minf(lo, q.y)
		hi = maxf(hi, q.y)
		if (hi - lo) * 4.0 + pen >= beat:
			return INF  # already worse than the best spot so far (quick)
	if ys.is_empty():
		return INF
	ys.sort()
	var base: float = ys[0] - 0.05
	var rock := 0
	for i in range(0, pts.size(), 3):  # rock in the way of its pieces, up to their own height
		var g: Vector2 = pts[i]
		var top := top_at(g.x, g.y)
		for h in [2.0, 6.0, 10.0, 14.0, 18.0, 22.0]:
			if h > top:
				break
			if maker.sdf_at(Vector3(p.x, base, p.z) + basis * Vector3(g.x, h, g.y)) < 0.0:
				rock += 1
	var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 1.0 + pen
	if score >= beat:
		return INF
	var at := Vector3(p.x, base, p.z)
	var front := front_state(maker, at, basis)
	if front == 2:
		return INF  # a drop in front of the yard
	score += front * FRONT_COST
	score += (BACK_ALL - back_rock(maker, at, basis)) * BACK_MISS
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


# ---------------------------------------------------------------- the cave's shape (keep in step with make_smeltery_ruin.py)
static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


const DIP := 2.5
const DIP_X := Vector2(-11.7, -8.6)  ## between the bridge's pier (x -14..-12) and the terrace's side wall (x -8)
const DIP_Z := Vector2(0.5, 5.0)     ## a gully in the cave floor just in front of the bridge (z -1): its 3 rows of columns stand on flat ground (owner, Nov 25)


## The dip under the bridge: how deep the floor goes (0 elsewhere, -2.5 at its deepest).
static func dip_at(x: float, z: float) -> float:
	return -DIP * _smooth((x - DIP_X.x) / 0.9) * _smooth((DIP_X.y - x) / 0.9) * _smooth((z - DIP_Z.x) / 2.0) * _smooth((DIP_Z.y - z) / 2.0)


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinSmeltery"
	drop_rubble = false   # (its rubble lies where the plan says: on the floors it fell onto, down in the dip)
	stone_key = "hearthbrick_smeltery"
	wood_key = "wooden_smeltery"
	ruin_name = "smeltery"
	hard_mat = "clay_brick"
	reach = REACH


## The Rebuilding Chest stands in front of the yard, beside its two steps (x 1 and 9).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(-3.0, 11.5), Vector2(13.0, 11.5), Vector2(5.0, 12.5), Vector2(-5.0, 11.5), Vector2(15.0, 11.5)]


func _path_z(_rad: float) -> float:
	return 14.0


func _ready() -> void:
	var st: String = auth.world_state.get("smeltery", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Smeltery
		return
	var spot: Dictionary = auth.world.maker.smeltery_spot
	if spot.is_empty():
		spot = pick(auth.world.maker)
	if spot.is_empty():
		push_warning("RuinSmeltery: no cavern for the Smeltery Terraces")
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
## its pieces, never below its ground line), the yard in front, and the dip under the bridge.
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
					if c.y >= 0.9:
						out.append(at + basis * c)
				i += 1
	var y := 1.5
	while y <= 4.5:  # the yard in front of the steps
		for x in range(-22, 25):
			for z in range(9, 13):
				out.append(at + basis * Vector3(x, y, z))
		y += 1.2
	var x := DIP_X.x - 0.6
	while x <= DIP_X.y + 0.6:  # the dip under the bridge
		var z := DIP_Z.x - 1.0
		while z <= DIP_Z.y + 1.0:
			var h := dip_at(x, z)
			if h < -0.3:
				y = h + 1.0
				while y <= 1.5:
					out.append(at + basis * Vector3(x, y, z))
					y += 1.0
			z += 0.5  # (half-metre steps: the dip is short now, in front of the bridge)
		x += 0.5
	return out


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = REACH + 4.0
		var box := AABB(origin + Vector3(-half, -4.0, -half), Vector3(half * 2.0, HEIGHT + 4.0, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			_state = "carve"
		return
	if _state == "build":
		_build()
		auth.world_state["smeltery"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_SMELTERY built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)
