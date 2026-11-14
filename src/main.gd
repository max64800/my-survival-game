extends Node3D
## Starts a game: makes the cave, the glow, the referee, the dwarf(s) and the screen.
##
## With no extras it shows the start menu. Command-line extras (after "--"):
##   seed=1234          a specific cave
##   host               host a direct (IP) co-op game right away
##   join=127.0.0.1     join a direct co-op game right away
##   port=24570         network port for host/join
##   autopilot          scripted solo test run (see src/debug/autopilot.gd)
##   netcheck           scripted co-op test run (see src/debug/netcheck.gd)
##   shots=folder       where autopilot screenshots go

var seed := 0
var world: World
var glow: GlowField
var authority: GameAuthority
var dwarf: Dwarf
var hud: Hud
var session: Session
var players_root: Node3D
var _ready_to_play := false
var _menu: Node
var player_slots := {1: 0}
var _monsters := true
var _saving := true  ## off for robot test runs
var _autosave := 300.0
var _jungle_kit := false  ## "-- jungle": start at the jungle gate with copper tools (for testing)
var _loaded := {}  ## the save we started from (friends' dwarfs are restored from it when they rejoin)  ## peer id -> player number (0 = host, 1-3 = friends)


func _ready() -> void:
	Controls.setup()
	seed = randi() % 1000000
	session = Session.new()
	session.name = "Session"
	add_child(session)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	session.connection_failed.connect(_on_connection_failed)

	var mode := "menu"
	var address := ""
	var port := Session.DEFAULT_PORT
	var debug_script := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("seed="):
			seed = arg.trim_prefix("seed=").to_int()
			if mode == "menu":
				mode = "solo"
		elif arg == "host":
			mode = "host"
		elif arg.begins_with("join="):
			mode = "join"
			address = arg.trim_prefix("join=")
		elif arg.begins_with("port="):
			port = arg.trim_prefix("port=").to_int()
		elif arg == "autopilot":
			debug_script = "res://src/debug/autopilot.gd"
			_saving = false
			_monsters = false  # random critters at the start would eat the robot's swings; it spawns its own
			if mode == "menu":
				mode = "solo"
		elif arg == "netcheck":
			debug_script = "res://src/debug/netcheck.gd"
			_monsters = false
			_saving = false
		elif arg == "nomonsters":
			_monsters = false
		elif arg == "jungle":
			_jungle_kit = true
			if mode == "menu":
				mode = "solo"
		elif arg == "continue":
			mode = "continue"
		elif arg.begins_with("art="):
			DwarfModel.art = arg.trim_prefix("art=")
		elif arg == "lookdev":
			debug_script = "res://src/debug/lookdev.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "artpreview":
			debug_script = "res://src/debug/artpreview.gd"
			_saving = false
		elif arg.begins_with("savecheck"):
			debug_script = "res://src/debug/savecheck.gd"
	if debug_script != "":
		var dbg: Node = load(debug_script).new()
		dbg.name = "Debug"
		add_child(dbg)

	match mode:
		"menu":
			_show_menu()
		"solo":
			start_game(seed)
		"continue":
			var data := SaveGame.newest()
			if data.is_empty():
				start_game(seed)
			else:
				start_game(data.seed, {}, data)
		"host":
			start_game(seed)
			session.host_direct(port)
		"join":
			_show_menu()
			_menu.call("set_status", "Connecting to %s…" % address)
			session.join_direct(address, port)


## What happened when a monster's attack reached us (shown briefly at the top of the screen).
func _on_defended(r: Dictionary) -> void:
	if dwarf and r.result == "hit":
		dwarf.model.react("hit")
	match r.result:
		"block":
			hud.show_toast("Blocked %s (−%d)" % [r.name, roundi(r.damage)], 1.2)
		"dodge":
			hud.show_toast("Dodged!", 1.0)
		"hit":
			hud.show_toast("Hit by %s (−%d)" % [r.name, roundi(r.damage)], 1.2)
	if r.has("ailment"):
		var what: String = {"poison": "You are poisoned!", "burn": "You are burning!", "chill": "You are chilled!", "frozen": "You are frozen!"}.get(r.ailment, "")
		hud.show_toast(what + "  (" + r.name + ")", 2.0)


