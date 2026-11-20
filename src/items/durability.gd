class_name Durability
## Tools and weapons wear out (Nov 20; makes Quick Fix, Thrifty and the Crafting ★25 repair discount work).
##  - Pickaxes, axes, weapons and shields. One "use" = a hit on rock, wood or a creature, or a blocked hit.
##  - They last USES[tier] uses: stone 150, copper 300, silver 500. Clothes and armor don't wear (yet).
##  - At 0 the item is BROKEN, not lost: it does nothing (bare hands) until repaired.
##  - Repair at the station that upgrades it (Upgrades.station_for). Cost: up to half of the item's main material
##    from its recipe, in proportion to how worn it is (at least 1).
## The wear lives on the item's slot: {id, count, used = 0..}, so it's saved and traded with the item.

const KINDS := ["pickaxe", "axe", "weapon", "shield"]
const USES := [150, 300, 500]  ## by tier: stone, copper, silver
const REPAIR_SHARE := 0.5
const WARN := 0.1  ## "almost worn out" at 10% left


static func wears(id: String) -> bool:
	return Items.kind(id) in KINDS


static func max_uses(id: String) -> int:
	return USES[clampi(Items.tier(id), 0, USES.size() - 1)]


static func used(slot: Dictionary) -> int:
	return int(slot.get("used", 0))


static func left(slot: Dictionary) -> int:
	return maxi(0, max_uses(slot.get("id", "")) - used(slot))


static func broken(slot: Dictionary) -> bool:
	return wears(slot.get("id", "")) and left(slot) <= 0


## 1.0 = like new, 0.0 = broken.
static func fraction(slot: Dictionary) -> float:
	return float(left(slot)) / float(max_uses(slot.get("id", "")))


## Adds one use. Returns "" or what to tell the player: "warn" (10% left) or "broke".
static func wear(slot: Dictionary) -> String:
	if slot.is_empty() or not wears(slot.id) or broken(slot):
		return ""
	slot["used"] = used(slot) + 1
	if broken(slot):
		return "broke"
	return "warn" if left(slot) == ceili(max_uses(slot.id) * WARN) else ""


## What a repair costs ({} = nothing to fix). `discount` 0.1 = 10% less (Thrifty, Crafting ★25), never below 1.
static func repair_cost(slot: Dictionary, discount: float = 0.0) -> Dictionary:
	var id: String = slot.get("id", "")
	if not wears(id) or used(slot) <= 0:
		return {}
	var mat := Upgrades.material_for(id)
	var base := int(Recipes.LIST.get(id, {}).get("inputs", {}).get(mat, 4))
	var worn := 1.0 - fraction(slot)
	return {mat: maxi(1, ceili(base * REPAIR_SHARE * worn * (1.0 - discount)))}


## "Copper Sword +2 (worn 40%)" style line for tooltips.
static func status_text(slot: Dictionary) -> String:
	if not wears(slot.get("id", "")):
		return ""
	if broken(slot):
		return "BROKEN: repair it at a %s" % Items.display_name(Upgrades.station_for(slot.id))
	return "Durability %d / %d" % [left(slot), max_uses(slot.id)]
