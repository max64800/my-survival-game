extends SceneTree
## Pictures of a flying creature's wing beat, front view, at 4 moments of one beat (Claude, Nov 18: the bat's jointed wings).
##   godot --audio-driver Dummy --path . --script res://tools/model_check/flap_shot.gd -- cave_bat <out_prefix> [red|blue|green] [above]
var prefix := ""
var model: Node3D
var step := 0
const PHASES := [0.0, 0.17, 0.35, 0.52]  # (seconds into the beat: one beat is 2*PI/9 = 0.70 s)


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var kind: String = a[0] if a.size() > 0 else "cave_bat"
	prefix = a[1] if a.size() > 1 else "user://flap"
	var variant: String = a[2] if a.size() > 2 else ""  # (a look: red = ember, blue = frost, green = spore)
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.45, 0.47)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	w.add_child(sun)
	model = MonsterModel.build(kind, Color.WHITE, 0.9, false, kind, 5, variant)
	w.add_child(model)
	var cam := Camera3D.new()
	w.add_child(cam)
	if a.has("above"):  # (from above and in front: the wings' tops and the face)
		cam.look_at_from_position(Vector3(0.0, 2.3, -1.6), Vector3(0, 0.5, 0))
	else:
		cam.look_at_from_position(Vector3(0.3, 1.0, 2.6), Vector3(0, 0.55, 0))


func _process(_d: float) -> bool:
	if step >= PHASES.size() * 3:
		return true
	var k := step / 3
	MonsterModel.animate(model, 0.0, 0.9, PHASES[k])
	if step % 3 == 2:  # (two frames later the picture shows the pose)
		root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, k])
	step += 1
	return false
