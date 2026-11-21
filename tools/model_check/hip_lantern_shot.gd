extends SceneTree
## The dwarf with the Hip Lantern on its belt (F562), from the front and the side.
##   godot --audio-driver Dummy --path . --script res://tools/model_check/hip_lantern_shot.gd -- <out.png>
var out := "user://hip_lantern.png"
var frames := 0
var lanterns := []
var dwarves := []


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.1, 0.09)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.48, 0.45)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	root.add_child(sun)
	for i in 2:
		var dm := DwarfModel.new()
		dm.position = Vector3(i * 1.4 - 0.7, 0, 0)
		dm.rotation.y = PI if i == 0 else PI * 0.5  # one faces the camera, one shows its left side
		root.add_child(dm)
		dwarves.append(dm)
	var cam := Camera3D.new()
	cam.look_at_from_position(Vector3(0, 0.75, 2.9), Vector3(0, 0.6, 0))
	cam.fov = 45
	root.add_child(cam)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:  # (the dwarves are built once they're in the tree)
		for dm: DwarfModel in dwarves:
			var l := Lantern.new()
			dm.left_hand.add_child(l)
			l.set_process(false)
			lanterns.append(l)
	if frames < 20:
		for l in lanterns:
			l.place("hip")
	if frames == 30:
		root.get_viewport().get_texture().get_image().save_png(out)
		return true
	return false
