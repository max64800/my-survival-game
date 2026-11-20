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
	var m := _spawn("cave_spider", Vector3(6, 0, 0))
	check_eq(m.state, Monster.State.IDLE, "starts idle")
	for i in 120:
		await tree.physics_frame
	check(m.state in [Monster.State.ALERT, Monster.State.CHASE, Monster.State.ATTACK, Monster.State.RECOVER], "noticed us (state %d)" % m.state)
	_teardown()


func test_sword_damage_and_kill() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, first_item_slot(ps))  # the start pickaxe is in the hotbar (F243)
	var m := _spawn("cave_spider", Vector3(1.2, 0, 0))
	m.state = Monster.State.CHASE  # it saw us: no sneak bonus
	var dealt := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check_eq(dealt, 13, "stone sword light on a cave spider (slash ×1.25): 10 × 1.25 = 12.5 → 13")
	check_near(m.hp, 11.0, 0.01, "24 - 13 = 11 HP left")
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), true, 0, false)
	check(auth.monsters.monsters.is_empty(), "heavy finishes it")
	check(ps.progress.skill_xp.sword >= 5, "Sword XP for the kill")
	check_eq(ps.progress.kills_of("cave_spider"), 1, "the kill is counted")
	_teardown()


func test_crystal_monster_hits_harder_and_drops_crystals() -> void:
	await _setup()
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + 1.2, player.global_position.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, "cave_spider", p + Vector3.UP * 0.3, false, 0, "red")
	var m := auth.monsters.get_monster(uid)
	check_near(m.hp, 24.0 * 1.4, 0.01, "24 HP × 1.4")
	m.target_peer = 1
	auth.monsters.send_tell(m, {name = "Bite", tell = 0.0, damage = 6, type = "pierce", reach = 1.3, parry = "any"})
	auth.monsters._judge_incoming()
	check_near(ps.vitals.health, 100.0 - (6.0 * 1.1 + 5.0), 0.01, "×1.1 damage + 5 fire")
	check_near(ps.vitals.ailments.buildup.burn, 30.0, 0.01, "and 30 burn buildup")
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, first_item_slot(ps))  # the start pickaxe is in the hotbar (F243)
	m.state = Monster.State.CHASE
	for i in 6:
		if auth.monsters.monsters.is_empty():
			break
		auth.monsters.request_attack(1, PackedInt32Array([uid]), true, 0, false)
	check(auth.monsters.monsters.is_empty(), "killed it")
	var red := 0  # (owner, Nov 18: it turns to stone; its crystals are inside, they come out when you mine it)
	for st: Dictionary in auth.monsters.statues.values():
		for d: Array in st.loot:
			if d[0] == "crystal_red":
				red += d[1]
	check_eq(red, 4, "4 red crystals inside its stone statue")
	_teardown()


## The Rock Snail is neutral: it fights back when hit, and goes away when it's badly hurt.
func test_a_healthy_snail_fights_back_a_hurt_one_runs() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, first_item_slot(ps))  # the start pickaxe is in the hotbar (F243)
	var snail := _spawn("rock_snail", Vector3(-1.2, 0, 0))
	snail.state = Monster.State.CHASE
	auth.monsters.request_attack(1, PackedInt32Array([snail.uid]), false, 0, false)
	check(snail.state != Monster.State.FLEE, "a healthy snail fights back")
	snail.hp = 30.0
	snail.state = Monster.State.IDLE
	snail.alert(1)
	check_eq(snail.state, Monster.State.FLEE, "a hurt snail goes away")
	_teardown()


func test_crossbow_shot() -> void:
	await _setup()
	var m := _spawn("rock_snail", Vector3(8.0, 0, 0))
	m.state = Monster.State.CHASE  # it saw us
	var from := player.global_position + Vector3.UP * 1.5
	check_eq(auth.monsters.request_shoot(1, "bolt_stone", true, m.uid, from, m.global_position + Vector3.UP), 0, "no crossbow in hand: no shot")
	ps.inventory.add("crossbow_stone", 1)
	ps.inventory.add("bolt_stone", 3)
	ps.inventory.add("bolt_ember", 1)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_stone":
			auth.request_select_slot(1, i)
	# Aimed stone bolt on a Rock Snail: 34 × pierce 1.0 × 100/120 (armor 20) = 28.3 → 28
	check_eq(auth.monsters.request_shoot(1, "bolt_stone", true, m.uid, from, m.global_position + Vector3.UP), 28, "aimed shot damage")
	check_eq(ps.inventory.count_of("bolt_stone"), 2, "the bolt was used")
	check_near(m.hp, 82.0, 0.01, "110 - 28")
	auth.monsters.request_shoot(1, "bolt_ember", false, m.uid, from, m.global_position + Vector3.UP)
	check_near(m.ailments.buildup.burn, 40.0, 0.01, "ember bolt: 40 burn buildup (no fire resist)")
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
	_teardown()


func test_sneak_attack_doubles() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, first_item_slot(ps))  # the start pickaxe is in the hotbar (F243)
	var m := _spawn("rock_snail", Vector3(1.2, 0, 0), true)  # a leader: armor 30, 275 HP (lives through the hit)
	m.state = Monster.State.SLEEP
	var dealt := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check_eq(dealt, 12, "sneak ×2 on armor 30, slash ×0.75: 10 × 0.75 × 100/130 × 2 = 11.5 → 12")
	_teardown()


func test_parry_stuns_the_monster() -> void:
	await _setup()
	var m := _spawn("cave_spider", Vector3(1.0, 0, 0))
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
	var m := _spawn("cave_spider", Vector3(1.0, 0, 0))
	auth.monsters._ev_tell(m.uid, 1, 0.0, 8.0, 1.3, false, false, "Bite")
	auth.monsters._judge_incoming()
	check_eq(ps.vitals.health, 92.0, "8 damage")
	_teardown()


