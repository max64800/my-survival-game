class_name Builder
extends Node
## Builder: everything that's been built, and every cave-in. A helper of the GameAuthority,
## using the same pattern: ask_* (your computer) → request_* (host approves) → _ev_* (everyone).
## Lives at Authority/Builder on every computer.

const PIECE_SCRIPT := preload("res://src/build/piece_node.gd")
const CHECK_DELAY := 0.05  ## cave-in checks run a moment after a dig
const WARN_TIME := 1.0  ## dust and rumble before rock falls
const BREAK_DELAY := 2.0  ## soft physics (spec §5): shaky pieces creak and shake for 2 s first

const RUBBLE_DAMAGE := 15.0

var auth: GameAuthority
var structure := Structure.new()
var nodes := {}  ## uid -> PieceNode
var ladders := {}  ## uid -> true for every built ladder (dwarves climb them)
var pieces_root: Node3D
var fall_log: Array[PackedVector3Array] = []  ## every cave-in, for friends who join later
var _next_uid := 1
var _clock := 0.0
var rubble := {}  ## rubble id -> Rubble (fallen pieces lying around, F90)
var _next_rubble := 1
signal message(text: String)  ## a short note for this player (shown at the top of the screen)
var _placed_at := {}  ## host: uid -> when it was placed (careful pick-up works for PICKUP_TIME seconds)
## Taking pieces down (owner, Nov 15, F100): a careful pick-up gives everything back, but only right
## after placing (a misclick); breaking a piece gives back BREAK_SHARE of what it cost.
const PICKUP_TIME := 10.0
const BREAK_SHARE := 0.8
var _checks := []  ## host: [time, center, radius]
var _falls := []  ## host: [time, points]
var _breaks := []  ## host: [time, uid]
var _pending_falls: Array[PackedVector3Array] = []  ## falls waiting for that area to load here
var sites := {}  ## Builder's Chest box id -> build site (see _ev_site)
var _site_timer := 0.0
var _site_ticks := 0
const MAX_SITES := 3
const SITE_TICK := 0.5  ## carve every 0.5 s, build every 1 s
const CHEST_RANGE := 16.0
const CARVE_RADIUS := 0.8  ## gentle scoops, so the floor under the building stays
const CARVES_PER_TICK := 3


func _ready() -> void:
	auth = get_parent()
	pieces_root = Node3D.new()
	pieces_root.name = "Pieces"
	add_child(pieces_root)


# ================================================================== ask

func ask_place(piece: String, family: String, pos: Vector3, rot: int) -> void:
	if auth.is_host():
		request_place(auth.local_peer_id(), piece, family, pos, rot)
	else:
		_rpc_place.rpc_id(1, piece, family, pos, rot)


## smash = false: careful pick-up (all back, only right after placing); true: break it (80% back).
func ask_remove(uid: int, smash: bool = false) -> void:
	if auth.is_host():
		var why := request_remove(auth.local_peer_id(), uid, smash)
		if why != "":
			message.emit(why)
	else:
		_rpc_remove.rpc_id(1, uid, smash)


## Open or close a built door (E while looking at it).
func ask_door(uid: int) -> void:
	if auth.is_host():
		request_door(auth.local_peer_id(), uid)
	else:
		_rpc_door.rpc_id(1, uid)


@rpc("any_peer", "reliable")
func _rpc_door(uid: int) -> void:
	if auth.is_host():
		request_door(multiplayer.get_remote_sender_id(), uid)


@rpc("any_peer", "reliable")
func _rpc_place(piece: String, family: String, pos: Vector3, rot: int) -> void:
	if auth.is_host() and pos.is_finite():
		request_place(multiplayer.get_remote_sender_id(), piece, family, pos, rot)


@rpc("any_peer", "reliable")
func _rpc_remove(uid: int, smash: bool = false) -> void:
	if auth.is_host():
		var why := request_remove(multiplayer.get_remote_sender_id(), uid, smash)
		if why != "":
			_ev_message.rpc_id(multiplayer.get_remote_sender_id(), why)


## A note for one player (why their take-down didn't work).
@rpc("authority", "reliable")
func _ev_message(text: String) -> void:
	message.emit(text)


# ================================================================== approve (host)

