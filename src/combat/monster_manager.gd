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
const BAT_KEY := 200000  ## each cave's sleeping bat roost (room index + this)
const DUNGEON_KEY := 300000  ## a dungeon room's creatures (DUNGEON_KEY + dungeon index * 100 + room group)
const DUNGEON_FIRE_ICE := 0.125  ## 1 in 8 dungeon creatures is a fiery red or icy blue one (owner, Nov 20: gems.md)
const DUNGEON_NEAR := 30.0  ## a dungeon room's creatures come when a player is this close (its rooms are close together)
const DUNGEON_RESPAWN := 3600.0  ## creatures move back into a cleared dungeon room after an hour (decisions: "3 in-game
                                 ## days", assumed; there is no day clock yet)
const BATS := [4, 6]  ## bats per roost (owner, Nov 19: "5 frost ones, or 5 ember ones")
const ROOST_CLEAR := 30.0  ## metres: no bat roosts this close to where you wake up (F428, owner Nov 20)

signal defended(result: Dictionary)  ## our own dwarf parried/blocked/took a hit (for the HUD)
## Host: a dungeon room's creatures came (cleared = false) or were all killed (true) (Mossgate's loot door, owner Nov 20).
signal dungeon_room(dungeon_id: String, room: String, cleared: bool)

var auth: GameAuthority
var monsters := {}  ## uid -> Monster
var dungeon_only := false  ## the dungeon test: only the dungeon's own creatures (no cave packs or roosts)
var _dgroups = null  ## the dungeons' creatures by room: [{key, center, list: [[kind, local pos, leader]], d}] (made once)
var enabled := false  ## the game turns spawning on (tests leave it off unless they want monsters)
var _root: Node3D
var _next_uid := 1
var _rooms := {}  ## room index -> {alive: [uids], cleared_at: seconds}
var _clock := 0.0
var _pose_timer := 0.0
var _spawn_timer := 0.0
var _incoming: Array[Dictionary] = []  ## hits on OUR dwarf waiting to land: {uid, at, ...}
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


const FAR_AWAY := 50.0  ## metres: further than this from every dwarf, a calm creature thinks less often
const FAR_EVERY := 4    ## ...every 4th physics step
var _far_turn := 0


func _host_step(delta: float) -> void:
	_update_boosts()
	_statues_step(delta)
	_far_turn = (_far_turn + 1) % FAR_EVERY
	for m: Monster in monsters.values():
		if m.is_alive():
			# Far from every dwarf and not fighting: it thinks every 4th step with the time saved up (owner, Nov 19:
			# 5 FPS, the creatures' step was too slow). Nobody sees it that far away in the caves.
			if m.state in [Monster.State.IDLE, Monster.State.WANDER, Monster.State.SLEEP, Monster.State.RETURN] 					and (m.uid + _far_turn) % FAR_EVERY != 0 and _nearest_player_dist(m.global_position) > FAR_AWAY:
				m.far_dt += delta
				continue
			m.think(delta + m.far_dt, self)
			m.far_dt = 0.0
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
		if m.leader and m.is_alive():
			leaders[m.pack_id] = m
	for m: Monster in monsters.values():
		var l: Monster = leaders.get(m.pack_id)
		m.boosted = l != null and l != m and l.global_position.distance_to(m.global_position) <= Monsters.PACK_BOOST.radius


func _spawn_and_despawn() -> void:
	var maker: CaveMaker = auth.world.maker
	for g in _dungeon_groups():
		_group_step(g.key, g, _nearest_player_dist(g.center), DUNGEON_RESPAWN, _spawn_dungeon_group.bind(g), DUNGEON_NEAR)
		# Tell the dungeon when a room's creatures came, or were all killed (not when they just left: nobody near).
		var st: Dictionary = _rooms[g.key]
		var now: int = st.alive.size()
		var was: int = g.get("was", 0)
		g.was = now
		if was == 0 and now > 0:
			dungeon_room.emit(String(g.d.id), String(g.room), false)
		elif was > 0 and now == 0 and float(st.cleared_at) > -DUNGEON_RESPAWN:
			dungeon_room.emit(String(g.d.id), String(g.room), true)
	for i in maker.rooms.size():
		if dungeon_only:
			break
		var room: Dictionary = maker.rooms[i]
		if room.get("sealed", false) or room.get("kind", "") in ["shrine", "hollow"]:
			continue
		var near := _nearest_player_dist(room.center)
		# Every cave has a roost of sleeping bats, the first one too: they only wake if you come close or shoot them.
		_group_step(BAT_KEY + i, room, near, RESPAWN, _spawn_roost.bind(i))
		var st: Dictionary = _rooms.get(i, {alive = [], cleared_at = -RESPAWN})
		_rooms[i] = st
		st.alive = st.alive.filter(func(u): return monsters.has(u))
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


## A group that lives in a room apart from its monster pack (the bat roost): spawns when a player comes
## near, leaves when everyone is far away, and comes back `respawn` seconds after it was wiped out.
## `spawn` gets the room and returns the new uids.
func _group_step(key: int, room: Dictionary, near: float, respawn: float, spawn: Callable, reach := SPAWN_NEAR) -> void:
	var st: Dictionary = _rooms.get(key, {alive = [], cleared_at = -respawn})
	_rooms[key] = st
	st.alive = st.alive.filter(func(u): return monsters.has(u) and (monsters[u] as Monster).is_alive())  # (only the living count: Mossgate's loot door, Nov 20)
	if st.alive.is_empty() and near < reach and _clock - st.cleared_at >= respawn:
		if auth.world.is_ready_at(room.center, 4.0):
			st.alive = spawn.call(room)
			st.cleared_at = _clock
	elif not st.alive.is_empty() and near > DESPAWN_FAR:
		for u in st.alive:
			_ev_remove.rpc(u)
		st.alive = []
		st.cleared_at = -respawn


