class_name Mat
## Rock materials. Each voxel stores one of these numbers.
## The number is also the color slot in the terrain shader.

const MOSS := 0
const STONE := 1
const DIRT := 2
const COPPER := 3
const BORDER := 4

const NAMES := {MOSS: "Moss", STONE: "Stone", DIRT: "Dirt", COPPER: "Copper ore", BORDER: "Border rock"}

## How many "hit points" a spot of this rock has. -1 = can't be dug (yet).
const HARDNESS := {MOSS: 1, DIRT: 1, STONE: 3, COPPER: 5, BORDER: -1}

## What item you get from dug voxels of this material, and how many voxels make one item.
const DROP_ITEM := {MOSS: "dirt", DIRT: "dirt", STONE: "stone", COPPER: "copper_ore"}
const VOXELS_PER_ITEM := {MOSS: 4, DIRT: 4, STONE: 3, COPPER: 3}


static func hardness(mat: int) -> int:
	return HARDNESS.get(mat, 3)


static func is_diggable(mat: int) -> bool:
	return hardness(mat) > 0


## How many swings a tool with `power` needs for this material. 0 = impossible.
static func hits_needed(mat: int, power: int) -> int:
	var h := hardness(mat)
	if h <= 0 or power <= 0:
		return 0
	return ceili(float(h) / float(power))
