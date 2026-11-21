extends SceneTree
## Records the game dwarf swinging the sword and the mace with the KayKit warrior's one-handed moves (F389 chat 12:
## DwarfOneSwing + DwarfFist, exactly as the game plays them, frame by frame) into one .glb for the "Sword and Mace
## Swings" 3D page: the dwarf's shaped bones, the sword, the mace and the shield (each its own node, moved every frame;
## the page shows the one the clip is for).
## Clips: "<Weapon>_<Move>_<light|heavy>" (the game's light and heavy swing times, Combat.WEAPONS), and "<Weapon>_Stand".
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/one_swing_export.gd
##     -- <out.glb> [shield=1] [video=1] claude=one_swing_export
## video=1 (chat 14): the owner's own filmed hits instead (assets/anim/one_video.json): "<Weapon>_Combo" = hits 1-2-3
## back to back at the filmed speed, "<Weapon>_Hit1".."_Hit3" alone, and "<Weapon>_Stand".
## ual=1 (chat 14): Quaternius UAL 2's sword moves (assets/anim/one_ual.json), each "Sword_<move>" at its own length.
## By the dwarf-animations Claude, chat 12, Nov 20, 2026 (from great_swing_export.gd).
const WEAPONS := {
	"Sword": ["sword_copper", "sword", ["SliceDiag", "SliceFlat", "Stab", "Chop"]],
	"Mace": ["mace_copper", "mace", ["Chop", "SliceDiag", "JumpChop", "SliceFlat"]],
}
const VIDEO := {
	"Sword": ["sword_copper", ["SwordHit1", "SwordHit2", "SwordHit3"]],
	"Mace": ["mace_copper", ["MaceHit1", "MaceHit2", "MaceHit3"]],
}
const UAL := {"Sword": ["sword_copper", ["UalCombo", "UalA", "UalB", "UalC", "UalHeavy"]]}
const AFTER := 0.45  ## s recorded after the swing (easing back)
## record every Nth frame (3: 60 fps game -> 20 fps clip; the page blends between). every=1 (chat 15): the page's
## straight-line blend between frames put the sword out of his hand in fast spins
var EVERY := 3
var chain_slow := 1.0  ## a chain's hits at this many times their own length
## pack=1 (chat 15, owner: "show me what UAL moves have"): the UAL 2 fighting moves the game doesn't use yet
const PACK_MOVES := ["b/Shield_OneShot", "b/Shield_Dash", "b/Idle_Shield", "b/Idle_Shield_Break", "b/Sword_Block",
	"b/Sword_Dash", "b/Melee_Hook", "b/OverhandThrow", "b/Hit_Knockback", "Roll", "Punch_Jab", "Punch_Cross", "b/Slide_Start"]
