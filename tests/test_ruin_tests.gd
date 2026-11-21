extends TestCase
## The dev "Ruins" test worlds (owner, Nov 21; RuinTests): every ruin's cave is made, the ruin's spot is set in it on
## flat open ground, you arrive in the open in front of it, and test layouts never clash with real or dungeon ones.


func test_every_ruin_test_cave_holds_its_ruin() -> void:
	var seen := {}
	for e in RuinTests.LIST:
		var lay := int(e.layout)
		check(not seen.has(lay) and not CaveMaker.DUNGEON_TESTS.has(lay) and lay > CaveMaker.LAYOUT_LATEST,
			"%s: its own test layout (%d)" % [e.key, lay])
		seen[lay] = true
		CaveMaker.use_layout(lay)
		check(CaveMaker.layout == lay, "%s: the layout is kept (not clamped to a real one)" % e.key)
		var m := CaveMaker.new(42)
		var spot: Dictionary = m.get(String(e.key) + "_spot")
		check(spot is Dictionary and not spot.is_empty(), "%s: its spot is set in the test cave" % e.key)
		if not spot is Dictionary or spot.is_empty():
			continue
		var base: Vector3 = spot.pos
		# Flat ground round its middle (the dome's floor), and open air above it.
		for k in 8:
			var a := k * TAU / 8.0
			var q := m.find_floor(base.x + cos(a) * 4.0, base.z + sin(a) * 4.0, base.y + 4.0)
			check(q.y >= base.y - 0.1 and q.y < base.y + 2.5, "%s: fairly flat ground, never below its base, 4 m from its middle (%.1f vs %.1f)" % [e.key, q.y, base.y])
		check(m.sdf_at(base + Vector3.UP * 3.0) > 0.0, "%s: open air over its middle" % e.key)
		# You arrive on open ground in front of its door (+z).
		check(m.spawn_point.z > base.z + 6.0, "%s: you arrive in front of it" % e.key)
		check(m.sdf_at(m.spawn_point + Vector3.UP * 0.5) > 0.0, "%s: you arrive in open air" % e.key)
		check(RuinTests.of_layout(lay) == e and RuinTests.of_key(String(e.key)) == e, "%s: found by layout and key" % e.key)
	check(RuinTests.of_layout(CaveMaker.LAYOUT_DEFAULT).is_empty(), "a real world is never a ruin test world")
	CaveMaker.use_layout(CaveMaker.LAYOUT_DEFAULT)
