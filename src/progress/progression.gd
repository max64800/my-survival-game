class_name Progression
extends RefCounted
## How a dwarf grows (progression doc section 7):
##  - 14 skills (0-100) that go up by USING them, like Valheim (docs/design/skills.md): a tiny bonus
##    every level and a special perk at 25, 50, 75 and 100.
##  - A character level (1-30) that goes up from ALL XP and gives 1 perk point per level.
##  - The perk tree (PERKS): 4 branches, mostly passive perks plus a few active ones you press a key for.

signal leveled_up(new_level: int)
signal skill_up(skill: String, new_level: int)

const SKILLS := ["running", "jumping", "mining", "woodcutting", "gathering", "crafting", "cooking",
	"sword", "axe", "mace", "warhammer", "spear", "shield", "crossbow"]
const MILESTONES := [25, 50, 75, 100]
## What each skill's ★ perks do (skills.md). Index 0..3 = level 25, 50, 75, 100.
const SKILL_INFO := {
	"running": ["Running", "+2% run speed, −3% run stamina", ["Quick burst of speed when you start running", "Rubble and slopes don't slow you", "Running past enemies makes them miss more", "Second Wind: at 0 stamina, get 25% back (every 2 min)"]],
	"jumping": ["Jumping", "+3% jump height, −3% jump stamina", ["Jumping uses less stamina", "Climb up ledges a bit higher", "Jump attack: hits in the air do +20%", "No fall damage up to 8 m"]],
	"mining": ["Mining", "+3% dig power, −2% swing stamina", ["Pickaxe swings 10% faster", "+10% chance of double ore", "Crystal spots give +1 crystal", "Lucky hit: 1 in 10 hits digs twice as hard"]],
	"woodcutting": ["Woodcutting", "+3% chop power, −2% stamina", ["Axe swings 10% faster when chopping", "+1 wood per Root Tree", "Chopped roots grow back faster", "15% chance of double wood"]],
	"gathering": ["Gathering", "+3% chance of an extra item", ["Pick things up from a bit further away", "Things on the ground glow from further away", "Mushrooms and plants regrow faster near you", "Rare finds turn up more often"]],
	"crafting": ["Crafting", "−3% craft time, better quality odds", ["Repair and upgrade cost 10% less", "Chance to save 1 material", "Craft several at once with no extra wait", "Best quality possible on anything"]],
	"cooking": ["Cooking", "−3% cook time, +2% food buff time", ["Cooking pots make 1 more dish at a time", "Chance of a double dish", "You can eat a 4th buff food", "Your cooked food also heals a little"]],
	"sword": ["Sword", "+2% damage, −2% attack stamina", ["Quick step forward on the first swing", "Parry window 20% bigger", "3rd hit of a combo does extra damage", "Perfect parry gives a free critical hit back"]],
	"axe": ["Axe", "+2% damage, −2% stamina", ["Hits make enemies bleed a little", "Hits 3 enemies instead of 2", "Heavy hits break enemy shields faster", "Heavy sweep gives stamina back for each enemy hit"]],
	"mace": ["Mace", "+2% damage, +3% armor piercing", ["Hits crack rock-shelled enemies faster", "Stuns build up 15% faster", "Hits on armored enemies make them stagger", "Stunned enemies take extra damage"]],
	"warhammer": ["Warhammer", "+2% damage, +3% stun", ["Heavy swings can't be interrupted", "Ground slam reaches 25% wider", "Slam breaks rock and digs a little", "Ground slam knocks enemies down"]],
	"spear": ["Spear", "+2% damage, +1.5% reach", ["A poke pushes enemies back", "Thrust goes through 1 extra enemy", "Throw your spear (pick it up again)", "Sweet spot: hits at the tip of your reach do +30%"]],
	"shield": ["Shield", "+2% block strength, −2% block stamina", ["Walk faster while blocking", "Shield bash stuns more", "After a perfect parry, your next hit does +25%", "Parry window 30% bigger; perfect parries give stamina back"]],
	"crossbow": ["Crossbow", "+2% damage, −3% reload time", ["Walk faster while aiming", "Reload 15% faster", "30% chance the bolt comes back to you", "Bolts ignore 30% of armor"]],
}
## Which weapon (Combat.weapon_of) trains which skill. Pickaxe and fists train none.
const WEAPON_SKILL := {sword = "sword", axe = "axe", axe_2h = "axe", mace = "mace", mace_2h = "warhammer",
	spear = "spear", shield = "shield", crossbow = "crossbow"}
