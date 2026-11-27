class_name GameAuthority
extends Node

signal hud_message(text: String)  ## a line for our own screen
signal music_stinger(name: String)  ## a short jingle for everyone (Music plays it)
signal learned_recipe(recipe_id: String)  ## a recipe page taught the group something (a card on the left)
signal learned_blueprint(what: String, page_id: String, why: String)
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

const REACH := 3.0  ## meters from the dwarf's chest to what they're hitting (was 4.5; owner F149: walk up to things)
const DIG_RADIUS := 1.35  ## size of the scoop one finished dig removes
const PICKUP_RANGE := 6.0
const MAX_FUEL := 600.0  ## 10 minutes of full lantern light
const FUEL_SYNC_TIME := 2.0
const DROP_SCENE := preload("res://src/items/drop.gd")
const STATION_SCRIPT := preload("res://src/world/station.gd")
const STATION_REACH := 4.0
const PROGRESS_SYNC_TIME := 0.5
## Fuel the R key uses, best first.
const FUEL_ORDER := ["crystal_white", "crystal_amber", "crystal_violet", "crystal_blue", "crystal_green", "crystal_red", "rootwood", "mushroom_wood"]

static var instance: GameAuthority

var world: World
var glow: GlowField
var drops_root: Node3D
var players: Dictionary = {}  ## peer_id -> PlayerState
var edit_log: Array[Vector4] = []  ## every dig: center (xyz) + packed tier & size (w, see pack_dig), for late joiners
var removed_glow: Array[int] = []
var cave_life: CaveLife  ## grass, ferns, small roots... (only looks, but they break when hit: F197)
var curtains: RootCurtains  ## root curtains in tunnel mouths (break for fiber)
var clutter: Clutter  ## pebbles, dripstone, the big hanging roots (those break for wood)
var removed_strands: Array[int] = []  ## root-curtain strands broken so far (saved)
var removed_hroots: Array[String] = []  ## big hanging roots broken so far (saved)
var pillars: RootPillars  ## giant root pillars (chop for wood)
var pillar_chops := {}  ## pillar id -> how much wood it has given (saved)
var groves: GlowGroves  ## glow-grove trees (chop for wood; owner Nov 19)
var grove_chops := {}  ## grove tree id -> how much wood it has given (saved)
var grove_regrow := {}  ## felled grove tree id -> seconds until it stands again (saved)
var tree_regrow := {}  ## broken Root Tree id -> seconds until it's whole again (saved)
var boulders: Boulders  ## breakable boulders (stone)
var boulder_hits := {}  ## boulder id -> hits taken (saved)
## Host: where each player last stood on solid ground, a few times a second: [[time, position], ...] (the newest last).
## A grave goes where you stood about GRAVE_BACK seconds before you died (dungeon decisions, round 2: every death,
## everywhere, so a grave never lands at the bottom of a chasm or inside a trap).
var _safe_spots := {}
var _safe_clock := 0.0
var _safe_tick := 0.0
const GRAVE_BACK := 3.0
var boulder_back := {}  ## broken boulder id -> seconds until a new one stands there (saved)
var removed_plants: Array[int] = []  ## cave-life plants broken so far (saved, sent to late joiners)
## Host: chopped roots growing back (F106): glow id -> seconds left.
var regrow := {}
var plant_regrow := {}  ## small roots (cave-life plant id) -> seconds until they grow back (saved)
const REGROW_TIME := 600.0  ## 10 minutes
const CRYSTAL_REGROW_TIME := 5400.0  ## 90 minutes (owner F406)
var _drops: Dictionary = {}  ## drop_id -> Drop
var _next_drop_id := 1
var _drop_extra := {}  ## host: drop_id -> the whole slot a thrown item came from (wear, upgrades, gems), F825
var _pending_digs: Array[Vector4] = []  ## digs waiting for that part of the cave to load
var _fuel_sync := 0.0
var _auto_timer := 0.0
const REST_FOR_COZY := 5.0
var _rest_seconds := 0.0  ## our dwarf: how long we've rested by a fire/bed
var _comfort_timer := 0.0
var comfort_here := 0  ## our dwarf's comfort right now (0 = not resting)  ## host: self-running furnaces look in their chests once a second
var stations: Dictionary = {}  ## station id -> Station node
var stations_root: Node3D
var rune_slab := RuneSlab.new()  ## one per world, shared by everyone
var builder: Builder
var storage: Storage
var keys: DungeonKeys  ## dungeon keys and locked doors (F237; Mossgate's loot door: owner, Nov 20)
var monsters: MonsterManager
var loot_props: LootProps  ## lootable decor in dungeons and ruins (E: take its items, it shows empty; Nov 22)
var poi_field: PoiField
## What the whole world remembers (shared by every player): shrines emptied (and more keys added later:
## columns, learned, blueprints...). Old saves may still carry clues/bosses_dead/lairs_found: unused now.
var world_state := {shrines = []}
var _refill_timer := 0.0  ## counts down to the next dungeon-chest refill check
var _next_station_id := 1
var _progress_dirty := {}  ## peer ids whose XP changed and need a sync
var _progress_sync := 0.0
var _banners := []  ## host: Clan Banners standing, {at, until}; friends within BANNER_REACH of one resist ailments
var _banner_tick := 0.0
const BANNER_REACH := 10.0
const BREW_REACH := 5.0   ## Healing Brew heals everyone this close to where the flask splashes
const BREW_THROW := 14.0  ## how far the flask flies at most


## Item kinds you hold in your hand to use. Anything else picked on the hotbar (rocks, ore,
## crystals...) leaves your hand free, so the equipped pickaxe is used.
const HAND_DIG := 1.0 / 3.0  ## bare hands dig at a third of a stone pickaxe's power (F89)
const BANDAGE_COOLDOWN := 30.0  ## seconds between two bandages (owner, Nov 20)
const HAND_KINDS := ["pickaxe", "axe", "hammer", "weapon", "shield", "food", "drink", "station", "chest",
	"throw", "tonic", "waterskin", "horn", "lens", "page", "rune"]


class PlayerState:
	var node: Node3D
	var inventory := Inventory.new(Inventory.PLAYER_SIZE)  ## with backpack + equipment slots (F23)
	var selected_slot := 0
	var weapon_drawn := false  ## F: fighting with the equipped weapon (+ shield)
	var hands_empty := false  ## the picked hotbar number pressed again: tool put away (owner, Nov 17)
	var equip_job := {}  ## putting something on (F826): {index, id, left, total, to, to_id, ring}; own computer only
	var equip_queue: Array = []  ## more rings filling at the same time (F828: helm, chest, legs, boots together)
	var fuel := GameAuthority.MAX_FUEL
	var needs_lantern := false  ## true = started with nothing: no light until you pick up the Lantern
	var thrifty_saved := 0.0  ## Thrifty perk: wear skipped so far (1.0 = skip the next one)
	var lantern_stowed := false  ## L: the lantern put away (no light, no fuel used) (owner, Nov 17)
	var dig_target := Vector3.INF
	var dig_hits := 0
	var harvest_id := -1
	var harvest_hits := 0
	var leftovers := {}  ## material -> voxels dug that didn't add up to a whole item yet
	var vitals := Vitals.new()  ## simulated on the player's own computer
	var fall := FallDamage.new()  ## watches for long falls (own computer too)
	var progress := Progression.new()  ## owned by the host, copied to the player
	var seen := {}  ## every item id this player has held (unlocks recipes)
	var bed_pos := Vector3.INF  ## where you wake up after dying (INF = the world start)
	var dying := false
	## Host: timed fight boosts it can see (food damage buffs, whetstone, bug oil, war horn).
	## name -> {damage, bugs, until (host seconds)}
	var boosts := {}
	## Host: the foods and drink this player has eaten: id -> until (host seconds). Full = no more eating (owner F824).
	var meals := {}
	var train_hits := 0
	var train_at := 0.0
	var body_xp_at := 0.0  ## when this player last sent Running/Jumping practice
	var run_carry := 0.0  ## Running XP below 1 waiting to add up
	var low_health := false  ## below 30% health (Berserker); sent by the player's own computer

	func _init() -> void:
		inventory.changed.connect(_note_seen)
		vitals.damaged.connect(func(_amount: float): equip_job = {}; equip_queue.clear())  # a hit stops it (owner F826)
		inventory.changed.connect(func(): vitals.gear = Gems.armor_bonus(inventory))  # armor gems work on your body
		vitals.progress = progress

	func _note_seen() -> void:
		for slot in inventory.slots:
			if not slot.is_empty():
				seen[slot.id] = true

	## What's in the dwarf's hand (feedback F23): the equipped weapon while it's drawn (F);
	## otherwise the picked hotbar item if it's something you hold to use; otherwise (empty hand,
	## rocks, ore...) the equipped pickaxe, so you can always dig.
	func selected_item() -> String:
		var s := inventory.get_slot(hand_slot())
		return "" if Durability.broken(s) else s.get("id", "")  # a broken tool does nothing until it's repaired

	## F can draw something: an equipped weapon, or at least an equipped shield.
	func can_draw() -> bool:
		return inventory.equipped("weapon") != "" or inventory.equipped("shield") != ""

	## The slot index of what's in hand (a hotbar slot or an equipment slot).
	## Host: is there a free food (or drink) slot for this meal? The same dish again just refreshes.
	func meal_fits(id: String, at: float) -> bool:
		var list := []
		for m in meals.keys():
			if meals[m] > at:
				list.append({id = m})
			else:
				meals.erase(m)
		return Vitals.meal_fits(list, id, vitals.food_slots())

	func hand_slot() -> int:
		if not equip_job.is_empty():
			return -1  # putting something on: hands busy until the ring is full (F826)
		if weapon_drawn and inventory.equipped("weapon") != "":
			return inventory.worn_slot("weapon")
		if weapon_drawn and inventory.equipped("shield") != "":
			return inventory.worn_slot("shield")  # only a shield worn: F raises it alone (owner, Nov 17)
		if hands_empty:
			return -1  # nothing in hand (an empty slot: get_slot(-1) is {})
		var picked: String = inventory.get_slot(selected_slot).get("id", "")
		if Inventory.equip_slot_for(picked) in Inventory.HAND and not inventory.is_worn(selected_slot):
			return -1  # a pickaxe/weapon/shield is used only once it's on (F826: picking it starts the ring)
		if picked == "":  # an empty hotbar slot = your pickaxe (owner F151: otherwise you hold what you picked)
			if inventory.equipped("pickaxe") != "":
				return inventory.worn_slot("pickaxe")
			var carried := inventory.best_of_kind("pickaxe")  # a pickaxe in the hotbar or bag still digs (F88)
			if carried >= 0:
				return carried
		return selected_slot

	## How much worn clothes/armor soak up: 2% per armor point, at most 60%.
	func armor_cut() -> float:
		var armor := 0.0
		for part in ["head", "chest", "legs", "feet"]:
			var worn := inventory.get_slot(Inventory.equip_index(part))
			armor += int(Items.info(inventory.equipped(part)).get("armor", 0)) * (1.0 + Upgrades.bonus(worn))
		return minf(0.6, armor * 0.02) + progress.armor_bonus()  # Stone Skin goes past the cap


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	builder = Builder.new()
	builder.name = "Builder"
	add_child(builder)
	storage = Storage.new()
	storage.name = "Storage"
	add_child(storage)
	keys = DungeonKeys.new()
	keys.name = "DungeonKeys"
	add_child(keys)
	monsters = MonsterManager.new()
	monsters.name = "Monsters"
	add_child(monsters)
	loot_props = LootProps.new()
	loot_props.name = "LootProps"
	add_child(loot_props)


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
		ps.needs_lantern = true  # wakes up with nothing: picks up the lantern lying in the room
	elif give_start_items:
		# Friends who join later (and test robots) arrive ready to dig, with a lantern built in.
		ps.inventory.add("pickaxe_stone", 1)
		ps.inventory.set_worn(ps.inventory.best_of_kind("pickaxe"), true)  # already on (F825 gold E)
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
		if ps.fuel > 0.0 and Lantern.has_lantern(ps) and not ps.lantern_stowed:  # no lantern yet / put away = nothing burning
			ps.fuel = maxf(0.0, ps.fuel - delta)
	var me := get_player(local_peer_id())
	if me:
		_tick_vitals(me, delta)
	_apply_pending_digs()
	if is_host():
		_track_safe_spots(delta)
		_tick_regrow(delta)
		world_state.played = float(world_state.get("played", 0.0)) + delta  # this world's play time (dungeon refills)
		_refill_timer -= delta
		if _refill_timer <= 0.0:
			_refill_timer = DungeonLoot.CHECK_EVERY
			DungeonLoot.tick(self)
		_auto_timer -= delta
		var feed_now := _auto_timer <= 0.0
		if feed_now:
			_auto_timer = 1.0
		for st in stations.values():
			for done in st.tick(delta):
				var left: int = done[1]
				if done[2] and storage:
					left = AutoSmelt.store(st, storage, done[0], left)  # self-running furnaces fill a chest
				if left > 0:
					spawn_drop(done[0], left, st.global_position + Vector3.UP * 1.2)
			if feed_now and storage and st.kind in AutoSmelt.KINDS:
				AutoSmelt.feed(st, storage)
			if st.tick_water(delta):
				_ev_water.rpc(st.station_id, st.water, st.under_drip)
		_banner_tick -= delta
		if _banner_tick <= 0.0 and not _banners.is_empty():
			_banner_tick = 1.0  # a short effect, renewed every second while you stand near a banner
			_banner_guard()
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
		me.hands_empty = slot == me.selected_slot and not me.hands_empty and not me.weapon_drawn  # same number again: put it away
		me.selected_slot = slot  # show it right away
	if is_host():
		request_select_slot(local_peer_id(), slot)
	else:
		_rpc_select_slot.rpc_id(1, slot)
	if me and not me.hands_empty:  # picking a pickaxe/weapon/shield you don't wear yet puts it on (F826, like Valheim)
		var id: String = me.inventory.get_slot(slot).get("id", "")
		if Inventory.equip_slot_for(id) in Inventory.HAND and not me.inventory.is_worn(slot):
			ask_equip(slot)


func ask_hit(point: Vector3, normal: Vector3) -> void:
	if is_host():
		request_hit(local_peer_id(), point, normal)
	else:
		_rpc_hit.rpc_id(1, point, normal)


## A swing at a boulder (owner, Nov 18, like Conan Exiles): stone every hit (2 with a pickaxe, 1 by hand), it bursts
## after Boulders.HITS hits and a new one stands there 20 minutes later.
func ask_hit_boulder(id: int) -> void:
	if is_host():
		request_hit_boulder(local_peer_id(), id)
	else:
		_rpc_hit_boulder.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _rpc_hit_boulder(id: int) -> void:
	if is_host():
		request_hit_boulder(multiplayer.get_remote_sender_id(), id)


func request_hit_boulder(peer_id: int, id: int) -> void:
	var ps := get_player(peer_id)
	if ps == null or boulders == null:
		return
	var r := boulders.rock(id)
	if r.is_empty() or r.broken or boulder_back.has(id):
		return
	var at: Vector3 = Boulders.middle(r)
	if _chest(ps).distance_to(at) > REACH + 1.5 * float(r.scale):
		return
	var pick := Items.kind(ps.selected_item()) == "pickaxe"
	if not pick and ps.selected_item() != "":
		_tell_feedback(peer_id, {state = "no_tool", point = at})
		return
	var n := 2 if pick else 1
	var out := (_chest(ps) - at).normalized()
	spawn_drop("stone", n, at + out * 0.6 * float(r.scale) + Vector3.UP * 0.3)
	give_xp(peer_id, 1, "mining")
	var hits: int = boulder_hits.get(id, 0) + 1
	boulder_hits[id] = hits
	if hits >= Boulders.HITS:
		boulder_hits.erase(id)
		boulder_back[id] = Boulders.RESPAWN
		_ev_boulder.rpc(id, true)
		_tell_feedback(peer_id, {state = "dug", hits = hits, needed = Boulders.HITS, material = Mat.STONE, point = at, normal = out, boulder = true})
	else:
		_tell_feedback(peer_id, {state = "hit", hits = hits, needed = Boulders.HITS, material = Mat.STONE, point = at, normal = out})


## A swing at an old ruin column (owner, Nov 19: "you should be able to destroy them just for some stone"): stone
## every hit, it crumbles after its hits (3 for a small broken one, up to 10 for a great hall's), plus a last pile.
## Gone for good (world_state.columns, saved and sent to friends who join).
var column_hits := {}  ## host: column id -> hits so far


func ask_hit_column(cid: int) -> void:
	if is_host():
		request_hit_column(local_peer_id(), cid)
	else:
		_rpc_hit_column.rpc_id(1, cid)


@rpc("any_peer", "reliable")
func _rpc_hit_column(cid: int) -> void:
	if is_host():
		request_hit_column(multiplayer.get_remote_sender_id(), cid)


