extends Node
## Robot (Nov 20): the skeleton miners in the real game. In the dungeon test world, on the cave floor in front of
## Mossgate's door: 3 Tunnel Rats, 2 Lost Miners and the Foreman lie scattered on the floor; the dwarf walks up, they
## get up and come running, swing, and are killed (fall apart, turn to stone). A picture at each step, then it quits.
## Run: godot --audio-driver Dummy --path . -- minercheck claude=miners shots=<folder>

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
		print("MINERCHECK shot ", _main.take_screenshot(_shots.path_join("miners_%s.png" % name)))


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
		print("MINERCHECK no dungeon")
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
	var row := [["tunnel_rat", -3.0, 6.0], ["lost_miner", -1.5, 7.0], ["foreman", 0.0, 8.0], ["lost_miner", 1.5, 7.0],
		["tunnel_rat", 3.0, 6.0], ["tunnel_rat", 4.5, 6.5]]
	if "warden" in OS.get_cmdline_user_args():
		row[2][0] = "prop_warden"  # (-- warden: the Prop Warden in the middle instead, F548: his raised shield)
	for r in row:
		var at: Vector3 = stand + out * float(r[2]) + side * float(r[1])
		var f := maker.find_floor(at.x, at.z, at.y + 3.0)
		if f == Vector3.INF:
			print("MINERCHECK no floor for ", r[0])
			continue
		var uid: int = mgr._next_uid
		mgr._ev_spawn.rpc(uid, r[0], f + Vector3.UP * 0.3, false, 777, "")
		made.append(mgr.get_monster(uid))
	print("MINERCHECK spawned %d; dwarf at %s, players %s" % [made.size(), dwarf.global_position, auth.players.keys()])
	if ps:
		ps.fuel = GameAuthority.MAX_FUEL
	var lamp := OmniLight3D.new()  # (robot pictures only: lamplight over the row)
	lamp.omni_range = 16.0
	lamp.light_energy = 2.0
	lamp.light_color = Color(1.0, 0.85, 0.6)
	_main.add_child(lamp)
	lamp.global_position = stand + out * 5.0 + Vector3.UP * 3.0
	var look_at := func(target: Vector3, from: Vector3) -> void:
		_hold = from + Vector3.UP * 0.1
		dwarf.global_position = _hold
		dwarf.velocity = Vector3.ZERO
		var v := target - (dwarf.global_position + Vector3.UP * 1.0)
		dwarf._yaw = atan2(-v.x, -v.z)
		dwarf._pitch = atan2(v.y, Vector2(v.x, v.z).length()) - 0.12
		dwarf.model.rotation.y = dwarf._yaw
	var mid := stand + out * 7.0
	look_at.call(mid, stand - out * 6.0)
	await get_tree().create_timer(1.5).timeout
	_report(made, "lying")
	await _shot("1_lying")
	# Walk up: within 8 m they get up (the Foreman at 10 m).
	look_at.call(mid, stand + out * 0.5)
	await get_tree().create_timer(1.1).timeout
	_report(made, "rising")
	await _shot("2_rising")
	await get_tree().create_timer(1.6).timeout
	_report(made, "risen")
	await _shot("3_risen")
	# Let them come: keep the dwarf alive and take a picture when someone swings.
	var swung := false
	var t := 0.0
	while t < 8.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if ps:
			ps.vitals.health = ps.vitals.max_health()
		for m: Monster in made:
			if is_instance_valid(m) and m.state == Monster.State.ATTACK and not swung and m._timer < 0.25:
				swung = true
				_report(made, "swing by " + m.kind)
				await _shot("4_swing_" + m.kind)
		if t > 1.0 and t < 1.1:
			await _shot("3b_running")
	if not swung:
		print("MINERCHECK nobody swung in 8 s")
	# A hit: the flinch and the white flash.
	for m: Monster in made:
		if is_instance_valid(m) and m.is_alive():
			mgr._ev_hit.rpc(m.uid, 10, dwarf.global_position, 0)
	await get_tree().create_timer(0.12).timeout
	await _shot("5_hit")
	# Killed: they fall apart, then turn to stone.
	for m: Monster in made:
		if is_instance_valid(m) and m.is_alive():
			mgr._kill(m, auth.local_peer_id())
	await get_tree().create_timer(1.0).timeout
	await _shot("6_falling")
	await get_tree().create_timer(5.0).timeout
	await _shot("7_stone")
	print("MINERCHECK statues: %d" % mgr.statues.size())
	get_tree().quit()


func _report(made: Array, when: String) -> void:
	var s := []
	var dwarf: Node3D = _main.dwarf
	for m: Monster in made:
		if is_instance_valid(m):
			s.append("%s:%s%s %.1fm" % [m.kind, Monster.State.keys()[m.state], " (lying)" if m.rig and m.rig.lying else "",
				m.global_position.distance_to(dwarf.global_position)])
	print("MINERCHECK %s: %s" % [when, ", ".join(s)])
