extends TestCase
## Cave layout 2 (F211, epic caves step 1): the old caves stay exactly the same, and the new ones are big, varied and
## walkable. New worlds get layout 2 (owner's OK, Nov 17); old saves keep layout 1.


## Old saves keep their caves: the same rooms, tunnels, places and rock, to 4 decimals (fingerprints from Nov 16).
func test_old_caves_unchanged() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(1)
	check_eq(_fingerprint(CaveMaker.new(42)),
		"rooms=53 segs=1426 pois=65 r0=(-106.8563, -24.81935, -56.50769) sum=-11055.2929", "seed 42, layout 1")
	check_eq(_fingerprint(CaveMaker.new(7)),
		"rooms=54 segs=1342 pois=68 r0=(-19.17805, -23.8586, 112.1128) sum=-10639.7901", "seed 7, layout 1")
	CaveMaker.use_layout(2)  # worlds made on Nov 17 before layout 3 keep theirs too
	check_eq(_fingerprint(CaveMaker.new(42)),
		"rooms=192 segs=5292 pois=162 r0=(-83.95856, -24.81935, -44.3989) sum=-9322.0347", "seed 42, layout 2")
	check_eq(_fingerprint(CaveMaker.new(7)),
		"rooms=192 segs=5191 pois=167 r0=(-15.06847, -23.8586, 88.08862) sum=-8536.2000", "seed 7, layout 2")
	CaveMaker.use_layout(3)  # worlds made before the huge first cavern (layout 4) keep theirs too
	check_eq(_fingerprint(CaveMaker.new(42)),
		"rooms=198 segs=5256 pois=162 r0=(-83.95856, -24.81935, -44.3989) sum=-9967.2001", "seed 42, layout 3")
	check_eq(_fingerprint(CaveMaker.new(7)),
		"rooms=197 segs=5492 pois=163 r0=(-15.06847, -23.8586, 88.08862) sum=-8989.8260", "seed 7, layout 3")
	CaveMaker.use_layout(4)  # worlds made before the stone columns (layout 5) keep theirs too
	check_eq(_fingerprint(CaveMaker.new(42)), "rooms=198 segs=5332 pois=162 r0=(-83.95856, -20.99115, -44.3989) sum=-9894.0944", "seed 42, layout 4")
	check_eq(_fingerprint(CaveMaker.new(7)), "rooms=197 segs=5554 pois=163 r0=(-15.06847, -20.1193, 88.08862) sum=-8555.4642", "seed 7, layout 4")
	CaveMaker.use_layout(5)  # worlds made before the columns kept out of the tower (layout 6) keep theirs too
	check_eq(_fingerprint(CaveMaker.new(42)), "rooms=198 segs=5332 pois=162 r0=(-83.95856, -20.99115, -44.3989) sum=-9894.0944", "seed 42, layout 5")
	check_eq(_fingerprint(CaveMaker.new(7)), "rooms=197 segs=5554 pois=163 r0=(-15.06847, -20.1193, 88.08862) sum=-8655.5548", "seed 7, layout 5")
	CaveMaker.use_layout(6)  # worlds made with the huge cavern and its columns keep theirs too
	check_eq(_fingerprint(CaveMaker.new(42)), "rooms=198 segs=5332 pois=162 r0=(-83.95856, -20.99115, -44.3989) sum=-9894.0944", "seed 42, layout 6")
	check_eq(_fingerprint(CaveMaker.new(7)), "rooms=197 segs=5554 pois=163 r0=(-15.06847, -20.1193, 88.08862) sum=-8559.8592", "seed 7, layout 6")
	CaveMaker.use_layout(9)  # worlds made with the first few bridges keep theirs
	check_eq(_fingerprint(CaveMaker.new(42)), "rooms=198 segs=5256 pois=161 r0=(-83.95856, -24.81935, -44.3989) sum=-9967.2001", "seed 42, layout 9")
	CaveMaker.use_layout(8)  # worlds made before the rock bridges (layout 9) keep their caves
	check_eq(_fingerprint(CaveMaker.new(42)), "rooms=198 segs=5256 pois=161 r0=(-83.95856, -24.81935, -44.3989) sum=-9967.2001", "seed 42, layout 8")
	CaveMaker.use_layout(8)  # (layout 8 only adds columns: the rooms, paths and places stay layout 3's)
	var l8 := _fingerprint(CaveMaker.new(42))
	check(l8.begins_with("rooms=198 segs=5256 pois="), "layout 8 keeps layout 3's rooms and paths (%s)" % l8)
	CaveMaker.use_layout(7)  # layout 7 is layout 3's caves again (owner: the huge first cavern was too big)
	check_eq(_fingerprint(CaveMaker.new(42)),
		"rooms=198 segs=5256 pois=162 r0=(-83.95856, -24.81935, -44.3989) sum=-9967.2001", "seed 42, layout 7 = layout 3")
	check(CaveMaker.new(7).first_cavern().is_empty(), "layout 7 has no huge first cavern")
	CaveMaker.use_layout(was)


