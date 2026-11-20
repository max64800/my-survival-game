extends SceneTree
## Test room for big hits (F237): a floor, a wall, a dwarf thrown from a different side every 3.5 s.
## Saves a picture mid-tumble and after each get-up, then quits.
##   godot --audio-driver Dummy --path . --script res://src/debug/ragdoll_room.gd -- claude=ragdoll shots=/folder

const PUSHES := [Vector3(8, 0, 0), Vector3(0, 0, 9), Vector3(-6, 0, -6), Vector3(10, 0, 3)]
var _shots := "user://ragdoll_room"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _block(at: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = Look.mat(color, "stone")
	body.add_child(mi)
	body.position = at
	root.add_child(body)


func _run() -> void:
	Controls.setup()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.31, 0.34)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.68)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(30), 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	_block(Vector3(0, -0.5, 0), Vector3(30, 1, 30), Color(0.42, 0.38, 0.33))
	_block(Vector3(0, 1, -6), Vector3(12, 2, 1), Color(0.35, 0.33, 0.3))  # a wall to bounce off
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	await create_timer(1.0).timeout
	for n in PUSHES.size():
		dwarf.big_hit(PUSHES[n])
		await create_timer(0.45).timeout
		_shot("%d_tumble" % n)
		await create_timer(1.6).timeout
		_shot("%d_lying" % n)
		await create_timer(1.4).timeout
		_shot("%d_up" % n)
	quit()


func _shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(_shots.path_join(name + ".png"))
