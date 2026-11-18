class_name RootCurtains
extends Node3D
## Root curtains (owner, Nov 17, F189): across some tunnel mouths, a curtain of thin roots hangs from the ceiling to
## a little above the floor. They sway in the cave air and swing aside as you walk through (hang_bend.gdshader).
## Only looks: no collision, nothing to network. Planned from the cave (same seed, same curtains), skipping ground kept
## clear for built things. Rock dug away under a strand's top takes the strand with it.

const SHARE := 0.7  ## 7 in 10 tunnel mouths into a big cavern get a curtain (owner: "a lot more of them")
const GAP := 0.26  ## metres between strands (in small bunches)
const CELL := 32.0

var walkers: Node3D  ## main's Players
var _mat: ShaderMaterial
var _cells := {}  ## Vector2i -> {mmi, tops, bots: PackedVector3Array, ids: PackedInt32Array (index in plan())}
var _where := {}  ## strand id -> [cell key, index in that cell]
## Every curtain glows (owner, Nov 17, round 2: "all of the vines should be glowing... from green to gray to white to
## bluish, very light colours, like the green"): pale green, grey, white, light blue, pale teal.
## Round 3 (owner, Nov 18: "I only see white and sometimes green, make new colours"): no white or grey any more.
const GLOW_TINTS := [Color(0.35, 1.0, 0.5), Color(0.55, 1.0, 0.8), Color(0.5, 0.75, 1.0), Color(0.75, 0.58, 1.0),
	Color(1.0, 0.58, 0.85), Color(1.0, 0.82, 0.42), Color(0.38, 0.95, 0.95)]


var _thread: Thread
var _built := false
var _pending_hide := PackedInt32Array()  ## broken before the curtains were ready (a saved game loading)


## Worked out on a helper thread (~6000 strands take seconds), made into meshes when done. `blocking` = all at once.
func build(maker: CaveMaker, world: World, blocking := false) -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://src/art/hang_bend.gdshader")
	if world:
		world.changed.connect(_on_rock_changed)
	if blocking:
		_finish(plan(maker))
		return
	_thread = Thread.new()
	_thread.start(func() -> void:
		var items := plan(maker)
		_finish.call_deferred(items))


func is_built() -> bool:
	return _built


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


