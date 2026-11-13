class_name Builder
extends Node
## Builder: everything that's been built, and every cave-in. A helper of the GameAuthority,
## using the same pattern: ask_* (your computer) → request_* (host approves) → _ev_* (everyone).
## Lives at Authority/Builder on every computer.

const PIECE_SCRIPT := preload("res://src/build/piece_node.gd")
const CHECK_DELAY := 0.05  ## cave-in checks run a moment after a dig
const WARN_TIME := 1.0  ## dust and rumble before rock falls
const BREAK_DELAY := 0.5  ## shaky pieces wait a moment, then fall apart one by one
const RUBBLE_DAMAGE := 15.0

var auth: GameAuthority
var structure := Structure.new()
var nodes := {}  ## uid -> PieceNode
var pieces_root: Node3D
var fall_log: Array[PackedVector3Array] = []  ## every cave-in, for friends who join later
var _next_uid := 1
var _clock := 0.0
var _checks := []  ## host: [time, center, radius]
var _falls := []  ## host: [time, points]
var _breaks := []  ## host: [time, uid]
var _pending_falls: Array[PackedVector3Array] = []  ## falls waiting for that area to load here


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


func ask_remove(uid: int) -> void:
	if auth.is_host():
		request_remove(auth.local_peer_id(), uid)
	else:
		_rpc_remove.rpc_id(1, uid)


@rpc("any_peer", "reliable")
func _rpc_place(piece: String, family: String, pos: Vector3, rot: int) -> void:
	if auth.is_host():
		request_place(multiplayer.get_remote_sender_id(), piece, family, pos, rot)


@rpc("any_peer", "reliable")
func _rpc_remove(uid: int) -> void:
	if auth.is_host():
		request_remove(multiplayer.get_remote_sender_id(), uid)


# ================================================================== approve (host)

## Why this piece can't go here, or "" if it can. Used by the host to approve, and by
## the ghost to turn red (same rules on both sides).
func problem(ps: GameAuthority.PlayerState, piece: String, family: String, pos: Vector3, rot: int) -> String:
	if not Pieces.allowed(piece, family):
		return "Can't be made from %s" % Pieces.FAMILIES.get(family, {}).get("name", family)
	if ps.node.global_position.distance_to(pos) > Pieces.BUILD_REACH + 1.0:
		return "Too far away"
	if not _workbench_near(pos):
		return "Needs a Workbench within 20 m"
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
	if ps == null or not Pieces.LIST.has(piece):
		return "?"
	var why := problem(ps, piece, family, pos, rot)
	if why != "":
		return why
	var cost := Pieces.cost(piece, family)
	for item in cost:
		ps.inventory.remove(item, cost[item])
	var uid := _next_uid
	_next_uid += 1
	_ev_add_piece.rpc(uid, piece, family, pos, rot, Pieces.touches_rock(piece, pos, rot, auth.world.sdf_at))
	auth.give_xp(peer_id, 2, "smithing")
	return ""


## Taking your own piece down gives back everything it cost.
func request_remove(peer_id: int, uid: int) -> bool:
	var ps := auth.get_player(peer_id)
	if ps == null or not structure.pieces.has(uid):
		return false
	var p: Dictionary = structure.pieces[uid]
	if ps.node.global_position.distance_to(p.pos) > Pieces.BUILD_REACH + 1.0:
		return false
	var cost := Pieces.cost(p.piece, p.family)
	for item in cost:
		var left := ps.inventory.add(item, cost[item])
		if left > 0:
			auth.spawn_drop(item, left, p.pos + Vector3.UP)
	_ev_remove_piece.rpc(uid)
	return true


func _workbench_near(pos: Vector3) -> bool:
	for st in auth.stations.values():
		if st.kind == "workbench" and st.global_position.distance_to(pos) <= Pieces.WORKBENCH_RANGE:
			return true
	return false


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_add_piece(uid: int, piece: String, family: String, pos: Vector3, rot: int, anchored: bool) -> void:
	structure.add(uid, piece, family, pos, rot, anchored)
	var n: PieceNode = PIECE_SCRIPT.new()
	n.uid = uid
	n.piece = piece
	n.family = family
	pieces_root.add_child(n)
	n.global_position = pos
	n.rotation.y = rot * PI / 2.0
	nodes[uid] = n
	_next_uid = maxi(_next_uid, uid + 1)
	if auth.is_host():
		_queue_shaky()


@rpc("authority", "call_local", "reliable")
func _ev_remove_piece(uid: int) -> void:
	var p: Dictionary = structure.pieces.get(uid, {})
	structure.remove(uid)
	var n: Node = nodes.get(uid)
	nodes.erase(uid)
	if n:
		n.queue_free()
	if auth.is_host() and not p.is_empty():
		_queue_shaky()
		if Pieces.LIST[p.piece].get("supports_rock", false):
			queue_check(Pieces.box(p.piece, p.pos, p.rot).end, 1.5)  # was holding rock up!


@rpc("authority", "call_local", "reliable")
func _ev_warn(center: Vector3) -> void:
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
	while not _checks.is_empty() and _checks[0][0] <= _clock:
		var c: Array = _checks.pop_front()
		_run_check(c[1], c[2], c[3] if c.size() > 3 else 0)
	while not _falls.is_empty() and _falls[0][0] <= _clock:
		_ev_cave_in.rpc(_falls.pop_front()[1])
	while not _breaks.is_empty() and _breaks[0][0] <= _clock:
		var uid: int = _breaks.pop_front()[1]
		if structure.pieces.has(uid):
			var p: Dictionary = structure.pieces[uid]
			for item in Pieces.cost(p.piece, p.family):
				var half: int = Pieces.cost(p.piece, p.family)[item] / 2
				if half > 0:
					auth.spawn_drop(item, half, p.pos + Vector3.UP * 0.5)
			_ev_remove_piece.rpc(uid)


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
			_breaks.append([_clock + BREAK_DELAY + 0.1 * _breaks.size(), uid])


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
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.39, 0.36)
		mi.material_override = mat
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
func site_status(_box_id: int) -> String:
	return ""


# ================================================================== late joiners

func snapshot() -> Dictionary:
	return {pieces = structure.to_data(), falls = fall_log.duplicate(), next = _next_uid}


func load_snapshot(s: Dictionary) -> void:
	for f in s.get("falls", []):
		fall_log.append(f)
		_pending_falls.append(f)
	for p in s.get("pieces", []):
		_ev_add_piece(p[0], p[1], p[2], p[3], p[4], p[5])
	_next_uid = s.get("next", _next_uid)
