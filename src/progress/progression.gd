class_name Progression
extends RefCounted
## How a dwarf grows (progression doc section 7):
##  - 4 skills (0-100) that go up by USING them: mining, fighting, smithing, survival.
##  - A character level (1-30) that goes up from ALL XP and gives perk points.
##  - Perks cost points AND need a minimum skill level, so you can't buy
##    "master miner" without actually mining.

signal leveled_up(new_level: int)
signal skill_up(skill: String, new_level: int)

const SKILLS := ["mining", "fighting", "smithing", "survival"]
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
var skill_level := {"mining": 0, "fighting": 0, "smithing": 0, "survival": 0}
var skill_xp := {"mining": 0, "fighting": 0, "smithing": 0, "survival": 0}
var perks := {}  ## perk id -> rank
var _points_spent := 0


# ---------------------------------------------------------------- curves

## XP from level L to L+1: 600 + 45 × L^1.3, rounded to the nearest 10.
static func xp_to_next(l: int) -> int:
	return int(roundf((600.0 + 45.0 * pow(l, 1.3)) / 10.0)) * 10


## Skill XP from skill n to n+1: 75 + 3 × n^1.2, rounded.
static func skill_xp_to_next(n: int) -> int:
	return int(roundf(75.0 + 3.0 * pow(n, 1.2)))


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
	if skill_level[p[0]] < p[3]:
		return "Needs %s %d." % [p[0].capitalize(), p[3]]
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

## Automatic skill bonus (doc 7.5) plus perks. Returns a multiplier like 1.15.
func dig_power_mult() -> float:
	return (1.0 + skill_level.mining * 0.003) * (1.0 + perk_rank("strong_swing") * 0.05)


func swing_stamina_mult() -> float:
	return (1.0 - skill_level.mining * 0.002) * (1.0 - perk_rank("light_arms") * 0.15)


func hunger_drain_mult() -> float:
	return (1.0 - skill_level.survival * 0.0015) * (1.0 - perk_rank("iron_belly") * 0.10)


func thirst_drain_mult() -> float:
	return (1.0 - skill_level.survival * 0.0015) * (1.0 - perk_rank("camel_throat") * 0.10)


func food_duration_mult() -> float:
	return (1.0 + skill_level.survival * 0.002) * (1.0 + perk_rank("good_cook") * 0.10)


func max_health_bonus() -> float:
	return perk_rank("thick_skin") * 0.05


func bag_bonus_slots() -> int:
	return perk_rank("deep_pockets") * 3


## Smithing used for the quality roll (perks add "+5 for the quality roll").
func quality_smithing(extra: int = 0) -> int:
	return skill_level.smithing + perk_rank("steady_hammer") * 5 + extra


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


func load_data(d: Dictionary) -> void:
	level = d.l
	xp = d.x
	skill_level = d.sl.duplicate()
	skill_xp = d.sx.duplicate()
	perks = d.p.duplicate()
	_points_spent = d.ps
