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

## F189 (owner, Nov 17): giant root pillars stand in some big caverns, floor to ceiling, never on kept-clear ground,
## in a stone column or on a place.
func test_root_pillars() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var total := 0
	for sd in [42, 7]:
		var m := CaveMaker.new(sd)
		var ps := RootPillars.plan(m)
		total += ps.size()
		for p in ps:
			var mid: Vector3 = (p.top as Vector3).lerp(p.bottom, 0.5)
			check(not m.is_reserved(mid, 1.0) and not m._in_column(mid, 0.5), "seed %d: a pillar on clear ground" % sd)
			check((p.top as Vector3).y - (p.bottom as Vector3).y >= 5.0, "seed %d: floor to ceiling" % sd)
	check(total >= 4, "some big caverns have root pillars (%d in 2 worlds)" % total)
	CaveMaker.use_layout(was)

## F190 (owner, Nov 18): puddles under the water drips and in low spots, only on flat floor, never on kept-clear ground.
func test_puddles() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var ps := CaveWater.plan_puddles(m, GlowPlacer.place(m))
	check(ps.size() >= 5, "some puddles (%d)" % ps.size())
	for p in ps:
		check(not m.is_reserved(p.pos, 0.5), "a puddle on clear ground")
	CaveMaker.use_layout(was)


## Boulders (owner, Nov 18): breakable rocks around the caves, never on kept-clear ground, bridges, columns or places.
func test_boulders_keep_clear() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var bs := Boulders.plan(m)
	check(bs.size() >= 120, "plenty of boulders around the caves (%d)" % bs.size())
	var shapes := {}
	for b in bs:
		shapes[b.model] = true
		check(not m.is_reserved(b.pos, 1.5) and not m.on_bridge(b.pos, 1.0) and not m._in_column(b.pos, 1.0), "a boulder on clear ground")
		for q in m.pois:
			check((q.pos as Vector3).distance_to(b.pos) >= 2.5, "a boulder not inside a place")
	check(shapes.size() >= 12, "several shapes and stone looks (%d)" % shapes.size())
	CaveMaker.use_layout(was)


## Mushroom grass (owner, Nov 18): over most of the first cave's floor, never on kept-clear ground, bridges, columns
## or paths.
func test_mushroom_grass_keeps_clear() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var t0 := Time.get_ticks_msec()
	var ts := MushroomGrass.plan(m)
	check(ts.size() >= 3000, "lots of tufts in the first cave (%d)" % ts.size())
	check(Time.get_ticks_msec() - t0 < 30000, "planned in under 30 s (%d ms)" % (Time.get_ticks_msec() - t0))
	var bad := 0
	for t in ts:
		if m.is_reserved(t.pos, 0.8) or m.on_bridge(t.pos, 0.4) or m._in_column(t.pos, 0.4):
			bad += 1
	check_eq(bad, 0, "none on kept-clear ground, bridges or columns")
	CaveMaker.use_layout(was)


## Nothing inside a Root Tree (owner, Nov 18: "dripstone spawns in the tree and drips water inside the tree").
func test_nothing_grows_inside_root_trees() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var trees := RootPillars.plan(m)
	check(not trees.is_empty(), "there are trees")
	var inside := func(p: Vector3, spread: float) -> bool:
		for t in trees:
			if p.y > (t.bottom as Vector3).y - 1.0 and p.y < (t.top as Vector3).y + 1.0 and Vector2(p.x - t.top.x, p.z - t.top.z).length() < float(t.width) * spread:
				return true
		return false
	var cl := Clutter.new()
	var plan: Dictionary = cl._plan(m)
	var bad := 0
	for k in cl._drips:
		for it in cl._drips[k]:
			if inside.call((it[0] as Transform3D).origin, 0.74):
				bad += 1
	for k in plan.picks:
		for xf: Transform3D in plan.picks[k]:
			if inside.call(xf.origin, 0.49):
				bad += 1
	check_eq(bad, 0, "no dripstone or pebbles inside a tree")
	var drips := 0
	for s in GlowPlacer.place(m):
		if s.kind == GlowPlacer.DRIP and not s.get("hidden", false) and inside.call(s.pos, 0.74):
			drips += 1
	check_eq(drips, 0, "no water dripping inside a tree")
	cl.free()
	CaveMaker.use_layout(was)