const NODES := ["turn", "Sword", "Mace", "shield"]
## bow=1 (chat 17, with all=1): the crossbow's KayKit moves ("c/", crossbow_kaykit_bake.gd), "Crossbow_Try<move>",
## and all three in a row ("Crossbow_TryAll")
const BOW_TRY := ["Aim", "Shoot", "Reload", "Reload1H"]
## all=1 (chat 15, owner: "an artifact where I can see everything we've implemented in terms of moves"): every weapon
## the way the game plays it (DwarfModel.attack at DwarfRig.attack_seconds, the combo clicked the moment the last hit
## lets you, as DwarfFight does), then the blocks, the shield bash, stunned, dying, the roll and the crossbow.
## [holder node, item, shield on the left arm]
const ALL := [["Sword", "sword_copper", true], ["Mace", "mace_copper", true], ["Spear", "spear_copper", true],
	["GreatAxe", "axe_2h_copper", false], ["GreatMaul", "mace_2h_copper", false], ["Crossbow", "crossbow_copper", false]]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var with_shield := "shield=1" in args
	var video := "video=1" in args
	var ual := "ual=1" in args
	for a: String in args:
		if a.begins_with("every="):
			EVERY = int(a.substr(6))
	var weapons: Dictionary = {} if "all=1" in args else (UAL if ual else (VIDEO if video else WEAPONS))
	var model := DwarfModel.new()
	root.add_child(model)
	for i in 5:
		await process_frame
	var rig := model.dwarf_rig
	var sk := rig.skeleton
	var lib := AnimationLibrary.new()
	var tools := {}
	var shield_copy: Node3D = null
	if with_shield:
		model.set_shield("shield_copper")
	for wname: String in weapons:
		var wdef: Array = weapons[wname]
		model.set_held(wdef[0])
		for i in 30:
			rig.set_motion(0.0, true, false)
			await process_frame
		tools[wname] = (rig.grip.get_child(rig.grip.get_child_count() - 1) as Node3D).duplicate()
		if with_shield and shield_copy == null:
			shield_copy = (rig.shield_grip.get_child(rig.shield_grip.get_child_count() - 1) as Node3D).duplicate()
		lib.add_animation(wname + "_Stand", await _record(rig, wname, "", 0.0, 1.0))
		if ual:
			for mv: String in wdef[1]:
				var d := DwarfOneSwing.clip_length(mv)
				lib.add_animation("%s_%s" % [wname, mv], await _record(rig, wname, mv, d, d + AFTER))
			# (chat 15) the game's own sword: 3 clicks in a row and the heavy blow, at DwarfRig.attack_seconds' speed
			chain_slow = DwarfRig.UAL_SLOW
			var hits: Array = DwarfRig.ATTACKS.sword[0]
			var names: PackedStringArray = []
			var total := 0.0
			for h: String in hits:
				names.append(String(DwarfRig.ANIMS[h]).trim_prefix("o/"))
				total += DwarfOneSwing.clip_length(names[-1]) * chain_slow
			lib.add_animation(wname + "_GameCombo", await _record(rig, wname, "+".join(names), total, total + AFTER))
			var hv := DwarfRig.attack_seconds("sword", true, 0, 1.0)
			lib.add_animation(wname + "_GameHeavy", await _record(rig, wname, String(DwarfRig.ANIMS[DwarfRig.ATTACKS.sword[1]]).trim_prefix("o/"), hv, hv + AFTER))
			chain_slow = 1.0
			if "pack=1" in args:  # the pack's other moves, played as the game plays any clip
				for c: String in PACK_MOVES:
					var ln := rig.tree.get_animation(c).length if rig.tree.has_animation(c) else 1.0
					lib.add_animation("Pack_" + c.get_file(), await _record(rig, wname, "!" + c, ln, ln + AFTER))
			continue
		if video:
			var hits: Array = wdef[1]
			var total := 0.0
			for h: String in hits:
				total += DwarfOneSwing.clip_length(h)
			lib.add_animation(wname + "_Combo", await _record(rig, wname, "+".join(hits), total, total + AFTER))
			for n in hits.size():
				var d := DwarfOneSwing.clip_length(hits[n])
				lib.add_animation("%s_Hit%d" % [wname, n + 1], await _record(rig, wname, hits[n], d, d + AFTER))
			continue
		var spd: Dictionary = Combat.WEAPONS[wdef[1]]
		for mv: String in wdef[2]:
			for kind: String in ["light", "heavy"]:
				var dur: float = spd[kind + "_speed"]
				lib.add_animation("%s_%s_%s" % [wname, mv, kind], await _record(rig, wname, mv, dur, dur + AFTER))
	if "all=1" in args:
		shield_copy = await _record_all(model, rig, lib, tools)
	# the scene: the dwarf's skeleton + skin, and the weapons (their own nodes, moved every frame)
	var scene := Node3D.new()
	scene.name = "dwarf"
	var turn := Node3D.new()
	turn.name = "turn"
	scene.add_child(turn)
	var sk2 := Skeleton3D.new()
	sk2.name = "Skeleton3D"
	turn.add_child(sk2)
	for i in sk.get_bone_count():
		sk2.add_bone(sk.get_bone_name(i))
	for i in sk.get_bone_count():
		sk2.set_bone_parent(i, sk.get_bone_parent(i))
		sk2.set_bone_rest(i, sk.get_bone_rest(i))
	sk2.reset_bone_poses()
	for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", false, false):
		if not mi.visible or mi.skin == null:
			continue
		var m2 := MeshInstance3D.new()
		m2.name = mi.name
		m2.mesh = mi.mesh
		m2.skin = mi.skin
		if mi.material_override:
			m2.material_override = mi.material_override
		sk2.add_child(m2)
		m2.skeleton = NodePath("..")
	for mi: MeshInstance3D in sk2.get_children():
		_slim(mi.mesh)
	for wname: String in tools:
		var holder := Node3D.new()
		holder.name = wname
		scene.add_child(holder)
		holder.add_child(tools[wname])
	if shield_copy:
		var holder := Node3D.new()
		holder.name = "shield"
		scene.add_child(holder)
		holder.add_child(shield_copy)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	scene.add_child(player)
	player.add_animation_library("", lib)
	_own(scene, scene)
	root.add_child(scene)
	await process_frame
	var doc := GLTFDocument.new()
	doc.image_format = "JPEG"
	doc.lossy_quality = 0.8
	var st := GLTFState.new()
	var err := doc.append_from_scene(scene, st)
	err = err if err != OK else doc.write_to_filesystem(st, out)
	print("EXPORT ", out, " err=", err)
	quit()


