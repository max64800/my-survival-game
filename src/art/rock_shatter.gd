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
static func burst(parent: Node, center: Vector3, out: Vector3, col: Color, mat_id := -1) -> void:
	if _shapes.is_empty():
		_make_shapes()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var n := rng.randi_range(20, 28)  # (owner: "more of them")
	out = out.normalized() if out.length_squared() > 0.01 else Vector3.UP
	var mat: Material
	if mat_id >= 0:  # painted with the cave's own picture of that rock (owner, Nov 18: "add the texture to them")
		var sm := ShaderMaterial.new()
		sm.shader = preload("res://src/art/rock_chunk.gdshader")
		sm.set_shader_parameter("albedo_tex", preload("res://assets/textures/terrain/terrain_albedo.png"))
		sm.set_shader_parameter("slice", float(mat_id * 4 + rng.randi_range(0, 3)))
		mat = sm
	else:
		var std := StandardMaterial3D.new()
		std.albedo_color = col
		std.albedo_texture = _detail
		std.uv1_triplanar = true
		std.uv1_scale = Vector3.ONE * 0.8
		std.roughness = 0.95
		std.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat = std
	for i in n:
		var c := RockShatter.new()
		var pick: Array = _shapes[rng.randi() % _shapes.size()]
		c._size = rng.randf_range(0.7, 1.05) if i < 3 else rng.randf_range(0.12, 0.45)  # 3 big slabs (owner: "some a lot bigger"), the rest smaller
		var mi := MeshInstance3D.new()
		mi.mesh = pick[0]
		mi.material_override = mat
		mi.scale = Vector3.ONE * c._size
		mi.set_instance_shader_parameter("chunk_size", c._size)  # (the texture keeps its real size on every chunk)
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


## Chunk shapes, 1 m across, four kinds (owner, Nov 18: "different shapes, similar size"): lumpy many-sided stones,
## chunky blocks, flat slabs, long shards and wedges; every corner pushed in or out a little, flat chiselled faces.
const ICO_FACES := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
	[7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
const BOX_FACES := [[0, 2, 6], [0, 6, 4], [1, 5, 7], [1, 7, 3], [0, 4, 5], [0, 5, 1], [2, 3, 7], [2, 7, 6], [0, 1, 3], [0, 3, 2],
	[4, 6, 7], [4, 7, 5]]
const WEDGE_FACES := [[0, 1, 2], [3, 5, 4], [0, 3, 4], [0, 4, 1], [1, 4, 5], [1, 5, 2], [2, 5, 3], [2, 3, 0]]


static func _make_shapes() -> void:
	# A stony pattern made by the game, for chunks of things without a rock picture.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.035
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	_detail = tex
	# Round 5 (owner, Nov 18: "the big pieces are just weird looking triangles... more complex, more shapes, more
	# corners"): a rounder ball of many corners, stretched into a lump, slab or shard, then split by 3-6 flat cuts the
	# way rock really breaks: big flat faces, sharp edges, lots of corners. 24 different ones.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2613
	var ball := _icosphere(2)
	for k in 24:
		var kind := k % 4
		var st := Vector3(rng.randf_range(0.8, 1.2), rng.randf_range(0.7, 1.0), rng.randf_range(0.8, 1.2))
		if kind == 1:
			st = Vector3(rng.randf_range(1.1, 1.4), rng.randf_range(0.3, 0.45), rng.randf_range(0.9, 1.2))  # a slab
		elif kind == 2:
			st = Vector3(rng.randf_range(0.4, 0.55), rng.randf_range(1.3, 1.7), rng.randf_range(0.45, 0.6))  # a shard
		var pts := PackedVector3Array()
		for v: Vector3 in ball[0]:
			pts.append(v * 0.5 * st * rng.randf_range(0.93, 1.07))
		var cuts := rng.randi_range(5, 9) + (2 if kind == 3 else 0)  # wedges: more and deeper cuts (5-9: more corners)
		for c in cuts:
			var nrm := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
			var keep := rng.randf_range(0.18, 0.36) * (0.7 if kind == 3 else 1.0)  # how far from the middle the cut is
			for i in pts.size():
				var over := pts[i].dot(nrm) - keep
				if over > 0.0:
					pts[i] -= nrm * over  # squashed flat onto the cut
		var shape := ConvexPolygonShape3D.new()
		shape.points = pts
		_shapes.append([_hull_mesh(pts, ball[1]), shape])


## A ball of many small faces (an icosahedron split `levels` times): [points, faces].
static func _icosphere(levels: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var pts: Array[Vector3] = []
	for v in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
			Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		pts.append((v as Vector3).normalized())
	var faces: Array = ICO_FACES.duplicate(true)
	for l in levels:
		var mid := {}
		var out: Array = []
		for f in faces:
			var m := []
			for e in [[f[0], f[1]], [f[1], f[2]], [f[2], f[0]]]:
				var key := Vector2i(mini(e[0], e[1]), maxi(e[0], e[1]))
				if not mid.has(key):
					mid[key] = pts.size()
					pts.append(((pts[e[0]] + pts[e[1]]) * 0.5).normalized())
				m.append(mid[key])
			out.append([f[0], m[0], m[2]])
			out.append([f[1], m[1], m[0]])
			out.append([f[2], m[2], m[1]])
			out.append([m[0], m[1], m[2]])
		faces = out
	return [PackedVector3Array(pts), faces]


## A flat-shaded mesh from the points and its faces (each face turned to point outward).
static func _hull_mesh(pts: PackedVector3Array, faces: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a: Vector3 = pts[f[0]]
		var b: Vector3 = pts[f[1]]
		var c: Vector3 = pts[f[2]]
		var cr := (b - a).cross(c - a)
		if cr.length_squared() < 1e-12:
			continue  # squashed flat by a cut: nothing to draw
		var n := cr.normalized()
		if n.dot(a + b + c) < 0.0:  # make every face point outward
			var tmp := b
			b = c
			c = tmp
			n = -n
		for p in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(p)
	return st.commit()
