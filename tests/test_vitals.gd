extends TestCase


func _minutes(v: Vitals, m: float) -> void:
	for i in int(m * 60.0):
		v.tick(1.0)


func test_hunger_takes_about_40_minutes() -> void:
	var v := Vitals.new()
	_minutes(v, 30)
	check(v.hunger > 20 and v.hunger < 30, "after 30 min hunger is around 25 (got %.1f)" % v.hunger)
	_minutes(v, 10)
	check_near(v.hunger, 0.0, 0.5, "empty after 40 min")
	check(v.thirst <= 0.0, "thirst runs out a bit faster")


func test_never_dies_from_hunger() -> void:
	var v := Vitals.new()
	_minutes(v, 120)
	check_eq(v.health, Vitals.BASE_HEALTH, "2 hours starving: health still full")
	check(v.is_tired(), "but you are tired")
	check_near(v.max_stamina(), 80.0, 0.01, "tired = 20% less max stamina")


func test_resting_halves_drain() -> void:
	var a := Vitals.new()
	var b := Vitals.new()
	for i in 600:
		a.tick(1.0)
		b.tick(1.0, true)
	check_near(100.0 - b.hunger, (100.0 - a.hunger) * 0.5, 0.01, "half the hunger while resting")


func test_worse_meter_counts() -> void:
	var v := Vitals.new()
	v.hunger = 90
	v.thirst = 10
	check_eq(v.status(), "peckish", "thirsty counts even when full")
	check_near(v.health_regen_mult(), 0.75, 0.001, "slower healing")


func test_health_regen_waits_after_damage() -> void:
	var v := Vitals.new()
	v.take_damage(30)
	v.tick(5.0)
	check_eq(v.health, 70.0, "no healing in the first 6 s")
	v.tick(2.0)
	check(v.health > 70.0, "heals after 6 s")


func test_stamina_spend_and_regen() -> void:
	var v := Vitals.new()
	check(v.use_stamina(60), "can spend 60")
	check(not v.use_stamina(50), "can't spend 50 more")
	v.tick(0.5)
	check_eq(v.stamina, 40.0, "no regen right after use")
	v.tick(1.0)
	check(v.stamina > 40.0, "regen after 0.8 s")


func test_buff_food_raises_max_health() -> void:
	var v := Vitals.new()
	check(v.consume("dish_hollowcap_stew"), "eat stew")
	check_near(v.max_health(), 120.0, 0.01, "+20% max health")
	check_eq(v.buffs.size(), 1, "one buff")


func test_same_dish_refreshes_not_stacks() -> void:
	var v := Vitals.new()
	v.consume("dish_tuber_mash")
	v.tick(600)
	v.consume("dish_tuber_mash")
	check_eq(v.buffs.size(), 1, "still one slot")
	check_near(v.buffs[0].time_left, 30 * 60.0, 0.01, "timer refreshed")


func test_fourth_dish_replaces_least_time_left() -> void:
	var v := Vitals.new()
	v.consume("dish_glowcap_skewer")  # 25 min
	v.consume("dish_hearth_stew")  # 40 min
	v.consume("dish_tuber_mash")  # 30 min
	v.consume("dish_miners_pie")  # 35 min, replaces the skewer
	check_eq(v.buffs.size(), 3, "3 slots max")
	var ids := v.buffs.map(func(b): return b.id)
	check(not ids.has("dish_glowcap_skewer"), "the shortest one was replaced")


func test_buffs_run_out_and_clear_on_death() -> void:
	var v := Vitals.new()
	v.consume("dish_glowcap_skewer")
	v.tick(25 * 60 + 1)
	check(v.buffs.is_empty(), "buff gone after 25 min")
	v.consume("dish_jungle_pie")
	v.take_damage(500)
	check(v.is_dead(), "dead")
	v.respawn()
	check(v.buffs.is_empty(), "buffs end at death")
	check_eq(v.health, 100.0, "full health after waking up")


func test_raw_meat_can_upset_belly() -> void:
	var v := Vitals.new()
	v.consume("critter_meat", 0.1)
	check(v.upset_time > 0.0, "bad luck: upset belly")
	check_near(v.stamina_regen_mult(), 0.75, 0.001, "slower stamina regen")
	var w := Vitals.new()
	w.consume("critter_meat", 0.9)
	check_eq(w.upset_time, 0.0, "good luck: fine")


func test_not_food_is_refused() -> void:
	var v := Vitals.new()
	check(not v.consume("stone"), "can't eat stone")


func test_damage_reduction_food() -> void:
	var v := Vitals.new()
	v.consume("dish_chitin_crunch")
	v.take_damage(50)
	check_near(v.health, 55.0, 0.01, "10% less damage")


func test_network_roundtrip() -> void:
	var v := Vitals.new()
	v.consume("dish_bug_hotpot")
	v.take_damage(12)
	var w := Vitals.new()
	w.load_data(v.to_data())
	check_eq(w.health, v.health, "health copied")
	check_eq(w.buffs.size(), 1, "buff copied")