## Rule (owner, Nov 17): what the world grows never stands inside something built. The watchtower's spot is clear
## of the stone columns, on several seeds.
func test_columns_keep_out_of_the_tower() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(6)  # (the last layout with columns)
	var plan := RuinTower.load_plan()
	var rad := float(plan.get("radius", 4.2))
	for sd in [42, 7, 1234, 99]:
		var c := CaveMaker.new(sd)
		var spot := RuinTower.find_spot(c, rad, float(plan.get("height", 9.0)))
		if spot.is_empty():
			continue
		check(not c._in_column(spot.pos, rad + 1.0), "seed %d: no column inside the tower at %s" % [sd, str(spot.pos)])
	CaveMaker.use_layout(was)


## Layout 8 (owner, Nov 17): 1 or 2 smaller stone columns in plain big caverns: solid, never on the watchtower's
## ground, in the Fallen Outpost's cavern, or over a place.
func test_columns_in_big_caverns() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(8)
	var plan := RuinTower.load_plan()
	var rad := float(plan.get("radius", 4.2))
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		check(c._cols.size() >= 4, "seed %d: columns in the big caverns (got %d)" % [sd, c._cols.size()])
		for i in c._cols.size():
			var o: Vector4 = c._cols[i]
			var sp: Vector2 = c._col_span[i]
			var y := sp.x + 3.0
			var mid := Vector3(o.x + sin(y * 0.13 + o.w) * o.z * 0.2, y, o.y + cos(y * 0.1 + o.w * 1.7) * o.z * 0.2)
			check(c.sdf_at(mid) < 0.0, "seed %d: column %d is solid rock" % [sd, i])
		var spot := RuinTower.find_spot(c, rad, float(plan.get("height", 9.0)))
		if not spot.is_empty():
			check(not c._in_column(spot.pos, rad + 1.0), "seed %d: no column in the tower" % sd)
		if ResourceLoader.exists("res://src/world/ruin_outpost.gd"):
			var ro: Script = load("res://src/world/ruin_outpost.gd")
			var orr: int = ro.call("pick_room", c)
			if orr >= 0:
				var oc: Vector3 = c.rooms[orr].center
				var big := maxf(c.rooms[orr].radii.x, c.rooms[orr].radii.z)
				for o in c._cols:
					check(Vector2(o.x - oc.x, o.y - oc.z).length() > big, "seed %d: no column in the outpost's cavern" % sd)
		for q in c.pois:
			check(not c._in_column(q.pos, 0.0), "seed %d: %s isn't inside a column" % [sd, q.type])
		check(not c.star_room().is_empty() and c.star_room().snakes == 2, "seed %d: the first cavern has the snake group" % sd)
	CaveMaker.use_layout(was)


## Layout 9 (owner, Nov 17, F189): natural rock bridges across some tall caverns: solid, with room to walk on top.
func test_rock_bridges() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	var total := 0
	for sd in [42, 7, 1234]:
		var c := CaveMaker.new(sd)
		total += c._bridges.size()
		for br in c._bridges:
			var mid: Vector3 = (br.a as Vector3).lerp(br.b, 0.5)
			check(c.sdf_at(mid - Vector3.UP * 0.8) < 0.0, "seed %d: the bridge is rock in the middle" % sd)
			check(c.sdf_at(mid + Vector3.UP * 1.6) > 0.0, "seed %d: room for a dwarf on top" % sd)
	check(total >= 15, "lots of tall caverns have a bridge (%d in 3 worlds)" % total)
	CaveMaker.use_layout(was)


## Layout 5 (owner F263): huge natural stone columns stand in the first cavern, solid rock, clear of where you start.
func test_first_cavern_columns() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(6)  # (the last layout with columns)
	for sd in [42, 7]:
		var c := CaveMaker.new(sd)
		check(c._cols.size() >= 4 and c._cols.size() <= 7, "seed %d: 4 to 7 columns (5 to 7 wanted, fewer if the paths leave no room) (got %d)" % [sd, c._cols.size()])
		for o in c._cols:
			var y := (c._col_floor + c._col_top) * 0.5
			var mid := Vector3(o.x + sin(y * 0.13 + o.w) * o.z * 0.2, y, o.y + cos(y * 0.1 + o.w * 1.7) * o.z * 0.2)  # (it leans)
			check(c.sdf_at(mid) < -1.0, "seed %d: a column at (%.0f, %.0f) is solid rock" % [sd, o.x, o.y])
			check(o.z * 2.0 >= 7.0, "seed %d: columns are wide" % sd)
		check(c.sdf_at(c.cavern_spawn + Vector3.UP) > 0.0, "seed %d: where you come in is open" % sd)
		check(c.sdf_at(c.spawn_point + Vector3.UP) > 0.0, "seed %d: the wake-up spot is open" % sd)
		for q in c.pois:
			check(not c._in_column(q.pos, 0.0), "seed %d: %s isn't inside a column" % [sd, q.type])
	CaveMaker.use_layout(was)


