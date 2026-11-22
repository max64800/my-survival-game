class_name Ghost
extends RefCounted
## The dungeon ghosts of the medium dungeons (#5-#8, Claude, Nov 22, 2026; owner: "the ghost uses the dwarf's skeleton
## and his moves"). A ghost is a dwarf model (DwarfModel: his skeleton, his mace swings, his grip) wearing a ghost body
## instead of his own (assets/models/creatures/ghost_<look>.glb, built by tools/asset_forge/builds/ghost_body.py),
## all painted with the ghost shader (src/art/ghost.gdshader). It floats: no feet, a misty tail (no sliding feet, F577).
##
## Three ghosts, each with its own mace move, and a boss with all four (Monsters: ghost_a/b/c, ghost_lord).
## After every quarter of its health it fades into mist and comes back a few metres away, then rushes at you
## (co-op: the host picks the spot, MonsterManager.ghost_fade tells everyone, everyone sees the same jump).

const SHADER := preload("res://src/art/ghost.gdshader")
const DEPTH := preload("res://src/art/ghost_depth.gdshader")  ## its front surface first: no tearing where it folds over itself
const BODY := "res://assets/models/creatures/ghost_%s.glb"
const LOOKS := {"ghost_a": "a", "ghost_b": "b", "ghost_c": "c", "ghost_lord": "c"}
const MACE := "mace_silver"
## Each ghost's mace, reshaped from the silver mace (owner, Nov 22: "make them a lot thinner", the skeletons' thick
## weapons looked like toys; the Bearded Shade's "twice as long", the Wrathful Shade's "very long" too):
## [how long (x the mace's 0.7 m: only the bare shaft between the grip wrap and the head stretches), how thick].
const MACE_SHAPE := {"a": [1.0, 0.62], "b": [1.6, 0.6], "c": [2.0, 0.58]}
const SHAFT := [0.23, 0.33]  ## m up the silver mace (its own model): the bare shaft, from the top of the grip wrap to the fins under the head
const HOVER := 0.22  ## m: how high it floats above the floor
const MARKS := 4  ## it fades away after each quarter of its health
const RUSH := 1.8  ## how much faster it comes at you after a jump...
const RUSH_TIME := 2.0  ## ...for this long (s)
const JUMP_MIN := 3.0  ## how far it jumps (m)
const JUMP_MAX := 5.5
const FADE_OUT := 0.18  ## s into mist
const FADE_IN := 0.4  ## s back out of it
const DOTS := 140  ## F659: it breaks into this many small glowing dots that fly to the new spot and gather there
const DOTS_FLY := 0.6  ## s the dots take from its old body to its new one (it is invisible for this long)


