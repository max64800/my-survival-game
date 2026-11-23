class_name RuinTwinGate
extends RuinTower
## The Twin Gate (owner, Nov 21-22, F479 + F656 + F657): the sixth ruin, the first grand one: two Stonehold towers with
## a gatehouse between them, a drill yard and barracks behind. The right tower cracked and half of it fell outward;
## the left one's fire still burns. 40 x 36 m, 16.5 m tall. Its plan is blueprints/ruins/twin_gate_ruin.json
## (tools/ruins/make_twin_gate_ruin.py). Works like the Prow Hall (ruin_prow_hall.gd): the world remembers
## "twin_gate: pending" and builds it the first time someone comes close.
## Built INTO the cave (F657, owner Nov 22: "yes, add cave shapes"): before its pieces go in, the world digs only the
## space round it (the blueprint's own "air" cells, the yard in front, the ground where the right tower fell) and a
## dry moat round the left tower's outside and front, then grows rock: a rough ledged cave wall wrapped round the
## barracks' back, and two rock lumps (one in the corner past the grand stair, one past the kitchen). Rebuilt in cut stone or
## wood; rock beetles guard it.

const PLAN_PATH := "res://blueprints/ruins/twin_gate_ruin.json"
const BLUEPRINT := "stonehold_twin_gate"
const WANT_DIST := 240.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 34.0        ## its far corners (the moat's outer corner, the rock lumps) are about 33 m from the middle
const HEIGHT := 16.5
const TRIES := 5
## Its ground, in its own frame: the whole gate, barracks and kitchen, the fallen tower half (x to 24), the moat
## (x from -25), the lumps and the yard in front (z to 22.5).
const LO := Vector2(-26.0, -17.0)
const HI := Vector2(25.0, 22.5)
const FILL_R := 1.6        ## the balls of rock the lumps and the wall are grown from
const FILL_STEP := 1.8
const FILLS_PER_FRAME := 20
const WALL_TOP := 20.0     ## the rock wall never grows higher than this
## The rock lumps: centre x, top, centre z; and how wide (m).
## F714 (owner, Nov 22: "the courtyard grew a big lump of mossy rock that should be level ground"): the first lump
## sat half in the yard in front of the grand stair; it now stands out in the corner past it, clear of the yard.
const LUMPS := [[Vector3(20.0, 2.6, 19.8), 2.5], [Vector3(22.0, 2.2, -3.5), 2.4]]
const MOAT_DEPTH := 2.5
static var built_origin := Vector3.INF
static var built_turn := 0

var room := -1
var _check := 0.0
var _fill: Array = []
var _grown := 0


## Its caverns, best first: Mossy's plain big caverns (not the start's, nor another ruin's), the widest first, each lot
## nearest 240 m from the start. Only the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [RuinOutpost.pick_room(maker), RuinBrewhall.pick_room(maker), int(maker.spire_spot.get("room", -1)),
		int(maker.manor_spot.get("room", -1)), int(maker.prow_hall_spot.get("room", -1))]
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


## Its ground in its own frame, every 2 m: under every piece of the whole gate and of its ruin (the fallen half too),
## the yard in front of the grand stair, the moat and the lumps. Not the rock wall it grows (a column may stand in
## that rock). [Vector2, ...]
static func ground() -> Array:
	if _ground.is_empty():
		var cells := {}
		for p in BlueprintLibrary.make(BLUEPRINT).pieces:
			cells[Vector2i(roundi(p.pos.x / 2.0), roundi(p.pos.z / 2.0))] = true
		for p in load_plan(PLAN_PATH).get("pieces", []):
			cells[Vector2i(roundi(float(p.pos[0]) / 2.0), roundi(float(p.pos[2]) / 2.0))] = true
		for x in range(-4, 7):
			for z in range(8, 12):
				cells[Vector2i(x, z)] = true  # the yard in front (x -8..12, z 16..22)
		for x in range(-13, 13):
			for z in range(-9, 12):
				var g := Vector2(x * 2.0, z * 2.0)
				if dip_at(g.x, g.y) < -0.2 or lump_at(g.x, g.y) > 0.2:
					cells[Vector2i(x, z)] = true  # the moat and the lumps
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


