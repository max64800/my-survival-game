extends SceneTree
## F389, Nov 20 (owner: "stop inventing poses in code, I'll pose him by hand in Blender"): records the game dwarf, with
## the great axe, into a .glb + .json for tools/blender_poses/make_pose_file.py, which builds the owner's pose file.
## Poses recorded (exactly as the game makes them, DwarfGreatSwing + DwarfFist): "ref" = the ready stance, then the
## chop's key poses from chat 8's numbers as a start (ready, wind-up top, middle, hit, recovery).
## The .glb holds the dwarf (shaped bones + skin) and the axe, with one clip "Keys": pose i at i seconds (0 = ref).
## The .json holds, per pose, every bone's skeleton-space pose (the game's numbers), the axe and the fists.
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/great_pose_blender_export.gd
##     -- <out.glb> <out.json> claude=great_pose_export
## By the dwarf-animations Claude, chat 9, Nov 20, 2026.
const KEYS := [["ready", 0.0], ["windup", 0.27], ["middle", 0.36], ["hit", 0.40], ["recovery", 0.75]]
const SETTLE := 40  ## frames each pose is held before it's recorded (the hips and the keep-out guard settle)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_glb: String = args[0]
	var out_json: String = args[1]
	var model := DwarfModel.new()
	root.add_child(model)
	for i in 5:
		await process_frame
	model.set_held("axe_2h_copper")
	var rig := model.dwarf_rig
	var sk := rig.skeleton
	var fist: DwarfFist = rig.fist
	var tool: Node3D = rig.grip.get_child(rig.grip.get_child_count() - 1)
	var R := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)  # (like great_swing_export: his front faces +Z)
	var poses: Array = [["ref", DwarfGreatSwing.STANCE.duplicate()]]
	for k: Array in KEYS:
		poses.append([k[0], DwarfGreatSwing.pose("Chop", float(k[1]), DwarfGreatSwing.STANCE)])
	var anim := Animation.new()
	anim.length = float(poses.size() - 1)
	var tracks := {}
	for i in sk.get_bone_count():
		var path := NodePath("turn/Skeleton3D:" + sk.get_bone_name(i))
		var list: Array = []
		for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			var tr := anim.add_track(type)
			anim.track_set_path(tr, path)
			list.append(tr)
		tracks[i] = list
	var node_tracks := {}
	for node in ["turn", "axe"]:
		var list: Array = []
		for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			var tr := anim.add_track(type)
			anim.track_set_path(tr, NodePath(node))
			list.append(tr)
		node_tracks[node] = list
	# (his facing, in the recording's space: the reader turns the axe Blender shows into his own frame with it)
	var data := {bones = [], parents = [], poses = [], rig_basis = _tf(Transform3D(R.basis * rig.global_basis.orthonormalized(),
		Vector3.ZERO))}
	for i in sk.get_bone_count():
		data.bones.append(sk.get_bone_name(i))
		data.parents.append(sk.get_bone_parent(i))
	for pi in poses.size():
		rig.great_fixed = poses[pi][1]
		for f in SETTLE:
			rig.set_motion(0.0, true, false)
			await sk.skeleton_updated
		var t := float(pi)
		var sk_x := R * sk.global_transform
		var axe_x := R * rig.grip.global_transform
		for x: Array in [["turn", sk_x], ["axe", axe_x]]:
			var tf: Transform3D = x[1]
			var k: Array = node_tracks[x[0]]
			anim.position_track_insert_key(k[0], t, tf.origin)
			anim.rotation_track_insert_key(k[1], t, tf.basis.get_rotation_quaternion())
			anim.scale_track_insert_key(k[2], t, tf.basis.get_scale())
		var globals: Array = []
		var locals: Array = []
		for i in sk.get_bone_count():
			var tt: Array = tracks[i]
			anim.position_track_insert_key(tt[0], t, sk.get_bone_pose_position(i))
			anim.rotation_track_insert_key(tt[1], t, sk.get_bone_pose_rotation(i))
			anim.scale_track_insert_key(tt[2], t, sk.get_bone_pose_scale(i))
			globals.append(_tf(sk.get_bone_global_pose(i)))
			var q := sk.get_bone_pose_rotation(i)
			locals.append([q.x, q.y, q.z, q.w])
		var dir := (fist.fist_center - fist.left_center).normalized()
		data.poses.append({name = poses[pi][0], time = t, sk = _tf(sk_x), axe = _tf(axe_x), globals = globals,
			locals = locals, left = _v(R * fist.left_center), right = _v(R * fist.fist_center), dir = _v(R.basis * dir),
			end = _v(R * (fist.left_center - dir * (fist.fist_half + DwarfFist.STUB))), gap = fist.left_gap,
			miss = [fist.left_miss, fist.right_miss], pose = var_to_str(poses[pi][1])})
		print("POSE ", poses[pi][0], " gap=", snappedf(fist.left_gap, 0.001), " miss=", snappedf(fist.left_miss, 0.001),
			"/", snappedf(fist.right_miss, 0.001))
	rig.great_fixed = {}
	var f := FileAccess.open(out_json, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	# the scene: the dwarf's skeleton + skin, and the axe
	var lib := AnimationLibrary.new()
	lib.add_animation("Keys", anim)
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
	var st := GLTFState.new()
	var err := doc.append_from_scene(scene, st)
	err = err if err != OK else doc.write_to_filesystem(st, out_glb)
	print("EXPORT ", out_glb, " err=", err)
	quit()


static func _tf(x: Transform3D) -> Array:
	return [x.basis.x.x, x.basis.x.y, x.basis.x.z, x.basis.y.x, x.basis.y.y, x.basis.y.z, x.basis.z.x, x.basis.z.y,
		x.basis.z.z, x.origin.x, x.origin.y, x.origin.z]


static func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)
