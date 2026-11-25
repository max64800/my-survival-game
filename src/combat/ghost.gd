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
const LOOKS := {"ghost_a": "a", "ghost_b": "b", "ghost_c": "c", "ghost_lord": "c", "shield_brother": "c", "hald_shade": "a", "hald_ironbrow": "c", "barrow_warden": "c", "barrow_keeper": "b"}
const MACE := "mace_silver"
const SHIELD := "shield_bronze"  ## the Shield-Brother's shield (F850)
## Each ghost's mace, reshaped from the silver mace (owner, Nov 22: "make them a lot thinner", the skeletons' thick
## weapons looked like toys; the Bearded Shade's "twice as long", the Wrathful Shade's "very long" too):
## [how long (x the mace's 0.7 m: only the bare shaft between the grip wrap and the head stretches), how thick].
## Each ghost's mace: [how long, how thin the stick, how wide the head, how long the head] (x the silver mace).
## Owner, Nov 22: the Wrathful Shade's length is right but its stick thicker and its head bigger; the Bearded Shade and
## the boss get exactly the same mace.
const MACE_SHAPE := {"a": [1.0, 0.62, 0.62, 1.0], "b": [1.6, 0.8, 1.35, 1.25], "c": [1.6, 0.8, 1.35, 1.25]}
const SHAFT := [0.23, 0.33]  ## m up the silver mace (its own model): the bare shaft, from the top of the grip wrap to the fins under the head
const RETURN_TIME := 0.6  ## s for the arms and the mace to ease back to rest after a swing
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
	dm.ready.connect(func() -> void: _dress(dm, String(LOOKS.get(kind, "a")), color, kind), CONNECT_ONE_SHOT)
	return holder


## The dwarf's own body hidden, the ghost body on his skeleton, a ghostly mace in his fist, all in the ghost shader.
static func _dress(dm: DwarfModel, look: String, color: Color, kind := "") -> void:
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
	# (owner, Nov 22: "still very fat"): no extra dwarf width under the ghost body, so it's as slim as on the 3D page
	dm.dwarf_rig.scale.x /= DwarfRig.WIDTH
	dm.dwarf_rig.scale.z /= DwarfRig.WIDTH
	# (owner, Nov 22: after every attack the mace "teleports a little bit at the last second" getting back to its
	# resting spot: the swing let go in 0.18 s, full speed to a dead stop. Now a slow, eased return.)
	dm.dwarf_rig.one_blend_out = RETURN_TIME
	dm.dwarf_rig.one_ease = true
	dm.set_held(MACE)
	var shape: Array = MACE_SHAPE.get(look, [1.0, 1.0, 1.0, 1.0])
	for mi: MeshInstance3D in dm.dwarf_rig.grip.find_children("*", "MeshInstance3D", true, false):
		mi.mesh = reshape_mace(mi.mesh, shape[0], shape[1], shape[2], shape[3])
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
	var mats := [mat, mace]
	if bool(Monsters.LIST.get(kind, {}).get("front_shield", false)):
		# F850 (owner: "hits from the front are blocked but you can't see a shield"): the Shield-Brother's old bronze
		# shield on his left arm, in the ghost shader but more solid than his body, so you see what stops your blows.
		dm.set_shield(SHIELD)
		var sh := ShaderMaterial.new()
		sh.shader = SHADER
		sh.set_shader_parameter("tint", color.lerp(Color(1.0, 0.85, 0.55), 0.35).lightened(0.25))
		sh.set_shader_parameter("use_guide", false)
		sh.set_shader_parameter("core", 0.7)
		_add_depth(sh, false)
		for mi: MeshInstance3D in dm.dwarf_rig.shield_grip.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = sh
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.add_to_group("ghost_skin")
		mats.append(sh)
	dm.set_meta("ghost_mats", mats)


static var _maces := {}  ## (the reshaped meshes, made once per mesh and shape)