## The model (MonsterModel.build: shape "ghost"). The dwarf inside builds when it enters the scene, then gets dressed.
static func build_model(kind: String, color: Color, size: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "GhostModel"
	holder.set_meta("ghost_model", true)
	holder.set_meta("eye_mat", StandardMaterial3D.new())  # (its eyes glow in its own shader: the tell flash has nothing to light)
	holder.scale = Vector3.ONE * size
	var dm := DwarfModel.new()
	dm.name = "Ghost"
	dm.position.y = HOVER
	holder.add_child(dm)
	dm.ready.connect(func() -> void: _dress(dm, String(LOOKS.get(kind, "a")), color), CONNECT_ONE_SHOT)
	return holder


## The dwarf's own body hidden, the ghost body on his skeleton, a ghostly mace in his fist, all in the ghost shader.
static func _dress(dm: DwarfModel, look: String, color: Color) -> void:
	if dm.dwarf_rig == null or not ResourceLoader.exists(BODY % look):
		return
	for mi: MeshInstance3D in dm.find_children("*", "MeshInstance3D", true, false):
		mi.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("tint", color)
	_add_depth(mat, true)
	var src: Node = (load(BODY % look) as PackedScene).instantiate()
	for mi: MeshInstance3D in src.find_children("ghost_*", "MeshInstance3D", true, false):
		dm.dwarf_rig._bind_to_skeleton(mi)
		mi.material_override = mat
		mi.material_overlay = null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_to_group("ghost_skin")
	src.free()
	dm.set_held(MACE)
	var shape: Array = MACE_SHAPE.get(look, [1.0, 1.0])
	for mi: MeshInstance3D in dm.dwarf_rig.grip.find_children("*", "MeshInstance3D", true, false):
		mi.mesh = reshape_mace(mi.mesh, shape[0], shape[1])
	var mace := ShaderMaterial.new()
	mace.shader = SHADER
	mace.set_shader_parameter("tint", color.lightened(0.35))
	mace.set_shader_parameter("use_guide", false)
	mace.set_shader_parameter("core", 0.35)
	_add_depth(mace, false)
	for mi: MeshInstance3D in dm.dwarf_rig.grip.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = mace
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_to_group("ghost_skin")
	dm.set_meta("ghost_mats", [mat, mace])


static var _maces := {}  ## (the reshaped meshes, made once per mesh and shape)


## The silver mace `long` times as long and `thin` times as thick: the bare shaft stretches (the grip wrap stays a
## fist long, the head keeps its shape and moves up), and every part slims. The mesh's own space: handle up +Y.
static func reshape_mace(mesh: Mesh, long: float, thin: float) -> Mesh:
	if mesh == null or (is_equal_approx(long, 1.0) and is_equal_approx(thin, 1.0)):
		return mesh
	var key := "%d_%.2f_%.2f" % [mesh.get_instance_id(), long, thin]
	if _maces.has(key):
		return _maces[key]
	var a := float(SHAFT[0])
	var b := float(SHAFT[1])
	var full := 0.7  # (the silver mace's length)
	var stretch := (full * long - full + (b - a)) / (b - a)  # the shaft's stretch that makes the whole mace `long` x
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in v.size():
			var p := v[i]
			var y := p.y
			if y > b:
				y += (b - a) * (stretch - 1.0)
			elif y > a:
				y = a + (y - a) * stretch
			v[i] = Vector3(p.x * thin, y, p.z * thin)
		arr[Mesh.ARRAY_VERTEX] = v
		if arr[Mesh.ARRAY_NORMAL] != null:
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in n.size():
				n[i] = Vector3(n[i].x / thin, n[i].y, n[i].z / thin).normalized()
			arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_TANGENT] = null
		out.add_surface_from_arrays(mesh.surface_get_primitive_type(si), arr)
		out.surface_set_material(si, mesh.surface_get_material(si))
	_maces[key] = out
	return out


## The depth pass drawn just before it (ghost_depth.gdshader: lower render_priority, so it goes first).
static func _add_depth(mat: ShaderMaterial, guide: bool) -> void:
	var d := ShaderMaterial.new()
	d.shader = DEPTH
	d.set_shader_parameter("use_guide", guide)
	d.render_priority = -1
	mat.next_pass = d


static func mats(model: Node3D) -> Array:
	var dm := model.get_node_or_null("Ghost")
	return dm.get_meta("ghost_mats", []) if dm else []


static func set_fade(model: Node3D, f: float) -> void:
	for m: ShaderMaterial in mats(model):
		m.set_shader_parameter("fade", f)
		if m.next_pass is ShaderMaterial:
			(m.next_pass as ShaderMaterial).set_shader_parameter("fade", f)


## Host: a hit took it past a quarter mark? Returns where it jumps to, or Vector3.INF (no jump).
static func jump_after_hit(m: Monster, hp_before: float, maker: CaveMaker) -> Vector3:
	if m.hp <= 0.0:
		return Vector3.INF
	var step := m.max_hp() / MARKS
	if floori((m.max_hp() - m.hp) / step) <= floori((m.max_hp() - hp_before) / step):
		return Vector3.INF
	return pick_spot(m.global_position, m.uid + floori(m.hp), maker)


