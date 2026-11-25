extends Node
## "Test the dungeon" (owner, Nov 19): the dev-only start menu button makes a new world, then this puts the dwarf on
## the cave floor in front of the first dungeon's door, facing it, wearing and carrying copper gear (owner, Nov 20: silver was too strong).
## Dev builds only (DevMenu.enabled()): the button never shows in the game players get.
## (A pickaxe on the hotbar too, owner Nov 19: the one in the pickaxe slot alone couldn't be swung at boulders.)

const WEAR := {pickaxe = "pickaxe_copper", weapon = "sword_copper", shield = "shield_copper", lantern = "lantern_back",  # (the back lantern leaves the shield hand free)
	head = "helm_copper", chest = "mail_copper", legs = "greaves_copper", feet = "boots_copper"}
## Keys 1-9 (owner, Nov 21: "I only have the spear and the mace": the worn sword only came out with F, so every
## weapon now has its own key too, the two-handed great axe and great maul as well; bolts, the wood axe and the
## bombs go in the bag: the crossbow takes its bolts from there).
const HOTBAR := [["pickaxe_copper", 1], ["sword_copper", 1], ["mace_copper", 1], ["spear_copper", 1], ["crossbow_copper", 1],
	["axe_2h_copper", 1], ["mace_2h_copper", 1], ["bandage", 20], ["crystal_torch", 10]]
const BAG := [["bolt_metal", 60], ["axe_copper", 1], ["spore_bomb", 10], ["blasting_pod", 10]]
## Food and drink for a long dungeon run (owner, Nov 25: "give me food and 15 levels anytime I start dev dungeon").
const FOOD := [["dish_hearth_stew", 10], ["dish_miners_pie", 10], ["dish_beetle_roast", 10], ["drink_moss_ale", 10],
	["drink_bellcap_juice", 10]]
const LEVEL := 15  ## the dwarf starts at level 15 (owner, Nov 25), plus the 15 test perk points below

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
		ps.progress.level = maxi(ps.progress.level, LEVEL)
		ps.progress.bonus_points = 15  # perk points to try perks in the dungeon (owner, Nov 20)
		var inv: Inventory = ps.inventory
		for slot in WEAR:
			inv.slots[Inventory.equip_index(slot)] = {id = WEAR[slot], count = 1}
		for i in Inventory.HOTBAR_SIZE:  # the starting tools are replaced by the copper ones (owner, Nov 20: silver made the dungeon far too easy)
			inv.slots[i] = {id = HOTBAR[i][0], count = HOTBAR[i][1]} if i < HOTBAR.size() else {}
		inv.hand_slots_out()  # the worn pickaxe, sword and shield sit in the hotbar/bag with the worn mark (F825)
		for it in BAG + FOOD:
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
	var dungeon_name := String(d.map.name)  # (Mossgate Hold, or Lampwick Drift for the menu's Dungeon 2)
	_main.hud.show_toast("Dungeon test: going to %s…" % dungeon_name, 3.0)
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
	_main.hud.show_toast("Dungeon test: %s is straight ahead. Copper gear on." % dungeon_name, 5.0)
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
			var views := LAMPWICK_VIEWS if d.id == "lampwick" else PELL_VIEWS if d.id == "pell" else MOSSPROP_VIEWS if d.id == "mossprop" else HALD_VIEWS if d.id == "hald" else [["door_close", Vector3(34.0, 0.3, face + 4.5), Vector3(34.0, 1.3, face)],
					["corridor", Vector3(34.0, 0.3, face - 1.0), Vector3(34.0, 1.4, 44.0)],
					["gate_hall", Vector3(36.0, 0.3, 45.0), Vector3(32.0, 1.4, 37.0)],
					["doorway", Vector3(30.0, 0.3, 38.0), Vector3(34.0, 1.2, 46.0)],
					["pillar_hall", Vector3(34.0, 0.3, 29.0), Vector3(36.0, 1.0, 19.0)],
					["bridge", Vector3(31.0, 0.3, 6.0), Vector3(40.0, 0.6, 6.0)],
					["bridge_gap", Vector3(35.0, 0.3, 3.2), Vector3(38.4, 0.0, 6.0)],  # (owner's 2nd play, Nov 20)
					["pack_door", Vector3(52.5, 0.3, 6.6), Vector3(56.0, 1.2, 6.0)],  # (owner's 3rd play, Nov 20)
					["crushers", Vector3(61.5, 0.3, 7.5), Vector3(57.2, 2.4, 6.0)],
					["lever", Vector3(73.2, 0.3, 40.6), Vector3(71.0, 1.0, 38.2)],
					["old_ceiling", Vector3(34.0, 0.3, 45.0), Vector3(34.0, 4.0, 38.0)],
					["cracked_wall", Vector3(65.0, 0.3, 39.5), Vector3(65.0, 1.2, 36.0)]]
			for v in views:
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
			if "drips" in OS.get_cmdline_user_args():
				await _walk_drips(d)
			if "climb" in OS.get_cmdline_user_args() and d.id == "lampwick":
				await _walk_rails(d)
			if "climb" in OS.get_cmdline_user_args() and d.id == "pell":
				await _pell_walks(d)
			get_tree().quit()
	queue_free()


