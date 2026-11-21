extends TestCase
## The owner's crafting notes from the tower-rebuild play (Nov 21): F561 (a free shield), F555 (craft many at once).

var world: World
var auth: GameAuthority
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	auth.stations_root = Node3D.new()
	root.add_child(auth.drops_root)
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	me.global_position = world.maker.cavern_spawn
	auth.add_player(1, me)
	ps = auth.players[1]
	auth._ev_place_station(7, "workbench", me.global_position + Vector3(1.5, 0, 0), 0.0)


## F561 (owner: "I crafted a wooden shield without having the resources on me").
func test_no_free_shield() -> void:
	await _setup()
	check(not auth.request_craft(1, "shield_stone", 7), "an empty bag makes no shield")
	check_eq(ps.inventory.count_of("shield_stone"), 0, "no shield appeared")
	ps.inventory.add("plank_root", 5)
	ps.inventory.add("rope", 2)
	check(not auth.request_craft(1, "shield_stone", 7), "one plank short: no shield")
	check_eq(ps.inventory.count_of("plank_root"), 5, "and nothing was taken")
	ps.inventory.add("plank_root", 1)
	var said := []
	auth.hud_message.connect(func(t): said.append(t))
	check(auth.request_craft(1, "shield_stone", 7), "6 planks + 2 rope make a shield")
	check_eq(ps.inventory.count_of("plank_root") + ps.inventory.count_of("rope"), 0, "and they were used up")
	check(said.any(func(t): return "Made a Wooden Shield from 6" in t), "it says what it used: %s (F561)" % [said])
	auth.get_parent().queue_free()