func _finish(items: Array) -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	var mesh := _strand_mesh()
	var by_cell := {}
	for n in items.size():
		items[n].append(n)  # its id
	for it in items:
		var o: Vector3 = (it[0] as Transform3D).origin
		var k := Vector2i(floori(o.x / CELL), floori(o.z / CELL))
		if not by_cell.has(k):
			by_cell[k] = []
		by_cell[k].append(it)
	for k in by_cell:
		var list: Array = by_cell[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = list.size()
		var tops := PackedVector3Array()
		var bots := PackedVector3Array()
		var ids := PackedInt32Array()
		for i in list.size():
			var xf: Transform3D = list[i][0]
			mm.set_instance_transform(i, xf)
			mm.set_instance_color(i, list[i][1])
			tops.append(xf.origin)
			bots.append(xf.origin - xf.basis.y)
			ids.append(list[i][2])
			_where[list[i][2]] = [k, i]
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = _mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 60.0
		mmi.visibility_range_end_margin = 6.0
		add_child(mmi)
		_cells[k] = {mmi = mmi, tops = tops, bots = bots, ids = ids}
	_built = true
	if not _pending_hide.is_empty():
		hide_strands(_pending_hide)
		_pending_hide.clear()


## Every strand: [Transform3D (origin = its top, -Y down, Y scale = its length), colour]. Same cave, same curtains.
static func plan(maker: CaveMaker) -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9300
	for sg: Dictionary in maker.segments:
		for e: Vector3 in [sg.a, sg.b]:
			var roll := rng.randf()
			if roll > SHARE:
				continue
			var room := _big_room_at(maker, e)
			if room.is_empty():
				continue
			var other: Vector3 = sg.b if e == sg.a else sg.a
			var along := Vector3(other.x - e.x, 0.0, other.z - e.z)
			if along.length() < 0.5:
				continue
			along = along.normalized()
			var side := along.cross(Vector3.UP).normalized()
			var mouth := e + along * 1.2  # a little way into the tunnel, where it's narrow
			var curtain_tint := rng.randi_range(0, GLOW_TINTS.size() - 1)
			var half := float(sg.r) * 0.85
			var x := -half
			while x <= half:
				var base := mouth + side * x + along * rng.randf_range(-0.2, 0.2)
				x += GAP * (rng.randf_range(0.25, 0.5) if rng.randf() < 0.6 else rng.randf_range(1.2, 2.2))  # bunches
				if maker.sdf_at(base) <= 0.2:
					continue
				var top := GlowPlacer._march(maker, base, Vector3.UP, 5.0)
				var fl := GlowPlacer._march(maker, base, Vector3.DOWN, 5.0)
				if top == Vector3.INF or fl == Vector3.INF or maker.is_reserved(top, 1.0):
					continue
				var length := ((top.y - fl.y) - rng.randf_range(0.5, 1.1)) * rng.randf_range(0.45, 1.0)  # a ragged edge
				if length < 0.6:
					continue
				var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(rng.randf_range(0.8, 1.4), length, rng.randf_range(0.8, 1.4)))
				var tint := Color(0.2, 0.13, 0.08).lerp(Color(0.34, 0.24, 0.15), rng.randf())  # dark, old roots
				if CaveMaker.biome_at(top) == "fungal":
					tint = tint.lerp(Color(0.45, 0.3, 0.5), 0.35)
				# each curtain its own light colour, each strand a little different (a few strands a neighbouring colour)
				var tc: Color = GLOW_TINTS[curtain_tint if rng.randf() < 0.8 else rng.randi_range(0, GLOW_TINTS.size() - 1)]
				tint = tc.darkened(rng.randf_range(0.15, 0.4))
				tint.a = 0.35  # (alpha below 1 = how much it glows, see hang_bend.gdshader)
				out.append([Transform3D(basis, top + Vector3.UP * 0.05), tint])  # (its top tucked into the rock)
	_plan_tunnels(maker, rng, out)
	_plan_under_bridges(maker, rng, out)
	return out


## Curtains in the middle of some tunnels too (owner, Nov 17: "a lot more of them, throughout the caves").
static func _plan_tunnels(maker: CaveMaker, rng: RandomNumberGenerator, out: Array) -> void:
	for sg: Dictionary in maker.segments:
		if rng.randf() > 0.07 or float(sg.r) < 1.2:
			continue
		var along := Vector3(sg.b.x - sg.a.x, 0.0, sg.b.z - sg.a.z)
		if along.length() < 3.0:
			continue
		along = along.normalized()
		var mid: Vector3 = (sg.a as Vector3).lerp(sg.b, rng.randf_range(0.3, 0.7))
		_curtain_across(maker, rng, out, mid, along.cross(Vector3.UP).normalized(), float(sg.r) * 0.85, along)


## Lots of long strands under every rock bridge (owner: "we can do a lot of hanging vines under those bridges").
static func _plan_under_bridges(maker: CaveMaker, rng: RandomNumberGenerator, out: Array) -> void:
	for br: Dictionary in maker._bridges:
		var a: Vector3 = br.a
		var b: Vector3 = br.b
		var along := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		var side := along.cross(Vector3.UP).normalized()
		var tint := rng.randi_range(0, GLOW_TINTS.size() - 1)
		var f := 0.12
		while f < 0.88:
			f += rng.randf_range(0.02, 0.07) if rng.randf() < 0.7 else rng.randf_range(0.1, 0.2)  # in bunches
			var at := a.lerp(b, f) + side * rng.randf_range(-0.45, 0.45) * float(br.w)
			var under := at - Vector3.UP * (float(br.t) + 0.6)
			if maker.sdf_at(under) <= 0.2:
				continue
			var top := GlowPlacer._march(maker, under, Vector3.UP, 3.0)  # the bridge's underside
			var fl := GlowPlacer._march(maker, under, Vector3.DOWN, 30.0)
			if top == Vector3.INF or fl == Vector3.INF or maker.is_reserved(top, 1.0):
				continue
			var length := minf(rng.randf_range(1.2, 4.5), (top.y - fl.y) - 1.0)
			if length < 0.6:
				continue
			_add_strand(rng, out, top, length, tint)


