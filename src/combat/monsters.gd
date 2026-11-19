class_name Monsters
## Monster data for Mossy Hollows and the Fungal Jungle (combat doc 5.2, 5.3, 6, 7).
## Owner, Nov 19: only these five creatures are in the game (no bosses, no raids, no other creatures).
## Each attack: tell = seconds of warning before it lands, reach in meters,
## parry: "any" (weapon or shield), "shield" (crushing: only a shield parry works).
## buildup = {poison/burn/chill: amount} fills the target's Ailments meter (combat doc 2.6).
## cloud = a spore cloud left when the attack lands: at "self", "target" or "between" them,
## radius m, time s, rate = poison buildup per second inside, dps = damage per second inside.

const LIST := {
	# ---- The first three, designed with the owner (docs/design/monsters-first-three.md).
	# shell_hide: when its health drops to each of `at` (fractions) it hides in its shell for `seconds`, taking `cut`
	# less damage (owner, Nov 18: once at half health, once at 10%, 10 s each: you have to wait it out, no stun-lock).
	# swoops: a flyer that cruises high, dives to bite, then climbs away (retreat m, recover s).
	# roosts: starts asleep, hanging from a cave ceiling.
	# soft_back: hits from behind do `back_mult` damage. straight_charge: a charge doesn't steer.
	"rock_snail": {name = "Rock Snail", ragdoll = {stay = ["soft_foot"], hop = 0.3, roll = "side", spin = 3.2, narrow = 0.5}, size = 1.0, hp = 110, armor = 20, stun = 90, slash = 0.75, blunt = 1.25, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 0.6, run = 0.6, pack = [1, 2], xp = 14, leader = "Old Shellback", leader_chance = 0.15,  # (run = walk: it never runs, owner Nov 17)
		color = Color(0.48, 0.44, 0.38), shape = "rock_snail", neutral = true, turns_in_place = true, shell_hide = {at = [0.5, 0.1], seconds = 10.0, cut = 0.9},
		attacks = [{name = "Shell Slam", land_sound = "snail_slam", tell = 1.2, damage = 20, type = "blunt", reach = 1.9, parry = "any"},
			{name = "Lunging Bite", tell = 0.9, damage = 14, type = "pierce", reach = 1.7, parry = "any"},
			# Spit (owner, Nov 17): short range (2-3 m), a shield stops it completely; he rears up, snaps, a gob flies.
			{name = "Spit", tell = 0.8, damage = 12, type = "blunt", reach = 3.0, min_reach = 1.6, parry = "any", spit = true, shield_stops = true}],
		drops = [["snail_meat", 1, 1.0], ["snail_meat", 1, 0.5], ["shell_piece", 2, 0.8]]},
	# Cave bats (owner, Nov 18): packs of 5-10; hit one and the whole pack wakes and swoops at you, flies back, swoops
	# again; easy (one heavy or two light sword hits each), they drop the wing leather that tans into leather armour.
	"cave_bat": {name = "Cave Bat", turns_in_place = true, turn_speed = 3.2, weaves = true, ragdoll = {hop = 0.4, spin = 6.0}, statue_hits = 2, size = 1.0, hp = 16, armor = 0, stun = 35, slash = 1.25, blunt = 1.0, pierce = 1.5,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 3.0, run = 6.5, pack = [5, 10], xp = 4, leader = "Bat Matriarch", leader_chance = 0.15,
		color = Color(0.3, 0.26, 0.28), shape = "cave_bat", flap_sound = "bat_flap", flies = true, swoops = true, roosts = true, sleeps = true,
		hit_and_run = true, retreat = 7.0, recover = 1.6,
		# F419 (owner, Nov 19): carry a light within 25 m of the roost and they wake; they keep attacking until you
		# leave their cave (they don't give up after 10 s like the others).
		wake_light = 25.0, stays_in_cave = true,
		attacks = [{name = "Swoop Bite", warn_sound = "bat_screech", tell = 0.6, damage = 6, type = "pierce", reach = 2.2, parry = "any"}],
		drops = [["wing_leather", 1, 1.0], ["wing_leather", 1, 0.3], ["bat_fang", 1, 0.4], ["bat_meat", 1, 0.8]]},
	# statue_hits: pickaxe hits to break its stone statue (default 4; owner, Nov 18: bat 2, beetle and snail 4, great 8).
	# ragdoll: on death it goes limp and falls apart into physics pieces (Ragdoll; the beetle first, owner Nov 18).
	"rock_beetle": {name = "Rock Beetle", turns_in_place = true, turn_speed = 2.6, ragdoll = true, size = 0.9, hp = 80, armor = 30, stun = 70, slash = 0.75, blunt = 1.25, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 1.8, run = 4.5, pack = [1, 2], xp = 15, leader = "Rock Beetle Brute", leader_chance = 0.2,
		color = Color(0.42, 0.39, 0.35), shape = "rock_beetle", soft_back = 2.0, straight_charge = true, recover = 1.8,
		attacks = [{name = "Mandible Snap", warn_sound = "beetle_hiss", tell = 0.7, damage = 10, type = "pierce", reach = 1.7, parry = "any"},
			{name = "Charge", warn_sound = "beetle_rumble", tell = 1.1, damage = 18, type = "blunt", reach = 9.0, parry = "shield", lunge = true}],
		drops = [["bug_meat", 2, 1.0], ["glow_gland", 1, 0.6]]},
	"great_rock_beetle": {name = "Great Rock Beetle", turns_in_place = true, turn_speed = 1.8, ragdoll = true, statue_hits = 8, size = 1.5, hp = 220, armor = 45, stun = 160, slash = 0.5, blunt = 1.5, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.25, walk = 2.0, run = 5.0, pack = [1, 1], xp = 45, leader = "Great Rock Beetle Matron", leader_chance = 0.1,
		color = Color(0.33, 0.31, 0.29), shape = "rock_beetle", soft_back = 2.0, straight_charge = true, recover = 2.0,
		attacks = [{name = "Horn Gore", warn_sound = "beetle_hiss", tell = 0.9, damage = 22, type = "pierce", reach = 2.4, parry = "any"},
			{name = "Charge", warn_sound = "beetle_rumble", tell = 1.3, damage = 30, type = "blunt", reach = 12.0, parry = "shield", knockdown = true, lunge = true}],
		drops = [["bug_meat", 4, 1.0], ["glow_gland", 2, 0.9], ["beetle_meat", 2, 1.0], ["chitin_plate", 1, 0.6], ["chitin_plate", 1, 0.3]]},
	# Cave Spider (owner, Nov 19): a Zone 1 pest, Claude 1's model (cave_spider_v0..3.glb), in as it is for the owner to
	# test. Small groups; it scuttles in, bites, and pounces from a few metres (pounce = a leap during the lunge),
	# then skitters back (hit_and_run). Planned later: webs. One heavy hit or two light ones kill it.
	"cave_spider": {name = "Cave Spider", turns_in_place = true, turn_speed = 4.0, ragdoll = {hop = 0.5, spin = 2.0}, statue_hits = 2, size = 1.0, hp = 24, armor = 0, stun = 30, slash = 1.25, blunt = 1.0, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 2.2, run = 5.5, pack = [3, 5], xp = 6, leader = "Spider Broodmother", leader_chance = 0.15,
		color = Color(0.25, 0.22, 0.2), shape = "cave_spider", hit_and_run = true, retreat = 4.0, recover = 1.2,
		attacks = [{name = "Bite", warn_sound = "beetle_hiss", tell = 0.5, damage = 7, type = "pierce", reach = 1.5, parry = "any"},
			{name = "Pounce", warn_sound = "beetle_hiss", tell = 0.8, damage = 11, type = "pierce", reach = 5.0, parry = "any", lunge = true, pounce = true}],
		drops = [["bug_meat", 1, 1.0], ["bug_meat", 1, 0.4], ["spider_silk", 1, 0.7], ["spider_silk", 1, 0.35], ["venom_sac", 1, 0.3]]},
}


