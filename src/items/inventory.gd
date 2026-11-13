class_name Inventory
extends RefCounted
## Inventory: the hotbar (slots 0-7) plus the bag (slots 8-37).
## Each slot is either empty ({}) or {id = "stone", count = 12}.

signal changed

const HOTBAR_SIZE := 8
const BAG_SIZE := 30
const SIZE := HOTBAR_SIZE + BAG_SIZE

var slots: Array[Dictionary] = []


## `size` = how many slots (a player's bag is SIZE; chests and graves pick their own).
func _init(size: int = SIZE) -> void:
	slots.resize(size)
	for i in size:
		slots[i] = {}


## Adds items. Fills matching stacks first, then empty slots (hotbar first).
## Returns how many did NOT fit (0 = everything fit).
func add(id: String, count: int) -> int:
	if count <= 0 or not Items.exists(id):
		return count
	var left := count
	var max_stack := Items.stack_size(id)
	for s in slots:
		if left == 0:
			break
		if s.get("id", "") == id and s.count < max_stack:
			var room: int = max_stack - s.count
			var put := mini(room, left)
			s.count += put
			left -= put
	for i in slots.size():
		if left == 0:
			break
		if slots[i].is_empty():
			var put := mini(max_stack, left)
			slots[i] = {id = id, count = put}
			left -= put
	if left != count:
		changed.emit()
	return left


func count_of(id: String) -> int:
	var n := 0
	for s in slots:
		if s.get("id", "") == id:
			n += s.count
	return n


## Removes items. Takes from the bag before the hotbar. Returns false (and changes nothing) if there aren't enough.
func remove(id: String, count: int) -> bool:
	if count <= 0:
		return true
	if count_of(id) < count:
		return false
	var left := count
	for i in range(slots.size() - 1, -1, -1):
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


## Swaps two slots (dragging items around in the bag).
func swap(a: int, b: int) -> void:
	if a == b or a < 0 or b < 0 or a >= slots.size() or b >= slots.size():
		return
	var tmp := slots[a]
	slots[a] = slots[b]
	slots[b] = tmp
	changed.emit()


## Plain data, for sending over the network or saving later.
func to_data() -> Array:
	return slots.duplicate(true)


func load_data(data: Array) -> void:
	for i in slots.size():
		slots[i] = data[i].duplicate() if i < data.size() and data[i] is Dictionary else {}
	changed.emit()
