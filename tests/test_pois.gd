extends TestCase
## Special places: rune shrines, ruin loot, carving runes.

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_shrine_gives_one_rune() -> void:
	await _setup()
	var shrine: Dictionary = world.maker.pois_of("shrine")[0]
	player.global_position = shrine.pos + shrine.normal * 1.5
	check_eq(auth.request_poi(1, shrine.id), "rune", "took the rune")
	var runes := 0
	for s in ps.inventory.slots:
		if not s.is_empty() and s.id.begins_with("rune_"):
			runes += s.count
	check_eq(runes, 1, "one rune in the bag")
	check_eq(auth.request_poi(1, shrine.id), "empty", "shrine is empty now")
	_teardown()


func test_ruin_and_camp_chests_have_loot() -> void:
	await _setup()
	auth.seed_poi_loot()
	var expect := world.maker.pois_of("ruin").size() + world.maker.pois_of("camp").size()
	check_eq(auth.storage.boxes.size(), expect, "one chest per ruin and camp")
	# Mossy Hollows: rare finds only, no free building materials (owner, Nov 15, F102).
	var pages := 0
	var free_stuff := 0
	for b in auth.storage.boxes.values():
		pages += b.inv.count_of("blueprint_page") + b.inv.count_of("recipe_page")
		for m in ["copper_ingot", "crystal_blue", "stone", "plank_root", "cut_stone", "clay_brick"]:
			free_stuff += b.inv.count_of(m)
	check(pages >= world.maker.pois_of("ruin", "mossy").size(), "Mossy ruins and camps hold old pages")
	check_eq(free_stuff, 0, "no free copper, crystals or building materials in Mossy chests")
	var silver := 0
	for b in auth.storage.boxes.values():
		silver += b.inv.count_of("silver_ingot")
	check(silver >= world.maker.pois_of("ruin", "fungal").size(), "Jungle ruins hold silver ingots")
	_teardown()


func test_carving_runes_at_the_slab() -> void:
	await _setup()
	ps.inventory.add("rune_verdant_m1", 2)
	check_eq(auth.request_carve(1, "rune_verdant_m1"), "no_slab", "need to stand at a Rune Slab")
	auth._ev_place_station(3, "rune_slab", player.global_position + Vector3(1.5, 0, 0), 0.0)
	check_eq(auth.request_carve(1, "rune_verdant_m1"), "carved", "carved")
	check(auth.rune_slab.taught_recipes().has("dish_glow_broth"), "it teaches Glow Broth")
	check_eq(auth.request_carve(1, "rune_verdant_m1"), "shard", "the second one becomes a shard")
	check_eq(auth.rune_slab.shards.verdant, 1, "1 verdant shard")
	_teardown()


## Owner (Nov 19): the ruins' columns "are still floating sometimes, and you cannot destroy them; you should be able to
## destroy them just for some stone".
func test_ruin_columns_break_for_stone() -> void:
	await _setup()
	var pf := PoiField.new()
	auth.get_parent().add_child(pf)
	pf.build(world.maker)
	auth.poi_field = pf
	check(pf._columns.size() > 0, "the ruins have columns")
	var cid: int = pf._columns.keys()[0]
	var c := pf.column(cid)
	player.global_position = pf.column_middle(cid) + Vector3(float(c.width) + 0.8, -1.0, 0)
	ps.inventory.slots[0] = {id = "pickaxe_stone", count = 1}
	if not ps.inventory.is_worn(0):
		ps.inventory.toggle_equip(0)  # a pickaxe works once it's put on (worn in place)
	ps.selected_slot = 0
	var stone_before := _stone_on_floor()
	var last := ""
	for i in int(c.hits):
		last = auth.request_hit_column(1, cid)
	check_eq(last, "broke", "it crumbles after %d hits" % c.hits)
	check_eq(_stone_on_floor() - stone_before, int(c.hits) * 2 + 3, "2 stone a hit with a pickaxe, 3 more at the end")
	check(auth.world_state.columns.has(cid), "remembered (saved, sent to friends)")
	check_eq(auth.request_hit_column(1, cid), "", "a broken column can't be hit again")
	await frames(2)
	check(pf.column(cid).is_empty(), "gone from the world")
	_teardown()


