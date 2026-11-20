extends SceneTree
## Bakes Quaternius's Universal Animation Library 2 sword moves (CC0, already the dwarf's own pack) into the swing
## format DwarfFist lays the weapon by (F389 chat 14: the owner's filmed moves looked "really bad"; his pick: free pack
## moves). UAL 2 uses the dwarf's own bone names, so each bone takes its own turn away from the T-pose rest (whole-
## skeleton space, ANIMATION-RULES 2b); the neck and head follow the hips. The sword's direction: the dwarf's own grip
## (DwarfModel.hand_tool_rot + DwarfRig.GRIPS.sword) on the turned hand. Strike and edge found like one_kaykit_bake.gd.
## (Tried once, Nov 17, played straight with the old grip: the blade went through his body. Not with this way.)
## Out: assets/anim/one_ual.json.
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/one_ual_bake.gd -- claude=one_ual_bake
## By the dwarf-animations Claude, chat 14, Nov 20, 2026 (from one_kaykit_bake.gd).
const GB := preload("res://tools/asset_forge/great_kaykit_bake.gd")
const PACK := "res://assets/characters/anims/UAL2.glb"
const OUT := "res://assets/anim/one_ual.json"
## The game's sword attacks (owner, chat 15: "as perfect as it can get"): the regular combo cut at its 3 hits (one per
## click; tip-speed peaks at 0.26, 0.73, 1.57 s, settled by 1.68), the heavy = hit C alone. [pack clip, from, to] (s)
const GAME := {"UalHit1": ["Sword_Regular_Combo", 0.0, 0.50], "UalHit2": ["Sword_Regular_Combo", 0.50, 1.15],
	"UalHit3": ["Sword_Regular_Combo", 1.15, 1.95], "UalHeavyHit": ["Sword_Regular_C", 0.0, 1.0],
	# the mace (owner, chat 15: "the heavy combo is the mace main combo"): its 4 hits, one per click (peaks 0.50, 1.17,
	# 1.86, 2.60 s; settled by 2.66)
	"UalMace1": ["Sword_Heavy_Combo", 0.0, 0.85], "UalMace2": ["Sword_Heavy_Combo", 0.85, 1.50],
	"UalMace3": ["Sword_Heavy_Combo", 1.50, 2.20], "UalMace4": ["Sword_Heavy_Combo", 2.20, 3.00]}
const CLIPS := {"UalCombo": "Sword_Regular_Combo", "UalA": "Sword_Regular_A", "UalB": "Sword_Regular_B", "UalC": "Sword_Regular_C",
	"UalHeavy": "Sword_Heavy_Combo"}
## dwarf bone -> [pack bone, pack bone, mix] (the same names; the neck and head with the hips: ANIMATION-RULES 2b)
const MAP := {
	"pelvis": ["pelvis", "pelvis", 0.0], "spine_01": ["spine_01", "spine_01", 0.0], "spine_02": ["spine_02", "spine_02", 0.0],
	"spine_03": ["spine_03", "spine_03", 0.0], "neck_01": ["pelvis", "pelvis", 0.0], "Head": ["pelvis", "pelvis", 0.0],
	"clavicle_l": ["clavicle_l", "clavicle_l", 0.0], "clavicle_r": ["clavicle_r", "clavicle_r", 0.0],
	"upperarm_l": ["upperarm_l", "upperarm_l", 0.0], "upperarm_r": ["upperarm_r", "upperarm_r", 0.0],
	"lowerarm_l": ["lowerarm_l", "lowerarm_l", 0.0], "lowerarm_r": ["lowerarm_r", "lowerarm_r", 0.0],
	"hand_l": ["hand_l", "hand_l", 0.0], "hand_r": ["hand_r", "hand_r", 0.0],
	"thigh_l": ["thigh_l", "thigh_l", 0.0], "thigh_r": ["thigh_r", "thigh_r", 0.0],
	"calf_l": ["calf_l", "calf_l", 0.0], "calf_r": ["calf_r", "calf_r", 0.0],
	"foot_l": ["foot_l", "foot_l", 0.0], "foot_r": ["foot_r", "foot_r", 0.0],
	"ball_l": ["ball_l", "ball_l", 0.0], "ball_r": ["ball_r", "ball_r", 0.0],
}
## the body bones whose bend end= scales (the neck and head follow the hips)
const BODY := ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head"]
const STEP := 4  ## poses between speed readings (1/30 s)
const FPS := 120.0  ## (chat 15: at 30 the pack's fast spins turned over 180 deg between poses and played backwards)
const TIP := 0.7  ## m (pack size) from the hand slot to the weapon's tip, for the strike's speed


