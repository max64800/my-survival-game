class_name MonsterManager
extends Node
## All monsters (Authority/Monsters on every computer).
##  - The HOST runs every monster's brain, spawns packs near players, and decides damage
##    that players deal (request_attack).
##  - Each PLAYER'S OWN computer judges incoming hits on its own dwarf (parry timing is
##    about your own reflexes, so it must be judged where your hands are), then tells the
##    host what happened (parry → the monster gets stunned).

const MONSTER_SCRIPT := preload("res://src/combat/monster.gd")
const SPAWN_NEAR := 60.0  ## spawn a room's pack when a player comes this close
const DESPAWN_FAR := 100.0
const RESPAWN := 600.0  ## a cleared room fills up again after 10 minutes
const POSE_SEND := 0.1
const SPAWN_CHECK := 2.0
const ANIMAL_KEY := 100000  ## animal herds are kept apart from monster packs (room index + this)

signal defended(result: Dictionary)  ## our own dwarf parried/blocked/took a hit (for the HUD)

var auth: GameAuthority
var monsters := {}  ## uid -> Monster
var enabled := false  ## the game turns spawning on (tests leave it off unless they want monsters)
var _root: Node3D
var _next_uid := 1
var _rooms := {}  ## room index -> {alive: [uids], cleared_at: seconds}
var _clock := 0.0
var _pose_timer := 0.0
var _spawn_timer := 0.0
var _incoming: Array[Dictionary] = []  ## hits on OUR dwarf waiting to land: {uid, at, ...}
var _boss_alone := {}  ## boss uid -> seconds with no player within 60 m (resets at 30)
var _block_ok := {}  ## host: like _parry_ok, for Blight-gem blocks
var _ff_ready := {}  ## host: peer -> seconds (clock) when their next friendly-fire hit may count
var _parry_ok := {}  ## host: monster uid -> the player its last swing was aimed at


func _ready() -> void:
	auth = get_parent()
	_root = Node3D.new()
	_root.name = "MonsterBodies"
	add_child(_root)


func player_node(peer: int) -> Node3D:
	var ps := auth.get_player(peer)
	return ps.node if ps else null


func get_monster(uid: int) -> Monster:
	return monsters.get(uid)


static func uid_of(collider: Object) -> int:
	if collider is Node and collider.has_meta("monster_uid"):
		return collider.get_meta("monster_uid")
	return -1


# ================================================================== host loop

func _physics_process(delta: float) -> void:
	_clock += delta
	if auth.is_host():
		_host_step(delta)
	else:
		for m in monsters.values():
			m.puppet_step(delta)
	_judge_incoming()
	_clouds_step(delta)


func _host_step(delta: float) -> void:
	_update_boosts()
	_check_boss_resets(delta)
	for m: Monster in monsters.values():
		if m.is_alive():
			m.think(delta, self)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_CHECK
		if enabled:
			_spawn_and_despawn()
	_pose_timer -= delta
	if _pose_timer <= 0.0 and not multiplayer.get_peers().is_empty() and not monsters.is_empty():
		_pose_timer = POSE_SEND
		var ids := PackedInt32Array()
		var pos := PackedVector3Array()
		var yaw := PackedFloat32Array()
		for m: Monster in monsters.values():
			ids.append(m.uid)
			pos.append(m.global_position)
			yaw.append(m.model.rotation.y)
		_ev_poses.rpc(ids, pos, yaw)


## Pack leaders boost pack-mates within 15 m (doc 6.3). The boost ends the moment the leader dies.
func _update_boosts() -> void:
	var leaders := {}
	for m: Monster in monsters.values():
		if (m.leader or m.is_boss()) and m.is_alive():  # side bosses lead their kind (doc 8.3)
			leaders[m.pack_id] = m
	for m: Monster in monsters.values():
		var l: Monster = leaders.get(m.pack_id)
		m.boosted = l != null and l != m and l.global_position.distance_to(m.global_position) <= Monsters.PACK_BOOST.radius


func _spawn_and_despawn() -> void:
	var maker: CaveMaker = auth.world.maker
	_wake_bosses()
	for i in maker.rooms.size():
		var room: Dictionary = maker.rooms[i]
		if room.get("sealed", false) or room.get("kind", "") in ["shrine", "lair"]:
			continue
		var st: Dictionary = _rooms.get(i, {alive = [], cleared_at = -RESPAWN})
		_rooms[i] = st
		st.alive = st.alive.filter(func(u): return monsters.has(u))
		var near := _nearest_player_dist(room.center)
		if st.alive.is_empty() and near < SPAWN_NEAR and _clock - st.cleared_at >= RESPAWN:
			if not auth.world.is_ready_at(room.center, 4.0):
				continue
			st.alive = _spawn_pack(i, room)
			st.cleared_at = _clock  # (also used as "last spawned")
		elif not st.alive.is_empty() and near > DESPAWN_FAR:
			for u in st.alive:
				_ev_remove.rpc(u)
			st.alive = []
			st.cleared_at = -RESPAWN  # nobody fought them: free to come back
		if room.big or i % 2 == 0:
			_animals_step(i, room, near)


## Cave animals: their own little herd per cavern (and every other room), back 20 min after a hunt.
func _animals_step(i: int, room: Dictionary, near: float) -> void:
	var key := ANIMAL_KEY + i
	var st: Dictionary = _rooms.get(key, {alive = [], cleared_at = -Monsters.ANIMAL_RESPAWN})
	_rooms[key] = st
	st.alive = st.alive.filter(func(u): return monsters.has(u))
	if st.alive.is_empty() and near < SPAWN_NEAR and _clock - st.cleared_at >= Monsters.ANIMAL_RESPAWN:
		if auth.world.is_ready_at(room.center, 4.0):
			st.alive = _spawn_herd(key, room)
			st.cleared_at = _clock
	elif not st.alive.is_empty() and near > DESPAWN_FAR:
		for u in st.alive:
			_ev_remove.rpc(u)
		st.alive = []
		st.cleared_at = -Monsters.ANIMAL_RESPAWN


