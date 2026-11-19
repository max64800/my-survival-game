extends TestCase
## The dwarf's weight (DwarfWeight, owner Nov 19: "heavy + chunky"): feet on the floor, a heavy landing.


func _make_rig() -> DwarfRig:
	var holder := Node3D.new()
	tree.root.add_child(holder)
	DwarfRig.use_weight = true  # (off in the game: owner kept the old moves)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	DwarfRig.use_weight = false  # (so other tests get the game's dwarf)
	return rig


func _lowest_foot(rig: DwarfRig) -> float:
	var low := INF
	for b in ["ball_l", "ball_r", "foot_l", "foot_r"]:
		low = minf(low, rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone(b)).origin.y)
	return low


## The pack's jog and sprint pushed the feet up to 16 cm into the floor (measured Nov 19).
func test_feet_stay_out_of_the_floor_walking_and_running() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY):
		return
	var rig := _make_rig()
	check(rig.weight != null and rig.weight.active, "the dwarf has its weight layer")
	for speed in [4.0, 6.5]:
		var deepest := 0.0
		for i in 90:
			rig.set_motion(speed, true, false)
			await rig.skeleton.skeleton_updated
			if i > 20:
				deepest = maxf(deepest, rig.proportions._rest_low - _lowest_foot(rig))
		# (skeleton units; the dwarf is scaled ~x0.6 in the world, so 0.01 is well under 1 cm)
		check(deepest < 0.01, "at %.1f m/s no foot goes into the floor (deepest %.3f)" % [speed, deepest])
	await frames(1)  # (not while the skeleton is still telling everyone it moved)
	rig.get_parent().free()


## Landing squashes him: the chest bends forward and the shoulders sag (not lift), then he springs back.
func test_landing_squashes_then_springs_back() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY):
		return
	var rig := _make_rig()
	var sk := rig.skeleton
	var arm := sk.find_bone("upperarm_l")
	var chest := sk.find_bone("spine_03")
	var head := sk.find_bone("Head")
	var pelvis := sk.find_bone("pelvis")
	for i in 60:
		rig.set_motion(0.0, true, false)
		await sk.skeleton_updated
	var shoulder := func() -> float: return sk.get_bone_global_pose(arm).origin.y - sk.get_bone_global_pose(chest).origin.y
	var forward := func() -> float:
		return (sk.get_bone_global_pose(head).origin - sk.get_bone_global_pose(pelvis).origin).dot(rig.weight._fwd)
	var tall := func() -> float: return sk.get_bone_global_pose(head).origin.y - sk.get_bone_global_pose(pelvis).origin.y
	var s0: float = shoulder.call()
	var f0: float = forward.call()
	var t0: float = tall.call()
	rig.weight.land(0.8)
	var s_min := s0
	var f_max := f0
	var t_min := t0
	for i in 12:  # the first ~0.2 s after touching down
		rig.set_motion(0.0, true, false)
		await sk.skeleton_updated
		s_min = minf(s_min, shoulder.call())
		f_max = maxf(f_max, forward.call())
		t_min = minf(t_min, tall.call())
	check(t_min < t0 * 0.97, "landing squashes him shorter (head above hips %.3f -> %.3f)" % [t0, t_min])
	check(f_max > f0 + 0.005, "landing bends him forward (head ahead of hips %.3f -> %.3f)" % [f0, f_max])
	check(s_min < s0 - 0.002, "the shoulders sag on landing, not lift (%.3f -> %.3f)" % [s0, s_min])
	for i in 120:  # two seconds later he's back to normal
		rig.set_motion(0.0, true, false)
		await sk.skeleton_updated
	check(absf(tall.call() - t0) < t0 * 0.03, "then he springs back to his normal height")
	await frames(1)  # (not while the skeleton is still telling everyone it moved)
	rig.get_parent().free()
