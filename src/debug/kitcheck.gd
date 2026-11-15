extends Node
## Kit check (Claude 2, art): builds one small house in each Zone 1 building style with the hand-made
## models (Delver's Shack = plank_root, Stonehold = cut_stone, Hearthbrick = clay_brick) and photographs
## each from the front, the back corner and above.
## Run:  godot --audio-driver Dummy --path . -- kitcheck seed=42 shots=/some/folder [family=plank_root]

var _main: Node
var _shots := "user://kitcheck"
var _uid := 950000


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
	_main.take_screenshot(_shots.path_join(name + ".png"))


func _place(piece: String, family: String, pos: Vector3, rot: int) -> void:
	_main.authority.builder._ev_add_piece(_uid, piece, family, pos, rot, true)
	_uid += 1


func _look(dwarf: Dwarf, from: Vector3, at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = from
	var d := at - (from + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-d.x, -d.z)
	dwarf._pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw


## A 4 × 4 m house: 4 foundations, walls with a round doorway + door and windows, front steps,
## then a pitched roof with gables (sloped styles) or a flat roof with battlements (Stonehold).
## Next to it: a triangle foundation with a sloped wall, a pillar, a beam and a railing.
func _house(f: String, c: Vector3) -> void:
	for x in [-1, 1]:
		for z in [-1, 1]:
			_place("foundation", f, c + Vector3(x, -1, z), 0)
	# Walls: front (z = +2) doorway + window, back two walls, sides wall + window.
	_place("doorway", f, c + Vector3(-1, 0, 2), 0)
	_place("door", f, c + Vector3(-1, 0, 2), 0)
	_place("window_wall", f, c + Vector3(1, 0, 2), 0)
	_place("wall", f, c + Vector3(-1, 0, -2), 2)
	_place("window_wall", f, c + Vector3(1, 0, -2), 2)
	_place("window_wall", f, c + Vector3(-2, 0, -1), 3)
	_place("wall", f, c + Vector3(-2, 0, 1), 3)
	_place("wall", f, c + Vector3(2, 0, -1), 1)
	_place("half_wall", f, c + Vector3(2, 0, 1), 1)
	_place("foundation_steps", f, c + Vector3(-1, -1, 3), 0)
	if f == "cut_stone":
		for x in [-1, 1]:
			for z in [-1, 1]:
				_place("flat_roof", f, c + Vector3(x, 2, z), 0)
		for x in [-1, 1]:
			_place("battlement", f, c + Vector3(x, 2.3, 2 - 0.2), 0)
			_place("battlement", f, c + Vector3(x, 2.3, -2 + 0.2), 2)
		for z in [-1, 1]:
			_place("battlement", f, c + Vector3(2 - 0.2, 2.3, z), 1)
			_place("battlement", f, c + Vector3(-2 + 0.2, 2.3, z), 3)
		for x in [-1.7, 1.7]:
			for z in [-1.7, 1.7]:
				_place("battlement_corner", f, c + Vector3(x, 2.3, z), 0)
	else:
		for x in [-1, 1]:
			_place("roof_26", f, c + Vector3(x, 2, 1), 0)
			_place("roof_26", f, c + Vector3(x, 2, -1), 2)
		for x in [-2, 2]:
			_place("gable_26", f, c + Vector3(x, 2, 1), 1)
			_place("gable_26", f, c + Vector3(x, 2, -1), 3)
	# Beside the house: a triangle foundation + floor, a sloped wall, pillar, beam, railing.
	var s := c + Vector3(5, 0, 0)
	_place("foundation_triangle", f, s + Vector3(0, -1, 0), 0)
	_place("floor_triangle", f, s + Vector3(0, 0, 0), 0)
	_place("sloped_wall", f, s + Vector3(0, 0.25, Pieces.TRI_IN - 0.15), 0)
	_place("pillar", f, s + Vector3(2.2, -1, 1.5), 0)
	_place("pillar", f, s + Vector3(2.2, -1, -1.5), 0)
	_place("beam", f, s + Vector3(2.2, 1.0, 0), 1)
	_place("railing", f, s + Vector3(2.2, -1, 0), 1)


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var dwarf: Dwarf = _main.dwarf
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_main.hud.visible = false
	var base := (_main.world.maker.cavern_spawn as Vector3).round() + Vector3(0, 4, 0)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 16.0
	lamp.light_energy = 5.0
	lamp.shadow_enabled = true
	add_child(lamp)
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("family="):
			only = arg.trim_prefix("family=")
		if arg == "part=stations":
			await _stations(dwarf, base, lamp)
			get_tree().quit()
			return
	for f in ["plank_root", "cut_stone", "clay_brick"]:
		if only != "" and f != only:
			continue
		var b: Builder = _main.authority.builder
		for uid in b.structure.pieces.keys():
			if int(uid) >= 950000:
				b._ev_remove_piece(uid)
		_house(f, base)
		await _wait(1.0)
		var views := [
			["front", Vector3(-1.5, 1.8, 6.5), Vector3(0.3, 1.4, 0)],
			["back", Vector3(4.5, 3.6, -5.5), Vector3(0.3, 1.6, 0)],
			["side", Vector3(8.0, 1.6, 4.0), Vector3(5.5, 0.4, 0)],
		]
		for v in views:
			lamp.global_position = base + (v[1] as Vector3) * 0.7 + Vector3(0, 2.5, 0)
			_look(dwarf, base + v[1], base + v[2])
			dwarf._zoom = 1.5
			dwarf.visible = false
			await _wait(0.9)
			await _shot("%s_%s" % [f, v[0]])
	get_tree().quit()


## `part=stations`: the stations remade from the night pictures, in rows on a stone floor, photographed in
## groups of about five.
func _stations(dwarf: Dwarf, base: Vector3, lamp: OmniLight3D) -> void:
	var rows := [
		["twin_smelter", "gem_bench", "copper_drip_basin", "drip_bucket"],
		["crystal_sconce", "glow_marker", "bellows", "campfire", "chest_small", "chopping_block"],
		["cooking_pot", "grindstone", "stone_saw", "tool_rack", "training_dummy"],
		["carpenters_vise", "tanning_rack", "kiln", "rune_slab"],
	]
	var auth: GameAuthority = _main.authority
	var uid := 990100
	for r in rows.size():
		var row: Array = rows[r]
		var c := base + Vector3(0, 0, -r * 5.0)
		for x in range(-4, 5):
			for z in range(-1, 1):
				_place("foundation", "cut_stone", c + Vector3(x * 2, -1, z * 2), 0)
		for i in row.size():
			auth._ev_place_station(uid, row[i], c + Vector3((i - (row.size() - 1) / 2.0) * 2.6, 0, -1), PI)
			uid += 1
		await _wait(0.8)
		lamp.global_position = c + Vector3(0, 4, 3)
		_look(dwarf, c + Vector3(0, 1.6, 4.5), c + Vector3(0, 0.6, -1))
		dwarf._zoom = 1.5
		dwarf.visible = false
		await _wait(0.9)
		await _shot("stations_%d" % r)