func request_hit_column(peer_id: int, cid: int) -> String:
	var ps := get_player(peer_id)
	if ps == null or poi_field == null or world_state.get("columns", []).has(cid):
		return ""
	var c := poi_field.column(cid)
	if c.is_empty():
		return ""
	var at := poi_field.column_middle(cid)
	if _chest(ps).distance_to(at) > REACH + float(c.width) + 1.0:
		return "far"
	var pick := Items.kind(ps.selected_item()) == "pickaxe"
	if not pick and ps.selected_item() != "":
		_tell_feedback(peer_id, {state = "no_tool", point = at})
		return "no_tool"
	var out := (_chest(ps) - at).normalized()
	spawn_drop("stone", 2 if pick else 1, at + out * (float(c.width) * 0.6 + 0.3) + Vector3.UP * 0.3)
	give_xp(peer_id, 1, "mining")
	var hits: int = column_hits.get(cid, 0) + 1
	column_hits[cid] = hits
	if hits < int(c.hits):
		_tell_feedback(peer_id, {state = "hit", hits = hits, needed = c.hits, material = Mat.STONE, point = at, normal = out})
		return "hit"
	column_hits.erase(cid)
	spawn_drop("stone", 3, at + out * 0.8)
	var gone: Array = world_state.get("columns", []).duplicate()
	gone.append(cid)
	world_state.columns = gone
	_ev_state.rpc(world_state)
	_ev_column.rpc(cid)
	_tell_feedback(peer_id, {state = "dug", hits = hits, needed = c.hits, material = Mat.STONE, point = at, normal = out, boulder = true})
	return "broke"


## Host: a charging Rock Beetle runs into a boulder (owner F447): it bursts at once, its stone drops beside it, and
## a new one stands there later (like the last pickaxe hit). `from`: where the beetle came from.
func smash_boulder(id: int, from: Vector3) -> bool:
	if boulders == null:
		return false
	var r := boulders.rock(id)
	if r.is_empty() or r.broken or boulder_back.has(id):
		return false
	var at: Vector3 = Boulders.middle(r)
	var out := ((from - at) * Vector3(1, 0, 1)).normalized()
	var left: int = Boulders.HITS - int(boulder_hits.get(id, 0))
	boulder_hits.erase(id)
	boulder_back[id] = Boulders.RESPAWN
	# Everything mining it to the end would give (owner, Nov 20): 2 stone for each hit it still had left.
	spawn_drop("stone", left * 2, at + out * 0.6 * float(r.scale) + Vector3.UP * 0.3)
	_ev_boulder.rpc(id, true)
	return true


## Host: a charging Rock Beetle runs into an old ruin column (owner F447): it crumbles, gone for good, like the last
## pickaxe hit (its last pile of stone drops).
func smash_column(cid: int, from: Vector3) -> bool:
	if poi_field == null or world_state.get("columns", []).has(cid):
		return false
	var c := poi_field.column(cid)
	if c.is_empty():
		return false
	var at := poi_field.column_middle(cid)
	var out := ((from - at) * Vector3(1, 0, 1)).normalized()
	# Everything mining it to the end would give (owner, Nov 20): 2 stone for each hit left, plus the last pile.
	var left: int = int(c.hits) - int(column_hits.get(cid, 0))
	column_hits.erase(cid)
	spawn_drop("stone", left * 2 + 3, at + out * (float(c.width) * 0.6 + 0.3))
	var gone: Array = world_state.get("columns", []).duplicate()
	gone.append(cid)
	world_state.columns = gone
	_ev_state.rpc(world_state)
	_ev_column.rpc(cid)
	return true


@rpc("authority", "call_local", "reliable")
func _ev_column(cid: int) -> void:
	if poi_field:
		poi_field.set_column_broken(cid)


@rpc("authority", "call_local", "reliable")
func _ev_boulder(id: int, broken: bool) -> void:
	if boulders:
		boulders.set_broken(id, broken)


## Host: broken boulders come back after a while.
func _tick_boulders(delta: float) -> void:
	for id in boulder_back.keys():
		boulder_back[id] -= delta
		if boulder_back[id] <= 0.0:
			boulder_back.erase(id)
			_ev_boulder.rpc(id, false)


const TREE_MOSS_CHANCE := 0.4  ## per swing at a Root Tree: 1 Tree Moss
const HEARTWOOD_CHANCE := 0.05  ## per swing at a Root Tree: 1 Heartwood (and always 1 when it cracks)


## A swing at a giant root pillar (owner, Nov 17, F189): bits of wood, 2 with an axe, up to RootPillars.CHOPS.
func ask_chop_pillar(id: int) -> void:
	if is_host():
		request_chop_pillar(local_peer_id(), id)
	else:
		_rpc_chop_pillar.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _rpc_chop_pillar(id: int) -> void:
	if is_host():
		request_chop_pillar(multiplayer.get_remote_sender_id(), id)


## Deep Onyx in a wood axe: sometimes 1 extra wood (docs/design/gems.md). Every wood source uses it.
func onyx_wood(ps: PlayerState) -> int:
	if Items.kind(ps.selected_item()) != "axe":
		return 0
	return 1 if randf() < Gems.bonus(ps.inventory.get_slot(ps.hand_slot())).get("extra_ore", 0.0) else 0


func request_chop_pillar(peer_id: int, id: int) -> void:
	var ps := get_player(peer_id)
	if ps == null or pillars == null:
		return
	var p := pillars.pillar(id)
	if p.is_empty():
		return
	var chest := _chest(ps)
	var axis := Geometry3D.get_closest_point_to_segment(chest, p.top, p.bottom)
	if axis.distance_to(chest) > REACH + 1.5 + float(p.width) * 0.15:
		return
	var used: int = pillar_chops.get(id, 0)
	if used >= RootPillars.CHOPS:
		# No "grows back in 45 min" message (owner F552): you can see it growing back. Just a dull knock.
		_tell_feedback(peer_id, {state = "blocked", point = axis, why = "", kind = "root"})
		return
	if p.stage != "tree":
		_tell_feedback(peer_id, {state = "blocked", point = axis, why = "Still growing. Leave it be.", kind = "root"})
		return
	var n := 2 if Items.kind(ps.selected_item()) == "axe" else 1
	n = mini(n, RootPillars.CHOPS - used)
	pillar_chops[id] = used + n
	wear_slot(ps, ps.hand_slot())
	var out := Vector3(chest.x - axis.x, 0.0, chest.z - axis.z).normalized()
	var wood := n * (2 if ps.progress.has_star("woodcutting", 100) and randf() < 0.15 else 1)  # ★100: double wood
	wood += onyx_wood(ps)
	if used + n >= RootPillars.CHOPS and ps.progress.has_star("woodcutting", 50):
		wood += 1  # Woodcutting ★50: +1 wood per Root Tree
	var drop_at := axis + out * float(p.width) * 0.18 + Vector3.UP * 0.4
	spawn_drop("rootwood", wood, drop_at)
	# Its moss and its heart (owner, Nov 19, after the bosses went): Tree Moss peels off the bark, and now and then a
	# piece of Heartwood (the Copper Pickaxe needs one). A tree always gives one Heartwood when it cracks.
	if randf() < TREE_MOSS_CHANCE:
		spawn_drop("tree_moss", 1, drop_at + Vector3.UP * 0.3)
	var heart := used + n >= RootPillars.CHOPS or randf() < HEARTWOOD_CHANCE
	if heart:
		spawn_drop("heartwood", 1, drop_at + Vector3.UP * 0.5)
	give_xp(peer_id, 3 * n, "woodcutting")
	_ev_tree_used.rpc(id, used + n)
	if used + n >= RootPillars.CHOPS:  # it cracks: 1-2 Root Seeds fall from it (owner, Nov 18)
		tree_regrow[id] = RootPillars.REGROW_TIME * _root_regrow_mult(get_player(peer_id))
		spawn_drop("root_seed", randi_range(1, 2), (p.bottom as Vector3) + out * float(p.width) * 0.25 + Vector3.UP * 1.0)
	_tell_feedback(peer_id, {state = "done", kind = "root", point = axis + out * float(p.width) * 0.15})


## A swing at a glow-grove tree (owner, Nov 19): like a Root Tree, 2 wood with an axe, 1 without, until the tree's
## own amount (bushes a few, big trees more than a Root Tree) is used up; then it comes down and grows back later.
func ask_chop_grove(id: int) -> void:
	if is_host():
		request_chop_grove(local_peer_id(), id)
	else:
		_rpc_chop_grove.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _rpc_chop_grove(id: int) -> void:
	if is_host():
		request_chop_grove(multiplayer.get_remote_sender_id(), id)


func request_chop_grove(peer_id: int, id: int) -> void:
	var ps := get_player(peer_id)
	if ps == null or groves == null:
		return
	var t := groves.tree(id)
	if t.is_empty():
		return
	var chest := _chest(ps)
	var foot: Vector3 = t.pos
	var axis := Geometry3D.get_closest_point_to_segment(chest, foot, foot + Vector3.UP * 4.0 * float(t.scale))
	if axis.distance_to(chest) > REACH + 1.5:
		return
	var used: int = grove_chops.get(id, 0)
	if used >= int(t.wood):
		return  # already felled (growing back)
	var n := mini(2 if Items.kind(ps.selected_item()) == "axe" else 1, int(t.wood) - used)
	wear_slot(ps, ps.hand_slot())
	var out := Vector3(chest.x - axis.x, 0.0, chest.z - axis.z).normalized()
	var wood := n * (2 if ps.progress.has_star("woodcutting", 100) and randf() < 0.15 else 1)  # ★100: double wood
	wood += onyx_wood(ps)
	spawn_drop("rootwood", wood, axis + out * 0.4 + Vector3.UP * 0.4)
	give_xp(peer_id, 3 * n, "woodcutting")
	_ev_grove_used.rpc(id, used + n)
	if used + n >= int(t.wood):
		grove_regrow[id] = GlowGroves.REGROW_TIME
	_tell_feedback(peer_id, {state = "done", kind = "root", point = axis + out * 0.3})


@rpc("authority", "call_local", "reliable")
func _ev_grove_used(id: int, used: int, burst: bool = true) -> void:
	grove_chops[id] = used
	if groves:
		groves.set_used(id, used, burst)


@rpc("authority", "call_local", "reliable")
func _ev_grove_back(id: int) -> void:
	grove_chops.erase(id)
	if groves:
		groves.set_regrow(id, 0.0)


@rpc("authority", "call_local", "reliable")
func _ev_tree_used(id: int, used: int) -> void:
	pillar_chops[id] = used
	if pillars:
		pillars.set_used(id, used)


## Planting a Root Seed with the Mason's Shovel (owner, Nov 18): on open floor with a ceiling 5-14 m up, nothing built
## there and no other tree close. It grows by itself (planted, _tick_trees).
var planted: Array = []  ## [{id, pos, top, grow (seconds left), model, spin}] (saved)


func _plant_seed(ps: PlayerState, aim_point: Vector3, aim_normal: Vector3) -> String:
	if pillars == null or ps.inventory.count_of("root_seed") <= 0:
		return ""
	if not aim_point.is_finite() or aim_normal.normalized().y < 0.7 or _chest(ps).distance_to(aim_point) > REACH + 1.0:
		return ""
	var top := Vector3.INF
	for k in range(1, 56):  # the ceiling above (the real rock, dug holes and all)
		if world.sdf_at(aim_point + Vector3.UP * (k * 0.25 + 0.5)) < 0.0:
			top = aim_point + Vector3.UP * (k * 0.25 + 0.5)
			break
	if top == Vector3.INF or top.y - aim_point.y < 5.0 or top.y - aim_point.y > 14.0:
		_tell_feedback(_peer_of(ps), {state = "blocked", point = aim_point, why = "A Root Tree needs a ceiling 5 to 14 m above."})
		return ""
	if world.maker.is_reserved(aim_point, 3.0) or pillars.near(aim_point, 6.0):
		_tell_feedback(_peer_of(ps), {state = "blocked", point = aim_point, why = "Too close to something else."})
		return ""
	ps.inventory.remove("root_seed", 1)
	_send_inventory(_peer_of(ps))
	var e := {id = RootPillars.PLANTED_ID + planted.size(), pos = aim_point, top = top, grow = RootPillars.GROW_TIME,
		model = randi_range(0, RootPillars.MODELS.size() - 1), spin = randf() * TAU}
	planted.append(e)
	_ev_planted.rpc(e)
	return "planted"


@rpc("authority", "call_local", "reliable")
func _ev_planted(e: Dictionary) -> void:
	if pillars:
		pillars.add_planted(e)


## Host: planted trees grow (a sprout halfway, a tree at the end); everyone's screen swaps it while nobody looks.
func _tick_trees(delta: float) -> void:
	for id in grove_regrow.keys():  # felled grove trees stand again after a while
		grove_regrow[id] -= delta
		if grove_regrow[id] <= 0.0:
			grove_regrow.erase(id)
			_ev_grove_back.rpc(int(id))
	for id in tree_regrow.keys():
		var before := RootPillars.regrow_stage(tree_regrow[id])
		tree_regrow[id] = maxf(0.0, tree_regrow[id] - delta)
		var left: float = tree_regrow[id]
		if RootPillars.regrow_stage(left) != before:
			if left <= 0.0:
				tree_regrow.erase(id)
				pillar_chops.erase(id)
			_ev_regrow.rpc(int(id), left)
	for e in planted:
		if e.grow <= 0.0:
			continue
		var before := RootPillars.stage_of(e.grow)
		e.grow = maxf(0.0, e.grow - delta)
		if RootPillars.stage_of(e.grow) != before:
			_ev_grow.rpc(int(e.id), float(e.grow))


@rpc("authority", "call_local", "reliable")
func _ev_regrow(id: int, left: float) -> void:
	if left <= 0.0:
		pillar_chops.erase(id)
	if pillars:
		pillars.set_regrow(id, left)


@rpc("authority", "call_local", "reliable")
func _ev_grow(id: int, grow_left: float) -> void:
	if pillars:
		pillars.set_growth(id, grow_left)


## A swing through hanging roots (owner, Nov 17): "strand" = a root-curtain strand (its bunch breaks, gives fiber),
## "hroot" = a big root hanging from the ceiling (gives rootwood).
func ask_break_hanging(kind: String, id: String) -> void:
	if is_host():
		request_break_hanging(local_peer_id(), kind, id)
	else:
		_rpc_break_hanging.rpc_id(1, kind, id)


@rpc("any_peer", "reliable")
func _rpc_break_hanging(kind: String, id: String) -> void:
	if is_host():
		request_break_hanging(multiplayer.get_remote_sender_id(), kind, id)


func request_break_hanging(peer_id: int, kind: String, id: String) -> void:
	var ps := get_player(peer_id)
	if ps == null:
		return
	if kind == "strand" and curtains:
		var top := curtains.top_of(int(id))
		if top == Vector3.INF or Vector2(top.x - _chest(ps).x, top.z - _chest(ps).z).length() > REACH + 1.0:
			return
		var bunch := curtains.bunch_of(int(id), 0.12)  # just the strand you hit (owner, Nov 18: the whole bunch vanishing looked odd)
		for s in bunch:
			removed_strands.append(s)
		_ev_break_hanging.rpc("strand", ",".join(Array(bunch).map(func(x): return str(x))))
		spawn_drop(CaveLife.FIBER_DROP, CaveLife.FIBER_PER_VINE, _chest(ps) + Vector3.UP * 0.3)
	elif kind == "hroot" and clutter:
		var top := clutter.hroot_top(id)
		if top == Vector3.INF or Vector2(top.x - _chest(ps).x, top.z - _chest(ps).z).length() > REACH + 2.0:
			return
		removed_hroots.append(id)
		_ev_break_hanging.rpc("hroot", id)
		spawn_drop("rootwood", 2 + onyx_wood(ps), _chest(ps) + Vector3.UP * 0.3)


@rpc("authority", "call_local", "reliable")
func _ev_break_hanging(kind: String, ids: String) -> void:
	var at := Vector3.INF
	if kind == "strand" and curtains:
		at = curtains.top_of(int(ids.get_slice(",", 0)))
	elif kind == "hroot" and clutter:
		at = clutter.hroot_top(ids)
	if at != Vector3.INF:
		Sfx.play("chop" if kind == "hroot" else "pickup", at, -4.0)
	if kind == "strand" and curtains:
		var list := PackedInt32Array()
		for x in ids.split(","):
			list.append(int(x))
		curtains.hide_strands(list)
	elif kind == "hroot" and clutter:
		clutter.hide_hroot(ids)


## E on grass, a fern or a small root: break it (fiber or wood). Never digs rock (owner, Nov 17).
func ask_pick_plant(point: Vector3) -> void:
	if is_host():
		request_pick_plant(local_peer_id(), point)
	else:
		_rpc_pick_plant.rpc_id(1, point)


@rpc("any_peer", "reliable")
func _rpc_pick_plant(point: Vector3) -> void:
	if is_host():
		request_pick_plant(multiplayer.get_remote_sender_id(), point)