## {} for a creature the game no longer has (an old save's, Nov 19: the bosses and the
## other early creatures were taken out; only the five in LIST are left).
static func info(id: String) -> Dictionary:
	return LIST.get(id, {})


## Pack leader (doc 6.2) and the boost it gives its pack (doc 6.3). No crown: you spot it by its size (owner, Nov 19,
## F421: "take the crown off and make them a lot bigger").
const LEADER := {size = 1.8, hp = 2.5, damage = 1.3, stun = 1.5, armor = 10, xp = 3}
const PACK_BOOST := {damage = 0.20, speed = 0.15, stun = 0.25, decay = 2.0, radius = 15.0}

## Which monsters live where in each biome: big caverns / small rooms.
const SPAWNS := {
	# Owner's choice (Nov 14): only the first three for now. Snails + small beetles in Mossy Hollows,
	# bats roost in caverns everywhere, big beetles in the Fungal Jungle. (Old lists in git history.)
	# Bats aren't here: every cave has its own roost of them (MonsterManager._spawn_roost, owner Nov 19).
	# Cave spiders (owner, Nov 19): a Zone 1 pest, in big caverns and small rooms.
	"mossy": {big = ["rock_snail", "rock_snail", "rock_beetle", "cave_spider"], small = ["rock_snail", "rock_beetle", "cave_spider"]},
	"fungal": {big = ["great_rock_beetle"], small = ["great_rock_beetle"]},
}