## Why this piece can't go here, or "" if it can. Used by the host to approve, and by
## the ghost to turn red (same rules on both sides).
func problem(ps: GameAuthority.PlayerState, piece: String, family: String, pos: Vector3, rot: int) -> String:
	if not Pieces.allowed(piece, family):
		return "Can't be made from %s" % Pieces.FAMILIES.get(family, {}).get("name", family)
	if ps.node.global_position.distance_to(pos) > Pieces.BUILD_REACH + 1.0:
		return "Too far away"
	var station_why := station_problem(piece, family, pos)
	if station_why != "":
		return station_why
	var rock := Pieces.rock_problem(piece, pos, rot, auth.world.sdf_at)
	if rock != "":
		return rock
	if structure.overlaps(piece, pos, rot):
		return "Something is already there"
	var b := Pieces.box(piece, pos, rot)
	for pid in auth.players:
		var body: Vector3 = auth.players[pid].node.global_position
		if b.grow(0.1).has_point(body + Vector3.UP * 0.3) or b.grow(0.1).has_point(body + Vector3.UP * 1.1):
			return "Someone is in the way"
	var anchored := Pieces.touches_rock(piece, pos, rot, auth.world.sdf_at)
	if structure.preview_stability(piece, family, pos, rot, anchored) < Pieces.MIN_STABILITY:
		return "Not steady enough here"
	var cost := Pieces.cost(piece, family)
	for item in cost:
		if ps.inventory.count_of(item) < cost[item]:
			return "Needs %d %s" % [cost[item], Items.display_name(item)]
	return ""


func request_place(peer_id: int, piece: String, family: String, pos: Vector3, rot: int) -> String:
	var ps := auth.get_player(peer_id)
	if ps == null or not Pieces.LIST.has(piece) or not pos.is_finite():
		return "?"
	if not Pieces.valid_rot(rot):
		rot = 0
	var why := problem(ps, piece, family, pos, rot)
	if why != "":
		return why
	var cost := Pieces.cost(piece, family)
	for item in cost:
		ps.inventory.remove(item, cost[item])
	var uid := _next_uid
	_next_uid += 1
	_ev_add_piece.rpc(uid, piece, family, pos, rot, Pieces.touches_rock(piece, pos, rot, auth.world.sdf_at))
	_placed_at[uid] = _clock
	auth.give_xp(peer_id, 2, "smithing")
	return ""


## Host: take piece `uid` down. Returns "" when done, or why not (shown to the player).
## Careful pick-up (smash = false) gives back everything, but only within PICKUP_TIME seconds of
## placing it; breaking it (smash = true) works any time and gives back 80% (rounded down, at least 1).
func request_remove(peer_id: int, uid: int, smash: bool = false) -> String:
	var ps := auth.get_player(peer_id)
	if ps == null or not structure.pieces.has(uid):
		return "?"
	var p: Dictionary = structure.pieces[uid]
	if ps.node.global_position.distance_to(p.pos) > Pieces.BUILD_REACH + 1.0:
		return "Too far away"
	var fresh: bool = _clock - float(_placed_at.get(uid, -INF)) <= PICKUP_TIME
	if not smash and not fresh:
		return "Too late to pick it up (only right after placing). Press X to break it for 80%."
	var cost := Pieces.cost(p.piece, p.family)
	for item in cost:
		var n: int = cost[item] if not smash else maxi(1, floori(cost[item] * BREAK_SHARE))
		var left := ps.inventory.add(item, n)
		if left > 0:
			auth.spawn_drop(item, left, p.pos + Vector3.UP)
	_placed_at.erase(uid)
	_ev_remove_piece.rpc(uid)
	return ""


## Building polish spec §3: wood pieces need a Workbench, stone/brick a Mason's Table, copper an
## Anvil, within 20 m and at the piece's level (more extras around the station = higher level).
const STATION_KIND := {"workbench": "workbench", "mason": "masonry_table", "anvil": "anvil"}


## Host: a player wants to open/close door `uid`. They must be close to it.
func request_door(peer_id: int, uid: int) -> bool:
	var ps := auth.get_player(peer_id)
	var p: Dictionary = structure.pieces.get(uid, {})
	if ps == null or p.is_empty() or p.piece != "door":
		return false
	if ps.node and ps.node.global_position.distance_to(p.pos) > Pieces.BUILD_REACH:
		return false
	_ev_door.rpc(uid, not p.get("open", false))
	return true


