class_name MonsterModel
## Placeholder monster looks made of simple shapes (until the art pack).
## Every model has glowing eyes; they flash right before an attack lands.


static func build(shape: String, color: Color, size: float, leader: bool) -> Node3D:
	var root := Node3D.new()
	var body := _mat(color)
	var dark := _mat(color.darkened(0.35))
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(1.0, 0.9, 0.5)
	eye.emission_enabled = true
	eye.emission = Color(1.0, 0.85, 0.4)
	eye.emission_energy_multiplier = 0.6
	root.set_meta("eye_mat", eye)
	var eye_y := 0.3
	var eye_z := -0.3
	match shape:
		"crab":
			_add(root, _sphere(0.32, 0.18), body, Vector3(0, 0.22, 0), Vector3(1.3, 1, 1))
			_add(root, _sphere(0.25, 0.12), _mat(Color(0.25, 0.55, 0.2)), Vector3(0, 0.32, 0.03))
			for i in 6:
				var side := -1.0 if i < 3 else 1.0
				var leg := _add(root, _cyl(0.025, 0.02, 0.35), dark, Vector3(side * 0.35, 0.12, -0.15 + (i % 3) * 0.15))
				leg.rotation.z = side * 0.9
			var claw := _add(root, _box(Vector3(0.22, 0.14, 0.32)), dark, Vector3(0.38, 0.25, -0.35))
			claw.rotation.y = 0.4
			eye_y = 0.36
			eye_z = -0.25
		"lizard":
			_add(root, _capsule(0.16, 0.8), body, Vector3(0, 0.2, 0), Vector3.ONE, Vector3(PI / 2.0, 0, 0))
			_add(root, _sphere(0.15, 0.14), body, Vector3(0, 0.24, -0.45))
			var tail := _add(root, _cyl(0.1, 0.0, 0.6), dark, Vector3(0, 0.18, 0.65))
			tail.rotation.x = PI / 2.0
			for x in [-1.0, 1.0]:
				for z in [-0.2, 0.2]:
					_add(root, _cyl(0.03, 0.03, 0.22), dark, Vector3(x * 0.18, 0.08, z)).rotation.z = x * 0.6
			for i in 4:
				_add(root, _sphere(0.035, 0.035), eye, Vector3(sin(i * 1.7) * 0.1, 0.34, -0.2 + i * 0.12))
			eye_y = 0.3
			eye_z = -0.55
		"moth":
			_add(root, _capsule(0.08, 0.35), body, Vector3(0, 1.2, 0))
			for x in [-1.0, 1.0]:
				var wing := _add(root, _box(Vector3(0.45, 0.02, 0.35)), _mat(color.lightened(0.2)), Vector3(x * 0.28, 1.25, 0))
				wing.rotation.z = x * 0.35
			eye_y = 1.32
			eye_z = -0.07
		"toad":
			_add(root, _sphere(0.5, 0.42), body, Vector3(0, 0.42, 0), Vector3(1.15, 1, 1))
			_add(root, _sphere(0.25, 0.2), _mat(Color(0.85, 0.75, 0.55)), Vector3(0, 0.3, -0.38))
			for x in [-1.0, 1.0]:
				_add(root, _sphere(0.16, 0.12), dark, Vector3(x * 0.45, 0.12, 0.2))
			eye_y = 0.75
			eye_z = -0.32
		"armor":
			_add(root, _cyl(0.24, 0.28, 0.6), body, Vector3(0, 0.55, 0))
			_add(root, _sphere(0.2, 0.2), dark, Vector3(0, 1.0, 0))
			_add(root, _box(Vector3(0.05, 0.12, 0.04)), dark, Vector3(0, 0.98, -0.2))
			var axe := _add(root, _box(Vector3(0.06, 0.7, 0.06)), _mat(Color(0.35, 0.25, 0.15)), Vector3(0.35, 0.55, -0.1))
			axe.rotation.x = -0.4
			_add(root, _box(Vector3(0.05, 0.22, 0.25)), dark, Vector3(0.35, 0.85, -0.25))
			_add(root, _sphere(0.18, 0.15), _mat(Color(0.25, 0.45, 0.2)), Vector3(-0.15, 0.85, 0.1))  # moss
			eye.emission = Color(0.4, 0.75, 1.0)
			eye.albedo_color = Color(0.4, 0.75, 1.0)
			eye_y = 1.0
			eye_z = -0.17
		"golem":
			_add(root, _box(Vector3(0.9, 0.7, 0.6)), body, Vector3(0, 0.75, 0))
			_add(root, _box(Vector3(0.5, 0.4, 0.45)), body, Vector3(0, 1.3, 0))
			for x in [-1.0, 1.0]:
				_add(root, _box(Vector3(0.3, 0.7, 0.3)), dark, Vector3(x * 0.6, 0.6, 0))
				_add(root, _box(Vector3(0.3, 0.45, 0.3)), dark, Vector3(x * 0.25, 0.22, 0))
			var runes := StandardMaterial3D.new()
			runes.albedo_color = Color(1.0, 0.6, 0.2)
			runes.emission_enabled = true
			runes.emission = Color(1.0, 0.55, 0.15)
			runes.emission_energy_multiplier = 1.5
			_add(root, _box(Vector3(0.35, 0.3, 0.02)), runes, Vector3(0, 0.8, -0.31))
			eye_y = 1.35
			eye_z = -0.23
		"mushroom":
			# A walking (or rooted) mushroom: stubby stem, wide spotted cap, a gill "mouth".
			_add(root, _cyl(0.2, 0.26, 0.6), _mat(Color(0.88, 0.84, 0.76)), Vector3(0, 0.3, 0))
			_add(root, _sphere(0.48, 0.3), body, Vector3(0, 0.62, 0), Vector3(1, 1, 1))
			for i in 5:
				var a := i * 1.3
				_add(root, _sphere(0.07, 0.04), _mat(color.lightened(0.45)), Vector3(cos(a) * 0.28, 0.82, sin(a) * 0.28))
			_add(root, _box(Vector3(0.22, 0.06, 0.04)), dark, Vector3(0, 0.38, -0.21))
			for x in [-1.0, 1.0]:
				_add(root, _cyl(0.05, 0.07, 0.2), dark, Vector3(x * 0.13, 0.08, 0))
			eye_y = 0.5
			eye_z = -0.2
		"mite":
			# Glassy-legged mite with a long needle mouth.
			_add(root, _sphere(0.28, 0.2), body, Vector3(0, 0.35, 0.1), Vector3(1, 1, 1.3))
			_add(root, _sphere(0.16, 0.13), dark, Vector3(0, 0.38, -0.25))
			var needle := _add(root, _cyl(0.0, 0.03, 0.4), _mat(Color(0.85, 0.95, 1.0)), Vector3(0, 0.36, -0.55))
			needle.rotation.x = -PI / 2.0
			var glass := _mat(Color(0.8, 0.92, 1.0))
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.albedo_color.a = 0.6
			for i in 6:
				var side := -1.0 if i < 3 else 1.0
				var leg := _add(root, _cyl(0.015, 0.02, 0.55), glass, Vector3(side * 0.3, 0.22, -0.15 + (i % 3) * 0.18))
				leg.rotation.z = side * 0.75
			eye_y = 0.45
			eye_z = -0.36
		"beetle":
			# A huge horned beetle: dark bronze shell, small head, one big horn.
			_add(root, _sphere(0.6, 0.38), body, Vector3(0, 0.5, 0.1), Vector3(1.0, 1.0, 1.35))
			_add(root, _box(Vector3(0.04, 0.5, 1.3)), _mat(color.darkened(0.5)), Vector3(0, 0.82, 0.1))  # shell seam
			_add(root, _sphere(0.26, 0.2), dark, Vector3(0, 0.42, -0.7))
			var horn := _add(root, _cyl(0.02, 0.09, 0.55), _mat(Color(0.82, 0.76, 0.6)), Vector3(0, 0.62, -0.95))
			horn.rotation.x = -0.9
			for i in 6:
				var side := -1.0 if i < 3 else 1.0
				var leg := _add(root, _cyl(0.04, 0.05, 0.45), dark, Vector3(side * 0.55, 0.2, -0.35 + (i % 3) * 0.4))
				leg.rotation.z = side * 0.8
			eye_y = 0.5
			eye_z = -0.88
		"mantis":
			# Tall thin stalker with folded scythe arms and a gilled head.
			_add(root, _capsule(0.12, 0.9), body, Vector3(0, 1.0, 0.1), Vector3.ONE, Vector3(0.35, 0, 0))
			_add(root, _capsule(0.1, 0.6), dark, Vector3(0, 0.55, 0.35), Vector3.ONE, Vector3(1.2, 0, 0))
			_add(root, _sphere(0.14, 0.12), body, Vector3(0, 1.5, -0.12))
			for x in [-1.0, 1.0]:
				_add(root, _box(Vector3(0.05, 0.12, 0.2)), _mat(color.lightened(0.3)), Vector3(x * 0.13, 1.52, -0.05))  # gills
				var arm := _add(root, _box(Vector3(0.05, 0.6, 0.06)), dark, Vector3(x * 0.18, 1.2, -0.3))
				arm.rotation.x = 0.6
				var blade := _add(root, _box(Vector3(0.03, 0.55, 0.1)), _mat(Color(0.8, 0.8, 0.85)), Vector3(x * 0.18, 1.05, -0.55))
				blade.rotation.x = -0.5
				for z in [-0.1, 0.35]:
					_add(root, _cyl(0.02, 0.025, 0.7), dark, Vector3(x * 0.2, 0.32, z)).rotation.z = x * 0.35
			eye_y = 1.54
			eye_z = -0.25
	for x in [-0.07, 0.07]:
		_add(root, _sphere(0.035, 0.035), eye, Vector3(x * (2.0 if shape == "golem" else 1.0), eye_y, eye_z))
	if leader:
		# A glowing gold moss crown, so you can spot the pack leader.
		var crown_mat := StandardMaterial3D.new()
		# Jungle leaders wear an orange frill instead of the gold moss crown (combat doc 6.2).
		var gold := Color(1.0, 0.45, 0.15) if shape in ["mushroom", "mite", "beetle", "mantis"] else Color(1.0, 0.75, 0.2)
		crown_mat.albedo_color = gold.lightened(0.1)
		crown_mat.emission_enabled = true
		crown_mat.emission = gold
		crown_mat.emission_energy_multiplier = 2.0
		var crown := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.1
		tm.outer_radius = 0.16
		crown.mesh = tm
		crown.material_override = crown_mat
		crown.position = Vector3(0, eye_y + 0.18, eye_z + 0.1)
		root.add_child(crown)
	root.scale = Vector3.ONE * size
	return root


## Bosses: every part gets a faint glow of `color` so the big shape reads in the dark.
static func make_glowy(model: Node3D, color: Color) -> void:
	for c in model.get_children():
		if c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override != model.get_meta("eye_mat"):
			var m: StandardMaterial3D = (c.material_override as StandardMaterial3D).duplicate()
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = 0.25
			c.material_override = m


## 0 = normal eyes, 1 = bright flash (the "tell" just before a hit lands).
static func set_glow(model: Node3D, amount: float) -> void:
	var m: StandardMaterial3D = model.get_meta("eye_mat")
	m.emission_energy_multiplier = 0.6 + amount * 8.0


static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scale := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m


static func _sphere(r: float, h: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h * 2.0
	m.radial_segments = 10
	m.rings = 5
	return m


static func _capsule(r: float, h: float) -> Mesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 8
	m.rings = 3
	return m


static func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 6
	return m


static func _box(s: Vector3) -> Mesh:
	var m := BoxMesh.new()
	m.size = s
	return m