## A floor spot a few metres away with room to stand (the ghost's blink, like the old _try_blink).
static func pick_spot(from: Vector3, seed: int, maker: CaveMaker) -> Vector3:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for i in 10:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, r.randf() * TAU)
		var spot := from + dir * r.randf_range(JUMP_MIN, JUMP_MAX)
		if maker == null:
			return spot
		spot = maker.find_floor(spot.x, spot.z, from.y + 1.5)
		if absf(spot.y - from.y) <= 2.0 and maker.sdf_at(spot + Vector3.UP * 0.8) > 0.3 \
				and maker.sdf_at(spot + Vector3.UP * 1.4) > 0.3:
			return spot + Vector3.UP * 0.1
	return Vector3.INF


## Everyone: it fades into mist, a trail of mist drifts to the new spot, it comes back there and rushes at you.
static func show_fade(m: Monster, to: Vector3) -> void:
	var from := m.global_position
	var model := m.model
	var now := Time.get_ticks_msec() / 1000.0
	m.set_meta("ghost_rush", now + FADE_OUT + DOTS_FLY + FADE_IN + RUSH_TIME)
	m.set_meta("ghost_hidden", now + FADE_OUT + DOTS_FLY)
	if model == null or not m.is_inside_tree():
		m.global_position = to
		return
	_dots(m.get_parent(), from, to, model, true)
	var t := m.create_tween()
	t.tween_method(func(f: float) -> void: set_fade(model, f), 1.0, 0.0, FADE_OUT)
	t.tween_callback(func() -> void:
		m.global_position = to
		m.set("_net_pos", to)  # (a friend's copy doesn't glide there: it is there)
		m.velocity = Vector3.ZERO)
	t.tween_interval(DOTS_FLY - 0.1)  # (it starts to show again as the last dots arrive)
	t.tween_method(func(f: float) -> void: set_fade(model, f), 0.0, 1.0, FADE_IN)


## How much faster it moves now (the rush after a jump), 1 = normal.
static func rush(m: Monster) -> float:
	return RUSH if Time.get_ticks_msec() / 1000.0 < float(m.get_meta("ghost_rush", 0.0)) else 1.0


## True while it is only dots (between fading out and coming back): it waits there, unseen.
static func hidden(m: Monster) -> bool:
	return Time.get_ticks_msec() / 1000.0 < float(m.get_meta("ghost_hidden", 0.0))


