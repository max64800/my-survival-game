class_name HairSwing
extends SkeletonModifier3D
## Hair that swings (owner, F192: "the 3 braids need a lot of skeleton points where it bends, so it actually looks like
## hair that swings"). The usual game way ("spring bones" / "verlet chains"):
## - every braid (7 bones) and the back hair (one chain of 7) is a chain; each joint is a little weight;
## - each frame a weight keeps the speed it had (so it trails behind and swings), loses some of it (drag), and is pulled
##   gently back toward where it rests (stiffness);
## - no joint may bend more than its kind's bend from its resting direction (seen from the joint above), so a chain can
##   never fold over; the links keep their length; the braids' weights are pushed out of collision balls inside the
##   body (fitted to the shirt by DwarfRig), so they rest on the belly instead of going through it;
## - then each hair bone is placed at its weight, pointing at the next one.
## The hair bones hang off the skeleton's root and are placed directly: the dwarf's skeleton is stretched unevenly (the
## dwarf shaping), and any bone under the head inherited that and skewed when it turned. (That's also why Godot's own
## SpringBoneSimulator3D does nothing here.) The swinging is worked out in world metres. (Claude, Nov 16, 2026)
##
## The back hair (owner, Nov 17: "it lifts off his back like a stiff visor, the bare neck shows"). Measured with
## tools/asset_forge/dwarf_clip_check.py, each of these lifted it off the back:
## - it rested where the head carries it: now, below the head, it lies on the shirt and moves exactly like the shirt
##   point under it (that point's bones and weights, DwarfRig), blended in over the neck; the joints up on the skull
##   don't swing at all (pinned to the head);
## - its drag worked against the world: that acted like a strong headwind whenever he ran and blew the ponytail out flat
##   behind him; now it works against how fast its resting place moves ("air" 0);
## - the collision balls (each riding one bone, the arm ones fat) poked out of the bending shirt and pushed it up to
##   4 cm off: now it simply may never sink below where it rests on the shirt (it may lift off a little when it swings);
## - where the head moves against the back the link over the neck gets longer or shorter: that bone now stretches
##   along its length, like skin at the nape. (Claude, Nov 17, 2026)

const GRAVITY := 0.0  ## (the hair is built hanging, and its resting place now moves with the back it lies on)
## per kind of hair: stiffness (share of the way back to the resting shape per 1/60 s), drag (share of the speed lost
## per 1/60 s), thickness (m), the most one joint may bend (degrees), air (how much of the drag works against the world
## instead of against the resting place: 1 = all of it, a headwind when running). Both heavy: they sway, they don't jump.
## (Owner, Nov 17: the livelier ponytail "jumps too much, looks too light": now heavier than the braids.)
const KINDS := {
	# (smaller swings: bigger ones stretched the hair joining them to the beard and head into sheets, Nov 17)
	# (braids: livelier again, owner Nov 17 evening: "the animation was a little bit better on the front beard before".
	# Halfway back to the noon swing (bend 20, stiff 0.15): all the way stretched the beard by the middle braid up to
	# 18x in mining (sheets); halfway measures the same as the tamer setting)
	# (F943, owner Nov 28: "when he's running it fully detaches; only the ends should flop": the braids now lie on the
	# chest, the top half stays put (loose_from: free from half way down), and the drag works on the resting place, not
	# the world (air 1 was a headwind that lifted the whole braid off his chest))
	"braid": {"stiff": 0.17, "drag": 0.27, "radius": 0.04, "bend": 16.0, "air": 0.35, "loose_from": 0.45},  # (radius: the thicker braids' half-depth + a gap)
	# (back hair: livelier again, owner Nov 17 evening: "it barely moves"; it lies on the shirt now, so it sways, no visor)
	"back": {"stiff": 0.14, "drag": 0.24, "radius": 0.035, "bend": 11.0, "air": 0.0},  # (radius: the hair layer's half-thickness)
	"cloth": {"stiff": 0.22, "drag": 0.3, "radius": 0.02, "bend": 14.0, "air": 0.35},  # (the shirt hem: a light sway and bounce, Nov 18)
}
## Where the back hair goes from riding on the head to lying on the shirt (metres above the floor as built: the same
## heights dwarf_body.py blends the beard and hair over, LOW..HIGH). Joints above HIGH sit on the skull: pinned.
const ON_BACK_LOW := 0.865
const ON_BACK_HIGH := 0.96
const MAX_BEND := deg_to_rad(30.0)  ## the most one joint bends from its resting direction

