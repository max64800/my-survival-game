extends TestCase
## The Cozy rest buff: comfort from a fire/bed, different furniture nearby, and a roof.


func _station(kind: String, pos: Vector3) -> Node3D:
	var st := Station.new()
	st.kind = kind
	st.position = pos
	return st


func test_comfort_counts_different_things() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var fire := _station("campfire", Vector3(1, 0, 0))
	root.add_child(fire)
	var stations := {1: fire}
	var pieces := {}
	check_eq(Comfort.score(Vector3(10, 0, 0), stations, pieces), 0, "far from the fire: not resting, no comfort")
	check_eq(Comfort.score(Vector3.ZERO, stations, pieces), 1, "just a fire: 1")
	pieces[1] = {piece = "table", pos = Vector3(2, 0, 2)}
	pieces[2] = {piece = "table", pos = Vector3(-2, 0, 2)}
	pieces[3] = {piece = "chair", pos = Vector3(2, 0, 3)}
	pieces[4] = {piece = "rug", pos = Vector3(0, 0, 0)}
	check_eq(Comfort.score(Vector3.ZERO, stations, pieces), 4, "table + chair + rug (two tables count once)")
	pieces[5] = {piece = "roof_26", pos = Vector3(0, 2.5, 0)}
	check_eq(Comfort.score(Vector3.ZERO, stations, pieces), 5, "+1 for a roof overhead")
	pieces[6] = {piece = "banner", pos = Vector3(30, 0, 0)}
	check_eq(Comfort.score(Vector3.ZERO, stations, pieces), 5, "things 30 m away don't count")
	root.free()


func test_cozy_buff() -> void:
	var v := Vitals.new()
	var plain := v.stamina_regen_mult()
	v.set_cozy(5)
	check_near(v.cozy_time, Comfort.duration(5), 0.01, "lasts 3 min + 1 min per point")
	check_near(v.stamina_regen_mult(), plain + 0.25, 0.001, "+5% stamina regen per point")
	check(v.health_regen_mult() > 1.0, "heals faster")
	v.set_cozy(1)
	check_near(v.cozy_time, Comfort.duration(5), 0.01, "a less cozy rest doesn't shorten it")
	v.tick(Comfort.duration(5) + 1.0)
	check_eq(v.cozy_time, 0.0, "wears off")
	v.set_cozy(3)
	v.respawn()
	check_eq(v.cozy_time, 0.0, "gone after dying")
