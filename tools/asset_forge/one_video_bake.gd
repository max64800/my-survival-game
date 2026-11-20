extends SceneTree
## Bakes the owner's OWN filmed sword and mace combos onto the dwarf (F389 chat 13, owner Nov 20: "copy my videos";
## he didn't like the pack's one-handed moves: too still, the free arm T-posed, not big swings).
## In: the direction file from tools/mocap/one_hand_targets.py (his tracked moves as bone DIRECTIONS in the dwarf's
## skeleton space: x = his left, y = up, z = his front; never his distances: his arms are twice as long).
## Each limb bone is turned so it points the filmed way, its hinge (elbow, knee) lined up with the filmed one; the
## chest and hips take the filmed turn and lean (the low spine bones take most of the twist: his belly is bound there);
## the neck and head follow the hips (ANIMATION-RULES 2b); the feet stay flat, turned the filmed way.
## "tip": where the stick's tip is against his body (shoulder widths from his shoulders' middle; DwarfFist aims the
## sword's tip at the same spot on the dwarf).
## Out: assets/anim/one_video.json, the same frame layout as one_kaykit.json (DwarfOneSwing plays both).
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/one_video_bake.gd -- <targets.json> claude=one_video_bake
## By the dwarf-animations Claude, chat 13, Nov 20, 2026.
const OUT := "res://assets/anim/one_video.json"
## limb bone -> [the bone it points at, which filmed direction, which filmed hinge]
const LIMBS := {
	"upperarm_r": ["lowerarm_r", "arm_r", "bend_r"], "lowerarm_r": ["hand_r", "fore_r", "bend_r"],
	"upperarm_l": ["lowerarm_l", "arm_l", "bend_l"], "lowerarm_l": ["hand_l", "fore_l", "bend_l"],
	"thigh_l": ["calf_l", "thigh_l", "knee_l"], "calf_l": ["foot_l", "calf_l", "knee_l"],
	"thigh_r": ["calf_r", "thigh_r", "knee_r"], "calf_r": ["foot_r", "calf_r", "knee_r"],
}
## how much of the chest's turn (against the hips') each spine bone takes
const SPINE := {"spine_01": 0.55, "spine_02": 0.85, "spine_03": 1.0}


func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


## The turn taking the frame (d0 along, r0 hinge) onto (d1, r1).
func _turn(d0: Vector3, r0: Vector3, d1: Vector3, r1: Vector3) -> Quaternion:
	var a := Basis(d0, r0, d0.cross(r0)).orthonormalized()
	var b := Basis(d1, r1, d1.cross(r1)).orthonormalized()
	return (b * a.inverse()).get_rotation_quaternion()


