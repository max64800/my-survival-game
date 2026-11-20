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
	check(albedo is TextureLayered and albedo.get_layers() == 64, "rock colours: 64 slices (4 looks per Mat number)")
	check(normal is TextureLayered and normal.get_layers() == 64, "rock bumps: 64 slices")


func test_rigged_dwarf_builds_and_animates() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	check(m.dwarf_rig != null, "the real dwarf is the default look")
	var rig := m.dwarf_rig
	for what in ["idle", "walk", "jog", "sprint", "air", "roll", "dig", "attack_a", "block", "eat"]:
		check(rig.tree.has_animation(DwarfRig.ANIMS[what]), "has the %s animation" % what)
	check(m.left_hand != null and m._hand != null, "has hands for the lantern and tools")
	# (the hand-built body is bareheaded like the approved picture: no starting cap, so only the two hands)
	check(rig.find_children("*", "BoneAttachment3D", true, false).size() >= (2 if rig.use_body else 3), "helmet + two hands ride on bones")
	var sk := rig.skeleton
	var pelvis := sk.find_bone("pelvis")
	var before := sk.get_bone_pose_rotation(sk.find_bone("upperarm_l"))
	await frames(20)
	check(not sk.get_bone_pose_rotation(sk.find_bone("upperarm_l")).is_equal_approx(sk.get_bone_rest(sk.find_bone("upperarm_l")).basis.get_rotation_quaternion()), "the idle animation moves the arms (not stuck in a T-pose)")
	check(pelvis >= 0 and before != null, "skeleton has the bones we use")
	m.swing(0.5)
	check(m.swinging, "swinging starts")
	m.free()


## Owner, Nov 17: pick points / axe blade in the swing, each weapon its own move, the shield always on the left arm.
## Chat 15 (owner: "as perfect as it can get", "slowed down quite drastically"): the sword's combo is UAL 2's regular
## combo, a hit per click, at half the pack's speed; weapons without their own moves keep the old swing.
func test_sword_swings_the_ual_combo_slowly() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	var light: Array = DwarfRig.ATTACKS.sword[0]
	check(light.size() == (Combat.WEAPONS.sword.combo as Array).size(), "one UAL hit for every step of the sword combo")
	for what: String in light + [DwarfRig.ATTACKS.sword[1]]:
		var clip: String = DwarfRig.ANIMS[what]
		check(rig.tree.has_animation(clip) and DwarfOneSwing.has_move(clip.trim_prefix("o/")), "%s is baked and playable" % clip)
	for step in 3:
		var s := DwarfRig.attack_seconds("sword", false, step, 0.55)
		check(is_equal_approx(s, DwarfOneSwing.clip_length(String(DwarfRig.ANIMS[light[step]]).trim_prefix("o/")) * DwarfRig.UAL_SLOW),
			"hit %d plays at half the pack's speed (%.2f s)" % [step + 1, s])
	check(DwarfRig.attack_seconds("axe", false, 0, 0.7) == 0.7, "the axe keeps its own speed")
	check(not DwarfRig.ATTACKS.has("axe") and String(DwarfRig.ATTACKS[""][1]) == "heavy", "the axe keeps the old swing")
	m.queue_free()
	await frames(2)  # (gone before the next test builds its dwarf)


func test_tools_sit_right_in_the_hands() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	for k in ["chop", "smash", "stab", "bash", "shield", "block"]:
		check(rig.tree.has_animation(DwarfRig.ANIMS[k]), "has the %s animation" % k)
	for w in DwarfRig.ATTACKS:
		var moves: Array = DwarfRig.ATTACKS[w]
		check(rig.tree.has_animation(DwarfRig.ANIMS[moves[1]]), "%s has a heavy attack" % w)
	m.set_held("pickaxe_copper")
	check(rig.tool_look == "pickaxe" and m._hand == rig.grip, "the tool sits in the rig's grip")
	var turn := (DwarfRig.grip_transform("pickaxe", "").basis * Vector3.RIGHT).dot(DwarfRig.grip_transform("", "").basis * Vector3.RIGHT)
	check(absf(turn) < 0.2, "the pick head is turned a quarter round from the old grip (into the swing)")
	m.set_held("shield_copper")
	m.set_shield("shield_copper")
	check(m._hand.get_child_count() == 0 or m._hand.get_child(0).is_queued_for_deletion(), "no shield in the right fist")
	check(rig.shield_grip.get_child_count() == 1 and rig.shield_grip.get_parent() == rig.left_hand, "the shield is on the left arm")
	m.set_shield("")
	await frames(1)
	check(rig.shield_grip.get_child_count() == 0, "and comes off again")
	m.set_pose(true, false, true)
	await frames(30)
	var lb := rig.skeleton.find_bone("hand_l")
	var hand := rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(lb).origin
	check(hand.z < -0.1, "the shield block raises the left arm in front (%.2f)" % hand.z)
	m.free()