func _spawn_herd(key: int, room: Dictionary) -> Array:
	var maker: CaveMaker = auth.world.maker
	var herd: Array = Monsters.ANIMALS[room.get("biome", "mossy")]
	if herd.is_empty():
		return []  # cave animals are hidden for now (Monsters.ANIMALS)
	var kind: String = herd.pick_random()
	var info: Dictionary = Monsters.LIST[kind]
	var uids := []
	for k in randi_range(info.pack[0], info.pack[1]):
		var a := randf() * TAU
		var r := randf_range(2.0, minf(room.radii.x, room.radii.z) * 0.6)
		var spot := maker.find_floor(room.center.x + cos(a) * r, room.center.z + sin(a) * r, room.center.y)
		if maker.sdf_at(spot + Vector3.UP) <= 0.0:
			continue
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, kind, spot + Vector3.UP * 0.3, false, key)
		uids.append(uid)
	return uids


func _spawn_pack(room_i: int, room: Dictionary) -> Array:
	var maker: CaveMaker = auth.world.maker
	var biome: String = room.get("biome", "mossy")
	var lists: Dictionary = Monsters.SPAWNS[biome]
	var choices: Array = lists.big if room.big else lists.small
	var kind: String = choices.pick_random()
	# Special rooms (owner's first three, docs/design/monsters-first-three.md).
	if biome == "fungal":
		match room.get("kind", ""):
			"nest", "brood_hollow", "ruin", "silver_vault":
				kind = "great_rock_beetle"
			"lantern_grove":
				kind = "cave_bat"
	else:
		match room.get("kind", ""):
			"spawn":
				kind = "rock_snail"  # slow: near the start you can always walk away
			"ruin", "great_hall", "nest", "nest_cavern":
				kind = "rock_beetle"
	var info: Dictionary = Monsters.LIST[kind]
	var has_leader: bool = randf() < info.get("leader_chance", 0.0) or room.get("kind", "") == "nest"  # nests always have a leader
	var count := randi_range(info.pack[0], info.pack[1]) + (1 if has_leader else 0)
	var uids := []
	for k in count:
		var a := randf() * TAU
		var r := randf_range(2.0, minf(room.radii.x, room.radii.z) * 0.5)
		var spot := maker.find_floor(room.center.x + cos(a) * r, room.center.z + sin(a) * r, room.center.y)
		if maker.sdf_at(spot + Vector3.UP) <= 0.0:
			continue
		var at := spot + Vector3.UP * 0.3
		if info.get("roosts", false):
			# Bats start asleep, hanging from the ceiling right above this spot.
			var ceiling := GlowPlacer._march(maker, spot + Vector3.UP * 1.0, Vector3.UP, 30.0)
			if ceiling == Vector3.INF:
				continue
			at = ceiling + Vector3.DOWN * 0.3
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, kind, at, has_leader and k == 0, room_i, Monsters.roll_variant(biome, randf(), randf()))
		uids.append(uid)
	return uids


func _nearest_player_dist(p: Vector3) -> float:
	var best := INF
	for pid in auth.players:
		best = minf(best, auth.players[pid].node.global_position.distance_to(p))
	return best


## Who does this monster notice? (sight inside your lantern light, hearing) — doc 5.1.
func nearest_noticer(m: Monster) -> int:
	var best := 0
	var best_d := INF
	for pid in auth.players:
		var ps: GameAuthority.PlayerState = auth.players[pid]
		var p: Vector3 = ps.node.global_position
		var d := p.distance_to(m.global_position)
		var lit := ps.fuel > 0.0
		var sight := Monsters.SIGHT if lit else Monsters.SIGHT_DARK
		if m.data.get("likes_light", false):
			sight = 25.0 if lit else 0.0
		var running: bool = ps.node is CharacterBody3D and Vector2(ps.node.velocity.x, ps.node.velocity.z).length() > 5.0
		var hear := Monsters.HEAR_RUN if running else Monsters.HEAR_WALK
		if m.state == Monster.State.SLEEP:
			sight = 4.0
			hear = 4.0
		if d > maxf(sight, hear) or d >= best_d:
			continue
		if d > hear and not _can_see(m.global_position + Vector3.UP * 0.6, p + Vector3.UP):
			continue
		best = pid
		best_d = d
	return best


func _can_see(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, World.TERRAIN_LAYER)
	return _root.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func alert_pack(m: Monster, peer: int) -> void:
	for o: Monster in monsters.values():
		if o != m and o.pack_id == m.pack_id and o.global_position.distance_to(m.global_position) < 20.0:
			o.alert(peer)


## The host starts an attack: everyone sees the tell, the target's computer judges the hit.
## A boss calls for help: monsters crawl out around it and join its pack.
func boss_summon(m: Monster, kind: String, count: int) -> void:
	for i in count:
		var a := randf() * TAU
		var p := m.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(2.5, 5.0)
		var spot: Vector3 = auth.world.maker.find_floor(p.x, p.z, m.global_position.y + 2.0)
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, kind, spot + Vector3.UP * 0.3, false, m.pack_id)
		var s: Monster = monsters.get(uid)
		if s:
			s.alert(m.target_peer)


