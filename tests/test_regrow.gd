extends TestCase
## F106: chopped roots grow back after a while, so a cave never runs out of rootwood.


func test_roots_grow_back() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var glow := GlowField.new()
	root.add_child(glow)
	glow.build(GlowPlacer.place(world.maker))
	var drops := Node3D.new()
	root.add_child(drops)
	var auth := GameAuthority.new()
	auth.world = world
	auth.glow = glow
	auth.drops_root = drops
	root.add_child(auth)
	var spot := {}
	for s in glow._spots.values():
		if s.kind == GlowPlacer.ROOT_DANGLE or s.kind == GlowPlacer.ROOT:
			spot = s
			break
	check(not spot.is_empty(), "the cave has roots")
	if spot.is_empty():
		root.queue_free()
		return
	var id: int = spot.id
	auth._host_remove_glow(spot)
	check(glow.get_spot(id).is_empty(), "the root is gone")
	auth._tick_regrow(GameAuthority.REGROW_TIME * 0.5)
	check(glow.get_spot(id).is_empty(), "not back after 5 minutes")
	# Its floor may have been dug away by the test world's carving; only check when the rock is there.
	var still_rock := world.sdf_at(spot.pos - spot.normal * 0.4) < 0.0
	auth._tick_regrow(GameAuthority.REGROW_TIME * 0.6)
	if still_rock:
		check(not glow.get_spot(id).is_empty(), "back after 10 minutes")
		check(not auth.removed_glow.has(id), "and no longer counted as removed (saves, friends joining)")
	root.queue_free()


## F337 (Nov 28): the lights' fast search (coarse glow grid) finds exactly the glowing spots the old full search found,
## also after one is removed and grows back.
func test_glow_light_search_matches_the_full_search() -> void:
	var g := GlowField.new()
	var kinds := ["crystal", "glowcap", "fiber", "twig", "firecap", "hollowcap"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 400:
		var s := {id = i, kind = kinds[i % kinds.size()], pos = Vector3(rng.randf_range(-120, 120), rng.randf_range(-40, 40), rng.randf_range(-120, 120))}
		g._spots[i] = s
		g._grid_add(s)
	g.remove_spot(0)  # a crystal mined
	g.remove_spot(1)  # a glowcap picked
	for p in [Vector3.ZERO, Vector3(60, 10, -50), Vector3(-119, -30, 119)]:
		var old := g.spots_near(p, GlowField.LIGHT_REACH).filter(func(s): return GlowPlacer.KINDS[s.kind].get("glow", false)).map(func(s): return s.id)
		var fast := g.glow_spots_near(p, GlowField.LIGHT_REACH).map(func(s): return s.id)
		old.sort()
		fast.sort()
		check(old.size() > 10, "the search finds some glowing spots (%d)" % old.size())
		check_eq(fast, old, "same glowing spots near %s" % p)
		check(not fast.has(0) and not fast.has(1), "removed spots are gone")
	g.free()
