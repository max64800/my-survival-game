extends TestCase
## The Twin Gate (owner, Nov 21-22, F479 + F656 + F657): the sixth ruin, a Stonehold gate built into the cave. Its plan,
## where it goes (and the placement rule: nothing the world grows stands inside it), the cave's shape round it (the
## rock wall, the moat, the lumps), and rebuilding it in stone.

var world: World
var auth: GameAuthority


func _setup(sd := 42) -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(sd)


func _inside(v: Vector3) -> bool:
	return v.x >= RuinTwinGate.LO.x and v.x <= RuinTwinGate.HI.x and v.z >= RuinTwinGate.LO.y and v.z <= RuinTwinGate.HI.y


func test_plan_is_whole() -> void:
	var plan := RuinTower.load_plan(RuinTwinGate.PLAN_PATH)
	check(not plan.is_empty(), "the Twin Gate's plan file loads")
	for p in plan.get("pieces", []):
		check(Pieces.allowed(p.id, p.mat), "%s can be made of %s" % [p.id, p.mat])
		var v := Vector3(p.pos[0], p.pos[1], p.pos[2])
		check(_inside(v) and v.y >= -0.1, "the ruin's %s at %s is inside the ground it keeps clear" % [p.id, v])
		check(Vector2(v.x, v.z).length() <= RuinTwinGate.REACH, "the ruin's %s at %s is within its reach" % [p.id, v])
		check(RuinTwinGate.dip_at(v.x, v.z) == 0.0, "the ruin's %s at %s is not in the moat" % [p.id, v])
	check(plan.get("chests", []).size() >= 3, "chests to find in it")
	for g: Vector2 in RuinTwinGate.ground():
		check(g.length() <= RuinTwinGate.REACH, "its ground at %s is within its reach" % g)
	var bp := BlueprintLibrary.make("stonehold_twin_gate")
	check(bp.size.x <= Blueprint.MAX_SIZE.x and bp.size.y <= Blueprint.MAX_SIZE.y and bp.size.z <= Blueprint.MAX_SIZE.z,
		"the blueprint fits the biggest size (%s)" % bp.size)
	check(bp.pieces.size() <= Blueprint.MAX_PIECES, "and has at most %d pieces (%d)" % [Blueprint.MAX_PIECES, bp.pieces.size()])
	check(bool(Blueprint.from_json(bp.to_json()).ok), "it saves and loads as a blueprint file")


## Nothing in the ruin falls when it is built.
func test_ruin_stands_up() -> void:
	var plan := RuinTower.load_plan(RuinTwinGate.PLAN_PATH)
	var s := Structure.new()
	var uid := 1
	for p in plan.pieces:
		if String(p.id) in RuinTower.RUBBLE:
			continue
		s.add(uid, p.id, p.mat, Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), float(p.pos[1]) < 0.3 or p.get("anchor", false))
		uid += 1
	var fell: Array = s.recompute()
	check_eq(fell.size(), 0, "no piece of the ruin falls")
	for f in fell.slice(0, 5):
		print("TWIN_FALLS %s" % [s.pieces[f] if s.pieces.has(f) else f])


func _whole_pieces(plan: Array) -> Array:
	return plan.filter(func(p): return not String(p.id).begins_with("ruin_") and not String(p.id) in RuinTower.RUBBLE \
		and not String(p.id) in Builder.RUIN_DEBRIS)


