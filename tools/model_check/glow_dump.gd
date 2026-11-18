extends SceneTree
## Prints how a creature's glowing materials breathe in the game, over 12 seconds (Claude, Nov 18).
##   godot --headless --path . --script res://tools/model_check/glow_dump.gd -- rock_snail
func _init() -> void:
	var kind := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "rock_snail"
	var model := MonsterModel.build(kind, Color.WHITE, 1.0, false, kind, 1, "")
	root.add_child(model)
	var mats: Array = model.get_meta("glow_mats", [])
	for m: StandardMaterial3D in mats:
		print("GLOW ", m.resource_name, " texture=", m.emission_texture != null, " base=", m.get_meta("base_energy", 0.0))
	var line := "ENERGY"
	for k in 25:
		MonsterModel.animate(model, 0.0, 1.0, k * 0.5)
		line += " %.2f" % (mats[0] as StandardMaterial3D).emission_energy_multiplier if not mats.is_empty() else ""
	print(line)
	quit()
