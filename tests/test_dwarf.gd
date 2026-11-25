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


## Owner (Nov 22 notes): walking speeds up into running smoothly, not a sudden jump from walk speed to run speed.
func test_walk_eases_into_run_not_a_snap() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var dwarf := _dwarf_in(root)
	Input.action_press("move_forward")
	for i in 60:  # walk a full second first, let the speed settle
		await tree.physics_frame
	var walk_speed := Vector2(dwarf.velocity.x, dwarf.velocity.z).length()
	check(absf(walk_speed - Dwarf.WALK_SPEED) < 0.1, "settled at walk speed first (%.2f)" % walk_speed)
	Input.action_press("run")
	var biggest_step := 0.0
	var prev := walk_speed
	for i in 60:  # watch the first second of switching to running
		await tree.physics_frame
		var now := Vector2(dwarf.velocity.x, dwarf.velocity.z).length()
		biggest_step = maxf(biggest_step, now - prev)
		prev = now
	check(biggest_step < 0.5, "no single-frame jump from walk to run speed (biggest step %.2f m/s, F701)" % biggest_step)
	check(prev > Dwarf.WALK_SPEED + 1.0, "eventually reaches run speed (%.2f)" % prev)
	Input.action_release("move_forward")
	Input.action_release("run")
	Controls.robot = false
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


## The hand-built Hide armor (F55) goes on the body's skeleton: every bone it uses exists, all three pieces show, and
## the helmet swaps in the hat-hair head (and gives the normal one back when taken off).
func test_hand_built_armor_fits_the_body() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY) or not ResourceLoader.exists(DwarfRig.ARMOR_FILES["hide"]):
		return
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	rig.set_wear(["armor_head_leather", "armor_chest_leather", "armor_feet_leather"])
	var pieces := {}
	var bad := []
	for mi: MeshInstance3D in rig.skeleton.find_children("armor_*", "MeshInstance3D", true, false):
		pieces[String(mi.name).split("_")[1]] = true
		check(mi.skin != null, "%s has its bones" % mi.name)
		for b in mi.skin.get_bind_count():
			if rig.skeleton.find_bone(String(mi.skin.get_bind_name(b))) < 0:
				bad.append(String(mi.skin.get_bind_name(b)))
	check(pieces.has("head") and pieces.has("chest") and pieces.has("feet"), "helmet, jerkin and boots are worn (%s)" % [pieces.keys()])
	check(bad.is_empty(), "every bone the armor uses exists in the game skeleton (missing: %s)" % [bad])
	var head := rig._body_head
	check(head != null and not head.visible, "with the helmet on, the normal head is swapped for the hat-hair one")
	check(rig._body_root.position.y * rig.scale.y > 0.01, "with boots on he stands on their soles (owner, Nov 18: feet sank into the ground)")
	rig.set_wear(["armor_chest_leather"])
	check(head != null and head.visible, "helmet off: the normal head (and his wild hair) is back")
	check(is_zero_approx(rig._body_root.position.y), "boots off: his bare feet are back on the floor")
	await frames(1)
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


## Owner, Nov 17: "the axe isn't axing the right stuff". Something between the camera and the dwarf (a root behind
## you) must not be hit: the swing lands on what's in front of the dwarf.
func test_aim_skips_things_behind_the_dwarf() -> void:
	Controls.setup()
	var root := _room([[Vector3(0, 1.0, -2.0), Vector3(4, 2.0, 0.4)]])  # a wall 1.8 m ahead
	var dwarf := _dwarf_in(root)
	for i in 20:
		await tree.physics_frame
	var cam := dwarf.camera.global_position
	var behind := StaticBody3D.new()  # a fat root aim shape right behind the dwarf, in the camera's view
	behind.collision_layer = GlowField.GLOW_LAYER
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.3
	shape.shape = ball
	behind.add_child(shape)
	root.add_child(behind)
	var chest := dwarf.global_position + Vector3.UP
	behind.global_position = chest.lerp(cam, 0.45)  # on the line from the camera through the dwarf's chest
	dwarf.camera.look_at(chest + (chest - cam).normalized() * 3.0)
	await tree.physics_frame
	await tree.physics_frame
	var hit := dwarf.aim()
	check(not hit.is_empty() and hit.collider != behind, "aim skips the root behind the dwarf (cam %s)" % cam)
	check(not hit.is_empty() and hit.position.z < -1.5, "aim lands on the wall in front (%s)" % hit.get("position", "-"))
	root.queue_free()


