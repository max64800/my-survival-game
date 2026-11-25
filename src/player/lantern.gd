class_name Lantern
extends Node3D
## The dwarf's lantern. Bright while it has fuel; a small dim glow when empty,
## so the cave is never pitch black. Fuel is kept by the GameAuthority.

const FULL_RANGE := 24.0  ## owner, Nov 22: +50% (was 16)
const FULL_ENERGY := 1.9
const ATTENUATION := 0.85  ## how fast light fades with distance (lower = reaches further)
const EMPTY_RANGE := 4.5
const EMPTY_ENERGY := 0.45
const WARM := Color(1.0, 0.78, 0.52)
const LOW_FUEL := 30.0  ## seconds left when it starts to flicker
const HIP_RANGE := 16.0  ## (owner, Nov 22: was 13) the Hip Lantern (F562): both hands free, but the body blocks a little light
const HOOK_MODEL := "res://assets/models/items/lantern_hip_hook.glb"
const BACK_RANGE := 24.0  ## the Back Lantern (owner, Nov 22: was 16)
const HOOK_DROP := 0.054  ## the hook's bottom, above the lantern's middle (it hangs on the carry ring)
const HIP_SCALE := 0.75  ## a smaller lantern on the belt: full size plus the hook is longer than a dwarf's leg (owner, Nov 22)
const BELT_ABOVE := 0.144  ## the belt, above the lantern's middle (the short hook's loop top sits 2.6 cm above it; owner Nov 22: the 20 cm hook hung it by his ankles)

var peer_id := 1
var light: OmniLight3D
var _glass_mat: StandardMaterial3D
var _flicker := 0.0
var _hook: Node3D  ## the belt hook, shown only on the hip
# The swing on the belt (F613): how far the lantern's middle is pushed out from straight below the belt, and how fast.
var _swing := Vector3.ZERO
var _swing_v := Vector3.ZERO
var _belt_last := Vector3.ZERO
var _belt_v := Vector3.ZERO
var _belt_seen := false
const SWING_SPEED := 6.5  ## how quickly it swings back and forth (a short pendulum)
const SWING_DAMP := 0.22  ## how fast a swing dies down (0 = forever, 1 = no swing)
const SWING_MAX := 0.6  ## the furthest it swings out, as a share of the hook's length (~30 degrees)
const SWING_PUSH := 0.1  ## how hard his starts, stops and turns push it


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
			return "On your back: both hands free · %d m light" % int(BACK_RANGE)
	return "Held in your left hand (no shield or two-handers) · %d m light" % int(FULL_RANGE)


## The back lantern (progression doc 5.4) sits above your head and frees both hands.
static func is_on_back(ps: GameAuthority.PlayerState) -> bool:
	return ps != null and (ps.inventory.equipped("lantern") == "lantern_back"
		or (not ps.inventory.is_player and ps.inventory.count_of("lantern_back") > 0))


## Do they have a lantern? In a new game the host wakes without one and picks it up off the floor (F11; owner Nov 22).
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
	var mine := peer_id == multiplayer.get_unique_id()
	if not visible:
		if mine:
			RenderingServer.global_shader_parameter_set("lantern_at", Vector4.ZERO)  # no lantern: no ore glints
		return
	var fuel := ps.fuel if ps else GameAuthority.MAX_FUEL
	var spot := spot_of(ps)
	if spot != _spot:
		place(spot)
	elif spot == "hip":
		_to_belt()  # every frame: follows the hips (and the hip bone isn't posed yet in the first frames)
	if spot != "back":
		_hang(spot)
	if spot == "hip":
		_swing_step(delta)
	else:
		_belt_seen = false
	var full_range: float = {back = BACK_RANGE, hip = HIP_RANGE}.get(spot, FULL_RANGE) * (ps.progress.lantern_range_mult() if ps else 1.0)  # (Lantern Bearer perk)
	var t := 1.0 if fuel > 0.0 else 0.0
	if fuel > 0.0 and fuel < LOW_FUEL:
		_flicker += delta * 14.0
		t = 0.55 + 0.45 * absf(sin(_flicker) * sin(_flicker * 0.37))
	var energy := lerpf(EMPTY_ENERGY, FULL_ENERGY, t)
	light.omni_range = lerpf(light.omni_range, lerpf(EMPTY_RANGE, full_range, t), minf(1.0, delta * 4.0))
	light.light_energy = lerpf(light.light_energy, energy, minf(1.0, delta * 6.0))
	if mine:  # F870: your own lantern tells the rock where it is, so copper and tin twinkle in its light
		var p := light.global_position
		RenderingServer.global_shader_parameter_set("lantern_at", Vector4(p.x, p.y, p.z, light.omni_range * t))
	_glass_mat.emission_energy_multiplier = 0.6 + 2.4 * t


## Hang straight down from the hand or belt, whatever it's doing (it swings, it doesn't tilt). Smaller on the belt.
func _hang(spot: String) -> void:
	var yaw := global_basis.z
	global_basis = Basis(Vector3.UP, atan2(yaw.x, yaw.z)).scaled(Vector3.ONE * (HIP_SCALE if spot == "hip" else 1.0))


## The Hip Lantern swings on its belt ring as he walks, runs and turns (owner, Nov 22, F613): a little pendulum
## pushed by how the belt speeds up and slows down. Call it after _to_belt() and _hang().
func _swing_step(delta: float) -> void:
	if delta <= 0.0:
		return
	var drop := BELT_ABOVE * HIP_SCALE
	var belt := global_position + Vector3(0, drop, 0)
	if not _belt_seen or belt.distance_to(_belt_last) > 1.0:  # (first frame, or a teleport: start still)
		_belt_seen = true
		_belt_last = belt
		_belt_v = Vector3.ZERO
		_swing = Vector3.ZERO
		_swing_v = Vector3.ZERO
		return
	var v := (belt - _belt_last) / delta
	var push := ((v - _belt_v) / delta).limit_length(250.0)  # (ignores glitches, not a hard stop)
	_belt_last = belt
	_belt_v = v
	push.y = 0.0
	var w := SWING_SPEED
	_swing_v += (-w * w * _swing - 2.0 * SWING_DAMP * w * _swing_v - push * SWING_PUSH) * delta
	_swing += _swing_v * delta
	_swing.y = 0.0
	if _swing.length() > drop * SWING_MAX:
		_swing = _swing.limit_length(drop * SWING_MAX)
		_swing_v *= 0.5
	var dir := Vector3(_swing.x, -drop, _swing.z).normalized()
	var axis := Vector3.DOWN.cross(dir)
	if axis.length() > 0.0001:
		global_basis = Basis(axis.normalized(), Vector3.DOWN.angle_to(dir)) * global_basis
	global_position = belt + dir * drop


## How far it tilts from hanging straight down, in degrees.
func swing_degrees() -> float:
	return rad_to_deg(atan2(_swing.length(), BELT_ABOVE * HIP_SCALE))


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
			transform = Transform3D(Basis(), Vector3(0, 1.75, 0.25))  # (full size again if it was on the belt)
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
		global_position = (dm as DwarfModel).hip_point() - Vector3(0, BELT_ABOVE * HIP_SCALE, 0)
