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
## Two-handed weapons (owner, Nov 19: "the great axe and great maul are two-handed"; F389 round 5, from a photo of a
## warrior with a long axe): the LEFT fist at the very end of the handle, the RIGHT fist high up it, wide apart. Where
## the fists go comes from hand-made key poses (DwarfGreatSwing); both arms reach there (two-bone reach) and the
## handle runs through both fists.
const TWO_HANDED := ["axe_2h", "mace_2h"]
const ELBOW_OUT := Vector3(0.8, 0.5, 0.2)  ## where the great weapons' elbows point: out, down, back (shares)
const MIN_GAP := 0.07  ## m: the closest the fists come (the slam: the right hand slides down to the left)
var two_hand := 0.0  ## 1 = both hands on a great weapon this frame
var left_gap := 0.0  ## m between the fists' middles this frame
var left_miss := 0.0  ## how far the left fist ended from its key-pose spot this frame (m)
var right_miss := 0.0  ## the same for the right fist
var target_l := Vector3.ZERO  ## the fists' key-pose spots this frame (world; for the preview tool)
var target_r := Vector3.ZERO
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
		two_hand = 1.0
		_close("_l", sk)
		_great_hold(sk, _delta)
		return
	if has_tool:
		_hold(sk)


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


## Two-handed (DwarfGreatSwing): the chest twists and leans, both fists go to the key pose's spots (the right one
## slides down the handle where his short arm can't reach), then the handle is laid through both fists, its end a
## small stub past the left fist and the blade facing the way the swing goes.
const SPINE := {"spine_01": 0.5, "spine_02": 0.3, "spine_03": 0.2}  ## share of the twist and lean (from the waist up:
	## his round belly is bound mostly to the low spine bones, so an even share hardly showed)
