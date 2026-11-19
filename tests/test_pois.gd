extends TestCase
## Special places: boss clues, rune shrines, ruin loot, carving runes.

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


func test_clue_circles_point_at_the_lair() -> void:
	for s in [1, 42, 99]:
		var c := CaveMaker.new(s)
		var circles := c.clue_circles()
		check_eq(circles.size(), 3, "3 circles")
		var lair := Vector2(c.lair_poi().pos.x, c.lair_poi().pos.z)
		check(lair.distance_to(circles[0][0]) <= 120.0, "seed %d: lair inside the big circle" % s)
		check(lair.distance_to(circles[1][0]) <= 45.0, "seed %d: lair inside the small circle" % s)
		check(circles[1][0].distance_to(circles[0][0]) + 45.0 <= 120.01, "seed %d: small circle inside the big one" % s)
		check(lair.distance_to(circles[0][0]) > 1.0, "seed %d: lair is not at the middle of the big circle" % s)


func test_reading_markings() -> void:
	await _setup()
	var marks := world.maker.pois_of("marking")
	player.global_position = marks[0].pos + marks[0].normal * 1.5
	check_eq(auth.request_poi(1, marks[0].id), "clue", "first marking read")
	check_eq(auth.request_poi(1, marks[0].id), "already", "can't count it twice")
	check_eq(auth.world_state.clues.size(), 1, "1 clue")
	check(ps.progress.xp >= 100, "100 XP for a discovery")
	check_eq(auth.request_poi(1, marks[1].id), "too_far", "must walk to the next one")
	_teardown()


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