func test_poison_jabs_build_up() -> void:
	await _setup()
	var m := _spawn("cave_spider", Vector3(1.0, 0, 0))
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
	var m := _spawn("cave_spider", Vector3(6.0, 0, 0))
	auth.monsters._ev_tell(m.uid, 1, 0.0, 8.0, 1.3, false, false, "Bite")
	auth.monsters._judge_incoming()
	check_eq(ps.vitals.health, 100.0, "you stepped away: it misses")
	_teardown()


func test_pack_leader_boost_ends_when_it_dies() -> void:
	await _setup()
	ps.inventory.add("mace_2h_copper", 1)
	auth.request_select_slot(1, first_item_slot(ps))  # the start pickaxe is in the hotbar (F243)
	var leader := _spawn("cave_spider", Vector3(5, 0, 0), true, 7)
	var member := _spawn("cave_spider", Vector3(6, 0, 1), false, 7)
	auth.monsters._update_boosts()
	check(member.boosted, "member near its leader is boosted")
	check_near(member.damage_mult(), 1.2, 0.001, "+20% damage")
	check_near(leader.damage_mult(), 1.3, 0.001, "leader itself hits ×1.3")
	check_near(leader.max_hp(), 60.0, 0.01, "leader has ×2.5 HP")
	auth.monsters._ev_remove(leader.uid)
	auth.monsters._update_boosts()
	check(not member.boosted, "boost gone when the leader is gone")
	_teardown()


func test_spawner_fills_nearby_caves() -> void:
	await _setup()
	auth.monsters.enabled = true
	auth.monsters._spawn_and_despawn()
	var bats := 0
	for m: Monster in auth.monsters.monsters.values():
		var r: Dictionary = world.maker.rooms[0]
		if m.global_position.distance_to(r.center) < maxf(r.radii.x, r.radii.z):
			# Owner, Nov 19 (replaces F154): the first cave has gentle snails and a roost of sleeping plain bats.
			check(m.kind in ["rock_snail", "cave_bat"], "only snails and bats in the first cave: %s" % m.kind)
			if m.kind == "cave_bat":
				bats += 1
				check(m.state == Monster.State.SLEEP and m.variant == "", "first-cave bats are plain and asleep")
	check(bats >= 1, "the first cave has bats to hunt")
	# Walk to another cavern: monsters appear there.
	for i in world.maker.rooms.size():
		var room: Dictionary = world.maker.rooms[i]
		if not room.get("sealed", false) and room.get("kind", "") in ["cavern", "room", "great_hall", "ruin"]:
			player.global_position = room.center
			break
	# Wait until the ground there is loaded (slow when the PC is busy), then try spawning a few times
	# (it was flaky with a fixed 120-frame wait: Claude 3, Nov 16).
	for i in 1500:
		if world.is_ready_at(player.global_position, 4.0):
			break
		await tree.process_frame
	for tries in 10:
		auth.monsters._spawn_and_despawn()
		if auth.monsters.monsters.size() > 0:
			break
		for f in 30:
			await tree.process_frame
	check(auth.monsters.monsters.size() > 0, "monsters appeared in the next cave (%d)" % auth.monsters.monsters.size())
	_teardown()


func test_attack_animation_keeps_monster_size() -> void:
	await _setup()
	var m := _spawn("cave_spider", Vector3(4, 0, 0), true)  # leaders are 1.3× bigger
	var before: Vector3 = m.model.scale
	m.show_tell(0.05)
	await tree.create_timer(0.5).timeout
	check(m.model.scale.is_equal_approx(before), "still %s after the attack (was %s)" % [m.model.scale, before])
	_teardown()


## Owner's Rock Snail (Nov 18): it hides in its shell at half health and again at 10%, 10 s each, taking 90% less
## damage (no more hiding every 3rd hit: that let you stun-lock it).
func test_rock_snail_hides_in_its_shell() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var m := _spawn("rock_snail", Vector3(1.2, 0, 0))
	m.state = Monster.State.CHASE
	var first := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check(m.shell_left <= 0.0, "one hit: still out")
	m.hp = m.max_hp() * 0.55
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check_near(m.shell_left, 10.0, 0.01, "below half health: hides for 10 s")
	var before := m.hp
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check(before - m.hp <= maxf(1.0, first * 0.15), "hidden: about 90%% less damage (%.0f instead of %d)" % [before - m.hp, first])
	m.think(10.1, auth.monsters)
	check(m.shell_left <= 0.0, "comes back out after 10 s")
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check(m.shell_left <= 0.0, "out again: no hiding until 10% health")
	m.hp = m.max_hp() * 0.12
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	if m.hp > 0.0:
		check_near(m.shell_left, 10.0, 0.01, "below 10%: hides again for 10 s")
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


## The first three creatures' sounds (warn_sound / land_sound / flap_sound) all exist as files,
## and the snail's shell / a beetle's charge show it to everyone.
func test_creature_sounds_and_tells() -> void:
	var named := []
	for kind in ["rock_snail", "cave_bat", "rock_beetle", "great_rock_beetle"]:
		var d: Dictionary = Monsters.LIST[kind]
		if d.has("flap_sound"):
			named.append(d.flap_sound)
		for a: Dictionary in d.attacks:
			for key in ["warn_sound", "land_sound"]:
				if a.has(key):
					named.append(a[key])
	named.append_array(["shell_clunk", "shell_clank", "death", "open", "close", "pickup", "refill"])
	check(named.size() >= 12, "the creatures name their sounds (%d)" % named.size())
	for n in named:
		check(not Sfx._variants(n).is_empty(), "sound files for '%s'" % n)
	await _setup()
	var snail := _spawn("rock_snail", Vector3(1.5, 0, 0))
	snail.show_shell(true)
	check(snail.shell_shut, "hiding snail is marked shut (hits clank)")
	snail.show_shell(false)
	check(not snail.shell_shut, "snail came out")
	var beetle := _spawn("rock_beetle", Vector3(-2.5, 0, 0))
	beetle.show_tell(1.1, "Charge")
	var eye: StandardMaterial3D = beetle.model.get_meta("eye_mat")
	check(eye.emission.g < 0.5, "charging beetle's eyes turn red")
	_teardown()