## Plays `move` ("" = stand) for `dur` s and records `seconds` of it, game time (frame by frame, like the game).
## steps (chat 15): [[time (s), Callable], ...] called as the game would (a click, a held button), frame by frame.
func _record(rig: DwarfRig, wname: String, move: String, dur: float, seconds: float, steps: Array = []) -> Animation:
	var sk := rig.skeleton
	var R := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)  # (the page looks at his front from +Z)
	var anim := Animation.new()
	anim.length = seconds
	anim.loop_mode = Animation.LOOP_LINEAR
	var tracks := {}
	for i in sk.get_bone_count():
		var path := NodePath("turn/Skeleton3D:" + sk.get_bone_name(i))
		var tp := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(tp, path)
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, path)
		var ts := anim.add_track(Animation.TYPE_SCALE_3D)
		anim.track_set_path(ts, path)
		tracks[i] = [tp, tr, ts]
	var node_tracks := {}
	for node: String in ["turn", wname, "shield"]:
		var list := []
		for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			var k := anim.add_track(type)
			anim.track_set_path(k, NodePath(node))
			list.append(k)
		node_tracks[node] = list
	# ("A+B+C": each starts the moment the one before ends, at its own filmed length; one move: `dur`)
	var chain: PackedStringArray = move.split("+") if move != "" else PackedStringArray()
	var next_at := 0.0
	var ci := 0
	var most_wrist := 0.0
	var frames := int(seconds * 60.0)
	var clear := {head = INF, head_t = 0.0, body = INF, body_t = 0.0, through = 0, through_t = -1.0}
	var si := 0
	for f in frames:
		while si < steps.size() and float(f) / 60.0 >= float(steps[si][0]) - 1e-6:
			(steps[si][1] as Callable).call()
			si += 1
		if ci < chain.size() and float(f) / 60.0 >= next_at - 1e-6:
			var d := dur if chain.size() == 1 else DwarfOneSwing.clip_length(chain[ci]) * chain_slow
			if chain[ci].begins_with("!"):  # (a pack clip as it is, the whole body)
				rig.play_full(chain[ci].substr(1), d)
			else:
				rig.play_upper("o/" + chain[ci], d)
			next_at += d
			ci += 1
		rig.set_motion(0.0, true, false)
		await sk.skeleton_updated
		most_wrist = maxf(most_wrist, rig.fist.wrist_turn)
		if f % EVERY != 0:
			continue
		var t := float(f) / 60.0
		var at := {"turn": R * sk.global_transform}
		if rig.grip.get_child_count() > 0:  # (nothing in the right fist: no weapon track; the page hides it)
			at[wname] = R * rig.grip.global_transform
		if rig.shield_grip.get_child_count() > 0:
			at["shield"] = R * rig.shield_grip.global_transform
		for node: String in at:
			var tf: Transform3D = at[node]
			var k: Array = node_tracks[node]
			anim.position_track_insert_key(k[0], t, tf.origin)
			anim.rotation_track_insert_key(k[1], t, tf.basis.get_rotation_quaternion())
			anim.scale_track_insert_key(k[2], t, tf.basis.get_scale())
		if rig.shield_grip.get_child_count() > 0 and rig.grip.get_child_count() > 0:
			_clear_check(rig, t, clear)
		# (chat 15, owner: "the sword is outside of his hand, he catches it a second later"): the grip as the node
		# says, against the grip worked out from this frame's hand bone (a late node = the sword left behind)
		var hb := sk.find_bone("hand_r")
		if rig.grip.get_child_count() == 0:
			hb = -1
		var lag := 0.0
		if hb >= 0:
			var from_bone := sk.global_transform * sk.get_bone_global_pose(hb) * rig.right_hand.transform * rig.grip.transform
			lag = from_bone.origin.distance_to(rig.grip.global_transform.origin)
		if lag > clear.get("lag", 0.0):
			clear["lag"] = lag
			clear["lag_t"] = t
		for i in sk.get_bone_count():
			var tt: Array = tracks[i]
			# (every bone's place, every frame: the head and hair hang on helper bones off the root, chat 11)
			anim.position_track_insert_key(tt[0], t, sk.get_bone_pose_position(i))
			anim.rotation_track_insert_key(tt[1], t, sk.get_bone_pose_rotation(i))
			if f == 0:
				anim.scale_track_insert_key(tt[2], t, sk.get_bone_pose_scale(i))
	for k in range(anim.get_track_count() - 1, -1, -1):  # (tracks left empty, the shield's without one: dropped)
		if anim.track_get_key_count(k) == 0:
			anim.remove_track(k)
	print("RECORDED %s %s %.2f s  most wrist turn %.0f deg" % [wname, move, dur, most_wrist])
	print("  SWORD most behind his hand %.3f m (at %.2f s)" % [clear.get("lag", 0.0), clear.get("lag_t", 0.0)])
	if clear.head < INF:
		var ok: bool = clear.head > 0.0 and clear.body > 0.0 and clear.through == 0
		print("  SHIELD %s  head gap %.2f m (at %.2f s)  body gap %.2f m (at %.2f s)  sword through it %d frames (first %.2f s)" % [
			"OK" if ok else "BAD", clear.head, clear.head_t, clear.body, clear.body_t, clear.through, clear.through_t])
	return anim


