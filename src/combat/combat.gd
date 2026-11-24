class_name Combat
## Fighting rules (docs/design/combat-and-monsters.md sections 1-3).
## Everything here is plain math, so it can be checked by auto-checks and runs the same
## on every computer.

# --- Weapons (doc 3.2, Stone tier). speed = seconds per attack; hits land at 40% of that.
# type: slash / blunt / pierce. armor_break = share of armor ignored. hands: 1 or 2.
## Critical hits (owner, Nov 15, F137): every weapon has a small chance to hit much harder.
## Quick, pointy weapons crit a bit more often; big slow ones a bit less.
const CRIT_MULT := 1.75
const CRIT := {"sword": 0.08, "spear": 0.10, "axe": 0.07, "mace": 0.06, "axe_2h": 0.06, "mace_2h": 0.05, "pickaxe": 0.05, "fists": 0.05, "shield": 0.04, "crossbow": 0.08}


static func crit_chance(weapon: String) -> float:
	return float(CRIT.get(weapon, 0.06))


static var WEAPONS := {
	"sword": {type = "slash", light = 10, heavy = 22, light_speed = 0.55, heavy_speed = 1.10, reach = 1.8, light_sta = 8, heavy_sta = 18, light_stun = 6, heavy_stun = 18, parry_ms = 180, block = 0.35, hands = 1, combo = [1.0, 1.3, 1.8]},
	"axe": {type = "slash", light = 12, heavy = 26, light_speed = 0.70, heavy_speed = 1.30, reach = 1.7, light_sta = 10, heavy_sta = 20, light_stun = 8, heavy_stun = 22, parry_ms = 150, block = 0.35, hands = 1, combo = [1.0, 1.3, 1.8], cleave = 0.6},
	"mace": {type = "blunt", light = 11, heavy = 25, light_speed = 0.75, heavy_speed = 1.35, reach = 1.6, light_sta = 10, heavy_sta = 20, light_stun = 15, heavy_stun = 44, parry_ms = 150, block = 0.35, hands = 1, combo = [1.0, 1.2, 1.5, 2.0]},  # (4 hits: UAL 2's heavy combo, owner chat 15)
	"spear": {type = "pierce", light = 11, heavy = 24, light_speed = 0.60, heavy_speed = 1.20, reach = 2.6, light_sta = 9, heavy_sta = 18, light_stun = 6, heavy_stun = 16, parry_ms = 150, block = 0.35, hands = 1, combo = [1.0, 1.3, 1.9], armor_break = 0.4},
	"axe_2h": {type = "slash", light = 22, heavy = 48, light_speed = 1.10, heavy_speed = 1.90, reach = 2.2, light_sta = 16, heavy_sta = 32, light_stun = 14, heavy_stun = 40, parry_ms = 150, block = 0.50, hands = 2, combo = [1.0, 1.35, 1.9], sweep = true},
	"mace_2h": {type = "blunt", light = 24, heavy = 52, light_speed = 1.20, heavy_speed = 2.10, reach = 2.0, light_sta = 18, heavy_sta = 36, light_stun = 28, heavy_stun = 75, parry_ms = 150, block = 0.50, hands = 2, combo = [1.0, 1.8]},
	"shield": {type = "blunt", light = 5, heavy = 12, light_speed = 0.60, heavy_speed = 1.00, reach = 1.4, light_sta = 6, heavy_sta = 16, light_stun = 10, heavy_stun = 30, parry_ms = 200, block = 0.50, hands = 1, combo = [1.0]},
	# Tools still swing in a pinch (weak, but better than fists).
	"pickaxe": {type = "pierce", light = 6, heavy = 12, light_speed = 0.55, heavy_speed = 1.10, reach = 1.6, light_sta = 5, heavy_sta = 12, light_stun = 4, heavy_stun = 10, parry_ms = 120, block = 0.20, hands = 1, combo = [1.0]},
	# Crossbow (doc 3.2, 3.6): "light" = hip shot, "heavy" = aimed shot. Damage also × the bolt's multiplier.
	"crossbow": {type = "pierce", light = 24, heavy = 34, light_speed = 0.30, heavy_speed = 0.40, reach = 40.0, light_sta = 4, heavy_sta = 4, light_stun = 15, heavy_stun = 20, parry_ms = 80, block = 0.15, hands = 2, combo = [1.0], ranged = true, armor_break = 0.5},
	"fists": {type = "blunt", light = 3, heavy = 6, light_speed = 0.45, heavy_speed = 0.9, reach = 1.2, light_sta = 4, heavy_sta = 10, light_stun = 3, heavy_stun = 8, parry_ms = 100, block = 0.10, hands = 1, combo = [1.0, 1.3]},
}

