class_name GameAuthority
extends Node

signal hud_message(text: String)  ## a line for our own screen
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
const STATION_SCRIPT := preload("res://src/world/station.gd")
const STATION_REACH := 4.0
const PROGRESS_SYNC_TIME := 0.5
## Fuel the R key uses, best first.
const FUEL_ORDER := ["crystal_white", "crystal_amber", "crystal_violet", "crystal_blue", "crystal_green", "crystal_red", "rootwood", "mushroom_wood", "glow_slime"]

static var instance: GameAuthority

var world: World
var glow: GlowField
var drops_root: Node3D
var players: Dictionary = {}  ## peer_id -> PlayerState
var edit_log: Array[Vector4] = []  ## every dig: center (xyz) + packed tier & size (w, see pack_dig), for late joiners
var removed_glow: Array[int] = []
var _drops: Dictionary = {}  ## drop_id -> Drop
var _next_drop_id := 1
var _pending_digs: Array[Vector4] = []  ## digs waiting for that part of the cave to load
var _fuel_sync := 0.0
var stations: Dictionary = {}  ## station id -> Station node
var stations_root: Node3D
var rune_slab := RuneSlab.new()  ## one per world, shared by everyone
var builder: Builder
var storage: Storage
var monsters: MonsterManager
var poi_field: PoiField
var raids: Raids
## What the whole world remembers (shared by every player): clues found, shrines emptied,
## bosses beaten, side-boss caverns discovered.
var world_state := {clues = [], shrines = [], bosses_dead = [], lairs_found = []}
var _next_station_id := 1
var _progress_dirty := {}  ## peer ids whose XP changed and need a sync
var _progress_sync := 0.0


class PlayerState:
	var node: Node3D
	var inventory := Inventory.new()
	var selected_slot := 0
	var fuel := GameAuthority.MAX_FUEL
	var needs_lantern := false  ## true = started with nothing: no light until a Lantern is made
	var dig_target := Vector3.INF
	var dig_hits := 0
	var harvest_id := -1
	var harvest_hits := 0
	var leftovers := {}  ## material -> voxels dug that didn't add up to a whole item yet
	var vitals := Vitals.new()  ## simulated on the player's own computer
	var progress := Progression.new()  ## owned by the host, copied to the player
	var seen := {}  ## every item id this player has held (unlocks recipes)
	var bed_pos := Vector3.INF  ## where you wake up after dying (INF = the world start)
	var dying := false
	## Host: timed fight boosts it can see (food damage buffs, whetstone, bug oil, war horn).
	## name -> {damage, bugs, until (host seconds)}
	var boosts := {}
	var train_hits := 0
	var train_at := 0.0

	func _init() -> void:
		inventory.changed.connect(_note_seen)

	func _note_seen() -> void:
		for slot in inventory.slots:
			if not slot.is_empty():
				seen[slot.id] = true

	func selected_item() -> String:
		return inventory.get_slot(selected_slot).get("id", "")


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	builder = Builder.new()
	builder.name = "Builder"
	add_child(builder)
	storage = Storage.new()
	storage.name = "Storage"
	add_child(storage)
	monsters = MonsterManager.new()
	monsters.name = "Monsters"
	add_child(monsters)
	raids = Raids.new()
	raids.name = "Raids"
	add_child(raids)


func _exit_tree() -> void:
	if instance == self:
		instance = null


func is_host() -> bool:
	return multiplayer.is_server()


func local_peer_id() -> int:
	return multiplayer.get_unique_id()


## Registers a player. `give_start_items` is false on a client's copy of itself
## (the host owns everyone's bag and sends it over).
## A real new game: the host wakes up with an empty bag and makes their first tools
## from what's lying in the starting room (feedback F11). Off for tests and robots.
var start_with_nothing := false


func add_player(peer_id: int, node: Node3D, give_start_items: bool = true) -> PlayerState:
	var ps := PlayerState.new()
	ps.node = node
	if start_with_nothing and peer_id == local_peer_id():
		ps.needs_lantern = true  # wakes up with nothing: makes a lantern from what's in the room
	elif give_start_items:
		# Friends who join later (and test robots) arrive ready to dig, with a lantern built in.
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
		if ps.fuel > 0.0 and Lantern.has_lantern(ps):  # no lantern yet = nothing burning
			ps.fuel = maxf(0.0, ps.fuel - delta)
	var me := get_player(local_peer_id())
	if me:
		_tick_vitals(me, delta)
	_apply_pending_digs()
	if is_host():
		for st in stations.values():
			for done in st.tick(delta):
				spawn_drop(done[0], done[1], st.global_position + Vector3.UP * 1.2)
			if st.tick_water(delta):
				_ev_water.rpc(st.station_id, st.water, st.under_drip)
		_progress_sync -= delta
		if _progress_sync <= 0.0 and not _progress_dirty.is_empty():
			_progress_sync = PROGRESS_SYNC_TIME
			for pid in _progress_dirty:
				if pid != local_peer_id() and multiplayer.get_peers().has(pid) and players.has(pid):
					_rpc_progress.rpc_id(pid, players[pid].progress.to_data())
			_progress_dirty.clear()
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


func ask_harvest(glow_id: int) -> void:
	if is_host():
		request_harvest(local_peer_id(), glow_id)
	else:
		_rpc_harvest.rpc_id(1, glow_id)


## Right click with the selected hotbar item: eat, drink, or place a station.
func ask_use(aim_point: Vector3, aim_normal: Vector3, yaw: float) -> void:
	if is_host():
		request_use(local_peer_id(), aim_point, aim_normal, yaw)
	else:
		_rpc_use.rpc_id(1, aim_point, aim_normal, yaw)


func ask_buy_perk(perk_id: String) -> void:
	if is_host():
		request_buy_perk(local_peer_id(), perk_id)
	else:
		_rpc_buy_perk.rpc_id(1, perk_id)


