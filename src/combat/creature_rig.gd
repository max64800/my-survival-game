class_name CreatureRig
extends RefCounted
## Creatures that move by a skeleton (the KayKit miners of Lampwick Drift and Old Pell's Diggings, Nov 20).
## The older creatures move by named parts (MonsterModel.animate); these play the moves stored in their model.
## Only looks: every computer picks the move from what it sees (how fast it goes) and from the host's events
## (rise, attack, hit, death), so everyone sees the same thing without sending any more.
##
## The pattern: the model's own AnimationPlayer, played straight from code with short crossfades (play(name, blend)).
## (Not an AnimationTree: the moves come from one-off events, and a crossfade is all the blending they need.)

const RISE := "Skeletons_Awaken_Floor"        ## lying in pieces -> standing (owner F462)
const LIE := "Skeletons_Inactive_Floor_Pose"  ## scattered bones on the floor
const DEATH := "Death_C_Skeletons"            ## falls apart (owner F463)
const HIT := "Hit_A"                          ## the flinch (owner F464: with our white flash)
const LOOPS := ["Idle", "Idle_Combat", "2H_Melee_Idle", "Walking_A", "Walking_D_Skeletons", "Running_A", "Running_B"]
## When the blow of each swing lands, in seconds into the move (measured: the tool moves fastest then). The move is
## sped up or slowed down so that moment comes exactly when the host's attack lands (the end of its tell).
## (the Spin: its whirl turns him round from 0.62 to 1.25 s; the blow lands as the whirl gets going, 0.8 s: owner, Nov 20,
## "the knock-down from the big spin is delayed": it was 1.16, the end of the whirl)
const IMPACT := {"1H_Melee_Attack_Chop": 0.57, "1H_Melee_Attack_Stab": 0.40, "2H_Melee_Attack_Chop": 0.72, "2H_Melee_Attack_Spin": 0.8}
## How fast each walk or run moves over the ground at normal speed (in the skeleton's own size; measured from the
## foot swing). The move plays faster or slower to match how fast the creature really goes.
const WHIRL := Vector2(0.62, 1.25)  ## the spinning part of 2H_Melee_Attack_Spin (seconds into the move)
const GROUND_SPEED :={"Walking_D_Skeletons": 0.49, "Walking_A": 0.75, "Running_A": 1.52}
const RUN_FROM := 0.55  ## faster than this part of its run speed: the run (owner F464: nearly always running)

var ap: AnimationPlayer
var unit := 1.0          ## how big one skeleton unit is in metres (the model's scale)
var lying := false
var dead := false
var knocked_down := false  ## non-lethal fall: plays death anim, then rises on get_up()
var _busy := 0.0         ## seconds a one-off move (rise, swing, flinch) still plays before walking takes over
var _busy_kind := ""     ## "rise", "attack" or "hit"
var _walk := ""          ## the walk or run move playing now
var _moving := 0.0       ## seconds a lying pile has been moving (a slide when it appears doesn't count)
var hand: BoneAttachment3D  ## follows the weapon hand (the pick's swing trail: owner, Nov 20)
const TRAIL_LEN := 0.95  ## m from the hand to the pick's head (the trail's far edge)
const TRAIL := Color(0.95, 0.88, 0.75, 0.45)
const TRAIL_BOSS := Color(1.0, 0.5, 0.38, 0.6)  ## the shield-only swings (the same red as their outline)
var skel: Skeleton3D
var shield: ShieldArm    ## the Prop Warden's raised shield arm (F548), or null
var _guard_swing := true  ## the swing playing now keeps the shield up (not his two-handed moves)
const SHIELD_FADE := 6.0  ## how fast the shield comes up / goes down (whole way in 1/6 s)


## The rig of a model made from a skeleton pack, or null (an older creature).
static func find(model: Node3D) -> CreatureRig:
	if model.has_meta("ghost_model"):
		return GhostRig.make(model)  # (a dungeon ghost: the dwarf's skeleton and moves, Ghost)
	var forged: Node3D = model.get_meta("forged_root", null)
	if forged == null:
		return null
	var player := forged.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skels := forged.find_children("*", "Skeleton3D", true, false)
	if player == null or skels.is_empty() or not player.has_animation(DEATH):
		return null
	var rig := CreatureRig.new()
	rig.ap = player
	for n in LOOPS:
		if player.has_animation(n):
			player.get_animation(n).loop_mode = Animation.LOOP_LINEAR  # (glTF moves come in unlooped)
	var s := 1.0
	var n: Node = skels[0]
	while n != null and n != model.get_parent():
		if n is Node3D:
			s *= (n as Node3D).scale.y
		n = n.get_parent()
	rig.unit = s
	var sk := skels[0] as Skeleton3D
	rig.skel = sk
	if sk.find_bone("handslot.r") >= 0:
		rig.hand = BoneAttachment3D.new()
		rig.hand.bone_name = "handslot.r"
		sk.add_child(rig.hand)
		rig.tips = tool_tips(sk, forged)
	return rig


