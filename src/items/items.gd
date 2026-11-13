class_name Items
## The list of every item in the game, and what it is.
## Source of truth for ids and numbers: docs/design/progression-and-economy.md (section 1).
##
## Fields: name, stack (how many fit in one bag slot), color + short (the placeholder icon),
## kind (tool / food / drink / station / ...), and extra numbers for some kinds:
##   power + tier  : pickaxes and axes (dig/chop power, tier 0 = stone, 1 = copper, 2 = silver)
##   fuel          : seconds of lantern light per piece
##   hunger/thirst : what eating/drinking it refills
##   buff          : food buff id (see Foods)

const DATA := {
	# --- rock and soil
	"dirt": {name = "Dirt", color = Color(0.45, 0.32, 0.2), short = "Di"},
	"moss": {name = "Moss Clump", color = Color(0.3, 0.5, 0.22), short = "Mo"},
	"stone": {name = "Stone", color = Color(0.55, 0.52, 0.5), short = "St"},
	"clay": {name = "Orange Clay", color = Color(0.8, 0.45, 0.25), short = "Cl"},
	"marble": {name = "White Marble", color = Color(0.9, 0.9, 0.88), short = "Ma"},
	"basalt": {name = "Dark Basalt", color = Color(0.2, 0.2, 0.22), short = "Ba"},
	"brown_rock": {name = "Brown Rock", color = Color(0.45, 0.33, 0.24), short = "Br"},
	"ancient_brick": {name = "Ancient Brick", color = Color(0.55, 0.42, 0.35), short = "AB"},
	"sporestone": {name = "Sporestone", color = Color(0.3, 0.25, 0.35), short = "Sp"},
	"amberrock": {name = "Amberrock", color = Color(0.85, 0.65, 0.25), short = "Am"},
	# --- ores and crystals
	"copper_ore": {name = "Copper Ore", color = Color(0.85, 0.5, 0.25), short = "Cu"},
	"silver_ore": {name = "Silver Ore", color = Color(0.78, 0.8, 0.85), short = "Ag"},
	"crystal_blue": {name = "Blue Glow Crystal", color = Color(0.4, 0.75, 1.0), short = "Cr", kind = "fuel", fuel = 240.0},
	"crystal_green": {name = "Green Glow Crystal", color = Color(0.4, 1.0, 0.5), short = "Cg", kind = "fuel", fuel = 240.0},
	"crystal_violet": {name = "Violet Glow Crystal", color = Color(0.65, 0.45, 1.0), short = "Cv", kind = "fuel", fuel = 300.0},
	"crystal_amber": {name = "Amber Glow Crystal", color = Color(1.0, 0.75, 0.3), short = "Ca", kind = "fuel", fuel = 300.0},
	"crystal_white": {name = "White Glow Crystal", color = Color(0.95, 0.95, 1.0), short = "Cw", kind = "fuel", fuel = 600.0},
	"crystal_red": {name = "Red Glow Crystal", color = Color(1.0, 0.35, 0.3), short = "Cr", kind = "fuel", fuel = 240.0},
	"rusty_scrap": {name = "Rusty Scrap", color = Color(0.55, 0.35, 0.25), short = "Rs"},
	"glow_slime": {name = "Glow Slime", color = Color(0.6, 1.0, 0.6), short = "Sl", kind = "fuel", fuel = 60.0},
	# --- wood, plants, mushrooms
	"rootwood": {name = "Rootwood", color = Color(0.5, 0.35, 0.2), short = "Rw", kind = "fuel", fuel = 60.0},
	"mushroom_wood": {name = "Mushroom Timber", color = Color(0.75, 0.65, 0.55), short = "Mw", kind = "fuel", fuel = 60.0},
	"fiber": {name = "Cave Fiber", color = Color(0.55, 0.65, 0.35), short = "Fb"},
	"root_tuber": {name = "Root Tuber", color = Color(0.7, 0.5, 0.3), short = "Tu", kind = "food", hunger = 0},
	"glowcap": {name = "Glowcap", color = Color(0.3, 0.9, 0.85), short = "Gc", kind = "food", hunger = 8},
	"hollowcap": {name = "Hollowcap", color = Color(0.55, 0.4, 0.3), short = "Hc", kind = "food", hunger = 8},
	"bellcap": {name = "Juicy Bellcap", color = Color(0.6, 0.75, 1.0), short = "Bc", kind = "food", hunger = 15, thirst = 25},
	"firecap": {name = "Firecap", color = Color(0.95, 0.3, 0.2), short = "Fc"},
	"mushroom_flesh": {name = "Giant Mushroom Flesh", color = Color(0.85, 0.8, 0.75), short = "Mf"},
	"spore_truffle": {name = "Spore Truffle", color = Color(0.45, 0.35, 0.5), short = "Tr"},
	"ember_morel": {name = "Ember Morel", color = Color(0.95, 0.5, 0.2), short = "Em"},
	# --- animal parts
	"critter_meat": {name = "Critter Meat", color = Color(0.8, 0.35, 0.35), short = "Me", kind = "food", hunger = 10, upset = 0.3},
	"critter_hide": {name = "Critter Hide", color = Color(0.6, 0.45, 0.3), short = "Hi"},
	"beetle_meat": {name = "Beetle Meat", color = Color(0.7, 0.45, 0.4), short = "Bm", kind = "food", hunger = 10, upset = 0.3},
	"chitin_plate": {name = "Chitin Plate", color = Color(0.3, 0.4, 0.3), short = "Ch"},
	# --- water
	"waterskin_empty": {name = "Waterskin (empty)", stack = 1, color = Color(0.5, 0.4, 0.3), short = "Ws", kind = "waterskin"},
	"waterskin_dirty": {name = "Waterskin (pool water)", stack = 1, color = Color(0.45, 0.5, 0.35), short = "Ws", kind = "drink", thirst = 25, upset = 0.3, empties_to = "waterskin_empty"},
	"waterskin_clean": {name = "Waterskin (clean)", stack = 1, color = Color(0.35, 0.6, 0.9), short = "Ws", kind = "drink", thirst = 35, sips = 5, empties_to = "waterskin_empty"},
	"water_bucket": {name = "Bucket of Clean Water", stack = 20, color = Color(0.3, 0.55, 0.95), short = "Wb", kind = "drink", thirst = 35},
	# --- refined
	"plank_root": {name = "Rootwood Plank", color = Color(0.65, 0.48, 0.3), short = "Pl"},
	"plank_mushroom": {name = "Mushroom Plank", color = Color(0.82, 0.75, 0.62), short = "Pm"},
	"rope": {name = "Rope", color = Color(0.75, 0.65, 0.45), short = "Ro"},
	"leather": {name = "Leather", color = Color(0.55, 0.35, 0.2), short = "Le"},
	"copper_ingot": {name = "Copper Ingot", color = Color(0.9, 0.55, 0.3), short = "CI"},
	"silver_ingot": {name = "Silver Ingot", color = Color(0.85, 0.87, 0.92), short = "SI"},
	"clay_brick": {name = "Clay Brick", color = Color(0.8, 0.4, 0.25), short = "CB"},
	"lantern_lens": {name = "Crystal Lens", color = Color(0.7, 0.9, 1.0), short = "Ln"},
	"cut_stone": {name = "Cut Stone", color = Color(0.62, 0.6, 0.58), short = "CS"},
	"cut_marble": {name = "Cut Marble", color = Color(0.95, 0.95, 0.93), short = "CM"},
	"sporestone_block": {name = "Sporestone Block", color = Color(0.35, 0.3, 0.4), short = "SB"},
	"amber_block": {name = "Amber Block", color = Color(0.9, 0.7, 0.3), short = "AmB"},
	"mushroom_brick": {name = "Mushroom Brick", color = Color(0.8, 0.7, 0.6), short = "MB"},
	# --- boss parts
	"keeper_heartstone": {name = "Keeper's Heartstone", color = Color(0.4, 1.0, 0.7), short = "KH"},
	"bloomheart_core": {name = "Bloomheart Core", color = Color(1.0, 0.5, 0.8), short = "BC"},
	# --- tools
	"pickaxe_stone": {name = "Stone Pickaxe", stack = 1, color = Color(0.7, 0.68, 0.62), short = "Pk", kind = "pickaxe", power = 10, tier = 0},
	"pickaxe_copper": {name = "Copper Pickaxe", stack = 1, color = Color(0.9, 0.55, 0.3), short = "Pk", kind = "pickaxe", power = 13, tier = 1},
	"pickaxe_silver": {name = "Silver Pickaxe", stack = 1, color = Color(0.85, 0.87, 0.92), short = "Pk", kind = "pickaxe", power = 17, tier = 2},
	"axe_stone": {name = "Stone Axe", stack = 1, color = Color(0.7, 0.68, 0.62), short = "Ax", kind = "axe", power = 10, tier = 0},
	"axe_copper": {name = "Copper Axe", stack = 1, color = Color(0.9, 0.55, 0.3), short = "Ax", kind = "axe", power = 13, tier = 1},
	"axe_silver": {name = "Silver Axe", stack = 1, color = Color(0.85, 0.87, 0.92), short = "Ax", kind = "axe", power = 17, tier = 2},
	"build_hammer": {name = "Build Hammer", stack = 1, color = Color(0.6, 0.5, 0.4), short = "Hm", kind = "hammer"},
	"lantern_back": {name = "Back Lantern", stack = 1, color = Color(1.0, 0.8, 0.45), short = "BL", kind = "lantern"},
	# --- stations (placed in the world)
	"campfire": {name = "Campfire", stack = 1, color = Color(1.0, 0.55, 0.2), short = "Fi", kind = "station"},
	"workbench": {name = "Workbench", stack = 1, color = Color(0.6, 0.45, 0.3), short = "Wk", kind = "station"},
	"smelter": {name = "Smelter", stack = 1, color = Color(0.7, 0.4, 0.3), short = "Sm", kind = "station"},
	"anvil": {name = "Anvil", stack = 1, color = Color(0.35, 0.35, 0.38), short = "An", kind = "station"},
	"cooking_pot": {name = "Cooking Pot", stack = 1, color = Color(0.85, 0.5, 0.3), short = "CP", kind = "station"},
	"tanning_rack": {name = "Tanning Rack", stack = 1, color = Color(0.6, 0.45, 0.3), short = "TR", kind = "station"},
	"masonry_table": {name = "Masonry Table", stack = 1, color = Color(0.6, 0.6, 0.6), short = "MT", kind = "station"},
	"bed": {name = "Bed", stack = 1, color = Color(0.5, 0.35, 0.5), short = "Bd", kind = "station"},
	"rune_slab": {name = "Rune Slab", stack = 1, color = Color(0.5, 0.5, 0.6), short = "RS", kind = "station"},
	"farm_plot": {name = "Farm Plot", stack = 1, color = Color(0.35, 0.25, 0.15), short = "FP", kind = "station"},
	"drip_bucket": {name = "Drip Bucket", stack = 1, color = Color(0.45, 0.4, 0.35), short = "DB", kind = "station"},
	# --- weapons (combat doc 3). tier: 0 stone, 1 copper, 2 silver
	"sword_stone": {name = "Stone Sword", stack = 1, color = Color(0.65, 0.63, 0.6), short = "Sw", kind = "weapon", weapon = "sword", tier = 0},
	"mace_stone": {name = "Stone Mace", stack = 1, color = Color(0.65, 0.63, 0.6), short = "Mc", kind = "weapon", weapon = "mace", tier = 0},
	"spear_stone": {name = "Stone Spear", stack = 1, color = Color(0.65, 0.63, 0.6), short = "Sp", kind = "weapon", weapon = "spear", tier = 0},
	"shield_stone": {name = "Wooden Shield", stack = 1, color = Color(0.65, 0.63, 0.6), short = "Sh", kind = "shield", weapon = "shield", tier = 0},
	"axe_2h_stone": {name = "Stone Great Axe", stack = 1, color = Color(0.65, 0.63, 0.6), short = "GA", kind = "weapon", weapon = "axe_2h", tier = 0},
	"mace_2h_stone": {name = "Stone Great Maul", stack = 1, color = Color(0.65, 0.63, 0.6), short = "GM", kind = "weapon", weapon = "mace_2h", tier = 0},
	"sword_copper": {name = "Copper Sword", stack = 1, color = Color(0.9, 0.55, 0.3), short = "Sw", kind = "weapon", weapon = "sword", tier = 1},
	"mace_copper": {name = "Copper Mace", stack = 1, color = Color(0.9, 0.55, 0.3), short = "Mc", kind = "weapon", weapon = "mace", tier = 1},
	"spear_copper": {name = "Copper Spear", stack = 1, color = Color(0.9, 0.55, 0.3), short = "Sp", kind = "weapon", weapon = "spear", tier = 1},
	"shield_copper": {name = "Copper Shield", stack = 1, color = Color(0.9, 0.55, 0.3), short = "Sh", kind = "shield", weapon = "shield", tier = 1},
	"axe_2h_copper": {name = "Copper Great Axe", stack = 1, color = Color(0.9, 0.55, 0.3), short = "GA", kind = "weapon", weapon = "axe_2h", tier = 1},
	"mace_2h_copper": {name = "Copper Great Maul", stack = 1, color = Color(0.9, 0.55, 0.3), short = "GM", kind = "weapon", weapon = "mace_2h", tier = 1},
	"sword_silver": {name = "Silver Sword", stack = 1, color = Color(0.85, 0.87, 0.92), short = "Sw", kind = "weapon", weapon = "sword", tier = 2},
	"mace_silver": {name = "Silver Mace", stack = 1, color = Color(0.85, 0.87, 0.92), short = "Mc", kind = "weapon", weapon = "mace", tier = 2},
	"spear_silver": {name = "Silver Spear", stack = 1, color = Color(0.85, 0.87, 0.92), short = "Sp", kind = "weapon", weapon = "spear", tier = 2},
	"shield_silver": {name = "Silver Shield", stack = 1, color = Color(0.85, 0.87, 0.92), short = "Sh", kind = "shield", weapon = "shield", tier = 2},
	"axe_2h_silver": {name = "Silver Great Axe", stack = 1, color = Color(0.85, 0.87, 0.92), short = "GA", kind = "weapon", weapon = "axe_2h", tier = 2},
	"mace_2h_silver": {name = "Silver Great Maul", stack = 1, color = Color(0.85, 0.87, 0.92), short = "GM", kind = "weapon", weapon = "mace_2h", tier = 2},
	# --- storage (placed in the world)
	"chest_small": {name = "Chest", stack = 1, color = Color(0.55, 0.38, 0.22), short = "Ch", kind = "chest"},
	"chest_stone": {name = "Stone Chest", stack = 1, color = Color(0.55, 0.55, 0.55), short = "SC", kind = "chest"},
}

