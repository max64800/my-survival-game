extends TestCase
## The owner's cave-floor notes of Nov 19: F404 (a calmer floor), F405 (Root Trees in the starting cave),
## F406 (crystals grow back), F407 (the glowing swarms never fly into the ground).

static var _world: World


func _maker() -> CaveMaker:
	if _world == null:
		_world = World.new()
		tree.root.add_child(_world)
		_world.setup(42)
	return _world.maker


## F404: no moss blobs, no spiky grass; small roots only in the tunnels.
func test_floor_has_no_moss_grass_or_cave_roots() -> void:
	var m := _maker()
	var spots := GlowPlacer.place(m)
	var plants := CaveLife.plan(m, spots)
	var gone := 0
	var roots_in_caves := 0
	var ferns := 0
	for p in plants:
		if p.kind in CaveLife.GONE:
			gone += 1
		if String(p.kind).begins_with("rootlet") and CaveLife.in_cave(m, (p.xform as Transform3D).origin):
			roots_in_caves += 1
		if p.kind == "fern":
			ferns += 1
	check_eq(gone, 0, "no moss blobs or cave grass on the floors")
	check_eq(roots_in_caves, 0, "no small roots inside the caves")
	check(ferns > 0, "the little ferns stay (%d)" % ferns)
	check_eq(int(Clutter.KINDS.bone.weight), 0, "no more old bones")
	# F404 🔁: the glow groves had their own tall grass (among the orange mushrooms): none there either
	for g in GlowGroves.PLANTS:
		check(not String(g).contains("grass"), "the glow groves plant no grass (%s)" % g)


## F404: the wood roots stick out of the ground in the tunnels only, and there's as much wood as before.
func test_wood_roots_only_in_tunnels() -> void:
	var m := _maker()
	var in_caves := 0
	var shown := 0
	var hidden := 0
	for s in GlowPlacer.place(m):
		if s.kind != GlowPlacer.ROOT or s.get("bridge", false):  # (roots on the rock bridges are wanted: F413)
			continue
		if s.get("hidden", false):
			hidden += 1
			continue
		shown += 1
		if CaveLife.in_cave(m, s.pos):
			in_caves += 1
	check_eq(in_caves, 0, "no wood roots inside the caves")
	check(shown >= hidden * 0.7, "most of the wood moved to the tunnels (%d shown, %d left out)" % [shown, hidden])


## F414 + F415: pebbles only in the tunnels, spread across a wide tunnel (not in one line down its middle).
func test_pebbles_only_in_tunnels_and_spread() -> void:
	var m := _maker()
	var c := Clutter.new()
	var plan: Dictionary = c._plan(m)
	var in_caves := 0
	var pebbles: Array = plan.picks.pebble + plan.picks.rock
	for xf: Transform3D in pebbles:
		if CaveLife.in_cave(m, xf.origin):
			in_caves += 1
	check(pebbles.size() > 50, "still pebbles in the tunnels (%d)" % pebbles.size())
	check_eq(in_caves, 0, "no pebbles or small rocks in the caves")
	for g in GlowGroves.PLANTS + GlowGroves.ROCKS:
		check(not String(g).contains("pebble"), "no grove pebbles")
	# the widest tunnel: how far off its middle line do its pebbles lie? (before: all within ~1 m of it)
	var wide: Dictionary = {}
	for s: Dictionary in m.segments:
		if not s.get("ramp", false) and (wide.is_empty() or float(s.r) > float(wide.r)):
			wide = s
	var off_mid := 0
	var near_it := 0
	for xf: Transform3D in pebbles:
		var cp := Geometry3D.get_closest_point_to_segment(xf.origin, wide.a, wide.b)
		var d := Vector2(cp.x - xf.origin.x, cp.z - xf.origin.z).length()
		if d < float(wide.r):
			near_it += 1
			if d > float(wide.r) * 0.35:
				off_mid += 1
	check(near_it == 0 or off_mid * 3 >= near_it, "widest tunnel (r %.1f): %d of %d pebbles away from the middle line" % [float(wide.r), off_mid, near_it])
	c.free()