func send_tell(m: Monster, atk: Dictionary) -> void:
	var dmg: float = atk.damage * m.damage_mult()
	var buildup: Dictionary = atk.get("buildup", {}).duplicate()
	var v: Dictionary = Monsters.VARIANTS.get(m.variant, {})
	if dmg > 0.0 and not v.is_empty():
		dmg += v.get("extra_damage", 0)
		for k in v.get("buildup", {}):
			buildup[k] = buildup.get(k, 0.0) + v.buildup[k]
	# Amber skin: its heaviest attack can only be parried with a shield (doc 7.1).
	var crushing: bool = atk.parry == "shield" or (m.variant == "amber" and atk.damage >= _heaviest(m))
	_ev_tell.rpc(m.uid, m.target_peer, atk.tell, dmg, atk.reach, crushing, atk.get("knockdown", false), atk.name, buildup)


func _heaviest(m: Monster) -> float:
	var best := 0.0
	for a in m.attack_options():
		best = maxf(best, a.damage)
	return best


func monster_changed(m: Monster) -> void:
	_ev_hp.rpc(m.uid, m.hp, m.stun.fraction(), m.stun.is_stunned())


# ================================================================== players attacking

## Our dwarf's swing landed: ask the host to hurt these monsters.
func ask_attack(uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool) -> void:
	if auth.is_host():
		request_attack(auth.local_peer_id(), uids, heavy, combo_step, riposte)
	else:
		_rpc_attack.rpc_id(1, uids, heavy, combo_step, riposte)


@rpc("any_peer", "reliable")
func _rpc_attack(uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool) -> void:
	if auth.is_host():
		var unique := PackedInt32Array()
		for u in uids:
			if not unique.has(u) and unique.size() < 8:
				unique.append(u)
		request_attack(multiplayer.get_remote_sender_id(), unique, heavy, clampi(combo_step, 0, 9), riposte)


## Host: works out the damage (doc 2.2) for each monster hit. Returns total damage dealt.
func request_attack(peer: int, uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool) -> int:
	var ps := auth.get_player(peer)
	if ps == null:
		return 0
	var item := ps.selected_item()
	var w := Combat.weapon_of(item)
	var tier := maxi(Items.tier(item), 0)
	var wd: Dictionary = Combat.WEAPONS[w]
	var gb := Gems.bonus(ps.inventory.get_slot(ps.selected_slot))
	var elem := {}
	for e in ["fire", "frost", "poison"]:
		if gb.has(e):
			elem[e] = gb[e]
	var buff: float = gb.get("keen", 0.0) + (gb.get("bash", 0.0) if w == "shield" else 0.0)
	var total := 0
	var n := 0
	var max_targets := max_targets_for(w)
	for uid in uids:
		var m: Monster = monsters.get(uid)
		if m == null or not m.is_alive():
			continue
		if ps.node.global_position.distance_to(m.global_position) > wd.reach + 2.0:
			continue  # too far: ignore (stops cheating and lag weirdness)
		n += 1
		if n > max_targets:
			break
		var sneak: bool = m.state in [Monster.State.IDLE, Monster.State.WANDER, Monster.State.SLEEP]
		var crush := heavy and m.stun.take_crush()
		var sit := Combat.situation(sneak, m.stun.is_stunned(), crush, riposte)
		var mult := 0.6 if (w == "axe" and n == 2) else 1.0
		var dmg := roundi(Combat.damage(w, heavy, tier, m.stats(), combo_step, sit, 0.0, 0.0, buff + auth.damage_boost(ps, m.kind), elem) * mult)
		total += dmg
		_gem_buildup(m, gb)
		_hurt_monster(m, peer, dmg, Combat.stun_value(w, heavy, tier) * (1.0 + gb.get("stun", 0.0)))
	auth.heal(peer, total * gb.get("leech", 0.0))
	return total


## Ember/Rime/Blight gems in a weapon add buildup on every hit.
func _gem_buildup(m: Monster, gb: Dictionary) -> void:
	for k in {"burn": "burn", "chill": "chill", "poisoned": "poison"}:
		if gb.has(k):
			m.add_buildup({"burn": "burn", "chill": "chill", "poisoned": "poison"}[k], gb[k])


## Host: one hit lands on a monster (sword, bolt...).
func _hurt_monster(m: Monster, peer: int, dmg: int, stun_amount: float) -> void:
	# Rock Beetle: its back is soft (owner: charge, sidestep, hit it from behind).
	var back: float = m.data.get("soft_back", 0.0)
	var hitter: Node3D = player_node(peer)
	if back > 0.0 and hitter:
		var facing := -Basis(Vector3.UP, m.model.rotation.y).z
		var from := (hitter.global_position - m.global_position) * Vector3(1, 0, 1)
		if from.length() > 0.01 and facing.dot(from.normalized()) < -0.25:
			dmg = roundi(dmg * back)
			_ev_note.rpc(m.uid, "Weak spot!")
	# Rock Snail: hiding in its shell = 90% less damage; every 3rd hit makes it hide.
	var shell: Dictionary = m.data.get("shell_hide", {})
	if not shell.is_empty():
		if m.shell_left > 0.0:
			dmg = maxi(1, roundi(dmg * (1.0 - shell.cut)))
		else:
			m.shell_hits += 1
			if m.shell_hits >= shell.hits:
				m.shell_hits = 0
				m.shell_left = shell.seconds
				monster_shell(m, true)
	m.hp -= dmg
	m.last_hitter = peer
	m.stun.add(stun_amount)
	m.alert(peer)
	alert_pack(m, peer)
	auth.give_xp(peer, 1, "fighting")
	_ev_hit.rpc(m.uid, dmg)
	if m.hp <= 0.0:
		_kill(m, peer)
	else:
		var entered := m.check_phase()
		if entered.has("summon"):
			boss_summon(m, entered.summon[0], entered.summon[1])
		monster_changed(m)


