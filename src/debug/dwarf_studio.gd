extends SceneTree
## Photo studio for the dwarf: bright even light, front + side cameras, a few poses
## (idle, mid-swing, strike, walking, attack). Saves pictures, then quits.
##   godot --audio-driver Dummy --path . --script res://src/debug/dwarf_studio.gd -- shots=/folder
## (Put "autopilot" in the folder name so the OBS auto-recorder skips the run.)

var _shots := "user://studio"
var _cam: Camera3D
var _model: DwarfModel


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.33, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.68)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child.call_deferred(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-40), deg_to_rad(30), 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	root.add_child.call_deferred(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	floor_mi.mesh = pm
	floor_mi.material_override = Look.mat(Color(0.4, 0.37, 0.33), "stone")
	root.add_child.call_deferred(floor_mi)
	_model = DwarfModel.new()
	_model.tunic = DwarfModel.TUNICS[0]
	root.add_child.call_deferred(_model)
	_cam = Camera3D.new()
	_cam.fov = 35.0
	root.add_child.call_deferred(_cam)
	_run.call_deferred()


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _view(dir: Vector3, dist: float = 3.2, at_y: float = 0.7) -> void:
	_cam.global_position = Vector3(0, at_y + 0.25, 0) + dir.normalized() * dist
	_cam.look_at(Vector3(0, at_y, 0))


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(_shots.path_join(name + ".png"))
	print("  studio: ", name)


func _both(name: String) -> void:
	_view(Vector3(0.35, 0, -1))  # the dwarf faces -Z: this is the front
	await _shot(name + "_front")
	_view(Vector3(1, 0, -0.1))
	await _shot(name + "_side")


func _run() -> void:
	await _wait(0.5)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("sheet="):
			await _anim_sheet(arg.trim_prefix("sheet=").split(","))
			quit()
			return
	if "props" in OS.get_cmdline_user_args():
		await _props_test()
		quit()
		return
	if "monsters" in OS.get_cmdline_user_args():
		await _monster_lineup()
		quit()
		return
	if "armor" in OS.get_cmdline_user_args():
		await _armor_lineup()
		quit()
		return
	if "three" in OS.get_cmdline_user_args():
		await _three_lineup()
		quit()
		return
	if "creatures" in OS.get_cmdline_user_args():
		await _creature_shoot()
		quit()
		return
	if "variety" in OS.get_cmdline_user_args():
		await _variety_shoot()
		quit()
		return
	if "fire" in OS.get_cmdline_user_args():
		await _fire_test()
		quit()
		return
	if "speartest" in OS.get_cmdline_user_args():
		_model.set_held("spear_stone")
		await _wait(0.5)
		await _both("spear_idle")
		for t in [0.15, 0.3]:
			_model.swinging = false
			_model.attack(0.6, false)
			await _wait(t)
			_view(Vector3(1, 0, -0.1))
			await _shot("spear_stab_%.2f" % t)
			await _wait(0.8)
		quit()
		return
	if "gripcheck" in OS.get_cmdline_user_args():
		await _grip_check()
		quit()
		return
	if "toolstrikes" in OS.get_cmdline_user_args():
		await _tool_strikes()
		quit()
		return
	if "swordtest" in OS.get_cmdline_user_args():
		await _sword_test()
		quit()
		return
	if "running" in OS.get_cmdline_user_args():
		await _running_test()
		quit()
		return
	if "rots" in OS.get_cmdline_user_args():
		await _rot_lineup()
		quit()
		return
	_model.set_held("pickaxe_stone")
	_model.set_motion(0.0, true, false)
	await _wait(0.6)
	await _both("1_idle")
	_view(Vector3(0.2, 0.1, -1), 1.3, 1.0)
	await _shot("1_face")
	for t in [0.15, 0.3, 0.42]:
		_model.swinging = false
		_model.swing(0.55)
		await _wait(t)
		_view(Vector3(1, 0, -0.3))
		await _shot("2_dig_%.2f" % t)
		await _wait(0.8)
	_model.set_held("sword_stone")
	_model.attack(0.5, false)
	await _wait(0.2)
	await _both("3_attack")
	await _wait(0.6)
	_model.set_held("pickaxe_stone")
	for i in 30:
		_model.set_motion(4.0, true, false)
		await process_frame
	await _both("4_jog")
	for i in 20:
		_model.set_motion(0.0, true, false)
		await process_frame
	_model.set_held("sword_stone")
	_model.set_pose(true, false, false)
	await _wait(0.5)
	await _both("5_block")
	_model.set_shield("shield_stone")  # (on the left arm)
	_model.set_pose(true, false, true)
	await _wait(0.5)
	await _both("6_shield")
	_model.set_shield("")
	_model.set_held("crossbow_stone")
	_model.set_pose(false, true, false)
	await _wait(0.5)
	await _both("7_aim")
	_model.set_pose(false, false, false)
	_model.set_held("")
	await _wait(0.4)
	_model.react("hit")
	await _wait(0.15)
	await _both("8_hit")
	await _wait(0.6)
	_model.react("eat")
	await _wait(0.6)
	await _both("9_eat")
	await _wait(1.0)
	_model.set_wear(["spore_mask"])
	await _wait(0.3)
	_view(Vector3(0.3, 0.05, -1), 1.6, 0.95)
	await _shot("10_mask")
	_model.set_wear([])
	_model.set_held("sword_copper")
	_model.swinging = false
	_model.attack(0.5, true)
	await _wait(0.3)
	await _both("11_trail")
	_model.set_held("")
	for i in 40:
		_model.set_climbing(true, 0.05)
		await process_frame
	await _both("12_climb")
	await _wait(0.25)
	await _both("12b_climb")
	quit()


## Tuning aid: the dwarf sprinting with a pickaxe, photographed from the side 5 times (the tool must not go through his head).
func _running_test() -> void:
	_model.set_held("pickaxe_stone")
	_view(Vector3(1, 0.1, -0.15), 3.4, 0.7)
	for k in 5:
		for i in 9:
			_model.set_motion(6.5, true, false)
			await process_frame
		var rig := _model.dwarf_rig
		var sk := rig.skeleton
		var head := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
		var tip := (rig.right_hand.get_child(0) as Node3D).global_transform * Vector3(0, 0.55, 0)
		print("tool tip ", tip, " head ", head, " apart %.2f m" % tip.distance_to(head))
		await _shot("run_%d" % k)


## Tuning aid: every tool's move photographed from his right side at its strike moment, through the game's own calls
## (DwarfModel.swing / attack / set_pose), all on one sheet (tool_strikes.png, 4 x 2; he faces right). Prints where the
## tool's far end is: how far in front of his chest, how far from his head (it must be well in front, away from the head).
## [label, item, call, seconds (played slow for a sharp picture), moment of the strike (0..1)]
const STRIKES := [
	["pick", "pickaxe_copper", "swing", 1.6, 0.55, -1], ["axe", "axe_copper", "swing", 1.8, 0.55, -1],
	["sword hit 1", "sword_copper", "attack", 1.6, 0.38, 0], ["sword hit 2", "sword_copper", "attack", 1.6, 0.4, 1],
	["mace hit 1", "mace_copper", "attack", 1.6, 0.33, 0], ["mace hit 2", "mace_copper", "attack", 1.6, 0.38, 1],
	["spear", "spear_copper", "attack", 1.2, 0.42, 0], ["shield block", "sword_copper", "block", 0.8, 1.0, -1],
	["walk", "pickaxe_copper", "walk", 1.0, 1.0, -1], ["run", "pickaxe_copper", "run", 1.2, 1.0, -1],
	["roll", "pickaxe_copper", "roll", 0.75, 0.45, -1], ["standing front", "pickaxe_copper", "front", 0.6, 1.0, -1],
]  # [label, item, call, seconds, moment (0..1), combo hit]. The shield: always on the left arm (DwarfModel.set_shield).


func _tool_strikes() -> void:
	var sheet := Image.create(4 * 360, 3 * 360, false, Image.FORMAT_RGBA8)
	var rig := _model.dwarf_rig
	var sk := rig.skeleton
	for i in STRIKES.size():
		var s: Array = STRIKES[i]
		_cam.global_position = Vector3(4.4, 0.95, -0.55)  # his right side, centred a little in front of him (the tools reach)
		_cam.look_at(Vector3(0, 0.8, -0.55))
		_model.set_pose(false, false, false)
		_model.set_held(s[1])
		_model.set_shield("shield_copper" if s[0].begins_with("shield") else "")
		for f in 30:
			_model.set_motion(0.0, true, false)
			await process_frame
		_model.swinging = false
		var start := Time.get_ticks_msec()
		match s[2]:
			"swing":
				_model.swing(s[3])
			"attack":
				_model.attack(s[3], false, s[5])
			"block":
				_model.set_pose(true, false, true)
			"front":
				_view(Vector3(0.15, 0, -1))
		while Time.get_ticks_msec() - start < s[3] * s[4] * 1000.0:  # (the game calls set_motion every frame)
			_model.set_motion({"walk": 1.6, "run": 6.5, "roll": 3.0}.get(s[2], 0.0), true, s[2] == "roll")
			await process_frame
		var tool := (_model.dwarf_rig.shield_grip if s[0].begins_with("shield") else _model._hand).get_child(0) as Node3D
		var tip := _far_end(tool)
		var head := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin
		var handle_mid := tool.global_transform * Vector3(0, 0.3, 0)
		print("%-14s tip %s  in front of the dwarf %.2f m  tip-head %.2f m  handle middle-head %.2f m" % [s[0], tip,
			-tip.z, tip.distance_to(head), handle_mid.distance_to(head)])
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		var side := mini(img.get_width(), img.get_height())
		var sq := img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
		sq.resize(360, 360)
		sq.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(sq, Rect2i(0, 0, 360, 360), Vector2i((i % 4) * 360, (i / 4) * 360))
		for f in 40:
			_model.set_motion(0.0, true, false)
			await process_frame
		await _wait(s[3] * (1.0 - s[4]) + 0.3)
	sheet.save_png(_shots.path_join("tool_strikes.png"))
	print("  studio: tool_strikes")


## Tuning aid: close-ups of the right fist holding the axe, pick and sword (standing still): the fist must close round
## the wrapped grip, the handle's end showing a little below it (owner, Nov 17). One sheet, grip_check.png.
func _grip_check() -> void:
	var sheet := Image.create(3 * 360, 360, false, Image.FORMAT_RGBA8)
	var items := ["axe_copper", "pickaxe_copper", "sword_copper"]
	for i in items.size():
		_model.set_held(items[i])
		for f in 40:
			_model.set_motion(0.0, true, false)
			await process_frame
		var fist := _model.dwarf_rig.right_hand.global_position
		_cam.global_position = fist + Vector3(0.9, 0.15, -0.35)
		_cam.look_at(fist)
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		var side := mini(img.get_width(), img.get_height())
		var sq := img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
		sq.resize(360, 360)
		sq.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(sq, Rect2i(0, 0, 360, 360), Vector2i(i * 360, 0))
	sheet.save_png(_shots.path_join("grip_check.png"))
	print("  studio: grip_check")


## The point of a held tool farthest from the fist (the pick's point, the blade's tip, the spear's head).
func _far_end(tool: Node3D) -> Vector3:
	var best := Vector3.ZERO
	for mi: MeshInstance3D in tool.find_children("*", "MeshInstance3D", true, false):
		var xf := tool.global_transform.affine_inverse() * mi.global_transform
		for k in mi.mesh.get_surface_count():
			for v: Vector3 in mi.mesh.surface_get_arrays(k)[Mesh.ARRAY_VERTEX]:
				var p := xf * v
				if p.length() > best.length():
					best = p
	return tool.global_transform * best


## Tuning aid: a sword attack seen from the side at 5 moments (the head and neck must keep their shape).
func _sword_test() -> void:
	_model.set_held("sword_stone")
	await _wait(0.4)
	_view(Vector3(1, 0.1, -0.15), 3.4, 0.7)
	var sk := _model.dwarf_rig.skeleton
	for k in 5:
		_model.swinging = false
		_model.attack(1.0, false)
		await _wait(0.1 + k * 0.18)
		var line := "t=%.2f" % (0.1 + k * 0.18)
		for bn in ["spine_03", "neck_01", "Head"]:
			var g := sk.get_bone_global_pose(sk.find_bone(bn))
			line += "  %s scale %s" % [bn, g.basis.get_scale()]
		print(line)
		await _shot("sword_%d" % k)
		await _wait(1.2)


## Tuning aid: 4 dwarfs, each holding the pickaxe turned a different way.
func _rot_lineup() -> void:
	_model.queue_free()
	var rots := [Vector3(90, 0, 0), Vector3(-90, 0, 0), Vector3(0, 0, 90), Vector3(0, 0, -90)]
	var models := []
	for i in rots.size():
		DwarfModel.hand_tool_rot = rots[i] * PI / 180.0
		var m := DwarfModel.new()
		m.position = Vector3((i - 1.5) * 1.3, 0, 0)
		root.add_child(m)
		m.set_held("pickaxe_stone")
		models.append(m)
	await _wait(0.6)
	_view(Vector3(0.3, 0.1, -1), 6.5, 0.6)
	await _shot("r_idle_front")
	_view(Vector3(1, 0.1, -0.2), 7.5, 0.6)
	await _shot("r_idle_side")
	for m in models:
		m.swing(0.55)
	await _wait(0.33)
	_view(Vector3(0.3, 0.1, -1), 6.5, 0.6)
	await _shot("r_strike_front")


## Tuning aid: a campfire in the dark next to the dwarf. Prints the frame rate.
func _fire_test() -> void:
	var we: WorldEnvironment = root.find_children("*", "WorldEnvironment", true, false)[0]
	we.environment.background_color = Color(0.02, 0.02, 0.03)
	we.environment.ambient_light_energy = 0.08
	we.environment.glow_enabled = true
	for l in root.find_children("*", "DirectionalLight3D", true, false):
		l.visible = false
	var fire := Fire.new(1.0)
	fire.position = Vector3(0.9, 0, -0.4)
	root.add_child(fire)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.3)
	light.omni_range = 9.0
	light.light_energy = 1.8
	light.position = fire.position + Vector3.UP * 0.6
	root.add_child(light)
	_model.set_held("pickaxe_stone")
	_view(Vector3(0.6, 0.15, -1), 3.6, 0.6)
	await _wait(0.3)
	print("  fps right away: ", Engine.get_frames_per_second())
	await _shot("f_fire_early")
	await _wait(3.0)
	print("  fps after 3 s: ", Engine.get_frames_per_second())
	await _shot("f_fire_later")


