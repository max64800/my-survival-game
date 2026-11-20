class_name Crafting
## Crafting with a bag (and later, nearby chests). All-or-nothing: if anything is missing,
## or the result won't fit, nothing is taken.


static func missing(inv: Inventory, recipe_id: String, times: int = 1) -> Dictionary:
	var r := Recipes.get_recipe(recipe_id)
	var out := {}
	for item in r.get("inputs", {}):
		var need: int = r.inputs[item] * times
		var have := inv.count_of(item)
		if have < need:
			out[item] = need - have
	return out


static func can_craft(inv: Inventory, recipe_id: String) -> bool:
	var r := Recipes.get_recipe(recipe_id)
	return not r.is_empty() and missing(inv, recipe_id).is_empty() and _fits(inv, r)


## Crafts once. Returns true if it worked. Stations with a timer (smelter, pot) use this
## when their timer finishes; hand/workbench/anvil crafts call it right away.
static func craft(inv: Inventory, recipe_id: String) -> bool:
	if not can_craft(inv, recipe_id):
		return false
	var r := Recipes.get_recipe(recipe_id)
	for item in r.inputs:
		inv.remove(item, r.inputs[item])
	var left := inv.add(r.output, r.count)
	assert(left == 0, "checked room before crafting")
	return true


## Would the output fit after the inputs are taken out? (Inputs free up room.)
static func _fits(inv: Inventory, r: Dictionary) -> bool:
	var copy := Inventory.new(inv.slots.size())  # same size: a dwarf's copy keeps its equipment slots
	copy.load_data(inv.to_data())
	for item in r.inputs:
		copy.remove(item, r.inputs[item])
	return copy.add(r.output, r.count) == 0


## Auto-crafting (owner, Nov 19): what to make first so `recipe_id` can be made from what's in the bag.
## Only in-between recipes made at the same station count (`station` = the recipe's station type), and
## `usable(id)` says if the player may make one (unlocked, station level). Returns the recipe ids to make
## in order, the final one last; [] = can't be done. Skips recipes that need fuel.
static func plan(inv: Inventory, recipe_id: String, station: String, usable: Callable) -> Array:
	var counts := {}
	for s in inv.slots:
		if not s.is_empty():
			counts[s.id] = counts.get(s.id, 0) + int(s.count)
	var steps := []
	if not _need_inputs(recipe_id, counts, station, usable, steps, 0):
		return []
	steps.append(recipe_id)
	return steps


static func _need_inputs(recipe_id: String, counts: Dictionary, station: String, usable: Callable, steps: Array, depth: int) -> bool:
	var r := Recipes.get_recipe(recipe_id)
	for item in r.inputs:
		if not _take(item, int(r.inputs[item]), counts, station, usable, steps, depth):
			return false
	return true


static func _take(item: String, n: int, counts: Dictionary, station: String, usable: Callable, steps: Array, depth: int) -> bool:
	while counts.get(item, 0) < n:
		var maker := _maker_of(item, station, usable) if depth < 4 else ""
		if maker == "" or not _need_inputs(maker, counts, station, usable, steps, depth + 1):
			return false
		steps.append(maker)
		counts[item] = counts.get(item, 0) + int(Recipes.get_recipe(maker).count)
	counts[item] -= n
	return true


static func _maker_of(item: String, station: String, usable: Callable) -> String:
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		if r.output == item and r.station == station and int(r.get("fuel", 0)) == 0 and usable.call(id):
			return id
	return ""
