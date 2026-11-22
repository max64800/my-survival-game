extends TestCase
## F724 (owner, Nov 22): a puff of dust as a piece goes up, different for each material.


func test_each_material_has_its_own_dust() -> void:
	check_eq(Fx.build_dust_kind("plank_root"), "wood", "rootwood: wood chips")
	check_eq(Fx.build_dust_kind("plank_mushroom"), "wood", "capwood: wood chips")
	check_eq(Fx.build_dust_kind("cut_stone"), "stone", "cut stone: grit")
	check_eq(Fx.build_dust_kind("clay_brick"), "brick", "clay brick: red brick dust")
	check_eq(Fx.build_dust_kind("copper_ingot"), "metal", "copper: sparks")
	var wood: Color = Fx.build_dust_colors("plank_root").dust
	var stone: Color = Fx.build_dust_colors("cut_stone").dust
	var brick: Color = Fx.build_dust_colors("clay_brick").dust
	check(brick.r - brick.b > 0.25, "brick dust is red (%s)" % brick)
	check(absf(stone.r - stone.b) < 0.1, "stone dust is grey (%s)" % stone)
	check(wood.r - wood.b > 0.2 and wood.v > brick.v, "sawdust is pale tan (%s)" % wood)


func test_puff_makes_chips_and_dust_that_clean_up() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	Fx.build_puff(root, Pieces.box("wall", Vector3.ZERO, 0), "clay_brick")
	var parts := root.get_children().filter(func(c): return c is CPUParticles3D)
	check_eq(parts.size(), 2, "flying bits + a dust cloud")
	for p: CPUParticles3D in parts:
		check(p.one_shot and p.emitting, "a single puff, not a loop")
		check(p.finished.get_connections().size() > 0, "it removes itself when done")
	check_eq((parts[0] as CPUParticles3D).emission_shape, CPUParticles3D.EMISSION_SHAPE_BOX, "spread along the wall's foot")
	root.free()


func test_loading_a_world_does_not_puff() -> void:
	var src := FileAccess.get_file_as_string("res://src/build/builder.gd")
	check(src.contains("not batch and not _loading"), "no puffs while a ruin is placed or a save is loaded")
