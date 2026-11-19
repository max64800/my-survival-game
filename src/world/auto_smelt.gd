class_name AutoSmelt
## Furnaces that run themselves (feedback F32):
##  - The Kiln turns wood from a chest within 5 m into Coal, and puts the coal in a chest.
##  - The Smelter takes ore (and clay) plus fuel (Coal first, then wood) from chests within 5 m,
##    smelts it, and puts the bars back in a chest. The Ore Crate counts as a chest.
##  - The Twin Smelter is half kiln, half smelter: one side smelts, the other makes coal.
## Only the host runs this, about once a second. Finished items that don't fit anywhere drop
## next to the furnace.

const RANGE := 5.0
const WOOD := ["rootwood", "mushroom_wood"]
const COAL_RECIPE := "coal"
## What a smelter makes by itself, in order of preference (copper first, it's what you need most).
const SMELTS := ["copper_ingot", "silver_ingot", "copper_from_scrap", "clay_brick"]
const KINDS := ["kiln", "smelter", "twin_smelter"]


## Host: start a job on this furnace if it's idle and nearby chests have what it needs.
## Returns the recipe id started ("" = nothing to do).
static func feed(st: Station, storage: Storage) -> String:
	if not st.kind in KINDS:
		return ""
	var chests := chests_near(st.global_position, storage)
	if chests.is_empty():
		return ""
	var slots := 2 if st.kind == "twin_smelter" else 1
	if st.jobs.size() >= slots:
		return ""  # busy (a furnace only starts a new batch when a side is free)
	if st.kind == "kiln":
		return _start(st, COAL_RECIPE, chests, storage, false)
	# Smelters: smelt if there's ore and fuel; the Twin Smelter makes coal with its other side.
	for id in SMELTS:
		if _start(st, id, chests, storage, true) != "":
			return id
	if st.kind == "twin_smelter" and not _has_job(st, "coal"):
		return _start(st, COAL_RECIPE, chests, storage, false)
	return ""


static func _has_job(st: Station, item: String) -> bool:
	for j in st.jobs:
		if j.item == item:
			return true
	return false


## The ids of every storage chest within reach (not graves or Builder's Chests), nearest first.
static func chests_near(pos: Vector3, storage: Storage) -> Array:
	var out := []
	for id in storage.boxes:
		var b: Dictionary = storage.boxes[id]
		if b.kind in ["grave", "builder"] or b.node == null:
			continue
		if (b.node as Node3D).global_position.distance_to(pos) <= RANGE:
			out.append(id)
	out.sort_custom(func(a: int, b: int) -> bool:
		return (storage.boxes[a].node as Node3D).global_position.distance_to(pos) < (storage.boxes[b].node as Node3D).global_position.distance_to(pos))
	return out


static func _count(chests: Array, storage: Storage, item: String) -> int:
	var n := 0
	for id in chests:
		n += (storage.boxes[id].inv as Inventory).count_of(item)
	return n


static func _take(chests: Array, storage: Storage, item: String, count: int) -> void:
	for id in chests:
		if count <= 0:
			return
		var inv: Inventory = storage.boxes[id].inv
		var n := mini(count, inv.count_of(item))
		if n > 0:
			inv.remove(item, n)
			storage._changed(id)
			count -= n


## Which fuel to burn: coal first (it burns twice as long), then wood. "" = none.
static func _fuel(chests: Array, storage: Storage, need: int) -> String:
	if _count(chests, storage, "coal") >= maxi(1, need / 2):
		return "coal"
	for w in WOOD:
		if _count(chests, storage, w) >= need:
			return w
	return ""


static func _start(st: Station, recipe_id: String, chests: Array, storage: Storage, fuelled: bool) -> String:
	var r := Recipes.get_recipe(recipe_id)
	if r.is_empty() or not st.can_queue():
		return ""
	for item in r.inputs:
		if _count(chests, storage, item) < r.inputs[item]:
			return ""
	var fuel := ""
	var need: int = r.get("fuel", 0)
	if fuelled and need > 0:
		fuel = _fuel(chests, storage, need)
		if fuel == "":
			return ""
	for item in r.inputs:
		_take(chests, storage, item, r.inputs[item])
	if fuel != "":
		_take(chests, storage, fuel, maxi(1, need / 2) if fuel == "coal" else need)
	st.queue_job(r.output, r.count, r.seconds)
	st.jobs[-1]["auto"] = true  # finished items go back into a chest
	return recipe_id


## Host: put a finished item into a chest near the furnace that takes it. Returns how many didn't fit.
static func store(st: Station, storage: Storage, item: String, count: int) -> int:
	for id in chests_near(st.global_position, storage):
		if count <= 0:
			break
		if Storage.accepts(storage.boxes[id].kind, item):
			count = storage.put(id, item, count)
	return count
