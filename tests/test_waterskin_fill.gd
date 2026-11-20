extends TestCase
## F401 (owner, Nov 20): an empty waterskin fills with pool water at a pool or a waterfall's pool, nowhere else.

var auth: GameAuthority
var ps: GameAuthority.PlayerState
var water: CaveWater


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	water = CaveWater.new()
	root.add_child(water)
	water.waters.append({pos = Vector3(10, 0, 0), r = 1.0})  # one pool, 1 m across each way
	auth = GameAuthority.new()
	auth.stations_root = Node3D.new()
	auth.drops_root = Node3D.new()
	root.add_child(auth.stations_root)
	root.add_child(auth.drops_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	ps = auth.add_player(1, me)
	await tree.process_frame
	ps.inventory.add("waterskin_empty", 1)
	for i in ps.inventory.slots.size():
		if ps.inventory.slots[i].get("id", "") == "waterskin_empty":
			ps.selected_slot = i


func _held() -> String:
	return String(ps.inventory.get_slot(ps.hand_slot()).get("id", ""))


func test_fills_only_at_water() -> void:
	await _setup()
	check_eq(_held(), "waterskin_empty", "you hold the empty waterskin")
	check_eq(auth.request_use(1, Vector3(0, 0, 0), Vector3.UP, 0.0), "", "aimed at dry rock: nothing happens")
	check_eq(_held(), "waterskin_empty", "still empty")
	check_eq(auth.request_use(1, Vector3(10.5, 0.05, 0.3), Vector3.UP, 0.0), "filled", "aimed at the pool: it fills")
	check_eq(_held(), "waterskin_dirty", "now it holds pool water (boil it to make it clean)")
	check(not water.water_near(Vector3(10, 4.0, 0)), "a pool a floor below doesn't count")
	auth.get_parent().queue_free()


func test_fills_standing_in_the_pool() -> void:
	await _setup()
	ps.node.global_position = Vector3(10.4, 0, 0)
	check_eq(auth.request_use(1, Vector3.INF, Vector3.ZERO, 0.0), "filled", "standing in the pool, aiming at nothing: it fills")
	auth.get_parent().queue_free()