## Is there a built ladder at `pos` (a dwarf's feet)? Same reach as rope ladders.
func ladder_at(pos: Vector3) -> bool:
	for uid in ladders:
		var p: Dictionary = structure.pieces.get(uid, {})
		if p.is_empty():
			continue
		var d: Vector3 = pos - p.pos
		if Vector2(d.x, d.z).length() < 0.8 and d.y > -0.5 and d.y < Pieces.LIST.ladder.size.y + 0.3:
			return true
	return false


## Where a blueprint's Builder's Chest goes: just outside the building, on the side nearest
## `from` (the player), on open floor. Tries all four sides. Vector3.INF = nowhere fits.
static func chest_spot(size: Vector3, origin: Vector3, rot: int, from: Vector3, sdf: Callable) -> Vector3:
	var sides := []
	for k in 4:
		var dir := Basis(Vector3.UP, (rot + k) * PI / 2.0) * Vector3(0, 0, 1)
		var reach: float = (size.z if k % 2 == 0 else size.x) * 0.5 + 1.5
		sides.append(origin + dir * reach)
	sides.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(from) < b.distance_to(from))
	for c: Vector3 in sides:
		# Look for a floor from 2 m above the building's base down to 3 m below it.
		var y := origin.y + 2.0
		while y > origin.y - 3.0:
			var here := Vector3(c.x, y, c.z)
			if float(sdf.call(here)) <= 0.0:
				if float(sdf.call(here + Vector3.UP * 0.5)) > 0.0 and float(sdf.call(here + Vector3.UP * 1.2)) > 0.0:
					return here + Vector3.UP * 0.25
				break  # rock straight away: this side is inside the mountain
			y -= 0.25
	return Vector3.INF


func station_problem(piece: String, family: String, pos: Vector3) -> String:
	var kind: String = STATION_KIND[Pieces.station_for(family)]
	var need := Pieces.needed_level(piece, family)
	var best := 0
	var nearest: Station = null
	for st in auth.stations.values():
		if st.kind == kind and st.global_position.distance_to(pos) <= Pieces.WORKBENCH_RANGE:
			var lvl: int = (st as Station).level()
			if lvl > best:
				best = lvl
				nearest = st
	var name := Items.display_name(kind)
	if nearest == null:
		return "Needs a %s within 20 m" % name
	if best < need:
		var extra := nearest.next_extra()
		return "Needs %s level %d (build a %s next to it)" % [name, need, Items.display_name(extra)] if extra != "" \
			else "Needs %s level %d" % [name, need]
	return ""


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_add_piece(uid: int, piece: String, family: String, pos: Vector3, rot: int, anchored: bool) -> void:
	Sfx.play("build", pos, -2.0, 1.2 if family in ["cut_stone", "cut_marble", "clay_brick"] else 1.0)
	structure.add(uid, piece, family, pos, rot, anchored)
	var n: PieceNode = PIECE_SCRIPT.new()
	n.uid = uid
	n.piece = piece
	n.family = family
	pieces_root.add_child(n)
	n.global_position = pos
	n.rotation.y = Pieces.yaw_of(rot)
	nodes[uid] = n
	if piece == "ladder":
		ladders[uid] = true
	_next_uid = maxi(_next_uid, uid + 1)
	if auth.is_host():
		_queue_shaky()


@rpc("authority", "call_local", "reliable")
func _ev_remove_piece(uid: int) -> void:
	var p: Dictionary = structure.pieces.get(uid, {})
	structure.remove(uid)
	ladders.erase(uid)
	var n: Node = nodes.get(uid)
	nodes.erase(uid)
	if n:
		n.queue_free()
	if auth.is_host() and not p.is_empty():
		_queue_shaky()
		if Pieces.LIST[p.piece].get("supports_rock", false):
			queue_check(Pieces.box(p.piece, p.pos, p.rot).end, 1.5)  # was holding rock up!


@rpc("authority", "call_local", "reliable")
func _ev_door(uid: int, open: bool) -> void:
	if not structure.pieces.has(uid):
		return
	structure.pieces[uid]["open"] = open
	Sfx.play("build", structure.pieces[uid].pos, -8.0, 1.6 if open else 1.3)
	if nodes.has(uid):
		(nodes[uid] as PieceNode).set_open(open)