## The dungeons' creatures (owner's first play, Nov 19: "no monsters"): the plan's creatures, grouped by the room they
## stand in. Each room's group comes like a cave pack (when someone is near, host-made, sent to everyone) and moves
## back in DUNGEON_RESPAWN after it was wiped out. The plan's big beetle is the Pack Hall's leader (a rock beetle
## leader: bigger and tougher, and it makes its pack hit harder while it lives).
func _dungeon_groups() -> Array:
	if _dgroups != null:
		return _dgroups
	_dgroups = []
	var maker: CaveMaker = auth.world.maker
	for di in maker.dungeons.size():
		var d: Dictionary = maker.dungeons[di]
		var by := {}
		for c in DungeonBuild.load_plan(String(d.id)).get("creatures", []):
			var local := Vector3(c.pos[0], c.pos[1], c.pos[2])
			var room := DungeonMap.space_at(d, DungeonMap.to_world(d, Vector3(local.x, 1.0, local.z)))
			if not by.has(room):
				by[room] = []
			by[room].append([String(c.kind), local])
		var gi := 0
		for room in by:
			var mid := Vector3.ZERO
			for c in by[room]:
				mid += c[1]
			mid /= float(by[room].size())
			_dgroups.append({key = DUNGEON_KEY + di * 100 + gi, center = DungeonMap.to_world(d, Vector3(mid.x, 1.0, mid.z)),
				list = by[room], d = d, room = room})
			gi += 1
	return _dgroups


func _spawn_dungeon_group(_room: Dictionary, g: Dictionary) -> Array:
	var uids := []
	for c in g.list:
		var kind: String = c[0]
		var leader := kind == "great_rock_beetle"
		if leader:
			kind = "rock_beetle"
		if not Monsters.LIST.has(kind):
			continue
		var local: Vector3 = c[1]
		var at := DungeonMap.to_world(g.d, Vector3(local.x, 0.55, local.z))  # on the floor boards
		if Monsters.LIST[kind].get("roosts", false):
			# Bats hang asleep from the ceiling right above their spot (root wood or the natural rock).
			var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP, at + Vector3.UP * 12.0, World.TERRAIN_LAYER)
			var hit := _root.get_world_3d().direct_space_state.intersect_ray(q)
			at = (hit.position as Vector3) + Vector3.DOWN * 0.3 if not hit.is_empty() else DungeonMap.to_world(g.d, local)
		var uid := _next_uid
		_next_uid += 1
		var variant: String = ["red", "blue"].pick_random() if randf() < DUNGEON_FIRE_ICE else ""
		_ev_spawn.rpc(uid, kind, at, leader, g.key, variant)
		var mon: Monster = monsters.get(uid)
		if mon:  # (it stays in its room and only notices you there: Monster.may_step, nearest_noticer)
			mon.dungeon = g.d
			mon.dungeon_room = String(g.room)
		uids.append(uid)
	print("DUNGEON_MONSTERS %s: %d in the %s" % [g.d.id, uids.size(), g.room])
	return uids


## Which bats roost in room `i` (owner, Nov 19): one kind per cave, the same every visit and on every computer.
## The first cave has plain bats; the others pick plain or one of the biome's crystal kinds (Ember, Rime, ...).
static func roost_variant(maker_seed: int, i: int, room: Dictionary) -> String:
	if room.get("kind", "") == "spawn":
		return ""
	var kinds: Array = [""] + Monsters.VARIANT_CHANCE.get(room.get("biome", "mossy"), [0.0, {}])[1].keys()
	return kinds[posmod(hash([maker_seed, i]), kinds.size())]


## A roost of 4-6 sleeping bats hanging from the ceiling of room `i`, all the same kind.
func _spawn_roost(room: Dictionary, i: int) -> Array:
	var maker: CaveMaker = auth.world.maker
	var variant := roost_variant(maker.seed, i, room)
	var uids := []
	# F428 (owner, Nov 20: "I spawn and get the bats right away"): in the starting cave the roost hangs on the far side
	# of the cave from where you come in (the wake-up room), and never within ROOST_CLEAR m of where you wake up.
	var base: Vector3 = room.center
	var home: Vector3 = maker.spawn_point
	var flat := Vector2(room.center.x - home.x, room.center.z - home.z)
	if room.get("kind", "") == "spawn" or flat.length() < maxf(room.radii.x, room.radii.z) + 10.0:
		var away := Vector3(flat.x, 0.0, flat.y).normalized() if flat.length() > 0.5 else Vector3.FORWARD
		base = room.center + away * minf(room.radii.x, room.radii.z) * 0.55
	for k in randi_range(BATS[0], BATS[1]):
		var a := randf() * TAU
		var r := randf_range(1.0, minf(room.radii.x, room.radii.z) * 0.35)  # close together, like a real roost
		var spot := maker.find_floor(base.x + cos(a) * r, base.z + sin(a) * r, base.y)
		if maker.sdf_at(spot + Vector3.UP) <= 0.0 or Vector2(spot.x - home.x, spot.z - home.z).length() < ROOST_CLEAR:
			continue
		var ceiling := GlowPlacer._march(maker, spot + Vector3.UP * 1.0, Vector3.UP, 30.0)
		if ceiling == Vector3.INF:
			continue
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, "cave_bat", ceiling + Vector3.DOWN * 0.3, false, BAT_KEY + i, variant)
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
			"ruin", "great_hall", "nest", "nest_cavern", "outpost":   # (the Fallen Outpost's cavern: beetles guard it)
				kind = "rock_beetle"
	# The Copper Deeps are guarded (F115): always rock beetles, a bigger pack, always with a leader.
	var deeps := false
	for d in maker.deeps:
		if d.room == room_i:
			deeps = true
	if deeps:
		kind = "rock_beetle"
	var info: Dictionary = Monsters.LIST[kind]
	var has_leader: bool = randf() < info.get("leader_chance", 0.0) or room.get("kind", "") == "nest" or deeps  # nests always have a leader
	var count := randi_range(info.pack[0], info.pack[1]) + (1 if has_leader else 0) + (1 if deeps else 0)
	if room.get("kind", "") == "spawn":
		count = randi_range(3, 4)  # a few gentle snails in the first cave (owner, Nov 19); no leader
		has_leader = false
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