## Tuning aid: freeze each named animation at 5 moments and photograph it from the side.
##   -- sheet=Sword_Attack,b/TreeChopping
func _anim_sheet(names: Array) -> void:
	_model.set_held("pickaxe_stone")
	var rig := _model.dwarf_rig
	rig.tree.active = false
	var ap := AnimationPlayer.new()
	rig.tree.get_parent().add_child(ap)
	for lib in rig.tree.get_animation_library_list():
		ap.add_animation_library(lib, rig.tree.get_animation_library(lib))
	_view(Vector3(1, 0.1, -0.15), 3.4, 0.7)
	for n in names:
		if not ap.has_animation(n):
			print("  no animation ", n)
			continue
		var length := ap.get_animation(n).length
		for k in 5:
			var t := length * (0.1 + 0.2 * k)
			ap.play(n)
			ap.seek(t, true)
			ap.pause()
			await process_frame
			await process_frame
			await _shot("s_%s_%d_t%.2f" % [n.replace("/", "_"), k, t])


## Tuning aid: a stalactite cluster and a hanging root next to the dwarf.
func _props_test() -> void:
	for i in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = Clutter._stalactite_mesh()
		mi.material_override = Look.mat(Color(0.5, 0.46, 0.41), "stone")
		var len: float = [1.6, 0.6, 0.4][i]
		mi.position = Vector3(0.9 + i * 0.35, 2.4, -0.3 + i * 0.2)
		mi.scale = Vector3(len * 0.2, len, len * 0.2)
		root.add_child(mi)
	var gf := GlowField.new()
	var root_mi := MeshInstance3D.new()
	root_mi.mesh = gf._make_root_mesh()
	root_mi.material_override = Look.mat(Color(0.42, 0.29, 0.18), "bark", 0.12, 0.025)
	root_mi.position = Vector3(-0.9, 2.4, -0.3)
	root_mi.rotation.x = PI  # hangs down (its +Y points down)
	root_mi.scale = Vector3(1, 1.8, 1)
	root.add_child(root_mi)
	gf.free()
	_model.set_held("pickaxe_stone")
	_view(Vector3(0.2, 0.3, -1), 5.0, 1.2)
	await _wait(0.5)
	await _shot("p_props")