const HEAD_KEEP := 0.6  ## share of the chest's twist the neck turns back (he keeps looking ahead)
func _great_hold(sk: Skeleton3D, delta: float) -> void:
	var p: Dictionary = rig.great_pose(delta)
	# the owner's own poses (Blender), where he has made them: _posed_hold
	if rig.great_fixed.is_empty() and use_posed and DwarfGreatSwing.has_posed(rig.great_move):
		_posed_hold(sk, delta)
		return
	_posed_now = {}
	var sk_world := sk.global_transform
	var to_sk := sk_world.affine_inverse()
	var rb := rig.global_basis.orthonormalized()
	var q := Quaternion(rb.y, deg_to_rad(-float(p.twist))) * Quaternion(rb.x, deg_to_rad(-float(p.lean)))
	# hips lead, knees bend, feet planted (standing only: walking, the legs are the animation's)
	_plant = move_toward(_plant, 1.0 if rig.move_speed < 0.3 else 0.0, delta * 4.0)
	var q_hip := _hips(sk, p, rb, _plant)
	var q_sk := _to_sk_turn(to_sk.basis, q * q_hip.inverse())  # (the spine turns the rest of the way)
	for bone_name: String in SPINE:  # (shared out over the spine bones, so he bends round, not at one joint)
		var b := sk.find_bone(bone_name)
		var g := sk.get_bone_global_pose(b)
		g.basis = Basis(Quaternion.IDENTITY.slerp(q_sk, float(SPINE[bone_name]))) * g.basis
		_set_turn(sk, b, g)
	var neck := sk.find_bone("neck_01")
	if neck >= 0:
		var g := sk.get_bone_global_pose(neck)
		g.basis = Basis(_to_sk_turn(to_sk.basis, Quaternion(rb.y, deg_to_rad(float(p.twist) * HEAD_KEEP)))) * g.basis
		_set_turn(sk, neck, g)
	var F := Basis(q) * rb  # the chest's frame (x his right, y up, z his back)
	var chest := sk_world * sk.get_bone_global_pose(sk.find_bone("spine_03")).origin
	var L: Vector3 = chest + _body(F, p.l)
	var D: Vector3 = _body(F, p.d).normalized()
	# the shoulders reach toward the fists (the collarbones turn, up to CLAVICLE_MAX): his arms are short
	for side in ["_l", "_r"]:
		var cb := sk.find_bone("clavicle" + side)
		if cb < 0:
			continue
		var c := sk_world * sk.get_bone_global_pose(cb).origin
		var sh := sk_world * sk.get_bone_global_pose(sk.find_bone("upperarm" + side)).origin
		var t: Vector3 = L if side == "_l" else L + D * float(p.gap)
		var turn := Quaternion((sh - c).normalized(), (t - c).normalized())
		var most := deg_to_rad(CLAVICLE_MAX)
		if turn.get_angle() > most:
			turn = Quaternion.IDENTITY.slerp(turn, most / turn.get_angle())
		var g := sk.get_bone_global_pose(cb)
		g.basis = Basis(_to_sk_turn(to_sk.basis, turn)) * g.basis
		_set_turn(sk, cb, g)
	# the hands turn first (the handle through each fist): then it's known where each wrist must go for its fist
	var arms := _arms(sk, D)
	var al: Array = arms["_l"]
	var wl: Vector3 = L - al[5]  # (the left wrist's spot)
	if wl.distance_to(al[3]) > float(al[4]):
		L = (al[3] as Vector3) + (wl - al[3]).normalized() * float(al[4]) + (al[5] as Vector3)
	# never through his body, at any moment of any swing (also one cut short by the next): see _keep_out
	var kept := _keep_out(sk, L, D, al, arms["_r"])
	if not (kept[1] as Vector3).is_equal_approx(D):  # (the handle tipped: the hands turn again to fit it)
		arms = _arms(sk, kept[1])
		al = arms["_l"]
	L = kept[0]
	D = kept[1]
	# the right fist: as high up the handle as the pose wants and his arm reaches
	var ar: Array = arms["_r"]
	var w: Vector3 = L - ar[5] - ar[3]
	var wd := w.dot(D)
	var disc := wd * wd - w.length_squared() + float(ar[4]) * float(ar[4])
	var s: float = (-wd + sqrt(disc)) if disc >= 0.0 else -wd
	s = clampf(minf(float(p.gap), s), MIN_GAP, maxf(float(p.gap), MIN_GAP))
	var R := L + D * s
	for side in ["_r", "_l"]:
		var arm: Array = arms[side]
		_fist_to(sk, side, arm[0], arm[1], arm[2], R if side == "_r" else L, D)
	_measure(sk)
	_measure(sk, "_l")
	var dir := D
	if fist_center.distance_to(left_center) > 0.04:
		dir = (fist_center - left_center).normalized()
		for side in ["_r", "_l"]:  # (the fists' holes along the handle as it really lies)
			_turn_fist(sk, side, (to_sk.basis * dir).normalized())
		_measure(sk)
		_measure(sk, "_l")
		dir = (fist_center - left_center).normalized()
	left_gap = fist_center.distance_to(left_center)
	left_miss = left_center.distance_to(L)
	right_miss = fist_center.distance_to(R)
	target_l = L
	target_r = R
	wrist_turn = 0.0
	# the weapon: handle along `dir` through both fists, the blade facing the swing's way
	_lay_weapon(sk, _body(F, p.edge), dir, fist_half + STUB, -F.z)


