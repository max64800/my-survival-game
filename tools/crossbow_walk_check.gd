extends SceneTree
## Walk around with the crossbow: aim, shoot, reload, then try every direction (owner, Nov 19: "with the crossbow my
## dwarf stops or only moves one way; another weapon works"). Prints how fast and which way the dwarf moves.
##   godot --audio-driver Dummy --path . --script res://tools/crossbow_walk_check.gd -- claude=crossbow seed=42
var main: Node
var dwarf: Dwarf


func _init() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate()
	main.set("_saving", false)
	root.add_child.call_deferred(main)
	_run.call_deferred()


func _walk(label: String, action: String, frames := 40) -> void:
	var p0 := dwarf.global_position
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)
	var d := dwarf.global_position - p0
	print("WALK %-22s %-13s moved %.2f m  dir %s  fight_mult-ish vel %.2f  dodge %s stagger %.2f busy %.2f reload %.2f aim %s" % [
		label, action, Vector2(d.x, d.z).length(), Vector2(d.x, d.z).normalized().snapped(Vector2.ONE * 0.1),
		Vector2(dwarf.velocity.x, dwarf.velocity.z).length(), dwarf.fight._dodge_t, dwarf.fight.stagger,
		dwarf.fight._busy, dwarf.fight.reload_left, dwarf.fight.aiming()])


func _all_dirs(label: String) -> void:
	for a in ["move_forward", "move_left", "move_back", "move_right"]:
		await _walk(label, a)


func _run() -> void:
	while not main.call("is_ready_to_play"):
		await process_frame
	for i in 120:
		await physics_frame
	Controls.robot = true
	Controls.set_captured(true)
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id())
	dwarf = ps.node
	ps.inventory.add("crossbow_copper", 1)
	ps.inventory.add("bolt_stone", 10)
	ps.inventory.add("sword_stone", 1)
	dwarf.global_position = auth.world.maker.cavern_spawn + Vector3.UP * 0.5
	for i in 60:
		await physics_frame
	await _all_dirs("empty hands")
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_copper":
			auth.request_select_slot(auth.local_peer_id(), i)
	for i in 10:
		await physics_frame
	print("held: ", ps.selected_item(), " weapon_mode ", dwarf.fight.weapon_mode(), " drawn ", ps.weapon_drawn)
	await _all_dirs("crossbow held")
	Input.action_press("use")
	await _all_dirs("crossbow aiming")
	Input.action_press("dig")
	await physics_frame
	await physics_frame
	Input.action_release("dig")
	await _all_dirs("aiming, just shot")
	Input.action_release("use")
	await _all_dirs("after shot")
	var ev := InputEventAction.new()
	ev.action = "refill_lantern"
	ev.pressed = true
	Input.parse_input_event(ev)
	await physics_frame
	print("after R: reload_left %.2f loaded %s" % [dwarf.fight.reload_left, dwarf.fight.loaded])
	await _all_dirs("reloading")
	await _all_dirs("reloaded")
	print("loaded at end: ", dwarf.fight.loaded, " bolts ", ps.inventory.count_of("bolt_stone"))
	quit()
