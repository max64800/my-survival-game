class_name PoiField
extends Node3D
## Shows the special places the Cave Maker planned (world doc 3.1): ruins, camps, rune
## shrines, wall markings (boss clues), nests, the boss altar. Same on every computer.
## What you can DO at them goes through the GameAuthority (read a marking, take a rune).

const POI_LAYER := 16  ## aim + E, like stations

var maker: CaveMaker
var _nodes := {}  ## poi id -> Node3D
static var _mats := {}


func build(p_maker: CaveMaker) -> void:
	maker = p_maker
	for p in maker.pois:
		var n := _make(p)
		if n:
			add_child(n)
			n.global_position = p.pos
			_nodes[p.id] = n


static func poi_id_of(collider: Object) -> int:
	if collider is Node and collider.has_meta("poi_id"):
		return collider.get_meta("poi_id")
	return -1


## A shrine's rune was taken: dim its glow.
func set_taken(poi_id: int) -> void:
	var n: Node3D = _nodes.get(poi_id)
	if n and n.has_node("Rune"):
		n.get_node("Rune").visible = false


## A marking was read: make it glow brighter.
func set_read(poi_id: int) -> void:
	var n: Node3D = _nodes.get(poi_id)
	if n and n.has_node("Glyph"):
		var mi: MeshInstance3D = n.get_node("Glyph")
		mi.material_override = _mat(Color(1.0, 0.85, 0.4), 3.0)