## The great weapon laid through both fists: the handle along `dir`, its end `back` below the left fist's middle,
## the blade facing `E` (as near as it can, square to the handle; `fallback` if E runs along the handle).
func _lay_weapon(sk: Skeleton3D, E: Vector3, dir: Vector3, back: float, fallback: Vector3) -> void:
	var sk_world := sk.global_transform
	var hand_world := sk_world * sk.get_bone_global_pose(_hands["_r"])
	var socket: Node3D = rig.right_hand
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()
	var tool: Node3D = rig.grip.get_child(rig.grip.get_child_count() - 1)
	handle = _handle_of(tool, Vector3.UP)
	var blade := _blade_of(tool)
	E = E - E.dot(dir) * dir
	if E.length() < 1e-3:
		E = fallback - fallback.dot(dir) * dir
	E = E.normalized()
	var lb := Basis(blade, Vector3.UP, blade.cross(Vector3.UP))
	var wb := Basis(E, dir, E.cross(dir))
	var B := wb * lb.inverse()
	var off: Vector3 = handle[0]
	var at := left_center - dir * back - B * (off + Vector3.UP * float(handle[1]))
	rig.grip.transform = (hand_world * socket.transform).affine_inverse() * Transform3D(B, at)
	if measure_clearance:
		_clearance(sk, left_center - dir * back, dir)


## ---- The owner's own poses (F389, Nov 20: he poses the dwarf by hand in Blender, tools/blender_poses/) ----
## Every bone he moved takes the turn he gave it (DwarfGreatSwing.posed_pose: his key poses on the swing's timing).
## Then, as a safety net: the hands turn so the handle runs through both fists, and the keep-out guard (_keep_out)
## slides the handle out of his body if it has to (both fists reach again). The axe's blade faces the way he set it.
## Walking, the legs and hips stay the walk's (like the old way).
const POSED_LEGS := ["pelvis", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]
static var use_posed := true  ## off = the old hand-made numbers (MOVES) for every swing (the tools' "before")
var _posed_now := {}
var _posed_from := {}
var _posed_swing := -2.0  ## which swing the pose started from (DwarfRig._great_started)
var _bone_ids := {}
func _posed_hold(sk: Skeleton3D, delta: float) -> void:
	var move: String = rig.great_move
	if move != "":
		if rig._great_started != _posed_swing:  # (a new swing: it starts from wherever he is now)
			_posed_swing = rig._great_started
			_posed_from = _posed_now if not _posed_now.is_empty() else DwarfGreatSwing.posed_ready()
		_posed_now = DwarfGreatSwing.posed_pose(move, rig.great_t, _posed_from)
	else:
		_posed_swing = -2.0
		var ready := DwarfGreatSwing.posed_ready()
		_posed_now = ready if _posed_now.is_empty() else \
			DwarfGreatSwing.blend_posed(_posed_now, ready, 1.0 - exp(-DwarfGreatSwing.RETURN * delta))
	var p := _posed_now
	_plant = move_toward(_plant, 1.0 if rig.move_speed < 0.3 else 0.0, delta * 4.0)
	feet_miss = 0.0
	for n: String in p.bones:
		if not _bone_ids.has(n):
			_bone_ids[n] = sk.find_bone(n)
		var b: int = _bone_ids[n]
		if b < 0:
			continue
		var q: Quaternion = p.bones[n]
		if n in POSED_LEGS:
			q = sk.get_bone_pose_rotation(b).slerp(q, _plant)
		sk.set_bone_pose_rotation(b, q)
	var pel := sk.find_bone("pelvis")
	if pel >= 0:
		sk.set_bone_pose_position(pel, sk.get_bone_pose_position(pel).lerp(p.pelvis, _plant))
	# the handle through both fists as he holds them (the hands turn about the wrists to fit it: twice, each turn
	# moves the fists' middles a little)
	_measure(sk)
	_measure(sk, "_l")
	var D := (fist_center - left_center).normalized()
	var arms := {}
	for i in 2:
		arms = _arms(sk, D)
		D = (fist_center - left_center).normalized()
	var L := left_center
	var R := fist_center
	var s := (R - L).dot(D)
	var kept := _keep_out(sk, L, D, arms["_l"], arms["_r"])
	if (kept[0] as Vector3).distance_to(L) > 0.002 or (kept[1] as Vector3).angle_to(D) > 0.01:
		L = kept[0]
		D = kept[1]
		R = L + D * s
		for side in ["_r", "_l"]:
			var arm: Array = arms[side]
			_fist_to(sk, side, arm[0], arm[1], arm[2], R if side == "_r" else L, D)
		_measure(sk)
		_measure(sk, "_l")
	var dir := (fist_center - left_center).normalized() if fist_center.distance_to(left_center) > 0.04 else D
	left_gap = fist_center.distance_to(left_center)
	left_miss = left_center.distance_to(L)
	right_miss = fist_center.distance_to(R)
	target_l = L
	target_r = R
	wrist_turn = 0.0
	var rb := rig.global_basis.orthonormalized()
	var blade := _blade_of(rig.grip.get_child(rig.grip.get_child_count() - 1))
	_lay_weapon(sk, rb * ((p.axe as Basis) * blade), dir, maxf(float(p.slide), fist_half), -rb.z)


