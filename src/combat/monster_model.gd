class_name MonsterModel
## Placeholder monster looks made of simple shapes (until the art pack).
## Every model has glowing eyes; they flash right before an attack lands.


## seed: makes each creature an individual (which hand-built version, and a slightly different
## size). Use the monster's uid, so every player in co-op sees the same creature the same way.
## Creatures made from the owner's approved ChatGPT pictures (docs/art/CREATURE-STYLE.md):
## res://assets/models/creatures/<art>_<look>.glb. The Great Rock Beetle is a bigger Rock Beetle.
const CREATURE_ART := {"rock_snail": "rock_snail", "cave_bat": "cave_bat", "rock_beetle": "rock_beetle", "great_rock_beetle": "rock_beetle"}
## Crystal variants (Monsters.VARIANTS) wear their own look: ember, frost, spore.
const VARIANT_ART := {"": "mossy", "red": "ember", "blue": "frost", "green": "spore"}
## Normal creatures wear any of the 4 looks (owner, Nov 19: "I still see only green snails, only green beetles": all 4
## looks mixed in every cave). Picked from the creature's number, so the next one is a different look (the first
## cave's two snails differ) and every computer sees the same. Crystal variants keep crystals on top to stand out.
const LOOKS := ["mossy", "ember", "frost", "spore"]


static func look_of(variant: String, seed: int) -> String:
	return VARIANT_ART[variant] if variant != "" and VARIANT_ART.has(variant) else LOOKS[posmod(seed, LOOKS.size())]


