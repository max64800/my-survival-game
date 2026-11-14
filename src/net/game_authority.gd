class_name GameAuthority
extends Node
## The referee. Every action that changes the shared world goes through here:
##
##   1. A player REQUESTS something      (request_* functions)
##   2. The authority APPROVES or says no (checks reach, tools, rules)
##   3. EVERYONE UPDATES the same way     (_do_* functions)
##
## Today there's one player and everything runs on this computer.
## In Step 2 (co-op), request_* run on the host (sent there as RPCs) and _do_* are
## broadcast to every player, so friends always see the same cave.

signal dig_feedback(peer_id: int, result: Dictionary)
signal fuel_changed(peer_id: int, fuel: float)

const REACH := 4.5  ## meters from the dwarf's chest to what they're hitting
const DIG_RADIUS := 1.35  ## size of the scoop one finished dig removes
const PICKUP_RANGE := 6.0
const MAX_FUEL := 600.0  ## 10 minutes of full lantern light
const DROP_SCENE := preload("res://src/items/drop.gd")

static var instance: GameAuthority

var world: World
var glow: GlowField
var drops_root: Node3D
var players: Dictionary = {}  ## peer_id -> PlayerState
var _drops: Dictionary = {}  ## drop_id -> Drop
var _next_drop_id := 1


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


func local_peer_id() -> int:
	return multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1


func add_player(peer_id: int, node: Node3D) -> PlayerState:
	var ps := PlayerState.new()
	ps.node = node
	ps.inventory.add("stone_pickaxe", 1)
	players[peer_id] = ps
	return ps


func get_player(peer_id: int) -> PlayerState:
	return players.get(peer_id)


func _process(delta: float) -> void:
	for id in players:
		var ps: PlayerState = players[id]
		if ps.fuel > 0.0:
			ps.fuel = maxf(0.0, ps.fuel - delta)


# ------------------------------------------------------------------ requests

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
	dig_feedback.emit(peer_id, result)
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
	var needed := Mat.hits_needed(mat, power)
	if needed == 0:
		return {state = "blocked", material = mat}
	if ps.dig_target.distance_to(center) > 1.0:
		ps.dig_target = center
		ps.dig_hits = 0
	ps.dig_hits += 1
	if ps.dig_hits < needed:
		return {state = "hit", hits = ps.dig_hits, needed = needed, material = mat}
	ps.dig_hits = 0
	ps.dig_target = Vector3.INF
	var counts := _do_dig(center)
	_give_dig_drops(ps, counts, center + normal * 0.8)
	return {state = "dug", hits = needed, needed = needed, material = mat}


## Breaking a glow crystal or mushroom.
func request_break_glow(peer_id: int, glow_id: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null or glow == null or Items.dig_power(ps.selected_item()) <= 0:
		return false
	var spot := glow.get_spot(glow_id)
	if spot.is_empty() or _chest(ps).distance_to(spot.pos) > REACH + 1.0:
		return false
	_do_remove_glow(glow_id)
	_spawn_glow_drop(spot)
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
		_do_remove_drop(drop_id)
	else:
		d.count = left
	return true


## Put one fuel item (a glow crystal) into the lantern.
func request_refill(peer_id: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null or ps.fuel > MAX_FUEL - 30.0:
		return false
	for id in ["glow_crystal"]:
		if ps.inventory.remove(id, 1):
			ps.fuel = minf(MAX_FUEL, ps.fuel + Items.fuel_seconds(id))
			fuel_changed.emit(peer_id, ps.fuel)
			Sfx.ui("refill")
			return true
	return false


# ------------------------------------------------------------------ everyone updates

## Removes a scoop of rock (and any crystals stuck to it).
func _do_dig(center: Vector3) -> Dictionary:
	var counts := world.apply_dig(center, DIG_RADIUS)
	Sfx.play("dig_break", center, -6.0)
	if glow:
		for spot in glow.spots_near(center, DIG_RADIUS + 0.9):
			_do_remove_glow(spot.id)
			_spawn_glow_drop(spot)
	return counts


func _do_remove_glow(glow_id: int) -> void:
	if glow:
		glow.remove_spot(glow_id)


func _do_spawn_drop(drop_id: int, item_id: String, count: int, pos: Vector3) -> Drop:
	var d: Drop = DROP_SCENE.new()
	d.drop_id = drop_id
	d.item_id = item_id
	d.count = count
	drops_root.add_child(d)
	d.global_position = pos
	d.linear_velocity = Vector3(randf_range(-1.5, 1.5), randf_range(1.5, 3.0), randf_range(-1.5, 1.5))
	_drops[drop_id] = d
	return d


func _do_remove_drop(drop_id: int) -> void:
	var d: Drop = _drops.get(drop_id)
	_drops.erase(drop_id)
	if d:
		d.queue_free()


# ------------------------------------------------------------------ helpers

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


func _spawn_glow_drop(spot: Dictionary) -> void:
	var item := "glow_crystal" if spot.kind == GlowPlacer.CRYSTAL else "glowcap"
	spawn_drop(item, 2 if item == "glow_crystal" else 1, spot.pos + spot.normal * 0.5)


func spawn_drop(item_id: String, count: int, pos: Vector3) -> void:
	var id := _next_drop_id
	_next_drop_id += 1
	_do_spawn_drop(id, item_id, count, pos)


func drop_count() -> int:
	return _drops.size()


func _chest(ps: PlayerState) -> Vector3:
	return ps.node.global_position + Vector3.UP * 1.0
