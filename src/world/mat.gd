class_name Mat
## Rock materials. Each voxel stores one of these numbers.
## The number is also the color slot in the terrain shader.
## Numbers from docs/design/progression-and-economy.md section 2 (×10 scale: stone pickaxe = 10).

const MOSS := 0
const STONE := 1
const DIRT := 2
const COPPER := 3
const BORDER := 4
const CLAY := 5
const TIN := 6  ## Zone 1 tin (F697): grey-silver specks in ordinary walls; needs a Copper Pickaxe
const PATH := 7  ## the old worn dirt path's packed dirt (F870 step 5, OldTrail): digs like dirt
# Fungal Jungle (world doc 2.7 numbering)
const MYCELIUM := 8  ## the jungle's "moss": soft white fungus mat on floors
const SILVER := 9
const AMBERROCK := 11
const SPORESTONE := 13  ## the jungle's default rock
const DWARF := 14  ## old dwarf stone: a dungeon's walls (owner, Nov 19): no pickaxe breaks it
const EDGE := 15  ## the end of the world: no pickaxe ever digs it

const NAMES := {MOSS: "Moss", STONE: "Stone", DIRT: "Dirt", COPPER: "Copper ore", BORDER: "Border rock", CLAY: "Orange clay", TIN: "Tin ore", PATH: "Packed dirt",
	MYCELIUM: "Mycelium", SILVER: "Silver ore", AMBERROCK: "Amberrock", SPORESTONE: "Sporestone", DWARF: "Old dwarf stone", EDGE: "World's edge"}

## How much digging a spot of this rock needs. Moss 20: the mossy top layer takes 2 hits with a stone pickaxe (owner, F196).
const HARDNESS := {MOSS: 20, DIRT: 10, PATH: 14, STONE: 26, COPPER: 45, BORDER: 80, CLAY: 15, TIN: 40,
	MYCELIUM: 10, SILVER: 55, AMBERROCK: 25, SPORESTONE: 30, DWARF: 999, EDGE: 999}
## The weakest pickaxe tier that can dig it (0 stone, 1 copper, 2 silver).
const MIN_TIER := {MOSS: 0, DIRT: 0, PATH: 0, STONE: 0, COPPER: 0, BORDER: 1, CLAY: 0, TIN: 1,
	MYCELIUM: 0, SILVER: 1, AMBERROCK: 0, SPORESTONE: 0, DWARF: 99, EDGE: 99}
const TIER_NAMES := ["Stone", "Copper", "Silver", "Iron", "Steel"]

## What item you get from dug voxels of this material, and how many voxels make one item.
const DROP_ITEM := {MOSS: "moss", DIRT: "dirt", PATH: "dirt", STONE: "stone", COPPER: "copper_ore", CLAY: "clay", TIN: "tin_ore",
	MYCELIUM: "dirt", SILVER: "silver_ore", AMBERROCK: "amberrock", SPORESTONE: "sporestone"}
const VOXELS_PER_ITEM := {MOSS: 4, DIRT: 4, PATH: 4, STONE: 3, COPPER: 3, CLAY: 2, TIN: 3,
	MYCELIUM: 4, SILVER: 3, AMBERROCK: 3, SPORESTONE: 3}
## Mining XP per finished dig (progression doc 7.2).
const DIG_XP := {MOSS: 1, DIRT: 1, PATH: 1, STONE: 2, COPPER: 6, BORDER: 50, CLAY: 1, TIN: 6,
	MYCELIUM: 1, SILVER: 8, AMBERROCK: 2, SPORESTONE: 2}

## Which rocks each biome is made of.
const PALETTES := {
	"mossy": {rock = STONE, floor = MOSS, under = DIRT, ore = COPPER, patch = CLAY},
	"fungal": {rock = SPORESTONE, floor = MYCELIUM, under = DIRT, ore = SILVER, patch = AMBERROCK},
}


## Ores: metal you smelt (hitting them always gives at least one, the Ore Smasher perk works on them).
static func is_ore(mat: int) -> bool:
	return mat == COPPER or mat == SILVER or mat == TIN


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