func test_dwarf_is_short_and_wide() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var sk := m.dwarf_rig.skeleton
	var prop: DwarfProportions = null
	for c in sk.get_children():
		if c is DwarfProportions:
			prop = c
	check(prop != null, "the dwarf-proportions step is on the skeleton")
	# Bones must be read right after the proportions are applied (before that, they're human).
	var got := {}
	var read := func():
		var at := func(b: String) -> Vector3: return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b)).origin
		got.head = at.call("Head").y
		got.hip = (at.call("thigh_l").y + at.call("thigh_r").y) * 0.5
		got.hand = at.call("hand_l").y
		got.toe = minf(at.call("ball_l").y, at.call("ball_r").y)
		got.belly = at.call("spine_01")
	prop.modification_processed.connect(read)
	await frames(20)
	var top: float = got.head + 0.25
	check(got.head > 0.75 and got.head < 1.1, "head at dwarf height (%.2f m)" % got.head)
	check(got.hip / top < 0.4, "stubby legs: hips at %.0f%% of the height (owner F25: about a third)" % (got.hip / top * 100.0))
	check(got.hand > got.hip - 0.05, "short arms: hands hang no lower than the hips (hands %.2f, hips %.2f)" % [got.hand, got.hip])
	check(absf(got.toe) < 0.08, "toes on the floor (%.2f m)" % got.toe)
	m.free()


func test_tool_models_cover_every_tool() -> void:
	for look in ToolModels.TOOLS:
		var t := ToolModels.build(look, Color(0.6, 0.6, 0.6), DwarfModel.VISUAL_LAYER)
		var meshes := t.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() >= 1, "%s has a model" % look)
		for mi: MeshInstance3D in meshes:
			check(mi.layers == DwarfModel.VISUAL_LAYER, "%s sits on the dwarf's layer (no lantern self-shadow)" % look)
		t.free()
	for look in ["fists", "", "food", "material"]:
		var empty := ToolModels.build(look, Color.WHITE, 2)
		check(empty.get_child_count() == 0, "%s: nothing in the hand (F22)" % look)
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


func test_armor_and_wear_show_on_the_dwarf() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var before := m.find_children("*", "MeshInstance3D", true, false).size()
	m.set_wear(["armor_head_copper", "armor_chest_copper", "armor_feet_copper", "spore_mask"])
	var after := m.find_children("*", "MeshInstance3D", true, false)
	check(after.size() > before + 8, "armor pieces and the mask appear (%d -> %d parts)" % [before, after.size()])
	for mi: MeshInstance3D in after:
		check(mi.layers == DwarfModel.VISUAL_LAYER, "every worn part is on the dwarf's layer (no lantern self-shadow)")
	var cap := m.dwarf_rig._cap  # (none on the bareheaded hand-built body)
	check(cap == null or not cap.visible, "an armor helmet replaces the starting iron cap")
	m.set_wear([])
	await frames(2)
	check(cap == null or cap.visible, "taking the helmet off brings the cap back")
	check(m.find_children("*", "MeshInstance3D", true, false).size() == before, "all armor parts are removed again")
	m.free()


func test_monsters_have_moving_parts() -> void:
	var beetle := MonsterModel.build("rock_beetle", Color(0.5, 0.4, 0.3), 1.0, false)
	check((beetle.get_meta("legs") as Array).size() >= 4, "a beetle has legs that walk")
	MonsterModel.animate(beetle, 3.0, 1.0, 0.4)
	check(beetle.rotation.x < 0.0, "it leans into a run")
	beetle.free()
	var bat := MonsterModel.build("cave_bat", Color(0.4, 0.3, 0.5), 1.0, false)
	check((bat.get_meta("wings") as Array).size() == 2, "a bat has two flapping wings")
	bat.free()
	var golem := MonsterModel.build("rock_beetle", Color(0.5, 0.5, 0.5), 1.0, false)
	var chunky := func(mi: MeshInstance3D) -> bool:
		if not mi.mesh is BoxMesh:
			return false
		var b := (mi.mesh as BoxMesh).size
		return minf(b.x, minf(b.y, b.z)) >= 0.09  # thin bars (handles, blades) stay sharp on purpose
	var boxes := golem.find_children("*", "MeshInstance3D", true, false).filter(chunky)
	check(boxes.is_empty(), "no chunky toy-block boxes left on a beetle (%d)" % boxes.size())
	golem.free()


