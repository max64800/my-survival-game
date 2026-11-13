extends SceneTree
## Writes res://blueprints/small_rootwood_lodge.dwbp (the blueprint that ships with the game).
## Run: godot --headless --path . --script res://tools/make_starter_blueprint.gd


func _initialize() -> void:
	var s := Structure.new()
	var uid := 1
	for x in [-2, 0, 2]:
		for z in [-1, 1]:
			s.add(uid, "floor", "cut_stone", Vector3(x, 0, z), 0, true)
			uid += 1
	var walls := [
		["wall", Vector3(-2, 0.25, -2), 0], ["wall", Vector3(0, 0.25, -2), 0], ["wall", Vector3(2, 0.25, -2), 0],
		["wall", Vector3(-2, 0.25, 2), 0], ["doorway", Vector3(0, 0.25, 2), 0], ["wall", Vector3(2, 0.25, 2), 0],
		["wall", Vector3(-3, 0.25, -1), 1], ["wall", Vector3(-3, 0.25, 1), 1],
		["window_wall", Vector3(3, 0.25, -1), 1], ["wall", Vector3(3, 0.25, 1), 1],
	]
	for w in walls:
		s.add(uid, w[0], "plank_root", w[1], w[2], false)
		uid += 1
	for c in [Vector3(-3, 0.25, -2), Vector3(3, 0.25, -2), Vector3(-3, 0.25, 2), Vector3(3, 0.25, 2)]:
		s.add(uid, "pillar", "cut_stone", c, 0, false)
		uid += 1
	# Open air inside the lodge, rock below the floor.
	var sdf := func(p: Vector3) -> float: return p.y
	var bp := Blueprint.capture(s, sdf, Vector3(-4, 0, -3), Vector3(4, 3, 3), "Small Rootwood Lodge")
	bp.author = "Dwarf Game"
	bp.source = "ancient"
	var f := FileAccess.open("res://blueprints/small_rootwood_lodge.dwbp", FileAccess.WRITE)
	f.store_string(bp.to_json())
	f.close()
	print("wrote %d pieces, cost %s" % [bp.pieces.size(), bp.cost()])
	quit()