## The Tomb of Hald Ironbrow's robot pictures (-- dungeontest dungeon5 shots=<folder>): [name, stand, look at].
const HALD_VIEWS := [
	["hd_gate", Vector3(42.0, 0.3, 61.0), Vector3(42.0, 1.5, 55.0)],
	["hd_candles", Vector3(35.0, 0.3, 58.0), Vector3(25.0, 1.2, 58.0)],
	["hd_wardens", Vector3(20.0, 0.3, 41.0), Vector3(20.0, 2.0, 31.0)],
	["hd_grand_stair", Vector3(20.0, 0.3, 31.0), Vector3(20.0, -6.0, 21.0)],
	["hd_broken_stair", Vector3(37.0, 0.3, 36.0), Vector3(47.0, 4.5, 36.0)],
	["hd_names", Vector3(20.0, -7.7, 19.0), Vector3(20.0, -6.0, 9.0)],
	["hd_bridge", Vector3(27.0, -7.7, 14.0), Vector3(40.0, -8.0, 14.0)],
	["hd_tomb", Vector3(44.0, -7.7, 37.0), Vector3(49.0, -7.0, 43.0)]]


## Mossprop Workings' robot pictures (-- dungeontest dungeon4 shots=<folder>): [name, stand (map metres), look at].
const MOSSPROP_VIEWS := [
	["mp_camp", Vector3(31.0, 0.3, 48.0), Vector3(28.0, 6.0, 30.0)],
	["mp_tower", Vector3(40.0, 0.3, 40.0), Vector3(30.0, 6.0, 26.0)],
	["mp_deck2", Vector3(28.0, 5.3, 25.0), Vector3(40.0, 5.0, 27.0)],
	["mp_slide", Vector3(36.0, 10.3, 25.0), Vector3(36.0, 2.0, 44.0)],
	["mp_warden", Vector3(37.0, 10.3, 22.0), Vector3(37.0, 11.0, 13.0)],
	["mp_warden_side", Vector3(41.0, 10.3, 21.0), Vector3(36.5, 10.8, 18.0)]]  # (F548: his shield up, seen from the side)


