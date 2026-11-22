class_name GhostRig
extends CreatureRig
## How a dungeon ghost moves (Ghost): the dwarf's own skeleton and moves under a ghost body. It floats with a slow bob,
## leans into its glide, and swings its mace with the dwarf's mace moves (DwarfRig.ATTACKS "mace": mace_1..mace_4),
## the blow landing exactly when the host's attack lands (the swing's strike is at DwarfOneSwing.HIT_AT of it).
## Like CreatureRig: only looks, every computer plays it from what it sees and the host's events.

var dm: DwarfModel
var _t := 0.0
var _lean := 0.0


static func make(model: Node3D) -> GhostRig:
	var dm := model.get_node_or_null("Ghost") as DwarfModel
	if dm == null:
		return null
	var r := GhostRig.new()
	r.dm = dm
	r._t = randf() * TAU  # (a pack doesn't bob in step)
	return r


func hold_shield() -> void:
	pass


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
	if dead or dm == null or dm.dwarf_rig == null:
		return
	var duration := maxf(tell, 0.1) / DwarfOneSwing.HIT_AT
	if clip.begins_with("mace_"):
		dm.attack(duration, false, clampi(clip.trim_prefix("mace_").to_int() - 1, 0, 3), "mace")
	else:
		dm.attack(duration, false, 0, "mace")  # (the swinging flag and the swoosh)
		dm.dwarf_rig.play_upper("o/" + clip, duration)  # (then the move itself in place of mace move 1)
	_busy = duration
	_busy_kind = "attack"


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
	# a slow float up and down, leaning into the glide; the arms only sway a little (it glides, it doesn't walk)
	var fast := clampf(speed / maxf(run, 0.1), 0.0, 1.0)
	_lean = move_toward(_lean, fast, delta * 3.0)
	dm.position.y = Ghost.HOVER + sin(_t * 2.1) * 0.05
	dm.rotation.x = -_lean * 0.18
	dm.set_motion(minf(speed, 1.2) * 0.6 if alert else 0.0, true, false)
