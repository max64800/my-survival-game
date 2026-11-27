class_name RuinBrewhall
extends RuinTower
## The Brewhall (owner, Nov 20, F479): the third ruin, an old dwarf tavern and brewery in clay brick, in a plain big
## cavern of Mossy Hollows about 95 m from the start (between the watchtower and the Fallen Outpost). Its plan is
## blueprints/ruins/brewhall_ruin.json (tools/ruins/make_brewhall_ruin.py). Works like the outpost (ruin_outpost.gd):
## the world remembers "brewhall: pending" and builds it the first time someone comes close enough for its rock to
## load; the spot only depends on the world's seed. Its cellar is dug below the ground line. Rebuilt with root
## planks or clay bricks (docs/design/ruin-rebuild-plan.md); rock beetles guard its cavern. New worlds only.

const PLAN_PATH := "res://blueprints/ruins/brewhall_ruin.json"
const WANT_DIST := 95.0   ## how far from the start (m)
const CHECK_EVERY := 1.0
## The cellar (x 2..6, z -6..-2 in its own frame): dug out below the ground line, down to its floor (-1.5).
const CELLAR_XS := [2.7, 3.6, 4.4, 5.3]
const CELLAR_ZS := [-5.3, -4.4, -3.6, -2.7]
const CELLAR_YS := [-0.7, 0.2]
static var built_origin := Vector3.INF  ## where it was built in this run (tests look there)
static var built_turn := 0

var room := -1
var _check := 0.0


## Which cavern: of Mossy's plain big caverns (not the start's, not the outpost's), the one nearest 95 m from the
## start (-1: none). Only depends on the seed.
static func pick_room(maker: CaveMaker) -> int:
	var c0 := maker.cavern_spawn
	var fort := RuinOutpost.pick_room(maker)
	var best_room := -1
	var best_d := INF
	for i in maker.rooms.size():
		var rm: Dictionary = maker.rooms[i]
		if i == fort or not rm.big or rm.get("biome", "mossy") != "mossy" or rm.get("kind", "") not in ["cavern", "ruin"]:
			continue
		var d := Vector2(rm.center.x - c0.x, rm.center.z - c0.z).length()
		if d > 45.0 and absf(d - WANT_DIST) < best_d:
			best_d = absf(d - WANT_DIST)
			best_room = i
	return best_room


## The spot in that cavern with the flattest floor and the least rock in the way (so no stone column or bridge of
## the cavern stands where it goes: the placement rule). Returns {room, pos, turn} or {}.
static func pick(maker: CaveMaker, half: float, height: float) -> Dictionary:
	var c0 := maker.cavern_spawn
	var best_room := pick_room(maker)
	if best_room < 0:
		return {}
	var rc: Vector3 = maker.rooms[best_room].center
	var best := {}
	var best_score := INF
	for gx in range(-4, 5):
		for gz in range(-4, 5):
			var p := rc + Vector3(gx * 3.0, 0, gz * 3.0)
			var mid := maker.find_floor(p.x, p.z, rc.y)
			var ys := []
			var ok := true
			for sx in 5:
				for sz in 5:
					var q := maker.find_floor(p.x + (sx - 2) * half / 2.0, p.z + (sz - 2) * half / 2.0, mid.y + 4.0)
					if q.y < mid.y - 2.5:
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
			for h in [1.5, 3.5, 5.5, height, height + 2.5]:
				for sx in 4:
					for sz in 4:
						if maker.sdf_at(Vector3(p.x + (sx - 1.5) * half * 0.6, base + h, p.z + (sz - 1.5) * half * 0.6)) < 0.0:
							rock += 1
			var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 2.0 + Vector2(gx, gz).length() * 0.3
			if score < best_score:
				best_score = score
				var to: Vector3 = c0 - p  # the front door (local +z) faces the way you come from
				best = {room = best_room, pos = Vector3(p.x, base, p.z), turn = posmod(roundi(atan2(to.x, to.z) / (PI / 2.0)), 4)}
	return best


func _init(p_auth: GameAuthority) -> void:
	super(p_auth)
	name = "RuinBrewhall"
	drop_rubble = false
	stone_key = "hearthbrick_brewhall"
	wood_key = "wooden_brewhall"
	ruin_name = "brewhall"
	hard_mat = "clay_brick"
	reach = 11.0   # its corners (chimney and front steps) are about 10.2 m from the middle


## The Rebuilding Chest stands in front of the hall, beside the front door's steps (x -6..-4, z 4..6).
func _chest_spots(_rad: float) -> Array[Vector2]:
	return [Vector2(-2.6, 6.6), Vector2(-7.4, 6.6), Vector2(-2.6, 7.8), Vector2(-7.4, 7.8), Vector2(0.4, 6.8), Vector2(-1.2, 8.4)]


func _path_z(_rad: float) -> float:
	return 7.4


func _ready() -> void:
	var st: String = auth.world_state.get("brewhall", "")
	plan = load_plan(PLAN_PATH)
	if st == "" or plan.is_empty() or auth.world == null:
		queue_free()  # an older world (or no plan): no Brewhall
		return
	var half: float = float(plan.get("radius", 8.6))
	var spot: Dictionary = auth.world.maker.brewhall_spot
	if spot.is_empty():
		spot = pick(auth.world.maker, half, float(plan.get("height", 8.0)))
	if spot.is_empty():
		push_warning("RuinBrewhall: no cavern for the Brewhall")
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
	# Carve its space: the whole square plus a margin, from about its ground line up to its top, and the cellar
	# below the ground line (ordinary digs: saved and sent to friends).
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var r := half + 1.5
	var front: float = float(plan.get("front", half)) + 1.5
	var top: float = float(plan.get("height", 8.0)) + 0.8
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
	for cy in CELLAR_YS:
		for cx in CELLAR_XS:
			for cz in CELLAR_ZS:
				_carve.append(origin + basis * Vector3(cx, cy, cz))


func _process(delta: float) -> void:
	if _state == "wait":
		_check -= delta
		if _check > 0.0:
			return
		_check = CHECK_EVERY
		var half: float = float(plan.get("radius", 8.6)) + 2.0
		var box := AABB(origin + Vector3(-half, -2.0, -half), Vector3(half * 2.0, float(plan.get("height", 8.0)) + 3.5, half * 2.0))
		if auth.world.terrain.is_area_meshed(box) and auth.world.is_ready_at(box.get_center(), half):
			_state = "carve"
		return
	if _state == "build":
		if not _build():
			return  # (a little each frame, F417)
		auth.world_state["brewhall"] = "built"
		built_origin = origin
		built_turn = turn
		print("RUIN_BREWHALL built at %s (turn %d)" % [origin, turn])
		_state = "done"
		set_process(false)
		return
	super(delta)
