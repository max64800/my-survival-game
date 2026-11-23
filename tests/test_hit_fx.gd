extends TestCase
## F717 + F788 (owner, Nov 23): hits throw bits matched to what you hit, at the contact point; damage numbers pop,
## shrink and fade, and a crit's number is bigger and a different colour.


func test_what_each_creature_is_made_of() -> void:
	check_eq(Fx.hit_body("rock_snail"), "rock", "snail = rock bits")
	check_eq(Fx.hit_body("great_rock_beetle"), "rock", "great beetle = rock bits")
	check_eq(Fx.hit_body("lost_miner"), "bone", "skeleton = bone-white bits")
	check_eq(Fx.hit_body("ghost_b"), "ghost", "ghost = cold wisps")
	check_eq(Fx.hit_body("cave_spider"), "ichor", "spider = green ichor")
	check_eq(Fx.hit_body("cave_bat"), "flesh", "bat = a splat")
	for k in Monsters.LIST.keys():
		check(Fx.hit_body(k) in ["rock", "bone", "ghost", "ichor", "flesh"], "%s has a hit look" % k)


func test_each_body_kind_throws_bits_at_the_contact_point() -> void:
	for body in ["rock", "bone", "ghost", "ichor", "flesh"]:
		var parent := Node3D.new()
		tree.root.add_child(parent)
		var at := Vector3(1, 2, 3)
		Fx.hit(parent, at, body, Vector3.UP, false, false)
		check(parent.get_child_count() > 0, "%s: bits thrown" % body)
		for c in parent.get_children():
			check_near((c as Node3D).global_position.distance_to(at), 0.0, 0.01, "%s: bits start at the contact point" % body)
		parent.free()


func test_flesh_splat_has_no_dust_but_rock_does() -> void:
	var flesh := Node3D.new()
	tree.root.add_child(flesh)
	Fx.hit(flesh, Vector3.ZERO, "flesh", Vector3.UP, true, false)
	var rock := Node3D.new()
	tree.root.add_child(rock)
	Fx.hit(rock, Vector3.ZERO, "rock", Vector3.UP, true, false)
	check(rock.get_child_count() > flesh.get_child_count(), "rock hits kick up dust, a splat doesn't")
	flesh.free()
	rock.free()


func test_a_crit_adds_a_flash_ring() -> void:
	var plain := Node3D.new()
	tree.root.add_child(plain)
	Fx.hit(plain, Vector3.ZERO, "bone", Vector3.UP, false, false)
	var crit := Node3D.new()
	tree.root.add_child(crit)
	Fx.hit(crit, Vector3.ZERO, "bone", Vector3.UP, false, true)
	check(crit.get_child_count() > plain.get_child_count(), "a crit throws more")
	plain.free()
	crit.free()


func test_number_size_grows_with_damage_heavy_and_crit() -> void:
	var small := MonsterManager.number_scale(5, false, false)
	var big := MonsterManager.number_scale(60, false, false)
	check(big > small, "a bigger hit has a bigger number")
	check(MonsterManager.number_scale(20, true, false) > MonsterManager.number_scale(20, false, false), "heavy is bigger")
	check(MonsterManager.number_scale(20, false, true) > MonsterManager.number_scale(20, true, false), "a crit is the biggest")
	check(MonsterManager.CRIT_COLOR != MonsterManager.EFFECT_COLOR[1], "a crit has its own colour")