## Layout 4 (owner F260): the first cavern is huge (~120 m across, a dome) and no other room sits inside it.
func test_huge_first_cavern() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(4)
	for sd in [42, 7]:
		var c := CaveMaker.new(sd)
		var f := c.first_cavern()
		check(not f.is_empty(), "seed %d: there is a first cavern" % sd)
		check_eq((f.radii as Vector3).x, CaveMaker.FIRST_CAVERN_R, "seed %d: it's huge" % sd)
		check(c.sdf_at(f.center) > 0.0, "seed %d: its middle is open air" % sd)
		for i in range(1, c.rooms.size()):
			var r: Dictionary = c.rooms[i]
			if r.biome != "mossy" or r.get("lobe_of", -1) == 0:
				continue
			var d := Vector2(r.center.x - f.center.x, r.center.z - f.center.z).length()
			check(d > CaveMaker.FIRST_CAVERN_R * 0.8 or r.kind in ["shrine", "geode", "lair"], "seed %d: room %d isn't swallowed by it (%.0f m)" % [sd, i, d])
	CaveMaker.use_layout(was)


## Layout 3 (F230, F231): wide-and-low, tall-and-narrow and tall-and-wide caverns, caverns joined to a second part,
## and tall caverns with a tunnel coming in high up and a ledge path down the wall that a dwarf fits along.
func test_cavern_kinds_and_cliffs() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(3)
	var c := CaveMaker.new(42)
	CaveMaker.use_layout(was)
	var props := {}
	var lobes := 0
	var cliffs := 0
	for r in c.rooms:
		props[int(r.get("prop", 0))] = props.get(int(r.get("prop", 0)), 0) + 1
		lobes += 1 if r.has("lobe_of") else 0
		cliffs += 1 if r.has("cliff") else 0
	print("        (kinds %s, joined %d, cliffs %d)" % [props, lobes, cliffs])
	for prop in range(1, CaveMaker.PROP_NAMES.size()):
		check(props.get(prop, 0) >= 2, "some %s caverns (%d)" % [CaveMaker.PROP_NAMES[prop], props.get(prop, 0)])
	check(lobes >= 3, "some caverns are joined to a second part (%d)" % lobes)
	check(cliffs >= 3, "some tall caverns have a cliff exit (%d)" % cliffs)
	var tot := 0
	var bad := 0
	for s in c.segments:
		if not s.get("ledge", false):
			continue
		var d: Vector3 = s.b - s.a
		check(absf(d.y) / Vector2(d.x, d.z).length() <= 0.42, "ledge at %s no steeper than a tunnel" % s.a)
		var side := Vector3(-d.z, 0, d.x).normalized()
		for f in [0.25, 0.5, 0.75]:
			tot += 1
			bad += 0 if _fits(c, (s.a as Vector3).lerp(s.b, f), side) else 1
	check(tot > 0 and bad <= tot / 20, "a dwarf fits along the ledge paths (%d of %d spots too tight)" % [bad, tot])


## The new caves: many more rooms, every room shape and every passage kind, plenty of each.
func test_new_caves_have_every_kind() -> void:
	var c := _v2(42)
	var big := 0
	var shapes := {}
	for r in c.rooms:
		big += 1 if r.big else 0
		shapes[int(r.get("shape", 0))] = true
	var kinds := {}
	for s in c.segments:
		var k := int(s.get("k", 0))
		kinds[k] = kinds.get(k, 0) + 1
	print("        (%d rooms, %d big, %d tunnel pieces %s)" % [c.rooms.size(), big, c.segments.size(), kinds])
	check(c.rooms.size() >= 100, "at least 100 rooms (got %d)" % c.rooms.size())
	check(big >= 10, "at least 10 big caverns (got %d)" % big)
	check_eq(shapes.size(), CaveMaker.SHAPE_NAMES.size(), "every room shape")
	for k in CaveMaker.KIND_NAMES.size():
		check(kinds.get(k, 0) >= 50, "plenty of %s passages (got %d)" % [CaveMaker.KIND_NAMES[k], kinds.get(k, 0)])


