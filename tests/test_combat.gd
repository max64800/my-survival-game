extends TestCase
## Fighting rules, checked against the worked examples in the combat doc.

## The combat doc's worked example: a stone creature with 40 armor (doc 2.2).
const STONE_40 := {armor = 40, slash = 0.5, blunt = 1.5, pierce = 0.75, fire = 0.5, frost = 0.5, poison = 1.0}


func test_doc_example_copper_mace_on_stone() -> void:
	# Doc 2.2: Copper mace heavy on a 40-armor stone creature = 38; 35 since F532 (chat 16: armor piercing moved from
	# the mace to the spear and crossbow).
	check_eq(Combat.damage("mace", true, 1, STONE_40), 35, "copper mace heavy vs stone")


func test_doc_example_copper_sword_on_stone() -> void:
	# Doc 2.2: the same hit with a sword = 10 (slash is bad against stone).
	check_eq(Combat.damage("sword", true, 1, STONE_40), 10, "copper sword heavy vs stone")


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


## Owner, chat 16: "the end of the combo damage really good, progressively better and better".
func test_combos_build_up_to_a_big_last_hit() -> void:
	for w in ["sword", "axe", "mace", "spear", "axe_2h", "mace_2h"]:
		var combo: Array = Combat.WEAPONS[w].combo
		for i in range(1, combo.size()):
			check(combo[i] > combo[i - 1], "%s: hit %d stronger than hit %d" % [w, i + 1, i])
		check(combo[-1] >= 1.8, "%s: the last hit does at least 1.8x (%.2f)" % [w, combo[-1]])


## Owner, chat 16: "the spear does two hits and then a spin attack".
func test_spear_two_thrusts_then_a_spin() -> void:
	var moves: Array = DwarfRig.ATTACKS.spear[0]
	check_eq(moves.size(), Combat.WEAPONS.spear.combo.size(), "one move per combo hit")
	check_eq(moves.size(), 3, "3 hits")
	check(moves[0] == "stab" and moves[1] == "stab", "two thrusts first")
	check_eq(moves[DwarfFight.SPEAR_SPIN_STEP], "ual_heavy", "then the spin (UAL 2's hit C)")
	check(DwarfRig.attack_seconds("spear", false, 2, 0.6) > 0.6, "the spin takes its own (longer) time")


## Owner, chat 17: the great maul is "left click, left click, right click": side swing, head shove, then a whirl
## you can still walk (slower) in.
func test_great_maul_slice_shove_then_whirl() -> void:
	var a: Array = DwarfRig.ATTACKS.mace_2h
	check_eq(a[0], ["great_slice", "great_shove"], "left clicks: side swing, then head shove")
	check_eq(a[1], "great_whirl", "right click: the whirl")
	for k in a[0] + [a[1]]:
		var mv := String(DwarfRig.ANIMS[k]).trim_prefix("g/")
		check(DwarfGreatSwing.MOVES.has(mv), "%s is a baked great move (%s)" % [k, mv])
	check(DwarfGreatSwing.LOOPS.get("Spinning", 0) >= 2, "the whirl turns round more than once")
	check(DwarfFight.WHIRL_WALK > 0.2 and DwarfFight.WHIRL_WALK < 1.0, "walk during the whirl, but slower")


## Owner, chat 16: stone swords/maces/spears have no finisher, stone great weapons no heavy; the finisher Crushes.
func test_stone_has_no_finisher_and_no_heavy() -> void:
	for w in ["sword", "mace", "spear"]:
		var n: int = Combat.WEAPONS[w].combo.size()
		check_eq(Combat.combo_hits(w, 0), n - 1, "stone %s: no finisher" % w)
		check_eq(Combat.combo_hits(w, 1), n, "copper %s: the whole combo" % w)
		check(not Combat.is_finisher(w, 0, n - 1) and Combat.is_finisher(w, 1, n - 1), "%s: only copper's last hit is a finisher" % w)
	for w in ["axe_2h", "mace_2h"]:
		check(not Combat.has_heavy(w, 0) and Combat.has_heavy(w, 1), "%s: heavy spin from copper up" % w)
		check_eq(Combat.combo_hits(w, 0), Combat.WEAPONS[w].combo.size(), "stone %s keeps its whole combo" % w)
	check(not Combat.has_heavy("sword", 1), "one-handed: never a heavy")


## Owner, chat 16: grey numbers = resists the damage type, white = normal, yellow = weak to it.
func test_hit_number_colour_follows_the_damage_type() -> void:
	var beetle := {slash = 0.75, blunt = 1.25, pierce = 1.0}
	check_eq(Combat.effect("slash", beetle), -1, "slash on a beetle: grey")
	check_eq(Combat.effect("pierce", beetle), 0, "pierce: white")
	check_eq(Combat.effect("blunt", beetle), 1, "blunt: yellow")


