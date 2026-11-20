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
	check_eq(Gems.socket_count("axe_copper"), 1, "the wood axe is a tool with a socket")
	check_eq(Gems.slot_kind("axe_copper"), "tool", "wood axe = tool")
	check_eq(Gems.slot_kind("axe_2h_copper"), "weapon", "great axe = weapon")
	check_eq(Gems.socket_count("helm_copper"), 1, "copper armor: 1 socket")
	check_eq(Gems.socket_count("helm_leather"), 0, "leather armor: none")
	var b := Gems.bonus({id = "sword_copper", count = 1, gems = ["keen", "keen"]})
	check_near(b.keen, 0.03, 0.0001, "Rough Edge Quartz 2%, a 2nd copy works at half strength")
	check_near(Gems.bonus({id = "sword_copper", count = 1, gems = ["keen_3"]}).keen, 0.10, 0.0001, "Polished: 10%")
	check_eq(Gems.bonus({id = "shield_copper", count = 1, gems = ["ember_2"]}), {parry_burn = 0.15}, "the same gem does something else in a shield")
	check_eq(Gems.full_name("bulwark_2"), "Cut Stone Amber", "level names")
	check_eq(Gems.gem_of("gem_keen_3"), "keen_3", "leveled gem items")
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
	ps.inventory.remove("gold_coin", ps.inventory.count_of("gold_coin"))
	check_eq(auth.request_unsocket(1, slot, 0), "Needs 5 gold", "taking it out costs gold")
	ps.inventory.add("gold_coin", 5)
	check_eq(auth.request_unsocket(1, slot, 0), "", "taken out")
	check_eq(ps.inventory.count_of("gem_ember"), 1, "it came back intact")
	check_eq(ps.inventory.count_of("gold_coin"), 0, "5 gold spent")
	_teardown()


func test_ember_sword_burns() -> void:
	await _setup()
	ps.inventory.slots[1] = {id = "sword_copper", count = 1, gems = ["ember"]}
	auth.request_select_slot(1, 1)  # the sword was put straight into slot index 1 above
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + 1.2, player.global_position.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, "rock_snail", p + Vector3.UP * 0.3, false, 0)
	var m := auth.monsters.get_monster(uid)
	m.state = Monster.State.CHASE
	seed(3)
	var burned := 0
	for i in 40:
		m.ailments.clear()
		m.hp = 1000
		auth.monsters.request_attack(1, PackedInt32Array([uid]), false, 0, false)
		burned += 1 if m.ailments.has("burn") else 0
	check(burned >= 1 and burned <= 8, "Rough Forge Garnet: about 1 hit in 20 sets it burning (%d of 40)" % burned)
	_teardown()


## Owner, Nov 20 ("make sure they're in the game"): on a creature, fire really hurts it over time and
## frost really stops it, through the creature's own thinking step.
func test_creature_burns_and_freezes() -> void:
	await _setup()
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + 1.2, player.global_position.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, "rock_snail", p + Vector3.UP * 0.3, false, 0)
	var m := auth.monsters.get_monster(uid)
	m.hp = 100.0
	m.add_buildup("burn", Ailments.FULL)
	check(m.ailments.has("burn"), "a full cup of fire: the snail burns")
	for i in 10:
		m.think(0.1, auth.monsters)
	check_near(m.hp, 97.0, 0.2, "burning 1 s: 3 damage")
	for k in 5:
		m.add_buildup("chill", Ailments.FULL)
	check(m.ailments.has("frozen"), "5 frost stacks: frozen")
	check(not m.ailments.has("burn"), "frost puts the fire out")
	m.velocity = Vector3(3, 0, 0)
	for i in 3:  # (it slides to a stop in about 0.15 s)
		m.think(0.1, auth.monsters)
	check(Vector2(m.velocity.x, m.velocity.z).length() < 0.01, "a frozen snail doesn't move")
	check(m.ailments.has("frozen"), "...still frozen after 0.3 s (1.5 s in all)")
	m.hp = 2.0
	m.add_buildup("burn", Ailments.FULL)
	for i in 20:
		if m.is_alive():
			m.think(0.1, auth.monsters)
	check(not m.is_alive(), "fire can finish it off")
	_teardown()


func test_shield_gems_change_blocks() -> void:
	var plain := Combat.defend(20.0, -1.0, true, "sword", true, 1)
	var bulwark := Combat.defend(20.0, -1.0, true, "sword", true, 1, false, {block = 0.08, block_stamina = 0.2})
	check_near(plain.damage, 8.0, 0.01, "copper shield blocks 60%")
	check_near(bulwark.damage, 6.4, 0.01, "Bulwark: 68%")
	check_near(bulwark.stamina, 8.0, 0.01, "Swift: blocks cost 20% less stamina")


func test_combine_three_into_a_better_gem() -> void:
	await _setup()
	ps.inventory.add("gem_keen", 3)
	check_eq(auth.request_combine(1, "keen"), "Stand at a Gem Bench", "needs a bench")
	auth._ev_place_station(7, "gem_bench", player.global_position + Vector3(1.5, 0, 0), 0.0)
	ps.inventory.remove("gold_coin", ps.inventory.count_of("gold_coin"))
	check_eq(auth.request_combine(1, "keen"), "Needs 10 gold", "a Cut gem costs 10 gold")
	ps.inventory.add("gold_coin", 10)
	check_eq(auth.request_combine(1, "keen"), "", "combined")
	check_eq(ps.inventory.count_of("gem_keen"), 0, "3 Rough gone")
	check_eq(ps.inventory.count_of("gem_keen_2"), 1, "1 Cut made")
	check_eq(auth.request_combine(1, "keen_2"), "Needs 3 Cut Edge Quartz", "a Polished one needs 3 Cut")
	check_eq(auth.request_combine(1, "keen_3"), "That gem can't get any better yet", "Polished is the top for now")
	_teardown()


func test_where_gems_come_from() -> void:
	check_eq(Gems.end_chest_gem("mossgate", 0.0, 0.0), "bulwark", "a small dungeon's last chest: Rough, its own gem")
	check_eq(Gems.end_chest_gem("emberdeep_forge", 0.0, 0.2), "ember_2", "a big one: Cut half the time")
	check_eq(Gems.end_chest_gem("emberdeep_forge", 0.9, 0.8), "keen", "...else Rough")
	for d in DungeonList.LIST:
		check(Gems.DUNGEON_GEMS.has(d.id), "%s has its 2 gems" % d.id)
	check_eq(Gems.CREATURE_GEM.cave_spider, "blight", "spiders hold Bog Jade")
	check(Monsters.LIST.rock_snail.attacks.any(func(a): return a.get("buildup", {}).get("poison", 0) >= 100), "snail spit: 1 poison stack")


func test_armor_gems() -> void:
	await _setup()
	ps.inventory.slots[Inventory.equip_index("chest")] = {id = "mail_copper", count = 1, gems = ["bulwark_3"]}
	ps.inventory.slots[Inventory.equip_index("head")] = {id = "helm_copper", count = 1, gems = ["blight_2"]}
	ps.inventory.changed.emit()
	check_near(ps.vitals.gear.get("guard_all", 0.0), 0.05, 0.0001, "Polished Stone Amber: 5% less damage")
	ps.vitals.add_ailment("poison", 100)
	check_near(ps.vitals.ailments.buildup.poison, 85.0, 0.5, "Cut Bog Jade: 15% less poison")
	_teardown()
