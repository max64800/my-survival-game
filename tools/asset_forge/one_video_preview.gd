extends SceneTree
## Key-pose pictures of the owner's filmed sword / mace combos on the dwarf (F389 chat 13: DwarfOneSwing's video clips,
## held still one at a time, exactly as DwarfFist lays the weapon and the shield), from the front and from behind.
##   godot --audio-driver Dummy --path . --script res://tools/asset_forge/one_video_preview.gd -- claude=one_video_preview
##     out=<folder> item=sword_copper shots=SwordHit1@0.00,SwordHit1@1.07,...   (clip @ seconds into the clip)
## Pictures: <out>/<clip>_<seconds>_front.png and _back.png.
## By the dwarf-animations Claude, chat 13, Nov 20, 2026.
var out := "user://one_video"
var item := "sword_copper"
var shots: Array = []  ## [clip, seconds]
var edge_turn := 0.0  ## edgeturn=<deg>: the blade turned round the handle (to show the owner choices)
var pole := Vector2(0.7, -0.7)  ## pole=x:y: where the shield arm's elbow points
var model: DwarfModel
var cam: Camera3D
var frames := 0
const SPOTS := {"front": Vector3(0.0, 0.9, -2.7), "back": Vector3(0.0, 1.05, 2.7)}  ## (the front picture hides the shield: his arms show)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="): out = a.substr(4)
		if a.begins_with("item="): item = a.substr(5)
		if a.begins_with("edgeturn="): edge_turn = float(a.substr(9))
		if a.begins_with("pole="): pole = Vector2(float(a.substr(5).split(":")[0]), float(a.substr(5).split(":")[1]))
		if a.begins_with("shots="):
			for s: String in a.substr(6).split(","):
				var p := s.split("@")
				shots.append([p[0], float(p[1])])
	DirAccess.make_dir_recursive_absolute(out)
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
	root.size = Vector2i(520, 720)
	await process_frame
	await process_frame
	model.set_held(item)
	model.set_shield("shield_copper")


## The share of the swing (0..1) that plays `sec` seconds into the clip (the clip's strike lands at HIT_AT).
func _share(clip: String, sec: float) -> float:
	var length := DwarfOneSwing.clip_length(clip)
	var hit := float(DwarfOneSwing._clips[clip][2])
	if sec <= hit:
		return DwarfOneSwing.HIT_AT * sec / hit
	return DwarfOneSwing.HIT_AT + (1.0 - DwarfOneSwing.HIT_AT) * (sec - hit) / maxf(length - hit, 0.01)


func _process(_d: float) -> bool:
	frames += 1
	if model == null or model.dwarf_rig == null:
		return frames > 200
	var rig := model.dwarf_rig
	rig.set_motion(0.0, true, false)
	# each shot: set the pose, let it settle 4 frames, then a front and a back picture (2 frames each)
	var per := 8
	var i := (frames - 30) / per
	var k := (frames - 30) % per
	if frames < 30:
		return false
	if i >= shots.size():
		return true
	var s: Array = shots[i]
	if k == 0:
		var pose := DwarfOneSwing.swing(s[0], _share(s[0], s[1]))
		if edge_turn != 0.0:
			pose.edge = (pose.edge as Vector3).rotated((pose.handle as Vector3).normalized(), deg_to_rad(edge_turn))
		rig.one_fixed = pose
		rig.fist.guard_pole = pole
		cam.look_at_from_position(SPOTS.front, Vector3(0, 0.75, 0))
		_show_shield(rig, false)
	elif k == 3:  # (how the weapon really points against the move's handle direction, and the right fist's place)
		var skb := rig.skeleton.global_transform.basis
		var want := (skb * (rig.one_fixed.handle as Vector3)).normalized()
		var tool := rig.grip.get_child(rig.grip.get_child_count() - 1) as Node3D
		var got := tool.global_basis.y.normalized()
		print("guard miss %.2f arm" % rig.fist.guard_miss)
		print("%s @%.2f  handle wanted %s got %s (%d deg apart)  fist %s" % [s[0], s[1], want, got, roundi(rad_to_deg(want.angle_to(got))),
			rig.fist.fist_center - model.global_position])
	elif k == 4 or k == 7:
		var view := "front" if k == 4 else "back"
		root.get_viewport().get_texture().get_image().save_png("%s/%s_%.2f_%s.png" % [out, s[0], s[1], view])
		if k == 4:
			cam.look_at_from_position(SPOTS.back, Vector3(0, 0.75, 0))
			_show_shield(rig, true)
	return false


## Hides only the shield's look (its holder keeps working, so the arm still holds the guard).
func _show_shield(rig: DwarfRig, on: bool) -> void:
	for m: Node in rig.shield_grip.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).visible = on
