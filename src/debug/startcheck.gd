extends Node
## Start check: plays the first minutes of a real new game by itself (feedback F10/F11) and
## takes screenshots: wake in the small room, pick up rocks, pull roots, craft a pickaxe and a
## lantern, dig through the soft wall, walk the tunnel into the cavern.
## Run:  godot --audio-driver Dummy --path . -- startcheck seed=42 shots=/some/folder

var _main: Node
var _shots := "user://startcheck"
var _report: Array[String] = []


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
	_main.take_screenshot(_shots.path_join(name + ".png"))


func _say(t: String) -> void:
	_report.append(t)


func _face(dwarf: Dwarf, dir: Vector3, pitch: float = -0.05) -> void:
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = pitch
	dwarf.model.rotation.y = dwarf._yaw


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var dwarf: Dwarf = _main.dwarf
	var auth: GameAuthority = _main.authority
	var me := auth.local_peer_id()
	var ps := auth.get_player(me)
	var st: Dictionary = _main.world.maker.start
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_main.hud.set_paused(false)
	_say("start room found: %s" % (not st.is_empty()))
	if st.is_empty():
		_finish()
		return
	var u: Vector3 = st.dir
	var things := 0
	for i in Inventory.SIZE:
		things += int(ps.inventory.get_slot(i).get("count", 0))
	_say("things in bag at start: %d; needs lantern: %s; lantern visible: %s" % [things, ps.needs_lantern, dwarf.lantern.visible])
	_say("in the start room: %s" % (dwarf.global_position.distance_to(st.room_c) < 4.5))
	_face(dwarf, u)
	await _wait(2.0)
	await _shot("01_wake_facing_peephole")
	_face(dwarf, -u, -0.35)
	await _wait(0.5)
	await _shot("02_room_behind")

	# Walk over each loose thing on the floor.
	for p in st.loose:
		dwarf.global_position = (p as Vector3) + Vector3.UP * 0.6
		await _wait(0.9)
	await _wait(1.0)
	_say("picked up: stone %d, crystal %d" % [ps.inventory.count_of("stone"), ps.inventory.count_of("crystal_blue")])

	# Pull down the thin roots by hand.
	var roots := 0
	for s in _main.glow.spots_near(st.room_c, 8.0):
		if s.kind != GlowPlacer.ROOT_DANGLE:
			continue
		dwarf.global_position = Vector3(s.pos.x, st.floor_y + 1.0, s.pos.z) - u * 0.5
		await _wait(0.3)
		var r := auth.request_harvest(me, s.id)
		roots += 1 if r.get("state", "") == "done" else 0
	await _wait(1.5)
	_say("roots pulled: %d, rootwood %d" % [roots, ps.inventory.count_of("rootwood")])

	_main._set_bag(true)
	await _wait(0.6)
	await _shot("03_bag_and_crafting")
	var pick := auth.request_craft(me, "pickaxe_stone")
	var lamp := auth.request_craft(me, "lantern")
	_main._set_bag(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_say("crafted pickaxe: %s, lantern: %s; lantern visible now: %s" % [pick, lamp, Lantern.has_lantern(ps)])
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "pickaxe_stone":
			auth.request_select_slot(me, i)
	dwarf.global_position = Vector3(st.room_c.x, st.floor_y + 1.0, st.room_c.z) - u * 1.0
	_face(dwarf, u)
	await _wait(1.0)
	await _shot("04_lantern_lit")

	# Dig through the soft wall, at the peephole.
	var wall: Vector3 = st.room_c + u * (CaveMaker.START_ROOM_R.x - 1.6)
	dwarf.global_position = Vector3(wall.x, st.floor_y + 0.9, wall.z)
	_face(dwarf, u, -0.1)
	await _wait(0.5)
	var plug_mid: Vector3 = ((st.plug_a as Vector3) + (st.plug_b as Vector3)) * 0.5
	plug_mid.y = st.floor_y + 1.0
	_say("wall material: %s" % Mat.NAMES.get(_main.world.material_at(plug_mid + Vector3.UP * 0.5), "?"))
	Input.action_press("dig")
	for i in 16:
		await _wait(0.5)
		dwarf.global_position = dwarf.global_position.move_toward(Vector3(plug_mid.x, dwarf.global_position.y, plug_mid.z), 0.35)
		_face(dwarf, u, -0.1)
	Input.action_release("dig")
	await _wait(0.5)
	var open: bool = _main.world.sdf_at(plug_mid + Vector3.UP * 0.4) > 0.0
	_say("wall dug through: %s" % open)
	await _shot("05_through_the_wall")

	# Walk down the tunnel.
	var t_end: Vector3 = st.tunnel[2].b
	var walked_from := dwarf.global_position
	for seg in st.tunnel:
		var target: Vector3 = seg.b
		for i in 40:
			var to := target - dwarf.global_position
			to.y = 0.0
			if to.length() < 1.2:
				break
			_face(dwarf, to.normalized())
			dwarf.bot_move = Vector2(0, -1)
			await _wait(0.1)
	dwarf.bot_move = Vector2.ZERO
	_say("walked %.1f m; reached the cavern: %s (%.1f m from the tunnel's end)" % [
		walked_from.distance_to(dwarf.global_position), dwarf.global_position.distance_to(t_end) < 4.0, dwarf.global_position.distance_to(t_end)])
	_face(dwarf, (t_end - (st.room_c as Vector3)).normalized())
	await _wait(1.0)
	await _shot("06_cavern")
	_finish()


func _finish() -> void:
	print("===== START CHECK =====")
	for line in _report:
		print("  " + line)
	print("=======================")
	get_tree().quit()
