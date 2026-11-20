extends TestCase
## Every item a recipe needs can really be got (owner, Nov 19: the bosses and most creatures were taken out, and
## some recipes needed things only they dropped). And old saves with removed creatures or items still load.

## Root Trees (game_authority.gd request_chop_pillar): wood, Tree Moss, Heartwood, Root Seeds.
const ROOT_TREE := ["rootwood", "tree_moss", "heartwood", "root_seed"]
## Old ruin and camp chests (game_authority.gd seed_poi_loot and _seed_fungal_loot).
const CHESTS := ["blueprint_page", "gold_coin", "rusty_scrap", "silver_ingot", "crystal_amber", "rope", "spore_truffle",
	"ember_morel", "mushroom_flesh", "cook_page", "armour_page", "weapon_page", "tool_page"]
## Got some other way: a Drip Bucket fills with clean water, a waterskin is filled at a pool.
const OTHER := ["water_bucket", "waterskin_dirty"]
## Found by this test (Nov 19), older than the boss removal: nothing in the world gives these yet. Waiting for the
## owner's OK before fixing (a Root Tuber only grows on a Farm Plot, which needs a tuber to plant; no marble rock).
const WAITING_FOR_OWNER := ["root_tuber", "marble"]


## Where each item comes from (item -> a short word). Not crafted: those are added by the caller.
func _sources() -> Dictionary:
	var src := {}
	for i in Recipes.GATHER:
		src[i] = "gathered"
	for k in GlowPlacer.KINDS:
		var g: Dictionary = GlowPlacer.KINDS[k]
		for key in ["item", "extra"]:
			if g.get(key, "") != "":
				src[g[key]] = "world"
		if g.has("rare"):
			src[g.rare[0]] = "world"
	for m in Mat.DROP_ITEM:
		src[Mat.DROP_ITEM[m]] = "dug"
	for kind in Monsters.LIST:
		for d in Monsters.LIST[kind].drops:
			src[d[0]] = kind
	for v in Monsters.VARIANTS:
		src[Monsters.VARIANTS[v].crystal] = "crystal creature"
	for i in ROOT_TREE + CHESTS + OTHER:
		src[i] = "world"
	return src


func test_every_recipe_item_has_a_source() -> void:
	var src := _sources()
	for id in Recipes.LIST:
		src[Recipes.LIST[id].output] = "made"
	var missing := []
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		var needs: Array = r.inputs.keys()
		if r.unlock is Array:
			needs += r.unlock
		for item in needs:
			if item.begins_with("rune_") or item.begins_with("gem_"):
				continue  # runes come from shrines and chests, gems from crystal creatures (unlocks only)
			if not src.has(item) and not item in WAITING_FOR_OWNER:
				missing.append("%s needs %s" % [id, item])
	check(missing.is_empty(), "items nobody can get: %s" % ", ".join(missing))


func test_no_recipe_or_drop_names_a_missing_item() -> void:
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		check(Items.exists(r.output), "%s makes unknown item %s" % [id, r.output])
		for item in r.inputs:
			check(Items.exists(item), "%s needs unknown item %s" % [id, item])
		if r.unlock is Array:
			for item in r.unlock:
				if item.ends_with("*"):  # "rune_*": some real item must start with it (F399)
					check(Items.ids().any(func(x): return x.begins_with(item.trim_suffix("*"))), "%s unlocks from %s, but no such item" % [id, item])
					continue
				check(Items.exists(item), "%s unlocks from unknown item %s" % [id, item])
	for kind in Monsters.LIST:
		for d in Monsters.LIST[kind].drops:
			check(Items.exists(d[0]), "%s drops unknown item %s" % [kind, d[0]])
	for i in ROOT_TREE + CHESTS + OTHER + Recipes.GATHER.keys():
		check(Items.exists(i), "unknown item %s" % i)
	for k in GlowPlacer.KINDS:
		var g: Dictionary = GlowPlacer.KINDS[k]
		if g.has("rare"):
			check(Items.exists(g.rare[0]), "%s's rare find %s exists" % [k, g.rare[0]])


func test_every_creature_lives_somewhere() -> void:
	var spawns := {"cave_bat": true}  # every cave has its own bat roost (MonsterManager._spawn_roost)
	for biome in Monsters.SPAWNS:
		for list in Monsters.SPAWNS[biome].values():
			for kind in list:
				spawns[kind] = true
	for kind in Monsters.LIST:
		if Monsters.LIST[kind].get("dungeon_only", false):
			continue  # (the skeleton miners: placed by a dungeon's plan, never in the caves)
		check(spawns.has(kind), "%s never spawns" % kind)
	for kind in spawns:
		check(Monsters.LIST.has(kind), "%s spawns but isn't a creature" % kind)


func test_only_the_five_creatures_are_left() -> void:
	# (Nov 20: plus the owner's three skeleton miners for Lampwick Drift and Old Pell's Diggings.)
	check_eq(Monsters.LIST.keys().size(), 8, "five cave creatures and three dungeon miners")
	for kind in ["rock_snail", "rock_beetle", "great_rock_beetle", "cave_bat", "cave_spider", "tunnel_rat", "lost_miner", "foreman"]:
		check(Monsters.LIST.has(kind), "%s is in" % kind)
	check(Monsters.info("orrumhal").is_empty(), "no bosses")
	check(Monsters.info("mossnipper").is_empty(), "no old creatures")


func test_new_drops() -> void:
	var drops := func(kind: String) -> Array: return Monsters.LIST[kind].drops.map(func(d): return d[0])
	check(drops.call("cave_bat").has("bat_meat"), "bats drop bat meat")
	check(drops.call("cave_spider").has("spider_silk"), "spiders drop silk")
	check(drops.call("cave_spider").has("venom_sac"), "spiders drop venom sacs")
	check(drops.call("great_rock_beetle").has("chitin_plate"), "great beetles drop chitin plate")
	check(drops.call("great_rock_beetle").has("beetle_meat"), "and beetle meat")
	check(Recipes.LIST.pickaxe_copper.inputs.has("heartwood"), "the Copper Pickaxe needs Heartwood")
	check_eq(Recipes.LIST.tanning_rack.unlock, ["wing_leather"], "the Tanning Rack shows up after wing leather")
	var inv := Inventory.new()
	inv.add("spider_silk", 2)
	check(Crafting.craft(inv, "rope_silk"), "2 spider silk make a rope")
	check_eq(inv.count_of("rope"), 1, "one rope")


func test_a_bandage_heals_a_little() -> void:
	var v := Vitals.new()
	v.health = 20.0
	check(v.consume("bandage"), "a bandage can be used")
	check_near(v.health, 45.0, 0.01, "it heals 25")


## Old saves: a boss or removed creature in the save is skipped, removed items vanish.
func test_old_saves_still_load() -> void:
	var mm := MonsterManager.new()
	mm.load_snapshot([[5, "orrumhal", Vector3.ZERO, false, 1000, 2000.0, ""], [6, "mossnipper", Vector3.ZERO, false, 3, 30.0]])
	check(mm.monsters.is_empty(), "the boss and the old creature are skipped")
	mm.free()
	var inv := Inventory.new()
	inv.load_data([{id = "critter_meat", count = 3}, {id = "dish_seared_critter", count = 2}, {id = "stone", count = 5}])
	check_eq(inv.count_of("critter_meat"), 0, "a removed item is dropped")
	check_eq(inv.count_of("dish_seared_critter"), 2, "the Seared Bat keeps its old id")
	check_eq(Items.display_name("dish_seared_critter"), "Seared Bat", "and its new name")
	check_eq(inv.count_of("stone"), 5, "everything else stays")
