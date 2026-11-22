extends TestCase
## F567 🔁🔁 (owner, said 3×: "I still see the blue outlines when I'm holding a hammer"). Holds the Build Hammer
## next to every kind of thing that could glow blue (a ruin being rebuilt and its built pieces, your own
## blueprint build site) and lists every blue see-through look on screen. Nothing may be blue unless you're
## placing something (the green/red preview, or a blueprint you're aiming).

var world: World
var auth: GameAuthority
var ps: GameAuthority.PlayerState


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = Node3D.new()
	auth.stations_root = Node3D.new()
	root.add_child(auth.drops_root)
	root.add_child(auth.stations_root)
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	me.global_position = world.maker.cavern_spawn
	ps = auth.add_player(1, me)


func _hold(item: String) -> void:
	if ps.inventory.count_of(item) == 0:
		ps.inventory.add(item, 1)
	ps.selected_slot = ps.inventory.slots.find_custom(func(s): return not s.is_empty() and s.id == item)


static func _is_blue(m: Material) -> bool:
	var sm := m as StandardMaterial3D
	if sm == null or sm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
		return false
	var c := sm.albedo_color
	return c.b > c.r + 0.25 and c.b >= c.g


## Every blue see-through look that's showing, named by what it belongs to.
func _blue_things(root: Node) -> Dictionary:
	var out := {}
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var blue := (g.material_override != null and _is_blue(g.material_override)) \
			or (g.material_overlay != null and _is_blue(g.material_overlay))
		if not blue:
			continue
		var p := g.get_parent()
		while p != null and not p is PieceNode:
			p = p.get_parent()
		var what := "something else (%s)" % g.get_path()
		if p is PieceNode:
			var pn := p as PieceNode
			what = "a blueprint site's plan" if pn.plan else ("the placing preview" if pn.ghost else "a built piece's strength glow")
		out[what] = int(out.get(what, 0)) + 1
	return out


func test_hammer_shows_nothing_blue() -> void:
	await _setup()
	var b: Builder = auth.builder
	# 1. The ruined tower, partly rebuilt (its real pieces stand there, like after filling its chest).
	var job := RuinTower.new(auth)
	auth.add_child(job)
	job._state = "carve"
	for i in 600:
		if not is_instance_valid(job):
			break
		await tree.process_frame
	var box := RuinTower.last_rebuild_box
	check(auth.storage.boxes.has(box), "the ruin has a Rebuilding Chest")
	b.instant_ruins = true
	auth.storage.put(box, "plank_root", 60)
	for i in 60:
		await tree.process_frame
	# 2. Your own blueprint build site, half built.
	var bp_box: int = auth.storage.create_box("builder", world.maker.cavern_spawn + Vector3(4, 0, 0), 0.0, 1)
	b._ev_site(bp_box, BlueprintLibrary.make("delvers_hut").to_json(), world.maker.cavern_spawn + Vector3(8, 0, 0), 0, [])
	check(b.sites.has(bp_box), "your own build site exists")
	check(not b.nodes.is_empty(), "there are built pieces in the world (%d)" % b.nodes.size())
	# Hammer in hand, not placing anything.
	_hold("build_hammer")
	var bm := BuildMode.new()
	auth.add_child(bm)
	bm.set_process(false)  # (no dwarf in this test: its own _process would say "no hammer" every frame)
	for i in 3:
		bm._update_tints(1.0, true)  # (what BuildMode._process does while the hammer is out)
		await tree.process_frame
	var blue := _blue_things(auth.get_parent())
	var strengths := {}
	for uid in b.nodes:
		var c := Structure.strength_color(b.structure.pieces[uid].stability) if b.structure.pieces.has(uid) else Color.BLACK
		strengths[c] = int(strengths.get(c, 0)) + 1
	print("F567 BLUE WITH HAMMER: %s | %d pieces, strength colours %s" % [blue, b.nodes.size(), strengths])
	check(blue.is_empty(), "holding the hammer shows nothing blue (F567): %s" % [blue])
	# Shaky pieces still warn you (yellow / red); strong and good ones don't glow at all.
	check_eq(BuildMode.warning_tint(1.0).a, 0.0, "a strong piece doesn't glow")
	check_eq(BuildMode.warning_tint(0.6).a, 0.0, "a good piece doesn't glow")
	check_eq(BuildMode.warning_tint(0.3), Structure.strength_color(0.3), "a weak piece glows yellow")
	check_eq(BuildMode.warning_tint(0.1), Structure.strength_color(0.1), "a barely-held piece glows red")
	auth.get_parent().queue_free()
