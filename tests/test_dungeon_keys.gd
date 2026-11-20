extends TestCase
## Dungeon keys and locked doors (owner, Nov 20, F237): one key per medium and big dungeon, a door opens only for its
## own key (Hammerfall's gate needs two), and an hour of play after the boss dropped it the key goes back to the boss.

var auth: GameAuthority
var keys: DungeonKeys
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	auth = GameAuthority.new()
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	keys = DungeonKeys.new()
	keys.name = "DungeonKeys"
	auth.add_child(keys)
	player = Node3D.new()
	root.add_child(player)
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_one_key_per_medium_and_big_dungeon() -> void:
	for d in DungeonList.LIST:
		var n := DungeonKeys.keys_of(d.id).size()
		check_eq(n, 0 if d.size == "small" else (2 if d.id == "the_hammerfall_works" else 1), "%s has the right number of keys" % d.name)
	for k in DungeonKeys.KEYS:
		check(Items.exists(k) and Items.kind(k) == "key", "%s is an item" % k)
		check(Items.icon(k) != null, "%s has a picture" % k)
	check_eq(Items.display_name("key_vault"), "Vault Key", "named like the plan says")


func test_a_door_opens_only_for_its_own_key() -> void:
	await _setup()
	keys.add_door("brassgate_vault", Vector3(2, 0, 0))
	check_eq(keys.request_unlock(1, "brassgate_vault"), "Locked. It needs the Vault Key.", "no key: stays shut")
	ps.inventory.add("key_bronze", 1)
	check(not keys.is_open("brassgate_vault") and keys.request_unlock(1, "brassgate_vault").begins_with("Locked"), "the wrong key does nothing")
	ps.inventory.add("key_vault", 1)
	player.global_position = Vector3(20, 0, 0)
	check_eq(keys.request_unlock(1, "brassgate_vault"), "Too far away.", "you have to stand at the door")
	player.global_position = Vector3.ZERO
	check_eq(keys.request_unlock(1, "brassgate_vault"), "The door swings open.", "its own key opens it")
	check(keys.is_open("brassgate_vault"), "and it stays open")
	_teardown()


func test_two_friends_open_the_twin_locks() -> void:
	await _setup()
	var friend := Node3D.new()
	auth.get_parent().add_child(friend)
	var ps2 := auth.add_player(2, friend)
	keys.add_door("the_hammerfall_works", Vector3.ZERO)
	ps.inventory.add("key_gear", 1)
	ps2.inventory.add("key_hammer", 1)
	check_eq(keys.request_unlock(1, "the_hammerfall_works"), "One lock clicks open. The other needs the Hammer Key.", "one lock")
	check(not keys.is_open("the_hammerfall_works"), "one lock isn't enough")
	check_eq(keys.request_unlock(2, "the_hammerfall_works"), "The door swings open.", "the friend opens the other")
	check(keys.is_open("the_hammerfall_works"), "both locks: open")
	_teardown()


func test_the_key_goes_back_to_its_boss_after_an_hour() -> void:
	await _setup()
	keys.add_door("emberdeep_forge", Vector3(200, 0, 0))
	check(keys.boss_has_key("key_forge"), "the boss starts with the key")
	auth.world_state.played = 50.0
	keys.drop_key("key_forge", Vector3(200, 1, 0))
	keys.drop_key("key_forge", Vector3(200, 1, 0))
	check_eq(auth._drops.size(), 1, "the key drops once")
	check(not keys.boss_has_key("key_forge"), "the boss no longer has it")
	auth._ev_remove_drop(auth._drops.keys()[0])  # picked up
	ps.inventory.add("key_forge", 1)
	player.global_position = Vector3(200, 0, 0)
	keys.request_unlock(1, "emberdeep_forge")
	var box := auth.storage.create_box("chest_small", Vector3.ZERO, 0.0)
	auth.storage.put(box, "key_forge", 1)  # (a second one hidden in a chest)
	auth.world_state.played = 50.0 + DungeonLoot.REFILL
	keys.tick()
	check(keys.is_open("emberdeep_forge"), "not while someone is at the door (nobody gets shut in)")
	player.global_position = Vector3.ZERO
	keys.tick()
	check(keys.boss_has_key("key_forge"), "back with the boss")
	check_eq(ps.inventory.count_of("key_forge") + auth.storage.get_box(box).inv.count_of("key_forge"), 0, "gone from bags and chests")
	check(not keys.is_open("emberdeep_forge"), "the door is locked again")
	_teardown()


func test_the_boss_bar_follows_its_boss() -> void:
	var m := Monster.new()
	m.setup(1, "rock_beetle", false, Vector3.ZERO)
	var bar := BossBar.new()
	bar.track(m, DungeonKeys.KEYS.key_vault.boss)
	check(bar.visible and bar.title.text == "The Vault Captain", "shows the boss's name")
	m.hp = m.max_hp() * 0.5
	bar._process(0.0)
	check_near(bar.bar.value / bar.bar.max_value, 0.5, 0.01, "half health, half bar")
	m.hp = 0.0
	bar._process(0.0)
	check(not bar.visible, "hides when the boss dies")
	bar.free()
	m.free()


## Owner, Nov 20: the way out ends at a barred gate in the first room; a lever on the inside opens it, and it closes
## again when the dungeon refills (never while someone is near).
func test_the_exit_gate_opens_with_its_lever_and_closes_on_refill() -> void:
	await _setup()
	keys.add_gate("mossgate_hold", Vector3(1, 0, 0))
	check(not keys.gate_open("mossgate_hold"), "shut at the start")
	player.global_position = Vector3(30, 0, 0)
	check_eq(keys.request_pull_lever(1, "mossgate_hold"), "Too far away.", "only at the lever")
	player.global_position = Vector3.ZERO
	auth.world_state.played = 10.0
	check_eq(keys.request_pull_lever(1, "mossgate_hold"), "The gate grinds open. The way out!", "the lever opens it")
	check(keys.gate_open("mossgate_hold"), "open for everyone")
	auth.world_state.played = 10.0 + DungeonLoot.REFILL
	keys.tick()
	check(keys.gate_open("mossgate_hold"), "not while someone is near")
	player.global_position = Vector3(500, 0, 0)
	keys.tick()
	check(not keys.gate_open("mossgate_hold"), "shut again after the refill")
	_teardown()
