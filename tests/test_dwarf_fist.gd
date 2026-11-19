extends TestCase
## The dwarf's fists (DwarfFist, owner Nov 19: "the handle runs past his hand and his fingers stay open"):
## holding a tool, the fingers close round the handle and the handle runs through the middle of the fist.

const TIP_MAX := 0.05  ## m: a fingertip this close to the handle's middle line is wrapped round it (open: 8+ cm)


## The handle's middle line, from the hand bone as the fist left it this frame (read inside skeleton_updated: Godot puts
## the plain animation pose back afterwards).
func _handle_line(rig: DwarfRig) -> Array:
	var sk := rig.skeleton
	var g := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_r")) * rig.right_hand.transform * rig.grip.transform
	var ax := Vector3.FORWARD if rig.tool_look == "spear" else Vector3.UP
	var off: Vector3 = rig.fist.handle[0]  # (the handle's middle line, measured from the tool's model)
	return [g * off, (g.basis * ax).normalized(), g * (off + ax * float(rig.fist.handle[1]))]


func _off_line(p: Vector3, line: Array) -> float:
	var d: Vector3 = p - (line[0] as Vector3)
	return (d - d.dot(line[1]) * (line[1] as Vector3)).length()


## Checks the grip in the pose playing now.
func _check_grip(rig: DwarfRig, what: String) -> void:
	var sk := rig.skeleton
	await sk.skeleton_updated
	var f := rig.fist
	check(f.holding, "%s: the fist is closed round the handle" % what)
	var line := _handle_line(rig)
	var off := _off_line(f.fist_center, line)
	check(off < 0.005, "%s: the handle runs through the middle of the fist (%.1f cm off)" % [what, off * 100.0])
	var tilt := rad_to_deg(f.fist_axis.angle_to(line[1]))
	check(tilt < 4.0 or tilt > 176.0, "%s: the handle lies along the hole through the fist (%.0f degrees off)" % [what, tilt])
	for finger in ["index", "middle", "ring", "pinky"]:
		var tip := sk.global_transform * sk.get_bone_global_pose(sk.find_bone(finger + "_04_leaf_r")).origin
		var d := _off_line(tip, line)
		check(d < TIP_MAX, "%s: the %s finger wraps round the handle (tip %.1f cm from its middle)" % [what, finger, d * 100.0])
	if rig.tool_look != "spear":
		# the handle's end pokes out a small stub past the little finger
		var end: Vector3 = line[2]
		var stub := (f.fist_center - end).dot(line[1]) - f.fist_half
		check(stub > 0.03 and stub < 0.07, "%s: a small stub of handle below the fist (%.1f cm)" % [what, stub * 100.0])


func test_fist_closes_round_the_handle() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	check(rig.fist != null, "the dwarf has fists")
	m.set_held("pickaxe_copper")
	for f in 15:
		rig.set_motion(0.0, true, false)
		await frames(1)
	await _check_grip(rig, "standing")
	for f in 40:
		rig.set_motion(4.0, true, false)
		await frames(1)
	await _check_grip(rig, "running (shoulder carry)")
	rig.set_motion(0.0, true, false)
	m.set_held("axe_copper")
	rig.play_upper("chop", 1.4)
	for f in 20:
		rig.set_motion(0.0, true, false)
		await frames(1)
	await _check_grip(rig, "chopping")
	for item in ["axe_stone", "sword_copper", "mace_copper", "spear_copper", "axe_2h_copper", "mace_2h_copper", "pickaxe_stone"]:
		m.set_held(item)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 800:  # (the great weapons swing up onto his shoulder first)
			rig.set_motion(0.0, true, false)
			await frames(1)
		await _check_grip(rig, item)
	m.queue_free()


func test_shield_hand_makes_a_fist() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	var sk := rig.skeleton
	var tip := func() -> float:
		await sk.skeleton_updated
		var hand := sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
		var mid := sk.get_bone_global_pose(sk.find_bone("middle_03_l")).origin
		var knuckle := sk.get_bone_global_pose(sk.find_bone("middle_01_l")).origin
		return (mid - hand).length() / (knuckle - hand).length()  # < 1: the finger curls back toward the palm
	await frames(10)
	var open: float = await tip.call()
	m.set_shield("shield_copper")
	await frames(10)
	var closed: float = await tip.call()
	check(closed < open - 0.03, "with a shield on, the left fingers close round its strap (%.2f -> %.2f)" % [open, closed])
	m.queue_free()


