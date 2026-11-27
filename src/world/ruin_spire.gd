class_name RuinSpire
extends RuinTower
## The Lantern Spire (owner, Nov 20, F479): the fourth ruin, a tall thin round Stonehold beacon tower whose top half
## snapped off and lies across the cave floor (the fallen top, a curved piece of wall, its fire bowl, rubble). A
## landmark to FIND: it stands in a tall Mossy cavern about 130 m from the start, with no flat base dug round it (owner,
## Nov 20): only the tower's own space is carved, and the wreckage lies on the cave's own floor. Its plan is
## blueprints/ruins/spire_ruin.json (tools/ruins/make_spire_ruin.py). Works like the Brewhall (ruin_brewhall.gd): the
## world remembers "spire: pending" and builds it the first time someone comes close enough for its rock to load; the
## spot only depends on the world's seed. Rebuilt with root planks or cut stone; rock beetles guard its cavern.

const PLAN_PATH := "res://blueprints/ruins/spire_ruin.json"
const WANT_DIST := 130.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const REACH := 21.0        ## its wreckage lies up to about 19 m from the middle
## How much higher the ground may be under one part of a fallen piece than another (it lies on the lowest part,
## so nothing floats; the rest sinks a little into the floor).
const FLAT := 1.5
const TALL := 8.0          ## a cavern this tall (its half height, m) or more: room for an 11.6 m tower
## The wreckage: big pieces lying on the cave floor (dropped onto it, like rubble), cleared when it's rebuilt.
const WRECKAGE := ["spire_top_fallen", "spire_wall_chunk", "beacon_bowl_fallen"]
static var built_origin := Vector3.INF  ## where it was built in this run (tests look there)
static var built_turn := 0

var room := -1
var _check := 0.0