func _init() -> void:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(PACK), st) != OK:
		print("BAKE could not read ", PACK)
		quit(1)
		return
	var kk := doc.generate_scene(st)
	var ksk: Skeleton3D = kk.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = kk.find_children("*", "AnimationPlayer", true, false)[0]
	var model := DwarfModel.new()
	root.add_child(model)
	await process_frame
	var dsk := model.dwarf_rig.skeleton
	var d_rest := {}
	for n: String in MAP:
		d_rest[n] = dsk.get_bone_global_rest(dsk.find_bone(n)).basis.get_rotation_quaternion()
	var k_rest := GB._globals(ksk, {})
	var d_leg := dsk.get_bone_global_rest(dsk.find_bone("thigh_l")).origin.y - dsk.get_bone_global_rest(dsk.find_bone("foot_l")).origin.y
	var k_leg: float = (k_rest["thigh_l"] as Transform3D).origin.y - (k_rest["foot_l"] as Transform3D).origin.y
	var grip := Basis.from_euler(DwarfModel.hand_tool_rot) * Basis.from_euler((DwarfRig.GRIPS.sword[""][0] as Vector3) * (PI / 180.0))
	var ratio := d_leg / k_leg
	var pel := dsk.find_bone("pelvis")
	var pel_parent := dsk.get_bone_global_rest(dsk.get_bone_parent(pel))
	var out := {_about = "F389 chat 14: Quaternius UAL 2 (CC0) sword moves on the dwarf; tools/asset_forge/one_ual_bake.gd",
		fps = FPS}
	var bend := float(_arg("bend=", "0.5"))
	var all_clips := CLIPS.merged(GAME)
	for clip: String in all_clips:
		var cdef: Variant = all_clips[clip]
		var src: String = cdef if cdef is String else cdef[0]
		var anim := ap.get_animation(src)
		var from := 0.0 if cdef is String else float(cdef[1])
		var length := anim.length if cdef is String else float(cdef[2]) - from
		var frames: Array = []
		var slots: Array = []  # [time, tip (skeleton space), slot basis]
		var n := int(round(length * FPS))
		for f in n + 1:
			var t := minf(f / FPS, length)
			var at := from + t
			var k_now := GB._globals(ksk, GB._sample(ksk, anim, at))
			var bones := {}
			for b: String in MAP:
				var m: Array = MAP[b]
				var dq := GB._delta(k_now, k_rest, m[0]).slerp(GB._delta(k_now, k_rest, m[1]), float(m[2]))
				if b in BODY:  # (chat 15: the pack's deep bends fold the round dwarf onto his own shield)
					dq = _less_lean(dq, bend)
				var q := (dq * (d_rest[b] as Quaternion)).normalized()
				bones[b] = [snappedf(q.x, 1e-4), snappedf(q.y, 1e-4), snappedf(q.z, 1e-4), snappedf(q.w, 1e-4)]
			var hip_move: Vector3 = ((k_now["pelvis"] as Transform3D).origin - (k_rest["pelvis"] as Transform3D).origin) * ratio
			var hp := pel_parent.affine_inverse() * (dsk.get_bone_global_rest(pel).origin + hip_move)
			var hq: Array = bones["hand_r"]  # (the dwarf's own hand turn, with his own grip: the sword's frame)
			var w := Basis(Quaternion(hq[0], hq[1], hq[2], hq[3])) * grip
			var hand: Transform3D = k_now["hand_r"]
			slots.append([t, hand.origin + w.y * TIP, w, (k_now["pelvis"] as Transform3D).origin])
			frames.append({bones = bones, pelvis = [snappedf(hp.x, 1e-4), snappedf(hp.y, 1e-4), snappedf(hp.z, 1e-4)],
				handle = [snappedf(w.y.x, 1e-4), snappedf(w.y.y, 1e-4), snappedf(w.y.z, 1e-4)]})
		var lock := _arg("lock=", "none")
		if lock != "none":
			_lock_shield_arm(frames, lock)
		# the strike: among the fast frames (60%+ of the fastest), the one where the tip is most in front of him (the
		# fastest frame alone was often past his side: the hit must land on what's in front)
		var best := 0.0
		var strike := length * 0.4
		var fwd := Vector3.BACK  # (the pack's mannequin faces +Z, like the dwarf's skeleton)
		var speeds: Array = [0.0]
		for i in range(1, slots.size()):
			var j := maxi(i - STEP, 0)  # (over 1/30 s, as before 120 poses a second: finer steps were jittery)
			speeds.append((((slots[i][1] as Vector3) - (slots[j][1] as Vector3)) * FPS / float(i - j)).length())
		var top: float = speeds.max()
		if "peaks=1" in OS.get_cmdline_user_args():  # (tools: where each hit of a combo lands, and where it settles)
			var pk := []
			var last := 0.0
			for i in range(1, speeds.size() - 1):
				if float(speeds[i]) > top * 0.15:
					last = float(slots[i][0])
				if float(speeds[i]) >= top * 0.5 and float(speeds[i]) >= float(speeds[i - 1]) and float(speeds[i]) > float(speeds[i + 1]):
					pk.append("%.2f(%.0f)" % [float(slots[i][0]), float(speeds[i])])
			print("PEAKS %s: %s  settles %.2f" % [clip, " ".join(pk), last])
		var most_front := -INF
		for i in range(1, slots.size()):
			if float(speeds[i]) < top * 0.6:
				continue
			var d: Vector3 = (slots[i][1] as Vector3) - (slots[i][3] as Vector3)
			d.y = 0.0
			var front := d.normalized().dot(fwd)
			if front > most_front:
				most_front = front
				strike = float(slots[i][0])
		var sum := {"x": 0.0, "-x": 0.0, "z": 0.0, "-z": 0.0}
		for i in range(1, slots.size()):
			var j := maxi(i - STEP, 0)
			var v: Vector3 = ((slots[i][1] as Vector3) - (slots[j][1] as Vector3)) * FPS / float(i - j)
			var w: Basis = slots[i][2]
			# (which side of the slot leads, weighted by speed squared: the strike counts most)
			var s := v.length()
			if s > 0.01:
				var d := v / s
				sum["x"] += s * s * maxf(d.dot(w.x), 0.0)
				sum["-x"] += s * s * maxf(-d.dot(w.x), 0.0)
				sum["z"] += s * s * maxf(d.dot(w.z), 0.0)
				sum["-z"] += s * s * maxf(-d.dot(w.z), 0.0)
			best = maxf(best, s)
		var lead := "x"
		for k: String in sum:
			if float(sum[k]) > float(sum[lead]):
				lead = k
		for i in frames.size():
			var w: Basis = slots[i][2]
			var e: Vector3 = {"x": w.x, "-x": -w.x, "z": w.z, "-z": -w.z}[lead]
			frames[i]["edge"] = [snappedf(e.x, 1e-4), snappedf(e.y, 1e-4), snappedf(e.z, 1e-4)]
		out[clip] = {length = length, strike = strike, frames = frames}
		print("BAKED %s (%s) %d frames, %.2f s, strike at %.2f s (tip %.2f in front; fastest %.1f m/s), edge %s" % [clip,
			src, frames.size(), length, strike, most_front, best, lead])
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("SAVED ", OUT)
	quit()