## E at a special place (wall marking, rune shrine).
func ask_poi(poi_id: int) -> void:
	if is_host():
		request_poi(local_peer_id(), poi_id)
	else:
		_rpc_poi.rpc_id(1, poi_id)


## Gem Bench (combat doc 4.4): put a gem from the bag into the item in bag slot `slot`.
func ask_socket(slot: int, gem: String) -> void:
	if is_host():
		request_socket(local_peer_id(), slot, gem)
	else:
		_rpc_socket.rpc_id(1, slot, gem)


func ask_unsocket(slot: int, index: int) -> void:
	if is_host():
		request_unsocket(local_peer_id(), slot, index)
	else:
		_rpc_unsocket.rpc_id(1, slot, index)


@rpc("any_peer", "reliable")
func _rpc_socket(slot: int, gem: String) -> void:
	if is_host():
		request_socket(multiplayer.get_remote_sender_id(), slot, gem)


@rpc("any_peer", "reliable")
func _rpc_unsocket(slot: int, index: int) -> void:
	if is_host():
		request_unsocket(multiplayer.get_remote_sender_id(), slot, index)


func _near_kind(ps: PlayerState, kind: String) -> bool:
	for st in stations.values():
		if st.kind == kind and st.global_position.distance_to(ps.node.global_position) < STATION_REACH + 1.0:
			return true
	return false


## Socketing is free. Returns "" or why not.
func request_socket(peer_id: int, slot: int, gem: String) -> String:
	var ps := get_player(peer_id)
	if ps == null:
		return "?"
	if not _near_kind(ps, "gem_bench"):
		return "Stand at a Gem Bench"
	var s := ps.inventory.get_slot(slot)
	if not Gems.can_socket(s, gem):
		return "No free socket for that gem"
	if not ps.inventory.remove(Gems.item_id(gem), 1):
		return "You don't have that gem"
	s = ps.inventory.get_slot(slot)  # (removing never moves other slots)
	var list: Array = s.get("gems", []).duplicate()
	list.append(gem)
	s.gems = list
	ps.inventory.changed.emit()
	return ""


## Taking a gem out gives it back intact, for 5 blue glow crystals.
func request_unsocket(peer_id: int, slot: int, index: int) -> String:
	var ps := get_player(peer_id)
	if ps == null:
		return "?"
	if not _near_kind(ps, "gem_bench"):
		return "Stand at a Gem Bench"
	var s := ps.inventory.get_slot(slot)
	var list: Array = s.get("gems", [])
	if index < 0 or index >= list.size():
		return "?"
	for item in Gems.REMOVE_COST:
		if ps.inventory.count_of(item) < Gems.REMOVE_COST[item]:
			return "Needs 5 blue glow crystals"
	for item in Gems.REMOVE_COST:
		ps.inventory.remove(item, Gems.REMOVE_COST[item])
	var gem: String = list[index]
	list = list.duplicate()
	list.remove_at(index)
	s.gems = list
	if ps.inventory.add(Gems.item_id(gem), 1) > 0:
		spawn_drop(Gems.item_id(gem), 1, ps.node.global_position + Vector3.UP)
	ps.inventory.changed.emit()
	return ""


## Recipes taught by carved runes and by old recipe pages (shared by everyone).
func taught_recipes() -> Dictionary:
	var out := rune_slab.taught_recipes()
	for r in world_state.get("learned", []):
		out[r] = true
	return out


@rpc("authority", "call_local", "reliable")
func _ev_learned(what: String) -> void:
	hud_message.emit("The old page teaches everyone: %s" % what)


## Healing (Leech gems): the player's own computer owns their health.
func heal(peer_id: int, amount: float) -> void:
	if amount <= 0.0:
		return
	if peer_id == local_peer_id():
		var ps := get_player(peer_id)
		if ps and not ps.dying and not ps.vitals.is_dead():  # no healing a dwarf who already fell
			ps.vitals.health = minf(ps.vitals.max_health(), ps.vitals.health + amount)
	elif get_player(peer_id):
		_rpc_heal.rpc_id(peer_id, amount)


@rpc("authority", "reliable")
func _rpc_heal(amount: float) -> void:
	heal(local_peer_id(), amount)


func ask_carve(item_id: String) -> void:
	if is_host():
		request_carve(local_peer_id(), item_id)
	else:
		_rpc_carve.rpc_id(1, item_id)


func ask_craft(recipe_id: String, station_id: int = 0) -> void:
	if is_host():
		request_craft(local_peer_id(), recipe_id, station_id)
	else:
		_rpc_craft.rpc_id(1, recipe_id, station_id)


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
	if is_host() and point.is_finite() and normal.is_finite():
		request_hit(multiplayer.get_remote_sender_id(), point, normal)


@rpc("any_peer", "reliable")
func _rpc_harvest(glow_id: int) -> void:
	if is_host():
		request_harvest(multiplayer.get_remote_sender_id(), glow_id)


@rpc("any_peer", "reliable")
func _rpc_use(aim_point: Vector3, aim_normal: Vector3, yaw: float) -> void:
	# INF means "aiming at nothing"; NaN (x != x) is never allowed.
	if is_host() and aim_point == aim_point and aim_normal.is_finite() and is_finite(yaw):
		request_use(multiplayer.get_remote_sender_id(), aim_point, aim_normal, yaw)


@rpc("any_peer", "reliable")
func _rpc_buy_perk(perk_id: String) -> void:
	if is_host():
		request_buy_perk(multiplayer.get_remote_sender_id(), perk_id)


@rpc("any_peer", "reliable")
func _rpc_poi(poi_id: int) -> void:
	if is_host():
		request_poi(multiplayer.get_remote_sender_id(), poi_id)


@rpc("any_peer", "reliable")
func _rpc_carve(item_id: String) -> void:
	if is_host():
		request_carve(multiplayer.get_remote_sender_id(), item_id)


