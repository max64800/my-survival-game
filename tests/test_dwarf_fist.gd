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
		# the handle's end pokes out a small stub past the little finger (great weapons: past the LEFT fist, at the end)
		var end: Vector3 = line[2]
		var low := f.left_center if rig.tool_look in DwarfFist.TWO_HANDED else f.fist_center
		var stub := (low - end).dot(line[1]) - f.fist_half
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


## Owner, Nov 19 (F389 round 5, his photo of a warrior with a long axe): the great axe and great maul always take both
## hands: the LEFT fist at the very end of the handle, the RIGHT fist higher up, wide apart in the stance; the handle runs
## through both fists and stays clear of his body; swings A, B, C (DwarfGreatSwing) take turns.
func test_two_handed_weapons_take_both_hands() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	for item in ["axe_2h_copper", "mace_2h_copper"]:
		m.set_held(item)
		for what in ["standing", "walking", "running"]:
			var speed: float = {"walking": 1.6, "running": 4.0}.get(what, 0.0)
			for i in 40:
				rig.set_motion(speed, true, false)
				await frames(1)
			rig.fist.measure_clearance = what == "standing"
			await rig.skeleton.skeleton_updated
			var fs := rig.fist
			check(fs.two_hand >= 1.0, "%s %s: both hands on the handle" % [item, what])
			var line := _handle_line(rig)
			var miss := _off_line(fs.left_center, line)
			check(miss < 0.01, "%s %s: the handle runs through the left fist (%.1f cm off)" % [item, what, miss * 100.0])
			var up: float = (fs.fist_center - fs.left_center).dot(line[1])
			check(up > 0.3, "%s %s: the right fist sits higher up the handle, wide apart (%.0f cm)" % [item, what, up * 100.0])
			if what == "standing":
				check(fs.clearance > 0.05, "%s: the handle clear of his body (%.0f cm, nearest: %s)" % [item, fs.clearance * 100.0, fs.clear_part])
			rig.fist.measure_clearance = false
		await _check_grip(rig, item + " stance")
	# the swings take turns: chop, sweep, slam (owner's pick)
	m.set_held("axe_2h_copper")
	var seen := []
	for step in 3:
		m.attack(0.6, false, step)
		await frames(2)
		seen.append(rig._upper_clip)
		for i in 45:
			await frames(1)
	check(seen == ["g/Chop", "g/Sweep", "g/Slam"], "the great axe swings chop, sweep, slam in turn (%s)" % [seen])
	m.queue_free()


## The animation rules' check (docs/art/ANIMATION-RULES.md 5, F389): every great axe swing, at each key and at 60
## moments in between: both fists within 2 cm of their spots, the handle 3+ cm clear of his body, his feet where they
## stood (hips turn, knees bend, feet planted), and at the hit the axe head in front of him.
func test_great_swings_keep_fists_and_handle_room() -> void:
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	m.set_held("axe_2h_copper")
	for i in 40:
		rig.set_motion(0.0, true, false)
		await frames(1)
	var tool: Node3D = rig.grip.get_child(rig.grip.get_child_count() - 1)
	var lo := INF
	var hi := -INF
	for mi: MeshInstance3D in tool.find_children("*", "MeshInstance3D", true, false):
		lo = minf(lo, mi.get_aabb().position.y)
		hi = maxf(hi, mi.get_aabb().end.y)
	var tool_len := (hi - lo) * tool.scale.y
	rig.fist.measure_clearance = true
	for mv: String in DwarfGreatSwing.MOVES:
		var ts: Array[float] = []
		for i in 60:  # (about one per frame of a light swing: 10 moments missed the fast strike's dips, chat 8)
			ts.append((float(i) + 0.5) / 60.0)
		for key: Array in DwarfGreatSwing.MOVES[mv]:
			ts.append(float(key[0]))
		var worst := {room = INF, miss = 0.0, feet = 0.0}
		var at := {room = 0.0, miss = 0.0, feet = 0.0}
		for t in ts:
			rig.great_fixed = DwarfGreatSwing.pose(mv, t, DwarfGreatSwing.STANCE)
			rig.set_motion(0.0, true, false)
			await frames(2)
			var f := rig.fist
			if f.clearance < float(worst.room):
				worst.room = f.clearance
				at.room = t
			if maxf(f.left_miss, f.right_miss) > float(worst.miss):
				worst.miss = maxf(f.left_miss, f.right_miss)
				at.miss = t
			if f.feet_miss > float(worst.feet):
				worst.feet = f.feet_miss
				at.feet = t
			if is_equal_approx(t, 0.40):
				var dir := (f.fist_center - f.left_center).normalized()
				var head := rig.global_transform.affine_inverse() * (f.left_center + dir * (tool_len * 0.9 - f.fist_half - DwarfFist.STUB))
				check(-head.z > 0.4, "%s: at the hit the axe head is in front of him (%.0f cm)" % [mv, -head.z * 100.0])
		check(float(worst.miss) <= 0.02, "%s: both fists on their spots all swing (worst %.1f cm at %d%%)" % [mv, float(worst.miss) * 100.0, roundi(float(at.miss) * 100)])
		check(float(worst.room) >= 0.03, "%s: the handle 3+ cm clear of his body all swing (least %.1f cm at %d%%)" % [mv, float(worst.room) * 100.0, roundi(float(at.room) * 100)])
		check(float(worst.feet) <= 0.02, "%s: his feet stay planted (worst %.1f cm off at %d%%)" % [mv, float(worst.feet) * 100.0, roundi(float(at.feet) * 100)])
	rig.great_fixed = {}
	rig.fist.measure_clearance = false
	m.queue_free()