## Rock Snail spit (owner, Nov 17): short range, and a shield stops it completely (a weapon block doesn't).
func test_shield_stops_snail_spit() -> void:
	await _setup()
	var m := _spawn("rock_snail", Vector3(2.5, 0, 0))
	var spit: Dictionary = {}
	for a: Dictionary in Monsters.LIST.rock_snail.attacks:
		if a.name == "Spit":
			spit = a
	check(not spit.is_empty() and spit.reach <= 3.0 and spit.shield_stops, "the snail has a short spit a shield stops")
	check(not m._pick_attack(1.0).get("spit", false), "too close: no spit")
	check(m._pick_attack(2.5).get("spit", false), "2.5 m away: it spits")
	var fake := player as FakeDwarf
	fake.defense = {holding = true, pressed_ago = -1.0, weapon = "sword", shield = true, tier = 0}
	auth.monsters._ev_tell(m.uid, 1, 0.0, 12.0, 3.0, false, false, "Spit", {}, false, true)
	auth.monsters._judge_incoming()
	check_eq(ps.vitals.health, 100.0, "shield up: no damage at all")
	fake.defense = {holding = true, pressed_ago = -1.0, weapon = "sword", shield = false, tier = 0}
	auth.monsters._ev_tell(m.uid, 1, 0.0, 12.0, 3.0, false, false, "Spit", {}, false, true)
	auth.monsters._judge_incoming()
	check(ps.vitals.health < 100.0, "blocked with a sword: some gets through")
	_teardown()


## Rock Snail hop and daze (owner, Nov 17): the body rises and sways, the foot stays planted on the ground.
func test_snail_foot_stays_put() -> void:
	await _setup()
	var m := _spawn("rock_snail", Vector3(3.0, 0, 0))
	var model := m.model
	check(model.has_meta("foot"), "the snail model has its own foot")
	if not model.has_meta("foot"):
		_teardown()
		return
	m.set_process(false)  # we drive the animation by hand
	var foot: MeshInstance3D = model.get_meta("foot")
	var forged: Node3D = model.get_meta("forged_root")
	MonsterModel.animate(model, 0.0, 1.0, 0.0)
	var foot0 := foot.global_position
	var body0 := forged.global_position
	var rose := 0.0
	for i in 12:  # walking: one whole hop
		MonsterModel.animate(model, 0.6, 1.0, i * MonsterModel.HOP_TIME / 12.0)
		check_near(foot.global_position.y, foot0.y, 0.001, "walking: the foot stays on the ground")
		var gap := Vector2(foot.global_position.x - forged.global_position.x, foot.global_position.z - forged.global_position.z)
		var gap0 := Vector2(foot0.x - body0.x, foot0.z - body0.z)
		check_near(gap.distance_to(gap0), 0.0, 0.001, "walking: the body stays over its foot")
		rose = maxf(rose, forged.global_position.y - body0.y)
	check(rose > 0.04, "the body rises in the hop")
	MonsterModel.dazed_sway(model, 0.15)
	MonsterModel.animate(model, 0.0, 1.0, 5.0)
	check_near(foot.global_position.distance_to(foot0), 0.0, 0.001, "dazed: the foot stays put")
	check(absf(forged.rotation.z) > 0.1, "dazed: the body sways")
	# Blinking (owner, Nov 18): two blink lids; getting hit squeezes the eyes shut.
	MonsterModel.dazed_sway(model, 0.0)
	var blinks: Array = model.get_meta("blinks", [])
	check_eq(blinks.size(), 2, "a blink lid for each eye")
	if blinks.size() == 2:
		var lid: MeshInstance3D = blinks[0][0]
		MonsterModel.animate(model, 0.0, 1.0, 1.0)  # (between blinks: open)
		var open_basis := lid.basis
		model.set_meta("flinch", 1.0)
		MonsterModel.animate(model, 0.0, 1.0, 1.0)
		check(not lid.basis.is_equal_approx(open_basis), "hit: the eyes squeeze shut")
	_teardown()


## Cave Bat (Nov 18 rebuild): flapping wings, folded wings for roosting, and it hangs upside down by its feet.
func test_bat_wings_and_roost() -> void:
	await _setup()
	var m := _spawn("cave_bat", Vector3(3.0, 0, 0))
	var model := m.model
	check_eq((model.get_meta("wings", []) as Array).size(), 2, "two flapping wings")
	check_eq((model.get_meta("folds", []) as Array).size(), 2, "two folded wings for roosting")
	check(model.has_meta("upright"), "built upright: it hangs by its feet")
	m.set_process(false)
	model.set_meta("roosting", true)
	MonsterModel.animate(model, 0.0, 1.0, 1.0)
	check_near(absf(model.rotation.z), PI, 0.01, "roosting: upside down")
	var f: MeshInstance3D = (model.get_meta("folds") as Array)[0]
	check(f.visible, "roosting: the wings are folded round it")
	var lids: Array = model.get_meta("blinks", [])
	check_eq(lids.size(), 2, "a blink lid for each eye")
	if lids.size() == 2:
		check(not (lids[0][0] as MeshInstance3D).basis.is_equal_approx(lids[0][1]), "asleep: the eyes are shut")
	model.set_meta("roosting", false)
	MonsterModel.animate(model, 0.0, 1.0, 1.0)
	check(not f.visible, "flying: the folded wings are hidden")
	_teardown()



## Rock Snail (owner, Nov 18): it only ever moves forward; to go another way it turns slowly on the spot first.
func test_snail_turns_before_it_moves() -> void:
	await _setup()
	var m := _spawn("rock_snail", Vector3(3.0, 0, 0))
	m.set_physics_process(false)
	m.model.rotation.y = 0.0  # facing -Z
	var start := m.global_position
	var r: Array = m._turn_toward(Vector3(1, 0, 0), 0.1)  # it wants to go +X: a quarter turn away
	check(r[1] == 0.0, "facing away: it doesn't move yet")
	check(m.model.get_meta("turning", false), "it hops in place, turning")
	for i in 40:
		r = m._turn_toward(Vector3(1, 0, 0), 0.1)
	check(r[1] > 0.5, "facing the way now: it sets off")
	var fwd: Vector3 = r[0]
	check(fwd.dot(Vector3(1, 0, 0)) > 0.9, "and it moves the way it faces (forward)")
	check(m.global_position.distance_to(start) < 0.01, "(turning alone never moved it)")
	_teardown()


