extends TestCase
## The dev "Test the dungeon" buttons' gear (owner, Nov 21: "I only have the spear and the mace": the worn sword only
## came out with F). Every kind of weapon the game has gets its own key 1-9, in copper (owner, Nov 20: silver was too strong).

const Start := preload("res://src/debug/dungeon_test_start.gd")


func test_every_weapon_kind_is_on_the_hotbar() -> void:
	var on_bar := {}
	check(Start.HOTBAR.size() <= Inventory.HOTBAR_SIZE, "the hotbar list fits keys 1-9")
	for it in Start.HOTBAR:
		check(Items.DATA.has(it[0]), "%s is a real item" % it[0])
		var d: Dictionary = Items.DATA.get(it[0], {})
		if d.get("kind", "") == "weapon":
			on_bar[d.weapon] = true
	var kinds := {}
	for id in Items.DATA:
		var d: Dictionary = Items.DATA[id]
		if d.get("kind", "") == "weapon":
			kinds[d.weapon] = true
	for w in kinds:
		check(on_bar.has(w), "a %s has its own hotbar key" % w)
	for it in Start.HOTBAR + Start.BAG:
		check(not String(it[0]).ends_with("_silver"), "%s: copper, not silver" % it[0])
	var bolts := false
	for it in Start.BAG:
		bolts = bolts or String(it[0]).begins_with("bolt_")
	check(bolts, "bolts for the crossbow (in the bag)")