## Tier scaling (doc 3.4): damage ×, stun ×, shield block.
const TIER_DAMAGE := [1.00, 1.30, 1.65, 2.05, 2.50]
const TIER_STUN := [1.00, 1.10, 1.20, 1.30, 1.40]
const SHIELD_BLOCK := [0.50, 0.60, 0.70, 0.80, 0.85]
const RELOAD := [3.4, 3.0, 2.6, 2.2, 1.8]  ## crossbow reload seconds by tier (owner Nov 20: doubled, then 1 s shorter)

# --- Crossbow bolts (doc 3.6)
const BOLT_RANGE := 40.0  ## full damage this far...
const BOLT_MAX := 60.0  ## ...then it fades out by here
const BOLT_SPEED := 55.0
const HIP_SPREAD := 3.0  ## degrees
const BOLTS := {
	"bolt_stone": {mult = 1.0},
	"bolt_metal": {mult = 1.2},
	"bolt_fang": {mult = 1.3},  # bat fang tips: sharper than metal
	"bolt_thumper": {mult = 1.1, type = "blunt", stun = 35.0, armor_break = 0.3},
	"bolt_ember": {mult = 0.9, elemental = {fire = 8.0}},
	"bolt_rime": {mult = 0.9, elemental = {frost = 8.0}},
	"bolt_blight": {mult = 0.9, elemental = {poison = 6.0}},
	"bolt_glow": {mult = 0.5, glow = 60.0},
}
## Which bolt gets fired: the first one found in this order (fancy bolts are kept for later).
const BOLT_ORDER := ["bolt_stone", "bolt_metal", "bolt_fang", "bolt_thumper", "bolt_glow", "bolt_blight", "bolt_ember", "bolt_rime"]

# --- Player (doc 1)
const DODGE_STAMINA := 20.0
const DODGE_DISTANCE := 3.0
const DODGE_TIME := 0.45
## Safe ("can't be hurt") from the first frame of the roll to 0.40 s in: almost the whole 0.45 s tap roll, only
## getting back up is open (F732, owner Nov 22: "need invulnerability window during roll"; it was 0.05-0.30 s,
## too short to feel). A held dash past 0.40 s is for distance, not safety.
const DODGE_IFRAME := Vector2(0.0, 0.40)
## Keep holding the dodge button past the usual roll and it keeps going, up to this long (F702: tap = short
## dash, hold = longer). Stays at or under DwarfRig.ROLL_TIME (0.75 s) so he's still mid-tumble the whole time.
const DASH_HOLD_MAX := 0.75
## How much past DASH_HOLD_MAX the roll animation keeps playing once a held dash ends (F798, owner Nov 23: "I am
## holding the control key all the way until the dwarf stops rolling... after my animation of the dodge is done,
## he propels me forward"). A held dash keeps moving right up to DASH_HOLD_MAX, so the stand-up finish can't land
## there like a tap roll's does (it would play mid-dash, not after it) — it gets this same tail budget instead,
## spent once the dash is over. Matches DwarfRig.ROLL_TIME - DODGE_TIME (0.75 - 0.45).
const DASH_RECOVERY_TAIL := 0.3
const COMBO_WINDOW := 0.5
const PARRY_COOLDOWN := 0.5  ## anti-spam: a new parry window can't start for 0.5 s
const RIPOSTE_TIME := 1.0
const FRIENDLY_FIRE := 0.5

# --- Stun (doc 2.5)
const STUN_SHIELD_PARRY := 40.0
const STUN_WEAPON_PARRY := 25.0
const STUN_SHIELD_BLOCK := 5.0
const STUN_DECAY := 8.0
const STUN_DECAY_DELAY := 2.5
const STUN_IMMUNE_AFTER := 2.0
## F594 Valheim-style: stun fill = damage dealt × this factor per weapon type.
const STUN_FACTOR := {blunt = 1.5, slash = 1.0, pierce = 0.8}

## Situations that multiply damage (doc 2.3). They don't stack: the biggest one counts.
const SNEAK := 2.0
const STUNNED := 1.5
const CRUSH := 2.0
const RIPOSTE := 1.3


## Stone swords, maces and spears have no combo finisher (owner, chat 16): their combo loops on the hits before it.
const NO_STONE_FINISHER := ["sword", "mace", "spear"]


## How many hits the combo has for this weapon at this tier.
static func combo_hits(w: String, tier: int) -> int:
	var n: int = (WEAPONS.get(w, WEAPONS.fists).combo as Array).size()
	return n - 1 if tier <= 0 and w in NO_STONE_FINISHER and n > 1 else n


## Only the great weapons have a heavy attack (F519), and not the stone ones (owner, chat 16).
static func has_heavy(w: String, tier: int) -> bool:
	return WEAPONS.get(w, WEAPONS.fists).hands == 2 and w != "crossbow" and tier > 0


