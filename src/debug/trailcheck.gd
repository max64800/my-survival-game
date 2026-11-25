extends Node
## Trail check (F870 step 5): photos of the old dirt path near the start, old stones, broken track and a fallen torch.
## Run:  godot --audio-driver Dummy --path . -- trailcheck claude=old_path seed=42 shots=<folder>

var _main: Node
var _shots := "user://trailcheck"


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	print("TRAILCHECK shot ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 150.0:
		await _wait(0.25)
		waited += 0.25
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var dwarf: Dwarf = _main.dwarf
	var maker: CaveMaker = _main.world.maker
	print("TRAILCHECK path spots ", maker.trail.size())
	# The path nearest the start.
	var best := 0
	for i in maker.trail.size():
		if maker.trail[i].distance_to(maker.spawn_point) < maker.trail[best].distance_to(maker.spawn_point):
			best = i
	await _look_along(dwarf, best, "1_path_near_start")
	var items := TrailDecor.plan(maker)
	for kind in [TrailDecor.STONES, TrailDecor.RAIL, TrailDecor.TORCH]:
		var pick: Dictionary = {}
		var bd := INF
		for it in items:
			var d: float = (it.xform as Transform3D).origin.distance_to(maker.spawn_point)
			if it.model == kind and d < bd:
				bd = d
				pick = it
		if pick.is_empty():
			continue
		var o: Vector3 = (pick.xform as Transform3D).origin
		var near := 0
		for i in maker.trail.size():
			if maker.trail[i].distance_to(o) < maker.trail[near].distance_to(o):
				near = i
		await _look_along(dwarf, near, "%d_%s" % [kind + 2, ["stones", "track", "torch"][kind]], o)
	var td: TrailDecor = _main.get_node_or_null("TrailDecor")
	if td:
		var hidden := 0
		var total := 0
		var kids := 0
		for c in td.get_children():
			var mm := (c as MultiMeshInstance3D).multimesh
			kids += 1
			for i in mm.instance_count:
				total += 1
				if mm.get_instance_transform(i).basis.get_scale().x < 0.01:
					hidden += 1
		print("TRAILCHECK decor nodes %d, things %d, hidden by the floor check %d, count() %d" % [kids, total, hidden, td.count()])
	else:
		print("TRAILCHECK no TrailDecor node")
	print("TRAILCHECK done")
	get_tree().quit()


## Stand on the path a few metres back from spot i and look along it (at `at` if given).
func _look_along(dwarf: Dwarf, i: int, name: String, at := Vector3.INF) -> void:
	var maker: CaveMaker = _main.world.maker
	var p: Vector3 = maker.trail[i]
	var dir: Vector3 = maker.trail_along[i]
	var back := p - dir * 5.0
	if at != Vector3.INF:  # (beside it, so the dwarf isn't in the way)
		back = at + Vector3(dir.z, 0.0, -dir.x) * 3.0 - dir * 1.5
	var stand := maker.find_floor(back.x, back.z, p.y + 3.0) + Vector3.UP * 0.2
	if maker.sdf_at(stand + Vector3.UP * 1.0) <= 0.3:
		stand = p + Vector3.UP * 0.2
	var look := at if at != Vector3.INF else p + dir * 6.0
	dwarf.set_physics_process(false)
	dwarf.global_position = stand
	for k in 400:
		if _main.world.terrain.is_area_meshed(AABB(stand - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await get_tree().process_frame
	var d := look - (stand + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-d.x, -d.z)
	dwarf._pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	dwarf.model.visible = at == Vector3.INF  # (hidden for the close looks)
	await _wait(2.5)
	await _shot(name)
