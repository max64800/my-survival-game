extends TestCase
## The Furnish tab (owner, Nov 19): free CC0 furniture rebuilt in our paint. Every piece shows its own model (it fits
## its piece box and nothing floats), and the pieces that do something say what.


func _furniture() -> Array:
	return Pieces.LIST.keys().filter(func(k): return Pieces.LIST[k].group == "furnish")


func test_every_furniture_piece_has_a_model_that_fits() -> void:
	var list := _furniture()
	check(list.size() >= 30, "the Furnish tab is full (%d pieces)" % list.size())
	for k in list:
		var fam: String = Pieces.LIST[k].families[0]
		var m := PieceNode.forged_mesh(k, fam)
		if m == null:
			var scene := Look.forged("decor", String(Pieces.LIST[k].model).get_slice("/", 1))
			var why := "no model file"
			if scene:
				var parts := scene.find_children("*", "MeshInstance3D", true, false)
				why = "%d meshes" % parts.size()
				if parts.size() == 1:
					var mm: Mesh = (parts[0] as MeshInstance3D).mesh
					why = PieceNode.model_misfit(k, mm.get_aabb())
					if why == "":
						why = "%d floating parts" % PieceMesh.islands(mm).size()
				scene.free()
			check(false, "%s shows its model (%s)" % [k, why])


func test_furniture_that_does_something() -> void:
	var uses := {}
	for k in _furniture():
		var u: String = Pieces.LIST[k].get("use", "")
		if u != "":
			uses[u] = int(uses.get(u, 0)) + 1
	check(uses.get("bed", 0) >= 1 and uses.get("sit", 0) >= 3 and uses.get("store", 0) >= 3, "beds, seats and storage: %s" % [uses])
	var lights: Array = _furniture().filter(func(k): return Pieces.LIST[k].has("light"))
	check(lights.size() >= 4, "candles, the chandelier and torches give light (%d)" % lights.size())
