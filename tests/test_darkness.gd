extends TestCase
## F293: lights that count, and how far they reach.


func test_lights_reach_and_empty_lantern_is_dark() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	var here := Vector3(500, 0, 500)
	check(not Darkness.is_lit(tree, here), "no light: dark")
	var torch := OmniLight3D.new()
	torch.omni_range = 8.0
	torch.light_energy = 1.0
	Darkness.mark(torch)
	root.add_child(torch)
	torch.global_position = here + Vector3(4, 0, 0)
	check(Darkness.is_lit(tree, here), "a torch 4 m away lights you")
	torch.global_position = here + Vector3(7.5, 0, 0)
	check(not Darkness.is_lit(tree, here), "at the dim edge of its range it doesn't")
	var lantern := OmniLight3D.new()
	lantern.omni_range = 4.5
	lantern.light_energy = 0.45  # an empty lantern
	Darkness.mark(lantern, 0.6)
	root.add_child(lantern)
	lantern.global_position = here
	check(not Darkness.is_lit(tree, here), "an empty lantern's glow is still dark")
	lantern.light_energy = 1.9
	check(Darkness.is_lit(tree, here), "a lit lantern is light")
	var creature := OmniLight3D.new()  # not marked: a glowing creature doesn't count
	creature.light_energy = 2.0
	root.add_child(creature)
	lantern.visible = false
	creature.global_position = here
	check(not Darkness.is_lit(tree, here), "a put-away lantern and a creature's glow: dark")
	root.free()
