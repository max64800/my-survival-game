extends TestCase
## F169 / F626 (owner, Nov 22): stairs are only the steps on a thin slanted underside, open below, so you can
## walk under them or put a chest, barrel or crate there. The build rules let furniture in that space (both ways
## round), and the stairs' bodies leave it empty.

const SPOTS := {  # stairs piece -> [a barrel or crate that fits under it, one that doesn't] (its own frame)
	"stairs": [["crate", Vector3(0, 0, -0.85)], ["crate", Vector3(0, 0, 0.0)]],
	"stairs_corner": [["barrel", Vector3(-0.55, 0, -0.6)], ["barrel", Vector3(0.5, 0, 0.5)]],
	"stairs_spiral": [["barrel", Vector3(1.0, 0, 1.0)], ["barrel", Vector3(0.9, 0, -0.5)]],  # F716: under the landing
}


func test_furniture_fits_under_the_stairs() -> void:
	for st: String in SPOTS:
		for rot in [0, 2]:
			var b := Basis(Vector3.UP, Pieces.yaw_of(rot))
			var fits: Array = SPOTS[st][0]
			var blocked: Array = SPOTS[st][1]
			var s := Structure.new()
			s.add(1, st, "cut_stone", Vector3(10, 0, 10), rot, true)
			check(not s.overlaps(fits[0], Vector3(10, 0, 10) + b * fits[1], rot),
				"%s rot %d: a %s fits under it" % [st, rot, fits[0]])
			check(s.overlaps(blocked[0], Vector3(10, 0, 10) + b * blocked[1], rot),
				"%s rot %d: a %s under the low steps doesn't" % [st, rot, blocked[0]])
			# the other way round: the furniture first, then the stairs over it
			var t := Structure.new()
			t.add(1, fits[0], "plank_root", Vector3(10, 0, 10) + b * fits[1], rot, true)
			check(not t.overlaps(st, Vector3(10, 0, 10), rot), "%s rot %d: can be built over a %s" % [st, rot, fits[0]])
	var s := Structure.new()
	s.add(1, "stairs", "cut_stone", Vector3.ZERO, 0, true)
	check(s.overlaps("shelf", Vector3(0, 0, -0.8), 0), "a tall shelf doesn't fit under the stairs")
	check(s.overlaps("crate", Vector3(0, 2.2, -0.85), 0) == false, "a crate on top of the stairs' top is fine")


func test_the_space_under_the_stairs_is_empty() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var spots := {}
	var k := 0
	for st: String in SPOTS:
		for fam: String in Pieces.KIT_FAMILIES:
			var n: PieceNode = preload("res://src/build/piece_node.gd").new()
			n.piece = st
			n.family = fam
			root.add_child(n)
			n.global_position = Vector3(4 * k, 0, 0)
			spots["%s %s" % [st, fam]] = Vector3(4 * k, 0, 0) + SPOTS[st][0][1]
			k += 1
	await tree.physics_frame
	await tree.physics_frame
	var space := root.get_world_3d().direct_space_state
	for name: String in spots:
		var p: Vector3 = spots[name]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.85, 0), p + Vector3(0, 0.03, 0)))
		check(hit.is_empty(), "%s: nothing solid in the space under it (hit %s)" % [name, hit.get("position")])
		var top := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 3, 0), p + Vector3(0, 0.9, 0)))
		check(not top.is_empty(), "%s: the steps are still above that spot" % name)
	root.queue_free()