## Owner, chat 15: "the left one with the shield should not move at all": the shield arm keeps the pose it ends the
## move in (his guard), fixed to his chest, so it turns with the body but never swings on its own.
const SHIELD_ARM := ["clavicle_l", "upperarm_l", "lowerarm_l", "hand_l"]


static func _lock_shield_arm(frames: Array, to: String) -> void:
	var last: Dictionary = frames[-1]["bones"]
	var chest_end := _q(last[to]).inverse()
	for fr: Dictionary in frames:
		var chest := _q(fr["bones"][to])
		for b: String in SHIELD_ARM:
			var q := (chest * chest_end * _q(last[b])).normalized()
			fr["bones"][b] = [snappedf(q.x, 1e-4), snappedf(q.y, 1e-4), snappedf(q.z, 1e-4), snappedf(q.w, 1e-4)]


static func _q(a: Array) -> Quaternion:
	return Quaternion(a[0], a[1], a[2], a[3])


static func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(key):
			return a.substr(key.length())
	return fallback


## Only the lean (forward, sideways) is cut to `k`; the spin round his up axis stays whole (chat 15: cutting the whole
## turn flipped him 180 deg in one frame as a spin passed half a turn).
static func _less_lean(q: Quaternion, k: float) -> Quaternion:
	var tw := Quaternion(0.0, q.y, 0.0, q.w)
	if tw.length_squared() < 1e-8:
		return Quaternion.IDENTITY.slerp(q, k)
	tw = tw.normalized()
	var sw := (q * tw.inverse()).normalized()
	return (Quaternion.IDENTITY.slerp(sw, k) * tw).normalized()