## One curtain straight across at `mid`, `half` metres each way along `side`.
static func _curtain_across(maker: CaveMaker, rng: RandomNumberGenerator, out: Array, mid: Vector3, side: Vector3, half: float, along: Vector3) -> void:
	var tint := rng.randi_range(0, GLOW_TINTS.size() - 1)
	var x := -half
	while x <= half:
		var base := mid + side * x + along * rng.randf_range(-0.2, 0.2)
		x += GAP * (rng.randf_range(0.25, 0.5) if rng.randf() < 0.6 else rng.randf_range(1.2, 2.2))
		if maker.sdf_at(base) <= 0.2:
			continue
		var top := GlowPlacer._march(maker, base, Vector3.UP, 5.0)
		var fl := GlowPlacer._march(maker, base, Vector3.DOWN, 5.0)
		if top == Vector3.INF or fl == Vector3.INF or maker.is_reserved(top, 1.0):
			continue
		var length := ((top.y - fl.y) - rng.randf_range(0.5, 1.1)) * rng.randf_range(0.45, 1.0)
		if length < 0.6:
			continue
		_add_strand(rng, out, top, length, tint)


static func _add_strand(rng: RandomNumberGenerator, out: Array, top: Vector3, length: float, tint_i: int) -> void:
	var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(rng.randf_range(0.8, 1.4), length, rng.randf_range(0.8, 1.4)))
	var tc: Color = GLOW_TINTS[tint_i if rng.randf() < 0.8 else rng.randi_range(0, GLOW_TINTS.size() - 1)]
	var tint := tc.darkened(rng.randf_range(0.15, 0.4))
	tint.a = 0.35
	out.append([Transform3D(basis, top + Vector3.UP * 0.05), tint])


## The big room whose wall this tunnel end sits on, or {}.
static func _big_room_at(maker: CaveMaker, e: Vector3) -> Dictionary:
	for room: Dictionary in maker.rooms:
		if not room.big:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var rel := Vector2((e.x - c.x) / r.x, (e.z - c.z) / r.z).length()
		if rel > 0.85 and rel < 1.15 and absf(e.y - c.y) < r.y * 1.2:
			return room
	return {}


## One strand, 1 m long down -Y from its top: a thin wobbly root, tapering, with two little side rootlets.
static func _strand_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, Vector3.ZERO, Vector3(0.04, -1.0, -0.03), 0.04, 0.007, 14, 0.07)
	_tube(st, Vector3(0.01, -0.25, 0.0), Vector3(0.16, -0.5, 0.06), 0.016, 0.004, 5, 0.02)
	_tube(st, Vector3(-0.005, -0.5, 0.0), Vector3(-0.14, -0.74, -0.05), 0.013, 0.003, 5, 0.02)
	_tube(st, Vector3(0.02, -0.72, -0.01), Vector3(0.09, -0.9, 0.08), 0.009, 0.002, 4, 0.015)
	st.generate_normals()
	return st.commit()


static func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, rings: int, wob: float) -> void:
	const SIDES := 5
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.FORWARD if absf(axis.z) < 0.9 else Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	var ring_pts: Array = []
	for i in rings + 1:
		var t := float(i) / rings
		var c := a.lerp(b, t) + (u * sin(t * 9.0) + v * cos(t * 7.0)) * wob * t
		var r := lerpf(r0, r1, t)
		var pts := []
		for k in SIDES:
			var ang := TAU * k / SIDES
			pts.append(c + (u * cos(ang) + v * sin(ang)) * r)
		ring_pts.append(pts)
	for i in rings:
		for k in SIDES:
			var p0: Vector3 = ring_pts[i][k]
			var p1: Vector3 = ring_pts[i][(k + 1) % SIDES]
			var p2: Vector3 = ring_pts[i + 1][k]
			var p3: Vector3 = ring_pts[i + 1][(k + 1) % SIDES]
			for p in [p0, p2, p1, p1, p2, p3]:
				st.set_color(Color.WHITE)  # (needed so each strand's own colour can tint it)
				st.add_vertex(p)