@rpc("any_peer", "reliable")
func _rpc_craft(recipe_id: String, station_id: int) -> void:
	if is_host():
		request_craft(multiplayer.get_remote_sender_id(), recipe_id, station_id)


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
	var power: float = Items.dig_power(ps.selected_item()) * ps.progress.dig_power_mult() \
		* (1.0 + Gems.bonus(ps.inventory.get_slot(ps.selected_slot)).get("dig", 0.0))
	if power <= 0:
		return {state = "no_tool"}
	if _chest(ps).distance_to(point) > REACH + 1.0:
		return {state = "too_far"}
	if normal.length_squared() < 0.25:
		return {state = "air"}
	normal = normal.normalized()  # a stretched normal would dig far past the reach check
	var center := point - normal * 0.55
	if monsters and monsters.lair_locked(center):
		return {state = "blocked", point = point, why = "The lair walls glow. No digging until the fight ends!"}
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
	give_xp(_peer_of(ps), Mat.DIG_XP.get(mat, 1), "mining")
	return {state = "dug", hits = needed, needed = needed, material = mat, point = point}


## Hitting something that grows on the cave: crystals, mushrooms, fiber, roots.
## Result like request_hit: {state = "hit"|"done"|"no_tool"|"too_far"|"gone", hits, needed}
func request_harvest(peer_id: int, glow_id: int) -> Dictionary:
	var ps := get_player(peer_id)
	if ps == null or glow == null:
		return {}
	var spot := glow.get_spot(glow_id)
	if spot.is_empty():
		return {state = "gone"}
	if _chest(ps).distance_to(spot.pos) > REACH + (spot.get("length", 0.0) if spot.kind in GlowPlacer.TALL else 0.0) + 1.0:
		return {state = "too_far"}
	var k: Dictionary = GlowPlacer.KINDS[spot.kind]
	var needed := 1
	if k.tool != "hand":
		var tool := ps.selected_item()
		if Items.tier(tool) < k.get("min_tier", 0):
			var r := {state = "blocked", point = spot.pos, why = "Too tough! This needs a copper axe."}
			_tell_feedback(peer_id, r)
			return r
		var power := 0.0
		if Items.kind(tool) == "pickaxe":
			power = Items.dig_power(tool) * ps.progress.dig_power_mult() * (0.5 if k.tool == "axe" else 1.0)
		elif Items.kind(tool) == "axe" and k.tool == "axe":
			power = Items.info(tool).power
		if power <= 0.0:
			var r := {state = "no_tool", point = spot.pos}
			_tell_feedback(peer_id, r)
			return r
		needed = ceili(k.hardness / power - 0.0001)
	if ps.harvest_id != glow_id:
		ps.harvest_id = glow_id
		ps.harvest_hits = 0
	ps.harvest_hits += 1
	if ps.harvest_hits < needed:
		var r := {state = "hit", hits = ps.harvest_hits, needed = needed, point = spot.pos}
		_tell_feedback(peer_id, r)
		return r
	ps.harvest_hits = 0
	ps.harvest_id = -1
	var count := randi_range(k.count[0], k.count[1])
	if GlowPlacer.is_plant(spot.kind) and ps.progress.perk_rank("forager") > 0:
		count += 1
	spawn_drop(k.item, count, spot.pos + spot.normal * 0.6)
	if k.has("extra"):
		spawn_drop(k.extra, 1, spot.pos + spot.normal * 0.6 + Vector3.UP * 0.3)
	give_xp(peer_id, k.xp, k.skill)
	var left: int = spot.get("chops", 1) - 1
	if left > 0:
		_ev_spot_chops.rpc(glow_id, left)
	else:
		removed_glow.append(glow_id)
		_ev_remove_glow.rpc(glow_id)
	var done := {state = "done", hits = needed, needed = needed, point = spot.pos, kind = spot.kind}
	_tell_feedback(peer_id, done)
	return done


## Right click: eat/drink the selected item, or place it if it's a station.
func request_use(peer_id: int, aim_point: Vector3, aim_normal: Vector3, yaw: float) -> String:
	var ps := get_player(peer_id)
	if ps == null:
		return ""
	var slot := ps.inventory.get_slot(ps.selected_slot)
	if slot.is_empty():
		return ""
	var id: String = slot.id
	match Items.kind(id):
		"food", "drink":
			if id == "waterskin_clean" or id == "waterskin_dirty":
				_take_sip(ps, ps.selected_slot)
			elif not ps.inventory.remove(id, 1):
				return ""
			var roll := randf()
			if peer_id == local_peer_id():
				ps.vitals.consume(id, roll)
				Sfx.ui("eat", -4.0)
			else:
				_rpc_consumed.rpc_id(peer_id, id, roll)
			# The host does the fighting math, so it remembers food damage buffs itself.
			var fb: Dictionary = Foods.buff_of(id) if Foods.is_buff_food(id) else {}
			if fb.has("damage"):
				add_boost(ps, id, {damage = fb.damage}, Foods.minutes_of(id) * 60.0)
			return "ate"
		"page":
			# An old recipe page from a ruin: the whole group learns a recipe nobody knew yet.
			var left := Recipes.LIST.keys().filter(func(r): return Recipes.LIST[r].unlock is String and Recipes.LIST[r].unlock == "ruin" \
				and not world_state.get("learned", []).has(r))
			if left.is_empty() or not ps.inventory.remove(id, 1):
				return "nothing_new"
			var r: String = left[randi() % left.size()]
			var learned: Array = world_state.get("learned", []).duplicate()
			learned.append(r)
			world_state.learned = learned
			_ev_state.rpc(world_state)
			_ev_learned.rpc(Items.display_name(Recipes.LIST[r].output))
			return "learned"
		"tonic":
			if not ps.inventory.remove(id, 1):
				return ""
			var info := Items.info(id)
			add_boost(ps, id, info.tonic, info.seconds)
			return "used"
		"horn":
			# War Horn: friends within 15 m hit 10% harder for 60 s. 5 minute cooldown.
			if ps.boosts.has("horn_cooldown") and ps.boosts.horn_cooldown.until > now():
				return "cooldown"
			add_boost(ps, "horn_cooldown", {}, 300.0)
			for pid in players:
				if players[pid].node.global_position.distance_to(ps.node.global_position) <= 15.0:
					add_boost(players[pid], "war_horn", {damage = 0.10}, 60.0)
			_ev_horn.rpc(ps.node.global_position)
			return "used"
		"throw":
			if not aim_point.is_finite() or _chest(ps).distance_to(aim_point) > 22.0 or not ps.inventory.remove(id, 1):
				return ""
			_ev_throw.rpc(_chest(ps), aim_point, id)
			if id == "spore_bomb":
				monsters.spawn_cloud(aim_point + Vector3.UP * 0.6, 3.0, 5.0, 40.0, 6.0, true)
			elif id == "blasting_pod":
				var counts := _host_dig(aim_point, 1, 2.0)  # copper-tier strength, 2 m hole
				_give_dig_drops(ps, counts, aim_point + aim_normal * 1.0)
			return "thrown"
		"station":
			if not aim_point.is_finite() or aim_normal.normalized().y < 0.6 or _chest(ps).distance_to(aim_point) > REACH + 1.0:
				return ""
			for st in stations.values():
				if st.global_position.distance_to(aim_point) < 1.5:
					return ""  # too close to another station
			if not ps.inventory.remove(id, 1):
				return ""
			var sid := _next_station_id
			_next_station_id += 1
			_ev_place_station.rpc(sid, id, aim_point, yaw)
			if Station.WATER.has(id):
				var drip := glow != null and GlowPlacer.drip_near(glow.spots_near(aim_point, 20.0), aim_point)
				_ev_water.rpc(sid, 0, drip)
			if id == "bed":
				ps.bed_pos = aim_point + Vector3.UP * 0.5
			return "placed"
		"chest":
			if not aim_point.is_finite() or aim_normal.normalized().y < 0.6 or _chest(ps).distance_to(aim_point) > REACH + 1.0:
				return ""
			if not ps.inventory.remove(id, 1):
				return ""
			storage.create_box(id, aim_point, yaw, peer_id)
			return "placed"
	return ""


