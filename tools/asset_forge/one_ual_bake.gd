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
const FPS := 30.0
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
	for clip: String in CLIPS:
		var anim := ap.get_animation(CLIPS[clip])
		var frames: Array = []
		var slots: Array = []  # [time, tip (skeleton space), slot basis]
		var n := int(round(anim.length * FPS))
		for f in n + 1:
			var t := minf(f / FPS, anim.length)
			var k_now := GB._globals(ksk, GB._sample(ksk, anim, t))
			var bones := {}
			for b: String in MAP:
				var m: Array = MAP[b]
				var q := (GB._delta(k_now, k_rest, m[0]).slerp(GB._delta(k_now, k_rest, m[1]), float(m[2])) * (d_rest[b] as Quaternion)).normalized()
				bones[b] = [snappedf(q.x, 1e-4), snappedf(q.y, 1e-4), snappedf(q.z, 1e-4), snappedf(q.w, 1e-4)]
			var hip_move: Vector3 = ((k_now["pelvis"] as Transform3D).origin - (k_rest["pelvis"] as Transform3D).origin) * ratio
			var hp := pel_parent.affine_inverse() * (dsk.get_bone_global_rest(pel).origin + hip_move)
			var hq: Array = bones["hand_r"]  # (the dwarf's own hand turn, with his own grip: the sword's frame)
			var w := Basis(Quaternion(hq[0], hq[1], hq[2], hq[3])) * grip
			var hand: Transform3D = k_now["hand_r"]
			slots.append([t, hand.origin + w.y * TIP, w, (k_now["pelvis"] as Transform3D).origin])
			frames.append({bones = bones, pelvis = [snappedf(hp.x, 1e-4), snappedf(hp.y, 1e-4), snappedf(hp.z, 1e-4)],
				handle = [snappedf(w.y.x, 1e-4), snappedf(w.y.y, 1e-4), snappedf(w.y.z, 1e-4)]})
		# the strike: among the fast frames (60%+ of the fastest), the one where the tip is most in front of him (the
		# fastest frame alone was often past his side: the hit must land on what's in front)
		var best := 0.0
		var strike := anim.length * 0.4
		var fwd := Vector3.BACK  # (the pack's mannequin faces +Z, like the dwarf's skeleton)
		var speeds: Array = [0.0]
		for i in range(1, slots.size()):
			speeds.append((((slots[i][1] as Vector3) - (slots[i - 1][1] as Vector3)) * FPS).length())
		var top: float = speeds.max()
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
			var v: Vector3 = ((slots[i][1] as Vector3) - (slots[i - 1][1] as Vector3)) * FPS
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
		out[clip] = {length = anim.length, strike = strike, frames = frames}
		print("BAKED %s (%s) %d frames, %.2f s, strike at %.2f s (tip %.2f in front; fastest %.1f m/s), edge %s" % [clip,
			CLIPS[clip], frames.size(), anim.length, strike, most_front, best, lead])
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("SAVED ", OUT)
	quit()
