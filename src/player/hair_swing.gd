class_name HairSwing
extends SkeletonModifier3D
## Hair that swings (owner, F192: "the 3 braids need a lot of skeleton points where it bends, so it actually looks like
## hair that swings"). The usual game way ("spring bones" / "verlet chains"):
## - every braid (7 bones) and strand of back hair (4 bones) is a chain; each joint is a little weight;
## - each frame a weight keeps the speed it had (so it trails behind and swings), loses some of it (drag), and is pulled
##   gently back toward where the head would carry it (stiffness);
## - no joint may bend more than MAX_BEND from its resting direction (seen from the joint above), so a chain can never
##   fold over; the links keep their length; the weights are pushed out of collision balls inside the body (fitted to
##   the shirt by DwarfRig), so the hair rests on the belly and back instead of going through them;
## - then each hair bone is placed at its weight, pointing at the next one.
## The hair bones hang off the skeleton's root and are placed directly: the dwarf's skeleton is stretched unevenly (the
## dwarf shaping), and any bone under the head inherited that and skewed when it turned. (That's also why Godot's own
## SpringBoneSimulator3D does nothing here.) The swinging is worked out in world metres. (Claude, Nov 16, 2026)

const GRAVITY := 0.0  ## (the hair is built hanging; extra gravity piled up down the chain and sagged it 21 cm)
## per kind of hair: stiffness (share of the way back to the resting shape per 1/60 s), drag (share of the speed lost
## per 1/60 s), thickness (m). Heavy braids: firm and slow; the back hair a little livelier.
const KINDS := {
	"braid": {"stiff": 0.12, "drag": 0.2, "radius": 0.024},
	"back": {"stiff": 0.07, "drag": 0.14, "radius": 0.02},  # (the big ponytail: livelier, so its swing shows, F215)
}
const MAX_BEND := deg_to_rad(30.0)  ## the most one joint bends from its resting direction

var _chains := []     ## [{bones, joints (rest, skeleton space, one more than bones), bind_rot, kind, p, prev, ready}]
var _colliders := []  ## [{bone, local (point in the bone's space), radius (m)}]
var _head := -1
var _head_rest := Transform3D()
var _global := {}     ## this frame's bone -> skeleton-space transform (worked out from the bones' own poses)
var biggest_swing := 0.0  ## how far a link has trailed from riding along with the head, so far (degrees), for checks
var biggest_fold := 0.0   ## the sharpest bend between two links against their rest, so far (degrees): never past MAX_BEND


func setup(chains: Dictionary, colliders: Array, head: int, head_rest: Transform3D) -> void:
	var sk := get_skeleton()
	_colliders = colliders
	_head = head
	_head_rest = head_rest
	for name: String in chains:
		var bones: Array = chains[name]
		if bones.size() < 2:
			continue
		var joints: Array[Vector3] = []
		var bind_rot := []
		for b in bones:
			var g := sk.get_bone_global_rest(b)
			joints.append(g.origin)
			bind_rot.append(g.basis.get_rotation_quaternion())
		joints.append(joints[-1] + (joints[-1] - joints[-2]))  # the last bone's tip
		_chains.append({"bones": bones, "joints": joints, "bind_rot": bind_rot,
			"kind": KINDS["back"] if name.begins_with("hair_back") else KINDS["braid"], "p": [], "prev": [], "ready": false})


## A bone's skeleton-space transform from the bones' current local poses. (Inside a modifier, get_bone_global_pose()
## still gives the pose from before DwarfProportions: the human-sized skeleton.)
func _pose_global(sk: Skeleton3D, bone: int) -> Transform3D:
	if _global.has(bone):
		return _global[bone]
	var t := sk.get_bone_pose(bone)
	var parent := sk.get_bone_parent(bone)
	if parent >= 0:
		t = _pose_global(sk, parent) * t
	_global[bone] = t
	return t


func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or delta <= 0.0 or _chains.is_empty() or _head < 0:
		return
	_global.clear()
	var to_world := sk.global_transform
	var balls := []
	for c in _colliders:
		balls.append([to_world * (_pose_global(sk, c.bone) * c.local), c.radius])
	var head_moved := _pose_global(sk, _head) * _head_rest.affine_inverse()  # the head now, against how it was built
	var head_turn := head_moved.basis.get_rotation_quaternion()
	var root_inv := _pose_global(sk, 0).affine_inverse()
	for ch in _chains:
		_step(sk, to_world, head_moved, head_turn, root_inv, ch, balls, delta)


