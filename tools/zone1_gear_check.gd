extends SceneTree
## What can a player make in Zone 1 (Mossy Hollows, incl. the Copper Deeps), and what's out of reach?
##   godot --headless --path . --script res://tools/zone1_gear_check.gd
## Starts from everything Zone 1 gives (rock, plants, crystals, Root Trees, creatures, ruin chests),
## then keeps crafting until nothing new can be made. Prints the best gear per slot and every
## recipe that stays out of reach, with the item that blocks it.

## Raw things the Zone 1 world gives (mat.gd DROP_ITEM, glow_placer.gd _pick_kind, GATHER), and the Root Trees
## (game_authority.gd request_chop_pillar: wood, Tree Moss, Heartwood, Root Seeds).
const WORLD := ["stone", "rootwood", "fiber", "dirt", "clay", "moss", "copper_ore",
	"crystal_blue", "crystal_green", "glowcap", "hollowcap", "bellcap", "firecap", "tree_moss", "heartwood", "root_seed"]
## Who lives in Zone 1 (Monsters.SPAWNS mossy + every cave's bat roost).
const CREATURES := ["rock_snail", "rock_beetle", "cave_spider", "cave_bat"]
## Zone 1 ruin and camp chests (game_authority.gd seed_poi_loot).
const CHESTS := ["blueprint_page", "gold_coin", "rusty_scrap", "dish_hollowcap_stew", "dish_tuber_mash", "drink_glowcap_tea"]


func _init() -> void:
	var have := {}  # item -> where it came from
	for i in WORLD:
		have[i] = "world"
	for c in CREATURES:
		for d in Monsters.info(c).get("drops", []):
			if not have.has(d[0]):
				have[d[0]] = c
	for i in CHESTS:
		have[i] = "chest"
	var rune_recipes := {}
	for r in RuneSlab.RUNES:
		if r.ends_with("_m1") or r.contains("_m") and RuneSlab.RUNES[r].has("recipe"):
			if RuneSlab.RUNES[r].has("recipe"):
				rune_recipes[RuneSlab.RUNES[r].recipe] = true

	print("== Zone 1 raw items ==")
	for i in have:
		print("  %s  (%s)" % [i, have[i]])

	var made := {}
	var changed := true
	while changed:
		changed = false
		for id in Recipes.LIST:
			if made.has(id):
				continue
			var r: Dictionary = Recipes.LIST[id]
			if not _shown(id, r, have, rune_recipes):
				continue
			var st := Recipes.station_type(r.station) if r.station != Recipes.HAND else Recipes.HAND
			if st != Recipes.HAND and not have.has(st) and not have.has(r.station):
				continue
			var ok := true
			for i in r.inputs:
				if not have.has(i):
					ok = false
			if ok:
				made[id] = true
				if not have.has(r.output):
					have[r.output] = "made"
				changed = true

	print("\n== Best gear you can make in Zone 1 ==")
	var best := {}
	for item in have:
		var info: Dictionary = Items.info(item)
		var k: String = info.get("kind", "")
		var slot := ""
		var score := 0.0
		if k == "wear" or k == "shield":
			slot = str(info.get("slot", k))
			score = float(info.get("armor", 0)) + float(info.get("tier", 0)) * 100
		elif k in ["pickaxe", "axe", "weapon", "crossbow"]:
			slot = k + (" " + str(info.get("type", "")) if k == "weapon" else "")
			score = float(info.get("power", info.get("damage", 0))) + float(info.get("tier", 0)) * 100
		else:
			continue
		if not best.has(slot) or score > best[slot][1]:
			best[slot] = [item, score]
	for s in best:
		print("  %-14s %s" % [s, Items.display_name(best[s][0])])

	print("\n== Recipes only from ruin pages (each page teaches one you don't know yet) ==")
	for kind in Recipes.PAGE_OF_KIND:
		var list := Recipes.page_recipes(Recipes.PAGE_OF_KIND[kind])
		print("  %s (%d): %s" % [kind, list.size(), ", ".join(list)])

	print("\n== Recipes out of reach in Zone 1 ==")
	for id in Recipes.LIST:
		if made.has(id):
			continue
		var r: Dictionary = Recipes.LIST[id]
		var why := []
		if not _shown(id, r, have, rune_recipes):
			why.append("never shows (unlock: %s)" % str(r.unlock))
		if r.station != Recipes.HAND and not have.has(Recipes.station_type(r.station)) and not have.has(r.station):
			why.append("no " + r.station)
		for i in r.inputs:
			if not have.has(i):
				why.append("no " + i)
		print("  %s: %s" % [id, ", ".join(why)])
	quit()


func _shown(id: String, r: Dictionary, have: Dictionary, rune_recipes: Dictionary) -> bool:
	if r.unlock is String:
		return r.unlock == "ruin" or rune_recipes.has(id)  # every ruin chest holds 2 recipe pages
	if r.unlock.is_empty():
		return true
	for u in r.unlock:
		if have.has(u):
			return true
	return false