## Owner, Nov 19: "with the crossbow my dwarf stops or only moves one way; and there's no reloading" (the walking
## code broke every frame and the reload never finished). Owner, Nov 20: reloading needs you to stand still; walking
## away stops it and it starts over; it takes twice as long as before.
func test_crossbow_reload_needs_standing_still() -> void:
	Controls.setup()
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	var ps := auth.add_player(1, dwarf)
	ps.inventory.add_worn("crossbow_copper")
	ps.inventory.add("bolt_stone", 5)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_copper":
			auth.request_select_slot(1, i)
	for i in 20:
		await tree.physics_frame
	check(dwarf.fight.is_crossbow(), "the crossbow is in hand")
	var was_robot := Controls.robot
	Controls.robot = true
	Controls.set_captured(true)  # playing (the reload only runs while you play, not in a menu)
	check_eq(Combat.RELOAD[1], 3.0, "a copper crossbow takes 3 s to reload (owner, Nov 20)")
	dwarf.fight.loaded = false
	dwarf.fight.start_reload()
	check(dwarf.fight.reload_left > 0.0, "reloading started")
	for i in 60:
		await tree.physics_frame
	check(dwarf.fight.reload_left > 0.0, "still reloading after 1 s")
	var z0 := dwarf.global_position.z
	dwarf.bot_move = Vector2(0, -1)  # walk away
	for i in 30:
		await tree.physics_frame
	check(dwarf.fight.reload_left < 0.0 and not dwarf.fight.loaded, "walking stops the reload, no bolt goes in")
	check(z0 - dwarf.global_position.z > 0.3, "and he really walks away (not stuck)")
	dwarf.bot_move = Vector2.ZERO
	for i in 20:
		await tree.physics_frame
	dwarf.fight.start_reload()
	check(absf(dwarf.fight.reload_left - dwarf.fight.reload_total) < 0.05, "the next reload starts from the beginning")
	var rig: DwarfRig = dwarf.model.dwarf_rig
	if rig:  # the reload move is stretched to last the whole reload (owner, Nov 20: no standing still after it)
		var clip_len := rig.tree.get_animation(rig._upper_clip).length if rig._upper_clip != "" else 0.0
		var plays_for := clip_len / maxf(float(rig.tree.get("parameters/upper_speed/scale")), 0.001)
		check(absf(plays_for - dwarf.fight.reload_total) < 0.1, "the reload move lasts as long as the reload (%.2f s vs %.2f s)" % [plays_for, dwarf.fight.reload_total])
	var x0 := dwarf.global_position.x
	for i in int(dwarf.fight.reload_total * 60) + 30:
		await tree.physics_frame
	check(dwarf.fight.loaded, "standing still, the reload finishes: a bolt is in")
	check(absf(dwarf.global_position.x - x0) < 0.05, "he stood still while reloading")
	Controls.set_captured(false)
	Controls.robot = was_robot
	root.queue_free()


