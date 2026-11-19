class_name DwarfFist
extends SkeletonModifier3D
## The dwarf's fists (owner, Nov 19: "the handle runs past his hand and his fingers stay open; he isn't really gripping
## it"). Runs after every animation frame, after the dwarf shaping (DwarfProportions), and changes only the hands:
##  - Holding a tool or weapon with a handle: the right fingers close into a tight fist, the thumb folded over them
##    (owner's pick). With a shield on: the left fingers close round its strap.
##  - The wrist turns so the hole through the fist points along the handle, and the tool slides so the handle runs
##    through the middle of the fist with a small stub (STUB) poking out below the little finger.
##    The tool itself still points exactly where the old grip put it (DwarfRig.GRIPS, the running shoulder carry, the
##    spear's level thrust: DwarfRig.hold_turn), so every swing looks as before; only the hand follows the handle now.
## The animations themselves are untouched (owner: "keep the moves"). Purely a look: nothing here is shared in co-op.
## By the dwarf-animations Claude, chat 3, Nov 19, 2026.

## How far each finger joint closes: [joint 1, joint 2, joint 3] in degrees, about the bend axis the pack's own
## standing animation curls that joint about (made by hand, so the bend directions are right).
const CURL := {
	"index": [80.0, 85.0, 70.0], "middle": [80.0, 85.0, 70.0], "ring": [80.0, 85.0, 70.0], "pinky": [80.0, 85.0, 70.0],
	"thumb": [20.0, 30.0, 60.0],
}
## Tools held by a handle through the fist (the rest, like a stone or a mushroom, sit in the open hand as before).
const HANDLE_LOOKS := ["pickaxe", "axe", "axe_2h", "sword", "mace", "mace_2h", "hammer", "shovel", "spear"]
const STUB := 0.05        ## m of handle below the fist (owner's pick: "a small stub, about a thumb's width")
const FINGER_HALF := 0.012  ## half a finger's thickness (m): the fist's edge is this far past the outer knuckle
## The most the wrist turns to line the fist up with the handle (degrees). Most tools need 20-45; past this a wrist
## looks broken (the spear, held pointing along the forearm, needed 110-130), so the tool tilts the rest of the way.
const WRIST_MAX := 45.0
const WRIST_MAX_TWO := 80.0  ## with both hands on a great weapon (the tilt toward the left hand must not be undone)

## Off = the old way, for the page's "Before" (tools/asset_forge/dwarf_anim_export.gd hands=1): fingers as the
## animation has them, the tool turned in the open hand about the wrist.
static var use_fist := true

var rig: DwarfRig
var _hands := {}   ## "_r"/"_l" -> hand bone index
var _joints := {}  ## "_r"/"_l" -> [[bone, rest rotation, bend axis (bone space), degrees], ...]
var _ring := {}    ## "_r"/"_l" -> bones whose joints ring the handle (index..pinky 01, 02, 03, tips)
var _knuckles := {}  ## "_r"/"_l" -> [index_01, pinky_01]
## Measured each frame from the closed fingers (world space), for the grip and for the test:
var fist_center := Vector3.ZERO  ## the middle of the hole through the right fist
var fist_axis := Vector3.UP      ## the hole's direction, from the little finger to the index finger
var fist_radius := 0.0           ## how far the finger joints sit from the middle (m)
var fist_half := 0.0             ## half the fist's width along the handle (m)
var holding := false             ## the right fist is closed round a handle this frame
var wrist_turn := 0.0            ## how far the wrist turned this frame to line the fist up (degrees)
## The held tool's handle, measured from its model (tool holder space): [the handle's middle line's offset from the
## holder's axis, where the handle ends along that axis]. Measured, not assumed (Nov 19, owner: "the axe still needs
## work"): the axe's handle sits 5.5 cm off the axis in its model (the stone axe 7 cm), and every handle ends at the
## holder, not 10 cm below it as the old note said.
var handle := [Vector3.ZERO, 0.0]
## The shield's back (tools/asset_forge/builds/items_tools.py shield_back, in the shield model's space; the same on
## every shield): the upright hand grip near the rim and the wide forearm strap in the middle. Worn like a real round
## shield (owner, Nov 19: "his hand should hold the grip, the forearm goes through the straps"): the left fist closes
## on the grip and the forearm runs through the two leather loops toward the middle.
const SHIELD_GRIP := Vector3(0.211, 0.355, -0.12)
const SHIELD_GRIP_DIR := Vector3.UP
const SHIELD_STRAP := Vector3(0.056, 0.355, -0.12)  ## toward the loops, flat along the board (the forearm runs grip -> loops)
const SHIELD_FACE := Vector3.BACK  ## the painted front (+Z of the model)
const SHIELD_LOOPS := [Vector3(0.111, 0.41, -0.08), Vector3(0.056, 0.41, -0.08)]  ## the forearm loops' middles
const GRIP_SLIDE_MAX := 0.05  ## m the fist may sit off the grip's middle
## Two-handed weapons (owner, Nov 19: "the great axe and great maul are two-handed"; picks: both hands always except
## running, the left hand higher up the handle, like a sledgehammer): the left arm reaches the handle (two-bone IK).
const TWO_HANDED := ["axe_2h", "mace_2h"]
const TWO_HAND_GAPS := [0.2, 0.17, 0.14, 0.11]  ## m between the fists' middles, the widest the arm reaches
var two_hand := 0.0  ## how much the left hand is on the handle this frame (0 = off, while running or rolling)
var left_gap := 0.0  ## the gap used this frame
var left_miss := 0.0  ## how far the left fist ended from its spot on the handle this frame (m)
var _push := 0.0  ## extra m the right fist comes in, learnt from the last frames (fast swings: the reach guess falls short)
var left_center := Vector3.ZERO  ## the middle of the hole through the left fist (world), measured like the right
var left_axis := Vector3.UP
var _handles := {}  ## tool node id -> handle


