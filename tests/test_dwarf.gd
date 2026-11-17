extends TestCase
## The dwarf standing in the real cave, with real physics.


func test_dwarf_does_not_fall_through_floor() -> void:
	Controls.setup()
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	var spawn := world.maker.cavern_spawn
	dwarf.global_position = spawn
	dwarf.set_physics_process(false)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	dwarf.add_child(viewer)
	auth.add_player(1, dwarf)
	var meshed := false
	for i in 900:
		if world.terrain.is_area_meshed(AABB(spawn - Vector3.ONE * 6, Vector3.ONE * 12)):
			meshed = true
			break
		await tree.physics_frame
	check(meshed, "floor got built around spawn")
	dwarf.set_physics_process(true)
	for i in 180:  # 3 seconds of falling and standing
		await tree.physics_frame
	check(dwarf.is_on_floor(), "dwarf is standing on the floor")
	check(dwarf.global_position.y > spawn.y - 3.0, "dwarf didn't sink (y %.2f, spawn %.2f)" % [dwarf.global_position.y, spawn.y])
	root.queue_free()


# ---------------------------------------------------------------- jump, step up, lantern
# These use a simple test room (flat floor + blocks), not the cave, so the shape is exact.

func _room(blocks: Array) -> Node3D:
	var root := Node3D.new()
	tree.root.add_child(root)
	_block(root, Vector3(0, -0.5, 0), Vector3(30, 1, 30))  # floor, top at y = 0
	for b in blocks:
		_block(root, b[0], b[1])
	return root


func _block(root: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	root.add_child(body)


func _dwarf_in(root: Node3D) -> Dwarf:
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	return dwarf


func _walk_forward(dwarf: Dwarf, seconds: float) -> float:
	var highest := dwarf.global_position.y
	dwarf.bot_move = Vector2(0, -1)  # forward = -z
	for i in int(seconds * 60):
		await tree.physics_frame
		highest = maxf(highest, dwarf.global_position.y)
	dwarf.bot_move = Vector2.ZERO
	return highest


func test_jump_goes_up_and_lands() -> void:
	Controls.setup()
	var root := _room([])
	var dwarf := _dwarf_in(root)
	for i in 30:
		await tree.physics_frame
	check(dwarf.is_on_floor(), "dwarf stands before jumping")
	dwarf.bot_jump = true
	var highest := 0.0
	for i in 90:
		await tree.physics_frame
		highest = maxf(highest, dwarf.global_position.y)
	check(highest > 1.2, "jump is at least 1.2 m high (got %.2f)" % highest)
	check(dwarf.is_on_floor(), "dwarf landed again")
	root.queue_free()


func test_jump_pressed_just_before_landing_still_counts() -> void:
	Controls.setup()
	var root := _room([])
	var dwarf := _dwarf_in(root)
	dwarf.global_position = Vector3(0, 0.6, 0)  # falling
	var pressed := false
	var highest_after := 0.0
	for i in 90:
		await tree.physics_frame
		if not pressed and dwarf.global_position.y < 0.25 and not dwarf.is_on_floor():
			dwarf.bot_jump = true  # a little too early
			pressed = true
		if pressed:
			highest_after = maxf(highest_after, dwarf.global_position.y)
	check(pressed, "test pressed jump while falling")
	check(highest_after > 1.0, "early jump press still jumped (got %.2f)" % highest_after)
	root.queue_free()


func test_steps_up_small_ledge() -> void:
	Controls.setup()
	# A 35 cm ledge starting 2 m ahead.
	var root := _room([[Vector3(0, 0.175, -6), Vector3(4, 0.35, 8)]])
	var dwarf := _dwarf_in(root)
	for i in 20:
		await tree.physics_frame
	await _walk_forward(dwarf, 2.0)
	check(dwarf.global_position.z < -3.0, "dwarf got past the ledge edge (z %.2f)" % dwarf.global_position.z)
	check(dwarf.global_position.y > 0.3, "dwarf is standing on top of the ledge (y %.2f)" % dwarf.global_position.y)
	root.queue_free()


func test_does_not_step_up_tall_wall() -> void:
	Controls.setup()
	# A 1.2 m wall 2 m ahead: needs a jump (or digging), not a step.
	var root := _room([[Vector3(0, 0.6, -4), Vector3(4, 1.2, 4)]])
	var dwarf := _dwarf_in(root)
	for i in 20:
		await tree.physics_frame
	var highest := await _walk_forward(dwarf, 2.0)
	check(highest < 0.3, "dwarf did not climb a 1.2 m wall by walking (highest %.2f)" % highest)
	root.queue_free()


func test_lantern_ignores_dwarf_body_for_shadows() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	await tree.process_frame
	var light := dwarf.lantern.light
	check(light.shadow_enabled, "lantern still makes shadows on the cave")
	check((light.shadow_caster_mask & DwarfModel.VISUAL_LAYER) == 0, "dwarf's body can't block own lantern")
	var meshes := dwarf.model.find_children("*", "MeshInstance3D", true, false)
	var bad := 0
	for m in meshes:
		var mi := m as MeshInstance3D
		var in_lantern := dwarf.lantern.is_ancestor_of(mi)
		if in_lantern and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			bad += 1
		if not in_lantern and mi.layers != DwarfModel.VISUAL_LAYER:
			bad += 1
	check(meshes.size() > 10, "found the dwarf's parts")
	check(bad == 0, "every body part is on the dwarf layer and the lantern casts no shadow (%d wrong)" % bad)
	root.queue_free()


## The hand-built body (Nov 16): every part is bound to bones the game skeleton really has, at the shaped rest pose.
func test_hand_built_body_fits_the_skeleton() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY):
		return
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	var parts := 0
	var bad := []
	for mi: MeshInstance3D in rig.skeleton.find_children("body_*", "MeshInstance3D", true, false):
		parts += 1
		check(mi.visible and mi.skin != null, "%s is shown and has its bones" % mi.name)
		for b in mi.skin.get_bind_count():
			if rig.skeleton.find_bone(String(mi.skin.get_bind_name(b))) < 0:
				bad.append(String(mi.skin.get_bind_name(b)))
	check(parts >= 8, "the hand-built body has its parts (%d)" % parts)  # (Nov 18: the bare body is 9 clay parts)
	check(bad.is_empty(), "every bone it uses exists in the game skeleton (missing: %s)" % [bad])
	await frames(1)  # (let the earlier tests' players finish freeing first)
	holder.free()