@rpc("authority", "call_local", "reliable")
func _ev_warn(center: Vector3) -> void:
	Sfx.play("dig_break", center, 4.0, 0.55)  # deep rumble before a cave-in
	Fx.burst(get_parent(), center, Color(0.55, 0.5, 0.45), 30, 1.5)


@rpc("authority", "call_local", "reliable")
func _ev_cave_in(points: PackedVector3Array) -> void:
	fall_log.append(points)
	_pending_falls.append(points)
	_apply_pending_falls()


func _apply_pending_falls() -> void:
	var still: Array[PackedVector3Array] = []
	for pts in _pending_falls:
		var b := _bounds(pts)
		if not auth.world.is_ready_at(b.get_center(), b.size.length() * 0.5 + 1.0):
			still.append(pts)
			continue
		var counts := auth.world.remove_voxels(pts)
		_rubble(b, counts)
		if auth.is_host():
			_after_fall(b, counts)
	_pending_falls = still


# ================================================================== host: checks over time

## Called by the authority after every dig (and by us after a support is removed).
func queue_check(center: Vector3, radius: float) -> void:
	for c in _checks:
		if c[1].distance_to(center) < 2.0:
			return  # one check per area at a time
	_checks.append([_clock + CHECK_DELAY, center, radius])


## Rock was dug near some pieces: are they still touching rock?
func reanchor_near(center: Vector3, radius: float) -> void:
	var changed := false
	for uid in structure.pieces:
		var p: Dictionary = structure.pieces[uid]
		if not p.anchored or p.pos.distance_to(center) > radius + 4.0:
			continue
		if not Pieces.touches_rock(p.piece, p.pos, p.rot, auth.world.sdf_at):
			p.anchored = false
			changed = true
	if changed:
		_queue_shaky()


func _process(delta: float) -> void:
	_clock += delta
	if not _pending_falls.is_empty():
		_apply_pending_falls()
	if not auth.is_host():
		return
	_site_timer -= delta
	if _site_timer <= 0.0:
		_site_timer = SITE_TICK
		_site_ticks += 1
		if not sites.is_empty():
			_tick_sites()
	while not _checks.is_empty() and _checks[0][0] <= _clock:
		var c: Array = _checks.pop_front()
		_run_check(c[1], c[2], c[3] if c.size() > 3 else 0)
	while not _falls.is_empty() and _falls[0][0] <= _clock:
		_ev_cave_in.rpc(_falls.pop_front()[1])
	while not _breaks.is_empty() and _breaks[0][0] <= _clock:
		var uid: int = _breaks.pop_front()[1]
		if not structure.pieces.has(uid):
			continue
		if not structure.recompute().has(uid):
			_ev_shake.rpc(uid, false)  # someone propped it up in time: saved!
			continue
		# It falls and lands as rubble; its materials come back when you clear the rubble (F90).
		var rid := _next_rubble
		_next_rubble += 1
		_ev_collapse.rpc(uid, rid, _landing_for(uid))


func _run_check(center: Vector3, radius: float, tries: int = 0) -> Array:
	var box := CaveIns.box_for(center)
	# Keep the box inside the world's limits (outside them nothing ever loads).
	var lim := auth.world.terrain.bounds
	var lo := Vector3i(Vector3(box[0]).max(lim.position))
	var hi := Vector3i((Vector3(box[0]) + Vector3(box[1])).min(lim.end))
	var buf := auth.world.copy_area(lo, hi - lo)
	if buf == null:
		if tries < 20:  # not loaded yet: try again soon
			_checks.append([_clock + 0.5, center, radius, tries + 1])
		return []
	box = [lo, hi - lo]
	var falls := CaveIns.find_falls(buf, box[0], center, radius, support_points())
	for pts in falls:
		_ev_warn.rpc(_bounds(pts).get_center())
		_falls.append([_clock + WARN_TIME, pts])
	return falls


## Tops of mine props and ceiling panels: rock touching these is held up.
func support_points() -> Array:
	var out := []
	for uid in structure.pieces:
		var p: Dictionary = structure.pieces[uid]
		if Pieces.LIST[p.piece].get("supports_rock", false):
			var b := Pieces.box(p.piece, p.pos, p.rot)
			var top := Vector3(b.get_center().x, b.end.y + 0.5, b.get_center().z)
			out.append(top)
			out.append(top + Vector3(b.size.x * 0.4, 0, b.size.z * 0.4))
			out.append(top - Vector3(b.size.x * 0.4, 0, b.size.z * 0.4))
	return out