## Old Pell's Diggings' robot pictures (-- dungeontest dungeon3 shots=<folder>): [name, stand (map metres), look at].
const PELL_VIEWS := [
	["pl_door", Vector3(36.0, 0.3, 68.5), Vector3(36.0, 1.3, 64.0)],
	["pl_hut", Vector3(36.0, 0.3, 51.0), Vector3(38.0, 1.2, 45.5)],
	["pl_gate", Vector3(36.0, 0.3, 48.0), Vector3(40.0, 1.2, 48.0)],
	["pl_shed", Vector3(31.0, 0.3, 48.0), Vector3(25.0, 0.6, 45.0)],
	["pl_tripwire", Vector3(30.5, 0.3, 49.0), Vector3(29.1, 0.3, 46.0)],
	["pl_shaft_top", Vector3(25.0, 0.3, 47.6), Vector3(25.0, -3.0, 45.0)],
	["pl_landing", Vector3(28.6, -5.7, 41.0), Vector3(24.5, -3.0, 45.5)],
	["pl_cave_in", Vector3(26.0, -5.7, 39.0), Vector3(26.0, -4.6, 31.0)],
	["pl_sorting", Vector3(26.0, -5.7, 29.0), Vector3(25.0, -5.4, 23.0)],
	["pl_den", Vector3(15.0, -5.7, 26.0), Vector3(10.0, -5.0, 25.0)],
	["pl_gallery", Vector3(32.6, -5.7, 26.0), Vector3(38.0, -6.0, 24.0)],
	["pl_crushers", Vector3(40.0, -5.7, 27.0), Vector3(40.0, -4.0, 31.0)],
	["pl_shrine", Vector3(37.0, -5.7, 34.0), Vector3(32.0, -5.0, 36.0)],
	["pl_dig", Vector3(40.0, -5.7, 40.6), Vector3(41.0, -4.8, 46.0)],
	["pl_lift", Vector3(42.0, -5.7, 48.6), Vector3(45.8, -3.0, 47.4)],
	["pl_lift_top", Vector3(41.0, 0.3, 49.0), Vector3(41.2, 1.0, 46.2)],
	["pl_squeeze", Vector3(25.0, -5.7, 38.5), Vector3(25.0, -5.0, 33.0)],
	["pl_push_walls", Vector3(32.8, -5.7, 21.0), Vector3(37.0, -5.0, 20.6)],
	["pl_winch", Vector3(42.4, 0.3, 49.4), Vector3(45.0, 1.6, 47.0)],
]


## Old Pell's robot walks (-- dungeontest dungeon3 climb): the dwarf really climbs the shaft's ladder, rides the rope
## lift up, squeezes past the spear walls and walks the gallery's strip past the push walls (physics on).
func _pell_walks(d: Dictionary) -> void:
	var dwarf: Dwarf = _main.dwarf
	var auth: GameAuthority = _main.authority
	var me: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id())
	var db := DungeonBuild.instance
	var put := func(at: Vector3, look: Vector3) -> void:
		dwarf.set_physics_process(false)
		dwarf.global_position = DungeonMap.to_world(d, at)
		dwarf.velocity = Vector3.ZERO
		var dir: Vector3 = DungeonMap.to_world(d, look) - DungeonMap.to_world(d, at)
		dwarf._yaw = atan2(-dir.x, -dir.z)
		dwarf.model.rotation.y = dwarf._yaw
	var report := func(what: String, hp0: float) -> void:
		var q := DungeonMap.to_local(d, dwarf.global_position)
		print("PELL_WALK %s: at (%.1f, %.2f, %.1f) in '%s', lost %.0f health" % [what, q.x, q.y, q.z,
			DungeonMap.space_at(d, dwarf.global_position + Vector3.UP), hp0 - me.vitals.health])
	# 1. Up the shaft's ladder (hold forward against it).
	put.call(Vector3(24.75, DungeonMap.DOWN + 0.3, 45.4), Vector3(23.0, DungeonMap.DOWN + 0.3, 45.4))
	await get_tree().create_timer(0.5).timeout
	dwarf.set_physics_process(true)
	var hp0: float = me.vitals.health
	print("PELL_WALK at the shaft's foot: on the ladder = %s (robots can't hold keys: the climb itself is the old ladder code)" % dwarf._ladder_here())
	dwarf.global_position = DungeonMap.to_world(d, Vector3(24.75, -1.0, 45.4))
	print("PELL_WALK half way up: on the ladder = %s" % dwarf._ladder_here())
	dwarf.global_position = DungeonMap.to_world(d, Vector3(24.75, 0.4, 46.3))
	print("PELL_WALK at the top, stepping off: on the ladder = %s" % dwarf._ladder_here())
	# 2. The rope lift: stand on it, E, ride up.
	var lift := -1
	for id in db.things:
		if db.things[id].kind == "lift":
			lift = id
	put.call(Vector3(45.0, DungeonMap.DOWN + 0.6, 47.2), Vector3(45.0, DungeonMap.DOWN + 0.6, 49.0))
	await get_tree().create_timer(0.5).timeout
	dwarf.set_physics_process(true)
	await get_tree().create_timer(0.5).timeout
	hp0 = me.vitals.health
	db.request_use(auth.local_peer_id(), lift)
	await get_tree().create_timer(MineTraps.LIFT_TIME + 1.5).timeout
	report.call("rode the rope lift", hp0)
	# 3. Through the spear walls' squeeze (walking, whenever).
	put.call(Vector3(25.0, DungeonMap.DOWN + 0.3, 37.5), Vector3(25.0, DungeonMap.DOWN + 0.3, 30.0))
	await get_tree().create_timer(0.5).timeout
	dwarf.set_physics_process(true)
	hp0 = me.vitals.health
	dwarf.bot_move = Vector2(0, -1)
	await get_tree().create_timer(2.2).timeout
	dwarf.bot_move = Vector2.ZERO
	report.call("through the spear squeeze", hp0)
	# 4. Along the gallery's north strip past the push walls (god mode off: you may die).
	me.vitals.health = me.vitals.max_health()
	put.call(Vector3(33.0, DungeonMap.DOWN + 0.3, 21.0), Vector3(41.0, DungeonMap.DOWN + 0.3, 21.0))
	await get_tree().create_timer(0.5).timeout
	dwarf.set_physics_process(true)
	hp0 = me.vitals.health
	dwarf.bot_move = Vector2(0, -1)
	await get_tree().create_timer(1.6).timeout
	dwarf.bot_move = Vector2.ZERO
	await get_tree().create_timer(1.5).timeout
	report.call("along the push walls' strip", hp0)


