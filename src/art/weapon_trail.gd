class_name WeaponTrail
extends MeshInstance3D
## A swoosh behind a swinging weapon or tool (only looks). Round 2 (owner, Nov 18: "juicy sword swipes", the 5 steps):
## 1. it traces the TIP of the real tool (its own length, measured from its model), 2. an arc from the tip almost down to
## the hand, 3. a ribbon mesh with its own pattern on it, 4. the tail fades out (the oldest part is see-through), 5.
## streaks run along it and a soft mask pans along it, so it flows with the swing. It remembers the last moment of
## the swing (KEEP_TIME, by time: smooth at any frame rate; the gaps between frames are filled with a curve), then
## fades out and frees itself.

const KEEP_TIME := 0.15  ## seconds of swing the ribbon shows
const FILL := 4          ## extra points on the curve between two frames (a smooth arc, not a fan of straight pieces)
const SHADER := preload("res://src/art/weapon_trail.gdshader")

var _holder: Node3D  ## the weapon's hand socket
var _near := 0.12    ## where the ribbon starts along the weapon (metres from the hand): almost at the hilt
var _far := 0.85     ## where it ends (the tip)
var _life := 0.0
var _t := 0.0
var _samples: Array = []  ## [time, near point, far point], newest first
var _mesh := ImmediateMesh.new()
var _mat := ShaderMaterial.new()


## Follows `holder` (the hand socket) for `seconds`. `near`/`far`: metres along the tool from the hand; far < 0 =
## measured from the tool in the hand (its tip).
static func follow(holder: Node3D, seconds: float, color: Color, near: float = -1.0, far: float = -1.0) -> WeaponTrail:
	if DisplayServer.get_name() == "headless" or not holder.is_inside_tree():
		return null  # (the test computer draws nothing: its shader would only make the engine complain)
	var t := WeaponTrail.new()
	t._holder = holder
	t._life = seconds
	var tip := far if far > 0.0 else _tool_length(holder)
	t._far = tip
	t._near = near if near >= 0.0 else tip * 0.15
	t._mat.shader = SHADER
	t._mat.set_shader_parameter("tint", color)
	holder.get_tree().root.add_child(t)  # top level: it stays where the blade was
	return t


## How far the held tool reaches from the hand along the socket's +Y (its tip), from its meshes.
static func _tool_length(holder: Node3D) -> float:
	var inv := holder.global_transform.affine_inverse()
	var far := 0.0
	for mi: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
		var b := mi.get_aabb()
		for i in 8:
			far = maxf(far, (inv * (mi.global_transform * b.get_endpoint(i))).y)
	return far if far > 0.15 else 0.85


func _ready() -> void:
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material_override = _mat


func _process(delta: float) -> void:
	_t += delta
	_life -= delta
	if is_instance_valid(_holder) and _life > 0.0:
		var g := _holder.global_transform
		_samples.push_front([_t, g * Vector3(0, _near, 0), g * Vector3(0, _far, 0)])
	while not _samples.is_empty() and _t - float(_samples.back()[0]) > KEEP_TIME:
		_samples.pop_back()  # (old moments age out; after the swing the tail shrinks away)
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		if _life <= 0.0:
			queue_free()
		return
	_mat.set_shader_parameter("pan", _t * 7.0)
	var near := _curve(1)
	var far := _curve(2)
	var n := near.size()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in n:
		var u := float(i) / float(n - 1)  # 0 = the blade now .. 1 = the oldest end of the tail
		var a := pow(1.0 - u, 1.3) * minf(1.0, u * 6.0 + 0.35)  # (the tail fades to nothing; the very front softens)
		_mesh.surface_set_color(Color(1, 1, 1, a))
		_mesh.surface_set_uv(Vector2(u, 0.0))
		_mesh.surface_add_vertex(near[i])
		_mesh.surface_set_color(Color(1, 1, 1, a))
		_mesh.surface_set_uv(Vector2(u, 1.0))
		_mesh.surface_add_vertex(far[i])
	_mesh.surface_end()


## The remembered points of one edge (1 = near the hand, 2 = the tip), with FILL extra points on a smooth curve
## (Catmull-Rom) between each pair.
func _curve(k: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var m := _samples.size()
	for i in m - 1:
		var p0: Vector3 = _samples[maxi(i - 1, 0)][k]
		var p1: Vector3 = _samples[i][k]
		var p2: Vector3 = _samples[i + 1][k]
		var p3: Vector3 = _samples[mini(i + 2, m - 1)][k]
		for j in FILL:
			var t := float(j) / FILL
			var t2 := t * t
			pts.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t2 * t))
	pts.append(_samples[m - 1][k])
	return pts
