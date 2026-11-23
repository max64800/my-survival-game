class_name CameraFade
extends RefCounted
## F807 (owner, Nov 23, "best case"): a built piece between the camera and the dwarf turns a bit see-through, so you
## always see him (the rock already does this with its speckle, F766). Each frame a fat invisible tube from the
## camera to his chest asks "which pieces are in here?"; those fade to DwarfFeel.CAM_BUILD_FADE, the rest fade back.
## Only on your own screen: nothing is sent to the other players.

const TUBE_RADIUS := 0.3  ## m: how fat the tube is
const TUBE_END := 0.85    ## the tube stops this part of the way to his chest (the floor he stands on stays solid)
const MAX_HITS := 16

var _faded := {}  ## PieceNode instance id -> [piece, how see-through it is now (0..1)]
var _shape := CapsuleShape3D.new()


## `from` = the camera, `to` = his chest. `exclude` = his own body.
func update(world: World3D, from: Vector3, to: Vector3, delta: float, exclude: Array[RID] = [], on := true) -> void:
	var want := {}
	var amount := DwarfFeel.CAM_BUILD_FADE
	if on and amount > 0.0 and world and from.distance_to(to) > 0.3:
		for p in _pieces_between(world, from, from.lerp(to, TUBE_END), exclude):
			want[p.get_instance_id()] = p
	for id in want:
		if not _faded.has(id):
			_faded[id] = [want[id], 0.0]
	var step := delta * DwarfFeel.CAM_BUILD_FADE_SPEED
	for id in _faded.keys():
		var entry: Array = _faded[id]
		var p: Node = entry[0]
		if not is_instance_valid(p):
			_faded.erase(id)
			continue
		entry[1] = move_toward(entry[1], amount if want.has(id) else 0.0, step)
		_set_see_through(p, entry[1])
		if entry[1] <= 0.0 and not want.has(id):
			_faded.erase(id)


## How see-through this piece is right now (0 = solid). For tests.
func faded(p: Node) -> float:
	var entry: Array = _faded.get(p.get_instance_id(), [])
	return entry[1] if entry.size() > 1 else 0.0


func _pieces_between(world: World3D, a: Vector3, b: Vector3, exclude: Array[RID]) -> Array:
	var length := a.distance_to(b)
	if length < 0.05:
		return []
	_shape.radius = TUBE_RADIUS
	_shape.height = length + TUBE_RADIUS * 2.0
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _shape
	q.collision_mask = PieceNode.PIECE_LAYER
	q.exclude = exclude
	var up := (b - a) / length   # (a capsule stands along its own y)
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	q.transform = Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5)
	var found := []
	for hit in world.direct_space_state.intersect_shape(q, MAX_HITS):
		var n := hit.get("collider") as Node
		if n and not (n is PieceNode) and n.get_parent() is PieceNode:
			n = n.get_parent()   # (a spiral stair's rail is its own small body, F781)
		if n is PieceNode and not (n as PieceNode).ghost and not found.has(n):
			found.append(n)
	return found


static func _set_see_through(p: Node, t: float) -> void:
	for g in p.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = t