# ================================================================== friendly fire (doc 2.7)

## Our swing (or bolt) hit a friend. Half damage as if they had no armor, half elemental buildup,
## never stun or knockdown.
func ask_hit_friend(target: int, heavy: bool, bolt: String = "", dist: float = 0.0) -> void:
	if auth.is_host():
		request_hit_friend(auth.local_peer_id(), target, heavy, bolt, dist)
	else:
		_rpc_hit_friend.rpc_id(1, target, heavy, bolt, dist)


@rpc("any_peer", "reliable")
func _rpc_hit_friend(target: int, heavy: bool, bolt: String, dist: float) -> void:
	if auth.is_host() and is_finite(dist):
		request_hit_friend(multiplayer.get_remote_sender_id(), target, heavy, bolt, dist)


func request_hit_friend(peer: int, target: int, heavy: bool, bolt: String = "", dist: float = 0.0) -> int:
	var ps := auth.get_player(peer)
	var tp := auth.get_player(target)
	if not auth.friendly_fire() or ps == null or tp == null or peer == target or tp.dying:
		return 0
	var item := ps.selected_item()
	var w := Combat.weapon_of(item)
	var tier := maxi(Items.tier(item), 0)
	if _clock < _ff_ready.get(peer, 0.0):
		return 0  # faster than the weapon can swing: not a real hit
	var gap := ps.node.global_position.distance_to(tp.node.global_position)
	var dmg := 0.0
	var buildup := {}
	if bolt != "":
		if w != "crossbow" or not Combat.BOLTS.has(bolt) or gap > Combat.BOLT_MAX + 2.0:
			return 0
		_ff_ready[peer] = _clock + Combat.RELOAD[clampi(tier, 0, 4)] * 0.8  # one bolt per reload
		dmg = Combat.shot_damage(heavy, tier, bolt, {armor = 0}, gap)
		for k in BOLT_BUILDUP.get(bolt, {}):
			buildup[k] = BOLT_BUILDUP[bolt][k] * Combat.FRIENDLY_FIRE
	else:
		if w == "crossbow" or gap > Combat.WEAPONS[w].reach + 1.5:
			return 0
		dmg = Combat.damage(w, heavy, tier, {armor = 0})
		_ff_ready[peer] = _clock + Combat.WEAPONS[w].light_speed * 0.8
	var dealt := roundi(dmg * Combat.FRIENDLY_FIRE)
	auth.hurt(target, dealt, buildup)
	return dealt


# ================================================================== crossbow (doc 3.6)

## Our bolt flew from `from` to `point` (and hit monster `uid`, or -1). The host judges it.
func ask_shoot(bolt: String, aimed: bool, uid: int, from: Vector3, point: Vector3) -> void:
	if auth.is_host():
		request_shoot(auth.local_peer_id(), bolt, aimed, uid, from, point)
	else:
		_rpc_shoot.rpc_id(1, bolt, aimed, uid, from, point)


@rpc("any_peer", "reliable")
func _rpc_shoot(bolt: String, aimed: bool, uid: int, from: Vector3, point: Vector3) -> void:
	if auth.is_host() and from.is_finite() and point.is_finite():
		request_shoot(multiplayer.get_remote_sender_id(), bolt, aimed, uid, from, point)


## Host: takes the bolt, shows its flight to everyone, and hurts the monster it hit.
## shortcut: the bolt hits instantly (no flight time or drop); upgrade if long shots feel too easy.
func request_shoot(peer: int, bolt: String, aimed: bool, uid: int, from: Vector3, point: Vector3) -> int:
	var ps := auth.get_player(peer)
	if ps == null or Combat.weapon_of(ps.selected_item()) != "crossbow" or not Combat.BOLTS.has(bolt):
		return 0
	if from.distance_to(ps.node.global_position) > 6.0 or not ps.inventory.remove(bolt, 1):
		return 0
	var dist := from.distance_to(point)
	if dist > Combat.BOLT_MAX:
		point = from + (point - from).normalized() * Combat.BOLT_MAX
		dist = Combat.BOLT_MAX
	_ev_shot.rpc(from, point, bolt)
	var b: Dictionary = Combat.BOLTS[bolt]
	var dealt := 0
	var m: Monster = monsters.get(uid)
	var near_line := false
	if m:
		var seg := point - from
		var t := clampf((m.global_position - from).dot(seg) / maxf(seg.length_squared(), 0.001), 0.0, 1.0)
		near_line = (from + seg * t).distance_to(m.global_position + Vector3.UP * 0.5 * m.data.size) < 1.5 + m.data.size
		# shortcut: no host-side rock check (the host may not have that rock loaded); add one if cheating shows up.
	if m and m.is_alive() and near_line and m.global_position.distance_to(point) < 2.0 + m.data.size * 1.5:
		var tier := maxi(Items.tier(ps.selected_item()), 0)
		var gb := Gems.bonus(ps.inventory.get_slot(ps.selected_slot))  # crossbow gems ride on every bolt
		var elem := {}
		for e in ["fire", "frost", "poison"]:
			if gb.has(e):
				elem[e] = gb[e]
		var sneak: bool = m.state in [Monster.State.IDLE, Monster.State.WANDER, Monster.State.SLEEP]
		var sit := Combat.situation(sneak, m.stun.is_stunned(), false, false)
		dealt = Combat.shot_damage(aimed, tier, bolt, m.stats(), dist, sit, gb.get("keen", 0.0) + auth.damage_boost(ps, m.kind), elem)
		var stun_amount: float = (Combat.stun_value("crossbow", aimed, tier) + b.get("stun", 0.0)) * (1.0 + gb.get("stun", 0.0))
		for k in BOLT_BUILDUP.get(bolt, {}):
			m.add_buildup(k, BOLT_BUILDUP[bolt][k])
		_gem_buildup(m, gb)
		_hurt_monster(m, peer, dealt, stun_amount)
		auth.heal(peer, dealt * gb.get("leech", 0.0))
	if b.has("glow"):
		_ev_glow_bolt.rpc(point, b.glow)
	elif randf() < 0.5:
		auth.spawn_drop(bolt, 1, point + (from - point).normalized() * 0.4)  # half the bolts can be picked up again
	return dealt


