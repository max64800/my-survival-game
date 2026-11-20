extends TestCase


func test_level_curve_matches_doc_table() -> void:
	# Rows from progression doc 7.3 (skipping level 1, which sits exactly on a .5 rounding edge).
	check_eq(Progression.xp_to_next(2), 710, "level 2 → 3")
	check_eq(Progression.xp_to_next(10), 1500, "level 10 → 11")
	check_eq(Progression.xp_to_next(20), 2810, "level 20 → 21")
	check_eq(Progression.xp_to_next(29), 4180, "level 29 → 30")
	check_near(Progression.total_xp_for_level(30), 64360, 40, "total XP to reach level 30")


func test_one_point_per_level() -> void:
	check_eq(Progression.points_for_level(1), 0, "level 1: no points")
	check_eq(Progression.points_for_level(5), 4, "level 5: 4 points")
	check_eq(Progression.points_for_level(30), 29, "level 30: 29 points")


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
	check_eq(p.points_free(), 29, "1 point per level: 29")


func test_perk_needs_points_and_the_perk_before() -> void:
	var p := Progression.new()
	check_eq(p.why_not("thick_skin"), "Not enough points.", "no points at level 1")
	p.add_xp(Progression.total_xp_for_level(6))  # level 6 = 5 points
	check(not p.buy_perk("iron_belly"), "Iron Belly needs Thick Skin first")
	check(p.why_not("iron_belly").begins_with("Needs Thick Skin"), "says why")
	check(p.buy_perk("thick_skin"), "buy Thick Skin")
	check(p.buy_perk("iron_belly"), "now Iron Belly opens")
	p.buy_perk("thick_skin")
	p.buy_perk("thick_skin")
	check_eq(p.why_not("thick_skin"), "Already maxed.", "3 ranks max")
	check_near(p.max_health_bonus(), 15.0, 0.0001, "+5 health per rank")
	check_eq(p.points_free(), 1, "4 of 5 points spent")


func test_respec_refunds_points() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
	p.buy_perk("thick_skin")
	p.buy_perk("iron_belly")
	check_eq(p.points_free(), 27, "spent 2")
	check_eq(p.respec_cost(), 30 * Progression.RESPEC_GOLD_PER_LEVEL, "reset costs gold by level")
	p.respec()
	check_eq(p.points_free(), 29, "all back")
	check_eq(p.perk_rank("thick_skin"), 0, "perk gone")


func test_every_perk_is_reachable() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
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
		check(Progression.PERKS[id][0] in Progression.BRANCHES, "%s is in a real branch" % id)
		check(Progression.PERKS[id][3] == Progression.ACTIVE.has(id), "%s: active perks have a recharge" % id)


func test_ability_keys_take_the_first_active_perks() -> void:
	var p := Progression.new()
	p.perks = {stone_stance = 1, war_horn = 1, whirlwind = 1, clan_banner = 1, thick_skin = 3}
	check_eq(p.ability_slots(), ["stone_stance", "whirlwind", "war_horn"], "3 keys, tree order, passives skipped")


func test_old_tree_perks_give_their_points_back() -> void:
	var p := Progression.new()
	p.add_xp(10_000_000)
	var d := p.to_data()
	d.p = {strong_swing = 3, thick_skin = 2}
	d.ps = 5
	p.load_data(d)
	check_eq(p.perk_rank("strong_swing"), 0, "old perk dropped")
	check_eq(p.perk_rank("thick_skin"), 2, "same-name perk kept")
	check_eq(p.points_free(), 27, "only the kept ranks still cost points")


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
	p.buy_perk("deep_pockets")
	var q := Progression.new()
	q.load_data(p.to_data())
	check_eq(q.level, p.level, "level copied")
	check_eq(q.perk_rank("deep_pockets"), 1, "perk copied")
	check_eq(q.points_free(), p.points_free(), "points copied")


