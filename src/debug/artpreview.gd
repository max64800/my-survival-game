extends Node
## Art pack lineup: today's placeholder dwarf next to free CC0 character candidates, in the
## cave with lantern light, squashed into dwarf proportions. Takes screenshots, then quits.
##   godot --path . -- seed=42 nomonsters artpreview shots=/some/folder
## With "creatures": each creature (Rock Snail, Cave Bat, Rock Beetle) in all 4 looks (mossy, frost,
## ember, spore) next to the Forge workbench, same cave light (docs/art/CREATURE-STYLE.md, step 8).

const CANDIDATES := [
	["res://assets/art_candidates/quaternius_adventurer.glb", "Quaternius Adventurer (CC0, 24 animations)"],
	["res://assets/art_candidates/quaternius_hooded.glb", "Quaternius Hooded Adventurer (CC0, 24 animations)"],
	["res://assets/art_candidates/polygonalmind_adventurer.glb", "Polygonal Mind Adventurer (CC0, no animations)"],
]
const DWARF_SHAPE := Vector3(1.15, 0.78, 1.15)  ## shorter and stockier than a human

var _main: Node
var _shots := "user://artpreview"


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _run() -> void:
	while not (_main.world and _main.is_ready_to_play()):
		await _wait(0.25)
	await _wait(1.0)
	if "creatures" in OS.get_cmdline_user_args():
		await _creatures()
		print("ARTPREVIEW done: ", _shots)
		get_tree().quit()
		return
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	var base := dwarf.global_position + fwd * 4.0
	var lineup := Node3D.new()
	_main.add_child(lineup)
	for i in CANDIDATES.size():
		var c: Array = CANDIDATES[i]
		var scene: PackedScene = load(c[0])
		var m: Node3D = scene.instantiate()
		lineup.add_child(m)
		var spot := base + side * (1.6 * (i + 1) - 1.6)
		m.global_position = _main.world.maker.find_floor(spot.x, spot.z, dwarf.global_position.y + 2.0)
		m.rotation.y = dwarf._yaw + PI  # face the camera
		_fit(m, 1.35)
		for ap in m.find_children("*", "AnimationPlayer", true, false):
			var names: PackedStringArray = ap.get_animation_list()
			for want in ["CharacterArmature|Idle", "Idle"]:
				if want in names:
					ap.play(want)
					break
		var label := Label3D.new()
		label.text = "%d. %s" % [i + 2, c[1]]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.004
		label.font_size = 40
		label.outline_size = 8
		label.position = Vector3.UP * 1.9
		m.add_child(label)
	var me := Label3D.new()
	me.text = "1. Today's placeholder dwarf"
	me.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	me.pixel_size = 0.004
	me.font_size = 40
	me.outline_size = 8
	me.position = Vector3.UP * 1.9
	dwarf.add_child(me)
	dwarf.global_position = base - side * 1.6
	dwarf.global_position = _main.world.maker.find_floor(dwarf.global_position.x, dwarf.global_position.z, dwarf.global_position.y + 2.0)
	dwarf.model.rotation.y = dwarf._yaw + PI
	# Camera: step back and look at the lineup.
	dwarf._yaw += PI
	dwarf._pitch = -0.1
	var cam_pos := base + side * 0.8 - fwd * -5.5 + Vector3.UP * 1.6
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.global_position = cam_pos
	cam.look_at(base + side * 0.8 + Vector3.UP * 0.8)
	cam.current = true
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.78, 0.52)
	light.omni_range = 12.0
	light.light_energy = 1.7
	_main.add_child(light)
	light.global_position = cam_pos + Vector3.UP * 0.5
	_main.hud.visible = false
	cam.global_position = base + side * 0.8 + fwd * 4.0 + Vector3.UP * 1.4
	cam.look_at(base + side * 0.8 + Vector3.UP * 0.7)
	light.global_position = cam.global_position + Vector3.UP * 0.5
	await _wait(1.5)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("art_lineup.png"))
	cam.global_position = base + side * 1.6 + fwd * 2.2 + Vector3.UP * 1.0
	cam.look_at(base + side * 1.6 + Vector3.UP * 0.7)
	light.global_position = cam.global_position + Vector3.UP * 0.4
	await _wait(0.5)
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("art_closeup.png"))
	print("ARTPREVIEW done: ", _shots)
	get_tree().quit()


## Scale a model so it's `height` meters tall, with dwarf proportions.
func _fit(m: Node3D, height: float) -> void:
	var aabb := AABB()
	var first := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	if aabb.size.y > 0.001:
		var s := height / aabb.size.y  # same height as our dwarf…
		m.scale = Vector3(s * 1.25, s, s * 1.25)  # …but wider and stockier, like a dwarf


# ---------------------------------------------------------------- creatures next to the workbench
const LOOKS := {"": "mossy", "blue": "frost", "red": "ember", "green": "spore"}
const CREATURES := [["rock_snail", "Rock Snail"], ["cave_bat", "Cave Bat"], ["rock_beetle", "Rock Beetle"]]


