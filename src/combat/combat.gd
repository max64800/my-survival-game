class_name Combat
## Fighting rules (docs/design/combat-and-monsters.md sections 1-3).
## Everything here is plain math, so it can be checked by auto-checks and runs the same
## on every computer.

# --- Weapons (doc 3.2, Stone tier). speed = seconds per attack; hits land at 40% of that.
# type: slash / blunt / pierce. armor_break = share of armor ignored. hands: 1 or 2.
const WEAPONS := {
	"sword": {type = "slash", light = 10, heavy = 22, light_speed = 0.55, heavy_speed = 1.10, reach = 1.8, light_sta = 8, heavy_sta = 18, light_stun = 6, heavy_stun = 18, parry_ms = 180, block = 0.35, hands = 1, combo = [1.0, 1.0, 1.25]},
	"axe": {type = "slash", light = 12, heavy = 26, light_speed = 0.70, heavy_speed = 1.30, reach = 1.7, light_sta = 10, heavy_sta = 20, light_stun = 8, heavy_stun = 22, parry_ms = 150, block = 0.35, hands = 1, combo = [1.0, 1.1, 1.3], cleave = 0.6},
	"mace": {type = "blunt", light = 11, heavy = 25, light_speed = 0.75, heavy_speed = 1.35, reach = 1.6, light_sta = 10, heavy_sta = 20, light_stun = 12, heavy_stun = 35, parry_ms = 150, block = 0.35, hands = 1, combo = [1.0, 1.2], armor_break = 0.3},
	"spear": {type = "pierce", light = 11, heavy = 24, light_speed = 0.60, heavy_speed = 1.20, reach = 2.6, light_sta = 9, heavy_sta = 18, light_stun = 6, heavy_stun = 16, parry_ms = 150, block = 0.35, hands = 1, combo = [1.0, 1.0, 1.1, 1.3]},
	"axe_2h": {type = "slash", light = 22, heavy = 48, light_speed = 1.10, heavy_speed = 1.90, reach = 2.2, light_sta = 16, heavy_sta = 32, light_stun = 14, heavy_stun = 40, parry_ms = 150, block = 0.50, hands = 2, combo = [1.0, 1.15], sweep = true},
	"mace_2h": {type = "blunt", light = 24, heavy = 52, light_speed = 1.20, heavy_speed = 2.10, reach = 2.0, light_sta = 18, heavy_sta = 36, light_stun = 22, heavy_stun = 60, parry_ms = 150, block = 0.50, hands = 2, combo = [1.0, 1.2], armor_break = 0.3},
	"shield": {type = "blunt", light = 5, heavy = 12, light_speed = 0.60, heavy_speed = 1.00, reach = 1.4, light_sta = 6, heavy_sta = 16, light_stun = 10, heavy_stun = 30, parry_ms = 200, block = 0.50, hands = 1, combo = [1.0]},
	# Tools still swing in a pinch (weak, but better than fists).
	"pickaxe": {type = "pierce", light = 6, heavy = 12, light_speed = 0.55, heavy_speed = 1.10, reach = 1.6, light_sta = 5, heavy_sta = 12, light_stun = 4, heavy_stun = 10, parry_ms = 120, block = 0.20, hands = 1, combo = [1.0]},
	# Crossbow (doc 3.2, 3.6): "light" = hip shot, "heavy" = aimed shot. Damage also × the bolt's multiplier.
	"crossbow": {type = "pierce", light = 24, heavy = 34, light_speed = 0.30, heavy_speed = 0.40, reach = 40.0, light_sta = 4, heavy_sta = 4, light_stun = 15, heavy_stun = 20, parry_ms = 80, block = 0.15, hands = 2, combo = [1.0], ranged = true},
	"fists": {type = "blunt", light = 3, heavy = 6, light_speed = 0.45, heavy_speed = 0.9, reach = 1.2, light_sta = 4, heavy_sta = 10, light_stun = 3, heavy_stun = 8, parry_ms = 100, block = 0.10, hands = 1, combo = [1.0, 1.0]},
}

## Tier scaling (doc 3.4): damage ×, stun ×, shield block.
const TIER_DAMAGE := [1.00, 1.30, 1.65, 2.05, 2.50]
const TIER_STUN := [1.00, 1.10, 1.20, 1.30, 1.40]
const SHIELD_BLOCK := [0.50, 0.60, 0.70, 0.80, 0.85]
const RELOAD := [2.2, 2.0, 1.8, 1.6, 1.4]  ## crossbow reload seconds by tier

# --- Crossbow bolts (doc 3.6)
const BOLT_RANGE := 40.0  ## full damage this far...
const BOLT_MAX := 60.0  ## ...then it fades out by here
const BOLT_SPEED := 55.0
const HIP_SPREAD := 3.0  ## degrees
const BOLTS := {
	"bolt_stone": {mult = 1.0},
	"bolt_metal": {mult = 1.2},
	"bolt_thumper": {mult = 1.1, type = "blunt", stun = 35.0, armor_break = 0.3},
	"bolt_ember": {mult = 0.9, elemental = {fire = 8.0}},
	"bolt_rime": {mult = 0.9, elemental = {frost = 8.0}},
	"bolt_blight": {mult = 0.9, elemental = {poison = 6.0}},
	"bolt_glow": {mult = 0.5, glow = 60.0},
}
## Which bolt gets fired: the first one found in this order (fancy bolts are kept for later).
const BOLT_ORDER := ["bolt_stone", "bolt_metal", "bolt_thumper", "bolt_glow", "bolt_blight", "bolt_ember", "bolt_rime"]

# --- Player (doc 1)
const DODGE_STAMINA := 20.0
const DODGE_DISTANCE := 3.0
const DODGE_TIME := 0.45
const DODGE_IFRAME := Vector2(0.05, 0.30)  ## safe from 0.05 s to 0.30 s into the roll
const HEAVY_HOLD := 0.3  ## hold left click this long for a heavy attack
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

## Situations that multiply damage (doc 2.3). They don't stack: the biggest one counts.
const SNEAK := 2.0
const STUNNED := 1.5
const CRUSH := 2.0
const RIPOSTE := 1.3


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
	phys *= 100.0 / (100.0 + target.get("armor", 0.0) * (1.0 - b.get("armor_break", 0.0)))
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


static func stun_value(w: String, heavy: bool, tier: int) -> float:
	var wd: Dictionary = WEAPONS.get(w, WEAPONS.fists)
	return (wd.heavy_stun if heavy else wd.light_stun) * TIER_STUN[clampi(tier, 0, 4)]


## Judging a defense at the moment a hit lands (doc 2.4).
## pressed_ago = seconds since block was pressed (-1 = not holding block).
## Returns {result: "parry"|"block"|"hit", damage, stamina, stun}.
## crushing: only a shield perfect parry counts as a parry.
## bonus: shield gem bonuses (block = extra reduction, block_stamina = cheaper blocks).
static func defend(hit: float, pressed_ago: float, holding: bool, w: String, has_shield: bool, tier: int, crushing: bool = false, bonus: Dictionary = {}) -> Dictionary:
	var parry_ms: float = WEAPONS.shield.parry_ms if has_shield else WEAPONS.get(w, WEAPONS.fists).parry_ms
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