## The last hit of a full combo (it can Crush a stunned enemy like a heavy hit did: owner, chat 16).
static func is_finisher(w: String, tier: int, combo_step: int) -> bool:
	var n: int = (WEAPONS.get(w, WEAPONS.fists).combo as Array).size()
	return n > 1 and combo_hits(w, tier) == n and combo_step == n - 1


## How a creature takes this damage type (owner, chat 16: the hit number's colour): 1 = weak to it (yellow),
## -1 = resists it (grey), 0 = normal (white).
static func effect(type: String, target: Dictionary) -> int:
	var m: float = target.get(type, 1.0)
	return 1 if m > 1.01 else (-1 if m < 0.99 else 0)


## Physical + elemental damage after armor and resistances (doc 2.2). Returns a whole number ≥ 1.
## w = weapon id, tier 0-4, quality/upgrade = bonus fractions (0.08 = +8%).
## target = {armor, slash, blunt, pierce (multipliers), fire/frost/poison (resist 0..1)}
static func damage(w: String, heavy: bool, tier: int, target: Dictionary, combo_step: int = 0,
		situation: float = 1.0, quality: float = 0.0, upgrade: float = 0.0, buff: float = 0.0, elemental := {}) -> int:
	var wd: Dictionary = WEAPONS.get(w, WEAPONS.fists)
	var base: float = wd.heavy if heavy else wd.light
	var combo: Array = wd.combo
	var cm: float = combo[mini(combo_step, combo.size() - 1)]
	var phys: float = base * TIER_DAMAGE[clampi(tier, 0, 4)] * (1.0 + quality) * (1.0 + upgrade) * cm * (1.0 + buff)
	phys *= target.get(wd.type, 1.0)
	var armor: float = target.get("armor", 0.0) * (1.0 - wd.get("armor_break", 0.0))
	phys *= 100.0 / (100.0 + armor)
	phys *= situation
	var elem := 0.0
	for e in elemental:
		elem += elemental[e] * (1.0 - minf(target.get(e, 0.0), 1.0))
	return maxi(1, roundi(phys + elem))


## The biggest situation multiplier that applies (they don't stack).
static func situation(sneak: bool, stunned: bool, first_heavy_on_stunned: bool, riposte: bool) -> float:
	var m := 1.0
	if sneak:
		m = maxf(m, SNEAK)
	if stunned:
		m = maxf(m, STUNNED)
	if first_heavy_on_stunned:
		m = maxf(m, CRUSH)
	if riposte:
		m = maxf(m, RIPOSTE)
	return m


## A crossbow bolt's damage. `dist` fades it out past 40 m.
static func shot_damage(aimed: bool, tier: int, bolt: String, target: Dictionary, dist: float, situation: float = 1.0, buff: float = 0.0, extra := {}) -> int:
	var b: Dictionary = BOLTS.get(bolt, BOLTS.bolt_stone)
	var wd: Dictionary = WEAPONS.crossbow
	var phys: float = (wd.heavy if aimed else wd.light) * TIER_DAMAGE[clampi(tier, 0, 4)] * b.mult
	phys *= target.get(b.get("type", "pierce"), 1.0)
	phys *= 100.0 / (100.0 + target.get("armor", 0.0) * (1.0 - maxf(b.get("armor_break", 0.0), wd.get("armor_break", 0.0))))  # (the crossbow pierces armor, F532)
	phys *= situation * range_falloff(dist) * (1.0 + buff)
	var elem := 0.0
	var el: Dictionary = b.get("elemental", {}).duplicate()
	for e in extra:  # gems in the crossbow
		el[e] = el.get(e, 0.0) + extra[e]
	for e in el:
		elem += el[e] * (1.0 - minf(target.get(e, 0.0), 1.0))
	return maxi(1, roundi(phys + elem)) if dist <= BOLT_MAX else 0


static func range_falloff(dist: float) -> float:
	return 1.0 if dist <= BOLT_RANGE else clampf(1.0 - (dist - BOLT_RANGE) / (BOLT_MAX - BOLT_RANGE), 0.0, 1.0)


## F594: stun fill = weapon base damage × tier × combo multiplier × stun type factor.
## combo_step matters because later combo hits land harder. Parry stun stays as absolute values.
static func stun_value(w: String, heavy: bool, tier: int, combo_step: int = 0) -> float:
	var wd: Dictionary = WEAPONS.get(w, WEAPONS.fists)
	var base: float = wd.heavy if heavy else wd.light
	var combo: Array = wd.combo
	var cm: float = combo[mini(combo_step, combo.size() - 1)]
	return base * TIER_DAMAGE[clampi(tier, 0, 4)] * cm * STUN_FACTOR.get(wd.type, 1.0)