## Owner (Mac, Nov 22 phone notes): dash — a short tap of dodge still gives the usual short roll; holding the
## button down dashes farther, building on the dodge we already have (F702).
func test_holding_dodge_dashes_farther_than_a_tap() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.bot_dodge = true  # a tap: trigger it once, nothing held down after
	await tree.physics_frame
	while dwarf.fight.dodging():
		await tree.physics_frame
	var tap_dist := (dwarf.global_position - p0).length()
	check(tap_dist > 1.0 and tap_dist < 4.0, "a tap gives the usual short dash (%.2f m)" % tap_dist)
	for i in 15:  # let the short recovery after a roll clear
		await tree.physics_frame
	var p1 := dwarf.global_position
	dwarf.bot_dodge = true
	Input.action_press("dodge")  # hold it down the whole time
	await tree.physics_frame
	while dwarf.fight.dodging():
		await tree.physics_frame
	Input.action_release("dodge")
	var hold_dist := (dwarf.global_position - p1).length()
	check(hold_dist > tap_dist + 0.5, "holding it dashes farther than a tap (%.2f m vs %.2f m, F702)" % [hold_dist, tap_dist])
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 23, F702): "the entire speed at the beginning of the dodge and the end of the dodge should be
## exactly the same... he's traveling too fast at the end of the long dodge" — an earlier version sped up toward
## DASH_HOLD_MAX; holding should only make the dash last longer, never faster.
func test_held_dash_moves_at_the_same_speed_start_to_finish() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	dwarf.bot_dodge = true
	Input.action_press("dodge")  # hold it down the whole time
	await tree.physics_frame
	var early_speed := dwarf.fight.dodge_velocity().length()
	var late_speed := early_speed
	while dwarf.fight.dodging():
		late_speed = dwarf.fight.dodge_velocity().length()
		await tree.physics_frame
	Input.action_release("dodge")
	check(absf(late_speed - early_speed) < 0.01,
			"dash speed stays the same start to finish (%.2f m/s vs %.2f m/s, F702)" % [early_speed, late_speed])
	Controls.robot = false
	root.queue_free()


## Owner (Mac, Nov 22 phone notes, F702): "the dwarf should always roll where you're pointing, or where you are looking" —
## not backward while you're plainly walking forward.
func test_dodge_while_walking_forward_rolls_forward_not_back() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	dwarf.bot_move = Vector2(0, -1)  # walking forward (-z), not holding run
	for i in 10:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.bot_dodge = true  # tap dodge while still walking forward
	await tree.physics_frame
	while dwarf.fight.dodging():
		await tree.physics_frame
	dwarf.bot_move = Vector2.ZERO
	var moved := dwarf.global_position - p0
	check(moved.z < -0.5, "rolling while walking forward moves forward (-z), not backward (moved.z=%.2f)" % moved.z)
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 22 night, F702 real-world repro): the bot test above walks straight ahead with a never-turned
## camera, so the body is always already facing forward before the roll. In real play the body's facing is a slow
## turn (12/s lerp in dwarf.gd) that can still be lagging behind a recent camera turn when the roll starts; the
## roll's actual travel direction was always right (previous test proves it), but the body kept turning to face it
## only gradually, so the tumble itself could visibly start facing the wrong way. The roll must snap the body to
## face its real direction instantly instead of easing into it.
func test_roll_snaps_to_face_its_real_direction_even_if_the_body_was_facing_elsewhere() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	dwarf.bot_move = Vector2(0, -1)  # walking forward (-z)
	for i in 10:
		await tree.physics_frame
	dwarf.model.rotation.y = PI  # body still facing backward, as if from a turn just before this
	dwarf.bot_dodge = true  # tap dodge while walking forward
	await tree.physics_frame
	check(dwarf.fight.dodging(), "the dodge triggered")
	check(absf(dwarf.model.rotation.y) < 0.1, "the body snaps to face the roll's real direction on the very first frame (got %.2f rad)" % dwarf.model.rotation.y)
	while dwarf.fight.dodging():
		await tree.physics_frame
		check(absf(wrapf(dwarf.model.rotation.y, -PI, PI)) < 0.1, "the body keeps facing the roll's direction for the whole roll (got %.2f rad)" % dwarf.model.rotation.y)
	dwarf.bot_move = Vector2.ZERO
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 22 night, F732): "need invulnerability window during roll pls." The safe window was 0.05-0.30 s,
## too short to feel. Now nearly the whole tapped roll is safe: from the very first frame, only getting up isn't.
func test_the_roll_cant_be_hurt_for_almost_all_of_it() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	check(not dwarf.is_invulnerable(), "standing still: you can be hurt")
	dwarf.bot_dodge = true  # a tap
	await tree.physics_frame
	check(dwarf.fight.dodging() and dwarf.is_invulnerable(), "safe from the very first frame of the roll")
	var frames := 0
	var safe := 0
	while dwarf.fight.dodging():
		frames += 1
		if dwarf.is_invulnerable():
			safe += 1
		await tree.physics_frame
	check(frames > 0 and float(safe) / frames >= 0.8, "safe for most of the roll (%d of %d frames)" % [safe, frames])
	check(not dwarf.is_invulnerable(), "the roll is over: you can be hurt again")
	Controls.robot = false
	root.queue_free()


