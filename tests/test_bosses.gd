extends TestCase
## Bosses: phases, summons, drops, resets (combat doc 8).

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


func _boss(id: String) -> Monster:
	var uid: int = auth.monsters._next_uid
	auth.monsters._ev_spawn(uid, id, player.global_position + Vector3(3, 0, 0), false, 500)
	return auth.monsters.get_monster(uid)


func test_orrumhal_phases() -> void:
	await _setup()
	var b := _boss("orrumhal")
	check(b.is_boss(), "is a boss")
	check_eq(b.max_hp(), 2000.0, "2000 HP")
	check_eq(b.stats().armor, 30.0, "armor 30 at first")
	check(not b.attack_options().any(func(a): return a.id == "hall_quake"), "no Hall Quake in phase 1")
	b.hp = 1250.0
	var entered := b.check_phase()
	check_eq(b.phase, 1, "phase 2 at 62%")
	check_eq(entered.get("summon"), ["mossnipper", 4], "Mossnippers crawl out")
	b.hp = 500.0
	b.check_phase()
	check_eq(b.phase, 2, "phase 3 at 25%")
	check_eq(b.stats().armor, 0, "heartstone open: armor 0")
	var slam: Dictionary = b.attack_options().filter(func(a): return a.id == "fist_slam")[0]
	check_near(slam.tell, 1.1 * 0.85, 0.001, "tells are faster in phase 3")
	_teardown()


func test_phase_change_through_damage_summons() -> void:
	await _setup()
	ps.inventory.add("mace_2h_silver", 1)
	auth.request_select_slot(1, 1)
	var b := _boss("orrumhal")
	b.state = Monster.State.CHASE
	b.hp = 1310.0
	var before := auth.monsters.monsters.size()
	auth.monsters.request_attack(1, PackedInt32Array([b.uid]), true, 0, false)
	check_eq(b.phase, 1, "a big hit pushed it into phase 2")
	check_eq(auth.monsters.monsters.size(), before + 4, "4 Mossnippers appeared")
	_teardown()


func test_brood_call_can_be_interrupted() -> void:
	await _setup()
	var b := _boss("skerra")
	var call: Dictionary = b.attack_options().filter(func(a): return a.id == "brood_call")[0]
	b._start_attack(call, auth.monsters)
	b.stun.add(35.0)  # someone parried during the call
	b._timer = 0.0
	var before := auth.monsters.monsters.size()
	b.think(0.016, auth.monsters)
	check_eq(auth.monsters.monsters.size(), before, "interrupted: no brood")
	b._cooldowns.clear()
	b.stun = StunMeter.new(120, 4.0, true)
	b._start_attack(call, auth.monsters)
	b._timer = 0.0
	b.think(0.016, auth.monsters)
	check_eq(auth.monsters.monsters.size(), before + 4, "not interrupted: 4 Mossnippers")
	_teardown()


func test_boss_drops_go_to_everyone_nearby() -> void:
	await _setup()
	var b := _boss("orrumhal")
	auth.monsters._kill(b, 1)
	check_eq(ps.inventory.count_of("keeper_heartstone"), 1, "Keeper's Heartstone in the bag")
	check_eq(ps.inventory.count_of("copper_ingot"), 10, "10 copper ingots")
	check(auth.world_state.bosses_dead.has("orrumhal"), "the world remembers")
	check(ps.progress.level >= 2, "1000 XP: level up")
	_teardown()


func test_heartstone_makes_the_copper_pickaxe() -> void:
	var inv := Inventory.new()
	for item in {copper_ingot = 8, plank_root = 4, leather = 2, keeper_heartstone = 1}:
		inv.add(item, {copper_ingot = 8, plank_root = 4, leather = 2, keeper_heartstone = 1}[item])
	check(Crafting.craft(inv, "pickaxe_copper"), "craft the Copper Pickaxe")
	check(Mat.hits_needed(Mat.BORDER, Items.dig_power("pickaxe_copper"), Items.tier("pickaxe_copper")) > 0, "it digs border rock: the way to the Fungal Jungle")


func test_boss_resets_when_everyone_leaves() -> void:
	await _setup()
	var b := _boss("brask")
	b.hp = 300.0
	player.global_position += Vector3(200, 0, 0)
	auth.monsters._check_boss_resets(31.0)
	check_eq(b.hp, b.max_hp(), "healed back to full")
	check_eq(b.phase, 0, "back to phase 1")
	_teardown()


func test_side_boss_cavern_becomes_a_raid_source() -> void:
	await _setup()
	var cav: Dictionary = world.maker.pois_of("nest_cavern")[0]
	player.global_position = cav.pos + Vector3.UP
	auth.monsters._wake_bosses()
	check(auth.world_state.lairs_found.has("skerra"), "Skerra's cavern discovered")
	_teardown()