## Each hand turned so the handle (along D) runs through its fist, then per arm: [upper arm, forearm, hand bones,
## shoulder (world), reach, fist middle - wrist].
func _arms(sk: Skeleton3D, D: Vector3) -> Dictionary:
	var sk_world := sk.global_transform
	var to_sk := sk_world.affine_inverse()
	var arms := {}
	for side in ["_l", "_r"]:
		var up_b := sk.find_bone("upperarm" + side)
		var low_b := sk.find_bone("lowerarm" + side)
		var hand_b: int = _hands[side]
		_turn_fist(sk, side, (to_sk.basis * D).normalized())
		_measure(sk, side)
		var sh := sk_world * sk.get_bone_global_pose(up_b).origin
		var el := sk_world * sk.get_bone_global_pose(low_b).origin
		var wr := sk_world * sk.get_bone_global_pose(hand_b).origin
		var c := left_center if side == "_l" else fist_center
		arms[side] = [up_b, low_b, hand_b, sh, (sh.distance_to(el) + el.distance_to(wr)) * 0.985, c - wr]
	return arms


## The handle keeps KEEP_OUT from his body at every moment (owner, F389: "never through his belly or beard"). Chat 8:
## tuning the key poses alone never managed it: the strike covers most of its arc in 2% of the swing and the handle
## brushed his belly in between, and a combo starts each swing from wherever the last one was. So: once, his skin
## (body, beard, kilt; not arms, hands or braids) is covered with small balls, one per KEEP_CELL patch, each riding
## on the bone that moves it (one egg per bone was tried first: far too fat, it shoved the axe round to his front).
## Every frame, where the handle comes too close to a ball, the left fist (and the handle with it) slides out, and
## where his arm can't reach that far, the handle tips away round the left fist.
const KEEP_OUT := 0.055  ## m (2 cm more than the rules ask: the balls sit a little inside the skin between their points,
	## and the hands start each frame from where they were)
