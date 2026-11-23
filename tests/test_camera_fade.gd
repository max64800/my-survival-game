extends TestCase
## F807 (owner, Nov 23, "best case"): a built piece between the camera and the dwarf turns a bit see-through.


func _piece(id: String, pos: Vector3) -> PieceNode:
	var n := PieceNode.new()
	n.piece = id
	n.family = "cut_stone"
	n.position = pos
	tree.root.add_child(n)
	return n


func _mesh_fade(p: PieceNode) -> float:
	for g in p.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		var m: Material = mi.material_override if mi.material_override else mi.get_surface_override_material(0)
		if m is ShaderMaterial and "see_cut" in (m as ShaderMaterial).shader.code:
			return float((m as ShaderMaterial).get_shader_parameter("see_amount"))
	return 0.0   # (its own paint = solid)


func test_pieces_in_the_way_turn_see_through() -> void:
	var far := Vector3(700, 200, 700)   # (up in the air, away from anything else in the test world)
	var rail := _piece("railing", far + Vector3(0, 0, 1.5))
	var aside := _piece("wall", far + Vector3(4, 0, 1.5))
	for i in 3:
		await tree.physics_frame
	var fade := CameraFade.new()
	var cam := far + Vector3(0, 0.6, 3.0)
	var chest := far + Vector3(0, 0.6, 0.0)
	for i in 30:   # half a second
		fade.update(rail.get_world_3d(), cam, chest, 1.0 / 60.0)
	check_near(fade.faded(rail), DwarfFeel.CAM_BUILD_FADE, 0.01, "the railing between them turns see-through")
	check_near(_mesh_fade(rail), DwarfFeel.CAM_BUILD_FADE, 0.01, "its model really shows it")
	check_near(_mesh_fade(aside), 0.0, 0.001, "a wall off to the side stays solid")
	for i in 30:   # the camera swings round: the railing isn't in the way any more
		fade.update(rail.get_world_3d(), far + Vector3(-3, 0.6, 0), chest, 1.0 / 60.0)
	check_near(_mesh_fade(rail), 0.0, 0.001, "out of the way, it turns solid again")
	for i in 10:
		fade.update(rail.get_world_3d(), cam, chest, 1.0 / 60.0)
	rail.free()
	fade.update(aside.get_world_3d(), cam, chest, 1.0 / 60.0)   # (a removed piece is simply forgotten, no error)
	aside.free()


## F807 round 3: a model's own paint is swapped for the see-through stand-in while in the way, and back after.
func test_models_get_the_see_through_paint_and_back() -> void:
	var far := Vector3(720, 200, 700)
	var wall := _piece("wall", far + Vector3(0, 0, 1.5))
	for i in 3:
		await tree.physics_frame
	var meshes := wall.find_children("*", "MeshInstance3D", true, false)
	var mi := meshes[0] as MeshInstance3D
	var before := mi.get_surface_override_material(0) if mi.mesh and mi.mesh.get_surface_count() > 0 else null
	var fade := CameraFade.new()
	var cam := far + Vector3(0, 1.0, 3.5)
	var chest := far + Vector3(0, 1.0, 0.0)
	for i in 30:
		fade.update(wall.get_world_3d(), cam, chest, 1.0 / 60.0)
	check(fade.faded(wall) > 0.5, "the wall in the way fades")
	if not mi.material_override:
		var now := mi.get_surface_override_material(0)
		check(now is ShaderMaterial and (now as ShaderMaterial).shader.resource_path.ends_with("see_through.gdshader"),
			"its model wears the see-through paint")
	for i in 40:
		fade.update(wall.get_world_3d(), far + Vector3(-4, 1.0, 0), chest, 1.0 / 60.0)
	check(mi.get_surface_override_material(0) == before, "out of the way, it gets its own paint back")
	wall.free()


