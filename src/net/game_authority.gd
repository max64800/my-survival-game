class_name GameAuthority
extends Node
## The referee. Every action that changes the shared world goes through here:
##
##   1. A player ASKS for something       (ask_*: called by the player's own computer)
##   2. The host APPROVES or says no      (request_*: only runs on the host)
##   3. EVERYONE UPDATES the same way     (_ev_*: "events" the host sends to every player)
##
## Playing alone, your computer is the host, so all three steps happen right here.
## In co-op, ask_* travels to the host over the network, and the host sends the
## events back to everyone, so all friends see the same cave.

signal dig_feedback(peer_id: int, result: Dictionary)
signal fuel_changed(peer_id: int, fuel: float)

const REACH := 4.5  ## meters from the dwarf's chest to what they're hitting
const DIG_RADIUS := 1.35  ## size of the scoop one finished dig removes
const PICKUP_RANGE := 6.0
const MAX_FUEL := 600.0  ## 10 minutes of full lantern light
const FUEL_SYNC_TIME := 2.0
const DROP_SCENE := preload("res://src/items/drop.gd")

static var instance: GameAuthority

var world: World
var glow: GlowField
var drops_root: Node3D
var players: Dictionary = {}  ## peer_id -> PlayerState
var edit_log: Array[Vector4] = []  ## every dig: center (xyz) + pickaxe tier (w), so late joiners can catch up
var removed_glow: Array[int] = []
var _drops: Dictionary = {}  ## drop_id -> Drop
var _next_drop_id := 1
var _pending_digs: Array[Vector4] = []  ## digs waiting for that part of the cave to load
var _fuel_sync := 0.0


class PlayerState:
	var node: Node3D
	var inventory := Inventory.new()
	var selected_slot := 0
	var fuel := GameAuthority.MAX_FUEL
	var dig_target := Vector3.INF
	var dig_hits := 0
	var leftovers := {}  ## material -> voxels dug that didn't add up to a whole item yet

	func selected_item() -> String:
		return inventory.get_slot(selected_slot).get("id", "")


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func is_host() -> bool:
	return multiplayer.is_server()


func local_peer_id() -> int:
	return multiplayer.get_unique_id()


## Registers a player. `give_start_items` is false on a client's copy of itself
## (the host owns everyone's bag and sends it over).
func add_player(peer_id: int, node: Node3D, give_start_items: bool = true) -> PlayerState:
	var ps := PlayerState.new()
	ps.node = node
	if give_start_items:
		ps.inventory.add("pickaxe_stone", 1)
	players[peer_id] = ps
	if is_host() and peer_id != local_peer_id():
		ps.inventory.changed.connect(func(): _send_inventory(peer_id))
		_send_inventory(peer_id)
	return ps


func remove_player(peer_id: int) -> void:
	players.erase(peer_id)


func get_player(peer_id: int) -> PlayerState:
	return players.get(peer_id)


func _process(delta: float) -> void:
	for id in players:
		var ps: PlayerState = players[id]
		if ps.fuel > 0.0:
			ps.fuel = maxf(0.0, ps.fuel - delta)
	_apply_pending_digs()
	if is_host() and multiplayer.has_multiplayer_peer():
		_fuel_sync -= delta
		if _fuel_sync <= 0.0:
			_fuel_sync = FUEL_SYNC_TIME
			for id in players:
				if id != local_peer_id() and multiplayer.get_peers().has(id):
					_rpc_fuel.rpc_id(id, players[id].fuel)


# ================================================================== 1. ASK
# Called by the local player's own code (dwarf, bag screen, drops).

func ask_select_slot(slot: int) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.selected_slot = slot  # show it right away
	if is_host():
		request_select_slot(local_peer_id(), slot)
	else:
		_rpc_select_slot.rpc_id(1, slot)


func ask_hit(point: Vector3, normal: Vector3) -> void:
	if is_host():
		request_hit(local_peer_id(), point, normal)
	else:
		_rpc_hit.rpc_id(1, point, normal)


func ask_break_glow(glow_id: int) -> void:
	if is_host():
		request_break_glow(local_peer_id(), glow_id)
	else:
		_rpc_break_glow.rpc_id(1, glow_id)


func ask_pickup(drop_id: int) -> void:
	if is_host():
		request_pickup(local_peer_id(), drop_id)
	else:
		_rpc_pickup.rpc_id(1, drop_id)


func ask_refill() -> void:
	if is_host():
		request_refill(local_peer_id())
	else:
		_rpc_refill.rpc_id(1)


func ask_swap(a: int, b: int) -> void:
	if is_host():
		request_swap(local_peer_id(), a, b)
	else:
		_rpc_swap.rpc_id(1, a, b)


# The network doors into the host. Only the host acts on them.
@rpc("any_peer", "reliable")
func _rpc_select_slot(slot: int) -> void:
	if is_host():
		request_select_slot(multiplayer.get_remote_sender_id(), slot)


@rpc("any_peer", "reliable")
func _rpc_hit(point: Vector3, normal: Vector3) -> void:
	if is_host():
		request_hit(multiplayer.get_remote_sender_id(), point, normal)