## Lampwick Drift's robot pictures (-- dungeontest dungeon2 shots=<folder>): [name, stand (map metres), look at].
const LAMPWICK_VIEWS := [
	["lw_door", Vector3(26.0, 0.3, 68.5), Vector3(26.0, 1.3, 64.0)],
	["lw_lamp_room", Vector3(25.0, 0.3, 51.0), Vector3(27.6, 1.2, 47.0)],
	["lw_tripwire", Vector3(26.0, 0.3, 45.0), Vector3(25.0, 0.4, 41.0)],
	["lw_carts_foot", Vector3(23.6, 0.3, 36.0), Vector3(19.0, 2.0, 24.0)],
	["lw_carts_top", Vector3(19.0, 3.3, 20.0), Vector3(19.0, 1.0, 34.0)],
	["lw_tool_store", Vector3(15.0, 3.3, 20.5), Vector3(12.0, 3.4, 17.5)],
	["lw_drips", Vector3(20.0, 3.3, 17.5), Vector3(20.0, 6.0, 10.0)],
	["lw_gallery", Vector3(22.5, 3.3, 7.0), Vector3(15.0, 4.0, 3.0)],
	["lw_vault", Vector3(16.0, 3.3, 3.0), Vector3(11.0, 3.4, 3.0)],
	["lw_shaft", Vector3(26.6, 3.3, 4.0), Vector3(33.0, 4.4, 4.0)],
	["lw_copper", Vector3(37.0, 3.3, 4.0), Vector3(42.0, 3.4, 2.5)],
	["lw_props", Vector3(42.0, 3.3, 7.0), Vector3(42.0, 4.0, 15.0)],
	["lw_rest", Vector3(39.0, 3.3, 14.0), Vector3(35.0, 3.5, 13.0)],
	["lw_office", Vector3(42.0, 3.3, 18.6), Vector3(44.0, 4.0, 25.0)],
	["lw_back_rails", Vector3(42.0, 3.3, 27.0), Vector3(42.0, 1.0, 40.0)],
	["lw_gate", Vector3(31.0, 0.3, 48.0), Vector3(28.0, 1.2, 48.0)],
]


