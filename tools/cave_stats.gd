extends SceneTree
## Cave numbers and timings, without opening the game (F211 step 1).
##   godot --headless --path . --script res://tools/cave_stats.gd -- seed=42 layout=2
## Prints: rooms and tunnels per area, how long planning and crystal placing take, and how long the
## terrain takes to build one 16 m block near caves (the game builds hundreds of these as you walk).


func _init() -> void:
	var seed := 42
	var layout := CaveMaker.LAYOUT_LATEST
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seed="):
			seed = a.trim_prefix("seed=").to_int()
		elif a.begins_with("layout="):
			layout = a.trim_prefix("layout=").to_int()
	CaveMaker.use_layout(layout)
	var t0 := Time.get_ticks_msec()
	var m := CaveMaker.new(seed)
	var t_plan := Time.get_ticks_msec() - t0
	if "fingerprint=1" in OS.get_cmdline_user_args():
		print(fingerprint(m))
		quit()
		return
	var per := {}
	for r in m.rooms:
		var b: String = r.get("biome", "mossy")
		if not per.has(b):
			per[b] = {big = 0, rooms = 0, kinds = {}}
		per[b].rooms += 1
		if r.big:
			per[b].big += 1
		var shape: String = CaveMaker.SHAPE_NAMES[int(r.get("shape", 0))]
		per[b].kinds[shape] = per[b].kinds.get(shape, 0) + 1
	var seg_kinds := {}
	for s in m.segments:
		var k := int(s.get("k", 0))
		seg_kinds[k] = seg_kinds.get(k, 0) + 1
	print("layout %d seed %d: plan %d ms, %d rooms, %d tunnel pieces %s, %d places" % [layout, seed, t_plan, m.rooms.size(), m.segments.size(), seg_kinds, m.pois.size()])
	for b in per:
		print("  %s: %d rooms (%d big) shapes %s" % [b, per[b].rooms, per[b].big, per[b].kinds])
	t0 = Time.get_ticks_msec()
	var spots := GlowPlacer.place(m)
	print("  crystals etc: %d spots in %d ms" % [spots.size(), Time.get_ticks_msec() - t0])
	# Terrain: build blocks around the spawn and in a few caverns.
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	var centers: Array[Vector3] = [m.spawn_point]
	for r in m.rooms:
		if r.big and centers.size() < 5:
			centers.append(r.center)
	var n := 0
	t0 = Time.get_ticks_usec()
	for c in centers:
		for dx in [-16, 0, 16]:
			for dz in [-16, 0, 16]:
				var o := Vector3i((Vector3(c) + Vector3(dx, -8, dz)).snapped(Vector3.ONE * 16) )
				o = Vector3i(o.x - posmod(o.x, 16), o.y - posmod(o.y, 16), o.z - posmod(o.z, 16))
				m.generate_block(buf, o)
				n += 1
	print("  terrain: %.1f ms per block near caves (%d blocks)" % [(Time.get_ticks_usec() - t0) / 1000.0 / n, n])
	# How many shapes each block near caves has to look at.
	var counts := [0, 0, 0]
	for c in centers:
		var cell = m._grid.get(Vector3i((Vector3(c) / 16.0).floor()))
		if cell != null:
			counts[0] += cell[0].size()
			counts[1] += cell[1].size()
			counts[2] += 1
	if counts[2] > 0:
		print("  shapes near a cave block: %.1f rooms, %.1f tunnel pieces" % [counts[0] / float(counts[2]), counts[1] / float(counts[2])])
	if "bench=1" in OS.get_cmdline_user_args():
		_bench(m, centers)
	quit()


## The same spots measured with the new shape math and with the old (all tubes and domes).
static func _bench(m: CaveMaker, centers: Array[Vector3]) -> void:
	var pts := PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for c in centers:
		for i in 4000:
			pts.append(c + Vector3(rng.randf_range(-24, 24), rng.randf_range(-12, 12), rng.randf_range(-24, 24)))
	var keep := m.made_layout
	for pass_layout in [keep, 1]:
		m.made_layout = pass_layout
		var t := Time.get_ticks_usec()
		for p in pts:
			m._smooth_at(p)
		print("  layout %d math: %.2f us per spot" % [pass_layout, float(Time.get_ticks_usec() - t) / pts.size()])
	m.made_layout = keep
	# Parts of the new math.
	var t := Time.get_ticks_usec()
	for p in pts:
		m._wall_bumps(p)
	print("  wall bumps: %.2f us" % (float(Time.get_ticks_usec() - t) / pts.size()))
	t = Time.get_ticks_usec()
	for p in pts:
		m._rock_detail(p)
	print("  rock detail: %.2f us" % (float(Time.get_ticks_usec() - t) / pts.size()))


## A short summary of a cave that changes if anything about it changes (tests compare it).
static func fingerprint(m: CaveMaker) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var sum := 0.0
	for i in 400:
		var r: Dictionary = m.rooms[rng.randi_range(0, m.rooms.size() - 1)]
		var p: Vector3 = r.center + Vector3(rng.randf_range(-30, 30), rng.randf_range(-12, 12), rng.randf_range(-30, 30))
		sum += m.sdf_at(p) * float(1 + i % 7)
	return "rooms=%d segs=%d pois=%d r0=%s sum=%.4f" % [m.rooms.size(), m.segments.size(), m.pois.size(), str(m.rooms[0].center), sum]