# ---------------------------------------------------------------- water (doc 6.4)

func ask_collect_water(station_id: int) -> void:
	if is_host():
		request_collect_water(local_peer_id(), station_id)
	else:
		_rpc_collect_water.rpc_id(1, station_id)


@rpc("any_peer", "reliable")
func _rpc_collect_water(station_id: int) -> void:
	if is_host():
		request_collect_water(multiplayer.get_remote_sender_id(), station_id)


## Empties a drip bucket: fills your empty waterskins first, the rest becomes buckets of water.
## Returns how much water you took.
func request_collect_water(peer_id: int, station_id: int) -> int:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null or st.water <= 0 or st.global_position.distance_to(ps.node.global_position) > STATION_REACH + 1.0:
		return 0
	var took := 0
	for i in ps.inventory.slots.size():
		if st.water <= 0:
			break
		if ps.inventory.slots[i].get("id", "") == "waterskin_empty":
			ps.inventory.slots[i] = {id = "waterskin_clean", count = 1}
			st.water -= 1
			took += 1
	if st.water > 0:
		var left := ps.inventory.add("water_bucket", st.water)
		took += st.water - left
		st.water = left
	ps.inventory.changed.emit()
	_ev_water.rpc(station_id, st.water, st.under_drip)
	return took


@rpc("authority", "call_local", "reliable")
func _ev_water(station_id: int, amount: int, under_drip: bool) -> void:
	var st: Station = stations.get(station_id)
	if st:
		st.under_drip = under_drip
		st.set_water(amount)


# ---------------------------------------------------------------- boosts (host)

static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func add_boost(ps: PlayerState, name: String, data: Dictionary, seconds: float) -> void:
	var b := data.duplicate()
	b.until = now() + seconds
	ps.boosts[name] = b  # the same boost again refreshes it


## Extra damage share from active boosts. Bug oil counts only against bugs.
func damage_boost(ps: PlayerState, target_kind: String = "") -> float:
	var t := now()
	var total := 0.0
	for name in ps.boosts.keys():
		var b: Dictionary = ps.boosts[name]
		if b.until <= t:
			ps.boosts.erase(name)
			continue
		total += b.get("damage", 0.0)
		if Monsters.LIST.get(target_kind, {}).get("shape", "") in BUG_SHAPES:
			total += b.get("bugs", 0.0)
	return total


const BUG_SHAPES := ["mite", "beetle", "mantis", "crab", "moth"]


@rpc("authority", "call_local", "reliable")
func _ev_horn(at: Vector3) -> void:
	Sfx.play("dig_break", at, 6.0, 0.4)  # a deep blast
	var me := get_player(local_peer_id())
	if me and me.node.global_position.distance_to(at) <= 15.0:
		hud_message.emit("The War Horn sounds! +10% damage for 60 s")


## Everyone: something thrown flies in an arc.
@rpc("authority", "call_local", "reliable")
func _ev_throw(from: Vector3, to: Vector3, item: String) -> void:
	var ball := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.15
	s.height = 0.3
	ball.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Items.color(item)
	m.emission_enabled = true
	m.emission = Items.color(item)
	ball.material_override = m
	drops_root.add_child(ball)
	ball.global_position = from
	var t := 0.15 + from.distance_to(to) / 18.0
	var tw := ball.create_tween()
	tw.tween_method(func(k: float): ball.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI) * from.distance_to(to) * 0.25, 0.0, 1.0, t)
	tw.tween_callback(ball.queue_free)
	Sfx.play("dig_break" if item == "blasting_pod" else "dig_soft", to, 2.0, 0.7)


## Training Dummy: hitting it trains Fighting at 25% (1 XP every 4 hits).
func ask_train(station_id: int) -> void:
	if is_host():
		request_train(local_peer_id(), station_id)
	else:
		_rpc_train.rpc_id(1, station_id)


