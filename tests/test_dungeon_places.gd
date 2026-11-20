extends TestCase
## Where the 12 Zone 1 dungeons sit (owner, Nov 20, F237): in their rings, 40 m apart, inside rock, and clear of every
## built thing and place (the placement rule, Nov 17).

const SEEDS := [42, 7, 1234]


func test_all_twelve_in_their_rings() -> void:
	for sd in SEEDS:
		var c := CaveMaker.new(sd)
		var got := DungeonPlaces.pick(c)
		check_eq(got.size(), 12, "seed %d: a spot for each dungeon" % sd)
		for i in got.size():
			var p: Dictionary = got[i]
			var d: Dictionary = DungeonList.LIST[i]
			check(not p.is_empty(), "seed %d: %s found a spot" % [sd, d.name])
			if p.is_empty():
				continue
			check_eq(p.id, d.id, "in the list's order")
			var ring: Array = DungeonList.SIZES[d.size].ring
			var mid := DungeonPlaces.middle(p)
			var dist := Vector2(mid.x - c.spawn_point.x, mid.z - c.spawn_point.z).length()
			check(dist >= ring[0] and dist <= ring[1], "seed %d: %s is %.0f m from the start (ring %s)" % [sd, d.name, dist, str(ring)])
			check(mid.x < CaveMaker.SLAB_X, "seed %d: %s is in Mossy Hollows" % [sd, d.name])
			check(c.sdf_at(mid + Vector3.UP * 2.0) < 0.0, "seed %d: %s sits inside rock" % [sd, d.name])
			check(c.sdf_at(p.pos + Vector3.UP * 1.0) > 0.0, "seed %d: %s's door opens onto open air" % [sd, d.name])
			for j in i:
				if got[j].is_empty():
					continue
				var o := DungeonPlaces.middle(got[j])
				var gap := Vector2(mid.x, mid.z).distance_to(Vector2(o.x, o.z))
				check(gap >= 40.0,
					"seed %d: %s and %s are 40 m apart (%.0f)" % [sd, d.name, got[j].id, gap])


## The placement rule (owner, Nov 17), like test_columns_keep_out_of_the_tower: no dungeon on the watchtower's or
## the Fallen Outpost's ground, on a place, or in a stone column.
func test_dungeons_keep_out_of_ruins_and_places() -> void:
	for sd in SEEDS:
		var c := CaveMaker.new(sd)
		check(not c.reserved.is_empty(), "seed %d: the ruins kept their ground" % sd)
		for p in DungeonPlaces.pick(c):
			if p.is_empty():
				continue
			var mid := DungeonPlaces.middle(p)
			var flat := Vector2(mid.x, mid.z)
			for z in c.reserved:
				check(flat.distance_to(Vector2(z.pos.x, z.pos.z)) > p.r + z.r, "seed %d: %s keeps off a ruin's ground" % [sd, p.id])
			for q in c.pois:
				check(flat.distance_to(Vector2(q.pos.x, q.pos.z)) > p.r, "seed %d: %s keeps off the %s" % [sd, p.id, q.type])
			check(not c._in_column(mid, p.r), "seed %d: %s keeps out of the stone columns" % [sd, p.id])


func test_same_world_same_places_and_mossgate_from_the_pc() -> void:
	var c := CaveMaker.new(42)
	var a := DungeonPlaces.pick(c)
	check_eq(str(a), str(DungeonPlaces.pick(c)), "the same world always gives the same spots")
	var mg := {pos = a[1].pos}  # the PC's Mossgate spot (here: where Lampwick Drift was)
	var b := DungeonPlaces.pick(c, mg)
	check_eq(b[0].pos, mg.pos, "Mossgate Hold stays where the PC put it")
	for i in range(1, b.size()):
		if not b[i].is_empty():
			check(Vector2(mg.pos.x, mg.pos.z).distance_to(Vector2(DungeonPlaces.middle(b[i]).x, DungeonPlaces.middle(b[i]).z)) >= 40.0,
				"%s keeps 40 m from Mossgate Hold" % b[i].id)


func test_reserved_ground_covers_the_dungeons() -> void:
	var c := CaveMaker.new(42)
	var got := DungeonPlaces.pick(c)
	DungeonPlaces.reserve_all(c, got)
	for p in got:
		if not p.is_empty():
			check(c.is_reserved(DungeonPlaces.middle(p)), "%s: pebbles and plants keep off it" % p.id)