var _chains := []     ## [{bones, joints (rest, skeleton space, one more than bones), bind_rot, kind, on_back, under, pinned, along_y, p, prev, was, ready}]
var _colliders := []  ## [{bone, local (point in the bone's space), radius (m)}]
var _head := -1
var _head_rest := Transform3D()
var _rest_inv := {}   ## bone -> its rest transform, inverted (the bones the back hair lies on)
var _moved := {}      ## this frame's bone -> how it moved since built (the bones the back hair lies on)
var _global := {}     ## this frame's bone -> skeleton-space transform (worked out from the bones' own poses)
var biggest_swing := 0.0  ## how far a link has trailed from riding along with the head, so far (degrees), for checks
var biggest_fold := 0.0   ## the sharpest bend between two links against their rest, so far (degrees): never past MAX_BEND


## heights: chain -> each joint's height above the floor as built (metres); under: chain -> each joint's
## {bone: weight} of the shirt point under it; rests: bone -> its rest transform (DwarfRig). For the back hair.
func setup(chains: Dictionary, colliders: Array, head: int, head_rest: Transform3D, heights := {}, under := {},
		rests := {}) -> void:
	var sk := get_skeleton()
	_colliders = colliders
	_head = head
	_head_rest = head_rest
	for b: int in rests:
		_rest_inv[b] = (rests[b] as Transform3D).affine_inverse()
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
		var on_back := []  # per joint: 0 = rests where the head carries it, 1 = where the shirt under it carries it
		var pinned := []   # per joint: up on the skull, doesn't swing
		var hs: Array = heights.get(name, [])
		var lies: Array = under.get(name, [])
		# (the back hair and the clothes' springy strips both rest on the body and move with it, swaying a little)
		# (F943, owner Nov 28: the braids came off the chest when he ran; now they lie on the chest like the back hair on
		# the back, and only their ends flop: see "loose")
		var is_back := (name.begins_with("hair_back") or name.begins_with("cloth_") or name.begins_with("hair_braid")) 				and hs.size() == bones.size() and lies.size() == joints.size()
		for i in joints.size():
			var h: float = 0.0
			if is_back:
				h = float(hs[i]) if i < hs.size() else float(hs[-1]) + (float(hs[-1]) - float(hs[-2]))
			var x := clampf((h - ON_BACK_LOW) / (ON_BACK_HIGH - ON_BACK_LOW), 0.0, 1.0)
			on_back.append(1.0 - x * x * (3.0 - 2.0 * x) if is_back else 0.0)
			pinned.append(i == 0 or (is_back and h >= ON_BACK_HIGH))
		var kind: Dictionary = KINDS["cloth"] if name.begins_with("cloth_") else (KINDS["back"] if name.begins_with("hair_back") else KINDS["braid"])
		# does each bone point along its own Y (then it can stretch along its length, like skin at the nape)
		var along_y := []
		for i in bones.size():
			var d: Vector3 = (joints[i + 1] - joints[i]).normalized()
			along_y.append(((bind_rot[i] as Quaternion).inverse() * d).dot(Vector3.UP) > 0.98)
		# how free each joint is to swing: 1 everywhere, but a braid's upper part stays on the chest (F943): free only from
		# loose_from of the way down, growing to fully free at the tip
		var loose := []
		var from: float = float(kind.get("loose_from", 0.0))
		for i in joints.size():
			var f := float(i) / float(joints.size() - 1)
			var x2 := clampf((f - from) / maxf(1.0 - from, 1e-3), 0.0, 1.0) if from > 0.0 else 1.0
			loose.append(x2 * x2 * (3.0 - 2.0 * x2))
		_chains.append({"name": name, "bones": bones, "joints": joints, "bind_rot": bind_rot, "kind": kind, "on_back": on_back,
			"under": lies if is_back else [], "pinned": pinned, "along_y": along_y, "loose": loose,
			"p": [], "prev": [], "was": [], "ready": false})


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
	for b: int in _rest_inv:  # (the bones the back hair lies on: how each moved since built)
		_moved[b] = _pose_global(sk, b) * (_rest_inv[b] as Transform3D)
	var root_inv := _pose_global(sk, 0).affine_inverse()
	for ch in _chains:
		_step(sk, to_world, head_moved, head_turn, root_inv, ch, balls, delta)


