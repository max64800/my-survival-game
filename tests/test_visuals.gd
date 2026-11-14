extends TestCase
## The look of the game: shared materials, the rigged dwarf, tools, fire, rock chips, textures.


func test_look_materials_are_shared_and_textured() -> void:
	var a := Look.mat(Color(0.5, 0.4, 0.3), "wood")
	var b := Look.mat(Color(0.5, 0.4, 0.3), "wood")
	check(a == b, "the same colour + surface gives the very same material (saves memory)")
	check(a is ShaderMaterial, "solid things use the painted prop shader")
	check((a as ShaderMaterial).get_shader_parameter("detail_tex") != null, "the painted grain texture is loaded")
	check(Look.mat(Color(1, 1, 1, 0.5)) is StandardMaterial3D, "see-through things keep the simple material")
	check_eq(Look.guess(Color(0.5, 0.5, 0.5)), "stone", "grey is stone")
	check_eq(Look.guess(Color(0.45, 0.31, 0.19)), "wood", "brown is wood")


func test_terrain_textures_have_one_slice_per_material() -> void:
	var albedo = load("res://assets/textures/terrain/terrain_albedo.png")
	var normal = load("res://assets/textures/terrain/terrain_normal.png")
	check(albedo is TextureLayered and albedo.get_layers() == 16, "rock colours: 16 slices (one per Mat number)")
	check(normal is TextureLayered and normal.get_layers() == 16, "rock bumps: 16 slices")


func test_rigged_dwarf_builds_and_animates() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	check(m.dwarf_rig != null, "the real dwarf is the default look")
	var rig := m.dwarf_rig
	for what in ["idle", "walk", "jog", "sprint", "air", "roll", "dig", "attack_a", "block", "eat"]:
		check(rig.tree.has_animation(DwarfRig.ANIMS[what]), "has the %s animation" % what)
	check(m.left_hand != null and m._hand != null, "has hands for the lantern and tools")
	check(rig.find_children("*", "BoneAttachment3D", true, false).size() >= 3, "helmet + two hands ride on bones")
	var sk := rig.skeleton
	var pelvis := sk.find_bone("pelvis")
	var before := sk.get_bone_pose_rotation(sk.find_bone("upperarm_l"))
	await frames(20)
	check(not sk.get_bone_pose_rotation(sk.find_bone("upperarm_l")).is_equal_approx(sk.get_bone_rest(sk.find_bone("upperarm_l")).basis.get_rotation_quaternion()), "the idle animation moves the arms (not stuck in a T-pose)")
	check(pelvis >= 0 and before != null, "skeleton has the bones we use")
	m.swing(0.5)
	check(m.swinging, "swinging starts")
	m.free()


func test_dwarf_is_short_and_wide() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	await frames(5)
	var sk := m.dwarf_rig.skeleton
	var head := (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head"))).origin
	var foot := (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("foot_l"))).origin
	check(head.y > 0.8 and head.y < 1.25, "head at dwarf height (%.2f m)" % head.y)
	check(foot.y < 0.25, "feet stay on the ground (%.2f m)" % foot.y)
	check(m.dwarf_rig.scale.x > m.dwarf_rig.scale.y * 1.3, "squashed wider than tall")
	m.free()


func test_tool_models_cover_every_tool() -> void:
	for look in ["pickaxe", "axe", "axe_2h", "sword", "mace", "mace_2h", "spear", "hammer", "shield", "crossbow", "food"]:
		var t := ToolModels.build(look, Color(0.6, 0.6, 0.6), DwarfModel.VISUAL_LAYER)
		var meshes := t.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() >= 1, "%s has a model" % look)
		for mi: MeshInstance3D in meshes:
			check(mi.layers == DwarfModel.VISUAL_LAYER, "%s sits on the dwarf's layer (no lantern self-shadow)" % look)
		t.free()
	var empty := ToolModels.build("fists", Color.WHITE, 2)
	check(empty.get_child_count() == 0, "bare fists hold nothing")
	empty.free()


func test_fire_and_chips_make_particles() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var fire := Fire.new(1.0)
	root.add_child(fire)
	check(fire.find_children("*", "GPUParticles3D", true, false).size() == 3, "fire = flames + embers + smoke")
	Fx.burst(root, Vector3.ZERO, Color(0.5, 0.48, 0.45), 12)
	check(root.find_children("*", "CPUParticles3D", true, false).size() == 2, "digging = chips + a dust puff")
	Fx.burst(root, Vector3.ZERO, Color(0.4, 0.75, 1.0), 4)
	check(root.find_children("*", "CPUParticles3D", true, false).size() == 3, "crystal sparks glow, no dust")
	root.free()