## F389, Nov 20: the owner's own Blender poses (DwarfGreatSwing.posed_pose) play as he made them: the chop, frame by
## frame like the game: the handle runs through both fists, stays 3+ cm clear of his body, and at the top of the
## wind-up (the hold) his chest bones are turned exactly as in the file.
func test_owner_posed_chop_plays_as_made() -> void:
	if not DwarfGreatSwing.has_posed("Chop"):
		check(false, "the owner's chop poses are in %s" % DwarfGreatSwing.POSED_FILE)
		return
	var m := DwarfModel.new()
	tree.root.add_child(m)
	var rig := m.dwarf_rig
	m.set_held("axe_2h_copper")
	for i in 40:
		rig.set_motion(0.0, true, false)
		await frames(1)
	rig.fist.measure_clearance = true
	rig.play_upper("g/Chop", 1.1)
	var worst := {line = 0.0, room = INF, spine = 0.0}
	var at := {line = 0.0, room = 0.0, part = ""}
	var key: Dictionary = DwarfGreatSwing.posed_pose("Chop", 0.29, DwarfGreatSwing.posed_ready())
	var sp := rig.skeleton.find_bone("spine_02")
	for f in 66:
		rig.set_motion(0.0, true, false)
		await rig.skeleton.skeleton_updated
		var fs := rig.fist
		var line := _handle_line(rig)
		var off := maxf(_off_line(fs.left_center, line), _off_line(fs.fist_center, line))
		if off > float(worst.line):
			worst.line = off
			at.line = rig.great_t
		if fs.clearance < float(worst.room):
			worst.room = fs.clearance
			at.room = rig.great_t
			at.part = "%s, %.0f cm up the handle, guard pushed %.1f cm, fists off %.1f/%.1f cm" % [fs.clear_part,
				fs.clear_along * 100.0, fs.keep_push * 100.0, fs.left_miss * 100.0, fs.right_miss * 100.0]
		if rig.great_t > 0.275 and rig.great_t < 0.305:  # (the hold at the top of the wind-up)
			var q: Quaternion = key.bones["spine_02"]
			worst.spine = maxf(float(worst.spine), rad_to_deg(rig.skeleton.get_bone_pose_rotation(sp).angle_to(q)))
	check(float(worst.line) < 0.015, "posed chop: the handle through both fists all swing (worst %.1f cm at %d%%)" % [float(worst.line) * 100.0, roundi(float(at.line) * 100)])
	check(float(worst.room) >= 0.03, "posed chop: the handle 3+ cm clear of his body (least %.1f cm at %d%%: %s)" % [float(worst.room) * 100.0, roundi(float(at.room) * 100), at.part])
	check(float(worst.spine) < 0.5, "posed chop: his chest turned as the owner posed it (%.2f deg off)" % float(worst.spine))
	rig.fist.measure_clearance = false
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
