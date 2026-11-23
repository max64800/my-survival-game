class_name CameraRoom
## How far back the camera can really go (F783, owner Nov 23: "the camera jitters" walking the Twin Gate's wall walks).
## Every built piece bumps like rock, so the camera's feeler (the spring arm) also hit every railing, battlement,
## post and lamp that passed behind the dwarf: the camera jumped in, glided back out, jumped in again. Now only the
## floors and stairs below him and the ground push the camera in (F807: since Nov 23 walls and roofs don't either;
## F766, Nov 23 late: nor rock walls, rock ceilings or dungeon walls, see FLOOR_NORMAL).
## (The same idea as F781, which took the spiral stairs' rails and post off the camera's layer.)

## F807 (owner, Nov 23: "do the same on the walls and the ceiling"; in a small tower room they pushed the camera so
## close the dwarf looked bigger): the camera now slips through every built piece and CameraFade makes it see-through.
## Only these stop it, and only when they're lower than his chest: you'd look up from under the floor.
const FLOORS := ["floor", "floor_half", "floor_triangle", "floor_hatch", "small_floor", "foundation", "foundation_half",
	"foundation_triangle", "foundation_steps", "stairs", "stairs_corner", "stairs_spiral", "ramp"]
const SIDE_TRIES := [1.0, 0.6, 0.3, 0.0]  ## shoulder spots tried, as parts of the wanted one (F806)
const MAX_SKIPS := 6   ## at most this many thin pieces looked past in one frame


## True if the camera may slip past this thing: any built piece except a floor or stair lower than `chest_y`.
static func see_through(collider: Object, chest_y := INF) -> bool:
	var node := collider as Node
	if node and not (node is PieceNode) and node.get_parent() is PieceNode:
		node = node.get_parent()
	if node is PieceNode:
		var id := String((node as PieceNode).piece)
		return not (id in FLOORS and (node as PieceNode).global_position.y < chest_y)
	return false


## How far along the spring arm the camera can go: like spring.get_hit_length(), but thin pieces don't count.
static func room(spring: SpringArm3D, extra_exclude: Array[RID] = []) -> float:
	var hit := spring.get_hit_length()
	var full := spring.spring_length
	if hit >= full - 0.01 or not spring.is_inside_tree() or spring.shape == null:
		return hit
	var free := _free(spring, spring.global_position, spring.global_basis.z.normalized() * full, extra_exclude)
	return full if free >= 1.0 else maxf(0.0, full * free - spring.margin)


## F806: how far out to the side (over his shoulder) the spring arm may start, up to `want` m. The shoulder spot
## itself is felt for first: in a round doorway it sat inside the door frame, so the camera found "no room" and
## jumped into his head, then glided out, jumped in again ("in, out, in, out").
static func side_room(spring: SpringArm3D, want: float, extra_exclude: Array[RID] = []) -> float:
	var pivot := spring.get_parent() as Node3D
	if want <= 0.0 or pivot == null or not spring.is_inside_tree() or spring.shape == null:
		return want
	var free := _free(spring, pivot.global_position, pivot.global_basis.x.normalized() * want, extra_exclude)
	return want if free >= 1.0 else maxf(0.0, want * free - 0.05)


## F806: the best spot over his shoulder, up to `want` m out: the farthest out one whose line back is clear, else
## the one with the most room behind (in a doorway that's nearer the middle, where the round hole is widest).
## It only depends on where he stands and looks, never on where the camera was, so it can't chase itself.
static func best_side(spring: SpringArm3D, want: float, extra_exclude: Array[RID] = []) -> float:
	var side := side_room(spring, want, extra_exclude)
	var pivot := spring.get_parent() as Node3D
	if pivot == null or not spring.is_inside_tree() or spring.shape == null:
		return side
	var back := pivot.global_basis.z.normalized() * spring.spring_length
	var right := pivot.global_basis.x.normalized()
	var best := side
	var best_free := -1.0
	for k in SIDE_TRIES:
		var s: float = side * k
		var free := _free(spring, pivot.global_position + right * s, back, extra_exclude)
		if free >= 0.999:
			return s
		if free > best_free + 0.02:  # (a clearly longer line wins; a tie keeps the one farther out)
			best_free = free
			best = s
	return best


## Rock and dungeon walls (owner, Nov 23: "if I am against the wall, it doesn't zoom in my camera all the way close
## to my character, but I can still see through the wall and the rock"): the camera slips through rock walls and
## ceilings too. From inside the rock its cave side faces away from the camera, so it isn't drawn: you see straight
## through (dungeon walls get CameraFade's circle). Only ground stops it: a surface facing up more than this ...
const FLOOR_NORMAL := 0.6
## ... or anything it touches lower than this far below his chest (m), so you never look up from under the ground.
const SLIP_LOWEST := 0.6


## True if the camera may slip through rock or a dungeon wall at this touch (`info` = get_rest_info's answer).
static func slips_through_rock(info: Dictionary, chest_y: float) -> bool:
	var n: Vector3 = info.get("normal", Vector3.UP)
	var p: Vector3 = info.get("point", Vector3.ZERO)
	return n.y < FLOOR_NORMAL and p.y > chest_y - SLIP_LOWEST


## The free part (0..1) of moving the spring's ball from `from` by `motion`, slipping past thin pieces, rock walls
## and dungeon walls.
static func _free(spring: SpringArm3D, from: Vector3, motion: Vector3, extra_exclude: Array[RID]) -> float:
	var space := spring.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = spring.shape
	q.collision_mask = spring.collision_mask
	var exclude: Array[RID] = extra_exclude.duplicate()
	var length := motion.length()
	if length < 0.001:
		return 1.0
	var sphere := spring.shape as SphereShape3D
	var hop := ((sphere.radius if sphere else 0.3) * 2.0 + 0.05) / length  # (past a wall: the ball's whole width on)
	var start := 0.0   # (where along `motion` the ball starts this round: past the walls slipped through so far)
	var last := 0.0
	for _i in MAX_SKIPS + 1:
		if start >= 1.0:
			return 1.0
		q.exclude = exclude
		q.transform = Transform3D(Basis(), from + motion * start)
		q.motion = motion * (1.0 - start)
		var frac := space.cast_motion(q)
		if frac.is_empty() or frac[0] >= 1.0:
			return 1.0
		var at := start + (1.0 - start) * frac[0]
		var touch := start + (1.0 - start) * frac[1]
		last = at
		q.transform = Transform3D(Basis(), from + motion * touch)
		q.motion = Vector3.ZERO
		var info := space.get_rest_info(q)
		if info.is_empty():
			return at
		var c: Object = instance_from_id(int(info.get("collider_id", 0)))
		if c != null and see_through(c, from.y):
			exclude.append(info.rid)   # (a built piece: look past that one piece)
			continue
		var piece := c is PieceNode or (c is Node and (c as Node).get_parent() is PieceNode)
		if piece or not slips_through_rock(info, from.y):
			return at   # (a built floor or stair below his chest, or the ground)
		start = touch + hop   # (rock or a dungeon wall: carry on from just past it; the rock's floors still count)
	return last  # (too many things in a row: stop at the last one)
