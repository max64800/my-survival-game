extends SceneTree
## Records the game dwarf swinging the great axe (F389: DwarfGreatSwing + DwarfFist, exactly as the game plays it,
## frame by frame) into one .glb for the "Great Axe Swings" 3D page: the dwarf's shaped bones and the axe.
## Clips: Stance, Chop, Sweep, Slam (each swing: the light swing's 1.1 s, then back to the stance).
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/great_swing_export.gd
##     -- <out.glb> claude=great_swing_export
## By the dwarf-animations Claude, chat 8, Nov 20, 2026.
const SWING := 1.1  ## s (Combat.WEAPONS.axe_2h.light_speed)
const AFTER := 0.5  ## s recorded after the swing (easing back to the stance)
const EVERY := 3  ## record every 3rd frame (60 fps game -> 20 fps clip; the page blends between)


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var model := DwarfModel.new()
	root.add_child(model)
	for i in 5:
		await process_frame
	model.set_held("axe_2h_copper")
	var rig := model.dwarf_rig
	var sk := rig.skeleton
	for i in 60:
		rig.set_motion(0.0, true, false)
		await process_frame
	var tool: Node3D = rig.grip.get_child(rig.grip.get_child_count() - 1)
	var lib := AnimationLibrary.new()
	lib.add_animation("Stance", await _record(rig, "", 1.0))
	for mv in ["Chop", "Sweep", "Slam"]:
		lib.add_animation(mv, await _record(rig, mv, SWING + AFTER))
		print("RECORDED ", mv)
	# the scene: the dwarf's skeleton + skin, and the axe (its own node, moved every frame)
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
	var axe := Node3D.new()
	axe.name = "axe"
	scene.add_child(axe)
	var t2 := tool.duplicate() as Node3D
	axe.add_child(t2)
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


## Plays `move` ("" = stand) and records `seconds` of it, game time (frame by frame, like the game).
func _record(rig: DwarfRig, move: String, seconds: float) -> Animation:
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
	var turn_tracks := []
	var axe_tracks := []
	for node in ["turn", "axe"]:
		var list := []
		for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			var k := anim.add_track(type)
			anim.track_set_path(k, NodePath(node))
			list.append(k)
		if node == "turn":
			turn_tracks = list
		else:
			axe_tracks = list
	if move != "":
		rig.play_upper("g/" + move, SWING)
	var frames := int(seconds * 60.0)
	var pelvis := sk.find_bone("pelvis")
	for f in frames:
		rig.set_motion(0.0, true, false)
		await sk.skeleton_updated
		if f % EVERY != 0:
			continue
		var t := float(f) / 60.0
		for x: Array in [[turn_tracks, R * sk.global_transform], [axe_tracks, R * rig.grip.global_transform]]:
			var tf: Transform3D = x[1]
			var k: Array = x[0]
			anim.position_track_insert_key(k[0], t, tf.origin)
			anim.rotation_track_insert_key(k[1], t, tf.basis.get_rotation_quaternion())
			anim.scale_track_insert_key(k[2], t, tf.basis.get_scale())
		for i in sk.get_bone_count():
			var tt: Array = tracks[i]
			if f == 0 or i == pelvis:  # (sizes and offsets stay put: only the hips move; keeps the file small)
				anim.position_track_insert_key(tt[0], t, sk.get_bone_pose_position(i))
			anim.rotation_track_insert_key(tt[1], t, sk.get_bone_pose_rotation(i))
			if f == 0:
				anim.scale_track_insert_key(tt[2], t, sk.get_bone_pose_scale(i))
	return anim


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