@rpc("any_peer", "reliable")
func _rpc_break_glow(glow_id: int) -> void:
	if is_host():
		request_break_glow(multiplayer.get_remote_sender_id(), glow_id)


@rpc("any_peer", "reliable")
func _rpc_pickup(drop_id: int) -> void:
	if is_host():
		request_pickup(multiplayer.get_remote_sender_id(), drop_id)


@rpc("any_peer", "reliable")
func _rpc_refill() -> void:
	if is_host():
		request_refill(multiplayer.get_remote_sender_id())


@rpc("any_peer", "reliable")
func _rpc_swap(a: int, b: int) -> void:
	if is_host():
		request_swap(multiplayer.get_remote_sender_id(), a, b)


# ================================================================== 2. APPROVE (host only)

func request_select_slot(peer_id: int, slot: int) -> void:
	var ps := get_player(peer_id)
	if ps and slot >= 0 and slot < Inventory.HOTBAR_SIZE:
		ps.selected_slot = slot


## Moving items around in your own bag.
func request_swap(peer_id: int, a: int, b: int) -> void:
	var ps := get_player(peer_id)
	if ps:
		ps.inventory.swap(a, b)


## A pickaxe swing landed on rock at `point` (surface) facing `normal`.
## Result: {state = "hit"|"dug"|"blocked"|"no_tool"|"too_far"|"air", hits, needed, material}
func request_hit(peer_id: int, point: Vector3, normal: Vector3) -> Dictionary:
	var ps := get_player(peer_id)
	if ps == null:
		return {}
	var result := _judge_hit(ps, point, normal)
	_tell_feedback(peer_id, result)
	return result


func _judge_hit(ps: PlayerState, point: Vector3, normal: Vector3) -> Dictionary:
	var power := Items.dig_power(ps.selected_item())
	if power <= 0:
		return {state = "no_tool"}
	if _chest(ps).distance_to(point) > REACH + 1.0:
		return {state = "too_far"}
	var center := point - normal * 0.55
	var mat := world.rock_material_near(point - normal * 0.3, 1.1)
	if mat < 0:
		return {state = "air"}
	var tool_tier := Items.tier(ps.selected_item())
	var needed := Mat.hits_needed(mat, power, tool_tier)
	if needed == 0:
		return {state = "blocked", material = mat, point = point}
	if ps.dig_target.distance_to(center) > 1.0:
		ps.dig_target = center
		ps.dig_hits = 0
	ps.dig_hits += 1
	if ps.dig_hits < needed:
		return {state = "hit", hits = ps.dig_hits, needed = needed, material = mat, point = point}
	ps.dig_hits = 0
	ps.dig_target = Vector3.INF
	var counts := _host_dig(center, tool_tier)
	_give_dig_drops(ps, counts, center + normal * 0.8)
	return {state = "dug", hits = needed, needed = needed, material = mat, point = point}