const KEEP_CELL := 0.07  ## m, the patch each ball covers
const KEEP_SKIP := ["arm", "hand", "index", "middle", "ring", "pinky", "thumb", "clavicle", "hair", "foot", "ball", "calf"]
var _shapes: Array = []  ## [bone, middle (bone space), radius (m)]
var keep_push := 0.0  ## m the guard moved the left fist this frame (the tools)
func _fit_shapes(sk: Skeleton3D) -> void:
	var sk_world := sk.global_transform
	var cells := {}  # Vector3i -> [bone, sum of points (world), count, points]
	for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", false, false):
		if not mi.visible or mi.skin == null or mi.mesh == null:
			continue
		var skin := mi.skin
		var bind_bone := []
		var bind_x := []
		for i in skin.get_bind_count():
			var bi := sk.find_bone(skin.get_bind_name(i))
			bind_bone.append(bi)
			bind_x.append(sk_world * sk.get_bone_global_pose(maxi(bi, 0)) * skin.get_bind_pose(i))
		for sf in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(sf)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			if bones == null or weights == null or verts.is_empty():
				continue
			var per: int = (bones as PackedInt32Array).size() / verts.size()
			for vi in verts.size():
				var top := 0
				var p := Vector3.ZERO
				for k in per:
					var wgt: float = weights[vi * per + k]
					if wgt <= 0.0:
						continue
					p += ((bind_x[bones[vi * per + k]] as Transform3D) * verts[vi]) * wgt
					if wgt > float(weights[vi * per + top]):
						top = k
				var bi: int = bind_bone[bones[vi * per + top]]
				if bi < 0:
					continue
				var bname := sk.get_bone_name(bi)
				var skipped := false
				for word: String in KEEP_SKIP:
					if word in bname:
						skipped = true
						break
				if skipped:
					continue
				var key := Vector3i((p / KEEP_CELL).floor())
				key = Vector3i(key.x, key.y, key.z * 64 + bi % 64)  # (one ball per patch and bone)
				if not cells.has(key):
					cells[key] = [bi, Vector3.ZERO, 0, []]
				var c: Array = cells[key]
				c[1] = (c[1] as Vector3) + p
				c[2] = int(c[2]) + 1
				(c[3] as Array).append(p)
	_shapes.clear()
	for key: Vector3i in cells:
		var c: Array = cells[key]
		if int(c[2]) < 3:
			continue
		var mid: Vector3 = (c[1] as Vector3) / float(c[2])
		var r := 0.0
		for p: Vector3 in c[3]:
			r = maxf(r, p.distance_to(mid))
		var bone_world := sk_world * sk.get_bone_global_pose(c[0])
		_shapes.append([c[0], bone_world.affine_inverse() * mid, maxf(r, 0.01)])


## L, D moved so the handle (from its end, HANDLE_ROOM long) keeps KEEP_OUT from every ball. `arm` = the left arm
## ([.., .., .., shoulder, reach, fist - wrist]) so the fist never goes past his reach; `right` = the right arm, so the
## handle only tips as far as the right fist can still follow it (chat 8: it floated 13 cm off the handle).
func _keep_out(sk: Skeleton3D, L: Vector3, D: Vector3, arm: Array, right: Array) -> Array:
	if _shapes.is_empty():
		_fit_shapes(sk)
	var start := L
	var sk_world := sk.global_transform
	var bone_world := {}
	var balls: Array = []  # [middle (world), radius]
	for shape: Array in _shapes:
		if not bone_world.has(shape[0]):
			bone_world[shape[0]] = sk_world * sk.get_bone_global_pose(shape[0])
		balls.append([(bone_world[shape[0]] as Transform3D) * (shape[1] as Vector3), shape[2]])
	for _r in 8:
		var worst := Vector3.ZERO
		var worst_at := 0.0
		var a := L - D * (fist_half + STUB)
		for ball: Array in balls:
			var c: Vector3 = ball[0]
			var along := clampf((c - a).dot(D), 0.0, HANDLE_ROOM)
			var q := a + D * along
			var need: float = float(ball[1]) + KEEP_OUT - q.distance_to(c)
			if need <= 0.0:
				continue
			var out := (q - c).normalized() if q.distance_to(c) > 1e-3 else -rig.global_basis.z
			if need > worst.length():
				worst = out * (need + 0.005)
				worst_at = along - (fist_half + STUB)  # (how far up the handle from the left fist)
		if worst == Vector3.ZERO:
			break
		var sh: Vector3 = arm[3]
		var wrist: Vector3 = L + worst - (arm[5] as Vector3)
		if wrist.distance_to(sh) <= float(arm[4]) or worst_at < 0.08:
			L = sh + (wrist - sh).limit_length(float(arm[4])) + (arm[5] as Vector3)
			D = _within_reach(L, D, right)  # (the right fist must still reach the handle)
		else:  # (his arm can't reach that far: the handle tips away round the left fist instead)
			D = _within_reach(L, (D * worst_at + worst).normalized(), right)
	keep_push = L.distance_to(start)
	return [L, D]


