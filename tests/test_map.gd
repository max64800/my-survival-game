extends TestCase


func test_floors_cover_the_biome() -> void:
	check_eq(MapData.floor_count(), 4, "80 m tall biome = 4 floors of 20 m")
	check_eq(MapData.floor_of(CaveMaker.Y_MIN + 1), 0, "bottom floor")
	check_eq(MapData.floor_of(CaveMaker.Y_MAX - 1), 3, "top floor")


func test_reveal_draws_open_and_rock() -> void:
	var m := MapData.new()
	# Pretend world: open air where x < 0, rock where x >= 0.
	var sdf := func(p: Vector3) -> float: return 1.0 if p.x < 0.0 else -1.0
	var at := Vector3(0, -30, 0)
	m.reveal(at, sdf)
	var f := MapData.floor_of(at.y)
	var img: Image = m.floors_at(at)[f]
	var c := m.to_pixel(at)
	check(_same(img.get_pixel(c.x - 6, c.y), MapData.OPEN), "left side drawn as open")
	check(_same(img.get_pixel(c.x + 6, c.y), MapData.ROCK), "right side drawn as rock")
	check_eq(img.get_pixel(c.x + 40, c.y).a, 0.0, "far away still unseen")
	check(m.seen_fraction(f) > 0.0, "something seen on this floor")
	check_eq(m.seen_fraction((f + 1) % 4), 0.0, "other floors untouched")


func test_each_biome_has_its_own_pages() -> void:
	var m := MapData.new()
	var sdf := func(_p: Vector3) -> float: return 1.0
	var jungle := Vector3(420, -30, 0)
	m.reveal(jungle, sdf)
	var f := MapData.floor_of(jungle.y)
	check(m.seen_fraction(f, "fungal") > 0.0, "the Jungle page got drawn")
	check_eq(m.seen_fraction(f, "mossy"), 0.0, "the Mossy page didn't")
	check_eq(m.to_pixel(jungle), Vector2i(200, 200), "the Jungle's middle is the middle of its page")
	var back := MapData.new()
	back.load_data(m.to_data())
	check(back.seen_fraction(f, "fungal") > 0.0, "jungle pages are saved and loaded")


func test_climbing_leaves_markers() -> void:
	var m := MapData.new()
	var sdf := func(_p: Vector3) -> float: return 1.0
	m.reveal(Vector3(10, -50, 10), sdf)
	m.reveal(Vector3(12, -30, 10), sdf)
	check_eq(m.markers.size(), 2, "a ▲ on the floor you left and a ▼ on the new one")
	check(m.markers[0].up, "climbed up")


## Colors are stored with 8 bits, so compare with a little room.
func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01 and absf(a.a - b.a) < 0.01
