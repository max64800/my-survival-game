extends TestCase


func test_same_seed_same_spots() -> void:
	var a := GlowPlacer.place(CaveMaker.new(5))
	var b := GlowPlacer.place(CaveMaker.new(5))
	check_eq(a.size(), b.size(), "same number of glow spots")
	if a.size() == b.size() and a.size() > 0:
		check_eq(a[a.size() / 2].pos, b[b.size() / 2].pos, "same spot position")


func test_enough_of_every_kind() -> void:
	var t := Time.get_ticks_msec()
	var spots := GlowPlacer.place(CaveMaker.new(12))
	var counts := {}
	for s in spots:
		counts[s.kind] = counts.get(s.kind, 0) + 1
	print("        (%d spots in %d ms) %s" % [spots.size(), Time.get_ticks_msec() - t, counts])
	check(spots.size() >= 100, "at least 100 spots (got %d)" % spots.size())
	check(counts.get("crystal", 0) >= 30, "crystals on walls")
	check(counts.get("glowcap", 0) >= 15, "glowcaps on floors")
	check(counts.get("root", 0) >= 8, "enough hanging roots for wood (got %d)" % counts.get("root", 0))
	check(counts.get("fiber", 0) >= 5, "fiber for rope")
	check(counts.get("hollowcap", 0) >= 5, "hollowcaps for stew")


func test_roots_hang_within_reach() -> void:
	var maker := CaveMaker.new(12)
	for s in GlowPlacer.place(maker):
		if s.kind != GlowPlacer.ROOT:
			continue
		var tip: Vector3 = s.pos + s.normal * s.length
		var floor_p := GlowPlacer._march(maker, tip, Vector3.DOWN, 40.0)
		if floor_p != Vector3.INF:
			check(tip.distance_to(floor_p) < 4.0, "root %d tip is %.1f m above the floor" % [s.id, tip.distance_to(floor_p)])


func test_jungle_grows_its_own_things() -> void:
	var maker := CaveMaker.new(12)
	var kinds := {}
	for s in GlowPlacer.place(maker):
		var b := CaveMaker.biome_at(s.pos)
		kinds[b + ":" + s.kind] = kinds.get(b + ":" + s.kind, 0) + 1
		if s.kind == GlowPlacer.GIANT:
			check(s.length >= 2.5 and maker.sdf_at(s.pos + Vector3.UP * (s.length + 0.8)) > 0.0, "giant mushroom fits under the ceiling")
	check(kinds.get("fungal:giant_mushroom", 0) >= 15, "plenty of giant mushrooms (wood) in the Jungle: %d" % kinds.get("fungal:giant_mushroom", 0))
	check(kinds.get("fungal:crystal_amber", 0) >= 10, "amber crystals in the Jungle")
	check(kinds.get("fungal:spore_truffle", 0) >= 10, "truffles in the Jungle")
	check_eq(kinds.get("mossy:giant_mushroom", 0), 0, "no giant mushrooms in Mossy")
	check_eq(kinds.get("fungal:root", 0), 0, "no hanging roots in the Jungle")


func test_spots_sit_on_rock_surface() -> void:
	var maker := CaveMaker.new(12)
	var spots := GlowPlacer.place(maker)
	for s in spots.slice(0, 50):
		var outside := maker.sdf_at(s.pos + s.normal * 0.8)
		var inside := maker.sdf_at(s.pos - s.normal * 0.8)
		check(outside > 0.0 and inside < 0.0, "spot %d should be on the wall (air %.2f / rock %.2f)" % [s.id, outside, inside])


func test_ids_are_unique_and_spaced() -> void:
	var spots := GlowPlacer.place(CaveMaker.new(3))
	var ids := {}
	for s in spots:
		ids[s.id] = true
	check_eq(ids.size(), spots.size(), "unique ids")