## Robots (Lampwick, Nov 20): the dwarf really walks (his own legs) up the Cart Junction's middle lane and down the
## Back Rails, and the game says where he got to (map metres).
func _walk_rails(d: Dictionary) -> void:
	var dwarf: Dwarf = _main.dwarf
	for id in DungeonBuild.instance.things:  # (the carts come down first, so the climb isn't cut short by one)
		if DungeonBuild.instance.things[id].kind in ["cart", "wedge"]:
			DungeonBuild.instance._break(id)
	await get_tree().create_timer(4.0).timeout
	for w in [["up the cart lanes", Vector3(19.0, 0.4, 34.6), Vector3(19.0, 0.4, 10.0), 3.2],
			["down the back rails", Vector3(42.0, 3.5, 25.0), Vector3(42.0, 0.4, 60.0), 5.0],
			["to the healing basin", Vector3(41.5, 3.5, 14.0), Vector3(35.0, 3.5, 13.0), 3.0]]:
		dwarf.set_physics_process(false)
		dwarf.global_position = DungeonMap.to_world(d, w[1])
		dwarf.velocity = Vector3.ZERO
		var look: Vector3 = DungeonMap.to_world(d, w[2]) - DungeonMap.to_world(d, w[1])
		dwarf._yaw = atan2(-look.x, -look.z)
		dwarf.model.rotation.y = dwarf._yaw
		await get_tree().create_timer(0.5).timeout
		dwarf.set_physics_process(true)
		dwarf.bot_move = Vector2(0, -1)
		var me: GameAuthority.PlayerState = _main.authority.get_player(_main.authority.local_peer_id())
		var t := 0.0
		while t < float(w[3]):  # (kept alive: the rats chewing on the robot mustn't end the walk)
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			me.vitals.health = me.vitals.max_health()
		dwarf.bot_move = Vector2.ZERO
		var q := DungeonMap.to_local(d, dwarf.global_position)
		var ps: GameAuthority.PlayerState = _main.authority.get_player(_main.authority.local_peer_id())
		print("RAIL_WALK %s: from %s to (%.1f, %.2f, %.1f), in '%s', health %.0f" % [w[0], w[1], q.x, q.y, q.z,
			DungeonMap.space_at(d, dwarf.global_position + Vector3.UP), ps.vitals.health])


## Robots (owner's 3rd play, Nov 20: "stalactites don't drop even when I'm close"): the dwarf really walks (his own
## legs, physics on) past every stalactite, 0.5 m to its side, and the game says whether it fell and hurt him.
func _walk_drips(d: Dictionary) -> void:
	var db := DungeonBuild.instance
	var dwarf: Dwarf = _main.dwarf
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	for id in db.things:
		var th: Dictionary = db.things[id]
		if th.kind != "drip":
			continue
		var c: Vector3 = th.centre
		var q := DungeonMap.to_local(d, c)
		var start := DungeonMap.to_world(d, Vector3(q.x - 4.0, 0.4, q.z + 0.5))
		if DungeonMap.space_at(d, start + Vector3.UP) == "":
			start = DungeonMap.to_world(d, Vector3(q.x + 4.0, 0.4, q.z + 0.5))
		var target := DungeonMap.to_world(d, Vector3(q.x, 0.4, q.z + 0.5))
		dwarf.set_physics_process(false)
		dwarf.global_position = start
		dwarf.velocity = Vector3.ZERO
		var look := target - start
		dwarf._yaw = atan2(-look.x, -look.z)
		dwarf.model.rotation.y = dwarf._yaw
		await get_tree().create_timer(0.5).timeout
		ps.vitals.health = ps.vitals.max_health()
		var hp0: float = ps.vitals.health
		dwarf.set_physics_process(true)
		dwarf.bot_move = Vector2(0, -1)
		var t := 0.0
		var fell_at := -1.0
		var closest := 99.0
		while t < 2.5:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			var p := dwarf.global_position
			closest = minf(closest, Vector2(p.x - c.x, p.z - c.z).length())
			if fell_at < 0.0 and db.is_broken(id):
				fell_at = t
		dwarf.bot_move = Vector2.ZERO
		await get_tree().create_timer(1.2).timeout
		print("DRIP_WALK %d (%s, %s): %s, closest %.2f m, dwarf y %.2f vs landing %.2f / centre %.2f, hurt %.0f" % [id,
			th.model.get_file(), DungeonMap.space_at(d, c), ("fell at %.2f s" % fell_at) if fell_at >= 0.0 else "DID NOT FALL",
			closest, dwarf.global_position.y, float(th.landing), c.y, hp0 - ps.vitals.health])
		ps.vitals.health = hp0
