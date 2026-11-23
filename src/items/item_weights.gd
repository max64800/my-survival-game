class_name ItemWeights
## Carry weight (owner, Nov 23, F793; choices in docs/decisions/2026-11-23-carry-weight.md).
## Every item weighs something (stone = 1). Up to HEAVY you walk normally; from HEAVY to the max you slow
## down a little more with every extra bit; past the max you are OVERLOADED: a slow plod, no sprint, dodge or jump.
## Also the stack sizes (how many fit in one bag slot) for items that don't set their own `stack` in Items.
## Co-op: the host owns every inventory and sends it to each player, and these numbers are the same code on
## every PC, so each player's own dwarf works out its own slowdown. Nothing extra to sync.

const HEAVY := 200.0  ## start slowing down here
const MAX := 300.0  ## past this: OVERLOADED
const WORN_FACTOR := 0.5  ## worn gear (equipment slots) counts half: dwarves carry armor well
const HEAVY_SLOWEST := 0.75  ## speed just under the max (100% at HEAVY, easing down to this)
const OVERLOADED_SPEED := 0.4  ## speed past the max
const DEEP_POCKETS_PER_RANK := 25.0  ## the Deep Pockets perk (3 ranks = +75)
## Backpacks add to both limits. Better backpacks later go here.
const PACK_BONUS := {"satchel": 60.0}

enum Load { LIGHT, HEAVY, OVERLOADED }

## [weight, stack] per kind of item. A kind not listed uses UNKNOWN.
const BY_KIND := {
	"material": [1.0, 50],  # (most materials are sorted into groups below, by id)
	"food": [0.2, 20], "drink": [0.5, 10], "tonic": [0.3, 10], "fuel": [0.5, 30], "ammo": [0.1, 100],
	"seed": [0.05, 20], "throw": [0.5, 20], "page": [0.0, 50], "rune": [0.5, 30], "gem": [0.5, 30],
	"lens": [0.5, 1], "key": [0.1, 1], "horn": [2.0, 1], "pack": [2.0, 1], "lantern": [2.0, 1],
	"pickaxe": [4.0, 1], "axe": [4.0, 1], "hammer": [4.0, 1], "shovel": [4.0, 1],
	"weapon": [5.0, 1], "shield": [6.0, 1], "wear": [3.0, 1], "station": [10.0, 1], "chest": [8.0, 1],
}
const UNKNOWN := [0.5, 50]

## Groups of items by id: [weight, stack].
const GROUPS := {
	"rock": [1.0, 50], "ore": [1.5, 50], "metal": [2.0, 30], "crystal": [0.5, 30], "wood": [0.5, 50],
	"light": [0.1, 50], "hide": [0.3, 50], "part": [0.5, 50], "small_part": [0.1, 50], "mushroom": [0.2, 20],
	"coin": [0.0, 100],
}
const GROUP_OF := {
	"dirt": "rock", "stone": "rock", "clay": "rock", "marble": "rock", "basalt": "rock", "brown_rock": "rock",
	"ancient_brick": "rock", "sporestone": "rock", "amberrock": "rock", "clay_brick": "rock", "mortar": "rock",
	"cut_stone": "rock", "cut_marble": "rock", "sporestone_block": "rock", "amber_block": "rock", "mushroom_brick": "rock",
	"copper_ore": "ore", "silver_ore": "ore",
	"copper_ingot": "metal", "silver_ingot": "metal", "rusty_scrap": "metal",
	"crystal_blue": "crystal", "crystal_green": "crystal", "crystal_violet": "crystal", "crystal_amber": "crystal",
	"crystal_white": "crystal", "crystal_red": "crystal", "bloomheart_core": "crystal", "lantern_lens": "crystal",
	"rootwood": "wood", "coal": "wood", "mushroom_wood": "wood", "plank_root": "wood", "plank_mushroom": "wood",
	"heartwood": "wood",
	"fiber": "light", "moss": "light", "tree_moss": "light", "spider_silk": "light", "spore_powder": "light",
	"rope": "hide", "leather": "hide", "wing_leather": "hide",
	"chitin_plate": "part", "shell_piece": "part",
	"bat_fang": "small_part", "venom_sac": "small_part", "glow_gland": "small_part",
	"firecap": "mushroom", "mushroom_flesh": "mushroom", "spore_truffle": "mushroom", "ember_morel": "mushroom",
	"gold_coin": "coin",
}
## Single items that don't match their kind's number.
const WEIGHT_OF := {
	# small lights and light station kits
	"crystal_sconce": 1.0, "glow_lamp": 1.0, "crystal_torch": 0.5, "glow_marker": 0.2, "rope_ladder": 2.0,
	"drip_bucket": 3.0, "water_bucket": 2.0, "campfire": 5.0, "training_dummy": 6.0,
	# big heavy stations
	"anvil": 20.0, "smelter": 15.0, "twin_smelter": 20.0, "stone_oven": 15.0, "stone_saw": 15.0,
	# armor: leather light, shell middle, copper heavy
	"cap_leather": 1.5, "boots_leather": 1.5, "trousers_leather": 2.5, "tunic_leather": 3.0,
	"helm_shell": 2.5, "boots_shell": 2.5, "greaves_shell": 4.0, "plate_shell": 5.0,
	"helm_copper": 3.5, "boots_copper": 3.5, "greaves_copper": 6.0, "mail_copper": 8.0, "spore_mask": 1.0,
	"shield_stone": 8.0, "shield_shell": 5.0,
	"bandage": 0.1, "waterskin_empty": 0.3, "satchel": 2.0, "whetstone": 0.5, "build_hammer": 3.0,
}


