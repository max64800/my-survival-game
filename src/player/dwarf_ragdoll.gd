class_name DwarfRagdoll
extends SkeletonModifier3D
## Big hits (F237: mine cart, swinging boulder or anvil, spiked flail): the dwarf goes floppy like a rag doll,
## tumbles, lies a moment, then gets back up. Started by Dwarf.big_hit (the host), on every player's screen.
##
## Ten physics pieces (hips, chest, upper and lower arms and legs) joined at the joints tumble in the world;
## every frame this turns the matching bones to match them. It runs before DwarfProportions, so the dwarf keeps
## his dwarf shape (Godot's own physical bones would lose it: they can't carry the stretched, scaled skeleton).
## Co-op: everyone starts the same tumble from the same push; on friends' screens the hips are also pulled
## toward where the dwarf's owner says they are, so he lands in the same spot for everyone.
## Meanwhile the Dwarf itself (camera, what friends are sent) stays on the floor right under the hips.

const DOWN_TIME := 2.2   ## seconds lying floppy
const BLEND_TIME := 0.5  ## seconds to blend from the floppy pose into the get-up move
const PULL := 4.0        ## a friend's dwarf: how fast its hips catch up with where its owner has them
## bone -> [the piece it hangs from ("" = none), the bone its capsule reaches to, radius m, mass kg]
const PARTS := {
	"pelvis": ["", "spine_02", 0.2, 14.0],
	"spine_02": ["pelvis", "Head", 0.22, 14.0],
	"upperarm_l": ["spine_02", "lowerarm_l", 0.075, 2.0],
	"lowerarm_l": ["upperarm_l", "hand_l", 0.07, 1.5],
	"upperarm_r": ["spine_02", "lowerarm_r", 0.075, 2.0],
	"lowerarm_r": ["upperarm_r", "hand_r", 0.07, 1.5],
	"thigh_l": ["pelvis", "calf_l", 0.1, 4.0],
	"calf_l": ["thigh_l", "foot_l", 0.09, 3.0],
	"thigh_r": ["pelvis", "calf_r", 0.1, 4.0],
	"calf_r": ["thigh_r", "foot_r", 0.09, 3.0],
}

var dwarf: Dwarf
var _bodies := {}  ## bone index -> RigidBody3D (parents first)
var _q0 := {}      ## bone index -> the piece's world turn at the hit
var _r0 := {}      ## bone index -> the bone's skeleton-space turn at the hit
var _pelvis := -1
var _root := -1
var _hold_pelvis := Vector3.ZERO  ## the hips' spot in the animation at the hit (kept: the fall move shifts it)
var _hold_root := Quaternion()
var _offset := Vector3.ZERO       ## hips piece minus the dwarf's position at the hit (sideways only)
var _t := -1.0
var _shaper: DwarfProportions  ## it lowers the hips after us; we take that into account
var _box: Node3D


func _ready() -> void:
	active = false


## Lying floppy or getting up (the Dwarf doesn't walk or act meanwhile).
func down() -> bool:
	return _t >= 0.0


