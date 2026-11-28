class_name Fx
## Little visual effects: rock bits flying when you dig, plus a puff of dust.
## The chunks are lumpy, painted little rocks (Look.mat) that tumble and fall; bright colours
## (crystals, sparks off rock that's too hard) glow instead. Only looks: nothing to sync.

static var _chunk_mesh: Mesh
static var _dust_tex: Texture2D
static var _chunk_mats := {}


## `dir` / `spread`: which way they fly (a hit sprays its sparks away from the hitter: owner, Nov 18, "juicy hits").
static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 10, speed: float = 3.0, dir := Vector3.UP, spread := 70.0, puff := true, size := 1.0) -> void:
	var glowing := color.v > 0.85 and color.s < 0.6 or color.v > 0.95
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.9 if not glowing else 0.45
	p.explosiveness = 0.95
	p.randomness = 0.5
	p.direction = dir.normalized() if dir.length() > 0.01 else Vector3.UP
	p.spread = spread
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
	p.scale_amount_min = (0.35 if not glowing else 0.2) * size
	p.scale_amount_max = (1.1 if not glowing else 0.5) * size
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
	if puff and not glowing and amount >= 6:
		dust(parent, pos, color.lerp(Color(0.55, 0.5, 0.45), 0.5), clampi(amount / 3, 3, 10))


## What a creature is made of, for the bits that fly off when you hit it (F717, owner Nov 22/23: "stone gives sparks, a
## skeleton throws off bits in its own bone-white, a creature a splat"). Anything not listed is flesh.
const HIT_BODY := {
	"rock_snail": "rock", "rock_beetle": "rock", "great_rock_beetle": "rock",
	"tunnel_rat": "bone", "lost_miner": "bone", "foreman": "bone", "prop_warden": "bone", "vault_captain": "bone", "vault_guard": "bone",
	"ghost_a": "ghost", "ghost_b": "ghost", "ghost_c": "ghost", "ghost_lord": "ghost", "shield_brother": "ghost", "hald_shade": "ghost", "hald_ironbrow": "ghost", "barrow_warden": "ghost", "barrow_keeper": "ghost",
	"cave_spider": "ichor",
}


static func hit_body(kind: String) -> String:
	return HIT_BODY.get(kind, "flesh")


## A weapon lands: little bits fly away from the hitter, right where the weapon touched, matched to what was hit.
## rock = sparks + chips of its own rock colour + dust; bone = bone-white chips + a little dust; ghost = cold glowing
## wisps; flesh/ichor = a splat of drops (no dust). A crit adds a bright flash ring; heavy = more and faster.
static func hit(parent: Node, pos: Vector3, body: String, dir: Vector3, heavy := false, crit := false, tint := Color(0.5, 0.45, 0.4)) -> void:
	var n := (14 if heavy else 9) + (6 if crit else 0)
	var sp := 4.5 if heavy else 3.2
	var big := 1.7  # (owner, Nov 23: "I can barely see them": bigger bits, and a fan out to the left and right)
	var fan := Color(0.55, 0.07, 0.05)
	match body:
		"rock":
			burst(parent, pos, Color(1.0, 0.8, 0.4), n / 2, sp * 1.2, dir, 60.0, true, big)  # sparks (glow)
			burst(parent, pos, tint.darkened(0.15), n, sp * 0.8, dir, 75.0, true, big)  # chips of its own rock
			fan = tint.darkened(0.15)
		"bone":
			burst(parent, pos, Color(0.82, 0.78, 0.66), n, sp * 0.9, dir, 75.0, true, big)
			fan = Color(0.82, 0.78, 0.66)
		"ghost":
			burst(parent, pos, Color(0.7, 0.95, 1.0), n / 2, sp * 0.5, Vector3.UP, 85.0, true, big)
			fan = Color(0.7, 0.95, 1.0)
		"ichor":
			burst(parent, pos, Color(0.38, 0.5, 0.12), n, sp, dir, 75.0, false, big)
			fan = Color(0.38, 0.5, 0.12)
		_:
			burst(parent, pos, Color(0.55, 0.07, 0.05), n, sp, dir, 75.0, false, big)
	# Start in the middle, then spread wide: a fan of bits sideways, to the left and to the right of the hit.
	var side := dir.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.05 else Vector3.RIGHT
	for sgn in [-1.0, 1.0]:
		burst(parent, pos, fan, maxi(n / 2, 3), sp * 1.1, side * sgn + Vector3.UP * 0.25, 35.0, false, big)
	if crit:
		burst(parent, pos, Color(1.0, 0.95, 0.7), 10, sp * 1.3, dir, 180.0, true, big)  # a bright ring of sparks all around