func setup(sk: Skeleton3D, owner_rig: DwarfRig) -> void:
	rig = owner_rig
	var idle: Animation = rig.tree.get_animation(DwarfRig.ANIMS.idle) if rig.tree.has_animation(DwarfRig.ANIMS.idle) else null
	for side in ["_r", "_l"]:
		_hands[side] = sk.find_bone("hand" + side)
		var joints := []
		var ring := []
		for f: String in CURL:
			for j in 3:
				var b := sk.find_bone("%s_0%d%s" % [f, j + 1, side])
				if b < 0:
					continue
				var rest := sk.get_bone_rest(b).basis.get_rotation_quaternion()
				joints.append([b, rest, _bend_axis(sk, idle, b, rest), (CURL[f] as Array)[j]])
				if f != "thumb":
					ring.append(b)
			var tip := sk.find_bone("%s_04_leaf%s" % [f, side])
			if f != "thumb" and tip >= 0:
				ring.append(tip)
		_joints[side] = joints
		_ring[side] = ring
		_knuckles[side] = [sk.find_bone("index_01" + side), sk.find_bone("pinky_01" + side)]


## The axis a finger joint bends about (in its own space): from the pack's standing animation, which curls every finger.
static func _bend_axis(sk: Skeleton3D, idle: Animation, b: int, rest: Quaternion) -> Vector3:
	if idle:
		var name := ":" + sk.get_bone_name(b)
		for t in idle.get_track_count():
			if idle.track_get_type(t) == Animation.TYPE_ROTATION_3D and str(idle.track_get_path(t)).ends_with(name):
				var d := rest.inverse() * idle.rotation_track_interpolate(t, 0.0)
				if d.get_angle() > 0.05:
					return d.get_axis().normalized()
	return Vector3.RIGHT


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or rig == null or not is_instance_valid(rig.grip):
		return
	var has_tool := rig.grip.get_child_count() > 0
	if not use_fist:
		holding = false
		_old_hold(sk)
		return
	holding = has_tool and rig.tool_look in HANDLE_LOOKS
	if holding:
		_close("_r", sk)
	if rig.shield_grip.get_child_count() > 0:
		_close("_l", sk)
		_wear_shield(sk)
	two_hand = 0.0
	if holding and rig.tool_look in TWO_HANDED and rig.shield_grip.get_child_count() == 0:
		# both hands in the swings; standing, walking and running it rests on his shoulder in one hand (owner, Nov 19,
		# after a try with both hands on the shoulder: his short arms and big chest put the fists inside his beard)
		two_hand = 1.0 - rig._carry
	if two_hand > 0.0:
		_close("_l", sk)
		_to_the_middle(sk)  # (the weapon leans so the left hand reaches)
	if has_tool:
		_hold(sk)
	if two_hand > 0.0:
		_second_hand(sk)


