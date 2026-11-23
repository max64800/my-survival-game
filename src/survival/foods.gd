class_name Foods
## Every buff dish and brewed drink (progression doc 6.6).
## buff keys: max_health, max_stamina, stamina_regen, damage, damage_taken, dig_power, spore_resist, and (zone 1 food
## plan, owner Nov 19): regen (extra health a second), guard_bat/beetle/spider/snail (less damage from that creature),
## hunger_slow, thirst_slow, extra_drops. Values are fractions: 0.1 = +10%. damage_taken -0.1 = take 10% less damage.
## minutes = how long it lasts (kitchen level 1 / 2 / 3 = 15 / 25 / 35 min). Draft source: tools/craft_wiki/food_plan.json.

const DISHES := {
	# --- Mossy Hollows dishes
	"dish_glowcap_skewer": {name = "Glowcap Skewer", hunger = 20, minutes = 15, buff = {regen = 0.02, max_stamina = 0.10}},
	"dish_seared_critter": {name = "Seared Bat", hunger = 30, minutes = 15, buff = {regen = 0.02, guard_bat = 0.15}},  # (bat meat now; the id stays for old saves and its picture)
	"dish_firecap_skewer": {name = "Firecap Skewer", hunger = 25, minutes = 25, buff = {regen = 0.04, damage = 0.08, guard_bat = 0.15}},
	"dish_tuber_mash": {name = "Tuber Mash", hunger = 45, minutes = 25, buff = {regen = 0.06, hunger_slow = 0.25, max_stamina = 0.10}},
	"dish_hollowcap_stew": {name = "Hollowcap Stew", hunger = 50, minutes = 25, buff = {regen = 0.06, max_health = 0.15, guard_snail = 0.20}},
	"dish_glow_broth": {name = "Glow Broth", hunger = 35, minutes = 25, buff = {regen = 0.06, stamina_regen = 0.20, thirst_slow = 0.15}},
	"dish_miners_pie": {name = "Miner's Pie", hunger = 60, minutes = 35, buff = {regen = 0.10, dig_power = 0.08, hunger_slow = 0.25, max_health = 0.10}},
	"dish_hearth_stew": {name = "Old Hearth Stew", hunger = 60, minutes = 35, buff = {regen = 0.15, max_health = 0.20, hunger_slow = 0.30, guard_bat = 0.20}},
	# --- Fungal Jungle dishes
	"dish_beetle_roast": {name = "Beetle Roast", hunger = 30, minutes = 25, buff = {max_health = 0.12}},
	# --- The first three creatures (docs/design/monsters-first-three.md)
	"dish_cooked_snail": {name = "Cooked Snail", hunger = 30, minutes = 15, buff = {regen = 0.02, guard_snail = 0.15}},
	"dish_roasted_bug": {name = "Roasted Bug", hunger = 30, minutes = 15, buff = {regen = 0.02, guard_spider = 0.10, guard_beetle = 0.10}},
	"dish_snail_stew": {name = "Snail & Mushroom Stew", hunger = 55, minutes = 25, buff = {regen = 0.06, max_health = 0.20, guard_snail = 0.25}},
	"dish_bug_stew": {name = "Bug & Mushroom Stew", hunger = 55, minutes = 25, buff = {regen = 0.06, max_stamina = 0.20, guard_spider = 0.20, guard_beetle = 0.15}},
	"dish_stalk_steak": {name = "Stalk Steak", hunger = 30, minutes = 25, buff = {max_stamina = 0.15}},
	"dish_ember_skewer": {name = "Ember Skewer", hunger = 30, minutes = 25, buff = {damage = 0.10}},
	"dish_truffle_risotto": {name = "Truffle Risotto", hunger = 50, minutes = 35, buff = {max_stamina = 0.20}},
	"dish_chitin_crunch": {name = "Shell Crunch", hunger = 45, minutes = 30, buff = {damage_taken = -0.10}},
	"dish_spore_ward_stew": {name = "Spore Ward Stew", hunger = 40, minutes = 30, buff = {spore_resist = 0.50}},
	"dish_bug_hotpot": {name = "Bug Hotpot", hunger = 55, minutes = 35, buff = {damage = 0.12}},
	"dish_jungle_pie": {name = "Jungle Pie", hunger = 65, minutes = 40, buff = {max_health = 0.25}},
	# --- drinks (their own slot: 2 foods + 1 drink at a time)
	"drink_bellcap_juice": {name = "Bellcap Juice", drink = true, thirst = 60, minutes = 10, buff = {regen = 0.01, thirst_slow = 0.10}},
	"drink_glowcap_tea": {name = "Glowcap Tea", drink = true, thirst = 40, minutes = 25, buff = {regen = 0.03, stamina_regen = 0.10, thirst_slow = 0.20}},
	"drink_firecap_cordial": {name = "Firecap Cordial", drink = true, thirst = 40, minutes = 25, buff = {regen = 0.05, damage = 0.06, max_stamina = 0.05, thirst_slow = 0.15}},
	"drink_moss_ale": {name = "Moss Ale", drink = true, thirst = 50, minutes = 25, buff = {regen = 0.05, max_stamina = 0.10, max_health = 0.05, thirst_slow = 0.25}},
	"drink_spore_mead": {name = "Spore Mead", drink = true, thirst = 50, minutes = 35, buff = {max_health = 0.15}},
	"drink_deep_stout": {name = "Deep Stout", drink = true, thirst = 50, minutes = 35, buff = {damage_taken = -0.08}},
	# --- the laxative (owner F824, Nov 23): your belly runs empty, so every eaten food and drink is gone and the slots are free
	"drink_gutweed_tea": {name = "Gutweed Tea", drink = true, thirst = 10, minutes = 0, purge = true, color = Color(0.55, 0.6, 0.25), short = "Gt"},
}