## Judging a defense at the moment a hit lands (doc 2.4).
## pressed_ago = seconds since block was pressed (-1 = not holding block).
## Returns {result: "parry"|"block"|"hit", damage, stamina, stun}.
## crushing: only a shield perfect parry counts as a parry.
## bonus: shield gem bonuses (block = extra reduction, block_stamina = cheaper blocks).
static func defend(hit: float, pressed_ago: float, holding: bool, w: String, has_shield: bool, tier: int, crushing: bool = false, bonus: Dictionary = {}) -> Dictionary:
	var parry_ms: float = (WEAPONS.shield.parry_ms if has_shield else WEAPONS.get(w, WEAPONS.fists).parry_ms) * bonus.get("parry_mult", 1.0)
	var in_window := pressed_ago >= 0.0 and pressed_ago * 1000.0 <= parry_ms
	if holding and in_window and (has_shield or not crushing):
		return {result = "parry", damage = 0.0, stamina = 0.0, stun = STUN_SHIELD_PARRY if has_shield else STUN_WEAPON_PARRY}
	if holding:
		var reduction: float = SHIELD_BLOCK[clampi(tier, 0, 4)] if has_shield else WEAPONS.get(w, WEAPONS.fists).block
		reduction = minf(0.9, reduction + bonus.get("block", 0.0))  # block reduction caps at 90%
		return {result = "block", damage = hit * (1.0 - reduction), stamina = hit * (0.5 if has_shield else 1.0) * (1.0 - bonus.get("block_stamina", 0.0)),
			stun = STUN_SHIELD_BLOCK if has_shield else 0.0}
	return {result = "hit", damage = hit, stamina = 0.0, stun = 0.0}


## Weapon id for an item ("sword_copper" -> "sword"), or "" if it isn't a weapon.
static func weapon_of(item: String) -> String:
	if item == "":
		return "fists"
	var k := Items.kind(item)
	if k == "pickaxe":
		return "pickaxe"
	if k == "axe":
		return "axe"
	if k == "weapon" or k == "shield":
		return Items.info(item).weapon
	return "fists"


## What a weapon (or a tool or shield you can hit with) hits for, as one line for its tooltip and the crafting card
## (owner F571, Nov 21: "weapons should show their damage"): on an enemy without armor, with its tier and upgrades.
## "" for things that don't fight.
## What each damage type is good at, in plain words (owner F831). Numbers match the monster table (Monsters).
const TYPE_INFO := {
	slash = {name = "Slash", color = "e0a060", what = "Cuts. Good against most creatures, weaker on shells and stone."},
	blunt = {name = "Blunt", color = "c8b090", what = "Smashes. +25% on shells and stone, and knocks foes dizzy faster."},
	pierce = {name = "Pierce", color = "90c0e0", what = "Stabs. +25% on bats, weaker on ghosts."},
}


## The weapon's tip lines (BBCode, ItemTipSlot): its kind in colour, one hand or two, what that kind is good at.
static func type_text(id: String) -> String:
	var w := weapon_of(id)
	if w == "fists" or not WEAPONS.has(w):
		return ""
	var wd: Dictionary = WEAPONS[w]
	var t: Dictionary = TYPE_INFO[wd.type]
	var text := "[color=#%s][b]%s[/b][/color]  ·  %s" % [t.color, t.name, "two hands" if wd.hands == 2 else "one hand"]
	if wd.hands == 1 and Items.kind(id) == "weapon" and not wd.get("ranged", false):
		text += ", shield allowed"
	text += "\n[color=#b8a890]%s[/color]" % t.what
	if wd.get("armor_break", 0.0) > 0.0:
		text += "\n[color=#b8a890]Goes through %d%% of armour.[/color]" % roundi(wd.armor_break * 100.0)
	return text


static func damage_text(slot: Dictionary) -> String:
	var id: String = slot.get("id", "")
	var w := weapon_of(id)
	if w == "fists" or not WEAPONS.has(w):
		return ""
	var tier := maxi(Items.tier(id), 0)
	if w == "crossbow":
		return "Damage %d · aimed %d (stone bolt)" % [shot_damage(false, tier, "bolt_stone", {armor = 0}, 0.0),
			shot_damage(true, tier, "bolt_stone", {armor = 0}, 0.0)]
	var up := Upgrades.bonus(slot)
	var text := "Damage %d" % damage(w, false, tier, {armor = 0}, 0, 1.0, 0.0, up)
	if has_heavy(w, tier):
		text += " · heavy %d" % damage(w, true, tier, {armor = 0}, 0, 1.0, 0.0, up)
	return text