const BAND_HOURS := [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]
## shortcut: a guess at the skill XP an hour of steady work gives; measure with the robots and retune.
const XP_PER_HOUR := 3000.0
const MAX_LEVEL := 30
const MAX_SKILL := 100

## The perk tree (owner, Nov 19; draft page: claude.ai/artifact/UTLcKhgPsVEZiubPB2dfWP). 1 point per level.
## Four branches around the dwarf: Bones (top, toughness), Fists (right, fighting), Hands (bottom, utility),
## Heart (left, playing together). The ids below keep the old words; only the shown names changed (owner, Nov 19).
## id: [branch, max ranks, needs perk id ("" = first in branch), active?, name, what it does]
## active = you press a key to use it (ACTIVE has the recharge). A perk opens once the one before it has a point.
const BRANCHES := ["toughness", "fighting", "utility", "together"]
const PERKS := {
	# Toughness
	"thick_skin": ["toughness", 3, "", false, "Thick Skin", "+5 max health per rank"],
	"iron_belly": ["toughness", 3, "thick_skin", false, "Iron Belly", "Hunger goes down 5% slower per rank"],
	"big_lungs": ["toughness", 3, "thick_skin", false, "Big Lungs", "+10 max stamina per rank"],
	"deep_well": ["toughness", 3, "thick_skin", false, "Deep Well", "Thirst goes down 5% slower per rank"],
	"poison_blood": ["toughness", 2, "iron_belly", false, "Poison Blood", "15% less poison per rank"],
	"stubborn_heart": ["toughness", 3, "big_lungs", false, "Stubborn Heart", "Health comes back 10% faster per rank"],
	"fire_and_frost": ["toughness", 2, "deep_well", false, "Fire and Frost", "Burning and chill build up 15% slower per rank"],
	"stone_skin": ["toughness", 3, "poison_blood", false, "Stone Skin", "+3% armor per rank"],
	"grave_walker": ["toughness", 2, "stubborn_heart", false, "Grave Walker", "Lose 25% less skill when you die, per rank (skill loss isn't in the game yet)"],
	"unbreakable": ["toughness", 1, "grave_walker", false, "Unbreakable", "Once every 10 min, a killing hit leaves you at 1 health"],
	"stone_stance": ["toughness", 1, "stone_skin", true, "Stone Stance", "Take 40% less damage for 60 s, but walk slowly"],
	# Fighting
	"warriors_grip": ["fighting", 3, "", false, "Warrior's Grip", "+3% damage with every weapon per rank"],
	"light_feet": ["fighting", 3, "warriors_grip", false, "Light Feet", "Dodging costs 10% less stamina per rank"],
	"battle_breath": ["fighting", 2, "warriors_grip", false, "Battle Breath", "Stamina comes back 10% faster for 10 s after you're hurt, per rank"],
	"quick_reload": ["fighting", 3, "warriors_grip", false, "Quick Reload", "Crossbow reloads 10% faster per rank"],
	"last_swing": ["fighting", 3, "light_feet", false, "Last Swing", "A kill heals you 3 health per rank"],
	"armor_breaker": ["fighting", 3, "battle_breath", false, "Armor Breaker", "Ignore 5% of enemy armor per rank"],
	"steady_aim": ["fighting", 3, "quick_reload", false, "Steady Aim", "+5% crossbow damage per rank"],
	"monster_lore": ["fighting", 2, "last_swing", false, "Monster Lore", "+5% damage to kinds you've killed 50 of (not in the game yet)"],
	"heavy_hands": ["fighting", 2, "armor_breaker", false, "Heavy Hands", "Heavy attacks stagger 15% more per rank"],
	"berserker": ["fighting", 1, "heavy_hands", false, "Berserker", "Below 30% health: +20% damage, 10% less damage taken"],
	"whirlwind": ["fighting", 1, "monster_lore", true, "Whirlwind", "Spin and hit every enemy around you"],
	"rapid_volley": ["fighting", 1, "steady_aim", true, "Rapid Volley", "Your next 3 crossbow bolts need no reload"],
	# Utility
	"deep_pockets": ["utility", 3, "", false, "Deep Pockets", "+2 bag slots per rank (not in the game yet)"],
	"ore_smasher": ["utility", 3, "deep_pockets", false, "Ore Smasher", "Ore breaks 15% faster per rank"],
	"quick_smelter": ["utility", 3, "deep_pockets", false, "Quick Smelter", "Smelting is 15% faster per rank"],
	"thrifty": ["utility", 3, "deep_pockets", false, "Thrifty", "Repairs cost 10% less per rank (not in the game yet)"],
	"prospector": ["utility", 3, "ore_smasher", false, "Prospector", "10% chance per rank of 1 extra ore"],
	"chest_looter": ["utility", 3, "quick_smelter", false, "Chest Looter", "More and rarer materials from chests (not in the game yet)"],
	"steady_hands": ["utility", 3, "thrifty", false, "Steady Hands", "5% chance per rank to get 1 material back when crafting"],
	"hearth_cook": ["utility", 3, "steady_hands", false, "Hearth Cook", "Food buffs last 10% longer per rank"],
	"monster_scavenger": ["utility", 3, "chest_looter", false, "Monster Scavenger", "Monsters drop 10% more per rank, rare drops more often"],
	"master_of_stone": ["utility", 1, "monster_scavenger", false, "Master of Stone", "Dig 20% faster; broken rock sometimes drops a rare gem"],
	"quick_fix": ["utility", 1, "hearth_cook", true, "Quick Fix", "Fully repair what's in your hand (tools don't wear out yet)"],
	# Together (support)
	"shoulder_to_shoulder": ["together", 3, "", false, "Shoulder to Shoulder", "A friend within 10 m: stamina comes back 5% faster per rank"],
	"shared_lessons": ["together", 2, "shoulder_to_shoulder", false, "Shared Lessons", "Friends within 20 m get 10% of your skill XP per rank"],
	"war_horn": ["together", 2, "shoulder_to_shoulder", true, "War Horn", "You and friends within 15 m: +10% damage per rank for 20 s"],
	"quick_helper": ["together", 2, "shoulder_to_shoulder", false, "Quick Helper", "Revive friends 25% faster per rank (no reviving yet)"],
	"lantern_bearer": ["together", 2, "shared_lessons", false, "Lantern Bearer", "Your lantern reaches 25% further per rank"],
	"healing_brew": ["together", 3, "war_horn", true, "Healing Brew", "Heal 15 per rank: you and friends within 5 m"],
	"stand_over": ["together", 2, "quick_helper", false, "Stand Over", "15% less damage per rank next to a fallen friend (no falling yet)"],
	"clan_banner": ["together", 1, "healing_brew", true, "Clan Banner", "You and friends within 10 m resist poison, chill and burn by 50% for 60 s"],
	"pack_hunters": ["together", 3, "stand_over", false, "Pack Hunters", "+5% damage per rank to an enemy a friend hit in the last 5 s"],
	"bond_of_the_clan": ["together", 1, "clan_banner", false, "Bond of the Clan", "A friend dies near you: you and everyone near get +25% damage and stamina for 60 s"],
}
## Active perks: seconds until you can use them again.
const ACTIVE := {stone_stance = 180.0, whirlwind = 45.0, rapid_volley = 60.0, quick_fix = 300.0,
	war_horn = 90.0, healing_brew = 120.0, clan_banner = 300.0}
