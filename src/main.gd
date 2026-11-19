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
var cave_life: CaveLife
var place_ghost: PlaceGhost
var _clutter: Clutter
var _curtains: RootCurtains
var _pillars: RootPillars
var _groves: GlowGroves
var _boulders: Boulders
var authority: GameAuthority
var dwarf: Dwarf
var hud: Hud
var _dev_items: DevItems  ## F8 in dev builds: any item into your bag (owner, Nov 19)
var session: Session
var players_root: Node3D
var _ready_to_play := false
var _away := false  ## Alt+Tabbed out with the mouse in the game (F228)
var _menu: Node
var world_file := ""  ## the save file of the world being played (F87)
var world_name := ""
var player_slots := {1: 0}
var _monsters := true
var _saving := true  ## off for robot test runs
var _autosave := 300.0
var _jungle_kit := false  ## "-- jungle": start at the jungle gate with copper tools (for testing)
## Test robots and test kits start in the big cavern with tools, like before.
## Real games start in the small room with nothing (feedback F10/F11).
var _robot_run := false
## Cave layout for brand-new worlds (F211). Saves and friends' games use the layout they were made with.
var _new_layout := CaveMaker.LAYOUT_DEFAULT
var _loaded := {}  ## the save we started from (friends' dwarfs are restored from it when they rejoin)  ## peer id -> player number (0 = host, 1-3 = friends)


func _ready() -> void:
	Controls.setup()
	SoundSettings.load_and_apply()
	GraphicsSettings.load_and_apply()  # Potato..Ultra, remembered on this computer (owner, Nov 19)
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
		elif arg == "perfcheck":
			debug_script = "res://src/debug/perfcheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg.begins_with("rock="):
			CaveMaker.rock_style = arg.trim_prefix("rock=")  # compare rock styles (blocks, slabs, ledges, mixed)
		elif arg.begins_with("layout="):
			_new_layout = arg.trim_prefix("layout=").to_int()  # new worlds in an older cave layout (comparing)
		elif arg == "lookdev":
			debug_script = "res://src/debug/lookdev.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "artpreview":
			debug_script = "res://src/debug/artpreview.gd"
			_saving = false
		elif arg == "buildcheck":
			debug_script = "res://src/debug/buildcheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "kitcheck":
			debug_script = "res://src/debug/kitcheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "outpostcheck":  # photos of the Fallen Outpost (moves the dwarf there so it gets built)
			debug_script = "res://src/debug/outpostcheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "towercheck":  # F254: photos of the ruined watchtower in the first cave
			debug_script = "res://src/debug/towercheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "steamshots":  # Steam store pictures (Nov 18): dwarf + tower + stars, beetle, snail
			debug_script = "res://src/debug/steamshots.gd"
			_saving = false
			if mode == "menu":
				mode = "solo"
		elif arg == "ruincheck":
			debug_script = "res://src/debug/ruincheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "startcheck":
			debug_script = "res://src/debug/startcheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg == "cavecheck":  # F404-F407 + F350: photos of the cave floor, Root Trees, Rebuilding Chest, swarm
			debug_script = "res://src/debug/cavecheck.gd"
			_saving = false
			_monsters = false
			if mode == "menu":
				mode = "solo"
		elif arg.begins_with("savecheck"):
			debug_script = "res://src/debug/savecheck.gd"
	# (startcheck is a robot too, but it plays the real new-game start on purpose.)
	_robot_run = (debug_script != "" and not debug_script.ends_with("startcheck.gd")) or _jungle_kit
	# Every test robot (startcheck too) leaves the real mouse alone (F27), and its window
	# never takes the keyboard/mouse focus from whatever the owner is doing.
	Controls.robot = debug_script != ""
	# Slowdowns and freezes go into the log (owner, Nov 17). A person's game says so on its first line, so the
	# recorder copies this log and not a test robot's (they all write to the same log folder).
	add_child(FreezeWatch.new())
	add_child(NanWatch.new())  # writes the first "broken number" things to the log (Claude, Nov 19)
	if not Controls.robot:
		print("PLAYER GAME (not a robot) started ", Time.get_datetime_string_from_system())
		FreezeWatch.open_player_file()
	if Controls.robot:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
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
	# Making a world takes a few seconds: a loading screen with a bar shows first (owner, Nov 16).
	_menu.connect("play_alone", func(s: int, wname: String): _close_menu(); _with_loading(func(): _new_world(s, wname), s if s > 0 else seed, _new_layout))
	_menu.connect("continue_game", func(data: Dictionary): _close_menu(); _with_loading(func(): start_game(data.seed, {}, data), int(data.seed), int(data.get("layout", 1))))
	_menu.connect("host_world", func(data: Dictionary):
		_close_menu()
		_with_loading(func():
			start_game(data.seed, {}, data)
			session.host_direct()))
	_menu.connect("host_direct", func(s: int, wname: String):
		_close_menu()
		_with_loading(func():
			_new_world(s, wname)
			session.host_direct()))
	_menu.connect("quit_game", func(): get_tree().quit())
	_menu.connect("join_direct", func(addr: String):
		_menu.call("set_status", "Connecting to %s…" % addr)
		session.join_direct(addr))
	_menu.connect("host_steam", func(s: int, wname: String):
		if session.host_steam():
			_close_menu()
			_new_world(s, wname))
	session.status_changed.connect(func(t: String): if _menu: _menu.call("set_status", t))


