extends TestCase
## Models must arrive in the game WITH their pictures (F164, Nov 16). Blender 5.3 writes a colour profile into every
## JPEG; Godot 4.7 can't read such a picture, so the model loads white. tools/asset_forge/glb_jpeg_fix.py removes it,
## and every export script must call it. This test catches a model that slipped through: every baked material
## ("*_baked", from the sculpt-and-bake pass) must have its colour picture.


func _baked_without_picture(path: String) -> Array:
	var missing := []
	var scene: PackedScene = load(path)
	if scene == null:
		return ["(could not load)"]
	var root := scene.instantiate()
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D and String(m.resource_name).ends_with("_baked") and (m as StandardMaterial3D).albedo_texture == null:
				missing.append(String(m.resource_name))
	root.free()
	return missing


func test_creatures_load_with_their_pictures() -> void:
	var dir := DirAccess.open("res://assets/models/creatures")
	check(dir != null, "the creatures folder exists")
	if dir == null:
		return
	var seen := 0
	for f in dir.get_files():
		if f.ends_with(".glb"):
			var missing := _baked_without_picture("res://assets/models/creatures/" + f)
			check(missing.is_empty(), "%s: every baked part has its picture (missing: %s)" % [f, missing])
			seen += 1
	check(seen > 0, "found creature models to check")


## The hand-built dwarf (round 2, Nov 16): its sculpted head, eyes and copper rings are baked too.
func test_dwarf_body_loads_with_its_pictures() -> void:
	if not ResourceLoader.exists(DwarfRig.BODY):
		return
	var missing := _baked_without_picture(DwarfRig.BODY)
	check(missing.is_empty(), "the dwarf's baked parts have their pictures (missing: %s)" % [missing])
	var scene: PackedScene = load(DwarfRig.BODY)
	var root := scene.instantiate()
	var baked := 0
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D and String(m.resource_name).ends_with("_baked"):
				baked += 1
	root.free()
	check(baked >= 3, "the head, eyes and copper rings are baked (%d baked parts)" % baked)