## Owner (Mac, Nov 22 phone notes, F702): "the longer roll needs a longer animation... right now he does the same
## thing" — a tapped dodge should play the usual short roll clip, a held dash a longer one, instead of always the
## same fixed length.
func test_roll_animation_matches_how_long_the_dash_lasts() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	var rig: DwarfRig = dwarf.model.dwarf_rig
	if rig == null:  # the rig-less fallback has its own fixed-length path, not this fix's target
		Controls.robot = false
		root.queue_free()
		return
	for i in 10:
		await tree.physics_frame
	dwarf.bot_dodge = true  # a tap: trigger it once, nothing held down after
	await tree.physics_frame
	var tap_plays_for := rig.tree.get_animation(rig._full_clip).length / float(rig.tree.get("parameters/full_speed/scale"))
	check(absf(tap_plays_for - Combat.DODGE_TIME) < 0.05, "a tapped roll plays for the usual dash time (%.2f s vs %.2f s)" % [tap_plays_for, Combat.DODGE_TIME])
	while dwarf.fight.dodging():
		await tree.physics_frame
	for i in 15:  # let the short recovery after a roll clear
		await tree.physics_frame
	dwarf.bot_dodge = true
	Input.action_press("dodge")  # hold it down the whole time: a longer dash should get a longer roll clip
	await tree.physics_frame
	while dwarf.fight.dodging():
		await tree.physics_frame
	var held_plays_for := rig.tree.get_animation(rig._full_clip).length / float(rig.tree.get("parameters/full_speed/scale"))
	Input.action_release("dodge")
	# Stretched past DASH_HOLD_MAX itself, not to it (F798): a held dash keeps moving right up to
	# DASH_HOLD_MAX, so the clip's stand-up finish needs its recovery tail after that, not landing exactly on it.
	var want := Combat.DASH_HOLD_MAX + Combat.DASH_RECOVERY_TAIL
	check(absf(held_plays_for - want) < 0.05, "holding the dash stretches the roll clip to match (%.2f s vs %.2f s)" % [held_plays_for, want])
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 23, F798): "I am holding the control key all the way until the dwarf stops rolling... after my
## animation of the dodge is done, he propels me forward" — a held dash keeps moving right up to DASH_HOLD_MAX,
## and the roll clip used to be stretched to finish exactly there too, so the stand-up pose landed right in the
## middle of the dash instead of after it. Checked with a robot + screenshots in journal-inbox before this was
## written; this locks the fix in.
func test_held_dash_roll_still_has_recovery_left_when_the_dash_ends() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	var rig: DwarfRig = dwarf.model.dwarf_rig
	if rig == null:
		Controls.robot = false
		root.queue_free()
		return
	for i in 10:
		await tree.physics_frame
	dwarf.bot_dodge = true
	Input.action_press("dodge")  # hold it all the way to the cap, like the owner's repro
	await tree.physics_frame
	while dwarf.fight.dodging():
		await tree.physics_frame
	Input.action_release("dodge")
	# Right as the dash ends (still at its fastest), the clip must still have unplayed content left — the
	# stand-up — not have already finished and looked done mid-burst.
	var elapsed := Time.get_ticks_msec() / 1000.0 - rig._full_start
	check(elapsed < rig._full_length - 0.05, "the roll clip still has a recovery tail left when the dash ends (%.2f s played of %.2f s)" % [elapsed, rig._full_length])
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 22 night, F702 real-world repro): "when I'm doing big dodge... he dodges, rolls and then just
## sprints a little bit" — a real keyboard can drop a single frame of a held key (the same quirk as F494), which
## used to end a held dash the instant it crossed DODGE_TIME even though the button was still actually down.
func test_one_dropped_frame_doesnt_end_a_held_dash_early() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.bot_dodge = true
	Input.action_press("dodge")  # hold it down, as if dashing
	await tree.physics_frame
	var dropped := false
	while dwarf.fight.dodging():
		if not dropped and dwarf.fight._dodge_t >= Combat.DODGE_TIME:
			Input.action_release("dodge")  # one real dropped frame, right as a tap roll would normally end
			await tree.physics_frame
			Input.action_press("dodge")
			dropped = true
		else:
			await tree.physics_frame
	Input.action_release("dodge")
	check(dropped, "the drop actually landed mid-dash (test didn't run long enough otherwise)")
	var dist := (dwarf.global_position - p0).length()
	check(dist > Combat.DODGE_DISTANCE + 0.5, "one dropped frame doesn't cut the held dash short (%.2f m, wanted well past a tap's %.2f m)" % [dist, Combat.DODGE_DISTANCE])
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 22 night, F702 real-world repro): "I dodge backwards, and then it dodges forward, so I can go back
## in place" — the move-direction buffer above only catches a dropped/zero input frame, not one that reads a real,
## fully-reversed direction (a rarer glitch, but the camera yaw or a key can still misread for exactly one frame).
## While you're already moving at real speed, that one bad frame should lose to your actual momentum.
func test_dodge_ignores_one_flipped_frame_and_rolls_with_your_real_momentum() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	dwarf.bot_move = Vector2(0, -1)  # walking forward (-z) long enough to build up real speed
	for i in 30:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.bot_move = Vector2(0, 1)  # one single glitched frame: the input reads the dead opposite direction
	dwarf.bot_dodge = true  # ...and the dodge triggers on that exact bad frame
	await tree.physics_frame
	dwarf.bot_move = Vector2(0, -1)  # the glitch is gone next frame, back to the real held direction
	check(dwarf.fight.dodging(), "the dodge triggered")
	while dwarf.fight.dodging():
		await tree.physics_frame
	dwarf.bot_move = Vector2.ZERO
	var moved := dwarf.global_position - p0
	check(moved.z < -0.5, "one flipped input frame doesn't roll backward when you were really moving forward (moved.z=%.2f)" % moved.z)
	Controls.robot = false
	root.queue_free()


