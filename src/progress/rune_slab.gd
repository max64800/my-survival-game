class_name RuneSlab
extends RefCounted
## The world's Rune Slab (progression doc section 8). One per world, shared by every player.
##  - Runes are found while exploring. Carving one unlocks a recipe or a small bonus.
##  - 4 colours (one per skill branch). Each biome has one set per colour.
##    Mossy sets have 5 runes, Fungal sets have 6. Finish a set = a big "set perk".
##  - A rune you already carved turns into a shard. 3 shards of a colour = carve any
##    missing rune of that colour.

signal carved(rune_id: String)
signal set_finished(set_id: String)

const COLOURS := {"ochre": "mining", "crimson": "fighting", "cobalt": "smithing", "verdant": "survival"}
const BIOME_SET_SIZE := {"m": 5, "f": 6}  ## m = Mossy Hollows, f = Fungal Jungle
const SHARDS_PER_RUNE := 3

## What each rune does. "recipe" teaches a recipe id; any other key is a bonus everyone gets.
const RUNES := {
	"ochre_m1": {recipe = "crystal_sconce"}, "ochre_m2": {lantern_fuel = 0.10}, "ochre_m3": {recipe = "rope_ladder"},
	"ochre_m4": {pickup_radius_m = 2.0}, "ochre_m5": {stone_bonus_chance = 0.10},
	"ochre_f1": {recipe = "blasting_pod"}, "ochre_f2": {dig_power = 0.05}, "ochre_f3": {recipe = "glow_marker"},
	"ochre_f4": {silver_double = 0.10}, "ochre_f5": {crystal_bonus = 1}, "ochre_f6": {recipe = "prospectors_lens"},
	"crimson_m1": {recipe = "training_dummy"}, "crimson_m2": {max_health_flat = 5}, "crimson_m3": {recipe = "whetstone"},
	"crimson_m4": {stamina_regen = 0.05}, "crimson_m5": {dodge_stamina = -0.05},
	"crimson_f1": {recipe = "spore_bomb"}, "crimson_f2": {heavy_damage = 0.05}, "crimson_f3": {recipe = "bugbane_oil"},
	"crimson_f4": {max_health_flat = 5}, "crimson_f5": {parry_stun = 0.05}, "crimson_f6": {recipe = "war_horn"},
	"cobalt_m1": {recipe = "ruin_style"}, "cobalt_m2": {smelt_speed = 0.10}, "cobalt_m3": {recipe = "chest_copper"},
	"cobalt_m4": {quality_smithing = 5}, "cobalt_m5": {recipe = "crate_ore"},
	"cobalt_f1": {recipe = "mushroom_style"}, "cobalt_f2": {upgrade_cost = -0.10}, "cobalt_f3": {recipe = "twin_smelter"},
	"cobalt_f4": {build_range_m = 2.0}, "cobalt_f5": {quality_smithing = 5}, "cobalt_f6": {blueprint_speed = 0.25},
	"verdant_m1": {recipe = "dish_glow_broth"}, "verdant_m2": {hunger_drain = -0.05}, "verdant_m3": {recipe = "copper_drip_basin"},
	"verdant_m4": {farm_speed = 0.10}, "verdant_m5": {recipe = "drink_moss_ale"},
	"verdant_f1": {recipe = "dish_spore_ward_stew"}, "verdant_f2": {thirst_drain = -0.05}, "verdant_f3": {recipe = "drink_spore_mead"},
	"verdant_f4": {recipe = "spore_mask"}, "verdant_f5": {harvest_bonus = 0.20}, "verdant_f6": {recipe = "dish_jungle_pie"},
}

## Set perks: id = "<colour>_<biome>". Their effects are wired up by the systems that use them.
const SET_PERKS := {
	"ochre_m": "Hollow Sense: press G to make ore within 15 m flash (60 s cooldown)",
	"ochre_f": "Vein Follower: ore touching a spot you just dug needs 1 fewer hit",
	"crimson_m": "Hollow Guard: the first hit every 30 s does 30% less damage",
	"crimson_f": "Leader's Fall: killing a pack leader heals you and nearby friends",
	"cobalt_m": "Bonus Bar: every 10th ingot is free",
	"cobalt_f": "Master's Mark: Q4 and Q5 crafts come with a free +1 upgrade",
	"verdant_m": "Long Meals: all buff food lasts 20% longer",
	"verdant_f": "Second Helping: re-eating an active dish refreshes it and makes it 10% stronger",
}

