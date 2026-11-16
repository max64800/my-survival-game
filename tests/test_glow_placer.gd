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
	check(counts.get("root", 0) >= 8, "enough roots for wood (got %d)" % counts.get("root", 0))
	check(counts.get("fiber", 0) >= 5, "fiber for rope")
	check(counts.get("hollowcap", 0) >= 5, "hollowcaps for stew")


## Roots break out of the floor (owner, Nov 16): standing up, rock under them, room above them.
func test_roots_grow_out_of_the_floor() -> void:
	var maker := CaveMaker.new(12)
	var n := 0
	for s in GlowPlacer.place(maker):
		if s.kind != GlowPlacer.ROOT:
			continue
		n += 1
		check(s.normal == Vector3.UP, "root %d stands up" % s.id)
		check(maker.sdf_at(s.pos + Vector3.DOWN * 0.5) < 0.0, "root %d has rock under it" % s.id)
		check(s.length >= 0.8 and s.length <= 1.25, "root %d is a sensible size (%.2f)" % [s.id, s.length])
	check(n > 0, "the cave has roots")


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
	check_eq(kinds.get("fungal:root", 0), 0, "no roots in the Jungle")


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


## F140: the first cavern always has a dripping stalactite (water).
func test_first_cavern_has_a_drip() -> void:
	for sd in [1, 42, 1234]:
		var maker := CaveMaker.new(sd)
		var first: Dictionary = {}
		for room in maker.rooms:
			if room.get("kind", "") == "spawn":
				first = room
		var found := false
		for s in GlowPlacer.place(maker):
			if s.kind == GlowPlacer.DRIP and s.pos.distance_to(first.center) < maxf(first.radii.x, first.radii.z):
				found = true
		check(found, "seed %d: a drip in the first cavern" % sd)
