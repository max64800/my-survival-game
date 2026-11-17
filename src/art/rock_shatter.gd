class_name RockShatter
extends RigidBody3D
## The rock you just broke bursts into real chunks (owner, Nov 17, F261: "break in a lot of different pieces, like a
## column after a fire hit on a stone"). Games do this with pre-cut pieces that fall with physics and fade; our rock is
## dug from smooth voxels, so the game cuts its own: 10-16 chisel-faced chunks (a lumpy 20-sided shape, each corner
## pushed in or out, flat faces) in the rock's colour, thrown out of the hole, bouncing and rolling, then shrinking away.
## Only a look on your own screen (the stone you get still comes from the normal drop).

const LIFE := 4.5  ## seconds before a chunk shrinks away
const MAX_CHUNKS := 110  ## never more than this many at once (fast digging)

static var _alive: Array[RockShatter] = []
static var _shapes: Array = []  ## [ArrayMesh, ConvexPolygonShape3D] x 6 ready-made chunk shapes
static var _detail: Texture2D

var _age := 0.0
var _size := 1.0


## The rock at `center` (the middle of the scoop that was dug) broke: throw chunks out along `out` (the rock face's
## normal) in colour `col`.
static func burst(parent: Node, center: Vector3, out: Vector3, col: Color) -> void:
	if _shapes.is_empty():
		_make_shapes()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var n := rng.randi_range(20, 28)  # (owner: "more of them")
	out = out.normalized() if out.length_squared() > 0.01 else Vector3.UP
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.albedo_texture = _detail
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * 0.8  # (big cells: chunks of stone, not gravel)
	mat.roughness = 0.95
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # (both sides drawn: no holes whichever way a face turned out)
	for i in n:
		var c := RockShatter.new()
		var pick: Array = _shapes[rng.randi() % _shapes.size()]
		c._size = rng.randf_range(0.7, 1.05) if i < 3 else rng.randf_range(0.12, 0.45)  # 3 big slabs (owner: "some a lot bigger"), the rest smaller
		var mi := MeshInstance3D.new()
		mi.mesh = pick[0]
		mi.material_override = mat
		mi.scale = Vector3.ONE * c._size
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if c._size < 0.3 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		c.add_child(mi)
		var cs := CollisionShape3D.new()
		var shape := (pick[1] as ConvexPolygonShape3D).duplicate() as ConvexPolygonShape3D
		var pts := PackedVector3Array()
		for p in shape.points:
			pts.append(p * c._size)
		shape.points = pts
		cs.shape = shape
		c.add_child(cs)
		c.collision_layer = 0
		c.collision_mask = World.TERRAIN_LAYER  # bounces on the rock, never on dwarfs
		c.mass = c._size * 3.0
		var pm := PhysicsMaterial.new()
		pm.bounce = 0.25
		pm.friction = 0.8
		c.physics_material_override = pm
		parent.add_child(c)
		c.global_position = center + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.4, 0.6), rng.randf_range(-0.6, 0.6))
		c.global_basis = Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		c.linear_velocity = (out * rng.randf_range(1.5, 3.5) + Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(0.5, 2.0), rng.randf_range(-1.2, 1.2)))
		c.angular_velocity = Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6), rng.randf_range(-6, 6))
		_alive.append(c)
	while _alive.size() > MAX_CHUNKS:
		var old: RockShatter = _alive.pop_front()
		if is_instance_valid(old):
			old.queue_free()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFE:
		var k := clampf(1.0 - (_age - LIFE) / 0.6, 0.0, 1.0)
		for ch in get_children():
			if ch is MeshInstance3D:
				(ch as MeshInstance3D).scale = Vector3.ONE * _size * k
		if k <= 0.0:
			_alive.erase(self)
			queue_free()


## Six chunk shapes: a 20-sided ball with every corner pushed in or out, flat faces (chisel-cut), 1 m across.
static func _make_shapes() -> void:
	# A stony pattern made by the game (cracked cells, light and dark), multiplied by the rock's colour.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.035
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.78, 0.76, 0.72))
	ramp.set_color(1, Color(1.1, 1.08, 1.04))
	tex.color_ramp = ramp
	_detail = tex
	var rng := RandomNumberGenerator.new()
	rng.seed = 2612
	var t := (1.0 + sqrt(5.0)) / 2.0
	var base := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
		Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for k in 6:
		var pts := PackedVector3Array()
		var stretch := Vector3(rng.randf_range(0.7, 1.3), rng.randf_range(0.55, 1.0), rng.randf_range(0.7, 1.3))  # flatter slabs
		for v in base:
			pts.append((v as Vector3).normalized() * 0.5 * rng.randf_range(0.65, 1.15) * stretch)
		var shape := ConvexPolygonShape3D.new()
		shape.points = pts
		var mesh := _hull_mesh(pts)
		_shapes.append([mesh, shape])


## A flat-shaded mesh around the points (they all lie on the hull: a pushed-about icosahedron keeps its 20 faces).
static func _hull_mesh(pts: PackedVector3Array) -> ArrayMesh:
	const FACES := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
		[7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in FACES:
		var a: Vector3 = pts[f[0]]
		var b: Vector3 = pts[f[1]]
		var c: Vector3 = pts[f[2]]
		var n := (b - a).cross(c - a).normalized()
		if n.dot(a + b + c) < 0.0:  # make every face point outward
			var tmp := b
			b = c
			c = tmp
			n = -n
		for p in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(p)
	return st.commit()
