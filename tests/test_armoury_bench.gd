extends TestCase
## The Armoury Bench (F894 step 2, owner Nov 25): made at the Workbench from planks + leather, shows up once you have
## leather; ALL armour and shields are made on it. The Anvil keeps weapons, tools, its helpers and the bronze mix.

var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var world := World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	ps = auth.add_player(1, player)


func _teardown() -> void:
	auth.get_parent().queue_free()


func test_the_bench_is_made_at_the_workbench_from_planks_and_leather() -> void:
	var r: Dictionary = Recipes.LIST.get("armoury_bench", {})
	check_eq(r.get("station", ""), "workbench", "made at the workbench")
	check_eq(r.get("inputs", {}).keys().size(), 2, "two things")
	check(r.get("inputs", {}).has("plank_root") and r.get("inputs", {}).has("leather"), "planks + leather")
	check_eq(r.get("unlock", []), ["leather"], "shows up once you have leather")
	check_eq(Items.kind("armoury_bench"), "station", "it's a station")
	check_eq(Items.display_name("armoury_bench"), "Armoury Bench", "its name")
	check(ResourceLoader.exists("res://assets/models/stations/armoury_bench.glb"), "its own model")
	check(ResourceLoader.exists("res://assets/icons/armoury_bench.png"), "its own picture")


func test_all_armour_and_shields_are_made_on_it() -> void:
	var count := 0
	for id in Recipes.LIST:
		var out: String = Recipes.LIST[id].output
		if Items.kind(out) in ["wear", "shield"]:
			count += 1
			check_eq(Recipes.LIST[id].station, "armoury_bench", "%s at the Armoury Bench" % id)
	check(count >= 22, "leather, shell, copper, bronze and silver armour + every shield (%d)" % count)
	for id in ["tunic_leather", "plate_shell", "helm_copper", "mail_bronze", "shield_stone", "shield_silver"]:
		check(id in Recipes.for_station("armoury_bench"), id + " is on the bench's list")


func test_the_anvil_keeps_weapons_and_tools() -> void:
	for id in ["sword_copper", "axe_copper", "pickaxe_bronze", "crossbow_silver", "bellows", "grindstone", "bronze_ingot"]:
		check_eq(Recipes.LIST[id].station, "anvil", id + " stays at the anvil")
	for id in Recipes.for_station("anvil"):
		check(not Items.kind(Recipes.LIST[id].output) in ["wear", "shield"], id + ": no armour left on the anvil")


func test_old_saves_get_the_bench_once_they_have_leather() -> void:
	# An old save has no bench but has held leather: the bench recipe shows at once, so armour stays makeable.
	check(Recipes.is_unlocked("armoury_bench", {"leather": true}, {}), "has had leather: the bench shows")
	check(not Recipes.is_unlocked("armoury_bench", {"stone": true}, {}), "no leather yet: hidden")
	# The copper armour pages still exist and still teach their recipe (they were made only for anvil recipes).
	check(Items.exists("page_helm_copper"), "the Copper Helm page still exists")
	check(Items.exists("page_shield_bronze"), "the Bronze Shield page still exists")


func test_make_a_tunic_on_the_bench_not_the_workbench() -> void:
	await _setup()
	ps.seen["leather"] = true
	ps.inventory.add("leather", 30)
	ps.inventory.add("rope", 2)
	auth._ev_place_station(7, "workbench", player.global_position + Vector3(1.5, 0, 0), 0.0)
	check(not auth.request_craft(1, "tunic_leather", 7), "the workbench can't make armour any more")
	ps.inventory.add("plank_root", 8)
	check(auth.request_craft(1, "armoury_bench", 7), "the bench is made at the workbench")
	check_eq(ps.inventory.count_of("armoury_bench"), 1, "a bench in the bag")
	auth._ev_place_station(8, "armoury_bench", player.global_position + Vector3(-1.5, 0, 0), 0.0)
	check(auth.request_craft(1, "tunic_leather", 8), "the tunic is made on the bench")
	check_eq(ps.inventory.count_of("tunic_leather"), 1, "a leather tunic in the bag")
	_teardown()


## Owner, Nov 25: armour upgrades (and repairs) moved to the Armoury Bench too.
func test_armour_is_upgraded_on_the_bench() -> void:
	await _setup()
	ps.inventory.slots[0] = {id = "tunic_leather", count = 1}
	ps.inventory.add("leather", 10)
	ps.inventory.add("crystal_blue", 2)
	auth._ev_place_station(7, "workbench", player.global_position + Vector3(1.5, 0, 0), 0.0)
	auth._ev_place_station(8, "armoury_bench", player.global_position + Vector3(-1.5, 0, 0), 0.0)
	check(auth.request_upgrade(1, 0, 7) != "", "the workbench can't upgrade armour any more")
	check_eq(auth.request_upgrade(1, 0, 8), "", "the bench upgrades the tunic")
	check_eq(Upgrades.level(ps.inventory.get_slot(0)), 1, "Leather Tunic +1")
	check_eq(Upgrades.station_for("sword_copper"), "anvil", "weapons still at the anvil")
	_teardown()
