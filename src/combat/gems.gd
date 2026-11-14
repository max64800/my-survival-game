class_name Gems
## Gems go into weapons, shields and pickaxes (combat doc 4). They're socketed at a Gem Bench.
##
## A socketed gem is stored on the item's own bag slot: {id = "sword_copper", count = 1, gems = ["ember"]}.
## Socket counts by tier: stone 0, copper 1, silver 1, iron 2, steel 2 + 1 epic (doc 4.1).
## A 2nd copy of the same gem in one item works at half strength (doc 4.4).
##
## Bonus keys (what each gem adds where it sits):
##   weapon : fire / frost / poison (flat elemental damage), burn / chill / poisoned (buildup),
##            leech (heal this share of damage), stun (+share), stamina (−share), guard (−share damage
##            taken while swinging), keen (+share physical damage)
##   shield : parry_burn / parry_chill (buildup on the attacker), block_poison, parry_heal (HP),
##            parry_stun (+share), block_stamina (−share), block (+reduction points), bash (+share)
##   pickaxe: dig (+share dig power), extra_ore (chance), mine_stamina (−share)

const NORMAL := {
	"ember": {name = "Ember Gem", color = Color(1.0, 0.35, 0.2),
		weapon = {fire = 5.0, burn = 25.0}, shield = {parry_burn = 50.0}, pickaxe = {}},
	"rime": {name = "Rime Gem", color = Color(0.45, 0.75, 1.0),
		weapon = {frost = 5.0, chill = 25.0}, shield = {parry_chill = 50.0}, pickaxe = {}},
	"blight": {name = "Blight Gem", color = Color(0.4, 1.0, 0.4),
		weapon = {poison = 3.0, poisoned = 30.0}, shield = {block_poison = 20.0}, pickaxe = {}},
	"leech": {name = "Leech Gem", color = Color(0.6, 0.1, 0.15),
		weapon = {leech = 0.05}, shield = {parry_heal = 4.0}, pickaxe = {}},
	"jolt": {name = "Jolt Gem", color = Color(1.0, 0.9, 0.25),
		weapon = {stun = 0.30}, shield = {parry_stun = 0.30}, pickaxe = {}},
	"swift": {name = "Swift Gem", color = Color(0.7, 0.45, 1.0),
		weapon = {stamina = 0.15}, shield = {block_stamina = 0.20}, pickaxe = {mine_stamina = 0.25}},
	"bulwark": {name = "Bulwark Gem", color = Color(1.0, 0.7, 0.25),
		weapon = {guard = 0.10}, shield = {block = 0.08}, pickaxe = {}},
	"keen": {name = "Keen Gem", color = Color(0.95, 0.95, 1.0),
		weapon = {keen = 0.08}, shield = {bash = 0.25}, pickaxe = {}},
	"burrow": {name = "Burrow Gem", color = Color(0.55, 0.38, 0.22),
		weapon = {}, shield = {}, pickaxe = {dig = 0.20, extra_ore = 0.10}},
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
const REMOVE_COST := {crystal_blue = 5}
## Which crystal-monster colour drops which gem (doc 7.4).
const VARIANT_GEM := {"red": "ember", "blue": "rime", "green": "blight", "violet": "swift", "amber": "bulwark"}


static func item_id(gem: String) -> String:
	return "gem_" + gem


## "gem_ember" -> "ember" ("" if it isn't a gem).
static func gem_of(item: String) -> String:
	if not item.begins_with("gem_"):
		return ""
	var g := item.trim_prefix("gem_")
	return g if NORMAL.has(g) or EPIC.has(g) else ""


## Where gems in this item count: "weapon", "shield", "pickaxe" or "" (can't hold gems).
static func slot_kind(item: String) -> String:
	match Items.kind(item):
		"weapon", "axe":
			return "weapon"
		"shield":
			return "shield"
		"pickaxe":
			return "pickaxe"
	return ""


static func socket_count(item: String) -> int:
	if slot_kind(item) == "":
		return 0
	return SOCKETS[clampi(Items.tier(item), 0, SOCKETS.size() - 1)]


## Can this gem go into this bag slot right now?
static func can_socket(slot: Dictionary, gem: String) -> bool:
	if slot.is_empty() or not NORMAL.has(gem):
		return false  # epic gems need an epic socket (Steel)
	return slot.get("gems", []).size() < socket_count(slot.id)


## All the bonuses of the gems in a bag slot, for where that item is used.
static func bonus(slot: Dictionary) -> Dictionary:
	var out := {}
	var where := slot_kind(slot.get("id", ""))
	if where == "":
		return out
	var seen := {}
	for g in slot.get("gems", []):
		var b: Dictionary = NORMAL.get(g, {}).get(where, {})
		var strength := 0.5 if seen.has(g) else 1.0  # the same gem twice: the 2nd works at 50%
		seen[g] = true
		for k in b:
			out[k] = out.get(k, 0.0) + b[k] * strength
	return out


## The best shield on the hotbar's bag slot (shield gems work while it's on your hotbar).
static func shield_slot(inv: Inventory) -> Dictionary:
	var best := inv.get_slot(Inventory.equip_index("shield")) if inv.is_player else {}  # the equipped shield (F23)
	for i in Inventory.HOTBAR_SIZE:
		var s := inv.get_slot(i)
		if not s.is_empty() and Items.kind(s.id) == "shield" and (best.is_empty() or Items.tier(s.id) > Items.tier(best.id)):
			best = s
	return best
