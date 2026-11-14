class_name GlowField
extends Node3D
## Shows the glowing crystals and mushrooms that the Glow Placer picked.
## Real lights are expensive, so only the LIGHT_COUNT spots nearest the player get
## a real light; all the others just glow (shiny material + bloom).

const GLOW_LAYER := 2
const LIGHT_COUNT := 12
const LIGHT_UPDATE := 0.3

var _spots: Dictionary = {}  ## id -> spot data
var _nodes: Dictionary = {}  ## id -> StaticBody3D
var _lights: Array[OmniLight3D] = []
var _light_timer := 0.0
var _crystal_mesh: Mesh
var _mushroom_mesh: Mesh
var _fiber_mesh: Mesh
var _root_mesh: Mesh
var _materials := {}


func build(spots: Array[Dictionary]) -> void:
	_crystal_mesh = _make_crystal_mesh()
	_mushroom_mesh = _make_mushroom_mesh()
	_fiber_mesh = _make_fiber_mesh()
	_root_mesh = _make_root_mesh()
	for s in spots:
		_spots[s.id] = s
		_add_node(s)
	for i in LIGHT_COUNT:
		var l := OmniLight3D.new()
		l.shadow_enabled = false
		l.omni_range = 6.0
		l.light_energy = 0.0
		add_child(l)
		_lights.append(l)


func get_spot(id: int) -> Dictionary:
	return _spots.get(id, {})


func spot_count() -> int:
	return _spots.size()