func _process(_delta: float) -> void:
	if _mat == null or walkers == null:
		return
	var feet: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
	var i := 0
	for d in walkers.get_children():
		if d is Node3D and i < 4:
			var p := (d as Node3D).global_position
			feet[i] = Vector4(p.x, p.y, p.z, 1.0)
			i += 1
	_mat.set_shader_parameter("pushers", feet)


## The strand closest to the line from `from` to `to` (within `near` metres), or -1. For a swing: the roots have no
## solid shape (thousands of them would slow the game), so the swing's aim line finds them.
func strand_near_ray(from: Vector3, to: Vector3, near := 0.35) -> int:
	var best := -1
	var best_d := near
	var lo := Vector2i(floori(minf(from.x, to.x) / CELL), floori(minf(from.z, to.z) / CELL))
	var hi := Vector2i(floori(maxf(from.x, to.x) / CELL), floori(maxf(from.z, to.z) / CELL))
	for x in range(lo.x, hi.x + 1):
		for z in range(lo.y, hi.y + 1):
			var cell: Dictionary = _cells.get(Vector2i(x, z), {})
			if cell.is_empty():
				continue
			var tops: PackedVector3Array = cell.tops
			var bots: PackedVector3Array = cell.bots
			for i in tops.size():
				if tops[i] == Vector3.INF:
					continue
				var pts := Geometry3D.get_closest_points_between_segments(from, to, tops[i], bots[i])
				var d := (pts[0] as Vector3).distance_to(pts[1])
				if d < best_d:
					best_d = d
					best = cell.ids[i]
	return best


## The strands within `radius` of strand `id` (a bunch breaks together), still there.
func bunch_of(id: int, radius := 0.45) -> PackedInt32Array:
	var out := PackedInt32Array()
	if not _where.has(id):
		return out
	var cell: Dictionary = _cells[_where[id][0]]
	var at: Vector3 = cell.tops[_where[id][1]]
	if at == Vector3.INF:
		return out
	for i in (cell.tops as PackedVector3Array).size():
		if cell.tops[i] != Vector3.INF and Vector2(cell.tops[i].x - at.x, cell.tops[i].z - at.z).length() < radius:
			out.append(cell.ids[i])
	return out


func top_of(id: int) -> Vector3:
	if not _where.has(id):
		return Vector3.INF
	return _cells[_where[id][0]].tops[_where[id][1]]


## Broken (by anyone): these strands are gone.
func hide_strands(ids: PackedInt32Array) -> void:
	if not _built:
		_pending_hide.append_array(ids)
		return
	for id in ids:
		if not _where.has(id):
			continue
		var cell: Dictionary = _cells[_where[id][0]]
		var i: int = _where[id][1]
		var mm: MultiMesh = (cell.mmi as MultiMeshInstance3D).multimesh
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), cell.tops[i]))
		cell.tops[i] = Vector3.INF


## Rock dug away near a strand's top: the strand falls with it (it disappears).
func _on_rock_changed(center: Vector3, radius: float) -> void:
	if not _built:
		return  # (digs during loading: the ruined tower's ground is kept clear of curtains anyway)
	var r2 := (radius + 0.6) * (radius + 0.6)
	var k0 := Vector2i(floori((center.x - radius) / CELL), floori((center.z - radius) / CELL))
	var k1 := Vector2i(floori((center.x + radius) / CELL), floori((center.z + radius) / CELL))
	for x in range(k0.x, k1.x + 1):
		for z in range(k0.y, k1.y + 1):
			var cell: Dictionary = _cells.get(Vector2i(x, z), {})
			if cell.is_empty():
				continue
			var tops: PackedVector3Array = cell.tops
			var mm: MultiMesh = (cell.mmi as MultiMeshInstance3D).multimesh
			for i in tops.size():
				if tops[i].distance_squared_to(center) < r2:
					mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), tops[i]))
					tops[i] = Vector3.INF
			cell.tops = tops
