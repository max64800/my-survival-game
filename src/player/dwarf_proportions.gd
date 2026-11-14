class_name DwarfProportions
extends SkeletonModifier3D
## Turns a normal human skeleton into a dwarf, every frame, AFTER the animation.
## A dwarf is not a small human: short, thick legs; broad shoulders; a barrel chest; thick arms;
## big hands and feet; a big head on hardly any neck; a wide, planted stance.
##
## Two kinds of change (the animations only turn bones, so both are safe):
## - THICK: a bone and everything on it gets bigger (uniform scale, so nothing is skewed).
## - LENGTHS: how far a joint sits from the one before it, as a share of a human's.
##   Making a bone thick would also make everything after it longer, so each joint is pulled
##   back in by exactly the thickness above it. Result: thick AND short.
## The hips are lowered by exactly what the legs lost, so the feet still touch the floor.

## Bone thickness (multiplies down the chain: hands also get the arm's thickness).
## A number = the same in every direction. A Vector3 = (sideways, along the bone, front-back):
## the belly bones get wide and deep but not taller, then the chest bones undo most of it,
## so only the middle bulges out: a round, fat dwarf belly (owner feedback F25: stout, not muscly).
const THICK := {
	"pelvis": Vector3(1.25, 1.0, 1.3),
	"spine_01": Vector3(1.3, 1.0, 1.45),        # the belly: out to the sides and the front
	"spine_02": Vector3(0.95, 1.0, 0.85),       # chest: still round (cumulative ~1.24 × 1.23)
	"spine_03": Vector3(0.82, 1.0, 0.8),        # shoulders back to near-normal width
	"thigh_l": Vector3(0.9, 1.15, 0.85), "thigh_r": Vector3(0.9, 1.15, 0.85),  # undo the hips' bulge, stubby thick legs
	"upperarm_l": 1.15, "upperarm_r": 1.15,     # sturdy, not muscle-bound
	"hand_l": 1.3, "hand_r": 1.3,               # big hands
	"Head": 1.15,                               # a big head (helmet + beard grow with it)
}
## Where each joint sits, as a share of a human's distance from the joint before it.
const LENGTHS := {
	"upperarm_l": 1.15, "upperarm_r": 1.15,     # shoulder width (round, not a V-shape)
	"lowerarm_l": 0.55, "lowerarm_r": 0.55,     # upper-arm length (short arms: hands reach the hips)
	"hand_l": 0.55, "hand_r": 0.55,             # forearm length
	"thigh_l": 1.2, "thigh_r": 1.2,             # hip width (planted stance)
	"calf_l": 0.32, "calf_r": 0.32,             # thigh length (stubby legs: about 1/4 of the height)
	"foot_l": 0.34, "foot_r": 0.34,             # shin length
	"spine_02": 0.85, "spine_03": 0.85,         # a short, round body
	"neck_01": 0.3, "Head": 0.5,                # hardly any neck
}

var _pos := {}    ## bone index -> new local position
var _scale := {}  ## bone index -> scale
var _pelvis := -1
var _drop := Vector3.ZERO  ## how much to lower the hips (in the pelvis' parent space)
var drop_height := 0.0     ## the same, as plain height in skeleton space (metres before scaling)
var _from_anim := Vector3.ZERO
var _frames := 0
var _feet := PackedInt32Array()  ## toe + foot bones, for the one-time "are the feet on the floor?" check
var _ground := 0.0               ## where the human's feet were in the same pose (skeleton space)
var _written := Vector3.INF


func setup(sk: Skeleton3D) -> void:
	# How thick each bone ends up in total (its own thickness times all the ones above it).
	var total := {}
	for i in sk.get_bone_count():
		total[i] = _total_thickness(sk, i)
		if THICK.has(sk.get_bone_name(i)):
			_scale[i] = _thick(sk.get_bone_name(i))
	for b in LENGTHS:
		var i := sk.find_bone(b)
		if i < 0:
			continue
		var p := sk.get_bone_parent(i)
		var above: Vector3 = total[p] if p >= 0 else Vector3.ONE
		_pos[i] = sk.get_bone_rest(i).origin * LENGTHS[b] / above
	_pelvis = sk.find_bone("pelvis")
	for b in ["ball_l", "ball_r", "foot_l", "foot_r"]:
		if sk.find_bone(b) >= 0:
			_feet.append(sk.find_bone(b))
	# Measure how much higher the feet sit after shortening the legs (in the rest pose).
	var foot := sk.find_bone("foot_l")
	if foot >= 0 and _pelvis >= 0:
		var before := _rest_global(sk, foot, false).origin
		var after := _rest_global(sk, foot, true).origin
		var parent := sk.get_bone_parent(_pelvis)
		var to_parent := _rest_global(sk, parent, false).basis.inverse() if parent >= 0 else Basis()
		_drop = to_parent * Vector3(0, after.y - before.y, 0)
		drop_height = after.y - before.y


## A bone's own thickness times the thickness of every bone above it (per direction; close
## enough, since the bones of one body part point roughly the same way).
static func _total_thickness(sk: Skeleton3D, i: int) -> Vector3:
	var t := Vector3.ONE
	while i >= 0:
		t *= _thick(sk.get_bone_name(i))
		i = sk.get_bone_parent(i)
	return t


static func _thick(bone: String) -> Vector3:
	var v = THICK.get(bone, 1.0)
	return v if v is Vector3 else Vector3.ONE * float(v)


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
		_frames += 1
		if _frames == 2:
			_ground = _lowest_foot(sk, false)  # the animation's own feet, before our changes
		elif _frames == 12:
			_settle_feet(sk)


## One time, a moment after appearing: if the feet ended up above (or below) where the
## animation had them, move the hips by exactly that much. The maths above gets close; this
## makes it exact, whatever the belly and leg changes did.
func _settle_feet(sk: Skeleton3D) -> void:
	var gap := _lowest_foot(sk, true) - _ground
	if absf(gap) < 0.002:
		return
	var parent := sk.get_bone_parent(_pelvis)
	var to_parent := _rest_global(sk, parent, false).basis.inverse() if parent >= 0 else Basis()
	_drop += to_parent * Vector3(0, gap, 0)
	drop_height += gap


func _lowest_foot(sk: Skeleton3D, with_changes: bool) -> float:
	var low := INF
	for i in _feet:
		var y: float
		if with_changes:
			y = sk.get_bone_global_pose(i).origin.y
		else:
			y = _pose_global(sk, i).origin.y
		low = minf(low, y)
	return low


## A bone's current pose in skeleton space using only the animation (none of our changes).
func _pose_global(sk: Skeleton3D, i: int) -> Transform3D:
	var t := Transform3D()
	var chain := []
	while i >= 0:
		chain.push_front(i)
		i = sk.get_bone_parent(i)
	for b in chain:
		var local := Transform3D(Basis(sk.get_bone_pose_rotation(b)), sk.get_bone_rest(b).origin)
		if b == _pelvis:
			local.origin = _from_anim
		t = t * local
	return t