func _stone_on_floor() -> int:
	var n := 0
	for d in auth._drops.values():
		if d.item_id == "stone":
			n += d.count
	return n


func test_ruin_column_sits_on_the_real_floor() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var pf := PoiField.new()
	root.add_child(pf)
	var place := Node3D.new()
	pf.add_child(place)
	place.global_position = Vector3(300, 50, 300)
	var rng := RandomNumberGenerator.new()
	pf._col(place, {id = 7}, 0, Vector3.ZERO, 4.0, 0.7, 0.5, rng)
	var floor := StaticBody3D.new()
	floor.collision_layer = World.TERRAIN_LAYER
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 1, 10)
	cs.shape = box
	floor.add_child(cs)
	root.add_child(floor)
	floor.global_position = Vector3(300, 48.6, 300)  # its top is 0.9 m below the column: it was floating
	await tree.physics_frame
	await tree.physics_frame
	var cid := 7 * PoiField.COLS_PER_POI
	pf._settle_column(cid)
	var y: float = (pf.column(cid).node as Node3D).global_position.y
	check_near(y, 49.05, 0.03, "it drops onto the floor (and sinks in 5 cm)")
	root.free()


## F878 (owner, Nov 25): "some stone columns float in the air" (a row of them hanging over a drop). Every ruin column
## stands with its whole base on the rock: the floor under its middle and round its edge is close below it.
func test_columns_stand_on_rock() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var cols := 0
	var hanging := []
	for s in [42, 7, 1234]:
		var m := CaveMaker.new(s)
		var field := PoiField.new()
		tree.root.add_child(field)
		field.build(m)
		for cid in field._columns:
			var c: Dictionary = field._columns[cid]
			var at: Vector3 = (c.node as Node3D).global_position
			cols += 1
			for k in 5:
				var p := at
				if k > 0:
					var a := k * TAU / 4.0 + 0.4
					p += Vector3(cos(a), 0.0, sin(a)) * float(c.width) * 0.55
				var gap := p.y - m.find_floor(p.x, p.z, p.y + 0.5).y
				if gap > 1.0:
					hanging.append("seed %d column %d: %.1f m over the floor" % [s, cid, gap])
					break
		field.free()
	check(cols >= 10, "there are ruin columns (%d)" % cols)
	check_eq(hanging.size(), 0, "none hanging over a drop %s" % str(hanging.slice(0, 6)))
	CaveMaker.use_layout(was)


## F968 (owner, Nov 28): "some of its stone blocks can be walked through" (the broken block wall by the glowing pool).
## Every block of a broken wall, standing or fallen, has a solid box exactly where you see it.
func test_broken_wall_blocks_are_solid() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	root.global_position = Vector3(300, 50, 300)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var body := RuinKit.broken_wall(root, Vector3(-2.5, 0, 0), Vector3(2.5, 0, 0), 3, rng)
	var blocks := 0
	for c in root.get_children():
		if c is MeshInstance3D:
			blocks += 1
	check(blocks > 4, "the wall has blocks")
	check_eq(body.get_child_count(), blocks, "every block has its own solid box")
	check(body.collision_layer & World.TERRAIN_LAYER != 0, "you bump into it like rock")
	await tree.physics_frame
	await tree.physics_frame
	# A ray along the bottom row hits the wall from the side.
	var q := PhysicsRayQueryParameters3D.create(Vector3(300, 50.25, 303), Vector3(300, 50.25, 297), World.TERRAIN_LAYER)
	var hit := root.get_world_3d().direct_space_state.intersect_ray(q)
	check(not hit.is_empty() and hit.collider == body, "walking into the wall stops at the blocks")
	root.free()
