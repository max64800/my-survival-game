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
	player.global_position = world.maker.cavern_spawn
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


func test_crystal_monster_hits_harder_and_drops_crystals() -> void:
	await _setup()
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + 1.2, player.global_position.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, "mossnipper", p + Vector3.UP * 0.3, false, 0, "red")
	var m := auth.monsters.get_monster(uid)
	check_near(m.hp, 42.0, 0.01, "30 HP × 1.4")
	m.target_peer = 1
	auth.monsters.send_tell(m, {name = "Claw Pinch", tell = 0.0, damage = 6, type = "slash", reach = 1.3, parry = "any"})
	auth.monsters._judge_incoming()
	check_near(ps.vitals.health, 100.0 - (6.0 * 1.1 + 5.0), 0.01, "×1.1 damage + 5 fire")
	check_near(ps.vitals.ailments.buildup.burn, 30.0, 0.01, "and 30 burn buildup")
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	m.state = Monster.State.CHASE
	for i in 6:
		if auth.monsters.monsters.is_empty():
			break
		auth.monsters.request_attack(1, PackedInt32Array([uid]), true, 0, false)
	check(auth.monsters.monsters.is_empty(), "killed it")
	var red := 0
	for d in auth._drops.values():
		if d.item_id == "crystal_red":
			red += d.count
	check_eq(red, 4, "4 red crystals dropped")
	_teardown()


func test_animals_run_and_the_hog_fights_back() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var shuffler := _spawn("moss_shuffler", Vector3(1.2, 0, 0))
	for i in 60:
		await tree.physics_frame
	check(shuffler.state in [Monster.State.IDLE, Monster.State.WANDER], "a shuffler ignores you")
	auth.monsters.request_attack(1, PackedInt32Array([shuffler.uid]), false, 0, false)
	check_eq(shuffler.state, Monster.State.FLEE, "hit: it rolls up and runs")
	check_eq(shuffler.stats().armor, 40, "rolled up: hard shell")
	var hog := _spawn("truffle_hog", Vector3(-1.2, 0, 0))
	hog.state = Monster.State.CHASE
	auth.monsters.request_attack(1, PackedInt32Array([hog.uid]), false, 0, false)
	check(hog.state != Monster.State.FLEE, "a healthy hog fights back")
	hog.hp = 30.0
	hog.state = Monster.State.IDLE
	hog.alert(1)
	check_eq(hog.state, Monster.State.FLEE, "a hurt hog runs")
	_teardown()


func test_crossbow_shot() -> void:
	await _setup()
	var m := _spawn("cairnling", Vector3(8.0, 0, 0))
	m.state = Monster.State.CHASE  # it saw us
	var from := player.global_position + Vector3.UP * 1.5
	check_eq(auth.monsters.request_shoot(1, "bolt_stone", true, m.uid, from, m.global_position + Vector3.UP), 0, "no crossbow in hand: no shot")
	ps.inventory.add("crossbow_stone", 1)
	ps.inventory.add("bolt_stone", 3)
	ps.inventory.add("bolt_ember", 1)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_stone":
			auth.request_select_slot(1, i)
	# Aimed stone bolt on a Cairnling: 34 × pierce 0.75 × 100/140 (armor 40) = 18.2 → 18
	check_eq(auth.monsters.request_shoot(1, "bolt_stone", true, m.uid, from, m.global_position + Vector3.UP), 18, "aimed shot damage")
	check_eq(ps.inventory.count_of("bolt_stone"), 2, "the bolt was used")
	check_near(m.hp, 102.0, 0.01, "120 - 18")
	auth.monsters.request_shoot(1, "bolt_ember", false, m.uid, from, m.global_position + Vector3.UP)
	check_near(m.ailments.buildup.burn, 20.0, 0.01, "ember bolt: 40 burn buildup, halved by its 50% fire resist")
	check_eq(auth.monsters.request_shoot(1, "bolt_ember", true, m.uid, from, m.global_position), 0, "out of ember bolts")
	_teardown()


