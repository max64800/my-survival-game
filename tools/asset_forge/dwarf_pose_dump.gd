extends SceneTree
## Writes the hand-built dwarf's head (face, hair, beard) and torso (shirt, shorts seat) exactly as the GAME bends
## them (Godot's own skinning, every animation clip, every 3rd frame), for tools/asset_forge/dwarf_clip_check.py:
## "does the beard or hair go through the body?" (owner, F183). By Claude, Nov 16, 2026.
##
##   godot --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_pose_dump.gd -- <out.bin>
##
## Writes <out.bin> (float32 x,y,z per point, frame after frame) and <out.bin>.json (counts, clips, the torso's
## triangles, the dwarf's world transform). Frame 0 is the pose the body was built in (DwarfRig.dwarf_rest_poses()).

## the same clips as dwarf_anim_export.gd (the 3D page)
const CLIPS := [
	["Standing", 2.4, "idle"], ["Walk", 1.4, "walk"], ["Run", 1.0, "jog"], ["Sprint", 0.8, "sprint"],
	["Mining", 1.2, "dig"], ["Sword", 1.0, "attack"], ["Chopping", 1.4, "chop"], ["Roll", 1.0, "roll"], ["Jump", 1.0, "air"],
]


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	await process_frame
	var holder := Node3D.new()
	root.add_child(holder)
	var rig := DwarfRig.new()
	rig.use_body = true
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	var sk := rig.skeleton
	var head := sk.find_child("body_head*", true, false) as MeshInstance3D
	var torso: Array[MeshInstance3D] = []
	for n in ["body_torso*", "body_pants*", "body_shirt*", "body_shorts*"]:  # (bare body, or the clothes)
		var mi := sk.find_child(n, true, false) as MeshInstance3D
		if mi != null:
			torso.append(mi)
	var tris := PackedInt32Array()
	var base := 0
	for mi in torso:
		var idx: PackedInt32Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
		for i in idx:
			tris.append(i + base)
		base += (mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("follow="):  # (to compare: how much of the head turning the dwarf keeps)
			rig.proportions.head_follow = float(a.substr(7))
	print("HEAD_FOLLOW ", rig.proportions.head_follow)
	var swing := sk.get_node_or_null("HairSwing") as SkeletonModifier3D
	if swing and "nosway" in OS.get_cmdline_user_args():
		swing.active = false  # (to compare: the braids without their springs)
	if swing is HairSwing and "nocol" in OS.get_cmdline_user_args():
		(swing as HairSwing)._colliders = []  # (to compare: the hair without its collision balls)
	if swing is HairSwing and "backrigid" in OS.get_cmdline_user_args():
		for ch: Dictionary in (swing as HairSwing)._chains:  # (to compare: the back hair held exactly at its resting place)
			if ch.kind == HairSwing.KINDS["back"]:
				ch.kind = {"stiff": 1.0, "drag": 1.0, "radius": 0.035, "bend": 7.0, "air": 0.0}
	print("SWING ", swing != null and swing.active)
	var f := FileAccess.open(out, FileAccess.WRITE)
	var clips := []
	for k in 3:  # (the skin needs a frame before it can be bent)
		await process_frame
	# frame 0: the pose the body was built in
	rig.dwarf_rest_poses()
	_write(f, head, torso)
	clips.append(["Built", 1])
	for c in CLIPS:
		if swing is HairSwing:
			(swing as HairSwing).biggest_swing = 0.0
		clips.append([c[0], await _record(rig, f, head, torso, c[1], c[2])])
		print("DUMPED ", c[0], "  biggest tuft swing: ", snappedf((swing as HairSwing).biggest_swing, 0.1) if swing is HairSwing else -1.0, " deg")
	var t: Transform3D = head.global_transform
	var head_tris: PackedInt32Array = head.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var info := {"head": _count(head), "torso": base, "tris": Array(tris), "head_tris": Array(head_tris), "clips": clips,
		"world": [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z,
			t.origin.x, t.origin.y, t.origin.z]}
	var j := FileAccess.open(out + ".json", FileAccess.WRITE)
	j.store_string(JSON.stringify(info))
	print("DUMP_DONE ", out)
	quit()


func _count(mi: MeshInstance3D) -> int:
	return (mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()


func _write(f: FileAccess, head: MeshInstance3D, torso: Array[MeshInstance3D]) -> void:
	for mi: MeshInstance3D in [head] + torso:
		var baked: ArrayMesh = mi.bake_mesh_from_current_skeleton_pose()
		f.store_buffer((baked.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).to_byte_array())


func _record(rig: DwarfRig, f: FileAccess, head: MeshInstance3D, torso: Array[MeshInstance3D], seconds: float, what: String) -> int:
	match what:
		"idle":
			rig.set_motion(0.0, true, false)
		"walk":
			rig.set_motion(1.6, true, false)
		"jog":
			rig.set_motion(4.0, true, false)
		"sprint":
			rig.set_motion(6.5, true, false)
		"air":
			rig.set_motion(0.0, false, false)
		"roll":
			rig.set_motion(3.0, true, true)
		"attack":
			rig.set_motion(0.0, true, false)
		_:
			rig.set_motion(0.0, true, false)
	for k in 20:  # settle into it
		await process_frame
	if what == "attack":
		rig.attack(seconds, false)
	elif what in ["dig", "chop"]:
		rig.play_upper(what, seconds)
	var frames := 0
	var start := Time.get_ticks_usec()
	var k := 0
	while (Time.get_ticks_usec() - start) / 1000000.0 <= seconds:
		await rig.skeleton.skeleton_updated  # (the final pose, after every modifier)
		k += 1
		if k % 3 == 0:
			_write(f, head, torso)
			frames += 1
	return frames
