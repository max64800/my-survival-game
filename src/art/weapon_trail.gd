class_name WeaponTrail
extends MeshInstance3D
## A short see-through swoosh behind a swinging weapon (only looks).
## It remembers where the weapon was over the last few frames and draws a ribbon through
## those spots, fading toward the oldest one. Then it fades out and frees itself.

const KEEP := 10  ## how many past spots the ribbon remembers

var _holder: Node3D  ## the weapon's hand socket
var _near := 0.3     ## where the ribbon starts along the weapon (metres from the hand)
var _far := 0.85     ## where it ends (the tip)
var _life := 0.0
var _points: Array = []  ## [near, far] pairs, newest first
var _mesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()


static func follow(holder: Node3D, seconds: float, color: Color, near: float = 0.3, far: float = 0.85) -> WeaponTrail:
	var t := WeaponTrail.new()
	t._holder = holder
	t._life = seconds
	t._near = near
	t._far = far
	t._mat.albedo_color = color
	holder.get_tree().root.add_child(t)  # top level: it stays where the blade was
	return t


func _ready() -> void:
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	material_override = _mat


func _process(delta: float) -> void:
	_life -= delta
	if is_instance_valid(_holder) and _life > 0.0:
		var g := _holder.global_transform
		_points.push_front([g * Vector3(0, _near, 0), g * Vector3(0, _far, 0)])
	else:
		_points.pop_back()  # shrink away from the old end
	if _points.size() > KEEP:
		_points.pop_back()
	if _points.size() < 2:
		if _life <= 0.0:
			queue_free()
		_mesh.clear_surfaces()
		return
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat)
	var c := _mat.albedo_color
	for i in _points.size():
		var a := c.a * (1.0 - float(i) / _points.size())
		_mesh.surface_set_color(Color(c.r, c.g, c.b, a * 0.3))
		_mesh.surface_add_vertex(_points[i][0])
		_mesh.surface_set_color(Color(c.r, c.g, c.b, a))
		_mesh.surface_add_vertex(_points[i][1])
	_mesh.surface_end()
