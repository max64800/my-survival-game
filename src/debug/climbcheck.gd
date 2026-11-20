extends Node
## Robot (Nov 20, creature climbing F474/F475): a Cave Spider and a Rock Snail on the ceiling near the start, a Rock
## Beetle on a wall; a picture; then the snail is hit (knocked down: it lands on its shell, dazed); a picture; quits.
## Run: godot --audio-driver Dummy --path . -- climbcheck claude=climbing seed=42 shots=<folder>

var _main: Node
var _shots := ""
var _hold := Vector3.INF


func _physics_process(_delta: float) -> void:
	if _hold != Vector3.INF and _main and _main.dwarf:
		_main.dwarf.global_position = _hold
		_main.dwarf.velocity = Vector3.ZERO


func _ready() -> void:
	_main = get_parent()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			_shots = a.trim_prefix("shots=")
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if _shots != "":
		print("CLIMBCHECK shot ", _main.take_screenshot(_shots.path_join("climb_%s.png" % name)))


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, World.TERRAIN_LAYER)
	return _main.world.get_world_3d().direct_space_state.intersect_ray(q)


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var maker: CaveMaker = _main.world.maker
	var mgr: MonsterManager = _main.authority.monsters
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	var base := dwarf.global_position
	await get_tree().create_timer(1.0).timeout
	# A ceiling 3-7 m up near the dwarf.
	var spot := {}
	for r: float in [3.0, 5.0, 7.0, 9.0, 11.0, 14.0]:
		for a in 12:
			var fl := maker.find_floor(base.x + cos(a * TAU / 12.0) * r, base.z + sin(a * TAU / 12.0) * r, base.y + 2.0)
			var hit := _ray(fl + Vector3.UP * 0.5, fl + Vector3.UP * 9.0)
			if not hit.is_empty() and hit.position.y - fl.y > 3.0 and hit.position.y - fl.y < 8.5 and hit.normal.y < Monster.CEILING_DOWN:
				spot = {pos = hit.position, normal = hit.normal, floor = fl}
				break
		if not spot.is_empty():
			break
	if spot.is_empty():
		print("CLIMBCHECK no ceiling")
		get_tree().quit()
		return
	var ids := []
	for k in [["cave_spider", Vector3.ZERO], ["rock_snail", Vector3(1.2, 0, 0.6)]]:
		var p: Vector3 = spot.pos + k[1]
		var hit := _ray(p + Vector3.DOWN * 1.0, p + Vector3.UP * 2.0)
		if hit.is_empty():
			continue
		var uid := mgr._next_uid
		mgr._ev_spawn(uid, k[0], hit.position, false, 0, "", hit.normal)
		ids.append(uid)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 12.0
	lamp.light_energy = 2.5
	lamp.light_color = Color(1.0, 0.85, 0.6)
	_main.add_child(lamp)
	lamp.global_position = spot.floor + Vector3.UP * 1.5
	var away: Vector3 = ((base - spot.floor) * Vector3(1, 0, 1)).normalized()
	var from: Vector3 = spot.floor + away * 4.0
	from = maker.find_floor(from.x, from.z, from.y + 2.0)
	_hold = from + Vector3.UP * 0.1
	var v: Vector3 = spot.pos - (from + Vector3.UP * 1.6)
	dwarf._yaw = atan2(-v.x, -v.z)
	dwarf._pitch = atan2(v.y, Vector2(v.x, v.z).length())
	dwarf.model.rotation.y = dwarf._yaw
	await get_tree().create_timer(1.5).timeout
	await _shot("1_on_ceiling")
	var snail: Monster = mgr.get_monster(ids[-1]) if ids.size() > 0 else null
	if snail:
		mgr._hurt_monster(snail, _main.authority.local_peer_id(), 1, 0.0)
		await get_tree().create_timer(1.6).timeout
		v = snail.global_position - (from + Vector3.UP * 1.6)
		dwarf._yaw = atan2(-v.x, -v.z)
		dwarf._pitch = atan2(v.y, Vector2(v.x, v.z).length())
		dwarf.model.rotation.y = dwarf._yaw
		await get_tree().create_timer(0.3).timeout
		print("CLIMBCHECK snail on floor %s stunned %s on_back %.1f" % [snail.is_on_floor(), snail.stun.is_stunned(), snail._on_back])
		await _shot("2_snail_knocked_down")
	get_tree().quit()
