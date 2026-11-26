extends SceneTree
## Records the game dwarf (hand-built body, shaped skeleton) playing its animations and writes it all to one .glb that a
## 3D page can play: the body, the skeleton and the recorded clips (by Claude 3, Nov 16, 2026).
##
##   godot --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_anim_export.gd -- <out.glb> [wear=<id>,<id>...]
##
## wear: what he wears while recorded, e.g. wear=armor_head_hide,armor_chest_hide,armor_feet_hide (DwarfRig.set_wear).
## tools=1: a tool in his hand in every clip, exactly where the game puts it (owner, Nov 17): the sword for the sword
## swing, the axe for chopping, the mace and spear for theirs, the pickaxe in all the others (carried at the hip
## while running, like in the game). The tool sits in the rig's own grip (DwarfRig.grip / GRIPS), like in the game.
## hands=1: the close-up hands page (Nov 19, the fists: DwarfFist): every tool and weapon standing still, walking,
## running (the shoulder carry) and its swing, twice: "Before_<clip>" = the old open-hand grip (DwarfFist.use_fist off),
## "After_<clip>" = the fist round the handle. hand_tool=<item or page name> records just that one (e.g. hand_tool=Spear).
##
## The game shapes the skeleton every frame (DwarfProportions), so the pack's animation files alone would show a human
## skeleton under a dwarf body; recording the real, shaped bones frame by frame gives exactly what the game shows.

## clip name -> [how long (s), what the dwarf does]
const CLIPS := [
	["Standing", 2.4, "idle"], ["Walk", 1.4, "walk"], ["Run", 1.0, "jog"], ["Sprint", 0.8, "sprint"],
	["Mining", 1.2, "dig"], ["Sword combo", 1.3, "attack"], ["Chopping", 1.4, "chop"], ["Roll", 1.0, "roll"],
	["Jump", 1.0, "air"], ["Mace combo", 1.6, "mace"], ["Spear", 0.7, "spear"], ["Shield block", 1.6, "shield"],
]
const FPS := 30.0
const TOOL_FOR := {"Sword combo": "sword_copper", "Chopping": "axe_copper", "Mace combo": "mace_copper", "Spear": "spear_copper",
	"Shield block": "sword_copper"}  ## (every other clip: the pickaxe)
const SHIELD_FOR := {"Shield block": "shield_copper"}  ## on his left arm (DwarfRig.shield_grip), as in the game
const TOOL_ITEMS := ["pickaxe_copper", "sword_copper", "axe_copper", "mace_copper", "spear_copper", "shield_copper"]
## hands=1: [page name, item, its swing ("" = none), shield on the left arm]
const HAND_TOOLS := [
	["Pickaxe", "pickaxe_copper", "dig", ""], ["Axe", "axe_copper", "chop", ""], ["Sword", "sword_copper", "attack", ""],
	["Mace", "mace_copper", "mace", ""], ["Great axe", "axe_2h_copper", "axe_2h", ""],
	["Great maul", "mace_2h_copper", "mace_2h", ""], ["Spear", "spear_copper", "spear", ""],
	["Build hammer", "build_hammer", "", ""], ["Mason's shovel", "masons_shovel", "", ""],
	["Sword + shield", "sword_copper", "shield", "shield_copper"],
]
var _hand: Node3D            ## the game's tool holder in the fist (DwarfRig.grip)
var _tools := {}             ## item -> the tool model


func _look_of(item: String) -> String:  # (as DwarfModel.set_held)
	var kind := Items.kind(item)
	return Combat.weapon_of(item) if kind in ["weapon", "shield", "axe"] else kind


