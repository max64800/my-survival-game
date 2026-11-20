class_name Gems
## Gems (owner's plan, Nov 20: docs/design/gems.md). Socketed at a Gem Bench into weapons, shields, tools
## (pickaxe, wood axe) and armor (head, chest, legs, feet).
##
## A socketed gem is stored on the item's own bag slot: {id = "sword_copper", count = 1, gems = ["keen_2"]}.
## A gem key is its kind plus its level: "keen" = Rough (1), "keen_2" = Cut, "keen_3" = Polished.
## 3 of the same gem at the same level combine into 1 of the next level (for gold).
## Socket counts by tier: stone/leather 0, copper 1, silver 1, iron 2, steel 2 + 1 epic.
## A 2nd copy of the same gem in one item works at half strength.
##
## Bonus keys (each gem's numbers are [Rough, Cut, Polished]):
##   weapon: keen (+share damage), guard (−share damage taken while swinging), stamina (−share), leech (heal this
##           share of damage), stun (+share), poison_chance / burn_chance / chill_chance (chance a hit adds a stack)
##   shield: parry_window (+share), block (+reduction points), block_stamina (−share), parry_heal (HP),
##           parry_stun (+share), block_poison / parry_burn / parry_chill (chance to give the attacker a stack)
##   tool  : dig (+share dig / chop power), extra_ore (chance), mine_stamina (−share)
##   armor : thorns (attacker takes this share back), guard_all (−share all damage), stamina_regen (+share),
##           double_ore (chance), heal (+share healing), stun_back (chance), resist_poison / resist_burn / resist_chill

const LEVEL_NAMES := ["Rough", "Cut", "Polished"]
const MAX_LEVEL := 3
const COMBINE_GOLD := {2: 10, 3: 30}  ## gold to make a gem of this level from 3 of the level below
const ELEMENT := [0.05, 0.15, 0.25]
const SMALL := [0.02, 0.05, 0.10]