func test_first_three_creatures() -> void:
	for id in ["rock_snail", "cave_bat", "rock_beetle", "great_rock_beetle"]:
		check(Monsters.LIST.has(id), "%s exists" % id)
		for d in Monsters.LIST[id].drops:
			check(Items.exists(d[0]), "%s drops a real item: %s" % [id, d[0]])
	check(Monsters.LIST.rock_snail.shell_hide.at == [0.5, 0.1] and Monsters.LIST.rock_snail.shell_hide.seconds == 10.0, "snail hides at half and at 10% health, 10 s each (owner, Nov 18)")
	check(is_equal_approx(Monsters.LIST.rock_snail.shell_hide.cut, 0.9), "hiding = 90% less damage (owner)")
	check(Monsters.LIST.cave_bat.flies and Monsters.LIST.cave_bat.swoops and Monsters.LIST.cave_bat.roosts, "bats fly, swoop and roost")
	check(Monsters.LIST.rock_beetle.soft_back > 1.0 and Monsters.LIST.rock_beetle.straight_charge, "beetle charges straight, soft back")
	for biome in ["mossy", "fungal"]:
		for kind in Monsters.SPAWNS[biome].big + Monsters.SPAWNS[biome].small:
			check(kind in ["rock_snail", "cave_bat", "rock_beetle", "great_rock_beetle", "cave_spider"], "only the first three (and the Cave Spider, owner Nov 19) spawn for now: %s" % kind)
	for r in ["dish_cooked_snail", "dish_roasted_bug", "dish_snail_stew", "dish_bug_stew", "shield_shell", "bolt_fang", "pickaxe_fang", "glow_lamp", "leather_from_wing"]:
		check(Recipes.LIST.has(r), "recipe %s exists" % r)
	check(Items.info("glow_gland").fuel > Items.info("crystal_blue").fuel, "a glow gland lasts longer than a crystal")
	# The snail's model can pull in and come back out.
	var m := MonsterModel.build("rock_snail", Color(0.5, 0.45, 0.4), 1.0, false)
	check(m.find_children("*", "MeshInstance3D", true, false).any(func(mi): return mi.has_meta("soft")), "snail has a soft body to pull in")
	m.free()


## The creatures made from the owner's approved pictures (tools/asset_forge/forge_creatures.py):
## all 12 looks exist, each has its moving parts, the eyes can flash, a charging beetle's glow blazes,
## the snail hides with only its eyes peeking out, and a sleeping bat hangs head-down.
func test_forged_creatures() -> void:
	for art in ["rock_snail", "cave_bat", "rock_beetle"]:
		for look in ["mossy", "frost", "ember", "spore"]:
			check(ResourceLoader.exists("res://assets/models/creatures/%s_%s.glb" % [art, look]), "%s %s model exists" % [art, look])
	var beetle := MonsterModel.build("rock_beetle", Color.WHITE, 0.9, false, "rock_beetle", 0, "red")
	check(beetle.has_meta("forged_root") and beetle.get_meta("look", "") == "ember", "an Ember-crested beetle wears the ember look")
	# Normal creatures wear all 4 looks (owner, Nov 19): two in a row never look the same
	var seen := {}
	for sd in 8:
		seen[MonsterModel.look_of("", sd)] = true
		check(MonsterModel.look_of("", sd) != MonsterModel.look_of("", sd + 1), "the next creature is a different look")
	check_eq(seen.size(), 4, "all 4 looks show up")
	check((beetle.get_meta("legs") as Array).size() >= 4, "beetle has walking legs (%d)" % (beetle.get_meta("legs") as Array).size())
	var eye: StandardMaterial3D = beetle.get_meta("eye_mat")
	check(eye != null and eye.emission_enabled, "beetle eyes can flash before an attack")
	if beetle.has_meta("glow_mat"):
		var g := beetle.get_meta("glow_mat") as StandardMaterial3D
		var before := g.emission_energy_multiplier
		MonsterModel.set_angry(beetle, true)
		check(g.emission_energy_multiplier > before * 1.5, "charging: its glowing back blazes")
	var great := MonsterModel.build("rock_beetle", Color.WHITE, 1.5, false, "great_rock_beetle", 0, "")
	check(great.has_meta("forged_root"), "the Great Rock Beetle is a bigger Rock Beetle")
	var snail := MonsterModel.build("rock_snail", Color.WHITE, 1.0, false, "rock_snail", 0, "")
	tree.root.add_child(snail)
	var peek: Array = snail.get_meta("peek")
	check(not peek.is_empty() and not (peek[0] as Node3D).visible, "snail: peeking eyes hidden while it's out")
	MonsterModel.set_shell(snail, true)
	await tree.create_timer(0.45).timeout
	var soft_small := true
	for mi: MeshInstance3D in (snail.get_meta("forged_root") as Node3D).find_children("*", "MeshInstance3D", true, false):
		if mi.has_meta("soft"):
			soft_small = soft_small and mi.scale.x < 0.1
	check(soft_small, "snail hiding: its whole soft body is inside the shell")
	check((peek[0] as Node3D).visible, "snail hiding: two eyes peek out")
	snail.queue_free()
	var bat := MonsterModel.build("cave_bat", Color.WHITE, 1.0, false, "cave_bat", 0, "blue")
	check((bat.get_meta("wings") as Array).size() == 2, "bat has two flapping wings")
	bat.set_meta("roosting", true)
	MonsterModel.animate(bat, 0.0, 1.0, 0.3)
	# (the Nov 18 bats are built upright and flip head-down; older forged bats tip forward)
	check(absf(absf(bat.rotation.z) - PI) < 0.01 or absf(bat.rotation.x + PI / 2.0) < 0.01, "asleep: hanging head-down")
	for n in [beetle, great, bat]:
		n.free()
