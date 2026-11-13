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
var _monsters := true  ## peer id -> player number (0 = host, 1-3 = friends)


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
			if mode == "menu":
				mode = "solo"
		elif arg == "netcheck":
			debug_script = "res://src/debug/netcheck.gd"
			_monsters = false
		elif arg == "nomonsters":
			_monsters = false
	if debug_script != "":
		var dbg: Node = load(debug_script).new()
		dbg.name = "Debug"
		add_child(dbg)

	match mode:
		"menu":
			_show_menu()
		"solo":
			start_game(seed)
		"host":
			start_game(seed)
			session.host_direct(port)
		"join":
			_show_menu()
			_menu.call("set_status", "Connecting to %s…" % address)
			session.join_direct(address, port)


## What happened when a monster's attack reached us (shown briefly at the top of the screen).
func _on_defended(r: Dictionary) -> void:
	match r.result:
		"block":
			hud.show_toast("Blocked %s (−%d)" % [r.name, roundi(r.damage)], 1.2)
		"dodge":
			hud.show_toast("Dodged!", 1.0)
		"hit":
			hud.show_toast("Hit by %s (−%d)" % [r.name, roundi(r.damage)], 1.2)


func _show_menu() -> void:
	_menu = load("res://src/ui/start_menu.gd").new()
	add_child(_menu)
	_menu.connect("play_alone", func(s: int): _close_menu(); start_game(s if s > 0 else seed))
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


## Builds the whole game. `snap` is the host's catch-up data when joining a friend.
func start_game(p_seed: int, snap: Dictionary = {}) -> void:
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

	var drops := Node3D.new()
	drops.name = "Drops"
	add_child(drops)

	authority = GameAuthority.new()
	authority.name = "Authority"
	authority.world = world
	authority.glow = glow
	authority.drops_root = drops
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

	var bm := BuildMode.new()
	bm.name = "BuildMode"
	bm.dwarf = dwarf
	add_child(bm)

	hud = Hud.new()
	hud.build_mode = bm
	bm.message.connect(func(t: String): hud.show_toast(t, 5.0))
	dwarf.fight.message.connect(func(t: String, _c: Color): hud.show_toast(t, 1.5))
	authority.monsters.defended.connect(_on_defended)
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
		others.append([d.peer_id, d.global_position])
	_welcome.rpc_id(id, seed, authority.snapshot(), others, player_slots)
	var pos := _spawn_spot(id)
	var puppet := _spawn_dwarf(id, pos, false)
	_player_joined.rpc(id, pos, player_slots)
	authority.add_player(id, puppet)
	if hud:
		hud.show_toast("%s joined!" % player_name(id))


func _on_peer_disconnected(id: int) -> void:
	var d := players_root.get_node_or_null("Dwarf_%d" % id) if players_root else null
	if d:
		d.queue_free()
	if authority:
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

func _make_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.025)
	# Soft "cave bounce" light so it's never pitch black.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.46, 0.6)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.09, 0.1, 0.15)
	env.fog_density = 0.007
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _process(_delta: float) -> void:
	if world == null or _ready_to_play:
		return
	var p := dwarf.global_position
	var area := AABB(p - Vector3(6, 6, 6), Vector3(12, 12, 12))
	if world.terrain.is_area_meshed(area):
		_ready_to_play = true
		dwarf.set_physics_process(true)
		hud.set_loading(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		take_screenshot()
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
		if info.has("box_id"):
			hud.open_box(info.box_id)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		var st: Station = info.get("station")
		if st == null:
			st = authority.station_near(dwarf.global_position, 2.5)
		if st:
			hud.open_station(st)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("interact") and hud.is_bag_open():
		_set_bag(false)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not hud.is_bag_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hud.set_paused(false)


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