## Keys for the first 3 active perks you own (in tree order). shortcut: no choosing which ability goes on which key yet.
const ABILITY_KEYS := 3
## Resetting your perk points costs gold coins (owner, Nov 19): this many per level.
const RESPEC_GOLD_PER_LEVEL := 5

## Quality roll table (progression doc 3.4): [min smithing, Q1%, Q2%, Q3%, Q4%, Q5%]
const QUALITY_TABLE := [
	[80, 0, 5, 25, 40, 30],
	[60, 0, 15, 35, 35, 15],
	[40, 10, 25, 40, 20, 5],
	[25, 25, 35, 30, 9, 1],
	[10, 45, 35, 17, 3, 0],
	[0, 70, 25, 5, 0, 0],
]
const QUALITY_BONUS := [0.0, 0.0, 0.04, 0.08, 0.13, 0.20]  ## index = quality 1..5

var level := 1
var xp := 0  ## XP into the current level
var skill_level := _zeros()
var skill_xp := _zeros()
var perks := {}  ## perk id -> rank
var _points_spent := 0


# ---------------------------------------------------------------- curves

## XP from level L to L+1: 600 + 45 × L^1.3, rounded to the nearest 10.
static func xp_to_next(l: int) -> int:
	return int(roundf((600.0 + 45.0 * pow(l, 1.3)) / 10.0)) * 10


static func _zeros() -> Dictionary:
	var d := {}
	for s in SKILLS:
		d[s] = 0
	return d