## Tuning aid: every monster shape in a row, frozen mid-stride (walking at 3 m/s).
func _monster_lineup() -> void:
	_model.visible = false
	var shapes := ["rock_snail", "cave_bat", "rock_beetle"]  # (the simple-shape bodies left, Nov 19)
	var models := []
	for i in shapes.size():
		var m := MonsterModel.build(shapes[i], Color.from_hsv(i / 3.0, 0.45, 0.6), 1.0, i == 1)
		m.position = Vector3((i % 5 - 2) * 1.6, 0, -int(i / 5) * 1.8)
		root.add_child(m)
		models.append(m)
	for k in 2:
		for m in models:
			MonsterModel.animate(m, 3.0, 1.0, 0.31 + k * 0.17)
		_view(Vector3(0.25, 0.45, 1), 9.0, 0.3)
		await _wait(0.3)
		await _shot("m_lineup_%d" % k)


## Tuning aid: one dwarf per armor material, full set each (docs/design/armor.md).
func _armor_lineup() -> void:
	_model.visible = false
	var tiers := ["hide", "copper", "husk", "silver", "ironshell"]
	for i in tiers.size():
		var m := DwarfModel.new()
		m.position = Vector3((i - 2) * 1.25, 0, 0)
		root.add_child(m)
		m.set_held("pickaxe_stone")
		m.set_wear(["armor_head_" + tiers[i], "armor_chest_" + tiers[i], "armor_feet_" + tiers[i]])
	await _wait(0.6)
	_view(Vector3(0.15, 0.1, -1), 6.3, 0.6)
	await _shot("a_armor_front")
	_view(Vector3(0.9, 0.1, -0.5), 6.5, 0.6)
	await _shot("a_armor_side")


