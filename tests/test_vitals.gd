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


func test_heals_one_health_every_five_seconds() -> void:
	var v := Vitals.new()
	v.hunger = 50.0  # normal (well fed heals 20% faster)
	v.thirst = 50.0
	v.take_damage(50)
	v.tick(5.99)  # the wait after a hit
	v.tick(30.0)
	check_near(v.health, 56.0, 0.5, "30 s of healing = 6 health: 1 every 5 s (owner, Nov 19)")


func test_no_healing_in_the_dark() -> void:
	var v := Vitals.new()
	v.take_damage(50)
	v.in_dark = true
	v.tick(60.0)
	check_eq(v.health, 50.0, "no healing at all in the dark (F293)")
	v.in_dark = false
	v.tick(3.0)
	check(v.health > 50.0, "heals again in the light")


func test_stamina_costs_more_in_the_dark() -> void:
	var v := Vitals.new()
	v.in_dark = true
	check(v.use_stamina(20), "can still swing")
	check_near(v.stamina, 70.0, 0.01, "a 20 swing costs 30 in the dark (F293)")
	v.drain_stamina(10.0, 1.0)
	check_near(v.stamina, 55.0, 0.01, "running drains 50% faster too")


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
	check(v.consume("dish_snail_stew"), "eat stew")
	check_near(v.max_health(), 120.0, 0.01, "+20% max health")
	check_eq(v.buffs.size(), 1, "one buff")


func test_same_dish_refreshes_not_stacks() -> void:
	var v := Vitals.new()
	v.consume("dish_tuber_mash")
	v.tick(600)
	v.consume("dish_tuber_mash")
	check_eq(v.buffs.size(), 1, "still one slot")
	check_near(v.buffs[0].time_left, 25 * 60.0, 0.01, "timer refreshed")


func test_two_foods_and_one_drink() -> void:
	var v := Vitals.new()
	v.consume("dish_glowcap_skewer")  # 15 min
	v.consume("dish_hearth_stew")  # 35 min
	v.consume("drink_moss_ale")  # the drink has its own slot
	check_eq(v.buffs.size(), 3, "2 foods + 1 drink")
	v.consume("dish_miners_pie")  # a 3rd food replaces the food with the least time left
	var ids := v.buffs.map(func(b): return b.id)
	check(not ids.has("dish_glowcap_skewer") and ids.has("drink_moss_ale"), "the skewer went, the drink stayed")
	v.consume("drink_glowcap_tea")
	ids = v.buffs.map(func(b): return b.id)
	check(ids.has("drink_glowcap_tea") and not ids.has("drink_moss_ale"), "a new drink replaces the old drink")


func test_food_speeds_up_healing_to_the_cap() -> void:
	var v := Vitals.new()
	check_near(v.regen_per_second() / v.health_regen_mult(), 0.2, 0.0001, "on your own: 1 health every 5 s")
	v.consume("dish_cooked_snail")
	check_near(v.regen_per_second() / v.health_regen_mult(), 0.22, 0.0001, "a campfire meal: a little faster")
	v.consume("dish_hearth_stew")
	v.consume("dish_miners_pie")
	v.consume("drink_moss_ale")
	check_near(v.regen_per_second() / v.health_regen_mult(), Vitals.REGEN_CAP, 0.0001, "the best meals: 1 every 2 s, never faster")
	check_eq(Foods.heart_halves(0.02), 1, "campfire meal = half a heart")
	check_eq(Foods.heart_halves(0.15), 2, "Old Hearth Stew = a whole heart")


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
	v.consume("bat_meat", 0.1)
	check(v.upset_time > 0.0, "bad luck: upset belly")
	check_near(v.stamina_regen_mult(), 0.75, 0.001, "slower stamina regen")
	var w := Vitals.new()
	w.consume("bat_meat", 0.9)
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


func test_meat_guards_and_bullet_lines() -> void:
	check_eq(Monsters.food_guard("cave_bat"), "bat", "bats")
	check_eq(Monsters.food_guard("great_rock_beetle"), "beetle", "beetles")
	var v := Vitals.new()
	v.consume("dish_seared_critter")
	check_near(v.buff_total("guard_bat"), 0.15, 0.0001, "Seared Bat: 15% less from bats")
	v.consume("dish_hearth_stew")
	check_near(v.buff_total("guard_bat"), 0.35, 0.0001, "two bat dishes add up")
	var lines := Foods.effect_lines("dish_hearth_stew")
	check(lines.has("take 20% less from bats") and lines[-1] == "lasts 35 min", "bullets, and how long it lasts at the end")


func test_second_wind() -> void:
	var v := Vitals.new()
	v.progress = Progression.new()
	v.progress.skill_level.running = 100
	v.stamina = 0.0
	v.tick(0.1)
	check(v.stamina >= v.max_stamina() * 0.25, "Running ★100: a quarter of your stamina comes back")
	v.stamina = 0.0
	v.tick(0.1)
	check(v.stamina < v.max_stamina() * 0.25, "only once every 2 minutes")


## Dev god mode (F9, owner Nov 20: "not killable and not agro mobs"): nothing hurts you, health stays full, and
## monsters leave you alone (like dev fly).
func test_god_mode_cannot_be_hurt_and_monsters_ignore_you() -> void:
	var v := Vitals.new()
	v.god = true
	check(not v.take_damage(9999.0), "a huge hit doesn't kill in god mode")
	check_eq(v.health, v.max_health(), "health stays full")
	v.hunger = 0.0
	v.thirst = 0.0
	for i in 600:
		v.tick(1.0)
	check_eq(v.health, v.max_health(), "no starving down either")
	var d := Dwarf.new()
	check(not MonsterManager.ignores(d), "monsters see a normal dwarf")
	d.dev_god = true
	check(MonsterManager.ignores(d), "monsters ignore a dwarf in god mode")
	d.free()


func test_hunger_and_thirst_dials_show_painted_pictures() -> void:
	# F638: the dials use the painted stew bowl and water drop, not shapes drawn by code.
	var script := load("res://src/ui/vital_dial.gd")
	for kind in ["hunger", "thirst"]:
		var tex: Texture2D = script.PICTURES.get(kind)
		check(tex != null and tex.get_width() == 128, "%s dial has its 128 px painted picture" % kind)
