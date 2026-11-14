extends TestCase
## The new start (feedback F10, F11, F12): a small sealed room, a soft wall, a tunnel to the
## first cavern; waking with nothing; making a pickaxe and a lantern by hand; refilling the lantern.


func test_every_cave_gets_a_start_room() -> void:
	for s in [1, 7, 42, 99, 1234, 2024]:
		var c := CaveMaker.new(s)
		check(not c.start.is_empty(), "seed %d: a start room was found" % s)
		if c.start.is_empty():
			continue
		check(c.sdf_at(c.spawn_point) > 0.0, "seed %d: you wake up in open air" % s)
		check(c.spawn_point.distance_to(c.start.room_c) < 4.0, "seed %d: ...inside the small room" % s)
		check(c.find_floor(c.spawn_point.x, c.spawn_point.z, c.spawn_point.y).y > c.spawn_point.y - 2.0, "seed %d: with a floor under you" % s)
		var lair := c.lair_poi()
		if not lair.is_empty():
			check(lair.pos.distance_to(c.spawn_point) >= 145.0, "seed %d: boss lair far from the start" % s)


func test_room_is_sealed_by_a_soft_dirt_wall() -> void:
	var c := CaveMaker.new(42)
	var st := c.start
	var u: Vector3 = st.dir
	var mid: Vector3 = ((st.plug_a as Vector3) + (st.plug_b as Vector3)) * 0.5
	var at := Vector3(mid.x, st.floor_y + 1.0, mid.z)
	check(c.sdf_at(at) < 0.0, "the wall is solid")
	check(c.material_at(Vector3i(at.round())) == Mat.DIRT, "the wall is dirt (1 hit)")
	# Walk a straight line from the room to the cavern: only the wall should be rock.
	var rock := 0.0
	var a := Vector3(st.room_c.x, st.floor_y + 1.0, st.room_c.z)
	var end: Vector3 = st.tunnel[0].a
	for i in 60:
		var p := a.lerp(end + u * 2.0, i / 60.0)
		if c.sdf_at(p) < 0.0:
			rock += (a.distance_to(end) + 2.0) / 60.0
	check(rock > 1.0 and rock < 4.0, "only a thin wall between the room and the tunnel (%.1f m of rock)" % rock)
	# The tunnel itself is open all the way into the cavern.
	var closed := 0
	for seg in st.tunnel:
		for i in 10:
			var p: Vector3 = (seg.a as Vector3).lerp(seg.b, i / 10.0)
			if c.sdf_at(p) <= 0.0:
				closed += 1
	check(closed == 0, "the tunnel is open all the way (%d blocked points)" % closed)


func test_start_room_has_roots_mushrooms_and_a_glow_behind_the_wall() -> void:
	var c := CaveMaker.new(42)
	var spots := GlowPlacer.place(c)
	var roots := 0
	var caps := 0
	var tunnel_crystals := 0
	var a0: Vector3 = c.start.tunnel[0].a
	for s in spots:
		if s.pos.distance_to(c.start.room_c) < 5.0:
			if s.kind == GlowPlacer.ROOT_DANGLE:
				roots += 1
			elif s.kind == GlowPlacer.MUSHROOM:
				caps += 1
		if s.kind == GlowPlacer.CRYSTAL and s.pos.distance_to(a0) < 4.5:
			tunnel_crystals += 1
	check(roots >= 2, "roots to pull by hand (%d)" % roots)
	check(caps >= 1, "a glowing mushroom so it isn't pitch black (%d)" % caps)
	check(tunnel_crystals >= 2, "crystals glowing just past the wall (%d)" % tunnel_crystals)
	check(GlowPlacer.KINDS[GlowPlacer.ROOT_DANGLE].tool == "hand", "the start roots need no tool")


func test_reachable_crystals_in_every_big_cavern() -> void:
	var c := CaveMaker.new(42)
	var spots := GlowPlacer.place(c)
	for room in c.rooms:
		if not room.big or room.get("sealed", false):
			continue
		var low := 0
		for s in spots:
			if not String(s.kind).begins_with("crystal") or s.pos.distance_to(room.center) > maxf(room.radii.x, room.radii.z) + 4.0:
				continue
			var fl := c.find_floor(s.pos.x + s.normal.x * 0.8, s.pos.z + s.normal.z * 0.8, s.pos.y + 0.5)
			if s.pos.y - fl.y < 2.4:
				low += 1
		check(low >= 3, "cavern at %s has crystals you can reach from the floor (%d)" % [room.center.round(), low])


func test_first_tools_by_hand_from_the_room() -> void:
	var p := Recipes.get_recipe("pickaxe_stone")
	var l := Recipes.get_recipe("lantern")
	check(p.station == Recipes.HAND and l.station == Recipes.HAND, "pickaxe and lantern are made by hand")
	check(p.unlock.is_empty() and l.unlock.is_empty(), "known from the start")
	# The room holds 6 rocks, 3 roots and 1 crystal: enough for both (3+2 rocks, 2+1 roots, 1 crystal).
	var inv := Inventory.new()
	inv.add("stone", 6)
	inv.add("rootwood", 3)
	inv.add("crystal_blue", 1)
	check(Crafting.craft(inv, "pickaxe_stone"), "made a stone pickaxe")
	check(Crafting.craft(inv, "lantern"), "made a lantern")
	check(inv.count_of("pickaxe_stone") == 1 and inv.count_of("lantern") == 1, "both are in the bag")


func test_waking_with_nothing_and_the_lantern_rules() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = root
	root.add_child(auth)
	auth.start_with_nothing = true
	var node := Node3D.new()
	root.add_child(node)
	var ps := auth.add_player(auth.local_peer_id(), node)
	var things := 0
	for i in Inventory.SIZE:
		things += int(ps.inventory.get_slot(i).get("count", 0))
	check(things == 0, "the bag starts empty")
	check(not Lantern.has_lantern(ps), "no lantern yet")
	var fuel := ps.fuel
	await frames(10)
	check(ps.fuel == fuel, "no lantern = no fuel burning")
	check(not auth.request_refill(auth.local_peer_id()), "can't refill a lantern you don't have")
	ps.inventory.add("lantern", 1)
	check(Lantern.has_lantern(ps), "made one: now you have a lantern")
	ps.fuel = 100.0
	check(not auth.request_refill(auth.local_peer_id()), "nothing to burn yet")
	ps.inventory.add("rootwood", 1)
	check(auth.request_refill(auth.local_peer_id()), "rootwood works as lantern fuel")
	check(ps.fuel > 100.0, "fuel went up")
	auth.spawn_start_items()
	await frames(2)
	var loose := 0
	for d in root.get_children():
		if d is Drop:
			loose += 1
	check(loose == 7, "6 rocks and 1 crystal lie in the room (%d)" % loose)
	root.queue_free()
