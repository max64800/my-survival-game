extends SceneTree
## Pictures of the crossbow moves (chat 18): each clip at a few moments, from the side and the three-quarter view.
##   godot --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/crossbow_preview.gd -- claude=crossbow_preview
##     out=<folder> clips=c/Aim,c/Reload1H shots=0,0.5,1 [cam=side|three|front]
## A clip name without "c/" is a normal clip (e.g. Pistol_Aim_Neutral). Held clips (Aim) are pictured held still.
var out := "user://crossbow"
var cam_name := "three"
var clips: PackedStringArray = ["c/Aim"]
var shots: Array = [0.0, 0.5, 1.0]
var model: DwarfModel
var frames := 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="): out = a.substr(4)
		if a.begins_with("cam="): cam_name = a.substr(4)
		if a.begins_with("clips="): clips = a.substr(6).split(",")
		if a.begins_with("shots="): shots = Array(a.substr(6).split(",")).map(func(s): return float(s))
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
	var cam := Camera3D.new()
	cam.fov = 40
	w.add_child(cam)
	var spots := {"front": Vector3(0.0, 1.0, -3.0), "side": Vector3(3.0, 1.0, 0.0),
		"three": Vector3(1.9, 1.2, -2.2), "back": Vector3(0.4, 1.1, 3.0), "top": Vector3(0.0, 3.6, -0.01)}
	cam.look_at_from_position(spots.get(cam_name, spots.three), Vector3(0, 0.75, 0))
	await process_frame
	await process_frame
	model.set_held("crossbow_copper")

var _clip := -1
var _start := 0
var _len := 1.0


func _process(_d: float) -> bool:
	frames += 1
	if model == null or model.dwarf_rig == null:
		return frames > 300
	var rig := model.dwarf_rig
	rig.set_motion(0.0, true, false)
	if frames < 20:
		return false
	if _clip < 0 or frames > _start + int(_len * 60.0) + 10:
		_clip += 1
		if _clip >= clips.size():
			return true
		_len = rig.tree.get_animation(clips[_clip]).length
		_start = frames
		rig.play_upper(clips[_clip], _len)
		return false
	for s: float in shots:
		if frames == _start + 3 + int(s * _len * 60.0):
			var nm := clips[_clip].replace("/", "_")
			root.get_viewport().get_texture().get_image().save_png("%s/%s_%d_%s.png" % [out, nm, roundi(s * 100), cam_name])
	return false
