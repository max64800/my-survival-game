extends TestCase
## The old worn dirt path (owner, Nov 25, F870 step 5): faint packed dirt from the start to every ruin and place.
## It never cuts through anything built, and nothing the world grows stands on it (the placement rule, like
## test_columns_keep_out_of_the_tower).


func _maker(sd: int) -> CaveMaker:
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	return CaveMaker.new(sd)


func test_trail_links_the_places() -> void:
	var was := CaveMaker.layout
	for sd in [42, 7]:
		var t0 := Time.get_ticks_msec()
		var m := _maker(sd)
		var t1 := Time.get_ticks_msec()
		var again := OldTrail.plan(m)
		print("TRAIL seed %d: %d spots, %d places, cave %d ms, path %d ms" % [sd, m.trail.size(), again.ends.size(), t1 - t0, Time.get_ticks_msec() - t1])
		check(m.trail.size() > 300, "seed %d: a long path (%d spots)" % [sd, m.trail.size()])
		check_eq(again.points, m.trail, "seed %d: the same path every time (no dice)" % sd)
		# Every ruin and place it leads to has path within 30 m of its edge.
		var far := 0
		for p: Dictionary in m.pois:
			if not OldTrail.TO_TYPES.has(p.type) or m.rooms[int(p.room)].get("sealed", false):
				continue
			if m.is_reserved(p.pos):
				continue  # (inside a ruin: the path stops at the ruin's edge, checked below)
			if not _path_near(m, p.pos, 30.0, 12.0):
				far += 1
				print("  no path near %s at %s" % [p.type, str(p.pos)])
		for z: Dictionary in m.reserved:
			if not _path_near(m, z.pos, float(z.r) + 12.0, 30.0):  # (ruins sit down in the cave's dips)
				far += 1
				print("  no path near built ground at %s (r %.1f)" % [str(z.pos), float(z.r)])
		check(far <= 2, "seed %d: the path reaches (nearly) every place (%d missed)" % [sd, far])
	CaveMaker.use_layout(was)


## The path never cuts through anything built (ruins, towers, dungeon doorways), never runs through a stone column
## and lies on the floor.
func test_trail_keeps_off_built_things() -> void:
	var was := CaveMaker.layout
	for sd in [42, 7, 1234]:
		var m := _maker(sd)
		var bad := 0
		var floating := 0
		for q in m.trail:
			if m.is_reserved(q, 1.0) or m._in_column(q, 1.0) or m.in_dungeon_stone(q):
				bad += 1
			if m.sdf_at(q + Vector3.UP * 0.5) <= 0.0 or m.sdf_at(q - Vector3.UP * 0.6) > 0.0:
				floating += 1
		check_eq(bad, 0, "seed %d: no path on built ground or in a column" % sd)
		check(floating < m.trail.size() / 50, "seed %d: the path lies on the floor (%d of %d off)" % [sd, floating, m.trail.size()])
		# Its floor is packed dirt.
		var dirt := 0
		for i in range(0, m.trail.size(), 7):
			var q: Vector3 = m.trail[i]
			for dy in [0, -1, 1]:
				if m.material_at(Vector3i(floori(q.x), floori(q.y) - 1 + dy, floori(q.z))) == Mat.PATH:
					dirt += 1
					break
		check(dirt > (m.trail.size() / 7) * 0.6, "seed %d: most of the path is packed dirt (%d of %d)" % [sd, dirt, m.trail.size() / 7])
	CaveMaker.use_layout(was)


## The placement rule (owner, Nov 17), like test_columns_keep_out_of_the_tower: crystals, roots, plants, moss,
## mushrooms, pebbles, boulders, root trees and glow groves never stand on the old path.
func test_nothing_grows_on_the_trail() -> void:
	var was := CaveMaker.layout
	for sd in [42, 7]:
		var m := _maker(sd)
		var spots := GlowPlacer.place(m)
		var bad := 0
		for s in spots:
			if m.on_trail(s.pos) and not s.get("hidden", false):
				bad += 1
		check_eq(bad, 0, "seed %d: no crystals or roots on the path" % sd)
		bad = 0
		for it in CaveLife.plan(m, spots):
			if m.on_trail((it.xform as Transform3D).origin):
				bad += 1
		check_eq(bad, 0, "seed %d: no moss, grass or mushrooms on the path" % sd)
		var cl := Clutter.new()
		var picks: Dictionary = cl._plan(m).picks
		bad = 0
		for k in picks:
			for xf: Transform3D in picks[k]:
				if m.on_trail(xf.origin):
					bad += 1
		check_eq(bad, 0, "seed %d: no pebbles or rocks on the path" % sd)
		cl.free()
		bad = 0
		for b in Boulders.plan(m):
			if m.on_trail(b.pos, 1.0):
				bad += 1
		check_eq(bad, 0, "seed %d: no boulders on the path" % sd)
		bad = 0
		for t in RootPillars.plan(m):
			if m.on_trail(t.bottom, 2.0):
				bad += 1
		check_eq(bad, 0, "seed %d: no root trees on the path" % sd)
		bad = 0
		for g in GlowGroves.plan(m):
			for tr: Dictionary in g.trees:
				if m.on_trail(tr.pos, 1.0):
					bad += 1
		check_eq(bad, 0, "seed %d: no glow groves on the path" % sd)
	CaveMaker.use_layout(was)


## Old stones, broken track and fallen torches lie along the path, never on built ground or in a column.
func test_trail_decor_along_the_path() -> void:
	var was := CaveMaker.layout
	var m := _maker(42)
	var items := TrailDecor.plan(m)
	var n := [0, 0, 0]
	var bad := 0
	for it in items:
		n[it.model] += 1
		var o: Vector3 = (it.xform as Transform3D).origin
		if m.is_reserved(o, 0.5) or m._in_column(o, 0.5) or not m.on_trail(o, 1.5):
			bad += 1
	print("TRAIL decor: %d stones, %d track, %d torches" % n)
	check(n[TrailDecor.STONES] > 100 and n[TrailDecor.RAIL] > 20 and n[TrailDecor.TORCH] > 10, "some of each (%s)" % str(n))
	check_eq(bad, 0, "all along the path, none on built ground")
	check_eq(TrailDecor.plan(m).size(), items.size(), "the same every time")
	CaveMaker.use_layout(was)


func _path_near(m: CaveMaker, p: Vector3, d: float, h: float) -> bool:
	for q in m.trail:
		if Vector2(q.x - p.x, q.z - p.z).length() < d and absf(q.y - p.y) < h:
			return true
	return false
