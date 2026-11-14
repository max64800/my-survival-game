class_name Inventory
extends RefCounted
## Inventory: the hotbar (slots 0-8, keys 1-9) plus the bag (slots 9-38).
## A dwarf's inventory (PLAYER_SIZE) also has (feedback F23):
##   slots 39-48: 10 backpack slots, open only while a backpack is equipped
##   slots 49-57: equipment: pickaxe, lantern, weapon, shield, head, chest, legs, feet, pack
## Chests and graves are plain inventories (any size, no backpack or equipment).
## Each slot is either empty ({}) or {id = "stone", count = 12}.

signal changed

const HOTBAR_SIZE := 9  ## keys 1-9 (feedback F18; was 8)
const BAG_SIZE := 30
const SIZE := HOTBAR_SIZE + BAG_SIZE  ## hotbar + bag: always open
const PACK_SIZE := 10
const PACK_START := SIZE
const EQUIP := ["pickaxe", "lantern", "weapon", "shield", "head", "chest", "legs", "feet", "pack"]
const EQUIP_START := SIZE + PACK_SIZE
const PLAYER_SIZE := EQUIP_START + 9  ## = EQUIP.size()

var slots: Array[Dictionary] = []
var is_player := false  ## has backpack + equipment slots


## `size` = how many slots (a dwarf uses PLAYER_SIZE; chests and graves pick their own).
func _init(size: int = SIZE) -> void:
	slots.resize(size)
	for i in size:
		slots[i] = {}
	is_player = size >= PLAYER_SIZE


static func equip_index(slot_name: String) -> int:
	return EQUIP_START + EQUIP.find(slot_name)


static func is_equip_index(i: int) -> bool:
	return i >= EQUIP_START and i < PLAYER_SIZE


static func is_pack_index(i: int) -> bool:
	return i >= PACK_START and i < EQUIP_START


## Which equipment slot an item goes in ("" = it can't be equipped).
static func equip_slot_for(id: String) -> String:
	match Items.kind(id):
		"pickaxe": return "pickaxe"
		"lantern": return "lantern"
		"weapon": return "weapon"
		"shield": return "shield"
		"pack": return "pack"
		"wear": return Items.info(id).get("slot", "head")
	return ""


func equipped(slot_name: String) -> String:
	return get_slot(equip_index(slot_name)).get("id", "") if is_player else ""


func pack_open() -> bool:
	return is_player and equipped("pack") != ""


## Slots that normal adding (picking things up, crafting) may fill.
func _carry(i: int) -> bool:
	return i < SIZE or (is_player and is_pack_index(i) and pack_open()) or (not is_player and i < slots.size())


## Adds items. Fills matching stacks first; then, for a dwarf, puts a tool/lantern/clothes into its
## empty equipment slot; then empty slots (hotbar first). Returns how many did NOT fit (0 = all fit).
func add(id: String, count: int) -> int:
	if count <= 0 or not Items.exists(id):
		return count
	var left := count
	var max_stack := Items.stack_size(id)
	for i in slots.size():
		if left == 0:
			break
		var s := slots[i]
		if _carry(i) and s.get("id", "") == id and s.count < max_stack:
			var put := mini(max_stack - int(s.count), left)
			s.count += put
			left -= put
	if left > 0 and is_player:
		# Tools you always use, clothes and backpacks put themselves on. Weapons and shields
		# go to the hotbar like before (right-click equips them).
		var es := equip_slot_for(id)
		if es in ["pickaxe", "lantern", "head", "chest", "legs", "feet", "pack"] and slots[equip_index(es)].is_empty():
			slots[equip_index(es)] = {id = id, count = 1}
			left -= 1
	for i in slots.size():
		if left == 0:
			break
		if _carry(i) and slots[i].is_empty():
			var put := mini(max_stack, left)
			slots[i] = {id = id, count = put}
			left -= put
	if left != count:
		changed.emit()
	return left


## Everything you have, equipped or not.
func count_of(id: String) -> int:
	var n := 0
	for s in slots:
		if s.get("id", "") == id:
			n += s.count
	return n


## Removes items. Takes from the bag before the hotbar, never from equipment.
## Returns false (and changes nothing) if there aren't enough.
func remove(id: String, count: int) -> bool:
	if count <= 0:
		return true
	var have := 0
	for i in slots.size():
		if not is_equip_index(i) or not is_player:
			if slots[i].get("id", "") == id:
				have += slots[i].count
	if have < count:
		return false
	var left := count
	for i in range(slots.size() - 1, -1, -1):
		if is_player and is_equip_index(i):
			continue
		var s := slots[i]
		if s.get("id", "") != id:
			continue
		var take := mini(s.count, left)
		s.count -= take
		left -= take
		if s.count == 0:
			slots[i] = {}
		if left == 0:
			break
	changed.emit()
	return true


func get_slot(i: int) -> Dictionary:
	return slots[i] if i >= 0 and i < slots.size() else {}


## Can slot i hold this item? (Equipment slots take only their kind; backpack slots need a backpack.)
func fits(i: int, item: Dictionary) -> bool:
	if item.is_empty():
		return true
	if is_player and is_equip_index(i):
		return equip_slot_for(item.id) == EQUIP[i - EQUIP_START] and int(item.count) == 1
	if is_player and is_pack_index(i):
		return pack_open()
	return true


## Swaps two slots (moving items around in the bag, equipping, unequipping).
## Refused if an item would land where it doesn't belong, or if taking off the backpack
## would leave things in its slots. Returns true if it swapped.
func swap(a: int, b: int) -> bool:
	if not swap_allowed(a, b):
		return false
	var tmp := slots[a]
	slots[a] = slots[b]
	slots[b] = tmp
	changed.emit()
	return true


## The rules for swap(), so the screen can check before asking.
func swap_allowed(a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0 or a >= slots.size() or b >= slots.size():
		return false
	if not fits(a, slots[b]) or not fits(b, slots[a]):
		return false
	if is_player:
		var pack_i := equip_index("pack")
		if (a == pack_i or b == pack_i) and not _pack_slots_empty():
			var other := b if a == pack_i else a
			if slots[other].is_empty() or equip_slot_for(slots[other].get("id", "")) != "pack":
				return false  # empty the backpack first (swapping one backpack for another is fine)
	return true


func _pack_slots_empty() -> bool:
	for i in range(PACK_START, EQUIP_START):
		if not slots[i].is_empty():
			return false
	return true


## Plain data, for sending over the network or saving.
func to_data() -> Array:
	return slots.duplicate(true)


func load_data(data: Array) -> void:
	for i in slots.size():
		slots[i] = data[i].duplicate(true) if i < data.size() and data[i] is Dictionary else {}  # deep: gems lists too
	changed.emit()