## Dishes and drinks are added from Foods (one list for food data).
static var _all := {}


static func _data() -> Dictionary:
	if _all.is_empty():
		_all = DATA.duplicate()
		for r in RuneSlab.RUNES:  # runes found while exploring, carved at the Rune Slab
			var colour := RuneSlab.colour_of(r)
			_all["rune_" + r] = {name = "%s Rune (%s)" % [colour.capitalize(), RuneSlab.COLOURS[colour].capitalize()],
				color = {"ochre": Color(0.8, 0.6, 0.25), "crimson": Color(0.85, 0.2, 0.25), "cobalt": Color(0.2, 0.35, 0.85), "verdant": Color(0.3, 0.8, 0.35)}[colour],
				short = "R" + r.right(2), kind = "rune"}
		for id in Foods.DISHES:
			var f: Dictionary = Foods.DISHES[id]
			_all[id] = {name = f.name, stack = 20, color = f.get("color", Color(0.9, 0.7, 0.4)), short = f.get("short", "Fd"),
				kind = "drink" if f.get("drink", false) else "food", hunger = f.get("hunger", 0), thirst = f.get("thirst", 0), buff = id}
	return _all


static func exists(id: String) -> bool:
	return _data().has(id)


static func info(id: String) -> Dictionary:
	return _data().get(id, {})


static func stack_size(id: String) -> int:
	return info(id).get("stack", 100)


static func display_name(id: String) -> String:
	return info(id).get("name", id)


static func color(id: String) -> Color:
	return info(id).get("color", Color.MAGENTA)


static func short_label(id: String) -> String:
	return info(id).get("short", id.left(2))


static func kind(id: String) -> String:
	return info(id).get("kind", "material")


## Pickaxe strength (×10 scale: stone pickaxe = 10). 0 = not a pickaxe.
static func dig_power(id: String) -> int:
	return info(id).power if kind(id) == "pickaxe" else 0


## Tool tier: 0 stone, 1 copper, 2 silver, ... -1 = not a tool.
static func tier(id: String) -> int:
	return info(id).get("tier", -1)


## Seconds of lantern light one of this item gives. 0 = not fuel.
static func fuel_seconds(id: String) -> float:
	return info(id).get("fuel", 0.0)


static func ids() -> Array:
	return _data().keys()