func _show_menu() -> void:
	_menu = load("res://src/ui/start_menu.gd").new()
	add_child(_menu)
	_menu.connect("play_alone", func(s: int): _close_menu(); start_game(s if s > 0 else seed))
	_menu.connect("continue_game", func(data: Dictionary): _close_menu(); start_game(data.seed, {}, data))
	_menu.connect("host_direct", func(s: int):
		_close_menu()
		start_game(s if s > 0 else seed)
		session.host_direct())
	_menu.connect("join_direct", func(addr: String):
		_menu.call("set_status", "Connecting to %s…" % addr)
		session.join_direct(addr))
	_menu.connect("host_steam", func(s: int):
		if session.host_steam():
			_close_menu()
			start_game(s if s > 0 else seed))
	session.status_changed.connect(func(t: String): if _menu: _menu.call("set_status", t))


func _close_menu() -> void:
	if _menu:
		_menu.queue_free()
		_menu = null


## Builds the whole game. `snap` is the host's catch-up data when joining a friend;
## `save` is a save file's data when continuing.
func start_game(p_seed: int, snap: Dictionary = {}, save: Dictionary = {}) -> void:
	seed = p_seed
	print("Cave seed: ", seed)
	_make_environment()
	world = World.new()
	world.name = "World"
	add_child(world)
	world.setup(seed)

	glow = GlowField.new()
	glow.name = "Glow"
	add_child(glow)
	glow.build(GlowPlacer.place(world.maker))

	var clutter := Clutter.new()  # pebbles, rocks, bones, twigs on the floors (only looks)
	clutter.name = "Clutter"
	add_child(clutter)
	clutter.build(world.maker, world)

	var pf := PoiField.new()
	pf.name = "Pois"
	add_child(pf)
	pf.build(world.maker)

	var drops := Node3D.new()
	drops.name = "Drops"
	add_child(drops)

	authority = GameAuthority.new()
	authority.name = "Authority"
	authority.world = world
	authority.glow = glow
	authority.drops_root = drops
	authority.poi_field = pf
	add_child(authority)

	players_root = Node3D.new()
	players_root.name = "Players"
	add_child(players_root)
	var stations_root := Node3D.new()
	stations_root.name = "Stations"
	add_child(stations_root)
	authority.stations_root = stations_root

	var me := multiplayer.get_unique_id()
	dwarf = _spawn_dwarf(me, _spawn_spot(me), true)
	dwarf.set_physics_process(false)  # wait until the floor exists
	authority.add_player(me, dwarf, authority.is_host())
	authority.monsters.enabled = _monsters
	if not snap.is_empty():
		authority.load_snapshot(snap)
	elif not save.is_empty():
		_loaded = save
		authority.load_snapshot(save.snap)
		if save.players.has(0):
			SaveGame.apply_player(authority.get_player(me), save.players[0])
	elif authority.is_host():
		authority.seed_poi_loot()
	if _jungle_kit:
		# Test kit: what you'd have after beating Orrumhal and Brask.
		var kit := authority.get_player(me).inventory
		for item in [["pickaxe_copper", 1], ["axe_copper", 1], ["sword_copper", 1], ["shield_copper", 1], ["crystal_blue", 20],
				["dish_hollowcap_stew", 3], ["waterskin_clean", 1]]:
			kit.add(item[0], item[1])

	var bm := BuildMode.new()
	bm.name = "BuildMode"
	bm.dwarf = dwarf
	add_child(bm)

	hud = Hud.new()
	if not save.is_empty() and save.get("map", {}).size() > 0:
		hud.map_data.load_data(save.map)
	hud.build_mode = bm
	bm.message.connect(func(t: String): hud.show_toast(t, 5.0))
	dwarf.fight.message.connect(func(t: String, _c: Color): hud.show_toast(t, 1.5))
	authority.monsters.defended.connect(_on_defended)
	authority.raids.warning.connect(func(t: String): hud.show_toast(t, 8.0))
	authority.hud_message.connect(func(t: String): hud.show_toast(t, 3.0))
	hud.peer_id = me
	hud.seed_text = str(seed)
	add_child(hud)


func _spawn_dwarf(peer_id: int, pos: Vector3, local: bool) -> Dwarf:
	var d := Dwarf.new()
	d.name = "Dwarf_%d" % peer_id
	d.peer_id = peer_id
	d.is_local = local
	d.color_index = player_slots.get(peer_id, 0)
	d.set_multiplayer_authority(peer_id)
	players_root.add_child(d)
	d.global_position = pos
	d.set_respawn(pos)
	if local or authority.is_host():
		# The host loads the cave around every player, so it can judge their digging.
		var viewer := VoxelViewer.new()
		viewer.view_distance = World.VIEW_DISTANCE if local else 48
		viewer.requires_visuals = local
		d.add_child(viewer)
	if not local:
		var tag := Label3D.new()
		tag.text = player_name(peer_id)
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = Vector3.UP * 1.75
		tag.font_size = 48
		tag.pixel_size = 0.005
		tag.outline_size = 12
		d.add_child(tag)
	return d


