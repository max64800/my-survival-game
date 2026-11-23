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
	var g := p.find_children("*", "GeometryInstance3D", true, false)
	return (g[0] as GeometryInstance3D).transparency if not g.is_empty() else -1.0


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
	rail.free()
	fade.update(aside.get_world_3d(), cam, chest, 1.0 / 60.0)   # (a removed piece is simply forgotten)
	aside.free()