## The silver mace `long` times as long and `thin` times as thick: the bare shaft stretches (the grip wrap stays a
## fist long, the head keeps its shape and moves up), and every part slims. The mesh's own space: handle up +Y.
static func reshape_mace(mesh: Mesh, long: float, thin: float, head_wide := 1.0, head_long := 1.0) -> Mesh:
	if mesh == null or (is_equal_approx(long, 1.0) and is_equal_approx(thin, 1.0) and is_equal_approx(head_wide, 1.0) and is_equal_approx(head_long, 1.0)):
		return mesh
	var key := "%d_%.2f_%.2f_%.2f_%.2f" % [mesh.get_instance_id(), long, thin, head_wide, head_long]
	if _maces.has(key):
		return _maces[key]
	var a := float(SHAFT[0])
	var b := float(SHAFT[1])
	var full := 0.7  # (the silver mace's length)
	var stretch := (full * long - a - (full - b) * head_long) / (b - a)  # the shaft's stretch that makes the whole mace `long` x
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in v.size():
			var p := v[i]
			var y := p.y
			var w := thin
			if y > b:  # the fins and the head: their own size, on top of the stretched shaft
				y = a + (b - a) * stretch + (y - b) * head_long
				w = head_wide
			elif y > a:
				y = a + (y - a) * stretch
			v[i] = Vector3(p.x * w, y, p.z * w)
		arr[Mesh.ARRAY_VERTEX] = v
		if arr[Mesh.ARRAY_NORMAL] != null:
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var v0: PackedVector3Array = mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
			for i in n.size():
				var hd := v0[i].y > b
				var w := head_wide if hd else thin
				var h := head_long if hd else stretch if v0[i].y > a else 1.0
				n[i] = Vector3(n[i].x / w, n[i].y / h, n[i].z / w).normalized()
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
## F873 (owner, Nov 25): right BEHIND the one who hit it (`hitter`), never a random spot or inside a wall; it swings
## at once when it shows there (ambush). No open spot behind or beside them: it doesn't jump at all.
## True when this hit took it past one of its quarter marks (it owes a jump, even if no spot was open).
static func jump_owed(m: Monster, hp_before: float) -> bool:
	var step := m.max_hp() / MARKS
	return m.hp > 0.0 and floori((m.max_hp() - m.hp) / step) > floori((m.max_hp() - hp_before) / step)


static func jump_after_hit(m: Monster, hp_before: float, maker: CaveMaker, hitter: Node3D = null) -> Vector3:
	if m.hp <= 0.0:
		return Vector3.INF
	var step := m.max_hp() / MARKS
	if floori((m.max_hp() - m.hp) / step) <= floori((m.max_hp() - hp_before) / step):
		return Vector3.INF
	if hitter == null:
		return Vector3.INF
	return spot_behind(m, hitter, maker, m.dungeon)


const BEHIND := 1.7  ## m behind you it comes back: inside its swing's reach, too close to just walk away from
const BODY_ROOM := 0.45  ## m of open air it needs all round its body there (no half-in-a-wall ghost, F873)
## The ways round you it tries, in turn (radians from straight behind) and how far: behind first, then a bit to
## either side, then beside you, last a little ahead of beside you (owner, Nov 25: "they stop teleporting" when you
## stand in a narrow spot). Never straight in front (you'd just see it come).
const TRY_TURNS := [0.0, 0.45, -0.45, 0.9, -0.9, 1.35, -1.35, 1.8, -1.8, 2.3, -2.3]  ## (last: beside you, a bit ahead)
const TRY_DIST := [BEHIND, BEHIND + 0.5, BEHIND - 0.4]


## Which way a player faces: their dwarf model's front (the rig faces -Z), else the way to the ghost (you face what
## you hit).
static func facing(player: Node3D, m: Node3D) -> Vector3:
	var model = player.get("model")
	var f := Vector3.ZERO
	if model is Node3D and (model as Node3D).is_inside_tree():
		f = -(model as Node3D).global_basis.z
	f.y = 0.0
	if f.length() < 0.1:
		f = (m.global_position - player.global_position) * Vector3(1, 0, 1)
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


## `m`: the ghost (any node where it stands, in the world); `dungeon`: the dungeon it is in ({} = none).
static func spot_behind(m: Node3D, player: Node3D, maker: CaveMaker, dungeon: Dictionary) -> Vector3:
	var back := -facing(player, m)
	for turn: float in TRY_TURNS:
		for dist: float in TRY_DIST:
			var spot := player.global_position + back.rotated(Vector3.UP, turn) * dist
			var ok := open_spot(m, dungeon, player.global_position, spot, maker)
			if ok != Vector3.INF:
				return ok
	return Vector3.INF


