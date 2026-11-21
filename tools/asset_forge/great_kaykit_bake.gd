extends SceneTree
## Bakes the Lampwick Foreman's two-handed moves onto the dwarf (F389, owner Nov 20: "use the Foreman's moves").
## Source: the CC0 "KayKit Character Pack: Skeletons" warrior (tools/asset_forge/packs/kaykit_skeletons/), the same
## skeleton and moves the Foreman uses (builds/kaykit_miners.py). Clips: 2H_Melee_Idle (stance), 2H_Melee_Attack_Chop,
## 2H_Melee_Attack_Spin.
## How (retarget in code, never Godot's import retarget: it renames every bone, ANIMATION-RULES 2): both skeletons
## stand in a T pose facing the same way, so each KayKit bone's turn away from its rest (in the whole skeleton's
## space) is given to the matching dwarf bone, then turned back into each bone's own turn. The hand-slot bone (it
## carries the KayKit weapon) is copied as well: the dwarf's handle follows it.
## Out: assets/anim/great_kaykit.json, per clip 30 frames a second: each dwarf bone's turn (whole-skeleton space), the hips' place,
## the weapon's frame (skeleton space: y = along the handle to the head, x = the pick's points/blade side), and where
## each KayKit hand sits along the handle (m up from the hand slot, KayKit size).
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/great_kaykit_bake.gd -- claude=kaykit_bake
## By the dwarf-animations Claude, chat 11, Nov 20, 2026.
const PACK := "res://tools/asset_forge/packs/kaykit_skeletons/Skeleton_Warrior.glb"
const OUT := "res://assets/anim/great_kaykit.json"
const CLIPS := {"Stance": "2H_Melee_Idle", "Chop": "2H_Melee_Attack_Chop", "Spin": "2H_Melee_Attack_Spin",
	# the great maul (owner, chat 17): side swing, head shove, then the whirl on the right click
	"Slice": "2H_Melee_Attack_Slice", "Stab": "2H_Melee_Attack_Stab", "Spinning": "2H_Melee_Attack_Spinning"}
const FPS := 30.0
const HEAD_CHEST := 0.0  ## share of the chest's turn (vs the hips') the neck and head take
## dwarf bone -> [KayKit bone, KayKit bone, share of the second] (the turn is blended between the two)
const MAP := {
	"pelvis": ["hips", "hips", 0.0],
	"spine_01": ["spine", "spine", 0.0],
	"spine_02": ["spine", "chest", 0.5],
	"spine_03": ["chest", "chest", 0.0],
	# (the neck and head lean with his HIPS, none of the Foreman's own nods: the Foreman bends at the hips and keeps his
	# chest up, but the dwarf's belly and shirt bend with the hips, so a head following the chest stayed behind its
	# shirt's neck hole; owner, chat 11: "the head is not moving correctly", "it needs to move forward with the beard")
	"neck_01": ["hips", "chest", HEAD_CHEST],
	"Head": ["hips", "chest", HEAD_CHEST],  # (owner, chat 11: "the head needs to move forward too, with the beard")
	"clavicle_l": ["chest", "chest", 0.0], "clavicle_r": ["chest", "chest", 0.0],
	"upperarm_l": ["upperarm.l", "upperarm.l", 0.0], "upperarm_r": ["upperarm.r", "upperarm.r", 0.0],
	"lowerarm_l": ["lowerarm.l", "lowerarm.l", 0.0], "lowerarm_r": ["lowerarm.r", "lowerarm.r", 0.0],
	"hand_l": ["hand.l", "hand.l", 0.0], "hand_r": ["hand.r", "hand.r", 0.0],
	"thigh_l": ["upperleg.l", "upperleg.l", 0.0], "thigh_r": ["upperleg.r", "upperleg.r", 0.0],
	"calf_l": ["lowerleg.l", "lowerleg.l", 0.0], "calf_r": ["lowerleg.r", "lowerleg.r", 0.0],
	"foot_l": ["foot.l", "foot.l", 0.0], "foot_r": ["foot.r", "foot.r", 0.0],
	"ball_l": ["toes.l", "toes.l", 0.0], "ball_r": ["toes.r", "toes.r", 0.0],
}


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
	# the dwarf's rest turns (whole-skeleton space) and the KayKit rest
	var d_rest := {}
	for n: String in MAP:
		d_rest[n] = dsk.get_bone_global_rest(dsk.find_bone(n)).basis.get_rotation_quaternion()
	var k_rest := _mirror(_globals(ksk, {}))
	# leg length ratio for the hips' bob (dwarf thigh->foot over KayKit upperleg->foot)
	var d_leg := dsk.get_bone_global_rest(dsk.find_bone("thigh_l")).origin.y - dsk.get_bone_global_rest(dsk.find_bone("foot_l")).origin.y
	var k_leg: float = (k_rest["upperleg.l"] as Transform3D).origin.y - (k_rest["foot.l"] as Transform3D).origin.y
	var ratio := d_leg / k_leg
	var pel := dsk.find_bone("pelvis")
	var pel_parent := dsk.get_bone_global_rest(dsk.get_bone_parent(pel))
	var out := {_about = "F389 chat 11: the Foreman's (KayKit Skeletons, CC0) 2H moves on the dwarf; tools/asset_forge/great_kaykit_bake.gd",
		fps = FPS}
	for clip: String in CLIPS:
		var anim := ap.get_animation(CLIPS[clip])
		var frames: Array = []
		var speeds: Array = []
		var prev_head := Vector3.ZERO
		var n := int(round(anim.length * FPS))
		for f in n + 1:
			var t := minf(f / FPS, anim.length)
			var k_now := _mirror(_globals(ksk, _sample(ksk, anim, t)))
			var g := {}  # dwarf bone -> wanted whole-skeleton turn
			for b: String in MAP:
				var m: Array = MAP[b]
				var da := _delta(k_now, k_rest, m[0])
				var db := _delta(k_now, k_rest, m[1])
				g[b] = da.slerp(db, float(m[2])) * (d_rest[b] as Quaternion)
			var bones := {}  # (whole-skeleton turns: the game gives them to the bones parents first, DwarfGreatSwing.ORDER)
			for b: String in MAP:
				var q := (g[b] as Quaternion).normalized()
				bones[b] = [snappedf(q.x, 1e-4), snappedf(q.y, 1e-4), snappedf(q.z, 1e-4), snappedf(q.w, 1e-4)]
			# the hips' place: the KayKit hips' move from rest, at dwarf size
			var hip_move: Vector3 = ((k_now["hips"] as Transform3D).origin - (k_rest["hips"] as Transform3D).origin) * ratio
			var hp := pel_parent.affine_inverse() * (dsk.get_bone_global_rest(pel).origin + hip_move)
			var slot: Transform3D = k_now["handslot.l"]  # (mirrored: the weapon hand is now the left)
			var w := slot.basis.orthonormalized()
			var hl: Vector3 = (k_now["hand.l"] as Transform3D).origin
			var hr: Vector3 = (k_now["hand.r"] as Transform3D).origin
			frames.append({bones = bones, pelvis = [snappedf(hp.x, 1e-4), snappedf(hp.y, 1e-4), snappedf(hp.z, 1e-4)],
				weapon = [snappedf(w.x.x, 1e-4), snappedf(w.x.y, 1e-4), snappedf(w.x.z, 1e-4),
					snappedf(w.y.x, 1e-4), snappedf(w.y.y, 1e-4), snappedf(w.y.z, 1e-4)],
				kk_l = snappedf((hl - slot.origin).dot(w.y), 1e-3), kk_r = snappedf((hr - slot.origin).dot(w.y), 1e-3),
				kk_off_l = snappedf(_off_line(hl, slot.origin, w.y), 1e-3)})
			var head: Vector3 = slot.origin + w.y * 1.0
			if f > 0:
				var v: Vector3 = (head - prev_head) * FPS
				speeds.append([v.length(), t, v.normalized().dot(w.x), v.normalized().dot(w.z)])
			prev_head = head
			if f % 6 == 0:
				print("%s t=%.2f handle=%s  L along %.2f (off %.2f)  R along %.2f  hips %s" % [clip, t, w.y,
					(hl - slot.origin).dot(w.y), _off_line(hl, slot.origin, w.y), (hr - slot.origin).dot(w.y), hip_move])
		speeds.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		for i in mini(6, speeds.size()):
			print("  fast %s: %.1f m/s at %.2f  (along x %.2f, z %.2f)" % [clip, speeds[i][0], speeds[i][1], speeds[i][2], speeds[i][3]])
		out[clip] = {length = anim.length, frames = frames}
		print("BAKED ", clip, " ", frames.size(), " frames, ", anim.length, " s")
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("SAVED ", OUT)
	quit()