## Where a point lying on the shirt is now, and how it turned: moved like the shirt there (its bones, weighted).
func _on_shirt(at: Vector3, weights: Dictionary) -> Array:
	var pos := Vector3.ZERO
	var turn := Quaternion(0, 0, 0, 0)
	var total := 0.0
	for b: int in weights:
		var w: float = weights[b]
		var m: Transform3D = _moved[b]
		pos += (m * at) * w
		var q := m.basis.get_rotation_quaternion()
		turn += (q if turn.dot(q) >= 0.0 else -q) * w
		total += w
	if total <= 0.0:
		return [at, Quaternion.IDENTITY]
	return [pos / total, turn.normalized()]


func _step(sk: Skeleton3D, to_world: Transform3D, head_moved: Transform3D, head_turn: Quaternion, root_inv: Transform3D,
		ch: Dictionary, balls: Array, delta: float) -> void:
	var bones: Array = ch.bones
	var joints: Array = ch.joints
	var on_back: Array = ch.on_back
	var under: Array = ch.under
	var pinned: Array = ch.pinned
	var n := bones.size()
	# where each joint rests now (world), and what turns it: carried by the head, or (the back hair lower down) lying
	# on the shirt and moving with it
	var targets: Array[Vector3] = []
	var carriers: Array[Quaternion] = []
	var outs: Array[Vector3] = []  # (the back hair: which way is out of the shirt under each joint now, world)
	for i in joints.size():
		var j: Vector3 = joints[i]
		var share: float = on_back[i]
		var on_head := head_moved * j
		if under.is_empty():
			targets.append(to_world * on_head)
			carriers.append(head_turn)
			continue
		var lie := _on_shirt(j, under[i].weights)
		targets.append(to_world * (on_head if share <= 0.0 else on_head.lerp(lie[0], share)))
		carriers.append(head_turn if share <= 0.0 else head_turn.slerp(lie[1], share))
		outs.append((to_world.basis * ((lie[1] as Quaternion) * (under[i].out as Vector3))).normalized())
	var p: Array = ch.p
	var prev: Array = ch.prev
	var was: Array = ch.was  # (last frame's resting places)
	if not ch.ready or (p[1] as Vector3).distance_to(targets[1]) > 1.0:  # (first frame, or the dwarf was moved far)
		p = targets.duplicate()
		prev = targets.duplicate()
		was = targets.duplicate()
		ch.ready = true
	var kind: Dictionary = ch.kind
	var keep := pow(1.0 - float(kind.drag), delta * 60.0)
	var pull := 1.0 - pow(1.0 - float(kind.stiff), delta * 60.0)
	var still := 1.0 - float(kind.air)  # (the share of the drag that works against the resting place, not the world)
	p[0] = targets[0]
	prev[0] = targets[0]
	for i in range(1, n + 1):
		var seg := targets[i].distance_to(targets[i - 1])
		if pinned[i]:  # (up on the skull: rides with the head, no swing)
			p[i] = targets[i]
			prev[i] = targets[i]
			continue
		var shape := targets[i] - targets[i - 1]
		var ref := shape.normalized()
		if i >= 2:  # (the resting direction as seen from the joint above as it is now)
			var above_rest := (targets[i - 1] - targets[i - 2]).normalized()
			var above_now := ((p[i - 1] as Vector3) - (p[i - 2] as Vector3)).normalized()
			if above_rest.angle_to(above_now) > 1e-4:
				ref = Quaternion(above_rest, above_now) * ref
		var now: Vector3 = p[i]
		var lo: float = float((ch.loose as Array)[i])  # (1 = swings freely; 0 = stays where it rests, F943)
		var carried: Vector3 = (targets[i] - (was[i] as Vector3)) * lerpf(1.0, still, lo)  # (how far its resting place moved this frame)
		var next: Vector3 = now + carried + (now - (prev[i] as Vector3) - carried) * keep + Vector3.DOWN * GRAVITY * delta * delta
		next = next.lerp((p[i - 1] as Vector3) + shape, lerpf(0.85, pull, lo))
		prev[i] = now
		for _pass in 2:
			var dir: Vector3 = next - (p[i - 1] as Vector3)
			dir = dir.normalized() if dir.length() > 1e-6 else ref
			var max_bend := deg_to_rad(float(kind.bend) * lerpf(0.15, 1.0, lo))
			if ref.angle_to(dir) > max_bend:
				var axis := ref.cross(dir)
				if axis.length() > 1e-6:
					dir = Quaternion(axis.normalized(), max_bend) * ref
			next = (p[i - 1] as Vector3) + dir * seg
			if not outs.is_empty():
				# the back hair lies on the shirt: it may lift off, never sink in below where it rests (the balls,
				# each riding one bone, poked out of the bending shirt and pushed it 4 cm off the back, Nov 17)
				var sink := (next - targets[i]).dot(outs[i])
				if sink < 0.0:
					next -= outs[i] * sink
				continue
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
	ch.was = targets.duplicate()
	# place each hair bone at its weight, pointing at the next one, turned with what carries it (head or back)
	var to_skel := to_world.affine_inverse()
	for i in n:
		var at := to_skel * (p[i] as Vector3)
		var now_dir := (to_skel * (p[i + 1] as Vector3)) - at
		var carrier: Quaternion = carriers[i]
		var rest_dir: Vector3 = carrier * ((joints[i + 1] as Vector3) - (joints[i] as Vector3))
		var rot: Quaternion = carrier * (ch.bind_rot[i] as Quaternion)
		if now_dir.length() > 1e-6 and rest_dir.normalized().angle_to(now_dir.normalized()) > 1e-4:
			rot = Quaternion(rest_dir.normalized(), now_dir.normalized()) * rot
		var bend := rad_to_deg(((p[i + 1] as Vector3) - (p[i] as Vector3)).angle_to(targets[i + 1] - targets[i]))
		biggest_swing = maxf(biggest_swing, bend)
		var basis := Basis(rot)
		var rest_len := ((joints[i + 1] as Vector3) - (joints[i] as Vector3)).length()
		if not under.is_empty() and ch.along_y[i] and rest_len > 1e-6:
			# (the back hair: where it passes from the head to the shirt, the head moving against the back makes the link
			# longer or shorter; the hair on it stretches along with it, like skin at the nape, instead of tearing)
			basis = basis * Basis.from_scale(Vector3(1.0, clampf(now_dir.length() / rest_len, 0.6, 1.6), 1.0))
		var local := root_inv * Transform3D(basis, at)
		sk.set_bone_pose_position(bones[i], local.origin)
		sk.set_bone_pose_rotation(bones[i], local.basis.get_rotation_quaternion())
		sk.set_bone_pose_scale(bones[i], local.basis.get_scale())
