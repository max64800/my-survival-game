class_name Lantern
extends Node3D
## The dwarf's lantern. Bright while it has fuel; a small dim glow when empty,
## so the cave is never pitch black. Fuel is kept by the GameAuthority.

const FULL_RANGE := 16.0
const FULL_ENERGY := 1.9
const ATTENUATION := 0.85  ## how fast light fades with distance (lower = reaches further)
const EMPTY_RANGE := 4.5
const EMPTY_ENERGY := 0.45
const WARM := Color(1.0, 0.78, 0.52)
const LOW_FUEL := 30.0  ## seconds left when it starts to flicker

var peer_id := 1
var light: OmniLight3D
var _glass_mat: StandardMaterial3D
var _flicker := 0.0


func _ready() -> void:
	# The look: glowing glass inside a dark iron cage (4 posts, a cap, a carry ring, a base).
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.albedo_color = WARM
	_glass_mat.emission_enabled = true
	_glass_mat.emission = WARM
	_glass_mat.emission_energy_multiplier = 3.0
	var glass := BoxMesh.new()
	glass.size = Vector3(0.1, 0.15, 0.1)
	_piece(glass, _glass_mat, Vector3(0, -0.13, 0))
	var iron := Look.mat(Color(0.22, 0.2, 0.18), "metal")
	var post := BoxMesh.new()
	post.size = Vector3(0.018, 0.19, 0.018)
	for x in [-0.06, 0.06]:
		for z in [-0.06, 0.06]:
			_piece(post, iron, Vector3(x, -0.13, z))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.025
	cap.bottom_radius = 0.095
	cap.height = 0.06
	cap.radial_segments = 8
	_piece(cap, iron, Vector3(0, -0.01, 0)).rotation.y = PI / 8.0
	var base := CylinderMesh.new()
	base.top_radius = 0.09
	base.bottom_radius = 0.08
	base.height = 0.03
	base.radial_segments = 8
	_piece(base, iron, Vector3(0, -0.235, 0)).rotation.y = PI / 8.0
	var ring := TorusMesh.new()
	ring.inner_radius = 0.03
	ring.outer_radius = 0.042
	ring.rings = 12
	ring.ring_segments = 5
	_piece(ring, iron, Vector3(0, 0.04, 0)).rotation.x = PI / 2.0
	light = OmniLight3D.new()
	light.shadow_enabled = true
	light.shadow_caster_mask = 0xFFFFF & ~DwarfModel.VISUAL_LAYER
	light.light_color = WARM
	light.omni_attenuation = ATTENUATION
	light.position = Vector3(0, -0.1, 0)
	add_child(light)


## One piece of the lantern's look. None of them cast shadows (they'd block the lantern's own light).
func _piece(mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


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
	if not back:
		# Hang straight down from the hand, whatever the hand is doing (it swings, it doesn't tilt).
		var yaw := global_basis.z
		global_basis = Basis(Vector3.UP, atan2(yaw.x, yaw.z))
	var full_range := 16.0 if back else FULL_RANGE
	var t := 1.0 if fuel > 0.0 else 0.0
	if fuel > 0.0 and fuel < LOW_FUEL:
		_flicker += delta * 14.0
		t = 0.55 + 0.45 * absf(sin(_flicker) * sin(_flicker * 0.37))
	var energy := lerpf(EMPTY_ENERGY, FULL_ENERGY, t)
	light.omni_range = lerpf(light.omni_range, lerpf(EMPTY_RANGE, full_range, t), minf(1.0, delta * 4.0))
	light.light_energy = lerpf(light.light_energy, energy, minf(1.0, delta * 6.0))
	_glass_mat.emission_energy_multiplier = 0.6 + 2.4 * t
