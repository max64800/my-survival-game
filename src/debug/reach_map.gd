class_name ReachMap
## Every spot the dwarf's body can walk to from a start (F783, Nov 23): a flood fill in 25 cm steps using the body's
## own collision (test_move). Walking each flight on its own isn't enough: a flight can climb fine and still be
## fenced off from the floor around it. Used by the robot walk (src/debug/tower_walk.gd) and the tests.

const GRID := 0.25

## Why the last step() failed (for printing).
static var why := ""


## Where the feet land after one step `m` from feet at `at`, or Vector3.INF if the body can't go there.
## Flat first (under a round door's arch), then forward-and-up together like sliding up a stair's slope (at a stair's
## foot the floor above can leave only ~1.6 m of head room: lifting first would bump it), then a full step up like
## Dwarf._try_step_up. Then down onto whatever is below (up to 3 m: you can drop down).
static func step(body: PhysicsBody3D, at: Vector3, m: Vector3) -> Vector3:
	var hit := KinematicCollision3D.new()
	var lift := Transform3D()
	var free := false
	why = ""
	var base := Transform3D(Basis(), at + Vector3.UP * 0.05)
	for r in [0.0, 0.3]:
		if not body.test_move(base, m + Vector3.UP * r, hit):
			lift = base.translated(Vector3.UP * r)
			free = true
			break
		why += "move up %.2f hits %s; " % [r, name_of(hit)]
	if not free:
		if body.test_move(base, Vector3.UP * Dwarf.STEP_HEIGHT, hit):
			why += "no head room to step up (%s); " % name_of(hit)
		else:
			lift = base.translated(Vector3.UP * Dwarf.STEP_HEIGHT)
			free = not body.test_move(lift, m, hit)
			if not free:
				why += "step up hits %s; " % name_of(hit)
	if not free:
		return Vector3.INF
	var over := lift.translated(m)
	if not body.test_move(over, Vector3.DOWN * 3.0, hit):
		why += "nothing under"
		return Vector3.INF
	return over.origin + hit.get_travel()


## All spots reached from `start` (feet), staying inside `box` (x/z only), at most `cap` spots.
static func flood(body: PhysicsBody3D, start: Vector3, box: AABB, cap := 250000) -> Array[Vector3]:
	var hit := KinematicCollision3D.new()
	var s := Vector3(snappedf(start.x, GRID), start.y, snappedf(start.z, GRID))  # (on the building grid: doorways' middles)
	var t0 := Transform3D(Basis(), s + Vector3.UP * 0.6)
	if body.test_move(t0, Vector3.DOWN * 2.0, hit):
		s = t0.origin + hit.get_travel()
	var seen := {_key(s): true}
	var spots: Array[Vector3] = []
	var todo: Array[Vector3] = [s]
	var dirs := [Vector3(GRID, 0, 0), Vector3(-GRID, 0, 0), Vector3(0, 0, GRID), Vector3(0, 0, -GRID)]
	while not todo.is_empty() and spots.size() < cap:
		var at: Vector3 = todo.pop_back()
		spots.append(at)
		for m: Vector3 in dirs:
			var land := step(body, at, m)
			if land == Vector3.INF:
				continue
			var k := _key(land)
			if seen.has(k) or land.x < box.position.x or land.x > box.end.x or land.z < box.position.z or land.z > box.end.z:
				continue
			seen[k] = true
			todo.append(land)
	return spots


## How far (flat) the nearest reached spot at about `q`'s height (+-0.4 m) is from `q` (99 if none).
static func distance(spots: Array[Vector3], q: Vector3) -> float:
	var best := 99.0
	for sp: Vector3 in spots:
		if absf(sp.y - q.y) < 0.4:
			best = minf(best, Vector2(sp.x - q.x, sp.z - q.z).length())
	return best


## Where a flight's feet step on (`foot`) and off (`top`), from the piece (id, pos, rot): the first and last point
## of the path a dwarf walks over it.
static func flight_ends(id: String, pos: Vector3, rot: int) -> Array[Vector3]:
	var b := Basis(Vector3.UP, Pieces.yaw_of(rot))
	if id == "stairs":
		return [pos + b * Vector3(0, -0.25, 2.2), pos + b * Vector3(0, 2, -1.9)]
	return [pos + b * Vector3(0.4, -0.25, 2.5), pos + b * Vector3(-1.9, 2, -0.6)]   # (stairs_corner: out at its side)


static func name_of(c: KinematicCollision3D) -> String:
	var n: Node = c.get_collider() as Node
	while n:
		if n is PieceNode:
			return "%s %s" % [n.piece, n.global_position.snapped(Vector3.ONE * 0.05)]
		n = n.get_parent()
	return "rock/other"


static func _key(q: Vector3) -> Vector3i:
	return Vector3i(roundi(q.x / GRID), roundi(q.y / GRID), roundi(q.z / GRID))
