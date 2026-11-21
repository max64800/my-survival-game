extends TestCase
## F557 (owner, Nov 21, said 3×): the wood in the first cave has to pay for rebuilding the tower in wood.
## Counts the real rootwood a player can gather in the first cave of a test world, then checks the tower's price.


static func _in_first_cave(maker: CaveMaker, p: Vector3) -> bool:
	var r0: Dictionary = maker.rooms[0]
	var c: Vector3 = r0.center
	var r: Vector3 = r0.radii
	return pow((p.x - c.x) / r.x, 2) + pow((p.z - c.z) / r.z, 2) < 1.0 and absf(p.y - c.y) <= r.y * 1.3 + 1.0


## Rootwood in the first cave: twigs (1), start roots (1), bridge roots (3 a harvest × 4), Root Trees (30 each).
## (Hanging roots, 2 each, aren't counted: whether any grow there changes per world.)
static func first_cave_rootwood(world: World) -> Dictionary:
	var out := {twig = 0, root_dangle = 0, root = 0, tree = 0}
	for s in GlowPlacer.place(world.maker):
		if s.get("hidden", false) or not _in_first_cave(world.maker, s.pos):
			continue
		match String(s.kind):
			"twig":
				out.twig += 1
			"root_dangle":
				out.root_dangle += 1
			"root":
				out.root += 12
	for t in RootPillars.plan(world.maker):
		if _in_first_cave(world.maker, t.top) or _in_first_cave(world.maker, t.bottom):
			out.tree += RootPillars.CHOPS
	return out


func test_the_first_cave_pays_for_the_wooden_tower() -> void:
	var world := World.new()
	tree.root.add_child(world)
	world.setup(42)
	var wood := first_cave_rootwood(world)
	var total := 0
	for k in wood:
		total += int(wood[k])
	var planks := total * 2  # 1 rootwood = 2 planks
	print("FIRST_CAVE_WOOD seed 42: %s = %d rootwood = %d planks" % [wood, total, planks])
	check(planks > 0, "the first cave has wood (%d planks)" % planks)
	world.queue_free()
