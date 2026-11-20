class_name DungeonVariety
## Same dungeon, a bit different in each world (owner, Nov 20, F237; docs/design/zone1-dungeons/traps-and-variety.md,
## "Variety"). Pure: the same world seed + dungeon always give the same picks, so everyone in co-op sees one layout
## and refills keep it. The dungeon's room file lists what MAY change; the main path, deadly traps, key, mini boss
## and recipe stand are simply never in that list, so they never move.
##
## `layout` (from the dungeon's room file, PC):
##   swap_wings = [["east_wing", "west_wing"], ...]   side wings marked "swap"
##   hidden = ["buried_chest_a", ...]                 its 5-6 possible hidden spots (3 are used)
##   spots = {"chest_hall": 3, "bear_jaws_1": 2, ...}  each chest / small trap / hidden room: how many places it may sit
##   timed = ["carts", "pendulum_1"]                   triple carts and pendulum blades (3 timing patterns)
## Returns {mirror: bool, swapped: [the swapped wing pairs], hidden: [3 spots], spots: {thing: place 0..n-1},
##   timing: {thing: pattern 0..2}}.

const HIDDEN_USED := 3
const PATTERNS := 3


static func pick(world_seed: int, dungeon_id: String, layout: Dictionary) -> Dictionary:
	var out := {mirror = _rng(world_seed, dungeon_id, "mirror").randf() < 0.5, swapped = [], hidden = [], spots = {}, timing = {}}
	for pair in layout.get("swap_wings", []):
		if _rng(world_seed, dungeon_id, "swap " + str(pair)).randf() < 0.5:
			out.swapped.append(pair)
	var hidden: Array = layout.get("hidden", []).duplicate()
	var rng := _rng(world_seed, dungeon_id, "hidden")
	for i in mini(HIDDEN_USED, hidden.size()):
		out.hidden.append(hidden.pop_at(rng.randi_range(0, hidden.size() - 1)))
	var spots: Dictionary = layout.get("spots", {})
	for thing in spots:
		out.spots[thing] = _rng(world_seed, dungeon_id, "spot " + thing).randi_range(0, maxi(1, int(spots[thing])) - 1)
	for thing in layout.get("timed", []):
		out.timing[thing] = _rng(world_seed, dungeon_id, "timing " + thing).randi_range(0, PATTERNS - 1)
	return out


## One dice per choice, so adding a chest to a room file never changes the other picks.
static func _rng(world_seed: int, dungeon_id: String, what: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, dungeon_id, what])
	return rng