## Rock Beetles and Cave Bats too (owner, Nov 19: beetles "move side to side", bats "only forward and backward"):
## they turn to face a new way first (faster than the snail), then go forward. Bats sway into curves as they fly.
func test_beetles_and_bats_turn_before_moving() -> void:
	await _setup()
	for kind in ["rock_beetle", "great_rock_beetle", "cave_bat"]:
		var m := _spawn(kind, Vector3(3.0, 0, 0))
		m.set_physics_process(false)
		m.model.rotation.y = 0.0  # facing -Z
		var r: Array = m._turn_toward(Vector3(1, 0, 0), 0.05)  # wants to go +X: a quarter turn away
		check(r[1] == 0.0, "%s: facing away, it doesn't move yet" % kind)
		var steps := 0
		while r[1] < 0.5 and steps < 200:
			r = m._turn_toward(Vector3(1, 0, 0), 0.05)
			steps += 1
		check((r[0] as Vector3).dot(Vector3(1, 0, 0)) > 0.9, "%s: then it goes the way it faces" % kind)
		check(steps * 0.05 < (2.5 if kind == "great_rock_beetle" else 1.5), "%s: a quick turn, not snail-slow (%.1f s)" % [kind, steps * 0.05])
	var bat := _spawn("cave_bat", Vector3(-3.0, 0, 0))
	var ways := {}
	for k in 8:
		bat._clock = k * 0.7
		var w := bat.weave(Vector3(1, 0, 0))
		ways[snappedf(atan2(w.z, w.x), 0.05)] = true
	check(ways.size() >= 3, "a flying bat's path sways (curves), not a dead straight line (%s)" % [ways.keys()])
	_teardown()


## Ragdolls (owner, Nov 18; the beetle first): on death the model falls apart into physics pieces joined at their
## hinges, falls and tumbles, then shrinks away.
func test_beetle_ragdoll_on_death() -> void:
	await _setup()
	var m := _spawn("rock_beetle", Vector3(4.0, 0, 0))
	for i in 5:
		await tree.physics_frame
	var start_y := m.global_position.y
	auth.monsters._ev_remove(m.uid)  # (dies the real way: the manager forgets it, then it goes limp)
	check(m.has_meta("corpse"), "it became a ragdoll")
	if not m.has_meta("corpse"):
		_teardown()
		return
	var body: RigidBody3D = m.get_meta("corpse")
	check(body.get_children().filter(func(c: Node) -> bool: return c is CollisionShape3D).size() >= 1, "one solid body (no joints to shiver)")
	check(int(body.get_meta("relax")) >= 8, "legs spread, mandibles open, feelers droop")
	var y0 := body.global_position.y
	var moved := 0.0
	for i in 90:
		await tree.physics_frame
		moved = maxf(moved, absf(body.global_position.y - y0))
	check(moved > 0.05, "it falls and tumbles (moved %.2f m)" % moved)
	check(body.global_position.y > start_y - 3.0, "it lands on the cave floor, doesn't fall through")
	for i in 120:
		await tree.physics_frame
	check(body.linear_velocity.length() < 0.3 and body.angular_velocity.length() < 0.5, "then it lies still (no shivering)")
	# the legs lie spread out below the shell's middle, never up inside it (owner: "the legs collide with the shell")
	var up_now: Vector3 = (body.global_basis * (body.get_meta("up_local") as Vector3)).normalized()
	var centre: Vector3 = (body.get_children().filter(func(c: Node) -> bool: return c is CollisionShape3D)[0] as Node3D).global_position  # (the shell's middle)
	var into_shell := 0
	for c in body.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("leg"):
			var tip: Vector3 = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb().get_center()
			if (tip - centre).dot(up_now) > 0.0:
				into_shell += 1
	check(into_shell == 0, "no leg turns up into the shell (%d did)" % into_shell)
	# the knee bends (owner's drawing): each lower leg lies flat, pointing out along the ground
	var flat := 0
	var shins := 0
	for c in body.find_children("shin*", "MeshInstance3D", true, false):
		var s := c as MeshInstance3D
		shins += 1
		var along := (s.global_transform * s.get_aabb().get_center()) - s.global_position
		if absf(along.normalized().dot(up_now)) < 0.35:
			flat += 1
	check(shins == 6 and flat == 6, "all six lower legs lie flat (%d of %d)" % [flat, shins])
	_teardown()


## Owner (Nov 18): the snail relaxes and falls over, but his foot stays on the ground (the shell comes off it).
func test_snail_ragdoll_leaves_its_foot() -> void:
	await _setup()
	var m := _spawn("rock_snail", Vector3(4.0, 0, 0))
	for i in 5:
		await tree.physics_frame
	auth.monsters._ev_remove(m.uid)
	check(m.has_meta("corpse"), "the snail became a ragdoll")
	if not m.has_meta("corpse"):
		_teardown()
		return
	var body: RigidBody3D = m.get_meta("corpse")
	var left: Array = body.get_meta("left", [])
	check(left.size() == 1 and String((left[0] as Node).name) == "soft_foot", "his foot is left behind")
	var foot_at: Vector3 = (left[0] as Node3D).global_position if left.size() == 1 else Vector3.ZERO
	var start := body.global_position
	for i in 330:  # (it settles, then its eye stalks flop down)
		await tree.physics_frame
	if left.size() == 1:
		check(is_instance_valid(left[0]) and (left[0] as Node3D).global_position.distance_to(foot_at) < 0.01, "the foot stays where it was, on the ground")
	check(body.global_position.distance_to(start) > 0.03, "the shell falls off it")
	check(body.global_position.y > start.y - 1.5, "and lands on the floor, not through it")
	check(body.linear_velocity.length() < 0.3, "then lies still")
	# his eyes stay on him (owner: they came off his body when he fell) and flop down to the ground
	var stalks := body.find_children("soft_stalk*", "MeshInstance3D", true, false)
	check(stalks.size() == 2 and stalks.all(func(st: Node) -> bool: return String(st.get_parent().name) == "soft_body"), "both eye stalks hang on his soft body")
	check(int(body.get_meta("flopped", 0)) == 4, "the stalks and their upper halves flop down (%d)" % int(body.get_meta("flopped", 0)))
	var floor_y := float(body.get_meta("drape_floor", body.global_position.y))
	check(_settled_clear(body), "his eyes are not under the floor or inside his shell or body: %s" % str(body.get_meta("settle_bad", {})))
	_teardown()