## Shows a loading screen first, waits two frames so it's really on screen, then does `job` (which
## freezes the game for a moment while the cave is made). The in-game bar takes over after that.
## `seed_hint`/`layout_hint`: the world about to be made. Its cave, crystals and plants are then worked out by a helper
## while this screen shows and its bar moves (owner, Nov 18: the game froze for ~30 s at "making the cave").
func _with_loading(job: Callable, seed_hint := 0, layout_hint := 0) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.035, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	bg.add_child(box)
	var title := Label.new()
	title.text = "Making your world…"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(420, 18)
	bar.value = 5
	bar.show_percentage = false
	box.add_child(bar)
	box.resized.connect(func(): box.position = (bg.size - box.size) * 0.5)
	bg.resized.connect(func(): box.position = (bg.size - box.size) * 0.5)
	add_child(layer)
	await get_tree().process_frame
	await get_tree().process_frame
	if seed_hint != 0:
		CaveMaker.use_layout(layout_hint)
		var th := Thread.new()
		th.start(_prefetch.bind(seed_hint, layout_hint))
		while th.is_alive():
			bar.value = minf(bar.value + 0.04, 60.0)
			await get_tree().process_frame
		th.wait_to_finish()
	job.call()
	layer.queue_free()


## (helper thread) The slow planning for world `sd`, saved where start_game looks for it.
func _prefetch(sd: int, layout: int) -> void:
	var key := "%d:%d" % [sd, layout]
	if not World._planned.has(key):
		World._planned[key] = CaveMaker.new(sd)
	var maker: CaveMaker = World._planned[key]
	var spots := GlowPlacer.place(maker)
	CaveLife.prefetched[key] = CaveLife.cached_plan(maker, spots)


## A brand-new world: its own save file and name (F87).
func _new_world(s: int, wname: String) -> void:
	var sd := s if s > 0 else seed
	world_file = SaveGame.new_path(sd)
	world_name = wname if wname != "" else "Cave %d" % sd
	start_game(sd)


## The Escape menu's buttons (F87).
func pause_action(what: String) -> void:
	match what:
		"resume":
			Controls.set_captured(true)
			hud.set_paused(false)
		"save":
			save_now()
		"menu":
			get_tree().paused = false
			save_now("Saved")
			_ready_to_play = false
			session.leave()
			get_tree().reload_current_scene()
		"quit":
			get_tree().paused = false
			save_now("Saved")
			get_tree().quit()
		"invite":  # Steam's own invite window, when you're hosting on Steam (F187)
			if session.lobby_id != 0 and session.steam_available():
				session.steam.activateGameOverlayInviteDialog(session.lobby_id)
			else:
				hud.show_toast("Host on Steam to invite friends from here. (Or friends join with your IP address.)", 4.0)


