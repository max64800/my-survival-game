extends TestCase
## F594 Step 1: Valheim-style stun meter. Stun fill = weapon base damage × tier × combo mult × stun type factor.
## Counts hits-to-stun per weapon vs each monster at tier 1 (iron).


## Count sword (or any weapon) hits until the stun meter fills. Returns hit count (capped at 20).
func _hits_to_stun(weapon: String, heavy: bool, tier: int, stun_max: float) -> int:
	var meter := StunMeter.new(stun_max, 3.0)
	var combo_size: int = (Combat.WEAPONS[weapon].combo as Array).size()
	var hits := 0
	while not meter.is_stunned() and hits < 20:
		meter.add(Combat.stun_value(weapon, heavy, tier, hits % combo_size))
		hits += 1
	return hits if meter.is_stunned() else -1


# ------------------------------------------------------------------ lost_miner (skeleton, hp 110, stun 50)

func test_sword_stuns_skeleton_in_full_combo() -> void:
	var hits := _hits_to_stun("sword", false, 1, Monsters.info("lost_miner").stun)
	check_eq(hits, 3, "iron sword stuns the skeleton in exactly 3 light hits (one full combo)")


func test_mace_stuns_skeleton_before_finisher() -> void:
	var hits := _hits_to_stun("mace", false, 1, Monsters.info("lost_miner").stun)
	check_eq(hits, 3, "iron mace stuns the skeleton in 3 of 4 hits (~75% of combo, before the finisher)")


func test_spear_needs_more_hits_than_sword_on_skeleton() -> void:
	var spear := _hits_to_stun("spear", false, 1, Monsters.info("lost_miner").stun)
	var sword := _hits_to_stun("sword", false, 1, Monsters.info("lost_miner").stun)
	check(spear > sword, "pierce factor (0.8) means the spear needs more hits than the sword to stun")


# ------------------------------------------------------------------ rock_beetle (hp 100, stun 45)

func test_sword_stuns_beetle_in_full_combo() -> void:
	var hits := _hits_to_stun("sword", false, 1, Monsters.info("rock_beetle").stun)
	check_eq(hits, 3, "iron sword stuns the rock beetle in one full 3-hit combo")


func test_mace_stuns_beetle_fast() -> void:
	var hits := _hits_to_stun("mace", false, 1, Monsters.info("rock_beetle").stun)
	check(hits <= 2, "blunt weapon stuns the beetle in at most 2 hits (beetles are soft to blunt)")


# ------------------------------------------------------------------ cave_spider (hp 30, stun 13)

func test_sword_one_hit_stuns_spider() -> void:
	var hits := _hits_to_stun("sword", false, 1, Monsters.info("cave_spider").stun)
	check_eq(hits, 1, "one iron sword hit stuns the fragile cave spider")


func test_mace_one_hit_stuns_spider() -> void:
	var hits := _hits_to_stun("mace", false, 1, Monsters.info("cave_spider").stun)
	check_eq(hits, 1, "one iron mace hit stuns the cave spider")


# ------------------------------------------------------------------ stun meter thresholds

func test_normal_stun_max_is_about_45_pct_hp() -> void:
	for kind in ["rock_beetle", "cave_spider", "lost_miner"]:
		var d := Monsters.info(kind)
		var pct := float(d.stun) / float(d.hp)
		check(pct >= 0.40 and pct <= 0.50,
			"%s stun max is ~45%% of hp (got %.0f%%" % [kind, pct * 100])


func test_boss_stun_harder_than_normal() -> void:
	var normal_pct := float(Monsters.info("lost_miner").stun) / float(Monsters.info("lost_miner").hp)
	var boss_pct := float(Monsters.info("foreman").stun) / float(Monsters.info("foreman").hp)
	check(boss_pct > normal_pct * 1.5, "boss stun threshold is much higher % of HP than a normal enemy")


func test_blunt_factor_higher_than_slash_higher_than_pierce() -> void:
	check(Combat.STUN_FACTOR.blunt > Combat.STUN_FACTOR.slash, "blunt > slash stun factor")
	check(Combat.STUN_FACTOR.slash > Combat.STUN_FACTOR.pierce, "slash > pierce stun factor")
