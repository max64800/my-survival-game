extends SceneTree
## Bakes the KayKit Skeletons warrior's ONE-handed moves onto the dwarf (F389, owner Nov 20: "do the same for the sword
## and the mace"). The same way as the great axe (great_kaykit_bake.gd, ANIMATION-RULES 2b): each KayKit bone's turn away
## from its T-pose rest (whole-skeleton space) goes to the matching dwarf bone; the neck and head follow the hips.
## Not mirrored: the pack holds one-handed weapons in the RIGHT hand, like the dwarf.
## Per clip it also finds the strike (the weapon tip's fastest frames: the game's hit lands on its end) and which side
## of the hand slot leads the swing (the blade's edge = the way it moves).
## Out: assets/anim/one_kaykit.json (same frame layout as great_kaykit.json, + "strike" per clip).
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/one_kaykit_bake.gd -- claude=one_bake
## By the dwarf-animations Claude, chat 12, Nov 20, 2026.
const GB := preload("res://tools/asset_forge/great_kaykit_bake.gd")
const PACK := "res://tools/asset_forge/packs/kaykit_skeletons/Skeleton_Warrior.glb"
const OUT := "res://assets/anim/one_kaykit.json"
const CLIPS := {"Chop": "1H_Melee_Attack_Chop", "SliceDiag": "1H_Melee_Attack_Slice_Diagonal",
	"SliceFlat": "1H_Melee_Attack_Slice_Horizontal", "Stab": "1H_Melee_Attack_Stab", "JumpChop": "1H_Melee_Attack_Jump_Chop",
	"BlockAttack": "Block_Attack"}
const FPS := 30.0
const TIP := 0.7  ## m (KayKit size) from the hand slot to the weapon's tip, for the strike's speed


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
	var MAP: Dictionary = GB.MAP
	var d_rest := {}
	for n: String in MAP:
		d_rest[n] = dsk.get_bone_global_rest(dsk.find_bone(n)).basis.get_rotation_quaternion()
	var k_rest := GB._globals(ksk, {})
	var d_leg := dsk.get_bone_global_rest(dsk.find_bone("thigh_l")).origin.y - dsk.get_bone_global_rest(dsk.find_bone("foot_l")).origin.y
	var k_leg: float = (k_rest["upperleg.l"] as Transform3D).origin.y - (k_rest["foot.l"] as Transform3D).origin.y
	var ratio := d_leg / k_leg
	var pel := dsk.find_bone("pelvis")
	var pel_parent := dsk.get_bone_global_rest(dsk.get_bone_parent(pel))
	var out := {_about = "F389 chat 12: the KayKit Skeletons warrior's (CC0) one-handed moves on the dwarf; tools/asset_forge/one_kaykit_bake.gd",
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
			var hip_move: Vector3 = ((k_now["hips"] as Transform3D).origin - (k_rest["hips"] as Transform3D).origin) * ratio
			var hp := pel_parent.affine_inverse() * (dsk.get_bone_global_rest(pel).origin + hip_move)
			var slot: Transform3D = k_now["handslot.r"]
			var w := slot.basis.orthonormalized()
			slots.append([t, slot.origin + w.y * TIP, w, (k_now["hips"] as Transform3D).origin])
			frames.append({bones = bones, pelvis = [snappedf(hp.x, 1e-4), snappedf(hp.y, 1e-4), snappedf(hp.z, 1e-4)],
				handle = [snappedf(w.y.x, 1e-4), snappedf(w.y.y, 1e-4), snappedf(w.y.z, 1e-4)]})
		# the strike: among the fast frames (60%+ of the fastest), the one where the tip is most in front of him (the
		# fastest frame alone was often past his side: the hit must land on what's in front)
		var best := 0.0
		var strike := anim.length * 0.4
		var fwd := Vector3.BACK  # (the KayKit warrior faces +Z)
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
