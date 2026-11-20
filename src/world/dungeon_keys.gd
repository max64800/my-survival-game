class_name DungeonKeys
extends Node
## Keys and locked round doors of the medium and big Zone 1 dungeons (owner, Nov 20, F237; key names from
## docs/design/zone1-dungeons/05-*.md to 12-*.md). A helper of the GameAuthority, same pattern as Storage:
## ask_* (your computer) → request_* (host checks) → _ev_* (everyone). Saved in world_state.
## Each mini boss drops its key; whoever in the group holds it opens that dungeon's door. The Hammerfall Works' gate
## has two locks (Gear Key + Hammer Key), each opened by its own key, so two friends can open one each.
## An hour of play after a key dropped (DungeonLoot.REFILL), it goes back to its boss: it vanishes from every bag,
## chest and floor, and its lock closes again.
##
## Owner, Nov 20: the locked door is in the boss room and opens the treasure room. Every dungeon (all 12) also has an
## exit gate in its first room with no handle outside: the way out ends behind it, and a lever there opens it. It
## closes again when the dungeon refills (an hour after it was opened, while nobody is near).
##
## Hook-in (PC, not done yet): in GameAuthority._ready, like Storage: `keys = DungeonKeys.new(); keys.name = "DungeonKeys";
## add_child(keys)`. Door built → add_door(dungeon_id, pos). E on the door → ask_unlock(dungeon_id). Boss spawns
## holding its key only if boss_has_key(key). Boss dies → drop_key(key, pos). Door looks follow door_changed / is_open().
## Exit gate built → add_gate(dungeon_id, lever_pos). E on the lever → ask_pull_lever(dungeon_id). Looks: gate_changed / gate_open().

signal door_changed(dungeon_id: String, open: bool)
signal gate_changed(dungeon_id: String, open: bool)

## Medium dungeons get the iron key picture, big ones the copper one (both our own models, recoloured later).
const KEYS := {
	key_bronze = {name = "Bronze Key", dungeon = "tomb_of_hald_ironbrow", boss = "The Shield-Brother"},
	key_barrow = {name = "Barrow Key", dungeon = "the_quiet_barrows", boss = "The Barrow Keeper"},
	key_vault = {name = "Vault Key", dungeon = "brassgate_vault", boss = "The Vault Captain"},
	key_armoury = {name = "Armoury Key", dungeon = "hall_of_the_shieldbearers", boss = "Sergeant Halfhelm"},
	key_rune = {name = "Rune Key", dungeon = "vigil_of_orrin_stonejaw", boss = "Orrin's Last Acolyte"},
	key_forge = {name = "Forge Key", dungeon = "emberdeep_forge", boss = "The Forge Foreman"},
	key_gear = {name = "Gear Key", dungeon = "the_hammerfall_works", boss = "The Gearmaster"},
	key_hammer = {name = "Hammer Key", dungeon = "the_hammerfall_works", boss = "The Smeltwarden"},
	key_foundry = {name = "Foundry Key", dungeon = "cinderhold_foundry", boss = "The Cinder Warden"},
}
const REACH := 4.0
## shortcut: a lock only closes again while nobody is this close to its door (so nobody gets shut inside); a
## medium dungeon fits in 60 m. Upgrade to the dungeon's real bounds once the PC builds them.
const KEEP_AWAY := 60.0

var auth: GameAuthority
var doors := {}  ## dungeon id -> door position (registered each time a dungeon is built; not saved)
var gates := {}  ## dungeon id -> the exit gate's lever position (inside, behind the gate)
var _timer := 0.0


func _ready() -> void:
	auth = get_parent()


func _process(delta: float) -> void:
	if not auth.is_host():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = DungeonLoot.CHECK_EVERY
		tick()


static func keys_of(dungeon_id: String) -> Array:
	return KEYS.keys().filter(func(k): return KEYS[k].dungeon == dungeon_id)


## Item data for Items (one entry per key).
static func item_data() -> Dictionary:
	var out := {}
	for k in KEYS:
		var big: bool = DungeonList.get_dungeon(KEYS[k].dungeon).size == "big"
		out[k] = {name = KEYS[k].name, stack = 1, kind = "key", short = "Ky", icon_of = "key_copper" if big else "key_iron",
			color = Color(0.85, 0.5, 0.3) if big else Color(0.55, 0.55, 0.6)}
	return out


func add_door(dungeon_id: String, pos: Vector3) -> void:
	doors[dungeon_id] = pos


## Every lock of the door is open.
func is_open(dungeon_id: String) -> bool:
	var opened: Array = auth.world_state.get("dungeon_doors", {}).get(dungeon_id, [])
	return keys_of(dungeon_id).all(func(k): return opened.has(k))


## Host: the boss still carries its key (false while the key is out in the world).
func boss_has_key(key: String) -> bool:
	return not auth.world_state.get("dungeon_keys", {}).has(key)


## Host: the boss died. Its key drops (once; the hour starts now).
func drop_key(key: String, pos: Vector3) -> void:
	if not KEYS.has(key) or not boss_has_key(key):
		return
	var out: Dictionary = auth.world_state.get("dungeon_keys", {}).duplicate()
	out[key] = float(auth.world_state.get("played", 0.0))
	auth.world_state.dungeon_keys = out
	auth.spawn_drop(key, 1, pos)


# ================================================================== ask → host → everyone

func ask_unlock(dungeon_id: String) -> void:
	if auth.is_host():
		auth.tell(auth.local_peer_id(), request_unlock(auth.local_peer_id(), dungeon_id))
	else:
		_rpc_unlock.rpc_id(1, dungeon_id)