## The braid tufts swing when the dwarf moves (F192): the swing bones arrive with the body and the spring moves them.
func test_braid_tufts_swing_when_moving() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY):
		return
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	var swing := rig.skeleton.get_node_or_null("HairSwing") as HairSwing
	check(swing != null, "the hair swing is on the skeleton")
	if swing == null:
		holder.free()
		return
	check(rig.skeleton.find_bone("hair_braid_m_7") >= 0, "the middle braid's 7 swing bones were added to the skeleton")
	check(rig.skeleton.find_bone("hair_back_m_4") >= 0, "the back hair's swing bones were added too")
	check(rig.skeleton.find_bone("cloth_hem_0_2") >= 0, "the shirt hem's springy bones were added (owner, Nov 18: clothes that bounce)")
	var back: Dictionary = {}
	for ch: Dictionary in swing._chains:
		if not (ch.under as Array).is_empty() and String(ch.get("name", "")).begins_with("hair_back"):
			back = ch
	check(not back.is_empty(), "the back hair lies on the shirt below the head (owner, Nov 17: 'a stiff visor')")
	var lifted := 0.0
	for i in 30:  # dash forward, then stop
		holder.position.z -= 0.12 if i < 15 else 0.0
		await tree.process_frame
		if not back.is_empty() and not (back.was as Array).is_empty():
			lifted = maxf(lifted, ((back.p as Array)[-1] as Vector3).distance_to((back.was as Array)[-1]))
	check(swing.biggest_swing > 3.0, "the hair swings when he moves (%.1f degrees)" % swing.biggest_swing)
	# (its drag used to work against the world: running blew the ponytail out flat behind him like a headwind; it may
	# sway several cm when he starts and stops: owner, Nov 17 evening, "it barely moves")
	check(lifted < 0.1, "the back hair's tip stays near its place on his back in a dash (%.1f cm away at most)" % (lifted * 100.0))
	# (on its own a link bends at most MAX_BEND; the body pushing the hair aside may bend it more, never back on itself)
	check(swing.biggest_fold < 90.0, "no link folds back on itself (sharpest bend %.1f degrees)" % swing.biggest_fold)
	holder.free()


# ---------------------------------------------------------------- dev fly (F6)
func test_dev_fly_floats_and_lands_again() -> void:
	Controls.setup()
	var root := _room([])
	var dwarf := _dwarf_in(root)
	for i in 30:
		await tree.physics_frame
	dwarf.set_dev_fly(true)
	dwarf.global_position.y += 3.0
	var y := dwarf.global_position.y
	for i in 60:
		await tree.physics_frame
	check(absf(dwarf.global_position.y - y) < 0.05, "flying dwarf doesn't fall (moved %.2f)" % (dwarf.global_position.y - y))
	check(dwarf.collision_mask == 0, "flying goes through rock")
	dwarf.set_dev_fly(false)
	for i in 90:
		await tree.physics_frame
	check(dwarf.is_on_floor(), "back on the floor after F6 again")
	root.queue_free()