## push: which way and how hard (m/s). Hit again while down: the new push adds on and the clock starts over.
func start(push: Vector3) -> void:
	var fling := push + Vector3.UP * push.length() * 0.35  # a little off the ground, so it tumbles
	if down():
		_t = 0.0
		influence = 1.0
		for i in _bodies:
			_bodies[i].freeze = false
			_bodies[i].linear_velocity += fling
		return
	var sk := get_skeleton()
	_pelvis = sk.find_bone("pelvis")
	_root = sk.get_bone_parent(_pelvis)
	_hold_pelvis = sk.get_bone_pose_position(_pelvis)
	_hold_root = sk.get_bone_pose_rotation(_root)
	for c in sk.get_children():
		if c is DwarfProportions:
			_shaper = c
	_t = 0.0
	await sk.skeleton_updated  # (only now are the bones dwarf-shaped; read any earlier, they are human-sized)
	_box = Node3D.new()
	_box.top_level = true  # (the pieces live in the world, not under the scaled skeleton)
	add_child(_box)
	var spin := Vector3.UP.cross(push).normalized() * 5.0  # head goes over in the push direction
	for bone in PARTS:
		var info: Array = PARTS[bone]
		var i := sk.find_bone(bone)
		var g := sk.global_transform * sk.get_bone_global_pose(i)
		var end := sk.global_transform * sk.get_bone_global_pose(sk.find_bone(info[1])).origin
		var b := RigidBody3D.new()
		b.collision_layer = 0
		b.collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
		b.mass = info[3]
		b.angular_damp = 1.5
		b.continuous_cd = true
		_box.add_child(b)
		b.global_transform = Transform3D(g.basis.orthonormalized(), g.origin)
		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = info[2]
		cap.height = maxf(g.origin.distance_to(end) + info[2], info[2] * 2.0 + 0.01)
		shape.shape = cap
		b.add_child(shape)
		shape.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, (end - g.origin).normalized())), (g.origin + end) * 0.5)
		if bone == "spine_02":  # the big head (and helmet) bumps the floor too
			var head := CollisionShape3D.new()
			var ball := SphereShape3D.new()
			ball.radius = 0.17
			head.shape = ball
			b.add_child(head)
			head.global_position = end + Vector3.UP * 0.12
		b.linear_velocity = fling
		b.angular_velocity = spin if bone in ["pelvis", "spine_02"] else Vector3.ZERO
		if info[0] != "":
			var j := ConeTwistJoint3D.new()
			_box.add_child(j)
			j.global_transform = Transform3D(Basis(Quaternion(Vector3.RIGHT, (end - g.origin).normalized())), g.origin)
			j.node_a = j.get_path_to(_bodies[sk.find_bone(info[0])])
			j.node_b = j.get_path_to(b)
			j.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(70.0))
			j.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(35.0))
		_bodies[i] = b
		_q0[i] = b.global_basis.get_rotation_quaternion()
		_r0[i] = sk.get_bone_global_pose(i).basis.get_rotation_quaternion()
	_offset = _bodies[_pelvis].global_position - dwarf.global_position
	_offset.y = 0.0
	influence = 1.0
	active = true
	dwarf.model.dwarf_rig.play_full("knock", 0.9)  # (the bones the pieces don't steer: neck, hands, feet)


func _physics_process(delta: float) -> void:
	if not down() or _bodies.is_empty():
		return
	_t += delta
	var hips: RigidBody3D = _bodies[_pelvis]
	if not dwarf.is_local:  # a friend's dwarf: drift the hips sideways toward where its owner has them
		var off := dwarf._net_pos + _offset - hips.global_position
		hips.global_position += Vector3(off.x, 0.0, off.z) * minf(1.0, PULL * delta)
	if _t < DOWN_TIME:
		var q := PhysicsRayQueryParameters3D.create(hips.global_position + Vector3.UP * 0.3,
				hips.global_position + Vector3.DOWN * 3.0, World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
		var hit := hips.get_world_3d().direct_space_state.intersect_ray(q)
		dwarf.global_position = hit.position - _offset if hit else hips.global_position - _offset - Vector3.UP * 0.9
		return
	if _t - delta < DOWN_TIME:  # time to get up: hold still and blend into the get-up move
		for i in _bodies:
			_bodies[i].freeze = true
		dwarf.model.dwarf_rig.play_full("wake", 1.1)
	var k := clampf((_t - DOWN_TIME) / BLEND_TIME, 0.0, 1.0)
	influence = 1.0 - k
	if k >= 1.0:
		_t = -1.0
		active = false
		influence = 1.0
		_box.queue_free()
		_bodies.clear()
		dwarf.velocity = Vector3.ZERO
		if dwarf.fight:
			dwarf.fight.stagger = 0.6  # still finishing the get-up move


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or _bodies.is_empty():
		return
	var s := sk.global_basis.get_rotation_quaternion()
	# The skeleton's base goes wherever puts the hips on their piece (the fall move would drag it off).
	sk.set_bone_pose_rotation(_root, _hold_root)
	sk.set_bone_pose_position(_pelvis, _hold_pelvis)
	var hips := sk.global_transform.affine_inverse() * (_bodies[_pelvis].global_position as Vector3)
	var base := sk.get_bone_parent(_root)
	var above := sk.get_bone_global_pose(base) if base >= 0 else Transform3D()
	sk.set_bone_pose_position(_root, above.affine_inverse() * hips - sk.get_bone_pose(_root).basis * (_hold_pelvis - (_shaper._drop if _shaper else Vector3.ZERO)))
	for i in _bodies:  # (parents first, so each parent is already turned)
		var turn: Quaternion = _bodies[i].global_basis.get_rotation_quaternion() * _q0[i].inverse()
		var want: Quaternion = s.inverse() * turn * s * _r0[i]
		var parent := sk.get_bone_parent(i)
		var up := sk.get_bone_global_pose(parent).basis.get_rotation_quaternion() if parent >= 0 else Quaternion()
		sk.set_bone_pose_rotation(i, up.inverse() * want)
