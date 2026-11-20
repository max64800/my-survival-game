extends SceneTree
## How much fiber a world has (Nov 20 economy check): spots by kind, and the fiber near the start.
##   godot --headless --path . --script res://tools/fiber_count.gd -- seed=42


func _init() -> void:
	var seed := 42
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seed="):
			seed = a.trim_prefix("seed=").to_int()
	var m := CaveMaker.new(seed)
	var spots := GlowPlacer.place(m)
	var start: Vector3 = m.start_pos if "start_pos" in m else m.rooms[0].center
	var kinds := {}
	var near := {}
	for s in spots:
		var biome: String = CaveMaker.biome_at(s.pos) if s.has("pos") else "?"
		var k: String = "%s/%s" % [biome, s.kind]
		kinds[k] = kinds.get(k, 0) + 1
		if s.has("pos") and (s.pos as Vector3).distance_to(start) < 80.0:
			near[s.kind] = near.get(s.kind, 0) + 1
	print("ALL ", kinds)
	print("WITHIN 80 m OF START ", near)
	quit()