const HEAD_R := 0.16  ## m: the dwarf's head and hair, a ball round the Head bone (raised HEAD_UP)
const HEAD_UP := 0.08
const BODY_R := 0.17  ## m: his chest and belly, balls round spine_03, spine_01 and the pelvis


## Chat 15 (owner: "the shield goes through his head, the sword through the shield"): measures, this frame, the
## shield's disc against his head, his body and the sword's blade line. The worst of each goes in `c`.
func _clear_check(rig: DwarfRig, t: float, c: Dictionary) -> void:
	var sk := rig.skeleton
	var disc := _box_of(rig.shield_grip)
	var sb: AABB = disc[0]
	var ax := _thin_axis(sb.size)
	var g := rig.shield_grip.global_transform
	var centre := g * sb.get_center()
	var normal := (g.basis * _axis(ax)).normalized()
	var r := 0.0
	for i in 3:
		if i != ax:
			r = maxf(r, sb.size[i] * 0.5)
	var half_thick := sb.size[ax] * 0.5
	var head := sk.global_transform * (sk.get_bone_global_pose(sk.find_bone("Head")).origin) + Vector3.UP * HEAD_UP
	var hg := _disc_dist(head, centre, normal, r) - half_thick - HEAD_R
	if hg < c.head:
		c.head = hg
		c.head_t = t
	for b: String in ["spine_03", "spine_01", "pelvis"]:
		var p := sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b)).origin
		var bg := _disc_dist(p, centre, normal, r) - half_thick - BODY_R
		if bg < c.body:
			c.body = bg
			c.body_t = t
	# the sword: its long line through the grip, end to end
	var wb: AABB = _box_of(rig.grip)[0]
	var long := 0
	for i in 3:
		if wb.size[i] > wb.size[long]:
			long = i
	var wg := rig.grip.global_transform
	var a := wg * (wb.get_center() - _axis(long) * wb.size[long] * 0.5)
	var b2 := wg * (wb.get_center() + _axis(long) * wb.size[long] * 0.5)
	var sa := (a - centre).dot(normal)
	var sbd := (b2 - centre).dot(normal)
	if signf(sa) != signf(sbd):
		var x := a.lerp(b2, sa / (sa - sbd))
		if (x - centre).length() < r:
			c.through += 1
			if c.through_t < 0.0:
				c.through_t = t