## Owner, Nov 23: "the camera is not close enough to the thing that is blocking". With the camera far back and high,
## an upper floor just over his head is in the way too (the tube used to stop a metre short of him).
func test_floor_just_over_his_head_fades_with_camera_far_back() -> void:
	var far := Vector3(740, 200, 700)
	var chest := far + Vector3(0, 1.0, 0)
	var above := _piece("floor", far + Vector3(0, 2.2, 1.0))   # an upper floor, just over him and a bit back
	var under := _piece("floor", far + Vector3(0, 0, 1.0))     # the floor he walks on
	for i in 3:
		await tree.physics_frame
	var fade := CameraFade.new()
	var cam := chest + Vector3(0, 6.0, 5.0)   # zoomed far out, looking down at him
	for i in 30:
		fade.update(above.get_world_3d(), cam, chest, 1.0 / 60.0)
	check(fade.faded(above) > 0.5, "the floor over his head gets the circle")
	check_near(fade.faded(under), 0.0, 0.001, "the floor under his feet stays solid")
	above.free()
	under.free()


## Owner, Nov 23 (screenshots under the Twin Gate's upper floor): only the slab right on the line got the circle,
## the slabs next to it stayed solid and still hid him. Now, once anything is in the way, every piece on screen
## that is nearer than him gets the circle.
func test_whole_ceiling_on_screen_gets_the_circle() -> void:
	var base := Vector3(760, 200, 700)
	var tiles := []
	for x in range(-1, 2):
		for z in range(-1, 2):
			tiles.append(_piece("floor", base + Vector3(x * 2, 2.0, z * 2)))
	for i in 3:
		await tree.physics_frame
	var chest := base + Vector3(0, 1.3, 0)
	var cam_at := chest + Basis(Vector3.UP, 2.4) * Basis(Vector3.RIGHT, -0.7) * Vector3(0.5, 0, 8.0)
	var cam := Camera3D.new()
	tree.root.add_child(cam)
	cam.fov = 72.0
	cam.look_at_from_position(cam_at, chest)
	var fade := CameraFade.new()
	var world: World3D = tiles[0].get_world_3d()
	for i in 30:
		fade.update(world, cam_at, chest, 1.0 / 60.0, [], true, cam)
	var n := 0
	for t in tiles:
		if fade.faded(t) > 0.5:
			n += 1
	check(n >= 7, "the slabs round the one in the way get the circle too (%d of 9)" % n)
	for i in 40:   # nothing in the way any more: all solid again
		fade.update(world, base + Vector3(0, -5, 20), chest, 1.0 / 60.0, [], true, cam)
	check(tiles.all(func(t): return fade.faded(t) == 0.0), "out of the way, they all turn solid again")
	cam.free()
	for t in tiles:
		t.free()


## Owner, Nov 23 (Twin Gate, 4th plate stayed solid over his head, and "it switches between one stone plate and
## another"): a big building has far more pieces on screen than the search used to hand back (128). The floors
## under him filled the list first, so some slabs over his head were left out, a different few each frame.
func test_big_building_still_clears_every_slab_over_him() -> void:
	var base := Vector3(780, 200, 700)
	var tiles := []
	var ground := []
	for x in range(-1, 2):
		for z in range(-1, 2):
			tiles.append(_piece("floor", base + Vector3(x * 2, 2.0, z * 2)))
	for y in 4:   # (layers of floor under him, like the Twin Gate's many floors and steps)
		for x in range(-5, 6):
			for z in range(-5, 6):
				ground.append(_piece("floor", base + Vector3(x * 2, -0.2 * y, z * 2)))
	for i in 3:
		await tree.physics_frame
	var chest := base + Vector3(0, 1.3, 0)
	var cam_at := chest + Basis(Vector3.UP, 2.4) * Basis(Vector3.RIGHT, -0.7) * Vector3(0.5, 0, 8.0)
	var cam := Camera3D.new()
	tree.root.add_child(cam)
	cam.fov = 72.0
	cam.look_at_from_position(cam_at, chest)
	var fade := CameraFade.new()
	var world: World3D = tiles[0].get_world_3d()
	for i in 30:
		fade.update(world, cam_at, chest, 1.0 / 60.0, [], true, cam)
	var n := 0
	for t in tiles:
		if fade.faded(t) > 0.5:
			n += 1
	check(n >= 7, "with %d pieces round him, the slabs over him still get the circle (%d of 9)" % [ground.size(), n])
	for i in 40:
		fade.update(world, base + Vector3(0, -5, 20), chest, 1.0 / 60.0, [], true, cam)
	cam.free()
	for t in tiles + ground:
		t.free()
