class_name Monsters
## Monster data for Mossy Hollows and the Fungal Jungle (combat doc 5.2, 5.3, 6, 7, 8).
## Each attack: tell = seconds of warning before it lands, reach in meters,
## parry: "any" (weapon or shield), "shield" (crushing: only a shield parry works).
## shortcut: poison buildup, spore clouds, blinding and hiding aren't built yet; those attacks
## deal plain damage for now (poison clouds as "poison" damage). Upgrade with the effects system.

const LIST := {
	"mossnipper": {name = "Mossnipper", size = 0.5, hp = 30, armor = 0, stun = 30, slash = 1.25, blunt = 1.0, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 2.0, run = 5.0, pack = [3, 5], xp = 5, leader = "Mossnipper Elder", leader_chance = 0.25,
		color = Color(0.35, 0.5, 0.28), shape = "crab",
		attacks = [{name = "Claw Pinch", tell = 0.5, damage = 6, type = "slash", reach = 1.3, parry = "any"},
			{name = "Scuttle Snap", tell = 0.6, damage = 8, type = "slash", reach = 1.4, parry = "any"}],
		drops = [["critter_meat", 1, 0.8], ["critter_hide", 2, 0.6]]},
	"skitterling": {name = "Skitterling", size = 0.5, hp = 40, armor = 0, stun = 35, slash = 1.0, blunt = 1.0, pierce = 1.25,
		fire = 0.0, frost = 0.0, poison = 0.0, walk = 3.0, run = 7.0, pack = [2, 4], xp = 7, leader = "Skitterling Ringleader", leader_chance = 0.25,
		color = Color(0.55, 0.6, 0.5), shape = "lizard", hit_and_run = true,
		attacks = [{name = "Bite", tell = 0.4, damage = 8, type = "pierce", reach = 1.3, parry = "any"},
			{name = "Pounce", tell = 0.7, damage = 12, type = "pierce", reach = 4.0, parry = "any", lunge = true}],
		drops = [["critter_hide", 1, 0.7], ["critter_meat", 1, 0.5]]},
	"wickwing": {name = "Wickwing", size = 0.35, hp = 25, armor = 0, stun = 20, slash = 1.0, blunt = 0.75, pierce = 1.5,
		fire = -0.5, frost = 0.0, poison = 0.0, walk = 6.0, run = 6.0, pack = [1, 3], xp = 5, leader = "Wickwing Lamplady", leader_chance = 0.15,
		color = Color(0.8, 0.75, 0.55), shape = "moth", flies = true, likes_light = true,
		attacks = [{name = "Dive", tell = 0.6, damage = 7, type = "pierce", reach = 1.5, parry = "any"}],
		drops = [["fiber", 2, 0.7]]},
	"bogbelly": {name = "Bogbelly", size = 1.0, hp = 70, armor = 5, stun = 60, slash = 1.0, blunt = 1.25, pierce = 1.0,
		fire = 0.0, frost = -0.25, poison = 0.25, walk = 1.5, run = 4.0, pack = [1, 1], xp = 12,
		color = Color(0.4, 0.5, 0.35), shape = "toad",
		attacks = [{name = "Tongue Lash", tell = 0.7, damage = 10, type = "blunt", reach = 5.0, parry = "any"},
			{name = "Belly Flop", tell = 1.1, damage = 16, type = "blunt", reach = 2.0, parry = "shield", knockdown = true}],
		drops = [["critter_meat", 2, 0.9]]},
	"rustwight": {name = "Rustwight", size = 0.7, hp = 90, armor = 25, stun = 80, slash = 0.75, blunt = 1.5, pierce = 0.75,
		fire = 0.25, frost = 0.0, poison = 1.0, walk = 2.0, run = 4.5, pack = [1, 2], xp = 20, leader = "Rustwight Captain", leader_chance = 0.3,
		color = Color(0.55, 0.38, 0.25), shape = "armor", sleeps = true,
		attacks = [{name = "Rusty Chop", tell = 0.7, damage = 14, type = "slash", reach = 1.8, parry = "any"},
			{name = "Two-Step", tell = 0.6, damage = 10, type = "slash", reach = 1.8, parry = "any", follow = {tell = 0.4, damage = 12}},
			{name = "Shield Shove", tell = 0.8, damage = 8, type = "blunt", reach = 1.6, parry = "any", push = 1.5}],
		drops = [["rusty_scrap", 3, 0.8]]},
	"cairnling": {name = "Cairnling", size = 1.0, hp = 120, armor = 40, stun = 120, slash = 0.5, blunt = 1.5, pierce = 0.75,
		fire = 0.5, frost = 0.5, poison = 1.0, walk = 2.0, run = 2.0, pack = [1, 1], xp = 30,
		color = Color(0.5, 0.5, 0.52), shape = "golem",
		attacks = [{name = "Stone Fist", tell = 0.9, damage = 18, type = "blunt", reach = 2.0, parry = "any"},
			{name = "Ruin Slam", tell = 1.2, damage = 24, type = "blunt", reach = 2.5, parry = "shield", knockdown = true},
			{name = "Rune Flare", tell = 1.0, damage = 12, type = "fire", reach = 4.0, parry = "any"}],
		drops = [["cut_stone", 6, 1.0]]},
	# ---- Fungal Jungle (combat doc 5.3). Players arrive with copper and leave with silver.
	"wheezecap": {name = "Wheezecap", size = 0.6, hp = 80, armor = 0, stun = 50, slash = 1.5, blunt = 1.0, pierce = 0.75,
		fire = -0.5, frost = 0.0, poison = 1.0, walk = 1.5, run = 3.0, pack = [2, 4], xp = 15, leader = "Wheezecap Puffmother", leader_chance = 0.25,
		color = Color(0.78, 0.7, 0.6), shape = "mushroom",
		attacks = [{name = "Cap Butt", tell = 0.6, damage = 12, type = "blunt", reach = 1.4, parry = "any"},
			{name = "Spore Puff", tell = 1.0, damage = 10, type = "poison", reach = 3.0, parry = "any"}],
		drops = [["mushroom_flesh", 2, 0.8], ["spore_powder", 1, 0.5]]},
	"needlemite": {name = "Needlemite", size = 0.55, hp = 45, armor = 10, stun = 40, slash = 1.0, blunt = 1.0, pierce = 1.5,
		fire = 0.0, frost = -0.25, poison = 0.5, walk = 3.0, run = 7.5, pack = [4, 7], xp = 10, leader = "Needlemite Broodkeeper", leader_chance = 0.2,
		color = Color(0.6, 0.72, 0.75), shape = "mite", hit_and_run = true,
		attacks = [{name = "Needle Jab", tell = 0.5, damage = 11, type = "pierce", reach = 1.4, parry = "any"},
			{name = "Leap Bite", tell = 0.7, damage = 14, type = "pierce", reach = 5.0, parry = "any", lunge = true}],
		drops = [["needle", 2, 0.7], ["venom_sac", 1, 0.25]]},
	"husk_charger": {name = "Husk Charger", size = 1.4, hp = 210, armor = 40, stun = 160, slash = 0.5, blunt = 1.5, pierce = 1.0,
		fire = 0.0, frost = 0.0, poison = 0.25, walk = 2.0, run = 5.0, pack = [1, 2], xp = 50,
		color = Color(0.42, 0.32, 0.2), shape = "beetle",
		attacks = [{name = "Horn Gore", tell = 0.9, damage = 22, type = "pierce", reach = 2.2, parry = "any"},
			{name = "Charge", tell = 1.3, damage = 30, type = "blunt", reach = 12.0, parry = "shield", knockdown = true, lunge = true},
			{name = "Shell Stomp", tell = 1.1, damage = 18, type = "blunt", reach = 3.0, parry = "any"}],
		drops = [["chitin_plate", 2, 0.9], ["beetle_meat", 3, 1.0], ["horn", 1, 0.3]]},
	"gill_stalker": {name = "Gill Stalker", size = 1.1, hp = 150, armor = 10, stun = 90, slash = 1.0, blunt = 1.0, pierce = 1.25,
		fire = -0.25, frost = 0.0, poison = 0.5, walk = 2.5, run = 6.0, pack = [1, 1], xp = 40,
		color = Color(0.5, 0.45, 0.6), shape = "mantis", sleeps = true,  # "hides" until you come close
		attacks = [{name = "Scythe Pair", tell = 0.6, damage = 14, type = "slash", reach = 2.0, parry = "any", follow = {tell = 0.4, damage = 14}},
			{name = "Ambush Lunge", tell = 1.0, damage = 26, type = "slash", reach = 5.0, parry = "any", lunge = true}],
		drops = [["scythe_blade", 1, 0.6], ["stalker_meat", 2, 0.8]]},
	"cap_spitter": {name = "Cap Spitter", size = 1.2, hp = 110, armor = 0, stun = 70, slash = 1.5, blunt = 0.75, pierce = 0.5,
		fire = -0.5, frost = 0.0, poison = 1.0, walk = 0.0, run = 0.0, pack = [1, 3], xp = 25,
		color = Color(0.85, 0.45, 0.3), shape = "mushroom",
		attacks = [{name = "Spore Bomb", tell = 1.2, damage = 15, type = "blunt", reach = 20.0, parry = "any", ranged = true},
			{name = "Root Snap", tell = 0.7, damage = 12, type = "pierce", reach = 2.0, parry = "any"}],
		drops = [["spitter_gill", 2, 0.7], ["glow_spores", 3, 0.6]]},
}

