class_name ChunkSwarm
extends MultiMeshInstance3D
## A broken block bursts into lots of little bits (feedback F13): 25-50 pieces pop out,
## tumble for a moment, then fly into the dwarf and vanish. Only for looks: you still get
## the same one rock / copper / dirt item as before (that comes from the normal drop).
## All pieces are drawn as ONE object (a MultiMesh), so 50 bits cost about as much as 1.

const BURST_TIME := 0.35   ## seconds the bits fly outward before heading to you
const HOME_SPEED := 14.0
const LIFETIME := 2.5      ## safety: gone after this no matter what

var _target: Node3D
var _pos: PackedVector3Array
var _vel: PackedVector3Array
var _spin: PackedVector3Array
var _rot: PackedVector3Array
var _size: PackedFloat32Array
var _alive: PackedByteArray
var _age := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


## Starts a burst of `count` bits at `at`, colored `color`, that fly to `target`.
static func burst(parent: Node, at: Vector3, color: Color, target: Node3D, count: int = -1) -> ChunkSwarm:
	if parent == null or not parent.is_inside_tree():
		return null
	var s := ChunkSwarm.new()
	s._target = target
	s._setup(at, color, count if count > 0 else randi_range(25, 50))
	parent.add_child(s)
	s.global_position = Vector3.ZERO
	return s


func _setup(at: Vector3, color: Color, count: int) -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.09
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = count
	multimesh = mm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pos.resize(count)
	_vel.resize(count)
	_spin.resize(count)
	_rot.resize(count)
	_size.resize(count)
	_alive.resize(count)
	for i in count:
		_pos[i] = at + Vector3(randf_range(-0.35, 0.35), randf_range(-0.25, 0.35), randf_range(-0.35, 0.35))
		var out := Vector3(randf_range(-1, 1), randf_range(0.2, 1.3), randf_range(-1, 1)).normalized()
		_vel[i] = out * randf_range(2.0, 5.5)
		_spin[i] = Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
		_rot[i] = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		_size[i] = randf_range(0.55, 1.45)
		_alive[i] = 1
	_write()


func _process(delta: float) -> void:
	_age += delta
	var goal := _target.global_position + Vector3.UP * 0.9 if is_instance_valid(_target) else Vector3.INF
	var left := 0
	for i in _pos.size():
		if _alive[i] == 0:
			continue
		if _age < BURST_TIME or goal == Vector3.INF:
			_vel[i] += Vector3.DOWN * _gravity * delta  # tumble out first
		else:
			# Then rush to the dwarf, faster the longer it flies (staggered a little per bit).
			var to := goal - _pos[i]
			var d := to.length()
			if d < 0.45:
				_alive[i] = 0
				continue
			var want := to / d * HOME_SPEED * (1.0 + (_age - BURST_TIME) * 2.0) * (0.8 + 0.4 * float(i % 5) / 4.0)
			_vel[i] = _vel[i].lerp(want, minf(1.0, delta * 7.0))
		_pos[i] += _vel[i] * delta
		_rot[i] += _spin[i] * delta
		left += 1
	_write()
	if left == 0 or _age > LIFETIME:
		queue_free()


func _write() -> void:
	for i in _pos.size():
		var sc := _size[i] if _alive[i] == 1 else 0.0
		var b := Basis.from_euler(_rot[i]).scaled(Vector3.ONE * sc)
		multimesh.set_instance_transform(i, Transform3D(b, _pos[i]))