## A dwarf flying with the dev fly key is left alone by every monster (owner, Nov 17).
static func ignores(node: Node) -> bool:
	return node is Dwarf and (node as Dwarf).dev_fly


## Who does this monster notice? (sight inside your lantern light, hearing) — doc 5.1.
func nearest_noticer(m: Monster) -> int:
	var best := 0
	var best_d := INF
	for pid in auth.players:
		var ps: GameAuthority.PlayerState = auth.players[pid]
		if ignores(ps.node):
			continue
		var p: Vector3 = ps.node.global_position
		if not m.dungeon.is_empty() and DungeonMap.space_at(m.dungeon, p + Vector3.UP) != m.dungeon_room:
			continue  # (a dungeon creature only notices you in its own room: owner, Nov 20, the bats woke early)
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
		if lit and d <= m.data.get("wake_light", 0.0) and d < best_d and in_cave(m, p):
			best = pid  # (F419: a light wakes bats anywhere in their cave, seen or not)
			best_d = d
			continue
		if d > maxf(sight, hear) or d >= best_d:
			continue
		if d > hear and not _can_see(m.global_position + Vector3.UP * 0.6, p + Vector3.UP):
			continue
		best = pid
		best_d = d
	return best


## Is `p` still inside the cave monster `m` lives in (a roost's room, a little roomier than its shape for the tunnel
## mouths)? Monsters without a cave of their own: always true.
const CAVE_MARGIN := 1.3
func in_cave(m: Monster, p: Vector3) -> bool:
	if m.pack_id < BAT_KEY or auth.world == null or auth.world.maker == null:
		return true
	var rooms: Array = auth.world.maker.rooms
	var i := m.pack_id - BAT_KEY
	if i >= rooms.size():
		return true
	return inside_room(rooms[i], p, CAVE_MARGIN)


static func inside_room(room: Dictionary, p: Vector3, scale := 1.0) -> bool:
	var r: Vector3 = room.radii * scale
	var d: Vector3 = p - room.center
	return Vector3(d.x / r.x, d.y / r.y, d.z / r.z).length() <= 1.0


func _can_see(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, World.TERRAIN_LAYER)
	return _root.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func alert_pack(m: Monster, peer: int) -> void:
	for o: Monster in monsters.values():
		if o != m and o.pack_id == m.pack_id and o.global_position.distance_to(m.global_position) < 20.0:
			o.alert(peer)


## The host starts an attack: everyone sees the tell, the target's computer judges the hit.
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
	# A charge reaches far while it winds up, but it only hits if the monster really gets to you
	# (F111: it was hitting from 9 m away): at the end it counts as touching range.
	var reach: float = atk.reach if not atk.get("lunge", false) else float(m.data.get("size", 1.0)) * 0.6 + 0.8
	_ev_tell.rpc(m.uid, m.target_peer, atk.tell, dmg, reach, crushing, atk.get("knockdown", false), atk.name, buildup,
		is_charge(atk), atk.get("shield_stops", false))


## A charge (a beetle running into you) knocks you down and shoves you (F234). A spider's pounce is a lunge too, but
## a small one: it only bites (owner, Nov 19, F416: "spiders shouldn't knock you down").
static func is_charge(atk: Dictionary) -> bool:
	return atk.get("lunge", false) and not atk.get("pounce", false)


func _heaviest(m: Monster) -> float:
	var best := 0.0
	for a in m.attack_options():
		best = maxf(best, a.damage)
	return best


func monster_changed(m: Monster) -> void:
	_ev_hp.rpc(m.uid, m.hp, m.stun.fraction(), m.stun.is_stunned())


# ================================================================== players attacking

## Our dwarf's swing landed: ask the host to hurt these monsters.
## airborne = our dwarf was in the air (Jumping ★75: jump attacks).
func ask_attack(uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool, airborne: bool = false) -> void:
	if auth.is_host():
		request_attack(auth.local_peer_id(), uids, heavy, combo_step, riposte, false, airborne)
	else:
		_rpc_attack.rpc_id(1, uids, heavy, combo_step, riposte, airborne)


@rpc("any_peer", "reliable")
func _rpc_attack(uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool, airborne: bool = false) -> void:
	if auth.is_host():
		var unique := PackedInt32Array()
		for u in uids:
			if not unique.has(u) and unique.size() < 8:
				unique.append(u)
		request_attack(multiplayer.get_remote_sender_id(), unique, heavy, clampi(combo_step, 0, 9), riposte, false, airborne)


