class_name DwarfWeight
extends SkeletonModifier3D
## Makes the dwarf feel heavy and chunky (owner, Nov 19: "heavy + chunky"; F30, F342 squash and stretch).
## Runs every frame AFTER the animation and the dwarf shaping (DwarfProportions), BEFORE the hair and clothes springs,
## so they swing along with it. It only adds small turns and squashes on top of the pack's animations:
## - Follow-through: the upper body hangs a moment behind the hips, like a sack of flour on a spring. When the hips come
##   down on a footstep, the chest keeps going down a little and the shoulders sag, then it bounces back up.
## - Waddle: he leans over the foot that's on the ground, the shoulders lean back a bit less (so the head stays calm).
## - Breathing when standing: a slow, deep breath and a lazy shift from one foot to the other.
## - Jump: a stretch on take-off, and on landing a big squash (shorter, wider body, bent forward) that springs back.
## - Feet on the floor: the hips lift when a foot would sink into the floor.
## Apart from that hip lift, only spine and collar bones are touched (never the head: DwarfProportions owns it).

## The follow-through spring: how stiff (higher = quicker) and how bouncy (lower = more bounces).
const STIFF := 140.0
const BOUNCY := 0.42
## How much the chest bends forward and squashes per unit of follow-through (a share of the hip height).
const LEAN_DEG := 40.0
const SQUASH := 1.0
## The waddle: how far he leans over the standing foot (degrees) walking and running.
const WADDLE_DEG := 3.5
## Standing still: one breath every BREATH_SECS seconds; a slow sway from foot to foot every SWAY_SECS seconds.
const BREATH_SECS := 3.6
const SWAY_SECS := 7.5
## Landing: how hard the squash hits per second of falling, and the most it can be.
const LAND_KICK := 0.9
const LAND_MAX := 0.7

var speed := 0.0      ## set by DwarfRig every frame (m/s)
var on_floor := true
var rolling := false

var _spine := PackedInt32Array()  ## spine_01, spine_02, spine_03
var _clav := PackedInt32Array()   ## clavicle_l, clavicle_r
var _foot_l := -1
var _foot_r := -1
var _pelvis := -1
var _prop: DwarfProportions
var _feet := PackedInt32Array()
var _up := Vector3.UP
var _fwd := Vector3.FORWARD
var _side := Vector3.RIGHT
var _lean_sign := 1.0
var _roll_sign := 1.0
var _clav_sign := {}
var _hip_h := 1.0   ## hip height above the feet at rest (skeleton units): every distance below is a share of it
var _y := 0.0       ## where the spring-hung upper body is (skeleton y)
var _v := 0.0       ## and how fast it moves
var _started := false
var _waddle := 0.0
var _idle := 0.0
var _t := 0.0
var _stretch := 0.0  ## take-off stretch (fades out)
var _base_rot := {}  ## bone -> the rotation the animation wrote (see _begin)
var _wrote_rot := {}
var _base_scl := {}
var _wrote_scl := {}


