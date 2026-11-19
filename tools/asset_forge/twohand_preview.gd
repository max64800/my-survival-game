extends SceneTree
## Preview pictures for F389 round 4 (owner's pick, Nov 19: great weapons on his back, both hands only in the swing).
## Shows (1) the great weapon hung across his back, hand empty; (2) the pack's two-handed tree chop at a few moments.
##   godot --audio-driver Dummy --path . --script res://tools/asset_forge/twohand_preview.gd -- claude=twohand_preview
##     item=axe_2h_copper out=<folder> [cam=front|side|back|three]
var out := "user://twohand"
var cam_name := "three"
var item := "axe_2h_copper"
var clip := "b/TreeChopping"
var model: DwarfModel
var cam: Camera3D
var frames := 0
var tool_node: Node3D
var back: Node3D


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="): out = a.substr(4)
		if a.begins_with("cam="): cam_name = a.substr(4)
		if a.begins_with("item="): item = a.substr(5)
		if a.begins_with("clip="): clip = a.substr(5)
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.13, 0.11)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.55)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 25, 0)
	w.add_child(sun)
	model = DwarfModel.new()
	w.add_child(model)
	cam = Camera3D.new()
	cam.fov = 40
	w.add_child(cam)
	_place_cam()
	await process_frame
	await process_frame
	model.set_held(item)


func _place_cam() -> void:
	# the dwarf faces -Z: front camera at -Z, his right side is +X
	var at := Vector3(0, 0.7, 0)
	var spots := {"front": Vector3(0.0, 0.95, -2.6), "side": Vector3(2.6, 0.95, 0.0), "back": Vector3(0.4, 1.0, 2.6),
		"three": Vector3(1.7, 1.1, -1.9)}
	cam.look_at_from_position(spots.get(cam_name, spots.three), at)


## Hangs the weapon across his back: head up behind his right shoulder, handle down to his left hip.
func _to_back() -> void:
	var rig := model.dwarf_rig
	tool_node = rig.grip.get_child(rig.grip.get_child_count() - 1)
	var sk := rig.skeleton
	back = BoneAttachment3D.new()
	(back as BoneAttachment3D).bone_name = "spine_03"
	sk.add_child(back)
	var holder := Node3D.new()
	back.add_child(holder)
	tool_node.reparent(holder, false)
	await process_frame
	# world placement: measured from the chest bone
	var chest := (back as Node3D).global_transform
	var up := Vector3.UP
	var behind := Vector3(0, 0, 1)  # his back
	var right := Vector3(1, 0, 0)
	var d := (up * 0.9 + right * 0.42).normalized()  # handle: left hip -> right shoulder
	var z := (behind - d * behind.dot(d)).normalized()  # the blade's flat side lies on his back
	var basis := Basis(d.cross(z), d, z)
	var origin := chest.origin + behind * 0.2 - right * 0.17 - up * 0.5
	holder.global_transform = Transform3D(basis, origin)
	holder.scale = Vector3.ONE / holder.global_transform.basis.get_scale() * 1.0


func _process(_d: float) -> bool:
	frames += 1
	if frames == 20:
		_to_back()
	if frames == 30:
		root.get_viewport().get_texture().get_image().save_png("%s/back_%s.png" % [out, cam_name])
		# into both hands and swing: the pack's two-handed tree chop
		tool_node.reparent(model.dwarf_rig.grip, false)
		model.dwarf_rig.play_upper(clip, 1.6)
	for f in [36, 44, 52, 60, 68]:
		if frames == f:
			root.get_viewport().get_texture().get_image().save_png("%s/chop_%s_%s_%d.png" % [out, clip.replace("/", ""), cam_name, f])
	return frames > 72