## Host: works out the damage (doc 2.2) for each monster hit. Returns total damage dealt.
## spin = the Whirlwind perk: a heavy hit on everything around you, no target limit.
func request_attack(peer: int, uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool, spin: bool = false, airborne: bool = false) -> int:
	var ps := auth.get_player(peer)
	if ps == null:
		return 0
	var item := ps.selected_item()
	var w := Combat.weapon_of(item)
	var tier := maxi(Items.tier(item), 0)
	var wd: Dictionary = Combat.WEAPONS[w]
	var gb := Gems.bonus(ps.inventory.get_slot(ps.hand_slot()))
	var elem := {}
	for e in ["fire", "frost", "poison"]:
		if gb.has(e):
			elem[e] = gb[e]
	var buff: float = gb.get("keen", 0.0) + (gb.get("bash", 0.0) if w == "shield" else 0.0)
	var total := 0
	var n := 0
	var max_targets := 99 if spin else max_targets_for(w) + ps.progress.extra_targets(w)  # Axe ★50, Spear ★50
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
		var mult := 0.6 if (w == "axe" and n >= 2) else 1.0
		var dist: float = ps.node.global_position.distance_to(m.global_position)
		var star: float = ps.progress.star_damage_bonus(w, {combo_step = combo_step, riposte = riposte, stunned = m.stun.is_stunned(),
			shelled = float(m.stats().get("armor", 0.0)) >= 20.0, airborne = airborne,
			tip = dist >= wd.reach * ps.progress.reach_mult(w) * 0.8})  # skills.md ★ perks
		var dmg := roundi(Combat.damage(w, heavy, tier, _pierced(ps, m, w), combo_step, sit, 0.0, Upgrades.bonus(ps.inventory.get_slot(ps.hand_slot())), buff + auth.damage_boost(ps, m.kind) + ps.progress.weapon_damage_bonus(w) + _perk_buff(ps, peer, m, w) + star, elem) * mult)
		if riposte and ps.progress.riposte_crits(w):  # Sword ★100: a perfect parry's counter is a critical
			dmg = roundi(dmg * Combat.CRIT_MULT)
			_ev_note.rpc(m.uid, "Critical!")
		elif not Controls.robot and randf() < Combat.crit_chance(w):  # now and then a critical hit (owner F137; never in tests: they need exact numbers)
			dmg = roundi(dmg * Combat.CRIT_MULT)
			_ev_note.rpc(m.uid, "Critical!")
		total += dmg
		_gem_buildup(m, gb)
		var stun: float = Combat.stun_value(w, heavy, tier) * (1.0 + gb.get("stun", 0.0)) * (ps.progress.heavy_stun_mult() if heavy else 1.0) * ps.progress.skill_stun_mult(w)
		if Progression.weapon_skill(w) == "mace" and ps.progress.has_star("mace", 75) and float(m.stats().get("armor", 0.0)) >= 20.0:
			stun *= 1.25  # Mace ★75: armored enemies stagger
		if heavy and Progression.weapon_skill(w) == "warhammer" and ps.progress.has_star("warhammer", 100):
			stun += 999.0  # Warhammer ★100: the slam knocks them down
		if not heavy and Progression.weapon_skill(w) == "spear" and ps.progress.has_star("spear", 25):
			var away := (m.global_position - ps.node.global_position) * Vector3(1, 0, 1)
			if away.length() > 0.01:
				m.knock(away.normalized() * 3.0)  # Spear ★25: a poke pushes them back
		_hurt_monster(m, peer, dmg, stun)
	auth.heal(peer, total * gb.get("leech", 0.0))
	if heavy and Progression.weapon_skill(w) == "axe" and ps.progress.has_star("axe", 100) and n > 0:
		auth.give_stamina(peer, 6.0 * mini(n, max_targets))  # Axe ★100: a heavy sweep gives stamina back per enemy
	if total > 0:
		auth.wear_slot(ps, ps.hand_slot())  # a swing that hit something wears the weapon once
	return total


## Perk damage on top (owner's tree, Nov 19): Warrior's Grip, Steady Aim, Berserker, Pack Hunters.
func _perk_buff(ps: GameAuthority.PlayerState, peer: int, m: Monster, w: String) -> float:
	var b := ps.progress.perk_damage_bonus(w)
	if ps.low_health and ps.progress.perk_rank("berserker") > 0:
		b += 0.20
	var r := ps.progress.perk_rank("pack_hunters")
	if r > 0:
		for other in m.hit_by:
			if other != peer and _clock - m.hit_by[other] <= 5.0:
				b += 0.05 * r
				break
	return b


## The monster's stats with part of its armor ignored (Armor Breaker perk, Mace skill, Crossbow ★100).
func _pierced(ps: GameAuthority.PlayerState, m: Monster, w: String = "") -> Dictionary:
	var st := m.stats()
	var pierce := minf(0.9, ps.progress.armor_pierce() + ps.progress.skill_armor_pierce(w))
	if pierce > 0.0:
		st = st.duplicate()
		st.armor = st.get("armor", 0.0) * (1.0 - pierce)
	return st


## Whirlwind perk: spin and hit every living monster within 3.5 m.
func whirlwind(peer: int) -> int:
	var ps := auth.get_player(peer)
	if ps == null:
		return 0
	var uids := PackedInt32Array()
	for m: Monster in monsters.values():
		if m.is_alive() and m.global_position.distance_to(ps.node.global_position) <= 3.5:
			uids.append(m.uid)
	return request_attack(peer, uids, true, 0, false, true)