## Bosses (combat doc 8.2, 8.3). boss: "main" or "side". phases: from full health down; each lists
## its attacks and what happens when it starts. summon attacks call monsters (interrupted by 30 stun).
const BOSSES := {
	"orrumhal": {name = "Orrumhal, the Mossbound Keeper", boss = "main", biome = "mossy", size = 3.2, hp = 2000, armor = 30, stun = 200,
		slash = 0.75, blunt = 1.25, pierce = 0.75, fire = 0.25, frost = 0.25, poison = 1.0, walk = 2.5, run = 2.5, xp = 1000,
		color = Color(0.45, 0.5, 0.42), shape = "golem", room = "lair",
		drops = [["keeper_heartstone", 1, 1.0], ["copper_ingot", 10, 1.0]], runes = 2,
		phases = [
			{until = 0.65, attacks = ["fist_slam", "sweep", "rubble_toss"]},
			{until = 0.30, attacks = ["fist_slam", "sweep", "rubble_toss", "moss_grasp", "hall_quake"], on_enter = {summon = ["mossnipper", 4]}},
			{until = 0.0, attacks = ["fist_slam", "sweep", "rubble_toss", "moss_grasp", "hall_quake", "heart_pulse"], tell_mult = 0.85, armor = 0}],
		attack_list = {
			fist_slam = {name = "Fist Slam", tell = 1.1, damage = 35, type = "blunt", reach = 4.5, parry = "shield", knockdown = true},
			sweep = {name = "Sweep", tell = 0.9, damage = 25, type = "blunt", reach = 6.0, parry = "any"},
			rubble_toss = {name = "Rubble Toss", tell = 1.2, damage = 20, type = "blunt", reach = 14.0, parry = "any", ranged = true},
			moss_grasp = {name = "Moss Grasp", tell = 0.8, damage = 10, type = "blunt", reach = 10.0, parry = "any", ranged = true},
			hall_quake = {name = "Hall Quake", tell = 1.5, damage = 15, type = "blunt", reach = 9.0, parry = "any", follow = {tell = 1.0, damage = 15, follow = {tell = 1.0, damage = 15}}},
			heart_pulse = {name = "Heart Pulse", tell = 1.5, damage = 30, type = "fire", reach = 6.0, parry = "shield"}}},
	"skerra": {name = "Skerra, the Nipper Queen", boss = "side", biome = "mossy", size = 2.4, hp = 1000, armor = 15, stun = 120,
		slash = 1.25, blunt = 1.0, pierce = 1.0, fire = 0.0, frost = 0.0, poison = 0.0, walk = 3.0, run = 4.5, xp = 300,
		color = Color(0.4, 0.55, 0.3), shape = "crab", room = "nest_cavern",
		drops = [["copper_ore", 15, 1.0]], runes = 1,
		phases = [{until = 0.0, attacks = ["great_pinch", "burrow_strike", "mud_spit", "brood_call"]}],
		attack_list = {
			great_pinch = {name = "Great Pinch", tell = 0.8, damage = 18, type = "slash", reach = 3.0, parry = "any"},
			burrow_strike = {name = "Burrow Strike", tell = 1.0, damage = 22, type = "slash", reach = 4.0, parry = "shield", knockdown = true},
			mud_spit = {name = "Mud Spit", tell = 0.9, damage = 12, type = "blunt", reach = 12.0, parry = "any", ranged = true},
			brood_call = {name = "Brood Call", tell = 1.5, damage = 0, type = "blunt", reach = 30.0, parry = "any", summon = ["mossnipper", 4], cooldown = 40.0}}},
	"brask": {name = "Brask, the Rusted Thane", boss = "side", biome = "mossy", size = 1.6, hp = 900, armor = 45, stun = 150,
		slash = 0.75, blunt = 1.5, pierce = 0.75, fire = 0.25, frost = 0.0, poison = 1.0, walk = 2.5, run = 4.5, xp = 300,
		color = Color(0.55, 0.38, 0.25), shape = "armor", room = "great_hall",
		drops = [["copper_ingot", 6, 1.0], ["axe_copper", 1, 1.0]], runes = 1,
		phases = [
			{until = 0.5, attacks = ["greataxe_cleave", "twin_chop", "shield_charge"]},
			{until = 0.0, attacks = ["greataxe_cleave", "twin_chop", "shield_charge"], on_enter = {summon = ["rustwight", 2]}}],
		attack_list = {
			greataxe_cleave = {name = "Greataxe Cleave", tell = 1.0, damage = 30, type = "slash", reach = 2.8, parry = "shield"},
			twin_chop = {name = "Twin Chop", tell = 0.7, damage = 18, type = "slash", reach = 2.6, parry = "any", follow = {tell = 0.5, damage = 18}},
			shield_charge = {name = "Shield Charge", tell = 1.2, damage = 25, type = "blunt", reach = 5.0, parry = "any", knockdown = true}}},
	# ---- Fungal Jungle bosses (combat doc 8.4, 8.5)
	"thallus": {name = "Thallus, the Grey Bloom", boss = "main", biome = "fungal", size = 4.0, hp = 4400, armor = 20, stun = 260,
		slash = 1.25, blunt = 1.0, pierce = 1.0, fire = -0.5, frost = 0.0, poison = 1.0, walk = 2.5, run = 3.0, xp = 2000,
		color = Color(0.55, 0.55, 0.52), shape = "beetle", room = "lair",
		drops = [["bloomheart_core", 1, 1.0], ["silver_ingot", 10, 1.0]], runes = 2,
		phases = [
			{until = 0.70, attacks = ["cap_crush", "tendril_lash", "spore_volley"]},
			{until = 0.35, attacks = ["cap_crush", "tendril_lash", "spore_volley", "bloom_burst", "choking_exhale"], on_enter = {summon = ["wheezecap", 3]}},
			{until = 0.0, attacks = ["cap_crush", "tendril_lash", "bloom_burst", "choking_exhale", "trample"], tell_mult = 0.85}],
		attack_list = {
			cap_crush = {name = "Cap Crush", tell = 1.0, damage = 40, type = "blunt", reach = 5.0, parry = "shield", knockdown = true},
			tendril_lash = {name = "Tendril Lash", tell = 0.7, damage = 15, type = "slash", reach = 6.0, parry = "any", follow = {tell = 0.5, damage = 15, follow = {tell = 0.5, damage = 15}}},
			spore_volley = {name = "Spore Volley", tell = 1.2, damage = 15, type = "poison", reach = 18.0, parry = "any", ranged = true},
			bloom_burst = {name = "Bloom Burst", tell = 1.3, damage = 45, type = "blunt", reach = 14.0, parry = "shield", knockdown = true, ranged = true},
			choking_exhale = {name = "Choking Exhale", tell = 1.4, damage = 20, type = "poison", reach = 8.0, parry = "any"},
			trample = {name = "Trample", tell = 1.1, damage = 30, type = "blunt", reach = 12.0, parry = "any", knockdown = true, lunge = true}}},
	"old_ironshell": {name = "Old Ironshell", boss = "side", biome = "fungal", size = 2.6, hp = 1600, armor = 70, stun = 200,
		slash = 0.5, blunt = 1.5, pierce = 1.0, fire = 0.0, frost = 0.0, poison = 0.25, walk = 2.0, run = 5.5, xp = 600,
		color = Color(0.38, 0.3, 0.2), shape = "beetle", room = "silver_vault",
		drops = [["ironshell_plate", 3, 1.0], ["silver_ore", 20, 1.0]], runes = 1,
		phases = [
			{until = 0.5, attacks = ["juggernaut_charge", "horn_toss", "shell_quake"]},
			{until = 0.0, attacks = ["juggernaut_charge", "horn_toss", "shell_quake", "roll_over"], on_enter = {summon = ["husk_charger", 1]}}],
		attack_list = {
			juggernaut_charge = {name = "Juggernaut Charge", tell = 1.3, damage = 40, type = "blunt", reach = 14.0, parry = "shield", knockdown = true, lunge = true},
			horn_toss = {name = "Horn Toss", tell = 0.8, damage = 25, type = "pierce", reach = 3.0, parry = "any"},
			shell_quake = {name = "Shell Quake", tell = 1.2, damage = 20, type = "blunt", reach = 4.0, parry = "any"},
			roll_over = {name = "Roll Over", tell = 1.0, damage = 25, type = "blunt", reach = 3.0, parry = "any"}}},
	"sivix": {name = "Sivix, Mother of Needles", boss = "side", biome = "fungal", size = 2.2, hp = 1600, armor = 15, stun = 140,
		slash = 1.0, blunt = 1.0, pierce = 1.5, fire = -0.25, frost = -0.25, poison = 1.0, walk = 3.0, run = 5.0, xp = 600,
		color = Color(0.55, 0.75, 0.8), shape = "mite", room = "brood_hollow",
		drops = [["sivix_silk", 5, 1.0], ["venom_sac", 5, 1.0]], runes = 1,
		phases = [{until = 0.0, attacks = ["stinger_lance", "web_spray", "ceiling_drop", "brood_swarm"]}],
		attack_list = {
			stinger_lance = {name = "Stinger Lance", tell = 0.9, damage = 25, type = "pierce", reach = 3.0, parry = "any"},
			web_spray = {name = "Web Spray", tell = 1.1, damage = 8, type = "blunt", reach = 6.0, parry = "any"},
			ceiling_drop = {name = "Ceiling Drop", tell = 1.4, damage = 35, type = "blunt", reach = 10.0, parry = "shield", knockdown = true, ranged = true},
			brood_swarm = {name = "Brood Swarm", tell = 1.5, damage = 0, type = "blunt", reach = 30.0, parry = "any", summon = ["needlemite", 6], cooldown = 30.0}}},
	"gloamstalker": {name = "The Gloamstalker", boss = "side", biome = "fungal", size = 2.4, hp = 1400, armor = 15, stun = 130,
		slash = 1.0, blunt = 1.0, pierce = 1.25, fire = -0.25, frost = 0.0, poison = 0.5, walk = 3.0, run = 6.0, xp = 600,
		color = Color(0.6, 0.6, 0.75), shape = "mantis", room = "lantern_grove",
		drops = [["gloam_scythe", 2, 1.0], ["silver_ingot", 6, 1.0], ["crystal_white", 5, 1.0]], runes = 1,
		phases = [
			{until = 0.5, attacks = ["scythe_pair", "shadow_lunge", "smoke_gill"]},
			{until = 0.0, attacks = ["scythe_pair", "shadow_lunge", "smoke_gill"], on_enter = {summon = ["gill_stalker", 2]}, tell_mult = 0.9}],
		attack_list = {
			scythe_pair = {name = "Scythe Pair", tell = 0.6, damage = 20, type = "slash", reach = 2.8, parry = "any", follow = {tell = 0.4, damage = 20}},
			shadow_lunge = {name = "Shadow Lunge", tell = 1.0, damage = 35, type = "slash", reach = 8.0, parry = "shield", knockdown = true, lunge = true},
			smoke_gill = {name = "Smoke Gill", tell = 1.0, damage = 10, type = "poison", reach = 6.0, parry = "any"}}},
}