## A creature with a front shield (the Prop Warden, F548): its left arm holds the shield up in front (ShieldArm).
func hold_shield() -> void:
	var sk := skel
	if sk == null:
		return
	var arm := ShieldArm.new()
	arm.name = "ShieldArm"
	if arm.setup(ap, sk):
		sk.add_child(arm)
		shield = arm


## Lying scattered on the floor until someone comes near.
func lie() -> void:
	lying = true
	ap.play(LIE)


## Gets up out of the pile (the host decided: someone came near).
func rise() -> void:
	if dead or not lying:
		return
	lying = false
	ap.play(RISE, 0.1)
	_busy = ap.get_animation(RISE).length
	_busy_kind = "rise"
	_walk = ""


func rise_time() -> float:
	return ap.get_animation(RISE).length


## A swing whose blow lands `tell` seconds from now.
func attack(clip: String, tell: float, red := false, again := false) -> void:
	if dead or not ap.has_animation(clip):
		return
	if knocked_down:
		return  # never attack while on the floor (F652)
	if _busy_kind == "rise" and _busy > 0.0:
		return  # finish getting up before swinging (never hit while rising)
	lying = false
	_guard_swing = not clip.begins_with("2H_")  # (his two-handed moves need the shield arm: the sweep, the Rally Slam)
	if clip in LOOPS:
		# A charge (the Prop Warden's Shield Charge): no swing to play, he runs (step() matches the run to his speed)
		# behind his raised shield; only the spark before it lands.
		_busy = 0.0
		_glint_later(glint_wait(tell))
		return
	if again and clip.contains("Spin"):
		# The whirl's next turn (owner, Nov 21): straight back into the spinning part (WHIRL), no new wind-up or spark.
		var turn := clampf((WHIRL.y - WHIRL.x) / maxf(tell, 0.05), 0.5, 2.5)
		ap.play(clip, 0.08, turn)
		ap.seek(WHIRL.x, true)
		_busy = (ap.get_animation(clip).length - WHIRL.x) / turn
		_busy_kind = "attack"
		_walk = ""
		if hand != null and hand.is_inside_tree():
			WeaponTrail.follow(hand, tell, TRAIL_BOSS if red else TRAIL, 0.25 / maxf(hand.global_basis.get_scale().y, 0.001),
				TRAIL_LEN / maxf(hand.global_basis.get_scale().y, 0.001))
		return
	var speed := clampf(float(IMPACT.get(clip, 0.5)) / maxf(tell, 0.05), 0.5, 2.5)
	ap.play(clip, 0.12, speed)
	_busy = ap.get_animation(clip).length / speed
	_busy_kind = "attack"
	_walk = ""
	_swing_trail(clip, speed, red)
	_glint_later(glint_wait(tell))


## The star + "ting" on the pick a moment before the blow (owner, Nov 20: "I don't see when to parry"):
## GLINT_LEAD seconds before it lands, or right away when the whole warning is shorter than that.
const GLINT_LEAD := 0.4


static func glint_wait(tell: float) -> float:
	return maxf(0.0, tell - GLINT_LEAD)


## The tool's points in the hand socket's own space (owner, Nov 21: "make sure the star is on the tip"): measured from
## the "tool" mesh itself. A pick has two (the ends of its head), a shovel one (the top of its blade).
var tips: Array[Vector3] = []


static func tool_tips(skel: Skeleton3D, root: Node) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var hb := skel.find_bone("handslot.r")
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if not String(mi.name).to_lower().begins_with("tool") or mi.mesh == null or mi.skin == null:
			continue
		var bind := Transform3D.IDENTITY
		var found := false
		for i in mi.skin.get_bind_count():
			if mi.skin.get_bind_name(i) == &"handslot.r" or mi.skin.get_bind_bone(i) == hb:
				bind = mi.skin.get_bind_pose(i)  # mesh space -> the hand socket's space
				found = true
		if not found:
			continue
		var pts: Array[Vector3] = []
		var top := -INF
		for si in mi.mesh.get_surface_count():
			for v: Vector3 in mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				var p := bind * v
				pts.append(p)
				top = maxf(top, p.y)
		var lo := Vector3(INF, 0, 0)
		var hi := Vector3(-INF, 0, 0)
		var peak := Vector3(0, -INF, 0)
		for p in pts:
			if p.y < top * 0.7:
				continue  # (only the head end of the handle)
			if p.x < lo.x:
				lo = p
			if p.x > hi.x:
				hi = p
			if p.y > peak.y:
				peak = p
		if hi.x - lo.x > 0.35:
			out.append(lo)  # a pick's two points
			out.append(hi)
		else:
			out.append(peak)  # a shovel's blade top
	return out


## The point that leads the swing: of the tool's points, the one furthest in front of the creature right now.
func lead_tip() -> Vector3:
	if tips.is_empty() or hand == null or not hand.is_inside_tree():
		return Vector3(0, TRAIL_LEN / maxf(hand.global_basis.get_scale().y, 0.001) if hand else TRAIL_LEN, 0)
	var front := hand.get_parent_node_3d().global_basis.z.normalized() if hand.get_parent_node_3d() else Vector3.BACK
	var best := tips[0]
	for t in tips:
		if (hand.global_transform * t).dot(front) > (hand.global_transform * best).dot(front):
			best = t
	return best