func _creatures() -> void:
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	Controls.set_captured(true)
	_main.hud.visible = false
	dwarf.visible = false
	var fwd := -Basis(Vector3.UP, dwarf._yaw).z
	var side := Basis(Vector3.UP, dwarf._yaw).x
	var base := dwarf.global_position + fwd * 4.0
	var floor_at := func(p: Vector3) -> Vector3:
		return _main.world.maker.find_floor(p.x, p.z, dwarf.global_position.y + 2.0)
	# The workbench, exactly as the game shows it.
	var bench: Node3D = Look.forged("stations", "workbench")
	if bench:
		_main.add_child(bench)
		bench.global_position = floor_at.call(base)
		bench.rotation.y = dwarf._yaw + PI * 0.85
	var cam := Camera3D.new()
	_main.add_child(cam)
	cam.current = true
	var light := OmniLight3D.new()  # a lantern beside the camera, like the player's
	light.light_color = Color(1.0, 0.78, 0.52)
	light.omni_range = 12.0
	light.light_energy = 1.8
	_main.add_child(light)
	var fill := OmniLight3D.new()  # a second lantern for the group pictures
	fill.light_color = Color(1.0, 0.85, 0.65)
	fill.omni_range = 9.0
	fill.light_energy = 1.2
	_main.add_child(fill)
	for c in CREATURES:
		var data: Dictionary = Monsters.LIST[c[0]]
		var lineup := Node3D.new()
		_main.add_child(lineup)
		var i := 0
		for variant in LOOKS:
			var m := MonsterModel.build(data.shape, data.color, data.size, false, c[0], 0, variant)
			var stand := Node3D.new()
			lineup.add_child(stand)
			stand.add_child(m)
			var spot: Vector3 = base + side * (1.6 + 1.7 * i) + fwd * 0.2
			stand.global_position = floor_at.call(spot) + (Vector3.UP * 0.9 if c[0] == "cave_bat" else Vector3.ZERO)
			stand.rotation.y = dwarf._yaw + {"rock_snail": -0.5, "cave_bat": 0.0, "rock_beetle": -0.45}[c[0]]  # facing the camera like the pictures
			MonsterModel.animate(m, 0.0 if c[0] != "cave_bat" else 1.5, data.size, 0.3)
			var label := Label3D.new()
			label.text = "%s: %s" % [c[1], LOOKS[variant]]
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.pixel_size = 0.004
			label.font_size = 36
			label.outline_size = 8
			label.position = Vector3.UP * 1.7
			stand.add_child(label)
			i += 1
		# Close-up: the mossy one right next to the workbench.
		var mid: Vector3 = base + side * 0.8
		cam.global_position = mid + fwd * 3.2 + Vector3.UP * 1.3 - side * 0.3
		cam.look_at(mid + Vector3.UP * 0.6)
		light.global_position = cam.global_position + Vector3.UP * 0.4 + side * 0.5
		fill.global_position = mid + fwd * 1.5 + Vector3.UP * 2.0
		await _wait(0.6)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("creature_%s_closeup.png" % c[0]))
		# All four looks, with the workbench on the left.
		var mid4: Vector3 = base + side * 3.2
		cam.global_position = mid4 + fwd * 4.8 + Vector3.UP * 1.5
		cam.look_at(mid4 + Vector3.UP * 0.45)
		light.global_position = cam.global_position + Vector3.UP * 0.3
		fill.global_position = mid4 + fwd * 2.0 + Vector3.UP * 2.0
		await _wait(0.4)
		await RenderingServer.frame_post_draw
		_main.take_screenshot(_shots.path_join("creature_%s_looks.png" % c[0]))
		lineup.queue_free()
		await _wait(0.1)
	await _live(base, fwd, side, cam, light, fill)


## Real game monsters (with their real collision) beside the workbench: a beetle winding up its charge
## (the attack warning: red eyes, its glow blazing, head down), a snail hiding, a bat in the air.
func _live(base: Vector3, fwd: Vector3, side: Vector3, cam: Camera3D, light: OmniLight3D, fill: OmniLight3D) -> void:
	var mm: MonsterManager = GameAuthority.instance.monsters
	var spots := {"rock_beetle": [1.6, "red"], "rock_snail": [3.3, "green"], "cave_bat": [4.9, "blue"]}
	var made := {}
	for kind in spots:
		var at: Vector3 = base + side * float(spots[kind][0])
		at = _main.world.maker.find_floor(at.x, at.z, at.y + 2.0) + Vector3.UP * (1.2 if kind == "cave_bat" else 0.3)
		var uid: int = mm._next_uid
		mm._ev_spawn(uid, kind, at, false, 99, spots[kind][1])
		mm._next_uid = uid + 1
		made[kind] = mm.monsters[uid]
		(made[kind] as Monster).state = Monster.State.IDLE  # awake (a sleeping bat would hang from the floor)
	mm.set_physics_process(false)  # a still life
	await _wait(0.3)
	for kind in made:
		var m: Monster = made[kind]
		m.model.rotation.y = atan2(-fwd.x, -fwd.z) + PI - 0.4  # face the camera
		var cap: CapsuleShape3D = (m.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D).shape
		print("LIVE ", kind, " ", m.variant, ": collision capsule radius %.2f height %.2f, look %s" % [cap.radius, cap.height, m.model.get_meta("variant_look", false)])
	(made["rock_beetle"] as Monster).show_tell(3.0, "Charge")
	MonsterModel.set_shell((made["rock_snail"] as Monster).model, true)
	(made["rock_snail"] as Monster).shell_shut = true
	await _wait(1.2)
	var mid: Vector3 = base + side * 3.2
	cam.global_position = mid + fwd * 4.6 + Vector3.UP * 1.6
	cam.look_at(mid + Vector3.UP * 0.5)
	light.global_position = cam.global_position + Vector3.UP * 0.3
	fill.global_position = mid + fwd * 2.0 + Vector3.UP * 2.0
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("creature_live_attack_warning.png"))
	var b: Vector3 = (made["rock_beetle"] as Monster).global_position
	cam.global_position = b + fwd * 2.4 + Vector3.UP * 1.0 + side * 0.4
	cam.look_at(b + Vector3.UP * 0.35)
	light.global_position = cam.global_position + Vector3.UP * 0.3
	await RenderingServer.frame_post_draw
	_main.take_screenshot(_shots.path_join("creature_live_charge_closeup.png"))
