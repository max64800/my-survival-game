extends TestCase
## Bronze (F697 step 4): 1 Copper Ingot + 1 Tin Ore makes a Bronze Ingot; 13 bronze items sit halfway
## between copper and silver (owner, Nov 25).

const IDS := ["helm", "mail", "greaves", "boots", "shield", "crossbow", "spear", "axe", "sword", "mace",
	"axe_2h", "mace_2h", "pickaxe"]


func test_bronze_ingot_is_copper_plus_tin_at_the_smelter() -> void:
	var r: Dictionary = Recipes.LIST.get("bronze_ingot", {})
	check_eq(r.get("station", ""), "smelter", "made at the smelter")
	check_eq(r.get("inputs", {}), {copper_ingot = 1, tin_ore = 1}, "1 copper ingot + 1 tin ore")
	check_eq(r.get("output", ""), "bronze_ingot", "makes a bronze ingot")
	check(Items.exists("bronze_ingot"), "the ingot is an item")
	check(ResourceLoader.exists("res://assets/icons/bronze_ingot.png"), "ingot icon")


func test_every_bronze_item_has_recipe_model_and_icon() -> void:
	for i in IDS:
		var id: String = i + "_bronze"
		check(Items.exists(id), id + " exists")
		var r: Dictionary = Recipes.LIST.get(id, {})
		check_eq(r.get("station", ""), "anvil", id + " at the anvil")
		check(r.get("inputs", {}).has("bronze_ingot"), id + " needs bronze ingots")
		check_eq(r.get("unlock", ""), "dungeon", id + " is locked until its own page teaches it")
		check(not Recipes.page_recipes("armour_page").has(id) and not Recipes.page_recipes("weapon_page").has(id)
			and not Recipes.page_recipes("tool_page").has(id), id + ": no random ruin page teaches it")
		check(Items.exists("page_" + id), id + " has its own named page (for step 5)")
		check(ResourceLoader.exists("res://assets/icons/%s.png" % id), id + " icon")
		check(ResourceLoader.exists("res://assets/models/items/%s.glb" % id), id + " model")


func test_bronze_is_between_copper_and_silver() -> void:
	for i in ["helm", "mail", "greaves", "boots"]:
		var c: int = Items.info(i + "_copper").get("armor", 0)
		var b: int = Items.info(i + "_bronze").get("armor", 0)
		check(b > c, i + ": bronze armour beats copper")
		var s: Dictionary = Items.info(i + "_silver")
		if not s.is_empty():
			check(b < int(s.get("armor", 0)), i + ": silver still beats bronze")
	for t in ["pickaxe", "axe"]:
		var c: int = Items.info(t + "_copper").get("power", 0)
		var b: int = Items.info(t + "_bronze").get("power", 0)
		var s: int = Items.info(t + "_silver").get("power", 0)
		check(c < b and b < s, "%s power: copper %d < bronze %d < silver %d" % [t, c, b, s])


func test_bronze_boost_hits_harder_but_silver_still_wins() -> void:
	for w in ["sword", "mace", "spear", "axe_2h", "mace_2h"]:
		var cu := Combat.damage_text({id = w + "_copper"})
		var br := Combat.damage_text({id = w + "_bronze"})
		var ag := Combat.damage_text({id = w + "_silver"})
		var n := func(t: String) -> int: return t.split(" ")[1].to_int()
		check(n.call(cu) < n.call(br) and n.call(br) < n.call(ag), "%s: %s < %s < %s" % [w, cu, br, ag])
	check_near(Combat.boost_block(Items.boost("shield_bronze")), 0.05, 0.001, "bronze shield blocks 5% more")
	check(Items.rank("shield_bronze") > Items.rank("shield_copper"), "a bronze shield is picked over copper")
	check(Items.rank("shield_silver") > Items.rank("shield_bronze"), "silver shield still picked first")


func test_bronze_armour_and_upgrades_use_bronze() -> void:
	check_eq(Gems.ARMOR_TIER.get("bronze", 0), 1, "bronze armour counts as metal tier 1")
	check_eq(Upgrades.material_for("sword_bronze"), "bronze_ingot", "upgrading bronze costs bronze ingots")