func request_pick_plant(peer_id: int, point: Vector3) -> Dictionary:
	var ps := get_player(peer_id)
	if ps == null:
		return {}
	var r := _break_plant_at(ps, point)
	if not r.is_empty():
		_tell_feedback(peer_id, r)
	return r


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


## Running and jumping practice (sent every few seconds by our dwarf).
func ask_body_xp(run_seconds: float, jumps: int, blocks: int = 0) -> void:
	if is_host():
		request_body_xp(local_peer_id(), run_seconds, jumps, blocks)
	else:
		_rpc_body_xp.rpc_id(1, run_seconds, jumps, blocks)


## Pressing an ability key (an active perk). `aim` = where you look (Healing Brew flies there).
func ask_ability(perk_id: String, aim := Vector3.INF) -> void:
	if is_host():
		request_ability(local_peer_id(), perk_id, aim)
	else:
		_rpc_ability.rpc_id(1, perk_id, aim)


## Dragging an ability onto Q / R / T in the perk window ("" = clear the key).
func ask_set_ability_key(slot: int, perk_id: String) -> void:
	if is_host():
		request_set_ability_key(local_peer_id(), slot, perk_id)
	else:
		_rpc_set_ability_key.rpc_id(1, slot, perk_id)


## Reset perk points for gold coins (skills window button).
func ask_respec() -> void:
	if is_host():
		request_respec(local_peer_id())
	else:
		_rpc_respec.rpc_id(1)


func ask_buy_perk(perk_id: String) -> void:
	if is_host():
		request_buy_perk(local_peer_id(), perk_id)
	else:
		_rpc_buy_perk.rpc_id(1, perk_id)


## E at a special place (a rune shrine).
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


## Gem Bench: 3 of the same gem at the same level -> 1 of the next level, for gold (docs/design/gems.md).
func ask_combine(gem: String) -> void:
	if is_host():
		request_combine(local_peer_id(), gem)
	else:
		_rpc_combine.rpc_id(1, gem)


@rpc("any_peer", "reliable")
func _rpc_combine(gem: String) -> void:
	if is_host():
		request_combine(multiplayer.get_remote_sender_id(), gem)


func request_combine(peer_id: int, gem: String) -> String:
	var ps := get_player(peer_id)
	if ps == null or not Gems.NORMAL.has(Gems.base_of(gem)):
		return "?"
	if not _near_kind(ps, "gem_bench"):
		return "Stand at a Gem Bench"
	var level := Gems.level_of(gem) + 1
	if level > Gems.MAX_LEVEL:
		return "That gem can't get any better yet"
	var gold: int = Gems.COMBINE_GOLD[level]
	if ps.inventory.count_of(Gems.item_id(gem)) < 3:
		return "Needs 3 %s" % Gems.full_name(gem)
	if ps.inventory.count_of("gold_coin") < gold:
		return "Needs %d gold" % gold
	ps.inventory.remove(Gems.item_id(gem), 3)
	ps.inventory.remove("gold_coin", gold)
	var made := Gems.item_id(Gems.with_level(Gems.base_of(gem), level))
	if ps.inventory.add(made, 1) > 0:
		spawn_drop(made, 1, ps.node.global_position + Vector3.UP)
	tell(peer_id, "You made a %s!" % Gems.full_name(Gems.gem_of(made)))
	return ""


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


## Taking a gem out gives it back intact, for 5 gold.
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
			return "Needs %d gold" % Gems.REMOVE_COST.gold_coin
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
func _ev_learned_blueprint(what: String, page_id: String, why: String) -> void:
	learned_blueprint.emit(what, page_id, why)  # a card on the left (LearnedCards)


## F636 (owner, Nov 22: "after rebuilding the tower, what's next? where do I see the blueprint I learned?"): a clear
## line for everyone the moment a ruin finishes, on top of the blueprint-learned cards that follow it.
@rpc("authority", "call_local", "reliable")
func _ev_ruin_rebuilt(name: String) -> void:
	hud_message.emit("The old %s stands again!" % name)
	music_stinger.emit(Music.ruin_stinger(name))


@rpc("authority", "call_local", "reliable")
func _ev_stinger(name: String) -> void:
	music_stinger.emit(name)
	if name == "boss_defeated":
		Sfx.ui("boss_cheer", -3.0)  # the dwarf's "Yeaah-hah-hah!" over the music (owner's pick, sound round 9, Nov 26)


@rpc("authority", "call_local", "reliable")
func _ev_learned(recipe_id: String) -> void:
	var cooks: bool = String(Recipes.get_recipe(recipe_id).get("station", "")) == "campfire"
	music_stinger.emit("recipe_cook" if cooks else "recipe")
	learned_recipe.emit(recipe_id)  # a card on the left with its picture (owner, Nov 19)


## Stamina back (Axe ★100): the player's own computer owns their body.
func give_stamina(peer_id: int, amount: float) -> void:
	if amount <= 0.0:
		return
	if peer_id == local_peer_id():
		var ps := get_player(peer_id)
		if ps:
			ps.vitals.stamina = minf(ps.vitals.max_stamina(), ps.vitals.stamina + amount)
	elif get_player(peer_id):
		_rpc_stamina.rpc_id(peer_id, amount)


@rpc("authority", "reliable")
func _rpc_stamina(amount: float) -> void:
	give_stamina(local_peer_id(), amount)


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


## Picking a crafting station back up with the build hammer (owner, Nov 15, F100): you always
## get the whole station back, as long as nothing is cooking in it.
func ask_pickup_station(station_id: int) -> void:
	if is_host():
		request_pickup_station(local_peer_id(), station_id)
	else:
		_rpc_pickup_station.rpc_id(1, station_id)


@rpc("any_peer", "reliable")
func _rpc_pickup_station(station_id: int) -> void:
	if is_host():
		request_pickup_station(multiplayer.get_remote_sender_id(), station_id)


func request_pickup_station(peer_id: int, station_id: int) -> String:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null:
		return "?"
	if ps.node.global_position.distance_to(st.global_position) > REACH + 1.0:
		return "too_far"
	if not st.jobs.is_empty():
		return "busy"
	var left := ps.inventory.add(st.kind, 1)
	if left > 0:
		spawn_drop(st.kind, left, st.global_position + Vector3.UP)
	_ev_remove_station.rpc(station_id)
	return ""


@rpc("authority", "call_local", "reliable")
func _ev_remove_station(station_id: int) -> void:
	var st: Station = stations.get(station_id)
	if st:
		Sfx.play("build", st.global_position)
		stations.erase(station_id)
		st.queue_free()
	if is_host():
		bed_gone("s%d" % station_id)


# ---------------------------------------------------------------- beds (F727, owner Nov 22: "the bed is the spawn point, one per person")
# Each bed (a Bed station "s<id>", or bed furniture "p<piece uid>") can belong to one player: their wake-up spot.
# One per person: a new bed (placed, or a plain bed you press E on) moves your wake-up spot there and your
# old bed turns into a plain bed (still good for resting, and any player can claim it with E).
# Owners are kept by player number (slot: 0 = host, 1-3 = friends), so they survive saving and rejoining.

## Bed key → owner's slot. On every computer (the "Your bed" label); only the host changes it; saved with the world.
var bed_owners := {}


## A player's number (0 = host, 1-3 = friends): the same each time they join this world.
func slot_of(peer_id: int) -> int:
	var m := get_parent()
	if m and "player_slots" in m:
		return int(m.player_slots.get(peer_id, -1))
	return 0 if peer_id == 1 else peer_id  # (tests: no main scene)


## The online player with this number, or -1.
func peer_of_slot(slot: int) -> int:
	for pid in players:
		if slot_of(pid) == slot:
			return pid
	return -1


static func slot_name(slot: int) -> String:
	return "Host" if slot == 0 else "Friend %d" % slot


## Where you wake up in this bed (INF = there's no such bed).
func bed_wake_spot(key: String) -> Vector3:
	var id := int(key.substr(1))
	if key.begins_with("s") and stations.has(id):
		return stations[id].global_position + Vector3.UP * 0.5
	if key.begins_with("p") and builder and builder.structure.pieces.has(id):
		return builder.structure.pieces[id].pos + Vector3.UP * 0.9
	return Vector3.INF


## What the look-at line says about this bed, on this computer.
func bed_label(key: String, bed_name: String) -> String:
	var owner_slot: int = bed_owners.get(key, -1)
	if owner_slot < 0:
		return "%s · E to make it your bed (you wake up here)" % bed_name
	if owner_slot == slot_of(local_peer_id()):
		return "Your bed"
	return "%s's bed" % slot_name(owner_slot)


## Host: bed `key` becomes `peer_id`'s bed and wake-up spot; their old bed turns plain.
func set_bed(peer_id: int, key: String) -> void:
	var ps := get_player(peer_id)
	var at := bed_wake_spot(key)
	if ps == null or not at.is_finite():
		return
	var slot := slot_of(peer_id)
	for k in bed_owners.keys():
		if bed_owners[k] == slot and k != key:
			_ev_bed_owner.rpc(k, -1)
	_ev_bed_owner.rpc(key, slot)
	ps.bed_pos = at


func ask_claim_bed(key: String) -> void:
	if is_host():
		request_claim_bed(local_peer_id(), key)
	else:
		_rpc_claim_bed.rpc_id(1, key)


@rpc("any_peer", "reliable")
func _rpc_claim_bed(key: String) -> void:
	if is_host():
		request_claim_bed(multiplayer.get_remote_sender_id(), key)


## Host: E on a bed. Returns "" when it's yours now, or why not (also told to the player).
func request_claim_bed(peer_id: int, key: String) -> String:
	var ps := get_player(peer_id)
	var at := bed_wake_spot(key)
	if ps == null or not at.is_finite():
		return "?"
	if ps.node.global_position.distance_to(at) > REACH + 2.0:
		return "too_far"
	var owner_slot: int = bed_owners.get(key, -1)
	var why := ""
	if owner_slot == slot_of(peer_id):
		why = "This is already your bed. You wake up here."
	elif owner_slot >= 0:
		why = "That's %s's bed. Place your own (or pick a free one)." % slot_name(owner_slot)
	if why != "":
		tell(peer_id, why)
		return why
	set_bed(peer_id, key)
	tell(peer_id, "This is your bed now. You wake up here.")
	return ""


## Host: bed `key` was taken down or destroyed. Its owner wakes up at the world start again until they get a new bed.
func bed_gone(key: String) -> void:
	if not bed_owners.has(key):
		return
	var slot: int = bed_owners[key]
	_ev_bed_owner.rpc(key, -1)
	var pid := peer_of_slot(slot)
	if pid >= 0:
		get_player(pid).bed_pos = Vector3.INF
		tell(pid, "Your bed is gone! You'll wake up at the world start until you place a new bed.")
	else:  # an offline friend: fix the dwarf kept for when they come back
		var loaded = get_parent().get("_loaded") if get_parent() else null
		if loaded is Dictionary and loaded.get("players", {}).has(slot):
			loaded.players[slot].bed = Vector3.INF


@rpc("authority", "call_local", "reliable")
func _ev_bed_owner(key: String, slot: int) -> void:
	if slot < 0:
		bed_owners.erase(key)
	else:
		bed_owners[key] = slot


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


## Gear upgrades (building polish spec §4): improve the item in `slot` at a station.
func ask_upgrade(slot: int, station_id: int) -> void:
	if is_host():
		request_upgrade(local_peer_id(), slot, station_id)
	else:
		_rpc_upgrade.rpc_id(1, slot, station_id)


@rpc("any_peer", "reliable")
func _rpc_upgrade(slot: int, station_id: int) -> void:
	if is_host():
		request_upgrade(multiplayer.get_remote_sender_id(), slot, station_id)


## Returns "" when done, otherwise why not.
func request_upgrade(peer_id: int, slot: int, station_id: int) -> String:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null:
		return "?"
	var s := ps.inventory.get_slot(slot)
	if s.is_empty() or not Upgrades.can_upgrade(s.id):
		return "That can't be upgraded."
	if st.kind != Upgrades.station_for(s.id):
		return "Upgrade this at a %s." % Items.display_name(Upgrades.station_for(s.id))
	if ps.node.global_position.distance_to(st.global_position) > 6.0:
		return "Too far from the %s." % Items.display_name(st.kind)
	var cost := Upgrades.next_cost(s, 0.10 if ps.progress.has_star("crafting", 25) else 0.0)  # Crafting ★25
	if cost.is_empty():
		return "Already +3."
	if st.level() < Upgrades.needed_level(s):
		return "Needs %s level %d." % [Items.display_name(st.kind), Upgrades.needed_level(s)]
	for item in cost:
		if ps.inventory.count_of(item) < cost[item]:
			return "Needs %d %s." % [cost[item], Items.display_name(item)]
	for item in cost:
		ps.inventory.remove(item, cost[item])
	s["up"] = Upgrades.level(s) + 1
	ps.inventory.changed.emit()
	give_xp(peer_id, 5, "crafting")
	if peer_id == local_peer_id():
		Sfx.ui("craft", 0.0)
		hud_message.emit("%s!" % Upgrades.display_name(s))
	return ""


func ask_repair(slot: int, station_id: int) -> void:
	if is_host():
		request_repair(local_peer_id(), slot, station_id)
	else:
		_rpc_repair.rpc_id(1, slot, station_id)


@rpc("any_peer", "reliable")
func _rpc_repair(slot: int, station_id: int) -> void:
	if is_host():
		request_repair(multiplayer.get_remote_sender_id(), slot, station_id)


## Returns "" when done, otherwise why not. Repairing is free (owner F568: "like Valheim").
func request_repair(peer_id: int, slot: int, station_id: int) -> String:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null:
		return "?"
	var s := ps.inventory.get_slot(slot)
	if s.is_empty() or not Durability.wears(s.id):
		return "That doesn't wear out."
	if st.kind != Upgrades.station_for(s.id):
		return "Repair this at a %s." % Items.display_name(Upgrades.station_for(s.id))
	if ps.node.global_position.distance_to(st.global_position) > 6.0:
		return "Too far from the %s." % Items.display_name(st.kind)
	if not Durability.needs_repair(s):
		return "It's like new."
	s["used"] = 0
	ps.inventory.changed.emit()
	give_xp(peer_id, 2, "crafting")
	if peer_id == local_peer_id():
		Sfx.ui("craft", 0.0)
		hud_message.emit("%s repaired." % Upgrades.display_name(s))
	return ""


func ask_repair_all(station_id: int) -> void:
	if is_host():
		request_repair_all(local_peer_id(), station_id)
	else:
		_rpc_repair_all.rpc_id(1, station_id)


@rpc("any_peer", "reliable")
func _rpc_repair_all(station_id: int) -> void:
	if is_host():
		request_repair_all(multiplayer.get_remote_sender_id(), station_id)


## "Repair all" at a station (F568): every worn thing you carry or wear that this station fixes. Returns how many.
func request_repair_all(peer_id: int, station_id: int) -> int:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null or ps.node.global_position.distance_to(st.global_position) > 6.0:
		return 0
	var n := 0
	for s in ps.inventory.slots:
		if Durability.needs_repair(s) and Upgrades.station_for(s.id) == st.kind:
			s["used"] = 0
			n += 1
	if n == 0:
		return 0
	ps.inventory.changed.emit()
	give_xp(peer_id, 2 * n, "crafting")
	if peer_id == local_peer_id():
		Sfx.ui("craft", 0.0)
		hud_message.emit("Repaired %d item%s: like new." % [n, "" if n == 1 else "s"])
	return n


## Thrifty (F568: repairs are free now, so it makes gear last longer): each rank skips 1 wear in 10.
## Counted, not rolled, so a rank-3 tool lasts exactly 1/0.7 as long.
static func thrifty_skips(ps: PlayerState) -> bool:
	var rank := ps.progress.perk_rank("thrifty")
	if rank <= 0:
		return false
	ps.thrifty_saved += 0.1 * rank
	if ps.thrifty_saved >= 1.0:
		ps.thrifty_saved -= 1.0
		return true
	return false


## Host: one use of the item in slot `i` (a dig, a chop, a hit, a block). Tells the player at 10% left and when it
## breaks. The bag is sent to the player only every 10 uses (and at those moments), not on every swing.
func wear_slot(ps: PlayerState, i: int) -> void:
	var s := ps.inventory.get_slot(i)
	if Durability.wears(s.get("id", "")) and thrifty_skips(ps):
		return
	var what := Durability.wear(s)
	var peer := _peer_of(ps)
	if what == "broke":
		tell(peer, "Your %s broke! Repair it at a %s (free)." % [Upgrades.display_name(s), Items.display_name(Upgrades.station_for(s.id))])
	elif what == "warn":
		tell(peer, "Your %s is almost worn out." % Upgrades.display_name(s))
	if what != "" or (Durability.wears(s.get("id", "")) and Durability.used(s) % 10 == 0):
		ps.inventory.changed.emit()


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
func _rpc_body_xp(run_seconds: float, jumps: int, blocks: int) -> void:
	if is_host():
		request_body_xp(multiplayer.get_remote_sender_id(), run_seconds, jumps, blocks)