const SIGHT := 15.0
const SIGHT_DARK := 8.0
const HEAR_RUN := 12.0
const HEAR_WALK := 6.0
const HEAR_DIG := 20.0
const LEASH := 40.0
const GIVE_UP := 10.0  ## seconds without reaching you before going home
const WANDER_RADIUS := 15.0


## Crystal variants (combat doc 7): crystals grow on their backs, glow, and add a power.
## shortcut: gem drops wait for the gem system; elemental resists are stored but only matter
## once players deal elemental damage.
const VARIANTS := {
	"red": {name = "Ember-crested", color = Color(1.0, 0.35, 0.2), extra_damage = 5, buildup = {burn = 30}, crystal = "crystal_red", count = 4, fire = 0.75, frost = -0.5},
	"blue": {name = "Rime-crested", color = Color(0.4, 0.75, 1.0), extra_damage = 5, buildup = {chill = 30}, crystal = "crystal_blue", count = 4, frost = 0.75, fire = -0.5},
	"green": {name = "Blight-crested", color = Color(0.4, 1.0, 0.45), extra_damage = 4, buildup = {poison = 35}, crystal = "crystal_green", count = 4, poison = 1.0, fire = -0.25},
	"violet": {name = "Shift-crested", color = Color(0.7, 0.45, 1.0), blink = 8.0, crystal = "crystal_violet", count = 3, pierce_mult = 1.25},
	"amber": {name = "Amber-crested", color = Color(1.0, 0.7, 0.25), armor = 30, crystal = "crystal_amber", count = 4, blunt_mult = 1.25},
}
const VARIANT_STATS := {hp = 1.4, damage = 1.1, stun = 1.2, xp = 2}
## [chance a spawned monster is a crystal variant, colour split] per biome (doc 7.3).
const VARIANT_CHANCE := {
	"mossy": [0.04, {red = 0.3, blue = 0.3, amber = 0.3, violet = 0.1}],
	"fungal": [0.07, {green = 0.35, red = 0.2, violet = 0.2, amber = 0.15, blue = 0.1}],
}


## Two dice (0..1) -> "" (normal) or a variant colour.
static func roll_variant(biome: String, chance_roll: float, colour_roll: float) -> String:
	var c: Array = VARIANT_CHANCE.get(biome, [0.0, {}])
	if chance_roll >= c[0]:
		return ""
	var acc := 0.0
	for colour in c[1]:
		acc += c[1][colour]
		if colour_roll < acc:
			return colour
	return c[1].keys()[-1]


## A monster's final numbers, with leader/variant boosts applied. Used for damage math.
static func target_stats(id: String, leader: bool, variant: String = "") -> Dictionary:
	var m: Dictionary = info(id)
	var v: Dictionary = VARIANTS.get(variant, {})
	return {armor = m.armor + (LEADER.armor if leader else 0) + v.get("armor", 0), slash = m.slash,
		blunt = m.blunt * v.get("blunt_mult", 1.0), pierce = m.pierce * v.get("pierce_mult", 1.0),
		fire = v.get("fire", m.fire), frost = v.get("frost", m.frost), poison = v.get("poison", m.poison)}


static func max_hp(id: String, leader: bool, variant: String = "") -> float:
	return info(id).hp * (LEADER.hp if leader else 1.0) * (VARIANT_STATS.hp if variant != "" else 1.0)
