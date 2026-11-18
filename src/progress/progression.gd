class_name Progression
extends RefCounted
## How a dwarf grows (progression doc section 7):
##  - 14 skills (0-100) that go up by USING them, like Valheim (docs/design/skills.md): a tiny bonus
##    every level and a special perk at 25, 50, 75 and 100.
##  - A character level (1-30) that goes up from ALL XP and gives perk points.
##  - Tree perks cost points AND need a minimum level in their branch, so you can't buy
##    "master miner" without actually mining. (The trees are being re-planned.)

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
## The tree branches (perks, runes) and the skills that count for them: the best one wins.
const BRANCH_SKILLS := {mining = ["mining"], smithing = ["crafting"], survival = ["cooking", "gathering", "woodcutting"],
	fighting = ["sword", "axe", "mace", "warhammer", "spear", "shield", "crossbow"]}
## Hours of doing mostly that one thing for each 10 levels (owner: ~40 h to reach 100).
const BAND_HOURS := [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]
## shortcut: a guess at the skill XP an hour of steady work gives; measure with the robots and retune.
const XP_PER_HOUR := 3000.0
const MAX_LEVEL := 30
const MAX_SKILL := 100
const BONUS_POINT_LEVELS := [5, 10, 15, 20, 25, 30]

## id: [branch skill, ranks, cost per rank, min skill, needs perk id ("" = none), needs perk rank]
const PERKS := {
	# Miner
	"strong_swing": ["mining", 3, 1, 0, "", 0],
	"light_arms": ["mining", 2, 1, 5, "", 0],
	"magnet_pockets": ["mining", 1, 1, 5, "", 0],
	"lucky_strike": ["mining", 3, 1, 10, "strong_swing", 1],
	"crystal_ear": ["mining", 2, 1, 10, "", 0],
	"wide_bite": ["mining", 2, 1, 15, "strong_swing", 1],
	"prospectors_eye": ["mining", 2, 2, 20, "lucky_strike", 1],
	"mole_stride": ["mining", 1, 1, 20, "", 0],
	"rock_sense": ["mining", 1, 1, 25, "", 0],
	"hard_rock_hands": ["mining", 1, 2, 35, "wide_bite", 1],
	"vein_breaker": ["mining", 1, 3, 50, "prospectors_eye", 1],
	# Warrior
	"thick_skin": ["fighting", 3, 1, 0, "", 0],
	"second_wind": ["fighting", 2, 1, 5, "", 0],
	"heavy_hand": ["fighting", 3, 1, 10, "", 0],
	"steady_guard": ["fighting", 2, 1, 10, "thick_skin", 1],
	"shield_wall": ["fighting", 2, 1, 15, "steady_guard", 1],
	"roll_master": ["fighting", 2, 1, 15, "second_wind", 1],
	"combo_keeper": ["fighting", 2, 1, 20, "heavy_hand", 1],
	"stunner": ["fighting", 2, 2, 25, "steady_guard", 1],
	"pack_breaker": ["fighting", 1, 2, 30, "", 0],
	"last_stand": ["fighting", 1, 2, 35, "thick_skin", 3],
	"executioner": ["fighting", 1, 3, 50, "stunner", 1],
	# Smith & Builder
	"steady_hammer": ["smithing", 3, 1, 0, "", 0],
	"hot_hearth": ["smithing", 2, 1, 5, "", 0],
	"fuel_saver": ["smithing", 1, 1, 10, "hot_hearth", 1],
	"thrifty_smith": ["smithing", 2, 1, 15, "steady_hammer", 1],
	"quick_mason": ["smithing", 2, 1, 15, "", 0],
	"long_reach": ["smithing", 1, 1, 20, "", 0],
	"blueprint_foreman": ["smithing", 2, 1, 20, "long_reach", 1],
	"strong_beams": ["smithing", 2, 1, 25, "", 0],
	"upgrade_expert": ["smithing", 1, 2, 35, "thrifty_smith", 1],
	"reforge": ["smithing", 1, 3, 50, "steady_hammer", 3],
	# Survivor & Cook
	"iron_belly": ["survival", 2, 1, 0, "", 0],
	"camel_throat": ["survival", 2, 1, 0, "", 0],
	"good_cook": ["survival", 3, 1, 5, "", 0],
	"forager": ["survival", 1, 1, 5, "", 0],
	"green_thumb": ["survival", 2, 1, 10, "", 0],
	"big_harvest": ["survival", 2, 1, 15, "green_thumb", 1],
	"hunter": ["survival", 2, 1, 15, "", 0],
	"deep_pockets": ["survival", 2, 1, 20, "", 0],
	"hearty": ["survival", 2, 2, 25, "good_cook", 1],
	"way_home": ["survival", 1, 1, 30, "", 0],
	"fourth_plate": ["survival", 1, 3, 50, "hearty", 1],
}

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


