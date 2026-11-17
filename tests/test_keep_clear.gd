extends TestCase
## The owner's placement rule (Nov 17): nothing the world grows stands inside something built. The ruined
## watchtower's ground is kept clear of crystals, plants, pebbles, dripstone, hanging roots and the old columns.


func test_tower_ground_is_kept_clear() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	for sd in [42, 7]:
		var m := CaveMaker.new(sd)
		check_eq(m.reserved.size(), 1, "seed %d: the tower's ground is kept clear" % sd)
		var plan := RuinTower.load_plan()
		var spot := RuinTower.find_spot(m, float(plan.get("radius", 4.2)), float(plan.get("height", 9.0)))
		check(not spot.is_empty() and m.is_reserved(spot.pos + Vector3.UP), "seed %d: it's where the tower goes" % sd)
		var spots := GlowPlacer.place(m)
		var bad := 0
		for s in spots:
			if m.is_reserved(s.pos) and not s.get("hidden", false):
				bad += 1
		check_eq(bad, 0, "seed %d: no crystals or roots there" % sd)
		bad = 0
		for it in CaveLife.plan(m, spots):
			if m.is_reserved((it.xform as Transform3D).origin):
				bad += 1
		check_eq(bad, 0, "seed %d: no moss, grass or mushrooms there" % sd)
		var cl := Clutter.new()
		var picks: Dictionary = cl._plan(m).picks
		bad = 0
		for k in picks:
			for xf: Transform3D in picks[k]:
				if m.is_reserved(xf.origin):
					bad += 1
		for k in cl._drips:
			for it in cl._drips[k]:
				if m.is_reserved((it[0] as Transform3D).origin):
					bad += 1
		check_eq(bad, 0, "seed %d: no pebbles or dripstone there" % sd)
		cl.free()
	CaveMaker.use_layout(was)

## F189 (owner, Nov 17): root curtains hang across some tunnel mouths, from the ceiling to a little above the floor,
## and never on a built thing's ground.
func test_root_curtains() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var strands := RootCurtains.plan(m)
	check(strands.size() > 100, "a good number of strands (%d)" % strands.size())
	var bad := 0
	for it in strands:
		var xf: Transform3D = it[0]
		if m.is_reserved(xf.origin, 0.5):
			bad += 1
		var tip := xf.origin - xf.basis.y  # its free end (the mesh is 1 m, scaled)
		if m.sdf_at(tip) <= 0.0:
			bad += 1  # a free end stuck in the floor
	check_eq(bad, 0, "none on kept-clear ground, none stuck in the floor")
	CaveMaker.use_layout(was)