## A perfect parry (F870, owner Nov 25: "no words: a bright spark star on the weapons"): a white-hot star of sparks
## flying out all around where the weapons meet, a ring of them sideways, and a quick flash of light. Returns the flash.
static func parry_star(parent: Node, pos: Vector3, facing: Vector3) -> OmniLight3D:
	var hot := Color(1.0, 0.97, 0.9)
	burst(parent, pos, hot, 22, 6.5, Vector3.UP, 180.0, false, 1.5)  # the star: every way at once
	var side := facing.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.05 else Vector3.RIGHT
	for sgn in [-1.0, 1.0]:  # two long streaks out to the sides, like blades scraping
		burst(parent, pos, hot, 8, 8.0, side * sgn, 12.0, false, 1.2)
	var flash := OmniLight3D.new()
	flash.name = "ParryFlash"
	flash.light_color = Color(1.0, 0.93, 0.8)
	flash.light_energy = 6.0
	flash.omni_range = 4.5
	parent.add_child(flash)
	flash.global_position = pos
	var t := flash.create_tween()
	t.tween_property(flash, "light_energy", 0.0, 0.22)
	t.tween_callback(flash.queue_free)
	return flash


## A soft puff of dust that drifts up and fades (digging, landing, things breaking).
## `extents` > 0 = spread over a box that size around `pos` (a new piece's foot, F724).
static func dust(parent: Node, pos: Vector3, color: Color, amount: int = 5, size: float = 0.45, extents := Vector3.ZERO) -> void:
	var p := CPUParticles3D.new()
	if extents != Vector3.ZERO:
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = extents
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
		Mat.PATH: return Color(0.52, 0.52, 0.54)  # the old grey brick road (F900)
		Mat.COPPER: return Color(0.9, 0.55, 0.25)
		Mat.TIN: return Color(0.7, 0.72, 0.74)
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


## F775 (owner, Nov 22: "I don't feel that I'm running"): what a sprinting dwarf's heels throw up, per floor.
## {dust: cloud colour, bits: colour of the little flying bits (none = no bits), n: how many bits}.
const RUN_KICK := {
	"rock": {dust = Color(0.5, 0.45, 0.38), bits = Color(0.42, 0.38, 0.33), n = 3},
	"dirt": {dust = Color(0.55, 0.42, 0.3), bits = Color(0.4, 0.29, 0.2), n = 4},
	"moss": {dust = Color(0.45, 0.5, 0.33), bits = Color(0.3, 0.45, 0.2), n = 4},
	"fungus": {dust = Color(0.85, 0.83, 0.75), bits = Color(0.92, 0.9, 0.82), n = 3},  # pale spores off the mycelium
	"wood": {dust = Color(0.8, 0.68, 0.48), bits = Color(0.0, 0.0, 0.0, 0.0), n = 0},  # light sawdust, nothing flies
	"stone": {dust = Color(0.62, 0.6, 0.57), bits = Color(0.5, 0.49, 0.47), n = 2},  # dungeon or built stone: grey grit
	"brick": {dust = Color(0.72, 0.5, 0.4), bits = Color(0.6, 0.35, 0.27), n = 2},
	"metal": {dust = Color(0.5, 0.48, 0.45), bits = Color(0.0, 0.0, 0.0, 0.0), n = 0},
}


