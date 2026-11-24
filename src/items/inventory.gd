class_name Inventory
extends RefCounted
## Inventory: the hotbar (slots 0-8, keys 1-9) plus the bag (slots 9-38).
## A dwarf's inventory (PLAYER_SIZE) also has (feedback F23):
##   slots 39-48: 10 backpack slots, open only while a backpack is equipped
##   slots 49-57: equipment: pickaxe, lantern, weapon, shield, head, chest, legs, feet, pack
##     (F825/F826, owner Nov 23, like Valheim: the pickaxe, weapon and shield slots are no longer used. Those three
##     stay in their hotbar/bag slot and get `worn = true` when put on; old saves move them out, see hand_slots_out.)
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
const HAND := ["pickaxe", "weapon", "shield"]  ## worn in place (a `worn` mark), not in an equipment slot (F825)
const GEAR := ["head", "chest", "legs", "feet", "lantern", "pack"]  ## the slots the bag's Gear panel shows

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
	return get_slot(worn_slot(slot_name)).get("id", "") if is_player else ""


## Where the thing you wear of this kind is (-1 = none). Pickaxe, weapon and shield: the hotbar/bag/backpack slot
## with the worn mark (F825); everything else: its equipment slot.
func worn_slot(slot_name: String) -> int:
	if not is_player:
		return -1
	var at := equip_index(slot_name)
	if not slot_name in HAND:
		return at
	for i in EQUIP_START:
		var s := slots[i]
		if s.get("worn", false) and equip_slot_for(s.get("id", "")) == slot_name:
			return i
	return at if not slots[at].is_empty() else -1  # an old save's item that found no room in the bag yet


## Is the item in slot i worn? (In an equipment slot, or a pickaxe/weapon/shield with the worn mark.)
func is_worn(i: int) -> bool:
	if not is_player or get_slot(i).is_empty():
		return false
	return is_equip_index(i) or get_slot(i).get("worn", false)


## Add one item and put it on straight away (robots and tests: "he already has his sword on"). Returns the slot or -1.
func add_worn(id: String) -> int:
	if add(id, 1) > 0:
		return -1
	for i in EQUIP_START:
		if slots[i].get("id", "") == id and not slots[i].get("worn", false):
			set_worn(i, true)
			return i
	return equip_index(equip_slot_for(id)) if equipped(equip_slot_for(id)) == id else -1


## Put on (or take off) the pickaxe/weapon/shield in slot i. Only one of each kind is worn: the old one comes off.
func set_worn(i: int, on: bool) -> bool:
	var s := get_slot(i)
	var kind := equip_slot_for(s.get("id", ""))
	if not is_player or not kind in HAND or is_equip_index(i) or int(s.get("count", 0)) != 1:
		return false
	if on:
		for j in EQUIP_START:
			if j != i and slots[j].get("worn", false) and equip_slot_for(slots[j].get("id", "")) == kind:
				slots[j].erase("worn")
		var old := equip_index(kind)
		if not slots[old].is_empty():  # an old save's leftover in the unused equipment slot: the two trade places
			var tmp := slots[old]
			s.erase("worn")
			slots[old] = s  # worn from there (worn_slot falls back to it)
			slots[i] = tmp
			slots[i].erase("worn")
			changed.emit()
			return true
		s.worn = true
	else:
		s.erase("worn")
	changed.emit()
	return true


## What putting on / taking off slot i would hit ("" = fine), so the screen can say why before asking the host.
func equip_problem(i: int) -> String:
	var s := get_slot(i)
	if s.is_empty():
		return "?"
	if is_equip_index(i):
		for j in SIZE:
			if slots[j].is_empty():
				return "" if swap_allowed(i, j) else "Empty the backpack first."
		return "No room in the bag to take that off."
	var where := equip_slot_for(s.id)
	if where == "":
		return "%s can't be equipped." % Items.display_name(s.id)
	if where in HAND:
		return ""
	return "" if swap_allowed(i, equip_index(where)) else "Empty the backpack first."


## Put on / take off slot i right now (the host does this when the equip ring is full, F826). True = it changed.
func toggle_equip(i: int) -> bool:
	if equip_problem(i) != "":
		return false
	var s := get_slot(i)
	if is_equip_index(i):
		for j in SIZE:
			if slots[j].is_empty():
				return swap(i, j)
		return false
	var where := equip_slot_for(s.id)
	if where in HAND:
		return set_worn(i, not s.get("worn", false))
	return swap(i, equip_index(where))


## Takes the whole slot out (Q in the bag throws it away, F825). Returns what was there, without the worn mark.
func take_slot(i: int) -> Dictionary:
	var s := get_slot(i)
	if s.is_empty():
		return {}
	if is_player and i == equip_index("pack") and not _pack_slots_empty():
		return {}  # empty the backpack first
	slots[i] = {}
	s = s.duplicate(true)
	s.erase("worn")
	changed.emit()
	return s


