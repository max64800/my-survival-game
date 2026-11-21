extends SceneTree
## Bakes the crossbow aim, shoot and reload by placing the bow first and then solving both arms onto it
## (owner, chat 18: the KayKit stance had the bow pointing sideways and the left hand never reached it; the dwarf's arms
## are SHORT (about 26 cm both bones together), so the poses are made for HIS reach, measured from the live rig).
## Each key = where the right wrist is (from the right shoulder), where the bow points, and where on the bow the left
## hand holds it. Between keys: smooth steps.
## Out: assets/anim/crossbow_kaykit.res ("c/" library: Aim, Shoot, Reload), same names as before so the game needs no change.
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/crossbow_ik_bake.gd -- claude=crossbow_bake
## By the dwarf-animations Claude, chat 18, Nov 21, 2026.
const OUT := "res://assets/anim/crossbow_kaykit.res"
const FPS := 30.0
const UPPER := ["spine_01", "spine_02", "spine_03", "neck_01", "Head", "clavicle_l", "clavicle_r",
	"upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r"]
const CHAIN := ["spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r", "upperarm_l", "upperarm_r"]
## Spots on the bow, in the bow's own space (-Z = pointing, +Y = up; stock back near z 0.1, limbs near z -0.62).
const FORE := Vector3(0, -0.04, -0.12)
const GROOVE := Vector3(0, 0.10, -0.11)
const STRING := Vector3(0, 0.07, -0.18)
const LATCH := Vector3(0, 0.07, -0.09)
const LEFT_ROLL := 160.0  ## degrees the left hand turns about its forearm (palm up under the bow)
const PITCH_FIX := 25.0  ## degrees: the measured bow sat this much too high in the picture (the hand and tool scales are not even)
const PALM := 0.07        ## from the left wrist to the middle of the palm (skeleton units)
## Right wrist spot, from the right shoulder: [sideways (+ = toward the middle), up, ahead].
const AIM_W := Vector3(0.19, 0.02, 0.15)
const AIM_F := Vector3(0.03, 0.04, 1.0)
const LOW_W := Vector3(0.16, -0.05, 0.17)
const LOW_F := Vector3(0.0, -0.30, 0.95)
## Reload (owner, chat 18): the bow points to HIS LEFT (+X), left hand takes a bolt from the belt and sets it at the bow's end.
const SIDE_W := Vector3(0.13, -0.04, 0.15)
const SIDE_F := Vector3(1.0, -0.12, 0.22)
const SIDE_HOLD := Vector3(0, -0.04, -0.22)  ## (bow space) left hand under the fore-end
const FRONT := Vector3(0.0, -0.08, 0.25)    ## (from the left shoulder) out in front of the belly, so the hand never cuts through it
const BOLT_END := Vector3(0, 0.10, -0.30)    ## (bow space) the groove near the bow's end
const BELT := Vector3(-0.02, -0.17, 0.20)    ## (from the left shoulder, skeleton space) the bolt pouch at the belt
var _sk: Skeleton3D
var _g := {}              ## bone -> rest global transform (T pose)
var _shoulder := {}       ## "l"/"r" -> the shoulder joint in skeleton space, chest at rest
var _l1 := {}
var _l2 := {}
var _r_hb: Basis          ## the right hand's turn -> the bow's
var _o_hb: Vector3        ## wrist -> bow origin, in the hand's own space
var _tool_scale: Vector3  ## bow metres -> skeleton units
var _clips := {
	"Aim": {"len": 1.0, "loop": true, "keys": [[0.0, AIM_W, AIM_F, FORE], [1.0, AIM_W, AIM_F, FORE]]},
	"Shoot": {"len": 0.4, "loop": false, "keys": [[0.0, AIM_W, AIM_F, FORE],
		[0.17, AIM_W + Vector3(0, 0.02, -0.03), Vector3(0.03, 0.22, 1.0), FORE],
		[1.0, AIM_W, AIM_F, FORE]]},
	"Reload": {"len": 2.6, "loop": false, "keys": [
		[0.00, AIM_W, AIM_F, FORE],
		[0.14, SIDE_W, SIDE_F, SIDE_HOLD],
		[0.26, SIDE_W, SIDE_F, SIDE_HOLD],
		[0.36, SIDE_W, SIDE_F, SIDE_HOLD, BELT, 1.0],
		[0.46, SIDE_W, SIDE_F, SIDE_HOLD, BELT, 1.0],
		[0.55, SIDE_W, SIDE_F, SIDE_HOLD, FRONT, 1.0],
		[0.64, SIDE_W, SIDE_F, BOLT_END],
		[0.78, SIDE_W, SIDE_F, BOLT_END],
		[0.88, SIDE_W, SIDE_F, SIDE_HOLD],
		[1.00, AIM_W, AIM_F, FORE]]},
}