## `D` turned (round L) just enough that the handle's line still passes within the right fist's reach.
static func _within_reach(L: Vector3, D: Vector3, right: Array) -> Vector3:
	var c: Vector3 = (right[3] as Vector3) + (right[5] as Vector3)  # (where the right fist can be: round this, reach far)
	var to := c - L
	if to.length() < 1e-3:
		return D
	var most := asin(clampf(float(right[4]) * 0.97 / to.length(), 0.0, 1.0))
	var ang := D.angle_to(to)
	if ang <= most:
		return D
	var ax := to.cross(D)
	if ax.length() < 1e-5:
		return D
	return to.normalized().rotated(ax.normalized(), most)


## "Hips lead, knees bend" (owner, F389; docs/art/ANIMATION-RULES.md 4): the hips turn and lean their share of the
## swing (DwarfGreatSwing.HIP_TWIST/HIP_LEAN, a little ahead of the chest), drop by `knee` and go forward by `fwd`
## (the lunge), and both legs bend so the feet stay where they stood, a little apart (FEET: the left foot forward).
## Returns the hips' turn (world) so the spine only turns the rest of the way. `k` 0..1 = how much (standing).
const FEET := {"_l": Vector3(-0.03, 0.0, 0.07), "_r": Vector3(0.03, 0.0, -0.05)}  ## m (x his right, z his front)
const KNEE_OUT := 0.35  ## the knees point forward and this share out to the sides
var _plant := 0.0
var feet_miss := 0.0  ## m, how far the feet ended from where they stood this frame (the test)
func _hips(sk: Skeleton3D, p: Dictionary, rb: Basis, k: float) -> Quaternion:
	var pel := sk.find_bone("pelvis")
	if pel < 0 or k <= 0.0:
		feet_miss = 0.0
		return Quaternion.IDENTITY
	var to_sk := sk.global_transform.affine_inverse()
	var hip_twist: float = p.get("hip", DwarfGreatSwing.HIP_TWIST * float(p.twist)) * k
	var hip_lean: float = p.get("hip_lean", DwarfGreatSwing.HIP_LEAN * float(p.lean)) * k
	var q_hip := Quaternion(rb.y, deg_to_rad(-hip_twist)) * Quaternion(rb.x, deg_to_rad(-hip_lean))
	# where each foot stands now (skeleton space), before the hips move
	var feet := {}
	for side in ["_l", "_r"]:
		var fb := sk.find_bone("foot" + side)
		var off: Vector3 = FEET[side]
		feet[side] = [fb, sk.get_bone_global_pose(fb), to_sk.basis * (rb * Vector3(off.x, off.y, -off.z) * k)]
	# the hips: down and forward, then turned
	var parent := sk.get_bone_parent(pel)
	var to_parent := sk.get_bone_global_pose(parent).basis.inverse() if parent >= 0 else Basis()
	var move: Vector3 = to_sk.basis * (-rb.y * float(p.get("knee", 0.0)) - rb.z * float(p.get("fwd", 0.0))) * k
	sk.set_bone_pose_position(pel, sk.get_bone_pose_position(pel) + to_parent * move)
	var g := sk.get_bone_global_pose(pel)
	g.basis = Basis(_to_sk_turn(to_sk.basis, q_hip)) * g.basis
	_set_turn(sk, pel, g)
	# the legs bend so each foot lands back where it stood, the foot turned as before (flat on the floor)
	feet_miss = 0.0
	for side in ["_l", "_r"]:
		var f: Array = feet[side]
		var out := rb.x if side == "_r" else -rb.x
		var pole := (to_sk.basis * (-rb.z + out * KNEE_OUT)).normalized()
		var at: Vector3 = (f[1] as Transform3D).origin + (f[2] as Vector3)
		for i in 2:  # (2 x 2 rounds: the squashed leg bones lose a little of each turn)
			_reach(sk, sk.find_bone("thigh" + side), sk.find_bone("calf" + side), f[0], at, pole)
		var fg := sk.get_bone_global_pose(f[0])
		fg.basis = (f[1] as Transform3D).basis
		_set_turn(sk, f[0], fg)
		feet_miss = maxf(feet_miss, (sk.global_transform.basis * (sk.get_bone_global_pose(f[0]).origin - at)).length())
	return q_hip


