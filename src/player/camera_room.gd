class_name CameraRoom
## How far back the camera can really go (F783, owner Nov 23: "the camera jitters" walking the Twin Gate's wall walks).
## Every built piece bumps like rock, so the camera's feeler (the spring arm) also hit every railing, battlement,
## post and lamp that passed behind the dwarf: the camera jumped in, glided back out, jumped in again. Now only the
## big solid pieces (walls, floors, roofs, stairs) and rock push the camera in; it slips past the thin ones.
## (The same idea as F781, which took the spiral stairs' rails and post off the camera's layer.)

## Pieces the camera never goes through: you'd see inside a room or under the floor.
const SOLID := ["wall", "wall_diagonal", "wall_narrow", "window_wall", "window_wide", "window_diagonal", "doorway",
	"arch_doorway", "gateway", "sloped_wall", "sloped_wall_down", "floor", "floor_half", "floor_triangle", "floor_hatch",
	"small_floor", "foundation", "foundation_half", "foundation_triangle", "foundation_steps", "flat_roof", "ceiling_panel",
	"dormer", "gable_26", "gable_45", "stairs", "stairs_corner", "stairs_spiral", "ramp", "ruin_wall_worn",
	"ruin_wall_collapsed", "spire_wall_chunk", "bartizan"]
const MAX_SKIPS := 6   ## at most this many thin pieces looked past in one frame


## True if the camera may slip past this thing (a thin or small built piece).
static func see_through(collider: Object) -> bool:
	var node := collider as Node
	if node and not (node is PieceNode) and node.get_parent() is PieceNode:
		node = node.get_parent()
	if node is PieceNode:
		var id := String((node as PieceNode).piece)
		return not (id in SOLID or id.begins_with("roof_"))
	return false


## How far along the spring arm the camera can go: like spring.get_hit_length(), but thin pieces don't count.
static func room(spring: SpringArm3D, extra_exclude: Array[RID] = []) -> float:
	var hit := spring.get_hit_length()
	var full := spring.spring_length
	if hit >= full - 0.01 or not spring.is_inside_tree() or spring.shape == null:
		return hit
	var space := spring.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = spring.shape
	q.collision_mask = spring.collision_mask
	var exclude: Array[RID] = extra_exclude.duplicate()
	var from := spring.global_position
	var motion := spring.global_basis.z.normalized() * full
	for _i in MAX_SKIPS + 1:
		q.exclude = exclude
		q.transform = Transform3D(Basis(), from)
		q.motion = motion
		var frac := space.cast_motion(q)
		if frac.is_empty() or frac[0] >= 1.0:
			return full
		q.transform = Transform3D(Basis(), from + motion * frac[1])
		q.motion = Vector3.ZERO
		var info := space.get_rest_info(q)
		var c: Object = instance_from_id(int(info.get("collider_id", 0))) if not info.is_empty() else null
		if c == null or not see_through(c):
			return maxf(0.0, full * frac[0] - spring.margin)
		exclude.append(info.rid)
	return hit