@rpc("any_peer", "reliable")
func _rpc_train(station_id: int) -> void:
	if is_host():
		request_train(multiplayer.get_remote_sender_id(), station_id)


func request_train(peer_id: int, station_id: int) -> bool:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null or st.kind != "training_dummy" or now() - ps.train_at < 0.4 \
			or st.global_position.distance_to(ps.node.global_position) > 3.5:
		return false
	ps.train_at = now()
	ps.train_hits += 1
	if ps.train_hits % 4 == 0:
		give_xp(peer_id, 1, "fighting")
	return true


func _take_sip(ps: PlayerState, slot_i: int) -> void:
	var slot := ps.inventory.slots[slot_i]
	var sips: int = slot.get("sips", Items.info(slot.id).get("sips", 1)) - 1
	if sips <= 0:
		ps.inventory.slots[slot_i] = {id = Items.info(slot.id).get("empties_to", "waterskin_empty"), count = 1}
	else:
		slot.sips = sips
	ps.inventory.changed.emit()


## Reading a wall marking (a boss clue) or taking a shrine's rune. Returns what happened.
func request_poi(peer_id: int, poi_id: int) -> String:
	var ps := get_player(peer_id)
	var pois: Array = world.maker.pois
	if ps == null or poi_id < 0 or poi_id >= pois.size():
		return ""
	var poi: Dictionary = pois[poi_id]
	if _chest(ps).distance_to(poi.pos) > 5.0:
		return "too_far"
	match poi.type:
		"marking":
			if world_state.clues.has(poi_id):
				return "already"
			world_state.clues.append(poi_id)
			for pid in players:
				give_xp(pid, 100)  # clues are shared: everyone learns from them
			_ev_state.rpc(world_state)
			return "clue"
		"lair":
			return _altar(ps, poi)
		"shrine":
			if world_state.shrines.has(poi_id):
				return "empty"
			var rune := rune_slab.pick_drop(rune_biome_at(poi.pos), [randf(), randf(), randf(), randf()])
			world_state.shrines.append(poi_id)
			if rune != "":
				var left := ps.inventory.add("rune_" + rune, 1)
				if left > 0:
					spawn_drop("rune_" + rune, 1, poi.pos + Vector3.UP)
			_ev_state.rpc(world_state)
			return "rune"
	return ""


## The summoning altar in a main boss lair: an offering brings a beaten boss back (doc 8.1).
func _altar(ps: PlayerState, poi: Dictionary) -> String:
	var boss := ""
	for id in Monsters.OFFERINGS:
		if Monsters.BOSSES[id].biome == poi.biome:
			boss = id
	if boss == "" or not world_state.bosses_dead.has(boss):
		return "sleeping"  # the boss still lives here
	if monsters._boss_alive(boss):
		return "awake"
	var need: Dictionary = Monsters.OFFERINGS[boss]
	var shard := ""
	for item in need:
		if item == "shard":
			for c in rune_slab.shards:
				if rune_slab.shards[c] > 0:
					shard = c
			if shard == "":
				return "need_offering"
		elif ps.inventory.count_of(item) < need[item]:
			return "need_offering"
	if not monsters.summon_boss(boss):
		return "awake"  # (checked before taking the offering, so nothing is lost)
	for item in need:
		if item != "shard":
			ps.inventory.remove(item, need[item])
	if shard != "":
		rune_slab.shards[shard] -= 1
		_ev_slab.rpc(rune_slab.to_data())
	return "summoned"


## Carving a rune you carry into the Rune Slab (you must stand at one).
func request_carve(peer_id: int, item_id: String) -> String:
	var ps := get_player(peer_id)
	if ps == null or not item_id.begins_with("rune_") or ps.inventory.count_of(item_id) < 1:
		return ""
	var near := false
	for st in stations.values():
		if st.kind == "rune_slab" and st.global_position.distance_to(ps.node.global_position) < STATION_REACH + 1.0:
			near = true
	if not near:
		return "no_slab"
	if not RuneSlab.RUNES.has(item_id.trim_prefix("rune_")):
		return ""  # unknown rune: keep the item instead of eating it
	ps.inventory.remove(item_id, 1)
	var result := rune_slab.offer(item_id.trim_prefix("rune_"))
	if result == "carved":
		for pid in players:
			give_xp(pid, 50)
	_ev_slab.rpc(rune_slab.to_data())
	return result


func request_buy_perk(peer_id: int, perk_id: String) -> bool:
	var ps := get_player(peer_id)
	if ps == null or not ps.progress.buy_perk(perk_id):
		return false
	_progress_dirty[peer_id] = true
	return true


## Crafting. station_id 0 = by hand. Instant recipes finish now; timed ones (smelter,
## campfire, pot, tanning rack) take their inputs now and pop out of the station later.
func request_craft(peer_id: int, recipe_id: String, station_id: int = 0) -> bool:
	var ps := get_player(peer_id)
	var r := Recipes.get_recipe(recipe_id)
	if ps == null or r.is_empty():
		return false
	if not Recipes.is_unlocked(recipe_id, ps.seen, taught_recipes()):
		return false
	var st: Station = stations.get(station_id)
	if r.station == Recipes.HAND:
		st = null
	elif st == null or Recipes.station_type(st.kind) != r.station or _chest(ps).distance_to(st.global_position) > STATION_REACH + 1.0:
		return false
	var fuel_item := ""
	if r.get("fuel", 0) > 0:
		for f in ["rootwood", "mushroom_wood"]:
			if ps.inventory.count_of(f) >= r.fuel:
				fuel_item = f
				break
		if fuel_item == "":
			return false
	if r.get("seconds", 0) > 0 and st:
		if not Crafting.missing(ps.inventory, recipe_id).is_empty() or not st.can_queue():
			return false
		for item in r.inputs:
			ps.inventory.remove(item, r.inputs[item])
		if fuel_item != "":
			ps.inventory.remove(fuel_item, r.fuel)
		st.queue_job(r.output, r.count, r.seconds)
	else:
		if not Crafting.craft(ps.inventory, recipe_id):
			return false
		if fuel_item != "":
			ps.inventory.remove(fuel_item, r.fuel)
	var skill := "survival" if r.station in ["campfire", "cooking_pot"] else "smithing"
	if peer_id == local_peer_id():
		Sfx.ui("craft", 0.0)
	var xp := 10 if Items.stack_size(r.output) == 1 else (5 if skill == "survival" else 1)
	give_xp(peer_id, xp, skill)
	return true