## Friends appear in a little circle around the start point.
func _spawn_spot(peer_id: int) -> Vector3:
	var base := world.maker.spawn_point
	if _jungle_kit:
		var gate: Dictionary = world.maker.pois_of("gate", "mossy")[0]
		base = world.maker.find_floor(gate.pos.x - 5.0, gate.pos.z, gate.pos.y + 1.5) + Vector3.UP
	if peer_id == 1:
		return base
	var a := float(peer_id % 7) * 0.9
	var p := base + Vector3(cos(a), 0, sin(a)) * 2.0
	return world.maker.find_floor(p.x, p.z, base.y + 2.0) + Vector3.UP


# ---------------------------------------------------------------- co-op

func player_name(peer_id: int) -> String:
	var n: int = player_slots.get(peer_id, -1)
	return "Host" if n == 0 else ("Friend %d" % n if n > 0 else "Friend")


func _free_slot() -> int:
	for n in range(1, Session.MAX_FRIENDS + 1):
		if not player_slots.values().has(n):
			return n
	return Session.MAX_FRIENDS + 1


func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server() or world == null:
		return
	player_slots[id] = _free_slot()
	var others := []
	for d in players_root.get_children():
		if d is Dwarf:  # dig sparkles live here too for a moment
			others.append([d.peer_id, d.global_position])
	_welcome.rpc_id(id, seed, authority.snapshot(), others, player_slots)
	var pos := _spawn_spot(id)
	var puppet := _spawn_dwarf(id, pos, false)
	_player_joined.rpc(id, pos, player_slots)
	var friend := authority.add_player(id, puppet)
	var slot: int = player_slots[id]
	if _loaded.get("players", {}).has(slot):
		# Welcome back: the bag, skills and lantern you had last time.
		var d: Dictionary = _loaded.players[slot]
		friend.inventory.load_data(d.inv)
		friend.progress.load_data(d.progress)
		friend.fuel = d.fuel
		authority._progress_dirty[id] = true
	if hud:
		hud.show_toast("%s joined!" % player_name(id))


func _on_peer_disconnected(id: int) -> void:
	var d := players_root.get_node_or_null("Dwarf_%d" % id) if players_root else null
	if d:
		d.queue_free()
	if authority:
		var ps := authority.get_player(id)
		if ps and multiplayer.is_server() and player_slots.has(id):
			# Keep their dwarf for when they come back (and for the next save).
			if not _loaded.has("players"):
				_loaded.players = {}
			_loaded.players[player_slots[id]] = SaveGame.player_data(ps)
		authority.remove_player(id)
	if hud:
		hud.show_toast("%s left." % player_name(id))
	player_slots.erase(id)


func _on_server_disconnected() -> void:
	if hud:
		hud.show_toast("The host left the game.", 6.0)
	session.leave()
	await get_tree().create_timer(4.0).timeout
	get_tree().reload_current_scene()


func _on_connection_failed(reason: String) -> void:
	if _menu:
		_menu.call("set_status", reason)
	elif hud:
		hud.show_toast(reason, 6.0)


## Host → a new friend: here's the cave and everything that changed so far.
@rpc("authority", "reliable")
func _welcome(p_seed: int, snap: Dictionary, others: Array, slots: Dictionary) -> void:
	player_slots = slots
	_close_menu()
	start_game(p_seed, snap)
	for o in others:
		_spawn_dwarf(o[0], o[1], false)


## Host → everyone: a friend arrived.
@rpc("authority", "reliable")
func _player_joined(id: int, pos: Vector3, slots: Dictionary) -> void:
	player_slots = slots
	if id == multiplayer.get_unique_id() or players_root == null or players_root.has_node("Dwarf_%d" % id):
		return
	_spawn_dwarf(id, pos, false)


# ---------------------------------------------------------------- look & feel

## Light, fog, colour and floating dust: all in src/art/ambience.gd.
func _make_environment() -> void:
	var amb := Ambience.new()
	amb.name = "Ambience"
	add_child(amb)