## The handle's room in front of his body (owner, F389: "never through his chest or beard"): how close the handle,
## from its end to where the head starts, comes to his skin, shirt and beard (his arms and hands don't count: they
## hold it). For the test and the preview tool (slow: it skins every point of the body by hand).
const CLAVICLE_MAX := 25.0  ## degrees the collarbones turn toward the fists
const HANDLE_ROOM := 0.75  ## m of handle checked from its end (past that the head sits beside his shoulder)
var measure_clearance := false
var clearance := 0.0  ## m, this frame (measure_clearance on)
var clear_part := ""  ## the body bone nearest the handle
var clear_along := 0.0  ## m along the handle from its end, where it comes nearest (the tools)
var clearance_hair := 0.0  ## the same for his hair and beard braids (they hang down his front)
func _clearance(sk: Skeleton3D, end: Vector3, dir: Vector3) -> void:
	clearance = INF
	clearance_hair = INF
	var skip := ["arm", "hand", "index", "middle", "ring", "pinky", "thumb", "clavicle"]
	var sk_world := sk.global_transform
	for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", false, false):
		if not mi.visible or mi.skin == null or mi.mesh == null:
			continue
		var skin := mi.skin
		var bind_bone := []
		var bind_x := []
		for i in skin.get_bind_count():
			var bi := sk.find_bone(skin.get_bind_name(i))
			bind_bone.append(bi)
			bind_x.append(sk.get_bone_global_pose(maxi(bi, 0)) * skin.get_bind_pose(i))
		for sf in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(sf)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			if bones == null or weights == null or verts.is_empty():
				continue
			var per: int = (bones as PackedInt32Array).size() / verts.size()
			for vi in range(0, verts.size(), 2):
				var top := 0
				var p := Vector3.ZERO
				for k in per:
					var wgt: float = weights[vi * per + k]
					if wgt <= 0.0:
						continue
					var bi: int = bones[vi * per + k]
					p += ((bind_x[bi] as Transform3D) * verts[vi]) * wgt
					if wgt > float(weights[vi * per + top]):
						top = k
				var main: int = bind_bone[bones[vi * per + top]]
				var bname := sk.get_bone_name(main) if main >= 0 else ""
				var skipped := false
				for word: String in skip:
					if word in bname:
						skipped = true
						break
				if skipped:
					continue
				var wp := sk_world * p
				var along := clampf((wp - end).dot(dir), 0.0, HANDLE_ROOM)
				var dist := wp.distance_to(end + dir * along)
				if bname.begins_with("hair"):
					clearance_hair = minf(clearance_hair, dist)
				elif dist < clearance:
					clearance = dist
					clear_part = bname
					clear_along = along


## A body point or direction (x his right, y up, z his front) in world space, by the chest's frame F.
static func _body(F: Basis, v: Vector3) -> Vector3:
	return F * Vector3(v.x, v.y, -v.z)


## A world turn as the same turn in skeleton space (the skeleton is a little wider than tall).
static func _to_sk_turn(to_sk: Basis, q: Quaternion) -> Quaternion:
	var ax := q.get_axis() if q.get_angle() > 1e-5 else Vector3.UP
	return Quaternion((to_sk * ax).normalized(), q.get_angle())