## Skill XP from skill n to n+1: each band of 10 levels takes BAND_HOURS of steady work.
static func skill_xp_to_next(n: int) -> int:
	return roundi(BAND_HOURS[clampi(n / 10, 0, 9)] * XP_PER_HOUR / 10.0)


## The skill a weapon trains ("" = none).
static func weapon_skill(weapon: String) -> String:
	return WEAPON_SKILL.get(weapon, "")


## True once `skill` reached the ★ perk at `at` (25, 50, 75 or 100).
func has_star(skill: String, at: int) -> bool:
	return skill_level.get(skill, 0) >= at


static func total_xp_for_level(l: int) -> int:
	var t := 0
	for i in range(1, l):
		t += xp_to_next(i)
	return t


## 1 perk point per level after the first (owner, Nov 19).
static func points_for_level(l: int) -> int:
	return l - 1


# ---------------------------------------------------------------- earning

## Adds XP. `skill` = "" gives character XP only (discoveries, runes).
func add_xp(amount: int, skill: String = "") -> void:
	if amount <= 0:
		return
	if skill != "":
		assert(skill_level.has(skill), "unknown skill " + skill)
		skill_xp[skill] += amount
		while skill_level[skill] < MAX_SKILL and skill_xp[skill] >= skill_xp_to_next(skill_level[skill]):
			skill_xp[skill] -= skill_xp_to_next(skill_level[skill])
			skill_level[skill] += 1
			skill_up.emit(skill, skill_level[skill])
	if level >= MAX_LEVEL:
		return
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		leveled_up.emit(level)
	if level >= MAX_LEVEL:
		xp = 0


# ---------------------------------------------------------------- perks

func points_total() -> int:
	return points_for_level(level)


func points_free() -> int:
	return points_total() - _points_spent


func perk_rank(id: String) -> int:
	return perks.get(id, 0)


## Why a perk can't be bought right now ("" = it can).
func why_not(id: String) -> String:
	if not PERKS.has(id):
		return "No such perk."
	var p: Array = PERKS[id]
	if perk_rank(id) >= p[1]:
		return "Already maxed."
	if p[2] != "" and perk_rank(p[2]) < 1:
		return "Needs %s first." % PERKS[p[2]][4]
	if points_free() < 1:
		return "Not enough points."
	return ""


func buy_perk(id: String) -> bool:
	if why_not(id) != "":
		return false
	perks[id] = perk_rank(id) + 1
	_points_spent += 1
	return true


## Gold coins it costs to reset your perk points.
func respec_cost() -> int:
	return level * RESPEC_GOLD_PER_LEVEL


## Refunds every perk point (the host takes the gold first). Skills stay.
func respec() -> void:
	perks.clear()
	_points_spent = 0


## The active perks on your ability keys: the first ABILITY_KEYS you own, in tree order.
func ability_slots() -> Array:
	var out := []
	for id in PERKS:
		if PERKS[id][3] and perk_rank(id) > 0 and out.size() < ABILITY_KEYS:
			out.append(id)
	return out


# ---------------------------------------------------------------- bonuses

## Automatic skill bonus (a tiny bit every level, skills.md) plus perks. Returns a multiplier like 1.15.
func dig_power_mult() -> float:
	return (1.0 + skill_level.mining * 0.003) * (1.2 if perk_rank("master_of_stone") > 0 else 1.0)


func chop_power_mult() -> float:
	return 1.0 + skill_level.woodcutting * 0.003


## Swing stamina: Mining for pickaxes, Woodcutting for axes on wood.
func swing_stamina_mult(skill: String = "mining") -> float:
	return 1.0 - skill_level.get(skill, 0) * 0.002


## Lantern Bearer (owner said yes, Nov 19): your lantern reaches 25% further per rank.
func lantern_range_mult() -> float:
	return 1.0 + perk_rank("lantern_bearer") * 0.25


func run_speed_mult() -> float:
	return 1.0 + skill_level.running * 0.002


func run_stamina_mult() -> float:
	return 1.0 - skill_level.running * 0.003


func jump_speed_mult() -> float:
	return 1.0 + skill_level.jumping * 0.003 * 0.5  # jump height grows with speed², so half the speed bonus ≈ the height bonus


func jump_stamina_mult() -> float:
	return (1.0 - skill_level.jumping * 0.003) * (0.75 if has_star("jumping", 25) else 1.0)


# ---------------------------------------------------------------- skill bonuses and ★ perks (skills.md)

func _lv(skill: String) -> int:
	return skill_level.get(skill, 0)