static func is_buff_food(id: String) -> bool:
	return DISHES.has(id) and DISHES[id].minutes > 0


static func buff_of(id: String) -> Dictionary:
	return DISHES.get(id, {}).get("buff", {})


static func minutes_of(id: String) -> float:
	return DISHES.get(id, {}).get("minutes", 0)


## Gutweed Tea: empties every food and drink slot (owner F824).
static func is_purge(id: String) -> bool:
	return DISHES.get(id, {}).get("purge", false)


static func is_drink(id: String) -> bool:
	return DISHES.get(id, {}).get("drink", false)


## Healing shown as half hearts (owner, Nov 19; docs/design/food-and-healing.md): 5 hearts = the best food of
## zone 7. Zone 1: +0.04 health a second or more = a whole heart, less = half a heart.
static func heart_halves(regen: float) -> int:
	if regen <= 0.0:
		return 0
	return 2 if regen >= 0.04 else 1


## What a food does, as short bullet lines (healing first). The healing line is "" when it doesn't heal.
static func effect_lines(id: String) -> Array[String]:
	var out: Array[String] = []
	var b := buff_of(id)
	var words := {max_health = "+%d%% max health", max_stamina = "+%d%% max stamina", stamina_regen = "stamina refills %d%% faster",
		damage = "+%d%% damage", damage_taken = "take %d%% less damage", dig_power = "+%d%% digging",
		spore_resist = "%d%% less spore sickness", hunger_slow = "lose food %d%% slower", thirst_slow = "lose water %d%% slower",
		guard_bat = "take %d%% less from bats", guard_beetle = "take %d%% less from beetles",
		guard_spider = "take %d%% less from spiders", guard_snail = "take %d%% less from snails",
		extra_drops = "%d%% chance of an extra creature drop"}
	for k in b:
		if words.has(k):
			out.append(words[k] % roundi(absf(b[k]) * 100.0))
	if is_purge(id):
		out.append("empties every food and drink slot (a quick trip behind a rock)")
	if minutes_of(id) > 0:
		out.append("lasts %d min" % minutes_of(id))
	return out