func _close_menu() -> void:
	if _menu:
		_menu.queue_free()
		_menu = null


## Builds the whole game. `snap` is the host's catch-up data when joining a friend;
## `save` is a save file's data when continuing.
func start_game(p_seed: int, snap: Dictionary = {}, save: Dictionary = {}) -> void:
	seed = p_seed
	# Which cave layout (F211): a save keeps its own (saves from before layouts existed = 1, the old
	# caves); a friend joining gets the host's; a new world gets CaveMaker.LAYOUT_DEFAULT.
	if not save.is_empty():
		CaveMaker.use_layout(int(save.get("layout", 1)))
	elif snap.has("layout"):
		CaveMaker.use_layout(int(snap.layout))
	else:
		CaveMaker.use_layout(_new_layout)
	print("Cave seed: ", seed, " (cave layout ", CaveMaker.layout, ")")
	FreezeWatch.doing = "making the cave"
	_make_environment()
	world = World.new()
	world.name = "World"
	add_child(world)
	world.setup(seed)

	glow = GlowField.new()
	glow.name = "Glow"
	add_child(glow)
	glow.rock = CaveLife.Rock.new(world.maker)  # crystals sit on the rock as it's drawn (F195)
	FreezeWatch.doing = "placing crystals and roots"
	var spots := GlowPlacer.place(world.maker)  # (~6 s: worked out once, the plants below get a copy)
	glow.build(spots)

	FreezeWatch.doing = "placing pebbles and dripstone"
	var ground_snap := GroundSnap.new()  # puts floor things onto the real rock once it's built (owner, Nov 18: things floating)
	ground_snap.name = "GroundSnap"
	ground_snap.world = world
	add_child(ground_snap)
	_clutter = Clutter.new()  # pebbles, rocks, bones, twigs on the floors (only looks)
	_clutter.name = "Clutter"
	add_child(_clutter)
	_clutter.build(world.maker, world)  # worked out on a helper thread while the rock loads

	FreezeWatch.doing = "hanging root curtains"
	_curtains = RootCurtains.new()  # thin roots hanging across some tunnel mouths, parting as you walk through (F189)
	_curtains.name = "RootCurtains"
	add_child(_curtains)
	_curtains.build(world.maker, world)
	FreezeWatch.doing = "growing root pillars"
	_pillars = RootPillars.new()  # giant root pillars in some big caverns, chop them for wood (F189)
	_pillars.name = "RootPillars"
	add_child(_pillars)
	_pillars.build(world.maker)
	FreezeWatch.doing = "growing glow groves"
	var groves := GlowGroves.new()
	_groves = groves  # glowing forests in 1-2 big caverns per biome, their main light (owner, Nov 19)
	groves.name = "GlowGroves"
	add_child(groves)
	groves.build(world.maker, _pillars.near)
	FreezeWatch.doing = "placing boulders"
	_boulders = Boulders.new()  # breakable boulders for stone (owner, Nov 18)
	_boulders.name = "Boulders"
	add_child(_boulders)
	_boulders.build(world.maker, func(p: Vector3, r: float) -> bool: return _pillars.near(p, r) or groves.near(p, r))
	FreezeWatch.doing = "growing mushroom grass"
	var mush := MushroomGrass.new()  # tiny mushroom grass over most of the first cave's floor (owner, Nov 18)
	mush.name = "MushroomGrass"
	add_child(mush)
	mush.build(world.maker, world, _pillars.trunks)
	FreezeWatch.doing = "puddles and mist"
	var water := CaveWater.new()  # puddles (rings under the drips) and low mist (F190)
	water.name = "CaveWater"
	add_child(water)
	water.build(world.maker, spots)
	FreezeWatch.doing = "cave critters"
	var critters := CaveCritters.new()  # glowing beetles, moths, crickets near you (only looks, F190)
	critters.name = "CaveCritters"
	add_child(critters)
	critters.setup(world, glow)
	FreezeWatch.doing = "glow swarms"
	var swarms := GlowSwarms.new()  # packs of glowing motes drifting through the caves (owner, Nov 18)
	swarms.name = "GlowSwarms"
	add_child(swarms)
	swarms.build(world.maker, _pillars.trunks())

	FreezeWatch.doing = "planting moss and ferns"
	cave_life = CaveLife.new()  # moss, grass, small roots, lichen, ferns in patches (only looks; F188)
	cave_life.name = "CaveLife"
	add_child(cave_life)
	cave_life.build(world.maker, spots.duplicate(true), world, true)  # placed in the background while the cave loads

	FreezeWatch.doing = "placing the cave's places"
	var pf := PoiField.new()
	pf.name = "Pois"
	add_child(pf)
	pf.build(world.maker)
	FreezeWatch.doing = "setting up the game"
	var peephole := Peephole.make(world)
	if peephole:
		peephole.name = "Peephole"
		add_child(peephole)

	var drops := Node3D.new()
	drops.name = "Drops"
	add_child(drops)

	authority = GameAuthority.new()
	authority.name = "Authority"
	authority.world = world
	authority.glow = glow
	authority.cave_life = cave_life
	authority.curtains = _curtains
	authority.pillars = _pillars
	authority.groves = _groves
	authority.boulders = _boulders
	authority.clutter = _clutter
	authority.drops_root = drops
	authority.poi_field = pf
	add_child(authority)

	players_root = Node3D.new()
	players_root.name = "Players"
	cave_life.walkers = players_root  # grass and ferns lean away from every dwarf
	glow.walkers = players_root  # and so do the little mushrooms (F219)
	_curtains.walkers = players_root  # and the root curtains swing aside
	add_child(players_root)
	var stations_root := Node3D.new()
	stations_root.name = "Stations"
	add_child(stations_root)
	authority.stations_root = stations_root

	var me := multiplayer.get_unique_id()
	dwarf = _spawn_dwarf(me, _spawn_spot(me), true)
	dwarf.set_physics_process(false)  # wait until the floor exists
	var fresh := snap.is_empty() and save.is_empty() and authority.is_host()
	authority.start_with_nothing = fresh and not _robot_run and not world.maker.start.is_empty()
	authority.add_player(me, dwarf, authority.is_host())
	authority.monsters.enabled = _monsters
	if not snap.is_empty():
		authority.load_snapshot(snap)
	elif not save.is_empty():
		_loaded = save
		world_file = str(save.get("path", world_file))
		world_name = SaveGame.world_name(save)
		authority.load_snapshot(save.snap)
		if save.players.has(0):
			SaveGame.apply_player(authority.get_player(me), save.players[0])
		if authority.is_host():
			RuinTower.add_missing_chest(authority)  # older worlds: their tower gets its Rebuilding Chest (F350)
	elif authority.is_host():
		authority.seed_poi_loot()
		# The ruined Stone Watchtower in the first cave (owner F254). Robot runs only with "ruin" (keeps their tests steady).
		if not _robot_run or OS.get_cmdline_user_args().has("ruin=1") or OS.get_cmdline_user_args().has("towercheck"):
			authority.add_child(RuinTower.new(authority))
		# The Fallen Outpost, built when someone first comes near (owner, Nov 17). Robots: only with outpostcheck.
		if not _robot_run or OS.get_cmdline_user_args().has("outpostcheck"):
			authority.world_state["outpost"] = "pending"
		if authority.start_with_nothing:
			authority.spawn_start_items()
	if authority.is_host() and authority.world_state.has("outpost"):
		authority.add_child(RuinOutpost.new(authority))  # builds it when someone comes near (or marks its cavern)
	if _jungle_kit:
		# Test kit: what you'd have after beating Orrumhal and Brask.
		var kit := authority.get_player(me).inventory
		for item in [["pickaxe_copper", 1], ["axe_copper", 1], ["sword_copper", 1], ["shield_copper", 1], ["crystal_blue", 20],
				["dish_hollowcap_stew", 3], ["waterskin_clean", 1]]:
			kit.add(item[0], item[1])

	var bm := BuildMode.new()
	bm.name = "BuildMode"
	bm.dwarf = dwarf
	dwarf.build_mode = bm
	place_ghost = PlaceGhost.new()  # see where a workbench/chest will go before placing it (F96)
	place_ghost.dwarf = dwarf
	add_child(place_ghost)
	add_child(bm)

	hud = Hud.new()
	if not save.is_empty() and save.get("map", {}).size() > 0:
		hud.map_data.load_data(save.map)
	hud.build_mode = bm
	hud.pause_pressed.connect(pause_action)
	bm.message.connect(func(t: String): hud.show_toast(t, 5.0))
	authority.builder.message.connect(func(t: String): hud.show_toast(t, 4.0))
	dwarf.fight.message.connect(func(t: String, _c: Color): hud.show_toast(t, 1.5))
	authority.monsters.defended.connect(_on_defended)
	authority.hud_message.connect(func(t: String): hud.show_toast(t, 3.0))
	authority.learned_recipe.connect(func(r: String): hud.learned_cards.show_recipe(r))
	authority.learned_blueprint.connect(func(w: String, page: String): hud.learned_cards.show_blueprint(w, page))
	hud.peer_id = me
	hud.seed_text = str(seed)
	add_child(hud)
	FreezeWatch.doing = "loading the rock around you"


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
		if local:
			# Solid rock only as far as it's needed (owner, Nov 19, speed): building it costs 3-5x drawing it and runs
			# on the main thread. This viewer only draws; a second one makes solid rock out to where creatures roam.
			viewer.requires_collisions = false
			var solid := VoxelViewer.new()
			solid.view_distance = World.COLLISION_DISTANCE
			solid.requires_visuals = false
			solid.requires_collisions = true
			d.add_child(solid)
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
	var base := world.maker.cavern_spawn if _robot_run else world.maker.spawn_point
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
	get_tree().paused = false  # a friend came in: a paused world starts again (F239)
	if not multiplayer.is_server() or world == null:
		return
	player_slots[id] = _free_slot()
	var others := []
	for d in players_root.get_children():
		if d is Dwarf:  # dig sparkles live here too for a moment
			others.append([d.peer_id, d.global_position])
	var snap := authority.snapshot()
	snap.layout = CaveMaker.layout  # the friend must make the same caves (F211)
	_welcome.rpc_id(id, seed, snap, others, player_slots)
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
	# Loading bar: how much of the ground around you is ready (rings from 2 m out to 6 m).
	var rings_ready := 0
	for r in [2.0, 3.0, 4.0, 5.0, 6.0]:
		if world.terrain.is_area_meshed(AABB(p - Vector3.ONE * r, Vector3.ONE * r * 2.0)):
			rings_ready += 1
	hud.set_loading_progress(0.15 + 0.85 * rings_ready / 5.0)
	if world.terrain.is_area_meshed(area) and (cave_life == null or cave_life.is_built()) and (_clutter == null or _clutter.is_built()):
		_ready_to_play = true
		FreezeWatch.doing = "playing"
		print("[%s] ready to play" % Time.get_time_string_from_system())
		RockShatter.warm_up(self)  # the first dig no longer hitches (owner, Nov 18)
		Fx.burst(self, Vector3(0, -5000, 0), Color.GRAY, 16, 4.0)
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
	# You switched to another program (Alt+Tab, clicked another window): let go of the mouse (F27),
	# but no pause menu, so screenshots of the game stay clean (F228). Coming back takes the mouse again.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not Controls.robot and Controls.captured():
		Controls.set_captured(false)
		_away = true
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and _away:
		_away = false
		if _ready_to_play and hud and not hud.is_paused():
			Controls.set_captured(true)


