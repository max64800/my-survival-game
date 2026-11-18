extends TestCase


func test_level_curve_matches_doc_table() -> void:
	# Rows from progression doc 7.3 (skipping level 1, which sits exactly on a .5 rounding edge).
	check_eq(Progression.xp_to_next(2), 710, "level 2 → 3")
	check_eq(Progression.xp_to_next(10), 1500, "level 10 → 11")
	check_eq(Progression.xp_to_next(20), 2810, "level 20 → 21")
	check_eq(Progression.xp_to_next(29), 4180, "level 29 → 30")
	check_near(Progression.total_xp_for_level(30), 64360, 40, "total XP to reach level 30")


func test_points_with_bonus_levels() -> void:
	check_eq(Progression.points_for_level(1), 0, "level 1: no points")
	check_eq(Progression.points_for_level(5), 5, "level 5: 4 + 1 bonus")
	check_eq(Progression.points_for_level(30), 35, "level 30: 35 points")


func test_skill_curve_total() -> void:
	var t := 0
	for n in 100:
		t += Progression.skill_xp_to_next(n)
	check_eq(t, roundi(41.0 * Progression.XP_PER_HOUR), "total skill XP to 100 = about 41 hours of work")
	check(Progression.skill_xp_to_next(95) > 10 * Progression.skill_xp_to_next(5), "high levels take much longer")


func test_xp_goes_to_skill_and_level() -> void:
	var p := Progression.new()
	p.add_xp(6, "mining")
	check_eq(p.skill_xp.mining, 6, "skill got it")
	check_eq(p.xp, 6, "character got it")
	p.add_xp(100)
	check_eq(p.skill_xp.mining, 6, "character-only XP doesn't touch skills")


func test_level_up_signal_and_carry_over() -> void:
	var p := Progression.new()
	var ups := []
	p.leveled_up.connect(func(l): ups.append(l))
	p.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2) + 5)
	check_eq(p.level, 3, "two level ups at once")
	check_eq(ups, [2, 3], "signal for each")
	check_eq(p.xp, 5, "leftover kept")


func test_level_cap() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
	check_eq(p.level, Progression.MAX_LEVEL, "stops at 30")
	check_eq(p.points_free(), 35, "35 points")


func test_perk_needs_skill_and_points() -> void:
	var p := Progression.new()
	check_eq(p.why_not("strong_swing"), "Not enough points.", "no points at level 1")
	p.add_xp(Progression.total_xp_for_level(6))  # level 6 = 6 points
	check(p.buy_perk("strong_swing"), "buy strong swing")
	check(not p.buy_perk("light_arms"), "light arms needs Mining 5")
	check(p.why_not("light_arms").begins_with("Needs Mining"), "says why")
	for i in 600:
		p.add_xp(2, "mining")
	check(p.skill_level.mining >= 5, "mined up to skill 5+ (got %d)" % p.skill_level.mining)
	check(p.buy_perk("light_arms"), "now light arms works")


func test_perk_prerequisite_and_ranks() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
	p.skill_level.mining = 100
	check(not p.buy_perk("lucky_strike"), "needs strong swing first")
	p.buy_perk("strong_swing")
	check(p.buy_perk("lucky_strike"), "now ok")
	p.buy_perk("strong_swing")
	p.buy_perk("strong_swing")
	check_eq(p.why_not("strong_swing"), "Already maxed.", "3 ranks max")
	check_near(p.dig_power_mult(), 1.3 * 1.15, 0.0001, "skill 100 + 3 ranks")


func test_respec_refunds_points() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
	p.buy_perk("thick_skin")
	p.buy_perk("iron_belly")
	check_eq(p.points_free(), 33, "spent 2")
	p.respec()
	check_eq(p.points_free(), 35, "all back")
	check_eq(p.perk_rank("thick_skin"), 0, "perk gone")


func test_every_perk_is_reachable() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
	for s in Progression.SKILLS:
		p.skill_level[s] = 100
	var bought := true
	var guard := 0
	while bought and guard < 200:
		bought = false
		guard += 1
		for id in Progression.PERKS:
			if p.why_not(id) == "":
				p.buy_perk(id)
				bought = true
		p._points_spent = 0  # pretend infinite points to test the requirement chain
	for id in Progression.PERKS:
		check_eq(p.perk_rank(id), Progression.PERKS[id][1], "%s reachable to max" % id)


