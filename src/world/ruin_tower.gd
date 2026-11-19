class_name RuinTower
extends Node
## The ruined Stone Watchtower in the first cave of a new world (owner, Nov 17, F254): the first stone place to
## discover. Host only, once, when the world is made. Its plan is blueprints/ruins/watchtower_ruin.json (made from
## the real blueprint by tools/ruins/make_watchtower_ruin.py): building pieces incl. worn and collapsed walls and
## rubble, plus chests with their loot. The first-cave tower has no beetles (owner).
## How: pick a fairly flat, open spot in the cavern you walk into (not right where you arrive), wait until that
## rock has loaded, carve the tower's space (ordinary digs, so they're saved and sent to friends like any other),
## then add the pieces through the Builder and the chests through Storage (both saved and sent too).

const PLAN := "res://blueprints/ruins/watchtower_ruin.json"
const CARVE_RADIUS := 1.1
const CARVES_PER_FRAME := 30

var auth: GameAuthority
var plan: Dictionary
var origin := Vector3.INF   ## the tower's bottom centre (ground level of its foundations)
var turn := 0               ## quarter turns: its door faces where you come from
var _carve: Array = []
var _state := "wait"        ## wait (for the rock to load) -> carve -> build -> done
static var last_origin := Vector3.INF  ## where the last one was built (the towercheck robot looks there)
static var last_turn := 0


static func load_plan() -> Dictionary:
	var f := FileAccess.open(PLAN, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## Where the tower goes: around the first cavern's arrival point, the spot with the flattest floor and the least
## rock in the way, 9-26 m from where you arrive. Returns {pos, turn} or {} when nothing fits.
static func find_spot(maker: CaveMaker, radius: float, height: float) -> Dictionary:
	var c := maker.cavern_spawn
	var best := {}
	var best_score := INF
	for r in [9.0, 11.0, 13.0, 15.0, 18.0, 21.0, 24.0]:
		for k in 16:
			var a := k * TAU / 16.0
			var p: Vector3 = c + Vector3(cos(a), 0, sin(a)) * r
			var mid := maker.find_floor(p.x, p.z, c.y + 6.0)
			if absf(mid.y - c.y) > 5.0:
				continue
			var ys := [mid.y]
			var ok := true
			for i in 12:
				var b := i * TAU / 12.0
				var q := maker.find_floor(p.x + cos(b) * radius, p.z + sin(b) * radius, mid.y + 3.0)
				if q.y < mid.y - 2.5:
					ok = false  # a drop or a chasm under the tower
					break
				ys.append(q.y)
			if not ok:
				continue
			ys.sort()
			var base: float = ys[ys.size() / 2]
			var rock := 0
			for h in [1.5, 3.5, 5.5, 7.5, height]:
				for i in 7:
					var b := i * TAU / 6.0
					var rr := 0.0 if i == 6 else radius * 0.8
					if maker.sdf_at(Vector3(p.x + cos(b) * rr, base + h, p.z + sin(b) * rr)) < 0.0:
						rock += 1
			var score: float = (ys[-1] - ys[0]) * 4.0 + rock * 0.6 + r * 0.04
			if score < best_score:
				best_score = score
				# The door (local +z) faces back toward where you arrive, in quarter turns.
				var to: Vector3 = c - p
				var yaw := atan2(to.x, to.z)
				best = {pos = Vector3(p.x, base, p.z), turn = posmod(roundi(yaw / (PI / 2.0)), 4)}
	return best


func _init(p_auth: GameAuthority) -> void:
	auth = p_auth
	name = "RuinTower"


func _ready() -> void:
	plan = load_plan()
	if plan.is_empty() or auth.world == null:
		queue_free()
		return
	var spot := find_spot(auth.world.maker, float(plan.get("radius", 4.2)), float(plan.get("height", 9.0)))
	if spot.is_empty():
		push_warning("RuinTower: no room for the watchtower in the first cave")
		queue_free()
		return
	origin = spot.pos
	turn = spot.turn
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var r: float = plan.get("radius", 4.2) + 0.4
	var front: float = plan.get("front", 6.8)
	var top: float = plan.get("height", 9.0) + 0.6
	var y := 0.4
	while y <= top:
		var x := -r
		while x <= r:
			var z := -r
			while z <= front:
				if Vector2(x, z).length() <= r or (absf(x) <= 2.6 and z > 0.0 and y <= 2.5):  # the tower, and the steps' corridor
					_carve.append(origin + basis * Vector3(x, y, z))
				z += 1.2
			x += 1.2
		y += 1.2


func _process(_delta: float) -> void:
	match _state:
		"wait":
			var box := AABB(origin - Vector3(6, 1, 6), Vector3(12, 11, 14))
			if auth.world.terrain.is_area_meshed(box):
				_state = "carve"
		"carve":
			var n := 0
			while not _carve.is_empty() and n < CARVES_PER_FRAME:
				var c: Vector3 = _carve.pop_back()
				if auth.world.sdf_at(c) < CARVE_RADIUS:
					auth._host_dig(c, 9, CARVE_RADIUS)  # tier 9: any rock gives way (it's the world making room)
					n += 1
			if _carve.is_empty():
				_state = "build"
		"build":
			_build()
			_state = "done"
			queue_free()


func _build() -> void:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var b: Builder = auth.builder
	for p in plan.get("pieces", []):
		var pos: Vector3 = origin + basis * Vector3(p.pos[0], p.pos[1], p.pos[2])
		var rot: int = Pieces.add_rot(int(p.rot), turn)
		var uid: int = b._next_uid
		b._ev_add_piece.rpc(uid, String(p.id), String(p.mat), pos, rot, float(p.pos[1]) < 0.3)
	for c in plan.get("chests", []):
		var pos: Vector3 = origin + basis * Vector3(c.pos[0], c.pos[1], c.pos[2])
		var yaw := deg_to_rad(float(c.yaw)) + turn * PI / 2.0
		var flat := Vector2(float(c.pos[0]), float(c.pos[2]))
		if String(c.kind).begins_with("chest") and flat.length() > 0.5:
			# A chest's front (its lid's lock, box -Z) faces the middle of the tower (owner, Nov 19: some faced the wall).
			yaw = atan2(flat.x, flat.y) + turn * PI / 2.0
		var id: int = auth.storage.create_box(String(c.kind), pos, yaw)
		for item in c.get("loot", {}):
			if Items.exists(item):
				auth.storage.put(id, item, int(c.loot[item]))
	last_origin = origin
	last_turn = turn
	print("RUIN_TOWER built at %s (turn %d): %d pieces, %d chests" % [origin, turn, plan.get("pieces", []).size(), plan.get("chests", []).size()])
