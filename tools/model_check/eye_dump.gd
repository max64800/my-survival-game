extends SceneTree
## Prints the eye materials of a creature as the game sets it up (Claude, Nov 18: "the snail's eyes are white").
##   godot --headless --path . --script res://tools/model_check/eye_dump.gd -- rock_snail
func _init() -> void:
	var kind := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "rock_snail"
	var model := MonsterModel.build(kind, Color.WHITE, 1.0, false, kind, 1, "")
	root.add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m is StandardMaterial3D and String(m.resource_name).begins_with("eye"):
				var s := m as StandardMaterial3D
				print("EYE ", mi.name, " surf ", i, " ", s.resource_name, " tex=", s.albedo_texture != null, " col=", s.albedo_color,
					" emis_on=", s.emission_enabled, " emis=", s.emission, " energy=", s.emission_energy_multiplier, " override=", mi.get_surface_override_material(i) != null)
	quit()