const BOSS_RESET_DISTANCE := 60.0
const BOSS_RESET_TIME := 30.0
const BOSS_DROP_RANGE := 60.0


static func info(id: String) -> Dictionary:
	return LIST[id] if LIST.has(id) else BOSSES.get(id, {})


## Pack leader (doc 6.2) and the boost it gives its pack (doc 6.3).
const LEADER := {size = 1.3, hp = 2.5, damage = 1.3, stun = 1.5, armor = 10, xp = 3}
const PACK_BOOST := {damage = 0.20, speed = 0.15, stun = 0.25, decay = 2.0, radius = 15.0}

## Which monsters live where in each biome: big caverns / small rooms.
const SPAWNS := {
	"mossy": {big = ["mossnipper", "mossnipper", "skitterling", "wickwing", "bogbelly", "rustwight"], small = ["mossnipper", "skitterling", "wickwing", "cairnling"]},
	"fungal": {big = ["wheezecap", "wheezecap", "needlemite", "husk_charger", "gill_stalker", "cap_spitter"], small = ["wheezecap", "needlemite", "cap_spitter", "gill_stalker"]},
}

const SIGHT := 15.0
const SIGHT_DARK := 8.0
const HEAR_RUN := 12.0
const HEAR_WALK := 6.0
const HEAR_DIG := 20.0
const LEASH := 40.0
const GIVE_UP := 10.0  ## seconds without reaching you before going home
const WANDER_RADIUS := 15.0


## A monster's final numbers, with leader/pack boosts applied. Used for damage math.
static func target_stats(id: String, leader: bool) -> Dictionary:
	var m: Dictionary = info(id)
	return {armor = m.armor + (LEADER.armor if leader else 0), slash = m.slash, blunt = m.blunt, pierce = m.pierce,
		fire = m.fire, frost = m.frost, poison = m.poison}


static func max_hp(id: String, leader: bool) -> float:
	return info(id).hp * (LEADER.hp if leader else 1.0)
