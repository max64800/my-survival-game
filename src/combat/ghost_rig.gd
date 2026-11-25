class_name GhostRig
extends CreatureRig
## How a dungeon ghost moves (Ghost): the dwarf's own skeleton and moves under a ghost body. It floats with a slow bob,
## leans into its glide, and swings its mace with the dwarf's mace moves (DwarfRig.ATTACKS "mace": mace_1..mace_4),
## the blow landing exactly when the host's attack lands (the swing's strike is at DwarfOneSwing.HIT_AT of it).
## Like CreatureRig: only looks, every computer plays it from what it sees and the host's events.

var dm: DwarfModel
var _t := 0.0
var _lean := 0.0
var guard := false  ## the Shield-Brother: his shield up in front of him (hold_shield)
var _open := 0.0  ## s his shield still hangs down after a swing (F850: your chance to hit him)
var _charging := 0.0  ## s his Shield Charge still runs (shield up, leaning in, no swing)
var _sag := 0.0  ## 0..1: how far it sinks while dazed
var stars := 0  ## how many parry stars it has shown (the tests count them; the test computer draws none)
const OPEN_AFTER := 1.7  ## s the shield stays down after his blow lands (his recover time, Monsters.LIST shield_brother)


static func make(model: Node3D) -> GhostRig:
	var dm := model.get_node_or_null("Ghost") as DwarfModel
	if dm == null:
		return null
	var r := GhostRig.new()
	r.dm = dm
	r._t = randf() * TAU  # (a pack doesn't bob in step)
	return r


## F850: the Shield-Brother holds his (ghostly bronze) shield up in front of him while he comes at you; it drops while
## he swings and for OPEN_AFTER after (MonsterManager._shield_blocks lets those hits through on the host).
func hold_shield() -> void:
	guard = true


## Dazed (his stun meter filled): a ghost has no bones to fall apart, so it sags, head bowed, low to the floor, until
## it gets up. (Before, the base rig's knock-down needed an AnimationPlayer a ghost doesn't have: it broke there and
## the ghost just hung in the air doing nothing, owner F873 "they often just stand there".)
func knock_down() -> void:
	if dead or knocked_down:
		return
	knocked_down = true
	_busy = 0.0
	_busy_kind = "hit"


func get_up() -> void:
	if dead or not knocked_down:
		return
	knocked_down = false
	_busy = 0.25
	_busy_kind = "rise"


func lie() -> void:
	pass


func rise() -> void:
	pass


func rise_time() -> float:
	return 0.1


## A swing whose blow lands `tell` seconds from now: a mace move ("mace_1".."mace_4", the dwarf's mace combo) or any
## other baked one-handed move by its own name ("Chop", "SliceDiag": DwarfOneSwing.MOVES; not JumpChop, its hips leap 1.3 m). Owner, Nov 22: mace moves 2
## and 3 alone made no sense ("he's just spinning", "he teleports into position and doesn't wind up"): they start
## where the hit before them ends, so they only play inside a combo; a ghost's single blow is a move that starts
## from standing and winds up.
func attack(clip: String, tell: float, _red := false, _again := false) -> void:
	if dead or knocked_down or dm == null or dm.dwarf_rig == null:
		return
	if clip == "charge":
		# The Shield-Brother's Shield Charge (F850): no swing, he leans in behind his shield and rushes you. Its warning
		# is the red outline (only a shield stops it: sidestep and he runs on past, his back open).
		_charging = tell
		_busy = tell
		_busy_kind = "attack"
		return
	var duration := maxf(tell, 0.1) / DwarfOneSwing.HIT_AT
	_open = duration + OPEN_AFTER
	if not _red:
		_glint_later(glint_wait(tell))  # F851: the parry star on its mace head, like every other creature's (F743)
	if clip.begins_with("mace_"):
		dm.attack(duration, false, clampi(clip.trim_prefix("mace_").to_int() - 1, 0, 3), "mace")
	else:
		dm.attack(duration, false, 0, "mace")  # (the swinging flag and the swoosh)
		dm.dwarf_rig.play_upper("o/" + clip, duration)  # (then the move itself in place of mace move 1)
	_busy = duration
	_busy_kind = "attack"


