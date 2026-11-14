extends Node
## Art pack lineup: today's placeholder dwarf next to free CC0 character candidates, in the
## cave with lantern light, squashed into dwarf proportions. Takes screenshots, then quits.
##   godot --path . -- seed=42 nomonsters artpreview shots=/some/folder

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
	var dwarf: Dwarf = _main.dwarf
	dwarf.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
