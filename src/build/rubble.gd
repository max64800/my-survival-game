class_name Rubble
extends StaticBody3D
## A building piece that fell down (owner, Nov 15, F90): it tumbles to where the host says it lands,
## then lies there as solid rubble you bump into and can stand on. Hit it with a pickaxe a few times
## to clear it and get half its materials back. Everyone sees it in the same place (co-op).

const HITS := 3
const TUMBLE_TIME := 0.7

var rubble_id := 0
var piece := ""
var family := ""
var hits := 0  ## host: pickaxe hits so far


## start = where the piece stood; end = where it lies (both world transforms).
func setup(p_id: int, p_piece: String, p_family: String, start: Transform3D, end: Transform3D, animate: bool) -> void:
	rubble_id = p_id
	piece = p_piece
	family = p_family
	collision_layer = World.TERRAIN_LAYER  # walk on it, bump into it, aim at it
	collision_mask = 0
	var s: Vector3 = (Pieces.LIST[piece].size as Vector3).max(Vector3.ONE * 0.2)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = s
	cs.shape = box
	cs.position = Vector3.UP * s.y * 0.5
	add_child(cs)
	var mi := MeshInstance3D.new()
	var made := PieceNode.forged_mesh(piece, family)
	mi.mesh = made if made else PieceMesh.visual(piece, family)
	mi.material_override = null if made else PieceNode._mat(family)
	add_child(mi)
	global_transform = end
	if animate:
		mi.transform = end.affine_inverse() * start
		var tw := mi.create_tween()
		tw.tween_property(mi, "transform", Transform3D.IDENTITY, TUMBLE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Where a fallen piece ends up: on its side if it was standing tall, a little tilted, resting on
## whatever is below (`floor_y`). `tilt` and `turn` come from the host so everyone agrees.
static func landing(piece_id: String, standing: Transform3D, floor_y: float, tilt: float, turn: float) -> Transform3D:
	var s: Vector3 = (Pieces.LIST[piece_id].size as Vector3).max(Vector3.ONE * 0.2)
	var basis := standing.basis.orthonormalized()
	var lift := 0.0
	if s.y > maxf(s.x, s.z) * 0.9:  # tall pieces fall over
		basis = basis * Basis(Vector3.RIGHT, PI / 2.0 + tilt)
		lift = s.z * 0.5
	else:
		basis = basis * Basis(Vector3.FORWARD, tilt)
	basis = Basis(Vector3.UP, turn) * basis
	var origin := standing.origin
	origin.y = floor_y + lift
	return Transform3D(basis, origin)
