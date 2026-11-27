extends SceneTree
## Photographs the hand-built copper set (F914). Usage:
## godot --audio-driver Dummy --path . -s tools/shot_armor.gd -- claude=armor3d out=<file.png> [back=1] [side=1] [hand=1]

const WEAR := ["armor_head_copper", "armor_chest_copper", "armor_legs_copper", "armor_feet_copper"]


func _init() -> void:
	_run.call_deferred()


func _dwarf(x: float, look: String, turn: float) -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	holder.position = Vector3(x, 0, 0)
	holder.rotation.y = turn
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	DwarfRig.armor_look = look
	rig.set_wear(WEAR)


func _run() -> void:
	var out := "user://armor3d.png"
	var back := false
	var side := false  # (side=1: from his left, to see under the arms)
	var hand := false  # (hand=1: close on his left hand and forearm, the gauntlet)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.trim_prefix("out=")
		back = back or a == "back=1"
		side = side or a == "side=1"
		hand = hand or a == "hand=1"
	root.size = Vector2i(1400, 1000)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.19, 0.18)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.52, 0.5)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.3
	root.add_child(sun)
	var turn := 0.35 if back else PI + 0.35  # (he faces -Z)
	if side:
		turn = PI * 0.5
	_dwarf(0.0, "plate", turn)  # (the picture-to-3D test that stood beside it was removed Nov 27)
	var cam := Camera3D.new()
	cam.fov = 30
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.85, 3.0), Vector3(0, 0.72, 0))
	if hand:
		cam.look_at_from_position(Vector3(0.75, 0.75, 1.3), Vector3(0.28, 0.5, 0))
	for i in 40:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
