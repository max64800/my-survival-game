extends TestCase
## F811 (owner, Nov 23: "every staircase needs a whole free block after it"): past the foot and the top of every
## flight in every blueprint there is a whole free 2 m block (a triangle after round-stage stairs) with floor under
## it, where a dwarf's body fits. Checked with the dwarf's own capsule against the pieces' real collision.

const STAIRS := ["stairs", "stairs_corner"]

var _root: Node3D
var _body_shape: CapsuleShape3D


func test_every_flight_has_a_free_block_at_both_ends() -> void:
	_body_shape = CapsuleShape3D.new()
	_body_shape.radius = 0.36
	_body_shape.height = 1.35
	var ids: Array = BlueprintLibrary.IDS.duplicate()
	for extra in ["stonehold_twin_gate", "wooden_twin_gate"]:
		if not extra in ids:
			ids.append(extra)
	for id in ids:
		var bp := BlueprintLibrary.make(id)
		if not bp.pieces.any(func(p): return p.id in STAIRS):
			continue
		_root = Node3D.new()
		tree.root.add_child(_root)
		for p in bp.pieces:
			if p.id in Pieces.DOORS:
				continue  # (a door opens out of the way)
			var n: PieceNode = preload("res://src/build/piece_node.gd").new()
			n.piece = p.id
			n.family = p.mat
			_root.add_child(n)
			n.global_position = p.pos
			n.rotation.y = Pieces.yaw_of(p.rot)
		await tree.physics_frame
		await tree.physics_frame
		var bad := []
		for p in bp.pieces:
			if p.id in STAIRS:
				for e in block_ends(p.id, p.pos, p.rot):
					var why := _blocked(e[0], e[1])
					if why != "":
						bad.append("%s at %s, %s: %s" % [p.id, p.pos, e[2], why])
		check(bad.is_empty(), "%s: every flight has a free block at both ends %s" % [id, bad])
		_root.free()


## The free block past each end of a flight: [centre (at the walking height), sample spread, "foot"/"top"].
## Grid stairs: the 2 m cell past it, its middle and four points 0.3 m out (walls round
## the block's far sides are fine: the body only has to fit inside it). Round-stage stairs (off the 1 m
## grid): the triangle there, its middle only (a 2 m triangle is just wide enough for the dwarf).
static func block_ends(id: String, pos: Vector3, rot: int) -> Array:
	var b := Basis(Vector3.UP, Pieces.yaw_of(rot))
	var ring := absf(pos.x - roundf(pos.x)) > 0.05 or absf(pos.z - roundf(pos.z)) > 0.05
	var out_dist := 1.0 + (0.577 if ring else 1.0)
	var spread := 0.0 if ring else 0.3
	var foot := Vector3(0, 0, out_dist)
	var top := Vector3(0, 2, -out_dist)
	if id == "stairs_corner":
		top = Vector3(-out_dist, 2, 0)   # (it comes out at its side)
	return [[pos + b * foot, spread, "foot"], [pos + b * top, spread, "top"]]


## "" when the dwarf's body fits on floor at every sample point of the block, else why not.
func _blocked(at: Vector3, spread: float) -> String:
	var space := _root.get_world_3d().direct_space_state
	var pts := [Vector3.ZERO]
	if spread > 0.0:
		pts += [Vector3(spread, 0, spread), Vector3(-spread, 0, spread), Vector3(spread, 0, -spread), Vector3(-spread, 0, -spread)]
	for d in pts:
		var q: Vector3 = at + d
		var ray := PhysicsRayQueryParameters3D.create(q + Vector3.UP * 0.6, q + Vector3.DOWN * 0.6, PieceNode.PIECE_LAYER)
		var hit := space.intersect_ray(ray)
		var feet := q + Vector3.UP * 0.08
		if not hit.is_empty():
			feet = hit.position + Vector3.UP * 0.08
		elif q.y > 0.5:
			return "no floor at %s" % q.snapped(Vector3.ONE * 0.01)   # (at the bottom the cave's ground carries you)
		var sq := PhysicsShapeQueryParameters3D.new()
		sq.shape = _body_shape
		sq.transform = Transform3D(Basis(), feet + Vector3.UP * 0.675)
		sq.collision_mask = PieceNode.PIECE_LAYER
		var res := space.intersect_shape(sq, 1)
		if not res.is_empty():
			var n: Node = res[0].collider
			while n and not n is PieceNode:
				n = n.get_parent()
			return "no room at %s (%s)" % [q.snapped(Vector3.ONE * 0.01), "%s %s" % [n.piece, n.global_position] if n else "?"]
	return ""