## Breaking a glow crystal or mushroom.
func request_break_glow(peer_id: int, glow_id: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null or glow == null or Items.dig_power(ps.selected_item()) <= 0:
		return false
	var spot := glow.get_spot(glow_id)
	if spot.is_empty() or _chest(ps).distance_to(spot.pos) > REACH + 1.0:
		return false
	_host_remove_glow(spot)
	return true


func request_pickup(peer_id: int, drop_id: int) -> bool:
	var ps := get_player(peer_id)
	var d: Drop = _drops.get(drop_id)
	if ps == null or d == null or _chest(ps).distance_to(d.global_position) > PICKUP_RANGE:
		return false
	var left := ps.inventory.add(d.item_id, d.count)
	if left == d.count:
		return false
	if left == 0:
		_ev_remove_drop.rpc(drop_id)
	else:
		_ev_drop_count.rpc(drop_id, left)
	return true


## Put one fuel item (a glow crystal) into the lantern.
func request_refill(peer_id: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null or ps.fuel > MAX_FUEL - 30.0:
		return false
	for id in ["crystal_blue"]:
		if ps.inventory.remove(id, 1):
			ps.fuel = minf(MAX_FUEL, ps.fuel + Items.fuel_seconds(id))
			fuel_changed.emit(peer_id, ps.fuel)
			if peer_id != local_peer_id():
				_rpc_fuel.rpc_id(peer_id, ps.fuel)
			return true
	return false


# Host-side helpers that decide things, then tell everyone.

func _host_dig(center: Vector3, tool_tier: int = 0) -> Dictionary:
	if glow:
		for spot in glow.spots_near(center, DIG_RADIUS + 0.9):
			_host_remove_glow(spot)
	var counts := world.apply_dig(center, DIG_RADIUS, tool_tier)
	var edit := Vector4(center.x, center.y, center.z, tool_tier)
	edit_log.append(edit)
	_ev_dig.rpc(edit)  # the others apply it; we already did
	return counts


func _host_remove_glow(spot: Dictionary) -> void:
	removed_glow.append(spot.id)
	_ev_remove_glow.rpc(spot.id)
	var item := "crystal_blue" if spot.kind == GlowPlacer.CRYSTAL else "glowcap"
	spawn_drop(item, 2 if item == "crystal_blue" else 1, spot.pos + spot.normal * 0.5)


func spawn_drop(item_id: String, count: int, pos: Vector3) -> void:
	var id := _next_drop_id
	_next_drop_id += 1
	var vel := Vector3(randf_range(-1.5, 1.5), randf_range(1.5, 3.0), randf_range(-1.5, 1.5))
	_ev_spawn_drop.rpc(id, item_id, count, pos, vel)


func _tell_feedback(peer_id: int, result: Dictionary) -> void:
	if peer_id == local_peer_id():
		dig_feedback.emit(peer_id, result)
	else:
		_rpc_feedback.rpc_id(peer_id, result)


func _send_inventory(peer_id: int) -> void:
	var ps := get_player(peer_id)
	if ps and multiplayer.get_peers().has(peer_id):
		_rpc_inventory.rpc_id(peer_id, ps.inventory.to_data(), ps.selected_slot)


# ================================================================== 3. EVERYONE UPDATES

## Dig event for the other players (the host already dug when it decided).
@rpc("authority", "reliable")
func _ev_dig(edit: Vector4) -> void:
	edit_log.append(edit)
	_pending_digs.append(edit)
	_apply_pending_digs()


func _apply_pending_digs() -> void:
	if _pending_digs.is_empty() or world == null:
		return
	var still: Array[Vector4] = []
	for e in _pending_digs:
		var c := Vector3(e.x, e.y, e.z)
		if world.is_ready_at(c, DIG_RADIUS + 1.0):
			world.apply_dig(c, DIG_RADIUS, int(e.w))  # carving is order-independent, so late is fine
		else:
			still.append(e)
	_pending_digs = still


@rpc("authority", "call_local", "reliable")
func _ev_remove_glow(glow_id: int) -> void:
	if glow:
		glow.remove_spot(glow_id)


@rpc("authority", "call_local", "reliable")
func _ev_spawn_drop(drop_id: int, item_id: String, count: int, pos: Vector3, vel: Vector3) -> void:
	var d: Drop = DROP_SCENE.new()
	d.drop_id = drop_id
	d.item_id = item_id
	d.count = count
	drops_root.add_child(d)
	d.global_position = pos
	d.linear_velocity = vel
	_drops[drop_id] = d
	_next_drop_id = maxi(_next_drop_id, drop_id + 1)


@rpc("authority", "call_local", "reliable")
func _ev_remove_drop(drop_id: int) -> void:
	var d: Drop = _drops.get(drop_id)
	_drops.erase(drop_id)
	if d:
		d.queue_free()


@rpc("authority", "call_local", "reliable")
func _ev_drop_count(drop_id: int, count: int) -> void:
	var d: Drop = _drops.get(drop_id)
	if d:
		d.count = count
		d.pickup_refused()


# Private messages from the host to one player.
@rpc("authority", "reliable")
func _rpc_feedback(result: Dictionary) -> void:
	dig_feedback.emit(local_peer_id(), result)


@rpc("authority", "reliable")
func _rpc_inventory(data: Array, selected: int) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.inventory.load_data(data)
		me.selected_slot = selected


@rpc("authority", "reliable")
func _rpc_fuel(fuel: float) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.fuel = fuel
		fuel_changed.emit(local_peer_id(), fuel)


# ================================================================== catching up a late joiner

## Everything a player joining mid-game needs, as plain data.
func snapshot() -> Dictionary:
	var drops := []
	for id in _drops:
		var d: Drop = _drops[id]
		drops.append([id, d.item_id, d.count, d.global_position])
	return {edits = edit_log.duplicate(), glow = removed_glow.duplicate(), drops = drops, next_drop = _next_drop_id}


func load_snapshot(snap: Dictionary) -> void:
	for id in snap.glow:
		removed_glow.append(id)
		if glow:
			glow.remove_spot(id)
	for c in snap.edits:
		edit_log.append(c)
		_pending_digs.append(c)
	for d in snap.drops:
		_ev_spawn_drop(d[0], d[1], d[2], d[3], Vector3.ZERO)
	_next_drop_id = snap.next_drop


# ================================================================== helpers

func _give_dig_drops(ps: PlayerState, counts: Dictionary, pos: Vector3) -> void:
	for mat in counts:
		var item: String = Mat.DROP_ITEM.get(mat, "")
		if item == "":
			continue
		var voxels: int = counts[mat] + ps.leftovers.get(mat, 0)
		var per: int = Mat.VOXELS_PER_ITEM.get(mat, 3)
		var n := voxels / per
		ps.leftovers[mat] = voxels % per
		if mat == Mat.COPPER:
			n = maxi(n, 1)  # always feel rewarded for hitting ore
		if n > 0:
			spawn_drop(item, n, pos)


func drop_count() -> int:
	return _drops.size()


func pending_dig_count() -> int:
	return _pending_digs.size()


func _chest(ps: PlayerState) -> Vector3:
	return ps.node.global_position + Vector3.UP * 1.0
