extends SceneTree
## Bakes the KayKit skeletons' crossbow moves (aim, shoot, reload) onto the dwarf as plain upper-body clips
## (owner, chat 17: the crossbow "reloads like a gun": it used the UAL pistol clips).
## Source: the CC0 "KayKit Character Pack: Skeletons" warrior (tools/asset_forge/packs/kaykit_skeletons/), clips
## 2H_Ranged_Aiming / _Shoot / _Reload (a two-handed crossbow) and 1H_Ranged_Reload (a hand crossbow) to compare.
## How: the same retarget as great_kaykit_bake.gd (both skeletons in a T pose; each KayKit bone's turn away from rest
## goes to the matching dwarf bone, MAP), NOT mirrored (the crossbow stays in his right hand), then turned into each
## bone's own (local) turn and saved as rotation tracks, so DwarfRig plays them like any other clip ("c/" library).
## Out: assets/anim/crossbow_kaykit.res (an AnimationLibrary: Aim, Shoot, Reload, Reload1H).
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/crossbow_kaykit_bake.gd -- claude=crossbow_bake
## By the dwarf-animations Claude, chat 17, Nov 21, 2026.
const PACK := "res://tools/asset_forge/packs/kaykit_skeletons/Skeleton_Warrior.glb"
const OUT := "res://assets/anim/crossbow_kaykit.res"
const CLIPS := {"Aim": "2H_Ranged_Aiming", "Shoot": "2H_Ranged_Shoot", "Reload": "2H_Ranged_Reload",
	"Reload1H": "1H_Ranged_Reload"}
const LOOPING := ["Aim"]
const FPS := 30.0
## Only the upper body (the legs keep walking; DwarfRig plays these on its upper-body layer).
const UPPER := ["spine_01", "spine_02", "spine_03", "neck_01", "Head", "clavicle_l", "clavicle_r",
	"upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r"]
## Bones kept at their rest turn in the whole skeleton (hips: the legs' own; neck and head: looking ahead).
const KEEP_REST := ["pelvis", "neck_01", "Head"]
## The extra turn of his chest (degrees round the up line, spread up the spine): the KayKit hands lie 40 degrees left
## of ahead once its hips' turn is left out, so the bow (right hand at the stock, left hand under the front) points ahead.
const TWIST := -40.0
const TWIST_SHARE := {"spine_01": 0.33, "spine_02": 0.67, "spine_03": 1.0}
const BAKE := preload("res://tools/asset_forge/great_kaykit_bake.gd")


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
	var rig := model.dwarf_rig
	var dsk := rig.skeleton
	# the track path the dwarf's other clips use (e.g. "Armature/Skeleton3D:spine_01" -> the part before ":")
	var ref := rig.tree.get_animation(DwarfRig.ANIMS.aim)
	var prefix := str(ref.track_get_path(0)).get_slice(":", 0)
	print("track prefix ", prefix)
	var d_rest := {}
	for n: String in BAKE.MAP:
		d_rest[n] = dsk.get_bone_global_rest(dsk.find_bone(n)).basis.get_rotation_quaternion()
	var k_rest := BAKE._globals(ksk, {})
	var lib := AnimationLibrary.new()
	for clip: String in CLIPS:
		var src := ap.get_animation(CLIPS[clip])
		var anim := Animation.new()
		anim.length = src.length
		anim.loop_mode = Animation.LOOP_LINEAR if clip in LOOPING else Animation.LOOP_NONE
		var tracks := {}
		for b: String in UPPER:
			var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(tr, NodePath("%s:%s" % [prefix, b]))
			tracks[b] = tr
		var n := int(round(src.length * FPS))
		for f in n + 1:
			var t := minf(f / FPS, src.length)
			var k_now := BAKE._globals(ksk, BAKE._sample(ksk, src, t))
			var want := {}  # dwarf bone -> wanted whole-skeleton turn
			for b: String in BAKE.MAP:
				var m: Array = BAKE.MAP[b]
				var da := BAKE._delta(k_now, k_rest, m[0])
				var db := BAKE._delta(k_now, k_rest, m[1])
				want[b] = (da.slerp(db, float(m[2])) * (d_rest[b] as Quaternion)).normalized()
				if TWIST_SHARE.has(b) or b in ["clavicle_l", "clavicle_r", "upperarm_l", "upperarm_r", "lowerarm_l",
						"lowerarm_r", "hand_l", "hand_r"]:  # (his chest turned further right: the bow points ahead)
					var share: float = TWIST_SHARE.get(b, 1.0)
					want[b] = (Quaternion(Vector3.UP, deg_to_rad(TWIST * share)) * (want[b] as Quaternion)).normalized()
			# every dwarf bone's whole-skeleton turn, parents first: the wanted one, else its rest under its parent
			var glob := {}
			for i in dsk.get_bone_count():
				var bn := dsk.get_bone_name(i)
				var p := dsk.get_bone_parent(i)
				var pq: Quaternion = glob[p] if p >= 0 else Quaternion.IDENTITY
				# (the KayKit skeleton turns its hips 46 degrees right to aim; the dwarf's legs keep walking ahead, so his
				# hips stay at rest here and the chest keeps the turn it has in the world; the head looks straight ahead)
				var own := want.has(bn) and not (bn in KEEP_REST)
				glob[i] = want[bn] if own else (pq * dsk.get_bone_rest(i).basis.get_rotation_quaternion()).normalized()
				if bn in KEEP_REST and want.has(bn):
					glob[i] = d_rest[bn]
				if tracks.has(bn):
					anim.rotation_track_insert_key(tracks[bn], t, (pq.inverse() * (glob[i] as Quaternion)).normalized())
		lib.add_animation(clip, anim)
		print("BAKED %s (%s) %d frames, %.2f s" % [clip, CLIPS[clip], n + 1, src.length])
	print("SAVED ", OUT, " ", ResourceSaver.save(lib, OUT))
	quit()