func _after_fall(b: AABB, counts: Dictionary) -> void:
	# Rubble turns into items: 1 per 4 rock voxels.
	for mat in counts:
		var item: String = Mat.DROP_ITEM.get(mat, "")
		if item != "" and counts[mat] >= 4:
			auth.spawn_drop(item, counts[mat] / 4, b.get_center())
	# Anyone underneath gets bonked.
	for pid in auth.players:
		var body: Vector3 = auth.players[pid].node.global_position
		var under := AABB(b.position - Vector3(1, 6, 1), b.size + Vector3(2, 6, 2))
		if under.has_point(body + Vector3.UP):
			auth.hurt(pid, RUBBLE_DAMAGE)
	reanchor_near(b.get_center(), b.size.length() * 0.5)
	queue_check(b.get_center() + Vector3.UP * b.size.y * 0.5, 1.5)  # chain: did that loosen more?


func _queue_shaky() -> void:
	for uid in structure.recompute():
		var already := false
		for br in _breaks:
			if br[1] == uid:
				already = true
		if not already:
			_breaks.append([_clock + BREAK_DELAY + 0.15 * _breaks.size(), uid])
			_ev_shake.rpc(uid, true)


## Everyone: a piece starts (or stops) creaking and shaking.
@rpc("authority", "call_local", "reliable")
func _ev_shake(uid: int, on: bool) -> void:
	var n: PieceNode = nodes.get(uid)
	if n:
		n.set_shaking(on)
		if on:
			Sfx.play("dig_soft", n.global_position, -4.0, 0.55)  # a low creak


## Everyone: a piece gives way. It tumbles to where the host says it lands and stays there as
## solid rubble (F90): you bump into it, stand on it, and clear it with a pickaxe for half its materials.
@rpc("authority", "call_local", "reliable")
func _ev_collapse(uid: int, rid: int, end: Transform3D) -> void:
	var p: Dictionary = structure.pieces.get(uid, {})
	var n: PieceNode = nodes.get(uid)
	if n and not p.is_empty():
		Sfx.play("dig_break", n.global_position, -4.0, 0.8)
		_add_rubble(rid, p.piece, p.family, n.global_transform, end, true)
	_ev_remove_piece(uid)


func _add_rubble(rid: int, piece: String, family: String, start: Transform3D, end: Transform3D, animate: bool) -> void:
	var rb := Rubble.new()
	add_child(rb)
	rb.setup(rid, piece, family, start, end, animate)
	rubble[rid] = rb
	_next_rubble = maxi(_next_rubble, rid + 1)


## Host: where a falling piece lands (the first solid thing under it, not itself).
func _landing_for(uid: int) -> Transform3D:
	var n: PieceNode = nodes[uid]
	var from := n.global_position + Vector3.UP * 0.5
	var floor_y := n.global_position.y
	if n.is_inside_tree():
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 60.0)
		q.collision_mask = World.TERRAIN_LAYER
		q.exclude = [n.get_rid()]
		var hit := n.get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			floor_y = hit.position.y
	return Rubble.landing(structure.pieces[uid].piece, n.global_transform, floor_y, randf_range(-0.25, 0.25), randf_range(-0.4, 0.4))


func ask_hit_rubble(rid: int) -> void:
	if auth.is_host():
		request_hit_rubble(auth.local_peer_id(), rid)
	else:
		_rpc_hit_rubble.rpc_id(1, rid)


@rpc("any_peer", "reliable")
func _rpc_hit_rubble(rid: int) -> void:
	if auth.is_host():
		request_hit_rubble(multiplayer.get_remote_sender_id(), rid)


## Host: a pickaxe hit on rubble. After Rubble.HITS hits it's cleared and gives back half its materials.
func request_hit_rubble(peer_id: int, rid: int) -> String:
	var ps := auth.get_player(peer_id)
	var rb: Rubble = rubble.get(rid)
	if ps == null or rb == null:
		return "?"
	if ps.node.global_position.distance_to(rb.global_position) > Pieces.BUILD_REACH + 2.0:
		return "too_far"
	rb.hits += 1
	if rb.hits < Rubble.HITS:
		_ev_rubble_hit.rpc(rid)
		return "hit"
	var cost := Pieces.cost(rb.piece, rb.family)
	for item in cost:
		var half: int = cost[item] / 2
		if half > 0:
			auth.spawn_drop(item, half, rb.global_position + Vector3.UP * 0.6)
	_ev_remove_rubble.rpc(rid)
	return "cleared"


