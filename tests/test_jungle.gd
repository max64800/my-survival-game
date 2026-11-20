extends TestCase
## The Fungal Jungle (biome 2): its monsters, plants and rocks fit together.


func test_every_monster_is_complete() -> void:
	for id in Monsters.LIST:
		var m: Dictionary = Monsters.LIST[id]
		if MonsterModel.RIG_LOOKS.has(id):  # (a skeleton creature: its own model and moves, test_skeleton_miners)
			var rigged := MonsterModel.build(m.shape, m.color, m.size, true, id)
			var holder := Node3D.new()
			holder.add_child(rigged)
			check(CreatureRig.find(rigged) != null, "%s moves by its skeleton" % id)
			holder.free()
		elif MonsterModel.variant_count(id) > 0:  # (a hand-built model only, like the Cave Spider: no simple-shapes body)
			var forged := MonsterModel.build(m.shape, m.color, m.size, true, id)
			check(forged.has_meta("forged_root"), "%s wears its hand-built model" % id)
			forged.free()
		else:
			var model := MonsterModel.build(m.shape, m.color, m.size, true)
			check(model.get_child_count() >= 6, "%s has a body (%s)" % [id, m.shape])
			model.free()
		for d in m.drops:
			check(Items.exists(d[0]), "%s drops a real item: %s" % [id, d[0]])
		for a in m.attacks:
			check(a.tell >= 0.4 and a.damage > 0 and a.reach > 0.0, "%s: %s has sane numbers" % [id, a.name])


func test_jungle_spawns_use_jungle_monsters() -> void:
	for kind in Monsters.SPAWNS.fungal.big + Monsters.SPAWNS.fungal.small:
		# Owner's first three (Nov 14): big beetles and bats live in the jungle; no snails there.
		check(Monsters.LIST[kind].shape in ["rock_beetle", "cave_bat"], "%s is a jungle monster" % kind)
		check(kind != "rock_snail", "no snails in the jungle")


func test_jungle_rocks() -> void:
	for biome in Mat.PALETTES:
		for key in Mat.PALETTES[biome]:
			var m: int = Mat.PALETTES[biome][key]
			check(Mat.HARDNESS.has(m) and Mat.NAMES.has(m), "%s %s has hardness and a name" % [biome, key])
	check_eq(Mat.hits_needed(Mat.SILVER, Items.dig_power("pickaxe_stone"), 0), 0, "silver needs a copper pickaxe")
	check(Mat.hits_needed(Mat.SILVER, Items.dig_power("pickaxe_copper"), 1) > 0, "copper pickaxe digs silver")
	check_eq(Mat.hits_needed(Mat.EDGE, 999.0, 5), 0, "nothing digs the world's edge")
	for m in Mat.DROP_ITEM.values():
		check(Items.exists(m), "rock drops a real item: %s" % m)
	var c := CaveMaker.new(42)
	var counts := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 3000:
		var p := Vector3i(rng.randi_range(230, 610), rng.randi_range(-60, 10), rng.randi_range(-190, 190))
		if c.sdf_at(Vector3(p)) < -1.0:
			var m := c.material_at(p)
			counts[m] = counts.get(m, 0) + 1
	check(counts.get(Mat.SPORESTONE, 0) > counts.get(Mat.STONE, 0), "the Jungle is made of sporestone")
	check(counts.get(Mat.SILVER, 0) > 0, "silver ore exists")
	check(counts.get(Mat.AMBERROCK, 0) > 0, "amberrock exists")
	check_eq(counts.get(Mat.COPPER, 0), 0, "no copper in the Jungle")


func test_glow_items_exist() -> void:
	for k in GlowPlacer.KINDS:
		if GlowPlacer.KINDS[k].item == "":
			continue  # drips mark water spots; there's nothing to pick
		check(Items.exists(GlowPlacer.KINDS[k].item), "%s gives a real item" % k)
		if GlowPlacer.KINDS[k].has("extra"):
			check(Items.exists(GlowPlacer.KINDS[k].extra), "%s extra is a real item" % k)


func test_jungle_runes_and_backfill() -> void:
	var slab := RuneSlab.new()
	check(slab.pick_drop("f", [0.1, 0.9, 0.5, 0.9]).ends_with("f1") or slab.pick_drop("f", [0.1, 0.9, 0.5, 0.9]).contains("_f"), "jungle drops jungle runes")
	check(slab.pick_drop("f", [0.1, 0.9, 0.5, 0.1]).contains("_m"), "sometimes a missing Mossy rune instead")
	check_eq(GameAuthority.rune_biome_at(Vector3(CaveMaker.BIOMES[1].cx, -20, 0)), "f", "jungle position")
	check_eq(GameAuthority.rune_biome_at(Vector3(0, -20, 0)), "m", "mossy position")


func test_crystal_variants() -> void:
	check_eq(Monsters.roll_variant("mossy", 0.5, 0.1), "", "most monsters are normal")
	check_eq(Monsters.roll_variant("fungal", 0.05, 0.1), "green", "jungle: green is the most common crystal")
	check_eq(Monsters.roll_variant("mossy", 0.03, 0.1), "red", "mossy: red first")
	check_eq(Monsters.roll_variant("mossy", 0.05, 0.1), "", "mossy chance is 4%")
	check_near(Monsters.max_hp("great_rock_beetle", false, "green"), 220.0 * 1.4, 0.01, "variants have 40% more health")
	check_eq(Monsters.target_stats("great_rock_beetle", false, "amber").armor, 45 + 30, "amber skin: +30 armor")
	for v in Monsters.VARIANTS:
		check(Items.exists(Monsters.VARIANTS[v].crystal), "%s drops a real crystal" % v)
	var model := MonsterModel.build("rock_beetle", Color.GRAY, 1.0, false)
	var before := model.get_child_count()
	MonsterModel.add_crystals(model, Color.RED)
	check(model.get_child_count() > before, "crystals grow on its back")
	model.free()
