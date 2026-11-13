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


## The back lantern (progression doc 5.4) sits above your head and frees both hands.
static func is_on_back(ps: GameAuthority.PlayerState) -> bool:
	return ps != null and ps.inventory.count_of("lantern_back") > 0


var _on_back := false


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	var fuel := ps.fuel if ps else GameAuthority.MAX_FUEL
	var back := is_on_back(ps)
	if back != _on_back:
		_on_back = back
		var model := get_parent()
		while model and not model is DwarfModel:
			model = model.get_parent()
		if model:
			reparent(model if back else (model as DwarfModel).left_hand, false)
			position = Vector3(0, 1.75, 0.25) if back else Vector3.ZERO
	var full_range := 16.0 if back else FULL_RANGE
	var t := 1.0 if fuel > 0.0 else 0.0
	if fuel > 0.0 and fuel < LOW_FUEL:
		_flicker += delta * 14.0
		t = 0.55 + 0.45 * absf(sin(_flicker) * sin(_flicker * 0.37))
	var energy := lerpf(EMPTY_ENERGY, FULL_ENERGY, t)
	light.omni_range = lerpf(light.omni_range, lerpf(EMPTY_RANGE, full_range, t), minf(1.0, delta * 4.0))
	light.light_energy = lerpf(light.light_energy, energy, minf(1.0, delta * 6.0))
	_glass_mat.emission_energy_multiplier = 0.6 + 2.4 * t