## Tuning aid: the first three creatures (snail out + hiding, bat flying + roosting, beetle front + back).
func _three_lineup() -> void:
	_model.position = Vector3(-2.6, 0, 0)
	var make := func(shape: String, col: Color, size: float, at: Vector3, yaw: float) -> Node3D:
		var m := MonsterModel.build(shape, col, size, false, shape)  # the hand-built model when there is one
		m.position = at
		m.rotation.y = yaw
		root.add_child(m)
		return m
	var snail: Node3D = make.call("rock_snail", Color(0.48, 0.44, 0.38), 1.0, Vector3(-1.2, 0, 0), 0.6)
	var hiding: Node3D = make.call("rock_snail", Color(0.48, 0.44, 0.38), 1.0, Vector3(-1.2, 0, 1.6), 0.6)
	MonsterModel.set_shell(hiding, true)
	var bat: Node3D = make.call("cave_bat", Color(0.3, 0.26, 0.28), 1.0, Vector3(0.6, 0.6, 0), 0.4)
	var roost: Node3D = make.call("cave_bat", Color(0.3, 0.26, 0.28), 1.0, Vector3(0.6, 1.4, 1.8), 0.4)
	roost.set_meta("roosting", true)
	var beetle: Node3D = make.call("rock_beetle", Color(0.42, 0.39, 0.35), 0.9, Vector3(2.4, 0, 0), 0.7)
	var back: Node3D = make.call("rock_beetle", Color(0.42, 0.39, 0.35), 0.9, Vector3(2.4, 0, 1.8), 0.7 + PI)
	for m in [snail, bat, beetle, back]:
		MonsterModel.animate(m, 2.0, 1.0, 0.4)
	MonsterModel.animate(roost, 0.0, 1.0, 0.4)
	await _wait(0.6)
	_view(Vector3(0.2, 0.35, -1), 7.0, 0.5)
	await _shot("t_three")
	_view(Vector3(0.9, 0.25, -0.4), 6.0, 0.5)
	await _shot("t_three_side")
	# A beetle winding up its charge: red eyes and a dust trail behind it.
	MonsterModel.set_angry(beetle, true)
	MonsterModel.set_glow(beetle, 1.0)
	var front := -Basis(Vector3.UP, beetle.rotation.y).z
	for i in 6:
		Fx.dust(root, beetle.position - front * (0.5 + 0.3 * i), Color(0.45, 0.4, 0.33), 3, 0.45)
		await _wait(0.04)
	_cam.global_position = beetle.position + front * 3.4 + Vector3.UP * 0.9
	_cam.look_at(beetle.position + front * 0.6 + Vector3.UP * 0.35)
	await _shot("t_charge")


