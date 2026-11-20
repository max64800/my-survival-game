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
	check_near(dmg, 10.0, 0.5, "1 stack: 1 damage/s for 10 s")
	check(not a.has("poison"), "it wears off")


func test_poison_stacks_up_to_3_and_fire_is_a_short_burst() -> void:
	var a := Ailments.new()
	for i in 5:
		a.add("poison", 100)
	check_eq(a.stacks_of("poison"), 3, "poison stacks up to 3")
	var dmg := 0.0
	for i in 120:
		dmg += a.tick(0.1)
	check_near(dmg, 30.0, 0.5, "3 stacks: 30 damage at most")
	var b := Ailments.new()
	b.add("burn", 100)
	dmg = 0.0
	for i in 80:
		dmg += b.tick(0.1)
	check_near(dmg, 15.0, 0.5, "fire: 3 damage/s for 5 s")
	check_eq(b.add("burn", 250), "burn", "250 buildup tips over twice")


func test_buildup_drains_when_quiet() -> void:
	var a := Ailments.new()
	a.add("poison", 50)
	a.tick(2.0)
	check_near(a.buildup.poison, 50.0, 0.01, "no draining in the first 3 s")
	for i in 30:
		a.tick(0.1)
	check(a.buildup.poison < 45.0, "then it drains")


func test_chill_stacks_freeze_and_fire_cancels_chill() -> void:
	var a := Ailments.new()
	a.add("chill", 100)
	check_near(a.speed_mult(), 0.9, 0.001, "1 chill stack: 10% slower")
	for i in 3:
		a.add("chill", 100)
	check_near(a.speed_mult(), 0.6, 0.001, "4 stacks: 40% slower")
	check(a.describe().has("Chilled x4 4 s"), "the screen shows the stacks")
	check_eq(a.add("chill", 100), "frozen", "the 5th stack: frozen")
	check_eq(a.speed_mult(), 0.0, "can't move")
	a.add("burn", 100)
	check(not a.has("chill") and not a.has("frozen"), "fire melts the ice")


func test_vitals_take_poison_damage_and_respawn_clears() -> void:
	var v := Vitals.new()
	v.ailments.add("poison", 100)
	for i in 50:
		v.tick(0.1)
	check(v.health < 96.0, "poison hurts over time (%.1f)" % v.health)
	v.respawn()
	check(not v.ailments.has("poison"), "waking up clears it")


func test_jungle_attacks_poison() -> void:
	# (Nov 19: the poisonous jungle creatures were taken out; the Blight-crested crystal kind brings the poison now.)
	check(Monsters.VARIANTS.green.buildup.has("poison"), "Blight-crested creatures carry poison")
	check(Monsters.VARIANT_CHANCE.fungal[1].get("green", 0.0) > 0.0, "and they live in the jungle")


func test_badges_above_the_health_bar() -> void:
	var row := AilmentBadges.new()
	tree.root.add_child(row)
	var a := Ailments.new()
	a.add("poison", 200)
	a.add("burn", 100)
	row.show_ailments(a)
	check_eq(row._badges.size(), 2, "a badge for poison and one for fire")
	check_eq(row._badges.poison._stacks, 2, "poison shows its 2 stacks")
	a.tick(6.0)
	row.show_ailments(a)
	check(not row._badges.has("burn"), "fire ran out: its badge is gone")
	check_near(row._badges.poison._left, 0.4, 0.01, "poison's ring: 4 of 10 s left")
	check(a.describe(false).is_empty(), "the text line no longer repeats the badges")
	row.queue_free()