## The slot with the strongest item of this kind you carry (hotbar, bag, backpack), or -1.
func best_of_kind(kind: String) -> int:
	var best := -1
	var best_power := -1.0
	for i in EQUIP_START:
		var id: String = slots[i].get("id", "") if i < slots.size() else ""
		if id != "" and Items.kind(id) == kind and float(Items.info(id).get("power", 0)) > best_power:
			best = i
			best_power = float(Items.info(id).get("power", 0))
	return best


func pack_open() -> bool:
	return is_player and equipped("pack") != ""


## Slots that normal adding (picking things up, crafting) may fill.
func _carry(i: int) -> bool:
	return i < SIZE or (is_player and is_pack_index(i) and pack_open()) or (not is_player and i < slots.size())


## Adds items. Fills matching stacks first; then, for a dwarf, puts a tool/lantern/clothes into its
## empty equipment slot (not pickaxes, F243); then empty slots (hotbar first). Returns how many did NOT fit (0 = all fit).
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
		# Lanterns, clothes and backpacks put themselves on. Pickaxes (owner F243), weapons and
		# shields go to the hotbar like everything else (double-click equips them).
		var es := equip_slot_for(id)
		if es in ["lantern", "head", "chest", "legs", "feet", "pack"] and slots[equip_index(es)].is_empty():
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
		if not is_worn(i):
			if slots[i].get("id", "") == id:
				have += slots[i].count
	if have < count:
		return false
	var left := count
	for i in range(slots.size() - 1, -1, -1):
		if is_worn(i):
			continue  # never what you're wearing (equipment, or a worn pickaxe/weapon/shield, F825)
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
		if EQUIP[i - EQUIP_START] in HAND:
			return false  # unused since F825: pickaxe/weapon/shield are worn where they lie
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


## Right-click (owner F187): half of a stack (rounded down) moves to the first empty slot you carry.
func split(i: int) -> bool:
	var s := get_slot(i)
	if s.is_empty() or int(s.count) < 2 or (is_player and is_equip_index(i)):
		return false
	for j in slots.size():
		if j != i and _carry(j) and not (is_player and is_equip_index(j)) and slots[j].is_empty():
			var half := int(s.count) / 2
			s.count -= half
			slots[j] = {id = s.id, count = half}
			changed.emit()
			return true
	return false


## Shift+Click (owner F187): hotbar -> bag, bag or backpack -> hotbar. Fills matching stacks first,
## then empty slots. Returns true if anything moved (what doesn't fit stays where it was).
func quick_move(i: int) -> bool:
	var s := get_slot(i)
	if s.is_empty() or (is_player and is_equip_index(i)):
		return false
	var to := range(HOTBAR_SIZE, SIZE) if i < HOTBAR_SIZE else range(0, HOTBAR_SIZE)
	if i < HOTBAR_SIZE and pack_open():
		to += range(PACK_START, EQUIP_START)
	var max_stack := Items.stack_size(s.id)
	var before := int(s.count)
	for j in to:  # top up matching stacks
		var t := slots[j]
		if t.get("id", "") == s.id and int(t.count) < max_stack and s.count > 0:
			var put := mini(max_stack - int(t.count), int(s.count))
			t.count += put
			s.count -= put
	for j in to:  # then the first empty slot
		if s.count > 0 and slots[j].is_empty():
			slots[j] = s.duplicate(true)
			s.count = 0
	if int(s.count) == before:
		return false
	if s.count <= 0:
		slots[i] = {}
	changed.emit()
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
		if slots[i].has("id") and not Items.exists(str(slots[i].id)):
			slots[i] = {}  # an old save's item the game no longer has (critter meat, boss parts..., Nov 19)
	_split_big_stacks()
	hand_slots_out()
	changed.emit()


## Stacks got smaller (F793: stone 100 -> 50). An old save's too-big stack spills its extra into empty slots
## (nothing is ever deleted: with no room left, the big stack just stays as it is).
func _split_big_stacks() -> void:
	for i in slots.size():
		var s := slots[i]
		if s.is_empty() or (is_player and is_equip_index(i)) or s.has("gems"):
			continue
		var max_stack := Items.stack_size(str(s.id))
		for j in slots.size():
			if int(s.count) <= max_stack:
				break
			if j != i and slots[j].is_empty() and not (is_player and (is_equip_index(j) or (is_pack_index(j) and not pack_open()))):
				var put := mini(int(s.count) - max_stack, max_stack)
				slots[j] = {id = s.id, count = put}
				s.count = int(s.count) - put


## Old saves (before F825) kept the pickaxe, weapon and shield in equipment slots. They move to the first free
## hotbar/bag slot, still worn. With no room they wait there (still worn) until a slot is free on the next load.
func hand_slots_out() -> void:
	if not is_player:
		return
	for kind in HAND:
		var at := equip_index(kind)
		if slots[at].is_empty():
			continue
		for j in SIZE:
			if slots[j].is_empty():
				for k in EQUIP_START:  # one worn of each kind
					if slots[k].get("worn", false) and equip_slot_for(slots[k].get("id", "")) == kind:
						slots[k].erase("worn")
				slots[j] = slots[at]
				slots[j].worn = true
				slots[at] = {}
				break