## A spot it may come back at (F873): the same floor you stand on, open air all round its body, inside the dungeon's
## rooms (not in a wall, not over its spike pit or chasm), and nothing solid between you and it (never through a wall).
## Returns the spot on the floor (+0.1 m), or Vector3.INF.
static func open_spot(m: Node3D, dungeon: Dictionary, player_pos: Vector3, at: Vector3, maker: CaveMaker) -> Vector3:
	var spot := at
	if maker != null:
		var under_you := maker.find_floor(player_pos.x, player_pos.z, player_pos.y + 1.2)  # (your floor, even mid-jump)
		var ground := under_you.y if under_you != Vector3.INF else player_pos.y
		spot = maker.find_floor(at.x, at.z, ground + 1.2)
		if spot == Vector3.INF or absf(spot.y - ground) > 0.7:
			return Vector3.INF
		for h in [0.8, 1.4]:
			if maker.sdf_at(spot + Vector3.UP * h) <= BODY_ROOM:
				return Vector3.INF
	if not dungeon.is_empty():
		var room := DungeonMap.space_at(dungeon, spot + Vector3.UP * 0.5)
		if room == "" or room in dungeon.map.get("deadly", []):
			return Vector3.INF
		if DungeonMap.sdf(dungeon, spot + Vector3.UP * 0.8) <= BODY_ROOM:
			return Vector3.INF  # (too near a room's wall line: built stone stands there)
	if m.is_inside_tree():
		var space := m.get_world_3d().direct_space_state
		var line := PhysicsRayQueryParameters3D.create(player_pos + Vector3.UP * 0.9, spot + Vector3.UP * 0.9,
			World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
		if not space.intersect_ray(line).is_empty():
			return Vector3.INF
		var body := PhysicsShapeQueryParameters3D.new()
		var ball := SphereShape3D.new()
		ball.radius = BODY_ROOM
		body.shape = ball
		body.collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
		for h in [0.95, 1.45]:  # (above the dungeon's floor tiles, 0.25 m over the rock: at knee height they "blocked" every spot)
			body.transform = Transform3D(Basis.IDENTITY, spot + Vector3.UP * h)
			if not space.intersect_shape(body, 1).is_empty():
				return Vector3.INF
	return spot + Vector3.UP * 0.35  # (over the floor tiles: it settles onto them)


## The swing it comes out of the mist with (F873, F849's idea): an overhead chop, its own blow's damage, the parry star
## first (F851). Dodge (or parry) it the moment you see the dots gather behind you.
static func ambush(data: Dictionary) -> Dictionary:
	var first: Dictionary = data.attacks[0]
	return {name = "Ambush Chop", anim = "Chop", warn_sound = "beetle_hiss", tell = AMBUSH_TELL, damage = first.damage,
		type = "blunt", reach = 3.0, parry = "any"}


const AMBUSH_TELL := 0.9  ## s from showing again to the blow (the star shows 0.4 s before it)


## Host: the ambush swing is due now (it just showed again behind you)? Once only, and not long after.
static func ambush_due(m: Monster) -> bool:
	var at := float(m.get_meta("ghost_ambush", -1.0))
	if at < 0.0:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < at:
		return false
	m.remove_meta("ghost_ambush")
	return now < at + 2.0  # (stuck dazed far longer: it just fights on)


## Everyone: it fades into mist, a trail of mist drifts to the new spot, it comes back there and rushes at you.
static func show_fade(m: Monster, to: Vector3) -> void:
	var from := m.global_position
	var model := m.model
	var now := Time.get_ticks_msec() / 1000.0
	m.set_meta("ghost_rush", now + FADE_OUT + DOTS_FLY + FADE_IN + RUSH_TIME)
	m.set_meta("ghost_hidden", now + FADE_OUT + DOTS_FLY)
	m.set_meta("ghost_ambush", now + FADE_OUT + DOTS_FLY)  # (the host swings then: ambush_due)
	if model == null or not m.is_inside_tree():
		m.global_position = to
		return
	_dots(m.get_parent(), from, to, model, true)
	var t := m.create_tween()
	t.tween_method(func(f: float) -> void: set_fade(model, f), 1.0, 0.0, FADE_OUT)
	t.tween_callback(func() -> void:
		m.global_position = to
		m.set("_net_pos", to)  # (a friend's copy doesn't glide there: it is there)
		m.velocity = Vector3.ZERO
		m.set("_knock", Vector3.ZERO)  # (the push of your hit doesn't carry it on at the new spot)
		# It shows again facing you (you stand between where it was and where it comes back; owner, Nov 25).
		var back := (from - to) * Vector3(1, 0, 1)
		if back.length() > 0.1:
			model.rotation.y = atan2(-back.x, -back.z))
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


# ================================================================== host: finding the way through doors (F872)
# Owner, Nov 25: "they struggle through doors". A ghost ran straight at you, so in the next room it pushed into the
# wall beside the doorway. Now in a dungeon it goes room by room: the rooms (the map's boxes) that meet with an
# opening at least DOOR_MIN wide are linked; it walks to the middle of the opening to the next room on the shortest
# way to you, a little through it, then on. Same room as you: straight at you, as before.
const DOOR_MIN := 1.2      ## m of shared wall two rooms need to count as joined (a doorway)
const THROUGH := 0.9       ## m past the opening's middle it aims, so it walks right through


## Which of the dungeon's boxes p is in (several where two rooms meet).
static func boxes_at(d: Dictionary, p: Vector3) -> Array[int]:
	var q := DungeonMap.to_local(d, p + Vector3.UP * 0.5)
	var out: Array[int] = []
	for i in d.boxes.size():
		var mn: Vector3 = d.boxes[i][0]
		var mx: Vector3 = d.boxes[i][1]
		if q.x > mn.x and q.x < mx.x and q.z > mn.z and q.z < mx.z and q.y > mn.y - 0.6 and q.y < mx.y:
			out.append(i)
	return out


## The links between the boxes: {i: [[j, the opening's middle (local)], ...]}. Worked out once per dungeon.
static func links(d: Dictionary) -> Dictionary:
	if d.has("ghost_links"):
		return d.ghost_links
	var out := {}
	for i in d.boxes.size():
		out[i] = []
	var deadly: Array = d.map.get("deadly", [])
	var bad := func(i: int) -> bool: return i < d.map.spaces.size() and String(d.map.spaces[i][0]) in deadly
	for i in d.boxes.size():
		if bad.call(i):
			continue  # (never the way through its spike pit or over its chasm)
		for j in range(i + 1, d.boxes.size()):
			if bad.call(j):
				continue
			var lo: Vector3 = (d.boxes[i][0] as Vector3).max(d.boxes[j][0])
			var hi: Vector3 = (d.boxes[i][1] as Vector3).min(d.boxes[j][1])
			if hi.x < lo.x - 0.05 or hi.z < lo.z - 0.05 or hi.y - lo.y < 1.6:
				continue  # (apart, or no head room where they meet)
			if maxf(hi.x - lo.x, hi.z - lo.z) < DOOR_MIN:
				continue
			var mid := Vector3((lo.x + hi.x) * 0.5, lo.y, (lo.z + hi.z) * 0.5)
			out[i].append([j, mid])
			out[j].append([i, mid])
	d.ghost_links = out
	return out


## The flat way to walk toward `goal` through the dungeon's doorways (a unit Vector3), or the straight way when it's
## in the same room, outside the dungeon, or no way is known.
static func way_to(m: Monster, goal: Vector3) -> Vector3:
	var straight := (goal - m.global_position) * Vector3(1, 0, 1)
	straight = straight.normalized() if straight.length() > 0.01 else Vector3.ZERO
	if m.dungeon.is_empty():
		return straight
	var d: Dictionary = m.dungeon
	var here := boxes_at(d, m.global_position)
	var there := boxes_at(d, goal)
	if here.is_empty() or there.is_empty():
		return straight
	for i in here:
		if i in there:
			return straight
	var next := first_door(links(d), here, there)
	if next.is_empty():
		return straight
	var from: int = next[0]
	var mid: Vector3 = next[1]
	# Aim at the opening's middle, a little through it into the next room (its box's middle side).
	var to_room: int = next[2]
	var room_mid: Vector3 = ((d.boxes[to_room][0] as Vector3) + (d.boxes[to_room][1] as Vector3)) * 0.5
	var push := (room_mid - mid) * Vector3(1, 0, 1)
	var own_mid: Vector3 = ((d.boxes[from][0] as Vector3) + (d.boxes[from][1] as Vector3)) * 0.5
	var across := (room_mid - own_mid) * Vector3(1, 0, 1)
	if across.length() > 0.01:
		push = across  # (straight through the wall line, not slanted toward the room's far corner)
	var aim := mid + (push.normalized() * THROUGH if push.length() > 0.01 else Vector3.ZERO)
	var w := DungeonMap.to_world(d, Vector3(aim.x, 0.0, aim.z))
	var dir := (w - m.global_position) * Vector3(1, 0, 1)
	return dir.normalized() if dir.length() > 0.05 else straight


## Shortest hop list (rooms walked through) from any of `starts` to any of `goals`: [the box it's in, the first
## opening's middle, the next box], or [] when they aren't joined.
static func first_door(link: Dictionary, starts: Array[int], goals: Array[int]) -> Array:
	var came := {}
	var queue: Array = []
	for s in starts:
		came[s] = -1
		queue.append(s)
	var found := -1
	while not queue.is_empty() and found < 0:
		var at: int = queue.pop_front()
		for l: Array in link.get(at, []):
			var j: int = l[0]
			if came.has(j):
				continue
			came[j] = at
			if j in goals:
				found = j
				break
			queue.append(j)
	if found < 0:
		return []
	var step := found
	while came[step] != -1 and not (came[step] in starts):
		step = came[step]
	var start: int = came[step]
	for l: Array in link[start]:
		if l[0] == step:
			return [start, l[1], step]
	return []


## Host: nothing solid (a tomb, a pillar, a wall) between it and `goal` at chest height (owner, Nov 25: Hald "is trying
## to hit me through the tomb and he can't hit me").
static func clear_to(m: Monster, goal: Vector3) -> bool:
	if not m.is_inside_tree():
		return true
	var line := PhysicsRayQueryParameters3D.create(m.global_position + Vector3.UP * 0.9, goal + Vector3.UP * 0.9,
		World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
	return m.get_world_3d().direct_space_state.intersect_ray(line).is_empty()


const AROUND_LOOK := 1.6  ## m ahead it looks for something in its way
const AROUND_TURNS := [0.5, 1.0, 1.5, 2.0]  ## radians it tries to either side to get past it


## Host: `way` bent round whatever solid stands right in front of it ("he just needs to go around it"). It keeps to
## the side it picked (meta ghost_side) so it doesn't swing left and right in front of the tomb; once the way is
## open again it forgets the side.
static func around(m: Monster, way: Vector3, goal: Vector3) -> Vector3:
	if way.length() < 0.1 or not m.is_inside_tree():
		return way
	var look := minf(AROUND_LOOK, ((goal - m.global_position) * Vector3(1, 0, 1)).length())
	if _open(m, way, look):
		m.remove_meta("ghost_side")
		return way
	var side := float(m.get_meta("ghost_side", 0.0))
	var sides := [side] if side != 0.0 else ([1.0, -1.0] if way.cross(goal - m.global_position).y >= 0.0 else [-1.0, 1.0])
	for turn: float in AROUND_TURNS:
		for sd: float in sides:
			var dir := way.rotated(Vector3.UP, turn * sd)
			if _open(m, dir, AROUND_LOOK * 0.75):
				m.set_meta("ghost_side", sd)
				return dir
	m.remove_meta("ghost_side")  # (boxed in on that side: next time it tries both)
	return way


static func _open(m: Monster, dir: Vector3, dist: float) -> bool:
	var space := m.get_world_3d().direct_space_state
	for h: float in [0.7, 1.2]:  # (above a stair step, below a doorway top)
		var a := m.global_position + Vector3.UP * h
		var q := PhysicsRayQueryParameters3D.create(a, a + dir * dist, World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
		if not space.intersect_ray(q).is_empty():
			return false
	return true
