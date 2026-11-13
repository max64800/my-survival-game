class_name DwarfModel
extends Node3D
## A placeholder dwarf built from simple shapes (body, head, big beard, helmet),
## until we pick a real art pack. Faces -Z (Godot's "forward").
## The right arm holds the pickaxe and can swing; the left hand holds the lantern.

signal swing_impact  ## the pickaxe just hit (time to dig)

const SKIN := Color(0.93, 0.72, 0.58)
const BEARD := Color(0.72, 0.33, 0.14)
const TUNIC := Color(0.25, 0.38, 0.55)
const LEATHER := Color(0.33, 0.21, 0.12)
const METAL := Color(0.6, 0.6, 0.63)

var right_arm: Node3D  ## shoulder pivot, rotates on X to swing
var left_hand: Node3D  ## where the lantern hangs
var swinging := false
var _mats := {}


func _ready() -> void:
	# Legs
	for x in [-0.13, 0.13]:
		_part(_cyl(0.09, 0.11, 0.36), LEATHER, Vector3(x, 0.18, 0))
		_part(_box(Vector3(0.18, 0.1, 0.28)), LEATHER.darkened(0.3), Vector3(x, 0.05, -0.04))
	# Body, belt
	_part(_capsule(0.33, 0.78), TUNIC, Vector3(0, 0.68, 0))
	_part(_cyl(0.34, 0.34, 0.08), LEATHER, Vector3(0, 0.55, 0))
	_part(_box(Vector3(0.12, 0.09, 0.04)), Color(0.85, 0.7, 0.3), Vector3(0, 0.55, -0.34))
	# Head, nose, eyes
	_part(_sphere(0.2), SKIN, Vector3(0, 1.12, 0))
	_part(_sphere(0.065), SKIN.darkened(0.08), Vector3(0, 1.1, -0.2))
	for x in [-0.075, 0.075]:
		_part(_sphere(0.025), Color(0.08, 0.06, 0.05), Vector3(x, 1.16, -0.18))
	# Beard: a big wedge hanging from the chin
	var beard := _part(_cyl(0.2, 0.05, 0.42), BEARD, Vector3(0, 0.88, -0.17))
	beard.rotation.x = deg_to_rad(-12)
	_part(_sphere(0.16), BEARD, Vector3(0, 1.0, -0.12))
	# Helmet with a nose guard
	var helm := _part(_hemisphere(0.23), METAL, Vector3(0, 1.17, 0))
	helm.scale = Vector3(1, 0.9, 1)
	_part(_box(Vector3(0.04, 0.14, 0.03)), METAL, Vector3(0, 1.15, -0.22))
	# Arms
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.38, 0.95, 0)
	add_child(right_arm)
	_part(_capsule(0.08, 0.5), TUNIC, Vector3(0, -0.22, 0), right_arm)
	_part(_sphere(0.08), SKIN, Vector3(0, -0.47, 0), right_arm)
	var pick := Node3D.new()
	pick.position = Vector3(0, -0.47, 0)
	pick.rotation.x = deg_to_rad(-90)
	right_arm.add_child(pick)
	_part(_cyl(0.025, 0.025, 0.85), Color(0.5, 0.35, 0.2), Vector3(0, 0.25, 0), pick)
	var head := _part(_box(Vector3(0.07, 0.07, 0.55)), Color(0.55, 0.53, 0.5), Vector3(0, 0.62, 0.02), pick)
	head.rotation.x = deg_to_rad(8)
	var left_arm := Node3D.new()
	left_arm.position = Vector3(-0.38, 0.95, 0)
	left_arm.rotation.x = deg_to_rad(-35)
	add_child(left_arm)
	_part(_capsule(0.08, 0.5), TUNIC, Vector3(0, -0.22, 0), left_arm)
	_part(_sphere(0.08), SKIN, Vector3(0, -0.47, 0), left_arm)
	left_hand = Node3D.new()
	left_hand.position = Vector3(0, -0.55, 0)
	left_arm.add_child(left_hand)
	_rest()


## Swing the pickaxe: wind up, strike (emits swing_impact), recover.
func swing(duration: float) -> void:
	if swinging:
		return
	swinging = true
	var t := create_tween()
	t.tween_property(right_arm, "rotation:x", deg_to_rad(150), duration * 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(right_arm, "rotation:x", deg_to_rad(10), duration * 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(swing_impact.emit)
	t.tween_property(right_arm, "rotation:x", deg_to_rad(35), duration * 0.38).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): swinging = false)


func _rest() -> void:
	right_arm.rotation.x = deg_to_rad(35)


# ---------------------------------------------------------------- shape helpers

func _part(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _mat(c: Color) -> Material:
	if not _mats.has(c):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.8
		_mats[c] = m
	return _mats[c]


func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 8
	m.rings = 1
	return m


func _capsule(r: float, h: float) -> Mesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	return m


func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 6
	return m


func _hemisphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r
	m.is_hemisphere = true
	m.radial_segments = 10
	m.rings = 4
	return m


func _box(size: Vector3) -> Mesh:
	var m := BoxMesh.new()
	m.size = size
	return m
