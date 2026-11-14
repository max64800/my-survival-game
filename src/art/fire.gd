class_name Fire
extends Node3D
## A real-looking little fire made of particles: soft flame tongues, sparks (embers) drifting up,
## and a thin wisp of smoke. Used by the campfire and the smelters. Only looks (no gameplay).
## `size` 1.0 = campfire; smaller for a furnace mouth.

var size := 1.0
var smoke := true

static var _soft: Texture2D


func _init(p_size: float = 1.0, p_smoke: bool = true) -> void:
	size = p_size
	smoke = p_smoke


func _ready() -> void:
	_flames()
	_embers()
	if smoke:
		_smoke()


func _flames() -> void:
	var p := _emitter(14, 0.55)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.16 * size
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.5 * size
	pm.initial_velocity_max = 1.0 * size
	pm.gravity = Vector3(0, 0.8 * size, 0)
	pm.scale_min = 0.7
	pm.scale_max = 1.2
	pm.scale_curve = _curve([Vector2(0, 0.6), Vector2(0.3, 1.0), Vector2(1, 0.1)])
	pm.color_ramp = _ramp([Color(1.0, 0.7, 0.25, 0.5), Color(1.0, 0.35, 0.05, 0.4), Color(0.5, 0.08, 0.02, 0.0)])
	pm.angle_min = -30.0
	pm.angle_max = 30.0
	p.draw_pass_1 = _quad(0.3 * size, Color(1, 1, 1), true)


func _embers() -> void:
	var p := _emitter(14, 1.8)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.2 * size
	pm.direction = Vector3.UP
	pm.spread = 25.0
	pm.initial_velocity_min = 0.8 * size
	pm.initial_velocity_max = 1.8 * size
	pm.gravity = Vector3(0, 0.3, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.5
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.15
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	pm.color_ramp = _ramp([Color(1.0, 0.8, 0.4, 1), Color(1.0, 0.4, 0.1, 1), Color(0.6, 0.1, 0.0, 0)])
	p.draw_pass_1 = _quad(0.018 * size, Color(1, 0.6, 0.3), true)


func _smoke() -> void:
	var p := _emitter(10, 3.5)
	p.position = Vector3.UP * 0.35 * size
	var pm := p.process_material as ParticleProcessMaterial
	pm.direction = Vector3.UP
	pm.spread = 10.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0, 0.1, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_influence_min = 0.02
	pm.turbulence_influence_max = 0.06
	pm.scale_curve = _curve([Vector2(0, 0.4), Vector2(1, 2.2)])
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.color_ramp = _ramp([Color(0.2, 0.18, 0.16, 0.0), Color(0.18, 0.16, 0.15, 0.35), Color(0.15, 0.14, 0.13, 0.0)])
	p.draw_pass_1 = _quad(0.5 * size, Color(1, 1, 1), false)


func _emitter(amount: int, lifetime: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-1.5, -0.5, -1.5) * size, Vector3(3, 6, 3) * size)
	p.process_material = ParticleProcessMaterial.new()
	add_child(p)
	return p


## A camera-facing soft blob; `glow` = adds light (flames, sparks) instead of covering (smoke).
func _quad(s: float, col: Color, glow: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(s, s * (1.9 if glow and s > 0.1 else 1.0))  # flames are tall
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glow else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if glow else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = col
	m.albedo_texture = _soft_tex()
	m.disable_receive_shadows = true
	q.material = m
	return q


static func _soft_tex() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.4, Color(1, 1, 1, 0.6))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 64
		t.height = 64
		_soft = t
	return _soft


static func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for pt in points:
		c.add_point(pt)
	var t := CurveTexture.new()
	t.curve = c
	return t


static func _ramp(colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, colors[0])
	g.set_color(1, colors[colors.size() - 1])
	for i in range(1, colors.size() - 1):
		g.add_point(float(i) / (colors.size() - 1), colors[i])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t