## True for ground under its buildings (not the moat, the lumps or the yard): how flat the floor is there counts.
static func _main_body(g: Vector2) -> bool:
	return g.y < 15.0 and g.x > -18.0 and g.x < 19.0


## The spot (in the first few caverns) with the flattest floor under its buildings, no column or other ruin on any of
## its ground, the least rock in the way; its gate turned toward the way you come from if it fits that way (else
## another way). Returns {room, pos, turn}.
static func pick(maker: CaveMaker, past_columns := false) -> Dictionary:
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
				var to: Vector3 = c0 - p  # the gate (local +z) faces the way you come from, if it can
				var facing := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
				var mid := maker.find_floor(p.x, p.z, rc.y)
				for k in 4:
					var turn := posmod(facing + [0, 1, 3, 2][k], 4)
					var basis := Basis(Vector3.UP, turn * PI / 2.0)
					var ok := true
					var inv := basis.inverse()
					for o in cols:
						if past_columns:
							break  # (its second try: the columns in the way are taken out after, see columns_in)
						if _column_in(o, p, inv):
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
						if q.y < mid.y - 3.0:
							ok = false  # a drop or a chasm under it
							break
						if _main_body(g):
							ys.append(q.y)
							lo = minf(lo, q.y)
							hi = maxf(hi, q.y)
							if (hi - lo) * 4.0 + [0, 5, 5, 10][k] >= best_score:
								ok = false  # already worse than the best spot so far (quick)
								break
					if not ok or ys.is_empty():
						continue
					ys.sort()
					var base: float = ys[0] - 0.05
					var rock := 0
					for h in [2.0, 6.0, 10.0, HEIGHT]:
						for sx in 6:
							for sz in 5:
								var o: Vector3 = basis * Vector3(lerpf(-18.0, 20.0, sx / 5.0), h, lerpf(-16.0, 20.0, sz / 4.0))
								if maker.sdf_at(Vector3(p.x, base, p.z) + o) < 0.0:
									rock += 1
					var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 1.0 + Vector2(gx, gz).length() * 0.3 + [0, 5, 5, 10][k]
					if score < best_score:
						best_score = score
						best = {room = best_room, pos = Vector3(p.x, base, p.z), turn = turn}
	return best


## A stone column (x, z, radius, twist) stands in its ground or too close (the placement rule, owner Nov 17).
static func _column_in(o: Vector4, p: Vector3, inv: Basis) -> bool:
	var l: Vector3 = inv * (Vector3(o.x, 0, o.y) - Vector3(p.x, 0, p.z))
	return clear_at(l.x, l.z) - 0.75 < o.z * 1.4 + 1.5


## The columns that stand in the Twin Gate at this spot (their numbers in maker._cols).
static func columns_in(maker: CaveMaker, spot: Dictionary) -> Array[int]:
	var inv := Basis(Vector3.UP, int(spot.turn) * PI / 2.0).inverse()
	var out: Array[int] = []
	for i in maker._cols.size():
		if _column_in(maker._cols[i], spot.pos, inv):
			out.append(i)
	return out


# ---------------------------------------------------------------- the cave's shape (F657)
static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _fbm(x: float, z: float) -> float:
	return RuinProwHall._fbm(x, z)