## F851: the star + "clink" on the mace head a moment before the blow lands (CreatureRig._glint_later does the same on
## a skeleton's pick; a ghost's mace sits in the dwarf rig's grip, not on a creature hand bone).
func _glint_later(wait: float) -> void:
	var grip := dm.dwarf_rig.grip if dm and dm.dwarf_rig else null
	if grip == null or not grip.is_inside_tree():
		return
	var held: WeakRef = weakref(grip)  # (the lambda holds no node: the ghost may be gone when the timer rings)
	var go := func() -> void:
		var g: Node3D = held.get_ref() as Node3D
		if g == null or not g.is_inside_tree() or dead or knocked_down:
			return
		var tip := mace_tip()
		stars += 1
		PickGlint.on(g, tip)
		Sfx.play("clink", g.global_transform * tip, -3.0, 1.0)
	if wait <= 0.01:
		go.call()
		return
	# (a scene-tree timer, not a Timer node: anything hung on the grip is taken for the weapon by DwarfFist)
	grip.get_tree().create_timer(wait).timeout.connect(go)


## The top of the mace head, in the grip's own space (the mace's handle points up its own +Y).
func mace_tip() -> Vector3:
	var grip := dm.dwarf_rig.grip if dm and dm.dwarf_rig else null
	var best := Vector3(0, 0.7, 0)
	if grip == null or not grip.is_inside_tree():
		return best
	var top := -INF
	var inv := grip.global_transform.affine_inverse()
	for mi: MeshInstance3D in grip.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var box := mi.get_aabb()
		var p := inv * (mi.global_transform * Vector3(box.get_center().x, box.end.y, box.get_center().z))
		if p.length() > top:
			top = p.length()
			best = p
	return best


static func swing_seconds(clip: String) -> float:
	if not clip.begins_with("mace_"):
		return DwarfOneSwing.clip_length(clip)
	var step := clampi(clip.trim_prefix("mace_").to_int() - 1, 0, 3)
	return DwarfRig.attack_seconds("mace", false, step, 1.0)


func hit() -> void:
	pass  # (the white flash is enough: a ghost doesn't flinch)


func die() -> float:
	dead = true
	return 1.2


func step(delta: float, speed: float, run: float, alert: bool, frozen: bool) -> void:
	if dead or dm == null or not is_instance_valid(dm):
		return
	if frozen:
		return
	_t += delta
	if _busy > 0.0:
		_busy -= delta
	_open = maxf(0.0, _open - delta)
	_charging = maxf(0.0, _charging - delta)
	# a slow float up and down, leaning into the glide; the arms only sway a little (it glides, it doesn't walk)
	var fast := clampf(speed / maxf(run, 0.1), 0.0, 1.0)
	if _charging > 0.0:
		fast = 2.2  # (leaning hard into his charge, behind the shield)
	_lean = move_toward(_lean, fast, delta * 3.0)
	# Dazed (knock_down): it only sinks a little and bows its head, still upright (owner, Nov 25, 3rd round: a tipped-over
	# ghost "looks like it lies down").
	_sag = move_toward(_sag, 1.0 if knocked_down else 0.0, delta * 4.0)
	dm.position.y = lerpf(Ghost.HOVER + sin(_t * 2.1) * 0.05, Ghost.HOVER - 0.12, _sag)
	dm.rotation.x = lerpf(-_lean * 0.18, -0.16, _sag)
	dm.set_motion(minf(speed, 1.2) * 0.6 if alert and not knocked_down else 0.0, true, false)
	if guard:
		dm.set_pose(not knocked_down and (_open <= 0.0 or _charging > 0.0), false, true)


## True while the shield hangs down (after a swing) or he is dazed: hits from the front get through.
func shield_open() -> bool:
	return knocked_down or (_open > 0.0 and _charging <= 0.0)