## After the wings or eye stalks settled, no piece pokes into the floor or the body (owner, Nov 18: wing ends vanished
## into the bat; the snail's eyes sank into him). (At most 2 stray points of ~80 per piece: an edge grazing.)
func _settled_clear(body: RigidBody3D) -> bool:
	var bad: Dictionary = body.get_meta("settle_bad", {})
	return not bad.is_empty() and bad.values().all(func(v: int) -> bool: return v <= 2)


## Owner (Nov 18): a dead bat ragdolls too: it drops out of the air, wings limp and spread, eyes shut.
func test_bat_ragdoll_falls_out_of_the_air() -> void:
	await _setup()
	var m := _spawn("cave_bat", Vector3(4.0, 0, 0))
	for i in 5:
		await tree.physics_frame
	m.state = Monster.State.CHASE  # (awake, wings open: asleep it hangs with them folded)
	for i in 3:
		await tree.process_frame  # (waking, it drops out of its roost first: then put it in the air)
	m.global_position = world.maker.find_floor(player.global_position.x + 4.0, player.global_position.z, player.global_position.y + 2.0) + Vector3.UP * 1.5
	# (in flight over the floor: a bat on its own goes off to find a roost)
	for i in 3:
		await tree.process_frame
	auth.monsters._ev_remove(m.uid)
	check(m.has_meta("corpse"), "the bat became a ragdoll")
	if not m.has_meta("corpse"):
		_teardown()
		return
	var body: RigidBody3D = m.get_meta("corpse")
	var start_y := body.global_position.y
	var lowest := body.global_position.y
	for i in 330:  # (it settles, then its wings fall: about 4 s)
		await tree.physics_frame
		lowest = minf(lowest, body.global_position.y)
	check(body.global_position.y > lowest - 0.01 and body.global_position.y > start_y - 3.0, "it lands on the floor, not through it (y %.2f, lowest %.2f, started %.2f)" % [body.global_position.y, lowest, start_y])
	check(body.global_position.y < start_y - 0.3, "it drops out of the air")
	check(body.linear_velocity.length() < 0.3, "then lies still (speed %.2f)" % body.linear_velocity.length())
	# its wings fall onto the floor, every section (owner: "when he dies it sticks out")
	check(int(body.get_meta("draped", 0)) == 6, "both wings drape: arm, middle and outer web (%d)" % int(body.get_meta("draped", 0)))
	var floor_y := float(body.get_meta("drape_floor", body.global_position.y))  # (the physics floor under it: find_floor's guess sat 30 cm lower)
	var up_high := 0
	for c in body.find_children("w*", "MeshInstance3D", true, false):
		var wm := c as MeshInstance3D
		if (String(wm.name).begins_with("wing") or String(wm.name).begins_with("web")) and (wm.global_transform * wm.get_aabb().get_center()).y > floor_y + 0.45:  # (the upper wing may lie over its body)
			up_high += 1
	check(up_high == 0, "no wing section sticks up in the air (%d did)" % up_high)
	check(_settled_clear(body), "no wing piece is under the floor or inside the body: %s" % str(body.get_meta("settle_bad", {})))
	_teardown()


## Owner (Nov 18): everything that dies turns to stone; nothing drops; mine the statue with a pickaxe (hits by size)
## for its stone and loot; left alone it crumbles after a few minutes.
func test_dead_creature_turns_to_stone_and_is_mined() -> void:
	await _setup()
	var m := _spawn("rock_beetle", Vector3(3.0, 0, 0))
	for i in 5:
		await tree.physics_frame
	var drops_before: int = auth._drops.size()
	auth.monsters._kill(m, 1)
	check(auth.monsters.statues.size() == 1, "it became a statue (the host keeps it)")
	check(auth._drops.size() == drops_before, "nothing drops when it dies: the loot is inside the stone")
	var id: int = auth.monsters.statues.keys()[0]
	var st: Dictionary = auth.monsters.statues[id]
	check(st.needed == 4 and st.loot.any(func(d: Array) -> bool: return d[0] == "stone"), "a beetle takes 4 hits and holds stone")
	for i in 420:  # (it falls, lies still, then turns to stone)
		await tree.physics_frame
	var body: Node3D = Statue.nodes.get(id)
	check(is_instance_valid(body) and body.has_meta("statue"), "its body turned to stone")
	if is_instance_valid(body):
		check((body as CollisionObject3D).collision_layer & World.TERRAIN_LAYER != 0, "the stone is solid: a pickaxe can hit it")
		check(body.find_children("*", "MeshInstance3D", true, false).all(func(mi: MeshInstance3D) -> bool: return mi.has_meta("stone")), "stone covers every part")
	# no pickaxe: it bounces off
	var ps: GameAuthority.PlayerState = auth.get_player(1)
	player.global_position = st.pos + Vector3(1.2, 0, 0)
	var saved: Array = ps.inventory.slots.duplicate(true)
	for i in ps.inventory.slots.size():
		if Items.kind(ps.inventory.slots[i].get("id", "")) == "pickaxe":
			ps.inventory.slots[i] = {}
	check(auth.monsters.request_hit_statue(1, id) == "no_tool", "a sword or fist bounces off: pickaxe only")
	ps.inventory.slots = saved
	var r := ""
	for i in 4:
		r = auth.monsters.request_hit_statue(1, id)
	check(r == "dug", "4 pickaxe hits break it")
	check(auth._drops.size() > drops_before, "then its stone and loot drop")
	await tree.process_frame
	check(not Statue.nodes.has(id), "and the stone body is gone")
	# another one, left alone, crumbles
	var m2 := _spawn("cave_bat", Vector3(-3.0, 0, 0))
	for i in 3:
		await tree.physics_frame
	auth.monsters._kill(m2, 1)
	var id2: int = auth.monsters.statues.keys()[0]
	check(auth.monsters.statues[id2].needed == 2, "a bat takes 2 hits")
	auth.monsters.statues[id2].left = 0.01
	for i in 3:
		await tree.physics_frame
	check(not auth.monsters.statues.has(id2) and not Statue.nodes.has(id2), "left alone, it crumbles away")
	_teardown()


