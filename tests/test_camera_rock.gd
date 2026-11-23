extends TestCase
## F766 (owner, Nov 23): "if I am against the wall, it doesn't zoom in my camera all the way close to my character,
## but I can still see through the wall and the rock". Rock walls and dungeon walls no longer push the camera in
## (only the ground does), and a dungeon wall between the camera and him fades like a building.


func _spring_at(pos: Vector3) -> SpringArm3D:
	var s := SpringArm3D.new()
	s.spring_length = 4.0
	s.collision_mask = World.TERRAIN_LAYER
	var sh := SphereShape3D.new()
	sh.radius = 0.25
	s.shape = sh
	s.margin = 0.25
	s.position = pos      # (it reaches back along +z, like the dwarf's)
	tree.root.add_child(s)
	return s


## A slab of "rock": a closed trimesh, like the voxel cave's (or a plain box, like a dungeon's wall boxes).
func _rock(centre: Vector3, size: Vector3, trimesh := true, ruin := false) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = World.TERRAIN_LAYER
	b.collision_mask = 0
	b.position = centre
	if ruin:
		b.add_to_group(RuinKit.GROUP)
	var cs := CollisionShape3D.new()
	if trimesh:
		var bm := BoxMesh.new()
		bm.size = size
		cs.shape = bm.create_trimesh_shape()
	else:
		var box := BoxShape3D.new()
		box.size = size
		cs.shape = box
	b.add_child(cs)
	tree.root.add_child(b)
	return b


func _settle() -> void:
	for i in 4:
		await tree.physics_frame


func test_rock_wall_behind_him_doesnt_push_the_camera_in() -> void:
	var far := Vector3(900, 300, 900)   # (up in the air, away from anything else in the test world)
	var spring := _spring_at(far + Vector3(0, 0.9, 0))
	var wall := _rock(far + Vector3(0, 1.5, 1.5), Vector3(6, 4, 1.0))
	await _settle()
	check(spring.get_hit_length() < 1.5, "the spring arm alone bumps the rock (%.2f m)" % spring.get_hit_length())
	check_near(CameraRoom.room(spring), 4.0, 0.01, "but the camera goes all the way back through the rock wall")
	wall.free()
	var thick := _rock(far + Vector3(0, 1.5, 2.5), Vector3(6, 4, 3.0), false, true)   # (a dungeon's wall box)
	await _settle()
	check_near(CameraRoom.room(spring), 4.0, 0.01, "and through a thick dungeon wall")
	thick.free()
	spring.free()


func test_the_ground_still_stops_the_camera() -> void:
	var far := Vector3(-900, 300, 900)
	var spring := _spring_at(far + Vector3(0, 0.9, 0))
	var ground := _rock(far + Vector3(0, -0.5, 0), Vector3(20, 1.0, 20))   # (top at his feet)
	spring.rotation.x = 0.5    # (looking up: the arm reaches back and down, into the ground)
	await _settle()
	var r := CameraRoom.room(spring)
	check(r < 3.0, "the ground behind him stops the camera, so you never look up from under it (%.2f m)" % r)
	var wall := _rock(far + Vector3(0, 1.5, 0.9), Vector3(6, 4, 0.6))   # (a wall right behind him too)
	await _settle()
	var r2 := CameraRoom.room(spring)
	check(r2 < 3.0, "slipping through a wall still stops at the ground (%.2f m)" % r2)
	ground.free()
	wall.free()
	spring.free()


func test_dungeon_walls_fade_but_floors_dont() -> void:
	var far := Vector3(900, 300, -900)
	var chest := far + Vector3(0, 0.9, 0)
	var cam := far + Vector3(0, 1.4, 3.0)
	var floor_box := _rock(far + Vector3(0, -0.1, 1.5), Vector3(6, 0.2, 6), false, true)
	await _settle()
	var fade := CameraFade.new()
	for i in 30:
		fade.update(floor_box.get_world_3d(), cam, chest, 1.0 / 60.0)
	check_near(fade.world_faded(), 0.0, 0.001, "the dungeon floor under him doesn't switch the circle on")
	var wall := _rock(far + Vector3(0, 1.5, 1.5), Vector3(6, 3, 0.3), false, true)
	await _settle()
	for i in 30:
		fade.update(wall.get_world_3d(), cam, chest, 1.0 / 60.0)
	check_near(fade.world_faded(), DwarfFeel.CAM_BUILD_FADE, 0.01, "a dungeon wall between them fades in")
	wall.free()
	await _settle()
	for i in 60:
		fade.update(floor_box.get_world_3d(), cam, chest, 1.0 / 60.0)
	check_near(fade.world_faded(), 0.0, 0.001, "and back out once it's gone")
	floor_box.free()


func test_dungeon_paints_get_the_circle() -> void:
	check(DungeonBuild.lies_low("build/floor__root_wood.glb"), "a built floor keeps its low part")
	check(DungeonBuild.lies_low("dungeon/floor_old.glb"), "an old floor too")
	check(DungeonBuild.lies_low("dungeon/junk_bones.glb"), "junk on the ground too")
	check(not DungeonBuild.lies_low("build/wall__root_wood.glb"), "a built wall fades all over")
	check(not DungeonBuild.lies_low("dungeon/wall_old.glb"), "an old wall too")
	var bm := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.4, 0.3)
	bm.material = mat
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	am.surface_set_material(0, mat)
	var see := CameraFade.see_mesh(am, true)
	var m := see.surface_get_material(0) as ShaderMaterial
	check(m != null and "see_cut" in m.shader.code, "the batch's paint is the see-through one")
	if m:
		check(bool(m.get_shader_parameter("keep_low")), "floors keep their low part solid")
		check_near(float(m.get_shader_parameter("see_amount")), 0.0, 0.001, "solid until a wall is in the way")
	check(am.surface_get_material(0) == mat, "the model's own mesh keeps its own paint (built pieces share it)")
