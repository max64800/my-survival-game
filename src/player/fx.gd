class_name Fx
## Little visual effects (rock bits flying when you dig).


static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 10, speed: float = 3.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.6
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.07
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
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
