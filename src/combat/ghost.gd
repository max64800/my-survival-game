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
const HOVER := 0.22  ## m: how high it floats above the floor
const MARKS := 4  ## it fades away after each quarter of its health
const RUSH := 1.8  ## how much faster it comes at you after a jump...
const RUSH_TIME := 2.0  ## ...for this long (s)
const JUMP_MIN := 3.0  ## how far it jumps (m)
const JUMP_MAX := 5.5
const FADE_OUT := 0.18  ## s into mist
const FADE_IN := 0.4  ## s back out of it


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
	m.set_meta("ghost_rush", Time.get_ticks_msec() / 1000.0 + FADE_OUT + FADE_IN + RUSH_TIME)
	if model == null or not m.is_inside_tree():
		m.global_position = to
		return
	_mist_trail(m.get_parent(), from + Vector3.UP * 0.7, to + Vector3.UP * 0.7, model)
	var t := m.create_tween()
	t.tween_method(func(f: float) -> void: set_fade(model, f), 1.0, 0.0, FADE_OUT)
	t.tween_callback(func() -> void:
		m.global_position = to
		m.set("_net_pos", to)  # (a friend's copy doesn't glide there: it is there)
		m.velocity = Vector3.ZERO)
	t.tween_interval(0.08)
	t.tween_method(func(f: float) -> void: set_fade(model, f), 0.0, 1.0, FADE_IN)


## How much faster it moves now (the rush after a jump), 1 = normal.
static func rush(m: Monster) -> float:
	return RUSH if Time.get_ticks_msec() / 1000.0 < float(m.get_meta("ghost_rush", 0.0)) else 1.0


## A line of soft mist puffs from where it was to where it went, each fading away (glowing in its colour).
static func _mist_trail(parent: Node, a: Vector3, b: Vector3, model: Node3D) -> void:
	if parent == null:
		return
	var col := Color(0.6, 0.95, 0.9)
	var ms := mats(model)
	if not ms.is_empty():
		col = (ms[0] as ShaderMaterial).get_shader_parameter("tint")
	var n := clampi(ceili(a.distance_to(b) / 0.45), 3, 14)
	for i in n + 1:
		var puff := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.22
		ball.height = 0.4
		ball.radial_segments = 10
		ball.rings = 5
		puff.mesh = ball
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(col.r, col.g, col.b, 0.35)
		puff.material_override = mat
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.add_to_group("ghost_mist")
		parent.add_child(puff)
		var t0 := float(i) / n
		puff.global_position = a.lerp(b, t0) + Vector3(sin(i * 2.1) * 0.15, sin(i * 1.3) * 0.12, cos(i * 1.7) * 0.15)
		puff.scale = Vector3.ONE * (0.6 + 0.5 * sin(t0 * PI))
		var tw := puff.create_tween()
		tw.tween_interval(t0 * FADE_OUT * 1.5)
		tw.set_parallel(true)
		tw.tween_property(puff, "scale", puff.scale * 1.8, 1.1)
		tw.tween_property(mat, "albedo_color:a", 0.0, 1.1)
		tw.tween_property(puff, "position:y", puff.position.y + 0.4, 1.1)
		tw.chain().tween_callback(puff.queue_free)


## Its death: no bones, no stone. It rises a little and fades into mist, then it is gone (the monster is already off
## the list, can't be hit and doesn't move: it just stays for the fade).
static func vanish(m: Monster) -> void:
	var model := m.model
	if model == null:
		m.queue_free.call_deferred()
		return
	_mist_trail(m.get_parent(), model.global_position + Vector3.UP * 0.4, model.global_position + Vector3.UP * 1.2, model)
	var t := m.create_tween()
	t.set_parallel(true)
	t.tween_method(func(f: float) -> void: set_fade(model, f), 1.0, 0.0, 1.2)
	t.tween_property(model, "position:y", model.position.y + 0.5, 1.2)
	t.chain().tween_callback(func() -> void:
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = null  # (let go of the ghost shader first: freeing it with the body upsets the renderer)
		m.queue_free())