## Ember/Rime/Blight gems in a weapon add buildup on every hit.
## Bog Jade / Forge Garnet / Frost Sapphire in a weapon: a chance on every hit to add a whole stack.
func _gem_buildup(m: Monster, gb: Dictionary) -> void:
	for k in ["poison", "burn", "chill"]:
		if randf() < gb.get(k + "_chance", 0.0):
			m.add_buildup(k, Ailments.FULL)


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
	# Rock Snail: hiding in its shell = 90% less damage; it hides when its health drops to half, and again at 10%.
	var shell: Dictionary = m.data.get("shell_hide", {})
	if not shell.is_empty() and m.shell_left > 0.0:
		dmg = maxi(1, roundi(dmg * (1.0 - shell.cut)))
	m.hp -= dmg
	if not shell.is_empty() and m.shell_left <= 0.0 and m.hp > 0.0 and m.shell_hits < shell.at.size() 			and m.hp <= m.max_hp() * float(shell.at[m.shell_hits]):
		while m.shell_hits < shell.at.size() and m.hp <= m.max_hp() * float(shell.at[m.shell_hits]):
			m.shell_hits += 1  # (a big hit past both marks uses both: it hides once)
		m.shell_left = shell.seconds
		monster_shell(m, true)
	m.last_hitter = peer
	m.hit_by[peer] = _clock
	m.stun.add(stun_amount)
	m.alert(peer)
	alert_pack(m, peer)
	var hitter_ps := auth.get_player(peer)
	if hitter_ps:
		auth.give_xp(peer, 1, Progression.weapon_skill(Combat.weapon_of(hitter_ps.selected_item())))
	# A push away from the hitter (owner, Nov 18, "juicy hits"): stronger for big hits, weaker for big creatures.
	var from := hitter.global_position if hitter else m.global_position
	if hitter and not m.shell_shut and m.shell_left <= 0.0:  # (a snail in his shell is a heavy stone)
		var away := (m.global_position - from) * Vector3(1, 0, 1)
		if away.length() > 0.01:
			m.knock(away.normalized() * clampf(1.8 + dmg * 0.06, 1.8, 5.0) / maxf(1.0, float(m.data.get("size", 1.0))))
	_ev_hit.rpc(m.uid, dmg, from, peer)
	if m.hp <= 0.0:
		_kill(m, peer)
	else:
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
		var gb := Gems.bonus(ps.inventory.get_slot(ps.hand_slot()))  # crossbow gems ride on every bolt
		var elem := {}
		for e in ["fire", "frost", "poison"]:
			if gb.has(e):
				elem[e] = gb[e]
		var sneak: bool = m.state in [Monster.State.IDLE, Monster.State.WANDER, Monster.State.SLEEP]
		var sit := Combat.situation(sneak, m.stun.is_stunned(), false, false)
		dealt = Combat.shot_damage(aimed, tier, bolt, _pierced(ps, m, "crossbow"), dist, sit, gb.get("keen", 0.0) + auth.damage_boost(ps, m.kind) + ps.progress.weapon_damage_bonus("crossbow") + _perk_buff(ps, peer, m, "crossbow"), elem)
		var stun_amount: float = (Combat.stun_value("crossbow", aimed, tier) + b.get("stun", 0.0)) * (1.0 + gb.get("stun", 0.0))
		for k in BOLT_BUILDUP.get(bolt, {}):
			m.add_buildup(k, BOLT_BUILDUP[bolt][k])
		_gem_buildup(m, gb)
		_hurt_monster(m, peer, dealt, stun_amount)
		auth.heal(peer, dealt * gb.get("leech", 0.0))
	if b.has("glow"):
		_ev_glow_bolt.rpc(point, b.glow)
	elif dealt > 0 and ps.progress.has_star("crossbow", 75) and randf() < 0.3:
		var back := ps.inventory.add(bolt, 1)  # Crossbow ★75: the bolt comes back to you
		if back > 0:
			auth.spawn_drop(bolt, back, ps.node.global_position + Vector3.UP)
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


func _kill(m: Monster, peer: int) -> void:
	var dc: Dictionary = m.data.get("death_cloud", {})
	if not dc.is_empty() and not m.ailments.has("burn"):  # a fire kill burns the spores away
		spawn_cloud(m.global_position + Vector3.UP * 0.5, dc.radius, dc.time, dc.rate, 0.0)
	var xp: int = m.data.xp * (Monsters.LEADER.xp if m.leader else 1) * (Monsters.VARIANT_STATS.xp if m.variant != "" else 1)
	# Everything that dies turns to stone (owner, Nov 18): nothing drops now; its loot is locked inside the statue and
	# comes out when you mine it (with its stone, and 1 in 50 a gem).
	var loot := []
	if m.variant != "":
		var v: Dictionary = Monsters.VARIANTS[m.variant]
		loot.append([v.crystal, v.count])
		if randf() < 0.15 * (1.0 + (auth.get_player(peer).progress.perk_rank("monster_scavenger") * 0.25 if auth.get_player(peer) else 0.0)):
			loot.append([Gems.item_id(Gems.VARIANT_GEM[m.variant]), 1])
		if m.variant == "violet" and CaveMaker.biome_at(m.global_position) == "fungal" and randf() < 0.005:
			loot.append([Gems.item_id("shiftstep"), 1])
	for pid in auth.players:  # kills give XP to everyone nearby (progression doc 7.2)
		if auth.players[pid].node.global_position.distance_to(m.global_position) < 30.0 or pid == peer:
			var pr: Progression = auth.players[pid].progress
			var was := pr.hunter_rank(m.kind)
			pr.add_kill(m.kind)  # kill counts: everyone who shares the XP shares the kill
			if pr.hunter_rank(m.kind) > was:
				auth.tell(pid, "%s! +%d%% damage against %s." % [Progression.hunter_title(m.kind, was + 1),
					roundi(Progression.HUNTER_BONUS[was + 1] * 100), Monsters.LIST[m.kind].name])
			auth.give_xp(pid, xp, Progression.weapon_skill(Combat.weapon_of(auth.players[pid].selected_item())))
	var killer := auth.get_player(peer)
	if killer:
		auth.heal(peer, killer.progress.perk_rank("last_swing") * 3.0)  # Last Swing
	var more := (killer.progress.extra_drop_chance() + auth.boost_total(killer, "extra_drops")) if killer else 0.0  # Monster Scavenger, food
	for d in m.data.drops:
		var times := (2 if m.leader else 1) + (1 if randf() < more else 0)
		for t in times:
			if randf() < d[2]:
				loot.append([d[0], d[1]])
	if m.leader and randf() < 0.1:
		var rune := auth.rune_slab.pick_drop(GameAuthority.rune_biome_at(m.global_position), [randf(), randf(), randf(), randf()])
		if rune != "":
			loot.append(["rune_" + rune, 1])
	var room: Dictionary = _rooms.get(m.pack_id, {})
	if not room.is_empty():
		room.alive.erase(m.uid)
		if room.alive.is_empty():
			room.cleared_at = _clock
	_ev_remove.rpc(m.uid, add_statue(m, loot))


# ================================================================== monsters attacking us

## Everyone: a monster starts an attack. Only the target's own computer judges it.
@rpc("authority", "call_local", "reliable")
func _ev_tell(uid: int, target: int, tell: float, dmg: float, reach: float, crushing: bool, kd: bool, attack_name: String, buildup: Dictionary = {}, charge: bool = false, shield_stops: bool = false) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_tell(tell, attack_name, player_node(target))
	if auth.is_host():
		_parry_ok[uid] = target  # only this player may parry this swing, once
		_block_ok[uid] = target
	if target == auth.local_peer_id() and dmg > 0.0:
		_incoming.append({uid = uid, at = _clock + tell, damage = dmg, reach = reach, crushing = crushing, kd = kd, name = attack_name, buildup = buildup, charge = charge,
			shield_stops = shield_stops})


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
			me.vitals.add_ailment("poison", c.rate * delta * ward)
			if c.dps > 0.0:
				me.vitals.take_damage(c.dps * delta * ward)
		still.append(c)
	clouds = still


