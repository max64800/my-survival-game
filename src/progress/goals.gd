class_name Goals
## "Next steps" (owner, Nov 15, F103): a short to-do list on screen that shows the next few things to
## do in Mossy Hollows and ticks itself off as you go. Only looks at what the player has held
## (`seen`), what's built, and the stations in the world, so it works the same in co-op.

const SHOWN := 3  ## how many steps are on screen at once

## In order: [id, what to do].
const STEPS := [
	["rootwood", "Pull thin hanging roots by hand for rootwood"],
	["stone", "Pick up loose stones (or dig rock) for stone"],
	["pickaxe_stone", "Make a Stone Pickaxe: Tab, then craft by hand"],
	["workbench", "Make a Workbench by hand (10 rootwood, 6 stone) and place it"],
	["rope", "Pull green fiber tufts, then make Rope by hand (3 fiber)"],
	["sword_stone", "Make a Stone Sword at the Workbench (E to use it)"],
	["shield_stone", "Make a Shield at the Workbench"],
	["build_hammer", "Make a Build Hammer at the Workbench"],
	["masonry_table", "Make a Mason's Table at the Workbench and place it"],
	["shelter", "Build a shelter: hold the hammer, B to choose foundation, walls, a doorway"],
	["brick", "For brick buildings: place a Chisel Rack near your Mason's Table (level 2)"],
	["chopping_block", "Place a Chopping Block by your Workbench (Workbench level 2)"],
	["pickaxe_fang", "Hunt bats for 4 fangs, tan a hide, then make a Fang Pickaxe"],
	["copper_ore", "Find the Copper Deeps (far, low caverns) and mine copper with the Fang Pickaxe"],
	["copper_ingot", "Make a Smelter and smelt the copper ore"],
	["heartwood", "Chop the big Root Tree's roots with an axe until Heartwood falls out"],
	["pickaxe_copper", "Make a Copper Pickaxe at the Anvil with the Heartwood (it opens the way on)"],
]


## Is step `id` done for this player?
static func done(id: String, ps: GameAuthority.PlayerState, auth: GameAuthority) -> bool:
	match id:
		"workbench", "masonry_table":
			for st in auth.stations.values():
				if st.kind == id:
					return true
			return false
		"shelter":
			return auth.builder != null and auth.builder.structure.pieces.size() >= 4
		"chopping_block":
			for st in auth.stations.values():
				if st.kind == "chopping_block":
					return true
			return ps.seen.has("pickaxe_fang")
		"brick":
			for st in auth.stations.values():
				if st.kind == "masonry_table" and st.level() >= 2:
					return true
			return false
	return ps.seen.has(id) or ps.inventory.count_of(id) > 0


## The next few steps not done yet (texts). Empty when everything is done.
static func next_steps(ps: GameAuthority.PlayerState, auth: GameAuthority) -> Array:
	var out := []
	for s in STEPS:
		if not done(s[0], ps, auth):
			out.append(s[1])
			if out.size() >= SHOWN:
				break
	return out