## Closes one hand's fingers into a fist.
func _close(side: String, sk: Skeleton3D) -> void:
	for j: Array in _joints[side]:
		sk.set_bone_pose_rotation(j[0], (j[1] as Quaternion) * Quaternion(j[2], deg_to_rad(j[3])))


## Turns the wrist so the fist's hole lies along the handle, then puts the tool in it.
func _hold(sk: Skeleton3D) -> void:
	var hand: int = _hands["_r"]
	var sk_world := sk.global_transform
	var socket: Node3D = rig.right_hand
	var hand_world := sk_world * sk.get_bone_global_pose(hand)
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()  # (things held keep their own size)
	# Where the old grip put the tool (the look the owner approved), plus the carry and the spear's aim.
	var want := hand_world * socket.transform * rig.grip_local
	want.basis = want.basis.orthonormalized()
	var extra := rig.hold_turn(want.basis)
	if two_hand > 0.0:
		extra = _tilt * extra  # (two-handed: the weapon leans over so the left hand reaches it: _to_the_middle)
	want.basis = Basis(extra) * want.basis
	var before := sk.get_bone_global_pose(hand).basis.get_rotation_quaternion()
	var inv := sk_world.basis.inverse()  # (directions in skeleton space: the dwarf is a bit wider than tall)
	var ax := Vector3.FORWARD if rig.tool_look == "spear" else Vector3.UP  # (the spear points along its holder's -Z)
	var handle_dir := want.basis * ax
	# The wrist's turn (skeleton space). The dwarf's stretched arm bones can't hold every turn exactly (a turned bone
	# under a squashed parent loses a little), so the fist's hole is lined up again until it lies along the handle.
	for i in 8:
		var turn: Quaternion
		if holding:
			_measure(sk)
			if fist_axis.angle_to(handle_dir) < deg_to_rad(0.5):
				break
			turn = Quaternion((inv * fist_axis).normalized(), (inv * handle_dir).normalized())
		else:  # (an open hand holding a stone or a mushroom: the wrist makes the carry's turn, once)
			if i > 0:
				break
			var q := sk_world.basis.get_rotation_quaternion()
			turn = q.inverse() * extra * q
		if turn.is_equal_approx(Quaternion.IDENTITY):
			break
		var g := sk.get_bone_global_pose(hand)
		g.basis = Basis(turn) * g.basis
		_set_turn(sk, hand, g)
	var g := sk.get_bone_global_pose(hand)
	var made := g.basis.get_rotation_quaternion() * before.inverse()
	if made.w < 0.0:
		made = -made  # (the short way round)
	wrist_turn = rad_to_deg(made.get_angle())
	var most := lerpf(WRIST_MAX, 180.0, rig._spear_aim)  # (the thrust: the spear points straight ahead, whatever it takes)
	most = lerpf(most, WRIST_MAX_TWO, two_hand)  # (two hands: the weapon's lean must stay, or the left hand can't reach)
	if wrist_turn > most:
		g.basis = Basis(Quaternion.IDENTITY.slerp(made, most / wrist_turn) * made.inverse()) * g.basis
		_set_turn(sk, hand, g)
		wrist_turn = most
	hand_world = sk_world * sk.get_bone_global_pose(hand)
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()
	var at := (hand_world * socket.transform * rig.grip_local).origin
	if holding:
		_measure(sk)
		# what the wrist couldn't do, the tool does: it tilts into the fist
		want.basis = Basis(Quaternion(handle_dir.normalized(), fist_axis)) * want.basis
		handle = _handle_of(rig.grip.get_child(rig.grip.get_child_count() - 1), ax)
		var off: Vector3 = handle[0]
		if rig.tool_look == "spear":  # (the spear is held a third of the way up its shaft: ToolModels)
			at = fist_center - want.basis * off
		else:  # the handle's end a small stub past the little finger
			at = fist_center - fist_axis * (fist_half + STUB) - want.basis * (off + ax * float(handle[1]))
	rig.grip.transform = (hand_world * socket.transform).affine_inverse() * Transform3D(want.basis, at)


## Two-handed: the animations hold the weapon out at his right side, where the short left arm can't reach across his
## round belly (measured: up to 78 cm short). First the weapon tilts about the right fist toward his left shoulder,
## only as far as the left hand needs (standing, the head leans over to his left, both hands low in front of him);
## only when that's not enough does the right fist come in too. (Pulling the right fist to the middle first buried
## both fists in his beard, the owner's page, Nov 19.)
const REACH := 0.92  ## the left fist's spot at most this share of the arm's reach from the shoulder
const FIST_PAST_WRIST := 0.08  ## m from the wrist to the middle of the fist (the reach counts to there)
const FRONT := 0.22  ## both fists stay at least this far in front of his chest bone (pulled straight in, they sank
                     ## into his round chest behind the beard: owner's page, Nov 19)
