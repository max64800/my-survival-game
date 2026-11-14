class_name Foods
## Every buff dish and brewed drink (progression doc 6.6).
## buff keys: max_health, max_stamina, stamina_regen, damage, damage_taken, dig_power, spore_resist
## Values are fractions: 0.1 = +10%. damage_taken -0.1 = take 10% less damage. minutes = how long it lasts.

const DISHES := {
	# --- Mossy Hollows dishes
	"dish_glowcap_skewer": {name = "Glowcap Skewer", hunger = 20, minutes = 25, buff = {max_stamina = 0.10}},
	"dish_seared_critter": {name = "Seared Critter", hunger = 30, minutes = 25, buff = {max_health = 0.10}},
	"dish_firecap_skewer": {name = "Firecap Skewer", hunger = 25, minutes = 25, buff = {damage = 0.08}},
	"dish_tuber_mash": {name = "Tuber Mash", hunger = 45, minutes = 30, buff = {max_stamina = 0.15}},
	"dish_hollowcap_stew": {name = "Hollowcap Stew", hunger = 50, minutes = 30, buff = {max_health = 0.20}},
	"dish_glow_broth": {name = "Glow Broth", hunger = 35, minutes = 30, buff = {stamina_regen = 0.20}},
	"dish_miners_pie": {name = "Miner's Pie", hunger = 60, minutes = 35, buff = {max_health = 0.12, dig_power = 0.05}},
	"dish_hearth_stew": {name = "Old Hearth Stew", hunger = 60, minutes = 40, buff = {max_health = 0.15, stamina_regen = 0.10}},
	# --- Fungal Jungle dishes
	"dish_beetle_roast": {name = "Beetle Roast", hunger = 30, minutes = 25, buff = {max_health = 0.12}},
	# --- The first three creatures (docs/design/monsters-first-three.md)
	"dish_cooked_snail": {name = "Cooked Snail", hunger = 30, minutes = 25, buff = {max_health = 0.10}},
	"dish_roasted_bug": {name = "Roasted Bug", hunger = 30, minutes = 25, buff = {damage = 0.08}},
	"dish_snail_stew": {name = "Snail & Mushroom Stew", hunger = 55, minutes = 35, buff = {max_health = 0.20}},
	"dish_bug_stew": {name = "Bug & Mushroom Stew", hunger = 55, minutes = 35, buff = {max_stamina = 0.20}},
	"dish_stalk_steak": {name = "Stalk Steak", hunger = 30, minutes = 25, buff = {max_stamina = 0.15}},
	"dish_ember_skewer": {name = "Ember Skewer", hunger = 30, minutes = 25, buff = {damage = 0.10}},
	"dish_truffle_risotto": {name = "Truffle Risotto", hunger = 50, minutes = 35, buff = {max_stamina = 0.20}},
	"dish_chitin_crunch": {name = "Shell Crunch", hunger = 45, minutes = 30, buff = {damage_taken = -0.10}},
	"dish_spore_ward_stew": {name = "Spore Ward Stew", hunger = 40, minutes = 30, buff = {spore_resist = 0.50}},
	"dish_bug_hotpot": {name = "Bug Hotpot", hunger = 55, minutes = 35, buff = {damage = 0.12}},
	"dish_jungle_pie": {name = "Jungle Pie", hunger = 65, minutes = 40, buff = {max_health = 0.25}},
	# --- drinks (use a buff slot too, except plain juice)
	"drink_bellcap_juice": {name = "Bellcap Juice", drink = true, thirst = 60, minutes = 0, buff = {}},
	"drink_glowcap_tea": {name = "Glowcap Tea", drink = true, thirst = 40, minutes = 25, buff = {stamina_regen = 0.10}},
	"drink_firecap_cordial": {name = "Firecap Cordial", drink = true, thirst = 40, minutes = 25, buff = {damage = 0.06, max_stamina = 0.05}},
	"drink_moss_ale": {name = "Moss Ale", drink = true, thirst = 50, minutes = 30, buff = {max_stamina = 0.10, max_health = 0.05}},
	"drink_spore_mead": {name = "Spore Mead", drink = true, thirst = 50, minutes = 35, buff = {max_health = 0.15}},
	"drink_deep_stout": {name = "Deep Stout", drink = true, thirst = 50, minutes = 35, buff = {damage_taken = -0.08}},
}


static func is_buff_food(id: String) -> bool:
	return DISHES.has(id) and DISHES[id].minutes > 0


static func buff_of(id: String) -> Dictionary:
	return DISHES.get(id, {}).get("buff", {})


static func minutes_of(id: String) -> float:
	return DISHES.get(id, {}).get("minutes", 0)