@rpc("authority", "call_local", "reliable")
func _ev_rubble_hit(rid: int) -> void:
	var rb: Rubble = rubble.get(rid)
	if rb:
		Sfx.play("dig", rb.global_position, -4.0)


@rpc("authority", "call_local", "reliable")
func _ev_remove_rubble(rid: int) -> void:
	var rb: Rubble = rubble.get(rid)
	rubble.erase(rid)
	if rb:
		Sfx.play("dig_break", rb.global_position, -3.0)
		rb.queue_free()


# ================================================================== looks

func _rubble(b: AABB, counts: Dictionary) -> void:
	var total := 0
	for m in counts:
		total += counts[m]
	var n := clampi(ceili(total / 8.0), 1, 12)
	for i in n:
		var rb := RigidBody3D.new()
		rb.collision_layer = 0
		rb.collision_mask = World.TERRAIN_LAYER
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		var sz := clampf(pow(total / float(n), 1.0 / 3.0), 0.4, 1.6)
		sh.size = Vector3.ONE * sz
		cs.shape = sh
		rb.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sh.size
		mi.mesh = bm
		mi.material_override = Look.mat(Color(0.42, 0.39, 0.36), "stone")
		rb.add_child(mi)
		add_child(rb)
		rb.global_position = b.position + Vector3(randf() * b.size.x, randf() * b.size.y, randf() * b.size.z)
		rb.rotation = Vector3(randf(), randf(), randf()) * TAU
		get_tree().create_timer(4.0).timeout.connect(rb.queue_free)


static func _bounds(pts: PackedVector3Array) -> AABB:
	var b := AABB(pts[0], Vector3.ZERO)
	for p in pts:
		b = b.expand(p)
	return b.grow(0.5)


## Text for a Builder's Chest ("Building 3 of 12", "Paused: needs 6 Rootwood Plank"…).
func site_status(box_id: int) -> String:
	return sites.get(box_id, {}).get("status", "")


# ================================================================== blueprints & build sites

func ask_place_blueprint(json: String, origin: Vector3, rot: int, chest_pos: Vector3) -> void:
	if auth.is_host():
		request_place_blueprint(auth.local_peer_id(), json, origin, rot, chest_pos)
	else:
		_rpc_place_blueprint.rpc_id(1, json, origin, rot, chest_pos)


@rpc("any_peer", "reliable")
func _rpc_place_blueprint(json: String, origin: Vector3, rot: int, chest_pos: Vector3) -> void:
	if auth.is_host() and origin.is_finite() and chest_pos.is_finite():
		request_place_blueprint(multiplayer.get_remote_sender_id(), json, origin, rot, chest_pos)


## Host: checks the blueprint (it may come from anyone, so every rule is re-checked here)
## and starts a build site. Returns "" or why not.
func request_place_blueprint(peer_id: int, json: String, origin: Vector3, rot: int, chest_pos: Vector3) -> String:
	var ps := auth.get_player(peer_id)
	if ps == null or not origin.is_finite() or not chest_pos.is_finite():
		return "?"
	rot = posmod(rot, 4)
	var r := Blueprint.from_json(json)
	if not r.ok:
		return r.error
	if sites.size() >= MAX_SITES:
		return "Too many build sites (max %d)" % MAX_SITES
	if ps.node.global_position.distance_to(origin) > 24.0:
		return "Too far away"
	if chest_pos.distance_to(origin) > CHEST_RANGE:
		return "The chest must be within 16 m"
	if auth.world.sdf_at(chest_pos + Vector3.UP * 0.5) < 0.0:
		return "The chest can't go inside rock"
	var bp: Blueprint = r.blueprint
	for c in bp.carve_cells(origin, rot):
		if auth.world.sdf_at(c) < 0.0 and auth.world.material_at(c) in [Mat.BORDER, Mat.EDGE]:
			return "It would carve border rock"
	var box_id: int = auth.storage.create_box("builder", chest_pos, rot * PI / 2.0, peer_id)
	_ev_site.rpc(box_id, json, origin, rot, [])
	return ""


