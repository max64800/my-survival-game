class_name DwarfProportions
extends SkeletonModifier3D
## Turns a normal human skeleton into dwarf proportions, every frame, AFTER the animation:
## short legs, slightly short arms, a big head and big hands. The animations only turn bones
## (they never move or stretch them), so we can safely move the joints closer together here.
## The hips are lowered by exactly what the legs lost, so the feet still touch the floor.

## How long each bone becomes (1.0 = normal), by moving the next joint closer.
const LENGTHS := {
	"calf_l": 0.58, "calf_r": 0.58,   # thigh length (the knee moves up)
	"foot_l": 0.6, "foot_r": 0.6,     # shin length (the ankle moves up)
	"spine_02": 0.9, "spine_03": 0.9, # a slightly shorter, rounder body
	"lowerarm_l": 0.88, "lowerarm_r": 0.88,
	"hand_l": 0.9, "hand_r": 0.9,
	"neck_01": 0.45,                  # hardly any neck
}
## Size of a bone and everything on it (uniform, so nothing gets skewed).
## spine_01 grows the whole upper body (chest, shoulders, arms, head): top-heavy, like a dwarf.
const SIZES := {"spine_01": 1.18, "Head": 1.12, "hand_l": 1.15, "hand_r": 1.15, "foot_l": 1.25, "foot_r": 1.25,
	"thigh_l": 1.15, "thigh_r": 1.15}

var _pos := {}    ## bone index -> shortened local position
var _scale := {}  ## bone index -> scale
var _pelvis := -1
var _drop := Vector3.ZERO  ## how much to lower the hips (in the pelvis' parent space)
var _from_anim := Vector3.ZERO
var _written := Vector3.INF


func setup(sk: Skeleton3D) -> void:
	for b in LENGTHS:
		var i := sk.find_bone(b)
		if i >= 0:
			_pos[i] = sk.get_bone_rest(i).origin * LENGTHS[b]
	for b in SIZES:
		var i := sk.find_bone(b)
		if i >= 0:
			_scale[i] = Vector3.ONE * SIZES[b]
	_pelvis = sk.find_bone("pelvis")
	# Measure how much higher the feet sit after shortening the legs (in the rest pose).
	var foot := sk.find_bone("foot_l")
	if foot >= 0 and _pelvis >= 0:
		var before := _rest_global(sk, foot, false).origin
		var after := _rest_global(sk, foot, true).origin
		var parent := sk.get_bone_parent(_pelvis)
		var to_parent := _rest_global(sk, parent, false).basis.inverse() if parent >= 0 else Basis()
		_drop = to_parent * Vector3(0, after.y - before.y, 0)


## The rest-pose transform of a bone in skeleton space, with or without our changes.
func _rest_global(sk: Skeleton3D, i: int, changed: bool) -> Transform3D:
	var t := Transform3D()
	var chain := []
	while i >= 0:
		chain.push_front(i)
		i = sk.get_bone_parent(i)
	for b in chain:
		var local := sk.get_bone_rest(b)
		if changed and _pos.has(b):
			local.origin = _pos[b]
		if changed and _scale.has(b):
			local.basis = local.basis.scaled(_scale[b])
		t = t * local
	return t


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for i in _pos:
		sk.set_bone_pose_position(i, _pos[i])
	for i in _scale:
		sk.set_bone_pose_scale(i, _scale[i])
	if _pelvis >= 0:
		# Only lower the hips from what the animation wrote, never twice (if the animation
		# skipped a frame, the pose still holds our own lowered value).
		var now := sk.get_bone_pose_position(_pelvis)
		if not now.is_equal_approx(_written):
			_from_anim = now
		_written = _from_anim - _drop
		sk.set_bone_pose_position(_pelvis, _written)
