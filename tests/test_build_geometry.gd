extends TestCase
## Building geometry (owner's test list, Nov 15): 60° triangles, snapping edge to edge, no gaps,
## nothing floating or sunk, walls on triangle edges, and what stands after a support is removed.

const EPS := 0.002


func _edge_pts(piece: String, pos: Vector3, rot: int) -> Array:
	var fp := Pieces.footprint(piece, pos, rot)
	var out := []
	for i in fp.size():
		out.append([fp[i], fp[(i + 1) % fp.size()]])
	return out


## Do two pieces share a whole side (same two corners)? = no gap and no overlap between them.
func _share_side(a: Dictionary, b: Dictionary) -> bool:
	for ea in _edge_pts(a.piece, a.pos, a.rot):
		for eb in _edge_pts(b.piece, b.pos, b.rot):
			if (ea[0].distance_to(eb[1]) < 0.01 and ea[1].distance_to(eb[0]) < 0.01) \
					or (ea[0].distance_to(eb[0]) < 0.01 and ea[1].distance_to(eb[1]) < 0.01):
				return true
	return false


func test_triangle_is_equilateral() -> void:
	var fp := Pieces.footprint("foundation_triangle", Vector3.ZERO, 0)
	check_eq(fp.size(), 3, "three corners")
	for i in 3:
		check_near(fp[i].distance_to(fp[(i + 1) % 3]), 2.0, EPS, "side %d is 2 m (one wall)" % i)
	var turned := Pieces.footprint("foundation_triangle", Vector3.ZERO, Pieces.rot_from_steps(2))
	for i in 3:
		check_near(turned[i].distance_to(turned[(i + 1) % 3]), 2.0, EPS, "still 2 m sides when turned 60°")
	check_eq(Pieces.rot_from_steps(3), 1, "90° is stored as an old quarter turn (old saves still work)")
	check_eq(Pieces.rot_from_steps(2), 6, "60° is stored as a 30° step")
	check_near(Pieces.yaw_of(6), PI / 3.0, 0.0001, "and turns 60°")


func test_triangle_snaps_onto_a_square_side() -> void:
	var sq := {piece = "foundation", pos = Vector3(0, 0, 0), rot = 0}
	for aim in [Vector3(1.0, 0.5, 0.2), Vector3(-0.3, 0.5, 1.0), Vector3(-1.0, 0.5, 0.0), Vector3(0.2, 0.5, -1.0)]:
		var n := Vector3(signf(aim.x) if absf(aim.x) > 0.9 else 0.0, 0, signf(aim.z) if absf(aim.z) > 0.9 else 0.0)
		var t := Pieces.snap("foundation_triangle", aim, n, 0.0, 0, 0.0, Pieces.box("foundation", Vector3.ZERO, 0), sq)
		var tri := {piece = "foundation_triangle", pos = t.pos, rot = t.rot}
		check(_share_side(sq, tri), "triangle on side %s shares the whole side (no gap)" % n)
		check_near(t.pos.y, 0.0, EPS, "same height as the square")
		var s := Structure.new()
		s.add(1, "foundation", "cut_stone", sq.pos, 0, true)
		check(not s.overlaps("foundation_triangle", t.pos, t.rot), "and doesn't overlap it")