## The blueprint and the ruin line up piece for piece: nothing whole is torn down.
func test_blueprint_matches_its_ruin() -> void:
	var bp := BlueprintLibrary.make("stonehold_twin_gate")
	var plan := RuinTower.load_plan(RuinTwinGate.PLAN_PATH)
	var off := 0
	for q in _whole_pieces(plan.pieces):
		var qp := Vector3(q.pos[0], q.pos[1], q.pos[2])
		var found := false
		for p in bp.pieces:
			if p.id == q.id and int(p.rot) == int(q.rot) and (p.pos as Vector3).distance_to(qp) < 0.05:
				found = true
				break
		if not found:
			off += 1
			if off <= 3:
				check(false, "the ruin's %s at %s is in the blueprint" % [q.id, qp])
	check_eq(off, 0, "every whole piece of the ruin is in the blueprint")
	var wood := BlueprintLibrary.make("wooden_twin_gate")
	check(wood != null and wood.pieces.size() == bp.pieces.size(), "a Wooden Twin Gate blueprint, piece for piece")
	check(BlueprintLibrary.REBUILD_ONLY.has("wooden_twin_gate") and BlueprintLibrary.REBUILD_ONLY.has("stonehold_twin_gate"),
		"both learned only by rebuilding the ruin")
	for bx in bp.pieces:
		check(_inside(bx.pos), "the whole gate's %s at %s fits the ground the ruin keeps clear" % [bx.id, bx.pos])


## F657 (owner, Nov 22: "yes, add cave shapes"): a rock wall behind the barracks, a dry moat round the left tower, two
## rock lumps; none of it touches a piece, and the blueprint keeps all of that rock (it only digs round the gate
## itself, so rebuilding never flattens the cave).
func test_cave_shape() -> void:
	check(RuinTwinGate.wall_at(0.0, -24.0) > 6.0, "a rock wall behind the barracks (%.1f m)" % RuinTwinGate.wall_at(0.0, -24.0))
	check(RuinTwinGate.wall_at(-22.0, -12.0) > 4.0, "wrapped round the back left corner")
	check(RuinTwinGate.wall_at(25.0, -12.0) > 4.0, "and the back right corner")
	check_eq(RuinTwinGate.wall_at(0.0, 0.0), 0.0, "no wall in the yard")
	check(RuinTwinGate.dip_at(-22.0, 8.0) < -2.0, "a moat beside the left tower (%.1f)" % RuinTwinGate.dip_at(-22.0, 8.0))
	check(RuinTwinGate.dip_at(-16.0, 18.5) < -2.0, "and in front of it")
	check_eq(RuinTwinGate.dip_at(0.0, 18.0), 0.0, "no moat in front of the grand stair")
	for x in range(-9, 14):   # F714: no lump grows into the yard in front of the grand stair
		for z in range(15, 23):
			if RuinTwinGate.lump_at(x, z) > 0.0:
				check(false, "a rock lump in the front yard at (%d, %d)" % [x, z])
	for l in RuinTwinGate.LUMPS:
		var c: Vector3 = l[0]
		check(RuinTwinGate.lump_at(c.x, c.z) > c.y - 0.6, "a rock lump at %s" % c)
	var plan := RuinTower.load_plan(RuinTwinGate.PLAN_PATH)
	var bp := BlueprintLibrary.make("stonehold_twin_gate")
	var touching := 0
	var all: Array = []
	for p in bp.pieces:
		all.append([p.id, p.pos, p.rot])
	for p in plan.pieces:
		all.append([p.id, Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot)])
	for a in all:
		var b := Pieces.box(a[0], a[1], a[2]).grow(0.3)
		for c in [b.position, b.end, Vector3(b.position.x, 0, b.end.z), Vector3(b.end.x, 0, b.position.z), b.get_center()]:
			if a[1].y + 0.1 < RuinTwinGate.rock_at(c.x, c.z) or RuinTwinGate.dip_at(c.x, c.z) < -0.05:
				touching += 1
				if touching <= 3:
					print("TWIN_TOUCH %s at %s" % [a[0], a[1]])
	check_eq(touching, 0, "the rock and the moat never reach into the gate")
	var air := 0
	for v in bp.air:
		air += int(v)
	check(air < bp.air.size() * 0.75, "the blueprint only digs round the gate (%d of %d cells)" % [air, bp.air.size()])
	var pts := RuinTwinGate.carve_points(Vector3.ZERO, 0)
	var into := 0
	for c in pts:
		var r := RuinTwinGate.rock_at(c.x, c.z)
		if r > 0.05 and c.y - RuinTower.CARVE_RADIUS < r - 0.31:   # (no rock grown there: the moat digs below 0)
			into += 1
	check_eq(into, 0, "the ruin never digs into its lumps or wall")
	check(pts.size() > 1000, "it digs its space (%d digs)" % pts.size())


