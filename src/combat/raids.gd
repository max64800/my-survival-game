class_name Raids
extends Node
## Raids on your base (combat doc 8.6). Runs on the host (Authority/Raids).
##  - A side boss whose cavern you've found sends raids until you kill it.
##  - Killing the biome's main boss stops all raids.
##  - Only when someone is home (within 40 m of a base = bed + a crafting station within 20 m).
##  - Check every 30 min, 35% chance, at least 20 min apart, 60 s warning, raid lasts 4 min.

signal warning(text: String)  ## shown to everyone

const CHECK_EVERY := 1800.0
const CHANCE := 0.35
const MIN_GAP := 1200.0
const WARN_TIME := 60.0
const RAID_TIME := 240.0
const HOME_RANGE := 40.0
const QUIET_AFTER_FOUND := 3600.0  ## no raid in the first hour after a new source appears
const SOURCES := {
	"skerra": [["mossnipper", 5, true], ["skitterling", 2, false]],  ## [kind, count, first one is a leader]: Elder + 4 + 2 = 7
	"brask": [["rustwight", 3, true], ["cairnling", 1, false]],
}

var auth: GameAuthority
var clock := 0.0
var _next_check := CHECK_EVERY
var _last_raid := -MIN_GAP
var _found_at := {}  ## source -> clock when its cavern was found
var active := {}  ## {source, base, arrive_at, end_at, uids}


func _ready() -> void:
	auth = get_parent()


func _process(delta: float) -> void:
	if not auth.is_host() or auth.world == null:
		return
	clock += delta
	for s in auth.world_state.lairs_found:
		if not _found_at.has(s):
			_found_at[s] = clock
	if not active.is_empty():
		_run_active()
	elif clock >= _next_check:
		_next_check = clock + CHECK_EVERY
		if randf() < CHANCE:
			try_start()


## Raid sources right now: found side-boss caverns whose boss lives, unless the main boss is dead.
func sources() -> Array:
	var out := []
	if auth.world_state.bosses_dead.has("orrumhal"):
		return out
	for s in SOURCES:
		if auth.world_state.lairs_found.has(s) and not auth.world_state.bosses_dead.has(s):
			if clock - _found_at.get(s, clock) >= QUIET_AFTER_FOUND:
				out.append(s)
	return out


## A base = a bed with a crafting station within 20 m, and a player within 40 m of it.
func occupied_base() -> Vector3:
	for bed in auth.stations.values():
		if bed.kind != "bed":
			continue
		var has_station := false
		for st in auth.stations.values():
			if st != bed and st.kind != "bed" and st.global_position.distance_to(bed.global_position) <= 20.0:
				has_station = true
		if not has_station:
			continue
		for pid in auth.players:
			if auth.players[pid].node.global_position.distance_to(bed.global_position) <= HOME_RANGE:
				return bed.global_position
	return Vector3.INF


## Starts a raid if everything allows it (also used by tests). Returns the source or "".
func try_start(force_source: String = "") -> String:
	if not active.is_empty() or clock - _last_raid < MIN_GAP and force_source == "":
		return ""
	var srcs := sources() if force_source == "" else [force_source]
	if srcs.is_empty():
		return ""
	var base := occupied_base()
	if base == Vector3.INF:
		return ""
	var src: String = srcs.pick_random()
	_last_raid = clock
	active = {source = src, base = base, arrive_at = clock + WARN_TIME, end_at = clock + WARN_TIME + RAID_TIME, uids = []}
	_ev_warning.rpc("Something is coming up the tunnels… (%s's raiders)" % Monsters.BOSSES[src].name.get_slice(",", 0))
	return src


func _run_active() -> void:
	if active.uids.is_empty() and clock >= active.arrive_at:
		active.uids = _send_raiders(active.source, active.base)
		active.arrive_at = INF
		return
	if active.arrive_at != INF:
		return
	var alive: Array = active.uids.filter(func(u): return auth.monsters.monsters.has(u))
	if alive.is_empty():
		# The whole raid is beaten: everyone gets a rune shard (doc 8.6).
		for pid in auth.players:
			var colour: String = RuneSlab.COLOURS.keys().pick_random()
			auth.rune_slab.shards[colour] += 1
		auth._ev_slab.rpc(auth.rune_slab.to_data())
		_ev_warning.rpc("The raid is beaten! Everyone gets a rune shard.")
		active = {}
	elif clock >= active.end_at:
		for u in alive:
			auth.monsters._ev_remove.rpc(u)  # survivors slink back into the tunnels
		_ev_warning.rpc("The raiders slink back into the tunnels.")
		active = {}


## Raiders come out of a tunnel 30-60 m from the base and head straight for it. Monsters never dig.
func _send_raiders(src: String, base: Vector3) -> Array:
	var maker: CaveMaker = auth.world.maker
	var entry := Vector3.INF
	for sg in maker.segments:
		var p: Vector3 = (sg.a + sg.b) * 0.5
		var d := p.distance_to(base)
		if d >= 30.0 and d <= 60.0:
			entry = p
			break
	if entry == Vector3.INF:
		entry = base + Vector3(30, 0, 0)
	var uids := []
	var mm := auth.monsters
	var target := 0
	for pid in auth.players:
		target = pid
	for group in SOURCES[src]:
		for i in group[1]:
			var uid := mm._next_uid
			mm._next_uid += 1
			var spot: Vector3 = maker.find_floor(entry.x + randf_range(-2, 2), entry.z + randf_range(-2, 2), entry.y + 2.0)
			mm._ev_spawn.rpc(uid, group[0], spot + Vector3.UP * 0.3, group[2] and i == 0, 2000)
			var m: Monster = mm.get_monster(uid)
			if m:
				m.home = base  # they head for the base
				m.alert(target)
			uids.append(uid)
	return uids


@rpc("authority", "call_local", "reliable")
func _ev_warning(text: String) -> void:
	Sfx.ui("parry", -6.0)  # a distant bell
	warning.emit(text)
