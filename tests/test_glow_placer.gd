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


## Ground things are sometimes bigger, never smaller (owner F218), the same on every computer.
func test_size_boost_only_grows() -> void:
	var big := 0
	var huge := 0
	for i in 2000:
		var p := Vector3(i * 0.37, sin(i) * 3.0, i * -0.21)
		var b := GlowPlacer.size_boost(p)
		check(b >= 1.0 and b <= 3.2, "boost %.2f is never smaller" % b)
		check_eq(b, GlowPlacer.size_boost(p), "same spot, same size")
		big += 1 if b > 1.2 else 0
		huge += 1 if b >= 1.9 else 0
	print("        (%d of 2000 bigger, %d a lot bigger)" % [big, huge])
	check(big > 400 and big < 900, "about 1 in 3 are bigger")
	check(huge > 60 and huge < 300, "about 1 in 12 are a lot bigger")


## Crystals and big roots are solid (owner F220), with the glow id so a swing still counts; mushrooms stay soft.
func test_crystals_and_roots_are_solid() -> void:
	var f := GlowField.new()
	f.build([
		{id = 1, pos = Vector3.ZERO, normal = Vector3.UP, kind = "crystal", color = Color.WHITE, scale = 1.0, spin = 0.0, length = 0.0},
		{id = 2, pos = Vector3(5, 0, 0), normal = Vector3.UP, kind = "root", color = Color.WHITE, scale = 1.0, spin = 0.0, length = 1.0},
		{id = 3, pos = Vector3(10, 0, 0), normal = Vector3.UP, kind = "glowcap", color = Color.WHITE, scale = 1.0, spin = 0.0, length = 0.0}])
	var solid := {}
	for b in f.find_children("*", "StaticBody3D", true, false):
		if b.collision_layer & World.TERRAIN_LAYER:
			solid[b.get_meta("glow_id")] = true
	check(solid.has(1), "a crystal is solid")
	check(solid.has(2), "a root is solid")
	check(not solid.has(3), "a little mushroom is not")
	f.free()


## Twigs on Mossy floors give wood and are picked by hand (E), like mushrooms and fiber (owner, Nov 17).
func test_twigs_on_mossy_floors() -> void:
	var c := CaveMaker.new(12)
	var twigs := 0
	for s in GlowPlacer.place(c):
		if s.kind != "twig":
			continue
		twigs += 1
		check(CaveMaker.biome_at(s.pos) == "mossy", "twig %d is in the Mossy Hollows" % s.id)
		check(s.normal.y >= 0.8, "twig %d lies on a floor" % s.id)
	check(twigs >= 30, "plenty of twigs (%d)" % twigs)
	check_eq(GlowPlacer.KINDS.twig.item, "rootwood", "a twig gives wood")
	check(GlowPlacer.is_plant("twig"), "picked by hand (E)")
