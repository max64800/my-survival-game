extends SceneTree
## Records the game dwarf (hand-built body, shaped skeleton) playing its animations and writes it all to one .glb that a
## 3D page can play: the body, the skeleton and the recorded clips (by Claude 3, Nov 16, 2026).
##
##   godot --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_anim_export.gd -- <out.glb>
##
## The game shapes the skeleton every frame (DwarfProportions), so the pack's animation files alone would show a human
## skeleton under a dwarf body; recording the real, shaped bones frame by frame gives exactly what the game shows.

## clip name -> [how long (s), what the dwarf does]
const CLIPS := [
	["Standing", 2.4, "idle"], ["Walk", 1.4, "walk"], ["Run", 1.0, "jog"], ["Sprint", 0.8, "sprint"],
	["Mining", 1.2, "dig"], ["Sword", 1.0, "attack"], ["Chopping", 1.4, "chop"], ["Roll", 1.0, "roll"], ["Jump", 1.0, "air"],
]
const FPS := 30.0


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	await process_frame
	var holder := Node3D.new()
	root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	var sk := rig.skeleton
	var lib := AnimationLibrary.new()
	for c in CLIPS:
		var secs: float = c[1]
		if c[2] in ["idle", "walk", "jog", "sprint"]:  # (the loops play slower now: record one whole loop so it joins up)
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
	for mi: MeshInstance3D in sk.find_children("body_*", "MeshInstance3D", true, false):
		var m2 := MeshInstance3D.new()
		m2.name = mi.name
		m2.mesh = mi.mesh
		m2.skin = mi.skin
		sk2.add_child(m2)
		m2.skeleton = NodePath("..")
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


func _record(rig: DwarfRig, clip: String, seconds: float, what: String) -> Animation:
	var sk := rig.skeleton
	match what:
		"idle":
			rig.set_motion(0.0, true, false)
		"walk":
			rig.set_motion(1.6, true, false)
		"jog":
			rig.set_motion(4.0, true, false)
		"sprint":
			rig.set_motion(6.5, true, false)
		"air":
			rig.set_motion(0.0, false, false)
		"roll":
			rig.set_motion(3.0, true, true)
		"attack":
			rig.set_motion(0.0, true, false)
			rig.attack(seconds, false)
		_:
			rig.set_motion(0.0, true, false)
			rig.play_upper(what, seconds)
	for f in 20:  # settle into it
		await process_frame
	if what == "attack":
		rig.attack(seconds, false)
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
	var calf := sk.find_bone("calf_l")
	print("CHECK ", clip, " knee pose ", sk.get_bone_pose_position(calf), " human rest ", sk.get_bone_rest(calf).origin, " shaped ", rig.proportions._pos.get(calf))
	var t := 0.0
	var start := Time.get_ticks_usec()
	while t <= seconds:
		await sk.skeleton_updated  # (the final pose, after every modifier: hair swing, dwarf shaping)
		t = (Time.get_ticks_usec() - start) / 1000000.0
		if t > seconds:
			break
		for i in sk.get_bone_count():
			var tt: Array = tracks[i]
			anim.position_track_insert_key(tt[0], t, sk.get_bone_pose_position(i))
			anim.rotation_track_insert_key(tt[1], t, sk.get_bone_pose_rotation(i))
			anim.scale_track_insert_key(tt[2], t, sk.get_bone_pose_scale(i))
	return anim
