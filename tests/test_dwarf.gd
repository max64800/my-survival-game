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
	ps.inventory.add("crossbow_copper", 1)
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
	check(absf(held_plays_for - Combat.DASH_HOLD_MAX) < 0.05, "holding the dash stretches the roll clip to match (%.2f s vs %.2f s)" % [held_plays_for, Combat.DASH_HOLD_MAX])
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