func spots_near(p: Vector3, radius: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in _spots.values():
		if s.pos.distance_to(p) <= radius:
			out.append(s)
	return out


## A root was chopped: remember how many chops it has left.
func set_chops(id: int, left: int) -> void:
	if _spots.has(id):
		_spots[id].chops = left
		var n: Node3D = _nodes.get(id)
		if n:
			n.scale = n.scale * Vector3(0.85, 1.0, 0.85)  # a bit thinner after each chop


func remove_spot(id: int) -> void:
	_spots.erase(id)
	var n: Node = _nodes.get(id)
	_nodes.erase(id)
	if n:
		n.queue_free()
	_light_timer = 0.0


## Glow-spot id for a physics collider, or -1.
func id_of(collider: Object) -> int:
	if collider is Node and collider.has_meta("glow_id"):
		return collider.get_meta("glow_id")
	return -1


func _add_node(s: Dictionary) -> void:
	if s.kind == GlowPlacer.DRIP:
		_add_drip(s)
		return
	var body := StaticBody3D.new()
	body.collision_layer = GLOW_LAYER
	body.collision_mask = 0
	body.set_meta("glow_id", s.id)
	var shape := CollisionShape3D.new()
	var is_root: bool = s.kind in GlowPlacer.TALL
	if is_root:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.35 if s.kind == GlowPlacer.ROOT else 0.45
		cap.height = maxf(s.length, 0.8)
		shape.shape = cap
		shape.position = Vector3.UP * s.length * 0.5
	else:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.4 * s.scale
		shape.shape = sphere
		shape.position = Vector3.UP * 0.3 * s.scale
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	match s.kind:
		"crystal", "crystal_green", "crystal_amber": mi.mesh = _crystal_mesh
		"fiber": mi.mesh = _fiber_mesh
		"root":
			mi.mesh = _root_mesh
			mi.scale = Vector3(1, s.length, 1) / s.scale  # stretch to reach toward the floor
		GlowPlacer.GIANT: mi.mesh = _giant_mesh(s.length)
		_: mi.mesh = _mushroom_mesh
	mi.material_override = _material_for(s.color, GlowPlacer.KINDS[s.kind].get("glow", false), _surface_of(s.kind))
	if s.kind == GlowPlacer.GIANT:
		mi.material_override = null  # the giant mushroom mesh brings its own stalk + cap colors
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	add_child(body)
	var up: Vector3 = s.normal
	var side := up.cross(Vector3.FORWARD if absf(up.y) > 0.9 else Vector3.UP).normalized()
	var basis := Basis(side, up, side.cross(up)).orthonormalized()
	body.global_transform = Transform3D(basis.rotated(up, s.spin).scaled(Vector3.ONE * s.scale), s.pos - up * 0.1)
	_nodes[s.id] = body


## A little wet stalactite with drops falling from its tip (not something you can hit).
func _add_drip(s: Dictionary) -> void:
	var root := Node3D.new()
	add_child(root)
	root.global_position = s.pos
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.18
	cone.bottom_radius = 0.0
	cone.height = 0.6
	cone.radial_segments = 6
	tip.mesh = cone
	tip.material_override = _material_for(Color(0.5, 0.55, 0.62), false)
	tip.position = Vector3.DOWN * 0.3
	root.add_child(tip)
	var drops := CPUParticles3D.new()
	drops.amount = 3
	drops.lifetime = 1.6
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	drops.direction = Vector3.DOWN
	drops.spread = 0.0
	drops.initial_velocity_min = 0.0
	drops.initial_velocity_max = 0.2
	drops.gravity = Vector3(0, -6.0, 0)
	var dm := SphereMesh.new()
	dm.radius = 0.03
	dm.height = 0.08
	dm.radial_segments = 4
	dm.rings = 2
	drops.mesh = dm
	drops.material_override = _material_for(s.color, true)
	drops.position = Vector3.DOWN * 0.6
	root.add_child(drops)
	_nodes[s.id] = root


## Which painted grain each kind of plant/crystal gets (see Look.SURFACES).
func _surface_of(kind: String) -> String:
	if kind == "root":
		return "bark"
	if kind.begins_with("crystal"):
		return "smooth"
	return "fungus"


func _material_for(c: Color, glows: bool = true, surface: String = "") -> Material:
	var key := c.to_html() + str(glows) + surface
	if not _materials.has(key):
		if surface == "":
			surface = "smooth" if glows else "fungus"
		# Glowing things shine; the rest get a faint glow so they're findable in the dark.
		# Crystals stay sharp; mushrooms and roots get a little lumpy.
		var wobble := 0.0 if surface == "smooth" else 0.025
		_materials[key] = Look.mat(c.darkened(0.3) if glows else c, surface,
			2.2 if glows else (0.12 if surface == "bark" else 0.35), wobble, c)
	return _materials[key]


func _process(delta: float) -> void:
	_light_timer -= delta
	if _light_timer > 0.0:
		return
	_light_timer = LIGHT_UPDATE
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	var near := _spots.values().filter(func(s): return GlowPlacer.KINDS[s.kind].get("glow", false))
	near.sort_custom(func(a, b): return a.pos.distance_squared_to(from) < b.pos.distance_squared_to(from))
	for i in LIGHT_COUNT:
		var l := _lights[i]
		if i < near.size() and near[i].pos.distance_to(from) < 40.0:
			var s: Dictionary = near[i]
			l.global_position = s.pos + s.normal * 0.6
			l.light_color = s.color
			l.light_energy = 1.1 if s.kind.begins_with("crystal") else 0.7
		else:
			l.light_energy = 0.0


# ------------------------------------------------------------ simple low-poly meshes

var _giants := {}  ## height (half meters) -> mesh


## A giant mushroom `h` meters tall: a pale stalk and a wide glowing-rimmed cap.
func _giant_mesh(h: float) -> Mesh:
	var key := int(round(h * 2.0))
	if _giants.has(key):
		return _giants[key]
	h = key * 0.5
	var mesh := ArrayMesh.new()
	var stalk := CylinderMesh.new()
	stalk.radial_segments = 12
	stalk.rings = 6
	stalk.top_radius = 0.22
	stalk.bottom_radius = 0.38
	stalk.height = h
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(stalk, 0, Transform3D(Basis(), Vector3.UP * h * 0.5))
	st.generate_normals()
	st.commit(mesh)
	mesh.surface_set_material(0, Look.mat(Color(0.82, 0.77, 0.68), "fungus", 0.1, 0.07))
	var cap := SphereMesh.new()
	cap.radial_segments = 20
	cap.rings = 7
	cap.radius = 0.9 + h * 0.18
	cap.height = 0.7 + h * 0.08
	cap.is_hemisphere = true
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	st2.append_from(cap, 0, Transform3D(Basis(), Vector3.UP * (h - 0.15)))
	st2.generate_normals()
	st2.commit(mesh)
	# A wavy, lumpy cap with a soft purple glow.
	mesh.surface_set_material(1, Look.mat(Color(0.48, 0.28, 0.56), "fungus", 0.45, 0.16, Color(0.72, 0.4, 0.9)))
	_giants[key] = mesh
	return mesh

func _make_crystal_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shards := [[0.0, 0.0, 0.0, 0.75], [0.7, 0.25, 0.4, 0.5], [2.4, -0.2, 0.5, 0.45], [4.2, 0.15, -0.45, 0.55]]
	for sh in shards:
		var c := CylinderMesh.new()
		c.radial_segments = 6
		c.rings = 0
		c.top_radius = 0.015
		c.bottom_radius = 0.1
		c.height = sh[3]
		var t := Transform3D(Basis(Vector3.UP, sh[0]) * Basis(Vector3.RIGHT, sh[1]) * Basis(Vector3.FORWARD, sh[2]), Vector3.ZERO)
		t.origin = t.basis.y * sh[3] * 0.5
		st.append_from(c, 0, t)
	st.generate_normals()
	return st.commit()


func _make_mushroom_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.radial_segments = 7
	stem.rings = 2
	stem.top_radius = 0.045
	stem.bottom_radius = 0.07
	stem.height = 0.4
	st.append_from(stem, 0, Transform3D(Basis(), Vector3.UP * 0.2))
	var cap := SphereMesh.new()
	cap.radial_segments = 11
	cap.rings = 4
	cap.radius = 0.24
	cap.height = 0.2
	cap.is_hemisphere = true
	st.append_from(cap, 0, Transform3D(Basis(), Vector3.UP * 0.38))
	var small := Transform3D(Basis().scaled(Vector3.ONE * 0.55), Vector3(0.22, 0.0, 0.1))
	st.append_from(stem, 0, small * Transform3D(Basis(), Vector3.UP * 0.2))
	st.append_from(cap, 0, small * Transform3D(Basis(), Vector3.UP * 0.38))
	st.generate_normals()
	return st.commit()


func _make_fiber_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var blade := CylinderMesh.new()
		blade.radial_segments = 3
		blade.rings = 0
		blade.top_radius = 0.0
		blade.bottom_radius = 0.025
		blade.height = 0.35 + 0.05 * (i % 3)
		var a := i * 0.9
		var t := Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.35), Vector3(cos(a), 0, sin(a)) * 0.08)
		t.origin += t.basis.y * blade.height * 0.5
		st.append_from(blade, 0, t)
	st.generate_normals()
	return st.commit()


## A root 1 m long (stretched to fit), thick at the ceiling and thin at the tip,
## with a few twists so it looks organic.
func _make_root_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var main := CylinderMesh.new()
	main.radial_segments = 7
	main.rings = 4
	main.top_radius = 0.06
	main.bottom_radius = 0.28
	main.height = 1.0
	st.append_from(main, 0, Transform3D(Basis(), Vector3.UP * 0.5))
	for i in 3:
		var side := CylinderMesh.new()
		side.radial_segments = 5
		side.rings = 1
		side.top_radius = 0.02
		side.bottom_radius = 0.1
		side.height = 0.45
		var a := i * 2.1
		var t := Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.7), Vector3(cos(a), 0, sin(a)) * 0.15 + Vector3.UP * (0.15 + 0.2 * i))
		t.origin += t.basis.y * 0.2
		st.append_from(side, 0, t)
	st.generate_normals()
	return st.commit()
