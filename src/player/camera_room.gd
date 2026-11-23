class_name CameraRoom
## How far back the camera can really go (F783, owner Nov 23: "the camera jitters" walking the Twin Gate's wall walks).
## Every built piece bumps like rock, so the camera's feeler (the spring arm) also hit every railing, battlement,
## post and lamp that passed behind the dwarf: the camera jumped in, glided back out, jumped in again. Now only the
## floors and stairs below him and rock push the camera in (F807: since Nov 23 walls and roofs don't either).
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


## The free part (0..1) of moving the spring's ball from `from` by `motion`, slipping past thin pieces.
static func _free(spring: SpringArm3D, from: Vector3, motion: Vector3, extra_exclude: Array[RID]) -> float:
	var space := spring.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = spring.shape
	q.collision_mask = spring.collision_mask
	var exclude: Array[RID] = extra_exclude.duplicate()
	var last := 0.0
	for _i in MAX_SKIPS + 1:
		q.exclude = exclude
		q.transform = Transform3D(Basis(), from)
		q.motion = motion
		var frac := space.cast_motion(q)
		if frac.is_empty() or frac[0] >= 1.0:
			return 1.0
		last = frac[0]
		q.transform = Transform3D(Basis(), from + motion * frac[1])
		q.motion = Vector3.ZERO
		var info := space.get_rest_info(q)
		var c: Object = instance_from_id(int(info.get("collider_id", 0))) if not info.is_empty() else null
		if c == null or not see_through(c, from.y):
			return frac[0]
		exclude.append(info.rid)
	return last  # (too many thin pieces in a row: stop at the last one)
