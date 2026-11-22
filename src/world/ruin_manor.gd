class_name RuinManor
extends RuinTower
## The Hearth Manor (owner, Nov 22, F479): the seventh ruin, a big clay-brick dwarf manor house: a main hall on a
## terrace, a wing with a balcony and a 4-storey lookout tower, half fallen in. It is long (about 36 x 16 m, 13.5 m
## tall when whole), so it needs one of the biggest Mossy caverns, about 200 m from the start. Its plan is
## blueprints/ruins/manor_ruin.json (tools/ruins/make_manor_ruin.py). Works like the Brewhall (ruin_brewhall.gd): the
## world remembers "manor: pending" and builds it the first time someone comes close enough for its rock to load; the
## spot only depends on the world's seed. Rebuilt with root planks or clay bricks; rock beetles guard its cavern.

const PLAN_PATH := "res://blueprints/ruins/manor_ruin.json"
const WANT_DIST := 200.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
const HALF_X := 18.5       ## half its length (the whole manor: x -18..18 in its own frame)
const BACK := 8.5          ## how far behind its middle it reaches (z -8)
const FRONT := 10.5        ## how far in front: its terrace steps (z 6..8) and the Rebuilding Chest
const TRIES := 5           ## how many caverns it looks at (the best spot of them wins)
static var built_origin := Vector3.INF  ## where it was built in this run (tests look there)
static var built_turn := 0

var room := -1
var _check := 0.0


## The caverns it may stand in, best first: Mossy's plain big caverns (not the start's, the outpost's, the Brewhall's
## or the Spire's), the wide ones first (it is 36 m long), each lot nearest 200 m from the start. Only the seed.
static func rooms_to_try(maker: CaveMaker) -> Array[int]:
	var c0 := maker.cavern_spawn
	var taken := [RuinOutpost.pick_room(maker), RuinBrewhall.pick_room(maker), int(maker.spire_spot.get("room", -1))]
	var found: Array = []
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if i in taken or not rm.big or rm.get("biome", "mossy") != "mossy" or rm.get("kind", "") not in ["cavern", "ruin"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d < 60.0:
			continue
		var r: Vector3 = rm.radii
		found.append([0 if maxf(r.x, r.z) >= 16.0 else 1, absf(d - WANT_DIST), i])
	found.sort()
	var out: Array[int] = []
	for f in found:
		out.append(int(f[2]))
	return out


## The spot (in the first few caverns) with the flattest floor under its whole long body and the least rock in the
## way, its front door turned toward the way you come from. Returns {room, pos, turn} or {}.
static func pick(maker: CaveMaker, height: float) -> Dictionary:
	var c0 := maker.cavern_spawn
	var best := {}
	var best_score := INF
	var rooms := rooms_to_try(maker)
	for best_room in rooms.slice(0, TRIES):
		var rc: Vector3 = maker.rooms[best_room].center
		for gx in range(-3, 4):
			for gz in range(-3, 4):
				var p := rc + Vector3(gx * 4.0, 0, gz * 4.0)
				var to: Vector3 = c0 - p  # the front door (local +z) faces the way you come from
				var turn := posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)
				var basis := Basis(Vector3.UP, turn * PI / 2.0)
				var mid := maker.find_floor(p.x, p.z, rc.y)
				var ys := []
				var ok := true
				for sx in 13:
					for sz in 7:
						var o: Vector3 = basis * Vector3(lerpf(-HALF_X, HALF_X, sx / 12.0), 0, lerpf(-BACK, FRONT - 1.0, sz / 6.0))
						if maker._in_column(p + o, 1.5):
							ok = false  # a stone column would stand in it (the placement rule)
							break
						var q := maker.find_floor(p.x + o.x, p.z + o.z, mid.y + 4.0)
						if q.y < mid.y - 3.0:
							ok = false  # a drop or a chasm under it
							break
						ys.append(q.y)
					if not ok:
						break
				if not ok:
					continue
				ys.sort()
				var base: float = ys[0] - 0.05
				var rock := 0
				for h in [2.0, 5.0, 8.0, height]:
					for sx in 5:
						for sz in 3:
							var o: Vector3 = basis * Vector3(lerpf(-HALF_X, HALF_X, sx / 4.0) * 0.85, h, lerpf(-BACK, FRONT - 2.0, sz / 2.0) * 0.85)
							if maker.sdf_at(Vector3(p.x, base, p.z) + o) < 0.0:
								rock += 1
				var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 1.0 + Vector2(gx, gz).length() * 0.3
				if score < best_score:
					best_score = score
					best = {room = best_room, pos = Vector3(p.x, base, p.z), turn = turn}
	return best


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinManor"
	drop_rubble = false
	stone_key = "hearthbrick_manor"
	wood_key = "wooden_manor"
	ruin_name = "manor"
	hard_mat = "clay_brick"
	reach = 21.0   # its far corners are about 20 m from the middle (36 x 16 m)


## The Rebuilding Chest stands in front of the terrace, beside its steps (x -1..3, z 6..8).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(5.4, 9.0), Vector2(-3.4, 9.0), Vector2(5.4, 10.0), Vector2(-3.4, 10.0), Vector2(7.0, 8.6), Vector2(-5.0, 8.6)]


func _path_z(_rad: float) -> float:
	return 9.6


func _ready() -> void:
	var st: String = auth.world_state.get("manor", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no manor
		return
	var spot: Dictionary = auth.world.maker.manor_spot
	if spot.is_empty():
		spot = pick(auth.world.maker, float(plan.get("height", 13.5)))
	if spot.is_empty():
		push_warning("RuinManor: no cavern for the Hearth Manor")
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
	# Carve its space: its whole long box plus a margin, from about its ground line up to its top (ordinary digs:
	# saved and sent to friends).
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var top: float = float(plan.get("height", 13.5)) + 0.8
	var y := 0.9
	while y <= top:
		var x := -HALF_X - 1.0
		while x <= HALF_X + 1.0:
			var z := -BACK - 1.0
			while z <= FRONT:
				_carve.append(origin + basis * Vector3(x, y, z))
				z += 1.2
			x += 1.2
		y += 1.2


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = HALF_X + 2.0
		var box := AABB(origin + Vector3(-half, -2.0, -half), Vector3(half * 2.0, float(plan.get("height", 13.5)) + 3.5, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			_state = "carve"
		return
	if _state == "build":
		_build()
		auth.world_state["manor"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_MANOR built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)