## Every passage kind has room for a dwarf (0.36 m wide each side, ~1.5 m tall), allowing a small sidestep, about as
## often as the old tubes do (layout 1: ~1% of spots have no room, mostly steep bits you climb).
func test_new_passages_fit_a_dwarf() -> void:
	var c := _v2(42)
	var tot := {}
	var bad := {}
	for s in c.segments:
		var k := int(s.get("k", 0))
		var d: Vector3 = s.b - s.a
		var side := Vector3(-d.z, 0, d.x).normalized() if Vector2(d.x, d.z).length() > 0.01 else Vector3.RIGHT
		for f in [0.25, 0.5, 0.75]:
			var p: Vector3 = (s.a as Vector3).lerp(s.b, f)
			if c._smooth_at(p) <= 0.0:
				continue
			tot[k] = tot.get(k, 0) + 1
			if not _fits(c, p, side):
				bad[k] = bad.get(k, 0) + 1
	for k in tot:
		var rate: float = float(bad.get(k, 0)) / tot[k]
		check(rate < 0.05, "%s: %.1f%% of spots too tight for a dwarf" % [CaveMaker.KIND_NAMES[k], rate * 100.0])


## The cave checks (test_cave_maker.gd) run in the new layout by default now; here they run in the old one too
## (old saves keep it).
func test_cave_checks_pass_in_old_layout() -> void:
	var script: GDScript = load("res://tests/test_cave_maker.gd")
	var was := CaveMaker.layout
	for m in script.get_script_method_list():
		if not String(m.name).begins_with("test_"):
			continue
		var t: TestCase = script.new()
		t.tree = tree
		CaveMaker.use_layout(1)
		await t.call(m.name)
		CaveMaker.use_layout(was)
		for f in t.failures:
			failures.append("%s: %s" % [m.name, f])


## Every hole a passing tunnel leaves high in a room's wall gets a ramp down (F141), gentle and wide enough.
func test_high_holes_have_ramps() -> void:
	var c := _v2(42)
	var ramps := []
	for s in c.segments:
		if s.get("ramp", false):
			ramps.append(s)
	check(ramps.size() >= 10, "ramps were dug (%d)" % (ramps.size() / 2))
	var tot := 0
	var bad := 0
	for s in ramps:
		var d: Vector3 = s.b - s.a
		check(absf(d.y) / Vector2(d.x, d.z).length() <= 0.42, "ramp at %s no steeper than a tunnel" % s.a)
		var side := Vector3(-d.z, 0, d.x).normalized()
		for f in [0.2, 0.4, 0.6, 0.8]:
			tot += 1
			bad += 0 if _fits(c, (s.a as Vector3).lerp(s.b, f), side) else 1
	check(bad <= tot / 50, "a dwarf fits along the ramps (%d of %d spots too tight)" % [bad, tot])


## 4x bigger areas, 3x the places (owner, Nov 17).
func test_more_places_in_new_caves() -> void:
	var c := _v2(42)
	var count := {}
	for p in c.pois:
		count[p.type] = count.get(p.type, 0) + 1
	print("        (%s)" % count)
	for kind in ["ruin", "camp", "nest", "shrine", "geode"]:
		check(count.get(kind, 0) >= 12, "plenty of %s (%d)" % [kind, count.get(kind, 0)])


func _v2(seed: int) -> CaveMaker:
	var was := CaveMaker.layout
	CaveMaker.use_layout(2)
	var c := CaveMaker.new(seed)
	CaveMaker.use_layout(was)
	return c


static func _fits(c: CaveMaker, p: Vector3, side: Vector3) -> bool:
	for o in [0.0, 0.3, -0.3, 0.6, -0.6, 0.9, -0.9, 1.2, -1.2]:
		var q: Vector3 = p + side * o
		if c._smooth_at(q) <= 0.0:
			continue
		var fl := c.find_floor(q.x, q.z, q.y)
		if fl == Vector3.INF or q.y - fl.y > 12.0:
			continue
		if c._smooth_at(fl + Vector3.UP * 0.9) > 0.36 and c._smooth_at(fl + Vector3.UP * 1.5) > 0.3:
			return true
	return false


## Same as tools/cave_stats.gd's fingerprint.
static func _fingerprint(m: CaveMaker) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var sum := 0.0
	for i in 400:
		var r: Dictionary = m.rooms[rng.randi_range(0, m.rooms.size() - 1)]
		var p: Vector3 = r.center + Vector3(rng.randf_range(-30, 30), rng.randf_range(-12, 12), rng.randf_range(-30, 30))
		sum += m.sdf_at(p) * float(1 + i % 7)
	return "rooms=%d segs=%d pois=%d r0=%s sum=%.4f" % [m.rooms.size(), m.segments.size(), m.pois.size(), str(m.rooms[0].center), sum]
