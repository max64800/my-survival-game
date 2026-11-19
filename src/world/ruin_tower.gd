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
const RUBBLE := ["ruin_rubble", "door_broken"]  ## placed as hit-to-clear rubble, not as building pieces

var auth: GameAuthority
var plan: Dictionary
var origin := Vector3.INF   ## the tower's bottom centre (ground level of its foundations)
var turn := 0               ## quarter turns: its door faces where you come from
var _carve: Array = []
var _state := "wait"        ## wait (for the rock to load) -> carve -> build -> done
var drop_rubble := true     ## rubble on the ground falls onto the cave floor (the outpost's ground is carved flat)
var chest_only := false     ## an old world's tower already stands: only add its Rebuilding Chest (see add_missing_chest)
static var last_origin := Vector3.INF  ## where the last one was built (the towercheck robot looks there)
static var last_turn := 0


## Worlds saved before Nov 19 (or while a merge had taken it out) have the tower but no Rebuilding Chest (owner, Nov 19).
## Host, after loading a save: if the world has no ruin chest yet, add one. The tower's spot comes from the same dice
## as when it was built; the chest is only added when the tower's whole pieces really stand there (see _tower_here).
static func add_missing_chest(p_auth: GameAuthority) -> RuinTower:
	if p_auth.world == null or not p_auth.world_state.get("ruins", {}).is_empty():
		return null
	var t := RuinTower.new(p_auth)
	t.chest_only = true
	p_auth.add_child(t)
	return t


static func load_plan(path: String = PLAN) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
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
			var base: float = ys[0] - 0.05  # the lowest ground under it: the tower always stands on the floor (owner)
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
	if chest_only:
		if not _tower_here(basis):
			print("RUIN_TOWER old world: no tower standing at %s, so no Rebuilding Chest" % origin)
			queue_free()
		return  # (waits for the rock to load, then adds the chest)
	var r: float = plan.get("radius", 4.2) + 0.4
	var front: float = plan.get("front", 6.8)
	var top: float = plan.get("height", 9.0) + 0.6
	var y := 1.7  # carve only ABOVE the ground line (digging lower left holes under the tower: it floated)
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
				_state = "chest" if chest_only else "carve"
		"chest":
			_add_rebuild_chest(Basis(Vector3.UP, turn * PI / 2.0))
			last_origin = origin
			last_turn = turn
			_state = "done"
			queue_free()
		"carve":
			var n := 0
			while not _carve.is_empty() and n < CARVES_PER_FRAME:
				var c: Vector3 = _carve.pop_back()
				if auth.world.sdf_at(c) < CARVE_RADIUS:
					auth._host_dig(c, 9, CARVE_RADIUS, true)  # tier 9: any rock gives way (it's the world making room)
					n += 1
			if _carve.is_empty():
				_state = "build"
		"build":
			_build()
			_state = "done"
			queue_free()


## The floor under `p`: the cave's own rock (the tower only carves ABOVE its ground line, so the ground the
## rubble lies on is still the cave's), found from a little above so higher ground doesn't bury it.
func _floor_at(p: Vector3) -> float:
	return auth.world.maker.find_floor(p.x, p.z, p.y + 2.5).y


func _build() -> void:
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var b: Builder = auth.builder
	b.batch = true
	for p in plan.get("pieces", []):
		var pos: Vector3 = origin + basis * Vector3(p.pos[0], p.pos[1], p.pos[2])
		var rot: int = Pieces.add_rot(int(p.rot), turn)
		if String(p.id) in RUBBLE:
			# Rubble and the broken door: real rubble you hit to clear (owner: "they have to be destroyable"),
			# dropped onto whatever is under it so nothing floats.
			if float(p.pos[1]) < 0.3 and drop_rubble:
				pos.y = _floor_at(pos)
			var t := Transform3D(Basis(Vector3.UP, Pieces.yaw_of(rot)), pos)
			b._ev_add_rubble.rpc(b._next_rubble, String(p.id), String(p.mat), t)
			continue
		var uid: int = b._next_uid
		b._ev_add_piece.rpc(uid, String(p.id), String(p.mat), pos, rot, float(p.pos[1]) < 0.3)
	b.end_batch()
	for c in plan.get("chests", []):
		var pos: Vector3 = origin + basis * Vector3(c.pos[0], c.pos[1], c.pos[2])
		var yaw := deg_to_rad(float(c.yaw)) + turn * PI / 2.0
		var flat := Vector2(float(c.pos[0]), float(c.pos[2]))
		if String(c.kind).begins_with("chest") and flat.length() > 0.5:
			# A chest's front (its lid's lock, box -Z) faces the middle of the tower (owner, Nov 19: some faced the wall).
			yaw = atan2(flat.x, flat.y) + turn * PI / 2.0
		var id: int = auth.storage.create_box(String(c.kind), pos, yaw)
		for item in c.get("loot", {}):
			if item == "recipe_page":  # the plan says "a recipe page": which kind is rolled per world (owner, Nov 19)
				for _p in int(c.loot[item]):
					auth.storage.put(id, Recipes.random_page(randf()), 1)
			elif Items.exists(item):
				auth.storage.put(id, item, int(c.loot[item]))
	_add_rebuild_chest(basis)
	last_origin = origin
	last_turn = turn
	for t in plan.get("torches", []):  # standing crystal torches (owner, F264)
		var tp: Vector3 = origin + basis * Vector3(t[0], t[1], t[2])
		var sid: int = auth._next_station_id
		auth._next_station_id += 1
		auth._ev_place_station.rpc(sid, "crystal_torch", tp, turn * PI / 2.0)
	print("RUIN_TOWER built at %s (turn %d): %d pieces, %d chests" % [origin, turn, plan.get("pieces", []).size(), plan.get("chests", []).size()])


