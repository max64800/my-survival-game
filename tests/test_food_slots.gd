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


## F824 + F827 (owner, Nov 23): the host refuses a meal when that row is full, Gutweed Tea empties it,
## and a right-click in the bag eats the food in that slot.
func test_host_refuses_full_belly_and_bag_right_click_eats() -> void:
	var ps := GameAuthority.PlayerState.new()
	ps.meals = {dish_glowcap_skewer = 1e9, dish_hearth_stew = 1e9}
	check(not ps.meal_fits("dish_miners_pie", 0.0), "2 foods eaten: a 3rd is refused")
	check(ps.meal_fits("dish_hearth_stew", 0.0), "the same dish again is fine")
	check(ps.meal_fits("drink_moss_ale", 0.0), "the drink slot is still free")
	ps.meals = {dish_glowcap_skewer = 5.0, dish_hearth_stew = 1e9}
	check(ps.meal_fits("dish_miners_pie", 10.0), "a meal that wore off frees its slot")
	check(Recipes.LIST.has("drink_gutweed_tea"), "Gutweed Tea can be made")
	check(Items.icon("drink_gutweed_tea") != null, "Gutweed Tea has a picture")
	var auth_src := FileAccess.get_file_as_string("res://src/net/game_authority.gd")
	check("ps.meals.clear()" in auth_src and "func request_eat(" in auth_src, "the tea clears the host's list and the bag can eat")
	var hud_src := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	check("auth.ask_eat(index)" in hud_src, "right-click in the bag eats")
