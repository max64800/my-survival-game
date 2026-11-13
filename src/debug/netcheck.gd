extends Node
## Co-op robot test. Start two copies of the game:
##   godot --path . -- host netcheck seed=5 shots=/tmp/net
##   godot --path . -- join=127.0.0.1 netcheck shots=/tmp/net
## The friend (client) digs, then sends a report to the host. The host checks that
## both computers agree (same holes, same bag) and prints NETCHECK PASS or FAIL.

const TIMEOUT := 90.0

var _main: Node
var _shots := "user://netcheck"
var _client_report := {}


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	get_tree().create_timer(TIMEOUT).timeout.connect(func():
		print("NETCHECK FAIL: timed out")
		get_tree().quit(1))
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _run() -> void:
	while not (_main.world and _main.is_ready_to_play()):
		await _wait(0.25)
	if multiplayer.is_server():
		await _run_host()
	else:
		await _run_client()


func _run_client() -> void:
	var dwarf: Dwarf = _main.dwarf
	var auth: GameAuthority = _main.authority
	var states := {}
	auth.dig_feedback.connect(func(_p, r): states[r.get("state", "?")] = states.get(r.get("state", "?"), 0) + 1)
	await _wait(2.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_main.hud.set_paused(false)
	dwarf._pitch = -0.75
	Input.action_press("dig")
	await _wait(6.0)
	Input.action_release("dig")
	Input.action_press("move_forward")
	await _wait(1.0)
	Input.action_release("move_forward")
	await _wait(1.0)
	# Step 3: the host gave us stone + wood. Craft a campfire and put it down.
	auth.ask_craft("campfire")
	await _wait(1.0)
	var me0 := auth.get_player(auth.local_peer_id())
	for i in Inventory.SIZE:
		if me0.inventory.get_slot(i).get("id", "") == "campfire":
			if i >= Inventory.HOTBAR_SIZE:
				auth.ask_swap(i, Inventory.HOTBAR_SIZE - 1)
				i = Inventory.HOTBAR_SIZE - 1
			await _wait(0.5)
			auth.ask_select_slot(i)
			break
	await _wait(0.5)
	var spot: Vector3 = _main.world.maker.find_floor(dwarf.global_position.x + 1.5, dwarf.global_position.z, dwarf.global_position.y + 1.5)
	auth.ask_use(spot, Vector3.UP, 0.0)
	await _wait(2.0)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("client.png"))
	var me := auth.get_player(auth.local_peer_id())
	var air := 0
	for e in auth.edit_log:
		if auth.world.sdf_at(Vector3(e.x, e.y, e.z)) > 0.0:
			air += 1
	var report := {
		edits = auth.edit_log.size(),
		air = air,
		pending = auth.pending_dig_count(),
		dirt = me.inventory.count_of("dirt") + me.inventory.count_of("moss") + me.inventory.count_of("clay"),
		stone = me.inventory.count_of("stone"),
		pickaxes = me.inventory.count_of("pickaxe_stone"),
		sees_host = _main.players_root.has_node("Dwarf_1"),
		drops = auth.drop_count(),
		stations = auth.stations.size(),
		xp = me.progress.xp,
		smithing = me.progress.skill_xp.smithing,
	}
	print("CLIENT REPORT: ", report, " answers: ", states)
	_report.rpc_id(1, report)
	await _wait(2.0)
	get_tree().quit()


func _run_host() -> void:
	# Dig a little before the friend arrives, so they must catch up on old holes.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_main.hud.set_paused(false)
	_main.dwarf._pitch = -0.75
	_main.dwarf._yaw = PI
	Input.action_press("dig")
	await _wait(3.0)
	Input.action_release("dig")
	var early: int = _main.authority.edit_log.size()
	print("HOST dug %d holes before the friend joined" % early)
	if early == 0:
		print("NETCHECK FAIL: host couldn't dig")
	var gave := false
	while _client_report.is_empty():
		if not gave and not multiplayer.get_peers().is_empty():
			var friend: GameAuthority.PlayerState = _main.authority.get_player(multiplayer.get_peers()[0])
			if friend:
				friend.inventory.add("stone", 5)
				friend.inventory.add("rootwood", 3)
				gave = true
		await _wait(0.25)
	var auth: GameAuthority = _main.authority
	var cid: int = multiplayer.get_peers()[0] if not multiplayer.get_peers().is_empty() else -1
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("host.png"))
	var ps := auth.get_player(cid)
	var air := 0
	for e in auth.edit_log:
		if auth.world.sdf_at(Vector3(e.x, e.y, e.z)) > 0.0:
			air += 1
	var r := _client_report
	var fails: Array[String] = []
	if auth.edit_log.size() == 0:
		fails.append("the friend's digging never reached the host")
	if r.edits != auth.edit_log.size():
		fails.append("hole count differs: host %d, friend %d" % [auth.edit_log.size(), r.edits])
	if r.air != r.edits or air != auth.edit_log.size():
		fails.append("some holes are still rock (host %d/%d, friend %d/%d)" % [air, auth.edit_log.size(), r.air, r.edits])
	if ps == null:
		fails.append("host doesn't know the friend")
	elif r.dirt != ps.inventory.count_of("dirt") + ps.inventory.count_of("moss") + ps.inventory.count_of("clay") or r.stone != ps.inventory.count_of("stone"):
		fails.append("friend's bag differs: friend says dirt %d stone %d, host says dirt %d stone %d" % [r.dirt, r.stone, ps.inventory.count_of("dirt"), ps.inventory.count_of("stone")])
	if r.pickaxes != 1:
		fails.append("friend should have exactly 1 pickaxe (has %d)" % r.pickaxes)
	if r.dirt + r.stone + r.edits == 0:
		fails.append("friend collected nothing")
	if not r.sees_host:
		fails.append("friend can't see the host's dwarf")
	if auth.stations.size() != 1 or r.stations != 1:
		fails.append("campfire count: host %d, friend %d (both should be 1)" % [auth.stations.size(), r.stations])
	if ps and (r.xp != ps.progress.xp or r.smithing != ps.progress.skill_xp.smithing):
		fails.append("friend's XP differs: friend %d/%d, host %d/%d" % [r.xp, r.smithing, ps.progress.xp, ps.progress.skill_xp.smithing])
	if ps and r.smithing == 0:
		fails.append("friend got no smithing XP for crafting")
	if not _main.players_root.has_node("Dwarf_%d" % cid):
		fails.append("host can't see the friend's dwarf")
	print("HOST: edits %d, friend's bag on host: dirt %d stone %d" % [auth.edit_log.size(), ps.inventory.count_of("dirt") if ps else -1, ps.inventory.count_of("stone") if ps else -1])
	print("NETCHECK PASS" if fails.is_empty() else "NETCHECK FAIL: " + "; ".join(fails))
	await _wait(1.0)
	get_tree().quit(0 if fails.is_empty() else 1)


@rpc("any_peer", "reliable")
func _report(r: Dictionary) -> void:
	_client_report = r