# ---------------------------------------------------------------- creature photo shoot
## One creature at a time, close up, in each pose the game uses (walking frames, hiding, asleep,
## charging, leader). For checking the hand-built models (tools/asset_forge/builds/monster_*.py).
var _stand: Node3D


func _creature(kind: String, shape: String, size: float, leader := false, at_y := 0.0) -> Node3D:
	if _stand:
		_stand.queue_free()
	_stand = Node3D.new()  # animate() moves the model's own height, so lift a stand instead
	_stand.position = Vector3(0, at_y, 0)
	root.add_child(_stand)
	var m := MonsterModel.build(shape, Color(0.45, 0.42, 0.38), size, leader, kind, 0)
	_stand.add_child(m)
	return m


func _aim(target: Vector3, dir: Vector3, dist: float) -> void:
	_cam.global_position = target + dir.normalized() * dist
	_cam.look_at(target)


func _creature_shoot() -> void:
	_model.visible = false
	# Rock Snail: crawling, eye stalks looking around
	var m := _creature("rock_snail", "rock_snail", 1.0)
	MonsterModel.animate(m, 0.6, 1.0, 0.7)
	await _wait(0.2)
	_aim(Vector3(0, 0.5, 0), Vector3(-0.8, 0.45, -1.0), 2.9)
	await _shot("c_snail")
	_aim(Vector3(0, 0.5, 0), Vector3(1, 0.25, 0), 2.9)
	await _shot("c_snail_side")
	# ... hiding: only two eyes peek out
	MonsterModel.set_shell(m, true)
	await _wait(0.5)
	_aim(Vector3(0, 0.4, 0), Vector3(-0.8, 0.45, -1.0), 2.6)
	await _shot("c_snail_hiding")
	m = _creature("rock_snail", "rock_snail", 1.3, true)
	MonsterModel.animate(m, 0.0, 1.3, 0.2)
	await _wait(0.2)
	_aim(Vector3(0, 0.8, 0), Vector3(-0.8, 0.5, -1.0), 3.8)
	await _shot("c_snail_leader")
	# Cave Bat: flying (two moments of the wing beat), then asleep under a ceiling
	m = _creature("cave_bat", "cave_bat", 1.0, false, 0.6)
	for k in [0.0, 0.17]:
		MonsterModel.animate(m, 2.0, 1.0, 0.3 + k)
		await _wait(0.1)
		_aim(Vector3(0, 1.1, 0), Vector3(-0.7, 0.5, -1.0), 2.6)
		await _shot("c_bat_fly_%d" % roundi(k * 100))
		_aim(Vector3(0, 1.1, 0), Vector3(0, 0.05, -1.0), 2.8)
		await _shot("c_bat_front_%d" % roundi(k * 100))
	m = _creature("cave_bat", "cave_bat", 1.0, false, 2.2)
	var ceiling := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(2.0, 0.2, 2.0)
	ceiling.mesh = slab
	ceiling.position = Vector3(0, 2.6, 0)
	_stand.add_child(ceiling)
	ceiling.position = Vector3(0, 0.62, 0)
	m.set_meta("roosting", true)
	MonsterModel.animate(m, 0.0, 1.0, 0.3)
	await _wait(0.1)
	_aim(Vector3(0, 2.1, 0), Vector3(-1.0, -0.1, -0.8), 2.4)
	await _shot("c_bat_asleep")
	_aim(Vector3(0, 2.1, 0), Vector3(1, -0.05, 0), 2.4)
	await _shot("c_bat_asleep_side")
	# Rock Beetle: standing (all feet down), four walking frames from the side, charging
	m = _creature("rock_beetle", "rock_beetle", 0.9)
	MonsterModel.animate(m, 0.0, 0.9, 0.3)
	await _wait(0.1)
	_aim(Vector3(0, 0.35, 0), Vector3(-0.3, 0.12, -1.0), 2.6)
	await _shot("c_beetle_stand_front")
	_aim(Vector3(0, 0.4, 0), Vector3(-0.8, 0.5, -1.0), 2.8)
	await _shot("c_beetle")
	for k in 4:
		MonsterModel.animate(m, 2.5, 0.9, 0.3 + k * 0.09)
		await _wait(0.05)
		_aim(Vector3(0, 0.35, 0), Vector3(1, 0.15, 0), 2.6)
		await _shot("c_beetle_walk%d" % k)
	MonsterModel.animate(m, 0.0, 0.9, 0.3)
	MonsterModel.set_angry(m, true)
	MonsterModel.set_glow(m, 0.35)
	m.rotation.x -= 0.22  # the charge pose (Monster._creature_fx does this in the game)
	m.position.y += 0.05 * 0.9
	for i in 5:
		Fx.dust(_stand, Vector3(0.15 * (i % 2), 0, 0.3 + 0.25 * i), Color(0.45, 0.4, 0.33), 3, 0.45)
	await _wait(0.12)
	_aim(Vector3(0, 0.4, 0), Vector3(-0.8, 0.45, -1.0), 2.8)
	await _shot("c_beetle_charge")
	_aim(Vector3(0, 0.4, 0), Vector3(1, 0.2, 0.15), 2.8)
	await _shot("c_beetle_charge_side")
	m = _creature("great_rock_beetle", "rock_beetle", 1.5)
	MonsterModel.animate(m, 0.0, 1.5, 0.3)
	await _wait(0.1)
	_aim(Vector3(0, 0.7, 0), Vector3(-0.8, 0.5, -1.0), 4.4)
	await _shot("c_great")
	_aim(Vector3(0, 0.7, 0), Vector3(0.7, 0.6, 1.0), 4.4)
	await _shot("c_great_back")


