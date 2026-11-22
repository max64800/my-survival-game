extends TestCase
## F577 (owner, Nov 21): "walk/sprint legs need to move faster, he slides", and the step sounds should match the feet.


## The loops now play at the speed where the feet grip the floor: faster legs the faster he goes.
func test_legs_keep_up_with_the_dwarf() -> void:
	check(DwarfRig.grip_feet, "gripping feet are on in the game")
	check(DwarfRig.loop_rate(4.0) > DwarfRig.LOOP_SPEED, "walking legs move faster than the old 70%")
	check(DwarfRig.loop_rate(6.5) > DwarfRig.loop_rate(4.0), "running legs faster still")


## 🔁 F577 (owner, Nov 22: "walking with no shift still feels like moonwalking"): the slow walk animation can't keep up
## with 4 m/s (its feet slid back at ~15% of his speed), so plain walking plays the trot, and Shift the sprint.
func test_plain_walking_trots_and_shift_sprints() -> void:
	check_eq(DwarfRig.MOVE_POINTS.jog, Dwarf.WALK_SPEED, "walking speed plays the trot (jog)")
	check_eq(DwarfRig.MOVE_POINTS.sprint, Dwarf.RUN_SPEED, "running speed plays the sprint, a different animation")
	check(DwarfRig.MOVE_POINTS.walk < Dwarf.WALK_SPEED, "the slow walk is only for slow moves (blocking, aiming)")
	check(DwarfRig.loop_rate(Dwarf.RUN_SPEED) > DwarfRig.loop_rate(Dwarf.WALK_SPEED), "sprint legs move faster")


## A step counts once, when the other foot comes clearly lower; level feet never click twice.
func test_a_step_is_a_foot_coming_down() -> void:
	check_eq(DwarfRig.lower_foot(0, 0.10, 0.20), -1, "left lower: left is down")
	check_eq(DwarfRig.lower_foot(-1, 0.20, 0.10), 1, "now right lower: right came down")
	check_eq(DwarfRig.lower_foot(1, 0.105, 0.10), 1, "nearly level: no new step")
	check_eq(DwarfRig.lower_foot(-1, 0.10, 0.105), -1, "nearly level the other way: still no step")
	var src := FileAccess.get_file_as_string("res://src/player/dwarf.gd")
	check(src.contains("var counted := rig.steps if rig else 0"), "the dwarf's step sound follows his feet, not a timer")


## The real rigged dwarf: walking his feet come down again and again, running they come down faster.
func test_the_rigged_dwarf_counts_his_steps() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY):
		return
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	var rate := {}
	for speed in [Dwarf.WALK_SPEED, Dwarf.RUN_SPEED]:
		for i in 30:  # (settle into the loop)
			rig.set_motion(speed, true, false)
			await rig.skeleton.skeleton_updated
		var start := rig.steps
		var t0 := Time.get_ticks_usec()
		while Time.get_ticks_usec() - t0 < 3_000_000:  # (3 s of real time: headless frames can come very fast)
			rig.set_motion(speed, true, false)
			await rig.skeleton.skeleton_updated
		var secs := (Time.get_ticks_usec() - t0) / 1e6
		rate[speed] = (rig.steps - start) / secs
		check(rig.steps - start >= 3, "at %.1f m/s his feet come down (%d steps)" % [speed, rig.steps - start])
	check(rate[Dwarf.RUN_SPEED] > rate[Dwarf.WALK_SPEED], "running steps come quicker (%.1f vs %.1f a second)" % [rate[Dwarf.RUN_SPEED], rate[Dwarf.WALK_SPEED]])
	await frames(1)
	holder.free()
