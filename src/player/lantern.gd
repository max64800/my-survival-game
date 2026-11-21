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
const HIP_RANGE := 13.0  ## the Hip Lantern (F562): both hands free, but the body blocks a little light
const HOOK_MODEL := "res://assets/models/items/lantern_hip_hook.glb"
const HOOK_DROP := 0.054  ## the hook's bottom, above the lantern's middle (it hangs on the carry ring)
const BELT_ABOVE := 0.23  ## the belt loop's middle, above the lantern's middle

var peer_id := 1
var light: OmniLight3D
var _glass_mat: StandardMaterial3D
var _flicker := 0.0
var _hook: Node3D  ## the belt hook, shown only on the hip


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
	Darkness.mark(light, EMPTY_ENERGY + 0.15)  # an empty lantern's last glow is "dark" (F293)
	light.shadow_enabled = true
	light.shadow_caster_mask = 0xFFFFF & ~DwarfModel.VISUAL_LAYER
	# Soft shadow edges (owner, Nov 17: "the light is very sharp"): a pebble or a tool right by the lantern threw huge
	# razor-edged shadows. A lantern flame is a few cm wide, so give the light that size (soft edges), blur a little,
	# and let some light into the shadows.
	light.light_size = 0.12
	light.shadow_blur = 1.5
	light.shadow_opacity = 0.85
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


## The Hip Lantern (F562, owner Nov 21: "so fighting is easy"): hangs from the belt, both hands free.
static func is_on_hip(ps: GameAuthority.PlayerState) -> bool:
	return ps != null and (ps.inventory.equipped("lantern") == "lantern_hip"
		or (not ps.inventory.is_player and ps.inventory.count_of("lantern_hip") > 0 and not is_on_back(ps)))


## Is the off hand free for a shield or a two-hander (back or hip lantern)?
static func hands_free(ps: GameAuthority.PlayerState) -> bool:
	return is_on_back(ps) or is_on_hip(ps)


## "hand", "hip" or "back".
static func spot_of(ps: GameAuthority.PlayerState) -> String:
	if is_on_back(ps):
		return "back"
	return "hip" if is_on_hip(ps) else "hand"


## Tooltip line: where it sits and how far it lights.
static func tip(id: String) -> String:
	match id:
		"lantern_hip":
			return "Hangs on your belt: both hands free · %d m light" % int(HIP_RANGE)
		"lantern_back":
			return "On your back: both hands free · 16 m light"
	return "Held in your left hand (no shield or two-handers) · %d m light" % int(FULL_RANGE)


## The back lantern (progression doc 5.4) sits above your head and frees both hands.
static func is_on_back(ps: GameAuthority.PlayerState) -> bool:
	return ps != null and (ps.inventory.equipped("lantern") == "lantern_back"
		or (not ps.inventory.is_player and ps.inventory.count_of("lantern_back") > 0))


## Do they have a lantern? In a new game the host wakes without one and crafts it (feedback F11).
## Everyone else (friends who join, test robots) has one built in, like before.
## (A friend's dwarf whose bag we can't see counts as having one.)
static func has_lantern(ps: GameAuthority.PlayerState) -> bool:
	if ps == null or not ps.needs_lantern:
		return true
	return ps.inventory.equipped("lantern") != ""  # it lights while it's in the lantern slot (F23)


var _spot := "hand"


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	visible = has_lantern(ps) and not (ps != null and ps.lantern_stowed)  # L puts it away (owner, Nov 17)
	if not visible:
		return
	var fuel := ps.fuel if ps else GameAuthority.MAX_FUEL
	var spot := spot_of(ps)
	if spot != _spot:
		place(spot)
	elif spot == "hip":
		_to_belt()  # every frame: follows the hips (and the hip bone isn't posed yet in the first frames)
	if spot != "back":
		# Hang straight down from the hand or belt, whatever it's doing (it swings, it doesn't tilt).
		var yaw := global_basis.z
		global_basis = Basis(Vector3.UP, atan2(yaw.x, yaw.z))
	var full_range: float = {back = 16.0, hip = HIP_RANGE}.get(spot, FULL_RANGE) * (ps.progress.lantern_range_mult() if ps else 1.0)  # (Lantern Bearer perk)
	var t := 1.0 if fuel > 0.0 else 0.0
	if fuel > 0.0 and fuel < LOW_FUEL:
		_flicker += delta * 14.0
		t = 0.55 + 0.45 * absf(sin(_flicker) * sin(_flicker * 0.37))
	var energy := lerpf(EMPTY_ENERGY, FULL_ENERGY, t)
	light.omni_range = lerpf(light.omni_range, lerpf(EMPTY_RANGE, full_range, t), minf(1.0, delta * 4.0))
	light.light_energy = lerpf(light.light_energy, energy, minf(1.0, delta * 6.0))
	_glass_mat.emission_energy_multiplier = 0.6 + 2.4 * t


## Move the lantern to the hand, the hip (on its belt hook) or the back.
func place(spot: String) -> void:
	_spot = spot
	var model := get_parent()
	while model and not model is DwarfModel:
		model = model.get_parent()
	if model == null:
		return
	var dm := model as DwarfModel
	match spot:
		"back":
			reparent(dm, false)
			position = Vector3(0, 1.75, 0.25)
		"hip":
			reparent(dm.hip, false)
			_to_belt()
		_:
			reparent(dm.left_hand, false)
			position = Vector3.ZERO
	if spot == "hip" and _hook == null and ResourceLoader.exists(HOOK_MODEL):
		_hook = (load(HOOK_MODEL) as PackedScene).instantiate()
		_hook.position = Vector3(0, HOOK_DROP, 0)
		add_child(_hook)
		for mi: MeshInstance3D in _hook.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # (it would block the lantern's own light)
	if _hook:
		_hook.visible = spot == "hip"


func _to_belt() -> void:
	var dm := get_parent()
	while dm and not dm is DwarfModel:
		dm = dm.get_parent()
	if dm:
		global_position = (dm as DwarfModel).hip_point() - Vector3(0, BELT_ABOVE, 0)
