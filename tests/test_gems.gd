extends TestCase
## Gems in weapons, shields and pickaxes (combat doc 4).

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


func _slot_of(id: String) -> int:
	for i in ps.inventory.slots.size():
		if ps.inventory.get_slot(i).get("id", "") == id:
			return i
	return -1


func test_socket_counts_and_bonuses() -> void:
	check_eq(Gems.socket_count("sword_stone"), 0, "stone: no sockets")
	check_eq(Gems.socket_count("sword_copper"), 1, "copper: 1 socket")
	check_eq(Gems.socket_count("pickaxe_silver"), 1, "pickaxes have sockets too")
	check_eq(Gems.socket_count("stone"), 0, "stone blocks don't")
	var b := Gems.bonus({id = "sword_copper", count = 1, gems = ["keen", "keen"]})
	check_near(b.keen, 0.12, 0.0001, "a 2nd copy works at half strength")
	check_eq(Gems.bonus({id = "shield_copper", count = 1, gems = ["ember"]}), {parry_burn = 50.0}, "the same gem does something else in a shield")
	check(not Gems.can_socket({id = "sword_copper", count = 1, gems = []}, "cinder_wake"), "epic gems need an epic socket")
	for g in Gems.NORMAL.keys() + Gems.EPIC.keys():
		check(Items.exists(Gems.item_id(g)), "%s is an item" % g)


func test_bench_socket_and_remove() -> void:
	await _setup()
	ps.inventory.add("sword_copper", 1)
	ps.inventory.add("gem_ember", 1)
	var slot := _slot_of("sword_copper")
	check_eq(auth.request_socket(1, slot, "ember"), "Stand at a Gem Bench", "needs a bench")
	auth._ev_place_station(7, "gem_bench", player.global_position + Vector3(1.5, 0, 0), 0.0)
	check_eq(auth.request_socket(1, slot, "ember"), "", "socketed")
	check_eq(ps.inventory.get_slot(slot).gems, ["ember"], "the sword holds the gem")
	check_eq(ps.inventory.count_of("gem_ember"), 0, "the gem left the bag")
	ps.inventory.add("gem_keen", 1)
	check_eq(auth.request_socket(1, slot, "keen"), "No free socket for that gem", "only 1 socket on copper")
	check_eq(auth.request_unsocket(1, slot, 0), "Needs 5 blue glow crystals", "taking it out costs crystals")
	ps.inventory.add("crystal_blue", 5)
	check_eq(auth.request_unsocket(1, slot, 0), "", "taken out")
	check_eq(ps.inventory.count_of("gem_ember"), 1, "it came back intact")
	check_eq(ps.inventory.count_of("crystal_blue"), 0, "5 crystals spent")
	_teardown()


func test_ember_sword_burns() -> void:
	await _setup()
	ps.inventory.slots[1] = {id = "sword_copper", count = 1, gems = ["ember"]}
	auth.request_select_slot(1, 1)  # the sword was put straight into slot index 1 above
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + 1.2, player.global_position.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, "cairnling", p + Vector3.UP * 0.3, false, 0)
	var m := auth.monsters.get_monster(uid)
	m.state = Monster.State.CHASE
	# Copper sword light on a Cairnling: 10 × 1.3 × slash 0.5 × 100/140 = 4.6, + 5 fire × (1 − 0.5 resist) = 2.5 → 7
	check_eq(auth.monsters.request_attack(1, PackedInt32Array([uid]), false, 0, false), 7, "fire adds damage")
	check_near(m.ailments.buildup.burn, 12.5, 0.01, "and burn buildup (halved by its fire resist)")
	_teardown()


func test_shield_gems_change_blocks() -> void:
	var plain := Combat.defend(20.0, -1.0, true, "sword", true, 1)
	var bulwark := Combat.defend(20.0, -1.0, true, "sword", true, 1, false, {block = 0.08, block_stamina = 0.2})
	check_near(plain.damage, 8.0, 0.01, "copper shield blocks 60%")
	check_near(bulwark.damage, 6.4, 0.01, "Bulwark: 68%")
	check_near(bulwark.stamina, 8.0, 0.01, "Swift: blocks cost 20% less stamina")
