extends TestCase
## Treasure in old places (owner, Nov 19): ruins get coins, candles and books by the loot chest (never on it), camps a
## traveller's things; every model exists; ruins keep their loot in the banded loot chest with a lid that opens.


func test_treasure_by_the_chest_never_on_it() -> void:
	var total := 0
	for sd in 30:
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		for t in RuinTreasure.plan({type = "ruin"}, rng):
			total += 1
			var at: Vector3 = t.at
			check(at.distance_to(RuinTreasure.CHEST_SPOT) >= 0.7, "nothing on the loot chest (%.2f m)" % at.distance_to(RuinTreasure.CHEST_SPOT))
			check(Vector2(at.x, at.z).length() < 3.4, "inside the ruin's walls")
			check(ResourceLoader.exists("res://assets/models/treasure/%s.glb" % t.model), "%s has its model" % t.model)
		rng.seed = sd
		for t in RuinTreasure.plan({type = "camp"}, rng):
			check(ResourceLoader.exists("res://assets/models/treasure/%s.glb" % t.model), "%s has its model" % t.model)
	check(total >= 30 * 7, "every ruin gets a handful of things (%d in 30)" % total)


func test_loot_chest_has_a_lid() -> void:
	var scene := Look.forged("stations", "chest_loot")
	check(scene != null, "the loot chest model exists")
	if scene:
		check(ChestOpen.lid_of(scene) != null, "its lid swings open (owner F345)")
		scene.free()
	check(Storage.SIZES.has("chest_loot"), "it holds things")