## F369 (owner, Nov 19): the first bat killed never turned to stone, but could still be mined. Shot off its high
## roost, it fell metres AFTER the stone began; the stone spreads from a start point, and that point stayed up in the
## air, so it never reached the body. Now the start point falls with it.
func test_bat_shot_down_from_high_turns_to_stone() -> void:
	await _setup()
	var m := _spawn("cave_bat", Vector3(3.0, 0, 0))
	for i in 5:
		await tree.physics_frame
	m.state = Monster.State.CHASE
	for i in 3:
		await tree.process_frame
	var floor_at := world.maker.find_floor(player.global_position.x + 3.0, player.global_position.z, player.global_position.y + 2.0)
	var high := floor_at + Vector3.UP * 6.0
	if world.maker.sdf_at(high) <= 0.0:
		high = floor_at + Vector3.UP * 3.0  # (a low ceiling here: still well above the floor)
	m.global_position = high
	for i in 3:
		await tree.process_frame
	auth.monsters._kill(m, 1)
	var id: int = auth.monsters.statues.keys()[0]
	for i in 420:
		await tree.physics_frame
	var body: Node3D = Statue.nodes.get(id)
	check(is_instance_valid(body) and body.has_meta("statue"), "it became a statue")
	if is_instance_valid(body):
		check(body.global_position.y < high.y - 1.5, "it fell a long way (from %.1f to %.1f)" % [high.y, body.global_position.y])
		var seed: Vector3 = body.get_meta("stone_seed", Vector3.INF)
		check(seed.distance_to(body.global_position) < 0.8, "the stone starts on its body, where it lies (%.2f m away)" % seed.distance_to(body.global_position))
		# Mining it: the sparks go where it lies, not up where it died (owner, Nov 19).
		var where := Statue.where(id, Vector3.INF)
		check(where.distance_to(body.global_position) < 0.8, "mining sparks on the fallen body (%.2f m away)" % where.distance_to(body.global_position))
		check(where.y < high.y - 1.5, "not up in the air where it died")
	_teardown()


## Owner (Nov 19): Claude 1's Cave Spider is a Zone 1 pest: its own model with 8 hinged legs that walk in two tripods,
## eyes that flash; it pounces; it dies into a ragdoll and turns to stone (2 pickaxe hits).
func test_cave_spider_walks_pounces_and_turns_to_stone() -> void:
	await _setup()
	check("cave_spider" in Monsters.SPAWNS.mossy.big and "cave_spider" in Monsters.SPAWNS.mossy.small, "spiders spawn in Zone 1 (Mossy Hollows)")
	check(Monsters.LIST.cave_spider.attacks.any(func(a: Dictionary) -> bool: return a.get("pounce", false) and a.get("lunge", false)), "it has a pounce")
	var m := _spawn("cave_spider", Vector3(3.0, 0, 0))
	for i in 5:
		await tree.physics_frame
	check(m.model.has_meta("forged_root"), "it wears the hand-built spider model")
	var legs: Array = m.model.get_meta("legs", [])
	check_eq(legs.size(), 8, "8 legs")
	var group := {}
	for l in legs:
		group[String((l[0] as Node).name)] = l[2]
	check(group.get("leg_l0") == group.get("leg_r1") and group.get("leg_l0") == group.get("leg_l2") and group.get("leg_l0") == group.get("leg_r3")
		and group.get("leg_r0") == group.get("leg_l1") and group.get("leg_r0") == group.get("leg_r2") and group.get("leg_r0") == group.get("leg_l3")
		and group.get("leg_l0") != group.get("leg_r0"), "tripod walk: l0 r1 l2 r3 step together, then r0 l1 r2 l3")
	check(not m.model.has_meta("tell_mat"), "its eyes flash before a bite (an \"eye\" material was found)")
	var before: Vector3 = (legs[0][0] as Node3D).rotation
	MonsterModel.animate(m.model, 4.0, 1.0, 0.37)
	check((legs[0][0] as Node3D).rotation.distance_to(before) > 0.01, "running moves its legs")
	# kill it: ragdoll, then stone, 2 hits
	auth.monsters._kill(m, 1)
	check(m.has_meta("corpse"), "it falls into a ragdoll")
	var id: int = auth.monsters.statues.keys()[0]
	check_eq(auth.monsters.statues[id].needed, 2, "its statue takes 2 pickaxe hits")
	for i in 420:
		await tree.physics_frame
	var body: Node3D = Statue.nodes.get(id)
	check(is_instance_valid(body) and body.has_meta("statue"), "its body turned to stone")
	if is_instance_valid(body):
		check(body.find_children("*", "MeshInstance3D", true, false).all(func(mi: MeshInstance3D) -> bool: return mi.has_meta("stone")), "stone covers every part, legs too")
	_teardown()


