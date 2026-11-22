class_name CaveCritters
extends Node3D
## Tiny harmless cave life (owner, Nov 18, F190): glowing beetles crawling over the walls, little moths fluttering round
## crystals (or round you and your lantern), pale cave crickets on the floor that hop away when you come near. Only looks,
## only on your own screen, and only near the camera: they're moved to new spots near you when you walk away.
## Models: tools/asset_forge/builds/critters.py.

const BEETLES := 5   ## (owner, Nov 19: "too many bugs crawling around", was 14)
const MOTHS := 10
const MOTH_SLOW := 0.35  ## m/s a moth's calmest flight (F630: they flew 0.6-4 m/s with darts: "too fast")
const MOTH_FAST := 0.75
const MOTH_STEER := 1.5  ## how quickly its flight bends to a new way (was 4: sharp turns)
const MOTH_TURN := 2.5   ## radians a second its body swings round to a new way, at most (it used to snap round at once)
const CRICKETS := 3  ## (owner, Nov 19: "that many crickets", was 10)
const NEAR := 26.0  ## further than this from the camera: moved to a new spot near it
const BEETLE_SPEED := 0.08
const CRICKET_SCARE := 2.5

var world: World
var maker: CaveMaker
var glow: GlowField
var _beetles: Array[Dictionary] = []  ## {node, dir: Vector3}
var _moths: Array[Dictionary] = []  ## {node, wings: [Node3D, Node3D], anchor, phase}
var _crickets: Array[Dictionary] = []  ## {node, hop: float (time left), from, to}
var _rng := RandomNumberGenerator.new()


func setup(p_world: World, p_glow: GlowField) -> void:
	world = p_world
	maker = p_world.maker
	glow = p_glow
	_rng.randomize()
	world.changed.connect(_on_rock_changed)
	for i in BEETLES:
		_beetles.append({node = _model("glow_beetle"), dir = Vector3.FORWARD})
	for i in MOTHS:
		var body := _model("moth_body")
		var wings := []
		for side in [-1, 1]:
			var hinge := Node3D.new()
			body.add_child(hinge)
			hinge.position = Vector3(0.0, 0.015, 0.0)
			var w := _model("moth_wing", hinge)
			if side < 0:
				w.scale = Vector3(-1, 1, 1)  # the left wing: the right one mirrored
			wings.append(hinge)
		_moths.append({node = body, wings = wings, anchor = Vector3.INF, phase = _rng.randf() * TAU, goal = Vector3.ZERO,
			vel = Vector3.ZERO, wait = 0.0, speed = _rng.randf_range(MOTH_SLOW, MOTH_FAST), wob = _rng.randf_range(1.5, 3.5)})
	for i in CRICKETS:
		_crickets.append({node = _model("cave_cricket"), hop = 0.0, from = Vector3.ZERO, to = Vector3.ZERO})
	for c in _beetles + _moths + _crickets:
		(c.node as Node3D).visible = false


func _model(id: String, parent: Node = null) -> Node3D:
	var scene := load("res://assets/models/critters/%s.glb" % id) as PackedScene
	var n: Node3D = scene.instantiate() if scene else Node3D.new()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(n)
	return n


func _process(delta: float) -> void:
	if world == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var at := cam.global_position
	for b in _beetles:
		_beetle(b, at, delta)
	for m in _moths:
		_moth(m, at, delta)
	for c in _crickets:
		_cricket(c, at, delta)


# ---------------------------------------------------------------- beetles: crawl over walls

