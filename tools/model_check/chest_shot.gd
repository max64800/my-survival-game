extends SceneTree
## Pictures of a chest's lid swinging open (ChestOpen, owner F345) at a few moments (Claude, Nov 18).
##   godot --audio-driver Dummy --path . --script res://tools/model_check/chest_shot.gd -- <out_prefix>
var prefix := ""
var frames := 0
var shots := [1, 6, 14, 40]
var kind := "chest_small"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	prefix = a[0] if a.size() > 0 else "user://chest"
	kind = a[1] if a.size() > 1 else kind
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.1, 0.08, 0.07)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.35, 0.33, 0.3)
	env.environment.glow_enabled = true
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.6
	w.add_child(sun)
	var body := StaticBody3D.new()
	w.add_child(body)
	var model := Look.forged("stations", kind)
	model.rotation.y = PI
	body.add_child(model)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.look_at_from_position(Vector3(1.8, 1.5, -2.2), Vector3(0, 0.5, 0))
	await process_frame
	ChestOpen.open(body)


func _process(_d: float) -> bool:
	frames += 1
	for sh in shots:
		if frames == sh:
			root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, sh])
	return frames > shots.back() + 2
