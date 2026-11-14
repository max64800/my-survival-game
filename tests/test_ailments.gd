extends TestCase
## Poison, burn and chill on a dwarf (combat doc 2.6).


func test_buildup_tips_over_into_poison() -> void:
	var a := Ailments.new()
	check_eq(a.add("poison", 60), "", "60 isn't enough")
	check_eq(a.add("poison", 45), "poison", "105 tips it over")
	check(a.has("poison") and a.blocks_regen(), "poisoned, no healing")
	var dmg := 0.0
	for i in 120:
		dmg += a.tick(0.1)
	check_near(dmg, 30.0, 0.5, "3 damage/s for 10 s")
	check(not a.has("poison"), "it wears off")


func test_buildup_drains_when_quiet() -> void:
	var a := Ailments.new()
	a.add("poison", 50)
	a.tick(2.0)
	check_near(a.buildup.poison, 50.0, 0.01, "no draining in the first 3 s")
	for i in 30:
		a.tick(0.1)
	check(a.buildup.poison < 45.0, "then it drains")


func test_chill_twice_freezes_and_fire_cancels_chill() -> void:
	var a := Ailments.new()
	a.add("chill", 100)
	check_near(a.speed_mult(), 0.75, 0.001, "chilled: 25% slower")
	check_eq(a.add("chill", 100), "frozen", "chilled again: frozen")
	check_eq(a.speed_mult(), 0.0, "can't move")
	a.add("burn", 100)
	check(not a.has("chill") and not a.has("frozen"), "fire melts the ice")


func test_vitals_take_poison_damage_and_respawn_clears() -> void:
	var v := Vitals.new()
	v.ailments.add("poison", 100)
	for i in 50:
		v.tick(0.1)
	check(v.health < 90.0, "poison hurts over time (%.1f)" % v.health)
	v.respawn()
	check(not v.ailments.has("poison"), "waking up clears it")


func test_jungle_attacks_poison() -> void:
	var poisonous := 0
	for id in Monsters.LIST:
		for a in Monsters.LIST[id].attacks:
			if a.get("buildup", {}).has("poison") or a.has("cloud"):
				poisonous += 1
	check(poisonous >= 3, "jungle monsters carry poison")