const BOLT_BUILDUP := {"bolt_ember": {burn = 40.0}, "bolt_rime": {chill = 40.0}, "bolt_blight": {poison = 50.0}}


## Everyone: a bolt flies (a thin dart that zips along the line).
@rpc("authority", "call_local", "reliable")
func _ev_shot(from: Vector3, to: Vector3, bolt: String) -> void:
	var dart := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.04, 0.04, 0.5)
	dart.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Items.color(bolt)
	mat.emission_enabled = true
	mat.emission = Items.color(bolt)
	mat.emission_energy_multiplier = 0.8
	dart.material_override = mat
	_root.add_child(dart)
	dart.global_position = from
	if from.distance_to(to) > 0.1:
		dart.look_at_from_position(from, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	var tw := dart.create_tween()
	tw.tween_property(dart, "global_position", to, from.distance_to(to) / Combat.BOLT_SPEED)
	tw.tween_callback(dart.queue_free)
	Sfx.play("clink", to, -10.0, 1.4)


## Everyone: a glow bolt stuck here and lights a 6 m circle for a minute.
@rpc("authority", "call_local", "reliable")
func _ev_glow_bolt(at: Vector3, seconds: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.9, 1.0)
	l.omni_range = 6.0
	l.light_energy = 1.6
	_root.add_child(l)
	l.global_position = at
	get_tree().create_timer(seconds).timeout.connect(l.queue_free)


## How many monsters one swing can hit: axe cleaves 2, spear pokes through 2, great weapons sweep.
static func max_targets_for(w: String) -> int:
	if Combat.WEAPONS[w].get("sweep", false) or w == "mace_2h":
		return 99
	return 2 if w in ["axe", "spear"] else 1


## Bosses wake when a player comes near their cavern (and the main boss when someone digs into its lair).
func _wake_bosses() -> void:
	var maker: CaveMaker = auth.world.maker
	for id in Monsters.BOSSES:
		var b: Dictionary = Monsters.BOSSES[id]
		var poi: Array = maker.pois_of(b.room, b.biome)
		if poi.is_empty():
			continue
		var at: Vector3 = poi[0].pos
		var near := _nearest_player_dist(at)
		if b.boss == "side" and near < 30.0 and not auth.world_state.lairs_found.has(id):
			auth.world_state.lairs_found.append(id)  # a raid source from now on (doc 8.6)
			auth._ev_state.rpc(auth.world_state)
		if auth.world_state.bosses_dead.has(id) or _boss_alive(id):
			continue
		var wake := 25.0 if b.boss == "main" else 35.0
		if near < wake and auth.world.is_ready_at(at, 4.0):
			var uid := _next_uid
			_next_uid += 1
			_ev_spawn.rpc(uid, id, at + Vector3.UP * 0.5, false, 1000 + poi[0].id)


## Host: brings a main boss back at its altar (after an offering).
func summon_boss(id: String) -> bool:
	var b: Dictionary = Monsters.BOSSES.get(id, {})
	if b.is_empty() or _boss_alive(id):
		return false
	var poi: Array = auth.world.maker.pois_of(b.room, b.biome)
	if poi.is_empty():
		return false
	var uid := _next_uid
	_next_uid += 1
	_ev_spawn.rpc(uid, id, poi[0].pos + Vector3.UP * 0.5, false, 1000 + poi[0].id)
	return true


## During a main boss fight its lair walls can't be dug (combat doc 8.1): no tunnelling around it.
func lair_locked(p: Vector3) -> bool:
	var maker: CaveMaker = auth.world.maker
	for m: Monster in monsters.values():
		if not m.is_boss() or m.data.boss != "main" or (m.target_peer == 0 and m.hp >= m.max_hp()):
			continue  # no fight going on
		var lair := maker.lair_poi(m.data.biome)
		if lair.is_empty():
			continue
		var room: Dictionary = maker.rooms[lair.room]
		var q: Vector3 = (p - room.center) / (room.radii + Vector3.ONE * 5.0)
		if q.length() < 1.0:
			return true
	return false


func _boss_alive(id: String) -> bool:
	for m: Monster in monsters.values():
		if m.kind == id:
			return true
	return false


## Bosses don't give up the chase, but if every player is 60+ m away for 30 s they heal up and go home.
func _check_boss_resets(delta: float) -> void:
	for m: Monster in monsters.values():
		if not m.is_boss():
			continue
		if _nearest_player_dist(m.global_position) > Monsters.BOSS_RESET_DISTANCE:
			_boss_alone[m.uid] = _boss_alone.get(m.uid, 0.0) + delta
			if _boss_alone[m.uid] >= Monsters.BOSS_RESET_TIME and m.hp < m.max_hp():
				m.hp = m.max_hp()
				m.phase = 0
				m.state = Monster.State.RETURN
				m.target_peer = 0
				monster_changed(m)
		else:
			_boss_alone[m.uid] = 0.0


## Boss drops (doc 8.1): every player within 60 m gets their own copy.
func _boss_drops(m: Monster) -> void:
	for pid in auth.players:
		var ps: GameAuthority.PlayerState = auth.players[pid]
		if ps.node.global_position.distance_to(m.global_position) > Monsters.BOSS_DROP_RANGE:
			continue
		var gifts := []
		for d in m.data.drops:
			if randf() < d[2]:
				gifts.append([d[0], d[1]])
		if m.data.has("epic_choice") and (not auth.world_state.bosses_dead.has(m.kind) or randf() < 0.2):
			gifts.append([Gems.item_id(m.data.epic_choice.pick_random()), 1])  # first kill: one epic gem; re-summons: 20%
		for r in m.data.get("runes", 0):
			var rune := auth.rune_slab.pick_drop(GameAuthority.rune_biome_at(m.global_position), [randf(), randf(), randf(), randf()])
			if rune != "":
				gifts.append(["rune_" + rune, 1])
		for g in gifts:
			var left: int = ps.inventory.add(g[0], g[1])
			if left > 0:
				auth.spawn_drop(g[0], left, ps.node.global_position + Vector3.UP)
	if not auth.world_state.bosses_dead.has(m.kind):
		auth.world_state.bosses_dead.append(m.kind)
	auth._ev_state.rpc(auth.world_state)


func _kill(m: Monster, peer: int) -> void:
	var dc: Dictionary = m.data.get("death_cloud", {})
	if not dc.is_empty() and not m.ailments.has("burn"):  # a fire kill burns the spores away
		spawn_cloud(m.global_position + Vector3.UP * 0.5, dc.radius, dc.time, dc.rate, 0.0)
	if m.is_boss():
		_boss_drops(m)
	var xp: int = m.data.xp * (Monsters.LEADER.xp if m.leader else 1) * (Monsters.VARIANT_STATS.xp if m.variant != "" else 1)
	if m.variant != "":
		var v: Dictionary = Monsters.VARIANTS[m.variant]
		auth.spawn_drop(v.crystal, v.count, m.global_position + Vector3.UP * 0.7)
		if randf() < 0.15:
			auth.spawn_drop(Gems.item_id(Gems.VARIANT_GEM[m.variant]), 1, m.global_position + Vector3.UP * 0.9)
		if m.variant == "violet" and CaveMaker.biome_at(m.global_position) == "fungal" and randf() < 0.005:
			auth.spawn_drop(Gems.item_id("shiftstep"), 1, m.global_position + Vector3.UP)
	for pid in auth.players:  # kills give XP to everyone nearby (progression doc 7.2)
		if auth.players[pid].node.global_position.distance_to(m.global_position) < 30.0 or pid == peer:
			auth.give_xp(pid, xp, m.data.get("skill", "fighting"))
	for d in ([] if m.is_boss() else m.data.drops):
		var times := 2 if m.leader else 1
		for t in times:
			if randf() < d[2]:
				auth.spawn_drop(d[0], d[1], m.global_position + Vector3.UP * 0.5)
	if m.leader and randf() < 0.1:
		var rune := auth.rune_slab.pick_drop(GameAuthority.rune_biome_at(m.global_position), [randf(), randf(), randf(), randf()])
		if rune != "":
			auth.spawn_drop("rune_" + rune, 1, m.global_position + Vector3.UP * 0.6)
	var room: Dictionary = _rooms.get(m.pack_id, {})
	if not room.is_empty():
		room.alive.erase(m.uid)
		if room.alive.is_empty():
			room.cleared_at = _clock
	_ev_remove.rpc(m.uid)


# ================================================================== monsters attacking us

## Everyone: a monster starts an attack. Only the target's own computer judges it.
@rpc("authority", "call_local", "reliable")
func _ev_tell(uid: int, target: int, tell: float, dmg: float, reach: float, crushing: bool, kd: bool, attack_name: String, buildup: Dictionary = {}) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_tell(tell)
	if auth.is_host():
		_parry_ok[uid] = target  # only this player may parry this swing, once
		_block_ok[uid] = target
	if target == auth.local_peer_id() and dmg > 0.0:
		_incoming.append({uid = uid, at = _clock + tell, damage = dmg, reach = reach, crushing = crushing, kd = kd, name = attack_name, buildup = buildup})


# ================================================================== spore clouds

const CLOUD_COLOR := Color(0.62, 0.72, 0.4, 0.16)
var clouds: Array[Dictionary] = []  ## {pos, radius, left, rate, dps, node}


## Host: a spore cloud appears (everyone sees it; each player's own computer feels it).
## by_player: a Spore Bomb. It poisons monsters, and friends only at half (friendly fire).
func spawn_cloud(pos: Vector3, radius: float, seconds: float, rate: float, dps: float, by_player: bool = false) -> void:
	_ev_cloud.rpc(pos, radius, seconds, rate, dps, by_player)


@rpc("authority", "call_local", "reliable")
func _ev_cloud(pos: Vector3, radius: float, seconds: float, rate: float, dps: float, by_player: bool = false) -> void:
	# A drifting cloud of soft see-through puffs (particles). One shared material, so fading
	# the whole cloud is one change (see _clouds_step).
	var mi := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = Fire._soft_tex()
	mat.proximity_fade_enabled = true  # soft where it meets the ground
	mat.proximity_fade_distance = 0.8
	mat.albedo_color = CLOUD_COLOR if rate > 0.0 else Color(0.85, 0.75, 0.95, CLOUD_COLOR.a)
	var p := GPUParticles3D.new()
	p.amount = 26
	p.lifetime = 3.0
	p.preprocess = 3.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(-Vector3.ONE * radius * 2.0, Vector3.ONE * radius * 4.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius * 0.55
	pm.gravity = Vector3(0, 0.05, 0)
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.5
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.scale_min = 0.8
	pm.scale_max = 1.3
	var swell := Curve.new()
	swell.add_point(Vector2(0.0, 0.3))
	swell.add_point(Vector2(0.3, 1.0))
	swell.add_point(Vector2(1.0, 0.7))
	var st := CurveTexture.new()
	st.curve = swell
	pm.scale_curve = st
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2.ONE * radius * 1.1
	q.material = mat
	p.draw_pass_1 = q
	mi.add_child(p)
	mi.set_meta("mat", mat)
	_root.add_child(mi)
	mi.global_position = pos
	clouds.append({pos = pos, radius = radius, left = seconds, total = seconds, rate = rate, dps = dps, node = mi, by_player = by_player})
	Sfx.play("dig_soft", pos, -6.0, 0.6)


func _clouds_step(delta: float) -> void:
	if clouds.is_empty():
		return
	var me := auth.get_player(auth.local_peer_id())
	var still: Array[Dictionary] = []
	for c in clouds:
		c.left -= delta
		if c.left <= 0.0:
			c.node.queue_free()
			continue
		var mat: StandardMaterial3D = c.node.get_meta("mat")
		mat.albedo_color.a = CLOUD_COLOR.a * clampf(c.left / 1.0, 0.0, 1.0)  # fades out in its last second
		c.node.scale = Vector3.ONE * (0.6 + 0.4 * minf(1.0, (c.total - c.left) / 0.5))  # puffs up
		if c.by_player and auth.is_host():
			for m: Monster in monsters.values():
				if m.is_alive() and m.global_position.distance_to(c.pos) < c.radius + 0.5:
					m.add_buildup("poison", c.rate * delta)
					m.hp -= c.dps * delta
					if m.hp <= 0.0:
						_kill(m, 0)
		var friendly: float = (Combat.FRIENDLY_FIRE if auth.friendly_fire() else 0.0) if c.by_player else 1.0
		if friendly > 0.0 and me and me.node and not me.dying and me.node.global_position.distance_to(c.pos) < c.radius + 0.3:
			var ward := (1.0 - me.vitals.buff_total("spore_resist")) * friendly  # Spore Ward Stew halves it
			if _has_mask(me):
				ward *= 0.5  # Spore Mask
			me.vitals.ailments.add("poison", c.rate * delta * ward)
			if c.dps > 0.0:
				me.vitals.take_damage(c.dps * delta * ward)
		still.append(c)
	clouds = still


func _has_mask(ps: GameAuthority.PlayerState) -> bool:
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "spore_mask":
			return true
	return false


func _judge_incoming() -> void:
	if _incoming.is_empty():
		return
	var me := auth.get_player(auth.local_peer_id())
	if me == null:
		_incoming.clear()
		return
	var still: Array[Dictionary] = []
	for hit in _incoming:
		if hit.at > _clock:
			still.append(hit)
			continue
		var m: Monster = monsters.get(hit.uid)
		var dwarf := me.node
		var result := {result = "miss", damage = 0.0, stun = 0.0}
		if m and m.is_alive() and not m.stun.is_stunned() and _in_reach(m, dwarf, hit.reach):
			if dwarf.has_method("is_invulnerable") and dwarf.is_invulnerable():
				result = {result = "dodge", damage = 0.0, stun = 0.0}
			else:
				var def: Dictionary = dwarf.call("defense_state") if dwarf.has_method("defense_state") else {holding = false, pressed_ago = -1.0, weapon = "fists", shield = false, tier = 0}
				var sb := Gems.bonus(Gems.shield_slot(me.inventory)) if def.shield else {}
				result = Combat.defend(hit.damage, def.pressed_ago, def.holding, def.weapon, def.shield, def.tier, hit.crushing, sb)
				var swinging: bool = dwarf.get("fight") != null and dwarf.fight._busy > 0.0
				if result.result == "hit" and swinging:
					result.damage *= 1.0 - Gems.bonus(me.inventory.get_slot(me.selected_slot)).get("guard", 0.0)  # Bulwark gem
				if result.result == "block" and sb.has("block_poison"):
					ask_blocked(hit.uid)
				me.vitals.take_damage(result.damage)
				# Poison/fire/frost buildup: all of it on a hit, half through a block, none on a parry.
				var share: float = {"hit": 1.0, "block": 0.5}.get(result.result, 0.0)
				for kind in hit.get("buildup", {}):
					var started := me.vitals.ailments.add(kind, hit.buildup[kind] * share)
					if started != "":
						result.ailment = started
				if result.stamina > 0.0:
					me.vitals.stamina = maxf(0.0, me.vitals.stamina - result.stamina)
					if me.vitals.stamina <= 0.0 and dwarf.has_method("guard_break"):
						dwarf.guard_break()
				if result.result == "hit" and hit.kd and dwarf.has_method("knock_down"):
					dwarf.knock_down()
				if result.result == "parry" and dwarf.has_method("got_parry"):
					dwarf.got_parry()
		result.name = hit.name
		match result.result:
			"parry": Sfx.ui("parry", -2.0)
			"block": Sfx.ui("block", -4.0)
			"hit": Sfx.ui("hit_heavy" if result.damage >= 15 else "hit", -2.0)
		defended.emit(result)
		if result.result == "parry":
			ask_parried(hit.uid, result.stun)
	_incoming = still


## We blocked a hit with a Blight-gem shield: poison the attacker (host).
func ask_blocked(uid: int) -> void:
	if auth.is_host():
		request_blocked(uid, auth.local_peer_id())
	else:
		_rpc_blocked.rpc_id(1, uid)


@rpc("any_peer", "reliable")
func _rpc_blocked(uid: int) -> void:
	if auth.is_host():
		request_blocked(uid, multiplayer.get_remote_sender_id())


func request_blocked(uid: int, peer: int) -> void:
	if _block_ok.get(uid, -1) != peer:
		return  # only a swing that was aimed at you, once
	_block_ok.erase(uid)
	var m: Monster = monsters.get(uid)
	var ps := auth.get_player(peer)
	if m == null or ps == null or ps.node.global_position.distance_to(m.global_position) > 8.0:
		return
	var sb := Gems.bonus(Gems.shield_slot(ps.inventory))
	if sb.has("block_poison"):
		m.add_buildup("poison", sb.block_poison)


func _in_reach(m: Monster, dwarf: Node3D, reach: float) -> bool:
	var d := m.global_position - dwarf.global_position
	return Vector2(d.x, d.z).length() <= reach + 0.8 and absf(d.y) < 2.5


## We parried: the host fills the monster's stun meter and staggers it.
func ask_parried(uid: int, stun_amount: float) -> void:
	if auth.is_host():
		request_parried(uid, stun_amount, auth.local_peer_id())
	else:
		_rpc_parried.rpc_id(1, uid, stun_amount)


@rpc("any_peer", "reliable")
func _rpc_parried(uid: int, stun_amount: float) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if auth.is_host() and is_finite(stun_amount) and _parry_ok.get(uid, -1) == sender:
		_parry_ok.erase(uid)
		request_parried(uid, stun_amount, sender)


## A perfect parry: stun the monster. Shield gems of the parrying player add their extras (doc 4.2).
func request_parried(uid: int, stun_amount: float, peer: int = 0) -> void:
	var m: Monster = monsters.get(uid)
	if m == null:
		return
	var ps := auth.get_player(peer)
	if ps:
		var sb := Gems.bonus(Gems.shield_slot(ps.inventory))
		stun_amount = clampf(stun_amount, 0.0, Combat.STUN_SHIELD_PARRY) * (1.0 + sb.get("parry_stun", 0.0))
		if sb.has("parry_burn"):
			m.add_buildup("burn", sb.parry_burn)
		if sb.has("parry_chill"):
			m.add_buildup("chill", sb.parry_chill)
		auth.heal(peer, sb.get("parry_heal", 0.0))
	m.stun.add(stun_amount)
	if not m.stun.is_stunned():
		m.state = Monster.State.RECOVER  # staggered for a moment
		m._timer = 0.6
	monster_changed(m)


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_spawn(uid: int, kind: String, pos: Vector3, leader: bool, pack: int, variant: String = "") -> void:
	var m: Monster = MONSTER_SCRIPT.new()
	m.setup(uid, kind, leader, pos, variant)
	m.pack_id = pack
	_root.add_child(m)
	m.global_position = pos
	monsters[uid] = m
	_next_uid = maxi(_next_uid, uid + 1)


@rpc("authority", "call_local", "reliable")
func _ev_remove(uid: int) -> void:
	var m: Monster = monsters.get(uid)
	monsters.erase(uid)
	if m:
		Fx.burst(_root, m.global_position + Vector3.UP * 0.4, m.data.color, 18, 3.0)
		Sfx.play("death", m.global_position)
		m.die_visual()  # tips over and sinks away (only looks), then frees itself


@rpc("authority", "call_local", "reliable")
func _ev_hp(uid: int, hp: float, stun_frac: float, stunned: bool) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.set_hp(hp, stun_frac, stunned)


## Host: the snail pulled into its shell (or came out). Everyone sees it.
func monster_shell(m: Monster, hidden: bool) -> void:
	_ev_shell.rpc(m.uid, hidden)


@rpc("authority", "call_local", "reliable")
func _ev_shell(uid: int, hidden: bool) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_shell(hidden)
		if hidden:
			_float_number(m.global_position + Vector3.UP * 1.3, "Hides in its shell!")


## A short word floating up over a monster ("Weak spot!").
@rpc("authority", "call_local", "reliable")
func _ev_note(uid: int, text: String) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		_float_number(m.global_position + Vector3.UP * 1.6, text)


@rpc("authority", "call_local", "reliable")
func _ev_hit(uid: int, dmg: int) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		Fx.burst(_root, m.global_position + Vector3.UP * 0.5, Color(1.0, 0.9, 0.7), 6, 2.0)
		Sfx.play("hit_heavy" if dmg >= 20 else "hit", m.global_position)
		m.hit_flash()
		_float_number(m.global_position + Vector3.UP * 1.4, str(dmg))


@rpc("authority", "unreliable_ordered")
func _ev_poses(ids: PackedInt32Array, pos: PackedVector3Array, yaw: PackedFloat32Array) -> void:
	for i in ids.size():
		var m: Monster = monsters.get(ids[i])
		if m:
			m.set_net(pos[i], yaw[i])


func _float_number(at: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 48
	l.pixel_size = 0.005
	l.outline_size = 10
	l.no_depth_test = true
	l.modulate = Color(1.0, 0.9, 0.5)
	_root.add_child(l)
	l.global_position = at
	var t := l.create_tween()
	t.tween_property(l, "global_position", at + Vector3.UP * 0.8, 0.8)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	t.tween_callback(l.queue_free)


# ================================================================== late joiners

func snapshot() -> Array:
	var out := []
	for m: Monster in monsters.values():
		out.append([m.uid, m.kind, m.global_position, m.leader, m.pack_id, m.hp, m.variant])
	return out


func load_snapshot(list: Array) -> void:
	for e in list:
		_ev_spawn(e[0], e[1], e[2], e[3], e[4], e[6] if e.size() > 6 else "")
		monsters[e[0]].hp = e[5]