func _has_mask(ps: GameAuthority.PlayerState) -> bool:
	if ps.inventory.equipped("head") == "spore_mask":
		return true
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
				if def.shield:  # Shield skill: stronger, cheaper blocks
					sb = sb.duplicate()
					for k in me.progress.block_bonus():
						sb[k] = sb.get(k, 0.0) + me.progress.block_bonus()[k]
				else:
					sb = sb.duplicate()
				sb["parry_mult"] = me.progress.parry_mult(def.weapon, def.shield) * (1.0 + sb.get("parry_window", 0.0))  # Sword ★50, Shield ★100, Edge Quartz
				result = Combat.defend(hit.damage, def.pressed_ago, def.holding, def.weapon, def.shield, def.tier, hit.crushing, sb)
				if result.result == "hit" and dwarf.get("running") and me.progress.has_star("running", 75) and randf() < 0.2:
					result = {result = "dodge", damage = 0.0, stun = 0.0, stamina = 0.0}  # Running ★75: they miss you on the run
				var swinging: bool = dwarf.get("fight") != null and dwarf.fight._busy > 0.0
				if result.result == "hit" and swinging:
					result.damage *= 1.0 - Gems.bonus(me.inventory.get_slot(me.selected_slot)).get("guard", 0.0)  # Bulwark gem
				if result.result == "block" and def.shield and hit.get("shield_stops", false):
					result.damage = 0.0  # spit: a shield stops it completely (owner, Nov 17)
				if result.result == "block":
					ask_blocked(hit.uid)  # the host wears the shield (and a Blight gem poisons the attacker)
				result.damage *= 1.0 - me.vitals.buff_total("guard_" + Monsters.food_guard(m.kind))  # meat of its kind (food plan)
				result.damage *= 1.0 - me.vitals.gear.get("guard_all", 0.0)  # Stone Amber armor
				me.vitals.take_damage(result.damage)
				if result.result == "hit" and result.damage > 0.0:
					ask_hit_back(hit.uid, result.damage)  # Edge Quartz / Storm Topaz armor (the host checks)
				# Poison/fire/frost buildup: all of it on a hit, none on a parry. Through a block: fire all of it,
				# frost half, poison none (owner, Nov 20).
				for kind in hit.get("buildup", {}):
					var share: float = {"hit": 1.0, "block": BLOCK_SHARE.get(kind, 0.5)}.get(result.result, 0.0)
					var started := me.vitals.add_ailment(kind, hit.buildup[kind] * share)
					if started != "":
						result.ailment = started
				if result.stamina > 0.0:
					me.vitals.stamina = maxf(0.0, me.vitals.stamina - result.stamina)
					if me.vitals.stamina <= 0.0 and dwarf.has_method("guard_break"):
						dwarf.guard_break()
				if result.result == "hit" and (hit.kd or hit.get("charge", false)) and dwarf.has_method("knock_down"):  # a charge knocks you down (F234)
					dwarf.knock_down()
				if result.result in ["hit", "block"] and hit.get("charge", false) and dwarf.has_method("shove"):
					dwarf.shove(charge_shove(m, dwarf.global_position))
				if result.result in ["block", "parry"] and def.shield and "shield_blocks" in dwarf:
					dwarf.shield_blocks += 1  # Shield practice (sent to the host with running and jumping)
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


const BLOCK_SHARE := {"burn": 1.0, "chill": 0.5, "poison": 0.0}  ## how much of each effect gets through a block


## A creature hit us: Edge Quartz armor hurts it back, Storm Topaz armor may stun it (host).
func ask_hit_back(uid: int, damage: float) -> void:
	if auth.is_host():
		request_hit_back(uid, damage, auth.local_peer_id())
	else:
		_rpc_hit_back.rpc_id(1, uid, damage)


@rpc("any_peer", "reliable")
func _rpc_hit_back(uid: int, damage: float) -> void:
	if auth.is_host():
		request_hit_back(uid, damage, multiplayer.get_remote_sender_id())


func request_hit_back(uid: int, damage: float, peer: int) -> void:
	if _block_ok.get(uid, -1) != peer or not is_finite(damage):
		return  # only a swing that was aimed at you, once
	_block_ok.erase(uid)
	var m: Monster = monsters.get(uid)
	var ps := auth.get_player(peer)
	if m == null or not m.is_alive() or ps == null:
		return
	var ab := Gems.armor_bonus(ps.inventory)
	var back := roundi(clampf(damage, 0.0, 100.0) * ab.get("thorns", 0.0))
	var stun := float(m.data.get("stun", 50)) if randf() < ab.get("stun_back", 0.0) else 0.0  # a full stun meter
	if back > 0 or stun > 0.0:
		_hurt_monster(m, peer, back, stun)


## We blocked a hit with a Bog Jade shield: maybe poison the attacker (host).
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
	# A blocked hit wears what blocked it once: the shield if one is equipped, else the weapon in hand.
	var shield_at := Inventory.equip_index("shield")
	auth.wear_slot(ps, shield_at if not ps.inventory.get_slot(shield_at).is_empty() else ps.hand_slot())
	var sb := Gems.bonus(Gems.shield_slot(ps.inventory))
	if randf() < sb.get("block_poison", 0.0):  # Bog Jade shield
		m.add_buildup("poison", Ailments.FULL)