@rpc("any_peer", "reliable")
func _rpc_unlock(dungeon_id: String) -> void:
	if auth.is_host():
		var peer := multiplayer.get_remote_sender_id()
		auth.tell(peer, request_unlock(peer, dungeon_id))


## Host: opens every lock of the door this player has the key for. Returns the line for their screen.
func request_unlock(peer_id: int, dungeon_id: String) -> String:
	var ps := auth.get_player(peer_id)
	if ps == null or not doors.has(dungeon_id) or keys_of(dungeon_id).is_empty():
		return ""
	if ps.node.global_position.distance_to(doors[dungeon_id]) > REACH + 1.0:
		return "Too far away."
	if is_open(dungeon_id):
		return "It's open."
	var opened: Array = auth.world_state.get("dungeon_doors", {}).get(dungeon_id, []).duplicate()
	var turned := false
	for k in keys_of(dungeon_id):
		if not opened.has(k) and ps.inventory.count_of(k) > 0:
			opened.append(k)
			turned = true
	var missing := keys_of(dungeon_id).filter(func(k): return not opened.has(k)).map(func(k): return KEYS[k].name)
	if not turned:
		return "Locked. It needs the %s." % " and the ".join(missing)
	_ev_door.rpc(dungeon_id, opened)
	return "The door swings open." if missing.is_empty() else "One lock clicks open. The other needs the %s." % missing[0]


@rpc("authority", "call_local", "reliable")
func _ev_door(dungeon_id: String, opened: Array) -> void:
	var all: Dictionary = auth.world_state.get("dungeon_doors", {}).duplicate()
	all[dungeon_id] = opened
	auth.world_state.dungeon_doors = all
	door_changed.emit(dungeon_id, is_open(dungeon_id))


# ================================================================== the exit gate (lever only on the inside)

func add_gate(dungeon_id: String, lever_pos: Vector3) -> void:
	gates[dungeon_id] = lever_pos


func gate_open(dungeon_id: String) -> bool:
	return auth.world_state.get("dungeon_gates", {}).has(dungeon_id)


func ask_pull_lever(dungeon_id: String) -> void:
	if auth.is_host():
		auth.tell(auth.local_peer_id(), request_pull_lever(auth.local_peer_id(), dungeon_id))
	else:
		_rpc_pull_lever.rpc_id(1, dungeon_id)


@rpc("any_peer", "reliable")
func _rpc_pull_lever(dungeon_id: String) -> void:
	if auth.is_host():
		var peer := multiplayer.get_remote_sender_id()
		auth.tell(peer, request_pull_lever(peer, dungeon_id))


## Host: the lever opens the exit gate. Returns the line for their screen.
func request_pull_lever(peer_id: int, dungeon_id: String) -> String:
	var ps := auth.get_player(peer_id)
	if ps == null or not gates.has(dungeon_id):
		return ""
	if ps.node.global_position.distance_to(gates[dungeon_id]) > REACH + 1.0:
		return "Too far away."
	if gate_open(dungeon_id):
		return "The gate is already open."
	_ev_gate.rpc(dungeon_id, float(auth.world_state.get("played", 0.0)))
	return "The gate grinds open. The way out!"


## opened_at < 0: the gate closes.
@rpc("authority", "call_local", "reliable")
func _ev_gate(dungeon_id: String, opened_at: float) -> void:
	var all: Dictionary = auth.world_state.get("dungeon_gates", {}).duplicate()
	if opened_at < 0.0:
		all.erase(dungeon_id)
	else:
		all[dungeon_id] = opened_at
	auth.world_state.dungeon_gates = all
	gate_changed.emit(dungeon_id, opened_at >= 0.0)


# ================================================================== the key goes back to its boss, the gate closes

## Host, every DungeonLoot.CHECK_EVERY seconds.
func tick() -> void:
	var played: float = auth.world_state.get("played", 0.0)
	var open_gates: Dictionary = auth.world_state.get("dungeon_gates", {})
	for d in open_gates.keys():
		if played - float(open_gates[d]) >= DungeonLoot.REFILL and not (gates.has(d) and _someone_near(gates[d])):
			_ev_gate.rpc(d, -1.0)
	var out: Dictionary = auth.world_state.get("dungeon_keys", {})
	for key in out.keys():
		var d: String = KEYS[key].dungeon
		if played - float(out[key]) < DungeonLoot.REFILL or (doors.has(d) and _someone_near(doors[d])):
			continue
		_take_back(key)
		out.erase(key)
		var opened: Array = auth.world_state.get("dungeon_doors", {}).get(d, [])
		if opened.has(key):
			_ev_door.rpc(d, opened.filter(func(k): return k != key))
	auth.world_state.dungeon_keys = out


func _take_back(key: String) -> void:
	for pid in auth.players:
		var inv: Inventory = auth.players[pid].inventory
		inv.remove(key, inv.count_of(key))  # (the bag sends itself to its player)
	for id in auth.storage.boxes:
		var inv: Inventory = auth.storage.boxes[id].inv
		if inv.count_of(key) > 0:
			inv.remove(key, inv.count_of(key))
			auth.storage._changed(id)
	for id in auth._drops.keys():
		if auth._drops[id].item_id == key:
			auth._ev_remove_drop.rpc(id)


func _someone_near(p: Vector3) -> bool:
	for pid in auth.players:
		if auth.players[pid].node.global_position.distance_to(p) < KEEP_AWAY:
			return true
	return false
