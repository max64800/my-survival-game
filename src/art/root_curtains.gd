class_name RootCurtains
extends Node3D
## Root curtains (owner, Nov 17, F189): across some tunnel mouths, a curtain of thin roots hangs from the ceiling to
## a little above the floor. They sway in the cave air and swing aside as you walk through (hang_bend.gdshader).
## Only looks: no collision, nothing to network. Planned from the cave (same seed, same curtains), skipping ground kept
## clear for built things. Rock dug away under a strand's top takes the strand with it.

const SHARE := 0.18  ## about 1 in 6 tunnel mouths into a big cavern gets a curtain
const GAP := 0.26  ## metres between strands (in small bunches)
const CELL := 32.0

var walkers: Node3D  ## main's Players
var _mat: ShaderMaterial
var _cells := {}  ## Vector2i -> {mmi, tops: PackedVector3Array}


func build(maker: CaveMaker, world: World) -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://src/art/hang_bend.gdshader")
	var mesh := _strand_mesh()
	var items := plan(maker)
	var by_cell := {}
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
		for i in list.size():
			mm.set_instance_transform(i, list[i][0])
			mm.set_instance_color(i, list[i][1])
			tops.append((list[i][0] as Transform3D).origin)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = _mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 60.0
		mmi.visibility_range_end_margin = 6.0
		add_child(mmi)
		_cells[k] = {mmi = mmi, tops = tops}
	if world:
		world.changed.connect(_on_rock_changed)


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
				out.append([Transform3D(basis, top + Vector3.UP * 0.05), tint])  # (its top tucked into the rock)
	return out


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


## Rock dug away near a strand's top: the strand falls with it (it disappears).
func _on_rock_changed(center: Vector3, radius: float) -> void:
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