## Owner (Nov 19): ~1,300 "broken number" (NaN) warnings in a game. Every kind, dying in odd poses (upside down,
## nose down, on its side, hit from straight above), must never give any part a broken (not finite) place or turn.
func test_no_broken_numbers_when_creatures_die() -> void:
	await _setup()
	var poses := [Vector3.ZERO, Vector3(0, 0, PI), Vector3(PI / 2, 0, 0), Vector3(-PI / 2, 0, 0), Vector3(0, 0, PI / 2)]
	var bad := []
	var x := 2.0
	for kind in ["rock_beetle", "rock_snail", "cave_bat", "cave_spider", "great_rock_beetle"]:
		for pose in poses:
			var m := _spawn(kind, Vector3(x, 0, 2.0))
			x += 1.5
			await tree.physics_frame
			m.model.rotation = pose
			auth.monsters._kill(m, 1)
	for i in 180:
		await tree.physics_frame
	for n in _all_nodes(tree.root):
		if n is Node3D and n.is_inside_tree():
			var g := (n as Node3D).global_transform
			if not (g.origin.is_finite() and g.basis.x.is_finite() and g.basis.y.is_finite() and g.basis.z.is_finite()):
				bad.append(str(n.get_path()))
	check(bad.is_empty(), "no broken numbers (%d bad: %s)" % [bad.size(), str(bad.slice(0, 4))])
	_teardown()


func _all_nodes(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all_nodes(c))
	return out


## Owner (Nov 18, "juicy hits"): a hit pushes the creature away from you and freezes it for a blink.
func test_a_hit_pushes_and_freezes() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, 1)
	var m := _spawn("rock_beetle", Vector3(1.4, 0, 0))
	m.state = Monster.State.CHASE
	for i in 3:
		await tree.physics_frame
	var away := (m.global_position - player.global_position) * Vector3(1, 0, 1)
	var before := m.global_position
	auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false)
	check(m._stop > 0.0, "it freezes for a blink")
	check(m._knock.dot(away) > 0.0, "and is pushed away from you, not toward you")
	m.set_physics_process(false)  # (only the push: no walking back at you)
	for i in 3:
		m.think(0.05, auth.monsters)
	var moved := (m.global_position - before) * Vector3(1, 0, 1)
	check(moved.dot(away.normalized()) > 0.03, "it slides back a little (%.2f m)" % moved.dot(away.normalized()))
	check(moved.length() < 0.6, "but only a little")
	_teardown()


func test_every_cave_has_its_own_bat_roost() -> void:
	# Owner, Nov 19: one kind of bat per cave, the same every time; the first cave has plain bats.
	var spawn_room := {kind = "spawn", biome = "mossy"}
	check_eq(MonsterManager.roost_variant(42, 0, spawn_room), "", "the first cave has plain bats")
	var kinds := {}
	for i in 40:
		var room := {kind = "cavern", biome = "mossy"}
		var v := MonsterManager.roost_variant(42, i, room)
		check_eq(MonsterManager.roost_variant(42, i, room), v, "a cave keeps its bat kind")
		check(v == "" or Monsters.VARIANTS.has(v), "a real bat kind: %s" % v)
		kinds[v] = true
	check(kinds.size() >= 3, "different caves have different bats")
	check(not Monsters.SPAWNS.mossy.big.has("cave_bat"), "bats come from roosts, not packs")
	check(Recipes.LIST.mace_copper.unlock == "ruin" and Recipes.LIST.spear_copper.unlock == "ruin", "copper gear is found on pages")
	check(Recipes.LIST.pickaxe_copper.unlock is Array, "the copper pickaxe is never down to luck")


func _solid_ground() -> void:  # (the real rock surface: the test viewer only loads the cave's data)
	var solid := VoxelViewer.new()
	solid.view_distance = 24
	player.add_child(solid)
	for i in 900:
		if world.terrain.is_area_meshed(AABB(player.global_position - Vector3.ONE * 8.0, Vector3.ONE * 16.0)):
			break
		await tree.physics_frame


## Owner (F236, said twice: first in F111): "dig a hole, they charge into it and you beat them easily; they should climb
## walls and climb out of holes". A 3 m pit: a beetle and a snail at the bottom, the dwarf at the edge.
func test_beetles_and_snails_climb_out_of_holes() -> void:
	await _setup()
	await _solid_ground()
	var base := player.global_position
	var c := world.maker.find_floor(base.x + 4.0, base.z, base.y + 2.0)
	for k in 7:
		world.apply_dig(c + Vector3.DOWN * (0.5 * k), 1.5, 4)
	for i in 90:
		await tree.physics_frame
	var bottom := c + Vector3.DOWN * 2.8
	player.global_position = world.maker.find_floor(base.x + 7.5, base.z, base.y + 2.0)
	for kind in ["rock_beetle", "rock_snail"]:
		var uid: int = auth.monsters._next_uid
		auth.monsters._ev_spawn(uid, kind, bottom + Vector3.UP * 0.3, false, 0)
		var m := auth.monsters.get_monster(uid)
		for i in 30:
			await tree.physics_frame
		var y0 := m.global_position.y
		check(y0 < c.y - 1.5, "%s: down in the pit (%.1f m below its edge)" % [kind, c.y - y0])
		m.alert(1)
		var top := y0
		for i in 600:  # 10 s
			await tree.physics_frame
			if not is_instance_valid(m):
				break
			top = maxf(top, m.global_position.y)
		check(top > c.y - 1.0, "%s climbed out of the hole (from %.1f to %.1f, edge %.1f)" % [kind, y0, top, c.y])
		if is_instance_valid(m):
			auth.monsters._ev_remove(uid, -1)
	_teardown()


## Owner (F233): "beetles go into each other; they should bump into each other, never overlap".
func test_beetles_bump_never_overlap() -> void:
	await _setup()
	await _solid_ground()
	var a := _spawn("rock_beetle", Vector3(3.0, 0, 0))
	var b := _spawn("rock_beetle", Vector3(3.0, 0, 0.2))
	for m in [a, b]:
		m.alert(1)
	var closest := 99.0
	for i in 240:
		await tree.physics_frame
		if i > 30:
			var d := a.global_position - b.global_position
			closest = minf(closest, Vector2(d.x, d.z).length())
	var r: float = (a._body_shape.shape as CapsuleShape3D).radius
	check(closest > r * 1.6, "two beetles chasing never overlap (closest %.2f m, bodies %.2f m wide)" % [closest, r * 2.0])
	_teardown()


