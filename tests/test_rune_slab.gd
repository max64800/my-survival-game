extends TestCase


func test_44_runes_in_8_sets() -> void:
	check_eq(RuneSlab.RUNES.size(), 44, "44 runes (doc 8.1)")
	for c in RuneSlab.COLOURS:
		check_eq(RuneSlab.runes_in_set(c + "_m").size(), 5, "%s Mossy set has 5" % c)
		check_eq(RuneSlab.runes_in_set(c + "_f").size(), 6, "%s Fungal set has 6" % c)


func test_carve_then_duplicate_becomes_shard() -> void:
	var s := RuneSlab.new()
	check_eq(s.offer("ochre_m2"), "carved", "first time: carved")
	check_eq(s.offer("ochre_m2"), "shard", "second time: shard")
	check_eq(s.shards.ochre, 1, "one ochre shard")
	check_near(s.bonus("lantern_fuel"), 0.10, 0.0001, "lantern bonus counted once")


func test_three_shards_carve_a_missing_rune() -> void:
	var s := RuneSlab.new()
	s.offer("cobalt_m1")
	for i in 2:
		s.offer("cobalt_m1")
	check(not s.carve_with_shards("cobalt_m2"), "2 shards aren't enough")
	s.offer("cobalt_m1")
	check(s.carve_with_shards("cobalt_m2"), "3 shards carve m2")
	check_eq(s.shards.cobalt, 0, "shards spent")
	check(not s.carve_with_shards("cobalt_m1"), "can't shard-carve one you have")


func test_set_finish_signal() -> void:
	var s := RuneSlab.new()
	var done := []
	s.set_finished.connect(func(id): done.append(id))
	for id in RuneSlab.runes_in_set("verdant_m"):
		s.offer(id)
	check_eq(done, ["verdant_m"], "finishing the set fires once")
	check_eq(s.finished_sets(), ["verdant_m"], "listed as finished")


func test_runes_teach_recipes() -> void:
	var s := RuneSlab.new()
	s.offer("verdant_m1")
	check(s.taught_recipes().has("dish_glow_broth"), "glow broth taught")
	check(Recipes.is_unlocked("dish_glow_broth", {}, s.taught_recipes()), "recipe shows up")


func test_drop_prefers_missing_runes() -> void:
	var s := RuneSlab.new()
	for id in ["ochre_m1", "ochre_m2", "ochre_m3", "ochre_m4"]:
		s.offer(id)
	check_eq(s.pick_drop("m", [0.0, 0.1, 0.0]), "ochre_m5", "bad-luck protection picks the missing one")
	var any := s.pick_drop("m", [0.0, 0.9, 0.0])
	check(any.begins_with("ochre_m"), "otherwise any ochre Mossy rune")


func test_roundtrip() -> void:
	var s := RuneSlab.new()
	s.offer("crimson_f2")
	s.offer("crimson_f2")
	var t := RuneSlab.new()
	t.load_data(s.to_data())
	check(t.carved_runes.has("crimson_f2"), "carved copied")
	check_eq(t.shards.crimson, 1, "shards copied")