func _step(sk: Skeleton3D, to_world: Transform3D, head_moved: Transform3D, head_turn: Quaternion, root_inv: Transform3D,
		ch: Dictionary, balls: Array, delta: float) -> void:
	var bones: Array = ch.bones
	var joints: Array = ch.joints
	var n := bones.size()
	# where each joint would be if the hair just rode along with the head (world)
	var targets: Array[Vector3] = []
	for j in joints:
		targets.append(to_world * (head_moved * (j as Vector3)))
	var p: Array = ch.p
	var prev: Array = ch.prev
	if not ch.ready or (p[1] as Vector3).distance_to(targets[1]) > 1.0:  # (first frame, or the dwarf was moved far)
		p = targets.duplicate()
		prev = targets.duplicate()
		ch.ready = true
	var kind: Dictionary = ch.kind
	var keep := pow(1.0 - float(kind.drag), delta * 60.0)
	var pull := 1.0 - pow(1.0 - float(kind.stiff), delta * 60.0)
	p[0] = targets[0]
	prev[0] = targets[0]
	for i in range(1, n + 1):
		var seg := targets[i].distance_to(targets[i - 1])
		var shape := targets[i] - targets[i - 1]
		var ref := shape.normalized()
		if i >= 2:  # (the resting direction as seen from the joint above as it is now)
			var above_rest := (targets[i - 1] - targets[i - 2]).normalized()
			var above_now := ((p[i - 1] as Vector3) - (p[i - 2] as Vector3)).normalized()
			if above_rest.angle_to(above_now) > 1e-4:
				ref = Quaternion(above_rest, above_now) * ref
		var now: Vector3 = p[i]
		var next: Vector3 = now + (now - (prev[i] as Vector3)) * keep + Vector3.DOWN * GRAVITY * delta * delta
		next = next.lerp((p[i - 1] as Vector3) + shape, pull)
		prev[i] = now
		for _pass in 2:
			var dir: Vector3 = next - (p[i - 1] as Vector3)
			dir = dir.normalized() if dir.length() > 1e-6 else ref
			if ref.angle_to(dir) > MAX_BEND:
				var axis := ref.cross(dir)
				if axis.length() > 1e-6:
					dir = Quaternion(axis.normalized(), MAX_BEND) * ref
			next = (p[i - 1] as Vector3) + dir * seg
			for ball in balls:
				var away: Vector3 = next - (ball[0] as Vector3)
				var need: float = float(ball[1]) + float(kind.radius)
				if away.length() < need and away.length() > 1e-6:
					next = (ball[0] as Vector3) + away.normalized() * need
		var last: Vector3 = next - (p[i - 1] as Vector3)
		p[i] = (p[i - 1] as Vector3) + (last.normalized() if last.length() > 1e-6 else ref) * seg
		biggest_fold = maxf(biggest_fold, rad_to_deg(ref.angle_to(((p[i] as Vector3) - (p[i - 1] as Vector3)).normalized())))
	ch.p = p
	ch.prev = prev
	# place each hair bone at its weight, pointing at the next one, turned with the head
	var to_skel := to_world.affine_inverse()
	for i in n:
		var at := to_skel * (p[i] as Vector3)
		var now_dir := (to_skel * (p[i + 1] as Vector3)) - at
		var rest_dir: Vector3 = head_turn * ((joints[i + 1] as Vector3) - (joints[i] as Vector3))
		var rot: Quaternion = head_turn * (ch.bind_rot[i] as Quaternion)
		if now_dir.length() > 1e-6 and rest_dir.normalized().angle_to(now_dir.normalized()) > 1e-4:
			rot = Quaternion(rest_dir.normalized(), now_dir.normalized()) * rot
		var bend := rad_to_deg(((p[i + 1] as Vector3) - (p[i] as Vector3)).angle_to(targets[i + 1] - targets[i]))
		biggest_swing = maxf(biggest_swing, bend)
		var local := root_inv * Transform3D(Basis(rot), at)
		sk.set_bone_pose_position(bones[i], local.origin)
		sk.set_bone_pose_rotation(bones[i], local.basis.get_rotation_quaternion())
		sk.set_bone_pose_scale(bones[i], local.basis.get_scale())