func setup(sk: Skeleton3D, prop: DwarfProportions) -> void:
	for b in ["spine_01", "spine_02", "spine_03"]:
		if sk.find_bone(b) >= 0:
			_spine.append(sk.find_bone(b))
	for b in ["clavicle_l", "clavicle_r"]:
		if sk.find_bone(b) >= 0:
			_clav.append(sk.find_bone(b))
	_foot_l = sk.find_bone("foot_l")
	_foot_r = sk.find_bone("foot_r")
	_pelvis = sk.find_bone("pelvis")
	_prop = prop
	for b in ["ball_l", "ball_r", "foot_l", "foot_r"]:
		if sk.find_bone(b) >= 0:
			_feet.append(sk.find_bone(b))
	var ul := sk.find_bone("upperarm_l")
	var ur := sk.find_bone("upperarm_r")
	if mini(mini(_foot_l, _foot_r), mini(_pelvis, mini(ul, ur))) < 0 or _spine.size() < 3:
		active = false
		return
	# Which way is forward and sideways for this skeleton (worked out from the bones, like DwarfProportions does).
	var side := prop._rest_global(sk, ur, true).origin - prop._rest_global(sk, ul, true).origin
	side.y = 0.0
	_side = side.normalized()
	_fwd = _up.cross(_side).normalized()
	var ball := sk.find_bone("ball_l")
	if ball >= 0 and _fwd.dot(prop._rest_global(sk, ball, true).origin - prop._rest_global(sk, _foot_l, true).origin) < 0.0:
		_fwd = -_fwd
	_hip_h = maxf(prop._rest_global(sk, _pelvis, true).origin.y - prop._rest_global(sk, _foot_l, true).origin.y, 0.01)
	# Which way each turn goes (worked out from the rest pose, never guessed): turning a bone by +angle about an axis,
	# does the bone after it move the way we want? If not, that turn uses -angle.
	var head := sk.find_bone("Head")
	var rest := func(b: int) -> Vector3: return prop._rest_global(sk, b, true).origin
	_lean_sign = _sign_of(rest.call(_spine[0]), rest.call(head), _side, _fwd)       # + = bends forward
	_roll_sign = _sign_of(rest.call(_spine[0]), rest.call(head), _fwd, -_side)      # + = leans to his left
	for c in _clav:
		var arm := sk.find_bone("upperarm_l" if sk.get_bone_name(c).ends_with("_l") else "upperarm_r")
		_clav_sign[c] = _sign_of(rest.call(c), rest.call(arm), _fwd, -_up)         # + = the shoulder drops


## +1 if turning the point `to` around `from` by a small +angle about `axis` moves it along `want`, else -1.
static func _sign_of(from: Vector3, to: Vector3, axis: Vector3, want: Vector3) -> float:
	var moved := (to - from).rotated(axis.normalized(), 0.1) - (to - from)
	return 1.0 if moved.dot(want) >= 0.0 else -1.0


## Landing after `fall_secs` in the air: kick the spring down (a short hop barely shows, a long fall squashes hard).
func land(fall_secs: float) -> void:
	_v -= minf(fall_secs * LAND_KICK, LAND_MAX) * _hip_h * 2.0


## Leaving the ground: a quick stretch.
func takeoff() -> void:
	_stretch = 1.0


