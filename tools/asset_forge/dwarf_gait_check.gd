extends SceneTree
## Measures the dwarf's walk and run (Nov 19, dwarf-animations Claude): for each speed the game uses, one whole loop:
## - sink: how far the lowest foot goes below the floor (cm; the feet should never go in),
## - lift: how high the body bobs (cm),
## - grip: how fast a planted foot moves backward, as a share of the dwarf's real speed (1.0 = no sliding;
##   0.6 = the foot skates forward 40% of the way, like on ice).
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_gait_check.gd

const SPEEDS := {"walk (slow)": 1.6, "walk (game)": 4.0, "run (game)": 6.5}


func _init() -> void:
	await process_frame
	var holder := Node3D.new()
	root.add_child(holder)
	DwarfRig.use_weight = true  # (off in the game: owner kept the old moves)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	if rig.weight and "noweight" in OS.get_cmdline_user_args():
		rig.weight.active = false
	if "grip" in OS.get_cmdline_user_args():
		DwarfRig.grip_feet = true
	var sk := rig.skeleton
	var feet := [sk.find_bone("foot_l"), sk.find_bone("ball_l"), sk.find_bone("foot_r"), sk.find_bone("ball_r")]
	var pelvis := sk.find_bone("pelvis")
	# The floor: where the lowest foot bone is when he stands still.
	rig.set_motion(0.0, true, false)
	for f in 40:
		await process_frame
	await sk.skeleton_updated
	var floor_y := INF
	for b in feet:
		floor_y = minf(floor_y, (sk.global_transform * sk.get_bone_global_pose(b).origin).y)
	for label in SPEEDS:
		var speed: float = SPEEDS[label]
		rig.set_motion(speed, true, false)
		for f in 40:
			await process_frame
		var loop := 1.2
		var lows := []
		var pel := []
		var grips := []
		var last := {}
		var t := 0.0
		var start := Time.get_ticks_usec()
		while t < loop:
			await sk.skeleton_updated
			var now := (Time.get_ticks_usec() - start) / 1000000.0
			var dt := now - t
			t = now
			var low := INF
			var ys := {}
			for b in feet:
				var p := sk.global_transform * sk.get_bone_global_pose(b).origin
				ys[b] = p
				low = minf(low, p.y)
			lows.append(low - floor_y)
			pel.append((sk.global_transform * sk.get_bone_global_pose(pelvis).origin).y)
			for b in [feet[1], feet[3]]:  # the balls of the feet
				var p: Vector3 = ys[b]
				if last.has(b) and dt > 0.0 and p.y - floor_y < 0.03:  # this foot is on the ground
					grips.append(Vector2(p.x - last[b].x, p.z - last[b].z).length() / dt / speed)
				last[b] = p
			rig.set_motion(speed, true, false)
		var g := 0.0
		for x in grips:
			g += x
		g = g / maxf(grips.size(), 1)
		print("GAIT %-12s lowest foot %5.1f..%5.1f cm  body bob %4.1f cm  grip %.2f" % [label,
			lows.min() * 100.0, lows.max() * 100.0, (pel.max() - pel.min()) * 100.0, g])
	quit()