## The meshes under the last child of `n`, as one box in `n`'s own space.
static func _box_of(n: Node3D) -> Array:
	var top := n.get_child(n.get_child_count() - 1) as Node3D
	var list: Array = top.find_children("*", "MeshInstance3D", true, false)
	if top is MeshInstance3D:
		list.append(top)
	var inv := n.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in list:
		var bb: AABB = (inv * mi.global_transform) * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	return [box]


static func _thin_axis(s: Vector3) -> int:
	return 0 if s.x <= s.y and s.x <= s.z else (1 if s.y <= s.z else 2)


static func _axis(i: int) -> Vector3:
	return [Vector3.RIGHT, Vector3.UP, Vector3.BACK][i]


## How far point p is from a flat disc (centre, normal, radius).
static func _disc_dist(p: Vector3, centre: Vector3, normal: Vector3, r: float) -> float:
	var v := p - centre
	var h := v.dot(normal)
	var flat := v - normal * h
	var out := maxf(flat.length() - r, 0.0)
	return sqrt(h * h + out * out)


## Smaller file for the page: no bump pictures, colour pictures half size (this tool's own copy: the game is untouched).
func _slim(mesh: Mesh) -> void:
	if mesh == null:
		return
	for i in mesh.get_surface_count():
		var mat := mesh.surface_get_material(i) as StandardMaterial3D
		if mat == null:
			continue
		mat = mat.duplicate() as StandardMaterial3D
		mat.normal_enabled = false
		mat.normal_texture = null
		if mat.albedo_texture:
			var img := mat.albedo_texture.get_image()
			if img.is_compressed():
				img.decompress()
			img.resize(maxi(img.get_width() / 2, 8), maxi(img.get_height() / 2, 8))
			mat.albedo_texture = ImageTexture.create_from_image(img)
		mesh.surface_set_material(i, mat)


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