static func build(shape: String, color: Color, size: float, leader: bool, kind: String = "", seed: int = 0, variant: String = "", look_seed: int = -1) -> Node3D:
	# 1. A creature forged from the approved pictures, in this variant's look.
	# 2. Else a hand-built model: res://assets/models/monsters/<kind>_v<N>.glb or <kind>.glb.
	# (front +Z, feet at the bottom, ~1 m = size 1). 3. Else simple shapes made here.
	var forged: Node3D = null
	var art_look := false
	if CREATURE_ART.has(kind):
		var look := look_of(variant, seed if look_seed < 0 else look_seed)
		forged = Look.forged("creatures", "%s_%s" % [CREATURE_ART[kind], look])
		if forged == null:
			forged = Look.forged("creatures", "%s_mossy" % CREATURE_ART[kind])
		art_look = false  # (a look alone no longer means a crystal variant: variants get their crystals too)
	if forged == null and kind != "":
		var count := variant_count(kind)
		forged = Look.forged("monsters", "%s_v%d" % [kind, posmod(seed, count)]) if count > 0 else Look.forged("monsters", kind)
	if forged:
		var holder := Node3D.new()
		forged.rotation.y = PI  # forged models face +Z; monsters face -Z
		holder.add_child(forged)
		var jitter := 1.0 + (float(posmod(seed * 7919, 1000)) / 1000.0 - 0.5) * 0.12  # each one a little bigger or smaller
		holder.scale = Vector3.ONE * size * jitter
		holder.set_meta("variant_look", art_look)  # it already shows its variant (no extra crystals needed)
		if CREATURE_ART.has(kind):
			holder.set_meta("look", look_of(variant, seed if look_seed < 0 else look_seed))
		_tag_forged(holder, forged, shape)
		_vary_stone(forged, seed)
		return holder  # (a leader is just much bigger: Monsters.LEADER.size; the crown came off, owner Nov 19, F421)
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
		"rock_snail":
			# A big rock snail: a heavy spiral shell of stone on a soft grey body, eyes on stalks.
			# Parts tagged "soft" pull into the shell when it hides (set_shell).
			var flesh := Look.mat(Color(0.6, 0.57, 0.52), "fungus", 0.0, 0.02)
			var foot := _add(root, _capsule(0.2, 1.25), flesh, Vector3(0, 0.16, -0.05), Vector3(1.15, 0.7, 1.0), Vector3(PI / 2.0, 0, 0))
			foot.set_meta("soft", true)
			var head := _add(root, _sphere(0.17, 0.15), flesh, Vector3(0, 0.3, -0.58))
			head.set_meta("soft", true)
			for x in [-1.0, 1.0]:
				var stalk := _add(root, _cyl(0.018, 0.03, 0.3), flesh, Vector3(x * 0.07, 0.48, -0.62))
				stalk.rotation = Vector3(-0.35, 0, x * 0.25)
				stalk.set_meta("soft", true)
			var rock := Look.mat(color, "stone", 0.0, 0.05)
			var shell := _add(root, _sphere(0.44, 0.44), rock, Vector3(0, 0.62, 0.15), Vector3(0.8, 1.0, 1.0))
			shell.set_meta("shell", true)
			for i in 3:  # the spiral: rings getting smaller toward the middle
				var ring := MeshInstance3D.new()
				var tm := TorusMesh.new()
				tm.inner_radius = 0.3 - i * 0.09
				tm.outer_radius = 0.38 - i * 0.09
				tm.rings = 18
				tm.ring_segments = 6
				ring.mesh = tm
				ring.material_override = Look.mat(color.darkened(0.15 + i * 0.05), "stone", 0.0, 0.03)
				ring.rotation.z = PI / 2.0  # lies flat against the side of the shell
				ring.set_meta("shell", true)
				for side in [-1.0, 1.0]:
					var r2 := ring if side < 0.0 else ring.duplicate() as MeshInstance3D
					r2.position = Vector3(side * (0.3 + i * 0.03), 0.64 + i * 0.02, 0.15 - i * 0.02)
					root.add_child(r2)
			eye_y = 0.63
			eye_z = -0.7
		"cave_bat":
			# A dog-sized cave bat: furry body, big ears, fangs, and real membrane wings (~1.5 m).
			var fur := Look.mat(color, "cloth", 0.0, 0.02)
			_add(root, _capsule(0.15, 0.48), fur, Vector3(0, 1.3, 0.05), Vector3.ONE, Vector3(0.3, 0, 0))
			_add(root, _sphere(0.14, 0.13), fur, Vector3(0, 1.52, -0.12))
			_add(root, _sphere(0.06, 0.05), dark, Vector3(0, 1.49, -0.25))  # snout
			for x in [-1.0, 1.0]:
				var ear := _add(root, _cyl(0.0, 0.06, 0.2), fur, Vector3(x * 0.08, 1.68, -0.1))
				ear.rotation.z = -x * 0.3
				_add(root, _cyl(0.0, 0.012, 0.07), _mat(Color(0.92, 0.9, 0.85)), Vector3(x * 0.025, 1.42, -0.27)).rotation.x = PI  # fang
				var wing := MeshInstance3D.new()
				wing.mesh = _bat_wing(x)
				wing.material_override = Look.mat(color.darkened(0.25), "leather", 0.0, 0.0)
				wing.position = Vector3(x * 0.1, 1.38, 0.0)
				wing.set_meta("wing", x)
				root.add_child(wing)
				_add(root, _cyl(0.02, 0.025, 0.14), dark, Vector3(x * 0.07, 1.06, 0.12))  # little legs
			eye_y = 1.56
			eye_z = -0.24
		"rock_beetle":
			# A rock beetle: a domed stone shell in front, horn and mandibles, and a pale soft back
			# end with a glowing gland: its weak spot (and where the glow gland drop comes from).
			var plate := Look.mat(color, "stone", 0.0, 0.04)
			_add(root, _sphere(0.5, 0.5), plate, Vector3(0, 0.46, -0.05), Vector3(0.95, 0.62, 1.1))  # shell dome
			_add(root, _box(Vector3(0.025, 0.04, 0.8)), _mat(color.darkened(0.4)), Vector3(0, 0.74, -0.05))  # shell seam
			_add(root, _sphere(0.3, 0.3), plate, Vector3(0, 0.42, -0.58), Vector3(1.1, 0.7, 0.8))  # front plate
			_add(root, _sphere(0.18, 0.18), dark, Vector3(0, 0.36, -0.86))  # head
			var horn := _add(root, _cyl(0.015, 0.08, 0.45), _mat(Color(0.78, 0.72, 0.6)), Vector3(0, 0.55, -1.0))
			horn.rotation.x = -0.75
			for x in [-1.0, 1.0]:
				var jaw := _add(root, _cyl(0.0, 0.04, 0.22), dark, Vector3(x * 0.08, 0.3, -1.0))
				jaw.rotation = Vector3(-PI / 2.0, 0, x * 0.5)
			var soft := Look.mat(Color(0.82, 0.68, 0.5), "fungus", 0.0, 0.02)
			for i in 3:  # soft ringed back end
				_add(root, _sphere(0.26 - i * 0.05, 0.2), soft, Vector3(0, 0.36 - i * 0.02, 0.5 + i * 0.13), Vector3(1.2, 0.8, 0.7))
			_add(root, _sphere(0.08, 0.08), Look.mat(Color(0.5, 0.9, 0.6), "smooth", 2.0), Vector3(0, 0.3, 0.72))  # glow gland
			for i in 6:
				var side := -1.0 if i < 3 else 1.0
				var z := -0.45 + (i % 3) * 0.38
				var upper := _add(root, _cyl(0.035, 0.045, 0.32), dark, Vector3(side * 0.45, 0.28, z))
				upper.rotation.z = side * 1.0
				_add(root, _cyl(0.025, 0.035, 0.3), dark, Vector3(side * 0.62, 0.12, z)).rotation.z = side * 0.25
			eye_y = 0.42
			eye_z = -0.98
	for x in [-0.07, 0.07]:
		_add(root, _sphere(0.035, 0.035), eye, Vector3(x, eye_y, eye_z))
	root.scale = Vector3.ONE * size
	_tag_parts(root, shape)
	return root


