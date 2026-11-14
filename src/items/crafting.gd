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
