class_name MonsterModel
## Placeholder monster looks made of simple shapes (until the art pack).
## Every model has glowing eyes; they flash right before an attack lands.


static func build(shape: String, color: Color, size: float, leader: bool, kind: String = "") -> Node3D:
	# A real model from the asset forge (Claude 2), when one exists for this monster:
	# res://assets/models/monsters/<kind>.glb (front +Z, feet at the bottom, ~1 m = size 1).
	var forged := Look.forged("monsters", kind) if kind != "" else null
	if forged:
		var holder := Node3D.new()
		forged.rotation.y = PI  # forged models face +Z; monsters face -Z
		holder.add_child(forged)
		var no_eyes := StandardMaterial3D.new()  # forged models have painted eyes; nothing to flash
		holder.set_meta("eye_mat", no_eyes)
		holder.scale = Vector3.ONE * size
		_tag_parts(holder, shape)
		return holder
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
			var glass := Look.mat(Color(0.8, 0.92, 1.0, 0.6))
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
		"shuffler":
			# A pig-sized pill-bug: banded shell segments, tiny legs, mossy back.
			for i in 5:
				_add(root, _sphere(0.42 - absf(i - 2) * 0.05, 0.3), body if i % 2 == 0 else dark, Vector3(0, 0.38, -0.36 + i * 0.18), Vector3(1.1, 1, 0.55))
			_add(root, _sphere(0.25, 0.08), _mat(Color(0.3, 0.5, 0.22)), Vector3(0, 0.62, 0.0), Vector3(1.2, 1, 1.6))
			for i in 8:
				var side := -1.0 if i < 4 else 1.0
				_add(root, _cyl(0.025, 0.02, 0.16), dark, Vector3(side * 0.36, 0.08, -0.3 + (i % 4) * 0.2))
			eye_y = 0.35
			eye_z = -0.52
		"bat":
			# A little cave bat with blue ear tufts.
			_add(root, _sphere(0.12, 0.12), body, Vector3(0, 1.3, 0))
			for x in [-1.0, 1.0]:
				var wing := _add(root, _box(Vector3(0.38, 0.02, 0.22)), dark, Vector3(x * 0.25, 1.32, 0.02))
				wing.rotation.z = x * 0.4
				_add(root, _cyl(0.0, 0.04, 0.1), _mat(Color(0.4, 0.7, 1.0)), Vector3(x * 0.06, 1.44, -0.03))
			eye_y = 1.33
			eye_z = -0.1
		"hog":
			# Six-legged grazer with mushroom-cap ears and a long snout.
			_add(root, _capsule(0.32, 1.0), body, Vector3(0, 0.5, 0.05), Vector3.ONE, Vector3(PI / 2.0, 0, 0))
			_add(root, _sphere(0.22, 0.2), body, Vector3(0, 0.55, -0.5))
			_add(root, _cyl(0.09, 0.12, 0.25), dark, Vector3(0, 0.48, -0.75)).rotation.x = PI / 2.0
			for x in [-1.0, 1.0]:
				_add(root, _sphere(0.13, 0.06), _mat(Color(0.75, 0.55, 0.45)), Vector3(x * 0.18, 0.75, -0.45))
				for z in [-0.3, 0.05, 0.4]:
					_add(root, _cyl(0.05, 0.05, 0.3), dark, Vector3(x * 0.22, 0.15, z))
			eye_y = 0.62
			eye_z = -0.66
		"snail":
			# A slow snail with a glowing green shell.
			_add(root, _capsule(0.12, 0.7), _mat(Color(0.75, 0.7, 0.6)), Vector3(0, 0.12, 0), Vector3.ONE, Vector3(PI / 2.0, 0, 0))
			var shell := StandardMaterial3D.new()
			shell.albedo_color = color.darkened(0.2)
			shell.emission_enabled = true
			shell.emission = color
			shell.emission_energy_multiplier = 1.4
			_add(root, _sphere(0.28, 0.26), shell, Vector3(0, 0.38, 0.1))
			for x in [-1.0, 1.0]:
				_add(root, _cyl(0.015, 0.015, 0.2), dark, Vector3(x * 0.05, 0.28, -0.35)).rotation.x = -0.4
			eye_y = 0.38
			eye_z = -0.4
		"puffpod":
			# A floating jellyfish-like spore sack trailing soft threads.
			var jelly := StandardMaterial3D.new()
			jelly.albedo_color = Color(color.r, color.g, color.b, 0.7)
			jelly.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			jelly.emission_enabled = true
			jelly.emission = color
			jelly.emission_energy_multiplier = 0.6
			_add(root, _sphere(0.32, 0.3), jelly, Vector3(0, 1.4, 0))
			for i in 5:
				var a := i * TAU / 5.0
				_add(root, _cyl(0.01, 0.02, 0.5), jelly, Vector3(cos(a) * 0.15, 1.0, sin(a) * 0.15))
			eye_y = 1.42
			eye_z = -0.29
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
	_tag_parts(root, shape)
	return root


# ------------------------------------------------------------ coming alive (only looks)