## Where it goes, on a few worlds: a big cavern of its own, a fair walk out, found quickly, and the placement rule
## (owner, Nov 17): no stone column inside it and its whole ground (the gate, the moat, the lumps, the yard) kept clear.
func test_spot_keeps_clear_of_what_the_world_grows() -> void:
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		var t0 := Time.get_ticks_msec()
		RuinTwinGate.pick(c)  # (only timed: its own spot is reserved now)
		var ms := Time.get_ticks_msec() - t0
		print("TWIN_PICK seed %d: %d ms" % [sd, ms])
		var spot: Dictionary = c.twin_gate_spot
		check(not spot.is_empty(), "seed %d: a cavern for the Twin Gate is found" % sd)
		if spot.is_empty():
			continue
		check(ms < 4000, "seed %d: finding the spot takes under 4 s (%d ms)" % [sd, ms])
		var taken := [RuinOutpost.pick_room(c), RuinBrewhall.pick_room(c), int(c.spire_spot.get("room", -1)),
			int(c.manor_spot.get("room", -1)), int(c.prow_hall_spot.get("room", -1))]
		check(not spot.room in taken, "seed %d: not another ruin's cavern" % sd)
		var d := Vector2(spot.pos.x - c.cavern_spawn.x, spot.pos.z - c.cavern_spawn.z).length()
		check(d > 80.0, "seed %d: a fair walk from the start (%.0f m)" % [sd, d])
		var basis := Basis(Vector3.UP, int(spot.turn) * PI / 2.0)
		var bad := 0
		for g: Vector2 in RuinTwinGate.ground():
			var at: Vector3 = spot.pos + basis * Vector3(g.x, 0.3, g.y)
			if c._in_column(at, 1.0) or not c.is_reserved(at):
				bad += 1
		check_eq(bad, 0, "seed %d: no column in the Twin Gate, all of its ground kept clear" % sd)
		if sd == 42:  # (a new world takes a few seconds: once is enough)
			check_eq(CaveMaker.new(sd).twin_gate_spot, spot, "seed %d: always the same spot" % sd)


## The dev menu's Ruins list has it (owner: "I want to spawn and see every ruin from that menu").
func test_in_the_ruins_test_menu() -> void:
	var e := RuinTests.of_key("twin_gate")
	check(not e.is_empty(), "the Ruins test list has the Twin Gate")
	check(LootProps.RUIN_PLANS.has("twin_gate"), "its props can be looted")


## A test world with the Twin Gate built (like the first time someone walks up to it). Returns its Rebuilding Chest.
func _build_twin() -> int:
	_setup()
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	auth.stations_root = Node3D.new()
	var root := world.get_parent()
	root.add_child(auth.drops_root)
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	me.global_position = world.maker.cavern_spawn
	auth.add_player(1, me)
	auth.world_state["twin_gate"] = "pending"
	RuinTower.last_rebuild_box = -1
	var job := RuinTwinGate.new(auth)
	auth.add_child(job)
	await tree.process_frame
	# Load its rock (the test world has no camera): its digging and the rock it grows need it.
	var eye := Node3D.new()
	root.add_child(eye)
	eye.global_position = job.origin + Vector3(0, 6, 0)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 72
	viewer.requires_visuals = false
	eye.add_child(viewer)
	for i in 4000:  # (slower in the full suite; the rock checks below tell if it never loaded)
		if world.is_ready_at(job.origin + Vector3(0, 6, 0), 36.0):
			break
		await tree.process_frame
	if not world.is_ready_at(job.origin + Vector3(0, 6, 0), 36.0):
		print("TWIN_TEST rock not fully loaded yet, going on")
	job._state = "carve"  # (no meshes in the test world: start digging now)
	for i in 8000:
		if not is_instance_valid(job) or job._state == "done":
			break
		await tree.process_frame
	return RuinTower.last_rebuild_box