## Everyone: a build site appeared. Shows its ghost (blue see-through pieces).
@rpc("authority", "call_local", "reliable")
func _ev_site(box_id: int, json: String, origin: Vector3, rot: int, built: Array) -> void:
	var r := Blueprint.from_json(json)
	if not r.ok:
		return
	var bp: Blueprint = r.blueprint
	var chest: Dictionary = auth.storage.get_box(box_id)
	var chest_pos: Vector3 = chest.node.global_position if not chest.is_empty() else origin
	var plan := bp.world_pieces(origin, rot)
	plan.sort_custom(func(a, b):
		if absf(a.pos.y - b.pos.y) > 0.01:
			return a.pos.y < b.pos.y
		return a.pos.distance_to(chest_pos) < b.pos.distance_to(chest_pos))
	var ghost_root := Node3D.new()
	add_child(ghost_root)
	for i in plan.size():
		plan[i].built = built.has(i)
		var g: PieceNode = PIECE_SCRIPT.new()
		g.ghost = true
		g.piece = plan[i].piece
		g.family = plan[i].family
		ghost_root.add_child(g)
		g.global_position = plan[i].pos
		g.rotation.y = Pieces.yaw_of(plan[i].rot)
		g.set_ghost_plan.call_deferred()
		g.visible = not plan[i].built
		plan[i].ghost = g
	var carve := bp.carve_cells(origin, rot)
	carve.sort_custom(func(a, b): return a.distance_to(chest_pos) < b.distance_to(chest_pos))
	sites[box_id] = {json = json, origin = origin, rot = rot, plan = plan, carve = carve, ghosts = ghost_root,
		status = "Starting…", leftovers = {}}


@rpc("authority", "call_local", "reliable")
func _ev_site_piece(box_id: int, index: int) -> void:
	var site: Dictionary = sites.get(box_id, {})
	if site.is_empty():
		return
	site.plan[index].built = true
	site.plan[index].ghost.visible = false


@rpc("authority", "call_local", "reliable")
func _ev_site_status(box_id: int, text: String) -> void:
	if sites.has(box_id):
		sites[box_id].status = text


@rpc("authority", "call_local", "reliable")
func _ev_site_done(box_id: int) -> void:
	var site: Dictionary = sites.get(box_id, {})
	sites.erase(box_id)
	if not site.is_empty():
		site.ghosts.queue_free()


## Host: one step of every build site. Carving first (rock goes into the chest), then pieces.
func _tick_sites() -> void:
	for box_id in sites.keys():
		var site: Dictionary = sites[box_id]
		var chest: Dictionary = auth.storage.get_box(box_id)
		if chest.is_empty():
			_set_status(box_id, "Paused: the Builder's Chest is gone")
			continue
		if _carve_step(box_id, site, chest):
			continue
		if _site_ticks % 2 == 0:
			_build_step(box_id, site, chest)


## Carves one cell of rock. Returns true if it did (or is waiting to).
func _carve_step(box_id: int, site: Dictionary, chest: Dictionary) -> bool:
	while not site.carve.is_empty():
		var c: Vector3 = site.carve[0]
		if auth.world.sdf_at(c) > 0.0:
			site.carve.pop_front()  # already open
			continue
		for pid in auth.players:
			if auth.players[pid].node.global_position.distance_to(c) < 1.6:
				_set_status(box_id, "Waiting: someone is in the way")
				return true
		var counts: Dictionary = auth._host_dig(c, 0, CARVE_RADIUS)
		site.carve.pop_front()
		for mat in counts:
			var item: String = Mat.DROP_ITEM.get(mat, "")
			if item == "":
				continue
			var v: int = counts[mat] + site.leftovers.get(mat, 0)
			var per: int = Mat.VOXELS_PER_ITEM.get(mat, 3)
			site.leftovers[mat] = v % per
			if v / per > 0:
				var left: int = auth.storage.put(box_id, item, v / per)
				if left > 0:
					auth.spawn_drop(item, left, chest.node.global_position + Vector3.UP)
		_set_status(box_id, "Carving rock… %d cells left" % site.carve.size())
		site.carved_this_tick = site.get("carved_this_tick", 0) + 1
		if site.carved_this_tick < CARVES_PER_TICK:
			continue  # a few scoops per tick
		site.carved_this_tick = 0
		return true
	site.carved_this_tick = 0
	return false


