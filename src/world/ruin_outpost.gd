class_name RuinOutpost
extends RuinTower
## The Fallen Outpost (owner, Nov 17): the big ruined stone fort, in a plain big cavern of Mossy Hollows about
## 160 m from the start. Its plan is blueprints/ruins/outpost_ruin.json (tools/ruins/make_outpost_ruin.py).
## It is far away, so its rock isn't loaded when the world is made: the world remembers "outpost: pending" (saved
## with the world) and the fort is built the first time someone comes close enough for its rock to load.
## Where it goes only depends on the world's seed, so it's found again after loading. Rock beetles guard its
## cavern (the room is marked "outpost"; the monster code spawns beetles there). New worlds only.

const OUTPOST_PLAN := "res://blueprints/ruins/outpost_ruin.json"
const WANT_DIST := 160.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
static var built_origin := Vector3.INF  ## where it was built in this run (the outpostcheck robot looks there)
static var built_turn := 0

var room := -1
var _check := 0.0


## Which cavern: of Mossy's plain big caverns, the one nearest 160 m from the start (-1: none). Cheap and only
## depends on the seed, so every computer gets the same answer (PoiField leaves that cavern's old columns out).
static func pick_room(maker: CaveMaker) -> int:
	var c0 := maker.cavern_spawn
	var best_room := -1
	var best_d := INF
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if not rm.big or rm.get("biome", "mossy") != "mossy" or rm.get("kind", "") not in ["cavern", "outpost"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d > 70.0 and absf(d - WANT_DIST) < best_d:
			best_d = absf(d - WANT_DIST)
			best_room = i
	return best_room


## The spot in that cavern with the flattest floor and the least rock in the way. Returns {room, pos, turn} or {}.
static func pick(maker: CaveMaker, half: float, height: float) -> Dictionary:
	var c0 := maker.cavern_spawn
	var best_room := pick_room(maker)
	if best_room < 0:
		return {}
	var rc: Vector3 = maker.rooms[best_room].center
	var best := {}
	var best_score := INF
	for gx in range(-3, 4):
		for gz in range(-3, 4):
			var p := rc + Vector3(gx * 4.0, 0, gz * 4.0)
			var mid := maker.find_floor(p.x, p.z, rc.y)
			var ys := []
			var ok := true
			for sx in 5:
				for sz in 5:
					var q := maker.find_floor(p.x + (sx - 2) * half / 2.0, p.z + (sz - 2) * half / 2.0, mid.y + 4.0)
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
			for h in [2.0, 4.0, height]:
				for sx in 3:
					for sz in 3:
						if maker.sdf_at(Vector3(p.x + (sx - 1) * half * 0.8, base + h, p.z + (sz - 1) * half * 0.8)) < 0.0:
							rock += 1
			var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 0.8 + Vector2(gx, gz).length() * 0.3
			if score < best_score:
				best_score = score
				var to: Vector3 = c0 - p  # the gate (local +z) faces the way you come from
				best = {room = best_room, pos = Vector3(p.x, base, p.z), turn = posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)}
	return best


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinOutpost"
	drop_rubble = false
	stone_key = "stone_outpost"   # (owner, Nov 20, F478: rebuildable like the watchtower)
	wood_key = "wooden_outpost"
	ruin_name = "outpost"
	reach = 26.0                  # its corners are 25.5 m from the middle (36 x 36 m), the gate halves lie outside


## The Rebuilding Chest stands in front of the gatehouse, beside the way in (the torn-off gate halves lie at x ±4.3).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(7.0, 17.2), Vector2(-7.0, 17.2), Vector2(7.0, 18.6), Vector2(-7.0, 18.6), Vector2(2.2, 19.2), Vector2(-2.2, 19.2)]


func _path_z(_rad: float) -> float:
	return 18.6


func _ready() -> void:
	var st: String = auth.world_state.get("outpost", "")
	plan = load_plan(OUTPOST_PLAN)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no outpost
		return
	var half: float = float(plan.get("radius", 18.5))
	var spot: Dictionary = auth.world.maker.outpost_spot
	if spot.is_empty():
		spot = pick(auth.world.maker, half, float(plan.get("height", 7.5)))
	if spot.is_empty():
		push_warning("RuinOutpost: no cavern for the outpost")
		queue_free()
		return
	room = spot.room
	auth.world.maker.rooms[room].kind = "outpost"  # beetles guard it (every run, also after it's built)
	origin = spot.pos
	turn = spot.turn
	if st != "pending":
		built_origin = origin
		built_turn = turn
		if _has_chest():
			set_process(false)
		else:
			_state = "chest_wait"  # built before it was rebuildable (Nov 20): add its Rebuilding Chest once its rock loads
		return
	# Carve its space: the whole square plus a margin, down to about its ground line, up to its top (ordinary digs:
	# saved and sent to friends). Owner: carving from higher up left rock bumps that buried doorways and steps.
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var r := half + 1.5
	var front: float = float(plan.get("front", half)) + 1.5
	var top: float = float(plan.get("height", 7.5)) + 0.8
	var y := 0.9
	while y <= top:
		var x := -r
		while x <= r:
			var z := -r
			while z <= front:
				_carve.append(origin + basis * Vector3(x, y, z))
				z += 1.2
			x += 1.2
		y += 1.2


## Its Rebuilding Chest is already in the world record. Outposts built Nov 19-20 got the tower's chest by mistake
## (it would have rebuilt a watchtower): that one is set right here.
func _has_chest() -> bool:
	var ruins: Dictionary = auth.world_state.get("ruins", {}).duplicate()
	for k in ruins:
		var r: Dictionary = ruins[k]
		if (r.get("origin", Vector3.INF) as Vector3).distance_to(origin) < 1.0:
			if String(r.get("stone", "")) != stone_key:
				r = r.duplicate()
				r.merge({stone = stone_key, wood = wood_key, name = ruin_name, reach = reach}, true)
				ruins[k] = r
				auth.world_state["ruins"] = ruins
			return true
	return false


func _process(delta: float) -> void:
	if _state == "chest_wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var box := AABB(origin + Basis(Vector3.UP, turn * PI / 2.0) * Vector3(0, 0, 17), Vector3.ZERO).grow(8.0)  # the ground before the gate
		if auth.world.terrain.is_area_meshed(box):
			_add_rebuild_chest(Basis(Vector3.UP, turn * PI / 2.0))
			_state = "done"
			set_process(false)
		return
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = float(plan.get("radius", 18.5)) + 2.0
		var box := AABB(origin + Vector3(-half, 0.0, -half), Vector3(half * 2.0, float(plan.get("height", 7.5)) + 1.5, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			_state = "carve"
			print("RUIN_OUTPOST carving %d spots (t=%d ms)" % [_carve.size(), Time.get_ticks_msec()])
		return
	if _state == "build":
		var t0 := Time.get_ticks_msec()
		print("RUIN_OUTPOST carved, building (t=%d ms)" % t0)
		_build()
		print("RUIN_OUTPOST build took %d ms" % (Time.get_ticks_msec() - t0))
		auth.world_state["outpost"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_OUTPOST built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)
