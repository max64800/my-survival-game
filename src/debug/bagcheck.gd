extends Node
## Bag check (F825, F826, owner Nov 23): photos of the new bag window (Gear panel left, bag middle, crafting right),
## the gold E on worn things, the putting-on ring half full, and a slot thrown away with Q.
## Run:  godot --audio-driver Dummy --path . -- bagcheck claude=bagui seed=42 shots=<folder>

var _main: Node
var _shots := "user://bagcheck"


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
	print("BAGCHECK shot ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 150.0:
		await _wait(0.25)
		waited += 0.25
	_main.hud.set_paused(false)
	var auth: GameAuthority = _main.authority
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id())
	var inv := ps.inventory
	inv.hand_slots_out()
	for id in ["sword_copper", "shield_stone", "sword_stone", "helm_copper", "mail_copper", "boots_leather", "lantern"]:
		inv.add(id, 1)
	inv.add("stone", 80)
	inv.add("coal", 12)
	inv.add("copper_ingot", 4)
	inv.add("dish_hollowcap_stew", 2)
	for i in Inventory.HOTBAR_SIZE:
		var kind := Inventory.equip_slot_for(inv.get_slot(i).get("id", ""))
		if kind in ["weapon", "shield", "pickaxe"] and inv.equipped(kind) == "":
			inv.set_worn(i, true)
	print("BAGCHECK worn weapon=", inv.equipped("weapon"), " shield=", inv.equipped("shield"), " pickaxe=", inv.equipped("pickaxe"))
	_main.hud.set_bag_open(true)
	await _wait(1.0)
	await _shot("01_bag")
	# F826: the ring, half full, on the stone sword
	var sw := -1
	for i in Inventory.SIZE:
		if inv.get_slot(i).get("id", "") == "sword_stone":
			sw = i
	auth.ask_equip(sw)
	await _wait(0.22)
	await _shot("02_ring")
	await _wait(0.6)
	print("BAGCHECK stone sword worn after the ring: ", inv.is_worn(sw), " (copper sword now: ", inv.equipped("weapon"), ")")
	# F825: Q throws the coal away
	var coal := -1
	for i in Inventory.SIZE:
		if inv.get_slot(i).get("id", "") == "coal":
			coal = i
	auth.ask_throw(coal)
	await _wait(0.6)
	print("BAGCHECK coal slot after Q: ", inv.get_slot(coal), " drops: ", auth.drops_root.get_child_count())
	await _wait(2.0)
	print("BAGCHECK 2 s later, coal back in the bag? ", inv.count_of("coal") if inv.has_method("count_of") else inv.get_slot(coal))
	await _shot("03_after_throw")
	print("BAGCHECK done")
	get_tree().quit()