var _tilt := Quaternion.IDENTITY  ## the weapon's tilt this frame (world), used by _hold
func _to_the_middle(sk: Skeleton3D) -> void:
	var to_sk := sk.global_transform.affine_inverse()
	var sk_world := sk.global_transform
	var hand: int = _hands["_r"]
	var hand_world := sk_world * sk.get_bone_global_pose(hand)
	var want := hand_world * rig.right_hand.transform * rig.grip_local
	var handle_dir := (Basis(rig.hold_turn(want.basis.orthonormalized())) * want.basis.orthonormalized() * Vector3.UP).normalized()
	_measure(sk)
	var at := fist_center
	var shoulder := sk_world * sk.get_bone_global_pose(sk.find_bone("upperarm_l")).origin
	var elbow := sk_world * sk.get_bone_global_pose(sk.find_bone("lowerarm_l")).origin
	var wrist_l := sk_world * sk.get_bone_global_pose(_hands["_l"]).origin
	var reach := (shoulder.distance_to(elbow) + elbow.distance_to(wrist_l) + FIST_PAST_WRIST) * REACH
	var ahead := -rig.global_basis.z.normalized()
	var chest := sk_world * sk.get_bone_global_pose(sk.find_bone("spine_03")).origin
	var gap: float = TWO_HAND_GAPS[0]
	# the right fist comes in only if even the best tilt can't bring the left spot within reach
	var need := at.distance_to(shoulder) - (reach + gap * 0.3) + _push  # (the lean alone is rarely enough: the wrist only turns so far)
	var move := (shoulder - at).normalized() * maxf(need, 0.0)
	var front := (at + move - chest).dot(ahead)
	if front < FRONT:
		move += ahead * (FRONT - front)
	move *= two_hand
	if move.length() > 0.001:
		var keep := sk.get_bone_global_pose(hand)
		_reach(sk, sk.find_bone("upperarm_r"), sk.find_bone("lowerarm_r"), hand, to_sk * (hand_world.origin + move))
		_set_turn(sk, hand, keep)  # (the hand keeps its turn; only the arm moves)
		_measure(sk)
		at = fist_center
	# the tilt: the smallest turn of the handle (about the right fist) that brings the left spot within reach
	var toward := (shoulder - at).normalized()
	var dir := handle_dir
	for k in 21:
		dir = handle_dir.lerp(toward, k / 20.0).normalized()
		var spot := at + dir * gap
		if spot.distance_to(shoulder) <= reach and (spot - chest).dot(ahead) >= FRONT - 0.04:
			break
	_tilt = Quaternion.IDENTITY.slerp(Quaternion(handle_dir, dir), two_hand)