func _beetle(b: Dictionary, cam: Vector3, delta: float) -> void:
	var n: Node3D = b.node
	if b.get("gone", 0.0) > 0.0:  # its rock was dug away: gone for a while
		b.gone -= delta
		return
	if not n.visible or n.global_position.distance_to(cam) > NEAR:
		var hit := _ray_from(cam, Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.6, 0.8), _rng.randf_range(-1, 1)), 20.0)
		if hit == Vector3.INF or hit.distance_to(cam) < 5.0 or absf(world.sdf_smooth(hit)) > 0.6:
			return  # (beetles crawl on the rock itself, not on built walls)
		n.global_position = hit
		var nr := _normal(hit)
		b.dir = nr.cross(Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1))).normalized()
		b.turn = 0.0
		b.rest = 0.0
		n.visible = true
	# Calm crawling (owner, Nov 18: "very sporadic... a little bit odd"): it keeps its heading and turns gently, and now
	# and then stops for a few seconds.
	if b.get("rest", 0.0) > 0.0:
		b.rest -= delta
		return
	if _rng.randf() < delta * 0.08:
		b.rest = _rng.randf_range(1.5, 4.0)
	var p := n.global_position
	var nrm := _normal(p)
	b.turn = clampf(b.get("turn", 0.0) + _rng.randf_range(-1.0, 1.0) * delta * 1.5, -0.8, 0.8)  # a slowly changing turn
	var dir: Vector3 = (b.dir as Vector3) - nrm * (b.dir as Vector3).dot(nrm)  # along the surface
	if dir.length() < 0.05:
		dir = nrm.cross(Vector3.UP if absf(nrm.y) < 0.9 else Vector3.RIGHT)
	dir = dir.normalized().rotated(nrm, b.turn * delta)
	b.dir = dir
	p += dir * BEETLE_SPEED * delta
	p -= nrm * world.sdf_smooth(p)  # stay on the surface
	n.global_position = p
	var look := Basis.looking_at(dir, nrm)
	n.global_basis = n.global_basis.slerp(look, minf(1.0, delta * 5.0)).orthonormalized()  # (turns smoothly)


## Rock dug away: beetles on it disappear (owner, Nov 18), and come back somewhere else a while later.
func _on_rock_changed(center: Vector3, radius: float) -> void:
	for b in _beetles:
		var n: Node3D = b.node
		if n.visible and n.global_position.distance_to(center) < radius + 0.6:
			n.visible = false
			b.gone = 12.0
	for c in _crickets:
		var n: Node3D = c.node
		if n.visible and n.global_position.distance_to(center) < radius + 0.6:
			n.visible = false


# ---------------------------------------------------------------- moths: flutter round crystals or round you

func _moth(m: Dictionary, cam: Vector3, delta: float) -> void:
	var n: Node3D = m.node
	if m.anchor == Vector3.INF or (m.anchor as Vector3).distance_to(cam) > NEAR:
		m.anchor = _moth_anchor(cam)
		if m.anchor == Vector3.INF:
			n.visible = false  # no crystal near: no moths
			return
		n.global_position = m.anchor
		n.visible = true
	m.phase += delta
	var t: float = m.phase
	var a: Vector3 = m.anchor
	# Each moth wanders on its own (owner, Nov 18: "they fly in the same pattern"): a new random spot near the crystal
	# every so often, its own speed and wobble, sometimes a quick dart, sometimes hovering for a moment.
	m.wait -= delta
	if m.wait <= 0.0 or n.global_position.distance_to(a + m.goal) < 0.15:
		m.goal = Vector3(_rng.randf_range(-1.4, 1.4), _rng.randf_range(-0.2, 1.2), _rng.randf_range(-1.4, 1.4))
		m.wait = _rng.randf_range(1.5, 4.0)
		m.speed = _rng.randf_range(MOTH_SLOW, MOTH_FAST)
	# Slow and soft (owner, Nov 22, F630: "they fly too fast and not gracefully, very sharp turns"): no quick darts,
	# the flight bends round gently and the body swings round to its new way slowly (it used to snap at once).
	var want: Vector3 = (a + m.goal - n.global_position).limit_length(1.0) * m.speed
	want += Vector3(sin(t * m.wob * 3.1), cos(t * m.wob * 2.3), sin(t * m.wob * 2.7 + 1.0)) * 0.15  # flutter
	m.vel = (m.vel as Vector3).lerp(want, minf(1.0, delta * MOTH_STEER))
	n.global_position += m.vel * delta
	var vel: Vector3 = m.vel
	var f := Vector3(vel.x, vel.y * 0.3, vel.z)
	if f.length() > 0.05 and absf(f.normalized().y) < 0.95:
		var face := Basis.looking_at(f.normalized(), Vector3.UP)
		var cur := n.global_basis.orthonormalized()
		var ang := cur.z.angle_to(face.z)  # (at most MOTH_TURN radians a second, however sharp the new way is)
		n.global_basis = cur.slerp(face, 1.0 if ang < 0.001 else minf(1.0, delta * MOTH_TURN / ang))
	var flap := sin(t * (34.0 + m.wob * 3.0)) * 0.9  # wings beat fast, round the body's long axis
	(m.wings[0] as Node3D).rotation.z = flap
	(m.wings[1] as Node3D).rotation.z = -flap