func test_six_triangles_make_a_hexagon() -> void:
	# Start with one triangle, keep snapping the next one onto the side facing round the circle.
	var s := Structure.new()
	var tris := [{piece = "floor_triangle", pos = Vector3(0, 0, -Pieces.TRI_OUT), rot = Pieces.rot_from_steps(6)}]
	s.add(1, "floor_triangle", "cut_stone", tris[0].pos, tris[0].rot, true)
	var centre := Vector3.ZERO
	for i in 5:
		var last: Dictionary = tris[-1]
		# Aim at a side of the last triangle that touches the centre and is still free (going round).
		var t := {}
		for e in Pieces.edges(last.piece, last.pos, last.rot):
			if (e.mid as Vector3).distance_to(centre) > 1.01 or (e.mid as Vector3).distance_to(centre) < 0.99:
				continue  # the outer side (its middle is 1.73 m out); the inner sides' middles are 1 m out
			var aim: Vector3 = e.mid + e.normal * 0.01 + Vector3.UP * 0.1
			var cand := Pieces.snap("floor_triangle", aim, e.normal, 0.0, 0, 0.0, Pieces.box(last.piece, last.pos, last.rot), last)
			if not s.overlaps("floor_triangle", cand.pos, cand.rot):
				t = cand
				break
		check(not t.is_empty(), "a free side for triangle %d" % (i + 2))
		if t.is_empty():
			return
		check(not s.overlaps("floor_triangle", t.pos, t.rot), "triangle %d fits next to the last one" % (i + 2))
		check(_share_side(last, {piece = "floor_triangle", pos = t.pos, rot = t.rot}), "triangle %d shares a whole side" % (i + 2))
		s.add(i + 2, "floor_triangle", "cut_stone", t.pos, t.rot, true)
		tris.append({piece = "floor_triangle", pos = t.pos, rot = t.rot})
	var all_touch_centre := true
	for t in tris:
		var near := false
		for q in Pieces.footprint(t.piece, t.pos, t.rot):
			near = near or q.distance_to(Vector2.ZERO) < 0.01
		all_touch_centre = all_touch_centre and near
	check(all_touch_centre, "all six meet in the middle: a hexagon")
	check(_share_side(tris[5], tris[0]), "the sixth closes the ring with no gap")


func test_walls_stand_on_triangle_edges() -> void:
	var tri := {piece = "foundation_triangle", pos = Vector3(3, 0, 3), rot = Pieces.rot_from_steps(1)}
	var s := Structure.new()
	s.add(1, tri.piece, "cut_stone", tri.pos, tri.rot, true)
	var uid := 2
	for e in Pieces.edges(tri.piece, tri.pos, tri.rot):
		var aim: Vector3 = e.mid - e.normal * 0.3 + Vector3.UP * 1.0
		var w := Pieces.snap("wall", aim, Vector3.UP, 0.0, 0, 0.0, Pieces.box(tri.piece, tri.pos, tri.rot), tri)
		check_near(w.pos.y, 1.0, EPS, "the wall stands on top of the foundation")
		# owner, Nov 20: fully on top, its outside face on the triangle's side (half the 0.3 m wall in from the side)
		var inside: Vector3 = e.mid - e.normal * 0.15
		check_near(Vector2(w.pos.x, w.pos.z).distance_to(Vector2(inside.x, inside.z)), 0.0, EPS, "outside face on the side")
		var wf := Pieces.footprint("wall", w.pos, w.rot)
		var along := (wf[1] - wf[0]).normalized()
		check_near(absf(along.dot(Vector2(e.normal.x, e.normal.z))), 0.0, 0.001, "running along the side")
		check(not s.overlaps("wall", w.pos, w.rot), "doesn't overlap the other walls (corners meet)")
		s.add(uid, "wall", "plank_root", w.pos, w.rot, false)
		uid += 1
	check(s.recompute().is_empty(), "a triangle room of 3 walls stands")
	for u in [2, 3, 4]:
		check(s.neighbors(u).has(1), "wall %d rests on the triangle" % u)


