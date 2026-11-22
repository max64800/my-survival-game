extends Node
## Robot (Nov 22): the dungeon ghosts in the real game (Ghost). In the dungeon test world, in front of Mossgate's door:
## the three shades and the Grey Warden float in a row; they come at the dwarf and swing their maces; one loses a
## quarter of its health and fades away to a new spot; then they all fade into mist. A picture at each step, then it quits.
## Run: godot --audio-driver Dummy --path . -- ghostcheck claude=ghost shots=<folder>

var _main: Node
var _shots := ""
var _hold := Vector3.INF  ## the dwarf stands here (pinned: he doesn't walk or fall during the pictures)


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
		print("GHOSTCHECK shot ", _main.take_screenshot(_shots.path_join("ghosts_%s.png" % name)))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var maker: CaveMaker = _main.world.maker
	var auth: GameAuthority = _main.authority
	var mgr: MonsterManager = auth.monsters
	var dwarf: Dwarf = _main.dwarf
	var ps := auth.get_player(auth.local_peer_id())
	if maker.dungeons.is_empty():
		print("GHOSTCHECK no dungeon")
		get_tree().quit()
		return
	var d: Dictionary = maker.dungeons[0]
	var mouth: Vector2 = d.map.mouth
	var door := DungeonMap.to_world(d, Vector3(mouth.x, 0.0, mouth.y))
	var stand := DungeonMap.to_world(d, Vector3(mouth.x, 0.0, mouth.y + float(d.entry_out) + 5.0))
	var out := (stand - door) * Vector3(1, 0, 1)
	out = out.normalized()
	var side := out.cross(Vector3.UP).normalized()
	var fl := maker.find_floor(stand.x, stand.z, stand.y + 3.0)
	if fl != Vector3.INF:
		stand = fl
	dwarf.set_physics_process(false)
	dwarf.global_position = stand + Vector3.UP * 0.3
	for i in 1200:
		if _main.world.terrain.is_area_meshed(AABB(stand - Vector3.ONE * 16.0, Vector3.ONE * 32.0)) and _main.world.is_ready_at(stand, 8.0):
			break
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	# The miners lie in a row 12-14 m out from the dwarf (away from the door), the Foreman in the middle.
	var made := []
	var row := [["ghost_a", -3.0, 6.0], ["ghost_b", -1.0, 7.0], ["ghost_lord", 1.2, 8.0], ["ghost_c", 3.4, 6.5]]
	for r in row:
		var at: Vector3 = stand + out * float(r[2]) + side * float(r[1])
		var f := maker.find_floor(at.x, at.z, at.y + 3.0)
		if f == Vector3.INF:
			print("GHOSTCHECK no floor for ", r[0])
			continue
		var uid: int = mgr._next_uid
		mgr._ev_spawn.rpc(uid, r[0], f + Vector3.UP * 0.3, false, 777, "")
		made.append(mgr.get_monster(uid))
	print("GHOSTCHECK spawned %d" % made.size())
	var lamp := OmniLight3D.new()  # (robot pictures only)
	lamp.omni_range = 16.0
	lamp.light_energy = 1.2
	lamp.light_color = Color(1.0, 0.85, 0.6)
	_main.add_child(lamp)
	lamp.global_position = stand + out * 5.0 + Vector3.UP * 3.0
	var mid := stand + out * 7.0
	_look(dwarf, mid, stand - out * 4.0)
	await get_tree().create_timer(1.5).timeout
	await _shot("1_row")
	_look(dwarf, mid, stand + out * 1.0)
	var swung := 0
	var t := 0.0
	while t < 9.0 and swung < 2:
		await get_tree().process_frame
		t += get_process_delta_time()
		if ps:
			ps.vitals.health = ps.vitals.max_health()
		if "trace" in OS.get_cmdline_user_args() and Engine.get_process_frames() % 20 == 0 and is_instance_valid(made[1]):
			var b: Monster = made[1]
			print("GHOSTCHECK trace %.1f %s %s v=%s" % [t, Monster.State.keys()[b.state], b.global_position - dwarf.global_position, b.velocity])
		for m: Monster in made:
			if is_instance_valid(m) and m.state == Monster.State.ATTACK and m._timer < 0.2 and not m.has_meta("shot"):
				m.set_meta("shot", true)
				swung += 1
				print("GHOSTCHECK swing by ", m.kind)
				await _shot("2_swing_%d_%s" % [swung, m.kind])
	for m: Monster in made:
		if is_instance_valid(m):
			print("GHOSTCHECK %s %s %.1f m" % [m.kind, Monster.State.keys()[m.state], m.global_position.distance_to(dwarf.global_position)])
	# a quarter of its health gone: it fades into mist and comes back somewhere else
	var g: Monster = made[0]
	if is_instance_valid(g):
		var was := g.global_position
		mgr._hurt_monster(g, auth.local_peer_id(), int(g.max_hp() * 0.3), 0.0)
		await get_tree().create_timer(0.1).timeout
		await _shot("3_fading")
		await get_tree().create_timer(0.6).timeout
		print("GHOSTCHECK jumped %.1f m" % g.global_position.distance_to(was))
		await _shot("4_back")
	for m: Monster in made:
		if is_instance_valid(m) and m.is_alive():
			mgr._kill(m, auth.local_peer_id())
	await get_tree().create_timer(0.5).timeout
	await _shot("5_vanishing")
	await get_tree().create_timer(1.5).timeout
	print("GHOSTCHECK statues: %d, left: %d" % [mgr.statues.size(), made.filter(func(m): return is_instance_valid(m)).size()])
	get_tree().quit()


func _look(dwarf: Dwarf, target: Vector3, from: Vector3) -> void:
	_hold = from + Vector3.UP * 0.1
	dwarf.global_position = _hold
	dwarf.velocity = Vector3.ZERO
	var v := target - (dwarf.global_position + Vector3.UP * 1.0)
	dwarf._yaw = atan2(-v.x, -v.z)
	dwarf._pitch = atan2(v.y, Vector2(v.x, v.z).length()) - 0.12
	dwarf.model.rotation.y = dwarf._yaw
