class_name Mat
## Rock materials. Each voxel stores one of these numbers.
## The number is also the color slot in the terrain shader.
## Numbers from docs/design/progression-and-economy.md section 2 (×10 scale: stone pickaxe = 10).

const MOSS := 0
const STONE := 1
const DIRT := 2
const COPPER := 3
const BORDER := 4

const NAMES := {MOSS: "Moss", STONE: "Stone", DIRT: "Dirt", COPPER: "Copper ore", BORDER: "Border rock"}

## How much digging a spot of this rock needs.
const HARDNESS := {MOSS: 10, DIRT: 10, STONE: 26, COPPER: 45, BORDER: 80}
## The weakest pickaxe tier that can dig it (0 stone, 1 copper, 2 silver).
const MIN_TIER := {MOSS: 0, DIRT: 0, STONE: 0, COPPER: 0, BORDER: 1}
const TIER_NAMES := ["Stone", "Copper", "Silver", "Iron", "Steel"]

## What item you get from dug voxels of this material, and how many voxels make one item.
const DROP_ITEM := {MOSS: "moss", DIRT: "dirt", STONE: "stone", COPPER: "copper_ore"}
const VOXELS_PER_ITEM := {MOSS: 4, DIRT: 4, STONE: 3, COPPER: 3}
## Mining XP per finished dig (progression doc 7.2).
const DIG_XP := {MOSS: 1, DIRT: 1, STONE: 2, COPPER: 6, BORDER: 50}


static func hardness(mat: int) -> int:
	return HARDNESS.get(mat, 26)


static func min_tier(mat: int) -> int:
	return MIN_TIER.get(mat, 0)


## Can a pickaxe of this tier dig it at all?
static func is_diggable(mat: int, tool_tier: int = 99) -> bool:
	return tool_tier >= min_tier(mat)


## How many swings a pickaxe with `power` and `tool_tier` needs. 0 = impossible.
static func hits_needed(mat: int, power: float, tool_tier: int = 0) -> int:
	if power <= 0.0 or not is_diggable(mat, tool_tier):
		return 0
	return ceili(hardness(mat) / power - 0.0001)
