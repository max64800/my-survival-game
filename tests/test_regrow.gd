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
	# Its ceiling may have been dug away by the test world's carving; only check when the rock is there.
	var still_rock := world.sdf_at(spot.pos - spot.normal * 0.4) < 0.0
	auth._tick_regrow(GameAuthority.REGROW_TIME * 0.6)
	if still_rock:
		check(not glow.get_spot(id).is_empty(), "back after 10 minutes")
		check(not auth.removed_glow.has(id), "and no longer counted as removed (saves, friends joining)")
	root.queue_free()
