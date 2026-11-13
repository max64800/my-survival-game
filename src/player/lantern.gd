class_name Lantern
extends Node3D
## The dwarf's lantern. Bright while it has fuel; a small dim glow when empty,
## so the cave is never pitch black. Fuel is kept by the GameAuthority.

const FULL_RANGE := 14.0
const FULL_ENERGY := 1.7
const EMPTY_RANGE := 4.5
const EMPTY_ENERGY := 0.45
const WARM := Color(1.0, 0.78, 0.52)
const LOW_FUEL := 30.0  ## seconds left when it starts to flicker

var peer_id := 1
var light: OmniLight3D
var _glass_mat: StandardMaterial3D
var _flicker := 0.0


func _ready() -> void:
	var frame := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.14, 0.2, 0.14)
	frame.mesh = box
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.albedo_color = WARM
	_glass_mat.emission_enabled = true
	_glass_mat.emission = WARM
	_glass_mat.emission_energy_multiplier = 3.0
	frame.material_override = _glass_mat
	frame.position = Vector3(0, -0.12, 0)
	add_child(frame)
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.1
	cm.height = 0.07
	cm.radial_segments = 6
	cap.mesh = cm
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.2, 0.18, 0.16)
	cap.material_override = dark
	cap.position = Vector3(0, 0.01, 0)
	add_child(cap)
	light = OmniLight3D.new()
	light.shadow_enabled = true
	light.light_color = WARM
	light.omni_attenuation = 1.2
	light.position = Vector3(0, -0.1, 0)
	add_child(light)


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var fuel := auth.get_player(peer_id).fuel if auth and auth.get_player(peer_id) else GameAuthority.MAX_FUEL
	var t := 1.0 if fuel > 0.0 else 0.0
	if fuel > 0.0 and fuel < LOW_FUEL:
		_flicker += delta * 14.0
		t = 0.55 + 0.45 * absf(sin(_flicker) * sin(_flicker * 0.37))
	var energy := lerpf(EMPTY_ENERGY, FULL_ENERGY, t)
	light.omni_range = lerpf(light.omni_range, lerpf(EMPTY_RANGE, FULL_RANGE, t), minf(1.0, delta * 4.0))
	light.light_energy = lerpf(light.light_energy, energy, minf(1.0, delta * 6.0))
	_glass_mat.emission_energy_multiplier = 0.6 + 2.4 * t
