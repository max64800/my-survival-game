class_name ChestOpen
## Opening a chest (owner, Nov 18: "7 steps to a juicy chest opening"). Only looks, on the opener's own screen.
## A loot chest the first time (`full`): 1. it wobbles faster and faster and squashes down, 2. springs up tall and
## bounces back, 3. SLAMS open: a blink of stillness and a camera shake, 4. a warm light from inside with slow turning
## rays, 5. a ring of light rushes out, 6. golden sparks pop out, 7. tiny magic dust keeps floating up.
## Any other time (your own chests): a quick squash-and-pop, so it never slows you down.
## Returns how many seconds until the chest is "open" (the menu opens then).

const WOBBLE := 0.34   ## seconds of wobbling before the spring
const SLAM := 0.47     ## when it slams open (the menu opens here)
const GOLD := Color(1.0, 0.82, 0.42)


static func play(body: Node3D, full: bool) -> float:
	var look := _look_of(body)
	if look == null:
		return 0.0
	var base: Vector3 = look.get_meta("chest_scale", look.scale)
	look.set_meta("chest_scale", base)
	var rot0: Vector3 = look.get_meta("chest_rot", look.rotation)
	look.set_meta("chest_rot", rot0)
	var t := look.create_tween()
	if not full:
		t.tween_property(look, "scale", base * Vector3(1.08, 0.9, 1.08), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(look, "scale", base * Vector3(0.97, 1.06, 0.97), 0.07)
		t.tween_property(look, "scale", base, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return 0.0
	# 1. wobble, faster and faster, and squash down
	t.tween_method(func(k: float) -> void:
		if is_instance_valid(look):
			look.rotation = rot0 + Vector3(0, 0, sin(k * k * 38.0) * 0.09 * (0.4 + k))
			look.scale = base * Vector3(1.0 + 0.1 * k, 1.0 - 0.16 * k, 1.0 + 0.1 * k), 0.0, 1.0, WOBBLE)
	# 2. stretch: spring up tall
	t.tween_callback(func() -> void:
		if is_instance_valid(look):
			look.rotation = rot0)
	t.tween_property(look, "scale", base * Vector3(0.9, 1.18, 0.9), SLAM - WOBBLE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 3. slam: a blink of stillness, then it bounces back to its size
	t.tween_interval(0.06)
	t.tween_property(look, "scale", base, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	body.get_tree().create_timer(SLAM).timeout.connect(func() -> void:
		if is_instance_valid(body):
			_burst(body))
	return SLAM


## The chest's drawn model (not its collision or its name tag): the part that wobbles.
static func _look_of(body: Node3D) -> Node3D:
	for c in body.get_children():
		if c is Node3D and not (c is CollisionShape3D or c is Label3D) and String(c.name) != "Fill":
			return c
	return null


## 4-7: light, rays, a ring, sparks and dust, from the chest's top.
static func _burst(body: Node3D) -> void:
	var parent := body.get_parent()
	var top := body.global_position + Vector3.UP * 0.75
	Sfx.play("pickup", top, 0.0, 0.8)
	# 4. a warm light from inside, with slow turning rays
	var light := OmniLight3D.new()
	light.light_color = GOLD
	light.omni_range = 4.5
	light.light_energy = 0.0
	parent.add_child(light)
	light.global_position = top
	var rays := Node3D.new()
	parent.add_child(rays)
	rays.global_position = top - Vector3.UP * 0.2
	var ray_mat := StandardMaterial3D.new()
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ray_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ray_mat.albedo_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.0)
	var fade := Gradient.new()  # (light, not planks: bright at the chest, gone at the tip, soft at the sides)
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	var ft := GradientTexture2D.new()
	ft.gradient = fade
	ft.fill = GradientTexture2D.FILL_RADIAL
	ft.fill_from = Vector2(0.5, 1.0)
	ft.fill_to = Vector2(0.5, 0.0)
	ft.width = 32
	ft.height = 128
	ray_mat.albedo_texture = ft
	for i in 6:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.22, 1.6)
		q.mesh = qm
		q.material_override = ray_mat
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := TAU * i / 6.0
		q.rotation = Vector3(0.0, a, 0.32)  # (fanned out, tilted outward)
		q.position = Vector3(sin(a) * 0.25, 0.72, cos(a) * 0.25)
		rays.add_child(q)
	var t := rays.create_tween()
	t.set_parallel(true)
	t.tween_property(light, "light_energy", 2.6, 0.12)
	t.tween_property(ray_mat, "albedo_color:a", 0.42, 0.15)
	t.tween_property(rays, "rotation:y", 1.4, 1.6)
	t.chain().tween_property(light, "light_energy", 0.0, 1.1)
	t.parallel().tween_property(ray_mat, "albedo_color:a", 0.0, 1.1)
	t.chain().tween_callback(func() -> void:
		light.queue_free()
		rays.queue_free())
	# 5. a ring of light rushes out
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	ring.mesh = tm
	var ring_mat := ray_mat.duplicate() as StandardMaterial3D
	ring_mat.albedo_color = Color(1.0, 0.92, 0.7, 0.8)
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.global_position = body.global_position + Vector3.UP * 0.35
	ring.scale = Vector3(0.5, 0.25, 0.5)
	var rt := ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(4.0, 0.25, 4.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring_mat, "albedo_color:a", 0.0, 0.4)
	rt.chain().tween_callback(ring.queue_free)
	# 6. golden sparks pop out
	Fx.burst(parent, top, Color(1.0, 0.95, 0.7), 16, 5.0, Vector3.UP, 45.0)
	# 7. magic dust that keeps floating up
	var dust := CPUParticles3D.new()
	dust.one_shot = true
	dust.amount = 26
	dust.lifetime = 2.2
	dust.explosiveness = 0.25
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.35
	dust.direction = Vector3.UP
	dust.spread = 25.0
	dust.initial_velocity_min = 0.25
	dust.initial_velocity_max = 0.6
	dust.gravity = Vector3(0, 0.15, 0)
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.0
	var dm := SphereMesh.new()
	dm.radius = 0.015
	dm.height = 0.03
	dm.radial_segments = 6
	dm.rings = 3
	dust.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(1.0, 0.9, 0.6)
	dmat.emission_enabled = true
	dmat.emission = GOLD
	dmat.emission_energy_multiplier = 2.0
	dust.material_override = dmat
	parent.add_child(dust)
	dust.global_position = top
	dust.emitting = true
	dust.finished.connect(dust.queue_free)