func test_rebuild_the_twin_gate_in_stone() -> void:
	var box: int = await _build_twin()
	check(auth.storage.boxes.has(box) and auth.storage.boxes[box].kind == "rebuild", "the Twin Gate has a Rebuilding Chest")
	if not auth.storage.boxes.has(box):
		world.get_parent().queue_free()
		return
	var o := RuinTwinGate.built_origin
	var basis := Basis(Vector3.UP, RuinTwinGate.built_turn * PI / 2.0)
	# The cave's shape (F657): rock in the wall and the lumps, the moat dug, open air over the yard.
	var l1: Vector3 = RuinTwinGate.LUMPS[0][0]
	check(world.sdf_at(o + basis * Vector3(l1.x, l1.y - 1.0, l1.z)) < 0.0, "rock in the lump past the grand stair")
	check(world.sdf_at(o + basis * Vector3(0.0, 4.0, -24.0)) < 0.0, "rock in the wall behind the barracks")
	check(world.sdf_at(o + basis * Vector3(-22.0, -1.5, 8.0)) > 0.0, "the moat is dug beside the left tower")
	check(world.sdf_at(o + basis * Vector3(0.0, 2.5, 19.0)) > 0.0, "an open yard in front of the grand stair")
	# F714: the courtyards are level: no rock lump in the front yard, nothing poking up in the drill yard.
	for g in [Vector2(10.0, 19.5), Vector2(12.5, 20.0), Vector2(0.0, -1.0), Vector2(-8.0, 2.0), Vector2(8.0, -4.0)]:
		check(world.sdf_at(o + basis * Vector3(g.x, 0.7, g.y)) > 0.0, "level, open ground at %s" % g)
	var r: Dictionary = auth.world_state.ruins[str(box)]
	check_eq([r.wood, r.stone, r.get("mat", "")], ["wooden_twin_gate", "stonehold_twin_gate", "cut_stone"], "its chest rebuilds the Twin Gate")
	auth.storage.put(box, "cut_stone", 5)
	var b: Builder = auth.builder
	# F713/F626: a Twin Gate built before Nov 22 (with its old spiral stairs) gets straight ones when the world loads.
	var fix := RuinTwinGate.new(auth)
	fix.origin = o
	fix.turn = RuinTwinGate.built_turn
	fix.plan = RuinTower.load_plan(RuinTwinGate.PLAN_PATH)
	var at := o + basis * Vector3(-9, 5.5, 8)   # (the straight stairs stand on the floor; the old spiral sat on a slab)
	var srot := Pieces.add_rot(0, fix.turn)
	for u in b.structure.near(Pieces.box("stairs", at, srot)):
		if b.structure.pieces[u].piece == "stairs" and (b.structure.pieces[u].pos as Vector3).distance_to(at) < 0.05:
			b._ev_remove_piece(u)
	b._ev_add_piece(b._next_uid, "floor", "cut_stone", at, srot, false)
	b._ev_add_piece(b._next_uid, "stairs_spiral", "cut_stone", at + Vector3.UP * 0.25, srot, false)
	check(fix._swap_old_stairs() >= 1, "an old spiral stair is swapped for a straight one")
	var spirals := 0
	var straight := 0
	var slabs := 0
	for u in b.structure.near(Pieces.box("stairs", at, srot)):
		spirals += int(b.structure.pieces[u].piece == "stairs_spiral")
		slabs += int(b.structure.pieces[u].piece == "floor" and (b.structure.pieces[u].pos as Vector3).distance_to(at) < 0.05)
		straight += int(b.structure.pieces[u].piece == "stairs" and (b.structure.pieces[u].pos as Vector3).distance_to(at) < 0.05)
	check(spirals == 0 and straight == 1, "no spiral left, the straight stairs in (%d, %d)" % [spirals, straight])
	check_eq(slabs, 0, "and the slab the old spiral sat on is gone")
	fix.free()
	var ps: GameAuthority.PlayerState = auth.players[1]
	ps.inventory.add("build_hammer", 1)
	ps.selected_slot = ps.inventory.best_of_kind("hammer")
	ps.node.global_position = o + Vector3(0, 40, 0)   # (high over the gate: never standing where a piece goes)
	for k in 40000:
		if not b.sites.has(box):
			break
		if k % 25 == 0:
			var left := []
			for i in b.sites[box].plan.size():
				if not b.sites[box].plan[i].built:
					left.append(i)
			var short := Builder.missing_for(b.sites[box].plan, left, auth.storage.get_box(box).inv)
			for item in short:
				auth.storage.put(box, item, mini(int(short[item]), 400))
		b._site_ticks += 1
		b._tick_sites()
	if b.sites.has(box):  # (what holds it up, to fix)
		var inv := basis.inverse()
		var n := 0
		for p in b.sites[box].plan:
			if not p.built and n < 6:
				n += 1
				print("TWIN_STUCK %s %s at %s overlap=%s rock='%s'" % [p.piece, p.family, inv * (p.pos - o),
					b.structure.overlapping(p.piece, p.pos, p.rot).map(func(u): return "%s@%s" % [b.structure.pieces[u].piece, inv * (b.structure.pieces[u].pos - o)]), Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at)])
	check(not b.sites.has(box), "the rebuilding finished (%s)" % b.site_status(box))
	var known: Array = auth.world_state.get("blueprints", [])
	check(known.has("wooden_twin_gate") and known.has("stonehold_twin_gate"), "rebuilt in stone: you learn both blueprints")
	check(world.sdf_at(o + basis * Vector3(0.0, 4.0, -24.0)) < 0.0, "the rock wall is still there after rebuilding")
	check(world.sdf_at(o + basis * Vector3(l1.x, l1.y - 1.0, l1.z)) < 0.0, "and the lump")
	# The placement rule: every piece of the rebuilt gate stands on ground the world keeps clear.
	var outside := 0
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(o) < RuinTwinGate.REACH + 2.0 and not world.maker.is_reserved(q.pos + Vector3.UP * 0.1):
			outside += 1
			if outside <= 3:
				check(false, "the rebuilt %s at %s is on kept-clear ground" % [q.piece, q.pos - o])
	check_eq(outside, 0, "every piece of the rebuilt gate stands on ground the world keeps clear")
	world.get_parent().queue_free()


