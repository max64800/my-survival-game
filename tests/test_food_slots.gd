extends TestCase
## F426 (owner, Nov 23): eaten foods and the drink show as picture slots next to the health bar.


func test_food_slots_show_meals_and_drink() -> void:
	var v := Vitals.new()
	var row := FoodSlots.new()
	row.show_buffs(v)
	check_eq(row.slot_count(false), 2, "2 food slots")
	check_eq(row.slot_count(true), 1, "1 drink slot")
	check_eq(row.shown(), [{}, {}, {}], "all empty before eating")
	v.consume("dish_miners_pie")
	v.consume("drink_moss_ale")
	row.show_buffs(v)
	var s := row.shown()
	check_eq(s[0].get("id", ""), "dish_miners_pie", "the pie in the first food slot")
	check_eq(s[1], {}, "the second food slot still empty")
	check_eq(s[2].get("id", ""), "drink_moss_ale", "the ale in the drink slot")
	check_near(s[0].left, 1.0, 0.01, "full ring right after eating")
	v.tick(35 * 60 * 0.5)
	row.show_buffs(v)
	check_near(row.shown()[0].left, 0.5, 0.02, "half the ring after half the time")
	var src := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	check(src.contains("_food_slots.show_buffs(v)"), "the HUD fills the row every frame")
	check(not src.contains("for b in v.buffs:"), "foods are no longer text lines in the corner")
	row.free()