## Owner (PC, Nov 22 night, F702 real-world repro): "I'm looking forward, I press Ctrl, I dash backwards. And
## then it dodges forward" - standing still (no movement key held) and dodging used to default to a backstep,
## which then flips which way is "backward" next time (the roll ends by facing the way it just went).
func test_dodging_with_no_movement_key_rolls_forward_not_backstep() -> void:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.bot_dodge = true  # no bot_move at all: standing still, looking forward
	await tree.physics_frame
	check(dwarf.fight.dodging(), "the dodge triggered")
	while dwarf.fight.dodging():
		await tree.physics_frame
	var moved := dwarf.global_position - p0
	check(moved.z < -0.5, "standing still and dodging rolls the way you're facing, not backward (moved.z=%.2f)" % moved.z)
	Controls.robot = false
	root.queue_free()


## Owner (F234, said again from F111): "a beetle hit sends you flying much too far; a couple of metres at most, then the
## dwarf gets back up". The push was added to his speed every frame and kept (103 m on a flat floor, 177 m knocked down).
func test_beetle_charge_throws_a_couple_of_metres() -> void:
	Controls.setup()
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 30:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.knock_down()
	dwarf.shove(Vector3(7.0, 0, 3.0))  # (MonsterManager.charge_shove's size)
	check(dwarf.fight.stagger > 1.0, "knocked down")
	for i in 150:
		await tree.physics_frame
	var d := dwarf.global_position - p0
	var far := Vector2(d.x, d.z).length()
	check(far > 0.8 and far < 2.5, "thrown a couple of metres (%.2f m)" % far)
	check(dwarf.fight.stagger <= 0.0, "back up after %.1f s" % DwarfFight.KNOCK_DOWN_TIME)
	root.queue_free()