func test_squares_join_with_no_gaps() -> void:
	var a := {piece = "foundation", pos = Vector3(0, 0, 0), rot = 0}
	for d in [Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.FORWARD]:
		var t := Pieces.snap("foundation", d * 1.0 + Vector3.UP * 0.5, d, 0.0, 0, 0.0, Pieces.box("foundation", Vector3.ZERO, 0), a)
		check(_share_side(a, {piece = "foundation", pos = t.pos, rot = t.rot}), "foundation on side %s: no gap" % d)
	# A square onto a 30°-turned triangle's side: turned too, still edge to edge.
	var tri := {piece = "foundation_triangle", pos = Vector3.ZERO, rot = Pieces.rot_from_steps(1)}
	var e: Dictionary = Pieces.edges(tri.piece, tri.pos, tri.rot)[0]
	var t := Pieces.snap("foundation", e.mid + e.normal * 0.01 + Vector3.UP * 0.5, e.normal, 0.0, 0, 0.0, Pieces.box(tri.piece, tri.pos, tri.rot), tri)
	check(t.rot >= Pieces.FINE_ROT, "the square turns to match (%d)" % t.rot)
	check(_share_side(tri, {piece = "foundation", pos = t.pos, rot = t.rot}), "and meets the triangle side with no gap")


func test_triangles_stack_and_take_pillars() -> void:
	var tri := {piece = "foundation_triangle", pos = Vector3(0, 0, 0), rot = Pieces.rot_from_steps(2)}
	var top := Pieces.snap("floor_triangle", Vector3(0.1, 1.0, 0.1), Vector3.UP, 0.0, 0, 0.0, Pieces.box(tri.piece, tri.pos, tri.rot), tri)
	check_near(top.pos.y, 1.0, EPS, "a triangle floor sits on top")
	check_eq(top.rot, tri.rot, "turned the same way")
	var pil := Pieces.snap("pillar", Vector3(0.9, 1.0, 0.4), Vector3.UP, 0.0, 0, 0.0, Pieces.box(tri.piece, tri.pos, tri.rot), tri)
	var on_corner := false
	for q in Pieces.footprint(tri.piece, tri.pos, tri.rot):
		on_corner = on_corner or q.distance_to(Vector2(pil.pos.x, pil.pos.z)) < 0.01
	check(on_corner, "a pillar goes on a corner")


func test_old_saves_still_load() -> void:
	check(Pieces.LIST.has("wall_diagonal"), "the old 45° wall still exists for old saves")
	check(not BuildMenu.pieces_in("wall").has("wall_diagonal"), "but isn't offered any more")
	var bp := BlueprintLibrary.make("stone_hall")
	var placed := bp.world_pieces(Vector3.ZERO, 1)
	check(placed[0].rot < Pieces.FINE_ROT, "blueprints still turn in quarter turns")


# ---------------------------------------------------------------- nothing floating, nothing sunk

## Every piece's shape (made in code) sits on its base and stays inside its own outline:
## nothing floats above the floor, sinks below it, or pokes far out of its space.
func test_code_shapes_sit_on_their_base() -> void:
	var bad := []
	for id in Pieces.LIST:
		if Pieces.LIST[id].group == "legacy":
			continue
		for fam in ["plank_root", "cut_stone"]:
			if not Pieces.allowed(id, fam):
				continue
			var b := PieceMesh.visual(id, fam).get_aabb()
			var want := Pieces.box(id, Vector3.ZERO, 0)
			var hangs: bool = Pieces.LIST[id].get("on_wall", false)  # banners, shields, sconces hang above the base
			if absf(b.position.y) > 0.02 and not hangs:
				bad.append("%s/%s bottom at %.3f" % [id, fam, b.position.y])
			for axis in [0, 2]:
				if b.position[axis] < want.position[axis] - 0.12 or b.end[axis] > want.end[axis] + 0.12:
					bad.append("%s/%s sticks out on %s (%.2f..%.2f, space %.2f..%.2f)" % [id, fam, "xyz"[axis], b.position[axis], b.end[axis], want.position[axis], want.end[axis]])
			if b.end.y > want.end.y + 0.12:
				bad.append("%s/%s too tall (%.2f > %.2f)" % [id, fam, b.end.y, want.end.y])
	check(bad.is_empty(), "every shape sits in its space: %s" % [bad])


static func floating_islands(mesh: Mesh) -> Array:
	return PieceMesh.islands(mesh)


