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
		var had: bool = not st.alive.is_empty()
		st.alive = st.alive.filter(func(u): return monsters.has(u))
		if had and st.alive.is_empty():
			st.cleared_at = _clock  # (F957: the wait starts when the last one dies, not when they came)
		if st.alive.is_empty() and near < SPAWN_NEAR and _clock - st.cleared_at >= _room_respawn(room):
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
			var fl := float(c.get("floor", 0.0))  # (Lampwick's upper level is 3 m up: its creatures say so)
			var room := DungeonMap.space_at(d, DungeonMap.to_world(d, Vector3(local.x, fl + 1.0, local.z)))
			if not by.has(room):
				by[room] = []
			by[room].append([String(c.kind), local, fl, c.get("wake", [])])
		var gi := 0
		for room in by:
			var mid := Vector3.ZERO
			for c in by[room]:
				mid += c[1]
			mid /= float(by[room].size())
			var fl := float(by[room][0][2])
			_dgroups.append({key = DUNGEON_KEY + di * 100 + gi, center = DungeonMap.to_world(d, Vector3(mid.x, fl + 1.0, mid.z)),
				list = by[room], d = d, room = room})
			gi += 1
	return _dgroups


func _spawn_dungeon_group(_room: Dictionary, g: Dictionary) -> Array:
	var uids := []
	for c in g.list:
		var kind := String(c[0])
		var leader := kind == "great_rock_beetle"
		if leader:
			kind = "rock_beetle"
		if not Monsters.LIST.has(kind):
			continue
		var local: Vector3 = c[1]
		var at := DungeonMap.to_world(g.d, Vector3(local.x, (float(c[2]) if c.size() > 2 else 0.0) + 0.55, local.z))  # on the floor boards
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
			mon.dungeon_wake = c[3] if c.size() > 3 else []
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
		var high := {}
		if String(info.get("climbs", "")) == "all" and randf() < Monster.UP_HIGH:
			# About 1 in 4 snails and spiders are up on a wall or ceiling when you find them (owner F475, F474).
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			high = Monster.high_spot(maker, spot, "all", rng)
			if not high.is_empty() and _built_near(high.pos):
				high = {}  # (nor over something a player built: the placement rule)
		if not high.is_empty():
			at = high.pos
		elif info.get("roosts", false):
			# Bats start asleep, hanging from the ceiling right above this spot.
			var ceiling := GlowPlacer._march(maker, spot + Vector3.UP * 1.0, Vector3.UP, 30.0)
			if ceiling == Vector3.INF:
				continue
			at = ceiling + Vector3.DOWN * 0.3
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, kind, at, has_leader and k == 0, room_i, Monsters.roll_variant(biome, randf(), randf()),
			high.get("normal", Vector3.ZERO))
		uids.append(uid)
	return uids


## Host: something thrown landed at `p`: creatures up on the rock right there are knocked down (owner F475).
func knock_off_near(p: Vector3, r: float, peer: int) -> void:
	for m: Monster in monsters.values():
		if m.is_alive() and m.clinging() and m.global_position.distance_to(p) < r:
			m.alert(peer)
			m.knocked_off()


## Is a player-built piece within a few metres of `p`, or of the floor under it? (Creatures up high keep off them.)
func _built_near(p: Vector3) -> bool:
	if _root == null or not _root.is_inside_tree():
		return false
	var q := PhysicsShapeQueryParameters3D.new()
	var s := CapsuleShape3D.new()
	s.radius = 2.5
	s.height = 12.0
	q.shape = s
	q.transform = Transform3D(Basis.IDENTITY, p + Vector3.DOWN * 3.0)
	q.collision_mask = PieceNode.PIECE_LAYER
	return not _root.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## Host: tell everyone which surface this creature is on now (climbing, F236/F474/F475), and any cue with it.
func monster_cling(m: Monster, cue := "") -> void:
	_ev_cling.rpc(m.uid, m.global_position, m.surface, cue)


@rpc("authority", "call_local", "reliable")
func _ev_cling(uid: int, pos: Vector3, n: Vector3, cue: String) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_cling(pos, n, cue)


## F957 (owner, Nov 28: "snails come back too fast near the base"): a cave with a station of yours in it (your base)
## waits NEAR_BASE_RESPAWN_MULT times as long before its creatures move back in.
const NEAR_BASE := 45.0
const NEAR_BASE_RESPAWN_MULT := 3.0


func _room_respawn(room: Dictionary) -> float:
	if auth and auth.stations:
		var c: Vector3 = room.center
		for st in auth.stations.values():
			if is_instance_valid(st) and (st as Node3D).global_position.distance_to(c) < NEAR_BASE:
				return RESPAWN * NEAR_BASE_RESPAWN_MULT
	return RESPAWN


func _nearest_player_dist(p: Vector3) -> float:
	var best := INF
	for pid in auth.players:
		best = minf(best, auth.players[pid].node.global_position.distance_to(p))
	return best


## A dwarf flying with the dev fly key (owner, Nov 17) or in god mode (F9, owner Nov 20) is left alone by every monster.
static func ignores(node: Node) -> bool:
	return node is Dwarf and ((node as Dwarf).dev_fly or (node as Dwarf).dev_god)


## Who does this monster notice? (sight inside your lantern light, hearing) — doc 5.1.
func nearest_noticer(m: Monster) -> int:
	var best := 0
	var best_d := INF
	for pid in auth.players:
		var ps: GameAuthority.PlayerState = auth.players[pid]
		if ignores(ps.node):
			continue
		var p: Vector3 = ps.node.global_position
		var d := p.distance_to(m.global_position)
		if not m.dungeon.is_empty():
			var room := DungeonMap.space_at(m.dungeon, p + Vector3.UP)
			if room != m.dungeon_room and room != "" and room in m.dungeon_wake and m.state == Monster.State.SLEEP and d < best_d:
				best = pid  # (Lampwick: the rats above the carts wake as you come into the junction, owner Nov 20)
				best_d = d
				continue
			# A dungeon creature only notices you in its own room (owner, Nov 20, the bats woke early). In Lampwick a
			# pile of bones also sees you from the next room, close by (owner, Nov 20: they lay there while shot at).
			if room != m.dungeon_room and not (m.chases_out() and m.state == Monster.State.SLEEP
					and d <= float(m.data.get("rise_near", 4.0)) and _can_see(m.global_position + Vector3.UP * 0.5, p + Vector3.UP)):
				continue
		var lit := ps.fuel > 0.0
		var sight := Monsters.SIGHT if lit else Monsters.SIGHT_DARK
		if m.data.get("likes_light", false):
			sight = 25.0 if lit else 0.0
		var running: bool = ps.node is CharacterBody3D and Vector2(ps.node.velocity.x, ps.node.velocity.z).length() > 5.0
		var hear := Monsters.HEAR_RUN if running else Monsters.HEAR_WALK
		if m.state == Monster.State.SLEEP:
			sight = m.data.get("rise_near", 4.0)  # (a pile of bones gets up when you come this close, F462)
			hear = sight
		if lit and d <= m.data.get("wake_light", 0.0) and d < best_d and in_cave(m, p):
			best = pid  # (F419: a light wakes bats anywhere in their cave, seen or not)
			best_d = d
			continue
		if d > maxf(sight, hear) or d >= best_d:
			continue
		if d > hear and not _can_see(m.global_position + m.global_transform.basis.y * 0.6, p + Vector3.UP):  # (its eyes: off the rock it clings to)
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


