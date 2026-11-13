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
var _materials := {}


func build(spots: Array[Dictionary]) -> void:
	_crystal_mesh = _make_crystal_mesh()
	_mushroom_mesh = _make_mushroom_mesh()
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
	var body := StaticBody3D.new()
	body.collision_layer = GLOW_LAYER
	body.collision_mask = 0
	body.set_meta("glow_id", s.id)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4 * s.scale
	shape.shape = sphere
	shape.position = Vector3.UP * 0.3 * s.scale
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	mi.mesh = _crystal_mesh if s.kind == GlowPlacer.CRYSTAL else _mushroom_mesh
	mi.material_override = _material_for(s.color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	add_child(body)
	var up: Vector3 = s.normal
	var side := up.cross(Vector3.FORWARD if absf(up.y) > 0.9 else Vector3.UP).normalized()
	var basis := Basis(side, up, side.cross(up)).orthonormalized()
	body.global_transform = Transform3D(basis.rotated(up, s.spin).scaled(Vector3.ONE * s.scale), s.pos - up * 0.1)
	_nodes[s.id] = body


func _material_for(c: Color) -> Material:
	var key := c.to_html()
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c.darkened(0.3)
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 2.2
		m.roughness = 0.25
		_materials[key] = m
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
	var near := _spots.values()
	near.sort_custom(func(a, b): return a.pos.distance_squared_to(from) < b.pos.distance_squared_to(from))
	for i in LIGHT_COUNT:
		var l := _lights[i]
		if i < near.size() and near[i].pos.distance_to(from) < 40.0:
			var s: Dictionary = near[i]
			l.global_position = s.pos + s.normal * 0.6
			l.light_color = s.color
			l.light_energy = 1.1 if s.kind == GlowPlacer.CRYSTAL else 0.7
		else:
			l.light_energy = 0.0


# ------------------------------------------------------------ simple low-poly meshes

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
	stem.radial_segments = 6
	stem.rings = 0
	stem.top_radius = 0.045
	stem.bottom_radius = 0.07
	stem.height = 0.4
	st.append_from(stem, 0, Transform3D(Basis(), Vector3.UP * 0.2))
	var cap := SphereMesh.new()
	cap.radial_segments = 8
	cap.rings = 3
	cap.radius = 0.24
	cap.height = 0.2
	cap.is_hemisphere = true
	st.append_from(cap, 0, Transform3D(Basis(), Vector3.UP * 0.38))
	var small := Transform3D(Basis().scaled(Vector3.ONE * 0.55), Vector3(0.22, 0.0, 0.1))
	st.append_from(stem, 0, small * Transform3D(Basis(), Vector3.UP * 0.2))
	st.append_from(cap, 0, small * Transform3D(Basis(), Vector3.UP * 0.38))
	st.generate_normals()
	return st.commit()
