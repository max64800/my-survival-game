extends SceneTree
## Records the game dwarf moving around (standing, walking, running, a whole jump with take-off and landing) into one
## .glb for the "Dwarf Moves" 3D page: before the weight layer (DwarfWeight), after, and after + gripping feet.
## Like dwarf_anim_export.gd, it records the real shaped bones frame by frame, so the page shows exactly the game.
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_moves_export.gd -- <out.glb>

## clip name -> [seconds (0 = one whole loop of the game animation), game speed (m/s), what]
const CLIPS := [
	["Standing", 0.0, 0.0, "idle"], ["Walk", 0.0, 4.0, "jog"], ["Run", 0.0, 6.5, "sprint"],
	["Jump", 2.6, 0.0, "jump"], ["Running jump", 2.6, 4.0, "jump"],
]
const FPS := 30.0
## The whole jump, like the game's (Dwarf.JUMP_SPEED 5.5 m/s: about 1.5 m up, 1.1 s in the air): standing 0.35 s,
## in the air, then the landing. The body really goes up and down (the "turn" node moves), not just the bones.
const JUMP_UP := 0.35
const JUMP_DOWN := 1.47
const JUMP_HIGH := 1.5


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	await process_frame
	var holder := Node3D.new()
	root.add_child(holder)
	DwarfRig.use_weight = true  # (off in the game: owner kept the old moves)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	var sk := rig.skeleton
	var lib := AnimationLibrary.new()
	# Three versions, one after the other, each clip named "<version>_<clip>":
	# Before = as the game was (no weight), After = with the weight, Grip = with the weight and gripping feet.
	for v in [["Before", false, false], ["After", true, false], ["Grip", true, true]]:
		rig.weight.active = v[1]
		DwarfRig.grip_feet = v[2]
		rig.tree.set("parameters/move_speed/scale", DwarfRig.LOOP_SPEED)
		for c in CLIPS:
			var secs: float = c[1]
			if secs <= 0.0:
				secs = 3.6 if c[3] == "idle" else rig.tree.get_animation(DwarfRig.ANIMS[c[3]]).length / DwarfRig.loop_rate(c[2])
			var anim := await _record(rig, secs, c[2], c[3], _look_base(rig))
			lib.add_animation("%s_%s" % [v[0], c[0]], anim)
			print("RECORDED ", v[0], " ", c[0], " ", snappedf(anim.length, 0.01), " s")
	var scene := Node3D.new()
	scene.name = "dwarf"
	var turn := Node3D.new()
	turn.name = "turn"
	turn.transform = _look_base(rig)
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
	doc.image_format = "JPEG"
	doc.lossy_quality = 0.8
	var st := GLTFState.new()
	var err := doc.append_from_scene(scene, st)
	err = err if err != OK else doc.write_to_filesystem(st, out)
	print("EXPORT ", out, " err=", err)
	quit()


## What the dwarf is doing `t` seconds into a clip: [speed, on the floor?].
func _state(what: String, speed: float, t: float) -> Array:
	if what == "jump":
		return [speed, t < JUMP_UP or t > JUMP_DOWN]
	return [speed, true]


func _look_base(rig: DwarfRig) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * _skel_in_look(rig)


func _record(rig: DwarfRig, seconds: float, speed: float, what: String, base: Transform3D) -> Animation:
	var sk := rig.skeleton
	var s0 := _state(what, speed, 0.0)
	for f in 45:  # settle into it (the springs too)
		rig.set_motion(s0[0], s0[1], false)
		await process_frame
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
	var lift := anim.add_track(Animation.TYPE_POSITION_3D)  # (how high off the floor the whole dwarf is)
	anim.track_set_path(lift, NodePath("turn"))
	var t := 0.0
	var next_key := 0.0
	var start := Time.get_ticks_usec()
	while t <= seconds:
		var s := _state(what, speed, t)
		rig.set_motion(s[0], s[1], false)
		await sk.skeleton_updated
		t = (Time.get_ticks_usec() - start) / 1000000.0
		if t > seconds:
			break
		if t < next_key:
			continue
		next_key = t + 1.0 / FPS
		var up := 0.0
		if what == "jump" and t > JUMP_UP and t < JUMP_DOWN:
			var u := (t - JUMP_UP) / (JUMP_DOWN - JUMP_UP)
			up = JUMP_HIGH * 4.0 * u * (1.0 - u)
		anim.position_track_insert_key(lift, t, base.origin + Vector3(0, up, 0))
		for i in sk.get_bone_count():
			var tt: Array = tracks[i]
			anim.position_track_insert_key(tt[0], t, sk.get_bone_pose_position(i))
			anim.rotation_track_insert_key(tt[1], t, sk.get_bone_pose_rotation(i))
			anim.scale_track_insert_key(tt[2], t, sk.get_bone_pose_scale(i))
	return anim


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
