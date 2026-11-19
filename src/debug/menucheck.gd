extends Node
## Menu check (menu overhaul, owner F187): fills the bag with a few things, then photographs the bag +
## crafting by hand, at a Workbench (gear upgrades on the left) and at a chest.
## Run:  godot --audio-driver Dummy --path . -- menucheck seed=42 shots=/some/folder

var _main: Node
var _shots := "user://menucheck"


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
	print("menucheck: ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var auth: GameAuthority = _main.authority
	var me := auth.local_peer_id()
	var ps := auth.get_player(me)
	var dwarf: Dwarf = _main.dwarf
	_main.hud.set_paused(false)
	for it in [["stone", 46], ["fiber", 14], ["plank_root", 22], ["rootwood", 9], ["rope", 2], ["coal", 6],
			["copper_ore", 7], ["glowcap", 5], ["leather", 3]]:
		ps.inventory.add(it[0], it[1])
	await _wait(0.5)
	_main._set_bag(true)
	await _wait(0.6)
	await _shot("01_bag_by_hand")
	_main._set_bag(false)
	var bench := _put(auth, ps, dwarf, "workbench", 1.5) as Station
	var box_id := _put(auth, ps, dwarf, "chest_small", -1.5) as int
	await _wait(0.5)
	if bench:
		_main.hud.open_station(bench)
		Controls.set_captured(false)
		await _wait(0.6)
		await _shot("02_workbench")
		_main._set_bag(false)
	if box_id >= 0:
		_main.hud.open_box(box_id)
		Controls.set_captured(false)
		await _wait(0.6)
		auth.storage.put(box_id, "stone", 30)  # put in while it's open: the panel must show them by itself
		auth.storage.put(box_id, "copper_ore", 4)
		auth.storage.put(box_id, "glowcap", 6)
		await _wait(1.5)
		await _shot("03_chest")
		_main._set_bag(false)
	get_tree().quit()


## Places a station or chest in front of the dwarf. Returns the Station, or the chest's box id (-1 if not).
func _put(auth: GameAuthority, ps: GameAuthority.PlayerState, dwarf: Dwarf, item: String, side: float) -> Variant:
	ps.inventory.add(item, 1)
	for i in Inventory.SIZE:
		if ps.inventory.get_slot(i).get("id", "") == item:
			if i != 0:
				auth.request_swap(auth.local_peer_id(), i, 0)
			auth.request_select_slot(auth.local_peer_id(), 0)
			break
	var basis := Basis(Vector3.UP, dwarf._yaw)
	var spot := dwarf.global_position - basis.z * 2.8 + basis.x * side
	var floor_p: Vector3 = _main.world.maker.find_floor(spot.x, spot.z, dwarf.global_position.y + 1.5)
	var boxes_before: Array = auth.storage.boxes.keys()
	auth.request_use(auth.local_peer_id(), floor_p, Vector3.UP, dwarf._yaw)
	if item.begins_with("chest"):
		for id in auth.storage.boxes:
			if not id in boxes_before:
				return id
		return -1
	for st: Station in auth.stations.values():
		if st.kind == item:
			return st
	return null