## The caverns it may stand in, best first: Mossy's plain big caverns (not the start's, the outpost's or the
## Brewhall's), the tall ones first, each lot nearest 130 m from the start. Only depends on the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [RuinOutpost.pick_room(maker), RuinBrewhall.pick_room(maker)]
	var found: Array = []
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if i in taken or not rm.big or rm.get("biome", "mossy") != "mossy" or rm.get("kind", "") not in ["cavern", "ruin"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d < 45.0:
			continue
		var tall: bool = (rm.radii as Vector3).y >= TALL
		found.append([0 if tall else 1, absf(d - WANT_DIST), i])
	found.sort()
	var out: Array[int] = []
	for f in found:
		out.append(int(f[2]))
	return out


## Where each big piece of wreckage touches the ground, in the ruin's own frame (x right, z toward the door): its
## middle and four spots toward its corners. Both the spot picker and the builder measure the ground there.
static func wreck_feet(plan: Dictionary) -> Array:
	var out := []
	for p in plan.get("pieces", []):
		if not String(p.id) in WRECKAGE:
			continue
		var s: Vector3 = Pieces.LIST[String(p.id)].size
		var b := Basis(Vector3.UP, Pieces.yaw_of(int(p.rot)))
		var at := Vector3(float(p.pos[0]), 0.0, float(p.pos[2]))
		var pts: Array[Vector3] = []
		for o in [Vector3.ZERO, Vector3(0.35, 0, 0.35), Vector3(-0.35, 0, 0.35), Vector3(0.35, 0, -0.35), Vector3(-0.35, 0, -0.35)]:
			pts.append(at + b * (o * s))
		out.append(pts)
	return out


## Every spot the wreckage covers (its feet, and the heaps of rubble out on the floor), in the ruin's own frame.
static func wreck_spots(plan: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for pts in wreck_feet(plan):
		out.append_array(pts)
	for p in plan.get("pieces", []):
		if String(p.id) in RUBBLE and absf(float(p.pos[1])) < 0.3:
			out.append(Vector3(float(p.pos[0]), 0.0, float(p.pos[2])))
	return out


## The lowest and highest cave floor under these world spots, looked for from `from_y` down (x = low, y = high;
## high = INF when a spot is inside rock even there).
static func ground_under(maker: CaveMaker, pts: Array, from_y: float) -> Vector2:
	var g := Vector2(INF, -INF)
	for q: Vector3 in pts:
		if maker.sdf_at(Vector3(q.x, from_y, q.z)) <= 0.0:
			return Vector2(g.x, INF)
		var y := maker.find_floor(q.x, q.z, from_y).y
		g = Vector2(minf(g.x, y), maxf(g.y, y))
	return g


## Open, fairly level ground for 10 m in front of its door (owner rule, F350: the way in can't be blocked or buried):
## never higher than the doorstep (1 m up), never a drop.
static func door_is_open(maker: CaveMaker, p: Vector3, base: float, basis: Basis) -> bool:
	for z in [5.5, 7.0, 8.5, 10.0]:
		for x in [-1.2, 0.0, 1.2]:
			var at: Vector3 = p + basis * Vector3(x, 0, z)
			if maker.sdf_at(Vector3(at.x, base + 4.0, at.z)) <= 0.0:
				return false
			var f := maker.find_floor(at.x, at.z, base + 4.0).y
			if f > base + 1.1 or f < base - 1.5:
				return false
	return true


## Where it goes: in the first cavern from rooms_to_try with room for it, the spot whose floor is flattest under the
## tower and under each piece of its wreckage, with the least rock in the tower's way, and no stone column anywhere
## near (the placement rule: nothing the world grows stands in the tower or on its wreckage). Returns {room, pos, turn}
## or {}. When no cavern has fairly flat ground for the fallen top, the best spot found anywhere.
static func pick(maker: CaveMaker, plan: Dictionary) -> Dictionary:
	var c0 := maker.cavern_spawn
	var rad := float(plan.get("radius", 4.2))
	var height := float(plan.get("height", 12.0))
	var feet := wreck_feet(plan)
	var wreck := wreck_spots(plan)
	var rubble: Array[Vector3] = []
	for p in plan.get("pieces", []):
		if String(p.id) in RUBBLE and absf(float(p.pos[1])) < 0.3:
			rubble.append(Vector3(float(p.pos[0]), 0.0, float(p.pos[2])))
	var loose := {}
	var loose_score := INF
	for ri in rooms_to_try(maker):
		var rc: Vector3 = maker.rooms[ri].center
		var best := {}
		var best_score := INF
		for gx in range(-5, 6):
			for gz in range(-5, 6):
				var p := rc + Vector3(gx * 3.0, 0, gz * 3.0)
				if maker._in_column(p, rad + 2.0):
					continue  # a stone column would stand in the tower
				var mid := maker.find_floor(p.x, p.z, rc.y)
				var ys := [mid.y]
				var ok := true
				for i in 12:
					var a := i * TAU / 12.0
					var q := maker.find_floor(p.x + cos(a) * rad, p.z + sin(a) * rad, mid.y + 3.0)
					if q.y < mid.y - 2.5 or q.y > mid.y + 2.9:
						ok = false  # a drop, a chasm or a lump of rock under the tower
						break
					ys.append(q.y)
				if not ok:
					continue
				ys.sort()
				var base: float = ys[0] - 0.05  # the lowest ground under it: the tower always stands on the floor
				var to: Vector3 = c0 - p  # the door (local +z) faces the way you come from
				var turn := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
				var basis := Basis(Vector3.UP, turn * PI / 2.0)
				if not door_is_open(maker, p, base, basis):
					continue  # its door would open onto a wall or a bank of earth
				var bumps := 0.0
				var flat := true
				for w in wreck:
					if maker._in_column(p + basis * w, 1.5):
						ok = false  # a stone column would stand on its wreckage
						break
				for pts in feet:
					if not ok:
						break
					var g := ground_under(maker, (pts as Array).map(func(w): return p + basis * w), base + 5.0)
					if g.x < base - 2.5 or g.y > base + 2.5:
						ok = false  # its wreckage would lie over a drop or in a wall
						break
					bumps += (g.y - g.x) * 3.0 + absf(g.x - base) * 0.5
					if g.y - g.x > FLAT:
						flat = false  # one end of it would be buried deep in a slope
				if not ok:
					continue
				var rock := 0
				for w in rubble:
					var at: Vector3 = p + basis * w
					var f := maker.find_floor(at.x, at.z, base + 3.0)
					if f.y < base - 2.5 or f.y > base + 2.9:
						rock += 2  # (a heap of rubble lost down a drop or in a wall)
				for h in [1.5, 4.0, 7.0, 10.0, height, height + 2.5]:
					for i in 7:
						var b := i * TAU / 6.0
						var rr := 0.0 if i == 6 else rad * 0.85
						if maker.sdf_at(Vector3(p.x + cos(b) * rr, base + h, p.z + sin(b) * rr)) < 0.0:
							rock += 1
				var score: float = (ys[-1] - ys[0]) * 4.0 + bumps + rock * 1.5 + Vector2(gx, gz).length() * 0.3
				var spot := {room = ri, pos = Vector3(p.x, base, p.z), turn = turn}
				if flat and score < best_score:
					best_score = score
					best = spot
				if score < loose_score:
					loose_score = score
					loose = spot
		if not best.is_empty():
			return best
	return loose


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinSpire"
	drop_rubble = true      # (no flat base: its rubble lies on the cave's own floor)
	stone_key = "lantern_spire"
	wood_key = "wooden_spire"
	ruin_name = "spire"
	reach = REACH
	worn_over = 2.35        # its Stonehold floors are 2.25 m apart (Builder._worn_to_go)


## The Rebuilding Chest stands in front of the door, on the left of the steps (the wreckage fell to the right).
func _chest_spots(rad: float) -> Array[Vector2]:
	return [Vector2(-3.4, rad + 1.6), Vector2(-3.4, rad + 3.0), Vector2(-4.6, rad + 0.8), Vector2(-2.8, rad + 4.2),
		Vector2(3.4, rad + 1.6), Vector2(3.4, rad + 3.0)]


func _ready() -> void:
	var st: String = auth.world_state.get("spire", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Spire
		return
	var spot: Dictionary = auth.world.maker.spire_spot
	if spot.is_empty():
		spot = pick(auth.world.maker, plan)
	if spot.is_empty():
		push_warning("RuinSpire: no cavern for the Lantern Spire")
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
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	plan = plan.duplicate(true)
	_lay_wreckage(basis)
	# Carve the tower's own space only (no flat base round it, owner): its round body from just above the ground line
	# up past its top, the corridor of its front steps, and the air over its fallen top, wall piece and bowl.
	var r: float = float(plan.get("radius", 4.2)) + 0.4
	var top: float = float(plan.get("height", 12.0)) + 0.6
	var y := 1.7
	while y <= top:
		var x := -r
		while x <= r:
			var z := -r
			while z <= float(plan.get("front", 6.8)):
				if Vector2(x, z).length() <= r or (absf(x) <= 2.6 and z > 0.0 and y <= 2.5):
					_carve.append(origin + basis * Vector3(x, y, z))
				z += 1.2
			x += 1.2
		y += 1.2
	for p in plan.get("pieces", []):
		if not String(p.id) in WRECKAGE:
			continue
		var s: Vector3 = Pieces.LIST[String(p.id)].size
		var b := basis * Basis(Vector3.UP, Pieces.yaw_of(int(p.rot)))
		var at: Vector3 = origin + basis * Vector3(float(p.pos[0]), float(p.pos[1]), float(p.pos[2]))
		var cy := 0.9
		while cy <= s.y + 0.4:
			var cx := -s.x * 0.5 + 0.4
			while cx <= s.x * 0.5 - 0.3:
				var cz := -s.z * 0.5 + 0.4
				while cz <= s.z * 0.5 - 0.3:
					_carve.append(at + b * Vector3(cx, cy, cz))
					cz += 1.2
				cx += 1.2
			cy += 1.2


## The fallen top, wall piece and fire bowl lie on the cave's own floor (it isn't flat here): each one is dropped to
## the lowest floor under it (measured as pick() did), so no end floats (higher ground hides a little of it instead).
func _lay_wreckage(basis: Basis) -> void:
	var maker: CaveMaker = auth.world.maker
	var feet := wreck_feet(plan)
	var k := 0
	for p in plan.get("pieces", []):
		if not String(p.id) in WRECKAGE:
			continue
		var g := ground_under(maker, (feet[k] as Array).map(func(w): return origin + basis * w), origin.y + 5.0)
		k += 1
		if is_finite(g.x):
			p.pos[1] = snappedf(g.x - 0.05 - origin.y, 0.01)


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half := REACH
		var box := AABB(origin + Vector3(-half, -2.0, -half), Vector3(half * 2.0, float(plan.get("height", 12.0)) + 3.5, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(origin + Vector3.UP * 4.0, REACH):
			_state = "carve"
		return
	if _state == "build":
		if not _build():
			return  # (a little each frame, F417)
		auth.world_state["spire"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_SPIRE built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)
