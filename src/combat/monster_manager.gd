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


func _spawn_pack(room_i: int, room: Dictionary) -> Array:
	var maker: CaveMaker = auth.world.maker
	var choices: Array = Monsters.SPAWNS.big if room.big else Monsters.SPAWNS.small
	var kind: String = choices.pick_random()
	match room.get("kind", ""):
		"spawn":
			kind = ["mossnipper", "wickwing"].pick_random()  # weak critters near the start (world doc 3.1)
		"ruin", "great_hall":
			kind = "rustwight"  # sleeping armor guards old ruins
		"nest", "nest_cavern":
			kind = ["mossnipper", "skitterling"].pick_random()
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
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, kind, spot + Vector3.UP * 0.3, has_leader and k == 0, room_i)
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
	_ev_tell.rpc(m.uid, m.target_peer, atk.tell, dmg, atk.reach, atk.parry == "shield", atk.get("knockdown", false), atk.name)


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
		request_attack(multiplayer.get_remote_sender_id(), uids, heavy, combo_step, riposte)


## Host: works out the damage (doc 2.2) for each monster hit. Returns total damage dealt.
func request_attack(peer: int, uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool) -> int:
	var ps := auth.get_player(peer)
	if ps == null:
		return 0
	var item := ps.selected_item()
	var w := Combat.weapon_of(item)
	var tier := maxi(Items.tier(item), 0)
	var wd: Dictionary = Combat.WEAPONS[w]
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
		var dmg := roundi(Combat.damage(w, heavy, tier, m.stats(), combo_step, sit) * mult)
		total += dmg
		m.hp -= dmg
		m.stun.add(Combat.stun_value(w, heavy, tier))
		m.alert(peer)
		alert_pack(m, peer)
		auth.give_xp(peer, 1, "fighting")
		_ev_hit.rpc(uid, dmg)
		if m.hp <= 0.0:
			_kill(m, peer)
		else:
			var entered := m.check_phase()
			if entered.has("summon"):
				boss_summon(m, entered.summon[0], entered.summon[1])
			monster_changed(m)
	return total


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
		var poi: Array = maker.pois_of(b.room)
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
			gifts.append([d[0], d[1]])
		for r in m.data.get("runes", 0):
			var rune := auth.rune_slab.pick_drop("m", [randf(), randf(), randf()])
			if rune != "":
				gifts.append(["rune_" + rune, 1])
		for g in gifts:
			var left: int = ps.inventory.add(g[0], g[1])
			if left > 0:
				auth.spawn_drop(g[0], left, ps.node.global_position + Vector3.UP)
	auth.world_state.bosses_dead.append(m.kind)
	auth._ev_state.rpc(auth.world_state)


func _kill(m: Monster, peer: int) -> void:
	if m.is_boss():
		_boss_drops(m)
	var xp: int = m.data.xp * (Monsters.LEADER.xp if m.leader else 1)
	for pid in auth.players:  # kills give XP to everyone nearby (progression doc 7.2)
		if auth.players[pid].node.global_position.distance_to(m.global_position) < 30.0 or pid == peer:
			auth.give_xp(pid, xp, "fighting")
	for d in ([] if m.is_boss() else m.data.drops):
		var times := 2 if m.leader else 1
		for t in times:
			if randf() < d[2]:
				auth.spawn_drop(d[0], d[1], m.global_position + Vector3.UP * 0.5)
	if m.leader and randf() < 0.1:
		var rune := auth.rune_slab.pick_drop("m", [randf(), randf(), randf()])
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
func _ev_tell(uid: int, target: int, tell: float, dmg: float, reach: float, crushing: bool, kd: bool, attack_name: String) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_tell(tell)
	if target == auth.local_peer_id() and dmg > 0.0:
		_incoming.append({uid = uid, at = _clock + tell, damage = dmg, reach = reach, crushing = crushing, kd = kd, name = attack_name})


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
				result = Combat.defend(hit.damage, def.pressed_ago, def.holding, def.weapon, def.shield, def.tier, hit.crushing)
				me.vitals.take_damage(result.damage)
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


func _in_reach(m: Monster, dwarf: Node3D, reach: float) -> bool:
	var d := m.global_position - dwarf.global_position
	return Vector2(d.x, d.z).length() <= reach + 0.8 and absf(d.y) < 2.5


## We parried: the host fills the monster's stun meter and staggers it.
func ask_parried(uid: int, stun_amount: float) -> void:
	if auth.is_host():
		request_parried(uid, stun_amount)
	else:
		_rpc_parried.rpc_id(1, uid, stun_amount)


@rpc("any_peer", "reliable")
func _rpc_parried(uid: int, stun_amount: float) -> void:
	if auth.is_host():
		request_parried(uid, minf(stun_amount, Combat.STUN_SHIELD_PARRY))


func request_parried(uid: int, stun_amount: float) -> void:
	var m: Monster = monsters.get(uid)
	if m == null:
		return
	m.stun.add(stun_amount)
	if not m.stun.is_stunned():
		m.state = Monster.State.RECOVER  # staggered for a moment
		m._timer = 0.6
	monster_changed(m)


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_spawn(uid: int, kind: String, pos: Vector3, leader: bool, pack: int) -> void:
	var m: Monster = MONSTER_SCRIPT.new()
	m.setup(uid, kind, leader, pos)
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
		m.queue_free()


@rpc("authority", "call_local", "reliable")
func _ev_hp(uid: int, hp: float, stun_frac: float, stunned: bool) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.set_hp(hp, stun_frac, stunned)


@rpc("authority", "call_local", "reliable")
func _ev_hit(uid: int, dmg: int) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		Fx.burst(_root, m.global_position + Vector3.UP * 0.5, Color(1.0, 0.9, 0.7), 6, 2.0)
		Sfx.play("hit_heavy" if dmg >= 20 else "hit", m.global_position)
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
		out.append([m.uid, m.kind, m.global_position, m.leader, m.pack_id, m.hp])
	return out


func load_snapshot(list: Array) -> void:
	for e in list:
		_ev_spawn(e[0], e[1], e[2], e[3], e[4])
		monsters[e[0]].hp = e[5]
