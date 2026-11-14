extends SceneTree
## Photo studio for the dwarf: bright even light, front + side cameras, a few poses
## (idle, mid-swing, strike, walking, attack). Saves pictures, then quits.
##   godot --audio-driver Dummy --path . --script res://src/debug/dwarf_studio.gd -- shots=/folder
## (Put "autopilot" in the folder name so the OBS auto-recorder skips the run.)

var _shots := "user://studio"
var _cam: Camera3D
var _model: DwarfModel


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.33, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.68)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child.call_deferred(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-40), deg_to_rad(30), 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	root.add_child.call_deferred(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	floor_mi.mesh = pm
	floor_mi.material_override = Look.mat(Color(0.4, 0.37, 0.33), "stone")
	root.add_child.call_deferred(floor_mi)
	_model = DwarfModel.new()
	_model.tunic = DwarfModel.TUNICS[0]
	root.add_child.call_deferred(_model)
	_cam = Camera3D.new()
	_cam.fov = 35.0
	root.add_child.call_deferred(_cam)
	_run.call_deferred()


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _view(dir: Vector3, dist: float = 3.2, at_y: float = 0.7) -> void:
	_cam.global_position = Vector3(0, at_y + 0.25, 0) + dir.normalized() * dist
	_cam.look_at(Vector3(0, at_y, 0))


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(_shots.path_join(name + ".png"))
	print("  studio: ", name)


func _both(name: String) -> void:
	_view(Vector3(0.35, 0, -1))  # the dwarf faces -Z: this is the front
	await _shot(name + "_front")
	_view(Vector3(1, 0, -0.1))
	await _shot(name + "_side")


func _run() -> void:
	await _wait(0.5)
	if "rots" in OS.get_cmdline_user_args():
		await _rot_lineup()
		quit()
		return
	_model.set_held("pickaxe_stone")
	_model.set_motion(0.0, true, false)
	await _wait(0.6)
	await _both("1_idle")
	_view(Vector3(0.2, 0.1, -1), 1.3, 1.0)
	await _shot("1_face")
	for t in [0.15, 0.3, 0.42]:
		_model.swinging = false
		_model.swing(0.55)
		await _wait(t)
		_view(Vector3(1, 0, -0.3))
		await _shot("2_dig_%.2f" % t)
		await _wait(0.8)
	_model.set_held("sword_stone")
	_model.attack(0.5, false)
	await _wait(0.2)
	await _both("3_attack")
	await _wait(0.6)
	_model.set_held("pickaxe_stone")
	for i in 30:
		_model.set_motion(4.0, true, false)
		await process_frame
	await _both("4_jog")
	quit()


## Tuning aid: 4 dwarfs, each holding the pickaxe turned a different way.
func _rot_lineup() -> void:
	_model.queue_free()
	var rots := [Vector3(90, 0, 0), Vector3(-90, 0, 0), Vector3(0, 0, 90), Vector3(0, 0, -90)]
	var models := []
	for i in rots.size():
		DwarfModel.hand_tool_rot = rots[i] * PI / 180.0
		var m := DwarfModel.new()
		m.position = Vector3((i - 1.5) * 1.3, 0, 0)
		root.add_child(m)
		m.set_held("pickaxe_stone")
		models.append(m)
	await _wait(0.6)
	_view(Vector3(0.3, 0.1, -1), 6.5, 0.6)
	await _shot("r_idle_front")
	_view(Vector3(1, 0.1, -0.2), 7.5, 0.6)
	await _shot("r_idle_side")
	for m in models:
		m.swing(0.55)
	await _wait(0.33)
	_view(Vector3(0.3, 0.1, -1), 6.5, 0.6)
	await _shot("r_strike_front")
