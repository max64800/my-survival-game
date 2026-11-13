extends TestCase
## Monsters and fighting, with the real cave and referee.

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


## A stand-in dwarf that can say "I'm blocking / I pressed block X seconds ago".
class FakeDwarf extends Node3D:
	var defense := {holding = false, pressed_ago = -1.0, weapon = "sword", shield = false, tier = 0}
	var parried := false

	func defense_state() -> Dictionary:
		return defense

	func is_invulnerable() -> bool:
		return false

	func got_parry() -> void:
		parried = true


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
	player = FakeDwarf.new()
	root.add_child(player)
	player.global_position = world.maker.spawn_point
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 900:
		if world.terrain.is_area_meshed(AABB(player.global_position - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await tree.physics_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


func _spawn(kind: String, offset: Vector3, leader := false, pack := 0) -> Monster:
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + offset.x, player.global_position.z + offset.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, kind, p + Vector3.UP * 0.3, leader, pack)
	return auth.monsters.get_monster(uid)


func test_monster_data_is_sane() -> void:
	for id in Monsters.LIST:
		var m: Dictionary = Monsters.LIST[id]
		for a in m.attacks:
			check(a.tell >= 0.4, "%s %s gives at least 0.4 s of warning" % [id, a.name])
		for d in m.drops:
			check(Items.exists(d[0]), "%s drops a real item (%s)" % [id, d[0]])


func test_notices_and_chases_you() -> void:
	await _setup()
	var m := _spawn("mossnipper", Vector3(6, 0, 0))
	check_eq(m.state, Monster.State.IDLE, "starts idle")
	for i in 120:
		await tree.physics_frame
	check(m.state in [Monster.State.ALERT, Monster.State.CHASE, Monster.State.ATTACK, Monster.State.RECOVER], "noticed us (state %d)" % m.state)
	_teardown()


func test_sword_damage_and_kill() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var m := _spawn("mossnipper", Vector3(1.2, 0, 0))
	m.state = Monster.State.CHASE  # it saw us: no sneak bonus
	var dealt := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check_eq(dealt, 13, "stone sword light on a mossnipper (slash ×1.25): 10 × 1.25 = 12.5 → 13")
	check_near(m.hp, 17.0, 0.01, "30 - 13 = 17 HP left")
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), true, 0, false)
	check(auth.monsters.monsters.is_empty(), "heavy finishes it")
	check(ps.progress.skill_xp.fighting >= 5, "fighting XP for the kill")
	_teardown()


func test_sneak_attack_doubles() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var m := _spawn("rustwight", Vector3(1.2, 0, 0))
	check_eq(m.state, Monster.State.SLEEP, "rustwights start asleep")
	var dealt := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check_eq(dealt, 12, "sneak ×2 on armor 25, slash ×0.75: 10 × 0.75 × 0.8 × 2 = 12")
	_teardown()


func test_parry_stuns_the_monster() -> void:
	await _setup()
	var m := _spawn("skitterling", Vector3(1.0, 0, 0))
	var fake := player as FakeDwarf
	fake.defense = {holding = true, pressed_ago = 0.05, weapon = "sword", shield = false, tier = 0}
	auth.monsters._ev_tell(m.uid, 1, 0.0, 8.0, 1.3, false, false, "Bite")
	auth.monsters._judge_incoming()
	check_eq(ps.vitals.health, 100.0, "perfect parry: no damage")
	check(fake.parried, "the dwarf was told")
	check_near(m.stun.value, Combat.STUN_WEAPON_PARRY, 0.01, "stun meter filled by 25")
	_teardown()


func test_unblocked_hit_hurts() -> void:
	await _setup()
	var m := _spawn("skitterling", Vector3(1.0, 0, 0))
	auth.monsters._ev_tell(m.uid, 1, 0.0, 8.0, 1.3, false, false, "Bite")
	auth.monsters._judge_incoming()
	check_eq(ps.vitals.health, 92.0, "8 damage")
	_teardown()


func test_too_far_misses() -> void:
	await _setup()
	var m := _spawn("skitterling", Vector3(6.0, 0, 0))
	auth.monsters._ev_tell(m.uid, 1, 0.0, 8.0, 1.3, false, false, "Bite")
	auth.monsters._judge_incoming()
	check_eq(ps.vitals.health, 100.0, "you stepped away: it misses")
	_teardown()


func test_pack_leader_boost_ends_when_it_dies() -> void:
	await _setup()
	ps.inventory.add("mace_2h_copper", 1)
	auth.request_select_slot(1, 1)
	var leader := _spawn("mossnipper", Vector3(5, 0, 0), true, 7)
	var member := _spawn("mossnipper", Vector3(6, 0, 1), false, 7)
	auth.monsters._update_boosts()
	check(member.boosted, "member near its leader is boosted")
	check_near(member.damage_mult(), 1.2, 0.001, "+20% damage")
	check_near(leader.damage_mult(), 1.3, 0.001, "leader itself hits ×1.3")
	check_near(leader.max_hp(), 75.0, 0.01, "leader has ×2.5 HP")
	auth.monsters._ev_remove(leader.uid)
	auth.monsters._update_boosts()
	check(not member.boosted, "boost gone when the leader is gone")
	_teardown()


func test_spawner_fills_nearby_caves() -> void:
	await _setup()
	auth.monsters.enabled = true
	auth.monsters._spawn_and_despawn()
	check(auth.monsters.monsters.size() > 0, "monsters appeared near us (%d)" % auth.monsters.monsters.size())
	_teardown()


func test_attack_animation_keeps_monster_size() -> void:
	await _setup()
	var m := _spawn("mossnipper", Vector3(4, 0, 0), true)  # leaders are 1.3× bigger
	var before: Vector3 = m.model.scale
	m.show_tell(0.05)
	await tree.create_timer(0.5).timeout
	check(m.model.scale.is_equal_approx(before), "still %s after the attack (was %s)" % [m.model.scale, before])
	_teardown()