func _tool_look(item: String) -> Node3D:
	var t := ToolModels.build(_look_of(item), Items.color(item), 1, item)
	t.name = "tool_" + item
	return t


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	await process_frame
	var holder := Node3D.new()
	root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("look="):  # (F914: plate / pic3d / old copper helmet + chest)
			DwarfRig.armor_look = a.trim_prefix("look=")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("wear="):
			rig.set_wear(Array(a.substr(5).split(",")))
	var sk := rig.skeleton
	var hands := "hands=1" in OS.get_cmdline_user_args()
	# each clip: [name, seconds, what, item in the hand, shield on the left arm, fists on]
	var clips := []
	for c in CLIPS:
		clips.append([c[0], c[1], c[2], TOOL_FOR.get(c[0], "pickaxe_copper"), SHIELD_FOR.get(c[0], ""), true])
	for a in OS.get_cmdline_user_args():  # clips=Standing,Walk: just those (a smaller file)
		if a.begins_with("clips="):
			var keep := a.substr(6).split(",")
			clips = clips.filter(func(c): return c[0] in keep)
	if hands:
		clips.clear()
		var only := ""  # hand_tool=<item>: just that tool (the page loads one file per tool: all of them is ~60 MB)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("hand_tool="):
				only = a.substr(10)
		for v in ["Before", "After"]:
			for t in HAND_TOOLS:
				if only != "" and t[1] != only and t[0] != only:
					continue
				var moves := [["still", 1.2, "idle"], ["walk", 0.0, "walk"], ["run", 0.0, "jog"]]
				if t[2] != "":
					moves.append(["swing", {"dig": 1.2, "chop": 1.4, "attack": 1.3, "mace": 1.6, "mace_2h": 1.6, "shield": 1.6}.get(t[2], 1.0), t[2]])
				for mv in moves:
					clips.append(["%s_%s %s" % [v, t[0], mv[0]], mv[1], mv[2], t[1], t[3], v == "After"])
	if "tools=1" in OS.get_cmdline_user_args() or hands:
		_hand = rig.grip
		rig.carrying = true
		var all := clips.duplicate()
		if hands:  # (every tool in every file, hidden when not in use: the page puts one body under all the files' moves)
			for t in HAND_TOOLS:
				all.append(["", 0, "", t[1], t[3], true])
		for c in all:
			for item in [c[3], c[4]]:
				if item != "" and not _tools.has(item):
					_tools[item] = _tool_look(item)
	var lib := AnimationLibrary.new()
	for c in clips:
		DwarfFist.use_fist = c[5]
		if _hand:
			for h in [_hand, rig.shield_grip]:
				for ch in h.get_children():
					h.remove_child(ch)
			if c[4] != "":
				rig.shield_grip.add_child(_tools[c[4]])
			var item: String = c[3]
			_hand.add_child(_tools[item])
			rig.tool_look = _look_of(item)
			rig.snap_grip()
		var secs: float = c[1]
		if c[2] in ["walk", "jog", "sprint"] or (c[2] == "idle" and not hands):  # (the loops play slower now: record one whole loop so it joins up)
			var src: String = DwarfRig.ANIMS[c[2]]
			if rig.tree.has_animation(src):
				secs = rig.tree.get_animation(src).length / DwarfRig.LOOP_SPEED
		var anim := await _record(rig, c[0], secs, c[2])
		lib.add_animation(c[0], anim)
		print("RECORDED ", c[0], " ", anim.length, " s")
	# The export scene: the skeleton (same bones and rest) with the body on it, facing +Z like the other models.
	var scene := Node3D.new()
	scene.name = "dwarf"
	var turn := Node3D.new()
	turn.name = "turn"
	turn.transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * _skel_in_look(rig)
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
	for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", true, false):
		if not (mi.name.begins_with("body_") or mi.name.begins_with("armor_")) or not mi.visible:
			continue  # (the stand-in pack meshes, and the normal head while the hat-hair head is worn)
		var m2 := MeshInstance3D.new()
		m2.name = mi.name
		m2.mesh = mi.mesh
		m2.skin = mi.skin
		if mi.material_override:  # (the hat-hair head wears the normal head's pictures)
			var arr := mi.mesh as ArrayMesh
			if arr:
				var copy := arr.duplicate() as ArrayMesh
				copy.surface_set_material(0, mi.material_override)
				m2.mesh = copy
		sk2.add_child(m2)
		m2.skeleton = NodePath("..")
	for item in _tools:  # the tools, moved by their own recorded tracks (hidden at size 0 when not in use)
		sk2.add_child(_tool_look(item))
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	scene.add_child(player)
	player.add_animation_library("", lib)
	_own(scene, scene)
	root.add_child(scene)
	await process_frame
	var doc := GLTFDocument.new()
	doc.image_format = "JPEG"  # (round 2: the baked head pictures; PNG would make the 3D page ~4x bigger)
	doc.lossy_quality = 0.88
	var st := GLTFState.new()
	var err := doc.append_from_scene(scene, st)
	err = err if err != OK else doc.write_to_filesystem(st, out)
	print("EXPORT ", out, " err=", err)
	quit()


func _skel_in_look(rig: DwarfRig) -> Transform3D:
	var t := Transform3D()
	var n: Node3D = rig.skeleton
	while n != null and n != rig:
		t = n.transform * t
		n = n.get_parent_node_3d()
	return rig.transform * t


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