func test_friendly_fire() -> void:
	await _setup()
	var friend := Node3D.new()
	player.get_parent().add_child(friend)
	friend.global_position = player.global_position + Vector3(1.0, 0, 0)
	var fs := auth.add_player(2, friend)
	fs.inventory.add("sword_stone", 1)
	for i in Inventory.HOTBAR_SIZE:
		if fs.inventory.get_slot(i).get("id", "") == "sword_stone":
			fs.selected_slot = i
	check_eq(auth.monsters.request_hit_friend(2, 1, false), 5, "a friend's sword: half of 10")
	check_near(ps.vitals.health, 95.0, 0.01, "it hurt")
	check_eq(auth.monsters.request_hit_friend(2, 1, false), 0, "a 2nd hit faster than a swing doesn't count")
	auth.monsters._ff_ready.clear()
	fs.inventory.add("crossbow_stone", 1)
	for i in Inventory.HOTBAR_SIZE:
		if fs.inventory.get_slot(i).get("id", "") == "crossbow_stone":
			fs.selected_slot = i
	check_eq(auth.monsters.request_hit_friend(2, 1, true, "bolt_blight", 1.0), 19, "a blight bolt: half of 34 × 0.9 + 6 = 37")
	check_near(ps.vitals.ailments.buildup.poison, 25.0, 0.01, "half the poison buildup")
	auth.set_friendly_fire(false)
	check_eq(auth.monsters.request_hit_friend(2, 1, false), 0, "switched off: no friendly fire")
	_teardown()


func test_spore_clouds() -> void:
	await _setup()
	var mm := auth.monsters
	mm.spawn_cloud(player.global_position, 3.0, 5.0, 25.0, 0.0)
	check_eq(mm.clouds.size(), 1, "a cloud appeared")
	for i in 20:
		mm._clouds_step(0.1)
	check_near(ps.vitals.ailments.buildup.poison, 50.0, 0.5, "2 s inside: 50 poison buildup")
	ps.vitals.consume("dish_spore_ward_stew")
	for i in 20:
		mm._clouds_step(0.1)
	check_near(ps.vitals.ailments.buildup.poison, 75.0, 0.5, "Spore Ward Stew halves it")
	for i in 20:
		mm._clouds_step(0.1)
	check_eq(mm.clouds.size(), 0, "after 5 s it's gone")
	# A Wheezecap bursts into a cloud when it dies (unless it burned).
	var w := _spawn("wheezecap", Vector3(1.2, 0, 0))
	mm._kill(w, 1)
	check_eq(mm.clouds.size(), 1, "death burst")
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


func test_poison_jabs_build_up() -> void:
	await _setup()
	var m := _spawn("needlemite", Vector3(1.0, 0, 0))
	for i in 4:
		auth.monsters._ev_tell(m.uid, 1, 0.0, 1.0, 1.4, false, false, "Needle Jab", {poison = 20})
		auth.monsters._judge_incoming()
	check(not ps.vitals.ailments.has("poison"), "4 jabs: not yet")
	(player as FakeDwarf).defense = {holding = true, pressed_ago = 0.05, weapon = "sword", shield = false, tier = 0}
	auth.monsters._ev_tell(m.uid, 1, 0.0, 1.0, 1.4, false, false, "Needle Jab", {poison = 20})
	auth.monsters._judge_incoming()
	check(not ps.vitals.ailments.has("poison"), "a parried jab adds nothing")
	(player as FakeDwarf).defense = {holding = false, pressed_ago = -1.0, weapon = "sword", shield = false, tier = 0}
	auth.monsters._ev_tell(m.uid, 1, 0.0, 1.0, 1.4, false, false, "Needle Jab", {poison = 20})
	auth.monsters._judge_incoming()
	check(ps.vitals.ailments.has("poison"), "the 5th jab that lands: poisoned")
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


## Owner's Rock Snail: after 3 hits it hides in its shell (3 s), taking 90% less damage.
func test_rock_snail_hides_in_its_shell() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var m := _spawn("rock_snail", Vector3(1.2, 0, 0))
	m.state = Monster.State.CHASE
	var first := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check(m.shell_left <= 0.0, "two hits: still out")
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check_near(m.shell_left, 3.0, 0.01, "third hit: hides for 3 s")
	var before := m.hp
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check(before - m.hp <= maxf(1.0, first * 0.15), "hidden: about 90%% less damage (%.0f instead of %d)" % [before - m.hp, first])
	m.think(3.1, auth.monsters)
	check(m.shell_left <= 0.0, "comes back out after 3 s")
	_teardown()


## Owner's Rock Beetle: its back is soft (double damage from behind).
func test_rock_beetle_soft_back() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var m := _spawn("rock_beetle", Vector3(1.2, 0, 0))
	m.state = Monster.State.CHASE
	# Face the beetle toward the player: a front hit.
	var to := player.global_position - m.global_position
	m.model.rotation.y = atan2(-to.x, -to.z)
	var hp0 := m.hp
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	var front := hp0 - m.hp
	m.model.rotation.y += PI  # now its back is to us
	hp0 = m.hp
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	var behind := hp0 - m.hp
	check(behind >= front * 1.8, "from behind: about double (%.0f vs %.0f)" % [behind, front])
	_teardown()