## The left hand on the handle, higher up than the right (TWO_HAND_GAPS): the left fist's hole turned along the
## handle (thumbs toward the head, like the right), then the arm reaches it. Skeleton space throughout.
func _second_hand(sk: Skeleton3D) -> void:
	var to_sk := sk.global_transform.affine_inverse()
	var up_b := sk.find_bone("upperarm_l")
	var low_b := sk.find_bone("lowerarm_l")
	var hand_b: int = _hands["_l"]
	var anim := [sk.get_bone_pose_rotation(up_b), sk.get_bone_pose_rotation(low_b), sk.get_bone_pose_rotation(hand_b)]
	var axis := (to_sk.basis * fist_axis).normalized()  # the handle, toward the head
	for gap: float in TWO_HAND_GAPS:
		left_gap = gap
		var target := to_sk * (fist_center + fist_axis * gap)  # the middle of the left fist goes here
		for i in 3:
			# 1. the left fist's hole along the handle (the smallest turn of the hand)
			_measure(sk, "_l")
			var g := sk.get_bone_global_pose(hand_b)
			g.basis = Basis(Quaternion((to_sk.basis * left_axis).normalized(), axis)) * g.basis
			_set_turn(sk, hand_b, g)
			var hand_basis := sk.get_bone_global_pose(hand_b).basis
			_measure(sk, "_l")
			var wrist_at := target - ((to_sk * left_center) - sk.get_bone_global_pose(hand_b).origin)
			# 2. the arm reaches: shoulder and elbow (the elbow stays on the side the animation bent it)
			_reach(sk, up_b, low_b, hand_b, wrist_at)
			g = sk.get_bone_global_pose(hand_b)
			g.basis = hand_basis
			_set_turn(sk, hand_b, g)
		_measure(sk, "_l")
		if (to_sk * left_center).distance_to(target) < 0.01 or gap == TWO_HAND_GAPS[-1]:
			break
		for k in 3:  # (too far: start again from the animation's arm, a little nearer the right hand)
			sk.set_bone_pose_rotation([up_b, low_b, hand_b][k], anim[k])
	left_miss = (to_sk * left_center).distance_to(to_sk * (fist_center + fist_axis * left_gap))
	_push = clampf(_push + (0.03 if left_miss > 0.012 else -0.004), 0.0, 0.35)
	if left_miss > 0.003 and two_hand >= 1.0:
		# the last bit (the fastest moments of a swing): the handle tilts about the right fist through the left one
		var through := (left_center - fist_center).normalized()
		if through.dot(fist_axis) > 0.5:  # (at most 60 degrees: more and the handle slips out of the right fist)
			var hand_r := sk.global_transform * sk.get_bone_global_pose(_hands["_r"]) * rig.right_hand.transform
			var tool := hand_r * rig.grip.transform
			var q := Basis(Quaternion(fist_axis, through))
			tool = Transform3D(q * tool.basis, fist_center + q * (tool.origin - fist_center))
			rig.grip.transform = hand_r.affine_inverse() * tool
			fist_axis = through
			left_miss = 0.0
	if two_hand < 1.0:  # fading in or out (starting or stopping a run)
		for k in 3:
			var bone: int = [up_b, low_b, hand_b][k]
			sk.set_bone_pose_rotation(bone, (anim[k] as Quaternion).slerp(sk.get_bone_pose_rotation(bone), two_hand))
	_measure(sk, "_l")


## Gives a bone the turn of `pose` (skeleton space), keeping its own size (DwarfProportions). Setting the whole pose
## (set_bone_global_pose) also rewrote the size from the squashed bones above it, and it grew a little every frame
## (the left hand reached millions, Nov 19).
static func _set_turn(sk: Skeleton3D, bone: int, pose: Transform3D) -> void:
	var parent := sk.get_bone_parent(bone)
	var above := sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis()
	sk.set_bone_pose_rotation(bone, (above.inverse() * pose.basis).get_rotation_quaternion())


## Two-bone reach: turns the upper arm and the forearm so the wrist (hand bone) lands on `at` (skeleton space).
static func _reach(sk: Skeleton3D, up_b: int, low_b: int, hand_b: int, at: Vector3) -> void:
	for i in 2:  # (the squashed dwarf bones lose a little of each turn: twice)
		var A := sk.get_bone_global_pose(up_b).origin
		var B := sk.get_bone_global_pose(low_b).origin
		var C := sk.get_bone_global_pose(hand_b).origin
		var a := (B - A).length()
		var b := (C - B).length()
		var to := at - A
		var d := clampf(to.length(), absf(a - b) + 0.001, a + b - 0.001)
		var dir := to.normalized()
		var bend := (B - A) - (B - A).dot(dir) * dir  # (where the elbow points now)
		if bend.length() < 1e-4:
			bend = (C - A).cross(Vector3.UP).cross(dir)
		bend = bend.normalized()
		var cos_a := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
		var elbow := A + a * (dir * cos_a + bend * sqrt(1.0 - cos_a * cos_a))
		var g := sk.get_bone_global_pose(up_b)
		g.basis = Basis(Quaternion((B - A).normalized(), (elbow - A).normalized())) * g.basis
		_set_turn(sk, up_b, g)
		B = sk.get_bone_global_pose(low_b).origin
		C = sk.get_bone_global_pose(hand_b).origin
		g = sk.get_bone_global_pose(low_b)
		g.basis = Basis(Quaternion((C - B).normalized(), (A + dir * d - B).normalized())) * g.basis
		_set_turn(sk, low_b, g)