## What the game calls every frame (Dwarf -> DwarfModel.set_motion): speed, on the floor, rolling. Called every frame
## like the game does (once was not enough: the roll and the jump never played, and the tool never swung into its
## running carry). t = seconds into the recording (< 0 while settling in).
func _drive(rig: DwarfRig, what: String, t: float) -> void:
	match what:
		"walk":
			rig.set_motion(1.6, true, false)
		"jog":
			rig.set_motion(4.0, true, false)
		"sprint":
			rig.set_motion(6.5, true, false)
		"air":  # standing, then a jump: off the ground for 0.65 s, then the landing
			rig.set_motion(0.0, t < 0.0 or t > 0.65, false)
		"roll":  # jogging, then a dodge roll as long as the game's (Combat.DODGE_TIME)
			rig.set_motion(3.0, true, t >= 0.0 and t < Combat.DODGE_TIME)
		_:
			rig.set_motion(0.0, true, false)


func _record(rig: DwarfRig, clip: String, seconds: float, what: String) -> Animation:
	var sk := rig.skeleton
	match what:
		"shield":
			rig.set_hold("shield")  # (as DwarfModel.set_pose with a shield: the shield guard, held)
		"dig", "chop":
			rig.play_upper(what, seconds)
	for f in 20:  # settle into it
		_drive(rig, what, -1.0)
		await process_frame
	var combo := what in ["attack", "mace", "mace_2h"]  # sword and mace: the two hits of the combo back to back (DwarfFight._combo_step)
	var weapon: String = {"attack": "sword"}.get(what, what)
	if what in ["attack", "mace", "spear", "mace_2h", "axe_2h"]:  # (as DwarfModel.attack: the weapon's own move, DwarfRig.ATTACKS)
		rig.attack(seconds / 2.0 if combo else seconds, false, weapon, 0)
	elif what == "shield":
		rig.set_hold("")  # lower it, then raise it again while recording
		for f in 20:
			await process_frame
		rig.set_hold("shield")
	elif what in ["dig", "chop"]:
		rig.play_upper(what, seconds)
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
	var tool_tracks := {}
	for item in _tools:
		var path := NodePath("turn/Skeleton3D/tool_" + item)
		var tp := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(tp, path)
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, path)
		var ts := anim.add_track(Animation.TYPE_SCALE_3D)
		anim.track_set_path(ts, path)
		tool_tracks[item] = [tp, tr, ts]
	var calf := sk.find_bone("calf_l")
	print("CHECK ", clip, " knee pose ", sk.get_bone_pose_position(calf), " human rest ", sk.get_bone_rest(calf).origin, " shaped ", rig.proportions._pos.get(calf))
	var t := 0.0
	var start := Time.get_ticks_usec()
	while t <= seconds:
		_drive(rig, what, t)
		var lift := sk.global_basis.inverse() * (rig.global_basis * Vector3(0, rig._roll_lift, 0))
		if combo and t >= seconds / 2.0:
			combo = false
			rig.attack(seconds / 2.0, false, weapon, 1)  # the 2nd hit
		await sk.skeleton_updated  # (the final pose, after every modifier: hair swing, dwarf shaping)
		t = (Time.get_ticks_usec() - start) / 1000000.0
		if t > seconds:
			break
		for i in sk.get_bone_count():
			var tt: Array = tracks[i]
			var at := sk.get_bone_pose_position(i)
			if i == 0:  # (the mid-roll lift moves the whole body, not a bone: DwarfRig._lift_roll; put it on the root bone)
				at += lift
			anim.position_track_insert_key(tt[0], t, at)
			anim.rotation_track_insert_key(tt[1], t, sk.get_bone_pose_rotation(i))
			anim.scale_track_insert_key(tt[2], t, sk.get_bone_pose_scale(i))
		for item in tool_tracks:
			var tk: Array = tool_tracks[item]
			var tool: Node3D = _tools[item]
			if tool.is_inside_tree():  # the one in his hand: where it is, seen from the skeleton
				var rel := sk.global_transform.affine_inverse() * tool.global_transform
				var holder := tool.get_parent() as Node3D  # (from the bones as DwarfFist left them this frame)
				var socket := holder.get_parent() as Node3D
				var bone := "hand_r" if socket == rig.right_hand else ("hand_l" if socket == rig.left_hand else "")
				if bone != "":
					rel = sk.get_bone_global_pose(sk.find_bone(bone)) * socket.transform * holder.transform * tool.transform
				anim.position_track_insert_key(tk[0], t, rel.origin + lift)
				anim.rotation_track_insert_key(tk[1], t, rel.basis.get_rotation_quaternion())
				anim.scale_track_insert_key(tk[2], t, rel.basis.get_scale())
			else:
				anim.position_track_insert_key(tk[0], t, Vector3.ZERO)
				anim.rotation_track_insert_key(tk[1], t, Quaternion.IDENTITY)
				anim.scale_track_insert_key(tk[2], t, Vector3.ZERO)
	rig.set_hold("")
	return anim
