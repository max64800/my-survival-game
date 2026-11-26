class_name RuinTests
## The dev "Ruins" test worlds (owner, Nov 21): one small cave with one ruin in it, the dwarf at its Rebuilding Chest.
## Opening the chest rebuilds the whole ruin at once (stone or wood: the menu has a button for each). Dev builds only.
## Adding a ruin later = one line in LIST (its ruin class must read CaveMaker.<key>_spot, like the outpost does).
##   key: the ruin's name in the code (CaveMaker.<key>_spot, world_state[key]); name: the menu's name for it;
##   layout: its own test layout number (like CaveMaker.DUNGEON_ONLY, so saves and caches keep it apart);
##   half: how far its body reaches from its middle (its plan's radius, m: it stands on the lowest ground under it);
##   cave: the dome cave's size (half-widths, m); back: how far behind the cave's middle the ruin's middle stands, so
##   its front steps and Rebuilding Chest are in the open; hard: what its "stone" button says (default "Stone").
const LIST := [
	{key = "tower", half = 4.2, name = "Stone Watchtower", layout = 1101, cave = Vector3(20.0, 9.0, 20.0), back = 4.0},
	{key = "outpost", half = 18.5, name = "Fallen Outpost", layout = 1102, cave = Vector3(38.0, 9.0, 38.0), back = 6.0},
	{key = "brewhall", half = 8.6, name = "Brewhall", layout = 1103, cave = Vector3(24.0, 9.0, 24.0), back = 4.0, hard = "Brick"},
	{key = "spire", half = 4.2, name = "Lantern Spire", layout = 1104, cave = Vector3(30.0, 13.0, 30.0), back = 4.0},
	{key = "manor", half = 18.5, name = "Hearth Manor", layout = 1105, cave = Vector3(40.0, 15.0, 38.0), back = 6.0, hard = "Brick"},
	{key = "prow_hall", half = 26.0, name = "Prow Hall", layout = 1106, cave = Vector3(50.0, 20.0, 46.0), back = 2.0},
	{key = "twin_gate", half = 20.0, name = "Twin Gate", layout = 1107, cave = Vector3(46.0, 20.0, 44.0), back = 2.0},
	{key = "smeltery", half = 27.0, name = "Smeltery Terraces", layout = 1108, cave = Vector3(50.0, 26.0, 40.0), back = 2.0, hard = "Brick"},
	{key = "minehead", half = 28.0, name = "Mine-head Works", layout = 1110, cave = Vector3(52.0, 24.0, 26.0), back = 19.0},
	{key = "cliff_galleries", half = 25.0, name = "Cliff Galleries", layout = 1111, cave = Vector3(54.0, 30.0, 28.0), back = 21.0},
]


## The LIST entry for a test layout number ({} for every real layout).
static func of_layout(layout: int) -> Dictionary:
	for e in LIST:
		if int(e.layout) == layout:
			return e
	return {}


## The LIST entry for a ruin key ({} if there is none).
static func of_key(key: String) -> Dictionary:
	for e in LIST:
		if String(e.key) == key:
			return e
	return {}
