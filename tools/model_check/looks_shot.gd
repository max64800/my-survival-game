extends SceneTree
## A row of creatures: the 4 looks of the Rock Snail, Rock Beetle and Cave Bat, and an Ember-crested (crystal)
## beetle with its crystals (Claude, Nov 19: owner wants all 4 looks in every cave).
##   godot --audio-driver Dummy --path . --script res://tools/model_check/looks_shot.gd -- <out.png>
var out := "user://looks.png"
var frames := 0


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.1, 0.09)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.48, 0.45)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	w.add_child(sun)
	var z := 0.0
	for kind in ["rock_snail", "rock_beetle", "cave_bat"]:
		for k in 4:
			var m := MonsterModel.build(kind, Color.GRAY, 1.0, false, kind, k, "")
			m.position = Vector3(k * 1.6 - 2.4, 0, z)
			w.add_child(m)
		z -= 1.8
	var v := MonsterModel.build("rock_beetle", Color.GRAY, 1.0, false, "rock_beetle", 0, "red")
	MonsterModel.add_crystals(v, Monsters.VARIANTS.red.color)
	v.position = Vector3(4.2, 0, -1.8)
	w.add_child(v)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.look_at_from_position(Vector3(0.8, 4.2, 4.2), Vector3(0.8, 0.3, -2.0))


func _process(_d: float) -> bool:
	frames += 1
	if frames == 8:
		root.get_viewport().get_texture().get_image().save_png(out)
	return frames > 9