const NORMAL := {
	"keen": {name = "Edge Quartz", color = Color(0.95, 0.95, 1.0),
		weapon = {keen = SMALL}, shield = {parry_window = SMALL}, tool = {}, armor = {thorns = SMALL}},
	"bulwark": {name = "Stone Amber", color = Color(1.0, 0.7, 0.25),
		weapon = {guard = SMALL}, shield = {block = SMALL}, tool = {}, armor = {guard_all = [0.01, 0.02, 0.05]}},
	"swift": {name = "Wind Amethyst", color = Color(0.7, 0.45, 1.0),
		weapon = {stamina = SMALL}, shield = {block_stamina = SMALL}, tool = {mine_stamina = SMALL}, armor = {stamina_regen = SMALL}},
	"burrow": {name = "Deep Onyx", color = Color(0.2, 0.22, 0.3),
		weapon = {}, shield = {}, tool = {dig = SMALL, extra_ore = SMALL}, armor = {double_ore = SMALL}},
	"leech": {name = "Blood Ruby", color = Color(0.6, 0.1, 0.15),
		weapon = {leech = SMALL}, shield = {parry_heal = [1.0, 2.0, 4.0]}, tool = {}, armor = {heal = SMALL}},
	"jolt": {name = "Storm Topaz", color = Color(1.0, 0.85, 0.25),
		weapon = {stun = ELEMENT}, shield = {parry_stun = ELEMENT}, tool = {}, armor = {stun_back = SMALL}},
	"blight": {name = "Bog Jade", color = Color(0.4, 0.8, 0.3),
		weapon = {poison_chance = ELEMENT}, shield = {block_poison = ELEMENT}, tool = {}, armor = {resist_poison = ELEMENT}},
	"ember": {name = "Forge Garnet", color = Color(1.0, 0.35, 0.2),
		weapon = {burn_chance = ELEMENT}, shield = {parry_burn = ELEMENT}, tool = {}, armor = {resist_burn = ELEMENT}},
	"rime": {name = "Frost Sapphire", color = Color(0.45, 0.65, 1.0),
		weapon = {chill_chance = ELEMENT}, shield = {parry_chill = ELEMENT}, tool = {}, armor = {resist_chill = ELEMENT}},
}
## Epic gems only fit a Steel item's epic socket. Steel isn't in the game yet, so for now
## they're prizes you carry and look forward to (doc 4.3 says that's on purpose).
const EPIC := {
	"cinder_wake": {name = "Cinder Wake (epic gem)", color = Color(1.0, 0.45, 0.1)},
	"hoarfrost_pulse": {name = "Hoarfrost Pulse (epic gem)", color = Color(0.6, 0.85, 1.0)},
	"echoing_guard": {name = "Echoing Guard (epic gem)", color = Color(0.85, 0.85, 0.6)},
	"rootbound_heart": {name = "Rootbound Heart (epic gem)", color = Color(0.45, 0.75, 0.3)},
	"bloomrot": {name = "Bloomrot (epic gem)", color = Color(0.55, 0.9, 0.35)},
	"shiftstep": {name = "Shiftstep (epic gem)", color = Color(0.75, 0.5, 1.0)},
}
const SOCKETS := [0, 1, 1, 2, 2]  ## normal sockets by tier
const REMOVE_COST := {gold_coin = 5}
## Which crystal-monster colour drops which gem (doc 7.4).
const VARIANT_GEM := {"red": "ember", "blue": "rime", "green": "blight", "violet": "swift", "amber": "bulwark"}
## Each creature's own gem: its statue gives it half the time (the other half: any gem).
const CREATURE_GEM := {"cave_spider": "blight", "rock_snail": "bulwark", "rock_beetle": "keen", "great_rock_beetle": "keen", "cave_bat": "swift"}
const STATUE_CHANCE := 0.02
## Each dungeon's 2 gems, by its theme (owner, Nov 20: "each dungeon should have a gem at the end").
const DUNGEON_GEMS := {
	"mossgate_hold": ["bulwark", "swift"], "lampwick_drift": ["burrow", "keen"], "old_pells_diggings": ["burrow", "blight"],
	"mossprop_workings": ["burrow", "bulwark"], "tomb_of_hald_ironbrow": ["leech", "bulwark"], "the_quiet_barrows": ["leech", "rime"],
	"brassgate_vault": ["keen", "jolt"], "hall_of_the_shieldbearers": ["bulwark", "keen"], "vigil_of_orrin_stonejaw": ["jolt", "rime"],
	"emberdeep_forge": ["ember", "keen"], "the_hammerfall_works": ["jolt", "swift"], "cinderhold_foundry": ["ember", "bulwark"],
}
const BOSS_CHANCE := 0.5  ## a boss drops a Rough gem half the time
const BIG_CUT_CHANCE := 0.5  ## a big dungeon's last chest: Cut half the time (the only place Cut gems drop)
const ARMOR_TIER := {"copper": 1, "silver": 2, "iron": 3}  ## armor has no "tier": its look says the metal
const ARMOR_SLOTS := ["head", "chest", "legs", "feet"]


static func item_id(gem: String) -> String:
	return "gem_" + gem


## "keen_2" -> "keen".
static func base_of(gem: String) -> String:
	var parts := gem.rsplit("_", true, 1)
	return parts[0] if parts.size() == 2 and parts[1] in ["2", "3"] else gem


## "keen" -> 1, "keen_2" -> 2.
static func level_of(gem: String) -> int:
	return int(gem.right(1)) if base_of(gem) != gem else 1


static func with_level(base: String, level: int) -> String:
	return base if level <= 1 else "%s_%d" % [base, level]


## "gem_keen_2" -> "keen_2" ("" if it isn't a gem).
static func gem_of(item: String) -> String:
	if not item.begins_with("gem_"):
		return ""
	var g := item.trim_prefix("gem_")
	return g if NORMAL.has(base_of(g)) or EPIC.has(g) else ""


## "Cut Edge Quartz".
static func full_name(gem: String) -> String:
	if EPIC.has(gem):
		return EPIC[gem].name
	return "%s %s" % [LEVEL_NAMES[level_of(gem) - 1], NORMAL[base_of(gem)].name]


## Where gems in this item count: "weapon", "shield", "tool", "armor" or "" (can't hold gems).
## The wood axe is a tool; the great axe is a weapon (owner, Nov 20).
static func slot_kind(item: String) -> String:
	match Items.kind(item):
		"weapon":
			return "weapon"
		"shield":
			return "shield"
		"pickaxe", "axe":
			return "tool"
		"wear":
			return "armor" if Items.info(item).get("slot", "") in ARMOR_SLOTS else ""
	return ""