## E turns what you're placing to the right (Q to the left), but only when you aren't aiming at something to open,
## sit on or pick up: then E still does that (owner, Nov 19).
func _turn_with_e(info: Dictionary) -> bool:
	for k in ["seat", "pick_glow", "box_id", "poi_id", "station", "door_uid"]:
		if info.has(k):
			return false
	var aimed := dwarf.aim()
	if not aimed.is_empty() and cave_life and cave_life.breakable_at(aimed.position) >= 0:
		return false
	if dwarf.build_mode and dwarf.build_mode.active():
		dwarf.build_mode.turn(-1)
		return true
	if place_ghost and place_ghost.visible:
		place_ghost.turn(-1)
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		take_screenshot()
	if event.is_action_pressed("quicksave") and _ready_to_play:
		save_now("Saved (F5)")
	if not _ready_to_play:
		return
	if DevMenu.enabled() and event.is_action_pressed("dev_fly") and dwarf:
		dwarf.set_dev_fly(not dwarf.dev_fly)  # owner, Nov 17: fly around to see the whole cave
		hud.show_toast("Dev: flying (Space up, Ctrl down, Shift fast) · F6 to land" if dwarf.dev_fly else "Dev: walking again", 3.0)
		return
	if DevMenu.enabled() and (event.is_action_pressed("dev_items") or (event.is_action_pressed("pause") and _dev_items and _dev_items.visible)):
		# Item menu (owner, Nov 19): any item straight into your bag, no crafting needed.
		if _dev_items == null:
			_dev_items = DevItems.new()
			_dev_items.visible = false
			hud.add_child(_dev_items)
			_dev_items.resized.connect(func() -> void: _dev_items.position = (get_viewport().get_visible_rect().size - _dev_items.size) * 0.5)
		_dev_items.visible = not _dev_items.visible
		if _dev_items.visible:
			_dev_items.position = (get_viewport().get_visible_rect().size - _dev_items.size) * 0.5
		Controls.set_captured(not _dev_items.visible)
		get_viewport().set_input_as_handled()
		return
	if DevMenu.enabled() and event.is_action_pressed("dev_bright"):
		var amb: Ambience = get_node_or_null("Ambience")
		if amb:
			amb.set_dev_bright(not amb.dev_bright)
			hud.show_toast("Dev: all lights on · F7 to turn off" if amb.dev_bright else "Dev: normal light", 3.0)
		return
	if DevMenu.enabled() and (event.is_action_pressed("dev_menu") or (event.is_action_pressed("pause") and hud.is_dev_menu_open())):
		# Dev menu (owner, Nov 16): P with a Builder's Chest open fills it; otherwise P opens/closes the menu.
		var chest := hud.open_builder_chest()
		if chest >= 0 and event.is_action_pressed("dev_menu"):
			authority.builder.ask_dev_fill(chest)
			return
		var open_d := not hud.is_dev_menu_open()
		if open_d and hud.is_bag_open():
			_set_bag(false)
		hud.set_dev_menu_open(open_d)
		Controls.set_captured(false) if open_d else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("blueprints") or (event.is_action_pressed("pause") and hud.is_blueprints_open()):
		var open_v := not hud.is_blueprints_open() and hud.build_mode.active()
		hud.set_blueprints_open(open_v)
		Controls.set_captured(false) if open_v else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("build_menu") or (event.is_action_pressed("pause") and hud.is_build_menu_open()):
		var open_b := not hud.is_build_menu_open() and hud.build_mode.active()
		hud.set_build_menu_open(open_b)
		Controls.set_captured(false) if open_b else Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("toggle_map") or (event.is_action_pressed("pause") and hud.is_map_open()):
		var open_map := not hud.is_map_open()
		hud.set_map_open(open_map)
		Controls.set_captured(false) if open_map else Input.MOUSE_MODE_CAPTURED
		return
	for i in Progression.ABILITY_KEYS:  # active perks on Z / G / T (owner's tree, Nov 19)
		if event.is_action_pressed("ability_%d" % (i + 1)):
			var me := authority.get_player(authority.local_peer_id())
			var slots: Array = me.progress.ability_slots() if me else []
			if i < slots.size():
				authority.ask_ability(slots[i])
			else:
				hud.show_toast("No ability on this key yet. Active perks (diamonds) in the skills window (K) go here.", 3.0)
			return
	if event.is_action_pressed("toggle_skills") or (event.is_action_pressed("pause") and hud.is_skills_open()):
		var open := not hud.is_skills_open()
		hud.set_skills_open(open)
		Controls.set_captured(not open)
		return
	if event.is_action_pressed("pause"):
		if hud.is_bag_open():
			_set_bag(false)
		elif hud.is_paused():
			pause_action("resume")
		else:
			Controls.set_captured(false)
			hud.set_paused(true)
	elif event.is_action_pressed("toggle_bag"):
		_set_bag(not hud.is_bag_open())
	elif event.is_action_pressed("interact") and not hud.is_bag_open():
		var info := dwarf._aim_info()
		if _turn_with_e(info):
			return
		if info.has("seat"):  # a chair, stool or bench: sit down (move or jump to stand up)
			dwarf.sit_on(info.seat)
			return
		if info.has("pick_glow"):  # mushrooms, fiber, twigs, thin roots (owner, Nov 17: "picked up with E")
			dwarf.model.react("use")
			authority.ask_harvest(info.pick_glow)
			return
		var aimed := dwarf.aim()
		if not aimed.is_empty() and cave_life and cave_life.breakable_at(aimed.position) >= 0:
			dwarf.model.react("use")
			authority.ask_pick_plant(aimed.position)  # grass, ferns (fiber), small roots (wood)
			return
		if info.has("box_id") or info.has("poi_id") or info.has("station") or info.has("door_uid"):
			dwarf.model.react("use")  # reach out to open / touch it
		if info.has("door_uid"):
			authority.builder.ask_door(info.door_uid)
			return
		if info.has("box_id"):
			# The lid swings open on its hinge and the menu opens with it (ChestOpen; owner F345). It shuts again when
			# the menu closes (BoxPanel).
			var bid: int = info.box_id
			var box: Dictionary = authority.storage.get_box(bid)
			if not box.is_empty() and is_instance_valid(box.node):
				ChestOpen.open(box.node)
			hud.open_box(bid)
			Controls.set_captured(false)
			return
		if info.has("poi_id"):
			authority.ask_poi(info.poi_id)
			hud.show_toast("You take the rune. Carve it at a Rune Slab.", 4.0)
			return
		var st: Station = info.get("station")
		if st == null:
			st = authority.station_near(dwarf.global_position, 2.5)
		if st and st.kind == "farm_plot":
			# Plant what you're holding if it's a mushroom/tuber, else the first one in your bag (F176).
			var me := authority.get_player(authority.local_peer_id())
			var held: String = me.inventory.get_slot(me.selected_slot).get("id", "")
			if st.crop_ripe():
				hud.show_toast("You pick the %s." % Items.display_name(st.crop), 2.0)
			elif st.crop != "":
				hud.show_toast("Still growing. Come back in %d:%02d." % [int(st.crop_left) / 60, int(st.crop_left) % 60], 2.5)
			else:
				var has_seed := false
				for c in Station.CROPS:
					has_seed = has_seed or me.inventory.count_of(c) > 0
				hud.show_toast("Planted!" if has_seed else "Plant a Glowcap, Hollowcap, Bellcap or Root Tuber here.", 3.0)
			authority.ask_farm(st.station_id, held)
			return
		if st and Station.WATER.has(st.kind):
			if st.water > 0:
				authority.ask_collect_water(st.station_id)
				hud.show_toast("You fill up with clean water.", 2.0)
			else:
				hud.show_toast("Still empty. It fills one bucket every few minutes." if st.under_drip else "No drips here! Place it under a dripping stalactite (look for falling drops).", 4.0)
			return
		if st:
			hud.open_station(st)
			Controls.set_captured(false)
	elif event.is_action_pressed("interact") and hud.is_bag_open():
		_set_bag(false)
	elif event is InputEventMouseButton and event.pressed and not Controls.captured() and not hud.is_bag_open():
		Controls.set_captured(true)
		hud.set_paused(false)


func _set_bag(open: bool) -> void:
	hud.set_bag_open(open)
	Controls.set_captured(not open)


func take_screenshot(path: String = "") -> String:
	if path == "":
		DirAccess.make_dir_recursive_absolute("user://screenshots")
		path = "user://screenshots/shot_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	get_viewport().get_texture().get_image().save_png(path)
	return ProjectSettings.globalize_path(path)


func is_ready_to_play() -> bool:
	return _ready_to_play