## F416 (owner, Nov 19): a spider's pounce bites but never knocks the dwarf down; the beetles' charges still do.
func test_spider_pounce_doesnt_knock_down() -> void:
	for atk: Dictionary in Monsters.info("cave_spider").attacks:
		check(not MonsterManager.is_charge(atk), "spider %s doesn't knock you down" % atk.name)
	for id in ["rock_beetle", "great_rock_beetle"]:
		var charges: Array = Monsters.info(id).get("attacks", []).filter(func(a: Dictionary) -> bool: return MonsterManager.is_charge(a))
		check(charges.size() > 0, "%s still has a charge that knocks you down" % id)


## F419 (owner, Nov 19): bats wake when you carry a light within 25 m of them in their cave, and keep after you until
## you leave that cave. In the dark they sleep on.
func test_bats_wake_to_light_and_stay_until_you_leave() -> void:
	await _setup()
	var room_i := -1
	for i in world.maker.rooms.size():
		if MonsterManager.inside_room(world.maker.rooms[i], player.global_position):
			room_i = i
	check(room_i >= 0, "the start spot is inside a cave")
	var m := _spawn("cave_bat", Vector3(10, 0, 0), false, MonsterManager.BAT_KEY + room_i)
	var far := _spawn("cave_bat", Vector3(0, 0, 18), false, MonsterManager.BAT_KEY + room_i)
	ps.fuel = 0.0
	for i in 60:
		await tree.physics_frame
	check_eq(m.state, Monster.State.SLEEP, "no light: the bat sleeps on at 10 m")
	ps.fuel = 100.0
	for i in 60:
		await tree.physics_frame
	check(m.state != Monster.State.SLEEP and m.target_peer == 1, "a light 10 m away wakes it (state %d)" % m.state)
	check_eq(far.state, Monster.State.SLEEP, "F428: a light 18 m away no longer wakes a bat")
	for i in 900:  # 15 s: longer than the others give up after
		await tree.physics_frame
	check(m.state != Monster.State.RETURN, "still after you while you're in its cave (state %d)" % m.state)
	var room: Dictionary = world.maker.rooms[room_i]
	player.global_position = room.center + Vector3(room.radii.x * 2.0, 0, 0)
	for i in 180:  # (it may be catching its breath after a bite first: RECOVER)
		await tree.physics_frame
		if m.state == Monster.State.RETURN or m.target_peer == 0:
			break
	check(m.state == Monster.State.RETURN or m.target_peer == 0, "you left the cave: it gives up (state %d)" % m.state)
	_teardown()


## F420 (owner, Nov 19): attacking bats bounced off the ceiling: they cruise 3 m above you, and where the rock is lower
## than that they kept flying up into it. Now they stay under the ceiling.
func test_bats_stay_under_the_ceiling() -> void:
	await _setup()
	ps.fuel = 100.0
	var top := GlowPlacer._march(world.maker, player.global_position + Vector3.UP, Vector3.UP, 30.0)
	check(top != Vector3.INF, "the start cave has a ceiling")
	player.global_position = top + Vector3.DOWN * 2.5  # (floating up near the rock: less than 3 m of room above him)
	var m := _spawn("cave_bat", Vector3(5, 0, 0))
	m.alert(1)
	var bumps := 0
	for i in 600:
		await tree.physics_frame
		if m.is_on_ceiling():
			bumps += 1
	check(bumps < 5, "the bat doesn't keep hitting the ceiling (%d frames touching it)" % bumps)
	_teardown()


## F421 (owner, Nov 19): pack leaders wear no crown; they're a lot bigger instead.
func test_leaders_are_big_without_a_crown() -> void:
	check(Monsters.LEADER.size >= 1.7, "a leader is a lot bigger (×%.1f)" % Monsters.LEADER.size)
	for id in Monsters.LIST:
		var info: Dictionary = Monsters.LIST[id]
		var plain := MonsterModel.build(info.shape, info.color, info.size, false, id, 1)
		var lead := MonsterModel.build(info.shape, info.color, info.size * Monsters.LEADER.size, true, id, 1)
		check_eq(lead.find_children("*", "MeshInstance3D", true, false).size(), plain.find_children("*", "MeshInstance3D", true, false).size(),
			"%s leader has no extra parts (no crown)" % id)
		plain.free()
		lead.free()


func test_sword_star_perks_in_a_real_fight() -> void:
	await _setup()
	ps.inventory.add("sword_stone", 1)
	auth.request_select_slot(1, first_item_slot(ps))
	var m := _spawn("rock_snail", Vector3(1.2, 0, 0), true)  # armor 30, lots of HP
	m.state = Monster.State.CHASE
	var plain := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 2, false)
	m.shell_hits = 0
	m.shell_left = 0.0
	ps.progress.skill_level.sword = 75
	var third := auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 2, false)
	check(third > plain, "Sword ★75: the 3rd combo hit does more (%d > %d)" % [third, plain])
	m.shell_hits = 0
	m.shell_left = 0.0
	check(auth.monsters.request_attack(1, PackedInt32Array([m.uid]), false, 0, false, false, true) > plain - 1, "a jump attack counts too (no ★ jumping yet: same)")
	_teardown()


## F428 (owner, Nov 20: "I spawn and get the bats right away"): the starting cave's roost hangs on its far side,
## never within ROOST_CLEAR m of where you wake up.
func test_no_bat_roost_by_the_start() -> void:
	await _setup()
	var home: Vector3 = world.maker.spawn_point
	var checked := 0
	for i in world.maker.rooms.size():
		var room: Dictionary = world.maker.rooms[i]
		if room.get("kind", "") != "spawn":
			continue  # the big starting cave
		for n in 3:
			for uid in auth.monsters._spawn_roost(room, i):
				var m: Monster = auth.monsters.monsters[uid]
				checked += 1
				check(Vector2(m.global_position.x - home.x, m.global_position.z - home.z).length() >= MonsterManager.ROOST_CLEAR,
					"bat %.0f m from the start" % m.global_position.distance_to(home))
				check(Vector2(m.global_position.x - home.x, m.global_position.z - home.z).length() > Vector2(room.center.x - home.x, room.center.z - home.z).length(),
					"on the far side of the cave")
	check(checked > 0, "the starting cave still has its bats (%d)" % checked)
	_teardown()
