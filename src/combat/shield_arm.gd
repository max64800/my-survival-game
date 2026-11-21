class_name ShieldArm
extends SkeletonModifier3D
## The Prop Warden's plank shield held up in front of him (owner, Nov 21, F548: "no shield showed"). His shield blocks
## most hits from the front (MonsterManager._shield_blocks); this shows it: while he walks at you, stands guard or
## charges, his left arm (the shield is fixed to its forearm) holds the pose of the pack's "Block" move, over whatever
## his legs and right arm are doing. CreatureRig fades it in and out with `influence` (down for his two-handed moves).
##
## The pattern: a SkeletonModifier3D (like the dwarf's DwarfFist) that writes a few bones after the AnimationPlayer.
## (Not an AnimationTree with a filtered blend: the rest of the creature is played straight from code by CreatureRig.)

const CLIP := "Block"
const HOLD_AT := 0.6  ## part of the Block move to hold: the arm is up and steady from about 0.4 on (measured)
const BONES := ["upperarm.l", "lowerarm.l", "wrist.l", "hand.l", "handslot.l"]

var _pose := {}  ## bone index -> rotation from the Block move (the forearm, wrist and hand: in their own space)
var _upper := -1  ## the upper arm: held at the Block move's direction in the body's space (Block also turns his
var _upper_q := Quaternion.IDENTITY  ## chest; copying only the arm's own turn left the shield out at his side)


## Fixes the arm pose from the model's Block move. False when the model has no Block move or no left arm.
func setup(ap: AnimationPlayer, sk: Skeleton3D) -> bool:
	if not ap.has_animation(CLIP):
		return false
	var a := ap.get_animation(CLIP)
	var rot := {}  ## bone index -> its rotation in the Block move at HOLD_AT
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
			continue
		var i := sk.find_bone(String(a.track_get_path(t).get_concatenated_subnames()))
		if i >= 0:
			rot[i] = a.rotation_track_interpolate(t, a.length * HOLD_AT)
	for bone: String in BONES:
		var i := sk.find_bone(bone)
		if i >= 0 and rot.has(i):
			_pose[i] = rot[i]
	_upper = sk.find_bone(BONES[0])
	if _upper < 0 or not _pose.has(_upper):
		return false
	_pose.erase(_upper)
	var q := Quaternion.IDENTITY  # the upper arm's turn in the skeleton's space: every bone above it, in the Block move
	var b := _upper
	while b >= 0:
		q = Quaternion(rot.get(b, sk.get_bone_rest(b).basis.get_rotation_quaternion())) * q
		b = sk.get_bone_parent(b)
	_upper_q = q
	_face_front(sk)
	influence = 0.0
	return true


## The plank lies flat along his forearm (in the Block move its face pointed up: from the front you saw only its edge).
## Turn the forearm about its own length so the plank's face points straight ahead (+Z: where he looks).
func _face_front(sk: Skeleton3D) -> void:
	var lower := sk.find_bone(BONES[1])
	var mesh := sk.find_child("shield", false, false) as MeshInstance3D
	if lower < 0 or not _pose.has(lower) or mesh == null or mesh.mesh == null:
		return
	var mid := Vector3.ZERO  # the middle of the plank (the mesh is in the skeleton's bind space)
	var verts: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for v in verts:
		mid += v
	mid /= maxf(verts.size(), 1)
	var rest := sk.get_bone_global_rest(lower)
	var out := rest.basis.inverse() * (mid - rest.origin)  # from the forearm out to the plank, in the forearm's space
	out.y = 0.0  # (only across the arm: along its length doesn't matter)
	if out.length() < 0.001:
		return
	var g := (_upper_q * Quaternion(_pose[lower])).normalized()  # the forearm in the body's space, held up
	var axis := (g * Vector3.UP).normalized()
	var now := g * out.normalized()
	var want := Vector3.BACK  # (+Z)
	now -= axis * now.dot(axis)
	want -= axis * want.dot(axis)
	if now.length() < 0.001 or want.length() < 0.001:
		return
	_pose[lower] = Quaternion(_pose[lower]) * Quaternion(Vector3.UP, now.signed_angle_to(want, axis))


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or _upper < 0:
		return
	var parent := sk.get_bone_parent(_upper)
	var above := sk.get_bone_global_pose(parent).basis.get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY
	sk.set_bone_pose_rotation(_upper, above.inverse() * _upper_q)
	for i: int in _pose:
		sk.set_bone_pose_rotation(i, _pose[i])
