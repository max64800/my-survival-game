extends SceneTree
## Pictures of the dwarf's swing trail (WeaponTrail) at a few moments of one swing (Claude, Nov 18).
##   godot --audio-driver Dummy --path . --script res://tools/model_check/swing_shot.gd -- <item> <out_prefix> [dig]
var prefix := ""
var frames := 0
var shots := [8, 14, 20, 30]
var model: DwarfModel


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var item: String = a[0] if a.size() > 0 else "sword_stone"
	prefix = a[1] if a.size() > 1 else "user://swing"
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.13, 0.11)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.5)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	w.add_child(sun)
	model = DwarfModel.new()
	w.add_child(model)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.look_at_from_position(Vector3(1.3, 1.3, -1.5), Vector3(0, 0.9, 0))
	await process_frame
	await process_frame
	model.set_held(item)
	await process_frame
	if a.has("dig"):
		model.swing(0.7)
	else:
		model.attack(0.6, true, 0)


func _process(_d: float) -> bool:
	frames += 1
	for sh in shots:
		if frames == sh + 4:
			var trails := root.get_children().filter(func(c: Node) -> bool: return c is WeaponTrail)
			print("SWING frame %d: %d trail(s), %s" % [sh, trails.size(), str(trails.map(func(t: WeaponTrail) -> int: return t._samples.size()))])
			root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, sh])
	return frames > shots.back() + 6