## Owner, chat 15: "you should have your own stun meter as well", and the pack's Shield broken when you're stunned.
func test_your_own_stun_meter() -> void:
	Controls.setup()
	var root := _room([])
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	var said := []
	dwarf.model.reacted.connect(func(what: String, _d: float) -> void: said.append(what))
	dwarf.fight.take_stun(20.0 * DwarfFight.STUN_PER_HIT)
	check(dwarf.fight.stagger <= 0.0 and dwarf.fight.stun_meter.fraction() > 0.0, "a 20-damage hit fills it, no stun yet")
	dwarf.fight.take_stun(25.0 * DwarfFight.STUN_PER_HIT)
	check(is_equal_approx(dwarf.fight.stagger, DwarfFight.STUN_TIME), "the next big hit stuns you (%.1f s)" % dwarf.fight.stagger)
	check("stunned" in said and dwarf.model.dwarf_rig.tree.has_animation(DwarfRig.ANIMS.stunned), "with the Shield broken move")
	var t := DwarfFight.STUN_TIME + 0.3
	while t > 0.0:
		await tree.physics_frame
		t -= 1.0 / 60.0
	check(dwarf.fight.stagger <= 0.0, "and you can fight again")
	dwarf.fight.take_stun(DwarfFight.STUN_MAX)
	check(dwarf.fight.stagger <= 0.0, "not stunned again straight away (2 s rest)")
	dwarf.fight.guard_break()
	check(said.count("stunned") == 2, "a guard break plays the Shield broken move too")
	root.queue_free()

# ---------------------------------------------------------------- camera (F469, F766) and sprint feel (F775)
func _robot_room(blocks: Array = []) -> Array:
	Controls.setup()
	Controls.robot = true
	Controls.set_captured(true)
	var root := _room(blocks)
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := _dwarf_in(root)
	auth.add_player(1, dwarf)
	for i in 10:
		await tree.physics_frame
	return [root, dwarf]


func _flat_speed(dwarf: Dwarf) -> float:
	return Vector2(dwarf.velocity.x, dwarf.velocity.z).length()


func test_sprint_ramps_up_instead_of_snapping_to_full_speed() -> void:
	var r: Array = await _robot_room()
	var dwarf: Dwarf = r[1]
	dwarf.bot_move = Vector2(0, -1)
	for i in 30:
		await tree.physics_frame
	dwarf.bot_run = true
	for i in 6:  # 0.1 s into the sprint
		await tree.physics_frame
	var early := _flat_speed(dwarf)
	for i in 60:
		await tree.physics_frame
	var full := _flat_speed(dwarf)
	check(early < Dwarf.RUN_SPEED - 1.0, "0.1 s in, still building speed (%.2f m/s)" % early)
	check(full > Dwarf.RUN_SPEED - 0.3, "after 1 s, full sprint (%.2f m/s)" % full)
	Controls.robot = false
	r[0].queue_free()


func test_sprint_turns_slower_than_walking() -> void:
	var r: Array = await _robot_room()
	var dwarf: Dwarf = r[1]
	dwarf.bot_move = Vector2(0, -1)
	for i in 30:
		await tree.physics_frame
	dwarf.bot_move = Vector2(1, 0)  # walking: turn right
	for i in 6:
		await tree.physics_frame
	var walk_side := dwarf.velocity.x
	dwarf.bot_move = Vector2(0, -1)
	dwarf.bot_run = true
	for i in 60:
		await tree.physics_frame
	dwarf.bot_move = Vector2(1, 0)  # sprinting: same turn
	for i in 6:
		await tree.physics_frame
	check(walk_side > 2.0, "walking turns at once (sideways %.2f m/s)" % walk_side)
	check(dwarf.velocity.z < -2.5, "sprinting still mostly going forward 0.1 s after turning (forward %.2f m/s)" % -dwarf.velocity.z)
	Controls.robot = false
	r[0].queue_free()


func test_letting_go_mid_sprint_skids_a_little() -> void:
	var r: Array = await _robot_room()
	var dwarf: Dwarf = r[1]
	dwarf.bot_move = Vector2(0, -1)
	dwarf.bot_run = true
	for i in 60:
		await tree.physics_frame
	var p0 := dwarf.global_position
	dwarf.bot_move = Vector2.ZERO
	dwarf.bot_run = false
	for i in 90:
		await tree.physics_frame
	var skid := (dwarf.global_position - p0).length()
	check(skid > 0.5 and skid < 2.0, "a short skid, not a dead stop (%.2f m)" % skid)
	check(_flat_speed(dwarf) < 0.1, "and then he stands still")
	Controls.robot = false
	r[0].queue_free()


