extends SceneTree
## Writes one zone's cave plan (rooms, tunnels, places) as JSON for the 3D map page (tools/cave_map/map.html).
##   godot --headless --path . -s res://tools/cave_map/export_zone.gd -- seed=42 out=<file.json> [biome=mossy]
func _init() -> void:
	var sd := 42
	var out := "user://zone.json"
	var biome := "mossy"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seed="): sd = a.trim_prefix("seed=").to_int()
		elif a.begins_with("out="): out = a.trim_prefix("out=")
		elif a.begins_with("biome="): biome = a.trim_prefix("biome=")
	var m := CaveMaker.new(sd)
	var r2 := func(v: Vector3) -> Array: return [snappedf(v.x, 0.1), snappedf(v.y, 0.1), snappedf(v.z, 0.1)]
	var rooms := []
	for r in m.rooms:
		if r.get("biome", "mossy") != biome:
			continue
		rooms.append({c = r2.call(r.center), r = r2.call(r.radii), big = r.big, kind = r.get("kind", "room"),
			shape = CaveMaker.SHAPE_NAMES[int(r.get("shape", 0))], sealed = r.get("sealed", false),
			prop = CaveMaker.PROP_NAMES[int(r.get("prop", 0))], lobe = r.has("lobe_of"), cliff = r.has("cliff")})
	var segs := []
	for s in m.segments:
		if CaveMaker.biome_at((s.a + s.b) * 0.5) != biome:
			continue
		segs.append({a = r2.call(s.a), b = r2.call(s.b), r = snappedf(s.r, 0.1), k = int(s.get("k", 0)),
			h = snappedf(float(s.get("h", 0.0)), 0.1), ramp = s.get("ramp", false), ledge = s.get("ledge", false)})
	var pois := []
	for p in m.pois:
		if p.biome == biome:
			pois.append({t = p.type, p = r2.call(p.pos)})
	var data := {seed = sd, layout = m.made_layout, biome = biome, half = CaveMaker.HALF_SIZE,
		cx = CaveMaker.BIOMES[0 if biome == "mossy" else 1].cx, spawn = r2.call(m.spawn_point),
		y_min = CaveMaker.Y_MIN, y_max = CaveMaker.Y_MAX, rooms = rooms, segs = segs, pois = pois}
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	print("zone: %d rooms, %d tunnel pieces, %d places -> %s" % [rooms.size(), segs.size(), pois.size(), out])
	quit()
