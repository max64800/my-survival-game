extends SceneTree
## Writes the game dwarf's skeleton, shaped by DwarfProportions and standing in its rest pose, to a JSON file, so the
## hand-built dwarf body can be modelled around the real bones in Blender (by Claude 3, Nov 16, 2026).
##
##   godot --headless --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_skeleton_dump.gd -- <out.json>
##
## Every bone: name, parent, and its transform in the DwarfModel's space (the player's look space: metres, feet on the
## floor, facing -Z), including the bone's thickness scale. Same numbers DwarfRig.dwarf_rest_poses() binds the body to.

func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var holder := Node3D.new()
	root.add_child(holder)
	var rig := DwarfRig.new()
	holder.add_child(rig)
	rig.build(Color(0.6, 0.45, 0.3))
	await process_frame
	var sk := rig.skeleton
	var poses: Array = rig.dwarf_rest_poses()  # skeleton-space transforms of every bone, shaped, standing
	var to_look := holder.global_transform.affine_inverse() * sk.global_transform
	var bones := []
	for i in sk.get_bone_count():
		var t: Transform3D = to_look * (poses[i] as Transform3D)
		var h: Transform3D = to_look * sk.get_bone_global_rest(i)  # the plain human, for comparison
		bones.append({
			"name": sk.get_bone_name(i), "parent": sk.get_bone_parent(i),
			"origin": [t.origin.x, t.origin.y, t.origin.z],
			"human_origin": [h.origin.x, h.origin.y, h.origin.z],
			"basis": [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z],
		})
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"bones": bones, "note": "DwarfModel space: metres, feet at y=0, facing -Z"}, "\t"))
	f.close()
	print("DUMP ", bones.size(), " bones -> ", out)
	quit()