## Every individual version side by side, one row per creature (seed = version number).
func _variety_shoot() -> void:
	_model.visible = false
	var rows := [["rock_beetle", "rock_beetle", 0.9, 0.0], ["great_rock_beetle", "rock_beetle", 1.5, 0.0],
		["cave_bat", "cave_bat", 1.0, 0.4], ["rock_snail", "rock_snail", 1.0, 0.0]]
	for r in rows.size():
		var row: Array = rows[r]
		var n := MonsterModel.variant_count(row[0])
		var gap := 1.7 * float(row[2]) + 0.4
		var group := Node3D.new()
		root.add_child(group)
		for v in n:
			var m := MonsterModel.build(row[1], Color.WHITE, row[2], false, row[0], v)
			var stand := Node3D.new()
			stand.position = Vector3((v - (n - 1) / 2.0) * gap, row[3], 0)
			stand.rotation.y = 0.5
			group.add_child(stand)
			stand.add_child(m)
			MonsterModel.animate(m, 0.0 if row[0] != "cave_bat" else 2.0, row[2], 0.35 + v * 0.1)
		await _wait(0.15)
		var w := gap * n
		_aim(Vector3(0, 0.5 * row[2] + row[3], 0), Vector3(-0.15, 0.45, -1.0), w * 0.95 + 1.2)
		await _shot("v_%s" % row[0])
		group.queue_free()
		await _wait(0.05)
