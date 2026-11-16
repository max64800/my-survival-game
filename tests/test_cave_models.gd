extends TestCase
## The hand-built cave plants and crystals (tools/asset_forge/builds/cave_plants.py): each loads with its painted
## pictures (a Blender JPEG Godot can't read turns a model white), and the game uses them.


func test_every_part_has_its_painted_pictures() -> void:
	for model in GlowField.CAVE_MODELS:
		var ps := load(GlowField.CAVE_MODELS[model]) as PackedScene
		check(ps != null, "%s loads" % model)
		if ps == null:
			continue
		var inst := ps.instantiate()
		var glow := 0
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).mesh.surface_get_material(i) as StandardMaterial3D
				check(m != null and m.albedo_texture != null, "%s %s has its colour picture" % [model, mi.name])
				check(m != null and m.normal_texture != null, "%s %s has its normal map" % [model, mi.name])
				if m and m.resource_name.begins_with("glow_"):
					glow += 1
		check(model == "root" or glow > 0, "%s has a glowing part" % model)
		inst.free()


func test_glow_field_uses_them() -> void:
	var f := GlowField.new()
	for kind in ["crystal", "crystal_amber", "glowcap", "hollowcap", "root", "root_dangle", "giant_mushroom"]:
		var model := f._model_of(kind)
		check(model != "", "%s uses a hand-built model" % kind)
		check(f._cave_mesh(model) != null and f._cave_mesh(model).get_surface_count() >= 2, "%s model has its parts" % kind)
	check_eq(f._model_of("fiber"), "", "fiber keeps its simple tufts")
	f.free()