## A bat wing: a membrane spanning thin finger bones, with a scalloped back edge.
## Built flat (both sides visible), reaching out along x (side = -1 left, +1 right).
static func _bat_wing(side: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tips := [Vector3(0.82, 0.12, -0.12), Vector3(0.74, -0.05, 0.3), Vector3(0.5, -0.08, 0.46), Vector3(0.22, -0.06, 0.42)]
	var root_front := Vector3(0.0, 0.04, -0.1)
	var root_back := Vector3(0.0, -0.08, 0.26)
	var pts := [root_front, Vector3(0.4, 0.14, -0.18), tips[0]]
	for i in range(1, tips.size()):
		var mid: Vector3 = (tips[i - 1] + tips[i]) * 0.5 + Vector3(-0.05, 0.02, -0.06)  # scallop dips in
		pts.append(mid)
		pts.append(tips[i])
	pts.append(root_back)
	for i in range(1, pts.size() - 1):
		for v in [pts[0], pts[i], pts[i + 1], pts[0], pts[i + 1], pts[i]]:  # both sides
			st.add_vertex(Vector3(v.x * side, v.y, v.z))
	st.generate_normals()
	return st.commit()


## Rock Snail: pull the soft body into the shell (hidden = true) or come back out.
static func set_shell(model: Node3D, hidden: bool) -> void:
	model.set_meta("hidden", hidden)
	if model.has_meta("forged_root"):
		_forged_shell(model, hidden)
		return
	for c in model.find_children("*", "MeshInstance3D", true, false):
		if c.has_meta("soft"):
			var mi := c as MeshInstance3D
			if not mi.has_meta("out_scale"):
				mi.set_meta("out_scale", mi.scale)
				mi.set_meta("out_pos", mi.position)
			var t := mi.create_tween()
			var to_pos: Vector3 = mi.get_meta("out_pos")
			if hidden and not mi.has_meta("forged"):
				to_pos = Vector3(0, 0.5, 0.1)
			# Hand-built models shrink toward their hinge, deep under the shell (creature_kit.py).
			var shrink := (0.45 if mi.has_meta("forged") else 0.15) if hidden else 1.0
			t.tween_property(mi, "scale", (mi.get_meta("out_scale") as Vector3) * shrink, 0.25)
			t.parallel().tween_property(mi, "position", to_pos, 0.25)


# ------------------------------------------------------------ coming alive (only looks)

## Hand-built snail hiding: the whole soft body (tail too) shrinks into the shell, the shell settles
## onto the ground, and only two small eyes peek out of the shell's mouth.
static func _forged_shell(model: Node3D, hidden: bool) -> void:
	var root: Node3D = model.get_meta("forged_root")
	var parts := root.find_children("*", "MeshInstance3D", true, false)
	var drop := 0.0
	for mi: MeshInstance3D in parts:
		if String(mi.name) == "body":  # the shell: how high its bottom sits above the ground
			drop = maxf(0.0, (mi.get_aabb().position.y + mi.position.y) - 0.04)
	for mi: MeshInstance3D in parts:
		if not mi.has_meta("out_pos"):
			mi.set_meta("out_pos", mi.position)
			mi.set_meta("out_scale", mi.scale)
		var t := mi.create_tween().set_trans(Tween.TRANS_QUAD)
		var pos: Vector3 = mi.get_meta("out_pos")
		t.tween_property(mi, "position", pos + Vector3.DOWN * (drop if hidden else 0.0), 0.3)
		if mi.has_meta("soft"):
			t.parallel().tween_property(mi, "scale", (mi.get_meta("out_scale") as Vector3) * (0.02 if hidden else 1.0), 0.3)
	for p: MeshInstance3D in model.get_meta("peek", []):
		p.visible = hidden


static var _variants := {}


## How many hand-built versions a creature has (<kind>_v0.glb, _v1...). 0 = none.
static func variant_count(kind: String) -> int:
	if not _variants.has(kind):
		var n := 0
		while n < 16 and ResourceLoader.exists("res://assets/models/monsters/%s_v%d.glb" % [kind, n]):
			n += 1
		_variants[kind] = n
	return _variants[kind]


## Hand-built creatures (tools/asset_forge/creature_kit.py) name their moving parts:
## leg* walk, wing_l / wing_r flap, soft* pull into the shell, material "eye*" flashes.
## Each part turns around its own hinge (hip, shoulder, shell mouth).
## Every creature that spawns wears its stones a little differently (owner, Nov 16): its stone materials get their own
## slight shade, warmer or cooler, lighter or darker. Uses the monster's seed, so co-op friends see the same one.
static func _vary_stone(forged: Node3D, seed: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(seed * 31 + 7)
	var v := r.randf_range(0.88, 1.1)
	var warm := r.randf_range(-0.07, 0.07)
	var tint := Color(v * (1.0 + warm), v * (1.0 + warm * 0.3), v * (1.0 - warm))
	var own := {}
	for mi: MeshInstance3D in forged.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count() if mi.mesh else 0:
			var m := mi.get_active_material(i)
			if m is StandardMaterial3D and String(m.resource_name).begins_with("stone"):
				if not own.has(m):
					own[m] = (m as StandardMaterial3D).duplicate()
					(own[m] as StandardMaterial3D).albedo_color *= tint
				mi.set_surface_override_material(i, own[m])
	# Keep the copies alive on the model root too (like the eye and glow copies): if they lived only in the parts,
	# deleting the whole world at once could free a copy before the engine let go of its part (an engine error).
	forged.set_meta("stone_mats", own.values())


static func _tag_forged(holder: Node3D, forged: Node3D, shape: String) -> void:
	var legs := []
	var wings := []
	var webs := []
	var stalks := []
	var blinks := []
	var peek := []
	var folds := []
	var mats := {}  # material name prefix -> this monster's own copy (eyes flash, cracks glow on their own)
	for mi: MeshInstance3D in forged.find_children("*", "MeshInstance3D", true, false):
		var n := String(mi.name)
		mi.set_meta("forged", true)
		if n.begins_with("leg"):
			# Insect walk: two tripods (front + back on one side, middle on the other) step in turns.
			var idx := int(n.right(1)) if n.right(1).is_valid_int() else 0
			var side := signf(mi.position.x)
			var group := (idx + (0 if side < 0.0 else 1)) % 2
			legs.append([mi, mi.rotation, float(group) * PI, side, 0.03 * idx])
		elif n.begins_with("wing"):
			wings.append([mi, mi.rotation, signf(mi.position.x)])
		elif n.begins_with("web"):
			# The bat's wing webs (owner, Nov 18: "more bones"): the middle web hangs on the arm, the outer web on the
			# middle one, both turning at the wrist; they follow the beat a little late, like a wave down the wing.
			webs.append([mi, mi.rotation, -1.0 if n.ends_with("_l") else 1.0, 2.0 if n.begins_with("web_tip") else 1.0])
		elif n.begins_with("soft"):
			mi.set_meta("soft", true)
			if n == "soft_foot":
				holder.set_meta("foot", mi)  # the snail's creeping foot: it gathers and splats when he hops (_snail)
			if n.begins_with("soft_stalk"):
				stalks.append([mi, mi.rotation, stalks.size() * 1.7])
		elif n.begins_with("blink"):
			blinks.append([mi, mi.basis])  # the snail's blink lids: tucked up, turned down to blink (_snail)
		elif n.begins_with("peek"):
			mi.visible = false  # only shows while hiding in the shell
			peek.append(mi)
		elif n.begins_with("fold"):
			mi.visible = false  # folded sleeping wings: only while it roosts
			folds.append(mi)
		for i in mi.mesh.get_surface_count() if mi.mesh else 0:
			var m := mi.get_active_material(i)
			if not m is StandardMaterial3D:
				continue
			var mname := String(m.resource_name)
			for prefix in ["eye", "vein", "glow"]:
				if mname.begins_with(prefix):
					# One copy per material name (so a beetle's amber facets and its lava keep their own colours),
					# shared by all its parts; this monster's copies flash and blaze on their own.
					var key: String = prefix if prefix == "vein" else mname  # (each eye its own copy: one shared copy of the first eye found gave the snail's painted eyes the plain white of its peeking eyes)
					if not mats.has(key):
						var own := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
						own.emission_enabled = true
						if prefix == "vein":
							own.emission = Color(1.0, 0.32, 0.08)
							own.emission_energy_multiplier = 0.0  # dark until it charges
						if prefix == "glow":  # lava cracks, glowing backs, spore spots: always glow a little
							# Painted glow (forged models) is in the texture; hand-built ones glow in their own colour.
							own.emission = Color.WHITE if own.emission_texture else own.albedo_color
							own.set_meta("base_energy", maxf(0.8, own.emission_energy_multiplier))
						mats[key] = own
					mi.set_surface_override_material(i, mats[key])
	var eyes: Array = mats.keys().filter(func(k: String) -> bool: return k.begins_with("eye")).map(func(k: String) -> StandardMaterial3D: return mats[k])
	if not eyes.is_empty():
		holder.set_meta("eye_mat", eyes[0])
		holder.set_meta("eye_mats", eyes)  # (they all flash and turn angry together: set_glow, set_angry)
	else:
		# No eyes found on the model: the attack warning makes the whole body glow faintly instead.
		var tell := StandardMaterial3D.new()
		tell.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tell.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tell.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		tell.albedo_color = Color(1.0, 0.75, 0.4, 0.0)
		holder.set_meta("tell_mat", tell)
		holder.set_meta("eye_mat", StandardMaterial3D.new())
	if mats.has("vein"):
		holder.set_meta("vein_mat", mats["vein"])
	var glows: Array = mats.keys().filter(func(k: String) -> bool: return k.begins_with("glow")).map(func(k: String) -> StandardMaterial3D: return mats[k])
	if not glows.is_empty():
		holder.set_meta("glow_mat", glows[0])
		holder.set_meta("glow_mats", glows)
	holder.set_meta("legs", legs)
	holder.set_meta("wings", wings)
	holder.set_meta("webs", webs)
	holder.set_meta("stalks", stalks)
	holder.set_meta("peek", peek)
	holder.set_meta("blinks", blinks)
	holder.set_meta("folds", folds)
	var marker := forged.find_child("upright", true, false) as Node3D
	if marker:  # an upright-built creature (the Nov 18 bat): how high its feet are, so it hangs by them
		var low := INF
		for mi: MeshInstance3D in forged.find_children("body", "MeshInstance3D", true, false):
			var par := mi.get_parent() as Node3D
			var sc := par.scale.y if par and par != forged else 1.0
			low = minf(low, (mi.get_aabb().position.y + mi.position.y) * sc)
		holder.set_meta("upright", 0.0 if low == INF else low)
	holder.set_meta("forged_root", forged)
	holder.set_meta("flyer", shape == "cave_bat")
	holder.set_meta("rest_y", 0.0)

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
		if mi.has_meta("wing"):
			wings.append([mi, mi.rotation, float(mi.get_meta("wing"))])
		elif (mi.mesh is CylinderMesh or mi.mesh is CapsuleMesh) and mi.position.y < 0.3 and mi.position.length() > 0.05:
			# Neighbouring legs move in turns: by side and by front/back position.
			var phase := (0.0 if mi.position.x < 0.0 else PI) + mi.position.z * 6.0
			legs.append([mi, mi.rotation, phase])
	root.set_meta("legs", legs)
	root.set_meta("wings", wings)
	root.set_meta("flyer", shape == "cave_bat")
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
		mi.material_override = Look.mat(albedo, "", 0.0, 0.03)


## Every frame: walking (legs swing in turns, the body bobs and waddles, leans into the run),
## wings flap, and a slow breath when standing still. `speed` in m/s, `size` = monster size.
static func animate(model: Node3D, speed: float, size: float, clock: float) -> void:
	# Glowing parts hum: a slow breath of light, in and out (owner, round 5). Charging keeps them blazing (set_angry).
	var hum := 0.7 + 0.3 * sin(clock * 1.8)  # one breath every 3.5 s
	var blaze := 2.6 if model.get_meta("angry", false) else 1.0
	# Crystals breathe like the world's crystals (owner, Nov 18; crystal.gdshader crystal_pulse): a slow, deep breath, all
	# the way down to no glow and up much brighter, each creature its own speed (3-10 s). Other glowing parts hum.
	var seed := float(model.get_instance_id() % 9973)
	var period := 3.0 + 7.0 * fposmod(seed * 0.137, 1.0)
	var p := 0.5 - 0.5 * cos(TAU * (clock / period + fposmod(seed * 0.71, 1.0)))
	var cbreath := p * p * (3.0 - 2.0 * p)
	for g: StandardMaterial3D in model.get_meta("glow_mats", []):
		var crystal := String(g.resource_name).contains("crystal")
		g.emission_energy_multiplier = float(g.get_meta("base_energy", 1.0)) * blaze * ((0.03 + 3.5 * cbreath * cbreath) if crystal else hum)
	if model.has_meta("foot"):
		_snail(model, speed, clock)
		return
	if not model.has_meta("legs"):
		return
	var go := clampf(speed / 3.0, 0.0, 1.0)            # 0 = standing, 1 = running
	var stride := clock * (5.0 + speed * 2.5) / maxf(size, 0.6)
	for leg in model.get_meta("legs"):
		var mi: MeshInstance3D = leg[0]
		if leg.size() > 3:
			# Insect tripod walk: the planted legs push back in a straight sweep; the others lift in an
			# arc and swing forward. Standing still, all six feet rest on the ground.
			var cyc := fposmod((stride + leg[2]) / TAU + leg[4], 1.0)
			var sweep: float
			var lift := 0.0
			if cyc < 0.5:
				sweep = lerpf(-0.28, 0.28, cyc / 0.5)
			else:
				var k := (cyc - 0.5) / 0.5
				sweep = lerpf(0.28, -0.28, smoothstep(0.0, 1.0, k))
				lift = sin(k * PI) * 0.32
			mi.rotation = leg[1] + Vector3(sweep * go, 0, leg[3] * lift * go)
		else:
			mi.rotation = leg[1] + Vector3(sin(stride + leg[2]) * 0.55 * go, 0, 0)
	for st in model.get_meta("stalks", []):  # a snail looking around with its eye stalks
		var mi: MeshInstance3D = st[0]
		mi.rotation = st[1] + Vector3(sin(clock * 0.9 + st[2]) * 0.12, 0, sin(clock * 1.3 + st[2] * 2.0) * 0.16)
	if model.has_meta("forged_root") and not model.get_meta("hidden", false):
		for c in (model.get_meta("forged_root") as Node3D).get_children():
			if String(c.name) == "soft_body":  # crawling: the body stretches and squeezes in waves
				(c as Node3D).scale = Vector3(1.0 - 0.03 * sin(clock * 4.0) * go, 1.0, 1.0 + 0.06 * sin(clock * 4.0) * go)
	var roosting: bool = model.get_meta("roosting", false)
	_blinks(model, clock, float(model.get_meta("flinch_any", 0.0)), roosting)  # (the bat: shut when hit, shut asleep)
	var folds: Array = model.get_meta("folds", [])
	for f: MeshInstance3D in folds:
		f.visible = roosting  # asleep: the folded wings, wrapped round the body like a cloak
	for wing in model.get_meta("wings"):
		var mi: MeshInstance3D = wing[0]
		mi.visible = not (roosting and not folds.is_empty())
		if roosting:
			mi.rotation = wing[1] + Vector3(0, 0, -1.25 * wing[2])  # folded around the body
		else:
			var beat := sin(clock * 9.0)
			mi.rotation = wing[1] + Vector3(0, 0, beat * 0.6 * wing[2])
			if model.has_meta("forged_root") and model.get_meta("webs", []).is_empty():
				mi.scale = Vector3(1.0 - 0.22 * maxf(0.0, cos(clock * 9.0)), 1.0, 1.0)  # half-folds on the upstroke
	for web in model.get_meta("webs", []):
		var wm: MeshInstance3D = web[0]
		if roosting:
			wm.rotation = web[1]
			continue
		var depth: float = web[3]
		# a beat a little behind the arm's (a wave out along the wing), and the webs curl down on the upstroke
		var lag := sin(clock * 9.0 - 0.8 * depth)
		var curl := maxf(0.0, cos(clock * 9.0 - 0.4 * depth))
		wm.rotation = web[1] + Vector3(0, 0, web[2] * (0.24 * lag - 0.22 * curl))
	var rest_y: float = model.get_meta("rest_y")
	if roosting:
		model.position.y = rest_y
		if model.has_meta("upright"):
			# The Nov 18 bat is built upright (like the picture): flip it head-down, its feet up at the anchor
			model.rotation = Vector3(0, model.rotation.y, PI)
			model.position.y = rest_y + float(model.get_meta("upright")) * model.scale.y
		elif model.has_meta("forged_root"):
			model.rotation = Vector3(-PI / 2.0, model.rotation.y, 0.0)  # hanging head-down by its feet
		else:
			model.rotation = Vector3(0, model.rotation.y, PI)  # hanging upside down from the ceiling
		return
	if model.get_meta("flyer"):
		model.position.y = rest_y + sin(clock * 2.2) * 0.12 * size + sin(clock * 9.0) * 0.03 * size  # hovering, lifts with each beat
		if absf(model.rotation.z) > 3.0:
			model.rotation.z = 0.0  # woke up: right way up again
	else:
		var bob := absf(sin(stride)) * 0.06 * size * go
		var breath := sin(clock * 2.0) * 0.012 * size * (1.0 - go)
		model.position.y = rest_y + bob + breath
	model.rotation.x = -0.15 * go  # lean into the run


## The Rock Snail moves in hops (owner, Nov 17): the foot gathers in and the body rises, the body moves forward, then
## it drops and the foot splats out wide again. The real movement is smooth, so the hop is drawn as a step: the
## body stays behind while it gathers, catches up and gets ahead while it moves, and settles back while it splats.
## The spit (show_tell sets "spit_t0"/"spit_len"): he rears up a little, snaps forward to spit, and splats down.
## Dazed ("sway"): only the body sways; the foot stays put on the ground.
const HOP_TIME := 1.1    ## seconds per hop at walking speed
const HOP_LEN := 0.66    ## metres per hop (walking speed 0.6 m/s x HOP_TIME)
const HOP_LIFT := 0.07   ## how high the body rises (m)
const FOOT_TALL := 0.115 ## the foot's height in the model (m): it stretches up this much plus the lift
const BLINK_TIME := 0.18 ## seconds for one blink (shut and open again)
const BLINK_SHUT := 2.6 ## how far the lid turns down about its own X from where it is tucked (the build's BLINK_OPEN, undone)


static func _snail(model: Node3D, speed: float, clock: float) -> void:
	var forged: Node3D = model.get_meta("forged_root")
	var foot: MeshInstance3D = model.get_meta("foot")
	if not model.is_inside_tree():
		return
	if not model.has_meta("foot_rest"):  # where the foot sits in the model, before anything moved it
		model.set_meta("foot_rest", model.global_transform.affine_inverse() * foot.global_transform)
		model.set_meta("forged_rest", forged.position)
	# (The snail's eye stalks stay still for now: the owner asked to "stick them there and not move them at all" to
	# see how it looks, Nov 18. The sway was: rotation = rest + (sin(clock*0.9+k)*0.12, 0, sin(clock*1.3+2k)*0.16).)
	for st in model.get_meta("stalks", []):
		(st[0] as MeshInstance3D).rotation = st[1]
	if model.get_meta("hidden", false):
		forged.position = model.get_meta("forged_rest")  # settled (no hop, no sway)
		forged.rotation = Vector3(0, forged.rotation.y, 0)
		return  # in its shell: the hiding tween owns the foot (_forged_shell)
	var lift := 0.0
	var gather := 0.0    # 0 = flat foot, 1 = gathered in (narrower, taller)
	var flat := 0.0      # > 0: the splat (wider, flatter)
	var surge := 0.0     # forward (+) / behind (-) its true place, in model metres
	var pitch := 0.0     # + dips the head, - lifts it
	# Turning on the spot (Monster._turn_toward): he hops in place, the same hop as walking, without moving forward.
	var turning: bool = model.get_meta("turning", false) and speed < 0.2
	if turning:
		speed = HOP_LEN / HOP_TIME
	var go := clampf(speed / 0.4, 0.0, 1.0)
	# The hop runs on the distance he really walks, not on the clock (owner, Nov 18: "he moves backwards sometimes":
	# on the clock, starting, slowing or stopping half-way through a hop slid the body back).
	var last: float = model.get_meta("hop_clock", clock)
	var phase: float = model.get_meta("hop_phase", 0.0) + speed * clampf(clock - last, 0.0, 0.1) / HOP_LEN
	model.set_meta("hop_clock", clock)
	model.set_meta("hop_phase", phase)
	if go > 0.05:
		var cyc := fposmod(phase, 1.0)
		if cyc < 0.35:  # gather and rise
			gather = smoothstep(0.0, 1.0, cyc / 0.35)
			lift = HOP_LIFT * gather
		elif cyc < 0.65:  # move forward, still up
			gather = 1.0
			lift = HOP_LIFT
		else:  # drop and splat
			var k := (cyc - 0.65) / 0.35
			gather = 1.0 - smoothstep(0.0, 0.35, k)
			lift = HOP_LIFT * gather
			flat = sin(clampf(k / 0.8, 0.0, 1.0) * PI) * (1.0 - gather)
		var step := smoothstep(0.35, 0.65, cyc)
		# (0.6 of a full step: even the steepest part never pulls the body back while he walks forward)
		surge = 0.0 if turning else 0.6 * (step - cyc) * HOP_LEN / maxf(model.scale.x, 0.01)
		lift *= go
		gather *= go
		flat *= go
		surge *= go
	var t0: float = model.get_meta("spit_t0", -100.0)
	var p := (clock - t0) / maxf(float(model.get_meta("spit_len", 1.0)), 0.1)
	if p >= 0.0 and p < 1.5:  # the spit: rear up, snap forward, splat
		if p < 0.8:
			gather = smoothstep(0.0, 0.8, p)
			lift = 0.1 * gather
			pitch = -0.14 * gather
		elif p < 1.0:
			var k := (p - 0.8) / 0.2
			gather = 1.0
			lift = 0.1
			pitch = lerpf(-0.14, 0.12, smoothstep(0.0, 1.0, k))
			surge = 0.08 * k
		else:
			var k := (p - 1.0) / 0.5
			gather = 1.0 - smoothstep(0.0, 0.4, k)
			lift = 0.1 * gather
			pitch = 0.12 * (1.0 - k)
			surge = 0.08 * (1.0 - k)
			flat = sin(clampf(k, 0.0, 1.0) * PI) * (1.0 - gather)
	var flinch: float = model.get_meta("flinch", 0.0)  # hit: the body jolts up and back, the foot stays put
	_blinks(model, clock, flinch, false)
	model.set_meta("flinch", 0.0)
	lift += 0.06 * flinch
	pitch -= 0.3 * flinch
	surge -= 0.05 * flinch
	var sway: float = model.get_meta("sway", 0.0)
	var rest: Vector3 = model.get_meta("forged_rest")
	forged.position = rest + Vector3(0, lift, -surge)  # (monsters face -Z)
	forged.rotation = Vector3(pitch, forged.rotation.y, sway)
	# The foot: always on the ground, gathered in (and stretched up to the body) or splatted.
	var w := 1.0 - 0.18 * gather + 0.08 * flat
	var tall := (1.0 + lift / FOOT_TALL) * (1.0 - 0.15 * flat)
	var fr: Transform3D = model.get_meta("foot_rest")
	# (it steps with the body: planted while it gathers and splats, forward with the body in between)
	foot.global_transform = model.global_transform * Transform3D(fr.basis * Basis.from_scale(Vector3(w, tall, w)), fr.origin + Vector3(0, 0, -surge))
	model.position.y = model.get_meta("rest_y")
	model.rotation.x = 0.0


## Blinking (owner, Nov 18): a quick blink every few seconds (each creature its own rhythm); the eyes squeeze shut
## when it is hit (flinch) and stay shut while it sleeps. 0 = open, 1 = closed; the lid turns down about the eye's middle.
static func _blinks(model: Node3D, clock: float, flinch: float, asleep: bool) -> void:
	var lids: Array = model.get_meta("blinks", [])
	if lids.is_empty():
		return
	var every := 3.2 + fposmod(float(model.get_instance_id() % 997) * 0.37, 2.5)
	var ph := fposmod(clock, every)
	var shut := sin(ph / BLINK_TIME * PI) if ph < BLINK_TIME else 0.0
	shut = maxf(shut, clampf(flinch * 2.0, 0.0, 1.0))
	if asleep:
		shut = 1.0
	for b in lids:
		(b[0] as MeshInstance3D).basis = (b[1] as Basis) * Basis(Vector3.RIGHT, BLINK_SHUT * shut)  # (a basis: tucked this far back, its angles can read as flipped)


## Dazed (stunned): sway the snail's body only, its foot stays put (owner, Nov 17). Other creatures tip as a whole.
static func dazed_sway(model: Node3D, angle: float) -> void:
	if model.has_meta("foot"):
		model.set_meta("sway", angle)
		model.rotation.z = 0.0
	else:
		model.rotation.z = angle


## Dazed (owner F449, every creature): a ring of 4 little chunky gold stars circling over its head. Each star is
## puffed (thick in the middle, thin at the rim) with uneven points, pale in the middle and deep gold at the tips,
## and lit by itself so you see it in a dark cave. Returns the ring (hidden until the creature is dazed).
static func add_daze_stars(model: Node3D) -> Node3D:
	var ring := Node3D.new()
	ring.name = "daze_stars"
	ring.visible = false
	var head := _head_spot(model)
	ring.position = head[0]
	ring.set_meta("base_y", (head[0] as Vector3).y)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var r: float = head[1]
	for i in 4:
		var star := MeshInstance3D.new()
		star.mesh = _star_mesh(0.075 * clampf(r / 0.3, 0.8, 1.6), i)
		star.material_override = mat
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		star.set_meta("angle", TAU * i / 4.0)
		star.set_meta("radius", r)
		ring.add_child(star)
	model.add_child(ring)
	spin_daze_stars(ring, 0.0)
	return ring


## Turns the ring of stars: they go round the head, bob up and down, and each one spins.
static func spin_daze_stars(ring: Node3D, clock: float) -> void:
	ring.position.y = float(ring.get_meta("base_y", ring.position.y)) + sin(clock * 3.0) * 0.015
	for star: Node3D in ring.get_children():
		var a: float = float(star.get_meta("angle")) + clock * 3.2
		var r: float = star.get_meta("radius")
		star.position = Vector3(cos(a) * r, sin(clock * 5.0 + a * 2.0) * 0.03, sin(a) * r)
		star.rotation = Vector3(0.25, -a + clock * 4.0, 0.0)


## Where its head is, in the model's own space, and how wide a ring fits round it: above its eyes if it has any,
## otherwise over the front of its body.
static func _head_spot(model: Node3D) -> Array:
	var eye_mats: Array = model.get_meta("eye_mats", [])
	var box := AABB()
	var eyes := AABB()
	var have_box := false
	var have_eyes := false
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.visible:
			continue
		var b := _in_model(model, mi) * mi.get_aabb()
		box = b if not have_box else box.merge(b)
		have_box = true
		for i in mi.mesh.get_surface_count():
			if eye_mats.has(mi.get_active_material(i)):
				eyes = b if not have_eyes else eyes.merge(b)
				have_eyes = true
	if not have_box:
		return [Vector3(0, 0.8, 0), 0.25]
	var top := box.end.y
	var width := minf(box.size.x, box.size.z)
	if have_eyes:
		var c := eyes.get_center()
		return [Vector3(c.x, maxf(eyes.end.y + 0.18, c.y + 0.25), c.z), clampf(width * 0.3, 0.14, 0.4)]
	var front := box.position.z + box.size.z * 0.25  # (creatures face -Z)
	return [Vector3(box.get_center().x, top + 0.12, front), clampf(width * 0.3, 0.14, 0.4)]


## A node's place inside the model (its parents' transforms, up to the model).
static func _in_model(model: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var at: Node = n
	while at != null and at != model:
		if at is Node3D:
			t = (at as Node3D).transform * t
		at = at.get_parent()
	return t


## One chunky star: 5 uneven points, puffed thick in the middle, pale yellow middle, deep gold tips.
static func _star_mesh(radius: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 + seed * 31
	var rim: Array[Vector3] = []
	for k in 10:
		var a := TAU * k / 10.0 + PI / 2.0 + rng.randf_range(-0.08, 0.08)
		var d := radius * (rng.randf_range(0.9, 1.1) if k % 2 == 0 else rng.randf_range(0.42, 0.5))
		rim.append(Vector3(cos(a) * d, sin(a) * d, 0.0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mid := Color(1.0, 0.95, 0.62)
	var tip := Color(0.93, 0.6, 0.12)
	var notch := Color(0.98, 0.78, 0.3)
	for side in [1.0, -1.0]:
		var c := Vector3(0, 0, radius * 0.38 * side)
		for k in 10:
			var a := rim[k]
			var b := rim[(k + 1) % 10]
			var ca := tip if k % 2 == 0 else notch
			var cb := tip if (k + 1) % 2 == 0 else notch
			st.set_color(mid)
			st.add_vertex(c)
			if side > 0.0:
				st.set_color(ca)
				st.add_vertex(a)
				st.set_color(cb)
				st.add_vertex(b)
			else:
				st.set_color(cb)
				st.add_vertex(b)
				st.set_color(ca)
				st.add_vertex(a)
	st.generate_normals()
	return st.commit()


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


## 0 = normal eyes, 1 = bright flash (the "tell" just before a hit lands).
static func set_glow(model: Node3D, amount: float) -> void:
	if model.has_meta("tell_mat"):
		var t := model.get_meta("tell_mat") as StandardMaterial3D
		var a := amount * 0.3
		if (t.albedo_color.a > 0.0) != (a > 0.0):
			for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				if mi.material_overlay == null or mi.material_overlay == t:
					mi.material_overlay = t if a > 0.0 else null
		t.albedo_color = (Color(1.0, 0.3, 0.1) if model.get_meta("angry", false) else Color(1.0, 0.75, 0.4)) * Color(1, 1, 1, 0) + Color(0, 0, 0, a)
	# Red eyes glow less: very bright light turns white on screen (AgX tone mapping), losing the red.
	for m: StandardMaterial3D in model.get_meta("eye_mats", [model.get_meta("eye_mat")]):
		m.emission_energy_multiplier = 0.6 + amount * (0.9 if model.get_meta("angry", false) else 8.0)


## Angry eyes: they burn red-orange while a beetle winds up a charge (a warning you can read).
static func set_angry(model: Node3D, angry: bool) -> void:
	model.set_meta("angry", angry)
	for m: StandardMaterial3D in model.get_meta("eye_mats", [model.get_meta("eye_mat")]):
		m.emission = Color(1.0, 0.08, 0.0) if angry else Color(1.0, 0.85, 0.4)
		m.albedo_color = Color(0.7, 0.05, 0.0) if angry else Color(1.0, 0.9, 0.5)
	if model.has_meta("vein_mat"):  # the cracks in its stone shell glow like coals while it charges
		(model.get_meta("vein_mat") as StandardMaterial3D).emission_energy_multiplier = 2.2 if angry else 0.0
	for g: StandardMaterial3D in model.get_meta("glow_mats", [model.get_meta("glow_mat")] if model.has_meta("glow_mat") else []):
		g.emission_energy_multiplier = float(g.get_meta("base_energy", 1.0)) * (2.6 if angry else 1.0)  # its glowing parts blaze while it charges


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