func _init() -> void:
	var model := DwarfModel.new()
	root.add_child(model)
	await process_frame
	var rig := model.dwarf_rig
	_sk = rig.skeleton
	model.set_held("crossbow_copper")
	for i in 30:
		await process_frame
	var prefix := str(rig.tree.get_animation(DwarfRig.ANIMS.idle).track_get_path(0)).get_slice(":", 0)
	for i in _sk.get_bone_count():
		_g[_sk.get_bone_name(i)] = _sk.get_bone_global_rest(i)
	_measure(rig)
	var lib := AnimationLibrary.new()
	for clip: String in _clips:
		var c: Dictionary = _clips[clip]
		var anim := Animation.new()
		anim.length = c.len
		anim.loop_mode = Animation.LOOP_LINEAR if c.loop else Animation.LOOP_NONE
		var tracks := {}
		for b: String in UPPER:
			var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(tr, NodePath("%s:%s" % [prefix, b]))
			tracks[b] = tr
		var n := int(round(c.len * FPS))
		var worst := 0.0
		for f in n + 1:
			var t := minf(f / FPS, c.len)
			var pose := _pose(c.keys, t / c.len)
			var loc := _local_rotations(pose)
			worst = maxf(worst, pose.miss)
			for b: String in UPPER:
				anim.rotation_track_insert_key(tracks[b], t, loc[b])
		lib.add_animation(clip, anim)
		print("BAKED %s %d frames, %.2f s, left hand worst miss %.1f cm" % [clip, n + 1, c.len, worst * 100.0])
	print("SAVED ", OUT, " ", ResourceSaver.save(lib, OUT))
	quit()


## Reads the live dwarf (the proportions script has shortened the arms): shoulders with the chest at rest, the two arm
## bones' lengths, and where the held bow sits in the right hand.
func _measure(rig: DwarfRig) -> void:
	# the chest at rest: walk from the live pelvis up through the bones' own positions
	var pel := _sk.find_bone("pelvis")
	var live_pel := _sk.get_bone_global_pose(pel)
	var tf := {"pelvis": Transform3D((_g["pelvis"] as Transform3D).basis.orthonormalized(), live_pel.origin)}
	for b: String in CHAIN:
		var i := _sk.find_bone(b)
		var p := _sk.get_bone_name(_sk.get_bone_parent(i))
		var par: Transform3D = tf[p]
		var local := Transform3D(_sk.get_bone_rest(i).basis.orthonormalized().scaled(_sk.get_bone_pose_scale(i)),
			_sk.get_bone_pose_position(i))
		tf[b] = par * local
	_shoulder["l"] = (tf["upperarm_l"] as Transform3D).origin
	_shoulder["r"] = (tf["upperarm_r"] as Transform3D).origin
	for s in ["l", "r"]:
		var u := _sk.get_bone_global_pose(_sk.find_bone("upperarm_" + s)).origin
		var e := _sk.get_bone_global_pose(_sk.find_bone("lowerarm_" + s)).origin
		var h := _sk.get_bone_global_pose(_sk.find_bone("hand_" + s)).origin
		_l1[s] = (e - u).length()
		_l2[s] = (h - e).length()
	# the bow in the right hand (c/Aim grip)
	rig.grip.transform = DwarfRig.grip_transform("crossbow", "c/Aim")
	var hg: Transform3D = _sk.get_bone_global_pose(_sk.find_bone("hand_r"))
	# (worked out from the transforms, not read from the tool: a headless run does not move the tool's attachment)
	var gt: Transform3D = hg * rig.right_hand.transform * rig.grip.transform
	var hn := hg.basis.orthonormalized()
	_r_hb = hn.inverse() * gt.basis.orthonormalized()
	_o_hb = hn.inverse() * (gt.origin - hg.origin)
	_tool_scale = gt.basis.get_scale()
	print("MEASURED shoulders ", _shoulder, " arm bones r ", _l1["r"], " ", _l2["r"], " l ", _l1["l"], " ", _l2["l"])
	print("MEASURED wrist->bow ", _o_hb, " bow scale ", _tool_scale)


## The right wrist, bow pointing and left spot at time share t (keys: [share, wrist, forward, left spot]).
func _pose(keys: Array, t: float) -> Dictionary:
	var a: Array = keys[0]
	var b: Array = keys[keys.size() - 1]
	for i in keys.size() - 1:
		if t >= keys[i][0] and t <= keys[i + 1][0]:
			a = keys[i]
			b = keys[i + 1]
			break
	var span := maxf(b[0] - a[0], 0.0001)
	var k := smoothstep(0.0, 1.0, clampf((t - a[0]) / span, 0.0, 1.0))
	return {w = (a[1] as Vector3).lerp(b[1], k),
		f = (a[2] as Vector3).normalized().slerp((b[2] as Vector3).normalized(), k),
		l = (a[3] as Vector3).lerp(b[3], k), miss = 0.0,
		la = _abs_of(a).lerp(_abs_of(b), k), m = lerpf(_mix_of(a), _mix_of(b), k)}