## The level that counts for a tree branch (its best skill).
func branch_level(branch: String) -> int:
	var best := 0
	for s in BRANCH_SKILLS.get(branch, [branch]):
		best = maxi(best, skill_level.get(s, 0))
	return best


static func total_xp_for_level(l: int) -> int:
	var t := 0
	for i in range(1, l):
		t += xp_to_next(i)
	return t


static func points_for_level(l: int) -> int:
	var p := l - 1
	for b in BONUS_POINT_LEVELS:
		if l >= b:
			p += 1
	return p


# ---------------------------------------------------------------- earning

## Adds XP. `skill` = "" gives character XP only (discoveries, bosses, runes).
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
	if branch_level(p[0]) < p[3]:
		return "Needs %s %d." % [" or ".join(BRANCH_SKILLS[p[0]].map(func(x): return x.capitalize())), p[3]]
	if p[4] != "" and perk_rank(p[4]) < p[5]:
		return "Needs %s first." % p[4].capitalize()
	if points_free() < p[2]:
		return "Not enough points."
	return ""


func buy_perk(id: String) -> bool:
	if why_not(id) != "":
		return false
	perks[id] = perk_rank(id) + 1
	_points_spent += PERKS[id][2]
	return true


## Refunds every perk point (paid for at the Rune Slab). Skills stay.
func respec() -> void:
	perks.clear()
	_points_spent = 0


# ---------------------------------------------------------------- bonuses

## Automatic skill bonus (a tiny bit every level, skills.md) plus perks. Returns a multiplier like 1.15.
func dig_power_mult() -> float:
	return (1.0 + skill_level.mining * 0.003) * (1.0 + perk_rank("strong_swing") * 0.05)


func chop_power_mult() -> float:
	return 1.0 + skill_level.woodcutting * 0.003


## Swing stamina: Mining for pickaxes, Woodcutting for axes on wood.
func swing_stamina_mult(skill: String = "mining") -> float:
	return (1.0 - skill_level.get(skill, 0) * 0.002) * (1.0 - perk_rank("light_arms") * 0.15 if skill == "mining" else 1.0)


func run_speed_mult() -> float:
	return 1.0 + skill_level.running * 0.002


func run_stamina_mult() -> float:
	return 1.0 - skill_level.running * 0.003


func jump_speed_mult() -> float:
	return 1.0 + skill_level.jumping * 0.003 * 0.5  # jump height grows with speed², so half the speed bonus ≈ the height bonus


func jump_stamina_mult() -> float:
	return (1.0 - skill_level.jumping * 0.003) * (0.75 if has_star("jumping", 25) else 1.0)


## Extra damage from the weapon's skill, as a bonus to add (0.2 = +20%).
func weapon_damage_bonus(weapon: String) -> float:
	var s := weapon_skill(weapon)
	return skill_level[s] * 0.002 if s != "" else 0.0


## Chance of one extra item when picking things up (Gathering).
func gather_extra_chance() -> float:
	return skill_level.gathering * 0.003


func hunger_drain_mult() -> float:
	return 1.0 - perk_rank("iron_belly") * 0.10


func thirst_drain_mult() -> float:
	return 1.0 - perk_rank("camel_throat") * 0.10


func food_duration_mult() -> float:
	return (1.0 + skill_level.cooking * 0.002) * (1.0 + perk_rank("good_cook") * 0.10)


func max_health_bonus() -> float:
	return perk_rank("thick_skin") * 0.05


func bag_bonus_slots() -> int:
	return perk_rank("deep_pockets") * 3


## Crafting skill used for the quality roll (perks add "+5 for the quality roll").
func quality_smithing(extra: int = 0) -> int:
	return skill_level.crafting + perk_rank("steady_hammer") * 5 + extra


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
	perks = d.p.duplicate()
	_points_spent = d.ps