func _glint_later(wait: float) -> void:
	if hand == null or not hand.is_inside_tree():
		return
	var h := hand
	var go := func() -> void:
		if not is_instance_valid(h) or not h.is_inside_tree() or dead:
			return
		var tip := lead_tip()
		var at := h.global_transform * tip
		PickGlint.on(h, tip)
		Sfx.play("clink", at, -3.0, 1.0)  # (a real metal clink at natural pitch: the attack warning)
	if wait <= 0.01:
		go.call()
		return
	var timer := Timer.new()  # (on the hand: if the creature goes away first, its timer goes with it)
	timer.one_shot = true
	timer.wait_time = wait
	h.add_child(timer)
	timer.timeout.connect(func() -> void:
		go.call()
		timer.queue_free())
	timer.start()


## The pick's swoosh (owner, Nov 20: "trails from the enemies and bosses"): from a moment before the blow lands to
## just after it; the Spin's along its whole whirl (0.62-1.25 s of the move).
func _swing_trail(clip: String, speed: float, red: bool) -> void:
	if hand == null or not hand.is_inside_tree():
		return
	var impact := float(IMPACT.get(clip, 0.5))
	var from := (0.62 if clip.contains("Spin") else impact - 0.28) / speed
	var to := (1.28 if clip.contains("Spin") else impact + 0.08) / speed
	var s := maxf(hand.global_basis.get_scale().y, 0.001)
	var h := hand
	var col := TRAIL_BOSS if red else TRAIL
	var timer := Timer.new()  # (on the hand: if the creature goes away first, its timer goes with it)
	timer.one_shot = true
	timer.wait_time = maxf(from, 0.01)
	hand.add_child(timer)
	timer.timeout.connect(func() -> void:
		WeaponTrail.follow(h, to - from, col, 0.25 / s, TRAIL_LEN / s)
		timer.queue_free())
	timer.start()


## Hit: the flinch (not in the middle of a swing or of getting up: the swing still lands).
func hit() -> void:
	if dead or lying or (_busy > 0.0 and _busy_kind != "hit"):
		return
	ap.play(HIT, 0.05)
	ap.seek(0.0, true)  # (hit again while flinching: it flinches again)
	_busy = ap.get_animation(HIT).length
	_busy_kind = "hit"
	_walk = ""


## Falls apart. Returns how long that takes.
func die() -> float:
	dead = true
	lying = false
	ap.speed_scale = 1.0
	ap.play(DEATH, 0.1)
	return ap.get_animation(DEATH).length


## Non-lethal fall: plays the death-fall animation but the creature is NOT dead and will get up.
func knock_down() -> void:
	if dead or knocked_down:
		return
	knocked_down = true
	lying = false
	ap.speed_scale = 1.0
	ap.play(DEATH, 0.1)
	ap.speed_scale = 1.0  # (overwrite any freeze that step() left behind)
	_busy = ap.get_animation(DEATH).length
	_busy_kind = "hit"
	_walk = ""


## Called when a knocked-down creature should get back up.
func get_up() -> void:
	if dead or not knocked_down:
		return
	knocked_down = false
	ap.speed_scale = 1.0
	ap.play(RISE, 0.1)
	_busy = ap.get_animation(RISE).length
	_busy_kind = "rise"
	_walk = ""


## Every frame. `speed` = how fast it really moves (m/s), `run` = its run speed, `alert` = it knows you're there.
## `frozen`: a hit's freeze-blink (the move waits).
func step(delta: float, speed: float, run: float, alert: bool, frozen: bool) -> void:
	if dead:
		if shield:
			shield.influence = 0.0
		return
	if shield:
		var up := alert and not lying and (_busy <= 0.0 or _busy_kind == "hit" or (_busy_kind == "attack" and _guard_swing))
		shield.influence = move_toward(shield.influence, 1.0 if up else 0.0, delta * SHIELD_FADE)
	ap.speed_scale = 0.0 if frozen else 1.0
	if frozen:
		return
	if lying:
		_moving = _moving + delta if speed > 0.8 else 0.0
		if _moving > 0.6:
			rise()  # (it keeps moving, so it has got up: a player who joined late missed the host's "rise")
		return
	if knocked_down:
		if _busy > 0.0:
			_busy -= delta
		return  # hold the floor pose until get_up() is called
	if _busy > 0.0:
		_busy -= delta
		return
	var clip := "Idle_Combat" if alert else "Idle"
	if speed > 0.25:
		clip = "Running_A" if speed > run * RUN_FROM else ("Walking_D_Skeletons" if alert else "Walking_A")
	var scale := 1.0
	if GROUND_SPEED.has(clip):
		scale = clampf(speed / (float(GROUND_SPEED[clip]) * unit), 0.6, 2.2)
	if clip != _walk:
		ap.play(clip, 0.18)
		_walk = clip
	ap.speed_scale = scale  # (follows the creature's real speed)
