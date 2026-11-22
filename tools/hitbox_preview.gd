extends SceneTree
## Pictures of every hitbox (owner, Nov 22: "give me an artifact of what you think it's going to look like").
## Builds the dwarf with each weapon and every creature, freezes each at the moment its blow lands and saves a
## picture with the HitShapes drawn on top (green = can be hurt, red = what hurts in this attack).
##   godot --audio-driver Dummy --path . --script res://tools/hitbox_preview.gd -- claude=hitboxes out=<folder> [only=name]

var out := "user://hitbox_preview"
var only := ""
var cam: Camera3D
var im := ImmediateMesh.new()
var label: Label
var stage: Node3D
var shots: Array = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
		elif a.begins_with("only="):
			only = a.substr(5)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(900, 700)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.13, 0.12, 0.11)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.environment.ambient_light_energy = 0.9
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.6, 0)
	root.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.23, 0.21)
	floor_mi.material_override = fm
	root.add_child(floor_mi)
	cam = Camera3D.new()
	cam.fov = 40
	root.add_child(cam)
	var wire := MeshInstance3D.new()
	wire.mesh = im
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.vertex_color_use_as_albedo = true
	wm.no_depth_test = true
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wire.material_override = wm
	root.add_child(wire)
	var ui := CanvasLayer.new()
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	ui.add_child(label)
	root.add_child(ui)
	await process_frame

	# --- the dwarf ---------------------------------------------------------
	await _dwarf_shot("dwarf_body", "Dwarf: where he can be hurt", "", "", "", false, 0)
	for w in [["sword", "sword_copper"], ["axe", "axe_copper"], ["mace", "mace_copper"], ["spear", "spear_copper"],
			["axe_2h", "axe_2h_copper"], ["mace_2h", "mace_2h_copper"], ["pickaxe", "pickaxe_copper"]]:
		await _dwarf_shot("dwarf_" + w[0], "Dwarf: %s swing" % _nice(w[0]), w[1], "", "weapon", false, 0)
	await _dwarf_shot("dwarf_mace_2h_slam", "Dwarf: two-handed mace, heavy ground slam", "mace_2h_copper", "", "slam", true, 0)
	await _dwarf_shot("dwarf_shield", "Dwarf: shield bash", "", "shield_stone", "shield", false, 0, "shield")
	await _dwarf_shot("dwarf_fists", "Dwarf: punch", "", "", "fists", false, 0, "fists")

	# --- creatures ----------------------------------------------------------
	for kind: String in Monsters.LIST.keys():
		var d: Dictionary = Monsters.LIST[kind]
		await _monster_shot(kind, d, "", "")  # its body
		var seen := {}
		for atk: Dictionary in d.get("attacks", []):
			if int(atk.get("damage", 0)) <= 0:
				continue  # (the Rally Slam only wakes the miners)
			var part: String = HitShapes.ATTACK_PART.get(atk.name, "weapon")
			var clip: String = atk.get("anim", "")
			var key := part + clip
			if seen.has(key):
				continue
			seen[key] = true
			await _monster_shot(kind, d, atk.name, part, clip)
	var f := FileAccess.open(out.path_join("shots.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(shots, "  "))
	f.close()
	print("HITBOX PREVIEW: %d pictures in %s" % [shots.size(), out])
	quit()


func _nice(w: String) -> String:
	return {axe_2h = "two-handed axe", mace_2h = "two-handed mace"}.get(w, w)


func _clear() -> void:
	if stage:
		stage.queue_free()
		await process_frame
	stage = Node3D.new()
	root.add_child(stage)
	Engine.time_scale = 1.0


func _dwarf_shot(id: String, title: String, item: String, shield: String, part: String, heavy: bool, step: int, move := "") -> void:
	if only != "" and not id.contains(only):
		return
	await _clear()
	var dm := DwarfModel.new()
	dm.art = "dwarf"
	stage.add_child(dm)
	for i in 4:
		await process_frame
	dm.set_held(item)
	if shield != "":
		dm.set_shield(shield)
	for i in 4:
		await process_frame
	if part != "":
		var weapon := move if move != "" else Combat.weapon_of(item)
		var dur := 1.2
		dm.attack(dur, heavy, step, move)
		await create_timer(dur * (0.40 if part != "slam" else 0.42)).timeout
		var hs := dm.hit_shapes
		if hs and hs.get_part(part):
			hs.flash(part, -1.0, 999.0)
		elif hs:
			print("HITBOX PREVIEW: %s has no '%s' shape (weapon %s)" % [id, part, weapon])
	await _snap(id, title, dm, part == "slam")


func _monster_shot(kind: String, d: Dictionary, atk_name: String, part: String, clip := "") -> void:
	var id := kind + ("" if atk_name == "" else "_" + atk_name.to_snake_case().replace("'", ""))
	if only != "" and not id.contains(only):
		return
	await _clear()
	var holder := Node3D.new()
	stage.add_child(holder)
	var model := MonsterModel.build(String(d.get("shape", kind)), d.get("color", Color.GRAY), float(d.get("size", 1.0)), false, kind, 1)
	holder.add_child(model)
	if d.get("shape", "") == "cave_bat" or kind == "cave_bat":
		model.position.y = 1.0  # (a bat flies)
	var rig := CreatureRig.find(model)
	for i in 3:
		await process_frame
	var hs := HitShapes.for_monster(model, kind, d)
	for i in 3:
		await process_frame
	if rig and clip != "":
		var tell := 0.8
		rig.attack(clip, tell)
		await create_timer(tell).timeout
	elif rig and d.get("ghost", false) == false:
		rig.ap.play("Idle")
		await create_timer(0.3).timeout
	if part != "":
		if hs.get_part(part):
			hs.flash(part, -1.0, 999.0)
		else:
			print("HITBOX PREVIEW: %s has no '%s' shape" % [id, part])
	var title := String(d.get("name", kind)) + (": where it can be hurt" if atk_name == "" else ": " + atk_name)
	await _snap(id, title, model, false)


func _snap(id: String, title: String, subject: Node3D, wide: bool) -> void:
	Engine.time_scale = 0.0
	await process_frame
	# Frame the subject: everything it has, its shapes too.
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in subject.find_children("*", "MeshInstance3D", true, false):
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		var b := mi.global_transform * mi.get_aabb()
		if b.size.length() > 30.0:
			continue
		box = b if first else box.merge(b)
		first = false
	for hs: HitShapes in get_nodes_in_group(HitShapes.GROUP):
		hs.sync()
		for p in hs.parts:
			if p.hurt or hs.is_active(p):
				var r := 0.3
				box = AABB(p.area.global_position - Vector3.ONE * r, Vector3.ONE * r * 2) if first else box.merge(AABB(p.area.global_position - Vector3.ONE * r, Vector3.ONE * r * 2))
				first = false
	if wide:
		box = box.merge(AABB(subject.global_position - Vector3(HitShapes.SLAM_RADIUS, 0, HitShapes.SLAM_RADIUS), Vector3(HitShapes.SLAM_RADIUS * 2, 1, HitShapes.SLAM_RADIUS * 2)))
	var c := box.get_center()
	var dist := maxf(box.size.length() * 1.35, 1.8)
	cam.global_position = c + Vector3(0.75, 0.55, -1.0).normalized() * dist  # in front (they face -Z), a bit to the side
	cam.look_at(c)
	label.text = title
	im.clear_surfaces()
	HitShapes.draw_all(self, im, false)
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var file := id + ".png"
	img.save_png(out.path_join(file))
	shots.append({id = id, title = title, file = file})
	Engine.time_scale = 1.0
