extends Node
## Camera check (F766, owner Nov 23): the dwarf stands with his back to a dungeon wall, then to cave rock, and the
## camera should stay back (inside the wall) and see through it. Starts like "Test the dungeon", then takes pictures.
## Run:  godot --audio-driver Dummy --path . -- dungeoncam claude=dungeon_camera seed=42 shots=/some/folder

var _main: Node
var _shots := "user://dungeoncam"
var _debug := false


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_main.add_child.call_deferred(load("res://src/debug/dungeon_test_start.gd").new())
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join(name + ".png"))


## The nearest wall round `at` (chest height), as [where it was hit, the way to it], from 24 looks round.
func _nearest_wall(at: Vector3, want_ruin: bool) -> Array:
	var space := (_main.dwarf as Node3D).get_world_3d().direct_space_state
	var best := []
	var best_d := INF
	for k in 48:
		var i := k % 24
		var at2 := at + Vector3.UP * (0.5 if k < 24 else 1.0)
		var a := TAU * i / 24.0
		var dir := Vector3(sin(a), 0, cos(a))
		var q := PhysicsRayQueryParameters3D.create(at2, at2 + dir * 8.0, World.TERRAIN_LAYER)
		q.exclude = [(_main.dwarf as CollisionObject3D).get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or absf((hit.normal as Vector3).y) > 0.5:
			if _debug:
				print("DUNGEONCAM ray %d: %s" % [i, "miss" if hit.is_empty() else "flat %s" % hit.normal])
			continue
		if _debug:
			print("DUNGEONCAM ray %d: %s at %.1f m, group %s" % [i, hit.collider, at.distance_to(hit.position),
				(hit.collider as Node).is_in_group(RuinKit.GROUP) if hit.collider is Node else "-"])
		var ruin := (hit.collider as Node).is_in_group(RuinKit.GROUP) if hit.collider is Node else false
		if ruin != want_ruin:
			continue
		var d := at2.distance_to(hit.position)
		if d < best_d:
			best_d = d
			best = [hit.position - Vector3.UP * (at2.y - at.y), dir]
	return best


## Stand him `gap` m in front of the wall, his back to it, looking a little down.
func _back_to(wall: Array, gap: float, name: String) -> void:
	var dwarf: Dwarf = _main.dwarf
	var dir: Vector3 = wall[1]
	dwarf.set_physics_process(false)
	dwarf.global_position = (wall[0] as Vector3) - dir * gap + Vector3(0, -0.9, 0)
	dwarf._yaw = atan2(dir.x, dir.z)
	dwarf._pitch = -0.3
	dwarf.model.rotation.y = dwarf._yaw + PI
	dwarf.set_physics_process(true)
	await _wait(1.5)
	var cam := dwarf.camera.global_position
	print("DUNGEONCAM %s: camera %.2f m from his chest" % [name, cam.distance_to(dwarf.global_position + Vector3.UP * 0.9)])
	await _shot(name)


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await _wait(0.25)
		waited += 0.25
	await _wait(4.0)   # (the dungeon test start puts him at the door)
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_main.hud.visible = false
	var dwarf: Dwarf = _main.dwarf
	var start := dwarf.global_position + Vector3.UP * 0.9
	print("DUNGEONCAM start %s yaw %.2f" % [start, dwarf._yaw])
	var rock := _nearest_wall(start, false)
	if not rock.is_empty():
		await _back_to(rock, 0.45, "01_back_to_rock")
	var fwd := Vector3(-sin(dwarf._yaw), 0, -cos(dwarf._yaw))
	var wall := []
	for step in [4.0, 7.0, 10.0, 2.0]:   # (through the door, inside)
		wall = _nearest_wall(start + fwd * step, true)
		if not wall.is_empty():
			break
	if not wall.is_empty():
		await _back_to(wall, 0.45, "02_back_to_dungeon_wall")
		dwarf._pitch = -0.7
		await _wait(1.0)
		await _shot("03_dungeon_wall_looking_down")
		dwarf._pitch = 0.4
		await _wait(1.0)
		await _shot("04_dungeon_wall_looking_up")
	else:
		print("DUNGEONCAM: no dungeon wall found")
	get_tree().quit()