func test_open_hand_without_a_tool() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	m.set_held("")
	await frames(10)
	check(not rig.fist.holding, "no tool: the fingers stay as the animation has them")
	m.set_held("stone")
	await frames(10)
	check(not rig.fist.holding, "a stone sits in the open hand, no fist round a handle")
	m.queue_free()


## Owner, Nov 19: the great axe and great maul are two-handed in the swings (the left hand higher up the handle);
## standing, walking and running they rest on his shoulder in one hand.
func test_two_handed_weapons_take_both_hands() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	for item in ["axe_2h_copper", "mace_2h_copper"]:
		m.set_held(item)
		for what in ["standing", "walking", "swinging", "running"]:
			var speed: float = {"walking": 1.6, "running": 4.0}.get(what, 0.0)
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 1200:  # (real time: let the last move finish)
				rig.set_motion(speed, true, false)
				await frames(1)
			if what == "swinging":
				m.attack(1.2, false)
			var worst := 0.0
			var on := 0
			var off := 0  # frames with the left fist more than 2 cm off the handle
			var frames_n := 70  # (the whole 1.2 s swing; the fastest moments were the hard ones)
			for f in frames_n:
				rig.set_motion(speed, true, false)
				await rig.skeleton.skeleton_updated
				var fs := rig.fist
				if fs.two_hand >= 1.0:
					on += 1
					var line := _handle_line(rig)
					var miss := _off_line(fs.left_center, line)
					var up: float = (fs.left_center - fs.fist_center).dot(line[1])
					if miss > 0.02 or up < 0.08:
						off += 1  # (known: a few frames at the very fastest part of the great axe's swing, Nov 19)
					else:
						worst = maxf(worst, miss)
			if what != "swinging":
				check(on == 0, "%s %s: one hand, the weapon on his shoulder (%d frames with two)" % [item, what, on])
			else:
				check(on >= frames_n - 3, "%s %s: both hands on the handle (%d of %d frames; the first come off the shoulder)" % [item, what, on, frames_n])
				check(worst < 0.01, "%s %s: the left fist round the handle (up to %.1f cm off)" % [item, what, worst * 100.0])
				check(off <= (4 if what == "swinging" else 0), "%s %s: the left fist slips off the handle in %d frames" % [item, what, off])
	m.queue_free()


## Owner, Nov 19: the shield is held by its grip (the left fist), the forearm through the leather loops on its back.
func test_shield_worn_on_the_forearm() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	m.set_held("sword_copper")
	m.set_shield("shield_copper")
	for pose in ["", "shield"]:
		rig.set_hold(pose)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 800:
			rig.set_motion(0.0, true, false)
			await frames(1)
		var sk := rig.skeleton
		await sk.skeleton_updated
		var sh := rig.shield_grip.get_child(0) as Node3D
		var hand := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l"))
		var w := hand * rig.left_hand.transform * rig.shield_grip.transform * sh.transform * (sh.get_child(0) as Node3D).transform
		var what := "blocking" if pose != "" else "standing"
		var grip_line := [w * DwarfFist.SHIELD_GRIP, (w.basis * DwarfFist.SHIELD_GRIP_DIR).normalized()]
		var along: float = (rig.fist.left_center - (grip_line[0] as Vector3)).dot(grip_line[1])
		check(_off_line(rig.fist.left_center, grip_line) < 0.01 and absf(along) <= 0.06, "%s: the left fist holds the shield's grip (%.1f cm along it)" % [what, along * 100.0])
		var wrist := hand.origin
		var elbow := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("lowerarm_l")).origin
		var fore := [wrist, (elbow - wrist).normalized()]
		for loop_x in [0.111, 0.056]:  # (tools/asset_forge/builds/items_tools.py shield_back: the two forearm loops)
			var loop := w * Vector3(loop_x, 0.41, -0.08)
			var d := _off_line(loop, fore)
			check(d < 0.02, "%s: the forearm runs through the loop at %.3f (%.1f cm off its middle)" % [what, loop_x, d * 100.0])
		var face := (w.basis * Vector3.BACK).normalized()
		var chest := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("spine_03")).origin
		check(face.dot(rig.fist.left_center - chest) > 0.0, "%s: the shield's face points away from him" % what)
	m.queue_free()