static func socket_count(item: String) -> int:
	var where := slot_kind(item)
	if where == "":
		return 0
	var tier: int = ARMOR_TIER.get(Items.info(item).get("look", ""), 0) if where == "armor" else Items.tier(item)
	return SOCKETS[clampi(tier, 0, SOCKETS.size() - 1)]


## Can this gem go into this bag slot right now?
## shortcut: no "highest level per metal" check yet (only Rough/Cut/Polished exist, copper holds all three).
static func can_socket(slot: Dictionary, gem: String) -> bool:
	if slot.is_empty() or not NORMAL.has(base_of(gem)) or level_of(gem) > MAX_LEVEL:
		return false  # epic gems need an epic socket (Steel)
	return slot.get("gems", []).size() < socket_count(slot.id)


## What one gem gives where it sits: {key: number}.
static func effect(gem: String, where: String) -> Dictionary:
	var out := {}
	var b: Dictionary = NORMAL.get(base_of(gem), {}).get(where, {})
	for k in b:
		out[k] = b[k][level_of(gem) - 1]
	return out


## All the bonuses of the gems in a bag slot, for where that item is used.
static func bonus(slot: Dictionary) -> Dictionary:
	var out := {}
	var where := slot_kind(slot.get("id", ""))
	if where == "":
		return out
	var seen := {}
	for g in slot.get("gems", []):
		var strength := 0.5 if seen.has(base_of(g)) else 1.0  # the same gem twice: the 2nd works at 50%
		seen[base_of(g)] = true
		var e := effect(g, where)
		for k in e:
			out[k] = out.get(k, 0.0) + e[k] * strength
	return out


## The gems in all worn armor pieces together.
static func armor_bonus(inv: Inventory) -> Dictionary:
	var out := {}
	if not inv.is_player:
		return out
	for s in ARMOR_SLOTS:
		var b := bonus(inv.get_slot(Inventory.equip_index(s)))
		for k in b:
			out[k] = out.get(k, 0.0) + b[k]
	return out


## Short text of what a gem does in each kind of item (for tooltips).
static func describe(gem: String) -> String:
	var lines: Array[String] = [full_name(gem)]
	for where in ["weapon", "shield", "tool", "armor"]:
		var e := effect(gem, where)
		if not e.is_empty():
			var parts: Array[String] = []
			for k in e:
				parts.append("%s %s" % [k.replace("_", " "), str(e[k]) if k == "parry_heal" else "%d%%" % roundi(e[k] * 100.0)])
			lines.append("%s: %s" % [where.capitalize(), ", ".join(parts)])
	return "\n".join(lines)


## A dungeon's list id ("mossgate_hold") from its list id or map id ("mossgate").
static func dungeon_key(id: String) -> String:
	for k in DUNGEON_GEMS:
		if k == id or k.begins_with(id + "_"):
			return k
	return ""


## A dungeon's 2 gems (any gem for one we don't know).
static func dungeon_gems(id: String) -> Array:
	return DUNGEON_GEMS.get(dungeon_key(id), NORMAL.keys())


## The gem in a dungeon's last chest (two dice 0..1): always Rough, a big dungeon's 50/50 Cut.
static func end_chest_gem(id: String, roll_kind: float, roll_cut: float) -> String:
	var pair := dungeon_gems(id)
	var g: String = pair[mini(int(roll_kind * pair.size()), pair.size() - 1)]
	var big: bool = DungeonList.get_dungeon(dungeon_key(id)).get("size", "") == "big"
	return with_level(g, 2 if big and roll_cut < BIG_CUT_CHANCE else 1)


## A random gem kind of this level: half the time `favourite` (if given), else any of the 9.
static func roll(favourite: String = "", level: int = 1) -> String:
	var base: String = favourite if favourite != "" and randf() < 0.5 else NORMAL.keys().pick_random()
	return with_level(base, level)


## The best shield on the hotbar's bag slot (shield gems work while it's on your hotbar).
static func shield_slot(inv: Inventory) -> Dictionary:
	var best := inv.get_slot(Inventory.equip_index("shield")) if inv.is_player else {}  # the equipped shield (F23)
	for i in Inventory.HOTBAR_SIZE:
		var s := inv.get_slot(i)
		if not s.is_empty() and Items.kind(s.id) == "shield" and (best.is_empty() or Items.tier(s.id) > Items.tier(best.id)):
			best = s
	return best
