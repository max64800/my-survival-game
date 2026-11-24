extends TestCase
## F833 🔁 (F165, owner Nov 24): a wall, window or doorway standing on another one with no floor between them left a
## 25 cm open slit (walls are 2 m tall, a storey 2.25 m). Builder.gap_fill_for gives the lower one a beam there.


func _structure_of(bp: Blueprint) -> Structure:
	var st := Structure.new()
	var uid := 1
	for p in bp.pieces:
		st.add(uid, p.id, p.mat, p.pos, p.rot, false)
		uid += 1
	return st


## Every stacked pair of wall-like pieces: touching, or a floor's rim fills the slit, or the gap beam does.
func _open_slits(st: Structure) -> Array:
	var bad := []
	for uid in st.pieces:
		var low: Dictionary = st.pieces[uid]
		if not Builder._stacks(low.piece):
			continue
		var ls: Vector3 = Pieces.LIST[low.piece].size
		var top: float = low.pos.y + ls.y
		var back := Basis(Vector3.UP, -Pieces.yaw_of(low.rot))
		var fill := Builder.gap_fill_for(st, uid)
		for q in st.near(AABB(Vector3(low.pos.x, top, low.pos.z) - Vector3(2.5, 0, 2.5), Vector3(5, 0.4, 5))):
			var up: Dictionary = st.pieces[q]
			if q == uid or not Builder._stacks(up.piece):
				continue
			var gap: float = up.pos.y - top
			var d: Vector3 = back * (up.pos - low.pos)
			if gap < 0.02 or gap > Builder.GAP_MAX or absf(d.z) > 0.05 \
					or absf(sin(Pieces.yaw_of(up.rot) - Pieces.yaw_of(low.rot))) > 0.05:
				continue
			var a := maxf(-ls.x * 0.5, d.x - Pieces.LIST[up.piece].size.x * 0.5)
			var b := minf(ls.x * 0.5, d.x + Pieces.LIST[up.piece].size.x * 0.5)
			if b - a < 0.1 or Builder._floor_fills(st, low, top, gap, (a + b) * 0.5):
				continue
			if fill.y < gap - 0.001 or fill.x > a + 0.01 or fill.z < b - 0.01:
				bad.append("%s %s at %s under %s %s" % [low.piece, low.mat if low.has("mat") else low.family, low.pos, up.piece, up.family])
	return bad


func test_prow_hall_stacked_walls_leave_no_slit() -> void:
	for id in ["wooden_prow_hall", "stonehold_prow_hall"]:
		var st := _structure_of(BlueprintLibrary.make(id))
		var filled := 0
		for uid in st.pieces:
			if Builder._stacks(st.pieces[uid].piece) and Builder.gap_fill_for(st, uid).y > 0.0:
				filled += 1
		check(filled > 0, "%s: the tall hall's stacked walls get gap beams (%d)" % [id, filled])
		var bad := _open_slits(st)
		check_eq(bad.size(), 0, "%s: no open slit between stacked walls %s" % [id, bad.slice(0, 3)])


func test_no_blueprint_leaves_a_slit_between_stacked_walls() -> void:
	for b in BlueprintLibrary.list():
		var bad := _open_slits(_structure_of(BlueprintLibrary.make(b.id)))
		check_eq(bad.size(), 0, "%s: no open slit %s" % [b.id, bad.slice(0, 3)])


func test_player_stacked_walls_wood_and_stone() -> void:
	for fam in ["plank_root", "cut_stone"]:
		for upper in ["wall", "window_wall", "doorway", "window_wide"]:
			var st := Structure.new()
			st.add(1, "wall", fam, Vector3(1, 0, 0), 0, true)
			# A storey up (2.25 m, like the floor next to it): the slit the owner saw.
			st.add(2, upper, "cut_stone" if fam == "plank_root" else "plank_root", Vector3(1, 2.25, 0), 0, false)
			var fill := Builder.gap_fill_for(st, 1)
			check_near(fill.y, 0.25, 0.001, "%s %s on a wall: the 25 cm slit is filled" % [fam, upper])
			check(fill.x < -0.98 and fill.z > 0.98, "%s %s: the whole 2 m width" % [fam, upper])
			# With a floor beside it, the floor's rim fills it: no beam (no two things in the same place).
			st.add(3, "floor", fam, Vector3(1, 2.0, 1), 0, false)
			check_eq(Builder.gap_fill_for(st, 1), Vector3.ZERO, "%s %s: floor beside it, its rim fills the slit" % [fam, upper])
	# Snapped right on top (aiming at the wall's top) there's no slit at all.
	var st2 := Structure.new()
	st2.add(1, "wall", "plank_root", Vector3(1, 0, 0), 0, true)
	var s := Pieces.snap("wall", Vector3(1, 2.0, 0), Vector3.UP, 0.0, 0, 0.0, Pieces.box("wall", Vector3(1, 0, 0), 0),
			{piece = "wall", pos = Vector3(1, 0, 0), rot = 0})
	check_near(s.pos.y, 2.0, 0.001, "wall on a wall snaps straight on top")
	st2.add(2, "wall", "plank_root", s.pos, s.rot, false)
	check_eq(Builder.gap_fill_for(st2, 1), Vector3.ZERO, "nothing to fill when they touch")


## The beam really shows in the game: a PieceNode gets it, sized to the slit, and loses it again.
func test_gap_beam_node() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	for fam in ["plank_root", "cut_stone", "clay_brick", "plank_mushroom"]:
		var n: PieceNode = load("res://src/build/piece_node.gd").new()
		n.piece = "wall"
		n.family = fam
		root.add_child(n)
		n.set_gap_fill(Vector3(-0.995, 0.25, 0.995))
		var g := n.get_node_or_null("GapFill")
		check(g != null, "%s: gap beam added" % fam)
		if g:
			var mi: MeshInstance3D = g.get_child(0)
			var box := mi.transform * mi.mesh.get_aabb()
			check_near(box.position.y, 2.0 - PieceNode.GAP_OVERLAP, 0.002, "%s: starts 1 cm inside the wall below" % fam)
			check_near(box.end.y, 2.25 + PieceNode.GAP_OVERLAP, 0.002, "%s: ends 1 cm inside the wall above" % fam)
			check_near(box.size.z, 0.3 + PieceNode.GAP_PROUD * 2.0, 0.002, "%s: 1.5 cm proud of both faces (no shimmer)" % fam)
		n.set_gap_fill(Vector3.ZERO)
		await tree.process_frame
		check(n.get_node_or_null("GapFill") == null, "%s: gap beam gone again" % fam)
	root.queue_free()