## The tower stands here: at least half of its plan's building pieces (not rubble) are in the world at their exact
## place and turn (players may have broken some). Otherwise the save's tower is somewhere else (an older world made
## before a change to find_spot), and a chest here would rebuild the wrong spot.
func _tower_here(basis: Basis) -> bool:
	var want := 0
	var found := 0
	for p in plan.get("pieces", []):
		if String(p.id) in RUBBLE:
			continue
		want += 1
		var pos: Vector3 = origin + basis * Vector3(p.pos[0], p.pos[1], p.pos[2])
		var rot: int = Pieces.add_rot(int(p.rot), turn)
		for uid in auth.builder.structure.pieces:
			var q: Dictionary = auth.builder.structure.pieces[uid]
			if q.piece == String(p.id) and q.rot == rot and (q.pos as Vector3).distance_to(pos) < 0.1:
				found += 1
				break
	return want > 0 and found * 2 >= want


static var last_rebuild_box := -1  ## the Rebuilding Chest's box id (tests and the towercheck robot look at it)


## The Rebuilding Chest (owner, Nov 19; docs/design/ruin-rebuild-plan.md, F350): beside the path in front of the door,
## facing the path. Root planks or cut stone put in it rebuild the tower as a build site; finishing it teaches its
## blueprint. Tries a few spots beside the steps' corridor (|x| > 2.6) and takes the first with open air above the
## floor, so it is never buried in rock or standing on the steps (F350 🔁: "make sure it can't be blocked or buried").
func _add_rebuild_chest(basis: Basis) -> void:
	var rad := float(plan.get("radius", 4.2))
	var pick := Vector3.INF
	for o: Vector2 in [Vector2(3.4, rad + 1.6), Vector2(-3.4, rad + 1.6), Vector2(3.4, rad + 3.0), Vector2(-3.4, rad + 3.0),
			Vector2(3.0, rad + 0.6), Vector2(-3.0, rad + 0.6)]:
		var p: Vector3 = origin + basis * Vector3(o.x, 0.0, o.y)
		p.y = auth.world.maker.find_floor(p.x, p.z, p.y + 2.5).y
		if absf(p.y - origin.y) > 1.5:
			continue  # a drop or a ledge: not by the door
		if auth.world.sdf_at(p + Vector3.UP * 0.6) > 0.45 and auth.world.sdf_at(p + Vector3.UP * 1.4) > 0.45:
			pick = p
			break
	if pick == Vector3.INF:  # (never seen: fall back to the middle of the path, which is always carved)
		pick = origin + basis * Vector3(0.0, 0.0, rad + 3.2)
		pick.y = auth.world.maker.find_floor(pick.x, pick.z, pick.y + 2.5).y
	var to_path := (origin + basis * Vector3(0.0, 0.0, rad + 2.0)) - pick
	var box_id: int = auth.storage.create_box("rebuild", pick, atan2(-to_path.x, -to_path.z))  # (its front, box -Z, toward the path)
	last_rebuild_box = box_id
	var ruins: Dictionary = auth.world_state.get("ruins", {}).duplicate()
	ruins[str(box_id)] = {origin = origin, turn = turn, stone = "stone_watchtower", wood = "wooden_watchtower", done = false}
	auth.world_state["ruins"] = ruins
	print("RUIN_TOWER rebuilding chest %d at %s" % [box_id, pick])