## F413: wood roots on the rock bridges, with room to walk past them.
func test_roots_on_bridges() -> void:
	var m := _maker()
	var on_bridges := 0
	for s in GlowPlacer.place(m):
		if s.get("bridge", false) and not s.get("hidden", false):
			on_bridges += 1
			check(m.on_bridge(s.pos, 0.5), "the root stands on a bridge")
			check(not m.is_reserved(s.pos, 1.0), "not on built ground")
	check(m._bridges.is_empty() or on_bridges > 0, "%d bridges carry %d roots" % [m._bridges.size(), on_bridges])


## F404: boulders, 1-2 per cave, by the walls.
func test_few_boulders_by_the_walls() -> void:
	var m := _maker()
	var rocks := Boulders.plan(m)
	var per_room := {}
	var open := 0
	for r in rocks:
		var p: Vector3 = r.pos + Vector3.UP * float(r.sink)
		var best := -1
		var best_d := INF
		for i in m.rooms.size():
			var rc: Vector3 = m.rooms[i].center
			var rr: Vector3 = m.rooms[i].radii
			var d := pow((p.x - rc.x) / rr.x, 2) + pow((p.z - rc.z) / rr.z, 2)  # (how far inside its oval)
			if d < best_d and absf(p.y - rc.y) < rr.y * 1.5 + 2.0:
				best_d = d
				best = i
		per_room[best] = per_room.get(best, 0) + 1
		if not Boulders.near_wall(m, p, 1.0 * float(r.scale) + 2.0):
			open += 1
	var most := 0
	for k in per_room:
		if k != 0:
			most = maxi(most, per_room[k])
	check(rocks.size() > 0, "there are still some boulders (%d)" % rocks.size())
	check(most <= 2, "at most 2 in a cave (most: %d)" % most)
	# F418: the starting cave gets a few more, out by its edges
	var first := int(per_room.get(0, 0))
	check(first >= 3 and first <= 2 + Boulders.START_EXTRA, "the starting cave has a few (%d)" % first)
	check(rocks.size() <= m.rooms.size() * 2 + Boulders.START_EXTRA, "far fewer than before (%d for %d caves)" % [rocks.size(), m.rooms.size()])
	check_eq(open, 0, "every boulder stands by a wall")


## F405: at least 2 big Root Trees in the starting cave, on two different worlds, none on kept-clear ground.
func test_starting_cave_has_two_root_trees() -> void:
	for sd in [42, 2024]:
		var w := World.new()
		tree.root.add_child(w)
		w.setup(sd)
		var m := w.maker
		var first: Dictionary = m.rooms[0]
		var n := 0
		for t in RootPillars.plan(m):
			var at: Vector3 = t.top
			var fc: Vector3 = first.center
			var fr: Vector3 = first.radii
			var dx := (at.x - fc.x) / fr.x
			var dz := (at.z - fc.z) / fr.z
			if dx * dx + dz * dz < 1.2:
				n += 1
				check(not m.is_reserved(Vector3(at.x, t.bottom.y, at.z), 0.5), "seed %d: a tree is not on the tower's ground" % sd)
		check(n >= 2, "seed %d: the starting cave has %d Root Trees (at least 2)" % [sd, n])
		w.queue_free()


## F406: a mined crystal grows back after about 90 minutes (the host counts, saved with the world).
func test_crystals_grow_back() -> void:
	var auth := GameAuthority.new()
	auth._start_regrow({id = 77, kind = "crystal"})
	auth._start_regrow({id = 78, kind = "crystal_blue"})
	auth._start_regrow({id = 79, kind = "glowcap"})
	check_eq(float(auth.regrow.get(77, 0.0)), 5400.0, "a crystal grows back after 90 minutes")
	check(auth.regrow.has(78), "every crystal colour grows back")
	check(not auth.regrow.has(79), "mushrooms are not changed by this")
	auth.free()


