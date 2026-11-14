class_name Fx
## Little visual effects: rock bits flying when you dig, plus a puff of dust.
## The chunks are lumpy, painted little rocks (Look.mat) that tumble and fall; bright colours
## (crystals, sparks off rock that's too hard) glow instead. Only looks: nothing to sync.

static var _chunk_mesh: Mesh
static var _dust_tex: Texture2D
static var _chunk_mats := {}


static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 10, speed: float = 3.0) -> void:
	var glowing := color.v > 0.85 and color.s < 0.6 or color.v > 0.95
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.9 if not glowing else 0.45
	p.explosiveness = 0.95
	p.randomness = 0.5
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -14, 0)
	p.damping_min = 0.5
	p.damping_max = 1.5
	# Tumbling, different sizes.
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = 0.35 if not glowing else 0.2
	p.scale_amount_max = 1.1 if not glowing else 0.5
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(0.75, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = shrink
	p.mesh = _chunk()
	p.material_override = _chunk_mat(color, glowing)
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	if not glowing and amount >= 6:
		dust(parent, pos, color.lerp(Color(0.55, 0.5, 0.45), 0.5), clampi(amount / 3, 3, 10))


## A soft puff of dust that drifts up and fades (digging, landing, things breaking).
static func dust(parent: Node, pos: Vector3, color: Color, amount: int = 5, size: float = 0.45) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 1.4
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, 0.15, 0)
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.45))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = fade
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = color
	m.albedo_texture = _dust()
	m.roughness = 1.0
	m.disable_receive_shadows = true
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func material_color(mat: int) -> Color:
	match mat:
		Mat.MOSS: return Color(0.3, 0.5, 0.2)
		Mat.DIRT: return Color(0.4, 0.28, 0.18)
		Mat.COPPER: return Color(0.9, 0.55, 0.25)
		Mat.BORDER, Mat.EDGE: return Color(0.6, 0.4, 1.0)
		Mat.CLAY: return Color(0.8, 0.45, 0.25)
	return Color(0.5, 0.48, 0.45)


## A small lumpy rock (a squashed low-poly ball).
static func _chunk() -> Mesh:
	if _chunk_mesh == null:
		var s := SphereMesh.new()
		s.radius = 0.045
		s.height = 0.07
		s.radial_segments = 5
		s.rings = 3
		_chunk_mesh = s
	return _chunk_mesh


static func _chunk_mat(color: Color, glowing: bool) -> Material:
	var key := color.to_html() + str(glowing)
	if not _chunk_mats.has(key):
		if glowing:
			var m := StandardMaterial3D.new()
			m.albedo_color = color
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = 3.0
			_chunk_mats[key] = m
		else:
			_chunk_mats[key] = Look.mat(color, "stone", 0.0, 0.012)
	return _chunk_mats[key]


## A soft round blob for dust (made once in code: bright middle, see-through edge).
static func _dust() -> Texture2D:
	if _dust_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 64
		t.height = 64
		_dust_tex = t
	return _dust_tex
