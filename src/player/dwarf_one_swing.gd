class_name DwarfOneSwing
extends RefCounted
## How the dwarf swings the sword and the mace (F389, owner Nov 20: "do the same for the sword and the mace", he didn't
## like their old moves). The moves are the KayKit Skeletons warrior's one-handed ones (CC0, the same pack as the great
## axe's: DwarfGreatSwing), copied onto the dwarf's bones by tools/asset_forge/one_kaykit_bake.gd into BAKED:
##   Chop, SliceDiag, SliceFlat, Stab, JumpChop, BlockAttack (1H_Melee_Attack_*, Block_Attack).
## Not mirrored (the pack holds one-handed weapons in the right hand too). Each frame: every big bone's turn
## (whole-skeleton space), the hips' place, which way the handle points and which way the blade's edge faces.
## DwarfRig.one_pose plays them ("o/" clips) and DwarfFist lays the weapon in the right fist by them; standing, walking
## and blocking stay the dwarf's own (only the swings are the pack's). The game's hit lands at HIT_AT of a swing: each
## clip is sped up or slowed down so its strike (the weapon tip's fastest moment, found by the bake) lands right there.
## By the dwarf-animations Claude, chat 12, Nov 20, 2026.

const BAKED := "res://assets/anim/one_kaykit.json"
const MOVES := ["Chop", "SliceDiag", "SliceFlat", "Stab", "JumpChop", "BlockAttack"]
const HIT_AT := 0.40
const BLEND_IN := 0.12  ## share of a swing spent easing in from wherever his arms were
const BLEND_OUT := 0.18  ## s easing back to his own arms after a swing

static var _clips := {}  ## name -> [length (s), frames per second, strike (s), [pose, ...]]


static func _load() -> void:
	if not _clips.is_empty() or not FileAccess.file_exists(BAKED):
		return
	var all: Variant = JSON.parse_string(FileAccess.get_file_as_string(BAKED))
	if not all is Dictionary:
		return
	var fps := float((all as Dictionary).get("fps", 30.0))
	for clip: String in all:
		if not all[clip] is Dictionary:
			continue
		var poses: Array = []
		for f: Dictionary in all[clip].frames:
			var bones := {}
			for b: String in f.bones:
				var q: Array = f.bones[b]
				bones[b] = Quaternion(q[0], q[1], q[2], q[3]).normalized()
			var h: Array = f.handle
			var e: Array = f.edge
			var pp: Array = f.pelvis
			poses.append({bones = bones, pelvis = Vector3(pp[0], pp[1], pp[2]),
				handle = Vector3(h[0], h[1], h[2]).normalized(), edge = Vector3(e[0], e[1], e[2]).normalized()})
		_clips[clip] = [float(all[clip].length), fps, float(all[clip].strike), poses]


static func has_move(move: String) -> bool:
	_load()
	return _clips.has(move)


## A baked clip's own length (s; 1 if it isn't there).
static func clip_length(clip: String) -> float:
	_load()
	return float(_clips[clip][0]) if _clips.has(clip) else 1.0


## The swing `move` at `t` (0..1 of the swing): the clip's strike lands at HIT_AT.
static func swing(move: String, t: float) -> Dictionary:
	_load()
	if not _clips.has(move):
		return {}
	var c: Array = _clips[move]
	var length := float(c[0])
	var hit := float(c[2])
	var sec := hit * t / HIT_AT if t <= HIT_AT else hit + (length - hit) * (t - HIT_AT) / (1.0 - HIT_AT)
	var poses: Array = c[3]
	var f := clampf(sec, 0.0, length) * float(c[1])
	var i := clampi(int(floor(f)), 0, poses.size() - 1)
	var j := mini(i + 1, poses.size() - 1)
	return DwarfGreatSwing.blend(poses[i], poses[j], f - float(i))
