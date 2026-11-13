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
	player.global_position = world.maker.spawn_point
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
	var copper := 0
	for b in auth.storage.boxes.values():
		copper += b.inv.count_of("copper_ingot")
	check(copper >= 2 * world.maker.pois_of("ruin").size(), "ruins hold copper ingots")
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
