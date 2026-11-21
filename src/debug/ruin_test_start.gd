extends Node
## The dev "Ruins" test worlds (owner, Nov 21; RuinTests): waits for the ruin to stand, puts the dwarf beside its
## Rebuilding Chest facing it, with a Build Hammer, pickaxe and axe. Opening the chest ("when u open the chest it
## rebuilds instantly") puts one of the chosen material in it: that picks the version (stone/brick, or wood with the
## menu's "Wood" button) and the Builder (instant_ruins) puts the whole ruin up at once, free.
## Dev builds only (DevMenu.enabled()): the buttons never show in the game players get.

const HOTBAR := [["build_hammer", 1], ["pickaxe_copper", 1], ["axe_copper", 1], ["crystal_torch", 10]]

var _main: Node
var _box := -1


func _ready() -> void:
	_main = get_parent()
	_run.call_deferred()


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var auth: GameAuthority = _main.authority
	var e := RuinTests.of_key(_main.ruin_test)
	var ps := auth.get_player(auth.local_peer_id())
	if ps:
		var inv: Inventory = ps.inventory
		for i in Inventory.HOTBAR_SIZE:
			inv.slots[i] = {id = HOTBAR[i][0], count = HOTBAR[i][1]} if i < HOTBAR.size() else {}
		inv.slots[Inventory.equip_index("lantern")] = {id = "lantern_back", count = 1}
		inv.changed.emit()
	_main.hud.show_toast("Ruin test: the %s is being put up…" % e.get("name", "ruin"), 4.0)
	# The ruin carves its space and stands, then adds its Rebuilding Chest to the world record.
	var rec := {}
	var found := -1
	for i in 3600:
		for k in auth.world_state.get("ruins", {}):
			found = int(k)
			rec = auth.world_state.ruins[k]
		if found >= 0 and not auth.storage.get_box(found).is_empty():
			break
		await get_tree().process_frame
	if rec.is_empty():
		_main.hud.show_toast("Ruin test: the ruin didn't appear (see the log)", 6.0)
		push_warning("RUIN_TEST no Rebuilding Chest after 60 s")
		queue_free()
		return
	_box = found
	# Beside the chest, on the path side, looking at it.
	var chest: Node3D = auth.storage.get_box(_box).node
	var origin: Vector3 = rec.origin
	var basis := Basis(Vector3.UP, int(rec.turn) * PI / 2.0)
	var out := basis * Vector3(0, 0, 1)  # (the ruin's front)
	var side := chest.global_position - origin
	side.y = 0.0
	var stand := chest.global_position + out * 1.6 - side.normalized().slide(out).normalized() * 0.6
	var fl: Vector3 = _main.world.maker.find_floor(stand.x, stand.z, stand.y + 2.0)
	if fl != Vector3.INF:
		stand = fl
	var dwarf: Dwarf = _main.dwarf
	dwarf.global_position = stand + Vector3.UP * 0.3
	dwarf.velocity = Vector3.ZERO
	var dir := chest.global_position - (dwarf.global_position + Vector3.UP * 1.0)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = 0.0
	dwarf.model.rotation.y = dwarf._yaw
	_main.world.maker.spawn_point = dwarf.global_position  # (wake here after dying)
	var version: String = "wood" if _main.ruin_test_wood else String(e.get("hard", "Stone")).to_lower()
	_main.hud.show_toast("Ruin test: open the Rebuilding Chest (E) to rebuild the %s in %s at once." % [e.get("name", "ruin"), version], 8.0)
	print("RUIN_TEST %s at the chest %d %s (%s)" % [_main.ruin_test, _box, dwarf.global_position, version])
	for a in OS.get_cmdline_user_args():  # robots: open the chest by itself, picture before and after, then quit
		if a.begins_with("shots="):
			await _robot_shots(a.trim_prefix("shots="), origin, out)


func _process(_delta: float) -> void:
	if _box < 0:
		return
	var panel: Node = _main.hud.box_panel
	if panel.visible and panel.box_id == _box:
		_rebuild()


## One of the chosen material into the chest: it picks the version and the rebuild starts (Builder.ruin_chest_changed).
func _rebuild() -> void:
	var auth: GameAuthority = _main.authority
	var rec: Dictionary = auth.world_state.get("ruins", {}).get(str(_box), {})
	var mat := BlueprintLibrary.WOOD if _main.ruin_test_wood else Builder.ruin_hard(rec)
	auth.storage.put(_box, mat, 1)
	print("RUIN_TEST chest opened: rebuilding in %s" % mat)
	_box = -1
	set_process(false)


func _robot_shots(folder: String, origin: Vector3, out: Vector3) -> void:
	var cam_at := origin + out * 22.0 + Vector3.UP * 9.0
	await get_tree().create_timer(4.0).timeout
	await _shot(folder, "ruintest_%s_before.png" % _main.ruin_test, cam_at, origin + Vector3.UP * 3.0)
	_main.hud.open_box(_box)
	var t0 := Time.get_ticks_msec()
	for i in 600:
		if _main.authority.builder.sites.is_empty() and i > 10:
			break
		await get_tree().process_frame
	print("RUIN_TEST rebuilt in %d ms; done = %s" % [Time.get_ticks_msec() - t0, _main.authority.world_state.get("ruins", {}).values().map(func(r): return r.get("done", false))])
	_main.hud.box_panel.visible = false
	_main.hud._bag_panel.visible = false
	await get_tree().create_timer(2.0).timeout
	await _shot(folder, "ruintest_%s_after.png" % _main.ruin_test, cam_at, origin + Vector3.UP * 3.0)
	get_tree().quit()


func _shot(folder: String, file: String, at: Vector3, look: Vector3) -> void:
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.global_position = at
	cam.look_at(look)
	cam.make_current()
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	print("RUIN_TEST shot ", _main.take_screenshot(folder.path_join(file)))
	cam.queue_free()