func test_quality_table_rows_add_to_100() -> void:
	for row in Progression.QUALITY_TABLE:
		var s := 0
		for i in range(1, 6):
			s += row[i]
		check_eq(s, 100, "row for smithing %d" % row[0])


func test_quality_roll() -> void:
	check_eq(Progression.roll_quality(0, 0.0), 1, "low roll, new smith: Q1")
	check_eq(Progression.roll_quality(0, 0.99), 3, "best roll, new smith: Q3")
	check_eq(Progression.roll_quality(100, 0.99), 5, "master smith can make Q5")
	check_eq(Progression.roll_quality(100, 0.0), 2, "master smith never makes Q1")
	check_near(Progression.quality_bonus(5), 0.20, 0.0001, "Q5 = +20%")


func test_network_roundtrip() -> void:
	var p := Progression.new()
	p.add_xp(5000, "crafting")
	p.buy_perk("steady_hammer")
	var q := Progression.new()
	q.load_data(p.to_data())
	check_eq(q.level, p.level, "level copied")
	check_eq(q.perk_rank("steady_hammer"), 1, "perk copied")
	check_eq(q.points_free(), p.points_free(), "points copied")


func test_skills_list_and_info_match() -> void:
	check_eq(Progression.SKILLS.size(), 14, "14 skills (skills.md)")
	for sk in Progression.SKILLS:
		check(Progression.SKILL_INFO.has(sk) and Progression.SKILL_INFO[sk][2].size() == 4, "%s has 4 ★ perks" % sk)
	for br in Progression.BRANCH_SKILLS:
		for sk in Progression.BRANCH_SKILLS[br]:
			check(sk in Progression.SKILLS, "branch %s uses a real skill (%s)" % [br, sk])


func test_weapons_train_their_skill() -> void:
	check_eq(Progression.weapon_skill("mace_2h"), "warhammer", "two-handed mace = Warhammer")
	check_eq(Progression.weapon_skill("axe_2h"), "axe", "two-handed axe = Axe")
	check_eq(Progression.weapon_skill("pickaxe"), "", "pickaxe trains no weapon skill")
	var p := Progression.new()
	p.skill_level.mace = 50
	check_near(p.weapon_damage_bonus("mace"), 0.10, 0.0001, "Mace 50: +10% damage")
	check_near(p.weapon_damage_bonus("sword"), 0.0, 0.0001, "other weapons don't get it")


func test_stars_and_branches() -> void:
	var p := Progression.new()
	p.skill_level.mining = 49
	check(p.has_star("mining", 25) and not p.has_star("mining", 50), "★25 yes, ★50 not yet")
	p.skill_level.spear = 30
	check_eq(p.branch_level("fighting"), 30, "Warrior branch counts the best weapon")
	check_near(p.run_speed_mult(), 1.0, 0.0001, "Running 0: no bonus")
	p.skill_level.running = 100
	check_near(p.run_speed_mult(), 1.2, 0.0001, "Running 100: +20% speed")


func test_old_four_skill_save_carries_over() -> void:
	var q := Progression.new()
	q.load_data({l = 5, x = 10, sl = {mining = 12, fighting = 20, smithing = 7, survival = 9},
		sx = {mining = 30, fighting = 1, smithing = 2, survival = 3}, p = {}, ps = 0})
	check_eq(q.skill_level.mining, 12, "Mining kept")
	check_eq(q.skill_xp.mining, 30, "Mining XP kept")
	check_eq(q.skill_level.sword, 20, "old Fighting became Sword")
	check_eq(q.skill_level.crafting, 7, "old Smithing became Crafting")
	check_eq(q.skill_level.cooking, 9, "old Survival became Cooking")
	check_eq(q.skill_level.woodcutting, 9, "... and Woodcutting")
	check_eq(q.skill_level.running, 0, "new skills start at 0")
	check(not q.skill_level.has("fighting"), "old names are gone")
