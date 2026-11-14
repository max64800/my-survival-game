class_name Upgrades
## Gear upgrades +1 to +3 (building polish spec §4).
##  - Pickaxes, axes, weapons, shields and clothes/armor can be upgraded 3 times.
##  - Stone/wood/leather gear at the Workbench, copper/silver gear at the Anvil.
##  - +1 needs station level 2, +2 level 3, +3 level 4 (or the station's top level).
##  - Each step costs the item's material × 2 / 4 / 6, plus a crystal (blue for +1/+2, green for +3).
##  - Each step: +15% dig power / damage / armor.
## The level lives on the item's slot: {id, count, up = 0..3}, so it's saved and traded with it.

const MAX_UP := 3
const PER_STEP := 0.15
const KINDS := ["pickaxe", "axe", "weapon", "shield", "wear"]


static func level(slot: Dictionary) -> int:
	return clampi(int(slot.get("up", 0)), 0, MAX_UP)


## The extra power from upgrades: 0.15 per step (0.45 at +3).
static func bonus(slot: Dictionary) -> float:
	return level(slot) * PER_STEP


static func can_upgrade(id: String) -> bool:
	return Items.kind(id) in KINDS


## "Copper Sword +2".
static func display_name(slot: Dictionary) -> String:
	var n := Items.display_name(slot.get("id", ""))
	return n + (" +%d" % level(slot) if level(slot) > 0 else "")


static func is_metal(id: String) -> bool:
	if id.contains("shell") or id.contains("leather"):
		return false  # Claude 3's shell gear is tier 1 but not metal
	return id.contains("copper") or id.contains("silver") or Items.tier(id) >= 1


## Which station upgrades it: "workbench" or "anvil".
static func station_for(id: String) -> String:
	return "anvil" if is_metal(id) else "workbench"


## The station level needed for the NEXT step.
static func needed_level(slot: Dictionary) -> int:
	var kind := station_for(slot.get("id", ""))
	return mini(level(slot) + 2, Station.max_level(kind))


## The item's main material.
static func material_for(id: String) -> String:
	if id.contains("shell"):
		return "shell_piece" if Items.exists("shell_piece") else "stone"
	if id.contains("leather"):
		return "leather"
	if id.contains("silver"):
		return "silver_ingot"
	if is_metal(id):
		return "copper_ingot"
	if Items.kind(id) == "wear":
		return "fiber"
	return "stone"


## What the next step costs ({} = can't go higher).
static func next_cost(slot: Dictionary) -> Dictionary:
	var id: String = slot.get("id", "")
	if not can_upgrade(id) or level(slot) >= MAX_UP:
		return {}
	var step := level(slot) + 1
	var c := {material_for(id): step * 2}
	c["crystal_green" if step == 3 else "crystal_blue"] = 1
	return c
