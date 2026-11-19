extends TestCase
## Glow groves (owner, Nov 19): 1-2 big caverns per biome hold a forest of glowing and dark trees, never the first
## cave. The owner's placement rule: no tree on kept-clear ground, a bridge, a stone column, a place, a path, a Root
## Tree or another tree.


func test_groves_per_biome() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var total := 0
	for sd in [42, 7, 1234]:
		var m := CaveMaker.new(sd)
		var gs := GlowGroves.plan(m, RootPillars.new().near)
		var per := {}
		for g in gs:
			check(g.room != 0, "seed %d: no grove in the first cave" % sd)
			per[g.biome] = int(per.get(g.biome, 0)) + 1
			var glow: int = g.trees.filter(func(t): return t.glow).size()
			check(glow >= 3 and g.trees.size() >= 6, "seed %d: a grove is a small forest (%d trees, %d glowing)" % [sd, g.trees.size(), glow])
		for b in per:
			check(per[b] <= 2, "seed %d: at most 2 groves in %s (%d)" % [sd, b, per[b]])
		total += gs.size()
	check(total >= 3, "groves turn up across worlds (%d in 3)" % total)
	CaveMaker.use_layout(was)


func test_grove_trees_keep_clear() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	for sd in [42, 7]:
		var m := CaveMaker.new(sd)
		var roots := RootPillars.plan(m)
		var all: Array = []
		for g in GlowGroves.plan(m):
			all.append_array(g.trees)
		for t in all:
			var p: Vector3 = t.pos
			check(not m.is_reserved(p, 1.0) and not m._in_column(p, 0.5) and not m.on_bridge(p, 0.5), "seed %d: a grove tree on clear ground" % sd)
			for q in m.pois:
				check(Vector2(q.pos.x - p.x, q.pos.z - p.z).length() >= 3.0, "seed %d: a grove tree not inside a place" % sd)
			for o in all:
				if o != t:
					check(Vector2(o.pos.x - p.x, o.pos.z - p.z).length() >= 2.0, "seed %d: grove trees not inside each other" % sd)
	CaveMaker.use_layout(was)


func test_grove_models_exist() -> void:
	for n in GlowGroves.GLOW + GlowGroves.DARK:
		check(ResourceLoader.exists("res://assets/models/cave/%s.glb" % n), "%s has its model" % n)


func test_trees_come_in_very_different_sizes() -> void:
	# Owner, Nov 19: "some big, some very tiny, like a bush the size of the dwarf. Obviously they give different
	# amounts of wood."
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var all: Array = []
	for sd in [42, 7, 1234]:
		for g in GlowGroves.plan(CaveMaker.new(sd), RootPillars.new().near):
			all.append_array(g.trees)
	var bushes: Array = all.filter(func(t): return float(t.scale) * GlowGroves.MODEL_HEIGHT < 2.1)
	var big: Array = all.filter(func(t): return float(t.scale) * GlowGroves.MODEL_HEIGHT > 5.0)
	check(bushes.size() >= 3, "bush-sized trees about as tall as a dwarf (%d of %d)" % [bushes.size(), all.size()])
	check(big.size() >= 3, "big trees too (%d of %d)" % [big.size(), all.size()])
	var ids := {}
	for t in all:
		ids[t.id] = true
	check(GlowGroves.wood_for(0.2) < 8 and GlowGroves.wood_for(1.2) > 30, "a bush gives a few wood, a big tree a lot")
	for t in bushes + big:
		check_eq(int(t.wood), GlowGroves.wood_for(float(t.scale)), "wood follows the tree's size")
		break
	CaveMaker.use_layout(was)


func test_chop_a_grove_tree_down_and_it_grows_back() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var auth := GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	root.add_child(auth)
	var groves := GlowGroves.new()
	root.add_child(groves)
	groves.build(world.maker)
	auth.groves = groves
	var player := Node3D.new()
	root.add_child(player)
	var ps := auth.add_player(1, player)
	var small := {}
	for t in groves._trees:
		if small.is_empty() or int(t.wood) < int(small.wood):
			small = t
	check(not small.is_empty(), "seed 42 has grove trees")
	if small.is_empty():
		root.queue_free()
		return
	player.global_position = (small.pos as Vector3) + Vector3(1.2, 0.2, 0)
	var id: int = small.id
	for i in int(small.wood) + 3:
		auth.request_chop_grove(1, id)
	check_eq(int(auth.grove_chops[id]), int(small.wood), "a tree gives exactly its own wood (%d), no more" % small.wood)
	check(not (groves._nodes[id][0] as Node3D).visible, "used up: it comes down")
	check(auth.grove_regrow.has(id), "and starts growing back")
	auth._tick_trees(GlowGroves.REGROW_TIME + 1.0)
	check((groves._nodes[id][0] as Node3D).visible and not auth.grove_chops.has(id), "after a while it stands again")
	root.queue_free()


## Owner, Nov 19 (pictures of the round scaly grove rocks): "we don't need that boulder, it doesn't look good".
func test_no_big_rocks_in_groves() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var bits := 0
	for sd in [42, 7]:
		for g in GlowGroves.plan(CaveMaker.new(sd)):
			for d in g.dressing:
				check(not (d.model in GlowGroves.ROCKS), "seed %d: no big grove rock (%s)" % [sd, d.model])
				bits += 1
	check(bits > 20, "the groves still have their pebbles and plants (%d)" % bits)
	CaveMaker.use_layout(was)


## Owner, Nov 19 (F383): "the new trees should have different colors, not just blue". Across a few worlds the groves
## use several colours, and a grove with enough glowing trees shows two.
func test_groves_glow_in_several_colours() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var mains := {}
	var mixed := 0
	for sd in [42, 7, 215187, 1234]:
		for g in GlowGroves.plan(CaveMaker.new(sd)):
			mains[g.colour] = true
			var cols := {}
			for t in g.trees:
				if t.glow:
					cols[t.colour] = true
			if cols.size() >= 2:
				mixed += 1
	check(mains.size() >= 3, "groves pick different main colours (%d seen)" % mains.size())
	check(mixed >= 2, "groves mix two colours (%d did)" % mixed)
	CaveMaker.use_layout(was)
