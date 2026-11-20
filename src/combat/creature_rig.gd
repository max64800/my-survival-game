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
const IMPACT := {"1H_Melee_Attack_Chop": 0.57, "1H_Melee_Attack_Stab": 0.40, "2H_Melee_Attack_Chop": 0.72, "2H_Melee_Attack_Spin": 1.16}
## How fast each walk or run moves over the ground at normal speed (in the skeleton's own size; measured from the
## foot swing). The move plays faster or slower to match how fast the creature really goes.
const GROUND_SPEED := {"Walking_D_Skeletons": 0.49, "Walking_A": 0.75, "Running_A": 1.52}
const RUN_FROM := 0.55  ## faster than this part of its run speed: the run (owner F464: nearly always running)

var ap: AnimationPlayer
var unit := 1.0          ## how big one skeleton unit is in metres (the model's scale)
var lying := false
var dead := false
var _busy := 0.0         ## seconds a one-off move (rise, swing, flinch) still plays before walking takes over
var _busy_kind := ""     ## "rise", "attack" or "hit"
var _walk := ""          ## the walk or run move playing now
var _moving := 0.0       ## seconds a lying pile has been moving (a slide when it appears doesn't count)


## The rig of a model made from a skeleton pack, or null (an older creature).
static func find(model: Node3D) -> CreatureRig:
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
	return rig


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
func attack(clip: String, tell: float) -> void:
	if dead or not ap.has_animation(clip):
		return
	lying = false
	var speed := clampf(float(IMPACT.get(clip, 0.5)) / maxf(tell, 0.05), 0.5, 2.5)
	ap.play(clip, 0.12, speed)
	_busy = ap.get_animation(clip).length / speed
	_busy_kind = "attack"
	_walk = ""


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


## Every frame. `speed` = how fast it really moves (m/s), `run` = its run speed, `alert` = it knows you're there.
## `frozen`: a hit's freeze-blink (the move waits).
func step(delta: float, speed: float, run: float, alert: bool, frozen: bool) -> void:
	if dead:
		return
	ap.speed_scale = 0.0 if frozen else 1.0
	if frozen:
		return
	if lying:
		_moving = _moving + delta if speed > 0.8 else 0.0
		if _moving > 0.6:
			rise()  # (it keeps moving, so it has got up: a player who joined late missed the host's "rise")
		return
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