## How much one of this item weighs.
static func weight(id: String) -> float:
	if WEIGHT_OF.has(id):
		return WEIGHT_OF[id]
	if GROUP_OF.has(id):
		return GROUPS[GROUP_OF[id]][0]
	if "_2h_" in id:
		return 8.0  # two-handed weapons
	return _kind_row(id)[0]


## How many fit in one bag slot when the item doesn't set its own `stack` (Items.stack_size asks this).
static func default_stack(id: String) -> int:
	if GROUP_OF.has(id):
		return GROUPS[GROUP_OF[id]][1]
	return _kind_row(id)[1]


static func _kind_row(id: String) -> Array:
	return BY_KIND.get(Items.kind(id), UNKNOWN)


## True when an item falls through to UNKNOWN (tests use this: every item must have a real weight).
static func is_unsorted(id: String) -> bool:
	if WEIGHT_OF.has(id) or GROUP_OF.has(id) or "_2h_" in id:
		return false
	var k := Items.kind(id)
	return k == "material" or not BY_KIND.has(k)  # (a plain material must be put in a group by id)


## Everything a dwarf (or chest) is carrying. Worn gear counts half.
static func total(inv: Inventory) -> float:
	var t := 0.0
	for i in inv.slots.size():
		var s: Dictionary = inv.slots[i]
		if s.is_empty():
			continue
		var w := weight(str(s.id)) * int(s.get("count", 1))
		t += w * WORN_FACTOR if inv.is_player and Inventory.is_equip_index(i) else w
	return t


## How much more the limits go up: backpack, Deep Pockets perk, then food/drink "carry" buffs (+0.2 = +20%).
static func bonus(inv: Inventory, prog: Progression) -> float:
	var b: float = PACK_BONUS.get(inv.equipped("pack"), 0.0) if inv.is_player else 0.0
	if prog:
		b += DEEP_POCKETS_PER_RANK * prog.perk_rank("deep_pockets")
	return b


## [heavy, max] for this dwarf. `buff` = the body's "carry" buff (a fraction).
static func limits(inv: Inventory, prog: Progression, buff: float = 0.0) -> Vector2:
	var b := bonus(inv, prog)
	var k := maxf(0.1, 1.0 + buff)
	return Vector2((HEAVY + b) * k, (MAX + b) * k)


static func load_of(weight_now: float, lim: Vector2) -> Load:
	if weight_now > lim.y:
		return Load.OVERLOADED
	return Load.HEAVY if weight_now > lim.x else Load.LIGHT


## Walking/sprinting speed multiplier for a load.
static func speed_mult(weight_now: float, lim: Vector2) -> float:
	if weight_now > lim.y:
		return OVERLOADED_SPEED
	if weight_now <= lim.x:
		return 1.0
	var t := (weight_now - lim.x) / maxf(lim.y - lim.x, 0.001)
	return lerpf(1.0, HEAVY_SLOWEST, t)


## A player's load, all in one go: {weight, heavy, max, load, speed}. `ps` = GameAuthority.PlayerState.
static func for_player(ps) -> Dictionary:
	var w := total(ps.inventory)
	var lim := limits(ps.inventory, ps.progress, ps.vitals.buff_total("carry") if ps.vitals else 0.0)
	return {weight = w, heavy = lim.x, max = lim.y, load = load_of(w, lim), speed = speed_mult(w, lim)}


## Pretty number for the screen: whole numbers, one decimal only when small.
static func pretty(w: float) -> String:
	return str(roundi(w)) if w >= 10.0 or is_equal_approx(w, roundf(w)) else "%.1f" % w