## Not blocking, the shield hangs upright at his side (owner, Nov 19: "tilt the shield more", a picture with the line
## straight up and down): the shield lies along the forearm, and the animation's forearm slants in over his round
## belly, so the forearm hangs straight down from the elbow instead, a little out from his side.
const SHIELD_HANG_OUT := 10.0  ## degrees out from straight down
var _hang := 0.0  ## 0 = the animation's arm (blocking, bashing), 1 = hanging straight


## Puts the shield on: the left fist round its grip, its strap along the forearm, its face away from his body.
func _wear_shield(sk: Skeleton3D) -> void:
	var blocking: bool = rig._hold != "" or bool(rig.tree.get("parameters/upper/active"))
	_hang = move_toward(_hang, 0.0 if blocking else 1.0, get_process_delta_time() * 6.0) if rig.is_inside_tree() else _hang
	if _hang > 0.0:
		var sk_world := sk.global_transform
		var up_b := sk.find_bone("upperarm_l")
		var low_b := sk.find_bone("lowerarm_l")
		var hand_b: int = _hands["_l"]
		var elbow := sk_world * sk.get_bone_global_pose(low_b).origin
		var wrist := sk_world * sk.get_bone_global_pose(hand_b).origin
		var out := -rig.global_basis.x.normalized()  # (his left: he faces -Z)
		var down := (-rig.global_basis.y.normalized()).rotated(rig.global_basis.z.normalized(), deg_to_rad(SHIELD_HANG_OUT))
		if down.dot(out) < 0.0:
			down = (-rig.global_basis.y.normalized()).rotated(rig.global_basis.z.normalized(), -deg_to_rad(SHIELD_HANG_OUT))
		var hang_at := elbow + down * elbow.distance_to(wrist)
		_reach(sk, up_b, low_b, hand_b, sk_world.affine_inverse() * wrist.lerp(hang_at, _hang))
	var shield := rig.shield_grip.get_child(rig.shield_grip.get_child_count() - 1) as Node3D
	var model := shield.get_child(0) as Node3D if shield.get_child_count() > 0 else null
	if model == null:
		return
	var sk_world := sk.global_transform
	_measure(sk, "_l")
	var wrist := sk_world * sk.get_bone_global_pose(_hands["_l"]).origin
	var elbow := sk_world * sk.get_bone_global_pose(sk.get_bone_parent(_hands["_l"])).origin
	# the shield's own directions (in its holder's space): along the grip, grip -> strap, and its face
	var m := shield.transform * model.transform
	var g := m * SHIELD_GRIP
	var u := (m.basis * SHIELD_GRIP_DIR).normalized()
	var v := (m * SHIELD_STRAP - g)
	v = (v - v.dot(u) * u).normalized()
	var own := Basis(u, v, u.cross(v))
	var face := (m.basis * SHIELD_FACE).normalized()
	var chest := sk_world * sk.get_bone_global_pose(sk.find_bone("spine_03")).origin
	var best: Transform3D
	var best_out := -INF
	for flip: float in [1.0, -1.0]:  # (the grip fits the fist both ways round: the one with the face out is right)
		var U: Vector3 = left_axis * flip
		var V := elbow - wrist
		V = (V - V.dot(U) * U).normalized()
		var b := Basis(U, V, U.cross(V)) * own.inverse()
		var out := (b * face).dot((left_center - chest).normalized())
		if out > best_out:
			best_out = out
			best = Transform3D(b, left_center - b * g)
	# the fist slides along the grip (its wrap is 16 cm) until the loops sit on the forearm
	var mid := Vector3.ZERO
	for l: Vector3 in SHIELD_LOOPS:
		mid += best * (m * l)
	mid /= SHIELD_LOOPS.size()
	var fore := (elbow - wrist).normalized()
	var on_arm := wrist + fore * (mid - wrist).dot(fore)
	var grip_dir := (best.basis * u).normalized()
	best.origin += grip_dir * clampf((on_arm - mid).dot(grip_dir), -GRIP_SLIDE_MAX, GRIP_SLIDE_MAX)
	var hand_world := sk_world * sk.get_bone_global_pose(_hands["_l"])
	var socket: Node3D = rig.left_hand
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()
	rig.shield_grip.transform = (hand_world * socket.transform).affine_inverse() * best * shield.transform.affine_inverse()


