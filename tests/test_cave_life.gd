extends TestCase
## Cave life (F188, src/art/cave_life.gd): moss, grass, small roots, lichen and ferns. Hand-built models that load
## with their painted pictures, the same patches on every computer, growing near life on real rock, gone where dug.


func test_models_load_with_their_pictures() -> void:
	for kind in CaveLife.KINDS:
		var mesh := CaveLife.mesh_of(kind)
		check(mesh != null and mesh.get_surface_count() > 0, "%s loads" % kind)
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i)
			var tex: Texture2D = null
			if m is ShaderMaterial:
				tex = (m as ShaderMaterial).get_shader_parameter("albedo_tex")
			elif m is StandardMaterial3D:
				tex = (m as StandardMaterial3D).albedo_texture
			check(tex != null, "%s part %d has its painted picture" % [kind, i])


func test_moss_is_drawn_in_fuzz_layers() -> void:
	var a := CaveLife.mesh_of("moss").surface_get_arrays(0)
	var c: PackedColorArray = a[Mesh.ARRAY_COLOR]
	check(c.size() > 0 and c[0].a == 0.0 and is_equal_approx(c[c.size() - 1].a, 1.0), "moss layers go from the cushion (0) to the tips (1)")
	check(CaveLife.mesh_of("moss").surface_get_material(0) is ShaderMaterial, "moss uses the fuzzy shader")
	check(CaveLife.mesh_of("grass").get_surface_count() == 2, "grass: soil and blades")


func test_same_cave_same_patches() -> void:
	var maker := CaveMaker.new(12)
	var t := Time.get_ticks_msec()
	var a := CaveLife.plan(maker, GlowPlacer.place(maker))
	print("        (%d plants in %d ms)" % [a.size(), Time.get_ticks_msec() - t])
	var other := CaveMaker.new(12)
	var b := CaveLife.plan(other, GlowPlacer.place(other))
	check_eq(a.size(), b.size(), "same number of plants")
	if a.size() == b.size() and a.size() > 0:
		var i := a.size() / 2
		check(a[i].xform.is_equal_approx(b[i].xform), "same place")
		check_eq(a[i].kind, b[i].kind, "same kind")


func test_patches_near_life_on_real_rock() -> void:
	var maker := CaveMaker.new(12)
	var spots := GlowPlacer.place(maker)
	var plants := CaveLife.plan(maker, spots)
	var counts := {}
	var lonely := 0
	var floating := 0
	var rock := CaveLife.Rock.new(maker)  # the rock as it is drawn
	for j in plants.size():
		var p: Dictionary = plants[j]
		counts[p.kind] = counts.get(p.kind, 0) + 1
		var at: Vector3 = p.xform.origin
		var up: Vector3 = p.xform.basis.y.normalized()
		if rock.at(at - up * 0.3) >= 0.0:
			floating += 1  # no rock just under it
		if j % 4 != 0 or p.kind in ["gravel", "gravel_b", "tinycaps"]:  # (those go almost everywhere)
			continue
		var near := false
		for s in spots:
			var flat := Vector2(s.pos.x - at.x, s.pos.z - at.z).length()
			if (s.kind == GlowPlacer.DRIP and flat <= 4.2 and s.pos.y > at.y) or s.pos.distance_to(at) <= 4.2:
				near = true
				break
		if not near:
			lonely += 1
	print("        %s" % counts)
	check(plants.size() >= 2000, "a cave that doesn't look empty (got %d plants)" % plants.size())
	for kind in ["moss", "grass", "fern", "rootlet", "lichen", "gravel", "gravel_b", "tinycaps"]:
		check(counts.get(kind, 0) >= 10, "enough %s (got %d)" % [kind, counts.get(kind, 0)])
	check_eq(lonely, 0, "everything grows in a patch near a glowing thing, a drip or a root")
	check(floating <= plants.size() / 50, "(almost) everything has rock right under it (%d floating)" % floating)


func test_digging_removes_what_grew_there() -> void:
	var maker := CaveMaker.new(12)
	var life := CaveLife.new()
	life.build(maker, GlowPlacer.place(maker))
	var x := life.nearest("moss", Vector3.ZERO)
	check(x.origin != Vector3.INF, "there is moss")
	life._on_rock_changed(x.origin, 0.5)
	var y := life.nearest("moss", x.origin)
	check(y.origin.distance_to(x.origin) > 0.01, "the moss where the rock was dug is gone (%s, %s)" % [x.origin, y.origin])
	life.free()


## Owner F197: a swing that lands on grass, a fern or a small root breaks it; every computer removes it.
func test_hitting_grass_breaks_it() -> void:
	var maker := CaveMaker.new(12)
	var life := CaveLife.new()
	life.build(maker, GlowPlacer.place(maker))
	var g := life.nearest("grass", Vector3.ZERO)
	check(g.origin != Vector3.INF, "there is grass")
	var id := life.breakable_at(g.origin + Vector3(0.1, 0.0, 0.05))
	check(id >= 0, "a swing next to the tuft finds it")
	life.remove_plant(id)
	check(life.position_of(id) == Vector3.INF, "it's gone")
	check(life.breakable_at(life.nearest("lichen", Vector3.ZERO).origin, 0.05) == -1, "lichen doesn't break (only grass, ferns, small roots)")
	life.free()
