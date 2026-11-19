extends TestCase
## Owner, Nov 17 ("I want to live in the first tower"): barrels hold things (one row), chests two rows, stone chests three.


func test_rows() -> void:
	check_eq(Storage.SIZES.barrel, 8, "a barrel holds one row")
	check_eq(Storage.SIZES.chest_small, 16, "a chest holds two rows")
	check_eq(Storage.SIZES.chest_stone, 24, "a stone chest holds three rows")


func test_barrel_can_be_made_and_placed() -> void:
	check(Items.exists("barrel") and Items.kind("barrel") == "chest", "a Storage Barrel is an item you place like a chest")
	check(Recipes.LIST.has("barrel") and Recipes.LIST.barrel.station == "workbench", "made at the workbench")
