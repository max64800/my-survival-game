extends TestCase
## Fighting rules, checked against the worked examples in the combat doc.

const CAIRNLING := {armor = 40, slash = 0.5, blunt = 1.5, pierce = 0.75, fire = 0.5, frost = 0.5, poison = 1.0}


func test_doc_example_copper_mace_on_cairnling() -> void:
	# Doc 2.2: Copper mace heavy on a Cairnling = 38.
	check_eq(Combat.damage("mace", true, 1, CAIRNLING), 38, "copper mace heavy vs cairnling")


func test_doc_example_copper_sword_on_cairnling() -> void:
	# Doc 2.2: the same hit with a sword = 10 (slash is bad against stone).
	check_eq(Combat.damage("sword", true, 1, CAIRNLING), 10, "copper sword heavy vs cairnling")


func test_silver_sword_light_on_nothing() -> void:
	# Doc 3.4: Silver sword light = 16.5 → 17.
	check_eq(Combat.damage("sword", false, 2, {}), 17, "silver sword light")


func test_armor_halves_at_100() -> void:
	check_eq(Combat.damage("sword", false, 0, {armor = 100}), 5, "100 armor = half")


func test_minimum_one_damage() -> void:
	check_eq(Combat.damage("fists", false, 0, {armor = 1000, blunt = 0.1}), 1, "never zero")


func test_situations_dont_stack() -> void:
	check_eq(Combat.situation(true, true, false, true), 2.0, "sneak beats stunned and riposte")
	check_eq(Combat.situation(false, true, true, false), 2.0, "crush replaces stunned")
	check_eq(Combat.situation(false, false, false, true), 1.3, "riposte alone")


func test_combo_finisher_hits_harder() -> void:
	var first := Combat.damage("sword", false, 0, {}, 0)
	var third := Combat.damage("sword", false, 0, {}, 2)
	check(third > first, "3rd sword hit (thrust) is stronger: %d vs %d" % [third, first])


func test_elemental_skips_armor() -> void:
	var plain := Combat.damage("sword", false, 0, {armor = 100})
	var with_fire := Combat.damage("sword", false, 0, {armor = 100}, 0, 1.0, 0, 0, 0, {fire = 8})
	check_eq(with_fire - plain, 8, "fire adds its full 8 despite armor")
	check_eq(Combat.damage("sword", false, 0, {fire = 0.5}, 0, 1.0, 0, 0, 0, {fire = 8}) - Combat.damage("sword", false, 0, {}), 4, "50% fire resist")


func test_parry_block_hit() -> void:
	var p := Combat.defend(20, 0.1, true, "sword", false, 0)
	check_eq(p.result, "parry", "sword parry inside 180 ms")
	check_eq(p.damage, 0.0, "no damage on a parry")
	check_eq(p.stun, Combat.STUN_WEAPON_PARRY, "weapon parry stun")
	var late := Combat.defend(20, 0.25, true, "sword", false, 0)
	check_eq(late.result, "block", "250 ms early is just a block")
	check_near(late.damage, 13.0, 0.01, "sword blocks 35%")
	check_eq(late.stamina, 20.0, "weapon block costs the full hit in stamina")
	var shield := Combat.defend(20, 0.19, true, "sword", true, 1)
	check_eq(shield.result, "parry", "shield window is 200 ms")
	check_eq(shield.stun, Combat.STUN_SHIELD_PARRY, "shield parry stuns more")
	check_eq(Combat.defend(20, -1, false, "sword", false, 0).result, "hit", "not blocking = hit")


func test_crushing_needs_a_shield() -> void:
	check_eq(Combat.defend(24, 0.05, true, "sword", false, 0, true).result, "block", "sword can't parry a crushing attack")
	check_eq(Combat.defend(24, 0.05, true, "sword", true, 0, true).result, "parry", "shield can")


func test_stun_meter() -> void:
	var m := StunMeter.new(60, 3.0)
	check(not m.add(25), "one parry isn't enough")
	check(not m.add(25), "two parries aren't either")
	check(m.add(25), "third fills it: stunned")
	check(m.is_stunned(), "dazed")
	check(m.take_crush(), "first heavy = crush")
	check(not m.take_crush(), "only once")
	check(not m.add(100), "can't add while stunned")
	m.tick(3.1)
	check(not m.is_stunned(), "stun wore off")
	check(not m.add(100), "2 s of immunity after a stun")
	m.tick(2.1)
	m.add(30)
	m.tick(2.0)
	check_near(m.value, 30.0, 0.01, "no drain in the first 2.5 s")
	m.tick(1.5)
	check(m.value < 30.0, "then it drains")


func test_boss_gets_harder_to_stun() -> void:
	var b := StunMeter.new(100, 5.0, true)
	b.add(100)
	check_near(b.max_value, 130.0, 0.01, "+30% after each stun")