## F532 (owner, chat 16): armor only on elites and bosses; more health per extra player (boss 75%, elite 50%, the
## rest 30%); the spear and crossbow pierce armor, the mace stuns more instead.
func test_balance_plan_f532() -> void:
	check_eq(Monsters.rank("cave_spider", false), "normal", "a spider is normal")
	check_eq(Monsters.rank("cave_spider", true), "elite", "a pack leader is an elite")
	check_eq(Monsters.rank("cave_spider", false, "red"), "elite", "a crested one is an elite")
	check_eq(Monsters.rank("great_rock_beetle", false), "elite", "the Great Rock Beetle is an elite")
	check_eq(Monsters.rank("foreman", false), "boss", "the Foreman is a boss")
	for id in ["cave_bat", "cave_spider", "rock_snail", "rock_beetle", "lost_miner"]:
		check_eq(Monsters.target_stats(id, false).armor, 0.0, "%s: no armor" % id)
	check(Monsters.target_stats("foreman", false).armor > 0.0, "the boss wears armor")
	check_near(Monsters.max_hp("rock_beetle", false, "", 2), 100.0 * 1.3, 0.01, "normal: +30% with 2 players")
	check_near(Monsters.max_hp("great_rock_beetle", false, "", 3), 240.0 * 2.0, 0.01, "elite: +50% per extra player")
	check_near(Monsters.max_hp("foreman", false, "", 4), 450.0 * 3.25, 0.01, "boss: +75% per extra player")
	var plated := {armor = 50}
	check(Combat.damage("spear", false, 1, plated) > Combat.damage("sword", false, 1, plated) * 1.05, "the spear goes through armor")
	check(Combat.shot_damage(false, 1, "bolt_stone", plated, 5.0) > Combat.shot_damage(false, 1, "bolt_stone", {}, 5.0) * 0.75, "bolts pierce armor")
	check(Combat.stun_value("mace", false, 1) > Combat.stun_value("sword", false, 1) * 2.0, "the mace stuns most")


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


func test_crossbow_numbers() -> void:
	var plain := {armor = 0, slash = 1.0, blunt = 1.0, pierce = 1.0}
	check_eq(Combat.shot_damage(false, 0, "bolt_stone", plain, 10.0), 24, "hip shot 24")
	check_eq(Combat.shot_damage(true, 0, "bolt_stone", plain, 10.0), 34, "aimed shot 34")
	check_eq(Combat.shot_damage(true, 0, "bolt_metal", plain, 10.0), 41, "metal tip ×1.2 = 40.8")
	check_eq(Combat.shot_damage(true, 0, "bolt_stone", plain, 50.0), 17, "half damage at 50 m")
	check_eq(Combat.shot_damage(true, 0, "bolt_stone", plain, 61.0), 0, "nothing past 60 m")
	check_eq(Combat.shot_damage(true, 1, "bolt_stone", plain, 10.0), 44, "copper ×1.3 = 44.2")
	var shell := {armor = 40, slash = 0.5, blunt = 1.5, pierce = 1.0}
	check(Combat.shot_damage(true, 0, "bolt_thumper", shell, 10.0) > Combat.shot_damage(true, 0, "bolt_stone", shell, 10.0), "thumpers beat shells")
	for b in Combat.BOLT_ORDER:
		check(Items.exists(b) and Recipes.LIST.values().any(func(r): return r.output == b), "%s exists and can be crafted" % b)



## Owner, chat 18 (F535): the crossbow uses the KayKit "c/" moves (the bow held in front, a two-hand reload), not the
## pistol's, and every "c/" clip has a grip turn so the bow lies along his arms.
func test_crossbow_uses_its_own_moves() -> void:
	check_eq(DwarfRig.ANIMS.aim, "c/Aim", "aiming holds the crossbow's own aim")
	var src: String = FileAccess.get_file_as_string("res://src/player/dwarf_model.gd")
	check(src.contains('play_upper("c/Shoot"') and src.contains('play_upper("c/Reload"'), "shoot and reload play the c/ clips")
	check(not src.contains("Pistol_"), "no pistol clips left in the model")
	for clip in ["c/Aim", "c/Shoot", "c/Reload"]:
		check(DwarfRig.GRIPS.crossbow.has(clip), "%s has a crossbow grip" % clip)
	var rig := DwarfRig.new()
	for clip in ["c/Aim", "c/Shoot", "c/Reload"]:
		check(ResourceLoader.exists(DwarfRig.CROSSBOW_LIB) and (load(DwarfRig.CROSSBOW_LIB) as AnimationLibrary).has_animation(clip.get_slice("/", 1)), "%s is baked" % clip)
	rig.free()


## F137: every weapon has a small critical-hit chance.
func test_every_weapon_can_crit() -> void:
	for w in Combat.WEAPONS:
		var c := Combat.crit_chance(w)
		check(c >= 0.03 and c <= 0.12, "%s crits sometimes, not often (%.2f)" % [w, c])
	check(Combat.CRIT_MULT > 1.4 and Combat.CRIT_MULT < 2.1, "a critical hit hits clearly harder")
