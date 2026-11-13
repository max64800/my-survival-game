class_name Items
## The list of every item in the game, and what it is.
## stack = how many fit in one bag slot. power = how strong a pickaxe digs.

const DATA := {
	"stone": {name = "Stone", stack = 100, color = Color(0.55, 0.52, 0.5), short = "St"},
	"dirt": {name = "Dirt", stack = 100, color = Color(0.45, 0.32, 0.2), short = "Di"},
	"copper_ore": {name = "Copper Ore", stack = 100, color = Color(0.85, 0.5, 0.25), short = "Cu"},
	"glow_crystal": {name = "Glow Crystal", stack = 100, color = Color(0.4, 0.75, 1.0), short = "Cr", fuel = 240.0},
	"glowcap": {name = "Glowcap Mushroom", stack = 100, color = Color(0.3, 0.9, 0.85), short = "Gc"},
	"stone_pickaxe": {name = "Stone Pickaxe", stack = 1, color = Color(0.7, 0.68, 0.62), short = "Pk", power = 1, kind = "pickaxe"},
}


static func exists(id: String) -> bool:
	return DATA.has(id)


static func stack_size(id: String) -> int:
	return DATA.get(id, {}).get("stack", 100)


static func display_name(id: String) -> String:
	return DATA.get(id, {}).get("name", id)


static func color(id: String) -> Color:
	return DATA.get(id, {}).get("color", Color.MAGENTA)


static func short_label(id: String) -> String:
	return DATA.get(id, {}).get("short", id.left(2))


## Pickaxe strength. 0 = not a pickaxe.
static func dig_power(id: String) -> int:
	return DATA.get(id, {}).get("power", 0)


## Seconds of lantern light one of this item gives. 0 = not fuel.
static func fuel_seconds(id: String) -> float:
	return DATA.get(id, {}).get("fuel", 0.0)
