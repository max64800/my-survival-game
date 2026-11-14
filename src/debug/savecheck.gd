extends Node
## Save robot test, in two runs:
##   godot --path . -- seed=777 savecheck=1     (plays a bit, saves, quits)
##   godot --path . -- continue savecheck=2     (continues the save and checks it)

var _main: Node
var _part := 1


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("savecheck="):
			_part = arg.trim_prefix("savecheck=").to_int()
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _run() -> void:
	while not (_main.world and _main.is_ready_to_play()):
		await _wait(0.25)
	await _wait(1.0)
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	if _part == 1:
		ps.inventory.add("stone", 5)
		ps.inventory.add("rootwood", 3)
		ps.inventory.add("copper_ingot", 9)
		auth.request_craft(auth.local_peer_id(), "campfire")
		var spot: Vector3 = _main.world.maker.find_floor(_main.dwarf.global_position.x + 2.0, _main.dwarf.global_position.z, _main.dwarf.global_position.y + 1.5)
		for i in Inventory.SIZE:
			if ps.inventory.get_slot(i).get("id", "") == "campfire":
				if i >= Inventory.HOTBAR_SIZE:
					auth.request_swap(auth.local_peer_id(), i, 7)
					i = 7
				auth.request_select_slot(auth.local_peer_id(), i)
		print("SAVECHECK placed: ", auth.request_use(auth.local_peer_id(), spot, Vector3.UP, 0.0))
		auth.request_select_slot(auth.local_peer_id(), 0)
		auth._host_dig(_main.dwarf.global_position + Vector3(0, -3, 3), 0)
		_main.save_now()
		print("SAVECHECK saved: stations %d, edits %d, copper %d" % [auth.stations.size(), auth.edit_log.size(), ps.inventory.count_of("copper_ingot")])
	else:
		var ok: bool = auth.stations.size() == 1 and auth.edit_log.size() >= 1 and ps.inventory.count_of("copper_ingot") == 9 and _main.seed == 777
		print("SAVECHECK loaded: seed %d, stations %d, edits %d, copper %d" % [_main.seed, auth.stations.size(), auth.edit_log.size(), ps.inventory.count_of("copper_ingot")])
		print("SAVECHECK PASS" if ok else "SAVECHECK FAIL")
	get_tree().quit()