func _make(p: Dictionary) -> Node3D:
	var root := StaticBody3D.new()
	root.collision_layer = 0
	root.collision_mask = 0
	match p.type:
		"marking":
			# A carved slab on the wall with a glowing glyph (the boss clue).
			root.collision_layer = POI_LAYER
			root.set_meta("poi_id", p.id)
			_shape(root, Vector3(2.4, 1.8, 0.5), Vector3(0, 1.2, 0))
			var slab := _part(root, _box(Vector3(2.4, 1.8, 0.25)), _mat(Color(0.5, 0.48, 0.45)), Vector3(0, 1.2, 0))
			slab.name = "Slab"
			var glyph := _part(root, _box(Vector3(1.6, 1.1, 0.05)), _mat(Color(0.4, 0.75, 1.0), 1.2), Vector3(0, 1.25, 0.14))
			glyph.name = "Glyph"
			root.look_at_from_position(Vector3.ZERO, -p.normal, Vector3.UP)
			_label(root, "Old carving · E to read", 2.6)
		"gate":
			# The plug of border rock between two biomes: a carved arch with a glowing seal.
			var arch_mat := _mat(Color(0.4, 0.36, 0.45))
			_part(root, _box(Vector3(0.6, 3.6, 0.6)), arch_mat, Vector3(-2.0, 1.2, 0.2))
			_part(root, _box(Vector3(0.6, 3.6, 0.6)), arch_mat, Vector3(2.0, 1.2, 0.2))
			_part(root, _box(Vector3(4.6, 0.6, 0.6)), arch_mat, Vector3(0, 3.0, 0.2))
			_part(root, _box(Vector3(1.4, 1.4, 0.06)), _mat(Color(0.65, 0.4, 1.0), 1.6), Vector3(0, 1.2, 0.05))
			root.look_at_from_position(Vector3.ZERO, -p.normal, Vector3.UP)
			_label(root, "Border rock · a Copper Pickaxe breaks it" if p.biome == "mossy" else "Border rock · the way back to Mossy Hollows", 3.6)
		"shrine":
			root.collision_layer = POI_LAYER
			root.set_meta("poi_id", p.id)
			_shape(root, Vector3(0.8, 1.2, 0.8), Vector3(0, 0.6, 0))
			_part(root, _cyl(0.35, 0.45, 0.9), _mat(Color(0.55, 0.52, 0.5)), Vector3(0, 0.45, 0))
			var rune := _part(root, _box(Vector3(0.25, 0.32, 0.08)), _mat(Color(0.95, 0.7, 0.3), 2.5), Vector3(0, 1.15, 0))
			rune.name = "Rune"
			rune.rotation.y = 0.6
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.75, 0.4)
			l.omni_range = 4.0
			l.light_energy = 0.8
			l.position = Vector3(0, 1.2, 0)
			rune.add_child(l)
			_label(root, "Rune shrine · E", 1.8)
		"ruin":
			# An old dwarf hall, fallen in (F9/F21): a ring of carved columns (most broken),
			# stretches of block wall with gaps, and a doorway of two columns.
			var rng := _rng_for(p)
			for i in 6:
				var a := i * TAU / 6.0 + 0.4
				var at := _on_floor(p, Vector3(cos(a), 0, sin(a)) * 4.6)
				RuinKit.column(root, at, rng.randf_range(3.6, 4.6), 0.7, 0.0 if rng.randf() < 0.3 else rng.randf_range(0.2, 0.75), rng)
			RuinKit.broken_wall(root, _on_floor(p, Vector3(-2.5, 0, -3.6)), _on_floor(p, Vector3(2.5, 0, -3.6)), 3, rng)
			RuinKit.broken_wall(root, _on_floor(p, Vector3(-3.8, 0, 1.0)), _on_floor(p, Vector3(-3.8, 0, -2.2)), 2, rng)
		"colonnade":
			# A row of great columns standing in a cavern, some broken (F9/F21).
			var rng := _rng_for(p)
			var count := rng.randi_range(3, 5)
			var along := Vector3(cos(p.get("yaw", 0.0)), 0, sin(p.get("yaw", 0.0)))
			for i in count:
				var off: Vector3 = along * (float(i) - (count - 1) * 0.5) * 3.8
				var whole := rng.randf() < 0.4
				RuinKit.column(root, _on_floor(p, off), rng.randf_range(5.0, 7.0), 0.95, 0.0 if whole else rng.randf_range(0.15, 0.7), rng)
		"camp":
			_part(root, _box(Vector3(0.9, 0.12, 1.9)), _mat(Color(0.45, 0.3, 0.25)), Vector3(1.2, 0.06, 0))  # bedroll
			for i in 6:
				var a := i * TAU / 6.0
				_part(root, _sphere(0.15), _mat(Color(0.35, 0.33, 0.3)), Vector3(cos(a), 0.08, sin(a)) * 0.4 + Vector3(-0.8, 0, 0))
			_part(root, _box(Vector3(0.5, 0.05, 0.3)), _mat(Color(0.12, 0.1, 0.08)), Vector3(-0.8, 0.03, 0))  # ashes
		"nest":
			for i in 7:
				var a := i * TAU / 7.0
				_part(root, _sphere(0.3), _mat(Color(0.75, 0.72, 0.55)), Vector3(cos(a), 0.2, sin(a)) * 1.2)  # eggs
			_part(root, _cyl(1.8, 2.2, 0.4), _mat(Color(0.35, 0.28, 0.18)), Vector3(0, 0.1, 0))
		"lair":
			# The summoning altar in the middle of the sealed hall. E with an offering re-summons a beaten boss.
			root.collision_layer = POI_LAYER
			root.set_meta("poi_id", p.id)
			_shape(root, Vector3(3.6, 1.6, 3.6), Vector3(0, 0.8, 0))
			_label(root, "Summoning altar · E", 2.4)
			_part(root, _cyl(1.6, 2.0, 1.0), _mat(Color(0.4, 0.42, 0.4)), Vector3(0, 0.5, 0))
			_part(root, _sphere(0.5), _mat(Color(0.3, 1.0, 0.7), 2.0), Vector3(0, 1.4, 0))
			var lrng := _rng_for(p)
			for i in 4:
				var a := i * TAU / 4.0 + PI / 4.0
				RuinKit.column(root, _on_floor(p, Vector3(cos(a), 0, sin(a)) * 9.0), 9.0, 1.3, 0.0, lrng, Color(0.5, 0.5, 0.48))
		"great_hall":
			var grng := _rng_for(p)
			for i in 8:
				var a := i * TAU / 8.0
				RuinKit.column(root, _on_floor(p, Vector3(cos(a), 0, sin(a)) * 10.0), 6.5, 1.1, 0.0 if i % 3 != 2 else grng.randf_range(0.3, 0.7), grng, Color(0.8, 0.78, 0.74))
		_:
			return null
	return root


## Same dice for the same place on every computer (co-op friends see the same broken columns).
static func _rng_for(p: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i((p.pos as Vector3).round())) + int(p.get("id", 0))
	return rng


## A spot `offset` away from the place's center, dropped onto the floor there (local to the place).
func _on_floor(p: Dictionary, offset: Vector3) -> Vector3:
	var c: Vector3 = p.pos
	var f := maker.find_floor(c.x + offset.x, c.z + offset.z, c.y + 1.5)
	return Vector3(offset.x, f.y - c.y, offset.z)


func _label(parent: Node3D, text: String, y: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3.UP * y
	l.pixel_size = 0.004
	l.font_size = 32
	l.outline_size = 8
	l.visibility_range_begin = 1.5
	l.visibility_range_end = 14.0
	parent.add_child(l)


func _shape(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _mat(c: Color, glow: float = 0.0) -> Material:
	var key := [c, glow]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		if glow > 0.0:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = glow
		_mats[key] = m
	return _mats[key]


static func _box(s: Vector3) -> Mesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 8
	return c


static func _sphere(r: float) -> Mesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	return s