## Could a player see any of these spots (close enough, no rock or built wall in between)? A stuck monster only jumps
## home when nobody would see it vanish or appear (owner F731, Nov 22: "if I run into the mine and back they will just
## teleport").
const SEEN_FAR := 40.0
func seen_by_a_player(spots: Array) -> bool:
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node == null:
			continue
		var eye := node.global_position + Vector3.UP * 1.5
		for s: Vector3 in spots:
			if eye.distance_to(s) > SEEN_FAR:
				continue
			var q := PhysicsRayQueryParameters3D.create(eye, s + Vector3.UP, World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
			if _root.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				return true
	return false


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
	var reach: float = atk.reach if not atk.get("lunge", false) else float(atk.get("lunge_reach", m.data.get("size", 1.0) * 0.6 + 0.8))
	_ev_tell.rpc(m.uid, m.target_peer, atk.tell, dmg, reach, crushing, atk.get("knockdown", false), atk.name, buildup,
		is_charge(atk), atk.get("shield_stops", false), atk.get("knock", 1.5))


## A charge (a beetle running into you) knocks you down and shoves you (F234). A spider's pounce is a lunge too, but
## a small one: it only bites (owner, Nov 19, F416: "spiders shouldn't knock you down").
static func is_charge(atk: Dictionary) -> bool:
	return atk.get("lunge", false) and not atk.get("pounce", false) and not atk.get("small_lunge", false)  # (a Lost Miner's leap-chop only hits, owner Nov 21)


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
func ask_attack(uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool, airborne: bool = false, bash: bool = false) -> void:
	if auth.is_host():
		request_attack(auth.local_peer_id(), uids, heavy, combo_step, riposte, false, airborne, bash)
	else:
		_rpc_attack.rpc_id(1, uids, heavy, combo_step, riposte, airborne, bash)


@rpc("any_peer", "reliable")
func _rpc_attack(uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool, airborne: bool = false, bash: bool = false) -> void:
	if auth.is_host():
		var unique := PackedInt32Array()
		for u in uids:
			if not unique.has(u) and unique.size() < 8:
				unique.append(u)
		request_attack(multiplayer.get_remote_sender_id(), unique, heavy, clampi(combo_step, 0, 9), riposte, false, airborne, bash)


## Host: works out the damage (doc 2.2) for each monster hit. Returns total damage dealt.
## spin = the Whirlwind perk: a heavy hit on everything around you, no target limit.
## bash = a shield bash while blocking (owner, chat 16): hits with the best shield carried, not the weapon in hand.
func request_attack(peer: int, uids: PackedInt32Array, heavy: bool, combo_step: int, riposte: bool, spin: bool = false, airborne: bool = false, bash: bool = false) -> int:
	var ps := auth.get_player(peer)
	if ps == null:
		return 0
	var item := ps.selected_item()
	var hand := ps.hand_slot()
	if bash:
		heavy = false
		combo_step = 0
		hand = _shield_slot(ps)
		if hand < 0:
			return 0  # no shield: no bash (stops cheating)
		item = ps.inventory.get_slot(hand).get("id", "")
	var w := Combat.weapon_of(item)
	var tier := maxi(Items.tier(item), 0)
	var wd: Dictionary = Combat.WEAPONS[w]
	if heavy and not spin and not Combat.has_heavy(w, tier):
		heavy = false  # (one-handed and stone great weapons have none: owner, chat 16)
	if not heavy and combo_step >= Combat.combo_hits(w, tier):
		combo_step = 0  # (a stone sword, mace or spear has no finisher: owner, chat 16)
	var finisher := not heavy and not bash and Combat.is_finisher(w, tier, combo_step)
	var gb := Gems.bonus(ps.inventory.get_slot(hand))
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
		var crush := (heavy or finisher) and m.stun.take_crush()  # (the combo finisher Crushes too: owner, chat 16)
		var sit := Combat.situation(sneak, m.stun.is_stunned(), crush, riposte)
		var mult := 0.6 if (w == "axe" and n >= 2) else 1.0
		var dist: float = ps.node.global_position.distance_to(m.global_position)
		var star: float = ps.progress.star_damage_bonus(w, {combo_step = combo_step, riposte = riposte, stunned = m.stun.is_stunned(),
			shelled = float(m.stats().get("armor", 0.0)) >= 20.0, airborne = airborne,
			tip = dist >= wd.reach * ps.progress.reach_mult(w) * 0.8})  # skills.md ★ perks
		var dmg := roundi(Combat.damage(w, heavy, tier, _pierced(ps, m, w), combo_step, sit, Items.boost(item), Upgrades.bonus(ps.inventory.get_slot(hand)), buff + auth.damage_boost(ps, m.kind) + ps.progress.weapon_damage_bonus(w) + _perk_buff(ps, peer, m, w) + star, elem) * mult)
		var crit := false
		if riposte and ps.progress.riposte_crits(w):  # Sword ★100: a perfect parry's counter is a critical
			dmg = roundi(dmg * Combat.CRIT_MULT)
			crit = true
		elif not Controls.robot and randf() < Combat.crit_chance(w):  # now and then a critical hit (owner F137; never in tests: they need exact numbers)
			dmg = roundi(dmg * Combat.CRIT_MULT)
			crit = true  # (the number itself shows it now: bigger, red, with a "!" (F788); no separate "Critical!" word)
		if bash:  # F841 (owner, Nov 24): a bash barely hurts; it shoves them away, harder the lower your health
			dmg = maxi(1, roundi(dmg * BASH_DAMAGE))
			crit = false
		if _shield_blocks(m, ps.node.global_position, heavy):
			dmg = roundi(dmg * SHIELD_BLOCK)
			_ev_note.rpc(m.uid, "Blocked!")
		total += dmg
		_gem_buildup(m, gb)
		var stun: float = Combat.stun_value(w, heavy, tier, combo_step) * (1.0 + gb.get("stun", 0.0) + (gb.get("bash_stun", 0.0) if bash else 0.0)) * (ps.progress.heavy_stun_mult() if heavy else 1.0) * ps.progress.skill_stun_mult(w)
		if Progression.weapon_skill(w) == "mace" and ps.progress.has_star("mace", 75) and float(m.stats().get("armor", 0.0)) >= 20.0:
			stun *= 1.25  # Mace ★75: armored enemies stagger
		if heavy and Progression.weapon_skill(w) == "warhammer" and ps.progress.has_star("warhammer", 100):
			stun += 999.0  # Warhammer ★100: the slam knocks them down
		if not heavy and Progression.weapon_skill(w) == "spear" and ps.progress.has_star("spear", 25):
			var away := (m.global_position - ps.node.global_position) * Vector3(1, 0, 1)
			if away.length() > 0.01:
				m.knock(away.normalized() * 3.0)  # Spear ★25: a poke pushes them back
		_hurt_monster(m, peer, dmg, stun, Combat.effect(wd.type, m.stats()), crit)
		var shove := (m.global_position - ps.node.global_position) * Vector3(1, 0, 1)
		if bash and m.is_alive() and shove.length() > 0.01 and not m.data.get("boss", false):  # (after the hurt: its small push would replace this)
			var low := 1.0 - clampf(ps.vitals.health / maxf(1.0, ps.vitals.max_health()), 0.0, 1.0)
			m.knock(shove.normalized() * lerpf(BASH_PUSH, BASH_PUSH_LOW, low) / maxf(1.0, float(m.data.get("size", 1.0))))
		if finisher and not m.data.get("boss", false) and m.is_alive() and m.hp <= m.max_hp() * 0.5:  # F607/F617: only knock down when wounded (below 50% HP); at full health they fight back
			var away_fin := (m.global_position - ps.node.global_position) * Vector3(1, 0, 1)
			if away_fin.length() > 0.01:
				m.knock(away_fin.normalized() * 14.0 / maxf(1.0, float(m.data.get("size", 1.0))))
			m.start_knockdown(2.5)  # falls apart, gets back up 2.5 s later
	auth.heal(peer, total * gb.get("leech", 0.0))
	if heavy and Progression.weapon_skill(w) == "axe" and ps.progress.has_star("axe", 100) and n > 0:
		auth.give_stamina(peer, 6.0 * mini(n, max_targets))  # Axe ★100: a heavy sweep gives stamina back per enemy
	if total > 0:
		auth.wear_slot(ps, hand)  # a swing that hit something wears the weapon once (a bash: the shield)
	return total


## The Prop Warden's plank shield (owner, Nov 21): a hit from the front does only this much, unless it is a heavy
## swing or he is stunned. Get round him (or stun him) to hurt him properly.
const SHIELD_BLOCK := 0.2
const BASH_DAMAGE := 0.2  ## a shield bash does a fifth of the shield's damage (F841: it was 20+ on beetles)
const BASH_PUSH := 7.0  ## the bash's shove (m/s) at full health ...
const BASH_PUSH_LOW := 16.0  ## ... and when nearly dead: shove them further away (owner F841)


func _shield_blocks(m: Monster, from: Vector3, heavy: bool) -> bool:
	if heavy or not m.data.get("front_shield", false) or m.stun.is_stunned() or m.model == null or not m.raising.is_empty():
		return false  # (during his Rally Slam the plank is up over his head: hit him now)
	if m.data.get("ghost", false) and (m.state == Monster.State.RECOVER or (m.rig is GhostRig and m.rig.shield_open())):
		return false  # F850: the Shield-Brother's shield drops after each swing and after his charge: hit him then
	if m.data.get("shield_drops", false) and (m.state == Monster.State.RECOVER or (m.rig and m.rig.shield_lowered())):
		return false  # F975: the Vault Captain lowers his shield after each swing and after his charge: hit him then
	var to_me := (from - m.global_position) * Vector3(1, 0, 1)
	var ahead := -m.model.global_transform.basis.z * Vector3(1, 0, 1)
	if to_me.length() < 0.01 or ahead.length() < 0.01:
		return false
	return to_me.normalized().dot(ahead.normalized()) > 0.3


## Host: the slot of the shield a bash hits with: the equipped one, else the best on the hotbar (-1 = none).
func _shield_slot(ps: GameAuthority.PlayerState) -> int:
	var eq := ps.inventory.worn_slot("shield")  # (-1 = none worn, F825)
	if Items.kind(ps.inventory.get_slot(eq).get("id", "")) == "shield":
		return eq
	var best := -1
	for i in Inventory.HOTBAR_SIZE:
		var id: String = ps.inventory.get_slot(i).get("id", "")
		if Items.kind(id) == "shield" and (best < 0 or Items.rank(id) > Items.rank(ps.inventory.get_slot(best).get("id", ""))):
			best = i
	return best


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
## eff: how it takes this damage type (Combat.effect): the colour of the hit's number.
func _hurt_monster(m: Monster, peer: int, dmg: int, stun_amount: float, eff := 0, crit := false) -> void:
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
	var hp_before := m.hp
	m.hp -= dmg
	if not m.raising.is_empty() and m.hp > 0.0:
		cancel_raise(m)  # a hit during the Rally Slam calls it off (owner, Nov 21)
	if not shell.is_empty() and m.shell_left <= 0.0 and m.hp > 0.0 and m.shell_hits < shell.at.size() 			and m.hp <= m.max_hp() * float(shell.at[m.shell_hits]):
		while m.shell_hits < shell.at.size() and m.hp <= m.max_hp() * float(shell.at[m.shell_hits]):
			m.shell_hits += 1  # (a big hit past both marks uses both: it hides once)
		m.shell_left = shell.seconds
		monster_shell(m, true)
	m.last_hitter = peer
	m.hit_by[peer] = _clock
	m.stun.add(stun_amount)
	m.hurt_by_someone()  # (it follows you out of its room for a while: F572)
	m.alert(peer)
	alert_pack(m, peer)
	var hitter_ps := auth.get_player(peer)
	if hitter_ps:
		auth.give_xp(peer, 1, Progression.weapon_skill(Combat.weapon_of(hitter_ps.selected_item())))
	# A push away from the hitter (owner, Nov 18, "juicy hits"): stronger for big hits, weaker for big creatures.
	var from := hitter.global_position if hitter else m.global_position
	if hitter and not m.shell_shut and m.shell_left <= 0.0 and not (m.rig != null and m.rig.knocked_down):  # (a snail in his shell is a heavy stone; don't slide knocked-down skeletons: they can't be hit while moving, and teleport when collision is restored)
		var away := (m.global_position - from) * Vector3(1, 0, 1)
		if away.length() > 0.01:
			m.knock(away.normalized() * clampf(1.8 + dmg * 0.06, 1.8, 5.0) / maxf(1.0, float(m.data.get("size", 1.0))))
	_ev_hit.rpc(m.uid, dmg, from, peer, eff, crit, m.hp <= 0.0)  # (the host decides the kill: F800)
	if m.hp <= 0.0:
		_kill(m, peer)
	else:
		m.knocked_off()  # up on a wall or ceiling: any hit knocks it down (a snail lands dazed on its shell, F475)
		monster_changed(m)
		if m.data.get("ghost", false):
			var spot := Ghost.jump_after_hit(m, hp_before, auth.world.maker if auth and auth.world else null, hitter)
			if spot != Vector3.INF:
				ghost_fade(m, spot)
			elif Ghost.jump_owed(m, hp_before):
				m.set_meta("ghost_jump_owed", 0.0)  # no room behind you right now: it tries again as it chases you


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
		dmg = Combat.shot_damage(heavy, tier, bolt, {armor = 0}, gap, 1.0, Items.boost(item))
		for k in BOLT_BUILDUP.get(bolt, {}):
			buildup[k] = BOLT_BUILDUP[bolt][k] * Combat.FRIENDLY_FIRE
	else:
		if w == "crossbow" or gap > Combat.WEAPONS[w].reach + 1.5:
			return 0
		dmg = Combat.damage(w, heavy, tier, {armor = 0}, 0, 1.0, Items.boost(item))
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
		dealt = Combat.shot_damage(aimed, tier, bolt, _pierced(ps, m, "crossbow"), dist, sit, gb.get("keen", 0.0) + Items.boost(ps.selected_item()) + auth.damage_boost(ps, m.kind) + ps.progress.weapon_damage_bonus("crossbow") + _perk_buff(ps, peer, m, "crossbow"), elem)
		var stun_amount: float = (Combat.stun_value("crossbow", aimed, tier) + b.get("stun", 0.0)) * (1.0 + gb.get("stun", 0.0))
		for k in BOLT_BUILDUP.get(bolt, {}):
			m.add_buildup(k, BOLT_BUILDUP[bolt][k])
		_gem_buildup(m, gb)
		_hurt_monster(m, peer, dealt, stun_amount, Combat.effect(String(Combat.BOLTS.get(bolt, Combat.BOLTS.bolt_stone).get("type", "pierce")), m.stats()))
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
	mesh.size = Vector3(0.022, 0.022, 0.32)  # F926 (owner, Nov 27): bolts were way too big (was 4 x 4 x 50 cm)
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


## F604: every weapon can hit up to 3 targets per swing; sweeps hit everything in arc.
static func max_targets_for(w: String) -> int:
	if Combat.WEAPONS[w].get("sweep", false) or w == "mace_2h":
		return 99
	return 3


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
	if m.data.get("boss", false) and randf() < Gems.BOSS_CHANCE:
		loot.append([Gems.item_id(Gems.roll()), 1])  # a boss: 50% a Rough gem in its statue (gems.md)
	if m.leader and randf() < 0.1:
		var rune := auth.rune_slab.pick_drop(GameAuthority.rune_biome_at(m.global_position), [randf(), randf(), randf(), randf()])
		if rune != "":
			loot.append(["rune_" + rune, 1])
	if m.data.get("boss", false):
		auth._ev_stinger.rpc("boss_defeated")  # everyone hears the short boss-down sound (owner, Nov 25)
	if m.data.has("key") and auth.keys != null:  # a key-keeper (the Shield-Brother): its dungeon key falls where it died
		auth.keys.drop_key(String(m.data.key), m.global_position + Vector3.UP * 0.5)
	var room: Dictionary = _rooms.get(m.pack_id, {})
	if not room.is_empty():
		room.alive.erase(m.uid)
		if room.alive.is_empty():
			room.cleared_at = _clock
	if m.data.get("ghost", false):  # a ghost fades into mist: no stone body, its loot falls where it was (Ghost)
		for d in loot:
			auth.spawn_drop(d[0], d[1], m.global_position + Vector3.UP * 0.5)
		_ev_remove.rpc(m.uid, -1)
		return
	_ev_remove.rpc(m.uid, add_statue(m, loot))


# ================================================================== monsters attacking us

## Everyone: a monster starts an attack. Only the target's own computer judges it.
@rpc("authority", "call_local", "reliable")
func _ev_tell(uid: int, target: int, tell: float, dmg: float, reach: float, crushing: bool, kd: bool, attack_name: String, buildup: Dictionary = {}, charge: bool = false, shield_stops: bool = false, knock: float = 1.5) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_tell(tell, attack_name, player_node(target))
	if auth.is_host():
		_parry_ok[uid] = target  # only this player may parry this swing, once
		_block_ok[uid] = target
	if target == auth.local_peer_id() and dmg > 0.0:
		_incoming.append({uid = uid, at = _clock + tell, damage = dmg, reach = reach, crushing = crushing, kd = kd, name = attack_name, buildup = buildup, charge = charge,
			shield_stops = shield_stops, knock = knock, run_from = _clock + tell * (1.0 - Monster.CHARGE_RUN_PART)})


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
		if hit.at > _clock and not _charge_ran_into(hit, me.node):
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
					sb["block"] = sb.get("block", 0.0) + Combat.boost_block(Items.boost(Gems.shield_slot(me.inventory).get("id", "")))  # bronze
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
				if result.result == "hit" and not hit.get("charge", false) and m and result.damage > 0.0 and dwarf.has_method("shove"):
					var away := (dwarf.global_position - m.global_position) * Vector3(1, 0, 1)
					if away.length() > 0.01:
						dwarf.shove(away.normalized() * hit.get("knock", 1.5))  # push away from attacker; charges use charge_shove below
				if dwarf.get("fight") != null and result.result in ["hit", "block"]:  # your stun meter (owner, chat 15)
					dwarf.fight.take_stun(result.damage * DwarfFight.STUN_PER_HIT if result.result == "hit" else float(hit.damage) * DwarfFight.STUN_PER_BLOCK)
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
			"parry": _parry_feel(m, dwarf)
			"block": Sfx.ui("block_thud", -4.0)  # a normal block: a dull thud (F870); a perfect parry rings
			"hit":
				var snd := you_hit_sound(m.kind if m else "", result.damage)
				if snd != "":
					Sfx.ui(snd, -2.0)  # a beast's bite: only the dwarf's "oof" (F925)
		defended.emit(result)
		if result.result == "parry":
			ask_parried(hit.uid, result.stun)
	_incoming = still


const BLOCK_SHARE := {"burn": 1.0, "chill": 0.5, "poison": 0.0}  ## how much of each effect gets through a block
const PARRY_STOP := 0.14  ## a perfect parry: both fighters freeze a moment (the "tiny slow-down", F870)


## A perfect parry, with no words (F870, owner Nov 25): the blade rings, a spark star flies where the weapons meet,
## and both fighters freeze a moment. Only the parrying player's game shows it (like the hit freeze).
func _parry_feel(m: Monster, dwarf: Node3D) -> void:
	Sfx.ui("parry", -2.0)
	Sfx.ui("parry_ring", -3.0)
	if m == null or dwarf == null:
		return
	var at := dwarf.global_position.lerp(m.global_position, 0.4) + Vector3.UP * 1.1  # (a bit nearer the dwarf: the weapon)
	Fx.parry_star(_root, at, m.global_position - dwarf.global_position)
	m.hit_stop(PARRY_STOP)
	if dwarf.has_method("hit_stop"):
		dwarf.hit_stop(PARRY_STOP)
	if dwarf.has_method("add_shake"):
		dwarf.add_shake(0.2)


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
	var shield_at := ps.inventory.worn_slot("shield")  # (-1 = none worn, F825)
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


const DIVE_GAP := 0.7  ## s between two bats of a pack starting a dive at the same dwarf (they take turns, F460)
var _dives := {}  ## (host) target peer -> when a bat last started a dive at them


## Host: may this bat start a dive at its target now? (Only one every DIVE_GAP seconds per dwarf.)
func may_dive(m: Monster) -> bool:
	if _clock - float(_dives.get(m.target_peer, -INF)) < DIVE_GAP:
		return false
	_dives[m.target_peer] = _clock
	return true


## Host: a short word over a monster's head for everyone ("Dazed!").
func note(m: Monster, text: String) -> void:
	_ev_note.rpc(m.uid, text)


## Host: a charging beetle smashes what it runs into (owner F447): boulders, ruin columns and stone bodies of dead
## creatures burst (their stone and loot drop, like mining them to the end). It thunders on through them.
## Returns how many things it broke this step.
func charge_smash(m: Monster, dir: Vector3) -> int:
	if _root == null or not _root.is_inside_tree() or dir.length() < 0.1:
		return 0
	var size := float(m.data.get("size", 1.0))
	var ball := SphereShape3D.new()
	ball.radius = 0.45 * size + 0.2
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = ball
	q.transform = Transform3D(Basis.IDENTITY, m.global_position + Vector3.UP * (0.5 * size) + dir.normalized() * (0.5 * size + 0.35))
	q.collision_mask = World.TERRAIN_LAYER | Ragdoll.LAYER
	var broke := 0
	var done := {}
	for hit in _root.get_world_3d().direct_space_state.intersect_shape(q, 16):
		var c: Object = hit.collider
		var key := ""
		var ok := false
		var b := Boulders.id_of(c)
		var col := PoiField.column_id_of(c)
		var st := Statue.id_of(c)
		if b >= 0:
			key = "b%d" % b
			ok = not done.has(key) and auth.smash_boulder(b, m.global_position)
		elif col >= 0:
			key = "c%d" % col
			ok = not done.has(key) and auth.smash_column(col, m.global_position)
		elif st >= 0:
			key = "s%d" % st
			ok = not done.has(key) and smash_statue(st, m.global_position)
		if ok:
			done[key] = true
			broke += 1
	return broke


## Host: a swing of a creature that smashes stone (the Foreman) lands: every fallen miner's stone in its reach breaks
## (in front of it; all round for a spin).
func smash_statues_in_reach(m: Monster, atk: Dictionary) -> int:
	var fwd := -Basis(Vector3.UP, m.model.rotation.y).z
	var all_round := String(atk.get("anim", "")).contains("Spin")
	var broke := 0
	for id in statues.keys():
		var at: Vector3 = Statue.where(id, statues[id].pos)
		var to := (at - m.global_position) * Vector3(1, 0, 1)
		if to.length() > float(atk.get("reach", 2.0)) + 0.8 or absf(at.y - m.global_position.y) > 2.0:
			continue
		if not all_round and to.length() > 0.3 and to.normalized().dot(fwd) < 0.2:
			continue
		if smash_statue(id, m.global_position):
			broke += 1
	return broke


## F603: host — a monster's attack lands: break any smash/rubble furniture within its reach.
func attack_smash_things(m: Monster, atk: Dictionary) -> void:
	if DungeonBuild.instance == null or m.dungeon.is_empty():
		return
	var fwd := -Basis(Vector3.UP, m.model.rotation.y).z if m.model else Vector3.FORWARD
	var all_round := String(atk.get("anim", "")).contains("Spin")
	var reach := float(atk.get("reach", 2.0)) + 0.3
	for id: int in DungeonBuild.instance.things.keys():
		var th: Dictionary = DungeonBuild.instance.things[id]
		if th.kind not in ["smash", "rubble"]:
			continue
		if DungeonBuild.instance.is_broken(id):
			continue
		var centre: Vector3 = th.centre
		var to: Vector3 = (centre - m.global_position) * Vector3(1, 0, 1)
		if to.length() > reach + float(th.radius):
			continue
		if absf(centre.y - m.global_position.y) > 2.0:
			continue
		if not all_round and to.length() > 0.3 and to.normalized().dot(fwd) < 0.0:
			continue
		DungeonBuild.instance.request_monster_hit(id)


## Host: a stone body breaks in one go (a beetle charged through it): its loot drops, as if mined.
func smash_statue(id: int, from: Vector3) -> bool:
	var st: Dictionary = statues.get(id, {})
	if st.is_empty():
		return false
	var at: Vector3 = Statue.where(id, st.pos + Vector3.UP * 0.4)
	var out := (from - at) * Vector3(1, 0, 1)
	out = out.normalized() if out.length() > 0.01 else Vector3.FORWARD
	statues.erase(id)
	for d in st.loot:
		auth.spawn_drop(d[0], d[1], at + out * 0.4 + Vector3.UP * 0.3)
	_ev_statue_gone.rpc(id, true)
	return true


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


## A charge hits the moment it runs into you, not at the end of its run (owner, Nov 22 night: "beetles no longer
## ragdoll u, and don't dmg u"): a straight charge thunders on past you, so by the end of its wind-up it was already
## 2-5 m beyond and every charge counted as a miss.
func _charge_ran_into(hit: Dictionary, dwarf: Node3D) -> bool:
	if not hit.get("charge", false) or _clock < float(hit.get("run_from", INF)):
		return false
	var m: Monster = monsters.get(hit.uid)
	return m != null and is_instance_valid(m) and m.is_alive() and not m.stun.is_stunned() and _in_reach(m, dwarf, hit.reach)


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
	if not m.stun.is_stunned() and combo_goes_on(m):
		pass  # F849 🔁 (owner, Nov 25: "he does two attacks and then just stands there"): a boss swings his whole combo
	elif not m.stun.is_stunned():
		m.state = Monster.State.RECOVER  # staggered for a moment
		m._timer = 0.6
	monster_changed(m)


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_spawn(uid: int, kind: String, pos: Vector3, leader: bool, pack: int, variant: String = "", surface := Vector3.ZERO) -> void:
	if not Monsters.LIST.has(kind):
		return  # a creature the game no longer has (an old save's boss or early creature, Nov 19)
	var m: Monster = MONSTER_SCRIPT.new()
	m.setup(uid, kind, leader, pos, variant)
	m.pack_id = pack
	m._mgr = self
	_root.add_child(m)
	m.global_position = pos
	if surface != Vector3.ZERO:
		m.apply_surface(surface)  # (up on a wall or ceiling: climbing, F474/F475)
		m._sent_surface = surface
	monsters[uid] = m
	_next_uid = maxi(_next_uid, uid + 1)


## F881 (owner, Nov 25: bats and Rock Snails died with a dwarf's death cry): their own last sounds.
## Owner, Nov 25: "fix the enemy dying, it doesn't match anyone": every other creature too (tools/art/make_death_sounds.py).
const DEATH_SOUNDS := {"cave_bat": "bat_death", "rock_snail": "snail_death", "rock_beetle": "beetle_death",
	"great_rock_beetle": "beetle_death", "cave_spider": "spider_death"}


## The ghosts blow apart into mist; the skeleton miners (they rise from the floor) fall into a heap of bones.
static func death_sound(kind: String) -> String:
	if DEATH_SOUNDS.has(kind):
		return DEATH_SOUNDS[kind]
	var data: Dictionary = Monsters.LIST.get(kind, {})
	if data.get("ghost", false):
		return "ghost_boss_death" if data.get("boss", false) else "ghost_death"
	if data.get("rises", false):
		return "boss_death" if data.get("boss", false) else "bones_death"
	return "death"


## F707 (owner's picks, sound rounds 6+7, Nov 26): each creature's own cry when hit, on top of the weapon's hit sound.
const HURT_SOUNDS := {"cave_spider": "spider_hurt", "rock_snail": "snail_hurt", "rock_beetle": "beetle_hurt",
	"great_rock_beetle": "beetle_hurt", "cave_bat": "bat_hurt"}
static func hurt_sound(kind: String) -> String:
	if HURT_SOUNDS.has(kind):
		return HURT_SOUNDS[kind]
	return "bones_hurt" if Monsters.LIST.get(kind, {}).get("rises", false) else ""


## F854 (owner, Nov 25: "the mace makes a sword sound"): blunt weapons land with a dull knock and crunch.
## Creatures that bite, claw or ram you with their own body (no weapon in hand).
const BEASTS := ["cave_bat", "rock_beetle", "great_rock_beetle", "cave_spider", "rock_snail"]


## The sound when a creature's blow lands on YOU. F925 (owner, Nov 27: "getting hit by a bat sounds like a 'ding'"):
## the old "hit" is a sword landing, so a bite rang like metal. Beasts now land with a soft body hit
## Rounds 12-14 found no bite the owner liked; Nov 28 the owner chose the dwarf's own "oof" (the `hurt` grunt that
## every hit already plays), so a beast's bite adds no sound on top. Armed creatures keep the weapon sounds.
static func you_hit_sound(kind: String, damage: float) -> String:
	if kind in BEASTS:
		return ""
	return "hit_heavy" if damage >= 15 else "hit"


func hit_sound(peer: int, heavy: bool) -> String:
	var ps: GameAuthority.PlayerState = auth.get_player(peer) if auth and peer != 0 else null
	var w := Combat.weapon_of(ps.selected_item()) if ps else ""
	# F707 (owner's picks, Nov 26): each weapon lands with its own sound.
	if WEAPON_HITS.has(w):
		return WEAPON_HITS[w]
	if Combat.WEAPONS.get(w, {}).get("type", "") == "blunt":
		return "hit_blunt"
	return "hit_heavy" if heavy else "hit"
const WEAPON_HITS := {"axe": "hit_axe", "axe_2h": "hit_axe_2h", "mace": "hit_mace", "mace_2h": "hit_warhammer",
	"spear": "hit_spear"}


@rpc("authority", "call_local", "reliable")
func _ev_remove(uid: int, statue := -1) -> void:
	var m: Monster = monsters.get(uid)
	monsters.erase(uid)
	if m:
		Fx.burst(_root, m.global_position + Vector3.UP * 0.4, m.data.color, 18, 3.0)
		Sfx.play(death_sound(m.kind), m.global_position)
		m.die_visual(statue)  # goes limp, then turns to stone (statue >= 0) or sinks away (only looks)


const HIT_STOP := 0.06        ## seconds both fighters freeze on a hit (owner, Nov 18: "juicy hits")
const HIT_STOP_HEAVY := 0.11  ## ... on a big hit


## What the hitter feels on their own screen (F800): {} on everyone else's screen; the hitter freezes `stop` seconds,
## longer for a killing blow, which also pushes their camera in (`push`). Nobody else's game slows (co-op).
static func hitter_feel(peer: int, local_peer: int, heavy: bool, killed: bool) -> Dictionary:
	if peer == 0 or peer != local_peer:
		return {}
	if killed:
		return {stop = DwarfFeel.KILL_STOP_HEAVY if heavy else DwarfFeel.KILL_STOP, push = true}
	return {stop = HIT_STOP_HEAVY if heavy else HIT_STOP, push = false}


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
	var needed: int = m.data.get("statue_hits", 2)
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
	if Statue.distance_to(id, chest, at) > GameAuthority.REACH + STATUE_REACH:  # (F952: to its nearest stone, not its middle)
		return "too_far"
	if Items.kind(ps.selected_item()) != "pickaxe":
		auth._tell_feedback(peer_id, {state = "no_tool", point = at, why = "Stone! Use a pickaxe."})
		return "no_tool"
	st.hits += 1
	auth.give_xp(peer_id, 1, "mining")
	var out := (chest - at).normalized()
	if st.hits < st.needed:
		_ev_statue_hit.rpc(id, st.hits, st.needed)
		auth._tell_feedback(peer_id, {state = "hit", hits = st.hits, needed = st.needed, material = Mat.STONE, point = at, normal = out, statue = true})
		return "hit"
	statues.erase(id)
	for d in st.loot:
		auth.spawn_drop(d[0], d[1], at + out * 0.4 + Vector3.UP * 0.3)
	_ev_statue_gone.rpc(id, true)
	auth._tell_feedback(peer_id, {state = "dug", hits = st.hits, needed = st.needed, material = Mat.STONE, point = at, normal = out, boulder = true, statue = true})
	return "dug"


# ================================================================== the Prop Warden's Rally Slam (owner, Nov 21)
# About every 25 s (its rest) he raises his plank and slams it down; the stone of his fallen Lost Miners in his room
# glows and shakes for the 2 s wind-up, then up to 2 of them get up again. Never more than RAISE_MAX_UP miners up at
# once. A hit on him during the slam calls it off; a statue mined away can't be raised. Host decides, everyone sees.
const RAISE_KIND := "lost_miner"
const RAISE_MAX_UP := 3       ## miners standing at once (with the raised ones)
const RAISE_MIN_AGE := 4.0    ## s a statue lies before he can raise it (time to start mining it)
const RAISE_REACH := 16.0     ## m: outside a dungeon (tests), how far he reaches; in one, his own room


## Host: the stone miners he could raise now, nearest first, as many as he may (empty = no Rally Slam).
func raisable_statues(m: Monster) -> Array:
	if not m.dungeon.is_empty() and m.dungeon.map.get("no_raising", false):
		return []  # (this dungeon's boss doesn't raise the fallen: Mossprop, F592)
	var up := 0
	for u in monsters:
		var o: Monster = monsters[u]
		if o.kind == RAISE_KIND and o.is_alive() and o.pack_id == m.pack_id and o.global_position.distance_to(m.global_position) < 30.0:
			up += 1
	var room_for := RAISE_MAX_UP - up
	if room_for <= 0:
		return []
	var found := []
	for id in statues:
		var st: Dictionary = statues[id]
		if st.kind != RAISE_KIND or STATUE_LIFE - float(st.left) < RAISE_MIN_AGE:
			continue
		var p: Vector3 = st.pos
		if m.dungeon.is_empty():
			if p.distance_to(m.global_position) > RAISE_REACH:
				continue
		elif DungeonMap.space_at(m.dungeon, p + Vector3.UP) != m.dungeon_room:
			continue
		found.append([p.distance_to(m.global_position), id])
	found.sort()
	var ids := []
	for f in found.slice(0, mini(room_for, 2)):
		ids.append(f[1])
	return ids


## Host: the slam starts: pick the statues, and everyone sees them glow and shake.
func start_raise(m: Monster, atk: Dictionary) -> void:
	m.raising = raisable_statues(m).slice(0, int(atk.get("raise_miners", 2)))
	if m.raising.is_empty():
		return
	_ev_note.rpc(m.uid, "Rise, my miners!")
	_ev_stir.rpc(PackedInt32Array(m.raising), float(atk.tell))


## A boss in the middle of a `chain` combo (Hald's four mace blows) isn't staggered by one parry (only a full daze bar stops him): each parry still
## dazes him a bit and sparks, but his last, hardest blows come too.
static func combo_goes_on(m: Monster) -> bool:
	return m.data.get("boss", false) and m.state == Monster.State.ATTACK and m._attack.get("chain", false)


## Host: a hit during the slam: called off (the glow stops; he needs a moment, and the move rests as usual).
func cancel_raise(m: Monster) -> void:
	var ids := PackedInt32Array(m.raising)
	m.raising = []
	m.state = Monster.State.RECOVER
	m._attack = {}
	m._timer = 1.2
	_ev_stir.rpc(ids, 0.0)
	_ev_note.rpc(m.uid, "Stopped!")


## Host: the slam lands: each chosen statue still there becomes a Lost Miner again, getting up and coming for you.
func finish_raise(m: Monster) -> Array:
	var uids := []
	for id in m.raising:
		var st: Dictionary = statues.get(id, {})
		if st.is_empty():
			continue  # mined away (or crumbled) during the slam
		statues.erase(id)
		_ev_statue_gone_raised.rpc(id)
		var uid := _next_uid
		_next_uid += 1
		_ev_spawn.rpc(uid, RAISE_KIND, (st.pos as Vector3) + Vector3.UP * 0.3, false, m.pack_id)
		var mon: Monster = monsters.get(uid)
		if mon == null:
			continue
		mon.dungeon = m.dungeon
		mon.dungeon_room = m.dungeon_room
		mon.alert(m.target_peer if m.target_peer != 0 else m.last_hitter)  # (it gets up from its bones, then runs at you)
		var room: Dictionary = _rooms.get(m.pack_id, {})
		if not room.is_empty():
			room.alive.append(uid)  # (the room isn't cleared while they stand)
		uids.append(uid)
	m.raising = []
	return uids


## Everyone: the chosen statues glow and shake for `seconds` (0 = stop).
@rpc("authority", "call_local", "reliable")
func _ev_stir(ids: PackedInt32Array, seconds: float) -> void:
	for id in ids:
		Statue.stir(id, seconds)


@rpc("authority", "call_local", "reliable")
func _ev_statue_gone_raised(id: int) -> void:
	Statue.raise_away(id)


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


## Host: a ghost owes a jump (owner, Nov 25: "if I shoot them from far away ... they stop teleporting": you stood in a
## narrow doorway or corridor, there was no room behind you, and that quarter's jump was lost). A few times a second
## it looks again for a spot behind you; true when it jumped now.
func ghost_owed_jump(m: Monster, target: Node3D) -> bool:
	if not m.has_meta("ghost_jump_owed") or Ghost.hidden(m) or target == null:
		return false
	if _clock < float(m.get_meta("ghost_jump_owed")):
		return false
	m.set_meta("ghost_jump_owed", _clock + 0.3)
	var spot := Ghost.spot_behind(m, target, auth.world.maker if auth and auth.world else null, m.dungeon)
	if spot == Vector3.INF:
		return false
	m.remove_meta("ghost_jump_owed")
	ghost_fade(m, spot)
	return true


## A ghost fades into mist and comes back at `to` (Ghost; the host picked the spot after a quarter of its health).
## Its swing is called off: the hits it was about to land are dropped everywhere.
func ghost_fade(m: Monster, to: Vector3) -> void:
	# Owner, Nov 25 (4th round): "anytime they teleport they should teleport behind me, facing me, and always attack":
	# no daze or push from your hit is carried along; it comes back chasing (CHASE swings the ambush at once).
	m.stun.stunned_left = 0.0
	m.stun.value = 0.0
	m._knock = Vector3.ZERO
	m.state = Monster.State.CHASE
	m._attack = {}
	m._best_dist = INF  # (F873: it came back further away: that isn't "can't get closer", so it doesn't give up)
	m._no_progress = 0.0
	_ev_ghost_fade.rpc(m.uid, to)


@rpc("authority", "call_local", "reliable")
func _ev_ghost_fade(uid: int, to: Vector3) -> void:
	_incoming = _incoming.filter(func(h: Dictionary) -> bool: return int(h.get("uid", -1)) != uid)
	var m: Monster = monsters.get(uid)
	if m:
		Ghost.show_fade(m, to)


## F792 (owner's picks, Nov 26): a creature that spots you gives a warning cry (skeletons pitched by size).
static func notice_sound(kind: String) -> String:
	var data: Dictionary = Monsters.LIST.get(kind, {})
	if kind == "cave_spider":
		return "spider_notice"
	if kind in ["rock_beetle", "great_rock_beetle"]:
		return "beetle_notice"
	if data.get("ghost", false):
		return "ghost_notice"
	if data.get("rises", false):
		return "boss_notice" if data.get("boss", false) else "bones_notice"
	return ""  # (snail: owner said skip; bats have none)


func monster_notice(m: Monster) -> void:
	if notice_sound(m.kind) != "":
		_ev_notice.rpc(m.uid)


@rpc("authority", "call_local", "reliable")
func _ev_notice(uid: int) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		Sfx.play(notice_sound(m.kind), m.global_position, 0.0, m._voice())


## Host: a pile of bones gets up (F462). Everyone sees it rise.
func monster_rise(m: Monster) -> void:
	_ev_rise.rpc(m.uid)


@rpc("authority", "call_local", "reliable")
func _ev_rise(uid: int) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		m.show_rise()


## A short word floating up over a monster ("Weak spot!").
@rpc("authority", "call_local", "reliable")
func _ev_note(uid: int, text: String) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		_float_number(m.global_position + Vector3.UP * 1.6, text)


@rpc("authority", "call_local", "reliable")
func _ev_hit(uid: int, dmg: int, from := Vector3.ZERO, peer := 0, eff := 0, crit := false, killed := false) -> void:
	var m: Monster = monsters.get(uid)
	if m:
		# Juicy hits (owner, Nov 18): sparks spray AWAY from the hitter, both fighters freeze for a blink (a bigger hit, a
		# longer freeze), the hitter's screen shakes, and a heavy hit bounces the dwarf back a little.
		var heavy := dmg >= 20
		var away := (m.global_position - from) * Vector3(1, 0, 1)
		var dir := (away.normalized() + Vector3.UP * 0.35) if from != Vector3.ZERO and away.length() > 0.01 else Vector3.UP
		# F717: the bits fly from where the weapon touched: on the side facing the hitter, at the creature's chest height.
		var side := -away.normalized() if from != Vector3.ZERO and away.length() > 0.01 else Vector3.ZERO
		# (Owner, Nov 23: a skeleton lying on the floor still got sparks at standing chest height: a body that is knocked
		# down or dead lies low, so the bits come from just above the floor, further out toward the hitter.)
		var lying: bool = m.rig != null and (m.rig.knocked_down or m.rig.dead or m.rig.lying)
		var at := m.global_position + Vector3.UP * (float(m.data.get("height", 1.0)) * (0.12 if lying else 0.55)) 				+ side * float(m.data.get("size", 1.0)) * (0.6 if lying else 0.35)
		if m.shell_shut:
			# Hitting a hidden snail: a hard stony clank and sparks (it's barely hurt).
			Fx.burst(_root, m.global_position + Vector3.UP * 0.6, Color(1.0, 0.75, 0.35), 12, 4.5, dir, 40.0)
			Sfx.play("shell_clank", m.global_position)
		else:
			Fx.hit(_root, at, Fx.hit_body(m.kind), dir, heavy, crit, m.data.get("color", Color(0.5, 0.45, 0.4)))
			if m.data.get("ghost", false):
				Sfx.play("ghost_hit", m.global_position, 0.0 if heavy else -3.0, 0.85 if heavy else 1.0)  # (F874: mist and cloth, no ring)
			else:
				Sfx.play(hit_sound(peer, heavy), m.global_position)
				var cry := hurt_sound(m.kind)
				if cry != "" and not killed:  # (a killed creature gives its death cry instead)
					Sfx.play(cry, m.global_position, -2.0, m._voice())
		var feel := hitter_feel(peer, auth.local_peer_id(), heavy, killed)
		m.hit_flash()
		m.hit_stop(feel.get("stop", HIT_STOP_HEAVY if heavy else HIT_STOP))  # (the killer sees it freeze longer too)
		if not feel.is_empty():
			var me := player_node(peer)
			if me and me.has_method("hit_stop"):
				me.hit_stop(feel.stop)
				me.add_shake(0.45 if heavy else 0.25)
				if feel.push:
					me.kill_push()
				if heavy and away.length() > 0.01:
					me.shove(-away.normalized() * 2.2)  # (a heavy hit bounces you back off it)
		_float_number(m.global_position + Vector3.UP * 1.4, str(dmg) + ("!" if crit else ""), heavy, dir, CRIT_COLOR if crit else EFFECT_COLOR[eff + 1], crit, dmg)


@rpc("authority", "unreliable_ordered")
func _ev_poses(ids: PackedInt32Array, pos: PackedVector3Array, yaw: PackedFloat32Array) -> void:
	for i in ids.size():
		var m: Monster = monsters.get(ids[i])
		if m:
			m.set_net(pos[i], yaw[i])


## A number (or a word) that pops up over a creature. Round 2 (owner, Nov 18, the Disney rules: "nothing flies
## straight, not the damage numbers"): it pops in (small, too big, then its size) and flies in an arc, away from the
## hit, up and over; a big hit's number is bigger and warmer.
## The hit number's colour by how the creature takes the damage type (owner, chat 16): resists = grey, normal = white,
## weak to it = yellow. A big hit is still bigger.
const EFFECT_COLOR := [Color(0.6, 0.6, 0.6), Color(1.0, 1.0, 1.0), Color(1.0, 0.85, 0.15)]


## A crit's number: hot red (owner F788: "crits bigger and a different colour").
const CRIT_COLOR := Color(1.0, 0.22, 0.18)


## How big a hit's number is (F788): a bigger hit = a bigger number, a heavy one bigger still, a crit biggest.
static func number_scale(dmg: int, big: bool, crit: bool) -> float:
	var s := clampf(0.8 + float(dmg) / 70.0, 0.8, 1.3)
	return s * (1.25 if big else 1.0) * (1.55 if crit else 1.0)


func _float_number(at: Vector3, text: String, big := false, away := Vector3.ZERO, color := Color(-1, 0, 0), crit := false, dmg := 0) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64 if (big or crit) else 48
	l.pixel_size = 0.005
	l.outline_size = 14 if crit else (12 if big else 10)
	l.outline_modulate = Color(0.12, 0.0, 0.0) if crit else Color(0.0, 0.0, 0.0)
	l.no_depth_test = true
	l.modulate = color if color.r >= 0.0 else (Color(1.0, 0.62, 0.25) if big else Color(1.0, 0.9, 0.5))
	_root.add_child(l)
	l.global_position = at
	var side := Vector3(away.x, 0.0, away.z)
	side = side.normalized() if side.length() > 0.01 else Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	side *= randf_range(0.35, 0.6)
	var rise := 1.0 if (big or crit) else 0.8
	# Grow fast to a big pop, settle to its size, then shrink away while it fades (owner F788).
	var size := number_scale(dmg, big, crit) if dmg > 0 else (1.2 if big else 1.0)
	l.scale = Vector3.ONE * 0.3
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector3.ONE * size * 1.35, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "scale", Vector3.ONE * size, 0.1)
	t.tween_property(l, "scale", Vector3.ONE * size * 0.45, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_method(func(u: float) -> void:
		if is_instance_valid(l):
			l.global_position = at + side * u + Vector3.UP * (rise * 1.6 * u - rise * 0.75 * u * u), 0.0, 1.0, 0.7)  # (an arc: up, over, a little down)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.17)
	t.tween_callback(l.queue_free)


# ================================================================== late joiners

func snapshot() -> Array:
	var out := []
	for m: Monster in monsters.values():
		out.append([m.uid, m.kind, m.global_position, m.leader, m.pack_id, m.hp, m.variant, m.surface])
	return out


func load_snapshot(list: Array) -> void:
	for e in list:
		_ev_spawn(e[0], e[1], e[2], e[3], e[4], e[6] if e.size() > 6 else "", e[7] if e.size() > 7 else Vector3.ZERO)
		if monsters.has(e[0]):  # (skipped if it's a creature the game no longer has)
			monsters[e[0]].hp = e[5]