## Every bone's place and turn in the whole skeleton's space, from local poses `local` (bone -> Transform3D; rest if missing).
static func _globals(sk: Skeleton3D, local: Dictionary) -> Dictionary:
	var g := {}
	for i in sk.get_bone_count():
		var n := sk.get_bone_name(i)
		var l: Transform3D = local.get(n, sk.get_bone_rest(i))
		var p := sk.get_bone_parent(i)
		g[n] = ((g[sk.get_bone_name(p)] as Transform3D) * l) if p >= 0 else l
	return g


## Each bone's own place and turn at time t of the clip.
static func _sample(sk: Skeleton3D, anim: Animation, t: float) -> Dictionary:
	var local := {}
	for i in sk.get_bone_count():
		local[sk.get_bone_name(i)] = sk.get_bone_rest(i)
	for tr in anim.get_track_count():
		var path := str(anim.track_get_path(tr))
		var bone := path.get_slice(":", 1)
		if not local.has(bone):
			continue
		var x: Transform3D = local[bone]
		match anim.track_get_type(tr):
			Animation.TYPE_ROTATION_3D:
				x.basis = Basis(anim.rotation_track_interpolate(tr, t)).scaled(x.basis.get_scale())
			Animation.TYPE_POSITION_3D:
				x.origin = anim.position_track_interpolate(tr, t)
			Animation.TYPE_SCALE_3D:
				x.basis = Basis(x.basis.get_rotation_quaternion()).scaled(anim.scale_track_interpolate(tr, t))
		local[bone] = x
	return local


## The KayKit pose mirrored left <-> right (F389, owner: LEFT fist at the end of the handle, RIGHT fist high up it;
## the Foreman holds the end in his right hand, so his moves are copied as in a mirror).
static func _mirror(g: Dictionary) -> Dictionary:
	var m := Basis.from_scale(Vector3(-1, 1, 1))
	var out := {}
	for n: String in g:
		var src := n.replace(".l", ".R").replace(".r", ".l").replace(".R", ".r")
		var x: Transform3D = g.get(src, g[n])
		out[n] = Transform3D(m * x.basis * m, m * x.origin)
	return out


## A KayKit bone's turn away from its rest (whole-skeleton space).
static func _delta(now: Dictionary, rest: Dictionary, bone: String) -> Quaternion:
	var a := (now[bone] as Transform3D).basis.get_rotation_quaternion()
	var r := (rest[bone] as Transform3D).basis.get_rotation_quaternion()
	return (a * r.inverse()).normalized()


static func _off_line(p: Vector3, a: Vector3, d: Vector3) -> float:
	var v := p - a
	return (v - d * v.dot(d)).length()