func test_sprinting_never_spends_the_last_dodge() -> void:
	var r: Array = await _robot_room()
	var dwarf: Dwarf = r[1]
	var body := dwarf._vitals()
	body.stamina = 40.0
	dwarf.bot_move = Vector2(0, -1)
	dwarf.bot_run = true
	for i in 300:  # 5 s of holding Shift
		await tree.physics_frame
	var dodge_cost := Combat.DODGE_STAMINA * dwarf._progress().dodge_stamina_mult()
	check(body.stamina >= dodge_cost - 0.5, "sprint stopped with a dodge's worth left (%.1f, dodge costs %.1f)" % [body.stamina, dodge_cost])
	dwarf.bot_dodge = true
	await tree.physics_frame
	check(dwarf.fight.dodging(), "and the dodge still works")
	Controls.robot = false
	r[0].queue_free()


func test_camera_comes_in_looking_up_and_out_looking_down() -> void:
	var r: Array = await _robot_room()
	var dwarf: Dwarf = r[1]
	dwarf._pitch = -1.0
	for i in 90:
		await tree.process_frame
	var down := dwarf.camera.position.z
	dwarf._pitch = 0.8
	for i in 90:
		await tree.process_frame
	var up := dwarf.camera.position.z
	check(down > Dwarf.CAMERA_DISTANCE and up < Dwarf.CAMERA_DISTANCE - 0.3, "looking down %.2f m out, up %.2f m (normal %.2f)" % [down, up, Dwarf.CAMERA_DISTANCE])
	Controls.robot = false
	r[0].queue_free()


func test_camera_slides_in_for_rock_and_glides_back_out() -> void:
	var r: Array = await _robot_room([[Vector3(0, 1.5, 1.6), Vector3(6, 3, 0.4)]])  # a wall just behind him
	var dwarf: Dwarf = r[1]
	dwarf._pitch = 0.0
	for i in 60:
		await tree.physics_frame
	check(dwarf.camera.global_position.z < 1.4, "camera stays in front of the rock (z %.2f, rock at 1.4)" % dwarf.camera.global_position.z)
	dwarf.global_position = Vector3(0, 0.05, -6)  # step away from the wall
	await tree.physics_frame
	await tree.physics_frame
	var right_after := dwarf.camera.position.z
	for i in 120:
		await tree.physics_frame
	var later := dwarf.camera.position.z
	check(right_after < later - 0.3, "glides back out instead of popping (%.2f → %.2f m)" % [right_after, later])
	check(later > Dwarf.CAMERA_DISTANCE * 0.9, "back to the normal distance (%.2f m)" % later)
	Controls.robot = false
	r[0].queue_free()


func test_sprint_dust_knows_wood_from_rock() -> void:
	var r: Array = await _robot_room()
	var root: Node3D = r[0]
	var dwarf: Dwarf = r[1]
	check(dwarf.floor_surface() == "rock", "a plain floor counts as rock (%s)" % dwarf.floor_surface())
	var plank := StaticBody3D.new()  # a dungeon bridge plank's box, tagged the way DungeonBuild tags them
	plank.collision_layer = World.TERRAIN_LAYER
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 0.2, 4)
	cs.shape = box
	cs.set_meta("surface", DungeonBuild.surface_of("dungeon/bridge_plank.glb"))
	plank.add_child(cs)
	root.add_child(plank)
	plank.global_position = Vector3(8, 0.1, 0)
	dwarf.global_position = Vector3(8, 0.25, 0)
	for i in 20:
		await tree.physics_frame
	check(dwarf.floor_surface() == "wood", "on a dungeon plank: wood (%s)" % dwarf.floor_surface())
	check(DungeonBuild.surface_of("dungeon/floor_old.glb") == "stone", "a dungeon's old floor is stone")
	var before := root.get_children().size()
	dwarf._kick_dust(6)
	check(root.get_children().size() > before, "a sprinting step throws up dust")
	Controls.robot = false
	root.queue_free()