func test_skills_list_and_info_match() -> void:
	check_eq(Progression.SKILLS.size(), 14, "14 skills (skills.md)")
	for sk in Progression.SKILLS:
		check(Progression.SKILL_INFO.has(sk) and Progression.SKILL_INFO[sk][2].size() == 4, "%s has 4 ★ perks" % sk)


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


func test_skill_level_bonuses() -> void:
	var p := Progression.new()
	p.skill_level.sword = 50
	check_near(p.attack_stamina_mult("sword"), 0.9, 0.0001, "Sword 50: 10% cheaper swings")
	check_near(p.attack_stamina_mult("mace"), 1.0, 0.0001, "the mace gets no stamina bonus")
	p.skill_level.mace = 100
	check_near(p.skill_armor_pierce("mace"), 0.30, 0.0001, "Mace 100: ignores 30% armor")
	p.skill_level.warhammer = 100
	check_near(p.skill_stun_mult("mace_2h"), 1.3, 0.0001, "Warhammer 100: +30% stun")
	p.skill_level.spear = 100
	check_near(p.reach_mult("spear"), 1.15, 0.0001, "Spear 100: +15% reach")
	p.skill_level.shield = 50
	check_near(p.block_bonus().block, 0.10, 0.0001, "Shield 50: blocks 10% more")
	p.skill_level.crossbow = 100
	check_near(p.crossbow_reload_mult(), 0.7 * 0.85, 0.0001, "Crossbow 100: −30% reload, ★50 −15% more")
	p.skill_level.cooking = 100
	check_near(p.craft_time_mult(true), 0.7, 0.0001, "Cooking 100: cooking 30% faster")


func test_star_perks() -> void:
	var p := Progression.new()
	check_near(p.star_damage_bonus("sword", {combo_step = 2}), 0.0, 0.0001, "no ★: nothing")
	p.skill_level.sword = 100
	check_near(p.star_damage_bonus("sword", {combo_step = 2}), 0.30, 0.0001, "Sword ★75: 3rd combo hit +30%")
	check(p.riposte_crits("sword"), "Sword ★100: the counter after a perfect parry is a critical")
	check_near(p.parry_mult("sword", false), 1.2, 0.0001, "Sword ★50: parry window +20%")
	p.skill_level.mace = 100
	check_near(p.star_damage_bonus("mace", {shelled = true, stunned = true}), 0.50, 0.0001, "Mace ★25 + ★100")
	p.skill_level.axe = 50
	check_eq(p.extra_targets("axe"), 1, "Axe ★50: hits 3 instead of 2")
	p.skill_level.jumping = 75
	check_near(p.star_damage_bonus("axe", {airborne = true}), 0.20, 0.0001, "Jumping ★75: +20% in the air")
	p.skill_level.mining = 25
	check_near(p.dig_swing_mult(false), 0.9, 0.0001, "Mining ★25: pickaxe swings 10% faster")
	p.skill_level.shield = 25
	check_near(p.guard_walk_mult(false), 0.8, 0.0001, "Shield ★25: walk faster while blocking")
	p.skill_level.crafting = 50
	check_near(p.save_material_chance(), 0.10, 0.0001, "Crafting ★50: 10% chance to save a material")


func test_kill_counts() -> void:
	var p := Progression.new()
	p.add_kill("cave_bat")
	p.add_kill("cave_bat")
	p.add_kill("rock_snail")
	check_eq(p.kills_of("cave_bat"), 2, "two bats")
	check_eq(p.kills_of("rock_beetle"), 0, "no beetles")
	check_eq(p.total_kills(), 3, "three in all")
	var q := Progression.new()
	q.load_data(p.to_data())
	check_eq(q.kills_of("cave_bat"), 2, "kills survive saving and the network")
	var old := p.to_data()
	old.erase("k")
	q.load_data(old)
	check_eq(q.total_kills(), 0, "saves from before kill counts still load")