## One fist to `target` (world), its hole along `dir`: the hand turns, then the arm reaches (three rounds: each
## changes the other a little). The elbow stays on the side the animation bent it.
func _fist_to(sk: Skeleton3D, side: String, up_b: int, low_b: int, hand_b: int, target: Vector3, dir: Vector3) -> void:
	var to_sk := sk.global_transform.affine_inverse()
	# the elbow out to his side and down, a little back (owner, Nov 19: the arms were folded into his belly)
	var rb := rig.global_basis.orthonormalized()
	var out := rb.x if side == "_r" else -rb.x
	var pole := (to_sk.basis * (out * ELBOW_OUT.x - rb.y * ELBOW_OUT.y + rb.z * ELBOW_OUT.z)).normalized()
	var dir_sk := (to_sk.basis * dir).normalized()
	var t_sk := to_sk * target
	for i in 8:
		_turn_fist(sk, side, dir_sk)
		var hand_basis := sk.get_bone_global_pose(hand_b).basis
		_measure(sk, side)
		var c := left_center if side == "_l" else fist_center
		var wrist_at := t_sk - ((to_sk * c) - sk.get_bone_global_pose(hand_b).origin)
		_reach(sk, up_b, low_b, hand_b, wrist_at, pole)
		var g := sk.get_bone_global_pose(hand_b)
		g.basis = hand_basis
		_set_turn(sk, hand_b, g)


## Turns one hand so the hole through its fist points along `dir_sk` (skeleton space).
func _turn_fist(sk: Skeleton3D, side: String, dir_sk: Vector3) -> void:
	var to_sk := sk.global_transform.affine_inverse()
	_measure(sk, side)
	var a := left_axis if side == "_l" else fist_axis
	var hand_b: int = _hands[side]
	var g := sk.get_bone_global_pose(hand_b)
	g.basis = Basis(Quaternion((to_sk.basis * a).normalized(), dir_sk)) * g.basis
	_set_turn(sk, hand_b, g)


## Which way the blade sticks out from the handle (tool holder space, square to the handle; cached per tool): the
## model's points in the top quarter of the handle's length, away from the handle's middle line. A maul's head
## sticks out both ways evenly: then any side does.
var _blades := {}
func _blade_of(tool: Node3D) -> Vector3:
	var id := tool.get_instance_id()
	if _blades.has(id):
		return _blades[id]
	var off: Vector3 = _handle_of(tool, Vector3.UP)[0]
	var pts: Array[Vector3] = []
	var lo := INF
	var hi := -INF
	for mi: MeshInstance3D in tool.find_children("*", "MeshInstance3D", true, false):
		var x := Transform3D()
		var n: Node = mi
		while n != tool and n is Node3D:
			x = (n as Node3D).transform * x
			n = n.get_parent()
		x = tool.transform * x
		if mi.mesh:
			for sf in mi.mesh.get_surface_count():
				for v: Vector3 in mi.mesh.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX]:
					var pt := x * v
					pts.append(pt)
					lo = minf(lo, pt.y)
					hi = maxf(hi, pt.y)
	var sum := Vector3.ZERO
	for pt in pts:
		if pt.y > hi - (hi - lo) * 0.25:
			var out := Vector3(pt.x - off.x, 0, pt.z - off.z)
			sum += out * out.length()  # (the far points count most: the blade's edge)
	var found := sum.normalized() if sum.length() > 1e-4 else Vector3.RIGHT
	_blades[id] = found
	return found


## Gives a bone the turn of `pose` (skeleton space), keeping its own size (DwarfProportions). Setting the whole pose
## (set_bone_global_pose) also rewrote the size from the squashed bones above it, and it grew a little every frame
## (the left hand reached millions, Nov 19).
static func _set_turn(sk: Skeleton3D, bone: int, pose: Transform3D) -> void:
	var parent := sk.get_bone_parent(bone)
	var above := sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis()
	sk.set_bone_pose_rotation(bone, (above.inverse() * pose.basis).get_rotation_quaternion())


## Two-bone reach: turns the upper arm and the forearm so the wrist (hand bone) lands on `at` (skeleton space).
static func _reach(sk: Skeleton3D, up_b: int, low_b: int, hand_b: int, at: Vector3, pole := Vector3.ZERO) -> void:
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
		if pole != Vector3.ZERO:  # (or where it's told to point: the great weapons' elbows out to the sides)
			bend = pole - pole.dot(dir) * dir
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