## all=1: records every clip into `lib` (holders into `tools`); returns the shield's copy.
func _record_all(model: DwarfModel, rig: DwarfRig, lib: AnimationLibrary, tools: Dictionary) -> Node3D:
	var shield_copy: Node3D = null
	for w: Array in ALL:
		var holder: String = w[0]
		model.set_shield("shield_copper" if w[2] else "")
		model.set_held(w[1])
		for i in 30:
			rig.set_motion(0.0, true, false)
			await process_frame
		tools[holder] = (rig.grip.get_child(rig.grip.get_child_count() - 1) as Node3D).duplicate()
		if w[2] and shield_copy == null:
			shield_copy = (rig.shield_grip.get_child(rig.shield_grip.get_child_count() - 1) as Node3D).duplicate()
		var weapon := Combat.weapon_of(w[1])
		var wd: Dictionary = Combat.WEAPONS[weapon]
		if weapon == "crossbow":  # aim (right click held), shoot, reload
			var bow := [[0.0, func() -> void: model.set_pose(false, true, false)], [0.8, func() -> void: model.react("shoot")],
				[1.3, func() -> void: model.set_pose(false, false, false)], [1.4, func() -> void: model.react("reload", 1.2)]]
			lib.add_animation(holder + "_Shoot", await _record(rig, holder, "", 0.0, 3.0, bow))
			continue
		var steps := []
		var t := 0.0
		for step in (wd.combo as Array).size():
			var d := DwarfRig.attack_seconds(weapon, false, step, wd.light_speed)
			steps.append([t, model.attack.bind(d, false, step)])
			t += d
		lib.add_animation(holder + "_Combo", await _record(rig, holder, "", 0.0, t + AFTER, steps))
		var hold := func(on: bool, sh: bool) -> void: model.set_pose(on, false, sh)
		if DwarfFight.weapon_has_heavy(weapon):  # (chat 16, F519: only great weapons have a heavy attack)
			var h := DwarfRig.attack_seconds(weapon, true, 0, wd.heavy_speed)
			lib.add_animation(holder + "_Heavy", await _record(rig, holder, "", 0.0, h + AFTER, [[0.0, model.attack.bind(h, true, 0)]]))
		elif w[2]:  # F520: block (right click held), then left click = the shield bash, as DwarfFight._shield_bash
			var sb: float = Combat.WEAPONS.shield.light_speed
			lib.add_animation(holder + "_Bash", await _record(rig, holder, "", 0.0, 0.5 + sb + 0.9, [[0.0, hold.bind(true, true)],
				[0.5, model.attack.bind(sb, false, 0, "shield")], [0.5 + sb + 0.6, hold.bind(false, true)]]))
		if holder == "GreatMaul" and "bow=1" in OS.get_cmdline_user_args():
			# chat 17: the crossbow's KayKit moves, each alone at its own speed, then aim, shoot, reload in a row
			model.set_held("crossbow_copper")
			for i in 20:
				rig.set_motion(0.0, true, false)
				await process_frame
			var ln := {}
			for mv: String in BOW_TRY:
				ln[mv] = rig.tree.get_animation("c/" + mv).length
				lib.add_animation("Crossbow_Try" + mv, await _record(rig, "Crossbow", "", 0.0, ln[mv] + AFTER,
					[[0.0, rig.play_upper.bind("c/" + mv, ln[mv])]]))
			var a: float = ln.Aim
			lib.add_animation("Crossbow_TryAll", await _record(rig, "Crossbow", "", 0.0, a + ln.Shoot + ln.Reload + AFTER,
				[[0.0, rig.play_upper.bind("c/Aim", a)], [a, rig.play_upper.bind("c/Shoot", ln.Shoot)],
				[a + ln.Shoot, rig.play_upper.bind("c/Reload", ln.Reload)]]))
			model.set_held(w[1])
		if holder != "Sword":
			continue
		# the sword's guard (no shield), the shield's guard, stunned, dying, the roll
		lib.add_animation("Sword_GuardShield", await _record(rig, holder, "", 0.0, 2.2, [[0.0, hold.bind(true, true)], [1.6, hold.bind(false, true)]]))
		lib.add_animation("Sword_Stunned", await _record(rig, holder, "", 0.0, DwarfFight.STUN_TIME + AFTER, [[0.0, model.react.bind("stunned", DwarfFight.STUN_TIME)]]))
		lib.add_animation("Sword_Death", await _record(rig, holder, "", 0.0, 1.6, [[0.0, model.react.bind("die", -1.0)]]))
		lib.add_animation("Sword_Roll", await _record(rig, holder, "", 0.0, 1.2, [[0.0, rig.play_full.bind("roll", DwarfRig.ROLL_TIME)]]))
		model.set_shield("")
		for i in 20:
			rig.set_motion(0.0, true, false)
			await process_frame
		lib.add_animation("Sword_Guard", await _record(rig, holder, "", 0.0, 2.2, [[0.0, hold.bind(true, false)], [1.6, hold.bind(false, false)]]))
		model.set_shield("shield_copper")  # (the shield back on for the next weapons)
	return shield_copy