## The dry moat along the left tower's outside (x -25..-19, z -2..21) and in front of it (x -25..-10, z 16..21.5):
## how deep the floor goes (0 elsewhere, -2.5 at its deepest). The noise only pulls its edge back.
static func dip_at(x: float, z: float) -> float:
	var e1 := minf(minf(x + 25.0, -19.0 - x), minf(z + 2.0, 21.0 - z))
	var e2 := minf(minf(z - 16.0, 21.5 - z), minf(x + 25.0, -10.0 - x))
	var e := maxf(e1, e2) - 0.8 * _fbm(x * 0.4 + 2.0, z * 0.4)
	if e <= 0.0:
		return 0.0
	return -MOAT_DEPTH * _smooth(e / 1.8)


## The two rock lumps: their height at (x, z) (0 where there is none). A rough ledged dome, flat-ish on top.
static func lump_at(x: float, z: float) -> float:
	var top := 0.0
	for l in LUMPS:
		var c: Vector3 = l[0]
		var rad: float = l[1]
		var r := Vector2(x - c.x, z - c.z).length() + 0.9 * _fbm(x * 0.5 + 4, z * 0.5)
		if r >= rad:
			continue
		var u := c.y * (1.0 - _smooth((r - rad * 0.35) / (rad * 0.65)))
		top = maxf(top, RuinProwHall._ledges(u, 1.2) + (_fbm(x * 0.9, z * 0.9) - 0.5) * 0.4 * _smooth(u))
	return top


## The rock wall wrapped round the barracks' back (behind z -18) and back corners (left of x -15, right of x 19.5,
## fading out before z -6): its height (0 where there is none). The noise only pulls it back.
static func wall_at(x: float, z: float) -> float:
	var dx := maxf(maxf(-15.0 - x, x - 19.5), 0.0)
	var dz := maxf(-18.0 - z, 0.0)
	var s := minf(Vector2(dx, dz).length(), -6.0 - z) - 1.5 * _fbm(x * 0.12, z * 0.12)
	if s <= 0.0:
		return 0.0
	var h := 12.0 + 6.0 * _fbm(x * 0.05 + 3, z * 0.05) + 6.0 * _fbm(x * 0.16 + 1, z * 0.16 + 4)
	var w := RuinProwHall._ledges(h * _smooth(s / 4.0), 4.0) + (_fbm(x * 0.45, z * 0.45) - 0.5) * 2.6 * _smooth(s / 2.0)
	return clampf(w, 0.0, WALL_TOP)


## The rock the world grows round it, at (x, z) in its own frame (0 = none).
static func rock_at(x: float, z: float) -> float:
	return maxf(lump_at(x, z), wall_at(x, z))


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinTwinGate"
	drop_rubble = false   # (its rubble lies where the plan says: on floors and the ground line)
	stone_key = "stonehold_twin_gate"
	wood_key = "wooden_twin_gate"
	ruin_name = "twin_gate"
	hard_mat = "cut_stone"
	reach = REACH


## The Rebuilding Chest stands in front, beside the grand stair (x -6..6, its foot at z 15).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(8.5, 16.5), Vector2(-8.0, 16.5), Vector2(8.5, 18.5), Vector2(-7.5, 18.5), Vector2(7.5, 15.6), Vector2(-7.5, 15.6)]


func _path_z(_rad: float) -> float:
	return 19.0