@rpc("any_peer", "reliable")
func _rpc_ability(perk_id: String, aim: Vector3) -> void:
	if is_host():
		request_ability(multiplayer.get_remote_sender_id(), perk_id, aim)


@rpc("any_peer", "reliable")
func _rpc_set_ability_key(slot: int, perk_id: String) -> void:
	if is_host():
		request_set_ability_key(multiplayer.get_remote_sender_id(), slot, perk_id)


@rpc("any_peer", "reliable")
func _rpc_respec() -> void:
	if is_host():
		request_respec(multiplayer.get_remote_sender_id())


@rpc("any_peer", "reliable")
func _rpc_low_health(low: bool) -> void:
	var ps := get_player(multiplayer.get_remote_sender_id()) if is_host() else null
	if ps:
		ps.low_health = low


## A line on one player's screen.
func tell(peer_id: int, text: String) -> void:
	if peer_id == local_peer_id():
		hud_message.emit(text)
	elif get_player(peer_id):
		_rpc_tell.rpc_id(peer_id, text)


@rpc("authority", "reliable")
func _rpc_tell(text: String) -> void:
	hud_message.emit(text)


## Our own item cooldowns (item id -> when it's ready, on our clock). Only looks: the host still checks every use.
var my_cooldowns := {}


## Host: tell one player an item of theirs is cooling down for `seconds` (owner F470: a grey shade on its slot).
func send_cooldown(peer_id: int, item_id: String, seconds: float) -> void:
	if peer_id == local_peer_id():
		_cooldown_started(item_id, seconds)
	elif get_player(peer_id):
		_rpc_cooldown.rpc_id(peer_id, item_id, seconds)


@rpc("authority", "reliable")
func _rpc_cooldown(item_id: String, seconds: float) -> void:
	_cooldown_started(item_id, seconds)


func _cooldown_started(item_id: String, seconds: float) -> void:
	my_cooldowns[item_id] = {start = now(), until = now() + seconds}


## How much of an item's cooldown is still left for us: 1 = just used, 0 = ready.
func cooldown_left(item_id: String) -> float:
	var c: Dictionary = my_cooldowns.get(item_id, {})
	if c.is_empty() or c.until <= now():
		my_cooldowns.erase(item_id)  # (an old one is forgotten, so the HUD stops checking every frame)
		return 0.0
	return clampf((c.until - now()) / maxf(c.until - c.start, 0.01), 0.0, 1.0)


## A timed perk effect on one player's body (their own computer owns it).
func send_effect(peer_id: int, effect: String, data: Dictionary, seconds: float) -> void:
	var ps := get_player(peer_id)
	if ps == null:
		return
	if peer_id == local_peer_id():
		ps.vitals.add_effect(effect, data, seconds)
	else:
		_rpc_effect.rpc_id(peer_id, effect, data, seconds)


@rpc("authority", "reliable")
func _rpc_effect(effect: String, data: Dictionary, seconds: float) -> void:
	send_effect(local_peer_id(), effect, data, seconds)


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
		if peer_id != local_peer_id():  # (the host's own choice was already made in ask_select_slot)
			ps.hands_empty = slot == ps.selected_slot and not ps.hands_empty and not ps.weapon_drawn
		ps.selected_slot = slot
		ps.weapon_drawn = false  # picking a hotbar slot puts the weapon away


## L: put the lantern away (dark, no fuel used) or take it out again (owner, Nov 17).
func ask_stow_lantern(stowed: bool) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.lantern_stowed = stowed  # show it right away
	if is_host():
		request_stow_lantern(local_peer_id(), stowed)
	else:
		_rpc_stow_lantern.rpc_id(1, stowed)


@rpc("any_peer", "reliable")
func _rpc_stow_lantern(stowed: bool) -> void:
	if is_host():
		request_stow_lantern(multiplayer.get_remote_sender_id(), stowed)


func request_stow_lantern(peer_id: int, stowed: bool) -> void:
	var ps := get_player(peer_id)
	if ps:
		ps.lantern_stowed = stowed


## F: draw or put away the equipped weapon (feedback F23).
func ask_draw_weapon(on: bool) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.weapon_drawn = on and me.can_draw()  # show it right away
	if is_host():
		request_draw_weapon(local_peer_id(), on)
	else:
		_rpc_draw_weapon.rpc_id(1, on)


@rpc("any_peer", "reliable")
func _rpc_draw_weapon(on: bool) -> void:
	if is_host():
		request_draw_weapon(multiplayer.get_remote_sender_id(), on)


func request_draw_weapon(peer_id: int, on: bool) -> void:
	var ps := get_player(peer_id)
	if ps:
		ps.weapon_drawn = on and ps.can_draw()


# ---------------------------------------------------------------- putting things on (F826, owner Nov 23, like Valheim)
# Right-click armour, a weapon, a shield, a tool: a ring fills (EquipTime.seconds_for) while you walk very slowly;
# a hit stops it. The ring runs on the player's own computer (that's where hits land, Vitals.damaged); when it's
# full the host is asked and does the change, and the new inventory goes back to the player. Taking armour off takes a ring too (F828); several fill together.

## Right-click in the bag (or a hotbar pick): start putting slot `index` on or taking it off. Armour takes a ring
## both ways (F828); weapons, tools and shields come off at once. Several rings fill at the same time.
func ask_equip(index: int) -> void:
	var me := get_player(local_peer_id())
	if me == null:
		return
	var s := me.inventory.get_slot(index)
	if s.is_empty():
		return
	var id := str(s.id)
	var secs := EquipTime.seconds_off(id) if me.inventory.is_worn(index) else EquipTime.seconds_for(id)
	if secs <= 0.0:
		_send_equip(index, id)
		return
	_queue_equip(me, {index = index, id = id, left = secs, total = secs})


## Dragging into or out of a gear slot (F828: it used to skip the ring). Swaps a and b once the ring is full.
func ask_equip_move(a: int, b: int) -> void:
	var me := get_player(local_peer_id())
	if me == null:
		return
	var id_a := str(me.inventory.get_slot(a).get("id", ""))
	var id_b := str(me.inventory.get_slot(b).get("id", ""))
	var gear := b if Inventory.is_equip_index(b) else a
	var going_on := id_a if gear == b else id_b
	var coming_off := id_b if gear == b else id_a
	var secs := maxf(EquipTime.seconds_for(going_on) if going_on != "" else 0.0,
			EquipTime.seconds_off(coming_off) if coming_off != "" else 0.0)
	if secs <= 0.0:
		ask_swap(a, b)
		return
	_queue_equip(me, {index = a, id = id_a, to = b, to_id = id_b, ring = gear, left = secs, total = secs})


func _queue_equip(me: PlayerState, job: Dictionary) -> void:
	for j in [me.equip_job] + me.equip_queue:
		if not j.is_empty() and j.index == job.index and j.get("to", -1) == job.get("to", -1):
			return  # already on its way
	if me.equip_job.is_empty():
		me.equip_job = job
	else:
		me.equip_queue.append(job)


## Is the job's item (and, for a drag, the other slot's) still where it was?
static func _job_valid(me: PlayerState, job: Dictionary) -> bool:
	if str(me.inventory.get_slot(job.index).get("id", "")) != job.id:
		return false
	return not job.has("to") or str(me.inventory.get_slot(job.to).get("id", "")) == job.to_id


## The player's own computer, every frame: fill every ring at once (owner F828: helm, chest, legs, boots all start as
## soon as you click them); each full one asks the host.
func tick_equip(delta: float) -> void:
	var me := get_player(local_peer_id())
	if me == null or me.equip_job.is_empty():
		return
	var keep := []
	var done := []
	for job in [me.equip_job] + me.equip_queue:
		if not _job_valid(me, job):
			continue  # it was moved or thrown away
		job.left -= delta
		(done if job.left <= 0.0 else keep).append(job)
	me.equip_job = keep[0] if not keep.is_empty() else {}
	me.equip_queue = keep.slice(1)
	for job in done:
		if job.has("to"):
			ask_swap(job.index, job.to)
		else:
			_send_equip(job.index, job.id)


## A hit (or anything else) stops it and everything waiting; nothing changes.
func cancel_equip() -> void:
	var me := get_player(local_peer_id())
	if me:
		me.equip_job = {}
		me.equip_queue.clear()


func _send_equip(index: int, id: String) -> void:
	if is_host():
		request_equip(local_peer_id(), index, id)
	else:
		_rpc_equip.rpc_id(1, index, id)


@rpc("any_peer", "reliable")
func _rpc_equip(index: int, id: String) -> void:
	if is_host():
		request_equip(multiplayer.get_remote_sender_id(), index, id)


## Host: put on / take off what's in `index`, if it's still the item the player meant. Returns "" or why not.
func request_equip(peer_id: int, index: int, id: String) -> String:
	var ps := get_player(peer_id)
	if ps == null:
		return "?"
	if ps.inventory.get_slot(index).get("id", "") != id:
		return "moved"
	var why := ps.inventory.equip_problem(index)
	if why == "" and not ps.inventory.toggle_equip(index):
		why = "?"
	if why != "" and peer_id == local_peer_id():
		hud_message.emit(why)
	return why


## Q over a bag slot (owner F825): throw the whole slot on the floor in front of you.
func ask_throw(index: int) -> void:
	if is_host():
		request_throw(local_peer_id(), index)
	else:
		_rpc_throw.rpc_id(1, index)


@rpc("any_peer", "reliable")
func _rpc_throw(index: int) -> void:
	if is_host():
		request_throw(multiplayer.get_remote_sender_id(), index)