## Attack stamina: Sword and Axe use 2% less per 10 levels.
func attack_stamina_mult(weapon: String) -> float:
	var s := weapon_skill(weapon)
	return 1.0 - _lv(s) * 0.002 if s in ["sword", "axe"] else 1.0


## Share of armor a weapon's skill ignores: Mace +3% per 10 levels; Crossbow ★100 ignores 30%.
func skill_armor_pierce(weapon: String) -> float:
	var s := weapon_skill(weapon)
	if s == "mace":
		return _lv(s) * 0.003
	if s == "crossbow" and has_star("crossbow", 100):
		return 0.30
	return 0.0


## Stun from a hit, from skills: Warhammer +3% per 10 levels; Mace ★50 +15%; Shield ★50 (bash) +30%.
func skill_stun_mult(weapon: String) -> float:
	var s := weapon_skill(weapon)
	var m := 1.0
	if s == "warhammer":
		m += _lv(s) * 0.003
	if s == "mace" and has_star("mace", 50):
		m += 0.15
	if s == "shield" and has_star("shield", 50):
		m += 0.30
	return m


## Spear reach: +1.5% per 10 levels.
func reach_mult(weapon: String) -> float:
	return 1.0 + _lv("spear") * 0.0015 if weapon_skill(weapon) == "spear" else 1.0


## Shield block: +2% stronger and 2% cheaper per 10 levels (added to Combat.defend's gem bonus).
func block_bonus() -> Dictionary:
	return {block = _lv("shield") * 0.002, block_stamina = _lv("shield") * 0.002}


## Parry window: Sword ★50 +20% (sword parries), Shield ★100 +30% (shield parries).
func parry_mult(weapon: String, shield: bool) -> float:
	if shield:
		return 1.3 if has_star("shield", 100) else 1.0
	return 1.2 if weapon_skill(weapon) == "sword" and has_star("sword", 50) else 1.0


## Crossbow reload: Quick Reload perk, Crossbow −3% per 10 levels, ★50 −15%.
func crossbow_reload_mult() -> float:
	return reload_mult() * (1.0 - _lv("crossbow") * 0.003) * (0.85 if has_star("crossbow", 50) else 1.0)


## How long a craft takes: Crafting −3% per 10 levels; cooking: Cooking −3% per 10 levels.
func craft_time_mult(cooking: bool) -> float:
	return 1.0 - _lv("cooking" if cooking else "crafting") * 0.003


## Extra damage share from ★ perks for one hit (host). ctx: combo_step, riposte, stunned, armor, shelled, heavy,
## airborne, tip (the target is at the very end of the reach).
func star_damage_bonus(weapon: String, ctx: Dictionary) -> float:
	var s := weapon_skill(weapon)
	var b := 0.0
	if ctx.get("airborne", false) and has_star("jumping", 75):
		b += 0.20  # jump attack
	match s:
		"sword":
			if has_star("sword", 75) and ctx.get("combo_step", 0) == 2:
				b += 0.30  # 3rd hit of a combo
		"mace":
			if has_star("mace", 25) and ctx.get("shelled", false):
				b += 0.25  # cracks rock-shelled enemies
			if has_star("mace", 100) and ctx.get("stunned", false):
				b += 0.25
		"spear":
			if has_star("spear", 100) and ctx.get("tip", false):
				b += 0.30  # sweet spot
		"shield":
			pass
	if ctx.get("riposte", false) and has_star("shield", 75):
		b += 0.25  # the hit after a perfect parry
	return b


## Sword ★100: a perfect parry's counter-hit is a critical.
func riposte_crits(weapon: String) -> bool:
	return weapon_skill(weapon) == "sword" and has_star("sword", 100)


## Most enemies one swing can hit: Axe ★50 hits 3, Spear ★50 goes through 1 more.
func extra_targets(weapon: String) -> int:
	var s := weapon_skill(weapon)
	return 1 if (s == "axe" and has_star("axe", 50)) or (s == "spear" and has_star("spear", 50)) else 0


## Digging / chopping swing time: Mining ★25 and Woodcutting ★25 swing 10% faster.
func dig_swing_mult(with_axe: bool) -> float:
	return 0.9 if has_star("woodcutting" if with_axe else "mining", 25) else 1.0


## Walking while blocking (Shield ★25) or aiming (Crossbow ★25): faster than the normal 60%.
func guard_walk_mult(aiming: bool) -> float:
	return 0.8 if has_star("crossbow" if aiming else "shield", 25) else 0.6