## Finds the parts that move: legs (thin tubes near the ground), wings (thin flat boxes on
## flyers) and a tail. Remembers their resting angle so the movement swings around it.
static func _tag_parts(root: Node3D, shape: String) -> void:
	var legs := []
	var wings := []
	for c in root.get_children():
		if not c is MeshInstance3D:
			continue
		var mi := c as MeshInstance3D
		_unbox(mi, shape)
		if mi.mesh is BoxMesh and (mi.mesh as BoxMesh).size.y < 0.05 and shape in ["moth", "bat"]:
			wings.append([mi, mi.rotation, signf(mi.position.x)])
		elif (mi.mesh is CylinderMesh or mi.mesh is CapsuleMesh) and mi.position.y < 0.3 and mi.position.length() > 0.05:
			# Neighbouring legs move in turns: by side and by front/back position.
			var phase := (0.0 if mi.position.x < 0.0 else PI) + mi.position.z * 6.0
			legs.append([mi, mi.rotation, phase])
	root.set_meta("legs", legs)
	root.set_meta("wings", wings)
	root.set_meta("flyer", shape in ["moth", "bat", "puffpod"])
	root.set_meta("rest_y", root.position.y)


## Chunky boxes look like toy blocks. Turn each one into a rough, faceted lump the same size
## (a boulder for stone creatures, a knobbly body part for the rest). Thin boxes (wings,
## blades, handles, eyes' brows) stay sharp.
static func _unbox(mi: MeshInstance3D, shape: String) -> void:
	if not mi.mesh is BoxMesh:
		return
	var size := (mi.mesh as BoxMesh).size
	if minf(size.x, minf(size.y, size.z)) < 0.09:
		return
	var lump := SphereMesh.new()
	lump.radius = 0.5
	lump.height = 1.0
	lump.radial_segments = 7
	lump.rings = 4
	mi.mesh = lump
	mi.scale *= size * 1.12
	if mi.material_override is ShaderMaterial:
		var albedo: Color = (mi.material_override as ShaderMaterial).get_shader_parameter("albedo")
		var stone := shape in ["golem", "armor", "shuffler"]
		mi.material_override = Look.mat(albedo, "stone" if stone else "", 0.0, 0.06 if stone else 0.03)


## Every frame: walking (legs swing in turns, the body bobs and waddles, leans into the run),
## wings flap, and a slow breath when standing still. `speed` in m/s, `size` = monster size.
static func animate(model: Node3D, speed: float, size: float, clock: float) -> void:
	if not model.has_meta("legs"):
		return
	var go := clampf(speed / 3.0, 0.0, 1.0)            # 0 = standing, 1 = running
	var stride := clock * (5.0 + speed * 2.5) / maxf(size, 0.6)
	for leg in model.get_meta("legs"):
		var mi: MeshInstance3D = leg[0]
		mi.rotation = leg[1] + Vector3(sin(stride + leg[2]) * 0.55 * go, 0, 0)
	for wing in model.get_meta("wings"):
		var mi: MeshInstance3D = wing[0]
		mi.rotation = wing[1] + Vector3(0, 0, sin(clock * 16.0) * 0.55 * wing[2])
	var rest_y: float = model.get_meta("rest_y")
	if model.get_meta("flyer"):
		model.position.y = rest_y + sin(clock * 2.2) * 0.12 * size  # hovering
	else:
		var bob := absf(sin(stride)) * 0.06 * size * go
		var breath := sin(clock * 2.0) * 0.012 * size * (1.0 - go)
		model.position.y = rest_y + bob + breath
	model.rotation.x = -0.15 * go  # lean into the run


## Crystal variants: a cluster of glowing crystals on the monster's back.
static func add_crystals(model: Node3D, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color.darkened(0.2)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.5
	var top := 0.3
	for c in model.get_children():
		if c is MeshInstance3D:
			top = maxf(top, c.position.y)
	for i in 4:
		var shard := _add(model, _cyl(0.0, 0.07, 0.35 - i * 0.04), m, Vector3((i - 1.5) * 0.09, top + 0.1, 0.1 + (i % 2) * 0.08))
		shard.rotation = Vector3(0.3 - (i % 2) * 0.5, 0, (i - 1.5) * 0.35)


## Bosses: every part gets a faint glow of `color` so the big shape reads in the dark.
static func make_glowy(model: Node3D, color: Color) -> void:
	for c in model.get_children():
		if c is MeshInstance3D and c.material_override is ShaderMaterial:
			# The painted look (Look.mat): same colour and grain, plus the soft glow.
			var albedo: Color = (c.material_override as ShaderMaterial).get_shader_parameter("albedo")
			c.material_override = Look.mat(albedo, "", 0.25, 0.015, color)
		elif c is MeshInstance3D and c.material_override is StandardMaterial3D and c.material_override != model.get_meta("eye_mat"):
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


static func _mat(c: Color) -> Material:
	return Look.mat(c, "", 0.0, 0.015)  # slightly lumpy: creatures shouldn't look machine-made


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