func request_pickup(peer_id: int, drop_id: int) -> bool:
	var ps := get_player(peer_id)
	var d: Drop = _drops.get(drop_id)
	if ps == null or d == null:
		return false
	# Each computer bounces drops on its own, and far from the host the host's copy may have
	# no floor loaded and fall away. So where it first appeared counts too.
	if _chest(ps).distance_to(d.global_position) > PICKUP_RANGE and _chest(ps).distance_to(d.home) > PICKUP_RANGE + 4.0:
		return false
	var left := ps.inventory.add(d.item_id, d.count)
	if left == d.count:
		return false
	if left == 0:
		_ev_remove_drop.rpc(drop_id)
	else:
		_ev_drop_count.rpc(drop_id, left)
	return true


## Put one fuel item (a glow crystal, rootwood...) into the lantern.
## Always says why when it can't (feedback F12: it used to fail silently).
func request_refill(peer_id: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null:
		return false
	var say := func(t: String) -> void:
		if peer_id == local_peer_id():
			hud_message.emit(t)
	if not Lantern.has_lantern(ps):
		say.call("You don't have a lantern yet. Make one in the bag (Tab).")
		return false
	if ps.fuel > MAX_FUEL - 20.0:
		say.call("Your lantern is already full.")
		return false
	for id in FUEL_ORDER:
		if ps.inventory.remove(id, 1):
			ps.fuel = minf(MAX_FUEL, ps.fuel + Items.fuel_seconds(id))
			fuel_changed.emit(peer_id, ps.fuel)
			if peer_id == local_peer_id():
				Sfx.ui("refill")
			if peer_id != local_peer_id():
				_rpc_fuel.rpc_id(peer_id, ps.fuel)
			say.call("Lantern refilled with %s." % Items.display_name(id))
			return true
	say.call("Nothing to burn! Glow crystals (hit them with a pickaxe) or rootwood work.")
	return false


## The loose rocks and the little crystal lying in the starting room (host, new games only).
func spawn_start_items() -> void:
	var st: Dictionary = world.maker.start
	if st.is_empty():
		return
	var loose: Array = st.loose
	for i in loose.size():
		var item := "crystal_blue" if i == loose.size() - 1 else "stone"
		var id := _next_drop_id
		_next_drop_id += 1
		_ev_spawn_drop.rpc(id, item, 1, loose[i], Vector3.ZERO)


# Host-side helpers that decide things, then tell everyone.

func _host_dig(center: Vector3, tool_tier: int = 0, radius: float = DIG_RADIUS) -> Dictionary:
	if glow:
		for spot in glow.spots_near(center, DIG_RADIUS + 0.9):
			_host_remove_glow(spot)
	var counts := world.apply_dig(center, radius, tool_tier)
	Sfx.play("dig_break", center, -6.0)
	if builder:
		builder.reanchor_near(center, radius)
		builder.queue_check(center, radius)
	var edit := Vector4(center.x, center.y, center.z, pack_dig(tool_tier, radius))
	edit_log.append(edit)
	_ev_dig.rpc(edit)  # the others apply it; we already did
	return counts


func _host_remove_glow(spot: Dictionary) -> void:
	removed_glow.append(spot.id)
	_ev_remove_glow.rpc(spot.id)
	var k: Dictionary = GlowPlacer.KINDS[spot.kind]
	spawn_drop(k.item, k.count[0], spot.pos + spot.normal * 0.5)


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
	Sfx.play("dig_break", Vector3(edit.x, edit.y, edit.z), -6.0)
	edit_log.append(edit)
	_pending_digs.append(edit)
	_apply_pending_digs()


func _apply_pending_digs() -> void:
	if _pending_digs.is_empty() or world == null:
		return
	var still: Array[Vector4] = []
	for e in _pending_digs:
		var c := Vector3(e.x, e.y, e.z)
		var tr := unpack_dig(e.w)
		if world.is_ready_at(c, tr.y + 1.0):
			world.apply_dig(c, tr.y, int(tr.x))  # carving is order-independent, so late is fine
		else:
			still.append(e)
	_pending_digs = still


@rpc("authority", "call_local", "reliable")
func _ev_remove_glow(glow_id: int) -> void:
	if glow:
		glow.remove_spot(glow_id)


@rpc("authority", "call_local", "reliable")
func _ev_spot_chops(glow_id: int, left: int) -> void:
	if glow:
		glow.set_chops(glow_id, left)


@rpc("authority", "call_local", "reliable")
func _ev_place_station(station_id: int, kind: String, pos: Vector3, yaw: float) -> void:
	Sfx.play("build", pos)
	var st: Station = STATION_SCRIPT.new()
	st.station_id = station_id
	st.kind = kind
	stations_root.add_child(st)
	st.global_position = pos
	st.rotation.y = yaw
	stations[station_id] = st
	_next_station_id = maxi(_next_station_id, station_id + 1)


@rpc("authority", "call_local", "reliable")
func _ev_spawn_drop(drop_id: int, item_id: String, count: int, pos: Vector3, vel: Vector3) -> void:
	var d: Drop = DROP_SCENE.new()
	d.drop_id = drop_id
	d.item_id = item_id
	d.count = count
	drops_root.add_child(d)
	d.global_position = pos
	d.home = pos
	d.linear_velocity = vel
	if vel == Vector3.ZERO:
		d.pickup_radius = Drop.LOOSE_PICKUP_RADIUS  # lying on the floor: walk up to it
		d.freeze = true  # placed on the floor already; don't fall before the floor has loaded
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


@rpc("authority", "call_local", "reliable")
func _ev_state(state: Dictionary) -> void:
	world_state = state.duplicate(true)
	if poi_field:
		for id in world_state.shrines:
			poi_field.set_taken(id)
		for id in world_state.clues:
			poi_field.set_read(id)


@rpc("authority", "call_local", "reliable")
func _ev_slab(data: Dictionary) -> void:
	rune_slab.load_data(data)


## "m" or "f": which biome's runes drop at p.
static func rune_biome_at(p: Vector3) -> String:
	return "f" if CaveMaker.biome_at(p) == "fungal" else "m"


func _seed_fungal_loot(rng: RandomNumberGenerator, id: int, ruin: bool) -> void:
	if ruin:
		storage.put(id, "recipe_page", 2)
		for g in [["keen", 0.03], ["leech", 0.04]]:
			if rng.randf() < g[1]:
				storage.put(id, Gems.item_id(g[0]), 1)
		storage.put(id, "silver_ingot", rng.randi_range(1, 3))
		storage.put(id, "crystal_amber", rng.randi_range(2, 4))
		storage.put(id, ["dish_truffle_risotto", "dish_chitin_crunch", "drink_spore_mead"][rng.randi_range(0, 2)], 1)
		if rng.randf() < 0.3:
			storage.put(id, "rune_" + rune_slab.pick_drop("f", [rng.randf(), rng.randf(), rng.randf(), rng.randf()]), 1)
		storage.put(id, "rusty_scrap", rng.randi_range(2, 5))
	else:
		storage.put(id, "crystal_amber", rng.randi_range(1, 2))
		storage.put(id, "rope", rng.randi_range(1, 3))
		storage.put(id, ["spore_truffle", "ember_morel", "mushroom_flesh"][rng.randi_range(0, 2)], rng.randi_range(2, 4))


## Host, new world only: fill the ruin and camp chests with old loot (world doc 3.1).
func seed_poi_loot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world.maker.seed + 4242
	for poi in world.maker.pois:
		if poi.type != "ruin" and poi.type != "camp":
			continue
		var at: Vector3 = world.maker.find_floor(poi.pos.x + 1.5, poi.pos.z + 1.0, poi.pos.y + 3.0)
		var id := storage.create_box("chest_small", at, rng.randf() * TAU)
		if poi.get("biome", "mossy") == "fungal":
			_seed_fungal_loot(rng, id, poi.type == "ruin")
			continue
		if poi.type == "ruin":
			storage.put(id, "recipe_page", 2)  # every old ruin keeps forgotten recipes
			for g in [["keen", 0.03], ["ember", 0.03]]:  # doc 4.2: rare gems in old chests
				if rng.randf() < g[1]:
					storage.put(id, Gems.item_id(g[0]), 1)
			storage.put(id, "copper_ingot", rng.randi_range(2, 4))
			storage.put(id, "crystal_blue", rng.randi_range(2, 5))
			storage.put(id, ["dish_hollowcap_stew", "dish_tuber_mash", "drink_glowcap_tea"][rng.randi_range(0, 2)], 1)
			if rng.randf() < 0.3:
				storage.put(id, "rune_" + rune_slab.pick_drop("m", [rng.randf(), rng.randf(), rng.randf()]), 1)
			storage.put(id, "rusty_scrap", rng.randi_range(1, 4))
		else:
			storage.put(id, "crystal_blue", rng.randi_range(1, 3))
			storage.put(id, "rope", rng.randi_range(1, 3))
			storage.put(id, ["critter_meat", "glowcap", "bellcap"][rng.randi_range(0, 2)], rng.randi_range(2, 4))


@rpc("authority", "reliable")
func _rpc_consumed(item_id: String, roll: float) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.vitals.consume(item_id, roll)


@rpc("authority", "reliable")
func _rpc_progress(data: Dictionary) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.progress.load_data(data)


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
	var sts := []
	for id in stations:
		var st: Station = stations[id]
		sts.append([id, st.kind, st.global_position, st.rotation.y, st.jobs.duplicate(true), st.water, st.under_drip])
	var chops := {}
	if glow:
		for id in glow._spots:
			if glow._spots[id].get("chops", 1) != GlowPlacer.KINDS[glow._spots[id].kind].get("chops", 1):
				chops[id] = glow._spots[id].chops
	return {edits = edit_log.duplicate(), glow = removed_glow.duplicate(), drops = drops, next_drop = _next_drop_id,
		stations = sts, chops = chops, runes = rune_slab.to_data(), build = builder.snapshot(), boxes = storage.snapshot(), monsters = monsters.snapshot(), state = world_state}


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
	for st in snap.get("stations", []):
		_ev_place_station(st[0], st[1], st[2], st[3])
		if st.size() > 4 and stations.has(st[0]):
			stations[st[0]].jobs.assign(st[4])  # smelting/cooking in progress survives a save
		if st.size() > 6 and stations.has(st[0]):
			stations[st[0]].under_drip = st[6]
			stations[st[0]].set_water(st[5])
	for id in snap.get("chops", {}):
		if glow:
			glow.set_chops(id, snap.chops[id])
	if snap.has("runes"):
		rune_slab.load_data(snap.runes)
	if snap.has("boxes"):
		storage.load_snapshot(snap.boxes)  # before build: build sites sort their plan by their chest
	if snap.has("build"):
		builder.load_snapshot(snap.build)
	if snap.has("monsters"):
		monsters.load_snapshot(snap.monsters)
	if snap.has("state"):
		_ev_state(snap.state)


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
		var ore: bool = mat == Mat.COPPER or mat == Mat.SILVER
		if ore:
			n = maxi(n, 1)  # always feel rewarded for hitting ore
			if randf() < Gems.bonus(ps.inventory.get_slot(ps.selected_slot)).get("extra_ore", 0.0):
				n += 1  # Burrow gem
			for i in n:
				if randf() < 0.005:
					spawn_drop(Gems.item_id("burrow"), 1, pos)  # ore veins hide Burrow gems (doc 4.2)
		if n > 0:
			spawn_drop(item, n, pos)


## Our dwarf's health hit zero.
func ask_died() -> void:
	if is_host():
		request_died(local_peer_id())
	else:
		_rpc_died.rpc_id(1)


@rpc("any_peer", "reliable")
func _rpc_died() -> void:
	if is_host():
		request_died(multiplayer.get_remote_sender_id())


## Death (progression doc 9): bag items and hotbar stackables go into a grave where you fell.
## Hotbar tools (stack 1) and the lantern stay with you. You wake at your bed.
func request_died(peer_id: int) -> void:
	var ps := get_player(peer_id)
	if ps == null:
		return
	var where: Vector3 = ps.node.global_position
	var grave := -1
	for i in ps.inventory.slots.size():
		var s: Dictionary = ps.inventory.slots[i]
		if s.is_empty() or (i < Inventory.HOTBAR_SIZE and Items.stack_size(s.id) == 1):
			continue
		if grave < 0:
			grave = storage.create_box("grave", where, 0.0, peer_id)
		storage.boxes[grave].inv.slots[i] = s.duplicate()
		ps.inventory.slots[i] = {}
	if grave >= 0:
		storage._changed(grave)
	ps.inventory.changed.emit()
	var wake: Vector3 = ps.bed_pos if ps.bed_pos != Vector3.INF else world.maker.spawn_point
	if peer_id == local_peer_id():
		_respawn_here(wake)
	else:
		_rpc_respawn.rpc_id(peer_id, wake)


@rpc("authority", "reliable")
func _rpc_respawn(wake: Vector3) -> void:
	_respawn_here(wake)


func _respawn_here(wake: Vector3) -> void:
	var me := get_player(local_peer_id())
	if me == null:
		return
	me.vitals.respawn()
	me.dying = false
	me.node.global_position = wake
	if me.node is CharacterBody3D:
		(me.node as CharacterBody3D).velocity = Vector3.ZERO
	if me.node is Dwarf:
		(me.node as Dwarf).model.react("wake")  # you wake up and get to your feet


## Something hurt a player (falling rock now, monsters in Step 5). Their own computer
## owns their body, so the host sends it there.
func hurt(peer_id: int, amount: float, buildup: Dictionary = {}) -> void:
	var ps := get_player(peer_id)
	if ps == null:
		return
	if peer_id == local_peer_id():
		_take_hurt(ps, amount, buildup)
	else:
		_rpc_hurt.rpc_id(peer_id, amount, buildup)


@rpc("authority", "reliable")
func _rpc_hurt(amount: float, buildup: Dictionary = {}) -> void:
	var me := get_player(local_peer_id())
	if me:
		_take_hurt(me, amount, buildup)


func _take_hurt(ps: PlayerState, amount: float, buildup: Dictionary) -> void:
	ps.vitals.take_damage(amount)
	Sfx.ui("hit_heavy", 0.0)
	for k in buildup:
		ps.vitals.ailments.add(k, buildup[k])


## Host only: friendly fire on/off (combat doc 2.7: on by default).
func set_friendly_fire(on: bool) -> void:
	if is_host():
		world_state.friendly_fire = on
		_ev_state.rpc(world_state)


func friendly_fire() -> bool:
	return world_state.get("friendly_fire", true)


## XP from the host. Goes to the skill and the character level, then syncs to the player.
func give_xp(peer_id: int, amount: int, skill: String = "") -> void:
	var ps := get_player(peer_id)
	if ps == null or amount <= 0:
		return
	ps.progress.add_xp(amount, skill)
	_progress_dirty[peer_id] = true


func _peer_of(ps: PlayerState) -> int:
	for id in players:
		if players[id] == ps:
			return id
	return -1


## Hunger, thirst, stamina and healing for OUR dwarf (each computer runs its own player's body).
func _tick_vitals(ps: PlayerState, delta: float) -> void:
	var resting := false
	for st in stations.values():
		if st.kind in ["campfire", "bed"] and st.global_position.distance_to(ps.node.global_position) < 4.0:
			resting = true
			break
	var v := ps.vitals
	if v.is_dead():
		if not ps.dying:
			ps.dying = true
			ask_died()
		return
	var hunger_before := v.hunger
	var thirst_before := v.thirst
	v.tick(delta, resting)
	# Survival skill and perks slow the drain.
	v.hunger = hunger_before - (hunger_before - v.hunger) * ps.progress.hunger_drain_mult() * (1.0 + rune_slab.bonus("hunger_drain"))
	v.thirst = thirst_before - (thirst_before - v.thirst) * ps.progress.thirst_drain_mult() * (1.0 + rune_slab.bonus("thirst_drain"))


func station_near(p: Vector3, radius: float = STATION_REACH) -> Station:
	var best: Station = null
	for st in stations.values():
		if st.global_position.distance_to(p) <= radius and (best == null or st.global_position.distance_to(p) < best.global_position.distance_to(p)):
			best = st
	return best


## A dig's pickaxe tier and size, squeezed into one number: tier × 1000 + radius in cm.
## (Exact to the centimeter, so every computer carves exactly the same hole.)
static func pack_dig(tool_tier: int, radius: float) -> float:
	return tool_tier * 1000.0 + roundf(radius * 100.0)


## Back to Vector2(tier, radius).
static func unpack_dig(w: float) -> Vector2:
	return Vector2(floorf(w / 1000.0), fmod(w, 1000.0) / 100.0)


func drop_count() -> int:
	return _drops.size()


func pending_dig_count() -> int:
	return _pending_digs.size()


func _chest(ps: PlayerState) -> Vector3:
	return ps.node.global_position + Vector3.UP * 1.0