## Extra damage from the weapon's skill, as a bonus to add (0.2 = +20%).
func weapon_damage_bonus(weapon: String) -> float:
	var s := weapon_skill(weapon)
	return skill_level[s] * 0.002 if s != "" else 0.0


## Chance of one extra item when picking things up (Gathering).
func gather_extra_chance() -> float:
	return skill_level.gathering * 0.003


func hunger_drain_mult() -> float:
	return 1.0 - perk_rank("iron_belly") * 0.05


func thirst_drain_mult() -> float:
	return 1.0 - perk_rank("deep_well") * 0.05


func food_duration_mult() -> float:
	return (1.0 + skill_level.cooking * 0.002) * (1.0 + perk_rank("hearth_cook") * 0.10)


## Perk numbers (owner's tree, Nov 19). Toughness:
func max_health_bonus() -> float:
	return perk_rank("thick_skin") * 5.0


func max_stamina_bonus() -> float:
	return perk_rank("big_lungs") * 10.0


func health_regen_bonus() -> float:
	return perk_rank("stubborn_heart") * 0.10


## How much of an ailment's buildup you shrug off (0.5 = half). kind: poison / burn / chill.
func ailment_resist(kind: String) -> float:
	match kind:
		"poison": return perk_rank("poison_blood") * 0.15
		"burn", "chill": return perk_rank("fire_and_frost") * 0.15
	return 0.0


func armor_bonus() -> float:
	return perk_rank("stone_skin") * 0.03


## Fighting: extra damage share on every hit (crossbow adds Steady Aim).
func perk_damage_bonus(weapon: String) -> float:
	return perk_rank("warriors_grip") * 0.03 + (perk_rank("steady_aim") * 0.05 if weapon == "crossbow" else 0.0)


func dodge_stamina_mult() -> float:
	return 1.0 - perk_rank("light_feet") * 0.10


func reload_mult() -> float:
	return 1.0 - perk_rank("quick_reload") * 0.10


## Share of enemy armor ignored.
func armor_pierce() -> float:
	return perk_rank("armor_breaker") * 0.05


func heavy_stun_mult() -> float:
	return 1.0 + perk_rank("heavy_hands") * 0.15


## Utility.
func ore_power_mult() -> float:
	return 1.0 + perk_rank("ore_smasher") * 0.15


func smelt_time_mult() -> float:
	return 1.0 / (1.0 + perk_rank("quick_smelter") * 0.15)


func extra_ore_chance() -> float:
	return perk_rank("prospector") * 0.10


func save_material_chance() -> float:
	return perk_rank("steady_hands") * 0.05 + (0.10 if has_star("crafting", 50) else 0.0)


func extra_drop_chance() -> float:
	return perk_rank("monster_scavenger") * 0.10


## Crafting skill used for the quality roll.
func quality_smithing(extra: int = 0) -> int:
	return skill_level.crafting + extra


## Rolls a crafted item's quality (1-5). `roll` is 0..1 (pass randf()).
static func roll_quality(smithing: int, roll: float) -> int:
	for row in QUALITY_TABLE:
		if smithing >= row[0]:
			var acc := 0.0
			for q in 5:
				acc += row[q + 1] / 100.0
				if roll < acc:
					return q + 1
			return 5
	return 1


static func quality_bonus(q: int) -> float:
	return QUALITY_BONUS[clampi(q, 1, 5)]


# ---------------------------------------------------------------- network / saving

func to_data() -> Dictionary:
	return {l = level, x = xp, sl = skill_level.duplicate(), sx = skill_xp.duplicate(), p = perks.duplicate(), ps = _points_spent}


## Old saves had 4 big skills: their levels carry over to the new skills they became (XP into the level restarts).
const OLD_SKILLS := {fighting = ["sword"], smithing = ["crafting"], survival = ["cooking", "gathering", "woodcutting"]}


func load_data(d: Dictionary) -> void:
	level = d.l
	xp = d.x
	skill_level = _zeros()
	skill_xp = _zeros()
	for s in d.sl:
		if skill_level.has(s):
			skill_level[s] = int(d.sl[s])
			skill_xp[s] = int(d.sx.get(s, 0))
		for n in OLD_SKILLS.get(s, []):
			skill_level[n] = maxi(skill_level[n], int(d.sl[s]))
	# Perks from the old 4 trees (before Nov 19) are dropped and their points come back.
	perks = {}
	_points_spent = 0
	for id in d.p:
		if PERKS.has(id):
			perks[id] = mini(int(d.p[id]), PERKS[id][1])
			_points_spent += perks[id]