## F565 🔁 (owner, Nov 22: "even after I rebuild it, it's still at 7 FPS"): the wooden Twin Gate, rushed like the dev
## Ruins world, finishes (it stopped at 99%: the ruin's old stairs, still raised 25 cm on a slab, blocked the new ones
## that stand on the floor, so its first floor never finished and its collapsed walls were never cleared). A site that
## is stuck waits a second between tries instead of a whole strength check of every piece every frame (120 ms a frame).
func test_rebuild_the_twin_gate_in_wood_rushed_stays_fast() -> void:
	var box: int = await _build_twin()
	if not auth.storage.boxes.has(box):
		check(false, "the Twin Gate has a Rebuilding Chest")
		world.get_parent().queue_free()
		return
	var o := RuinTwinGate.built_origin
	var b: Builder = auth.builder
	b.instant_ruins = true
	auth.players[1].node.global_position = o + Vector3(0, 40, 0)   # (never standing where a piece goes)
	# Something in the way of one wall: the site gets stuck there.
	auth.storage.put(box, BlueprintLibrary.WOOD, 1)
	check(b.sites.has(box), "a wooden rebuild starts")
	var site: Dictionary = b.sites.get(box, {})
	var stuck_at := -1
	for i in site.get("plan", []).size():
		var p: Dictionary = site.plan[i]
		if not p.built and p.piece == "wall" and p.pos.y > o.y + 2.0 and Vector2(p.pos.x - o.x, p.pos.z - o.z).length() > 12.0:
			stuck_at = i
			break
	var blocker := -1
	if stuck_at >= 0:
		blocker = b._next_uid
		b._ev_add_piece(blocker, "wall", "cut_stone", site.plan[stuck_at].pos, site.plan[stuck_at].rot, true)
	var clock_at := b._clock
	for k in 200:
		if not b.sites.has(box) or site.has("rush_wait"):
			break
		b._rush(box, site, auth.storage.get_box(box))
	check(site.has("rush_wait"), "the rush stops where something is in the way")
	var t0 := Time.get_ticks_usec()
	for k in 30:  # (30 frames of a stuck site)
		b._rush(box, site, auth.storage.get_box(box))
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	check(ms < 30.0, "a stuck site costs nothing between its tries (30 frames: %.1f ms)" % ms)
	if blocker >= 0:
		b._ev_remove_piece(blocker)
	for k in 400:
		if not b.sites.has(box):
			break
		b._clock = clock_at + 2.0 * (k + 1)   # (a second has passed: it tries again)
		b._rush(box, site, auth.storage.get_box(box))
	if b.sites.has(box):
		var n := 0
		for p in site.plan:
			if not p.built and n < 6:
				n += 1
				print("TWIN_WOOD_STUCK %s %s at %s overlap=%s" % [p.piece, p.family, p.pos - o, b.structure.overlapping(p.piece, p.pos, p.rot).map(
					func(u): return "%s %s@%s" % [b.structure.pieces[u].piece, b.structure.pieces[u].family, b.structure.pieces[u].pos - o])])
	check(not b.sites.has(box), "the wooden rebuild finished, not stuck at 99%% (%s)" % b.site_status(box))
	# Nothing of the ruin left doubled under the new gate: no broken walls, no old raised stairs or their slabs.
	var plan_n := BlueprintLibrary.make("wooden_twin_gate").pieces.size()
	var near := 0
	var broken := 0
	var stairs_slabs := 0
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if (q.pos as Vector3).distance_to(o) > RuinTwinGate.REACH + 2.0:
			continue
		near += 1
		broken += int(String(q.piece).begins_with("ruin_"))
		if q.piece in ["stairs", "stairs_corner"]:
			for u2 in b.structure.near(Pieces.box(q.piece, q.pos, q.rot)):
				var f: Dictionary = b.structure.pieces[u2]
				stairs_slabs += int(f.piece == "stairs" and u2 != uid and (f.pos as Vector3).distance_to(q.pos) < 0.3)
				stairs_slabs += int(f.piece == "floor" and (f.pos as Vector3).distance_to(q.pos) < 0.05)
	check_eq(broken, 0, "no broken ruin wall left in the rebuilt gate")
	check_eq(stairs_slabs, 0, "no old raised stairs or their slabs left under the new ones")
	check(near <= plan_n + 5, "the rebuilt gate is its plan, not the ruin plus the plan (%d pieces, plan %d)" % [near, plan_n])
	world.get_parent().queue_free()