## Owner (Nov 23, PC): "the animation finishes and then he just sprints forward... the animation should end where he
## should appear if it's a long jump" (F807) — the Jump pose was always one fixed-length clip, so a real jump (which
## hangs in the air longer than that clip runs) finished early and held its last pose while still mid-flight, looking
## like he was already running before he'd actually come down. Stretched to the real hang time, same trick as the
## roll's clip (F702).
func test_jump_animation_is_stretched_to_match_how_long_hes_really_airborne() -> void:
	Controls.setup()
	var root := _room([])
	var dwarf := _dwarf_in(root)
	var rig: DwarfRig = dwarf.model.dwarf_rig
	if rig == null:  # the rig-less fallback has its own fixed-length path, not this fix's target
		root.queue_free()
		return
	for i in 20:
		await tree.physics_frame
	check(dwarf.is_on_floor(), "dwarf stands before jumping")
	dwarf.bot_jump = true
	await tree.physics_frame
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var expected := 2.0 * Dwarf.JUMP_SPEED / gravity
	var scale: float = rig.tree.get("parameters/jump_speed/scale")
	check(scale > 0.0, "the jump clip got a playback scale at all")
	var plays_for := rig.tree.get_animation(DwarfRig.ANIMS.air).length / scale
	check(absf(plays_for - expected) < 0.05, "the jump pose is stretched to the real hang time (%.2f s vs %.2f s)" % [plays_for, expected])
	root.queue_free()


## Owner (Nov 23, PC) said the jump still looked wrong after the fix above: "it is the same, he jumps lands and if
## it a long jump he just sprints to the next stop" 🔁. The first fix guessed once at takeoff, assuming he'd come
## back down to the exact height he left — wrong for a real long jump, which often lands in a dip (a gap) or up on
## a rise, so that single guess stayed wrong for the whole flight. Now it re-guesses every tick from a straight-down
## ray to the real ground, so a landing well below launch gets the longer time it actually needs.
func test_jump_hang_guess_accounts_for_landing_lower_than_launch() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	_block(root, Vector3(-3, -0.5, 0), Vector3(6, 1, 6))  # launch platform, top at y = 0
	_block(root, Vector3(7, -3.5, 0), Vector3(6, 1, 6))  # landing platform, top at y = -3 (a real drop, like a gap)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(5, 1.0, 0)  # mid-flight, over the gap, above the lower platform
	await tree.physics_frame  # let the physics server register the new platforms (and free the last test's room)
	var vy := 5.5
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var drop := 4.0  # from y=1.0 down to the landing platform's top at y=-3
	var expected := (vy + sqrt(vy * vy + 2.0 * gravity * drop)) / gravity
	var flat_guess := 2.0 * vy / gravity
	var got: float = dwarf._jump_hang_guess(vy, 0.0)
	check(absf(got - expected) < 0.05, "guess accounts for the real drop (%.2f s vs %.2f s)" % [got, expected])
	check(got > flat_guess + 0.1, "landing lower takes longer than the flat up-and-down guess (%.2f s vs flat %.2f s)" % [got, flat_guess])
	root.queue_free()


## F494/F805, 5th time (owner, Nov 25): a stuck sprint heals itself: any mouse move, click or key press that says
## Shift is up lets go of "run" (bound to Shift), whatever made the game miss Shift coming back up.
func test_stuck_sprint_heals_on_the_next_mouse_move() -> void:
	Controls.setup()
	var move := InputEventMouseMotion.new()
	check(Dwarf.shift_is_really_up(move, true), "run held, the mouse says Shift is up: let go of run")
	move.shift_pressed = true
	check(not Dwarf.shift_is_really_up(move, true), "Shift really held: keep running")
	check(not Dwarf.shift_is_really_up(InputEventMouseMotion.new(), false), "not running: nothing to do")
	var click := InputEventMouseButton.new()
	check(Dwarf.shift_is_really_up(click, true), "a click with Shift up heals it too")
	var shift_key := InputEventKey.new()
	shift_key.keycode = KEY_SHIFT
	check(not Dwarf.shift_is_really_up(shift_key, true), "the Shift key's own event is left alone")
	var w := InputEventKey.new()
	w.keycode = KEY_W
	check(Dwarf.shift_is_really_up(w, true), "pressing W with Shift up heals it")