## F417: after loading, swarms are finished a few feelers a frame (never a whole swarm in one frame: that was 40-110 ms),
## the nearest first; far swarms wait until you come near.
func test_swarms_finish_a_little_each_frame() -> void:
	var m := _maker()
	var sw := GlowSwarms.new()
	tree.root.add_child(sw)
	sw.build(m)
	check(sw._swarms.size() > 2, "the caves have swarms (%d)" % sw._swarms.size())
	check(sw._swarms[0].done, "the first cave's swarm is ready at once")
	var far: Dictionary = sw._swarms[sw._swarms.size() - 1]
	var at: Vector3 = far.c
	var worst := 0.0
	for i in 400:
		var t := Time.get_ticks_usec()
		sw._finish_some(at)
		worst = maxf(worst, (Time.get_ticks_usec() - t) / 1000.0)
		if far.get("done", false):
			break
	check(far.get("done", false), "the swarm where you stand gets finished")
	check(worst < GlowSwarms.FINISH_BUDGET + 4.0, "never long in one frame (worst %.1f ms)" % worst)
	var waiting := 0
	for s2 in sw._swarms:
		if not s2.get("done", false) and (s2.c as Vector3).distance_to(at) > GlowSwarms.FINISH_NEAR:
			waiting += 1
	check(waiting > 0, "swarms far away wait until you come near")
	sw.free()


## F407: the swarm is lifted over the real floor when its path would dip into it.
func test_swarm_stays_above_the_floor() -> void:
	var m := _maker()
	var sw := GlowSwarms.new()
	sw._maker = m
	var c: Vector3 = m.rooms[0].center
	var fl := GlowPlacer._march(m, c, Vector3.DOWN, 40.0)
	check(fl != Vector3.INF, "found the first cave's floor")
	var d := {prev = fl + Vector3.DOWN * 0.5}
	var head := fl + Vector3.DOWN * 0.5  # a path point under the ground
	var got := head
	for i in 120:
		got = sw._above_floor(d, head, 1.0 / 60.0)
	check(got.y >= fl.y + GlowSwarms.FLOOR_GAP - 0.05, "lifted over the floor (%.2f over it)" % (got.y - fl.y))
	sw.free()


## F566 (owner, Nov 21: "I went through a tunnel and found none"): nearly every walking tunnel has wood roots,
## and none stand on built ground, paths or an old place's treasure (the placement rule).
func test_roots_in_nearly_every_tunnel() -> void:
	var m := _maker()
	var roots: Array = GlowPlacer.place(m).filter(func(s: Dictionary) -> bool:
		return s.kind == GlowPlacer.ROOT and not s.get("hidden", false) and not s.get("bridge", false))
	var tunnels: Array = GlowPlacer._root_tunnels(m).filter(func(sg: Dictionary) -> bool:
		return CaveMaker.biome_at(((sg.a as Vector3) + (sg.b as Vector3)) * 0.5) != "fungal")
	var near_root := 0  # tunnel pieces with a wood root within 15 m of their middle
	for sg in tunnels:
		var mid: Vector3 = ((sg.a as Vector3) + (sg.b as Vector3)) * 0.5
		if roots.any(func(r: Dictionary) -> bool: return (r.pos as Vector3).distance_to(mid) < 15.0):
			near_root += 1
	check(near_root >= tunnels.size() * 0.85, "walking a tunnel, a wood root is never far (%d of %d tunnel pieces)" % [near_root, tunnels.size()])
	check(roots.size() >= 700, "more than twice the wood roots of before (353): %d" % roots.size())
	var taken := RuinTreasure.keep_clear(m)
	for r in roots:
		check(not m.is_reserved(r.pos, 0.5), "no root on built ground or a path")
		for z in taken:
			check((r.pos as Vector3).distance_to(z.pos) >= float(z.r) + 0.5, "no root in an old place's treasure")