## Host: empty the slot into a drop. Items with their own data (wear, upgrades, gems) keep it when picked up.
func request_throw(peer_id: int, index: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null or ps.node == null:
		return false
	var s := ps.inventory.take_slot(index)
	if s.is_empty():
		return false
	var fwd := -ps.node.global_transform.basis.z * Vector3(1, 0, 1)
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var id := _next_drop_id
	_next_drop_id += 1
	if s.size() > 2:
		_drop_extra[id] = s
	_ev_spawn_drop.rpc(id, str(s.id), int(s.count), _chest(ps) + fwd * 0.6, fwd * 2.5 + Vector3.UP * 2.0, true)
	return true


## Moving items around in your own bag.
func request_swap(peer_id: int, a: int, b: int) -> void:
	var ps := get_player(peer_id)
	if ps:
		ps.inventory.swap(a, b)


## Right-click in the bag: split a stack in half (F187). Shift+Click: quick move hotbar <-> bag (F187).
func ask_split(slot: int) -> void:
	if is_host():
		request_split(local_peer_id(), slot)
	else:
		_rpc_split.rpc_id(1, slot)


func ask_quick_move(slot: int) -> void:
	if is_host():
		request_quick_move(local_peer_id(), slot)
	else:
		_rpc_quick_move.rpc_id(1, slot)


@rpc("any_peer", "reliable")
func _rpc_split(slot: int) -> void:
	if is_host():
		request_split(multiplayer.get_remote_sender_id(), slot)


@rpc("any_peer", "reliable")
func _rpc_quick_move(slot: int) -> void:
	if is_host():
		request_quick_move(multiplayer.get_remote_sender_id(), slot)


func request_split(peer_id: int, slot: int) -> void:
	var ps := get_player(peer_id)
	if ps:
		ps.inventory.split(slot)


func request_quick_move(peer_id: int, slot: int) -> void:
	var ps := get_player(peer_id)
	if ps:
		ps.inventory.quick_move(slot)


## A pickaxe swing landed on rock at `point` (surface) facing `normal`.
## Result: {state = "hit"|"dug"|"blocked"|"no_tool"|"too_far"|"air", hits, needed, material}
func request_hit(peer_id: int, point: Vector3, normal: Vector3) -> Dictionary:
	var ps := get_player(peer_id)
	if ps == null:
		return {}
	var result := _judge_hit(ps, point, normal)
	_tell_feedback(peer_id, result)
	return result


## Copper is too hard for plain stone (F115): you need a Fang Pickaxe (Workbench level 2) or better.
## Returns why not ("" = this pickaxe can mine it). `tool` "" = bare hands.
static func ore_too_hard(mat: int, tool: String) -> String:
	if mat == Mat.TIN:  # F697: tin comes after copper
		return "" if Items.tier(tool) >= 1 else "Tin is too hard for this pickaxe. Make a Copper Pickaxe at the Anvil."
	if mat != Mat.COPPER or Items.tier(tool) >= 1 or Items.info(tool).get("copper", false):
		return ""
	return "Copper is too hard for stone. Make a Fang Pickaxe (Workbench level 2: 4 bat fangs, 1 leather)."


## A grass tuft, fern or small root at `point` breaks: fiber, or wood from a small root, which grows back. {} if none.
func _break_plant_at(ps: PlayerState, point: Vector3) -> Dictionary:
	if cave_life and _chest(ps).distance_to(point) <= REACH + 1.0:
		var plant := cave_life.breakable_at(point)
		if plant >= 0:
			var at := cave_life.position_of(plant)
			var is_root := cave_life.kind_of(plant).begins_with("rootlet")
			removed_plants.append(plant)
			_ev_break_plant.rpc(plant)
			# small roots give wood and grow back (owner, Nov 17: "I'm missing a ton of wood"); grass and ferns: fiber
			spawn_drop("rootwood" if is_root else CaveLife.FIBER_DROP, 1 + onyx_wood(ps) if is_root else CaveLife.FIBER_PER_PLANT, at + Vector3.UP * 0.3)
			if is_root:
				plant_regrow[plant] = REGROW_TIME * _root_regrow_mult(ps)
			return {state = "done", hits = 1, needed = 1, point = at, kind = "rootwood" if is_root else "fiber"}
	return {}


func _judge_hit(ps: PlayerState, point: Vector3, normal: Vector3) -> Dictionary:
	# A grass tuft, fern or small root where the swing landed breaks first (owner F197: people will hit them by
	# accident). Any swing does it, even bare hands; the rock under it is dug by the next swing.
	var plant_hit := _break_plant_at(ps, point)
	if not plant_hit.is_empty():
		return plant_hit
	if Items.kind(ps.selected_item()) == "shovel":
		return _judge_level(ps, point)
	var power: float = Items.dig_power(ps.selected_item()) * ps.progress.dig_power_mult() * (1.0 + boost_total(ps, "dig_power")) \
		* (1.0 + Gems.bonus(ps.inventory.get_slot(ps.hand_slot())).get("dig", 0.0)) 		* (1.0 + Upgrades.bonus(ps.inventory.get_slot(ps.hand_slot())))  # +15% per upgrade step
	if ps.progress.has_star("mining", 100) and randf() < 0.1:
		power *= 2.0  # Mining ★100: lucky hit
	var bare := false
	if power <= 0:
		# No pickaxe at all: dig with bare hands, three times slower, so you can never get stuck
		# without stone (owner, Nov 15, F89). Holding another tool or weapon still says "no tool".
		if ps.selected_item() != "":
			return {state = "no_tool"}  # holding something else (stones, a sword...): pick your pickaxe to dig
		power = Items.dig_power("pickaxe_stone") * HAND_DIG
		bare = true
	if _chest(ps).distance_to(point) > REACH + 1.0:
		return {state = "too_far"}
	if normal.length_squared() < 0.25:
		return {state = "air"}
	normal = normal.normalized()  # a stretched normal would dig far past the reach check
	var center := point - normal * 0.55
	if monsters and monsters.standing_over(center):
		return {state = "blocked", point = point, why = "Something is standing on that rock."}  # no pit traps (F125)
	var mat := world.rock_material_near(point - normal * 0.3, 1.1)
	if mat < 0:
		return {state = "air"}
	var tool_tier := 0 if bare else Items.tier(ps.selected_item())
	var too_hard := ore_too_hard(mat, "" if bare else ps.selected_item())
	if too_hard != "":
		return {state = "blocked", material = mat, point = point, why = too_hard}
	if Mat.is_ore(mat):
		power *= ps.progress.ore_power_mult()  # Ore Smasher
	var needed := Mat.hits_needed(mat, power, tool_tier)
	if needed == 0:
		return {state = "blocked", material = mat, point = point}
	if ps.dig_target.distance_to(center) > 1.0:
		ps.dig_target = center
		ps.dig_hits = 0
	ps.dig_hits += 1
	if not bare:
		wear_slot(ps, ps.hand_slot())  # the pickaxe wears a little with every hit
	if ps.dig_hits < needed:
		_pay_hit(ps, mat, point + normal * 0.4)
		return {state = "hit", hits = ps.dig_hits, needed = needed, material = mat, point = point, normal = normal}
	ps.dig_hits = 0
	ps.dig_target = Vector3.INF
	var counts := _host_dig(center, tool_tier)
	_dig_ramp(ps, center, tool_tier, counts)
	_give_dig_drops(ps, counts, center + normal * 0.8)
	give_xp(_peer_of(ps), Mat.DIG_XP.get(mat, 1), "mining")
	return {state = "dug", hits = needed, needed = needed, material = mat, point = point, normal = normal}


const LEVEL_R := 1.0  ## the Mason's Shovel flattens a patch this far around where you aim (about 2 m across)
const LEVEL_HEAD := 1.9  ## and clears rock up to this high above your feet
const FILL_R := 1.0  ## (the rock is stored in 1 m steps: smaller balls hardly change it)
const RAISE_COST := 3  ## stone per block the shovel's right click raises (owner, Nov 25)


## The Mason's Shovel (owner, Nov 17: "leveling the ground"): one swing flattens the patch where you aim to the height
## of your feet: bumps up to head height are shaved off (what it removes drops, like digging) and small dips are
## filled with 1 dirt or stone from your bag (dirt first). Same rules as digging: too-hard rock stays.
func _judge_level(ps: PlayerState, point: Vector3) -> Dictionary:
	var feet: Vector3 = ps.node.global_position
	if _chest(ps).distance_to(point) > REACH + 1.0:
		return {state = "too_far"}
	var c := Vector3(point.x, feet.y, point.z)
	if Vector2(c.x - feet.x, c.z - feet.z).length() > 3.2:
		return {state = "too_far"}
	if monsters and monsters.standing_over(c):
		return {state = "blocked", point = point, why = "Something is in the way."}
	var counts := {}
	var spots: Array[Vector3] = []
	for ix in range(-1, 2):
		for iz in range(-1, 2):
			spots.append(c + Vector3(ix, 0.0, iz) * LEVEL_R * 0.6)
	# shave: balls resting on the floor line, up to LEVEL_HEAD
	var r := LEVEL_HEAD * 0.5
	for s in spots:
		var more := _host_dig(s + Vector3.UP * (r + 0.02), Items.tier("pickaxe_stone"), r)
		for m in more:
			counts[m] = counts.get(m, 0) + more[m]
	# fill: balls hanging just under the floor line, only if there's dirt or stone to fill with
	var mat := Mat.DIRT if ps.inventory.count_of("dirt") > 0 else (Mat.STONE if ps.inventory.count_of("stone") > 0 else -1)
	var filled := 0
	if mat >= 0:
		for s in spots:
			var f := s - Vector3.UP * (FILL_R + 0.02)
			if world.sdf_at(f + Vector3.UP * (FILL_R * 0.5)) <= 0.0:
				continue  # already solid there
			var n := world.apply_fill(f, FILL_R, mat)
			if n > 0:
				filled += n
				var edit := Vector4(f.x, f.y, f.z, pack_fill(mat, FILL_R))
				edit_log.append(edit)
				_ev_dig.rpc(edit)
		if filled > 0:
			ps.inventory.remove("dirt" if mat == Mat.DIRT else "stone", 1)
			_send_inventory(_peer_of(ps))
	if counts.is_empty() and filled == 0:
		return {state = "air", point = point}
	_give_dig_drops(ps, counts, c + Vector3.UP * 0.8)
	give_xp(_peer_of(ps), 1, "mining")
	return {state = "dug", hits = 1, needed = 1, material = Mat.STONE, point = point, levelled = true}


## The Mason's Shovel's right click (F890, owner Nov 25: "left click to flatten, right click to raise, 3 stone per
## block"): one block of stone piles up on the floor where you aim (about 1 m high in the middle), for RAISE_COST
## stone. Never on top of anyone (a dwarf or a creature standing there).
func _raise_ground(ps: PlayerState, aim_point: Vector3, aim_normal: Vector3) -> String:
	if not aim_point.is_finite() or not aim_normal.is_finite() or aim_normal.normalized().y < 0.5:
		return ""
	if _chest(ps).distance_to(aim_point) > REACH + 1.0:
		_tell_feedback(_peer_of(ps), {state = "too_far", point = aim_point})
		return ""
	if ps.inventory.count_of("stone") < RAISE_COST:
		_tell_feedback(_peer_of(ps), {state = "blocked", point = aim_point, why = "Needs %d stone to raise the ground." % RAISE_COST})
		return ""
	var blocked := monsters != null and monsters.standing_over(aim_point)
	for other: PlayerState in players.values():
		var at: Vector3 = other.node.global_position
		if Vector2(at.x - aim_point.x, at.z - aim_point.z).length() < FILL_R + 0.5 and absf(at.y - aim_point.y) < 2.0:
			blocked = true
	if blocked:
		_tell_feedback(_peer_of(ps), {state = "blocked", point = aim_point, why = "Someone is standing there."})
		return ""
	var n := world.apply_fill(aim_point, FILL_R, Mat.STONE)
	if n <= 0:
		return ""
	var edit := Vector4(aim_point.x, aim_point.y, aim_point.z, pack_fill(Mat.STONE, FILL_R))
	edit_log.append(edit)
	_ev_dig.rpc(edit)
	ps.inventory.remove("stone", RAISE_COST)
	_send_inventory(_peer_of(ps))
	give_xp(_peer_of(ps), 1, "mining")
	return "raised"


## Host: fill a ball of rock with `mat` on every computer (levelling: F159). Returns the voxels filled here.
func host_fill(center: Vector3, radius: float, mat: int) -> int:
	var n := world.apply_fill(center, radius, mat)
	if n > 0:
		var edit := Vector4(center.x, center.y, center.z, pack_fill(mat, radius))
		edit_log.append(edit)
		_ev_dig.rpc(edit)
		if builder:
			builder.reanchor_near(center, radius)
	return n


const RAMP_R := 1.05  ## the size of the scoops that clear a natural ramp (a dwarf fits under them)
const RAMP_STEEPEST := 0.9  ## steeper than this (rise per metre, ~42 degrees) = digging up at the ceiling: no ramp


## Natural ramps (owner, Nov 17: "dig the tunnels up without making too big of a ledge... somehow natural"): when the
## scoop you just dug is up and in front of you (its floor 0.35 m or more above your feet, not too steep), a few
## smaller scoops also clear the rock between your feet and it, so its floor becomes a slope you can walk up. They
## follow the same rules as any dig (too-hard rock stays, what they remove drops). Digging ahead, down or straight up
## is unchanged.
func _dig_ramp(ps: PlayerState, center: Vector3, tool_tier: int, counts: Dictionary) -> void:
	if ps.node == null:
		return
	var feet: Vector3 = ps.node.global_position
	var bottom := Vector3(center.x, center.y - DIG_RADIUS, center.z)  # the new scoop's floor
	var run := Vector2(bottom.x - feet.x, bottom.z - feet.z).length()
	var rise := bottom.y - feet.y
	if rise < 0.25 or run < 0.8 or rise > run * RAMP_STEEPEST:
		return
	var dir := Vector3(bottom.x - feet.x, 0.0, bottom.z - feet.z) / run
	var a := feet + dir * 0.3
	var n := ceili(a.distance_to(bottom) / 0.5)
	for i in range(1, n):
		var f := a.lerp(bottom, float(i) / n) + Vector3.UP * (RAMP_R + 0.02)
		if monsters and monsters.standing_over(f):
			continue
		var more := _host_dig(f, tool_tier, RAMP_R)
		for m in more:
			counts[m] = counts.get(m, 0) + more[m]
	# And a little past the hole, the same slope on (owner: "nearly at the end I still need to jump"): the lip where the
	# ramp met the floor above was the last step.
	var past := bottom + dir * 0.8 + Vector3.UP * (rise / run * 0.8 + RAMP_R + 0.02)
	if not (monsters and monsters.standing_over(past)):
		var extra := _host_dig(past, tool_tier, RAMP_R)
		for m in extra:
			counts[m] = counts.get(m, 0) + extra[m]


## Wood (roots, giant mushrooms): an axe is clearly the tool for it (owner, Nov 17: "axes aren't better at cutting
## wood"). A stone axe chops a root in 2 hits, a stone pickaxe needs about 5 (owner F550: half of the old 10).
const AXE_ON_WOOD := 1.5
const PICK_ON_WOOD := 0.6


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
			power = Items.dig_power(tool) * ps.progress.dig_power_mult() * (PICK_ON_WOOD if k.tool == "axe" else 1.0) 				* (1.0 + Upgrades.bonus(ps.inventory.get_slot(ps.hand_slot())))
		elif Items.kind(tool) == "axe" and k.tool == "axe":
			power = Items.info(tool).power * AXE_ON_WOOD * ps.progress.chop_power_mult() 				* (1.0 + Upgrades.bonus(ps.inventory.get_slot(ps.hand_slot()))) 				* (1.0 + Gems.bonus(ps.inventory.get_slot(ps.hand_slot())).get("dig", 0.0))  # Deep Onyx in a wood axe
		if power <= 0.0:
			var r := {state = "no_tool", point = spot.pos}
			_tell_feedback(peer_id, r)
			return r
		needed = ceili(k.hardness / power - 0.0001)
		wear_slot(ps, ps.hand_slot())
	if ps.harvest_id != glow_id:
		ps.harvest_id = glow_id
		ps.harvest_hits = 0
	ps.harvest_hits += 1
	if ps.harvest_hits < needed:
		var r := {state = "hit", hits = ps.harvest_hits, needed = needed, point = spot.pos, kind = spot.kind}  # kind: wood sounds like wood (F558)
		_tell_feedback(peer_id, r)
		return r
	ps.harvest_hits = 0
	ps.harvest_id = -1
	var count := randi_range(k.count[0], k.count[1])
	if GlowPlacer.is_plant(spot.kind) and ps.progress.perk_rank("forager") > 0:
		count += 1
	if k.tool == "hand" and randf() < ps.progress.gather_extra_chance():
		count += 1  # Gathering skill
	elif k.tool == "axe" and ps.progress.has_star("woodcutting", 100) and randf() < 0.15:
		count *= 2  # Woodcutting ★100: double wood
	if k.tool == "axe":
		count += onyx_wood(ps)
	spawn_drop(k.item, count, spot.pos + spot.normal * 0.6)
	if k.has("extra"):
		spawn_drop(k.extra, 1, spot.pos + spot.normal * 0.6 + Vector3.UP * 0.3)
	if k.has("rare") and randf() < k.rare[1]:  # (a Bloomheart Core in a giant mushroom, owner Nov 19)
		spawn_drop(k.rare[0], 1, spot.pos + spot.normal * 0.6 + Vector3.UP * 0.5)
	give_xp(peer_id, k.xp, k.skill)
	var left: int = spot.get("chops", 1) - 1
	if left > 0:
		_ev_spot_chops.rpc(glow_id, left)
	else:
		removed_glow.append(glow_id)
		_ev_remove_glow.rpc(glow_id)
		_start_regrow(spot, ps)
	var done := {state = "done", hits = needed, needed = needed, point = spot.pos, kind = spot.kind}
	_tell_feedback(peer_id, done)
	return done


## Reading an old page (recipe page, blueprint, plans). Works from the hand (click) or from the bag
## (right-click it, owner Nov 17: "I cannot read the recipe"). Says why when it teaches nothing.
func _read_page(ps: PlayerState, peer_id: int, id: String) -> String:
	var r0 := _learn_from_page(ps, id)
	if r0 == "nothing_new" and peer_id == local_peer_id():
		hud_message.emit("You already know everything this %s shows." % Items.display_name(id))
	return r0


func _learn_from_page(ps: PlayerState, id: String) -> String:
	if id == "blueprint_page" or Items.info(id).has("teaches"):
		# An old blueprint from a ruin: the whole group can now place that ready-made building (F98).
		# A named plan (Watchtower Plans, F254) teaches its own building; an Old Blueprint a random one.
		var unknown := BlueprintMenu.ready_made_keys().filter(func(k): return not world_state.get("blueprints", []).has(k) and not BlueprintLibrary.REBUILD_ONLY.has(k))
		if Items.info(id).has("teaches"):
			unknown = unknown.filter(func(k): return k == Items.info(id).teaches)
		if unknown.is_empty() or not ps.inventory.remove(id, 1):
			return "nothing_new"
		var key: String = unknown[randi() % unknown.size()]
		var known: Array = world_state.get("blueprints", []).duplicate()
		known.append(key)
		world_state.blueprints = known
		_ev_state.rpc(world_state)
		_ev_learned_blueprint.rpc(BlueprintMenu.ready_made_name(key), id, "From reading the %s" % Items.display_name(id))
		return "learned"
	# A recipe page from a ruin: the whole group learns a recipe nobody knew yet, of the page's kind (a Cook's Page
	# teaches food, an Armourer's Page armour... owner, Nov 19). A dungeon's page or scroll always teaches its one
	# recipe (F237; Mossgate's scroll: "teaches_recipe").
	var one: String = Items.info(id).get("recipe", Items.info(id).get("teaches_recipe", ""))
	var left := ([one] if one != "" else Recipes.page_recipes(id)).filter(func(r): return not world_state.get("learned", []).has(r))
	if left.is_empty() or not ps.inventory.remove(id, 1):
		return "nothing_new"
	var r: String = left[randi() % left.size()]
	var learned: Array = world_state.get("learned", []).duplicate()
	learned.append(r)
	world_state.learned = learned
	_ev_state.rpc(world_state)
	_ev_learned.rpc(r)
	return "learned"


## Read a page straight from a bag slot (right-click in the bag). Request -> host decides -> everyone learns.
## Right-click a food or drink in the bag to eat it (owner F827).
func ask_eat(index: int) -> void:
	if is_host():
		request_eat(local_peer_id(), index)
	else:
		_rpc_eat.rpc_id(1, index)


@rpc("any_peer", "reliable")
func _rpc_eat(index: int) -> void:
	if is_host():
		request_eat(multiplayer.get_remote_sender_id(), index)


func request_eat(peer_id: int, index: int) -> String:
	var ps := get_player(peer_id)
	if ps == null or index < 0 or index >= ps.inventory.slots.size():
		return ""
	var id: String = ps.inventory.get_slot(index).get("id", "")
	if not Items.kind(id) in ["food", "drink"]:
		return ""
	return _eat(ps, peer_id, id, index)


func ask_read(index: int) -> void:
	if is_host():
		request_read(local_peer_id(), index)
	else:
		_rpc_read.rpc_id(1, index)


@rpc("any_peer", "reliable")
func _rpc_read(index: int) -> void:
	if is_host():
		request_read(multiplayer.get_remote_sender_id(), index)


func request_read(peer_id: int, index: int) -> String:
	var ps := get_player(peer_id)
	if ps == null:
		return ""
	var slot := ps.inventory.get_slot(index)
	if slot.is_empty() or Items.kind(slot.id) != "page":
		return ""
	return _read_page(ps, peer_id, slot.id)


## Right click: eat/drink the selected item, or place it if it's a station.
func request_use(peer_id: int, aim_point: Vector3, aim_normal: Vector3, yaw: float) -> String:
	var ps := get_player(peer_id)
	if ps == null:
		return ""
	var slot := ps.inventory.get_slot(ps.hand_slot())
	if slot.is_empty():
		return ""
	var id: String = slot.id
	match Items.kind(id):
		"waterskin":  # F401 (owner, Nov 20): an empty waterskin fills at a pool or under a waterfall
			var water := CaveWater.instance
			var at_water := water != null and ((aim_point != Vector3.INF and water.water_near(aim_point)) or water.water_near(ps.node.global_position))
			if not at_water:
				tell(peer_id, "Look at a pool or a waterfall to fill your waterskin.")
				return ""
			ps.inventory.slots[ps.hand_slot()] = {id = "waterskin_dirty", count = 1}
			ps.inventory.changed.emit()
			tell(peer_id, "Filled with pool water. Boil it at a campfire to make it clean.")
			return "filled"
		"food", "drink":
			return _eat(ps, peer_id, id, ps.selected_slot)
		"page":
			return _read_page(ps, peer_id, id)
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
			_war_horn(ps, 0.10, 60.0)
			return "used"
		"throw":
			if not aim_point.is_finite() or _chest(ps).distance_to(aim_point) > 22.0 or not ps.inventory.remove(id, 1):
				return ""
			_ev_throw.rpc(_chest(ps), aim_point, id)
			monsters.knock_off_near(aim_point, 1.5, _peer_of(ps))  # (a creature up high it lands by falls down, F475)
			if id == "spore_bomb":
				monsters.spawn_cloud(aim_point + Vector3.UP * 0.6, 3.0, 5.0, 40.0, 6.0, true)
			elif id == "blasting_pod":
				var counts := _host_dig(aim_point, 1, 2.0)  # copper-tier strength, 2 m hole
				_give_dig_drops(ps, counts, aim_point + aim_normal * 1.0)
			return "thrown"
		"shovel":
			if ps.inventory.count_of("root_seed") > 0:
				return _plant_seed(ps, aim_point, aim_normal)  # with a Root Seed in the bag (owner, Nov 18)
			return _raise_ground(ps, aim_point, aim_normal)  # F890: right click raises the ground
		"station":
			var on_wall := id in Station.ON_WALL and aim_normal.is_finite() and absf(aim_normal.normalized().y) < 0.3
			if not aim_point.is_finite() or (aim_normal.normalized().y < 0.6 and not on_wall) or _chest(ps).distance_to(aim_point) > REACH + 1.0:
				return ""
			var spot := aim_point
			if on_wall:  # back flat on the wall, facing out, hung where you aim (in 25 cm steps)
				var out := Vector3(aim_normal.x, 0.0, aim_normal.z).normalized()
				spot = wall_spot(id, aim_point, out)
				yaw = atan2(out.x, out.z)
			var on_fire := Station.on_fire_spot(id, aim_point, stations.values())  # a pot goes on top of a campfire
			if on_fire.is_finite():
				spot = on_fire
			else:
				for st in stations.values():
					if st.global_position.distance_to(aim_point) < 1.5:
						return ""  # too close to another station
			if not on_fire.is_finite() and Station.in_rock(id, spot, yaw, world):
				return ""  # it would stand in the wall (owner, Nov 17: the ghost shows red)
			if not ps.inventory.remove(id, 1):
				return ""
			var sid := _next_station_id
			_next_station_id += 1
			_ev_place_station.rpc(sid, id, spot, yaw)
			if Station.WATER.has(id):
				var drip := glow != null and GlowPlacer.drip_near(GlowPlacer.drips_above(glow, spot), spot)
				_ev_water.rpc(sid, 0, drip)
			if id == "bed":
				set_bed(peer_id, "s%d" % sid)  # F727: your newest bed is your wake-up spot
			return "placed"
		"chest":
			if not aim_point.is_finite() or aim_normal.normalized().y < 0.6 or _chest(ps).distance_to(aim_point) > REACH + 1.0:
				return ""
			if not ps.inventory.remove(id, 1):
				return ""
			storage.create_box(id, aim_point, yaw, peer_id)
			return "placed"
	return ""


# ---------------------------------------------------------------- farming (owner F176)

func ask_farm(station_id: int, seed_item: String = "") -> void:
	if is_host():
		request_farm(local_peer_id(), station_id, seed_item)
	else:
		_rpc_farm.rpc_id(1, station_id, seed_item)


@rpc("any_peer", "reliable")
func _rpc_farm(station_id: int, seed_item: String) -> void:
	if is_host():
		request_farm(multiplayer.get_remote_sender_id(), station_id, seed_item)


## A Farm Plot: empty → plant one mushroom/tuber from your bag (`seed_item`, or the first one you have);
## ready → pick the crop. Returns "planted", "picked", "growing", "no_seed" or "".
func request_farm(peer_id: int, station_id: int, seed_item: String = "") -> String:
	var ps := get_player(peer_id)
	var st: Station = stations.get(station_id)
	if ps == null or st == null or st.kind != "farm_plot" or st.global_position.distance_to(ps.node.global_position) > STATION_REACH + 1.0:
		return ""
	if st.crop_ripe():
		var give: int = Station.CROPS[st.crop].give
		var left := ps.inventory.add(st.crop, give)
		if left > 0:
			spawn_drop(st.crop, left, st.global_position + Vector3.UP * 0.8)
		if st.crop == "root_tuber":  # 5 tubers give back 1-2 seeds, never none (owner, Nov 21)
			var seeds := ps.inventory.add("tuber_seed", randi_range(1, 2))
			if seeds > 0:
				spawn_drop("tuber_seed", seeds, st.global_position + Vector3.UP * 0.8)
		give_xp(peer_id, 3, "gathering")
		_ev_farm.rpc(station_id, "", 0.0)
		return "picked"
	if st.crop != "":
		return "growing"
	if not Station.can_plant(seed_item) or ps.inventory.count_of(seed_item) <= 0:
		seed_item = ""
		for c in Station.CROPS.keys() + Station.SEEDS.keys():
			if Station.can_plant(c) and ps.inventory.count_of(c) > 0:
				seed_item = c
				break
	if seed_item == "":
		return "no_seed"
	ps.inventory.remove(seed_item, 1)
	var crop: String = Station.SEEDS.get(seed_item, seed_item)
	_ev_farm.rpc(station_id, crop, Station.CROPS[crop].grow)
	return "planted"


@rpc("authority", "call_local", "reliable")
func _ev_farm(station_id: int, crop: String, left: float) -> void:
	var st: Station = stations.get(station_id)
	if st:
		st.set_crop(crop, left)


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


## One number summed over active boosts ("dig_power", "extra_drops"...).
func boost_total(ps: PlayerState, key: String) -> float:
	var total := 0.0
	for b in ps.boosts.values():
		if b.until > now():
			total += b.get(key, 0.0)
	return total


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
	return total + ps.progress.hunter_bonus(target_kind)  # kill rewards: Bat Hunter +5% against bats


const BUG_SHAPES := ["rock_beetle", "cave_spider"]  ## Bugbane Oil works on beetles and spiders


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
		give_xp(peer_id, 1, Progression.weapon_skill(Combat.weapon_of(ps.selected_item())))
	return true


func _take_sip(ps: PlayerState, slot_i: int) -> void:
	var slot := ps.inventory.slots[slot_i]
	var sips: int = slot.get("sips", Items.info(slot.id).get("sips", 1)) - 1
	if sips <= 0:
		ps.inventory.slots[slot_i] = {id = Items.info(slot.id).get("empties_to", "waterskin_empty"), count = 1}
	else:
		slot.sips = sips
	ps.inventory.changed.emit()


## Eating or drinking the item in one bag slot (the hotbar's right click, or a right click in the bag: owner F827).
func _eat(ps: PlayerState, peer_id: int, id: String, slot_i: int) -> String:
	if id == "bandage":  # (owner, Nov 20: "you can just spam bandages": one every BANDAGE_COOLDOWN s)
		if ps.boosts.has("bandage_cooldown") and ps.boosts.bandage_cooldown.until > now():
			tell(peer_id, "Your last bandage is still fresh. Wait %d s." % ceili(ps.boosts.bandage_cooldown.until - now()))
			return "cooldown"
		add_boost(ps, "bandage_cooldown", {}, BANDAGE_COOLDOWN)
		send_cooldown(peer_id, "bandage", BANDAGE_COOLDOWN)  # a grey shade on its slot (owner F470)
	if not ps.meal_fits(id, now()):  # every slot of that sort is taken (owner F824)
		tell(peer_id, ("You've had a drink already" if Foods.is_drink(id) else "You're full") + ": wait for one to wear off, or drink Gutweed Tea to empty your belly.")
		return "full"
	if id == "waterskin_clean" or id == "waterskin_dirty":
		_take_sip(ps, slot_i)
	elif not ps.inventory.remove(id, 1):
		return ""
	var roll := randf()
	if Foods.is_purge(id):
		ps.meals.clear()
		for m in Foods.DISHES:
			ps.boosts.erase(m)  # the host's food fight boosts go too
	elif Foods.is_buff_food(id):
		ps.meals[id] = now() + Foods.minutes_of(id) * 60.0
	if Foods.is_buff_food(id) and ps.progress.has_star("cooking", 100):
		heal(peer_id, 10.0)  # Cooking ★100: your cooked food heals a little
	if peer_id == local_peer_id():
		ps.vitals.consume(id, roll)
		Sfx.ui("bandage" if id == "bandage" else "eat", -4.0)  # (owner's pick, Nov 26: a cloth bandage rip)
	else:
		_rpc_consumed.rpc_id(peer_id, id, roll)
	# The host does the fighting, digging and drops math, so it remembers those food buffs itself.
	var fb: Dictionary = Foods.buff_of(id) if Foods.is_buff_food(id) else {}
	var host_part := {}
	for k in ["damage", "dig_power", "extra_drops"]:
		if fb.has(k):
			host_part[k] = fb[k]
	if not host_part.is_empty():
		add_boost(ps, id, host_part, Foods.minutes_of(id) * 60.0)
	return "ate"


## Taking a shrine's rune. Returns what happened.
func request_poi(peer_id: int, poi_id: int) -> String:
	var ps := get_player(peer_id)
	var pois: Array = world.maker.pois
	if ps == null or poi_id < 0 or poi_id >= pois.size():
		return ""
	var poi: Dictionary = pois[poi_id]
	if _chest(ps).distance_to(poi.pos) > 5.0:
		return "too_far"
	match poi.type:
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


## Host: Running XP (1 per 1.2 s of running), Jumping XP (3 per jump) and Shield XP (4 per blocked hit,
## blocks are worked out on the player's computer). Never more than the
## time since the last report allows, so a friend can't send made-up numbers.
func request_body_xp(peer_id: int, run_seconds: float, jumps: int, blocks: int = 0) -> void:
	var ps := get_player(peer_id)
	if ps == null:
		return
	var since := minf(now() - ps.body_xp_at, 10.0)
	ps.body_xp_at = now()
	ps.run_carry += clampf(run_seconds, 0.0, since + 0.5) / 1.2
	var run_xp := int(ps.run_carry)
	ps.run_carry -= run_xp
	give_xp(peer_id, run_xp, "running")
	give_xp(peer_id, 3 * clampi(jumps, 0, ceili(since / 0.6)), "jumping")
	give_xp(peer_id, 4 * clampi(blocks, 0, ceili(since / 0.5)), "shield")


## An active perk (owner's tree, Nov 19). Returns "used", "cooldown" or "" (can't).
func request_ability(peer_id: int, perk_id: String, aim := Vector3.INF) -> String:
	var ps := get_player(peer_id)
	if ps == null or ps.dying or not Progression.ACTIVE.has(perk_id) or ps.progress.perk_rank(perk_id) < 1:
		return ""
	var name: String = Progression.PERKS[perk_id][4]
	var cd_key := "cd_" + perk_id
	if ps.boosts.has(cd_key) and ps.boosts[cd_key].until > now():
		tell(peer_id, "%s is recharging: %d s" % [name, ceili(ps.boosts[cd_key].until - now())])
		return "cooldown"
	var rank := ps.progress.perk_rank(perk_id)
	var here: Vector3 = ps.node.global_position
	var flat := Vector3(aim.x - here.x, 0.0, aim.z - here.z) if aim.is_finite() else Vector3.ZERO
	var fwd := flat.normalized() if flat.length() > 0.1 else Vector3.FORWARD
	var to := here  # where the flask lands / the banner stands
	match perk_id:
		"stone_stance":
			send_effect(peer_id, "stone_stance", {damage_taken = -0.4, move_speed = -0.5}, 60.0)
		"whirlwind":
			if monsters:
				monsters.whirlwind(peer_id)
		"rapid_volley":
			send_effect(peer_id, "rapid_volley", {free_reloads = 3.0}, 60.0)
		"quick_fix":
			var held := ps.inventory.get_slot(ps.hand_slot())
			if Durability.used(held) <= 0 or not Durability.wears(held.get("id", "")):
				tell(peer_id, "Nothing in your hand needs fixing.")
				return ""
			held["used"] = 0
			ps.inventory.changed.emit()
			tell(peer_id, "%s is like new." % Upgrades.display_name(held))
		"war_horn":
			_war_horn(ps, 0.10 * rank, 20.0)
		"healing_brew":  # a thrown flask: it heals everyone near where it splashes (owner, Nov 27)
			# shortcut: aimed at open air, it splashes in the air 14 m out (no falling arc); fine in caves
			to = _chest(ps) + (aim - _chest(ps)).limit_length(BREW_THROW) if aim.is_finite() else here + fwd * 6.0
			get_tree().create_timer(brew_flight(_chest(ps), to)).timeout.connect(func():
				for pid in players:
					if players[pid].node.global_position.distance_to(to) <= BREW_REACH:
						heal(pid, 15.0 * rank))
		"clan_banner":  # planted in front of you for 60 s; friends near the BANNER resist (owner, Nov 27)
			to = here + fwd * 1.5
			_banners.append({at = to, until = now() + 60.0})
			_banner_guard()  # guards right away, then every second from _process
	add_boost(ps, cd_key, {}, Progression.ACTIVE[perk_id])
	send_effect(peer_id, cd_key, {}, Progression.ACTIVE[perk_id])  # so their screen can show the recharge
	_ev_ability.rpc(peer_id, here, perk_id, to)
	tell(peer_id, name + "!")
	return "used"


## War Horn (the item and the perk): you and friends within 15 m hit harder.
func _war_horn(ps: PlayerState, damage: float, seconds: float) -> void:
	for pid in players:
		if players[pid].node.global_position.distance_to(ps.node.global_position) <= 15.0:
			add_boost(players[pid], "war_horn", {damage = damage}, seconds)
	_ev_horn.rpc(ps.node.global_position)


## Seconds a thrown flask flies (the same arc as a thrown bomb, _ev_throw).
static func brew_flight(from: Vector3, to: Vector3) -> float:
	return 0.15 + from.distance_to(to) / 18.0


@rpc("authority", "call_local", "reliable")
func _ev_ability(peer: int, at: Vector3, perk_id: String, to: Vector3) -> void:
	var dwarf := get_player(peer).node as Dwarf if get_player(peer) else null
	match perk_id:
		"whirlwind":
			Sfx.play("swing", at + Vector3.UP, 0.0, 0.7)
			if dwarf:
				dwarf.model.react("whirlwind")
		"healing_brew":
			if dwarf:
				dwarf.model.react("throw")
			AbilityFx.throw_flask(drops_root, at + Vector3.UP * 1.3, to, brew_flight(at + Vector3.UP * 1.3, to), BREW_REACH)
		"clan_banner":
			Sfx.play("dig_break", to, -4.0, 0.6)
			AbilityFx.plant_banner(drops_root, to, dwarf.model.global_rotation.y if dwarf else 0.0, 60.0)
		"stone_stance":
			Sfx.play("dig_break", at, -4.0, 0.6)


## Resetting perk points costs gold coins (owner, Nov 19). Skills stay.
func request_respec(peer_id: int) -> bool:
	var ps := get_player(peer_id)
	if ps == null or ps.progress.points_free() == ps.progress.points_total():
		return false
	var cost := ps.progress.respec_cost()
	if ps.inventory.count_of("gold_coin") < cost:
		tell(peer_id, "Resetting your perks costs %d gold coins. Old chests hold some." % cost)
		return false
	ps.inventory.remove("gold_coin", cost)
	ps.progress.respec()
	_progress_dirty[peer_id] = true
	tell(peer_id, "Perk points reset for %d gold." % cost)
	return true


## Host: puts an ability on a key. One that wasn't on a key starts its full recharge (no swapping to skip waits, owner Nov 27).
func request_set_ability_key(peer_id: int, slot: int, perk_id: String) -> bool:
	var ps := get_player(peer_id)
	if ps == null:
		return false
	var was_on := ps.progress.ability_slots().has(perk_id)
	if not ps.progress.set_ability_key(slot, perk_id):
		return false
	if perk_id != "" and not was_on:
		add_boost(ps, "cd_" + perk_id, {}, Progression.ACTIVE[perk_id])
		send_effect(peer_id, "cd_" + perk_id, {}, Progression.ACTIVE[perk_id])
	_progress_dirty[peer_id] = true
	return true


func request_buy_perk(peer_id: int, perk_id: String) -> bool:
	var ps := get_player(peer_id)
	if ps == null or not ps.progress.buy_perk(perk_id):
		return false
	_progress_dirty[peer_id] = true
	return true


## Crafting. station_id 0 = by hand. Instant recipes finish now; timed ones (smelter,
## campfire, pot, tanning rack) take their inputs now and pop out of the station later.
## F629 (owner, Nov 22): a batch (10 ropes) finishes all at once, and every craft played the same sound at the same
## moment. Now the first craft rings, at most CRAFT_SFX_EXTRA more follow a little later (quieter, a different pitch),
## and the rest of the batch is quiet.
const CRAFT_SFX_GAP := 0.6  ## crafts closer together than this count as one batch
const CRAFT_SFX_EXTRA := 2
var _craft_sfx_at := -10.0
var _craft_sfx_extra := 0


func _craft_sound() -> void:
	var delay := craft_sound_delay(Time.get_ticks_msec() / 1000.0)
	if delay == 0.0:
		Sfx.ui("craft", 0.0)
	elif delay > 0.0 and is_inside_tree():
		var vol := -4.0 - 2.0 * _craft_sfx_extra
		get_tree().create_timer(delay).timeout.connect(Sfx.ui.bind("craft", vol, randf_range(0.86, 1.1)))


## When this craft's sound plays: 0 = now, > 0 = that many seconds later, -1 = not at all (the batch already rang).
func craft_sound_delay(t: float) -> float:
	if t - _craft_sfx_at > CRAFT_SFX_GAP:
		_craft_sfx_at = t
		_craft_sfx_extra = 0
		return 0.0
	if _craft_sfx_extra >= CRAFT_SFX_EXTRA:
		return -1.0
	_craft_sfx_extra += 1
	return 0.2 * _craft_sfx_extra + randf_range(0.0, 0.08)


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
	if st and st.level() < int(r.get("level", 1)):
		return false  # needs a better-equipped station (F115)
	var pulled := _pull_for_craft(ps, recipe_id, st)
	var fuel_item := ""
	if r.get("fuel", 0) > 0:
		for f in ["coal"]:  # only coal from the Bloomery, never raw wood (owner, Nov 19, F404)
			if ps.inventory.count_of(f) >= r.fuel:
				fuel_item = f
				break
		if fuel_item == "":
			return false
	# Auto-crafting (owner, Nov 19): missing in-between items made at this same station get made first, silently;
	# their cooking time is added to the final job.
	var extra_seconds := 0.0
	var crafted_first := false
	if not Crafting.missing(ps.inventory, recipe_id).is_empty():
		crafted_first = true
		var lvl := st.level() if st else 1
		var steps := Crafting.plan(ps.inventory, recipe_id, r.station, func(id): \
			return Recipes.is_unlocked(id, ps.seen, taught_recipes()) and lvl >= int(Recipes.get_recipe(id).get("level", 1)))
		if steps.is_empty():
			return false
		for sub in steps.slice(0, -1):
			if not Crafting.craft(ps.inventory, sub):
				return false
			extra_seconds += float(Recipes.get_recipe(sub).get("seconds", 0))
	if r.get("seconds", 0) > 0 and st:
		if not Crafting.missing(ps.inventory, recipe_id).is_empty() or not st.can_queue():
			return false
		for item in r.inputs:
			ps.inventory.remove(item, r.inputs[item])
		if fuel_item != "":
			ps.inventory.remove(fuel_item, r.fuel)
		var cooking: bool = r.station == "campfire"
		var made: int = r.count
		if cooking and int(r.get("level", 1)) >= 2 and ps.progress.has_star("cooking", 25):
			made += 1  # Cooking ★25: the pot makes one more dish
		if cooking and ps.progress.has_star("cooking", 50) and randf() < 0.10:
			made *= 2  # Cooking ★50: now and then a double dish
		st.queue_job(r.output, made, (r.seconds + extra_seconds) * (ps.progress.smelt_time_mult() if r.station == "smelter" else 1.0) \
			* ps.progress.craft_time_mult(cooking))
	else:
		if not Crafting.craft(ps.inventory, recipe_id):
			return false
		if fuel_item != "":
			ps.inventory.remove(fuel_item, r.fuel)
	if randf() < ps.progress.save_material_chance():  # Steady Hands: one material comes back
		var back: String = r.inputs.keys().pick_random()
		var left := ps.inventory.add(back, 1)
		if left > 0:
			spawn_drop(back, left, _chest(ps))
	var skill := "cooking" if r.station == "campfire" else "crafting"
	if peer_id == local_peer_id():
		_craft_sound()
	if Items.stack_size(r.output) == 1 and (peer_id == local_peer_id() or multiplayer.get_peers().has(peer_id)):
		# F561 (owner, Nov 21: "I crafted a wooden shield without the resources"): say what it took from the bag.
		var used := []
		for item in r.inputs:
			used.append("%d %s" % [r.inputs[item], Items.display_name(item)])
		tell(peer_id, "Made a %s from %s%s.%s" % [Items.display_name(r.output), ", ".join(used),
			" (some made first from what was in your bag)" if extra_seconds > 0.0 or crafted_first else "",
			" Some came from the chests nearby." if pulled else ""])
	var xp := 10 if Items.stack_size(r.output) == 1 else (5 if skill == "cooking" else 1)
	give_xp(peer_id, xp, skill)
	return true


## F888 (owner, Nov 25): what the bag is short of for this craft (and the in-between things auto-crafting makes
## first, and the coal) comes out of the chests and barrels nearby (Storage.craft_boxes) into the bag, then the
## craft goes on as usual. Only when bag + chests have it all; otherwise nothing moves. Returns true if it took any.
func _pull_for_craft(ps: PlayerState, recipe_id: String, st: Station) -> bool:
	if storage == null:
		return false
	var r := Recipes.get_recipe(recipe_id)
	var at := _chest(ps)
	var fuel: int = int(r.get("fuel", 0))
	if Crafting.missing(ps.inventory, recipe_id).is_empty() and ps.inventory.count_of("coal") >= fuel:
		return false
	if storage.craft_boxes(at).is_empty():
		return false
	var stock := storage.craft_stock(ps.inventory, at)
	var steps := [recipe_id]
	if not Crafting.missing(stock, recipe_id).is_empty():
		var lvl := st.level() if st else 1
		steps = Crafting.plan(stock, recipe_id, r.station, func(id): 			return Recipes.is_unlocked(id, ps.seen, taught_recipes()) and lvl >= int(Recipes.get_recipe(id).get("level", 1)))
		if steps.is_empty():
			return false
	# Walk the steps on the bag's counts: what runs short has to come from the chests.
	var have := {}
	var short := {}
	for sid in steps:
		var sr := Recipes.get_recipe(sid)
		for item in sr.inputs:
			if not have.has(item):
				have[item] = ps.inventory.count_of(item)
			var n: int = int(sr.inputs[item])
			if have[item] < n:
				short[item] = short.get(item, 0) + n - have[item]
				have[item] = n
			have[item] -= n
		have[sr.output] = have.get(sr.output, ps.inventory.count_of(sr.output)) + int(sr.count)
	if fuel > 0 and ps.inventory.count_of("coal") < fuel:
		short["coal"] = short.get("coal", 0) + fuel - ps.inventory.count_of("coal")
	for item in short:
		if stock.count_of(item) - ps.inventory.count_of(item) < short[item]:
			return false
	var took := false
	for item in short:
		took = storage.pull_for_craft(ps.inventory, at, item, short[item]) > 0 or took
	return took


func request_pickup(peer_id: int, drop_id: int) -> bool:
	var ps := get_player(peer_id)
	var d: Drop = _drops.get(drop_id)
	if ps == null or d == null:
		return false
	# Each computer bounces drops on its own, and far from the host the host's copy may have
	# no floor loaded and fall away. So where it first appeared counts too.
	var reach := PICKUP_RANGE * (1.3 if ps.progress.has_star("gathering", 25) else 1.0)  # Gathering ★25
	if _chest(ps).distance_to(d.global_position) > reach and _chest(ps).distance_to(d.home) > reach + 4.0:
		return false
	if _drop_extra.has(drop_id):  # a thrown item with its own data (wear, upgrades): back into one free slot, whole
		var whole: Dictionary = _drop_extra[drop_id]
		for i in Inventory.SIZE:
			if ps.inventory.slots[i].is_empty():
				ps.inventory.slots[i] = whole.duplicate(true)
				_drop_extra.erase(drop_id)
				ps.inventory.changed.emit()
				_ev_remove_drop.rpc(drop_id)
				return true
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
	# Your lantern lies on the floor next to where you wake (owner, Nov 22: "he picks it up and not crafts").
	_ev_spawn_drop.rpc(_next_drop_id, "lantern", 1, start_lantern_spot(), Vector3.ZERO)
	_next_drop_id += 1


## Where the start lantern lies: a step to the side of where you wake, a little toward the peephole.
func start_lantern_spot() -> Vector3:
	var st: Dictionary = world.maker.start
	var u: Vector3 = st.dir
	var p: Vector3 = st.spawn + Vector3(-u.z, 0.0, u.x) * 0.9 + u * 0.5
	return Vector3(p.x, float(st.floor_y) + 0.25, p.z)


# Host-side helpers that decide things, then tell everyone.

func _host_dig(center: Vector3, tool_tier: int = 0, radius: float = DIG_RADIUS, world_made := false) -> Dictionary:
	if glow:
		for spot in glow.spots_near(center, maxf(DIG_RADIUS, radius) + 0.9):
			_host_remove_glow(spot, not world_made)
	var counts := world.apply_dig(center, radius, tool_tier)
	Sfx.play("dig_break", center, -6.0)
	if builder:
		builder.reanchor_near(center, radius)
		builder.queue_check(center, radius)
	var edit := Vector4(center.x, center.y, center.z, pack_dig(tool_tier, radius))
	edit_log.append(edit)
	_ev_dig.rpc(edit)  # the others apply it; we already did
	return counts


## `mined` = false: the world itself cleared the spot (a ruin making room): nothing drops and nothing grows back
## (owner: crystals, stones and twigs were left hanging in the air round the Fallen Outpost).
func _host_remove_glow(spot: Dictionary, mined := true) -> void:
	removed_glow.append(spot.id)
	_ev_remove_glow.rpc(spot.id)
	if not mined:
		return
	_start_regrow(spot)
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
		var tr := unpack_dig(absf(e.w))
		# Digs alone could go in any order, but a fill and a dig in the same place can't: anything near an edit that is
		# still waiting waits too, so they always happen in the order they were made.
		var behind := false
		for w in still:
			if c.distance_to(Vector3(w.x, w.y, w.z)) < tr.y + unpack_dig(absf(w.w)).y + 1.0:
				behind = true
				break
		if not behind and world.is_ready_at(c, tr.y + 1.0):
			if e.w < 0.0:
				world.apply_fill(c, tr.y, int(tr.x))
			else:
				world.apply_dig(c, tr.y, int(tr.x))
		else:
			still.append(e)
	_pending_digs = still


## Roots (thin and big) grow back after REGROW_TIME (owner, Nov 15, F106); crystals after CRYSTAL_REGROW_TIME (owner F406,
## Nov 19: "mine them all and there's no way to get them back"), each where it was, so every cave fills up again.
## `by` = who chopped it (Woodcutting ★75: their roots grow back 25% faster).
func _start_regrow(spot: Dictionary, by: PlayerState = null) -> void:
	if spot.get("kind", "") in [GlowPlacer.ROOT, GlowPlacer.ROOT_DANGLE]:
		regrow[spot.id] = REGROW_TIME * _root_regrow_mult(by)
	elif String(spot.get("kind", "")).begins_with("crystal"):
		regrow[spot.id] = CRYSTAL_REGROW_TIME


func _root_regrow_mult(by: PlayerState) -> float:
	return 0.75 if by and by.progress.has_star("woodcutting", 75) else 1.0


## Host: count down; a root comes back only if the rock it hangs from is still there.
func _tick_regrow(delta: float) -> void:
	_tick_trees(delta)
	_tick_boulders(delta)
	for id in plant_regrow.keys():
		plant_regrow[id] -= delta
		if plant_regrow[id] > 0.0:
			continue
		plant_regrow.erase(id)
		var home := cave_life.home_of(id) if cave_life else Vector3.INF
		if home == Vector3.INF or world.sdf_at(home + Vector3.DOWN * 0.3) >= 0.0:
			continue  # the rock it grew from was dug away
		removed_plants.erase(id)
		_ev_restore_plant.rpc(id)
	for id in regrow.keys():
		regrow[id] -= delta
		if regrow[id] > 0.0:
			continue
		regrow.erase(id)
		var s: Dictionary = glow._gone.get(id, {}) if glow else {}
		if s.is_empty() or world.sdf_at(s.pos - s.normal * 0.4) >= 0.0:
			continue  # its ceiling was dug away
		removed_glow.erase(id)
		_ev_restore_glow.rpc(id)


@rpc("authority", "call_local", "reliable")
func _ev_restore_glow(glow_id: int) -> void:
	removed_glow.erase(glow_id)
	if glow:
		glow.restore_spot(glow_id)


@rpc("authority", "call_local", "reliable")
func _ev_restore_plant(plant_id: int) -> void:
	removed_plants.erase(plant_id)
	if cave_life:
		cave_life.restore_plant(plant_id)


@rpc("authority", "call_local", "reliable")
func _ev_break_plant(plant_id: int) -> void:
	if cave_life:
		cave_life.remove_plant(plant_id)


@rpc("authority", "call_local", "reliable")
func _ev_remove_glow(glow_id: int) -> void:
	if glow:
		glow.remove_spot(glow_id)


@rpc("authority", "call_local", "reliable")
func _ev_spot_chops(glow_id: int, left: int) -> void:
	if glow:
		glow.set_chops(glow_id, left)


## Where a wall station goes: its back on the wall at `aim`, its bottom 25 cm-snapped below the aim point.
static func wall_spot(kind: String, aim: Vector3, out: Vector3) -> Vector3:
	var size := Station.size_of(kind)
	var spot := aim + out * (size.z * 0.5 + 0.005)
	spot.y = snappedf(aim.y - size.y * 0.5, 0.25)
	return spot


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
func _ev_spawn_drop(drop_id: int, item_id: String, count: int, pos: Vector3, vel: Vector3, thrown := false) -> void:
	var d: Drop = DROP_SCENE.new()
	d.thrown = thrown
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
	_drop_extra.erase(drop_id)
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
	if DungeonBuild.instance:  # (F844: the signposts' ticks follow the learned recipes: a save, or a friend joining)
		DungeonBuild.instance.update_signs()
	for gone in ["clues", "bosses_dead", "lairs_found"]:  # old saves: boss clues and boss kills (bosses removed, Nov 19)
		world_state.erase(gone)
	if poi_field:
		for id in world_state.shrines:
			poi_field.set_taken(id)
		for cid in world_state.get("columns", []):  # broken ruin columns (a save, or a friend joining)
			poi_field.set_column_broken(int(cid), false)


@rpc("authority", "call_local", "reliable")
func _ev_slab(data: Dictionary) -> void:
	rune_slab.load_data(data)


## "m" or "f": which biome's runes drop at p.
static func rune_biome_at(p: Vector3) -> String:
	return "f" if CaveMaker.biome_at(p) == "fungal" else "m"


func _seed_fungal_loot(rng: RandomNumberGenerator, id: int, ruin: bool) -> void:
	if ruin:
		for _p in 2:
			storage.put(id, Recipes.random_page(rng.randf()), 1)
		for g in [["keen", 0.03], ["leech", 0.04]]:
			if rng.randf() < g[1]:
				storage.put(id, Gems.item_id(g[0]), 1)
		storage.put(id, "silver_ingot", rng.randi_range(1, 3))
		storage.put(id, "crystal_amber", rng.randi_range(2, 4))
		storage.put(id, ["dish_truffle_risotto", "dish_chitin_crunch", "drink_spore_mead"][rng.randi_range(0, 2)], 1)
		if rng.randf() < 0.3:
			storage.put(id, "rune_" + rune_slab.pick_drop("f", [rng.randf(), rng.randf(), rng.randf(), rng.randf()]), 1)
		storage.put(id, "rusty_scrap", rng.randi_range(2, 5))
		storage.put(id, "gold_coin", rng.randi_range(8, 20))
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
		var at := RuinTreasure.chest_spot(world.maker, poi)
		# Ruins keep their loot in the old banded chest (owner's cup winner, Nov 19); camps in a traveller's small chest.
		var id := storage.create_box("chest_loot" if poi.type == "ruin" else "chest_small", at, rng.randf() * TAU)
		if poi.get("biome", "mossy") == "fungal":
			_seed_fungal_loot(rng, id, poi.type == "ruin")
			continue
		# Rare finds only, no free building materials (owner, Nov 15, F102).
		if poi.type == "ruin":
			for _p in 2:  # every old ruin keeps forgotten recipes
				storage.put(id, Recipes.random_page(rng.randf()), 1)
			storage.put(id, "blueprint_page", 1)  # and an old building plan (F98)
			for g in [["keen", 0.03], ["ember", 0.03]]:  # doc 4.2: rare gems in old chests
				if rng.randf() < g[1]:
					storage.put(id, Gems.item_id(g[0]), 1)
			if rng.randf() < 0.3:
				storage.put(id, "rune_" + rune_slab.pick_drop("m", [rng.randf(), rng.randf(), rng.randf()]), 1)
			storage.put(id, "gold_coin", rng.randi_range(5, 15))  # gold pays for a perk reset (owner, Nov 19)
			storage.put(id, "tuber_seed", rng.randi_range(2, 4))  # the only way to start growing Root Tubers
			storage.put(id, "rusty_scrap", rng.randi_range(2, 5))  # smelts into copper (its creatures are gone, Nov 19)
		else:
			# A camp someone left: a page, and maybe one bite of food.
			storage.put(id, Recipes.random_page(rng.randf()) if rng.randf() < 0.6 else "blueprint_page", 1)
			if rng.randf() < 0.5:
				storage.put(id, ["dish_hollowcap_stew", "dish_tuber_mash", "drink_glowcap_tea"][rng.randi_range(0, 2)], 1)
			storage.put(id, "tuber_seed", rng.randi_range(1, 2))


@rpc("authority", "reliable")
func _rpc_consumed(item_id: String, roll: float) -> void:
	var me := get_player(local_peer_id())
	if me:
		me.vitals.consume(item_id, roll)
		if item_id == "bandage":
			Sfx.ui("bandage", -4.0)


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
		drops.append([id, d.item_id, d.count, d.global_position, _drop_extra.get(id, {})])
	var sts := []
	for id in stations:
		var st: Station = stations[id]
		sts.append([id, st.kind, st.global_position, st.rotation.y, st.jobs.duplicate(true), st.water, st.under_drip, st.crop, st.crop_left])
	var chops := {}
	if glow:
		for id in glow._spots:
			if glow._spots[id].get("chops", 1) != GlowPlacer.KINDS[glow._spots[id].kind].get("chops", 1):
				chops[id] = glow._spots[id].chops
	return {boulder_hits = boulder_hits.duplicate(), boulder_back = boulder_back.duplicate(),
		tree_regrow = tree_regrow.duplicate(),
		strands = removed_strands.duplicate(), hroots = removed_hroots.duplicate(), pillar_chops = pillar_chops.duplicate(),
		grove_chops = grove_chops.duplicate(), grove_regrow = grove_regrow.duplicate(),
		planted = planted.duplicate(true),
		edits = edit_log.duplicate(), glow = removed_glow.duplicate(), plants = removed_plants.duplicate(), drops = drops, next_drop = _next_drop_id,
		stations = sts, chops = chops, regrow = regrow.duplicate(), plant_regrow = plant_regrow.duplicate(), runes = rune_slab.to_data(), build = builder.snapshot(), boxes = storage.snapshot(), monsters = monsters.snapshot(), state = world_state,
		beds = bed_owners.duplicate()}


func load_snapshot(snap: Dictionary) -> void:
	for id in snap.glow:
		removed_glow.append(id)
		if glow:
			glow.remove_spot(id)
	for id in snap.get("plants", []):  # broken grass, ferns, small roots
		removed_plants.append(id)
		if cave_life:
			cave_life.remove_plant(id)
	for id in snap.get("boulder_hits", {}):
		boulder_hits[int(id)] = int(snap.boulder_hits[id])
	for id in snap.get("boulder_back", {}):
		boulder_back[int(id)] = float(snap.boulder_back[id])
		if boulders:
			boulders.set_broken(int(id), true, false)
	for e in snap.get("planted", []):
		planted.append(e)
		if pillars:
			pillars.add_planted(e)
	for id in snap.get("pillar_chops", {}):
		pillar_chops[int(id)] = int(snap.pillar_chops[id])
		if pillars:
			pillars.set_used(int(id), pillar_chops[int(id)], false)
	for id in snap.get("grove_chops", {}):  # chopped (and felled) grove trees
		grove_chops[int(id)] = int(snap.grove_chops[id])
		if groves:
			groves.set_used(int(id), grove_chops[int(id)], false)
	for id in snap.get("grove_regrow", {}):
		grove_regrow[int(id)] = float(snap.grove_regrow[id])
	for id in snap.get("strands", []):
		removed_strands.append(int(id))
	if curtains and not removed_strands.is_empty():
		curtains.hide_strands(PackedInt32Array(removed_strands))
	for id in snap.get("hroots", []):
		removed_hroots.append(String(id))
		if clutter:
			clutter.hide_hroot(String(id))
	for id in snap.get("tree_regrow", {}):  # broken Root Trees growing back from both ends
		tree_regrow[int(id)] = float(snap.tree_regrow[id])
		if pillars:
			pillars.set_regrow(int(id), tree_regrow[int(id)])
	for id in pillar_chops:  # (trees broken in older saves start growing back now)
		if pillar_chops[id] >= RootPillars.CHOPS and not tree_regrow.has(id):
			tree_regrow[id] = RootPillars.REGROW_TIME
	for id in snap.get("plant_regrow", {}):  # small roots growing back
		plant_regrow[int(id)] = float(snap.plant_regrow[id])
	for c in snap.edits:
		edit_log.append(c)
		_pending_digs.append(c)
	for d in snap.drops:
		_ev_spawn_drop(d[0], d[1], d[2], d[3], Vector3.ZERO)
		if d.size() > 4 and d[4] is Dictionary and not d[4].is_empty():
			_drop_extra[d[0]] = d[4]  # a thrown sword keeps its wear and upgrades (F825)
	_next_drop_id = snap.next_drop
	for st in snap.get("stations", []):
		_ev_place_station(st[0], st[1], st[2], st[3])
		if st.size() > 4 and stations.has(st[0]):
			stations[st[0]].jobs.assign(st[4])  # smelting/cooking in progress survives a save
		if st.size() > 6 and stations.has(st[0]):
			stations[st[0]].under_drip = st[6] or (glow != null and GlowPlacer.drip_near(GlowPlacer.drips_above(glow, st[2]), st[2]))  # F884: old saves
			stations[st[0]].set_water(st[5])
		if st.size() > 8 and stations.has(st[0]):
			stations[st[0]].set_crop(st[7], st[8])  # what's growing on a farm plot
	for k in snap.get("beds", {}):  # whose bed is whose (F727)
		bed_owners[String(k)] = int(snap.beds[k])
	for id in snap.get("regrow", {}):
		regrow[id] = snap.regrow[id]
	if glow:  # saves from before roots grew back: their chopped roots start growing now
		for id in removed_glow:
			if not regrow.has(id) and glow._gone.get(id, {}).get("kind", "") in [GlowPlacer.ROOT, GlowPlacer.ROOT_DANGLE]:
				regrow[id] = REGROW_TIME
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

## Every hit pays (owner, Nov 17, F261, like Conan Exiles): a hit that doesn't break the rock yet already gives 1 stone
## (or ore). It's an advance: it's taken off what that rock gives when it breaks (ps.leftovers goes below zero for a
## moment), so the total stays the same, and hitting a rock and walking away isn't free stone.
func _pay_hit(ps: PlayerState, mat: int, pos: Vector3) -> void:
	var item: String = Mat.DROP_ITEM.get(mat, "")
	if item == "":
		return
	ps.leftovers[mat] = ps.leftovers.get(mat, 0) - int(Mat.VOXELS_PER_ITEM.get(mat, 3))
	spawn_drop(item, 1, pos)


func _give_dig_drops(ps: PlayerState, counts: Dictionary, pos: Vector3) -> void:
	for mat in counts:
		var item: String = Mat.DROP_ITEM.get(mat, "")
		if item == "":
			continue
		var voxels: int = counts[mat] + ps.leftovers.get(mat, 0)
		var per: int = Mat.VOXELS_PER_ITEM.get(mat, 3)
		var n := maxi(voxels, 0) / per
		ps.leftovers[mat] = voxels - n * per  # (below zero = hits paid in advance, taken off later digs)
		var ore: bool = Mat.is_ore(mat)
		if ore and ps.leftovers[mat] >= 0:
			n = maxi(n, 1)  # always feel rewarded for hitting ore (the hits already paid count too)
			if randf() < Gems.bonus(ps.inventory.get_slot(ps.hand_slot())).get("extra_ore", 0.0):
				n += 1  # Burrow gem
			if randf() < ps.progress.extra_ore_chance():
				n += 1  # Prospector
			if ps.progress.has_star("mining", 50) and randf() < 0.1:
				n *= 2  # Mining ★50: double ore
			for i in n:
				if randf() < 0.005:
					spawn_drop(Gems.item_id("burrow"), 1, pos)  # ore veins hide Burrow gems (doc 4.2)
		if n > 0 and not ore and ps.progress.perk_rank("master_of_stone") > 0 and randf() < 0.02:
			spawn_drop(Gems.item_id(Gems.NORMAL.keys().pick_random()), 1, pos)  # Master of Stone: a rare gem
		if n > 0 and item.begins_with("crystal_") and ps.progress.has_star("mining", 75):
			n += 1  # Mining ★75: +1 crystal
		if n > 0 and not item.begins_with("crystal_") and randf() < Gems.armor_bonus(ps.inventory).get("double_ore", 0.0):
			n *= 2  # Deep Onyx armor: double ore and stone
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
	_bond_of_the_clan(peer_id, where)
	_death_skill_loss(ps, peer_id)
	where = grave_spot(peer_id, where)
	var grave := -1
	for i in ps.inventory.slots.size():
		var s: Dictionary = ps.inventory.slots[i]
		if s.is_empty() or (i < Inventory.HOTBAR_SIZE and Items.stack_size(s.id) == 1) or ps.inventory.is_worn(i):
			continue  # hotbar tools and everything worn (F23, F825) stay with you
		if grave < 0:
			grave = storage.create_box("grave", where, 0.0, peer_id)
		storage.boxes[grave].inv.slots[i] = s.duplicate()
		ps.inventory.slots[i] = {}
	if grave >= 0:
		storage._changed(grave)
	ps.inventory.changed.emit()
	ps.meals.clear()  # waking up clears your eaten foods (Vitals.respawn does the same on your own computer)
	var wake: Vector3 = ps.bed_pos if ps.bed_pos != Vector3.INF else world.maker.spawn_point
	if peer_id == local_peer_id():
		_respawn_here(wake)
	else:
		_rpc_respawn.rpc_id(peer_id, wake)


## Host: everyone within BANNER_REACH of a standing Clan Banner resists poison, fire and chill by half.
func _banner_guard() -> void:
	_banners = _banners.filter(func(b): return b.until > now())
	for b in _banners:
		for pid in players:
			if players[pid].node.global_position.distance_to(b.at) <= BANNER_REACH:
				send_effect(pid, "clan_banner", {resist_poison = 0.5, resist_burn = 0.5, resist_chill = 0.5}, 1.5)


## Host: dying costs a bit of every skill (like Valheim, owner Nov 27), then none for 10 min ("skill_calm": the HUD
## shows its icon and timer).
func _death_skill_loss(ps: PlayerState, peer_id: int) -> void:
	if ps.boosts.has("skill_calm") and ps.boosts.skill_calm.until > now():
		tell(peer_id, "No skills lost: you died less than 10 minutes ago.")
		return
	var part := ps.progress.lose_skills_on_death()
	_progress_dirty[peer_id] = true
	add_boost(ps, "skill_calm", {}, Progression.DEATH_CALM)
	send_effect(peer_id, "skill_calm", {}, Progression.DEATH_CALM)
	tell(peer_id, "You lost %s%% of every skill. No more loss for 10 minutes." % String.num(part * 100.0, 2).trim_suffix(".0"))


## Host: a few times a second, note where each player stands on solid ground (rock or something built under their feet).
func _track_safe_spots(delta: float) -> void:
	_safe_clock += delta
	_safe_tick -= delta
	if _safe_tick > 0.0:
		return
	_safe_tick = 0.25
	for pid in players:
		var node: Node3D = players[pid].node
		if node == null or not node.is_inside_tree():
			continue
		var p := node.global_position
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.4, World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
		var grounded := not node.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
		if not grounded and world and world.maker:
			grounded = world.maker.sdf_at(p + Vector3.DOWN * 0.25) <= 0.0
		if not grounded:
			continue
		var list: Array = _safe_spots.get(pid, [])
		list.append([_safe_clock, p])
		if list.size() > 40:
			list.pop_front()
		_safe_spots[pid] = list


## Where a player's grave goes: where they stood safely about GRAVE_BACK seconds ago (else the oldest safe spot we
## know from the last few seconds, else where they died).
func grave_spot(peer_id: int, died_at: Vector3) -> Vector3:
	var list: Array = _safe_spots.get(peer_id, [])
	var best := died_at
	for i in range(list.size() - 1, -1, -1):
		best = list[i][1]
		if _safe_clock - float(list[i][0]) >= GRAVE_BACK:
			break
	_safe_spots.erase(peer_id)  # (a new life starts a new list)
	return best


## Bond of the Clan: a friend with it near where someone fell rallies everyone close by.
func _bond_of_the_clan(fallen: int, where: Vector3) -> void:
	for pid in players:
		var o: PlayerState = players[pid]
		if pid == fallen or o.progress.perk_rank("bond_of_the_clan") < 1 or o.node.global_position.distance_to(where) > 20.0:
			continue
		for q in players:
			if q != fallen and players[q].node.global_position.distance_to(o.node.global_position) <= 15.0:
				add_boost(players[q], "bond", {damage = 0.25}, 60.0)
				send_effect(q, "bond", {stamina_regen = 0.25, max_stamina = 0.25}, 60.0)
				tell(q, "Bond of the Clan! +25% damage and stamina for 60 s.")
		return


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
	# clothes/armor soak some up (F23); `pierce`: nothing does (a falling stalactite: always 50, owner Nov 20)
	ps.vitals.take_damage(amount * (1.0 if buildup.get("pierce", false) else 1.0 - ps.armor_cut()))
	Sfx.ui("hurt", -2.0)  # F551: a leather-and-gear body thump (old-world, not a hard impact)
	for k in buildup:
		if k != "pierce":
			ps.vitals.add_ailment(k, buildup[k])


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
	var share := amount * 0.10 * ps.progress.perk_rank("shared_lessons")
	if skill != "" and share > 0.0:  # Shared Lessons: friends nearby learn a bit too
		for pid in players:
			var n := int(share) + (1 if randf() < share - int(share) else 0)
			if pid != peer_id and n > 0 and players[pid].node.global_position.distance_to(ps.node.global_position) <= 20.0:
				players[pid].progress.add_xp(n, skill)
				_progress_dirty[pid] = true


func _peer_of(ps: PlayerState) -> int:
	for id in players:
		if players[id] == ps:
			return id
	return -1


var _dark_timer := 0.0


## Hunger, thirst, stamina and healing for OUR dwarf (each computer runs its own player's body).
func _tick_vitals(ps: PlayerState, delta: float) -> void:
	var resting := false
	for st in stations.values():
		if st.kind in ["campfire", "bed"] and st.global_position.distance_to(ps.node.global_position) < 4.0:
			resting = true
			break
	var v := ps.vitals
	if ps.node is CharacterBody3D and not v.is_dead():  # long falls hurt (Jumping ★100: never)
		var body := ps.node as CharacterBody3D
		var drop := ps.fall.step(body.global_position.y, body.is_on_floor(), body.velocity.y, delta)
		if FallDamage.damage_for(drop) > 0.0 and not ps.progress.has_star("jumping", 100):
			v.take_damage(FallDamage.damage_for(drop))
			Sfx.ui("hurt", 0.0, 0.85)  # F551: a fall lands heavier (lower)
			hud_message.emit("Ouch! You fell %d m." % roundi(drop))
	if v.is_dead():
		if not ps.dying:
			ps.dying = true
			if ps.node is Dwarf:  # the knock-back first, then you wake at your bed (owner, chat 15)
				(ps.node as Dwarf).model.react("die")
				get_tree().create_timer(DwarfFight.DEATH_FALL).timeout.connect(ask_died)
			else:
				ask_died()
		return
	_dark_timer -= delta
	if _dark_timer <= 0.0:  # F293: is any light reaching us? (twice a second is plenty)
		_dark_timer = 0.5
		v.in_dark = not Darkness.is_lit(get_tree(), ps.node.global_position + Vector3.UP)
	v.friends_near = false  # Shoulder to Shoulder
	for pid in players:
		if players[pid] != ps and is_instance_valid(players[pid].node) and players[pid].node.global_position.distance_to(ps.node.global_position) <= 10.0:
			v.friends_near = true
			break
	var low := ps.progress.perk_rank("berserker") > 0 and v.health < v.max_health() * 0.3
	if low != ps.low_health:  # Berserker: the host judges damage, so it needs to know
		ps.low_health = low
		if not is_host():
			_rpc_low_health.rpc_id(1, low)
	# The Cozy buff: rest by a fire or bed for a few seconds (Comfort).
	_rest_seconds = _rest_seconds + delta if resting else 0.0
	_comfort_timer -= delta
	if resting and _rest_seconds >= REST_FOR_COZY and _comfort_timer <= 0.0:
		_comfort_timer = 1.0
		var pieces: Dictionary = builder.structure.pieces if builder else {}
		comfort_here = Comfort.score(ps.node.global_position, stations, pieces)
		v.set_cozy(comfort_here)
	elif not resting:
		comfort_here = 0
	var hunger_before := v.hunger
	var thirst_before := v.thirst
	v.tick(delta, resting)
	# Survival skill and perks slow the drain.
	v.hunger = hunger_before - (hunger_before - v.hunger) * ps.progress.hunger_drain_mult() * (1.0 + rune_slab.bonus("hunger_drain")) * (1.0 - v.buff_total("hunger_slow"))
	v.thirst = thirst_before - (thirst_before - v.thirst) * ps.progress.thirst_drain_mult() * (1.0 + rune_slab.bonus("thirst_drain")) * (1.0 - v.buff_total("thirst_slow"))


func station_near(p: Vector3, radius: float = STATION_REACH) -> Station:
	var best: Station = null
	for st in stations.values():
		if st.global_position.distance_to(p) <= radius and (best == null or st.global_position.distance_to(p) < best.global_position.distance_to(p)):
			best = st
	return best


## A dig's pickaxe tier and size, squeezed into one number: tier × 1000 + radius in cm.
## (Exact to the centimeter, so every computer carves exactly the same hole.)
## A fill (Mason's Shovel) is saved in the same list with a negative w: -(material * 1000 + radius * 100).
static func pack_fill(mat: int, radius: float) -> float:
	return -(mat * 1000.0 + roundf(radius * 100.0))


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
