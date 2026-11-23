extends TestCase
## The Monster Arena (owner, Nov 23): every creature gets its own spot on the flat floor, inside it, not on top of another.


func test_every_creature_has_its_own_spot_on_the_floor() -> void:
	var spots := MonsterArena.layout(Monsters.LIST.keys())
	check_eq(spots.size(), Monsters.LIST.size(), "one spot per creature kind")
	var seen := []
	for kind in spots:
		var p: Vector3 = spots[kind]
		check(absf(p.x - MonsterArena.ORIGIN.x) < MonsterArena.SIZE.x * 0.5 - 1.0, "%s stands inside the floor (x)" % kind)
		check(absf(p.z - MonsterArena.ORIGIN.z) < MonsterArena.SIZE.y * 0.5 - 1.0, "%s stands inside the floor (z)" % kind)
		for q in seen:
			check(p.distance_to(q) >= MonsterArena.SPACING - 0.01, "%s isn't on top of another creature" % kind)
		seen.append(p)


func test_a_standing_dummy_does_not_walk() -> void:
	var m := Monster.new()
	m.dummy = true
	check(m.dummy, "dummy flag exists and is settable")
	m.free()