func _ready() -> void:
	var st: String = auth.world_state.get("twin_gate", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Twin Gate
		return
	var spot: Dictionary = auth.world.maker.twin_gate_spot
	if spot.is_empty():
		spot = pick(auth.world.maker)
	if spot.is_empty():
		push_warning("RuinTwinGate: no cavern for the Twin Gate")
		queue_free()
		return
	room = spot.room
	auth.world.maker.rooms[room].kind = "ruin"  # rock beetles guard it (every run, also after it's built)
	origin = spot.pos
	turn = spot.turn
	if st != "pending":
		built_origin = origin
		built_turn = turn
		_swap_old_stairs()
		_fix_blocked_ways()
		_fix_right_stage()
		_fix_f811()
		_fix_f804()
		set_process(false)
		return
	_carve = carve_points(origin, turn)


## A Twin Gate built before Nov 22 still has its two spiral stairs (F713/F626, owner: "avoid the spiral stairs, they're
## breaking the game": you got stuck in the towers) and the railings round their tops. Host, once on loading: those
## old pieces come down and the plan's straight stairs and railings go in (only where nothing stands already).
const OLD_PIECES := [["stairs_spiral", Vector3(-9, 5.75, 8), 0], ["stairs_spiral", Vector3(9, 5.75, 8), 2],
	["railing", Vector3(-9, 7.75, 7), 0], ["railing", Vector3(9, 7.75, 7), 0], ["railing", Vector3(-13, 5.5, 7), 0],
	["floor", Vector3(-13, 5.25, 6), 0], ["floor", Vector3(-9, 5.5, 8), 0], ["floor", Vector3(9, 5.5, 8), 0]]
## (F565 🔁, Nov 22: the straight stairs stand on the floor, F169; the slab that lifted them goes with the spirals)
## (F783, Nov 23: the deck flights climb toward the gate now, their top at the stage's door; see FIX_F783)
const NEW_PIECES := [["stairs", Vector3(-9, 5.5, 8), 3], ["stairs", Vector3(9, 5.5, 8), 1],
	["railing", Vector3(-9, 7.75, 7), 0], ["railing", Vector3(9, 7.75, 7), 0], ["railing", Vector3(-14, 5.5, 6), 1],
	["railing", Vector3(-13, 5.5, 5), 0], ["railing", Vector3(-12, 5.5, 6), 1]]
## F783 (owner, Nov 23): a Twin Gate built (or rebuilt) before Nov 23 has a railing 0.7 m inside each tower's top
## door (it guarded the deck stairs' hole right behind the door) and a railing across the corner stairs' way out
## (they come out sideways). Host, once on loading: those railings come out, the deck stairs turn to climb toward
## the door (railings on their long sides).
const FIX_F783_OLD := [["railing", Vector3(-8, 7.75, 8), 1], ["railing", Vector3(8, 7.75, 8), 1],
	["railing", Vector3(-12, 5.5, 8), 1], ["railing", Vector3(14, 5.5, 8), 1],
	["stairs", Vector3(-9, 5.5, 8), 0], ["stairs", Vector3(9, 5.5, 8), 0]]
const FIX_F783_NEW := [["stairs", Vector3(-9, 5.5, 8), 3], ["stairs", Vector3(9, 5.5, 8), 1],
	["railing", Vector3(-9, 7.75, 7), 0], ["railing", Vector3(9, 7.75, 7), 0]]
## (Those deck stairs then move again for F811, see FIX_F811.)


func _swap_old_stairs() -> int:
	var found := _find_pieces(OLD_PIECES)
	if not found.values().has("stairs_spiral"):
		return 0  # (a newer Twin Gate, or the old stairs are already gone)
	var added := _swap(found, NEW_PIECES)
	print("TWIN_GATE swapped its old spiral stairs: %d old pieces down, %d new up" % [found.size(), added])
	return added


## F783: takes out the railings that blocked the towers' top doors and the corner stairs' way out (FIX_F783_OLD).
## Returns how many pieces went in (0: nothing to fix).
func _fix_blocked_ways() -> int:
	var found := _find_pieces(FIX_F783_OLD)
	if found.is_empty():
		return 0
	var added := _swap(found, FIX_F783_NEW)
	print("TWIN_GATE cleared its blocked doors and stairs: %d old pieces down, %d new up" % [found.size(), added])
	return added


## F783 round 3 (robot walk, Nov 23): the right tower's round stage (only there once rebuilt: it is in the fallen
## half) had its first stairs climbing the same way as the left one's, so their foot sat behind a gap too narrow for
## the dwarf. A stage rebuilt before then: those stairs turn round and their railing upstairs moves to the other end.
const FIX_F783_STAGE_OLD := [["stairs", Vector3(11, 8.0, 5.2679), 1], ["railing", Vector3(12, 10.0, 5.2679), 3]]
const FIX_F783_STAGE_NEW := [["stairs", Vector3(11, 8.0, 5.2679), 3], ["railing", Vector3(10, 10.0, 5.2679), 3]]


## Turns the right stage's first stairs round (FIX_F783_STAGE_OLD), each new piece in the old one's material.
## Returns how many pieces went in (0: nothing to fix).
func _fix_right_stage() -> int:
	var found := _find_pieces(FIX_F783_STAGE_OLD)
	if not found.values().has("stairs"):
		return 0
	var b: Builder = auth.builder
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var had := {}
	for uid in found:
		had[found[uid]] = String(b.structure.pieces[uid].family)
		b._ev_remove_piece.rpc(uid)
	var added := 0
	for n in FIX_F783_STAGE_NEW:
		var pos: Vector3 = origin + basis * (n[1] as Vector3)
		var rot: int = Pieces.add_rot(int(n[2]), turn)
		if not had.has(n[0]) or not b.structure.overlapping(n[0], pos, rot).is_empty():
			continue
		b._ev_add_piece.rpc(b._next_uid, String(n[0]), String(had[n[0]]), pos, rot, false)
		added += 1
	print("TWIN_GATE turned the right stage's stairs round: %d old pieces down, %d new up" % [found.size(), added])
	return added


## F811 (owner, Nov 23: "every staircase needs a whole free block after it; don't make half-railing models, rebuild
## the spot"): the deck stairs used to climb toward the stage's door, their top 0.7 m from it, and the round stage
## was fenced off from them. They now stand in the stage's middle and climb toward the back. Per tower (x sign):
## the old stairs, the railings round their hole (full or the short one an unfinished fix used) and the deck floor
## where the new hole goes come out; the new stairs, their three railings and the floor over the old hole go in.
const FIX_F811_OLD := [["stairs", Vector3(-9, 5.5, 8), 3], ["railing", Vector3(-9, 7.75, 9), 0],
	["railing", Vector3(-10, 7.75, 8), 1], ["railing", Vector3(-9, 7.75, 7), 0], ["railing_narrow", Vector3(-9.5, 7.75, 7), 0],
	["floor", Vector3(-11, 7.5, 10), 0]]
const FIX_F811_NEW := [["stairs", Vector3(-11, 5.5, 10), 0], ["floor", Vector3(-9, 7.5, 8), 0],
	["railing", Vector3(-12, 7.75, 10), 1], ["railing", Vector3(-10, 7.75, 10), 1], ["railing", Vector3(-11, 7.75, 11), 0]]


## The left tower's FIX_F811 lists for tower `side` (-1 left, +1 right: mirrored in x, its stairs turned to match).
static func f811_list(list: Array, side: int) -> Array:
	var out := []
	for o in list:
		var p: Vector3 = o[1]
		var rot: int = o[2]
		if side == 1:
			p.x = -p.x
			if o[0] == "stairs" and rot == 3:
				rot = 1  # (the old right stairs climbed the mirrored way)
		out.append([o[0], p, rot])
	return out


## Moves each tower's deck stairs (FIX_F811). A rebuilt tower (the old deck floor is there) gets every new piece; a
## ruined one only those the plan has (the right tower's deck is half fallen: no railings in the air). Nothing changes
## in a tower where a new piece's spot is taken by something else. Returns how many pieces went in.
func _fix_f811() -> int:
	var b: Builder = auth.builder
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var added := 0
	for side in [-1, 1]:
		var old := f811_list(FIX_F811_OLD, side)
		var found := _find_pieces(old)
		var mat := ""
		var rebuilt := false
		for uid in found:
			var q: Dictionary = b.structure.pieces[uid]
			if q.piece == "stairs":
				mat = String(q.family)
			rebuilt = rebuilt or q.piece == "floor"
		if mat == "":
			continue  # (a newer Twin Gate, or this tower's old deck stairs are gone)
		var todo := []
		var blocked := false
		for n in f811_list(FIX_F811_NEW, side):
			var in_plan: bool = plan.get("pieces", []).any(func(p): return String(p.id) == n[0] and int(p.rot) == n[2] and Vector3(p.pos[0], p.pos[1], p.pos[2]).distance_to(n[1]) < 0.05)
			if not (rebuilt or in_plan):
				continue
			var pos: Vector3 = origin + basis * (n[1] as Vector3)
			var rot: int = Pieces.add_rot(int(n[2]), turn)
			for uid in b.structure.overlapping(n[0], pos, rot):
				if not found.has(uid) and not (n[0] == "floor" and b.structure.pieces[uid].piece == "floor"):
					blocked = true
			todo.append([n[0], pos, rot])
		if blocked or todo.is_empty():
			continue  # (something else stands where the new stairs go: leave this tower as it is)
		for uid in found:
			b._ev_remove_piece.rpc(uid)
		for t in todo:
			if t[0] == "floor" and not b.structure.overlapping("floor", t[1], t[2]).is_empty():
				continue  # (a floor already lies there)
			b._ev_add_piece.rpc(b._next_uid, String(t[0]), mat, t[1], t[2], false)
			added += 1
		print("TWIN_GATE moved tower %d's deck stairs to the stage's middle (F811): %d old pieces down, %d new up" % [side, found.size(), added])
	return added


## F804 (owner, Nov 23: "the railings on the stairs that are diagonal, they're still floating"): the towers' first
## stairs sit 25 cm lower than they were planned (on the floor, F169) but their stair railing stayed up. A Twin Gate
## built before then: that railing comes down 25 cm (same material). Returns how many moved.
const FIX_F804_OLD := [["railing_stairs", Vector3(-10, 1.25, 10), 1], ["railing_stairs", Vector3(10, 1.25, 10), 1]]


func _fix_f804() -> int:
	var b: Builder = auth.builder
	var found := _find_pieces(FIX_F804_OLD)
	for uid in found:
		var q: Dictionary = b.structure.pieces[uid]
		var mat := String(q.family)
		var pos: Vector3 = q.pos - Vector3(0, 0.25, 0)
		var rot: int = q.rot
		b._ev_remove_piece.rpc(uid)
		b._ev_add_piece.rpc(b._next_uid, "railing_stairs", mat, pos, rot, false)
	if not found.is_empty():
		print("TWIN_GATE lowered %d floating stair railings (F804)" % found.size())
	return found.size()


## The pieces of `list` ([id, spot in the plan, rot]) standing in the world: uid -> [id, material].
func _find_pieces(list: Array) -> Dictionary:
	var b: Builder = auth.builder
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var found := {}
	for o in list:
		var pos: Vector3 = origin + basis * (o[1] as Vector3)
		var rot: int = Pieces.add_rot(int(o[2]), turn)
		for uid in b.structure.near(Pieces.box(o[0], pos, rot)):
			var q: Dictionary = b.structure.pieces[uid]
			if q.piece == o[0] and q.rot == rot and (q.pos as Vector3).distance_to(pos) < 0.05:
				found[uid] = String(q.piece)
	return found


## Takes the `found` pieces down and puts `new` in where nothing stands, each in the material the same kind of piece
## had (a wooden rebuild keeps its look), else the plan's. Only pieces the plan has (never into the right tower's
## fallen half).
func _swap(found: Dictionary, new: Array) -> int:
	var b: Builder = auth.builder
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var had := {}
	var spots := []  # [where an old piece stood, its material]
	for uid in found:
		had[found[uid]] = String(b.structure.pieces[uid].family)
		spots.append([b.structure.pieces[uid].pos, String(b.structure.pieces[uid].family)])
		b._ev_remove_piece.rpc(uid)
	var added := 0
	for n in new:
		var mat := ""
		for p in plan.get("pieces", []):
			if String(p.id) == n[0] and int(p.rot) == n[2] and Vector3(p.pos[0], p.pos[1], p.pos[2]).distance_to(n[1]) < 0.05:
				mat = String(p.mat)
		if mat != "":
			mat = String(had.get(n[0], mat))
		var pos: Vector3 = origin + basis * (n[1] as Vector3)
		var rot: int = Pieces.add_rot(int(n[2]), turn)
		if mat == "":
			# F811: a later fix moved this piece out of the plan (the deck stairs moved twice). It still goes in where
			# an old piece came out right beside it (that tower stands), so the next fix can move it on.
			for sp in spots:
				if (sp[0] as Vector3).distance_to(pos) < 2.5:
					mat = String(had.get(n[0], sp[1]))
		if mat == "" or not b.structure.overlapping(n[0], pos, rot).is_empty():
			continue
		b._ev_add_piece.rpc(b._next_uid, String(n[0]), mat, pos, rot, false)
		added += 1
	return added


## Digs a box of its own frame (x0..x1, z0..z1, from y0 up to 4.5 m), never into its own rock. y0 1.5 digs down to
## 0.4 m (the yards: the ground stays); 0.9 down to the floor (where pieces stand on it).
static func _dig_box(out: Array, at: Vector3, basis: Basis, x0: float, x1: float, z0: float, z1: float, y0 := 1.5) -> void:
	var y := y0
	while y <= 4.5:
		var x := x0
		while x <= x1:
			var z := z0
			while z <= z1:
				if y - CARVE_RADIUS >= rock_at(x, z) - 0.3 and dip_at(x, z) > -0.3:
					out.append(at + basis * Vector3(x, y, z))
				z += 1.2
			x += 1.2
		y += 1.2


## What it digs (ordinary digs: saved and sent to friends), in world space: the blueprint's own air cells (only round
## the buildings; never into its rock), the yard in front, the ground where the right tower fell, and the moat.
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
	_dig_box(out, at, basis, -9.0, 13.0, 15.0, 22.5)   # the yard in front of the grand stair
	_dig_box(out, at, basis, 13.0, 25.0, -2.0, 15.0, 0.9)   # where the right tower's outer half fell, and its buttresses' feet
	_dig_box(out, at, basis, -12.0, 12.0, -5.0, 3.0)   # the drill yard: level ground (F714), the cave floor never pokes up
	var x := -26.0
	while x <= -8.0:  # the moat: from its floor up to 5 m
		var z := -3.0
		while z <= 22.5:
			var h := dip_at(x, z)
			if h < -0.3:
				var y := h + 1.0
				while y <= 5.0:
					out.append(at + basis * Vector3(x, y, z))
					y += 1.2
			z += 1.2
		x += 1.2
	return out


## Where it grows rock (after the digging): the lumps and the wall, balls of rock from the top of each column down to
## the rock that's already there. Only where the cave is open (no ball is wasted inside solid rock).
func _fill_points() -> Array:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var out := []
	var x := LO.x - 6.0
	while x <= HI.x + 4.0:
		var z := LO.y - 8.0
		while z <= HI.y + 2.0:
			var h := rock_at(x, z)
			if h > 0.8:
				var y := h - FILL_R
				var started := false
				while y >= -4.0:
					var w: Vector3 = origin + basis * Vector3(x, y, z)
					var solid: bool = auth.world.sdf_at(w) < -(FILL_R - 0.2)  # (a ball that still reaches the air counts: on high ground too)
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
		print("RUIN_TWIN_GATE growing its rock: %d balls" % _fill.size())
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
		auth.world_state["twin_gate"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_TWIN_GATE built at %s (turn %d), %d balls of rock grown" % [origin, turn, _grown])
		_state = "done"
		set_process(false)
		return
	super(delta)