func test_code_shapes_have_no_floating_bits() -> void:
	var bad := []
	for id in Pieces.LIST:
		if Pieces.LIST[id].group == "legacy":
			continue
		for fam in ["plank_root", "cut_stone", "copper_ingot"]:
			if Pieces.allowed(id, fam):
				var g := floating_islands(PieceMesh.visual(id, fam))
				if g.size() > 1:
					bad.append("%s/%s: %d parts" % [id, fam, g.size()])
	check(bad.is_empty(), "every code shape is one connected piece: %s" % [bad])


## Claude 2's hand-made models (only the ones on this computer): each must fit its piece and be in one piece.
func test_hand_made_models_fit_and_hold_together() -> void:
	var dir := "res://assets/models/build"
	if not DirAccess.dir_exists_absolute(dir):
		check(true, "no hand-made building models on this computer")
		return
	var misfits := []
	var floating := []
	var n := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".glb"):
			continue
		var parts := f.trim_suffix(".glb").split("__")
		if parts.size() != 2 or not Pieces.LIST.has(parts[0]):
			continue
		var scene: Node3D = Look.forged("build", f.trim_suffix(".glb"))
		if scene == null:
			continue
		var meshes := scene.find_children("*", "MeshInstance3D", true, false)
		if meshes.size() == 1:
			n += 1
			var m: Mesh = (meshes[0] as MeshInstance3D).mesh
			var why := PieceNode.model_misfit(parts[0], m.get_aabb())
			if why != "":
				misfits.append("%s (%s)" % [f, why])
			var g := floating_islands(m)
			if g.size() > 1:
				floating.append("%s: %d parts" % [f, g.size()])
		scene.free()
	print("        (%d hand-made building models checked; misfits %d, floating %d)" % [n, misfits.size(), floating.size()])
	if not misfits.is_empty():
		print("        misfits: ", misfits)
	if not floating.is_empty():
		print("        floating: ", floating)
	# Models that don't fit or have floating parts are never used: the game falls back to the shape
	# made in code (and warns), so a bad model can't put a gap or a floating bit in your house.
	var used_bad := []
	for f in misfits + floating:
		var key: String = f.get_slice(".glb", 0)
		var parts := key.split("__")
		if PieceNode.forged_mesh(parts[0], parts[1]) != null:
			used_bad.append(key)
	check(used_bad.is_empty(), "the game never uses a model that doesn't fit or has floating parts: %s" % [used_bad])


# ---------------------------------------------------------------- taking a support out

func test_removing_a_support() -> void:
	# A floor held up in the air by a pillar on a foundation, with a wall on it.
	var s := Structure.new()
	s.add(1, "foundation", "cut_stone", Vector3(0, 0, 0), 0, true)
	s.add(2, "pillar", "plank_root", Vector3(1, 1, 1), 0, false)
	s.add(3, "floor", "plank_root", Vector3(2, 3, 2), 0, false)
	s.add(4, "wall", "plank_root", Vector3(2, 3.25, 3), 0, false)
	check(s.recompute().is_empty(), "with its pillar, everything stands")
	s.remove(2)
	var falling := s.recompute()
	check(falling.has(3) and falling.has(4), "pillar gone: the floor and the wall on it fall (%s)" % [falling])
	check(not falling.has(1), "the foundation stays")
	# Two pillars: taking one away leaves the floor standing.
	var t := Structure.new()
	t.add(1, "foundation", "cut_stone", Vector3(0, 0, 0), 0, true)
	t.add(2, "foundation", "cut_stone", Vector3(2, 0, 0), 0, true)
	t.add(3, "pillar", "plank_root", Vector3(1, 1, 1), 0, false)
	t.add(4, "pillar", "plank_root", Vector3(3, 1, 1), 0, false)
	t.add(5, "floor", "plank_root", Vector3(2, 3, 2), 0, false)
	t.remove(3)
	check(t.recompute().is_empty(), "one pillar of two gone: the floor still stands on the other")
