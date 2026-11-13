extends Node3D
## Starts a game: makes the cave, the glow, the referee, the dwarf and the screen.
## Command-line extras (after "--"):  seed=1234   autopilot   shots=folder

var seed := 0
var world: World
var glow: GlowField
var authority: GameAuthority
var dwarf: Dwarf
var hud: Hud
var _ready_to_play := false


func _ready() -> void:
	Controls.setup()
	seed = randi() % 1000000
	var autopilot := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("seed="):
			seed = arg.trim_prefix("seed=").to_int()
		elif arg == "autopilot":
			autopilot = true
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

	dwarf = Dwarf.new()
	dwarf.name = "Dwarf"
	add_child(dwarf)
	dwarf.global_position = world.maker.spawn_point
	dwarf.set_respawn(world.maker.spawn_point)
	dwarf.set_physics_process(false)  # wait until the floor exists
	var viewer := VoxelViewer.new()
	viewer.view_distance = World.VIEW_DISTANCE
	dwarf.add_child(viewer)
	authority.add_player(authority.local_peer_id(), dwarf)

	hud = Hud.new()
	hud.seed_text = str(seed)
	add_child(hud)

	if autopilot:
		var ap: Node = load("res://src/debug/autopilot.gd").new()
		add_child(ap)


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
	if not _ready_to_play:
		var p := world.maker.spawn_point
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
	if event.is_action_pressed("pause"):
		if hud.is_bag_open():
			_set_bag(false)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hud.set_paused(true)
	elif event.is_action_pressed("toggle_bag"):
		_set_bag(not hud.is_bag_open())
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
