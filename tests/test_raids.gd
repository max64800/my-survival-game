extends TestCase
## Raids on your base (combat doc 8.6).

var world: World
var auth: GameAuthority
var player: Node3D


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
	auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func _base() -> void:
	auth._ev_place_station(1, "bed", player.global_position + Vector3(2, 0, 0), 0.0)
	auth._ev_place_station(2, "workbench", player.global_position + Vector3(-2, 0, 0), 0.0)


func test_no_raid_without_a_source() -> void:
	await _setup()
	_base()
	check_eq(auth.raids.try_start(), "", "no side-boss cavern found: no raids")
	_teardown()


func test_no_raid_when_nobody_is_home() -> void:
	await _setup()
	_base()
	auth.world_state.lairs_found.append("skerra")
	auth.raids.clock = 99999.0
	player.global_position += Vector3(100, 0, 0)
	check_eq(auth.raids.try_start(), "", "nobody home: no raid")
	_teardown()


func test_raid_comes_and_can_be_beaten() -> void:
	await _setup()
	_base()
	auth.world_state.lairs_found.append("skerra")
	auth.raids.clock = 99999.0
	auth.raids._found_at.skerra = 0.0
	check(auth.raids.sources().has("skerra"), "Skerra sends raids")
	check_eq(auth.raids.try_start(), "skerra", "raid starts")
	auth.raids.clock = auth.raids.active.arrive_at + 0.1
	auth.raids._run_active()
	var n: int = auth.raids.active.uids.size()
	check_eq(n, 7, "Elder + 4 Mossnippers + 2 Skitterlings (doc 8.6)")
	for u in auth.raids.active.uids:
		auth.monsters._ev_remove(u)
	auth.raids._run_active()
	check(auth.raids.active.is_empty(), "raid over when all raiders are beaten")
	var shards := 0
	for c in auth.rune_slab.shards:
		shards += auth.rune_slab.shards[c]
	check_eq(shards, 1, "a rune shard for the player")
	_teardown()


func test_killing_bosses_stops_raids() -> void:
	await _setup()
	auth.world_state.lairs_found.append("skerra")
	auth.world_state.lairs_found.append("brask")
	auth.raids.clock = 99999.0
	auth.raids._found_at = {skerra = 0.0, brask = 0.0}
	auth.world_state.bosses_dead.append("skerra")
	check_eq(auth.raids.sources(), ["brask"], "Skerra dead: only Brask raids")
	auth.world_state.bosses_dead.append("orrumhal")
	check(auth.raids.sources().is_empty(), "main boss dead: no raids at all")
	# Each biome's main boss only stops its own biome's raids.
	auth.world_state.lairs_found.append("sivix")
	auth.raids._found_at.sivix = 0.0
	check_eq(auth.raids.sources(), ["sivix"], "Orrumhal's death doesn't stop Sivix")
	auth.world_state.bosses_dead.append("thallus")
	check(auth.raids.sources().is_empty(), "Thallus dead: the Jungle goes quiet too")
	_teardown()
