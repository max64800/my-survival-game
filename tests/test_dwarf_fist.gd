extends TestCase
## The dwarf's fists (DwarfFist, owner Nov 19: "the handle runs past his hand and his fingers stay open"):
## holding a tool, the fingers close round the handle and the handle runs through the middle of the fist.

const TIP_MAX := 0.045  ## m: a fingertip this close to the handle's middle line is wrapped round it (open: 8+ cm)


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
		for f in 10:
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