var carved_runes := {}  ## rune id -> true
var shards := {"ochre": 0, "crimson": 0, "cobalt": 0, "verdant": 0}


static func colour_of(rune_id: String) -> String:
	return rune_id.get_slice("_", 0)


static func set_of(rune_id: String) -> String:
	return rune_id.left(rune_id.length() - 1)  # "ochre_m3" -> "ochre_m"


static func runes_in_set(set_id: String) -> Array:
	var out := []
	for id in RUNES:
		if set_of(id) == set_id:
			out.append(id)
	out.sort()
	return out


## A rune item reached the slab. Returns "carved", or "shard" if the world already had it.
func offer(rune_id: String) -> String:
	if not RUNES.has(rune_id):
		return ""
	if carved_runes.has(rune_id):
		shards[colour_of(rune_id)] += 1
		return "shard"
	_carve(rune_id)
	return "carved"


## Spend 3 shards of a colour to carve a missing rune of that colour.
func carve_with_shards(rune_id: String) -> bool:
	var c := colour_of(rune_id)
	if not RUNES.has(rune_id) or carved_runes.has(rune_id) or shards[c] < SHARDS_PER_RUNE:
		return false
	shards[c] -= SHARDS_PER_RUNE
	_carve(rune_id)
	return true


func _carve(rune_id: String) -> void:
	carved_runes[rune_id] = true
	carved.emit(rune_id)
	var s := set_of(rune_id)
	if is_set_done(s):
		set_finished.emit(s)


func is_set_done(set_id: String) -> bool:
	for id in runes_in_set(set_id):
		if not carved_runes.has(id):
			return false
	return true


func finished_sets() -> Array:
	var out := []
	for s in SET_PERKS:
		if is_set_done(s):
			out.append(s)
	return out


## Sum of one bonus over every carved rune (e.g. bonus("max_health_flat") = 10).
func bonus(key: String) -> float:
	var t := 0.0
	for id in carved_runes:
		t += RUNES[id].get(key, 0.0)
	return t


## Recipe ids taught by carved runes.
func taught_recipes() -> Dictionary:
	var out := {}
	for id in carved_runes:
		if RUNES[id].has("recipe"):
			out[RUNES[id].recipe] = true
	return out


## Which rune a lucky drop gives (doc 8.2): own biome's sets, even colour odds, and 75% of the
## time a rune the world is still missing. `rolls` = three 0..1 numbers (pass randf() ×3).
## biome "m" or "f". In the Jungle, a 4th roll under 0.2 gives a missing Mossy rune instead
## (progression doc 8: Fungal backfills Mossy sets until they're done).
func pick_drop(biome: String, rolls: Array) -> String:
	var colour: String = COLOURS.keys()[int(rolls[0] * 4.0) % 4]
	if biome == "f" and rolls.size() > 3 and rolls[3] < 0.2:
		var missing_m: Array = []
		for c in COLOURS:
			missing_m.append_array(runes_in_set(c + "_m").filter(func(r): return not carved_runes.has(r)))
		if not missing_m.is_empty():
			return missing_m[int(rolls[2] * missing_m.size()) % missing_m.size()]
	var pool := runes_in_set(colour + "_" + biome)
	if pool.is_empty():
		return ""
	if rolls[1] < 0.75:
		var missing := pool.filter(func(r): return not carved_runes.has(r))
		if not missing.is_empty():
			pool = missing
	return pool[int(rolls[2] * pool.size()) % pool.size()]


func to_data() -> Dictionary:
	return {c = carved_runes.keys(), s = shards.duplicate()}


func load_data(d: Dictionary) -> void:
	carved_runes.clear()
	for id in d.c:
		carved_runes[id] = true
	shards = d.s.duplicate()
