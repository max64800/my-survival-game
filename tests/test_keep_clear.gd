extends TestCase
## The owner's placement rule (Nov 17): nothing the world grows stands inside something built. The ruined
## watchtower's ground is kept clear of crystals, plants, pebbles, dripstone, hanging roots and the old columns.


func test_tower_ground_is_kept_clear() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	for sd in [42, 7]:
		var m := CaveMaker.new(sd)
		check_eq(m.reserved.size(), 2, "seed %d: the tower's and the Fallen Outpost's ground are kept clear" % sd)
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
	# Not on crystals (owner, Nov 19: mushroom grass grew on a crystal)
	var on_crystal := 0
	for g in GlowPlacer.place(m):
		if String(g.kind).begins_with("crystal"):
			for t in ts:
				if (t.pos as Vector3).distance_to(g.pos) < 0.6:
					on_crystal += 1
	check_eq(on_crystal, 0, "no mushroom grass on a crystal")
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


## Little waterfalls (owner, Nov 19): water down a cave wall into a pool, never over paths, places, bridges, trees or
## ground kept clear for built things; the first cave gets two.
func test_waterfalls_keep_clear() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var falls := CaveWater.plan_falls(m)
	check(falls.size() >= 8, "waterfalls around the caves (%d)" % falls.size())
	var c0: Vector3 = m.rooms[0].center
	var first := 0
	for f in falls:
		var pts: PackedVector3Array = f.pts
		check(pts[0].y - (f.pool as Vector3).y >= 1.4, "at least 1.5 m of falling water")
		check(not m.is_reserved(f.pool, 1.0) and not m.on_bridge(f.pool, 1.0), "its pool on clear ground")
		var stuck := 0
		for q in pts:
			if m.sdf_at(q) <= 0.0:
				stuck += 1
		check_eq(stuck, 0, "the water runs in the air, along the rock, never inside it")
		if Vector2(pts[0].x - c0.x, pts[0].z - c0.z).length() < maxf(m.rooms[0].radii.x, m.rooms[0].radii.z) * 1.3:
			first += 1
	check(first >= 1, "the first cave has a waterfall (%d)" % first)
	CaveMaker.use_layout(was)


## No little root, twig or fiber grows over a crystal (owner, Nov 19).
func test_no_roots_on_crystals() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var spots := GlowPlacer.place(m)
	var crystals := spots.filter(func(s): return String(s.kind).begins_with("crystal") and not s.get("hidden", false))
	var bad := 0
	for s in spots:
		if s.get("hidden", false) or not s.kind in ["root", "root_dangle", "twig", "fiber"]:
			continue
		for c in crystals:
			if (c.pos as Vector3).distance_to(s.pos) < 0.6 + 0.6 * float(c.get("scale", 1.0)):
				bad += 1
	check_eq(bad, 0, "no root, twig or fiber on a crystal")
	CaveMaker.use_layout(was)


## Rune shrines stand on their alcove's floor (owner, Nov 19: "all the time they're spawning in mid-air").
func test_rune_shrines_stand_on_the_floor() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var field := PoiField.new()
	tree.root.add_child(field)
	field.build(m)
	var shrines := 0
	var floating := 0
	for p in m.pois:
		if p.type != "shrine" or not field._nodes.has(p.id):
			continue
		shrines += 1
		var at: Vector3 = (field._nodes[p.id] as Node3D).global_position
		if at.y - m.find_floor(at.x, at.z, at.y + 0.5).y > 0.3:
			floating += 1
	check(shrines >= 3, "there are rune shrines (%d)" % shrines)
	check_eq(floating, 0, "none floating")
	field.queue_free()
	CaveMaker.use_layout(was)


## Owner, Nov 19 (seen by the glow-groves Claude in seed 42): mushrooms and grass grew through a ruin's loot chest.
## Nothing the cave grows shows on a storage box's ground: ruin and camp loot chests, the ruins' treasure, and boxes
## players put down (they all send World.ground_taken, like here).
func test_clutter_keeps_clear_of_boxes() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var m := CaveMaker.new(42)
	var taken := RuinTreasure.keep_clear(m)
	check(taken.size() >= 10, "the ruins and camps have chests and treasure (%d)" % taken.size())
	# A box a player puts down, in the middle of the first cave's mushroom grass.
	var first: Vector3 = m.rooms[0].center
	taken.append({pos = m.find_floor(first.x + 2.0, first.z + 1.0, first.y + 2.0), r = 0.75})
	var on := func(p: Vector3, z: Dictionary) -> bool:
		return Vector2(p.x - z.pos.x, p.z - z.pos.z).length() < float(z.r) and absf(p.y - (z.pos as Vector3).y) < 0.6
	# Planned before anything is built: boulders and glowing mushrooms keep off.
	var bad := 0
	for b in Boulders.plan(m):
		for z in taken:
			if not b.get("gone", false) and Vector2(b.pos.x - z.pos.x, b.pos.z - z.pos.z).length() < float(z.r) + 0.6 * float(b.scale) and absf(b.pos.y - z.pos.y) < 3.0:
				bad += 1
	check_eq(bad, 0, "no boulder on a chest or treasure")
	bad = 0
	var spots := GlowPlacer.place(m)
	for s in spots:
		for z in taken:
			if not s.get("hidden", false) and (s.pos as Vector3).distance_to(z.pos) < float(z.r) + 0.3:
				bad += 1
	check_eq(bad, 0, "no glowing mushroom or crystal on a chest or treasure")
	# Put down in a game: plants, pebbles and mushroom grass make room.
	var w := World.new()
	var snap := GroundSnap.new()
	snap.world = w
	var had: GroundSnap = GroundSnap.instance
	GroundSnap.instance = snap
	var life := CaveLife.new()
	life.build(m, spots, w)
	var cl := Clutter.new()
	cl.build(m, w, true)
	var grass := MushroomGrass.new()
	for i in MushroomGrass.MODELS.size():  # (looks only: the test needs where the tufts are, not their models)
		grass._meshes.append(null)
		grass._mats.append(null)
	w.ground_taken.connect(grass.clear_ground)
	grass._finish(MushroomGrass.plan(m))
	var count_on := func() -> Array:
		var n := [0, 0, 0]
		for z in taken:
			for c in life._cells.values():
				for kind in c:
					for p in (c[kind].where as PackedVector3Array):
						if on.call(p, z):
							n[0] += 1
			for kind in cl._where:
				for p in (cl._where[kind] as PackedVector3Array):
					if on.call(p, z):
						n[1] += 1
			for pt in grass._patches.values():
				for list in pt.xforms:
					for xf: Transform3D in list:
						if on.call(xf.origin, z):
							n[2] += 1
		return n
	var before: Array = count_on.call()
	check(before[0] + before[1] + before[2] > 0, "before: things grow there (plants %d, pebbles %d, mushroom grass %d)" % before)
	for z in taken:
		GroundSnap.take(z.pos, z.r)
	var after: Array = count_on.call()
	check_eq(after, [0, 0, 0], "after: no plants, pebbles or mushroom grass on a chest or treasure [plants, pebbles, grass]")
	GroundSnap.instance = had
	life.free()
	cl.free()
	grass.free()
	snap.free()
	w.free()
	CaveMaker.use_layout(was)