func _square(r: Vector3, d: Vector3) -> Vector3:
	return (r - r.dot(d) * d).normalized()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var src: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not src is Dictionary:
		print("BAKE could not read ", args[0])
		quit(1)
		return
	var model := DwarfModel.new()
	root.add_child(model)
	await process_frame
	var dsk := model.dwarf_rig.skeleton
	var rest := {}  # bone -> global rest
	for n: String in DwarfGreatSwing.ORDER:
		rest[n] = dsk.get_bone_global_rest(dsk.find_bone(n))
	var rq := func(n: String) -> Quaternion: return (rest[n] as Transform3D).basis.get_rotation_quaternion()
	var d_leg := dsk.get_bone_global_rest(dsk.find_bone("thigh_l")).origin.y - dsk.get_bone_global_rest(dsk.find_bone("foot_l")).origin.y
	var pel := dsk.find_bone("pelvis")
	var pel_parent := dsk.get_bone_global_rest(dsk.get_bone_parent(pel))
	# each limb's rest frame: along the bone, and its hinge (arms: the forearm folds forward; legs: the calf folds back)
	var rest_dir := {}
	var rest_hinge := {}
	for b: String in LIMBS:
		var d := ((rest[LIMBS[b][0]] as Transform3D).origin - (rest[b] as Transform3D).origin).normalized()
		rest_dir[b] = d
		rest_hinge[b] = _square(d.cross(Vector3.BACK) if b.contains("arm") else d.cross(Vector3.FORWARD), d)
	var foot_rest := {}
	for s in ["l", "r"]:
		var f := ((rest["ball_" + s] as Transform3D).origin - (rest["foot_" + s] as Transform3D).origin)
		f.y = 0.0
		foot_rest[s] = f.normalized()
	print("rest: arm_r ", rest_dir["upperarm_r"], " hinge ", rest_hinge["upperarm_r"], "; thigh_l ", rest_dir["thigh_l"],
		" hinge ", rest_hinge["thigh_l"], "; foot_l ", foot_rest["l"], "; leg ", d_leg)
	var fps := float(src.get("fps", 30.0))
	var out := {_about = "F389 chat 13: the owner's own filmed sword and mace combos on the dwarf; tools/mocap/one_hand_targets.py + tools/asset_forge/one_video_bake.gd",
		fps = fps}
	for clip: String in src:
		if not src[clip] is Dictionary:
			continue
		var frames: Array = []
		for f: Dictionary in src[clip].frames:
			var g := {}
			for b: String in LIMBS:
				var d := _v(f[LIMBS[b][1]]).normalized()
				var t := _turn(rest_dir[b], rest_hinge[b], d, _square(_v(f[LIMBS[b][2]]), d))
				g[b] = t * rq.call(b)
			g["hand_r"] = (g["lowerarm_r"] as Quaternion) * (rq.call("lowerarm_r") as Quaternion).inverse() * rq.call("hand_r")
			g["hand_l"] = (g["lowerarm_l"] as Quaternion) * (rq.call("lowerarm_l") as Quaternion).inverse() * rq.call("hand_l")
			var hx := _v(f.hips_x).normalized()
			var hips := Basis(hx, _square(_v(f.hips_y), hx), hx.cross(_square(_v(f.hips_y), hx))).get_rotation_quaternion()
			var cx := _v(f.chest_x).normalized()
			var cy := _square(_v(f.chest_y), cx)
			var chest := Basis(cx, cy, cx.cross(cy)).get_rotation_quaternion()
			g["pelvis"] = hips * rq.call("pelvis")
			for b: String in SPINE:
				g[b] = hips.slerp(chest, float(SPINE[b])) * rq.call(b)
			for b in ["clavicle_l", "clavicle_r"]:
				g[b] = chest * rq.call(b)
			for b in ["neck_01", "Head"]:  # (with the hips: ANIMATION-RULES 2b)
				g[b] = hips * rq.call(b)
			for s in ["l", "r"]:
				var want := _v(f["foot_" + s])
				var yaw := Quaternion(foot_rest[s], want.normalized()) if want.length() > 0.1 else Quaternion.IDENTITY
				g["foot_" + s] = yaw * rq.call("foot_" + s)
				g["ball_" + s] = yaw * rq.call("ball_" + s)
			var bones := {}
			for b: String in g:
				var q: Quaternion = (g[b] as Quaternion).normalized()
				bones[b] = [snappedf(q.x, 1e-4), snappedf(q.y, 1e-4), snappedf(q.z, 1e-4), snappedf(q.w, 1e-4)]
			var hm: Array = f.hip_move
			var hp := pel_parent.affine_inverse() * ((rest["pelvis"] as Transform3D).origin + Vector3(hm[0], hm[1], 0.0) * d_leg)
			var h := _v(f.handle).normalized()
			var e := _square(_v(f.edge), h)
			frames.append({bones = bones, pelvis = [snappedf(hp.x, 1e-4), snappedf(hp.y, 1e-4), snappedf(hp.z, 1e-4)],
				handle = [snappedf(h.x, 1e-4), snappedf(h.y, 1e-4), snappedf(h.z, 1e-4)],
				edge = [snappedf(e.x, 1e-4), snappedf(e.y, 1e-4), snappedf(e.z, 1e-4)],
				tip = (f.tip as Array).map(func(x: float) -> float: return snappedf(x, 1e-4))})
		out[clip] = {length = float(src[clip].length), strike = float(src[clip].strike), frames = frames}
		print("BAKED %s: %d frames, %.2f s, strike at %.2f s" % [clip, frames.size(), float(src[clip].length), float(src[clip].strike)])
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("SAVED ", OUT)
	quit()