## One running step's kick: a cloud thrown back and up behind his heel, and a few bits of the floor.
## `back` = the way behind him (flat). `amount`/`size` come from DwarfFeel.
static func run_kick(parent: Node, pos: Vector3, back: Vector3, surface: String, amount: int, size: float, see := 0.5) -> void:
	var k: Dictionary = RUN_KICK.get(surface, RUN_KICK.rock)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = maxi(1, amount)
	p.lifetime = 1.1
	p.explosiveness = 0.85
	p.randomness = 0.4
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12
	p.direction = (back.normalized() + Vector3.UP * 0.6).normalized()
	p.spread = 30.0
	p.initial_velocity_min = 0.9
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, -0.3, 0)
	p.damping_min = 2.0
	p.damping_max = 3.5
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.8))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, see))  # (see = how solid the cloud starts: 0.5 sprint, faint for walking)
	fade.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = fade
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_color = k.dust
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
	if int(k.n) > 0 and see >= 0.4:  # (no flying bits from a walking step; under 6, so burst() adds no second cloud of its own)
		burst(parent, pos + Vector3.UP * 0.05, k.bits, int(k.n), 2.2, back + Vector3.UP * 0.8, 35.0)


## F724 (owner, Nov 22): a little puff as a piece goes up, different for each material.
## wood = pale chips + sawdust, brick = red chips + red dust, metal = a few sparks, the rest (stone) = grit + grey dust.
static func build_dust_kind(family: String) -> String:
	if family in Pieces.WOODS or family.begins_with("plank"):
		return "wood"
	if family.contains("brick"):
		return "brick"
	if family.ends_with("_ingot"):
		return "metal"
	return "stone"


## {chips: colour of the flying bits, dust: colour of the cloud} for a material.
static func build_dust_colors(family: String) -> Dictionary:
	var base: Color = Pieces.FAMILIES.get(family, {}).get("color", Color(0.55, 0.5, 0.45))
	match build_dust_kind(family):
		"wood":  # fresh-cut wood is paler than the planks
			return {chips = base.lightened(0.25), dust = Color(0.8, 0.68, 0.48)}
		"brick":
			return {chips = base.darkened(0.1), dust = base.lerp(Color(0.8, 0.5, 0.38), 0.5)}
		"metal":
			return {chips = Color(1.0, 0.8, 0.45), dust = Color(0.5, 0.48, 0.45)}
	return {chips = base, dust = base.lerp(Color(0.75, 0.73, 0.7), 0.5)}


static var _wood_chip: Mesh


## The puff around the foot of a new piece. `box` = the piece's space in the world.
static func build_puff(parent: Node, box: AABB, family: String) -> void:
	var kind := build_dust_kind(family)
	var cols := build_dust_colors(family)
	var foot := Vector3(box.get_center().x, box.position.y + minf(box.size.y, 0.6) * 0.5, box.get_center().z)
	var spread := Vector3(box.size.x * 0.4, minf(box.size.y, 0.6) * 0.3, box.size.z * 0.4)
	var big := clampf(box.size.x * box.size.z, 0.3, 6.0)  # bigger pieces, bigger puff
	if kind == "metal":
		burst(parent, foot, cols.chips, 5, 2.5)  # glowing sparks
	else:
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.emitting = false
		p.amount = int(clampf(big * 4.0, 5, 18))
		p.lifetime = 0.8
		p.explosiveness = 0.9
		p.randomness = 0.5
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = spread
		p.direction = Vector3.UP
		p.spread = 75.0
		p.initial_velocity_min = 1.0
		p.initial_velocity_max = 2.4
		p.gravity = Vector3(0, -12, 0)
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -500.0
		p.angular_velocity_max = 500.0
		p.particle_flag_rotate_y = true
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.0
		var shrink := Curve.new()
		shrink.add_point(Vector2(0.0, 1.0))
		shrink.add_point(Vector2(0.7, 1.0))
		shrink.add_point(Vector2(1.0, 0.0))
		p.scale_amount_curve = shrink
		p.mesh = _chip() if kind == "wood" else _chunk()
		p.material_override = _chunk_mat(cols.chips, false)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(p)
		p.global_position = foot
		p.emitting = true
		p.finished.connect(p.queue_free)
	# The soft cloud, spread along the piece's foot.
	dust(parent, foot, cols.dust, int(clampf(big * 3.0, 4, 14)), 0.5 if kind == "wood" else 0.6, spread)


## A thin wood chip (a shaving off a plank).
static func _chip() -> Mesh:
	if _wood_chip == null:
		var b := BoxMesh.new()
		b.size = Vector3(0.09, 0.012, 0.035)
		_wood_chip = b
	return _wood_chip