## F659: it breaks into lots of small glowing dots (its own colour). They burst out of its body, swirl through the air
## to `b` and, with `gather`, form its body again there (then fade as it shows again). Without `gather` (its death)
## they drift up and apart and fade out. One MultiMesh = one draw call; each dot follows its own curve.
## (Not GPUParticles3D: particles can't be sent to an exact spot to rebuild the body there.)
static func _dots(parent: Node, a: Vector3, b: Vector3, model: Node3D, gather: bool) -> void:
	if parent == null:
		return
	var col := Color(0.6, 0.95, 0.9)
	var ms := mats(model)
	if not ms.is_empty():
		col = (ms[0] as ShaderMaterial).get_shader_parameter("tint")
	col = col.lightened(0.35)
	var size := model.global_transform.basis.get_scale().y if model.is_inside_tree() else 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(a.round()))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _dot_mesh()
	mm.instance_count = DOTS
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_to_group("ghost_dots")
	parent.add_child(node)
	node.global_transform = Transform3D.IDENTITY
	node.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 100, 100))  # (it moves its dots itself: never cull it)
	# each dot: where it starts (in the old body), its curve's two pull points, where it ends, when it leaves, how long
	var p0: Array[Vector3] = []
	var p1: Array[Vector3] = []
	var p2: Array[Vector3] = []
	var p3: Array[Vector3] = []
	var go: Array[float] = []
	var fly: Array[float] = []
	var big: Array[float] = []
	var trip := FADE_OUT + DOTS_FLY if gather else 1.3
	for i in DOTS:
		var start := a + _body_point(rng) * size
		var out := (start - a) * Vector3(1, 0, 1)
		out = (out.normalized() if out.length() > 0.01 else Vector3.RIGHT) * rng.randf_range(0.4, 1.0) * size
		out.y = rng.randf_range(-0.1, 0.5) * size
		var end := b + _body_point(rng) * size if gather else a + Vector3(0, rng.randf_range(0.8, 1.8), 0) * size \
				+ out * 1.6
		p0.append(start)
		p1.append(start + out * 1.3)
		var out2 := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.0, 0.8), rng.randf_range(-1, 1)) * 0.7 * size
		p2.append(end + out2 if gather else end - out * 0.4)
		p3.append(end)
		var leave := rng.randf_range(0.0, FADE_OUT)
		go.append(leave)
		fly.append(trip - leave - rng.randf_range(0.0, 0.12))
		big.append(rng.randf_range(0.6, 1.4) * size)
	var total := trip + (FADE_IN if gather else 0.0)
	var now: Array[Vector3] = p0.duplicate()
	mm.set_meta("dots", now)  # (where each dot is now: the tests read it, a headless run doesn't keep MultiMesh spots)
	var step := func(t: float) -> void:
		for i in DOTS:
			var u := clampf((t - go[i]) / fly[i], 0.0, 1.0)
			var e := u * u * (3.0 - 2.0 * u)
			var k := 1.0 - e
			var pos := p0[i] * k * k * k + p1[i] * 3.0 * k * k * e + p2[i] * 3.0 * k * e * e + p3[i] * e * e * e
			var w := sin(u * PI) * 0.12 * size  # (a little swirl on the way)
			pos += Vector3(sin(t * 9.0 + i), cos(t * 7.0 + i * 1.7), cos(t * 8.0 + i * 2.3)) * w
			var alpha := clampf(t / 0.08, 0.0, 1.0)
			if gather:
				alpha *= 1.0 - clampf((t - trip) / FADE_IN, 0.0, 1.0)  # (gathered: they melt into its body as it shows)
			else:
				alpha *= 1.0 - u * u
			now[i] = pos
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * big[i] * (0.6 + 0.4 * alpha)), pos))
			mm.set_instance_color(i, Color(col.r, col.g, col.b, alpha))
	step.call(0.0)
	var tw := node.create_tween()
	tw.tween_method(step, 0.0, total, total)
	tw.tween_callback(node.queue_free)


## A random spot inside a ghost's body (feet at 0, about 1.7 m tall, widest at the shoulders).
static func _body_point(rng: RandomNumberGenerator) -> Vector3:
	var h := rng.randf_range(0.05, 1.7)
	var r := (0.12 + 0.28 * sin(clampf(h / 1.7, 0.0, 1.0) * PI * 0.85)) * sqrt(rng.randf())
	return Vector3(0, h, 0) + Vector3.FORWARD.rotated(Vector3.UP, rng.randf() * TAU) * r


static var _dot: QuadMesh


## One small round glowing dot that always faces you (shared by every ghost).
static func _dot_mesh() -> QuadMesh:
	if _dot != null:
		return _dot
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 32
	tex.height = 32
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.8))
	tex.gradient = g
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	_dot = QuadMesh.new()
	_dot.size = Vector2(0.05, 0.05)
	_dot.material = mat
	return _dot


## Its death: no bones, no stone. It rises a little and fades into mist, then it is gone (the monster is already off
## the list, can't be hit and doesn't move: it just stays for the fade).
static func vanish(m: Monster) -> void:
	var model := m.model
	if model == null:
		m.queue_free.call_deferred()
		return
	_dots(m.get_parent(), model.global_position, model.global_position, model, false)
	var t := m.create_tween()
	t.set_parallel(true)
	t.tween_method(func(f: float) -> void: set_fade(model, f), 1.0, 0.0, 1.2)
	t.tween_property(model, "position:y", model.position.y + 0.5, 1.2)
	t.chain().tween_callback(func() -> void:
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = null  # (let go of the ghost shader first: freeing it with the body upsets the renderer)
		m.queue_free())
