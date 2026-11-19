class_name EvenHead
extends SkeletonModifier3D
## Keeps the dwarf's neck and head their own shape whatever the body does (F280, owner Nov 17: "the head is squashed
## forward like a beak" in the sword and spear moves).
##
## Why: DwarfProportions makes the hips, belly and chest thicker one way than another (THICK Vectors). Every bone under
## an unevenly sized bone gets skewed once the spine bends, and the head sits under all of them. Removing those uneven
## sizes (DwarfProportions.no_skew) broke the arms and the armour, which are bound to the skewed rest pose, so it stays off.
##
## How: the neck and head each get a twin bone hanging straight from the skeleton's root ("neck_01_even", "Head_even"),
## with no stretch. Every frame (after DwarfProportions, before HairSwing) each twin takes its bone's place and turn but
## drops the skew: the twin's move from rest is the pure turn closest to the real bone's move (polar decomposition).
## Everything that was bound to the neck or head (body, beard, helmets, the hair following the head) is bound to the
## twins instead (DwarfRig._bind_to_skeleton, _on_bone). No bone the body or arms hang on changes.

const BONES := ["neck_01", "Head"]
const SUFFIX := "_even"

var _pairs := []  ## [real bone, twin bone, the real bone's shaped rest (skeleton space)]


## Adds the twins to sk. rests = the shaped rest of every bone (DwarfRig.dwarf_rest_poses); the twins' own rests are
## appended to it. Returns {real bone name: twin name}.
func setup(sk: Skeleton3D, rests: Array) -> Dictionary:
	var names := {}
	var root_rest: Transform3D = rests[0]
	for bn: String in BONES:
		var real := sk.find_bone(bn)
		if real < 0:
			continue
		var rest: Transform3D = rests[real]
		var twin := sk.add_bone(bn + SUFFIX)
		sk.set_bone_parent(twin, 0)
		var twin_rest := Transform3D(Basis(), rest.origin)  # (no turn, no size: a twin may never hold a skew)
		sk.set_bone_rest(twin, root_rest.affine_inverse() * twin_rest)
		sk.reset_bone_pose(twin)
		rests.append(twin_rest)
		_pairs.append([real, twin, rest])
		names[bn] = bn + SUFFIX
	return names


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or _pairs.is_empty():
		return
	var root_g := sk.get_bone_global_pose(0)
	for pr: Array in _pairs:
		var g := sk.get_bone_global_pose(pr[0])
		var rest: Transform3D = pr[2]
		var turn := _nearest_turn(g.basis * rest.basis.inverse())
		var local := root_g.affine_inverse() * Transform3D(Basis(turn), g.origin)
		sk.set_bone_pose_position(pr[1], local.origin)
		sk.set_bone_pose_rotation(pr[1], local.basis.get_rotation_quaternion())
		sk.set_bone_pose_scale(pr[1], local.basis.get_scale())


## The pure turn closest to a (skewed, stretched) basis: polar decomposition by averaging with its inverse transpose.
static func _nearest_turn(m: Basis) -> Quaternion:
	var r := m
	for k in 8:
		r = Basis(r.x + r.inverse().transposed().x, r.y + r.inverse().transposed().y, r.z + r.inverse().transposed().z) * 0.5
	return r.get_rotation_quaternion()