## A key's left-hand spot from the LEFT SHOULDER in skeleton space (optional 5th/6th entries: spot, 1 = use it).
func _abs_of(key: Array) -> Vector3:
	return key[4] as Vector3 if key.size() > 4 else Vector3.ZERO


func _mix_of(key: Array) -> float:
	return float(key[5]) if key.size() > 5 else 0.0


func _local_rotations(pose: Dictionary) -> Dictionary:
	var out := {}
	var zb: Vector3 = -(pose.f as Vector3)
	var xb := Vector3.UP.cross(zb).normalized()
	var bow := Basis(xb, zb.cross(xb), zb)
	var hand_rot := Basis(Vector3.RIGHT, deg_to_rad(PITCH_FIX)) * bow * _r_hb.inverse()
	var w: Vector3 = pose.w
	var wrist_r: Vector3 = (_shoulder["r"] as Vector3) + w
	var bow_o := wrist_r + hand_rot * _o_hb
	var r := _arm("r", wrist_r)
	var left_spot := bow_o + bow * ((pose.l as Vector3) * _tool_scale)
	left_spot = left_spot.lerp((_shoulder["l"] as Vector3) + (pose.la as Vector3), pose.m)
	var guess: Vector3 = (left_spot - (_shoulder["l"] as Vector3)).normalized()
	var wrist_l := left_spot - guess * PALM
	var l := _arm("l", wrist_l)
	pose.miss = ((l.wrist as Vector3) + guess * PALM - left_spot).length()
	var roll := Quaternion(l.low_dir, deg_to_rad(-LEFT_ROLL))
	var hand_l_rest: Quaternion = (_g["hand_l"] as Transform3D).basis.get_rotation_quaternion()
	var low_rest: Quaternion = (_g["lowerarm_l"] as Transform3D).basis.get_rotation_quaternion()
	var hand_l_q: Quaternion = (roll * (l.low_q as Quaternion) * low_rest.inverse() * hand_l_rest).normalized()
	var glob := {"upperarm_r": r.up_q, "lowerarm_r": r.low_q, "hand_r": hand_rot.get_rotation_quaternion(),
		"upperarm_l": l.up_q, "lowerarm_l": l.low_q, "hand_l": hand_l_q}
	for b: String in UPPER:
		var pname := _sk.get_bone_name(_sk.get_bone_parent(_sk.find_bone(b)))
		var pq: Quaternion = glob[pname] if glob.has(pname) else (_g[pname] as Transform3D).basis.get_rotation_quaternion()
		var own: Quaternion = glob[b] if glob.has(b) else (_g[b] as Transform3D).basis.get_rotation_quaternion()
		out[b] = (pq.inverse() * own).normalized()
	return out


## Two-bone solve of an arm ("r"/"l") to a wrist spot, from the measured shoulder and bone lengths.
func _arm(side: String, target: Vector3) -> Dictionary:
	var s: Vector3 = _shoulder[side]
	var e0: Vector3 = (_g["lowerarm_" + side] as Transform3D).origin
	var w0: Vector3 = (_g["hand_" + side] as Transform3D).origin
	var u0: Vector3 = (_g["upperarm_" + side] as Transform3D).origin
	var l1: float = _l1[side]
	var l2: float = _l2[side]
	var d := target - s
	var dist := clampf(d.length(), 0.05, (l1 + l2) * 0.995)
	var dir := d.normalized()
	var a := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var out_dir := -1.0 if side == "r" else 1.0
	var pole := Vector3(out_dir * 0.4, -1.0, -0.6)
	var pn := (pole - dir * pole.dot(dir)).normalized()
	var e := s + dir * a + pn * h
	var wr := s + dir * dist
	var n_rest := Vector3.UP if side == "r" else Vector3.DOWN
	var n_new := dir.cross(-pn).normalized()
	var a1_r := (e0 - u0).normalized()
	var a1_n := (e - s).normalized()
	var a2_r := (w0 - e0).normalized()
	var a2_n := (wr - e).normalized()
	var up_rest: Quaternion = (_g["upperarm_" + side] as Transform3D).basis.get_rotation_quaternion()
	var low_rest: Quaternion = (_g["lowerarm_" + side] as Transform3D).basis.get_rotation_quaternion()
	var up_q := _frame(a1_n, n_new) * _frame(a1_r, n_rest).inverse() * up_rest
	var low_q := _frame(a2_n, n_new) * _frame(a2_r, n_rest).inverse() * low_rest
	return {up_q = up_q.normalized(), low_q = low_q.normalized(), wrist = wr, low_dir = a2_n}


## A turn from an axis and a side hint (columns: axis, hint made square to it, their cross).
func _frame(axis: Vector3, hint: Vector3) -> Quaternion:
	var n := (hint - axis * hint.dot(axis)).normalized()
	return Basis(axis, n, axis.cross(n)).get_rotation_quaternion()