## Measures a tool's handle from its model (cached per tool): its middle line (the points 3-12 cm from its end) and
## its end, along the holder's axis `ax`.
func _handle_of(tool: Node, ax: Vector3) -> Array:
	var id := tool.get_instance_id()
	if _handles.has(id):
		return _handles[id]
	var pts: Array[Vector3] = []
	for mi: MeshInstance3D in tool.find_children("*", "MeshInstance3D", true, false):
		var x := Transform3D()  # (the mesh's place in the tool, from the nodes in between)
		var n: Node = mi
		while n != tool and n is Node3D:
			x = (n as Node3D).transform * x
			n = n.get_parent()
		x = (tool as Node3D).transform * x
		if mi.mesh:
			for sf in mi.mesh.get_surface_count():
				for v: Vector3 in mi.mesh.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX]:
					pts.append(x * v)
	var found := [Vector3.ZERO, 0.0]
	if not pts.is_empty():
		var lo := INF
		var hi := -INF
		for p in pts:
			lo = minf(lo, p.dot(ax))
			hi = maxf(hi, p.dot(ax))
		var from := lo if ax == Vector3.UP else (lo + hi) / 2.0 - 0.1  # (the spear: round its middle, where he holds it)
		var mid := Vector3.ZERO
		var k := 0
		for p in pts:
			var along := p.dot(ax)
			if along > from + 0.03 and along < from + 0.12:
				mid += p - ax * along
				k += 1
		found = [mid / maxf(k, 1), lo]
	_handles[id] = found
	return found


## The way it was before the fists (for the page's "Before"): the carry and the spear's aim turned the tool holder
## about the wrist, and the fingers stayed as the animation had them.
func _old_hold(sk: Skeleton3D) -> void:
	var socket: Node3D = rig.right_hand
	var hand_world := sk.global_transform * sk.get_bone_global_pose(_hands["_r"])
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()
	var s_world := hand_world * socket.transform
	var was := s_world * rig.grip_local
	was.basis = was.basis.orthonormalized()
	var turn := Basis(rig.hold_turn(was.basis))
	var now := Transform3D(turn * was.basis, s_world.origin + turn * (was.origin - s_world.origin))
	rig.grip.transform = s_world.affine_inverse() * now


## Measures the hole through the right fist (world space): the finger joints ring the handle. (side "_l": the left
## fist, into left_center / left_axis.)
func _measure(sk: Skeleton3D, side := "_r") -> void:
	if side == "_l":
		var keep := [fist_center, fist_axis, fist_radius, fist_half]
		_measure_side(sk, "_l")
		left_center = fist_center
		left_axis = fist_axis
		fist_center = keep[0]; fist_axis = keep[1]; fist_radius = keep[2]; fist_half = keep[3]
		return
	_measure_side(sk, side)


func _measure_side(sk: Skeleton3D, side: String) -> void:
	var sk_world := sk.global_transform
	var pts: Array[Vector3] = []
	for b: int in _ring[side]:
		pts.append(sk_world * sk.get_bone_global_pose(b).origin)
	var kn: Array = _knuckles[side]
	var index := sk_world * sk.get_bone_global_pose(kn[0]).origin
	var pinky := sk_world * sk.get_bone_global_pose(kn[1]).origin
	fist_axis = (index - pinky).normalized()
	fist_half = (index - pinky).length() / 2.0 + FINGER_HALF
	# A circle through the ring of joints, seen along the axis (least squares).
	var u := fist_axis.cross(Vector3.UP if absf(fist_axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := fist_axis.cross(u)
	var mid := (index + pinky) / 2.0
	var sxx := 0.0; var sxy := 0.0; var syy := 0.0; var sx := 0.0; var sy := 0.0
	var sxz := 0.0; var syz := 0.0; var sz := 0.0
	var n := float(pts.size())
	for p in pts:
		var x := (p - mid).dot(u)
		var y := (p - mid).dot(v)
		var z := x * x + y * y
		sxx += x * x; sxy += x * y; syy += y * y; sx += x; sy += y
		sxz += x * z; syz += y * z; sz += z
	# x^2 + y^2 + a x + b y + c = 0
	var m := Basis(Vector3(sxx, sxy, sx), Vector3(sxy, syy, sy), Vector3(sx, sy, n))  # (columns; symmetric)
	if absf(m.determinant()) < 1e-12:
		fist_center = mid
		return
	var abc := m.inverse() * Vector3(-sxz, -syz, -sz)
	var cx := -abc.x / 2.0
	var cy := -abc.y / 2.0
	fist_center = mid + u * cx + v * cy
	fist_radius = sqrt(maxf(cx * cx + cy * cy - abc.z, 0.0))
