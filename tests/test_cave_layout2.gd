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
	CaveMaker.use_layout(was)


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