## True if a live monster stands on (or just above) the rock at `p`: you can't dig the ground out from
## under it so it falls into a pit (owner, Nov 15, F125).
func standing_over(p: Vector3) -> bool:
	for m: Monster in monsters.values():
		if not m.is_alive() or m.data.get("flies", false):
			continue
		var feet := m.global_position
		var flat := Vector2(p.x - feet.x, p.z - feet.z).length()
		if flat < float(m.data.get("size", 1.0)) * 0.6 + 1.0 and p.y < feet.y + 0.3 and p.y > feet.y - 3.0:
			return true
	return false


## Host: a short word over a monster's head for everyone ("Dazed!").
func note(m: Monster, text: String) -> void:
	_ev_note.rpc(m.uid, text)


## Which way a charge knocks you (F111): off to the side it hit you on, plus a little forward.
static func charge_shove(m: Monster, dwarf_pos: Vector3) -> Vector3:
	var fwd := -m.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var to := dwarf_pos - m.global_position
	to.y = 0.0
	var side := fwd.cross(Vector3.UP).normalized()  # the monster's right
	var which := 1.0 if to.dot(side) >= 0.0 else -1.0
	return (side * which * 7.0 + fwd * 3.0)


func _in_reach(m: Monster, dwarf: Node3D, reach: float) -> bool:
	var d := m.global_position - dwarf.global_position
	if Vector2(d.x, d.z).length() > reach + 0.8 or absf(d.y) >= 2.5:
		return false
	# Not through a wall (owner, Nov 19: a snail hit him through the tower's wall): rock or a built piece in between
	# stops the hit.
	var q := PhysicsRayQueryParameters3D.create(m.global_position + Vector3.UP * 0.6, dwarf.global_position + Vector3.UP * 0.9,
		World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
	return _root.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


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
		for k in ["burn", "chill"]:  # Forge Garnet / Frost Sapphire shield: a chance to give the attacker a stack
			if randf() < sb.get("parry_" + k, 0.0):
				m.add_buildup(k, Ailments.FULL)
		auth.heal(peer, sb.get("parry_heal", 0.0))
	m.stun.add(stun_amount)
	if not m.stun.is_stunned():
		m.state = Monster.State.RECOVER  # staggered for a moment
		m._timer = 0.6
	monster_changed(m)


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_spawn(uid: int, kind: String, pos: Vector3, leader: bool, pack: int, variant: String = "") -> void:
	if not Monsters.LIST.has(kind):
		return  # a creature the game no longer has (an old save's boss or early creature, Nov 19)
	var m: Monster = MONSTER_SCRIPT.new()
	m.setup(uid, kind, leader, pos, variant)
	m.pack_id = pack
	_root.add_child(m)
	m.global_position = pos
	monsters[uid] = m
	_next_uid = maxi(_next_uid, uid + 1)


@rpc("authority", "call_local", "reliable")
func _ev_remove(uid: int, statue := -1) -> void:
	var m: Monster = monsters.get(uid)
	monsters.erase(uid)
	if m:
		Fx.burst(_root, m.global_position + Vector3.UP * 0.4, m.data.color, 18, 3.0)
		Sfx.play("death", m.global_position)
		m.die_visual(statue)  # goes limp, then turns to stone (statue >= 0) or sinks away (only looks)


const HIT_STOP := 0.06        ## seconds both fighters freeze on a hit (owner, Nov 18: "juicy hits")
const HIT_STOP_HEAVY := 0.11  ## ... on a big hit


# ================================================================== stone statues (owner, Nov 18)
# Everything that dies turns to stone where it lies. Mine it with a pickaxe (hits by size: data.statue_hits) for its
# stone and its loot (1 in 50 also a gem). Left alone it crumbles to dust after STATUE_LIFE. The host keeps the list;
# every computer shows its own stone body (Statue).
const STATUE_LIFE := 300.0     ## seconds before an unmined statue crumbles away
const STATUE_REACH := 2.5      ## extra reach (m): the body may have rolled a little from where it died
var statues := {}  ## (host) statue id -> {pos, kind, loot, hits, needed, left}
var _next_statue := 1


## Host: a new statue where this monster died, holding `loot`. Returns its id.
func add_statue(m: Monster, loot: Array) -> int:
	var needed: int = m.data.get("statue_hits", 4)
	var items := loot.duplicate()
	items.append(["stone", needed])  # (one stone for each hit it takes)
	if randf() < Gems.STATUE_CHANCE:  # half the time the creature's own gem (spider: Bog Jade, red: Forge Garnet...)
		items.append([Gems.item_id(Gems.roll(Gems.VARIANT_GEM.get(m.variant, Gems.CREATURE_GEM.get(m.kind, "")))), 1])
	var id := _next_statue
	_next_statue += 1
	statues[id] = {pos = m.global_position, kind = m.kind, loot = items, hits = 0, needed = needed, left = STATUE_LIFE}
	return id


func ask_hit_statue(id: int) -> void:
	if auth.is_host():
		request_hit_statue(auth.local_peer_id(), id)
	else:
		_rpc_hit_statue.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _rpc_hit_statue(id: int) -> void:
	if auth.is_host():
		request_hit_statue(multiplayer.get_remote_sender_id(), id)


## Host: a swing at a statue. Pickaxe only (owner); it breaks after its hits and drops its stone and loot.
func request_hit_statue(peer_id: int, id: int) -> String:
	var ps := auth.get_player(peer_id)
	var st: Dictionary = statues.get(id, {})
	if ps == null or st.is_empty():
		return "gone"
	var at: Vector3 = Statue.where(id, st.pos + Vector3.UP * 0.4)  # where the stone body lies now (it fell after dying)
	var chest: Vector3 = ps.node.global_position + Vector3.UP * 1.1
	if chest.distance_to(at) > GameAuthority.REACH + STATUE_REACH:
		return "too_far"
	if Items.kind(ps.selected_item()) != "pickaxe":
		auth._tell_feedback(peer_id, {state = "no_tool", point = at, why = "Stone! Use a pickaxe."})
		return "no_tool"
	st.hits += 1
	auth.give_xp(peer_id, 1, "mining")
	var out := (chest - at).normalized()
	if st.hits < st.needed:
		_ev_statue_hit.rpc(id, st.hits, st.needed)
		auth._tell_feedback(peer_id, {state = "hit", hits = st.hits, needed = st.needed, material = Mat.STONE, point = at, normal = out})
		return "hit"
	statues.erase(id)
	for d in st.loot:
		auth.spawn_drop(d[0], d[1], at + out * 0.4 + Vector3.UP * 0.3)
	_ev_statue_gone.rpc(id, true)
	auth._tell_feedback(peer_id, {state = "dug", hits = st.hits, needed = st.needed, material = Mat.STONE, point = at, normal = out, boulder = true, statue = true})
	return "dug"


## Host: unmined statues crumble away after a while.
func _statues_step(delta: float) -> void:
	for id in statues.keys():
		statues[id].left -= delta
		if statues[id].left <= 0.0:
			statues.erase(id)
			_ev_statue_gone.rpc(id, false)


@rpc("authority", "call_local", "reliable")
func _ev_statue_hit(id: int, hits: int, needed: int) -> void:
	Statue.hit(id, hits, needed)


@rpc("authority", "call_local", "reliable")
func _ev_statue_gone(id: int, mined: bool) -> void:
	Statue.remove(id, mined)


@rpc("authority", "call_local", "reliable")
func _ev_hp(uid: int, hp: float, stun_frac: float, stunned: bool) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.set_hp(hp, stun_frac, stunned)


## Host: the snail pulled into its shell (or came out). Everyone sees it.
func monster_shell(m: Monster, hidden: bool) -> void:
	# Inside its shell a snail can't bite (F105): a bite it was winding up is called off, and when it
	# comes back out it needs a moment before it can start a new one.
	m.state = Monster.State.RECOVER
	m._attack = {}
	m._timer = 1.0
	_ev_shell.rpc(m.uid, hidden)


@rpc("authority", "call_local", "reliable")
func _ev_shell(uid: int, hidden: bool) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_shell(hidden)
	if hidden:
		# A bite it was winding up was already sent to everyone's screen; it must not land now (F105/F138).
		_incoming = _incoming.filter(func(h): return h.uid != uid)
		if hidden:
			_float_number(m.global_position + Vector3.UP * 1.3, "Hides in its shell!")


## A short word floating up over a monster ("Weak spot!").
@rpc("authority", "call_local", "reliable")
func _ev_note(uid: int, text: String) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		_float_number(m.global_position + Vector3.UP * 1.6, text)


@rpc("authority", "call_local", "reliable")
func _ev_hit(uid: int, dmg: int, from := Vector3.ZERO, peer := 0) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		# Juicy hits (owner, Nov 18): sparks spray AWAY from the hitter, both fighters freeze for a blink (a bigger hit, a
		# longer freeze), the hitter's screen shakes, and a heavy hit bounces the dwarf back a little.
		var heavy := dmg >= 20
		var away := (m.global_position - from) * Vector3(1, 0, 1)
		var dir := (away.normalized() + Vector3.UP * 0.35) if from != Vector3.ZERO and away.length() > 0.01 else Vector3.UP
		var at := m.global_position + Vector3.UP * 0.5
		if m.shell_shut:
			# Hitting a hidden snail: a hard stony clank and sparks (it's barely hurt).
			Fx.burst(_root, m.global_position + Vector3.UP * 0.6, Color(1.0, 0.75, 0.35), 12, 4.5, dir, 40.0)
			Sfx.play("shell_clank", m.global_position)
		else:
			Fx.burst(_root, at, Color(1.0, 0.9, 0.7), 14 if heavy else 9, 4.5 if heavy else 3.2, dir, 38.0)
			Sfx.play("hit_heavy" if heavy else "hit", m.global_position)
		var stop := HIT_STOP_HEAVY if heavy else HIT_STOP
		m.hit_flash()
		m.hit_stop(stop)
		if peer != 0 and peer == auth.local_peer_id():
			var me := player_node(peer)
			if me and me.has_method("hit_stop"):
				me.hit_stop(stop)
				me.add_shake(0.45 if heavy else 0.25)
				if heavy and away.length() > 0.01:
					me.shove(-away.normalized() * 2.2)  # (a heavy hit bounces you back off it)
		_float_number(m.global_position + Vector3.UP * 1.4, str(dmg), heavy, dir)


@rpc("authority", "unreliable_ordered")
func _ev_poses(ids: PackedInt32Array, pos: PackedVector3Array, yaw: PackedFloat32Array) -> void:
	for i in ids.size():
		var m: Monster = monsters.get(ids[i])
		if m:
			m.set_net(pos[i], yaw[i])


## A number (or a word) that pops up over a creature. Round 2 (owner, Nov 18, the Disney rules: "nothing flies
## straight, not the damage numbers"): it pops in (small, too big, then its size) and flies in an arc, away from the
## hit, up and over; a big hit's number is bigger and warmer.
func _float_number(at: Vector3, text: String, big := false, away := Vector3.ZERO) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64 if big else 48
	l.pixel_size = 0.005
	l.outline_size = 12 if big else 10
	l.no_depth_test = true
	l.modulate = Color(1.0, 0.62, 0.25) if big else Color(1.0, 0.9, 0.5)
	_root.add_child(l)
	l.global_position = at
	var side := Vector3(away.x, 0.0, away.z)
	side = side.normalized() if side.length() > 0.01 else Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	side *= randf_range(0.35, 0.6)
	var rise := 1.0 if big else 0.8
	l.scale = Vector3.ONE * 0.3
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector3.ONE * (1.35 if big else 1.2), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "scale", Vector3.ONE, 0.1)
	t.parallel().tween_method(func(u: float) -> void:
		if is_instance_valid(l):
			l.global_position = at + side * u + Vector3.UP * (rise * 1.6 * u - rise * 0.75 * u * u), 0.0, 1.0, 0.85)  # (an arc: up, over, a little down)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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
		if monsters.has(e[0]):  # (skipped if it's a creature the game no longer has)
			monsters[e[0]].hp = e[5]