func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or delta <= 0.0:
		return
	delta = minf(delta, 0.05)
	_t += delta
	for b in _spine:
		_begin(sk, b)
	for b in _clav:
		_begin(sk, b)
	# 0. Feet on the floor: the pack's jog and sprint drop the hips for a human's long legs, so with the dwarf's short
	# legs the feet went up to 16 cm into the floor (measured, tools/asset_forge/dwarf_gait_check.gd). Lift the hips by
	# exactly what the lowest foot would sink.
	if _prop and _feet.size() > 0 and on_floor and not rolling:
		var low := INF
		for b in _feet:
			low = minf(low, sk.get_bone_global_pose(b).origin.y)
		var sink := _prop._rest_low - low
		if sink > 0.0:
			var parent := sk.get_bone_parent(_pelvis)
			var to_parent := sk.get_bone_global_pose(parent).basis.inverse() if parent >= 0 else Basis()
			var p := sk.get_bone_pose_position(_pelvis) + to_parent * Vector3(0, sink, 0)
			sk.set_bone_pose_position(_pelvis, p)
			_prop._written = p  # (so DwarfProportions still knows this as its own value and never lowers it twice)
	# 1. Follow-through: the spring chases the hips.
	var hip_y := sk.get_bone_global_pose(_pelvis).origin.y
	if not _started:
		_y = hip_y
		_started = true
	var damp := 2.0 * BOUNCY * sqrt(STIFF)
	_v += (STIFF * (hip_y - _y) - damp * _v) * delta
	_y += _v * delta
	var lag := clampf((_y - hip_y) / _hip_h, -0.09, 0.06)  # below 0 = the chest is sinking into the hips (squash)
	_stretch = move_toward(_stretch, 0.0, delta * 4.0)
	var squash := -lag * SQUASH - _stretch * 0.06  # > 0 = shorter and wider
	var lean := deg_to_rad(maxf(-lag, 0.0) * LEAN_DEG)
	# 2. Waddle over the standing foot (and 3. the lazy weight shift when standing).
	var moving := clampf(speed / 1.6, 0.0, 1.0) if on_floor and not rolling else 0.0
	var fl := sk.get_bone_global_pose(_foot_l).origin.y
	var fr := sk.get_bone_global_pose(_foot_r).origin.y
	var toward := clampf((fr - fl) / (_hip_h * 0.12), -1.0, 1.0)  # +1 = the left foot is the one down
	_waddle = lerpf(_waddle, toward * moving, minf(1.0, delta * 10.0))
	_idle = move_toward(_idle, 1.0 if on_floor and speed < 0.4 and not rolling else 0.0, delta * 2.0)
	var roll := deg_to_rad(_waddle * WADDLE_DEG + _idle * 1.6 * sin(_t * TAU / SWAY_SECS))
	var breath := _idle * sin(_t * TAU / BREATH_SECS)
	# Apply: the belly takes the squash and the lean, the chest the counter-lean and the breath.
	_turn(sk, _spine[0], _side, _lean_sign * lean * 0.6)
	_turn(sk, _spine[1], _side, _lean_sign * lean * 0.4)
	_turn(sk, _spine[0], _fwd, _roll_sign * roll)           # lean toward the standing foot (left foot down = lean left)
	_turn(sk, _spine[2], _fwd, -_roll_sign * roll * 0.55)   # the shoulders lean back about half, so the head stays calm
	_squash(sk, _spine[0], squash)
	_squash(sk, _spine[2], -0.012 * breath)    # breathing in: the chest swells a little
	for c in _clav:  # the shoulders sag on a heavy step and lift on a breath in
		_turn(sk, c, _fwd, _clav_sign[c] * deg_to_rad(maxf(-lag, 0.0) * 30.0 - breath * 1.5))


## Remember what the animation wrote this frame (if it wrote nothing new, the bone still holds our value from last
## frame: then go back to the animation's, so nothing piles up).
func _begin(sk: Skeleton3D, b: int) -> void:
	var r := sk.get_bone_pose_rotation(b)
	if not (_wrote_rot.has(b) and r.is_equal_approx(_wrote_rot[b])):
		_base_rot[b] = r
	sk.set_bone_pose_rotation(b, _base_rot[b])
	var s := sk.get_bone_pose_scale(b)
	if not (_wrote_scl.has(b) and s.is_equal_approx(_wrote_scl[b])):
		_base_scl[b] = s
	sk.set_bone_pose_scale(b, _base_scl[b])
	_wrote_rot[b] = _base_rot[b]
	_wrote_scl[b] = _base_scl[b]


## Turn a bone by `angle` around an axis given in skeleton space.
func _turn(sk: Skeleton3D, b: int, axis: Vector3, angle: float) -> void:
	if absf(angle) < 0.0001:
		return
	var g := sk.get_bone_global_pose(b).basis * Basis.from_scale(sk.get_bone_pose_scale(b)).inverse()
	var local_axis := (g.inverse() * axis).normalized()
	var r := (sk.get_bone_pose_rotation(b) * Quaternion(local_axis, angle)).normalized()
	sk.set_bone_pose_rotation(b, r)
	_wrote_rot[b] = r


## Squash a bone along its length (> 0 = shorter) and widen it to keep its size, like a ball of dough pressed down.
func _squash(sk: Skeleton3D, b: int, amount: float) -> void:
	amount = clampf(amount, -0.04, 0.07)
	if absf(amount) < 0.0005:
		return
	var along := 1.0 - amount
	var wide := 1.0 / sqrt(along)
	var s := sk.get_bone_pose_scale(b) * Vector3(wide, along, wide)
	sk.set_bone_pose_scale(b, s)
	_wrote_scl[b] = s