func _process(delta: float) -> void:
	if world and _ready_to_play and _saving and authority.is_host():
		_autosave -= delta
		if _autosave <= 0.0:
			_autosave = 300.0  # every 5 minutes (spec 5.11)
			save_now("Autosaved")
	if world == null or _ready_to_play:
		return
	var p := dwarf.global_position
	var area := AABB(p - Vector3(6, 6, 6), Vector3(12, 12, 12))
	if world.terrain.is_area_meshed(area):
		_ready_to_play = true
		dwarf.set_physics_process(true)
		hud.set_loading(false)


## Saves now (host only). Shows a small note.
func save_now(note: String = "Saved") -> void:
	if not _saving or world == null or not authority.is_host():
		return
	var err := SaveGame.save(self)
	if hud:
		hud.show_toast(note if err == "" else "Save failed: " + err, 2.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _ready_to_play:
		save_now()  # saving when you quit (spec 5.11)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		take_screenshot()
	if event.is_action_pressed("quicksave") and _ready_to_play:
		save_now("Saved (F5)")
	if not _ready_to_play:
		return
	if event.is_action_pressed("blueprints") or (event.is_action_pressed("pause") and hud.is_blueprints_open()):
		var open_v := not hud.is_blueprints_open() and hud.build_mode.active()
		hud.set_blueprints_open(open_v)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open_v else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("build_menu") or (event.is_action_pressed("pause") and hud.is_build_menu_open()):
		var open_b := not hud.is_build_menu_open() and hud.build_mode.active()
		hud.set_build_menu_open(open_b)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open_b else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("toggle_map") or (event.is_action_pressed("pause") and hud.is_map_open()):
		var open_map := not hud.is_map_open()
		hud.set_map_open(open_map)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open_map else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("toggle_skills") or (event.is_action_pressed("pause") and hud.is_skills_open()):
		var open := not hud.is_skills_open()
		hud.set_skills_open(open)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("pause"):
		if hud.is_bag_open():
			_set_bag(false)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hud.set_paused(true)
	elif event.is_action_pressed("toggle_bag"):
		_set_bag(not hud.is_bag_open())
	elif event.is_action_pressed("interact") and not hud.is_bag_open():
		var info := dwarf._aim_info()
		if info.has("box_id") or info.has("poi_id") or info.has("station"):
			dwarf.model.react("use")  # reach out to open / touch it
		if info.has("box_id"):
			hud.open_box(info.box_id)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		if info.has("poi_id"):
			authority.ask_poi(info.poi_id)
			var t: String = world.maker.pois[info.poi_id].type
			if t == "lair":
				hud.show_toast(_altar_text(world.maker.pois[info.poi_id].biome), 6.0)
			else:
				hud.show_toast("You copy the old carving onto your map (M)." if t == "marking" else "You take the rune. Carve it at a Rune Slab.", 4.0)
			return
		var st: Station = info.get("station")
		if st == null:
			st = authority.station_near(dwarf.global_position, 2.5)
		if st and Station.WATER.has(st.kind):
			if st.water > 0:
				authority.ask_collect_water(st.station_id)
				hud.show_toast("You fill up with clean water.", 2.0)
			else:
				hud.show_toast("Still empty. It fills one bucket every few minutes." if st.under_drip else "No drips here! Place it under a dripping stalactite (look for falling drops).", 4.0)
			return
		if st:
			hud.open_station(st)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("interact") and hud.is_bag_open():
		_set_bag(false)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not hud.is_bag_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hud.set_paused(false)


## What the summoning altar tells you (the host does the real check).
func _altar_text(biome: String) -> String:
	for id in Monsters.OFFERINGS:
		if Monsters.BOSSES[id].biome != biome:
			continue
		var boss: String = Monsters.BOSSES[id].name.get_slice(",", 0)
		if not authority.world_state.bosses_dead.has(id):
			return "The altar is cold. %s still lives here." % boss
		var parts := []
		for item in Monsters.OFFERINGS[id]:
			parts.append("%d %s" % [Monsters.OFFERINGS[id][item], "rune shard" if item == "shard" else Items.display_name(item)])
		return "Offering to call %s back: %s. (If you carry it all, it's taken and the fight begins!)" % [boss, ", ".join(parts)]
	return ""


func _set_bag(open: bool) -> void:
	hud.set_bag_open(open)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


func take_screenshot(path: String = "") -> String:
	if path == "":
		DirAccess.make_dir_recursive_absolute("user://screenshots")
		path = "user://screenshots/shot_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	get_viewport().get_texture().get_image().save_png(path)
	return ProjectSettings.globalize_path(path)


func is_ready_to_play() -> bool:
	return _ready_to_play
