extends TestCase


func test_same_seed_same_spots() -> void:
	var a := GlowPlacer.place(CaveMaker.new(5))
	var b := GlowPlacer.place(CaveMaker.new(5))
	check_eq(a.size(), b.size(), "same number of glow spots")
	if a.size() == b.size() and a.size() > 0:
		check_eq(a[a.size() / 2].pos, b[b.size() / 2].pos, "same spot position")


func test_enough_glow_and_both_kinds() -> void:
	var t := Time.get_ticks_msec()
	var spots := GlowPlacer.place(CaveMaker.new(12))
	print("        (%d glow spots in %d ms)" % [spots.size(), Time.get_ticks_msec() - t])
	check(spots.size() >= 100, "at least 100 glow spots (got %d)" % spots.size())
	var mush := spots.filter(func(s): return s.kind == GlowPlacer.MUSHROOM).size()
	var crys := spots.filter(func(s): return s.kind == GlowPlacer.CRYSTAL).size()
	check(mush >= 20, "mushrooms on floors (got %d)" % mush)
	check(crys >= 40, "crystals on walls (got %d)" % crys)


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
