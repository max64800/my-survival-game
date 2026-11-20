extends Node
## "Test the dungeon" (owner, Nov 19): the dev-only start menu button makes a new world, then this puts the dwarf on
## the cave floor in front of the first dungeon's door, facing it, wearing and carrying the best gear there is.
## Dev builds only (DevMenu.enabled()): the button never shows in the game players get.
## (A pickaxe on the hotbar too, owner Nov 19: the one in the pickaxe slot alone couldn't be swung at boulders.)

const WEAR := {pickaxe = "pickaxe_silver", weapon = "sword_silver", shield = "shield_silver", lantern = "lantern_back",  # (the back lantern leaves the shield hand free)
	head = "helm_copper", chest = "mail_copper", legs = "greaves_copper", feet = "boots_copper"}
const CARRY := [["pickaxe_silver", 1], ["crossbow_silver", 1], ["bolt_metal", 60], ["mace_silver", 1], ["spear_silver", 1], ["axe_silver", 1],
	["bandage", 20], ["crystal_torch", 10]]

var _main: Node


func _ready() -> void:
	_main = get_parent()
	_run.call_deferred()


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var maker: CaveMaker = _main.world.maker
	if maker.dungeons.is_empty():
		_main.hud.show_toast("This world has no dungeon (old cave layout)", 4.0)
		queue_free()
		return
	var d: Dictionary = maker.dungeons[0]
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	if ps:
		var inv: Inventory = ps.inventory
		for slot in WEAR:
			inv.slots[Inventory.equip_index(slot)] = {id = WEAR[slot], count = 1}
		for i in Inventory.HOTBAR_SIZE:
			inv.slots[i] = {}  # the starting tools are replaced by the silver ones
		for it in CARRY:
			inv.add(it[0], it[1])
		inv.changed.emit()
		ps.fuel = GameAuthority.MAX_FUEL
	# On the cave floor 5 m out from the round door, looking at it.
	var mouth: Vector2 = d.map.mouth
	var stand := DungeonMap.to_world(d, Vector3(mouth.x, 0.0, mouth.y + float(d.entry_out) + 5.0))
	var fl := maker.find_floor(stand.x, stand.z, stand.y + 3.0)
	if fl != Vector3.INF:
		stand = fl
	var dwarf: Dwarf = _main.dwarf
	# Hold him still until the rock there has loaded (else he falls through and the game puts him back at the start).
	dwarf.set_physics_process(false)
	dwarf.global_position = stand + Vector3.UP * 0.3
	dwarf.velocity = Vector3.ZERO
	_main.hud.show_toast("Dungeon test: going to Mossgate Hold…", 3.0)
	for i in 1200:
		if _main.world.terrain.is_area_meshed(AABB(stand - Vector3.ONE * 8.0, Vector3.ONE * 16.0)) and _main.world.is_ready_at(stand, 8.0):
			break
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	dwarf.global_position = stand + Vector3.UP * 0.3
	dwarf.velocity = Vector3.ZERO
	dwarf.set_physics_process(true)
	var door := DungeonMap.to_world(d, Vector3(mouth.x, 1.2, mouth.y))
	var dir := door - (dwarf.global_position + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = 0.0
	dwarf.model.rotation.y = dwarf._yaw
	_main.hud.show_toast("Dungeon test: Mossgate Hold is straight ahead. Best gear on.", 5.0)
	print("DUNGEON_TEST at the door ", dwarf.global_position)
	for a in OS.get_cmdline_user_args():  # robots: one picture, then quit
		if a.begins_with("shots="):
			await get_tree().create_timer(6.0).timeout
			await RenderingServer.frame_post_draw
			var fwd := Vector3(-sin(dwarf._yaw), 0.0, -cos(dwarf._yaw))
			print("DUNGEON_TEST now at ", dwarf.global_position, ", %.1f m from the door; 8 m ahead is '%s'" % [
				dwarf.global_position.distance_to(door), DungeonMap.space_at(d, dwarf.global_position + fwd * 8.0 + Vector3.UP)])
			print("DUNGEON_TEST shot ", _main.take_screenshot(a.trim_prefix("shots=").path_join("dungeon_test.png")))
			var face := DungeonMap.mouth_z(d.map)
			for v in [["door_close", Vector3(34.0, 0.3, face + 4.5), Vector3(34.0, 1.3, face)],
					["corridor", Vector3(34.0, 0.3, face - 1.0), Vector3(34.0, 1.4, 44.0)],
					["gate_hall", Vector3(36.0, 0.3, 45.0), Vector3(32.0, 1.4, 37.0)],
					["doorway", Vector3(30.0, 0.3, 38.0), Vector3(34.0, 1.2, 46.0)],
					["pillar_hall", Vector3(34.0, 0.3, 29.0), Vector3(36.0, 1.0, 19.0)],
					["bridge", Vector3(31.0, 0.3, 6.0), Vector3(40.0, 0.6, 6.0)],
					["bridge_gap", Vector3(35.0, 0.3, 3.2), Vector3(38.4, 0.0, 6.0)],  # (owner's 2nd play, Nov 20)
					["crushers", Vector3(55.6, 0.3, 7.4), Vector3(53.0, 1.2, 5.6)],
					["cracked_wall", Vector3(65.0, 0.3, 39.5), Vector3(65.0, 1.2, 36.0)]]:
				dwarf.set_physics_process(false)
				dwarf.global_position = DungeonMap.to_world(d, v[1])
				var look: Vector3 = DungeonMap.to_world(d, v[2]) - (dwarf.global_position + Vector3.UP * 1.5)
				dwarf._yaw = atan2(-look.x, -look.z)
				dwarf._pitch = atan2(look.y, Vector2(look.x, look.z).length())
				dwarf.model.rotation.y = dwarf._yaw
				await get_tree().create_timer(3.0).timeout
				await RenderingServer.frame_post_draw
				print("DUNGEON_TEST shot ", _main.take_screenshot(a.trim_prefix("shots=").path_join("dungeon_%s.png" % v[0])))
			print("DUNGEON_TEST monsters alive: %d" % _main.authority.monsters.monsters.size())
			get_tree().quit()
	queue_free()