## A crystal near the camera: the moths fly round crystals only (owner, Nov 18). INF = none near: the moth hides.
func _moth_anchor(cam: Vector3) -> Vector3:
	if glow:
		var near: Array = glow.spots_near(cam, 20.0).filter(func(s): return String(s.kind).begins_with("crystal") and not s.get("hidden", false))
		if not near.is_empty():
			var s: Dictionary = near[_rng.randi() % near.size()]
			return (s.pos as Vector3) + (s.normal as Vector3) * 0.5
	return Vector3.INF


# ---------------------------------------------------------------- crickets: hop away from you

func _cricket(c: Dictionary, cam: Vector3, delta: float) -> void:
	var n: Node3D = c.node
	if not n.visible or n.global_position.distance_to(cam) > NEAR:
		var start := cam + Vector3(_rng.randf_range(-14, 14), 0.0, _rng.randf_range(-14, 14))
		if world.sdf_smooth(start) <= 0.3:
			return
		var fl := _ray_from(start, Vector3.DOWN, 12.0)
		if fl == Vector3.INF or fl.distance_to(cam) < 4.0:
			return
		n.global_position = fl
		n.rotation.y = _rng.randf() * TAU
		n.visible = true
		c.hop = 0.0
	if c.hop > 0.0:  # in the air
		c.hop = maxf(0.0, c.hop - delta)
		var u: float = 1.0 - float(c.hop) / 0.45
		var p := (c.from as Vector3).lerp(c.to, u)
		p.y += sin(u * PI) * 0.45
		n.global_position = p
		return
	var feet := _nearest_feet(n.global_position)
	if feet != Vector3.INF and feet.distance_to(n.global_position) < CRICKET_SCARE:
		var away := Vector3(n.global_position.x - feet.x, 0.0, n.global_position.z - feet.z).normalized()
		away = away.rotated(Vector3.UP, _rng.randf_range(-0.6, 0.6))
		var land := n.global_position + away * _rng.randf_range(1.0, 1.6)
		var fl := _ray_from(land + Vector3.UP * 1.0, Vector3.DOWN, 4.0)
		if fl != Vector3.INF:
			c.from = n.global_position
			c.to = fl
			c.hop = 0.45
			n.global_basis = Basis.looking_at(away, Vector3.UP)
			Sfx.play("pickup", n.global_position, -22.0, 2.2)  # a tiny chirp-click as it jumps


## The nearest dwarf's feet (any player), or INF.
func _nearest_feet(p: Vector3) -> Vector3:
	var best := Vector3.INF
	var root := get_tree().current_scene
	var players := root.get_node_or_null("Players") if root else null
	if players == null:
		return best
	for d in players.get_children():
		if d is Node3D and (d as Node3D).global_position.distance_to(p) < best.distance_to(p):
			best = (d as Node3D).global_position
	return best


# ---------------------------------------------------------------- helpers

## The first solid thing along a ray: the real rock (dug holes and all) or something built (owner, Nov 18: crickets were
## jumping in the air in the Fallen Outpost: the cave's plan doesn't know about digging or built floors).
func _ray_from(from: Vector3, dir: Vector3, reach: float) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(from, from + dir.normalized() * reach)
	q.collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else Vector3.INF


## The rock's surface normal at p (pointing out into the air), from the loaded rock.
func _normal(p: Vector3) -> Vector3:
	const E := 0.5
	var g := Vector3(world.sdf_smooth(p + Vector3(E, 0, 0)) - world.sdf_smooth(p - Vector3(E, 0, 0)),
		world.sdf_smooth(p + Vector3(0, E, 0)) - world.sdf_smooth(p - Vector3(0, E, 0)),
		world.sdf_smooth(p + Vector3(0, 0, E)) - world.sdf_smooth(p - Vector3(0, 0, E)))
	return g.normalized() if g.length() > 0.0001 else Vector3.UP