## F715 (owner, Nov 22: "I was trying to jump over them and I couldn't"): a worn or collapsed wall collides as its
## broken top, so where its stones are low (the gap) the dwarf can jump over it, and where they stand tall it stops him.
func test_broken_walls_collide_as_their_broken_top() -> void:
	for id in ["ruin_wall_worn", "ruin_wall_collapsed"]:
		for fam in ["cut_stone", "clay_brick"]:
			if PieceNode.forged_mesh(id, fam) == null:
				continue
			var n := PieceNode.new()
			n.piece = id
			n.family = fam
			tree.root.add_child(n)
			var lo := 99.0
			var hi := 0.0
			for c in n.get_children():
				if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
					var h: float = ((c as CollisionShape3D).shape as BoxShape3D).size.y
					lo = minf(lo, h)
					hi = maxf(hi, h)
			check(hi > 1.0, "%s (%s) still blocks where it stands tall (%.2f m)" % [id, fam, hi])
			# (the worn wall only lost its top course; the collapsed one has a real gap to jump over)
			var drop := 0.8 if id == "ruin_wall_collapsed" else 0.2
			if id == "ruin_wall_collapsed":
				check(lo < 1.2, "its gap is low enough to jump over (a jump is about 1.5 m; %.2f m)" % lo)
			check(lo < hi - drop, "%s (%s): its broken part is lower (%.2f m vs %.2f m)" % [id, fam, lo, hi])
			n.queue_free()