func _build_step(box_id: int, site: Dictionary, chest: Dictionary) -> void:
	var inv: Inventory = chest.inv
	var first_missing := {}
	var done := 0
	for i in site.plan.size():
		var p: Dictionary = site.plan[i]
		if p.built:
			done += 1
			continue
		if _identical_exists(p):
			_ev_site_piece.rpc(box_id, i)
			return
		if structure.overlaps(p.piece, p.pos, p.rot) or Pieces.rock_problem(p.piece, p.pos, p.rot, auth.world.sdf_at) != "":
			continue  # blocked: something else is there
		var cost := Pieces.cost(p.piece, p.family)
		var missing := {}
		for item in cost:
			if inv.count_of(item) < cost[item]:
				missing[item] = cost[item] - inv.count_of(item)
		if not missing.is_empty():
			if first_missing.is_empty():
				first_missing = missing
			continue  # skip ahead to something we can afford
		var anchored := Pieces.touches_rock(p.piece, p.pos, p.rot, auth.world.sdf_at)
		if structure.preview_stability(p.piece, p.family, p.pos, p.rot, anchored) < Pieces.MIN_STABILITY:
			continue  # wait until what holds it up is built
		var blocked := false
		for pid in auth.players:
			if Pieces.box(p.piece, p.pos, p.rot).grow(0.1).has_point(auth.players[pid].node.global_position + Vector3.UP):
				blocked = true
		if blocked:
			_set_status(box_id, "Waiting: someone is in the way")
			return
		for item in cost:
			inv.remove(item, cost[item])
		auth.storage._changed(box_id)
		var uid := _next_uid
		_next_uid += 1
		_ev_add_piece.rpc(uid, p.piece, p.family, p.pos, p.rot, anchored)
		_ev_site_piece.rpc(box_id, i)
		_set_status(box_id, "Building… %d of %d" % [done + 1, site.plan.size()])
		return
	if done == site.plan.size():
		_set_status(box_id, "Done!")
		_ev_site_done.rpc(box_id)
	elif not first_missing.is_empty():
		var parts := []
		for item in first_missing:
			parts.append("%d %s" % [first_missing[item], Items.display_name(item)])
		_set_status(box_id, "Paused: needs " + ", ".join(parts))
	else:
		_set_status(box_id, "Waiting: something is in the way")


func _identical_exists(p: Dictionary) -> bool:
	for uid in structure.pieces:
		var q: Dictionary = structure.pieces[uid]
		if q.piece == p.piece and q.family == p.family and q.rot == p.rot and q.pos.distance_to(p.pos) < 0.05:
			return true
	return false


func _set_status(box_id: int, text: String) -> void:
	if sites.has(box_id) and sites[box_id].status != text:
		_ev_site_status.rpc(box_id, text)


# ================================================================== late joiners

func snapshot() -> Dictionary:
	var site_list := []
	for box_id in sites:
		var st: Dictionary = sites[box_id]
		var built := []
		for i in st.plan.size():
			if st.plan[i].built:
				built.append(i)
		site_list.append([box_id, st.json, st.origin, st.rot, built])
	var rubble_list := []
	for rid in rubble:
		var rb: Rubble = rubble[rid]
		rubble_list.append([rid, rb.piece, rb.family, rb.global_transform, rb.hits])
	return {pieces = structure.to_data(), falls = fall_log.duplicate(), next = _next_uid, sites = site_list, rubble = rubble_list}


func load_snapshot(s: Dictionary) -> void:
	for f in s.get("falls", []):
		fall_log.append(f)
		_pending_falls.append(f)
	for p in s.get("pieces", []):
		_ev_add_piece(p[0], p[1], p[2], p[3], p[4], p[5])
		if p.size() > 6 and p[6]:
			_ev_door(p[0], true)
	_next_uid = s.get("next", _next_uid)
	for st in s.get("sites", []):
		_ev_site(st[0], st[1], st[2], st[3], st[4])
	for r in s.get("rubble", []):
		_add_rubble(r[0], r[1], r[2], r[3], r[3], false)
		rubble[r[0]].hits = r[4]
